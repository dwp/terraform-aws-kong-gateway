variable "ami_id" {
  description = "AMI image id to use for the deployments"
  type        = string
}

variable "instance_type" {
  description = "The instance type to use for the kong deployments"
  type        = string
  default     = "t3.medium"
}

variable "iam_instance_profile_name" {
  description = "The name of an IAM instance profile to apply to this deployment"
  type        = string
}

variable "key_name" {
  description = "The name of the aws key pair to use with the deployment"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group ID's to associate with the instances"
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Should our instances be given public IP addresses"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Should monitoring be enabled on the instances"
  type        = bool
  default     = true
}

variable "placement_tenancy" {
  description = "TODO"
  type        = string
  default     = "default"
}

variable "kong_config" {
  description = "A map of key value pairs that describe the Kong GW config, used when constructing the userdata script"
  type        = map(string)
  default     = {}
}

variable "root_block_size" {
  description = "The size of the root block device to attach to each instance"
  type        = number
  default     = 20
}

variable "root_block_type" {
  description = "The type of root block device to add"
  type        = string
  default     = "gp2"
}

variable "vpc_zone_identifier" {
  description = "A list of subnet IDs to launch resources in. Subnets automatically determine which availability zones the group will reside"
  type        = list(string)
  default     = []
}

variable "desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  type        = number
  default     = 1
}

variable "force_delete" {
  description = "Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate"
  type        = bool
  default     = false
}

variable "health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "EC2 or ELB. Controls how health checking is done"
  type        = string
  default     = "EC2"
}

variable "max_size" {
  description = "The maximum size of the auto scaling group"
  type        = number
  default     = 3
}

variable "min" {
  description = "The minimum size of the auto scaling group"
  type        = number
  default     = 1
}

variable "environment" {
  description = "Resource environment tag (i.e. dev, stage, prod)"
  type        = string
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

variable "additional_tags" {
  description = "Tags to apply to the ASG"
  type        = map(string)
  default     = {}
}

## cloud init variables

variable "kong_database_user" {
  description = "The database use needed to access kong"
  type        = string
  default     = "kong"
}

variable "ce_pkg" {
  description = "Filename of the Community Edition package"
  type        = string
  default     = "kong-1.5.0.bionic.amd64.deb" # todo: update
}

variable "ee_pkg" {
  description = "Filename of the Enterprise Edition package"
  type        = string
  default     = "kong-enterprise-edition-1.3.0.1.bionic.all.deb" # todo: update
}

variable "ssm_parameter_path" {
  description = "The path to the Kong config items in SSM"
  type        = string
}

variable "region" {
  description = "The aws region to access the SSM config items"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block in use by the kong vpc"
  type        = string
}

variable "private_subnets" {
  description = "List of private subent IDs"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subent IDs"
  type        = list(string)
}

variable "deck_version" {
  description = "The version of deck to install"
  type        = string
  default     = "1.0.0"
}

variable "manager_host" {
  description = "The host address or name to access kong manager"
  type        = string
}

variable "portal_host" {
  description = "The host address or name to access kong developer portal"
  type        = string
}

variable "session_secret" {
  description = "The host address or name to access kong developer portal"
  type        = string
}

variable "ec2_root_volume_size" {
  description = "Size of the root volume (in Gigabytes)"
  type        = string

  default = 8
}

variable "ec2_root_volume_type" {
  description = "Type of the root volume (standard, gp2, or io)"
  type        = string

  default = "gp2"
}

variable "asg_max_size" {
  description = "The maximum size of the auto scale group"
  type        = string

  default = 3
}

variable "asg_min_size" {
  description = "The minimum size of the auto scale group"
  type        = string

  default = 1
}

variable "asg_desired_capacity" {
  description = "The number of instances that should be running in the group"
  type        = string

  default = 2
}

variable "asg_health_check_grace_period" {
  description = "Time in seconds after instance comes into service before checking health"
  type        = string

  # Terraform default is 300
  default = 300
}
