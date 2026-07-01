# AWS Cloud Security Assignment 2
## Secure Migration of a Traditional Application to AWS

**Course:** CCS6344 - Database and Cloud Security  
**Institution:** Multimedia University (MMU)  
**Assignment:** Assignment 2 - Secure Migration to AWS  
**Group:** Group 1

**Live Demo:** https://securestyle.duckdns.org  
**GitHub:** https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19

---

## 📋 Project Overview

This project demonstrates the secure migration of a legacy monolithic application to AWS cloud infrastructure using Infrastructure as Code (Terraform) and cloud-native security best practices.

### Architecture
```
Internet → Internet Gateway → Public Subnet → Security Groups → EC2 (App Tier) → Private Subnet → RDS PostgreSQL
```

### AWS Services Used
- **Compute:** EC2 (t3.micro)
- **Database:** Amazon RDS PostgreSQL (encrypted, not publicly accessible)
- **Networking:** VPC, Subnets, Security Groups, NACLs
- **Security:** IAM, AWS WAF, CloudTrail, CloudWatch
- **Data Protection:** Encryption at rest (AES-256) and in transit (TLS 1.3)

---

## 🧪 Testing Guide

### Part A: Legacy Security Risk Assessment

**Required Testing:** Run the security validation script to verify risks are mitigated.

```bash
# Port Scan - Verify SSH (22) is closed
powershell -Command "Write-Host 'SSH Port 22:' -NoNewline; (Test-NetConnection securestyle.duckdns.org -Port 22 -WarningAction SilentlyContinue).TcpTestSucceeded"

# SQL Injection Test - Verify parameterized queries work
curl -k -X POST https://securestyle.duckdns.org/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"admin@test.com' OR '1'='1\",\"password\":\"test\"}"
# Expected: HTTP 401 Unauthorized

# Rate Limiting - Verify 5 attempts/minute limit
for /L %i in (1,1,10) do curl -k -X POST https://securestyle.duckdns.org/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"test@test.com\",\"password\":\"wrong\"}" -w "Attempt %i: %%{http_code}\n" -o nul
# Expected: Attempt 6+ returns HTTP 429
```

**Expected Results:**
| Risk | Mitigation | Status |
|------|-----------|--------|
| Network Exposure | Security Groups, NACLs | ✅ Verified |
| Privileged Access | IAM roles, no SSH | ✅ Verified |
| Software Vulnerabilities | Parameterized queries, Helmet.js | ✅ Verified |
| Data Protection | RDS/S3 encryption, TLS | ✅ Verified |
| Logging & Monitoring | CloudTrail, CloudWatch | ✅ Verified |
| Rate Limiting | express-rate-limit | ✅ Verified |

---

### Part B: Secure AWS Architecture Design

**Required Testing:** Deploy infrastructure and verify architecture.

```bash
# Verify VPC and subnets exist
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=securestyle-demo-vpc" --region ap-southeast-1

# Verify public subnets
aws ec2 describe-subnets --filters "Name=tag:Name,Values=securestyle-demo-public-*" --region ap-southeast-1

# Verify private database subnets
aws ec2 describe-subnets --filters "Name=tag:Name,Values=securestyle-demo-database-*" --region ap-southeast-1

# Security Group: App tier (no SSH)
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=securestyle-demo-app-*" --region ap-southeast-1 --query 'SecurityGroups[0].{Group:GroupName,Ports:IpPermissions[].{From:FromPort,To:ToPort,Cidr:IpRanges[0].CidrIp}}' --output table

# Security Group: Database tier (restricted)
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=securestyle-demo-db-*" --region ap-southeast-1
```

---

### Part C: Security-Focused Migration Strategy

**Required Testing:** Verify all migration security controls are in place.

```bash
# Verify RDS encryption
aws rds describe-db-instances --db-instance-identifier securestyle-demo-postgres --region ap-southeast-1 --query 'DBInstances[0].[StorageEncrypted,PubliclyAccessible]' --output table
# Expected: StorageEncrypted=true, PubliclyAccessible=false

# Verify S3 encryption
aws s3api get-bucket-encryption --bucket securestyle-demo-audit-* --region ap-southeast-1
# Expected: SSEAlgorithm: AES256

# Verify HTTPS/TLS
curl -k -v https://securestyle.duckdns.org/health 2>&1 | findstr "SSL"
# Expected: TLS connection established

# Verify secrets management (secrets not exposed)
curl -k https://securestyle.duckdns.org/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"test\",\"password\":\"test\"}"
# Expected: No error messages exposing internal details
```

---

### Part D: Secure Implementation on AWS (IaC)

**Required Testing:** Deploy the Terraform code and verify security configurations.

1. **Initialize and apply Terraform:**
```bash
cd terraform
"C:\Installers\Installed\terraform_1.15.7_windows_386\terraform.exe" init
"C:\Installers\Installed\terraform_1.15.7_windows_386\terraform.exe" apply -auto-approve
```

2. **Verify IAM least privilege:**
```bash
aws iam list-attached-role-policies --role-name securestyle-demo-ec2-role --region ap-southeast-1
# Expected: Only AmazonSSMManagedInstanceCore attached

aws iam get-policy-version --policy-arn arn:aws:iam::640122370467:policy/securestyle-demo-ec2-role --version-id v1 --region ap-southeast-1
```

3. **Verify security group rules:**
```bash
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=securestyle-demo-app-*" --region ap-southeast-1
# Expected: Only ports 80, 443, 3000 open to 0.0.0.0/0
```

4. **Verify CloudTrail is active:**
```bash
aws cloudtrail describe-trails --region ap-southeast-1
aws cloudtrail get-trail-status --name securestyle-demo --region ap-southeast-1
```

