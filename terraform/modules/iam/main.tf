# ==========================================
# 1. CI/CD Identity: Dedicated GitHub Actions IAM User
# ==========================================
# Secure, dedicated IAM user for CI/CD automation.
# Adheres strictly to Least-Privilege, granting ONLY ECR push and ASG Instance Refresh.
resource "aws_iam_user" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions-user"

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-actions-user"
    Environment = var.environment
  }
}

resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}

# CI/CD Least Privilege Policy: Push to ECR & Trigger ASG Refresh ONLY (NO SECRETS ACCESS!)
resource "aws_iam_policy" "github_actions_policy" {
  name        = "${var.project_name}-${var.environment}-github-actions-policy"
  description = "Allows GitHub Actions to push to ECR and trigger ASG Instance Refresh"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages"
        ]
        Resource = var.ecr_repository_arn
      },
      {
        Sid    = "ASGInstanceRefresh"
        Effect = "Allow"
        Action = [
          "autoscaling:StartInstanceRefresh",
          "autoscaling:DescribeInstanceRefreshes",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "github_actions_attach" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

# ==========================================
# 3. Compute Identity: EC2 IAM Role & Profile
# ==========================================
resource "aws_iam_role" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-role"
  description = "IAM Role for EC2 instances in the Auto Scaling Group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Environment = var.environment
  }
}

# Managed Policy: AWS Systems Manager (Zero SSH Access!)
resource "aws_iam_role_policy_attachment" "ssm_managed_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom Least-Privilege Policy for EC2 Application
resource "aws_iam_policy" "ec2_app_policy" {
  name        = "${var.project_name}-${var.environment}-ec2-app-policy"
  description = "Grants EC2 permissions for ECR pull, CloudWatch logs, DynamoDB, and SSM Parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. ECR Pull
      {
        Sid    = "ECRAuth"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = var.ecr_repository_arn
      },
      # 2. CloudWatch Logs
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${var.cloudwatch_log_group_arn}:*"
      },
      # 3. DynamoDB Read & Write
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = var.dynamodb_table_arn
      },
      # 4. SSM Parameter Store Get
      {
        Sid    = "SSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = var.ssm_parameter_prefix_arn
      },
      # 5. KMS Decrypt
      {
        Sid    = "KMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_app_attach" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_app_policy.arn
}

# Instance Profile attached to Launch Template
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-instance-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-instance-profile"
    Environment = var.environment
  }
}
