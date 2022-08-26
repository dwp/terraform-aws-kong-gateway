resource "aws_kms_key" "kong" {
  description = format("%s-%s", var.service, local.environment)

  tags = merge(
    {
      "Name"        = format("%s-%s", var.service, local.environment),
      "Environment" = local.environment,
      "Description" = var.description,
      "Service"     = var.service,
    },
    var.tags
  )
}

resource "aws_kms_alias" "kong" {
  name          = format("alias/%s-%s", var.service, local.environment)
  target_key_id = aws_kms_key.kong.key_id
}


resource "random_string" "admin_token" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "ee-admin-token" {
  name  = format("/%s/%s/ee/admin/token", var.service, local.environment)
  type  = "SecureString"
  value = random_string.admin_token.result

  key_id = aws_kms_alias.kong.target_key_arn

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_password" {
  name  = format("/%s/%s/db/password", var.service, local.environment)
  type  = "SecureString"
  value = var.kong_database_password

  key_id = aws_kms_alias.kong.target_key_arn

  lifecycle {
    ignore_changes = [value]
  }

  overwrite = true
}

resource "random_string" "master_password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "db_master_password" {
  name  = format("/%s/%s/db/password/master", var.service, local.environment)
  type  = "SecureString"
  value = random_string.master_password.result

  key_id = aws_kms_alias.kong.target_key_arn

  lifecycle {
    ignore_changes = [value]
  }

  overwrite = true
}

resource "random_string" "session_secret" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "session_conf" {
  name  = format("/%s/%s/ee/session/conf", var.service, local.environment)
  type  = "SecureString"
  value = "{\"secret\":\"${random_string.session_secret.result}\",\"cookie_secure\":false}"

  key_id = aws_kms_alias.kong.target_key_arn

  lifecycle {
    ignore_changes = [value]
  }

  overwrite = true
}
