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

#    default: Creating admin user
#    default: 
#    default: Deploy Complete
#    default: Your credentials have been saved to automate-credentials.toml
#    default: Access the web UI at https://ubuntu1604.localdomain/
#    default: 
#    default: Users of this Automate deployment may elect to share anonymized usage data with
#    default: Chef Software, Inc. Chef uses this shared data to improve Automate.
#    default: Please visit https://chef.io/privacy-policy for more information about the
#    default: information Chef collects, and how that information is used.

#vagrant@ubuntu1604:~$ sudo cat automate-credentials.toml 
#url = "https://ubuntu1604.localdomain"
#username = "admin"
#password = "fe9f61d17ba9f5e05b3536715eaef23d"

#adjust /etc/hosts
#10.11.12.13 server.bootstrap

#navigate to https://ubuntu1604.localdomain
#--> accept the self-signed certificate

#login with your admin credentials

#Fill out the form, agree to the license and Register
