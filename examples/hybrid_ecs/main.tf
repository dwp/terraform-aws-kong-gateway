provider "aws" {
  region = var.region
}



# Used for supporting infra
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

resource "aws_security_group" "allow_proxy" {
  name        = "allow_proxy"
  description = "Allow proxy inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "proxy from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
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
  user_data = templatefile("${path.module}/templates/db/cloud-init.cfg", {})
  user_data_script = templatefile("${path.module}/templates/db/cloud-init.sh", {
    db_master_pass = random_string.master_password.result
    db_master_user = var.postgres_master_user
    db_pass = var.kong_database_password
    db_user = var.kong_database_user
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

data "template_cloudinit_config" "proxy_cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/proxy/cloud-init.cfg", {})
  }

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/proxy/cloud-init.sh", {})
  }
}

resource "aws_instance" "external_proxy" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.small"
  key_name               = var.key_name
  subnet_id              = aws_subnet.public_subnets.0.id
  vpc_security_group_ids = [aws_security_group.allow_proxy.id]
  user_data              = data.template_cloudinit_config.proxy_cloud_init.rendered
  tags                   = merge({ Name = "proxy" }, var.tags)
}

locals {
  environment = "${var.environment}-${terraform.workspace}"
}

resource "aws_cloudwatch_log_group" "kong_dp" {
  name              = "${var.environment}-dp"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-dp"
  }
}

# resource "aws_cloudwatch_log_group" "kong_cp" {
#   name              = "${var.environment}-cp"
#   retention_in_days = 7

#   tags = {
#     Name = "${var.environment}-cp"
#   }
# }

module "create_kong_cp" {
  source = "../../"

  deployment_type  = "ecs"
  ecs_cluster_arn  = aws_ecs_cluster.kong.arn
  ecs_cluster_name = aws_ecs_cluster.kong.name
  instance_type    = var.instance_type
  vpc_id           = aws_vpc.vpc.id
  region           = var.region
  vpc_cidr_block   = aws_vpc.vpc.cidr_block

  db_password_arn        = aws_ssm_parameter.db_password.arn
  db_master_password_arn = aws_ssm_parameter.db_master_password.arn

  ssl_cert     = aws_ssm_parameter.cert.arn
  ssl_key      = aws_ssm_parameter.key.arn
  lua_ssl_cert = aws_ssm_parameter.cert.arn

  cluster_cert = aws_ssm_parameter.cert.arn
  cluster_key  = aws_ssm_parameter.key.arn

  session_secret   = random_string.session_secret.result

  kong_log_level = "debug" # TBD

  desired_count = var.desired_capacity
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  log_group = aws_cloudwatch_log_group.kong_dp.name

  access_log_format = var.access_log_format
  error_log_format  = var.error_log_format

  custom_nginx_conf = var.custom_nginx_conf

  rules_with_source_cidr_blocks = var.rules_with_source_cidr_blocks

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

  image_url = var.image_url

  lb_target_group_arn = aws_lb_target_group.external-admin-api.arn

  skip_rds_creation = true
  template_file     = "control_plane"

  environment = local.environment
  service     = var.service
  description = var.description
  tags        = var.tags
}

# module "create_kong_dp" {
#   source = "../../"

#   deployment_type  = "ecs"
#   ecs_cluster_arn  = aws_ecs_cluster.kong.arn
#   ecs_cluster_name = aws_ecs_cluster.kong.name
#   instance_type    = var.instance_type
#   vpc_id           = aws_vpc.vpc.id
#   region           = var.region
#   vpc_cidr_block   = aws_vpc.vpc.cidr_block

#   ssl_cert     = aws_ssm_parameter.cert.arn
#   ssl_key      = aws_ssm_parameter.key.arn
#   lua_ssl_cert = aws_ssm_parameter.cert.arn

#   cluster_cert = aws_ssm_parameter.cert.arn
#   cluster_key  = aws_ssm_parameter.key.arn

#   kong_log_level = "debug" # TBD

#   desired_count = var.desired_capacity
#   min_capacity  = var.min_capacity
#   max_capacity  = var.max_capacity

#   log_group = aws_cloudwatch_log_group.kong_dp.name

#   access_log_format = var.access_log_format
#   error_log_format  = var.error_log_format

#   custom_nginx_conf = var.custom_nginx_conf

#   rules_with_source_cidr_blocks = var.rules_with_source_cidr_blocks

#   image_url = var.image_url

#   lb_target_group_arn = aws_lb_target_group.external-admin-api.arn

#   skip_rds_creation = true
#   template_file     = "data_plane"

#   environment = local.environment
#   service     = var.service
#   description = var.description
#   tags        = var.tags
# }

# module "create_kong_dp" {
#   source = "../../"

#   deployment_type      = "ec2"
#   instance_type        = var.instance_type
#   vpc_id               = aws_vpc.vpc.id
#   ami_id               = data.aws_ami.amazon_linux_2.id
#   ami_operating_system = "amazon-linux"
#   ce_pkg               = "kong-2.3.2.aws.amd64.rpm"
#   key_name             = var.key_name
#   region               = var.region
#   vpc_cidr_block       = aws_vpc.vpc.cidr_block

#   iam_instance_profile_name = aws_iam_instance_profile.kong.name


#   asg_desired_capacity = var.asg_desired_capacity
#   asg_max_size         = var.asg_max_size
#   asg_min_size         = var.asg_min_size

#   proxy_config = {
#     http_proxy  = "http://${aws_instance.external_proxy.private_ip}:3128"
#     https_proxy = "http://${aws_instance.external_proxy.private_ip}:3128"
#     no_proxy    = "localhost,169.254.169.254,127.0.0.1"
#   }

#   rules_with_source_cidr_blocks = var.rules_with_source_cidr_blocks

#   target_group_arns = local.target_group_dp

#   skip_rds_creation = true
#   kong_config       = local.kong_data_plane_config
#   kong_hybrid_conf  = local.kong_hybrid_conf

#   private_subnets    = module.create_kong_cp.private_subnet_ids
#   availability_zones = module.create_kong_cp.private_subnet_azs

#   environment = local.environment
#   service     = var.service
#   description = var.description
#   tags        = var.tags
# }

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
