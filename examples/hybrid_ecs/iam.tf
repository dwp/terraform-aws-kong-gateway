data "aws_iam_policy_document" "kong-ssm" {
  statement {
    actions   = ["ssm:DescribeParameters"]
    resources = [
      "arn:aws:ssm:${var.region}:*:parameter/*"
    ]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.region}:*:parameter/${var.service}/${local.environment}/*"]
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_alias.kong.target_key_arn]
  }
}

resource "aws_iam_role_policy" "kong-ssm" {
  name = format("%s-%s-ssm", var.service, local.environment)
  role = aws_iam_role.kong.id

  policy = data.aws_iam_policy_document.kong-ssm.json
}

data "aws_iam_policy_document" "kong" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "kong" {
  name               = format("%s-%s", var.service, local.environment)
  assume_role_policy = data.aws_iam_policy_document.kong.json
}

resource "aws_iam_instance_profile" "kong" {
  name = format("%s-%s", var.service, local.environment)
  role = aws_iam_role.kong.id
}

resource "aws_iam_role_policy_attachment" "ingestion_ecs_ssm" {
  role       = aws_iam_role.kong.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "ingestion_ssm_managed" {
  role       = aws_iam_role.kong.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ecs_execute_command_policy" {
  name        = "${var.environment}-kong-cp-execute-command-policy"
  description = "Policy defining permissions forto enable Execute Command on ECS"
  policy      = data.aws_iam_policy_document.ecs_execute_command_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_execute_command_policy_attachment_cp" {
  role       = module.create_kong_cp.kong_iam_role
  policy_arn = aws_iam_policy.ecs_execute_command_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execute_command_policy_attachment_dp" {
  role       = module.create_kong_dp.kong_iam_role
  policy_arn = aws_iam_policy.ecs_execute_command_policy.arn
}

data "aws_iam_policy_document" "ecs_execute_command_policy" {
  statement {
    sid    = "GetSecrets"
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
    resources = [
      "arn:aws:ssm:${var.region}:*:parameter/*",
      "arn:aws:secretsmanager:${var.region}:*:secret:*",
      "arn:aws:kms:${var.region}:*:key/*"
    ]
  }
  statement {
    sid    = "ECSExec"
    effect = "Allow"

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}
