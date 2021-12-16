output "outputs" {
  description = "Returns `endpoint` as RDS Database endpoint, `database_name` as the DB name, and `security_group_id` as the Security Group associated to the RDS database."
  value = {
    endpoint          = aws_rds_cluster.cluster.endpoint
    database_name     = aws_rds_cluster.cluster.database_name
    security_group_id = aws_security_group.db.id
  }
}
