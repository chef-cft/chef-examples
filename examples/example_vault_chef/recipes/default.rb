#
# Cookbook:: example_vault_chef
# Recipe:: default
#

vault_token = case node['example_vault_chef']['vault_token']
              when 'data-bag'
                # Fetches the token/secretid to read from Vault via data bag
                #  In a real environment this should be an encrypted data bag or some other secure
                #  location for obtaining this data.
                data_bag_item('approle_tokens', 'default')["#{node['example_vault_chef']['vault_approle']}"]['token']
              when 'token-file'
                # Fetches the token/secretid from a file on the filesystem of the server
                # Mock up creating the token_file for test-kitchen only
                file node['example_vault_chef']['vault_token_file'] do
                  content node['example_vault_chef']['vault_token_file_content'].to_s
                  owner 'root'
                  group 'root'
                  mode '0600'
                  only_if { ENV['TEST_KITCHEN'] }
                end.run_action(:create)

                # Reads the first line of a file
                File.read(node['example_vault_chef']['vault_token_file']).split()[0] if File.exist?(node['example_vault_chef']['vault_token_file'])
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
node.run_state['vault_data'] = get_hashi_vault_object(
  node['example_vault_chef']['vault_path'],
  node['example_vault_chef']['vault_server'],
  vault_token,
  node['example_vault_chef']['vault_approle'],
  node['example_vault_chef']['vault_namespace']
).data[:data]

include_recipe 'example_vault_chef::example' if node['example_vault_chef']['run_examples']
