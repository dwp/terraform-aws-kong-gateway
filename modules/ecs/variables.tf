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
  default = [
    {
      cidr_block = "10.0.1.0/24"
      az         = "default"
      public     = false
    },
    {
      cidr_block = "10.0.2.0/24"
      az         = "default"
      public     = false
    },
    {
      cidr_block = "10.0.3.0/24"
      az         = "default"
      public     = false
    }
  ]
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

variable "encrypt_storage" {
  description = "(Optional) true/false value to set whether storage within the RDS Database should be encrypted"
  type        = bool
  default     = true
}

variable "tags" {
  description = "(Optional) Tags to apply to AWS resources, except Auto Scaling Group"
  type        = map(string)
  default     = {}
}

variable "skip_final_snapshot" {
  description = "(Optional) true/false value to set whether a final RDS Database snapshot should be taken when RDS resource is destroyed"
  type        = bool
  default     = true
}

variable "region" {
  description = "The aws region to access the SSM config items"
  type        = string
  default     = "eu-central-1"
}

variable "kong_database_config" {
  description = "(Optional) Configuration for the kong database"
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
  description = "(Optional) Configuration settings for the postgres database engine"
  type = object({
    master_user     = string
    master_password = string
  })
  default = {
    master_user     = "root"
    master_password = null
  }
}

variable "postgres_host" {
  description = "(Optional) The address or name of the postgres database host, set this variable when choosing to skip_rds_creation"
  type        = string
  default     = ""
}

variable "rules_with_source_cidr_blocks" {
  description = "(Optional) Security rules for the Kong instance that have a cidr range for their source"
  type = map(object({
    type        = string,
    from_port   = number,
    to_port     = number,
    protocol    = string,
    cidr_blocks = list(string)
  }))
  default = {
    "kong-ingress-proxy-https" = {
      type        = "ingress",
      from_port   = 8443,
      to_port     = 8443,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-api-https" = {
      type        = "ingress",
      from_port   = 8444,
      to_port     = 8444,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-manager-https" = {
      type        = "ingress",
      from_port   = 8445,
      to_port     = 8445,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-portal-gui-https" = {
      type        = "ingress",
      from_port   = 8446,
      to_port     = 8446,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-portal-https" = {
      type        = "ingress",
      from_port   = 8447,
      to_port     = 8447,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-ssh" = {
      type        = "ingress",
      from_port   = 22,
      to_port     = 22,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-8005" = {
      type        = "ingress",
      from_port   = 8005,
      to_port     = 8005,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-8006" = {
      type        = "ingress",
      from_port   = 8006,
      to_port     = 8006,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-8100" = {
      type        = "ingress",
      from_port   = 8100,
      to_port     = 8100,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-80" = {
      type        = "egress",
      from_port   = 80,
      to_port     = 80,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-443" = {
      type        = "egress",
      from_port   = 443,
      to_port     = 443,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-8443" = {
      type        = "egress",
      from_port   = 8443,
      to_port     = 8443,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-8444" = {
      type        = "egress",
      from_port   = 8444,
      to_port     = 8444,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-8005" = {
      type        = "egress",
      from_port   = 8005,
      to_port     = 8005,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-8006" = {
      type        = "egress",
      from_port   = 8006,
      to_port     = 8006,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-postgresq" = {
      type        = "egress",
      from_port   = 5432,
      to_port     = 5432,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-proxy" = {
      type        = "egress",
      from_port   = 3128,
      to_port     = 3128,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "rules_with_source_security_groups" {
  description = "(Optional) Security rules for the Kong instance that have another security group for their source"
  type = map(object({
    type                     = string,
    from_port                = number,
    to_port                  = number,
    protocol                 = string,
    source_security_group_id = string
  }))
  default = {}
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
  default = {}
}

###

variable "service" {
  description = "(Optional) Resource service tag"
  type        = string
  default     = "exchange"
}

variable "create_ecs_cluster" {
  description = "(Optional) Create ECS cluster to deploy to - defaults to true, otherwise deploy to existing cluster"
  type        = bool
  default     = true
}

# variable "env" {
#   description = "Environment name, used to namespace resources e.g. pipeline ID or local reference"
#   type        = string
# }

variable "fargate_cpu" {
  description = "(Optional) The CPU for the Fargate Task"
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.fargate_cpu)
    error_message = "Must be one of the following values: 256, 512, 1024, 2048, 4096."
  }
}

variable "fargate_memory" {
  description = "(Optional) The Memory for the Fargate Task"
  type        = number
  default     = 2048

  validation {
    condition     = contains([512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384, 17408, 18432, 19456, 20480, 21504, 22528, 23552, 24576, 25600, 26624, 27648, 28672, 29696, 30720], var.fargate_memory)
    error_message = "Must be either 512 or a multiple of 1024, up to 30720."
  }
}

variable "kong_dp_ports" {
  description = "The ports for the Kong Data Plane"
  type        = map(string)
  default = {
    "admin-api"  = 8444,
    "status"     = 8100,
    "clustering" = 8005,
    "telemetry"  = 8006
  }
}

variable "kong_cp_ports" {
  description = "The ports for the Kong Control Plane"
  type        = map(string)
  default = {
    "proxy"      = 8443,
    "status"     = 8100
  }
}

variable "log_retention_period" {
  description = "(Optional) The retention period for logs (in days), as described in the policy document"
  type        = number
  default     = 7

  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_period)
    error_message = "Must be one of the following values: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "gateway_image" {
  description = "(Optional) Image to be used for the Exchange Gateway"
  type = object({
    account    = string
    repository = string
    tag        = string
  })
  default = {
    account    = "072874872668"
    repository = "exchange-gateway"
    tag        = "kong2.8.1.1-oidc2.3.0-1" # Default for now whilst versioning is refined and decided upon
  }
}

