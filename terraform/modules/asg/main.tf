# ==========================================
# Latest Amazon Linux 2023 AMI
# ==========================================
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ==========================================
# Launch Template
# ==========================================
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  vpc_security_group_ids = [var.ec2_security_group_id]

  # Root EBS volume - encrypted with Customer Managed KMS Key (Bonus requirement)
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 10 # Free Tier friendly (up to 30GB total across account)
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  # Security best practice: IMDSv2 strictly enforced
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(templatefile("${path.module}/templates/userdata.sh.tpl", {
    aws_region           = var.aws_region
    ecr_url              = var.ecr_repository_url
    image_tag            = var.image_tag
    cloudwatch_log_group = var.cloudwatch_log_group
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-${var.environment}-instance"
      Environment = var.environment
      Project     = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# Auto Scaling Group (ASG) with Instance Refresh
# ==========================================
resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.project_name}-${var.environment}-asg-"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  min_size         = var.min_size
  desired_capacity = var.desired_capacity
  max_size         = var.max_size

  # Use ELB health checks so failing HTTP /health marks the instance unhealthy
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Zero-Downtime Rolling Update Strategy
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 180
    }
    triggers = ["tag"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg-node"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# ==========================================
# Dynamic Scaling Policy (Bonus Requirement)
# Target-Tracking Policy: Maintain average CPU at 50%
# ==========================================
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-${var.environment}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
