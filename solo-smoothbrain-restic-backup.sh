#!/bin/bash

# This backup script uses the team's original script. Use this script to perform a one time smoothbrain backup on your desired node. 
# On the terminal, input the argument of NODE when starting script

#Backwards compatibility to old config location
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

STATUS=$?
N1=$'\n'
NODE=$1

if [[ -d "$BACKUPPATH" ]]; then
  echo "Deleting existing backup folder"
  rm -rf $BACKUPPATH
fi

SQLITE_INSTALLED=$(dpkg-query -W -f='${Status}' sqlite3 2>/dev/null | grep -c "ok installed")
if [[ $SQLITE_INSTALLED -eq 0 ]]; then
  $MAINPATH/data/send.sh "Installing sqlite3 to backup system.db"
  apt install sqlite3
fi

echo "Linking container backup folder to $BACKUPPATH"
ln -sf "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/backup" $BACKUPPATH
  if [[ $STATUS -ne 0 ]]; then
  echo "Linking container backup folder command FAILED"
  exit 1
fi

echo "Deleting any existing backups inside container"
rm -rf $BACKUPPATH/*
  if [[ $STATUS -ne 0 ]]; then
  echo "Delete existing backup contents FAILED"
  exit 1
fi

echo "Backing up OT Node data"
docker exec $NODE node scripts/backup.js --config=/ot-node/.origintrail_noderc --configDir=/ot-node/data --backupDirectory=/ot-node/backup  2>&1
  if [[ $STATUS -ne 0 ]]; then
  echo "OT docker backup command FAILED"
  exit 1
fi

echo "Moving data out of dated folder into backup"
mv -v $BACKUPPATH/202*/* $BACKUPPATH/ 2>&1
  if [[ $STATUS -ne 0 ]]; then
  echo "Moving data command FAILED"
  exit 1
fi

echo "Moving hidden data out of dated folder into backup"
mv -v $BACKUPPATH/202*/.origintrail_noderc $BACKUPPATH/ 2>&1
  if [[ $STATUS -ne 0 ]]; then
  echo "Moving hidden data command FAILED"
  exit 1
fi

echo "Deleting dated folder"
rm -rf $BACKUPPATH/20* 2>&1
  if [[ $STATUS -ne 0 ]]; then
  echo "Deleting data folder command FAILED"
  exit 1
fi

echo "Using sqlite3 to backup system.db to system.db.backup"
sqlite3 $($DOCKER_INSPECT_UPPER $NODE)$SYSTEMDB ".backup '$BACKUPPATH/system.db.backup'"
if [[ $STATUS -ne 0 ]]; then
  $MAINPATH/data/send.sh "Backup of system.db using sqlite3 on $NODE FAILED"
  exit 1
fi

echo "Uploading $NODE data to storage server"
OUTPUT=$($MAINPATH/restic backup --tag $NODE $BACKUPPATH/.origintrail_noderc $BACKUPPATH/* 2>&1)
if [[ $STATUS -eq 0 ]]; then
  echo "Backup SUCCESSFUL:${N1}$OUTPUT"
  rm -rf $BACKUPPATH
else
  echo "Uploading backup to storage VPS FAILED:${N1}$OUTPUT"
  exit 1
fi

echo "Smoothbrain backup complete !"