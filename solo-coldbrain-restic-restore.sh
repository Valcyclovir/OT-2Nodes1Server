#!/bin/bash

# Use this script if you want to restore one particular node in your multinode server. The provenance of the coldbrain backup must come from your previous multinode setup. 
# This script requires that you have node_port, node_rpc_port, node_remote_control_port defined on .origintrail_noderc
# You need to define argument of NODE first.

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

if [ -z "$1" ]; then
  echo "No NODE argument supplied. Please provide argument NODE before running this script again"
  exit 1
fi

echo "Initial node server setup"
$MAINPATH/data/initial-node-setup.sh
if [[ $STATUS -ne 0 ]]; then
  echo "Initial node server setup FAILED"
  exit 1
fi

echo "$MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1"
SNAPSHOT=$($MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1)
if [[ $STATUS -ne 0 ]]; then
  echo "Getting restic snapshot for $NODE FAILED"
  exit 1
fi

echo "mkdir $BACKUPPATH"
mkdir $BACKUPPATH
if [[ $STATUS -ne 0 ]]; then
  echo "Creating $BACKUPPATH directory FAILED"
  exit 1
fi

echo "mkdir $NODEBASEPATH/$NODE"
rm -rf $NODEBASEPATH/$NODE
mkdir $NODEBASEPATH/$NODE
if [[ $STATUS -ne 0 ]]; then
  echo "Creating $NODEBASEPATH/$NODE directory FAILED"
  exit 1
fi

echo "$MAINPATH/restic restore $SNAPSHOT --target $BACKUPPATH"
$MAINPATH/restic restore $SNAPSHOT --target $BACKUPPATH
if [[ $STATUS -ne 0 ]]; then
  echo "Restoring snapshot to $BACKUPPATH failed"
  exit 1
fi

echo "mv $BACKUPPATH/root/$NODE/.origintrail_noderc $NODEBASEPATH/$NODE/"
mv $BACKUPPATH/root/$NODE/.origintrail_noderc $NODEBASEPATH/$NODE/
if [[ $STATUS -ne 0 ]]; then
  echo "Moving config file to $NODE failed"
  exit 1
fi

echo "mv $BACKUPPATH/var/lib/docker/overlay2/*/merged/var/lib/arango* $BACKUPPATH/"
mv $BACKUPPATH/var/lib/docker/overlay2/*/merged/var/lib/arango* $BACKUPPATH/

echo "mv $BACKUPPATH/var/lib/docker/overlay2/*/merged/ot-node/data $BACKUPPATH/"
mv $BACKUPPATH/var/lib/docker/overlay2/*/merged/ot-node/data $BACKUPPATH/

NODE_PORT=$(cat $NODEBASEPATH/$NODE/.origintrail_noderc | jq -r '.node_port')
NODE_RPC_PORT=$(cat $NODEBASEPATH/$NODE/.origintrail_noderc | jq -r '.node_rpc_port')
NODE_REMOTE_CONTROL_PORT=$(cat $NODEBASEPATH/$NODE/.origintrail_noderc | jq -r '.node_remote_control_port')

firewall="`ufw status | grep Status | cut -c 9-`"
if [[ $firewall = "inactive" ]]; then
  echo "Enabling firewall"
  ufw allow 22/tcp && yes | ufw enable
fi

echo "Setting up Firewall rules"
ufw allow $NODE_REMOTE_CONTROL_PORT && ufw allow $NODE_PORT && ufw allow $NODE_RPC_PORT
if [[ $STATUS -ne 0 ]]; then
  echo "Setting up Firewall rules for $NODE failed"
  exit 1
fi

echo "Creating $NODE"
OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $NODE_RPC_PORT:$NODE_RPC_PORT -p $NODE_PORT:$NODE_PORT -p $NODE_REMOTE_CONTROL_PORT:$NODE_REMOTE_CONTROL_PORT -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)
if [[ $STATUS -ne 0 ]]; then
  echo "$NODE creation failed"
  exit 1
fi

echo "Starting docker $NODE"
docker start $NODE
if [[ $STATUS -ne 0 ]]; then
  echo "Docker start FAILED:${N1}"
  exit 1
fi

sleep 2s

echo "rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data"
rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data

echo "mv $BACKUPPATH/data $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data"
mv $BACKUPPATH/data $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data
if [[ $STATUS -ne 0 ]]; then
  echo "Moving /ot-node/data into $NODE directory failed"
  exit 1
fi

echo "Enable docker always restart"
OUTPUT=$(docker update --restart=always $NODE 2>&1)
if [[ $STATUS -ne 0 ]]; then
  echo "Docker update for $NODE failed"
  exit 1
fi

echo "Adding rocksdb variables to /ot-node/init/testnet/supervisord.conf for $NODE"
sed -i 's/command=arangod.*/command=arangod --rocksdb.write-buffer-size 67108864 --rocksdb.total-write-buffer-size 536870912 --rocksdb.max-total-wal-size 1024000 --rocksdb.max-write-buffer-number 2 --rocksdb.dynamic-level-bytes false --rocksdb.block-cache-size 536870912/g' $($DOCKER_INSPECT_MERGED $NODE)/ot-node/init/testnet/supervisord.conf
if [[ $STATUS -ne 0 ]]; then
  echo "Changing rocksdb vars for $NODE FAILED"
  exit 1
fi

echo "docker stop $NODE"
docker stop $NODE
if [[ $STATUS -ne 0 ]]; then
  echo "Docker stop $NODE failed"
  exit 1
fi

echo "rm -rf $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS"
rm -rf $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS
if [[ $STATUS -ne 0 ]]; then
  echo "Removing docker $NODE directories failed"
  exit 1
fi

echo "chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data"
chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data
if [[ $STATUS -ne 0 ]]; then
  echo "chmod -R 777 /ot-node/data for $NODE failed !"
  exit 1
fi

echo "chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data"
chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data
if [[ $STATUS -ne 0 ]]; then
  echo "chown -R root:root /ot-node/data for $NODE failed !"
  exit 1
fi

echo "mv $BACKUPPATH/arangodb* $($DOCKER_INSPECT_UPPER $NODE)/var/lib/"
mv $BACKUPPATH/arangodb* $($DOCKER_INSPECT_UPPER $NODE)/var/lib/
if [[ $STATUS -ne 0 ]]; then
  echo "Moving /var/lib/arangodb files into $NODE directory failed"
  exit 1
fi

echo "Setting chmod -R 777 on arangodb3 files"
chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS
chmod -R 777 $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3

echo "Setting chown -R root:root on arangodb3 files"
chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3APPS
chown -R root:root $($DOCKER_INSPECT_UPPER $NODE)$ARANGODB3
if [[ $STATUS -ne 0 ]]; then
  echo "chown -R root:root /var/lib/arangodb for $NODE failed !"
  exit 1
fi

if [ -z "$(ls -A $BACKUPPATH)" ]; then
  echo "rm -rf $BACKUPPATH"
  rm -rf $BACKUPPATH
fi

echo "docker start $NODE"
docker start $NODE
if [[ $STATUS -ne 0 ]]; then
  echo "Docker start $NODE failed"
  exit 1
fi

docker logs -f $NODE
