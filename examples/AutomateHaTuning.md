# A-HA  60k+ nodes Tuning Recommendations

Good read for additional Operating system level tuning <https://community.progress.com/s/article/Chef-Automate-Deployment-Planning-and-Performance-tuning-transcribed-from-Scaling-Chef-Automate-Beyond-100-000-nodes>

Assumption is running with minimum servers specs for a combined cluster of:

- 7 FE Nodes:
  - 8-16 cores cpu, 32GB ram
- 3 BE PGSQL Nodes:
  - 8-16 cores cpu, 32-64GB ram, 1TB SSD hard drive space
- 5 BE OpenSearch Nodes:
  - 16 cores cpu, 64GB ram, 15TB SSD hard drive space

You will also get more mileage by creating separate clusters for infra-server and Automate. This will allow for separate PGSQL and OpenSearch clusters for each application.

---

## #1 Apply to all BE’s for PGSQL via `chef-automate config patch pgsql-be-patch.toml --pg`

### *Note: Requires manual service restart of the leader for the setting to take effect

```toml
# PGSQL connections
[postgresql.v1.sys.pg]
  max_connections = 2000
```

### *Note: Only needed for A-HA clusters version below 4.13.76. 4.13.76 removed the need for HAProxy connection to PGSQL and FE nodes connect directly to PGSQL now.

### PGSQL servers haproxy service isn't configurable via `chef-automate config patch` Below are the steps to update the haproxy service

#### Get the current HaProxy config, and update with the new parameters

Note: run this on a db backend, normally a follower

```bash
source /hab/sup/default/SystemdEnvironmentFile.sh
automate-backend-ctl applied --svc=automate-ha-haproxy | tail -n +2 > haproxy_config.toml
# note haproxy_config.toml may be blank. This is only to capture any local customisations that might have occurred
```

```toml
# HaProxy config
# Global
maxconn = 2000
# Backend Servers
[server]
maxconn = 1500
```

##### Apply the change as below on a single db backend:-

```bash
hab config apply automate-ha-haproxy.default $(date '+%s') haproxy_config.toml
```

Note: this will propagate to all 3 backend db's and will restart the haproxy service on each Backend, causing an outage(will only last a few mins), but a complete db restart is required as follows:- (the only robust way is to restart all db backends, Do not skip the below steps)

###### Restart, follower01, follower02 ,then leader as below.  Have to wait for sync.

###### On Followers

```bash
Systemctl stop hab-sup 
Systemctl start hab-sup 
journalctl -fu hab-sup
```

###### On leader

```bash
Systemctl stop hab-sup
# wait till leader is elected from other 2 old followers.  Only then do the start 
Systemctl start hab-sup
```

###### Check the synchronization

```bash
journalctl -fu hab-sup
```

###### Cat the following file on all x3 BE pgsql nodes.  Just to be sure the settings have taken, after restart

(ie witness the "maxconn = 1500" setting is present )

```bash
hab/svc/automate-ha-haproxy/config/haproxy.conf
```

---

## #2 Apply to all BE’s for OpenSearch via `chef-automate config patch opensearch-be-patch.toml --os`

Fix for knife search when nodes are over 10k. First run this on an FE node for embedded OpenSearch.

```bash
curl -XPUT "http://127.0.0.1:10144/chef/_settings" -d '{"index": {"max_result_window": 100000}}' -H "Content-Type: application/json"
```

Then run config patch with toml file below

```toml
# knife search fix for nodes over 10k
[erchef.v1.sys.index] # For Automate version 4.13.76 and newer
  track_total_hits = true
# Cluster Ingestion
[opensearch.v1.sys.cluster]
  max_shards_per_node = 6000
# JVM Heap
[opensearch.v1.sys.runtime]
  heapsize = "32g" # 50% of total memory up to 32GB
```

---

## #3 Apply to all FE’s for Automate via `chef-automate config patch automate-fe-patch.toml --a2`

```toml
# Worker Processes
[load_balancer.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
[esgateway.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
```

---

## #4 Apply to all FE’s for infra-server via `chef-automate config patch infr-fe-patch.toml -cs`

```toml
# Cookbook Version Cache
[erchef.v1.sys.api]
  cbv_cache_enabled = true

# Worker Processes
[load_balancer.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
[cs_nginx.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
[esgateway.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores

# CB Depsolver
# Depsolver tuning parameters assume a chef workload of roles/envs/cookbooks
# If only using policyfiles instead of roles/envs depsolver tuning is not required 
[erchef.v1.sys.depsolver]
  timeout = 10000
  pool_init_size = 32
  pool_max_size = 32
  pool_queue_max = 512
  pool_queue_timeout = 10000

# Connection Pools
[erchef.v1.sys.data_collector]
  pool_init_size = 100
  pool_max_size = 100
[erchef.v1.sys.sql]
  timeout = 5000
  pool_init_size = 80
  pool_max_size = 80
  pool_queue_max = 512
  pool_queue_timeout = 10000
[bifrost.v1.sys.sql]
  timeout = 5000
  pool_init_size = 80
  pool_max_size = 80
  pool_queue_max = 512
  pool_queue_timeout = 10000
[erchef.v1.sys.authz]
  timeout = 10000
  pool_init_size = 100
  pool_max_size = 100
  pool_queue_max = 512
  pool_queue_timeout = 10000
```

## #5 Optional settings

### Add client ip to x-forwarded-for header for tracing requests

Patch frontend nodes via `chef-automate config patch x-forward-patch.toml -fe`

```toml
[global.v1.sys.ngx.http]
  include_x_forwarded_for = true
```

### Increase knife search results past 10k results <https://docs.chef.io/automate/troubleshooting/#step-1-increase-the-max_result_window-to-retrieve-more-than-10000-records>

#### For Automate version 4.13.76 and newer

On an Opensearch node run:

```bash
curl -XPUT "http://127.0.0.1:10144/chef/_settings" \
    -d '{
          "index": {
            "max_result_window": 50000
          }
        }' \
    -H "Content-Type: application/json"
```

To verify setting run:

```bash
curl http://127.0.0.1:10144/_settings?pretty
```

Then patch frontend nodes via `chef-automate config patch knife-patch.toml -fe`

```toml
[erchef.v1.sys.index]
 track_total_hits = true
```
