locals {
  zone_count = length(data.aws_availability_zones.current.zone_ids)
  zone_names = data.aws_availability_zones.current.names
}
