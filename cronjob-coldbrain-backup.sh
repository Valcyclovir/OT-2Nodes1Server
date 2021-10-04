#!/bin/bash

# Use this script to make a cold backup of your node. Note that your node has to be stopped during this process, and will automatically restart when done. 

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

N1=$"%0A"
ALLRESTARTED=true
HOST=$(hostname)
MESSAGE=""

if ! sqlite3_loc="$(type -p "sqlite3")" || [[ -z sqlite3 ]]; then
        MESSAGE+="${N1}Installing sqlite3 to backup system.db"
        #Yum (RHEL, Centos)
        YUM_CMD=$(which yum)
        #apt-get (Debian)
        APT_GET_CMD=$(which apt-get)
        #DNF (RHEL, Centos > 8)
        DNF_CMD=$(which dnf)
        if [[ ! -z $DNF_CMD ]]; then
                dnf -y install sqlite
        elif [[ ! -z $APT_GET_CMD ]]; then
                apt-get -y install sqlite3
        elif [[ ! -z $YUM_CMD ]]; then
                yum -y install sqlite
        else
                MESSAGE+="${N1}Error: Unable to install sqlite3 please install manually"
                $MAINPATH/data/send.sh $MESSAGE
                exit 1;
        fi
fi

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
        NODE="$NODE_NAME$i"
  
        echo "docker exec $NODE supervisorctl stop all"
        docker exec $NODE supervisorctl stop all
        STATUS=$?
        if [[ $STATUS -ne 0 ]]; then
                MESSAGE+="${N1}$NODE: Error: Stopping $NODE failed during coldbrain backup."
                #even though this node failed, continue to next 
                continue
        else
                #a node is stopped, so set allrestarted to false until a succesfull restart
                ALLRESTARTED=false
        fi

        #backup system.db using sqlite3, retry on failure (maximum 2 retries)
        echo "Using sqlite3 to backup system.db to system.db.backup on $NODE"
	SQLOK=false
        for (( t=0; t<3; t++ ))
        do
                #remove previous system.db.backup, may prevent diskIO error
                if [[ -f "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup" ]]; then
                        rm -f $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup 2>&1
                fi
                sqlite3 $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db ".backup '$($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup'"
                STATUS=$?
                if [[ $STATUS -eq 0 ]]; then
                        #succes, stop trying
                        SQLOK=true
                        break
                else
                        echo "Info: Using sqlite3 to backup system.db on $NODE failed, retrying"
                fi
        done
        if [[ ! $SQLOK ]]; then
                echo "Info: Using sqlite3 to backup system.db on $NODE failed 3 times. Making simple copy"
                cp -f $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup
                STATUS=$?
                if [[ $STATUS -eq 0 ]]; then
                        echo "Error: Backup of system.db using sqlite3 and simple copy on $NODE FAILED aborting backup"
                        MESSAGE+="${N1}Error: Backup of system.db using sqlite3 and simple copy on $NODE FAILED aborting backup of $NODE"
                else
                        MESSAGE+="${N1}Info: Backup of system.db using sqlite3 on $NODE FAILED. Created simple copy instead."
                        SQLOK=true
                fi
        fi      
        if [[ $SQLOK ]]; then
                #Proceed with data upload only if backing of system.db was succesfull.
                #Otherwise user investigation is needed to prevent incomplete backups and data loss
                echo "Uploading $NODE data to storage server"
 		OUTPUT=$($MAINPATH/restic backup --tag $NODE $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data $NODEBASEPATH/$NODE/.origintrail_noderc $($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3 $($DOCKER_INSPECT_MERGED $NODE)$ARANGODB3APPS --exclude="brick.img" --exclude "bootstraps.json" --exclude "system.db-journal" --exclude "import_cache" --exclude "kadence.dht" --exclude "peercache" --exclude "replication_cache" 2>&1)                STATUS=$?
                if [[ $STATUS -eq 0 ]]; then
                        if [[ $BACKUP_NOTIFY_ON_SUCCESS == "true" ]]; then
                                MESSAGE+="${N1}$NODE: Backup SUCCESSFUL"
                                rm $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup
                        fi
                else
                        MESSAGE+="${N1}Error: Uploading backup to storage server FAILED:"
                fi
        fi
  
        echo "Restarting $NODE"
        docker restart $NODE
        STATUS=$?
        if [[ $STATUS -ne 0 ]]; then
                MESSAGE+="${N1}Error: Starting $NODE failed during backup."
        else
                #succesfullrestart reset allrestarted variable
                ALLRESTARTED=true
        fi
done
if [[ $ALLRESTARTED ]]; then
        MESSAGE+="${N1}Info: Coldbrain backup on all nodes complete !"
        echo "Coldbrain backup on all nodes complete ! All nodes have been restarted successfully."
else
        MESSAGE+="${N1}ERROR: Not all nodes have been restarted successfully."
        echo "WARNING: Coldbrain backup on all nodes complete ! Not all nodes have been restarted successfully."
fi
$MAINPATH/data/send.sh $MESSAGE
