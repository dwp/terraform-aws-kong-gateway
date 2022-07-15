#!/usr/bin/env bash
set -Eeo pipefail

export KONG_NGINX_DAEMON=${KONG_NGINX_DAEMON:=off}

PREFIX=${KONG_PREFIX:=/usr/local/kong}

set +x
mkdir -p /usr/local/kong/ssl
echo "${SSL_CERT}" > /usr/local/kong/ssl/kong.crt
echo "${SSL_KEY}"  > /usr/local/kong/ssl/kong.key

echo "${LUA_SSL_CERT}" > /usr/local/kong/ssl/lua.crt

mkdir -p /usr/local/kong/kong_clustering
echo "${CLUSTER_CERT}" > /usr/local/kong/kong_clustering/cluster.crt
echo "${CLUSTER_KEY}" > /usr/local/kong/kong_clustering/cluster.key
echo "${CUSTOM_NGINX_CONF}" | base64 -d > /usr/local/kong/custom-nginx.conf

kong prepare -p "$PREFIX" "$@"

ln -sf /dev/stdout $PREFIX/logs/access.log
ln -sf /dev/stdout $PREFIX/logs/admin_access.log
ln -sf /dev/stderr $PREFIX/logs/error.log

exec kong start -p "$PREFIX" "$@"
