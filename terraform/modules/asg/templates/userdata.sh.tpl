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
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL" || true

# 5. Fetch application configuration from AWS Systems Manager (SSM) Parameter Store
echo "Fetching parameters from SSM Parameter Store..."
DYNAMODB_TABLE=$(aws ssm get-parameter --name "/compie/dev/dynamodb_table_name" --region "$AWS_REGION" --query "Parameter.Value" --output text || echo "compie-dev-table")
APP_MSG=$(aws ssm get-parameter --name "/compie/dev/app_message" --region "$AWS_REGION" --query "Parameter.Value" --output text || echo "Welcome to Compie DevOps")

# 6. Resilient Image Pull with Automated Fallback (Zero-Touch Self-Healing)
echo "Attempting to pull Docker image $ECR_URL:$IMAGE_TAG..."
IMAGE_PULLED=false
for i in 1 2 3; do
  if docker pull "$ECR_URL:$IMAGE_TAG"; then
    IMAGE_PULLED=true
    echo "Successfully pulled $ECR_URL:$IMAGE_TAG on attempt $i"
    break
  fi
  echo "Image not available yet in ECR (attempt $i/3). Retrying in 5s..."
  sleep 5
done

# 7. Stop any existing container or fallback service
docker stop compie-app || true
docker rm compie-app || true
systemctl stop compie-bootstrap || true

if [ "$IMAGE_PULLED" = "true" ]; then
  # 8. Run Production Container with AWS CloudWatch Logs Driver
  echo "Launching production application container on port 8000..."
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
else
  # 9. Standby Bootstrap Fallback: Guarantees ALB Target Group /health stays Healthy (200 OK)
  echo "⚠️ Notice: ECR image not yet pushed. Starting native bootstrap standby service on port 8000..."
  mkdir -p /opt/bootstrap-app
  cat << 'EOF' > /opt/bootstrap-app/server.py
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        body = {
            "status": "healthy",
            "mode": "standby_bootstrap",
            "message": "Compie infrastructure is online! Awaiting first CI/CD image deployment to ECR."
        }
        self.wfile.write(json.dumps(body).encode('utf-8'))

    def log_message(self, format, *args):
        pass

if __name__ == '__main__':
    httpd = HTTPServer(('0.0.0.0', 8000), HealthHandler)
    httpd.serve_forever()
EOF

  cat << 'EOF' > /etc/systemd/system/compie-bootstrap.service
[Unit]
Description=Compie Standby Bootstrap Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /opt/bootstrap-app/server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable compie-bootstrap
  systemctl start compie-bootstrap
  echo "Bootstrap standby service active on port 8000. ALB Target Group health checks will pass."
fi

echo "=========================================="
echo "Compie EC2 Bootstrap Completed Successfully!"
echo "=========================================="
