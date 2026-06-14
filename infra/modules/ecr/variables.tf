variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "image_tag_mutability" {
  description = "ECR image tag mutability."
  type        = string
  default     = "MUTABLE"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
