## EC2
output "asg_outputs" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].asg_outputs : null
  description = "Full `aws_autoscaling_group` resource details for the autoscaling group created for Kong."
  sensitive   = false
}

output "launch_config_outputs" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].launch_config_outputs : null
  description = "Full `aws_launch_configuration` resource details for the launch configuration created for Kong."
  sensitive   = false
}

output "db_outputs" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].db_outputs : null
  description = "The DNS address and database name of the RDS instance, and security group ID from the database module."
  sensitive   = false
}

## All
output "private_subnet_azs" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].private_subnet_azs : var.deployment_type == "ecs" ? module.kong_ecs[0].private_subnet_azs : null
  description = "List of availability zones used for the private subnets, either supplied in the optional `supplied in the optional `private_subnets` input variable or created in `subnets` submodule` input variable or defined in `subnets` submodule."
  sensitive   = false
}

output "private_subnet_ids" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].private_subnet_ids : var.deployment_type == "ecs" ? module.kong_ecs[0].private_subnet_ids : null
  description = "List of private subnet IDs. These are either supplied in the optional `private_subnets` input variable or created in `subnets` submodule."
  sensitive   = false
}

output "security_groups" {
  description = "List of Security Groups used by Kong."
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].launch_config_outputs["security_groups"] : var.deployment_type == "ecs" ? module.kong_ecs[0].security_groups : null
  sensitive   = false
}

## ECS

output "kong_iam_role" {
  description = "IAM Role used by the ECS Task for the Gateway"
  value       = var.deployment_type == "ecs" ? module.kong_ecs[0].kong_iam_role : null
}

