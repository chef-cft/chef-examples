#
# Cookbook:: secrets_management
# Recipe:: hashi_vault
#
# Copyright:: 2020, The Authors, All Rights Reserved.

# Hashi_vault library. This was written so the out could be used during the converge stage
vault_data = get_hashi_vault_object(node['secrets_managment']['hashi']['vault_path'], node['secrets_managment']['hashi']['vault_address'], node['secrets_managment']['hashi']['vault_token'])

template '/tmp/config.conf' do
  source 'app.conf.erb'
  sensitive true
  variables(username: vault_data[:username],
  password: vault_data[:password])
end

file '/tmp/vault.txt' do
  content "This is a test and the password is: #{vault_data[:password]}"
  mode '0755'
  action :create
  sensitive true
end
