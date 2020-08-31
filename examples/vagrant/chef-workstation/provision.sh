CHEF_WORKSTATION_VERSION=$1
OS_TYPE=$2
OS_VERSION=$3

echo "************************"
echo "Preflight Configuration "
echo "************************"

sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.dirty_expire_centisecs=20000
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sudo echo "vm.dirty_expire_centisecs=20000" >> /etc/sysctl.conf

echo "******************************************"
echo "Downloading & Installing Chef Workstation "
echo "******************************************"

if [[ $OS_TYPE == *'ubuntu'* ]]
then
  if [ ! -e "chef-workstation_$CHEF_WORKSTATION_VERSION-1_amd64.deb" ]; then
    wget https://packages.chef.io/files/stable/chef-workstation/$CHEF_WORKSTATION_VERSION/ubuntu/$OS_VERSION/chef-workstation_$CHEF_WORKSTATION_VERSION-1_amd64.deb
    sudo dpkg -i ./chef-workstation_$CHEF_WORKSTATION_VERSION-1_amd64.deb
  fi
else
  if [ ! -e "chef-workstation_$CHEF_WORKSTATION_VERSION-1.el$OS_VERSION.x86_64.rpm" ]; then
    wget https://packages.chef.io/files/stable/chef-workstation/$CHEF_WORKSTATION_VERSION/el/$OS_VERSION/chef-workstation-$CHEF_WORKSTATION_VERSION-1.el$OS_VERSION.x86_64.rpm
    rpm -Uvh ./chef-workstation_$CHEF_WORKSTATION_VERSION.el$OS_VERSION-1.x86_64.rpm
  fi
fi

echo ""
echo ""
echo "*************************************"
echo "Verify Chef Workstation Installation "
echo "*************************************"
chef -v

echo ""
echo ""
echo "******************"
echo "Adjust /etc/hosts "
echo "******************"
sudo echo "10.11.12.13 server.bootstrap" >> /etc/hosts
sudo echo "10.11.12.42 node.bootstrap" >> /etc/hosts
sudo echo "10.11.12.43 workstation.bootstrap" >> /etc/hosts


# Make this key based going forward...
echo ""
echo ""
echo "*********************************"
echo " Adjust secure SSH Configuration "
echo "**********************************"
if [[ $OS_TYPE == *'centos'* ]]
then
  echo ""
  echo "*************************************"
  echo "Centos Machine : Allowing PasswordAuth"
  echo "*************************************"
  sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication  yes/g' /etc/ssh/sshd_config
  sudo systemctl restart sshd.service
fi

echo ""
echo ""
echo "**********************************************"
echo "Copy Credentials from Chef Infra Server Setup "
echo "**********************************************"
mkdir /home/vagrant/.chef
cp /home/vagrant/vbox/server/souschef.user.key /home/vagrant/.chef/
cp /home/vagrant/vbox/workstation/config.rb /home/vagrant/.chef/
sudo chown -R vagrant:vagrant /home/vagrant/.chef
su -l vagrant -c "knife ssl fetch --profile bootstrap"

echo ""
echo ""
echo "***************************************"
echo "Create Example Repository and Contents "
echo "***************************************"
chef generate repo chef-repo --chef-license accept-silent
mkdir -p /home/vagrant/chef-repo/.chef
echo '.chef' >> /home/vagrant/chef-repo/.gitignore
sudo chown -R vagrant:vagrant /home/vagrant/chef-repo

echo ""
echo ""
echo "***********************************************************"
echo "Download the Basline Profile and Install the Audit Cookbook"
echo "***********************************************************"
if [[ $OS_TYPE == *'ubuntu'* ]]
then
    sudo apt-get install -y git
else
    sudo yum -y install git
fi
su -l vagrant -c "git clone https://github.com/dev-sec/linux-baseline /home/vagrant/linux-baseline"
su -l vagrant -c "git clone https://github.com/chef-cookbooks/audit.git /home/vagrant/chef-repo/cookbooks/audit"

echo ""
echo ""
echo "**************************"
echo "Bootstrap Our Workstation " 
echo "**************************"

## SSH into our localhost by name and use the `souschef` user agains the Chef Infra Server 
knife bootstrap workstation.bootstrap -s https://server.bootstrap/organizations/bootstrap -N workstation.bootstrap -P vagrant -U vagrant -u souschef --chef-license accept --yes --sudo

## chef-client firstboot.json approach
#sudo chmod +x /home/vagrant/vbox/node/firstboot.sh
#sudo /bin/bash -xev /home/vagrant/vbox/node/firstboot.sh

echo ""
echo ""
echo "************************"
echo "Setup Knife Credentials "
echo "************************"
cp /home/vagrant/vbox/workstation/credentials.EXAMPLE /home/vagrant/.chef/credentials
sudo chown -R vagrant:vagrant /home/vagrant/.chef

echo ""
echo ""
echo "***********************************"
echo "Upload Audit and Example Cookbooks "
echo "***********************************"
## cookbook upload
knife cookbook upload -ao /home/vagrant/chef-repo/cookbooks/ -u souschef

echo ""
echo ""
echo "********************"
echo "Run the Chef Client "
echo "********************"
chef-client -s server.bootstrap -r 'recipe[audit::default]'

echo ""
echo ""
echo "*****************************"
echo "Bootstrap an additional Node "
echo "*****************************"
knife bootstrap node.bootstrap -s https://server.bootstrap/organizations/bootstrap -N node.bootstrap -P vagrant -U vagrant -u souschef --chef-license accept --yes --sudo

echo ""
echo ""
echo "*****************************************"
echo "Perform an Inspec Scan of node.bootstrap "
echo "*****************************************"
echo ""
echo "NOTE: This step will fail because you now need to move onto resolving issues with your node!"
echo ""
inspec exec /home/vagrant/linux-baseline -t ssh://vagrant@node.bootstrap:22 --password=vagrant
