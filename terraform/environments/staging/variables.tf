variable "aws_region" {
  description = "AWS region for staging infrastructure"
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
  default     = "staging"
}

variable "github_repo" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "shlomi-sharbet/compie-devops-assigment"
}

variable "vpc_cidr" {
  description = "Dedicated non-overlapping CIDR block for Staging VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnets for Staging"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets for Staging"
  type        = list(string)
  default     = ["10.1.11.0/24", "10.1.12.0/24"]
}

variable "app_port" {
  description = "Port on which the application container listens"
  type        = number
  default     = 8000
}

variable "alert_email" {
  description = "Placeholder email address for SNS alerts"
  type        = string
  default     = "devops-staging-alerts@example.com"
}
