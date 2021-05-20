default['example_vault_chef']['vault_server']             = 'http://host.docker.internal:8200'
default['example_vault_chef']['vault_path']               = 'secret/data/demo'
default['example_vault_chef']['vault_approle']            = 'chef-role'
default['example_vault_chef']['vault_token']              = 'data-bag'
default['example_vault_chef']['api_secret_server']        = 'http://host.docker.internal:10811'
default['example_vault_chef']['vault_namespace']          = nil

# used with 'token-file' option of 'vault_token' attribute
default['example_vault_chef']['vault_token_file']         = '/etc/chef/vault_token_file'
default['example_vault_chef']['vault_token_file_content'] = 's.FBTzEisjULaRxxTYhJA5brF9'
