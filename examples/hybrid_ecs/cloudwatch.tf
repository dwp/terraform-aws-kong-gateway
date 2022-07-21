resource "aws_cloudwatch_log_group" "kong_dp" {
  name              = "${var.environment}-dp"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-dp"
  }
}

resource "aws_cloudwatch_log_group" "kong_cp" {
  name              = "${var.environment}-cp"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-cp"
  }
}