locals {
  zone_count = length(data.aws_availability_zones.current.zone_ids)
  zone_names = data.aws_availability_zones.current.names
  # zone_count = length(var.vpc.azs)
  # zone_names = var.vpc.azs
}
