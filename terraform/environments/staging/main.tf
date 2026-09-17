# ==========================================
# 1. KMS Module (Customer Managed Key for Staging)
# ==========================================
module "kms" {
  source       = "../../modules/kms"
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================
# 2. VPC Module (Isolated CIDR 10.1.0.0/16, Single NAT GW)
# ==========================================
module "vpc" {
  source               = "../../modules/vpc"
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ==========================================
# 3. Security Groups Module (Least Privilege & Zero SSH)
# ==========================================
module "security" {
  source       = "../../modules/security"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  app_port     = var.app_port
}

# ==========================================
# 4. ECR Repository Module
# ==========================================
module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

# ==========================================
# 5. Database Module (DynamoDB encrypted with KMS CMK)
# ==========================================
module "database" {
  source       = "../../modules/database"
  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.kms.key_arn
}

# ==========================================
# 6. SSM Parameter Store Module
# ==========================================
module "ssm" {
  source              = "../../modules/ssm"
  project_name        = var.project_name
  environment         = var.environment
  dynamodb_table_name = module.database.table_name
  kms_key_id          = module.kms.key_arn
  app_message         = "Welcome to Compie Cloud Solutions DevOps Microservice (STAGING)!"
}

# ==========================================
# 7. Monitoring Module (CloudWatch Logs, Alarms, SNS, Dashboard)
# ==========================================
module "monitoring" {
  source                  = "../../modules/monitoring"
  project_name            = var.project_name
  environment             = var.environment
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  asg_name                = module.asg.asg_name
  alert_email             = var.alert_email
}

# ==========================================
# 8. IAM Module (Dedicated CI/CD User & EC2 Profile)
# ==========================================
module "iam" {
  source                   = "../../modules/iam"
  project_name             = var.project_name
  environment              = var.environment
  github_repo              = var.github_repo
  ecr_repository_arn       = module.ecr.repository_arn
  dynamodb_table_arn       = module.database.table_arn
  kms_key_arn              = module.kms.key_arn
  cloudwatch_log_group_arn = module.monitoring.cloudwatch_log_group_arn
  ssm_parameter_prefix_arn = module.ssm.ssm_parameter_prefix_arn
}

# ==========================================
# 9. ALB Module (Public Load Balancer & Health Checks)
# ==========================================
module "alb" {
  source                = "../../modules/alb"
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  app_port              = var.app_port
}

# ==========================================
# 10. ASG Module (Launch Template, ASG, Instance Refresh, Dynamic Scaling)
# ==========================================
module "asg" {
  source                = "../../modules/asg"
  project_name          = var.project_name
  environment           = var.environment
  aws_region            = var.aws_region
  private_subnet_ids    = module.vpc.private_subnet_ids
  target_group_arn      = module.alb.target_group_arn
  ec2_security_group_id = module.security.ec2_security_group_id
  instance_profile_name = module.iam.instance_profile_name
  ecr_repository_url    = module.ecr.repository_url
  cloudwatch_log_group  = module.monitoring.cloudwatch_log_group_name
  kms_key_arn           = module.kms.key_arn
  instance_type         = "t3.micro"
  min_size              = 1
  desired_capacity      = 2
  max_size              = 3
}
