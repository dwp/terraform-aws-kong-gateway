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
      "name": "KONG_ADMIN_GUI_AUTH",
      "value": "basic-auth"
    },
    {
      "name": "KONG_ENFORCE_RBAC",
      "value": "on"
    },
    {
      "name": "KONG_ADMIN_GUI_SESSION_CONF",
      "value": "{\"secret\":\"${session_secret}\",\"cookie_secure\":false}"
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
      "name": "KONG_ADMIN_ACCESS_LOG",
      "value": "/dev/stdout"
    },
    {
      "name": "KONG_ADMIN_ERROR_LOG",
      "value": "/dev/stderr"
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
      "name": "KONG_SSL_CERT",
      "value": "/usr/local/kong/ssl/kong.crt"
    },
    {
      "name": "KONG_SSL_CERT_KEY",
      "value": "/usr/local/kong/ssl/kong.key"
    },
    {
      "name": "KONG_ADMIN_LISTEN",
      "value": "0.0.0.0:${admin_api_port} ssl"
    },
    {
      "name": "KONG_ADMIN_API_URI",
      "value": "${kong_admin_api_uri}"
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
    {
      "name": "KONG_NGINX_HTTP_INCLUDE",
      "value": "/usr/local/kong/custom-nginx.conf"
    },
    {
      "name": "KONG_ROLE",
      "value": "control_plane"
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
    "name": "PGPASSWORD",
    "valueFrom": "${db_master_password_arn}"
    },
    {
    "name": "KONG_PG_PASSWORD",
    "valueFrom": "${db_password_arn}"
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
