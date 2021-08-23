locals {
  create_private_subnets = length(var.private_subnets) > 0 ? 0 : 1
  create_security_groups = length(var.security_group_ids) > 0 ? 0 : 1

  role = var.role != null ? var.role : lookup(var.kong_config, "KONG_ROLE", "embedded")

  # If the module user has specified a postgres_host then we use
  # that as our endpoint, as we will not be triggering the database module
  db_info = var.postgres_host != "" ? {
    endpoint      = var.postgres_host
    database_name = var.kong_database_config.name
    } : {
    endpoint      = local.role == "data_plane" ? "" : module.database.0.outputs.endpoint,
    database_name = local.role == "data_plane" ? "" : module.database.0.outputs.database_name
  }

  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : module.security_groups.0.ids
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : module.private_subnets.0.ids
  database = var.skip_rds_creation ? null : {
    endpoint          = module.database.0.outputs.endpoint
    database_name     = module.database.0.outputs.database_name
    security_group_id = module.database.0.outputs.security_group_id
  }

  azs = length(var.availability_zones) > 0 ? var.availability_zones : module.private_subnets.0.azs

  ssm_parameter_path = format("/%s/%s", var.service, var.environment)

  vpc_object = {
    id      = var.vpc_id
    subnets = local.private_subnets
    azs     = local.azs
  }

  user_data = {
    amazon-linux = templatefile("${path.module}/templates/amazon-linux/cloud-init.cfg", {})
    ubuntu       = templatefile("${path.module}/templates/ubuntu/cloud-init.cfg", {})
  }
  user_data_script = {
    amazon-linux = templatefile("${path.module}/templates/amazon-linux/cloud-init.sh", {
      proxy_config       = var.proxy_config
      db_user            = var.kong_database_config.user
      db_host            = local.db_info.endpoint
      db_name            = local.db_info.database_name
      ce_pkg             = var.ce_pkg
      ee_pkg             = var.ee_pkg
      ee_creds_ssm_param = var.ee_creds_ssm_param
      parameter_path     = local.ssm_parameter_path
      region             = var.region
      vpc_cidr_block     = var.vpc_cidr_block
      deck_version       = var.deck_version
      manager_host       = var.manager_host
      portal_host        = var.portal_host
      session_secret     = random_string.session_secret.result
      kong_config        = var.kong_config
      kong_ports         = var.kong_ports
      kong_ssl_uris      = var.kong_ssl_uris
      kong_hybrid_conf   = var.kong_hybrid_conf
      clear_database     = var.kong_clear_database
    })
    ubuntu = templatefile("${path.module}/templates/ubuntu/cloud-init.sh", {
      proxy_config       = var.proxy_config
      db_user            = var.kong_database_config.user
      db_host            = local.db_info.endpoint
      db_name            = local.db_info.database_name
      ce_pkg             = var.ce_pkg
      ee_pkg             = var.ee_pkg
      ee_creds_ssm_param = var.ee_creds_ssm_param
      parameter_path     = local.ssm_parameter_path
      region             = var.region
      vpc_cidr_block     = var.vpc_cidr_block
      deck_version       = var.deck_version
      manager_host       = var.manager_host
      portal_host        = var.portal_host
      session_secret     = random_string.session_secret.result
      kong_config        = var.kong_config
      kong_ports         = var.kong_ports
      kong_ssl_uris      = var.kong_ssl_uris
      kong_hybrid_conf   = var.kong_hybrid_conf
      clear_database     = var.kong_clear_database
    })
  }

  name = format("%s-%s-%s", var.service, var.environment, local.role)
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
  count                   = var.skip_rds_creation ? 0 : 1
  source                  = "./modules/database"
  name                    = var.kong_database_config.name
  environment             = var.environment
  vpc                     = local.vpc_object
  allowed_security_groups = local.security_groups
  skip_final_snapshot     = var.skip_final_snapshot
  encrypt_storage         = var.encrypt_storage
  database_credentials = { # FIXME: secretes_manager
    username = var.postgres_config.master_user
    password = var.postgres_config.master_password
  }
  tags = var.tags
}

data "template_cloudinit_config" "cloud_init" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = local.user_data[var.ami_operating_system]
  }

  part {
    content_type = "text/x-shellscript"
    content      = local.user_data_script[var.ami_operating_system]
  }
}

resource "aws_launch_configuration" "kong" {
  name_prefix          = local.name
  image_id             = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile_name
  key_name             = var.key_name

  security_groups = local.security_groups

  associate_public_ip_address = false
  enable_monitoring           = true
  placement_tenancy           = "default"
  user_data                   = var.user_data == null ? data.template_cloudinit_config.cloud_init.rendered : var.user_data

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
  name                = local.name
  vpc_zone_identifier = local.private_subnets

  launch_configuration = aws_launch_configuration.kong.name

  desired_capacity          = var.asg_desired_capacity
  force_delete              = false
  health_check_grace_period = var.asg_health_check_grace_period
  health_check_type         = "ELB"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  target_group_arns         = var.target_group_arns

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.min_healthy_percentage
    }
  }

  dynamic "tag" {
    for_each = var.tags_asg
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
