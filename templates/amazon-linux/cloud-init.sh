#!/bin/bash

set -x
%{ for config_key, config_value in proxy_config ~}
%{ if config_value != null ~}
export ${config_key}="${config_value}"
%{ endif ~}
%{ endfor ~}

# Proxy Setting
echo "Checking and setting Proxy configuration..."
# Checking if HTTP Proxy(s) provided and setting
%{ if proxy_config.http_proxy != null ~}
  echo "export http_proxy=${proxy_config.http_proxy}" >> /etc/environment
  echo "HTTP Proxy configured"
%{ else ~}
  echo "No HTTP Proxy configuration found. Skipping"
%{ endif ~}
# Checking if HTTPS Proxy(s) provided and setting
%{ if proxy_config.https_proxy != null ~}
  echo "export https_proxy=${proxy_config.https_proxy}" >> /etc/environment
  echo "HTTPS Proxy configured"
%{ else ~}
  echo "No HTTPS Proxy configuration found. Skipping"
%{ endif ~}
# Checking if No Proxy configuration provided and setting
%{ if proxy_config.no_proxy != null ~}
  echo "export no_proxy=${proxy_config.no_proxy}" >> /etc/environment
  echo "export NO_PROXY=${proxy_config.no_proxy}" >> /etc/environment
  # echo "No-Proxy settings configured"
%{ else ~}
  echo "No No-Proxy configuration found. Skipping"
%{ endif ~}

source /etc/environment

exec &> /tmp/cloud-init.log

## Set up firewalld
setenforce 0;
firewall-cmd --add-port=5432/tcp --permanent --zone=public;
%{ for kong_port in kong_ports ~}
firewall-cmd --add-port=${kong_port}/tcp --permanent --zone=public;
%{ endfor ~}
firewall-cmd --reload;
setenforce 1;

# Pause: in testing we need this
# to make sure we wait to be routed out
# the internet before trying to get
# packages
for ((i=1;i<=300;i++)); do
  curl ubuntu.com/security/notices
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1
done


# Function to grab SSM parameters
aws_get_parameter() {
    aws ssm --region ${region} get-parameter \
        --name $1 \
        --with-decryption \
        --output text \
        --query Parameter.Value 2>/dev/null
}

yum update
yum install -y wget unzip curl openssl python python2-pip postgresql-server jq

# Enable auto updates
####### echo "Enabling auto updates"
####### echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true \
#######    | debconf-set-selections
####### dpkg-reconfigure -f noninteractive unattended-upgrades

# Installing decK
# https://github.com/hbagdi/deck
curl -sL https://github.com/hbagdi/deck/releases/download/v${deck_version}/deck_${deck_version}_linux_amd64.tar.gz \
    -o deck.tar.gz
tar zxf deck.tar.gz deck
sudo mv deck /usr/local/bin
sudo chown root:kong /usr/local/bin/deck
sudo chmod 755 /usr/local/bin/deck

# These certificates are used for
# clustering Kong control plane
# and data plane when used in hybrid
# mode
%{ if lookup(kong_config, "KONG_ROLE", null) != null ~}
mkdir -p /etc/kong_clustering
%{ if kong_hybrid_conf.cluster_cert != "" ~}
cat << EOF >/etc/kong_clustering/cluster.crt
${kong_hybrid_conf.cluster_cert}
EOF
%{ endif ~}
%{ if kong_hybrid_conf.ca_cert != "" ~}
cat << EOF >/etc/kong_clustering/cluster_ca.crt
${kong_hybrid_conf.ca_cert}
EOF
%{ endif ~}

%{ if kong_hybrid_conf.cluster_key != "" ~}
cat << EOF >/etc/kong_clustering/cluster.key
${kong_hybrid_conf.cluster_key}
EOF
%{ endif ~}
%{ endif ~}

# Install Kong
%{ if ee_creds_ssm_param.license != null && ee_creds_ssm_param.bintray_username != null && ee_creds_ssm_param.bintray_password != null && ee_creds_ssm_param.admin_token != null ~}
EE_LICENSE=$(aws_get_parameter ${ee_creds_ssm_param.license})
EE_BINTRAY_USERNAME=$(aws_get_parameter ${ee_creds_ssm_param.bintray_username})
EE_BINTRAY_PASSWORD=$(aws_get_parameter ${ee_creds_ssm_param.bintray_password})
ADMIN_TOKEN=$(aws_get_parameter ${ee_creds_ssm_param.admin_token})
%{ else ~}
EE_LICENSE="placeholder"
%{ endif ~}
if [ "$EE_LICENSE" != "placeholder" ]; then
    echo "Installing Kong EE"
    curl -sL https://download.konghq.com/gateway-2.x-amazonlinux-2/Packages/k/${ee_pkg} \
        -o ${ee_pkg}
    if [ ! -f ${ee_pkg} ]; then
        echo "Error: Enterprise edition download failed, aborting."
        exit 1
    fi
    yum install -y ${ee_pkg}
    cat <<EOF > /etc/kong/license.json
