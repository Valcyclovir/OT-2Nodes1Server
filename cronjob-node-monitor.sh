#!/bin/bash

# This script requires the following app to be installed:
# apt install jq

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
fi

source "$MAINPATH/data/fixed-variables.sh"

SPACE=$(df -m / | grep sda | awk '{print $5}')
SPACE=$(sed 's|%||' <<< $SPACE)
echo Disk space is $SPACE% full.

if [ $SPACE -ge $DISK_CHECK_THRESHOLD ]; then
  $MAINPATH/data/send.sh "Disk space is $SPACE% full."
fi

JOBS=$(curl -sX GET "https://v5api.othub.info/api/jobs/jobcreatedcountinperiod?timePeriod=hours&time=1&blockchainID=2")

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
  NODE=$NODE_NAME$i
  
  UPDATE=$(docker logs $NODE --since "$BID_CHECK_INTERVAL_DOCKER" | grep "OT Node updated to" | wc -l)

  if [ $UPDATE -ge 1 ]; then
    echo "Changing arangod variables for $NODE"
    sed -i 's/command=arangod.*/command=arangod --rocksdb.total-write-buffer-size 536870912 --rocksdb.block-cache-size 536870912/g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/5.1.1/testnet/supervisord.conf
    if [[ $? -ne 0 ]]; then
      $MAINPATH/data/sendnode.sh $i "Error: arangod variables update failed for $NODE"
    fi
    
    echo "docker restart $NODE"
    docker restart $NODE
    if [[ $? -ne 0 ]]; then
      $MAINPATH/data/sendnode.sh $i "Error : docker restart $NODE failed"
    fi
  fi

  BIDS=$(docker logs $NODE --since "$BID_CHECK_INTERVAL_DOCKER" | grep Accepting | wc -l)
  
  if [ $BIDS -eq 0 ]; then
    if [ $JOBS -ne 0 ]; then
      $MAINPATH/data/sendnode.sh $i "Has not bid since $BID_CHECK_INTERVAL_DOCKER and jobs are being issued, restarting node"
      docker restart $NODE
      if [[ $? -ne 0 ]]; then
        echo "Error : docker restart $NODE failed."
      fi
    fi
  fi

  OFFER_ID=($(docker logs $NODE --since "$BID_CHECK_INTERVAL_DOCKER" | grep 've been chosen' | grep -Eo '0x[a-z0-9]+'))

  if [[ $BID_CHECK_JOB_NOTIFY_ENABLED == "true" ]]; then
    for x in "${OFFER_ID[@]}"
    do
      TOKEN_ARRAY=($(curl -sX GET "https://v5api.othub.info/api/Job/detail/$x" -H  "accept: text/plain" | jq '.TokenAmountPerHolder' | cut -d'"' -f2))
      JOBTIME_ARRAY=($(curl -sX GET "https://v5api.othub.info/api/Job/detail/$x" -H  "accept: text/plain" | jq '.HoldingTimeInMinutes'))
      BLOCKCHAIN_ARRAY=($(curl -sX GET "https://v5api.othub.info/api/Job/detail/$x" -H  "accept: text/plain" | jq '.BlockchainDisplayName' | cut -d'"' -f2))
      DAYS=$(expr ${JOBTIME_ARRAY[@]} / 60 / 24)
      $MAINPATH/data/sendnode.sh $i "Job awarded on ${BLOCKCHAIN_ARRAY[@]}: $DAYS days at ${TOKEN_ARRAY[@]} TRAC"
    done
  fi

  OUTPUT=$(docker ps | grep $NODE | wc -l)
  if [ $OUTPUT -eq 0 ]; then
    $MAINPATH/data/sendnode.sh $i "Node is NOT running!"
  fi

  if [ $PRUNE_LOW_VALUE_DATASETS == "true" ]; then
    NEXT_NODE=$NODE_NAME$(($i+1))
    PRUNING_SUCCESS=$(docker logs $NODE --since "$BID_CHECK_INTERVAL_DOCKER" | grep "Successfully pruned" | wc -l)

    if [ $PRUNING_SUCCESS -ge 1 ] && [ -f "$($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3/engine-rocksdb/brick.img" ]; then
      if [[ $PRUNING_NOTIFY_ENABLED == "true" ]]; then
        $MAINPATH/data/send.sh "Successfully pruned $NODE"
      fi
      rm $($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3/engine-rocksdb/brick.img
      
      DISK_SPACE_REMAINING=$(df -BG | grep "overlay" | cut -d G -f 3 | sed -n 1p | sed 's/^ *//g')
      BRICK=$(($DISK_SPACE_REMAINING-50))

      if [[ $i -eq $NODE_TOTAL ]]; then
        fallocate -l "$BRICK"g $($DOCKER_INSPECT_MERGED "$NODE_NAME"1)$ARANGODB3/engine-rocksdb/brick.img
        if [[ $? -eq 0 ]]; then
          if [[ $PRUNING_NOTIFY_ENABLED == "true" ]]; then
            $MAINPATH/data/send.sh "Beginning pruning with "$BRICK"g sized brick on "$NODE_NAME"1"
          fi
        fi
        docker restart "$NODE_NAME"1
      else
        fallocate -l "$BRICK"g $($DOCKER_INSPECT_MERGED $NEXT_NODE)$ARANGODB3/engine-rocksdb/brick.img
        if [[ $? -eq 0 ]]; then
          if [[ $PRUNING_NOTIFY_ENABLED == "true" ]]; then
            $MAINPATH/data/send.sh "Beginning pruning with "$BRICK"g sized brick on $NEXT_NODE"
          fi
        fi
        docker restart $NEXT_NODE
      fi
    fi
  fi

done
