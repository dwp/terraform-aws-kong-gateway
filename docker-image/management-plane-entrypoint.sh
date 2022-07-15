#!/usr/bin/env bash
set -Eeo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
# "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  # Do not continue if _FILE env is not set
  if ! [ "${!fileVar:-}" ]; then
    return
  elif [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

export KONG_NGINX_DAEMON=${KONG_NGINX_DAEMON:=off}

set +x
mkdir -p /usr/local/kong/ssl
echo "${SSL_CERT}" > /usr/local/kong/ssl/kong.crt
echo "${SSL_KEY}"  > /usr/local/kong/ssl/kong.key

echo "${LUA_SSL_CERT}" > /usr/local/kong/ssl/lua.crt

mkdir -p /usr/local/kong/kong_clustering
echo "${CLUSTER_CERT}" > /usr/local/kong/kong_clustering/cluster.crt
echo "${CLUSTER_KEY}" > /usr/local/kong/kong_clustering/cluster.key
echo "${CUSTOM_NGINX_CONF}" | base64 -d > /usr/local/kong/custom-nginx.conf

all_kong_options="/usr/local/share/lua/5.1/kong/templates/kong_defaults.lua"
set +Eeo pipefail
while IFS='' read -r LINE || [ -n "${LINE}" ]; do
    opt=$(echo "$LINE" | grep "=" | sed "s/=.*$//" | sed "s/ //" | tr '[:lower:]' '[:upper:]')
    file_env "KONG_$opt"
done < $all_kong_options
set -Eeo pipefail

file_env KONG_PASSWORD
PREFIX=${KONG_PREFIX:=/usr/local/kong}

echo "running migrations"
kong migrations bootstrap
kong migrations up
kong migrations finish

echo "running kong"
kong prepare -p "$PREFIX" "$@"

ln -sf /dev/stdout $PREFIX/logs/access.log
ln -sf /dev/stdout $PREFIX/logs/admin_access.log
ln -sf /dev/stderr $PREFIX/logs/error.log

exec /usr/local/openresty/nginx/sbin/nginx \
  -p "$PREFIX" \
  -c nginx.conf
