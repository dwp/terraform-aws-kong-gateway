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
    cidr_blocks = list(string),
  }))
  default = {}
}

variable "rules_with_source_security_groups" {
  description = "Security rules for the Kong instance that have another security group for their source"
  type = map(object({
    type                     = string,
    from_port                = number,
    to_port                  = number,
    protocol                 = string,
    source_security_group_id = string,
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

variable "name" {
  description = "(Optional) Common name. Used as security_group name prefix and `Name` tag"
  type        = string
  default     = "kong-security-group"
}
