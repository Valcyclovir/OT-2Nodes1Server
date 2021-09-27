#!/bin/bash

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
fi

JOBS_WON=($(for i in `docker ps -q`; do docker logs --since 24h $i | grep 've been chosen' | wc -l; done | awk 'NF{sum+=$1} END {print sum}'))

JOBS_WON_ID=($(for i in `docker ps -q`; do docker logs --since 24h $i | grep 've been chosen' | grep -Eo '0x[a-z0-9]+'; done))

TRAC_WON=$(for x in "${JOBS_WON_ID[@]}"; do TOKEN=($(curl -sX GET "https://v5api.othub.info/api/Job/detail/$x" -H  "accept: text/plain" | jq '.TokenAmountPerHolder' | cut -d'"' -f2)); echo ${TOKEN[@]}; done | awk '{ total += $1} END {print total}')

$MAINPATH/data/send.sh "$TRAC_WON TRAC ($JOBS_WON jobs) awarded today"