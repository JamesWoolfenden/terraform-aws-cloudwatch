resource "aws_cloudwatch_log_subscription_filter" "logs" {
  for_each = var.subscription_filters

  name            = each.key
  log_group_name  = aws_cloudwatch_log_group.logs.name
  destination_arn = each.value.destination_arn
  filter_pattern  = each.value.filter_pattern
  role_arn        = each.value.role_arn
  distribution    = each.value.distribution

  lifecycle {
    precondition {
      condition     = var.log_group_class == "STANDARD"
      error_message = "Subscription filters require log_group_class = \"STANDARD\"; the INFREQUENT_ACCESS class does not support them."
    }
  }
}
