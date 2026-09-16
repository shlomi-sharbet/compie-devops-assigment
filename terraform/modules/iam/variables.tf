variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "compie"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo (e.g. shlomi-sharbet/compie-devops-assigment)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS Key"
  type        = string
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch Log Group"
  type        = string
}

variable "ssm_parameter_prefix_arn" {
  description = "ARN prefix for SSM parameters allowed to be read by the EC2 instance"
  type        = string
}
