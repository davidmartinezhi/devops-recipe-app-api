output "api_endpoint" {
  value = aws_route53_record.app.fqdn # This extracts the fully qualified domain name ands outputs that when the deployment takes place
}
