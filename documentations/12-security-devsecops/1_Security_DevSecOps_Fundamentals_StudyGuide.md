# Security & DevSecOps: Comprehensive Study Guide

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Security in DevSecOps](#overview-of-security-in-devsecops)
   - [Why Security Matters in Modern DevOps Platforms](#why-security-matters-in-modern-devops-platforms)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Where Security Appears in Cloud Architecture](#where-security-appears-in-cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Security Principles](#important-devops-security-principles)
   - [Best Practices Overview](#best-practices-overview)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Security Fundamentals](#security-fundamentals)
   - [Core Security Principles](#core-security-principles)
   - [CIA Triad](#cia-triad)
   - [Threat Modeling](#threat-modeling)
   - [Risk Assessment](#risk-assessment)
   - [Attack Surface Analysis](#attack-surface-analysis)
   - [Security Controls Framework](#security-controls-framework)
   - [Zero Trust Architecture](#zero-trust-architecture)
   - [Best Practices for Security in DevOps](#best-practices-for-security-in-devops)
   - [Common Pitfalls and Prevention Strategies](#common-pitfalls-and-prevention-strategies)

4. [Linux & System Hardening](#linux--system-hardening)
   - [Operating System Hardening Overview](#operating-system-hardening-overview)
   - [Kernel Hardening Techniques](#kernel-hardening-techniques)
   - [File System Permissions and Ownership](#file-system-permissions-and-ownership)
   - [SELinux and AppArmor Basics](#selinux-and-apparmor-basics)
   - [SSH Hardening](#ssh-hardening)
   - [Secure System Configurations](#secure-system-configurations)
   - [Best Practices for Linux Hardening in DevOps](#best-practices-for-linux-hardening-in-devops)
   - [Common Pitfalls in Linux Hardening](#common-pitfalls-in-linux-hardening)

5. [Identity & Access Management](#identity--access-management)
   - [IAM Principles and Architecture](#iam-principles-and-architecture)
   - [Role-Based Access Control (RBAC)](#role-based-access-control-rbac)
   - [Least Privilege Principle](#least-privilege-principle)
   - [Service Accounts and Managed Identities](#service-accounts-and-managed-identities)
   - [Federated Identity](#federated-identity)
   - [Multi-Factor Authentication (MFA)](#multi-factor-authentication-mfa)
   - [Best Practices for IAM in DevOps](#best-practices-for-iam-in-devops)
   - [Common IAM Pitfalls](#common-iam-pitfalls)

6. [Secrets Management](#secrets-management)
   - [Secrets Management Fundamentals](#secrets-management-fundamentals)
   - [Vault Solutions (HashiCorp Vault, Azure Key Vault, AWS Secrets Manager)](#vault-solutions)
   - [Key Management Services (KMS)](#key-management-services-kms)
   - [Secret Rotation Strategies](#secret-rotation-strategies)
   - [Runtime Injection Patterns](#runtime-injection-patterns)
   - [Best Practices for Secrets Management in DevOps](#best-practices-for-secrets-management-in-devops)
   - [Common Secrets Management Pitfalls](#common-secrets-management-pitfalls)

7. [Network Security Fundamentals](#network-security-fundamentals)
   - [Network Security Principles](#network-security-principles)
   - [Network Segmentation](#network-segmentation)
   - [Firewalls and Security Groups](#firewalls-and-security-groups)
   - [Intrusion Detection and Prevention Systems](#intrusion-detection-and-prevention-systems)
   - [DDoS Protection](#ddos-protection)
   - [Best Practices for Network Security in DevOps](#best-practices-for-network-security-in-devops)
   - [Common Network Security Pitfalls](#common-network-security-pitfalls)

8. [Secure Software Supply Chain](#secure-software-supply-chain)
   - [Supply Chain Security Overview](#supply-chain-security-overview)
   - [Software Bill of Materials (SBOM)](#software-bill-of-materials-sbom)
   - [Dependency Risk Management](#dependency-risk-management)
   - [Code Signing](#code-signing)
   - [Artifact Signing](#artifact-signing)
   - [Container Image Security](#container-image-security)
   - [Best Practices for Secure Software Supply Chain](#best-practices-for-secure-software-supply-chain)
   - [Common Supply Chain Pitfalls](#common-supply-chain-pitfalls)

9. [Hands-on Scenarios](#hands-on-scenarios)

10. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Security in DevSecOps

DevSecOps represents the integration of security practices into the DevOps workflow, embedding security "left" into the development lifecycle rather than treating it as an afterthought. For senior DevOps engineers, understanding security fundamentals means thinking beyond infrastructure and understanding the entire attack surface from development through production.

**Security in DevSecOps encompasses:**
- Shifting security focus left (embedding in CI/CD pipelines)
- Automating security controls and compliance checks
- Enabling autonomous teams while maintaining governance
- Implementing defense-in-depth across all layers
- Balancing developer velocity with risk mitigation
- Operating with observability and incident response capabilities

Security is not a single layer but a **cross-cutting concern** that spans:
- **Application security** (code quality, dependency management, secure coding practices)
- **Infrastructure security** (system hardening, network segmentation, identity management)
- **Data security** (encryption, access controls, compliance)
- **Operational security** (monitoring, incident response, disaster recovery)
- **Supply chain security** (artifact management, source control, build pipeline integrity)

### Why Security Matters in Modern DevOps Platforms

**1. Threat Landscape Evolution:**
- Attack surface has expanded with distributed systems, microservices, and cloud-native architectures
- Threat actors are increasingly targeting the software supply chain rather than endpoints
- Attacks have become more sophisticated, automated, and faster to exploit

**2. Compliance and Regulatory Pressure:**
- GDPR, HIPAA, SOC 2, PCI-DSS, and industry-specific regulations require security by design
- Cloud platforms introduce shared responsibility models requiring security understanding
- Organizations face financial penalties and reputational damage from breaches

**3. Business Continuity and Risk Management:**
- Security breaches directly impact revenue, customer trust, and brand reputation
- Downtime costs can exceed $5,600+ per minute for critical services
- Insurance requirements increasingly mandate specific security controls

**4. Developer and Organizational Velocity:**
- Well-implemented security actually enables faster deployment cycles
- Automated security gates reduce manual reviews and bottlenecks
- Clear security policies reduce decision paralysis and rework
- Secure platforms allow developers to focus on business logic

**5. Supply Chain Risks:**
- Log4j, SolarWinds, and similar incidents demonstrate supply chain vulnerabilities
- Open-source dependency vulnerabilities are discovered and exploited within hours
- Container and artifact integrity at scale requires robust security practices

### Real-World Production Use Cases

**1. E-Commerce Platform (High-Frequency Transactions)**
- **Challenge:** Handle millions of transactions securely while maintaining sub-100ms latency
- **Security Approach:** 
  - Zero-trust architecture with TLS everywhere
  - Secrets rotated hourly across 1000+ services
  - Real-time anomaly detection for fraud prevention
  - Network segmentation isolating payment systems from public interfaces
- **Outcome:** 99.99% availability with zero credential compromise in 3+ years

**2. Healthcare Platform (Regulated Data)**
- **Challenge:** HIPAA compliance with 10x growth in user base
- **Security Approach:**
  - Mandatory MFA for all access
  - RBAC with automated least-privilege enforcement
  - Encryption at rest (AES-256) and in transit (TLS 1.3)
  - Complete audit logs for all data access
  - Network segmentation with IDS/IPS
- **Outcome:** Passed SOC 2 Type II audit with zero findings

**3. SaaS Startup (Rapid Scaling)**
- **Challenge:** Build security into product from day one while maintaining deployment velocity
- **Security Approach:**
  - SBOM generated automatically for each build
  - Dependency scanning in CI/CD pipeline with automatic updates
  - Infrastructure as Code with policy-as-code enforcement
  - Secrets never stored in code or logs
  - Container image scanning before deployment
- **Outcome:** Attracted enterprise customers requiring security certifications

**4. Financial Services (High-Value Targets)**
- **Challenge:** Prevent sophisticated attacks targeting financial transactions
- **Security Approach:**
  - Multi-layer defense: WAF, API Gateway, application-level controls
  - Strict network segmentation with microsegmentation
  - Federated identity with adaptive MFA
  - Continuous threat hunting with SIEM integration
  - Incident response runbooks for 15-minute breach detection
- **Outcome:** Maintained security posture against APT groups

### Where Security Appears in Cloud Architecture

**1. Perimeter Layer:**
- DDoS protection and WAF (AWS WAF, Azure WAF, Cloudflare)
- DNS security (DNSSEC, threat feeds)
- Public IP management and exposure monitoring

**2. Identity and Access Layer:**
- IAM platforms (AWS IAM, Azure Active Directory, Okta)
- MFA services
- API authentication and rate limiting

**3. Network Layer:**
- VPCs/VNets with subnets (small scopes per security group)
- Security groups and NACLs
- Network segmentation and microsegmentation
- VPN and bastion hosts for administrative access

**4. Application Layer:**
- API gateway and service mesh security policies
- Container orchestration security (Kubernetes RBAC, network policies)
- Application secrets and config management

**5. Data Layer:**
- Encryption services (managed KMS, HSM)
- Database access controls and VPC endpoints
- Data classification and masking

**6. Monitoring Layer:**
- SIEM and log aggregation (ELK, Splunk, Cloud Logging)
- Threat detection and response
- Compliance monitoring and asset inventory

**7. Incident Response Layer:**
- Backup and disaster recovery
- Forensics and audit logs
- Communication and escalation paths

---

## Foundational Concepts

### Key Terminology

**Defense in Depth:**
Multiple layers of security controls so that failure of one control does not compromise overall security. Example: Even if a service account is compromised, network segmentation and RBAC limit damage.

**Attack Surface:**
The sum of all possible attack vectors against a system. Includes exposed APIs, accessible databases, misconfigured IAM roles, unpatched systems, and social engineering vectors.

**Threat Vector/Attack Vector:**
A method by which an attacker exploits a vulnerability. Examples: SQL injection, credential stuffing, privilege escalation, supply chain compromise.

**Vulnerability:**
A weakness in a system that can be exploited to cause unauthorized access, denial of service, or data disclosure.

**Exploit:**
Working code or technique that successfully leverages a vulnerability.

**Risk:**
The potential for harm. Risk = (Threat Probability) × (Impact Severity). A system can have many vulnerabilities with low risk if the threat probability or impact is low.

**Zero Trust Architecture:**
Security model assuming no implicit trust for access requests, even from within the network. Every access request must be explicitly verified based on identity, device, and context.

**Least Privilege:**
Users and systems should have only the minimum permissions necessary to perform their function. Principle reduces blast radius of compromise.

**Defense:**
Preventative controls that stop attacks before they succeed (firewalls, encryption, authentication).

**Detection:**
Monitoring and alerting that identifies when attacks are occurring (IDS, SIEM, anomaly detection).

**Response:**
Actions taken after detection to contain and remediate incidents (isolation, remediation, communication).

**Compliance:**
Meeting regulatory and policy requirements (GDPR, HIPAA, SOC 2).

**Audit Trail:**
Complete record of who did what, when, and where, enabling forensics and compliance verification.

### Architecture Fundamentals

**1. Security Domains:**

```
┌─────────────────────────────────────────────────────────┐
│                    Internet / Public                     │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────▼─────────────┐
        │  DDoS Protection / WAF    │
        │  Perimeter Security       │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────────┐
        │  Public Load Balancer / Ingress│
        │  API Gateway                   │
        └────────────┬───────────────────┘
                     │
        ┌────────────▼───────────────────────────┐
        │  Application Security Domain           │
        │  ┌─────────────┐  ┌────────────────┐  │
        │  │  Service A  │  │  Service B     │  │
        │  └──────┬──────┘  └────────┬───────┘  │
        │         │                  │           │
        │  ┌──────▼──────────────────▼────────┐ │
        │  │   Service Mesh / Control Plane   │ │
        │  └──────┬───────────────────────────┘ │
        └─────────┼─────────────────────────────┘
                  │
        ┌─────────▼──────────────────────────┐
        │  Data Security Domain              │
        │  ┌──────────────┐ ┌──────────────┐ │
        │  │  Database    │ │   Cache +    │ │
        │  │  (Encrypted) │ │   Secrets    │ │
        │  └──────────────┘ └──────────────┘ │
        └──────────────────────────────────────┘
```

**2. Threat Model Layers:**

| Layer | Examples | Threats | Controls |
|-------|----------|---------|----------|
| **User/Identity** | Users, service accounts | Credential theft, impersonation | MFA, RBAC, federated identity |
| **Application** | APIs, microservices | Code injection, logic flaws | WAF, input validation, rate limiting |
| **Network** | VPCs, ingress, services | Unauthorized access, data exfiltration | Segmentation, encryption, firewalls |
| **Data** | Databases, KMS, vaults | Data breaches, ransomware | Encryption, access controls, backups |
| **Infrastructure** | Servers, containers, VMs | Lateral movement, privilege escalation | Hardening, patching, monitoring |
| **Supply Chain** | Dependencies, artifacts | Compromised packages, malicious code | SBOM, scanning, signing |

**3. Security Stack Components:**

```
CI/CD Pipeline Integration
├── Pre-commit hooks (credential scanning)
├── SAST (Static Application Security Testing)
├── Dependency scanning (SCA - Software Composition Analysis)
├── Container image scanning
├── Infrastructure as Code scanning (IaC)
└── Artifact signing

Runtime Protection
├── WAF and API Gateway
├── Service mesh policies
├── Network policies and microsegmentation
├── RBAC enforcement
├── Secret management and injection
└── Audit logging

Observability & Detection
├── SIEM / Log aggregation
├── Threat detection (behavioral analysis)
├── Vulnerability scanning
├── Compliance monitoring
└── Incident response automation
```

### Important DevOps Security Principles

**1. Shift Left (Security by Design)**
- Identify and fix security issues as early as possible (development > build > deploy)
- Automated security gates prevent vulnerable code from reaching production
- Reduces cost of remediation exponentially (10x cheaper to fix in dev vs. production)
- Requires developers to think about security from day one

**2. Automation (Remove Manual Toil)**
- Manual security processes are slow, inconsistent, and error-prone
- Automate: scanning, compliance checks, secret rotation, access provisioning
- Enables security at scale without proportional team growth
- Provides consistent policy enforcement across all environments

**3. Defense in Depth (Layered Controls)**
- No single control is 100% effective
- Assume each layer will fail and design compensating controls
- Example: Even if a container escapes, network policies limit lateral movement
- Increases attacker effort and dwell time for detection

**4. Least Privilege (Minimum Access)**
- Users, services, and systems should have only necessary permissions
- Reduces blast radius when credentials are compromised
- Hard to implement well (requires understanding dependencies)
- Conflicts with convenience but improves security significantly

**5. Observable Security (See Everything)**
- Cannot secure what you cannot see
- Log all security-relevant events (auth, access, modifications)
- Centralize logs for correlation and alerting
- Enables rapid incident detection and response

**6. Zero Trust (Trust Nothing)**
- Do not trust network location, device type, or historical access patterns
- Every access request requires explicit verification and authorization
- No implicit trust, even for internal traffic or returning users
- Requires continuous authentication and device posture checks

**7. Failing Securely (Security Over Convenience)**
- When security controls fail, deny access rather than allowing it
- Better to have false negatives (blocking legitimate access) than false positives
- Requires clear incident response procedures and communication

**8. Know Your Threat Model**
- Security decisions should be driven by realistic threats, not fear
- Tailor controls to threats you actually face
- Avoid over-engineering for unlikely scenarios
- Enables risk-based prioritization and resource allocation

### Best Practices Overview

**1. Security Policy and Governance:**
- Document security requirements and policies
- Implement automated compliance checking (policy-as-code)
- Regular policy reviews and updates based on new threats
- Clear escalation paths and accountability

**2. Identity and Access Management:**
- Implement zero-trust with continuous verification
- Use role-based access control (RBAC) with regular audits
- Require MFA for all sensitive access
- Separate production and non-production environments

**3. Secrets Management:**
- Never store secrets in code, logs, or configuration files
- Use centralized secret vault with encryption
- Implement automatic secret rotation
- Audit all secret access

**4. Network Security:**
- Implement network segmentation (security groups/NACLs)
- Use VPN or bastion hosts for administrative access
- Encrypt all inter-service communication
- Monitor for anomalous traffic patterns

**5. Application Security:**
- Implement secure coding practices and code reviews
- Use input validation and output encoding
- Implement rate limiting and request throttling
- Use WAF for public-facing applications

**6. Infrastructure Security:**
- Keep systems patched and up-to-date
- Harden systems by removing unnecessary services
- Implement host-based firewalls and IDS
- Use configuration management for consistency

**7. Data Security:**
- Encrypt data at rest and in transit
- Implement access controls on sensitive data
- Classify data by sensitivity level
- Implement data masking for non-production environments

**8. Monitoring and Incident Response:**
- Centralize logging for all security events
- Implement alerting for suspicious activities
- Regular incident response drills
- Post-incident reviews to identify improvements

### Common Misunderstandings

**Misunderstanding #1: "We're in the cloud so we're secure"**
- **Reality:** Cloud providers handle infrastructure security but not application security
- **Truth:** Shared responsibility model requires security expertise on your part
- **Implication:** Misconfigured IAM, unencrypted data, and weak secrets are common in cloud

**Misunderstanding #2: "Security slows down deployment"**
- **Reality:** Poor security practices eventually slow down deployment (incident response, firefighting)
- **Truth:** Well-implemented security actually enables faster, more confident deployments
- **Implication:** Investing in security automation provides velocity dividends

**Misunderstanding #3: "We don't have anything valuable to attack"**
- **Reality:** Attackers target everything, not just high-value targets
- **Truth:** Your infrastructure can be used for cryptomining, botnets, or ransomware distribution
- **Implication:** Even "unimportant" systems need baseline security

**Misunderstanding #4: "Security is IT's responsibility"**
- **Reality:** Security decisions embed in architecture, code, and operations
- **Truth:** DevOps engineers make security decisions daily
- **Implication:** Security is everyone's responsibility, especially DevOps

**Misunderstanding #5: "Encryption solves all problems"**
- **Reality:** Encryption protects data but doesn't prevent unauthorized access to decryption keys
- **Truth:** Key management is as critical as encryption itself
- **Implication:** Encryption is necessary but not sufficient

**Misunderstanding #6: "We can patch on a quarterly schedule"**
- **Reality:** Critical vulnerabilities are exploited within hours of disclosure
- **Truth:** You need rapid patching for critical issues and regular patching for others
- **Implication:** Requires automation and well-tested deployment processes

**Misunderstanding #7: "Zero-trust means blocking everything"**
- **Reality:** Zero-trust is about explicit verification, not blanket denial
- **Truth:** Zero-trust verification can be transparent and user-friendly
- **Implication:** Balance security rigor with operational convenience

**Misunderstanding #8: "Compliance equals security"**
- **Reality:** Compliance checklists sometimes miss real security issues
- **Truth:** Compliance is a floor, not a ceiling
- **Implication:** Implement security beyond minimum compliance requirements

---

## Security Fundamentals

### Core Security Principles

**1. Confidentiality (C) - Information Privacy**

Confidentiality ensures that sensitive information is accessible only to authorized individuals or systems.

**Mechanisms:**
- **Encryption:** Transforms plaintext into ciphertext using a key, making data unreadable without the key
  - Symmetric encryption (AES-256): Same key for encryption/decryption, fast, scalable
  - Asymmetric encryption (RSA, ECDSA): Different keys for encryption/decryption, enables secure key exchange
  - Hybrid approaches: Use asymmetric to exchange symmetric keys
- **Access controls:** Limit who can read sensitive data
- **Data classification:** Tag data by sensitivity level
- **Network segmentation:** Restrict which systems can communicate

**Real-world example:**
```
Customer database containing PII:
✓ Encrypted at rest using AES-256 with separate keys per shard
✓ Encrypted in transit using TLS 1.3
✓ Access restricted to applications with legitimate need
✓ Database views limit column visibility per role
✓ Changes logged to immutable audit trail
```

**2. Integrity (I) - Information Accuracy**

Integrity ensures that information is accurate, complete, and has not been modified by unauthorized parties.

**Mechanisms:**
- **Cryptographic hashing:** One-way function that creates unique fingerprint of data
  - SHA-256: Secure hash algorithm, widely used for integrity verification
  - Changes to data result in completely different hash (avalanche effect)
- **Digital signatures:** Prove authenticity and integrity using asymmetric cryptography
- **Message authentication codes (MAC):** Prove integrity and authenticity using shared key
- **Version control:** Track all changes to code and configuration
- **Access controls:** Prevent unauthorized modifications

**Real-world example:**
```
Software artifact integrity:
✓ Build process creates SHA-256 hash of compiled binary
✓ Publisher signs hash using private key (digital signature)
✓ Consumer verifies signature using publisher's public key
✓ If binary is modified, hash won't match
✓ If signature doesn't verify, binary is tampered or from wrong source
```

**3. Availability (A) - System Accessibility**

Availability ensures that authorized users can access information and systems when needed.

**Mechanisms:**
- **Redundancy:** Multiple copies of systems and data (replication, failover)
- **Load balancing:** Distribute traffic across multiple instances
- **DDoS protection:** Mitigate large-scale volumetric attacks
- **Capacity planning:** Ensure sufficient resources for peak load
- **Disaster recovery:** Recovery procedures and backup systems
- **Rate limiting:** Prevent resource exhaustion from single users
- **Circuit breakers:** Fail gracefully when dependent systems are down

**Real-world example:**
```
Payment service availability:
✓ Replicated across 3 data centers in different regions
✓ Auto-scaling: 2-10 instances based on load
✓ DDoS mitigation in front of load balancer
✓ Backup payment processor if primary fails
✓ Rate limiting: 1000 req/sec per customer
✓ Complete data backup with 15-minute RTO (Recovery Time Objective)
✓ 99.99% uptime SLA enforced
```

### CIA Triad

The CIA Triad is foundational security model emphasizing three interdependent properties:

```
        ┌─────────────┐
        │ INTEGRITY   │
        │  (Accuracy) │
        └──────┬──────┘
               │
        ┌──────┴──────┐
        │             │
    ┌───▼───┐     ┌──▼────┐
    │   C   │     │    A   │
    │   I   │     │        │
    │   A   │     └────────┘
    └───────┘    AVAILABILITY
  (Privacy)     (Accessibility)
  (Secrecy)
  
Legend:
C = Confidentiality
I = Integrity  
A = Availability
```

**Trade-offs in CIA Triad:**

| Trade-off | Description | Example |
|-----------|-------------|---------|
| **C vs A** | Restrictive access (C) reduces availability; open access (A) reduces confidentiality | Require authentication (C) vs. public endpoints (A) |
| **I vs A** | Verification (I) adds latency; immediate response (A) may skip validation | Checksum verification vs. fast writes |
| **I vs C** | Encryption (C) can obscure changes (I); transparency (I) exposes data (C) | Plaintext logs (I) vs. encrypted logs (C) |
| **All three** | Perfect CIA requires redundancy, encryption, authentication—expensive and slow | Must prioritize based on risk |

**DevOps Security Focus:**

For DevOps platforms, the priority varies by context:

| Context | Priority | Reasoning |
|---------|----------|-----------|
| **E-commerce payment** | I > C > A | Integrity prevents fraud; confidentiality protects customers; downtime acceptable for seconds |
| **Healthcare records** | C > I > A | Confidentiality protects privacy; integrity ensures accuracy; availability needed but resilience exists |
| **Social media feeds** | A > C > I | Availability primary (users expect 24/7); confidentiality moderate; integrity slightly variable acceptable |
| **Financial operations** | I > C > A | Integrity prevents billions in fraud; confidentiality protects strategies; brief downtime acceptable |
| **Infrastructure control** | C > I > A | Confidentiality protects admin access; integrity ensures only authorized changes; some downtime recoverable |

### Threat Modeling

Threat modeling is systematic process of identifying, documenting, and prioritizing threats to a system.

**Threat Modeling Frameworks:**

**1. STRIDE (Microsoft)**

Threat categories by component type:

| Threat | Description | Example | Component |
|--------|-------------|---------|-----------|
| **S**poofing | Pretending to be someone/something else | Compromised API key, forged credentials | Identity |
| **T**ampering | Unauthorized modification of data/process | SQL injection, code injection | Data, Process |
| **R**epudiation | Denying actions you performed | Deleting logs, hiding API calls | Process |
| **I**nformation Disclosure | Unauthorized access to sensitive data | Reading environment variables, database dump | Data-at-rest |
| **D**enial of Service | Making system unavailable | DDoS, resource exhaustion, crash | Availability |
| **E**levation of Privilege | Gaining higher permissions than authorized | Container escape, privilege escalation | Authorization |

**Application: E-commerce checkout**
```
┌──────────────┐
│ User Browser │ ◀─── Spoofing: Fake checkout page (phishing)
└──────┬───────┘      Tampering: Modify amount in transit
       │              Repudiation: Claim you didn't purchase
       │              
┌──────▼──────────┐
│ API Gateway    │ ◀─── Spoofing: Compromised API key
└──────┬──────────┘      Tampering: Inject malicious requests
       │                 Elevation: Use admin key that leaked
       │
┌──────▼──────────┐
│ Payment Svc    │ ◀─── Information Disclosure: Expose other orders
└──────┬──────────┘      DoS: Request flood
       │                 Elevation: Exploit bug to approve denied payments
       │
┌──────▼──────────┐
│ Database       │ ◀─── Tampering: SQL injection
└───────────────┘       Information Disclosure: Read all payment data
                        Denial: Delete critical tables
```

**2. PASTA (Process for Attack Simulation and Threat Analysis)**

Seven-stage methodology:

1. **Define objectives** - Business goals, risk tolerance, constraints
2. **Define technical scope** - Systems, boundaries, trust zones
3. **Decompose application** - Detailed system architecture and data flow
4. **Analyze threats** - Identify threats for each component
5. **Perform vulnerability analysis** - Known vulnerabilities that enable threats
6. **Conduct attack modeling** - Attack chains and exploitation paths
7. **Risk analysis and management** - Prioritize and plan mitigation

**3. Trike (Risk-driven approach)**

Risk-focused threat modeling:

```
Requirements ──────▶ Use cases ──────▶ Swimlane diagram
     │                     │                  │
     ▼                     ▼                  ▼
  Implementation data   Attack tree      Threat model
```

**Practical Threat Modeling Process:**

```
Step 1: Identify Assets
├── What are we protecting?
│   ├── Customer data (PII)
│   ├── Business logic (IP)
│   ├── Authentication tokens
│   └── Infrastructure resources (compute, storage)
└── What is the impact if compromised?

Step 2: Identify Trust Boundaries
├── External vs. internal users
├── Public vs. private networks
├── Trusted 3rd parties (payment processors, CDN)
└── Diagram data flows across boundaries

Step 3: Identify Threats
├── Apply STRIDE to each component
│   ├── Determine how component could be spoofed
│   ├── Determine what data could be tampered with
│   ├── Determine what evidence could be repudiated
│   └── (... and so on for each STRIDE category)
└── Estimate likelihood and impact

Step 4: Identify Mitigations
├── Which threats already have controls?
├── Which threats need additional controls?
├── Prioritize by risk (likelihood × impact)
└── Assign ownership and timeline

Step 5: Validate
├── Re-examine model as system evolves
├── Include threat modeling in threat assessment process
├── Update when new threats emerge
└── Review after security incidents
```

### Risk Assessment

Risk assessment is the process of identifying, analyzing, and prioritizing risks.

**Risk Calculation:**
```
Risk = Probability of threat occurrence × Impact if occurs
     = Asset value × Threat frequency × Vulnerability exploitability
```

**Risk Matrix:**

```
        │ PROBABILITY
IMPACT  │ Low    Medium   High
────────┼────────────────────────
High    │ 🟡     🟠      🔴      Risk score increases
Medium  │ 🟡     🟡      🟠      with severity
Low     │ ⚪     🟡      🟡

Legend:
⚪ = Low risk (accept or monitor)
🟡 = Medium risk (plan mitigation)  
🟠 = High risk (prioritize mitigation)
🔴 = Critical risk (immediate action)
```

**Risk Scoring Example:**

| Vulnerability | Probability | Impact | Mitigation | Risk |
|---|---|---|---|---|
| Unpatched Apache server | High | High | Update in 24h | 🔴 Critical |
| Default admin password | Medium | High | Reset password | 🟠 High |
| No log retention | Low | Medium | Implement 90day retention | 🟡 Medium |
| Missing HTTP headers | Low | Low | Add headers in WAF | ⚪ Low |

**Risk Management Strategies:**

**1. Mitigate (Reduce risk)**
- Implement controls to reduce probability or impact
- Most common approach for important risks
- Example: Required MFA reduces identity compromise risk

**2. Accept (Live with risk)**
- Acknowledge risk but take no action
- Appropriate for low-priority or unavoidable risks
- Must be documented and approved
- Example: Accept brief downtime from rare hardware failure

**3. Transfer (Shift risk to others)**
- Use insurance, outsourcing, or 3rd parties
- Example: Use managed security service for threat monitoring
- Example: Insurance covers data breach costs

**4. Avoid (Eliminate risk by not doing activity)**
- Remove capability that introduces risk
- Sometimes not practical
- Example: Disable SSH password login (force key-only)

### Attack Surface Analysis

Attack surface is the total sum of all possible entry points where an attacker could attempt to access a system.

**Components of Attack Surface:**

**1. Network Attack Surface**
```
Internet ─▶ Public IP/Domain
           │
           ├─ Load Balancer (port 80, 443)
           │  ├─ Exposed management ports (22, 3389, 5000)
           │  └─ Misconfigurations (open security groups)
           │
           ├─ API Endpoints
           │  ├─ Authentication endpoints (login, token refresh)
           │  ├─ Unauthenticated endpoints (health checks, metrics)
           │  └─ Deprecated APIs (old versions still running)
           │
           └─ 3rd party integrations
              ├─ Webhooks accepting data from external sources
              └─ APIs called by trusted partners
```

**2. Application Attack Surface**
```
Code base
├─ Input vectors
│  ├─ User form inputs (XSS, injection)
│  ├─ File uploads (malicious files)
│  ├─ API request bodies (overflows, type confusion)
│  └─ URL parameters (traversal, manipulation)
├─ Output handling
│  ├─ Template injection (render untrusted data)
│  ├─ Error messages (information disclosure)
│  └─ Log files (sensitive data in logs)
├─ Business logic
│  ├─ Race conditions (concurrent requests)
│  ├─ Authorization flaws (missing checks)
│  └─ State management (invalid sequences)
└─ Dependencies
   ├─ Known vulnerabilities (CVEs in libraries)
   ├─ Weak cryptography (old algorithms)
   └─ Third-party API changes
```

**3. Data Attack Surface**
```
Data lifecycle
├─ Data at rest
│  ├─ Databases (weak authentication, unencrypted)
│  ├─ File storage (object storage, file systems)
│  ├─ Backups (often less protected than primary)
│  └─ Caches (plaintext secrets in Redis)
├─ Data in motion
│  ├─ Network communication (unencrypted protocols)
│  ├─ Inter-service communication (trust all internal)
│  ├─ External API calls (intercepted credentials)
│  └─ Log data (sent unencrypted to central system)
└─ Data in memory
   ├─ Application memory (core dumps, crash logs)
   ├─ System memory (sensitive values in env vars)
   └─ Browser memory (XSS, session tokens)
```

**4. Infrastructure Attack Surface**
```
Cloud platform
├─ Compute (EC2, VMs, containers)
│  ├─ Public IPs exposed unnecessarily
│  ├─ Overly permissive security groups
│  ├─ Missing OS hardening
│  └─ Outdated OS versions
├─ Storage (S3, blobs, managed databases)
│  ├─ Public read access (misconfiguration)
│  ├─ Default encryption disabled
│  └─ Backup exposure
├─ Identity and access (IAM)
│  ├─ Overly permissive policies
│  ├─ Long-lived credentials
│  └─ Shared accounts
└─ Network configuration
   ├─ Wide open security groups (0.0.0.0/0)
   ├─ Missing network segmentation
   └─ Unencrypted inter-service communication
```

**5. Operational Attack Surface**
```
People and processes
├─ Access provisioning
│  ├─ Slow deprovisioning (leavers still have access)
│  ├─ Weak approval workflows
│  └─ Standing access without justification
├─ Secrets management
│  ├─ Secrets in code repositories
│  ├─ Hardcoded credentials in config files
│  └─ Shared credentials across team
├─ Deployment
│  ├─ Manual deployments (error-prone)
│  ├─ Secrets in deployment logs
│  └─ Lack of change tracking
└─ Incident response
   ├─ No runbooks or procedures
   ├─ Unclear escalation paths
   └─ Limited ability to rollback
```

**Attack Surface Reduction Strategies:**

| Strategy | Implementation | Impact |
|----------|----------------|--------|
| **Minimize exposed services** | Disable unnecessary services, close ports | Fewer entry points |
| **Authentication everywhere** | Require auth for all APIs, internal and external | Reduce unauthorized access |
| **Input validation, output encoding** | Whitelist good input, escape output | Prevent injection attacks |
| **Least privilege** | Minimal IAM permissions, security groups | Limit blast radius |
| **Encryption** | TLS for network, AES-256 for data | Reduce data compromise impact |
| **Security updates** | Rapid patching of known vulnerabilities | Fewer exploitable flaws |
| **Secrets management** | Vault-based storage, no hardcoding | Reduce credential compromise |
| **Logging and monitoring** | Detect unauthorized access attempts | Faster breach detection |
| **Network segmentation** | Security groups, microsegmentation | Limit lateral movement |
| **Change management** | Track all changes, require approvals | Easier rollback if compromised |

### Security Controls Framework

Security controls are measures implemented to address identified risks. They are typically categorized as preventive, detective, or corrective.

**Control Types:**

**1. Preventive Controls (Stop attacks before they occur)**

Examples:
- **Authentication:** Prevent unauthorized users from accessing systems
- **Encryption:** Prevent reading of data without key
- **Input validation:** Prevent injection attacks
- **Access controls (RBAC):** Prevent unauthorized actions
- **Firewalls:** Prevent unauthorized network traffic
- **WAF:** Prevent application-level attacks

Advantages:
- Most cost-effective (prevents problems early)
- Reduces detection and response effort

Disadvantages:
- Cannot prevent all attacks (determined attackers may break through)
- Over-blocking can impact legitimate users

**2. Detective Controls (Identify attacks while occurring)**

Examples:
- **Intrusion detection (IDS):** Monitor for suspicious network traffic
- **Log analysis and SIEM:** Correlate logs to identify attacks
- **Vulnerability scanning:** Identify unpatched systems
- **File integrity monitoring:** Detect unauthorized file changes
- **Behavioral analysis:** Identify anomalous user/system activity
- **Alerts and notifications:** Notify security team of suspicious activity

Advantages:
- Can catch attacks that preventive controls missed
- Enables faster response and damage limitation

Disadvantages:
- Requires skilled staff to analyze alerts (alert fatigue)
- Time delay between attack and detection

**3. Corrective Controls (Respond to attacks and limit damage)**

Examples:
- **Incident response procedures:** Steps to contain and remediate
- **Automated response:** Isolation systems, block traffic
- **Backup and recovery:** Restore systems after compromise
- **Change management:** Rollback unauthorized changes
- **Communication procedures:** Notify stakeholders and customers
- **Forensics and investigations:** Understand how attack occurred

Advantages:
- Minimize damage and downtime from successful attacks
- Enable learning and improvement for future

Disadvantages:
- Most expensive (attack already succeeded)
- Recovery time and lost revenue still occur

**Control Matrix Example:**

| Risk | Preventive | Detective | Corrective |
|-----|-----------|-----------|-----------|
| **SQL injection** | Input validation, parameterized queries, WAF | WAF alerts, log analysis, IDS | Kill sessions, revoke credentials, restore DB |
| **Credential theft** | MFA, strong password policy, encrypted storage | Failed login alerts, anomaly detection | Force password reset, audit access, disable accounts |
| **Unauthorized data access** | RBAC, encryption, VPC endpoints | Access logging, SIEM alerts | Audit access logs, notify users, revoke credentials |
| **Malware on systems** | Application whitelisting, OS hardening, EDR | EDR detection, log analysis | Isolate systems, wipe and reimage, threat hunt |
| **Data loss** | Network segmentation, encryption, DLP | Data exfiltration alerts, FIM | Backup restore, evidence preservation, notification |

### Zero Trust Architecture

Zero Trust is a security model that assumes no implicit trust for any access attempt, even from within the network.

Traditional perimeter security model:
```
Trusted inside perimeter       Untrusted outside perimeter
┌─────────────────────────┐                  
│ ┌──────────┐ ┌────────┐ │        Internet       
│ │ Database │ │ App    │ │    ◀─ Firewall ──▶
│ │          │ │        │ │                  
│ └──────────┘ └────────┘ │   "If you're inside
│ ┌──────────┐ ┌────────┐ │    the network,
│ │ App      │ │ Admin  │ │    you're trusted"
│ │          │ │ system │ │    
│ └──────────┘ └────────┘ │    Problem:
└─────────────────────────┘    Compromised insider
                               is fully trusted
```

Zero Trust model:
```
Every access verified continuously:

User/Service ─▶ [Verify Identity] ─────────┐
                    ↓                       │
            [Get Device Posture] ────────┐  │
                    ↓                    │  │
        [Check Network Location] ─────┐ │  │
                    ↓                  │ │  │
        [Evaluate Context/Risk] ─────┐│ │  │
                    ↓                 ││ │  │
            [Least Privilege Check]◀─┘│ │  │
                    ↓                  │ │  │
        [Real-time Trust Score]◀──────┘ │  │
                    ↓                    │  │
        [Verify Resource Access]◀───────┘  │
                    ↓                       │
        [Encrypt Communication]◀───────────┘
                    ↓
        Grant access with continuous
        monitoring and audit
```

**Zero Trust Principles:**

**1. Verify explicit identity**
- Authenticate users with strong credentials
- Use MFA (at least 2 factors)
- Bind identity to device/location
- Continuous/periodic re-authentication

**2. Verify device posture**
- Enforce OS patching and security updates
- Verify antimalware/EDR running
- Check disk encryption enabled
- Monitor device for compromise indicators

**3. Validate resource access**
- RBAC based on least privilege
- Time-based access restrictions
- Session-based access with audit
- Separate access paths by sensitivity level

**4. Assume breach**
- Implement segmentation (if one system compromised, others isolated)
- Monitor all traffic (including internal)
- Implement rapid detection and response
- Process and infrastructure logs for forensics

**5. Encrypt communication**
- Use TLS 1.3+ for all network traffic
- Encrypt application-to-application communication
- Use VPN or mTLS for sensitive connections
- Key rotation and modern cryptography

**Zero Trust Implementation (Maturity Model):**

| Level | Focus | Controls | State |
|-------|-------|----------|-------|
| **1. Foundation** | Visibility | IAM, MFA, device inventory | "Where are we?" |
| **2. Advanced** | Segmentation | Network policies, microsegmentation | "How do we separate?" |
| **3. Optimized** | Continuous verification | Behavioral analytics, real-time risk | "Is this request normal?" |
| **4. Mature** | Autonomous response | Automated remediation, policy enforcement | "Act without human delay" |
| **5. Exceeds** | Predictive defense | Threat hunting, proactive testing | "Stop attacks before occurrence" |

**Zero Trust Tools/Services:**

| Area | Tools | Examples |
|------|-------|----------|
| **Identity verification** | SSO, MFA, PAM | Okta, Azure AD, HashiCorp Vault |
| **Network access** | BeyondCorp-like, VPN, proxy | Google BeyondCorp, Cloudflare Zero Trust, Zscaler |
| **Data segmentation** | Security groups, network policies | AWS security groups, Kubernetes network policies |
| **Continuous verification** | CASB, device posture | Microsoft Defender, Crowdstrike  |
| **Monitoring & analytics** | SIEM, behavior analytics | Splunk, Azure Sentinel, Datadog |

### Best Practices for Security in DevOps

**1. Code Security:**
- Implement secure coding guidelines using OWASP Top 10 as reference
- Code review process with security focus
- Static Application Security Testing (SAST) in CI/CD pipeline
- Dependency scanning for known vulnerabilities
- Avoid hardcoding secrets (use secret management)
- Implement input validation and output encoding

**2. Infrastructure Security:**
- Infrastructure as Code (IaC) for consistency and auditability
- Policy-as-Code for automated compliance checking
- Immutable infrastructure (never modify production, redeploy)
- OS hardening: remove unnecessary services, apply security updates
- Container security: scan images, minimize base layers, non-root users
- Secrets encryption in transit and at rest

**3. Access Control:**
- RBAC with least privilege principles
- Separate production and non-production access paths
- MFA required for all administrative access
- Service accounts with limited permissions
- Regular access reviews and cleanup
- Audit all access (who, what, when, where)

**4. Network Security:**
- Network segmentation (security groups, NACLs)
- TLS 1.3+ for all communications
- WAF for public-facing applications
- DDoS protection enabled
- API rate limiting and throttling
- Regular network security assessments

**5. Data Security:**
- Encrypt data at rest (AES-256)
- Encrypt data in transit (TLS)
- Implement database access controls and VPC endpoints
- Data classification and differential protections
- Backup testing and disaster recovery drills
- PII handling and compliance (GDPR, HIPAA, etc.)

**6. Secrets Management:**
- Centralized secret vault (Vault, Key Vault, Secrets Manager)
- Secret rotation (automated where possible)
- Audit all secret access
- Separate credentials per environment
- Never log secrets
- Use managed identities for cloud services

**7. Monitoring and Logging:**
- Centralized logging for all systems
- Immutable logs (cannot be modified or deleted)
- Alert on suspicious activity (failed auth, privilege escalation, data access)
- Audit logging for compliance (changes, access, admin actions)
- SIEM for correlation and forensics
- Retention policy aligned with compliance requirements

**8. Incident Response:**
- Documented runbooks for common scenarios
- Clear escalation paths and communication procedures
- Regular incident drills and war games
- Post-incident reviews to identify improvements
- Forensics capability (preserve evidence, collect logs)
- Communication templates for customers/stakeholders

**9. Supply Chain Security:**
- Track all dependencies (SBOM - Software Bill of Materials)
- Vulnerability scanning with automated updates
- Code signing for artifacts and containers
- Secure build pipelines (no privilege escalation)
- Container image signature verification
- Third-party security assessments

**10. Compliance and Governance:**
- Security policies and standards documentation
- Regular security assessments and penetration testing
- Compliance monitoring (automated where possible)
- Security awareness training for all staff
- Executive reporting on security metrics
- Budget and resource allocation for security

### Common Pitfalls and Prevention Strategies

**Pitfall #1: "Hardcoded Secrets in Code"**

**Problem:**
- Credentials left in source code repositories
- Accessible to anyone with code access
- If repository is compromised, all systems are compromised
- Humans are terrible at finding secrets in code

**Real consequence:** 
- Millions of AWS keys leaked from public GitHub repositories
- Attackers scan public repos and immediately exploit exposed credentials
- Remediation requires immediate credential rotation across production

**Prevention strategies:**
```
✓ Use secret vault (HashiCorp Vault, Azure Key Vault, AWS Secrets Manager)
✓ Inject secrets at runtime (environment variables, mounted secrets)
✓ Automated scanning in CI/CD (GitGuardian, git-secrets, TruffleHog)
✓ Pre-commit hooks to prevent secret commits
✓ Deny push to main branch if secrets detected
✓ Regular scanning of repository history for backdoored credentials
```

**Prevention implementation:**
```bash
# Pre-commit hook to prevent secret commits
#!/bin/bash
# .git/hooks/pre-commit

if git diff --cached | grep -E "(password|secret|api.?key|token)" -i; then
  echo "Error: Detected potential secret in staged code"
  echo "Use 'git rm --cached <file>' to remove from staging"
  exit 1
fi
exit 0

# In CI/CD pipeline
- name: Scan for secrets
  run: |
    pip install git-secret
    git secrets scan --cached
    # Alternative: truffleHog, GitGuardian, etc.
```

**Pitfall #2: "Overly Permissive IAM Roles"**

**Problem:**
- Service accounts with admin access
- Users with more permissions than needed
- Shared credentials across team
- No time-based or purpose-based access restrictions

**Real consequence:**
- Internal tool with admin AWS keys stolen
- Attacker provisions EC2 instances and runs cryptominers
- Costs balloon before detection (AWS didn't alert)
- All services (S3, database, etc.) are compromised

**Prevention strategies:**
```
✓ Implement least privilege by default (start with no permissions, add as needed)
✓ Role switching instead of credential sharing
✓ Separate production and non-production credentials
✓ Time-based temporary credentials (AWS STS, Vault)
✓ Regular access reviews and cleanup
✓ Automated policy analysis tools to detect overly permissive access
✓ MFA for sensitive operations
```

**Prevention implementation:**
```python
# Least privilege IAM policy example
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-bucket/app-logs/*",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": ["10.0.0.0/8"]  # Only from VPC
        },
        "StringEquals": {
          "aws:userid": "*:service-app"    # Only this service
        }
      }
    },
    # Note: No wildcard(*) permissions, specific resources only
  ]
}
```

**Pitfall #3: "No Network Segmentation"**

**Problem:**
- All services can communicate with all other services
- Compromised front-end can access database
- Internal traffic never encrypted
- No detection of lateral movement

**Real consequence:**
- Web server compromised via application vulnerability
- Attacker can directly query customer database (10,000+ records exposed)
- Attacker accesses admin systems and creates backdoor accounts
- Insider threat goes undetected

**Prevention strategies:**
```
✓ Implement network segmentation (security groups, NACLs, subnets)
✓ Default deny, explicit allow for each path
✓ Microsegmentation using service mesh (Istio) or host-based FW
✓ Encrypt all inter-service communication (mTLS)
✓ Monitor and alert on unexpected communication patterns
✓ Use private endpoints for managed services (no internet exposure)
✓ VPC isolation between environments
```

**Prevention implementation:**
```yaml
# Kubernetes NetworkPolicy example (microsegmentation)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: backend    # Only backend services can access DB
    ports:
    - port: 5432
      protocol: TCP
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - port: 53            # Only DNS outbound allowed
      protocol: UDP
# Note: Default denies all traffic except explicitly allowed
```

**Pitfall #4: "Logging Secrets and Sensitive Data"**

**Problem:**
- Passwords logged in application logs
- Credit card numbers in request logs
- API tokens in debug logs
- PII in error messages
- Logs sent unencrypted to central logging system

**Real consequence:**
- Junior developer reads logs to debug issue
- Sees production database password in logs
- Accidentally commits password to their personal GitHub repo
- Database compromised within hours

**Prevention strategies:**
```
✓ Data classification: identify what data is sensitive
✓ Log scrubbing: redact/mask sensitive data before logging
✓ Structured logging: use fields to separate data types
✓ Error message sanitization: generic user messages, detailed internal logs
✓ Encrypt logs in transit and at rest
✓ Audit logging: who accessed/read logs
✓ Log retention limited to regulatory requirements
✓ Policy: never log passwords, API keys, PII by default
```

**Prevention implementation:**
```python
# Log scrubbing example (Python)
import logging
import re

class SensitiveDataFilter(logging.Filter):
    """Remove sensitive data from logs"""
    
    patterns = {
        'password': r'password["\']?\s*[:=]\s*["\']?([^"\'\s,}]+)',
        'api_key': r'api[_-]?key["\']?\s*[:=]\s*["\']?([^"\'\s,}]+)',
        'credit_card': r'\b(?:\d{4}[-\s]?){3}\d{4}\b',
        'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    }
    
    def filter(self, record):
        message = record.getMessage()
        for data_type, pattern in self.patterns.items():
            message = re.sub(pattern, f'[{data_type.upper()}_REDACTED]', message, flags=re.IGNORECASE)
        record.msg = message
        record.args = ()
        return True

# Apply filter
logger = logging.getLogger(__name__)
logger.addFilter(SensitiveDataFilter())

logger.info(f"Database connection: password='secret123'")
# Output: Database connection: [PASSWORD_REDACTED]
```

**Pitfall #5: "No Incident Response Plan"**

**Problem:**
- No documented procedures for security incidents
- Unclear who should respond
- No tools or access for incident investigation
- Each incident handled ad-hoc
- Valuable investigation time wasted

**Real consequence:**
- Security alert triggers (suspicious activity detected)
- On-call person unsure what to do
- By the time manager is reached and investigation starts, attacker has spread
- Logs are overwritten before forensics collection
- No evidence preserved for legal proceedings

**Prevention strategies:**
```
✓ Document incident response procedures (runbooks)
✓ Define escalation chain and communication procedures
✓ Pre-position tools and access for investigation
✓ Regular incident drills to test procedures
✓ Clear definition of who declares/owns incidents
✓ Post-incident review process
✓ Evidence preservation and forensics capability
✓ Communication templates for customers/stakeholders
```

**Prevention implementation:**
```markdown
# Incident Response Runbook: Database Unauthorized Access

## Detection
- Alert: "Unusual large data export from production database"
- Alert: "Database credentials used from unauthorized IP"

## Initial Response (15 minutes)
1. Page on-call incident commander
2. Open incident war room (Slack channel #sec-incident-war-room)
3. Gather: Database logs, API logs, IAM access logs, network flows
4. Determine: Is access still occurring? If yes, ACTION ITEM: Kill sessions
5. Preserve: Export logs to immutable storage (not overwritten)
6. Notify: CTO, Security Lead, Legal (if data compromise suspected)

## Investigation (1-2 hours)
1. Full timeline: when did unauthorized access start?
2. Scope: what data was accessed/exfiltrated?
3. Root cause: how did attacker get credentials?
4. Check: are other systems compromised?
5. Artifact collection: save all relevant logs and evidence

## Containment (30 mins)
1. Revoke database credentials
2. Force rotate all related credentials
3. If confirmed compromise: rotate keys, secrets, certs
4. Audit all recent database activities
5. Check application logs for abnormal queries

## Recovery (1-4 hours)
1. Deploy database backup (if corruption/deletion)
2. Monitor database for further suspicious activity
3. Gradually restore normal operations
4. Verify monitoring and alerting still working

## Post-Incident (within 1 week)
1. Full forensic analysis (timeline, root cause)
2. Determine if customer/regulatory notification needed
3. Implement mitigations (e.g., database encryption, activity monitoring)
4. Update this runbook based on lessons learned
5. Post-incident review meeting (blameless)
```

---

---

## Linux & System Hardening

### Textual Deep Dive

**Operating System Hardening Overview**

Operating system hardening is the process of eliminating unnecessary features, closing known vulnerabilities, and limiting administrative access to the minimum required for legitimate operations. The goal is to reduce the attack surface and limit the damage potential if a system is compromised.

**Why Linux Hardening Matters in DevOps:**
- Containers and Kubernetes run on Linux (often hundreds of nodes)
- Compromised host can container-escape to compromise cluster
- CI/CD pipelines run on Linux servers and agents
- Misconfigured Linux systems are frequent entry points for attackers
- Linux systems often run with insufficient monitoring (assumed "hardened by default")

**Internal Working Mechanisms:**

The Linux security model operates at multiple levels:

```
User/Process Level
├─ User privileges (UID/GID)
├─ Process isolation (namespace, cgroups)
└─ Capabilities (fine-grained permissions)

Kernel Level
├─ Syscall filtering (seccomp)
├─ Access controls (SELinux, AppArmor)
├─ Memory protection (ASLR, DEP, stack canaries)
└─ Integrity checking (Audit subsystem)

File System Level
├─ Permission bits (rwx for user/group/other)
├─ Attribute permissions (immutable, security contexts)
├─ Mount options (noexec, nosuid, nodev)
└─ Encryption (full disk encryption, dm-crypt)
```

**Kernel Hardening Techniques**

The Linux kernel exposes many interfaces that can be exploited:

**1. Disable/Remove Unnecessary Kernel Modules**

Kernel modules extend kernel functionality but also expand attack surface. Modules commonly exploited:
- USB (access to arbitrary hardware)
- Thunderbolt (DMA access)
- Wireless drivers (protocol-level attacks)
- Sound systems (less audited code)

```bash
# Remove unnecessary modules on hardened systems
echo "install usb-core /bin/true" >> /etc/modprobe.d/usb.conf
echo "install thunderbolt /bin/true" >> /etc/modprobe.d/thunderbolt.conf
echo "blacklist snd_*" >> /etc/modprobe.d/sound.conf  # If no audio needed

# List loaded modules
lsmod

# Verify modules don't load
modprobe thunderbolt  # Should fail
```

**2. Enable Kernel Protection Features**

Modern kernels have hardening features that must be explicitly enabled:

```bash
# /etc/sysctl.d/99-hardening.conf

# ASLR - Address Space Layout Randomization
kernel.randomize_va_space = 2

# DEP / NX - Prevent executing code from data regions
# (Usually enabled by default, verify with: cat /proc/cpuinfo | grep nx)

# Stack canaries - Detect stack buffer overflows
# (Usually enabled by default in modern compilers)

# Restrict access to kernel logs (prevent info disclosure)
kernel.printk = 3 3 3 3
kernel.sysrq = 0

# Restrict dmesg access
kernel.dmesg_restrict = 1

# Restrict kernel pointer exposure
kernel.kptr_restrict = 2

# Restrict access to user namespace creation
kernel.unprivileged_userns_clone = 0  # For container engines, set to 1 with additional controls

# Restrict access to sensitive /proc files
kernel.core_uses_pid = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 2

# Restrict interaction with kernel stack
kernel.kexec_load_disabled = 1

# Restrict module loading
kernel.modules_disabled = 1  # After all modules loaded, set to 1 to prevent new module loads

# Network kernel hardening
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.tcp_syncookies = 1
```

**3. Enable Mandatory Access Control (MAC)**

SELinux (Security Enhanced Linux) and AppArmor provide access controls beyond traditional Unix permissions:

- **SELinux:** Type Enforcement (TE) - every file/process has a type, rules define which types can interact
- **AppArmor:** Profile-based - each application has a profile listing what it can access

**File System Permissions and Ownership**

Unix permissions are the foundation of Linux security:

```
rwx rwx rwx = 777 (user/group/other)
│   │   └─ Other permissions
│   └─ Group permissions
└─ Owner permissions

Common secure permissions:
644 = rw-r--r--  (configuration files, readable by all, writable only by owner)
755 = rwxr-xr-x  (executable, accessible by all, writable only by owner)
600 = rw-------  (secrets, writable only by owner, not readable by others)
700 = rwx------  (directories with secrets, only owner can access)
```

**Permission Best Practices for Hardened Systems:**

```bash
# Remove world-readable/writable permissions
find /etc -type f -perm /077 -exec chmod 640 {} \;   # Remove other permissions from config files
find /etc -type d -perm /077 -exec chmod 750 {} \;   # Remove other permissions from directories

# Restrict SSH private key permissions
chmod 600 ~/.ssh/id_rsa                              # Only owner can read
chmod 644 ~/.ssh/id_rsa.pub                          # Public key can be read

# Restrict sudo configuration (very sensitive)
chmod 440 /etc/sudoers
chmod 750 /etc/sudoers.d

# Restrict system files
chmod 644 /etc/passwd                                # Publicly readable (hashes removed)
chmod 000 /etc/shadow                                # NO ONE can read (sudo/system can only)
chmod 644 /etc/group
chmod 000 /etc/gshadow

# Find world-writable files (major security risk)
find / -type f -perm -002 2>/dev/null                # -002 means "at least write for others"

# Verify no SUID/SGID binaries that shouldn't be (setuid escalates to owner)
find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null
```

**SELinux and AppArmor Basics**

SELinux uses Type Enforcement:
- **Type:** Label for files/processes (e.g., `httpd_t`, `httpd_sys_content_t`)
- **Rules:** Define interactions ("httpd_t can read httpd_sys_content_t")
- **Context:** Combination of user, role, type, and level

```bash
# Check if SELinux is enabled
getenforce                                           # Enforcing, Permissive, or Disabled

# View file security context
ls -Z                                                # Shows type in output

# View process security context
ps auxZ | head                                       # Shows process types

# Check if file is labeled correctly
ls -Z /var/www/html
# Output: system_u:object_r:httpd_sys_content_t:s0 /var/www/html

# Manage SELinux
setenforce 0                                         # Switch to Permissive (still logs violations)
setenforce 1                                         # Switch to Enforcing
echo "SELINUX=enforcing" | sudo tee /etc/selinux/config

# Restore labeled files (after mass permissions change)
restorecon -Rv /var/www/html
```

AppArmor uses profile-based restrictions:

```bash
# Check AppArmor status
aa-status

# View active profiles
sudo cat /etc/apparmor.d/usr.bin.man

# Profile structure:
/usr/bin/man {
  /usr/bin/man mr,         # man binary can read/execute itself
  /usr/share/man/** r,      # Can read man pages
  /tmp/** rw,               # Can read/write /tmp
  /proc/*/stat r,           # Can read process stats
  # ... more rules
}

# Load/reload profile after changes
sudo apparmor_parser -r /etc/apparmor.d/usr.bin.man

# Test profile without enforcing (report violations to syslog)
sudo aa-complain usr.bin.man

# Enforce profile
sudo aa-enforce usr.bin.man
```

**SSH Hardening**

SSH is often the primary attack vector for Linux systems. Hardening requires both server and client changes:

```bash
# SSH Server Hardening (/etc/ssh/sshd_config)

# Port: Change from default 22 to non-standard (obscurity, not security)
Port 2222

# Authentication
PermitRootLogin no                                   # Never allow direct root login
PubkeyAuthentication yes                             # Only key-based auth
PasswordAuthentication no                            # Disable password login
PermitEmptyPasswords no                              # Ensure password is required
MaxAuthTries 3                                       # Limit failed attempts
MaxSessions 5                                        # Limit concurrent sessions per user

# Security
Protocol 2                                           # Only SSH v2 (v1 is obsolete)
X11Forwarding no                                     # Disable X11 forwarding if not needed
AllowTcpForwarding no                                # Disable port forwarding if not needed
PermitTunnel no                                      # No tunnel mode
PermitUserEnvironment no                             # Don't allow ~/.ssh/environment

# Crypto
# Use strong algorithms (older systems may need AES)
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
HostKeyAlgorithms rsa-sha2-512,rsa-sha2-256

# Timeouts
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Restrict user access
AllowUsers appuser devops-team                       # Whitelist allowed users
DenyUsers root nobody                                # Explicitly deny users

# Apply changes
systemctl reload sshd                                # Reload to apply config

# SSH Client Hardening (~/.ssh/config)

Host *
  # Only use strong key exchange algorithms
  KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
  
  # Only use strong ciphers
  Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
  
  # Use MFA (ProxyUseFdpass allows sudo+ssh MFA)
  ProxyUseFdpass yes
  
  # Timeout after inactivity
  ServerAliveInterval 300
  ServerAliveCountMax 2
  
  # Strict host key checking (prevents MITM)
  StrictHostKeyChecking accept-new
  UserKnownHostsFile ~/.ssh/known_hosts

# SSH Key Generation (client-side)
ssh-keygen -t ed25519 -C "email@example.com" -f ~/.ssh/id_ed25519 -N "passphrase"
# Use ed25519 over RSA (smaller, faster, more secure)
```

**Secure System Configurations**

**1. Disable Services**

Each running service is a potential attack vector:

```bash
# List services running as root
ps aux | grep root

# Disable unnecessary services
systemctl disable bluetooth.service
systemctl disable cups.service     # Print service if not needed
systemctl disable avahi-daemon.service
systemctl stop bluetooth.service
systemctl stop cups.service

# Verify services are stopped
systemctl is-active bluetooth.service  # Should output: inactive

# Mask services to prevent accidental start
systemctl mask bluetooth.service
```

**2. System-wide Account Management**

```bash
# Disable unnecessary system accounts
usermod -L postgres           # Lock account (password login impossible)
usermod -s /usr/sbin/nologin postgres  # Set shell to nologin

# Lock root account (use sudo instead)
usermod -L root

# Remove login shells for service accounts
for user in mail uucp news sync games; do
  usermod -s /usr/sbin/nologin $user
done

# Verify no passwordless accounts exist (major security risk)
awk -F: '($2 == "" || $2 == "!" || $2 == "!!") {print $1}' /etc/shadow  # Should be empty
```

**3. Umask Configuration**

Umask defines default permissions for newly created files:

```bash
# ~/.bashrc or /etc/bash.bashrc
umask 0077    # Files created: 600 (rw-------), directories: 700 (rwx------)
# Default umask 0022 results in: files: 644, directories: 755 (Too permissive!)

# Verify umask after login
umask  # Should output: 0077

# Create test file to verify
touch test.txt && ls -la test.txt
# Should show: -rw------- (600)
```

**Best Practices for Linux Hardening in DevOps**

**1. Infrastructure as Code (IaC) for Consistency**

Use tools to ensure all systems are hardened consistently:

```bash
# Ansible playbook for OS hardening
---
- name: Harden Linux Systems
  hosts: all
  become: yes
  tasks:
  
  - name: Update system packages
    apt:
      update_cache: yes
      upgrade: dist
    when: ansible_os_family == "Debian"
  
  - name: Enable kernel hardening
    sysctl:
      name: "{{ item.key }}"
      value: "{{ item.value }}"
      sysctl_set: yes
    loop:
      - { key: kernel.randomize_va_space, value: 2 }
      - { key: kernel.kptr_restrict, value: 2 }
      - { key: kernel.dmesg_restrict, value: 1 }
      - { key: fs.protected_hardlinks, value: 1 }
      - { key: fs.protected_symlinks, value: 1 }
  
  - name: Harden SSH Configuration
    lineinfile:
      path: /etc/ssh/sshd_config
      regexp: "^#?PermitRootLogin"
      line: "PermitRootLogin no"
      backup: yes
    notify: restart sshd
  
  - name: Ensure SSH key-based auth
    lineinfile:
      path: /etc/ssh/sshd_config
      regexp: "^#?PasswordAuthentication"
      line: "PasswordAuthentication no"
    notify: restart sshd
  
  handlers:
  - name: restart sshd
    systemd:
      name: sshd
      state: restarted
```

**2. Immutable Infrastructure**

Rather than patching systems in place, replace them:

```bash
# Hardened base image (build once, use everywhere)
1. Create base Linux image with all hardening applied
2. Scan for vulnerabilities and test
3. Deploy as immutable (never modify production image)
4. When patches available: rebuild image + redeploy
5. Old images automatically replaced (no manual patching needed)

Benefits:
- Consistent across all systems
- Easy rollback (keep old image)
- No drift (all systems identical)
- Reproducible (can audit what changed)
```

**3. Continuous Vulnerability Scanning**

```bash
# Cron job for weekly hardening audit
#!/bin/bash
# /usr/local/bin/hardening-audit.sh

REPORT="/var/log/hardening-audit.log"
echo "=== Hardening Audit $(date) ===" >> $REPORT

# Check for setuid binaries that shouldn't exist
echo "--- Unexpected SUID Binaries ---" >> $REPORT
find / -type f -perm -4000 2>/dev/null | grep -v -f /etc/approved_suid >> $REPORT

# Check for world-writable files
echo "--- World-Writable Files ---" >> $REPORT
find / -type f -perm -002 2>/dev/null >> $REPORT

# Check for passwordless accounts
echo "--- Passwordless Accounts ---" >> $REPORT
awk -F: '($2 == "") {print $1}' /etc/shadow >> $REPORT

# Check for services running as root
echo "--- Services as Root ---" >> $REPORT
ps -ef | grep "^root" | grep -v grep >> $REPORT

# Email report if issues found
if [ $(wc -l < $REPORT) -gt 10 ]; then
  mail -s "Hardening Audit Alert" security@company.com < $REPORT
fi

# Add to crontab
# 0 2 * * 0 /usr/local/bin/hardening-audit.sh
```

### Common Pitfalls in Linux Hardening

**Pitfall #1: "Running as Root"**

**Problem:** Services and applications running with root privileges when they don't need them.

**Real consequence:**
- Service has vulnerability (remote code execution)
- Attacker gets root access and can compromise entire system
- Can access all user files, modify system configuration
- Can access all secrets and environment variables

**Prevention:**
```bash
# Create service account (non-root)
useradd -r -s /usr/sbin/nologin myapp   # -r = system account

# Run service as that user in systemd
[Service]
ExecStart=/usr/bin/myapp
User=myapp
Group=myapp
PrivateTmp=yes
NoNewPrivileges=yes
```

**Pitfall #2: "Overly Permissive File Permissions"**

**Problem:** Configuration files, secrets, or binaries world-readable or world-writable.

**Real consequence:**
- Any user on system can read sensitive data (database passwords, API keys)
- Any user can modify system configuration
- Privilege escalation attacks succeed

**Prevention:**
```bash
# Scan for problems
find /etc -type f -perm /077 -ls               # Files readable/writable by non-owner
find /home -type f -perm /077 -ls              # Same in home directories

# Fix: Remove world permissions
find /etc -type f -perm /077 -exec chmod 640 {} \;
```

**Pitfall #3: "SSH Password Auth Still Enabled"**

**Problem:** SSH allows password authentication despite key-based auth being more secure.

**Real consequence:**
- Brute force attacks (millions of passwords attempted)
- Compromised credentials used for SSH access
- No correlation with SSH key if compromised (harder to track)

**Prevention:**
```bash
# /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
systemctl reload sshd
# Verify with: ssh -v user@host 2>&1 | grep authentication
```

**Pitfall #4: "Sudo Configured with NOPASSWD"**

**Problem:** Sudo commands allowed without password (NOPASSWD in sudoers).

**Real consequence:**
- Low-privilege process gains root access without additional auth
- Lateral movement attacks use compromised account for escalation
- Credential compromise becomes automatic privilege escalation

**Prevention:**
```bash
# Bad: NOPASSWD allows escalation without password
account ALL=(ALL) NOPASSWD: ALL              # ❌ NEVER DO THIS

# Good: Require password for escalation
account ALL=(ALL) ALL                        # ✓ Must enter password

# Better: Specific commands without password (limit blast radius)
app1 ALL=(ALL) NOPASSWD: /usr/sbin/service app1 restart
app2 ALL=(ALL) NOPASSWD: /usr/sbin/service app2 stop,start

# Verify sudoers syntax
visudo -c
```

**Pitfall #5: "Not Monitoring/Auditing Changes"**

**Problem:** No logging or detection of unauthorized system changes.

**Real consequence:**
- Attacker modifies system, changes aren't noticed
- Backdoors installed without detection
- Breach discovered weeks/months later (extensive damage)
- No forensics to understand how attack occurred

**Prevention:**
```bash
# Install audit tool (File Integrity Monitoring)
apt install aide                                   # or tripwire, osquery

# Create baseline (initial scan)
aideinit

# Scan regularly (cron)
aide --check

# Alert on changes
aide --check | mail -s "System Integrity Alert" admin@company.com

# Kernel audit system
auditctl -w /etc/shadow -p wa -k shadow_changes  # Watch shadow file
ausearch -k shadow_changes                        # Query audit logs
```

---

## Identity & Access Management

### Textual Deep Dive

**IAM Principles and Architecture**

Identity & Access Management is the foundation of security. It answers three critical questions:
1. Who are you? (Authentication/Identity)
2. What are you allowed to do? (Authorization/Permissions)
3. Are you still authorized? (Continuous verification)

**IAM Architecture in Cloud:**

```
┌─────────────────────────────────────────────────────────┐
│                    IAM System                           │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────┐      ┌──────────────────┐        │
│  │ Identity Store   │      │ Policy Store     │        │
│  │ (Users, Groups)  │      │ (Permissions)    │        │
│  │                  │      │                  │        │
│  │ LDAP/AD/Okta     │      │ RBAC/ABAC        │        │
│  │ Database, Files  │      │ CloudFormation   │        │
│  └────────┬─────────┘      └────────┬─────────┘        │
│           │                         │                   │
│           └────────────┬────────────┘                   │
│                        │                                │
│                  ┌─────▼───────┐                       │
│                  │ IAM Engine   │                       │
│                  │              │                       │
│                  │ Authenticate │                       │
│                  │ Authorize    │                       │
│                  │ Audit        │                       │
│                  └─────┬────────┘                       │
│                        │                                │
│        ┌───────────────┼───────────────┐               │
│        │               │               │               │
│    Access Granted   Access Denied   Audit Logged       │
│                                                          │
│  ┌──────────────────┐      ┌──────────────────┐        │
│  │ Cloud Resources  │      │ Services/Apps    │        │
│  │                  │      │                  │        │
│  │ S3, Database     │      │ APIs, Functions  │        │
│  │ Networks, VMs    │      │ CI/CD Pipelines  │        │
│  └──────────────────┘      └──────────────────┘        │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

**Role-Based Access Control (RBAC)**

RBAC assigns permissions not to users directly but to roles, which are then assigned to users:

```
User ──(assigned to)──▶ Role ──(has)──▶ Permissions

Benefits:
- Easier to manage (change role once affects all users in role)
- Separation of duties (different roles have different permissions)
- Scalable (add users to role quickly)
```

**RBAC Implementation Example:**

```
Roles in e-commerce platform:

1. Developer
   - Read: Code, Logs, Non-prod secrets
   - Write: Code, Deploy to staging
   - No access: Prod database, customer secrets

2. DevOps Engineer
   - Read: All logs, all infrastructure
   - Write: Deploy to prod, modify infrastructure
   - No access: Write to code repository

3. Security Engineer
   - Read: All logs, all audit trails, all policies
   - Write: Security policies, secret rotation
   - No access: Modify production code or infra

4. DBA
   - Read: Database metrics, logs
   - Write: Database backups, maintenance
   - No access: Application code, infrastructure

5. Customer Support
   - Read: Customer data (for support), Non-sensitive logs
   - Write: Tickets, customer notes
   - No access: Code, infrastructure, other customers' data
```

**RBAC vs ABAC:**

| Aspect | RBAC | ABAC |
|--------|------|------|
| **How it works** | Role = collection of permissions | Attributes + conditions = access decision |
| **Example** | "Developer role can read staging logs" | "User with dept=engineering + time=9-5 can read logs" |
| **Scalability** | Limited (role explosion) | Excellent (conditions handle complexity) |
| **Implementation** | Simple | Complex (requires policy engine) |
| **Use case** | Small teams, simple structures | Large orgs, complex rules |

**Least Privilege Principle**

Users and systems should have only the minimum permissions needed to perform their function.

```
Traditional approach:
Everyone ──▶ Admin access

Least privilege approach:
Dev team ──▶ Deploy staging + read logs
Prod ops ──▶ Deploy prod + modify infra
DBA ──▶ Manage databases
Security ──▶ View audit logs

Result: Fewer people with dangerous permissions
```

**Service Accounts and Managed Identities**

Service accounts are non-human identities used by applications, scripts, and systems to authenticate:

```
Traditional (Dangerous):
┌──────────────────┐
│ Application      │
└────────┬─────────┘
         │stores
         │credentials
         ▼
    Hardcoded username/password
    (or in environment variabled)
    
    Problem: If app compromised, attacker gets credentials

Modern (Secure - Managed Identities):
┌──────────────────┐
│ Application      │ ──▶ (to Azure AD / AWS IAM)
│ (Container/VM)   │     "I'm this app on this VM"
└──────────────────┘
         │
         │receives temporary token
         │(valid for 12-24 hours)
         ▼
    Use token for API calls
    
    Benefit: No credentials stored anywhere
            Token auto-rotates
            Audit trail of who/what accessed resources
```

**Federated Identity**

Federated identity allows users to authenticate once and access multiple systems:

```
Traditional:
User ──(password)──▶ System A
User ──(password)──▶ System B
User ──(password)──▶ System C
(Problem: manage passwords in multiple places)

Federated:
User ──(password)──▶ Identity Provider (Azure AD, Okta)
                     │
                     ├──▶ System A (OpenID Connect / SAML)
                     ├──▶ System B (OAuth 2.0)
                     └──▶ System C (OIDC)

(Benefit: single source of truth for identity)
```

**Multi-Factor Authentication (MFA)**

MFA requires multiple forms of verification before granting access:

```
Single Factor (Username + Password):
┌───────────────────┐
│ Username: john    │
│ Password: ****    │
│ [Login]           │
└───────────────────┘
Vulnerability: Password can be stolen/guessed

Two Factor (Password + TOTP/SMS):
┌───────────────────┐      ┌────────────────┐
│ Username: john    │      │ Enter code from│
│ Password: ****    │ ──▶  │ authenticator: │
│ [Login]           │      │ [______]       │
└───────────────────┘      └────────────────┘
Vulnerability: SMS can be intercepted (use TOTP instead)

Three Factor (Password + TOTP + Biometric):
┌───────────────────┐      ┌────────────────┐      ┌─────────────┐
│ Username: john    │      │ TOTP Code:     │      │ Fingerprint │
│ Password: ****    │ ──▶  │ [______]       │ ──▶  │ [Scan]      │
│ [Login]           │      │ [Submit]       │      │ [Verify]    │
└───────────────────┘      └────────────────┘      └─────────────┘
```

**Best Practices for IAM in DevOps**

**1. Implement Zero Trust for Access**

Every access request should be verified:

```bash
# Example: AWS cross-account access with strict MFA

# User authenticates to Identity Provider
aws sso login --profile prod

# IAM policy enforces MFA
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::PROD_ACCOUNT:role/DeploymentRole",
      "Condition": {
        "Bool": {"aws:MultiFactorAuthPresent": "true"},
        "NumericLessThan": {"aws:MultiFactorAuthAge": "3600"}  # MFA max 1 hour old
      }
    }
  ]
}

# User must MFA before access granted
aws sts assume-role \
  --role-arn arn:aws:iam::PROD_ACCOUNT:role/DeploymentRole \
  --role-session-name devops-session \
  --serial-number arn:aws:iam::ACCOUNT:mfa/user \
  --token-code 123456
```

**2. Separate Access Paths by Sensitivity**

Production, staging, and development should have separate access paths:

```
Development Environment:
└─ Low friction access
   └─ Developers can do most things
   └─ Quick iteration
   └─ Mistakes have limited impact

Staging Environment:
└─ Medium friction access
   └─ Requires code review for changes
   └─ Production-like but isolated
   └─ Testing ground for access changes

Production Environment:
└─ High friction access
   └─ Requires multi-person approval
   └─ Requires MFA
   └─ All changes audited
   └─ Time-based temporary access
   └─ Automatic approval denial after time
```

**3. Regular Access Reviews and Cleanup**

```bash
# AWS: Find users not used in 90 days
aws iam get-credential-report | \
  grep -v password_last_changed | \
  awk -F',' '{
    cmd = "date -d \""$5"\" +%s"
    cmd | getline last_change
    close(cmd)
    
    cmd = "date +%s"
    cmd | getline now
    close(cmd)
    
    if ((now - last_change) > 7776000) {  # 90 days in seconds
      print $1, $5, "NOT USED IN 90 DAYS"
    }
  }'
```

### Common IAM Pitfalls

**Pitfall #1: "Root Account with Password Stored"**

**Problem:** Root AWS account credentials used and stored instead of creating IAM users.

**Real consequence:**
- If root credentials compromised, entire AWS account is compromised
- Can delete all resources, drain budgets, steal data
- Often no MFA enabled (or stored credentials bypass MFA)
- Root credentials left in shared documents/emails

**Prevention:**
```bash
# AWS Best practice:
1. Create root account (one-time)
2. Enable MFA on root (hardware token)
3. Create IAM user for yourself (with MFA)
4. Store root credentials in secure location (not password manager)
5. Never use root for day-to-day operations
6. Rotate root credentials every 90 days
7. Enable CloudTrail to audit who logged in as root

# Delete AWS root access keys if they exist
aws iam list-access-keys --user-name root
aws iam delete-access-key --user-name root --access-key-id AKIAIO5ISXAMPLE
```

**Pitfall #2: "Permanent Access Keys for Service Accounts"**

**Problem:** Service accounts use long-lived access keys that are never rotated.

**Real consequence:**
- If key is compromised, attacker has permanent access
- Difficult to know when key was compromised
- Old systems still using key even after rotation

**Prevention:**
```bash
# Use temporary credentials with auto-rotation

# Kubernetes: Use IRSA (IAM Roles for Service Accounts)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/AppRole

---
kind: Pod
metadata:
  name: app-pod
spec:
  serviceAccountName: app-service-account  # Pod gets temporary credentials automatically
  
# AWS STS: Get temporary credentials
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT:role/AppRole \
  --role-session-name app-session

# Credentials auto-rotate (default 1 hour validity)
```

**Pitfall #3: "Shared IAM Users"**

**Problem:** Multiple people share the same IAM user account and credentials.

**Real consequence:**
- Cannot audit who did what (all actions appear as same user)
- If credential compromised, must change for entire team
- Team member leaving: must change credentials for entire team

**Prevention:**
```bash
# Give each person their own IAM user
aws iam create-user --user-name alice.smith
aws iam create-user --user-name bob.jones

# Same permissions via group membership
aws iam create-group --group-name developers
aws iam add-user-to-group --group-name developers --user-name alice.smith
aws iam add-user-to-group --group-name developers --user-name bob.jones

# Audit who did what
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=alice.smith
```

---

## Secrets Management

### Textual Deep Dive

**Secrets Management Fundamentals**

Secrets are sensitive information like passwords, API keys, encryption keys, tokens that must be protected. Improper secret management is one of the most common security failures.

**Why Secrets Matter:**

```
If exposed:
├─ Database password ──▶ Full database access (customer data breach)
├─ API key ──▶ Impersonate service (make requests as your application)
├─ SSH key ──▶ SSH access (command execution, lateral movement)
├─ OAuth token ──▶ Access user accounts (data exfiltration)
└─ Encryption key ──▶ Decrypt all past/future communications

Cost of compromise:
- Immediate: Attackers use access, steal data
- Short-term: Incident response, credential rotation, heartbleed
- Long-term: Regulatory fines, reputational damage, customer trust
```

**Secrets vs Configuration:**

| Type | Example | Storage | Rotation |
|------|---------|---------|----------|
| **Secret** | Database password | Vault | Every 30-90 days |
| **Secret** | API key | KMS/Vault | Every 90-180 days |
| **Configuration** | Database host | Code/ConfigMap | Changes with deployment |
| **Configuration** | Log level | Environment variable | Changes with restart |

**Key Principles:**

1. **Never commit to version control** - Revoke all credentials if found in history
2. **Encrypt at rest** - Stored secrets encrypted with separate key
3. **Encrypt in transit** - TLS for all secret transmissions
4. **Audit access** - Log who accessed what secret when
5. **Rotate regularly** - Even if not compromised, rotate to limit damage window
6. **Least privilege** - Applications access only secrets they need
7. **Short-lived** - Temporary credentials better than permanent

**Secret Vault Solutions**

**1. HashiCorp Vault**

Centralized secret management with fine-grained access control:

```
┌────────────────────────────────┐
│     HashiCorp Vault            │
├────────────────────────────────┤
│                                │
│  ┌──────────────────────────┐ │
│  │ Secrets Storage          │ │
│  │ (Encrypted at rest)      │ │
│  │                          │ │
│  │ Database passwords       │ │
│  │ API keys                 │ │
│  │ SSH keys                 │ │
│  │ Certificates             │ │
│  └──────────────────────────┘ │
│                                │
│  ┌──────────────────────────┐ │
│  │ Access Control           │ │
│  │ (RBAC/Token)             │ │
│  │                          │ │
│  │ Policies define what     │ │
│  │ each client can access   │ │
│  └──────────────────────────┘ │
│                                │
│  ┌──────────────────────────┐ │
│  │ Audit Logging            │ │
│  │ (Immutable log)          │ │
│  │                          │ │
│  │ Who accessed what secret │ │
│  │ When and from where      │ │
│  └──────────────────────────┘ │
│                                │
└────────────────────────────────┘
     │
     ├─▶ Application polls for DB password
     ├─▶ Microservice requests API key
     └─▶ CI/CD pipeline gets deployment token
```

**2. AWS Secrets Manager**

AWS-managed service for storing and rotating secrets:

```bash
# Store secret
aws secretsmanager create-secret \
  --name prod/database/master-password \
  --secret-string '{"username":"admin","password":"verysecure"}'

# Retrieve secret (automatically decrypted)
aws secretsmanager get-secret-value \
  --secret-id prod/database/master-password \
  --query SecretString --output text | jq .password

# Automatic rotation (trigger Lambda)
aws secretsmanager rotate-secret \
  --secret-id prod/database/master-password \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:rotate-secret

# Tag secret (organize by app/environment)
aws secretsmanager tag-resource \
  --secret-id prod/database/master-password \
  --tags Key=app,Value=payment Key=env,Value=prod

# Access control (IAM policy)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:region:account:secret:prod/database/*",
      "Condition": {
        "StringEquals": {"aws:RequestedRegion": "us-east-1"}  # Only in specific region
      }
    }
  ]
}
```

**3. Azure Key Vault**

Azure-managed service with role-based access and managed identities:

```bash
# Create vault
az keyvault create \
  --name "my-key-vault" \
  --resource-group "my-rg" \
  --enable-rbac-authorization  # Use AAD for access control

# Store secret
az keyvault secret set \
  --vault-name "my-key-vault" \
  --name "db-password" \
  --value "verysecure"

# Grant access to service principal (e.g., managed identity)
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id <service-principal-id> \
  --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.KeyVault/vaults/<vault>

# Retrieve secret from application
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://my-key-vault.vault.azure.net/", credential=credential)
secret = client.get_secret("db-password")
password = secret.value

# Secret rotates automatically through managed identities (no token management)
```

**Key Management Services (KMS)**

KMS provides encryption key management at scale:

```
Use case: Encrypt secrets at rest

┌──────────────────────────────┐
│ Secret: "database-password"  │
└──────────────┬───────────────┘
               │
        ┌──────▼──────────────────────────┐
        │ 1. Generate random data key     │
        │ 2. Use KMS master key to        │
        │    encrypt data key             │
        │ 3. Encrypt secret with data key │
        └──────┬───────────────────────────┘
               │
        ┌──────▼──────────────────────────┐
        │ Encrypted secret + encrypted    │
        │ data key stored in database     │
        │ (master key never leaves KMS)   │
        └──────────────────────────────────┘

To decrypt:
1. Encrypted data key ─▶ KMS (decrypt using master key) ─▶ Data key
2. Data key + Encrypted secret ─▶ decrypt ─▶ "database-password"
```

**Secret Rotation Strategies**

**1. Zero-Downtime Rotation**

Secrets rotated without disrupting service:

```
Step 1: Create new secret (both old and new valid)
Step 2: Applications update configs to use new secret
Step 3: Delete old secret after all services migrated

Example: Database password rotation
┌─────────────────────────────────────────────────────┐
│ Database: password_v1                               │
│ Application knows: password_v1                      │
└──────────────┬──────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Vault: rotation triggered                           │
│ 1. Generate password_v2                             │
│ 2. Update database to accept both passwords         │
│ 3. Update vault: both password_v1 and password_v2   │
│ 4. Applications retrieve password_v2 on next read   │
│ 5. Delete password_v1 from database/vault           │
└──────────────┬──────────────────────────────────────┘

Result: No downtime, applications automatically use new secret
```

**2. In-Place Rotation**

Secret updated in place:

```bash
# AWS secret automatic rotation with Lambda

{
  "SecretId": "prod/database/password",
  "RotationRules": {
    "AutomaticallyAfterDays": 30
  }
}

# Lambda function triggered automatically every 30 days
# Lambda modifies the actual resource and updates secret in vault

# Database password rotation Lambda flow:
1. Get old password from vault
2. Generate new password
3. Update database user password (using old password)
4. Update password in vault (KMS encrypted)
5. Test new password works
6. Done - all apps automatically get new password on next retrieval
```

**Runtime Injection Patterns**

Applications should not embed secrets - they should be injected at runtime:

**1. Environment Variables (Simple)**

```bash
# Dockerfile
FROM python:3.9
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
# Secret NOT in image, injected at runtime
CMD ["python", "app.py"]

# Runtime injection (Kubernetes)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  DB_PASSWORD: "secret123"
  API_KEY: "key456"

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: my-app:latest
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: DB_PASSWORD
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: API_KEY
```

**2. Volume Mounts (More Secure)**

```yaml
# Kubernetes mount secrets as files

apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db_password: c2VjcmV0MTIz  # base64 encoded
  api_key: a2V5NDU2

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: my-app:latest
        volumeMounts:
        - name: secrets
          mountPath: /etc/secrets
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: app-secrets
          defaultMode: 0400  # Read-only for owner
```

Application code:

```python
# Read secret from file
with open('/etc/secrets/db_password', 'r') as f:
    db_password = f.read().strip()

# File is automatically cleaned up when pod terminates
# Secret never appears in process environment (can't be seen with 'ps' or 'env')
```

**3. HashiCorp Vault Injection (Most Secure)**

```yaml
# Kubernetes with Vault Agent injecting secrets

apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "app-role"
        vault.hashicorp.com/agent-inject-secret-database: "secret/data/database"
        vault.hashicorp.com/agent-inject-file-database: "db_creds"
    spec:
      serviceAccountName: app-sa
      containers:
      - name: app
        image: my-app:latest
        # Vault Agent automatically:
        # 1. Authenticates using service account
        # 2. Retrieves secrets from Vault
        # 3. Mounts as /vault/secrets/db_creds
        # 4. Auto-rotates secrets based on TTL
```

**Best Practices for Secrets Management in DevOps**

**1. Never Hardcode Secrets**

```python
# ❌ BAD - Secret in code
database_url = "postgresql://admin:supersecret@db.example.com:5432/mydb"

# ✓ GOOD - Secret from environment
import os
database_url = os.environ['DATABASE_URL']

# ✓ BETTER - Secret from vault with SDK
from vault_client import get_secret
database_url = get_secret('prod/database/url')
```

**2. Implement Secret Scanning in CI/CD**

```bash
# Pre-commit hook to prevent secret commits
#!/bin/bash
# .git/hooks/pre-commit

PATTERNS=(
  'password\s*[=:]\s*[^[:space:]]'
  'api[_-]?key\s*[=:]\s*[^[:space:]]'
  'secret.*[=:]\s*[^[:space:]]'
  'BEGIN PRIVATE KEY'
  'BEGIN RSA PRIVATE KEY'
)

for pattern in "${PATTERNS[@]}"; do
  if git diff --cached | grep -i -E "$pattern"; then
    echo "ERROR: Potential secret detected in commit"
    echo "Use 'git rm --cached <file>' to remove from staging"
    exit 1
  fi
done
exit 0

# In CI/CD pipeline (TruffleHog scanning)
- name: Scan for secrets
  run: |
    pip install truffleHog3
    trufflehog3 -r $PWD -f json | tee scan-results.json
    # Fail if secrets found
    if [ $(jq 'length' scan-results.json) -gt 0 ]; then
      exit 1
    fi
```

**3. Audit All Secret Access**

```bash
# Enable KMS audit logging
aws kms put-key-policy \
  --key-id arn:aws:kms:region:account:key/id \
  --policy-name default \
  --policy file://policy.json

# CloudTrail records all GetSecretValue calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=prod/database/password \
  --max-results 50
```

### Common Secrets Management Pitfalls

**Pitfall #1: "Secrets in Environment Variables"**

**Problem:** Secrets stored in Dockerfile environment variables or visible in `docker inspect`.

**Real consequence:**
```bash
# Attacker can see secrets without entering container
docker inspect my-container | grep -A 50 Env

# Or from `/proc` inside container
cat /proc/self/environ | tr '\0' '\n' | grep SECRET

# Or from history
history | grep DATABASE_PASSWORD
```

**Prevention:**
```bash
# ❌ Don't do this (secrets visible)
ENV DATABASE_PASSWORD="secret"

# ✓ Do this instead (secrets injected at runtime from vault)
# Mount secret as file
-v /run/secrets/db_password:/etc/secrets/db_password:ro

# Read from file in application
db_password = open('/etc/secrets/db_password').read().strip()
```

**Pitfall #2: "No Secret Rotation"**

**Problem:** Secrets created once and never updated.

**Real consequence:**
- If secret ever compromised, attacker has permanent access
- Old developers/ex-employees still have credentials
- Attackers with stolen credentials continue accessing systems indefinitely

**Prevention:**
```bash
# Implement automatic rotation

# Vault: Enable automatic rotation
vault write -f secrets/rotate/database
# (Triggered by policy or manually)

# AWS Secrets Manager: Enable automatic rotation
aws secretsmanager rotate-secret \
  --secret-id prod/db/password \
  --rotation-lambda-arn arn:aws:lambda:region:account:function/rotate-db-password \
  --rotation-rules AutomaticallyAfterDays=30

# Check rotation history
aws secretsmanager describe-secret --secret-id prod/db/password
```

**Pitfall #3: "Storing Secrets in Container Images"**

**Problem:** Secrets baked into Docker image (e.g., AWS credentials in ~/.aws/credentials).

**Real consequence:**
- Anyone with image access gets secrets
- Secrets in image registries accessible to attackers
- Image scans reveal all secrets

**Prevention:**
```dockerfile
# ❌ BAD - Secrets in image
FROM ubuntu
COPY ~/.aws/credentials /root/.aws/credentials
COPY app.py .
RUN python app.py

# ✓ GOOD - Use managed identity
FROM ubuntu
COPY app.py .
# AWS IAM role attached to container runtime
# Application uses STS GetCallerIdentity for temporary credentials
RUN python app.py
```

---

## Network Security Fundamentals

### Textual Deep Dive

**Network Security Principles**

Network security protects data and systems from unauthorized access and disruption by controlling what traffic is allowed where.

**The Network Stack:**

```
Layer 7 (Application): TLS/SSL encryption, API authentication
Layer 6 (Presentation): Data encoding, encryption
Layer 5 (Session): Session management
Layer 4 (Transport): TCP/UDP ports, SSL/TLS tunnels
Layer 3 (Network): IP routing, network segmentation
Layer 2 (Data Link): MAC addresses, VLANs
Layer 1 (Physical): Cables, switches
```

**Network Segmentation**

Segmentation divides networks into smaller zones, limiting lateral movement if one zone is compromised.

```
No Segmentation (Dangerous):
┌────────────────────────────────────────┐
│  Public Web Servers                    │
│  ├─ Can directly access database       │
│  ├─ Can directly access admin systems  │
│  └─ If web server compromised, all    │
│     internal systems accessible        │
│                                        │
│  Database server can be accessed       │
│  from anywhere in network              │
│                                        │
│  Admin systems visible to all servers  │
└────────────────────────────────────────┘
```

```
With Segmentation (Secure):
┌──────────────────────────────────────────────────────┐
│              Internet (0.0.0.0/0)                    │
└──────────────────────┬───────────────────────────────┘
                       │
        ┌──────────────▼──────────────┐
        │   DMZ (Demilitarized Zone)  │
        │                             │
        │  ┌───────────────────────┐ │
        │  │ Web Servers           │ │
        │  │ (Public access)       │ │
        │  │ Can only:             │ │
        │  │ - Receive from inet   │ │
        │  │ - Send to app tier    │ │
        │  └───────────────────────┘ │
        └──────────────┬──────────────┘
                       │ (Restricted path)
        ┌──────────────▼──────────────────────┐
        │  Application Tier (10.1.0.0/16)    │
        │                                     │
        │  ┌──────────────────────────────┐  │
        │  │ App Servers (Kubernetes)     │  │
        │  │ Can only:                    │  │
        │  │ - Receive from web tier      │  │
        │  │ - Send to database tier      │  │
        │  └──────────────────────────────┘  │
        └──────────────┬────────────────────┘
                       │ (Restricted path)
        ┌──────────────▼──────────────────────┐
        │  Data Tier (10.2.0.0/16)           │
        │                                     │
        │  ┌──────────────────────────────┐  │
        │  │ Database                     │  │
        │  │ Can only:                    │  │
        │  │ - Receive from app tier      │  │
        │  │ - Receive from admin tier    │  │
        │  └──────────────────────────────┘  │
        └──────────────┬────────────────────┘
                       │ (Restricted path)
        ┌──────────────▼──────────────────────┐
        │  Admin Tier (10.3.0.0/16)          │
        │                                     │
        │  ┌──────────────────────────────┐  │
        │  │ Bastion/Admin Systems        │  │
        │  │ Can:                         │  │
        │  │ - Access any tier (as needed)│  │
        │  │ - Only accessible via VPN    │  │
        │  └──────────────────────────────┘  │
        └──────────────────────────────────────┘

Benefits:
✓ Web server compromised: Attacker can't reach database
✓ App compromised: Limited to application tier
✓ Database isolated: Only app and admin access
✓ Blast radius controlled: Breach doesn't spread
```

**Firewalls and Security Groups**

**1. Cloud Native Security Groups (Stateful Firewalls)**

```
Security Group (AWS):
A virtual stateful firewall controlling:
- What traffic is ALLOWED inbound
- What traffic is ALLOWED outbound
- Everything else DENIED by default (fail-secure)

Characteristics:
- Stateful: If you allow inbound traffic, response automatically allowed
- VPC-scoped: Can reference other security groups
- Mutable: Changes apply immediately (no reboot)

Example: Web Server Security Group
Inbound Rules:
├─ Protocol: TCP, Port: 80, Source: 0.0.0.0/0    (HTTP from anywhere)
├─ Protocol: TCP, Port: 443, Source: 0.0.0.0/0   (HTTPS from anywhere)
└─ Protocol: TCP, Port: 22, Source: 10.0.0.0/8    (SSH from VPC only)

Outbound Rules:
├─ Protocol: TCP, Port: 3306, Dest: app-sg       (MySQL to app tier)
└─ Protocol: TCP, Port: 53, Dest 0.0.0.0/0        (DNS to anywhere)

Result: Web server can be accessed from internet on ports 80/443,
         can SSH from VPC only, can access database and DNS only
```

**2. Network Access Control Lists (NACLs - Stateless)**

```
NACL (AWS):
Stateless firewall at subnet boundary:
- Most permissive NACL wins         (allow rule evaluated, deny rule checked)
- Order matters (rules evaluated top-to-bottom)
- Applied to all traffic entering/leaving subnet

vs Security Groups:
┌──────────────────────┬────────────────────┬──────────────────┐
│                      │   Security Group   │      NACL        │
├──────────────────────┼────────────────────┼──────────────────┤
│ Scope                │ Instance/ENI level │ Subnet level     │
│ Statefulness         │ Stateful           │ Stateless        │
│ Rule evaluation      │ Allow only         │ Allow/Deny       │
│ Default              │ Deny all inbound   │ Allow all        │
│ Performance impact   │ Minimal            │ Minimal          │
│ Use case             │ Primary security   │ Additional layer │
└──────────────────────┴────────────────────┴──────────────────┘
```

**Intrusion Detection/Prevention Systems**

**1. Network-based (Passive Detection)**

```
IDS (Intrusion Detection System):
Analyzes traffic for suspicious patterns

┌─────────────────────────────────┐
│  Network Traffic (Mirrored)     │
│  ├─ 10.1.1.1:80 ──▶ 1.2.3.4:443│
│  ├─ 10.1.1.2:22 ──▶ 1.2.3.5:22 │
│  └─ 10.1.1.3:3306 ─▶ ext IP    │
└────────────┬────────────────────┘
             │
      ┌──────▼──────────────────────┐
      │  IDS Detection Engine       │
      │  ├─ Signature matching      │ (known attack patterns)
      │  ├─ Anomaly detection       │ (behavior analysis)
      │  └─ Protocol analysis       │ (malformed packets)
      └──────┬───────────────────────┘
             │
      ┌──────▼──────────────────────┐
      │  Alert/Log                  │
      │  "SQL injection attempt"    │
      │  "Port scan detected"       │
      │  "DDoS threshold exceeded"  │
      └─────────────────────────────┘

Note: IDS doesn't block - it only alerts
```

**2. Network-based (Active Prevention)**

```
IPS (Intrusion Prevention System):
Actively blocks suspicious traffic

┌─────────────────────────────────┐
│  Incoming Network Traffic       │
│  ├─ 10.1.1.1:80 ──▶ 1.2.3.4:443│
│  ├─ Attacker:22 ──▶ Your Host  │
│  └─ Botnet:53 ──▶ Your IP      │
└────────────┬────────────────────┘
             │
      ┌──────▼──────────────────────┐
      │  IPS Analysis               │
      │  "Malware C&C traffic!"     │
      │  Action: ████░░░░░░         │
      └──────┬───────────────────────┘
             │
      ┌──────▼──────────────────────┐
      │  Block or Rate-Limit        │
      │  - Drop connection          │
      │  - Rate limit to 1 Mbps     │
      │  - Log and alert            │
      └─────────────────────────────┘
```

**DDoS Protection**

DDoS (Distributed Denial of Service) attacks overwhelm services with traffic:

```
DDoS Attack Types:

1. Volumetric (Bandwidth exhaustion):
   ├─ UDP floods: Send millions of UDP packets
   ├─ DNS amplification: Use DNS servers to reflect traffic
   └─ ICMP floods: Ping with max-size packets
   
   Protection:
   ├─ Rate limiting at ISP level
   ├─ Traffic filtering at CDN/edge
   └─ Anycasting (distribute to multiple locations)

2. Protocol (Resource exhaustion):
   ├─ SYN floods: TCP handshake abuse
   ├─ Fragmented packets: Reassembly CPU exhaustion
   └─ Slowloris: Hold connections open
   
   Protection:
   ├─ SYN cookies (validate handshake)
   ├─ Stateless filtering
   └─ Connection rate limiting

3. Application (Logic abuse):
   ├─ HTTP floods: Valid requests, overwhelming app
   ├─ Cache bypass: Requests that can't be cached
   └─ Bot attacks: Low-rate, hard to distinguish from legitimate
   
   Protection:
   ├─ WAF with behavior analysis
   ├─ API rate limiting
   └─ CAPTCHA challenges
```

**Best Practices for Network Security in DevOps**

**1. Network Segmentation Details**

```yaml
# Kubernetes Network Policies (microsegmentation)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-tier-isolation
spec:
  podSelector:
    matchLabels:
      tier: app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web     # Only web tier can access app tier
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:                            # Allow DNS (needed for service discovery)
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
```

**2. Encryption in Transit**

```bash
# TLS for all communication

# Kubernetes mTLS with Istio
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT  # All traffic must be mTLS

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: app
spec:
  host: app
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL  # Use Istio mTLS
```

### Common Network Security Pitfalls

**Pitfall #1: "Overly Permissive Security Groups"**

**Problem:** Security groups allow 0.0.0.0/0 (anywhere) access to sensitive ports.

**Real consequence:**
```
Misconfiguration: Database port 5432 open to 0.0.0.0/0
├─ Attacker scans internet for open databases
├─ Finds your exposed database
├─ Attempts default credentials
├─ Gains database access (if weak credentials)
└─ Exfiltrates customer data

Cost: Data breach, regulatory fines, reputational damage
```

**Prevention:**
```bash
# Audit security groups for overly permissive rules
aws ec2 describe-security-groups | \
  jq '.SecurityGroups[] | select(.IpPermissions[].IpRanges[].CidrIp=="0.0.0.0/0") | .'

# Fix: Restrict access to database
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 5432 \
  --source-group sg-app-tier  # Only from app tier security group
```

**Pitfall #2: "No Encryption Between Services"**

**Problem:** Services communicate without TLS (unencrypted, unencrypted credentials in traffic).

**Real consequence:**
```
Internal attacker (compromised app):
1. Spoofs internal service requests (no mutual TLS)
2. Intercepts database traffic on shared network
3. Steals credentials from plaintext API calls
4. Impersonates services to other components
```

**Prevention:**
```bash
# Enable mTLS everywhere
istioctl install --set profile=demo -y

# Enforce STRICT mTLS
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: default
spec:
  mtls:
    mode: STRICT
EOF
```

---

## Secure Software Supply Chain

### Textual Deep Dive

**Supply Chain Security Overview**

The software supply chain includes all components that go into building and deploying software:

```
SOFTWARE SUPPLY CHAIN LAYERS:

┌──────────────────────────────────────────────────────┐
│ 1. SOURCE CODE                                       │
│    ├─ Developer code (must not have backdoors)      │
│    ├─ GitHub, GitLab repositories                   │
│    └─ Risk: Code injection, malicious dependencies │
└──────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│ 2. DEPENDENCIES                                      │
│    ├─ Open-source libraries (npm, pip, Maven)       │
│    ├─ Third-party packages                          │
│    └─ Risk: Vulnerable, malicious, or compromised  │
└──────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│ 3. BUILD PROCESS                                     │
│    ├─ Compile code                                  │
│    ├─ Run tests                                     │
│    ├─ Create artifacts (binary, image, etc.)        │
│    └─ Risk: Compromised build system, malicious    │
│           dependencies injected during build        │
└──────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│ 4. ARTIFACT STORAGE                                  │
│    ├─ Container registries (Docker Hub, ECR, etc.)  │
│    ├─ Package repositories                          │
│    └─ Risk: Unauthorized modifications, tampering   │
└──────────────────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────┐
│ 5. DEPLOYMENT                                        │
│    ├─ CI/CD pipelines                               │
│    ├─ Kubernetes pull and run                       │
│    └─ Risk: Pulling wrong version, unsigned images  │
└──────────────────────────────────────────────────────┘

Attacker goal: Inject malicious code at weakest link
```

**Software Bill of Materials (SBOM)**

SBOM is a complete list of all components in software, enabling vulnerability tracking:

```json
{
  "version": "1.3",
  "identifier": "my-application@1.0.0",
  "components": [
    {
      "type": "library",
      "name": "requests",
      "version": "2.28.1",
      "purl": "pkg:pypi/requests@2.28.1",
      "licenses": ["Apache-2.0"],
      "vulnerabilities": []
    },
    {
      "type": "library",
      "name": "flask",
      "version": "2.1.2",
      "purl": "pkg:pypi/flask@2.1.2",
      "licenses": ["BSD-3-Clause"],
      "vulnerabilities": [
        {
          "id": "CVE-2022-1234",
          "severity": "HIGH"
        }
      ]
    },
    {
      "type": "library",
      "name": "urllib3",
      "version": "1.26.9",
      "purl": "pkg:pypi/urllib3@1.26.9",
      "licenses": ["MIT"],
      "vulnerabilities": []
    }
  ]
}
```

**SBOM Usage:**

1. **Vulnerability Scanning:** Check dependencies against CVE databases
2. **License Management:** Ensure compliance (GPL requires open-sourcing)
3. **Supply Chain Risk:** Identify which apps affected by compromised package
4. **Incident Response:** Determine blast radius of vulnerability

**Dependency Risk Management**

**1. Identify Vulnerable Dependencies**

```bash
# npm audit (Node.js)
npm audit

# pip pip-audit (Python)
pip install pip-audit
pip-audit

# Maven Security Plugin (Java)
mvn dependency-check:check

# Trivy (Multi-language, container images)
trivy image my-app:latest
trivy fs --security-checks vuln,config,secret .

# Sample output showing vulnerability
```

| Severity | Package | Version | Vulnerability | Fix Version |
|----------|---------|---------|---|---|
| CRITICAL | requests | 2.27.0 | CVE-2022-1234 | 2.28.1 |
| HIGH | django | 2.1.4 | SQL injection | 2.2.0 |
| MEDIUM | pillow | 8.0.0 | Integer overflow | 8.1.0 |

**2. Secure Dependencies Update**

```bash
# Automated dependency updates with Dependabot (GitHub)
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    allow:
      - dependency-type: "direct"  # Only direct dependencies
    reviewers:
      - security-team
    labels:
      - bump
      - python
    open-pull-requests-limit: 5

# Configure to auto-merge patches (non-breaking)
auto:
  merge:
    enabled: true
    merge-type: squash
```

**3. Lock Files and Reproducible Builds**

```
Lock files pin exact dependency versions:

Before lock file:
└── requirements.txt:
    requests>=2.25.0        # Could be 2.25.0, 2.26.0, 2.27.0, etc.
    └─ Creates unpredictable builds (version depends on when installed)
    └─ Different developers build with different versions

After lock file:
└── requirements-lock.txt:
    requests==2.28.1        # Exact version pinned
    urllib3==1.26.12        # dependencies also pinned
    charset-normalizer==2.1.1
    └─ Creates reproducible builds (same version every time)
    └─ All developers build with same versions
    └─ Security: Know exactly what code is running
```

**Code Signing**

Code signing proves authenticity and integrity:

```
WITHOUT Code Signing:
1. Developer creates code
2. Builder creates binary
3. Binary uploaded to registry
4. Consumer downloads binary

Problem: How does consumer know:
├─ Binary wasn't modified in transit?
├─ Binary from legitimate developer?
└─ Binary not backdoored by registry?

WITH Code Signing:
1. Developer creates code
2. Builder creates binary
3. Builder signs binary with private key
4. Binary + signature uploaded to registry
5. Consumer receives binary + signature
6. Consumer verifies signature with developer's public key
7. If verified: Binary is authentic and unmodified

Process:
┌──────────┐
│  Binary  │ ──▶ Hash ──▶ Sign with private key ──▶ Signature
└──────────┘
     │
     └────────▶ Distribution (binary + signature)
                      │
                      ▼
          Consumer: Verify with public key
                      │
                  ┌───┴────┐
                  ▼        ▼
              Valid     Invalid
            (Use it)  (Reject it)
```

**Artifact Signing (Container Images)**

Cosign signs container images:

```bash
# Generate signing key
cosign generate-key-pair
# Generates: cosign.key (private), cosign.pub (public)

# Build and sign image
docker build -t my-registry/app:latest .
cosign sign --key cosign.key my-registry/app:latest

# Verify image signature before using
cosign verify --key cosign.pub my-registry/app:latest

# Kubernetes admission controller only allows signed images
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: k8srequiredsignature
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredSignature
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        violation[{"msg": msg}] {
          image := input.review.object.spec.containers[_].image
          # Image must be signed with approved key
          # Verify using Cosign before deployment
        }
```

**Container Image Security**

**1. Minimal Base Images**

```dockerfile
# ❌ BAD: Full Linux distribution (400MB+, many attack vectors)
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y python3 pip
COPY app.py .
# Image contains: shell, package manager, compilers, etc. (not needed)

# ✓ GOOD: Slim image (100MB, minimal attack surface)
FROM python:3.11-slim
COPY app.py .
# Image contains: Python only

# ✓ BETTER: Distroless image (5-10MB, no shell, no package manager)
FROM python:3.11-slim as builder
COPY app.py .
RUN pip install -r requirements.txt

FROM gcr.io/distroless/python3  # No shell, only Python runtime
COPY --from=builder /usr/local/lib/python3.11/site-packages /
COPY app.py .
CMD ["python", "app.py"]
```

**2. Non-root User**

```dockerfile
# Create non-root user
RUN useradd -m -u 1000 appuser

# Copy app with correct ownership
COPY --chown=appuser:appuser app.py .

# Run as non-root (cannot install packages, modify system)
USER appuser
```

**3. Image Scanning**

```bash
# Scan for vulnerabilities before pushing
trivy image --severity HIGH,CRITICAL my-app:latest

# Scan for hardening issues
trivy image --severity HIGH,CRITICAL my-app:latest
# Checks for: hardcoded secrets, root user, writable filesystem

# Scan for supply chain issues (SBOM)
syft my-app:latest > sbom.json

# Periodically re-scan running images (images degrade over time)
# New CVEs discovered in dependencies, need updates
```

**Best Practices for Secure Software Supply Chain**

**1. Source Code Security**

```bash
# Branch protection on main
├─ Require pull request reviews (minimum 2)
├─ Require status checks to pass (tests, security scans)
├─ Dismiss stale reviews when code updated
├─ Require branches to be up to date
└─ Enforce code signing on commits

# Implement CODEOWNERS (require specific team to review)
# CODEOWNERS file:
* @security-team            # Security team reviews everything
/src/payment/ @payment-team  # Payment team reviews payment code
/src/admin/ @security-team   # Security team reviews admin code
```

**2. Dependency Management**

```bash
# Dependabot configuration
1. AUTO-DETECT dependencies (package-lock.json, requirements.txt, pom.xml)
2. CHECK DAILY for new versions and vulnerabilities
3. OPEN PULL REQUESTS for updates
4. REQUIRE TESTS to pass (don't merge broken builds)
5. AUTO-MERGE patch updates (if tests pass)
6. MANUAL REVIEW for minor/major updates
```

**3. Build Pipeline Security**

```bash
# Secure CI/CD pipeline

1. Source verification
   ├─ Verify commit signatures
   └─ Verify branch protection rules followed

2. Dependency verification
   ├─ Lock file integrity check
   ├─ SBOM generation
   └─ Vulnerability scanning

3. Build verification
   ├─ Reproducible build (same inputs = same output)
   ├─ SAST (static application security testing)
   ├─ SCA (software composition analysis)
   └─ Build artifact freshness (don't reuse old builds)

4. Artifact verification
   ├─ Sign build artifacts
   ├─ Scan container images
   ├─ Generate SBOM
   └─ Push to registry with immutable tags
```

### Common Supply Chain Pitfalls

**Pitfall #1: "No Dependency Scanning"**

**Problem:** Using packages without checking for known vulnerabilities.

**Real consequence:**
- Log4Shell (CVE-2021-44228): RCE in ubiquitous logging library
- Thousands of applications compromised within hours
- Attackers immediately exploited vulnerable apps
- Cost: Trillions in potential damage (if all affected systems exploited)

**Prevention:**
```bash
# Scan dependencies before deployment
- name: Check for vulnerable dependencies
  run: |
    # Python
    pip install pip-audit
    pip-audit --strict  # Fail build if vulnerabilities found
    
    # Node.js
    npm audit --audit-level=high
    
    # Java
    mvn dependency-check:check
    
    # Multi-language
    trivy fs --exit-code 1 --severity HIGH,CRITICAL .
```

**Pitfall #2: "Pulling Latest Tag"**

**Problem:** Deployments use "latest" tag which can change, breaking reproducibility.

**Real consequence:**
```
latest tag points to: image v2.0.0
├─ Deploy application with "latest"
├─ Everything works

Later, new v3.0.0 released
├─ latest tag now points to v3.0.0
├─ Your deployment picks up image v3.0.0 on next rollout
├─ Breaking changes in v3.0.0 break your app
└─ You have no idea why because you didn't specify version
```

**Prevention:**
```yaml
# ✓ Always use specific version tags
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: my-registry/my-app:v1.2.3  # ✓ Specific version
        # image: my-registry/my-app:latest  # ❌ Never use latest in prod

# Also enable imagePullPolicy to verify image digest
imagePullPolicy: IfNotPresent
```

**Pitfall #3: "No Artifact Integrity Verification"**

**Problem:** No verification that artifacts haven't been modified.

**Real consequence:**
- Attacker compromises image registry or repository
- Modifies image/binary with malware
- You pull and deploy compromised code
- Malware runs in production

**Prevention:**
```bash
# Sign all artifacts
cosign sign --key cosign.key my-registry/my-app:v1.2.3

# Verify signature before deployment
# Kubernetes policy to only allow signed images
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-signature-verification
webhooks:
- name: verify.sigstore.dev
  admissionReviewVersions: ["v1"]
  clientConfig:
    service:
      name: sigstore-webhook
      namespace: sigstore
      path: "/verify"
    caBundle: <base64-encoded-ca>
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

---

## Hands-on Scenarios

### Scenario 1: Production AWS Credential Compromise - Incident Response & Recovery

**Problem Statement:**

Your monitoring alerts at 2:47 AM: "Unusual EC2 instance creation from IP 192.168.1.100 (unknown)". Investigation reveals:
- 3 new t2.xlarge instances launched in us-east-1
- All instances running cryptomining software
- AWS bill spike detected ($2,400/hour in unexpected EC2 costs)
- Attacker created new IAM user "backup-automation" with admin policy
- Access key leaked 6 hours ago in GitHub commit

**Architecture Context:**

```
Your Infrastructure:
├─ AWS Account: 123456789012
├─ Deployment: Multi-region (us-east-1, eu-west-1, ap-southeast-1)
├─ Services: ECS, RDS, S3, Lambda, API Gateway
├─ Development Team: 15 engineers + 3 DevOps
├─ CI/CD: GitHub Actions with AWS credentials
└─ Current controls:
   ├─ CloudTrail enabled (logs to S3)
   ├─ No MFA required for assume-role (failure!)
   └─ Secrets in GitHub (pre-commit hooks not enforced)
```

**Step-by-Step Response & Implementation:**

**Phase 1: Immediate Containment (Minutes 0-5)**

```bash
# Step 1: Identify compromised credentials
# From GitHub Actions logs or developer machine

COMPROMISED_ACCESS_KEY="AKIA5JXYZ..."
COMPROMISED_SECRET="wJal..."

# Step 2: Immediately revoke compromised credentials
aws iam delete-access-key \
  --access-key-id $COMPROMISED_ACCESS_KEY

# Step 3: Kill all unauthorized instances
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=launch-time,Values=2024-03-22T06:00:00*" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

for INSTANCE_ID in $INSTANCE_IDS; do
  aws ec2 terminate-instances --instance-ids $INSTANCE_ID
  echo "Terminated: $INSTANCE_ID"
done

# Step 4: Delete unauthorized IAM users
aws iam detach-user-policy --user-name backup-automation --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam delete-user --user-name backup-automation

# Step 5: Rotate all AWS credentials immediately
# Root account
aws iam remove-access-key-from-account-if-exists
aws iam create-access-key  # For root (temporary)

# All IAM users in CI/CD
for USER in $(aws iam list-users --query 'Users[].UserName' --output text); do
  OLD_KEYS=$(aws iam list-access-keys --user-name $USER --query 'AccessKeyMetadata[].AccessKeyId' --output text)
  for KEY in $OLD_KEYS; do
    aws iam delete-access-key --user-name $USER --access-key-id $KEY
  done
  aws iam create-access-key --user-name $USER
done
```

**Phase 2: Forensics & Investigation (Minutes 5-30)**

```bash
# Step 1: Query CloudTrail for all actions from compromised key
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=$COMPROMISED_ACCESS_KEY \
  --max-results 50 | jq '.Events[] | {EventTime, EventName, Resources}'

# Expected output:
# - ec2:RunInstances (3 times - cryptomining instances)
# - iam:CreateUser (1 time - backup-automation user)
# - iam:AttachUserPolicy (1 time - admin policy)
# - s3:GetObject (multiple times - checking for data)
# - dynamodb:Scan (multiple times - scanning databases)

# Step 2: Check if data was exfiltrated
aws s3api list-bucket-metrics-configurations --bucket my-prod-bucket
aws s3api get-object-tagging --bucket my-prod-bucket --key sensitive-data.xlsx

# S3 access logs
aws s3 cp s3://my-logging-bucket/s3-access-logs/ ./logs/
grep $COMPROMISED_ACCESS_KEY logs/* | grep get-object

# Step 3: Check database access logs
# RDS: Check audit logs for DESCRIBE TABLE, SELECT statements
# DynamoDB: Check CloudTrail for Scan/Query operations
```

**Phase 3: Blast Radius Assessment**

```bash
# Step 1: Did attacker access S3 buckets?
aws s3api get-object-acl --bucket my-prod-bucket --key customer-data.csv
# Check if any buckets made public

# Step 2: Did attacker create persistent access?
# Check for EC2 key pairs created
aws ec2 describe-key-pairs --query 'KeyPairs[?CreateTime > `2024-03-22T06:00:00`]'

# Step 3: Did attacker modify IAM policies?
aws iam list-users | jq '.Users[] | select(.CreateDate > "2024-03-22T06:00:00")'

# Step 4: Determine if customer data compromised
# If yes, initiate incident response + customer notification

# Step 5: Check ECS/Lambda for compromised roles
aws ecs list-tasks --cluster production
aws lambda list-functions | grep -A5 CreateDate

# If any found in time window, regenerate IAM roles/credentials
```

**Phase 4: Long-Term Remediation**

```bash
# Step 1: Implement MFA requirement for assume-role
cat > mfa-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": ["sts:AssumeRole"],
      "Resource": "*",
      "Condition": {
        "BoolIfExists": {"aws:MultiFactorAuthPresent": "false"}
      }
    }
  ]
}
EOF

# Apply as SCPs (Service Control Policy) at organization level
aws organizations put-policy --content file://mfa-policy.json --type SERVICE_CONTROL_POLICY

# Step 2: Enable credential monitoring
aws accessanalyzer start-resource-scan --analyzer-arn arn:aws:access-analyzer:region:account:analyzer/ConsoleAnalyzer --resource-arn arn:aws:iam::account:user/*

# Step 3: Implement automated credential rotation
aws secretsmanager create-secret \
  --name prod/github-actions/aws-credentials \
  --rotation-lambda-arn arn:aws:lambda:region:account:function/rotate-credentials \
  --rotation-rules AutomaticallyAfterDays=30

# Step 4: Enforce pre-commit hooks
git config core.hooksPath .githooks
chmod +x .githooks/pre-commit

# Step 5: Implement secret scanning in CI/CD
# Add to GitHub Actions
- name: Check for secrets
  run: |
    pip install detect-secrets
    detect-secrets scan --baseline .secrets.baseline
    if [ $? -ne 0 ]; then echo "Secrets detected!"; exit 1; fi
```

**Post-Incident Review:**

- **Root cause:** Credentials committed to GitHub, not detected by pre-commit hooks
- **Detection delay:** 6 hours (should have been < 5 minutes)
- **Improvements needed:**
  - Mandatory MFA for all IAM role assumptions
  - Automated credential rotation (30-day max lifetime)
  - Real-time CloudTrail analysis with alerting
  - Pre-commit hooks enforcing secret scanning
  - Ephemeral credentials for CI/CD (STS instead of long-lived keys)

---

### Scenario 2: Zero-Trust Migration - Legacy Organization (6-Month Project)

**Problem Statement:**

You inherit a 500-person financial services company with highly permissive network security:
- All internal traffic unencrypted
- Any employee can SSH to any server
- Database accessible from any application server
- Admin credentials shared across teams
- No MFA requirement for system access

**Challenge:** Migrate to Zero-Trust while maintaining operations and compliance (PCI-DSS required).

**Architecture Context:**

```
Current State (Perimeter Security):
┌──────────────────────────────────────────────────────┐
│ Corporate Network (10.0.0.0/8)                       │
│                                                      │
│ ┌────────────┐  ┌───────────┐  ┌──────────────┐    │
│ │ Desktops   │──│  File     │──│ Databases    │    │
│ │            │  │  Servers  │  │              │    │
│ └────────────┘  └───────────┘  └──────────────┘    │
│      │                │                │            │
│      └────────────────┼────────────────┘            │
│       (All traffic unencrypted)                      │
│                      │                              │
│ ┌────────────────────▼──────────────────────┐      │
│ │  Firewall: 80, 443 only                   │      │
│ │  Internal: All protocols allowed          │      │
│ └───────────────────────────────────────────┘      │
│                                                      │
└──────────────────────────────────────────────────────┘
       │
       └──▶ Internet (Default: Allow)
```

**Target State (Zero-Trust):**

```
Zero-Trust Architecture:
User ──▶ Authenticate (MFA) ──▶ Access Control ──▶ Encrypted Channel ──▶ Resource
         (Azure AD)                 (Context-aware)      (mTLS)
             │                           │                    │
          Verify:                   Check:              All traffic
          - Identity                - Device posture    encrypted/signed
          - Device                  - Network location
          - MFA                      - Risk level
```

**6-Month Implementation Plan:**

**Month 1: Foundation (Planning & Tooling)**

```bash
# Step 1: Assess current state
# Inventory all systems and access patterns

# Create audit baseline
for host in $(cat inventory.txt); do
  echo "=== $host ===" >> audit-baseline.log
  ssh $host "netstat -tlnp" >> audit-baseline.log
  ssh $host "ps aux" >> audit-baseline.log
  ssh $host "sudo iptables -L" >> audit-baseline.log
done

# Step 2: Deploy centralized logging
# Implement ELK stack or cloud-native (Azure Log Analytics)

# Step 3: Choose zero-trust tools
# Identity: Azure AD / Okta (already evaluating)
# Device: Intune / Workspace ONE
# Network: Cisco Zero Trust, Zscaler, or open-source (StrongSwan + PolicyEngine)
# Secrets: HashiCorp Vault (deploy centralized instance)

# Step 4: Train security and DevOps teams
# 40 hours of training on:
# - Zero Trust concepts
# - MFA administration
# - Certificate management
# - Policy definition

# Step 5: Communication plan to organization
# "Security is improving. Your access patterns will change.
#  Here's what to expect and how to get help."
```

**Month 2-3: Identity Layer (Hardest Part)**

```bash
# Step 1: Deploy Azure AD (identity provider)
# All employees must authenticate against Azure AD
# Enforce MFA via Conditional Access

# Step 2: Create role hierarchy
# Instead of: everyone has admin access
# New model:
cat > roles.yaml <<EOF
roles:
  developer:
    - permission: deploy-staging
    - permission: read-prod-logs
    
  devops-engineer:
    - permission: deploy-prod
    - permission: modify-infrastructure
    - permission: rotate-secrets
    
  security-engineer:
    - permission: audit-all
    - permission: manage-firewalls
    - permission: incident-response
    
  database-admin:
    - permission: manage-databases
    - permission: backup-restore
    - permission: capacity-planning
EOF

# Step 3: Migrate from shared credentials to individual accounts
# For each employee:
# 1. Create individual AD account
# 2. Add to appropriate security group
# 3. Test access on non-prod systems
# 4. Confirm access works
# 5. Remove shared credentials
# (Phased approach: dev teams first, then prod teams)

# Step 4: Implement approval workflow
# Elevated access requires:
# - Requestor: specify what, why, how long
# - Manager: approve or deny
# - Security: audit decision
# - System: grant temporary credentials (auto-expire)

cat > request-elevated-access.sh <<EOF
#!/bin/bash
# Request temporary elevated access

RESOURCE=$1    # "prod-database" 
DURATION=${2:-4h}  # How long needed

# Request to approval system
curl -X POST https://approvals.company.com/request \
  -d "resource=$RESOURCE" \
  -d "duration=$DURATION" \
  -d "reason=$(read -p 'Why do you need access?'; echo $REPLY)" \
  -d "user=$(whoami)"

echo "Request submitted. Manager will approve in Slack."
# Auto-expire after duration (even if forgotten)
EOF
```

**Month 4: Network Layer (mTLS Between Services)**

```yaml
# Deploy service mesh (Istio) for internal service communication
# All service-to-service traffic now requires mutual TLS

apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # All traffic must be mTLS

---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: database
  namespace: production
spec:
  hosts:
  - database
  http:
  - match:
    - sourceLabels:
        app: backend-api  # Only backend API can access DB
    route:
    - destination:
        host: database
        port:
          number: 5432

  # Any other source is denied
  - fault:
      abort:
        percentage: 100
        grpc:
          status: PERMISSION_DENIED
```

**Month 5: Device Posture & Endpoint Compliance**

```bash
# Step 1: Deploy endpoint protection
# - Antimalware
# - Disk encryption
# - OS patching enforcement
# - Device inventory

# Step 2: Configure Conditional Access
# MFA required if:
# - Accessing prod resources
# - Network location is public
# - Device hasn't checked in > 24h
# - OS is unpatched

# Azure AD Conditional Access Policy
{
  "displayName": "Require MFA for Prod Access",
  "conditions": {
    "applications": ["prod-database", "prod-api"],
    "users": ["all"],
    "locations": ["Unknown", "Virtual_IPRange"]
  },
  "grantControls": {
    "operator": "AND",
    "builtInControls": [
      "mfa",
      "compliantDevice"
    ]
  }
}

# Step 3: Audit device compliance
# Every 6 hours, verify:
# - Device is Azure AD registered
# - Firewall enabled
# - Antimalware installed and updated
# - Full disk encryption enabled
# - OS patches installed
# - No jailbreak/root
```

**Month 6: Continuous Monitoring & Optimization**

```bash
# Step 1: Implement continuous logging
# All authentication attempts logged to SIEM
# All resource access logged to SIEM
# All policy decisions logged to SIEM

# Query: Who accessed what, when, from where?
select timestamp, user, resource, action, source_ip, status
from audit_logs
where timestamp > now() - interval 7 day
order by timestamp desc
limit 1000;

# Step 2: Behavioral analytics
# Alert if:
# - User accesses resource outside normal pattern
# - Same user from 2 cities simultaneously (impossible)
# - Massive data download from normally read-only user
# - 10+ failed login attempts

# Step 3: Measure security posture
# Track metrics:
# - % of users with MFA enabled (target: 100%)
# - % of devices compliant (target: 98%)
# - Average time from vulnerability disclosure to patch (target: 24h)
# - Mean time to detect anomalies (target: < 5min)
# - Mean time to remediate (target: < 30min)

# Step 4: Incident playbooks
# Test regularly (monthly drills):
# - Compromised account detection and lockdown
# - Suspicious data access investigation
# - Malware detection and containment
# - Ransomware recovery
```

**Success Metrics After 6 Months:**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| % users with MFA | 0% | 98% | 100% increase |
| Avg time to detect breach | 6 hours | 2 minutes | 180x faster |
| Data breaches | 1 per year (avg) | 0 | Target: 0 |
| Compliance violations | 12/year | 0 | Target: 0 |
| Employee satisfaction | Still high | High | No significant impact |
| Security team workload | High (manual review) | Lower (automated) | 30% less manual work |

---

### Scenario 3: Supply Chain Security Incident - Compromised Dependency Detection

**Problem Statement:**

At 9:00 AM on Monday, a critical vulnerability (CVSS 9.8) is discovered in a popular npm package `axios-pro` (fake package, typo of `axios`). The package contains backdoor code that:
- Exfiltrates API keys from environment variables
- Creates reverse shell for attackers
- Spreads to transitive dependencies

Your organization has this package (dependency of a dependency) in production.

**Step-by-Step Incident Response:**

```bash
# Step 1: Immediate detection (your SBOM + vulnerability scanning)
# Monday 9:15 AM - Alert from Snyk/Trivy

# Your SBOM shows inventory:
my-api-service
├── axios@1.4.0 (vulnerable known)
├── express@4.18.0
│   └── axios-pro@1.0.2  # ⚠️ TRANSITIVE DEPENDENCY WITH BACKDOOR
└── lodash@4.17.21

# Step 2: Determine blast radius
# Which services are affected?

for service in $(list-all-services); do
  sbom=$(generate-sbom $service)
  if echo "$sbom" | grep -q "axios-pro"; then
    echo "AFFECTED: $service has axios-pro"
  fi
done

# Output:
# AFFECTED: my-api-service (production)
# AFFECTED: payment-processor (production - CRITICAL!)
# AFFECTED: admin-dashboard (development)
# NOT AFFECTED: mobile-backend (uses axios, not axios-pro)

# Step 3: Determine exposure window
# Check when axios-pro was introduced

git log --all --source -- package-lock.json | grep axios-pro
# Introduced 45 days ago in commit abc123

# Current production images deployed:
kubectl get deployments -o json | jq '.items[] | select(.spec.template.spec.containers[].image | contains("my-api-service")) | .metadata.creationTimestamp'
# Deployed since: 45 days ago

# Assume: EXPOSURE = 45 days

# Step 4: Investigate if backdoor was exploited
# Check logs for indicators of compromise

# Indicator 1: Unexpected external connections from containers
kubectl logs -l app=payment-processor --tail=10000 | \
  grep -E "(outbound|connect|socket|reverse)" 

# Indicator 2: Unauthorized API key exposure
# Query vault for who accessed what secrets during exposure window
vault audit logs | grep -A5 -B5 "2024-02-01 to 2024-03-16"

# Indicator 3: New IAM users created
aws iam list-users | grep CreateDate | grep "2024-02"

# Indicator 4: Unusual cloudtrail activity
aws cloudtrail lookup-events \
  --start-time 2024-02-01T00:00:00Z \
  --end-time 2024-03-16T23:59:59Z \
  --max-results 100 | jq '.Events[] | select(.ResourceName | contains("secret"))'

# If any indicators found: ESCALATE TO INCIDENT RESPONSE

# Step 5: Immediate remediation

# 5a. Revoke all credentials used by affected services
for secret in $(vault list secret/payment-processor); do
  echo "Revoking: $secret"
  vault kv destroy secret/payment-processor/$secret
done

# 5b. Rebuild images without backdoor
# Update package.json
cat > package.json <<EOF
{
  "dependencies": {
    "axios": "^1.4.0",  # Use correct package (not axios-pro)
    "express": "^4.18.0",
    "lodash": "^4.17.21"
  }
}
EOF

# Rebuild and deploy new images
docker build -t payment-processor:v2.0.0-patched .
docker push my-registry/payment-processor:v2.0.0-patched

# 5c. Deploy patched version immediately
kubectl set image deployment/payment-processor \
  payment-processor=my-registry/payment-processor:v2.0.0-patched \
  --record

# 5d. Rotate all credentials again (double rotation for safety)
vault generate-root
aws iam create-access-key

# Step 6: Forensics & investigation
# Did attacker gain access?
# What data was potentially stolen?

# 6a. Get forensic container image for analysis
docker exec payment-processor-pod /bin/sh -c \
  'env | grep -i "api\|secret\|key" > /tmp/env_dump.txt'

# 6b. Check network flows
kubectl logs -l app=payment-processor \
  -c istio-proxy --tail=50000 | \
  jq '.destination_ip, .destination_port' | \
  sort | uniq -c | sort -rn

# 6c. Check file system modifications
# What changed since image build?
sha256sum container_fs/* > /tmp/current_checksums
diff /tmp/build_checksums /tmp/current_checksums > /tmp/filesystem_changes

# Step 7: Communication & notification
# Notify affected customers if data compromise confirmed

cat > incident-notification.txt <<EOF
Subject: Security Incident Notification - Payment Processing

Dear Customer,

We are writing to inform you of a security incident that may have affected your account.

Details:
- Vulnerability: axios-pro package backdoor (CVSS 9.8)
- Discovery date: Monday, March 18, 2024, 9:00 AM
- Exposure window: February 1 - March 18 (45 days)
- Affected service: Payment Processing
- Status: Mitigated (all credentials rotated, images patched)

What we did:
1. Immediately identified all affected services
2. Revoked all potentially exposed credentials
3. Deployed patched application versions
4. Enabled continuous monitoring for anomalies

Did this affect me?
- If you made payments: Verify recent transactions match your records
- If you see unauthorized charges: Contact support immediately

We are committed to your security and will keep you updated.
EOF

# Step 8: Post-incident improvements (within 1 week)

# 8a. Implement lock file integrity checking
# Prevent typos (axios vs axios-pro) with dependency verification

cat > verify-dependencies.sh <<EOF
#!/bin/bash
# Verify no typos in dependencies

DANGEROUS_TYPOS=(
  "axies:axios"          # axios typo
  "req:request"          # request typo
  "bable:babel"          # babel typo
  "lodsh:lodash"         # lodash typo
  "expresss:express"     # express typo
)

for typo in "${DANGEROUS_TYPOS[@]}"; do
  FAKE=$(echo $typo | cut -d: -f1)
  REAL=$(echo $typo | cut -d: -f2)
  
  if npm list $FAKE 2>/dev/null | grep -q $FAKE; then
    echo "ERROR: Found typo package: $FAKE (did you mean $REAL?)"
    exit 1
  fi
done
EOF

chmod +x verify-dependencies.sh

# 8b. Implement supply chain defense layers
# 1. SCA (Software Composition Analysis) in CI/CD with breaking changes for critical
# 2. SBOM generation for every build
# 3. Container image scanning before deployment
# 4. Artifact signing and verification
# 5. Runtime scanning for anomalies

# 8c. Update incident response playbook
cat >> playbook.md <<EOF
## Supply Chain Incident Playbook

Detection:
- [ ] SCA tool alerts on new vulnerability
- [ ] SBOM checked for affected packages
- [ ] Affected services identified

Containment:
- [ ] Affected deployments identified
- [ ] Credentials for affected services revoked
- [ ] Images rebuilt without compromised dependency

Investigation:
- [ ] Check logs for indicator of compromise
- [ ] Check CloudTrail for unauthorized access
- [ ] Check vault for secret access during exposure window
- [ ] Forensic analysis of container images

Recovery:
- [ ] Deploy patched images
- [ ] Rotate all affected credentials
- [ ] Monitor for anomalies (24-48 hours)

Communication:
- [ ] Notify leadership
- [ ] Prepare customer communication if needed
- [ ] Update stakeholders

Post-Incident:
- [ ] Add dependency to supply chain risk monitoring
- [ ] Update vulnerability assessment tools
- [ ] Add supplier to monitoring list
- [ ] Review timeline for improvements
EOF
```

---

## Interview Questions

### Q1: How would you design a zero-trust architecture for a hybrid cloud environment with 500+ microservices?

**Answer Expected from Senior DevOps Engineer:**

"I'd approach this from three layers: identity, network, and data.

**Identity Layer:**
- Implement centralized federated identity (Azure AD / Okta) as single source of truth
- Every service authenticates via OIDC/OAuth2, not hardcoded credentials
- Use workload identity (AWS IRSA, Azure Managed Identity) - no service account credentials stored
- Time-limited tokens (1-2 hour TTL max) with auto-refresh
- MFA required for human access to sensitive resources
- Device compliance checks (patched OS, disk encryption, endpoint protection installed)

**Network Layer:**
- Service mesh (Istio/Linkerd) enforcing mTLS between all services
- Network policies restricting traffic to specific source/destination
- Microsegmentation: each microservice can only call specific services it needs
- All east-west traffic encrypted and authenticated

**Data Layer:**
- Encryption at rest with managedkeys (KMS)
- TLS 1.3 for all data in motion
- Secrets vault with short-lived credentials
- Access audit logging for all data access

**Real Challenge I'd Address:**
The hard part isn't technology—it's organizational change. Teams used to 'implicit trust' resist MFA and approval workflows. I'd phase implementation:

1. **Months 1-2:** Foundation (identity infrastructure, logging)
2. **Months 3-4:** Non-prod environments (dev/staging) - teams learn without production pressure
3. **Months 5-6:** Production rollout with feature flags allowing bypass for specific services
4. **Months 7+:** Enforce universally, fix issues as they arise

Success metrics I'd track:
- % services with mTLS enabled (target: 100%)
- % workloads using ephemeral credentials (target: 100%)
- Mean time to detect suspicious access (target: < 5 min)
- False positive rate in anomaly detection (target: < 2%)

One mistake many teams make: conflating zero-trust with 'deny everything.' That's frustrating for teams and doesn't work. Zero-trust means *explicit verification*, not blanket denial. It should be transparent to legitimate users."

---

### Q2: You discover a critical CVE in a transitive dependency used by 50+ microservices. Walk me through your response.

**Answer Expected:**

"I'd execute this in parallel streams to minimize exposure:

**Immediate (Next 5 minutes):**
1. Run SBOM check to identify all affected services
   - Which services use this dependency (directly or transitively)?
   - Which production services are affected (vs dev)?
   - What's the blast radius?

2. Check if vulnerability is actively exploited in the wild
   - Is there a public PoC?
   - What's the CVSS score and exploit complexity?
   - Am I in active danger or do I have hours to prepare?

3. Query audit logs for suspicious activity during exposure window
   - If vulnerable for 30 days, check last 30 days of access logs
   - Look for unauthorized API access, data exfiltration, strange outbound connections
   - If found: escalate to incident response

**Assessment (Next 30 minutes):**
1. Determine update strategy
   - Is there a patch available?
   - Will updating break anything (check test results)?
   - Can I update in stages (non-prod first)?

2. Run dependency analysis
   - Are there other vulnerabilities in the same package?
   - Should I update other packages while I'm at it?
   - Are there breaking changes I need to test?

**Implementation (Next 2-4 hours):**
1. Update dependency in package/requirements/pom files
2. Run full CI/CD suite (tests, SAST, SCA, container scanning)
3. Deploy in stages:
   - Non-prod environments (dev/staging)
   - Non-critical production services (test deployment)
   - Critical services (with monitoring for rollback)
4. Verify dependencies still work (no transitive version conflicts)

**Operational (Ongoing):**
1. Monitor for anomalies (24-48 hours)
   - Error rates
   - Performance degradation
   - Behavioral changes
2. Keep team informed with status updates
3. Document lessons learned

**Real caveat:**
50 services is a lot. Rebuilding and redeploying takes time. I'd parallelize:
- Batch 1: Services with auto-scaling (they can handle redraws quickly)
- Batch 2: Medium-traffic services
- Batch 3: Critical low-latency services (deploy last, monitor carefully)

If the vulnerability is critical + exploited + no patch available, I'd have to consider:
- Temporary network segmentation (isolate services)
- Increased monitoring
- IP blocking if attacker is known
- 'Circuit breaker': shut down service temporarily if attack detected

The key is: don't panic and deploy broken code. Test first, even if it means staying vulnerable for 4 hours. A broken production deployment is worse than vulnerability."

---

### Q3: How do you balance security with developer velocity? Give a real example from your experience.

**Answer Expected:**

"This is the real question that matters. Security that slows devs wins no goodwill.

**Real scenario I faced:**

My previous company implemented strict IAM policies:
- Every identity change required manager approval
- Approval process took 24-48 hours
- Devs waiting on access became frustrated
- Security team was bottleneck

**What I did wrong:**
- Designed security correctly but didn't automate the workflow
- Manual approval process became choke point

**What I fixed:**
1. **Automated as much as possible**
   - Self-service: Developer requests DB read access ➜ Auto-approved if pattern is normal
   - Policy enforcement: Roles defined in code, changes require code review (not separate approval)
   - Pre-defined access templates: "Give me standard developer access" ➜ Granted immediately

2. **Time-bound access**
   - Access expires automatically (no permission creep)
   - Devs request "access for 4 hours" or "access for this sprint"
   - Don't need approval for renewal

3. **Made security visible to builders**
   - Showed devs: "This policy prevents this class of attack"
   - Explained trade-offs: "Yes, you need to provide reason for access. Here's why that helps us."
   - Got buy-in

4. **Measured developer experience**
   - "% of access requests approved in < 5 minutes" (target: 95%)
   - "% of access requests requiring escalation" (target: < 5%)
   - Tracked manually-approved requests and asked: "Can this be automated?"

**Result:**
- DevOps latency dropped from 48 hours to 5 minutes (99% of cases)
- Privileged access still required manager approval (but < 5% of requests)
- Devs felt trusted (they were)
- Security posture improved (more visibility + automatic expiry)

**Key lesson:**
Security theater (lots of processes that look good but create friction) damages security. Devs work around bad policies. Instead:
- Automate decisions where possible
- Require human approval only for high-risk decisions
- Make security fast and frictionless for normal workflows
- Monitor compliance automatically (don't rely on manual audits)

**Metrics I'd use to measure success:**
- Developer satisfaction with security process (pulse survey)
- Mean time to grant access
- % of access requests that are legitimate (low false-positive rate)
- Number of security incidents (did we maintain our posture while improving velocity?)"

---

### Q4: Explain the trade-offs between centralized vs decentralized secret management. When would you choose each?

**Answer Expected:**

"This is nuanced and depends on your organization's maturity.

**Centralized Secret Management (Vault, AWS Secrets Manager):**

Characteristics:
- Single source of truth for all secrets
- Centrally managed rotation policies
- Single audit log for all access
- Single point of failure (if down, can't get secrets)

When I'd choose it:
- **Large organizations** (100+ teams) where audit trail matters
- **Regulated industries** (finance, healthcare) requiring compliance
- **High-security threshold** (secrets are truly sensitive)

Example architecture:
```
All services ──▶ [Vault] ──▶ Secrets
                (HA + backup)
                     │
                  Audit log (immutable)
```

Challenges:
- Vault itself becomes high-value target (must harden thoroughly)
- Performance: 10,000 services all hitting same vault = bottleneck
- Requires network access to vault (might not work for air-gapped systems)

**Decentralized Secret Management:**

Characteristics:
- Each service/team manages own secrets
- Faster (no central bottleneck)
- More resilient (one team's vault down doesn't affect others)
- Harder to audit globally
- Risk of inconsistent policies

When I'd choose it:
- **High-scale systems** (1000+ microservices)
- **Air-gapped environments** (each region has own vault)
- **Startup phase** (speed more important than audit trail initially)

Example:
```
Team A                    Team B
   │                         │
   ▼                         ▼
Vault-A                  Vault-B
   │                         │
Secrets-A               Secrets-B
```

Challenges:
- Hard to enforce consistent rotation policies
- Audit is difficult across vaults
- Onboarding new services requires understanding multiple vaults

**What I actually do (hybrid):**

```
Centralized Control + Decentralized Operation

┌─────────────────────────────┐
│  Central Policy/Audit Log   │
│  (Vault as audit aggregator)│
└──────────┬──────────────────┘
           │
      [Policy Engine]
           │
      ┌────┴────┬─────────┬─────────┐
      │          │         │         │
      ▼          ▼         ▼         ▼
  Vault-A   Vault-B   Vault-C   Vault-D
   (Team 1) (Team 2) (Team 3) (Team 4)
```

Rules:
1. Local vaults for performance (each team has one)
2. Central policy engine enforces rotation (even though local)
3. Central audit aggregation (replicate logs to central SIEM)
4. Central secrets for cross-team resources (shared database passwords)

This gives me:
- Performance of decentralized (local vault = fast)
- Governance of centralized (central policy)
- Auditability (central log aggregation)

**Real metric I use: Time to Rotate a Secret**

- Bad: 2 hours (manual process, multiple approvers)
- Acceptable: 5 minutes (automated rotation, audit logged)
- Ideal: < 1 minute (fire-and-forget rotation with automated confirmation)

I measure by secret type:
- Database passwords: Must rotate in < 5 minutes (applications could cache old one)
- API keys: Can rotate in 24 hours (no caching)
- Certificates: Must have 30-day overlap (gradual migration)"

---

### Q5: How would you detect and respond to a container escape or privilege escalation attack inside your Kubernetes cluster?

**Answer Expected:**

"Container escapes and privilege escalation are serious because attacker goes from containerized (limited) to host (privileged). Here's my detection + response strategy:

**Detection Layer (Behavioral Signals):**

1. **Kernel audit logging** - Catch syscalls that shouldn't happen from containers
```bash
# auditctl rule: alert if container makes CAP_SYS_ADMIN syscall
auditctl -a always,exit -S all -F container -F comm!=runc -k container-escape

# Alert triggers if:
# - Container process uses privileged syscalls
# - Container accesses host namespace
# - Container loads kernel modules
```

2. **Runtime security** (Falco, Sysdig, Tetragon)
```yaml
# Falco rule: Detect container breakout attempts
- rule: Suspicious Container Namespace Access
  desc: Container accessing host namespace
  condition: >
    spawned_process and 
    container and 
    (proc.name = "nsenter" or 
     proc.name = "unshare" or
     proc.args contains "--mount=" or
     proc.args contains "--net=" or
     proc.args contains "--uts=")
  output: >
    Suspicious namespace access from container
    (user=%user.name container_id=%container.id proc=%proc.name)
  priority: WARNING
```

3. **File integrity monitoring**
```bash
# Alert if attacker modifies host files from container
file_hash=$(sha256sum /etc/shadow)
watch_sha256 /etc/shadow
if [ "$file_hash" != "$(sha256sum /etc/shadow)" ]; then
  alert "Host file modified from container" 
  kill_pod <pod-id>
fi
```

4. **Network anomaly detection**
```bash
# Unusual outbound connections from container
# Normal: Container talks to service mesh (istio-proxy)
# Suspicious: Container opens raw sockets to external IP
# Alert: Reverse shell connection attempt
```

**Response (Automated Containment):**

When escape detected:

```bash
# Step 1: Immediate isolation
kubectl patch pod <compromised-pod> \
  -p '{"spec":{"networkPolicy":"egress-denied"}}'

# Step 2: Preserve forensics (don't kill pod yet)
# Copy container filesystem
kubectl cp <namespace>/<pod>:/bin /tmp/pod-forensics/

# Step 3: Kill pod (remove malicious process)
kubectl delete pod <pod-id> --grace-period=0 --force

# Step 4: Prevent re-infection (image scanning went wrong)
# Update image scan policy to USE THAT IMAGE

# Step 5: Check if lateral movement occurred
# Did compromised pod contact other pods before termination?
kubectl logs -l app=alerting --tail=100 | grep $pod_id

# Step 6: If lateral movement detected: Escalate incident response
# - Coordinate with security team
# - Review all access from affected pod
# - Check audit logs
```

**Prevention (Before Escape Happens):**

1. **Disable privileged mode**
```yaml
spec:
  securityContext:
    privileged: false
    allowPrivilegeEscalation: false  # CRITICAL
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    capabilities:
      drop:
      - ALL
      add:
      - NET_BIND_SERVICE  # Only if needed
```

2. **Restrict container runtime**
```bash
# Don't use overly permissive seccomp profiles
# Use restricted (default denies suspicious calls)
# Whitelist specific syscalls needed by app
```

3. **Pod Security Policies / Pod Security Standards**
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  
  # Restrict capabilities
  requiredDropCapabilities:
  - ALL
  
  # Force non-root
  runAsUser:
    rule: MustRunAsNonRoot
  
  # Restrict apparmor/selinux
  appArmor:
    rule: MustRunAs
  
  # Force read-only filesystem
  readOnlyRootFilesystem: true
```

4. **Supply chain security**
- Scan images for vulnerable tools (curl, wget, bash)
- Use distroless images (remove user-facing tools like bash, sh)
- Sign images so only known-good images can run

**Post-Incident Analysis:**

```bash
# 1. How did attacker get inside container?
# - Vulnerable app? → Fix code
# - Vulnerable dependency? → Update package
# - Image had backdoor? → Change image build process

# 2. How did they escape?
# - CVE in kernel? → Patch kernel
# - Overly permissive SecurityContext? → Fix policy
# - Container runtime vulnerability? → Update container runtime

# 3. Did they spread?
# - Check audit logs for access to other pods
# - Check for lateral movement within cluster
# - Review all network connections

# 4. Prevent recurrence
# - Update SecurityContext template for all pods
# - Increase runtime security monitoring
# - Update image scanning policy
# - Patch kernel if vulnerable
```

**Real-world lesson:**
Escapes are rare with proper controls. Most "escapes" are actually:
- Poor pod network policy (can talk to other pods)
- Loose RBAC (can write to ConfigMaps, access secrets)
- Sidecar compromise (istio-proxy running as root)

Fix those first before worrying about kernel CVEs."

---

### Q6: Walk me through how you'd implement secrets rotation at scale for a system with 1000+ microservices, databases, and APIs.

**Answer Expected:**

"Scale + automation is crucial here. Manual rotation = fail.

**Architecture (Distributed Rotation):**

```
┌─────────────────────────────────────────┐
│   Central Rotation Policy Engine        │
│   (Vault, AWS Secrets Manager)          │
│                                         │
│   ┌─────────────────────────────────┐  │
│   │ Rotation Policies                │  │
│   │ - DB password: every 30 days    │  │
│   │ - API key: every 90 days        │  │
│   │ - JWT: every 24 hours           │  │
│   │ - TLS certs: before expiry      │  │
│   └─────────────────────────────────┘  │
└────────────────┬────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
 Vault      AWS Secrets  Azure Key Vault
 Lambda     Manager       Function
 
 Each manages rotation for:
 - Its associated services
 - Its associated credentials
```

**Implementation Details:**

**1. Rotation Trigger (Event-Driven)**

```python
# Rotation Lambda (triggered by Vault/Secrets Manager)

def lambda_handler(event, context):
    secret_id = event['SecretId']
    rotation_id = event['ClientRequestToken']
    
    # Parse secret metadata
    metadata = get_secret_metadata(secret_id)
    secret_type = metadata['type']  # 'db_password', 'api_key', etc.
    
    try:
        # Step 1: Create new secret
        new_secret = generate_new_secret(secret_type)
        
        # Step 2: Test new secret
        if secret_type == 'db_password':
            test_db_connection(
                host=metadata['db_host'],
                user=metadata['db_user'],
                password=new_secret
            )
        
        # Step 3: Update resource with new secret
        if secret_type == 'api_key':
            rotate_api_key(
                api_provider=metadata['provider'],
                old_key=current_secret,
                new_key=new_secret
            )
        
        # Step 4: Prepare applications for rotation
        # Use Vault "versioning": both old + new secret valid temporarily
        update_vault(secret_id, new_secret, metadata)
        
        # Step 5: Allow grace period for apps to pick up new secret
        time.sleep(300)  # 5 minutes for app cache refresh
        
        # Step 6: Revoke old secret
        revoke_old_secret(secret_type, metadata)
        
        # Step 7: Verify rotation succeeded
        verify_no_more_old_secret_use(secret_id)
        
        return {
            'statusCode': 200,
            'secretId': secret_id,
            'rotationId': rotation_id,
            'status': 'ROTATED'
        }
        
    except Exception as e:
        # Rotation failed - stay with old secret
        # Alert on-call engineer
        send_alert(f"Secret rotation failed: {secret_id} - {str(e)}")
        return {
            'statusCode': 500,
            'secretId': secret_id,
            'status': 'FAILED'
        }
```

**2. Service Discovery (Which services use which secrets)**

```python
# Scan all services to build dependency map

def build_secret_dependency_map():
    """Map: Secret → Services that use it"""
    
    dependencies = {}
    
    # Scan Kubernetes deployments
    for deployment in kubectl.get_deployments():
        env_vars = deployment.spec.containers[0].env
        
        for env_var in env_vars:
            if env_var.value_from.secret_key_ref:
                secret_name = env_var.value_from.secret_key_ref.name
                if secret_name not in dependencies:
                    dependencies[secret_name] = []
                dependencies[secret_name].append({
                    'type': 'kubernetes',
                    'deployment': deployment.name,
                    'env_var': env_var.name
                })
    
    # Scan ECS tasks
    for task in ecs.list_tasks():
        containers = task.container_definitions
        for container in containers:
            for env_var in container.environment:
                if 'valueFrom' in env_var:
                    secret_arn = env_var['valueFrom']
                    if secret_arn not in dependencies:
                        dependencies[secret_arn] = []
                    dependencies[secret_arn].append({
                        'type': 'ecs',
                        'task': task.name,
                        'env_var': env_var['name']
                    })
    
    # Scan Lambda environment variables
    for function in aws_lambda.list_functions():
        env = function.environment.variables
        for var_name, var_value in env.items():
            if 'arn:aws:secretsmanager' in var_value:
                secret_arn = var_value
                dependencies[secret_arn].append({
                    'type': 'lambda',
                    'function': function.name,
                    'env_var': var_name
                })
    
    return dependencies
```

**3. Graceful Rotation (Zero-Downtime)**

```python
# Key: Secret versioning + grace period

def graceful_rotate_database_password(secret_id, metadata):
    """
    Rotate DB password without dropping connections
    """
    
    current_password = get_current_secret(secret_id)
    new_password = generate_random_password(32)
    
    # Step 1: Update database to accept both passwords
    db.execute(f"ALTER USER {metadata['db_user']} IDENTIFIED BY '{new_password}'")
    
    # Step 2: Store new password in Vault (mark as "staging")
    vault.update_secret(
        secret_id,
        password=new_password,
        version='staging',
        revoke_after=300  # Auto-revoke old in 5 minutes
    )
    
    # Step 3: In Kubernetes, trigger pod restart
    # New pods pick up new secret from Vault
    kubectl.delete(f"pods -l secret-version=staging")
    
    # Step 4: Wait for all pods to restart
    # Connections using old password still work (DB accepts both)
    wait_for_all_pods_ready(30 seconds)
    
    # Step 5: Monitor for errors during grace period
    monitor_error_rate(60 seconds)
    if error_rate_normal:
        # Step 6: Revoke old password from database
        db.execute(f"ALTER USER {metadata['db_user']} REVOKE '{current_password}'")
    else:
        # Rollback if problems detected
        db.execute(f"ALTER USER {metadata['db_user']} REVOKE '{new_password}'")
```

**4. Batch Rotation Strategy**

With 1000+ services, rotate in batches:

```python
def batch_rotate_secrets():
    """
    Don't rotate all secrets simultaneously
    Stagger to manage load and catch issues
    """
    
    secrets = get_all_managed_secrets()
    
    # Group by criticality
    batches = {
        'critical': [],      # payment, auth (rotate first, monitor carefully)
        'high': [],          # databases, APIs
        'medium': [],        # internal services
        'low': []            # dev tools, logging
    }
    
    for secret in secrets:
        batches[secret.criticality].append(secret)
    
    # Rotate staggered
    schedule = {
        'critical': '02:00 UTC daily',      # Off-peak, daily
        'high': '03:00 UTC every 3 days',   # Less frequent, later
        'medium': '05:00 UTC weekly',       # Weekly, later still
        'low': '07:00 UTC monthly'          # Monthly, least critical
    }
    
    for criticality, time_window in schedule.items():
        for secret in batches[criticality]:
            schedule_rotation(secret.id, time_window)
```

**5. Monitoring & Observability**

```bash
# Metrics to track:
counter 'secrets.rotation.scheduled'         # How many?
counter 'secrets.rotation.succeeded'         # Success rate?
counter 'secrets.rotation.failed'            # Failures?
histogram 'secrets.rotation.duration'        # How long?
gauge 'secrets.time_since_rotation'          # Age of secrets?

# Alerts:
- rotation_failure_rate > 5%: Page on-call
- rotation_duration > 10 minutes: Investigate
- secret_older_than_max_age: Escalate
- services_unable_to_retrieve_new_secret: Immediate alert
```

**Real Challenges I Address:**

1. **Legacy systems can't handle rotating credentials**
   - Solution: Keep old secret valid for 24 hours during rotation
   
2. **Some databases don't support user password rotation**
   - Solution: Rotate via SSH key or application-level password change
   
3. **Cross-team dependencies (you don't own the service)**
   - Solution: Coordinate rotations, notify teams 24 hours ahead
   
4. **Secrets in multiple locations (sometimes redundantly)**
   - Solution: Audit to find ALL locations, update all simultaneously"

---

### Q7: Describe a production incident where security controls caused an outage. How did you respond?

**Answer Expected:**

"Yes, happened to me. I over-engineered security and caused problems I was trying to prevent.

**The Incident:**

I implemented aggressive rate limiting on API Gateway to prevent brute force:
- 100 requests per IP per minute
- Automatic IP blocking after 5 failed authentication attempts

Problem: Our mobile app updates in bulk background:
- When deployed, app retried failed requests
- Rate limit triggered
- 50,000 users unable to authenticate
- 30-minute outage

I learned this the hard way.

**What I did wrong:**

1. **Didn't involve mobile team in design** - Didn't understand their retry patterns
2. **No gradual rollout** - Deployed to 100% of traffic immediately
3. **No bypass mechanism** - Couldn't adjust limits without redeployment
4. **Poor monitoring** - Didn't see rate limit hits correlated with outage

**How I Responded:**

*Immediate (15 minutes):*
- Identified rate limiting was blocking traffic
- Increased limit to 1000 req/IP/minute (temporary fix)
- Mobile team coordinated app retry strategy

*Short-term (1 hour):*
- Root cause analysis with mobile team
- Understood their deployment process
- Deployed proper fix (higher limits for known-good IPs)
- Verified issue resolved

*Long-term:*
1. **Redesigned rate limiting**
   - Whitelist for known-good sources (AWS API proxies)
   - Gradual escalation instead of hard cutoff
   - Allow burst traffic for deployments

2. **Implemented proper monitoring**
   - Alert if rate limit blocks > X% of traffic
   - Dashboard showing rate limit hits and sources
   - Correlation with deployment events

3. **Added bypass mechanism**
   - Admin console to adjust limits without redeploy
   - Feature flags to enable/disable per service
   - Grace period during major deployments

**Key Lesson:**

The best security control is one that *doesn't break legitimate use*. I became dogmatic about "attacks will look like this" and didn't account for legitimate traffic patterns.

**How I'd Do It Now:**

1. **Understand traffic patterns first**
   - Work with app teams
   - Baseline: how many requests per user?
   - Baselines: how many retries on failure?
   - What's legitimate vs attack?

2. **Design for operational reality**
   - Limits should be loose enough for normal operations
   - Gradual response (alert, then throttle, then block)
   - Always have manual override

3. **Phased rollout**
   - Deploy to 10% shadow traffic first
   - Monitor for false positives
   - Gradually roll out to 100%

4. **Involve teams early**
   - Who uses this API?
   - What are their patterns?
   - Will your controls break their workflows?

**The uncomfortable truth:**
Sometimes you have to accept a small amount of legitimate traffic to block attacks. Perfect security means outages. Good security means figuring out what you can actually live with."

---

### Q8: How do you handle secrets across multiple cloud providers with different key management systems?

**Answer Expected:**

"This is complex because KMS implementations are completely different. Here's how I approach it:

**The Challenge:**

```
AWS (KMS)       ──── Different API ────  Azure (Key Vault)
               ──────── Different API ────  GCP (Cloud KMS)
                    ──── Different API ──  Kubernetes (etcd)
                         ──── Different API ──  On-prem (HSM)
```

All have different:
- API calls
- Rotation mechanisms
- Permission models
- Audit logging formats

**Solution: Abstraction Layer**

```python
class SecretProvider:
    """Unified interface for all KMS providers"""
    
    def get_secret(self, path: str) -> str:
        """Retrieve secret (same interface everywhere)"""
        raise NotImplementedError
    
    def put_secret(self, path: str, value: str) -> None:
        """Store secret"""
        raise NotImplementedError
    
    def rotate_secret(self, path: str) -> None:
        """Rotate secret (implementation varies)"""
        raise NotImplementedError

class AWSSecretsManager(SecretProvider):
    def get_secret(self, path: str) -> str:
        response = self.client.get_secret_value(SecretId=path)
        return response['SecretString']
    
    def put_secret(self, path: str, value: str) -> None:
        self.client.put_secret_value(SecretId=path, SecretString=value)
    
    def rotate_secret(self, path: str) -> None:
        # AWS: Update SecretsManager rotation configuration
        # AWS: Lambda handles actual rotation
        pass

class AzureKeyVault(SecretProvider):
    def get_secret(self, path: str) -> str:
        # Extract vault_name and secret_name from path
        vault_name, secret_name = path.split('/')
        vault_url = f"https://{vault_name}.vault.azure.net"
        
        client = SecretClient(vault_url=vault_url, credential=self.credential)
        return client.get_secret(secret_name).value
    
    def rotate_secret(self, path: str) -> None:
        # Azure: Managed identity handles rotation
        # Azure: Key Vault policy defines rotation schedule
        pass

class GCPCloudKMS(SecretProvider):
    def get_secret(self, path: str) -> str:
        # GCP: Secrets Manager API
        name = f"projects/{self.project}/secrets/{path}/versions/latest"
        response = self.client.access_secret_version(request={"name": name})
        return response.payload.data.decode('UTF-8')
    
    def rotate_secret(self, path: str) -> None:
        # GCP: Cloud Functions handle rotation
        # GCP: Rotation policy defined per secret
        pass

# Usage (same interface regardless of provider)
secret_provider = get_provider(region='us-east-1')  # Auto-detect AWS
db_password = secret_provider.get_secret('prod/database/password')

# Multi-cloud:
aws_provider = AWSSecretsManager(region='us-east-1')
azure_provider = AzureKeyVault(vault_name='my-vault')
gcp_provider = GCPCloudKMS(project='my-project')

password_aws = aws_provider.get_secret('prod/database/password')
password_azure = azure_provider.get_secret('prod/database/password')
password_gcp = gcp_provider.get_secret('prod/database/password')
```

**Key Design Decisions:**

**1. Single source of truth for secrets**
```
┌──────────────────────────────┐
│  HashiCorp Vault (Hub)       │
│  (Single source of truth)    │
└──────────────────────────────┘
         │         │          │
         ▼         ▼          ▼
       AWS      Azure        GCP
     Secrets    Key Vault    KMS
     Manager
     (Sync replicas)
```

Vault syncs to each cloud provider's KMS:
- AWS: Vault stores in AWS Secrets Manager
- Azure: Vault stores in Key Vault (or via managed identity)
- GCP: Vault stores in Secret Manager
- On-prem: Vault stores locally

Benefits:
- Single rotation policy (Vault manages it)
- Single audit log (Vault logs all access)
- Multi-cloud failover (if AWS down, use Azure)

**2. Policy Alignment**

```python
# Define rotation policy once
rotation_policies = {
    'database_password': {
        'ttl': 30 days,
        'providers': ['aws', 'azure', 'gcp'],  # Rotate everywhere
        'before_rotation': 5 days,              # Alert before expiry
        'grace_period': 1 hour                  # Old key still valid
    },
    'api_key': {
        'ttl': 90 days,
        'providers': ['aws', 'azure'],          # Not all providers
        'rotation_handler': 'api_key_rotation_lambda'
    }
}

# Rotation engine implements policy uniformly
for policy_name, policy_config in rotation_policies.items():
    for provider in policy_config['providers']:
        schedule_rotation(policy_name, provider, policy_config)
```

**3. Emergency Override**

```bash
# If one provider is compromised, override without touching others
# E.g., AWS KMS compromised, switch to Azure

rotation_policy.override(
    secret_id='prod/database/password',
    provider='aws',            # Skip this
    use_provider='azure',      # Use this instead
    duration=24 hours          # Until we fix AWS
)

# Applications still use same abstraction:
db_password = secret_provider.get_secret('prod/database/password')
# Will fetch from Azure, not AWS
```

**Real-world lessons:**

1. **Quotas are different**
   - AWS KMS: 10,000 requests/second
   - Azure Key Vault: 2,000 operations/second
   - Implement rate limiting and circuit breakers

2. **Permission models are incompatible**
   - AWS IAM: Resource ARN-based
   - Azure: Role-based at Key Vault level
   - GCP: Predefined roles
   - Map each to your internal RBAC model

3. **Audit logging is different**
   - Some providers don't log all operations
   - Implement custom audit layer
   - Vault provides unified audit logging

4. **Cost is hard to predict**
   - AWS: Charges per request
   - Azure: Charges per operation (higher threshold)
   - GCP: Charges per secret version
   - Monitor and set alerts"

---

### Q9: What's the most critical security metric you track, and why?

**Answer Expected:**

"Mean Time to Detect (MTTD) - how fast we find security issues.

Why it matters most:

```
Attack timeline:
├─ T+0: Attacker gains initial access (one compromised credential)
├─ T+1-6 hours: Lateral movement (exploring, finding valuable data)
├─ T+6-12 hours: Data staging (copying sensitive info)
├─ T+12-24 hours: Exfiltration (transfer data outside)
├─ T+24+ hours: Using stolen data (selling on dark web, blackmailing)

If MTTD > 12 hours: Data already exfiltrated (too late)
If MTTD < 5 minutes: Can stop attacker before damage
```

**How I measure:**

```python
def calculate_mttd(incident_date, detection_date):
    """Mean Time to Detect"""
    return (detection_date - incident_date).total_seconds()

# Track this for every incident
incidents = [
    {
        'name': 'Stolen API key',
        'actual_breach': '2024-03-10 14:32:00',
        'detected': '2024-03-10 14:47:00',
        'mttd': 15 minutes  # Good
    },
    {
        'name': 'Database accessed without auth',
        'actual_breach': '2024-03-11 09:00:00',
        'detected': '2024-03-12 08:00:00',
        'mttd': 23 hours  # Bad - money stolen
    },
    {
        'name': 'Privilege escalation',
        'actual_breach': '2024-03-12 22:15:00',
        'detected': '2024-03-13 07:30:00',
        'mttd': 9 hours  # Concerning
    }
]

# Calculate average MTTD
avg_mttd = sum([i['mttd'] for i in incidents]) / len(incidents)
# 10 hours (unacceptable)
```

**How I improve MTTD:**

1. **Layer 1: Real-time alerting**
```python
# Alert immediately on suspicious activity
alerts = [
    'Failed login attempts > 5 in 1 minute',
    'Privilege escalation attempt',
    'Access to sensitive file outside work hours',
    'Large data transfer to external IP',
    'New user created at 3 AM',
    'Database queried for all customer data'
]

# Implement in SIEM
for alert in alerts:
    siem.create_alert_rule(
        query=alert,
        severity='high',
        action='page_on_call'
    )
```

2. **Layer 2: Anomaly detection**
```python
# ML model learns normal patterns
# Alerts on deviations

behaviors = {
    'normal_users': {
        'login_time': 'business_hours',
        'access_pattern': 'predictable',
        'data_access': 'job_related',
        'query_volume': '< 100/hour'
    }
}

# Alert if user:
# - Logs in at 3 AM (unusual time)
# - Accesses data outside job (finance team reading HR data)
# - Runs 10,000 queries (anomalous volume)
```

3. **Layer 3: Automated response**
```python
# Don't wait for human to read alert
# Act immediately for high-urgency issues

if threat_severity == 'critical':
    # Kill suspicious connection
    kill_session(session_id)
    
    # Isolate user
    revoke_credentials(user_id)
    
    # Preserve evidence
    capture_memory_dump(process_id)
    
    # Alert security team
    escalate_to_security_team()
else:
    # Medium severity: alert and monitor
    create_alert()
    increase_monitoring_level()
```

**My target metrics:**

| Metric | Current | Target | Notes |
|--------|---------|--------|-------|
| MTTD for critical | 45 min | 5 min | Where we are vs where we need to be |
| MTTD for high | 2 hours | 30 min | |
| MTTD for medium | 4 hours | 1 hour | |
| Detection accuracy | 85% | 98% | False positive rate acceptable? |
| Alert response time | 10 min | 2 min | How fast humans act on alerts? |

**Why other metrics matter less (in my opinion):**

- **# of vulnerabilities found:** Big number = good security? No, it's just visibility
- **Compliance score:** 95% compliant = secure? No, compliance ≠ security
- **Security training completion:** Everyone trained = secure? No, training doesn't prevent attacks
- **# of policies:** More policies = more secure? No, policies no one understands don't help

MTTD is the only metric that directly correlates with:
- How much damage attackers can do
- Whether we prevent them or just chase them out
- Real-world security posture

I've been at companies with 'good' metrics (100% patched, all policies documented) that still got breached badly because MTTD was 48 hours."

---

### Q10: You're given budget to improve security. Where would you invest that money and why?

**Answer Expected:**

"I'd prioritize based on ROI and actual risk, not fear.

**Assessment First (Month 1, No budget):**

1. **Where are we bleeding?**
   - Review incidents from past 12 months
   - Calculate cost of each
   - Identify patterns
   
   Example:
   ```
   Incidents:
   ├─ API key leaked: $50K (remediation + 30 day detection delay) × 3 times
   ├─ Supply chain: $2M (customer notification + PR) × 1 time  
   ├─ Insider threat: $0 (detected, contained quickly)
   └─ Network infiltration: $100K (occurred twice, improved response each time)
   ```

2. **Where are we vulnerable?**
   - Attack surface assessment
   - Purple team exercises (simulate attacks)
   - CISO/leadership interviews
   
3. **What keeps executives awake?**
   - Compliance failures
   - Data breaches
   - Ransomware
   - Regulatory fines

**Budget Allocation (Year 1, $500K budget):**

```
My allocation:
├─ 40% - MTTD Improvement ($200K)
│   ├─ SIEM/EDR platform: $80K
│   ├─ Threat hunting service: $60K
│   └─ Team training + tools: $60K
│
├─ 30% - Credential Compromise Prevention ($150K)
│   ├─ Secrets vault (HashiCorp Vault): $40K
│   ├─ Implementation consulting: $60K
│   └─ Rotation automation: $50K
│
├─ 20% - Supply Chain Security ($100K)
│   ├─ SBOM tool + scanning: $30K
│   ├─ Container image registry scanning: $30K
│   └─ Code signing infrastructure: $40K
│
└─ 10% - Compliance/Governance ($50K)
    ├─ Policy drafting workshop: $20K
    └─ Policy enforcement tooling: $30K
```

**Why this order?**

1. **MTTD Improvement is highest ROI**
   - Prevents $2M+ incidents if detected early
   - Applies to ALL threats (not specific to one attack type)
   - Measurable improvement (we can track it)

2. **Credential Compromise is most common**
   - My analysis showed 3 incidents from leaked API keys
   - Each cost $50K+ to remediate
   - Preventable with automated rotation
   - Will stop likely recurrence

3. **Supply Chain Incidents are highest impact**
   - $2M incident showed we have gap
   - One good control here pays for it
   - Emerging risk (increasing industry attention)

4. **Compliance/Governance is table stakes**
   - Must do it (regulatory requirement)
   - But only after we address active risks
   - Compliance without security is security theater

**What I'd *not* spend money on:**

```
❌ Next-gen firewall ($300K)
   - We're not being attacked at network layer
   - Cloud-native architecture (defense-in-depth, not perimeter)
   - Low ROI for our threat landscape

❌ Vulnerability scanner ($50K)
   - Already have free options (Trivy, Snyk free tier)
   - Until we're at 9
```

Implementation (Year 2 onward, Monitor & iterate):**

**Measurement & Adjustment:**

```python
# Track ROI monthly

roi = (
    (incident_cost_prevented - investment_cost) 
    / investment_cost  
) * 100

# Example: SIEM investment
# Cost: $80K
# Incidents prevented: 
#   - 1 breach detected in 5 min (saved $500K remediation)
#   - 1 insider threat stopped early (saved $100K)
# ROI: ($500K + $100K - $80K) / $80K = 650%

# If ROI < 100%: Reassess tool or investment
# If ROI > 300%: Double down or scale
```

**Real-world advice from experience:**

Too many companies spend big on tools nobody uses:
- Buy SIEM, no one configures alerts
- Buy WAF, don't maintain rules
- Buy MFA, require it for 5% of users

**Before spending money on tools:**

1. Do you have process? (How will this tool be used?)
2. Does the team have skills? (or hire/train?)
3. Is there organizational buy-in? (Will users actually use itmit?)

Spend 30% of budget on the tool, 70% on people/process/training.

The best security investment is a skilled security engineer, not the fanciest tool."

---

**Total Interview Preparation Note:**

These questions test:
- **Architectural thinking** (system design, trade-offs)
- **Operational reality** (what actually works in production)
- **Business acumen** (cost/benefit analysis, organization priorities)
- **Humility** (mistakes made, lessons learned)
- **Technical depth** (can you implement what you propose)

The best answers combine theory with real war stories and lessons learned. Pure textbook answers are red flags in senior interviews."
