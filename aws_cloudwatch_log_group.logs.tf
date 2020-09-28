resource "aws_cloudwatch_log_group" "logs" {
  name              = var.log_group_name
  retention_in_days = "1"
  kms_key_id        = "aws/cloudwatch"
  tags              = var.common_tags
}


variable "log_group_name" {
  type    = string
  default = "test_logs"
}
