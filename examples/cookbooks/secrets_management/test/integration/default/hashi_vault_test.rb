# InSpec test for recipe secrets_management::hashi_vault

# The InSpec reference, with examples and extensive documentation, can be
# found at https://www.inspec.io/docs/reference/resources/


#   action :create
describe file('/tmp/config.conf') do
  it { should exist }
  it { should be_file }
  its('content') { should match /The user name is:/ }
end

describe file('/tmp/vault.txt') do
  it { should exist }
  it { should be_file }
  its('mode') { should cmp '0755' }
  its('content') { should match /This is a test and the password is:*/ }
end

