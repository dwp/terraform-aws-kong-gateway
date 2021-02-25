locals {
  ids = [for s in aws_subnet.this-subnet : s.id]
  azs = [for s in local.subnets : s.az]
}

output "ids" {
  value = local.ids
}

output "azs" {
  value = local.azs
}
