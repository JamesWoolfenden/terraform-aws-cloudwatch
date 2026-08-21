# holden:ignore:HLD_TF_026 a module's own example must call it by local path so CI tests the working tree, not a published version
# holden:ignore:HLD_TF_065 this repo is a published single-resource module; wrapping one resource is its purpose
module "cloudwatch" {
  source         = "../../"
  log_group_name = "/aws/cloudwatch/examplea"
  kms_key_id     = aws_kms_key.cloudwatch_logs.arn

  deletion_protection_enabled = false

  metric_filters = {
    errors = {
      pattern = "ERROR"
      metric_transformation = {
        name      = "ExampleaErrorCount"
        namespace = "Examplea/Logs"
        value     = "1"
      }
      alarm = {
        threshold          = 5
        description        = "More than five ERROR lines in five minutes"
        treat_missing_data = "notBreaching"
      }
    }
  }
}
