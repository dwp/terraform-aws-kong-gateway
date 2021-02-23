variable "name" {
  description = "Common name. Used as part of resource names"
  type        = string
}

variable "tags" {
  description = "Tags to apply to aws resources"
  type        = map(string)
}

variable "vpc" {
  description = "VPC config, including VPC ID and a list of subnets"
  type = object({
    id      = string
    subnets = list(string)
  })
}

variable "database" {
  description = "Database configuration options"

  type = object({
    instance_type           = string
    db_count                = number
    engine                  = string
    engine_version          = string
    backup_retention_period = number
    preferred_backup_window = string
  })

  default = {
    instance_type           = "db.t3.medium"
    db_count                = 1
    engine                  = "aurora-postgresql"
    engine_version          = "11.9"
    backup_retention_period = 14
    preferred_backup_window = "01:00-03:00"
  }
}

variable "database_credentials" {
  description = "Credentials to set for database master user"

  type = object({
    username = string,
    password = string,
  })
}
