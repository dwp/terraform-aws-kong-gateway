###########################################################
# Some prerequs for running the example:
#  a kubernetes cluster (minikube/eks) and a
#  ~/.kube/config file that enables connectivity to it
#
# Other Files In this Example:
#
# tls_shared.tf:    creates all the certificates we need for a 
#                   hybrid mode deplolyment of Kong
#
# secrets_setup.tf: creates secrets in kubernetes for the kong
#                   + postgres deployments
#
# postgres.tf:      deploys a simple postgres pod for
#                   the kong cp to connect to
#
# variables.tf:      variables for the kong deployment
#                   can be overriden if needed

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Create two namespaces one for cp and pg and
# one for dp
resource "kubernetes_namespace" "kong" {
  for_each = var.namespaces
  metadata {
    name = each.value["name"]
  }
}

locals {
  kong_cp_deployment_name = "kong-enterprise-cp"
  kong_dp_deployment_name = "kong-enterprise-dp"
  kong_image              = "kong-docker-kong-enterprise-edition-docker.bintray.io/kong-enterprise-edition:2.2.0.0-alpine"
  portal_ip               = kubernetes_service.kong-portal-gui-portal-admin-api.status.0.load_balancer.0.ingress.0.hostname != "" ? kubernetes_service.kong-portal-gui-portal-admin-api.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.kong-portal-gui-portal-admin-api.status.0.load_balancer.0.ingress.0.ip
  manager_ip              = kubernetes_service.kong-admin-api-manager-gui.status.0.load_balancer.0.ingress.0.hostname != "" ? kubernetes_service.kong-admin-api-manager-gui.status.0.load_balancer.0.ingress.0.hostname : kubernetes_service.kong-admin-api-manager-gui.status.0.load_balancer.0.ingress.0.ip
  #  portal_ip               = kubernetes_service.kong-portal-gui-portal-admin-api.status.0.load_balancer.0.ingress.0.ip
  #  manager_ip              = kubernetes_service.kong-admin-api-manager-gui.status.0.load_balancer.0.ingress.0.ip
  #  portal_ip               = kubernetes_service.kong-portal-gui-portal-admin-api.status.0.load_balancer.0.ingress.0.hostname
  #  manager_ip              = kubernetes_service.kong-admin-api-manager-gui.status.0.load_balancer.0.ingress.0.hostname
  cluster_ip   = kubernetes_service.kong-cluster-endpoint.spec.0.cluster_ip
  telemetry_ip = kubernetes_service.kong-cluster-endpoint.spec.0.cluster_ip

  kong_image_pull_secrets = [
    {
      name = var.image_pull_secret_name
    }
  ]

  kong_volume_mounts = [
    {
      mount_path = "/etc/secrets/kong-cluster-cert"
      name       = var.tls_secret_name
      read_only  = true
    }
  ]

  kong_volume_secrets = [
    {
      name        = var.tls_secret_name
      secret_name = var.tls_secret_name
    }
  ]

  #
  # Control plane configuration 
  #
  kong_cp_secret_config = [
    {
      name        = "KONG_LICENSE_DATA"
      secret_name = var.license_secret_name
      key         = var.license_secret_name
    },
    {
      name        = "KONG_ADMIN_GUI_SESSION_CONF"
      secret_name = var.session_conf_secret_name
      key         = var.gui_config_secret_key
    },
    {
      name        = "KONG_PORTAL_SESSION_CONF"
      secret_name = var.session_conf_secret_name
      key         = var.portal_config_secret_key
    }
  ]


  kong_cp_config = [
    {
      name  = "KONG_ADMIN_LISTEN"
      value = "0.0.0.0:8001, 0.0.0.0:8444 ssl"
    },
    {
      name = "KONG_ADMIN_API_URI"
      # value = "http://kong-admin-api-manager-gui.kong-hybrid-cp.scv.cluster.local:8001"
      value = "http://${local.manager_ip}:8001"
    },
    {
      name  = "KONG_ADMIN_GUI_AUTH"
      value = "basic-auth"
    },
    {
      name  = "KONG_ADMIN_GUI_LISTEN"
      value = "0.0.0.0:8002, 0.0.0.0:8445 ssl"
    },
    {
      name  = "KONG_ENFORCE_RBAC"
      value = "on"
    },
    {
      name  = "KONG_PG_PASSWORD"
      value = "kong"
    },
    {
      name  = "KONG_PG_HOST"
      value = "postgres"
    },
    {
      name  = "KONG_PROXY_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_ADMIN_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_PROXY_ERROR_LOG"
      value = "/dev/stderr"
    },
    {
      name  = "KONG_ADMIN_ERROR_LOG"
      value = "/dev/stderr"
    },
    {
      name  = "KONG_PORTAL"
      value = "on"
    },
    {
      name  = "KONG_ADMIN_GUI_FLAGS"
      value = "{\"IMMUNITY_ENABLED\":true}"
    },
    {
      name  = "KONG_PORTAL_GUI_LISTEN"
      value = "0.0.0.0:8003, 0.0.0.0:8446 ssl"
    },
    {
      name  = "KONG_PORTAL_API_LISTEN"
      value = "0.0.0.0:8004, 0.0.0.0:8447 ssl"
    },
    {
      name  = "KONG_PORTAL_GUI_HOST"
      value = "${local.portal_ip}:8003"
    },
    {
      name  = "KONG_PORTAL_API_URL"
      value = "http://${local.portal_ip}:8004"
    },
    {
      name  = "KONG_PORTAL_GUI_PROTOCOL"
      value = "http"
    },
    {
      name  = "KONG_PORTAL_AUTH"
      value = "basic-auth"
    },
    {
      name  = "KONG_ANONYMOUS_REPORTS"
      value = "off"
    },
    {
      name  = "KONG_ROLE"
      value = "control_plane"
    },
    {
      name  = "KONG_CLUSTER_CERT"
      value = "/etc/secrets/kong-cluster-cert/tls.crt"
    },
    {
      name  = "KONG_CLUSTER_CERT_KEY"
      value = "/etc/secrets/kong-cluster-cert/tls.key"
    },
    {
      name  = "KONG_CLUSTER_LISTEN"
      value = "0.0.0.0:8005 ssl"
    },
    {
      name  = "KONG_CLUSTER_MTLS"
      value = "shared"
    },
    {
      name  = "KONG_CLUSTER_TELEMETRY_LISTEN"
      value = "0.0.0.0:8006 ssl"
    },
    {
      name  = "KONG_STATUS_LISTEN"
      value = "0.0.0.0:8100"
    },
    {
      name  = "KONG_STREAM_LISTEN"
      value = "off"
    }
  ]

  #
  # Data plane configuration 
  #
  kong_dp_secret_config = [
    {
      name        = "KONG_LICENSE_DATA"
      secret_name = var.license_secret_name
      key         = var.license_secret_name
    }
  ]

  kong_dp_config = [
    {
      name  = "KONG_ADMIN_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_PROXY_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_ADMIN_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_PROXY_ERROR_LOG"
      value = "/dev/stderr"
    },
    {
      name  = "KONG_ADMIN_ERROR_LOG"
      value = "/dev/stderr"
    },
    {
      name  = "KONG_ADMIN_GUI_LISTEN"
      value = "off"
    },
    {
      name  = "KONG_ADMIN_LISTEN"
      value = "off"
    },
    {
      name  = "KONG_CLUSTER_CERT"
      value = "/etc/secrets/kong-cluster-cert/tls.crt"
    },
    {
      name  = "KONG_CLUSTER_CERT_KEY"
      value = "/etc/secrets/kong-cluster-cert/tls.key"
    },
    {
      name  = "KONG_LUA_SSL_TRUSTED_CERTIFICATE"
      value = "/etc/secrets/kong-cluster-cert/tls.crt"
    },
    {
      name  = "KONG_ROLE"
      value = "data_plane"
    },
    {
      name = "KONG_CLUSTER_CONTROL_PLANE"
      # value = "kong-cluster-endpoint.kong-hybrid-cp.svc.cluster.local:8005"
      value = "${local.cluster_ip}:8005"
    },
    {
      name  = "KONG_CLUSTER_LISTEN"
      value = "off"
    },
    {
      name  = "KONG_CLUSTER_MTLS"
      value = "shared"
    },
    {
      name = "KONG_CLUSTER_TELEMETRY_ENDPOINT"
      # value = "kong-cluster-endpoint.kong-hybrid-cp.svc.cluster.local:8006"
      value = "${local.telemetry_ip}:8006"
    },
    {
      name  = "KONG_CLUSTER_TELEMETRY_LISTEN"
      value = "off"
    },
    {
      name  = "KONG_DATABASE"
      value = "off"
    },
    {
      name  = "KONG_LOG_LEVEL"
      value = "error"
    },
    {
      name  = "KONG_LUA_PACKAGE_PATH"
      value = "/opt/?.lua;/opt/?/init.lua;;"
    },
    {
      name  = "KONG_NGINX_WORKER_PROCESSES"
      value = "2"
    },
    {
      name  = "KONG_PLUGINS"
      value = "bundled"
    },
    {
      name  = "KONG_PORTAL_API_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_PORTAL_API_ERROR_LOG"
      value = "/dev/stderr"
    },
    {
      name  = "KONG_PORT_MAPS"
      value = "8000:8000, 8443:8443"
    },
    {
      name  = "KONG_PROXY_ACCESS_LOG"
      value = "/dev/stdout"
    },
    {
      name  = "KONG_PROXY_ERROR_LOG"
      value = "/dev/stderr"
    },
    {
      name  = "KONG_PROXY_LISTEN"
      value = "0.0.0.0:8000 , 0.0.0.0:8443 ssl"
    },
    {
      name  = "KONG_STATUS_LISTEN"
      value = "0.0.0.0:8100"
    },
    {
      name  = "KONG_STREAM_LISTEN"
      value = "off"
    }
  ]
}

