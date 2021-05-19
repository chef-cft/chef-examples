#
# Cookbook:: example_vault_chef
# Recipe:: default
#

# Log the secret contents to show what the contents look like as a string
log node.run_state['vault_data'].to_s do
  level :info
end

# Use the secret data obtained from Vault for populating our configuration file
file '/tmp/secretfile' do
  content <<~SECFILE
    key1 value: #{node.run_state['vault_data'][:key1]}
    key2 value: #{node.run_state['vault_data'][:key2]}
  SECFILE
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

template '/tmp/my_application_config' do
  source 'example.yml.erb'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
