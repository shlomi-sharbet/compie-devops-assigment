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

variable "kms_key_arn" {
  description = "ARN of the KMS Key for server-side encryption"
  type        = string
}
