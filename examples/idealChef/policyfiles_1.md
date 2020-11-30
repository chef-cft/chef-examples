# Policyfile In Action

## The Policyfile Explained (further)
_This is not exhaustive, just in addition to the information already located
[in the Chef Docs about Policyfiles](https://docs.chef.io/policyfile/)._

### **Part I - What is a Policyfile?**
Policyfile is often confused with a single file or as an entirely new way of 
"doing" Chef. In reality, _it's less about how you write cookbooks, and more 
about how you organize and deploy them_.
* Official Chef Documentation states - 

  > "A Policyfile is an optional way to manage role, environment, and community cookbook data with a single document that is uploaded to the Chef Infra Server. The file is associated with a group of nodes, cookbooks, and settings. When these nodes perform a Chef Infra Client run, they utilize recipes specified in the Policyfile run-list."
* The description above applies to only one part of the components that make up
a "Policyfile", referred to as the Policyfile Artifact. However, there is a 
process to create that artifact which will be covered below. Just know that
there are **two types of Policyfile Artifacts**, they are -
  * `Policyfile.lock.json` - this is the file that is created when running the
  `chef install` command (more on that later.)
  * A **Policyfile Archive** - this is created _from_ a `Policyfile.lock.json` 
  and include everything necessary to deploy _itself_ onto a node, including the
  pre-compiled `run_list`, all necessary cookbooks and defined attributes.
    * Note: _Useful for deploying to nodes that aren't connected to a Chef Infra
    Server._
    * Note: _The preferred way to create, push and store Policyfiles because it
    creates an artifact that can be referenced - great for pipelines and 
    backups._
### **Part II - How is a Policyfile Created?**
A Policyfile can be created in two ways, either way is fine it really just
depends on the scenario.
#### **Step 1** - Generate the `Policyfile.rb`
* _**First way**:_ You can use the Chef CLI command  `chef generate cookbook 
my-cookbook` to generate an empty **Policyfile Cookbook**. 
  
  More info:
  
  * A "Policyfile Cookbook" is the default type of Chef Cookbook. It
  consists of a complete cookbook structure, as well as a `Policyfile.rb` in 
  the root of the cookbook. The `Policyfile.rb` is auto-populated with the 
  cookbook name (which is also the Policy name), as well as the path to the 
  local cookbook that is associated with it (`cookbook 'my-cookbook, path: '.'`
  ).
  * The "Policyfile Cookbook" also auto-populates the `Policyfile.rb` with a 
  default `run_list` which maps to the default recipe of the associated 
  cookbook.
  * Note: _Useful when creating a new cookbook from scratch_
* _**Second way** (optional):_ Simply create a **`Policyfile.rb`** file, then
populate it with all of the required info. It can be stored anywhere, as long as
it exists on a workstation that has access to the defined cookbook sources, 
either local or remote.

  More Info:

  * A `Policyfile.rb` can exist either with a cookbook, or without a cookbook - 
  it is the mechanism used to pull together all required cookbooks and their 
  dependencies (more about that in the next section) into a single location and 
  when it's job is done, it then creates a file named `Policyfile.lock.json`.
  * Note: _Useful when updating an existing cookbook to use Policyfile_ 
#### **Step 2** - Create the **`Policyfile.lock.json`** file
1. In the same directory as your `Policyfile.rb`, run the command `chef install`
. This will generate a new file in the same directory called 
`Policyfile.lock.json`.
#### **Step 3** - Create a **Policyfile Archive** (optional, but strongly recommended)
1. Continuing from Step 2, after you have created the `Policyfile.lock.json`, 
you can create a file that contains everything required to deploy to a node by
running the following command from the same directory as the lock file -
    ```shell
    chef export Policyfile.lock.json /path/to/output/ -a
    ```
    This will create a file with the Policy name and revision ID in the name of
    the file, you can then use it later either by pushing to the Chef Infra 
    Server, or using Chef Zero.

### **Part III - How is a Policyfile Tested, Stored and Deployed?**
#### **Step 1** - Testing Policyfiles
Policyfiles are very simple in their complexity, and other than syntax/linting
issues that can be caught by running `cookstyle` against the Policy, there's not
really much "testing" of Policyfiles to be done. However, Policyfiles tie 
together multiple upstream policies and cookbooks, and define a `run_list`, and
that should definitely be tested using Test Kitchen (to validate the converge
happens without errors, and as expected), and Inspec (to validate the expected
results of the configuration application.) Taking all of that into 
consideration, here is a list of how Policyfiles should be tested:
1. **Cookbook Unit Testing (optional)** - It's assumed that cookbooks that are 
included ina Policyfile have already been unit tested using ChefSpec (not always 
necessary), you _can_ unit test the Policyfile cookbook if you want, but
typically this type of testing is reserved for very complex cookbooks and
usually not necessary for a Policyfile cookbook. For more information, and to
help you determine if you really need to do unit tests or not, see the 
[ChefSpec GitHub repo](https://github.com/chefspec/chefspec) for more info.
2. **Cookstyle Linting** - It's always a good idea to run the `cookstyle` command
(built-in to Chef Workstation) before building (`chef install`) or committing
your code into source control. It highlight **style**, **syntax**, and **logic**
mistakes in your Policyfile (and Policyfile cookbook), and you can also pass in
the auto-correct flag (`-a`) to have `cookstyle` automatically correct a number
of the mistakes it finds. More info on the official tool can be found on the
[Cookstyle GitHub repo](https://github.com/chef/cookstyle).
3. **Integration Testing** - 
#### **Step 2** - Storing Policyfiles
* _**Store as Archive Using `chef export` (Recommended)**:_ - In Step 3 above, 
you created a Policyfile Archive. This is a `*.tgz` file that can be stored on 
any local or remote storage solution. It is recommended to store all created 
Archive files in a nested directory structure, for example, if I have a Policy 
named `epic-app` and the Policyfile Archive that was created looks like this:
    ```
    epic-app-64e62070985fc462762c8db348ada2201b513d210c70349479929a153fdcc74f.tgz
    ```
    A good storage strategy is to keep all archive files stored in a directory
    hierarchy that looks like this:
    ```
    policies
    ├── epic-app
    │   ├── epic-app-64e62070985fc462762c8db348ada2201b513d210c70349479929a153fdcc74f.tgz
    │   └── epic-app-962763fd7c1731b2825d89293dc8e4ea5d6b74497d7df3a0a6a1196aede19487.tgz
    ├── another-policy
    │   ├── another-policy-77323987nbasdf0d9078cfadf00f9879879879as7d9f8asf7992909dasfpoof9.tgz
    │   └── another-policy-87980hafsd8fyhnljh94382y9hg30h80fh97h97sga97h9749t349bg97bg97has.tgz
    │
    ... continued ...
    ```
    These files can be kept in any regularly backed up storage solution, such as
    an S3 bucket, Azure Blob Storage Container, or GCS, and referenced as 
    needed.
    
    **Pros:**
    * The entire Policyfile is immutable and locked when creating an archive,
    meaning it cannot be changed. This follows the general philosophy of 
    Policyfile of "create once, deploy many".
    * The archive can be re-used as a rollback mechanism if needed, this is
    because it can be re-pushed to the Chef Infra Server, or re-deployed via
    Chef Zero whenever required.
    * The archive is portable, and can be used by many processes, such as 
    deployment pipelines, image builds and ad-hoc Chef Infra Client runs.
    * It doesn't require the `Policyfile.lock.json` to be stored in SCM, this is
    beneficial because the `lock` file may contain sensitive data if attributes
    are being defined at the Policy level.
    
    **Cons:**
    * Adds a few more steps to the CI/CD pipeline process.
2. _**Store `Policyfile.lock.json` File in SCM**_: - When the 
`Policyfile.lock.json` is generated, it can then be stored in Source Control
Management (GitHub, Bitbucket, GitLab to name a few.) This way is not
recommended for any production workflow, however it's being included here for
the sake of listing the reasons why this is true.

    **Pros:**
    * Simple process that's good for testing Policyfile workflow outside of a
    production environment.
    
    **Cons:**
    * Even though the `lock` file is stored in SCM, every time a cookbook cache
    needs to be built, you will have to re-run `chef install` in order to pull
    them in to the local cache. This is problematic in a pipeline, because 
    the remote cookbooks might have changed between the time you ran and tested
    the Policy on your local workstation and the time `chef install` was run as
    part of a pipeline job, causing potential drift.
    * There is no way to "roll back" to a previously known working Policy, this
    is because the `lock` file just describes what is converged, but doesn't
    actually contain all of the required elements for a converge, such as an
    archive does.
    * Adds complexity to a pipeline, the job server that runs the `chef push`
    command will need to either have all cached cookbooks available to it, or
    will need to delete and re-create the `lock` file and cache all of the
    required cookbooks prior to running the `chef push` command.
    * **TL;DR** - Use Policyfile Archive as your storage and delivery mechanism
    it is the way.

#### **Step 3** - Deploying Policyfiles

### **Part IV - How is the Policyfile used, and what does it do?**
* The `Policyfile.rb` is used in three ways:
  * When running the 
  [`chef install`](https://docs.chef.io/policyfile/#chef-install) 
  or [`chef update`](https://docs.chef.io/policyfile/#chef-update) commands (
  that's the first two).
  * When using Test Kitchen, Test Kitchen will read the `Policyfile.rb` and 
  perform it's own `chef install` before proceeding in order to make sure it's
  not using any cached data during it's run.
* **`Policyfile.lock.json`**

  The previously mentioned `Policyfile.lock.json` is a file that contains all of
  the metadata required for the Chef Infra Client to perform a client run. This
  includes:
  
  * A `revision_id` for the Policyfile that uniquely identifies the Policy and
  associated archives that are created from it.
  * The `name` of the policy.
  * The `run_list` of the policy, this is the entry point for the Chef Infra 
  Client when it begins it's run.
  * `included_policy_locks` - simply describes any upstream policies that were
  included in the `Policyfile.rb`.
  * `cookbook_locks` - these are the specific names, versions and unique 
  identifiers associated with each cookbook for the entire dependency chain. 
  These cookbooks are stored in your local cookbook cache when you run `chef 
  install`, and are then uploaded to the Chef Infra Server when you run the 
  `chef push` command.
  * Attributes that are defined at the `Policyfile.rb` level are also included
  in this file, however most use-cases involve using Attribute Data Bags, which
  give more flexibility to the use of attributes in a more dynamic manner.
  * Other metadata is also included and included in the official docs or can be
  interpreted from the Source Code.

* **Dependency Solving (depsolving)**

  When generating the lock file, the `chef install` command retrieves all 
  cookbooks required by the `run_list`, as well as their dependencies, it always
  uses the `metadata.rb` that is associated with the cookbook to determine  the 
  version of the dependency it needs to retrieve, if no version is defined, it 
  will retrieve the latest version of the dependent cookbook. This is similar to
  how Berkshelf operated, meaning if you want to assure there is no unwanted 
  cookbook version drift before the lock is generated, all upstream cookbooks 
  should have versions pinned in `metadata.rb`.
* **Version Pinning**

  If an upstream cookbook doesn't have a version pin for a specific dependency,
  but you want to ensure the version of that dependency is exactly what you want
  it to be, you can specify a `cookbook` source for the cookbook in question,
  specifically stating where to pull the cookbook from, and what version to pull.
  That way, even if the cookbook isn't pinned in an upstream cookbook, you will be
  able to make sure the version you want is always used - this is handy for public
  cookbooks that aren't under your organizations control.

## Policy Hierarchy
* Policies are best used in a nested hierarchical manner.

## Base Policies
* Policies that contain resources, libraries and default `run_list`'s for all
other policies that include them. These Policies are not meant to be deployed
directly to a node, but rather included in other downstream policies via the
`include_policy` stanza.
* Usually include agents that are required to be installed to all nodes in an
organization.
* Can either have a default `run_list`, or a collection of recipes with an empty
`run_list`.
  * When using a default `run_list`, this means that what the policy converges 
  is completely controlled by the policy itself, with attributes being the only
  things that can change downstream.

    **Usually used by a centralized Chef team**
  * When using an empty `run_list`, this means that all resources and libraries
  will be pulled in and available to other cookbooks in the policy, but wont' be
  used unless a recipe in another cookbook calls for it to be used. 
    
    **Usually used by a distributed Chef team**
## Library Policies
* Library policies are policies that contain resources and libraries that are
used **any** other policies. These policies will always have a `run_list` that
is empty because they are not expected to make any changes to a node, but rather
provide the means for downstream policies to make changes.
## Deployable Policies
* Deployable Policies tie together **Base Policies** and **Library Policies**,
as well as the cookbook that is associated with itself into a single, deployable
Policy.
* The cookbook that is associated with a Deployable Policy has the recipe(s)
required to make the necessary changes on a node.
* The `metadata.rb` of the cookbook doesn't need to have any version pinnings,
and doesn't even need to have it's `version` changed - that's because it will
always use the upstream policies that have already been depsolved and have the
required cookbook versions already included. This means that the right versions
of all dependent cookbooks will always be used by default.
## Policyfile Templates

## Attribute Data Bags

## Policy Groups

