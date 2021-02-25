variable "vpc_id" {
  description = "The vpc to associate the security group to"
  type        = string
}

variable "tags" {
  description = "A map of key values to tag the security group with"
  type        = map(any)
  default     = {}
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
    "kong-egress-80" = {
      type        = "ingress",
      from_port   = 80,
      to_port     = 80,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    "kong-egress-443" = {
      type        = "ingress",
      from_port   = 443,
      to_port     = 443,
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
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
  default = {}
}
