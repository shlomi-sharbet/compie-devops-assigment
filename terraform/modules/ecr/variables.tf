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

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "compie-app"
}
