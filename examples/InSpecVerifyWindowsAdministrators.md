# HowTo - Verify Windows Administrators with InSpec

This process outlines one way to identify users and/or groups that are in the local Administrators group on a Windows system that should not be there.

## Before You Start

### Assumptions

* You have a list of known administrators
* You have working clients that report to Automate. If not, please review the [Secure Your Infrastructure with Chef Automate](https://learn.chef.io/courses/course-v1:chef+Automate101+Perpetual/about) course.

### Tested Versions

* InSpec 4.19.0
* Automate 2
* Chef 16

## Steps

1. If you have an existing profile, open it. If not, create a new profile `inspec init profile admins_audit`
1. Create a new file in the `controls` folder, e.g. `administrators_audit.rb`.
1. Add the sample code below and update the `admin_members` list.

  ``` ruby
  admin_members = [ 'Domain Admins', 'Server Admins' ]
  describe group("Administrators") do
    its("members") { should be_in admin_members }
  end
  ```

1. Upload the profile to Automate then review the data.
1. If there are members that shouldn't be there, you'll get a compliance failure similar to the following:

  ``` text
    Group Administrators
     [FAIL]  members is expected to be in "Domain Admins", "Server Admins"
     expected `bad_user` to be in the list: `["Domain Admins", "Server Admins"]`
  ```

## FAQs

1. It is possible to dynamically build and/or add to the list of known users. For example, say you have a registry key with a site code of the physical datacenter site. Each data center has local administrators. We want to dynamically add their AD group to our list of known administrators.

``` ruby
site_code = powershell("$(Get-ItemProperty -Path HKLM:\MyCompany\SiteDetails).SiteCode").stdout.strip
group_name = "Site-Admins-#{site_code}"
admin_members = [ 'Domain Admins', 'Server Admins' ]
admin_members.append(group_name)
```
