#!/bin/bash

# Use this script if your node stopped working due to arango error on reboot or restart
# Remember to add your node name as an argument when running this script
# Example : ./solo-arango-bug-fix.sh otnode

NODE=$1

echo "docker restart $NODE"
docker restart $NODE

sleep 1s

echo "docker exec $NODE supervisorctl stop all"
docker exec $NODE supervisorctl stop all

sleep 2s

echo "docker exec $NODE supervisorctl restart arango otnode otnodelistener remote_syslog"
docker exec $NODE supervisorctl restart arango otnode otnodelistener remote_syslog

echo "docker logs -f --since 5m $NODE"
docker logs -f --since 5m $NODE