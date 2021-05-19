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

module ChefMagic
  module SecretsManagementHelpers
    def akv_token(client_id, client_secret, tenant)
      token_uri = URI.parse("https://login.microsoftonline.com/#{tenant}/oauth2/token")
      resource = 'https://vault.azure.net'
      checkout = Net::HTTP.new(token_uri.host, token_uri.port)
      checkout.use_ssl = true
      req = Net::HTTP::Post.new(token_uri)
      req['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = "grant_type=client_credentials&client_id=#{client_id}&client_secret=#{client_secret}&resource=#{resource}"
      get_token = JSON.parse(checkout.request(req).body)
      (get_token['access_token'] || {}).to_s
    # I removed the 200 check because it is in a rescue block so either JSON parse it or rescue and return empty object
    rescue
      {}
    end

    def akv_token_using_credentials_file(subscription_id, credentials_file)
      credentials_hash['azure_credentials'] = Tomlrb.load_file(credentials_file)
      client_id = credentials_hash['azure_credentials'][subscription_id]['client_id']
      client_secret = credentials_hash['azure_credentials'][subscription_id]['client_secret']
      tenant_id = credentials_hash['azure_credentials'][subscription_id]['tenant_id']
      akv_token(client_id, client_secret, tenant_id)
    end

    def akv_fetch_secret(client_id, client_secret, tenant, vault, secret_name, secret_version = '')
      api_token = akv_token(client_id, client_secret, tenant)
      secret_uri = URI.parse("https://#{vault}.vault.azure.net/secrets/#{secret_name}/#{secret_version}?api-version=7.0")
      header = { 'Authorization' => "Bearer #{api_token}", 'Content-Type' => 'application/json' }
      retrieve = Net::HTTP.new(secret_uri.host, secret_uri.port)
      retrieve.use_ssl = true if secret_uri.to_s.include?('https')
      get_secret_request = retrieve.get(secret_uri, header)
      get_secret = JSON.parse(get_secret_request.body)
      (get_secret['value'] || {}).to_s
    end

    def akv_fetch_secret_with_token(token, vault, secret_name, secret_version = '')
      secret_uri = URI.parse("https://#{vault}.vault.azure.net/secrets/#{secret_name}/#{secret_version}?api-version=7.0")
      header = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
      retrieve = Net::HTTP.new(secret_uri.host, secret_uri.port)
      retrieve.use_ssl = true if secret_uri.to_s.include?('https')
      get_secret_request = retrieve.get(secret_uri, header)
      get_secret = JSON.parse(get_secret_request.body)
      (get_secret['value'] || {}).to_s
    end

    def akv_fetch_vault_secrets(token, vault)
      vault_uri = URI.parse("https://#{vault}.vault.azure.net/secrets?api-version=7.1")
      header = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
      retrieve = Net::HTTP.new(vault_uri.host, vault_uri.port)
      retrieve.use_ssl = true if vault_uri.to_s.include?('https')
      get_vault_request = retrieve.get(vault_uri, header)
      get_vault = JSON.parse(get_vault_request.body)
      my_vault = {}
      this_vault = get_vault['value']
      this_vault.each do |secret|
        secret_name = secret['id'].split('/')[-1]
        secret_value = akv_fetch_secret_with_token(token, vault, secret_name)
        my_vault[secret_name] = secret_value
      end
      my_vault
    end

    def get_hashi_vault_object(vault_path, vault_address, vault_token, vault_role = nil, vault_namespace = nil)
      # Need to set the vault address
      Vault.address = vault_address
      # Authenticate with the token
      Vault.token = vault_token

      # Add namespace if passed (default is nil)
      Vault.namespace = vault_namespace

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

Chef::DSL::Universal.include ::ChefMagic::SecretsManagementHelpers
