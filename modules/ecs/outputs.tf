output "ecs_task_definition_outputs" {
  value       = aws_ecs_task_definition.kong
  description = "Full resource details for the ECS Task definition"
  sensitive   = false
}

output "ecs_service_outputs" {
  value       = aws_ecs_service.kong
  description = "Full resource details for the ECS Service"
  sensitive   = false
}

output "kong_iam_role" {
  description = "IAM Role used by the ECS Task for the Gateway"
  value       = aws_iam_role.kong_task_role.name
}

output "private_subnet_azs" {
  value       = local.azs
  description = "List of availability zones used for the private subnets, either supplied in the optional `supplied in the optional `private_subnets` input variable or created in `subnets` submodule` input variable or defined in `subnets` submodule."
  sensitive   = false
}

output "private_subnet_ids" {
  value       = local.private_subnets
  description = "List of private subnet IDs. These are either supplied in the optional `private_subnets` input variable or created in `subnets` submodule."
  sensitive   = false
}

output "db_outputs" {
  value       = local.database
  description = "The DNS address and database name of the RDS instance, and security group ID from the database module."
  sensitive   = false
}