5. **Test application functionality:**
```bash
# Health check
curl -k https://securestyle.duckdns.org/health
# Expected: {"ok":true,"service":"secure-ecommerce-management-system"}

# Login
curl -k -X POST https://securestyle.duckdns.org/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"customer@securecart.local\",\"password\":\"Password@123\"}"
# Expected: {"user":{"userId":"USR-CUST-001","role":"Customer",...}}

# Access protected endpoint
curl -k https://securestyle.duckdns.org/api/auth/me
# Expected: Not signed in (no cookie)
```

---

### Part E: Security Validation & Reflection

**Required Testing:** Perform at least 3 of the following 4 security tests.

#### Test 1: Port Scanning
```powershell
Write-Host "=== PORT SCAN ===" -ForegroundColor Yellow
$ports = @{22="SSH";80="HTTP";443="HTTPS";3000="App";5432="DB"}
foreach($p in ($ports.Keys | Sort-Object)) {
    $r = Test-NetConnection securestyle.duckdns.org -Port $p -WarningAction SilentlyContinue
    Write-Host "Port $p ($($ports[$p])): $($r.TcpTestSucceeded)" -ForegroundColor $(if($r.TcpTestSucceeded){"Green"}else{"Red"})
}
```
**Expected:** Only ports 80, 443, 3000 = True. Ports 22, 5432 = False.

#### Test 2: WAF Rule Enforcement (SQL Injection)
```bash
curl -k -X POST https://securestyle.duckdns.org/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"admin@test.com' OR '1'='1\",\"password\":\"test\"}"
```
**Expected:** `{"error":"Invalid credentials"}` (HTTP 401)

```bash
# More injection attempts
curl -k -X POST https://securestyle.duckdns.org/api/auth/login -H "Content-Type: application/json" -d "{\"email\":\"admin'; DROP TABLE users; --\",\"password\":\"test\"}"
```
**Expected:** `{"error":"Invalid credentials"}` or `{"error":"Invalid login payload"}`

#### Test 3: CloudTrail Log Verification
```bash
# Check recent API events
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances --max-results 5 --region ap-southeast-1 --query 'Events[*].[EventTime,EventName,Username]' --output table

# Check for login events
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin --max-results 5 --region ap-southeast-1 --query 'Events[*].[EventTime,EventName,Username]' --output table

# Check RDS events
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=CreateDBInstance --max-results 3 --region ap-southeast-1
```

#### Test 4: Encryption Confirmation
```bash
# RDS encryption
aws rds describe-db-instances --db-instance-identifier securestyle-demo-postgres --region ap-southeast-1 --query 'DBInstances[0].[DBInstanceIdentifier,StorageEncrypted,PubliclyAccessible,Engine]' --output table

# S3 encryption  
aws s3api get-bucket-encryption --bucket securestyle-demo-audit-20260701032123316400000001 --region ap-southeast-1

# S3 public access block
aws s3api get-public-access-block --bucket securestyle-demo-audit-20260701032123316400000001 --region ap-southeast-1

# Check EBS encryption
aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=i-0c24edb2ff254ea4a" --region ap-southeast-1 --query 'Volumes[0].[VolumeId,Encrypted]' --output table
```

---

## 🚀 Quick Start

### Prerequisites
- Terraform >= 1.6.0
- AWS CLI v2 configured with credentials
- Git

### Deployment
```bash
git clone https://github.com/WANNABE003/AWS-Cloud-Security-TC1L-G19.git
cd AWS-Cloud-Security-TC1L-G19/terraform
"C:\Installers\Installed\terraform_1.15.7_windows_386\terraform.exe" init
"C:\Installers\Installed\terraform_1.15.7_windows_386\terraform.exe" apply -auto-approve
```

### Application Login Credentials
- **Customer:** customer@securecart.local / Password@123
- **Admin:** admin@securecart.local / Admin@123
- **Inventory Officer:** officer@securecart.local / Officer@123

### Cleanup
```bash
cd terraform
"C:\Installers\Installed\terraform_1.15.7_windows_386\terraform.exe" destroy -auto-approve
```

---

## 📁 Repository Structure

```
├── public/               # Frontend (HTML, JS, CSS)
├── src/                  # Node.js/Express backend
├── sql/                  # PostgreSQL schemas & seed data
├── terraform/            # Infrastructure as Code (IaC)
│   ├── main.tf          # VPC, subnets, NACLs
│   ├── ec2.tf           # EC2 instance
│   ├── db.tf            # RDS PostgreSQL
│   ├── security_group.tf # Security Groups
│   ├── iam.tf           # IAM roles
│   ├── load_balancer.tf # ALB, WAF
│   ├── observability.tf # CloudTrail, CloudWatch, S3
│   └── user_data.sh.tftpl # EC2 bootstrap script
├── report/               # Assignment deliverables
│   └── PartD_IaC/       # Report IaC (to submit on eBwise)
└── docs/                 # Architecture diagrams
```

---

## 🔒 Security Features Implemented

| Category | Controls |
|----------|----------|
| **Network** | VPC isolation, Security Groups, NACLs, No SSH |
| **Compute** | IMDSv2, IAM instance profile, EBS encryption |
| **Database** | RDS encryption, Private subnet, SSL/TLS |
| **Logging** | CloudTrail multi-region, CloudWatch logs |
| **IAM** | Least privilege, Secrets Manager, No hardcoded creds |
| **App** | Rate limiting, SQL injection protection, bcrypt, JWT |
| **Encryption** | AES-256 (RDS, S3, EBS), TLS 1.3 (in transit) |

---

## 👥 Group Members

| Name | Student ID | Role |
|------|-----------|------|
| [Student 1] | 2331101423 | Cloud Architecture & IaC |
| [Student 2] | 2441101424 | Security & Compliance |
| [Student 3] | 2551101425 | Application & Testing |