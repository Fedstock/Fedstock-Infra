variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "artifact_bucket_name" {
  description = "Optional globally unique artifact bucket name."
  type        = string
  default     = null
}

variable "lifecycle_expiration_days" {
  description = "Days before old noncurrent artifact versions expire."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
