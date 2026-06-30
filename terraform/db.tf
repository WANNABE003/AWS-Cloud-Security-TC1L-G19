resource "random_password" "db_master" {
  length           = 32
  special          = true
  override_special = "!#%+,-.:=?_"
}

resource "random_password" "db_app" {
  length           = 32
  special          = true
  override_special = "!#%+,-.:=?_"
}

resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "db_master_password" {
  name        = "/${local.name}/db/master-password"
  description = "Generated RDS master password"
  type        = "SecureString"
  value       = random_password.db_master.result
}

resource "aws_ssm_parameter" "db_app_password" {
  name        = "/${local.name}/db/app-password"
  description = "Generated least-privilege application DB password"
  type        = "SecureString"
  value       = random_password.db_app.result
}

resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${local.name}/app/jwt-secret"
  description = "Generated JWT signing secret"
  type        = "SecureString"
  value       = random_password.jwt.result
}

resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db-subnets"
  subnet_ids = aws_subnet.database[*].id
  tags       = { Name = "${local.name}-db-subnets" }
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${local.name}-postgres"
  engine                     = "postgres"
  engine_version             = "16"
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  max_allocated_storage      = 20
  storage_type               = "gp2"
  storage_encrypted          = true
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = random_password.db_master.result
  port                       = 5432
  db_subnet_group_name       = aws_db_subnet_group.main.name
  vpc_security_group_ids     = [aws_security_group.database.id]
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 7
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = true
  apply_immediately          = true

  tags = { Name = "${local.name}-postgres" }
}
