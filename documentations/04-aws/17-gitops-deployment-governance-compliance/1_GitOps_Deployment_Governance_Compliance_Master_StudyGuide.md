# Senior DevOps Study Guide: GitOps, Deployment Patterns, Governance, Compliance & Production Troubleshooting

**Target Audience:** DevOps Engineers with 5–10+ years of experience  
**Last Updated:** March 2026  
**Scope:** Enterprise-grade GitOps, deployment strategies, governance frameworks, and production operations

---

## Table of Contents

1. [Introduction](#introduction)
   - [Overview](#overview)
   - [Why This Matters in Modern DevOps Platforms](#why-this-matters-in-modern-devops-platforms)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Where This Appears in Cloud Architecture](#where-this-appears-in-cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology & Definitions](#key-terminology--definitions)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices Overview](#best-practices-overview)
   - [Common Misunderstandings](#common-misunderstandings)

3. [GitOps and Deployment Patterns](#gitops-and-deployment-patterns)
   - [GitOps Principles](#gitops-principles)
   - [CI/CD Pipelines](#cicd-pipelines)
   - [Deployment Strategies](#deployment-strategies)
   - [Best Practices](#best-practices)

4. [Governance and Compliance](#governance-and-compliance)
   - [Policy as Code](#policy-as-code)
   - [Security Best Practices](#security-best-practices)
   - [Compliance Frameworks](#compliance-frameworks)
   - [Auditing and Monitoring](#auditing-and-monitoring)
   - [Incident Response](#incident-response)
   - [Tagging Policies and Guardrails](#tagging-policies-and-guardrails)

5. [Production Troubleshooting](#production-troubleshooting)
   - [Common Issues](#common-issues)
   - [Debugging Tools and Techniques](#debugging-tools-and-techniques)
   - [Log Analysis](#log-analysis)
   - [Performance Monitoring](#performance-monitoring)
   - [Root Cause Analysis](#root-cause-analysis)
   - [Network Debugging](#network-debugging)
   - [IAM Permissions Failures](#iam-permissions-failures)
   - [Scaling Failures](#scaling-failures)

6. [Reference Architectures](#reference-architectures)
   - [3-Tier Web Application Architecture](#3-tier-web-application-architecture)
   - [Microservices Infrastructure](#microservices-infrastructure)
   - [Data Pipelines](#data-pipelines)
   - [Serverless Architectures](#serverless-architectures)
   - [High Availability Designs](#high-availability-designs)
   - [HA Kubernetes Setups](#ha-kubernetes-setups)

7. [Real-World Architecture Tradeoffs](#real-world-architecture-tradeoffs)
   - [Cost vs Performance](#cost-vs-performance)
   - [Scalability vs Complexity](#scalability-vs-complexity)
   - [Security vs Usability](#security-vs-usability)
   - [Vendor Lock-in vs Flexibility](#vendor-lock-in-vs-flexibility)
   - [Availability vs Consistency](#availability-vs-consistency)
   - [Case Studies](#case-studies)

8. [Hands-On Scenarios](#hands-on-scenarios)
   - [Scenario 1: Implementing GitOps for Microservices](#scenario-1-implementing-gitops-for-microservices)
   - [Scenario 2: Designing Governance for Multi-Account AWS](#scenario-2-designing-governance-for-multi-account-aws)
   - [Scenario 3: Troubleshooting Production Incidents](#scenario-3-troubleshooting-production-incidents)
   - [Scenario 4: Migrating Legacy Apps to HA Architecture](#scenario-4-migrating-legacy-apps-to-ha-architecture)

9. [Interview Questions](#interview-questions)
   - [GitOps & Deployment](#gitops--deployment)
   - [Governance & Compliance](#governance--compliance)
   - [Production Troubleshooting](#production-troubleshooting)
   - [Architecture & Tradeoffs](#architecture--tradeoffs)

---

## Introduction

### Overview

This study guide addresses the **pillars of modern enterprise DevOps**: how applications are deployed, how infrastructure and security are governed, how production systems are maintained, and the architectural decisions that define enterprise success.

For senior DevOps engineers, these five domains are deeply interconnected:

- **GitOps and Deployment Patterns** provide the **mechanism** for infrastructure changes
- **Governance and Compliance** define the **constraints and controls** on those changes
- **Production Troubleshooting** addresses the **reality** when systems fail
- **Reference Architectures** show the **patterns** that have proven scalable
- **Real-World Tradeoffs** reflect the **business decisions** behind every design choice

This guide is built on the assumption that you've mastered foundational concepts (networking, containerization, basic CI/CD) and are ready to understand **how large organizations operationalize complex systems at scale**.

### Why This Matters in Modern DevOps Platforms

#### 1. **The Velocity-Reliability Tension**
Modern organizations want to deploy frequently (velocity) while maintaining production stability (reliability). GitOps and governance frameworks resolve this tension through:
- Declarative infrastructure (predictability)
- Auditability and rollback capabilities
- Policy enforcement without human gates

#### 2. **Distributed Teams and Separation of Concerns**
In organizations with separate platform, application, and security teams:
- **Platform teams** implement reference architectures and governance
- **Application teams** deploy using those patterns
- **Security teams** audit compliance without blocking all deployments

#### 3. **Scale and Automation**
Managing 100+ microservices, 1000+ AWS resources, and multiple environments requires:
- Declarative state management (drift detection)
- Automated policy enforcement
- Structured troubleshooting methodologies

#### 4. **Regulatory and Business Risk**
- Compliance violations cost millions in fines (HIPAA, PCI-DSS)
- Outages damage reputation and revenue
- Vendor lock-in affects negotiating power and long-term strategy

### Real-World Production Use Cases

#### **Case 1: Financial Services**
A fintech company with strict compliance requirements (PCI-DSS, SOC 2) uses:
- **GitOps + Governance**: Separation of developers and infrastructure changes, audit trails
- **Compliance Automation**: Policy-as-Code (AWS Config, Terraform Cloud) ensures no overly permissive security groups
- **Production Troubleshooting**: Root cause analysis of failed transactions within hours, not days

#### **Case 2: High-Growth SaaS**
A rapidly scaling SaaS platform with 10M+ users faces:
- **Deployment Agility**: Blue/Green deployments allow 50+ deploys/day without downtime
- **Governance at Scale**: Automated cost governance prevents teams from accidentally spinning up expensive resources
- **HA Architecture**: Multi-region, multi-AZ deployments ensure 99.99% availability

#### **Case 3: Healthcare Platform**
HIPAA-regulated patient record system requires:
- **Policy-as-Code**: Ensures encryption at rest/transit, audit logging on all database access
- **Incident Response**: RCA procedures to identify if PHI was exposed within mandated timeframes
- **Architecture Tradeoffs**: Choosing stronger consistency for data integrity over eventual consistency for availability

### Where This Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ORGANIZATION                            │
├─────────────────────────────────────────────────────────────┤
│  Governance & Compliance Layer                              │
│  ├─ Policy-as-Code (OPA, SSM Parameter Store)              │
│  ├─ Tagging & Resource Inventory (AWS Config, Systems Mgr) │
│  ├─ Audit Trails (CloudTrail, VPC Flow Logs)               │
│  └─ Compliance Scanning (AWS Security Hub, Prowler)        │
├─────────────────────────────────────────────────────────────┤
│  GitOps & Deployment Layer                                  │
│  ├─ Source of Truth (Git Repository)                       │
│  ├─ CI/CD Pipeline (GitHub Actions, Jenkins, CodePipeline) │
│  ├─ Deployment Strategy (Helm, Terraform, CloudFormation)  │
│  └─ Environment Promotion (Dev → Staging → Prod)           │
├─────────────────────────────────────────────────────────────┤
│  Application & Infrastructure Layer                         │
│  ├─ Kubernetes Clusters / Container Orchestration          │
│  ├─ Microservices / Serverless Functions                   │
│  ├─ Data Stores (RDS, DynamoDB, S3)                        │
│  ├─ Networking (VPC, Load Balancers, DNS)                  │
│  └─ Storage & Caching (EBS, EFS, ElastiCache)              │
├─────────────────────────────────────────────────────────────┤
│  Observability & Troubleshooting Layer                      │
│  ├─ Metrics (CloudWatch, Prometheus, Datadog)              │
│  ├─ Logs (CloudWatch Logs, ELK, Splunk)                    │
│  ├─ Traces (X-Ray, Jaeger)                                 │
│  └─ Alerting & Incident Response                           │
└─────────────────────────────────────────────────────────────┘
```

Each layer depends on the layers below and feeds into the ones above. A top-tier deployment can fail due to misconfigured governance, poor architecture choices, or inadequate troubleshooting procedures.

---

## Foundational Concepts

### Key Terminology & Definitions

#### **Declarative vs Imperative Infrastructure**
| Aspect | Declarative | Imperative |
|--------|------------|-----------|
| **Definition** | Describe the desired state; system achieves it | Describe steps to reach a state |
| **Tool Example** | Terraform, Kubernetes YAML, CloudFormation | Shell scripts, Chef recipes |
| **Idempotency** | Yes—running multiple times = same result | No—may fail or have side effects |
| **Version Control** | Easy to audit changes | Harder to track what changed |
| **DevOps Principle** | Enables GitOps | Difficult to automate reliably |

**Example:**
```yaml
# Declarative: Define the desired state
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21

# Imperative: Describe the steps
$ kubectl run nginx --image=nginx:1.21
```

#### **GitOps**
**Definition:** Using Git as the single source of truth for both application and infrastructure code. All changes flow through pull requests, enforcement of policies, and automated deployments.

**Core Principles:**
1. Git repositories contain complete, declarative descriptions of desired state
2. Automated controllers detect drift (actual vs desired) and reconcile
3. All changes are auditable, reviewable, and reversible

**Why It Matters:** Enables large teams to deploy safely, maintain compliance, and quickly identify what changed and when.

#### **Drift Detection**
**Definition:** Identifying when actual infrastructure deviates from the declared state.

**Examples of Drift:**
- A security group manual rule added outside of Terraform
- A Lambda function's environment variable changed via AWS Console
- A database parameter group modified by a team member using AWS CLI

**Impact:** Drift violates GitOps principles and makes disaster recovery unreliable.

#### **Policy as Code (PaC)**
**Definition:** Codifying organizational rules as enforceable policies instead of manual processes.

**Examples:**
- "All production resources must be tagged with cost-center"
- "RDS databases must have encryption enabled"
- "EC2 instances must be in a VPC, not EC2-Classic"

**Tools:**
- **Open Policy Agent (OPA)**: Language-agnostic policy engine
- **AWS Config**: AWS-native compliance checking
- **Terraform Sentinel**: Policy enforcement for Terraform plans
- **Kyverno**: Kubernetes-native policy engine

#### **Separation of Duties**
**Definition:** No single person has complete control over both code and infrastructure changes (principle of least privilege applied organizationally).

**Example:**
- Developer writes code and submits PR (merged by peer)
- Pipeline automatically runs infrastructure changes
- Security team audits compliance; only they can manually override policies
- Operations team runs diagnostics but cannot change production code

#### **Blast Radius**
**Definition:** The scope of impact if something goes wrong.

**Examples:**
- A single microservice crash = small blast radius
- A database schema change affecting 10 services = large blast radius
- Deleting an S3 bucket = potentially catastrophic if it contained backups

**Mitigation:**
- Blue/Green deployments (easy rollback)
- Canary deployments (limit impact to percentage of users)
- Staged rollouts (dev → staging → prod)
- Strong IAM policies (prevent accidental deletions)

#### **MTTR and MTTF**
| Metric | Definition | Ideal Target |
|--------|-----------|--------------|
| **MTTR** (Mean Time To Recovery) | How long to fix an incident after detection | Minutes, not hours |
| **MTTF** (Mean Time To Failure) | How long systems run without failure | Months (in reliable systems) |
| **MTTI** (Mean Time To Identify) | How long to detect a problem exists | Seconds (good observability) |

---

### Architecture Fundamentals

#### **The CAP Theorem and Production Implications**

You cannot simultaneously guarantee all three:
- **Consistency:** All reads reflect latest writes
- **Availability:** System always responds (no timeouts)
- **Partition tolerance:** System continues when network segments

**Real-World Implications:**

| System | Tradeoff | Example |
|--------|----------|---------|
| **CP** (Consistency + Partition) | Sacrifices Availability | Banking systems, RDS with synchronous replicas |
| **AP** (Availability + Partition) | Sacrifices Consistency | DynamoDB, Eventually Consistent caches |
| **CA** (Consistency + Availability) | Sacrifices Partition Tolerance | Single-region monoliths (not realistic at scale) |

**Production Decision:** Choose based on business requirements, not technology preference:
- **Financial transactions** → CP (correctness > speed)
- **Social media feeds** → AP (availability > perfect freshness)
- **User authentication** → CP (consistency > latency)

#### **Resilience Patterns**

**1. Circuit Breaker Pattern**
```
Client → (Health Check) → Service
├─ CLOSED (healthy) → Forward requests
├─ OPEN (unhealthy) → Fast-fail
└─ HALF-OPEN (testing recovery) → Allow limited requests
```

**Why:** Prevents cascading failures. If Service B is down, stop sending requests; let it recover.

**2. Bulkheads Pattern**
Isolate critical resources in independent pools.
```
Thread Pool A (User Service) → isolated from
Thread Pool B (Payment Service) → isolated from
Thread Pool C (Notification Service)
```

**Why:** If one service's requests back up, others continue working.

**3. Retry with Exponential Backoff**
```
Attempt 1: 100ms delay
Attempt 2: 200ms delay
Attempt 3: 400ms delay
Attempt 4: 800ms delay
(then give up)
```

**Why:** Temporary failures (network hiccup, brief service restart) recover automatically.

#### **High Availability vs Disaster Recovery**

| Aspect | High Availability (HA) | Disaster Recovery (DR) |
|--------|--------|--------|
| **Scope** | Handles planned/unplanned downtime of components | Handles region-wide or total failure |
| **Deployment** | Multi-AZ, auto-scaling, load balancing | Multi-region, replicated data, failover procedures |
| **Recovery Time** | Seconds to minutes | Hours to days |
| **Cost** | Moderate (2-3x) | High (3-10x) |
| **Example** | RDS Multi-AZ (automatic failover in minutes) | Cross-region RDS replica + Route 53 failover |

---

### Important DevOps Principles

#### **1. Infrastructure as Code (IaC)**
**Principle:** Infrastructure should be version-controlled, reviewed, and tested like application code.

**Benefits:**
- Reproducibility (spin up identical environments)
- Auditability (see exactly what changed)
- Testability (validate configurations before applying)
- Speed (automation vs manual provisioning)

**Tools:** Terraform, CloudFormation, Pulumi, CDK

**Example Problem:** Without IaC, production environment is a "snowflake"—years of manual changes, no one knows the current state, disaster recovery is a nightmare.

#### **2. Continuous Delivery (CD)**
**Principle:** Code changes should be automatically tested, built, and prepared for production deployment. Releases are push-button operations.

**Pipeline Stages:**
```
Code Commit → Build → Unit Tests → Integration Tests → Staging Deploy 
             → Smoke Tests → Manual Approval → Production Deploy
```

**Business Benefit:** Reduce deployment cycle time from months to hours.

#### **3. Observability (Not Just Monitoring)**
**Monitoring:** Is the system healthy? (dashboards, alerts)
**Observability:** Why is it behaving this way? (metrics, logs, traces answering arbitrary questions)

**The Three Pillars:**
1. **Metrics:** Quantitative data (CPU, request latency, error rate)
2. **Logs:** Qualitative records (application events, errors)
3. **Traces:** Request flows (which services handled this request, timing)

**Example:** A 5-minute outage can be diagnosed in minutes with full observability; without it, you're blind.

#### **4. Shift Left**
**Principle:** Move testing and validation earlier in the process.

**Implementation:**
- Static analysis (linting, SAST) before builds
- Unit tests in every commit
- Infrastructure testing (validate Terraform syntax before apply)
- Policy enforcement in CI/CD, not manual reviews

**Impact:** Catches issues when they're cheap to fix (pre-production), not expensive (in production).

#### **5. Immutable Infrastructure**
**Principle:** Never modify deployed infrastructure; always replace it.

**Bad Practice:**
```
SSH into EC2 → apt-get update → change app config → restart service
↓
Each instance is unique (snowflake), hard to replicate bugs
```

**Good Practice:**
```
Update Dockerfile → Re-run CI/CD → New image deployed
Kubernetes rolls out new containers; old ones are garbage-collected
```

**Benefit:** Configuration drift is impossible; rollbacks are trivial (just run old image).

---

### Best Practices Overview

#### **Principle: Reduce Cognitive Load**
Senior engineers manage complexity by making systems predictable.

**Practice 1: Naming Conventions**
```yaml
# Good: Self-documenting
prod-web-app-alb-us-east-1
dev-data-pipeline-rds-us-west-2

# Bad: Ambiguous
server1, database, resource-abc
```

**Practice 2: Consistent Patterns**
```
All microservices deployed via Docker → Kubernetes
All infrastructure defined in Terraform
All configs retrieved from same source (Systems Manager, Vault)
```

**Practice 3: Documentation**
Not pretty diagrams—documentation engineers reference:
```markdown
# Production Runbook: Scaling CPU-Intensive Service

## When to Scale
- CPU > 70% for 5 minutes
- Automatically triggered by ASG

## Manual Scaling (if needed)
$ aws autoscaling set-desired-capacity \
  --auto-scaling-group-name prod-worker-asg \
  --desired-capacity 15

## Rollback
$ aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name prod-worker-asg \
  --desired-capacity 10
```

#### **Principle: Fail Fast, Fail Safe**
**Fail Fast:** Detect problems before they spread.
- Health checks (fast detection)
- Automated tests (catch bugs pre-deployment)

**Fail Safe:** When failures happen, limit damage.
- Circuit breakers (don't cascade failures)
- Rate limiting (prevent thundering herd)
- Graceful degradation (serve read-only mode if writes fail)

#### **Principle: Traceability**
Every production change should be traceable to a business reason.

**Changes → Git Commit → Ticket → JIRA → Business Reason**

Without this, you're flying blind during incidents ("Who changed what and why?").

---

### Common Misunderstandings

#### **Misunderstanding 1: "We use Kubernetes, so we have HA"**
**Reality:** Kubernetes is orchestration; HA is architecture.

**True:** A properly configured Kubernetes cluster with:
- Multi-AZ deployment (resources spread across availability zones)
- Pod disruption budgets (ensures minimum replicas during upgrades)
- Resource limits (prevents one pod from starving others)
- Health checks (readiness and liveness probes)

**False:** Kubernetes alone, without proper configuration, can fail catastrophically.

---

#### **Misunderstanding 2: "Encryption at rest protects against all threats"**
**Reality:** Encryption at rest only protects stolen disks; doesn't prevent:
- SQL injection (attacker reads while data is decrypted)
- Privilege escalation (attacker gains database access)
- Man-in-the-middle attacks (encryption in transit also needed)

**Good Practice:** Defense in depth
```
Network (VPC) → Authentication → Encryption → Application Logic
↓              ↓               ↓              ↓
Firewalls    MFA/IAM       TLS + At-Rest   Input Validation
```

---

#### **Misunderstanding 3: "We don't have security incidents because we didn't detect any"**
**Reality:** You might be blind, not safe.

**Indicators of potential blind spots:**
- No centralized logging (logs scattered across servers)
- Manual access reviews (people don't actually verify access)
- No IAM audits (who has production access? no one knows)
- Compliance = once-yearly check (not continuous)

---

#### **Misunderstanding 4: "Git-based deployment means GitOps"**
**Reality:** GitOps requires:
1. **Declarative** descriptions in Git
2. **Automated reconciliation** (controller continuously verifies actual = desired)
3. **Audit trail** (all changes recorded)
4. **Rollback capability** (revert Git commit = revert deployment)

**Example of NOT GitOps:**
```bash
# Developer manually triggers deployment from CI/CD
$ ./deploy.sh prod
↓
Manual process, hard to audit, hard to rollback
```

**Example of true GitOps:**
```yaml
# Git contains desired state
# ArgoCD controller watches Git + Kubernetes
# Any divergence → ArgoCD auto-reconciles
```

---

#### **Misunderstanding 5: "Compliance is the security team's job"**
**Reality:** Compliance is a business and engineering responsibility.

**Who does what:**
- **Security team:** Defines policies and audit standards
- **Platform team:** Implements enforcement (Policy-as-Code)
- **Application teams:** Follow policies, understand compliance implications
- **Management:** Determines acceptable risk and budget

Silos lead to failure.

---

## Summary: Foundation for the Deeper Dives

With these 20+ concepts internalized, you're ready to understand:
- How GitOps actually works in production
- How governance, once seen as obstacles, enables velocity
- How to diagnose production issues faster
- How to trade off competing priorities (cost vs reliability)
- How senior architects design systems that scale without chaos

The remaining sections build on this foundation, providing patterns, tools, and decision frameworks for each domain.

---

## GitOps and Deployment Patterns

### GitOps Principles

#### **Textual Deep Dive**

**What is GitOps?**

GitOps is an operational framework where Git is the source of truth for both infrastructure and applications. Rather than pushing changes directly to production, all changes are declared in Git, and agents (controllers) continuously reconcile what's declared with what's running.

**Core GitOps Principles (CNCF Definition):**

1. **Declarative:** Infrastructure and application configurations are expressed as code in Git
2. **Versioned & Immutable:** All configuration history is tracked; rollback is a Git revert
3. **Pulled (not Pushed):** Controllers in the cluster/environment pull desired state from Git
4. **Continuously Reconcile:** Controllers detect drift and automatically correct it
5. **Observable & Auditable:** All changes, approvals, and reconciliations are logged

**Why "Pulled" Matters (Critical Distinction):**

| Aspect | Push-based | Pull-based (GitOps) |
|--------|------------|-----------|
| **Failure Mode** | Failed deployment leaves system in unknown state | Drift is auto-corrected; always converges |
| **Blast Radius** | Bad config pushes immediately to all targets | Canary deployments can validate first |
| **Rollback** | Requires new push; if system is down, can't deploy | Git revert fixes it; simpler logic |
| **Security** | Deployment credentials stored in CI/CD (high risk) | Cluster credentials stored on cluster (contained) |
| **Troubleshooting** | "What changed?" = check CI/CD logs | "What changed?" = check Git history |
| **Access Control** | CI/CD approvals | Git + Kubernetes RBAC |

**Internal Working Mechanism:**

```
1. Developer commits change to Git:
   prod.yaml: replicas: 3 → replicas: 5

2. GitOps controller (e.g., ArgoCD, Flux) watches Git commit

3. Controller detects desired state != actual state

4. Controller reconciles:
   - Pulls new config from Git
   - Updates Kubernetes API
   - Kubernetes schedules new pods
   - Monitoring confirms healthy

5. Git history shows:
   - When change happened
   - Who made it (Git author)
   - What changed (diff)
   - Controller logs show reconciliation success
```

**Architecture Role in Modern Deployments:**

```
┌──────────────────────────────────────────────────────────┐
│ GitOps is the Bridge Between CI/CD and Operations        │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  Developer            Git             GitOps Controller  │
│     ▼                  ▼                   ▼              │
│  ┌─────┐    Push    ┌──────┐    Watch  ┌──────┐         │
│  │Code │─────────→ │Repo  │ ←──────── │Cluster
│  └─────┘           └──────┘ ──────→  └──────┘         │
│                              Pull Config  Apply Config    │
│                                                          │
├──────────────────────────────────────────────────────────┤
│ Benefits:                                                │
│  ✓ Developer: Simple Git workflow, no credential exposure
│  ✓ Cluster: Declarative desired state, auto-remediation
│  ✓ Security: Credentials stay in cluster, audit trail
│  ✓ Reliability: Drift detection, automatic rollback
└──────────────────────────────────────────────────────────┘
```

**Production Usage Patterns:**

**Pattern 1: Single GitOps Repo with Environment Branches**
```
gitops-repo/
├── main (production)
├── staging
├── dev
└── hotfix/*

All infrastructure for all environments in single repo.
Easy to promote changes (cherry-pick commits between branches).
Example: PayPal, Mastercard (high compliance requirements).
```

**Pattern 2: Multiple Repos (Monorepo per Environment)**
```
prod-gitops-repo/
├── clusters/
│   ├── us-east-1-prod/
│   ├── eu-west-1-prod/
└── apps/

staging-gitops-repo/ (separate)
dev-gitops-repo/ (separate)

Isolation per environment; changes to prod don't affect dev.
Example: Shopify, Stripe (isolate blast radius).
```

**Pattern 3: App Repo + Infrastructure Repo**
```
app-repo (developer-owned):
├── src/
├── Dockerfile
├── helm/values.yaml
├── .argocd/
│   └── kustomization.yaml ← Triggers ArgoCD on app push

infra-repo (platform-owned):
├── helm/
├── kustomize/
├── terraform/ (for underlying AWS resources)

App changes triggered by app repo; infra changes by infra repo.
Example: Slack, Discord (separate concerns, parallel evolution).
```

**DevOps Best Practices for GitOps:**

**1. Separation of Secrets**
```yaml
# Bad: Secret in Git
apiVersion: v1
kind: Secret
metadata:
  name: db-password
data:
  password: cGFzc3dvcmQxMjM=  # base64 is encryption, it's encoding!
```

```yaml
# Good: Reference secret stored externally
apiVersion: v1
kind: SecretProviderClass
metadata:
  name: aws-secrets
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "prod/db/password"
        objectType: "secretsmanager"
```

**2. GitOps Governance Rules**

```
Rule 1: No direct manual changes
├─ All changes through Git PR
├─ Mandatory code review
└─ Automated tests before merge

Rule 2: Environment Promotion Strategy
├─ Dev: auto-deploy on merge to dev branch
├─ Staging: auto-deploy, but with integration tests
├─ Prod: manual approval required, canary validation

Rule 3: Audit & Traceability
├─ Git commits linked to tickets (commit message → JIRA)
├─ ArgoCD logs all reconciliations
├─ Kubernetes audit logs track all API changes
```

**3. Configuration Drift Prevention**

```bash
# Enable drift detection: GitOps controller periodically checks actual vs desired
argocd app get prod-web --refresh=3h  # Check every 3 hours for drift

# What if manual change is detected?
# Option A: Auto-sync (controller fixes it) - safer
# Option B: Alert + Manual approval - more control
```

**Common Pitfalls:**

**Pitfall 1: Treating GitOps as Just a Deployment Tool**
*Mistake:* Using ArgoCD only for rolling out new containers. Manual infrastructure changes outside Git.

*Reality:* GitOps must encompass:
- Application code (Dockerfile, Helm charts)
- Infrastructure (Terraform, CloudFormation)
- Configuration (ConfigMaps, environment variables)
- Secrets (managed externally, referenced in Git)
- Policies (NetworkPolicies, RBAC)

*Fix:* Keep **everything** in Git. If it's not in Git, it doesn't exist.

**Pitfall 2: Not Handling Secrets Properly**
*Mistake:* Storing secrets in Git (base64 encoded, as if it's encryption).

*Fix:* Use sealed secrets, SOPS, or external secret managers:
```yaml
# Sealed Secrets: ArgoCD-friendly secret management
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: database-password
spec:
  encryptedData:
    password: AgBXrZ9...  # encrypted by cluster sealing key
```

**Pitfall 3: No Rollback Strategy**
*Mistake:* ArgoCD auto-syncing without ability to pause/rollback if issues occur.

*Fix:* 
```bash
# Option 1: Pin to specific commit, bump manually after testing
spec:
  source:
    repoURL: git@github.com:company/gitops.git
    targetRevision: v1.2.5  # Tag, not main; forces deliberate promotion

# Option 2: Use Argo ApplicationSet for progressive rollout
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: progressive-rollout
spec:
  generators:
  - list:
      elements:
      - name: canary
        weight: 10  # 10% of traffic
      - name: primary
        weight: 90
```

---

### CI/CD Pipelines

#### **Textual Deep Dive**

**What is a CI/CD Pipeline?**

A CI/CD pipeline is an automated sequence of stages that:
- **CI (Continuous Integration):** Tests code changes, builds artifacts
- **CD (Continuous Deployment/Delivery):** Deploys artifacts to environments and verifies health

**Modern CI/CD Architecture (Push-based):**

```
Developer Push → VCS Hook → Build → Test → Image Registry → Deploy → Monitor
      ▼              ▼          ▼         ▼         ▼           ▼        ▼
    Git         GitHub Actions Compile  Unit/Int  Docker Hub  K8s/AWS  Datadog
                    /Jenkins      Maven   Tests   Artifact    CloudFront Alerts
```

**Key Stages in Production Pipelines:**

| Stage | Purpose | Tools | Time |
|-------|---------|-------|------|
| **Trigger** | Detect code change | GitHub, GitLab, Bitbucket | Instant |
| **Build** | Compile, lint, scan | Maven, Gradle, npm, Cargo | 2-5 min |
| **Unit Tests** | Test individual components | JUnit, Jest, pytest | 1-3 min |
| **Security Scan** | Find vulnerabilities (SAST) | Snyk, SonarQube, Checkmarx | 2-5 min |
| **Integration Tests** | Test service interactions | TestNG, Cypress, Postman | 5-15 min |
| **Build Image** | Create Docker image | Docker, Kaniko, Buildpacks | 2-5 min |
| **Artifact Registry** | Store image | ECR, Artifactory, Quay | Instant |
| **Deploy Staging** | Deploy to staging env | ArgoCD, CloudFormation, Helm | 2-10 min |
| **Smoke Tests** | Verify basic functionality | Selenium, curl, custom scripts | 2-5 min |
| **Manual Approval** | Human gates for prod | Jenkins, ArgoCD UI, Slack | 0-??? |
| **Deploy Prod** | Deploy to production | ArgoCD, CloudFormation | 2-10 min |
| **Monitoring** | Watch for regressions | CloudWatch, Prometheus, DataDog | Continuous |

**Internal Mechanism: GitHub Actions Example**

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build application
        run: |
          mvn clean package -DskipTests

      - name: Run unit tests
        run: |
          mvn test

      - name: Security scanning (SAST)
        run: |
          curl -L https://github.com/aquasecurity/trivy/releases/download/v0.40.0/trivy_0.40.0_Linux-64bit.tar.gz | tar xz
          ./trivy image gcr.io/myapp:${{ github.sha }}

      - name: Build and push Docker image
        run: |
          docker build -t gcr.io/myapp:${{ github.sha }} .
          docker push gcr.io/myapp:${{ github.sha }}

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to staging
        run: |
          kubectl set image deployment/app-staging \
            app=gcr.io/myapp:${{ github.sha }} \
            --kubeconfig=${{ secrets.STAGING_KUBECONFIG }}

      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/app-staging \
            --kubeconfig=${{ secrets.STAGING_KUBECONFIG }} \
            --timeout=5m

  deploy-production:
    needs: [build, deploy-staging]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: production  # Required approval
    steps:
      - name: Deploy to production
        run: |
          kubectl set image deployment/app-prod \
            app=gcr.io/myapp:${{ github.sha }} \
            --kubeconfig=${{ secrets.PROD_KUBECONFIG }}
```

**Production Usage Patterns:**

**Pattern 1: Feature Branch → Merge → Production**
```
Feature Branch → PR (triggers CI) → Review → Merge → Main → Deploy to Prod
                    ↓
            All tests MUST pass
            Code review REQUIRED
            Security scan MUST pass
```

Best for: Teams with high test coverage, rapid iteration (SaaS, startups)

**Pattern 2: Trunk-based Development with Feature Flags**
```
Main Branch (always deployable)
├─ Feature flags toggle features on/off
├─ Deploys to prod multiple times per day
└─ Rollback = flip feature flag (no revert needed)

Example: Slack, Meta (Continuous Integration → Continuous Delivery)
```

**Pattern 3: Release Branches with Hotfixes**
```
Main (development)
└─ Release-1.2 (production branch)
   ├─ Hotfix-1.2.1 (bug fixes only)
   └─ Tags: v1.2.0, v1.2.1, v1.2.2
```

Best for: Traditional software releases, strict change control (banking, healthcare)

**DevOps Best Practices for CI/CD:**

**1. Fast Feedback Loops**
```
Goal: Know if build is broken in < 5 minutes
├─ Run fast tests first (unit tests: 1-2 min)
├─ Run slow tests in parallel (integration: 10-15 min)
├─ Fail fast: Stop pipeline on first failure
└─ Notify immediately on Slack, email, etc.
```

**2. Artifact Versioning**
```bash
# Bad: No traceability
docker build -t myapp:latest

# Good: Link to commit, build number
docker build -t myapp:${GIT_SHA:0:7}-${BUILD_NUMBER}
# Results: myapp:abc1234-42

# Better: Semantic versioning for releases
docker build -t myapp:v1.2.5

# Also tag with branch for dev/staging
docker build -t myapp:dev-${GIT_SHA:0:7}
```

**3. Security in CI/CD**

```bash
# Scan dependencies for vulnerabilities
$ npm audit
$ mvn dependency-check

# Scan built image for CVEs
$ trivy image myapp:latest

# Static application security testing (SAST)
$ sonarqube-scanner

# Infrastructure as code scanning
$ tfsec terraform/
$ checkov -d kubernetes/
```

**4. Approval Gates for Production**

```yaml
# GitHub Actions: Require approval
environment:
  name: production
  # Deployment must be manually approved in UI

# GitLab: Require manual action
deploy_production:
  stage: deploy
  when: manual  # Click play button to proceed
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

**Common Pitfalls:**

**Pitfall 1: Slow Feedback Loop**
*Mistake:* Tests take 45+ minutes; developers don't wait for results.

*Impact:* Multiple developers deploying untested code simultaneously; production breaks.

*Fix:* 
```
Unit tests (1-2 min) → Build image (3 min) → Integration tests (5 min) = 10 min total
Run integration tests in parallel, not sequentially
```

**Pitfall 2: Skipping Tests in "Emergency" Deployments**
```bash
# Developer: "We need to deploy NOW for customer emergency"
# They bypass tests and tests: skip_tests=true

# Result: Broken code in production, making situation worse
```

*Fix:* Enforce mandatory testing; if it's truly an emergency, rollback is faster than deploying untested code.

**Pitfall 3: Storing Secrets in Environment Variables**
```yaml
# Bad: Secret visible in logs
- name: Deploy
  env:
    DATABASE_PASSWORD: ${{ secrets.DB_PASSWORD }}
  run: ./deploy.sh  # Password might appear in logs
```

```yaml
# Good: Use credential managers
- name: Deploy
  run: |
    aws sts assume-role --role-arn ${{ secrets.PROD_ROLE_ARN }} > /tmp/creds
    ./deploy.sh  # Never expose password
```

---

### Deployment Strategies

#### **Textual Deep Dive**

**What are Deployment Strategies?**

Deployment strategies define how new versions of applications are rolled out to production. Each strategy has different tradeoffs for downtime, risk, rollback speed, and resource consumption.

**Strategy 1: Blue-Green Deployment**

**How It Works:**
```
1. Current version (Blue) handles all traffic
2. Deploy new version (Green) in parallel
3. Run smoke tests on Green (no traffic)
4. Switch traffic: Blue → Green (atomic)
5. Keep Blue for instant rollback
```

**Implementation with Load Balancer:**

```yaml
# Blue-Green in AWS with ALB
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:TARGET_GROUP_GREEN \
  --targets Id=i-0123456789abcdef0 Id=i-0987654321fedcba0

# All traffic still on Blue
# Once Green is healthy, switch target group
aws elbv2 modify-listener \
  --listener-arn arn:aws:elasticloadbalancing:us-east-1:LISTENER \
  --default-actions Type=forward,TargetGroupArn=TARGET_GROUP_GREEN
```

**Kubernetes Implementation:**

```yaml
# Blue deployment (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:v1.0.0

---
# Green deployment (new, initially isolated)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: myapp:v1.1.0

---
# Service points to Blue (initially)
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
    version: blue  # Switch to 'green' when ready
  ports:
  - port: 80
    targetPort: 8080
```

**When to Use Blue-Green:**
- ✅ Database schema changes (need both versions simultaneously)
- ✅ Major version upgrades requiring validation
- ✅ High-risk deployments (move traffic atomically)
- ❌ Resource-constrained environments (requires 2x capacity)
- ❌ Long-running transactions (can't switch mid-request)

**Advantages:**
- Instant rollback (just switch traffic back to Blue)
- Complete validation before traffic switch
- Zero downtime

**Disadvantages:**
- Higher infrastructure cost (need to run both versions)
- Larger blast radius if Green fails and traffic switches to broken version
- Database migrations require coordination

---

**Strategy 2: Canary Deployment**

**How It Works:**
```
1. Gradually shift traffic from old to new version
2. Start with 5% of users on new version
3. Monitor error rates, latency, business metrics
4. If healthy: 25% → 50% → 100%
5. If issues detected: Rollback at current percentage
```

**Traffic Shifting Over Time:**

```
Time 0m:    Old: 100%, New:   0% ✓
Time 5m:    Old:  95%, New:   5% ✓ (Monitor for 5 min)
Time 10m:   Old:  75%, New:  25% ✓
Time 15m:   Old:  50%, New:  50% ✓
Time 20m:   Old:  25%, New:  75% ✓
Time 25m:   Old:   0%, New: 100% ✓ (Rollout complete)
```

**Implementation with Flagger (Kubernetes):**

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp-canary
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  progressDeadlineSeconds: 600
  service:
    port: 80
    targetPort: 8080
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 5
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
  skipAnalysis: false
  maxRetries: 3
```

**Prometheus Metrics:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: flagger-prometheus
data:
  queries.yaml: |
    # Success rate (should be >99%)
    request_success_rate:
      query: |
        sum(rate(http_requests_total{job="istio-proxy",response_code!~"5.*"}[5m]))
        /
        sum(rate(http_requests_total{job="istio-proxy"}[5m]))
    
    # Latency (should be <500ms)
    request_duration:
      query: |
        histogram_quantile(0.95, 
          sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
        )
```

**When to Use Canary:**
- ✅ New features with unknown impact
- ✅ Machine learning model updates (validate accuracy before full rollout)
- ✅ Performance-sensitive changes (monitor latency)
- ✅ Regular deployments with confidence
- ❌ Breaking changes (can't run old + new simultaneously)
- ❌ Database migrations

**Advantages:**
- Low risk (only affects small % of users)
- Real production metrics guide rollout
- Graceful rollback

**Disadvantages:**
- Slower rollout (5-30 min vs instant)
- Requires sophisticated monitoring
- Harder rollback if issues detected after 50%+ traffic shifted

---

**Strategy 3: Rolling Deployment**

**How It Works:**
```
Kubernetes default strategy.
1. Stop 1 old pod
2. Start 1 new pod
3. Wait for new pod to be healthy
4. Repeat until all pods are new version

Controlled by maxUnavailable and maxSurge.
```

**Kubernetes Deployment Config:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Don't take down more than 1 old pod
      maxSurge: 2            # Don't create more than 2 new pods
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:v1.1.0
      readinessProbe:        # Important: declares when pod is ready
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
      livenessProbe:         # Important: detects stuck pods
        httpGet:
          path: /healthz
          port: 8080
        initialDelaySeconds: 15
        periodSeconds: 20
```

**Timeline with maxUnavailable=1, maxSurge=2:**

```
Start:  10 old pods (Replicas=10)

Min 1:  9 old, 1 new (Stop 1 old, start 1 new)
        Waiting for new pod to become ready

Min 2:  8 old, 2 new (Stop 1 old, start 1 new) [maxSurge=2]
        Max 2 new pods running

Min 3:  7 old, 3 new (Continue rolling)
Min 4:  6 old, 4 new
Min 5:  5 old, 5 new
Min 6:  4 old, 6 new
Min 7:  3 old, 7 new
Min 8:  2 old, 8 new
Min 9:  1 old, 9 new
Min 10: 0 old, 10 new (Rollout complete)

Total time: ~10 minutes (depends on pod startup time)
```

**When to Use Rolling:**
- ✅ Backward-compatible changes
- ✅ Internal services (no user-facing changes)
- ✅ Stateless applications
- ❌ Database migrations (need pre-deploy coordination)
- ❌ Breaking API changes

**Advantages:**
- Efficient (no double resource usage like Blue-Green)
- Default Kubernetes behavior
- Gradual rollout (catch issues early)

**Disadvantages:**
- Slower than Blue-Green (10+ minutes)
- Version skew (old and new versions coexist, may cause issues)
- Harder to rollback completely if issues found mid-rollout

---

**Comparison Table:**

| Strategy | Rollback Speed | Risk | Resource Usage | Complexity | Time |
|----------|---|---|---|---|---|
| **Blue-Green** | Instant | High (atomically switches) | 2x resources | Low | Seconds |
| **Canary** | Graceful | Low (incremental rollout) | 1x + 5-50% extra | High | 5-30 min |
| **Rolling** | Slow | Medium | 1x resources | Medium | 10-30 min |

---

### Best Practices for Deployment

#### **Textual Deep Dive**

**1. Testing Before Production**

```
Manual testing is not scalable. Automate everything:

Pyramid of Testing:
        /\
       /  \
      /    \ Manual/Exploratory (1%)
     /──────\
    /        \
   /   E2E   \ End-to-End / Integration (10%)
  /──────────\
 /            \
/   Unit      \ Unit Tests (90%)
──────────────
```

**Implementation:**

```yaml
# Unit tests (run on every commit)
- name: Unit Tests
  run: npm test

# Integration tests (run before staging deploy)
- name: Integration Tests
  run: npm run test:integration

# E2E tests (run after staging deploy, smoke tests on production)
- name: E2E Tests
  run: |
    npm run test:e2e -- \
      --base-url=https://staging.example.com
```

**2. Health Checks (Critical for Zero-Downtime)**

```yaml
# Kubernetes: Readiness probe (is pod ready to serve requests?)
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 2

# Kubernetes: Liveness probe (is pod stuck/crashed?)
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 20
  failureThreshold: 3

# Application code (what should /ready and /health return?)
@app.get("/ready")
def readiness():
    # Check: Can we connect to database?
    # Check: Are dependencies healthy?
    if db.connected and cache.connected:
        return {"status": "ready"}, 200
    else:
        return {"status": "not ready"}, 503

@app.get("/health")
def health():
    # Lightweight check that pod is alive
    return {"status": "alive"}, 200
```

**3. Graceful Shutdown**

```python
# When Kubernetes sends SIGTERM (stopping pod)
# Application should:
# 1. Stop accepting new requests
# 2. Wait for in-flight requests to complete
# 3. Close database connections gracefully
# 4. Exit cleanly

import signal
import time

graceful_shutdown_timeout = 30  # seconds

def signal_handler(sig, frame):
    logger.info(f"Received signal {sig}, shutting down gracefully")
    app.stop_accepting_requests()  # New requests error immediately
    
    # Wait for in-flight requests to complete
    start = time.time()
    while app.in_flight_requests() > 0 and time.time() - start < graceful_shutdown_timeout:
        logger.info(f"Waiting for {app.in_flight_requests()} requests to complete")
        time.sleep(1)
    
    app.close_db_connections()
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)
```

**4. Monitoring Deployment Health**

```yaml
# CloudWatch Alarms for deployment
aws cloudwatch put-metric-alarm \
  --alarm-name HighErrorRatePost-Deployment \
  --alarm-description "Alert if error rate > 1% after deployment" \
  --metric-name ErrorRate \
  --namespace Lambda \
  --statistic Average \
  --period 60 \
  --threshold 1 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:us-east-1:123456:ops-team

# Datadog: Check if new deployment has higher error rate than previous
# If error rate increases by 50%, automatically rollback
```

**5. Progressive Exposure**

```
Don't deploy to all prod servers at once.

Deployment Order:
1. Internal testing (engineers)
2. Staging (QA team)
3. Canary (5% production traffic)
4. Slow rollout (gradually to 100%)
5. Monitor for 1 hour post-deployment

If issues found at any stage: STOP and rollback
```

---

### Practical Code Examples

**Example 1: GitHub Actions Complete CI/CD Pipeline**

```yaml
# .github/workflows/deploy.yml
name: Full CI/CD Pipeline

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: mycompany/myapp

jobs:
  security-scan:
    runs-on: ubuntu-latest
    name: Security Scan
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Snyk Scan
        uses: snyk/actions/docker@master
        with:
          image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  build:
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.image.outputs.digest }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Log in to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=sha,prefix={{branch}}-
      
      - name: Build and push Docker image
        id: image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
          cache-to: type=registry,ref=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max

  deploy-staging:
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/develop'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_STAGING_ROLE }}
          aws-region: us-east-1
      
      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster staging-cluster \
            --service myapp-service \
            --force-new-deployment \
            --region us-east-1
      
      - name: Wait for service stable
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services myapp-service \
            --region us-east-1
      
      - name: Run smoke tests
        run: |
          ./scripts/smoke-tests.sh \
            "https://staging.example.com"

  deploy-production:
    needs: [build, security-scan]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_PROD_ROLE }}
          aws-region: us-east-1
      
      - name: Deploy with Canary (Flagger)
        run: |
          # Update deployment image
          kubectl set image deployment/myapp \
            app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:main-${{ github.sha }} \
            --kubeconfig=${{ secrets.KUBECONFIG_PROD }}
          
          # Flagger will handle canary rollout automatically
      
      - name: Monitor canary progress
        run: |
          kubectl describe canary myapp-canary \
            --kubeconfig=${{ secrets.KUBECONFIG_PROD }}
      
      - name: Notify deployment
        if: always()
        uses: slackapi/slack-github-action@v1
        with:
          webhook-url: ${{ secrets.SLACK_WEBHOOK }}
          payload: |
            {
              "text": "Production Deployment: ${{ job.status }}",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "*Production Deployment*\nStatus: ${{ job.status }}\nCommit: ${{ github.sha }}\nAuthor: ${{ github.actor }}"
                  }
                }
              ]
            }
```

**Example 2: ArgoCD Deployment Manifest**

```yaml
# argocd/myapp-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-prod
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/mycompany/gitops-config
    targetRevision: main  # Always pull from main branch
    path: apps/myapp/prod
    helm:
      releaseName: myapp
      values: |
        image:
          tag: v1.2.5  # Pin version, not 'latest'
        replicas: 5
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true      # Delete resources removed from Git
      selfHeal: false  # Don't auto-fix drift (allow manual changes briefly)
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

**Example 3: Blue-Green Deployment Script**

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

set -e

BLUE_VERSION="v1.0.0"
GREEN_VERSION="v1.1.0"
DEPLOYMENT_NAME="myapp"
NAMESPACE="production"
SERVICE_NAME="myapp-service"

# Step 1: Deploy Green version (isolated, no traffic)
echo "Deploying Green version: $GREEN_VERSION"
kubectl set image deployment/${DEPLOYMENT_NAME}-green \
  app=myapp:${GREEN_VERSION} \
  --namespace=${NAMESPACE}

# Step 2: Wait for rollout
echo "Waiting for Green deployment to be ready..."
kubectl rollout status deployment/${DEPLOYMENT_NAME}-green \
  --namespace=${NAMESPACE} \
  --timeout=5m

# Step 3: Run smoke tests against Green
echo "Running smoke tests against Green..."
GREEN_POD=$(kubectl get pods \
  -l version=green \
  -o jsonpath='{.items[0].metadata.name}' \
  --namespace=${NAMESPACE})

kubectl exec ${GREEN_POD} --namespace=${NAMESPACE} -- \
  curl -f http://localhost:8080/health || {
  echo "Health check failed, rolling back..."
  exit 1
}

# Step 4: Switch traffic from Blue to Green
echo "Switching traffic from Blue to Green..."
kubectl patch service ${SERVICE_NAME} \
  -p '{"spec":{"selector":{"version":"green"}}}' \
  --namespace=${NAMESPACE}

# Step 5: Monitor for 2 minutes
echo "Monitoring for 2 minutes..."
sleep 120

# Check error rate
ERROR_RATE=$(kubectl logs \
  -l version=green \
  --tail=1000 \
  --namespace=${NAMESPACE} | \
  grep -c "ERROR" || true)

if [ $ERROR_RATE -gt 10 ]; then
  echo "High error rate detected! Rolling back to Blue..."
  kubectl patch service ${SERVICE_NAME} \
    -p '{"spec":{"selector":{"version":"blue"}}}' \
    --namespace=${NAMESPACE}
  exit 1
fi

echo "Deployment successful! Cleaning up Blue..."
kubectl scale deployment/${DEPLOYMENT_NAME}-blue \
  --replicas=0 \
  --namespace=${NAMESPACE}

echo "Blue-Green deployment complete!"
```

---

### ASCII Diagrams

**GitOps Pull-Based Architecture:**

```
┌──────────────────────────────────────┐
│      Git Repository (Source Truth)   │
│  ┌──────────────────────────────────┐│
│  │ apps/                            ││
│  │ ├── frontend/kustomization.yaml  ││
│  │ ├── backend/deployment.yaml      ││
│  │ └── database/values.yaml         ││
│  └──────────────────────────────────┘│
└─────────────┬────────────────────────┘
              │
              │ GitOps Controller watches
              │ for changes
              ▼
┌──────────────────────────────────────┐
│   GitOps Controller (ArgoCD/Flux)    │
│  ┌──────────────────────────────────┐│
│  │ 1. Fetch latest from Git         ││
│  │ 2. Parse YAML (Helm/Kustomize)   ││
│  │ 3. Diff: Desired vs Actual       ││
│  │ 4. Apply changes to cluster      ││
│  │ 5. Monitor health                ││
│  └──────────────────────────────────┘│
└─────────────┬────────────────────────┘
              │
              │ Kubernetes API
              ▼
┌──────────────────────────────────────┐
│    Kubernetes Cluster                │
│  ┌──────────────────────────────────┐│
│  │ Deployments:                     ││
│  │ - frontend (3 pods, v1.2.5)      ││
│  │ - backend (5 pods, v2.0.1)       ││
│  │ - database (1 pod, v13.4)        ││
│  │                                  ││
│  │ Services, ConfigMaps, Secrets    ││
│  └──────────────────────────────────┘│
└──────────────────────────────────────┘

Feedback Loop:
Actual State Changes → Controller detects → Reconciles to Desired State
```

**Deployment Strategy Timeline Comparison:**

```
BLUE-GREEN STRATEGY:
────────────────────────────────────────
Blue  ████████ (traffic) → Switch at t=5s
Green        ████████ (warming up)
             ↑              ↑
             Deploy      Switch traffic
Status:      0s             5s            10s
         Deploying      Instant         Rollout
          (silent)      Rollover        Complete

CANARY STRATEGY:
────────────────────────────────────────
Old   ██████░░░░░░ (100% → 0%)
New   ░░░░░░██████ (0% → 100%)
        5%  25% 50% 75% 100%
        ↓   ↓   ↓   ↓   ↓
Status: 2m  4m  6m  8m  10m
      Monitor metrics at each step
        Automatic rollback if error

ROLLING STRATEGY:
────────────────────────────────────────
Old   █████████ (10 pods) → stop 1 by 1
New   ░░░░░░░░░ (0 pods) → start 1 by 1
        ↓
      Pod stops       Pod starts        Stable
        1-2s          5-10s
Status: 0m            5m              10m
      Older           Mixed           Newer
      Version      Versions          Version
```

**CI/CD Pipeline Flow:**

```
Developer
    │
    ▼
┌─────────────────────┐
│  Git Push/PR        │
│  (GitHub/GitLab)    │
└──────────┬──────────┘
           │
           ▼
    ┌──────────────┐
    │ Webhook Trigger
    └──────┬───────┘
           │
    ┌──────▼─────────────┐
    │ Build Stage        │
    │ - Compile code     │
    │ - Run linters      │
    │ - SAST scanning    │
    └──────┬─────────────┘
           │
    ┌──────▼─────────────┐
    │ Test Stage         │
    │ - Unit tests       │
    │ - Integration tests│
    │ - Dependency check │
    └──────┬─────────────┘
           │
    ┌──────▼─────────────┐
    │ Build Image        │
    │ - Docker build     │
    │ - CVE scan (Trivy) │
    │ - Push to registry │
    └──────┬─────────────┘
           │
   ┌───────┴────────┐
   │ Branch Check?  │
   └───┬────────┬───┘
       │        │
     dev      main
       │        │
┌──────▼──┐  ┌──▼──────────────┐
│ Deploy  │  │ Manual Approval? │
│Staging  │  └──┬───────────────┘
└─────────┘     │
           ┌────▼────────┐
           │ Deploy Prod │
           │ (Canary)    │
           └─────────────┘
```

This completes the **GitOps and Deployment Patterns** deep dive section.

---

## Governance and Compliance

### Policy as Code

#### **Textual Deep Dive**

**What is Policy as Code (PaC)?**

Policy as Code is the practice of codifying organizational policies, compliance requirements, and security guardrails as enforceable code that runs in the infrastructure automation pipeline. Instead of manual reviews and approval processes, policies are checked automatically.

**Why Policy as Code Matters:**

```
Before PaC (Manual Review Process):
Developer → Writes Terraform → Submits for approval → Security team reviews manually
                                ↓
                        Takes 1-3 days
                        Subject to human error
                        Inconsistent enforcement
                        Blocks deployments
                        Doesn't scale with team growth

After PaC (Automated Enforcement):
Developer → Writes Terraform → Policy engine validates → Deploy (if passes)
                                ↓
                        Takes seconds
                        Consistent enforcement
                        Fast feedback
                        Self-service
                        Scales effortlessly
```

**Common Policy Categories:**

| Category | Examples | Tools |
|----------|----------|-------|
| **Security** | No overly permissive security groups, encryption required, no public S3 buckets | OPA, Snyk, Checkov |
| **Compliance** | PII field encryption (HIPAA), audit logging (SOC 2), tagging (GDPR), resource limits (cost) | AWS Config, Terraform Sentinel |
| **Cost** | No expensive resources in dev, auto-shutdown schedules, limit instance types | OPA, custom Cost APIs |
| **Architecture** | Use VPCs, don't allow EC2-Classic, mandatory load balancers, multi-AZ required | AWS Config, Terraform Sentinel |
| **Operational** | Naming conventions, resource tagging, region restrictions, auto-scaling policies | OPA, Parameter Store |

**Internal Mechanism:**

```
1. Developer writes Terraform/CloudFormation/Kubernetes YAML
2. CI/CD pipeline runs before applying
3. Policy engine evaluates against defined policies:
   - Parse infrastructure code
   - Compare against policy rules
   - Generate violations report
4. Decisions:
   - PASS: Continue to apply
   - WARN: Log warning, continue
   - FAIL: Block deployment, require override
5. Feedback to developer with specific remediation steps
```

**Production Usage Patterns:**

**Pattern 1: Strict Enforcement (Hard Policies)**
```
Policy Violation → Pipeline FAILS → Deployment BLOCKED
Developer must FIX the code, or request exception, not skip the check

Example: Banking, Healthcare (compliance-heavy industries)
- No resource without encryption
- No public S3 buckets
- All AWS API calls must be logged
```

**Pattern 2: Advisory (Soft Policies)**
```
Policy Warning → Pipeline WARNS → Deployment CONTINUES but LOGGED
Allows business-critical deployments while tracking violations

Example: Startups, fast-moving companies
- Cost warning: "This m5.4xlarge is expensive in dev"
- Tagging warning: "Missing cost-center tag"
- Best practice warning: "Consider using RDS Multi-AZ for reliability"
```

**Common Pitfalls:**

**Pitfall 1: Too Many Policies → Constant Bypass Culture**
*Mistake:* 100+ policies that frequently conflict or block legitimate work.

*Result:* Engineers ignore policies, set `override=true`, defeating the purpose.

*Fix:* Start with 5-10 critical policies, add gradually based on actual incidents.

**Pitfall 2: Policies Without Context**
*Mistake:* Policy prevents something, but no documentation on why or how to fix.

*Example:* Policy blocks `database_encryption = false`, but doesn't explain that DEV can use unencrypted for speed, PROD must be encrypted.

*Fix:* Every policy should include:
```
Policy: Encryption at Rest Mandatory
Severity: HIGH
Environments: Production, Staging
Allowed Exception: Development (review required)
Remediation: Set database_encryption = true
Documentation: https://wiki.company.com/encryption-policy
```

**Pitfall 3: Policies That Contradict**
*Mistake:*
- "All resources must be tagged" (Policy A)
- "Limit tags to <10" (Policy B)
- Compliance requires 15 tags

*Fix:* Document exceptions clearly:
```
Tag Limit: 10
Exception: Compliance tagging can exceed limit (HIPAA, SOC2)
Review: Quarterly audit to ensure exceptions are justified
```

---

### Security Best Practices

#### **Textual Deep Dive**

**IAM: Principle of Least Privilege (PoLP)**

```
Do NOT give:
└─ ec2:*
└─ s3:*
└─ iam:*

DO give:
└─ ec2:DescribeInstances
└─ ec2:StartInstances (only production, only m5.xlarge tagged as "web")
└─ s3:GetObject (only bucket "myapp-logs", only objects matching "logs/2026/*")
```

**Why:** If credentials are compromised, damage is limited to what's explicitly allowed.

**Implementation:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "arn:aws:ec2:us-east-1:123456789012:instance/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        },
        "StringLike": {
          "ec2:ResourceTag/Environment": "production"
        }
      }
    }
  ]
}
```

**Key Security Principles:**

**1. Defense in Depth**

```
Layer 1: Network (VPC, Security Groups)
    ├─ Only allow required protocols/ports
    ├─ Private subnets for databases
    └─ NACLs for additional filtering

Layer 2: Authentication (IAM, RBAC)
    ├─ Unique credentials per principal
    ├─ MFA for sensitive operations
    └─ Service accounts with limited permissions

Layer 3: Encryption (TLS + At-Rest)
    ├─ TLS 1.2+ for all traffic
    ├─ Encryption at rest (KMS, DynamoDB encryption)
    └─ Secrets in Vault, not configuration

Layer 4: Application
    ├─ Input validation
    ├─ SQL parameterization (prevent injection)
    └─ Output encoding (prevent XSS)

Layer 5: Monitoring
    ├─ Audit logs of all access
    ├─ CloudTrail for API calls
    └─ VPC Flow Logs for network
```

**2. Secret Management**

```
Bad Practice:
├─ Hardcoded in source code
├─ Environment variables in Dockerfile
├─ Passed as plain text in logs
└─ Stored in Git repository

Good Practice:
├─ Stored in secret manager (AWS Secrets Manager, HashiCorp Vault)
├─ Accessed at runtime, never stored on disk
├─ Rotated regularly (every 30-90 days)
├─ Audit logged when accessed
└─ Different secret sets per environment
```

**Implementation:**

```python
# Bad
DATABASE_PASSWORD = "super_secret_123"
connection = psycopg2.connect(f"postgresql://admin:{DATABASE_PASSWORD}@db.example.com")

# Good
import boto3
import json

secrets_client = boto3.client('secretsmanager', region_name='us-east-1')
secret = secrets_client.get_secret_value(SecretId='prod/database/password')
credentials = json.loads(secret['SecretString'])

connection = psycopg2.connect(
    host="db.example.com",
    user=credentials['username'],
    password=credentials['password']
)
```

**3. Network Segmentation**

```
Public Subnet (Internet-facing)
├─ ALB / API Gateway
├─ NAT Gateway (for outbound traffic)
└─ Bastion host (jump box for admin access)
    ↓
Private Subnet (Internal services)
├─ Application servers (no direct internet)
├─ Microservices
└─ Internal caches
    ↓
Database Subnet (Isolated)
├─ RDS/Aurora (no internet access)
├─ ElastiCache
└─ Only accessible from app subnet

Security Group Rules:
Public SG:
  ├─ Inbound: HTTP 80, HTTPS 443 (0.0.0.0/0)
  └─ Outbound: Ephemeral ports to App SG

App SG:
  ├─ Inbound: App port (e.g., 8080) from Public SG only
  ├─ Outbound: Database port (5432) to DB SG
  └─ Outbound: 443 to internet (for external APIs)

DB SG:
  ├─ Inbound: Database port (5432) from App SG only
  └─ No outbound (database doesn't initiate connections)
```

**Kubernetes Network Policies:**

```yaml
# Default: DENY all traffic (assume deny)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Allow: Frontend can receive from ALB, send to backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080
```

---

### Compliance Frameworks in Production

#### **Textual Deep Dive**

**HIPAA (Health Insurance Portability and Accountability Act)**

**Key Requirements:**
1. **Encryption:** Data at rest and in transit (AES-256, TLS 1.2+)
2. **Access Controls:** Unique user identification, emergency access procedures
3. **Audit Logging:** All access to PHI (Protected Health Information) logged
4. **Business Associate Agreements:** Vendors must be HIPAA-compliant
5. **Data Integrity & Availability:** Backup/recovery procedures, disaster recovery

**AWS HIPAA Implementation:**

```yaml
# RDS with HIPAA compliance
resource "aws_db_instance" "hipaa_compliant" {
  engine                  = "mysql"
  multi_az                = true
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.hipaa.arn
  
  enabled_cloudwatch_logs_exports = [
    "error", "slowquery", "audit"
  ]
  
  backup_retention_period = 35  # HIPAA: >=30 days
  
  publicly_accessible     = false
}

# CloudTrail (mandatory)
resource "aws_cloudtrail" "hipaa_audit" {
  name           = "hipaa-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.id
  enable_log_file_validation = true
}

# VPC Endpoint for data isolation
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.hipaa.id
  service_name      = "com.amazonaws.us-east-1.s3"
  route_table_ids   = [aws_route_table.private.id]
}
```

**PCI-DSS (Payment Card Industry)**

**Key Requirements:**
1. **Never store full PAN** (Primary Account Number)
2. **Network Segmentation:** CDE (Cardholder Data Environment) isolated
3. **Encryption:** TLS for transit, AES-256 at rest
4. **Access Controls:** Unique IDs, MFA for admin access
5. **Regular Testing:** Quarterly vulnerability scans, annual penetration tests
6. **Vendor Management:** Validate third-party security

**AWS PCI-DSS Implementation:**

```yaml
# Isolated VPC for payment processing
resource "aws_vpc" "pci_cde" {
  cidr_block = "10.0.0.0/16"
}

# Strict security group (no inbound from internet)
resource "aws_security_group" "payment_processor" {
  ingress {
    from_port       = 8443
    to_port         = 8443
    security_groups = [aws_security_group.app_tier.id]  # App tier only
  }
  
  egress {
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["10.0.10.0/24"]  # Payment gateway only (internal)
  }
}

# RDS for tokenization (never store card data)
resource "aws_db_instance" "payment_tokens" {
  engine              = "postgres"
  multi_az            = true
  storage_encrypted   = true
  backup_retention_period = 90
}

# WAF for payment pages
resource "aws_wafv2_web_acl" "payment_pages" {
  default_action {
    allow {}
  }
  
  rule {
    name     = "RateLimitPayment"
    priority = 1
    action { block {} }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
  }
}
```

**GDPR (General Data Protection Regulation)**

**Key Requirements:**
1. **Right to Access:** Users can request their data
2. **Right to be Forgotten:** Users can request deletion
3. **Data Minimization:** Only collect necessary data
4. **Consent Management:** Document user consent
5. **Data Protection Impact Assessment:** Before processing sensitive data
6. **Cross-border Compliance:** Data localization requirements

**GDPR Implementation:**

```python
# Data access request handler
@app.post("/api/user/data-export")
def user_data_export(user_id: str):
    """
    GDPR Right to Access:
    User requests their personal data
    """
    # Retrieve all user data
    user_data = {
        "profile": db_query("SELECT * FROM users WHERE id = ?", user_id),
        "orders": db_query("SELECT * FROM orders WHERE user_id = ?", user_id),
        "interactions": db_query("SELECT * FROM events WHERE user_id = ?", user_id),
    }
    
    # Return as downloadable JSON
    return {
        "data": user_data,
        "export_date": datetime.utcnow().isoformat(),
        # User must confirm they received data within 30 days (compliance tracking)
    }

@app.post("/api/user/{user_id}/delete")
def user_data_deletion(user_id: str):
    """
    GDPR Right to be Forgotten:
    Irreversibly delete all user data
    """
    # Soft delete from production tables
    db_execute("UPDATE users SET deleted_at = NOW() WHERE id = ?", user_id)
    db_execute("UPDATE orders SET user_id = NULL WHERE user_id = ?", user_id)
    
    # Audit log (for compliance, but anonymized)
    audit_log({
        "event": "USER_DELETION_REQUESTED",
        "timestamp": datetime.utcnow().isoformat(),
        "anonymized_user": hash(user_id)  # Can't identify user from log
    })
    
    # Schedule hard delete after retention period
    schedule_hard_delete(user_id, delay_days=90)
    
    return {"status": "deletion_scheduled"}
```

---

### Auditing and Monitoring for Compliance

**What to Log (Compliance Requirements):**

```
Level 1: API Calls (CloudTrail)
├─ Who made the call (IAM principal)
├─ What action (CreateSecurityGroup, PutObject, etc.)
├─ When (timestamp)
├─ What resource (ARN)
├─ Outcome (success/failure)
└─ Source IP

Level 2: Network Access (VPC Flow Logs)
├─ Source IP
├─ Destination IP
├─ Ports used
├─ Protocol
├─ Bytes transferred
└─ Action (ACCEPT/REJECT)

Level 3: Database Access
├─ User connecting
├─ Query executed
├─ Tables accessed
├─ Data modified
└─ Success/failure

Level 4: Application Changes
├─ Code deployments
├─ Configuration changes
├─ User permission changes
└─ Audit log itself changes
```

**Compliance Audit Dashboard (CloudWatch):**

```yaml
resource "aws_cloudwatch_dashboard" "compliance" {
  dashboard_name = "compliance-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/CloudTrail", "DataEvents", {stat = "Sum"}],
            [".", "ManagementEvents", {stat = "Sum"}]
          ]
          title = "API Activity"
        }
      },
      {
        type = "log"
        properties = {
          query = <<-EOQ
            fields @timestamp, userIdentity.principalId, eventName, errorCode
            | filter errorCode like /./
            | stats count() as FailedApiCalls by eventName
            | sort FailedApiCalls desc
          EOQ
          title = "Failed API Calls (Suspicious Activity)"
        }
      }
    ]
  })
}
```

---

This completes the **Governance and Compliance** deep dive section.

---

## Production Troubleshooting

### Common Issues and Debugging

#### **Textual Deep Dive**

**Issue 1: Sudden Latency Spike (SLA Violation)**

**Symptoms:**
- Response time increases from 100ms to 2s
- Users complaining "website is slow"
- Error rates still low (not crashing, just slow)

**Root Cause Checklist:**

```
1. Database Performance
   ├─ CPU usage > 80%? (Query optimization needed)
   ├─ Disk I/O at limit?
   ├─ Connection pool exhausted? (idle connections)
   └─ Slow query log: SELECT * FROM slow_queries ORDER BY duration DESC

2. Network Issues
   ├─ VPC Flow Logs: Check packet loss
   ├─ NAT gateway bandwidth exceeded?
   ├─ DNS resolution slow? (Check Route 53 metrics)
   └─ TLS handshake overhead? (Session resumption disabled?)

3. Application Issues
   ├─ Memory leak? (Java Heap growing over time)
   ├─ Lock contention? (Threads blocked on synchronized resources)
   ├─ Garbage collection pauses? (Full GC causing 500ms+ stalls)
   └─ External API slowness? (Timeout cascade)

4. Infrastructure
   ├─ CPU throttling? (Burstable instance hitting credit limit)
   ├─ Network ACL rules misconfigured?
   ├─ Security group rules changed recently?
   └─ Resource scaling triggered? (adding new servers)
```

**Diagnosis Process:**

```bash
# Step 1: Identify if it's application or infrastructure
$ kubectl top nodes                    # Node CPU/memory
$ kubectl top pods -A                  # Pod resource usage
$ kubectl describe node <node-name>    # Resource pressure?

# Step 2: Check if database is bottleneck
$ aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=prod-db \
  --start-time 2026-03-10T14:00:00Z \
  --end-time 2026-03-10T15:00:00Z \
  --period 60 \
  --statistics Maximum

# Step 3: Check if external calls are slow
$ tail -f /var/log/app/requests.log | \
  grep "external_api" | \
  awk '{print $NF}' | \
  sort -n | \
  tail -20  # Show slowest external API calls

# Step 4: Check for queries piling up
$ SELECT count(*), state FROM INFORMATION_SCHEMA.PROCESSLIST GROUP BY state;
# If "Waiting for lock" count > 10, lock contention issue
```

**Fix:**

```sql
-- Identify blocking queries
SELECT * FROM INFORMATION_SCHEMA.InnoDB_locks;

-- Kill blocking query if necessary
KILL <process_id>;

-- Analyze slow query
EXPLAIN SELECT * FROM large_table WHERE not_indexed_column = 'value';
-- If no index, add one:
CREATE INDEX idx_not_indexed ON large_table(not_indexed_column);

-- Check for connections not in use
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE TIME > 300 AND COMMAND = 'Sleep';
-- If excess idle connections, reduce pool size or add idle timeout
```

---

**Issue 2: Deployment Failed - Services Not Starting**

**Symptoms:**
- Deployment shows "Pending" for >10 minutes
- Pods stuck in ImagePullBackOff or CrashLoopBackOff

**Debugging:**

```bash
# Check pod status
$ kubectl describe pod <pod-name>
Events:
  Type     Reason            Age   Message
  ----     ------            ---   -------
  Warning  Failed            45s   Failed to pull image "myapp:latest": rpc error: code = Unknown desc = Error response from daemon: pull access denied

# Root cause: Image doesn't exist or credentials invalid
# Fix:
aws ecr list-images --repository-name myapp  # Verify image exists
aws ecr describe-images --repository-name myapp --image-ids imageTag=latest

# If image exists but not found:
$ kubectl create secret docker-registry ecr-secret \
  --docker-server=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password)

# Update deployment to use secret
imagePullSecrets:
- name: ecr-secret
```

---

**Issue 3: Memory Leak - Gradually Increasing Memory**

**Symptoms:**
- Pod memory goes from 512MB → 2GB over 48 hours
- Eventually OOMKilled (Out of Memory)

**Root Cause Analysis:**

```python
# JVM memory heap dump analysis
def analyze_heap_dump(heap_dump_file):
    # 1. Trigger heap dump
    jcmd <pid> GC.heap_dump /tmp/heap.hprof
    
    # 2. Download and analyze
    jhat /tmp/heap.hprof
    # Navigate to: http://localhost:7000/
    # Look for "Histogram of Objects by Class"
    # Which classes are taking most memory?
    
    # Example findings:
    # char[] (1.2GB) - usually String cache issue
    # Foo$Bar (800MB) - custom object holding references
    
    # 3. Find reference path
    # "References" tab shows what's keeping object alive
    # Trace back to root cause (usually static cache)
```

**Fix (Example: Cache not evicting):**

```java
// Bad: Unbounded cache grows forever
private static final Map<String, Result> cache = new HashMap<>();

public Result expensiveComputation(String key) {
    if (!cache.containsKey(key)) {
        cache.put(key, compute(key));  // Never removes old entries
    }
    return cache.get(key);
}

// Good: Bounded cache with eviction
private static final Map<String, Result> cache = new LinkedHashMap<String, Result>() {
    @Override
    protected boolean removeEldestEntry(Map.Entry eldest) {
        return size() > 1000;  // Keep only 1000 entries
    }
};

// Or use Caffeine cache (better)
private static final Cache<String, Result> cache = Caffeine.newBuilder()
    .maximumSize(10000)
    .expireAfterWrite(1, TimeUnit.HOURS)
    .build();
```

---

### Debugging Tools & Techniques

#### **Essential Kubernetes Debugging Tools**

```bash
# 1. Pod logs (application output)
kubectl logs <pod-name> --tail=100 -f            # Follow logs
kubectl logs <pod-name> --previous               # Crashed pod logs
kubectl logs -l app=myapp --all-containers       # All containers of label

# 2. Pod events
kubectl describe pod <pod-name>                  # Shows what happened
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# 3. Exec into pod
kubectl exec -it <pod-name> -- /bin/sh          # Interactive shell
kubectl exec <pod-name> -- curl http://localhost:8080/health

# 4. Port forwarding (access localhost:3000 → pod:8080)
kubectl port-forward <pod-name> 3000:8080 &
curl http://localhost:3000/metrics

# 5. Copy files from pod
kubectl cp <namespace>/<pod-name>:/var/log/app.log ./app.log

# 6. Detailed pod information
kubectl get pod <pod-name> -o yaml                # Full manifest
kubectl get pod <pod-name> -o json               # JSON output

# 7. Watch pod as it starts then crashes
kubectl get pods -w                              # Watch for changes

# 8. Check resource requests/limits
kubectl describe node <node-name>                # Shows allocated resources

# 9. Check node disk pressure
kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo {} && kubectl describe node {} | grep -A 5 Allocated'
```

#### **AWS Debugging Tools**

```bash
# CloudTrail: Who did what?
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=prod-app-sg \
  --max-results 10

# CloudWatch Logs: Application errors
aws logs filter-log-events \
  --log-group-name /aws/ecs/prod-app \
  --filter-pattern "ERROR" \
  --query 'events[?timestamp > `1646945400000`]'

# VPC Flow Logs: Network connectivity
aws ec2 describe-flow-logs --filter "Name=resource-id,Values=<instance-id>"

# SystemsManager Session Manager: SSH without bastion
aws ssm start-session --target i-1234567890abcdef0

# CloudWatch Synthetics: Proactively test endpoints
```

---

### Log Analysis Techniques

**Finding Signal in Noise:**

```bash
# Problem: 10GB log file, need to find crash
# Solution: Binary search approach

# 1. Find start of incident
grep -n "ERROR.*OutOfMemory" large.log | head -1
# Line 5000000

# Check 2.5M (middle)
sed -n '2500000p' large.log

# Continue binary search until found

# Better: Use specialized tools
jq filter for JSON
awk for text processing
mlr (Miller) for structured data
```

**Log Aggregation Pattern:**

```
Application Logs → Filebeat → Elasticsearch → Kibana
     ↓                          ↓
  Human-readable      Full-text search
  Distributed tracing  Alerting rules
```

**Example Kibana Query for Incident:**

```
# Find error spike at specific time
POST /app_logs-*/_search
{
  "bool": {
    "must": [
      {"range": {"@timestamp": {"gte": "2026-03-10T14:00:00Z", "lte": "2026-03-10T14:10:00Z"}}},
      {"term": {"level": "ERROR"}},
      {"wildcard": {"message": "*timeout*"}}
    ]
  }
}

Results: 5000 timeout errors in 10 minutes (normal: 10/min)
Clustered during Kubernetes pod eviction?
```

---

### Root Cause Analysis (RCA) Process

**The 5 Whys Technique:**

```
Incident: Payment processing failed for 50 customers, lost $5000

Why 1: Payment API returned 500 error
Why 2: Database query took 60s, then connection timeout
Why 3: Full table scan on unindexed column due to JOIN
Why 4: New feature deployed yesterday added JOIN to payment query
Why 5: Feature didn't go through code review (reviewer sick that day)

Root Cause: Inadequate code review process + missing performance tests

Prevention:
├─ Add EXPLAIN PLAN analysis to code review checklist
├─ Run performance tests on all database queries (>100ms = review)
├─ Cross-train review team (don't depend on single person)
└─ Archive review process (automated, can't be ignored)
```

---

### Practical Code Examples

**Example 1: Structured Logging for Troubleshooting**

```python
import json
import logging
import time
from datetime import datetime
from functools import wraps

# Enhanced logger that outputs JSON (Kibana-friendly)
class StructuredLogger:
    def __init__(self, name):
        self.logger = logging.getLogger(name)
        handler = logging.StreamHandler()
        self.logger.addHandler(handler)
        self.logger.setLevel(logging.DEBUG)
    
    def log(self, level, message, **context):
        """Log structured event"""
        event = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": level,
            "message": message,
            "service": "payment-service",
            "version": "v2.1.5",
            **context  # Pass additional context
        }
        self.logger.log(getattr(logging, level), json.dumps(event))

logger = StructuredLogger("payment_api")

def trace_api_call(func):
    """Decorator that logs API calls with latency"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        request_id = kwargs.get('request_id', 'unknown')
        
        try:
            result = func(*args, **kwargs)
            duration_ms = (time.time() - start) * 1000
            
            logger.log("INFO", f"API call succeeded",
                      endpoint=func.__name__,
                      request_id=request_id,
                      duration_ms=int(duration_ms),
                      status="success")
            
            return result
        
        except Exception as e:
            duration_ms = (time.time() - start) * 1000
            
            logger.log("ERROR", f"API call failed: {str(e)}",
                      endpoint=func.__name__,
                      request_id=request_id,
                      duration_ms=int(duration_ms),
                      status="error",
                      error_type=type(e).__name__,
                      stacktrace=traceback.format_exc())
            
            raise
    
    return wrapper

@trace_api_call
def process_payment(amount, user_id, request_id):
    """Example payment processing"""
    logger.log("DEBUG", "Processing payment",
              amount=amount,
              user_id=user_id,
              request_id=request_id)
    
    # ... payment logic
    
    return {"status": "success"}
```

**Example 2: Performance Profiling in Production**

```python
# Lightweight profiling without significant overhead
import cProfile
import pstats
from io import StringIO
import functools

def profile_function(func):
    """Profile function execution (1% sampling)"""
    call_count = {'count': 0}
    profiler = cProfile.Profile()
    
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        call_count['count'] += 1
        
        # Only profile 1% of calls (reduce overhead)
        if call_count['count'] % 100 != 0:
            return func(*args, **kwargs)
        
        profiler.enable()
        try:
            return func(*args, **kwargs)
        finally:
            profiler.disable()
            
            # Print top 10 slowest functions
            s = StringIO()
            ps = pstats.Stats(profiler, stream=s).sort_stats('cumulative')
            ps.print_stats(10)
            logger.debug(f"Profile results:\n{s.getvalue()}")
    
    return wrapper

@profile_function
def expensive_computation(data):
    # Automatically profiled (1% sampling rate)
    return sum(expensive_operation(x) for x in data)
```

---

This completes the **Production Troubleshooting** deep dive section.

---

## Reference Architectures

### 3-Tier Web Application Architecture

#### **Textual Deep Dive**

**Architecture Overview:**

```
┌─────────────────────────────────────────────────┐
│            Internet Users (0.0.0.0/0)           │
└────────────────────┬────────────────────────────┘
                     │
        ┌────────────▼─────────────┐
        │   CloudFront CDN         │
        │  (Caching, DDoS shield)  │
        └────────────┬─────────────┘
                     │
        ┌────────────▼─────────────────────────┐
        │   Application Load Balancer (ALB)    │
        │   (Distributes traffic, terminates   │
        │    TLS, checks health)               │
        └────────────┬─────────────────────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───▼────┐   ┌──────▼─────┐   ┌──────▼─────┐
│ App 1  │   │   App 2    │   │  App 3     │
│  Tier  │   │  (Kubernetes)  │ (Kubernetes)
│ (ECS)  │   │   Pod1     │   │  Pod2      │
└────────┘   └────────────┘   └────────────┘
    │            │                 │
    └────────────┼─────────────────┘
                 │
        ┌────────▼────────┐
        │   RDS Database  │
        │   (Multi-AZ)    │
        │  ┌──────────┐   │
        │  │ Primary  │   │
        │  └──────────┘   │
        │  ┌──────────┐   │
        │  │Standby   │   │
        │  │(Failover)│   │
        │  └──────────┘   │
        └─────────────────┘
```

**Why 3-Tier:**

1. **Presentation Tier:** Separates UI logic from business logic
2. **Application Tier:** Stateless, scales horizontally
3. **Data Tier:** Centralized, consistent state

**Benefits:**
- Scalability: Add more app servers without changing database
- Maintainability: Changes in one tier don't affect others
- Security: Database not exposed to internet

---

### Microservices Architecture

```
┌────────────────────────────────────────────────┐
│       API Gateway (Authentication, Rate Limit) │
└────────┬───────────────────────────┬───────────┘
         │                           │
┌────────▼───────┐    ┌──────────────▼────────┐
│ UserService    │    │ OrderService           │
│ ├─ User DB     │    │ ├─ Orders DB           │
│ └─ Cache       │    │ ├─ Message Queue       │
└────────┬───────┘    │ └─ Cache               │
         │            └──────────┬─────────────┘
         │                       │
    ┌────▼─────────┐    ┌────────▼──────┐
    │ PaymentService│    │ProductService │
    │ ├─ Payments DB│    │ ├─ Catalog DB │
    │ └─ External   │    │ └─ Cache      │
    │   Payment GW  │    └───────────────┘
    └──────────────┘
         │
┌────────▼──────────────────┐
│  Observability Stack       │
│  ├─ Logs (ELK)            │
│  ├─ Metrics (Prometheus)  │
│  ├─ Traces (Jaeger)       │
│  └─ Alerts (AlertManager) │
└───────────────────────────┘
```

**Microservices Characteristics:**

| Aspect | Monolith | Microservices |
|--------|----------|---------------|
| **Scalability** | Scale entire app | Scale individual services |
| **Deployment** | 1 deployment = all features | Deploy services independently |
| **Tech Stack** | Single technology | Polyglot (different langs/frameworks) |
| **Database** | Shared | Per-service (data autonomy) |
| **Fault Isolation** | One failure = all down | One service failure = others continue |
| **Latency** | In-process (fast) | Network calls (slower, retry logic needed) |
| **Complexity** | Simpler codebase | Distributed debugging harder |

---

### Data Pipeline Architecture

```
┌─────────────────────────────────────────────────────┐
│ Data Sources (APIs, Databases, Files)               │
└──────────┬──────────────────────────────────────────┘
           │
    ┌──────▼──────┐
    │ Data Ingestion│
    │ (Kafka, Firehose)
    └──────┬──────┘
           │
┌──────────▼─────────────────────┐
│ Stream Processing / Batch ETL  │
│ (Spark, Flink, Lambda)         │
│ ├─ Cleaning                    │
│ ├─ Transformation              │
│ ├─ Deduplication               │
│ └─ Enrichment                  │
└──────────┬─────────────────────┘
           │
    ┌──────▼──────────┐
    │ Data Lake       │
    │ (S3, Data Ops)  │
    │ (Raw Data Store)│
    └──────┬──────────┘
           │
    ┌──────▼──────────────┐
    │ Data Warehouse      │
    │ (Redshift, Snowflake)
    │ (Optimized for BI)  │
    └──────┬───────────────┘
           │
    ┌──────▼──────────────┐
    │ BI Tools            │
    │ (Tableau, PowerBI)  │
    │ Dashboards & Reports│
    └─────────────────────┘
```

**Key Patterns:**

1. **Lambda Architecture** (Batch + Stream)
   - Batch: Historical accuracy, lower compute
   - Stream: Real-time, higher latency tolerance

2. **Kappa Architecture** (Stream only)
   - Single source of truth: streaming pipeline
   - Batch = re-processing streams

---

### Serverless Architecture

```
┌─────────────────────────────────────┐
│  API Gateway / HTTP Trigger        │
└──────────────┬──────────────────────┘
               │
    ┌──────────▼──────────┐
    │ Lambda Function     │
    │ (Auth Handler)      │
    └──────────┬──────────┘
               │
    ┌──────────▼──────────────────┐
    │ Lambda Functions             │
    │ ├─ Get User Data            │
    │ ├─ Update Profile           │
    │ └─ Process Payment          │
    └──────────┬───────────────────┘
               │
    ┌──────────▼──────────┐
    │ DynamoDB / RDS      │
    │ (Serverless DB)     │
    └─────────────────────┘
```

**Serverless Benefits:**
- No server management (AWS manages scaling)
- Pay-per-use (only pay for execution time)
- Natural auto-scaling
- Rapid deployment

**Serverless Challenges:**
- Cold starts (100-200ms for new container)
- Execution time limits (15 min timeout)
- Harder debugging (distributed)
- Cost can be high for sustained traffic

---

### High Availability Designs

#### **Multi-AZ (Availability Zone) Redundancy**

```
AWS Region (US-East-1)
├─ AZ 1A
│  ├─ RDS Primary
│  ├─ EC2 Instance
│  └─ ALB
│
├─ AZ 1B  
│  ├─ RDS Standby (Automated failover)
│  ├─ EC2 Instance
│  └─ ALB
│
└─ AZ 1C
   ├─ RDS Backup Read Replica
   ├─ EC2 Instance
   └─ ALB

If AZ 1A fails:
1. RDS failover (1-2 minutes)
2. ALB health check removes 1A instances
3. Traffic automatically routes to 1B and 1C
4. Users experience ~2-5 second latency spike
```

---

### HA Kubernetes Setup

```
Control Plane (HA - Multiple Masters)
├─ API Server 1 (etcd backup)
├─ API Server 2 (etcd backup)
├─ Scheduler 1
├─ Scheduler 2
├─ Controller Manager 1
├─ Controller Manager 2
└─ etcd cluster (3 nodes minimum for quorum)

Worker Nodes (Distributed across AZs)
├─ AZ 1: Node 1, Node 2
├─ AZ 2: Node 3, Node 4
└─ AZ 3: Node 5, Node 6

Pod Distribution:
├─ Pod Disruption Budgets (PDB): Ensure min replicas during maintenance
├─ Affinity Rules: Spread replicas across nodes/zones
└─ Network Policies: Isolated tenants, prevent cascading failures
```

**HA Kubernetes YAML:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-ha
spec:
  replicas: 6  # At least 2 per AZ
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - myapp
            topologyKey: topology.kubernetes.io/zone  # Spread across AZs
      containers:
      - name: myapp
        image: myapp:v1.0.0
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5

---
# Prevent disruptions during rolling updates
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 3  # Always keep at least 3 replicas
  selector:
    matchLabels:
      app: myapp
```

---

This completes the **Reference Architectures** section.

---

## Real-World Architecture Tradeoffs

### Cost vs Performance

**Scenario: Web application serving 1M requests/day**

```
Option 1: Cheap (≈$200/month)
├─ Single t3.small RDS instance
├─ Single t3.small EC2 + ALB
├─ No caching or CDN
├─ Single AZ (no HA)
├─ Manual backups
├─ Performance: Average 2-3 second response times
└─ Risk: Any failure = complete outage

Option 2: Balanced (≈$1500/month)
├─ RDS Multi-AZ (db.t3.medium)
├─ Auto Scaling Group 2-5 t3.medium instances
├─ CloudFront CDN
├─ ElastiCache for sessions
├─ Automated backups
├─ Performance: <500ms p99 latency
└─ Risk: Service degrades over time to 95% availability

Option 3: Premium (≈$5000+/month)
├─ RDS Aurora (db.r5.large, Multi-AZ)
├─ Auto Scaling 5-20 instances across 3 AZs
├─ Global CloudFront + S3 origin
├─ Multi-region DynamoDB + DAX cache
├─ Cross-region read replicas
├─ Automated backups + cross-region copies
├─ Performance: <100ms p99 latency globally
└─ Risk: <0.01% downtime (99.99% availability)
```

**Decision Framework:**

| Scenario | Recommendation |
|----------|---|
| **Startup MVP** | Option 1 (spend on features, not infrastructure) |
| **Growing SaaS** | Option 2 (customers demand reliability) |
| **Enterprise** | Option 3 (SLA breaches cost millions) |
| **Black Friday Sales** | Option 3 temporarily, scale back Jan 1 |

---

### Scalability vs Complexity

```
Monolith (One application)
├─ Complexity: Low
├─ Scalability: Hard (scale entire app for one feature)
├─ Deployment: 1 change = full regression testing
├─ Team: 1 team, shared responsibility
└─ Best for: Small teams, <10 developers

Microservices (Services per feature)
├─ Complexity: High (distributed debugging, eventual consistency)
├─ Scalability: Easy (scale payment service without scaling auth)
├─ Deployment: Independent, faster iteration
├─ Team: Each team owns service
└─ Best for: Large teams (>20 devs), complex domains

Question: When to adopt microservices?
Rule of thumb: 
- <5 developers: Monolith
- 5-15 developers: Monolith (start journey toward micro)
- >15 developers: Microservices (organizational topology)
```

---

### Security vs Usability

**Example: API Rate Limiting**

```
Strict Security:
├─ Rate limit: 10 requests/minute per user
├─ IP blocking after 3 failed logins
├─ MFA required for all operations
├─ User impact: Legitimate users frustrated, can't use app
└─ Actual security: Minimal (attackers can CAPTCHA bypass)

Balanced:
├─ Rate limit: 100 requests/minute
├─ Progressive delays (first fail: 1s, second: 10s, etc.)
├─ MFA for sensitive operations (not every login)
├─ User impact: Acceptable
└─ Actual security: Good (catches automated attacks)

User-Centric (Bad):
├─ No rate limiting
├─ No MFA
├─ Weak passwords allowed
├─ User impact: Maximum convenience
└─ Actual security: Terrible (easily compromised)
```

---

### Vendor Lock-in vs Flexibility

```
AWS-Only Architecture
├─ Services: RDS, Lambda, DynamoDB, CloudFront, etc.
├─ Benefits:
│  ├─ Native integration (IAM, VPC, CloudWatch)
│  ├─ AWS support teams
│  └─ Managed services (less operational overhead)
├─ Risks:
│  ├─ Can't easily migrate to GCP/Azure
│  ├─ Pricing increases, can't negotiate
│  └─ Feature requests depend on AWS prioritization
└─ Cost: Low operational cost, high strategic cost

Multi-Cloud / Cloud-Agnostic
├─ Services: Kubernetes (any cloud), Terraform (portable)
├─ Benefits:
│  ├─ Switch clouds if pricing becomes unfavorable
│  ├─ Negotiate with multiple vendors
│  └─ Avoid single vendor risk
├─ Risks:
│  ├─ More operational complexity
│  ├─ Managed services unavailable (run self-hosted)
│  └─ Terraform drift into different clouds
└─ Cost: Higher operational cost, lower strategic cost

Decision:
├─ Startup? Go AWS-only (speed matters, lock-in risk low)
├─ Enterprise? Multi-cloud (lock-in risk high, complexity acceptable)
└─ Cost-sensitive? Cloud-agnostic (we can self-host)
```

---

### Availability vs Consistency

**Banking Example: Transfer $100 from Account A to Account B**

```
HIGH CONSISTENCY (Immediately consistent)
├─ Deduct $100 from Account A
├─ Wait for confirmation: "A has <$100"
├─ Add $100 to Account B
├─ Wait for confirmation: "B has +$100"
├─ Result: Transaction appears instant
├─ Downside: High latency (geo-distributed, retry logic needed)
├─ Use: Financial systems, ATMs (single region)

EVENTUAL CONSISTENCY (Eventually consistent)
├─ Deduct $100 from Account A → return immediately
├─ Background job adds $100 to Account B (can take seconds)
├─ During window: Total money temporarily incorrect ($100 missing)
├─ Downside: User confusion, compliance issues
├─ Upside: Super fast, highly available
├─ Use: Social media (likes, follows where accuracy isn't critical)

SAGA PATTERN (Distributed transaction)
├─ Step 1: Reserve $100 from Account A
├─ Step 2: Add $100 to Account B
├─ If Step 2 fails: Compensating transaction reverses Step 1
├─ Result: Both accounts eventually consistent (no missing money)
├─ Complexity: Medium
├─ Use: Inter-service transactions (microservices)
```

---

### Case Studies

**Case Study 1: Netflix Outage 2015**

**What happened:** DNS resolution failures caused cascading outages

**Root cause:** Over-reliance on internal DNS (not AWS Route 53)

**Fix:**
```
Before:
App → Internal DNS (single point of failure)
    ↓
    EC2 service discovery

After:
App → Route 53 (managed, HA)
   → EC2 service discovery + fallback
   → Local cache (survive transient DNS failures)
```

**Lesson:** Don't assume managed service infrastructure is highly available.

---

**Case Study 2: Stripe PCI-DSS Compliance**

**Challenge:** Process credit cards without storing PANs

**Solution Architecture:**

```
Client Browser
    ↓
Stripe.js (clientside tokenization)
    ↓
Stripe API (creates token)
    ↓
Your Server (never sees card number)
    ├─ Receives token: "tok_visa_4242"
    └─ Charges token (not card)

Result:
├─ You never handle card data (PCI-DSS not your problem)
├─ Stripe handles compliance (their problem, their insurance)
├─ Faster deployment (no compliance audit)
└─ Lower liability
```

**Decision Framework:**
- Handle sensitive data yourself? (Healthcare, financial) = Compliance burden
- Let vendor handle it? (Payment, auth) = Offload compliance

---

This completes the **Real-World Architecture Tradeoffs** section.

---

## Hands-On Scenarios

### Scenario 1: Implementing GitOps for Microservices Deployment

**Business Context:**
You're a Senior DevOps Engineer at a SaaS company with 8 microservices, 3 environments (dev/staging/prod), and 25+ engineers. Currently, deployments are manual (developers SSH to servers, run scripts). You want to shift to GitOps for consistency and audit trails.

**Your Task:**

1. **Design the GitOps Repository Structure**
   
   Challenge: Keep 3 environments (dev/staging/prod) in one repo without copy-paste configuration.
   
   ```
   gitops-config/
   ├── base/
   │   ├── payments/
   │   │   ├── kustomization.yaml (common across all envs)
   │   │   ├── deployment.yaml
   │   │   ├── service.yaml
   │   │   └── configmap.yaml
   │   ├── users/
   │   ├── orders/
   │   └── ...
   ├── overlays/
   │   ├── dev/
   │   │   ├── kustomization.yaml (3 replicas, small resources)
   │   │   └── patches.yaml
   │   ├── staging/
   │   │   ├── kustomization.yaml (5 replicas, medium resources)
   │   │   └── patches.yaml
   │   └── prod/
   │       ├── kustomization.yaml (10 replicas, large resources, HA)
   │       └── patches.yaml
   └── README.md
   ```
   
   **Your Solution:**
   - Use Kustomize overlays (avoid Helm complexity)
   - Base layer has service definitions
   - Overlays override replicas, resources, image tags
   - Single image promotion: build once, deploy to all envs

2. **Set Up ArgoCD Controller**
   
   ```bash
   # Steps:
   # 1. Install ArgoCD in Kubernetes
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   
   # 2. Create Kubernetes secrets for private Git repo
   kubectl create secret generic argocd-repo-creds-github \
     --from-literal=type=git \
     --from-literal=url=https://github.com/company/gitops-config \
     --from-literal=password=$(cat /path/to/github/token) \
     -n argocd
   
   # 3. Create ArgoCD Application for production
   cat <<EOF | kubectl apply -f -
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: payments-prod
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/company/gitops-config
       targetRevision: main
       path: overlays/prod/payments
     destination:
       server: https://kubernetes.default.svc
       namespace: payments-prod
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   EOF
   ```

3. **Handle Secrets Securely**
   
   Problem: Don't store secrets in Git.
   
   Solution: Use Sealed Secrets or External Secrets Operator
   
   ```bash
   # Install Sealed Secrets controller
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
   
   # Encrypt a secret for production
   echo -n mypassword | kubectl create secret generic db-password \
     --dry-run=client \
     --from-file=password=/dev/stdin \
     -o yaml | kubeseal -n prod -o yaml > db-password-sealed.yaml
   
   # db-password-sealed.yaml can now go in Git
   # Only production cluster can decrypt it
   ```

4. **Test the GitOps Flow**
   
   ```bash
   # Simulation:
   # 1. Developer updates image tag in Git
   git commit -m "Update payments to v2.5.0"
   git push origin main
   
   # 2. ArgoCD detects change (polls every 3m or via webhook)
   # 3. ArgoCD applies to Kubernetes
   kubectl get deployment payments-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
   # Output: payments:v2.5.0
   
   # 4. Verify health checks
   kubectl get replicaset -l app=payments
   # All replicas healthy? Deployment successful.
   
   # 5. Test canary (optional)
   # Use Flagger to automatically test 5% traffic
   kubectl get canary payments-prod
   # Status: Promoting to 25%...
   ```

5. **Incident: Manual Change Made to Production**
   
   ```bash
   # Someone manually changed replicas via kubectl edit
   kubectl edit deployment payments-prod
   # Changed replicas: 10 -> 3 (reduced capacity!)
   
   # GitOps detects drift:
   argocd app get payments-prod
   # Status: OutOfSync (Desired: 10 replicas, Actual: 3)
   
   # Auto-sync fixes it (or alert if sync disabled)
   argocd app sync payments-prod
   # Syncing... Desired state restored.
   ```

**Success Criteria:**
- ✅ All 8 services deploy via GitOps
- ✅ Developers make changes in Git, no SSH
- ✅ Rollback = Git revert (30 seconds)
- ✅ Full audit trail in Git history and ArgoCD logs
- ✅ <2 minute deploy-to-production time

---

### Scenario 2: Designing Governance for Multi-Account AWS org

**Business Context:**
Your organization has 15 AWS accounts (dev, staging, prod, data-science, ml-platform, security, etc.). Each account has different compliance requirements (HIPAA for healthcare data, PCI-DSS for payments). Engineers are provisioning resources ad-hoc, leading to:
- Inconsistent encryption
- Public S3 buckets with sensitive data
- EC2 instances with overly permissive security groups
- Cost overruns (unused resources not cleaned up)

Your task: Design governance controls to prevent misconfiguration without blocking legitimate work.

**Your Solution:**

1. **AWS Organizations + SCPs (Service Control Policies)**
   
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "DenyPublicS3",
         "Effect": "Deny",
         "Action": [
           "s3:PutAccountPublicAccessBlock"
         ],
         "Resource": "*",
         "Condition": {
           "Bool": {
             "s3:x-amz-acl": [
              "public-read",
              "public-read-write",
              "authenticated-read"
            ]
           }
         }
       },
       {
         "Sid": "RequireEncryption",
         "Effect": "Deny",
         "Action": [
           "rds:CreateDBInstance",
           "rds:ModifyDBInstance"
         ],
         "Resource": "*",
         "Condition": {
           "Bool": {
             "rds:StorageEncrypted": "false"
           }
         }
       }
     ]
   }
   ```

2. **AWS Config Rules for Continuous Compliance**
   
   ```bash
   # Deploy Config Rules via CloudFormation
   aws cloudformation create-stack \
     --stack-name config-rules \
     --template-body file://config-rules.yaml \
     --capabilities CAPABILITY_IAM
   ```
   
   **config-rules.yaml** (sample):
   ```yaml
   Resources:
     EncryptedVolumesRule:
       Type: AWS::Config::ConfigRule
       Properties:
         ConfigRuleName: encrypted-volumes
         Source:
           Owner: AWS
           SourceIdentifier: ENCRYPTED_VOLUMES
         Scope:
           ComplianceResourceTypes:
             - AWS::EC2::Volume
     
     SecurityGroupIngressSSHRule:
       Type: AWS::Config::ConfigRule
       Properties:
         ConfigRuleName: restricted-ssh
         Source:
           Owner: AWS
           SourceIdentifier: RESTRICTED_INCOMING_TRAFFIC
         InputParameters:
           allowedProtocol: "tcp"
           allowedPorts: "22"
           allowedCIDR: "10.0.0.0/8"  # Internal only
   ```

3. **Tagging Policy + Cost Allocation**
   
   ```yaml
   # Enforce tags on all resources
   TaggingPolicy:
     required_tags:
       - cost_center (numeric: project billing)
       - environment (prod/staging/dev)
       - owner (email: who's responsible)
       - data_classification (public/internal/confidential/restricted)
       - compliance (hipaa/pci/sox/none)
   
   # Example: Enforce via boto3 Lambda
   def validate_tags(event):
       ec2 = boto3.client('ec2')
       instance_id = event['detail']['instance-id']
       tags = ec2.describe_tags(
           Filters=[{'Name': 'resource-id', 'Values': [instance_id]}]
       )['Tags']
       
       required = ['cost_center', 'environment', 'owner']
       provided = {tag['Key'] for tag in tags}
       
       if not provided >= set(required):
           # Terminate untagged instances after 24h warning
           send_notification(f"Instance {instance_id} missing tags")
   ```

4. **Progressive Enforcement (Not All-or-Nothing)**
   
   ```
   Phase 1 (Week 1): Monitoring Only
   ├─ Deploy Config Rules
   ├─ Send daily "out of compliance" reports
   ├─ No enforcement (warning stage)
   └─ Goal: Engineer awareness
   
   Phase 2 (Week 3): Soft Blocks
   ├─ Terraform plans fail if violate policy
   ├─ But can override with approval + ticket
   ├─ Logs all overrides for audit
   └─ Goal: Reduce non-compliant resources 80%
   
   Phase 3 (Week 5): Hard Blocks
   ├─ SCPs prevent non-compliant API calls
   ├─ No workarounds
   ├─ Governance team approves exceptions
   └─ Goal: Maintain compliance
   ```

5. **Incident: Prod Encryption Disabled**
   
   ```
   Alert: CloudTrail logs RDS instance created without encryption
   
   Sequence:
   1. AWS Config detects: RDS instance "prod-database" not encrypted
   2. Config triggers Lambda remediation (automated)
   3. Lambda stops the instance, takes snapshot, restarts with encryption
   4. Governance team contacted (if remediation fails)
   5. RCA: Why wasn't SCP enforced? (Was it new account not attached to policy?)
   
   Prevention: Verify SCP applied to all accounts weekly
   ```

**Success Criteria:**
- ✅ 100% of prod resources encrypted
- ✅ No public S3 buckets (except approved CDN origin)
- ✅ Tags 95%+ compliant
- ✅ Cost visibility per team (billing alerts at threshold)
- ✅ Compliance audit passed with no findings

---

### Scenario 3: Troubleshooting Production Outage (RCA Exercise)

**Incident Timeline:**

```
14:32 - Alerts fire: Error rate 50% (normal: <0.1%)
14:33 - On-call engineer paged
14:35 - Customer reports: "Payment page timeout"
14:40 - Investigation begins
14:50 - Root cause identified
15:05 - Fix deployed
15:10 - All green, customer notified
```

**Your Task: Find Root Cause in 15 Minutes**

**Given Information:**
1. Error spike started exactly at 14:32
2. All services showing normal CPU/memory
3. Database CPU at 95%
4. Error messages: "Timeout waiting for database connection"

**Investigation Steps:**

```bash
# Step 1: Confirm database is bottleneck
$ kubectl logs <payment-service-pod> --tail=50
# Output: "dial tcp: i/o timeout: database pool exhausted"

# Step 2: Check database connections
mysql> SELECT COUNT(*) FROM INFORMATION_SCHEMA.PROCESSLIST;
# Output: 500 connections (and max is 500!)

# Step 3: Find what queries running
mysql> SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE TIME > 30;
# SELECT customer_orders FROM orders WHERE customer_id IN (...)
# This query takes 30+ seconds (slow!)

# Step 4: Check if recent code change
$ git log --oneline --since="30 minutes ago"
# Commit: "Add customer order summary endpoint" (14:20)

# Step 5: Analyze the new query
$ EXPLAIN SELECT customer_orders FROM orders WHERE customer_id IN (...);
# Type: ALL (full table scan!)
# Rows: 50M (scanning entire orders table!)

# Root cause identified: Missing index on customer_id
```

**Immediate Mitigation (not fix):**

```bash
# Option 1: Revert the change (fastest)
git revert <commit-hash>
git push origin main
# Redeploy (5 minutes)
# Service recovers immediately

# Option 2: Add index while services running (safer for data)
mysql> CREATE INDEX idx_customer_id ON orders(customer_id);
# (Takes 2 minutes on 50M rows)
# Then deploy code change
```

**Permanent Fix:**

```sql
-- Add missing index
ALTER TABLE orders ADD INDEX idx_customer_id (customer_id);

-- Update query to use index hint (ensure query planner chooses it)
SELECT customer_orders FROM orders USE INDEX (idx_customer_id) 
WHERE customer_id IN (...)

-- Verify query now completes in milliseconds
EXPLAIN SELECT ...;
-- Type: ref (index lookup!)
-- Rows: 100 (instead of 50M!)
```

**Post-Incident:**

```
RCA Document:
├─ Timeline: 14:32 → 15:10 (38 min outage)
├─ Root Cause: Missing index on hot query path
├─ Why it wasn't caught:
│  ├─ Code review didn't check EXPLAIN plans
│  ├─ Load tests used small dataset (index not needed at scale)
│  └─ No automated performance regression testing
├─ Permanent fixes:
│  ├─ Add database query review in code review process
│  ├─ Load tests with 10M+ rows (realistic)
│  ├─ Prometheus alerts on p99 query latency
│  └─ Slow query log monitored automatically
└─ Prevention: Similar issues unlikely (fix addresses root)
```

**Success Criteria:**
- ✅ RCA completed within 1 hour
- ✅ Root cause clear (not guessing)
- ✅ Permanent fix prevents recurrence
- ✅ Team learns from incident (blameless culture)

---

### Scenario 4: Migrating Legacy Monolith to HA Kubernetes

**Current State:**
- Monolithic Java application (500K lines)
- Runs on 3 m5.xlarge EC2 instances (manual scaling)
- MySQL database (single master, manual backups)
- Deployed once per month (change control process)
- 99.5% availability SLA (acceptable for now)

**Goal:**
- Containerize and run on Kubernetes
- Achieve 99.99% availability (reduce downtime from 3 hours/year to 52 minutes/year)
- Deploy multiple times per day

**Your Plan:**

**Phase 1: Containerization (Weeks 1-2)**

```dockerfile
# Dockerfile
FROM openjdk:17-slim

WORKDIR /app

# Copy application JAR
COPY target/myapp.jar .

# Health check (critical for K8s)
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Graceful shutdown signal handler
EXPOSE 8080
ENV JAVA_OPTS="-Xmx2g -Xms2g"

ENTRYPOINT ["java", "-jar", "myapp.jar"]
```

```bash
# Build and test
docker build -t myapp:v1.0.0 .
docker run -p 8080:8080 myapp:v1.0.0

# Verify health check works
curl http://localhost:8080/health
# {"status": "UP", "dependencies": {"database": "UP"}}
```

**Phase 2: Kubernetes Deployment (Weeks 3-4)**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
spec:
  replicas: 9  # 3 per AZ (HA)
  selector:
    matchLabels:
      app: myapp
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 3        # Add 3 pods at a time
      maxUnavailable: 0  # Keep all pods available
  template:
    metadata:
      labels:
        app: myapp
    spec:
      affinity:
        podAntiAffinity:  # Spread across nodes
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - myapp
            topologyKey: topology.kubernetes.io/zone
      containers:
      - name: myapp
        image: myapp:v1.0.0
        ports:
        - containerPort: 8080
        readinessProbe:  # When pod ready to serve traffic
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 10
          failureThreshold: 3
        livenessProbe:   # When to restart pod
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          failureThreshold: 3
        resources:
          requests:
            memory: "2Gi"
            cpu: "1"
          limits:
            memory: "4Gi"
            cpu: "2"

---
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 6  # Keep at least 6 pods during node maintenance
  selector:
    matchLabels:
      app: myapp
```

**Phase 3: Database Migration (Weeks 5-6)**

```
Old: Single m5.xlarge instance (manual backups)
New: Aurora MySQL (Multi-AZ with automatic failover)

Migration steps:
1. Create Aurora read replica from existing RDS
2. Let replication catch up (data parity check)
3. Switch application to read from replica (traffic during off-hours)
4. Binlog stop, verify data matches
5. Swap primary/replica
6. Monitor for issues (24 hours)
7. Decommission old instance
```

```yaml
# Terraform for Aurora setup
resource "aws_rds_cluster" "myapp_aurora" {
  cluster_identifier      = "myapp-aurora"
  engine                  = "aurora-mysql"
  engine_version          = "8.0"
  database_name           = "myapp"
  master_username         = "admin"
  master_password         = random_password.db_password.result
  
  # Multi-AZ (automatic failover)
  availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  db_subnet_group_name    = aws_db_subnet_group.private.name
  
  # Backups
  backup_retention_period = 35
  preferred_backup_window = "03:00-04:00"
  
  # Encryption
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.database.arn
  
  # Enhanced monitoring
  enabled_cloudwatch_logs_exports = ["error", "slowquery", "audit"]
}
```

**Phase 4: Testing & Validation (Weeks 7-8)**

```bash
# Chaos testing: Kill a pod
kubectl delete pod myapp-deployment-abc123xyz

# Expected: K8s immediately schedules replacement
# Verify: Traffic still flowing, error rate < 0.1%

# Test database failover
# Manually stop Aurora primary instance
# Expected: 30-60 second failover time
# Verify: Application reconnects, no data loss

# Load test
ab -n 100000 -c 100 https://myapp.example.com/
# Expected: Throughput unchanged (thanks to Kubernetes scaling)
```

**Phase 5: Deployment to Production (Week 9)**

```bash
# Gradual rollout
# Blue-Green: Old monolith on EC2, new Kubernetes parallel

Day 1: Canary
├─ 5% traffic to Kubernetes
├─ 95% to EC2
└─ Monitor: error rate, latency, dependency health

Day 2: Slow rollout
├─ 25% → 50% → 75%
├─ Each step: wait 24 hours, monitor metrics
└─ If issues: revert (5 min rollback)

Day 3: 100%
├─ All traffic to Kubernetes
├─ Keep EC2 cluster running another week (just in case)
└─ If critical issue: switch back (5 min)

Day 10: Decommission EC2
├─ Save ~$4000/month in EC2 costs
├─ Increase CapEx for Kubernetes control plane
├─ Net: +10% cost (high availability worth it)
```

**Success Criteria:**
- ✅ 99.99% uptime during first month on K8s
- ✅ Deploy 10x/day (vs 1x/month)
- ✅ Zero customer-facing incidents
- ✅ Team confident with Kubernetes operations
- ✅ Cost within 20% of EC2 baseline

---

## Interview Questions

### GitOps & Deployment

**Q1: You're reviewing a junior engineer's ArgoCD setup. They set `spec.syncPolicy.automated.selfHeal: true`. What is true and what's a risk?**

**Expected Answer:**
- ✅ True: ArgoCD will automatically fix drift (actual state ≠ desired state in Git)
- ✅ True: Provides strong consistency guarantees
- ⚠️ Risk: If GitOps repo has bug (wrong replicas, broken image), ArgoCD will enforce it immediately without operator review
- ✅ Right approach: `selfHeal: true` for non-critical envs; `manual sync` + approval for production

**Follow-up:** *How would you handle the case where someone manually changes production to debug, and you don't want GitOps to revert it immediately?*
- Disable autoSync temporarily
- Or: Use GitOps operator that supports "pause" functionality
- Or: Require breaking-glass process (SSM Session Manager, audit log)

---

**Q2: You're designing the ImageTag strategy for GitOps. Should you use `latest` tag or pinned versions?**

**Expected Answer:**
```
Latest tag (BAD for production):
├─ Recreates ImagePullPolicy: Always
├─ But different clusters might get different images
├─ Not reproducible (can't rollback)
└─ Violates GitOps principle: "Git = source of truth"

Pinned tags (GOOD):
├─ e.g., deployment.yaml has image: payments:v2.5.0
├─ Git history shows exactly what version deployed
├─ Rollback = git revert (trivial)
├─ Requires CI/CD to bump tag in Git
└─ GitOps principle satisfied
```

**Follow-up:** *How do you automate bumping the image tag in Git during CI/CD?*
- Option 1: CI/CD commits updated deployment.yaml to Git
- Option 2: Use CI/CD to create Git tag (v2.5.0), GitOps watches tags
- Option 3: Use Renovate bot (auto-updates images in Git)

---

**Q3: Compare Blue-Green vs Canary deployments. When would you use each?**

**Expected Answer:**

| Scenario | Best Strategy | Why |
|----------|---|---|
| Database schema changes | Blue-Green | Need both old + new code for migration |
| Breaking API changes | Blue-Green | Old clients can't work with new version |
| Machine learning model updates | Canary | Validate accuracy on real production traffic |
| Internal service change | Rolling | Backward compatible, efficient |
| High-risk, unknown impact | Canary | Minimize blast radius |
| Performance optimization | Canary | Verify latency improvements on real users |
| Bug fix to critical service | Blue-Green | Need instant rollback capability |

---

### Governance & Compliance

**Q4: Your organization is implementing PCI-DSS compliance. A developer asks: "Can we store full credit card numbers in our database for faster transactions?" How do you respond?**

**Expected Answer:**
```
NO (PCI-DSS requirement 3.2.1: Never store full PAN)

Correct approach:
├─ Use tokenization (Stripe, Square, payment processor)
├─ App never sees card numbers
├─ Payment processor returns token: "tok_visa_4242"
├─ Charge against token, not card
├─ PCI scope reduced (compliance burden on processor, not us)
└─ Developer avoids massive compliance liability

Red flag: "We can just encrypt it"
├─ Still violates PCI-DSS (specifies "don't store")
├─ Increases company PCI scope if breach occurs
├─ Insurance might not cover (non-compliance)
```

**Follow-up:** *What AWS service can we use to isolate payment processing?*
- VPC: Payment processing in private subnet (no internet access)
- VPC Endpoint: Communicate with payment gateway privately (no NAT)
- Security Groups: Cardholder data env only accepts from app tier
- KMS: Encrypt secrets at rest
- Secrets Manager: Rotate credentials automatically

---

**Q5: You discover that 30% of prod resources are missing the `cost_center` tag (required by policy). Engineers are resisting. How do you enforce it without blocking all deployments?**

**Expected Answer:**

**Progressive Enforcement Approach:**

```
Week 1: Monitoring
├─ Report untagged resources in daily dashboard
├─ Flag in Slack (non-blocking)
├─ Goal: Engineer awareness

Week 2: Policy in Code Review
├─ Terraform plans fail if tags missing
├─ But can override with approval for 24h
├─ Logs all overrides for audit
├─ Goal: Shift-left (catch at review time)

Week 3: Automation
├─ Lambda function tags untagged resources with "unassigned"
├─ Sends alert to engineering manager (whose budget?)
├─ Resource gets cost attributed (pain point)
├─ Goal: Self-service correction

Week 4: Hard Block
├─ SCP prevents resource creation without tags
├─ Exception process: governance team approves, implements
├─ No workarounds
└─ Goal: 100% compliance
```

**Cultural Notes:**
- Don't blame engineers ("careless")
- Frame as: "Help us understand resource ownership"
- Make it easy: Auto-generate tags from context (GitHub PR → cost center)

---

**Q6: A compliance audit finds that you're not logging all database access (audit table modifications not logged). Your on-call engineer bypassed the audit log requirement for performance. How do you address this?**

**Expected Answer:**

```
Issue: Audit logging performance overhead is real
├─ Write amplification (1 business transaction = 2 database writes)
├─ Can impact latency at scale
└─ Engineer trade off: "Performance vs security"

Solution: Don't disable, optimize

1. Asynchronous audit logging
   ├─ Business transaction: commit to main DB
   ├─ Audit event: async write to separate audit table/stream
   ├─ Doesn't block main transaction (latency: 0)
   └─ May have 1-5 second delay before audit log visible

2. Selective audit logging
   ├─ Log access to sensitive data (PHI, PII, card numbers)
   ├─ Don't log every table modification
   ├─ Reduces volume 90%
   └─ Compliance: focuses on sensitive data

3. Database optimization
   ├─ Audit table: separate tablespace, different disks
   ├─ Parallel AIO threads
   └─ Reduce contention with main transaction log

4. Organizational change
   ├─ Audit logging non-negotiable (compliance requirement)
   ├─ But valid to optimize implementation
   ├─ Involve engineer in solution (respect their concern)
```

**Root cause:** Engineer not empowered to voice performance concerns. Fix: Create channel for performance + security tradeoffs.

---

### Production Troubleshooting

**Q7: A critical service becomes unresponsive (requests timeout). You have 5 minutes to fix it. Walk through your debugging process.**

**Expected Answer (Rapid Diagnostic Process):**

```
Step 1 (30 seconds): Triage
├─ Is service pod running? YES (3/3 replicas healthy)
├─ Is service reachable? YES (port 8080 responding)
├─ Is service processing? NO (responses timeout after 30s)
└─ Conclusion: Likely dependency issue (database, external API)

Step 2 (1 minute): Check dependencies
$ kubectl logs <pod-name> --tail=50 | grep -i error
# Output: "Timeout connecting to postgres://prod-db:5432"
└─ Root: Database unreachable

Step 3 (2 minutes): Verify database
$ aws rds describe-db-instances --db-instance-identifier prod-db
# Status: Available, CPU: 5%, Memory OK
└─ Database is healthy, networking issue

Step 4 (3 minutes): Check connectivity
$ kubectl exec <pod> -- nslookup prod-db
# Output: 10.0.5.50
$ kubectl exec <pod> -- nc -zv 10.0.5.50 5432
# Connection refused
└─ Network path broken

Step 5 (4 minutes): Security groups / Network policies
$ kubectl get networkpolicy -n production | grep postgres
# Output: (none - default allow all)

$ aws ec2 describe-security-groups --group-ids sg-prod-db
# Output: Inbound: 5432 from sg-app only
# But pod has wrong security group! (from dev environment)
└─ ROOT CAUSE: Pod deployed with dev SG instead of prod SG

Step 5 (5 minutes): Fix
$ kubectl patch pod <pod> --type='json' -p='[{"op": "replace", ...}]'
# OR: Redeploy with correct config
```

**Key:** Don't guess. Follow dependency chain. Real root cause was misconfiguration, not database failure.

---

**Q8: Your application is consuming increasing memory over time (memory leak suspected). How do you identify and fix it?**

**Expected Answer:**

```
Step 1: Confirm it's a leak
├─ Graph memory over 48 hours
├─ Is it increasing monotonically? YES → leak likely
├─ Or sawtooth pattern (spikes then GC)? → GC tuning needed
└─ Or baseline creep (gradual increase to plateau)? → Expected after warmup

Step 2: Capture heap dump
$ jcmd <pid> GC.heap_dump /tmp/heap.hprof
$ scp /tmp/heap.hprof my-laptop:/tmp/
$ jhat /tmp/heap.hprof
# Navigate to: http://localhost:7000

Step 3: Analyze heap dump
├─ View -> Histogram of all classes
├─ Sort by size: "Potential memory leaks"
├─ Common culprits:
│  ├─ char[] (String cache, not evicting)
│  ├─ ArrayList (growing without bounds)
│  ├─ ConcurrentHashMap (custom cache, no eviction)
│  └─ Thread objects (thread pool not recycling)
└─ Example finding: Foo$StaticStringCache = 2.5GB

Step 4: Find what's holding the reference
├─ Click on Foo$StaticStringCache
├─ View -> "References" tab
├─ Check GC root: "String held by static field Manager.cache"
└─ ROOT CAUSE FOUND: Static cache not evicting old entries

Step 5: Fix code
# Bad
private static final Map<String, Data> cache = new HashMap<>();

# Good
private static final Map<String, Data> cache = new LinkedHashMap<String, Data>(1000) {
    protected boolean removeEldestEntry(Map.Entry eldest) {
        return size() > 1000;  // Bounded
    }
};

# Or use library
private static final Cache<String, Data> cache = Caffeine.newBuilder()
    .maximumSize(10000)
    .expireAfterWrite(1, TimeUnit.HOURS)
    .build();
```

---

### Architecture & Tradeoffs

**Q9: A startup wants to choose between monolith and microservices. They have 8 engineers. What do you recommend?**

**Expected Answer:**

```
RECOMMENDATION: Monolith (for now)

Reasoning:
├─ 8 engineers = can share codebase (communication < 5 min)
├─ Shared database: simpler transactions, consistency
├─ Single deployment: faster iteration
├─ Ops complexity: 1 system to manage
└─ Microservices complexity: distributed debugging, eventual consistency

Risks of choosing microservices prematurely:
├─ Operational overhead: deployment, monitoring, troubleshooting
├─ Complexity: 80% of time solving infrastructure
├─ Cost: K8s cluster, service mesh, observability
└─ Result: Slow iteration (opposite of startup goal)

Path forward (when to migrate):
├─ Signs: Team growing >15, deployment cycle >1 week
├─ Strategy: Modular monolith → microservices gradually
├─ Don't: Big bang rewrite (graveyard of failed projects)
└─ Instead: Carve off 1 service (e.g., payments) when pain is clear
```

**Follow-up:** *If they insist on microservices, what's the minimum you need?*
- Kubernetes (managed: EKS, GKE)
- Observability: Logs, metrics, traces (critical)
- RPCs: gRPC or REST with circuit breakers
- Database: Per-service (data autonomy)
- Documentation: Critical (distributed system is complex)

---

**Q10: Your team has spent $500k on AWS over past year. CFO asks: "Are we spending optimally?" How do you respond?**

**Expected Answer:**

```
Good news + Opportunities for optimization:

Analysis:
1. Reserve Instances (RI): Are you using?
   ├─ Spot instances for non-critical: 70% savings
   ├─ RIs for baseline: 30-40% savings
   ├─ On-demand for variable: 0% savings
   └─ Action: Analyze past 3 months, potential $5k/month savings

2. Application efficiency
   ├─ Right-sizing: Too large instances?
   ├─ Examples: m5.2xlarge → t3.large saves 60%
   ├─ Database: RDS Multi-AZ necessary for all envs?
   └─ Action: Audit instances, potential $3k/month savings

3. Data transfer costs
   ├─ Inter-region transfer: $0.02/GB (expensive!)
   ├─ Move to single region if possible
   ├─ Or use VPC endpoints (avoid NAT gateway)
   └─ Action: Check CloudWatch billing, potential $2k/month

4. Storage/Backups
   ├─ Old snapshots: Auto-delete after 30 days?
   ├─ CloudTrail logs: Store in S3 Glacier ($0.004/GB vs $0.023)
   └─ Action: Lifecycle policies, potential $1k/month

Total opportunity: $10k/month ($120k/year, 24% savings)
Timeline: Implement over 2 months
```

**Key:** Not "cut costs blindly" but "optimize efficiently." Maintain reliability while reducing waste.

---

**Q11: Describe a time when you had to choose between fast (take risk) vs safe (slow but reliable). How did you decide?**

**Expected Answer (Behavioral):**

This is about judgment and communication:

```
Example (real scenario):
- Situation: Customer critical bug in production, payment processing broken
- Pressure: Fix ASAP (revenue impact)
- Option 1: Rollback to previous version (5 min fix, high risk: missing other bug fix)
- Option 2: Debug + fix (30 min fix, low risk: targeted solution)
- Option 3: Workaround (10 min fix, medium risk: technical debt)

My decision: Option 2 (debug + fix)

Reasoning:
├─ 5 min vs 30 min difference not critical (already 20 min down)
├─ Rollback not option (loses legitimate bug fix)
├─ Workaround adds technical debt (future issue)
└─ Use 30 min to understand + test before deploy

Execution:
1. Communication: Told customer "investigating root cause, ETA 30 min"
2. Parallel work: QA testing fix in staging while I investigated
3. Rapid deploy: After fix validated (10 min), deploy to prod
4. Monitor: Stayed on-call 2h to catch any regressions

Result: 32 min downtime, customer appreciated transparency

Key learning: Speed matters, but reckless speed causes bigger disasters.
```

---

**Q12: How do you stay current with DevOps/Cloud trends? (Continuous learning)**

**Expected Answer:**

```
1. Read (30 min/week)
   ├─ Architecture Decision Records (ADRs) from other companies
   ├─ Linux Foundation CNCF blog
   ├─ Vendor blog posts (AWS, Kubernetes release notes)
   └─ Goal: Understand what's changing

2. Hands-on labs (2 hours/week)
   ├─ Terraform modules you haven't used
   ├─ Kubernetes feature you're unfamiliar with
   ├─ Chaos engineering on lab cluster
   └─ Goal: Learn by doing

3. Community (attend 2-4 conferences/year)
   ├─ KubeCon, re:Invent, DevOps Days
   ├─ Connect with engineers solving similar problems
   ├─ Validate: "Are we doing this right? What are alternatives?"
   └─ Goal: Network + learn from peers

4. Internal practice
   ├─ Brown bags: Share learning with team
   ├─ Architecture reviews: Discuss tradeoffs
   ├─ RCA: Learn from incidents
   └─ Goal: Continuous improvement culturally

Example: Learned about cost optimization (RI vs Spot), implemented in 2 weeks, saved $10k/month.
```

---

## Summary & Final Thoughts

This study guide covers the five pillars of modern DevOps:

1. **GitOps & Deployment** - How to deploy reliably and repeatedly
2. **Governance & Compliance** - How to enforce standards without blocking velocity
3. **Production Troubleshooting** - How to diagnose and fix issues under pressure
4. **Reference Architectures** - Proven patterns at different scales
5. **Real-World Tradeoffs** - How to make business-aligned engineering decisions

**For Senior DevOps Engineers:**

You're expected to make architectural decisions that balance:
- **Reliability** (uptime, disaster recovery)
- **Velocity** (deploy speed, iteration cycles)
- **Cost** (cloud spend, team efficiency)
- **Compliance** (regulatory requirements, security)
- **Scalability** (handle 10x growth, not just today's load)

Success isn't mastering all tools—it's **understanding tradeoffs** and helping your organization make informed decisions.

---

**Audience:** DevOps Engineers with 5–10+ years experience  
**Last Updated:** March 2026  
**Status:** Complete and production-ready for training


