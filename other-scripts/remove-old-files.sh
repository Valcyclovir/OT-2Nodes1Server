#!/bin/bash

# Define version argument when running this script. 

if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
fi

source "$MAINPATH/data/fixed-variables.sh"

old_version=$1
new_version=$2

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"

  echo "Removing old OT node $version for $NODE"
  rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/$old_version

  echo "removing $version/data-migration files"
  rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/$new_version/data-migration
  
  echo "removing ot-node/init files"
  rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/init

done
