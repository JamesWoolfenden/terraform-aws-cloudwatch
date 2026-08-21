resource "aws_cloudwatch_metric_alarm" "logs" {
  for_each = { for name, filter in var.metric_filters : name => filter if filter.alarm != null }

  alarm_name          = "${var.log_group_name}-${each.key}"
  alarm_description   = each.value.alarm.description
  actions_enabled     = each.value.alarm.actions_enabled
  namespace           = each.value.metric_transformation.namespace
  metric_name         = each.value.metric_transformation.name
  comparison_operator = each.value.alarm.comparison_operator
  evaluation_periods  = each.value.alarm.evaluation_periods
  period              = each.value.alarm.period
  statistic           = each.value.alarm.statistic
  threshold           = each.value.alarm.threshold
  treat_missing_data  = each.value.alarm.treat_missing_data
  alarm_actions       = each.value.alarm.alarm_actions
  ok_actions          = each.value.alarm.ok_actions
}
