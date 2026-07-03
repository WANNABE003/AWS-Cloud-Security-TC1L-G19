data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  monitoring                  = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region                = var.aws_region
    db_host                   = aws_db_instance.postgres.address
    db_name                   = var.db_name
    db_username               = var.db_username
    master_password_parameter = aws_ssm_parameter.db_master_password.name
    app_password_parameter    = aws_ssm_parameter.db_app_password.name
    jwt_parameter             = aws_ssm_parameter.jwt_secret.name
    repository_url            = var.repository_url
    repository_branch         = var.repository_branch
    log_group_name            = aws_cloudwatch_log_group.app.name
  })

  user_data_replace_on_change = true

  depends_on = [aws_iam_role_policy.app]

  tags = { Name = "${local.name}-app" }
}
