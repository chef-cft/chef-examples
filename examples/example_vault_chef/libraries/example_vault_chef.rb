#
# Author:: Jeff Brimager
# Author:: Paul Bradford (<pbradford@chef.io>)
# Author:: Davin Taddeo (<davin@davintaddeo.com>)
# Cookbook:: chef_magic
# Library:: secrets_management
#
# Copyright:: 2019-2020, Davin Taddeo

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'vault'
require 'tomlrb'

module ExampleVaultChef
  module Helpers
    def get_hashi_vault_object(vault_path, vault_address, vault_token, vault_role = nil)
      # Need to set the vault address
      Vault.address = vault_address
      # Authenticate with the token
      Vault.token = vault_token

      Vault.ssl_verify = false

      if vault_role # Authenticate to Vault using the role_id
        approle_id = Vault.approle.role_id(vault_role)
        secret_id = Vault.approle.create_secret_id(vault_role).data[:secret_id]
        Vault.auth.approle(approle_id, secret_id)
      end

      # Attempt to read the secret
      secret = Vault.logical.read(vault_path)
      # Chef::Log.warn(secret)
      if secret.nil?
        raise "Could not read secret '#{vault_path}'!"
      else
        secret
      end
    end
  end
end

Chef::DSL::Universal.include ::ExampleVaultChef::Helpers
