output "dynamodb_table_param_arn" {
  description = "ARN of the DynamoDB table name parameter"
  value       = aws_ssm_parameter.db_table.arn
}

output "app_message_param_arn" {
  description = "ARN of the application message parameter"
  value       = aws_ssm_parameter.app_message.arn
}

output "secret_token_param_arn" {
  description = "ARN of the secret token parameter"
  value       = aws_ssm_parameter.secret_token.arn
}

output "ssm_parameter_prefix_arn" {
  description = "Wildcard ARN pattern for the application SSM parameter namespace"
  value       = "arn:aws:ssm:*:*:parameter/${var.project_name}/${var.environment}/*"
}
