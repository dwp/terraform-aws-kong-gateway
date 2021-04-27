variable "allowed_security_groups" {
  description = "The ids of the security groups to allow db access from"
  type        = list(string)
}

variable "database_credentials" {
  description = "Credentials to set for database master user"

  type = object({
    username = string,
    password = string,
  })
}

variable "name" {
  description = "Common name. Used as part of resource names"
  type        = string
}

variable "vpc" {
  description = "VPC config, including VPC ID and a list of subnets"
  type = object({
    id      = string
    subnets = list(string)
    azs     = list(string)
  })
}

variable "environment" {
  description = "(Optional) Resource environment tag (i.e. dev, stage, prod). Used in resource names"
  type        = string
  default     = "test"
}

variable "database" {
  description = "(Optional) Database configuration options"

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

variable "skip_final_snapshot" {
  type        = bool
  description = "(Optional) true/false value to set whether a final RDS Database snapshot should be taken when RDS resource is destroyed"
  default     = true
}

variable "encrypt_storage" {
  type        = bool
  description = "(Optional) true/false value to set whether storage within the RDS Database should be encrypted"
  default     = true
}

variable "tags" {
  description = "Tags to apply to aws resources"
  type        = map(string)
  default     = {}
}
