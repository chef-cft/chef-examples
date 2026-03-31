# HowTo: Retrieving secrets from a secrets management tool
This cookbook will store examples on how to grab secrets from tools like Hashicorp Vault. In the future I would like to include examples for Akeyless.io/Aws KMS/Azure

## Before you start
### Assumptions
* This guide assumes that you have a working Vault solution up and running that you can interact with

**Note:** The way that the vault token is used in this cookbook is not the way we recommended to store the vault_token. 
This is just an example on how to communicate with the sercrets management platform. Please consider using encrypted databags or some other means to protect the vault token.

### Tested on chef client version 16+

### Cookbook

#### recipes

* hashi_vault : This is the main recipe that shows how to interact with a vault instance.

#### libraries

* hashi_vault

#### Attributes

* hashi_vault

`default['secrets_managment']['hashi']['vault_address']`

The address to the hashi corp vault *Example*:
 default['secrets_managment']['hashi']['vault_address'] = 'https://myvault.chefsuccess.io:8200'

`default['secrets_managment']['hashi']['vault_token']`

 The Vault token of the AppRole or Root(not suggested but used to for demo purposes) Example:
 default['secrets_managment']['hashi']['vault_token'] = 's.xfffffff6666666777777hhh'

`default['secrets_managment']['hashi']['vault_path']`

The path to the secrets Example:
 default['secrets_managment']['hashi']['vault_path'] = 'secret/my-app'

`default['secrets_managment']['hashi']['vault_role']`
 
The name of the app role is used. Leave an empty string if a app role is not used Example:
 default['secrets_managment']['hashi']['vault_role'] = 'web'
