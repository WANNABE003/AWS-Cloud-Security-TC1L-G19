// IAM module – creates role for EC2/ECS with Secrets Manager & SSM read access

resource "aws_iam_role" "demo_ec2_role" {
  name = "cloud-security-demo-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "cloud-security-ec2-role"
  }
}

resource "aws_iam_policy" "secrets_ssm_read" {
  name        = "cloud-security-secrets-ssm-read"
  description = "Read DB password from SSM Parameter Store and Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter${var.db_password_ssm_name}"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets" {
  role       = aws_iam_role.demo_ec2_role.name
  policy_arn = aws_iam_policy.secrets_ssm_read.arn
}

output "ec2_role_arn" {
  value = aws_iam_role.demo_ec2_role.arn
}
