# terraform-aws-kong-gateway

Terraform module for provisioning [Kong Gateway]() in AWS on EC2 instances. The module will also, optionally, create an RDS database cluster, subnets, and security groups.

The [cloud-init script]() will install either Kong community or enterprise edition (depending on `ee_creds_ssm_param` variable value)

The module can deploy Kong Gateway in several ways:
- [Embedded](https://docs.konghq.com/enterprise/2.3.x/deployment/deployment-options/#embedded)
- [Hybrid](https://docs.konghq.com/enterprise/2.3.x/deployment/hybrid-mode/) Control Plane
- [Hybrid](https://docs.konghq.com/enterprise/2.3.x/deployment/hybrid-mode/) Data Plane

:warning: The module is currently only tested for Hybrid control planes and data planes. Use of embedded has not been tested. 

## Status
Maturing - Some scenarios tested, but not all. Module in use, but only for a limited number of configurations. Looking for more consumers to raise issues they find with additional scenarios.

## Examples
Examples of how to use the module are in the [examples](examples) directory.
Currently, there are three examples:

- [hybrid](examples/hybrid) deploys Kong in hybrid mode
- [hybrid_external_database](examples/hybrid_external_database) first creates a database, then supplies the DB config to the module to use, instead of the module building the DB.
- [hybrid_http_proxy](examples/hybrid_http_proxy) deploys Kong in hybrid mode behind an outbound HTTP proxy for internet access

```hcl
locals {
  kong_control_plane_config = {
    "KONG_ROLE" = "control_plane"
    "KONG_PROXY_LISTEN" = "off"
    "KONG_ANONYMOUS_REPORTS" = "off"
    "KONG_PORTAL" = "on"
    "KONG_VITALS" = "on"
    "KONG_AUDIT_LOG" = "on"
    "KONG_LOG_LEVEL" = "info"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical AWS account that publishes Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_kms_alias" "default_ssm" {
  name = "alias/aws/ssm"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

data "aws_iam_policy_document" "kong_ssm" {
  statement {
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:*:parameter/${var.service}/${var.environment}/*"]
  }

  statement {
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.default_ssm.target_key_arn]
  }
}

resource "aws_iam_role_policy" "kong_ssm" {
  name = format("%s-%s-ssm", var.service, var.environment)
  role = aws_iam_role.kong.id

  policy = data.aws_iam_policy_document.kong_ssm.json
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
  name               = format("%s-%s", var.service, var.environment)
  assume_role_policy = data.aws_iam_policy_document.kong.json
}

resource "aws_iam_instance_profile" "kong" {
  name = format("%s-%s", var.service, var.environment)
  role = aws_iam_role.kong.id
}

resource "random_string" "db_password" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name  = format("/%s/%s/db/password", var.service, var.environment)
  type  = "SecureString"
  value = random_string.db_password.result

  key_id = data.aws_kms_alias.default_ssm.target_key_arn

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
  name  = format("/%s/%s/db/password/master", var.service, var.environment)
  type  = "SecureString"
  value = random_string.master_password.result

  key_id = data.aws_kms_alias.default_ssm.target_key_arn

  lifecycle {
    ignore_changes = [value]
  }

  overwrite = true
}

module "kong_control_plane" {
  source = "dwp/kong-gateway/aws"

  vpc_id                    = aws_vpc.vpc.id
  ami_id                    = data.aws_ami.ubuntu.id
  region                    = "eu-west-2"
  vpc_cidr_block            = aws_vpc.vpc.cidr_block
  iam_instance_profile_name = aws_iam_instance_profile.kong.name
  
  postgres_config = {
    master_user     = "root"
    master_password = random_string.master_password.result
  }

  kong_database_config = {
    user     = "kong"
    name     = "kong"
    password = random_string.db_password.result
  }
  
  kong_config = local.kong_control_plane_config
}
```


## Testing

For details refer to [CONTRIBUTING.md](CONTRIBUTING.md#testing-and-linting)
