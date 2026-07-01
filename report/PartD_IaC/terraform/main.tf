# Terraform configuration for secure AWS architecture

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ---------- VPC ----------
module "vpc" {
  source          = "./modules/vpc"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = data.aws_availability_zones.available.names
}

# ---------- Security Groups ----------
module "sg" {
  source = "./modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

# ---------- IAM Roles ----------
module "iam" {
  source = "./modules/iam"
}

# ---------- RDS ----------
module "rds" {
  source               = "./modules/rds"
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_username          = var.db_username
  db_password_ssm_name = var.db_password_ssm_name
  db_sg_id             = module.sg.db_sg_id
  kms_key_id           = var.kms_key_id
}


# ---------- ALB & WAF ----------
module "alb" {
  source               = "./modules/alb"
  vpc_id               = module.vpc.vpc_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  security_group_ids   = module.sg.alb_sg_id
  certificate_arn      = var.acm_certificate_arn
}

module "waf" {
  source = "./modules/waf"
  alb_arn = module.alb.alb_arn
}

output "vpc_id" { value = module.vpc.vpc_id }
output "alb_dns_name" { value = module.alb.dns_name }
output "rds_endpoint" { value = module.rds.endpoint }
