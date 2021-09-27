#!/bin/bash                                                                                                                                                         
# Use this script if your nodes stop working due to arango error on reboot or restart
# This will fix all your nodes at once

if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
fi

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
  NODE="$NODE_NAME$i"
  
  echo "docker restart $NODE"
  docker restart $NODE

  sleep 1s

  echo "docker exec $NODE supervisorctl stop all"
  docker exec $NODE supervisorctl stop all

  sleep 2s

  echo "docker exec $NODE supervisorctl restart arango otnode otnodelistener remote_syslog"
  docker exec $NODE supervisorctl restart arango otnode otnodelistener remote_syslog

  sleep 5s

done

echo "ALL NODES SUCCESSFULLY FIXED AND RESTARTED ! USE BELOW COMMAND TO CHECK ALL NODE LOGS"
echo "docker ps --format='{{.Names}}' | xargs -P0 -d '\n' -n1 sh -c 'docker logs -f --since 5m "$1" | sed "s/^/$1: /"' _"