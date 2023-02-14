# kics-scan disable=1e434b25-8763-4b00-a5ca-ca03b7abbb66
# The above line disables rule "Name Is Not Snake Case" in KICS

### required Variables
variable "deployment_type" {
  type        = string
  description = "Define the deployment type of either `ec2` or `ecs`"

  validation {
    condition     = contains(["ec2", "ecs"], var.deployment_type)
    error_message = "Invalid value - please choose ec2 or ecs."
  }
}

variable "ami_id" {
  description = "(Optional) AMI image id to use for the deployments"
  type        = string
  default     = null
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
  description = "(Optional) The name of an IAM instance profile to apply to this deployment"
  type        = string
  default     = null
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
  default     = "kong_2.3.2_amd64.deb"
}

variable "deck_version" {
  description = "(Optional) The version of deck to install"
  type        = string
  default     = "1.0.0"
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

# kics-scan ignore-block
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

variable "user_data" {
  description = "(Optional) The user data to provide when launching the instance. N.B if set, this will override the user_data provided by this module"
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

# kics-scan ignore-block
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
  type        = map(number)
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

# kics-scan ignore-block
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
  description = "(Optional) Security rules for the Kong instance that have a Prefix List ID as their Source"
  type = map(object({
    type           = string,
    from_port      = number,
    to_port        = number,
    protocol       = string,
    prefix_list_id = list(string),
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
  description = "(Optional) If set to true then this module will not create its own RDS instance"
  type        = bool
  default     = false
}

variable "tags" {
  description = "(Optional) Tags to apply to AWS resources, except Auto Scaling Group"
  type        = map(string)
  default     = {}
}

variable "tags_asg" {
  description = "(Optional) Tags to apply to Auto Scaling Group resources"
  type        = map(string)
  default     = {}
}

variable "target_group_arns" {
  description = "(Optional) A list of target groups to associate with the Kong ASG"
  type        = list(string)
  default     = []
}

variable "desired_capacity" {
  description = "(Optional) The number of Amazon EC2 instances that should be running in the group"
  type        = number
  default     = 1
}

variable "min_healthy_percentage" {
  description = "(Optional) The minimum percentage of healthy instances in Auto Scaling Group during instance refresh"
  type        = number
  default     = 30
}

variable "role" {
  description = "(Optional) Role of the Kong Task"
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "(Optional) Common name. Used as security_group name prefix and `Name` tag"
  type        = string
  default     = "kong-security-group"
}

## ECS

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

variable "enable_execute_command" {
  description = "(Optional) Define whether to enable Amazon ECS Exec for tasks within the service."
  type        = bool
  default     = true
}

variable "platform_version" {
  description = "(Optional) ECS Service platform version"
  type        = string
  default     = "1.4.0"
}

variable "ssl_cert" {
  description = "(Optional) Secrets Manager or Parameter Store ARN of the Certificate used to secure traffic to the gateway"
  type        = string
  default     = null
}

variable "ssl_key" {
  description = "(Optional) Secrets Manager or Parameter Store ARN of the Key used to secure traffic to the gateway"
  type        = string
  default     = null
}

variable "lua_ssl_cert" {
  description = "(Optional) Secrets Manager or Parameter Store ARN of the Certificate used for Lua cosockets"
  type        = string
  default     = null
}

variable "kong_cluster_mtls" {
  description = "Define what type of Cluster mTLS is required - either 'shared' or 'pki'."
  type        = string
  default     = "shared"

  validation {
    condition     = contains(["pki", "shared"], var.kong_cluster_mtls)
    error_message = "Invalid value - please choose pki or shared."
  }
}

variable "cluster_ca_cert" {
  description = "Secrets Manager or Parameter Store ARN of the Clustering Certificate Authority"
  type        = string
  default     = null
}

variable "cluster_cert" {
  description = "(Optional) Secrets Manager or Parameter Store ARN of the Clustering Certificate"
  type        = string
  default     = null
}

variable "cluster_key" {
  description = "(Optional) Secrets Manager or Parameter Store ARN of the Clustering Key"
  type        = string
  default     = null
}

variable "kong_log_level" {
  description = "(Optional) Level of log output for the Gateway"
  type        = string
  default     = "warn"
}

variable "access_log_format" {
  description = "(Optional) Log location and format to be defined for the access logs"
  type        = string
  default     = "logs/access.log"
}

variable "error_log_format" {
  description = "(Optional) Log location and format to be defined for the error logs"
  type        = string
  default     = "logs/error.log"
}

variable "nginx_custom_config_path" {
  description = "(Optional) Custom NGINX Config that is included in the main configuration through the variable KONG_NGINX_HTTP_INCLUDE"
  type        = string
  default     = null
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

variable "image_url" {
  description = "(Optional) The URL where the Docker image resides"
  type        = string
  default     = null
}

variable "ecs_target_group_arns" {
  description = "(Optional) Target Group ARNs for the ECS Service"
  type        = map(string)
  default     = null
}

variable "execution_role_arn" {
  type        = string
  description = "(Optional) ARN of the Task Execution Role"
  default     = null
}

variable "ecs_cluster_arn" {
  type        = string
  description = "(Optional) The ARN of the ECS Cluster created"
  default     = null
}

variable "ecs_cluster_name" {
  type        = string
  description = "(Optional) The ARN of the ECS Cluster created"
  default     = null
}

variable "db_password_arn" {
  description = "(Optional) The DB Password ARN that is used by the ECS Task Definition"
  type        = string
  default     = null
}

variable "log_group" {
  description = "(Optional) The Log Group for ECS to report out to"
  type        = string
  default     = null
}

variable "kong_admin_gui_session_conf" {
  description = "(Optional) The session configuration that Kong will use"
  type        = string
  default     = null
}

variable "clustering_endpoint" {
  type        = string
  description = "(Optional) Address of the control plane node from which configuration updates will be fetched"
  default     = null
}

variable "telemetry_endpoint" {
  type        = string
  description = "(Optional) Telemetry address of the control plane node to which telemetry updates will be posted"
  default     = ""
}

variable "cluster_server_name" {
  type        = string
  description = "(Optional) The server name used in the SNI of the TLS connection from a DP node to a CP node"
  default     = ""
}

variable "admin_token" {
  type        = string
  description = "(Optional) The ARN of the admin token to be used within the ECS Task Definition."
  default     = null
}

variable "kong_admin_api_uri" {
  description = "(Optional) The Admin API URI composed of a host, port and path on which the Admin API accepts traffic."
  type        = string
  default     = ""
}

variable "kong_admin_gui_url" {
  description = "(Optional) The Admin GUI URL of the Kong Manager."
  type        = string
  default     = ""
}

variable "entrypoint" {
  description = "(Optional) The entrypoint for the Docker container. Set this to override the default behaviour."
  type        = string
  default     = null
}

variable "kong_vitals_enabled" {
  description = "(Optional) Define whether or not Kong Vitals should be enabled."
  type        = string
  default     = "on"
}

variable "kong_portal_enabled" {
  description = "(Optional) Define whether or not the Kong Portal should be enabled."
  type        = string
  default     = "on"
}

variable "kong_portal_gui_host" {
  description = "(Optional) The Hostname used for the Portal GUI."
  type        = string
  default     = ""
}

variable "kong_portal_gui_protocol" {
  description = "(Optional) The protocol used for the portal GUI."
  type        = string
  default     = ""
}

variable "kong_portal_api_url" {
  description = "(Optional) The Portal API URL of the Portal."
  type        = string
  default     = ""
}

variable "vitals_endpoint" {
  description = "(Optional) The DNS name for the Vitals endpoint that Gateways should send their metrics to"
  type = object({
    fqdn     = string
    port     = number
    protocol = string
  })
  default = null
}

variable "kong_plugins" {
  description = "(Optional) List of Kong plugins, passed through the variable KONG_PLUGINS"
  type        = list(string)
  default     = []
}
