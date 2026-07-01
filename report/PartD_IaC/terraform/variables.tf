// Terraform variables for AWS Cloud Security assignment

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "db_username" {
  description = "Username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password_ssm_name" {
  description = "Name of the SSM Parameter that stores the DB password"
  type        = string
  default     = "/cloud-security-demo/db_password"
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS termination"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "KMS Key ID for encrypting RDS storage"
  type        = string
  default     = ""
}



}
