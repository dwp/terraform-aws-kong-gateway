variable "private_subnets" {
  description = "(Optional) List of private subnet IDs, if not specified then the subnets listed in the private_subnets_to_create variable will be created and used"
  type        = list(string)
  default     = []
}

variable "private_subnets_to_create" {
  description = "(Optional) A map of subnet objects to create"
  type = list(object({
    cidr_block = string
    az         = string
    public     = bool
  }))
  default = []
}

variable "security_group_ids" {
  description = "(Optional) A list of security group ID's to associate with the instances"
  type        = list(string)
  default     = []
}


variable "skip_rds_creation" {
  description = "(Optional) If set to true then this module will not create its own RDS instance"
  type        = bool
  default     = false
}

variable "environment" {
  description = "(Optional) Resource environment tag (i.e. dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "availability_zones" {
  description = "(Optional) If using the private_subnets variable then list the subnets availability_zones here"
  type        = list(string)
  default     = []
}

variable "security_group_name" {
  description = "(Optional) Common name. Used as security_group name prefix and `Name` tag"
  type        = string
  default     = "kong-security-group"
}

variable "vpc_id" {
  description = "The id of the vpc to create resources in"
  type        = string
}

variable "tags" {
  description = "Tags to apply to AWS resources, except Auto Scaling Group"
  type        = map(string)
}

variable "skip_final_snapshot" {
  description = "True/false value to set whether a final RDS Database snapshot should be taken when RDS resource is destroyed"
  type        = bool
}

variable "region" {
  description = "The aws region to access the SSM config items"
  type        = string
}

variable "kong_database_config" {
  description = "Configuration for the kong database"
  type = object({
    name     = string
    user     = string
    password = string
  })
  default = {
    name     = "kong"
    user     = "kong"
    password = null
  }
}

variable "postgres_config" {
  description = "Configuration settings for the postgres database engine"
  type = object({
    master_user     = string
    master_password = string
  })
}

variable "postgres_host" {
  description = "The address or name of the postgres database host, set this variable when choosing to skip_rds_creation"
  type        = string
}

variable "rules_with_source_cidr_blocks" {
  description = "Security rules for the Kong instance that have a cidr range for their source"
  type = map(object({
    type        = string,
    from_port   = number,
    to_port     = number,
    protocol    = string,
    cidr_blocks = list(string)
  }))
}

variable "rules_with_source_security_groups" {
  description = "Security rules for the Kong instance that have another security group for their source"
  type = map(object({
    type                     = string,
    from_port                = number,
    to_port                  = number,
    protocol                 = string,
    source_security_group_id = string
  }))
}

variable "rules_with_source_prefix_list_id" {
  description = "Security rules for the Kong instance that have a Prefix List ID as their Source"
  type = map(object({
    type           = string,
    from_port      = number,
    to_port        = number,
    protocol       = string,
    prefix_list_id = list(string),
  }))
}

###

variable "service" {
  description = "(Optional) Resource service tag"
  type        = string
}

variable "create_ecs_cluster" {
  description = "(Optional) Create ECS cluster to deploy to - defaults to true, otherwise deploy to existing cluster"
  type        = bool
  default     = true
}

variable "fargate_cpu" {
  description = "The CPU for the Fargate Task"
  type        = number
}

variable "fargate_memory" {
  description = "The Memory for the Fargate Task"
  type        = number
}

variable "kong_ports" {
  description = "The ports used by Kong"
  type        = map(number)
}

variable "enable_execute_command" {
  description = "Define whether to enable Amazon ECS Exec for tasks within the service."
  type        = bool
}

variable "platform_version" {
  description = "ECS Service platform version"
  type        = string
}

variable "ssl_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Certificate used to secure traffic to the gateway"
  type        = string
}

variable "ssl_key" {
  description = "Secrets Manager or Parameter Store ARN of the Key used to secure traffic to the gateway"
  type        = string
}

variable "lua_ssl_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Certificate used for Lua"
  type        = string
}

variable "kong_cluster_mtls" {
  description = "Define what type of Cluster mTLS is required - either 'shared' or 'pki'."
  type        = string
}

variable "cluster_ca_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Clustering Certificate Authority"
  type        = string
}

variable "cluster_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Clustering Certificate"
  type        = string
}

variable "cluster_key" {
  description = "Secrets Manager or Parameter Store ARN of the Clustering Key"
  type        = string
}

variable "kong_log_level" {
  description = "(Optional) Level of log output for the Gateway"
  type        = string
}

variable "access_log_format" {
  description = "Log location and format to be defined for the access logs"
  type        = string
}

variable "error_log_format" {
  description = "Log location and format to be defined for the error logs"
  type        = string
}

variable "desired_count" {
  description = "Desired Task count for the Gateway ECS Task Definition"
  type        = number
}

variable "min_capacity" {
  description = "Minimum Capacity for the Gateway ECS Task Definition"
  type        = number
}

variable "max_capacity" {
  description = "Maximum Capacity for the Gateway ECS Task Definition"
  type        = number
}

variable "custom_nginx_conf" {
  description = "Custom NGINX Config that is included in the main configuration through the variable KONG_NGINX_HTTP_INCLUDE"
  type        = string
}

variable "ecs_target_group_arns" {
  description = "Target Group ARNs for the ECS Service"
  type        = map(string)
}

variable "image_url" {
  description = "The URL where the Docker image resides"
  type        = string
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the Task Execution Role"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ARN of the ECS Cluster created"
}

variable "ecs_cluster_name" {
  type        = string
  description = "The ARN of the ECS Cluster created"
}

variable "db_password_arn" {
  description = "The DB Password ARN that is used by the ECS Task Definition"
  type        = string
}

variable "log_group" {
  description = "The Log Group for ECS to report out to"
  type        = string
}

variable "kong_admin_gui_session_conf" {
  description = "The session configuration that Kong will use"
  type        = string
}

variable "role" {
  description = "Role of the Kong Task"
  type        = string
}
variable "clustering_endpoint" {
  type        = string
  description = "Address of the control plane node from which configuration updates will be fetched"
}

variable "telemetry_endpoint" {
  type        = string
  description = "Telemetry address of the control plane node to which telemetry updates will be posted"
}

variable "cluster_server_name" {
  type        = string
  description = "The server name used in the SNI of the TLS connection from a DP node to a CP node"
}

variable "admin_token" {
  type        = string
  description = "The ARN of the admin token to be used within the ECS Task Definition."
}

variable "kong_admin_api_uri" {
  description = "The Admin API URI composed of a host, port and path on which the Admin API accepts traffic."
  type        = string
}

variable "kong_admin_gui_url" {
  description = "The Admin GUI URL of the Kong Manager."
  type        = string
}

variable "entrypoint" {
  description = "The entrypoint file used for the Task definition."
  type        = string
}

variable "kong_vitals_enabled" {
  description = "Define whether or not Kong Vitals should be enabled."
  type        = string
}

variable "kong_portal_enabled" {
  description = "Define whether or not the Kong Portal should be enabled."
  type        = string
}

variable "kong_portal_gui_host" {
  description = "The Hostname used for the Portal GUI."
  type        = string
}

variable "kong_portal_gui_protocol" {
  description = "The protocol used for the portal GUI."
  type        = string
}

variable "kong_portal_api_url" {
  description = "The Portal API URL of the Portal."
  type        = string
}

variable "kong_plugins" {
  description = "Comma-separated list of Kong plugins, passed through the variable KONG_PLUGINS"
  type        = string
  default     = "bundled"
}
