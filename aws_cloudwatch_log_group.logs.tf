resource "aws_cloudwatch_log_group" "logs" {
  name              = var.log_group_name
  retention_in_days = var.retention
  kms_key_id        = var.kms_key_id

  log_group_class             = var.log_group_class
  deletion_protection_enabled = var.deletion_protection_enabled
  skip_destroy                = var.skip_destroy
}
