resource "aws_security_group" "sec-grp" {
  description = "Kong Security Groups"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "kong-security-group" })
}

resource "aws_security_group_rule" "this-sec-rule-source-cidr-blocks" {
  for_each          = var.rules_with_source_cidr_blocks
  description       = each.key
  security_group_id = aws_security_group.sec-grp.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "this-sec-rule-source-security-group" {
  for_each                 = var.rules_with_source_security_groups
  description              = each.key
  security_group_id        = aws_security_group.sec-grp.id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.source_security_group_id
}
