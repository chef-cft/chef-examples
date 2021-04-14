#
# Cookbook:: example_vault_chef
# Recipe:: default
#
# Copyright:: 2021, Collin McNeese, All Rights Reserved.

vault_token = case node['example_vault_chef']['vault_token']
              when 'data-bag'
                # Fetches the token/secretid to read from Vault via data bag
                #  In a real environment this should be an encrypted data bag or some other secure
                #  location for obtaining this data.
                data_bag_item('approle_tokens', 'default')["#{node['example_vault_chef']['vault_approle']}"]['token']
              when 'encrypted-data-bag-from-bag'
                # Fetches the encrypted data_bag secret key from a data_bag and then uses that encryption key to read the
                #  Vault secret token from the `encrypted_tokens` data_bag.
                key_content = data_bag_item('encrypted_data_bag_keys', 'default')['key'].strip()
                data_bag_item('encrypted_tokens', 'default', key_content)["#{node['example_vault_chef']['vault_approle']}"]['token']
              when 'secret-from-api'
                # Fetches the token/secretid to read from Vault via external API
                api_data = api_json_fetch(node['example_vault_chef']['api_secret_server'].to_s)
                api_data['chef-role']['token']
              when 'encrypted-data-bag-from-file'
                # Fetches the encrypted data_bag secret key from a local file and then uses that encryption key to read the
                #  Vault secret token from the `encrypted_tokens` data_bag.
                cookbook_file '/tmp/keyfile' do
                  source 'mysecretfile'
                  owner 'root'
                  group 'root'
                  mode '0400'
                  action :create
                  compile_time true
                end

                key_content = Chef::EncryptedDataBagItem.load_secret('/tmp/keyfile')
                data_bag_item('encrypted_tokens', 'default', key_content)["#{node['example_vault_chef']['vault_approle']}"]['token']
              end

# Use the get_hashi_vault_object helper from secrets_management to fetch secret data.
vault_data = get_hashi_vault_object(
  node['example_vault_chef']['vault_path'],
  node['example_vault_chef']['vault_server'],
  vault_token,
  node['example_vault_chef']['vault_approle']
).data[:data]

# Log the secret contents to show what the contents look like as a string
log vault_data.to_s do
  level :info
end

# Use the secret data obtained from Vault for populating our configuration file
file '/tmp/secretfile' do
  content <<~SECFILE
    key1 value: #{vault_data[:key1]}
    key2 value: #{vault_data[:key2]}
  SECFILE
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end
