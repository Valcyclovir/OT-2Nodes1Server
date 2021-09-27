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
STATUS=$?
N1=$'\n'

i=$1
PORT1=$(($i+2999))
PORT2=$(($i+5277))
PORT3=$(($i+8899))
NODE="$NODE_NAME$i"
tmp=BLOCKCHAIN_IMPLEMENTATIONS_$i[@]
BLOCKCHAIN_IMPLEMENTATIONS=("${!tmp}")
NODE_WALLET=NODE_WALLET_$i
NODE_PRIVATE_KEY=NODE_PRIVATE_KEY_$i
RPC_SERVER_URL=RPC_SERVER_URL_$i
INITIAL_DEPOSIT_AMOUNT=INITIAL_DEPOSIT_AMOUNT_$i
SUBDOMAIN=HOSTNAME_$i
DH_MAX_HOLDING_TIME_IN_MINUTES=DH_MAX_HOLDING_TIME_IN_MINUTES_$i

if [[ -d "$NODEBASEPATH/$NODE" ]]; then
  echo "$NODEBASEPATH/$NODE detected, proceeding to .origintrail_noderc config update"
else
  echo "mkdir $NODEBASEPATH/$NODE"
  mkdir $NODEBASEPATH/$NODE
fi

echo "Copying .origintrail_noderc template over to $NODEBASEPATH/$NODE"
head -n 3 $MAINPATH/data/.origintrail_noderc > $NODEBASEPATH/$NODE/.origintrail_noderc

for ((j = 0; j < ${#BLOCKCHAIN_IMPLEMENTATIONS[@]}; j++))
do

implementation=${BLOCKCHAIN_IMPLEMENTATIONS[$j]}
cat $MAINPATH/data/.implementation_$implementation >> $NODEBASEPATH/$NODE/.origintrail_noderc

lastElement=$((${#BLOCKCHAIN_IMPLEMENTATIONS[@]} - 1))
if [[ $j != ${lastElement} ]]; then
  echo ',' >> $NODEBASEPATH/$NODE/.origintrail_noderc
fi
done

tail -n +4 $MAINPATH/data/.origintrail_noderc >> $NODEBASEPATH/$NODE/.origintrail_noderc

echo "Copying variables into origintrail_noderc"
sed -i -E 's/"hostname":.*/"hostname": "'"${!SUBDOMAIN}"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"management_wallet":.*/"management_wallet": "'"$MANAGEMENT_WALLET"'"/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"node_wallet":.*/"node_wallet": "'"${!NODE_WALLET}"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"node_private_key":.*/"node_private_key": "'"${!NODE_PRIVATE_KEY}"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"initial_deposit_amount":.*/"initial_deposit_amount": "'"${!INITIAL_DEPOSIT_AMOUNT}"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"dh_max_holding_time_in_minutes":.*/"dh_max_holding_time_in_minutes": "'"${!DH_MAX_HOLDING_TIME_IN_MINUTES}"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"autoUpdater":.*/"autoUpdater": {"enabled": '$AUTO_UPDATER'},/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"node_port":.*/"node_port": "'"$PORT2"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"node_rpc_port":.*/"node_rpc_port": "'"$PORT3"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"node_remote_control_port":.*/"node_remote_control_port": "'"$PORT1"'"','/g' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E '/"dataset_pruning":.*/!b;n;c"enabled": '$DATASET_PRUNING'','' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E '/"low_estimated_value_datasets":.*/!b;n;c"enabled": '$PRUNE_LOW_VALUE_DATASETS'','' $NODEBASEPATH/$NODE/.origintrail_noderc
sed -i -E 's/"minimum_free_space_percentage":.*/"minimum_free_space_percentage": "'"$MINIMUM_FREE_SPACE_PERCENTAGE"'"/g' $NODEBASEPATH/$NODE/.origintrail_noderc
if [[ "${!RPC_SERVER_URL}" == "INPUT_VARIABLE_HERE" ]]; then
  continue
else
  sed -i -E 's|"rpc_server_url":.*|"rpc_server_url": "'"${!RPC_SERVER_URL}"'"','|g' $NODEBASEPATH/$NODE/.origintrail_noderc
fi

echo "file .origintrail_noderc for $NODE has been successfully created from config.sh"
