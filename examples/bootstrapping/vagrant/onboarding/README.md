# Onboarding 

`NOTE: This is not a recommended architecture but rather meant to help you get started on your journey with Chef.`

The purpose of this project is to have you become comfortable with leveraging the Chef toolkit to identify and remediate a compliance issue on a node. During this exercise you will provision, configure and use components like Chef Automate, Chef Infra Server, Chef Inspec and Policyfiles. If you find something you think should be changed, updated, added or removed please submit a Pull Request (PR). Enjoy!

## General Overview 

After working through the `Assumptions` and `Prerequisities` you will need to provision the `server.bootstrap` machine using the accompanying [Vagrantfile](./server/Vagrantfile), then adjust your `/etc/hosts` or HOSTS file on your machine to include a reference to `server.bootstrap` on `10.11.12.13`, then proceed to provision your `client.bootstrap` machine using the 
accompanying [Vagrantfile](./client/Vagrantfile). Note that before you provision either of these machines you will need to create a `settings.rb` file from the `settings.rb.EXAMPLE` in both the `client/` and `server/` directories. You will then need to adjust the value of the `SHARED_DIRECTORY` variable in each file to match the location of where you checked out this repository on your machine. This is important because both the server and client you are configuring will use this directory to created and consume key and settings files used to configure the two machines for this exercise. 

After you've provisioned each machine you will then use the address you added to your `/etc/hosts` or HOSTS file to access Chef Automate through your browser using the credentials found in the `automate-credentials.toml` file in the `SHARED_DIRECTORY` location. This credentials file was generated during the `server` bootstrap process. 

## Before You Start

### Assumptions

We assume the following:

- You have unrestricted access to the Internet.
- You have a computer capable of hosting virtual machines  (e.g. at least two cores, at least 8GB of free RAM and at least 60 GB of disk available).
- You have administrative rights to install software on your computer.

### Prerequisites

We assume you have the following software installed and/or available to you:

- The latest version of [Virtual Box](https://www.virtualbox.org/wiki/Downloads) is installed.
- The latest version of [Vagrant](https://www.vagrantup.com/downloads) is installed.
- You have access to the latest `generic` vagrant box images or an unrestricted connection to 
  the Internet to download the boxes.
- You've successfully run the command `vagrant box add` with the distribution you want to use 
  for the exercises described in this README.
  - All free `generic` boxes can be found through [vagrantup](https://app.vagrantup.com/boxes/search) or
    in the following list:

    - `generic/rhel7`
    - `generic/rhel8`
    - `generic/centos7`
    - `generic/ubuntu1804`
- You plan to use the Ubuntu 18.04 version as that was the only version tested in this process. Please submit a PR once you've successfully tested against other distributions or if you'd like to add directions for Windows.

## Provision Chef Automate with Chef Infra Server 

The first step we're taking in this exercise is to install Chef Automate with Chef Infra Server using Vagrant. To accomplish this task you will need to do the following:

* Change the `server` directory.
* Update the `Vagrantfile` with the `BOX` you want to use.
  * For example an Ubuntu box, `BOX=generic/ubuntu1804`
* Run `vagrant up`

 The `provision.sh` script will then:
  - Install the Chef Infra Server version and Automated version specified,
  - Adjust the local `/etc/hosts` file,
  - Create a user on the `server.bootstrap` machine with the name `vagrant` and the password `vagrant`,
  - Create a chef org called `bootstrap` and add an administrative and billing user with the name `souschef`,
  - Place both the user and validator pem files in the `SHARED_DIRECTORY` directory,
  - Assign the IP of `10.11.12.13` to the chef infra server on the private network,
    - `NOTE:` You will need to update the `BOX_IP` if this IP address is in use on the network
- No signed certificates are installed during this process which means when you attempt to access `Chef Automate` through your browser you will be greeted with an untrusted site/certificate warning. You will need to ignore this warning to proceed to the sign up page where you will enter your information and accept the license to sign-in,
- Once the `vagrant up` finishes you will need to confirm the `Chef Infra Server` is installed. Do the following to accomplish this task:
  - In the same directory where the `Vagrantfile` is located, run `vagrant ssh`,
  - Once in, run `head -n1 /opt/opscode/version-manifest.txt` to verify the chef server version you expected to be installed is _actually_ installed.

## Provision your Client Node and Chef Workstation

`NOTE: There are many ways to bootstrap nodes and this is but one where we co-mingle a workstation with a node. Usually you will not have a workstation as a node.`

The next step we're taking in this exercise is to install the Chef Workstation code on your client and then bootstrap the client as a node with the Chef Infra Server with a default run list including `audit` cookbook and `default` recipe. To accomplish this task you will need to do the following:

* Change to the `client` directory.
* Update the `Vagrantfile` with the `BOX` you want to use.
  * For example an Ubuntu box, `BOX=generic/ubuntu1804`
* Select which `config.rb.absolute` or `config.rb.relative` you want to link to `config.rb`. It is suggested you use the `config.rb.absolute` file.
* Run `vagrant up`

 The `provision.sh` script will then:
  - Create a user on the `client.bootstrap` machine with the name `vagrant` and the password `vagrant`,
  - Install the Chef Workstation Version specified.
  - Adjust the local `/etc/hosts` file,
  - Create a `bootstrap` directory containing the client `config.rb` and required credentials,
  - bootstrap the node,
  - fetch the SSL certificates from the Chef Infra Server,
  - upload the `audit` cookbook to the Chef Infra Server
  - run the default audit recipe using the `chef-client`.
  - login to the Chef Automate server to confirm the node is connected and working as expected.

## Clean Up

If and when you'd like to destroy the `server.bootstrap` and `client.bootstrap` machines simple do the following:

```bash
adam@hostie onboarding % cd server
adam@hostie server % vagrant destroy
    default: Are you sure you want to destroy the 'default' VM? [y/N] y
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...
```

and then

```bash
adam@hostie onboarding % cd client
adam@hostie client % vagrant destroy
    default: Are you sure you want to destroy the 'default' VM? [y/N] y
==> default: Forcing shutdown of VM...
==> default: Destroying VM and associated drives...
```

# Contributors (by last name)

Thank to those who helped with ideas or code to get this started. This work was based on the work Dina already started. Thank you Dina!

* Daniel Bright 
* Adam M Dutko
* Dina Muscanell
* Steven Tan
