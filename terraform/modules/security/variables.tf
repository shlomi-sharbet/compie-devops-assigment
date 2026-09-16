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

variable "vpc_id" {
  description = "VPC ID where Security Groups will be created"
  type        = string
}

variable "app_port" {
  description = "Port on which the application container listens"
  type        = number
  default     = 8000
}
