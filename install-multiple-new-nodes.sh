#!/bin/bash

# This script is for installing from one to a million new nodes on a new server.

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
  export NODEBASEPATH="/root"
fi
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
  PORT1=$((i+2999))
  PORT2=$((i+5277))
  PORT3=$((i+8899))
  NODE="$NODE_NAME$i"

  echo "Setting up Firewall rules"
  ufw allow $PORT1 && ufw allow $PORT2 && ufw allow $PORT3

  echo "Setting up origintrail RC file for $NODE"
  $MAINPATH/data/setup-noderc.sh $i

  echo "Starting docker $NODE"
  OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $PORT3:$PORT3 -p $PORT2:$PORT2 -p $PORT1:$PORT1 -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Docker creation FAILED:${N1}$OUTPUT"
    exit 1
  fi

  echo "docker start $NODE"
  docker start $NODE
  if [[ $? -ne 0 ]]; then
    echo "docker start $NODE failed"
    exit 1
  fi

  echo "sleep 30s, please wait"
  sleep 30s

  echo "Enable docker always restart"
  OUTPUT=$(docker update --restart=always $NODE 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Docker restart update FAILED:${N1}$OUTPUT"
    exit 1
  fi
  
  echo "Restarting $NODE"
  docker restart $NODE
  if [[ $? -ne 0 ]]; then
    echo "Docker start FAILED:${N1}$OUTPUT"
    exit 1
  fi

  sleep 2s

  echo "changing PRAGMA journal_mode to WAL"
  sqlite3 $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db 'PRAGMA journal_mode=WAL;'
  if [[ $? -ne 0 ]]; then
    echo "changing PRAGMA journal_mode to WAL for $NODE failed"
    continue
  fi

done

echo "########## MULTINODE INSTALLATION COMPLETE ! ##########"
echo "########## REMEMBER TO SAVE YOUR IDENTITY.JSON AND ERC725_IDENTITY.JSON FILES AFTER NODE CREATION !!"
echo "FIRST, TRANSFER YOUR ERC725 IDENTITY AND NODE ID TO /ROOT" 
echo "Do individually by changing "otnode" to the node name, i.e. "otnode1""
echo "docker cp otnode:/ot-node/data/xdai_erc725_identity.json /root/xdai_erc725_identity.js"
echo "docker cp otnode:/ot-node/data/identity.json /root/identity.js"
echo "REMEMBER TO RUN update-arango-vars.sh after the install to get the correct arangod values for MN docker"

