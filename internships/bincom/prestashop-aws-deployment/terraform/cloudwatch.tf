resource "aws_cloudwatch_log_group" "web_logs" {
  name              = "/prestashop/web-server"
  retention_in_days = 7

  tags = {
    Name = "prestashop-web-logs"
  }
}

resource "aws_cloudwatch_log_group" "db_logs" {
  name              = "/prestashop/database-server"
  retention_in_days = 7

  tags = {
    Name = "prestashop-db-logs"
  }
}
