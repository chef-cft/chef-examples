# Cookbook to delete files sandbox.html

## What is Polyfill Vulnerability?  

Polyfill vulnerability refers to a security issue involving the Polyfill.io service. Polyfill.io is a popular service that provides JavaScript polyfills to ensure that modern web features work in older browsers. 

A vulnerability in this context typically involves malicious actors exploiting the service to inject harmful scripts into websites that rely on Polyfill.io. Over 100,000 websites were affected by a supply chain attack involving Polyfill.io.  

Recently, following the acquisition of Pollyfill.io, a security issue emerged. The scripts on polyfills started redirecting users to malicious and scam sites. The domain is said to have injected malware into mobile devices via any site that embeds ’cdn.polyfill.io’.  

## What Are the Mitigation Steps? 

You must delete two HTML files from the Automate configuration. Both files are stored in the asset's directory within the hab package.  

You can perform this action via cookbooks or with the help of a script. 

This recipe deletes the file sandbox.html from a couple of directories (collection and chef). 

automat_dir—This variable stores the first part of the path (/hab/pkg/chef/automate-ui/2.0.0).

parent_dir - This variable stores the first directory name.

file_names_tobe_deleted—This variable stores the values collection and chef and is performed in a loop. 

action: delete - delete the file mentioned. 

Once both files are deleted, a new file by name tag file is created in the /home directory. 

You can perform this action via cookbooks or with the help of a script. 