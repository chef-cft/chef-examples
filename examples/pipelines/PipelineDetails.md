# HowTo - Chef Pipeline Details

This document contains example details and tool specific instructions. While these examples should be functional and directly consumable, they are not exhaustive and only provide the minimum recommended steps. The author's expectation is that consumers will use these examples to get started then tailor them as needed in a continuous improvement fashion.

## Before You Start

### Assumptions

* This assumes you have the ability to provision resources and/or enable the settings and options in The desired tool.
* This assumes you have the cookbooks, plans, and profiles in an individual repository.
* This assumes you have the data bags, environments, and roles in a single repository.
* This assumes all names are hard coded in pipeline files. Add dynamic processing as part of your continuous improvement after you have working pipelines.
* This assumes your pipeline tool has the appropriate network ACLs to communicate with you Chef server and your Habitat BLDR.
* The Azure DevOps examples do use Azure Keyvault (AKV). While this does add an additional component, AKV is extremely simple to manage and ADO has built-in functions for consuming secrets. More AKV info [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-key-vault?view=azure-devops).

### Tested Versions

* Azure DevOps - [dev.azure.com](https://dev.azure.com)
* Jenkins - [2.190.2](https://jenkins.io/download/)
* GitLab - [gitlab.com](https://www.gitlab.com)

## Instructions

The general process is to copy the desired example, renamed appropriately  (`jenkinsfile`, `gitlab-ci.yml`, or `azure-pipelines.yml`), into the root of the artifact's repo, then add the repo to the desired tool.

### Cookbooks

Since there are three cookbook patterns, you'll need to pick the proper example for your cookbook. Let's take a look at the variations between patterns and tools.

Notes:

* Legacy Berks pattern
  * ADO - Chef publishes an extension for ADO that simplifies managing the Chef server info and secrets. Our examples use these extensions whenever possible. More info [here](https://github.com/chef-partners/azuredevops-chef/wiki/getting-started).
  * GitLab-CI - These examples leverage the `chef/chefdk` docker image to reduce the effort needed to set up the Chef kit. We also need to set up two variables (`admin-pem` and `knife-rb`) in `Settings > CI/CD > Variables` in each project.
  * Jenkins - Since Jenkins vary soo much, these example assume that ChefDK or Chef Workstation are installed on the Jenkins server.
* Policyfile pattern
  * ADO - We continue to use the Chef extensions for several tasks; however, the extension doesn't support policyfiles. For the steps that interact directly with the policyfile, we call the `chef` command directly. We also fetch the `admin.pem` and `knife.rb` from Azure Key Vault.
  * GitLab-CI - Same config as Berks pattern
  * Jenkins - Same config as Berks pattern
* Modern Effortless pattern
  * ADO - We'll use the Chef Server extensions to test the cookbook. Chef also has an extension for Habitat which we'll use for several tasks. More info [here](https://github.com/chef-partners/azuredevops-habitat/wiki/getting-started).
  * GitLab-CI - We'll use the `chef/chefdk` image here as well. We'll also install Habitat at runtime. in addition to the variables above, we'll need to configure  thee more: `sig`, `key`, `cli`. These are for the Habitat signing keys along with the `cli.toml` that provide origin and token info for working with BLDR.
  * Jenkins - Along with needing ChefDK/Chef Workstation, Habitat will need to be installed. You'll also need the additional variables for Habitat.

### Data bags, Environments, and Roles

The example for the server objects pipeline assumes you have the `chef_repo` style folder structure. If not, you'll need to adjust the paths in the pipeline file or reorganize your files to fit this format:

``` bash
├── jenkinsfile
├── README.md
├── data_bags
│   ├── admin_users
│   │   ├── professor.json
│   │   └── leela.json
│   └── op_users
│       ├── bender.json
│       ├── fry.json
│       └── amy.json
└── environments
    ├── dev.json
    ├── stg.json
    └── prod.json
```

> NOTE: Since these object types aren't versioned on the server, there's not much testing that takes place.

### Plans

The `plan.sh/plan.ps1` and accompanying files should reside in a `./habitat/` subdirectory in the repository. Similar to the Effortless cookbook pattern, you'll need to define some variables: `sig`, `key`, `cli`.

``` bash
├── README.md
├── gitlab-ci.yml
└── habitat
    ├── config
    │   ├── standalone.conf
    │   └── wildfly.xml
    ├── default.toml
    ├── hooks
    │   ├── init
    │   └── run
    └── plan.sh
```

### Profiles

The pipeline file should be in the root of the repo. As with the cookbooks, we have multiple patterns.

* The Audit pattern example expects the repo to contain a full profile with an `inspec.yml` and other files. This pattern requires a couple variables to interact with Automate: `AUTOMATE_SERVER_NAME`, `AUTOMATE_USER`, `AUTOMATE_ENTERPRISE`, and `DC_TOKEN`.

  ``` bash
  ├── azure-pipelines.yml
  ├── README.md
  ├── controls
  │   └── example.rb
  ├── inspec.yml
  └── libraries
  ```

* As with the effortless infra pattern and the Habitat plans, the effortless audit profile needs a `habitat` subdirectory with a full profile. As with all the Habitat based patterns, you'll need to define these variables in your CI/CD tool: `sig`, `key`, `cli`.

  ``` bash
  ├── azure-pipelines.yml
  ├── README.md
  ├── controls
  │   └── example.rb
  ├── habitat
  │   ├── default.toml
  │   └── plan.ps1
  └── inspec.yml
  ```

## FAQs

Q: Why do some pipeline files have a note about Windows packages when others don't?

A: Habitat requires that one use the target platform when building packages. It doesn't matter for the other tasks (upload/promote) so the pipelines use linux containers since they are faster than Windows containers.

Q. How do I securely provide tokens, passwords, keys, etc. to the pipeline?

A. While there are multitude of secrets management tools/services out there, at some point, we have to provide a basic secret. For our purposes, we'll use some sort of variable in the CI/CD. Most CI/CD tools have a way to protect a variable and while it's not 100%, it's secure enough for our examples.

Q. How do I provide complex strings such as `knife.rb` or `origin-20190000000.pub` data to the pipeline?

A. The easiest way is to encode the data using `base64`. Encode the text, then store it in a variable. To consume it, decode the specified environment variable.

  Encode:

  ``` bash
  cat knife.rb | base64
  ```

  ``` powershell
  [string]$sStringToEncode = $(Get-Content knife.rb -Encoding UTF8 -Raw)
  $sEncodedString = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($sStringToEncode))
  Write-Output $sEncodedString
  ```

  Decode:

  ``` bash
  echo $knife | base64 -d > .chef/knife.rb
  ```

  ``` powershell
  $sEncodedString = $Env:knife
  $sDecodedString = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($sEncodedString))
  write-host $sDecodedString | Out-file .chef/knife.rb
  ```

Q: There are several variables in the different sections, can you list them and what they do?

A: Sure!

| Variable Name | Description | Purpose/Usage |
| ---           | ---           | ---         |
| admin-pem | Private key of a Chef Server user | Upload artifacts to Chef Server |
| knife-rb | Config file for `knife` | Used to tell `knife` information about the target Chef Server.|
| sig| Origin Signature | Used in conjunction with the private key to sign packages |
| key | Origin Private key | Used in conjunction with the signature to sign packages |
| cli | Habitat config file `cli.toml` | Provides info like BLDR token and origin name to the hab executable |
