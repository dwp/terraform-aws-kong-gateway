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

resource "aws_subnet" "public_subnets" {
  count                   = length(module.create_kong_cp.private_subnet_azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${4 + count.index}.0/24"
  availability_zone       = module.create_kong_cp.private_subnet_azs[count.index]
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

locals {
  user_data = templatefile("${path.module}/templates/cloud-init.cfg", {})
  user_data_script = templatefile("${path.module}/templates/cloud-init.sh", {
    db_master_pass = random_string.master_password.result
    db_master_user = var.postgres_master_user
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
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnets.0.id
  vpc_security_group_ids = [aws_security_group.allow_postgres.id]
  user_data              = data.template_cloudinit_config.cloud-init.rendered
  tags                   = var.tags
}

locals {
  environment = "${var.environment}-${terraform.workspace}"

  kong_control_plane_config = {
    "KONG_ROLE"              = "control_plane"
    "KONG_PROXY_LISTEN"      = "off"
    "KONG_ANONYMOUS_REPORTS" = "off"
    "KONG_PORTAL"            = "on"
    "KONG_VITALS"            = "on"
    "KONG_AUDIT_LOG"         = "on"
    "KONG_LOG_LEVEL"         = "debug"
  }

  kong_data_plane_config = {
    "KONG_ROLE"              = "data_plane"
    "KONG_DATABASE"          = "off"
    "KONG_LOG_LEVEL"         = "debug"
    "KONG_ANONYMOUS_REPORTS" = "off"
  }

  kong_hybrid_conf = {
    cluster_cert = tls_locally_signed_cert.cert.cert_pem
    cluster_key  = tls_private_key.cert.private_key_pem
    endpoint     = aws_lb.internal.dns_name
  }
}

module "create_kong_cp" {
  source = "../../"

  instance_type             = var.instance_type
  vpc_id                    = aws_vpc.vpc.id
  ami_id                    = data.aws_ami.ubuntu.id
  key_name                  = var.key_name
  region                    = var.region
  vpc_cidr_block            = aws_vpc.vpc.cidr_block
  iam_instance_profile_name = aws_iam_instance_profile.kong.name

  ee_creds_ssm_param = {
    license      = aws_ssm_parameter.ee-license.name
    bintray_auth = aws_ssm_parameter.ee-bintray-auth.name
    admin_token  = aws_ssm_parameter.ee-admin-token.name
  }

  asg_desired_capacity = var.asg_desired_capacity
  asg_max_size         = var.asg_max_size
  asg_min_size         = var.asg_min_size

  postgres_config = {
    master_user     = var.postgres_master_user
    master_password = random_string.master_password.result
  }

  postgres_host = aws_instance.external_postgres.private_ip

  kong_database_config = {
    user     = var.kong_database_user
    name     = var.kong_database_name
    password = var.kong_database_password
  }

  target_group_arns = local.target_group_cp

  skip_rds_creation = true
  kong_config       = local.kong_control_plane_config
  kong_hybrid_conf  = local.kong_hybrid_conf

  environment = local.environment
  service     = var.service
  description = var.description
  tags        = var.tags
}

module "create_kong_dp" {
  source = "../../"

  instance_type  = var.instance_type
  vpc_id         = aws_vpc.vpc.id
  ami_id         = data.aws_ami.ubuntu.id
  key_name       = var.key_name
  region         = var.region
  vpc_cidr_block = aws_vpc.vpc.cidr_block

  iam_instance_profile_name = aws_iam_instance_profile.kong.name


  asg_desired_capacity = var.asg_desired_capacity
  asg_max_size         = var.asg_max_size
  asg_min_size         = var.asg_min_size

  target_group_arns = local.target_group_dp

  skip_rds_creation = true
  kong_config       = local.kong_data_plane_config
  kong_hybrid_conf  = local.kong_hybrid_conf

  private_subnets    = module.create_kong_cp.private_subnet_ids
  availability_zones = module.create_kong_cp.private_subnet_azs

  environment = local.environment
  service     = var.service
  description = var.description
  tags        = var.tags
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
  count          = length(module.create_kong_cp.private_subnet_ids)
  subnet_id      = element(module.create_kong_cp.private_subnet_ids, count.index)
  route_table_id = aws_route_table.private.id
}