# Use the Kong module to create a cp
module "kong-enterprise" {
  source              = "../../"
  deployment_name     = local.kong_cp_deployment_name
  namespace           = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  deployment_replicas = 1
  config              = local.kong_cp_config
  secret_config       = local.kong_cp_secret_config
  kong_image          = local.kong_image
  image_pull_secrets  = local.kong_image_pull_secrets
  volume_mounts       = local.kong_volume_mounts
  volume_secrets      = local.kong_volume_secrets
}

# Use the Kong module to create a dp
module "kong-enterprise-dp" {
  source              = "../../"
  deployment_name     = local.kong_dp_deployment_name
  namespace           = kubernetes_namespace.kong["kong-hybrid-dp"].metadata[0].name
  deployment_replicas = 1
  config              = local.kong_dp_config
  secret_config       = local.kong_dp_secret_config
  kong_image          = local.kong_image
  image_pull_secrets  = local.kong_image_pull_secrets
  volume_mounts       = local.kong_volume_mounts
  volume_secrets      = local.kong_volume_secrets
}

#
# Create services for all of our Kong endpoints
#
resource "kubernetes_service" "kong-admin-api-manager-gui" {
  metadata {
    name      = "kong-admin-api-manager-gui"
    namespace = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  }
  spec {
    type = "LoadBalancer"
    load_balancer_source_ranges = [
      "0.0.0.0/0"
    ]

    port {
      name        = "kong-admin"
      port        = 8001
      protocol    = "TCP"
      target_port = 8001
    }

    port {
      name        = "kong-manager"
      port        = 8002
      protocol    = "TCP"
      target_port = 8002
    }

    port {
      name        = "kong-admin-ssl"
      port        = 8444
      protocol    = "TCP"
      target_port = 8444
    }

    port {
      name        = "kong-manager-ssl"
      port        = 8445
      protocol    = "TCP"
      target_port = 8445
    }
    selector = {
      app = local.kong_cp_deployment_name
    }
  }
}

