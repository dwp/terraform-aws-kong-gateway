locals {
  ids = [for s in aws_subnet.subnet : s.id]
  azs = [for s in local.subnets : s.az]
}

output "ids" {
  value       = local.ids
  description = "Array of subnet IDs"
}

output "azs" {
  value       = local.azs
  description = "Array of availability zones used by the subnets"
}
