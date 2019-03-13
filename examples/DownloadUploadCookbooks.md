## How To Download All Chef Cookbooks, Including Different Versions from a Chef Server, then Upload to Another Chef Server

_Note, this was done on a Mac, Windows is similar_

### Using Source Chef Server in `knife.rb`
1. Edit your `knife.rb` and add the following line:
   ```
   versioned_cookbooks      true
   ```
1. Create a directory on your local workstations called `chef_cookbooks`.
1. CD into the `chef_cookbooks` directory and run the following command:
   ```
   knife download --chef-repo-path ./ /cookbooks

   ## Output Similar to this, note the version numbers on the end of each one:

    Created cookbooks/audit-7.0.0
    Created cookbooks/auditd-2.3.3
    Created cookbooks/bitbucket-version-test-cookbook-0.1.3
    Created cookbooks/audit-7.1.0
    Created cookbooks/bastion-host-0.1.1
    Created cookbooks/bitbucket-version-test-cookbook-1.1.11
    Created cookbooks/bitbucket-version-test-cookbook-1.1.8
    Created cookbooks/bitbucket-version-test-cookbook-1.1.10
    Created cookbooks/bitbucket-version-test-cookbook-0.1.3/DELIVERY.md
    Created cookbooks/bitbucket-version-test-cookbook-1.1.11/DELIVERY.md
    Created cookbooks/bastion-host-0.1.1/DELIVERY.md
    Created cookbooks/auditd-2.3.3/CHANGELOG.md
    Created cookbooks/bitbucket-version-test-cookbook-1.1.8/DELIVERY.md
    .......
1. That's it, you've downloaded all cookbooks from the source.

### Using Destination Chef Server in `knife.rb`
1. CD into the `chef_cookbooks` directory you created in step 2 above.
1. Run the following command to upload all cookbooks in the directory:
   ```
   knife upload --chef-repo-path ./ /cookbooks

   ## Output Similar to this:

    Created cookbooks/audit-7.0.0
    Created cookbooks/auditd-2.3.3
    Created cookbooks/bitbucket-version-test-cookbook-0.1.3
    Created cookbooks/audit-7.1.0
    Created cookbooks/bastion-host-0.1.1
    Created cookbooks/bitbucket-version-test-cookbook-1.1.11
    Created cookbooks/bitbucket-version-test-cookbook-1.1.8
    Created cookbooks/bitbucket-version-test-cookbook-1.1.10
    Created cookbooks/bitbucket-version-test-cookbook-0.1.3/DELIVERY.md
    Created cookbooks/bitbucket-version-test-cookbook-1.1.11/DELIVERY.md
    Created cookbooks/bastion-host-0.1.1/DELIVERY.md
    Created cookbooks/auditd-2.3.3/CHANGELOG.md
    Created cookbooks/bitbucket-version-test-cookbook-1.1.8/DELIVERY.md
    .......
   ```
1. That's it, you now have all of your cookbooks + versions uploaded to a new Chef Server.