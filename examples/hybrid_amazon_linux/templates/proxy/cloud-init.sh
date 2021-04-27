#!/bin/bash
set -x
exec &> /tmp/cloud-init.log

apt-get update

apt-get install -y apt-transport-https \
  ca-certificates curl gnupg-agent \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

sleep 10

docker run -d  \
  --restart=always \
  -p 3128:3128 \
  -v /etc/squid/squid.conf:/etc/squid/squid.conf \
  sameersbn/squid:3.5.27-2
