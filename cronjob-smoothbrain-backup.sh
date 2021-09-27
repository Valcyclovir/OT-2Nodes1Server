#!/bin/bash

# This backup script uses the team's original script

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
	source "/etc/otnode/config.sh"
else
	#**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
	source "/root/OT-2Nodes1Server/config.sh"
	export MAINPATH="/root/OT-2Nodes1Server"
	export BACKUPPATH="/root/backup"
fi
source "$MAINPATH/data/fixed-variables.sh"

N1=$'\n'

if ! sqlite3_loc="$(type -p "sqlite3")" || [[ -z sqlite3 ]]; then
	$MAINPATH/data/send.sh "Installing sqlite3 to backup system.db"
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
		$MAINPATH/data/send.sh "Error: Unable to install sqlite3 please install manually"
		exit 1;
	fi
fi

for (( i=1; i<=$NODE_TOTAL; i++ ))
do
	NODE="$NODE_NAME$i"
 
	if [ -d "$BACKUPPATH" ]; then
		#Check if it is a link (expected) or an actual directory
		if [ -L "$BACKUPPATH" ]; then
			#symlink, delete contents, then unlink
			echo "Deleting existing content in backup folder"
			rm -rf $BACKUPPATH/* 2>&1
			unlink $BACKUPPATH 2>&1
		else
			#Actual directory, we did not create this, something may be wrong in configuration. Do not delete to prevent unexpected data loss
			$MAINPATH/data/sendnode.sh $i "Error: $BACKUPPATH is an existing folder. Check contents and if data is not vital, manually remove using rm -Rf $BACKUPPATH"
			exit 1
		fi
	fi
	
	echo "Linking container backup folder to $BACKUPPATH"
	#check if folder exists on node
	if [[ ! -d $($DOCKER_INSPECT_MERGED $NODE)/ot-node/backup ]]; then
		echo "Creating /ot-node/backup in container"
		mkdir $($DOCKER_INSPECT_MERGED $NODE)/ot-node/backup
		STATUS=$?
		if [[ $STATUS -ne 0 ]]; then
			$MAINPATH/data/sendnode.sh $i "Error: creating /ot-node/backup folder in container failed"
			continue
		fi
	else
		echo "Using existing /ot-node/backup in container"
	fi
			
	#creating link
	ln -sf "$($DOCKER_INSPECT_MERGED $NODE)/ot-node/backup" $BACKUPPATH
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Error: Linking container backup folder command FAILED"
		continue
	fi

	echo "Deleting any existing backups inside container"
	rm -rf $BACKUPPATH/* 2>&1
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Error: Delete existing backup contents FAILED"
		continue
	fi

	echo "Backing up OT Node data"
	docker exec $NODE node scripts/backup.js --config=/ot-node/.origintrail_noderc --configDir=/ot-node/data --backupDirectory=/ot-node/backup  2>&1
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Error: OT docker backup command FAILED"
		continue
	fi

	echo "Moving data out of dated folder into backup"
	mv -v $BACKUPPATH/202*/* $BACKUPPATH/ 2>&1
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Error: Moving data command FAILED"
		continue
	fi

	echo "Moving hidden data out of dated folder into backup"
	mv -v $BACKUPPATH/202*/.origintrail_noderc $BACKUPPATH/ 2>&1
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Error: Moving hidden data command FAILED"
		continue
	fi

	echo "Deleting dated folder"
	rm -rf $BACKUPPATH/20* 2>&1
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Error: Deleting data folder command FAILED"
		continue
	fi

	#backup system.db using sqlite3, retry on failure (maximum 2 retries)
	echo "Using sqlite3 to backup system.db to system.db.backup on $NODE"
	SQLOK=false
	for (( t=0; t<3; t++ ))
	do
		#remove previous system.db.backup, may prevent diskIO error
		if [[ -f "$BACKUPPATH/system.db.backup" ]]; then
			rm -f $BACKUPPATH/system.db.backup 2>&1
		fi
		sqlite3 $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/system.db ".backup '$BACKUPPATH/system.db.backup'"
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
		cp -f $($DOCKER_INSPECT_UPPER $NODE)/ot-node/data/system.db $BACKUPPATH/system.db.backup
		STATUS=$?
		if [[ $STATUS -eq 0 ]]; then
			echo "Error: Backup of system.db using sqlite3 and simple copy on $NODE FAILED aborting backup"
			$MAINPATH/data/sendnode.sh $i "Error: Backup of system.db using sqlite3 and simple copy on $NODE FAILED aborting backup of $NODE"
			continue;
		else
			$MAINPATH/data/sendnode.sh $i "Info: Backup of system.db using sqlite3 on $NODE FAILED. Created simple copy instead."
		fi
	fi	
	
	echo "Uploading $NODE data to storage server"
	OUTPUT=$($MAINPATH/restic backup --tag $NODE $BACKUPPATH/.origintrail_noderc $BACKUPPATH/* 2>&1)
	STATUS=$?
	if [[ $STATUS -eq 0 ]]; then
		if [[ $BACKUP_NOTIFY_ON_SUCCESS == "true" ]]; then
			$MAINPATH/data/sendnode.sh $i "Backup SUCCESSFUL:${N1}$OUTPUT"
			rm $($DOCKER_INSPECT_MERGED $NODE)/ot-node/data/system.db.backup
		fi
	else
		$MAINPATH/data/sendnode.sh $i "Error: Uploading backup to storage server FAILED:${N1}$OUTPUT"
		continue
	fi

	echo "Deleting contents of backup folder"
	rm -rf $BACKUPPATH/* 2>&1
	STATUS=$?
	if [[ $STATUS -ne 0 ]]; then
		$MAINPATH/data/sendnode.sh $i "Delete contents of backup folder FAILED"
		continue
	fi
	echo "Removing Symlink"
	if [ -L "$BACKUPPATH" ]; then
		unlink $BACKUPPATH 2>&1
	fi
	
	echo "Removing /ot-node/backup"
	rm -rf $($DOCKER_INSPECT_MERGED $NODE)/ot-node/backup 2>&1
	
done

echo "Smoothbrain backup on all nodes complete !"
exit 0