output "task_execution_role_arn" {
  description = "ECS task execution role ARN."
  value       = aws_iam_role.task_execution.arn
}

output "backend_task_role_arn" {
  description = "Backend ECS task role ARN."
  value       = aws_iam_role.backend_task.arn
}

output "ai_backend_task_role_arn" {
  description = "AI Backend ECS task role ARN."
  value       = aws_iam_role.ai_backend_task.arn
}
