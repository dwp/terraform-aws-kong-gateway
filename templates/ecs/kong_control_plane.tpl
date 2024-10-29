[{
  "cpu": ${cpu},
  "image": "${image_url}",
  "memory": ${memory},
  "name": "${name}",
  "networkMode": "awsvpc",
  "user": "${user}",
  "linuxParameters": {
    "initProcessEnabled": true
  },
  "environment": [
    {
      "name": "AWS_REGION",
      "value": "${region}"
    },
    {
      "name": "KONG_CLUSTER_MTLS",
      "value": "${kong_cluster_mtls}"
    },
    {
      "name": "KONG_ADMIN_GUI_AUTH",
      "value": "basic-auth"
    },
    {
      "name": "KONG_ENFORCE_RBAC",
      "value": "on"
    },
    {
      "name": "KONG_ADMIN_SSL_CERT",
      "value": "/usr/local/kong/kong_clustering/cluster.crt"
    },
    {
      "name": "KONG_ADMIN_SSL_CERT_KEY",
      "value": "/usr/local/kong/kong_clustering/cluster.key"
    },
    {
      "name": "KONG_ADMIN_GUI_SSL_CERT",
      "value": "/usr/local/kong/kong_clustering/cluster.crt"
    },
    {
      "name": "KONG_ADMIN_GUI_SSL_CERT_KEY",
      "value": "/usr/local/kong/kong_clustering/cluster.key"
    },
    {
      "name": "KONG_ADMIN_ACCESS_LOG",
      "value": "${access_log_format}"
    },
    {
      "name": "KONG_ADMIN_ERROR_LOG",
      "value": "${error_log_format}"
    },
    {
      "name": "KONG_ADMIN_GUI_ACCESS_LOG",
      "value": "${access_log_format}"
    },
    {
      "name": "KONG_ADMIN_GUI_ERROR_LOG",
      "value": "${error_log_format}"
    },
    %{ if kong_cluster_mtls == "pki" }
    {
      "name": "KONG_CLUSTER_CA_CERT",
      "value": "/usr/local/kong/kong_clustering/cluster_ca.crt"
    },
    %{ endif }
    {
      "name": "KONG_CLUSTER_CERT",
      "value": "/usr/local/kong/kong_clustering/cluster.crt"
    },
    {
      "name": "KONG_CLUSTER_CERT_KEY",
      "value": "/usr/local/kong/kong_clustering/cluster.key"
    },
    {
      "name": "KONG_ADMIN_LISTEN",
      "value": "0.0.0.0:${admin_api_port} ssl"
    },
    {
      "name": "KONG_ADMIN_GUI_LISTEN",
      "value": "0.0.0.0:${admin_gui_port} ssl"
    },
    {
      "name": "${api_uri_env_name}",
      "value": "${kong_admin_api_uri}"
    },
    {
      "name": "KONG_ADMIN_GUI_URL",
      "value": "${kong_admin_gui_url}"
    },
    {
      "name": "KONG_CLUSTER_SERVER_NAME",
      "value": ""
    },
    {
      "name": "KONG_AUDIT_LOG",
      "value": "on"
    },
    {
      "name": "KONG_STATUS_LISTEN",
      "value": "0.0.0.0:${status_port} ssl"
    },
    {
      "name": "KONG_STATUS_SSL_CERT",
      "value": "/usr/local/kong/kong_clustering/cluster.crt"
    },
    {
      "name": "KONG_STATUS_SSL_CERT_KEY",
      "value": "/usr/local/kong/kong_clustering/cluster.key"
    },
    {
      "name": "CUSTOM_NGINX_CONF",
      "value": "${nginx_custom_config}"
    },
    {
      "name": "KONG_PLUGINS",
      "value": "${kong_plugins}"
    },
    {
      "name": "KONG_DATABASE",
      "value": "postgres"
    },
    {
      "name": "KONG_PG_HOST",
      "value": "${db_host}"
    },
    {
      "name": "KONG_PG_USER",
      "value": "${db_user}"
    },
    {
      "name": "KONG_PG_DATABASE",
      "value": "${db_name}"
    },
    %{ if pg_max_concurrent_queries != null }
    {
      "name": "KONG_PG_MAX_CONCURRENT_QUERIES",
      "value": "${pg_max_concurrent_queries}"
    },
    %{ endif }
    %{ if pg_keepalive_timeout != null }
    {
      "name": "KONG_PG_KEEPALIVE_TIMEOUT",
      "value": "${pg_keepalive_timeout}"
    },
    %{ endif }
    {
      "name": "KONG_NGINX_HTTP_INCLUDE",
      "value": "/usr/local/kong/custom-nginx.conf"
    },
    {
      "name": "KONG_ROLE",
      "value": "control_plane"
    },
    {
      "name": "KONG_PORTAL",
      "value": "${kong_portal_enabled}"
    },
    {
      "name": "KONG_PROXY_LISTEN",
      "value": "off"
    },
    {
      "name": "KONG_LOG_LEVEL",
      "value": "${kong_log_level}"
    },
    {
      "name": "KONG_ANONYMOUS_REPORTS",
      "value": "off"
    },
    {
      "name": "KONG_REAL_IP_HEADER",
      "value": "X-Forwarded-For"
    },
    {
      "name": "KONG_TRUSTED_IPS",
      "value": "0.0.0.0/0"
    },
    {
      "name": "KONG_VITALS",
      "value": "${kong_vitals_enabled}"
    }
    %{ if kong_vitals_enabled == "on" }
    %{ if vitals_endpoint != "" }
    ,{
      "name": "KONG_VITALS_STRATEGY",
      "value": "prometheus"
    },
    {
      "name": "KONG_VITALS_STATSD_ADDRESS",
      "value": "${vitals_endpoint}"
    }
    %{ endif }
    ,{
      "name": "KONG_VITALS_TSDB_ADDRESS",
      "value": "${vitals_tsdb_address}"
    }
    %{ endif }
    %{ if additional_vars != null }
    %{ for name, value in additional_vars ~}
    ,{
      "name": "${name}",
      "value": "${value}"
    }
    %{ endfor ~}
    %{ endif }
  ],
  "secrets": [
    {
    "name": "SSL_CERT",
    "valueFrom": "${ssl_cert}"
    },
    {
    "name": "SSL_KEY",
    "valueFrom": "${ssl_key}"
    },
    {
    "name": "KONG_PASSWORD",
    "valueFrom": "${admin_token}"
    },
    {
    "name": "KONG_PG_PASSWORD",
    "valueFrom": "${db_password_arn}"
    },
    {
    "name": "KONG_ADMIN_GUI_SESSION_CONF",
    "valueFrom": "${kong_admin_gui_session_conf}"
    },
    {
    "name": "LUA_SSL_CERT",
    "valueFrom": "${lua_ssl_cert}"
    },
    %{ if kong_cluster_mtls == "pki" }
    {
    "name": "CLUSTER_CA",
    "valueFrom": "${cluster_ca_cert}"
    },
    %{ endif }
    {
    "name": "CLUSTER_CERT",
    "valueFrom": "${cluster_cert}"
    },
    {
    "name": "CLUSTER_KEY",
    "valueFrom": "${cluster_key}"
    }
    %{ if portal_and_vitals_key_arn != "" }
    ,{
    "name": "KONG_PORTAL_AND_VITALS_KEY",
    "valueFrom": "${portal_and_vitals_key_arn}"
    }
    %{ endif }
  ],
  "entryPoint": ["${entrypoint}"],
  "healthCheck": {
    "command": ["CMD-SHELL", "kong health"],
    "timeout": 10,
    "interval": 10,
    "retries": 10,
    "startPeriod": null
  },
  "portMappings": ${jsonencode([
    for port in jsondecode(ports) : {
      containerPort = port,
      hostPort = port,
      protocol = "tcp"
    }
  ])},
  "ulimits": ${jsonencode([
    for limit in jsondecode(ulimits) :
    {
      name      = "nofile",
      hardLimit = limit,
      softLimit = limit
    }
  ])},
  "logConfiguration": {
    "logDriver": "awslogs",
    "options": {
      "awslogs-group": "${log_group}",
      "awslogs-region": "${region}",
      "awslogs-stream-prefix": "${name}"
    }
  },
  "placementStrategy": [
    {
      "field": "attribute:ecs.availability-zone",
      "type": "spread"
    }
  ]
}]
