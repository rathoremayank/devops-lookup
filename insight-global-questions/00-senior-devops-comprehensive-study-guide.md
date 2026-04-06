# Senior DevOps Engineer - Comprehensive Study Guide
## AWS Cloud, Containerization, ROSA, CI/CD, IaC, Configuration Management, Scripting, Monitoring, Container Runtime, Scaling & MLOps

---

## Table of Contents

### Core Sections
1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)

### Topic Deep-Dives
3. [AWS Cloud](#aws-cloud)
4. [Containerization](#containerization)
5. [ROSA (Red Hat OpenShift on AWS)](#rosa)
6. [CI/CD Pipelines](#cicd-pipelines)
7. [Infrastructure as Code (Terraform)](#infrastructure-as-code)
8. [Configuration Management (Chef)](#configuration-management)
9. [Scripting (Python & Bash)](#scripting)
10. [Monitoring & Observability](#monitoring--observability)
11. [Container Runtime](#container-runtime)
12. [Data & Infrastructure Scaling](#data--infrastructure-scaling)
13. [Advanced Systems - MLOps](#advanced-systems---mlops)

### Practical Application
14. [Hands-on Scenarios](#hands-on-scenarios)
15. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

This comprehensive study guide covers the complete spectrum of modern DevOps engineering at a senior level, integrating cloud infrastructure, containerization platforms, infrastructure automation, and operational excellence. The scope encompasses **11 interconnected domains** that form the backbone of cloud-native, scalable, and maintainable systems in enterprise environments.

**Core Message**: Modern DevOps is not about individual tools but about orchestrating a **unified ecosystem** where:
- Infrastructure is defined as code (IaC)
- Applications run in containers with orchestration
- Deployment pipelines are automated end-to-end
- Systems observe themselves through comprehensive telemetry
- Scaling happens automatically based on demand
- Configuration drift is eliminated through continuous management

### Why It Matters in Modern DevOps Platforms

**Business Impact:**
- **Velocity**: Deploy from code to production in minutes, not months
- **Reliability**: Automated testing, monitoring, and self-healing reduce MTTR (Mean Time To Recovery)
- **Cost Efficiency**: Right-sizing compute through auto-scaling and container density saves millions annually
- **Security**: Infrastructure as Code enables compliance as code; immutable containers reduce attack surface
- **Competitive Advantage**: Organizations that master DevOps practices ship features faster and iterate on customer feedback

### Real-World Production Use Cases

#### Case Study 1: E-Commerce Platform Scaling (Peak Shopping Season)
**Scenario**: A $500M e-commerce company needs to handle 100x traffic spike during Black Friday without service degradation.

**Solution Components**:
- **Terraform IaC**: Infrastructure as versioned code enables reproducible environment provisioning
- **AWS Auto Scaling**: EC2/RDS auto-scaling handles load elasticity
- **Docker Containers**: Consistent application runtime environment reduces "works on my machine" failures
- **ROSA/Kubernetes**: Orchestrates 1000+ container replicas across availability zones
- **CI/CD Pipeline**: Safely deploys 200+ microservices per day with canary deployments
- **Monitoring/Observability**: Prometheus + Grafana + ELK detects anomalies and triggers auto-remediation

**Outcome**: Zero downtime during peak traffic; 40% cost reduction through container density and auto-scaling

---

## Foundational Concepts

*(Full foundational concepts section from Part 1 - maintained for continuity)*

### Key Terminology

**Cloud-Native Architecture, Infrastructure as Code, Immutable Infrastructure, Cattle vs. Pets, Declarative vs. Imperative Configuration, CI/CD, Observability vs. Monitoring, Blast Radius** - *See Part 1 for detailed explanations*

### Architecture Fundamentals

**Scalability Types, Resilience & Fault Tolerance Patterns, Microservices Architecture, Event-Driven Architecture** - *See Part 1 for detailed explanations*

### Important DevOps Principles

**IaC, Immutability, Single Responsibility, Observability-First, Speed vs. Stability, Automation, Failure Injection** - *See Part 1 for detailed explanations*

---

# AWS Cloud

## AWS Core Services

### Textual Deep Dive

#### Internal Working Mechanism

AWS core services are built on a distributed, fault-tolerant architecture spanning multiple Availability Zones and regions. Each service operates independently but integrates through well-defined APIs. The fundamental architecture follows:

```
Request Routing → Authentication (IAM) → Service Logic → Data Layer → Response Return
```

**Computation Services**:
- **EC2 (Elastic Compute Cloud)**: On-demand VMs with configurable CPU, memory, storage. KVM hypervisor virtualizes hardware; instances are isolated but share underlying physical hardware (via virtualization).
- **Lambda**: Serverless compute triggered by events. AWS manages infrastructure; you provision only CPU time. Cold starts occur when function hasn't run recently (100-500ms delay).
- **Elastic Beanstalk**: PaaS simplifying application deployment. Abstracts infrastructure; you provide code.

**Storage Services**:
- **S3 (Simple Storage Service)**: Object storage (key-value pairs, not filesystems). Replicated across AZs; 99.999999999% durability (11 nines). Eventual consistency model for puts.
- **EBS (Elastic Block Store)**: Block storage attached to EC2. Presented as raw disk; you provision filesystem. Supports snapshots (point-in-time backups).

**Database Services**:
- **RDS (Relational Database Service)**: Managed SQL databases (PostgreSQL, MySQL, Oracle, SQL Server). AWS handles backups, patching, failover. Multi-AZ deployments replicate synchronously to standby.
- **DynamoDB**: NoSQL, serverless, fully managed. Scales automatically; you provision capacity or use on-demand billing.

#### Production Usage Patterns

**EC2 Usage**:
```
Typical Enterprise Pattern:
Development → Staging → Production
t2.micro    t2.small   m5.xlarge (right-sized)
```

Production EC2 patterns:
- **Auto Scaling Groups (ASG)**: Cluster of identical instances; scale up/down based on metrics
- **Spot Instances**: Bid for unused capacity at 70-90% discount; can be terminated with 2-min notice. Used for fault-tolerant batch jobs
- **Reserved Instances**: Commit to 1 or 3-year term; 30-60% discount vs. on-demand. Optimal for steady-state servers

**Lambda Usage**:
```
Best Fit:
- Event-driven processing (S3 upload → resize image)
- Scheduled tasks (cron jobs)
- API endpoints with bursty traffic

Avoid:
- Long-running processes (>15 min max timeout)
- Continuous background work (use EC2/Fargate)
```

**S3 Usage Patterns**:
```
High-Frequency Access (millisecond latency) → S3 (standard tier)
Infrequent Access (seconds acceptable) → S3 Intelligent-Tiering
Archive (hours+ acceptable) → Glacier (cents per GB)
```

#### DevOps Best Practices

**1. Right-Sizing Compute**:
```
Problem: Provisioned m5.2xlarge; metrics show only 5% CPU utilization
Solution: CloudWatch metrics show actual usage; downsize to t2.medium; save $1000+/month
```

Instance families to understand:
- **t2/t3**: Burstable; baseline performance; cheap for bursty loads
- **m5/m6**: General purpose; balanced CPU/memory; production workhorses
- **c5/c6**: Compute optimized; high CPU; batch processing, gaming
- **r5/r6**: Memory optimized; high RAM; databases, caching
- **i3/i4**: Storage optimized; fast NVMe; analytics, data warehouses

**2. Backup & Disaster Recovery**:
```
Best Practice: Automated backups + cross-region replication
EBS: Enable automated snapshots every 24 hours
RDS: Enable automated backups (35-day retention) + multi-region read replica
S3: Enable versioning; replicate to secondary region
```

**3. High Availability Design**:
```
Single AZ Architecture:
┌─────────────────────────────┐
│    Availability Zone 1      │
│ ┌──────┐    ┌──────────┐    │
│ │ WEB  │───▶│ Database │    │
│ └──────┘    └──────────┘    │
│                             │
│  Problem: AZ failure = outage│
└─────────────────────────────┘

Multi-AZ Architecture:
┌──────────────────┬──────────────────┐
│    AZ 1          │    AZ 2          │
│ ┌──────┐         │ ┌──────┐         │
│ │ WEB  │◄───────▶│ │ WEB  │         │
│ └──────┘         │ └──────┘         │
│  │ Database      │  │ Replica       │
│  └──────────┬────┘  └─────────┬─────│
│             │ (Sync Replication)   │
├─────────────┴─────────────────────┤
│ Result: AZ failure = automatic     │
│ failover to other AZ               │
└────────────────────────────────────┘
```

#### Common Pitfalls

| Pitfall | Consequence | Prevention |
|---------|-------------|-----------|
| Storing credentials in EC2 user-data | Secrets exposed in CloudTrail/backups | Use IAM Roles; store secrets in Secrets Manager |
| Single-region infrastructure | Regional outage = total downtime | Multi-region with Route53 failover |
| Not archiving old logs | Storage costs spiral; compliance violations | Lifecycle policies: S3 → Glacier after 90 days |
| Unencrypted backups | Compliance failures; breach exposure | Enable encryption by default (KMS) |
| Running on-demand instances 24x7 | Waste; 30% of cloud spend | Reserved Instances for committed workloads |

---

## AWS Security

### Textual Deep Dive

#### Internal Working Mechanism

AWS provides **defense in depth**: security operates at multiple layers.

```
┌─────────────────────────────────────────────────────┐
│                AWS Account                          │
├─────────────────────────────────────────────────────┤
│  Layer 1: IAM (Identity & Access Management)       │
│  ├─ AuthN (who are you?) → AWS credentials        │
│  ├─ AuthZ (what can you do?) → IAM policies       │
│  └─ MFA (second factor) → TOTP/U2F devices        │
├─────────────────────────────────────────────────────┤
│  Layer 2: Network (AWS VPC)                        │
│  ├─ Security Groups (stateful firewall rules)     │
│  ├─ Network ACLs (NACLs - stateless rules)        │
│  └─ VPC Endpoints (private connectivity)          │
├─────────────────────────────────────────────────────┤
│  Layer 3: Service-Level                            │
│  ├─ Encryption at-rest (KMS keys)                 │
│  ├─ Encryption in-transit (TLS 1.2+)              │
│  └─ API access logging (CloudTrail)               │
├─────────────────────────────────────────────────────┤
│  Layer 4: Application                              │
│  ├─ Input validation                              │
│  ├─ Output encoding                               │
│  └─ Secrets management (not hardcoded)            │
└─────────────────────────────────────────────────────┘
```

**IAM (Identity & Access Management)**:
- **Users**: Human identities
- **Roles**: Assume-able identities (temporary credentials)
- **Policies**: JSON documents defining permissions
- **Trust relationships**: Who can assume a role

**Secrets Management**:
- **AWS Secrets Manager**: Rotate database passwords automatically
- **AWS Systems Manager Parameter Store**: Simple key-value storage
- **Encrypted EBS**: Data at-rest encrypted with KMS keys
- **TLS in transit**: All AWS API calls use TLS 1.2+

#### Production Usage Patterns

**IAM Best Practice: Cross-Account Access**:
```json
// Production Account Role Trust Policy
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::DEV_ACCOUNT_ID:role/cross-account-access"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-token-12345"
        }
      }
    }
  ]
}
```

This allows Dev account to assume Prod role (with external ID for safety), enabling temporary access.

**KMS Encryption Pattern**:
```
Application
  ↓ (plaintext data + key ID)
  ↓ AWS API call (TLS encrypted)
  ↓ KMS Service
  ↓ ✓ Check: User has "kms:Decrypt" permission?
  ↓ ✓ Check: API call logged in CloudTrail?
  ↓ Decrypt with root key material
  ↓ Return plaintext (ephemeral, not logged)
  ↓ Application uses plaintext
  ↓ Clear from memory after use
```

#### Common Pitfalls

| Pitfall | Risk | Fix |
|---------|------|-----|
| Root account used for daily work | Full account compromise if credentials leaked | Create IAM admin user; disable root access keys |
| Wildcard IAM policies (`"Resource": "*"`) | Principle of least privilege violated | List specific resources or use resource tags |
| Secrets stored in code/environment variables | Version control exposes secrets | AWS Secrets Manager; rotate automatically |
| Security groups allow 0.0.0.0/0 (all IPs) | Unnecessary exposure; attack surface | Restrict to known CIDRs; use security group chaining |
| No MFA enforced | Compromised credential = full compromise | Enforce MFA for AWS console + API (IMDSv2) |
| Unencrypted S3 buckets | Data breach; compliance violation | S3 default encryption; block unencrypted puts |

---

## AWS Networking

### Textual Deep Dive

#### Internal Working Mechanism

AWS networking follows OSI layers; DevOps focuses on Layers 2-4 (data link through transport).

```
Layer Architecture:

Application Layer
    ↓
Transport Layer (Layer 4) → Security Groups (stateful firewall on port/protocol)
    ↓
Network Layer (Layer 3) → Route Tables (IP routing) + NACLs (stateless firewall)
    ↓
Data Link / Physical Layers (Layer 2-1) → VPC + Availability Zones
```

**VPC (Virtual Private Cloud)**: Isolated network environment; you define:
- CIDR block (e.g., 10.0.0.0/16)
- Subnets (10.0.1.0/24, 10.0.2.0/24, etc.)
- Route tables (traffic routing rules)
- Internet Gateway (IGW) or NAT Gateway (outbound access)

**Route53 (DNS)**:
- Translates domain names to IP addresses
- Health checks enable failover
- Policy-based routing (geolocation, weighted, latency-based)

**Elastic Load Balancers (ELB)**:
- **Application Load Balancer (ALB)**: Layer 7 (application); routes based on hostname/path
- **Network Load Balancer (NLB)**: Layer 4 (transport); ultra-high throughput (millions of requests/sec)
- **Classic Load Balancer**: Legacy; rarely used

#### Production Usage Patterns

**Multi-AZ Load Balancing**:
```
Internet
    ↓
Route53 (DNS) → AWS-managed; failover if ALB unhealthy
    ↓
ALB (Multi-AZ)
  ├─ AZ-1a: web-pod-1, web-pod-2
  ├─ AZ-1b: web-pod-3, web-pod-4
  └─ AZ-1c: web-pod-5, web-pod-6
    ↓
Target Group (Health Checks every 30s)
  ├─ If pod unhealthy → Remove from rotation
  ├─ If AZ unhealthy → Reroute to other AZs
    ↓
Application
```

**VPC Peering** (Private connectivity between VPCs):
```
VPC 1 (10.0.0.0/16)
    ↓
VPC Peering Connection (managed by AWS)
    ↓
VPC 2 (10.1.0.0/16)

Advantage: Private traffic (no internet); no data transfer charges between AZs
```

#### DevOps Best Practices

**1. Network Segmentation**:
```
Public Tier (Internet-facing)
  ├─ ALB (port 443)
  ├─ NAT Gateway (egress only)
  └─ NGW (NAT Gateway, manages outbound)

Private Tier (No direct internet)
  ├─ Application servers
  ├─ Kubernetes nodes
  └─ Outbound via NAT Gateway

Database Tier (Isolated)
  ├─ No inbound from public
  ├─ Inbound only from private tier
  └─ Encryption in-transit
```

**2. DNS Strategy**:
```
Production DNS (Route53):
├─ Primary: api.example.com → ALB Endpoint (weighted 90%)
├─ Canary: api.example.com → ALB Endpoint (weighted 10%, new code)
└─ If canary error rate > threshold → Remove canary; reroute 100% to primary
```

---

## AWS Storage

### Textual Deep Dive

#### Internal Working Mechanism

**S3 (Simple Storage Service)**: Distributed object storage built for 11 nines durability.

```
PUT request:
1. Route to regional gateway
2. Split object into chunks (default 5MB)
3. Compute MD5 hash
4. Distribute across multiple facilities (AZ-independent)
5. Replicate across ≥3 geographic locations
6. Return success to client

Durability implications:
For object to be lost:
  AND all replicas in>3 facilities corrupted
  AND AWS datacenter fails
  → Probability ≈ 0.0000001% (11 nines)
```

**EBS (Elastic Block Store)**: Persistent block storage attached to EC2.
```
ebs-volume-1 (gp3, 100GB)
    ↓ (attached to ec2-instance-1)
    ↓ Appears as /dev/xvda in instance
    ↓ Format as ext4 filesystem
    ↓ Mount at /data

Snapshot (point-in-time backup):
  ├─ First snapshot: Full backup of all blocks
  ├─ Subsequent snapshots: Incremental (changed blocks only)
  └─ Can restore to new volume or across regions
```

**EFS (Elastic File System)**: Shared filesystem (NFS).
```
Multiple EC2 instances
    ↓ (all mount same EFS)
    ↓ /mnt/shared (shared data visible to all)
    ↓ Automatic scaling (no provisioning)
    ↓ Replicated across AZs
```

#### Production Usage Patterns

**S3 Tiering for Cost Optimization**:
```
Day 1-30: S3 Standard ($0.023/GB/month, frequent access)
Day 31-90: S3 Standard-IA ($0.0125/GB/month, infrequent access)
Day 91-365: S3 Glacier Flexible ($0.004/GB/month, archive)
Year 2+: S3 Deep Archive ($0.00099/GB/month, compliance holds)

Lifecycle Rule:
Age < 30 days: Standard
Age 30-90 days: Standard-IA
Age > 90 days: Glacier
```

**Database Backup Pattern**:
```
RDS Automated Backups:
├─ Daily full backup → S3 (AWS managed, your account)
├─ Retention: 1-35 days (configurable)
├─ Cross-region replication (optional)
│  └─ Read-only replica in secondary region
│  └─ Automatic failover on primary failure
└─ Point-in-time recovery: Restore to any second within retention window
```

---

## AWS Compute

### Textual Deep Dive

#### Internal Working Mechanism

**EC2 Instance Lifecycle**:
```
pending → running → stopping → stopped
           ↓ (EBS root volume detached)
           ↓ (can reattach later)

terminating → terminated
(instance deleted; EBS deleted if not marked "delete on termination: false")
```

**Auto Scaling Group (ASG)**:
```
Desired Capacity = 5 instances

Current State: 3 instances running

ASG Action:
  ├─ Launch Configuration spec: ami-12345, t2.medium, security-group-web
  ├─ Launch 2 more instances
  ├─ Register with Target Group
  ├─ Health checks pass
  └─ ASG now reconciles to desired state

Scaling Policy (CPU-based):
  ├─ If Avg CPU > 70% for 2 minutes → Scale up by 1
  ├─ If Avg CPU < 30% for 5 minutes → Scale down by 1
  └─ Min: 2, Max: 10
```

**Lambda Execution Model**:
```
Lambda Function

1. Request arrives (API Gateway, S3 event, CloudWatch timer)
2. AWS provisions execution environment (cold start, 100-500ms)
   ├─ Download code package
   ├─ Start Linux microVM
   ├─ Run handler initialization code
   └─ Execute function logic
3. Return response
4. Keep environment warm for ~15 minutes (reuse across invocations)
5. If invocation arrives while warm → Use same environment (no cold start)
6. Timeout: 15 minutes max; function killed if exceeds
```

#### Production Usage Patterns

**Right-Sizing EC2 Fleet**:
```
Typical SaaS company:
├─ Web Tier: t2.medium (CPU bursting, cost-optimized)
├─ API Tier: m5.large (sustained CPU load)
├─ Processing Tier: c5.2xlarge (batch analytics)
└─ Database Tier: r5.4xlarge (memory-intensive)

Cost Optimization:
├─ 50% On-Demand (handle spikes, flexibility)
├─ 30% Reserved Instances (predictable baseline)
└─ 20% Spot Instances (fault-tolerant batch jobs)

Result: 40-60% cost reduction vs. all on-demand
```

**Lambda for Event Processing**:
```
S3 Upload Event
    ↓ (new image: photos/vacation/pic.jpg)
    ↓ S3 sends event to Lambda
    ↓ Lambda Function: resize-image (Python 3.11)
    ├─ Download from S3
    ├─ Resize using PIL
    ├─ Upload thumbnail to S3
    └─ Log to CloudWatch
    ↓ Duration: 800ms (0.0008GB-seconds)
    ↓ Cost: $0.0000002 (essentially free)

Advantage: No servers to manage; scales to millions of events/day
```

---

## AWS Databases

### Textual Deep Dive

#### Internal Working Mechanism

**RDS Architecture**:
```
Primary DB Instance (Multi-AZ):
  ├─ Accepts reads/writes
  ├─ Real-time replication (synchronous)
  └─ AZ-1a

  ↓ (replication lag: <0.1ms)

Standby Replica:
  ├─ Receives replicated writes
  ├─ Cannot be read from (hot standby)
  └─ AZ-1b

Automatic Failover (if primary fails):
  ├─ Detect primary failure (30-60s)
  ├─ Promote standby to primary
  ├─ Update DNS (internal endpoint still works)
  └─ Old primary terminated; new standby provisioned
```

**DynamoDB (NoSQL) Architecture**:
```
DynamoDB Table: orders
  ├─ Partition Key: customer_id (distributions data across partitions)
  ├─ Sort Key: order_timestamp (ordering within partition)
  └─ TTL: expires old orders after 30 days

Provisioned Capacity:
  ├─ Read: 1000 RCU (read capacity units)
  │  └─ 1 RCU = 1 strongly-consistent read/sec (up to 4KB item)
  ├─ Write: 500 WCU (write capacity units)
  │  └─ 1 WCU = 1 write/sec (up to 1KB item)
  └─ Cost: ~$474/month for above

On-Demand (PAY-AS-YOU-GO):
  ├─ Read: $1.25 per million requests
  ├─ Write: $6.25 per million requests
  └─ Good for bursty/unpredictable workloads
```

#### Production Usage Patterns

**Multi-Region Database**:
```
Primary Region (us-east-1): RDS PostgreSQL
    ↓ (async replication)
    ↓ ~1 second lag
Secondary Region (eu-west-1): Read Replica
    ├─ Read-only; reduces primary load
    ├─ Handles regional failover if configured
    └─ Separates analytics queries (don't impact production)

Failover Process:
  ├─ Detect primary region failure
  ├─ Promote read replica to standalone
  ├─ Update application DNS/connection string
  └─ Accept writes in secondary region (RTO: 5-10 min)
```

---

## AWS DevOps Tools

### Textual Deep Dive

**AWS Systems Manager**:
```
On-demand agent runs on all EC2 instances + on-premises servers

Capabilities:
├─ Session Manager: SSH alternative (bastion-less access, audited)
├─ Run Command: Execute commands across fleet
├─ Patch Manager: Automatically patch EC2 instances
├─ State Manager: Enforce desired config state (Chef/Puppet recipes)
└─ OpsCenter: Centralized incident response
```

**AWS CodePipeline**:
```
Source (GitHub) → Build (CodeBuild) → Deploy (CodeDeploy) → Approval → Production
     ↓                  ↓                    ↓
  Trigger on         Compile code,      Roll out to
  push to main       run tests,          EC2/Lambda
                     push image to ECR
```

**AWS CodeDeploy**:
```
Deployment Strategies:

All-at-once (risky):
  ├─ Terminate all v1 instances
  ├─ Spin up all v2 instances
  └─ Downtime during transition

Rolling (safer):
  ├─ Terminate 25% of v1 instances
  ├─ Spin up 25% of v2 instances
  ├─ Repeat until 100% migrated
  └─ Always have capacity; gradual migration

Canary (safest):
  ├─ 5% of traffic → v2 (canary)
  ├─ Monitor error rate, latency
  ├─ If all good → Gradual shift (5% → 10% → 50% → 100%)
  └─ If canary fails → Automatic rollback to v1
```

---

## AWS Best Practices

### Textual Deep Dive

**1. Tagging Strategy**:
```json
Resource Tags (enable cost allocation + governance):

{
  "Environment": "production",
  "Application": "checkout-service",
  "Team": "payments",
  "CostCenter": "engineering",
  "Backup": "daily",
  "DataClassification": "confidential"
}

Benefit:
├─ Cost analysis: $2M/month for production
├─ Governance: All resources without "Backup: daily" flagged
├─ Lifecycle: Resources tagged "EOL: 2025-12-31" auto-deleted
└─ Compliance: Data classification enables encryption policies
```

**2. Cost Optimization**:
```
Audit findings:
├─ Unattached EBS volumes (cost: $0.05/GB/month): Delete old snapshots
├─ Idle RDS instances: Downsize or delete non-production
├─ NAT Gateway costs (data transfer: $0.045/GB): Use VPC Endpoints for AWS services
├─ Over-provisioned EC2 instances: Right-size based on CloudWatch metrics
└─ Reserved Instances not fully used: Cancel unused reservations

Potential savings: 30-50% of cloud spend
```

**3. Disaster Recovery (DR)**:
```
DR Strategies (by cost + RTO/RPO):

Backup & Restore (cheapest):
├─ RTO: 4-24 hours
├─ RPO: Daily backups
└─ Cost: Storage only (~$100/month)

Pilot Light (moderate):
├─ Secondary region has minimal setup
├─ RTO: 1-4 hours
├─ RPO: Real-time replication
└─ Cost: ~30% of primary (~$3000/month)

Warm Standby (balanced):
├─ Secondary region scaled for reduced load
├─ RTO: 15-60 minutes
├─ RPO: Real-time
└─ Cost: ~50% of primary (~$5000/month)

Hot-Hot Active-Active (expensive):
├─ Both regions fully scaled
├─ RTO: Seconds (automatic failover)
├─ RPO: ~0 (real-time sync)
└─ Cost: 2x primary (~$10000/month)

Choice: Balance criticality vs. cost
```

---

## Real-World AWS Examples

### Example 1: Containerized Microservices on AWS

```yaml
# Architecture Overview:
# Users → CloudFront CDN → ALB → ECS (containerized services) → RDS + ElastiCache

DNS (Route53):
  - api.example.com → ALB DNS name
  - cdn.example.com → CloudFront distribution

CloudFront (CDN):
  - Caches static assets (HTML, CSS, JS, images)
  - Edge locations worldwide; 99.99% availability
  - Origin: S3 bucket or ALB

ALB (Application Load Balancer):
  - Port 443 (HTTPS)
  - Path-based routing:
    /api/users → User Service (port 8001)
    /api/orders → Order Service (port 8002)
    /api/payments → Payment Service (port 8003)

ECS Cluster (EC2 launch type):
  - EC2 instances: t3.large (3 instances, Auto Scaling Group)
  - Containers:
    - User Service (3 replicas, port 8001)
    - Order Service (2 replicas, port 8002)
    - Payment Service (2 replicas, port 8003)
  - Task CPU/Memory: 512 CPU units, 1GB memory per task

Data Layer:
  - RDS PostgreSQL (Multi-AZ)
    - Primary: db.r5.large (production workload)
    - Standby: db.r5.large (hot standby, automatic failover)
    - Backups: Daily + cross-region replication
  - ElastiCache (Redis)
    - 3-node cluster (high availability)
    - Session storage, rate-limiting cache
    - Eviction policy: allkeys-lru (auto-evict LRU keys)

Monitoring:
  - CloudWatch: CPU, memory, network metrics
  - Application Insights: Application Performance Monitoring (APM)
  - VPC Flow Logs: Network traffic analysis
  - X-Ray: Distributed tracing across services
```

**Deployment Pipeline**:
```
Developer Push to GitHub (main branch)
  ↓ GitHub webhook
  ↓ CodePipeline triggered
  ↓ Stage 1: Source (pull from GitHub)
  ↓ Stage 2: Build
    ├─ CodeBuild pulls code
    ├─ Run unit tests (PHP/Python/Node.js)
    ├─ Build Docker image
    ├─ Scan for CVEs (Trivy)
    ├─ Push to ECR (elastic container registry)
    └─ Success → proceed
  ↓ Stage 3: Deploy to Staging
    ├─ Pull image from ECR
    ├─ Update ECS staging service
    ├─ Run integration tests
    ├─ Load test (verify performance)
    └─ Success → proceed
  ↓ Stage 4: Approval (Manual gate)
    ├─ Slack notification to team lead
    ├─ Approve deployment
    └─ Proceed to production
  ↓ Stage 5: Deploy to Production
    ├─ Canary deployment (10% of traffic → new version)
    ├─ Monitor error rate, latency (5 minutes)
    ├─ If good: Increase to 50%, then 100%
    ├─ If bad: Automatic rollback to previous version
    └─ Slack notification of completion
```

---

# Containerization

## Docker Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**Container Runtime Layer**:
```
Docker (client-facing tool)
    ↓ API request
    ↓ Docker daemon (dockerd)
    ↓ containerd (container runtime)
    ↓ runc (low-level runtime)
    ↓ Linux kernel namespaces + cgroups
    ↓ Isolated process (appears as separate machine)
```

**Namespace Isolation** (What containers see):
```
Host System:
├─ 500 processes total
├─ Network interfaces: eth0, eth1, loopback
├─ Filesystems: /var, /tmp, /home, /opt
└─ User IDs: root=0, user=1000, etc.

Container View (PID namespace):
├─ 5 processes (init=1, app=2, library launcher=3, etc.)
├─ Thinks it owns PID 1
└─ Cannot see host processes

Container View (Network namespace):
├─ eth0 (veth pair connected to host bridge)
├─ Cannot see host's eth1 or loopback (unless bridged)
└─ Isolated routing table

Container View (Mount namespace):
├─ Root filesystem: /app (container image layers)
├─ /var mounted from container runtime
└─ Cannot see /home, /opt from host (unless mounted)
```

**Image Layers** (Efficient storage):
```
Base Image: ubuntu:22.04 (100MB)
  ├─ Layer: apt update + apt install python3 (50MB)
  ├─ Layer: COPY app /app (5MB)
  ├─ Layer: pip install requirements.txt (20MB)
  └─ Layer: CMD python app.py

Final Image Size: 175MB

Image Registry Storage:
├─ Base layer: Stored once (shared across all Python containers)
├─ Subsequent layers: Stored separately
└─ Container filesystem = RO layers + RW container layer (ephemeral)
```

#### Production Usage Patterns

**Multi-Stage Dockerfile**:
```dockerfile
# Stage 1: Builder (large, includes build tools)
FROM node:18 as builder
WORKDIR /src
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build  # Output: /src/dist

# Stage 2: Runtime (small, only runtime needed)
FROM node:18-slim
WORKDIR /app
COPY --from=builder /src/dist /app
# NOT including package.json, node_modules (builder artifacts not copied)
EXPOSE 3000
CMD ["node", "server.js"]

# Final image: ~200MB (only runtime) instead of ~800MB (all build tools)
```

**Secrets Management** (Anti-Pattern):
```dockerfile
# ❌ WRONG: Secrets in Dockerfile
FROM ubuntu:22.04
RUN echo "DATABASE_PASSWORD=secret123" >> /etc/config.sh

# Problem:
├─ Secret visible in image layers
├─ Secret in image: docker history reveals it
├─ Secret in container: can be extracted with docker exec
└─ Secret in registry: anyone with pull access sees it

# ✅ RIGHT: Secrets at runtime
FROM ubuntu:22.04
# No secrets in Dockerfile

# At runtime:
# Option 1: Environment variable (passed by orchestrator)
# Option 2: Volume mount (secret from orchestrator)
# Option 3: Secrets Manager API call (app fetches it at startup)
```

---

## Docker Architecture

### Textual Deep Dive

#### Internal Working Mechanism

**Docker Engine Components**:
```
┌────────────────────────────────────────────┐
│            Docker Client                   │
│  (docker run, docker build, docker push)  │
└────────────────────────────────────────────┘
         ↓ (HTTP/Unix socket)
┌────────────────────────────────────────────┐
│         Docker Daemon (dockerd)            │
│  - Image management                        │
│  - Container lifecycle                     │
│  - Network management                      │
│  - Storage driver (overlay2, aufs, etc.)  │
└────────────────────────────────────────────┘
         ↓ (gRPC)
┌────────────────────────────────────────────┐
│        Container Runtime (containerd)      │
│  - Lower-level container operations        │
│  - Image unpacking                         │
│  - Process execution coordination          │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│        OCI Runtime (runc / crun)           │
│  - Create namespaces                       │
│  - Apply cgroups                           │
│  - Start process                           │
└────────────────────────────────────────────┘
         ↓
┌────────────────────────────────────────────┐
│        Linux Kernel                        │
│  - Namespaces (PID, NET, MOUNT, UTS, etc.)│
│  - cgroups (resource limiting)             │
└────────────────────────────────────────────┘
```

**Storage Driver** (Overlay2 - most common):
```
Container State (Writable layer):
┌─────────────────────────────────┐
│ Container Layer (RW)            │
│ ├─ app logs (new file)          │
│ ├─ /tmp/temp (modified)         │
│ └─ (stores diffs only)          │
└─────────────────────────────────┘
         ↓ (copy-on-write)
┌─────────────────────────────────┐
│ Layer N (RO - from Dockerfile)  │
│ ├─ Application binary           │
│ ├─ Configuration files          │
│ └─ (mounted read-only)          │
├─ Layer N-1 (RO)
│ ├─ Python runtime
│ └─ Libraries
├─ Layer N-2 (RO)
│ ├─ apt packages
│ └─ OS utilities
├─ Base Layer (RO)
│ └─ Ubuntu 22.04 (150MB)
└─────────────────────────────────┘

Efficiency: Layers shared across containers; only new/modified data stored
```

#### Production Usage Patterns

**Docker Registry (Repository)**:
```
Docker Hub (public, free):
  ├─ docker pull ubuntu:22.04 (millions of downloads)
  ├─ docker pull python:3.11-slim (official images)
  └─ docker pull mycompany/myapp:v1.2.3 (private)

Private Registry (on-premises):
  ├─ Docker Registry (simple, no UI)
  ├─ Harbor (enterprise, RBAC, scanning)
  ├─ Nexus (artifact manager, multiple artifact types)
  └─ AWS ECR (managed, tight AWS integration)

Image Naming Convention:
  registry.example.com:5000/mycompany/checkout-service:v1.2.3
  │                    │ │          │              │     │
  │ Registry URL       │ │ Org      │ App Name     │     └── Tag (version)
  │                    └─┤          │              └─── Repository path
  └────────────────────── Port (5000 for registry)
```

---

## Dockerfile Best Practices

### Textual Deep Dive

**Best Practice 1: Minimal Base Images**:
```dockerfile
# ❌ Bad: 300MB+ image
FROM ubuntu:22.04
RUN apt update && apt install -y python3 python3-pip build-essential

# ✅ Good: 50MB image
FROM python:3.11-slim
# Already has Python installed; only 150MB vs 300MB

# ✅ Best: 10MB image (if Python not needed for runtime)
FROM alpine:3.18
# Multi-stage build: compile in large image, run in tiny image
```

**Best Practice 2: Dockerfile Caching Layers**:
```dockerfile
# ❌ Bad: Cache busted on any code change
FROM python:3.11-slim
WORKDIR /app
COPY . .                          # Include entire repo
RUN pip install -r requirements.txt
RUN python app.py

# Problem: If code changes → COPY busts cache → Re-run pip install (slow)

# ✅ Good: Separate dependencies from code
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt  # Cache hit if requirements unchanged
COPY . .                             # Code layer (changes frequently)
RUN python app.py

# Benefit: Code changes DON'T re-run pip install (seconds faster builds)
```

**Best Practice 3: Security Hardening**:
```dockerfile
# Run as non-root user
RUN useradd -m -u 1000 appuser
USER appuser

# Read-only root filesystem
# (Run with: docker run --read-only ...)

# No unnecessary packages
RUN pip install --no-cache-dir requirements.txt
# --no-cache-dir: don't store pip cache (wasteful in containers)

# Minimal privileges
RUN chmod 755 /app  # Not 777 (world-writable)
```

**Best Practice 4: Health Checks**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Effect: Docker monitors container health
# ├─ Every 30 seconds: curl /health
# ├─ If HTTP 200 (exit 0) → Healthy
# ├─ If failure or timeout → Unhealthy
# └─ Orchestrator (Kubernetes) restarts unhealthy container
```

---

## Docker Compose

### Textual Deep Dive

#### Internal Working Mechanism

**Docker Compose** (Multi-container orchestration for development):
```yaml
version: '3.9'
services:
  web:
    build: .  # Build from current directory's Dockerfile
    ports:
      - "3000:3000"  # Host:Container
    environment:
      DATABASE_URL: postgres://db:5432/myapp
      REDIS_URL: redis://cache:6379
    depends_on:
      db:
        condition: service_healthy  # Wait for DB health check
  
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Persist data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 3
  
  cache:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:  # Named volume (managed by Docker)

networks:
  default:  # Built-in network; services DNS-resolvable by name
    # web can reach db via: postgres://db:5432
```

**Docker Compose Workflow**:
```
$ docker-compose up
  1. Build web image (if needed)
  2. Create network: myapp_default
  3. Start db service
    ├─ Run healthcheck
    ├─ Wait for healthy
    └─ Continue
  4. Start cache service
  5. Start web service (DATABASE_URL resolves to db:5432)
  6. Log all output to console (interleaved)

$ docker-compose down
  1. Stop all services (graceful termination)
  2. Remove containers
  3. Remove networks (volume data persists by default)
```

#### Production Usage Patterns

**Development vs. Production**:
```
Development (docker-compose):
  ├─ Single machine
  ├─ All services in one network
  ├─ Volume mounts for live code
  ├─ No high availability

Production (Kubernetes):
  ├─ Multi-machine cluster
  ├─ Service mesh (Istio, Linkerd)
  ├─ Immutable images (no live code mounts)
  ├─ High availability (replicas, auto-restart)
  ├─ Rolling deployments
  ├─ Observability (Prometheus, logs aggregation)
```

**Docker Compose Override Pattern**:
```yaml
# docker-compose.yml (base configuration)
services:
  web:
    image: myapp:latest
    replicas: 1  # Not for compose; for Kubernetes

# docker-compose.override.yml (dev-specific)
services:
  web:
    build: .  # Override: build locally
    volumes:
      - .:/app  # Live code mount
    environment:
      DEBUG: "true"

# Usage:
# Development: docker-compose up (loads docker-compose.yml + docker-compose.override.yml)
# Production: docker-compose -f docker-compose.yml up (ignores override)
```

---

## Docker Swarm

### Textual Deep Dive

#### Internal Working Mechanism

**Docker Swarm** (Built-in orchestration, lightweight alternative to Kubernetes):
```
Swarm Cluster:
├─ Manager Nodes (5 recommended, odd number for quorum)
│  ├─ Raft consensus (distributed state across all managers)
│  ├─ Store desired state (services, tasks, networks)
│  └─ Coordinate scheduling
├─ Worker Nodes (unlimited)
│  ├─ No decision-making
│  ├─ Run tasks (containers)
│  └─ Report health to managers

Task Scheduling:
  Global Service: Run 1 copy on every node
    └─ Example: logging daemon, monitoring agent
  
  Replicated Service: Run N copies (distributed)
    ├─ Manager decides where to place tasks
    ├─ Attempts to spread across nodes
    └─ Example: web service, 5 replicas
```

**Service Definition**:
```bash
$ docker service create \
  --name web \
  --replicas 5 \
  --publish 8080:8080 \
  --limit-memory 512M \
  --reserve-memory 256M \
  --constraint 'node.labels.type == web' \
  myapp:v1.2.3

Effect:
  ├─ Create service "web"
  ├─ Start 5 replicas across cluster
  ├─ Listen on port 8080 (all nodes route to healthy replicas)
  ├─ Memory limits: max 512M, reserve 256M (CPU-share)
  ├─ Only run on nodes with label type=web
  └─ Use image myapp:v1.2.3
```

#### Production Usage Patterns

**Rolling Updates**:
```bash
$ docker service update \
  --image myapp:v2.0.0 \
  --update-parallelism 1 \
  --update-delay 10s \
  web

Effect (rolling, 1 replica at a time):
  Time 0s: 5 replicas of v1.2.3 running
  Time 10s: Terminate 1 x v1.2.3, Start 1 x v2.0.0 (4 v1 + 1 v2)
  Time 20s: Terminate 1 x v1.2.3, Start 1 x v2.0.0 (3 v1 + 2 v2)
  Time 30s: (2 v1 + 3 v2)
  Time 40s: (1 v1 + 4 v2)
  Time 50s: (0 v1 + 5 v2) ← Update complete
  
  If health check fails during update:
    ├─ Pause update at current parallelism
    ├─ Operator investigates
    ├─ Manually rollback or continue
```

---

## Kubernetes vs. Docker

### Textual Deep Dive

**Comparison Matrix**:
```
┌─────────────────────────────┬──────────────┬────────────────────┐
│ Aspect                      │ Docker/Swarm │ Kubernetes         │
├─────────────────────────────┼──────────────┼────────────────────┤
│ Scale                       │ 100s nodes   │ 1000s+ nodes       │
│ Setup complexity            │ Simple       │ Complex            │
│ Learning curve              │ Hours        │ Weeks              │
│ Storage orchestration       │ Basic        │ Advanced (StatefulSets) │
│ Networking model            │ Overlay      │ Pod CIDR, SDN       │
│ Health checks               │ Basic        │ Liveness/Readiness │
│ Resource limits             │ Per container│ Per pod, namespace  │
│ Multi-region support        │ None         │ Federation         │
│ Service mesh integration    │ None         │ Istio/Linkerd      │
│ Community adoption          │ Declining    │ Dominant           │
└─────────────────────────────┴──────────────┴────────────────────┘
```

**When to use Docker Swarm**:
```
✅ Good fit:
  - Single team, <50 servers
  - Development/testing environments
  - Tight Docker budget
  - Simple stateless services

❌ Bad fit:
  - Multi-region deployments
  - Stateful applications (databases)
  - Service mesh requirements
  - Large organizations with multiple teams
```

**When to use Kubernetes**:
```
✅ Good fit:
  - Enterprise scale (100s+ services)
  - Multi-cloud strategy
  - Stateful applications (via StatefulSets)
  - Managed service (EKS, GKE, AKS)
  - DevOps best practices enforcement

❌ Overkill for:
  - Single simple application
  - Team new to containerization
  - Very resource-constrained environments
```

---

## Containerization Best Practices

### Textual Deep Dive

**1. Image Security**:
```
Build Pipeline:
  Code → Build Image → Scan Image → Push to Registry → Deploy

Image Scanning (detect known vulnerabilities):
  Tools: Trivy, Grype, Snyk, Twistlock
  
  $ trivy image myapp:v1.2.3
  
  Output:
  ├─ Base OS vulnerabilities (Ubuntu, glibc, etc.)
  ├─ Application library vulnerabilities (pip, npm packages)
  ├─ Severity ratings (Critical, High, Medium, Low)
  └─ Remediation (update base image, patch library)
  
  Remediation:
  ├─ Critical/High: Fail build, fix immediately
  ├─ Medium: Track in backlog, fix within sprint
  ├─ Low: Monitor, defer unless cluster exposed
```

**2. Container Resource Requests & Limits**:
```
Kubernetes Pod Definition:
  containers:
  - name: app
    image: myapp:v1.0.0
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "500m"

Behavior:
  ├─ Requests (minimum guaranteed)
  │  ├─ Scheduler: Only place pod if node has free resources
  │  ├─ Memory: 256MB reserved for this pod
  │  ├─ CPU: 100 millicores (0.1 CPU core)
  │  └─ Example: t3.small (1 core) = 10 pods @ 100m request
  └─ Limits (maximum allowed)
     ├─ Memory: If pod exceeds 512MB → OOMKilled (terminated)
     ├─ CPU: If pod exceeds 500m → Throttled (performance reduced)
     └─ Prevents noisy neighbor problem
```

**3. Image Versioning***

```
❌ Bad:
  myapp:latest  (ambiguous; could mean any version)
  Deployed: v1.5.2
  Re-deployed later: now it's v1.6.0 (breaking change!)
  
✅ Good Practices:
  Tags:
  ├─ Git commit SHA: myapp:abc123def456 (immutable, traceable)
  ├─ Semantic version: myapp:v1.2.3 (human-readable)
  ├─ Multiple tags: Same image, multiple tags
  │  └─ myapp:v1.2.3 AND myapp:v1.2 AND myapp:v1 AND myapp:latest
  │  └─ v1 → v1.2 → v1.2.3 (semantic versioning chain)
  └─ Environment-specific: myapp:staging-abc123
  
Rule: NEVER push myapp:latest to production
      Always pin exact version
```

---

## Real-World Containerization Examples

### Example 1: Multi-Service Docker Application

```docker
# App Structure:
# ├─ frontend/ (HTML, CSS, JS)
# ├─ api/ (Python Flask backend)
# ├─ worker/ (Python Celery async tasks)
# └─ docker-compose.yml

# frontend/Dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build  # Output: /app/dist

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80

# api/Dockerfile
FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y postgresql-client && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:5000/health || exit 1
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]

# worker/Dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser
CMD ["celery", "-A", "tasks", "worker", "-l", "info"]

# docker-compose.yml
version: '3.9'
services:
  frontend:
    build: ./frontend
    ports:
      - "80:80"
    environment:
      API_URL: http://api:5000

  api:
    build: ./api
    ports:
      - "5000:5000"
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
      CELERY_BROKER_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started

  worker:
    build: ./worker
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
      CELERY_BROKER_URL: redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 3

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:

networks:
  default:
    name: myapp_network
```

---

# ROSA (Red Hat OpenShift on AWS)

## ROSA Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**ROSA (Red Hat OpenShift Service on AWS)**: Managed Kubernetes distribution built on Red Hat OpenShift.

```
ROSA Architecture:
┌──────────────────────────────────────────────────────────┐
│                  AWS Account (Customer)                  │
├──────────────────────────────────────────────────────────┤
│  ROSA Cluster                                            │
│  ├─ Control Plane (Managed by Red Hat)                   │
│  │  ├─ API Server                                        │
│  │  ├─ etcd (distributed state store)                   │
│  │  ├─ Scheduler                                        │
│  │  ├─ Controller Manager                               │
│  │  └─ Hosted in Red Hat AWS Account                    │
│  │  └─ NOT visible/accessible to customer               │
│  │                                                       │
│  ├─ Worker Nodes (In Customer AWS Account)              │
│  │  ├─ EC2 instances (m5.xlarge typical)               │
│  │  ├─ kubelet (agent communicating with API Server)   │
│  │  ├─ containerd (container runtime)                   │
│  │  └─ Network: VPC in customer account                │
│  │                                                       │
│  └─ Networking                                          │
│     ├─ VPC Peering (customer VPC ↔ Red Hat VPC)       │
│     ├─ Internet Gateway (for egress)                   │
│     └─ Load Balancers (ALB/NLB for ingress)           │
│                                                         │
│  Observability                                         │
│  ├─ Red Hat managed (not customer-facing by default)   │
│  ├─ CloudWatch integration (customer can see metrics)  │
│  └─ Prometheus + Grafana (built-in; optional access)   │
└──────────────────────────────────────────────────────────┘
```

**OpenShift vs. Kubernetes**:
```
Kubernetes (vanilla):
├─ Minimal + ecosystem
├─ Requires additional tools (networking, storage, auth)
└─ Community-driven

OpenShift (Red Hat distribution):
├─ Kubernetes + extras
├─ Integrated: networking (SDN), storage (Dynamic provisioning)
├─ Integrated auth: LDAP, OAuth, SAML
├─ Source-to-Image (S2I): Build directly from source code
├─ Enterprise support (SLA, patching)
└─ Web console (user-facing UI, role management)
```

#### Production Usage Patterns

**ROSA Cluster Architecture**:
```
ROSA High-Availability Setup:
┌────────────────────────────────────────────────────────┐
│              Load Balancer (ALB/NLB)                   │
│        (Distributes incoming traffic)                 │
├────────────────────────────────────────────────────────┤
│  ┌──────────────┬──────────────┬──────────────┐       │
│  │  AZ 1a       │  AZ 1b       │  AZ 1c       │       │
│  ├──────────────┼──────────────┼──────────────┤       │
│  │ Node:        │ Node:        │ Node:        │       │
│  │ m5.xlarge    │ m5.xlarge    │ m5.xlarge    │       │
│  │ Replica:3    │ Replica:3    │ Replica:3    │       │
│  │              │              │              │       │
│  │ + Pod:       │ + Pod:       │ + Pod:       │       │
│  │  ├─ App v1   │  ├─ App v1   │  ├─ App v1   │       │
│  │  ├─ App v2   │  ├─ App v2   │  ├─ App v2   │       │
│  │  └─ System   │  └─ System   │  └─ System   │       │
│  │    pods      │    pods      │    pods      │       │
│  └──────────────┴──────────────┴──────────────┘       │
│                                                        │
│  Persistent Storage (EBS volumes)                     │
│  ├─ Database volume (gp3, 100GB)                      │
│  └─ Replicated across AZs                            │
└────────────────────────────────────────────────────────┘
```

---

## ROSA Architecture

### Textual Deep Dive

**ROSA Control Plane** (Hosted by Red Hat):
```
Red Hat AWS Account:
├─ Control Plane Cluster (shared infrastructure)
│  ├─ Multiple API Server replicas (HA)
│  ├─ etcd cluster (distributed state, HA)
│  ├─ Controllers (StatefulSet, Deployment, Job, etc.)
│  ├─ Monitoring & Metering
│  └─ Shared compute, network, storage
│     (multiple customer clusters share infra)
│
└─ Communication:
   ├─ Private link between customer cluster + control plane
   ├─ Customer nodes connect to API Server (TLS 1.3)
   ├─ No public IP exposure
   └─ AWS-managed security groups
```

**ROSA Data Plane** (In Customer Account):
```
Customer AWS Account:
├─ VPC: 10.0.0.0/16
│  ├─ Public subnets (0.0/24, 1.0/24) - NAT Gateway
│  ├─ Private subnets (10.0/24, 11.0/24) - No direct internet
│  └─ Endpoint (for kubeapi access)
│
├─ Machine Set (Auto Scaling Group)
│  ├─ Worker nodes: 3-300 (configurable)
│  ├─ Instance type: m5.large (typical)
│  ├─ Volume: gp3 (120GB, encrypted)
│  └─ Auto-triggers scaling based on CPU/memory
│
├─ Networking
│  ├─ SDN (Software-Defined Network - Calico or OVN)
│  ├─ Service CIDR: 172.30.0.0/16
│  ├─ Pod CIDR: 10.128.0.0/14
│  └─ Network policies (internal firewall rules)
│
└─ Storage
   ├─ EBS volumes (gp3 default)
   ├─ EFS (shared filesystem)
   └─ StorageClass provisioning
```

---

## ROSA Installation & Configuration

### Textual Deep Dive

**ROSA Setup Flow**:
```bash
# Step 1: Create AWS account + IAM user with admin
# Step 2: Install ROSA CLI
$ aws s3 cp s3://rosa-quickstart/rosa /usr/local/bin/
$ rosa version

# Step 3: Verify AWS permissions
$ rosa verify permissions --region us-east-1

# Step 4: Create cluster
$ rosa create cluster \
    --cluster-name my-app-prod \
    --region us-east-1 \
    --version 4.13 \
    --compute-machine-type m5.xlarge \
    --replicas 3 \
    --enable-autoscaling \
    --min-replicas 3 \
    --max-replicas 10 \
    --machine-cidr 10.0.0.0/16

# Output: Cluster ID, Cluster URL, etc.
# Wait: 30-45 minutes for provisioning

# Step 5: Configure access
$ rosa create admin -c my-app-prod
# Output: kubeadmin user + password

$ aws s3 cp s3://rosa-quickstart/kubectl /usr/local/bin/
$ oc login https://api.my-app-prod.xxx.p1.openshiftapps.com:6443 \
    -u kubeadmin -p password

# Step 6: Verify cluster
$ oc get nodes
# Output:
# NAME                       STATUS   ROLES
# ip-10-0-10-100.ec2.internal Ready   worker
# ip-10-0-11-200.ec2.internal Ready   worker
# ip-10-0-12-150.ec2.internal Ready   worker

$ oc get projects  # OpenShift namespaced projects
```

**ROSA Configuration (PostInstall)**:
```yaml
# Configure ingress
apiVersion: operators.openshift.io/v1
kind: IngressController
metadata:
  name: default
  namespace: openshift-ingress-operator
spec:
  replicas: 3
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/infra: ""
  endpointPublishingStrategy:
    type: LoadBalancerService

# Configure router
apiVersion: v1
kind: Service
metadata:
  name: router-lb
  namespace: openshift-ingress
spec:
  type: LoadBalancer
  selector:
    ingresscontroller.operator.openshift.io/deployment-ingresscontroller: default
  ports:
    - port: 80
      targetPort: 80
    - port: 443
      targetPort: 443
```

---

## ROSA Networking

### Textual Deep Dive

**Network Architecture**:
```
Internet (User Requests)
    ↓ (DNS rosa.example.com)
    ↓ Route53 (AWS-managed DNS)
    ↓
ALB (Application Load Balancer)
    ├─ Public IP: 203.0.113.50
    ├─ Listener: 443 (HTTPS)
    ├─ Routing: rosa.example.com → OpenShift Router Service
    └─ Cross-AZ (AZ-1a, AZ-1b, AZ-1c)
    ↓
OpenShift Router (Ingress Controller)
    ├─ Namespace: openshift-ingress
    ├─ Pod: router-xxxxx
    ├─ TLS termination (customer certificate)
    ├─ Host-based routing (URL path → service)
    └─ 3 replicas (HA)
    ↓
OpenShift Service
    ├─ Service Name: myapp-service
    ├─ Port: 8080
    ├─ Selector: app=myapp
    └─ Load balances to 3 Pod replicas
    ↓
Application Pod
    ├─ Running on worker node
    ├─ Container listening on 8080
    └─ Logs visible via: oc logs pod/myapp-xxxxx
```

**Network Policies** (Micro-segmentation / Zero Trust):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  podSelector: {}  # Match all pods
  policyTypes:
  - Ingress
  - Egress
  ingress: []  # No inbound traffic allowed
  egress: []   # No outbound traffic allowed

---
# Exception: Allow App Tier → Database Tier
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: app
    ports:
    - protocol: TCP
      port: 5432
```

---

## CI/CD Pipelines

### Textual Deep Dive

#### Internal Working Mechanism

**CI/CD Pipeline Flow**:
```
Source Control Event (git push)
    ↓
Git Webhook → CI/CD Platform
    ↓
Pipeline Trigger:
├─ Pull code from repository
├─ Stage 1 (Build):
│  ├─ Run tests (unit, integration)
│  ├─ Build artifacts (compile, bundle)
│  ├─ Publish to artifact repository
│  └─ Publish to container registry (Docker image)
├─ Stage 2 (Test):
│  ├─ Deploy to staging environment
│  ├─ Run smoke tests + integration tests
│  ├─ Load testing (verify performance baseline)
│  └─ Security scanning (SAST, dependency scanning)
├─ Stage 3 (Approval):
│  ├─ Manual approval gate
│  ├─ Slack/email notification
│  └─ Requires team lead sign-off
└─ Stage 4 (Deploy):
   ├─ Deploy to production
   ├─ Canary deployment (10% traffic)
   ├─ Monitoring (error rate, latency)
   ├─ Gradual rollout (10% → 50% → 100%)
   └─ Or automatic rollback (if error rate spike)
```

#### CI/CD Tools (Comparison)

| Tool | Architecture | Pros | Cons | Best For |
|------|-------------|------|------|----------|
| **Jenkins** | Master + Agents | Self-hosted, highly customizable | Complex setup, maintenance | Enterprise infrastructure |
| **GitLab CI** | Server + Runners | Git-native, built-in, container-based | Vendor lock-in | Teams on GitLab |
| **GitHub Actions** | GitHub-hosted | Simplicity, tight GitHub integration | Limited free tier | GitHub repositories |
| **CircleCI** | Cloud + Self-hosted | User-friendly, fast | Limited free tier | Small/medium teams |
| **ArgoCD** | Kubernetes-native | Git-ops, declarative | Only for Kubernetes | Cloud-native apps |

---

## CI/CD Pipeline Components

### Textual Deep Dive

**Source Control Integration**:
```
GitHub/GitLab Repository
├─ Webhooks: Trigger pipeline on push/PR
├─ Branch protection: Require passing tests before merge
├─ CODEOWNERS: Require review from specific teams
└─ Status checks: CI/CD results displayed on PR

Jenkins Pipeline Example:
pipeline {
  agent any
  triggers {
    githubPush()  # Trigger on GitHub push
  }
  stages {
    stage('Build') {
      steps {
        sh 'npm install'
        sh 'npm run build'
      }
    }
    stage('Test') {
      steps {
        sh 'npm test'
      }
    }
    stage('Deploy') {
      when {
        branch 'main'  # Only deploy from main
      }
      steps {
        sh 'docker build -t myapp:${BUILD_NUMBER} .'
        sh 'docker push myregistry.azurecr.io/myapp:${BUILD_NUMBER}'
      }
    }
  }
}
```

**Build Optimization**:
```
Docker Layer Caching:
  ├─ First build: 5 minutes (download base image, install deps)
  ├─ Second build: 30 seconds (layers cached, only code layer rebuilt)
  └─ Speedup: 10x with smart layer ordering

Artifact Caching:
  ├─ Maven: ~/.m2 cache persisted across builds
  ├─ npm: node_modules cached
  └─ Result: Dependencies not re-downloaded

Parallel Testing:
  ├─ Unit tests (60 seconds)
  ├─ Integration tests (120 seconds)
  ├─ Security scanning (45 seconds)
  └─ All in parallel: 120 seconds total (vs. 225 sequential)
```

---

## CI/CD Pipeline Configuration

### Textual Deep Dive

**Deployment Strategies**:
```
Strategy 1: All-at-Once (Fastest, Risky)
  v1 v1 v1 → Stop all → v2 v2 v2
  Downtime: 2 minutes
  Rollback: Manual, slow
  Use Case: Non-critical, low traffic

Strategy 2: Rolling (Balanced)
  v1 v1 v1 → v1 v2 v1 → v2 v2 v1 → v2 v2 v2
  Downtime: 0
  Rollback: Manual, 10 minutes
  Use Case: Standard production deployments
  Orchestration: Kubernetes rolling update

Strategy 3: Canary (Safe, Monitored)
  v1 v1 v1 → v1 v1 v1+v2 (10% traffic) → v1 v1 v2 → v1 v2 v2 → v2 v2 v2
  Duration: 20 minutes
  Automatic rollback: If error rate spikes in canary
  Use Case: High-traffic, business-critical
  Orchestration: Flagger, Argo Rollouts, service mesh

Strategy 4: Blue-Green (Instant rollback)
  Blue environment (v1, serving 100% traffic)
  Green environment (v2, 0% traffic, warming up)
  When green healthy → Switch 100% to green (instant)
  If problem → Switch back to blue (instant rollback)
  Cost: 2x infrastructure
  Use Case: Critical production, SLA <5 min RTO
```

---

## CI/CD Best Practices

### Textual Deep Dive

**1. Shift-Left Security**:
```
Traditional Pipeline:
  Build → Test → Deploy → Security Review (SLOW, late)

Shift-Left Pipeline:
┌─────────────────────────────────────────────┐
│ Pre-Push (Developer machine)                │
├─────────────────────────────────────────────┤
│ $ git hooks (pre-commit): Lint, format     │
│ $ Local security scan: TruffleHog (secrets)│
│ $ SAST: SonarQube local analysis           │
│                                            │
├─────────────────────────────────────────────┤
│ CI Pipeline (after push)                   │
├─────────────────────────────────────────────┤
│ $ Source code security (SAST)              │
│ $ Dependency check (known CVEs)            │
│ $ Container scanning (Trivy, Grype)        │
│ $ Infrastructure scanning (Checkov)        │
│ $ Test coverage gate (>80% required)       │
│ → Fail fast if security issues             │
│                                            │
├─────────────────────────────────────────────┤
│ Post-Deploy (Runtime)                      │
├─────────────────────────────────────────────┤
│ $ DAST (Dynamic Application Security Test) │
│ $ Runtime monitoring (RASP)                │
│ $ Continuous compliance                    │
│                                            │
└─────────────────────────────────────────────┘

Result: Security issues caught early (minutes after code);
        not at deployment gate (hours/days later)
```

**2. Pipeline as Code (GitOps)**:
```yaml
# .github/workflows/deploy.yml (GitHub Actions)
name: Deploy

on:
  push:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v3
      
      - name: Build image
        run: |
          docker build -t ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} .
          docker tag ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }} \
                     ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
      
      - name: Push image
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ${{ env.REGISTRY }} -u ${{ github.actor }} --password-stdin
          docker push ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
      
      - name: Deploy to staging
        run: |
          helm upgrade --install myapp ./helm \
            --namespace staging \
            --set image.tag=${{ github.sha }}
      
      - name: Smoke tests
        run: |
          sleep 30  # Wait for pod startup
          curl -f https://staging.myapp.com/health || exit 1
      
      - name: Production approval
        if: success()
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.create({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Ready for production deployment'
            })

Benefit: Pipeline is version-controlled; changes require code review
```

---

## CI/CD Best Practices & Troubleshooting

### Textual Deep Dive

**Common Pitfalls**:
```
Pitfall 1: Flaky Tests
  Problem: Tests pass 9/10 times; randomly fail (no code change)
  Causes:
    ├─ Timing issues (race conditions)
    ├─ External service dependency (API call timeout)
    └─ Test data contamination (tests affect each other)
  
  Solution:
    ├─ Use test containers (isolated DB per test run)
    ├─ Mock external services (don't call real APIs)
    ├─ Add retry logic (3 attempts before failing)
    └─ Flag flaky tests; prioritize fixing

Pitfall 2: Long Build Times
  Problem: 30-minute build; slows developer feedback loop
  Causes:
    ├─ Docker layer caching not optimized
    ├─ Dependency re-download every build
    ├─ Tests running sequentially
    └─ Artifact bloat
  
  Solution:
    ├─ Cache layers (see Docker best practices)
    ├─ Parallelize tests
    ├─ Trim unused dependencies
    └─ Target: <5 minutes (should iterate fast)

Pitfall 3: Image Bloat
  Problem: 500MB image; slow pushes, long pulls
  Causes:
    ├─ Base image too large
    ├─ Build tools left in runtime image
    ├─ Old layers not cleaned
    └─ Unused dependencies
  
  Solution:
    ├─ Multi-stage build (huge improvement)
    ├─ Alpine base images
    ├─ RUN rm -rf (clean up cache in same RUN)
    └─ Target: <100MB for typical app
```

---

## Infrastructure as Code (Terraform)

### Textual Deep Dive

#### Terraform Concepts

**Infrastructure as Code Philosophy**:
```
Desired Infrastructure (Terraform Code):
  resource "aws_instance" "web" {
    ami           = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    tags = {
      Name = "web-server"
    }
  }

Terraform Apply:
  ├─ Plan: What WILL change (dry-run)
  ├─ Apply: Execute the plan
  └─ State: Store current state in terraform.tfstate

Benefit:
  ├─ Reproducible: Another engineer runs same Terraform → same result
  ├─ Auditable: Git history shows who changed what, when
  ├─ Testable: terraform validate, terraform fmt
  ├─ Collaborative: Code review before merge to main
  └─ Reversible: Rollback by reverting to previous commit
```

**State Management** (Critical):
```
terraform.tfstate (Local):
  ├─ Contains: All resources, their IDs, attributes
  ├─ Problem: Local file isn't shared; team members overwrite each other
  ├─ Problem: Stored in clear text; credentials visible
  └─ Usage: Development only

terraform.tfstate (Remote, S3 backend):
  ├─ S3 bucket (us-east-1)
  ├─ Versioning enabled (historical state)
  ├─ Encryption enabled (KMS)
  ├─ Lock file (DynamoDB table)
  │  └─ Prevents concurrent terraform apply (race condition)
  └─ Usage: Team collaboration, production

Benefits:
  ├─ Single source of truth (cloud state)
  ├─ Team access (all engineers see same state)
  ├─ Disaster recovery (S3 versioning for rollback)
  └─ Encryption (sensitive data protected)
```

#### Terraform Architecture

**Core Concepts**:
```
Provider (AWS, Azure, GCP):
  ├─ Authentication (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  ├─ Region (us-east-1)
  └─ API: Communicates with cloud provider

Resource (Cloud object):
  resource "aws_instance" "web" {
    ami           = "ami-xxx"
    instance_type = "t2.micro"
  }
  
  Unique identifier: aws_instance.web
  Used in: references (aws_security_group.allow_ssh.id → referenced by instance)

Data Source (Read-only):
  data "aws_ami" "ubuntu" {
    filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
  }
  
  Usage: Get existing resource attributes without managing it
         (e.g., latest Ubuntu AMI)

Variables (Input):
  variable "instance_type" {
    default = "t2.micro"
  }
  
  Usage: terraform apply -var="instance_type=t2.small"

Outputs (Return values):
  output "instance_ip" {
    value = aws_instance.web.public_ip
  }
  
  Usage: Echo back important values after apply
```

---

#### Terraform Configuration

**Basic Example**:
```hcl
# main.tf

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Version 5.x
    }
  }
  
  backend "s3" {
    bucket = "mycompany-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = "MyApp"
    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone = var.availability_zones[count.index]
  
  tags = {
    Name = "${var.project_name}-public-${count.index}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

#### Terraform State Management

**State File Structure**:
```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "abc123",
  "outputs": {},
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-0a1b2c3d4e5f6g7h8",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t2.micro",
            "public_ip": "203.0.113.50",
            "private_ip": "10.0.1.10",
            ...
          }
        }
      ]
    }
  ]
}
```

**State Lock** (Prevents concurrent modifications):
```
Scenario: Two engineers run terraform apply simultaneously

Without lock:
  Engineer A: Read state (serial=5)
  Engineer B: Read state (serial=5)  ← Same version!
  Engineer A: Modify, write (serial=6)
  Engineer B: Modify, write (serial=6)  ← Conflict! Engineer B overwrites A's changes
  Result: Lost changes; corruption

With lock (DynamoDB):
  Engineer A: Acquire lock
  Engineer A: Read state
  Engineer A: Modify, write
  Engineer A: Release lock
  
  Engineer B: Attempt lock → BLOCK (A holds lock)
  Engineer B: Wait...
  Engineer A: Release lock
  
  Engineer B: Acquire lock (now available)
  Engineer B: Read state (serial=6, sees A's changes)
  Engineer B: Modify, write (serial=7)
  Engineer B: Release lock
  
  Result: Sequential, no conflict
```

#### Terraform Modules

**Module Pattern** (Reusable components):
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  count             = var.public_subnet_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, 2, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

# modules/vpc/variables.tf
variable "cidr_block" {
  type = string
}

variable "public_subnet_count" {
  type = number
  default = 2
}

# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

---

# main.tf (Root module)
module "vpc" {
  source = "./modules/vpc"
  
  cidr_block           = "10.0.0.0/16"
  public_subnet_count  = 3
}

module "eks_cluster" {
  source = "./modules/eks"
  
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  cluster_name  = "my-app-prod"
}

# Benefit: modules/vpc is reusable across projects
#          modules/eks uses vpc module's outputs
```

#### Terraform Best Practices

**1. State File Security**:
```
✅ DO:
  ├─ S3 backend with versioning + encryption
  ├─ DynamoDB lock to prevent concurrent access
  ├─ Restrict IAM permissions: only developers can access S3
  ├─ Enable MFA delete (can't delete state without MFA)
  ├─ Enable logging (CloudTrail tracks access)
  └─ Regular backups (state versioning)

❌ DON'T:
  ├─ Store terraform.tfstate in Git (secrets exposed)
  ├─ Share state file via email
  ├─ Store credentials in Terraform (use IAM roles)
  └─ Make S3 state bucket public
```

**2. Environment Separation**:
```
Directory structure:
├─ modules/ (reusable components)
│  ├─ vpc/
│  ├─ eks/
│  ├─ rds/
│  └─ alb/
├─ environments/
│  ├─ dev/
│  │  ├─ main.tf (calls modules)
│  │  ├─ terraform.tfvars (dev-specific values)
│  │  └─ terraform.tfstate (dev state)
│  ├─ staging/
│  │  ├─ main.tf
│  │  ├─ terraform.tfvars (staging-specific)
│  │  └─ terraform.tfstate (staging state)
│  └─ prod/
│     ├─ main.tf
│     ├─ terraform.tfvars (prod-specific)
│     └─ terraform.tfstate (prod state)
└─ shared/ (shared configs)
   └─ variables.tf

Benefits:
  ├─ Clear separation (dev != staging != prod)
  ├─ Different state files (no accidental prod deployment)
  ├─ Same modules used everywhere (consistency)
  └─ Environment-specific values in terraform.tfvars
```

**3. Code Quality**:
```bash
# Lint & Validate
$ terraform fmt -recursive .
# Standardize formatting (tabs, spacing)

$ terraform validate
# Check syntax, resource references

$ tflint
# Linter for Terraform (best practices)

# Security scanning
$ checkov -d .
# Scan for misconfigurations, secrets, compliance

$ tfsec .
# Security-focused scanning

# Testing (optional)
$ terraform test
# Run validation tests (Terraform 1.6+)
```

#### Real-World Terraform Example

```hcl
# Production Kubernetes on EKS

# environments/prod/main.tf

module "vpc" {
  source = "../../modules/vpc"
  
  name                 = "eks-prod"
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  environment = "prod"
}

module "eks" {
  source = "../../modules/eks"
  
  cluster_name    = "myapp-prod"
  cluster_version = "1.27"
  subnet_ids      = module.vpc.private_subnet_ids
  
  node_groups = {
    general = {
      desired_size    = 3
      min_size        = 3
      max_size        = 10
      instance_types  = ["t3.large"]
      disk_size       = 50
      capacity_type   = "ON_DEMAND"
    }
    
    spot = {
      desired_size    = 2
      min_size        = 0
      max_size        = 5
      instance_types  = ["t3.large"]
      disk_size       = 50
      capacity_type   = "SPOT"  # 70% cheaper, can be terminated
    }
  }
  
  enabled_cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  environment = "prod"
}

module "rds" {
  source = "../../modules/rds"
  
  identifier           = "myapp-prod"
  engine              = "postgres"
  engine_version      = "15.3"
  instance_class      = "db.r6i.large"
  allocated_storage   = 100
  max_allocated_storage = 500  # Auto-scaling
  
  db_name  = "myappdb"
  username = "postgres"
  password = random_password.db_password.result
  
  multi_az            = true
  backup_retention    = 30
  backup_window       = "03:00-04:00"
  maintenance_window  = "sun:04:00-sun:05:00"
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  skip_final_snapshot = false
  final_snapshot_identifier = "myapp-prod-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "prod/rds/password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id      = aws_secretsmanager_secret.db_password.id
  secret_string  = random_password.db_password.result
}

# Outputs
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  value = module.rds.db_instance_endpoint
}
```

---

# Configuration Management (Chef)

## Chef Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**Chef Architecture**:
```
Chef Workstation (Developer machine)
  ├─ Knife CLI (chef commands, uploads to server)
  │  
├─ Chef Server (Centralized configuration repository)
│  ├─ Cookbooks (versions stored)
│  ├─ Roles (server profiles)
│  ├─ Environments (dev/staging/prod configurations)
│  ├─ Attributes (variables for cookbooks)
│  └─ Data Bags (encrypted secrets, environment-specific data)
│
├─ Target Nodes (Servers to manage)
│  ├─ Chef Client (agent running on each node)
│  ├─ Node Convergence (Pull cookbooks → Apply recipes → Report status)
│  └─ Runs every 30 minutes (configurable)
│
└─ Auditing & Reporting
   ├─ Node state (what's installed, configurations)
   ├─ Compliance reports (did node converge successfully?)
   └─ Chef Analytics (compliance trends)
```

**Recipe Execution Flow**:
```
Chef Client Run (every 30 minutes or on-demand)

1. Ohai (gather node facts)
   ├─ OS type, version, IP address, installed packages
   ├─ CPU, memory information
   └─ Network configuration

2. Authorize (authenticate with Chef Server)
   ├─ Use node private key (stored on client)
   ├─ Chef Server verifies identity
   └─ Grant access to recipes/attributes

3. Fetch (pull cookbooks/recipes relevant to node)
   ├─ Query: "What recipes should run on this node?"
   ├─ Answer: Based on node's role and environment
   └─ Download recipes to /var/chef/cache

4. Compile (convert recipes to executable format)
   ├─ Evaluate Ruby code in recipes
   ├─ Resolve attributes (which values apply?)
   ├─ Build resource collection (ordered list of actions)
   └─ Stop if there's a syntax error

5. Converge (execute resources to reach desired state)
   ├─ For each resource:
   │  ├─ Check current state (is package installed?)
   │  ├─ Compare to desired state (should be version 1.2.3)
   │  ├─ Take action if different (install/update/remove)
   │  └─ Report success or failure
   └─ Continue even if one resource fails (default)

6. Report (send results to Chef Server)
   ├─ Success/failure of each resource
   ├─ Node attributes updated
   ├─ Logs stored on Chef Server
   └─ Triggers alerts if configured
```

#### Production Usage Patterns

**Cookbook Structure**:
```
cookbooks/
├─ base/
│  ├─ recipes/
│  │  ├─ default.rb (runs by default)
│  │  ├─ security.rb (security hardening)
│  │  └─ monitoring.rb (install monitoring agent)
│  ├─ attributes/
│  │  ├─ default.rb (default values)
│  │  └─ security.rb (security settings)
│  ├─ files/
│  │  └─ /etc/security/audit.conf (static files)
│  ├─ templates/
│  │  └─ config.erb (templated files with variables)
│  └─ metadata.rb (cookbook metadata, dependencies)
│
├─ web/
│  ├─ recipes/
│  │  └─ default.rb (installs Nginx, starts service)
│  ├─ templates/
│  │  └─ nginx.conf.erb (nginx configuration)
│  └─ metadata.rb
│
└─ db/
   ├─ recipes/
   │  └─ default.rb (installs PostgreSQL, initializes DB)
   └─ metadata.rb
```

**Role Definition** (Server profile):
```ruby
# roles/web-production.rb

name "web-production"
description "Production web server"
run_list(
  "recipe[base]",
  "recipe[base::security]",
  "recipe[base::monitoring]",
  "recipe[web]"
)

default_attributes(
  "nginx" => {
    "version" => "1.21.0",
    "worker_processes" => 4,
    "keepalive_timeout" => 65
  },
  "monitoring" => {
    "enabled" => true,
    "agent" => "datadog"
  }
)

override_attributes(
  "firewall" => {
    "enabled" => true,
    "inbound_rules" => [
      { "port" => 80, "action" => "accept" },
      { "port" => 443, "action" => "accept" }
    ]
  }
)
```

#### DevOps Best Practices

**1. Idempotency** (Running recipe multiple times = same result):
```ruby
# ❌ BAD: Not idempotent
execute "install nginx" do
  command "apt-get install nginx"  # Runs every time, even if installed
end

# ✅ GOOD: Idempotent
package "nginx" do
  action :install
  notifies :start, "service[nginx]", :immediately
end

# Chef checks: Is nginx installed? 
#   ├─ Yes → Skip (no action)
#   └─ No → Install
```

**2. Attribute Precedence** (Multiple places to set values):
```
1. Default attributes (lowest priority)
2. Environment attributes
3. Role attributes
4. Node attributes
5. Override attributes (highest priority)

Example:
  default["apache2"]["port"] = 80        # Default
  override["apache2"]["port"] = 8080     # Override (wins)
  
  Result: apache2 listens on 8080 (override takes precedence)
```

**3. Test-Driven Development (ChefSpec, InSpec)**:
```bash
# ChefSpec (unit tests)
$ chef exec rspec
# Simulates recipe execution without running on real node
# Checks: Does recipe install the right package? Is service started?

# InSpec (integration/compliance tests)
$ inspec exec profiles/web_compliance.yml -t ssh://prod-server
# Runs on actual node; verifies real state
# Checks: Is port 80 open? Is nginx running? Are permissions correct?
```

#### Common Pitfalls

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Recipe side effects | SSH into server manually; manual changes lost on next converge | Recipes should be idempotent; all desired state in recipes |
| Attribute confusion | Multiple sources define same value; unclear which wins | Document precedence; use role/environment attributes strategically |
| Version mismatch | Cookbook version 1.0 on chef server; client has 0.9 | Version lock in runlist: `recipe[nginx@2.0.0]` |
| Long convergence | Recipes take 10+ minutes; slow deployments | Profile recipes; optimize resource calls |
| No testing | Recipe works locally; fails in production | ChefSpec + InSpec in pipeline before push |

---

## Chef Architecture

### Textual Deep Dive

**Chef Client Modes**:
```
Chef Client - Pull Mode (Standard):
  ├─ Node has private key (stored at /etc/chef/client.pem)
  ├─ Scheduled run (every 30 min via cron)
  ├─ Node initiates connection to Chef Server
  ├─ Fetches recipes designated for this node
  └─ Converges (applies recipes)

Chef Solo - Standalone Mode:
  ├─ No Chef Server (runs locally on node)
  ├─ Recipes copied to node via Packer/Terraform
  ├─ chef-solo command runs recipes
  └─ Use case: Golden image creation (immutable VM)

Chef Zero - Local Testing:
  ├─ Lightweight Chef Server on workstation
  ├─ Test recipes before uploading to production
  └─ chef-zero command spawns temporary server
```

**Node Anatomy** (What Chef tracks):
```json
{
  "name": "web-prod-01",
  "fqdn": "web-prod-01.example.com",
  "ipaddress": "10.0.1.50",
  "os": "ubuntu",
  "os_version": "22.04",
  "hostname": "web-prod-01",
  "cpu": {
    "total": 4,
    "cores_per_socket": 2
  },
  "memory": {
    "total": "8192MB"
  },
  "automatic": {
    "platform": "ubuntu",
    "platform_version": "22.04.1",
    "packages": {
      "nginx": "1.21.0-1~jammy",
      "postgresql": "14.2"
    }
  },
  "run_list": [
    "role[web-production]",
    "recipe[monitoring]"
  ]
}
```

---

## Chef Configuration & Resources

### Textual Deep Dive

**Common Chef Resources**:
```ruby
# Package management
package "nginx" do
  action :install
  version "1.21.0"
end

# Service management
service "nginx" do
  action [:enable, :start]
  subscribes :reload, "template[/etc/nginx/nginx.conf]"
end

# File management
file "/etc/nginx/nginx.conf" do
  owner "root"
  group "root"
  mode "0644"
  action :create
end

# Template files (with variables)
template "/etc/nginx/nginx.conf" do
  source "nginx.conf.erb"
  variables(
    worker_processes: node["nginx"]["worker_processes"],
    keepalive_timeout: node["nginx"]["keepalive_timeout"]
  )
  notifies :reload, "service[nginx]"
end

# Execute commands (use rarely; prefer explicit resources)
execute "initialize database" do
  command "psql -c 'CREATE DATABASE myapp;'"
  not_if "psql -lqt | cut -d '|' -f 1 | grep -qw myapp"
end

# User management
user "appuser" do
  uid 1000
  gid 1000
  home "/home/appuser"
  shell "/bin/bash"
  action :create
end

# Directory management
directory "/var/log/myapp" do
  owner "appuser"
  group "appuser"
  mode "0755"
  recursive true
end
```

**Recipe with Guard Clauses** (Conditional execution):
```ruby
# recipes/web.rb

# Skip if already on web-production role
return unless node.roles.include?("web-production")

# Install only on Ubuntu
if node["platform"] == "ubuntu"
  package "nginx-full"
else
  package "nginx"  # Different package on CentOS
end

# Use different template based on version
template "/etc/nginx/nginx.conf" do
  if node["nginx"]["version"].to_f >= 1.20
    source "nginx-1.20.conf.erb"
  else
    source "nginx-1.18.conf.erb"
  end
end

# Notify only if attribute enabled
service "nginx" do
  subscribes :restart, "template[/etc/nginx/nginx.conf]" if node["nginx"]["auto_restart"]
end
```

---

## Chef Best Practices

### Textual Deep Dive

**1. Cookbook Versioning & Testing**:
```bash
# Development workflow
$ berks install  # Install cookbook dependencies
$ kitchen test --log-level=debug  # Test-drive recipe
  ├─ Create: Spin up VM (Docker/EC2)
  ├─ Converge: Run recipes
  ├─ Verify: Run InSpec tests
  └─ Destroy: Clean up VM

# Before committing
$ chef exec cookstyle .  # Lint (style checks)
$ chef exec rspec        # Unit tests (ChefSpec)

# Upload versioned cookbook
$ knife cookbook upload nginx --freeze
# --freeze: Prevent overwriting this version (safety)
```

**2. Data Bags** (Encrypted configuration):
```ruby
# data_bags/production/db_credentials.json (encrypted via knife)
{
  "id": "db_credentials",
  "username": "admin",
  "password": "ENCRYPTED_TEXT",
  "host": "rds.example.com"
}

# In recipe: Fetch encrypted data bag item
creds = data_bag_item("production", "db_credentials")
template "/etc/myapp/database.yml" do
  variables(
    username: creds["username"],
    password: creds["password"],
    host: creds["host"]
  )
end

# Command line: knife data bag create
$ knife data bag create production
$ knife data bag from file production data_bags/production/db_credentials.json --secret-file ~/.chef/secret_key
```

**3. Policyfiles** (Version lock all dependencies):
```ruby
# Policyfile.rb
name "web-production"

run_list(
  "recipe[base]",
  "recipe[web]",
  "recipe[monitoring]"
)

cookbook "base", "= 2.5.0"
cookbook "web", "= 3.1.0"
cookbook "monitoring", "= 1.2.0"

# Generate lock file
$ chef install Policyfile.rb  # Creates Policyfile.lock.json

# Push to Chef Server as atomic update
$ chef push web-production Policyfile.rb
```

**4. Automated Testing Pipeline**:
```bash
# CI/CD integration (GitHub Actions / Jenkins)
stages:
  - lint
  - unit_test
  - integration_test
  - upload

lint:
  $ cookstyle --display-cop-names .
  # Fail if style violations

unit_test:
  $ rspec --format documentation
  # Chef spec tests (mock execution)

integration_test:
  $ kitchen test
  # Test on real VM; verify actual state

upload:
  $ knife cookbook upload --freeze
  # Only if all tests pass
```

---

## Real-World Chef Example

```ruby
# cookbooks/postgresql/recipes/default.rb

# Install PostgreSQL from official repository
apt_repository "postgresql" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{node["lsb"]["codename"]}-pgdg"
  components ["main"]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  action :add
end

# Install packages
package ["postgresql-#{node["postgresql"]["version"]}", "postgresql-contrib"] do
  action :install
end

# Create systemd override directory
directory "/etc/systemd/system/postgresql.service.d" do
  owner "root"
  group "root"
  mode "0755"
  recursive true
end

# Tune PostgreSQL for production
template "/etc/postgresql/#{node["postgresql"]["version"]}/main/postgresql.conf" do
  source "postgresql.conf.erb"
  variables(
    shared_buffers: node["postgresql"]["shared_buffers"],
    effective_cache_size: node["postgresql"]["effective_cache_size"],
    maintenance_work_mem: node["postgresql"]["maintenance_work_mem"],
    checkpoint_completion_target: 0.9,
    wal_buffers: "16MB",
    default_statistics_target: 100,
    random_page_cost: 1.1,
    effective_io_concurrency: 200,
    work_mem: node["postgresql"]["work_mem"],
    min_wal_size: "2GB",
    max_wal_size: "4GB",
    max_worker_processes: node["cpu"]["total"],
    max_parallel_workers_per_gather: (node["cpu"]["total"] / 2).to_i,
    max_parallel_workers: node["cpu"]["total"],
    max_parallel_maintenance_workers: (node["cpu"]["total"] / 2).to_i
  )
  notifies :restart, "service[postgresql]"
end

# Ensure data directory has correct permissions
directory "/var/lib/postgresql/#{node["postgresql"]["version"]}/main" do
  owner "postgres"
  group "postgres"
  mode "0700"
  recursive true
end

# Enable and start service
service "postgresql" do
  supports restart: true, reload: true, status: true
  action [:enable, :start]
end

# Create backup script
template "/usr/local/bin/pg-backup.sh" do
  source "pg-backup.sh.erb"
  owner "root"
  group "root"
  mode "0755"
  backup false
end

# Schedule daily backup
cron "postgresql-backup" do
  minute "0"
  hour "2"  # 2 AM
  command "/usr/local/bin/pg-backup.sh"
  user "postgres"
end

# Verify service is running
service "postgresql" do
  action [:enable, :start]
  supports status: true
  timeout 300  # 5 minute timeout
end
```

---

# Scripting (Python & Bash)

## Python Concepts for DevOps

### Textual Deep Dive

#### Internal Working Mechanism

**Python Execution Model**:
```
Python Script Execution:

1. Parsing (interpreter reads source code)
   └─ Checks syntax; reports errors before execution

2. Compilation (to bytecode)
   ├─ .py → .pyc (cached in __pycache__)
   ├─ Speeds up subsequent runs (no re-parsing)
   └─ Platform-independent (runs on any Python version)

3. Execution (via Python Virtual Machine - PVM)
   ├─ For loop → PVM instructions
   ├─ Variable assignment → Memory allocation
   └─ Function call → Stack frame creation

4. Modules/Imports
   ├─ import module: Loads code once; cached
   ├─ from module import func: Imports specific item
   └─ sys.path: List of directories to search for modules
```

**Virtual Environment Isolation**:
```
System Python:
/usr/bin/python3
  └─ Global site-packages (shared by all scripts)
  └─ Risk: Package conflicts between projects

Virtual Environment (venv):
project-a/
  ├─ venv/bin/python
  ├─ venv/lib/python3.11/site-packages/ (isolated)
  └─ requirements.txt (project dependencies)

project-b/
  ├─ venv/bin/python
  ├─ venv/lib/python3.11/site-packages/ (isolated)
  └─ requirements.txt

Benefits:
  ├─ project-a uses requests==2.28.0
  ├─ project-b uses requests==2.30.0
  └─ No conflict; each venv has its own version
```

#### Production Usage Patterns

**DevOps Python Script Template**:
```python
#!/usr/bin/env python3
"""
Infrastructure automation script for database backup.
Usage: python backup.py --database myapp --retention 30 --dry-run
"""

import argparse
import logging
import sys
import json
from typing import List, Dict, Optional
from datetime import datetime
import boto3
from botocore.exceptions import ClientError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DatabaseBackupManager:
    """Manages database backups to S3."""
    
    def __init__(self, db_host: str, db_name: str, s3_bucket: str, dry_run: bool = False):
        self.db_host = db_host
        self.db_name = db_name
        self.s3_bucket = s3_bucket
        self.dry_run = dry_run
        self.s3_client = boto3.client("s3", region_name="us-east-1")
        self.timestamp = datetime.utcnow().isoformat()
    
    def backup_database(self) -> bool:
        """Create database backup."""
        try:
            backup_file = f"{self.db_name}-{self.timestamp}.sql"
            logger.info(f"Starting backup: {backup_file}")
            
            if self.dry_run:
                logger.info(f"[DRY-RUN] Would backup {self.db_name} to {backup_file}")
                return True
            
            # Execute backup
            cmd = f"pg_dump -h {self.db_host} {self.db_name} > /tmp/{backup_file}"
            exit_code = os.system(cmd)
            
            if exit_code != 0:
                logger.error(f"Backup failed with exit code {exit_code}")
                return False
            
            # Upload to S3
            self.s3_client.upload_file(
                f"/tmp/{backup_file}",
                self.s3_bucket,
                f"backups/{backup_file}",
                ExtraArgs={"ServerSideEncryption": "AES256"}
            )
            
            logger.info(f"✓ Backup uploaded to s3://{self.s3_bucket}/backups/{backup_file}")
            return True
            
        except ClientError as e:
            logger.exception(f"AWS error: {e}")
            return False
        except Exception as e:
            logger.exception(f"Unexpected error: {e}")
            return False
    
    def cleanup_old_backups(self, retention_days: int) -> None:
        """Delete backups older than retention period."""
        try:
            from datetime import timedelta
            cutoff = datetime.utcnow() - timedelta(days=retention_days)
            
            response = self.s3_client.list_objects_v2(
                Bucket=self.s3_bucket,
                Prefix="backups/"
            )
            
            if "Contents" not in response:
                logger.info("No backups found for cleanup")
                return
            
            for obj in response["Contents"]:
                if obj["LastModified"].replace(tzinfo=None) < cutoff:
                    key = obj["Key"]
                    if self.dry_run:
                        logger.info(f"[DRY-RUN] Would delete {key}")
                    else:
                        self.s3_client.delete_object(Bucket=self.s3_bucket, Key=key)
                        logger.info(f"✓ Deleted old backup: {key}")
        
        except Exception as e:
            logger.exception(f"Cleanup failed: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="Backup database to S3"
    )
    parser.add_argument("--db-host", default="localhost", help="Database host")
    parser.add_argument("--database", required=True, help="Database name")
    parser.add_argument("--s3-bucket", default="company-backups", help="S3 bucket")
    parser.add_argument("--retention", type=int, default=30, help="Retention days")
    parser.add_argument("--dry-run", action="store_true", help="Dry run, no actual changes")
    
    args = parser.parse_args()
    
    manager = DatabaseBackupManager(
        db_host=args.db_host,
        db_name=args.database,
        s3_bucket=args.s3_bucket,
        dry_run=args.dry_run
    )
    
    # Backup
    if not manager.backup_database():
        logger.error("Backup failed")
        sys.exit(1)
    
    # Cleanup
    manager.cleanup_old_backups(args.retention)
    
    logger.info("✓ Backup process completed successfully")
    sys.exit(0)

if __name__ == "__main__":
    main()
```

---

## Python Libraries for DevOps

### Textual Deep Dive

**Essential Libraries**:
```python
# Infrastructure Automation
import boto3                 # AWS SDK (EC2, S3, RDS, etc.)
import paramiko              # SSH client (remote command execution)

# Configuration Management
import ansible              # Configuration orchestration
import salt                 # Remote execution framework

# Container/Kubernetes
import docker               # Docker Python SDK
import kubernetes           # Kubernetes Python client

# Data Processing
import pandas               # Data manipulation
import numpy                # Numerical computing

# Networking
import requests             # HTTP client
import socket               # Low-level networking

# Testing
import pytest               # Testing framework
import unittest             # Built-in testing

# Logging & Monitoring
import structlog            # Structured logging
import prometheus_client    # Prometheus metrics

# Utilities
import typer                # CLI argument parsing
import pyyaml               # YAML parsing
import python-dotenv        # Environment variable loading
```

**Practical Example: Infrastructure Scaling Script**:
```python
#!/usr/bin/env python3
"""
Auto-scale EC2 instances based on CPU utilization.
"""

import boto3
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)
ec2 = boto3.resource("ec2", region_name="us-east-1")
cloudwatch = boto3.client("cloudwatch", region_name="us-east-1")

def get_asg_metrics(asg_name: str, minutes: int = 5) -> dict:
    """Fetch CPU metrics for ASG."""
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(minutes=minutes)
    
    response = cloudwatch.get_metric_statistics(
        Namespace="AWS/EC2",
        MetricName="CPUUtilization",
        Dimensions=[{"Name": "AutoScalingGroupName", "Value": asg_name}],
        StartTime=start_time,
        EndTime=end_time,
        Period=60,
        Statistics=["Average"]
    )
    
    if response["Datapoints"]:
        avg_cpu = sum(d["Average"] for d in response["Datapoints"]) / len(response["Datapoints"])
        return {"avg_cpu": avg_cpu, "instance_count": len(ec2.instances.all())}
    return {"avg_cpu": 0, "instance_count": 0}

def scale_asg(asg_name: str, desired_count: int) -> bool:
    """Scale ASG to desired count."""
    autoscaling = boto3.client("autoscaling")
    try:
        autoscaling.set_desired_capacity(
            AutoScalingGroupName=asg_name,
            DesiredCapacity=desired_count
        )
        logger.info(f"Scaled {asg_name} to {desired_count} instances")
        return True
    except Exception as e:
        logger.error(f"Scale failed: {e}")
        return False

def main():
    asg_name = "web-server-asg"
    metrics = get_asg_metrics(asg_name)
    
    if metrics["avg_cpu"] > 70:  # High CPU
        new_count = metrics["instance_count"] + 2
        logger.warning(f"CPU high ({metrics['avg_cpu']:.1f}%), scaling up to {new_count}")
        scale_asg(asg_name, new_count)
    elif metrics["avg_cpu"] < 20:  # Low CPU
        new_count = max(metrics["instance_count"] - 1, 2)  # Min 2 instances
        logger.info(f"CPU low ({metrics['avg_cpu']:.1f}%), scaling down to {new_count}")
        scale_asg(asg_name, new_count)

if __name__ == "__main__":
    main()
```

---

## Bash Scripting for DevOps

### Textual Deep Dive

**Bash Script Template** (Error handling, logging):
```bash
#!/bin/bash

# Script: Deploy application to production
# Usage: ./deploy.sh --version v1.2.3 --environment prod --dry-run

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"
DRY_RUN=false
VERSION=""
ENVIRONMENT=""

# Logging
log() {
    local level="$1"
    shift
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# Error handling
trap 'log_error "Error on line $LINENO"; exit 1' ERR

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validation
if [[ -z "$VERSION" ]] || [[ -z "$ENVIRONMENT" ]]; then
    log_error "Missing required arguments"
    echo "Usage: ./deploy.sh --version VERSION --environment ENVIRONMENT [--dry-run]"
    exit 1
fi

log_info "Starting deployment: Version=$VERSION, Environment=$ENVIRONMENT"

# Deploy function
deploy() {
    local version="$1"
    local environment="$2"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would deploy $version to $environment"
        return 0
    fi
    
    log_info "Pulling image: myapp:$version"
    docker pull "docker.example.com/myapp:$version"
    
    log_info "Stopping old deployment..."
    docker-compose -f "docker-compose.$environment.yml" down || true
    
    log_info "Starting new deployment..."
    export IMAGE_VERSION="$version"
    docker-compose -f "docker-compose.$environment.yml" up -d
    
    # Wait for service to be healthy
    local max_attempts=30
    local attempt=0
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -f "http://localhost:8080/health" &>/dev/null; then
            log_info "✓ Service is healthy"
            return 0
        fi
        attempt=$((attempt + 1))
        log_info "Waiting for service to be healthy... ($attempt/$max_attempts)"
        sleep 2
    done
    
    log_error "Service failed to become healthy after $max_attempts attempts"
    return 1
}

# Main execution
if deploy "$VERSION" "$ENVIRONMENT"; then
    log_info "✓ Deployment completed successfully"
    exit 0
else
    log_error "✗ Deployment failed"
    exit 1
fi
```

---

# Monitoring & Observability

## Monitoring Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**Monitoring vs. Observability**:
```
Monitoring (Traditional):
  ├─ Collect known metrics (CPU, memory, disk)
  ├─ Alert when threshold exceeded
  ├─ Limited visibility (only what you defined)
  └─ Question: "Is it broken?" → Answer from predefined alerts

Observability (Modern):
  ├─ Collect metrics + logs + traces
  ├─ Enable ad-hoc queries (arbitrary questions)
  ├─ Comprehensive visibility (answer any question)
  └─ Question: "Why is latency high?" → Explore data to find root cause
```

**Four Pillars of Observability**:
```
1. Metrics (Time-series data)
   ├─ CPU, memory, disk usage
   ├─ Request count, latency, error rate
   ├─ Application-specific (conversion rate, cart size)
   └─ Collected every 15-60 seconds
   └─ Storage: Prometheus, CloudWatch

2. Logs (Textual records)
   ├─ Application logs ("User logged in")
   ├─ System logs (kernel messages)
   ├─ Infrastructure logs (API calls, resource changes)
   └─ Usually unstructured text (improved with JSON/structured logging)
   └─ Storage: Elasticsearch, Splunk, CloudWatch Logs

3. Traces (Request flow)
   ├─ Single request travels through multiple services
   ├─ Trace: Represents entire request journey
   ├─ Spans: Individual service/component work
   └─ Example: Web request → API service → Database → Response
   └─ Storage: Jaeger, Zipkin, X-Ray

4. Events (State changes)
   ├─ Deployment started/completed
   ├─ Pod crashed and restarted
   ├─ Certificate expiration alert
   └─ Link events to metrics/traces for root cause
```

#### Production Usage Patterns

**Prometheus Architecture** (Metrics collection):
```
┌─────────────────────────────────────────┐
│       Pull-based Architecture           │
├─────────────────────────────────────────┤
│                                          │
│  Prometheus Server (time-series DB)     │
│  ├─ Scrape configuration (targets)      │
│  ├─ Scrape /metrics endpoint every 15s  │
│  ├─ Store in TSDB (time-series DB)      │
│  └─ Retention: 15 days (configurable)   │
│                                          │
│  Targets (emit metrics):                │
│  ├─ Application (:8080/metrics)         │
│  ├─ Node Exporter (system metrics)      │
│  ├─ Docker containers                   │
│  └─ Kubernetes (kube-state-metrics)     │
│                                          │
│  AlertManager:                          │
│  ├─ Evaluates alert rules (every 15s)   │
│  ├─ If rule matches → send alert        │
│  └─ Integrates: Slack, PagerDuty, etc.  │
│                                          │
│  Grafana (visualization):               │
│  ├─ Queries Prometheus                  │
│  ├─ Renders graphs/dashboards           │
│  └─ No direct metrics storage            │
│                                          │
└─────────────────────────────────────────┘
```

**Metric Types**:
```
Counter (always increases or resets):
  http_requests_total: 1,000,000 requests
  bytes_uploaded_total: 5 GB
  errors_total: 1,234
  
Gauge (can go up or down):
  cpu_usage_percent: 45%
  memory_available_bytes: 8 GB
  pod_replicas: 3
  
Histogram (distribution of values):
  request_latency_seconds: [0.01, 0.05, 0.1, 0.5, 1.0, 5.0]
  Calculates percentiles (p50, p95, p99)
  Example: 95% of requests <0.1 seconds
  
Summary (quantiles of observations):
  Similar to histogram but exact quantiles
  More accurate but higher cardinality
```

---

## Observability Concepts

### Textual Deep Dive

**Structured Logging** (JSON instead of unstructured text):
```
❌ Unstructured:
  "2024-01-15 10:30:45 ERROR: User login failed for admin from 10.0.1.50"
  Problem: Hard to parse, query, or alert on specific fields

✅ Structured (JSON):
{
  "timestamp": "2024-01-15T10:30:45Z",
  "level": "ERROR",
  "service": "auth-service",
  "user_id": "admin",
  "event": "login_failed",
  "source_ip": "10.0.1.50",
  "reason": "invalid_password",
  "request_id": "abc-123-def"
}

Benefits:
  ├─ Query: "Find all failed logins from IP X"
  ├─ Alert: If errors_total > 10 in 5 minutes
  ├─ Trace: Link logs via request_id across services
  └─ Graph: Failed_logins_per_user dashboard
```

**Distributed Tracing** (Track requests across services):
```
User Request: GET /api/orders/123

Service: API Gateway
  ├─ Span: Route request (10ms)
  └─ Call: Order Service
  
Service: Order Service
  ├─ Span: Fetch order (5ms)
  ├─ Call: User Service (2ms latency)
  │  └─ Service: User Service
  │     └─ Span: Get user (3ms)
  ├─ Call: Payment Service (50ms latency)
  │  └─ Service: Payment Service (SLOW)
  │     ├─ Span: Check payment status (48ms)
  │     └─ Event: External API call (slow)
  └─ Span: Format response (2ms)

Response: 200 OK

Total latency: 80ms
Bottleneck identified: Payment Service (48ms)
Root cause: External payment API is slow; implement caching
```

---

## Monitoring Tools

### Textual Deep Dive

**Prometheus Configuration**:
```yaml
# prometheus.yml

global:
  scrape_interval: 15s      # Default collection interval
  evaluation_interval: 15s  # Rule evaluation frequency
  external_labels:
    monitor: 'prod'

# Alert Manager integration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Alert rules
rule_files:
  - '/etc/prometheus/alert.rules'

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Application metrics
  - job_name: 'myapp'
    static_configs:
      - targets: ['app-server-1:8080', 'app-server-2:8080']

  # Kubernetes cluster (service discovery)
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

**Alert Rules**:
```yaml
# alert.rules

groups:
  - name: application
    interval: 30s
    rules:
      # Alert if high CPU for 5 minutes
      - alert: HighCPUUtilization
        expr: avg(cpu_usage_percent) > 80
        for: 5m
        annotations:
          summary: "High CPU usage detected"
          description: "CPU > 80% for 5 minutes"
        labels:
          severity: warning

      # Alert if service is down
      - alert: ServiceDown
        expr: up{job="myapp"} == 0
        for: 1m
        annotations:
          summary: "Service {{ $labels.instance }} is down"
        labels:
          severity: critical
```

---

## Monitoring & Log Aggregation

### Textual Deep Dive

**ELK Stack** (Elasticsearch, Logstash, Kibana):
```
┌──────────────────────────────────────────┐
│ Log Sources                              │
├──────────────────────────────────────────┤
│ ├─ Application logs (stdout/file)        │
│ ├─ System logs (syslog, journald)        │
│ └─ Infrastructure logs (API, events)     │
│                                          │
│        ↓ (collect & parse)               │
│                                          │
│ Logstash (data processing)               │
│ ├─ Input plugins (read logs)             │
│ ├─ Filter plugins (parse, enrich)        │
│ └─ Output plugins (send to ES)           │
│                                          │
│        ↓ (index in real-time)            │
│                                          │
│ Elasticsearch (search & storage)         │
│ ├─ Distributed document database         │
│ ├─ Full-text search                      │
│ └─ Index per day (for retention)         │
│                                          │
│        ↓ (query & visualize)             │
│                                          │
│ Kibana (UI)                              │
│ ├─ Search logs                           │
│ ├─ Create dashboards                     │
│ └─ Set up alerts                         │
│                                          │
└──────────────────────────────────────────┘
```

**Log Retention Strategy**:
```
All logs → Elasticsearch (hot tier)
├─ Retention: 30 days
├─ Daily indices: logstash-logs-2024-01-15
├─ Size: 100GB/day
└─ Cost: High (SSD storage)

After 30 days → Archive
├─ Move to S3 (Glacier for compliance)
├─ Cost: 10x cheaper than hot storage
├─ Retention: 1 year (compliance requirement)
└─ Access: Slow (hours to retrieve)

Cost optimization:
├─ Index lifecycle policy (ILM)
├─ Hot → Warm → Cold → Delete
├─ Example: Hot (7 days), Warm (23 days), Archive (365 days)
└─ Estimated savings: 60% of logging costs
```

---

## Alerting Strategy

### Textual Deep Dive

**Alert Design** (Context + Action):
```
❌ BAD Alert:
  "CPU > 80%"
  ├─ No context (why should we care?)
  ├─ No action (what do we do?)
  └─ Results in alert fatigue

✅ GOOD Alert:
  "High CPU on web-prod-01 (usage 88%) for 10 minutes"
  ├─ Specific threshold + duration (not noise)
  ├─ Context: Which service? Which environment?
  ├─ Action: Check for hung process, auto-scale, or user notification
  └─ Owner: Assigned to on-call engineer via PagerDuty
```

**Alert Routing**:
```
AlertManager routes based on labels:

rule matches
    ↓
alert_name: HighCPUUtilization
severity: warning
service: api-server
environment: production
    ↓
Routing:
├─ environment=production → PagerDuty (wake up on-call)
├─ severity=warning → Slack #ops-warnings
├─ service=api-server → @team-api tag
└─ environment=staging → Slack #dev-alerts (no PagerDuty)
```

---

## Monitoring & Observability Troubleshooting

### Textual Deep Dive

**Common Issues**:
```
Issue 1: Alert Storm (hundreds of alerts fire simultaneously)
  Cause:
    ├─ Threshold too low
    ├─ Many similar issues trigger same alert
    └─ No deduplication

  Solution:
    ├─ Increase alert threshold (or duration)
    ├─ Add alert grouping (group similar alerts)
    ├─ Implement alert suppression (during maintenance)
    └─ Use severity levels (only critical wake on-call)

Issue 2: Missing Metrics (application not reporting)
  Cause:
    ├─ Application not instrumented
    ├─ Prometheus scrape failing
    ├─ Metrics endpoint down

  Solution:
    ├─ Check: curl http://app:8080/metrics
    ├─ Review Prometheus /targets page
    ├─ Check logs: "failed to scrape target"
    └─ Alert: Instrumentation is DevOps responsibility

Issue 3: Query Timeout (Prometheus query slow)
  Cause:
    ├─ Query too complex
    ├─ Large time range (querying 1 year of data)
    ├─ High cardinality metrics

  Solution:
    ├─ Use rate() instead of raw counts
    ├─ Limit time range
    ├─ Record rules (pre-aggregate expensive queries)
```

---

## Real-World Observability Stack

```yaml
# Comprehensive monitoring setup

Global Architecture:

Instrumentation Layer:
  ├─ Application: OpenTelemetry library (auto-instrumentation)
  ├─ System: Node Exporter (CPU, memory, disk)
  ├─ Container: cAdvisor (pod metrics)
  └─ Infrastructure: Prometheus scrape targets

Collection Layer:
  ├─ Prometheus: Metrics collection + storage
  ├─ Loki: Log aggregation (Grafana Labs)
  ├─ Jaeger: Distributed tracing
  └─ Fluentd: Log shipper to Loki

Analytics Layer:
  ├─ Grafana: Dashboards + alerts
  ├─ Alertmanager: Alert routing + deduplication
  ├─ AlertManager-Webhook: Integrations (Slack, PagerDuty)
  └─ Cortex: Long-term metric storage

Visualization:
  ├─ Grafana dashboards
  ├─ Alert history
  └─ SLO tracking
```

---

# Container Runtime

## Container Runtime Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**Container Runtime Layers**:
```
High-level Runtime (Docker, containerd):
  ├─ Manages image management
  ├─ Container lifecycle (create, run, stop)
  └─ Networking, storage abstractions

Low-level Runtime (OCI - Open Container Initiative):
  ├─ runc (Go implementation, most common)
  ├─ crun (C implementation, lighter weight)
  └─ gVisor (sandboxed, secure)
    
Kernel:
  ├─ Namespaces (PID, network, mount, user, UTS, IPC)
  ├─ cgroups (CPU, memory, I/O limits)
  └─ seccomp (syscall filtering)
```

**Container Namespace Isolation** (What container sees):
```
PID Namespace:
  Host sees: [kernel, systemd(1), docker(500), app(501), ...]
  Container sees: [app(1), child_process(2), ...] (own PID 1)

Network Namespace:
  Host: eth0 (192.168.1.100), eth1 (10.0.0.50)
  Container: eth0 (172.17.0.2) - veth pair (tied to host bridge)

Mount Namespace:
  Host: / (root), /var, /home, /opt, /sys, /proc
  Container: / (image root), /var (mounted), others hidden (unless mounted)

User Namespace (optional):
  Host: User 1000 (regular user)
  Container: User 0 (root) ← But maps to 1000 on host (security)

IPC Namespace:
  Host: System V message queues, semaphores, shared memory (global)
  Container: Own IPC namespace (unless --ipc=host)

UTS Namespace:
  Host: hostname = "prod-server-1"
  Container: hostname = "abc123def456" (container ID)
```

**Cgroups (Resource Limiting)**:
```
CPU Limiting:
  cgroup limit: 500m (0.5 CPU cores)
  ├─ Container can't exceed 50% of 1 core
  ├─ If it tries: CPU throttled (performance reduced, not OOM)
  └─ Set via: docker run -c 512 (512 cpu-shares)

Memory Limiting:
  cgroup limit: 512MB
  ├─ Container allocated 512MB
  ├─ If it tries to use >512MB: OOMKilled (process terminated)
  └─ Set via: docker run -m 512m

I/O Limiting:
  cgroup limit: 1MB/s read, 1MB/s write
  ├─ Block device I/O capped
  ├─ Disk operations throttled if exceeded
  └─ Prevents noisy neighbor (one container saturating disk)
```

#### Container Runtime Comparison

| Feature | Docker | containerd | CRI-O | Podman |
|---------|--------|-----------|-------|--------|
| **Architecture** | Client-daemon | Minimal daemon | Minimal daemon | Daemonless |
| **Container Format** | Docker images | OCI images | OCI images | OCI images |
| **Kubernetes Integration** | CRI shim | Native CRI | Native CRI | CRI plugin |
| **Image Build** | Bundled | External (buildkit) | External | Bundled |
| **Rootless Mode** | Experimental | Supported | Supported | Supported |
| **Best For** | Development, Docker Compose | Kubernetes (minimal) | OpenShift, Kubernetes | Secure, rootless |
| **Learning Curve** | Gentle | Steep | Steep | Medium |

---

## Container Runtime Configuration & Performance

### Textual Deep Dive

**containerd Configuration**:
```toml
# /etc/containerd/config.toml

version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"  # Storage driver
      
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        CriuPath = ""
        BinaryName = "runc"
        CriuWorkPath = ""
        SystemCgroup = false
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
          BinaryName = "runc"
          CriuPath = ""
          CriuWorkPath = ""
          SystemCgroup = false
    
    [plugins."io.containerd.grpc.v1.cri".registry]
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry-1.docker.io"]
        
        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."gcr.io"]
          endpoint = ["https://gcr.io"]

[metrics]
  address = "127.0.0.1:1338"  # Prometheus metrics
  grpc_histogram = false       # Histogram metrics (high cardinality)
```

**Container Runtime Performance Tuning**:
```
1. Storage Driver Optimization:
   overlayfs (default, fast): Use with fast SSD
   zfs: High memory overhead; avoid unless required
   
2. Snapshotter:
   native: Slower, simpler
   overlayfs: Fast, supports incremental snapshots
   
3. Limit Context Switches:
   Set CPU affinity for important containers
   Reserve CPU for system (kubelet, container runtime)
   
4. Memory Pressure:
   Monitor: cat /proc/pressure/memory
   Swap disabled: Prevents unpredictable performance
   
5. Network Optimization:
   Use host network (--network=host) for latency-critical apps
   Accept: No network namespace isolation
   
6. Cgroup v2 (newer):
   Better CPU throttling (less jittery)
   More memory accounting
   Enable: Set kernel parameter: cgroup_enable=+memory systemd.unified_cgroup_hierarchy=1
```

**Real-World Runtime Limits**:
```yaml
# Kubernetes Pod with realistic limits

apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
    - name: app
      image: myapp:v1.0.0
      
      resources:
        requests:
          cpu: "100m"           # Guaranteed 0.1 cores
          memory: "256Mi"       # Guaranteed 256MB
        limits:
          cpu: "500m"           # Max 0.5 cores (throttles above)
          memory: "512Mi"       # Max 512MB (OOMKills above)
      
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 15
        periodSeconds: 20
      
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
```

---

## Container Runtime Troubleshooting

### Textual Deep Dive

**Common Issues**:
```
Issue 1: OOMKilled Containers
  Symptom: Pod restarts every 5 minutes; logs show "Out of memory"
  Diagnosis:
    $ kubectl top pod web-server
    or
    $ docker stats web_container
    
  Solution:
    ├─ Increase memory limit
    ├─ Reduce memory consumption (code optimization)
    ├─ Add swap (not recommended; use for emergency)

Issue 2: Slow Pull Speed
  Symptom: Pod takes 2 minutes to start; image pull is slow
  Diagnosis:
    $ docker pull myregistry.com/myapp:v1  # Time it
    
  Solution:
    ├─ Use local registry mirror (pull from nearby)
    ├─ Compress layers (reduce image size)
    ├─ Use private registry (faster than Docker Hub)

Issue 3: Container Crashes During Startup
  Symptom: Container exits immediately
  Diagnosis:
    $ docker logs container_name
    $ docker inspect container_name (check exit code)
    
  Solution:
    ├─ Check entrypoint script (does it fail silently?)
    ├─ Verify working directory and file permissions
    ├─ Add delay before running main process (wait for dependencies)

Issue 4: Network Connectivity Issues
  Symptom: Container can't reach external service
  Diagnosis:
    $ docker exec container_name curl -v https://external.com
    
  Solution:
    ├─ Check DNS (can resolve domain names?)
    ├─ Check firewall rules (AWS security group open?)
    ├─ Check network mode (bridge vs. host)
```

---

# Data & Infrastructure Scaling

## Scaling Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**Scaling Dimensions**:
```
Vertical Scaling (Scale Up):
  ┌─────────────────┐
  │  t2.xlarge      │
  │  16 CPU cores   │
  │  64GB memory    │
  │  1000 Mbps NW   │
  └─────────────────┘
  └─ Cost: Higher per instance
  └─ Limits: AWS instance max is huge, but practical limit ~500GB memory
  └─ Downtime: Stop → Resize → Start (minutes)

Horizontal Scaling (Scale Out):
  ┌──────────┬──────────┬──────────┐
  │ t2.small │ t2.small │ t2.small │
  │ 2 cores  │ 2 cores  │ 2 cores  │
  │ 8GB RAM  │ 8GB RAM  │ 8GB RAM  │
  └──────────┴──────────┴──────────┘
  └─ Cost: Cheaper per instance, distributed cost
  └─ Limits: Thousands of instances available
  └─ Downtime: None (gradual addition of instances)

Database-Specific Scaling:
  Write Scaling:
    ├─ Vertical: Upgrade to larger RDS instance (limited by single table locks)
    ├─ Horizontal (Sharding): Distribute data across multiple databases
    │   └─ Shard key: User ID, Geography, etc.
    │   └─ Problem: Complex application logic (routing)
    └─ Managed: Aurora multi-master write (coming)
  
  Read Scaling:
    ├─ Read Replicas: Multiple read-only copies
    ├─ Cache (Redis): Reduce database reads
    └─ Managed: Aurora serverless (auto-scales read replicas)
```

#### Production Usage Patterns

**Load Balancing Algorithms**:
```
Round Robin:
  Request 1 → Server A
  Request 2 → Server B
  Request 3 → Server C
  Request 4 → Server A
  ├─ Simple but ignores server health
  └─ Modern LBs use health checks

Least Connections:
  Server A: 5 active connections
  Server B: 2 active connections
  Request → Server B (fewest connections)
  ├─ Better for long-lived connections
  └─ Better than round robin for uneven loads

Source IP Hash:
  Client IP 192.168.1.10 → Always routes to Server A
  ├─ Sticky sessions: Ensures affinity (no loss of session)
  ├─ Problem: Adding server B breaks hash; connections reroute
  └─ Solution: Consistent hashing (minimize rerouting on changes)

Weighted:
  Server A (powerful): weight 5
  Server B (weak): weight 1
  ├─ Send 5 requests to A for every 1 to B
  ├─ Accounts for different capabilities
```

---

## Auto Scaling

### Textual Deep Dive

**AWS Auto Scaling Group (ASG)**:
```
┌───────────────────────────────────────────────┐
│  Auto Scaling Group: web-servers              │
│  ├─ Launch Template: ami-123, t2.medium      │
│  ├─ Desired Capacity: 5 instances            │
│  ├─ Min: 3, Max: 10                          │
│  ├─ Availability Zones: 1a, 1b, 1c           │
│  └─ Health Check: ELB (60s grace period)     │
│                                              │
│  Current Instances:                          │
│  ├─ 1a: web-1 (Healthy), web-2 (Healthy)    │
│  ├─ 1b: web-3 (Healthy), web-4 (Healthy)    │
│  └─ 1c: web-5 (Unhealthy) → Terminate       │
│                                              │
│  Scaling Policy:                             │
│  ├─ Metric: Average CPU > 70% for 5 min     │
│  ├─ Action: Add 2 instances                 │
│  └─ Cooldown: 300s (wait 5 min after scale) │
│                                              │
└───────────────────────────────────────────────┘
```

**Kubernetes Horizontal Pod Autoscaler (HPA)**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-server-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-server
  
  minReplicas: 2
  maxReplicas: 10
  
  metrics:
    # Primary metric: CPU utilization
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    
    # Secondary metric: Custom metric
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: "1000"
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100  # Double replicas  
          periodSeconds: 60
    
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scale down
      policies:
        - type: Percent
          value: 50  # Reduce by 50%
          periodSeconds: 60
```

**Scaling Predictor (Predictive auto-scaling)**:
```
Traditional (reactive):
  Load increases → Metrics spike → Alert triggers → Scale up → Finally can handle
  Problem: Gap between load spike and scaling; brief service degradation

Predictive (proactive):
  AI/ML predicts load based on patterns
  ├─ Historical: Mondays 9 AM always busy; pre-scale at 8:50 AM
  ├─ Seasonal: Black Friday → scale 10x weeks in advance
  └─ Scheduled: Known events (campaigns, notifications)

Implementation:
  $ # AWS Predictive Scaling (built-in to ASG)
  $ aws autoscaling put-scaling-policy \
      --auto-scaling-group-name web-servers \
      --policy-name web-predictive \
      --policy-type TargetTrackingScaling \
      --target-tracking-configuration file://config.json
```

---

## Load Balancing Strategies

### Textual Deep Dive

**Layer 4 (Transport) vs. Layer 7 (Application)**:
```
Client Request

┌─────────────────────────────────────┐
│ Network Load Balancer (Layer 4)     │
├─────────────────────────────────────┤
│ ├─ Route based on: IP:port, protocol
│ ├─ Ultra-high throughput (millions/sec)
│ ├─ Ultra-low latency (~25 microseconds)
│ ├─ Best for: Gaming, IoT, DNS
│ └─ Example: 192.168.1.5:443 → Server A
│                                      
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Application Load Balancer (Layer 7)  │
├─────────────────────────────────────┤
│ ├─ Route based on: Hostname, path, headers
│ ├─ Good throughput (millions/sec)
│ ├─ Better latency (1-2ms)
│ ├─ Best for: Web services, microservices
│ └─ Example: api.example.com → Service A
│            webapp.example.com → Service B
│                                      
└─────────────────────────────────────┘
```

**Session Persistence** (Sticky Sessions):
```
Problem: User logs in on Server A; session stored locally
         Next request routes to Server B; user must login again

Solution 1: Sticky Sessions (Cookie-based)
  ├─ LB sets cookie: SessionID=abc123
  ├─ LB hash based on SessionID → Always route to same Server A
  ├─ Problem: Server A goes down → Session lost; user must re-login

Solution 2: Distributed Sessions (Shared Cache)
  ├─ Server A: Store session in Redis
  ├─ Server B: Can read same session from Redis
  ├─ Server A fails → Server B handles; session intact
  └─ Better: Stateless design (JWT tokens; no server-side session)
```

---

## Scaling Best Practices

### Textual Deep Dive

**Scaling Testing** (Chaos Engineering):
```bash
# Load test: Verify system can handle expected peak

$ ab -n 100000 -c 500 http://api.example.com/
# -n: 100k requests
# -c: 500 concurrent connections

Monitors during test:
├─ Error rate (should stay < 0.1%)
├─ Latency (p95 should stay < 500ms)
├─ Auto-scaling activation (new instances start)
├─ Load balancer health checks (no 503s)
└─ Database connection pooling (connections don't exhaust)

Chaos Injection:
├─ Kill random pod: Verify traffic reroutes
├─ Saturate CPU on one node: Verify node drains gracefully
├─ Simulate network latency: Verify circuit breakers activate
└─ Database failover: Verify read replica takes over
```

**Scaling Monitoring**:
```
Metrics to track:
├─ Scaling event frequency
├─ Time to scale (how long from metric spike to capacity?)
├─ Cost per scale event
├─ Scaling correctness (did it scale enough?)
│   └─ If HPA scaled but latency still high; increase max or improve efficiency

Red flags:
├─ Scaling up but performance doesn't improve → Vertical scaling needed
├─ Scaling down too aggressively → Load spike crashes system
├─ Oscillating scaling (up/down/up/down) → Adjust stabilization window
```

---

---

# Advanced Systems - MLOps

## MLOps Concepts

### Textual Deep Dive

#### Internal Working Mechanism

**MLOps (Machine Learning Operations)**: DevOps applied to ML systems; orchestrates the ML lifecycle from training to serving.

```
Traditional Software Deployment:
  Code → Build → Test → Deploy → Monitor

ML Deployment:
  Data → Experiment → Train → Evaluate → Deploy → Monitor → Retrain (continuous)
           ↓                           ↓
     200 models tested         Model versioning
     (hyperparameter sweep)     (model registry)
```

**ML Pipeline Architecture**:
```
Data Ingestion
    ↓ (raw data)
Data Preprocessing
    ├─ Cleaning, normalization, feature engineering
    ├─ Split: train (70%), validation (15%), test (15%)
    └─ Artifact: training-data-v2.parquet
    ↓
Model Training
    ├─ Algorithm selection (Random Forest, Neural Net, Gradient Boost)
    ├─ Hyperparameter tuning (grid search, Bayesian optimization)
    ├─ Track: metrics, parameters, code version
    └─ Artifact: model.pkl (serialized)
    ↓
Model Evaluation
    ├─ Metrics: Accuracy, Precision, Recall, F1, AUC, RMSE
    ├─ Compare to baseline
    ├─ Validation on holdout test set
    └─ Pass/fail gate (e.g., accuracy > 95%)
    ↓
Model Registry
    ├─ Store model artifact + metadata
    ├─ Version: model-v1.pkl, model-v2.pkl
    ├─ Track: training parameters, metrics, author, timestamp
    └─ Approval gate (can this model be promoted?)
    ↓
Model Deployment
    ├─ Containerize model (FastAPI/Flask wrapper)
    ├─ Push to registry (ECR, DockerHub)
    ├─ Deploy to inference cluster
    └─ Canary: 5% traffic → 10% → 50% → 100%
    ↓
Model Serving
    ├─ API endpoint: POST /predict with features
    ├─ Batch serving: Process 1M records overnight
    ├─ Edge deployment: Mobile app, embedded device
    └─ Latency requirement: <100ms per prediction
    ↓
Monitoring & Drift Detection
    ├─ Prediction latency (is serving slow?)
    ├─ Data drift (input features changed?)
    ├─ Model drift (prediction accuracy degraded?)
    ├─ If drift detected → Trigger retraining
    └─ Feedback loop: Production predictions → Retrain data
```

#### Production Usage Patterns

**Model Training at Scale**:
```
Single GPU (Development):
  ├─ Laptop GPU: Training time = 5 hours

Distributed Training (Production):
  ├─ 8x GPU instances (AWS p3.8xlarge)
  ├─ Framework: PyTorch Distributed Data Parallel
  ├─ Training time = 30 minutes (10x speedup)
  ├─ Cost: ~$12/hour × 0.5 hours = $6

Scale to Terabytes:
  ├─ TPU Pod (Google): 1000+ TPUs
  ├─ Framework: TensorFlow with multi-host distribution
  ├─ Training time: Hours instead of days
  ├─ Cost: Google-managed, no on-prem infrastructure
```

**Model Inference Scaling**:
```
Low Latency Requirement (<10ms):
  ├─ GPU inference server (NVIDIA Triton)
  ├─ Batch size = 1 (minimal overhead)
  ├─ Replicas: 10+ for high throughput
  └─ Cost: GPU expensive; suitable for high-revenue models

High Throughput Batch:
  ├─ CPU-based inference (no GPU)
  ├─ Batch size = 1000 (maximize batching)
  ├─ Spark/Ray cluster (distributed processing)
  ├─ Process 1 million records in 1 hour
  └─ Cost: CPU cheap; suitable for periodic batches

Serverless Inference:
  ├─ Lambda function (AWS)
  ├─ Load model from S3 each invocation
  ├─ Cold start: 5-10 seconds
  ├─ Cost: $0.0002 per 100ms execution + storage
  └─ Best for: Bursty, infrequent predictions
```

---

## MLOps Tools

### Textual Deep Dive

**MLOps Technology Stack**:
```
Data Layer:
  ├─ Data Warehouse: Snowflake, BigQuery, Redshift
  ├─ Feature Store: Feast, Tecton (cached, versioned features)
  ├─ Data Versioning: DVC (Git for data)
  └─ Data Catalog: Datahub, Collibra (metadata management)

Experiment Tracking:
  ├─ MLflow: Logs parameters, metrics, artifacts (open-source)
  ├─ Weights & Biases: Cloud-native experiment tracking
  ├─ Neptune: Data science experiment tracking
  └─ Artifact: Store models, datasets, predictions

Model Training:
  ├─ Frameworks: TensorFlow, PyTorch, Scikit-learn
  ├─ Training Infrastructure: Kubernetes, Ray, Spark
  ├─ Hyperparameter Tuning: Optuna, Hyperopt, Ray Tune
  └─ Distributed Training: Horovod, PyTorch Distributed

Model Management:
  ├─ Model Registry: MLflow Model Registry, Vertex AI Model Registry
  ├─ Model Versioning: Track code + data + parameters
  ├─ Model Governance: Approval workflows, audit trail
  └─ Model Reproducibility: DVC, CML (Continuous ML)

Model Deployment:
  ├─ Containerization: Docker (model + runtime)
  ├─ Orchestration: Kubernetes, Ray Serve, Seldon
  ├─ Serving Framework: KServe, Triton, BentoML
  └─ API Framework: FastAPI, Flask

Monitoring:
  ├─ Model Monitoring: Evidently, Whylabs, Arize
  ├─ Data Drift: Detect feature distribution changes
  ├─ Model Drift: Track prediction accuracy decline
  ├─ Prediction Monitoring: Latency, error rate, throughput
  └─ Feedback Loop: Collect predictions for retraining

Orchestration:
  ├─ Workflow: Airflow, Kubeflow, Prefect
  ├─ Scheduling: Daily/weekly model retraining
  ├─ DAG (Directed Acyclic Graph): Define dependencies
  └─ Auto-triggering: If data quality metric fails, skip training
```

---

## MLOps Pipeline Components

### Textual Deep Dive

**Feature Engineering Pipeline**:
```python
# With Feast (Feature Store)

import feast
from feast import FeatureStore

store = FeatureStore(repo_path=".")

# Define features (code + data versioning)
features = store.get_online_features(
    features=[
        "user_profile:age",
        "user_profile:country",
        "user_events:purchase_count_30d",
        "user_events:avg_order_value_30d"
    ],
    entity_rows=[{"user_id": "12345"}]
).to_df()

# Benefit: Features cached (reusable across models)
# Problem solved: Feature leakage (using future data)
#                 Feature inconsistency (train vs. serve)
```

**Model Training Pipeline (Airflow)**:
```python
from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'ml-team',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'train-model',
    default_args=default_args,
    schedule_interval='0 2 * * *',  # Daily at 2 AM
    start_date=datetime(2024, 1, 1)
)

def fetch_data():
    # Download training data from warehouse
    pass

def preprocess_data():
    # Clean, normalize, engineer features
    pass

def train_model():
    # Train model, log metrics to MLflow
    pass

def evaluate_model():
    # Validate on test set; failure stops deployment
    pass

def register_model():
    # Register in Model Registry if evaluation passes
    pass

def deploy_model():
    # Deploy to staging for canary test
    pass

# Define DAG dependencies
fetch_task = PythonOperator(task_id='fetch_data', python_callable=fetch_data, dag=dag)
preprocess_task = PythonOperator(task_id='preprocess_data', python_callable=preprocess_data, dag=dag)
train_task = PythonOperator(task_id='train_model', python_callable=train_model, dag=dag)
eval_task = PythonOperator(task_id='evaluate_model', python_callable=evaluate_model, dag=dag)
register_task = PythonOperator(task_id='register_model', python_callable=register_model, dag=dag)
deploy_task = PythonOperator(task_id='deploy_model', python_callable=deploy_model, dag=dag)

fetch_task >> preprocess_task >> train_task >> eval_task >> register_task >> deploy_task
```

---

## MLOps Best Practices

### Textual Deep Dive

**1. Data Versioning & Lineage**:
```
Problem: Model trained on dataset-v1
         Week later, dataset was updated (bugs fixed)
         Old model now makes incorrect predictions

Solution: DVC (Data Version Control)
  ├─ Git tracks code
  ├─ DVC tracks data
  ├─ Combination: Reproducible ML
  
$ dvc add training_data.csv
$ git add training_data.csv.dvc
$ git commit -m "Update training data"

Reproducing old model:
$ git checkout v1.0.0  # Old code version
$ dvc checkout v1.0.0  # Old data version
$ python train.py      # Reproduces exact model from past
```

**2. Model Evaluation Gate**:
```
Continuous Integration for ML:

Branch: feature/new-features
  ├─ DataScientist: Engineer new features
  ├─ Train new model on old data
  ├─ Evaluate: New model > baseline?
  │  ├─ Yes → PR approval
  │  └─ No → Request changes
  ├─ Metrics tracked:
  │  ├─ Accuracy: 95.2% → 96.1% (+0.9%) ✓
  │  ├─ Latency: 50ms → 48ms ✓
  │  └─ Memory: 512MB → 640MB ⚠ (acceptable)
  └─ Merge → Deploy to staging

Production Evaluation:
  ├─ Canary: 5% traffic → new model
  ├─ Monitor: Prediction accuracy (from labeling service)
  ├─ If accuracy < 94% → Automatic rollback
  └─ Monitor window: 24 hours before full rollout
```

**3. Model Monitoring & Retraining Triggers**:
```
Continuous Model Monitoring:

In Production:
  ├─ Track: Prediction latency (p95 < 100ms?)
  ├─ Track: Input features (data drift?)
  ├─ Track: Predictions (model drift? accuracy declining?)
  └─ Alert: If deviation > threshold

Data Drift Detection:
  ├─ Compare: Feature distribution(train) vs. (production)
  ├─ Example: Age distribution shifted from 25-45 → 18-60
  ├─ Probability mass shift (Kolmogorov-Smirnov test)
  └─ Alert: If drift significant (p-value < 0.01)

Model Drift Detection:
  ├─ Compare: Model accuracy(baseline) vs. (current)
  ├─ Use shadow model: Run new model alongside, compare predictions
  ├─ If divergence > threshold: Trigger retraining
  └─ Automatic retraining job: Collect recent predictions + labels

Feedback Loop:
  ├─ Predictions in production
  ├─ After decision (e.g., customer churn: did they churn?)
  ├─ Add (features, label) to training database
  ├─ Trigger retraining if enough feedback collected
  └─ New model deployed automatically (if evaluation passes)
```

---

## MLOps Troubleshooting

### Textual Deep Dive

**Common Issues**:
```
Issue 1: Model Drift (Accuracy declining in production)
  Symptoms:
    ├─ Baseline accuracy: 95%
    ├─ Current accuracy: 89% (Friday)
    ├─ Users complaining: Degraded results
    └─ Investigation: What changed?

  Root causes:
    ├─ Data distribution shift (new user segment)
    ├─ Feature pipeline bug (feature value wrong)
    ├─ Model not updated recently (uses old training data)
    └─ Feedback loop broken (labels not collected)

  Solution:
    ├─ Compare feature distributions (identify which feature drifted)
    ├─ Review recent training data (is new segment represented?)
    ├─ Retrain with recent data
    ├─ Add new data type to training set
    └─ Deploy retrained model; monitor accuracy

Issue 2: Model Serving Latency Spike
  Symptoms:
    ├─ Baseline: 50ms per prediction
    ├─ Current: 500ms per prediction
    ├─ Users timeout after 1 second
    └─ Impact: 5% of predictions fail

  Root causes:
    ├─ Model size increased (new model)
    ├─ Batch size misconfigured
    ├─ GPU out of memory; falling back to CPU
    ├─ Too many requests; overload
    └─ Feature lookup slow (feature store latency)

  Solution:
    ├─ Profile model: Which layer is slow?
    ├─ Quantize model (reduce size, trade accuracy)
    ├─ Increase batch size (if latency tolerance allows)
    ├─ Scale replicas (more instances)
    ├─ Add caching layer (cache frequent predictions)

Issue 3: Feature Scaling Bottleneck
  Symptoms:
    ├─ Training: 24 hours (acceptable)
    ├─ Feature engineering: 20 hours (majority!)
    ├─ Model training: 4 hours (fast)
    └─ Bottleneck: Feature engineering is slow

  Root causes:
    ├─ SQL query fetching user history (joins slow)
    ├─ No caching (recalculating features every run)
    ├─ Complex transformations (expensive calculations)
    └─ Inefficient distributed computing

  Solution:
    ├─ Move to Feature Store (cache features)
    ├─ Optimize SQL queries (add indexes, denormalize)
    ├─ Parallelize feature computation (Spark, Ray)
    ├─ Materialize intermediate features
    └─ Profile: Identify slowest operation
```

---

## Real-World MLOps Example

**Fraud Detection Model Pipeline**:
```
Data Collection (Real-time)
  ├─ Payment transactions
  ├─ User behavior (login patterns, device fingerprints)
  └─ External data (IP geolocation, device reputation)

Feature Engineering (Daily)
  ├─ User features:
  │  ├─ Total transactions (30d, 7d, 1d)
  │  ├─ Average transaction amount
  │  ├─ Time since last transaction
  │  └─ Count of failed transactions
  ├─ Transaction features:
  │  ├─ Amount (normalized)
  │  ├─ Merchant category
  │  ├─ Device type
  │  └─ Geographic distance from home
  └─ External features:
     ├─ IP reputation score
     ├─ Device reputation score
     └─ VPN detected

Model Training (Weekly)
  ├─ Algorithm: Gradient Boosted Trees (XGBoost)
  ├─ Hyperparameters:
  │  ├─ max_depth: 6
  │  ├─ learning_rate: 0.1
  │  └─ n_estimators: 200
  ├─ Evaluation:
  │  ├─ Precision: 99.2% (false positives acceptable?)
  │  ├─ Recall: 92.5% (catching % of actual fraud)
  │  ├─ F1: 95.7%
  │  └─ ROC-AUC: 0.987
  └─ Baseline comparison: Previous model ROC-AUC = 0.984 (improvement!)

Model Deployment
  ├─ Containerize:
  │  ├─ FastAPI service
  │  ├─ Load model from S3
  │  ├─ Endpoint: POST /predict
  │  └─ Docker image: 500MB
  ├─ Kubernetes deployment:
  │  ├─ Replicas: 5 (high-availability)
  │  ├─ CPU request: 500m, limit: 1000m
  │  ├─ Memory request: 1Gi, limit: 2Gi
  │  └─ Latency SLO: p95 < 500ms
  └─ Canary deployment:
     ├─ 1% of traffic → new model
     ├─ Monitor false positive rate
     ├─ If FP rate > 1.5%, rollback
     ├─ Gradual increase: 1% → 5% → 25% → 100%
     └─ Timeline: 7 days

Inference API
  ├─ Request: {user_id, transaction_amount, merchant, device, location}
  ├─ Response: {fraud_probability: 0.12, decision: "allow", confidence: 0.95}
  ├─ Latency: 45ms (p95)
  └─ Throughput: 10,000 predictions/sec

Monitoring & Feedback
  ├─ Predictions logged (for feedback loop)
  ├─ Labels (fraud/not fraud) collected after 30 days
  ├─ Data drift monitored:
  │  ├─ Feature distributions (daily)
  │  └─ Alert if Kolmogorov-Smirnov p-value < 0.01
  ├─ Model drift monitored:
  │  ├─ Shadow model (new model runs alongside)
  │  ├─ Compare predictions (should be similar)
  │  └─ Alert if divergence > 5%
  └─ Retraining triggered:
     ├─ Weekly automatic (if evaluation passes)
     ├─ On-demand (if drift detected)
     └─ Feedback loop data + recent production data
```

---

# Hands-on Scenarios

## Scenario 1: Emergency Scaling During Black Friday Traffic Spike

**Problem Statement**: E-commerce company experiences 10x traffic spike on Black Friday. Current infrastructure running at 60% capacity fails to handle the spike. For 4 hours, website is responding slowly; 15% of checkout transactions timeout. Need to implement emergency scaling and prevent similar incidents.

**Architecture Context**:
```
Current Setup:
├─ Web tier: 5 m5.large instances (ASG, min=5, max=10)
├─ API tier: 3 c5.xlarge instances (2 CPU-bound replicas)
├─ Database: RDS Multi-AZ (db.r5.2xlarge)
├─ Cache: ElastiCache Redis (3-node cluster)
└─ Load Balancer: ALB with 60-second connection timeout

Issue:
├─ ASG hit max capacity (10 instances) by hour 1
├─ New requests queued; ALB timeout (60s) triggered
├─ Database connection pool exhausted (100 connections, all used)
└─ Cache evicted old entries due to memory pressure
```

**Step-by-Step Resolution**:

1. **Immediate Actions** (First 30 min):
```bash
# Scale up ASG max capacity (temporary relief)
$ aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name web-asg \
  --max-size 20
# Triggers launch of 10 more instances; 5-10 min to be healthy

# Increase ALB timeout
$ aws elbv2 modify-target-group-attributes \
  --target-group-arn arn:aws:elasticloadbalancing:... \
  --attributes Key=deregistration_delay.timeout_seconds,Value=120
# More time for graceful shutdown; reduces dropped connections

# Scale RDS read replicas
$ aws rds create-db-instance-read-replica \
  --db-instance-identifier prod-db-replica-2 \
  --source-db-instance-identifier prod-db
# Read-only replica for analytics queries; reduces primary load

# Increase database connection pool
$ kubectl set env deployment/api-server \
  DB_MAX_CONNECTIONS=200 \
  DB_POOL_SIZE=50
# More connections available; requires rolling restart
```

2. **Scaling Analysis** (Hour 1):
```
Metrics to monitor:
├─ EC2 CPU utilization: 60% → 85% (indicates more capacity needed)
├─ ALB target health: 45 healthy instances + new ones coming online
├─ RDS CPU: 70% (struggling; is bottleneck)
├─ RDS disk IOPS: At provisioned limit (10,000)
└─ Cache hit rate: 92% → 85% (cache pressure)

Bottleneck identified: RDS is limiting factor
  ├─ Web + API tiers can scale horizontally (add instances)
  ├─ Database cannot easily scale (vertical scale requires downtime)
  └─ Solution: Read replicas (for reads), connection pooling (reuse connections)
```

3. **Mid-term Scaling** (1-2 hours):
```yaml
# Kubernetes HPA auto-scale (future-proof)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-server
  minReplicas: 5
  maxReplicas: 50  # Increased for peak load
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 65
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "5000"

# Apply predictive scaling for next year
$ aws autoscaling put-scaling-policy \
  --auto-scaling-group-name web-asg \
  --policy-name predictive-scaling \
  --policy-type TargetTrackingScaling \
  --use-predictive-scaling true
# ML-based forecast; pre-scales before peak
```

4. **Database Optimization** (2-3 hours):
```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 123 AND created_at > NOW() - INTERVAL '7 days';

-- Create missing indexes
CREATE INDEX idx_orders_user_date ON orders(user_id, created_at DESC);

-- Enable query caching (for frequently accessed products)
-- Rails cache_digests + Redis integration

-- Connection pooling (reduce overhead)
$ # pgBouncer: 500 app connections → 20 actual DB connections
$ docker run -d pgbouncer -c /etc/pgbouncer/pgbouncer.ini
```

5. **Post-Incident Review** (Next day):

```
Failure analysis (5 Whys):
├─ Why did traffic cause outage? → ASG max too low
├─ Why was max set to 10? → Historical was sufficient
├─ Why not predict peak? → No forecasting model
├─ Why was database connection pool small? → Legacy configuration
└─ Why no monitoring alerts? → Reactive stance instead of proactive

Action items:
├─ Implement predictive scaling (ML-based forecast)
├─ Increase ASG max to 50 (prevent capacity ceiling)
├─ Set database connection pool = 200 (handle burst)
├─ Add RDS cluster read replicas (handle read spikes)
├─ Implement chaos engineering tests (monthly load tests)
├─ Set up cost tracking (scaling cost vs. revenue impact)
└─ Document post-mortems (prevent repeat mistakes)
```

**Best Practices Applied**:
- ✅ Horizontal scaling (add instances, not vertical)
- ✅ Database optimization (indices, connection pooling)
- ✅ Predictive scaling (anticipate peaks)
- ✅ Cost tracking (scaling is expensive; measure ROI)
- ✅ Post-incident review (improve for next time)

---

## Scenario 2: Debugging Container Memory Leak in Production

**Problem Statement**: Kubernetes pod serving user API gradually increases memory usage; after 24 hours, pod is OOMKilled. This happens repeatedly, cycling pods every day. Need to identify and fix the memory leak causing production degradation.

**Architecture Context**:
```
Deployment:
├─ Service: user-api-service (3 replicas)
├─ Image: mycompany/user-api:v1.2.3
├─ Memory request: 512Mi, limit: 1Gi
├─ Runtime: Python 3.11 + FastAPI
└─ Pod lifecycle: ~24 hours before OOMKill

Logs indicate:
├─ Hour 0: Pod memory = 200Mi
├─ Hour 6: Pod memory = 500Mi
├─ Hour 12: Pod memory = 850Mi
├─ Hour 24: Memory = 1100Mi → OOMKilled
└─ Pattern: Linear growth (~30Mi/hour)
```

**Step-by-Step Debugging**:

1. **Collect Evidence** (Immediately):
```bash
# Check pod memory history
$ kubectl top pod user-api-pod-xyz
  NAME                  CPU(cores)   MEMORY(bytes)
  user-api-pod-xyz      250m         950Mi

# Check previous pod (OOMKilled)
$ kubectl describe pod user-api-pod-old
  ...
  Last State:
    Terminated:
      Reason: OOMKilled
      Exit Code: 137
  ...

# Check pod logs (no error messages)
$ kubectl logs user-api-pod-xyz | tail -100
  # Only routine logs; no exceptions

# Conclusion: Silent memory leak (no exceptions thrown)
```

2. **Memory Profiling** (Reproduce locally):
```python
# Run locally with memory profiler
import sys
from memory_profiler import profile

# Endpoint that's suspect (user profile lookup)
@profile
def get_user_profile(user_id: int):
    # Query database
    user = db.query(User).filter(User.id == user_id).first()
    
    # Fetch related objects
    orders = db.query(Order).filter(Order.user_id == user_id).all()
    
    # Build response (suspect: large objects kept in memory)
    return {
        "user": user,
        "orders": [o.serialize() for o in orders]
    }

# Run with memory profiler
$ python -m memory_profiler app.py

# Output: Shows line-by-line memory consumption
```

3. **Identify Root Cause** (Load test):
```python
# Simulate production traffic (1000 requests/min)
import asyncio
import httpx

async def load_test():
    async with httpx.AsyncClient() as client:
        for i in range(100000):
            response = await client.get(f"http://localhost:8000/users/{i}")
            if i % 1000 == 0:
                memory_usage = get_process_memory()
                print(f"Request {i}: Memory = {memory_usage}Mi")
            
            # Memory keeps growing; OOMs after 24 hours of traffic

# Findings:
# Issue 1: Database connection not closed
#   └─ Pool of connections grows; old connections not recycled
# Issue 2: Caching decorator without eviction
#   └─ @cache decorator stores results indefinitely
# Issue 3: Large response objects held in memory
#   └─ No garbage collection of old responses
```

4. **Fast Fix** (Deploy immediately):
```python
# user_api/routes.py

from functools import lru_cache
import gc

# Fix 1: Limit cache size (LRU)
@lru_cache(maxsize=1000)  # Keep only 1000 entries
def get_user_profile_cached(user_id: int):
    return db.query(User).filter(User.id == user_id).first()

# Fix 2: Force garbage collection
@app.middleware("http")
async def garbage_collect_middleware(request, call_next):
    response = await call_next(request)
    if request.url.path.startswith("/users"):
        gc.collect()  # Force cleanup every user request
    return response

# Fix 3: Close database connections properly
async def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()  # Ensure connection returned to pool

# Deploy:
$ docker build -t mycompany/user-api:v1.2.4 .
$ docker push mycompany/user-api:v1.2.4
$ kubectl set image deployment/user-api user-api=mycompany/user-api:v1.2.4
# Rolling restart: v1.2.3 → v1.2 (monitors: no OOMKill)
```

5. **Proper Fix** (Root cause):
```python
# Investigate: Why was connection pool leaking?
# Root cause: SQLAlchemy pool_pre_ping=False (default)

# Fixed configuration:
from sqlalchemy import create_engine

DATABASE_URL = "postgresql://user:pass@rds-endpoint/myapp"

engine = create_engine(
    DATABASE_URL,
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,  # Test connection before reuse; remove stale
    pool_recycle=3600,   # Recycle connections every hour
    pool_reset_on_return="rollback"  # Reset state on return
)

# Result: Connections properly recycled; no growth after 24 hours
```

6. **Monitoring** (Prevent recurrence):
```yaml
# Prometheus alert: Memory growth trend
- alert: PodMemoryIncreasing
  expr: |
    rate(container_memory_usage_bytes{pod="user-api-pod"}[1h]) > 0
    and
    increase(container_memory_usage_bytes{pod="user-api-pod"}[24h]) > 500000000
  for: 1h
  annotations:
    summary: "{{ $labels.pod }} memory growing {{ $value }}MB/hour"
    
# Automatically trigger diagnosis:
$ # If alert fires, collect memory profile
$ # Send comparison to on-call engineer
$ # Consider auto-restart if memory > 80% of limit
```

**Best Practices Applied**:
- ✅ Systematic debugging (eliminate possibilities)
- ✅ Memory profiling (data-driven analysis)
- ✅ Fast fix (temporary relief)
- ✅ Proper fix (address root cause)
- ✅ Monitoring (prevent recurrence)

---

## Scenario 3: Multi-Region Failover & Disaster Recovery

**Problem Statement**: Primary AWS region (us-east-1) experiences total outage (8 hours). Secondary region (eu-west-1) should failover automatically. Ensure <5 min RTO (Recovery Time Objective) and <15 min RPO (Recovery Point Objective).

**Architecture Context**:
```
Primary Region (us-east-1):
├─ Active-active or Active-passive?
├─ RDS Primary (prod database)
├─ S3 replicated to secondary region
├─ Route53 routing policy (failover)
└─ DNSis propagation: 60 seconds

Secondary Region (eu-west-1):
├─ Standby (reduced capacity)
├─ RDS Read Replica (async replication, ~1-5s lag)
├─ S3 destination (cross-region replication)
└─ Auto Scaling Group (can scale up)
```

**Failover Sequence** (Automated):

```
Hour 0: us-east-1 goes down (network partition)
  ├─ Route53 health check fails
  ├─ Lambda trigger: activate failover
  └─ Notification: #incident Slack channel

Hour 0-1: Automatic failover
  ├─ Step 1: Promote RDS read replica (eu-west-1) to primary
  │  └─ Time: 2-3 minutes (network I/O)
  ├─ Step 2: Update Route53 DNS
  │  ├─ Failover routing policy: Switch to eu-west-1 ALB
  │  ├─ TTL = 60 seconds (clients update within 1-2 minutes)
  │  └─ Monitor: DNS query latency increase (some clients cached old DNS)
  ├─ Step 3: Scale up eu-west-1 infrastructure
  │  ├─ ASG: desired=5 → desired=20
  │  ├─ Time: 3-5 minutes (instance launch + health check)
  │  └─ Monitor: ALB healthy target count increases
  └─ Step 4: Alert: On-call engineer notified

Hour 1-2: Degraded service (secondary region only)
  ├─ Throughput: 50% of normal (secondary region smaller)
  ├─ Latency: Increased (users in US now hitting EU)
  ├─ Data loss: None (up to 15s loss acceptable)
  └─ Monitoring: Watch CPU/memory; triggered more scaling if needed

Hour 2-8: Service running on secondary region
  ├─ Users buffering through EU servers
  ├─ Backups continue (daily snapshots)
  ├─ Logs replicated (to S3, cross-region)
  └─ Data consistency maintained

Hour 8: Primary region recovers
  ├─ AWS announces: us-east-1 EC2 service restored
  ├─ Health check passes
  ├─ Route53: Still routing to secondary (manual confirmation needed)
  ├─ Decision: Failback or stay on secondary?
  │  ├─ Option 1: Immediate failback (risky; might fail again)
  │  ├─ Option 2: Verify region healthy (stress test; 1 hour)
  │  └─ Option 3: Stay on secondary (if no reason to failback)
  └─ Manual action required: SRE decides

Hour 9: Failback to primary
  ├─ Step 1: Sync data from secondary to primary
  │  ├─ Snapshot secondary database
  │  ├─ Restore to primary (cross-region restore)
  │  └─ Time: 15-30 minutes (large database)
  ├─ Step 2: Update Route53 DNS
  │  └─ Route 100% back to primary
  ├─ Step 3: Scale down secondary
  │  └─ Reduce costs (secondary back to standby)
  └─ Monitoring: Primary handling traffic normally

RTO & RPO Analysis:
├─ RTO (Recovery Time Objective): 3-5 minutes ✓
│  └─ Started failover: minute 0
│  └─ DNS updated: minute 1
│  └─ New infrastructure healthy: minute 3-5
│  └─ Target: < 5 minutes (achieved)
├─ RPO (Recovery Point Objective): 15 minutes ✓
│  └─ RDS replication lag: 1-5 seconds
│  └─ Some requests lost if primary crashes mid-request
│  └─ Acceptable: ~15 seconds max data loss (< 15 min target)
└─ Cost of standby infrastructure: ~30% of primary
```

**Implementation** (Terraform):

```hcl
# Multi-region Terraform

# Primary database
resource "aws_db_instance" "primary" {
  identifier         = "myapp-db-primary"
  engine            = "postgres"
  instance_class    = "db.r5.2xlarge"
  allocated_storage = 100
  multi_az          = true
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  
  tags = {
    Region = "us-east-1"
    Role   = "primary"
  }
}

# Secondary read replica (cross-region)
resource "aws_db_instance" "secondary" {
  identifier         = "myapp-db-secondary"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class    = "db.r5.large"  # Smaller (standby)
  
  tags = {
    Region = "eu-west-1"
    Role   = "secondary"
  }
  
  # Enable automated promotion
  auto_minor_version_upgrade = false
}

# Route53 failover policy
resource "aws_route53_record" "failover" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "CNAME"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  set_identifier = "primary-us-east-1"
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id               = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.example.com"
  type    = "CNAME"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  set_identifier = "secondary-eu-west-1"
  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id               = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
}

# Health check (primary region)
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port              = 443
  type              = "HTTPS"
  failure_threshold = 3
  
  measure_latency = true
  enable_sni      = true
}
```

**Best Practices Applied**:
- ✅ Automated failover (no manual intervention needed)
- ✅ Cross-region replication (data consistency)
- ✅ Health checks (triggers failover automatically)
- ✅ RTO/RPO metrics (defined targets; measurable)
- ✅ Standby infrastructure (ready to scale)
- ✅ Post-incident checklist (verification before failback)

---

# Interview Questions for Senior DevOps Engineers

## Q1: Explain your approach to designing a system with 99.99% uptime SLA (four nines). What are the key components and trade-offs?

**Expected Answer from Senior**: 
A senior engineer would recognize this as ~52.5 minutes downtime per year per component.

Structure:
1. **Redundancy**: "Multi-AZ or multi-region deployment. Each AZ has ~99.9% availability; two AZs gives ~99.99%"
2. **Health checks**: "Automated failover with <1 minute detection + <2 minute failover"
3. **Database**: "RDS Multi-AZ with synchronous replication; promotes read replica in case of failure"
4. **Load balancing**: "Multiple load balancers across AZs; route 53 DNS failover between regions if needed"
5. **Monitoring**: "Continuous monitoring; no human waiting for alert. Automated remediations (scale, restart)"

**Real-world trade-off**:
- Cost: 2-3x higher (redundant infrastructure)
- Complexity: High (distributed systems are complex)
- Data consistency: Synchronous replication is slower than async
- Risk mitigation: 99.99% doesn't mean zero downtime; it's ~5 minutes/year acceptable

Example: "At Company X, we designed for 99.99% uptime. The database replication latency was <100ms (synchronous). During peak load, we saw occasional 1-2 second spikes due to commit overhead. Trade-off: Accept slight latency increase for guaranteed consistency."

---

## Q2: You deploy a new version of your application. Suddenly, error rate jumps from 0.1% to 5%. What's your diagnostic process, and how would you roll back?

**Expected Answer**:
1. **Immediate assessment**:
   - "Check: Which service is erroring? (trace /metrics endpoint)"
   - "Check: Is it 4xx (client) or 5xx (server) errors?"
   - "Check: Error logs (JSON structure for querying)"

2. **Rollback decision**:
   - "If error rate unexplained AND spike started at deployment time → Immediate rollback"
   - "Don't wait for root cause analysis if affecting customers"
   - "Rollback is 2 minutes; diagnosis is 30+ minutes"

3. **Execution**:
   - "Kubernetes: `kubectl rollout undo deployment/myapp` (reverts to previous version)"
   - "Or: Canary deployment catch this (5% traffic → new version; alert on error rate spike)"
   - "After rollback: Error rate drops to 0.1% → Confirms bad deployment"

4. **Post-incident**:
   - "Diagnosis: What code change caused errors?"
   - "Testing: Why didn't unit/integration tests catch it?"
   - "Process improvement: Implement e2e tests in staging before production"

**Red flags if candidate says**:
- "Wait 30 minutes to understand root cause" ❌ (customer impact!)
- "Manually restart individual containers" ❌ (no GitOps)
- "No canary deployment" ❌ (risky for production)

---

## Q3: A colleague says "Terraform state file shouldn't be version-controlled because it contains secrets." Do you agree? Explain.

**Expected Answer**: 
"Partially right, but incomplete thinking."

Correct points:
- State file CAN contain secrets (database passwords, API keys)
- Secrets should be encrypted (KMS, HashiCorp Vault)

Better approach:
- "Don't store state in Git; store in S3 with encryption"
- "Enable versioning on S3; enables rollback"
- "Lock file in DynamoDB prevents concurrent modifications"
- "Encrypt secrets in transit (HTTPS); at-rest (KMS)"
- "Never run `terraform apply` locally without locking"

Example setup:
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

Mistake to avoid:
"I'll just keep credentials out of Terraform" ❌
  → Better: "Use IAM roles; Terraform assumes role without hardcoding credentials"

---

## Q4: You notice Kubernetes pods are being OOMKilled during peak traffic. How would you investigate and fix?

**Expected Answer**:
1. **Understand the issue**:
   - "OOMKilled = container exceeded memory limit"
   - "During peak: Maybe memory is shared across requests?"
   - "Check: What's the memory request vs. limit?"

2. **Investigate**:
   ```bash
   # Check current pod memory
   $ kubectl top pod POD_NAME
   
   # Check limits
   $ kubectl get pod POD_NAME -o yaml | grep -A5 resources
   
   # Check memory leak (historical)
   $ kubectl describe node NODE_NAME | grep -A10 "Allocated resources"
   ```

3. **Solutions** (in priority order):
   - Short-term: Increase memory limit (quick fix; symptoms not root cause)
   - Medium-term: Optimize app code (cache sizing, connection pooling)
   - Long-term: Implement memory profiling in CI/CD

4. **Example fix**:
   - "If the app caches user sessions without eviction → Limit cache size"
   - "If database connections leak → Add connection pooling + validation"
   - "If memory grows per request → Check for allocations not freed"

---

## Q5: How would you implement a blue-green deployment strategy in Kubernetes?

**Expected Answer**:
"Blue-green means two identical environments; switch between them. Advantages: instant rollback, zero downtime."

Implementation:
```yaml
# Blue deployment (current version v1.2.0)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  selector:
    matchLabels:
      version: blue
  replicas: 3
  template:
    metadata:
      labels:
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:v1.2.0

---
# Green deployment (new version v1.2.1, not receiving traffic yet)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  selector:
    matchLabels:
      version: green
  replicas: 3
  template:
    metadata:
      labels:
        version: green
    spec:
      containers:
      - name: app
        image: myapp:v1.2.1

---
# Service routes traffic (to blue initially)
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    version: blue  # Routes to blue
  ports:
  - port: 80
    targetPort: 8080
```

**Switching traffic** (at deployment time):
```bash
# Verify green is healthy
$ kubectl logs -l version=green
$ curl http://green-svc/health

# Switch service selector
$ kubectl patch service myapp -p '{"spec":{"selector":{"version":"green"}}}'

# All traffic now routes to green

# Rollback if needed (instant)
$ kubectl patch service myapp -p '{"spec":{"selector":{"version":"blue"}}}'
```

Trade-offs:
- ✅ Zero downtime switching
- ✅ Simple rollback
- ❌ Double infrastructure cost during switch
- ❌ No gradual validation (all or nothing)

Better alternative for most: Canary deployment (gradual traffic shift with monitoring)

---

## Q6: Your RDS database is running out of disk space. It's in production, and you have <1 hour before it becomes read-only. What's your action plan?

**Expected Answer** (Prioritizes business continuity):

1. **Immediate** (5 minutes):
   ```bash
   # Scale up RDS storage (can be done online; no downtime)
   $ aws rds modify-db-instance \
     --db-instance-identifier prod-db \
     --allocated-storage 500 \
     --apply-immediately
   # Growth from 200GB → 500GB
   # Takes 10-15 minutes; database remains available
   ```

2. **Parallel actions**:
   - "Clean up old data" (backup old logs, delete old records)
   - "Analyze disk usage" (what's consuming space?)
   - "Kill long-running queries" (might be holding locks)

3. **Root cause analysis** (after crisis)
   - "Why did we run out? Logs? Old transactions?"
   - "Implement disk usage monitoring alerts" (alert at 70%, 80%)
   - "Set up archival process" (move old data to S3)"

4. **Prevention**:
   ```python
   # CloudWatch monitoring
   alarm = cloudwatch.create_alarm(
       AlarmName='RDSDiskUsage',
       MetricName='FreeStorageSpace',
       Threshold=53687091200,  # 50GB free
       ComparisonOperator='LessThanThreshold',
       AlarmActions=[sns_topic]  # Alert on-call
   )
   ```

❌ Bad answer: "Drop tables" or "Restore backup" (destructive; business-critical actions)
❌ Bad answer: "Wait for AWS support" (too slow; proactive action needed)

---

## Q7: Explain the difference between "Monitoring" and "Observability." When would you use each?

**Expected Answer**:

**Monitoring** (Known unknowns):
- You define what to measure in advance
- "CPU > 80% for 5 minutes → Alert"
- Tool: Prometheus + Grafana + PagerDuty

**Observability** (Unknown unknowns):
- System emits telemetry; you explore with ad-hoc queries
- "Why is latency high?" → Query traces to find bottleneck
- Tool: Jaeger, Datadog, Splunk

Example:
```
Scenario: User sees slow checkout

Monitoring approach:
  ├─ CPU metric: 50% (normal) ❌
  ├─ Memory metric: 60% (normal) ❌
  ├─ Disk metric: 40% (normal) ❌
  └─ Alert didn't fire (metrics look normal, but user complained)

Observability approach:
  ├─ Trace request: /checkout endpoint
  ├─ Spans show: Payment Service taking 5 seconds
  ├─ Drill down: Payment Service → External API call
  ├─ Issue: External payment processor is slow (their problem)
  └─ Solution: Implement caching or timeout
```

**When to use**:
- **Monitoring**: Known issues (CPU spike, disk full)
- **Observability**: Unexpected issues (mysterious latency, cascading failures)

Maturity path: Level 1 = Monitoring only → Level 3 = Monitoring + Observability

---

## Q8: Your container image is 1.5 GB. It takes 5 minutes to push and 2 minutes to pull. How would you optimize?

**Expected Answer** (Data-driven optimization):

1. **Analyze image layers**:
   ```bash
   $ docker history myapp:v1.0.0 | head -20
   # Shows layer sizes; identify bloat
   ```

2. **Multi-stage build** (usual culprit):
   ```dockerfile
   # ❌ Bad: 1.5GB (build artifacts included)
   FROM ubuntu:22.04
   RUN apt install build-essential python3-dev
   COPY . /app
   RUN pip install -r requirements.txt

   # ✅ Good: 200MB (only runtime)
   FROM ubuntu:22.04 as builder
   RUN apt install build-essential python3-dev
   COPY requirements.txt .
   RUN pip install -r requirements.txt -t /pkg

   FROM python:3.11-slim
   COPY --from=builder /pkg /pkg
   ENV PYTHONPATH=/pkg
   ```

3. **Other optimizations**:
   - Compress layers: `RUN apt clean && rm -rf /var/lib/apt/lists/*`
   - Alpine base: `FROM alpine:3.18` (5MB instead of 100MB)
   - Remove unnecessary files: Delete documentation, examples

4. **Registry side**:
   - "Enable image compression (gzip)"
   - "Use private registry closer to deployment (lower latency)"

Result: 1.5GB → 200MB (7.5x reduction); push 30s, pull 10s

---

## Q9: You're designing disaster recovery. Business needs <5 min RTO and <15 min RPO. What architecture would you propose, and what's the cost?

**Expected Answer** (Balanced trade-off):

For <5 min RTO / <15 min RPO:

**Recommended**: **Pilot Light + Read Replica**
```
Primary region (us-east-1): ACTIVE
├─ RDS primary (prod database)
├─ Application servers (handling traffic)
└─ S3 with cross-region replication

Secondary region (eu-west-1): STANDBY
├─ RDS read replica (1-5s lag)
├─ Minimal infrastructure (1-2 small instances)
├─ Lambda function (monitors primary health)
└─ Ready to scale up in <5 minutes
```

Failover flow:
```
Primary fails → Health check fails (1 min)
  ↓
Lambda triggers failover (automated, <2 min)
  ├─ Promote RDS read replica to primary
  ├─ Scale up ASG (from 2 → 20 instances)
  ├─ Update Route53 DNS
  └─ Total time: ~3 minutes → RTO = 3 min ✓

RPO: ~15 seconds (RDS async replication lag) ✓
```

**Cost estimate**:
- Primary: $5000/month (full infrastructure)
- Secondary standby: $750/month (minimal)
- DR cost: 15% premium (~$750/month for business continuity)

-----

Trade-offs:
- ✅ Low RTO (automated failover)
- ✅ Low cost (secondary is minimal)
- ⚠ Slight data loss possible (~15s)
- ❌ Secondary can't handle full primary load immediately (scale-up delay)

For **zero data loss** (expensive): **Active-Active multi-region** = 2x cost

---

## Q10: A distributed system is experiencing frequent timeout errors. How do you debug and fix?

**Expected Answer** (Systematic approach):

1. **Understand "timeout"**:
   - Connection timeout (can't reach server)
   - Read timeout (server is slow)
   - Deadline timeout (service call takes too long)

2. **Trace the slow request**:
   ```bash
   # Distributed tracing
   $ jaeger query --service=api-server
   # Find slow traces; drill into spans
   # Identify which service is slow
   ```

3. **Common causes**:
   - **Database**: Slow query (add index)
   - **Network**: High latency (check connections)
   - **Resource**: High CPU/memory (scale up)
   - **Thundering herd**: Cascading retries (circuit breaker)

4. **Fix** (specific to root cause):
   ```python
   # Before: No timeout, no retry limit
   response = requests.get(url)
   
   # After: Timeout + retry + backoff
   from tenacity import retry, stop_after_attempt, wait_exponential
   
   @retry(
       stop=stop_after_attempt(3),
       wait=wait_exponential(multiplier=1, min=2, max=10)
   )
   def call_service(url):
       return requests.get(url, timeout=5)
   
   # Also: Circuit breaker (stop calling if service down)
   from pybreaker import CircuitBreaker
   
   breaker = CircuitBreaker(fail_max=5, reset_timeout=60)
   
   @breaker
   def call_service(url):
       return requests.get(url, timeout=5)
   ```

5. **Monitoring**:
   ```
   Alerts:
   ├─ Timeout rate > 1% for 5 min → Page on-call
   ├─ P95 latency > 1 second (baseline 100ms) → Page on-call
   └─ Failing circuit breaker → Page on-call (service issue)
   ```

---

## Q11: Explain how you'd secure credentials (database passwords, API keys) in your infrastructure.

**Expected Answer** (Defense in depth):

1. **Never in code/git**:
   ```
   ❌ BAD: password = "mysql://user:secret@db:3306"
   ❌ BAD: export API_KEY=xyz123
   ```

2. **Secrets management** (tiered):
   ```
   Local development:
     → .env file (in .gitignore)
     → docker-compose secrets (for testing)
   
   Staging/Prod:
     → AWS Secrets Manager (encrypted, rotated)
     → OR HashiCorp Vault (advanced)
     → OR Kubernetes Secrets (encrypted in etcd)
   ```

3. **Implementation**:
   ```python
   # Application code
   import boto3
   
   secrets_client = boto3.client('secretsmanager', region_name='us-east-1')
   
   # Fetch at startup
   secret = secrets_client.get_secret_value(SecretId='prod/db/password')
   db_password = secret['SecretString']
   
   # Or: Use IAM role (no credential management needed)
   db_creds = boto3.client('rds').describe_db_instances()
   # RDS auth tokens (temporary, refreshed automatically)
   ```

4. **Rotation**:
   ```
   ✅ Automated: AWS Secrets Manager rotates every 30 days
   ✅ Application handles rotation (no restart needed)
   ✅ Both old + new credentials accepted during rotation
   ```

5. **Audit**:
   ```
   CloudTrail logs:
   ├─ Who accessed secret?
   ├─ When?
   ├─ From which IP?
   └─ Review quarterly
   ```

**Red flags if candidate says**:
- "Store in environment variables" ❌ (exposed in process list, logs)
- "Store in Dockerfile" ❌ (exposed in image layers)
- "Manual password rotation" ❌ (error-prone, slow)

---

## Q12: You manage Kubernetes for a company with multiple teams. How do you prevent one team's misconfiguration from impacting others?

**Expected Answer** (Namespaces + RBAC + Network Policies):

1. **Namespace isolation**:
   ```yaml
   # Team A namespace
   apiVersion: v1
   kind: Namespace
   metadata:
     name: team-a
   
   # Team B namespace
   apiVersion: v1
   kind: Namespace
   metadata:
     name: team-b
   ```

2. **RBAC** (role-based access control):
   ```yaml
   # Team A can only modify their namespace
   apiVersion: rbac.authorization.k8s.io/v1
   kind: RoleBinding
   metadata:
     name: team-a-admin
     namespace: team-a
   roleRef:
     apiGroup: rbac.authorization.k8s.io
     kind: ClusterRole
     name: admin
   subjects:
   - kind: Group
     name: team-a@company.com
   
   # Team A cannot access Team B namespace
   ```

3. **Resource Quotas** (prevent resource hogging):
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: team-a-quota
     namespace: team-a
   spec:
     hard:
       cpu: "10"              # Max 10 CPU cores total
       memory: "50Gi"         # Max 50GB RAM total
       pods: "100"            # Max 100 pods
       services.loadbalancers: "2"  # Max 2 load balancers
   ```

4. **Network Policies** (prevent cross-team traffic):
   ```yaml
   # Deny all traffic in team-a namespace
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-all
     namespace: team-a
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
   
   # Allow external API call (but not inter-team)
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: allow-api-calls
     namespace: team-a
   spec:
     podSelector: {}
     policyTypes:
     - Egress
     egress:
     - to:
       - namespaceSelector:
           matchLabels:
             name: external-apis
       ports:
       - protocol: TCP
         port: 443
   ```

5. **Pod Security Policies** (enforce security standards):
   ```yaml
   apiVersion: policy/v1
   kind: PodSecurityPolicy
   metadata:
     name: restricted
   spec:
     runAsNonRoot: true
     runAsUser:
       rule: 'MustRunAsNonRoot'
     fsGroup:
       rule: 'MustRunAs'
       ranges:
         - min: 1
           max: 65535
     readOnlyRootFilesystem: true
   ```

---

## Q13: What metrics would you use to evaluate the health of your CI/CD pipeline?

**Expected Answer**:

Key metrics:

1. **Lead Time for Changes** (Code commit → Production):
   ```
   Ideal: < 1 day
   Industry: 1-3 days
   
   Metric: time(committed) - time(deployed)
   Use case: How fast can we deploy? Agility indicator
   ```

2. **Deployment Frequency**:
   ```
   Ideal: > 1 per day
   Industry: 1-2 per week
   
   Use case: How often do we release? Risk distribution
   (More frequent releases = smaller changes = lower risk)
   ```

3. **Change Failure Rate**:
   ```
   Ideal: < 15%
   Industry: 15-45%
   
   Metric: (failed deployments) / (total deployments)
   Use case: Quality of releases
   (Low = good testing; high = need better testing)
   ```

4. **Mean Time to Recovery (MTTR)**:
   ```
   Ideal: < 1 hour
   Industry: 1-12 hours
   
   Metric: time(failure detected) - time(resolved)
   Use case: Resilience (not "don't fail"; "recover fast")
   ```

5. **Pipeline Duration**:
   ```
   Ideal: < 10 minutes
   Industry: 10-60 minutes
   
   Use case: Developer feedback loop speed
   (Faster = more iterations; quicker fixes)
   ```

**How to improve**:
- Slow builds? Parallelize tests; cache dependencies
- High change failure? Add integration tests; canary deployments
- High MTTR? Better alerting; automated rollback

---

## Q14: Kubernetes pod memory limits keep getting exceeded. You've increased the limit multiple times. When is the right time to say "this needs architectural change"?

**Expected Answer** (Recognizes limits of scaling):

Scaling timeline:
```
Week 1: Memory limit 512Mi → Pod OOMKilled
  → Increase to 1Gi

Week 2: Memory limit 1Gi → Pod OOMKilled
  → Increase to 2Gi

Week 4: Memory limit 2Gi → Pod OOMKilled
  → Increase to 4Gi

Week 8: Memory limit 4Gi → Pod OOMKilled
  → STOP. Architectural issue.
```

**Red flag**: Exponential growth indicates root cause, not capacity issue.

**Actions**:
1. Profile the application:
   ```python
   from memory_profiler import profile
   
   @profile
   def expensive_operation():
       # Which lines allocate memory?
       # Can we optimize?
   ```

2. Identify pattern:
   - ✅ Memory grows over time (cache leaking) → Implement cache eviction
   - ✅ Memory per request (large objects) → Stream instead of buffering
   - ✅ Third-party library (can't optimize) → Use lighter alternative
   - ✅ Inherent to workload → Split into multiple services

3. Example fix:
   ```python
   # Before: Load entire dataset into memory
   data = load_entire_dataset()  # 5GB file
   process(data)
   
   # After: Stream chunks
   for chunk in stream_dataset(chunk_size=10MB):
       process(chunk)
   ```

4. When to split/refactor:
   - If optimization gains small (~10-20% improvement)
   - If different concerns (reporting vs. serving)
   → Split into separate services with independent scaling

---

## Q15 (Bonus): Tell me about a time you made a mistake in production. How did you handle it?

**Expected Answer** (Honesty + learning):

Structure:
1. **What happened**:
   - "I deployed database migration without testing in staging"
   - "Migration locked table for 30 minutes"
   - "Website was read-only during peak traffic"

2. **Impact**:
   - "50% of requests failed"
   - "~$100k revenue lost"
   - "Customers complained on Twitter"

3. **What did you do** (immediate):
   - "Detected error within 2 minutes (anomaly alert)"
   - "Immediately rolled back to previous version"
   - "Rollback took 1 minute; service recovered"

4. **What did you learn**:
   - "Tests should include schema changes"
   - "Long-running migrations need `CONCURRENTLY` flag (no locks)"
   - "Always test on staging environment"

5. **What changed** (systemic):
   - "Added database migration testing to CI/CD"
   - "Implemented pre-deployment validation (dry-run migration)"
   - "Updated runbook documentation"

**What impresses seniors**:
- ✅ Admits mistakes (no defensiveness)
- ✅ Owns the error (not "someone else")
- ✅ Fast response (didn't waste time)
- ✅ Root cause analysis (why, not just what)
- ✅ Systemic improvement (prevents recurrence)

**Red flags**:
- ❌ "It was someone else's fault" (no ownership)
- ❌ "I haven't made mistakes" (dishonest or inexperienced)
- ❌ "Manual process; happens all the time" (no improvement mindset)

---

**End of Study Guide**

This comprehensive senior DevOps study guide covers:

✅ **11 major topics** with deep technical content  
✅ **Real-world production patterns** across all domains  
✅ **Best practices** proven in enterprise environments  
✅ **Common pitfalls** and solutions  
✅ **Practical code examples** (Terraform, Python, Bash, YAML, SQL)  
✅ **Hands-on scenarios** (real-world problems with solutions)  
✅ **Interview questions** (15 questions covering architecture, operations, culture)  

**Target audience**: DevOps Engineers with 5–10+ years of experience  
**Length**: 6000+ lines of comprehensive content  
**Last updated**: April 2026  

---

**Document Statistics**:
- Total sections: 15 (Intro + 11 topics + Scenarios + Questions)
- Topics covered: 11 major DevOps domains
- Real-world examples: 8+ production case studies
- Code examples: 40+ practical snippets
- Interview questions: 15 senior-level scenarios
- Diagrams: 30+ ASCII architecture diagrams
- Best practices: 100+ actionable recommendations

This guide is suitable for:
- Interview preparation (both candidates and interviewers)
- Team onboarding (new senior hires)
- Knowledge documentation (organizational learning)
- Career development (skill assessment and gaps)

---
