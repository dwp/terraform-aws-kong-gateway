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
    db_pass        = var.kong_database_password
    db_user        = var.kong_database_user
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

module "create_kong_cp" {
  source = "../../"

  deployment_type  = "ecs"
  role             = "control_plane"
  ecs_cluster_arn  = aws_ecs_cluster.kong.arn
  ecs_cluster_name = aws_ecs_cluster.kong.name
  vpc_id           = aws_vpc.vpc.id
  region           = var.region
  vpc_cidr_block   = aws_vpc.vpc.cidr_block

  db_password_arn = aws_ssm_parameter.db_password.arn

  ssl_cert     = aws_ssm_parameter.cert.arn
  ssl_key      = aws_ssm_parameter.key.arn
  lua_ssl_cert = aws_ssm_parameter.cert.arn

  cluster_cert = aws_ssm_parameter.cert.arn
  cluster_key  = aws_ssm_parameter.key.arn

  admin_token = aws_ssm_parameter.ee-admin-token.arn

  kong_admin_gui_session_conf = aws_ssm_parameter.session_conf.arn

  kong_log_level = "debug"

  entrypoint = "/management-plane-entrypoint.sh"

  desired_count = var.desired_capacity
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  log_group = aws_cloudwatch_log_group.kong_cp.name

  kong_admin_api_uri = "${aws_lb.external.dns_name}:8001"
  kong_admin_gui_url = "http://${aws_lb.external.dns_name}:8002"

  access_log_format = var.access_log_format
  error_log_format  = var.error_log_format

  cluster_server_name = aws_lb.external.dns_name

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

  ecs_target_group_arns = local.target_group_cp

  skip_rds_creation = true

  environment = local.environment
  service     = var.service
  description = var.description
  tags        = var.tags
}

module "create_kong_portal" {
  source = "../../"

  deployment_type  = "ecs"
  role             = "portal"
  ecs_cluster_arn  = aws_ecs_cluster.kong.arn
  ecs_cluster_name = aws_ecs_cluster.kong.name
  instance_type    = var.instance_type
  vpc_id           = aws_vpc.vpc.id
  region           = var.region
  vpc_cidr_block   = aws_vpc.vpc.cidr_block

  db_password_arn = aws_ssm_parameter.db_password.arn

  ssl_cert     = aws_ssm_parameter.cert.arn
  ssl_key      = aws_ssm_parameter.key.arn
  lua_ssl_cert = aws_ssm_parameter.cert.arn

  cluster_cert = aws_ssm_parameter.cert.arn
  cluster_key  = aws_ssm_parameter.key.arn

  kong_log_level = "debug"

  entrypoint = "/portal-entrypoint.sh"

  desired_count = var.desired_capacity
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  log_group = aws_cloudwatch_log_group.kong_portal.name

  kong_portal_gui_host     = "${aws_lb.external.dns_name}:8003"
  kong_portal_api_url      = "http://${aws_lb.external.dns_name}:8004"
  kong_portal_gui_protocol = "http"

  access_log_format = var.access_log_format
  error_log_format  = var.error_log_format

  cluster_server_name = aws_lb.external.dns_name

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

  private_subnets    = module.create_kong_cp.private_subnet_ids
  availability_zones = module.create_kong_cp.private_subnet_azs

  image_url = var.image_url

  ecs_target_group_arns = local.target_group_portal

  skip_rds_creation = true

  environment = local.environment
  service     = var.service
  description = var.description
  tags        = var.tags
}

module "create_kong_dp" {
  source = "../../"

  deployment_type  = "ecs"
  role             = "data_plane"
  ecs_cluster_arn  = aws_ecs_cluster.kong.arn
  ecs_cluster_name = aws_ecs_cluster.kong.name
  vpc_id           = aws_vpc.vpc.id
  region           = var.region
  vpc_cidr_block   = aws_vpc.vpc.cidr_block

  ssl_cert     = aws_ssm_parameter.cert.arn
  ssl_key      = aws_ssm_parameter.key.arn
  lua_ssl_cert = aws_ssm_parameter.cert.arn

  cluster_cert = aws_ssm_parameter.cert.arn
  cluster_key  = aws_ssm_parameter.key.arn

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  # DP Specific
  clustering_endpoint = "${aws_lb.internal.dns_name}:8005"
  telemetry_endpoint  = "${aws_lb.internal.dns_name}:8006"

  desired_count = var.desired_capacity
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  log_group         = aws_cloudwatch_log_group.kong_dp.name
  access_log_format = var.access_log_format
  error_log_format  = var.error_log_format
  custom_nginx_conf = var.custom_nginx_conf
  kong_log_level    = "debug"

  entrypoint = "/gateway-entrypoint.sh"

  rules_with_source_cidr_blocks = var.rules_with_source_cidr_blocks

  image_url = var.image_url

  ecs_target_group_arns = local.target_group_dp
  skip_rds_creation     = true

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
