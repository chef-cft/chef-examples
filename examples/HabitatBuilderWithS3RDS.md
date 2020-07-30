# HowTo - Setup On-Premise Depot to Leverage RDS and S3.

These instructions will allow a highly-available on-premise depot installation leveraging cloud services (in this case, RDS and S3).
## Before You Start

### Assumptions

* New Instance:
  * 16 Cores
  * 32 GB RAM
  * /hab partitioned to a 100 GB volume
  * /tmp partitioned to a 50 GB volume
  * Communication opened on 443, 80, Postgres RDS port
  * Able to get root access

### Tested Versions

* Chef Habitat On-Premise Depot

## Setup On-Premise Depot to Leverage RDS and S3

1. Download the Zip archive of the on-prem-builder repo:<br />
`curl -LO https://github.com/habitat-sh/on-prem-builder/archive/master.zip`
2. Download the Chef Habitat cli tool:<br />
`curl -Lo hab.tar.gz https://packages.chef.io/files/stable/habitat/latest/hab-x86_64-linux.tar.gz`
3. From the zip archive, install the hab binary somewhere in $PATH and ensure it has execute permissions:<br />
`sudo chmod 755 /usr/bin/hab`<br />
`sudo hab license accept # accepts the license`<br />
4. Import the public package signing keys from the downloaded Builder package bundle:<br />
`export UNZIP_DIR=/some/base/unzip/directory`<br />
`for file in $(ls ${UNZIP_DIR}/builder_packages/keys/*pub); do cat $file | sudo hab origin key import;done`
5. Create a Habitat artifact cache directory, place the Builder *.hart packages into that directory and then pre-install the Builder Services:<br />
`sudo mkdir -p /hab/cache/artifacts`<br />
`sudo mv ${UNZIP_DIR}/builder_packages/artifacts/*hart /hab/cache/artifacts`<br />
`sudo hab pkg install /hab/cache/artifacts/habitat-builder*hart`
6. Pre-install the Habitat Supervisor and its dependencies:<br />
`sudo hab pkg install --binlink --force /hab/cache/artifacts/core-hab-*hart`
7. Clone the Habitat Builder repository to the target machine: habitat-sh/on-prem-builder 
`cd ${SRC_ROOT}`<br />
`cp bldr.env.sample bldr.env`
8. Edit the bldr.env file to the desired values. 

To enable RDS, modify these values to match your RDS instance:

`export RDS_ENABLED=true      #edit this to match`<br />
`export RDS_USER=hab          #edit this to your RDS user`<br />
`export RDS_PASSWORD=hab      #edit this to your RDS password`<br />
`export POSTGRES_HOST=localhost  #replace with RDS fqdn`<br />
`export POSTGRES_PORT=5432       #replace with RDS port`<br />

To enable S3 instead of the local Minio, modify these values:

`export S3_ENABLED=false     #change to true`<br />
`export S3_REGION=us-west-2  #update to match your S3 target`<br />
`export S3_BUCKET=habitat-builder-artifact-store.local #update to match your S3 target`<br />
`export S3_ACCESS_KEY=depotaccesskey #update to match your S3 geared creds`<br />
`export S3_SECRET_KEY=depotsecretkey #update to match your S3 geared creds`<br />
`./install.sh`<br />
`sudo systemctl restart hab-sup`<br />
9. Check the service status:<br />
`hab svc status`<br />
10. Follow the instructions at: https://github.com/habitat-sh/on-prem-builder/blob/master/on-prem-docs/bootstrap-core.md to get your packages from one builder to another.