$EE_LICENSE
EOF
    chown root:kong /etc/kong/license.json
    chmod 640 /etc/kong/license.json
else
    echo "Installing Kong CE"
    curl -sL "https://download.konghq.com/gateway-2.x-amazonlinux-2/Packages/k/${ce_pkg}" \
        -o ${ce_pkg}
    yum install -y ${ce_pkg}
fi

%{ if lookup(kong_config, "KONG_ROLE", "embedded") != "data_plane" ~}

# Setup database
echo "Setting up Kong database"
PGPASSWORD=$(aws_get_parameter "${parameter_path}/db/password/master")
DB_PASSWORD=$(aws_get_parameter "${parameter_path}/db/password")

DB_HOST=${db_host}
DB_NAME=${db_name}

export PGPASSWORD

RESULT=$(psql --host $DB_HOST --username root \
    --tuples-only --no-align postgres \
    <<EOF
SELECT 1 FROM pg_roles WHERE rolname='${db_user}'
EOF
)

if [ $? != 0 ]; then
    echo "Error: Database connection failed, please configure manually"
    exit 1
fi

echo $RESULT | grep -q 1
if [ $? != 0 ]; then
    psql --host $DB_HOST --username root postgres <<EOF
CREATE USER ${db_user} WITH PASSWORD '$DB_PASSWORD';
GRANT ${db_user} TO root;
CREATE DATABASE $DB_NAME OWNER = ${db_user};
EOF
fi
unset PGPASSWORD
%{ endif }

# Setup systemd unit file
cat <<EOF > /etc/systemd/system/kong-gw.service
[Unit]
Description=KongGW
Documentation=https://docs.konghq.com/
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
ExecStartPre=/usr/local/bin/kong prepare -p /usr/local/kong
ExecStart=/usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf
ExecReload=/usr/local/bin/kong prepare -p /usr/local/kong
ExecReload=/usr/local/openresty/nginx/sbin/nginx -p /usr/local/kong -c nginx.conf -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
Environment=KONG_NGINX_DAEMON=off
Environment=KONG_PROXY_ACCESS_LOG=syslog:server=unix:/dev/log
Environment=KONG_PROXY_ERROR_LOG=syslog:server=unix:/dev/log
Environment=KONG_ADMIN_ACCESS_LOG=syslog:server=unix:/dev/log
Environment=KONG_ADMIN_ERROR_LOG=syslog:server=unix:/dev/log
EnvironmentFile=/etc/kong/kong_env.conf
LimitNOFILE=infinity
[Install]
WantedBy=multi-user.target
EOF

# Setup Configuration file
cat <<EOF > /etc/kong/kong_env.conf
%{if lookup(kong_config, "KONG_ROLE", "embedded") == "embedded" || lookup(kong_config, "KONG_ROLE", "embedded") == "control_plane" ~}
KONG_DATABASE="postgres"
KONG_PG_HOST="$DB_HOST"
KONG_PG_USER="${db_user}"
KONG_PG_PASSWORD="$DB_PASSWORD"
KONG_PG_DATABASE="$DB_NAME"
%{ endif }

# Load balancer headers
KONG_REAL_IP_HEADER="X-Forwarded-For"
KONG_TRUSTED_IPS="0.0.0.0/0"

%{if lookup(kong_config, "KONG_ROLE", null) != null ~}
%{if kong_config["KONG_ROLE"] == "data_plane" ~}
KONG_PROXY_LISTEN="0.0.0.0:${kong_ports.proxy}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"
%{ else ~}
KONG_ADMIN_LISTEN="0.0.0.0:${kong_ports.admin_api}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"
%{ endif ~}
%{ else ~}
KONG_PROXY_LISTEN="0.0.0.0:${kong_ports.proxy}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"
KONG_ADMIN_LISTEN="0.0.0.0:${kong_ports.admin_api}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"
%{ endif ~}
EOF
chmod 640 /etc/kong/kong_env.conf
chgrp kong /etc/kong/kong_env.conf

if [ "$EE_LICENSE" != "placeholder" ]; then
    cat <<EOF >> /etc/kong/kong_env.conf
