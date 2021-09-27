#!/bin/bash

# Define version argument when running this script. 

if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
fi

source "$MAINPATH/data/fixed-variables.sh"


for (( i=1; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"

  docker exec $NODE supervisorctl stop all

  sqlite3 $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db 'vacuum;'

  sqlite3 $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db 'reindex;'

  sqlite3 $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db 'pragma optimize;'

  docker restart $NODE

done
