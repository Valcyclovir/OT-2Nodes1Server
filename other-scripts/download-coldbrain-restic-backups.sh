#!/bin/bash

# This script will download your coldbrain restic backup files to your server.

# To complete the installation, you must adjust the backup folder number, edit your config.sh and run install-from-local-coldbrain-backups.sh

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
  export BACKUPPATH="/root/backup"
  export NODEBASEPATH="/root"
fi

for (( i=$NODE_COUNTER; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"
  BACKUP="$BACKUPPATH$i"

  echo "$MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1"
  SNAPSHOT=$($MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1)

  echo "mkdir $BACKUP"
  rm -rf $BACKUP
  mkdir $BACKUP
  if [[ $? -ne 0 ]]; then
    echo "mkdir $BACKUP failed"
    exit 1
  fi

  echo "$MAINPATH/restic restore $SNAPSHOT --target $BACKUP"
  $MAINPATH/restic restore $SNAPSHOT --target $BACKUP

  echo "mv -v $BACKUP/var/lib/docker/overlay2/*/merged/var/lib/arango* $BACKUP/"
  mv -v $BACKUP/var/lib/docker/overlay2/*/merged/var/lib/arango* $BACKUP/

  echo " mv -v $BACKUP/var/lib/docker/overlay2/*/merged/ot-node/data $BACKUP/"
  mv -v $BACKUP/var/lib/docker/overlay2/*/merged/ot-node/data $BACKUP/

done

echo "Backup files downloaded to $BACKUPPATH. Remember to complete /etc/otnode/config.sh and run install-from-local-coldbrain-backups.sh to complete the installation !"