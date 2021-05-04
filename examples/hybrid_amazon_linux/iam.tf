data "aws_iam_policy_document" "kong-ssm" {
  statement {
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/${var.service}/${local.environment}/*"]
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
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ingestion_ssm_managed" {
  role       = aws_iam_role.kong.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
