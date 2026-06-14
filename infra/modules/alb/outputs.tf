output "alb_dns_name" {
  description = "ALB DNS name."
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ALB ARN."
  value       = aws_lb.this.arn
}

output "alb_security_group_id" {
  description = "ALB security group id."
  value       = aws_security_group.alb.id
}

output "backend_target_group_arn" {
  description = "Backend target group ARN."
  value       = aws_lb_target_group.backend.arn
}

output "ai_backend_target_group_arn" {
  description = "AI backend target group ARN."
  value       = try(aws_lb_target_group.ai_backend[0].arn, null)
}
