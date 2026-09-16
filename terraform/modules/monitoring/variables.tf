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

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for metrics"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group for metrics"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group for metrics"
  type        = string
}

variable "alert_email" {
  description = "Placeholder email address for SNS alerts"
  type        = string
  default     = "devops-alerts-placeholder@example.com"
}