resource "kubernetes_service" "kong-portal-gui-portal-admin-api" {
  metadata {
    name      = "kong-portal-gui-portal-admin-api"
    namespace = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  }

  spec {
    type = "LoadBalancer"
    load_balancer_source_ranges = [
      "0.0.0.0/0"
    ]

    port {
      name        = "kong-portal-admin"
      port        = 8004
      protocol    = "TCP"
      target_port = 8004
    }

    port {
      name        = "kong-portal-gui"
      port        = 8003
      protocol    = "TCP"
      target_port = 8003
    }

    port {
      name        = "kong-portal-admin-ssl"
      port        = 8447
      protocol    = "TCP"
      target_port = 8447
    }

    port {
      name        = "kong-portal-gui-ssl"
      port        = 8446
      protocol    = "TCP"
      target_port = 8446
    }
    selector = {
      app = local.kong_cp_deployment_name
    }
  }
}

resource "kubernetes_service" "kong-cluster-endpoint" {

  metadata {
    name      = "kong-cluster-endpoint"
    namespace = kubernetes_namespace.kong["kong-hybrid-cp"].metadata[0].name
  }
  spec {
    port {
      name        = "kong-cluster-ssl"
      port        = 8005
      protocol    = "TCP"
      target_port = 8005
    }

    port {
      name        = "kong-telemetry-ssl"
      port        = 8006
      protocol    = "TCP"
      target_port = 8006
    }

    selector = {
      app = local.kong_cp_deployment_name
    }
  }
}

resource "kubernetes_service" "kong-proxy-api" {

  metadata {
    name      = "kong-proxy-api"
    namespace = kubernetes_namespace.kong["kong-hybrid-dp"].metadata[0].name
  }
  spec {
    type = "LoadBalancer"
    load_balancer_source_ranges = [
      "0.0.0.0/0"
    ]

    port {
      name        = "kong-proxy"
      port        = 8000
      protocol    = "TCP"
      target_port = 8000
    }

    port {
      name        = "kong-proxy-ssl"
      port        = 8443
      protocol    = "TCP"
      target_port = 8443
    }

    selector = {
      app = local.kong_dp_deployment_name
    }
  }
}
