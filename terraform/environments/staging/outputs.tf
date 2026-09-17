output "application_public_url" {
  description = "Public URL to access the Staging application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "application_health_url" {
  description = "Public URL to test Staging deep application health check"
  value       = "http://${module.alb.alb_dns_name}/health"
}

output "ecr_repository_url" {
  description = "ECR Repository URL for container image push"
  value       = module.ecr.repository_url
}

output "dynamodb_table_name" {
  description = "Name of the Staging DynamoDB table"
  value       = module.database.table_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name for Staging"
  value       = module.monitoring.cloudwatch_log_group_name
}

output "asg_name" {
  description = "Auto Scaling Group Name for Staging"
  value       = module.asg.asg_name
}
