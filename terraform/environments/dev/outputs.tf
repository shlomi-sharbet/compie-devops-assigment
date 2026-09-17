output "application_public_url" {
  description = "Public URL to access the deployed application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "application_health_url" {
  description = "Public URL to test deep application health check"
  value       = "http://${module.alb.alb_dns_name}/health"
}

output "ecr_repository_url" {
  description = "ECR Repository URL for container image push"
  value       = module.ecr.repository_url
}

output "github_actions_access_key_id" {
  description = "AWS Access Key ID to be configured in GitHub Secrets (AWS_ACCESS_KEY_ID)"
  value       = module.iam.github_actions_access_key_id
}

output "github_actions_secret_access_key" {
  description = "AWS Secret Access Key to be configured in GitHub Secrets (AWS_SECRET_ACCESS_KEY)"
  value       = module.iam.github_actions_secret_access_key
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = module.database.table_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  value       = module.monitoring.cloudwatch_log_group_name
}

output "asg_name" {
  description = "Auto Scaling Group Name"
  value       = module.asg.asg_name
}
