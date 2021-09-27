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

N1=$'\n'

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"
  
  rm $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup

done