resource "aws_db_subnet_group" "cluster" {
  subnet_ids = var.vpc.subnets
  tags       = merge(var.tags, { Name = "${var.name}-subnet-group" })
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid       = "KMS"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_kms_key" "aurora" {
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${var.name}-db-key", ProtectsSensitiveData = true })
  policy                  = var.kms_key_policy != null ? var.kms_key_policy : data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_kms_alias" "aurora" {
  name          = "alias/${var.name}-db-key-${var.environment}"
  target_key_id = aws_kms_key.aurora.key_id
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier        = "${var.name}-${var.environment}"
  engine                    = var.database.engine
  engine_version            = var.database.engine_version
  availability_zones        = local.zone_names
  database_name             = var.name
  master_username           = var.database_credentials.username
  master_password           = var.database_credentials.password
  backup_retention_period   = 14
  preferred_backup_window   = "06:00-08:00"
  apply_immediately         = var.cluster_apply_immediately
  db_subnet_group_name      = aws_db_subnet_group.cluster.id
  final_snapshot_identifier = "${var.name}-final-snapshot"
  skip_final_snapshot       = var.skip_final_snapshot
  storage_encrypted         = var.encrypt_storage
  kms_key_id                = aws_kms_key.aurora.arn
  vpc_security_group_ids    = [aws_security_group.db.id]
  tags                      = merge(var.tags, { Name = "${var.name}-db" })

  lifecycle {
    ignore_changes = [
      engine_version,
      snapshot_identifier,
      master_password,
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster" {
  count              = var.database.db_count
  identifier_prefix  = "${var.name}-${local.zone_names[count.index]}-"
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.cluster.engine_version
  availability_zone  = local.zone_names[count.index]
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = var.database.instance_type
  apply_immediately  = var.instance_apply_immediately
  ca_cert_identifier = var.ca_certificate_identifier
  tags               = merge(var.tags, { Name = "${var.name}-db" })

  lifecycle {
    create_before_destroy = true
  }
}
