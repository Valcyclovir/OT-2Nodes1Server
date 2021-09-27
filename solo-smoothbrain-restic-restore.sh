#!/bin/bash

# Use this script if you want to restore one particular node in your multinode server.

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

if [ -z $NODE ]; then
  echo "Must provide NODE and BACKUP variables before proceeding. Before trying this script again, type export NODE=NODE_NAME_HERE on the command prompt"
  exit 1
else
  echo "Variable provided, proceeding with coldbrain-restore.sh"
fi

echo "$MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1"
SNAPSHOT=$($MAINPATH/restic snapshots -H $HOSTNAME --tag $NODE | grep $HOSTNAME | cut -c1-8 | tail -n 1)

echo "mkdir $BCAKUPPATH"
rm -rf $BCAKUPPATH
mkdir $BCAKUPPATH

echo "mkdir $NODEBASEPATH/$NODE"
rm -rf $NODEBASEPATH/$NODE
mkdir $NODEBASEPATH/$NODE

echo "Copying restore script over to /root"
cp $MAINPATH/data/restore.sh /root/
chmod +x /root/restore.sh
  if [[ $STATUS -ne 0 ]]; then
  echo "Docker copy restore script FAILED:${N1}$OUTPUT"
  exit 1
fi

echo "$MAINPATH/restic restore $SNAPSHOT --target $BCAKUPPATH"
$MAINPATH/restic restore $SNAPSHOT --target $BCAKUPPATH

echo "mv -v $BCAKUPPATH/root/$NODE/.origintrail_noderc $NODEBASEPATH/$NODE/"
mv -v $BCAKUPPATH/root/$NODE/.origintrail_noderc $NODEBASEPATH/$NODE/

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

echo "Creating $NODE"
OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $NODE_RPC_PORT:$NODE_RPC_PORT -p $NODE_PORT:$NODE_PORT -p $NODE_REMOTE_CONTROL_PORT:$NODE_REMOTE_CONTROL_PORT -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)

echo "Enable docker always restart"
OUTPUT=$(docker update --restart=always $NODE 2>&1)

echo "cd to root"
cd

echo "Modifying container name and backup directory in restore script"
sed -i -E 's|CONTAINER_NAME=.*|CONTAINER_NAME='"$NODE"'|g' restore.sh
sed -i -E 's|BACKUPDIR=.*|BACKUPDIR='"$BCAKUPPATH"'|g' restore.sh
  if [[ $STATUS -ne 0 ]]; then
  echo "restore script modification FAILED"
  exit 1
fi

echo "Running restore script"
./restore.sh
  if [[ $STATUS -ne 0 ]]; then
  echo "Restore FAILED:${N1}$OUTPUT"
  exit 1
fi

echo "docker start $NODE"
docker start $NODE

sleep 15s

echo "Adding rocksdb variables to /ot-node/current/testnet/supervisord.conf for $NODE"
sed -i 's/command=arangod.*/command=arangod --rocksdb.total-write-buffer-size 536870912 --rocksdb.block-cache-size 536870912/g' $($DOCKER_INSPECT_UPPER $NODE)/ot-node/init/testnet/supervisord.conf

echo "docker restart $NODE"
docker restart $NODE

docker logs -f $NODE

echo "########## SMOOTHBRAIN RESTORE FOR $NODE COMPLETE !! ##########" 
