locals {
  proxy     = "http://${aws_lb.external.dns_name}:8000"
  admin_api = "http://${aws_lb.external.dns_name}:8001"
}

output "kong-proxy-endpoint" {
  value = local.proxy
}

output "kong-api-endpoint" {
  value = local.admin_api
}
