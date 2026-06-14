output "backend_repository_url" {
  description = "Backend ECR repository URL."
  value       = aws_ecr_repository.this["backend"].repository_url
}

output "ai_backend_repository_url" {
  description = "AI Backend ECR repository URL."
  value       = aws_ecr_repository.this["ai_backend"].repository_url
}

output "repository_arns" {
  description = "ECR repository ARNs by service."
  value       = { for key, repo in aws_ecr_repository.this : key => repo.arn }
}
