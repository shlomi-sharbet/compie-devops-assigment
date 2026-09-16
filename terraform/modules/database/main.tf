# ==========================================
# DynamoDB Table
# ==========================================
resource "aws_dynamodb_table" "app_table" {
  name         = "${var.project_name}-${var.environment}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Server-Side Encryption with Customer Managed Key (CMK)
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  # Point-in-time recovery for disaster recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-table"
    Environment = var.environment
    Project     = var.project_name
  }
}
