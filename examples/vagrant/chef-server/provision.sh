CHEF_SERVER_VERSION=$1
OS_TYPE=$2
OS_VERSION=$3

echo "******************"
echo "Updating system..."
echo "******************"
if [[ $OS_TYPE == *'ubuntu'* ]]
then
  echo "************************************************"
  echo "Updating apt-get and installing build-essential "
  echo "************************************************"
  sudo apt-get update
  sudo apt-get -y install build-essential
elif [[ $OS_TYPE != *'rhel'* ]]
then
    sudo yum update -y
    sudo yum install gcc gcc-c++ make
fi

echo "*************************"
echo "Adjust Kernel Parameters "
echo "*************************"
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.dirty_expire_centisecs=20000
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sudo echo "vm.dirty_expire_centisecs=20000" >> /etc/sysctl.conf

echo "************************************************************************"
echo "Downloading & Installing Chef Infra Server Version $CHEF_SERVER_VERSION "
echo "************************************************************************"
if [[ $OS_TYPE == *'ubuntu'* ]]
then
  if [ ! -f "chef-server-core_$CHEF_SERVER_VERSION-1_amd64.deb" ]; then
    wget https://packages.chef.io/files/stable/chef-server/$CHEF_SERVER_VERSION/ubuntu/$OS_VERSION/chef-server-core_$CHEF_SERVER_VERSION-1_amd64.deb
    sudo dpkg -i ./chef-server-core_$CHEF_SERVER_VERSION-1_amd64.deb
  else
    echo "Package already downloaded."
  fi
elif [[ $OS_TYPE == 'rhel8' || $OS_TYPE == 'centos8' ]]
then
  if [ ! -f "chef-server-core_$CHEF_SERVER_VERSION-1.el7.x86_64.rpm" ]; then
    wget https://packages.chef.io/files/stable/chef-server/$CHEF_SERVER_VERSION/el/$OS_VERSION/chef-server-core-$CHEF_SERVER_VERSION-1.el7.x86_64.rpm
    rpm -Uvh ./chef-server-core-$CHEF_SERVER_VERSION-1.el7.x86_64.rpm
  else
    echo "Package already downloaded."
  fi
else
  if [ ! -f "chef-server-core_$CHEF_SERVER_VERSION-1.el7.x86_64.rpm" ]; then
    wget https://packages.chef.io/files/stable/chef-server/$CHEF_SERVER_VERSION/el/$OS_VERSION/chef-server-core-$CHEF_SERVER_VERSION-1.el$OS_VERSION.x86_64.rpm
    rpm -Uvh ./chef-server-core-$CHEF_SERVER_VERSION-1.el$OS_VERSION.x86_64.rpm
  else
    echo "Package already downloaded."
  fi
fi

if [[ $CHEF_SERVER_VERSION > '13.0.0' ]]
then
  sudo chef-server-ctl reconfigure --chef-license=accept
else
  sudo chef-server-ctl reconfigure
fi


#curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate
#sudo ./chef-automate deploy --product automate --product infra-server --accept-terms-and-mlsa

echo ""
echo ""
echo "************************************************************"
echo "Creating Bootstrap Organization and User on the Chef Server "
echo "************************************************************"
sudo chef-server-ctl user-create souschef Bootstrap User success@chef.io 'S0u$Ch3f!' -f souschef.user.key
sudo chef-server-ctl org-create bootstrap "Bootstrap Chef Server" --association_user souschef -f bootstrap-validator.key
#sudo chef-server-ctl org-user-add bootstrap souschef --admin
echo "*************************************************************************"
echo "User and Org Pem files are saved in the home directory"
echo "*************************************************************************"

echo ""
echo ""
echo "*********************************************"
echo "Copy Generated Files to the Shared Directory "
echo "*********************************************"
mkdir -p /home/vagrant/vbox/server/
cp /home/vagrant/bootstrap-validator.key /home/vagrant/vbox/server/
cp /home/vagrant/souschef.user.key /home/vagrant/vbox/server/
#cp /home/vagrant/automate-credentials.toml /home/vagrant/vbox/server/
