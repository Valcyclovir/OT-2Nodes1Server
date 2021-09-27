#!/bin/bash

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
fi
N1=$'\n'

echo "Removing outdated snapshots and data"

if [ -z "$NUMBERRESTICSNAPSHOTS" ]; then
	NUMBERRESTICSNAPSHOTS=1
fi

FORGET_OUTPUT=`$MAINPATH/restic forget --group-by host,tag --keep-last $NUMBERRESTICSNAPSHOTS 2>&1`
FORGET_STATUS=$?
echo "$FORGET_OUTPUT"

echo "Notifying result of forget command with telegram STATUS=$FORGET_STATUS"

if [ $FORGET_STATUS -eq 0 ]; then
  $MAINPATH/data/send.sh "Forget command SUCCEEDED"
else
  $MAINPATH/data/send.sh "Forget command FAILED${N1}$FORGET_OUTPUT"
  exit 1
fi

PRUNE_OUTPUT=`$MAINPATH/restic prune` 2>&1
PRUNE_SUCCESS_OUTPUT=$(echo "$PRUNE_OUTPUT" | grep 'total\ prune\|remaining:')
PRUNE_STATUS=$?

if [ $PRUNE_STATUS -eq 0 ]; then
  $MAINPATH/data/send.sh "Prune command SUCCEEDED${N1}$PRUNE_SUCCESS_OUTPUT"
else
  $MAINPATH/data/send.sh "Prune command FAILED${N1}$PRUNE_OUTPUT"
  exit 1
fi

CHECK_OUTPUT=`$MAINPATH/restic check 2>&1`

if [ $? -eq 0 ]; then
  $MAINPATH/data/send.sh "Check command SUCCEEDED"
else
  $MAINPATH/data/send.sh "Check command FAILED${N1}$CHECK_OUTPUT"
  exit 1
fi
