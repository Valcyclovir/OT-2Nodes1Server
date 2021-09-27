#!/bin/bash

###############################################
# Use this script to migrate existing nodes on individual servers to a multinode server. 
# 
# IMPORTANT :  
# This script assumes that you have backups ready in /root/backup1 /root/backup2 ... /root/backup10 and so on, depending on the amount of nodes you want to migrate into 1 server.
# In order to transfer backup files over from your current node to your new multinode server, you can use the scp -r function :
# For example, for first node, in your old node, run : scp -r "PATH_TO_BACKUP_FILE" root@NEW_MULTINODE_SERVER_IP:/root/backup1
# for your second node, run : scp -r "PATH_TO_BACKUP_FILE" root@NEW_MULTINODE_SERVER_IP:/root/backup2
# 
#
# This script will also return an error if your backup files are in /root/backup1/202... /root/backup2/202... and not in /root/backup1 /root/backup2 ...
# Run these scripts to move your backup files for your first node in the correct directory (use backup2 instead for second node, backup3 for your third node, etc.) :
#
# mv -v /root/backup1/20*/* /root/backup1
# mv -v /root/backup1/20*/.origintrail_noderc /root/backup1
# rm -rf /root/backup1/20*
# rm -rf /root/backup1/lost+found
#
# Good luck !
#
###############################################

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
  export NODEBASEPATH="/root"
fi

source "$MAINPATH/data/fixed-variables.sh"

STATUS=$?
N1=$'\n'

echo "Initial node server setup"
$MAINPATH/data/initial-node-setup.sh
if [ $? -ne 0 ]; then
  echo "Initial node server setup FAILED"
  exit 1
fi

echo "Copying restore script over to /root"
cp $MAINPATH/data/restore.sh /root/
if [ $? -ne 0 ]; then
  echo "Docker copy restore script FAILED:${N1}$OUTPUT"
  exit 1
fi

firewall="`ufw status | grep Status | cut -c 9-`"
if [[ $firewall = "inactive" ]]; then
  echo "Enabling firewall"
  ufw allow 22/tcp && yes | ufw enable
fi

for (( i=$NODE_COUNTER; i<=$NODE_TOTAL; i++ ))
do
  PORT1=$((i+2999))
  PORT2=$((i+5277))
  PORT3=$((i+8899))
  NODE="$NODE_NAME$i"

  if [[ -d "/root/backup$i/arangodb" && -f "/root/backup$i/houston.txt" && -f "/root/backup$i/identity.json" && -f "/root/backup$i/kademlia.crt" && -f "/root/backup$i/kademlia.key" && -f "/root/backup$i/system.db" && -d "/root/backup$i/migrations" ]]; then
    echo "/root/backup$i directory detected and no files missing. Proceeding with restore !"
  else
    echo "######### CAREFUL !! SCRIPT STOPPED BECAUSE BACKUP FILES ARE NOT IN THE RIGHT DIRECTORY !! #########"
    echo "Please make sure all backup files are placed in /root/backup$i and not /root/backup$i/2021... before trying again."
    echo "If your backup files are in /root/backup$i/202..... and not /root/backup$i, this will not work, you must move the backup files into /root/backup$i by running these commands first :"
    echo "mv -v /root/backup$i/20*/* /root/backup$i"
    echo "mv -v /root/backup$i/20*/.origintrail_noderc /root/backup$i"
    echo "rm -rf /root/backup$i/20*"
    echo "rm -rf /root/backup$i/lost+found"
    exit 1
  fi

  echo "Setting up Firewall rules"
  ufw allow $PORT1 && ufw allow $PORT2 && ufw allow $PORT3

  echo "Setting up origintrail RC file for $NODE"
  $MAINPATH/data/setup-noderc.sh $i

  echo "Creating docker $NODE"
  OUTPUT=$(docker create -i --log-driver json-file --log-opt max-size=50m --name=$NODE -p $PORT3:$PORT3 -p $PORT2:$PORT2 -p $PORT1:$PORT1 -v $NODEBASEPATH/$NODE/.origintrail_noderc:/ot-node/.origintrail_noderc origintrail/ot-node:release_mainnet 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Docker creation FAILED:${N1}$OUTPUT"
    exit 1
  fi

  echo "Enable docker always restart"
  OUTPUT=$(docker update --restart=always $NODE 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Docker restart update FAILED:${N1}$OUTPUT"
    exit 1
  fi

  echo "cd to root"
  cd

  echo "Modifying container name and backup directory in restore script"
  sed -i -E 's|CONTAINER_NAME=.*|CONTAINER_NAME='"$NODE"'|g' restore.sh
  sed -i -E 's|BACKUPDIR=.*|BACKUPDIR='"backup$i"'|g' restore.sh
  if [[ $? -ne 0 ]]; then
    echo "restore script modification FAILED"
    exit 1
  fi

  echo "Running restore script"
  ./restore.sh
  if [[ $? -ne 0 ]]; then
    echo "Restore FAILED:${N1}$OUTPUT"
    exit 1
  fi

  sleep 2s 

  echo "changing PRAGMA journal_mode to WAL"
  sqlite3 $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db 'PRAGMA journal_mode=WAL;'
  if [[ $? -ne 0 ]]; then
    echo "changing PRAGMA journal_mode to WAL for $NODE failed"
    continue
  fi

done

echo "########## RESTORE COMPLETE ! REMEMBER TO DELETE YOUR BACKUP FOLDER ON ROOT IF EVERYTHING WORKS ! ##########"
echo "REMEMBER TO RUN update-arango-vars.sh after the install to get the correct arangod values for MN docker"