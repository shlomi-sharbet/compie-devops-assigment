output "instance_profile_name" {
  description = "Name of the EC2 IAM Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 IAM Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "github_actions_user_name" {
  description = "Name of the IAM User for GitHub Actions CI/CD"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_access_key_id" {
  description = "Access Key ID for GitHub Actions CI/CD"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_access_key" {
  description = "Secret Access Key for GitHub Actions CI/CD"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM Role"
  value       = aws_iam_role.ec2.name
}
