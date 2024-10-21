## EC2
output "asg_outputs" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].asg_outputs : null
  description = "Full `aws_autoscaling_group` resource details for the autoscaling group created for Kong."
  sensitive   = false
}

output "launch_template_outputs" {
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].launch_template_outputs : null
  description = "Full `aws_launch_template` resource details for the launch configuration created for Kong."
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
  value       = var.deployment_type == "ec2" ? module.kong_ec2[0].security_groups : var.deployment_type == "ecs" ? module.kong_ecs[0].security_groups : null
  sensitive   = false
}

## ECS

output "kong_iam_role" {
  description = "IAM Role used by the ECS Task for the Gateway"
  value       = var.deployment_type == "ecs" ? module.kong_ecs[0].kong_iam_role : null
}

output "ecs_task_definition_outputs" {
  value       = module.kong_ecs[0].ecs_task_definition_outputs
  description = "Full resource details for the ECS Task definition"
  sensitive   = false
}

output "ecs_service_outputs" {
  value       = module.kong_ecs[0].ecs_service_outputs
  description = "Full resource details for the ECS Service"
  sensitive   = false
}
