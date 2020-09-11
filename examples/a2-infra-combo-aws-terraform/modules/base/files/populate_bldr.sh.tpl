#!/bin/bash

# Ensure this script is being run as root.  This is required because the
# download script needs to create a subdirectory in a root-owned directory.
if [[ $EUID -ne 0 ]]; then
   echo "ERROR:  This script must be run as root.  Use sudo and try again."
   exit 1
fi

echo
echo "NOTE:"
echo "You need to go log in to http://${bldr_fqdn} as admin and create a core origin."
echo "You will also need to generate a Personal Access Token for use in this script."
echo "Go do that now, if you haven't already."
echo
echo "Please enter your Personal Access Token now..."

read ON_PREM_PERSONAL_ACCESS_TOKEN

echo

cd /opt/on-prem-builder/

echo "Available package seed lists:"
echo

ls -1 package_seed_lists|grep -v README.md

echo
echo "Which package seed list would you like to bootstrap your instance with?"

read PACKAGE_SEED_LIST

echo
echo "Starting bootstrap process..."
hab pkg download --channel stable --file package_seed_lists/$${PACKAGE_SEED_LIST} --download-directory $${PACKAGE_SEED_LIST}_bootstrap
export HAB_AUTH_TOKEN=$${ON_PREM_PERSONAL_ACCESS_TOKEN}
hab pkg bulkupload --url http://${bldr_fqdn} --channel stable $${PACKAGE_SEED_LIST}_bootstrap/
echo "Bootstrap complete."
echo
