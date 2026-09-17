variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "eu-north-1"
}

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
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "shlomi-sharbet/compie-devops-assigment"
}

variable "app_port" {
  description = "Port on which the application container listens"
  type        = number
  default     = 8000
}

variable "alert_email" {
  description = "Placeholder email address for SNS alerts"
  type        = string
  default     = "devops-alerts-placeholder@example.com"
}
