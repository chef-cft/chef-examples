OS_TYPE=$1
OS_VERSION=$2

echo "************************"
echo "Preflight Configuration "
echo "************************"

sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w vm.dirty_expire_centisecs=20000
sudo echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sudo echo "vm.dirty_expire_centisecs=20000" >> /etc/sysctl.conf

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
echo "*********************************************"
echo "Copy Keys to ~/chef needed for Bootstrapping "
echo "*********************************************"
if [ ! -d /home/vagrant/.chef ]; then
  sudo mkdir /home/vagrant/.chef
fi
sudo cp /home/vagrant/vbox/server/bootstrap-validator.key /home/vagrant/.chef/
sudo cp /home/vagrant/vbox/server/souschef.user.key /home/vagrant/.chef/
sudo chown -R vagrant:vagrant /home/vagrant/.chef
