module "kong_ec2" {
  count  = var.deployment_type == "ec2" ? 1 : 0
  source = "./modules/ec2"

  ami_id                            = var.ami_id
  ami_operating_system              = var.ami_operating_system
  iam_instance_profile_name         = var.iam_instance_profile_name
  region                            = var.region
  vpc_cidr_block                    = var.vpc_cidr_block
  vpc_id                            = var.vpc_id
  asg_desired_capacity              = var.asg_desired_capacity
  asg_health_check_grace_period     = var.asg_health_check_grace_period
  asg_max_size                      = var.asg_max_size
  asg_min_size                      = var.asg_min_size
  associate_public_ip_address       = var.associate_public_ip_address
  availability_zones                = var.availability_zones
  ce_pkg                            = var.ce_pkg
  deck_version                      = var.deck_version
  desired_capacity                  = var.desired_capacity
  description                       = var.description
  ec2_root_volume_size              = var.ec2_root_volume_size
  ec2_root_volume_type              = var.ec2_root_volume_type
  ee_creds_ssm_param                = var.ee_creds_ssm_param
  ee_pkg                            = var.ee_pkg
  enable_monitoring                 = var.enable_monitoring
  encrypt_storage                   = var.encrypt_storage
  environment                       = var.environment
  force_delete                      = var.force_delete
  health_check_grace_period         = var.health_check_grace_period
  health_check_type                 = var.health_check_type
  instance_type                     = var.instance_type
  key_name                          = var.key_name
  user_data                         = var.user_data
  kong_clear_database               = var.kong_clear_database
  kong_config                       = var.kong_config
  kong_database_config              = var.kong_database_config
  kong_hybrid_conf                  = var.kong_hybrid_conf
  kong_ports                        = var.kong_ports
  kong_ssl_uris                     = var.kong_ssl_uris
  manager_host                      = var.manager_host
  placement_tenancy                 = var.placement_tenancy
  portal_host                       = var.portal_host
  postgres_config                   = var.postgres_config
  postgres_host                     = var.postgres_host
  private_subnets                   = var.private_subnets
  private_subnets_to_create         = var.private_subnets_to_create
  proxy_config                      = var.proxy_config
  root_block_size                   = var.root_block_size
  root_block_type                   = var.root_block_type
  rules_with_source_cidr_blocks     = var.rules_with_source_cidr_blocks
  rules_with_source_security_groups = var.rules_with_source_security_groups
  rules_with_source_prefix_list_id  = var.rules_with_source_prefix_list_id
  security_group_ids                = var.security_group_ids
  service                           = var.service
  skip_final_snapshot               = var.skip_final_snapshot
  skip_rds_creation                 = var.skip_rds_creation
  tags                              = var.tags
  tags_asg                          = var.tags_asg
  target_group_arns                 = var.target_group_arns
  min_healthy_percentage            = var.min_healthy_percentage
  role                              = var.role
  security_group_name               = var.security_group_name
}


module "kong_ecs" {
  count  = var.deployment_type == "ecs" ? 1 : 0
  source = "./modules/ecs"

  #env = replace(var.env, "_", "-")
  role                   = var.role
  ecs_cluster_arn        = var.ecs_cluster_arn
  ecs_cluster_name       = var.ecs_cluster_name
  platform_version       = var.platform_version
  service                = var.service
  fargate_cpu            = var.fargate_cpu
  fargate_memory         = var.fargate_memory
  enable_execute_command = var.enable_execute_command
  admin_api_port         = var.admin_api_port # TBD
  kong_status_port       = var.kong_status_port
  vpc_id                 = var.vpc_id
  # subnet_names                 = var.subnet_names
  # parent_domain                = var.parent_domain
  # acm_certificate_arn          = var.acm_certificate_arn

  access_log_format = var.access_log_format
  error_log_format  = var.error_log_format

  region                    = var.region
  private_subnets           = var.private_subnets
  private_subnets_to_create = var.private_subnets_to_create
  tags                      = var.tags

  kong_ssl_uris = var.kong_ssl_uris

  # Needed?
  lb_target_group_arn = var.lb_target_group_arn
  image_url           = var.image_url
  execution_role_arn  = var.execution_role_arn

  #DB
  skip_final_snapshot    = var.skip_final_snapshot
  skip_rds_creation      = var.skip_rds_creation
  postgres_config        = var.postgres_config
  postgres_host          = var.postgres_host
  db_password_arn        = var.db_password_arn
  db_master_password_arn = var.db_master_password_arn

  session_secret = var.session_secret

  log_group = var.log_group

  template_file = var.template_file

  custom_nginx_conf = var.custom_nginx_conf

  ssl_cert     = var.ssl_cert
  ssl_key      = var.ssl_key
  lua_ssl_cert = var.lua_ssl_cert

  cluster_cert = var.cluster_cert
  cluster_key  = var.cluster_key

  kong_log_level       = var.kong_log_level
  log_retention_period = var.log_retention_period

  secrets_list = var.secrets_list

  desired_count = var.desired_count
  min_capacity  = var.min_capacity
  max_capacity  = var.max_capacity

  control_plane_endpoint = var.control_plane_endpoint
  clustering_endpoint    = var.clustering_endpoint
  telemetry_endpoint     = var.telemetry_endpoint
}
