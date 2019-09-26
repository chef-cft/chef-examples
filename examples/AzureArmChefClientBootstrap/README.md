## HowTo - Bootstrap Chef Infra Client to an Azure VM using an ARM template and Policyfiles

This how-to will walk you through a basic bootstrap scenario for an Azure VM. By following this guide, you'll accomplish the following:

* Create a Blob Storage Container in Azure that contains your bootstrap scrip and validation pem.
* Create an ARM Template that reads the contents of the Blob Storage Container and deploys a VM with Chef Infra Client boostrapped and registered to your Chef Infra Server.
* Validate the VM has been deployed and is checking into Automate.

### Before You Start

**Assumptions** -- This guide assumes that you, as the reader, have the following already setup.
* A working Azure account with the following already created:
  * Permissions to create:
    * Virtual Machine
    * Virtual NIC
    * Virtual Network
    * Public IP
    * Storage Account
    * Disk
* Access to the proper Windows Azure images.
  * 2016-Datacenter (this is what's used in the guide)
* [Windows Azure Powershell `2.7.0`](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-2.7.0) (This was tested on a Windows 10 workstation)

**Versions Tested On**
* Chef Infra Client | `15.3.14`
* Chef Infra Server | `12.17.33`
* Chef Automate | `20190904132002`

### Part 1. Stage the `azuredeploy.json`, `boostrap.ps1` and validation pem locally
In this step, you're going to pull down the example bootstrap script from this repo, you'll modify it, and get it ready to upload along with your validation pem for the next step.

1. Pull down the [bootstrap.ps1](./bootstrap.ps1) and put it into a directory on your local workstation.
1. Open the file in your favorite editor and update all of the variables on lines 4-15 to match your setup. Only change things past line 15 if you know what you're doing.
1. Next, go get your validator pem file and put it in the same directory, make sure the name of the validator file is the same as your validator name.
1. Finally, pull down the [azuredeploy.json](./azuredeploy.json) and [azuredeploy.parameters.json](./azuredeploy.parameters.json) files and put them into the same working directory as the other files.
1. Once these 4 files are ready to go, move on to Part 2.

### Part 2. Create Blob Storage Container & SAS Token
We're going to create the storage account + container in the Azure GUI, I know this can be done using Terraform, ARM templates, etc... but for the sake of this excercise, it's good to walk through the process first.

1. In Azure, click "Storage Accounts" -> then "+ Add"
1. Fill out the first tab, in my example below, I create a new Resource Group, however you can use an existing one if you'd like:
![](images/step-1a.png)
1. Next, click "Review + Create" - you can go through all of the steps in the wizard if you'd like, but we're just going to get'er'done here. Once you confirm, you'll be taken to a page that says "Your deployment is underway" - just wait for that to complete before moving on.
1. Once it completes, click on "Go to resource"
1. Click on the box labelled "Blobs"
1. Click on the "+ Container" an create a new container named "client-bootstrap", leave it as private.
![](images/step-1b.png)
1. Click on your newly created container, you should now see nothing in it.
1. Next, click "Upload" and upload the 2 files you staged in Part 1.
1. You should now see both files in the container as below, my client is named "dbright" so my validator is named `dbright.pem`.
![](images/step-2c.png)
1. Now, for each file, we're going to generate an SAS token, so first click on the `bootstrap.ps1` file, then click on the "Generate SAS" tab.
1. Change the settings to your liking, you can set the token to expire quickly or make it longer lived. Ideally, this will be part of a pipeline process so the tokens should always be short-lived.
![](images/step-2d.png)
1. Next, click "Generate blob SAS token and URL"
1. Copy the "Blob SAS URL".
1. Open up the `azuredeploy.parameters.json` file you pulled down in Part 1. Update the value for the `bootstrapURL` parameter with the URL you copied in the previous step.
1. Repeat the process for the `VALIDATOR.pem`, making usre the URL is updated in the parameters file as well.
1. Verify that all other parameters have been set (especially if the say `CHANGEME`!)

### Part 3. Deploy the ARM Template and Validate

1. In Windows, open Powershell and navigate to the directory you have your files stored in.
1. Be sure to logon to Azure by using `Connect-AzAccount` before proceeding.
1. Next, change the following code snippet to match your ResourceGroupName and run it you can also change `ChefClientBootstrap` to whatever you want:
    ```powershell
    New-AzResourceGroupDeployment -Name ChefClientBootstrap -ResourceGroupName CHANGEME `
    -TemplateFile ./azuredeploy.json `
    -TemplateParameterFile ./azuredeploy.parameters.json
    ```
1. You can follow-along in Azure if you want, however I just open up Automate and wait to see my new node get created on the dashboard. Once I see it, I can also go inspect the Chef Infra Client run to see if it converged succesfully. I've found this can take up to 10 minutes, so be patient. Here's my node showing up in Automate:
![](images/step-3a.png)
![](images/step-3b.png)
1. Here's what my completed Powershell output looks like:
   ```powershell
    PS C:\git\azure-bootstrap\chef-client-policyfiles> New-AzResourceGroupDeployment -Name ChefClientBootstrap -ResourceGroupName dbright `
    >>   -TemplateFile ./azuredeploy.json `
    >>   -TemplateParameterFile ./azuredeploy.parameters.json


    DeploymentName          : ChefClientBootstrap
    ResourceGroupName       : dbright
    ProvisioningState       : Succeeded
    Timestamp               : 9/26/2019 3:17:35 PM
    Mode                    : Incremental
    TemplateLink            :
    Parameters              :
                            Name                Type                       Value
                            ==================  =========================  ==========
                            adminUsername       String                     dbright
                            adminPassword       SecureString
                            dnsLabelPrefix      String                     myawsmvm01
                            bootstrapURL        SecureString
                            validatorURL        SecureString
                            vNicName            String                     myVNic
                            vNetName            String                     myVNet
                            pubIPName           String                     myPubIP
                            vmName              String                     dbrighttest01
                            windowsOSVersion    String                     2016-Datacenter
                            location            String                     eastus

    Outputs                 :
                            Name             Type                       Value
                            ===============  =========================  ==========
                            hostname         String                     myawsmvm01.eastus.cloudapp.azure.com

    DeploymentDebugLogLevel :
    ```


### FAQs

1. [This section should be updated regularly as people ask about certain 
behaviours and you answer questions related to this example.]