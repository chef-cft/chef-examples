#
# Chef Infra Documentation
# https://docs.chef.io/libraries/
#

#
# This module name was auto-generated from the cookbook name. This name is a
# single word that starts with a capital letter and then continues to use
# camel-casing throughout the remainder of the name.
#
require 'vault'
module SecretsManagement
  module HashiVaultObjectHelpers
    def get_hashi_vault_object(vault_path, vault_address, vault_token, vault_role = nil)
      # Setting the vault address
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
      if secret.nil?
        raise "Could not read secret '#{vault_path}'!"
      else
        secret.data
      end
    end
  end
end
Chef::Resource.include ::SecretsManagement::HashiVaultObjectHelpers
Chef::Recipe.include ::SecretsManagement::HashiVaultObjectHelpers
Chef::Node.include ::SecretsManagement::HashiVaultObjectHelpers
