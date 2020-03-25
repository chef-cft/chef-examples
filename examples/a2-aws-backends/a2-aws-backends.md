# HowTo - Install Chef Automate & Chef Infra Server with AWS RDS Postgres and AWS Elasticsearch Backends

## USE AT YOUR OWN RISK, the support model for this is currently being worked out, please contact your CS team for any support.

This guide will show you how to setup your Chef Automate server using external Postgres and
Elasticsearch. Allowing you to offload the database operations of Chef Automate to AWS instead 
of managing them in-house.

## Arch Diagram:

![arch diagram](./images/Cloud-backends.png)

## Before You Start

### Assumptions

* You have AWS account access and can create resources including:
  * EC2 instances
  * RDS Postgres/Aurora PostgreSQL Clusters
  * Elasticsearch Service Domains
  * Any security groups and vpc subnets that are required as part of the setup
* This guide uses the Centos 7 HVM image.
* You have priced out the RDS and ES costs beforehand, please note that even the    smallest dev/ES cluster will cost around $120/mo.
* You have an understanding of AWS ES and how you want the HA configured, this will just cover setting up a Development deployment type for testing.
* You have an understanding of AWS networking and can figure out things like port ingress/egress access and can troubleshoot connectivity issues if needed.

### Tested Versions

* [Automate] | [`20200310163217`]
* [AWS RDS Aurora Postgres] | [`9.6.16`]
* [AWS ES] | [`6.8`]

## Part 1 of 4 - Create the Elasticsearch Domain in AWS
_The plan is to have Terraform code for this as well, I will update when ready_

### Step 1: Choose Deployment Type
1. In AWS, navigate to the Elasticsearch Service.
1. Click "Create New Domain"
1. Select the deployment type you want, for this example we're using Development.
1. Set the Elasticsearch version to `6.8`, that is currently the version that ships with Automate, and we want to be consistent.
1. Click "Next"
### Step 2: Configure Domain
1. Set the desired domain name.
1. Leave everything else set to default, unless you are configuring ES in a custom manner, which this guide doesn't cover.
### Step 3: Configure Access and Security
1. Set the Network configuration as follows:
   1. VPC - select the VPC you want ES to be deployed into, make sure it's a VPC that is accessible by the A2 instance you are standing up later.
   1. Subnet - be sure to put your ES cluster into a subnet that will also house your A2 instance.
   1. Security Groups - make sure you assign a Security Group that has port 443 access enabled _from_ the A2 instance security group. For my testing, I use a security group that has full access inboud/outbound from _itself_, thus allowing anything assigned to the same security group to be able to talk to each other.
   1. IAM Role - This should be a default.
1. Enable fine-grained access control, and choose "Create master user".
1. Configure a Master uername and password and save the credentials for later use.
1. For Access Policy, choose "Allow open access to the domain" - this seems like it's open to the world, but it's not, because you setup VPC/subnet/sg access in step 1, you don't need this.
1. Encryption options will auto-enable since fine-grained access control is on,you can set the KMS master key as needed, or use the default.
### Step 4: Review and Confirm
1. Click "Confirm" when everything looks good, and move on to Part 2, as the ES service will take a while to configure.

## Part 2 of 4 - Create the Aurora Postgres DB

