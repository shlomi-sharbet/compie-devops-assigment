# ==========================================
# ALB Security Group (Public facing)
# ==========================================
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Controls HTTP traffic to the public Application Load Balancer"
  vpc_id      = var.vpc_id

  # Inbound HTTP from entire internet
  ingress {
    description      = "Allow public HTTP traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Inbound HTTPS (ready for SSL/TLS)
  ingress {
    description      = "Allow public HTTPS traffic"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Outbound: allow forwarding traffic strictly to downstream EC2 targets
  egress {
    description = "Forward traffic to application targets"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # Restricted to internal VPC range
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ==========================================
# EC2 Security Group (Private compute - Zero SSH)
# ==========================================
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Allows traffic ONLY from the ALB security group on app port, Zero SSH access"
  vpc_id      = var.vpc_id

  # Strict Inbound rule: ONLY from ALB Security Group
  ingress {
    description     = "Allow traffic strictly from ALB SG"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Outbound rule: HTTPS egress for ECR, SSM, CloudWatch, DynamoDB
  egress {
    description      = "Allow outbound HTTPS for AWS services via NAT Gateway"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # Outbound rule: HTTP egress for OS package updates (dnf/yum)
  egress {
    description = "Allow outbound HTTP for package updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
    Security    = "ZeroSSH-PrivateCompute"
  }
}
