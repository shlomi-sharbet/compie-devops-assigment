# ==========================================
# SSM Parameter Store
# ==========================================

# 1. DynamoDB Table Name Parameter
resource "aws_ssm_parameter" "db_table" {
  name        = "/${var.project_name}/${var.environment}/dynamodb_table_name"
  description = "DynamoDB table name used by the application"
  type        = "String"
  value       = var.dynamodb_table_name
  tier        = "Standard" # Free Tier friendly

  tags = {
    Name        = "${var.project_name}-${var.environment}-param-table"
    Environment = var.environment
    Project     = var.project_name
  }
}

# 2. Application Message Parameter
resource "aws_ssm_parameter" "app_message" {
  name        = "/${var.project_name}/${var.environment}/app_message"
  description = "Application custom banner message"
  type        = "String"
  value       = var.app_message
  tier        = "Standard"

  tags = {
    Name        = "${var.project_name}-${var.environment}-param-msg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# 3. Secret Token (KMS-encrypted SecureString)
resource "aws_ssm_parameter" "secret_token" {
  name        = "/${var.project_name}/${var.environment}/secret_token"
  description = "Application internal secret token"
  type        = "SecureString"
  value       = "compie-production-secret-token-demo-xyz123"
  key_id      = var.kms_key_id
  tier        = "Standard"

  tags = {
    Name        = "${var.project_name}-${var.environment}-param-secret"
    Environment = var.environment
    Project     = var.project_name
  }
}