variable "enable_execute_command" {
  description = "Define whether to enable Amazon ECS Exec for tasks within the service."
  type        = bool
  default     = true
}

variable "platform_version" {
  description = "(Optional) ECS Service platform version"
  type        = string
  default     = "1.4.0"
}

# variable "management_plane_endpoint" {
#   description = "Server name of the Control Plane to cluster to"
#   type        = string
# }

variable "ssl_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Certificate used to secure traffic to the gateway"
  type        = string
}

variable "ssl_key" {
  description = "Secrets Manager or Parameter Store ARN of the Key used to secure traffic to the gateway"
  type        = string
}

variable "lua_ssl_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Certificate used for Lua cosockets"
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
  default     = "warn"
}

variable "access_log_format" {
  description = "Log location and format to be defined for the access logs"
  type        = string
}

variable "error_log_format" {
  description = "Log location and format to be defined for the error logs"
  type        = string
}

variable "secrets_list" {
  description = "(Optional) List of Secret or Parameter Store ARNs to grant the ECS Task Execution Role to"
  type        = list(string)
  default     = ["*"]
}

variable "desired_count" {
  description = "(Optional) Desired Task count for the Gateway ECS Task Definition"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "(Optional) Minimum Capacity for the Gateway ECS Task Definition"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "(Optional) Maximum Capacity for the Gateway ECS Task Definition"
  type        = number
  default     = 2
}

variable "custom_nginx_conf" {
  description = "Custom NGINX Config that is included in the main configuration through the variable KONG_NGINX_HTTP_INCLUDE"
  type        = string
}

variable "ecs_target_group_arns" {
  description = "Target Group ARN for ECS"
  type        = map(string)
  default     = null
}

variable "image_url" {
  description = "URL Image"
  type        = string
}

variable "template_file" {
  description = "Template file to use to decide if data or control plane"
  type        = string
}

variable "execution_role_arn" {
  type        = string
  description = "ARN of the Task Execution Role"
  default     = null
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
  default     = null
}

variable "db_master_password_arn" {
  description = "The Master DB Password ARN that is used by the ECS Task Definition"
  type        = string
  default     = null
}

variable "log_group" {
  description = "The Log Group for ECS to report out to"
  type        = string
}

variable "session_secret" {
  description = "The session secret that Kong will use"
  type        = string
  default     = null
}

variable "kong_ssl_uris" {
  description = "(Optional) Object containing the ssl uris for kong, e.g. load balancer dns names and ports"
  type = object({
    protocol            = string
    admin_api_uri       = string
    admin_gui_url       = string
    portal_gui_host     = string
    portal_api_url      = string
    portal_cors_origins = string
  })
  default = { # TBD
    protocol            = "http"
    admin_api_uri       = "https://localhost:8444"
    admin_gui_url       = "https://localhost:8445"
    portal_gui_host     = "https://localhost:8446"
    portal_api_url      = "https://localhost:8447"
    portal_cors_origins = null
  }
}

variable "role" {
  description = "Role of the Kong Task"
  type        = string
}

variable "control_plane_endpoint" {
  type        = string
  description = ""
  default     = null
}

variable "clustering_endpoint" {
  type        = string
  description = ""
  default     = null
}

variable "telemetry_endpoint" {
  type        = string
  description = ""
  default     = null
}

variable "admin_token" {
  type        = string
  description = ""
  default     = null
}
