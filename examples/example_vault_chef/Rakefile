require 'fileutils'

# Make sure that the vault binary is in PATH
begin
  `vault --version` || raise
rescue
  pp 'Could not find `vault` binanry in PATH, exiting.'
  raise
end

def wd(file)
  Dir.getwd() + "/#{file}"
end

Rake::TaskManager.record_task_metadata = true

task :default do
  Rake.application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments
end

desc 'Create a local vault instance running on port 8200'
task :local_vault_start do
  system('VAULT_REDIRECT_ADDR=http://127.0.0.1:8200 && VAULT_UI=true && vault server -log-level=TRACE -dev -dev-root-token-id=root -dev-listen-address="0.0.0.0:8200"')
end

desc 'Configure a running local vault instance'
task :local_vault_config do
  file_chef_policy = <<~CHEF_POLICY
  path "secret/data/demo" {
    capabilities = ["read"]
  }
  CHEF_POLICY

  File.write(wd('chef-policy.hcl'), file_chef_policy)

  file_chef_role = <<~CHEF_ROLE
  path "auth/approle/role/chef-role/secret-id" {
    capabilities = ["update"]
  }
  path "auth/approle/role/chef-role/role-id" {
    capabilities = ["read"]
  }
  CHEF_ROLE

  File.write(wd('chef-role-token.hcl'), file_chef_role)

  setup_commands = [
    'vault kv put secret/demo key1=key1_value key2=key2_value',
    'vault kv get secret/demo',
    'vault policy write chef-policy chef-policy.hcl',
    'vault auth enable approle',
    'vault write auth/approle/role/chef-role policies=chef-policy',
    'vault policy write chef-role-token chef-role-token.hcl',
    'vault token create -policy=chef-role-token',
  ]

  setup_commands.each do |cmd|
    system(cmd)
  end
end
