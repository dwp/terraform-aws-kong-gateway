locals {
  ids = [for s in aws_subnet.this-subnet : s.id]
}
output "ids" {
  value = local.ids
}
