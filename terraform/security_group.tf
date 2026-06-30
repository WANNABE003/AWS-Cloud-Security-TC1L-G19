resource "aws_security_group" "alb" {
  count       = var.enable_alb ? 1 : 0
  name_prefix = "${local.name}-alb-"
  description = "Public HTTPS entry point"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP redirect"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "app" {
  name_prefix = "${local.name}-app-"
  description = "Application tier; no SSH ingress"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.enable_alb ? [] : [80, 443]
    content {
      description = "Direct web access in free-tier mode"
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.enable_alb ? [1] : []
    content {
      description     = "Node application only from ALB"
      protocol        = "tcp"
      from_port       = 3000
      to_port         = 3000
      security_groups = [aws_security_group.alb[0].id]
    }
  }

  egress {
    description = "Updates, SSM, RDS, and package installation"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "database" {
  name_prefix = "${local.name}-db-"
  description = "PostgreSQL only from application security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL TLS from application"
    protocol        = "tcp"
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]
  }

  lifecycle { create_before_destroy = true }
}
