# HowTo - Jenkins Pipeline examples

This document contains example details and tool specific instructions. While these examples should be functional and directly consumable, they are not exhaustive and only provide the minimum recommended steps. The author's expectation is that consumers will use these examples to get started then tailor them as needed in a continuous improvement fashion.

## Before You Start

### Assumptions

* This assumes you have the ability to provision resources and/or enable the settings and options in The desired tool.
* This assumes you have the cookbooks, plans, and profiles in an individual repository.
* This assumes you have the data bags, environments, and roles in a single repository.
* This assumes all names are hard coded in pipeline files. Add dynamic processing as part of your continuous improvement after you have working pipelines.
* The Azure DevOps examples do use Azure Keyvault (AKV). While this does add an additional component, AKV is extremely simple to manage and ADO has built-in functions for consuming secrets. More AKV info [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-key-vault?view=azure-devops).

### Tested Versions

* Azure DevOps - [dev.azure.com](https://dev.azure.com)
* Jenkins - [2.190.2](https://jenkins.io/download/)
* GitLab - [gitlab.com](https://www.gitlab.com)

## Instructions

The general process is to copy the desired file (`jenkinsfile`, `gitlab-ci.yml`, or `azure-pipelines.yml`) into the root of the artifact's repo, then add the repo to the desired tool.

### Cookbooks

Since there are three cookbook patterns, you'll need to pick the proper example for your cookbook. You shouldn't need to change the contents of the files; however, you do need to rename it to `jenkinsfile` and place it in the root of the repo.

### Data bags, Environments, and Roles

The example for the server objects pipeline assumes you have the `chef_repo` style folder structure. If not, you'll need to adjust the paths in the `jenkinsfile` or reorganize your files to fit this format:

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

### Plans

The `plan.sh/plan.ps1` and accompanying files should reside in a `./habitat/` subdirectory in the repository.

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

* The Audit pattern example expects the repo to contain a full profile with an `inspec.yml` and other files.

  ``` bash
  ├── azure-pipelines.yml
  ├── README.md
  ├── controls
  │   └── example.rb
  ├── inspec.yml
  └── libraries
  ```

* As with the effortless infra pattern and the Habitat plans, the effortless audit profile needs a `habitat` subdirectory with a full profile.

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
