#!/bin/bash

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

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
  NODE=$NODE_NAME$i

  if [ -f "$($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3/engine-rocksdb/brick.img" ]; then
    rm $($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3/engine-rocksdb/brick.img
    echo "Pruning stopped for $NODE"
  fi

done
