# HowTo - Jenkins Pipeline examples

This document contains example files and Jenkins specific instructions. While these examples should be functional and directly consumable, they are not exhaustive and only provide the minimum recommended steps. The author's expectation is that consumers will use these examples to get started then tailor them as needed in a continuous improvement fashion.

## Before You Start

### Assumptions

* This assumes you have the ability to provision resources and/or enable the settings and options in Jenkins.
* This assumes you have the cookbooks, plans, and profiles in an individual repository.
* This assumes you have the data bags, environments, and roles in a single repository.
* This assumes all names are hard coded in pipeline files. Add dynamic processing as part of your continuous improvement after you have working pipelines.

### Tested Versions

* [Jenkins](Jenkins/README.md) - [2.190.2](https://jenkins.io/download/)

## Instructions

The general process is to copy the desired `jenkinsfile` into the root of the artifact's repo, then add the repo to Jenkins. If there are specific notes, we'll talk about them individually.

### Cookbooks

Since there are three cookbook patterns, you'll need to pick the proper example for your cookbook. You shouldn't need to change the contents of the files; however, you do need to rename it to `jenkinsfile` and place it in the root of the repo.

### Data bags, Environments, and Roles

The example for the server objects pipeline assumes you have the `chef_repo` style folder structure. If not, you'll need to adjust the paths in the `jenkinsfile` or reorganize your files to fit this format:

``` bash
├── Jenkinsfile
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
├── jenkinsfile
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

The jenkinsfile should be in the root of the repo. As with the cookbooks, we have multiple patterns.

* The Audit pattern example expects the repo to contain a full profile with an `inspec.yml` and other files.

  ``` bash
  ├── jenkinsfile
  ├── README.md
  ├── controls
  │   └── example.rb
  ├── inspec.yml
  └── libraries
  ```

* As with the effortless infra pattern and the Habitat plans, the effortless audit profile needs a `habitat` subdirectory with a full profile.

  ``` bash
  ├── README.md
  ├── controls
  │   └── example.rb
  ├── habitat
  │   ├── default.toml
  │   └── plan.ps1
  └── inspec.yml
  ```

## FAQs

1. [This section should be updated regularly as people ask about certain behaviors and you answer questions related to this example.]
