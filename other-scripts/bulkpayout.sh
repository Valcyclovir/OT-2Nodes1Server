#!/bin/bash

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
fi

source "$MAINPATH/data/fixed-variables.sh"

for var
do
  PORT1=$((var+2999))
  PORT2=$((var+5277))
  PORT3=$((var+8899))
  NODE="$NODE_NAME$var"
  NODEID="NODE_ID_$var"

    curl -X GET "https://v5api.othub.info/api/nodes/DataHolder/${!NODEID}/jobs" -H "accept: text/plain" | jq -r '. - map(select(.Status | contains ("Active"))) | .[] .OfferId' > offerids.txt

    cat offerids.txt | while read line; do docker exec $NODE curl -s -X GET http://127.0.0.1:$PORT3/api/latest/payout?offer_id=$line; done

done