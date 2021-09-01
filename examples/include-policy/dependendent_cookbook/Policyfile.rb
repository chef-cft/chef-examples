# Policyfile.rb - Describe how you want Chef Infra Client to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile/

# A name that describes what the system you're building with Chef does.
name 'dependendent_cookbook'

# Where to find external cookbooks:
default_source :supermarket

# run_list: chef-client will run these recipes in the order specified.
run_list 'dependendent_cookbook::default'

include_policy 'base_cookbook', path: '../base_cookbook/Policyfile.lock.json'

# Specify a custom source for a single cookbook:
cookbook 'dependendent_cookbook', path: '.'
cookbook 'base_cookbook', path: '../base_cookbook/.'
