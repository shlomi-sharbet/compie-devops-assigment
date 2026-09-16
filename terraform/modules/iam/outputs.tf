output "instance_profile_name" {
  description = "Name of the EC2 IAM Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 IAM Instance Profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM Role for GitHub Actions OIDC"
  value       = aws_iam_role.github_actions.arn
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM Role"
  value       = aws_iam_role.ec2.name
}
