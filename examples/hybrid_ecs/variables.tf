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
  description = "The name of an AWS ssh key pari to associate with the instances in the ASG"
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

variable "ee_license" {
  description = "kong enterprise license"
  type        = string
  default     = "placeholder"
}

variable "vpc_cidr_block" {
  description = "VPC cidr range"
  type        = string
}

variable "desired_capacity" {
  description = "The maximum size of the auto scale group"
  type        = string
  default     = 1
}

variable "min_capacity" {
  description = "The minimum size of the auto scale group"
  type        = string
  default     = 1
}

variable "max_capacity" {
  description = "The size of the autoscaling group"
  type        = string
  default     = 1
}

variable "postgres_master_user" {
  description = "The master user for postgresql"
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

variable "external_cidr_blocks" { default = ["0.0.0.0/0"] }

variable "tags" {
  type = map(string)
  default = {
    "Dept" = "Testing"
  }
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

variable "custom_nginx_conf" {
  description = "(Optional) Custom NGINX Config that is included in the main configuration through the variable KONG_NGINX_HTTP_INCLUDE"
  type        = string
  default     = "# No custom configuration required, can be ignored"
}

variable "image_url" {
  description = "URL Image"
  type        = string
}
