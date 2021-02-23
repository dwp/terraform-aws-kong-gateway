locals {

  user_data = templatefile("${path.module}/templates/cloud_init.cfg", {})

  user_data_script = templatefile("${path.module}/templates/cloud_init.sh", {
    DB_USER        = var.kong_database_user
    CE_PKG         = var.ce_pkg
    EE_PKG         = var.ee_pkg
    PARAMETER_PATH = var.ssm_parameter_path
    REGION         = var.region
    VPC_CIDR_BLOCK = var.vpc_cidr_block
    DECK_VERSION   = var.deck_version
    MANAGER_HOST   = var.manager_host
    PORTAL_HOST    = var.portal_host
    SESSION_SECRET = random_string.session_secret.result
    KONG_CONFIG    = var.kong_config
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

resource "aws_launch_configuration" "kong" {
  name_prefix          = format("%s-%s-", var.service, var.environment)
  image_id             = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.iam_instance_profile_name
  key_name             = var.key_name

  security_groups = var.security_group_ids

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
}

resource "aws_autoscaling_group" "kong" {
  name                = format("%s-%s", var.service, var.environment)
  vpc_zone_identifier = data.aws_subnet_ids.private.ids

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