KONG_ADMIN_GUI_LISTEN="0.0.0.0:${kong_ports.admin_gui}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"
KONG_PORTAL_GUI_LISTEN="0.0.0.0:${kong_ports.portal_gui}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"
KONG_PORTAL_API_LISTEN="0.0.0.0:${kong_ports.portal_api}%{ if kong_ssl_uris.protocol == "https"} ssl%{endif}"

KONG_ADMIN_API_URI="${replace(kong_ssl_uris.admin_api_uri, "${kong_ssl_uris.protocol}://", "")}"
KONG_ADMIN_GUI_URL="${kong_ssl_uris.admin_gui_url}"

KONG_PORTAL_GUI_PROTOCOL="${kong_ssl_uris.protocol}"
KONG_PORTAL_GUI_HOST="${replace(kong_ssl_uris.portal_gui_host, "${kong_ssl_uris.protocol}://", "")}"
KONG_PORTAL_API_URL="${kong_ssl_uris.portal_api_url}"
%{ if kong_ssl_uris.portal_cors_origins != null ~}
KONG_PORTAL_CORS_ORIGINS="${kong_ssl_uris.portal_cors_origins}"
%{ endif ~}
EOF

    for DIR in gui lib portal; do
        chown -R kong:kong /usr/local/kong/$DIR
    done
else
    # CE does not create the kong directory
    mkdir /usr/local/kong
fi

chown root:kong /usr/local/kong
chmod 2775 /usr/local/kong

%{if lookup(kong_config, "KONG_ROLE", "embedded") == "embedded" || lookup(kong_config, "KONG_ROLE", "embedded") == "control_plane" ~}
# Initialize Kong
echo "Initializing Kong"

export KONG_DATABASE="postgres"
export KONG_PG_HOST="$DB_HOST"
export KONG_PG_DATABASE="$DB_NAME"
export KONG_PG_USER="${db_user}"
export KONG_PG_PASSWORD="$DB_PASSWORD"
export KONG_PG_DATABASE="$DB_NAME"

if [ "$EE_LICENSE" != "placeholder" ]; then
    export KONG_PASSWORD=$ADMIN_TOKEN
    kong migrations bootstrap %{ if clear_database}-f %{endif}
else
    kong migrations bootstrap
fi

unset KONG_DATABASE
unset KONG_PG_HOST
unset KONG_PG_DATABASE
unset KONG_PG_USER
unset KONG_PG_PASSWORD
unset KONG_PG_DATABASE
%{ endif ~}

systemctl enable --now kong-gw
%{if lookup(kong_config, "KONG_ROLE", "embedded") == "embedded" || lookup(kong_config, "KONG_ROLE", "embedded") == "control_plane" ~}
# Verify Admin API is up
RUNNING=0
for I in 1 2 3 4 5 6 7 8 9; do
    curl -s -I %{ if kong_ssl_uris.protocol == "https"}-k https%{else}http%{endif}://localhost:${kong_ports.admin_api}/status | grep -q "200 OK"
    if [ $? = 0 ]; then
        RUNNING=1
        break
    fi
    sleep 1
done

if [ $RUNNING = 0 ]; then
    echo "Cannot connect to admin API, avoiding further configuration."
    exit 1
fi

# Enable healthchecks using a kong endpoint
curl -s localhost:${kong_ports.admin_api}/services | \
  jq -e -r '.data[] | select(.name | contains("status")) | if .id !="" then .name else false end'
if [ $? != 0 ]; then
    echo "Configuring healthcheck"
    curl -s -X POST http://localhost:${kong_ports.admin_api}/services \
        -d name=status \
        -d url=http://httpbin.org/get > /dev/null
    curl -s -X POST http://localhost:${kong_ports.admin_api}/services/status/routes \
        -d name=status \
        -d 'methods[]=HEAD' \
        -d 'methods[]=GET' \
        -d 'paths[]=/status' > /dev/null
    curl -s -X POST http://localhost:${kong_ports.admin_api}/services/status/plugins \
        -d name=ip-restriction \
        -d "config.whitelist=127.0.0.1" \
        -d "config.whitelist=${vpc_cidr_block}" > /dev/null
fi

