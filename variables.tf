### required Variables
variable "ami_id" {
  description = "AMI image id to use for the deployments"
  type        = string
}

variable "ami_operating_system" {
  description = "(Optional) Operating system present on supplied `ami_id` AMI. Supported values are `amazon-linux` and `ubuntu`"
  type        = string
  default     = "ubuntu"

  validation {
    condition     = can(regex("^(amazon-linux|ubuntu)$", var.ami_operating_system))
    error_message = "Supported values are `amazon-linux` and `ubuntu`."
  }
}

variable "iam_instance_profile_name" {
  description = "The name of an IAM instance profile to apply to this deployment"
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

variable "vpc_id" {
  description = "The id of the vpc to create resources in"
  type        = string
}

### Optional Variables
variable "asg_desired_capacity" {
  description = "(Optional) The number of instances that should be running in the group"
  type        = string
  default     = 2
}

variable "asg_health_check_grace_period" {
  description = "(Optional) Time in seconds after instance comes into service before checking health"
  type        = string
  default     = 600
}

variable "asg_max_size" {
  description = "(Optional) The maximum size of the auto scale group"
  type        = string
  default     = 3
}

variable "asg_min_size" {
  description = "(Optional) The minimum size of the auto scale group"
  type        = string
  default     = 1
}

variable "associate_public_ip_address" {
  description = "(Optional) Should our instances be given public IP addresses"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "(Optional) If using the private_subnets variable then list the subnets availability_zones here"
  type        = list(string)
  default     = []
}

variable "ce_pkg" {
  description = "(Optional) Filename of the Community Edition package"
  type        = string
  default     = "kong-2.3.2.focal.amd64.deb"
}

variable "deck_version" {
  description = "(Optional) The version of deck to install"
  type        = string
  default     = "1.0.0"
}

variable "desired_capacity" {
  description = "(Optional) The number of Amazon EC2 instances that should be running in the group"
  type        = number
  default     = 1
}

variable "description" {
  description = "(Optional) Resource description tag"
  type        = string
  default     = "Kong API Gateway"
}

variable "ec2_root_volume_size" {
  description = "(Optional) Size of the root volume (in Gigabytes)"
  type        = string
  default     = 8
}

variable "ec2_root_volume_type" {
  description = "(Optional) Type of the root volume (standard, gp2, or io)"
  type        = string
  default     = "gp2"
}

variable "ee_creds_ssm_param" {
  description = "(Optional) SSM parameter names where customer's Kong enterprise license credentials are stored"
  type = object({
    license          = string
    bintray_username = string
    bintray_password = string
    admin_token      = string
  })
  default = {
    license          = null
    bintray_username = null
    bintray_password = null
    admin_token      = null
  }
}

variable "ee_pkg" {
  description = "(Optional) Filename of the Enterprise Edition package"
  type        = string
  default     = "kong-enterprise-edition_2.3.2.0_all.deb"
}

variable "enable_monitoring" {
  description = "(Optional) Should monitoring be enabled on the instances"
  type        = bool
  default     = true
}

variable "encrypt_storage" {
  description = "(Optional) true/false value to set whether storage within the RDS Database should be encrypted"
  type        = bool
  default     = true
}

variable "environment" {
  description = "(Optional) Resource environment tag (i.e. dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "force_delete" {
  description = "(Optional) Allows deleting the Auto Scaling Group without waiting for all instances in the pool to terminate"
  type        = bool
  default     = false
}

variable "health_check_grace_period" {
  description = "(Optional) Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "(Optional) EC2 or ELB. Controls how health checking is done"
  type        = string
  default     = "EC2"
}

variable "instance_type" {
  description = "(Optional) The instance type to use for the kong deployments"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "(Optional) The name of the aws key pair to use with the deployment"
  type        = string
  default     = null
}

variable "kong_clear_database" {
  description = "(Optional) If set to true then the database contents will be replaced when control plane instance starts. Typically only used during development."
  type        = bool
  default     = false
}

variable "kong_config" {
  description = "(Optional) A map of key value pairs that describe the Kong GW config, used when constructing the userdata script"
  type        = map(string)
  default     = {}
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

variable "kong_hybrid_conf" {
  description = "(Optional) An object defining the kong http ports"
  type = object({
    server_name  = string
    cluster_cert = string
    cluster_key  = string
    mtls         = string
    ca_cert      = string
    endpoint     = string
  })
  default = {
    server_name  = ""
    cluster_cert = ""
    cluster_key  = ""
    mtls         = "shared"
    ca_cert      = ""
    endpoint     = ""
  }
}

variable "kong_ports" {
  description = "(Optional) An object defining the kong http ports"
  type = object({
    proxy      = number
    admin_api  = number
    admin_gui  = number
    portal_gui = number
    portal_api = number
    cluster    = number
    telemetry  = number
  })
  default = {
    proxy      = 8000
    admin_api  = 8001
    admin_gui  = 8002
    portal_gui = 8003
    portal_api = 8004
    cluster    = 8005
    telemetry  = 8006
  }
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
  default = {
    protocol            = "http"
    admin_api_uri       = "http://localhost:8001"
    admin_gui_url       = "http://localhost:8002"
    portal_gui_host     = "http://localhost:8003"
    portal_api_url      = "http://localhost:8004"
    portal_cors_origins = null
  }
}

variable "manager_host" {
  description = "(Optional) The host address or name to access kong manager"
  type        = string
  default     = ""
}

variable "placement_tenancy" {
  description = "(Optional) TODO"
  type        = string
  default     = "default"
}

variable "portal_host" {
  description = "(Optional) The host address or name to access kong developer portal"
  type        = string
  default     = ""
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

variable "proxy_config" {
  description = "(Optional) Configure HTTP, HTTPS, and NO_PROXY"
  type = object({
    http_proxy  = string
    https_proxy = string
    no_proxy    = string
  })
  default = {
    http_proxy  = null
    https_proxy = null
    no_proxy    = null
  }
}

variable "root_block_size" {
  description = "(Optional) The size of the root block device to attach to each instance"
  type        = number
  default     = 20
}

variable "root_block_type" {
  description = "(Optional) The type of root block device to add"
  type        = string
  default     = "gp2"
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
    "kong-ingress-proxy-http" = {
      type        = "ingress",
      from_port   = 8000,
      to_port     = 8000,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-api-http" = {
      type        = "ingress",
      from_port   = 8001,
      to_port     = 8001,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-manager-http" = {
      type        = "ingress",
      from_port   = 8002,
      to_port     = 8002,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-portal-gui-http" = {
      type        = "ingress",
      from_port   = 8003,
      to_port     = 8003,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-ingress-portal-http" = {
      type        = "ingress",
      from_port   = 8004,
      to_port     = 8004,
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
    "kong-egress-8000" = {
      type        = "egress",
      from_port   = 8000,
      to_port     = 8000,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-8001" = {
      type        = "egress",
      from_port   = 8001,
      to_port     = 8001,
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

variable "security_group_ids" {
  description = "(Optional) A list of security group ID's to associate with the instances"
  type        = list(string)
  default     = []
}

variable "service" {
  description = "(Optional) Resource service tag"
  type        = string
  default     = "kong"
}

variable "skip_final_snapshot" {
  description = "(Optional) true/false value to set whether a final RDS Database snapshot should be taken when RDS resource is destroyed"
  type        = bool
  default     = true
}

variable "skip_rds_creation" {
  description = "(Optional) If set to true then this module will not create its own rds instance"
  type        = bool
  default     = false
}

variable "tags" {
  description = "(Optional) Tags to apply to aws resources"
  type        = map(string)
  default     = {}
}

variable "target_group_arns" {
  description = "(Optional) A list of target groups to associate with the kong asg"
  type        = list(string)
  default     = []
}
