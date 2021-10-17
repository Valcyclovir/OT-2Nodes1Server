#!/bin/bash

# ONLY USE THIS IS YOU HAVE A PRE-EXISTING MULTINODE SETUP WITH COLDBRAIN BACKUP ON YOUR RESTIC IN THE PAST. THIS WILL NOT WORK WITH NEW INSTALLS. 

# This can be used in case of EMERGENCY when you need to quickly redeploy all your nodes elsewhere if you had everything backed up on restic.

# For emergency use, before you begin, make you you have the SSH private keys to log in to your storage VPS in /root/.ssd/id_rsa and complete the config.sh file inside $MAINPATH/config.sh

# Make sure you change your subdomain's linked IP Address on your domain name provider, and make sure your server HOSTNAME is the same as your restic backup's.

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

source "$MAINPATH/data/fixed-variables.sh"

STATUS=$?
N1=$'\n'

echo "Initial node server setup"
$MAINPATH/data/initial-node-setup.sh
if [[ $? -ne 0 ]]; then
  echo "Initial node server setup FAILED"
  exit 1
fi

firewall="`ufw status | grep Status | cut -c 9-`"
if [[ $firewall = "inactive" ]]; then
  echo "Enabling firewall"
  ufw allow 22/tcp && yes | ufw enable
fi

for (( i=$NODE_COUNTER; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"

  echo "$MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1"
  SNAPSHOT=$($MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1)

  echo "mkdir $BACKUPPATH"
  mkdir $BACKUPPATH
  if [[ $? -ne 0 ]]; then
    echo "mkdir $BACKUPPATH failed"
    exit 1
  fi

  echo "mkdir $NODEBASEPATH/$NODE"
  mkdir $NODEBASEPATH/$NODE
  if [[ $? -ne 0 ]]; then
    echo "mkdir $NODEBASEPATH/$NODE"
    exit 1
  fi

  echo "$MAINPATH/restic restore $SNAPSHOT --target $BACKUPPATH"
  $MAINPATH/restic restore $SNAPSHOT --target $BACKUPPATH

  echo "mv -v $BACKUPPATH/$NODEBASEPATH/$NODE/.origintrail_noderc $NODEBASEPATH/$NODE/"
  mv -v $BACKUPPATH/$NODEBASEPATH/$NODE/.origintrail_noderc $NODEBASEPATH/$NODE/

  echo "mv -v $BACKUPPATH/var/lib/docker/overlay2/*/merged/var/lib/arango* $BACKUPPATH/"
  mv -v $BACKUPPATH/var/lib/docker/overlay2/*/merged/var/lib/arango* $BACKUPPATH/

  echo " mv -v $BACKUPPATH/var/lib/docker/overlay2/*/merged/ot-node/data $BACKUPPATH/"
  mv -v $BACKUPPATH/var/lib/docker/overlay2/*/merged/ot-node/data $BACKUPPATH/

  NODE_PORT=$(cat $NODEBASEPATH/$NODE/.origintrail_noderc | jq -r '.node_port')
  NODE_RPC_PORT=$(cat $NODEBASEPATH/$NODE/.origintrail_noderc | jq -r '.node_rpc_port')
  NODE_REMOTE_CONTROL_PORT=$(cat $NODEBASEPATH/$NODE/.origintrail_noderc | jq -r '.node_remote_control_port')

  echo "Setting up Firewall rules"
  ufw allow $NODE_REMOTE_CONTROL_PORT && ufw allow $NODE_PORT && ufw allow $NODE_RPC_PORT

  echo "Creating $NODE"
  OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $NODE_RPC_PORT:$NODE_RPC_PORT -p $NODE_PORT:$NODE_PORT -p $NODE_REMOTE_CONTROL_PORT:$NODE_REMOTE_CONTROL_PORT -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Docker creation FAILED:${N1}$OUTPUT"
    exit 1
  fi

  echo "docker start $NODE"
  docker start $NODE
  if [[ $? -ne 0 ]]; then
    echo "Docker start FAILED:${N1}"
    exit 1
  fi

  sleep 2s

  echo "rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data"
  rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data

  echo "mv $BACKUPPATH/data $($DOCKER_INSPECT_MERGED $NODE)/ot-node/"
  mv $BACKUPPATH/data $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data
  if [[ $? -ne 0 ]]; then
    echo "Moving /ot-node/data into $NODE directory failed"
    exit 1
  fi

  echo "Enable docker always restart"
  OUTPUT=$(docker update --restart=always $NODE 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Docker restart update FAILED:${N1}$OUTPUT"
    exit 1
  fi

  echo "docker stop $NODE"
  docker stop $NODE
  if [[ $? -ne 0 ]]; then
    echo "Docker restart FAILED:${N1}"
    exit 1
  fi

  echo "rm -rf $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS"
  rm -rf $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS
  if [[ $? -ne 0 ]]; then
    echo "Removing node files for $NODE failed"
    exit 1
  fi

  chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data
  if [[ $? -ne 0 ]]; then
    echo "chown -R 777 /ot-node/data for $NODE failed !"
    exit 1
  fi

  chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data
  if [[ $? -ne 0 ]]; then
    echo "chown -R root:root /ot-node/data for $NODE failed !"
    exit 1
  fi

  echo "mv $BACKUPPATH/merged/var/lib/arangodb* $($DOCKER_INSPECT_UPPER $NODE)/var/lib/"
  mv $BACKUPPATH/arangodb* $($DOCKER_INSPECT_UPPER $NODE)/var/lib/
  if [[ $? -ne 0 ]]; then
    echo "Moving /var/lib/arangodb files into $NODE directory failed:${N1}"
    exit 1
  fi

  echo "Setting chmod -R 777 on arangodb3 files"
  chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS
  chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3
  if [[ $? -ne 0 ]]; then
    echo "chmod -R 777 /var/lib/arangodb for $NODE failed !"
    exit 1
  fi

  echo "Setting chown -R root:root on arangodb3 files"
  chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS
  chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3
  if [[ $? -ne 0 ]]; then
    echo "chown -R root:root /var/lib/arangodb for $NODE failed !"
    exit 1
  fi

  echo "Starting docker $NODE"
  docker start $NODE
  if [[ $? -ne 0 ]]; then
    echo "Docker start FAILED:${N1}"
    exit 1
  fi

  echo "rm -rf $BACKUPPATH"
  rm -rf $BACKUPPATH
  if [[ $? -ne 0 ]]; then
    echo "Removing $BACKUPPATH failed"
    exit 1
  fi

done

echo "########## RESTORE COMPLETE ! ##########"
echo "REMEMBER TO RUN update-arango-vars.sh after the install to get the correct arangod values for MN docker"
