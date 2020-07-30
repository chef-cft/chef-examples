CHEF_SERVER_VERSION=$1
OS_TYPE=$2
OS_VERSION=$3

echo "*************************************************************************"
echo "Updating packages..."
echo "*************************************************************************"
if [[ $OS_TYPE == *'ubuntu'* ]]
then
  sudo apt-get update
  sudo apt-get -y install build-essential
elif [[ $OS_TYPE != *'rhel'* ]]
then
    sudo yum update -y
    sudo yum install gcc gcc-c++ make
fi

echo "*************************************************************************"
echo "Downloading & Installing Chef Server Version: $CHEF_SERVER_VERSION"
echo "*************************************************************************"
if [[ $OS_TYPE == *'ubuntu'* ]]
then
  wget https://packages.chef.io/files/stable/chef-server/$CHEF_SERVER_VERSION/ubuntu/$OS_VERSION/chef-server-core_$CHEF_SERVER_VERSION-1_amd64.deb
  sudo dpkg -i ./chef-server-core_$CHEF_SERVER_VERSION-1_amd64.deb
  echo "*************************************************************************"
  echo "Updating apt-get and installing build-essentials"
  echo "*************************************************************************"
elif [[ $OS_TYPE == 'rhel8' || $OS_TYPE == 'centos8' ]]
then
  wget https://packages.chef.io/files/stable/chef-server/$CHEF_SERVER_VERSION/el/$OS_VERSION/chef-server-core-$CHEF_SERVER_VERSION-1.el7.x86_64.rpm
  rpm -Uvh ./chef-server-core-$CHEF_SERVER_VERSION-1.el7.x86_64.rpm
else
  wget https://packages.chef.io/files/stable/chef-server/$CHEF_SERVER_VERSION/el/$OS_VERSION/chef-server-core-$CHEF_SERVER_VERSION-1.el$OS_VERSION.x86_64.rpm
  rpm -Uvh ./chef-server-core-$CHEF_SERVER_VERSION-1.el$OS_VERSION.x86_64.rpm
fi

if [ $CHEF_SERVER_VERSION \> '13.0.0' ]
then
  sudo chef-server-ctl reconfigure --chef-license=accept
else
  sudo chef-server-ctl reconfigure
fi

echo "*************************************************************************"
echo "Creating Vagrant user and vagrant-dev org on Chef Server"
echo "*************************************************************************"
sudo chef-server-ctl user-create vagrant Vagrant Vagrant chefserver@chef.io 'vagrant' --filename vagrant-user.pem
sudo chef-server-ctl org-create vagrant-dev 'vagrant-chef-server' --association_user vagrant --filename vagrant-dev-validator.pem
echo "*************************************************************************"
echo "User and Org Pem files are saved in the home directory"
echo "*************************************************************************"