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
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\e[1m'
UNBOLD='\e[0m'

shopt -s nocasematch

echo_color() {
  echo -e "$1$2$NC"
}

echo_header() {
  echo && echo_color "$YELLOW $1" && echo
}

perform_step() {
  echo -n "$2: "
  OUTPUT=$($1 2>&1)
  if [[ $? -ne 0 ]]; then
    echo_color $RED "FAILED"
    echo -e "${N1}Step failed. Output of error is:${N1}${N1}$OUTPUT"
    return 0
  else
    echo_color $GREEN "OK"
  fi
}

for var
do

  PORT1=$((var+2999))
  PORT2=$((var+5277))
  PORT3=$((var+8899))
  NODE="$NODE_NAME$var"
  
  perform_step "rm -rf $NODEBASEPATH/temp$var" "Removing old temp path"
  perform_step "mkdir $NODEBASEPATH/temp$var" "Making new temp path directory"
  perform_step "docker start $NODE" "Start $NODE"

  sleep 4s

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/identity.json" ]; then
    perform_step "docker cp $NODE:/ot-node/data/identity.json $NODEBASEPATH/temp$var/" "Copying identity.json"
  fi

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/erc725_identity.json" ]; then
    perform_step "docker cp $NODE:/ot-node/data/erc725_identity.json $NODEBASEPATH/temp$var/" "Copying erc725_identity.json"
  fi

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/xdai_erc725_identity.json" ]; then
    perform_step "docker cp $NODE:/ot-node/data/xdai_erc725_identity.json $NODEBASEPATH/temp$var/" "Copying xdai_erc725_identity.json"
  fi

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/polygon_erc725_identity.json" ]; then
    perform_step "docker cp $NODE:/ot-node/data/polygon_erc725_identity.json $NODEBASEPATH/temp$var/" "Copying polygon_erc725_identity.json"
  fi
  
  perform_step "docker stop $NODE" "Stopping $NODE"

  # while true; do
  #   read -p "Please confirm deletion of $NODE: [1]Confirm [2]Decline [E]xit: " choice
  #   case "$choice" in
  #       [1cC]* ) perform_step "docker rm -f $NODE" "Deleting $NODE"; break;;
  #       [2dD]* ) echo -e "Operation canceled. Node IDs successfully backed up to $NODEBASEPATH"; return 0;;
  #       [Ee]* ) echo "Stopped by user"; return 0;;
  #       * ) echo "Please make a valid choice and try again.";;
  #   esac
  # done

  perform_step "docker rm -f $NODE" "Deleting $NODE"

  echo -n "Setting up Firewall Rules: "
  ufw allow $PORT1 && ufw allow $PORT2 && ufw allow $PORT3
  if [[ $? -ne 0 ]]; then
    echo_color $RED "FAILED"
    echo -e "${N1}Step failed. Output of error is:${N1}${N1}$OUTPUT"
    return 0
  else
    echo_color $GREEN "OK"
  fi
  
  perform_step "rm -rf $NODEBASEPATH/$NODE" "Deleting old RC file"

  perform_step "mkdir $NODEBASEPATH/$NODE" "Making new RC file directory"

  perform_step "$MAINPATH/data/setup-noderc.sh $var" "Setting up origintrail RC file for $NODE"

  ID_IMPORT=false
	for (( t=0; t<3; t++ ))
	do
    perform_step "docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $PORT3:$PORT3 -p $PORT2:$PORT2 -p $PORT1:$PORT1 -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet" "Creating new $NODE"

    perform_step "docker start $NODE" "Starting $NODE"

    sleep 5s

    perform_step "docker stop $NODE" "Stopping $NODE"

    sleep 1s

    echo -n "Moving identities to $NODE: "
    mv $NODEBASEPATH/temp$var/* $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/
    if [[ $? -eq 0 ]]; then
      #success, stop trying
      echo_color $GREEN "OK"
      ID_IMPORT=true
      break
    else
      docker rm $NODE
      echo_color $YELLOW "Node ID import FAILED, retrying..."
    fi
	done

	if [[ ! $ID_IMPORT ]]; then
    echo_color $RED "Node ID import FAILED after 3 attempts."
    exit 1
  fi

  perform_step "chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data" "Setting chmod to $NODE"
  
  perform_step "chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data" "Setting chown to $NODE"

  sleep 3s

  version=5.1.2
  write_buffer_size=67108864
  total_write_buffer_size=536870912
  #max_total_wal_size=1024000
  max_write_buffer_number=2
  dynamic_level_bytes=true
  block_cache_size=536870912
  server_statistics=false

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf" ]; then
    echo -n "Changing arangod vars to be compatible with MN docker: "
    sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size '$write_buffer_size' --rocksdb.total-write-buffer-size '$total_write_buffer_size' --rocksdb.max-write-buffer-number '$max_write_buffer_number' --rocksdb.dynamic-level-bytes '$dynamic_level_bytes' --rocksdb.block-cache-size '$block_cache_size' --server.statistics '$server_statistics' /g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf
    if [[ $? -ne 0 ]]; then
      echo_color $RED "FAILED"
      echo -e "${N1}Step failed. Output of error is:${N1}${N1}$OUTPUT"
      return 0
    else
      echo_color $GREEN "OK"
    fi
  fi

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/$version/testnet/supervisord.conf" ]; then
    echo -n "Changing arangod vars to be compatible with MN docker: "
    sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size '$write_buffer_size' --rocksdb.total-write-buffer-size '$total_write_buffer_size' --rocksdb.max-write-buffer-number '$max_write_buffer_number' --rocksdb.dynamic-level-bytes '$dynamic_level_bytes' --rocksdb.block-cache-size '$block_cache_size' --server.statistics '$server_statistics' /g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/$version/testnet/supervisord.conf
    if [[ $? -ne 0 ]]; then
      echo_color $RED "FAILED"
      echo -e "${N1}Step failed. Output of error is:${N1}${N1}$OUTPUT"
      return 0
    else
      echo_color $GREEN "OK"
    fi  
  fi

  perform_step "docker update --memory=5G --memory-swap=10G $NODE" "Added swap to $NODE"

  perform_step "docker restart $NODE" "Restarting $NODE"

done


