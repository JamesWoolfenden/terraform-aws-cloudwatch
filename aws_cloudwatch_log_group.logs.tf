resource "aws_cloudwatch_log_group" "logs" {
  name              = var.log_group_name
  retention_in_days = var.retention
  kms_key_id        = var.kms_key_id
  tags              = var.common_tags
}
