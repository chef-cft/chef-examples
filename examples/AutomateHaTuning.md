# A-HA  60k+ nodes Tuning Recommendations

Good read for additional Operating system level tuning <https://community.progress.com/s/article/Chef-Automate-Deployment-Planning-and-Performance-tuning-transcribed-from-Scaling-Chef-Automate-Beyond-100-000-nodes>

Assumption is running with minimum servers specs for a combined cluster of:

- 7 FE Nodes:
  - 8-16 cores cpu, 32GB ram
- 3 BE PGSQL Nodes:
  - 8-16 cores cpu, 32-64GB ram, 1TB SSD hard drive space
- 5 BE OpenSearch Nodes:
  - 16 cores cpu, 64GB ram, 15TB SSD hard drive space

You will also get more milage by creating seperate clusters for infra-server and Automate. This will allow for separate PGSQL and OpenSearch clusters for each application.

Additionally, these tuning parameters assume a chef workload of roles/envs/cookbooks.  
It is not intended to be used for policyfile only deployments(eg, depsolvers are not required for Policyfiles)

## Apply to all FE’s for infra-server via `chef-automate config patch infr-fe-patch.toml --cs`

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

# Depsolver Workers
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

## Apply to all FE’s for Automate via `chef-automate config patch automate-fe-patch.toml --a2`

```toml
# Worker Processes
[load_balancer.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
[cs_nginx.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
[esgateway.v1.sys.ngx.main]
  worker_processes = 10 # Not to exceed 10 or max number of cores
```

## Apply to all BE’s for OpenSearch via `chef-automate config patch opensearch-be-patch.toml --os`

```toml
# Cluster Ingestion
[opensearch.v1.sys.cluster]
  max_shards_per_node = 6000
# JVM Heap
[opensearch.v1.sys.runtime]
heapsize = "32g" # 50% of total memory up to 32GB
```

## Apply to all BE’s for PGSQL via `chef-automate config patch pgsql-be-patch.toml --pg`

```toml
# PGSQL connections
[postgresql.v1.sys.pg]
  max_connections = 1500
```

### PGSQL servers haproxy service isn't configurable via `chef-automate config patch` Below are the steps to update the haproxy service

#### Get the current HaProxy config, and update with the new parameters

### note: run this on a db backend, normally a follower

```bash
source /hab/sup/default/SystemdEnvironmentFile.sh
automate-backend-ctl applied --svc=automate-ha-haproxy | tail -n +2 > haproxy_config.toml
# note haproxy_config.toml may be blank. This is only to capture any local customisations that might have occurred
```

```haproxy.config
# HaProxy config
# Global
maxconn = 2000
# Each backend Server add
maxconn = 1500
```

##### Apply the change as below on a single db backend:-

```bash
hab config apply automate-ha-haproxy.default $(date '+%s') haproxy_config.toml
```
Note: this will propogate to all 3 backend db's and will restart the haproxy service on each Backend,
causing an outage(will only last a few mins), but a complete db restart is required as follows:-
(the only robust way is to restart all db backends, Do not skip the below steps)

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
