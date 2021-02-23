output "outputs" {
  value = {
    endpoint          = aws_rds_cluster.cluster.endpoint
    database_name     = aws_rds_cluster.cluster.database_name
    security_group_id = aws_security_group.db.id
  }
}
