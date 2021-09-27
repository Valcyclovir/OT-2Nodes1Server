#!/bin/bash

# For new setups of 2Nodes1Server

N1=$'\n'

echo "apt update && apt upgrade -y"
apt install apt update && apt upgrade -y
if [[ $STATUS -ne 0 ]]; then
  echo "Server update FAILED"
  exit 1
fi

echo "apt install screen"
apt install screen -y
if [[ $STATUS -ne 0 ]]; then
  echo "apt install screen failed"
  exit 1
fi

echo "Installing jq"
apt install jq -y

echo "Installing sqlite3"
apt install sqlite3

echo "Setting system journal max size to 50M"
sed -i 's/SystemMaxUse=.*/SystemMaxUse=50M/g' /etc/systemd/journald.conf

echo "sudo sysctl vm.swappiness=10"
sudo sysctl vm.swappiness=10
if [[ $STATUS -ne 0 ]]; then
  echo "Setting swappiness FAILED"
  exit 1
fi

apt-get install apt-transport-https ca-certificates curl software-properties-common -y
if [[ $STATUS -ne 0 ]]; then
  echo "Docker-ce install FAILED"
  exit 1
fi

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
if [[ $STATUS -ne 0 ]]; then
  echo "Docker-ce install FAILED"
  exit 1
fi

add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
if [[ $STATUS -ne 0 ]]; then
  echo "Docker-ce install FAILED"
  exit 1
fi

apt-get update -y
if [[ $STATUS -ne 0 ]]; then
  echo "Update FAILED"
  exit 1
fi

apt-get install docker-ce -y
if [[ $STATUS -ne 0 ]]; then
  echo "Docker-ce install FAILED"
  exit 1
fi