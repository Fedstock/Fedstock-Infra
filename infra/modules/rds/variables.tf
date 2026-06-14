variable "name_prefix" {
  description = "Common resource name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC id."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet ids for the DB subnet group."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to PostgreSQL."
  type        = list(string)
}

variable "postgres_db_name" {
  description = "PostgreSQL database name."
  type        = string
}

variable "postgres_username" {
  description = "PostgreSQL master username."
  type        = string
}

variable "postgres_password" {
  description = "PostgreSQL master password."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Whether RDS manages the master password in AWS Secrets Manager."
  type        = bool
  default     = true
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB."
  type        = number
  default     = 20
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "16.14"
}

variable "backup_retention_period" {
  description = "Backup retention period in days."
  type        = number
  default     = 0
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ for RDS."
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
