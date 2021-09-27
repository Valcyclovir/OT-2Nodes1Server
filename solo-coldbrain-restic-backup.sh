#!/bin/bash

# Use this script to perform a one time backup. You need to define argument of NODE first.

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

NODE=$1

SQLITE_INSTALLED=$(dpkg-query -W -f='${Status}' sqlite3 2>/dev/null | grep -c "ok installed")
if [[ $SQLITE_INSTALLED -eq 0 ]]; then
  $MAINPATH$SENDSERVER "Installing sqlite3 to backup system.db"
  apt install sqlite3
fi

if [ -z $NODE ]; then
  echo "Must provide NODE variable before proceeding. Before trying this script again, input NODE=NODE_NAME_HERE on the command prompt" 1>&2
  exit 1
fi

echo "Using sqlite3 to backup system.db to system.db.backup"
sqlite3 $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/system.db ".backup '$($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/system.db.backup'"
if [[ $STATUS -ne 0 ]]; then
  $MAINPATH$SENDSERVER "Backup of system.db using sqlite3 on $NODE FAILED"
  exit 1
fi

echo "docker exec $NODE supervisorctl stop all"
docker exec $NODE supervisorctl stop all

echo "Uploading $NODE data to storage server"
OUTPUT=$($MAINPATH/restic backup --tag $NODE $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data $NODEBASEPATH/$NODE/.origintrail_noderc $($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3 $($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3APPS --exclude="brick.img" "system.db-journal" 2>&1)
echo "$OUTPUT"

echo "Restarting $NODE"
docker restart $NODE
