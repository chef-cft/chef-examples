# Do some chef pre-work
mkdir -p /etc/chef
mkdir -p /var/lib/chef
mkdir -p /var/log/chef

# Setup hosts file correctly
cat >> "/etc/hosts" << EOF
10.11.13.13 server.bootstrap
10.11.12.13 compliance-server compliance-server.automate.com
10.11.12.13 infra-server infra-server.automate.com
10.11.12.13 automate-server automate-server.automate.com
EOF

cd /etc/chef/

# Install chef
curl -L https://omnitruck.chef.io/install.sh | bash || error_exit 'could not install chef'

# Create first-boot.json
cat > "/etc/chef/first-boot.json" << EOF
{
   "run_list" :[
   "role[base]"
   ]
}
EOF

NODE_NAME=client.bootstrap
#NODE_NAME=node-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 4 | head -n 1)

# Create client.rb
echo 'log_location     STDOUT' >> /etc/chef/client.rb
echo -e "chef_server_url  \"https://server.bootstrap/organizations/bootstrap\"" >> /etc/chef/client.rb
echo -e "validation_client_name \"bootstrap-validator\"" >> /etc/chef/client.rb
echo -e "validation_key \"/home/vagrant/.chef/bootstrap-validator.pem\"" >> /etc/chef/client.rb
echo -e "node_name  \"${NODE_NAME}\"" >> /etc/chef/client.rb
echo -e "ssl_verify_mode    :verify_none" >> /etc/chef/client.rb

chef-client -j /etc/chef/first-boot.json --chef-license accept
