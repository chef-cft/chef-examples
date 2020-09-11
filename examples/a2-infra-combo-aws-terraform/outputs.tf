# # Outputs

# Automate Server
output "a2_server_url" {
  value = module.base_mod.a2_server_url
}

output "chef_password" {
  value = var.a2_admin_password
}

# Centos Sample nodes
output "centos_sample_nodes" {
  value = module.centos_sample_nodes.centos_sample_nodes
}
