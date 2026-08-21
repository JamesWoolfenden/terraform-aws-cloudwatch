variable "log_group_name" {
  description = "Name of the CloudWatch log group to create"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_./#-]{1,512}$", var.log_group_name))
    error_message = "The log_group_name must be 1-512 characters of a-z, A-Z, 0-9, '_', '-', '/', '.' or '#'."
  }
}

variable "retention" {
  description = "Log retention in days"
  type        = number
  default     = 365

  validation {
    condition = contains(
      [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.retention
    )
    error_message = "The retention must be a CloudWatch Logs retention value: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288 or 3653."
  }
}

variable "kms_key_id" {
  description = "ARN of the KMS key used to encrypt the log group data"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:kms:[a-z0-9-]+:[0-9]{12}:(key|alias)/.+$", var.kms_key_id))
    error_message = "The kms_key_id must be a KMS key or alias ARN, e.g. arn:aws:kms:eu-west-2:123456789012:key/<key-id>."
  }
}

variable "log_group_class" {
  description = "Log group class. INFREQUENT_ACCESS costs roughly half the ingestion price of STANDARD but does not support metric filters, subscription filters or Live Tail"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "INFREQUENT_ACCESS"], var.log_group_class)
    error_message = "The log_group_class must be STANDARD or INFREQUENT_ACCESS."
  }
}

variable "deletion_protection_enabled" {
  description = "Prevent the log group being deleted. Unlike lifecycle.prevent_destroy this is enforced by AWS, so it still applies if the resource block is removed. Set false for ephemeral log groups that CI needs to destroy"
  type        = bool
  default     = true
}

variable "skip_destroy" {
  description = "Retain the log group in AWS when it is removed from Terraform state, rather than deleting it"
  type        = bool
  default     = false
}

variable "metric_filters" {
  description = "Metric filters to create on the log group, keyed by filter name. Set the optional alarm object to also create a CloudWatch alarm on the extracted metric"
  type = map(object({
    pattern = string
    metric_transformation = object({
      name          = string
      namespace     = string
      value         = string
      default_value = optional(string)
      unit          = optional(string)
    })
    alarm = optional(object({
      threshold           = number
      actions_enabled     = optional(bool, true)
      comparison_operator = optional(string, "GreaterThanOrEqualToThreshold")
      evaluation_periods  = optional(number, 1)
      period              = optional(number, 300)
      statistic           = optional(string, "Sum")
      description         = optional(string)
      alarm_actions       = optional(list(string), [])
      ok_actions          = optional(list(string), [])
      treat_missing_data  = optional(string, "notBreaching")
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for f in values(var.metric_filters) :
      can(regex("^[A-Za-z0-9._/#:-]{1,255}$", f.metric_transformation.namespace))
    ])
    error_message = "Each metric_transformation.namespace must be 1-255 characters of alphanumerics, '.', '_', '/', '#', ':' or '-'."
  }

  validation {
    condition = alltrue([
      for f in values(var.metric_filters) :
      contains(
        ["GreaterThanOrEqualToThreshold", "GreaterThanThreshold", "LessThanThreshold", "LessThanOrEqualToThreshold"],
        try(f.alarm.comparison_operator, "GreaterThanOrEqualToThreshold")
      )
    ])
    error_message = "Each alarm.comparison_operator must be one of GreaterThanOrEqualToThreshold, GreaterThanThreshold, LessThanThreshold or LessThanOrEqualToThreshold."
  }

  validation {
    condition = alltrue([
      for f in values(var.metric_filters) :
      contains(["SampleCount", "Average", "Sum", "Minimum", "Maximum"], try(f.alarm.statistic, "Sum"))
    ])
    error_message = "Each alarm.statistic must be one of SampleCount, Average, Sum, Minimum or Maximum."
  }

  validation {
    condition = alltrue([
      for f in values(var.metric_filters) :
      try(f.alarm.period, 300) % 60 == 0 || contains([10, 30], try(f.alarm.period, 300))
    ])
    error_message = "Each alarm.period must be 10, 30, or a multiple of 60 seconds."
  }
}

variable "subscription_filters" {
  description = "Subscription filters to create on the log group, keyed by filter name, forwarding log events to a Lambda function, Kinesis stream or Firehose delivery stream"
  type = map(object({
    destination_arn = string
    filter_pattern  = string
    role_arn        = optional(string)
    distribution    = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for f in values(var.subscription_filters) :
      can(regex("^arn:aws[a-zA-Z-]*:(lambda|kinesis|firehose|logs):", f.destination_arn))
    ])
    error_message = "Each destination_arn must be a Lambda, Kinesis, Firehose or CloudWatch Logs destination ARN."
  }

  validation {
    condition = alltrue([
      for f in values(var.subscription_filters) :
      contains(["ByLogStream", "Random"], coalesce(f.distribution, "ByLogStream"))
    ])
    error_message = "Each distribution must be either ByLogStream or Random."
  }
}
