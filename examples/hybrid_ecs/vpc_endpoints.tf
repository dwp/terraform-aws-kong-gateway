# ## VPC Endpoint Security Group
# resource "aws_security_group" "vpc_endpoints" {
#   name        = "${var.environment}-vpc-endpoints"
#   description = "Allow connections to AWS endpoints from all vpc subnets"
#   vpc_id      = aws_vpc.vpc.id
# }

# resource "aws_security_group_rule" "vpcendpoint_for_ingress" {
#   type      = "ingress"
#   from_port = 443
#   to_port   = 443
#   protocol  = "tcp"

#   cidr_blocks = [aws_vpc.vpc.cidr_block]

#   security_group_id = aws_security_group.vpc_endpoints.id
# }

# resource "aws_security_group_rule" "vpcendpoint_for_egress" {
#   type      = "egress"
#   from_port = 443
#   to_port   = 443
#   protocol  = "tcp"

#   cidr_blocks = [aws_vpc.vpc.cidr_block]

#   security_group_id = aws_security_group.vpc_endpoints.id

#   lifecycle {
#     create_before_destroy = true
#   }
# }


# # VPC Endpoints required for pulling Container Image from ECR
# resource "aws_vpc_endpoint" "dkr" {
#   vpc_id = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${var.region}.ecr.dkr"
#   vpc_endpoint_type = "Interface"
#   subnet_ids = module.create_kong_cp.private_subnet_ids
#   security_group_ids = [aws_security_group.vpc_endpoints.id]
# }

# resource "aws_vpc_endpoint" "api" {
#   vpc_id = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${var.region}.ecr.api"
#   vpc_endpoint_type = "Interface"
#   security_group_ids = [aws_security_group.vpc_endpoints.id]
#   subnet_ids = module.create_kong_cp.private_subnet_ids
# }

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id = aws_vpc.vpc.id
#   service_name = "com.amazonaws.${var.region}.s3"
#   route_table_ids = aws_route_table.private.*.id
# }
