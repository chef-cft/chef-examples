# example_vault_chef

Example cookbook using [Vault](https://www.vaultproject.io/) to store secrets.

## References

* HashiCorp Vault - https://www.vaultproject.io
* HashiCorp Vault AppRoles with Chef - https://github.com/hashicorp-guides/vault-approle-chef
* `secrets_management` helper from [Chef Magic](https://github.com/chef-davin/chef_magic)

## Usage

This cookbook can be used as an example for interacting with a HashiCorp Vault instance to retrieve secret data using the AppRole method.

### Using with local development Vault instance

This repository includes mechanisms for setting up a local development Vault instance on your workstation to use with the cookbook for demo purposes.  Pre-built Rake tasks are present in the local `Rakefile`:

```plain
$ chef exec rake -T
rake local_vault_config  # Configure a running local vault instance
rake local_vault_start   # Create a local vault instance running on port 8200
```

* Install HashiCorp Vault locally - [https://www.vaultproject.io]
* Start the local `vault` instance (this is best done in a split terminal as the process stays open) using `chef exec rake local_vault_start`:

    ```plain
    $ chef exec rake local_vault_start
    ==> Vault server configuration:

                Api Address: http://0.0.0.0:8200
                        Cgo: disabled
            Cluster Address: https://0.0.0.0:8201
                Go Version: go1.16
                Listener 1: tcp (addr: "0.0.0.0:8200", cluster address: "0.0.0.0:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
                Log Level: TRACE
                    Mlock: supported: false, enabled: false
            Recovery Mode: false
                    Storage: inmem
                    Version: Vault v1.6.3
                Version Sha: b540be4b7ec48d0dd7512c8d8df9399d6bf84d76+CHANGES

    ==> Vault server started! Log data will stream in below:
    ```

* Configure the local `vault` instance using the rake task `local_vault_config`:
  ```plain
  $ chef exec rake local_vault_config
    Key              Value
    ---              -----
    created_time     2021-03-11T17:06:31.007421Z
    deletion_time    n/a
    destroyed        false
    version          1
    ====== Metadata ======
    Key              Value
    ---              -----
    created_time     2021-03-11T17:06:31.007421Z
    deletion_time    n/a
    destroyed        false
    version          1

    ==== Data ====
    Key     Value
    ---     -----
    key1    key1_value
    key2    key2_value
    Success! Uploaded policy: chef-policy
    Success! Enabled approle auth method at: approle/
    Success! Data written to: auth/approle/role/chef-role
    Success! Uploaded policy: chef-role-token
    Key                  Value
    ---                  -----
    token                s.c01xCqxnKcvxOcDghhHmdkkx
    token_accessor       vT3SCX3v4MHjqJlLAaHX5kCs
    token_duration       768h
    token_renewable      true
    token_policies       ["chef-role-token" "default"]
    identity_policies    []
    policies             ["chef-role-token" "default"]
    ```

* Note the `token` output from the configuration, in the above example it is `s.c01xCqxnKcvxOcDghhHmdkkx`.
    * Save this token in the `test/integration/data_bags/approle_tokens/default.json` data_bag file.
    * Save this token in the encrypted data bag `encrypted_data_bag_keys`:
        ```sh
        # cd to the test/integration directory so that it finds the data_bags path
        cd test/integration
        EDITOR=vi knife data bag edit --local-mode encrypted_data_bag_keys default --secret-file ../../files/mysecretfile
        cd ../../
        ```
* Run `kitchen test`
