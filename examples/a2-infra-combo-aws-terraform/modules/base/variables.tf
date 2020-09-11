# Key Name - The name of your key at AWS.
variable "key_name" {}

# Domain - The domain name used
variable "domain" {}

# Instance Key - The local copy of your key file.
variable "instance_key" {}

# Common Tags map gets passed in from the root module.
variable "common_tags" { type = "map" }

# Chef User
variable "chef_user" {
  type             = "map"
  description      = "Chef User"
}

# Chef Org
variable "chef_org" {
  type             = "map"
  description      = "Chef Organization"
  default          = {
    long_name      = "Chef Demo"
    short_name     = "chef-demo"
  }
}

# A2 License gets passed in from the root module.
variable "a2_license" {}

# A2 Admin Password gets passed in from the root module.
variable "a2_admin_password" {}

# Instances types get passed in from root module.
variable "bldr_server_instance_type" {}
variable "chef_server_instance_type" {}
variable "a2_server_instance_type" {}

# Harvest created user's key file - Set this to true to auto harvest the key.
variable "harvest_key" {}

# Directory where the harvested key will be placed
variable "local_keys_directory" {}

# Update the knife-override.rb file.  See README.md for explanation.
variable "update_knife_override" {}

# Domain Zone ID
variable "domain_zone_id" {}

# Bldr Server
variable "provision_bldr" {}
