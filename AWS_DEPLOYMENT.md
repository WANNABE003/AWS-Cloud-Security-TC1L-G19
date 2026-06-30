# SecureStyle: localhost to AWS

This project deploys a Node.js application on EC2 and PostgreSQL on encrypted Amazon RDS. The database is isolated in two private subnets; only the application security group can reach port 5432. Administrators use Systems Manager Session Manager, so SSH port 22 is not opened. CloudTrail writes validated management events to a private, encrypted, versioned S3 bucket, and application logs go to CloudWatch.

## Cost modes

The default mode avoids NAT Gateway, load-balancer, and WAF hourly charges. It uses one `t3.micro` EC2 instance, one `db.t3.micro` RDS instance, 8 GiB EBS, and 20 GiB RDS storage. Eligibility depends on the AWS account creation date, remaining credits, region, and usage. A public IPv4 address, S3 log storage, or usage beyond an account's allowance can still create a small bill. Set `alert_email` to create a USD 5 budget alert and always run `terraform destroy` after marking.

Default HTTPS uses a 30-day self-signed certificate, so the browser displays a warning. This encrypts traffic for the classroom demo but does not establish public identity.

The full rubric mode adds an Application Load Balancer, a validated ACM certificate, AWS WAF Common Rules, and an IP rate limit. It is opt-in because WAF is billed per web ACL/rule/request and load-balancer benefits vary by account. Destroy it immediately after recording the demo.

## 1. Test on localhost

Install Node.js 20+, Docker Desktop, and Docker Compose. In PowerShell from the repository root:

```powershell
docker compose down -v
docker compose up --build -d
docker compose ps
powershell -ExecutionPolicy Bypass -File .\scripts\test-api.ps1
```

Open <http://localhost:3000>. Demo users all use `Password@123`:

- `admin@securecart.local`
- `officer@securecart.local`
- `customer@securecart.local`

View logs and stop locally:

```powershell
docker compose logs -f app
docker compose down -v
```

## 2. Prepare AWS and GitHub

Install AWS CLI v2 and Terraform 1.6+. Push this exact code to a public GitHub repository because EC2 clones it during bootstrap. Never commit `.env`, `terraform.tfstate`, or real credentials.

```powershell
aws configure
aws sts get-caller-identity
Copy-Item .\terraform\terraform.tfvars.example .\terraform\terraform.tfvars
notepad .\terraform\terraform.tfvars
```

Change `repository_url`, `repository_branch`, and `alert_email`. Leave `enable_alb` and `enable_waf` false for the lowest-cost deployment.

## 3. Deploy the default free-tier-conscious mode

```powershell
Set-Location .\terraform
terraform init
terraform fmt -check
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform output
$AppUrl = terraform output -raw application_url
```

RDS creation and EC2 bootstrap commonly take 10–20 minutes. Check bootstrap without opening SSH:

```powershell
$InstanceId = terraform output -raw ec2_instance_id
aws ssm start-session --target $InstanceId
```

Inside the SSM session, use:

```bash
sudo tail -n 100 /var/log/securestyle-bootstrap.log
sudo systemctl status securestyle nginx --no-pager
curl http://127.0.0.1:3000/health
exit
```

Back in PowerShell, test AWS (the script accepts the self-signed certificate):

```powershell
powershell -ExecutionPolicy Bypass -File ..\scripts\test-api.ps1 -BaseUrl $AppUrl
Start-Process $AppUrl
```

## 4. Security validation evidence

Run at least three of these and capture screenshots/output for Part E.

Port scan from your own computer (install Nmap first):

```powershell
$PublicIp = ($AppUrl -replace '^https://','')
nmap -Pn -p 22,80,443,3000,5432 $PublicIp
```

Expected: 80 and 443 are reachable; 22, 3000, and 5432 are filtered/closed. In ALB mode, scan the ALB hostname and expect only 80/443.

Confirm RDS and EBS encryption:

```powershell
$DbId = aws rds describe-db-instances --query "DBInstances[?contains(DBInstanceIdentifier, 'securestyle-demo')].DBInstanceIdentifier | [0]" --output text
aws rds describe-db-instances --db-instance-identifier $DbId --query "DBInstances[0].{Encrypted:StorageEncrypted,Public:PubliclyAccessible,MultiAZ:MultiAZ,BackupDays:BackupRetentionPeriod}" --output table
$InstanceId = terraform output -raw ec2_instance_id
$VolumeId = aws ec2 describe-instances --instance-ids $InstanceId --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" --output text
aws ec2 describe-volumes --volume-ids $VolumeId --query "Volumes[0].{Encrypted:Encrypted,Type:VolumeType,Size:Size}" --output table
```

Confirm S3 encryption/public blocking and CloudTrail:

```powershell
$Bucket = terraform output -raw cloudtrail_bucket
aws s3api get-bucket-encryption --bucket $Bucket
aws s3api get-public-access-block --bucket $Bucket
aws cloudtrail get-trail-status --name securestyle-demo
aws cloudtrail lookup-events --max-results 10 --query "Events[].{Time:EventTime,Name:EventName,User:Username}" --output table
```

Application-layer injection test is already included in `test-api.ps1`. With paid WAF mode enabled, also run:

```powershell
curl.exe -i "$AppUrl/?id=1%20OR%201=1"
aws wafv2 list-web-acls --scope REGIONAL --region ap-southeast-1
```

Capture the HTTP 403 and WAF sampled-request/CloudWatch metric in the AWS console.

## 5. Optional full-rubric ALB/WAF mode

Request/validate an ACM certificate for a domain you control, then set `enable_alb = true`, `enable_waf = true`, `certificate_arn`, and `application_domain` in `terraform.tfvars`.

```powershell
terraform plan -out rubric.tfplan
terraform apply rubric.tfplan
terraform output application_url
```

Point the domain's DNS record at the ALB. The raw ALB hostname will serve TLS, but browsers report a name mismatch unless you browse through the certificate's domain name.

## 6. Destroy everything after the demo

```powershell
terraform destroy
```

Type `yes`, then verify the AWS console has no remaining RDS instance, EC2 instance, ALB, WAF web ACL, or project S3 bucket. Terraform state contains generated secrets, so keep it local and private.
