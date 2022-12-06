{
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
      "value": "shared"
    },
    {
      "name": "KONG_CLUSTER_CERT",
      "value": "/usr/local/kong/kong_clustering/cluster.crt"
    },
    {
      "name": "KONG_CLUSTER_CERT_KEY",
      "value": "/usr/local/kong/kong_clustering/cluster.key"
    },
    {
      "name": "KONG_CLUSTER_SERVER_NAME",
      "value": "${cluster_server_name}"
    },
    {
      "name": "KONG_LUA_SSL_TRUSTED_CERTIFICATE",
      "value": "/usr/local/kong/ssl/lua.crt"
    },
    {
      "name": "KONG_SSL_CERT",
      "value": "/usr/local/kong/ssl/kong.crt"
    },
    {
      "name": "KONG_SSL_CERT_KEY",
      "value": "/usr/local/kong/ssl/kong.key"
    },
    {
      "name": "KONG_CLUSTER_CONTROL_PLANE",
      "value": "${clustering_endpoint}"
    },
    {
      "name": "KONG_CLUSTER_TELEMETRY_ENDPOINT",
      "value": "${telemetry_endpoint}"
    },
    {
      "name": "KONG_PROXY_ACCESS_LOG",
      "value": "${access_log_format}"
    },
    {
      "name": "KONG_PROXY_ERROR_LOG",
      "value": "${error_log_format}"
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
      "name": "KONG_NGINX_HTTP_INCLUDE",
      "value": "/usr/local/kong/custom-nginx.conf"
    },
    {
      "name": "CUSTOM_NGINX_CONF",
      "value": "${nginx_custom_config}"
    },
    {
      "name": "KONG_ROLE",
      "value": "data_plane"
    },
    {
      "name": "KONG_PLUGINS",
      "value": "${kong_plugins}"
    },
    {
      "name": "KONG_DATABASE",
      "value": "off"
    },
    {
      "name": "KONG_LOG_LEVEL",
      "value": "${kong_log_level}"
    },
    {
      "name": "KONG_ANONYMOUS_REPORTS",
      "value": "off"
    }
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
    "name": "LUA_SSL_CERT",
    "valueFrom": "${lua_ssl_cert}"
    },
    {
    "name": "CLUSTER_CERT",
    "valueFrom": "${cluster_cert}"
    },
    {
    "name": "CLUSTER_KEY",
    "valueFrom": "${cluster_key}"
    }
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
}
