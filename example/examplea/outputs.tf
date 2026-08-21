output "name" {
  value       = module.cloudwatch.name
  description = "The name of the CloudWatch log group"
}

output "arn" {
  value       = module.cloudwatch.arn
  description = "The ARN of the CloudWatch log group"
}

output "retention_in_days" {
  value       = module.cloudwatch.retention_in_days
  description = "The retention period in days applied to the log group"
}

output "log_group_class" {
  value       = module.cloudwatch.log_group_class
  description = "The class of the CloudWatch log group"
}
