variable "common_tags" {
  description = "This is to help you add tags to your cloud objects"
  type        = map(any)
}


variable "log_group_name" {
  type    = string
  default = "test_logs"
}

variable "retention" {
  description = "Log retention in days"
  type        = number
  default     = 14
}
