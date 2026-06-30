output "application_url" {
  description = "Open this URL. Direct mode uses a self-signed classroom certificate."
  value       = var.enable_alb ? "https://${var.application_domain}" : "https://${aws_instance.app.public_ip}"
}

output "ec2_instance_id" {
  description = "Use this with AWS Systems Manager Session Manager; SSH is intentionally closed."
  value       = aws_instance.app.id
}

output "rds_endpoint" {
  description = "Private database endpoint."
  value       = aws_db_instance.postgres.endpoint
}

output "cloudtrail_bucket" {
  description = "Encrypted private S3 bucket containing validated CloudTrail logs."
  value       = aws_s3_bucket.audit.id
}

output "cost_warning" {
  value = var.enable_waf ? "ALB and WAF are enabled and can incur charges. Destroy after the demo." : "Free-tier mode: ALB and WAF are disabled. Confirm account eligibility and destroy when finished."
}
