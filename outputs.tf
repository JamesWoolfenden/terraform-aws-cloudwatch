output "name" {
  value       = aws_cloudwatch_log_group.logs.name
  description = "The name of the CloudWatch log group"
}

output "arn" {
  value       = aws_cloudwatch_log_group.logs.arn
  description = "The ARN of the CloudWatch log group"
}

output "retention_in_days" {
  value       = aws_cloudwatch_log_group.logs.retention_in_days
  description = "The retention period in days applied to the log group"
}

output "log_group_class" {
  value       = aws_cloudwatch_log_group.logs.log_group_class
  description = "The class of the CloudWatch log group"
}

output "metric_filter_names" {
  value       = { for name, filter in aws_cloudwatch_log_metric_filter.logs : name => filter.name }
  description = "Names of the metric filters created on the log group, keyed by filter key"
}

output "metric_alarm_arns" {
  value       = { for name, alarm in aws_cloudwatch_metric_alarm.logs : name => alarm.arn }
  description = "ARNs of the CloudWatch alarms created from the metric filters, keyed by filter key"
}

output "subscription_filter_names" {
  value       = { for name, filter in aws_cloudwatch_log_subscription_filter.logs : name => filter.name }
  description = "Names of the subscription filters created on the log group, keyed by filter key"
}
