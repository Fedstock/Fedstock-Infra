variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC id."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet ids for ECS services."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALB security group id."
  type        = string
}

variable "backend_target_group_arn" {
  description = "Backend target group ARN."
  type        = string
}

variable "ai_backend_target_group_arn" {
  description = "AI backend target group ARN."
  type        = string
  default     = null
}

variable "enable_ai_backend" {
  description = "Whether to create AI backend task definition, security group, and ECS service."
  type        = bool
  default     = true
}

variable "backend_repository_url" {
  description = "Backend ECR repository URL."
  type        = string
}

variable "ai_backend_repository_url" {
  description = "AI backend ECR repository URL."
  type        = string
}

variable "backend_image_tag" {
  description = "Backend image tag."
  type        = string
}

variable "ai_backend_image_tag" {
  description = "AI backend image tag."
  type        = string
}

variable "backend_container_port" {
  description = "Backend container port."
  type        = number
}

variable "ai_backend_container_port" {
  description = "AI backend container port."
  type        = number
}

variable "task_execution_role_arn" {
  description = "ECS task execution role ARN."
  type        = string
}

variable "backend_task_role_arn" {
  description = "Backend task role ARN."
  type        = string
}

variable "ai_backend_task_role_arn" {
  description = "AI backend task role ARN."
  type        = string
}

variable "log_group_names" {
  description = "CloudWatch log group names by service."
  type        = map(string)
}

variable "artifact_bucket_name" {
  description = "Artifact bucket name."
  type        = string
}

variable "model_table_name" {
  description = "Model version table name."
  type        = string
}

variable "round_table_name" {
  description = "Round table name."
  type        = string
}

variable "participant_update_table_name" {
  description = "Federated learning participant update table name."
  type        = string
}

variable "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  type        = string
}

variable "postgres_port" {
  description = "RDS PostgreSQL port."
  type        = number
}

variable "postgres_db_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "postgres_username" {
  description = "PostgreSQL username."
  type        = string
}

variable "postgres_password_secret_arn" {
  description = "Secrets Manager secret ARN containing the PostgreSQL password under the password JSON key."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name."
  type        = string
}

variable "public_domain_name" {
  description = "Public domain name for backend-to-AI proxy calls."
  type        = string
}

variable "desired_counts" {
  description = "Desired ECS task counts by service."
  type = object({
    backend    = number
    ai_backend = number
  })
}

variable "task_cpu" {
  description = "Fargate task CPU units by service."
  type = object({
    backend    = number
    ai_backend = number
  })
}

variable "task_memory" {
  description = "Fargate task memory MiB by service."
  type = object({
    backend    = number
    ai_backend = number
  })
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
