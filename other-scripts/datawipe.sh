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

for var;
do
  NODE="$NODE_NAME$var"

  echo "rm $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db"
  rm $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db

  echo "rm -rf $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS"
  rm -rf $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS

  docker restart $NODE
done