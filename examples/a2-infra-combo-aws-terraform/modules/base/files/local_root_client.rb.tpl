log_level        :info
log_location     STDOUT
chef_server_url  'https://${chef_server}/organizations/${org_short_name}'
client_key '/opt/chef-keys/${chef_user}.pem'
node_name "${chef_user}"
