variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC id."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet ids for the ALB."
  type        = list(string)
}

variable "allowed_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to reach the ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS listener. When null, ALB serves HTTP only."
  type        = string
  default     = null
}

variable "enable_ai_backend" {
  description = "Whether to create AI target group and /ai routing rules."
  type        = bool
  default     = true
}

variable "backend_container_port" {
  description = "Backend target port."
  type        = number
}

variable "ai_backend_container_port" {
  description = "AI backend target port."
  type        = number
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
