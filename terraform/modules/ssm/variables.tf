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

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to store in SSM"
  type        = string
}

variable "app_message" {
  description = "Application message text"
  type        = string
  default     = "Welcome to Compie Cloud Solutions DevOps Microservice!"
}

variable "kms_key_id" {
  description = "KMS Key ID/ARN for encrypting SecureString parameters"
  type        = string
}
