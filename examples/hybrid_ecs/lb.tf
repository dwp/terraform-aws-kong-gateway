resource "aws_security_group" "external-lb" {
  description = "Kong External Load Balancer"
  name        = "external-lb-sg"
  vpc_id      = aws_vpc.vpc.id
  tags        = var.tags
}

resource "aws_security_group_rule" "external-lb-ingress-proxy" {
  security_group_id = aws_security_group.external-lb.id

  type      = "ingress"
  from_port = 8000
  to_port   = 8000
  protocol  = "tcp"

  cidr_blocks = var.external_cidr_blocks

}

resource "aws_security_group_rule" "external-lb-ingress-admin" {
  security_group_id = aws_security_group.external-lb.id

  type      = "ingress"
  from_port = 8001
  to_port   = 8001
  protocol  = "tcp"

  cidr_blocks = var.external_cidr_blocks

}

# TBD
resource "aws_security_group_rule" "external-lb-status" {
  security_group_id = aws_security_group.external-lb.id

  type      = "ingress"
  from_port = 8100
  to_port   = 8100
  protocol  = "tcp"

  cidr_blocks = var.external_cidr_blocks

}
resource "aws_security_group_rule" "external-lb-egress" {
  security_group_id = aws_security_group.external-lb.id

  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"

  cidr_blocks = var.external_cidr_blocks

}

resource "aws_lb" "external" {

  name     = "external-lb"
  internal = false
  subnets  = local.public_subnet_ids

  security_groups = [aws_security_group.external-lb.id]

  idle_timeout = 60

  tags = var.tags
}

resource "aws_lb_target_group" "external-proxy" {
  name     = "external-proxy-8443"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 4
    interval            = 10
    path                = "/status"
    protocol            = "HTTPS"
    port                = 8100
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "external-admin-api" {
  name        = "external-admin-api-8444"
  port        = 8444
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold   = 4
    interval            = 10
    path                = "/status"
    protocol            = "HTTPS"
    port                = 8100
    unhealthy_threshold = 2
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "external-proxy" {

  load_balancer_arn = aws_lb.external.arn
  port              = 8000

  default_action {
    target_group_arn = aws_lb_target_group.external-proxy.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "admin" {

  load_balancer_arn = aws_lb.external.arn
  port              = 8001
  default_action {
    target_group_arn = aws_lb_target_group.external-admin-api.arn
    type             = "forward"
  }
}

resource "aws_lb" "internal" {

  name               = "kong-internal-lb"
  internal           = true
  subnets            = module.create_kong_cp.private_subnet_ids
  load_balancer_type = "network"
  idle_timeout       = 60
  tags               = var.tags
}

resource "aws_lb_target_group" "internal-cluster" {
  name     = "internal-cluster-8005"
  port     = 8005
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 5
    interval            = 30
    port                = 8005
    protocol            = "TCP"
    unhealthy_threshold = 5
  }
}

resource "aws_lb_target_group" "internal-telemetry" {
  name     = "internal-telemetry-8006"
  port     = 8006
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 5
    interval            = 30
    port                = 8006
    protocol            = "TCP"
    unhealthy_threshold = 5
  }
}

resource "aws_lb_target_group" "internal-admin-api" {
  name     = "internal-admin-api-8444" # FIX
  port     = 8444
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    healthy_threshold   = 5
    interval            = 30
    port                = 8444
    protocol            = "TCP"
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "cluster" {

  load_balancer_arn = aws_lb.internal.arn
  port              = 8005
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.internal-cluster.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "telemetry" {

  load_balancer_arn = aws_lb.internal.arn
  port              = 8006
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.internal-telemetry.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "internal-admin" {

  load_balancer_arn = aws_lb.internal.arn
  port              = 8444
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.internal-admin-api.arn
    type             = "forward"
  }
}
