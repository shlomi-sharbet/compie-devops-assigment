output "key_arn" {
  description = "ARN of the Customer Managed KMS Key"
  value       = aws_kms_key.main.arn
}

output "key_id" {
  description = "ID of the Customer Managed KMS Key"
  value       = aws_kms_key.main.key_id
}

output "key_alias_arn" {
  description = "ARN of the KMS Key Alias"
  value       = aws_kms_alias.main.arn
}
