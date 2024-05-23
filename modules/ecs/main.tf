locals {
  create_private_subnets = length(var.private_subnets) > 0 ? 0 : 1
  create_security_groups = length(var.security_group_ids) > 0 ? 0 : 1

  db_info = {
    endpoint      = var.postgres_host
    database_name = var.kong_database_config.name
  }

  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : module.security_groups.0.ids
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : module.private_subnets.0.ids

  azs = length(var.availability_zones) > 0 ? var.availability_zones : module.private_subnets.0.azs

  vpc_object = {
    id      = var.vpc_id
    subnets = local.private_subnets
    azs     = local.azs
  }
  name = format("%s-%s-%s", var.service, substr(var.environment, 0, 24), var.role)
}

resource "aws_ecs_task_definition" "kong" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  task_role_arn            = aws_iam_role.kong_task_role.arn
  execution_role_arn       = var.execution_role_arn
  container_definitions = var.role == "control_plane" ? templatefile("${path.module}/../../templates/ecs/kong_control_plane.tpl",
    {
      name                        = local.name
      group_name                  = local.name
      cpu                         = var.fargate_cpu
      image_url                   = var.image_url
      memory                      = var.fargate_memory
      user                        = "kong"
      db_user                     = var.kong_database_config.user
      db_host                     = local.db_info.endpoint
      db_name                     = local.db_info.database_name
      db_password_arn             = var.db_password_arn
      kong_admin_gui_session_conf = var.kong_admin_gui_session_conf
      log_group                   = var.log_group
      admin_api_port              = var.kong_ports.admin_api
      admin_gui_port              = var.kong_ports.admin_gui
      status_port                 = var.kong_ports.status
      ports                       = jsonencode([for k, v in var.kong_ports : v])
      ulimits                     = jsonencode([4096])
      region                      = var.region
      access_log_format           = var.access_log_format
      error_log_format            = var.error_log_format
      ssl_cert                    = var.ssl_cert
      ssl_key                     = var.ssl_key
      api_uri_env_name            = var.kong_major_version > 2 ? "KONG_ADMIN_GUI_API_URL" : "KONG_ADMIN_API_URI"
      kong_admin_api_uri          = var.kong_admin_api_uri
      kong_admin_gui_url          = var.kong_admin_gui_url
      admin_token                 = var.admin_token
      kong_vitals_enabled         = var.kong_vitals_enabled
      kong_portal_enabled         = var.kong_portal_enabled
      portal_and_vitals_key_arn   = var.portal_and_vitals_key_arn
      lua_ssl_cert                = var.lua_ssl_cert
      kong_cluster_mtls           = var.kong_cluster_mtls
      cluster_ca_cert             = var.cluster_ca_cert
      cluster_cert                = var.cluster_cert
      cluster_key                 = var.cluster_key
      kong_log_level              = var.kong_log_level
      kong_plugins                = join(",", concat(["bundled"], var.kong_plugins))
      entrypoint                  = var.entrypoint
      nginx_custom_config         = base64encode(var.nginx_custom_config)
      vitals_tsdb_address         = var.vitals_tsdb_address
      vitals_endpoint = var.vitals_endpoint != null ? format("%s:%g %s",
        var.vitals_endpoint.fqdn,
        var.vitals_endpoint.port,
        lower(var.vitals_endpoint.protocol)
      ) : ""
    }) : var.role == "data_plane" ? templatefile("${path.module}/../../templates/ecs/kong_data_plane.tpl",
    {
      name                = local.name
      group_name          = local.name
      cpu                 = var.fargate_cpu
      image_url           = var.image_url
      memory              = var.fargate_memory
      user                = "kong"
      log_group           = var.log_group
      ports               = jsonencode([for k, v in var.kong_ports : v])
      ulimits             = jsonencode([4096])
      region              = var.region
      access_log_format   = var.access_log_format
      error_log_format    = var.error_log_format
      clustering_endpoint = var.clustering_endpoint
      telemetry_endpoint  = var.telemetry_endpoint
      cluster_server_name = var.cluster_server_name
      status_port         = var.kong_ports.status
      ssl_cert            = var.ssl_cert
      ssl_key             = var.ssl_key
      lua_ssl_cert        = var.lua_ssl_cert
      cluster_cert        = var.cluster_cert
      cluster_key         = var.cluster_key
      kong_log_level      = var.kong_log_level
      kong_plugins        = join(",", concat(["bundled"], var.kong_plugins))
      entrypoint          = var.entrypoint
      nginx_custom_config = base64encode(var.nginx_custom_config)
      kong_vitals_enabled = var.kong_vitals_enabled
      vitals_endpoint = var.vitals_endpoint != null ? format("%s:%g %s",
        var.vitals_endpoint.fqdn,
        var.vitals_endpoint.port,
        lower(var.vitals_endpoint.protocol)
      ) : ""
    }) : var.role == "portal" ? templatefile("${path.module}/../../templates/ecs/kong_portal.tpl",
    {
      name                      = local.name
      group_name                = local.name
      cpu                       = var.fargate_cpu
      image_url                 = var.image_url
      memory                    = var.fargate_memory
      user                      = "kong"
      db_user                   = var.kong_database_config.user
      db_host                   = local.db_info.endpoint
      db_name                   = local.db_info.database_name
      db_password_arn           = var.db_password_arn
      log_group                 = var.log_group
      portal_gui_port           = var.kong_ports.portal_gui
      portal_api_port           = var.kong_portal_api_enabled == "on" ? var.kong_ports.portal_api : ""
      status_port               = var.kong_ports.status
      kong_portal_gui_host      = var.kong_portal_gui_host
      kong_portal_gui_protocol  = var.kong_portal_gui_protocol
      kong_portal_api_url       = var.kong_portal_api_url
      kong_portal_api_enabled   = var.kong_portal_api_enabled
      portal_and_vitals_key_arn = var.portal_and_vitals_key_arn
      ports                     = jsonencode([for k, v in var.kong_ports : v])
      ulimits                   = jsonencode([4096])
      region                    = var.region
      access_log_format         = var.access_log_format
      error_log_format          = var.error_log_format
      ssl_cert                  = var.ssl_cert
      ssl_key                   = var.ssl_key
      cluster_cert              = var.cluster_cert
      cluster_key               = var.cluster_key
      kong_log_level            = var.kong_log_level
      kong_plugins              = join(",", concat(["bundled"], var.kong_plugins))
      entrypoint                = var.entrypoint
      nginx_custom_config       = base64encode(var.nginx_custom_config)
      environment               = var.environment
  }) : null

  tags = {
    Name = local.name
  }
}

