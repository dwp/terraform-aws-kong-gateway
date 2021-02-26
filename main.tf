locals {
  create_private_subnets = length(var.private_subnets) > 0 ? 0 : 1
  create_security_groups = length(var.security_group_ids) > 0 ? 0 : 1
  create_postgres        = 0 # var.postgresql_host != "" ? 0 : 1

  db_info = var.postgresql_host != "" ? {
    endpoint      = var.postgresql_host
    database_name = var.kong_database_name
    } : {
    endpoint      = module.database.0.outputs.endpoint,
    database_name = module.database.0.outputs.database_name
  }

  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : module.security_groups.0.ids
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : module.private_subnets.0.ids

  azs = length(var.availability_zones) > 0 ? var.availability_zones : module.private_subnets.0.azs

  ssm_parameter_path = format("/%s/%s", var.service, var.environment)

  vpc_object = {
    id      = var.vpc_id
    subnets = local.private_subnets
    azs     = local.azs
  }

  user_data = templatefile("${path.module}/templates/cloud-init.cfg", {})
  user_data_script = templatefile("${path.module}/templates/cloud-init.sh", {
    DB_USER        = var.kong_database_user
    DB_HOST        = local.db_info.endpoint
    DB_NAME        = local.db_info.database_name
    CE_PKG         = var.ce_pkg
    EE_PKG         = var.ee_pkg
    PARAMETER_PATH = local.ssm_parameter_path
    REGION         = var.region
    VPC_CIDR_BLOCK = var.vpc_cidr_block
    DECK_VERSION   = var.deck_version
    MANAGER_HOST   = var.manager_host
    PORTAL_HOST    = var.portal_host
    SESSION_SECRET = random_string.session_secret.result
    KONG_CONFIG    = var.kong_config
  })
}

module "security_groups" {
  count                             = local.create_security_groups
  source                            = "./modules/security_groups"
  vpc_id                            = var.vpc_id
  rules_with_source_cidr_blocks     = var.rules_with_source_cidr_blocks
  rules_with_source_security_groups = var.rules_with_source_security_groups
  tags                              = var.tags
}

module "private_subnets" {
  count             = local.create_private_subnets
  source            = "./modules/subnets"
  vpc_id            = var.vpc_id
  region            = var.region
  subnets_to_create = var.private_subnets_to_create
  tags              = var.tags
}

module "database" {
  count                   = var.skip_rds ? 0 : 1
  source                  = "./modules/database"
  name                    = var.kong_database_name
  vpc                     = local.vpc_object
  allowed_security_groups = local.security_groups
  database_credentials = { # FIXME: secretes_manager
    username = var.postgresql_master_user
    password = var.postgresql_master_password
  }
  tags = var.tags
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

resource "aws_launch_configuration" "kong" {
  name_prefix          = format("%s-%s-", var.service, var.environment)
  image_id             = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile_name
  key_name             = var.key_name

  security_groups = local.security_groups

  associate_public_ip_address = false
  enable_monitoring           = true
  placement_tenancy           = "default"
  user_data                   = data.template_cloudinit_config.cloud-init.rendered

  root_block_device {
    volume_size = var.ec2_root_volume_size
    volume_type = var.ec2_root_volume_type
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [module.database]
}

resource "aws_autoscaling_group" "kong" {
  name                = format("%s-%s", var.service, var.environment)
  vpc_zone_identifier = local.private_subnets

  launch_configuration = aws_launch_configuration.kong.name

  desired_capacity          = var.asg_desired_capacity
  force_delete              = false
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = "ELB"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size

  tag {
    key                 = "Name"
    value               = format("%s-%s", var.service, var.environment)
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "Description"
    value               = var.description
    propagate_at_launch = true
  }
  tag {
    key                 = "Service"
    value               = var.service
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.additional_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "random_string" "session_secret" {
  length  = 32
  special = false
}
