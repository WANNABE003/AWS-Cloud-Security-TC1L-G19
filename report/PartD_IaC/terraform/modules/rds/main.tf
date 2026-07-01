// RDS module – creates an encrypted Multi‑AZ PostgreSQL instance with IAM DB auth

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "cloud-security-rds-subnet"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "cloud-security-rds-subnet"
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "cloud-security-db"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t3.medium"
  allocated_storage       = 20
  name                    = "secureapp"
  username                = var.db_username
  password                = data.aws_ssm_parameter.db_password.value
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids  = [var.db_sg_id]
  multi_az                = true
  storage_encrypted       = true
  kms_key_id              = var.kms_key_id
  iam_database_authentication_enabled = true
  skip_final_snapshot     = true
  publicly_accessible     = false
  apply_immediately       = true
  backup_retention_period = 7
  performance_insights_enabled = true
  tags = {
    Name = "cloud-security-rds"
  }
}

# Pull DB password from SSM Parameter Store (expects a SecureString)

data "aws_ssm_parameter" "db_password" {
  name = var.db_password_ssm_name
  with_decryption = true
}

output "endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
}
