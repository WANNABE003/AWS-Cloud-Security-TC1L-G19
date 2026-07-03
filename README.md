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
requirements.txt            Required software and installation checklist
install-requirements.ps1    Installs only missing required software
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

First obtain the project. If Git is already installed:

```powershell
git clone https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19.git
cd .\AWS-Cloud-Security-TC1L-G19
```

If Git is not installed, download the repository ZIP from GitHub, extract it, open PowerShell, and change to the extracted project folder.

### Where to run commands

| Task | Required directory |
|---|---|
| Install required software | Project root: `AWS-Cloud-Security-TC1L-G19` |
| Configure or verify AWS credentials | Any directory |
| Run Terraform commands | `AWS-Cloud-Security-TC1L-G19\terraform` |
| Run the application locally with npm | Project root: `AWS-Cloud-Security-TC1L-G19` |

Required software is listed in [`requirements.txt`](requirements.txt). From the project root, run:

```powershell
cd "C:\path\to\AWS-Cloud-Security-TC1L-G19"
powershell -ExecutionPolicy Bypass -File .\install-requirements.ps1
```

The installer checks Git, Terraform, AWS CLI and Node.js. Existing tools are skipped automatically; only missing tools are installed through `winget`. Close and reopen PowerShell afterward, then verify:

```powershell
git --version
terraform -version
aws --version
node --version
```

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

Change to the Terraform directory before running any Terraform commands:

```powershell
cd "C:\path\to\AWS-Cloud-Security-TC1L-G19\terraform"

Copy-Item .\terraform.tfvars.example .\terraform.tfvars
notepad .\terraform.tfvars
```

Recommended `terraform.tfvars` values:

```hcl
aws_region   = "us-east-1"
project_name = "securestyle"
environment  = "demo"

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

`terraform apply` creates AWS resources and may consume credits or incur charges. With the settings above, resources use names such as `securestyle-demo-app` and `securestyle-demo-postgres`.

If temporary AWS credentials expire, replace the values in `$HOME\.aws\credentials` and run `aws sts get-caller-identity` again.

## Basic verification

After deployment, wait several minutes for EC2 initialization:

```powershell
$AppUrl = terraform output -raw application_url

curl.exe -k -i "$AppUrl/health"
```

Expected health result: HTTP `200 OK`.

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
