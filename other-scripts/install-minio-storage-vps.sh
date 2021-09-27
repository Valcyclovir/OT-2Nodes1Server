#!/bin/bash

# This script will install minio to use with restic backup / restores to speed up network speeds. 

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
fi

sudo apt update
wget https://dl.min.io/server/minio/release/linux-amd64/minio
sudo chmod +x minio
sudo mv minio /usr/local/bin
sudo useradd -r $MINIO_USER -s /sbin/nologin
sudo chown $MINIO_USER:$MINIO_USER /usr/local/bin/minio
sudo mkdir $MINIO_BACKUPDIR
sudo chown $MINIO_USER:$MINIO_USER $MINIO_BACKUPDIR
sudo mkdir /etc/minio
sudo chown $MINIO_USER:$MINIO_USER /etc/minio

ADDRESS=$(hostname -I | cut -f 1 -d ' ')

echo MINIO_ROOT_USER='"'"$AWS_ACCESS_KEY_ID"'"' >> /etc/default/minio
echo MINIO_ROOT_PASSWORD='"'"$AWS_SECRET_ACCESS_KEY"'"' >> /etc/default/minio
echo MINIO_VOLUMES='"'"$MINIO_BACKUPDIR/"'"' >> /etc/default/minio
echo MINIO_OPTS='"'"-C /etc/minio --address $ADDRESS:9000 --console-address :9001"'"' >> /etc/default/minio

curl -O https://raw.githubusercontent.com/minio/minio-service/master/linux-systemd/minio.service

sed -i 's/User=.*/User='$MINIO_USER'/g' minio.service
sed -i 's/Group=.*/Group='$MINIO_USER'/g' minio.service

sudo mv minio.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable minio
sudo systemctl start minio

firewall="`ufw status | grep Status | cut -c 9-`"
if [[ $firewall = "inactive" ]]; then
  echo "Enabling firewall"
  ufw allow 22/tcp && yes | ufw enable
fi

sudo ufw allow 9000

echo "Minio installation complete on your storage VPS ! "
echo "Now please go back to your node server, input source /etc/otnode/config.sh then on your OT-2Nodes1Server directory, run ./restic init"
echo "The setup will be complete then. Good luck !"
