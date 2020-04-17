# HowTo - Install Chef Automate & Chef Infra Server with Google Cloud Platform (GCP) Cloud SQL 

## USE AT YOUR OWN RISK, the support model for this is currently being worked out, please contact your CS team for any support.

This guide will show you how to setup your Chef Automate + Chef Infra Server using external Postgres and
Elasticsearch. Allowing you to offload the database operations of Chef Automate + Chef Infra Server to GCP instead 
of managing them in-house.

### Current Limitations

#### Chef Specific
* Does not support Supermarket currently, to use Supermarket you'll have to setup a separate Chef Infra Server to act as the oauth provider.
* Does not support push-jobs
* No custom `chef-server.rb` can be defined
* This deployment method for Chef Infra is assuming you will be using a pipeline to deliver changes to your Chef Infra Server for all objects (cookbooks, data bags, etc...) and will not be creating users other than the one(s) needed for pipelining the process.
* Chef-Manage is not supported with this deployment model, as it is currently deprecated, and some of it's features are being migrated to Automate: https://docs.chef.io/versions/#deprecated-products-and-versions 

#### Cloud Specific
* Connecting to Cloud SQL for PostgreSQL via SSL works fine, however the option to "only allow SSL connections" will not work as it requires the use of a client cert and key, currently there is no way to apply that to the service that Chef uses to connect to an external DB.
* GCP does not have a native Elasticsearch service, 

## Arch Diagram:


## Before You Start

### Assumptions

* You have GCP account access and can create resources including:
  * Compute Engine> VM instances
  * GCP SQL> PostgreSQL instances [Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/features#postgres)
  * Some form of ES cluster creation ability, either ES6 Click to Deploy, or Elasticsearch Service on Elastic Cloud, this guide uses [ES 6 Click to Deploy](https://github.com/GoogleCloudPlatform/elasticsearch-docker/blob/master/6/README.md).
  * Any firewall and network settings are created/applied to allow communications between the VM instances, PostgreSQL instance and ES endpoints.
* This guide uses the Centos 7 image, if you want to use Centos 8, there are probably some `selinux` things you need to worry about.
* You have priced everything out beforehand, please note that even the smallest dev/ES | dev/PostgreSQL cluster can be costly.
* You have an understanding of PostgreSQL Clusters and how you want HA configured, this will just cover setting up a Development deployment type for testing.
* You have an understanding of ES Clusters and how you want HA configured, this will just cover setting up a Development deployment type for testing.
* You have an understanding of GCP networking and can figure out things like port ingress/egress access and can troubleshoot connectivity issues if needed.



Complete!
[dbright@chefauto certs]$ psql "sslmode=verify-ca sslrootcert=server-ca.pem \
> sslcert=client-cert.pem sslkey=client-key.pem \
> hostaddr=10.99.112.3 \
> user=postgres"
psql: private key file "client-key.pem" has group or world access; permissions should be u=rw (0600) or less
[dbright@chefauto certs]$ chmod 600 client-key.pem
[dbright@chefauto certs]$ psql "sslmode=verify-ca sslrootcert=server-ca.pem \
sslcert=client-cert.pem sslkey=client-key.pem \
hostaddr=10.99.112.3 \
user=postgres"
Password:
psql (9.2.24, server 9.6.16)
WARNING: psql version 9.2, server version 9.6.
         Some psql features might not work.
SSL connection (cipher: ECDHE-RSA-AES128-GCM-SHA256, bits: 128)
Type "help" for help.

postgres=> \q


postgres=> CREATE USER dbuser WITH PASSWORD 'chef.io.password' CREATEDB;
CREATE ROLE
postgres=> GRANT dbuser TO postgres;
GRANT ROLE
postgres=> \du
                                                               List of roles
         Role name         |                   Attributes                   |                          Member of
---------------------------+------------------------------------------------+--------------------------------------------------------------
 cloudsqladmin             | Superuser, Create role, Create DB, Replication | {}
 cloudsqlagent             | Create role, Create DB                         | {cloudsqlsuperuser}
 cloudsqliamserviceaccount | Cannot login                                   | {}
 cloudsqliamuser           | Cannot login                                   | {}
 cloudsqlimportexport      | Create role, Create DB                         | {cloudsqlsuperuser}
 cloudsqlreplica           | Replication                                    | {}
 cloudsqlsuperuser         | Create role, Create DB                         | {pg_monitor}
 dbuser                    | Create DB                                      | {}
 pg_monitor                | Cannot login                                   | {pg_read_all_settings,pg_read_all_stats,pg_stat_scan_tables}
 pg_read_all_settings      | Cannot login                                   | {}
 pg_read_all_stats         | Cannot login                                   | {}
 pg_signal_backend         | Cannot login                                   | {}
 pg_stat_scan_tables       | Cannot login                                   | {}
 postgres                  | Create role, Create DB                         | {cloudsqlsuperuser,dbuser}

postgres=> \q


Elasticsearch user
elastic
Elasticsearch password (Temporary)
Y3BGj366
Kibana user
kibana
Kibana password (Temporary)
JQ7wMfwm
Logstash System user
logstash_system
Logstash System password (Temporary)
wv4vScCf
Zone
us-east1-b

# WIP