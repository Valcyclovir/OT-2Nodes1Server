#!/bin/bash

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

N1=$'\n'

for var;
do
  PORT1=$((var+2999))
  PORT2=$((var+5277))
  PORT3=$((var+8899))
  NODE="$NODE_NAME$var"
  
  echo "rm -rf $NODEBASEPATH/temp$var"
  rm -rf $NODEBASEPATH/temp$var

  echo "mkdir $NODEBASEPATH/temp$var"
  mkdir $NODEBASEPATH/temp$var
  
  echo "docker start $NODE"
  docker start $NODE

  sleep 4s

  echo "docker cp $NODE:/ot-node/data/identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/identity.json $NODEBASEPATH/temp$var/

  echo "docker cp $NODE:/ot-node/data/erc725_identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/erc725_identity.json $NODEBASEPATH/temp$var/

  echo "docker cp $NODE:/ot-node/data/xdai_erc725_identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/xdai_erc725_identity.json $NODEBASEPATH/temp$var/

  echo "docker cp $NODE:/ot-node/data/polygon_erc725_identity.json $NODEBASEPATH/temp$var/"
  docker cp $NODE:/ot-node/data/polygon_erc725_identity.json $NODEBASEPATH/temp$var/

  mkdir $NODEBASEPATH/$HOSTNAME/temp$var

  echo "mv $NODEBASEPATH/temp* $NODEBASEPATH/$HOSTNAME"
  mv $NODEBASEPATH/temp$var $NODEBASEPATH/$HOSTNAME/temp$var

  echo "docker stop $NODE"
  docker stop $NODE

done