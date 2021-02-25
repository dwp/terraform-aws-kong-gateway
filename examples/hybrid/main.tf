provider "aws" {
  region = var.region
}

data "aws_ami_ids" "ubuntu" {
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_vpc" "example" {
  cidr_block = var.vpc_cidr_block
}

output "ami" {
  value = data.aws_ami_ids.ubuntu.id
}

module "create_kong_asg" {
  source                    = "../../"
  vpc_id                    = aws_vpc.example.id
  ami_id                    = data.aws_ami_ids.ubuntu.id
  key_name                  = var.key_name
  region                    = var.region
  vpc_cidr_block            = aws_vpc.example.cidr_block
  environment               = var.environment
  service                   = var.service
  description               = var.description
  iam_instance_profile_name = aws_iam_instance_profile.kong.name
  kong_database_password    = var.kong_database_password
  tags                      = var.tags
}
