resource "aws_security_group" "db" {
  vpc_id = var.vpc.id
  tags   = merge(var.tags, { Name = "${var.name}-db" })
}
