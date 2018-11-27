#!/bin/bash
sudo apt update -y || exit 1
sudo apt upgrade -y || exit 2
sudo apt install -y git || exit 3
git clone https://github.com/cncf/devstats.git || exit 4
cd devstats || exit 5
sudo apt install -y curl lsb-release software-properties-common apt-transport-https || exit 6
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || exit 7
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || exit 8
sudo apt update || exit 9
sudo apt-cache policy docker-ce || exit 10
sudo apt install -y docker-ce || exit 11
