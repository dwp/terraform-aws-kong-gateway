locals {
  proxy     = "http://${aws_lb.external.dns_name}:8000"
  admin_api = "http://${aws_lb.external.dns_name}:8001"
  cluster   = "http://${aws_lb.internal.dns_name}:8005"
  telemetry = "http://${aws_lb.internal.dns_name}:8006"
}

output "kong-proxy-endpoint" {
  value = local.proxy
}

output "kong-api-endpoint" {
  value = local.admin_api
}

output "kong-cluster-endpoint" {
  value = local.cluster
}

output "kong-telemetry-endpoint" {
  value = local.telemetry
}
