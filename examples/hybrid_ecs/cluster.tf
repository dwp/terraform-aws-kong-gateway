resource "aws_ecs_cluster" "kong" {
  name = var.environment

  tags = {
    Name = var.environment
  }

  lifecycle {
    ignore_changes = [
      setting,
    ]
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.environment}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
  tags = {
    Name = "${var.environment}-ecs-task-execution"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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

## SSM Decryption policy
resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "${var.environment}-ecs-task-execution-ssm-policy"
  description = "Policy defining permissions for ECS to retrieve Secret and Parameter Store Values"
  policy      = data.aws_iam_policy_document.ecs_secrets_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
}

data "aws_iam_policy_document" "ecs_secrets_policy" {
  statement {
    sid    = "GetSecrets"
    effect = "Allow"

    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
    resources = [
      "arn:aws:ssm:eu-west-1:*:parameter/*",
      "arn:aws:secretsmanager:eu-west-1:*:secret:*",
      "arn:aws:kms:eu-west-1:*:key/*"
    ]
  }
}