### Create Database
1. Navigate to RDS in AWS, and click "Create Database"
1. Choose "Standard Create"
1. For Engine Options, choose:
   1. Amazon Aurora (we use this because it's low cost and easy to setup).
   1. Edition: Amazon Aurora with PostgreSQL compatibility.
   1. Version: `9.6.16`
1. Templates - Dev/Test for our purposes.
1. Settings:
   1. Set the cluser identifier.
   1. Set the credentials, choose a strong password.
1. Set the db instance size, I choose db.r4.large for this test.
1. For availability and durability, you can create an Aurora replica in a different AZ for fast failover if needed, it's good to do this and test it out before creating your final production Aurora cluster.
1. Under Connectivity, set the following:
   1. VPC (same that you used for ES).
   1. Expand "Additional connectivity configuration".
   1. Subnet group (same used for ES).
   1. Publicly accessible - NO
   1. VPC Security Group - "Choose existing", add the security groups that you added for ES.
   1. Availability zone & database port leave default.
1. Database authentication - leave set to password authentication.
1. Additional configuration - leave set to default.
1. Click "Create database".

## Part 3 of 4 - Create EC2 Instance & Prep for A2 Install

### Create EC2 Instance

1. I'm not going to go into much detail here, I just created an EC2 instance with a public IP for easy access, with a type of `t3a.large`. I made sure it was in the same VPC as my ES and RDS Postgres, and also made sure to assign the same security groups.
1. I also made sure to use the latest Centos 7 HVM image with updates, the ami ID is `ami-02eac2c0129f6376b` as of this writing.

### Create RDS Postgres `dbuser` and Assign Role to `postgres`
1. Centos 7 doesn't have the `psql` client installed by default, so let's download it using `yum`:
   `sudo yum install postgresql`
1. Now let's connect to our RDS Aurora Postgres endpoint with the credentials we configured in Part 2.
1. Command:
   ```
   psql -h <POSTGRES ENDPOINT> -U postgres
   ```
   example:
   ```
   psql -h database-1.cluster-ct71rco8carx.us-east-1.rds.amazonaws.com -U postgres
   ```
   type the postgres PW when prompted
1. Now, create the `dbuser`
   ```
   CREATE USER dbuser WITH PASSWORD '<CHOOSEAPW>' CREATEDB;
   > OUTPUT SHOULD SHOW "CREATE ROLE"
   GRANT dbuser TO postgres;
   > OUTPUT SHOULD SHOW "GRANT ROLE"
   \du
   > OUTPUT SHOULD SHOW SIMILAR TO:
                                                 List of roles
        Role name      |                   Attributes                   |              Member of
    -------------------+------------------------------------------------+-------------------------------------
     dbuser            | Create DB                                      | {}
     pg_signal_backend | Cannot login                                   | {}
     postgres          | Create role, Create DB                        +| {rds_superuser,dbuser}
                       | Password valid until infinity                  |
     rds_iam           | Cannot login                                   | {}
     rds_replication   | Cannot login                                   | {}
     rds_superuser     | Cannot login                                   | {rds_replication,pg_signal_backend}
     rdsadmin          | Superuser, Create role, Create DB, Replication+| {}
                       | Password valid until infinity                  |
    ```
### Download the AWS CA Cert bundles
AWS signs their own certs now with their own CA, we need to download those and make sure we have the entire intermediate chain included in our `config.toml`

1. For RDS Postgres, download the [rds-combined-ca-bundle.pem](https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem)
1. For ES, we need to create a Root CA bundle by combining the Root CAs available on this site: https://www.amazontrust.com/repository/
   1. Starting with `CN=Amazon Root CA 1,O=Amazon,C=US` and ending with `CN=Starfield Services Root Certificate`, click on the `PEM` link to the right and copy/paste the contents in order into a new file, you should end up with something like this (only a lot more text, I added ....'s to represent content)...
   ```
    -----BEGIN CERTIFICATE-----
    MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
    ........
    rqXRfboQnoZsG4q5WTP468SQvvG5
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIFQTCCAymgAwIBAgITBmyf0pY1hp8KD+WGePhbJruKNzANBgkqhkiG9w0BAQwF
    ........
    4PsJYGw=
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIBtjCCAVugAwIBAgITBmyf1XSXNmY/Owua2eiedgPySjAKBggqhkjOPQQDAjA5
    .......
    YyRIHN8wfdVoOw==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIB8jCCAXigAwIBAgITBmyf18G7EEwpQ+Vxe3ssyBrBDjAKBggqhkjOPQQDAzA5
    .......
    1KyLa2tJElMzrdfkviT8tQp21KW8EA==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIID7zCCAtegAwIBAgIBADANBgkqhkiG9w0BAQsFADCBmDELMAkGA1UEBhMCVVMx
    .......
    sSi6
    -----END CERTIFICATE-----
    ```
1. You should now have two files, one for ES and one for RDS that contain the CA root certs required to proceed.

### Download A2 and generate `config.toml`

1. Follow the instructions here to download A2 and generate a `config.toml`: 
   * https://automate.chef.io/docs/install/
1. Copy the contents of your `config.toml` to your favorite text editor, because we're about to do some major editing :).
1. Below is a working `config.toml`, with the SSL certs shortened for readability:
    ```toml
    # This is a default Chef Automate configuration file. You can run
    # 'chef-automate deploy' with this config file and it should
    # successfully create a new Chef Automate instance with default settings.

    [global.v1]
    # The external fully qualified domain name.
    # When the application is deployed you should be able to access 'https://<fqdn>/'
    # to login.
    fqdn = "<YOUR FQDN or EXTERNAL IP HERE>"

    # TLS Certificates for External-Facing Services
        # The following TLS certificate and RSA public key were
        # automatically generated. The certificate is a self-signed
        # certificate and will likely produce security warnings when you
        # visit Chef Automate in your web browser. We recommend using a
        # certificate signed by a certificate authority you trust.
    [[global.v1.frontend_tls]]
        # The TLS certificate for the load balancer frontend.
        cert = """-----BEGIN CERTIFICATE-----
    <YOUR TLS CERT>
    -----END CERTIFICATE-----
    """

        # The TLS RSA key for the load balancer frontend.
        key = """-----BEGIN RSA PRIVATE KEY-----
    <YOUR TLS RSA KEY>
    -----END RSA PRIVATE KEY-----
    """
    [global.v1.external.elasticsearch]
    enable = true
    nodes = ["https://<ES ENDPOINT FQDN, FORMATTED EXAMPLE BELOW>:443"]
    # nodes = ["https://vpc-automate-es-qejobocqaanhwp7mw7sqt47yhe.us-east-1.es.amazonaws.com:443"]

    [global.v1.external.elasticsearch.ssl]
    root_cert = """
    <CONTENTS OF ES CA BUNDLE YOU CREATED>
    """
    server_name = "<ES ENDPOINT NAME, EXAMPLE BELOW>"
    # server_name = "vpc-automate-es-qejobocqaanhwp7mw7sqt47yhe.us-east-1.es.amazonaws.com"

    [global.v1.external.postgresql]
    enable = true
    nodes = ["<POSTGRES ENDPOINT NAME:PORT, EXAMPLE BELOW>"]
    # nodes = ["database-1.cluster-ro-ct71rco8carx.us-east-1.rds.amazonaws.com:5432"]

    [global.v1.external.postgresql.auth]
    scheme = "password"

    [global.v1.external.postgresql.auth.password.superuser]
    username = "postgres"
    password = "<PASSWORD FOR POSTGRES>"
    [global.v1.external.postgresql.auth.password.dbuser]
    username = "dbuser"
    password = "<PASSWORD FOR DBUSER>"

    [global.v1.external.postgresql.ssl]
    enable = true
    root_cert = """
    <ENTIRE CONTENTS OF rds-combined-ca-bundle.pem, WAIT TO DO THIS AT THE END, IT's OVER 1000 LINES>
    """

    # Deployment service configuration.
    [deployment.v1]
    [deployment.v1.svc]
        # Habitat channel to install hartifact from.
        # Can be 'dev', 'current', or 'acceptance'
        channel = "current"
        upgrade_strategy = "none"
        deployment_type = "local"
        products=["automate", "chef-server"]  

    # License Control service configuration.
    [license_control.v1]
    [license_control.v1.svc]
        # The Chef Software provided license token required to run Chef Automate.
        # This can also be set with the "chef-automate license apply" command.
        license = ""
        
    # Add this because our CA root chain is LOOONG
    [esgateway.v1.sys.ngx.http]
    ssl_verify_depth = 1000
    ```
1. Once your new `config.toml` is created, copy it back to the EC2 Instance you're installing Automate on.

## Part 4 of 4 - Deploy Automate!

1. On the EC2 instance, let's now run the `deploy` with the new `config.toml`
1. When done, you should see something like this:
    ```
    .......
    Starting automate-gateway
    Starting automate-load-balancer

    Checking service health

    Creating admin user

    Deploy Complete
    Your credentials have been saved to automate-credentials.toml
    Access the web UI at https://<YOUR FQDN>/

    Users of this Automate deployment may elect to share anonymized usage data with
    Chef Software, Inc. Chef uses this shared data to improve Automate.
    Please visit https://chef.io/privacy-policy for more information about the
    information Chef collects, and how that information is used.
    ```
1. Get your credentials from the `credentials.toml` file and login, and you're all set!


## FAQs

1. [This section should be updated regularly as people ask about certain behaviors and you answer questions related to this example.]
