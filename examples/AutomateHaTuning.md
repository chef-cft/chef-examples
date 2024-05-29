# A-HA  60k+ nodes Tuning Recommendations

Assumption is running with servers specs of:

- 7 FE Nodes:
  - 8-16 cores cpu, 32GB ram
- 3 BE PGSQL Nodes:
  - 8-16 cores cpu, 32-64GB ram, 1TB SSD hard drive space
- 5 BE OpenSearch Nodes:
  - 16 cores cpu, 64GB ram, 15TB SSD hard drive space

## Apply to all FE’s for infra-server and Automate via patch.toml

```toml
# Cookbook Version Cache
[erchef.v1.sys.api]
  cbv_cache_enabled=true

# Depsolver Workers
[erchef.v1.sys.depsolver]
  timeout=5000
[erchef.v1.sys.depsolver]
  pool_init_size=32
  pool_queue_timeout=10000

# Connection Pools
[erchef.v1.sys.data_collector]
  pool_init_size=100
  pool_max_size=100
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
  timeout = 5000
  pool_init_size = 100
  pool_max_size = 100
  pool_queue_max = 512
  pool_queue_timeout = 10000
```

## Apply to all BE’s for OpenSearch via patch.toml

```toml
# Cluster
[cluster]
name = "opensearch"
max_shards_per_node= “6000"

# JVM Heap
[runtime]
es_java_opts = ""
es_startup_sleep_time = ""
g1ReservePercent = "25"
initiatingHeapOccupancyPercent = "15"
maxHeapsize = “32g"
max_locked_memory = "unlimited"
max_open_files = ""
minHeapsize = “32g"

```

## Apply to all BE’s for PGSQL via patch.toml

```toml
# PGSQL connections
max_connections = 1500
```

### Get current HaProxy config, and update with the new parameters

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

#### Apply the change as below:-

```bash
hab config apply automate-ha-haproxy.default $(date '+%s') haproxy_config.toml
```
##### Restart, follower01, follower02 ,then leader as below.  Have to wait for sync. 

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
 
##### Check the synchonisation

```bash
journalctl -fu hab-sup
```

##### cat the following file on all x3 BE pgsql nodes.  Just to be sure the settings have taken, after restart

```bash
hab/svc/automate-ha-haproxy/config/haproxy.conf
```
