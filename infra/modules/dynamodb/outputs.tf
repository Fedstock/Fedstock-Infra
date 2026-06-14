output "model_version_table_name" {
  description = "Model version table name."
  value       = aws_dynamodb_table.model_version.name
}

output "round_table_name" {
  description = "Round table name."
  value       = aws_dynamodb_table.round.name
}

output "participant_update_table_name" {
  description = "Federated learning participant update table name."
  value       = aws_dynamodb_table.participant_update.name
}

output "table_arns" {
  description = "DynamoDB table ARNs."
  value = [
    aws_dynamodb_table.model_version.arn,
    aws_dynamodb_table.round.arn,
    aws_dynamodb_table.participant_update.arn
  ]
}
