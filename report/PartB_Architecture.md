# Part B – Secure AWS Architecture Design

**Total Marks: 25**

## Architecture Overview
The proposed architecture follows a classic three‑tier, multi‑AZ design with defense‑in‑depth security controls.

```mermaid
flowchart TD
    subgraph VPC["VPC (10.0.0.0/16)"]
        subgraph Public["Public Subnets (AZ1 & AZ2)"]
            ALB["Application Load Balancer (HTTPS)"]
            IGW["Internet Gateway"]
        end
        subgraph Private["Private Subnets (AZ1 & AZ2)"]
            EC2["EC2/ECS Instances (App Tier)"]
            RDS["Amazon RDS (Multi‑AZ) – PostgreSQL"]
        end
    end
    IGW --> ALB
    ALB --> EC2
    EC2 --> RDS
    %% Security controls
    IAM["IAM Roles & Policies"] --> EC2
    WAF["AWS WAF (Web ACL)"] --> ALB
    SG["Security Groups"] --> EC2 & RDS
    NACL["Network ACLs"] --> Private
    CloudTrail["CloudTrail"] --> VPC
    CloudWatch["CloudWatch (Logs, Alarms)"] --> VPC
    S3["S3 (Static Assets, Backups)"] --> EC2 & RDS
```

### Key Services & Justification
- **VPC, Subnets, IGW, NACLs** – Isolate public‑facing load balancer from private application and database tiers.
- **ALB (HTTPS)** – Centralised TLS termination; integrates with WAF.
- **AWS WAF** – Protects against OWASP Top 10 attacks (SQLi, XSS, etc.).
- **EC2/ECS‑Fargate** – Compute for the web application; can be swapped later.
- **Amazon RDS (Multi‑AZ, encrypted)** – Managed relational DB with automated backups and high availability.
- **IAM least‑privilege roles** – Fine‑grained permissions for each component.
- **Amazon S3 (server‑side encryption)** – Stores static assets and backup snapshots.
- **CloudTrail & CloudWatch** – Auditing, logging, and alerting for security events.
- **Encryption at rest & in transit** – KMS‑managed keys for RDS, S3, and TLS for ALB.

---
