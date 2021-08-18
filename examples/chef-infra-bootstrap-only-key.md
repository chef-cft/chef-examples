# Creating a Bootstrap-only Key for Chef Infra Server

In some cases, it is helpful for an organization to want to create keys which can be used to bootstrap new clients to
a Chef Infra Server without additional or undesired access levels.

This is intended for reference only and should be validated and tested within a safe development environment.  See [https://docs.chef.io/server_orgs/](https://docs.chef.io/server_orgs/) for additional details on permissions for objects with Chef Infra Server.

## Requirements

* Administrative access to the Chef Infra Server organization which will have the new bootstrap client created.
* Chef Workstation

## Create a group with specific permissions

* Create a new group which will have bootstrap-only permissions that we will adjust assignments for.  In this example, this group will be called `bootstrap`

    ```sh
    knife create group bootstrap
    ```

* Apply explicit permissions to the `bootstrap` group to allow it to create new clients and
nodes but not update anything which already exists.  Below are examples which could be used for minimal access.

    ```sh
    knife acl add group bootstrap containers clients create,read
    knife acl add group bootstrap containers nodes create
    ```

* Create a new _client_, this is what will be used to authenticate similar to a validator client.  Save the
key for the client once it gets created.

    ```sh
    knife create client bootstrapclient
    ```

    ```json
    {
    "name": "bootstrapclient",
    "validator": false,
    "admin": false,
    "chef_type": "client",
    "create_key": true
    }
    ```

* Add the new `bootstrapclient` user to the bootstrap group and remove it from the `clients` group

    ```sh
    knife group add client bootstrapclient bootstrap
    knife group remove client bootstrapclient clients
    ```

## Validation

* Test it out!  In this example, the created client key was saved as `bstrap.pem` locally and
it was verified that it cannot read data which has not been explicitly granted.

    ```plain
    $ knife client create testing -u bootstrapclient --key bstrap.pem -d
    Created client[testing]
    -----BEGIN RSA PRIVATE KEY-----
    MIIEowIBAAKCAQEAqsrVkkmJgd3ig5DSZb7JoFntNMJRPy3fXS7zdRImoVwPgTjR
    ... truncated ...
    neQErkFabUrj0aUPgN6/CoNb/ZnIChK2qDUWa8lpya67Oqt07NcB
    -----END RSA PRIVATE KEY-----
    ```

    ```plain
    $ knife node create testing -u bootstrapclient --key bstrap.pem -d
    Created node[testing]
    ```

    ```plain
    $ knife data bag show bag1 item1 -u bootstrapclient --key bstrap.pem
    ERROR: You authenticated successfully to https://chef.server.fqdn/organizations/cslocal as bootstrapclient but you are not authorized for this action.
    Response:  missing read permission
    ```

    ```plain
    $ knife node list  -u bootstrapclient --key bstrap.pem
    ERROR: You authenticated successfully to https://chef.server.fqdn/organizations/cslocal as bootstrapclient but you are not authorized for this action.
    Response:  missing read permission
    ```

    ```plain
    $ knife client list  -u bootstrapclient --key bstrap.pem
    bootstrap
    bootstrap-client
    bootstrapclient
    client01
    client02
    client03
    client04
    cslocal-validator
    testing
    $ knife data bag list  -u bootstrapclient --key bstrap.pem
    ERROR: You authenticated successfully to https://chef.server.fqdn/organizations/cslocal as bootstrapclient but you are not authorized for this action.
    Response:  missing read permission
    ```
