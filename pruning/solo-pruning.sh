#!/bin/bash

# This script is for one time use only
# Use this script to introduce a brick into your arangodb3 folder to initiate pruning in a MN docker setup
# Define arguments for NODE and PRUNING_BRICK before running this script
# Example : To add a 200g brick to otnode2, input ./solo-pruning.sh 2 200

NODE=$1
PRUNING_BRICK=$2

ARANGODB3=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/var/lib/arangodb3/engine-rocksdb/brick.img

echo "adding a $PRUNING_BRICK sized brick into your arangodb3 folder on $NODE"
fallocate -l $PRUNING_BRICK $ARANGODB3

echo "docker restart $NODE"
docker restart $NODE

docker logs -f --since 5m $NODE

echo "Remember to remove that brick once you are done !!"
echo "To delete the brick, simply enter the 2 lines below (replace $NODE with your node name):"
echo "ARANGO=$(docker inspect --format='{{.GraphDriver.Data.MergedDir}}' $NODE)/var/lib/arangodb3/engine-rocksdb"
echo "rm $ARANGO/brick.img"
echo "df -h to check if disk space and to make sure you deleted your brick"