# SecureStyle

SecureStyle is a role-based e-commerce management application built with Node.js, Express and PostgreSQL. Terraform deploys it to AWS using EC2, private Amazon RDS, encrypted storage, IAM, SSM Parameter Store, CloudTrail and CloudWatch.

- Live application: https://securestyle.duckdns.org
- Repository: https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19
- Group 19

## Main functions

| Role | Functions |
|---|---|
| Customer | Register, sign in, browse products, manage a cart, place orders and view personal order history |
| Inventory Officer | Add products, update stock, view masked customer information and approve or reject orders |
| Administrator | Manage users and roles, manage products and stock, process orders, view masked customers and review audit logs |

Security features include role-based access control, bcrypt password hashing, signed HTTP-only session cookies, parameterized PostgreSQL queries, input validation, rate limiting, security headers, private RDS access, encryption and centralized AWS logging.

## Project structure

```text
public/                     Frontend
src/                        Node.js/Express backend
sql/postgres_*.sql          PostgreSQL schema, seed data and permissions
terraform/                  AWS Infrastructure as Code
```

Docker is not required. The application runs directly on EC2 behind Nginx.

## Demo accounts

| Role | Email | Password |
|---|---|---|
| Customer | `customer@securecart.local` | `Password@123` |
| Administrator | `admin@securecart.local` | `Password@123` |
| Inventory Officer | `officer@securecart.local` | `Password@123` |

These accounts are for classroom demonstration only.

## How to use the application

1. Open https://securestyle.duckdns.org.
2. Sign in with one of the demonstration accounts.
3. Customer: open **Shop**, add products to the cart and submit an order.
4. Inventory Officer: open **Inventory** to manage stock and **Orders** to approve or reject orders.
5. Administrator: use **Users**, **Inventory**, **Orders** and **Security** to manage the system and view audit evidence.

## First-time AWS deployment

Prerequisites: Git, Terraform 1.6+, AWS CLI v2 and an AWS account with sufficient permissions.

### Configure AWS credentials

Terraform uses the credentials already configured for the AWS CLI. Credentials belong in the user's AWS credentials file, not inside this project or GitHub.

For a personal AWS IAM user with an access key, run:

```powershell
aws configure
```

Enter the access key ID and secret access key when prompted, use `us-east-1` as the default region and `json` as the output format.

For temporary AWS Academy credentials, open the credentials file:

```powershell
New-Item -ItemType Directory -Force "$HOME\.aws"
notepad "$HOME\.aws\credentials"
```

Add the current temporary values supplied by AWS Academy:

```ini
[default]
aws_access_key_id=REPLACE_WITH_CURRENT_ACCESS_KEY
aws_secret_access_key=REPLACE_WITH_CURRENT_SECRET_KEY
aws_session_token=REPLACE_WITH_CURRENT_SESSION_TOKEN
```

Academy credentials expire and must be replaced when a new lab session starts. Verify the active identity before running Terraform:

```powershell
aws sts get-caller-identity
```

Never commit the AWS credentials file, access keys, session tokens, `.env`, `terraform.tfvars`, Terraform state or saved plan files.

```powershell
git clone https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19.git
cd .\AWS-Cloud-Security-TC1L-G19\terraform

Copy-Item .\terraform.tfvars.example .\terraform.tfvars
notepad .\terraform.tfvars
```

Recommended `terraform.tfvars` values:

```hcl
aws_region   = "us-east-1"
project_name = "securestyle"
environment  = "group19"

repository_url    = "https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19.git"
repository_branch = "main"

alert_email = ""
enable_alb  = false
enable_waf  = false
```

Deploy only after reviewing the plan:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan -out deployment.tfplan
terraform apply deployment.tfplan
terraform output
```

`terraform apply` creates AWS resources and may consume credits or incur charges. With the settings above, resources use names such as `securestyle-group19-app` and `securestyle-group19-postgres`.

If temporary AWS credentials expire, replace the values in `$HOME\.aws\credentials` and run `aws sts get-caller-identity` again.

## Basic verification

After deployment, wait several minutes for EC2 initialization:

```powershell
$Region       = "us-east-1"
$AppUrl       = terraform output -raw application_url
$InstanceId   = terraform output -raw ec2_instance_id
$DbEndpoint   = terraform output -raw rds_endpoint
$DbIdentifier = $DbEndpoint.Split(".")[0]

curl.exe -k -i "$AppUrl/health"
```

Expected health result: HTTP `200 OK`.

Run the combined security validation from the repository root:

```powershell
cd ..
powershell -ExecutionPolicy Bypass `
  -File .\scripts\test-security.ps1 `
  -BaseUrl $AppUrl `
  -Region $Region `
  -DbIdentifier $DbIdentifier `
  -InstanceId $InstanceId
```

Expected security results:

- Ports 80 and 443 are open.
- Ports 22, 3000 and 5432 are closed externally.
- Malicious login input is rejected.
- RDS and EBS encryption are enabled.
- RDS is not publicly accessible.
- CloudTrail events are available.

Only test systems that you own or are authorized to test.

## Local development

```powershell
npm install
Copy-Item .\.env.example .\.env
notepad .\.env
npm run check
npm start
```

A reachable PostgreSQL database must be configured in `.env`. Never commit `.env`, AWS credentials, `terraform.tfvars`, Terraform state or saved plan files.

## Cleanup

Run cleanup when the AWS deployment is no longer needed:

```powershell
cd .\terraform
terraform plan -destroy
terraform destroy
```

Review the destruction plan before entering `yes`. This removes the resources managed by the current Terraform state and permanently deletes the classroom database without a final snapshot.
