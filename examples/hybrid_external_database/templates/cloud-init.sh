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

mkdir -p /root/data

sleep 10

docker run -d  \
  --env POSTGRES_PASSWORD=${db_master_pass} \
  --env POSTGRES_USER=${db_master_user} -v /root/data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:13.1
