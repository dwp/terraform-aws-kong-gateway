provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

resource "aws_subnet" "public_subnets" {
  count                   = length(module.create_kong_asg.private_subnet_azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${4 + count.index}.0/24"
  availability_zone       = module.create_kong_asg.private_subnet_azs[count.index]
  map_public_ip_on_launch = true
}

locals {
  public_subnet_ids = aws_subnet.public_subnets.*.id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets.0.id
  depends_on    = [aws_internet_gateway.ig]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route_table_association" "public" {
  count          = length(local.public_subnet_ids)
  subnet_id      = element(local.public_subnet_ids, count.index)
  route_table_id = aws_route_table.public.id
}

module "create_kong_asg" {
  source                    = "../../"
  vpc_id                    = aws_vpc.vpc.id
  ami_id                    = data.aws_ami.ubuntu.id
  key_name                  = var.key_name
  region                    = var.region
  vpc_cidr_block            = aws_vpc.vpc.cidr_block
  environment               = var.environment
  service                   = var.service
  description               = var.description
  iam_instance_profile_name = aws_iam_instance_profile.kong.name
  asg_desired_capacity      = var.asg_desired_capacity

  postgres_config = {
    master_user     = var.postgres_master_user
    master_password = random_string.master_password.result
  }

  kong_database_config = {
    user     = var.kong_database_user
    name     = var.kong_database_name
    password = var.kong_database_password
  }

  target_group_arns = local.target_groups

  tags = var.tags
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = length(module.create_kong_asg.private_subnet_ids)
  subnet_id      = element(module.create_kong_asg.private_subnet_ids, count.index)
  route_table_id = aws_route_table.private.id
}
