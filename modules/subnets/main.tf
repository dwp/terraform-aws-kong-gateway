data "aws_availability_zones" "default" {
  state = "available"
}

locals {
  default_az = data.aws_availability_zones.default.names
  subnets = [
    for s in var.subnets_to_create :
    {
      cidr_block = s.cidr_block,
      az         = s.az == "default" ? local.default_az[index(var.subnets_to_create, s)] : s.az
      public     = s.public
    }
  ]
}

resource "aws_subnet" "subnet" {
  for_each                = { for s in local.subnets : s.cidr_block => s }
  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public
  tags                    = merge(var.tags, { Name = "Private Subnet" })
}
