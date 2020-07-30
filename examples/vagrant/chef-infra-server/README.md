# HowTo: Use Vagrant and Virtual Box to create a Chef Infra Server

- Use the vagrantfile to spin up a stand alone chef server for older (or newer) versions.

- This can be used to for:
  - In-place upgrades from chef-server 12.x to 13.x on your local machine for POC testing
  - Verifying migration steps from [here](https://blog.chef.io/migrating-chef-server-knife-ec-backup-knife-tidy/), with the assumption the chef-server has nodes on it or [chef-load](https://github.com/chef/chef-load) was run.
    - For migrations, two instances are required
  - A need to have a chef-server of a specific version that is ephemeral

## Before You Start

### Assumptions

- Vagrant is installed. [Download here](https://www.vagrantup.com/downloads)
- Virtual Box is installed. [Download here](https://www.virtualbox.org/wiki/Downloads)
- This code assumes you'll be using a `generic` image
  - For example, `vagrant box add generic/ubuntu1604` or `vagrant box add generic/rhel6`
- A `vagrant box add` of the type of OS you want to install the chef server on has been executed
  - All free boxes can be found [here](https://app.vagrantup.com/boxes/search)
- The ip address `10.11.12.13` is not in use
  - Change the `BOX-IP` in the `vagrantfile` if it is in use

### Versions tested

- Chef Server Stand Alone Install & In-Place Upgrade
  - `generic/rhel6`
    - `chef-server 12-17-15`
    - `chef-server 12-3-0`
  - `generic/rhel7`
    - `chef-server 13-2-0`
  - `generic/rhel8`
    - `chef-server 13-2-0`
  - `generic/ubuntu1604`
    - `chef-server 12-17-15`
    - `chef-server 12-3-0`
  - `generic/centos7`
    - `chef-server 12-17-15`
  - `generic/ubuntu1804`
    - `chef-server 13.2.0`

- Chef Server Migration
  -`generic/ubuntu1604` to `generic/ubuntu1804`, `chef-server 12.17.15` to `chef-server 13.2.0`

## Provision a Chef Infra Server using Vagrant and Virtual Box

- Update the `Vagrantfile` with the `BOX` you want to use.
  - For example an Ubuntu box, `BOX=generic/ubuntu1604`
- Update the `CHEF_SERVER_VERSION` if desired
- Go into the directory where the `Vagrantfile` is located and run `vagrant up`
- The script will:
  - Install the Chef Server Version specified
  - Create a user `vagrant` with the password `vagrant`
  - Create a chef org called `vagrant-dev`
  - Place both the user and validator pem files in the home directory
  - Assign the IP of `10.11.12.13` to the chef infra server on the private network
    - Update the `BOX_IP` if this IP address is in use on the network
- **No certificate is installed during this process.**  A cert warning will occur if trying to hit the front end.
  - If configuring a `knife.rb` or `config.rb` and a cert is not installed, add the following line:
    - `ssl_verify_mode          :verify_none`
- To export .pem(s) on the local machine go into the directory where the `Vagrantfile` is and run:
  - `vagrant ssh -c "sudo cat /home/vagrant/vagrant-user.pem" > vagrant-user.pem`
  - `vagrant ssh -c "sudo cat /home/vagrant/vagrant-dev-validator.pem" > vagrant-dev-validator.pem`

## How to confirm the chef server is installed

- In the same directory where the `Vagrantfile` is located, run `vagrant ssh`
- Once in, run `head -n1 /opt/opscode/version-manifest.txt` to verify the chef server version you expected to be installed is _actually_ installed

## FAQ

- Use centos unless a RHEL license is available to you/your organization.

- For migrations, spin up two instances in two separate directories, make sure to change the IP address on one instance.
