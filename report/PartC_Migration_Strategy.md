# Part C – Security‑Focused Migration Strategy

**Total Marks: 15**

## Migration Steps
1. **Pre‑Migration Assessment**
   - Run the risk assessment (Part A) and map each risk to an AWS control.
   - Export current database dump (mysqldump / pg_dump) and encrypt it with GPG.
2. **Secure Network Connectivity**
   - Set up a **Site‑to‑Site VPN** or **AWS Direct Connect** between on‑premises network and the new VPC.
   - Restrict VPN access to specific CIDR blocks and use IAM authentication for the AWS side.
3. **Secrets Management**
   - Store DB credentials, API keys, and any third‑party secrets in **AWS Secrets Manager**.
   - Update application config to read secrets via the AWS SDK at runtime.
4. **Data Migration**
   - Transfer the encrypted dump to an S3 bucket using **AWS CLI `s3 cp`** with `--sse AES256`.
   - Use **AWS Database Migration Service (DMS)** to stream data into the newly provisioned RDS instance, with SSL enabled.
5. **Deploy Application Infrastructure**
   - Apply the Terraform IaC (Part D) to create the VPC, subnets, ALB, EC2/ECS, RDS, WAF, IAM roles, and security groups.
   - Deploy the Dockerised web application to the EC2 instances (or ECS) and register it with the ALB target group.
6. **Cut‑over & DNS Switch**
   - Perform a blue‑green deployment: keep the old on‑premises app running while the new AWS version is validated.
   - Update the DNS record (Route 53) to point to the ALB DNS name.
   - De‑commission the on‑premises server after successful validation.
7. **Post‑Migration Hardening**
   - Enable **Amazon GuardDuty** and **AWS Inspector** for continuous threat detection.
   - Configure **CloudTrail** multi‑region logging to an S3 bucket with MFA‑protected delete.
   - Set up **CloudWatch Alarms** for anomalous API calls and failed login attempts.

## Risk‑to‑Control Mapping (excerpt)
| Risk | AWS Control |
|------|--------------|
| Publicly exposed management interfaces | **AWS Systems Manager Session Manager** + **Security Groups** that only allow inbound from VPN CIDR |
| Weak privileged passwords | **IAM Password Policy** + **Secrets Manager** for rotating credentials |
| Unpatched software | **EC2 Image Builder** pipelines to regularly build patched AMIs |
| Plain‑text DB credentials | **Secrets Manager** with automatic rotation |
| No encryption at rest/in‑transit | **RDS encryption**, **S3 SSE**, **TLS** on ALB |
| Insufficient logging | **CloudTrail**, **CloudWatch Logs**, **GuardDuty** |

---
