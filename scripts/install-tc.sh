#!/bin/sh -e
# Copyright (c) 2021 Deepak Singh

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This script install NiFi by running a docker swarm running a stack deployed
# using 'docker-compose.yml'.
#
# Author    :   dkrypt
# Link      :   dkrypt.github.io


#########################################################
# create required directories for docker volume mounts
#########################################################

# Repository
mkdir -p /data/apps

# NiFi CA
mkdir -p /data/nifi-ca

# NiFi
mkdir -p /data/nifi/cr
mkdir -p /data/nifi/pr
mkdir -p /data/nifi/fr
mkdir -p /data/nifi/dr
mkdir -p /data/nifi/logs

# Nginx
mkdir -p /data/rp-nginx/conf
mkdir -p /data/rp-nginx/log

#########################################################
# clone repository from github.com/dkrypt/nifi-docker-stack
#########################################################
cd /data/apps
rm -rf ./*
apt-get -y install git

git clone https://github.com/dkrypt/nifi-docker-stack.git

#########################################################
# nginx configuration
#########################################################
cp /data/apps/nifi-docker-stack/conf/nginx/* /data/rp-nginx/conf/

#########################################################
# install required plugins
#########################################################

apt-get -y install jq
apt-get -y install apt-transport-https

#########################################################
# install Docker CE and Docker Compose
#########################################################

# Docker
sudo apt-get remove docker docker-engine docker.io containerd runc

apt-get -y update

apt-get install apt-transport-https ca-certificates curl gnupg lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get -y update 
apt-get install docker-ce docker-ce-cli containerd.io

# Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

chmod -R +x /data/apps/

#########################################################
# initialise docker swarm and deplot the stack
#########################################################

docker swarm init

docker stack deploy -c /data/apps/nifi-docker-stack/docker-compose.yml nifi_stack --with-registry-auth

