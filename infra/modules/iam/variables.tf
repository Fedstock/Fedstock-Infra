variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "artifact_bucket_arn" {
  description = "S3 artifact bucket ARN."
  type        = string
}

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs used for MLOps metadata."
  type        = list(string)
}

variable "secrets_manager_secret_arns" {
  description = "Secrets Manager secret ARNs that ECS task execution role can read."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