if [ "$EE_LICENSE" != "placeholder" ]; then
    echo "Configuring enterprise edition settings"
    # Monitor role, endpoints, user, for healthcheck
    curl -s -X GET -I http://localhost:${kong_ports.admin_api}/rbac/roles/monitor | grep -q "200 OK"
    if [ $? != 0 ]; then
        COMMENT="Load balancer access to /status"
        curl -s -X POST http://localhost:${kong_ports.admin_api}/rbac/roles \
            -d name=monitor \
            -d comment="$COMMENT" > /dev/null
        curl -s -X POST http://localhost:${kong_ports.admin_api}/rbac/roles/monitor/endpoints \
            -d endpoint=/status -d actions=read \
            -d comment="$COMMENT" > /dev/null
        curl -s -X POST http://localhost:${kong_ports.admin_api}/rbac/users \
            -d name=monitor -d user_token=monitor \
            -d comment="$COMMENT" > /dev/null
        curl -s -X POST http://localhost:${kong_ports.admin_api}/rbac/users/monitor/roles \
            -d roles=monitor > /dev/null
        
        # Add authentication token for /status
        curl -s -X POST http://localhost:${kong_ports.admin_api}/services/status/plugins \
            -d name=request-transformer \
            -d 'config.add.headers[]=Kong-Admin-Token:monitor' > /dev/null
    fi

    cat <<EOF >> /etc/kong/kong_env.conf
%{ if lookup(kong_config, "KONG_ADMIN_GUI_SESSION_CONF", null) == null }
KONG_ADMIN_GUI_SESSION_CONF="{\"secret\":\"${session_secret}\",\"cookie_secure\":false}"
KONG_ADMIN_GUI_AUTH="basic-auth"
KONG_ENFORCE_RBAC="on"
KONG_ADMIN_LISTEN="0.0.0.0:8001, 0.0.0.0:8444 ssl"
%{ endif }
EOF
fi
%{ endif }

cat <<EOF >> /etc/kong/kong_env.conf
%{ if lookup(kong_config, "KONG_ROLE", null) == "control_plane" ~}
KONG_CLUSTER_MTLS="${kong_hybrid_conf.mtls}"
%{ if kong_hybrid_conf.ca_cert != "" ~}
KONG_CLUSTER_CA_CERT="/etc/ssl/certs/ca-bundle.crt"
%{ endif ~}
KONG_CLUSTER_CERT="/etc/kong_clustering/cluster.crt"
KONG_CLUSTER_CERT_KEY="/etc/kong_clustering/cluster.key"
KONG_CLUSTER_SERVER_NAME="${kong_hybrid_conf.server_name}"

# ADMIN API
KONG_ADMIN_SSL_CERT="/etc/kong_clustering/cluster.crt"
KONG_ADMIN_SSL_CERT_KEY="/etc/kong_clustering/cluster.key"

# ADMIN GUI
KONG_ADMIN_GUI_SSL_CERT="/etc/kong_clustering/cluster.crt"
KONG_ADMIN_GUI_SSL_CERT_KEY="/etc/kong_clustering/cluster.key"

# PORTAL API
KONG_PORTAL_API_SSL_CERT="/etc/kong_clustering/cluster.crt"
KONG_PORTAL_API_SSL_CERT_KEY="/etc/kong_clustering/cluster.key"

# PORTAL GUI
KONG_PORTAL_GUI_SSL_CERT="/etc/kong_clustering/cluster.crt"
KONG_PORTAL_GUI_SSL_CERT_KEY="/etc/kong_clustering/cluster.key"
%{ endif ~}

%{ if lookup(kong_config, "KONG_ROLE", null) == "data_plane" ~}
KONG_CLUSTER_MTLS="${kong_hybrid_conf.mtls}"
%{ if kong_hybrid_conf.ca_cert != "" ~}
KONG_CLUSTER_CA_CERT="/etc/ssl/certs/ca-bundle.crt"
%{ endif ~}
KONG_CLUSTER_CERT="/etc/kong_clustering/cluster.crt"
KONG_CLUSTER_CERT_KEY="/etc/kong_clustering/cluster.key"
KONG_CLUSTER_SERVER_NAME="${kong_hybrid_conf.server_name}"
KONG_LUA_SSL_TRUSTED_CERTIFICATE="/etc/kong_clustering/cluster.crt"
KONG_SSL_CERT="/etc/kong_clustering/cluster.crt"
KONG_SSL_CERT_KEY="/etc/kong_clustering/cluster.key"
KONG_CLUSTER_CONTROL_PLANE="${kong_hybrid_conf.endpoint}:${kong_ports.cluster}"
KONG_CLUSTER_TELEMETRY_ENDPOINT="${kong_hybrid_conf.endpoint}:${kong_ports.telemetry}"
%{ endif ~}

%{ for key, value in kong_config ~}
${key}="${value}"
%{ endfor ~}
EOF

systemctl restart kong-gw
