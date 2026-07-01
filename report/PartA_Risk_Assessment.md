# Part A – Legacy Security Risk Assessment

**Total Marks: 20**

| # | Risk | Description | Severity (High/Medium/Low) | Justification |
|---|------|-------------|---------------------------|---------------|
| 1 | **Publicly Exposed Management Interfaces** | The on‑premises server runs SSH and remote desktop ports directly exposed to the internet without a bastion host or VPN. | High | Direct remote access increases attack surface; brute‑force and exploitation are easy. |
| 2 | **Privileged Local Accounts with Weak Passwords** | Administrator accounts use default or weak passwords, and password rotation is not enforced. | High | Compromise of a privileged account leads to full system takeover. |
| 3 | **Unpatched Software Vulnerabilities** | The web stack (Apache/Nginx, PHP/Node) runs outdated versions lacking recent security patches. | Medium | Known CVEs can be exploited remotely; patch management is essential. |
| 4 | **Plain‑Text Database Credentials Stored on Disk** | Database connection strings with usernames/passwords are kept in plain text configuration files. | High | Credential leakage leads to data breach; should use a secrets manager. |
| 5 | **No Encryption at Rest or In‑Transit** | Data files and database storage are not encrypted; HTTP traffic is unencrypted. | Medium | Data could be intercepted or leaked if the server is compromised. |
| 6 | **Insufficient Logging & Monitoring** | System logs are not centrally aggregated; no alerting for suspicious activity. | Medium | Delayed detection of breaches; compliance requirements are unmet. |

*Rank the risks by severity and provide a brief justification as shown above.*

---
