variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "enable_ai_backend" {
  description = "Whether to create AI backend log group."
  type        = bool
  default     = true
}

variable "retention_in_days" {
  description = "CloudWatch log retention days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
