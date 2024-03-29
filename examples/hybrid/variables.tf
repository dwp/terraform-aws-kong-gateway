variable "region" {
  description = "The name of an AWS region"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the kong deployments"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "The name of an AWS ssh key pair to associate with the instances in the ASG"
  type        = string
  default     = null
}

variable "kong_database_password" {
  description = "The password to use for the kong database"
  type        = string
}

variable "environment" {
  description = "Resource environment tag (i.e. dev, stage, prod)"
  type        = string
  default     = "test"
}

variable "service" {
  description = "Resource service tag"
  type        = string
  default     = "kong"
}

variable "description" {
  description = "Resource description tag"
  type        = string
  default     = "Kong API Gateway"
}

variable "ee_bintray_auth" {
  description = "enterprise repo creds"
  type        = string
  default     = "placeholder"
}

variable "ee_license" {
  description = "kong enterprise license"
  type        = string
  default     = "placeholder"
}

variable "vpc_cidr_block" {
  description = "VPC cidr range"
  type        = string
}

variable "asg_max_size" {
  description = "The maximum size of the auto scale group"
  type        = string
  default     = 1
}

variable "asg_min_size" {
  description = "The minimum size of the auto scale group"
  type        = string
  default     = 1
}

variable "asg_desired_capacity" {
  description = "The size of the autoscaling group"
  type        = string
  default     = 1
}

variable "postgres_master_user" {
  description = "The master user for postgres"
  type        = string
  default     = "root"
}

variable "kong_database_name" {
  description = "The kong database name"
  type        = string
  default     = "kong"
}

variable "kong_database_user" {
  description = "The database use needed to access kong"
  type        = string
  default     = "kong"
}

variable "external_cidr_blocks" {
  default = ["0.0.0.0/0"]
}

variable "tags" {
  type = map(string)
  default = {
    "Dept" = "Testing",
  }
}
