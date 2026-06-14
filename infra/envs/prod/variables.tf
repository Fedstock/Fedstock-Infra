variable "project" {
  description = "Project name used as the prefix for AWS resource names."
  type        = string
  default     = "fl-mlops"
}

variable "env" {
  description = "Deployment environment name."
  type        = string
  default     = "prod"

  validation {
    condition     = var.env == "prod"
    error_message = "This repository is currently configured for prod only."
  }
}

variable "aws_region" {
  description = "AWS region for production infrastructure."
  type        = string
  default     = "ap-northeast-2"
}

variable "aws_account_id" {
  description = "AWS account id allowed for production Terraform operations. Set this in terraform.tfvars."
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12 digit AWS account id."
  }
}

variable "aws_profile" {
  description = "AWS CLI profile used by Terraform."
  type        = string
  default     = "default"
}

variable "availability_zones" {
  description = "Availability zones used by public and private subnets."
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "vpc_cidr" {
  description = "CIDR block for the production VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "allowed_alb_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to access the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Public domain name connected manually through Cloudflare DNS."
  type        = string
  default     = "example.com"
}

variable "existing_certificate_arn" {
  description = "Issued ACM certificate ARN in ap-northeast-2 for the public ALB HTTPS listener."
  type        = string
  default     = null
}

variable "artifact_bucket_name" {
  description = "Optional globally unique S3 artifact bucket name. If null, account id is appended automatically."
  type        = string
  default     = null
}

variable "enable_ai_service" {
  description = "Whether to create and run AI ECS service and ALB AI routing. Keep false when only preparing AI ECR image."
  type        = bool
  default     = false
}

variable "enable_mlops_resources" {
  description = "Whether to create MLOps metadata resources such as DynamoDB tables."
  type        = bool
  default     = false
}

variable "backend_image_tag" {
  description = "Container image tag for the Spring backend service."
  type        = string
  default     = "latest"
}

variable "ai_backend_image_tag" {
  description = "Container image tag for the AI backend service."
  type        = string
  default     = "latest"
}

variable "backend_container_port" {
  description = "Container port exposed by the Spring backend service."
  type        = number
  default     = 8080
}

variable "ai_backend_container_port" {
  description = "Container port exposed by the AI backend service."
  type        = number
  default     = 8000
}

variable "postgres_db_name" {
  description = "Production PostgreSQL database name."
  type        = string
  default     = "app"
}

variable "postgres_username" {
  description = "Production PostgreSQL master username."
  type        = string
  default     = "app"
}

variable "postgres_password" {
  description = "Optional PostgreSQL master password when Secrets Manager is disabled. Keep null when RDS manages the password in Secrets Manager."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_rds_master_user_password" {
  description = "Use RDS-managed AWS Secrets Manager secret for the PostgreSQL master password."
  type        = bool
  default     = true

  validation {
    condition     = var.manage_rds_master_user_password
    error_message = "Fedstock-Infra prod is configured to use AWS Secrets Manager for the RDS master password."
  }
}

variable "rds_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB."
  type        = number
  default     = 20
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.14"
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days."
  type        = number
  default     = 0
}

variable "rds_multi_az" {
  description = "Whether to enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

variable "rds_deletion_protection" {
  description = "Whether to enable deletion protection for RDS."
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip the final snapshot on RDS destroy."
  type        = bool
  default     = false
}

variable "cloudwatch_retention_in_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 30
}

variable "ecs_desired_counts" {
  description = "Desired ECS task counts by service."
  type = object({
    backend    = number
    ai_backend = number
  })
  default = {
    backend    = 1
    ai_backend = 0
  }
}

variable "ecs_task_cpu" {
  description = "Fargate task CPU units by service."
  type = object({
    backend    = number
    ai_backend = number
  })
  default = {
    backend    = 512
    ai_backend = 1024
  }
}

variable "ecs_task_memory" {
  description = "Fargate task memory MiB by service."
  type = object({
    backend    = number
    ai_backend = number
  })
  default = {
    backend    = 1024
    ai_backend = 2048
  }
}

variable "extra_tags" {
  description = "Additional tags merged into every AWS resource."
  type        = map(string)
  default     = {}
}
