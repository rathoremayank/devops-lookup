# Security & DevSecOps: AWS Cloud Security, IaC Security, Pipeline Security, Secrets Management, Authentication & Authorization, Encryption
**Senior DevOps Engineering Study Guide**

---

## 1. Table of Contents

- [1. Table of Contents](#1-table-of-contents)
- [2. Introduction](#2-introduction)
  - [2.1 Overview of Security & DevSecOps](#21-overview-of-security--devsecops)
  - [2.2 Why It Matters in Modern DevOps Platforms](#22-why-it-matters-in-modern-devops-platforms)
  - [2.3 Real-World Production Use Cases](#23-real-world-production-use-cases)
  - [2.4 Where It Appears in Cloud Architecture](#24-where-it-appears-in-cloud-architecture)
- [3. Foundational Concepts](#3-foundational-concepts)
  - [3.1 Key Terminology](#31-key-terminology)
  - [3.2 Architecture Fundamentals](#32-architecture-fundamentals)
  - [3.3 Important DevOps Security Principles](#33-important-devops-security-principles)
  - [3.4 Best Practices Overview](#34-best-practices-overview)
  - [3.5 Common Misunderstandings](#35-common-misunderstandings)
- [4. AWS Cloud Security](#4-aws-cloud-security)
  - [4.1 Principles of AWS Cloud Security](#41-principles-of-aws-cloud-security)
  - [4.2 Shared Responsibility Model](#42-shared-responsibility-model)
  - [4.3 AWS Security Services Overview](#43-aws-security-services-overview)
  - [4.4 Identity and Access Management (IAM)](#44-identity-and-access-management-iam)
  - [4.5 Security Boundaries and Isolation](#45-security-boundaries-and-isolation)
  - [4.6 VPC Isolation Strategies](#46-vpc-isolation-strategies)
  - [4.7 Best Practices for Securing AWS Environments](#47-best-practices-for-securing-aws-environments)
  - [4.8 Common Pitfalls and Mitigation](#48-common-pitfalls-and-mitigation)
- [5. Infrastructure as Code (IaC) Security](#5-infrastructure-as-code-iac-security)
  - [5.1 Principles of IaC Security](#51-principles-of-iac-security)
  - [5.2 Popular IaC Tools and Security Posture](#52-popular-iac-tools-and-security-posture)
  - [5.3 Secure IaC Practices](#53-secure-iac-practices)
  - [5.4 Tfsec and Checkov Scanning](#54-tfsec-and-checkov-scanning)
  - [5.5 Integration into CI/CD Pipelines](#55-integration-into-cicd-pipelines)
  - [5.6 Policy Enforcement for IaC](#56-policy-enforcement-for-iac)
  - [5.7 Best Practices for IaC Security in DevOps](#57-best-practices-for-iac-security-in-devops)
  - [5.8 Common Pitfalls and Mitigation](#58-common-pitfalls-and-mitigation)
- [6. Pipeline Security](#6-pipeline-security)
  - [6.1 Principles of Pipeline Security](#61-principles-of-pipeline-security)
  - [6.2 Securing CI/CD Pipelines](#62-securing-cicd-pipelines)
  - [6.3 Secure Runners and Execution Environments](#63-secure-runners-and-execution-environments)
  - [6.4 Ephemeral Environments and Agents](#64-ephemeral-environments-and-agents)
  - [6.5 Pipeline Isolation Strategies](#65-pipeline-isolation-strategies)
  - [6.6 Popular Pipeline Security Tools](#66-popular-pipeline-security-tools)
  - [6.7 Best Practices for Pipeline Security in DevOps](#67-best-practices-for-pipeline-security-in-devops)
  - [6.8 Common Pitfalls and Mitigation](#68-common-pitfalls-and-mitigation)
- [7. Secrets Management in CI/CD](#7-secrets-management-in-cicd)
  - [7.1 Principles of Secrets Management](#71-principles-of-secrets-management)
  - [7.2 Popular Secrets Management Tools](#72-popular-secrets-management-tools)
  - [7.3 Secure Secrets Handling in CI/CD Pipelines](#73-secure-secrets-handling-in-cicd-pipelines)
  - [7.4 Secret Masking and Obfuscation](#74-secret-masking-and-obfuscation)
  - [7.5 Runtime Injection and Dynamic Secrets](#75-runtime-injection-and-dynamic-secrets)
  - [7.6 Credential Rotation Strategies](#76-credential-rotation-strategies)
  - [7.7 Best Practices for Secrets Management in DevOps](#77-best-practices-for-secrets-management-in-devops)
  - [7.8 Common Pitfalls and Mitigation](#78-common-pitfalls-and-mitigation)
- [8. Authentication & Authorization Models](#8-authentication--authorization-models)
  - [8.1 Principles of Authentication and Authorization](#81-principles-of-authentication-and-authorization)
  - [8.2 Popular Authentication and Authorization Tools](#82-popular-authentication-and-authorization-tools)
  - [8.3 OAuth 2.0 for DevOps Workflows](#83-oauth-20-for-devops-workflows)
  - [8.4 OpenID Connect (OIDC) Integration](#84-openid-connect-oidc-integration)
  - [8.5 SAML Basics and Enterprise Scenarios](#85-saml-basics-and-enterprise-scenarios)
  - [8.6 Implementing Secure Authentication and Authorization](#86-implementing-secure-authentication-and-authorization)
  - [8.7 Best Practices for Authentication & Authorization in DevOps](#87-best-practices-for-authentication--authorization-in-devops)
  - [8.8 Common Pitfalls and Mitigation](#88-common-pitfalls-and-mitigation)
- [9. Encryption Concepts](#9-encryption-concepts)
  - [9.1 Principles of Encryption](#91-principles-of-encryption)
  - [9.2 Popular Encryption Tools](#92-popular-encryption-tools)
  - [9.3 TLS/SSL Fundamentals](#93-tlsssl-fundamentals)
  - [9.4 Certificate Management](#94-certificate-management)
  - [9.5 Encryption at Rest](#95-encryption-at-rest)
  - [9.6 Encryption in Transit](#96-encryption-in-transit)
  - [9.7 Implementing Encryption in DevOps Environments](#97-implementing-encryption-in-devops-environments)
  - [9.8 Best Practices for Encryption in DevOps](#98-best-practices-for-encryption-in-devops)
  - [9.9 Common Pitfalls and Mitigation](#99-common-pitfalls-and-mitigation)
- [10. Hands-on Scenarios](#10-hands-on-scenarios)
- [11. Interview Questions](#11-interview-questions)

---

## 2. Introduction

### 2.1 Overview of Security & DevSecOps

**DevSecOps** represents the integration of security practices into DevOps workflows, embedding security controls at every stage of the software development lifecycle (SDLC) rather than treating security as a post-deployment concern. This encompasses:

- **Proactive threat modeling** during architecture design
- **Automated security scanning** in CI/CD pipelines
- **Infrastructure-as-Code (IaC) security** compliance
- **Secrets management** and credential handling
- **Identity and Access Management (IAM)** frameworks
- **Encryption strategies** for data protection
- **Continuous monitoring and audit logging**

In the context of AWS cloud platforms, DevSecOps combines AWS-native security services with third-party tools to create defense-in-depth architectures that maintain security velocity without sacrificing deployment speed.

### 2.2 Why It Matters in Modern DevOps Platforms

**Security Velocity Trade-off:**
Traditional security approaches create friction in deployment pipelines, forcing DevOps teams to choose between speed and security. DevSecOps reconciles this by:
- Shifting left: Moving security earlier in the SDLC (design, code, build phases)
- Automating compliance checks: Reducing manual security reviews
- Enabling rapid remediation: Detecting and fixing issues before production

**Regulatory and Compliance Drivers:**
- **SOC 2, ISO 27001, PCI-DSS**: Require documented security controls and audit trails
- **AWS Well-Architected Framework**: Mandates security as a core pillar
- **Industry-specific requirements**: Healthcare (HIPAA), Finance (PCI-DSS), Government (FedRAMP)

**Threat Landscape Evolution:**
- Supply chain attacks (compromised dependencies, container images)
- Infrastructure misconfigurations (exposed S3 buckets, overpermissive IAM roles)
- Secrets leakage in code repositories
- Lateral movement through compromised CI/CD runners
- Cloud-native attack vectors (container escape, privilege escalation)

**Business Impact:**
- Breach costs: Average $4.45M per incident (IBM Cost of a Data Breach Report 2023)
- Reputational damage and customer trust erosion
- Operational disruption and recovery costs
- Regulatory fines and legal liability

### 2.3 Real-World Production Use Cases

**Case Study 1: E-Commerce Platform Migration**
A mid-sized e-commerce company migrated to AWS and containerized their microservices. Without DevSecOps:
- Developers stored AWS credentials in Docker image layers
- IaC code (CloudFormation) had hardcoded database passwords
- CI/CD pipeline had no scanning for vulnerable dependencies
- Result: Attackers gained AWS credentials from public Container Registry, escalated to data breach

**DevSecOps Solution:**
- Implemented AWS Secrets Manager for credential rotation
- Integrated Checkov into CI/CD to scan IaC before deployment
- Added container image scanning with ECR image scanning
- Enabled IAM roles for EC2 runners, eliminating credential storage

**Case Study 2: Financial Services Organization**
A regulated financial institution required PCI-DSS compliance for payment processing systems. Challenges:
- No centralized audit logging of infrastructure changes
- Manual security approvals slowing deployment cycles
- Inconsistent encryption configuration across environments
- Risk of non-compliance fines ($5K-$100K per incident)

**DevSecOps Solution:**
- Implemented AWS Config + Config Rules for continuous compliance monitoring
- Automated IaC scanning with policy enforcement (OPA/Kyverno)
- Centralized secrets management with HashiCorp Vault
- Automated encryption enablement across S3, EBS, RDS

**Case Study 3: SaaS Platform with Multi-Tenant Architecture**
A SaaS provider needed to prevent cross-tenant data exposure while maintaining rapid deployment velocity:
- Multi-tenant blast radius: A misconfiguration in one tenant's namespace could expose others
- Secrets sprawl: Each tenant had unique credentials across 50+ microservices
- Compliance requirements: SOC 2 Type II audit

**DevSecOps Solution:**
- Network policies enforced tenant isolation at pod level (Kubernetes)
- Workload identity federation (OIDC) eliminated static credentials
- Automated policy integration using Sentinel/Kyverno
- Continuous compliance scanning with audit trail generation

### 2.4 Where It Appears in Cloud Architecture

**1. Design Phase (Pre-Production)**
- Threat modeling with STRIDE methodology
- Security architecture reviews (CAF framework)
- Compliance requirement mapping
- Risk assessment documentation

**2. Development Phase**
- Pre-commit hooks scanning for secrets
- Static Application Security Testing (SAST) on code commits
- Dependency scanning for known vulnerabilities (OWASP SCA)
- Code review processes with security focus

**3. Build/CI Phase**
- Container image building with minimal base images
- Container image scanning for CVEs
- IaC scanning (Terraform/CloudFormation/Bicep)
- Software composition analysis (SCA)
- Artifact signing and verification

**4. Deployment/CD Phase**
- Policy evaluation before production deployment
- Secure secret injection at runtime
- Immutable infrastructure deployment
- Network policy enforcement
- Compliance policy validation

**5. Runtime/Operations Phase**
- Continuous monitoring with CloudWatch/Security Hub
- Runtime threat detection (CNAPP tools)
- Audit logging and forensic analysis
- Incident response automation
- Security patch management

**6. Decommissioning Phase**
- Secure resource deletion and data wiping
- Audit trail retention for compliance
- Credential revocation

---

## 3. Foundational Concepts

### 3.1 Key Terminology

**Attack Surface**
The sum of all possible points where an unauthorized user can interact with a system. In cloud environments:
- Network interfaces (security groups, NACLs)
- IAM principals (users, roles, service accounts)
- Data stores (databases, object storage)
- Application APIs and endpoints
- Supply chain dependencies

**Defense in Depth**
A security strategy implementing multiple layers of controls so that if one layer is compromised, others still provide protection.

Example layers:
```
Layer 1: Perimeter (VPC, security groups, WAF)
Layer 2: Authentication (MFA, SSO)
Layer 3: Authorization (IAM policies, RBAC)
Layer 4: Encryption (TLS, at-rest)
Layer 5: Monitoring (CloudTrail, GuardDuty)
Layer 6: Incident Response (automated remediation)
```

**Zero Trust Architecture**
Modern security model: "Never trust, always verify." Principles:
- Verify every access request (user, device, context)
- Assume breach: Design assuming attackers are inside
- Least privilege: Grant minimum necessary permissions
- Verify device security posture before access
- Continuous authentication/authorization

**Secrets**
Sensitive credentials needed for system operation:
- Database passwords
- API keys and tokens
- SSH private keys
- TLS certificates
- Encryption keys
- OAuth client secrets

**Security Posture**
The overall security readiness of a system, measured by:
- Compliance with industry standards (SOC 2, ISO 27001)
- Configuration compliance (AWS CIS Benchmarks)
- Vulnerability status (patch level, known CVEs)
- Detection capabilities (logging, monitoring coverage)
- Incident response maturity

**Least Privilege**
Security principle: Grant users/services minimum permissions needed to perform their function.
- Reduces blast radius of compromise
- Simplifies audit and compliance
- Requires continuous review

**Blast Radius**
The scope of damage if a security incident occurs.
- Compromised developer account: Access to all repositories and deployments
- Exposed database passwords: Access to sensitive data
- Overpermissive IAM role: Potential to modify infrastructure

**Threat Model**
Systematic analysis of potential threats to a system using frameworks like STRIDE:
- Spoofing: Identity falsification
- Tampering: Unauthorized modification
- Repudiation: Denying actions were performed
- Information Disclosure: Unauthorized data access
- Denial of Service: Resource unavailability
- Elevation of Privilege: Gaining higher-level access

**Supply Chain Attack**
Attack through dependencies rather than the main target:
- Compromised npm/PyPI packages
- Malicious container images
- Compromised GitHub Actions workflows
- Dependency confusion attacks

**CVSS (Common Vulnerability Scoring System)**
Standardized metric for severity (0.0-10.0):
- 0.0: None
- 0.1-3.9: Low
- 4.0-6.9: Medium
- 7.0-8.9: High
- 9.0-10.0: Critical

**SBOM (Software Bill of Materials)**
Inventory of components, libraries, and dependencies used in software.
- Enables vulnerability tracking
- Supports compliance requirements
- Enables rapid incident response

---

### 3.2 Architecture Fundamentals

**Security Architecture Layers**

```
┌─────────────────────────────────────────────────────┐
│  User/Application Layer                             │
│  (Authentication, Authorization, API calls)         │
├─────────────────────────────────────────────────────┤
│  Transport/Network Layer                            │
│  (TLS, VPN, Network policies)                       │
├─────────────────────────────────────────────────────┤
│  Infrastructure Layer                               │
│  (IAM, Security Groups, Encryption, Monitoring)     │
├─────────────────────────────────────────────────────┤
│  Physical/Cloud Provider Layer                      │
│  (AWS data centers, hardware security)              │
└─────────────────────────────────────────────────────┘
```

**Trust Boundaries**
Conceptual boundaries where data changes trust context:
- Moving from untrusted to trusted network (e.g., DMZ to internal)
- Transitioning between security zones
- Crossing application boundaries
- Entering/exiting cloud infrastructure

Requires:
- Input validation
- Authentication/authorization verification
- Encryption for data in transit
- Audit logging

**Blast Radius Isolation**
Architectural techniques to limit compromise scope:

| Technique | Implementation | Benefit |
|-----------|-----------------|---------|
| Network Segmentation | Security groups, NACLs, VPC separation | Limits lateral movement |
| Service Isolation | Containerization, dedicated IAM roles | Blast radius per service |
| Data Segregation | Encryption, ABAC policies | Protects sensitive datasets |
| Temporal Isolation | Ephemeral infrastructure | Reduces persistence window |
| Privilege Separation | IAM role boundaries | Prevents privilege escalation |

**Cloud Security Shared Responsibility**

```
AWS Responsibility (Security OF the Cloud):
├── Physical infrastructure security
├── Hardware management
├── Facility access control
├── Network infrastructure
└── Hypervisor security

Customer Responsibility (Security IN the Cloud):
├── IAM configuration
├── Security groups and NACLs
├── Encryption (keys, at-rest, in-transit)
├── Application security
├── Data classification and handling
├── Patching (OS, applications)
├── Monitoring and logging
└── Incident response
```

**Encryption Models**

```
At Rest:
├── Server-Side Encryption (SSE)
│   ├── SSE-S3 (AWS-managed keys)
│   ├── SSE-KMS (customer-managed keys via AWS KMS)
│   └── SSE-C (customer-provided keys)
├── Transparent Data Encryption (TDE) - Databases
└── Client-Side Encryption (before upload)

In Transit:
├── TLS 1.2/1.3 for transport layer
├── VPN for site-to-site connectivity
├── Certificate pinning for critical connections
└── Perfect Forward Secrecy (PFS) for key exchange
```

**Identity and Access Management (IAM) Hierarchy**

```
AWS Account Root User (Unrestricted)
├── IAM Users (Human identities)
│   └── Permissions via Policies
├── IAM Roles (Assumed by services/resources)
│   └── Permissions via Policies
├── Federated Users (External identity providers)
│   └── Mapped via Identity Federation
└── Cross-Account Roles (Access from other accounts)
```

---

### 3.3 Important DevOps Security Principles

**1. Shift Left Principle**
Move security earlier in the SDLC:

```
Traditional (Shift Right):
Code → Build → Deploy → Test → Security Review (Late!) → Remediate

Shift Left:
Design → Code (Pre-commit scan) → Build (SAST/SCA) → 
Scan (Container/IaC) → Deploy (Policy check) → Runtime (Monitor)
```

**Benefits:**
- Faster feedback on security issues
- Lower remediation cost (fix in code vs. production)
- Prevents vulnerable code from reaching production
- Enables continuous security

**2. Defense in Depth**
Multiple overlapping security controls:

```
Threat Scenario: Attacker gains AWS credentialsfrom exposed secret in GitHub

Defense Layer 1: Prevent
├── Pre-commit scanning for secrets (TruffleHog)
├── GitHub secret scanning detection
└── Developer education on secrets management

Defense Layer 2: Detect
├── CloudTrail logging of credential usage
├── GuardDuty anomaly detection
└── Secret exposure notifications

Defense Layer 3: Respond
├── Automated credential rotation
├── Alert and human investigation
└── Infrastructure changes via audit trail

Defense Layer 4: Recover
├── Damage assessment via CloudTrail
├── Revocation of exposed credentials
└── Incident post-mortem and improvements
```

**3. Least Privilege Access**
Every principal gets minimum permissions needed:

```
❌ Overprivileged:
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}

✅ Least Privilege:
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::production-data/*",
    "arn:aws:s3:::production-data"
  ]
}
```

**4. Zero Trust Architecture**
Never assume trust; verify every access:

```
Traditional Perimeter Model (Outdated):
Outside World ──(No Trust)──┤ Firewall ├──(Implicit Trust)──> Internal Systems

Zero Trust Model:
All Access ──(Verify)──> Identity ──(Verify)──> Device Posture ──(Verify)──> 
Authorization ──(Verify)──> Resource Access ──(Continuous Monitor)──> 
Behavior Analysis
```

**5. Encryption-First Approach**
Data is encrypted by default, everywhere:

```
Data Classification:
├── Public: No encryption strictly required
├── Internal: Encryption in transit (TLS)
├── Confidential: Encryption at-rest + in-transit
└── Restricted: Customer-managed encryption keys + auditing

Implementation:
├── Enable default encryption (S3, EBS, RDS)
├── Enforce TLS 1.2+ for all connections
├── Manage encryption keys with AWS KMS
└── Rotate keys regularly
```

**6. Assume Breach Mentality**
Design systems assuming attackers have breached one component:

```
Attacker has:
├── Junior developer's AWS access key from laptop
├── Production database credentials from Secrets Manager
├── Container runner environment variable
└── Kubernetes service account token

System should still prevent:
├── Cross-account access (isolation)
├── Data exfiltration (segmentation, encryption)
├── Lateral movement (network policies)
├── Privilege escalation (RBAC, admission control)
```

**7. Continuous Monitoring and Visibility**
Real-time security posture assessment:

```
Data Sources:
├── CloudTrail: All API calls
├── CloudWatch: Application/infrastructure logs
├── VPC Flow Logs: Network traffic patterns
├── GuardDuty: Threat detection ML
├── Security Hub: Compliance findings (CIS, PCI-DSS, etc.)
└── Config: Configuration compliance monitoring

Analysis:
├── Baseline normal behavior
├── Detect deviations (anomalies)
├── Correlate events across sources
└── Trigger automated remediation

Alerts:
├── Unknown principal accessing production
├── Root account usage
├── Bulk data exfiltration
├── Failed authentication brute-force
└── Compliance violation detected
```

**8. Immutability and Auditability**
Changes are logged, traced, and cannot be undone without evidence:

```
✅ Auditable:
Code Change → Git Commit (Author, Time, Diff) → 
Code Review (Approver) → Build (Artifact Hash) → 
Deployment (Who, When, Which revision) → 
Changes in CloudTrail/Config

❌ Non-Auditable:
SSH into server → Manual configuration changes → 
No logs of who changed what or why
```

**9. Supply Chain Security**
Secure dependencies and build artifacts:

```
Dependency Risk Management:
├── Scan open-source components for known CVEs (SCA)
├── Verify integrity of downloaded packages
├── Pin versions to prevent supply chain confusion
├── Audit transitive dependencies
├── Monitor for security announcements
└── Have remediation process for vulnerable dependencies

Artifact Security:
├── Sign build artifacts cryptographically
├── Verify signatures before deployment
├── Scan container images for vulnerabilities
├── Implement image admission control (registry policy)
└── Track artifact provenance (SBOM, build logs)
```

**10. Compliance as Code**
Automate compliance checking:

```
Policy Example - "No public RDS databases":
resource "aws_db_instance" "example" {
  # ✅ COMPLIANT: publicly_accessible = false
  publicly_accessible = false
}

Automated Scanning:
├── Pre-commit: Local policy checks
├── Build: Tfsec/Checkov in CI/CD
├── Deploy: OPA/Kyverno enforce policies
├── Runtime: Config Rules continuous monitoring
├── Report: Compliance dashboard and audit logs
```

---

### 3.4 Best Practices Overview

#### 3.4.1 Account and Credential Management

**AWS Account Strategy:**
- **Master/Root Account**: Billing only, minimal access
- **Shared Services Account**: Centralized logging, DNS, VPC peering
- **Development Account**: For development and testing
- **Staging Account**: Production-like environment
- **Production Account**: Isolated production workloads
- **Security Account**: Centralized security tools and audit logs

**Rationale:**
- Constrains blast radius: Compromise of dev account doesn't affect production
- Enforces separation of duties: Different teams, different accounts
- Simplifies compliance: Audit trail per environment
- Enables cross-account monitoring: Centralized security visibility

**Credential Management Best Practices:**
```
❌ Anti-Patterns:
├── Long-lived IAM access keys for humans
├── Credentials hardcoded in applications
├── Shared credentials across multiple persons/services
├── Credentials stored in version control
└── Manual credential rotation

✅ Best Practices:
├── Use IAM roles with temporary credentials (15-60 minute expiration)
├── Use SSO (AWS SSO/IdP integration) for human access
├── Service-to-service: Use workload identity (OIDC, IAM roles)
├── Secrets Manager for application credentials (auto-rotation)
├── Audit credential usage via CloudTrail
└── Implement credential rotation policies (quarterly for manual)
```

#### 3.4.2 Network Security

**VPC and Network Segmentation:**
```
Classic Flat Network (Deprecated):
┌───────────────────────┐
│ All Resources in One  │
│ Security Group        │
│ Single Blast Radius   │
└───────────────────────┘

Segmented Network (Best Practice):
┌──────────────────────────────────┐
│ VPC                              │
├──────────────────┬───────────────┤
│ Public Subnet    │ Private       │
│ (Load Balancer)  │ Subnet        │
│ (Bastion)        │ (Applications)│
├──────────────────┼───────────────┤
│ Database Subnet  │ Reserved      │
│ (RDS, ElastiCache)               │
└──────────────────────────────────┘
```

**Network Policy Rules:**
1. Default deny: Nothing allowed unless explicitly permitted
2. Explicit ingress rules: Only required ports/protocols
3. Explicit egress rules: Only required destinations
4. Regular audit: Review rules quarterly

**Example:**
```
Incorrect (Overly Permissive):
├── Security Group: Allow 0.0.0.0/0:443 (HTTPS from anywhere)
├── Database security group: Allow 0.0.0.0/0:3306 (accessible from internet)
└── Result: Potential unauthorized database access

Correct (Segmented):
├── ALB security group: Allow 0.0.0.0/0:443 (public internet)
├── App security group: Allow ALB-SG:8443 only (app port from ALB)
├── DB security group: Allow APP-SG:3306 only (database from app)
└── Result: Traffic flows through layers; blocked at each boundary
```

#### 3.4.3 Identity and Access Management (IAM)

**IAM Policy Structure:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadProductionDataOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::production-data",
        "arn:aws:s3:::production-data/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        },
        "IpAddress": {
          "aws:SourceIp": "10.0.0.0/8"
        }
      }
    }
  ]
}
```

**Policy Review Checklist:**
- [ ] Principle of least privilege: Minimum necessary permissions?
- [ ] Resource scoping: Specific ARNs or wildcards?
- [ ] Conditions: IP restrictions, time-based, region-based?
- [ ] Effect: Allow or Deny (explicit deny takes precedence)?
- [ ] Actions: Specific or wildcards affecting security?
- [ ] Cross-account access: Is trust relationship necessary?

#### 3.4.4 Monitoring and Logging

**What to Log:**
```
API Calls (CloudTrail):
├── Who: Principal identity (user, role, service)
├── What: API action (CreateUser, ModifyDB, etc.)
├── When: Timestamp
├── Where: Source IP, user agent
├── Why: RequestParameters showing intent
└── Result: Success/failure and response

Application/Workload Logs:
├── Authentication events (login, MFA)
├── Authorization decisions (access granted/denied)
├── Data access (who accessed what data)
├── Configuration changes
├── Error conditions and exceptions
└── Security event (suspicious patterns)
```

**Log Retention and Analysis:**
- **Compliance requirement**: Usually 1-7 years retention
- **Implementation**: S3 with lifecycle policies, Glacier for long-term
- **Analysis**: CloudWatch Logs Insights, Athena, third-party SIEM
- **Alerting**: Real-time notifications for critical events

#### 3.4.5 Encryption

**Encryption Key Management:**
```
AWS KMS Best Practices:
├── Separate keys for different purposes (data, encryption, signing)
├── Key rotation (annual for customer-managed keys)
├── Key policies restrict who can administer keys
├── Audit key usage via CloudTrail
├── Never store key material outside KMS
└── Use envelope encryption for high-volume operations

Key Hierarchy:
├── Master Key (KMS CMK): Never leaves AWS data centers
├── Data Encryption Key (generated from Master Key)
├── Plaintext data encrypted with Data Key
├── Encrypted data key stored with encrypted data
└── Only KMS can decrypt data key (requires IAM permission)
```

**Encryption Standards:**
- **TLS**: Use 1.2 or higher (1.3 preferred)
- **Algorithms**: AES-256 for symmetric, RSA-2048+ for asymmetric
- **Certificate**: Valid, not self-signed, in production
- **Perfect Forward Secrecy (PFS)**: Session keys not recoverable even if long-term key compromised

---

### 3.5 Common Misunderstandings

#### Misunderstanding 1: "Security is the sole responsibility of the security team"

**Reality:**
Security is a shared responsibility across the entire organization.

| Role | Responsibility |
|------|-----------------|
| Developers | Secure coding, dependency scanning, input validation |
| DevOps | Secure infrastructure, automation, monitoring |
| Security Team | Policy, governance, incident response |
| Management | Resource allocation, risk acceptance |
| Operations | Patching, configuration, monitoring |

**Implication for DevSecOps:**
Developers must understand security implications of their code.
DevOps must shift security left, not wait for security team approval.

#### Misunderstanding 2: "Encryption alone provides security"

**Reality:**
Encryption protects data confidentiality, not availability or integrity (without additional measures).

```
Encryption Limitations:
├── Doesn't prevent unauthorized access if keys are compromised
├── Doesn't protect against DDoS attacks (data still delivered)
├── Doesn't validate data integrity (needs HMAC or signatures)
├── Overhead: Performance impact for encryption/decryption
├── Operational burden: Key management complexity

Encryption-Only Example (Insufficient):
├── RDS database encrypted ✓
├── But IAM allows public database access ✗
├── Attacker connects, encrypted connection to database ✗
├── Data is readable (they decrypted with database password)
```

**Correct Approach:**
Encryption is one layer of defense; combine with:
- Strong authentication credentials (not publicly known)
- Network segmentation (VPC isolation, security groups)
- Access controls (IAM policies, resource-based policies)
- Monitoring (who's accessing the encrypted data?)

#### Misunderstanding 3: "Compliance = Security"

**Reality:**
Compliance is meeting minimum regulatory requirements; security is a continuous process.

```
Compliance Checklist (One-Time):
├── [ ] Enable encryption
├── [ ] Implement IAM roles
├── [ ] Enable logging
└── Audit passes ✓

But Missing Security:
├── No monitoring of logs (logging but not checking)
├── No incident response process
├── No security training
├── No vulnerability scanning
├── No threat modeling
```

**Consequence:**
Organizations can be "compliant on paper" but still be breached because they don't actively detect/respond to threats.

#### Misunderstanding 4: "Secrets should be version controlled"

**Reality:**
Secrets must NEVER be in version control (Git, GitHub, GitLab).

```
Why This is Catastrophic:
├── Secrets are in git history forever (even after deletion)
├── Every clone copies all secrets
├── Developers see each other's private credentials
├── Secrets can be extracted by anyone with repository access
├── Secret scrubbing tools only partially effective
├── Public repositories expose secrets to everyone
└── One compromised developer machine exposes all secrets

Example Incident:
Developer commits AWS credentials to GitHub
→ Attacker finds credentials via GitHub search
→ Uses credentials to launch EC2 instances for crypto mining
→ $50K+ AWS charges

Prevention:
├── Use pre-commit hooks scanning for secrets (TruffleHog)
├── Use external secret stores (Secrets Manager, Vault)
├── Educate developers on secrets handling
└── Rotate credentials immediately if exposed
```

#### Misunderstanding 5: "Long-lived credentials are acceptable with IAM permissions"

**Reality:**
Long-lived credentials increase compromise window and blast radius.

```
Risk Analysis:

Long-lived Credentials (1 year):
├── Larger window if compromised
├── Hardcoded in applications
├── Difficult to rotate without downtime
├── Potential exposure in backups, logs, etc.
└── Blast radius: Large until discovered

Short-lived Credentials (15 minutes - 1 hour) via IAM Roles:
├── Automatically rotated
├── Cannot be hardcoded (self-service refresh)
├── Limited window if compromised
├── Audit trail of every credential issued
└── Blast radius: Automatically reduced
```

**Implementation:**
- Humans: Use SSO with temporary credentials
- Services: Use IAM roles, not access keys
- CI/CD: Use OIDC for GitHub Actions, assume roles dynamically

#### Misunderstanding 6: "Network security alone provides sufficient protection"

**Reality:**
Network security is important but not sufficient (assume breach).

```
Scenario:
Attacker compromises developer laptop with VPN access
├── They're now "inside the network" (network security passed)
├── But they need access to specific systems/data
├── Network firewall doesn't authenticate to databases
├── IAM policies don't authenticate to web apps
└── Application-layer authentication still required

Layered Defense:
├── Network: VPC, security groups, NACLs
├── Identity: IAM, MFA, role assumption
├── Encryption: TLS, at-rest encryption
├── Application: Authentication, authorization, input validation
├── Monitoring: Detect lateral movement attempts
```

#### Misunderstanding 7: "Secrets rotation isn't critical if keys are secure"

**Reality:**
Keys are compromised despite security; rotation reduces impact.

```
Scenarios Requiring Rotation:
├── Insider threat: Disgruntled employee leaves
├── Suspected compromise: Unauthorized access detected
├── Stolen credentials: Credentials found in public repository
├── Regular rotation: Quarterly for administrative access
├── Key exposure: Logged in debug output, captured in screenshot
└── Regulatory requirement: Some compliance frameworks mandate rotation

Rotation Strategy:
├── Automatic (preferred): Database, Secrets Manager, GSM (0 downtime)
├── Planned rotation: Out-of-band credentials during maintenance window
├── Emergency rotation: Immediate revocation if compromise detected
└── Audit trail: Who rotated keys, when, and why
```

#### Misunderstanding 8: "IaC scanning at build time is sufficient"

**Reality:**
Infrastructure changes at runtime; only scanning at build time misses drift.

```
Build-Time Scanning (Good):
├── Terraform plan checked for security issues
├── Checkov finds hardcoded secrets
└── Bad config rejected before deployment

But Runtime Drift (Bad):
├── Manual change in AWS Console
├── Security group rule modified without IaC change
├── Encryption disabled directly in RDS
├── Config drift undetected
└── Runtime state != IaC code

Solution: Continuous Compliance Monitoring:
├── AWS Config Rules: Continuous monitoring of configuration
├── Config Aggregator: Multi-account, multi-region view
├── OPA/Kyverno: Kubernetes runtime policy enforcement
├── GuardDuty: ML-based threat detection
└── Automated remediation: Revert to compliant state
```

#### Misunderstanding 9: "Role-based access control (RBAC) is outdated"

**Reality:**
RBAC is still useful; attribute-based access control (ABAC) is more flexible but not always necessary.

```
RBAC (Role-Based):
├── Grant permissions to a role (e.g., "developer", "admin")
├── User assumes the role
├── Simple, but limited granularity
└── Example: All admins get identical permissions

ABAC (Attribute-Based):
├── Grant permissions based on attributes (tags, department, project)
├── More flexible: Conditional access based on metadata
├── Harder to manage initially but scales better
└── Example: All staff in "fintech" department, with AWS tag environment=prod

Modern Approach:
├── Use RBAC for role-level access (developer, admin)
├── Use ABAC for environment/resource filtering (prod vs. dev)
├── Use conditions for time-based, IP-based restrictions
└── Combine for flexibility and simplicity
```

#### Misunderstanding 10: "IAM policy evaluation is straightforward"

**Reality:**
IAM policy evaluation is complex with multiple policy types and evaluation logic.

```
IAM Policy Types:
├── Identity-based policies: Attached to user/role
├── Resource-based policies: Attached to resources (S3, SQS, etc.)
├── Session policies: Applied when assuming a role
├── Permissions boundaries: Maximum permissions a principal can have
└── Organization Control Policies (SCPs): Applied across accounts

Evaluation Logic:
1. Explicit Deny: Overrides everything (circuit breaker)
2. Permissions Boundary: Maximum allowed
3. Identity-based policy: What principal is allowed
4. Resource-based policy: What resource allows
5. Result: Intersection of all applicable policies

Example Confusion:
Issue: Developer claims they can't list S3 buckets
Analysis:
├── Identity policy: s3:ListAllMyBuckets allowed ✓
├── Resource policy: Not applicable for this action ✓
├── Session policy: Admin access granted ✓
├── But S3 Console Error: "Not Authorized"
Cause:
├── EC2 instance has IAM role with limited permissions
├── Developer is using EC2 instance credentials (assumed role)
└── Role doesn't have ListBucket permission
Solution:
├── Update EC2 role permissions
├── Or use personal IAM credentials with correct permissions
```

---

## 4. AWS Cloud Security

### 4.1 Principles of AWS Cloud Security

**Internal Working Mechanism:**

AWS cloud security operates on a layered model where AWS provides infrastructure security while customers implement security within their deployed resources:

1. **Physical Security Layer**: AWS operates highly secure data centers with multi-factor access controls, video surveillance, and intrusion detection systems. Customers cannot directly influence this but can audit through compliance reports.

2. **Virtual Infrastructure Layer (Hypervisor)**: AWS uses Xen hypervisor to isolate EC2 instances. Each instance runs in a separate security domain; compromise of one instance cannot directly affect others on the same server.

3. **Network Layer**: Security groups (stateful firewall) and network ACLs (stateless firewall) provide network segmentation. VPCs provide logical isolation of networks.

4. **Storage Layer**: EBS volumes are encrypted separately from the hypervisor; S3 implements bucket policies and access controls independent of compute.

5. **Identity Layer**: IAM enforces authentication and authorization for all AWS API calls before they reach resources.

6. **Application Layer**: Application-level security (TLS, input validation) remains customer responsibility.

**Architecture Role:**

AWS security fundamentally enables:
- **Multi-tenancy with isolation**: Hundreds of thousands of customers share AWS infrastructure without accessing each other's data
- **Auditability**: Every API call logged in CloudTrail
- **Compliance enablement**: Services support SOC 2, ISO 27001, HIPAA, PCI-DSS requirements
- **Security at scale**: Security controls applied consistently across global infrastructure
- **Rapid patching**: AWS can patch hypervisor without customer action

**Production Usage Patterns:**

```
Enterprise Production Deployment:

1. Organizational Setup
├── Root account created (locked down, billing only)
├── Multiple member accounts (dev, staging, prod, security)
├── AWS Organizations for policy enforcement
├── Centralized logging account for CloudTrail
└── Centralized security account for GuardDuty, Security Hub

2. Per-Account Setup
├── Enable CloudTrail (all regions, multi-account)
├── Enable GuardDuty (threat detection)
├── Enable Security Hub (compliance monitoring)
├── Configure Config Rules (continuous monitoring)
└── Setup CloudWatch alarms (critical events)

3. Workload Deployment
├── VPC with public/private subnets
├── ALB in public subnet (TLS termination)
├── Applications in private subnets (no direct internet access)
├── RDS in database subnets (multi-AZ)
├── Encryption: S3 (KMS), RDS (KMS), EBS (KMS)
└── IAM roles with least-privilege policies
```

**DevOps Best Practices:**

1. **Least Privilege IAM**: Every principal (user, service, role) gets minimum permissions needed
2. **MFA Enforcement**: Interactive users require MFA; detected via CloudTrail
3. **Encryption Defaults**: Enable KMS encryption for all data stores by default
4. **Network Segmentation**: Private subnets for workloads; public only for load balancers
5. **Centralized Logging**: CloudTrail → S3 (encrypted, MFA delete enabled)
6. **Continuous Monitoring**: GuardDuty + CloudWatch for real-time detection
7. **Incident Response Plan**: Documented runbooks for common security events
8. **Regular Audits**: Monthly IAM policy review, quarterly access reviews

**Common Pitfalls:**

| Pitfall | Cause | Consequence | Mitigation |
|---------|-------|-------------|-----------|
| Root account usage | Convenience, lack of training | Total AWS account compromise if credentials leaked | Enforce root account lockdown via SCPs |
| Overpermissive roles | Copy-paste admin policies | Blast radius too large if role compromised | Audit roles quarterly, use IAM Access Analyzer |
| Mixed public/private subnets | Poor planning | Workloads exposed to internet | Audit security groups monthly |
| Unencrypted data stores | Default settings | Data breach on storage compromise | Enable default encryption in account settings |
| Missing MFA | Optional in console | Account takeover via password leak | SCPs require MFA for sensitive actions |
| No CloudTrail | Unknown API calls | Cannot detect breach or investigate | Enable CloudTrail day one, immutable logging |
| Disabled GuardDuty | Cost concerns | Malicious activity undetected | GuardDuty costs <$2/day/account |

---

### 4.2 Shared Responsibility Model

**Internal Working Mechanism:**

The shared responsibility model allocates security tasks between AWS and customers based on what each can control:

```
┌─────────────────────────────────────────────────────────────┐
│ Customer Responsibility                                     │
├─────────────────────────────────────────────────────────────┤
│ • Data classification and encryption                        │
│ • Network configuration (VPC, SGs, NACLs)                   │
│ • IAM policies and access control                           │
│ • OS and application patching                               │
│ • Firewall configuration (host-based and network-based)     │
│ • Account and credential management                         │
│ • Monitoring and logging of customer activity               │
│ • Data backup and disaster recovery                         │
├─────────────────────────────────────────────────────────────┤
│ AWS "Shared" Responsibility (conditional on service type)  │
├─────────────────────────────────────────────────────────────┤
│ • Patch management for underlying infrastructure            │
│ • Data center access and physical security                  │
│ • Network infrastructure (DDoS protection at boundary)      │
│ • Hardware lifecycle management                             │
├─────────────────────────────────────────────────────────────┤
│ AWS Responsibility                                          │
├─────────────────────────────────────────────────────────────┤
│ • Global infrastructure security                            │
│ • Data center design and redundancy                         │
│ • Hypervisor isolation                                      │
│ • Physical facility access                                  │
│ • Hardware disposal                                         │
└─────────────────────────────────────────────────────────────┘
```

**Service Type Variations:**

```
Infrastructure (IaaS) - EC2:
┌──────────────┬─────────────────────────────┐
│ AWS          │ Customer                    │
├──────────────┼─────────────────────────────┤
│ • Hypervisor │ • OS patching               │
│ • Hardware   │ • Application updates       │
│ • Network    │ • Security groups           │
│            │ • IAM roles                 │
└──────────────┴─────────────────────────────┘

Platform (PaaS) - RDS:
┌──────────────────────┬─────────────────────┐
│ AWS                  │ Customer            │
├──────────────────────┼─────────────────────┤
│ • OS patching        │ • Access control    │
│ • Database engine    │ • Database config   │
│ • Backups            │ • Application logic │
│ • Failover           │ • Data classification│
└──────────────────────┴─────────────────────┘

Software (SaaS) - S3:
┌──────────────────────────┬─────────────┐
│ AWS                      │ Customer    │
├──────────────────────────┼─────────────┤
│ • All infrastructure     │ • IAM       │
│ • Storage durability     │ • Encryption│
│ • Encryption (optional)  │ • Policies  │
│ • DDoS mitigation        │ • What data |
└──────────────────────────┴─────────────┘
```

**Production Usage Patterns:**

For a typical 3-tier application:

```
Tier 1: Load Balancer (ALB)
├── AWS: Infrastructure, patching, DDoS mitigation
└── Customer: Security groups, TLS certificate, access logs

Tier 2: Compute (EC2)
├── AWS: Hypervisor, hardware, network connectivity
└── Customer: OS patching, application updates, security hardening

Tier 3: Database (RDS)
├── AWS: Database engine patching, backups, HA failover
└── Customer: IAM policies, encryption keys, backup retention
```

**DevOps Best Practices:**

1. **Create a RACI Matrix**: Clearly define responsibility for each security aspect
2. **Document Assumptions**: What does the team assume AWS handles?
3. **Test Failover**: Verify AWS is actually handling HA/failover
4. **Audit Regularly**: Monthly review of who can do what
5. **Patch Planning**: Have calendar for OS updates (AWS doesn't patch EC2 OSes)

**Common Pitfalls:**

- **Assuming AWS patching includes EC2 OS**: AWS only patches hypervisor; you patch EC2 OS
- **Assuming AWS handles credential rotation**: You must rotate IAM keys, database passwords
- **Assuming CloudTrail is retained forever**: Default is 90 days; configure S3 for long-term storage
- **Not testing backup recovery**: AWS provides backups; you must verify they work

---

### 4.3 AWS Security Services Overview

**Internal Working Mechanism:**

AWS security services are integrated but independent; they collect different data signals:

```
Data Sources and Processing:

CloudTrail (API Calls)
├── Captures: Who called what API, when, from where, result
├── Storage: S3 (immutable, encrypted)
├── Processing: CloudWatch Logs Insights for queries
└── Retention: Can be configured indefinitely

Config (Configuration Compliance)
├── Captures: Resource configuration snapshots
├── Storage: S3 snapshots, Config history
├── Processing: Evaluates against rules (AWS-managed or custom)
└── Triggers: Auto-remediation or SNS notifications

GuardDuty (Threat Detection)
├── Captures: VPC Flow Logs, CloudTrail, DNS queries
├── Processing: ML models trained on AWS threat data
├── Output: Findings (Low/Medium/High/Critical)
└── Action: Can trigger Lambda, SNS, or EventBridge

Security Hub (Compliance Aggregation)
├── Captures: Findings from GuardDuty, Macie, IAM Access Analyzer, etc.
├── Processing: Correlates findings, maps to compliance frameworks (CIS, PCI-DSS, HIPAA)
├── Output: Compliance dashboard, filtered findings
└── Action: Custom actions via EventBridge

Macie (Data Discovery)
├── Captures: S3 object content and metadata
├── Processing: ML to identify PII (credit card numbers, SSNs)
├── Output: Findings on sensitive data locations
└── Action: Alerting, automated remediation
```

**Service Interactions:**

```
                    ┌────────────────┐
                    │   VPC Flow Logs│
                    │ CloudTrail Logs│
                    │  Route 53 Logs │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │    GuardDuty    │
                    │ (Threat Analysis │
                    │  via ML)         │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────▼────┐       ┌──────▼──────┐    ┌──────▼─────┐
    │Config    │       │ IAM Access  │    │ Macie      │
    │Rules     │       │ Analyzer    │    │ (S3 scan)  │
    │(CompCheck       │             │    │            │
    └────┬────┘       └──────┬──────┘    └──────┬─────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                    ┌────────▼────────┐
                    │  Security Hub   │
                    │ (Aggregation &  │
                    │  Compliance)    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Compliance     │
                    │  Dashboard &    │
                    │  Findings       │
                    └─────────────────┘
```

**Popular AWS Security Services:**

| Service | Primary Function | Data Source | Output | DevOps Use |
|---------|------------------|-------------|--------|-----------|
| CloudTrail | API audit logging | All AWS API calls | Audit trail | Who did what, when, where |
| Config | Configuration compliance | Resource state snapshots | Config drift events | Detect configuration changes |
| GuardDuty | Threat detection | VPC Flow, CloudTrail, DNS | Security findings | Detect suspicious activity |
| Security Hub | Compliance aggregation | Multiple sources | Compliance dashboard | Meet regulatory requirements |
| Macie | PII discovery | S3 object scanning | Data discovery findings | Identify sensitive data |
| IAM Access Analyzer | IAM compliance | IAM policy review | Policy findings | Validate access permissions |
| Secrets Manager | Credential management | API calls | Audit trail | Rotate credentials automatically |
| KMS | Key management | Encryption operations | CloudTrail logs | Audit encryption key usage |
| WAF | Web application firewall | HTTP/HTTPS traffic | Blocked requests | Protect against web attacks |
| Shield | DDoS protection | DDoS attack patterns | Attack metrics | Automatic DDoS mitigation |
| VPC Flow Logs | Network traffic logging | Network interfaces | Flow records | Debug network connectivity |

---

### 4.4 Identity and Access Management (IAM)

**Internal Working Mechanism:**

IAM evaluates every AWS API request through a multi-step process:

```
Step 1: Authentication
├── User provides credentials (AWS Access Key ID + Secret Access Key)
├── AWS verifies credentials using internal database
├── Creates temporary session token (if using STS AssumeRole)
└── Request continues only if authenticated

Step 2: Get Applicable Policies
├── Identity-based: Policies attached directly to the principal
├── Resource-based: Policies on the target resource (S3 bucket, SQS queue)
├── Session-based: Policies from assumed role session
├── Organizational: Service Control Policies (SCPs) limit maximum
└── Permissions boundary: Maximum permissions for role (optional)

Step 3: Policy Evaluation
├── Check for explicit Deny (if found, deny the action)
├── Evaluate permissions boundary (is action within max?
├── Check identity-based policies (is action allowed?)
├── Check resource-based policies (does resource allow?)
├── Check SCPs (is action allowed at organization level?)
└── Default: Deny unless explicitly allowed

Step 4: Authorization Decision
├── If any policy says "Deny": Action blocked
├── If required policies say "Allow": Action permitted
├── Otherwise: Action blocked (default deny)
└── CloudTrail logs the decision

Step 5: Service Handler
├── AWS service receives allowed request
├── Service performs the action
├── CloudTrail logs the successful action
└── Response returned to requester
```

**Practical IAM Policy Example:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadProductionLogs",
      "Effect": "Allow",
      "Action": [
        "logs:GetLogEvents",
        "logs:DescribeLogStreams",
        "logs:DescribeLogGroups"
      ],
      "Resource": "arn:aws:logs:us-east-1:123456789012:log-group:/aws/production/*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "o-xxxxxxxxxxxxx"
        },
        "IpAddress": {
          "aws:SourceIp": [
            "10.0.0.0/8",
            "203.0.113.0/24"
          ]
        },
        "StringLike": {
          "aws:userid": "*:production-reader-*"
        }
      }
    },
    {
      "Sid": "DenyUnencryptedTransport",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Common IAM Roles Architecture:**

```
UserRole (Human developers)
├── Permissions:
│   ├── EC2: Describe, start, stop (not terminate)
│   ├── S3: List, read development buckets only
│   ├── CloudWatch: Read logs only
│   └── Assume: DeployRole for deployments
├── MFA Required: Yes
├── Max duration: 1 hour
└── Statement: "ec2:*" with Resource "dev" tag only

DeployRole (for CI/CD automation)
├── Permissions:
│   ├── IAM: Ability to assume limited roles
│   ├── S3: Full access to artifact buckets
│   ├── CloudFormation: Full access (updates infrastructure)
│   ├── EC2: Update, create, delete
│   └── Secrets Manager: GetSecretValue only
├── Assumable by: CodePipeline service role
├── Max duration: 15 minutes
└── Audit: Every deployment logged to CloudTrail

ReadOnlyRole (Auditors)
├── Permissions:
│   ├── Describe all resources (EC2, RDS, S3)
│   ├── Read logs and configs
│   └── Read CloudTrail
├── Restrictions:
│   ├── Cannot modify anything
│   ├── Cannot delete anything
│   └── Cannot read sensitive data
└── Audit: All read actions logged

AdminRole (Rarely used)
├── Permissions: "*" (all actions)
├── Assumable by: Named root users only
├── MFA Required: Yes
├── Max duration: 15 minutes
└── Audit: Every admin action requires approval
```

**DevOps Best Practices for IAM:**

1. **Tier-based roles**: User > Operator > Admin (increasing permissions)
2. **Service roles per service**: Lambda, EC2, ECS, etc. each get specific role
3. **Assume role for elevated access**: Require explicit assumption, not default permissions
4. **Session policies**: Reduce permissions duration for temporary credentials
5. **ABAC tags**: Use tags (environment, team, critical) for conditional policies
6. **Quarterly access reviews**: Audit who has what permissions
7. **No shared credentials**: Each human gets own credential (never shared)
8. **Removal process**: Offboarded user credentials should be disabled, not deleted

**Common Pitfalls:**

- **Sharing IAM credentials**: One account per human; never share keys
- **Long-lived credentials**: Rotate every 90 days; prefer temporary credentials
- **Admin by default**: Developers don't need admin; give minimum permissions
- **No testing of policies**: Always test IAM changes in dev before production
- **Not using conditions**: IAM conditions (IP, time, tags) dramatically improve security
- **Cross-account access hell**: Over-complicated trust relationships; document carefully
- **SCPs confusion**: SCPs don't grant permissions, only limit maximum perm

---

### 4.5 Security Boundaries and Isolation

**Internal Working Mechanism:**

Security boundaries define trust zones where different access controls apply:

```
Boundary Types in AWS:

1. Organization Boundary
├── One AWS Organization with multiple accounts
├── Each account is a trust boundary
├── Cross-account access requires explicit trust relationships
└── SCPs apply organization-wide policies

2. Account Boundary
├── IAM users/roles within account are separate identities
├── No automatic access between users/roles
├── Resources by default accessible only to account owner
└── Resource policies can grant cross-account access

3. VPC Boundary
├── Logical network isolation
├── Traffic between VPCs blocked unless explicitly allowed
├── Network doesn't know about IAM; controlled at layer 3/4
└── VPC Peering or PrivateLink required for VPC-to-VPC communication

4. Subnet Boundary
├── Public subnets route through Internet Gateway
├── Private subnets don't have direct internet route
├── Network ACLs provide stateless filtering
├── Security Groups provide stateful filtering
└── Traffic flows based on Layer 3/4 rules

5. Data Boundary
├── Encryption at-rest: Different keys for different data classifications
├── Encryption in-transit: TLS prevents eavesdropping
├── Data residency: Geographically bound to regions
└── Data retention: Separate policies per data classification

6. Temporal Boundary
├── Session expiration: Credentials automatically invalidated
├── Time-based access: IAM conditions restrict access by time
├── Audit logs: Actions logged with timestamp
└── Incident boundary: Limited backward visibility after incident
```

**Architecture Diagram - Multi-Account Security Boundaries:**

```
┌─────────────────────────────────────────────────────────────┐
│ AWS Organization                                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Root Account (Billing only)                        │     │
│  │ └─ Limited root user access (locked down)          │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌─────────────┬──────────────┬────────────────────────┐    │
│  │             │              │                        │    │
│  ▼             ▼              ▼                        ▼    │
│ ┌─────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│ │ Dev Account     │  │ Staging Account  │  │ Prod Account │ │
│ ├─────────────────┤  ├──────────────────┤  ├──────────────┤ │
│ │ VPC: 10.0.0.0   │  │ VPC: 10.1.0.0    │  │ VPC: 10.2.0  │ │
│ │ ├─ Public       │  │ ├─ Public        │  │ ├─ Public    │ │
│ │ └─ Private      │  │ └─ Private       │  │ └─ Private   │ │
│ │                 │  │                  │  │              │ │
│ │ S3: dev-*       │  │ S3: staging-*    │  │ S3: prod-*   │ │
│ │ RDS: dev        │  │ RDS: staging-ha  │  │ RDS: prod-ha │ │
│ │                 │  │                  │  │ (encrypted)  │ │
│ │ IAM: Developers │  │ IAM: QA          │  │ IAM: Admins  │ │
│ │ (full access)   │  │ (limited access) │  │ (least priv) │ │
│ └────────┬────────┘  └────────┬─────────┘  └──────┬───────┘ │
│          │                    │                   │          │
│          └────────────────────┼───────────────────┘          │
│                               │                              │
│         No cross-account access unless explicitly granted    │
└─────────────────────────────────────────────────────────────┘
```

---

### 4.6 VPC Isolation Strategies

**Internal Working Mechanism:**

VPCs provide network-level isolation through multiple layers:

```
Layer 1: Internet Gateway + Route Tables
├── Internet Gateway: Allows outbound internet traffic for public subnets
├── NAT Gateway: Allows private subnets to initiate outbound only (no inbound)
├── Route Tables: Control which traffic goes where
└── Destination: Routing rules determine traffic path

Layer 2: Security Groups (Stateful Firewall)
├── Ingress Rules: Restrict inbound traffic by source, protocol, port
├── Egress Rules: Restrict outbound traffic by destination
├── Stateful: Response traffic automatically allowed back
├── Default: Deny all ingress, allow all egress
└── Can reference other security groups (e.g., ALB-SG)

Layer 3: Network ACLs (Stateless Firewall)
├── Allow: rules (permit or deny)
├── Deny rules: Block still-allowed traffic
├── Stateless: Must explicitly allow both directions
├── Ordered rules: Evaluated top-to-bottom (first match wins)
└── Default: Allow all (but can be customized)

Layer 4: Application Firewalls (Layer 7)
├── AWS WAF: Protects web applications
├── Rule groups: OWASP Top 10, rate limiting, geo-blocking
├── Applied to: CloudFront, ALB, API Gateway
└── Logging: Requests logged and can be sampled

Layer 5: Application-Level TLS
├── TLS 1.2+: Encrypt traffic between client and server
├── Certificate: HTTPS required for sensitive data
├── Cipher suites: Strong algorithms only
└── Perfect Forward Secrecy: Session-specific key even if cert compromised
```

**Practical VPC Segmentation for Production:**

```
Production VPC: 10.0.0.0/16
│
├── Public Subnet (AZ-a): 10.0.1.0/24
│   ├── NAT Gateway (for private subnets to reach internet)
│   ├── ALB Security Group (allows 0.0.0.0/0:443, 0.0.0.0/0:80)
│   └── Bastion Host SG (allows specific IPs:22)
│
├── Private App Subnet (AZ-a): 10.0.10.0/24
│   ├── EC2 Instances (Application servers)
│   ├── Security Group (allows ALB-SG:8443 only)
│   ├── Route: 0.0.0.0/0 → NAT Gateway (can reach internet)
│   └── No direct internet access from outside
│
├── Private DB Subnet (AZ-a): 10.0.20.0/24
│   ├── RDS Primary (encrypted)
│   ├── Security Group (allows APP-SG:3306 only)
│   ├── No internet routes
│   └── Multi-AZ backup in AZ-b
│
├── Public Subnet (AZ-b): 10.0.2.0/24
│   └── Standby NAT Gateway (for HA)
│
├── Private App Subnet (AZ-b): 10.0.11.0/24
│   └── EC2 Instances (duplicate for HA)
│
└── Private DB Subnet (AZ-b): 10.0.21.0/24
    └── RDS Standby (replicates from AZ-a)
```

**Network ACL Example (stateless):**

```
Network ACL for Private App Subnet:

Inbound Rules:
│ Rule │ Protocol │ Port  │ Source CIDR    │ Action │
├──────┼──────────┼───────┼────────────────┼────────┤
│ 100  │ TCP      │ 8443  │ 10.0.1.0/24    │ Allow  │ (from ALB)
│ 110  │ TCP      │ 3306  │ 10.0.20.0/24   │ Allow  │ (to DB)
│ 120  │ TCP      │ 1024+ │ 0.0.0.0/0      │ Allow  │ (ephemeral)
│ 130  │ ICMP     │ -     │ 10.0.0.0/16    │ Allow  │ (diagnostics)
│ 140  │ All      │ All   │ 0.0.0.0/0      │ Deny   │ (default)

Outbound Rules:
│ Rule │ Protocol │ Port  │ Dest CIDR      │ Action │
├──────┼──────────┼───────┼────────────────┼────────┤
│ 100  │ TCP      │ 443   │ 0.0.0.0/0      │ Allow  │ (HTTPS out)
│ 110  │ TCP      │ 3306  │ 10.0.20.0/24   │ Allow  │ (to DB)
│ 120  │ TCP      │ 53    │ 0.0.0.0/0      │ Allow  │ (DNS)
│ 130  │ UDP      │ 53    │ 0.0.0.0/0      │ Allow  │ (DNS)
│ 140  │ TCP      │ 1024+ │ 0.0.0.0/0      │ Allow  │ (responses)
│ 150  │ All      │ All   │ 0.0.0.0/0      │ Deny   │ (default)
```

---

### 4.7 Best Practices for Securing AWS Environments

**1. Account Security:**

```bash
# Agenda: Lock down root account
- [ ] Enable MFA on root account (hardware token, not TOTP)
- [ ] Create IAM user for daily login
- [ ] Enable CloudTrail
- [ ] Enable GuardDuty
- [ ] Review root account access weekly

# Root account SCP policy (prevent damage)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
```

**2. IAM Best Practices:**

```yaml
Human Users:
  - Principle: Use IAM users for console login, not root
  - MFA: Required for all interactive users
  - Access Keys: Rotate every 90 days (automated by Secrets Manager)
  - Groups: Use groups for permission management, not individual policies
  - Conditions: Restrict by IP, time, MFA status

Service Accounts:
  - Principle: Use IAM roles, not long-lived keys
  - Temporary Credentials: 15-minute max lifetime
  - Trust Relationships: Explicit about who can assume role
  - Conditions: Restrict assume role by source account, IP
  - Audit: Every credential issued logged in CloudTrail

Privileged Access:
  - Admin Role: Requires MFA
  - Assumption: Only specific users can assume admin
  - Logging: Every action logged with user identifier
  - Approval: Manual approval process for sensitive changes
  - Expiration: Admin session expires after 15 minutes
```

**3. Network Security Checklist:**

```
☐ VPC configuration:
  ☐ Default VPC deleted or not used
  ☐ Custom VPC created per environment
  ☐ CIDR blocks don't overlap between VPCs
  ☐ Flow Logs enabled on VPC
  
☐ Subnet configuration:
  ☐ Public subnets: Only load balancers and NAT
  ☐ Private subnets: Applications and databases
  ☐ Database subnets: Separate from app subnets
  ☐ Multiple AZs: High availability
  
☐ Security Groups:
  ☐ No 0.0.0.0/0 for SSH (22), RDP (3389)
  ☐ ALB allows 0.0.0.0/0:443 only
  ☐ Apps allow ALB-SG:port only
  ☐ Databases allow APP-SG:port only
  ☐ Bastion allows corporate IP:22 only
  
☐ Network ACLs:
  ☐ Stateless rules defined (usually not needed if SGs sufficient)
  ☐ Explicit deny rules for known bad IPs
  ☐ Ephemeral ports allowed (1024-65535)
  
☐ DDoS Protection:
  ☐ AWS Shield Standard (automatic)
  ☐ AWS Shield Advanced (optional, recommended for prod)
  ☐ WAF rules for Layer 7 attacks
  ☐ Rate limiting on ALB/API Gateway
  
☐ VPN/Access:
  ☐ AWS Direct Connect for on-prem connectivity (if applicable)
  ☐ VPN endpoints with MFA
  ☐ Bastion host for SSH access (not SSH from internet)
```

**4. Encryption Strategy:**

```
Data at Rest:
├── S3: Enable default KMS encryption (SSE-S3 minimum, KMS preferred)
├── EBS: Encryption enabled by default (account setting)
├── RDS: Encryption enabled at database creation
├── Secrets Manager: Automatic encryption with KMS
└── DynamoDB: Encryption enabled by default

Data in Transit:
├── ALB: TLS 1.2+ termination
├── Application: Enforce HTTPS redirects
├── AWS APIs: Always use HTTPS (default)
├── Databases: Encryption in-flight to RDS
└── Inter-service: Service Mesh (Istio) for mutual TLS

Key Management:
├── KMS: Customer-managed keys for sensitive data
├── Key Rotation: Annual rotation
├── Key Policies: Restrict who can administer keys
├── CloudTrail: Log all key operations
└── Audit: Monthly review of key access

Certificate Management:
├── AWS Certificate Manager: Auto-renewal
├── Validity: 90 days (consider 30-day renewal just-in-case)
├── Monitoring: CloudWatch alerts for 30-day expiration
└── Pinning: Consider certificate pinning for critical APIs
```

**5. Monitoring and Detection:**

```yaml
CloudTrail Configuration:
  Organization Trail: Multi-account, multi-region
  S3 Bucket: Encrypted, versioning enabled, MFA delete
  Log Bucket: Separate account (logging account)
  Retention: 1-7 years (per compliance requirement)
  Alerts: SNS on PutObject, DeleteBucket, DeleteTrail

GuardDuty:
  Enabled: All member accounts
  Findings: Reviewed within 24 hours
  Baseline: 30 days to establish baselines
  Remediation: Automated Lambda response to high-severity
  Review: Weekly findings summary

Config:
  Recorder: Multi-account aggregation
  Rules: CIS Benchmarks, encryption checks, IAM policies
  Remediation: Auto-remediation for known safe fixes
  Compliance: Monthly compliance dashboard

Security Hub:
  Framework: CIS AWS Foundations Benchmark
  Score: Aggregated security score per account
  Findings: Filtered by severity (only High/Critical reviewed weekly)
  Compliance: PCI-DSS, HIPAA, SOC 2 (optional integrations)

Alerts List:
  ☐ Root account login
  ☐ Console login outside corporate IP
  ☐ MFA disabled
  ☐ IAM policy attached to user (not group)
  ☐ Unauthorized API calls (CloudTrail events with Deny)
  ☐ Security group modified
  ☐ RDS encryption disabled
  ☐ S3 bucket made public
  ☐ KMS key deletion scheduled
  ☐ CloudTrail disabled
  ☐ GuardDuty findings (Medium+)
```

---

### 4.8 Common Pitfalls and Mitigation

| Pitfall | Root Cause | Impact | Mitigation |
|---------|-----------|--------|-----------|
| **S3 Bucket Made Public** | Default public ACL, misconfigured bucket policy | Data exposure, GDPR violation | Block public ACL (account setting), S3 Block Public Access, Config Rules |
| **Overpermissive Security Group** | Copy-paste error, lack of review | Unexpected internet access to resources | Use SG description field for documentation, review monthly |
| **Unencrypted Database** | Default setting oversight | Encrypted breach at rest | Enable KMS encryption at account level (default all new resources) |
| **Root Account Used Daily** | Convenience, lack of training | Total account compromise if credentials leak | SCP to prevent root actions, enforce IAM user use |
| **No CloudTrail** | Cost concerns, unknown requirement | Cannot audit or investigate incidents | Enable CloudTrail immediately; cost is <$2/day |
| **Long-Lived Access Keys** | Once created, forgotten | Compromise window large | 90-day rotation, use Secrets Manager, revoke monthly |
| **Cross-Account Access Hell** | Over-engineered trust relationships | Cannot debug access issues | Document trust relationships in RACI matrix |
| **No Multi-AZ for Production** | Cost reduction | Single point of failure (AZ outage) | Multi-AZ required for prod RDS, EC2 ASG across AZs |
| **MFA Not Enforced** | Seen as user friction | Password breach = account compromise | IAM policy requiring MFA for sensitive actions |
| **No VPC Flow Logs** | Unknown value, setup complexity | Cannot debug network connectivity | VPC Flow Logs to CloudWatch, enable day one |
| **Application Secrets Hardcoded** | Developer convenience | Source code breach = secrets exposure | Use Secrets Manager, scan code in CI/CD (TruffleHog) |
| **No IAM Access Analyzer** | Unknown tool, extra cost | Unused permissions undetected | Enable IAM Access Analyzer for quarterly access reviews |

---

## 5. Infrastructure as Code (IaC) Security

### 5.1 Principles of IaC Security

**Internal Working Mechanism:**

IaC security operates on the principle that infrastructure is treated as software, subject to the same security controls:

```
Traditional Infrastructure (High Risk):
├── Manual console changes (no audit trail)
├── Inconsistent environments (drift)
├── Hard to review (no diff before deploying)
├── Serial remediation (fix one server at a time)
└── Compliance verification: Manual and slow

IaC Infrastructure (Low Risk):
├── Code changes (Git history = audit trail)
├── Consistent environments (automated deployment)
├── Code review (pull request approval before deploying)
├── Parallel remediation (redeploy 100 servers instantly)
└── Compliance verification: Automated (scan IaC)
```

**Key Principles:**

1. **Code as the Source of Truth**: Infrastructure definition is in Git, not in AWS Console
2. **Version Control**: Every infrastructure change has commit history showing who/what/when/why
3. **Testability**: Infrastructure changes can be tested before production deployment
4. **Auditability**: Complete audit trail of infrastructure changes
5. **Reproducibility**: Deploy identical infrastructure across environments
6. **Policy as Code**: Define security policies in code (Sentinel, OPA, CEL)

**Architecture Role:**

IaC security enables:
- **Rapid Detection**: Security scan runs in seconds, not days
- **Rapid Remediation**: Redeploy compliant infrastructure in minutes
- **Consistency**: Same security configuration across 1000s of resources
- **Compliance**: Automated proof of compliance by design
- **Disaster Recovery**: Recreate infrastructure from code

**Production Usage Patterns:**

```
Enterprise IaC Workflow:

1. Developer Workshop
├── Create Terraform file in Git branch
├── Open pull request
└── Wait for approval

2. Automated Checks
├── Pre-commit hooks check formatting
├── Checkov scans for security issues
├── TFLint finds style violations
├── Sonarqube checks code quality
└── All must pass before merge

3. Code Review
├── Security team reviews IaC diff
├── Architecture team reviews design
├── DevOps team reviews operational aspects
└── Approval/rejection decision

4. Infrastructure Deployment
├── Merge approved PR to main branch
├── CD pipeline triggered automatically
├── Terraform plan created (preview of changes)
├── OPA/Sentinel policy evaluation
├── If policy passes, apply infrastructure
└── New resources created in AWS

5. Post-Deployment
├── AWS Config monitors for drift
├── CloudTrail logs all changes
├── GuardDuty monitors for threats
└── Compliance checks verify state
```

**DevOps Best Practices:**

1. **Adopt GitOps**: Infrastructure changes only via Git (never via console)
2. **Test environments first**: Changes must pass dev/staging before production
3. **Plan before apply**: Always run `terraform plan` and review before `terraform apply`
4. **Immutable infrastructure**: Redeploy servers (don't update in-place)
5. **State file security**: Use remote state (S3 + DynamoDB), not local
6. **Access control**: Limit who can merge to main branch
7. **Audit all changes**: CloudTrail + CloudWatch alerts on terraform execution
8. **Rollback capability**: Keep previous infrastructure versions for quick rollback

---

### 5.2 Popular IaC Tools and Security Posture

| Tool | Language | Maturity | Security Scanning | Best For | Weaknesses |
|------|----------|----------|-------------------|----------|-----------|
| **Terraform** | HCL | Mature | Tfsec, Checkov, Snyk | AWS, GCP, Azure multi-cloud | State file management complexity |
| **CloudFormation** | YAML/JSON | Mature | Checkov, Cfn-lint | AWS-only, native integration | JSON verbose, less portable |
| **Ansible** | YAML | Mature | Limited (mainly linting) | Configuration management, imperative workflows | Less common for infrastructure provisioning |
| **Pulumi** | Python/Go/TS | Growing | Integrated policy, Checkov | Developers preferring programming languages | Smaller community, less mature |
| **CDK** | TypeScript/Python | Growing | AWS native validation | AWS workloads with code-first approach | Lock-in to AWS |
| **Bicep** | DSL | Growing | Checkov support | Azure-specific, simpler than ARM | Azure only |
| **Helm** | YAML | Mature | Checkov, Kubesec | Kubernetes deployments | Not general-purpose IaC |

**Security Scanning Capability Comparison:**

```
Tfsec (Terraform-specific):
├── Pre-commit scanning: Can run locally
├── Speed: Scans entire project in <1 second
├── Coverage: 600+ rules for common misconfigurations
├── False Positives: Low
└── Best for: Developers checking locally

Checkov (Multi-IaC):
├── Supports: Terraform, CloudFormation, Kubernetes, Docker, Ansible, Helm
├── Coverage: 1000+ rules across frameworks
├── Integration: Runs in CI/CD, IDE plugins, Git pre-commit
├── Policy as Code: Write custom checks in Python
└── Best for: Multi-tool environments, policy enforcement

Snyk (Commercial):
├── SCA (Dependency scanning): Integrated
├── IaC scanning: Terraform, CloudFormation, Kubernetes
├── Supply Chain: Container scanning, IaC scanning, dependency scanning
├── Integration: GitHub, GitLab, Azure DevOps, Jenkins
└── Best for: Commercial organizations needing unified scanning

CloudFormation Lint (cfn-lint):
├── CloudFormation-specific
├── Rules: 200+ checks
├── Integration: IDE (VS Code), CLI, GitHub Actions
└── Best for: CloudFormation-first shops

Policy as Code Engines:
├── OPA/Rego: General-purpose policy language
├── Sentinel: HashiCorp-specific (Terraform Cloud)
├── Kyverno: Kubernetes-native policy
└── CEL: Common Expression Language (YAML-based)
```

---

### 5.3 Secure IaC Practices

**Anti-Patterns (What NOT to do):**

```hcl
# ❌ WRONG: Hardcoded secrets
resource "aws_db_instance" "prod" {
  engine             = "mysql"
  allocated_storage  = 100
  instance_class     = "db.t3.medium"
  username           = "admin"                    # EXPOSED
  password           = "MyPassword123!"           # EXPOSED
  skip_final_snapshot = true                      # DANGEROUS
}

# ❌ WRONG: Public database
resource "aws_security_group" "db" {
  ingress {
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]  # EXPOSED: Internet can access
  }
}

# ❌ WRONG: Unencrypted storage
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data"
  # Missing: server_side_encryption_configuration
  # Missing: versioning
  # Missing: block_public_access
}

# ❌ WRONG: Hard-coded AWS credentials
provider "aws" {
  region = "us-east-1"
  access_key = "AKIAIOSFODNN7EXAMPLE"  # EXPOSED
  secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"  # EXPOSED
}
```

**Best Practices (What TO do):**

```hcl
# ✅ RIGHT: Use Secrets Manager for database password
resource "aws_db_instance" "prod" {
  engine               = "mysql"
  allocated_storage    = 100
  instance_class       = "db.t3.medium"
  username             = "admin"
  password             = random_password.db_password.result
  storage_encrypted    = true
  kms_key_id          = aws_kms_key.db.arn
  skip_final_snapshot  = false
  final_snapshot_identifier_prefix = "prod-backup"
  
  multi_az             = true  # High availability
  backup_retention_period = 30  # 30-day retention
  
  vpc_security_group_ids = [aws_security_group.db.id]
  db_subnet_group_name   = aws_db_subnet_group.private.name
}

# Generate random password (auto-rotated by Secrets Manager)
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "prod/db/password/"
  rotation_rules {
    automatically_after_days = 30  # Auto-rotate every 30 days
  }
}

# ✅ RIGHT: Restrict database access
resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Database security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from app servers only"
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.app.id]  # App SG only
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database"
  }
}

# ✅ RIGHT: Encrypted S3 bucket with access logs
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "production-data"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Access logs
resource "aws_s3_bucket_logging" "data" {
  bucket        = aws_s3_bucket.data.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# ✅ RIGHT: Use IAM role for AWS provider (no hardcoded credentials)
provider "aws" {
  region = "us-east-1"
  # AWS credentials from assumed IAM role (OIDC or EC2 metadata)
  assume_role {
    role_arn = "arn:aws:iam::123456789012:role/terraform-deployment"
  }
}

# Variable to pass sensitive data
variable "environment" {
  description = "Environment name"
  type        = string
  sensitive   = true  # Won't print in logs
}
```

---

### 5.4 Tfsec and Checkov Scanning

**Tfsec Usage in CI/CD:**

```bash
#!/bin/bash
# scan-infrastructure.sh - Pre-deployment IaC scanning

echo "🔍 Running Tfsec security scan..."
tfsec . \
  --format json \
  --out tfsec-results.json \
  --minimum-severity MEDIUM \
  --exit-code 1  # Fail if MEDIUM+ severity found

TFSEC_EXIT=$?

if [ $TFSEC_EXIT -ne 0 ]; then
  echo "❌ Tfsec found security issues:"
  cat tfsec-results.json | jq '.[] | "\(.rule_id): \(.description)"'
  exit 1
fi

echo "✅ Tfsec passed"

# Checkov covers additional checks
echo "🔍 Running Checkov..."
checkov -d . \
  --framework terraform \
  --compact \
  --quiet \
  --exit-code 1

CHECKOV_EXIT=$?

if [ $CHECKOV_EXIT -ne 0 ]; then
  echo "❌ Checkov found issues"
  exit 1
fi

echo "✅ All scans passed"
```

**Checkov Custom Policy:**

```python
# custom-check.py - Enforce encryption on all RDS instances
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, Any

class RDSEncryption(BaseResourceCheck):
    name = "Ensure RDS instances have encryption enabled"
    id = "CKV2_AWS_12"
    supported_resources = ["aws_db_instance"]

    def scan_resource_conf(self, conf):
        """
        Looks for encryption configuration on RDS instances:
        https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance
        """
        if "storage_encrypted" in conf:
            if conf["storage_encrypted"][0] is True:
                return CheckResult.PASSED
        return CheckResult.FAILED

check = RDSEncryption()
```

**Tfsec Results Example:**

```json
{
  "results": [
    {
      "rule_id": "AVD-AWS-0037",
      "description": "S3 bucket does not have encryption enabled",
      "severity": "CRITICAL",
      "file": "main.tf",
      "line": 42,
      "resource": "aws_s3_bucket.logs",
      "status": "FAILED",
      "code": "resource \"aws_s3_bucket\" \"logs\" {\n  bucket = \"app-logs\"\n  # Missing encryption configuration\n}\n"
    },
    {
      "rule_id": "AVD-AWS-0074",
      "description": "AWS RDS database instance is publicly accessible",
      "severity": "CRITICAL",
      "file": "rds.tf",
      "line": 15,
      "resource": "aws_db_instance.prod",
      "status": "FAILED"
    }
  ],
  "summary": {
    "passed": 45,
    "failed": 2,
    "skipped": 0
  }
}
```

---

### 5.5 Integration into CI/CD Pipelines

**GitHub Actions Workflow:**

```yaml
name: Infrastructure Security

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/infra-security.yml'

jobs:
  scan:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      # Terraform format check
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format
        run: |
          cd terraform
          terraform fmt -check
      
      # TFLint (style and best practices)
      - uses: terraform-linters/setup-tflint@v3
      - name: TFLint
        run: |
          cd terraform
          tflint --init
          tflint --format json > tflint-results.json
          cat tflint-results.json
      
      # Tfsec (security scanning)
      - name: Run Tfsec
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: 'terraform'
          format: 'json'
          out: 'tfsec-results.json'
      
      # Checkov (compliance scanning)
      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform
          framework: terraform
          compact: true
          quiet: true
      
      # Plan Terraform
      - name: Terraform Plan
        id: plan
        run: |
          cd terraform
          terraform init
          terraform plan -json > tfplan.json
          terraform show -json tfplan.json > tfplan-readable.json
      
      # Upload results
      - name: Upload Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: scan-results
          path: |
            terraform/tfsec-results.json
            terraform/tflint-results.json
            terraform/tfplan.json
      
      # Comment on PR
      - name: Comment on PR
        uses: actions/github-script@v6
        if: github.event_name == 'pull_request'
        with:
          script: |
            const fs = require('fs');
            const tfsecResults = JSON.parse(fs.readFileSync('terraform/tfsec-results.json', 'utf8'));
            
            let comment = '## Infrastructure Security Scan\n';
            comment += `✅ **Tfsec**: ${tfsecResults.summary.passed} passed, `;
            comment += `❌ ${tfsecResults.summary.failed} failed\n\n`;
            
            if (tfsecResults.summary.failed > 0) {
              comment += '### Issues Found:\n';
              tfsecResults.results.forEach(result => {
                comment += `- **${result.rule_id}**: ${result.description} (${result.file}:${result.line})\n`;
              });
            }
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

**GitLab CI Pipeline:**

```yaml
stages:
  - scan
  - plan
  - deploy

variables:
  TF_ROOT: ${CI_PROJECT_DIR}/terraform

before_script:
  - cd ${TF_ROOT}
  - terraform init

tfsec:scan:
  stage: scan
  image: aquasec/tfsec:latest
  script:
    - tfsec . --minimum-severity MEDIUM --exit-code 1 --format json > tfsec-results.json
  artifacts:
    reports:
      sast: tfsec-results.json
  allow_failure: false

checkov:scan:
  stage: scan
  image: bridgecrew/checkov:latest
  script:
    - checkov -d . --framework terraform --compact --exit-code 1
  allow_failure: false

terraform:plan:
  stage: plan
  image: hashicorp/terraform:latest
  script:
    - terraform plan -json | jq . > tfplan.json
  artifacts:
    paths:
      - ${TF_ROOT}/tfplan.json
  only:
    - merge_requests

terraform:apply:
  stage: deploy
  image: hashicorp/terraform:latest
  script:
    - terraform apply -auto-approve tfplan.json
  only:
    - main
  when: manual
```

---

### 5.6 Policy Enforcement for IaC

**OPA/Rego Policy Example:**

```rego
# Required encryption and tagging policy for Terraform

package terraform.aws

import data.lib.outputs

# Find all aws_s3_bucket resources
s3_buckets[res] = val {
    res := input.resource.aws_s3_bucket[_]
    val := res[1]
}

# Check S3 encryption is enabled
deny[msg] {
    bucket := s3_buckets[name]
    not bucket.server_side_encryption_configuration
    msg := sprintf("S3 bucket '%s' must have encryption enabled", [name])
}

# Check S3 versioning is enabled
deny[msg] {
    bucket := s3_buckets[name]
    not bucket.versioning
    msg := sprintf("S3 bucket '%s' must have versioning enabled", [name])
}

# Check required tags
required_tags := ["Environment", "Owner", "CostCenter"]

deny[msg] {
    resource := s3_buckets[name]
    tags := resource.tags[0]
    missing := [tag | tag := required_tags[_]; not tags[tag]]
    length(missing) > 0
    msg := sprintf("S3 bucket '%s' missing required tags: %s", [name, missing])
}

# Check RDS encryption
rds_instances[res] = val {
    res := input.resource.aws_db_instance[_]
    val := res[1]
}

deny[msg] {
    db := rds_instances[name]
    not db.storage_encrypted
    msg := sprintf("RDS instance '%s' must have storage encryption enabled", [name])
}

# Check multi-AZ for production
deny[msg] {
    db := rds_instances[name]
    tags := db.tags[0]
    tags.Environment == "production"
    not db.multi_az
    msg := sprintf("Production RDS '%s' must be multi-AZ", [name])
}
```

**Sentinel Policy (HashiCorp Terraform Cloud):**

```hcl
# Sentinel policy for Terraform

import "tfplan/v2" as tfplan

policy "require_encryption" {
  evaluation {
    rds_instances = find_resources_from_plan_by_type("aws_db_instance")

    for rds_instances as name, resource {
      storage_encrypted = resource.config.storage_encrypted[0] else null

      if storage_encrypted is null {
        print("RDS instance", name, "must have storage_encrypted enabled")
        fail()
      }

      if storage_encrypted is not true {
        print("RDS instance", name, "storage_encrypted must be true")
        fail()
      }
    }
  }
}

policy "require_tags" {
  evaluation {
    resources = find_resources_by_type_in_plan("aws_instance")

    for resources as name, resource {
      tags = resource.config.tags[0] else {}

      if length(tags) == 0 {
        print("EC2 instance", name, "must have tags")
        fail()
      }

      required_tags = ["Environment", "Owner"]
      for required_tags as req_tag {
        if tags[req_tag] is undefined {
          print("EC2 instance", name, "must have tag:", req_tag)
          fail()
        }
      }
    }
  }
}
```

---

### 5.7 Best Practices for IaC Security in DevOps

**IaC Governance Model:**

```
┌─────────────────────────────────────────┐
│ Version Control (Git)                   │
│ All infrastructure changes tracked      │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Pre-commit Hooks                        │
│ • Terraform fmt check                   │
│ • Checkov scanning                      │
│ • TruffleHog (secrets scanning)         │
│ Fail if issues found                    │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Pull Request                            │
│ • Diff is human-readable                │
│ • Security team reviews                 │
│ • At least 2 approvals required         │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Automated Testing (Dev Environment)    │
│ • Deploy to non-prod first              │
│ • Functional testing                    │
│ • Infrastructure validation             │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Deployment Gate (Prod)                 │
│ • Policy evaluation (OPA/Sentinel)     │
│ • Compliance check                      │
│ • Optional manual approval              │
│ Fail if policies violated               │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Deploy to Production                   │
│ • Infrastructure created/updated        │
│ • All changes in CloudTrail             │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│ Continuous Compliance                   │
│ • AWS Config monitors drift             │
│ • Config Rules evaluate compliance      │
│ • Auto-remediation or alerts            │
└─────────────────────────────────────────┘
```

**Checklist - IaC Security Setup:**

```
☐ Repository Setup
  ☐ Git repository for infrastructure code
  ☐ Branch protection: Main requires code review
  ☐ Branch protection: Require PRs for all changes
  ☐ Branch protection: Disable force push to main
  ☐ Pre-commit hooks configured

☐ Scanning Integration
  ☐ Tfsec configured and running
  ☐ Checkov configured and running
  ☐ TFLint configured (style checking)
  ☐ TruffleHog configured (secrets scanning)
  ☐ Sonarqube or similar for code quality
  ☐ All scans required before deploy

☐ CI/CD Integration
  ☐ Terraform init/validate in CI
  ☐ Terraform plan generates JSON output
  ☐ OPA/Sentinel policy evaluation
  ☐ Scan results uploaded as artifacts
  ☐ Failure if scans fail (no bypass)

☐ Policy Definition
  ☐ Security policies documented in code (OPA/Sentinel)
  ☐ Compliance policies defined
  ☐ Tagging requirements enforced
  ☐ Encryption requirements enforced
  ☐ Network policies enforced

☐ State File Management
  ☐ Remote state backend (S3 + DynamoDB)
  ☐ State file encryption enabled
  ☐ State file versioning enabled
  ☐ State file access restricted to specific roles
  ☐ MFA delete enabled on state bucket
  ☐ Regular state file backups

☐ Monitoring and Compliance
  ☐ AWS Config Rules for drift detection
  ☐ CloudTrail logging for all changes
  ☐ Config Aggregator for multi-account view
  ☐ Compliance dashboard showing deviation from code
  ☐ Alerts if manual changes detected in AWS Console
  ☐ Auto-remediation to revert drift to IaC code
```

---

### 5.8 Common Pitfalls and Mitigation

| Pitfall | Root Cause | Impact | Mitigation |
|---------|-----------|--------|-----------|
| **Secrets in Git History** | Hardcoded passwords/keys | Permanent exposure (history is immutable) | Use pre-commit hooks (TruffleHog), Secrets Manager |
| **No State File Backup** | Assumption state file is safe | Entire infrastructure lost if state deleted | S3 versioning, MFA delete, regular backups |
| **Manual Console Changes** | Developer convenience | Drift between code and reality | Git workflow enforcement, no console access |
| **No Code Review** | Assumption code is correct | Broken infrastructure deployed to prod | Require PR approval before applying |
| **Plan not reviewed** | Rushing to production | Unexpected resource changes (termination, replacement) | Always run terraform plan first, review diff |
| **Stale infrastructure code** | Not maintaining IaC - | Drift grows over time | Quarterly audit of IaC vs. live infrastructure |
| **Unversioned modules** | Using latest module version | Breaking changes applied unexpectedly | Pin module versions in module calls |
| **No encryption by default** | Manual per-resource encryption | Unencrypted data stores created | Account-level default encryption setting |
| **Public IaC repository** | GitHub template repo | Security groups, IAM policies exposed | Private repository or redact sensitive values |
| **Shared state lock failed** | Network timeout, Lambda timeout | Multiple applies conflict, state corruption | DynamoDB lock timeout configuration, monitoring |



---

## 6. Pipeline Security

### 6.1 Principles of Pipeline Security

**Internal Working Mechanism:**

CI/CD pipelines are attack vectors because they handle code, credentials, and infrastructure changes. Pipeline security operates on defense-in-depth:

```
Traditional Pipeline (High Risk):
├── Code checkout → runs on public IP
├── Build artifacts → unscanned for vulnerabilities
├── Secrets → hardcoded or stored in plain files
├── Deployment → manual approval (can be bypassed)
├── Logs → contain secrets and sensitive data
└── Blast radius: Pipeline compromise = production compromise

Secure Pipeline (Low Risk):
├── Code checkout → signed commits verified
├── Build artifacts → scanned (SAST, SCA, container images)
├── Secrets → injected at runtime from vault
├── Deployment → policy evaluation (OPA/Sentinel)
├── Logs → secrets masked, audit trail immutable
└── Blast radius: Limited by short-lived credentials, isolation
```

**Key Principles:**

1. **Defense in Depth**: Multiple layers of validation before production
2. **Least Privilege**: Pipeline runner has minimal necessary permissions
3. **Immutable Audit Trail**: Every step logged, cannot be modified after-fact
4. **Secrets Injection at Runtime**: Not stored in configurations or repositories
5. **Ephemeral Runners**: Clean environment for each pipeline run (no persistence)
6. **Network Isolation**: Pipeline runners isolated from production and each other
7. **Artifact Signing**: Cryptographic proof of build origin and integrity
8. **Rate Limiting**: Prevent brute-force attacks on deployment gates

**Architecture Role:**

Pipeline security enables:
- **Early Detection**: Vulnerabilities caught before production
- **Credential Rotation**: No long-lived credentials in pipelines
- **Audit Trail**: Complete history of what was deployed and who approved
- **Policy Enforcement**: Automated checks prevent non-compliant infrastructure
- **Rapid Remediation**: Quickly redeploy patched code

---

### 6.2 Securing CI/CD Pipelines

**Attack Vectors in Pipelines:**

```
Developer Machine Compromise
├── Attacker: Git credential theft
├── Attack: Push malicious code to repository
├── Result: Malicious code runs in pipeline, deployed to production
└── Mitigation: Signed commits (git sign-off), branch protection

Repository Compromise
├── Attacker: Stolen GitHub token
├── Attack: Modify pipeline configuration, add backdoor job
├── Result: Pipeline injects malicious code into builds
└── Mitigation: Token rotation, branch protection, code review

Pipeline Runner Compromise
├── Attacker: RCE in build script or dependency
├── Attack: Access runner resources (credentials, source code)
├── Result: Data exfiltration, infrastructure modification
└── Mitigation: Ephemeral runners, least privilege, network isolation

Secrets Exposure
├── Attacker: Pipeline logs contain AWS credentials
├── Attack: Parse logs, use credentials for unauthorized access
├── Result: AWS account compromise, data breach
└── Mitigation: Secret masking, Vault integration, no console output

Artifact Tampering
├── Attacker: Modify Docker image before deployment
├── Attack: Push payload into container registry
├── Result: Malicious code runs in production
└── Mitigation: Container image signing, verification before deploy

YAML Injection
├── Attacker: Pull request with malicious pipeline YAML
├── Attack: Execute arbitrary commands during pipeline
├── Result: Credentials stolen, infrastructure modified
└── Mitigation: PR validation, Dockfile scanning, script linting

Supply Chain Attack
├── Attacker: Compromise build dependency (npm, pip, etc.)
├── Attack: Inject malware into dependency
├── Result: Malware compiled into final artifact
└── Mitigation: SCA scanning, lockfiles, SBOM verification

Access Control Bypass
├── Attacker: Assume deployment role without approval
├── Attack: Deploy to production without review
├── Result: Unauthorized infrastructure changes
└── Mitigation: Group approval, manual gates, audit logging
```

**Secure Pipeline Architecture:**

```
┌─────────────────┐
│  Git Repository │
│  (protected)    │
└────────┬────────┘
         │ webhook on push
         │
  ┌──────▼──────────────────────┐
  │ GitHub/GitLab/Azure DevOps  │
  │ Initiates Pipeline          │
  └──────┬──────────────────────┘
         │
  ┌──────▼──────────────────────┐
  │ Pipeline Step: Checkout     │
  │ • Verify signed commits     │
  │ • Branch protection check   │
  └──────┬──────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Pipeline Step: Security Scanning        │
  │ • SAST (SpotBugs, Sonarqube)            │
  │ • SCA (Snyk, Dependabot)                │
  │ • Secrets (TruffleHog)                  │
  │ • IaC (Checkov, Tfsec)                  │
  │ Fail if critical findings               │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Pipeline Step: Build Artifact           │
  │ • Build application binary/image        │
  │ • Sign artifact (sigstore/cosign)       │
  │ • Push to artifact registry             │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Pipeline Step: Container Scanning       │
  │ • Scan image for CVEs (Trivy)           │
  │ • Check image signatures (Cosign)       │
  │ • Verify provenance (in-toto)           │
  │ Fail if vulnerabilities detected        │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Pipeline Step: Policy Evaluation        │
  │ • OPA/Sentinel: Infrastructure policy   │
  │ • Compliance checks (CIS, SOC 2)        │
  │ • Risk assessment                       │
  │ Fail if policy violated                 │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Manual Approval Gate (if required)      │
  │ • Requires human approval               │
  │ • Audit who approved, when, why         │
  │ • Approval via secure interface (MFA)   │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Pipeline Step: Deploy                   │
  │ • Assume role with temporary creds      │
  │ • Deploy to target environment          │
  │ • Register in deployment database       │
  └──────┬──────────────────────────────────┘
         │
  ┌──────▼──────────────────────────────────┐
  │ Post-Deployment                         │
  │ • Verify deployment succeeded           │
  │ • Log to immutable audit system         │
  │ • Cleanup temporary credentials         │
  │ • Notify stakeholders                   │
  └──────────────────────────────────────────┘
```

---

### 6.3 Secure Runners and Execution Environments

**Runner Types and Security Posture:**

```
GitHub-Hosted Runners (Managed by GitHub)
├── Advantages:
│   ├── Automatic patching and maintenance
│   ├── Ephemeral (fresh for each job)
│   ├── No persistent data between runs
│   └── Microsoft-managed infrastructure security
├── Disadvantages:
│   ├── Network isolated (cannot access private resources)
│   ├── Public IP (rate-limited by third parties)
│   └── Limited to GitHub Actions
└── Security Rating: ⭐⭐⭐⭐⭐ (5/5)

Self-Hosted Runners (On Your Infrastructure)
├── Advantages:
│   ├── Can access private resources (VPC, on-prem)
│   ├── High performance (hardware you control)
│   ├── Works with GitHub, GitLab, Jenkins, etc.
│   └── Customizable environment
├── Disadvantages:
│   ├── You manage security (patching, updates)
│   ├── Can be compromised (must assume breach)
│   ├── Persistent state between runs (isolation risk)
│   └── Cost to run 24/7
└── Security Rating: ⭐⭐⭐ (3/5) - depends on maintenance

Containerized Runners (Docker in Docker)
├── Advantages:
│   ├── Ephemeral (container deleted after each job)
│   ├── Isolated (separate filesystem, network per job)
│   ├── Fast startup (usually <5 seconds)
│   └── Consistent environment (Dockerfile defines it)
├── Disadvantages:
│   ├── Container escape risk (Docker socket mounted)
│   ├── Build complexity (multi-stage Dockerfile)
│   ├── Image supply chain risk
│   └── Storage overhead (large images)
└── Security Rating: ⭐⭐⭐⭐ (4/5)

Kubernetes-Based Runners (K8s Executor)
├── Advantages:
│   ├── Native multi-tenancy (pod per job)
│   ├── Resource limits enforced (CPU, memory, disk)
│   ├── Network policies (pod isolation)
│   ├── Ephemeral (pod deleted after job)
│   └── Scalable (auto-scale runners)
├── Disadvantages:
│   ├── K8s complexity (requires expertise)
│   ├── Storage: PVCs needed for caching
│   ├── Credential management complex
│   └── Debugging harder (pod already deleted)
└── Security Rating: ⭐⭐⭐⭐⭐ (5/5)
```

**Secure Runner Configuration:**

```bash
#!/bin/bash
# setup-secure-runner.sh - Setup hardened self-hosted runner

# Updates and security patches
apt-get update && apt-get upgrade -y
apt-get install -y ufw fail2ban auditd

# Firewall configuration
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp  # SSH only from bastion
ufw allow from 10.0.1.0/24 to any port 8080  # GitHub Actions port
ufw enable

# Fail2ban: Protect against brute-force SSH
systemctl enable fail2ban
systemctl start fail2ban

# Audit logging
systemctl enable auditd
systemctl start auditd

# Add audit rule for sudo
auditctl -w /etc/sudoers -p wa -k sudoers_changes

# Create non-root runner user
useradd -m -s /bin/bash -G docker runner
echo "runner ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/runner

# Disable swap (security best practice)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Install GitHub Actions runner
cd /opt/actions-runner
sudo -u runner ./config.sh \
  --url https://github.com/myorg/myrepo \
  --token <TOKEN> \
  --runnergroup secure-runners \
  --labels docker,secure \
  --unattended \
  --replace

# Install runner as service
./svc.sh install runner
./svc.sh start

# Runner will now be ephemeral if configured with task auto-cleanup
```

---

### 6.4 Ephemeral Environments and Agents

**Ephemeral vs. Persistent Runners:**

```
Persistent Runners (Risk):
├── Created: Month ago
├── Reused: Many thousands of builds
├── Filesystem: Contains build artifacts, logs, credentials cache
├── Threat: Compromised build can steal credentials from previous builds
├── Patching: Security update requires restartting active jobs
├── Debugging: Can SSH to runner and examine state
└── Consequence: Blast radius grows as state accumulates

Ephemeral Runners (Secure):
├── Created: 2 minutes ago
├── Reused: Exactly 1 build
├── Filesystem: Fresh, empty except build files
├── Threat: Compromised build cannot access previous builds' data
├── Patching: New runner starts with latest image automatically
├── Debugging: No SSH access (pod/container deleted after job)
└── Consequence: Blast radius limited to current job only
```

**Implementation - Ephemeral Runners with GitLab:**

```yaml
# .gitlab-ci.yml with ephemeral runners

stages:
  - build
  - test
  - deploy

variables:
  FF_USE_FASTZIP: "true"
  TRANSFER_METER_FREQUENCY: "5s"

# Ephemeral Docker runner
build:
  stage: build
  image: node:18-alpine  # Fresh image every time
  tags:
    - docker
    - ephemeral
  before_script:
    - echo "Runner IP: $(hostname -I)"  # Will be different for each build
  script:
    - npm install
    - npm run build
  artifacts:
    paths:
      - build/
    expire_in: 1 hour  # Cleanup after 1 hour
  cache:
    key: "$CI_COMMIT_REF_SLUG-build"
    paths:
      - node_modules/
    policy: pull-push

# Cleanup after job
cleanup:
  stage: .post
  image: node:18-alpine
  script:
    - echo "Cleanup job - runner will be destroyed after this"
    - rm -rf /home/gitlab-runner/builds/*  # Clean filesystem
  when: always

# Secure deployment with temporary credentials
deploy:
  stage: deploy
  image: amazon/aws-cli:latest
  tags:
    - docker
    - ephemeral
  script:
    # Assume role with OIDC (no long-lived credentials)
    - |
      STS_RESPONSE=$(aws sts assume-role-with-web-identity \
        --role-arn $DEPLOY_ROLE_ARN \
        --role-session-name "gitlab-run-${CI_PIPELINE_ID}" \
        --web-identity-token $CI_JOB_JWT)
    
    - export AWS_ACCESS_KEY_ID=$(echo $STS_RESPONSE | jq -r '.Credentials.AccessKeyId')
    - export AWS_SECRET_ACCESS_KEY=$(echo $STS_RESPONSE | jq -r '.Credentials.SecretAccessKey')
    - export AWS_SESSION_TOKEN=$(echo $STS_RESPONSE | jq -r '.Credentials.SessionToken')
    
    # Credentials automatically expire in 1 hour (session token expiry)
    - aws s3 cp build/ s3://app-artifacts/
  only:
    - main
```

**Implementation - Ephemeral Runners with GitHub Actions:**

```yaml
# .github/workflows/ephemeral-build.yml

name: Ephemeral Build Pipeline

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest  # GitHub-hosted = ephemeral by default
    container:  # Additional layer of isolation
      image: node:18-alpine
      options: --cpus 2 --memory 2g --network-aliases github-actions
    
    permissions:
      contents: read
      id-token: write  # Required for OIDC
    
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Setup Node
        run: |
          echo "Runner ID: $RUNNER_NAME"
          echo "Workspace: $GITHUB_WORKSPACE"
          echo "Platform: $(uname -a)"
      
      - name: Install dependencies
        run: npm install
      
      - name: Run tests
        run: npm test
      
      - name: Build artifact
        run: npm run build
      
      - name: Assume AWS role (OIDC)
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-role
          aws-region: us-east-1
      
      - name: Push to S3
        run: aws s3 cp build/ s3://app-artifacts/
      
      - name: Cleanup (automatic on job completion)
        if: always()
        run: |
          # GitHub Actions automatically destroy runner after job
          # No cleanup needed; runner is ephemeral
          echo "Job
 complete. Runner will be destroyed."
  
  # Container automatically cleaned up after job
```

---

### 6.5 Pipeline Isolation Strategies

**Network Isolation:**

```
┌────────────────────────────────────────────────────────────┐
│ Internet                                                   │
└────────────────────────────────────────────────────────────┘
         │
    ┌────▼─────┐
    │ NAT GW   │
    └────┬─────┘
         │
    ┌────▼─────────────────────────────────────────────┐
    │ Public Subnet (Pipeline Runners)                │
    │ • GitHub-hosted runners run here                │
    │ • Output-only traffic (artifact uploads)        │
    │ • Cannot reach private resources directly       │
    └────┬────────────────────────────────────────────┘
         │
    ┌────▼─────────────────────────────────────────────┐
    │ VPC Peering / PrivateLink                       │
    │ • Mutual TLS authentication                      │
    │ • No internet-routable IP                        │
    │ • Audit all traffic through this connection      │
    └────┬────────────────────────────────────────────┘
         │
    ┌────▼─────────────────────────────────────────────┐
    │ Private Subnet (Internal Resources)             │
    │ • RDS databases                                  │
    │ • Private Docker registries                      │
    │ • Secrets Manager VPC endpoints                 │
    │ • No direct internet access                      │
    └─────────────────────────────────────────────────┘
```

**Process Isolation (Containers):**

```
Host:
┌──────────────────────────────────────────┐
│ Linux Kernel                             │
│                                          │
│  ┌──────────────┐   ┌──────────────┐   │
│  │ Container 1  │   │ Container 2  │   │
│  │ (Build Job)  │   │ (Test Job)   │   │
│  │              │   │              │   │
│  │ PID: 1       │   │ PID: 1       │   │
│  │ UID: 0-65535 │   │ UID: 0-65535 │   │
│  │ Mounts: /app │   │ Mounts: /test│   │
│  │              │   │              │   │
│  │ cgroup limit │   │ cgroup limit │   │
│  │ CPU: 2       │   │ CPU: 2       │   │
│  │ Memory: 2GB  │   │ Memory: 2GB  │   │
│  │              │   │              │   │
│  └──────────────┘   └──────────────┘   │
│                                        │
│  Cannot see:                           │
│  ├── Each other's processes           │
│  ├── Each other's filesystems         │
│  ├── Each other's environment vars    │
│  ├── Host's sensitive files           │
│  └── Each other's network connections│
│                                        │
└──────────────────────────────────────────┘
```

**Credential Isolation:**

```
Job 1: Secrets Injection
│
├── AWS IAM Role (temporary, 1-hour max)
├── Environment Variables (passed, not stored)
├── Vault Token (ephemeral, job-scoped)
├── GitHub Token (action token, limited permissions)
└── Expires: After job completion
    
Job 2: Separate Credentials
│
├── AWS IAM Role (different from Job 1)
├── Environment Variables (different scope)
├── Vault Token (different token)
├── GitHub Token (different token)
└── Cannot use Job 1 credentials

Result:
├── Job 1 compromise doesn't expose Job 2 credentials
├── Each job gets only necessary permissions
├── Credentials automatically expire
└── No credential reuse across jobs
```

---

### 6.6 Popular Pipeline Security Tools

| Tool | Purpose | Integration | Strengths | Weaknesses |
|------|---------|-------------|----------|-----------|
| **Snyk** | Vulnerability scanning | GitHub, GitLab, Jenkins, Azure DevOps | SCA, IaC, container scanning unified | Requires account, cost for advanced features |
| **SonarQube** | Code quality & security | All platforms | SAST, detailed reports, custom rules | Self-hosted complexity, learning curve |
| **Sigstore/Cosign** | Artifact signing | All platforms | Keyless signing, PKI integration | Newer (adoption still growing) |
| **OPA/Conftest** | Policy enforcement | All platforms | Multi-format policies, testable | Rego language requires learning |
| **Aqua Trivy** | Container scanning | All platforms | Fast, lightweight, offline mode | Less comprehensive than commercial tools |
| **HashiCorp Vault** | Secrets management | All platforms | Enterprise-grade, dynamic secrets | Operational complexity, self-hosted |
| **OWASP Dependency-Check** | SCA-lite | All platforms | Open source, OWASP standard | Less accurate than commercial SCA tools |
| **Checkov** | IaC scanning | All platforms | Terraform, CloudFormation, K8s support | Can have false positives |
| **Renovate** | Dependency updates | GitHub, GitLab | Automatic PRs for dependency updates | Requires configuration tuning |
| **In-toto** | Supply chain integrity | All platforms | S slsa.dev standard, provenance | Complex setup, adoption still growing |

---

### 6.7 Best Practices for Pipeline Security in DevOps

**Pipeline Security Checklist:**

```yaml
Code Management:
  ☐ Enforce branch protection on main
  ☐ Require code reviews (at least 2 approvals)
  ☐ Require signed commits (git sign-off)
  ☐ Dismiss stale PR approvals
  ☐ Require status checks to pass before merge
  ☐ No force push to main
  ☐ Require conversation resolution before merge

Secrets Management:
  ☐ No hardcoded secrets in repository
  ☐ Pre-commit hooks scan for secrets
  ☐ No secrets in logs (use secret masking)
  ☐ Secrets Manager rotation implemented
  ☐ OIDC for credential injection (no long-lived keys)
  ☐ Secrets scoped to specific jobs/environments
  ☐ Temporary credentials with 1-hour max lifetime

Build Pipeline:
  ☐ SAST (SpotBugs, Sonarqube) - code scanning
  ☐ SCA (Snyk, Dependabot) - dependency scanning
  ☐ Secrets scanning (TruffleHog) - GitGuardian
  ☐ IaC scanning (Checkov, Tfsec) - infrastructure validation
  ☐ Container image scanning (Trivy, Snyk) - vulnerability check
  ☐ SBOM generation (syft, CycloneDX) - supply chain
  ☐ Artifact signing (Cosign, sigstore) - integrity proof

Artifact Management:
  ☐ Private registry (ECR, Docker Hub private)
  ☐ Registry authentication (IAM, tokens)
  ☐ Registry encryption enabled
  ☐ Container image signing before push
  ☐ Image verification before pull (production)
  ☐ Access logging for registry pulls
  ☐ Old images cleanup (lifecycle policy)

Deployment:
  ☐ Policy evaluation (OPA, Sentinel) before deploy
  ☐ Policy failover if policy engine down
  ☐ Manual approval gate for prod (if not test)
  ☐ Deployment approval audit trail (who, when, why)
  ☐ Role assumption with temporary credentials
  ☐ Least-privilege role per environment
  ☐ Deployment logging to CloudTrail

Runners:
  ☐ Ephemeral runners (fresh for each job)
  ☐ Resource limits enforced (CPU, memory)
  ☐ Network isolation (private subnet)
  ☐ No SSH access to runners
  ☐ Runner version updates automatic
  ☐ Security group restricted (not 0.0.0.0/0)
  ☐ Runner logs retention policy

Monitoring & Audit:
  ☐ Pipeline execution logged
  ☐ All deployments tracked in audit system
  ☐ Failed pipeline runs investigated
  ☐ Security findings reviewed weekly
  ☐ Alerts on unusual pipeline patterns
  ☐ Deployment dashboard showing changes per environment
  ☐ Incident post-mortem for pipeline breaches

Compliance:
  ☐ Deployment records for compliance audit
  ☐ Retention policy for pipeline logs (1 year)
  ☐ Access control for sensitive environments
  ☐ Change request tracking integrated with pipeline
  ☐ Seasonal compliance audits (quarterly)
```

---

### 6.8 Common Pitfalls and Mitigation

| Pitfall | Root Cause | Impact | Mitigation |
|---------|-----------|--------|-----------|
| **Secrets in Logs** | Console output prints variables | Exposed credentials in searchable logs | Use secret masking, never `echo $SECRET` |
| **YAML Injection** | Untrusted PR modifies pipeline | Arbitrary code execution during CI/CD | Validate YAML before execution (linting) |
| **Compromised Dependency** | Unvetted third-party actions | Malware in build, data exfiltration | SCA scanning, pin action versions, review diffs |
| **Self-Hosted Runner Persistence** | Runner reused across jobs | Previous job secrets accessible in next job | Ephemeral runners, filesystem cleanup |
| **Overpermissive Role** | Deploy role has admin access | Compromise allows infrastructure changes | Least-privilege role, limited to deployment needs |
| **No Manual Gate** | Automatic deployment to production | Untested/unapproved code in prod | Require approval before prod deployment |
| **Missing Artifact Signing** | No proof of artifact origin | Attacker swaps artifact in registry | Cosign signing, image verification |
| **No Container Scanning** | Vulnerable dependencies in image | Breach via known CVE in production | Trivy scanning before push to registry |
| **Long-lived Token** | Convenience, forgotten rotation | Stolen token = pipeline compromise | Auto-rotation, short expiration (1 hour) |
| **No Policy Evaluation** | Deployment not validated | Non-compliant infrastructure deployed | OPA/Sentinel policy gate before deploy |
| **GitHub Token Exposure** | Token printed in logs or diff | Attacker reuses token for unauthorized access | Use job-scoped token (short-lived), secret masking |
| **SSH Access to Runners** | Debugging via SSH | Attacker exploits to access build artifacts | No SSH access, ephemeral runners deleted after job |
| **No Approval Audit Trail** | Who approved deployment? Unknown | Cannot trace who approved bad deployment | Approval records with timestamp and approver identity |
| **Shared Runners Across Teams** | Resource contention, security bleed | Team A data visible to Team B | Separate runners per team/environment |


---

## 7. Secrets Management in CI/CD

*(Core principles, tools, and practices - detailed content to follow in Part 2)*

### Summary
Secrets management in CI/CD pipelines requires:
- **No hardcoded credentials** in code or configuration
- **Runtime injection** from external vaults (AWS Secrets Manager, HashiCorp Vault)
- **Automated rotation** with zero-downtime credential updates
- **Audit logging** of all secret access
- **Least-privilege** scoped to specific jobs/environments
- **Ephemeral credentials** with short-lived tokens (15 min - 1 hour max)

---

## 8. Authentication & Authorization Models

*(Core principles, protocols, and implementations - detailed content to follow in Part 2)*

### Summary
Modern authentication/authorization in DevOps:
- **OAuth 2.0**: Delegated authorization for third-party integrations
- **OIDC**: OpenID Connect for federated identity (GitHub Actions, GitLab CI/CD)
- **SAML**: Enterprise SSO for human users
- **Workload Identity**: Service-to-service authentication via short-lived tokens
- **MFA**: Required for sensitive operations (console access, deployments)

---

## 9. Encryption Concepts

*(Core principles, standards, and implementations - detailed content to follow in Part 2)*

### Summary
Encryption fundamentals for DevOps:
- **TLS 1.2+**: Industry standard for transport encryption
- **AES-256**: Symmetric encryption for data at rest
- **KMS (Key Management Service)**: Centralized key management
- **Perfect Forward Secrecy (PFS)**: Session-specific encryption even if long-term key compromised
- **Certificate Management**: Lifecycle, rotation, expiration monitoring
- **Encryption by Default**: Enable KMS on all data stores (S3, RDS, EBS)

---

## 10. Hands-on Scenarios

### Scenario 1: Security Groups Misconfiguration Causing Outage

**Problem Statement:**
You receive a P1 alert: Production API servers cannot reach the database. The error started 30 minutes ago without any infrastructure changes. All health checks in the load balancer are failing. Your team deployed code 2 hours ago, but database connectivity shouldn't be affected by application code changes.

**Architecture Context:**
```
Production Environment:
├── Load Balancer (ALB) - 0.0.0.0/0:443 → app-sg
├── App Servers (EC2) - app-sg
│   └── Outbound to RDS on port 3306
├── RDS Database - db-sg
│   └── Inbound from app-sg:3306
└── All in single VPC, same region
```

**Step-by-Step Troubleshooting:**

```bash
# Step 1: Verify network connectivity
ssh-i app-key.pem ec2-user@10.0.10.5
curl -v https://api.production.internal/health
# Response: Connection timeout

# Step 2: Verify EC2 can reach RDS at network level
telnet 10.0.20.5 3306
# Output: timeout (network-level issue, not application)

# Step 3: Check security group rules from EC2 console
# LOGIN: AWS Console → EC2 → Security Groups
# Found: app-sg outbound rule is restricted to app-sg only
# Problem: app-sg CANNOT reach db-sg (outbound to db-sg:3306 missing)

# Step 4: Find who changed the security group
aws ec2 describe-security-groups \
  --group-ids sg-0a1b2c3d4e5f6 \
  --region us-east-1

# Step 5: Audit via CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=app-sg \
  --max-results 10 \
  --region us-east-1 | jq '.Events[].CloudTrailEvent | fromjson | {EventTime, UserIdentity, EventName}' 

# Output shows: ModifySecurityGroupRules by terraform-automation-role
# Timestamp: 2 hours ago (timing matches)

# Step 6: Check Terraform state vs live
cd terraform/
terraform init
terraform plan -json | jq '.[] | select(.type == "aws_security_group_rule") | {address: .address, mode: .mode}'

# Step 7: Root cause analysis
# The Terraform code applies app-sg outbound rules, but terraform plan didn't show changes
# This suggests: Someone manually modified security group in AWS Console
# OR Terraform state was corrupted by concurrent apply

# Step 8: Check for concurrent Terraform applies
aws dynamodb scan \
  --table-name terraform-lock \
  --region us-east-1

# Output: Lock exists from terraform-automation, created 30 min ago
# Suggests: Long-running terraform apply that locked the resource

# Step 9: Immediate mitigation
# Add missing security group rule via AWS CLI
aws ec2 authorize-security-group-egress \
  --group-id sg-0a1b2c3d4e5f \
  --protocol tcp \
  --port 3306 \
  --source-security-group-id sg-0a1b2c3d4e5f \
  --region us-east-1

# Step 10: Verify connectivity restored
telnet 10.0.20.5 3306
# Output: Connected (should connect briefly to port)

# Step 11: Verify application health
curl https://api.production.internal/health
# Response: 200 OK

# Step 12: Update Terraform to prevent drift
# Edit security_group.tf to include missing rule:
resource "aws_security_group_rule" "app_to_db" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}

# Step 13: Apply Terraform update
terraform plan  # Verify no drift
terraform apply

# Step 14: Root cause prevention
# Issue: Security group rules modified outside of Terraform
# Solution: Enable AWS Config drift detection

# Create Config rule for security group compliance
aws configservice put-config-rule \
  --config-rule '{
    "ConfigRuleName": "restricted-ssh-prod",
    "Source": {
      "Owner": "AWS",
      "SourceIdentifier": "RESTRICTED_INCOMING_TRAFFIC"
    }
  }'

# Step 15: Audit all manual changes
# Review CloudTrail for all security group modifications in last 24 hours
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ModifySecurityGroupRules \
  --start-time 2026-03-21 \
  --end-time 2026-03-22 | jq '.Events[] | {UserIdentity, EventTime, EventSource}'
```

**Best Practices Applied:**
1. **Network Isolation**: Security groups enforce least privilege
2. **Audit Trail**: CloudTrail captures all changes with user identity
3. **IaC Enforcement**: Terraform declares desired state
4. **Drift Detection**: AWS Config monitors configuration changes
5. **CloudTrail Alerts**: Alert on manual security group changes
6. **Lock Mechanism**: Terraform locks prevent concurrent modifications
7. **Documentation**: Post-incident review document what happened

**Prevention:**
```hcl
# Terraform: Lock down manual changes via SCP
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PreventManualSecurityGroupChanges",
      "Effect": "Deny",
      "Action": [
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/terraform-automation",
            "arn:aws:iam::*:role/infrastructure-admin"
          ]
        }
      }
    }
  ]
}
```

---

### Scenario 2: Secrets Exposure in Pipeline Logs

**Problem Statement:**
Your security team receives an alert from GitHub's secret scanning: An AWS access key was detected in your GitLab CI pipeline logs. Investigation shows the logs are public on the GitLab runner output page accessible to anyone with the GitLab URL. The credential belongs to a CircleCI integration user that has S3 put/get permissions. This happened 4 days ago and hasn't been remediated yet.

**Architecture Context:**
```
Pipeline Flow:
├── Code Push → Trigger Job
├── Job Setup → Clone Repository
├── Job: Build Application
│   ├── Run: npm install
│   ├── Run: npm build
│   ├── Output: Build logs (PUBLIC)
│   └── Contains: AWS_ACCESS_KEY_ID in .env file
├── Job: Push Artifact
│   ├── Run: aws s3 cp dist/ s3://app-artifacts/
│   ├── Uses: Credential from build logs
│   └── Output: Success
└── Job artifacts kept for 1 week
```

**Step-by-Step Remediation:**

```bash
# Step 1: Assess exposure
# Timeline: Alert on day 4, exposed for 4 days
# Audience: Anyone with GitLab and job URL can access logs
# Credential: S3 put/get only (narrower than full AWS access)

# Step 2: Immediate credential rotation
# Option A: Download credentials from vault
vault kv get secret/prod/aws/s3-uploader
# Output: access_key = AKIAIOSFODNN7EXAMPLE

# Option B: Revoke old credential
aws iam delete-access-key --access-key-id AKIAIOSFODNN7EXAMPLE
# Verify all services fail over to backup credential
# Wait 5 minutes to ensure services transitioned

# Step 3: Create new credential
aws iam create-access-key --user-name s3-uploader
# Output: AccessKeyId, SecretAccessKey
# Store in: Vault under secret/prod/aws/s3-uploader (encrypted)

# Step 4: Update pipeline to use Vault instead of env var
# Before (WRONG):
cat > .env <<EOF
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=secretkey123456
EOF

# After (CORRECT):
export VAULT_TOKEN=$(vault write -field=token auth/jwt/login \
  role=pipeline-role \
  jwt=$CI_JOB_JWT)

export AWS_CREDENTIALS=$(vault kv get -format=json secret/prod/aws/s3-uploader)
export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq -r '.data.data.access_key_id')
export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq -r '.data.data.secret_access_key')
# Note: Still in env var, but retrieved at runtime and not in git history

# Even better: Use OIDC (no credential in memory)
export VAULT_ADDR=https://vault.prod.internal
export VAULT_ROLE=pipeline-s3-uploader

aws sts assume-role-with-web-identity \
  --role-arn arn:aws:iam::123456789012:role/pipeline-s3 \
  --role-session-name "gitlab-pipeline-${CI_PIPELINE_ID}" \
  --web-identity-token $CI_JOB_JWT_V2 \
  --duration-seconds 3600 > creds.json

export AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' creds.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' creds.json)
export AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' creds.json)
# Tokens auto-expire after 3600 seconds; no manual cleanup needed

# Step 5: Update security group to reject old credential
# This prevents old cred from being useful even if found
aws iam put-user-policy --user-name s3-uploader \
  --policy-name deny-old-credential-use \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Deny",
        "Action": "s3:*",
        "Resource": "*",
        "Condition": {
          "StringEquals": {
            "aws:AccessKeyId": "AKIAIOSFODNN7EXAMPLE"
          }
        }
      }
    ]
  }'

# Step 6: Audit what was accessed with old credential
aws s3api list-objects --bucket app-artifacts \
  --query 'Contents[?LastModified>=`2026-03-18`]'  # Exposure window

# Step 7: Check CloudTrail for suspicious activity
aws cloudtrail lookup-events \
  --start-time 2026-03-18 \
  --end-time 2026-03-22 \
  --query 'Events[?UserIdentity.accessKeyId==`AKIAIOSFODNN7EXAMPLE`]' \
  | jq '.[] | {EventTime, EventName, SourceIPAddress, EventSource}'

# If suspicious activity found:
# 1. Investigate each suspicious action
# 2. Determine if any data was accessed/modified
# 3. Notify data owners and compliance team
# 4. Review CloudTrail for lateral movement attempts

# Step 8: Prevent secrets in logs
# Update .gitignore in pipeline
cat >> .gitignore <<EOF
.env
.env.local
credentials.json
*.pem
*.key
EOF

# Setup pre-commit hook
cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/bash
# Scan for secrets before commit

files=$(git diff --cached --name-only)
for file in $files; do
  # Check for AWS credentials patterns
  if grep -E 'AKIA[0-9A-Z]{16}|aws_secret_access_key' "$file"; then
    echo "❌ AWS credentials detected in $file"
    exit 1
  fi
  
  # Check for private keys
  if grep -E 'BEGIN RSA PRIVATE KEY|BEGIN OPENSSH PRIVATE KEY' "$file"; then
    echo "❌ Private key detected in $file"
    exit 1
  fi
done
exit 0
HOOK

chmod +x .git/hooks/pre-commit

# Step 9: Enable secret masking in pipeline
# GitLab CI secret masking (hides secrets in job logs)
variables:
  AWS_ACCESS_KEY_ID:
    value: $AWS_S3_KEY
    description: "AWS credential for S3"

# Secrets auto-masked in output if they appear

# Step 10: Implement log scrubbing
# Add log masking tool to remove credentials before uploading
cat > scripts/mask-logs.sh <<'END'
#!/bin/bash
# Remove AWS credentials patterns from logs

LOG_FILE=$1

# Mask AWS access keys (AKIA...)
sed -i -E 's/AKIA[0-9A-Z]{16}/AKIA_REDACTED/g' "$LOG_FILE"

# Mask AWS secret keys
sed -i -E 's/aws_secret_access_key\s*=\s*[A-Za-z0-9\/+]+/aws_secret_access_key=REDACTED/g' "$LOG_FILE"

# Mask bearer tokens
sed -i -E 's/Bearer\s+[A-Za-z0-9_.-]+/Bearer REDACTED/g' "$LOG_FILE"

END

# Call after pipeline step
bash scripts/mask-logs.sh $CI_PROJECT_DIR/logs/*

# Step 11: Set log retention policy
# Delete job logs after 3 days (don't keep long-term)
# GitLab Setting: Admin → Settings → CI/CD → Job artifact expiration
# Set to: 3 days (reduces exposure window of logs if leaked)

# Step 12: Implement detection of leaked secrets
# Use TruffleHog to scan repository history for any existing secrets
trufflehog filesystem / --json > trufflehog-scan.json
cat trufflehog-scan.json | jq '.[] | select(.verified == true)'

# If found, immediately rotate those credentials

# Step 13: Post-incident documentation
cat > INCIDENT_REPORT.md <<'REPORT'
# Incident: AWS Credential Exposure in Pipeline Logs

## Timeline
- 2026-03-18 08:15 UTC: Pipeline job executes, credentials in logs
- 2026-03-22 14:30 UTC: Security alert received (4-day exposure)
- 2026-03-22 15:00 UTC: Credential rotated, log visibility changed

## Root Cause
- Credentials defined in .env file, checked into Git
- Pipeline printed .env during debugging
- Log output publicly accessible via GitLab web interface
- No secret masking enabled in CI/CD

## Blast Radius
- Credential: S3 uploader access only (not admin)
- Access: 4 days of log availability
- Usage: Reviewed CloudTrail, no suspicious access detected
- Action: Credential immediately revoked

## Resolution
1. Rotated AWS credential (new access key issued)
2. Enabled secret masking in GitLab CI
3. Set 3-day log retention policy
4. Implemented pre-commit hook for secrets scanning
5. Updated pipeline to use OIDC (no credential in memory)
6. Added TruffleHog scanning to repository

## Prevention
- Secrets Manager for all credentials
- OIDC authentication (no long-lived keys)
- Pre-commit hooks (TruffleHog scanning)
- Log masking enabled by default
- Short log retention (3 days)

REPORT
```

**Best Practices Applied:**
1. **Zero-Trust for Credentials**: Assume any exposed credential is compromised
2. **Immediate Rotation**: Old credential revoked within hours
3. **Audit Trail**: CloudTrail reviewed for unauthorized access
4. **Root Cause**: Systematic prevention of recurrence
5. **Defense in Depth**: Multiple layers (masking, scanning, log retention)

---

### Scenario 3: Cross-Account IAM Role Assumption Privilege Escalation

**Problem Statement:**
During a security audit, you discover that developers in the development account can assume a role in the production account with admin permissions. The intended behavior was developers should have read-only access to production resources for troubleshooting. An attacker with a compromised dev account credential could escalate privileges to production admin. You need to immediately fix this and audit who has access.

**Architecture Context:**
```
AWS Organization:
├── Development Account (123456789012)
│   ├── IAM Role: developer
│   ├── Permissions: S3 read, EC2 describe
│   └── Trust Relationship: (misconfigured)
├── Production Account (210987654321)
│   ├── IAM Role: production-admin
│   ├── Permissions: *:* (admin)
│   └── Trust Relationship: (allows dev account to assume)
└── Incident: Dev can assume prod-admin via trust relationship
```

**Step-by-Step Resolution:**

```bash
# Step 1: Identify the problematic IAM role
# Login to production account, navigate to IAM → Roles
# Find: production-admin role

aws iam get-role --role-name production-admin
# Check trust relationship (AssumeRolePolicyDocument)

# Output shows:
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"  # PROBLEM: Entire dev account can assume
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

# Step 2: Verify who can assume this role (security assessment)
aws iam get-role-policy --role-name production-admin --policy-name inline-policy

# Intending to see what users in dev account actually HAVE assume permissions
aws iam list-role-policies --role-name production-admin

# Step 3: Check which users in dev account have assume-role permission
aws iam get-group-policy \
  --group-name developers \
  --policy-name developer-policy --region us-east-1

# Output shows:
{
  "Action": [
    "sts:AssumeRole"
  ],
  "Resource": "*"  # ANY role in ANY account
}

# Step 4: Assess damage (who has accessed production)
aws sts get-caller-identity
# (need to assume the dev role first to see if anyone used it)

# Simulate assuming the role from dev account
aws sts assume-role \
  --role-arn arn:aws:iam::210987654321:role/production-admin \
  --role-session-name "test-escalation" \
  --duration-seconds 3600

# Output: Success - this confirms the vulnerability

# Step 5: Audit CloudTrail for role assumption
# Switch to production account
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --start-time 2026-03-01 \
  --max-results 50 \
  | jq '.Events[] | {UserIdentity.principalId, UserIdentity.sourceIPAddress, EventTime, EventName}'

# Look for any AssumeRole events from dev account principals (arn:aws:iam::123456789012:*)

# Step 6: Immediate fix - Restrict trust relationship
# Change trust relationship to specifically named role, not entire account

cat > trust-policy.json <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:role/prod-read-only-role"
        ]
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id-12345"  # Additional security
        },
        "IpAddress": {
          "aws:SourceIp": "10.0.0.0/8"  # Only from VPN/corp network
        },
        "StringLike": {
          "aws:userid": "*:prod-access-session"  # Session naming requirement
        }
      }
    }
  ]
}
POLICY

aws iam update-assume-role-policy-document \
  --role-name production-admin \
  --policy-document file://trust-policy.json

# Step 7: Remove incorrect developer permission
# Remove "sts:AssumeRole" on "*" resource from dev group

aws iam delete-group-policy \
  --group-name developers \
  --policy-name developer-policy

# Create new precise policy
cat > developers-precise-policy.json <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AdminAssumeRole",
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": [
        "arn:aws:iam::123456789012:role/dev-admin"
      ]
    }
  ]
}
POLICY

aws iam put-group-policy \
  --group-name developers \
  --policy-name developer-policy-restricted \
  --policy-document file://developers-precise-policy.json

# Step 8: Create proper prod read-only role in dev account
# (This is the role that dev users will assume to get prod read access)

cat > prod-read-only-trust.json <<'TRUST'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
TRUST

# In dev account, create the role
aws iam create-role \
  --role-name prod-read-only-role \
  --assume-role-policy-document file://prod-read-only-trust.json

# Attach read-only permissions
aws iam attach-role-policy \
  --role-name prod-read-only-role \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Step 9: Test the fix
# Try to assume production-admin (should now fail)
aws sts assume-role \
  --role-arn arn:aws:iam::210987654321:role/production-admin \
  --role-session-name "test-escalation-denied"
# Should error: "User is not authorized to perform: sts:AssumeRole"

# Try to assume prod-read-only-role (should succeed)
aws sts assume-role \
  --role-arn arn:aws:iam::210987654321:role/prod-read-only-role \
  --role-session-name "prod-access-session" \
  --duration-seconds 3600 \
  --external-id unique-external-id-12345

# Step 10: Audit all cross-account roles
aws iam list-roles | jq '.Roles[].AssumeRolePolicyDocument | select(.Statement[].Principal.AWS != null)'

# For each role, verify:
# 1. Trust relationship is specific (not root account)
# 2. Conditions restrict access (IP, ExternalId)
# 3. External ID is configured
# 4. Permissions are least-privilege

# Step 11: Implement preventative measures
# Create IAM policy to prevent over-permissive trust relationships

cat > prevent-over-permissive-trust.json <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOverPermissiveTrust",
      "Effect": "Deny",
      "Action": [
        "iam:PutRolePolicy",
        "iam:UpdateAssumeRolePolicy"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/*cross-account*",
            "arn:aws:iam::*:role/*assume*"
          ]
        }
      }
    }
  ]
}
POLICY

# Step 12: Monitor for future trust relationship changes
# Use EventBridge to alert on IAM policy changes

cat > eventbridge-rule.json <<'RULE'
{
  "Name": "monitor-cross-account-role-changes",
  "Description": "Alert on changes to cross-account IAM roles",
  "State": "ENABLED",
  "EventPattern": {
    "source": ["aws.iam"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["iam.amazonaws.com"],
      "eventName": [
        "UpdateAssumeRolePolicy",
        "PutRolePolicy",
        "CreateRole"
      ]
    }
  },
  "Target": {
    "Arn": "arn:aws:sns:us-east-1:210987654321:security-alerts",
    "RoleArn": "arn:aws:iam::210987654321:role/eventbridge-invoke-sns"
  }
}
RULE

aws events put-rule --name monitor-cross-account-role-changes \
  --event-pattern file://eventbridge-rule.json \
  --state ENABLED

# Step 13: Document the security boundary model
cat > SECURITY_BOUNDARIES.md <<'DOC'
# IAM Security Boundaries

## Cross-Account Assumptions

### Dev → Prod (Read-Only)
- Assumed by: arn:aws:iam::123456789012:role/prod-read-only-role
- Permissions: ReadOnlyAccess
- Duration: 1 hour max
- IP Restriction: 10.0.0.0/8
- Conditions: ExternalId required

### Dev → Dev (Admin)
- Assumed by: arn:aws:iam::123456789012:root
- Permissions: AdministratorAccess to dev only
- Duration: 1 hour max
- Duration policy prevents escalation

### Prod → Prod (Admin)
- Assumed by: Only specific named IAM users in prod account
- Never from another account
- Requires MFA
- Logged in CloudTrail
- Approval process for sensitive changes

## Preventative Controls
- ☐ IAM Policy Analyzer run monthly
- ☐ Trust relationships reviewed quarterly
- ☐ Cross-account access audit annually
- ☐ CloudTrail alerts on policy changes
- ☐ EventBridge rules monitor role changes

DOC
```

**Best Practices Applied:**
1. **Principle of Least Privilege**: Trust only specific roles, not entire account
2. **External IDs**: Additional verification for cross-account access
3. **Conditions**: IP restrictions, session naming, duration limits
4. **Audit Trail**: CloudTrail captures all assume-role actions
5. **Proactive Detection**: EventBridge alerts on policy changes
6. **Documentation**: Security boundaries documented and monitored

---

## 11. Most Asked Interview Questions

### Question 1: "Walk me through how you would audit and enforce least-privilege IAM across a multi-account AWS organization."

**Expected Senior Answer:**

"I'd implement a three-phase approach with continuous monitoring:

**Phase 1: Discovery & Assessment (2-4 weeks)**
- Use IAM Access Analyzer across all accounts to identify unused permissions
- Run AWS Trusted Advisor for security summary
- Query CloudTrail to see what actions principals actually use vs. what they can do
- Export all IAM policies, analyze with custom scripts for wildcards and overly broad permissions
- Identify roles with cross-account access and verify necessity

**Phase 2: Remediation (iterative, 3-6 months)**
- Start with non-critical layers: development accounts first
- Use policy simulator to test new policies before applying
- Implement ABAC (attribute-based access control) using tags for environment/team/project
- Replace action wildcards like 's3:*' with specific actions (GetObject, ListBucket, etc.)
- Add conditions: IP restrictions for sensitive roles, time-based access, MFA requirements
- Create tiered roles: ReadOnly → PowerUser → Admin → Super-Admin (with MFA)
- Implement service control policies (SCPs) to set guardrails at organization level

**Phase 3: Continuous Enforcement (ongoing)**
- Weekly IAM Policy Analyzer reviews (automated dashboard)
- Monthly access reviews where managers confirm team permissions
- CloudTrail alerts on policy changes (EventBridge → SNS)
- Config Rules to detect non-compliant policies (e.g., principals with admin)
- Quarterly comprehensive audit with executive sign-off

**Real-world example:**
I once inherited an organization where developers had full EC2 admin (iam:AttachUserPolicy). In 6 months, we reduced average policy size from 15 statements to 3-4. Used ABAC tags like Environment=prod, Team=backend which automatically scoped access. Result: 40% fewer over-privileged users, same productivity.

The key is: Don't do it all at once. You'll break something. Start with read-only roles (easiest to test), measure impact with access logs, then gradually tighten. And document exceptions explicitly."

---

### Question 2: "A developer accidentally committed AWS credentials to GitHub. What's your response plan, and how would you prevent it?"

**Expected Senior Answer:**

"This is a critical incident. I'd execute immediately:

**Immediate (Minutes 0-5):**
1. Revoke the credential in IAM (delete access key)
2. Check CloudTrail for any usage: `aws cloudtrail lookup-events --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=AKIA...`
3. If suspicious usage detected, initiate incident response (isolate accounts, check S3 for unauthorized changes, etc.)
4. Notify the developer and security team

**Short-term (Minutes 5-60):**
1. Git history is forever; credential can't be fully removed. Use BFG or git-filter-branch to rewrite history (but this breaks clones)
2. Better approach: Assume it's compromised, rotate everything the credential could access
3. If it was S3 uploader token: Rotate, check S3 access logs for unauthorized GET/PUT
4. If AWS account admin: Full security assessment
5. If it's in multiple repos: Find all instances, schedule coordinated remediation
6. Create incident report with timeline

**Prevention (Multi-layered):**

I'd implement three layers:

**Layer 1: Pre-commit hooks (Developer machine)**
- Install TruffleHog locally pre-commit hook
- Blocks commits that look like credentials (AKIA patterns, AWS secret key patterns, PEM keys)
- False positive rate ~2% but worth it since it's on developer machine

**Layer 2: Push-time scanning (GitHub)**
- Enable GitHub secret scanning (https://github.com/settings/security)
- GitHub automatically scans for known patterns
- If secret found, GitHub notifies immediately and auto-invalidates it
- Consider third-party like GitGuardian for enhanced detection

**Layer 3: Architecture (Prevent needing long-lived credentials)**
- Use OIDC for GitHub Actions (I'll explain this below)
- Use IAM roles for EC2/Lambda (never credentials on instances)
- Use Secrets Manager with auto-rotation
- Never dev credentials – only machine accounts, and rotate monthly

**OIDC Example (best practice):**
Instead of storing AWS IAM access keys in GitHub secrets, GitHub Actions assumes a role via OIDC:
```yaml
- uses: aws-actions/configure-aws-credentials@v2
  with:
    role-to-assume: arn:aws:iam::123456789012:role/github-actions-role
    aws-region: us-east-1
```
No credentials stored anywhere. AWS verifies GitHub's JWT token. Role assumed for ~1 hour. Done.

**I've seen:**
- One shop store every credential in vault and rotate every 7 days (overkill but secure)
- Another had one developer commit credentials monthly until we made pre-commit mandatory

The best defense is: Developers shouldn't have long-lived credentials at all. Ephemeral tokens only."

---

### Question 3: "How would you design a secure multi-account AWS strategy for a company with dev/staging/prod environments?"

**Expected Senior Answer:**

"I'd use AWS Organizations with a hub-and-spoke model. Here's the architecture:

**Account Structure:**
```
Root Organization
├── Billing Account (AWS Org management account)
│   ├── Billing only
│   ├── Access: CFO, Finance
│   └── Locked down (SCPs prevent resource creation)
├── Logging Account
│   ├── Centralized CloudTrail (all accounts)
│   ├── Centralized CloudWatch Logs
│   ├── Centralized GuardDuty findings
│   ├── Access: Security team only
│   └── All logs immutable (S3 versioning + MFA delete)
├── Security Account
│   ├── Secrets Manager (credentials for all accounts)
│   ├── AWS KMS keys (master keys for cross-account encryption)
│   ├── Security Hub (compliance aggregation)
│   ├── Config Aggregation (compliance view across accounts)
│   └── Access: SOC/Security team only
├── Dev Account (123456789012)
│   ├── Developers: Full access (fast iteration)
│   ├── IAM: Developers, DevOps, limited admin
│   ├── Cost limit: Allowance via AWS Budgets alerts
│   └── Assumption: Assume dev-admin role to do work
├── Staging Account (210987654321)
│   ├── Access: DevOps team (narrow access)
│   ├── IAM: No human admin (service accounts only)
│   ├── Approval: Required to deploy (3-way approval for DB changes)
│   └── Assumption: Cross-account assume from CI/CD
└── Production Account (300000000000)
    ├── Access: Very limited (on-call engineer only)
    ├── IAM: Named individuals only, MFA required
    ├── Immutable infrastructure (no SSH)
    ├── Approval: Both DevOps and on-call engineer for deploy
    ├── Separation: Critical data in separate account (for compliance)
    └── Assumption: Cross-account from CI/CD + manual approval
```

**Security Controls at Organization Level (SCPs):**

```json
{
  "Sid": "DenyLeavingOrganization",
  "Effect": "Deny",
  "Action": "organizations:LeaveOrganization",
  "Resource": "*"
}

{
  "Sid": "DenyDisablingCloudTrail",
  "Effect": "Deny",
  "Action": [
    "cloudtrail:DeleteTrail",
    "cloudtrail:StopLogging",
    "cloudtrail:UpdateTrail"
  ],
  "Resource": "*"
}

{
  "Sid": "RequireEncryption",
  "Effect": "Deny",
  "Action": [
    "s3:CreateBucket",
    "s3:PutBucketEncryption"
  ],
  "Resource": "*",
  "Condition": {
    "StringNotEquals": {
      "s3:x-amz-server-side-encryption": "aws:kms"
    }
  }
}
```

**Cross-Account Access Pattern:**

Dev → Prod access should be:
- Jenkins/GitLab assumes role in Prod via OIDC
- Role has only CloudFormation + EC2 update permissions (app deploy only)
- Role session scoped to 15 minutes
- All actions logged to centralized CloudTrail
- Approval required (manual gate in pipeline)

**Rationale:**
- Billing locked down: Prevents accidental (or malicious) high charges
- Logging centralized: Can't turn off CloudTrail locally
- Security account: Single source of truth for secrets/keys
- Separate prod-data account: Compliance/regulatory requirement (some industries need this)
- Cross-account roles: Blast radius limited to one role's permissions, not entire account
- SCPs: Last-resort guardrails (prevent accidental deletion, enforce standards)

**I've seen companies:**
- Too many accounts (50+) → unmanageable
- Too few accounts (1) → blast radius too large, compliance issues
- No separation of duties → developer can deploy prod without approval
- Single-account orgs → regretted it after scaling

The sweet spot I've found: 5-7 accounts minimum. More if regulatory requirements demand it."

---

### Question 4: "Explain the difference between a security group and a network ACL, and when you'd use each."

**Expected Senior Answer:**

"This is one of the most commonly misunderstood AWS concepts. Let me break it down with a real incident I debugged.

**Comparison:**

| Aspect | Security Group | Network ACL |
|--------|-----------------|------------|
| **Layer** | Layer 4 (transport) | Layer 3 (network) |
| **Stateful?** | Yes (response traffic auto-allowed) | No (must explicitly allow both directions) |
| **Rules** | Allow only (Deny implicit) | Allow AND Deny (Deny overrides Allow) |
| **Scope** | Per-instance/ENI | Per-subnet |
| **Rule Evaluation** | All rules evaluated (highest score wins) | Top-to-bottom (first match wins) |
| **Typical Use** | Day-to-day access control | Edge case denial, compliance rules |

**Real Example: Debugging Why App Can't Reach Database**

I once spent 4 hours debugging why an EC2 instance couldn't reach RDS. Here's what was wrong:

**Security Group on App Server (sg-app):**
```
Inbound: 0.0.0.0/0:443 (from ALB)
Outbound: ALL (0.0.0.0/0)  # Allows everything out
```

**Security Group on RDS Database (sg-db):**
```
Inbound: sg-app:3306 (only from app SG)
Outbound: (N/A – RDS doesn't use egress rules for response)
```

**Network ACL on Database Subnet:**
```
Inbound Rule 100:  Allow TCP 3306 from 10.0.10.0/24
Inbound Rule 110:  Allow TCP 1024-65535 (ephemeral responses)
Outbound Rule 100: Allow TCP 3306 to 10.0.10.0/24
Outbound Rule 110: Allow TCP 1024-65535 (responses)
Rule 120 (implicit): DENY ALL
```

**Problem:** The outbound ephemeral port range was 1024-65535, but MySQL picks a random port in that range for the response. When EC2 initiates connection on port 3306, MySQL responds on port (e.g., 49123). The NACL **outbound rule wasn't allowing that**.

**Solution:** Update NACL rule to explicitly allow ephemeral responses. This is why NACLs are confusing – security groups are stateful so you don't need to think about it.

**When I'd use Each:**

**Use Security Groups (99% of the time):**
- Day-to-day access control
- EC2 to RDS, Lambda to DynamoDB, ALB to backend
- Instance-specific rules
- Easy to modify

**Use NACLs (1% of cases):**
- Compliance requirement: Deny specific IPs or subnets (NACL deny rules prevent evasion)
- DDoS mitigation: Block known malicious CIDR blocks
- Multi-layer defense: Security groups + NACL belt-and-suspenders
- Protecting entire subnets from internet
- PCI-DSS requirement: Explicit allow lists with no implicit defaults

**Common Mistake:**
I see teams create super-permissive NACLs (0.0.0.0/0 allow all) thinking that security groups will protect them. But that defeats the purpose. If NACL allows all traffic, it's not adding security.

**Best Practice:**
- Keep NACLs at defaults (allow all, don't overthink)
- Put 100% of access control logic in security groups
- Only customize NACL if compliance or specific threat requires it

**Real incident I've handled:**
Competitor's AWS account got hacked. Attacker moved laterally between subnets. Better NACL rules (subnet → subnet deny) would have stopped lateral movement. Since then, I recommend: NACLs should deny other subnets by default, except explicit whitelisted subnets (like ALB subnet → app subnet)."

---

### Question 5: "You have thousands of S3 buckets across dozens of AWS accounts. How would you audit and ensure they're not publicly accessible?"

**Expected Senior Answer:**

"Large-scale S3 security is a real challenge. Here's a systematic approach:

**One-Time Audit (Weeks 1-2):**
```bash
# Use S3 Block Public Access (Account-level setting)
# This is the guardrail that stops accidents

for account in $(cat account-list.txt); do
  aws s3api put-account-public-access-block \
    --account-id $account \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
done
# This alone prevents 95% of accidental exposure

# Find existing public buckets (if any)
# Use S3 Inventory + Athena for fast querying
aws s3api list-buckets --query 'Buckets[].Name' > all-buckets.txt

# For each bucket, check public access
for bucket in $(cat all-buckets.txt); do
  # Check S3 public access block settings
  aws s3api get-public-access-block --bucket $bucket 2>/dev/null || echo "Bucket $bucket is public"
  
  # Check bucket policy for Principal: "*"
  aws s3api get-bucket-policy --bucket $bucket 2>/dev/null | \
    grep -q '"Principal":"\\*"' && echo "WARNING: $bucket has public policy"
  
  # Check ACLs
  aws s3api get-bucket-acl --bucket $bucket | grep -q 'AllUsers' && echo "WARNING: $bucket has public ACL"
done
```

**Ongoing Monitoring (After Audit):**

**Option 1: AWS Config Rules (simplest)**
```
Rule: S3_BUCKET_PUBLIC_READ_PROHIBITED
Rule: S3_BUCKET_PUBLIC_WRITE_PROHIBITED
Rule: S3_BLOCK_PUBLIC_ACCESS_ENABLED

These run continuously and alert on violations
```

**Option 2: Macie (ML-based)**
```
- Scans all S3 buckets in account
- Identifies sensitive data exposure risk
- Alerts if bucket becomes public
- Can auto-remediate (block public if critical data found)
```

**Option 3: Custom Lambda Function (most control)**
```python
import boto3
import json
from datetime import datetime

s3 = boto3.client('s3')
sns = boto3.client('sns')

def lambda_handler(event, context):
    paginator = s3.get_paginator('list_buckets')
    
    for page in paginator.paginate():
        for bucket in page['Buckets']:
            bucket_name = bucket['Name']
            
            try:
                # Check public access block
                response = s3.get_public_access_block(Bucket=bucket_name)
                settings = response['PublicAccessBlockConfiguration']
                
                if not all([
                    settings['BlockPublicAcls'],
                    settings['IgnorePublicAcls'],
                    settings['BlockPublicPolicy'],
                    settings['RestrictPublicBuckets']
                ]):
                    # Not fully blocked – investigate
                    alert_team(bucket_name, "Public access block not fully enabled")
                
                # Check policy for wildcards
                policy = s3.get_bucket_policy(Bucket=bucket_name)
                if '"Principal":"*"' in policy['Policy']:
                    alert_team(bucket_name, f"Bucket policy allows public access")
                    
            except Exception as e:
                # Bucket doesn't exist or permission denied
                pass
    
    return {'statusCode': 200}

def alert_team(bucket, reason):
    message = f"S3 Security Issue: {bucket}\nReason: {reason}\nTime: {datetime.now()}"
    sns.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:s3-security',
        Subject='S3 Public Access Alert',
        Message=message
    )
```

**Prevention (Before They Happen):**

**IAM Policy to prevent S3 from being made public:**
```json
{
  "Sid": "PreventPublicS3",
  "Effect": "Deny",
  "Action": [
    "s3:PutBucketPublicAccessBlock",
    "s3:PutAccountPublicAccessBlock"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "s3:x-amz-acl": "public-read"
    }
  }
}
```

**Terraform Enforcement:**
```hcl
# Require all S3 buckets have block public access enabled
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Make this required by policy:
# All S3 bucket creations must include public_access_block resource
```

**Real incident:**
Company's logo bucket was exposed by mistake. Logo is public anyway, but attacker wrote a 500GB file to it ($5K AWS bill). If they'd had account-level block public access, this couldn't happen. Cost of AWS Config Rule: <$1/month. Cost of incident: $5K + incident response time.

**Bottom line:**
1. Account-level S3 Block Public Access (must-have)
2. Config Rules for continuous compliance
3. S3 Inventory + Athena for auditing (if needed)
4. Macie if you have sensitive data
5. IAM policies preventing public access changes
6. Terraform/IaC enforcement so public buckets never accidentally created

The order matters: Block Public Access handles 95% of cases. Config Rules catch the 5%."

---

### Question 6: "Walk me through implementing OIDC for GitHub Actions to assume AWS IAM roles. Why is this better than IAM access keys?"

**Expected Senior Answer:**

"OIDC (OpenID Connect) is one of the best security improvements I've made to CI/CD. Let me explain the before, after, and why it matters.

**Before OIDC (Insecure):**
```
Setup:
1. Create IAM user for GitHub Actions
2. Create access key (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
3. Store in GitHub as repository secrets
4. GitHub Actions uses keys in every workflow

Problems:
- Long-lived credentials: Keys valid for years (until rotated)
- Exposure window: If secret leaks, attacker has unlimited time to use it
- Secret sprawl: Teams copy keys across repos (multiple copies = multiple risks)
- Key compromise: Rotating requires updating every repo that uses it
- No audit trail per repository (only per IAM user)
```

**After OIDC (Secure):**
```
Setup:
1. Configure OIDC provider in AWS (trust GitHub)
2. Create IAM role with trust relationship to GitHub
3. Role trusts GitHub's OIDC token as proof of identity
4. No credentials stored anywhere
5. GitHub automatically exchanges token for temporary AWS credentials

Benefits:
- Short-lived credentials: JWT token (~1 hour expiration)
- Unique per job: Each PR/push gets different token
- Repository-specific: Can scope access by repo, branch, commit SHA
- No rotation needed: Tokens auto-expire
- Audit trail: CloudTrail logs which repository/workflow did what
```

**How OIDC Works (step-by-step):**

```
1. GitHub Actions runs workflow
2. GitHub generates ephemeral JWT token containing:
   - Repository name: owner/repo
   - Branch: refs/heads/main
   - Commit SHA: abc123def456
   - Workflow: .github/workflows/deploy.yml
   - Run ID: 12345
   - Actor (who triggered): developers-team
   - Token expiry: 1 hour

3. Python script (aws-actions/configure-aws-credentials) runs:
   a. Reads JWT token from $ACTIONS_ID_TOKEN_REQUEST_TOKEN
   b. Sends token to AWS STS endpoint
   c. AWS verifies token signature (using GitHub's public key)
   d. AWS checks: "Is this token from trusted GitHub?"
   e. AWS checks: "Does IAM role trust this specific repository?"
   f. AWS returns temporary access key valid for ~1 hour

4. GitHub Actions exports AWS credentials
5. Workflow runs with temporary credentials
6. After 1 hour: Credentials automatically expire
7. CloudTrail logs: "arn:aws:sts::123456789012:assumed-role/github-actions-role/owner-repo-main-abc123def456"
```

**Setup Code (AWS side):**

```python
# Create OIDC provider trust
import boto3

iam = boto3.client('iam')

# Step 1: Create OIDC provider (one-time)
oidc_provider = iam.create_open_id_connect_provider(
    Url='https://token.actions.githubusercontent.com',
    ClientIDList=['sts.amazonaws.com'],
    ThumbprintList=['6938fd4d98bab03faadb97b34396831e3780aea1']  # GitHub's OIDC thumbprint
)

# Step 2: Create IAM role that trusts GitHub
trust_policy = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": f"arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
                },
                "StringLike": {
                    "token.actions.githubusercontent.com:sub": "repo:myorg/myrepo:ref:refs/heads/main"
                }
            }
        }
    ]
}

role_response = iam.create_role(
    RoleName='github-actions-deploy-role',
    AssumeRolePolicyDocument=json.dumps(trust_policy)
)

# Step 3: Attach deployment permissions
iam.attach_role_policy(
    RoleName='github-actions-deploy-role',
    PolicyArn='arn:aws:iam::123456789012:policy/github-actions-deploy'
)
```

**GitHub Workflow (client side):**

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Required for OIDC
      contents: read
    
    steps:
      - uses: actions/checkout@v3
      
      # This is the key step – configures AWS credentials via OIDC
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789012:role/github-actions-deploy-role
          aws-region: us-east-1
          role-duration-seconds: 3600  # Max 1 hour
      
      # No AWS_ACCESS_KEY_ID or AWS_SECRET_ACCESS_KEY needed!
      # Credentials are injected automatically by configure-aws-credentials
      
      - run: aws s3 cp build/ s3://app-artifacts/
      
      # After job: credentials automatically expire
```

**Condition Filtering (for fine-grained control):**

```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      // Allow only main branch of specific repo
      "token.actions.githubusercontent.com:sub": [
        "repo:myorg/production-app:ref:refs/heads/main",
        "repo:myorg/infrastructure:ref:refs/heads/main"
      ]
    }
  }
}
```

This means:
- Staging branch pushes: CANNOT assume role (access denied)
- Other repositories: CANNOT assume role (even in same organization)
- PR from fork: CANNOT assume role (different repository)
- Main branch: YES, can assume role

**Audit Trail (CloudTrail):**

```json
{
  "eventSource": "sts.amazonaws.com",
  "eventName": "AssumeRoleWithWebIdentity",
  "requestParameters": {
    "roleArn": "arn:aws:iam::123456789012:role/github-actions-deploy-role",
    "roleSessionName": "myorg-production-app-main-abc123def456",
    "durationSeconds": 3600
  },
  "responseElements": {
    "credentials": {
      "sessionToken": "..."
    }
  },
  "sourceIPAddress": "140.82.112.0/20"  // GitHub's IP
}
```

You can see exactly which repository and branch requested the credentials.

**Comparison: OIDC vs IAM Keys**

| Aspect | IAM Keys | OIDC |
|--------|----------|------|
| Lifetime | Years | 1 hour |
| Storage | GitHub secrets | None (ephemeral) |
| Rotation | Manual/monthly risk | Automatic (new token each job) |
| Scope | Entire repository | Per-branch, per-job |
| Repository isolation | No (key works in all forks) | Yes (token tied to specific repo) |
| Audit | Per-user, not per-repo | Per-repository, per-workflow, per-commit |
| Cost to implement | 5 minutes | 30 minutes (one-time) |
| Security | Medium | High |

**Why this matters:**
If GitHub repository gets compromised (hacked) or someone exfils the IAM key:
- With IAM keys: Attacker has credentials for years
- With OIDC: Attacker has 1-hour credentials for that specific repository

I've rolled this out to 20+ teams and it's one of my security wins. Everyone complains about complexity at first, but after reading this explanation, it clicks."

---

### Question 7: "Describe a situation where you had to debug a complex VPC networking issue. How did you approach it?"

**Expected Senior Answer:**

"Great question. I'll walk through a real incident that took me 6 hours to solve:

**The Problem:**
ECS task couldn't reach Aurora RDS database. Error: `Connection timeout (port 3306)`. This started after cluster scaling up.

**What I Knew:**
- 5 identical EC2 instances, 3 working, 2 failing
- Same RDS database, properly configured
- Same security groups
- Same subnet
- Same application code

**Debugging Approach (Layered, bottom-to-top):**

**Layer 1: Network Connectivity (TCP level)**
```bash
# From affected EC2, check physical network connectivity
ping 10.0.20.5  # RDS IP
# Output: TIMEOUT (network issue, not application)

# Check route table
ip route show
# Output shows default route via NAT gateway

# So traffic should flow: EC2 → NAT GW → RDS
# Problem: Can't reach RDS at all (ping timeout)

# Is RDS in same VPC?
aws rds describe-db-instances --db-instance-identifier prod-db | grep 'Endpoint\|VpcSecurityGroups'
# Output: VpcSecurityGroupId=sg-1234, Endpoint=prod-db.region.rds.amazonaws.com (10.0.20.5)
```

**Layer 2: Security Groups**
```bash
# Check EC2 security group
aws ec2 describe-security-groups --group-ids sg-0a1b2c3d | jq '.SecurityGroups[0].IpPermissions'
# Output: Outbound allows 0.0.0.0/0 (should be fine)

# Check RDS security group
aws rds describe-db-instances --query 'DBInstances[0].VpcSecurityGroups'
# Output: sg-0a1b2c3d (same SG as EC2!)

# Ah! Both EC2 and RDS are in same SG. Let's check ingress
aws ec2 describe-security-groups --group-ids sg-0a1b2c3d | \
  jq '.SecurityGroups[0].IpPermissions | .[] | select(.FromPort == 3306)'

# Output: No rules - port 3306 not allowing traffic!
# But working instances are in same SG... why do they work?
```

**Layer 3: The Aha Moment**
```bash
# Let me check which instances are working vs not working
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,PrivateIpAddress,State.Name,SubnetId]' --output table

# Output (table):
# Instance1: 10.0.10.5, running, subnet-a (working)
# Instance2: 10.0.10.6, running, subnet-a (working)
# Instance3: 10.0.10.7, running, subnet-a (working)
# Instance4: 10.0.11.5, running, subnet-b (BROKEN)
# Instance5: 10.0.11.6, running, subnet-b (BROKEN)

# Aha! Failing instances are in different subnet (subnet-b)
# Let's check the Network ACL for subnet-b

aws ec2 describe-network-acls \
  --filter "Name=association.subnet-id,Values=subnet-11111111" | \
  jq '.NetworkAcls[0].Entries | sort_by(.RuleNumber)' | \
  jq '.[] | {RuleNumber, Protocol, PortRange: .PortRange, CidrBlock, Egress}'

# Output (abbreviated):
# RuleNumber=100, Egress=false, Protocol=TCP, Port=443, CIDR=0.0.0.0/0, ALLOW
# RuleNumber=110, Egress=false, Protocol=TCP, Port=80, CIDR=0.0.0.0/0, ALLOW
# ... (more rules)
# RuleNumber=3306, Egress=false, Protocol=TCP, Port=3306, CIDR=10.0.20.0/24, ALLOW
# RuleNumber=32767, Egress=false, Protocol=-1, CIDR=0.0.0.0/0, DENY (default)

# Port 3306 rule IS there, so why doesn't it work?

# Wait... the rule number is 3306. Rule numbers matter!
# Rules are evaluated top to bottom; first match wins

# Let me see the full ordered list
aws ec2 describe-network-acls \
  --filter "Name=association.subnet-id,Values=subnet-11111111" | \
  jq '.NetworkAcls[0].Entries[] | select(.Egress == false) | sort_by(.RuleNumber) | {RuleNumber, Protocol, PortRange, CidrBlock}'

# OUTPUT:
# RuleNumber=100, Protocol=TCP, PortRange={From=443, To=443}, CIDR=0.0.0.0/0
# RuleNumber=110, Protocol=TCP, PortRange={From=80, To=80}, CIDR=0.0.0.0/0
# RuleNumber=120, Protocol=TCP, PortRange={From=22, To=22}, CIDR=10.0.0.0/8
# RuleNumber=130, Protocol=TCP, PortRange={From=1024, To=65535}, CIDR=0.0.0.0/0  <-- THIS MATCHES FIRST!
# RuleNumber=3306, Protocol=TCP, PortRange={From=3306, To=3306}, CIDR=10.0.20.0/24  <-- Never reached
# RuleNumber=32767, Protocol=-1, CIDR=0.0.0.0/0, DENY

# THE BUG: Rule 130 allows ephemeral ports (1024-65535) for all traffic.
# When EC2 initiates connection to RDS:3306, the response comes back on an ephemeral port (e.g., 49000).
# Rule 130 (ephemeral) allows the outbound connection to initiate, BUT:
#
# Response traffic from RDS:3306 back to EC2 comes on a random ephemeral port (e.g., RDS:49000 → EC2:12345)
# This matches Rule 130 but with source port 49000 (from RDS), not destination port 3306.

# Actually wait, that's egress. Let me check EGRESS rules...
```

**Layer 4: The Real Issue (Egress Rules)**
```bash
# Check EGRESS rules for subnet-b (outbound from instances to database)
aws ec2 describe-network-acls \
  --filter "Name=association.subnet-id,Values=subnet-11111111" | \
  jq '.NetworkAcls[0].Entries[] | select(.Egress == true) | sort_by(.RuleNumber)'

# OUTPUT (egress):
# RuleNumber=100, Protocol=TCP, PortRange={From=443, To=443}, CIDR=0.0.0.0/0, ALLOW
# RuleNumber=110, Protocol=TCP, PortRange={From=80, To=80}, CIDR=0.0.0.0/0, ALLOW
# RuleNumber=120, Protocol=TCP, PortRange={From=1024, To=65535}, CIDR=0.0.0.0/0, ALLOW  <-- Generic ephemeral
# RuleNumber=130, Protocol=TCP, PortRange={From=3306, To=3306}, CIDR=10.0.20.0/24, ALLOW  <-- Too late!
# RuleNumber=32767, Protocol=-1, CIDR=0.0.0.0/0, DENY

# FOUND IT!
# Egress Rule 120 allows 1024-65535 to 0.0.0.0/0
# Egress Rule 130 allows 3306 to RDS (10.0.20.0/24)
#
# Problem: Rule 120 matches first ("Allow any ephemeral port to anywhere")
# This is overly broad. When MySQL connection initiates on :3306, it matches rule 120 first.
# But the RESPONSE packet from RDS:3306 comes back on a different ephemeral port.
#
# Actually, I realize NACLs are stateless. So I need to think about this differently...
```

**Layer 5: Understanding Stateless NACL Behavior**
```bash
# Connection flow:
# 1. EC2 (10.0.11.5:49000) → RDS (10.0.20.5:3306)  [Outbound from EC2's perspective]
#    Matches NACL egress rule 120 (Allow 1024-65535) ✓
#
# 2. RDS (10.0.20.5:3306) → EC2 (10.0.11.5:49000)  [Inbound to EC2's perspective]
#    This response packet: Source=10.0.20.5:3306, Dest=10.0.11.5:49000
#    Checking EC2's NACL ingress rules (from subnet-b):
#    Rule 100: TCP 443 - NO
#    Rule 110: TCP 80 - NO
#    Rule 120: TCP 22 - NO
#    Rule 130: TCP 1024-65535 from ANY - SHOULD MATCH!
#
#    But wait, Rule 130 should match... unless...
#    Check the CIDR block for Rule 130

# Get full details
aws ec2 describe-network-acls \
  --filter "Name=association.subnet-id,Values=subnet-11111111" | \
  jq '.NetworkAcls[0].Entries[] | select(.Egress == true and .RuleNumber == 130) | {RuleNumber, Protocol, PortRange, CidrBlock, RuleAction}'

# OUTPUT:
# CidrBlock: 10.0.20.0/24
# RuleAction: ALLOW
# But rule 120 is:
# CidrBlock: 0.0.0.0/0

# Response packet from RDS comes from 10.0.20.5 - matches 0.0.0.0/0
# But Rule 120 is EGRESS (outbound from EC2's subnet), not INGRESS

# Let me check INGRESS rules properly
aws ec2 describe-network-acls \
  --filter "Name=association.subnet-id,Values=subnet-11111111" | \
  jq '.NetworkAcls[0].Entries[] | select(.Egress == false)'

# INGRESS OUTPUT (all of them):
# RuleNumber=100, Protocol=TCP, PortRange={From=443, To=443}, CIDR=0.0.0.0/0, ALLOW
# RuleNumber=110, Protocol=TCP, PortRange={From=80, To=80}, CIDR=0.0.0.0/0, ALLOW
# RuleNumber=120, Protocol=TCP, PortRange={From=22, To=22}, CIDR=10.0.0.0/8, ALLOW
# RuleNumber=32767, Protocol=-1, CIDR=0.0.0.0/0, DENY (implicit)

# THERE IT IS!!!
# Ingress rule 120 only allows port 22 (SSH)
# No rule allows inbound port 1024-65535 (ephemeral response traffic)!
#
# So the flow fails at:
# Step 2: RDS (10.0.20.5:3306) → EC2 (10.0.11.5:49000)
#   Checking ingress NACL: Port 49000, from 10.0.20.5
#   Rule 100: Port 443 - NO
#   Rule 110: Port 80 - NO
#   Rule 120: Port 22 - NO
#   Rule 32767: DENY ALL - YES (blocked)
```

**The Fix:**
```bash
# Add ingress rule to allow ephemeral ports
aws ec2 create-network-acl-entry \
  --network-acl-id acl-123456 \
  --rule-number 130 \
  --protocol tcp \
  --port-range From=1024,To=65535 \
  --cidr-block 10.0.20.0/24 \
  --ingress

# Verify instances can now connect
ssh -i key.pem ec2-user@10.0.11.5
mysql -h 10.0.20.5 -u admin -p
# Connected!
```

**Root Cause:**
Someone created a NACL for subnet-b with restrictive rules (443, 80, SSH only) but forgot to add ephemeral port responses. When instances scaled to subnet-b, they had no ingress rule for response traffic.

**Why It Took 6 Hours:**
- Assumed it was security group (first hour) - common issue
- Checked application logs (second hour) - looked like connection timeout
- Tested from bastion with mysql-cli (third hour) - worked from bastion (different subnet!)
- Finally realized instances in subnet-b failed, subnet-a worked (fourth hour)
- NACL investigation took two more hours because:
  - Stateless rules are confusing
  - Had to understand ephemeral port ranges
  - Had to trace exact packet flow in both directions

**What I Learned:**
- Always check source and destination (ping vs telnet)
- Security groups are stateful, misunderstanding is common
- NACLs are stateless - both inbound AND outbound must explicitly allow
- Ephemeral ports (1024-65535) needed for responses
- Subnet-level failures are less obvious than instance-level

**Prevention:**
- Default NACL: Allow all (let security groups do the work)
- Only customize NACL if compliance requires explicit allow lists
- Document NACL rules with comments explaining ephemeral ports
- Use NACLs for blast radius containment, not primary access control"

---

### Question 8: "What's your approach to credential rotation in a production environment?"

**Expected Senior Answer:**

"Credential rotation is hard because doing it wrong causes outages. I'll walk through my production playbook:

**For Database Credentials (RDS):**

```bash
# AWS Secrets Manager auto-rotation (best practice)
# Creates new master user password every 30 days, zero downtime

# Setup (one-time):
aws secretsmanager create-secret \
  --name prod/rds/master \
  --secret-string '{"username":"admin","password":"InitialPassword123"}'

aws secretsmanager rotate-secret \
  --secret-id prod/rds/master \
  --rotation-rules AutomaticallyAfterDays=30

# How it works:
# 1. Create new password in Secrets Manager
# 2. Update RDS master user password to new value
# 3. Test connection with new password
# 4. Store in Secrets Manager
# 5. Update old password to new value (for backward compatibility)
# 6. Done - zero application downtime

# Applications read password from Secrets Manager (always current):
aws secretsmanager get-secret-value --secret-id prod/rds/master \
  | jq -r '.SecretString | fromjson.password'
```

**For API Keys (e.g., Datadog, external services):**

```bash
# This is tricky because you can't always create new key without outage
# Strategy: Maintain two keys (blue-green)

# Day 1: Create secondary API key
datadog_api_key_new=$(curl -X POST \
  https://api.datadoghq.com/api/admin/users \
  -H "Authorization: Bearer $DATADOG_KEY" \
  -d '{"name":"api-key-2"}' \
  | jq -r '.key')

# Store temporarily
aws secretsmanager update-secret \
  --secret-id datadog-api-key \
  --secret-string "{\"primary\":\"$DATADOG_KEY\",\"secondary\":\"$datadog_api_key_new\"}"

# Day 2-7: Applications use secondary key (gradual rollout)
# Monitoring: Verify secondary key is working in all environments

# Day 8: Applications fully switched to secondary
# Delete old primary key
datadog_delete_old_key($old_key)

# Day 9: Rename secondary to primary
aws secretsmanager update-secret \
  --secret-id datadog-api-key \
  --secret-string "{\"primary\":\"$datadog_api_key_new\"}"
```

**For AWS IAM Access Keys (CI/CD):**

```bash
# Delete long-lived keys entirely, use OIDC instead
# If stuck with keys, rotate weekly:

# Cleanup script
#!/bin/bash
set -e

service_account_user="github-actions"

# List all access keys
keys=$(aws iam list-access-keys --user-name $service_account_user --query 'AccessKeyMetadata[].AccessKeyId' --output text)

# If more than 1 key exists, delete the oldest
key_count=$(echo $keys | wc -w)
if [[ $key_count -gt 1 ]]; then
  # Find creation time
  oldest_key=$(aws iam list-access-keys \
    --user-name $service_account_user \
    --query 'sort_by(AccessKeyMetadata, &CreateDate)[0].AccessKeyId' \
    --output text)
  
  # Before deleting, verify no applications use old key
  aws iam get-access-key-last-used --access-key-id $oldest_key | \
    jq '.AccessKeyLastUsed'
  
  # If usage > 7 days ago, safe to delete
  if [[ $(date -d "$(jq .AccessKeyLastUsed.LastUsedDate)" +%s) -lt $(date -d "7 days ago" +%s) ]]; then
    aws iam delete-access-key --user-name $service_account_user --access-key-id $oldest_key
  fi
fi

# Create new key
new_key=$(aws iam create-access-key --user-name $service_account_user)
export AWS_ACCESS_KEY_ID=$(echo $new_key | jq -r '.AccessKey.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $new_key | jq -r '.AccessKey.SecretAccessKey')

# Update GitHub secret
gh secret set AWS_ACCESS_KEY_ID --body $AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY --body $AWS_SECRET_ACCESS_KEY

# Test
aws sts get-caller-identity

# If key rotation fails, CloudTrail will show API errors
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateAccessKey \
  --start-time $(date -Iseconds -d "1 hour ago") \
  | jq '.Events[] | {EventTime, ErrorCode, ErrorMessage}'
```

**The Dangerous Way (what NOT to do):**

```bash
# ❌ WRONG: Rotate all keys at once
for key in $(all_service_keys); do
  aws iam delete-access-key --access-key-id $key  # Immediate deletion
done
# Result: All services fail simultaneously, massive outage

# ✅ RIGHT: Rolling rotation (blue-green)
# - Create new key
# - Scale to 10% traffic with new key
# - Wait 24 hours, monitor for errors
# - Scale to 50% traffic
# - Wait 24 hours
# - Scale to 100%
# - Delete old key
```

**Audit Trail for Rotations:**

```bash
# Track all credential changes
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=RotateSecret \
  --start-time 2026-01-01 \
  --max-results 50 \
  | jq '.Events[] | {EventTime, UserIdentity.principalId, EventName, RequestParameters}'

# Should log:
# - Who initiated rotation (automation role?)
# - When (timestamp)
# - Which credential (ARN)
# - Success/failure
```

**Compliance & Documentation:**

```markdown
# Credential Rotation Policy

## Schedule
- Database passwords: Automatic every 30 days (Secrets Manager)
- IAM user keys: Every 90 days (quarterly)
- API keys: Every 180 days (semi-annual)
- Emergency rotation: Immediately if compromise suspected

## Process
1. Create new credential (don't delete old yet)
2. Test with new credential (no traffic)
3. Route 10% traffic through new credential
4. Monitor for errors (24 hours)
5. Route 50% traffic
6. Monitor (24 hours)
7. Route 100% traffic
8. Delete old credential AFTER 30 days (grace period for rollback)

## Monitoring
- CloudTrail logs all create/delete/rotate events
- Failed rotations alert on-call engineer
- Credentials older than max age trigger alerts
- Unused credentials cleaned up (lifecycle)

## Escalation
- Rotation fails → Page on-call
- Duplicate credentials in use → Investigation
- Evidence of credential compromise → Incident
```

**Real incident I handled:**
Customer's API key expired during production deployment. App kept retrying with old key. AWS rate-limited the failures. Service went down for 2 hours. Recovery: Manual key replacement in CloudFormation, redeploy. The problem: Credential rotation hadn't happened since setup 3 years ago. Now I automate everything."

---

### Question 9: "Explain how you'd implement and audit a secrets rotation policy across multiple environments (dev, staging, prod)."

**Expected Senior Answer:**

"This is enterprise-grade security automation. I'll explain my complete solution:

**Architecture Overview:**

```
┌─────────────────────────────────────────────────────────────┐
│ Secrets Rotation Orchestration                              │
└─────────────────────────────────────────────────────────────┘
         │
    ┌────▼────────────┐
    │ AWS Secrets     │
    │ Manager (dev)   │
    │ Auto-rotate:30d │
    └────┬────────────┘
         │ triggers
    ┌────▼────────────────────────────────────┐
    │ Lambda Rotation Function                │
    │  1. Generate new password               │
    │  2. Update RDS/app                      │
    │  3. Test connectivity                   │
    │  4. Store in Secrets Manager            │
    │  5. Notify ops team                     │
    └────┬────────────────────────────────────┘
         │
    ┌────▼─────────────┐
    │ CloudWatch Logs  │
    │ (Audit Trail)    │
    └────┬─────────────┘
         │
    ┌────▼─────────────────────────────┐
    │ SNS Notifications (on-call)      │
    │ • Success: Quiet                 │
    │ • Failure: PagerDuty alert       │
    │ • Schedule: Every rotation       │
    └─────────────────────────────────┘
```

**Implementation (Python Lambda):**

```python
import boto3
import json
import time
from datetime import datetime
import requests

secrets_client = boto3.client('secretsmanager')
rds_client = boto3.client('rds')
sns_client = boto3.client('sns')

def lambda_handler(event, context):
    """
    Rotate RDS password for database secret
    Triggered by Secrets Manager on schedule
    """
    
    secret_id = event['SecretId']
    client_request_token = event['ClientRequestToken']
    environment = secret_id.split('/')[1]  # dev, staging, prod
    
    try:
        # Step 1: Get the current secret
        secret = secrets_client.get_secret_value(SecretId=secret_id)
        secret_dict = json.loads(secret['SecretString'])
        
        # Step 2: Generate new password
        new_password = generate_secure_password()
        
        # Step 3: Get the rotation metadata
        metadata = secrets_client.describe_secret(SecretId=secret_id)
        
        # Step 4: Update the password in RDS
        db_instance_identifier = secret_dict['dbname']
        rds_client.modify_db_instance(
            DBInstanceIdentifier=db_instance_identifier,
            MasterUserPassword=new_password,
            ApplyImmediately=True
        )
        
        # Step 5: Test the connection with new password
        is_connected = test_db_connection(
            host=secret_dict['host'],
            user=secret_dict['username'],
            password=new_password,
            database=secret_dict['dbname']
        )
        
        if not is_connected:
            raise Exception("Failed to connect with new password")
        
        # Step 6: Update the secret in Secrets Manager
        secret_dict['password'] = new_password
        secrets_client.put_secret_value(
            SecretId=secret_id,
            ClientRequestToken=client_request_token,
            Secret=json.dumps(secret_dict),
            VersionStages=['AWSCURRENT']
        )
        
        # Step 7: Notify team
        notify_rotation_success(
            secret_id=secret_id,
            environment=environment,
            timestamp=datetime.now().isoformat()
        )
        
        return {
            'statusCode': 200,
            'message': f'Password rotated successfully for {secret_id}'
        }
        
    except Exception as e:
        notify_rotation_failure(
            secret_id=secret_id,
            environment=environment,
            error=str(e)
        )
        raise

def generate_secure_password(length=32):
    """Generate cryptographically secure password"""
    import secrets
    import string
    
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    password = ''.join(secrets.choice(alphabet) for i in range(length))
    return password

def test_db_connection(host, user, password, database, max_retries=5):
    """Test database connectivity with exponential backoff"""
    import pymysql
    
    for attempt in range(max_retries):
        try:
            conn = pymysql.connect(
                host=host,
                user=user,
                password=password,
                database=database,
                connect_timeout=10
            )
            conn.close()
            return True
        except Exception as e:
            if attempt < max_retries - 1:
                wait_time = 2 ** attempt  # Exponential backoff
                time.sleep(wait_time)
            else:
                raise

def notify_rotation_success(secret_id, environment, timestamp):
    """Notify team of successful rotation"""
    message = f"""
    ✅ Credential Rotation Successful
    
    Secret: {secret_id}
    Environment: {environment}
    Time: {timestamp}
    
    The credential has been rotated and verified.
    No action needed.
    """
    
    sns_client.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:rotation-success',
        Subject=f'[{environment}] Credential Rotated: {secret_id}',
        Message=message
    )

def notify_rotation_failure(secret_id, environment, error):
    """Alert team of rotation failure"""
    message = f"""
    ❌ Credential Rotation FAILED
    
    Secret: {secret_id}
    Environment: {environment}
    Error: {error}
    
    IMMEDIATE ACTION REQUIRED!
    1. Check RDS connection status
    2. Verify applications still connectable
    3. Manually rotate if database is unstable
    4. Page on-call engineer
    """
    
    sns_client.publish(
        TopicArn='arn:aws:sns:us-east-1:123456789012:rotation-failure',
        Subject=f'🚨 [{environment}] Rotation FAILED: {secret_id}',
        Message=message
    )
```

**Terraform Configuration:**

```hcl
# RDS with Secrets Manager integration

resource "aws_secretsmanager_secret" "rds_password" {
  for_each = {
    dev     = { db = "prod-db-dev", rotation_days = 30 }
    staging = { db = "prod-db-staging", rotation_days = 30 }
    prod    = { db = "prod-db-prod", rotation_days = 14 }  # Shorter for prod
  }
  
  name_prefix = "prod/${each.key}/rds/master-password/"
  description = "Master password for ${each.key} RDS instance"
  
  tags = {
    Environment = each.key
    Criticality = each.key == "prod" ? "critical" : "normal"
  }
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  for_each = aws_secretsmanager_secret.rds_password
  
  secret_id = each.value.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rds[each.key].result
    host     = aws_db_instance.prod[each.key].address
    dbname   = "production"
  })
}

resource "random_password" "rds" {
  for_each = {
    dev     = {}
    staging = {}
    prod    = {}
  }
  
  length  = 32
  special = true
}

# Rotation configuration
resource "aws_secretsmanager_secret_rotation" "rds_password" {
  for_each = aws_secretsmanager_secret.rds_password
  
  secret_id           = each.value.id
  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }
  
  rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
}

resource "aws_lambda_function" "rotate_secret" {
  filename      = "lambda_rotation.zip"
  function_name = "secrets-rotation-rds"
  role          = aws_iam_role.lambda_rotation.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  
  vpc_config {
    subnet_ids         = var.private_subnet_ids  # Must be same VPC as RDS
    security_group_ids = [aws_security_group.lambda_rotation.id]
  }
}

# IAM permissions for Lambda
resource "aws_iam_role" "lambda_rotation" {
  name = "lambda-secrets-rotation"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_rotation" {
  name = "lambda-rotation-inline-policy"
  role = aws_iam_role.lambda_rotation.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue"
        ]
        Effect   = "Allow"
        Resource = "${aws_secretsmanager_secret.rds_password[*].arn}"
      },
      {
        Action = [
          "rds-db:connect"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds:*:*:db/*"
      }
    ]
  })
}

# VPC Endpoint for Secrets Manager (so Lambda can reach it from private subnet)
resource "aws_vpc_endpoint" "secrets_manager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
}
```

**Auditing & Monitoring:**

```bash
# Query rotation history
aws secretsmanager list-secret-version-ids \
  --secret-id prod/dev/rds/master-password \
  --query 'Versions[].{VersionId,CreatedDate,VersionStages}'

# Output shows every rotation with timestamp

# CloudWatch Logs insights query
fields @timestamp, @message, environment, status
| filter ispresent(secret_id)
| stats count() as rotations by environment, status

# Create dashboard
aws cloudwatch put-metric-alarm \
  --alarm-name "secrets-rotation-failures" \
  --metric-name RotationFailureCount \
  --namespace "SecretsManager" \
  --statistic Sum \
  --period 3600 \
  --evaluation-periods 1 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
 --alarm-actions arn:aws:sns:us-east-1:123456789012:on-call

# Compliance report
for env in dev staging prod; do
  echo "=== $env Environment ==="
  aws secretsmanager describe-secret --secret-id prod/$env/rds/master-password | \
    jq '{SecretId, RotationEnabled: .RotationRules, LastRotatedDate: .LastRotatedDate}'
done
```

**Compliance & Auditing:**

```markdown
# Secrets Rotation Audit Report

## Rotation Schedule Compliance
- Dev: 30-day rotation ✅
- Staging: 30-day rotation ✅
- Prod: 14-day rotation ✅

## Recent Rotations (Last 30 Days)
| Environment | Secret | Last Rotation | Status |
|-------------|--------|--------------|--------|
| Dev | rds/master | 2026-03-20 | ✅ Success |
| Staging | rds/master | 2026-03-20 | ✅ Success |
| Prod | rds/master | 2026-03-18 | ✅ Success |

## Audit Trail (CloudTrail)
- Who: Lambda service account (arn:aws:iam::123456789012:role/lambda-rotation)
- What: PutSecretValue, ModifyDBInstance
- When: 2026-03-20 14:23:45 UTC
- Status: Only authorized principal can initiate

## Failures (Last 90 Days)
- None (0% failure rate)

## Recommendation
- All environments compliant
- Rotation working as designed
- No manual intervention needed
```

This is enterprise-level automation. Key benefits: Zero-human rotation, audit trail, alerts on failure."

---

### Question 10: "If you had to audit 500+ S3 buckets for security misconfiguration, walk through your approach without running AWS CLI 500 times."

**Expected Senior Answer:**

"I wouldn't audit them manually. I'd use S3 Inventory + Athena for a distributed query across all buckets.

**Step 1: Enable S3 Inventory (consolidate data)**

```bash
# Generate manifest file listing all buckets
for region in us-east-1 us-west-2 eu-west-1; do
  aws s3api list-buckets --region $region | jq -r '.Buckets[].Name' >> all_buckets.txt
done

# Enable inventory on each bucket (sends manifest to S3 daily)
cat all_buckets.txt | while read bucket; do
  aws s3api put-bucket-inventory-configuration \
    --bucket $bucket \
    --id inventory \
    --inventory-configuration '{
      "Destination": {
        "S3BucketDestination": {
          "Bucket": "arn:aws:s3:::audit-inventory",
          "Format": "ORC"
        }
      },
      "IsEnabled": true,
      "Id": "SecurityAudit",
      "IncludedObjectVersions": "Current",
      "OptionalFields": ["ETag", "StorageClass", "LastModifiedDate"],
      "Schedule": {
        "Frequency": "Daily"
      }
    }'
done

# Wait 24 hours for inventory to be generated...
```

**Step 2: Query with Athena (distributed analysis)**

```sql
-- Create external table from S3 Inventory data
CREATE EXTERNAL TABLE IF NOT EXISTS s3_inventory (
  bucket_name STRING,
  key STRING,
  version_id STRING,
  is_latest BOOLEAN,
  size BIGINT,
  last_modified_date TIMESTAMP,
  storage_class STRING,
  etag STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.orc.OrcSerde'
LOCATION 's3://audit-inventory/data/'

-- Query 1: Find unencrypted objects
SELECT bucket_name, COUNT(*) as unencrypted_count
FROM s3_inventory
WHERE storage_class = 'STANDARD'  -- Not encrypted
GROUP BY bucket_name
ORDER BY unencrypted_count DESC
LIMIT 50;

-- Query 2: Find old objects (potential PII exposure)
SELECT bucket_name, key, last_modified_date
FROM s3_inventory
WHERE last_modified_date < date_add('day', -365, current_date)
AND key LIKE '%password%' OR key LIKE '%secret%' OR key LIKE '%backup%'
ORDER BY last_modified_date DESC;

-- Query 3: Find buckets with many PII-like keys
SELECT 
  bucket_name,
  COUNT(*) as suspicious_files,
  COUNT(DISTINCT substring(key, 0, position('/' IN key))) as directories
FROM s3_inventory
WHERE key LIKE '%.sql%' OR key LIKE '%.bak%' OR key LIKE '%credentials%'
GROUP BY bucket_name
ORDER BY suspicious_files DESC;
```

**Step 3: Cross-reference with Bucket Policies (parallel)**

```bash
# Use multi-threaded script to get all bucket policies
#!/bin/bash

get_bucket_policies() {
  local bucket=$1
  policy=$(aws s3api get-bucket-policy --bucket $bucket 2>/dev/null | jq '.Policy')
  
  if echo $policy | grep -q '"Principal":"\\*"'; then
    echo "ALERT: $bucket has public policy"
  fi
  
  if echo $policy | grep -q '"Effect":"Allow".*"Principal":.*"AWS":"arn:aws:iam::.*:root"'; then
    echo "WARNING: $bucket allows cross-account root access (may be intended)"
  fi
}

export -f get_bucket_policies

# Parallel execution using GNU parallel (or xargs)
cat all_buckets.txt | parallel --jobs 10 'get_bucket_policies {}'
```

**Step 4: Consolidate Results (single report)**

```python
import pandas as pd
import json
from datetime import datetime

# Read Athena query results
athena_results = pd.read_csv('athena_output.csv')

# Read bucket policies
bucket_policies = json.load(open('bucket_policies.json'))

# Combine into single audit report
audit_report = pd.DataFrame({
    'Bucket': athena_results['bucket_name'],
    'UnencryptedObjects': athena_results['unencrypted_count'],
    'PublicPolicy': [bucket_policies.get(b, {}).get('public') for b in athena_results['bucket_name']],
    'OldFiles': athena_results['suspicious_files'],
    'RiskScore': (
        (athena_results['unencrypted_count'] > 0).astype(int) * 30 +
        (athena_results['suspicious_files'] > 0).astype(int) * 20 +
        [bucket_policies.get(b, {}).get('public') for b in athena_results['bucket_name']] * 50
    )
})

# Sort by risk
audit_report = audit_report.sort_values('RiskScore', ascending=False)

# Generate report
print("=== S3 Security Audit Report (500+ buckets) ===")
print(f"Generated: {datetime.now()}")
print(f"Total buckets scanned: {len(audit_report)}")
print(f"High-risk buckets: {len(audit_report[audit_report['RiskScore'] > 50])}")
print("\nTop 10 Highest Risk Buckets:")
print(audit_report[['Bucket', 'RiskScore', 'PublicPolicy', 'UnencryptedObjects']].head(10).to_string())

# Export for remediation
audit_report[audit_report['RiskScore'] > 50].to_csv('remediation_required.csv')
```

**Why This Works:**
- Athena queries all 500 buckets in parallel (not sequential)
- Single Athena query scans all inventory data at once
- S3 Inventory is designed for this (daily batch processing)
- Cost: ~$5 for Athena query (scan 500 bucket inventories)
- Time: ~5 minutes (not 500+ minutes of CLI calls)

**If Inventory Not Available (Quick Audit):**

```bash
# Use AWS Config + Config Analyzer (simpler, less flexible)
aws configservice describe-compliance-by-config-rule \
  --compliance-types NON_COMPLIANT \
  | jq '.ComplianceByConfigRules[] | select(.ConfigRuleName | contains("s3"))'

# Results tell you which rules are broken per bucket
# Example: S3_BUCKET_PUBLIC_READ_PROHIBITED reports all public read buckets

# Remediation: Auto-remediation via Config Rules
# No manual bucket policy updates needed
```

**Audit Report Output:**

```
=== S3 Security Audit (500+ Buckets) ===
Summary:
- Total buckets: 523
- Compliant: 487 (93%)
- Non-compliant: 36 (7%)
  - Public read: 8
  - Unencrypted: 15
  - No bucket versioning: 13

Top Risks:
1. app-backups-staging (public read, unencrypted) - CRITICAL
2. analytics-data (unencrypted) - HIGH
3. legacy-logs (no versioning) - MEDIUM

Remediation:
- 8 buckets: Block public access (3 CLI commands)
- 15 buckets: Enable default encryption (Terraform update)
- 13 buckets: Enable versioning (Config remediation)
```

**Your Real Benefit:**
Don't audit 500 buckets manually. Use inventory + Athena to query all simultaneously. Get results in minutes, not days. This scales from 500 to 50,000 buckets with same approach."

---

**Document Version**: 2.0  
**Last Updated**: 2026-03-22  
**Target Audience**: Senior DevOps Engineers (5-10+ years experience)  
**Status**: Complete with detailed deep dives, hands-on scenarios, and interview questions
