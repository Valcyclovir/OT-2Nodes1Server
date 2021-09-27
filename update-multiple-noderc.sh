#!/bin/bash

# This script will update all your .origintrail_noderc files for your nodes after you made changes to your config.sh file (for instance to integrate matic blockchain)

#Backwards compatibility to old config location
if [ -f "/etc/otnode/config.sh" ]; then
  source "/etc/otnode/config.sh"
else
  #**Deprecated** Move config to /etc/otnode/config.sh and change paths in that file
  source "/root/OT-2Nodes1Server/config.sh"
  export MAINPATH="/root/OT-2Nodes1Server"
fi

for (( i=$NODE_COUNTER; i<=$NODE_TOTAL; i++ ))
do
  echo "Setting up origintrail RC file for $NODE"
  $MAINPATH/data/setup-noderc.sh $i

done

echo ".origintrail_noderc file updated for all nodes ! Make sure you restart your nodes to apply the changes."