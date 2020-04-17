# HowTo - Add Frontend Nodes to a Backendless Chef Deployment

This guide walks you through the process of creating a bootstrap bundle on the first Automate + Chef Infra node, and then how to 
include it in the install script with any subsequent nodes.

## Before You Start

### Assumptions

* You have setup Automate + Chef Infra using the Automate deployment method, and are using AWS/GCP or Azure database backends for Postgres and Elasticsearch, this means you have your first node done and working.
* You intend to have multiple Frontend nodes behind a load balancer.
* You understand that this is USE AT YOUR OWN RISK, unless your partnering with your CS team of course.
* You have downloaded the installer for Automate and it's the same version that you 
* You have created an Airgapped bundle and saved the file for future use (https://automate.chef.io/docs/airgapped-installation/)

### Tested Versions

* Automate + Chef Infra | [`20200408141957`]

## Guide

1. On the FIRST (remember, you should only have one node at this point) node that's been configured and is working properly, run the following command:
    ```
    sudo ./chef-automate bootstrap bundle create /tmp/bootstrap.abb
    ```
1. On the FIRST node, copy the `config.toml` that was used for the initial setup, the airgap bundle, and the `bootstrap.abb` file you just created to the NEXT node you want to bootstrap.
1. On the NEXT node, edit the `config.toml` if needed, if you're using a load balancer with it's own FQDN - then set the FQDN to the load balancer.
1. When the `config.toml` is ready, run the install script on the NEXT node as follows:
    ```
    sudo ./chef-automate deploy /etc/chef-automate/config.toml --airgap-bundle /path/to/airgap.aib --bootstrap-bundle /path/to/bootstrap.abb --accept-terms-and-mlsa
    ```
1. That should be it, work with your CS team if you have issues.

## FAQs

1. [This section should be updated regularly as people ask about certain behaviors and you answer questions related to this example.]