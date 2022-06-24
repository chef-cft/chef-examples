# Gitlab CI pipelines for use with internal chef supermarket and policyfile repo

These recommended pipelines are from Corey Hemminger and are just 1 opinionated way of setting up gitlab ci pipelines. 
Feel free to modify as needed.

## Overview

These pipelines are setup to do linting/integration(test-kitchen) tests and deploy cookbooks to a central artifact repository
like an internal chef-supermarket server. From there you'd update your named policyfile lock files in the chef-repo/policyfiles
folder to pull all versions of the cookbooks and their dependencies from internal and/or external supermarket servers to
your local machine. Then you'd push the policyfile lock to chef-server which will upload all the cookbooks and make the 
policy ready for assignment to nodes.

## Assumptions

- Using internal Chef Supermarket server with anonymous access for pulling cookbooks
- Using central chef-repo for policyfiles associated to servers
- Using a seperate repo for each cookbook and not mono repo with all cookbooks in them
- You have working kitchen.yml, kitchen.dokken.yml, kitchen.exec.yml files for testing against various OSs. The latter 2 are for running linux and or windows pipelines in gitlab ci

## Setup

I recommend creating a seperate central repo to house these pipline files. This gives you 1 place to modify pipelines
for all cookbooks and can override certain settings in the calling .gitlab-ci.yml file.

- The chef_cookbook-gitlab-ci.yml file is the file that you'd put in all cookbook repos with file name .gitlab-ci.yml
- The chef_cookbook_code_pipelines.yml would live in the central repo and will be called by the cookbook repo .gitlab-ci.yml file
- The chef_repo_code_pipelines.yml would live in the central repo and will be called by the chef-repo .gitlab-ci.yml file to deploy changes to databags and policyfile locks
- In the chef-repo .gitlab-ci.yml file you'd call the chef_repo_code_pipelines.yml like in the cookbook example

### The cookbook repos will need gitlab ci variables:

- CHEF_SUPERMARKET_USER setup as a variable
- CHEF_SUPERMARKET_KEY setup as a masked file

### The chef-repo repo will need gitlab ci variables:

- CHEF_ADMIN_KEY setup as a masked variable

## How it works

### Cookbook pipelines

The cookbook repos .gitlab-ci.yml will pull in the chef_cookbook_code_pipelines.yml file and run the pipelines defined.
Any keys in the .gitlab-ci.yml file will override values in the called pipeline. In this repos example the
chef_cookbook-gitlab-ci.yml will call the chef_cookbook_code_pipelines.yml file and would override the kitchen_dokken job
OS matrix to only run the default suite against amazonlinux2 machine instead of the default machines defined in
chef_cookbook_code_pipelines.yml file.

The Cookbook pipelines will run various linting stage tests in parallel based on the rules checking if any files the linter is
made for have been modified or added. If not that job will not run. The linting jobs will run on all branch pushes and
merge request pushes.

The Integration stage jobs will run with a dependency on cookstyle lint job. The kitchen_dokken and or kitchen_exec jobs
will run if their coresponding file exists. This allows you to control which JOBS/OSs are tested by adding the kitchen.dokken.yml
file for linux and kitchen.exec.yml file for windows. If both exist both jobs will run against the OS's defined in the pipelines
parallel matrix section.

The deploy stage job runs on merge to main or master branch and will run the knife command to upload the cookbook to your
internal supermarket server.

### Chef-repo pipeline

The chef-repo pipeline will run linting stage to verify your policyfile locks and ruby policyfiles are syntactically correct
as well as any markdown or yaml files if they've been added/modified in the repo.

The deploy stage will automatically deploy any databags that have been changed. It will also grab any policyfile locks
that have changed and deploy them to the dev policygroup automatically. The prod deploy job does the same thing but has
a manual wait till someone clicks in gitlab the run job button to deploy the changes to the prod policy group.

## Example Policyfile contents

### Cookbook Policyfile.rb

```ruby
# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'example_application'

# Where to find external cookbooks:
default_source :supermarket, 'https://chef-server.example.com' # Internal supermarket url
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'test::default'

# Specify a custom source for a single cookbook:
cookbook 'autopatch_ii', path: '.' # Local filesystem source for cb testing
cookbook 'test', path: './test/cookbooks/test' # Local cb test folder for cb testing
```

#### Notes:

- The first default_source overrides any cookbooks that may be found in other default_source lines, internal supermarket is then highly recommend to be primary source if you want to fork and host any changed community cookbooks by the same coobook name
- For Higher security it is recommended to only use an internal supermarket and any community cookbooks that need to be used would be uploaded to the internal supermarket after review and approval by security or approval authority
- Any cookbook lines will override any cookbooks with the same name found in the default_source
- This example is an application cookbook that is resource driven and doesn't have any recipes or attributes. The test directory then contains a test cookbook with a recipe calling the resource and metadata depending on actual cookbook name. The run_list then points to that test cookbook for testing purposes

### Chef-repo named policyfile example_role.rb

```ruby
# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

# A name that describes what the system you're building with Chef does.
name 'example_role'

# Where to find external cookbooks:
default_source :supermarket, 'https://chef-server.example.com' # Internal supermarket url
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'cookbook_example_role::default'
```

#### Notes:

- First 3 notes from above example are true here
- This is an example of a named polcyfile in a chef-repo/policyfile folder with filename `example_role.rb`
- The run_list here is pointing to a role cookbook with the name `cookbook_example_role` and it's default recipe. This can also be an `[]` of recipes for run_list
- For named policyfiles you should be using your default_sources only for pulling all cookbooks and dependencies
- Only use cookbook line if needing to pull a cookbook from another source due to availability or for a temporary git fork that you may have that fixes a bug while you are waiting to get it merged and released to central source like community supermarket
- Policyfile locks generated off these name policyfiles should be what get uploaded to chef-server and have nodes assigned to them and a policy group
