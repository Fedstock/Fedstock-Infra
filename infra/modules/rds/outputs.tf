output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "RDS PostgreSQL port."
  value       = aws_db_instance.postgres.port
}

output "postgres_security_group_id" {
  description = "RDS PostgreSQL security group id."
  value       = aws_security_group.postgres.id
}

output "postgres_instance_id" {
  description = "RDS PostgreSQL instance id."
  value       = aws_db_instance.postgres.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret ARN for the RDS master user when managed by RDS."
  value       = try(aws_db_instance.postgres.master_user_secret[0].secret_arn, null)
}
