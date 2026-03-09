# AWS Security Hardening and Compliance - Senior DevOps Study Guide

**Version:** 1.0  
**Target Audience:** DevOps Engineers with 5–10+ years experience  
**Last Updated:** March 2026

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [KMS Basics - Key Management, Encryption, Decryption, Key Policies](#kms-basics)
4. [Secrets Manager - Secret Storage, Rotation, Access Control, Auditing](#secrets-manager)
5. [WAF - Web Application Firewall, Rules, ACLs, Bot Control](#waf)
6. [Shield - DDoS Protection, Detection, Mitigation Strategies](#shield)
7. [GuardDuty - Threat Detection, Findings, Response Automation](#guardduty)
8. [Security Hub - Security Posture Management, Compliance Standards, Automated Checks](#security-hub)
9. [Compliance Services - AWS Config, Artifact, Audit Manager, Security Assessments](#compliance-services)
10. [IAM Auditing - Access Analyzer, Credential Report, Policy Simulator, Access Advisor](#iam-auditing)
11. [Incident Response Automation - Lambda, Step Functions, CloudWatch Events, Runbooks](#incident-response-automation)
12. [Hands-on Scenarios](#hands-on-scenarios)
13. [Interview Questions](#interview-questions)

---

## Introduction {#introduction}

### Overview of Topic

Security Hardening and Compliance in AWS represents a critical operational discipline for mature DevOps organizations managing production workloads at scale. This topic encompasses the mechanisms, architectural patterns, and procedural frameworks required to encrypt sensitive data, audit access patterns, detect threats, and maintain regulatory compliance across distributed cloud infrastructure.

At a mature organizational level, security hardening is not merely a checkbox exercise—it is a foundational component of infrastructure-as-code practices, CI/CD pipeline design, and operational excellence. Senior DevOps engineers must understand both the **technical mechanics** of AWS security services and how these services integrate into broader organizational governance frameworks.

### Why It Matters in Modern DevOps Platforms

**Data Protection in Motion and at Rest**  
Modern workloads process sensitive customer data, credentials, encryption keys, and proprietary information. Without robust encryption and key management strategies, data breaches become an inevitable operational failure rather than a possibility. Senior teams recognize encryption as a *required* architectural component, not a post-deployment hardening step.

**Regulatory and Compliance Requirements**  
Enterprise organizations operate under regulatory frameworks:
- **PCI-DSS**: Required for payment card processing
- **HIPAA**: Mandated for healthcare data
- **GDPR/Privacy Laws**: Required for processing EU resident data
- **SOC 2 Type II**: Often required by enterprise customers
- **FedRAMP**: Required for government contracts

Non-compliance results in financial penalties, failed customer audits, and loss of contractual business.

**Operational Visibility and Incident Response**  
At scale, security incidents become a certainty. The competitive advantage belongs to organizations that can:
- **Detect incidents in minutes, not weeks** (GuardDuty, CloudWatch)
- **Automate response mechanisms** (Lambda, Step Functions, SNS)
- **Maintain auditable records** of all access and changes (CloudTrail, Config)
- **Demonstrate rapid containment** to regulators and customers (Incident Response Runbooks)

**Lateral Movement and Privilege Escalation Prevention**  
Mature threat actors leverage weak internal controls to move horizontally across infrastructure. Security hardening mitigates:
- Credential exposure and reuse
- Over-privileged roles and services
- Unmonitored permission changes
- Absence of detective controls

**Business Continuity and Trust**  
Security breaches damage organizational reputation, customer trust, and valuation. Board-level stakeholders increasingly view security posture as a business continuity metric equivalent to uptime and performance.

### Real-World Production Use Cases

**Financial Services Platform**  
A fintech organization processing millions of daily transactions must:
- Encrypt all data with customer-managed keys (KMS) for compliance tenants
- Rotate secrets (database passwords, API keys) automatically
- Detect unauthorized access patterns in minutes
- Maintain PCI-DSS compliance audit trails indefinitely
→ **Outcome**: Passwords rotated hourly, encryption keys audited quarterly, threat detection baseline established within 30 days.

**Healthcare Cloud Migration**  
A healthcare provider migrating legacy workloads to AWS must:
- Ensure HIPAA-compliant encryption for patient records
- Track data access for audit purposes
- Automate responses to unusual access patterns
- Maintain evidence for annual compliance audits
→ **Outcome**: Patient data encrypted at-rest and in-transit, access logs queryable for 7 years, breach detection < 15 minutes.

**Multi-Tenant SaaS Platform**  
A SaaS provider serving thousands of enterprise customers must:
- Isolate encryption keys per customer tenant
- Provide customers with encryption key management options
- Demonstrate security compliance to customer security teams
- Respond to security incidents without customer service disruption
→ **Outcome**: Per-tenant key rotation, compliance reports auto-generated, incident response runbooks tested quarterly.

**DevOps Team Credential Management**  
A DevOps team managing 50+ microservices (each requiring database passwords, API keys, TLS certificates) must:
- Automatically rotate credentials without service interruption
- Audit who accessed which credentials
- Enforce access control (service A can read its password, not others')
- Replace compromised credentials in under 5 minutes
→ **Outcome**: Centralized secrets repository, automated rotation every 30 days, zero manual credential management.

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Enterprise Organization                 │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         AWS Account (Production Environment)         │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                       │   │
│  │  ┌─────────────────┐      ┌─────────────────┐      │   │
│  │  │   Application   │      │   Database      │      │   │
│  │  │   (Service)     │─────▶│   (Encrypted)   │      │   │
│  │  └─────────────────┘      └─────────────────┘      │   │
│  │          │                         │                │   │
│  │          ▼                         ▼                │   │
│  │    ┌──────────────┐        ┌─────────────────┐     │   │
│  │    │ Secrets Mgr  │        │  KMS (Keys)     │     │   │
│  │    │ (Passwords)  │        │  (Master Keys)  │     │   │
│  │    └──────────────┘        └─────────────────┘     │   │
│  │          │                         │                │   │
│  │          └────────────┬────────────┘                │   │
│  │                       ▼                            │   │
│  │          ┌──────────────────────┐                  │   │
│  │          │  CloudTrail Logging  │                  │   │
│  │          │  (Audit Trail)       │                  │   │
│  │          └──────────────────────┘                  │   │
│  │                       │                            │   │
│  │                       ▼                            │   │
│  │   ┌────────────────────────────────────────┐      │   │
│  │   │      Security Hub (Compliance)         │      │   │
│  │   │      - GuardDuty (Threat Detection)    │      │   │
│  │   │      - Config (Configuration Changes)  │      │   │
│  │   │      - Access Analyzer (Permissions)   │      │   │
│  │   └────────────────────────────────────────┘      │   │
│  │                       │                            │   │
│  │             ┌─────────┴──────────┐                │   │
│  │             ▼                    ▼                │   │
│  │       ┌──────────────┐    ┌──────────────┐      │   │
│  │       │Lambda/Step   │    │ SNS/Email    │      │   │
│  │       │Functions     │    │ Incident     │      │   │
│  │       │(Auto-Response)    │ Response     │      │   │
│  │       └──────────────┘    └──────────────┘      │   │
│  │                       │                          │   │
│  │                       ▼                          │   │
│  │          ┌──────────────────────┐               │   │
│  │          │  WAF + Shield        │               │   │
│  │          │  (Edge Protection)   │               │   │
│  │          └──────────────────────┘               │   │
│  │                                                  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         AWS Account (Logging/Compliance)         │   │
│  │    (Centralized audit logs, security findings)  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Key Placement Patterns:**
- **KMS & Secrets Manager** sit at the data layer, protecting credentials and encryption keys
- **WAF & Shield** operate at the network/edge layer, protecting against application and DDoS attacks
- **GuardDuty, Config, Access Analyzer** monitor infrastructure across accounts
- **Security Hub** aggregates findings from all these sources
- **Incident Response Automation** (Lambda, Step Functions) triggers on security events
- **Compliance Services** track configuration changes and maintain audit trails for regulators

---

## Foundational Concepts {#foundational-concepts}

### Key Terminology

**Encryption Key Hierarchy**
- **Master Key (Customer Master Key - CMK)**: The top-level key managed by AWS KMS, typically never directly accessed
- **Data Key**: A unique key generated by CMK for encrypting individual objects; encrypted copy stored with encrypted data
- **Key Rotation**: Automatic or manual renewal of keys on a schedule; essential for compliance (annual required, best practice quarterly or monthly)
- **Key Policy**: IAM-like resource-based policy controlling who can use, manage, and administer encryption keys

**Secrets Management**
- **Secret**: A sensitive value (password, API key, certificate) stored centrally and accessed via API
- **Rotation**: Automated or manual replacement of secrets; critical for limiting blast radius of credential compromise
- **Versioning**: Maintaining multiple versions of a secret to support rotation without application downtime
- **Access Control**: Who (principal) can read/write specific secrets, enforced via IAM + Secrets Manager resource policies

**Threat Detection**
- **Finding**: An automated detection of suspicious activity (failed login attempts, API calls from unusual locations, etc.)
- **Threat Intel Feed**: External intelligence about malicious IPs, domains, and threat actor activity
- **Baseline Behavior**: Learned normal pattern of activity; deviations trigger findings
- **Confidence Score**: Probability that a finding represents actual malicious activity (0-100%)

**Compliance and Auditing**
- **Configuration Drift**: When actual resource configuration diverges from desired state; indicates unauthorized changes or misconfigurations
- **Compliance Rule**: Automated check that evaluates resources against a desired state (e.g., "all S3 buckets encrypted")
- **Evidence**: Logs and records (from CloudTrail, Config) proving compliance status
- **Audit Trail**: Immutable, tamper-evident record of all actions in an account

### Architecture Fundamentals

**The Shared Responsibility Model in Security**

```
┌───────────────────────────────────────┬───────────────────────────────────────┐
│           AWS Responsibility          │        Customer Responsibility        │
├───────────────────────────────────────┼───────────────────────────────────────┤
│ • Hardware/Facilities Security        │ • IAM Policies & User Management      │
│ • Physical Data Center Access         │ • Network Configuration (VPC)         │
│ • Encryption at Hypervisor Level      │ • OS-Level Patching                  │
│ • AWS Service Configuration Security  │ • Firewall & Network ACLs            │
│ • Availability of Services            │ • Application-Level Security         │
│ • S3, RDS, DynamoDB Platform Security │ • Customer Data Classification       │
│                                       │ • Credential Management              │
│                                       │ • Encryption Key Management          │
│                                       │ • Audit & Compliance Enforcement     │
└───────────────────────────────────────┴───────────────────────────────────────┘
```

**For Senior DevOps Teams:** The distinction is critical—AWS cannot enforce your IAM policies or rotate your secrets. You own the entire application security stack above the hypervisor layer.

**Defense in Depth (Layered Security)**

Mature security architectures employ multiple independent layers, so compromise at one layer doesn't eliminate all protections:

```
Layer 1 (Perimeter):     WAF + Shield
                         ↓
Layer 2 (Network):       VPC + NACLs + Security Groups
                         ↓
Layer 3 (Identity):      IAM + Credential Management
                         ↓
Layer 4 (Data):          Encryption (KMS) + Access Control
                         ↓
Layer 5 (Detection):     GuardDuty + CloudTrail + Config
                         ↓
Layer 6 (Response):      Automated Incident Response + Alerting
```

**Example:** An attacker compromising a developer workstation should not automatically gain access to production databases because:
- WAF blocks reconnaissance traffic
- Security groups restrict lateral movement
- IAM requires explicit permissions
- Secrets aren't hardcoded; keys derive from encrypted storage
- Unusual access patterns trigger GuardDuty alerts
- Lambda functions auto-disable compromised credentials

### Important DevOps Principles

**1. Encryption by Default**

**Principle:** Every piece of sensitive data should be encrypted at rest with customer-managed keys (not AWS-managed) by architectural default, not by exception.

**Implication for DevOps:**
- Infrastructure-as-code (Terraform, CloudFormation) should specify encryption for every applicable resource
- Non-encrypted resources should trigger policy violation alerts
- Developers shouldn't have an option to disable encryption; it should be architecturally enforced

**Example Implementation:**
```hcl
# Terraform block enforcing encryption
resource "aws_s3_bucket" "application_data" {
  bucket = "app-data-prod"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.application_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.production.arn
    }
  }
}
```

**2. Credentials Must Not Appear in Code or Logs**

**Principle:** The absence of credentials in source code, logs, or forensic records is a non-negotiable requirement that enables trustworthy incident response.

**Implication for DevOps:**
- Secrets Manager integration mandatory for all services consuming credentials
- CI/CD pipelines must scan for leaked credentials (truffleHog, GitGuardian, git-secrets)
- Log aggregation systems must redact sensitive values before storage
- Post-incident, leaked credentials must be rotated within minutes

**Common Failure Patterns:**
- Hardcoded database passwords in deployment Kubernetes manifests
- API keys committed to git history (and forgotten)
- Secrets logged during application error handling
- Configuration files containing plaintext credentials in S3 buckets

**3. Audit Everything; Trust Nothing**

**Principle:** Every action that affects security posture (permissions changes, encryption key usage, secret access) must be logged and queryable.

**Implication for DevOps:**
- CloudTrail must log all API calls, with logs stored in immutable S3 buckets with MFA delete protection
- Config must track all resource configuration changes
- Access logging must be enabled on highly sensitive resources
- Logs must be retained per regulatory requirements (often 7 years)
- Log analysis must be automated; no team manually reviews terabytes of logs

**Example Query (Athena on CloudTrail logs):**
```sql
SELECT eventTime, userIdentity.principalId, eventName, requestParameters
FROM cloudtrail_logs
WHERE eventSource = 'kms.amazonaws.com'
  AND eventName IN ('Decrypt', 'GenerateDataKey')
  AND from_iso8601_timestamp(eventTime) > current_timestamp - interval '1' hour
ORDER BY eventTime DESC;
```

**4. Identities, Not Hostnames**

**Principle:** Access control decisions should be based on verified identity (IAM role, principal ARN, service principal) not assumed-secure hostnames or IPs.

**Implication for DevOps:**
- Instance metadata restrictions (IMDSv2 mandate)
- Cross-account access must use role assumption (assume role, not long-lived keys)
- Service-to-service authentication via IAM roles, not API keys
- Network perimeter is no longer a security boundary (zero-trust assumption)

**Example (Compromised EC2 Instance):**
```
Old Model (Insecure):
EC2 instance → hardcoded AWS credentials in ~/.aws/credentials
→ Attacker exfiltrates credentials
→ Attacker can access any resource those credentials allow (outside VPC control)

Modern Model (Secure):
EC2 instance → IAM instance profile (temporary credentials, auto-rotated)
→ Attacker gains shell access
→ Credentials auto-expire in <1 hour
→ Can only access resources allowed by IAM role
→ All access logged to CloudTrail
→ GuardDuty detects unusual API calls
```

**5. Least Privilege with Regular Audit**

**Principle:** Identities should have the minimum permissions required for their function, with quarterly audits identifying and removing unused permissions.

**Implication for DevOps:**
- IAM roles must have explicit action lists, never `"*"` (except in rare exceptional cases, documented)
- Resource-level permissions must be specific (e.g., `arn:aws:s3:::app-data/*` not `arn:aws:s3:::*`)
- Service control policies (SCPs) must prevent broad actions at the account level
- Access Analyzer must identify unused permissions; teams must justify or remove them

**6. Incident Response Must Be Automated and Tested**

**Principle:** Security incidents requiring manual intervention typically escalate during the delay. Automated response reduces incident duration from hours to minutes.

**Implication for DevOps:**
- Runbooks for incident response must be in code (CloudFormation, Lambda, Step Functions)
- GuardDuty findings must auto-trigger response workflows (e.g., disable EC2 instance)
- Team must drill incident response quarterly; timing is measured
- Post-incident, runbooks must be updated based on lessons learned

### Best Practices

**KMS & Encryption**
1. Use customer-managed keys (CMKs) instead of AWS-managed keys for all regulated data
2. Implement key rotation on annual basis minimum; best practice is quarterly
3. Separate key policies (who administers keys) from key usage (who uses keys)
4. Log all key operations (decrypt, encrypt, rotate) to CloudTrail
5. Use AWS CloudHSM for cryptographic key storage in highly regulated industries (FIPS 140-2 Level 3 compliance)

**Secrets Management**
1. Centralize all credentials in Secrets Manager; never hardcode
2. Implement automatic rotation with 30-day frequency as baseline
3. Create secret rotation Lambda functions with application-aware logic (e.g., DB must accept new password before rotating)
4. Enable MFA delete on secrets to prevent accidental deletion
5. Tag secrets by application and environment; audit access via CloudTrail

**Threat Detection**
1. Enable GuardDuty in all production accounts immediately upon account creation
2. Integrate GuardDuty findings into SIEM (security information event management) systems
3. Implement custom logic for high-confidence findings (confidence > 85): auto-response
4. Export GuardDuty findings to S3 for long-term analysis and compliance
5. Build baseline behavior models in regional infrastructure for at least 2 weeks before raising confidence threshold

**Compliance & Auditing**
1. Implement AWS Config rules for all resource types, especially those containing sensitive data
2. Store Config snapshots in separate account for audit immutability
3. Use Config Rules to enforce tagging standards (cost center, owner, environment)
4. Query Config for compliance reports monthly; review with security team
5. Use AWS Audit Manager to automate compliance assessment for PCI-DSS, HIPAA, etc.

**Incident Response**
1. Create incident response playbooks in code (CloudFormation templates, Lambda functions)
2. Implement automated actions for high-confidence findings:
   - Disabled compromised EC2 instances (with AMI snapshot for forensics)
   - Rotated exposed credentials
   - Blocked suspicious IAM principals
3. Set up SNS topics to notify on-call team within seconds of finding detection
4. Maintain forensic evidence (logs, network traffic, memory dumps) for compliance and learning
5. Conduct quarterly tabletop exercises of incident response; measure time-to-response

### Common Misunderstandings

**Misunderstanding #1: "We use AWS-managed encryption, so our data is secure"**

**Reality:** AWS-managed encryption (default S3 encryption, AWS-managed RDS keys) provides protection against unauthorized AWS infrastructure access, but not against authorized actions by your own team members or compromised credentials. For sensitive data, you must use customer-managed keys with explicit access policies.

**Example:** A disgruntled DBA can read encrypted data if their IAM role has `kms:Decrypt` permission, regardless of encryption type.

---

**Misunderstanding #2: "Security Hub aggregates findings from GuardDuty, so I don't need to monitor GuardDuty separately"**

**Reality:** Security Hub is a *visibility and reporting* tool, not a response mechanism. It doesn't auto-remediate or alert. You still need GuardDuty findings to trigger automated Lambda response functions. Security Hub helps with compliance reporting.

---

**Misunderstanding #3: "Secrets Manager automatically rotates my database password, so my apps always work"**

**Reality:** Rotation requires application-specific logic. The Secrets Manager rotation Lambda function must:
1. Generate new credentials
2. Authenticate to the target system (RDS, external service)
3. Update the credential on the target
4. Verify the new credential works
5. Only then update the secret version

If step 3 fails (e.g., unauthorized database user), the rotation fails and the old secret becomes inconsistent with the target system.

---

**Misunderstanding #4: "GuardDuty is just threat intelligence; it doesn't add security"**

**Reality:** GuardDuty uses threat intelligence *combined with behavioral analysis* of your infrastructure. It can detect:
- Compromised credentials making API calls from unusual locations
- Exfiltration-like patterns (large data downloads to unknown IPs)
- Privilege escalation within your account
- Port scanning and reconnaissance activity

These are indicators you won't see without GuardDuty unless you manually analyze terabytes of logs.

---

**Misunderstanding #5: "Encryption at rest is sufficient; I don't need encryption in transit"**

**Reality:** Encrypted-at-rest data becomes unencrypted when read. Encryption in transit (TLS 1.3, VPN) protects against:
- Network sniffing on shared infrastructure
- Man-in-the-middle attacks
- Lateral movement within your VPC (though VPC is not a security boundary)

Both are required for defense in depth.

---

**Misunderstanding #6: "We have compliance audit next month; let's just enable Security Hub and Config for that"**

**Reality:** Effective security auditing requires at least 2-3 months of historical data for:
- Demonstrating consistent compliance (not just point-in-time compliance)
- Understanding patterns and anomalies
- Identifying and remediating drift

Point-in-time audits often reflect only your team's responsiveness on the audit day, not actual operational compliance.

---

**Misunderstanding #7: "IAM Analyzer will tell me of all overly-permissive policies"**

**Reality:** Access Analyzer identifies *external access* (who outside your account can access resources) and *unused permissions*. It does NOT identify:
- Over-permissive internal policies (role with `s3:*` on all buckets)
- Implicit permissions through group memberships
- Unintended permission grants via resource policies

Manual policy review and automated scanning tools (CloudMapper, ScoutSuite) are still necessary.

---

### Critical Integration Points for Senior Teams

**Creating an Integrated Security Posture**

For mature organizations, individual security services only add value when integrated into a cohesive workflow:

```
┌────────────────────────────────────────────────────────────────┐
│                    Event-Driven Response             │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  GuardDuty Finding (High Confidence)                           │
│          ↓                                                      │
│  EventBridge Rule                                              │
│          ↓                                                      │
│  Lambda Function                                               │
│          ├─ -> SNS (Alert team)                               │
│          ├─ -> Step Function (Orchestrate response)           │
│          ├─ -> SSM Parameter (Flag for later analysis)        │
│          └─ -> CloudWatch Logs (Audit trail)                  │
│          ↓                                                      │
│  Step Function Workflow                                        │
│          ├─ -> Snapshot EC2 instance (forensics)              │
│          ├─ -> Rotate credentials (if credential compromise)  │
│          ├─ -> Disable IAM principal (if detected)            │
│          ├─ -> Update Security Hub (mark as responded)        │
│          └─ -> Create ticket in ticketing system              │
│          ↓                                                      │
│  Post-Incident                                                 │
│          ├─ -> Export logs to S3 (compliance/analysis)       │
│          ├─ -> Config Rule evaluation (any drift introduced?) │
│          ├─ -> Access analyzer check (new over-permissions?)  │
│          └─ -> Update runbook based on learnings             │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

This integration creates automated response loops that:
- Reduce incident response time from hours to minutes
- Ensure consistent response (always follows the same procedure)
- Create audit evidence of rapid response
- Enable compliance officers to demonstrate effective controls

---

**End of Section: Foundational Concepts**

This section provides the conceptual foundation for understanding subsequent topic sections. Readers should now comprehend the shared responsibility model, defense-in-depth principles, and the importance of audit-driven security operations.

---

## KMS Basics - Key Management, Encryption, Decryption, Key Policies {#kms-basics}

### Textual Deep Dive

#### Internal Working Mechanism

AWS Key Management Service (KMS) is a managed service for creating, storing, and controlling cryptographic keys used to encrypt data across AWS services. Unlike self-managed cryptographic solutions, KMS provides hardware security module (HSM) backing and automated key administration.

**The KMS Key Hierarchy:**

Every encrypted object in AWS is encrypted with a two-tier key system:

1. **Customer Master Key (CMK)** - The top-level key stored in KMS, never directly exported
   - Created in KMS
   - Managed by AWS (hardware security module protection)
   - Used to encrypt/decrypt data keys
   - Can be used for up to 4 KB of direct encryption (rare; typically only encrypts data keys)
   - Identified by ARN: `arn:aws:kms:region:account-id:key/key-id`

2. **Data Key** - Unique key generated per encrypted object
   - Generated by KMS from CMK
   - Returns two versions: plaintext (used immediately) and encrypted (stored with data)
   - Used for AES-256 encryption of actual data
   - Never stored in plaintext; only encrypted version persists
   - Must be decrypted via KMS before use

**Why Two Tiers?**

- **Scalability**: Encrypt unlimited data without KMS API throttling; data keys bear encryption burden
- **Auditability**: All CMK usage logged to CloudTrail; most data-key operations don't require KMS
- **Key Isolation**: Compromise of single data key affects only one object, not all encrypted data

**Encryption/Decryption Flow:**

```
Application wants to encrypt data:
  1. Call KMS GenerateDataKey → returns plaintext_key + encrypted_key
  2. Encrypt data with plaintext_key (local, fast)
  3. Delete plaintext_key from memory
  4. Store: {encrypted_data, encrypted_key}
  5. Log operation to CloudTrail

Application wants to decrypt data:
  1. Call KMS Decrypt with encrypted_key → returns plaintext_key
  2. Decrypt data with plaintext_key
  3. Delete plaintext_key from memory

Note: Step 5 (logging) is mandatory. Cannot decrypt without CloudTrail evidence.
```

#### Architecture Role

**KMS in the Security Stack:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                             │
│                   (writes/reads to DB)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────┐
        │  RDS / S3 / DynamoDB Services  │
        │    (Transparent Encryption)    │
        │  Calls KMS GenerateDataKey()   │
        └──────────┬─────────────────────┘
                   │
                   ▼
        ┌────────────────────────────────┐
        │     AWS KMS Service            │
        │  (CMK Storage & Operations)     │
        │  ┌──────────────────────────┐  │
        │  │ Hardware Security Module │  │
        │  │ (Master Keys Stored Here)│  │
        │  └──────────────────────────┘  │
        └──────────┬─────────────────────┘
                   │
                   ▼
        ┌────────────────────────────────┐
        │   CloudTrail Logging           │
        │   (All KMS operations logged)  │
        └────────────────────────────────┘
```

**Separation of Duties:**

KMS enforces separation between key administrators and key users via **Key Policy**:

- **Key Administrator**: Can manage key (rotation, policy, tagging, deletion schedule)
- **Key User**: Can only encrypt/decrypt with key, cannot modify key settings

This prevents a compromised application role from modifying encryption keys.

#### Production Usage Patterns

**Pattern 1: RDS Database Encryption**

In production, RDS instances are encrypted using customer-managed KMS keys:

```
┌──────────────────────────────────────────────────────┐
│              RDS Instance (Encrypted)                 │
│  ┌───────────────────────────────────────────────┐   │
│  │ Database Storage                              │   │
│  │ (All rows encrypted with data keys)           │   │
│  └────────────────────────┬──────────────────────┘   │
│                           │                          │
│  Data flow on read:       │                          │
│  1. Retrieve encrypted    │                          │
│     row from disk         │                          │
│  2. KMS Decrypt call      ▼                          │
│     with encrypted_key ──────► KMS Service          │
│  3. Returns plaintext_key◄─────── (Validates IAM    │
│  4. Decrypt row locally       role + logs to        │
│  5. Return to application     CloudTrail)           │
└──────────────────────────────────────────────────────┘
```

**Why Not Just Encrypt Application Layer?**

Some teams argue: "We can encrypt on the application side; why use RDS encryption?"

**Answer:** Different threat models:
- RDS encryption protects against: stolen AWS snapshots, disk theft, misconfigurations
- Application encryption protects against: application bugs, code injection, insider threats
- **Best practice**: Use both (defense in depth)

**Pattern 2: S3 Cross-Account Bucket Encryption**

Organization structure: Production data in Account A (RDS/S3), backup/analytics in Account B

```
Account A (Production):
  ├─ KMS key (managed by Account A)
  ├─ S3 bucket (encrypted with key)
  └─ IAM role (can encrypt/decrypt)

Account B (Analytics):
  ├─ Lambda function (needs to read S3 data from Account A)
  ├─ Lambda IAM role (s3:GetObject permission on Account A bucket)
  └─ Problem: Lambda role lacks kms:Decrypt permission in Account A

Solution:
  1. Account A: Update KMS key policy to allow Account B's Lambda role
  2. Account B: Lambda role automatically inherits decrypt permission
  3. When Lambda reads S3, KMS validates Account B role against Account A's key policy
```

**Key Policy Update (Account A):**
```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::ACCOUNT-B:role/lambda-analytics-role"
  },
  "Action": [
    "kms:Decrypt",
    "kms:DescribeKey"
  ],
  "Resource": "*"
}
```

#### DevOps Best Practices

**1. Always Use Customer-Managed Keys (CMKs)**

Default AWS-managed encryption is convenient but limits control:
- AWS rotates keys automatically (unpredictable timing)
- Cannot change key policy
- Cannot enable key deletion protection
- Less suitable for regulatory audits

```hcl
# Good: Customer-managed key
resource "aws_kms_key" "prod_main" {
  description             = "Production data encryption key"
  deletion_window_in_days = 30  # Safe grace period before deletion
  enable_key_rotation     = true  # Automatic annual rotation
  tags = {
    Environment = "production"
    Owner       = "infrastructure-team"
  }
}

# Bad: AWS-managed (default)
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.legacy_backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"  # No key control; avoid for sensitive data
    }
  }
}
```

**2. Implement Key Rotation**

Manual annual rotation is the minimum compliance requirement; best practice is quarterly.

```hcl
resource "aws_kms_key" "quarterly_rotate" {
  enable_key_rotation = true  # AWS rotates annually
}

# For teams requiring more frequent rotation:
# Use Lambda + EventBridge to trigger manual rotation every 90 days
# (Not directly supported by KMS; requires custom orchestration)
```

**3. Separate Keys by Data Classification**

Do not use single key for all data:

```hcl
# Customer data (PII)
resource "aws_kms_key" "customer_data" {
  description = "Encrypts customer PII (highest audit requirements)"
  tags = {
    DataClassification = "sensitive"
  }
}

# Application logs (moderate audit requirements)
resource "aws_kms_key" "application_logs" {
  description = "Encrypts CloudWatch logs"
  tags = {
    DataClassification = "internal"
  }
}

# Backup data (quarterly audit only)
resource "aws_kms_key" "backup_data" {
  description = "Encrypts database backups"
  tags = {
    DataClassification = "backup"
  }
}
```

**4. Grant-Based Access (OAuth-like model)**

For temporary access, use KMS grants instead of permanent key policies:

```bash
# Grant Lambda function temporary decrypt access
aws kms create-grant \
  --key-id arn:aws:kms:us-east-1:123456789012:key/abcd1234 \
  --grantee-principal arn:aws:iam::123456789012:role/my-lambda-role \
  --operations Decrypt DescribeKey \
  --name lambda-temp-access

# Creates grant with grant token; grant auto-revokes after function execution
# More granular than permanent key policy
```

**5. Enable Key Policy Audit Logging**

All KMS operations must be queryable:

```bash
# Query CloudTrail for all key operations in last 24 hours
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GenerateDataKey \
  --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
  --output table | less
```

#### Common Pitfalls

**Pitfall 1: Misunderstanding Key Deletion**

```
Operation: Delete KMS key immediately
Result: ERROR - CMKs cannot be immediately deleted (prevents accidental data loss)

Instead:
  1. Schedule key for deletion (7-30 day grace period)
  2. During grace period, data remains encrypted but key cannot be used
  3. After grace period, key is deleted and encrypted data becomes unrecoverable
```

**Pitfall 2: Assuming Encryption Enables Access Control**

```
Scenario:
  Account A: S3 bucket, KMS key
  Attacker: Compromises IAM user in Account A with S3 GetObject permission

Result: Attacker can read all S3 objects
  - S3 encryption doesn't prevent access; it encrypts at rest
  - IAM permissions determine who can decrypt
  - If IAM user has s3:GetObject + kms:Decrypt, encryption is bypassed

Solution: Use separate KMS key policies that are more restrictive than S3 IAM role
```

**Pitfall 3: Key Policy Overwrites (Terraform Gotcha)**

```hcl
# Bad: Terraform overwrites entire key policy
resource "aws_kms_key" "prod" {
  description = "Main key"
}

# Later, update key policy (wrong way):
resource "aws_kms_key_policy" "prod" {
  key_id = aws_kms_key.prod.id
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Principal = { # All other principals lost!
          Service = "s3.amazonaws.com"
        }
        Action = "*"
      }
    ]
  })
}

# Good: Use aws_kms_key with policy inline to avoid overwrites
resource "aws_kms_key" "prod" {
  description = "Main key"
  policy      = jsonencode({
    Statement = [/* ... */]
  })
}
```

**Pitfall 4: CloudTrail Logging for DecryptKey Causes Log Explosion**

```
Configuration: Log all KMS.Decrypt operations to CloudTrail
Result: CloudTrail ingests millions of find per day (decrypt called for every DB read)
Cost: $0.10 per 100K events = $1000+/day for high-traffic applications

Solution:
  1. Log only admin operations (CreateKey, UpdateKeyPolicy, ScheduleKeyDeletion)
  2. Use S3 access logging for data-plane operations
  3. Use CloudWatch Logs for metrics, not detailed event logging
```

---

### Practical Code Examples

#### CloudFormation: Complete KMS + RDS Encryption Setup

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Production RDS with Customer-Managed KMS Encryption'

Parameters:
  EnvironmentName:
    Type: String
    Default: production
    Description: Environment name for resource tagging

Resources:
  # ==================== KMS Key ====================
  ProductionKMSKey:
    Type: AWS::KMS::Key
    Properties:
      Description: !Sub 'Master encryption key for ${EnvironmentName} databases'
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          # Allow AWS Account to manage the key
          - Sid: Enable IAM Account Permissions
            Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'

          # Allow RDS service to use key
          - Sid: Allow RDS to use the key
            Effect: Allow
            Principal:
              Service: 'rds.amazonaws.com'
            Action:
              - 'kms:Decrypt'
              - 'kms:GenerateDataKey'
              - 'kms:CreateGrant'
              - 'kms:DescribeKey'
            Resource: '*'

          # Allow CloudWatch Logs to use key
          - Sid: Allow CloudWatch Logs
            Effect: Allow
            Principal:
              Service: !Sub 'logs.${AWS::Region}.amazonaws.com'
            Action:
              - 'kms:Encrypt'
              - 'kms:Decrypt'
              - 'kms:ReEncrypt*'
              - 'kms:GenerateDataKey*'
              - 'kms:CreateGrant'
              - 'kms:DescribeKey'
            Resource: '*'
            Condition:
              ArnLike:
                'kms:EncryptionContext:aws:logs:arn': !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:*'

          # Allow backup service
          - Sid: Allow AWS Backup
            Effect: Allow
            Principal:
              Service: 'backup.amazonaws.com'
            Action:
              - 'kms:DescribeKey'
              - 'kms:CreateGrant'
            Resource: '*'

      EnableKeyRotation: true
      Tags:
        - Key: Environment
          Value: !Ref EnvironmentName
        - Key: DataClassification
          Value: sensitive

  ProductionKMSKeyAlias:
    Type: AWS::KMS::Alias
    Properties:
      AliasName: !Sub 'alias/${EnvironmentName}-database-key'
      TargetKeyId: !Ref ProductionKMSKey

  # ==================== RDS Security Group ====================
  RDSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for production RDS
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 5432
          ToPort: 5432
          SourceSecurityGroupId: !Ref ApplicationSecurityGroup
          Description: 'PostgreSQL from application tier'
      Tags:
        - Key: Name
          Value: !Sub '${EnvironmentName}-rds-sg'

  # ==================== RDS Instance ====================
  ProductionDatabase:
    Type: AWS::RDS::DBInstance
    DeletionPolicy: Snapshot
    Properties:
      DBInstanceIdentifier: !Sub '${EnvironmentName}-postgres-primary'
      Engine: postgres
      EngineVersion: '14.7'
      DBInstanceClass: db.r6i.2xlarge
      AllocatedStorage: 500
      StorageType: io1
      Iops: 10000
      
      # ========== Encryption Settings ==========
      StorageEncrypted: true
      KmsKeyId: !GetAtt ProductionKMSKey.Arn  # Enable encryption with customer-managed key
      
      DBName: production_db
      MasterUsername: admin
      MasterUserPassword: !Sub '{{resolve:secretsmanager:${DBMasterSecret}:SecretString:password}}'
      
      # ========== Backup & Recovery ==========
      BackupRetentionPeriod: 30
      BackupWindow: '03:00-04:00'  # Off-peak hour (UTC)
      PreferredMaintenanceWindow: 'sun:04:00-sun:05:00'
      CopyTagsToSnapshot: true
      EnableCloudwatchLogsExports:
        - postgresql  # Enable query logs (encrypted with KMS)
      
      # ========== HA & Recovery ==========
      MultiAZ: true
      EnableIAMDatabaseAuthentication: true  # Use IAM roles instead of passwords
      EnableDeletionProtection: true
      
      # ========== Performance & Monitoring ==========
      EnablePerformanceInsights: true
      PerformanceInsightsRetentionPeriod: 7
      PerformanceInsightsKMSKeyId: !GetAtt ProductionKMSKey.Arn
      EnableEnhancedMonitoring: true
      MonitoringInterval: 60
      MonitoringRoleArn: !GetAtt RDSMonitoringRole.Arn
      
      Tags:
        - Key: Environment
          Value: !Ref EnvironmentName

  # ==================== IAM Role for RDS Monitoring ====================
  RDSMonitoringRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: 'monitoring.rds.amazonaws.com'
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - 'arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole'

  # ==================== CloudWatch Log Group (Encrypted) ====================
  RDSLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: !Sub '/aws/rds/instance/${ProductionDatabase}/postgresql'
      RetentionInDays: 30
      KmsKeyId: !GetAtt ProductionKMSKey.Arn

  # ==================== Secrets Manager for DB Credentials ====================
  DBMasterSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Description: 'RDS Master Database Credentials'
      GenerateSecretString:
        SecretStringTemplate: '{"username": "admin"}'
        GenerateStringKey: 'password'
        PasswordLength: 32
        ExcludeCharacters: '"@/\'
      KmsKeyId: !Ref ProductionKMSKey  # Encrypt secret with custom KMS key

Outputs:
  KMSKeyId:
    Description: KMS Key ID for database encryption
    Value: !Ref ProductionKMSKey
    Export:
      Name: !Sub '${EnvironmentName}-db-kms-key-id'

  DBEndpoint:
    Description: RDS Database Endpoint
    Value: !GetAtt ProductionDatabase.Endpoint.Address
    Export:
      Name: !Sub '${EnvironmentName}-db-endpoint'

  DBPort:
    Description: RDS Database Port
    Value: !GetAtt ProductionDatabase.Endpoint.Port
    Export:
      Name: !Sub '${EnvironmentName}-db-port'
```

#### Shell Script: Audit KMS Key Usage

```bash
#!/bin/bash
# Script: Audit KMS key usage in the last 24 hours

set -e

KMS_KEY_ID="${1:?Usage: $0 <kms-key-id>}"
HOURS_AGO="${2:-24}"
REGION="${AWS_REGION:-us-east-1}"

echo "=== KMS Key Audit Report ==="
echo "Key ID: $KMS_KEY_ID"
echo "Region: $REGION"
echo "Time Period: Last $HOURS_AGO hours"
echo ""

START_TIME=$(date -u -d "$HOURS_AGO hours ago" +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

# Query CloudTrail for KMS operations
echo "=== KMS Operations ==="
aws cloudtrail lookup-events \
  --region "$REGION" \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$KMS_KEY_ID" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --query 'Events[*].[EventTime,EventName,Username,CloudTrailEvent]' \
  --output table

# Show key rotation status
echo ""
echo "=== Key Rotation Status ==="
aws kms describe-key \
  --region "$REGION" \
  --key-id "$KMS_KEY_ID" \
  --query 'KeyMetadata.[KeyId,CreationDate,KeyState,KeyUsage]' \
  --output table

# Show key policy (who can use/manage)
echo ""
echo "=== Key Policy ==="
aws kms get-key-policy \
  --region "$REGION" \
  --key-id "$KMS_KEY_ID" \
  --policy-name default \
  --output json | jq '.Policy | fromjson'

# Show active grants
echo ""
echo "=== Active Grants (Temporary Access) ==="
aws kms list-grants \
  --region "$REGION" \
  --key-id "$KMS_KEY_ID" \
  --query 'Grants[*].[GrantId,GranteePrincipal,Operations,CreationDate]' \
  --output table

# Summary statistics
echo ""
echo "=== Usage Summary ==="
ENCRYPT_COUNT=$(aws cloudtrail lookup-events \
  --region "$REGION" \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$KMS_KEY_ID" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --query "length(Events[?EventName=='Encrypt'])" \
  --output text)

DECRYPT_COUNT=$(aws cloudtrail lookup-events \
  --region "$REGION" \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$KMS_KEY_ID" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --query "length(Events[?EventName=='GenerateDataKey'])" \
  --output text)

echo "Encrypt Operations: $ENCRYPT_COUNT"
echo "GenerateDataKey Operations: $DECRYPT_COUNT"

# Alert if unusual activity detected
if [ "$ENCRYPT_COUNT" -gt 1000000 ]; then
  echo "WARNING: High encryption volume detected - possible misconfiguration?"
fi
```

---

## Secrets Manager - Secret Storage, Rotation, Access Control, Auditing {#secrets-manager}

### Textual Deep Dive

#### Internal Working Mechanism

AWS Secrets Manager is a secrets storage service that centralizes management of passwords, API keys, database credentials, and certificates. Unlike hardcoding secrets or storing in Parameter Store, Secrets Manager provides rotation, versioning, and encryption-at-rest.

**Secret Storage Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│           Secrets Manager (AWS-Managed Service)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Secret: "prod/database/master-password"                        │
│  ├─ Current Version (AWSCURRENT): version_id_1                 │
│  │   └─ Encrypted with KMS key                                 │
│  │   └─ Active (in use by applications)                        │
│  │                                                               │
│  ├─ Previous Version (AWSPREVIOUS): version_id_2               │
│  │   └─ Retained during rotation                               │
│  │   └─ Used by applications slow to reconnect                 │
│  │                                                               │
│  ├─ Staging Version (AWSPENDING): version_id_3                 │
│  │   └─ Temporary during rotation                              │
│  │   └─ Testing happens before promotion                       │
│  │                                                               │
│  └─ Metadata:                                                   │
│      ├─ Created: 2026-01-15 10:30 UTC                          │
│      ├─ Last Rotated: 2026-03-07 04:00 UTC                     │
│      ├─ Rotation Enabled: true                                 │
│      ├─ Rotation Lambda ARN: arn:aws:lambda:...                │
│      ├─ Rotation Rules: automatically every 30 days            │
│      └─ Tags: environment=production, owner=database-team      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Secret Lifecycle (Rotation):**

```
Day 1: Application running on version_1 (AWSCURRENT)
Day 30: Rotation triggered (automatic or manual)
  ├─ Create new value internally → version_2 (AWSPENDING)
  ├─ Run rotation Lambda function
  │  ├─ CreateSecret: Generate new password
  │  ├─ SetSecret: Update target system (RDS, external service)
  │  ├─ TestSecret: Verify new password works
  │  └─ FinishSecret: Promote version_2 to AWSCURRENT
  │
  ├─ If FinishSecret succeeds:
  │  ├─ version_1 → AWSPREVIOUS
  │  ├─ version_2 → AWSCURRENT
  │  └─ Applications transparently get new password
  │
  └─ If FinishSecret fails:
     ├─ version_2 deleted
     ├─ version_1 remains AWSCURRENT
     ├─ Alert sent to admin
     └─ Rotation retried next day
```

**Why Automatic Rotation?**

If password not rotated and exposed:
- Without rotation: Attacker maintains access indefinitely
- With 30-day rotation: Attacker's access expires in <30 days
- With daily rotation: Attacker's access expires in <1 day

#### Architecture Role

**Secrets Manager in Application Architecture:**

```
┌─────────────────────────────────────────────────────────────────┐
│                  Application Container                          │
│  (ECS, Lambda, EC2, Kubernetes)                                │
│                                                                  │
│  Startup:                                                       │
│    1. Initialize database connection                           │
│    2. Call AWS Secrets Manager API                             │
│       aws secretsmanager get-secret-value \                    │
│         --secret-id prod/database/password                     │
│    3. Receive plaintext password                               │
│    4. Establish database connection                            │
│    5. Delete plaintext from memory                             │
│                                                                  │
│  At Runtime:                                                    │
│    - Never retry to Secrets Manager for every connection       │
│          (cache password in memory)                             │
│    - Periodically refresh (every 5-10 min)                     │
│    - On connection error, fetch fresh password                 │
│                                                                  │
└────────────────┬──────────────────────────────────────────────┘
                 │
                 ▼
    ┌────────────────────────────────┐
    │  Secrets Manager Service       │
    │  ┌──────────────────────────┐  │
    │  │ Secret encrypted with    │  │
    │  │ customer KMS key         │  │
    │  └──────────────────────────┘  │
    └────────────┬───────────────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
    CloudTrail        KMS Service
    (All Get Calls)   (Decryption)
```

**Advantages Over Parameter Store:**

| Feature | Secrets Manager | Parameter Store |
|---------|-----------------|-----------------|
| Automatic Rotation | ✓ (Lambda integration) | ✗ (Manual only) |
| Version History | ✓ (CURRENT/PREVIOUS/PENDING) | ✗ (Single value) |
| Backup Autoreplication | ✓ (Multi-region) | ✗ |
| RDS/DB Rotation | ✓ (Built-in templates) | ✗ |
| Cost | ~$0.40/secret/month + rotation | ~$0.04/month |
| Use Case | Sensitive production secrets | Config & parameters |

#### Production Usage Patterns

**Pattern 1: DatabaseSecret with Automatic Rotation**

```
RDS PostgreSQL Setup:
  Master User: admin
  Master Password: Stored in Secrets Manager
  Rotation: Every 30 days using Lambda

Problem Solved:
  - Developers never see master password (only stored encrypted)
  - Password changes automatically without application downtime
  - Old password retained during rotation (AWSPREVIOUS) for slow-connecting apps
  - All password operations logged to CloudTrail
  - DBA cannot access password without CloudTrail audit
```

**Pattern 2: Application API Key Rotation**

```
Third-Party API Setup:
  Provider: DataDog API
  API Key needed by: Monitoring Lambda function
  Key stored in: Secrets Manager
  Rotation: Manual (provider doesn't support auto rotation)

Workflow:
  1. DataDog admin generates new API key
  2. Store new key in Secrets Manager (AWSPENDING)
  3. Lambda function tests new key (calls DataDog API)
  4. If test passes: promote to AWSCURRENT
  5. Application continues using new key transparently
```

**Pattern 3: TLS Certificate Rotation**

```
Certificate Generation:
  Obtain cert from Let's Encrypt / AWS Certificate Manager
  Store private key in Secrets Manager
  
Renewal (90 days):
  1. Obtain new cert
  2. Store new cert + private key as AWSPENDING
  3. Lambda function:
     - Updates certificate in ALB
     - Validates certificate is trusted by clients
     - Tests TLS handshake
  4. If validation passes: promote to AWSCURRENT
  5. Old cert retained (AWSPREVIOUS) for client grace period
```

#### DevOps Best Practices

**1. Never Cache Secrets Beyond Connection Lifetime**

```python
# Bad: Cache secret forever
SECRET_CACHE = {}

def get_db_password():
    if 'db_password' not in SECRET_CACHE:
        response = client.get_secret_value(SecretId='prod/db/password')
        SECRET_CACHE['db_password'] = response['SecretString']
    return SECRET_CACHE['db_password']

# Problem: If rotated, old password persists in memory indefinitely

# Good: Cache with TTL and refresh strategy
import time

class SecretCache:
    def __init__(self, ttl_seconds=300):
        self.cache = {}
        self.ttl = ttl_seconds

    def get(self, secret_id):
        now = time.time()
        if secret_id in self.cache:
            value, timestamp = self.cache[secret_id]
            if now - timestamp < self.ttl:
                return value
        
        # Fetch fresh
        response = client.get_secret_value(SecretId=secret_id)
        self.cache[secret_id] = (response['SecretString'], now)
        return response['SecretString']

cache = SecretCache(ttl_seconds=300)  # Refresh every 5 minutes
password = cache.get('prod/db/password')
```

**2. Design Rotation Lambdas for Idempotency**

```python
# Rotation Lambda must be idempotent (safe to run multiple times)

def lambda_handler(event, context):
    secret_id = event['ClientRequestToken']
    step = event['ClientRequestToken']  # CreateSecret, SetSecret, TestSecret, FinishSecret
    
    if step == 'CreateSecret':
        # Create new secret version
        # IDEMPOTENT: If version already exists, skip
        try:
            response = client.get_secret_value(
                SecretId=secret_id,
                VersionId=version_id,
                VersionStage='AWSPENDING'
            )
            # Version already created, nothing to do
            return
        except client.exceptions.ResourceNotFoundException:
            # Create new version
            new_password = generate_random_password()
            client.put_secret_value(
                SecretId=secret_id,
                ClientRequestToken=version_id,
                SecretString=new_password,
                VersionStages=['AWSPENDING']
            )
    
    elif step == 'SetSecret':
        # Update target system with new password
        # IDEMPOTENT: Update RDS user if password differs
        secret_dict = get_secret_value(secret_id, version_id)
        conn = psycopg2.connect(/* ... */)
        try:
            conn.execute(f"ALTER USER admin PASSWORD '{secret_dict['password']}'")
            conn.commit()
        except Exception as e:
            if 'no change' in str(e):
                pass  # Password already updated, OK
            else:
                raise
```

**3. Use Resource Policies for Cross-Account Access**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountLambda",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::PARTNER-ACCOUNT:role/lambda-monitoring"
      },
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "secretsmanager:VersionStage": "AWSCURRENT"
        }
      }
    }
  ]
}
```

**4. Tag Secrets by Data Classification**

```bash
# Create secret with classification tags
aws secretsmanager create-secret \
  --name prod/payment-api/key \
  --secret-string "{\"api_key\": \"xxx\"}" \
  --tags \
    Key=DataClassification,Value=PCI-DSS \
    Key=Owner,Value=payments-team \
    Key=RetentionDays,Value=365 \
    Key=RotationRequired,Value=true
```

#### Common Pitfalls

**Pitfall 1: Rotation Lambda Cannot Update Target System**

```
Setup:
  - RDS password in Secrets Manager
  - Rotation Lambda tries to update RDS password
  - Lambda lacks credentials to access RDS

Solution:
  1. Store RDS master credentials separately (or use same secret)
  2. Ensure Lambda IAM role has rds:ModifyDBClusterParameterGroup
  3. Lambda must connect to RDS (network access):
     - If RDS is in private subnet: Lambda must be in same VPC + security group
     - If RDS is publicly accessible: Lambda needs outbound internet

Validation:
  aws lambda invoke \
    --function-name test-rotation \
    --payload '{"ClientRequestToken": "test", "Step": "TestSecret"}' \
    response.json && cat response.json
```

**Pitfall 2: Application Doesn't Handle Rotation Gracefully**

```
Scenario:
  Old password: expired_pass_v1
  New password: fresh_pass_v2 (just rotated)
  Application has connection pool with expired_pass_v1

Result:
  - New requests fail to connect (get wrong password from AWSCURRENT)
  - Old requests with expired_pass_v1 also fail
  - Downtime during rotation

Solution:
  1. Application must refresh secret before each connection attempt
  2. Implement connection pool TTL (discard connections older than 5 min)
  3. On connection failure, refresh secret and retry

Java Example:
if (connection.isClosed() || connectionAge > MAX_AGE) {
    String newPassword = secretsManagerClient.getSecretValue(
        GetSecretValueRequest.builder()
            .secretId("prod/db/password")
            .build()
    ).secretString();
    connection = createNewConnection(host, user, newPassword);
}
```

**Pitfall 3: Rotation Happens While App Holds Connections**

```
Timeline:
  T=0:00  App connects with password_v1
  T=0:30  Rotation starts (every 30 days)
  T=0:35  AWSPENDING = password_v2 (not yet active)
  T=0:40  AWSCURRENT = password_v2 (rotated)
  T=0:45  Rotation complete
  T=1:00  App request on old connection (still using password_v1 auth)
  T=1:05  Request fails (password_v1 now invalid)

Solution:
  - Keep AWSPREVIOUS for grace period (5-10 minutes)
  - Database system accepts both AWSCURRENT and AWSPREVIOUS
  - Application creates new connections (which use AWSCURRENT)
  - Old connections eventually timeout
```

---

### Practical Code Examples

#### CloudFormation: Secrets Manager with RDS Auto-Rotation

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'RDS Database with Automatic Secret Rotation'

Parameters:
  DBMasterUsername:
    Type: String
    Default: admin
    NoEcho: true
  DBMasterPassword:
    Type: String
    NoEcho: true
    MinLength: 12

Resources:
  # ==================== Secret for RDS Password ====================
  RDSMasterSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: prod/rds/master-password
      Description: RDS Master Database Password with Automatic Rotation
      SecretString: !Sub |
        {
          "username": "${DBMasterUsername}",
          "password": "${DBMasterPassword}"
        }
      KmsKeyId: !GetAtt SecretsKMSKey.Arn
      Tags:
        - Key: Environment
          Value: production
        - Key: DataClassification
          Value: sensitive
        - Key: RotationRequired
          Value: 'true'

  # ==================== Rotation Lambda Function ====================
  RotationLambdaRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - 'arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole'
      Policies:
        - PolicyName: SecretsManagerRotation
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 'secretsmanager:DescribeSecret'
                  - 'secretsmanager:GetSecretValue'
                  - 'secretsmanager:PutSecretValue'
                  - 'secretsmanager:UpdateSecretVersionStage'
                Resource: !Sub 'arn:aws:secretsmanager:${AWS::Region}:${AWS::AccountId}:secret:prod/rds/*'
              - Effect: Allow
                Action:
                  - 'kms:Decrypt'
                  - 'kms:GenerateDataKey'
                Resource: !GetAtt SecretsKMSKey.Arn

  RotationLambda:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: rds-password-rotation
      Runtime: python3.11
      Handler: index.lambda_handler
      Role: !GetAtt RotationLambdaRole.Arn
      Timeout: 300
      VpcConfig:
        SecurityGroupIds:
          - !Ref LambdaSecurityGroup
        SubnetIds:
          - !Ref PrivateSubnet1
          - !Ref PrivateSubnet2
      Environment:
        Variables:
          SECRETS_MANAGER_ENDPOINT: !Sub 'https://secretsmanager.${AWS::Region}.amazonaws.com'
      Code:
        ZipFile: |
          import json
          import boto3
          import pymysql
          import os
          from botocore.exceptions import ClientError

          secrets_client = boto3.client('secretsmanager')

          def lambda_handler(event, context):
              """Rotate RDS database password"""
              
              service_client = boto3.client('rds')
              secret_id = event['ClientRequestToken']
              secret_dict = event['SecretString']
              token = event['ClientRequestToken']
              step = event['Step']
              
              # Parse secret
              secret_dict = json.loads(event['SecretString'])
              username = secret_dict['username']
              password = secret_dict['password']
              host = secret_dict.get('host', 'prod-rds.xxx.rds.amazonaws.com')
              port = secret_dict.get('port', 3306)
              
              # Step 1: Create new secret version
              if step == "create":
                  create_secret(secret_id, token)
              
              # Step 2: Set new password on target system
              elif step == "set":
                  conn = get_connection(host, username, password, port)
                  set_secret(conn, secret_id, token)
                  conn.close()
              
              # Step 3: Test new password works
              elif step == "test":
                  conn = get_connection(host, username, password, port)
                  test_secret(conn, secret_id, token)
                  conn.close()
              
              # Step 4: Finalize rotation
              elif step == "finish":
                  finish_secret(secret_id, token)
              
              else:
                  raise ValueError(f"Invalid step parameter: {step}")

          def create_secret(secret_id, token):
              """Create new secret version"""
              try:
                  secrets_client.get_secret_value(
                      SecretId=secret_id,
                      VersionId=token,
                      VersionStage='AWSPENDING'
                  )
                  print(f"Version {token} already exists")
              except ClientError as e:
                  if e.response['Error']['Code'] == 'ResourceNotFoundException':
                      current = secrets_client.get_secret_value(
                          SecretId=secret_id, VersionStage='AWSCURRENT')
                      current_secret = json.loads(current['SecretString'])
                      
                      # Generate new password
                      new_password = current_secret['password']  # In production, generate random
                      new_secret = current_secret.copy()
                      new_secret['password'] = new_password
                      
                      secrets_client.put_secret_value(
                          SecretId=secret_id,
                          ClientRequestToken=token,
                          SecretString=json.dumps(new_secret),
                          VersionStages=['AWSPENDING']
                      )
                      print(f"Created secret version {token}")
                  else:
                      raise

          def set_secret(conn, secret_id, token):
              """Update password on RDS instance"""
              try:
                  pending = secrets_client.get_secret_value(
                      SecretId=secret_id, VersionId=token, VersionStage='AWSPENDING')
                  pending_secret = json.loads(pending['SecretString'])
                  
                  username = pending_secret['username']
                  new_password = pending_secret['password']
                  
                  with conn.cursor() as cursor:
                      cursor.execute(f"ALTER USER '{username}'@'%' IDENTIFIED BY %s", (new_password,))
                      conn.commit()
                  
                  print(f"Updated password for user {username}")
              except Exception as e:
                  raise ValueError(f"Failed to set password: {str(e)}")

          def test_secret(conn, secret_id, token):
              """Test new password works"""
              try:
                  pending = secrets_client.get_secret_value(
                      SecretId=secret_id, VersionId=token, VersionStage='AWSPENDING')
                  pending_secret = json.loads(pending['SecretString'])
                  
                  # Re-establish connection with new password
                  test_conn = get_connection(
                      pending_secret['host'],
                      pending_secret['username'],
                      pending_secret['password'],
                      pending_secret['port']
                  )
                  test_conn.close()
                  print("New password validated successfully")
              except Exception as e:
                  raise ValueError(f"Failed to test new password: {str(e)}")

          def finish_secret(secret_id, token):
              """Promote rotation to AWSCURRENT"""
              secrets_client.update_secret_version_stage(
                  SecretId=secret_id,
                  VersionStage='AWSCURRENT',
                  MoveToVersionId=token,
                  RemoveFromVersionId=secrets_client.describe_secret(SecretId=secret_id)\
                      ['VersionIdsToStages'][secret_id]
              )
              print(f"Rotation completed for secret {secret_id}")

          def get_connection(host, username, password, port):
              """Create database connection"""
              return pymysql.connect(
                  host=host,
                  user=username,
                  password=password,
                  port=port,
                  connect_timeout=5
              )

  # ==================== Enable Rotation ====================
  SecretTargetAttachment:
    Type: AWS::SecretsManager::RotationRule
    DependsOn: RotationLambda
    Properties:
      SecretId: !Ref RDSMasterSecret
      RotationLambdaARN: !GetAtt RotationLambda.Arn
      RotationRules:
        AutomaticallyAfterDays: 30
        Duration: 3
        ScheduleExpression: 'rate(30 days)'

  LambdaInvokePermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref RotationLambda
      Action: 'lambda:InvokeFunction'
      Principal: secrets.amazonaws.com

  # ==================== KMS Key for Encryption ====================
  SecretsKMSKey:
    Type: AWS::KMS::Key
    Properties:
      Description: Encryption key for Secrets Manager
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          - Sid: Enable IAM Account Permissions
            Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'
          - Sid: Allow SecretsManager
            Effect: Allow
            Principal:
              Service: 'secretsmanager.amazonaws.com'
            Action:
              - 'kms:Decrypt'
              - 'kms:GenerateDataKey'
            Resource: '*'

Outputs:
  SecretArn:
    Description: ARN of the RDS password secret
    Value: !GetAtt RDSMasterSecret.Id
```

---

## WAF - Web Application Firewall, Rules, ACLs, Bot Control {#waf}

### Textual Deep Dive

#### Internal Working Mechanism

AWS Web Application Firewall (WAF) is a managed service that protects web applications by filtering and monitoring HTTP/HTTPS traffic based on configurable rules. Unlike network-level firewalls (security groups, NACLs), WAF operates at Layer 7 (application layer), enabling sophisticated attack detection and defense.

**WAF Inspection Points:**

WAF can be attached to multiple AWS resources:

```
Internet
    │
    ▼
┌─ ──────────────────────────────────────────┐
│        CloudFront (CDN)                    │ ◄─ WAF can block at edge
│  - Caches content globally                 │
│  - First inspection point                  │
│  - Lowest latency for attacks              │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│     Application Load Balancer (ALB)         │ ◄─ WAF can block at ALB
│  - Routes to backend applications          │
│  - Scale horizontally                      │
│  - Second inspection point                 │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────┐
│     API Gateway                             │ ◄─ WAF can block at API
│  - Routes to Lambda/microservices          │
│  - Rate limiting per endpoint              │
│  - Third inspection point                  │
└─────────────────────────────────────────────┘
```

**WAF Rule Processing:**

WAF evaluates requests sequentially against rules in a Web ACL:

```
Incoming Request
    │
    ▼
┌─ ──────────────────────────────────┐
│ Rule 1: Rate Limiting              │
│ - Limit: 2000 req/5min per IP      │  ├─ ALLOW
│ Match: Source IP from logging      │  ├─ BLOCK
├─ ───────────────────────────────── ┤  ├─ COUNT
│ Rule 2: SQL Injection Detection    │  └─ (Metadata)
│ - Pattern: "UNION SELECT"          │
│ - Method: String match             │
├──────────────────────────────────── │
│ Rule 3: XSS Detection              │
│ - Pattern: "<script>"              │
│ - Method: Regex match              │
├──────────────────────────────────── │
│ Rule 4: Geo-blocking               │
│ - Exclude countries: CN, KP, RU    │
│ - Action: BLOCK                    │
├──────────────────────────────────── │
│ Rule 5: Bot Control                │
│ - Detects AWS Lambda fingerprint   │
│ - Detects headless Chrome          │
│ - Action: CHALLENGE                │
├──────────────────────────────────── │
│ DEFAULT RULE: ALLOW                │
│ - If no rule matches: Allow        │
└─────────────────────────────────────┘
    │
    ├─ BLOCK ──────► Return 403 Forbidden
    ├─ ALLOW ──────► Forward to application
    ├─ COUNT ──────► Log but allow
    └─ CHALLENGE ─► Require proof (CAPTCHA)
```

**Rule Matching Mechanics:**

WAF matches requests against rule criteria:

```
HTTP Request:
  GET /api/products?id=1 UNION SELECT password FROM users--
  Host: shop.example.com
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
  X-Forwarded-For: 203.0.113.45

WAF Rule: "SQL Injection Detection"
  - Inspect: QUERY_STRING
  - Pattern Match: "UNION.*SELECT|--"
  - Threshold: 1 match = trigger
  - Action: BLOCK

Result: 403 Forbidden (SQL injection blocked)
```

#### Architecture Role

**WAF in Defense-in-Depth:**

```
┌────────────────────────────────────────────────────────┐
│              Layer 1: WAF                              │
│  - Blocks application-layer attacks (SQLi, XSS)       │
│  - Geo-blocking, IP reputation                        │
│  - Rate limiting                                      │
│  - Bot filtering                                      │
└────────────────────────────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────────┐
│            Layer 2: Network Layer                      │
│  - Security Groups (stateful firewall)                │
│  - NACLs (stateless rules)                            │
│  - VPC isolation                                      │
└────────────────────────────────────────────────────────┘
                   │
                   ▼
┌────────────────────────────────────────────────────────┐
│            Layer 3: Application Logic                  │
│  - Input validation                                   │
│  - Output encoding                                    │
│  - Authentication/Authorization                      │
└────────────────────────────────────────────────────────┘
```

**Why WAF is Critical:**

- **Network firewalls** (security groups) cannot see HTTP content; they only see IP/port
- **Application firewalls** (WAF) inspect request body and headers; can detect SQLi, XSS
- **WAF + Network firewalls** = defense in depth

#### Production Usage Patterns

**Pattern 1: Protecting E-Commerce Platform**

```
Threats:
  1. Credential stuffing (attackers testing stolen username/passwords)
  2. Account enumeration (checking if email exists)
  3. SQL injection (in search box)
  4. Credential scraping (bots stealing pricing data)

WAF Strategy:
  ├─ Rule 1: Rate limit login endpoint (10 per minute per IP)
  │  └─ Action: BLOCK if exceeded
  ├─ Rule 2: Detect SQL injection patterns in search box
  │  └─ Action: BLOCK + log
  ├─ Rule 3: Bot detection (headless browsers, scrapers)
  │  └─ Action: CHALLENGE (Captcha) or BLOCK
  ├─ Rule 4: Geo-blocking (block known botnet countries)
  │  └─ Action: BLOCK
  └─ Rule 5: Restrict API endpoints to known user agents
     └─ Action: BLOCK mobile apps not in allowlist

Result:
  - Credential stuffing attacks deflected
  - SQL injection blocked
  - Pricing scraping bots challenged
  - Attack surface reduced 95%
```

**Pattern 2: Protecting REST API**

```
API Endpoint: POST /api/v1/auth/login
  Expected: JSON with {"email": "user@example.com", "password": "secret"}
  Risk: SQL injection, XSS, XXE attacks

WAF Rules:
  ├─ Rule: Content-Type validation
  │  └─ Reject if not "application/json"
  ├─ Rule: Body size limit
  │  └─ Reject if > 1 MB (prevents XXE DoS)
  ├─ Rule: SQL injection patterns in body
  │  └─ Pattern: "SELECT|UNION|DROP|--" in body
  │  └─ Action: BLOCK
  ├─ Rule: XML External Entity (XXE)
  │  └─ Pattern: "<!ENTITY" in body
  │  └─ Action: BLOCK
  └─ Rule: Rate limiting
     └─ 5 requests/minute per source IP
     └─ Action: BLOCK if exceeded

Validation:
  curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"user@example.com","password":"secret"}' \
    https://api.example.com/auth/login
  # Returns: 200 OK

  curl -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"user@example.com\"; DROP TABLE users--","password":"x"}' \
    https://api.example.com/auth/login
  # Returns: 403 Forbidden (WAF blocked SQL injection)
```

#### DevOps Best Practices

**1. Use AWS Managed Rules Instead of Custom Rules**

```
AWS Managed Rules (Tested by AWS):
  - Core Rule Set (CRS): Common attacks (SQLi, XSS, RFI, LFI)
  - Known Bad Inputs (KBI): Exploit patterns
  - Common CVE rules: Specific vulnerability patterns
  - Advantage: Maintained by AWS, proven effective

Custom Rules (Requires expertise):
  - Business logic specific rules (e.g., rate limit by customer ID, not IP)
  - Whitelisting known good patterns
  - Should be minimal; mostly logic should be in app

Best Practice: Start with AWS Managed Rules; customize only when necessary
```

```yaml
# CloudFormation example
WebAcl:
  Type: AWS::WAFv2::WebACL
  Properties:
    Scope: CLOUDFRONT
    DefaultAction:
      Allow: {}
    Rules:
      # AWS Managed Core Rule Set
      - Name: AWSManagedRulesCommonRuleSet
        Priority: 0
        Statement:
          ManagedRuleGroupStatement:
            Name: AWSManagedRulesCommonRuleSet
            VendorName: AWS
        OverrideAction:
          None: {}
        VisibilityConfig:
          SampledRequestsEnabled: true
          CloudWatchMetricsEnabled: true
          MetricName: AWSManagedRulesCommonRuleSetMetric
  
      # AWS Managed Known Bad Inputs
      - Name: AWSManagedRulesKnownBadInputsRuleSet
        Priority: 1
        Statement:
          ManagedRuleGroupStatement:
            Name: AWSManagedRulesKnownBadInputsRuleSet
            VendorName: AWS
        OverrideAction:
          None: {}
        VisibilityConfig:
          SampledRequestsEnabled: true
          CloudWatchMetricsEnabled: true
          MetricName: AWSManagedRulesKnownBadInputsRuleSetMetric
```

**2. Implement Rate Limiting Per Customer (Not Just IP)**

```
Problem: Rate limiting by IP alone doesn't work in modern architectures
  - CloudFlare users share same IP (affects legitimate users)
  - Behind NAT: multiple users share same IP
  - Distributed attacks: attackers use different IPs

Solution: Rate limit by request attribute
  - Customer ID (from JWT token)
  - API key
  - Session ID
  - Combination of IP + User-Agent + request path
```

```python
# AWS WAFv2 Rate-limiting by custom header
rate_limit_rule = {
    "Name": "RateLimitByCustomerID",
    "Priority": 2,
    "Statement": {
        "RateBasedStatement": {
            "Limit": 1000,  # Per 5 minutes
            "AggregateKeyType": "CUSTOM_KEYS",
            "CustomKeys": [
                {
                    "HeaderName": {
                        "Name": "X-Customer-ID"  # Custom header with customer ID
                    }
                }
            ]
        }
    },
    "Action": {"Block": {}},
    "VisibilityConfig": {
        "SampledRequestsEnabled": True,
        "CloudWatchMetricsEnabled": True,
        "MetricName": "RateLimitCustomerID"
    }
}
```

**3. Use WAF Logging to Feed Security Investigations**

```
WAF Logs → S3 Bucket → Athena (SQL queries) → Security alerts

Setup:
  1. Enable WAF logging to CloudWatch Logs / Kinesis Firehose
  2. Firehose delivers to S3 (compressed, partitioned by date)
  3. Athena queries S3 for forensics
  4. EventBridge triggers Lambda on suspicious patterns
```

```sql
-- Athena query: Find SQLi attempts in last hour
SELECT
  formatDateTime(from_iso8601_timestamp(timestamp), '%Y-%m-%d %H:%i:%S') as timestamp,
  httpRequest.clientIp,
  httpRequest.uri,
  httpRequest.httpMethod,
  action,
  terminatingRuleId
FROM waf_logs
WHERE
  year = 2026
  AND month = 3
  AND day = 8
  AND from_iso8601_timestamp(timestamp) > now() - interval '1' hour
  AND (
    action = 'BLOCK'
    OR terminatingRuleId IN ('AWSManagedRulesSQLiRuleSet', 'SQLinjection')
  )
ORDER BY timestamp DESC
LIMIT 100;
```

**4. Test WAF Rules Before Production**

```
Deployment Strategy:
  1. Create rule in COUNT mode (logs matches but doesn't block)
  2. Monitor for 7 days; check CloudWatch metrics
  3. Verify false positives (legitimate traffic blocked)
  4. If false positives, update rule scope (e.g., narrower path)
  5. Switch from COUNT to BLOCK
```

```bash
# Monitor WAF metrics before going live
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=Rule,Value=SQLinjectionProtection \
  --start-time 2026-03-01T00:00:00Z \
  --end-time 2026-03-08T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

---

### Practical Code Examples

#### CloudFormation: Complete WAF Deployment

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'AWS WAF for protecting ALB against common web attacks'

Parameters:
  ApplicationLoadBalancerArn:
    Type: String
    Description: ARN of the Application Load Balancer to protect

Resources:
  # ==================== S3 Bucket for WAF Logs ====================
  WAFLoggingBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'waf-logs-${AWS::AccountId}-${AWS::Region}'
      BucketEncryption:
        ServerSideEncryptionConfiguration:
          - ServerSideEncryptionByDefault:
              SSEAlgorithm: AES256
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true
      LifecycleConfiguration:
        Rules:
          - Id: DeleteOldLogs
            Status: Enabled
            ExpirationInDays: 90

  WAFLoggingBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref WAFLoggingBucket
      PolicyText:
        Version: '2012-10-17'
        Statement:
          - Sid: AllowWAFLogging
            Effect: Allow
            Principal:
              Service: logging.s3.amazonaws.com
            Action: 's3:PutObject'
            Resource: !Sub '${WAFLoggingBucket.Arn}/*'
            Condition:
              StringEquals:
                'aws:SourceAccount': !Ref 'AWS::AccountId'

  # ==================== WAF Web ACL ====================
  WebApplicationFirewall:
    Type: AWS::WAFv2::WebACL
    Properties:
      Name: ProductionWebACL
      Scope: REGIONAL  # For ALB; use CLOUDFRONT for CloudFront
      DefaultAction:
        Allow: {}

      Rules:
        # AWS Managed Rules: Core Rule Set (OWASP Top 10)
        - Name: AWSManagedRulesCommonRuleSet
          Priority: 0
          Statement:
            ManagedRuleGroupStatement:
              Name: AWSManagedRulesCommonRuleSet
              VendorName: AWS
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: CoreRuleSetMetric

        # AWS Managed Rules: Known Bad Inputs
        - Name: AWSManagedRulesKnownBadInputsRuleSet
          Priority: 1
          Statement:
            ManagedRuleGroupStatement:
              Name: AWSManagedRulesKnownBadInputsRuleSet
              VendorName: AWS
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: KnownBadInputsMetric

        # AWS Managed Rules: SQL Injection Protection
        - Name: AWSManagedRulesSQLiRuleSet
          Priority: 2
          Statement:
            ManagedRuleGroupStatement:
              Name: AWSManagedRulesSQLiRuleSet
              VendorName: AWS
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: SQLiRuleSetMetric

        # Custom Rule: Rate Limiting
        - Name: RateLimitByIP
          Priority: 3
          Statement:
            RateBasedStatement:
              Limit: 2000  # Per 5 minutes
              AggregateKeyType: IP
          Action:
            Block:
              CustomResponse:
                ResponseCode: 429
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: RateLimitByIPMetric

        # Custom Rule: Geo-Blocking
        - Name: GeoBlockHighRiskCountries
          Priority: 4
          Statement:
            GeoMatchStatement:
              CountryCodes:
                - CN  # China
                - KP  # North Korea
                - RU  # Russia
                - IR  # Iran
          Action:
            Block: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: GeoBlockMetric

        # Custom Rule: Block Suspicious User Agents
        - Name: BlockHeadlessBrowsers
          Priority: 5
          Statement:
            ByteMatchStatement:
              SearchString: 'headless'
              FieldToMatch:
                SingleHeader:
                  Name: user-agent
              TextTransformation: LOWERCASE
              PositionalConstraint: CONTAINS
          Action:
            Block: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: HeadlessBrowserBlockMetric

        # AWS Bot Control (optional - additional cost)
        - Name: AWSManagedRulesBotControlRuleSet
          Priority: 6
          Statement:
            ManagedRuleGroupStatement:
              Name: AWSManagedRulesBotControlRuleSet
              VendorName: AWS
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: BotControlMetric

      VisibilityConfig:
        SampledRequestsEnabled: true
        CloudWatchMetricsEnabled: true
        MetricName: ProductionWebACLMetric

      Tags:
        - Key: Environment
          Value: production

  # ==================== Associate WAF with ALB ====================
  WAFAssociation:
    Type: AWS::WAFv2::WebACLAssociation
    Properties:
      ResourceArn: !Ref ApplicationLoadBalancerArn
      WebACLArn: !GetAtt WebApplicationFirewall.Arn

  # ==================== WAF Logging ====================
  WAFLoggingConfiguration:
    Type: AWS::WAFv2::LoggingConfiguration
    DependsOn: WAFLoggingBucketPolicy
    Properties:
      ResourceArn: !GetAtt WebApplicationFirewall.Arn
      LogDestinationConfigs:
        - !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/wafv2/alb'
      RedactedFields:
        - SingleHeader:
            Name: authorization
        - SingleHeader:
            Name: cookie
        - SingleHeader:
            Name: x-api-key

  # ==================== CloudWatch Log Group ====================
  WAFLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /aws/wafv2/alb
      RetentionInDays: 30

  # ==================== CloudWatch Alarms ====================
  BlockedRequestsAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: WAF-High-Block-Rate
      MetricName: BlockedRequests
      Namespace: AWS/WAFV2
      Statistic: Sum
      Period: 300
      EvaluationPeriods: 1
      Threshold: 1000
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref SNSAlertTopic
      Dimensions:
        - Name: WebACL
          Value: !GetAtt WebApplicationFirewall.Name
        - Name: Rule
          Value: ALL
        - Name: Region
          Value: !Ref 'AWS::Region'

  SNSAlertTopic:
    Type: AWS::SNS::Topic
    Properties:
      DisplayName: WAF Alert Topic
      TopicName: waf-alerts

Outputs:
  WebACLArn:
    Description: ARN of the WAF Web ACL
    Value: !GetAtt WebApplicationFirewall.Arn

  LogGroupName:
    Description: CloudWatch Log Group for WAF logs
    Value: !Ref WAFLogGroup

  LogBucketName:
    Description: S3 bucket for WAF logs
    Value: !Ref WAFLoggingBucket
```

#### Shell Script: WAF Rule Management

```bash
#!/bin/bash
# Script: WAF rule testing and deployment

set -e

WEB_ACL_NAME="${1:?Usage: $0 <web-acl-name>}"
REGION="${AWS_REGION:-us-east-1}"
ACTION="${2:-monitor}"  # monitor or deploy

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"; }

# Get Web ACL ID
get_web_acl_id() {
  aws wafv2 list-web-acls \
    --scope REGIONAL \
    --region "$REGION" \
    --query "WebACLs[?Name=='$WEB_ACL_NAME'].Id" \
    --output text
}

# Get current metrics
check_metrics() {
  log "Checking WAF metrics..."
  
  WEB_ACL_ID=$(get_web_acl_id)
  
  aws cloudwatch get-metric-statistics \
    --namespace AWS/WAFV2 \
    --metric-name AllowedRequests \
    --dimensions Name=WebACL,Value="$WEB_ACL_NAME" Name=Rule,Value=ALL \
    --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 300 \
    --statistics Sum \
    --region "$REGION" \
    --query 'Datapoints | sort_by(@, &Timestamp) | [-5:] | [*].[Timestamp, Sum]' \
    --output table
    
  log "Allowed requests in last hour:"
  
  aws cloudwatch get-metric-statistics \
    --namespace AWS/WAFV2 \
    --metric-name BlockedRequests \
    --dimensions Name=WebACL,Value="$WEB_ACL_NAME" Name=Rule,Value=ALL \
    --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 300 \
    --statistics Sum \
    --region "$REGION" \
    --query 'Datapoints | sort_by(@, &Timestamp) | [-5:] | [*].[Timestamp, Sum]' \
    --output table
}

# Analyze blocked requests
analyze_blocks() {
  log "Analyzing blocked requests..."
  
  # Query CloudWatch Logs for blocks
  aws logs insights start-query \
    --log-group-name "/aws/wafv2/alb" \
    --start-time "$(date -d '1 hour ago' +%s)" \
    --end-time "$(date +%s)" \
    --query-string 'fields @timestamp, action, blockedRuleId, httpRequest.clientIp, httpRequest.uri | filter action = "BLOCK" | stats count() as block_count by blockedRuleId' \
    --region "$REGION" \
    --output table
}

# Switch rule from COUNT to BLOCK
deploy_rule() {
  RULE_NAME="${3:?Usage: $0 <web-acl-name> deploy <rule-name>}"
  log "Deploying rule: $RULE_NAME (switching from COUNT to BLOCK)"
  
  # This requires AWS CLI v2 and custom JSON manipulation
  # Simplified example:
  log "Manual step: Update rule in AWS Console or via AWS CLI JSON"
  log "aws wafv2 update-web-acl --name $WEB_ACL_NAME --scope REGIONAL ..."
}

case "$ACTION" in
  monitor)
    check_metrics
    analyze_blocks
    ;;
  deploy)
    deploy_rule
    ;;
  *)
    log "Unknown action: $ACTION"
    exit 1
    ;;
esac

log "Done."
```

---

## Shield - DDoS Protection, Detection, Mitigation Strategies {#shield}

### Textual Deep Dive

#### Internal Working Mechanism

AWS Shield is a managed Distributed Denial-of-Service (DDoS) protection service. There are two tiers: **Standard** (automatic, no cost) and **Advanced** (paid, enhanced protection and response).

**DDoS Attack Types:**

```
DDoS Attack
    │
    ├─ Layer 3 (Network Layer) Attacks
    │  ├─ UDP Flood: Overwhelm bandwidth with UDP packets
    │  ├─ IP Fragmentation: Malformed packet floods
    │  └─ ICMP Flood: Ping of Death variants
    │
    ├─ Layer 4 (Transport Layer) Attacks
    │  ├─ SYN Flood: Overwhelm TCP connection pool
    │  │  └─ Attacker sends SYN without completing handshake
    │  │  └─ Server allocates resource for each SYN
    │  │  └─ Connection table fills, legitimate users rejected
    │  ├─ ACK Flood: Legitimate-looking packets to trigger processing
    │  └─ DNS Amplification: Abuse DNS servers to flood target
    │
    └─ Layer 7 (Application Layer) Attacks
       ├─ HTTP Flood: Legitimate HTTP requests, massive volume
       │  └─ Problem: Cannot distinguish from legitimate users
       │  └─ Solution: Rate limiting, behavioral analysis
       ├─ Slowloris: Send HTTP requests slowly to exhaust connections
       └─ Cache Busting: Request unique resources (prevent caching)
```

**AWS Shield Standard (Automatic):**

Enabled by default for all AWS customers (no cost):

```
DDoS Attack Traffic
    │
    ▼
┌─────────────────────────────────────────┐
│  AWS Shield Standard                    │
│  - Network-layer DDoS detection         │
│  - Automatic mitigation:                │
│    • Rate limiting                      │
│    • Connection tracking                │
│    • Intelligent flow sampling          │
│  - Coverage:                            │
│    • AWS data center infrastructure     │
│    • ELB, CloudFront, Route 53          │
│  - Limits: Handles attacks up to ~100  │
│    Gbps per region                      │
└─────────────────────────────────────────┘
    │
    ├─ Attack Mitigated ───► Request forwarded
    └─ Attack Continues ──► Alert to AWS team
```

**AWS Shield Advanced (Paid Tier):**

Costs $3,000/month; provides:
- DDoS/Cost Protection (8-hour mitigation credit if attack causes surge)
- Dedicated support team (24/7 response)
- Real-time attack notifications
- Attack metrics and detailed reporting
- Web ACL cost protection (WAF and Shield Advanced = shared pricing)

#### Architecture Role

**Shield in Multi-Layer Defense:**

```
Internet Attacker ──┐
                    │ (1 Gbps UDP flood)
                    ▼
    ┌──────────────────────────────────┐
    │ AWS Network Edge                 │
    │ ┌────────────────────────────┐   │
    │ │ Shield Standard             │   │ ◄─ Layer 3/4 DDoS mitigation
    │ │ - Detects anomalous traffic │   │
    │ │ - Drops malformed packets   │   │
    │ │ - Rate limits per region    │   │
    │ └────────────────────────────┘   │
    └──────────────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────┐
    │ CloudFront / AWS WAF             │
    │ ┌────────────────────────────┐   │
    │ │ Shield Advanced            │   │ ◄─ Layer 7 DDoS (HTTP Flood)
    │ │ + WAF Rules                │   │
    │ │ - Rate limiting            │   │
    │ │ - Bot detection            │   │
    │ │ - Geo-blocking             │   │
    │ └────────────────────────────┘   │
    └──────────────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────┐
    │ Application Load Balancer        │
    │ - Connection per IP limiting     │
    │ - Stickiness settings            │
    │ - Health checks (remove bad)     │
    └──────────────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────┐
    │ Application Layer                │
    │ - Connection pooling             │
    │ - Request validation             │
    │ - Circuit breakers               │
    └──────────────────────────────────┘
```

#### Production Usage Patterns

**Pattern 1: E-Commerce Platform Under Attack**

```
Timeline:
  T=0:00   - Attack starts: 10 Gbps UDP flood
  T=0:15   - Shield Standard detects and begins mitigation
  T=0:30   - Traffic reduced to 2 Gbps (still above normal)
  T=1:00   - Platform still slow; requests timing out
  
  Without Shield Advanced:
    - AWS support contacted but no priority
    - Mitigation takes 2-4 hours
    - Revenue loss: $50K+
  
  With Shield Advanced:
    - DRT (DDoS Response Team) alerted automatically
    - Dedicated engineer assigned
    - Custom WAF rules deployed within 15 minutes
    - Traffic normalized within 30 minutes
    - DDoS/Cost Protection credit applied ($30K)
    - Detailed attack forensics provided
```

**Pattern 2: API Service Experiencing HTTP Flood**

```
Attack: Layer 7 HTTP Flood
  - 50,000 req/sec from botnet
  - Each request legitimate-looking (full HTTP headers, random User-Agents)
  - Cannot distinguish from real users
  
Shield Standard Cannot Help:
  - Shield Standard only detects Layer 3/4 anomalies
  - HTTP looks legitimate; Shield Standard allows through
  
Solution: WAF + Shield Advanced
  ├─ WAF Rate Limiting Rule
  │  └─ Limit: 100 requests/minute per IP
  │  └─ Blocks 99.9% of botnet, allows legitimate users
  ├─ WAF Bot Control
  │  └─ Detects headless browser / suspicious fingerprints
  │  └─ Challenges with CAPTCHA or blocks
  └─ Shield Advanced
     └─ Real-time metrics show attack pattern
     └─ DRT can recommend additional AWS resource scaling
```

#### DevOps Best Practices

**1. Enable Shield Advanced for Production**

```
ROI Calculation:
  Cost: $3,000/month = $36,000/year
  
  Single DDoS event:
    - 2-hour downtime × $100K/hour lost revenue = $200K
    - Cost of incident response (engineers, tools) = $10K
    - Opportunity cost / reputation = $50K
    - Total impact per event = $260K
  
  With Shield Advanced:
    - Same event mitigated in 30 minutes (vs 2+ hours)
    - Revenue loss: $50K (vs $260K)
    - Savings: $210K
  
  Break-even: Single major attack every ~2 months justifies cost
  
  Reality: High-value targets experience attacks quarterly+
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  
  Recommendation for production: ALWAYS enable Shield Advanced
                                + DRT support
```

**2. Implement Multi-Layer Rate Limiting**

```
Layer 1: CloudFront / WAF
  - Rate limit by IP: 1000 requests/5 min per IP
  - Rate limit by URI: 500 requests/5 min per URI per IP
  - Bot Control: Challenge suspicious fingerprints

Layer 2: ALB / API Gateway
  - Connection rate limiting: 100 connections/min per IP
  - Request timeout: 30 seconds (kill slow requests)
  - Health check: Remove unresponsive targets

Layer 3: Application
  - Connection pooling: Max 1000 concurrent
  - Queue management: Drop requests if queue > 10K
  - Circuit breaker: Stop accepting if error rate > 5%
```

**3. Plan for Attack Scaling**

```
Pre-Planning:
  1. Document baseline traffic:
     - Normal peak: 10,000 req/sec
     - Normal peak users: 50,000 concurrent
  
  2. Set up cost controls:
     - CloudFront auto-scaling cap
     - WAF rule cost alerts
     - Budget alerts

  3. Identify scaling limits:
     - Which resources have per-account limits?
     - Which resources have regional limits?
     - Which resources require manual increase?
  
  4. Pre-request limit increases:
     - Request 100x normal for: CloudFront, ALB, API Gateway
     - Have pre-approved request templates ready

During Attack:
  1. Activate WAF rules (rate limiting, bot control)
  2. Scale infrastructure (auto-scaling groups)
  3. Enable request logging (CloudTrail, WAF logs)
  4. Contact DRT (if Shield Advanced)
  5. Activate emergency communication channels
```

**4. Test DDoS Response Procedure**

```
Quarterly Drill (tabletop exercise):
  
  Participants: On-call engineer, DevOps lead, manager, DRT liaison
  
  Scenario: "We're receiving 50 Gbps attack; customers report slow response"
  
  Checklist:
    ☐ Who is incident commander? (Should be manager, not on-call engineer)
    ☐ How are alerts triggered? (PagerDuty, SNS, Slack)
    ☐ Who are escalation contacts? (AWS account team, DRT, external comms)
    ☐ What metrics indicate successful mitigation?
      (CloudFront dropped packets, WAF blocked requests, ALB latency)
    ☐ How do you communicate to customers?
    ☐ Do you take website offline to protect backend?
    ☐ How do you measure attack duration?
    ☐ What do you log for post-mortem?
  
  Post-Drill:
    - Document what worked
    - Document what was missing
    - Update runbook
    - Train team on changes
```

---

### Practical Code Examples

#### Terraform: Shield Advanced + WAF + Auto-Scaling

```hcl
# Terraform: DDoS-protected infrastructure

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  default = "us-east-1"
}

variable "shield_advanced_enabled" {
  default = true
  description = "Enable AWS Shield Advanced (costs $3000/month)"
}

# ==================== Shield Advanced ====================
resource "aws_shield_protection" "alb" {
  count           = var.shield_advanced_enabled ? 1 : 0
  name            = "production-alb-protection"
  resource_arn    = aws_lb.production.arn
  protection_group_rules = [
    {
      group_behavior             = "AGGREGATE"
      remediation_enabled        = true
      resource_type              = "APPLICATION_LOAD_BALANCER"
    }
  ]
}

resource "aws_shield_protection" "cloudfront" {
  count           = var.shield_advanced_enabled ? 1 : 0
  name            = "production-cdn-protection"
  resource_arn    = aws_cloudfront_distribution.cdn.arn
}

# ==================== DRT Access ====================
resource "aws_shield_drt_access" "this" {
  count = var.shield_advanced_enabled ? 1 : 0
}

# ==================== WAF Web ACL ====================
resource "aws_wafv2_web_acl" "rate_limit" {
  name        = "ddos-rate-limit-rules"
  description = "Rate limiting rules to prevent all attack types"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: CoreRuleSet (AWS Managed)
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0
    action {
      block {
        custom_response {
          response_code = 403
        }
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CoreRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 2: Rate Limiting by IP (10K requests / 5 min)
  rule {
    name     = "RequestLimitByIP"
    priority = 1
    action {
      block {
        custom_response {
          response_code = 429
          custom_response_body_key = "RateLimitedResponse"
        }
      }
    }
    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
        scope_down_statement {
          # Only rate limit if request is not from CloudFront
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.cloudfront_ips.arn
              }
            }
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitByIPMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 3: Rate Limiting by URI (avoid cache busting attacks)
  rule {
    name     = "RequestLimitByURI"
    priority = 2
    action {
      block {
        custom_response {
          response_code = 429
        }
      }
    }
    statement {
      rate_based_statement {
        limit              = 5000
        aggregate_key_type = "CUSTOM_KEYS"
        custom_key {
          header {
            name = "User-Agent"
          }
        }
        custom_key {
          uri_path {}
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitByURIMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 4: Bot Control
  rule {
    name     = "BotControl"
    priority = 3
    action {
      block {
        custom_response {
          response_code = 403
        }
      }
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BotControlMetric"
      sampled_requests_enabled   = true
    }
  }

  # Rule 5: Geo-blocking (block known DDoS sources)
  rule {
    name     = "GeoBlockHighRisk"
    priority = 4
    action {
      block {}
    }
    statement {
      geo_match_statement {
        country_codes = ["CN", "KP", "RU", "IR"]  # Adjust as needed
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockMetric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "DDosProtectionMetric"
    sampled_requests_enabled   = true
  }

  custom_response_body {
    key          = "RateLimitedResponse"
    content      = "Too many requests. Please try again later."
    content_type = "TEXT_PLAIN"
  }
}

# ==================== WAF Logging ====================
resource "aws_s3_bucket" "waf_logs" {
  bucket = "waf-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  resource_arn            = aws_wafv2_web_acl.rate_limit.arn
  log_destination_configs = [aws_s3_bucket.waf_logs.arn]
  
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

# ==================== Application Load Balancer ====================
resource "aws_lb" "production" {
  name               = "production-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnets

  enable_deletion_protection = true
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "production-alb"
  }
}

# Attach WAF to ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = aws_lb.production.arn
  web_acl_arn  = aws_wafv2_web_acl.rate_limit.arn
}

# ==================== Auto-Scaling Group ====================
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = var.ami_id  # Ubuntu with app installed
  instance_type = "t3.large"

  vpc_security_group_ids = [aws_security_group.app.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "production-app"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "production-asg"
  vpc_zone_identifier       = var.private_subnets
  target_group_arn          = aws_lb_target_group.app.arn
  health_check_type         = "ELB"
  health_check_grace_period = 300

  min_size         = 3
  max_size         = 50         # Scale up to 50 instances under attack
  desired_capacity = 10
  default_cooldown = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Scale up when under attack
  tag {
    key                 = "Application"
    value               = "production"
    propagate_at_launch = true
  }
}

# Target group for ALB
resource "aws_lb_target_group" "app" {
  name        = "production-app-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    path                = "/health"
    matcher             = "200"
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.production.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ==================== CloudWatch Alarms ====================
resource "aws_cloudwatch_metric_alarm" "ddos_detected" {
  alarm_name          = "DDoS-Attack-Detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DDoSDetected"
  namespace           = "AWS/Shield"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Shield detects DDoS attack"
  alarm_actions       = [var.sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked_high" {
  alarm_name          = "WAF-High-Block-Rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = 5000
  alarm_description   = "Alert on high WAF block rate (possible attack)"
  alarm_actions       = [var.sns_topic_arn]
  dimensions = {
    WebACL = aws_wafv2_web_acl.rate_limit.name
    Rule   = "ALL"
  }
}

# ==================== Data & Outputs ====================
data "aws_caller_identity" "current" {}

output "alb_dns_name" {
  value = aws_lb.production.dns_name
}

output "waf_web_acl_arn" {
  value = aws_wafv2_web_acl.rate_limit.arn
}

output "shield_advanced_enabled" {
  value = var.shield_advanced_enabled
}
```

---

## GuardDuty - Threat Detection, Findings, Response Automation {#guardduty}

### Textual Deep Dive

#### Internal Working Mechanism

Amazon GuardDuty is a threat detection service that uses machine learning and threat intelligence to identify suspicious activity in AWS accounts. Unlike WAF (Layer 7) or Shield (DDoS), GuardDuty operates at the behavioral layer—analyzing API calls, network traffic patterns, and resource access logs.

**GuardDuty Data Sources:**

```
┌──────────────────────────────────────────────────────────────┐
│              GuardDuty Threat Analysis Engine                 │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Input Source 1: VPC Flow Logs                              │
│  └─ Network traffic: Source IP, dest IP, ports, bytes       │
│  └─ Analyzed for: Port scanning, DDoS patterns, C&C comms   │
│                                                               │
│  Input Source 2: CloudTrail Events                          │
│  └─ API calls: Who called what, when, from where           │
│  └─ Analyzed for: AWS privilege escalation, credential use  │
│  └─ Example: Unusual DeleteUser, PutUserPolicy calls        │
│                                                               │
│  Input Source 3: DNS Logs                                   │
│  └─ DNS queries from instances                              │
│  └─ Analyzed for: Malware C&C domains, DGA domains          │
│  └─ Example: Request to known-botnet.ru                     │
│                                                               │
│  Input Source 4: S3 Access Logs (optional)                  │
│  └─ Bucket access patterns                                  │
│  └─ Analyzed for: Data exfiltration, mass enumeration       │
│                                                               │
│  Data Enrichment:                                           │
│  └─ AWS threat intelligence database                        │
│  └─ External IP reputation feeds                            │
│  └─ Known malware signatures                                │
│  └─ Botnet C&C infrastructure                               │
│                                                               │
└──────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│               Finding Generation (Machine Learning)          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Baseline Behavior Model:                                   │
│  └─ What is "normal" traffic for this account?             │
│  └─ Machine learning runs for 2 weeks to establish baseline │
│  └─ Deviations trigger findings                             │
│                                                               │
│  Example Finding: "Unusual AWS API call"                    │
│  └─ Principal: IAM role app-role-prod                       │
│  └─ API: GetSecretValue on 500+ secrets                     │
│  └─ Baseline: Normal is 10 calls/day                        │
│  └─ Deviation: 500 calls in 2 minutes = Finding             │
│  └─ Confidence: 85% (high probability of compromise)        │
│                                                               │
└──────────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────────┐
│               Finding Delivery (Multi-channel)               │
├──────────────────────────────────────────────────────────────┤
│  └─ Console: GuardDuty Dashboard                            │
│  └─ CloudWatch Logs: Detailed events                        │
│  └─ S3: Findings exported for long-term analysis            │
│  └─ EventBridge: Trigger Lambda/SNS/SQS on findings        │
│  └─ Security Hub: Aggregated findings                       │
└──────────────────────────────────────────────────────────────┘
```

**Finding Types (58 total, grouped by category):**

```
Recon Findings (attacker gathering information):
  ├─ UnauthorizedAPI: Calls to APIs without permission
  ├─ Policy:PrincipalPolicy.S3.BucketPublicAccessBlockDisabled
  └─ Stealth:IAMUser.AnomalousAPICall

Compromised Finding (attacker has credentials/access):
  ├─ Trojan.EC2.Bitcorn.A: EC2 mining cryptocurrency
  ├─ Backdoor.EC2.DenialOfService: EC2 participating in DDoS
  ├─ CryptoCurrency.EC2.Bitcoin: Mining activity
  └─ Exploitation.RDS.SQLInjection: Potential SQL injection

Instance Finding (suspicious EC2 instance behavior):
  ├─ Behavior:EC2/NetworkPortUnusual: Unusual port access
  ├─ Behavior:EC2/MalwareDetected: Malware found
  └─ Behavior:EC2/UnauthorizedAccess: Brute-force attempt

API Key Finding (credentials exposed):
  ├─ UnauthorizedAPI.IAMUser.MaliciousIPCaller
  ├─ CryptoCurrency.UnauthorizedAPI
  └─ PenTest.UnauthorizedAPI.IAMUser.CustomPermission
```

**Confidence Scoring:**

GuardDuty assigns confidence (0-100%) indicating probability of actual threat:

```
Confidence 90%+: High probability of actual threat
  └─ Auto-remediate: Disable IAM user, rotate credentials
  └─ Example: Known malware connecting to C&C server

Confidence 70-89%: Suspicious, requires investigation
  └─ Alert security team; await human confirmation
  └─ Example: Unusual API call pattern (could be legitimate)

Confidence <70%: Low threat probability
  └─ Log for auditing; don't alert
  └─ Example: New user making expected API calls
```

#### Architecture Role

**GuardDuty in Threat Detection Stack:**

```
┌─────────────────────────────────────────────────────────────┐
│         Attacker compromises EC2 instance                   │
│         (stolen IAM credentials or code injection)          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ Attacker runs CloudTrail API calls │
        │ (enumerate resources, escalate     │
        │  privileges, exfiltrate data)      │
        └────────────────┬────────────────────┘
                         │
    ┌────────────────────┴──────────────────┐
    │                                       │
    ▼                                       ▼
┌──────────────────────┐        ┌──────────────────────┐
│ VPC Flow Logs        │        │ CloudTrail Logs      │
│ (Network patterns)   │        │ (API activity)       │
└──────────────────────┘        └──────────────────────┘
    │                                       │
    └────────────────────┬──────────────────┘
                         │
                         ▼
        ┌────────────────────────────────────┐
        │ GuardDuty Anomaly Detection        │
        │ "API calls from unusual location"  │
        │ "Data exfiltration pattern"       │
        │ "Privilege escalation attempt"    │
        └────────────────┬────────────────────┘
                         │
                    FINDING GENERATED
                         │
    ┌────────────────────┼──────────────────┐
    ▼                    ▼                  ▼
EventBridge        CloudWatch        Security Hub
 (auto-response)    (metrics)       (compliance)
   │
   ├─► Lambda function
   │   ├─ Snapshot EC2 (forensics)
   │   ├─ Disable IAM role
   │   ├─ Rotate credentials
   │   └─ Alert security team
   │
   └─► SNS notification
       └─ On-call engineer alerted
```

#### Production Usage Patterns

**Pattern 1: Detecting Lambda Reconnaissance**

```
Scenario:
  Attacker compromises Lambda execution role
  Runs "ListBuckets", "ListSecrets", "DescribeDBInstances"
  
Normal Behavior:
  Lambda called: 100 times/day (various functions)
  API calls per invocation: 5-10 (read application config)
  
Attack Behavior:
  Lambda called: 1 time
  API calls made: 500+ in 30 seconds (high-speed enumeration)
  
GuardDuty Finding:
  "Recon:IAMUser.Anomalous/ApiCall"
  └─ Confidence: 92%
  └─ Principal: LambdaRole
  └─ Suggested action: Disable role, investigate Lambda
```

**Pattern 2: Detecting Credential Abuse**

```
Scenario:
  EC2 instance credentials stolen (hardcoded in container image)
  Attacker uses credentials from external IP (different country)
  
GuardDuty Flow:
  
  Time T=0:00
    └─ Normal: EC2 instance makes API calls from internal IP (10.x.x.x)
  
  Time T=0:15
    └─ Anomaly: EC2 credentials used from external IP (91.234.45.67)
    └─ Location: Impossible travel (US to Russia in 15 seconds)
    └─ GuardDuty Finding: "UnauthorizedAPI.EC2.MaliciousIPCaller"
    └─ Confidence: 98% (very high)
  
  Time T=0:30
    └─ Lambda auto-responds:
       ├─ Detach IAM policy from EC2 role
       ├─ Snapshot EC2 AMI (for forensics)
       ├─ Terminate EC2 instance
       └─ Alert security team
```

**Pattern 3: Detecting Cryptocurrency Mining**

```
Threat: Attacker installs cryptocurrency mining software on EC2
  └─ Uses instance CPU to mine (reduces application performance)
  └─ Attacker benefits, company pays for compute

Detection:
  1. Network Indicator:
     └─ EC2 connects to known mining pool (e.g., stratum.mining.com:3333)
     └─ GuardDuty recognizes IP as mining pool
     └─ Finding: "Trojan.EC2.BitcoinTool.B"

  2. Behavioral Indicator:
     └─ CPU consistently at 100% (unusual for normal workload)
     └─ Network egress to port 3333 (mining pool)
     └─ GuardDuty correlates with threat intel
     └─ Finding: "Behavior:EC2/MiningActivity"

  3. Remediation:
     └─ Auto-stop instance
     └─ Capture memory dump
     └─ Snapshot volume
     └─ Alert: "Cryptocurrency mining detected on prod-app-2"
```

#### DevOps Best Practices

**1. Enable GuardDuty in All Regions**

```bash
# GuardDuty doesn't work across regions; enable in each region
for region in us-east-1 us-west-2 eu-west-1 ap-southeast-1; do
  aws guardduty create-detector \
    --region "$region" \
    --enable \
    --finding-publishing-frequency FIFTEEN_MINUTES \
    --query 'DetectorId' \
    --output text
done

# Result: One detector per region
# Cost: $30/month per region (3 regions = $90/month)
```

**2. Baseline Detection for 2 Weeks Before Automating Response**

```
Week 1-2: COUNT mode (log all findings, no action)
  └─ Understand false positives in your environment
  └─ Example: Legitimate batch jobs that look like reconnaissance
  
Week 3+: Automated response with human gate
  └─ High confidence (>90%): Auto-remediate
  └─ Medium confidence (70-89%): Auto-notify, manual approval
  └─ Low confidence (<70%): Log only
```

```python
# Example: Filter findings by confidence before automation
def should_auto_remediate(finding):
    if finding['Severity'] == 'High' and finding['Confidence'] >= 0.9:
        return True  # Auto-remediate
    else:
        return False  # Manual review required
```

**3. Route Findings to SIEM (Security Information Event Management)**

```
GuardDuty Findings
    │
    ├─► CloudWatch Logs (log group: /aws/guardduty)
    │  └─► CloudWatch Logs Insights (SQL queries)
    │
    ├─► EventBridge Rule
    │  └─► Kinesis Firehose → S3
    │     └─ Long-term storage for audits
    │
    ├─► EventBridge Rule
    │  └─► SQS/SNS → Security Team
    │     └─ Real-time alerting
    │
    └─► EventBridge Rule
       └─► Splunk / DataDog / Sumo Logic
          └─ SIEM ingestion for correlation

Benefit: Correlate GuardDuty findings with other security signals
  - If GuardDuty finds "credential abuse" + WAF finds "SQLi attempts"
    = likely coordinated attack (need stronger response)
```

**4. Tag Findings by Severity and Auto-Response**

```hcl
# Terraform: EventBridge rules routing findings by severity

resource "aws_cloudwatch_event_rule" "guardduty_high_severity" {
  name        = "guardduty-high-severity-findings"
  description = "Route high-severity GuardDuty findings to auto-response"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7, 7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_remediate" {
  rule      = aws_cloudwatch_event_rule.guardduty_high_severity.name
  target_id = "RemediationLambda"
  arn       = aws_lambda_function.remediate.arn
}

resource "aws_cloudwatch_event_rule" "guardduty_medium_severity" {
  name        = "guardduty-medium-severity-findings"
  description = "Route medium-severity findings to SNS (manual review)"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [4, 4.0, 4.5, 5, 5.5, 6, 6.5]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns_notify" {
  rule      = aws_cloudwatch_event_rule.guardduty_medium_severity.name
  target_id = "ManualReview"
  arn       = aws_sns_topic.security_alerts.arn
}
```

#### Common Pitfalls

**Pitfall 1: GuardDuty Base Rate (False Positives)**

```
Problem:
  GuardDuty finds: "Unusual API call from IP 203.0.113.45"
  Reality: That's CloudFlare's WAF IP (legitimate)
  Cost: Security team investigates false alarm

Solution:
  1. Whitelist expected IPs in findings filter
  2. Use "S3 Bucket Access" finding type instead of raw API calls
  3. Wait 2 weeks for baseline before alerting on medium findings
  4. Tune confidence threshold higher (require >85%, not >70%)
```

**Pitfall 2: "FindingSuppression" Rules Suppress Real Attacks**

```
Scenario:
  Rule: "Suppress all 'UnauthorizedAPI' findings from VPN IP"
  Reason: Office VPN is shared by 1000 employees
  
Problem:
  Attacker compromises VPN server
  All attacker API calls from VPN IP are suppressed
  Real attack goes undetected

Better Solution:
  └─ Don't suppress entire finding types
  └─ Only suppress findings already investigated + confirmed safe
  └─ Use "FindingAttributes" suppression (specific IP + API + resource)
```

**Pitfall 3: Event Pattern Misconfiguration**

```
Bad EventBridge rule:
  Trigger on: severity >= 4
  Problem: Also triggers on severity 4.0 (numerical comparison quirk)
  
Better: Use explicit severity list
  Severity in [7, 7.5, 8]  (only high severity)
```

---

### Practical Code Examples

#### Shell Script: GuardDuty Finding Analysis and Response

```bash
#!/bin/bash
# Script: GuardDuty threat response automation

set -e

DETECTOR_ID="${1:?Usage: $0 <detector-id>}"
REGION="${AWS_REGION:-us-east-1}"
MIN_CONFIDENCE="${2:-0.75}"  # Respond to findings > 75% confidence

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@" >&2; }

# Fetch unresolved findings
fetch_findings() {
  log "Fetching unresolved findings..."
  
  aws guardduty list-findings \
    --region "$REGION" \
    --detector-id "$DETECTOR_ID" \
    --finding-criteria 'Criterion={updatedAt={Gte=1000000000},severity={Gte=4}}' \
    --query 'FindingIds[]' \
    --output text
}

# Get finding details
get_finding_details() {
  local finding_id="$1"
  
  aws guardduty get-findings \
    --region "$REGION" \
    --detector-id "$DETECTOR_ID" \
    --finding-ids "$finding_id" \
    --query 'Findings[0]' \
    --output json
}

# Assess threat level and respond
respond_to_finding() {
  local finding_json="$1"
  
  local finding_type=$(echo "$finding_json" | jq -r '.Type')
  local severity=$(echo "$finding_json" | jq -r '.Severity')
  local resource_type=$(echo "$finding_json" | jq -r '.Resource.ResourceType')
  local resource_id=$(echo "$finding_json" | jq -r '.Resource.InstanceDetails.InstanceId // .Resource.AccessKeyDetails.AccessKeyId')
  
  log "Finding: $finding_type | Severity: $severity | Resource: $resource_type/$resource_id"
  
  # High severity: Auto-response
  if (( $(echo "$severity >= 7" | bc -l) )); then
    log "HIGH severity - initiating auto-response..."
    
    case "$resource_type" in
      Instance)
        log "Stopping EC2 instance: $resource_id"
        aws ec2 create-image \
          --instance-id "$resource_id" \
          --name "forensic-snapshot-$(date +%s)" \
          --no-reboot \
          --region "$REGION" \
          --query 'ImageId' \
          --output text
        
        aws ec2 stop-instances \
          --instance-ids "$resource_id" \
          --region "$REGION"
        
        log "Instance $resource_id stopped. Snapshot created for forensics."
        ;;
      
      AccessKey)
        log "Disabling IAM access key: $resource_id"
        aws iam update-access-key \
          --access-key-id "$resource_id" \
          --status Inactive
        
        log "Access key $resource_id disabled."
        ;;
      
      *)
        log "Unknown resource type: $resource_type (manual review required)"
        ;;
    esac
  
  # Medium severity: Notify team
  elif (( $(echo "$severity >= 5" | bc -l) )); then
    log "MEDIUM severity - sending notification..."
    
    aws sns publish \
      --topic-arn "arn:aws:sns:${REGION}:$(aws sts get-caller-identity --query Account --output text):security-alerts" \
      --subject "GuardDuty Finding: Manual Review Required" \
      --message "Type: $finding_type\nResource: $resource_id\nSeverity: $severity\nPlease investigate."
  
  # Low severity: Log only
  else
    log "LOW severity - logging for audit purposes."
  fi
}

# Main
log "Starting GuardDuty threat response..."

FINDINGS=$(fetch_findings)

if [ -z "$FINDINGS" ]; then
  log "No findings to process."
  exit 0
fi

for finding_id in $FINDINGS; do
  log "Processing finding: $finding_id"
  finding_json=$(get_finding_details "$finding_id")
  respond_to_finding "$finding_json"
done

log "Threat response completed."
```

---

## Security Hub - Security Posture Management, Compliance Standards, Automated Checks {#security-hub}

### Textual Deep Dive

#### Internal Working Mechanism

AWS Security Hub is a security findings aggregator and compliance dashboard. It centralizes findings from multiple AWS security services (GuardDuty, Config, IAM Access Analyzer, etc.) and third-party tools, providing unified visibility and automated compliance reporting.

**Finding Aggregation Pipeline:**

```
Multiple AWS Accounts
    │
    ├─ Account 1 (Prod)
    │  └─ GuardDuty findings
    │  └─ Config compliance results
    │  └─ Access Analyzer results
    │
    ├─ Account 2 (Staging)
    │  └─ GuardDuty findings
    │  └─ Config compliance results
    │  └─ Access Analyzer results
    │
    └─ Account 3 (Backup/Logging)
       └─ CloudTrail findings
       └─ Config findings
       └─ Access Analyzer results

         │
         ▼ (Import via Service Aggregator)

┌──────────────────────────────────────────────────────────┐
│            AWS Security Hub                             │
│  (Designated "security hub" account)                    │
│                                                         │
│  Unified Finding Repository:                          │
│  ├─ 5 months of finding history                        │
│  ├─ Cross-account, cross-region visibility            │
│  ├─ Deduplication (same finding from multiple sources) │
│  └─ Correlation (related findings linked)             │
│                                                         │
│  Compliance Frameworks:                                │
│  ├─ PCI-DSS v3.2.1                                    │
│  ├─ NIST Cybersecurity Framework                       │
│  ├─ CIS Benchmarks                                     │
│  ├─ GDPR regulations                                   │
│  └─ Custom rule sets                                   │
│                                                         │
└──────────────────────────────────────────────────────────┘
        │
        ├─► Dashboard (Security posture visualization)
        ├─► Insights (Curated finding groups)
        ├─► Automated insights (ML-driven patterns)
        ├─► Remediation runbooks
        └─► Compliance reports (exportable to auditors)
```

**Compliance Framework Mapping:**

```
PCI-DSS Requirement 1.1: "Firewall configuration standards"

Security Hub Check:
  ├─ EC2.2: "Security groups should not allow inbound access on port 4379"
  ├─ EC2.40: "Unused security groups should be removed"
  ├─ Config Rule: "restricted-common-ports"
  └─ Status: PASSED / FAILED

Compliance Report Section:
  PCI-DSS 1.1 Status: 85% compliant (17 of 20 checks passing)
  └─ Issues:
     ├─ Security group sg-1234 allows inbound 22 from 0.0.0.0/0
     ├─ Instance i-5678 not behind firewall
     └─ 2 unused security groups in production account

Exported for Auditor:
  "Date assessed: 2026-03-08"
  "PCI-DSS 1.1: FAILED (17/20)"
  "Evidence: Attached CloudTrail logs showing issue discovery"
```

#### Architecture Role

**Security Hub in Compliance Stack:**

```
┌─────────────────────────────────────┐
│   Multi-Account Organization        │
│                                     │
│  ├─ Production Account              │
│  ├─ Staging Account                 │
│  ├─ Development Account             │
│  ├─ Security Account (Hub)          │
│  └─ Logging Account                 │
└─────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────┐
│    Security Hub (Aggregation Account)               │
│    ┌───────────────────────────────────────────┐   │
│    │ Findings from all accounts                │   │
│    │ - GuardDuty (5K findings/day)             │   │
│    │ - Config (10K compliance checks/day)      │   │
│    │ - IAM Analyzer (50 external access items) │   │
│    │ - Third-party integrations                │   │
│    └───────────────────────────────────────────┘   │
│                    │                                │
│    ┌───────────────┴──────────────────────────┐   │
│    │  Compliance Dashboard                    │   │
│    │  ├─ PCI-DSS: 82% (1234 findings)        │   │
│    │  ├─ NIST CSF: 75% (567 findings)        │   │
│    │  ├─ CIS AWS: 68% (890 findings)         │   │
│    │  └─ Custom: 95% (12 findings)           │   │
│    └───────────────────────────────────────────┘   │
│                    │                                │
│    ┌───────────────┼──────────────────────────┐   │
│    ▼               ▼                  ▼            │
│  Insights      Remediation         Custom         │
│  (AI grouping) (Auto-fix)         Reports        │
└─────────────────────────────────────────────────────┘
```

#### Production Usage Patterns

**Pattern 1: Quarterly Compliance Audit**

```
PCI-DSS Audit Timeline:

Week 1-2 (Pre-Audit):
  └─ Security team reviews Security Hub compliance status
  └─ Fixes failing checks to achieve baseline compliance
  └─ Generates "Compliance Status" report in Security Hub

Week 3 (Audit):
  └─ External auditor reviews compliance evidence
  └─ Evidence sources:
     ├─ Security Hub dashboard (day-of-audit compliance)
     ├─ CloudTrail logs (all changes in audit period)
     ├─ Config snapshots (daily resource configurations)
     ├─ GuardDuty findings (security incidents detected)
     └─ Automated remediation logs (issues fixed)
  
  └─ Key question: "Can you prove this resource was compliant
     on [specific date]?"
  └─ Answer: "Yes, Config has daily snapshots; on [date], EC2
     security groups met PCI-DSS restrictions"

Week 4:
  └─ Auditor generates report
  └─ Find: "All required controls demonstrated with evidence"
  └─ Result: Audit PASSED
```

**Pattern 2: Automated Insight Generation**

```
Security Hub Automated Insights (AI-driven):

Example Insight:
  Title: "Unusual API activity from misconfigurations this week"
  Correlation: 47 findings tied to 3 root causes:
    ├─ 22 findings: Lambda functions missing encryption
    ├─ 18 findings: S3 buckets with public access
    └─ 7 findings: IAM policies too permissive
  
  Recommendation:
    "Implement Config rule 'lambda-in-vpc' for 15 non-compliant Lambdas"
    "Apply S3 Block Public Access to 6 buckets"
    "Review and restrict 12 IAM policies"
  
  Impact if fixed:
    "44 of 47 findings would resolve (93%)"
    "Estimated remediation time: 4 hours"
    "Compliance score improvement: +8%"

Automation:
  └─ Use Security Hub insights to drive sprint planning
  └─ Product owner queries top 3 insights weekly
  └─ DevOps team prioritizes fixes based on impact
```

#### DevOps Best Practices

**1. Designate a Dedicated Security Account for Hub**

```
Architecture:
  ├─ Organization Account (AWS Organizations root)
  │  └─ Contains: Billing, consolidated views
  │
  ├─ Security Account (dedicated)
  │  └─ Contains: Security Hub, Config Aggregator, CloudTrail
  │  └─ Central repository for all security findings
  │
  ├─ Production Account
  │  └─ Contains: Applications, databases
  │  └─ Sends findings to Security Account
  │
  └─ Logging Account
     └─ Contains: S3 logs, CloudTrail central storage
     └─ Immutable; restricted access

Benefits:
  - Separates security operations from application workloads
  - Prevents accidental deletion of security findings
  - Restricts access (auditors don't access production)
  - Complies with security hardening best practices
```

**2. Enable Only Relevant Compliance Standards**

```bash
# Get current enabled standards
aws securityhub get-compliance-summary \
  --query 'ComplianceSummary.ComplianceByResourceType' \
  --output table

# Disable irrelevant standards (reduces noise)
aws securityhub batch-disable-standards \
  --standards-subscription-requests StandardsSubscriptionArn="arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0"

# Cost: Fewer enabled standards = faster processing = lower AWS fees
```

**3. Create Custom Insights for Triage**

```json
{
  "Name": "HighPriorityForProduction",
  "Filters": {
    "RecordState": [{"Value": "ACTIVE"}],
    "SeverityLabel": [
      {"Value": "CRITICAL"},
      {"Value": "HIGH"}
    ],
    "ResourceTags": [
      {
        "Key": "Environment",
        "Value": "production"
      }
    ],
    "FirstObservedAt": [
      {
        "DateRange": {
          "Unit": "DAYS",
          "Value": 7
        }
      }
    ]
  },
  "GroupByAttributes": ["RESOURCE_ID", "FINDING_TYPE"]
}
```

---

### Practical Code Examples

#### Shell Script: Security Hub Compliance Reporting

```bash
#!/bin/bash
# Script: Generate compliance report from Security Hub

set -e

REGION="${AWS_REGION:-us-east-1}"
OUTPUT_FILE="security-hub-compliance-$(date +%Y-%m-%d).txt"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"; }

log "Generating Security Hub compliance report..."

{
  echo "========================================="
  echo "AWS Security Hub Compliance Report"
  echo "Generated: $(date)"
  echo "========================================="
  echo ""
  
  # Overall compliance status
  echo "## COMPLIANCE SUMMARY"
  aws securityhub get-compliance-summary \
    --region "$REGION" \
    --query 'ComplianceSummary' \
    --output json | jq '.'
  
  echo ""
  echo "## PCI-DSS COMPLIANCE"
  aws securityhub describe-standards-control-associations \
    --standards-arn "arn:aws:securityhub:${REGION}::standards/pci-dss/v/3.2.1" \
    --region "$REGION" \
    --query 'StandardsControlAssociations[?Standards[0].Arn]' \
    --output json | jq 'group_by(.StandardsControlAssociationState.AssociationStatus) | map({status: .[0].StandardsControlAssociationState.AssociationStatus, count: length})'
  
  echo ""
  echo "## TOP SECURITY FINDINGS"
  aws securityhub get-findings \
    --filters 'RecordState=[{Value=ACTIVE}]' \
    --region "$REGION" \
    --query 'Findings[*].[Title,Severity,ResourceType]' \
    --output table \
    | head -20
  
  echo ""
  echo "## AUTOMATED REMEDIATION OPPORTUNITIES"
  aws securityhub describe-insights \
    --region "$REGION" \
    --query 'Insights[0:5].[Name,Filters]' \
    --output json | jq '.[] | {name: .[0], finding_count: .[1] | length}'
  
  echo ""
  echo "## RESOURCES BY COMPLIANCE STATUS"
  aws securityhub get-findings \
    --filters 'ComplianceStatus=[{Value=PASSED}]' \
    --region "$REGION" \
    --query 'length(Findings)' \
    --output text | xargs -I {} echo "Compliant resources: {}"
  
  aws securityhub get-findings \
    --filters 'ComplianceStatus=[{Value=FAILED}]' \
    --region "$REGION" \
    --query 'length(Findings)' \
    --output text | xargs -I {} echo "Non-compliant resources: {}"

} | tee "$OUTPUT_FILE"

log "Report saved to: $OUTPUT_FILE"
```

---

## Compliance Services - AWS Config, Artifact, Audit Manager, Security Assessments {#compliance-services}

### Textual Deep Dive

#### Internal Working Mechanism

Compliance Services in AWS encompass Config (configuration tracking), Artifact (compliance documentation), and Audit Manager (automated evidence collection).

**AWS Config: Configuration Change Tracking**

```
┌───────────────────────────────────────────────────────────┐
│            AWS Resource (e.g., S3 bucket)                 │
│  Configuration:                                           │
│  └─ Encryption: enabled                                  │
│  └─ Versioning: enabled                                  │
│  └─ Access logging: enabled                              │
│  └─ Server-side encryption algorithm: aws:kms            │
│  └─ Block public access: all enabled                     │
└──────────────────────────────────────────────────────────┘
    │
    ▼ (every 6 hours or on change)
    
┌──────────────────────────────────────────────────────────┐
│              AWS Config Recorder                         │
│  Records current configuration snapshot                  │
└──────────────────────────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────────────────────────┐
│          AWS Config Rules Evaluation                    │
│                                                          │
│  Rule 1: s3-bucket-versioning-enabled                  │
│  └─ Result: COMPLIANT (versioning is enabled)          │
│                                                          │
│  Rule 2: s3-bucket-public-access-disabled              │
│  └─ Result: COMPLIANT (block public access enabled)    │
│                                                          │
│  Rule 3: s3-bucket-server-side-encryption-enabled      │
│  └─ Result: COMPLIANT (SSE-KMS enabled)                │
│                                                          │
│  Rule 4: s3-bucket-server-side-encryption-by-default   │
│  └─ Result: COMPLIANT (default encryption KMS)         │
│                                                          │
└──────────────────────────────────────────────────────────┘
    │
    ├─► Config Dashboard
    │   (Visual compliance status)
    │
    ├─► Config Timeline
    │   (Historical changes and rule evaluations)
    │
    ├─► Audit Trail
    │   (Who changed bucket? When? Why?)
    │
    └─► Compliance Report
        (Export for auditors)
```

**Change Timeline (Compliance Drift Detection):**

```
Configuration History:

T=2026-03-01  S3 bucket created
              Encryption: enabled ✓
              Version control: enabled ✓
              Block public: enabled ✓
              Compliance: 100%

T=2026-03-05  Developer disables versioning (manual mistake)
              Encryption: enabled ✓
              Version control: DISABLED ✗
              Block public: enabled ✓
              Compliance: 66% (2/3 checks passing)
              
              Config detects drift immediately
              EventBridge triggers Lambda
              Lambda re-enables versioning
              Manual investigation created

T=2026-03-07  Auditor checks S3 configuration
              "When was versioning disabled?"
              Answer: "For 2 minutes; automatically re-enabled"
              Evidence: Config timeline shows exact timestamp
              Assessment: Compensating controls worked
               
              Auditor acceptance: "Risk mitigated, no audit finding"
```

**AWS Artifact: Compliance Documentation**

```
Artifact provides downloadable compliance reports from AWS:

├─ Compliance Reports
│  ├─ PCI-DSS attestation letter
│  ├─ SOC 2 Type II report (updated annually)
│  ├─ ISO 27001 certification
│  ├─ HIPAA compliance documentation
│  └─ FedRAMP authorization boundary documents
│
├─ NDA/Contract Management
│  ├─ AWS Business Associate Agreement (BAA)
│  ├─ Data Processing Addendum (DPA)
│  └─ Custom contractual agreements
│
└─ Use Case
   ├─ Customer asks: "Is AWS SOC 2 certified?"
   ├─ You download: SOC 2 Type II report from Artifact
   ├─ You provide: Report to customer compliance team
   └─ Customer accepts: Audit requirement satisfied

Benefit: Prove AWS security compliance
  (AWS responsibility in Shared Responsibility Model)
```

**AWS Audit Manager: Automated Evidence Collection**

```
Manual Audit (Old Way):
  ├─ Compliance officer: "Show me evidence of patch management"
  ├─ DevOps team: Manually collects 100+ log files
  ├─ Review process: 3 days of manual work
  └─ Result: Partial, incomplete evidence

Audit Manager (Automated Way):
  ├─ Audit framework: NIST Cybersecurity Framework
  ├─ Evidence collection: Automated from AWS APIs
  │  ├─ CloudTrail logs (who changed what)
  │  ├─ Config snapshots (what was the configuration)
  │  ├─ Lambda logs (when changes were applied)
  │  ├─ SNS notifications (evidence of alerting)
  │  └─ S3 access logs (audit trail)
  │
  ├─ Evidence aggregation: Audit Manager correlates
  │  └─ "On 2026-03-07, EC2 instance was patched"
  │  └─ Evidence: SSM document execution + CloudTrail log
  │
  └─ Report generation: Auto-formatted for auditors
     └─ Exportable as evidence summary
     └─ Links to source logs
```

#### Architecture Role

**Compliance Services in Audit Strategy:**

```
Configuration Change
    │
    ├─► AWS Config Records
    │   └─ Point-in-time snapshots
    │   └─ Each resource configuration version
    │
    ├─► Config Rules Evaluate
    │   └─ Against compliance baseline
    │   └─ Real-time compliance status
    │
    ├─► Audit Manager Collects Evidence
    │   └─ CloudTrail logs
    │   └─ Config snapshots
    │   └─ Remediation logs
    │   └─ Linking events with evidence
    │
    ├─► Security Hub Aggregates Findings
    │   └─ Config compliance results
    │   └─ Consolidated view
    │
    └─► Auditor Reviews
        ├─ Compliance dashboard
        ├─ Evidence links
        ├─ Assessment: Compliant / Non-compliant
        └─ Report signed
```

#### Production Usage Patterns

**Pattern 1: Continuous Compliance Monitoring**

```
Set up Config to track all resources:

aws configservice start-configuration-recorder --recorder-name default

aws configservice put-config-rules \
  --config-rules file://rules.json

Audit frequency: Every resource change (not just daily)
  ├─ S3 bucket encryption changed? Config detects < 1 minute
  ├─ Lambda function code updated? Compliance re-evaluated < 1 minute
  ├─ IAM policy added? Evaluated < 1 minute

Result:
  └─ No configuration drift goes undetected
  └─ Compliance status always current
  └─ Auditors can trust the dashboard
```

**Pattern 2: Config Rules for PCI-DSS Compliance**

```
PCI-DSS Requirement → Config Rule

Requirement 1.1 (Firewall standards):
  └─ aws-cloudfront-distribution-https-enabled
  └─ restricted-common-ports
  └─ security-group-ingress-cidr-check

Requirement 2.2 (Configuration standards):
  └─ ec2-security-group-ssh-check
  └─ iam-policy-blacklist-check
  └─ rds-public-access-check

Requirement 3.2 (Encryption):
  └─ s3-bucket-server-side-encryption-enabled
  └─ rds-encryption-enabled
  └─ encrypted-volumes

Requirement 8.1 (Access control):
  └─ iam-policy-no-statements-with-admin-access
  └─ iam-root-access-key-check
  └─ mfa-enabled-for-iam-console-access

Coverage: Deploy 50+ Config rules
  └─ Each rule monitors 1-100s of resources
  └─ Total compliance coverage: 95%+
```

#### DevOps Best Practices

**1. Implement Automatic Remediation for Drifted Resources**

```hcl
# Terraform: Config Rule with Auto-Remediation

resource "aws_config_config_rule" "s3_bucket_encryption" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
}

resource "aws_config_remediation_configuration" "s3_encryption_remediate" {
  config_rule_name = aws_config_config_rule.s3_bucket_encryption.name

  automatic                = true
  maximum_automatic_attempts = 10
  automatic_attempts_before_manual = 5

  target_type       = "SSM_DOCUMENT"
  target_identifier = "AWS-PublishS3BucketEncryption"

  target_version = "1"

  parameter {
    name           = "BucketName"
    static_value   = null
    resource_value = "RESOURCE_ID"
  }

  parameter {
    name         = "SSEAlgorithm"
    static_value = "AES256"
  }
}
```

**2. Archive Config Data to S3 for Long-Term Compliance**

```bash
# Enable AWS Config to deliver to S3

aws configservice put-delivery-channel \
  --delivery-channel name=default,s3BucketName=config-history-bucket,\
includeGlobalResources=true

# Transition old data to Glacier for cost savings
aws s3api put-bucket-lifecycle-configuration \
  --bucket config-history-bucket \
  --lifecycle-configuration '{
    "Rules": [
      {
        "Id": "ArchiveOldConfigSnapshots",
        "Filter": {"Prefix": "config/"},
        "Transitions": [
          {
            "Days": 90,
            "StorageClass": "GLACIER"
          }
        ]
      }
    ]
  }'
```

---

### Practical Code Examples

#### CloudFormation: Setup Config with Auto-Remediation

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'AWS Config setup with compliance rules and auto-remediation'

Resources:
  # ==================== Config Recorder ====================
  ConfigRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: config.amazonaws.com
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - 'arn:aws:iam::aws:policy/service-role/ConfigRole'
      Policies:
        - PolicyName: S3Access
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 's3:GetBucketVersioning'
                  - 's3:PutObject'
                Resource:
                  - !Sub 'arn:aws:s3:::${ConfigBucket}'
                  - !Sub 'arn:aws:s3:::${ConfigBucket}/*'

  ConfigBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'aws-config-${AWS::AccountId}-${AWS::Region}'
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  ConfigRecorder:
    Type: AWS::Config::ConfigurationRecorder
    Properties:
      RoleArn: !GetAtt ConfigRole.Arn
      RecordingGroup:
        AllSupported: true
        IncludeGlobalResources: true

  ConfigDeliveryChannel:
    Type: AWS::Config::DeliveryChannel
    Properties:
      S3BucketName: !Ref ConfigBucket
      SnsTopicARN: !GetAtt ComplianceNotificationTopic.TopicArn
      ConfigSnapshotDeliveryProperties:
        DeliveryFrequency: TwentyFour_Hours

  # ==================== Compliance Rules ====================
  S3EncryptionRule:
    Type: AWS::Config::ConfigRule
    DependsOn: ConfigRecorder
    Properties:
      ConfigRuleName: s3-bucket-server-side-encryption-enabled
      Description: Checks that S3 buckets have encryption enabled
      Source:
        Owner: AWS
        SourceIdentifier: S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED
      Scope:
        ComplianceResourceTypes:
          - 'AWS::S3::Bucket'

  EC2SecurityGroupRule:
    Type: AWS::Config::ConfigRule
    DependsOn: ConfigRecorder
    Properties:
      ConfigRuleName: ec2-ssh-restricted
      Description: Restricts SSH access to specific IPs
      Source:
        Owner: AWS
        SourceIdentifier: RESTRICTED_INCOMING_TRAFFIC
      InputParameters: |
        {
          "allowedPorts": "22",
          "allowedCIDR": "10.0.0.0/8"
        }
      Scope:
        ComplianceResourceTypes:
          - 'AWS::EC2::SecurityGroup'

  RDSEncryptionRule:
    Type: AWS::Config::ConfigRule
    DependsOn: ConfigRecorder
    Properties:
      ConfigRuleName: rds-storage-encrypted
      Description: Checks RDS encryption
      Source:
        Owner: AWS
        SourceIdentifier: RDS_STORAGE_ENCRYPTED
      Scope:
        ComplianceResourceTypes:
          - 'AWS::RDS::DBInstance'

  # ==================== Auto-Remediation ====================
  RemediationRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - config.amazonaws.com
                - ssm.amazonaws.com
            Action: 'sts:AssumeRole'
      ManagedPolicyArns:
        - 'arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole'
      Policies:
        - PolicyName: S3Remediation
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: Allow
                Action:
                  - 's3:PutEncryptionConfiguration'
                  - 's3:GetBucketVersioning'
                Resource: !Sub 'arn:aws:s3:::*'

  S3EncryptionRemediation:
    Type: AWS::Config::RemediationConfiguration
    Properties:
      ConfigRuleName: !Ref S3EncryptionRule
      TargetType: SSM_DOCUMENT
      TargetIdentifier: AWS-PublishS3BucketEncryption
      TargetVersion: '1'
      Automatic: true
      MaximumAutomaticAttempts: 5
      AutomaticAttemptIntervalSeconds: 60
      Parameters:
        BucketName:
          ResourceValue:
            Value: RESOURCE_ID
        SSEAlgorithm:
          StaticValue:
            Values:
              - AES256

  # ==================== Notifications ====================
  ComplianceNotificationTopic:
    Type: AWS::SNS::Topic
    Properties:
      DisplayName: AWS Config Compliance Notifications
      TopicName: config-compliance-notifications

  ComplianceNotificationSubscription:
    Type: AWS::SNS::Subscription
    Properties:
      TopicArn: !Ref ComplianceNotificationTopic
      Protocol: email
      Endpoint: security-team@example.com

Outputs:
  ConfigBucketName:
    Description: S3 bucket for Config snapshots
    Value: !Ref ConfigBucket

  ComplianceTopicArn:
    Description: SNS topic for compliance notifications
    Value: !Ref ComplianceNotificationTopic
```

---

## IAM Auditing - Access Analyzer, Credential Report, Policy Simulator, Access Advisor {#iam-auditing}

### Textual Deep Dive

#### Internal Working Mechanism

IAM Auditing comprises four complementary tools that provide visibility into identity and access patterns:

1. **Access Analyzer**: Identifies external access (who outside your account can access resources)
2. **Credential Report**: Lists all IAM users, credential status, MFA enrollment
3. **Policy Simulator**: Tests whether a specific IAM principal can perform an action
4. **Access Advisor**: Shows which IAM permissions are actually used by a principal

**Access Analyzer: External Access Detection**

```
┌────────────────────────────────────────────────┐
│   Your AWS Account (Account ID: 123456789012)  │
│                                                 │
│  ├─ S3 Bucket: customer-data                  │
│  │  └─ Bucket Policy: Allows Account 987654321 │
│  │                   (partner account)         │
│  │                                             │
│  ├─ Lambda Function: process-orders           │
│  │  └─ Role Trust Policy: Allows               │
│  │     arn:aws:iam::EXTERNAL:role/partner-app │
│  │                                             │
│  └─ KMS Key: prod-encryption-key              │
│     └─ Key Policy: Allows                      │
│        service: cloudtrail.amazonaws.com       │
│        (AWS service, not external)             │
│                                                 │
└────────────────────────────────────────────────┘
    │
    ▼
┌────────────────────────────────────────────────┐
│   Access Analyzer Analysis                     │
│                                                 │
│   Finding Type 1: External Principal Access   │
│   └─ Resource: S3 bucket customer-data        │
│   └─ External: Account 987654321              │
│   └─ Action: s3:GetObject, s3:ListBucket      │
│   └─ Status: EXTERNAL_ACCESS_ALLOWED          │
│   └─ Source: Bucket policy                    │
│   └─ Recommendation: Review if intentional    │
│                                                 │
│   Finding Type 2: Unused Permissions          │
│   └─ Resource: Lambda IAM role                │
│   └─ Permission: s3:DeleteBucket              │
│   └─ Status: UNUSED (never called in 90 days) │
│   └─ Recommendation: Remove permission        │
│                                                 │
│   Finding Type 3: Public Access               │
│   └─ Resource: S3 bucket logs                 │
│   └─ Principal: * (anyone)                    │
│   └─ Action: s3:GetObject                     │
│   └─ Status: PUBLIC_READ_ACCESS               │
│   └─ Recommendation: Remove or restrict       │
│                                                 │
└────────────────────────────────────────────────┘
```

**Credential Report: User Status Dashboard**

```
csv output from get-credential-report:

user,arn,user_creation_time,password_enabled,password_last_changed,\
password_next_rotation,mfa_active,access_key_1_active,access_key_2_active

app-user-1,arn:aws:iam::123456789012:user/app-user-1,\
2024-01-15T10:00:00Z,false,N/A,N/A,false,false,false

  └─ Status: No credentials; inactive user (good - clean up?)

app-user-2,arn:aws:iam::123456789012:user/app-user-2,\
2024-01-15T10:00:00Z,true,2025-02-28T14:00:00Z,2026-02-28,true,true,false

  └─ Status: Password enabled, MFA active, 1 access key active (good)
  └─ Password age: 8 days (recent rotation - good)

legacy-user,arn:aws:iam::123456789012:user/legacy-user,\
2020-06-01T10:00:00Z,true,2023-08-15T10:00:00Z,2024-08-15,false,true,true

  └─ Problems:
     ├─ Password last changed 2.5 years ago (should be < 1 year)
     ├─ MFA not enabled (violates security policy)
     ├─ Has 2 active access keys (should have 1)
     └─ Password rotation past due

Recommendation:
  ├─ Disable legacy-user
  ├─ Rotate credentials immediately
  ├─ Require MFA
  └─ Audit what this user is doing
```

**Policy Simulator: Permission Validation**

```
Question: "Can app-role assume Lambda from EC2?"

Inputs:
  - Principal: arn:aws:iam::123456789012:role/app-role
  - Action: sts:AssumeRole
  - Resource: arn:aws:iam::123456789012:role/lambda-role

Policy Simulator Checks:
  ├─ Step 1: Check app-role's IAM policy
  │  └─ Does app-role have sts:AssumeRole permission?
  │  └─ Is the resource lambda-role in scope?
  │  └─ Are any conditions (IP, time) met?
  │  └─ Result: Explicit DENY not found
  │
  ├─ Step 2: Check lambda-role's trust policy
  │  └─ Does lambda-role trust app-role?
  │  └─ Trust Principal: arn:aws:iam::123456789012:role/app-role
  │  └─ Result: app-role explicitly trusted
  │
  └─ Step 3: Check for SCPs (Service Control Policies)
     └─ Organization-level policies that override IAM
     └─ Result: No restrictive SCP found

Final Result:
  ┌────────────────────┐
  │  ALLOWED           │
  │  implicit       │
  └────────────────────┘
  Explanation: app-role can assume lambda-role
```

**Access Advisor: Permission Usage Analysis**

```
IAM Role: app-role

Granted Permissions (from IAM policies):
  ├─ s3:GetObject          (granted 2024-01-10)
  ├─ s3:ListBucket        (granted 2024-01-10)
  ├─ dynamodb:Scan        (granted 2024-01-10)
  ├─ dynamodb:Query       (granted 2024-01-10)
  ├─ cloudwatch:PutMetric (granted 2024-01-10)
  ├─ logs:PutLogEvents    (granted 2024-01-10)
  ├─ kms:Decrypt          (granted 2024-01-10)
  └─ sns:Publish          (granted 2024-01-10)

Last Accessed (from CloudTrail):
  ├─ s3:GetObject           → accessed 2 hours ago   ✓ IN USE
  ├─ s3:ListBucket         → accessed 1 day ago     ✓ IN USE
  ├─ dynamodb:Scan         → accessed 30 days ago   ⚠ STALE
  ├─ dynamodb:Query        → never accessed         ✗ UNUSED
  ├─ cloudwatch:PutMetric  → accessed 10 min ago    ✓ IN USE
  ├─ logs:PutLogEvents     → accessed 2 min ago     ✓ IN USE
  ├─ kms:Decrypt           → accessed 1 week ago    ✓ IN USE
  └─ sns:Publish           → never accessed         ✗ UNUSED

Recommendation:
  ├─ UNUSED: Remove dynamodb:Query and sns:Publish
  ├─ STALE: Review dynamodb:Scan; remove if not needed
  └─ IN USE: Keep as-is

Action:
  Remove 3 unused permissions
  → Reduces role from 8 to 5 permissions (least privilege)
  → Reduces attack surface
  → Acceptable: Lost privileges only if never used
```

#### Architecture Role

**IAM Auditing in Governance Stack:**

```
┌─────────────────────────────────────────────────┐
│ IAM Auditing (4 complementary tools)            │
├─────────────────────────────────────────────────┤
│                                                  │
│  Access Analyzer                               │
│  └─ Answers: "Who outside our account can     │
│             access our resources?"             │
│  └─ Focus: External threats                    │
│                                                  │
│  Credential Report                             │
│  └─ Answers: "What's the credential health    │
│             of all IAM users?"                 │
│  └─ Focus: Compliance + hygiene                │
│                                                  │
│  Policy Simulator                              │
│  └─ Answers: "Can principal X do action Y?"   │
│  └─ Focus: Testing + troubleshooting           │
│                                                  │
│  Access Advisor                                │
│  └─ Answers: "Which grantedpermissions are   │
│             actually used?"                   │
│  └─ Focus: Least privilege enforcement        │
│                                                  │
└─────────────────────────────────────────────────┘
    │
    └─► Integrated Security Posture:
        └─ Permission creep identified (Access Advisor)
        └─ Unused permissions removed (Access Advisor)
        └─ Stale users identified (Credential Report)
        └─ External access reviewed (Access Analyzer)
        └─ Quarterly audit completed
```

#### Production Usage Patterns

**Pattern 1: Quarterly Least-Privilege Audit**

```
Process:

Week 1: Generate Reports
  ├─ Credential Report: All IAM users status
  ├─ Access Advisor: All roles and permissions
  └─ Access Analyzer: All external access

Week 2: Analysis
  ├─ Identify stale users (no login in 90 days)
  ├─ Identify unused permissions (Access Advisor)
  ├─ Flag questionable external access
  └─ Create remediation list

Week 3: Remediation
  ├─ Delete stale users (with approval)
  ├─ Remove unused permissions
  │  └─ Use Policy Simulator to verify removal won't break app
  ├─ Adjust external access policies
  └─ Require MFA for users lacking it

Week 4: Verification
  ├─ Test application functionality post-changes
  ├─ Verify no permission errors in CloudWatch Logs
  ├─ Confirm external access still works (if intentional)
  └─ Generate updated reports (baseline for next quarter)

Result:
  └─ Permissions reduced 20-30% (less attack surface)
  └─ Unused credentials removed
  └─ External access justified + documented
  └─ Compliance audit: "Least privilege demonstrated"
```

**Pattern 2: Eliminating Long-Lived Access Keys**

```
Old Architecture (High Risk):
  ├─ App deployed 3 years ago with hardcoded AWS credentials
  ├─ Same credentials still active today
  ├─ If credentials leaked: 3 years of potential unauthorized access
  └─ Risk: High (stale, possibly compromised)

Credential Report shows:
  └─ access_key_1_active: true
  └─ access_key_1_last_rotated: 2023-01-15 (2+ years ago)

New Architecture (Low Risk):
  ├─ App uses IAM role (temporary credentials)
  ├─ Credentials auto-rotated every hour by STS
  ├─ If credentials leaked: Valid for < 1 hour only
  ├─ Access logged to CloudTrail (full audit trail)
  └─ Risk: Low (auto-rotation, short-lived)

Steps:
  1. Disable old access key
  2. Migrate app to use IAM role
  3. Test in staging (1 week)
  4. Deploy to production (canary, 10% → 100%)
  5. Delete old access key after 30-day grace period
```

---

### Practical Code Examples

#### Shell Script: IAM Auditing Automation

```bash
#!/bin/bash
# Script: Comprehensive IAM auditing report

set -e

OUTPUT_DIR="iam-audit-$(date +%Y-%m-%d)"
mkdir -p "$OUTPUT_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"; }

log "Starting IAM audit..."

# ==================== Credential Report ====================
log "Generating credential report..."
aws iam generate-credential-report
sleep 2  # Wait for report generation

aws iam get-credential-report \
  --query 'Content' \
  --output text | base64 -d > "$OUTPUT_DIR/credential-report.csv"

# Parse and highlight issues
log "Analyzing credential report..."
{
  echo "## Users with Missing MFA"
  awk -F',' 'NR>1 && $9=="false" {print $1}' "$OUTPUT_DIR/credential-report.csv"
  
  echo ""
  echo "## Users with Stale Passwords (>90 days)"
  awk -F',' 'NR>1 && $3!="N/A" {
    last_changed=$3
    # Convert to epoch (simplified)
    if((now - mktime(last_changed)) > 7776000) print $1
  }' "$OUTPUT_DIR/credential-report.csv"
  
  echo ""
  echo "## Inactive Users (no login >90 days)"
  awk -F',' 'NR>1 && $8=="N/A" {print $1}' "$OUTPUT_DIR/credential-report.csv"
} | tee "$OUTPUT_DIR/credential-issues.txt"

# ==================== Access Advisor ====================
log "Collecting Access Advisor data..."
aws iam get-credential-report --output json | jq '.Roles[] | .RoleName' -r | while read role; do
  log "Analyzing role: $role"
  
  aws iam get-role-policy-version \
    --role-name "$role" \
    --query 'PolicyVersion.Document.Statement[]' \
    --output json > "$OUTPUT_DIR/role-$role-policies.json"
  
  # Get last accessed info
  aws accessanalyzer validate-policy \
    --policy-document file://"$OUTPUT_DIR/role-$role-policies.json" \
    --policy-type IDENTITY_POLICY \
    --output json | jq '.findings[]' \
    >> "$OUTPUT_DIR/role-policy-findings.json"
done

# ==================== Access Analyzer ====================
log "Checking for external access via Access Analyzer..."
aws accessanalyzer list-findings \
  --analyzer-arn "arn:aws:access-analyzer:us-east-1:$(aws sts get-caller-identity --query Account --output text):analyzer/ConsoleAnalyzer" \
  --filter 'resourceType=[{value=AWS::S3::Bucket},{value=AWS::KMS::Key},{value=AWS::IAM::Role}]' \
  --query 'findings[?status==`ACTIVE`].[resourceType,resourceId,principal,access]' \
  --output table | tee "$OUTPUT_DIR/external-access.txt"

# ==================== Policy Simulator Tests ====================
log "Testing critical permissions..."
{
  echo "## Testing: Can app-role access prod-database?"
  aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/app-role" \
    --action-names rds-db:connect \
    --resource-arns "arn:aws:rds:*:*:db/prod-database" \
    --query 'EvaluationResults[0].[EvalDecision,EvalResourceName]' \
    --output table
  
  echo ""
  echo "## Testing: Can app-role read Secrets Manager?"
  aws iam simulate-principal-policy \
    --policy-source-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/app-role" \
    --action-names secretsmanager:GetSecretValue \
    --resource-arns "arn:aws:secretsmanager:*:*:secret:prod/*" \
    --query 'EvaluationResults[0].[EvalDecision,EvalResourceName]' \
    --output table
} | tee "$OUTPUT_DIR/policy-simulator-results.txt"

# ==================== Recommendations ====================
log "Generating recommendations..."
{
  echo "## RECOMMENDATIONS"
  echo ""
  echo "1. MFA Remediation:"
  grep -c "mfa" "$OUTPUT_DIR/credential-issues.txt" | xargs echo "   Users without MFA:" || true
  
  echo ""
  echo "2. Credential Rotation:"
  grep "stale" "$OUTPUT_DIR/credential-issues.txt" | wc -l | xargs echo "   Users with stale passwords:" || true
  
  echo ""
  echo "3. Access Review:"
  wc -l < "$OUTPUT_DIR/external-access.txt" | xargs echo "   External access findings:" || true
  
  echo ""
  echo "4. Next Steps:"
  echo "   - Require MFA for all human users"
  echo "   - Enforce 90-day password rotation"
  echo "   - Review and justify external access"
  echo "   - Implement access advisor cleanup quarterly"
} | tee "$OUTPUT_DIR/recommendations.txt"

log "IAM audit complete. Results saved to: $OUTPUT_DIR"
ls -lah "$OUTPUT_DIR"
```

---

## Incident Response Automation - Lambda, Step Functions, CloudWatch Events, Runbooks {#incident-response-automation}

### Textual Deep Dive

#### Internal Working Mechanism

Incident response automation transforms manual response procedures (which take hours) into automated workflows (which take minutes). The typical architecture is:

```
SecurityEvent
    │
    ├─► EventBridge Rule (matches event type)
    │
    ├─► SNS/SQS (notify team + queue event)
    │
    ├─► Lambda (lightweight response)
    │   OR
    │   Step Functions (complex workflow)
    │
    ├─► Remediation Actions
    │   ├─ Disable IAM role
    │   ├─ Snapshot EC2 instance
    │   ├─ Isolate security group
    │   ├─ Rotate credentials
    │   └─ Create incident ticket
    │
    ├─► Post-Incident
    │   ├─ Preserve forensics
    │   ├─ Notify on-call team
    │   ├─ Trigger post-mortem
    │   └─ Update runbook
    │
    └─ Incident Response Time: Minutes (vs. Hours)
```

**Event-Driven Response Example:**

```
GuardDuty Finding: "UnauthorizedAPI.IAMUser.MaliciousIPCaller"
  └─ Severity: 8.0 (high)
  └─ Principal: lambda-exec-role
  └─ API: GetSecretValue (500+ times in 2 minutes)
  └─ Source IP: 203.0.113.45 (known botnet)

EventBridge Pattern Match:
  ├─ Source: aws.guardduty
  ├─ Severity >= 7
  ├─ Type contains "UnauthorizedAPI"
  └─ MATCH → Trigger Lambda

Lambda Execution (Auto-remediation):
  ├─ Receive event
  ├─ Extract principal: lambda-exec-role
  ├─ Action 1: Embed response Lambda
  │  └─ Get inline policies for principal
  │  └─ Create deny policy
  │  └─ Attach deny policy (blocks all future actions)
  │  └─ Result: Role disabled in < 10 seconds
  │
  ├─ Action 2: Create forensics snapshot
  │  └─ If event is EC2-related, snapshot AMI
  │  └─ Send to forensics bucket
  │  └─ Result: Evidence preserved
  │
  ├─ Action 3: Notify team
  │  └─ SNS message with finding details
  │  └─ Slack webhook with incident summary
  │  └─ On-call engineer alerted
  │  └─ Result: Human aware < 1 minute
  │
  ├─ Action 4: Create incident ticket
  │  └─ POST to Jira / Servicenow API
  │  └─ Set priority: Critical
  │  └─ Assign to on-call
  │  └─ Result: Investigation tracked
  │
  └─ Action 5: Preserve evidence
     └─ Export CloudTrail logs
     └─ Store in immutable S3 bucket
     └─ Result: Audit trail secured

Total time: < 2 minutes (vs. 2+ hours manual)
```

#### Architecture Role

**Incident Response Automation in Security Stack:**

```
┌────────────────────────────────────────┐
│  Multiple Security Events              │
├────────────────────────────────────────┤
│                                        │
│  Event 1: GuardDuty Finding (threat   │
│  Event 2: WAF High Block Rate          │
│  Event 3: Config Drift (config change)│
│  Event 4: IAM Analyzer Finding         │
│  Event 5: CloudTrail Suspicious API   │
│                                        │
└────────────────┬───────────────────────┘
                 │
                 ▼
        ┌────────────────────┐
        │  EventBridge       │
        │  (Event Router)    │
        └────┬───┬───────┬──┘
             │   │       │
        ┌────▼┐ ┌┴────┐ ┌┴─────────┐
        │SNS  │ │SQS  │ │Lambda    │
        │Alert│ │Queue│ │Response  │
        └─────┘ └─────┘ └────┬────┘
                           │
                   ┌───────┼──────────┐
                   ▼       ▼          ▼
              Step Fn   S3 Snapshot   Disable IAM
```

#### Production Usage Patterns

**Pattern 1: Automated Incident Response Runbook**

```
Threat: Compromised IAM credential
Detected by: GuardDuty (impossible travel detection)
Response Time Goal: < 5 minutes
Automation: Step Functions + Lambda

Step Function Workflow:

1. RECEIVE EVENT
   └─ Extract principal ARN, API called, source IP
   
2. VALIDATE THREAT
   └─ Confidence score > 80%?
   └─ If no: Manual review; exit
   └─ If yes: Continue
   
3. IMMEDIATE CONTAINMENT
   Lambda 1: Disable Principal
   └─ Create deny-all policy
   └─ Attach to principal (blocks all APIs)
   └─ Timeline: < 10 seconds
   
   Lambda 2: Snapshot State
   └─ Export CloudTrail logs (last 1 hour)
   └─ Export VPC Flow Logs
   └─ Store in forensics S3 bucket
   └─ Timeline: < 30 seconds
   
4. NOTIFY TEAM
   Lambda 3: Alert
   └─ SNS to security@company
   └─ Slack to #security-incidents
   └─ Page on-call via PagerDuty
   └─ Timeline: < 1 minute
   
5. INVESTIGATION
   Human Decision Point:
   └─ On-call engineer reviews evidence
   └─ Decides: Legitimate access or actual breach?
   
6. REMEDIATION
   If Breach Confirmed:
   └─ Rotate credentials
   └─ Review CloudTrail (what was accessed?)
   └─ Notify affected customers
   └─ Create post-mortem ticket
   
7. RECOVERY
   If False Positive:
   └─ Remove deny policy
   └─ Restore principal
   └─ Log incident for baseline adjustment

Result:
  └─ If breach: Contained < 5 min (vs. 2+ hours manual)
  └─ If false positive: Easy recovery
  └─ Full audit trail of response actions
```

**Pattern 2: Step Functions for Complex Workflows**

```
Threat: Cryptocurrency mining detected on EC2 instance
Automation Goal: Disable instance while preserving forensics

Step Function Definition (JSON):

{
  "StartAt": "ReceiveEvent",
  "States": {
    "ReceiveEvent": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:region:account:function:ParseFinding",
      "Next": "AssessConditions"
    },
    
    "AssessConditions": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.severity",
          "NumericGreaterThan": 7,
          "Next": "BeginContainment"
        }
      ],
      "Default": "ManualReview"
    },
    
    "BeginContainment": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "CreateSnapshot",
          "States": {
            "CreateSnapshot": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:region:account:function:SnapshotEC2",
              "Next": "StoreForensics"
            },
            "StoreForensics": {
              "Type": "Task",
              "Resource": "arn:aws:s3:::forensics-bucket",
              "End": true
            }
          }
        },
        {
          "StartAt": "ExportLogs",
          "States": {
            "ExportLogs": {
              "Type": "Task",
              "Resource": "arn:aws:lambda:region:account:function:ExportLogs",
              "Next": "StoreEvidence"
            },
            "StoreEvidence": {
              "Type": "Task",
              "Resource": "arn:aws:s3:::evidence-bucket",
              "End": true
            }
          }
        }
      ],
      "Next": "IsolateInstance"
    },
    
    "IsolateInstance": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:region:account:function:DisableEC2",
      "Next": "NotifyTeam"
    },
    
    "NotifyTeam": {
      "Type": "Task",
      "Resource": "arn:aws:sns:region:account:security-alerts",
      "Next": "CreateTicket"
    },
    
    "CreateTicket": {
      "Type": "Task",
      "Resource": "arn:aws:lambda:region:account:function:CreateJiraTicket",
      "End": true
    },
    
    "ManualReview": {
      "Type": "Pass",
      "Next": "NotifyTeam"
    }
  }
}

Benefits of Step Functions:
  ├─ Orchestrates multiple Lambda functions
  ├─ Parallel execution (snapshots + logs simultaneously)
  ├─ Error handling (if snapshot fails, continue with logs)
  ├─ Human approval points (pause for decision)
  ├─ Visual workflow in console (debugging)
  └─ Execution history (full audit trail)
```

#### DevOps Best Practices

**1. Design Runbooks in Code**

```python
# Runbook defined in code (not in README)
# Ensures: Automated, tested, version-controlled

class IncidentResponse:
    def __init__(self, finding):
        self.finding = finding
        self.incident_id = generate_incident_id()
    
    def respond(self):
        try:
            self.assess_threat()
            self.contain_threat()
            self.preserve_forensics()
            self.notify_team()
            self.create_investigation_ticket()
        except Exception as e:
            self.handle_failure(e)
            self.escalate_to_human()
    
    def assess_threat(self):
        if self.finding['Severity'] < 7:
            raise ManualReviewRequired("Low severity")
    
    def contain_threat(self):
        principal = self.finding['Principal']
        self.disable_iam_principal(principal)  # < 10 sec
    
    def preserve_forensics(self):
        cloudtrail_logs = self.export_cloudtrail(last_hour=True)
        self.store_in_s3(cloudtrail_logs, prefix="forensics")
    
    def notify_team(self):
        self.send_sns("Security incident detected")
        self.post_slack_webhook()
        self.page_oncall()
    
    def create_investigation_ticket(self):
        self.create_jira_ticket(
            assignee="security-team",
            priority="Critical",
            description=f"Incident {self.incident_id}"
        )
```

**2. Test Runbooks Quarterly**

```bash
# Runbook testing: Simulate incidents without causing damage

# Test 1: Verify Lambda response execution
aws lambda invoke \
  --function-name incident-response-lambda \
  --payload '{"finding":{"Severity":8,"Principal":"test-role"},"DryRun":true}' \
  response.json

# Test 2: Verify Step Function workflow
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:region:account:stateMachine:IncidentResponse \
  --input '{"DryRun":true,"InstanceId":"i-test123"}' \
  --output json

# Test 3: Verify notifications reach team
# Expected: SNS email received, Slack message posted, PagerDuty alert triggered

# Test 4: Measure response time
# Dry-run Execution time: 45 seconds (vs. manual response: 2 hours)
# Target: Keep automated response < 5 minutes
```

**3. Implement Incident Response Phases**

```
Phase 1: DETECT (<5 min)
  ├─ Security event occurs
  ├─ GuardDuty / WAF / Config triggers finding
  ├─ EventBridge matches rule
  └─ Alert sent to on-call

Phase 2: RESPOND (<15 min)
  ├─ Lambda auto-remedies (disable, isolate, snapshot)
  ├─ Manual verification begins
  ├─ Investigation ticket created
  └─ Stakeholders notified

Phase 3: INVESTIGATE (1-4 hours)
  ├─ Analyze CloudTrail logs
  ├─ Determine scope of compromise
  ├─ Identify root cause
  └─ Plan recovery

Phase 4: RECOVER (varies)
  ├─ Rotate credentials
  ├─ Apply patches
  ├─ Rebuild affected systems
  └─ Verify operations

Phase 5: LEARN (post-incident)
  ├─ Document timeline
  ├─ Root cause analysis
  ├─ Update runbooks
  ├─ Train team
  └─ Adjust detection baselines

KPIs:
  ├─ Detection to Response: < 5 min
  ├─ Response to Investigation: < 15 min
  ├─ Investigation to Recovery: < 4 hours
  └─ Post-incident to Lessons Learned: < 1 week
```

---

### Practical Code Examples

#### Python Lambda: Automated Response to GuardDuty Findings

```python
"""
Lambda function: Respond to GuardDuty findings automatically
Triggers from EventBridge when GuardDuty finding severity >= 7
"""

import json
import boto3
import logging
from datetime import datetime

# Initialize clients
iam = boto3.client('iam')
ec2 = boto3.client('ec2')
s3 = boto3.client('s3')
sns = boto3.client('sns')
ssm = boto3.client('ssm')
cloudtrail = boto3.client('cloudtrail')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

FORENSICS_BUCKET = 'incident-forensics'
SNS_TOPIC = 'arn:aws:sns:us-east-1:123456789012:security-alerts'
INCIDENT_PREFIX = 'incident'

def lambda_handler(event, context):
    """
    Main handler for GuardDuty events
    """
    try:
        finding = event['detail']
        incident_id = f"{INCIDENT_PREFIX}-{int(datetime.now().timestamp())}"
        
        logger.info(f"Processing GuardDuty finding: {finding['id']}")
        logger.info(f"Incident ID: {incident_id}")
        
        # Extract threat information
        threat_info = extract_threat_info(finding)
        
        # Assess threat severity
        severity = float(finding['severity'])
        if severity < 7:
            logger.info(f"Severity {severity} below threshold; manual review only")
            notify_manual_review(incident_id, finding)
            return {
                'statusCode': 200,
                'body': 'Low severity finding - manual review'
            }
        
        # HIGH SEVERITY - AUTO-REMEDIATE
        logger.warning(f"HIGH SEVERITY finding ({severity}) - initiating auto-response")
        
        # Step 1: Contain threat
        containment_result = contain_threat(threat_info, incident_id)
        
        # Step 2: Preserve forensics
        forensics_result = preserve_forensics(threat_info, incident_id)
        
        # Step 3: Notify team
        notify_incident(incident_id, finding, containment_result)
        
        # Step 4: Create investigation ticket
        ticket_id = create_investigation_ticket(incident_id, finding)
        
        return {
            'statusCode': 200,
            'incident_id': incident_id,
            'containment': containment_result,
            'forensics': forensics_result,
            'ticket_id': ticket_id
        }
    
    except Exception as e:
        logger.error(f"Error processing finding: {str(e)}", exc_info=True)
        escalate_to_human(event, str(e))
        raise

def extract_threat_info(finding):
    """Extract threat details from GuardDuty finding"""
    resource = finding.get('resource', {})
    return {
        'finding_id': finding['id'],
        'finding_type': finding['type'],
        'severity': finding['severity'],
        'resource_type': resource.get('resourceType'),
        'principal': extract_principal(finding),
        'source_ip': extract_source_ip(finding),
        'api_called': extract_api(finding),
    }

def extract_principal(finding):
    """Extract IAM principal from finding detail"""
    detail = finding.get('detail', {})
    
    # Try different finding types
    if 'principalId' in detail:
        return detail['principalId']
    
    access_key = detail.get('accessKeyDetails', {}).get('accessKeyId')
    if access_key:
        return access_key
    
    instance_id = finding.get('resource', {}).get('instanceDetails', {}).get('instanceId')
    if instance_id:
        try:
            instance = ec2.describe_instances(InstanceIds=[instance_id])
            return instance['Reservations'][0]['Instances'][0]['IamInstanceProfile']['Arn']
        except:
            pass
    
    return None

def extract_source_ip(finding):
    """Extract source IP from finding"""
    return finding.get('detail', {}).get('service', {}).get('action', {}).get('networkConnectionAction', {}).get('remoteIpDetails', {}).get('ipAddressV4')

def extract_api(finding):
    """Extract API called from finding"""
    return finding.get('detail', {}).get('service', {}).get('action', {}).get('awsApiCallAction', {}).get('api')

def contain_threat(threat_info, incident_id):
    """
    Contain the threat by disabling the compromised principal
    """
    result = {
        'success': False,
        'actions': []
    }
    
    principal = threat_info['principal']
    if not principal:
        logger.warning("Cannot determine principal; skipping containment")
        return result
    
    try:
        if principal.startswith('arn:aws:iam'):
            # It's an IAM role
            role_name = principal.split('/')[-1]
            
            # Create deny-all policy
            deny_policy = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Deny",
                        "Action": "*",
                        "Resource": "*"
                    }
                ]
            }
            
            # Attach deny policy to role
            iam.put_role_policy(
                RoleName=role_name,
                PolicyName=f'emergency-deny-{incident_id}',
                PolicyDocument=json.dumps(deny_policy)
            )
            
            result['success'] = True
            result['actions'].append(f"Attached deny-all policy to role {role_name}")
            logger.info(f"Disabled IAM role: {role_name}")
        
        elif principal.startswith('AKIA') or principal.startswith('ASIA'):
            # It's an access key
            user_info = iam.get_access_key_last_used(AccessKeyId=principal)
            user_name = user_info['AccessKeyLastUsed']['UserName']
            
            # Deactivate access key
            iam.update_access_key(
                AccessKeyId=principal,
                Status='Inactive'
            )
            
            result['success'] = True
            result['actions'].append(f"Deactivated access key {principal[:10]}... for user {user_name}")
            logger.info(f"Disabled access key: {principal}")
        
        else:
            logger.warning(f"Unknown principal type: {principal}")
    
    except Exception as e:
        logger.error(f"Failed to contain threat: {str(e)}")
        result['success'] = False
    
    return result

def preserve_forensics(threat_info, incident_id):
    """
    Preserve forensic evidence for investigation
    """
    result = {
        'success': False,
        'forensics_location': None
    }
    
    try:
        # Export CloudTrail logs
        events = cloudtrail.lookup_events(
            LookupAttributes=[
                {
                    'AttributeKey': 'PrincipalId',
                    'AttributeValue': threat_info['principal']
                }
            ],
            MaxResults=50
        )
        
        # Store in S3
        forensics_key = f"{FORENSICS_BUCKET}/{incident_id}/cloudtrail-logs.json"
        s3.put_object(
            Bucket=FORENSICS_BUCKET,
            Key=forensics_key,
            Body=json.dumps(events['Events']),
            ServerSideEncryption='AES256',
            Metadata={
                'incident-id': incident_id,
                'timestamp': datetime.now().isoformat(),
                'principal': threat_info['principal']
            }
        )
        
        result['success'] = True
        result['forensics_location'] = f"s3://{FORENSICS_BUCKET}/{forensics_key}"
        logger.info(f"Forensics preserved at {result['forensics_location']}")
    
    except Exception as e:
        logger.error(f"Failed to preserve forensics: {str(e)}")
    
    return result

def notify_incident(incident_id, finding, containment_result):
    """
    Notify security team of incident
    """
    message = f"""
INCIDENT ALERT: High-Severity Security Finding

Incident ID: {incident_id}
Finding Type: {finding['type']}
Severity: {finding['severity']}/10
Timestamp: {finding['updateTime']}

Containment Actions:
{json.dumps(containment_result['actions'], indent=2)}

Evidence: Check forensics bucket for CloudTrail logs
Status: {containment_result['status']}

Action Required: Verify incident scope and plan recovery
"""
    
    try:
        sns.publish(
            TopicArn=SNS_TOPIC,
            Subject=f"[CRITICAL] Incident {incident_id}: {finding['type']}",
            Message=message
        )
        logger.info("Team notified via SNS")
    except Exception as e:
        logger.error(f"Failed to send SNS notification: {str(e)}")

def create_investigation_ticket(incident_id, finding):
    """
    Create investigation ticket in ticketing system
    (assumes integration with Jira, ServiceNow, etc.)
    """
    try:
        # Example: Call Parameter Store to get ticket system endpoint
        ticket_endpoint = ssm.get_parameter(
            Name='/incident-response/ticketing-endpoint',
            WithDecryption=True
        )['Parameter']['Value']
        
        # Create ticket (implementation depends on system)
        # This is a simplified example
        logger.info(f"Would create ticket at {ticket_endpoint}")
        
        return f"TICKET-{incident_id}"
    
    except Exception as e:
        logger.error(f"Failed to create ticket: {str(e)}")
        return None

def notify_manual_review(incident_id, finding):
    """Notify for manual review of low-severity findings"""
    message = f"Low-severity finding requires manual review: {finding['type']}"
    sns.publish(TopicArn=SNS_TOPIC, Subject="Manual Review Required", Message=message)

def escalate_to_human(event, error_message):
    """Escalate to human if automation fails"""
    message = f"Incident response automation failed:\n\n{error_message}\n\nEvent: {json.dumps(event)}"
    sns.publish(
        TopicArn=SNS_TOPIC,
        Subject="INCIDENT RESPONSE FAILURE - MANUAL ACTION REQUIRED",
        Message=message
    )
```

---

## Hands-on Scenarios {#hands-on-scenarios}

### Scenario 1: Implementing Automated Secrets Rotation Without Service Disruption

**Problem Statement:**

Your organization runs a multi-region e-commerce platform with:
- 3 RDS instances (US, EU, APAC)
- 50+ microservices accessing databases with hardcoded credentials currently stored in Parameter Store
- No rotation currently happening (credentials unchanged for 2+ years)
- SLA requirement: Zero downtime during rotation
- Compliance requirement: Quarterly credential rotation (PCI-DSS)

**Challenge:**
Current approach uses static IAM credentials stored in environment variables. If you rotate immediately, all services fail until redeployed. Need to implement automated rotation without service outages.

**Architecture Context:**

```
Current (Insecure):
  Microservice 1,2,3... ──┐
                          ├──► Hardcoded password ──► RDS
  Microservice 50... ────┘
  
  Problem:
  - All services break simultaneously when password rotates
  - No way to do graceful transition
  - Audit trail for who changed passwords is poor
```

**Step-by-Step Implementation:**

**Step 1: Enable Secrets Manager for RDS (Day 1)**

```bash
# Create master secret in Secrets Manager
aws secretsmanager create-secret \
  --name prod/rds/master-password \
  --secret-string "{\"username\":\"admin\",\"password\":\"$(openssl rand -base64 32)\"}" \
  --add-replica-regions '[{"Region":"eu-west-1"},{"Region":"ap-southeast-1"}]' \
  --tags Key=Environment,Value=production Key=RotationRequired,Value=true

# Enable automatic rotation (every 30 days)
aws secretsmanager rotate-secret \
  --secret-id prod/rds/master-password \
  --rotation-rules AutomaticallyAfterDays=30,Duration=3,ScheduleExpression='rate(30 days)'
```

**Step 2: Update Application Code to Use Secrets Manager (Week 1)**

Change from hardcoded credentials to Secrets Manager lookup:

```python
# OLD CODE (BEFORE):
DB_PASSWORD = os.getenv('DB_PASSWORD')  # Hardcoded in Dockerfile/env
connection = psycopg2.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD)

# NEW CODE (AFTER):
import boto3

secrets_client = boto3.client('secretsmanager')
secret_cache = {}
cache_ttl = 300  # Refresh every 5 min

def get_db_password():
    now = time.time()
    
    if 'password' in secret_cache:
        password, timestamp = secret_cache['password']
        if now - timestamp < cache_ttl:
            return password
    
    response = secrets_client.get_secret_value(SecretId='prod/rds/master-password')
    password = json.loads(response['SecretString'])['password']
    secret_cache['password'] = (password, now)
    return password

# Connection now automatically gets fresh password every 5 min
connection = psycopg2.connect(
    host=DB_HOST,
    user=DB_USER,
    password=get_db_password(),
    connect_timeout=5
)
```

**Step 3: Deploy Gradually (Week 2)**

Use canary deployment:

```bash
# Deploy to 10% of services
aws ecs update-service \
  --cluster prod-cluster \
  --service microservice-1 \
  --force-new-deployment

# Monitor for errors
aws logs tail /ecs/microservice-1 --follow

# Verify database connections still work
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=prod-primary \
  --start-time 2026-03-08T00:00:00Z \
  --end-time 2026-03-08T01:00:00Z \
  --period 60 \
  --statistics Average

# If successful: Scale to 50%→100%
# Monitor for 24 hours before declaring victory
```

**Step 4: Set Up Automatic Rotation Lambda (Week 3)**

```python
# Lambda function for RDS password rotation
import boto3
import pymysql

def lambda_handler(event, context):
    """
    Rotation Lambda: Create → Set → Test → Finish
    """
    
    secret_id = event['ClientRequestToken']
    step = event['Step']
    
    if step == 'create':
        # Generate new password
        new_password = generate_random_password()
        # Store as AWSPENDING (not yet active)
        store_secret_version(secret_id, new_password, stage='AWSPENDING')
    
    elif step == 'set':
        # Update RDS with new password
        conn = connect_to_rds(get_current_password())
        conn.execute(f"ALTER USER admin IDENTIFIED BY '{new_password}'")
        conn.commit()
        # At this point: Old password still active, new password works
    
    elif step == 'test':
        # Verify new password works
        test_conn = connect_to_rds(new_password)
        test_conn.execute("SELECT 1")
        test_conn.close()
        # New password validated
    
    elif step == 'finish':
        # Promote AWSPENDING → AWSCURRENT
        # Old password moves to AWSPREVIOUS
        promote_secret_version(secret_id, stage='AWSCURRENT')
    
    return {'statusCode': 200}
```

**Step 5: Monitor Rotation (Week 4+)**

```bash
# Check rotation history
aws secretsmanager describe-secret --secret-id prod/rds/master-password \
  --query 'VersionIdsToStages' \
  --output json

# Expected output after rotation:
{
  "version-1": ["AWSPREVIOUS"],     # Old (grace period)
  "version-2": ["AWSCURRENT"],      # New (active)
  "version-3": ["AWSPENDING"]       # Next (staging)
}

# Monitor successful rotations
aws cloudwatch get-metric-statistics \
  --namespace AWS/SecretsManager \
  --metric-name RotationSucceeded \
  --dimensions Name=SecretId,Value=prod/rds/master-password \
  --start-time 2026-02-01T00:00:00Z \
  --end-time 2026-03-08T00:00:00Z \
  --period 86400 \
  --statistics Sum

# Alert on rotation failures
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:123456789012:alerts \
  --subject "RDS Password Rotation Status" \
  --message "Monthly rotation completed successfully at $(date)"
```

**Best Practices Demonstrated:**

1. **Non-Disruptive Transition**: Applications cache credentials; rotation happens transparently
2. **Multi-Region Strategy**: Secrets replicated to prevent single-region failure
3. **Gradual Rollout**: Canary deployment catches issues before full rollout
4. **Idempotent Rotation**: Lambda can be re-run if it fails (safe to retry)
5. **Audit Trail**: All password changes logged to CloudTrail
6. **Compliance Evidence**: Automated rotation satisfies PCI-DSS requirement

**Outcome:**
- ✅ Zero downtime during rotation
- ✅ Credentials rotated quarterly automatically
- ✅ Old password available for 5 minutes (grace period for slow-connecting apps)
- ✅ Full audit trail (who rotated, when, evidence)
- ✅ PCI-DSS compliance achieved

---

### Scenario 2: Detecting and Responding to a Compromised EC2 Instance

**Problem Statement:**

Your security team discovers that:
- An EC2 instance was compromised 2 hours ago
- Attacker used the instance's IAM role to access S3 buckets
- 500 customer records were downloaded
- Currently unclear: How long has attacker had access? What else was accessed?

**Goal:**
Investigate the incident, determine scope of compromise, and respond automatically within minutes (not hours).

**Architecture Context:**

```
Compromise Timeline:

T=0:00   Attacker gains shell on EC2 instance
         └─ Exploits application vulnerability
         └─ No detection yet

T=0:30   Attacker explores AWS environment
         └─ Runs: aws s3 ls (lists buckets)
         └─ Runs: aws s3 cp s3://customer-data/records.csv /tmp/ (downloads data)
         └─ No alerts triggered

T=2:00   Security team discovers attack
         └─ From customer complaint about data exposure
         └─ FAR TOO LATE

Goal: Reduce detection time from 2 hours to 5 minutes
Method: GuardDuty + Security Hub + Automated Response
```

**Step-by-Step Investigation & Response:**

**Step 1: Immediate Containment (T=0:00 - Auto)**

GuardDuty detects unusual API calls from the instance:

```
GuardDuty Finding: "UnauthorizedAPI:IAMUser.ConsoleAccessMFADisabled"
  └─ Principal: EC2-instance-profile-role
  └─ API: ListBuckets (called 50 times in 2 minutes)
  └─ Confidence: 92%
  └─ Severity: 8 (HIGH)

EventBridge Rule (auto-trigger):
  IF severity >= 7 AND confidence >= 0.90:
    THEN run IncidentResponse Lambda

Lambda Execution:
  1. Get IAM role for principal
  2. Create deny-all policy
  3. Attach policy to role (blocks all APIs)
  4. Result: Attacker's API calls fail immediately
  5. Time to block: < 10 seconds
```

```python
# Auto-Response Lambda (simplified)
def lambda_handler(event, context):
    finding = event['detail']
    principal_arn = finding['resource']['accessKeyDetails']['principalId']
    role_name = principal_arn.split('/')[-1]
    
    # Create deny-all and append
    iam.put_role_policy(
        RoleName=role_name,
        PolicyName='emergency-deny-all',
        PolicyDocument=DENY_ALL_POLICY
    )
    
    # Snapshot the instance (forensics)
    instance_id = finding['resource']['instanceDetails']['instanceId']
    ec2.create_image(
        InstanceId=instance_id,
        Name=f'forensic-snapshot-{instance_id}-{datetime.now().timestamp()}'
    )
    
    # Notify on-call
    sns.publish(TopicArn=ALERT_TOPIC, Message=f"EC2 instance compromised: {instance_id}")
    
    return {'statusCode': 200, 'instance_stopped': True}
```

**Step 2: Forensic Investigation (T=0:05 - Human)**

```bash
# 1. Export CloudTrail logs for the compromised role
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=PrincipalId,AttributeValue="ARPA123456789012:EC2-instance" \
  --start-time 2026-03-08T00:00:00Z \
  --end-time 2026-03-08T02:00:00Z \
  --output json > /tmp/cloudtrail-events.json

# Parse to find first suspicious API call
jq '.Events[] | select(.EventName=="ListBuckets") | .EventTime' /tmp/cloudtrail-events.json | head -1

# Result: 2026-03-08T01:47:32Z (29 minutes after compromise detected)
# Conclusion: Attacker had access for at least 29 minutes
```

**Step 3: Determine Scope of Compromise**

```bash
# 2. Query S3 access logs to see what was downloaded
# S3 has logging enabled on customer-data bucket
aws s3api get-object-acl \
  --bucket customer-data \
  --key "access-logs/"

# Analyze logs using Athena
aws athena start-query-execution \
  --query-string "SELECT * FROM s3_access_logs WHERE requester LIKE '%EC2-instance%' AND request_date_time > '2026-03-08T01:45:00Z'"

# Result from logs:
# - 500 GetObject calls on customer records file
# - 0 DeleteObject calls (good - data wasn't deleted)
# - 0 PutObject calls (good - no malware uploaded)
# - Scope: Only customer records exposed, nothing else

# 3. Verify customer data integrity
# Check if attacker modified any records
aws s3api get-object \
  --bucket customer-data \
  --key records.csv \
  --version-id version-before-compromise /tmp/records-before.csv

aws s3api get-object \
  --bucket customer-data \
  --key records.csv \
  --version-id current /tmp/records-after.csv

diff /tmp/records-before.csv /tmp/records-after.csv
# No differences = attacker only read, didn't modify
```

**Step 4: Access Analyzer for Permission Review**

```bash
# 4. Verify what permissions the compromised role actually had
aws iam get-role-policy \
  --role-name EC2-instance-profile-role \
  --policy-name App-policy

# Check if role had more permissions than needed
aws accessanalyzer list-findings \
  --analyzer-arn "arn:aws:access-analyzer:us-east-1:123456789012:analyzer/default" \
  --filter 'resourceType=[{value=AWS::IAM::Role}]' \
  --query 'findings[?resourceId==`rn:aws:iam::123456789012:role/EC2-instance-profile-role`]'

# Finding: Role had s3:* on all buckets (over-privileged)
# Should have been: s3:GetObject only on prod-data bucket
# Lesson: Principle of least privilege not implemented
```

**Step 5: Incident Timeline Report**

```
INCIDENT TIMELINE: EC2 Compromise Investigation

T=01:47:32  First suspicious API (ListBuckets)
T=01:48:00  AttemptedS3 GetObject on customer-data
T=01:50:15  Downloaded 500 customer records
T=02:00:00  Customer reported data exposure
T=02:01:00  GuardDuty finding generated (53 min latency - too long!)
T=02:01:05  Lambda auto-response triggered; IAM role disabled
T=02:02:00  On-call engineer alerted
T=02:15:00  Investigation begins
T=02:45:00  Scope determined: 500 records, read-only
T=03:00:00  Root cause identified: over-privileged IAM role

IMPACT:
  - 500 customer records exposed
  - No data modified
  - No infrastructure compromised
  - Access blocked 12 minutes after detection

ROOT CAUSES:
  1. EC2 role had s3:* instead of minimal s3:GetObject
  2. GuardDuty latency 53 minutes (should be < 5 minutes)
  3. Application vulnerability not patched

REMEDIATION:
  1. Implement least-privilege role (remove s3:* wildcard)
  2. Enable GuardDuty with faster response (< 5 min SLA)
  3. Patch application vulnerability
  4. Require all external traffic through WAF
  5. Enable VPC Flow Logs for network-level visibility
```

**Best Practices Demonstrated:**

1. **Automated Containment**: Block attacker before manual investigation
2. **Multi-Layer Evidence**: CloudTrail + S3 logs + Access logs + Config snapshots
3. **Least Privilege Review**: Use Access Analyzer to prevent future issues
4. **Forensic Preservation**: Snapshot AMI immediately (immutable evidence)
5. **Timeline Analysis**: Determine exactly when compromise occurred

**Outcome:**
- ✅ Containment in < 1 minute (vs. hours manual)
- ✅ Scope determined: 500 records, read-only
- ✅ Root cause identified: Over-privileged IAM role
- ✅ Preventive measures implemented

---

### Scenario 3: Multi-Region Security Compliance Audit

**Problem Statement:**

Your organization operates in 5 AWS regions with:
- 3 production accounts
- 2 staging accounts
- Each region has different compliance requirements:
  - US (PCI-DSS required for payment processing)
  - EU (GDPR required)
  - APAC (Local data residency required)
- Compliance audit in 6 weeks
- Currently: No unified visibility across regions/accounts

**Challenge:**
Senior management requires: "Prove compliance with all standards across all regions."

Manual process would take weeks. Need automated compliance checking.

**Architecture Context:**

```
Current (Manual, Fragmented):
  Account 1 (US) ─┐
  Account 2 (EU) ─┤  Each has own Config rules
  Account 3 (APAC)┼  Compliance status unknown
  Account 4 (Staging)─┐
  Account 5 (Test)    └─ Completely unaudited

Desired (Automated, Unified):
  All Accounts → Security Hub (Aggregator) → Unified Dashboard
       ↓
  PCI-DSS compliance: 92% (1234 checks passing, 100 failing)
  GDPR compliance: 87% (2345 checks passing, 350 failing)
  Local requirement: 95% (500 checks passing, 25 failing)
```

**Step-by-Step Audit Implementation:**

**Step 1: Multi-Account Security Hub Setup (Week 1)**

```bash
# In security-account (aggregator):
aws securityhub enable-organization-admin-account \
  --admin-account-id 111111111111

# In each production account:
aws securityhub enable-security-hub \
  --region us-east-1
  --tags Environment=production

aws securityhub enable-security-hub \
  --region eu-west-1 \
  --tags Environment=production

# Register aggregator
aws securityhub create-security-hub-aggregator \
  --aggregator-name ProductionAggregator \
  --account-aggregation-sources '[{"AllAwsRegions":true,"AccountIds":["prod-account1","prod-account2","prod-account3"]}]'
```

**Step 2: Enable Compliance Standards (Week 1)**

```bash
# Determine which standards apply to each region

# US accounts: Enable PCI-DSS
aws securityhub enable-standards \
  --standards-subscription-requests StandardsArn="arn:aws:securityhub:us-east-1::standards/pci-dss/v/3.2.1"

# EU accounts: Enable GDPR
aws securityhub enable-standards \
  --standards-subscription-requests StandardsArn="arn:aws:securityhub:eu-west-1::standards/gdpr/v/1.0.0"

# All accounts: Enable CIS Benchmarks
aws securityhub enable-standards \
  --standards-subscription-requests StandardsArn="arn:aws:securityhub:region::standards/aws-foundational-security-best-practices/v/1.0.0"
```

**Step 3: Configure Automated Fixes via Config (Week 2)**

```hcl
# Terraform: Deploy Config rules with auto-remediation to all regions

resource "aws_config_remediation_configuration" "s3_encryption" {
  config_rule_name = "s3-bucket-server-side-encryption-enabled"
  
  automatic                = true
  maximum_automatic_attempts = 5
  automatic_attempts_before_manual = 3
  
  target_type       = "SSM_DOCUMENT"
  target_identifier = "AWS-PublishS3BucketEncryption"
}

resource "aws_config_remediation_configuration" "ec2_open_ssh" {
  config_rule_name = "restricted-common-ports"
  
  automatic = true
  target_type = "SSM_DOCUMENT"
  target_identifier = "AWS-RestrictSecurityGroupIngress"
}

# Result: Non-compliant resources automatically remediate
# Example: S3 bucket missing encryption → Auto-enable AES256
```

**Step 4: Generate Compliance Report (Week 5)**

```bash
# Query Security Hub for compliance status
aws securityhub get-compliance-summary \
  --region us-east-1 \
  --query 'ComplianceSummary' \
  --output json > compliance-summary.json

# Parse results
jq '.ComplianceByResourceType | to_entries | .[] | "\(.key): \(.value.CompliantCount)/\(.value.NonCompliantCount)"' compliance-summary.json

# Expected output:
# AWS::S3::Bucket: 450/12 (97% compliant)
# AWS::EC2::SecurityGroup: 120/8 (94% compliant)
# AWS::RDS::DBInstance: 25/2 (93% compliant)
# AWS::Lambda::Function: 200/15 (93% compliant)
# Overall: 95% PCI-DSS compliant

# Export detailed evidence for auditors
aws securityhub get-findings \
  --filters 'ComplianceStatus=[{Value=FAILED}]' \
  --output json > findings-failed-controls.json

# Generate executive summary
{
  echo "COMPLIANCE AUDIT REPORT - $(date)"
  echo "=================================="
  echo ""
  echo "PCI-DSS v3.2.1 Compliance Status:"
  echo "  PASSED: 1234 controls"
  echo "  FAILED: 100 controls (7.5%)"
  echo "  TOTAL: 95% compliant"
  echo ""
  echo "Top Non-Compliant Resources:"
  jq '.Findings[] | select(.ComplianceStatus=="FAILED") | "\(.ResourceId): \(.Title)"' findings-failed-controls.json | head -10
  echo ""
  echo "Remediation Actions Taken:"
  echo "  - Auto-fixed 45 S3 encryption issues"
  echo "  - Auto-fixed 12 security group overrides"
  echo "  - Manual review required for 43 findings"
} > audit-report.txt
```

**Step 5: Drill & Validation (Week 6)**

```bash
# Test: Introduce a non-compliant resource and verify detection

# Create non-compliant S3 bucket (unencrypted)
aws s3api create-bucket \
  --bucket test-non-compliant-bucket \
  --region us-east-1

# Verify Config detects it within 15 minutes
while true; do
  status=$(aws configservice describe-compliance-by-config-rule \
    --config-rule-names "s3-bucket-server-side-encryption-enabled" \
    --query "ComplianceByConfigRules[0].Compliance.ComplianceType" \
    --output text)
  
  if [ "$status" == "NON_COMPLIANT" ]; then
    echo "✓ Non-compliance detected!"
    break
  fi
  sleep 30
done

# Verify auto-remediation kicks in
aws s3api get-bucket-encryption \
  --bucket test-non-compliant-bucket > /dev/null

# If succeeds: Bucket was auto-encrypted
# If fails: 30+ second delay, but it will be encrypted shortly

# Cleanup test
aws s3 rm s3://test-non-compliant-bucket
```

**Best Practices Demonstrated:**

1. **Unified Visibility**: Single pane of glass across regions/accounts
2. **Automated Fixes**: Non-compliant resources auto-remediate
3. **Evidence Collection**: Full audit trail for compliance officers
4. **Compliance-as-Code**: Deploy rules via Infrastructure-as-Code
5. **Testing**: Validate detection and remediation before audit

**Outcome:**
- ✅ 95%+ compliance across all regions
- ✅ Automated fixes prevented manual work
- ✅ Audit completed in 6 weeks (vs. 3 months manual)
- ✅ Auditors provided complete evidence
- ✅ Audit PASSED with zero findings

---

## Interview Questions {#interview-questions}

### Question 1: Designing a Secure Multi-Account Architecture

**Interview Question:**

"Design a secure AWS multi-account architecture for a large organization with 5+ production accounts. How would you implement security hardening and compliance at scale? Walk me through your key decisions."

**Expected Senior-Level Answer:**

A senior DevOps engineer should discuss:

**Account Structure:**
```
Organization Root
├─ Security Account (dedicated, logs all activity)
│  ├─ CloudTrail central (immutable bucket)
│  ├─ Config aggregator (unified compliance)
│  ├─ Security Hub (incident coordination)
│  ├─ GuardDuty central (threat detection)
│  └─ VPC Flow Logs central archive
│
├─ Logging Account (long-term retention)
│  ├─ CloudWatch Logs aggregation
│  ├─ S3 for CloudTrail, Config, WAF logs
│  └─ Athena/Glue for analysis
│
├─ Prod-Account-1 (applications)
├─ Prod-Account-2 (applications)
├─ Prod-Account-3 (applications)
│
├─ Staging Account (pre-prod validation)
└─ Development Account (experimentation)
```

**Key Decisions & Reasoning:**

1. **Separate Security Account**
   - *Why*: Isolation prevents compromised application account from impacting security controls
   - *How*: Only security team has access; all accounts send findings to it
   - *Audit*: Auditors can trust central repository (not under application team control)

2. **Aggregated CloudTrail in Logging Account**
   - *Why*: Immutable audit trail prevents deletion by rogue admins
   - *How*: Enable CloudTrail in all accounts, route to central S3 bucket with:
     - `BlockPublicAccess` enabled
     - Versioning enabled
     - MFA delete enabled
   - *Benefit*: Long-term compliance evidence (7 years retention typical)

3. **GuardDuty + Security Hub Centralization**
   - *Why*: Single view across all accounts for threat detection
   - *How*: Designate security account as admin; findings auto-routed to it
   - *Automation*: EventBridge rules in security account trigger response
   - *Example*: If GuardDuty finds credential abuse in Prod-Account-1, auto-disable in that account from Security Account

4. **Config Rules with Auto-Remediation**
   - *Why*: Prevent security drift at source
   - *How*: Deploy Config rules to all accounts, aggregate compliance in Security Hub
   - *Example*: S3 bucket without encryption → Auto-enable within 30 seconds
   - *Audit*: Config timeline proves issue was detected and fixed automatically

5. **Cross-Account IAM Roles for Automation**
   - *Why*: Avoid hardcoding credentials; enable principle-based access
   - *Strategy*: Central Security account assumes role in each Prod account
     ```json
     // Trust policy in Prod-Account-1:
     {
       "Principal": {"AWS": "arn:aws:iam::security-account:role/SecurityAudit"},
       "Action": "sts:AssumeRole",
       "Effect": "Allow"
     }
     ```
   - *Benefit*: Audit trail shows exactly which principal made changes (implicit accountability)

6. **Network Isolation**
   - *How*: Each Prod account has isolated VPC; no customer data leaves network
   - *GuardDuty*: Monitor unusual outbound connections
   - *WAF*: Rate limit and geo-block at load balancer

**Common Follow-up Questions:**

Q: "But this adds complexity. Why not just one account?"
A: "Because credentials are like keys to a house. If someone steals the front door key, they should only access the living room, not the safe. Multiple accounts enforce that separation. At your scale (5+ teams, millions of customers), the complexity is prevented by having clear blast radius boundaries."

Q: "How do you handle production incidents that require cross-account access?"
A: "Pre-authorize specific incident response roles that can assume into prod accounts for limited time. Example:
```bash
aws sts assume-role \
  --role-arn arn:aws:iam::prod-account:role/IncidentResponse \
  --role-session-name incident-on-call \
  --duration-seconds 3600
```
This is logged to CloudTrail; security team reviews after incident. No standing access."

---

### Question 2: Incident Response at Scale

**Interview Question:**

"Walk me through how you'd detect and respond to a credential compromise affecting 50+ microservices in a production account. Your SLA is 5 minutes to containment, 15 minutes to determining scope."

**Expected Senior-Level Answer:**

**Detection (Automated, < 1 minute):**
- GuardDuty detects unusual API calls from external IP
- Finding published to EventBridge (confidence > 85%)
- SNS notification to on-call engineer
- Post-incident: "Why wasn't this detected automatically before GuardDuty?"

**Containment (< 5 minutes):**
```
T=0:00   GuardDuty Finding: UnauthorizedAPI.IAMUser.MaliciousIPCaller
         └─ Severity: 8.5, Confidence: 92%

T=0:05   Lambda auto-response:
         ├─ Extract principal: app-role
         ├─ Create emergency deny-all policy
         ├─ Attach to app-role (blocks all APIs)
         └─ Result: Attacker's API calls now fail

T=0:10   Notify on-call:
         ├─ SNS email
         ├─ Slack webhook
         ├─ PagerDuty page
         └─ Result: Manual verification begins
```

**Scope Determination (5-15 minutes):**

```python
# Which services were affected?
affected_services = query_cloudtrail(
    principal='app-role',
    time_range='last_2_hours',
    action_pattern=['Describe*', 'Get*', 'List*']
)

# What did attacker try to do?
dangerous_actions = [
    'DeleteDBInstance',  # No match
    'GetSecretValue',     # MATCHED - 500 calls
    's3:GetObject',       # MATCHED - 100 calls
    'DeleteSnapshot',     # No match
]

# Scope assessment:
scopes = {
    'databases_compromised': 0,     # No delete attempts
    'secrets_exposed': 500,          # GetSecretValue called 500x
    'data_exfiltrated': '100|MB',    # S3 objects downloaded
}

# Impact to services:
# Services that read secrets: All 50+ microservices potentially compromised
# Services that share same secrets: ALL affected (if attacker got the secret)
# Services with unique secrets: Only those whose secrets were accessed

# Query audit logs to identify which secrets were accessed
accessed_secrets = parse_cloudtrail_logs(
    event_name='GetSecretValue',
    time_range='attack_window'
)

# Result: 3 secrets accessed:
#   - prod/database/admin-password
#   - prod/api/datadog-key
#   - prod/auth/jwt-signing-key
```

**Remediation Timeline:**
```
T=15:00  Scope determined: 3 secrets compromised
         └─ 50+ microservices using at least 1 of these secrets

T=15:05  Initiate secret rotation:
         ├─ Database password rotated (5 min, RDS accepts both old+new)
         ├─ API key rotated via Datadog console (manual, 2 min)
         ├─ JWT key rotated (automatic, 30 seconds)
         └─ Result: Old secrets no longer valid

T=15:10  Monitor for errors:
         ├─ CloudWatch: Check application errors
         ├─ ALB: Check connection drops
         ├─ RDS: Check failed authentication
         └─ Result: A few transient errors, all cleared < 5min

T=20:00  Deploy fixes to prevent recurrence:
         ├─ Patch application vulnerability
         ├─ Deploy WAF rules to detect similar exploitation
         ├─ Enable VPC Flow Logs (was disabled)
         ├─ Restrict IAM role (was over-privileged)
         └─ Result: Future attacks prevented

T=24:00  Post-incident:
         ├─ Timeline analysis (detect to remediate: 20 min)
         ├─ Root cause (unpatched web app vulnerability)
         ├─ Prevent measures (patch, WAF, Flow Logs)
         └─ Updated runbook for next incident
```

**Key Points a Senior Would Make:**

1. **Automation is Critical**: Without Lambda auto-response, manual investigation takes 1-2 hours before containment
2. **Multi-Layer Response**: Can't just fix the IAM role; must also rotate secrets and investigate scope
3. **Non-Breaking Rotation**: Grace period (AWSPREVIOUS) prevents service disruption during secret rotation
4. **Audit Trail**: Every action logged to CloudTrail; can reconstruct exactly what attacker did
5. **Drills Matter**: The team that responds best has rehearsed this quarterly

---

### Question 3: Secrets Management and Rotation

**Interview Question:**

"You're migrating 200 hardcoded credentials (in config files, environment variables, Docker images) to Secrets Manager with automatic rotation. What's your strategy to avoid downtime?"

**Expected Senior-Level Answer:**

**Phase 1: Parallel Operation (1-2 weeks)**
- Deploy code to read from Secrets Manager
- Cache credentials in-memory (TTL: 5 min)
- Run alongside old hardcoded credentials
- No rotation yet (just retrieval)
- **Benefit**: Can rollback if issues

**Phase 2: Gradual Rotation (2-4 weeks)**
- Start with non-critical services (dev, staging)
- Enable automatic rotation (every 30 days)
- Monitor for errors; adjust runbooks
- Gradually move to production services
- **Testing**: Kill Lambda during rotation, verify auto-retry works

**Phase 3: Rotation Verification**
```python
# Test: Rotate credential mid-request
1. Application makes DB connection with password_v1
2. Rotation triggered (password_v1 → password_v2)
3. Mid-request, connection still using password_v1 (should work)
   └─ Database accepts both versions during grace period

4. New connections use password_v2 (fresh password from Secrets Manager)

Expected: 0% downtime
Actual: Measure via:
  - CloudWatch: HTTP error rate during rotation
  - RDS: Connection drops
  - Application logs: Authentication failures
```

**Common Pitfalls to Avoid:**

1. **Pitfall**: Rotate password before application is updated
   - *Solution*: Ensure rotation Lambda only runs after code-deploy success
   
2. **Pitfall**: Rotation Lambda doesn't verify new password on target system
   - *Solution*: TestSecret step must successfully connect with new credential
   
3. **Pitfall**: No grace period for connections using old password
   - *Solution*: Keep AWSPREVIOUS for 5 minutes; database accepts both

**Cost-Benefit Analysis:**
```
Secrets Manager Cost: $0.40/secret/month × 200 = $80/month = $960/year
Rotation Lambda Cost: $0.20/execution × 200 secrets × 12 rotations/year = $480/year
Total: ~$1,440/year

Benefit: Credential compromise blast radius reduced from "months" to "30 days"
If single breach prevented: Savings = $1M+ (incident response, notification, reputation)
ROI: Massive (1000x return)
```

---

### Question 4: KMS Key Management at Scale

**Interview Question:**

"You manage 50+ AWS accounts across 3 regions. Should you use a single customer-managed KMS key for all encryption, or separate keys per account/region? Trade-offs?"

**Expected Senior-Level Answer:**

**Option A: Single Global Key (Anti-Pattern)**
```
Pros:
  - Simpler to manage
  - Single audit trail

Cons:
  - Single point of failure (key deleted = all data unrecoverable)
  - No separation of duties (finance team can decrypt HR secrets)
  - Security: AWS calls this "monolithic key strategy"
  - Compliance: Auditors hate this (PCI-DSS requires isolation)
  - Scaling: Excessive throttling (KMS has per-key rate limits)
```

**Option B: Separate Key Per Account (Best Practice)**
```
Prod-Account-1 KMS Key (manages all encryption for Account 1)
Prod-Account-2 KMS Key (separate, isolated)
Prod-Account-3 KMS Key (separate, isolated)

Pros:
  - Account isolation (compromised Account 1 ≠ compromise Account 2)
  - Separate audit trails (easier to audit compliance)
  - Team isolation (prod finance team manages prod key; doesn't affect staging)
  - Compliance: Meets PCI-DSS Requirement 3.6 (key segregation)

Cons:
  - More operational overhead
  - More policy management (but: Infrastructure-as-Code solves this)
```

**Option C: Separate Key Per Data Classification (Production Best Practice)**
```
Prod-Account-1 KMS Key (customer data, highest security)
Prod-Account-1 Logs KMS Key (CloudWatch/S3 logs, moderate security)
Prod-Account-1 Backup KMS Key (long-term retention, can be shared with Logging Account)

Advantage: Each key has policies reflecting allowed actions
  - Customer data key: Only app services + audit
  - Logs key: Broader access (logging aggregation needs read access)
  - Backup key: Can be shared for disaster recovery
```

**Recommendation (What a Senior Would Design):**

```
Architecture:
  ├─ Prod accounts (3): Each has 2-3 keys
  │  ├─ Primary: Encrypt customer data at rest
  │  ├─ Logs: Encrypt CloudWatch/S3 logs
  │  └─ Backup: Encrypt RDS snapshots (can be cross-account)
  │
  ├─ Staging: 1 key per region (less sensitive)
  │
  └─ Logging Account: 1 key for all log decryption
     └─ Prod account keys' policies trust this key for cross-account access

Total: ~15 keys across all accounts
Cost: $30/month per key × 15 = $450/month (vs. $40 single key, but with massive security benefit)

Automation:
  - Deploy via Terraform (templated, consistent, versioned)
  - Key rotation: Automatic (annual) + manual (quarterly) for sensitivity
  - Audit: Separate audit trail per key; aggregated in Security Hub
  - Access: Principle of least privilege (API only; no console access)
```

**Key Rotation Strategy:**
- Automatic annual rotation (AWS default)
- Manual quarterly rotation for Customer Data key (Requirement 3.6.5 PCI-DSS)
- No rotation needed for backup keys (one-time encryption)

---

### Question 5: WAF Rules and False Positives

**Interview Question:**

"You deployed a WAF with AWS Managed Rules in COUNT mode to monitor traffic. After 1 week, you have 10,000 blocked requests. How do you determine which rules are false positives vs. actual attacks?"

**Expected Senior-Level Answer:**

**Analysis Method:**

```
Step 1: Categorize by Rule Type
aws wafv2 get-sampled-requests \
  --web-acl-arn <acl-arn> \
  --rule-metric-name <rule-name> \
  --scope REGIONAL \
  --query 'SampledRequests[*].[Request.URI,Request.Headers,TerminatingRuleId]'

# Result: 10,000 blocked requests across:
# - Rule 1 (CoreRuleSet): 7,000 requests
# - Rule 2 (Rate Limiting): 2,000 requests
# - Rule 3 (Bot Detection): 1,000 requests
```

**Step 2: Sample and Analyze**

```
Rule 1: CoreRuleSet (7,000 blocks)
  Sample 100 random requests
  Analyze for false positives:
    - Legitimate API calls with unusual patterns → False positive
    - Actual SQLi/XSS patterns → True positive
  
  Example false positive:
    Request: GET /search?q=select%20top%20100%20products
    Reason: "select" keyword triggers SQLi rule
    Reality: Legitimate search query (not SQL)
    Solution: Exclude /search endpoint from SQLi rule
  
  Example true positive:
    Request: GET /api/users?id=1%20UNION%20SELECT%20password%20FROM%20users
    Reason: UNION SELECT pattern
    Reality: Actual SQLi attack
    Solution: Block (no change to rule)

  Assessment: 5% false positive rate (500/10,000)
  Action: Update rule scope to exclude /search, /products, other common endpoints
```

**Step 3: Implement Rule Overrides**

```hcl
# Terraform: Exclude known false-positive endpoints from SQLi rule

resource "aws_wafv2_web_acl" "adjusted" {
  name  = "api-waf-adjusted"
  scope = "REGIONAL"
  
  rules {
    name     = "CoreRuleSetAdjusted"
    priority = 0
    
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
        
        # Exclude specific rules that cause false positives
        rule_action_override {
          action_to_use {
            block {}
          }
          name = "GenericRFI_BODY"  # Rule that's overly broad
        }
        
        # Exclude specific paths from ALL rules
        scope_down_statement {
          not_statement {
            statement {
              byte_match_statement {
                search_string = "/search"
                field_to_match {
                  uri_path {}
                }
                text_transformation = [NONE]
                positional_constraint = STARTS_WITH
              }
            }
          }
        }
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "CoreRuleSetAdjustedMetric"
      sampled_requests_enabled = true
    }
  }
}
```

**Step 4: Monitor and Verify**

```bash
# After adjustment, monitor for 1 week
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=Rule,Value=CoreRuleSetAdjusted \
  --start-time 2026-03-08T00:00:00Z \
  --end-time 2026-03-15T00:00:00Z \
  --period 86400 \
  --statistics Sum

# Expected: Blocked requests drop from 7,000/day to ~200/day
# (remaining are actual attacks)
```

**Key Decision Points:**

1. **False Positive Tolerance**: Different industries accept different rates
   - E-commerce: < 1% (annoyed customers)
   - Enterprise APIs: Can tolerate 5% (customers accept challenge/CAPTCHA)
   - Banking: Must be < 0.1% (regulatory requirement)

2. **False Positive Cost vs Benefit**:
   - False negative (let attack through): $1M+ breach
   - False positive (block legitimate user): $0 immediate cost, but reputation damage
   - WAF works by:
     - High-confidence blocks: Actual attacks
     - Medium-confidence: CHALLENGE (CAPTCHA)
     - Low-confidence: LOG ONLY (no block)

3. **Rule Tuning vs Upgrading**:
   - If > 5% false positives: Tune existing rules
   - If performance issues: Consider AWS Bot Control (paid, more accurate)
   - If application-specific: Write custom rules (require regex expertise)

**Outcome:**
- False positive rate reduced from 100% to 5% over 1 week
- Actual attacks still blocked (100% accuracy)
- Rules now trust worthy; can switch from COUNT to BLOCK

---

### Question 6: Compliance Drift Detection and Remediation

**Interview Question:**

"A developer accidentally disables encryption on an RDS database in production (manually, via console). Your monitoring detects it 5 minutes later. Walk me through detection → remediation → audit."

**Expected Senior-Level Answer:**

**Detection (T=0:05):**

```
AWS Config Rule: "rds-encryption-enabled"
  └─ Continuously evaluates all RDS instances
  └─ Detects: Instance encryption disabled
  └─ Severity: CRITICAL
  └─ Time to detection: < 5 minutes
```

**Remediation (T=0:10):**

```
Config Rule triggers auto-remediation Lambda:
  1. Get current RDS instance state
  2. Create snapshot (backup before applying fix)
  3. Modify RDS instance: enable-iam-database-authentication + encryption
  4. Execute: aws rds modify-db-instance --db-instance-identifier prod-db \
       --storage-encrypted --apply-immediately
  5. Monitor: Wait for modification complete (~2 minutes)
  6. Verify: Encryption now enabled
  
  Time to remediate: < 2 minutes
  
Result:
  - RDS instance now encrypted with default AWS key
  - Config rule status: COMPLIANT (changed from NON_COMPLIANT)
  - Data was encrypted for 5 minutes (drift window)
```

**Audit Trail (Complete record of what happened):**

```
1. Who changed it?
   CloudTrail Log:
   {
     "eventName": "ModifyDBInstance",
     "userIdentity": {
       "principalId": "AIDACKCEVSQ6C2EXAMPLE",
       "userName": "john.doe"
     },
     "sourceIPAddress": "203.0.113.45",
     "eventTime": "2026-03-08T10:00:00Z",
     "requestParameters": {
       "dBInstanceIdentifier": "prod-db",
       "storageEncrypted": false  ← Disabling encryption
     }
   }

2. When did Config detect it?
   {
     "ConfigRuleInvokingEvent": "2026-03-08T10:05:00Z",
     "configRuleCompliance": {
       "configRuleName": "rds-encryption-enabled",
       "compliance": {
         "complianceType": "NON_COMPLIANT"
       }
     }
   }

3. How was it fixed?
   Config Remediation:
   {
     "remediationExecutionId": "remediation-abc123",
     "eventTime": "2026-03-08T10:07:00Z",
     "action": "ApplyRemediationConfiguration",
     "targetParameters": {
       "dBInstanceIdentifier": "prod-db",
       "storageEncrypted": true  ← Re-enabling encryption
     },
     "status": "SUCCEDED"
   }

4. What was the impact?
   Timeline:
   - 10:00:00: Encryption disabled (5 minutes of drift)
   - 10:05:00: Config detected issue
   - 10:07:00: Auto-remediation applied
   - 10:09:00: RDS modification complete, encrypted again
```

**Audit Conclusion:**

```
Evidence Summary for Auditors:
─────────────────────────────

Non-Compliance Window: 10:00:00 - 10:09:00 (9 minutes)
Root Cause: Manual configuration change (user error)
Compensating Control: AWS Config auto-remediation
Data Protection: Failure rate = 0 minutes
  - RDS data was encrypted during drift window
  - User error didn't result in actual exposure

Lessons Learned:
  1. Require change approval before production changes
  2. Enable AWS Config to prevent manual changes
  3. Train developers on proper change procedures

Auditor Finding: "Compensating control effective"
  - Issue detected and remediated automatically
  - Full audit trail available
  - No data exposure occurred
  - Compliance demonstrated
```

**What Prevents This Future Occurrence:**

```
1. Remove console access
   └─ Via SCP: Deny rds:ModifyDBInstance from AWS Console

2. Require Infrastructure-as-Code for changes
   └─ All RDS changes via Terraform pull requests (peer review)

3. Deploy immutable Config rule
   └─ aws-config-rule marks RDS encryption as immutable
   └─ Can't be disabled (requires Terraform change)

4. Monitor for manual changes
   └─ CloudTrail → EventBridge → Lambda
   └─ If manual change detected: Notify security team
   └─ Auto-remediate + alert
```

---

### Question 7: GuardDuty Alert Fatigue vs. Detection

**Interview Question:**

"Your GuardDuty is generating 200+ findings per day, but 90% are false positives (developers running stress tests, backup jobs making unusual API calls). How do you reduce noise while maintaining security?"

**Expected Senior-Level Answer:**

**Problem Analysis:**

```
Current State: 200 findings/day
- 180 false positives (developer activity)
- 20 true positives (actual threats)

Cost: 
  - Engineer time reviewing: 4 hours/day × $100/hr = $400/day
  - Alert fatigue: Reduces team vigilance
  - Risk: Team ignores alerts (missed real threats)
```

**Solution: Suppress False Positives Intelligently**

```
Strategy 1: Suppress by Context (Not by Rule Type)

AWS GuardDuty Suppression Rules:
{
  "RuleArn": "arn:aws:guardduty:region:account:detector/detector-id",
  "FindingSuppressed": {
    "FindingType": "UnauthorizedAPI:EC2.SpotInstanceLaunch"
    "ResourceType": "Instance",
    "InstanceTags": [
      {"Key": "Purpose", "Value": "load-testing"}
    ]
  }
}

Result: Load-testing instances can launch spot instances without alerting
✓ Legitimate use case allowed
✓ Real attack still detected if from non-load-testing instance
```

**Strategy 2: Suppress by Timeframe**

```
{
  "FindingSuppressed": {
    "FindingType": "CryptoCurrency:EC2.BitcoinTool.A",
    "TimeRange": {
      "StartDate": "2026-03-08T02:00:00Z",
      "EndDate": "2026-03-08T06:00:00Z"
    },
    "Reason": "Scheduled blockchain validation job (prod-validate-1)"
  }
}

Result: Blockchain node using CPU = suppressed 2-6 AM (maintenance window)
✓ Known legitimate activity suppressed during window
✓ Activity outside window still detected
```

**Strategy 3: Suppress by Principal + Action**

```
{
  "FindingSuppressed": {
    "FindingType": "UnauthorizedAPI:IAMUser.AnomalousAPICall",
    "Principal": "arn:aws:iam::account:role/backup-orchestration",
    "Action": "DescribeInstances, ListSnapshots, CopySnapshot"
  }
}

Result: Backup job can enumerate resources without alerting
✓ Legitimate use case allowed
✓ Same role making *different* API calls still alerts
```

**Strategy 4: Use Confidence Thresholds**

```python
# Instead of suppressing findings, just change alerting threshold

if finding['confidence'] >= 0.85:  # High confidence
    alert_security_team()  # SMS, call, page
    auto_remediate()

elif finding['confidence'] >= 0.70:  # Medium confidence
    alert_to_slack()  # Async notification
    log_for_audit()

else:  # Low confidence
    log_only()  # Store but don't alert
    # Review weekly in audit
```

**Result:**
- High-confidence findings: Immediate action
- Medium-confidence findings: Reviewed daily
- Low-confidence findings: Reviewed weekly (90% are false positives)

**Evaluation: Did We Solve the Problem?**

```
Implementation Timeline:

Week 1: Deploy suppression rules for known benign activities
  └─ Findings drop: 200 → 150/day
  └─ False positives: 90% → 70%

Week 2: Add confidence-based alerting
  └─ Findings: Still 150/day, but only 20/day alert team
  └─ False positives requiring action: 90% → 5%

Week 3-4: Adjust thresholds based on missed attacks
  └─ If real attack missed: Lower confidence threshold
  └─ If false positive increased: Raise threshold

End State:
  └─ 150 findings/day (logged)
  └─ 20 alerts/day (team reviews)
  └─ Alert fatigue eliminated
  └─ Security maintained (0 real attacks missed)
```

**Key Principle:**
"Don't suppress findings; suppress alerts. Findings should be comprehensive (for auditing). Alerts should be selective (for action)."

---

### Question 8: Least Privilege Role Design

**Interview Question:**

"Design an IAM role for an ECS task that needs to: read secrets from Secrets Manager, write logs to CloudWatch, read environment config from S3, and send metrics to CloudWatch. How do you ensure least privilege?"

**Expected Senior-Level Answer:**

**Anti-Pattern (Too Broad):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",  // ← Too permissive
      "Resource": "*"
    }
  ]
}
```

**Correct Pattern (Least Privilege):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:region:account:secret:app/production/*",
      "Condition": {
        "StringEquals": {
          "secretsmanager:VersionStage": "AWSCURRENT"
        }
      }
    },
    
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:region:account:log-group:/ecs/app:*"
    },
    
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::app-config-bucket/prod/*"
    },
    
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "cloudwatch:namespace": "app/production"
        }
      }
    },
    
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:region:account:key/app-key-id"
    }
  ]
}
```

**Why Each Decision:**

| Action | Why | Restricted How |
|--------|-----|-----------------|
| `GetSecretValue` | Must read secrets | Only `prod/*` secrets; only `AWSCURRENT` version |
| `DescribeSecret` | Needed to get secret metadata | Same resource ARN as GetSecretValue |
| `CreateLogStream` | ECS task creates its own log stream | Only to specific log group (`/ecs/app`) |
| `PutLogEvents` | Task writes logs | Only to existing log streams (can't write to other apps' logs) |
| `GetObject` | Read config | Only from `prod/` prefix (can't read `staging/` or `dev/`) |
| `PutMetricData` | Send metrics | Only to `app/production` namespace (can't pollute other namespaces) |
| `Decrypt` + `DescribeKey` | Decrypt secrets encrypted with KMS | Specific key ARN (not all keys) |

**Testing the Role (Verification):**

```bash
# Test 1: Can task read its own secret?
aws sts assume-role --role-arn <task-role-arn> --role-session-name test
aws secretsmanager get-secret-value --secret-id app/production/database-password
# ✓ SUCCESS

# Test 2: Can task read other app's secret? (Should fail)
aws secretsmanager get-secret-value --secret-id app/staging/database-password
# ✗ AccessDeniedException (as expected)

# Test 3: Can task read old secret version? (Should fail)
aws secretsmanager get-secret-value \
  --secret-id app/production/database-password \
  --version-stage AWSPREVIOUS
# ✗ AccessDeniedException (as expected)

# Test 4: Can task delete logs? (Should fail)
aws logs delete-log-group --log-group-name /ecs/app
# ✗ AccessDeniedException (as expected)

# Test 5: Can task create logs in other app? (Should fail)
aws logs create-log-stream --log-group-name /ecs/other-app
# ✗ AccessDeniedException (as expected)
```

**Using Access Advisor to Refine Further:**

```bash
# After 1 month in production:
aws iam get-role-policy --role-name app-task-role

# Check which actions are actually used
aws accessanalyzer validate-policy --policy-document file://role-policy.json

# Finding: Task never calls DescribeSecret
# Action: Remove DescribeSecret from policy (reduce surface)

# Finding task never uses specific S3 bucket (staging/prod-backup)
# Action: Remove that resource ARN
```

---

### Question 9: Compliance Evidence and Auditor Trust

**Interview Question:**

"An external auditor is reviewing your PCI-DSS controls. They ask: 'Prove to me that all database access is logged and that you detect unauthorized access attempts.' How do you demonstrate this?"

**Expected Senior-Level Answer:**

**Evidence Presentation (What auditors want to see):**

**1. Evidence of Configuration (Controls in place):**
```bash
# Show that logging is ENABLED (not just policy)
aws rds describe-db-instances --db-instance-identifier prod-db-primary \
  --query 'DBInstances[0].EnableCloudwatchLogsExports'

# Result: ['postgresql'] ← Logs enabled

aws rds describe-db-cluster-parameters \
  --db-cluster-parameter-group-name prod-parameters \
  --query 'Parameters[?ParameterName==`log_statement`]'

# Result: ParameterValue: 'all' ← All statements logged
```

**2. Evidence of Detection (Findings in place):**
```bash
# Show GuardDuty is enabled and finding unauthorized access
aws guardduty get-detector --detector-id <detector-id> \
  --query 'FindingPublishingFrequency'

# Result: 'FIFTEEN_MINUTES' ← Actively detecting

# Show recent examples of detected unauthorized access
aws guardduty list-findings --detector-id <detector-id> \
  --finding-criteria 'Criterion={type={Equals=[UnauthorizedAPI.IAMUser.ConsoleAccessMFADisabled]}}' \
  --max-results 5

# Result: [finding-id-1, finding-id-2, ...] ← Examples of detections
```

**3. Evidence of Response (Incidents remediated):**
```bash
# Show example incident: detected and remediated
incident_id = "INCIDENT-2026-02-15"

# CloudTrail: Original unauthorized API call
aws cloudtrail lookup-events --lookup-attributes \
  AttributeKey=EventId,AttributeValue=$incident_id

# Config: Policy was non-compliant, auto-fixed
aws configservice describe-compliance-by-config-rule \
  --config-rule-names iam-policy-no-statements-with-admin-access

# Lambda logs: Remediation action executed
aws logs read-log-events --log-group-name /aws/lambda/incident-response

# All: Proves detect → contain → remediate workflow
```

**4. Evidence of Audit Trail:**
```bash
# Auditor asks: "Show me database access for [user] during [date range]"

# Query CloudTrail for database activities
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=PrincipalId,AttributeValue=[user-id] \
  --start-time 2026-02-01T00:00:00Z \
  --end-time 2026-02-28T23:59:59Z \
  --query 'Events[*].[EventTime,EventName,SourceIPAddress,ErrorCode]' \
  --output table

# Result:
# 2026-02-15 10:30:00  | RDSDBCluster:DescribeDBClusters  | 10.0.1.45  | -
# 2026-02-15 10:31:00  | RDSDBCluster:ModifyDBCluster     | 10.0.1.45  | -
# 2026-02-15 10:35:00  | RDSDBCluster:DeleteDBCluster     | 10.0.1.45  | UnauthorizedOperation

# Query database logs for same timeframe
aws logs start-query \
  --log-group-name /aws/rds/instance/prod-db/postgresql \
  --start-time 1612137600 \
  --end-time 1614556800 \
  --query-string 'fields @timestamp, user, query, rows | filter user = "postgres"'

# Result: Access log showing who connected, when, what queries
```

**5. Evidence of Compliance Maintenance:**
```bash
# Show continuous monitoring (not point-in-time)
aws config describe-compliance-by-config-rule \
  --query 'ComplianceByConfigRules[?ConfigRuleName==`rds-encryption-enabled`].[Compliance.ComplianceType]

# Timeline: 
# - Feb: PASSED (10 instances)
# - Mar: FAILED (1 instance - developer error)
# - Auto-remediated: Yes
# - Current: PASSED (10 instances)

# Auditor sees: Continuous monitoring detected, responded to drift
```

**Key Principle for Auditors:**
```
Auditors want to answer:
  1. Are controls configured? ← Configuration evidence
  2. Are controls active? ← Recent findings/alerts
  3. Do controls catch bad actors? ← Incident examples
  4. Is there an audit trail? ← CloudTrail + logs
  5. Are deviations handled? ← Auto-remediation examples

Don't just say "we have GuardDuty"
Instead: "Here are 5 incidents GuardDuty detected in [timeframe], 
          here's how we responded to each, and here's the audit trail"

Results: Auditor confidence = HIGH → Compliance finding = PASSED
```

---

### Question 10: Strategic Security Decisions

**Interview Question:**

"You're designing security architecture for a new org from scratch. $5M budget over 5 years. You must choose: (A) Hire large security team + basic tooling, or (B) Minimal security team + advanced automation. Which and why?"

**Expected Senior-Level Answer:**

**Analysis:**

**Option A: Large Security Team + Basic Tooling**
```
Year 1 spend:
  ├─ Salaries: 5-person security team = $500K
  ├─ Tools: CloudTrail, basic Config = $50K
  └─ Infrastructure: Manual operations = $50K
  Total Year 1: $600K

Challenges:
  - 5 people cannot 24/7 monitor 200+ accounts
  - Manual investigation takes days (real attack: minutes)
  - Team burnout (alert fatigue; on-call)
  - Scaling: Need 10+ people for 10 regions

Reality: $5M = 8 people over 5 years (can't scale)
```

**Option B: Minimal Team + Advanced Automation**
```
Year 1 spend:
  ├─ Salaries: 2 senior engineers = $200K
  ├─ Tools: GuardDuty, Security Hub, Automation = $200K
  ├─ Infrastructure: CI/CD, Lambda functions = $100K
  └─ Training: Security upskilling = $50K
  Total Year 1: $550K

Advantages:
  - 2 engineers + automation = effectively 20 engineers
  - Detection in < 5 minutes (automatic)
  - Remediation in < 5 minutes (automatic)
  - Scales: Same cost for 10 regions
  - Team health: Focused work, not burnout

Reality: $5M = compound security investment (tooling enables more capability)
```

**My Recommendation:**
```
Go with Option B (Automation), for these reasons:

1. SCALING ECONOMICS
   ├─ Automation scales; hiring doesn't
   ├─ 2 engineers + automation > 8 engineers manual
   └─ Can grow to 500 accounts with same team

2. INCIDENT RESPONSE TIME SLA
   ├─ Manual: 2-4 hours (human decision loop)
   ├─ Automated: < 5 minutes (Lambda + EventBridge)
   ├─ Compliance: Fastest responders win audit
   └─ Business: Faster response = less damage

3. HUMAN LIMITS
   ├─ Manual team: 200 alerts/day → alert fatigue
   ├─ Automated: Filter to top 20 alerts → focus
   ├─ Job satisfaction: Solving problems vs. firefighting
   └─ Retention: Good engineers leave burnout teams

4. COMPLIANCE ADVANTAGE
   ├─ Automation = reproducible controls
   ├─ Automation = full audit trail
   ├─ Manual = human error, inconsistency
   └─ Auditor trust: "Your controls are consistent"
```

**Implementation Plan (5-year strategy):**

```
Year 1: Foundation ($600K)
  ├─ Hire 2 senior security/DevOps engineers
  ├─ Deploy GuardDuty, Security Hub, Config across all accounts
  ├─ Set up CloudTrail central logging
  ├─ Build incident response automation (Lambda + Step Functions)
  └─ Result: Basic security posture + automation foundation

Year 2: Integration ($800K)
  ├─ Integrate all tools (SIEM handoff)
  ├─ Build compliance automation (Config rules + AWS Audit Manager)
  ├─ Implement secrets rotation (Secrets Manager)
  ├─ Add WAF + Shield to production
  └─ Result: Compliance-ready infrastructure

Year 3: Scaling ($1M)
  ├─ Expand to new regions (same team)
  ├─ Implement advanced threat detection (machine learning tuning)
  ├─ Build custom detections (business logic)
  ├─ Hire 1 more engineer (team is now 3)
  └─ Result: Operating 10+ regions; full compliance

Year 4+: Optimization ($1.5M/year)
  ├─ Continuous improvement (reduce false positives, add detections)
  ├─ Threat hunting (proactive investigations)
  ├─ Security training program (developers)
  ├─ Hiring specialized roles (security architect, compliance officer)
  └─ Result: Industry-leading security posture

Business Impact:
  Year 1: Compliance baseline achieved
  Year 2: Audit passed (first time, no findings)
  Year 3: Competitors ask "how are you so secure?"
  Year 4: Security becomes competitive advantage
  Year 5: $5M investment prevented $100M+ in breach costs
```

---

## Conclusion

This comprehensive study guide covers the complete spectrum of AWS security hardening and compliance for senior DevOps engineers operating at scale. Key takeaways:

**Technical Mastery:** Understand not just *how* tools work, but *why* they exist and when to use them.

**Operational Excellence:** Security is not a project; it's an ops discipline requiring automation, monitoring, and continuous improvement.

**Business Acumen:** Security investments have ROI. Frame them as risk mitigation, not cost.

**Compliance as Enabler:** Compliance requirements drive architecture decisions (good ones, usually).

**Automation is Non-Negotiable:** Manual security doesn't scale. Invest heavily in automation at the start.

As a final thought from experienced practitioners: The best security is the one nobody notices because everything is working as intended. Use the patterns, principles, and practices in this guide to build that invisible security posture.

---

**Study Guide Complete: 5,600+ lines, 150+ code examples, 50+ diagrams, 10+ interview questions**

Good luck with your DevOps and security growth journey.



