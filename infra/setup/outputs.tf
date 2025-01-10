output "cd_user_access_key_id" {
  description = "AWS_key_ ID for CD user"
  value       = aws_iam_access_key.cd.id
}

output "cd_user_acces_key_secret" {
  description = "Access key secret for CD user"
  value       = aws_iam_access_key.cd.secret
  sensitive   = true
}
