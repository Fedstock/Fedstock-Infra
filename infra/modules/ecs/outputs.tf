output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "backend_service_name" {
  description = "Backend ECS service name."
  value       = aws_ecs_service.backend.name
}

output "ai_backend_service_name" {
  description = "AI ECS service name."
  value       = try(aws_ecs_service.ai_backend[0].name, null)
}

output "backend_security_group_id" {
  description = "Backend service security group id."
  value       = aws_security_group.backend.id
}

output "ai_backend_security_group_id" {
  description = "AI service security group id."
  value       = try(aws_security_group.ai_backend[0].id, null)
}
