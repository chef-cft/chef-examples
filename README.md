# Chef Examples

A collection of HowTo Chef examples to help you figure out how to do _that thing you really want to do_ with Chef, Habitat, InSpec and anything else Chef-related. This repo is maintained by Chef, however, feel free to request examples, or file PR's to provide examples to the Chef Community.

Note: USE AT YOUR OWN RISK!

## Automate

- [Setting Up SAML Auth in Automate with Okta](./examples/A2SamlWithOkta.md)
- [Creating a Cookbook Pipeline Using Azure DevOps](./examples/AzureDevOpsCookbookPipeline.md)
- [Set up Automate + Chef Infra Server to use RDS Aurora Postgres + AWS Elastisearch Service Backends](./examples/a2-aws-backends/a2-aws-backends.md)
- [Setup Automate with Let's Encrypt SSL Cert](./examples/A2WithLetsEncryptSSLCert.md)
- [Automate SAML with AzureAD](./examples/A2SamlWithAzureAD.md)

## Infra

- [HowTo download then upload all Chef Cookbooks from one Chef Server to another](./examples/DownloadUploadCookbooks.md)
- [Role Cookbook Model Explained](./examples/RoleCookbookModel.md)
- [HowTo bootstrap an Azure VM using an ARM template & Policyfiles](./examples/AzureArmChefClientBootstrap/README.md)
- Policyfiles:
  - [The Definitive Policyfile Implementation Guide](./examples/ChefPolicyfileWorkflow.md)
  - [The Definitive Policyfile Automation Guide](./examples/ChefPolicyFileAutomation.md)
  - [Testing Policyfiles]()
  - [Migrating to Policyfiles from Roles and Environments]()
  - []()

## InSpec

- [Inspec example of checking Netbios configuration on Windows](./examples/InspecNetBiosQuery.md)
- [Inspec example of verifying Local Administrators on Windows](./examples/InspecVerifyWindowsAdministrators.md)

## Habitat

## Other

- [Example Pipelines](./examples/pipelines/PipelineOverview.md)
- [Test Kitchen](./examples/test-kitchen/README.md)

### Contributing

1. Verify if there is a current "Example Request" issue for what you are
going to be adding content for, if not, add a new issue so it's not duplicated.
1. Fork this repo.
1. Create a named example branch (e.g. example_xyz).
1. Using the [HowTo](./HowToTemplate.md) template, write your new HowTo example.
1. Submit a Pull Request, and request review.
