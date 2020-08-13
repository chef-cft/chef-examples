CHEF_SERVER_VERSION=$1
OS_TYPE=$2
OS_VERSION=$3

echo "************************"
echo "Preflight Configuration "
echo "************************"

sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.dirty_expire_centisecs=20000
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sudo echo "vm.dirty_expire_centisecs=20000" >> /etc/sysctl.conf

echo "***********************************************************************************"
echo "Downloading & Installing Chef Automate with Chef Infra Server $CHEF_SERVER_VERSION "
echo "***********************************************************************************"

curl https://packages.chef.io/files/current/latest/chef-automate-cli/chef-automate_linux_amd64.zip | gunzip - > chef-automate && chmod +x chef-automate
sudo ./chef-automate deploy --product automate --product infra-server --accept-terms-and-mlsa

echo ""
echo ""
echo "************************************************************"
echo "Creating Bootstrap Organization and User on the Chef Server "
echo "************************************************************"
sudo chef-server-ctl user-create souschef Bootstrap User success@chef.io 'S0u$Ch3f!' --filename souschef-user.pem
sudo chef-server-ctl org-create bootstrap 'bootstrap-chef-server' --association_user souschef --filename bootstrap-validator.pem
sudo chef-server-ctl org-user-add bootstrap souschef --admin
echo "*************************************************************************"
echo "User and Org Pem files are saved in the home directory"
echo "*************************************************************************"

echo ""
echo ""
echo "*********************************************"
echo "Copy Generated Files to the Shared Directory "
echo "*********************************************"
cp /home/vagrant/bootstrap-validator.pem /home/vagrant/vbox/
cp /home/vagrant/souschef-user.pem /home/vagrant/vbox/
cp /home/vagrant/automate-credentials.toml /home/vagrant/vbox/
