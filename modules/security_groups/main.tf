resource "aws_security_group" "security_group" {
  description = "Kong Security Groups"
  name_prefix = var.name
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = var.name })
}

resource "aws_security_group_rule" "security_group_with_cidr_block" {
  for_each          = var.rules_with_source_cidr_blocks
  description       = each.key
  security_group_id = aws_security_group.security_group.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
}

resource "aws_security_group_rule" "security_group_with_security_group" {
  for_each                 = var.rules_with_source_security_groups
  description              = each.key
  security_group_id        = aws_security_group.security_group.id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  source_security_group_id = each.value.source_security_group_id
}

resource "aws_security_group_rule" "security_group_with_prefix_list_id" {
  for_each          = var.rules_with_source_prefix_list_id
  description       = each.key
  security_group_id = aws_security_group.security_group.id
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  prefix_list_ids   = each.value.prefix_list_id
}
