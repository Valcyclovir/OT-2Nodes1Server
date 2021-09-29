#!/bin/bash

# FOLLOW INSTRUCTIONS ON README BEFORE USING THIS SCRIPT

# Use this to easily migrate all your nodes to your new multinode server using the fast recommended way

# This script will also return an error if your backup files are not in /root/backup1 /root/backup2 ...

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
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

for (( i=$NODE_COUNTER; i<=$NODE_TOTAL ; i++ ))
do
  PORT1=$((i+2999))
  PORT2=$((i+5277))
  PORT3=$((i+8899))
  NODE="$NODE_NAME$i"

  if [[ -d "/root/backup$i/data" ]] && [[ -d "/root/backup$i/arangodb3" ]] && [[ -d "/root/backup$i/arangodb3-apps" ]]; then
    echo "/root/backup$i subdirectories detected. Proceeding with restore."
  else
    echo "######### CAREFUL !! SCRIPT STOPPED BECAUSE BACKUP FILES ARE NOT IN THE RIGHT DIRECTORY !! #########"
    echo "Before attempting this script again, please make sure your cold backup files are in /root/backup$i/data /root/backup$i/arangodb3 and /root/backup$i/arangodb3-apps"
    exit 1
  fi

  if [[ -d "/root/backup$i/data/import_cache" ]]; then
    echo "rm -rf /root/backup$i/data/import_cache"
    rm -rf /root/backup$i/data/import_cache
  fi

  echo "Setting up Firewall rules"
  ufw allow $PORT1 && ufw allow $PORT2 && ufw allow $PORT3

  echo "removing old $NODEBASEPATH/$NODE and making new directory $NODEBASEPATH/$NODE"
  rm -rf $NODEBASEPATH/$NODE
  mkdir $NODEBASEPATH/$NODE

  echo "Setting up origintrail RC file for $NODE"
  $MAINPATH/data/setup-noderc.sh $i

  echo "Creating $NODE"
  OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $PORT3:$PORT3 -p $PORT2:$PORT2 -p $PORT1:$PORT1 -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)
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

  sleep 4s

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

  echo "rm -rf $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data"
  rm -rf $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data

  echo "mv /root/backup$i/data $($DOCKER_INSPECT_UPPER $NODE)/ot-node/"
  mv /root/backup$i/data $($DOCKER_INSPECT_UPPER $NODE)/ot-node/
  if [[ $? -ne 0 ]]; then
    echo "Moving /ot-node/data into $NODE directory failed"
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
    echo "chmod -R 777 /ot-node/data for $NODE failed !"
    exit 1
  fi

  chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data
  if [[ $? -ne 0 ]]; then
    echo "chown -R root:root /ot-node/data for $NODE failed !"
    exit 1
  fi

  echo "mv /root/backup$i/arangodb* $($DOCKER_INSPECT_UPPER $NODE)/var/lib/"
  mv -v /root/backup$i/arangodb* $($DOCKER_INSPECT_UPPER $NODE)/var/lib/
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

  echo "docker start $NODE"
  docker start $NODE
  if [[ $? -ne 0 ]]; then
    echo "docker start $NODE failed"
    exit 1
  fi

done

echo "########## RESTORE COMPLETE ! REMEMBER TO DELETE YOUR BACKUP FOLDER ON ROOT IF EVERYTHING WORKS ! ##########"
echo "REMEMBER TO RUN update-arango-vars.sh after the install to get the correct arangod values for MN docker"
