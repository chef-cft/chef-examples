[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12'

# Modify these variables, you can remove the <:CUSTOMPORTIFNEEDED> if you're running Chef Infra Server on the standard HTTPS port
$ChefServerURL = 'https://YOURURL<:CUSTOMPORTIFNEEDED>/organizations/YOURORG'
# The .pem file you have uploaded to Blob Storage should match the VALIDATORNAME below - e.g. VALIDATORNAME.pem
$ValidatorName = 'VALIDATORNAME'
$ChefRootDir = "c:\chef"
$ChefClientRBFile = "client.rb"
$ChefFirstBootFile = "first-boot.json"
$ClientPolicyGroup = "POLICYGROUPNAME"
$ClientPolicyName = "POLICYNAME"
# Change this to :verify_peer if you have a valid SSL cert and know the Chef Infra Client will connect properly
$ClientVerifyMode = ":verify_none"
# You must change this to 'accept' for the Chef Infra Client to run
$ClientLicenseAccept = "null"

# This funtion writes the required output to the client.rb file. The file needs to be generated instead of copied since the individual computer name needs to be injected into it.
function Create-ClientRBFile {
    write-output "log_level        :info" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii
    write-output "log_location     STDOUT" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "chef_server_url  '$ChefServerURL'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "validation_client_name '$ValidatorName'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "validation_key '$ChefRootDir\$ValidatorName.pem'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "node_name '$($env:computername)'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "ssl_verify_mode $ClientVerifyMode" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    write-output "chef_license '$ClientLicenseAccept'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    Write-Output "policy_name '$ClientPolicyName'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    Write-Output "policy_group '$ClientPolicyGroup'" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
    Write-Output "use_policyfile true" | Out-File -FilePath $ChefRootDir\$ChefClientRBFile -Encoding ascii -Append
}

# Create the first-boot.json file. This runlist may need to be edited to specify the appropriate runlist and additional info (i.e. system_info)
function Create-FirstBootFile {
    write-output "{`"policy_name`": `"$ClientPolicyName`", `"policy_group`": `"$ClientPolicyGroup`"}" | Out-File -FilePath $ChefRootDir\$ChefFirstBootFile -Encoding ascii
}

### Let's make the client.rb
if (Test-Path -Path "$ChefRootDir\$ChefClientRBFile") {
    #File already exists so let's overwrite it with the new params
    Create-ClientRBFile
}
else{
    # something doesn't exist so we need to make the things
    if (Test-Path -Path "$ChefRootDir"){
        #Folder is there so all we need to do is make the file
        Out-File -FilePath "$ChefRootDir\$ChefClientRBFile" -Encoding ascii
    }
    else {
        #nothing exists so make all the things
        New-Item -Path "$ChefRootDir" -ItemType Directory
        Out-File -FilePath "$ChefRootDir\$ChefClientRBFile" -Encoding ascii
    }

    # now that the file exists, populate it!
    Create-ClientRBFile
}

### No make the firstboot.json
if (Test-Path -Path "$ChefRootDir\$ChefFirstBootFile") {
    #File already exists so let's overwrite it with the new params
    Create-ClientRBFile
}
else{
    # something doesn't exist so we need to make the things
    if (Test-Path -Path "$ChefRootDir"){
        #Folder is there so all we need to do is make the file
        Out-File -FilePath "$ChefRootDir\$ChefFirstBootFile" -Encoding ascii
    }
    else {
        #nothing exists so make all the things
        New-Item -Path "$ChefRootDir" -ItemType Directory
        Out-File -FilePath "$ChefRootDir\$ChefFirstBootFile" -Encoding ascii
    }

    # now that the file exists, populate it!
    Create-FirstBootFile
}

# Add hack so the script will run in PS 2.0 and higher ($PSScriptRoot isn't a thing in PS2.0 so this will use the old way to get the path)
if(!$PSScriptRoot){ $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

# Last but not least, copy the validator file from the SCCM cache directory into the $ChefRootDir with the other files
Copy-Item -Path "$PSScriptRoot\$ValidatorName.pem" -Destination $ChefRootDir

# This pulls the latest Chef Infra Client directly from Chef, //TODO make this more customizable/add the ability to stage your own installer
. { iwr -useb https://omnitruck.chef.io/install.ps1 } | iex; install

cmd /c "c:\opscode\chef\bin\chef-client.bat -j c:\chef\first-boot.json"

# Clean up our validator pem after initial install:
Remove-Item -Path "$PSScriptRoot\$ValidatorName.pem"
Remove-Item -Path "$ChefRootDir\$ValidatorName.pem"
