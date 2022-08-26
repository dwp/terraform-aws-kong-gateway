locals {
  proxy      = "http://${aws_lb.external.dns_name}:8000"
  admin_api  = "http://${aws_lb.external.dns_name}:8001"
  admin_gui  = "http://${aws_lb.external.dns_name}:8002"
  portal_gui = "http://${aws_lb.external.dns_name}:8003"
  portal_api = "http://${aws_lb.external.dns_name}:8004"
  cluster    = "http://${aws_lb.internal.dns_name}:8005"
  telemetry  = "http://${aws_lb.internal.dns_name}:8006"
}

output "kong-proxy-endpoint" {
  value = local.proxy
}

output "kong-api-endpoint" {
  value = local.admin_api
}

output "kong-gui-endpoint" {
  value = local.admin_gui
}

output "kong-portal-endpoint" {
  value = local.portal_gui
}

output "kong-portal-api-endpoint" {
  value = local.portal_api
}

output "kong-cluster-endpoint" {
  value = local.cluster
}

output "kong-telemetry-endpoint" {
  value = local.telemetry
}

output "admin_token_path" {
  value = aws_ssm_parameter.ee-admin-token.name
}
