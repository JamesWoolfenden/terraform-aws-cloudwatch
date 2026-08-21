resource "aws_sns_topic" "alerts" {
  name              = "examplea-cloudwatch-alerts"
  kms_master_key_id = aws_kms_key.cloudwatch_logs.id
}
