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

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where instances run"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN to attach ASG instances to"
  type        = string
}

variable "ec2_security_group_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM Instance profile name for EC2 instances"
  type        = string
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "cloudwatch_log_group" {
  description = "CloudWatch log group name for docker logs"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN for EBS volume encryption"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (Free Tier friendly)"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum size of ASG"
  type        = number
  default     = 1
}

variable "desired_capacity" {
  description = "Desired capacity of ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum size of ASG"
  type        = number
  default     = 3
}
