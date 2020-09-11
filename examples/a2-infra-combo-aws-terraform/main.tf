terraform {
  required_version = "~> 0.13.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

data "aws_route53_zone" "selected" {
  name = var.domain
}

module "base_mod" {
  source                    = "./modules/base"
  common_tags               = local.common_tags
  a2_license                = var.a2_license
  a2_admin_password         = var.a2_admin_password
  domain                    = var.domain
  key_name                  = var.key_name
  instance_key              = var.instance_key
  bldr_server_instance_type = var.bldr_server_instance_type
  chef_server_instance_type = var.chef_server_instance_type
  a2_server_instance_type   = var.a2_server_instance_type
  chef_user                 = local.chef_user
  harvest_key               = var.harvest_key
  local_keys_directory      = var.local_keys_directory
  update_knife_override     = var.update_knife_override
  domain_zone_id            = data.aws_route53_zone.selected.zone_id
  provision_bldr            = var.provision_bldr
}

module "centos_sample_nodes" {
  source         = "./modules/centos_sample_nodes"
  common_tags    = local.common_tags
  domain         = var.domain
  key_name       = var.key_name
  instance_key   = var.instance_key
  node_count     = var.centos_sample_node_count
  domain_zone_id = data.aws_route53_zone.selected.zone_id
}
