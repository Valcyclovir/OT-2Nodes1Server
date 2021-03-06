#!/bin/bash

# This script will begin the pruning process that will be automated alongside with cronjob-node-monitor.sh

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
fi

source "$MAINPATH/data/fixed-variables.sh"

if [ $PRUNE_LOW_VALUE_DATASETS == "true" ]; then
  DISK_SPACE_REMAINING=$(df -BG | grep "overlay" | cut -d G -f 3 | sed -n 1p | sed 's/^ *//g')
  DISK_SPACE_TOTAL=$(df -BG | grep "overlay" | cut -d G -f 1 | rev | cut -d ' ' -f 1 | rev | sed -n 1p | sed 's/^ *//g')
  BRICK=$(($DISK_SPACE_TOTAL/2))

  fallocate -l "$BRICK"g $($DOCKER_INSPECT_MERGED "$NODE_NAME"1)$ARANGODB3/engine-rocksdb/brick.img
  echo "adding a "$BRICK"g sized brick into your arangodb3 folder on "$NODE_NAME"1"

  docker restart "$NODE_NAME"1
  echo "Beginning pruning on "$NODE_NAME"1"

fi