#!/bin/bash

# To wipe otnode1, otnode3 and otnode5, run ./data-wipe.sh 1 3 5

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

N1=$'\n'

for var
do
  PORT1=$((var+2999))
  PORT2=$((var+5277))
  PORT3=$((var+8899))
  NODE="$NODE_NAME$var"
  
  echo "rm -rf $NODEBASEPATH/temp$var"
  rm -rf $NODEBASEPATH/temp$var

  echo "mkdir $NODEBASEPATH/temp$var"
  mkdir $NODEBASEPATH/temp$var
  
  echo "docker start $NODE"
  docker start $NODE

  sleep 4s

  echo "docker cp $NODE:/ot-node/data/identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/identity.json $NODEBASEPATH/temp$var/

  echo "docker cp $NODE:/ot-node/data/erc725_identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/erc725_identity.json $NODEBASEPATH/temp$var/

  echo "docker cp $NODE:/ot-node/data/xdai_erc725_identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/xdai_erc725_identity.json $NODEBASEPATH/temp$var/

  echo "docker cp $NODE:/ot-node/data/polygon_erc725_identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/polygon_erc725_identity.json $NODEBASEPATH/temp$var/

  echo "docker stop $NODE"
  docker stop $NODE

done

while true; do
  read -p "Please confirm deletion of docker container: [1]Confirm [2]Decline [E]xit: " choice
  case "$choice" in
      [1cC]* ) echo -e "Deleting docker container."; break;;
      [2dD]* ) echo -e "Operation canceled. Node IDs successfully backed up to $NODEBASEPATH"; return 0;;
      [Ee]* ) echo "Stopped by user"; return 0;;
      * ) echo "Please make a valid choice and try again.";;
  esac
done

echo "docker rm -f $NODE"
docker rm -f $NODE

for var
do
  PORT1=$((var+2999))
  PORT2=$((var+5277))
  PORT3=$((var+8899))
  NODE="$NODE_NAME$var"

  echo "Setting up Firewall rules"
  ufw allow $PORT1 && ufw allow $PORT2 && ufw allow $PORT3

  echo "removing old $NODEBASEPATH/$NODE and making new directory $NODEBASEPATH/$NODE"
  rm -rf $NODEBASEPATH/$NODE
  mkdir $NODEBASEPATH/$NODE

  echo "Setting up origintrail RC file for $NODE"
  $MAINPATH/data/setup-noderc.sh $var

  ID_IMPORT=false

	for (( t=0; t<3; t++ ))
	do
    echo "Creating $NODE"
    OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $PORT3:$PORT3 -p $PORT2:$PORT2 -p $PORT1:$PORT1 -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "Docker creation FAILED:${N1}$OUTPUT"
      exit 1
    fi

    echo "docker start $NODE"
    docker start $NODE
    if [[ $? -ne 0 ]]; then
      echo "Docker start FAILED"
      exit 1
    fi

    sleep 5s

    echo "docker stop $NODE"
    docker stop $NODE
    if [[ $? -ne 0 ]]; then
      echo "Docker stop FAILED"
      exit 1
    fi

    sleep 1s

    echo "mv $NODEBASEPATH/temp$var/* $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/"
    mv $NODEBASEPATH/temp$var/* $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/
    if [[ $? -eq 0 ]]; then
      #success, stop trying
      echo "Node ID import to new node SUCCESS"
      ID_IMPORT=true
      break
    else
      docker rm $NODE
      echo "Node ID import FAILED, retrying..."
    fi
	done

	if [[ ! $ID_IMPORT ]]; then
    echo "Node ID import FAILED after 3 attempts."
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

  echo "docker start $NODE"
  docker start $NODE
  if [[ $? -ne 0 ]]; then
    echo "docker start $NODE failed"
    exit 1
  fi

  sleep 3s

  echo "changing arangod vars to be compatible with MN docker"

  version=5.1.2
  write_buffer_size=67108864
  total_write_buffer_size=536870912
  #max_total_wal_size=1024000
  max_write_buffer_number=2
  dynamic_level_bytes=true
  block_cache_size=536870912
  server_statistics=false

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf" ]; then
    sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size '$write_buffer_size' --rocksdb.total-write-buffer-size '$total_write_buffer_size' --rocksdb.max-write-buffer-number '$max_write_buffer_number' --rocksdb.dynamic-level-bytes '$dynamic_level_bytes' --rocksdb.block-cache-size '$block_cache_size' --server.statistics '$server_statistics' /g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf
  fi

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/$version/testnet/supervisord.conf" ]; then
    sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size '$write_buffer_size' --rocksdb.total-write-buffer-size '$total_write_buffer_size' --rocksdb.max-write-buffer-number '$max_write_buffer_number' --rocksdb.dynamic-level-bytes '$dynamic_level_bytes' --rocksdb.block-cache-size '$block_cache_size' --server.statistics '$server_statistics' /g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/$version/testnet/supervisord.conf
  fi

  docker update --memory=5G --memory-swap=10G $NODE
  
  echo "docker restart $NODE"
  docker restart $NODE

done


