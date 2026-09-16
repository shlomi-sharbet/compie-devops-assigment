data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ==========================================
# Customer Managed Key (CMK)
# ==========================================
resource "aws_kms_key" "main" {
  description             = "CMK for ${var.project_name}-${var.environment} encryption (EBS, SSM, DynamoDB)"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${var.project_name}-${var.environment}-kms-policy"
    Statement = [
      {
        Sid    = "Enable Root Account Full Access"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs and AWS Services"
        Effect = "Allow"
        Principal = {
          Service = [
            "logs.${data.aws_region.current.name}.amazonaws.com",
            "dynamodb.amazonaws.com",
            "ssm.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-kms-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Key Alias
resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}-key"
  target_key_id = aws_kms_key.main.key_id
}
