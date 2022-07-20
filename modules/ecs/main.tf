locals {
  create_private_subnets = length(var.private_subnets) > 0 ? 0 : 1
  create_security_groups = length(var.security_group_ids) > 0 ? 0 : 1

  # If the module user has specified a postgres_host then we use
  # that as our endpoint, as we will not be triggering the database module
  db_info = {
    endpoint      = var.postgres_host
    database_name = var.kong_database_config.name
  }

  security_groups = length(var.security_group_ids) > 0 ? var.security_group_ids : module.security_groups.0.ids
  private_subnets = length(var.private_subnets) > 0 ? var.private_subnets : module.private_subnets.0.ids
  #  database = var.skip_rds_creation ? null : {
  #    endpoint          = module.database.0.outputs.endpoint
  #    database_name     = module.database.0.outputs.database_name
  #    security_group_id = module.database.0.outputs.security_group_id
  #  }

  azs = length(var.availability_zones) > 0 ? var.availability_zones : module.private_subnets.0.azs

  ssm_parameter_path = format("/%s/%s", var.service, var.environment)

  vpc_object = {
    id      = var.vpc_id
    subnets = local.private_subnets
    azs     = local.azs
  }
  name = format("%s-%s-%s", var.service, var.environment, var.role)
}

resource "aws_ecs_task_definition" "kong" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  task_role_arn            = aws_iam_role.kong_task_role.arn
  execution_role_arn       = var.execution_role_arn
  container_definitions    = var.role == "control_plane" ? "[${data.template_file.kong_task_definition_cp[0].rendered}]" : var.role == "data_plane" ? "[${data.template_file.kong_task_definition_dp[0].rendered}]" : null

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

data "template_file" "kong_task_definition_cp" {
  count    = var.role == "control_plane" ? 1 : 0
  template = file("${path.module}/../../templates/ecs/kong_control_plane.tpl")
  vars = {
    name                   = local.name
    group_name             = local.name
    cpu                    = var.fargate_cpu
    image_url              = var.image_url # To be updated
    memory                 = var.fargate_memory
    user                   = "kong"
    parameter_path         = local.ssm_parameter_path
    db_user                = var.kong_database_config.user
    db_host                = local.db_info.endpoint
    db_name                = local.db_info.database_name
    db_password_arn        = var.db_password_arn
    db_master_password_arn = var.db_master_password_arn
    session_secret         = var.session_secret
    log_group              = var.log_group
    admin_api_port         = var.kong_dp_ports.admin-api
    status_port            = var.kong_dp_ports.status
    ports = jsonencode([8444, 8100, 8005, 8006]) # TBD
    #ports                  = jsonencode([for k, v in var.kong_dp_ports : v])
    ulimits                = jsonencode([4096])
    region                 = var.region
    access_log_format      = var.access_log_format
    error_log_format       = var.error_log_format
    ssl_cert               = var.ssl_cert
    ssl_key                = var.ssl_key
    kong_admin_api_uri     = var.kong_ssl_uris.admin_api_uri
    kong_admin_gui_url     = var.kong_ssl_uris.admin_gui_url
    admin_token            = var.admin_token
    lua_ssl_cert           = var.lua_ssl_cert
    cluster_cert           = var.cluster_cert
    cluster_key            = var.cluster_key
    kong_log_level         = var.kong_log_level
    entrypoint             = "/management-plane-entrypoint.sh"
    custom_nginx_conf      = base64encode(var.custom_nginx_conf)
  }
}

data "template_file" "kong_task_definition_dp" {
  count    = var.role == "data_plane" ? 1 : 0
  template = file("${path.module}/../../templates/ecs/kong_data_plane.tpl")
  vars = {
    name                   = local.name
    group_name             = local.name
    cpu                    = var.fargate_cpu
    image_url              = var.image_url # To be updated
    memory                 = var.fargate_memory
    user                   = "kong"
    parameter_path         = local.ssm_parameter_path
    log_group              = var.log_group
    ports = jsonencode([8443, 8100]) # TBD
    ulimits                = jsonencode([4096])
    region                 = var.region
    access_log_format      = var.access_log_format
    error_log_format       = var.error_log_format
    control_plane_endpoint = var.control_plane_endpoint
    clustering_endpoint    = var.clustering_endpoint
    telemetry_endpoint     = var.telemetry_endpoint
    ssl_cert               = var.ssl_cert
    ssl_key                = var.ssl_key
    lua_ssl_cert           = var.lua_ssl_cert
    cluster_cert           = var.cluster_cert
    cluster_key            = var.cluster_key
    kong_log_level         = var.kong_log_level
    entrypoint             = "/gateway-entrypoint.sh"
    custom_nginx_conf      = base64encode(var.custom_nginx_conf)
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

#module "database" {
#  count                   = var.skip_rds_creation ? 0 : 1
#  source                  = "../database"
#  name                    = var.kong_database_config.name
#  environment             = var.environment
#  vpc                     = local.vpc_object
#  allowed_security_groups = local.security_groups
#  skip_final_snapshot     = var.skip_final_snapshot
#  encrypt_storage         = var.encrypt_storage
#  database_credentials = { # FIXME: secrets_manager
#    username = var.postgres_config.master_user
#    password = var.postgres_config.master_password
#  }
#  tags = var.tags
#}
