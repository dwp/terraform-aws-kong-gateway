# resource "aws_route53_zone" "public" {
#   name = aws_lb.external.dns_name
# }

# resource "aws_acm_certificate" "kong" {
#   domain_name       = aws_lb.external.dns_name
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "kong" {
#   for_each = {
#     for dvo in aws_acm_certificate.kong.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = aws_route53_zone.public.zone_id
# }

# resource "aws_acm_certificate_validation" "kong" {
#   certificate_arn         = aws_acm_certificate.kong.arn
#   validation_record_fqdns = [for record in aws_route53_record.kong : record.fqdn]
# }
