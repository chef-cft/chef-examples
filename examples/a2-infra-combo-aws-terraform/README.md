# A2-Infra-AWS-Terraform
This repo contains terraform code that will quickly:
- Spin up a Chef server + Chef Automate combo
- Spin up empty centos nodes to manage (OPTIONAL)

**DISCLAIMER**:  This code was originally intended to quickly spin up a demo environment.  There are most certainly optimizations that can and should be made if you were going to use this to spin up a stack for actual usage.

*Translation*:  YMMV, and do your due dilligence if you are going to use this for anything other than a transient demo environment.

## Modules
### Base
This module is responsible for spinning up the Chef server+Automate server combo, These servers are built with the latest available CentOS AMIs, and are provisioned with the latest versions of the various Chef products.

### Centos Sample Nodes
This module controls spinning up CentOS sample nodes.  It uses the latest available CentOS 7 image.  Control wether or not these nodes spin up by using an integer value for the variable `centos_sample_node_count`.

## Usage
- Copy terraform.tfvars.example to terraform.tfvars.
  - `cp terraform.tfvars.example terraform.tfvars`
- Edit terraform.tfvars and use whatever values you need.
  - `vi terraform.tfvars`
    - **Note**, this plan expects to create DNS entries w/ Route53.  You will need to make sure to put in valid values for the DNS zone IDs.  Adjust any other values accordingly.
- Initialize and apply the plan.
  - `terraform init`
  - `terraform apply`

## Credit
Some ideas, code, and inspiration taken from:
https://github.com/mengesb/tf_chef_server
https://github.com/chef-cft/quickspin - template from this minus some features

## License
This is licensed under [the Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0).
