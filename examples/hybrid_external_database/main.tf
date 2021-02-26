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

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow postgres inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "postgresql from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "TCP"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    description = "postgresql from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
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
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

locals {
  user_data = templatefile("${path.module}/templates/cloud-init.cfg", {})
  user_data_script = templatefile("${path.module}/templates/cloud-init.sh", {
    db_master_pass = random_string.master_password.result
    db_master_user = var.postgresql_master_user
  })
}

data "template_cloudinit_config" "cloud-init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = local.user_data
  }

  part {
    content_type = "text/x-shellscript"
    content      = local.user_data_script
  }
}

resource "aws_instance" "external_postgres" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_postgres.id]
  user_data              = data.template_cloudinit_config.cloud-init.rendered
  tags                   = var.tags
}

module "create_kong_asg" {
  source                     = "../../"
  vpc_id                     = aws_vpc.vpc.id
  ami_id                     = data.aws_ami.ubuntu.id
  key_name                   = var.key_name
  region                     = var.region
  vpc_cidr_block             = aws_vpc.vpc.cidr_block
  environment                = var.environment
  service                    = var.service
  description                = var.description
  iam_instance_profile_name  = aws_iam_instance_profile.kong.name
  asg_desired_capacity       = var.asg_desired_capacity
  postgresql_master_user     = var.postgresql_master_user
  postgresql_master_password = random_string.master_password.result
  postgresql_host            = aws_instance.external_postgres.private_ip
  kong_database_user         = var.kong_database_user
  kong_database_name         = var.kong_database_name
  kong_database_password     = var.kong_database_password
  skip_rds                   = true
  tags                       = var.tags
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
