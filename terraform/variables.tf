variable "aws_region" {
  description = "AWS region. Singapore is closest to Malaysia."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Short lowercase name used in resource names."
  type        = string
  default     = "securestyle"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "demo"
}

variable "repository_url" {
  description = "Public Git repository cloned by EC2 during first boot."
  type        = string
  default     = "https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19.git"
}

variable "repository_branch" {
  description = "Git branch to deploy."
  type        = string
  default     = "main"
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "secureecommerce"
}

variable "db_username" {
  description = "RDS master username; its password is generated and stored in SSM."
  type        = string
  default     = "dbadmin"
}

variable "instance_type" {
  description = "EC2 type. Confirm eligibility in your own AWS account before apply."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS type. Confirm eligibility in your own AWS account before apply."
  type        = string
  default     = "db.t3.micro"
}

variable "enable_alb" {
  description = "Adds the rubric load balancer. May incur cost; requires certificate_arn."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Adds AWS WAF to the ALB. WAF is billed; requires enable_alb=true."
  type        = bool
  default     = true
}

variable "enable_multi_az" {
  description = "Enables RDS Multi-AZ standby for high availability. Recommended for production; set false to reduce demo costs."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "Validated ACM certificate ARN for ALB HTTPS. Leave empty in free-tier mode."
  type        = string
  default     = ""
}

variable "application_domain" {
  description = "DNS name covered by the ACM certificate, for example shop.example.com."
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Optional email for a USD 5 monthly AWS Budget alert. Empty disables it."
  type        = string
  default     = ""
}
