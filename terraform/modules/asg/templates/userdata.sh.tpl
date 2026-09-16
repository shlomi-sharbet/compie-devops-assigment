#!/bin/bash
set -xe

# Output all logs to console and to file for debugging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Compie EC2 Bootstrap"
echo "=========================================="

# 1. Update OS and install Docker & AWS CLI
dnf update -y
dnf install -y docker aws-cli

# 2. Start and enable Docker daemon
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# 3. Retrieve Instance Metadata (IMDSv2)
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION="${aws_region}"

echo "Instance ID: $INSTANCE_ID in Region: $AWS_REGION"

# 4. ECR Authentication
ECR_URL="${ecr_url}"
IMAGE_TAG="${image_tag}"

echo "Authenticating to ECR: $ECR_URL..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"

# 5. Fetch application configuration from AWS Systems Manager (SSM) Parameter Store
echo "Fetching parameters from SSM Parameter Store..."
DYNAMODB_TABLE=$(aws ssm get-parameter --name "/compie/dev/dynamodb_table_name" --region "$AWS_REGION" --query "Parameter.Value" --output text || echo "compie-dev-table")
APP_MSG=$(aws ssm get-parameter --name "/compie/dev/app_message" --region "$AWS_REGION" --query "Parameter.Value" --output text || echo "Welcome to Compie DevOps")

# 6. Pull the latest Docker Image
echo "Pulling Docker image $ECR_URL:$IMAGE_TAG..."
docker pull "$ECR_URL:$IMAGE_TAG"

# 7. Stop any existing container (if re-running)
docker stop compie-app || true
docker rm compie-app || true

# 8. Run Application Container with AWS CloudWatch Logs Driver
echo "Launching application container on port 8000..."
docker run -d \
  --name compie-app \
  --restart always \
  -p 8000:8000 \
  -e AWS_REGION="$AWS_REGION" \
  -e AWS_DEFAULT_REGION="$AWS_REGION" \
  -e DYNAMODB_TABLE_NAME="$DYNAMODB_TABLE" \
  -e APP_MESSAGE="$APP_MSG" \
  -e ENVIRONMENT="dev" \
  --log-driver=awslogs \
  --log-opt awslogs-region="$AWS_REGION" \
  --log-opt awslogs-group="${cloudwatch_log_group}" \
  --log-opt awslogs-stream="instance-$INSTANCE_ID" \
  --log-opt awslogs-create-group=false \
  "$ECR_URL:$IMAGE_TAG"

echo "=========================================="
echo "Compie EC2 Bootstrap Completed Successfully!"
echo "=========================================="