resource "aws_ecs_service" "kong" {
  name                   = local.name
  cluster                = var.ecs_cluster_arn
  enable_execute_command = var.enable_execute_command
  task_definition        = aws_ecs_task_definition.kong.arn
  platform_version       = var.platform_version
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  propagate_tags         = "TASK_DEFINITION"

  lifecycle {
    ignore_changes = [desired_count] # Required in case Autoscaling Policy changes the desired_count
  }

  network_configuration {
    security_groups = local.security_groups
    subnets         = local.private_subnets
  }

  dynamic "load_balancer" {
    for_each = var.ecs_target_group_arns
    content {
      target_group_arn = load_balancer.key
      container_name   = local.name
      container_port   = load_balancer.value
    }
  }

  tags = {
    Name = local.name
  }
}

data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    sid     = "EcsAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kong_task_role" {
  name               = "${local.name}-kong-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json

  tags = {
    Name = local.name
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.kong.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

module "security_groups" {
  count                             = local.create_security_groups
  source                            = "../security_groups"
  name                              = var.security_group_name
  vpc_id                            = var.vpc_id
  rules_with_source_cidr_blocks     = var.rules_with_source_cidr_blocks
  rules_with_source_security_groups = var.rules_with_source_security_groups
  rules_with_source_prefix_list_id  = var.rules_with_source_prefix_list_id
  tags                              = var.tags
}

module "private_subnets" {
  count             = local.create_private_subnets
  source            = "../subnets"
  vpc_id            = var.vpc_id
  region            = var.region
  subnets_to_create = var.private_subnets_to_create
  tags              = var.tags
}
