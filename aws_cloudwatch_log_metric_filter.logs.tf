resource "aws_cloudwatch_log_metric_filter" "logs" {
  for_each = var.metric_filters

  name           = each.key
  pattern        = each.value.pattern
  log_group_name = aws_cloudwatch_log_group.logs.name

  metric_transformation {
    name          = each.value.metric_transformation.name
    namespace     = each.value.metric_transformation.namespace
    value         = each.value.metric_transformation.value
    default_value = each.value.metric_transformation.default_value
    unit          = each.value.metric_transformation.unit
  }

  lifecycle {
    precondition {
      condition     = var.log_group_class == "STANDARD"
      error_message = "Metric filters require log_group_class = \"STANDARD\"; the INFREQUENT_ACCESS class does not support them."
    }
  }
}
