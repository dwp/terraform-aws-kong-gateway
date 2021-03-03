output "private_subnet_ids" {
  value = local.private_subnets
}

output "private_subnet_azs" {
  value = local.azs
}

output "asg_outputs" {
  value = aws_autoscaling_group.kong
}