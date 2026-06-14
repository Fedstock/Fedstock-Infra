output "name_prefix" {
  description = "Common production resource name prefix."
  value       = local.name_prefix
}

output "aws_region" {
  description = "AWS region used by this environment."
  value       = var.aws_region
}

output "aws_account_id" {
  description = "AWS account id allowed by the provider."
  value       = var.aws_account_id
}

output "common_tags" {
  description = "Common tags applied through the AWS provider."
  value       = local.common_tags
}

output "vpc_id" {
  description = "VPC id."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet ids."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet ids."
  value       = module.network.private_subnet_ids
}

output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "public_domain_name" {
  description = "Public domain name expected to point to the ALB through Cloudflare DNS."
  value       = var.domain_name
}

output "backend_health_url" {
  description = "Backend health check URL after Cloudflare DNS points the domain to the ALB."
  value       = "https://${var.domain_name}/health"
}

output "artifact_bucket_name" {
  description = "S3 artifact bucket name."
  value       = module.s3.artifact_bucket_name
}

output "backend_repository_url" {
  description = "Backend ECR repository URL."
  value       = module.ecr.backend_repository_url
}

output "ai_backend_repository_url" {
  description = "AI Backend ECR repository URL."
  value       = module.ecr.ai_backend_repository_url
}

output "model_version_table_name" {
  description = "Model version DynamoDB table name."
  value       = local.model_table_name
}

output "round_table_name" {
  description = "Round DynamoDB table name."
  value       = local.round_table_name
}

output "participant_update_table_name" {
  description = "Federated learning participant update DynamoDB table name."
  value       = local.participant_update_table_name
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.rds.postgres_endpoint
}

output "postgres_master_user_secret_arn" {
  description = "Secrets Manager secret ARN for the RDS master user."
  value       = module.rds.master_user_secret_arn
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "backend_service_name" {
  description = "Backend ECS service name."
  value       = module.ecs.backend_service_name
}

output "ai_backend_service_name" {
  description = "AI Backend ECS service name."
  value       = module.ecs.ai_backend_service_name
}
