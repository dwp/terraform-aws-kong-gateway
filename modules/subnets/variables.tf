variable "vpc_id" {
  description = "The vpc to associate the security group to"
  type        = string
}

variable "region" {
  description = "The AWS region we are deploying to"
  type        = string
}

variable "tags" {
  description = "A map of key values to tag the security group with"
  type        = map(any)
  default     = {}
}

variable "subnets_to_create" {
  description = "A map of subnet objects to create"
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
