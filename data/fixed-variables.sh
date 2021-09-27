#!/bin/bash

export DOCKER_INSPECT_MERGED='docker inspect --format='{{.GraphDriver.Data.MergedDir}}''
export DOCKER_INSPECT_UPPER='docker inspect --format='{{.GraphDriver.Data.UpperDir}}''
export OTNODE_DATA="/ot-node/data"
export ARANGODB3="/var/lib/arangodb3"
export ARANGODB3APPS="/var/lib/arangodb3-apps"