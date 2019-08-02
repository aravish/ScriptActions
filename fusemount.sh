#!/bin/sh
ACCOUNTNAME=$1
ACCOUNTKEY=$2
CONTAINERNAME=$3
USERNAME=$4

wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
sudo DEBIAN_FRONTEND=noninteractive dpkg -i packages-microsoft-prod.deb
sudo DEBIAN_FRONTEND=noninteractive apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install blobfuse

sudo mkdir /mnt/blobfusetmp -p
sudo chown "${USERNAME}" /mnt/blobfusetmp

touch /home/"${USERNAME}"/fuse_connection.cfg
echo "accountName ${ACCOUNTNAME}" >> /home/"${USERNAME}"/fuse_connection.cfg
echo "accountKey ${ACCOUNTKEY}" >> /home/"${USERNAME}"/fuse_connection.cfg
echo "containerName ${CONTAINERNAME}" >> /home/"${USERNAME}"/fuse_connection.cfg
chmod 600 /home/"${USERNAME}"/fuse_connection.cfg

sudo mkdir /persistentdata

sudo blobfuse /persistentdata --tmp-path=/mnt/blobfusetmp  --config-file=/home/"${USERNAME}"/fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 -o allow_other