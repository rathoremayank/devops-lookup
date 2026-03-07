# AWS Storage Services - Senior DevOps Study Guide

## Table of Contents

- [Introduction](#introduction)
  - [Overview of Topic](#overview-of-topic)
  - [Why It Matters in Modern DevOps Platforms](#why-it-matters-in-modern-devops-platforms)
  - [Real-World Production Use Cases](#real-world-production-use-cases)
  - [Where It Appears in Cloud Architecture](#where-it-appears-in-cloud-architecture)

- [Foundational Concepts](#foundational-concepts)
  - [Key Terminology](#key-terminology)
  - [Architecture Fundamentals](#architecture-fundamentals)
  - [Important DevOps Principles](#important-devops-principles)
  - [Best Practices](#best-practices)
  - [Common Misunderstandings](#common-misunderstandings)

- [S3, S3 Storage Classes and Pricing vs Performance](#s3-s3-storage-classes-and-pricing-vs-performance)
- [S3 Versioning, Lifecycle, Replication & Cross-Region Replication, Object Lock, MFA Delete, S3 Object Lambda, S3 Object Tagging, S3 Object ACLs & Bucket Policies](#s3-versioning-lifecycle-replication--cross-region-replication-object-lock-mfa-delete-s3-object-lambda-s3-object-tagging-s3-object-acls--bucket-policies)
- [S3 IAM & Access Control](#s3-iam--access-control)
- [S3 Event Notifications](#s3-event-notifications)
- [EBS & EFS](#ebs--efs)
- [Hands-on Scenarios](#5-hands-on-scenarios)
- [Interview Questions](#6-most-asked-interview-questions)

---

## Introduction

### Overview of Topic

AWS Storage Services represent the foundational layer of cloud infrastructure, providing diverse mechanisms for persisting, managing, and retrieving data across distributed systems. From object storage via Simple Storage Service (S3) to block storage through Elastic Block Store (EBS), file systems with Elastic File System (EFS), and specialized storage solutions like FSx and Storage Gateway, AWS offers a comprehensive portfolio designed to address virtually every storage requirement in modern cloud-native architectures.

Storage services in AWS are not monolithic—they reflect decades of distributed systems engineering maturity, supporting trillions of objects, petabyte-scale operations, and sub-millisecond access patterns. For DevOps engineers, understanding these services is non-negotiable. Storage decisions directly impact:

- **Infrastructure costs** (often 30-50% of cloud budgets)
- **Application performance** (latency, throughput, IOPS)
- **Compliance and regulatory requirements** (data residency, retention)
- **Disaster recovery and business continuity** strategies
- **Security posture** across the entire organization

### Why It Matters in Modern DevOps Platforms

In contemporary DevOps practices, storage decisions are not reactive afterthoughts—they are strategic architectural choices that influence deployment patterns, scaling behaviors, and operational complexity.

**Cost Optimization**: Storage is often the largest variable cost in cloud infrastructure. S3 alone represents billions of dollars in AWS revenue. Understanding storage classes, intelligent tiering, and lifecycle policies can reduce storage costs by 60-80% without sacrificing functionality.

**State Management in Containerized Environments**: As organizations migrate to Kubernetes and container orchestration, storage becomes increasingly complex. EBS for stateful components, EFS for shared file systems, and S3 for distributed data processing create a multi-layered storage strategy.

**Data Pipeline Architecture**: Modern data engineering pipelines (ETL/ELT) rely on S3 as the data lake foundation, with lifecycle policies automatically transitioning data, versioning protecting against accidental deletions, and event notifications triggering downstream processing.

**Compliance and Auditing**: Regulatory frameworks (HIPAA, GDPR, SOX) mandate specific storage controls. Object Lock ensures immutability, MFA Delete provides additional protection, and fine-grained IAM policies enable zero-trust access models.

**High-Availability and Disaster Recovery**: Cross-region replication (CRR), multi-region failover strategies, and backup architectures fundamentally depend on storage service capabilities. A misconfigured S3 bucket can become a single point of failure or, conversely, the most resilient component of your infrastructure.

### Real-World Production Use Cases

**1. Data Lake and Analytics Platform**
A financial services company ingests 10TB of transaction data daily into S3. Raw data lands in a `bronze` tier with STANDARD storage class and 90-day lifecycle to INTELLIGENT_TIERING. Partitioned data flows to `silver` and `gold` tiers where analysts query via Athena. Event notifications trigger Lambda functions for data validation, triggering SNS alerts on schema violations.

**2. Multi-Region Active-Active Architecture**
A SaaS platform replicates user content across us-east-1 and eu-west-1 with two-way S3 CRR. DynamoDB streams trigger Lambda functions to maintain eventual consistency. Object versions are retained for 30 days; delete operations use MFA Delete to prevent accidental data loss from compromised IAM credentials.

**3. Legacy Application Modernization**
A monolithic enterprise application persists documents on NFS. Storage Gateway (File Gateway) bridges this to S3, providing NFS compatibility while maintaining a local cache. Documents indexed via S3 Object Tagging enable application searches without refactoring. This preserves application code while gaining cloud reliability.

**4. Machine Learning Model Registry**
ML pipelines store model artifacts, training datasets, and inference logs in S3. Intelligent Tiering automatically manages access patterns; models accessed weekly remain in STANDARD, while archived training datasets transition to GLACIER_IR after 30 days. Model versioning leverages S3 Object Versioning; rollback is a single API call.

**5. Disaster Recovery as a Service (DRaaS)**
An organization maintains EBS snapshots across regions and replicates to S3 for archival. RTO/RPO requirements drive decisions: EBS in one region for sub-minute recovery, snapshots in another region for compliance, and DEEP_ARCHIVE in a third region for long-term retention. This multi-region strategy meets SLA requirements while managing costs.

### Where It Appears in Cloud Architecture

Storage services permeate every layer of modern cloud architectures:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer                             │
│          (APIs, Microservices, Web Applications)                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Data & State Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   DynamoDB   │  │    ElastiCache│  │   RDS        │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐                             │
│  │   EBS        │  │   EFS        │   (Block & File Storage)    │
│  └──────────────┘  └──────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              Object Storage & Data Lake                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │               S3 (Object Storage)                        │   │
│  │  ├─ Data Lake (Bronze/Silver/Gold Tiers)                │   │
│  │  ├─ Model Registry (ML Artifacts)                       │   │
│  │  ├─ Application Backups                                 │   │
│  │  └─ Log Aggregation & Analysis                          │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Glacier    │  │ Storage GW   │  │     FSx      │           │
│  │  (Archival)  │  │  (Hybrid)    │  │ (Enterprise) │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

Storage decisions cascade throughout architecture:

- **Compute decisions** depend on storage choices (instance store, EBS, or EFS)
- **Network design** is optimized for storage access patterns (VPC endpoints for S3, ENIs for high-throughput EFS)
- **Backup and disaster recovery** strategies are built on storage capabilities
- **CI/CD pipelines** depend on artifact storage (CodeBuild caches on EBS, artifacts in S3)
- **Compliance frameworks** are enforced through storage configuration (encryption, versioning, access logging)

---

## Foundational Concepts

### Key Terminology

**Object**: The fundamental unit in S3, consisting of data (blob) plus metadata. Objects are immutable—modifications create new versions or new objects.

**Bucket**: An S3 container holding objects. Bucket names are globally unique, region-specific, and follow DNS naming conventions. A single AWS account can own 100 buckets (increasable via request).

**Version ID**: A unique identifier assigned to each object in a versioned bucket. Enables point-in-time recovery and coexistence of multiple object states.

**Storage Class**: A classification determining object availability, durability, cost, and retrieval characteristics (STANDARD, INTELLIGENT_TIERING, ONEZONE_IA, GLACIER, DEEP_ARCHIVE, etc.).

**Lifecycle Policy**: Automated rules transitioning objects between storage classes or expiring objects based on age, tags, or prefix.

**Access Pattern**: The frequency and latency requirements for data access. Drives storage class selection: frequently accessed → STANDARD; infrequently accessed → GLACIER; unknown → INTELLIGENT_TIERING.

**Durability vs Availability**:
- **Durability** (11 9's = 99.999999999%): Probability that AWS will NOT lose your object. Protects against hardware failure.
- **Availability** (99.99%-99.9%): Probability that the object is accessible. Protects against temporary unavailability.

**Replication**: Asynchronous copying of objects to another bucket (same-region or cross-region). Enables disaster recovery and data residency compliance.

**Eventual Consistency**: S3's consistency model. After PUT or DELETE, subsequent reads might return stale data for a brief period. Critical for multi-region architectures.

**Block Storage (EBS)**: Volume-based storage attached to EC2 instances. Provides raw block access (like traditional hard drives) requiring filesystem management. Enables point-in-time snapshots.

**File System (EFS)**: Network-attached shared file system supporting concurrent access from multiple compute instances. NFS-compatible, fully managed, elastic.

**Immutable Object Lock**: Prevents object deletion or overwrite for a fixed retention period. WORM (Write-Once-Read-Many) compliance.

**Tagging**: Key-value metadata attached to objects enabling cost allocation, lifecycle policy filtering, and access control.

**ACL (Access Control List)**: Legacy access control mechanism at bucket or object level. Predefined grants (READ, WRITE, READ_ACP, WRITE_ACP, FULL_CONTROL) to AWS accounts or predefined groups. Largely superseded by IAM and bucket policies.

### Architecture Fundamentals

#### The Shared Responsibility Model in Storage

AWS secures the infrastructure; you secure configuration, access, and compliance:

| **AWS Responsibility** | **Your Responsibility** |
| --- | --- |
| Hardware durability | Encryption keys (CMK management) |
| Data replication | Access control (IAM, bucket policies) |
| Physical security | Versioning & retention policies |
| Regional redundancy | Application-level encryption |
| Service availability | Data categorization & classification |
| | Compliance enforcement |

#### Storage Hierarchy and Access Latency

```
Access Latency (approximate)  |  Durability  |  Cost         |  Primary Use
────────────────────────────────────────────────────────────────────────
~100µs (microseconds)         |  11 9's      |  $$$$         | Instance Store
~1ms (milliseconds)           |  11 9's      |  $$$          | EBS General Purpose
~5-10ms                       |  11 9's      |  $$           | EFS (NFS)
~100-500ms                    |  11 9's      |  $            | S3 STANDARD
~1-5 seconds                  |  11 9's      |  $            | S3 INTELLIGENT_TIERING
~3-5 hours (retrieval)        |  11 9's      |  ¢            | S3 GLACIER
~12 hours (retrieval)         |  11 9's      |  ¢¢           | S3 DEEP_ARCHIVE
```

#### Request Path and Performance Boundaries

All S3 requests flow through:

```
Client → CloudFront (optional caching) → S3 API Endpoint → Partition
```

S3 automatically shards objects across partitions based on key prefix. This enables:
- Unlimited scalability: millions of requests/sec possible
- Predictable latency: hardware-level consistency vs application-level queuing

**Critical DevOps insight**: Poor key design (e.g., timestamps as prefix) can create hot partitions causing request rate limiting (HTTP 503 Slow Down). Proper key design distributes load: `year/month/day/UUID/filename` rather than `timestamp-filename`.

#### Multi-Region and Availability Considerations

S3 buckets are **regional** but objects can be replicated across regions. This distinction creates architecture patterns:

- **Single Region**: Higher durability (5 AZ replication), lowest cost, simplest
- **Multi-Region (Active-Active)**: CRR enables failover but introduces eventual consistency complexity
- **Multi-Region (Active-Passive)**: Copy to secondary region only after validation; higher RTO but simpler consistency model

#### EBS vs EFS vs S3: Decision Matrix

| Factor | EBS | EFS | S3 |
| --- | --- | --- | --- |
| **Access Model** | Single EC2 (block) | Multiple EC2 (NFSv4) | HTTP/HTTPS (REST) |
| **Latency** | Sub-millisecond | Low milliseconds | 50-100ms typical |
| **Throughput** | 64,000 IOPS | Thousands NFS ops/sec | Multi-GB/sec aggregate |
| **Data Durability** | 11 9's | 11 9's | 11 9's |
| **Consistency** | Strong | Strong | Eventual |
| **Use Cases** | Databases, VMs | Shared filesystems, content | Data lakes, archives, logs |
| **Filesystem Required** | Yes (ext4, xfs) | Built-in | REST API |
| **Snapshots** | Yes (to S3) | No | N/A (versioning instead) |

### Important DevOps Principles

#### 1. Infrastructure as Code (IaC) for Storage Configuration

Storage configuration must be version-controlled and reproducible:

```yaml
# Bad: Manual bucket configuration
# Created storage-prod S3 bucket via AWS Console
# Added lifecycle policy via CLI
# Shared access keys with team

# Good: IaC approach
resource "aws_s3_bucket" "data_lake" {
  bucket = "org-datalake-prod"
  tags = {
    Environment = "production"
    CostCenter  = "analytics"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id
  
  rule {
    id     = "archive_old_data"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "INTELLIGENT_TIERING"
    }
    
    transition {
      days          = 365
      storage_class = "GLACIER_IR"
    }
  }
}
```

#### 2. Defense in Depth for Access Control

Never rely on a single access control mechanism. Implement layering:

1. **Network isolation**: VPC endpoints prevent internet egress
2. **IAM policies**: Least privilege principle (e.g., can't PutObject without explicit permission)
3. **Bucket policies**: Organization-wide enforcement (e.g., must be encrypted)
4. **Object ACLs**: Granular per-object rules (rare, usually overridden by bucket policies)
5. **Encryption**: Data encrypted at-rest (unreadable even if accessed)
6. **Audit logging**: CloudTrail tracks who accessed what, when

#### 3. Cost Optimization Through Data Classification

DevOps must enforce data classification, not application teams:

```
Data Classification Framework:

Hot Data (frequent access):
  └─ Storage Class: STANDARD
  └─ Lifecycle: None
  └─ Replication: Might replicate for HA
  └─ Cost: ~$0.023/GB/month
  └─ Examples: API responses, current logs, active datasets

Warm Data (occasional access):
  └─ Storage Class: STANDARD_IA
  └─ Lifecycle: After 30 days of inactivity
  └─ Replication: Usually same-region only
  └─ Cost: ~$0.0125/GB/month (+ retrieval costs)
  └─ Examples: Week-old logs, archived datasets

Cold Data (rare/compliance-driven access):
  └─ Storage Class: GLACIER_IR
  └─ Lifecycle: After 90+ days
  └─ Replication: Usually to single region
  └─ Cost: ~$0.004/GB/month (+ retrieval costs)
  └─ Examples: Yearly reports, backup data

Frozen Data (archival):
  └─ Storage Class: DEEP_ARCHIVE
  └─ Lifecycle: After 1+ years
  └─ Replication: No
  └─ Cost: ~$0.00099/GB/month (bulk retrieval ~12hrs)
  └─ Examples: Tax records, compliance archives
```

#### 4. Operational Automation and Monitoring

Storage operations require automation:

- **Backup automation**: AWS Backup orchestrates cross-service snapshots
- **Replication monitoring**: CloudWatch metrics detect replication lag
- **Cost monitoring**: AWS Cost Explorer tracks storage spend by bucket/class
- **Compliance audits**: Config Rules validate bucket policies, encryption status
- **Alerting**: SNS notifications on unusual access patterns, quota violations

#### 5. Disaster Recovery Strategy

Storage is the foundation of DR:

```
Tier 1 - Immediate Recovery (RTO: <1 min):
  └─ Active data in STANDARD S3
  └─ Primary EBS snapshots in current region
  └─ Cost: Highest, but fastest recovery

Tier 2 - Regional Recovery (RTO: 1-4 hours):
  └─ Cross-region replicated S3 objects
  └─ EBS snapshots copied to secondary region
  └─ Cost: Medium-high

Tier 3 - Long-term Recovery (RTO: >6 hours):
  └─ GLACIER/DEEP_ARCHIVE backups
  └─ Cost: Lowest
```

### Best Practices

#### S3 Bucket Naming and Partitioning

**Anti-pattern:**
```
my-bucket/my-app/data_2024_03_15_timestamp_userid_sessionid.json
```
Problem: Sequential timestamps create hot partitions → throttling.

**Best practice:**
```
my-bucket/data/year=2024/month=03/day=15/hour=14/account-{uuid}-{sequence}.json
```
Why: UUID in key distributes load across partitions. Year/month/day enables partition pruning in queries.

#### Encryption Strategy

```
At-Rest Encryption:
├─ SSE-S3 (S3-Managed Keys)
│  └─ Default, included in S3 cost
│  └─ Use when: No regulatory requirement for customer-managed keys
│
├─ SSE-KMS (Customer Master Keys)
│  └─ ~$0.03/10k requests additional cost
│  └─ Use when: Regulatory requirement or centralized key management
│
└─ Client-side encryption
   └─ Encrypt before sending to S3
   └─ Use when: Keys must never reach AWS

In-Transit Encryption:
└─ Always use HTTPS
└─ Enforce TLS 1.2+ minimum via bucket policy
```

#### Versioning and Rollback

**Enable versioning proactively** on all production buckets:

```hcl
resource "aws_s3_bucket_versioning" "production" {
  bucket = aws_s3_bucket.production.id
  
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = true  # Require MFA to permanently delete
  }
}
```

Versioning enables:
- Accidental deletion recovery (delete sets current, old version remains)
- Point-in-time data recovery
- Compliance audit trails
- Application rollback without separate backup restore

#### Lifecycle Policy Automation

Automate storage class transitions:

```json
{
  "Rules": [
    {
      "Id": "StandToIA",
      "Status": "Enabled",
      "Prefix": "logs/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    },
    {
      "Id": "StandToArchive",
      "Status": "Enabled",
      "Prefix": "archive/",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "GLACIER_IR"
        }
      ]
    }
  ]
}
```

**Typical lifecycle flow for analytics data:**
```
Day 0        Day 30       Day 90       Day 365
STANDARD  →  STANDARD_IA → GLACIER_IR → DEEP_ARCHIVE (or delete)
```

#### Monitoring and Cost Control

**Set up CloudWatch alarms:**
- Unusual spike in S3 request volume
- Cross-region replication lag exceeds SLA
- Bucket size trending rapidly upward
- Access from unexpected AWS accounts

**Monitor costs:**
- S3 storage costs by bucket and storage class
- Data transfer costs (cross-region, to internet)
- Request volume costs (especially LIST operations which are expensive)

#### Tagging Strategy for Cost Allocation

```hcl
# Enable cost allocation tagging
resource "aws_s3_bucket_tag_set" "mandatory_tags" {
  bucket = aws_s3_bucket.production.id
  
  tags = {
    Environment  = "production"
    CostCenter   = "data-platform"
    Team         = "platform-eng"
    Application  = "data-lake"
    DataClass    = "internal"
    Retention    = "7-years"
  }
}
```

AWS Cost Explorer can then report by any tag dimension.

### Common Misunderstandings

#### Misunderstanding 1: "S3 Versioning Doubles Storage Costs"

**False.** You only pay for stored data. S3 versioning adds a new version only when an object is overwritten—it doesn't create duplicates. If you never overwrite, versioning costs nothing.

**Reality**: Enable versioning everywhere. Disable only if you have frequent overwrites of massive objects and absolutely no recovery requirement.

#### Misunderstanding 2: "S3 is Eventually Consistent, So It's Unreliable"

**Misleading.** S3 *read-after-write* consistency is now provided for all operations (*as of 2020*). The old eventual consistency caveat no longer applies to normal operations.

**Reality**: Trust S3's consistency model—it's been battle-tested with trillions of objects. Consistency issues in your architecture are usually application-level (e.g., DynamoDB → S3 → DynamoDB loop).

#### Misunderstanding 3: "Just Use S3 Intelligent-Tiering for Everything"

**Tempting but wrong.** Intelligent-Tiering has overhead:
- Monitoring cost: ~$0.0025 per 1,000 objects/month
- Minimum 30-day commitment to frequent tier
- Network scan overhead for infrequent tier detection

**When to use:**
- Unknown access patterns (analytics datasets, user uploads)
- Cost optimization when baseline cost is high enough
- Never for small datasets (<1GB)

**Better alternatives:**
- Known access pattern? Use specific storage class (STANDARD_IA, GLACIER_IR)
- Unknown, small dataset? Keep in STANDARD
- Unknown, large dataset? Use Intelligent-Tiering

#### Misunderstanding 4: "EBS Snapshots are Point-in-Time; No Versioning Needed"

**Incomplete thinking.** EBS snapshots capture volume state at a moment but don't preserve application semantics. You need storage-level protection:

```
Bad scenario:
Corrupted application writes corrupt data → EBS snapshot captures corruption
Later snapshot is just as corrupted

Better scenario:
Enable EBS snapshots + S3 versioning for application data
Snapshots protect against hardware failure
Versioning protects against application failure
```

#### Misunderstanding 5: "Encryption Adds Significant Latency"

**False.** AWS KMS encryption adds <1ms for most workloads. Doesn't require network roundtrip for KMS—keys are cached in S3 metal.

**Reality**: Enable encryption everywhere; performance impact is negligible, security gain is massive.

#### Misunderstanding 6: "IAM Policies are Enough; Bucket Policies are Legacy"

**Wrong.** Best practice requires both:

- **IAM policies**: Control what principals can do (principal-based)
- **Bucket policies**: Control what happens in the bucket (resource-based enforcement)

Example: Even with perfect IAM, a bucket policy can enforce "all objects must be encrypted" or "no public ACLs" organization-wide.

#### Misunderstanding 7: "Cross-Region Replication is for Disaster Recovery Only"

**Narrow view.** CRR enables:
1. Disaster recovery (primary region failure)
2. Compliance (data residency in specific regions)
3. Performance optimization (global users access nearest region)
4. Multi-region analytics (replicate data for regional processing)
5. Data sovereignty (meet regulatory requirements)

---

## S3, S3 Storage Classes and Pricing vs Performance

### Textual Deep Dive

#### Internal Working Mechanism

S3 operates as a key-value store spanning multiple Availability Zones within a region. When you upload an object, AWS performs the following sequence:

1. **Request Authorization**: The S3 API endpoint validates AWS credentials and IAM permissions
2. **Partition Assignment**: The object key is hashed to determine which S3 partition (shard) stores the object. This enables parallel scalability—each partition handles millions of requests/sec independently
3. **Replication**: The object is written to primary storage, then asynchronously replicated to two additional AZs (minimum 3 copies automatically)
4. **Metadata Indexing**: S3 indexes the object metadata (key, size, storage class, tags, ACL) in a distributed index enabling fast listing and filtering
5. **Consistency Guarantee**: Once S3 returns a 200 response, the object is durably stored across AZs and readable by all clients

**Critical insight**: S3 is not a filesystem that "stores files." It's a distributed key-value database. This distinction explains performance characteristics:
- **No filesystem overhead**: No inode tables, no directory structures to traverse
- **Flat namespace**: All objects are equally accessible regardless of "folder" structure
- **Partition-based scaling**: Performance scales with partition count, not application demand

#### Storage Classes: Architecture and Economics

AWS offers 7 storage classes, each optimizing for different access patterns:

```
┌──────────────────────────────────────────────────────────────────┐
│                    STORAGE CLASS SPECTRUM                        │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  STANDARD                                                       │
│  ├─ Availability: 99.99%                                        │
│  ├─ Durability: 11 9's                                          │
│  ├─ Replication: 3+ AZs                                         │
│  ├─ Cost: ~$0.023/GB/month                                      │
│  └─ Retrieval: Immediate (first byte in <100ms)                │
│                                                                  │
│  STANDARD_IA (Infrequent Access)                               │
│  ├─ Availability: 99.9%                                         │
│  ├─ Durability: 11 9's                                          │
│  ├─ Replication: 3+ AZs                                         │
│  ├─ Cost: ~$0.0125/GB/month + $0.01/1000 retrievals           │
│  ├─ Min storage duration: 30 days                              │
│  └─ Retrieval: Immediate                                        │
│                                                                  │
│  ONEZONE_IA (Single AZ, Infrequent Access)                     │
│  ├─ Availability: 99.5%                                         │
│  ├─ Durability: 11 9's (single AZ replication)                 │
│  ├─ Replication: 1 AZ only                                      │
│  ├─ Cost: ~$0.01/GB/month + $0.01/1000 retrievals             │
│  ├─ Min storage duration: 30 days                              │
│  └─ Retrieval: Immediate                                        │
│                                                                  │
│  INTELLIGENT_TIERING                                            │
│  ├─ Availability: 99.9%                                         │
│  ├─ Durability: 11 9's                                          │
│  ├─ Auto-tiering: Frequent/Infrequent/Archive (configurable)  │
│  ├─ Cost: ~$0.0125/GB (tier 1) + monitoring ($0.0025/1k obj)  │
│  └─ Retrieval: Varies by tier                                   │
│                                                                  │
│  GLACIER_IR (Instant Retrieval)                                │
│  ├─ Availability: 99.9%                                         │
│  ├─ Durability: 11 9's                                          │
│  ├─ Cost: ~$0.004/GB/month + $0.03/1000 retrievals            │
│  ├─ Min storage duration: 90 days                              │
│  └─ Retrieval: Instant (<250ms)                                │
│                                                                  │
│  GLACIER_FLEX (Flexible Retrieval)                             │
│  ├─ Availability: 99.9%                                         │
│  ├─ Durability: 11 9's                                          │
│  ├─ Cost: ~$0.0036/GB/month + $0.01/1000 retrievals           │
│  ├─ Min storage duration: 90 days                              │
│  └─ Retrieval: Expedited (1-5 min), Standard (3-5 hr)         │
│                                                                  │
│  DEEP_ARCHIVE                                                   │
│  ├─ Availability: 99.99%                                        │
│  ├─ Durability: 11 9's                                          │
│  ├─ Cost: ~$0.00099/GB/month + $0.02/1000 retrievals          │
│  ├─ Min storage duration: 180 days                             │
│  └─ Retrieval: Standard (12 hr), Bulk (48 hr)                  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Economics Analysis:**

For a 10GB dataset accessed weekly:
```
STANDARD:        $0.023 × 12 months × 10GB = $2.76/year (immediate access)
INTELLIGENT_IA:  $0.0125 × 12 × 10 + $2.50 monitor = $3.50/year + retrieval
GLACIER_IR:      $0.004 × 12 × 10 + $30/year retrieval = $30.48/year
GLACIER_FLEX:    $0.0036 × 12 × 10 + $10/year retrieval = $10.43/year
DEEP_ARCHIVE:    $0.00099 × 12 × 10 + $200/year retrieval = $200.12/year
```

**Correct decision**: STANDARD for actively accessed data. GLACIER_IR if accessed monthly. GLACIER_FLEX if accessed quarterly.

#### Architecture Role in DevOps

Storage class selection directly impacts:

1. **Cost Optimization Budget** ($x/month storage versus $y/month compute)
2. **RTO/RPO calculations** (DEEP_ARCHIVE has 48hr retrieval; can't be primary tier for RTO <4 hours)
3. **Compliance requirements** (ONEZONE_IA violates "multi-region" requirements)
4. **Data pipeline efficiency** (Hot data in STANDARD for Athena queries; cold in GLACIER for archives)

#### Production Usage Patterns

**Data Lake Architecture** (Most Common):
```
Raw Ingestion → STANDARD bucket (transient, 24 hours)
    ↓
Bronze Layer → STANDARD_IA (7 days inactivity)
    ↓
Silver Layer → INTELLIGENT_TIERING (unknown pattern)
    ↓
Gold Layer → STANDARD (active queries)
    ↓
Archive → GLACIER_FLEX (lifecycle after 1 year)
```

**Backup and Disaster Recovery**:
```
EBS Snapshots → STANDARD (primary, cross-region)
                    ↓ (after 30 days)
                STANDARD_IA (secondary)
                    ↓ (after 90 days)
                DEEP_ARCHIVE (compliance hold)
```

**Log Aggregation**:
```
Real-time logs → STANDARD (S3 + Athena queries)
    ↓ (after 30 days)
    STANDARD_IA (occasional audits)
    ↓ (after 90 days)
    GLACIER_IR (rare requests)
    ↓ (after 7 years)
    Expired (regulatory requirement met)
```

#### DevOps Best Practices

**1. Tag-Based Cost Allocation**
```hcl
resource "aws_s3_bucket_tag_set" "classification" {
  bucket = aws_s3_bucket.analytics.id
  
  tags = {
    StorageClass      = "intelligent"  # Drives policy decisions
    CostCenter        = "analytics"
    DataRetention     = "7-years"
    AccessFrequency   = "weekly"       # Drives class selection
  }
}
```

**2. Lifecycle Policies Driven by Metadata**
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "tiered" {
  bucket = aws_s3_bucket.datalake.id
  
  # Rule 1: Data with "archive-after-30d" tag
  rule {
    id       = "tag_driven_archive"
    status   = "Enabled"
    
    filter {
      tag {
        key   = "archive-policy"
        value = "30d"
      }
    }
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  
  # Rule 2: Objects older than expiration date
  rule {
    id       = "compliance_expiration"
    status   = "Enabled"
    
    filter {
      tag {
        key   = "retention"
        value = "compliant"
      }
    }
    
    expiration {
      days = 2555  # 7 years
    }
  }
}
```

**3. Storage Class Analysis**
Monitor which storage class is actually cost-optimal:
```bash
# CLI: Export all objects with storage class metadata
aws s3api list-objects-v2 \
  --bucket my-bucket \
  --query 'Contents[*].[Key,StorageClass,Size]' \
  --output table > storage-inventory.txt

# Identify misclassified objects
# Find objects in STANDARD that haven't been accessed in 60 days
aws s3api list-objects-v2 \
  --bucket my-bucket \
  --query 'Contents[?StorageClass==`STANDARD`].[Key,LastModified,Size]' \
  --output json | \
  jq -r '.[] | select(.LastModified < "2024-01-15Z") | .Key'
```

**4. Intelligent Tiering Configuration**
```hcl
resource "aws_s3_bucket_intelligent_tiering_configuration" "auto_archive" {
  bucket = aws_s3_bucket.data.id
  name   = "auto-archive-policy"
  
  tiering {
    # Moves objects here after 31 days of no access
    days          = 31
    access_tier   = "ARCHIVE_ACCESS"
  }
  
  tiering {
    # Moves objects here after 91 days of no access
    days          = 91
    access_tier   = "DEEP_ARCHIVE_ACCESS"
  }
  
  status = "Enabled"
}
```

#### Common Pitfalls

**Pitfall 1: Choosing Intelligent-Tiering for Everything**
Problem: Monitoring costs ($0.0025/1000 objects) exceed storage savings for small datasets.
Solution: Use specific classes for known patterns; Intelligent-Tiering only for unknown/variable access.

**Pitfall 2: Not Accounting for Minimum Storage Duration**
Problem: Store object in GLACIER_IR, delete after 45 days. Charged for full 90 days.
Solution: Model lifecycle policies before implementation. Calculate break-even point.

**Pitfall 3: ONEZONE_IA for "Important" Data**
Problem: Single AZ failure causes data loss despite "11 9's durability."
Solution: ONEZONE_IA acceptable only for non-critical, reproducible data (caches, temporary datasets).

**Pitfall 4: Hot Partition Due to Key Design**
Problem: Storing objects with keys like `YYYY-MM-DD-HH-MM-SS-uuid.gz` creates sequential prefixes hitting same partition.
Solution: Use: `YYYY/MM/DD/HH/uuid-sequence-YYYY-MM-DD-HH-MM-SS.gz` to distribute across partitions.

---

## S3 Versioning, Lifecycle, Replication & Cross-Region Replication, Object Lock, MFA Delete, S3 Object Lambda, S3 Object Tagging, S3 Object ACLs & Bucket Policies

### Textual Deep Dive

#### S3 Versioning: Internal Mechanism

When versioning is enabled on a bucket, S3 assigns a unique **Version ID** to every object PUT operation. The version ID is a 32-character alphanumeric string generated by AWS. This creates a version history:

```
PUT operation 1 → Version ID: "ABC123XYZ..." (marked as Current)
PUT operation 2 → Version ID: "DEF456PQR..." (marked as Current)
                  Version ID: "ABC123XYZ..." (marked as Previous)
PUT operation 3 → Version ID: "GHI789STU..." (marked as Current)
                  Version ID: "DEF456PQR..." (marked as Previous)
                  Version ID: "ABC123XYZ..." (marked as Previous)

DELETE operation → Creates delete marker
                   All previous versions remain accessible
                   GET returns 404 (delete marker is "current")
                   But GET with Version ID parameter still retrieves old version
```

**Key distinction from filesystem delete:**
- Filesystem delete: File removed, recovery requires external backup
- S3 versioning delete: Delete marker created, previous versions persist, recovery = copy previous version to current

**Durability implication**: With versioning, each version is independently durable (11 9's). Delete a file 100 times; all 100 versions remain retrieval-safe.

#### Lifecycle Policies: State Machine

Lifecycle policies define state transitions on objects based on age or metadata:

```
Object Creation
    ↓
    ├─ Day 0-29: STANDARD (current version)
    ├─ Day 30: TRANSITION to STANDARD_IA
    ├─ Day 90: TRANSITION to GLACIER_IR
    ├─ Day 365: TRANSITION to DEEP_ARCHIVE
    └─ Day 730: EXPIRATION (deleted permanently)

For Previous Versions (when versioning enabled):
    ├─ Day 1: Created (previous version after new PUT)
    ├─ Day 30: TRANSITION to STANDARD_IA
    ├─ Day 90: TRANSITION to GLACIER_IR
    └─ Day 365: EXPIRATION (previous version deleted)
```

Lifecycle policies can filter by:
- **Prefix**: Apply rule only to `logs/` directory
- **Tags**: Apply only if `archive=true`
- **Object size**: Apply only to objects >1GB
- **Storage class**: Apply only to objects in STANDARD

#### Replication: Two Strategies

**Same-Region Replication (SRR):**
- Source and destination in same region
- Use case: Compliance backup (WORM target), logging aggregation, failover within region
- Typical latency: Sub-second replication
- Cost: Data transfer charge only

**Cross-Region Replication (CRR):**
- Source and destination in different regions
- Use case: Disaster recovery (region failure), compliance (data residency), performance (geography)
- Typical latency: 15 seconds to 5 minutes (depends on serialization on source, destination region load)
- Cost: Data transfer charge (egress from source region + ingress to destination)

**Replication Flow:**
```
Object PUT in Source Bucket
    ↓
S3 Internal Replication Service detects new object
    ↓
Serializes object → Transfers over AWS backbone network
    ↓
PUTs object in Destination Bucket with same metadata
    ↓
Destination bucket notified of replication completion
    ↓
Source object tagged with: x-amz-replication-status = COMPLETE
```

**Consistency model**: CRR is **eventually consistent**. Source and destination may diverge briefly. Objects modified before replication is configured are NOT replicated (replication is forward-only).

#### Object Lock and MFA Delete: Immutability

**Object Lock** (governance or compliance mode):
- Prevents object overwrite/deletion for specified period
- **Governance mode**: Can be bypassed with special IAM permission (recovery mechanism)
- **Compliance mode**: Irreversible, even root account cannot delete until retention expires
- Common with: WORM (Write-Once-Read-Many) workflows, log retention

**MFA Delete** (requires Physical MFA device):
- Protects versioned bucket
- Deletes and lifecycle configuration changes require MFA-authenticated DELETE request
- Mitigates risk: Compromised AWS credentials alone cannot destroy data
- Must be enabled by root account

#### S3 Object Lambda: Transformation at Scale

Object Lambda intercepts S3 GET requests and applies transformations via Lambda functions:

```
GET Request for /sensitive-data.json
    ↓
S3 detects Object Lambda rule matches
    ↓
Invokes Lambda function with S3 request context
    ↓
Lambda executes transformation (e.g., PII masking, format conversion, redaction)
    ↓
Lambda returns modified object
    ↓
Client receives transformed data (not aware transformation occurred)
```

**Common use cases:**
- Redact PII from objects before returning to applications
- Convert formats on-the-fly (CSV → Parquet)
- Filter data based on requesting principal (user-specific views)
- Watermark or add metadata

#### S3 Object Tagging: Metadata-Driven Operations

Tags are key-value pairs attached to objects (separate from object metadata headers):

```
Object: /user-logs/2024-03-15/session-abc123.log

Headers:
  Content-Type: text/plain
  Content-Length: 102400

Tags:
  department = analytics
  retention = 90d
  access-frequency = low
  cost-center = 4829
```

Tags enable:
- **Lifecycle policies**: Transition `retention=90d` tagged objects after 90 days
- **Access control**: Deny PutObject for objects without `classification=public`
- **Cost allocation**: Report storage costs grouped by `cost-center` tag
- **Backup strategies**: Snapshot only objects with `backup=true`

#### S3 Bucket Policies vs ACLs vs IAM: Layered Security

**IAM Policies** (Principal-based):
```json
{
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789:user/alice"
    },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```
Controls: What can an IAM principal do?

**Bucket Policies** (Resource-based):
```json
{
  "Statement": [{
    "Effect": "Deny",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": {
      "Bool": { "aws:SecureTransport": "false" }
    }
  }]
}
```
Controls: What can be done to this bucket?

**ACLs** (Legacy):
```
BucketOwner: FULL_CONTROL
GroupAwsUsers: READ
AmazonRDSDataShares: READ
```
Controls: Predefined grants to AWS accounts or groups.

**Evaluation logic** (ALL must allow):
```
1. Explicit Deny in any policy → DENIED
2. No Allow found → DENIED
3. Allow found (IAM or Bucket or ACL) → ALLOWED
```

Best practice: Use IAM for principal-based, bucket policies for resource-wide enforcement.

#### Common Architecture Pattern: Multi-Layer Access Control

```
┌─────────────────────────────────────────────────────────┐
│ Network Layer                                           │
│ └─ VPC Endpoint: Only traffic from specific VPC        │
├─────────────────────────────────────────────────────────┤
│ IAM Layer                                               │
│ └─ Principal can perform s3:GetObject                  │
├─────────────────────────────────────────────────────────┤
│ Bucket Policy Layer                                     │
│ └─ Deny all unless encrypted (aws:x-amz-server-side-  │
│    encryption: AES256)                                 │
├─────────────────────────────────────────────────────────┤
│ Object Tag Layer                                        │
│ └─ Deny access unless object has classification=public │
├─────────────────────────────────────────────────────────┤
│ Encryption Layer                                        │
│ └─ Object encrypted with customer-managed KMS key      │
├─────────────────────────────────────────────────────────┤
│ Audit Layer                                             │
│ └─ All access logged to CloudTrail                     │
└─────────────────────────────────────────────────────────┘
```

#### Advanced Pattern: Bucket Policies for Compliance

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceHTTPS",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": ["arn:aws:s3:::my-bucket/*"],
      "Condition": {
        "Bool": { "aws:SecureTransport": "false" }
      }
    },
    {
      "Sid": "EnforceEncryption",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": "DenyUnwantedStorageClass",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-storage-class": ["ONEZONE_IA"]
        }
      }
    }
  ]
}
```

---

### Practical Code Examples

#### S3 Versioning Configuration

**Enable via Terraform:**
```hcl
resource "aws_s3_bucket" "versioned" {
  bucket = "my-versioned-bucket-prod"
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.versioned.id
  
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = true  # Requires MFA for deletions
  }
}

# Enforce deletion protection
resource "aws_s3_bucket_lifecycle_configuration" "noncurrent_prune" {
  bucket = aws_s3_bucket.versioned.id
  
  # Delete old versions after 90 days (compliance requirement)
  rule {
    id     = "delete_old_versions"
    status = "Enabled"
    
    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    noncurrent_version_expiration {
      days = 90
    }
  }
}
```

**Version operations via CLI:**
```bash
# Upload object (creates version 1)
aws s3api put-object \
  --bucket my-bucket \
  --key data.json \
  --body ./data.json

# List all versions
aws s3api list-object-versions \
  --bucket my-bucket \
  --key data.json

# Retrieve specific version
aws s3api get-object \
  --bucket my-bucket \
  --key data.json \
  --version-id ABC123XYZ \
  ./data-v1.json

# Restore previous version (copy old version as current)
aws s3api copy-object \
  --copy-source my-bucket/data.json?versionId=ABC123XYZ \
  --bucket my-bucket \
  --key data.json

# Delete current version (creates delete marker)
aws s3api delete-object \
  --bucket my-bucket \
  --key data.json

# Permanently delete version (requires MFA)
aws s3api delete-object \
  --bucket my-bucket \
  --key data.json \
  --version-id ABC123XYZ \
  --region us-east-1
```

#### Lifecycle Policies

**Complex lifecycle policy (Terraform):**
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.analytics.id
  
  # Rule 1: Transition based on creation time
  rule {
    id       = "tiered-transition"
    status   = "Enabled"
    prefix   = "data/"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }
    
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
    
    expiration {
      days = 2555  # 7 years
    }
  }
  
  # Rule 2: Expire old versions quickly
  rule {
    id       = "expire-old-versions"
    status   = "Enabled"
    
    noncurrent_version_expiration {
      days = 30
    }
  }
  
  # Rule 3: Delete incomplete multipart uploads
  rule {
    id       = "cleanup-multipart"
    status   = "Enabled"
    
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

**Lifecycle policy via JSON (CloudFormation):**
```yaml
Resources:
  DataLakeBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: my-datalake-prod
      VersioningConfiguration:
        Status: Enabled
      LifecycleConfiguration:
        Rules:
          - Id: TransitionToIA
            Status: Enabled
            Prefix: archive/
            Transitions:
              - TransitionInDays: 30
                StorageClass: STANDARD_IA
              - TransitionInDays: 90
                StorageClass: GLACIER_IR
            NoncurrentVersionTransitions:
              - TransitionInDays: 7
                StorageClass: STANDARD_IA
            ExpirationInDays: 365
          - Id: CleanupMultipart
            Status: Enabled
            AbortIncompleteMultipartUpload:
              DaysAfterInitiation: 7
```

#### Replication Configuration

**Cross-Region Replication (Terraform):**
```hcl
# Source bucket (us-east-1)
resource "aws_s3_bucket" "source" {
  bucket = "my-source-bucket-prod"
  region = "us-east-1"
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Destination bucket (eu-west-1)
resource "aws_s3_bucket" "destination" {
  bucket = "my-dest-bucket-prod"
  region = "eu-west-1"
}

resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  name = "s3-crr-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  name   = "s3-crr-policy"
  role   = aws_iam_role.replication.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.source.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Resource = "${aws_s3_bucket.source.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}

# Replication configuration
resource "aws_s3_bucket_replication_configuration" "crr" {
  depends_on = [aws_s3_bucket_versioning.source]
  
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication.arn
  
  rule {
    id       = "replicate-all"
    status   = "Enabled"
    priority = 1
    
    filter {
      prefix = ""  # Replicate all objects
    }
    
    destination {
      bucket       = aws_s3_bucket.destination.arn
      storage_class = "STANDARD_IA"  # Reduce cost in dr-region
      
      replication_time {
        status = "Enabled"
        time {
          minutes = 15  # RTC: replicate within 15 mins
        }
      }
      
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }
  }
}
```

**Check replication status (CLI):**
```bash
# Monitor replication progress
aws s3api list-object-versions \
  --bucket my-source-bucket \
  --query 'Versions[*].[Key,VersionId,StorageClass,{"Replication":Metadata.x-amz-replication-status}]' \
  --output table

# Check if destination has replicated objects
aws s3api list-objects-v2 \
  --bucket my-dest-bucket \
  --query 'Contents[*].[Key,Size,LastModified]' \
  --output table

# Count objects matching in both
SOURCE_COUNT=$(aws s3api list-objects-v2 --bucket my-source --query 'KeyCount' --output text)
DEST_COUNT=$(aws s3api list-objects-v2 --bucket my-dest --query 'KeyCount' --output text)
echo "Source: $SOURCE_COUNT, Destination: $DEST_COUNT"
```

#### Object Lock Configuration

**Governance mode with Terraform:**
```hcl
resource "aws_s3_bucket" "compliance_logs" {
  bucket = "my-compliance-logs"
}

resource "aws_s3_bucket_object_lock_configuration" "governance" {
  bucket = aws_s3_bucket.compliance_logs.id
  
  rule {
    default_retention {
      mode = "GOVERNANCE"  # Can be bypassed with s3:BypassGovernanceRetention
      days = 90            # Retain for 90 days
    }
  }
}

# Put object with governance lock
resource "aws_s3_object" "log_entry" {
  bucket       = aws_s3_bucket.compliance_logs.id
  key          = "audit-log-2024-03-15.csv"
  source       = "./audit.csv"
  
  object_lock_mode = "GOVERNANCE"
  object_lock_retain_until_date = "2024-06-13T23:59:59Z"
}
```

**Compliance mode (immutable, even by root):**
```hcl
# Cannot be changed after creation
resource "aws_s3_bucket_object_lock_configuration" "compliance" {
  bucket = aws_s3_bucket.archival.id
  
  rule {
    default_retention {
      mode = "COMPLIANCE"  # Irreversible
      days = 2555           # 7 years
    }
  }
}
```

**Create object with retention via CLI:**
```bash
# Object-level retention (GOVERNANCE)
aws s3api put-object \
  --bucket my-bucket \
  --key important-doc.pdf \
  --body ./doc.pdf \
  --object-lock-mode GOVERNANCE \
  --object-lock-retain-until-date 2025-12-31T23:59:59Z

# Check retention
aws s3api get-object-retention \
  --bucket my-bucket \
  --key important-doc.pdf

# Attempt to delete (will fail unless user has bypass permission)
aws s3api delete-object \
  --bucket my-bucket \
  --key important-doc.pdf
# Result: AccessDenied - the object is under retention
```

#### S3 Object Tagging and Filtering

**Apply tags via Terraform:**
```hcl
resource "aws_s3_object" "data_file" {
  bucket = aws_s3_bucket.analytics.id
  key    = "datasets/2024-03-15-transactions.parquet"
  source = "./transactions.parquet"
  
  tags = {
    Environment     = "production"
    DataClass       = "internal"
    Retention       = "7-years"
    CostCenter      = "analytics"
    AccessPattern   = "monthly"
    BackupRequired  = "true"
  }
}
```

**Apply tags in bulk via CLI:**
```bash
# Tag all objects with prefix "archive/"
aws s3api put-bucket-tagging \
  --bucket my-bucket \
  --tagging 'TagSet=[
    {Key=Environment,Value=prod},
    {Key=BackupRequired,Value=true}
  ]'

# More practical: tag via lifecycle policy interaction
# Tag objects based on age (requires script)
for obj in $(aws s3api list-objects-v2 --bucket my-bucket --query 'Contents[*].Key' --output text); do
  aws s3api put-object-tagging \
    --bucket my-bucket \
    --key "$obj" \
    --tagging 'TagSet=[{Key=LastProcessed,Value=2024-03-15}]'
done
```

**Use tags in lifecycle policies:**
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "tagged_archive" {
  bucket = aws_s3_bucket.datalake.id
  
  rule {
    id     = "archive-tagged-data"
    status = "Enabled"
    
    filter {
      and {
        prefix = "datasets/"
        tags = {
          ArchivePolicy = "30days"
        }
      }
    }
    
    transition {
      days          = 30
      storage_class = "GLACIER_IR"
    }
  }
}
```

#### Object Lambda Transformation

**Python Lambda function for PII masking:**
```python
import json
import boto3
import re
from urllib.parse import unquote_plus

s3 = boto3.client('s3')

def lambda_handler(event, context):
    """
    Intercepts S3 GET requests and masks sensitive data.
    """
    
    # Extract request context
    get_context = event['getObjectContext']
    route = get_context['outputRoute']
    token = get_context['outputToken']
    s3_url = get_context['inputS3Url']
    
    # Fetch object from S3
    response = requests.get(s3_url)
    original_object = response.text
    
    # Transform: Mask email addresses
    masked_object = re.sub(
        r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
        r'***@***',
        original_object
    )
    
    # Transform: Mask credit card numbers
    masked_object = re.sub(
        r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b',
        '****-****-****-****',
        masked_object
    )
    
    # Write transformed object back
    s3.write_get_object_response(
        Body=masked_object.encode('utf-8'),
        ContentType='text/plain',
        ContentLength=len(masked_object),
        OutputRoute=route,
        OutputToken=token
    )
    
    return {'statusCode': 200}
```

**Configure Object Lambda in Terraform:**
```hcl
resource "aws_s3_object_lambda_access_point" "pii_masking" {
  name = "pii-masking-oapbucket = aws_s3_bucket.sensitive.id

  configuration {
    supporting_access_point = aws_s3_access_point.standard.arn
    
    transformation_configuration {
      actions = ["GetObject"]
      
      content_transformation {
        aws_lambda {
          function_arn       = aws_lambda_function.mask_pii.arn
          function_payload   = "{\"mode\": \"mask-pii\"}"
        }
      }
    }
  }
}
```

#### Bucket Policies for Compliance

**Enforce encryption and HTTPS:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": [
            "AES256",
            "aws:kms"
          ]
        }
      }
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

**Apply via Terraform:**
```hcl
resource "aws_s3_bucket_policy" "compliance_enforced" {
  bucket = aws_s3_bucket.production.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceHTTPS"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.production.arn,
          "${aws_s3_bucket.production.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "DenyPublicACL"
        Effect = "Deny"
        Principal = "*"
        Action = [
          "s3:PutObjectAcl",
          "s3:PutBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.production.arn,
          "${aws_s3_bucket.production.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = [
              "public-read",
              "public-read-write"
            ]
          }
        }
      }
    ]
  })
}
```

---

### ASCII Diagrams

#### S3 Partition and Replication Flow

```
PUT /my-bucket/year=2024/month=03/day=15/uuid-abc-123.json

S3 API (us-east-1 endpoint)
    │
    ├─ Hash Key Name
    │  Determine Partition ID
    │
    └─ Partition Assignment
       ┌──────────────────────────────────────┐
       │ Partition-0 → AZ-1, AZ-2, AZ-3      │
       │ (Primary writes here)                 │
       │ ┌──────────────────────────────────┐ │
       │ │ Metadata Index                   │ │
       │ │ Key: year=2024/month=03/...     │ │
       │ │ Size: 4096 bytes                │ │
       │ │ ETag: a3b8c4d2e1f9g6h5...       │ │
       │ │ StorageClass: STANDARD           │ │
       │ │ Tags: {Archive: false}           │ │
       │ └──────────────────────────────────┘ │
       │                                      │
       │ Replication Targets (within region): │
       │   ├─ AZ-2: REPLICA (sync)           │
       │   └─ AZ-3: REPLICA (sync)           │
       │                                      │
       │ Cross-Region Replication Trigger:   │
       │   └─ Queue to eu-west-1 (async)     │
       └──────────────────────────────────────┘
    │
    └─ Response to Client
       200 OK
       {
         "ETag": "a3b8c4d2e1f9g6h5...",
         "VersionId": "ABC123XYZ...",
         "ServerSideEncryption": "AES256"
       }

Async: Cross-Region Replication
    │
    └─ eu-west-1 Replication Service
       │
       ├─ Fetch object metadata + data
       │  from us-east-1
       │
       └─ Write to eu-west-1 partition
          ┌──────────────────────────────────────┐
          │ Partition-M (eu-west-1)              │
          │ ┌──────────────────────────────────┐ │
          │ │ Same object, same metadata       │ │
          │ │ Replicated: 2024-03-15T14:32:01Z│ │
          │ │ ReplicationStatus: COMPLETE      │ │
          │ └──────────────────────────────────┘ │
          │                                      │
          │ Replication Targets (within region): │
          │   ├─ AZ-4: REPLICA (sync)           │
          │   └─ AZ-5: REPLICA (sync)           │
          └──────────────────────────────────────┘
```

#### Lifecycle Transition Timeline

```
Object Lifecycle With Transitions and Expiration

│                CREATION → 365 DAYS → DELETION
│
├─ Day 0-30 (CURRENT VERSION, STANDARD)
│  │
│  ├─ Storage: Fully replicated across 3+ AZs
│  ├─ Cost: $0.023/GB/month
│  ├─ Access Time: ~100ms
│  └─ Use Case: Active queries, real-time access
│
├─ Day 30 → TRANSITION to STANDARD_IA
│  │
│  ├─ Storage: Moved to different tier
│  ├─ Cost: $0.0125/GB/month + $0.01 per 1k retrievals
│  ├─ Access Time: Immediate (on-demand)
│  └─ Use Case: Occasional access, week-old data
│
├─ Day 90 → TRANSITION to GLACIER_IR
│  │
│  ├─ Storage: Compressed, lower redundancy at edge
│  ├─ Cost: $0.004/GB/month + $0.03 per 1k retrievals
│  ├─ Access Time: 250ms - 1s (instant retrieval)
│  └─ Use Case: Archival, monthly audit access
│
├─ Day 365 → TRANSITION to DEEP_ARCHIVE
│  │
│  ├─ Storage: Off-line tier, tape backup
│  ├─ Cost: $0.00099/GB + $0.02 per 1k retrievals
│  ├─ Retrieval Time: 12 hours (standard) to 48 hours (bulk)
│  └─ Use Case: Compliance, disaster recovery
│
└─ Day 730 → EXPIRATION (DELETE)
   │
   ├─ Object marked for deletion
   ├─ No further storage charges
   ├─ If versioned, previous versions remain
   └─ If not versioned, object removed from bucket

COST IMPACT EXAMPLE (10GB object):
  Day 0-30:   $0.023 × 10 = $0.23
  Day 30-90:  $0.0125 × 10 = $0.125
  Day 90-365: $0.004 × 10 = $0.04
  Day 365+:   $0.00099 × 10 = $0.01/month
  
  Total Year 1: ~$2.76 (if follows transitions)
  vs. STANDARD only: $2.76 (same if only used for 1 year)
  
  Total Year 2-7: $0.01/month = $0.07/month
  vs. STANDARD only: $2.76/month = massive savings
```

#### Multi-Region Replication Consistency Model

```
┌─────────────────────────────────────────────────────────────┐
│ Application Architecture with CRR                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Region: us-east-1 (Primary)                              │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ Application Instance (us-east-1a)                    │ │
│  │ ┌──────────────────────────────────────────────────┐ │ │
│  │ │ PUT /data/session-123.json                       │ │ │
│  │ │ {"user_id": "alice", "actions": [...]}           │ │ │
│  │ └──────────────────────────────────────────────────┘ │ │
│  │          ↓ (200 OK - 50ms)                           │ │
│  │ ┌──────────────────────────────────────────────────┐ │ │
│  │ │ Primary: S3 Bucket (us-east-1)                   │ │ │
│  │ │ Object: session-123.json (STANDARD, 3+ copies)   │ │ │
│  │ │ Version ID: v1                                    │ │ │
│  │ └──────────────────────────────────────────────────┘ │ │
│  │          ↓ (async replication triggered)             │ │
│  │ ┌──────────────────────────────────────────────────┐ │ │
│  │ │ Replication Queue                                │ │ │
│  │ │ → Serialize object data & metadata              │ │ │
│  │ │ → Cross-region transfer initiate                │ │ │
│  │ └──────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  ~15 second delay                                          │
│         ↓                                                   │
│                                                             │
│  Region: eu-west-1 (Secondary/DR)                         │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ S3 Bucket (eu-west-1)                               │ │
│  │ Object: session-123.json (STANDARD_IA, 3+ copies)   │ │
│  │ Version ID: v1 (same)                               │ │
│  │ ReplicationStatus: COMPLETE                         │ │
│  │ LastModified: 2024-03-15T14:32:15Z                 │ │
│  │                                                      │ │
│  │ Accessible via:                                      │ │
│  │ ├─ GET /session-123.json → 200 (eventual consistent) │ │
│  │ ├─ For regional failover                             │ │
│  │ └─ For compliance data residency                     │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  Consistency Guarantee:                                    │
│  ├─ Within 15 minutes: Objects replicated 99.99% of time │
│  ├─ After 15 minutes: Failed replication triggers alert   │ │
│  ├─ During replication lag:                               │ │
│  │  └─ GET from primary: Latest version                   │ │
│  │  └─ GET from secondary: Stale or missing version       │ │
│  └─ Application must handle eventual consistency          │ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### Versioning with Delete Markers

```
Timeline: Versions and Delete Markers

PUT /file.txt (version: v1, content: "hello")
PUT /file.txt (version: v2, content: "hello world")
DELETE /file.txt
PUT /file.txt (version: v3, content: "hello world 2")

Bucket State After Operations:
┌─────────────────────────────────────────────┐
│ Object: /file.txt                           │
├─────────────────────────────────────────────┤
│                                             │
│ Current Version (v3):                       │
│ ┌──────────────────────────────────────┐   │
│ │ Content: "hello world 2"             │   │
│ │ Size: 15 bytes                       │   │
│ │ IsLatest: true                       │   │
│ │ StorageClass: STANDARD               │   │
│ └──────────────────────────────────────┘   │
│                                             │
│ Previous Versions (retrievable):            │
│ ┌──────────────────────────────────────┐   │
│ │ v2: Content: "hello world"           │   │
│ │     IsLatest: false                  │   │
│ │     DeleteMarker: false              │   │
│ │     Available: Yes                   │   │
│ └──────────────────────────────────────┘   │
│                                             │
│ ┌──────────────────────────────────────┐   │
│ │ DELETE MARKER (from DELETE operation)│   │
│ │     IsLatest: false (overridden by v3)   │
│ │     Available: Yes                   │   │
│ │     Purpose: Tracks deletion history │   │
│ └──────────────────────────────────────┘   │
│                                             │
│ ┌──────────────────────────────────────┐   │
│ │ v1: Content: "hello"                 │   │
│ │     IsLatest: false                  │   │
│ │     DeleteMarker: false              │   │
│ │     Available: Yes                   │   │
│ └──────────────────────────────────────┘   │
│                                             │
├─────────────────────────────────────────────┤
│ Actions:                                    │
│ ├─ GET /file.txt                           │
│ │  → Returns v3 (current)                  │
│ │  → HTTP 200                              │
│ │                                          │
│ ├─ GET /file.txt?versionId=v2             │
│ │  → Returns v2 content                    │
│ │  → HTTP 200                              │
│ │  → Restore: Copy v2 as new current      │
│ │                                          │
│ ├─ DELETE /file.txt (without versionId)   │
│ │  → Creates new delete marker (v4)       │
│ │  → GET returns 404, but v3 still   │
│ │     available via versionId         │
│ │                                          │
│ └─ DELETE /file.txt?versionId=v2          │
│    → Permanently removes v2 (no recovery) │
│    → Requires MFA if MFA Delete enabled   │
└─────────────────────────────────────────────┘

Key Insight: Versioning ≠ Backup
├─ Versioning is for accidental overwrites
├─ Backup requires separate cross-region replication
└─ Together they provide comprehensive data protection
```

---

## S3 IAM & Access Control

### Textual Deep Dive

#### Internal Working Mechanism: Policy Evaluation

When a principal (IAM user, role, or AWS account) attempts an S3 action, AWS evaluates policies in a specific order:

```
Request: DELETE /my-bucket/sensitive-data.csv (from IAM user: alice)
  ↓
1. Check for EXPLICIT DENY
   ├─ Principal Policy: No Deny matched
   ├─ Bucket Policy: No Deny matched
   ├─ ACL: No Deny matched
   └─ Result: Continue (no explicit deny = OK)

2. Check for ALLOW
   ├─ IAM Policy for alice:
   │  ├─ s3:GetObject on my-bucket/* → ALLOW
   │  └─ s3:DeleteObject on my-bucket/* → NOT FOUND
   │
   ├─ Bucket Policy:
   │  ├─ s3:* denied unless aws:SecureTransport=true
   │  └─ Request used HTTPS → NOT DENIED
   │
   └─ Result: Need explicit allow for DeleteObject

3. Final Decision: DENY (no allow found for s3:DeleteObject)

Response: AccessDenied - User: alice is not authorized to perform: s3:DeleteObject
```

**Key insight**: A single Deny supersedes all Allows. No Allow defaults to Deny.

#### Principal vs Resource-Based Access Control

```
IAM Policy (Principal-Based): "What can THIS principal do?"
├─ Attached to: IAM users, roles, groups
├─ Scope: Applies when principal authenticates
├─ Example: User alice can ListBucket and GetObject on prod-bucket
├─ Advantage: Centralized, easy to audit by principal
└─ Limitation: Can't enforce org-wide rules across principals

Bucket Policy (Resource-Based): "What is allowed ON this bucket?"
├─ Attached to: S3 bucket (not principals)
├─ Scope: Applies to ANY principal accessing bucket
├─ Example: All requests must use HTTPS; all objects must be encrypted
├─ Advantage: Organization-wide enforcement, works across accounts
└─ Limitation: Bucket-specific (not portable across buckets)

Evaluation: BOTH must allow (unless explicit Deny)
├─ Alice's IAM Policy: Allow s3:GetObject
├─ Bucket Policy: Allow GetObject only from VPC endpoint
├─ Result: Alice can only GetObject from VPC endpoint
└─ Alice from public internet: DENIED
```

#### SigV4 and Request Signing

S3 uses AWS Signature Version 4 for request authentication. Every request is signed with the requester's secret access key:

```
GET /my-sensitive-file.csv HTTP/1.1
Host: my-bucket.s3.amazonaws.com
Authorization: AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20240315/us-east-1/s3/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=abscd1234efgh
X-Amz-Date: 20240315T143000Z
```

AWS verifies:
1. The access key (AKIA...) is valid
2. The request hasn't been tampered with (signature matches content)
3. The request isn't expired (timestamp in last 15 minutes)
4. The IAM principal has permissions for the action

#### Principal Tags and ABAC

Attribute-Based Access Control (ABAC) uses tags instead of explicit grants:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::my-bucket/*",
    "Condition": {
      "StringEquals": {
        "aws:PrincipalTag/team": "${aws:ResourceTag/team}"
      }
    }
  }]
}
```

This allows: If principal's `team` tag matches the object's `team` tag, allow GetObject. Enables dynamic, scalable access control without modifying policies.

#### Architecture Role: Zero-Trust Model

In DevOps, S3 IAM & access control implements Zero-Trust principles:

```
Zero-Trust S3 Access Model:
├─ Default: DENY all access
├─ Principle 1: Least Privilege
│  └─ Grant only s3:GetObject, never s3:*
├─ Principle 2: Need-to-Know
│  └─ Grant access only to specific prefixes
├─ Principle 3: Audit Everything
│  └─ Enable CloudTrail and S3 access logging
├─ Principle 4: Encrypt Everything
│  └─ Enforce server-side encryption via bucket policy
├─ Principle 5: Assume Breach
│  └─ Use MFA Delete, Object Lock for critical data
└─ Verification: External audits validate access controls
```

#### Production Usage Patterns

**Pattern 1: Cross-Account Data Sharing**

Org A (Account 123) shares data with Org B (Account 456):

```hcl
# In Account 123 (data owner)
resource "aws_s3_bucket_policy" "cross_account" {
  bucket = aws_s3_bucket.shared_data.id
  
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::456789012345:role/DataConsumer"
      }
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.shared_data.arn,
        "${aws_s3_bucket.shared_data.arn}/*"
      ]
    }]
  })
}

# Trust relationship in Account 456
resource "aws_iam_role" "data_consumer" {
  name = "DataConsumer"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  role = aws_iam_role.data_consumer.name
  
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::shared-data-bucket-123",
        "arn:aws:s3:::shared-data-bucket-123/*"
      ]
    }]
  })
}
```

**Pattern 2: Service-to-Service Communication**

Lambda function requires S3 read access only:

```hcl
resource "aws_iam_role" "lambda_s3_reader" {
  name = "lambda-s3-reader"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_s3_reader.name
  
  policy = jsonencode({
    Statement = [
      {
        Sid    = "ReadDataLake"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::data-lake",
          "arn:aws:s3:::data-lake/incoming/*"
        ]
      },
      {
        Sid    = "WriteProcessedData"
        Effect = "Allow"
        Action = "s3:PutObject"
        Resource = "arn:aws:s3:::data-lake/processed/*"
      },
      {
        Sid    = "DenyOtherBuckets"
        Effect = "Deny"
        Action = "s3:*"
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:SourceArn" = "arn:aws:s3:::data-lake*"
          }
        }
      }
    ]
  })
}
```

**Pattern 3: Multi-Tenant Isolation**

Different customers segregated by prefix:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "MultiTenantIsolation",
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789:user/customer-alice"
    },
    "Action": [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ],
    "Resource": [
      "arn:aws:s3:::multi-tenant-bucket",
      "arn:aws:s3:::multi-tenant-bucket/customer-alice/*"
    ]
  }]
}
```

#### DevOps Best Practices

**1. Principal Isolation with Separate Roles**

```hcl
# Role for data scientists (read-only)
resource "aws_iam_role" "data_scientist" {
  name = "data-scientist"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789:user/bob"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Role for data engineers (read-write)
resource "aws_iam_role" "data_engineer" {
  name = "data-engineer"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789:user/alice"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Role for data platform admin (full access)
resource "aws_iam_role" "data_admin" {
  name = "data-admin"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789:user/charlie"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
```

**2. Time-Limited Access with Session Duration**

```hcl
resource "aws_iam_role" "temporary_access" {
  name = "temporary-s3-access"
  
  assume_role_policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::123456789:user/contractor"
      }
      Action    = "sts:AssumeRole"
      Condition = {
        DateLessThan = {
          "aws:CurrentTime" = "2024-06-30T23:59:59Z"
        }
      }
    }]
  })
  
  max_session_duration = 3600  # 1 hour
}
```

**3. IP-Based Access Restrictions**

```hcl
# Only allow access from corporate network
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "restricted_to_corp_ip" {
  bucket = aws_s3_bucket.sensitive.id
  
  policy = jsonencode({
    Statement = [
      {
        Sid    = "DenyNonCorporateIP"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.sensitive.arn,
          "${aws_s3_bucket.sensitive.arn}/*"
        ]
        Condition = {
          NotIpAddress = {
            "aws:SourceIp" = [
              "203.0.113.0/24",      # Corporate network
              "198.51.100.0/24"      # VPN range
            ]
          }
        }
      }
    ]
  })
}
```

#### Common Pitfalls

**Pitfall 1: Overly Permissive Wildcard Actions**
```json
// Bad
"Action": "s3:*"

// Good
"Action": [
  "s3:GetObject",
  "s3:ListBucket"
]
```

**Pitfall 2: Forgetting aws:SecureTransport Check**
Without this, HTTPS enforcement is missing. Always include:
```json
"Condition": {
  "Bool": {
    "aws:SecureTransport": "true"
  }
}
```

**Pitfall 3: Cross-Account Access Without Principal Verification**
Cross-account scenarios require mutual trust setup:
```
Account A (data): Bucket policy allows Account B role
Account B (consumer): Role policy allows S3 access to Account A bucket
Both must align or access fails
```

---

### Practical Code Examples

#### IAM Policy for S3 Data Lake Access

**Terraform module for controlled access:**
```hcl
variable "bucket_name" {
  type = string
}

variable "team_name" {
  type = string
}

resource "aws_iam_role" "team_s3_access" {
  name = "${var.team_name}-s3-access"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "team_policy" {
  name = "${var.team_name}-s3-policy"
  role = aws_iam_role.team_s3_access.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucketRoot"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = "arn:aws:s3:::${var.bucket_name}"
        Condition = {
          StringEquals = {
            "s3:prefix" = ["${var.team_name}/"]
          }
        }
      },
      {
        Sid    = "GetObjectTeamPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/${var.team_name}/*"
      },
      {
        Sid    = "PutObjectTeamPrefix"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}/${var.team_name}/*"
      },
      {
        Sid    = "DenyUnencrypted"
        Effect = "Deny"
        Action = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.bucket_name}/${var.team_name}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "team_profile" {
  name = "${var.team_name}-profile"
  role = aws_iam_role.team_s3_access.name
}
```

**Usage:**
```hcl
module "analytics_team_access" {
  source = "./modules/s3-team-access"
  
  bucket_name = "company-data-lake"
  team_name   = "analytics"
}

module "engineering_team_access" {
  source = "./modules/s3-team-access"
  
  bucket_name = "company-data-lake"
  team_name   = "engineering"
}
```

#### Bucket Policies for Compliance

**CloudFormation for compliance enforcement:**
```yaml
Resources:
  ComplianceBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: compliance-data-prod
      VersioningConfiguration:
        Status: Enabled

  ComplianceBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref ComplianceBucket
      PolicyText:
        Version: '2012-10-17'
        Statement:
          - Sid: DenyInsecureTransport
            Effect: Deny
            Principal: '*'
            Action: 's3:*'
            Resource:
              - !GetAtt ComplianceBucket.Arn
              - !Sub '${ComplianceBucket.Arn}/*'
            Condition:
              Bool:
                'aws:SecureTransport': false

          - Sid: DenyUnencryptedObjectUploads
            Effect: Deny
            Principal: '*'
            Action: 's3:PutObject'
            Resource: !Sub '${ComplianceBucket.Arn}/*'
            Condition:
              StringNotEquals:
                's3:x-amz-server-side-encryption': AES256

          - Sid: AllowInternal
            Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action:
              - 's3:GetObject'
              - 's3:PutObject'
            Resource: !Sub '${ComplianceBucket.Arn}/*'

Outputs:
  BucketName:
    Value: !Ref ComplianceBucket
  BucketArn:
    Value: !GetAtt ComplianceBucket.Arn
```

#### Cross-Account S3 Access Script

**Bash script for testing access:**
```bash
#!/bin/bash
# Test S3 access from different accounts/roles

BUCKET_NAME="shared-data-bucket"
TEST_FILE="test-access.txt"
ROLE_ARN="arn:aws:iam::456789012345:role/DataConsumer"

# 1. Assume role
SESSION=$(aws sts assume-role \
  --role-arn "$ROLE_ARN" \
  --role-session-name "test-session" \
  --duration-seconds 900)

# Extract temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $SESSION | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $SESSION | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $SESSION | jq -r '.Credentials.SessionToken')

# 2. Test operations in assumed role
echo "Testing access with assumed role..."

# List bucket
echo "Testing ListBucket..."
aws s3 ls "$BUCKET_NAME" || echo "❌ ListBucket failed"

# Get object
echo "Testing GetObject..."
aws s3 cp "s3://$BUCKET_NAME/$TEST_FILE" "./$TEST_FILE" && echo "✓ GetObject succeeded" || echo "❌ GetObject failed"

# Try to put object (should fail if read-only)
echo "Testing PutObject..."
echo "test data" > /tmp/test.txt
aws s3 cp "/tmp/test.txt" "s3://$BUCKET_NAME/test-put.txt" && echo "✓ PutObject succeeded" || echo "❌ PutObject denied (expected if read-only)"

# 3. Cleanup
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
echo "Access testing complete"
```

#### CloudTrail Logging and Audit

**Enable CloudTrail for S3 data events:**
```hcl
resource "aws_cloudtrail" "s3_audit" {
  name                          = "s3-data-events-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/"]
    }

    data_resource {
      type   = "AWS::S3::Bucket"
      values = ["arn:aws:s3:::"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "org-cloudtrail-logs"
}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AWSCloudTrailAclCheck"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action   = "s3:GetBucketAcl"
      Resource = aws_s3_bucket.cloudtrail_logs.arn
    },
    {
      Sid    = "AWSCloudTrailWrite"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
      Condition = {
        StringEquals = {
          "s3:x-amz-acl" = "bucket-owner-full-control"
        }
      }
    }]
  })
}
```

#### Query CloudTrail Logs with Athena

```sql
-- Create table for CloudTrail logs
CREATE EXTERNAL TABLE cloudtrail_logs (
  eventVersion STRING,
  userIdentity STRUCT<
    type: STRING,
    principalId: STRING,
    arn: STRING,
    accountId: STRING,
    userName: STRING
  >,
  eventTime STRING,
  eventSource STRING,
  eventName STRING,
  awsRegion STRING,
  sourceIPAddress STRING,
  userAgent STRING,
  requestParameters STRING,
  responseElements STRING,
  additionalEventData STRING,
  requestId STRING,
  eventId STRING,
  resources ARRAY<STRUCT<arn: STRING, accountId: STRING, type: STRING>>,
  eventType STRING,
  recipientAccountId STRING,
  sharedEventID STRING,
  vpcEndpointId STRING
)
PARTITIONED BY (region STRING, year STRING, month STRING, day STRING)
ROW FORMAT SERDE 'com.amazon.emr.hive.serde.CloudTrailSerde'
STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://org-cloudtrail-logs/AWSLogs/'

-- Find all DeleteObject operations
SELECT
  eventTime,
  userIdentity.principalId,
  eventName,
  sourceIPAddress,
  requestParameters
FROM cloudtrail_logs
WHERE eventName = 'DeleteObject'
  AND eventSource = 's3.amazonaws.com'
ORDER BY eventTime DESC
LIMIT 100;

-- Find failed access attempts
SELECT
  eventTime,
  userIdentity.principalId,
  eventName,
  errorCode,
  errorMessage
FROM cloudtrail_logs
WHERE errorCode IS NOT NULL
  AND eventSource = 's3.amazonaws.com'
ORDER BY eventTime DESC;
```

---

### ASCII Diagrams

#### IAM Policy Evaluation Logic

```
S3 Request from Principal
  │
  ├─ Step 1: Authentication
  │ └─ Verify AWS credentials (SigV4)
  │    └─ If invalid: DENY (403 Forbidden)
  │
  ├─ Step 2: Principal Identification
  │ └─ Map access key to IAM entity
  │    └─ If not found: DENY
  │
  ├─ Step 3: Check for EXPLICIT DENY
  │ ├─ IAM Policy attached to principal?
  │ │ └─ Any "Deny" statement matches?
  │ ├─ Source IP-based Deny?
  │ │ └─ Request from unauthorized IP?
  │ ├─ Time-based Deny?
  │ │ └─ Request outside allowed window?
  │ └─ If explicit Deny found: STOP → DENIED (403)
  │
  ├─ Step 4: Check for Allow (Principal-Based)
  │ └─ Does IAM policy contain matching Allow?
  │    ├─ Action matches? (s3:GetObject)
  │    ├─ Resource matches? (bucket ARN)
  │    └─ Conditions satisfied? (IP, SSL)
  │
  ├─ Step 5: Check for Allow (Resource-Based)
  │ └─ Does Bucket Policy contain matching Allow?
  │    ├─ Principal matches? (account, role, user)
  │    ├─ Action matches?
  │    └─ Resource matches?
  │
  ├─ Step 6: Check ACL (Legacy)
  │ └─ Object or bucket ACL grants permission?
  │
  └─ Final Decision:
    ├─ Any explicit Deny? → DENIED
    ├─ Any Allow (IAM OR Bucket OR ACL)? → ALLOWED
    └─ No Allow found? → DENIED (default deny)
```

#### Cross-Account Access Flow

```
Account A (Data Provider)              Account B (Data Consumer)
┌─────────────────────────────┐      ┌──────────────────────────┐
│ S3 Bucket: shared-data      │      │ IAM Role: DataConsumer   │
│ ┌───────────────────────────┤      │ ┌──────────────────────┤
│ │ Bucket Policy:            │      │ │ Trust Relationship:  │
│ │ {                         │  ←──→│ │ Allow Account A root │
│ │   "Principal": {          │      │ │ to assume this role  │
│ │     "AWS":                │      │ │                      │
│ │   "arn:aws:iam::         │      │ │ Permissions Policy:  │
│ │   456789:role/           │      │ │ s3:GetObject         │
│ │   DataConsumer"           │      │ │ s3:ListBucket       │
│ │   }                       │      │ │ on Account A bucket   │
│ │ }                         │      │ │                      │
│ └───────────────────────────┘      │ └──────────────────────┘
│ Permissions:                       │ Assume Role Request:
│ ├─ Allows Account B               │ ├─ Account B instance
│ └─ To read objects                │ └─ Uses service role
│                                    │    to assume DataConsumer
└─────────────────────────────────────┴──────────────────────────┘

Workflow:
1. EC2 instance in Account B authenticated as its service role
2. Calls sts:AssumeRole → DataConsumer role in Account B
3. DataConsumer trust relationship verified (Account A root)
4. EC2 obtains temporary credentials for DataConsumer role
5. EC2 calls s3:GetObject on Account A bucket
6. Bucket policy evaluates: Principal = Account B's DataConsumer role
7. Matches bucket policy principal → ALLOW
8. DataConsumer role policy allows s3:GetObject → ALLOW
9. Object returned to Account B
```

---

## S3 Event Notifications

### Textual Deep Dive

#### Internal Working Mechanism

S3 event notifications trigger when specific actions occur on objects:

```
Timeline: Object PUT triggering notifications

1. Client: PUT /my-bucket/incoming/file.csv
        ↓
2. S3 API: Write object, update metadata
        ↓
3. Replication: Sync to additional AZs
        ↓
4. Event Generated: ObjectCreated:Put event created
   {
     "eventVersion": "2.0",
     "eventSource": "aws:s3",
     "awsRegion": "us-east-1",
     "eventTime": "2024-03-15T14:32:01.123Z",
     "eventName": "ObjectCreated:Put",
     "s3": {
       "bucket": {"name": "my-bucket"},
       "object": {"key": "incoming/file.csv", "size": 102400}
     }
   }
        ↓
5. Event Router: Evaluates notification rules
   ├─ Is notification enabled? ✓
   ├─ Does filter match (prefix/suffix)? ✓
   └─ Is destination ready? ✓
        ↓
6. Notification Delivery
   ├─ SNS: Publish to topic (async, ~1-2 seconds)
   ├─ SQS: Send message to queue (async, ~1-5 seconds)
   └─ Lambda: Invoke function (async, cold start 1-30 seconds)
        ↓
7. Destination processes event
   └─ Lambda: Validate file, trigger ETL pipeline
```

**Critical architecture insight**: Notifications are delivered **at-least-once**, not exactly-once. Applications must be idempotent. If Lambda processes an event twice, it shouldn't corrupt state.

#### Event Notification Types

```
Object-Level Events:
├─ ObjectCreated:Put
│  └─ Direct upload: curl -X PUT -d @file.csv s3://bucket/key
├─ ObjectCreated:Post
│  └─ HTML form upload
├─ ObjectCreated:Copy
│  └─ S3 copy operation
├─ ObjectCreated:CompleteMultipartUpload
│  └─ Multipart upload completed
├─ ObjectRemoved:Delete
│  └─ DELETE request (not delete marker in versioned bucket)
├─ ObjectRemoved:DeleteMarkerCreated
│  └─ DELETE in versioned bucket (creates delete marker)
└─ ObjectRestore:Completed
   └─ Restore from GLACIER/DEEP_ARCHIVE

Object Tagging and ACL Events:
├─ ObjectTagging:Put
├─ ObjectTagging:Delete
├─ ObjectAcl:Put

Replication Events:
├─ Replication:OperationFailedReplication
│  └─ CRR failed (network issues, permissions)
├─ Replication:OperationNotTracked
│  └─ CRR not configured for this object
└─ Replication:OperationMissedThreshold
   └─ CRR exceeded RTC threshold (>15 mins)

S3 Lifecycle Events:
└─ LifecycleTransition
   └─ Object transitioned to different storage class
```

#### Destination Options and Trade-offs

```
SNS (Simple Notification Service):
├─ Latency: 1-2 seconds
├─ Fanout: One event → Multiple subscribers
├─ Durability: SNS queue (temporary storage)
├─ Use case: Broadcast events to multiple systems
├─ Cost: Low (~$0.50 per million events)
├─ Retry: SNS handles retries to endpoints
└─ Limitation: No guarantee of delivery order

SQS (Simple Queue Service):
├─ Latency: 1-5 seconds
├─ Fanout: Single FIFO or Standard queue
├─ Durability: SQS message store
├─ Use case: Decouple S3 from processing
├─ Cost: Medium (~$0.40 per million requests)
├─ Retry: Consumer responsibility
└─ Benefit: Order preservation (FIFO), visibility timeout

Lambda (Direct Invocation):
├─ Latency: 10-30 seconds (cold start)
├─ Fanout: Single Lambda function
├─ Durability: AWS manages retries
├─ Use case: Real-time processing, quick actions
├─ Cost: Pay per invocation (pay for compute)
├─ Retry: Automatic (2x), configurable deadletter
└─ Limitation: Lambda concurrency limits
```

#### Architecture Role: Event-Driven Data Pipeline

Event notifications enable serverless data pipelines:

```
S3 Event Notifications → Data Pipeline
    ↓
1. File lands in "incoming" bucket
2. S3 triggers Lambda function
3. Lambda: validate schema, parse CSV
4. Lambda: Post to SNS for failures
5. Lambda: PUT processed file in "processed" bucket
6. Processed bucket triggers Glue job
7. Glue: Partition data, update Athena catalog
8. Analysts query via Athena
```

This is **event-driven architecture**: real-time processing without polling.

#### Production Usage Patterns

**Pattern 1: Log Processing Pipeline**

```
CloudFront logs → S3 bucket (s3://logs/)
    ↓ (S3 event notification)
Lambda function (triggered)
    ├─ Parse log file
    ├─ Aggregate statistics
    ├─ Put summary to DynamoDB
    └─ Put processed log to s3://logs-processed/
```

**Pattern 2: Multi-Region Data Sync**

```
Application → PUT file in s3://us-east-1/
    ↓ (ObjectCreated event)
Lambda (us-east-1)
    ├─ Validate file
    └─ Replicate to s3://eu-west-1/
        ↓
        SNS notification to Slack: "File synced"
```

**Pattern 3: Image Processing Farm**

```
User uploads image → s3://images/uploads/
    ↓ (ObjectCreated event)
SQS queue (accumulates image keys)
    ↓
Lambda (scales automatically, up to 1000 concurrent)
    ├─ Download image from S3
    ├─ Resize, thumbnail, optimize
    └─ Upload to s3://images/processed/
        ↓
        DynamoDB: Update image metadata
        ↓ (CloudFront caches)
User can access via CDN
```

#### DevOps Best Practices

**1. Filter Events by Prefix/Suffix**

```hcl
resource "aws_s3_bucket_notification" "filtered" {
  bucket = aws_s3_bucket.data.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process.arn
    # Only trigger for CSV files in incoming/ prefix
    filter_prefix       = "incoming/"
    filter_suffix       = ".csv"
    events              = ["s3:ObjectCreated:*"]
  }

  sns_topic {
    # Different notification for errors
    filter_prefix = "errors/"
    events        = ["s3:ObjectRemoved:*"]
    topic_arn     = aws_sns_topic.alerts.arn
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data.arn
}
```

**2. Implement Idempotency**

```python
import json
import hashlib
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('event-idempotency')

def lambda_handler(event, context):
    """Process S3 event idempotently"""
    
    # Extract event details
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    event_id = event['Records'][0]['eventID']
    
    # Create unique identifier for this event
    idempotency_key = f"{bucket}#{key}#{event_id}"
    
    try:
        # Check if we've processed this event before
        response = table.get_item(Key={'eventID': idempotency_key})
        
        if 'Item' in response:
            print(f"Event already processed: {idempotency_key}")
            return {'statusCode': 200, 'message': 'Duplicate event ignored'}
        
        # Process the event
        print(f"Processing new event: {idempotency_key}")
        process_file(bucket, key)
        
        # Record that we've processed this event
        table.put_item(
            Item={
                'eventID': idempotency_key,
                'timestamp': int(time.time()),
                'status': 'completed'
            }
        )
        
        return {'statusCode': 200, 'message': 'Success'}
        
    except Exception as e:
        print(f"Error processing event: {str(e)}")
        return {'statusCode': 500, 'error': str(e)}

def process_file(bucket, key):
    s3 = boto3.client('s3')
    # Download and process file
    pass
```

**3. Dead Letter Queue for Failed Events**

```hcl
resource "aws_sqs_queue" "dlq" {
  name                      = "s3-events-dlq"
  message_retention_seconds = 1209600  # 14 days
}

resource "aws_lambda_function" "process_s3_event" {
  filename            = "lambda_function.zip"
  function_name       = "process-s3-event"
  role                = aws_iam_role.lambda_role.arn
  handler             = "index.handler"
  timeout             = 60
  memory_size         = 512

  environment {
    variables = {
      DLQ_URL = aws_sqs_queue.dlq.url
    }
  }
}

resource "aws_lambda_event_source_mapping" "s3_to_lambda" {
  event_source_arn  = aws_sqs_queue.events.arn
  function_name     = aws_lambda_function.process_s3_event.function_name
  batch_size        = 10
  function_response_types = ["ReportBatchItemFailures"]
}
```

#### Common Pitfalls

**Pitfall 1: Assuming Exactly-Once Delivery**
S3 guarantees **at-least-once**. Duplicates are possible. Always implement idempotency.

**Pitfall 2: Lambda Timeout Too Short**
Default 3 seconds is too short for S3 processing. Set to 30-60 seconds minimum.

**Pitfall 3: Not Handling Large Files**
If a 5GB file triggers Lambda, it can't download in time. Use S3 range requests or skip large files.

```python
# Filter by size
def lambda_handler(event, context):
    size = event['Records'][0]['s3']['object']['size']
    if size > 500 * 1024 * 1024:  # 500MB
        print("File too large, skipping")
        return
    # process file
```

**Pitfall 4: Circular Notifications**
Lambda processes file, uploads to same bucket → Lambda triggered again → Infinite loop.

```hcl
# Solution: Upload to different bucket
resource "aws_s3_bucket_notification" "safe" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    events       = ["s3:ObjectCreated:*"]
    lambda_function_arn = aws_lambda_function.process.arn
    filter_prefix = "input/"
  }
}

# Lambda outputs to different bucket to avoid trigger
# s3://input/file.csv → Lambda → s3://processed/file.csv
```

---

### Practical Code Examples

#### S3 → Lambda → SQS Pipeline

**Lambda function:**
```python
import json
import boto3
import logging

s3 = boto3.client('s3')
sqs = boto3.client('sqs')
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Process S3 events, validate, and enqueue for further processing
    """
    
    queue_url = os.environ['QUEUE_URL']
    results = []
    
    for record in event['Records']:
        try:
            bucket = record['s3']['bucket']['name']
            key = record['s3']['object']['key']
            size = record['s3']['object']['size']
            
            logger.info(f"Processing s3://{bucket}/{key} (size: {size})")
            
            # Validate: Check file size
            if size == 0:
                logger.warning(f"Skipping empty file: {key}")
                continue
            
            if size > 1024 * 1024 * 1024:  # 1GB limit
                logger.error(f"File too large: {key} ({size} bytes)")
                continue
            
            # Validate: Check file type
            if not key.endswith('.csv'):
                logger.warning(f"Skipping non-CSV file: {key}")
                continue
            
            # Send to SQS for processing
            message = {
                'bucket': bucket,
                'key': key,
                'size': size,
                'timestamp': record['eventTime'],
                'eventID': record['eventID']
            }
            
            response = sqs.send_message(
                QueueUrl=queue_url,
                MessageBody=json.dumps(message),
                MessageAttributes={
                    'bucket': {'StringValue': bucket, 'DataType': 'String'},
                    'filesize': {'StringValue': str(size), 'DataType': 'Number'}
                }
            )
            
            results.append({
                'key': key,
                'status': 'queued',
                'messageId': response['MessageId']
            })
            
        except Exception as e:
            logger.exception(f"Error processing record: {str(e)}")
            results.append({
                'key': key,
                'status': 'error',
                'error': str(e)
            })
    
    return {
        'statusCode': 200,
        'body': json.dumps({'processed': results})
    }
```

**Terraform configuration:**
```hcl
resource "aws_sqs_queue" "s3_events" {
  name                      = "s3-process-queue"
  message_retention_seconds = 604800  # 7 days
  
  tags = {
    Environment = "production"
  }
}

resource "aws_lambda_function" "s3_event_processor" {
  filename            = "lambda_function.zip"
  function_name       = "s3-event-processor"
  role                = aws_iam_role.lambda_exec.arn
  handler             = "index.lambda_handler"
  source_code_hash    = filebase64sha256("lambda_function.zip")
  timeout             = 60
  memory_size         = 256

  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.s3_events.url
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "s3-lambda-exec"

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

resource "aws_iam_role_policy" "lambda_policy" {
  name = "s3-lambda-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::input-bucket/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.s3_events.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "input" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_event_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "incoming/"
    filter_suffix       = ".csv"
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_event_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn
}
```

#### Multi-Region Event Forwarding

**SNS fanout for multi-region notification:**
```hcl
resource "aws_sns_topic" "s3_events" {
  name = "s3-events-global"
  
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_policy" "allow_s3" {
  arn = aws_sns_topic.s3_events.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.s3_events.arn
    }]
  })
}

resource "aws_s3_bucket_notification" "events" {
  bucket = aws_s3_bucket.data.id

  topic {
    topic_arn     = aws_sns_topic.s3_events.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix = "data/"
  }
}

# Multiple subscribers across regions
resource "aws_sns_topic_subscription" "us_lambda" {
  topic_arn            = aws_sns_topic.s3_events.arn
  protocol             = "lambda"
  endpoint             = aws_lambda_function.us_processor.arn
  filter_policy        = jsonencode({"eventName": ["ObjectCreated:Put"]})
}

resource "aws_sns_topic_subscription" "eu_lambda" {
  topic_arn = aws_sns_topic.s3_events.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.eu_processor.arn
}

resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.s3_events.arn
  protocol  = "https"
  endpoint  = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  
  filter_policy = jsonencode({
    eventName: ["ObjectRemoved:Delete"],
    s3 = {
      object = {
        size: [{"numeric": [">", 1000000000]}]  # >1GB
      }
    }
  })
}
```

#### CloudWatch Rule for Scheduled S3 Tasks

**Alternative to event notifications: Scheduled processing:**
```hcl
resource "aws_cloudwatch_event_rule" "daily_s3_scan" {
  name                = "daily-s3-scan"
  description         = "Scan S3 daily for processing"
  schedule_expression = "cron(0 2 * * ? *)"  # 2 AM UTC daily
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_s3_scan.name
  target_id = "DailyScanLambda"
  arn       = aws_lambda_function.s3_scanner.arn

  input = jsonencode({
    bucket = "my-bucket"
    prefix = "unprocessed/"
  })
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_scanner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_s3_scan.arn
}
```

---

### ASCII Diagrams

#### Event Notification Flow

```
User uploads file to S3
        │
        ├─ PUT /my-bucket/incoming/data.csv
        └─ 200 OK (object replicated to 3+ AZs)

S3 Event Engine
        │
        ├─ Detect: ObjectCreated:Put event
        ├─ Check: Notification rules
        │  ├─ Prefix "incoming/"? ✓
        │  ├─ Suffix ".csv"? ✓
        │  └─ Notification enabled? ✓
        │
        ├─ Create event JSON
        │  │{
        │  │  "Records": [{
        │  │    "eventName": "ObjectCreated:Put",
        │  │    "s3": {
        │  │      "bucket": {"name": "my-bucket"},
        │  │      "object": {"key": "incoming/data.csv", "size": 102400}
        │  │    },
        │  │    "eventID": "abc123xyz"
        │  │  }]
        │  │}
        │
        └─ Route to destinations (async, parallel)

    ┌─────────────────────────────────────┬──────────┐
    │                                     │          │
    ▼ (SQS)                              ▼ (Lambda) │ (SNS)
Queue                             Function          Topic
  │                                 │               │
  ├─ Message stored                 ├─ Invoked      ├─ Published
  ├─ Visibility timeout 30s          ├─ Executes    ├─ Fanned out to:
  ├─ Retry up to 4 times            ├─ Processes   │  ├─ Slack
  └─ DLQ if all fails               └─ Returns    │  ├─ Email
                                               │  └─ SQS
                                               └─ CloudWatch Logs

Consumer processes                Processing complete
  │                         
  ├─ Delete message         Monitoring
  ├─ Handle failures        ├─ CloudWatch metrics
  └─ Update DynamoDB        │  ├─ Events delivered
                            │  ├─ Lambda errors
                            │  └─ SQS queue depth
                            └─ CloudTrail logs
```

#### Event-Driven Pipeline

```
Data Ingestion Pipeline Using S3 Events

┌────────────────────────────────────────────────────────────┐
│                                                            │
│  1. Data Source                                           │
│  └─ User/API uploads file to s3://bucket/incoming/      │
│                                                            │
└────────────────────────────────────────────────────────────┘
                          │
                          │ S3 event triggered: ObjectCreated
                          ▼
┌────────────────────────────────────────────────────────────┐
│ 2. Validation Layer (Lambda)                              │
│  ├─ Schema validation                                      │
│  ├─ Duplicate detection (idempotency key)                 │
│  ├─ Size checks                                            │
│  └─ Route to:                                              │
│     ├─ SQS (valid) → processing queue                     │
│     └─ SNS error topic (invalid)                          │
└────────────────────────────────────────────────────────────┘
                          │
                          ├─── (Valid) ──→ SQS Queue
                          │                   │
                          │                   ▼
                          │              ┌──────────────────┐
                          │              │ 3. Processing    │
                          │              │ (Consumer Lambda)│
                          │              │ ├─ Parse CSV     │
                          │              │ ├─ Transform     │
                          │              │ └─ Aggregate     │
                          │              └──────────────────┘
                          │                   │
                          │                   ▼
                          │              ┌──────────────────┐
                          │              │ 4. Output        │
                          │              │ PUT processed/   │
                          │              │ Upsert DynamoDB  │
                          │              └──────────────────┘
                          │                   │
                          │                   ▼
                          │              ┌──────────────────┐
                          │              │ 5. Query Layer   │
                          │              │ Athena, Analytics│
                          │              └──────────────────┘
                          │
                          └─── (Invalid) → SNS Error Topic
                                            │
                                            ▼
                                        ┌─────────────────┐
                                        │ Alert (Slack)  │
                                        │ CloudWatch     │
                                        │ Event Log      │
                                        └─────────────────┘

Key Characteristics:
├─ Real-time: Events processed within seconds
├─ Scalable: Lambda scales automatically
├─ Resilient: SQS buffers spikes, DLQ catches failures
├─ Observable: CloudWatch monitors all stages
└─ Cost-effective: Pay only for invocations + compute
```

---

## EBS & EFS

### Textual Deep Dive

#### EBS: Block Storage Architecture

Elastic Block Store provides block-level (not object-level) storage attached to EC2 instances. Unlike S3's distributed object model, EBS provides raw block access requiring a filesystem:

```
┌──────────────────────────────────┐
│ EC2 Instance                     │
│ ┌──────────────────────────────┐ │
│ │ OS (Linux, Windows)          │ │
│ │ ┌──────────────────────────┐ │ │
│ │ │ Filesystem (ext4, xfs)   │ │ │
│ │ │ ├─ /data/file.txt        │ │ │
│ │ │ ├─ /var/log/app.log      │ │ │
│ │ │ └─ /home/user/data       │ │ │
│ │ └──────────────────────────┘ │ │
│ │          ↓ (read/write)        │ │
│ │ ┌──────────────────────────┐ │ │
│ │ │ Block Device Mapping     │ │ │
│ │ │ /dev/xvda (root)         │ │ │
│ │ │ /dev/xvdf (attached)     │ │ │
│ │ └──────────────────────────┘ │ │
│ └──────────────────────────────┘ │
│            ↓ (block I/O)          │
│ ┌──────────────────────────────┐ │
│ │ Network Interface (ENI)      │ │
│ │ Communicates with EBS service│ │
│ └──────────────────────────────┘ │
└──────────────────────────────────┘
            ↓ (iSCSI over network)
┌──────────────────────────────────────┐
│ EBS Subsystem (NOT in instance)      │
│ ┌──────────────────────────────────┐ │
│ │ EBS Volume                       │ │
│ │ ├─ Stored in EBS Subsystem       │ │
│ │ ├─ Replicated across 3+ AZs      │ │
│ │ ├─ Snapshot capability (to S3)   │ │
│ │ └─ Encrypted with KMS            │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**Key characteristic**: EBS is for single-instance block access. If you want multiple instances to share storage, use EFS instead.

#### EBS Volume Types and Performance

```
Volume Type           IOPS            Throughput      Use Case
─────────────────────────────────────────────────────────────
gp3               16,000 baseline    1,000 MB/s      General purpose
(General Purpose) 64,000 max         4,000 MB/s      Fast provisioning
                  configurable                       Web servers

gp2               100-3,200 burst    125-250 MB/s    Previous gen
(General Purpose) (based on volume)                  Legacy apps

io2               64,000-256,000     1,000-4,000 MB/s Databases
(High IOPS)       (provisioned)      MB/s            Critical apps
                  99.99% durability                  Multi-attach option

io1               32,000 max         500 MB/s        High-performance
(High IOPS)       (provisioned)                      DBs (older)

st1               250-500 burst      125-250 MB/s    Big data
(Throughput       (based on volume)  MB/s            Sequential I/O
 Optimized)       12,500 max

sc1               250-3,000 burst    40-90 MB/s      Cold storage
(Cold storage)    (based on volume)  MB/s            Infrequent access

magnetic          40-200 burst       40-90 MB/s      Very old apps
(Legacy)          (based on volume)  MB/s            Deprecated
```

**IOPS explanation:**
- 1 IOPS = 1 I/O operation per second
- Read: 256 KB or smaller
- Write: 256 KB or smaller
- Larger I/Os consume multiple IOPS

**gp3 vs gp2:**
```
gp3 (Newer):
├─ Baseline 3,000 IOPS + 125 MB/s (included)
├─ Can provision up to 16,000 IOPS independently
├─ Can provision up to 1,000 MB/s independently
└─ Better value for most workloads

gp2 (Legacy):
├─ IOPS = 3 × volume size (GB)
├─ 1 GB → 3 IOPS baseline, burst to 3,000
├─ 500 GB → 1,500 IOPS, burst to 3,000
└─ IOPS and throughput linked (can't separate)
```

#### EBS Snapshots and Disaster Recovery

Snapshots are point-in-time copies of volumes stored in S3:

```
Timeline: EBS Volume Lifecycle with Snapshots

Day 1:
EC2 instance with 100GB volume
├─ Snapshot-1 created
│  └─ Full copy of volume → S3 (~50GB actual, compression)
│  └─ Cost: ~$5/month

Day 30:
├─ More data written (50GB new)
├─ Snapshot-2 created
│  └─ Incremental snapshot (only changed blocks)
│  └─ S3 stores: Snapshot-1 (full) + Snapshot-2 (60GB delta)
│  └─ Cost: +$3/month

Day 60:
├─ Database corruption detected
├─ Restore from Snapshot-1
│  └─ Create new volume from snapshot
│  └─ Attach to new EC2 instance
│  └─ Lost 30 days of data (acceptable RTO/RPO trade-off)
│
└─ Or restore from Snapshot-2
   └─ Only lost 30 days
```

**Snapshot lifecycle:**
```
Snapshots older than 30 days → Archive to S3 (cheaper tier)
Snapshots older than 1 year → Delete (compliance retention met)
```

#### EFS: Shared Network File System

EFS (Elastic File System) is different from EBS—it's NFS (Network File System) providing concurrent access:

```
┌────────────────────────────────────────────────┐
│ VPC with EFS                                   │
├────────────────────────────────────────────────┤
│                                                │
│ ┌──────────────┐       ┌──────────────┐       │
│ │ EC2 (us-1a) │       │ EC2 (us-1b) │       │
│ │ ┌──────────┐│       │┌──────────┐ │       │
│ │ │ Mount at ││       ││ Mount at  │ │       │
│ │ │/mnt/efs  ││◄─────►││ /mnt/efs  │ │       │
│ │ └──────────┘│ NFS   │└──────────┘ │       │
│ └──────────────┘       └──────────────┘       │
│        ↑                       ↑               │
│        │                       │               │
│ ┌──────┴───────────────────────┴───────────┐ │
│ │ EFS Mount Targets (ENI per AZ)           │ │
│ │ ├─ Mount Target (us-1a)                  │ │
│ │ ├─ Mount Target (us-1b)                  │ │
│ │ ├─ Mount Target (us-1c)                  │ │
│ │ └─ All point to same filesystem          │ │
│ └──────────────────────────────────────────┘ │
│             ↓ (NFS metadata)                  │
│ ┌──────────────────────────────────────────┐ │
│ │ EFS Elastic Metadata (Managed by AWS)    │ │
│ │ ├─ Inode table                           │ │
│ │ ├─ Directory entries                     │ │
│ │ ├─ Permissions (POSIX)                   │ │
│ │ └─ Auto-scales (no provisioning)         │ │
│ └──────────────────────────────────────────┘ │
│             ↓ (Data storage)                  │
│ ┌──────────────────────────────────────────┐ │
│ │ EFS Data (Fully Managed)                 │ │
│ │ ├─ Replicated across AZs                 │ │
│ │ ├─ Automatic replication                 │ │
│ │ ├─ Encrypted with KMS                    │ │
│ │ └─ No capacity planning needed            │ │
│ └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
```

**EBS vs EFS comparison:**

```
                    EBS                    EFS
Access              Single instance        Multiple instances
Filesystem          Must create (ext4)     NFS built-in
Replication         3+ AZs (automatic)     3+ AZs (automatic)
Capacity            Fixed (provision)      Elastic (grows)
Performance         Low latency (1-3ms)    Higher latency (5-10ms)
Cost                ~$0.10/GB/month        ~$0.30/GB/month (3x more)
Snapshots           Yes (to S3)            No (EFS backup service)
Multi-AZ            Same region only       Same region only
Use Case            Databases, OSes        Shared storage, containers
```

#### Architecture Role: Persistent Storage for Stateful Apps

EBS/EFS enable stateful applications in cloud:

```
Traditional On-Premises:
Database Server → SAN Storage
     ↓
    Expensive, power-hungry

AWS Cloud:
EC2 Instance → EBS Volume
     ↓
    Cheaper, automated backups, snapshots
    
Kubernetes:
Pod → EBS (single-AZ) or EFS (multi-AZ)
     ↓
    StatefulSets require persistent storage
    EFS enables concurrent access
```

#### Production Usage Patterns

**Pattern 1: Database Server with EBS**

```
RDS alternative (self-managed):
├─ EC2 instance (c6i.xlarge)
├─ EBS gp3 volume (2TB, 8,000 IOPS)
├─ Daily snapshots → S3
├─ Standby instance in different AZ
└─ Costs less than RDS if licenses are owned
```

**Pattern 2: Kubernetes StatefulSet with EFS**

```
StatefulSet: PostgreSQL cluster
├─ Pod-0 → EFS /postgres/pod-0
├─ Pod-1 → EFS /postgres/pod-1
├─ Pod-2 → EFS /postgres/pod-2
└─ All pods access shared configuration from /postgres/config
```

**Pattern 3: Lambda with EFS**

```
Lambda function needs file system
├─ /tmp (512 MB ephemeral, per execution)
├─ Too small for ML models?
└─ Use EFS mount: 500,000x more storage

Lambda → EFS → Mount model files → Runtime access
```

#### DevOps Best Practices

**1. Automated Snapshots with Lifecycle Policies**

```hcl
resource "aws_ebs_snapshot_schedule" "daily" {
  description        = "Daily snapshots, retention 30 days"
  copy_tags          = true
  create_rule {
    interval      = 24
    interval_unit = "HOURS"
    times         = ["03:00"]
  }
  
  retain_rule {
    count = 30
  }
  
  tags = {
    Name = "daily-snapshot"
  }
}
```

**2. EFS for Container Persistence**

```hcl
resource "aws_efs_file_system" "app_data" {
  creation_token   = "app-data-efs"
  encrypted        = true
  kms_key_id       = aws_kms_key.ebs.arn
  
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "app-shared-storage"
  }
}

resource "aws_efs_mount_target" "app_data" {
  for_each            = toset(data.aws_availability_zones.available.names)
  file_system_id      = aws_efs_file_system.app_data.id
  subnet_id           = aws_subnet.app[each.value].id
  security_groups     = [aws_security_group.efs.id]
}
```

**3. Volume Encryption by Default**

```hcl
resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "example" {
  kms_key_id = aws_kms_key.ebs.arn
}

resource "aws_ebs_volume" "encrypted" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn
  
  tags = {
    Name = "encrypted-volume"
  }
}
```

#### Common Pitfalls

**Pitfall 1: Using EFS When EBS Is Sufficient**
EFS is 3x more expensive. Only use for multi-instance shared access.

**Pitfall 2: gp2 for New Projects**
gp3 is cheaper and faster for same IOPS. Migrate from gp2 to gp3.

**Pitfall 3: Not Encrypting Snapshots**
Snapshots of unencrypted volumes are unencrypted. Encrypt at source.

**Pitfall 4: Lambda /tmp Not Persisted**
Lambda /tmp is lost between invocations. Use EFS for persistent state.

---

### Practical Code Examples

#### EBS Volume Creation and Attachment

**Terraform:**
```hcl
resource "aws_ebs_volume" "database" {
  availability_zone           = "us-east-1a"
  size                        = 500
  encrypted                   = true
  kms_key_id                  = aws_kms_key.ebs.arn
  type                        = "gp3"
  iops                        = 8000
  throughput                  = 500
  
  tags = {
    Name        = "db-volume"
    Environment = "production"
  }
}

resource "aws_volume_attachment" "db_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.database.id
  instance_id = aws_instance.db_server.id
  
  # Ensure volume is available before attaching
  depends_on = [aws_instance.db_server]
}

resource "aws_instance" "db_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c6i.xlarge"
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    encrypt               = true
    delete_on_termination = true
  }
  
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Wait for volume to be available
    while [ ! -e /dev/xvdf ]; do sleep 1; done
    
    # Format and mount volume
    mkfs.ext4 /dev/xvdf
    mkdir -p /mnt/database
    mount /dev/xvdf /mnt/database
    
    # Persistent mount
    echo "/dev/xvdf /mnt/database ext4 defaults,nofail 0 2" >> /etc/fstab
  EOF
  )
}
```

#### EBS Snapshot Management

**CloudFormation for backup lifecycle:**
```yaml
Resources:
  DatabaseVolume:
    Type: AWS::EC2::Volume
    Properties:
      Size: 500
      VolumeType: gp3
      Iops: 8000
      Throughput: 500
      AvailabilityZone: !Select [0, !GetAZs '']
      Encrypted: true
      KmsKeyId: !GetAtt EBSKey.Arn
      Tags:
        - Key: Name
          Value: db-volume

  SnapshotSchedule:
    Type: AWS::DLM::LifecyclePolicy
    Properties:
      Description: Daily snapshots with 30-day retention
      State: ENABLED
      PolicyDetails:
        ResourceTypes:
          - VOLUME
        TargetTags:
          - Key: backup
            Value: 'true'
        Schedules:
          - Name: Daily
            CreateRule:
              Interval: 24
              IntervalUnit: HOURS
              Times:
                - '03:00'
            RetainRule:
              Count: 30
            TagsToAdd:
              - Key: AutoSnapshot
                Value: 'true'
            CopyTags: true
```

#### EFS for Kubernetes

**Terraform for EKS with EFS:**
```hcl
resource "aws_efs_file_system" "eks" {
  creation_token = "eks-efs"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  
  tags = {
    Name = "eks-persistent-storage"
  }
}

resource "aws_efs_mount_target" "eks" {
  for_each            = { for subnet in aws_subnet.private : subnet.availability_zone => subnet.id }
  file_system_id      = aws_efs_file_system.eks.id
  subnet_id           = each.value
  security_groups     = [aws_security_group.efs.id]
}

# Kubernetes StorageClass
resource "kubernetes_storage_class" "efs" {
  depends_on = [aws_efs_file_system.eks]
  
  metadata {
    name = "efs-sc"
  }
  
  storage_provisioner = "efs.csi.aws.com"
  allow_volume_expansion = true
  
  parameters = {
    provisioningMode = "efs"
    fileSystemId     = aws_efs_file_system.eks.id
    basePath         = "/data"
  }
}

# PersistentVolumeClaim example
resource "kubernetes_persistent_volume_claim" "app_data" {
  metadata {
    name = "app-data-pvc"
  }
  
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.efs.metadata[0].name
    
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}
```

#### EBS Volume Monitoring

**CloudWatch monitoring and alerting:**
```hcl
resource "aws_cloudwatch_metric_alarm" "high_read_latency" {
  alarm_name          = "ebs-volume-read-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "VolumeReadLatency"
  namespace           = "AWS/EBS"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"  # milliseconds
  alarm_description   = "Alert when read latency > 10ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    VolumeId = aws_ebs_volume.database.id
  }
}

resource "aws_cloudwatch_metric_alarm" "high_iops_usage" {
  alarm_name          = "ebs-volume-iops-usage-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "5"
  metric_name         = "VolumeConsumedReadWriteOps"
  namespace           = "AWS/EBS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "6400"  # 80% of 8000 IOPS
  alarm_description   = "Alert when IOPS usage > 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    VolumeId = aws_ebs_volume.database.id
  }
}
```

#### Lambda with EFS Access

**Terraform Lambda + EFS:**
```hcl
resource "aws_lambda_function" "model_inference" {
  filename      = "lambda_function.zip"
  function_name = "ml-inference"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  timeout       = 60
  memory_size   = 3008  # Up to 10GB RAM for Lambda
  
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }
  
  file_system_config {
    arn              = aws_efs_access_point.model_storage.arn
    local_mount_path = "/mnt/model"
  }
}

resource "aws_efs_access_point" "model_storage" {
  file_system_id = aws_efs_file_system.models.id
  
  posix_user_configuration {
    gid            = 1000
    uid            = 1000
    secondary_gids = [1001]
  }
  
  root_directory {
    path = "/lambda-models"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
}
```

---

### ASCII Diagrams

#### EBS Volume Attachment and Mounting

```
EC2 Instance (i-12ab34cd)
┌─────────────────────────────────────┐
│ Operating System                    │
│ ┌─────────────────────────────────┐ │
│ │ Kernel (Linux)                  │ │
│ │ ├─ Block device driver          │ │
│ │ ├─ Filesystem driver (ext4)     │ │
│ │ └─ VFS (Virtual File System)    │ │
│ └─────────────────────────────────┘ │
│          │                           │
│          └─ Mount point: /mnt/data   │
│             Directory entry in       │
│             root filesystem          │
│                                      │
│ Application Data:                   │
│ /mnt/data/                          │
│  ├─ database/                       │
│  ├─ logs/                           │
│  └─ cache/                          │
│                                      │
└─────────────────────────────────────┘
            │ (iSCSI protocol)
            │ Block I/O requests (READ/WRITE)
            ▼
        Network (ENI)
            │
            │ Encrypted iSCSI traffic
            ▼
EBS Service (us-east-1a)
┌─────────────────────────────────────┐
│ EBS Volume (vol-abc123xyz)          │
│ Type: gp3                           │
│ Size: 500 GB                        │
│ IOPS: 8,000 baseline               │
│ Throughput: 500 MB/s               │
│ Encryption: KMS (production-key)   │
│                                     │
│ Storage Backend:                    │
│ ├─ AZ-1a: Copy 1 (primary)        │
│ ├─ AZ-1b: Copy 2 (replication)    │
│ └─ AZ-1c: Copy 3 (replication)    │
│                                     │
│ Snapshot History:                   │
│ ├─ snap-001 (2024-03-01)           │
│ ├─ snap-002 (2024-03-02)           │
│ └─ snap-003 (2024-03-15) [current] │
└─────────────────────────────────────┘
```

#### EFS Multi-Instance Access

```
EFS Shared Filesystem:
          efs-a1b2c3d4
┌──────────────────────────────────┐
│ Mount Targets (ENI per AZ)       │
│                                  │
│ AZ-1a:                           │
│ ├─ Private IP: 10.0.1.15         │
│ ├─ Security Group: allow NFS     │
│ └─ Status: Available             │
│                                  │
│ AZ-1b:                           │
│ ├─ Private IP: 10.0.2.42         │
│ └─ Status: Available             │
│                                  │
│ AZ-1c:                           │
│ ├─ Private IP: 10.0.3.28         │
│ └─ Status: Available             │
└──────────────────────────────────┘
       ▲          ▲          ▲
       │          │          │
    (NFS)      (NFS)      (NFS)
       │          │          │
    ┌──┴──┐    ┌──┴──┐    ┌──┴──┐
    │     │    │     │    │     │
    │EC2-1│    │EC2-2│    │EC2-3│
    │(1a) │    │(1b) │    │(1c) │
    │     │    │     │    │     │
    └─────┘    └─────┘    └─────┘
      ▲           ▲          ▲
      │           │          │
   Mount at    Mount at   Mount at
   /mnt/efs    /mnt/efs   /mnt/efs

Concurrent Access:
├─ EC2-1: CREATE /file.txt
├─ EC2-2: READ /file.txt (immediate visibility)
├─ EC2-3: LIST directory (sees all files)
└─ All instance can write simultaneously
   (POSIX locking ensures consistency)

Network Path per Request:
1. EC2-1 in AZ-1a
2. Talks to nearest mount target (10.0.1.15)
3. Uses VPC private network (no NAT)
4. NFS metadata server responds immediately
5. Data flows directly (no bottleneck)
```

---

## 5. Hands-on Scenarios

### Scenario 1: Cross-Region S3 Replication for Disaster Recovery

**Problem Statement:**
A financial services company has a critical payment processing system that stores transaction logs in S3. A regional outage in us-east-1 caused 6 hours of data unavailability, resulting in significant revenue loss. The team needs to implement a disaster recovery solution that ensures data availability across regions and can failover automatically.

**Architecture Context:**
- Primary region: us-east-1 (production workloads)
- Secondary region: us-west-2 (DR site)
- RTO: 30 minutes | RPO: 15 minutes
- Data size: ~500 GB with 10,000 daily writes
- Multiple applications consuming data via cross-region read replicas

**Step-by-Step Implementation:**

1. **S3 Bucket Replication Setup:**
   - Enable Versioning on both source (us-east-1) and destination (us-west-2) buckets
   - Create Replication Rule with IAM role allowing s3:GetReplicationConfiguration, s3:ListBucket, s3:GetObjectVersionForReplication
   - Enable RTC (Replication Time Control) with 15-minute SLA for guaranteed RPO
   - Configure Metrics & Notifications for failed replication tasks

2. **Cross-Region Failover Mechanism:**
   ```
   - Deploy Route 53 with Health Checks monitoring source bucket connectivity
   - Use Application Load Balancer (ALB) with Target Groups pointing to regional S3 endpoints
   - Implement DNS failover policy to redirect traffic to us-west-2 on us-east-1 failure
   - Configure read-after-write consistency with Multi-Region Access Points (MRAP)
   ```

3. **Validation & Testing:**
   - Perform monthly DR drills simulating regional failure
   - Monitor DataSync metrics for replication lag
   - Test application failover by temporarily rerouting DNS
   - Verify data integrity using S3 Object Lambda to compare checksums

4. **Production Updates:**
   - Deploy S3 Event Notifications to trigger Lambda functions on replication completion
   - Use CloudTrail to audit all replication activities
   - Set up CloudWatch alarms for ReplicationLatency > 30 seconds
   - Implement cost optimization by transitioning replicated objects to Glacier after 90 days

**Best Practices Used:**
- Enabled Replication Metrics to monitor lag between regions
- Used versioning to protect against accidental deletions during failover
- Segregated replication IAM role with least privilege access
- Implemented MFA Delete on source bucket to prevent unauthorized deletion
- Used S3 Inventory to reconcile objects between regions weekly

**Lessons Learned:**
A regional failure was detected within 2 minutes via CloudWatch. Failover completed in 12 minutes, well within RTO. Replication backlog built up to 200GB during the outage but caught up within 45 minutes post-recovery. Recommendation: Implement cross-region read preference in application layer for better resilience.

---

### Scenario 2: EBS-Backed Application Performance Degradation

**Problem Statement:**
An e-commerce platform running on EC2 instances with EBS gp2 volumes experienced performance degradation during peak shopping hours. Database queries were timing out, batch jobs were failing, and IOPS were consistently maxing out causing cascading failures. The team needs to optimize storage performance without downtime.

**Architecture Context:**
- 20 x EC2 t3.2xlarge instances (each with 1TB gp2 volume)
- MySQL database on m5.2xlarge with 500 GB EBS volume
- Peak traffic: 500K requests/hour
- Current IOPS: 16 cores × 100 baseline IOPS = 1600 IOPS (insufficient for workload)
- Batch jobs processing 50GB nightly logs

**Step-by-Step Troubleshooting:**

1. **Performance Analysis:**
   - Run `iostat -dx 1 10` on affected EC2 instances → shows 98% disk utilization
   - Check EBS CloudWatch metrics: `VolumeReadOps`, `VolumeWriteOps`, `VolumeThroughputPercentage`
   - Identify bottlenecks: Database server at 4000 IOPS (far exceeds gp2 baseline)
   - Analyze query patterns using MySQL Slow Query Log

2. **Migration Strategy (Zero-Downtime):**
   - Create EBS snapshots of all volumes for rollback capability
   - Use AWS DataSync to prepare io1 volumes in parallel during off-peak hours
   - Implement automated switching using EC2 Systems Manager Patch Manager
   - Perform rolling update: stop instance → detach gp2 → attach io1 → start instance

3. **Volume Configuration Changes:**
   - Database volume: gp2 (16,000 IOPS) → io1 (20,000 IOPS provisioned)
   - Application volumes: gp2 (100 IOPS baseline) → gp3 (3,000 IOPS, adjustable)
   - Batch processor volume: gp2 → st1 (throughput-optimized for sequential access)
   - Total monthly increase: $800 (accepted for peak hour reliability)

4. **Validation Post-Migration:**
   - Re-run application load tests: response time reduced from 2.5s → 800ms
   - Monitor metrics for 1 week before declaring success
   - Rollback plan: Keep gp2 snapshots for 30 days
   - Cost tracking: Set up AWS Cost Anomaly Detection

**Best Practices Used:**
- Maintained constant IOPS provisioning > peak hour demand by 20%
- Used io1 for database (predictable, critical workload)
- Used gp3 for application servers (burstable workload)
- Enabled EBS encryption with customer-managed KMS keys
- Set up automatic daily snapshots with 7-day retention
- Configured CloudWatch alarms on `BurstBalance` to warn if gp3 devices exhaust burst credits

**Metrics Post-Implementation:**
- p95 response time: reduced from 3.2s to 650ms
- Failed requests during peak: reduced from 0.5% to 0.02%
- Monthly cost: +$800 but revenue increase justified $50K additional profit
- MTTR for future performance issues: reduced from 4 hours to 15 minutes

---

### Scenario 3: S3 Versioning Enables Lost Data Recovery

**Problem Statement:**
A data analytics company accidentally deleted critical parquet files from their S3 data lake due to a misconfigured ETL job. 2 years of historical data (3.2 TB) across 140 million objects was lost. Recovery from backup tapes would take 48+ hours. The team needed immediate recovery with minimal business impact.

**Architecture Context:**
- S3 data lake in us-east-1 with prefix-based partitioning (year/month/day format)
- ETL pipeline in Python using Boto3 (had a bug in delete logic)
- Backup tapes (immutable, 48-hour retrieval time)
- 30% of analytics queries reference deleted data
- No versioning enabled on S3 bucket (critical oversight)

**Step-by-Step Recovery:**

1. **Rapid Incident Response (First 15 minutes):**
   - Identified affected prefix range: s3://datalake/2023/11/* → s3://datalake/2024/02/*
   - Disabled ETL pipeline to prevent further deletions
   - Contacted AWS Support (Enterprise) to check S3 request history via CloudTrail
   - Queried CloudTrail for delete-api calls (s3:DeleteObject) to timeline damage

2. **Recovery Strategy (Implemented within 2 hours):**
   - CloudTrail logs revealed ALL delete operations with DeleteMarkers (not permanent deletion since lifecycle rules weren't enabled)
   - Used S3 API to list-object-versions on affected buckets
   - Discovered that deleted objects still exist as DeleteMarker versions!
   - Created automated script to remove DeleteMarkers for recovered objects

   ```python
   import boto3
   s3 = boto3.client('s3')
   marker_response = s3.list_object_versions(Bucket='datalake', Prefix='2023/11/')
   for delete_marker in marker_response.get('DeleteMarkers', []):
       s3.delete_object(
           Bucket='datalake',
           Key=delete_marker['Key'],
           VersionId=delete_marker['VersionId']
       )
   ```

3. **Data Validation (3-4 hours):**
   - Restored 3.2TB (140M objects) with zero data loss
   - Ran S3 Inventory job to validate object count and ETag checksums
   - Spot-checked 1000 random parquet files using Athena queries
   - All analytical queries resumed within 2 hours of incident detection

4. **Post-Incident Hardening:**
   - Enabled Versioning on datalake bucket
   - Enabled S3 Object Lock with GOVERNANCE mode (7-year retention)
   - Implemented MFA Delete on critical prefixes
   - Added S3 Block Public Access policies
   - Implemented Lifecycle Policies: delete DeleteMarkers after 1 day, transition old versions to Glacier after 90 days

**Best Practices Implemented:**
- Enable versioning BEFORE needing recovery (lesson learned)
- Use CloudTrail for forensic analysis of deletion events
- Implement Object Lock for immutability on critical data
- MFA Delete as additional protection layer
- S3 Inventory for automated data validation
- Lifecycle policies to manage version storage costs

**Cost Impact:**
- Without versioning recovery: $500K lost revenue + $50K tape recovery costs
- With versioning enabled going forward: +$800/month in storage costs (acceptable ROI)
- Total recovery time: 2 hours vs 48 hours with tape backups
- Lesson: Versioning is cheaper than disaster recovery

---

### Scenario 4: EFS Scaling for Containerized Workload

**Problem Statement:**
A machine learning platform running containerized training jobs on ECS + Fargate needed shared file access across 50+ concurrent containers. The team initially used EBS volumes (not shareable) which required redesigning the entire data pipeline. EFS was implemented to provide seamless multi-container access, but performance degradation occurred during parallel training jobs.

**Architecture Context:**
- 50 concurrent ECS Fargate tasks processing training datasets
- Each task reads 50 GB of training data from shared storage
- Training job duration: 2-4 hours per model
- Network throughput requirement: 1000 MB/s aggregate
- Total data in EFS: 500 GB (accessed simultaneously by all tasks)

**Step-by-Step Implementation:**

1. **EFS Creation & Configuration:**
   ```
   - Created EFS in VPC with 3 Mount Targets (one per AZ)
   - Configured Bursting throughput mode (600 MB/s baseline, burst up to 3000 MB/s)
   - Set ENI trunking to optimize network bandwidth for Fargate
   - Enabled EFS access points for isolated container permissions
   ```

2. **Performance Optimization:**
   - Issue: Full aggregate throughput requirement (2500 MB/s) exceeded bursting limits
   - Solution: Migrated to Provisioned Throughput mode with 2500 MB/s (cost: +$100/hour vs $20/hour)
   - Implemented data caching layer in each container's local ephemeral storage
   - Used ECS task definitions with 50 GB ephemeral volumes for hot data

3. **Network & NFS Tuning:**
   ```bash
   # Optimized mount options in ECS task definition:
   mount -t nfs4 -o rsize=1048576,wsize=1048576,timeo=30 
         fs-xxxxx.efs.us-east-1.amazonaws.com:/ /mnt/efs
   ```

4. **Monitoring & Alerting:**
   - Set CloudWatch alarms: BurstCreditBalance < 10%, ClientConnections > 5000
   - Implemented EFS Replication to us-west-2 for HA training pipelines
   - Used EFS access logs to identify hot data files and optimize

**Best Practices:**
- Chose Provisioned Throughput for predictable, high-demand workloads
- Used Access Points to isolate permissions per ECS task
- Implemented local caching in containers (Ephemeral volumes) before EFS access
- Set up automated data lifecycle: hot data in EFS, cold data in S3
- Configured Security Groups to restrict EFS NFS (port 2049) only to ECS task ENIs

**Results:**
- Training job parallelization improved from 20 parallel tasks → 50 parallel tasks
- ML model training time reduced by 30% (due to improved concurrent I/O)
- Cost-per-training-job increased by 40% but reduced overall time-to-production by 50%

---

### Scenario 5: FSx for Windows File Server in Hybrid Environment

**Problem Statement:**
A manufacturing company needed to migrate legacy Visual Basic applications for inventory management from on-premises Windows Server to AWS while maintaining seamless SMB access for 200+ users. Direct Migration Lift-and-Shift approach failed because applications required shared file access, user authentication, and Group Policy Objects (GPO). The team implemented FSx for Windows File Server as a hybrid storage solution.

**Architecture Context:**
- On-premises: DC architecture with Active Directory, 50 GB shared file server
- Target: Hybrid AWS deployment with Site-to-Site VPN
- User base: 200 inventory managers accessing files 8KB-2MB in size
- Access patterns: 95% read, 5% write; peak concurrent users: 80
- Compliance: Needs HIPAA-compliant encryption

**Step-by-Step Implementation:**

1. **FSx Deployment:**
   - Created FSx Single-AZ Multi-AZ deployment in us-east-1, 1a, 1b
   - Throughput capacity: 64 MB/s (sufficient for 80 concurrent users)
   - Storage: 100 GB SSD (room for growth)
   - Joined existing on-premises Active Directory (seamless authentication)
   - Data Deduplication: enabled (reduced storage overhead by 35%)

2. **Hybrid Connectivity:**
   - Established AWS Direct Connect (Dedicated 1 Gbps connection) to on-premises
   - Fallback: Site-to-Site VPN with IPSec encryption
   - Latency: 8ms via Direct Connect (acceptable for SMB file sharing)
   - Backup route ensures failover within 5 minutes if primary drops

3. **User Access Configuration:**
   - FSx automatically synced with on-premises AD user accounts
   - NTFS permissions maintained (ACLs replicated from legacy server)
   - Group Policy Objects (GPO) applied automatically via AD integration
   - No user education needed (used identical UNC path: \\fsx-server\inventory)

4. **Performance Tuning:**
   - SMB multichannel enabled (NIC aggregation across multiple connections)
   - Optimized TCP window scaling for WAN latency (Direct Connect)
   - Set SMB encryption to AES-256 (HIPAA requirement, minimal performance impact)

5. **HA & DR Strategy:**
   - Automatic daily snapshots to S3 (7-day retention)
   - Multi-AZ failover: RTO < 2 minutes, RPO < 30 seconds
   - Implemented DataSync for incremental sync to S3 backup bucket in us-west-2

**Best Practices:**
- Joined existing Active Directory (no user management overhead)
- Used Direct Connect for predictable, low-latency file access
- Enabled data deduplication for Windows-specific file patterns (duplicate test files, redundant documents)
- Configured NTFS quotas per user (limit 10 GB per inventory manager)
- Enabled shadow copies for user self-service file recovery
- Used Kerberos authentication (HIPAA-compliant)

**Results:**
- User adoption: 100% within 1 week (identical UNC path)
- Performance: 95th percentile file open latency = 120ms (acceptable for office workers)
- Cost: FSx deployment ($800/month) vs legacy on-premises server ($2000/month running costs + licensing)
- Compliance: Passed HIPAA audit with AES-256 encryption + audit logging
- Migration time: 3 weeks vs 3 months estimated for manual lift-and-shift

---

## 6. Most Asked Interview Questions

### Q1: Explain the difference between S3 Standard, S3-IA, and S3 Glacier storage classes. How do you decide which to use in production?

**Answer from Senior DevOps Engineer:**

Each storage class targets different access patterns and cost profiles:

**S3 Standard:**
- First byte latency: < 1 ms (immediate access)
- Minimum storage duration: None
- Retrieval cost: Free
- Use case: Frequently accessed data (photos, logs being analyzed, website assets)
- Real-world example: Web server static assets, active database backups, application cache

**S3 Standard-IA (Infrequent Access):**
- First byte latency: < 1 ms (but retrieval fees apply)
- Minimum storage duration: 30 days (penalty for earlier deletion)
- Retrieval cost: $0.01/GB
- Use case: Data accessed < 1 time/month
- Real-world example: Database backups older than 30 days, archived logs for audit compliance
- Cost savings: 50% storage, but retrieval fees eat 20% savings if accessed > 2x/month

**S3 Glacier Instant Retrieval:**
- First byte latency: < 1 ms (requires payment)
- Minimum storage duration: 90 days
- Retrieval cost: $0.01/GB
- Use case: Data accessed quarterly
- Real-world example: Quarterly audit report archives, yearly compliance backups

**S3 Glacier Flexible Retrieval:**
- First byte latency: 1-5 minutes (Standard tier), 3-5 hours (Bulk tier)
- Minimum storage duration: 90 days
- Retrieval cost: $0.004-0.01/GB depending on tier
- Use case: Backup archives with rare access, disaster recovery scenarios
- Real-world example: Off-site backups, compliance archives not needed for months

**Decision Matrix:**
```
Data Access Pattern          Recommended Class       Monthly Cost (per TB)
Accessed daily              S3 Standard             $23.55
Accessed 2-4x/month         S3 Standard             $23.55
Accessed monthly             S3 Standard-IA         $12.48 + retrieval
Accessed quarterly          S3 Glacier Instant     $4.00 + retrieval
Accessed 2x/year            S3 Glacier Flexible    $1.00 + retrieval
Compliance archive (7yr)    S3 Glacier Deep        $0.40/month
```

**Real-world optimization tip:** Use S3 Intelligent-Tiering ($0.0125/1000 objects/month) for unpredictable access patterns. It automatically moves objects between access tiers, saving 40-70% vs Standard on data with variable access.

**Common mistake:** Organizations keep all data in S3 Standard due to "might need it." This wastes 60% of storage costs. Implement Lifecycle Policies ruthlessly: 30 days Standard → 90 days IA → 1 year Glacier.

---

### Q2: Walk me through how S3 Replication works. What are the key differences between CRR (Cross-Region) and SRR (Same-Region)?

**Answer from Senior DevOps Engineer:**

**Core Mechanics of S3 Replication:**

When an object is uploaded to a source bucket with replication configured:
1. S3 service creates object in source bucket
2. Replication rule is triggered (asynchronous, not synchronous)
3. Object metadata + content replicated to destination bucket
4. Destination objects appear with source object's last-modified timestamp
5. Eventual consistency: replica appears within seconds to minutes

**Key Limitation:** Objects added BEFORE replication is enabled are NOT retroactively replicated. You must use DataSync or S3 Batch Operations to back-fill.

**CRR (Cross-Region Replication):**

**Use Case:** Disaster recovery, regulatory compliance (data residency), latency reduction

**Example Architecture:**
```
us-east-1 (primary)  → S3 Replication → us-west-2 (secondary)
                                    ↓
                            Route 53 failover
                                    ↓
                        Multi-Regional Access Point
```

**Key Benefits:**
- Automatic failover in disaster recovery
- Reduces latency for geographically distributed users
- Regulatory compliance (healthcare data in HIPAA regions, GDPR in EU)
- Protects against regional DDoS attacks

**Cost:** Replication charges per GB transferred ($0.02/GB us-east to us-west), storage in destination bucket ($23.55/TB), data transfer out (if accessed)

**Real-world Issue:** One customer had CRR enabled but forgot to failover application DNS on region outage. Data was replicated but applications still tried connecting to us-east-1 → timeout → incident. Lesson: Failover testing is critical, not just replication setup.

---

**SRR (Same-Region Replication):**

**Use Case:** Data segregation, operational environments separation, audit logging

**Example Real-world Scenarios:**
1. **Log Analysis:** Production bucket → Separate analysis bucket (limits who can access raw logs vs processed data)
2. **Compliance:** Raw business data → Separate bucket with stricter retention policies
3. **Development mirror:** Production S3 → Identical copy for safe testing without impacting production

**Key Differences from CRR:**
```
Feature                 CRR              SRR
Primary Use            DR               Segregation
Cost Structure         Higher (transfer) Lower (no transfer)
Failover supported     YES              NO
Regulatory driver      GDPR, HIPAA      Internal governance
Replication lag        Network speed    < 1 second
```

**Production-Tested Approach:**

In one e-commerce company, they use:
- **Bucket A (Production):** Receives raw user transaction data (1TB/day)
- **CRR enabled:** Copies to us-west-2 for disaster recovery
- **SRR enabled:** Copies to separate "analytics" bucket with delete protection
- **Lifecycle on SRR bucket:** Archive to Glacier after 90 days (one-way, triggers only once)

**Cost:** CRR transfer ($0.02/GB × 1TB/day × 30 days = $600/month) + SRR replication (no transfer cost within region)

**Interview Tip:** Mention "Replication metrics" and "RTC (Replication Time Control)" to show advanced knowledge. RTC guarantees 15-minute RPO with SLA. Without RTC, replication can take hours on surge traffic.

---

### Q3: How would you design S3 bucket policies and IAM policies to give developers read-only access to logs but deny them access to customer PII?

**Answer from Senior DevOps Engineer:**

**Layered Security Approach:**

This requires combining bucket-level and object-level permissions:

**Step 1: Bucket Policy (Deny-first approach):**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowDevReadOnlyLogs",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789:group/developers"
      },
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Resource": [
        "arn:aws:s3:::company-logs",
        "arn:aws:s3:::company-logs/logs/*"
      ]
    },
    {
      "Sid": "DenyPIIAccess",
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::123456789:group/developers"
      },
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::company-logs/pii/*"
    },
    {
      "Sid": "DenyUnencryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::company-logs/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    }
  ]
}
```

**Step 2: IAM User/Role Permissions:**

Complement bucket policy with restrictive IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListLogsOnly",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::company-logs",
      "Condition": {
        "StringLike": {
          "s3:prefix": "logs/*"
        }
      }
    },
    {
      "Sid": "GetLogsOnly",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion"
      ],
      "Resource": "arn:aws:s3:::company-logs/logs/*"
    },
    {
      "Sid": "ExplicitDenyPII",
      "Effect": "Deny",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::company-logs/pii/*",
        "arn:aws:s3:::company-logs/customers/*"
      ]
    }
  ]
}
```

**Step 3: Additional Hardening - S3 Object Lambda (Advanced):**

To prevent accidental PII exposure in logs (e.g., credit card numbers in error messages):

```python
# Lambda function invoked by S3 Object Lambda Access Point
def lambda_handler(event, context):
    object_context = event["getObjectContext"]
    s3_client = boto3.client('s3')
    
    # Get original object
    response = s3_client.get_object(Bucket=object_context['inputS3Bucket'],
                                   Key=object_context['inputS3Key'])
    
    # Redact PII patterns (credit card, SSN, email)
    original_content = response['Body'].read().decode('utf-8')
    redacted = re.sub(r'\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}', 'XXXX-XXXX-XXXX-XXXX', original_content)
    redacted = re.sub(r'\d{3}-\d{2}-\d{4}', 'XXX-XX-XXXX', redacted)
    
    # Stream back redacted object
    s3_client.write_get_object_response(
        Body=redacted,
        RequestRoute=object_context['outputRoute'],
        OutputToken=object_context['outputToken']
    )
    
    return {'statusCode': 200}
```

**Real-world Testing Approach:**

1. **Positive test:** Developer tries `aws s3 cp s3://company-logs/logs/app.log .` → SUCCESS
2. **Negative test:** Developer tries `aws s3 cp s3://company-logs/pii/customers.csv .` → DENIED with 403
3. **Cross-bucket test:** Developer tries accessing different bucket → DENIED
4. **Encryption test:** Try uploading unencrypted object → DENIED

**Common Pitfalls to Avoid:**
- **Root account access:** Even with bucket policy, root AWS account bypasses all S3 policies → Use SCPs (Service Control Policies) to restrict root
- **Forgotten condition keys:** Missing Condition checks allows unintended access patterns
- **Object ACLs override:** If object ACL allows public-read, bucket policy becomes useless → Disable ACL with `BlockPublicAcls: true`
- **Whitelist vs Blacklist:** Deny PII prefix works, but whitelist (Allow logs/* only) is safer from new path additions

**Interview Depth:** Mention AWS Access Analyzer for S3 to validate your policies and find unintended public access vulnerabilities.

---

### Q4: Describe your approach to implementing lifecycle policies for cost optimization. How do you balance cost vs. data availability?

**Answer from Senior DevOps Engineer:**

**Multi-tier Lifecycle Strategy:**

```
Timeline Cost Evolution (per GB)
Day 0-30:        S3 Standard    ($0.023/GB/month) — frequent access
Day 31-90:       S3 Standard-IA  ($0.0124/GB/month + retrieval cost)
Day 91-365:      S3 Glacier Inst ($0.004/GB/month + retrieval cost)
Day 366-2555:    S3 Glacier Flex ($0.001/GB/month + retrieval cost)
Year 8+:         S3 Deep Archive ($0.00099/GB/month + retrieval cost)
```

**Real-world Data Lake Example:**

```json
{
  "Rules": [
    {
      "Id": "ActiveLogs30Days",
      "Status": "Enabled",
      "Prefix": "logs/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER_IR"
        }
      ],
      "Expiration": {
        "Days": 2555 // 7 years for compliance
      }
    },
    {
      "Id": "DatabaseBackups",
      "Status": "Enabled",
      "Prefix": "backups/db/",
      "Transitions": [
        {
          "Days": 1,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 7,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ],
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 30,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 2555
      }
    },
    {
      "Id": "DeleteIncompleteMultipart",
      "Status": "Enabled",
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    }
  ]
}
```

**Cost vs. Availability Trade-off Analysis:**

For a 500 GB data lake with daily 10 GB ingest:

| Storage Tier | Monthly Cost | Access Latency | Retrieval Fee | Use When |
|---|---|---|---|---|
| All Standard | $11.77 | <1ms | $0 | Need instant access, warm data |
| Lifecycle (1yr Standard→IA→Glacier) | $6.40 | 1-5 min | $0.01/GB | Balanced cost/availability |
| Aggressive (30d Standard→IA→Glacier) | $4.20 | 1-5 min | $0.01/GB | Can tolerate retrieval delays |
| All Glacier Deep Archive | $0.50 | 12 hours | $0.02/GB | Compliance archive only |

**Real-world Cost Optimization Story:**

One healthcare company had 2 PB of patient data in S3 Standard at $46,000/month. After lifecycle implementation:
- Days 0-30: Standard (active analysis)
- Days 31-180: Standard-IA (rare queries)
- Days 181+: Glacier Deep (compliance only)
- **New cost: $12,000/month (74% savings)**
- 3-month payback on project labor

**Critical Design Pattern: Incomplete Multipart Upload Cleanup:**

95% of S3 storage cost overruns are due to orphaned multipart uploads. A single 1TB failed upload left running costs $23/month forever. Lifecycle rule to abort after 7 days:

```json
{
  "AbortIncompleteMultipartUpload": {
    "DaysAfterInitiation": 7
  }
}
```

**Advanced: Predictive Lifecycle with S3 Intelligent-Tiering:**

For unpredictable access patterns, use Intelligent-Tiering instead of fixed lifecycle:

```json
{
  "Id": "IntelligentTier",
  "Status": "Enabled",
  "Filter": {"Prefix": "uncertain-access/"},
  "Tiering": [
    {
      "Days": 0,
      "AccessTier": "FREQUENT"  // Standard
    },
    {
      "Days": 30,
      "AccessTier": "INFREQUENT"  // IA
    },
    {
      "Days": 90,
      "AccessTier": "ARCHIVE_INSTANT"  // Glacier IR
    }
  ]
}
```

**Cost: $0.0125/1000 objects/month** (monitoring fee) but auto-moves objects based on actual access patterns. Saves 40-70% vs fixed lifecycle for unpredictable workloads.

**Monitoring Best Practices:**

Use S3 Storage Lens to identify anomalies:
```
- Objects stuck in STANDARD when STANDARD_IA applicable
- Rapid retrieval requests (indicates over-aggressive lifecycle)
- Orphaned versions taking storage (noncurrent versions not expiring)
```

**Interview Tip:** Mention that Glacier has retrieval time tiers. Bulk retrieval (12 hours, cheapest) vs Standard (3-5 hours) vs Expedited (<1 hour, expensive). Architecture decision: batch nightly retrieval jobs in bulk tier to minimize costs.

---

### Q5: Explain versioning and how it protects against data loss. How does this relate to bucket replication?

**Answer from Senior DevOps Engineer:**

**Versioning Mechanics:**

When you enable versioning on S3 bucket, every object upload creates a new version ID:

```
Initial upload:  my-file.txt → VersionID: null001
Second upload:   my-file.txt → VersionID: v8Kd9s2
Third upload:    my-file.txt → VersionID: pL2K8x3
```

When you delete an object, S3 adds a DeleteMarker (not permanent deletion):

```
GET my-file.txt → Returns DeleteMarker (404 Not Found)
GET my-file.txt?versionId=v8Kd9s2 → Returns second upload (200 OK)
```

**How Versioning Protects Against Data Loss:**

**Scenario 1: Accidental Deletion**
- Developer runs: `aws s3 rm s3://bucket/critical-file.txt`
- File shows as deleted (DeleteMarker added)
- Recovery: `aws s3api get-object --bucket bucket --key critical-file.txt --version-id v8Kd9s2 critical-file.txt`
- **RTO: 5 minutes, RPO: 0 (zero data loss)**

**Scenario 2: Malicious Deletion or Ransomware**
- Attacker runs: `aws s3api delete-object --bucket bucket --key data.json --version-id v1 --version-id v2 --version-id v3`
- Versioning protects against this with **Object Lock (GOVERNANCE mode)**
  - Cannot delete protected versions even with higher IAM permissions
  - 7-year retention policy prevents any deletion for compliance archives

**Scenario 3: Application Bug Corrupts Data**
- Bug in ETL pipeline overwrites dataset with zeros
- All 1 TB of data files now contain: `000000000000...`
- With versioning: Can restore previous version with valid data
- **Rollback time: < 1 hour, data integrity maintained**

**How This Relates to S3 Replication:**

```
Architecture: Versioning + Replication + Object Lock = Maximum Protection

Source Bucket (us-east-1)
  ├── Versioning: ENABLED
  ├── Object Lock: GOVERNANCE (7-year retention)
  ├── MFA Delete: ENABLED (requires MFA to delete)
  └── Replication Rule → Destination Bucket (us-west-2)
        └── Versioning: ENABLED (required for replication)
        └── Object Lock: ENABLED (same retention)
```

**Real-world Disaster Scenario:**

A financial services company had:
- Source bucket in us-east-1 with versioning + replication → us-west-2
- Ransomware locks all data (encrypts with attacker's key)
- Data in us-east-1 encrypted, but replication hasn't occurred yet

**Timeline:**
```
T=0:00    Ransomware encrypts 50GB in us-east-1
T=0:15    Replication begins copying encrypted objects to us-west-2
T=0:45    All 50GB replicated (now encrypted in both regions)
T=1:00    Team discovers encryption, attempts recovery
T=1:30    Realizes new versions are encrypted, retrieves 30 days old version
T=2:00    Recovers 99% of data from version before ransomware
```

**Best Practice:** Use replication with version preference to prefer older versions:

```json
{
  "Role": "arn:aws:iam::123456789:role/s3-replication",
  "Rules": [{
    "Destination": {
      "Bucket": "arn:aws:s3:::backup-bucket",
      "ReplicationTime": {
        "Status": "Enabled",
        "Time": {"Minutes": 15}  // RTC SLA
      },
      "Metrics": {
        "Status": "Enabled"
      }
    }
  }]
}
```

**Cost Impact of Versioning:**

Every version stored = storage charges:

```
100 GB object, 10 versions = 1 TB stored = $23.55/month
Same object without versioning = 100 GB = $2.36/month

Cost of versioning protection: ~$21/month per TB with high churn
```

**Cost Optimization:** Use Lifecycle to manage old versions:

```json
{
  "NoncurrentVersionTransitions": [
    {
      "NoncurrentDays": 30,
      "StorageClass": "STANDARD_IA"
    },
    {
      "NoncurrentDays": 90,
      "StorageClass": "GLACIER"
    }
  ],
  "NoncurrentVersionExpiration": {
    "NoncurrentDays": 2555  // 7 years
  }
}
```

**Advanced Protection: MFA Delete**

Requires physical 2FA to delete objects:

```bash
aws s3api put-bucket-versioning \
  --bucket my-bucket \
  --versioning-configuration Status=Enabled,MFADelete=Enabled \
  --sse-customer-key AQEDAHhzaGFkb3dfdGVzdAECAQEAB2F3cy1r... \
  --mfa "arn:aws:iam::123456789:mfa/user-mfa 123456"
```

Now to delete: `--mfa "arn:aws:iam::123456789:mfa/user-mfa 654321"` (different code required)

**Interview Depth:** Mention that versioning + replication creates "write-once, read-many" architecture for compliance. This is required by regulated industries (healthcare, finance) and earns you "Senior Engineer" credibility.

---

### Q6: You have an EBS-backed EC2 instance that's running out of disk space. Walk me through your troubleshooting and remediation steps.

**Answer from Senior DevOps Engineer:**

**Step 1: Immediate Diagnosis (within 2 minutes)**

```bash
# SSH into instance
ssh -i key.pem ec2-user@instance-ip

# Check disk space
df -h
# Output:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/xvda1      100G   95G  5.0G  95%  /
# /dev/xvdf       500G  480G  20G   96%  /data

# Identify which mountpoint is full
du -sh /* | sort -h
# Shows: /var/log is 40GB (unexpected)
#        /data is 480GB (expected)

# Disk I/O saturation?
iostat -dx 1 5
# Shows r/s (read/sec), w/s (write/sec), %util
# If %util > 90%, disk is I/O bottlenecked (not just full)

# EBS volume metrics via CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/EBS \
  --metric-name VolumeReadBytes \
  --dimensions Name=VolumeId,Value=vol-1234567 \
  --start-time 2024-11-01T00:00:00Z \
  --end-time 2024-11-01T01:00:00Z \
  --period 300 \
  --statistics Sum
```

**Step 2: Root Cause Analysis**

**Scenario A: Log Explosion**
```bash
# Find large log files
find /var/log -type f -size +1G | head
# /var/log/application.log is 45GB (not rotating)

# Check log rotation config
cat /etc/logrotate.d/application
# Missing logrotate policy

# Immediate fix: compress old logs
cd /var/log && gzip application.log.1 application.log.2
# Frees up ~30GB immediately

# Permanent fix: Update logrotate
# /var/log/application.log {
#   daily
#   rotate 7
#   compress
#   missingok
#   notifempty
# }
```

**Scenario B: Old Snapshots/Backups**
```bash
# Find large files not accessed recently
find /data -type f -atime +30 -size +1G
# /data/backups/old_database_20230101.dump is 300GB

# Check if needed
ls -lrt /data/backups/ | tail -20
# Old backups taking unnecessary space

# Move to S3 for archival
aws s3 cp /data/backups/old_database_20230101.dump \
  s3://archive-bucket/database-backups/

# Remove local copy
rm /data/backups/old_database_20230101.dump
# Frees 300GB
```

**Scenario C: Docker Container Images (if Docker running)**
```bash
# List size of images
docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}"

# Remove dangling/unused images
docker image prune -a
# Can free 50+ GB on development instances

# Container log accumulation
docker system df  # Shows space used by containers, volumes, networks
docker system prune --volumes  # Remove unused volumes
```

**Step 3: Remediation Strategy**

### **Option A: Expand Existing Volume (No Downtime with gp3)**

```bash
# Check current volume details
aws ec2 describe-volumes --volume-ids vol-1234567 \
  --query 'Volumes[0].{Size:Size,Type:VolumeType,Iops:Iops}'

# Expand volume (gp2 → gp3) with no downtime if using EBS elastic volumes
aws ec2 modify-volume --volume-id vol-1234567 --size 200

# Inside EC2, check if volume expanded
df -h
# Still shows 100G (need to extend filesystem)

# Extend EXT4 filesystem
sudo resize2fs /dev/xvda1
# Now df -h shows 200G available

# Expand LVM volume (if using LVM)
sudo pvresize /dev/xvdf
sudo lvresize -l +100%FREE /dev/mapper/vg0-lv0
sudo resize2fs /dev/mapper/vg0-lv0
```

**Cost:** gp3 at $0.10/GB/month, so 100GB expansion = $10/month additional

### **Option B: Attach New Volume (If Expansion Required Post-volume Creation)**

For very large expansions (e.g., need 1TB total):

```bash
# Create new EBS volume
aws ec2 create-volume --size 500 --volume-type gp3 \
  --availability-zone us-east-1a --iops 3000 --throughput 125

# Attach to instance
aws ec2 attach-volume --instance-id i-1234567 \
  --volume-id vol-new --device /dev/sdf

# Inside EC2, format and mount
sudo mkfs.ext4 /dev/nvme1n1
sudo mkdir /data-new
sudo mount /dev/nvme1n1 /data-new

# Copy data (with progress indicator)
rsync -avh /data/ /data-new/ &

# After migration, update fstab
sudo blkid /dev/nvme1n1  # Get UUID
# UUID=aaaa-bbbb /data ext4 defaults,nofail 0 2

# Unmount old volume, remount new one
sudo umount /data
sudo mount /data-new /data

# Verify
df -h
```

**Step 4: Monitoring to Prevent Recurrence**

```bash
# CloudWatch alarm for disk usage
aws cloudwatch put-metric-alarm \
  --alarm-name high-disk-usage \
  --alarm-description "Alert when disk > 80%" \
  --namespace CustomMetrics \
  --metric-name DiskUsagePercent \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold

# Send disk metrics to CloudWatch (custom metric)
# In cron, every 5 minutes:
#!/bin/bash
USAGE=$(df / | awk 'NR==2 {print int($5)}')
aws cloudwatch put-metric-data \
  --namespace CustomMetrics \
  --metric-name DiskUsagePercent \
  --value $USAGE
```

**Step 5: Automation with Autoscaling (Long-term Fix)**

For frequently-growing workloads, automate expansion:

```yaml
# CloudFormation: Auto-expand EBS on high usage
Resources:
  DiskExpansionLambda:
    Type: AWS::Lambda::Function
    Properties:
      Handler: index.handler
      Runtime: python3.11
      Code:
        ZipFile: |
          import boto3
          import os
          
          ec2 = boto3.client('ec2')
          
          def handler(event, context):
              volume_id = event['detail']['volume-id']
              disk_usage = float(event['detail']['usage_percent'])
              
              if disk_usage > 85:
                  volume = ec2.describe_volumes(VolumeIds=[volume_id])
                  current_size = volume['Volumes'][0]['Size']
                  
                  # Expand by 20%
                  new_size = int(current_size * 1.2)
                  ec2.modify_volume(VolumeId=volume_id, Size=new_size)
                  
                  return f"Expanded {volume_id} from {current_size}GB to {new_size}GB"

  # CloudWatch Event triggers Lambda when custom metric > 85%
  DiskExpansionRule:
    Type: AWS::Events::Rule
    Properties:
      EventPattern:
        source: [aws.custommetrics]
        detail-type: ["EC2 Disk Usage High"]
```

**Real-world Scenario Results:**

One e-commerce company automated disk expansion with Lambda:
- Before: Manual expansion took 4 hours (2 hours incident detection + 2 hours remediation)
- After: Automatic expansion in 2 minutes
- Cost increase: +$5/month (Lambda + metrics) but avoided 12+ hours/year of manual work
- ROI: 50:1 savings in engineering labor

**Interview Follow-up Topics:**
1. **NVMe vs EBS naming:** `/dev/sda1` (older instances) vs `/dev/nvme0n1` (newer instances)
2. **Max size limits:** gp2 max 16TB, io1 max 16TB, st1 max 16TB
3. **Snapshot dependencies:** Cannot reduce volume size; must create new volume with snapshot
4. **Cost optimization:** gp3 cheaper than gp2 for same IOPS, consider migration

---

### Q7: How do you handle S3 bucket access from on-premises applications? Compare Gateway endpoints, VPC endpoints, and VPN/Direct Connect approaches.

**Answer from Senior DevOps Engineer:**

**Three Primary Approaches:**

**Approach 1: S3 Gateway Endpoints (Simplest for VPC)**

```
On-Premises Application
         ↓ (NOT through VPC)
  Internet Gateway
         ↓
   Public S3 API endpoint (s3.amazonaws.com)
         ↓
    S3 Bucket
```

**Limitations:**
- Requires internet connectivity from on-prem
- Data traverses public internet (security concern)
- No source IP validation possible
- Bandwidth charges incurred ($0.09/GB in/out)

**Use case:** Development/test environments only

---

**Approach 2: VPC Endpoints (Better for Low-Latency VPC to S3)**

**Interface Endpoint:**
```json
{
  "ServiceName": "com.amazonaws.us-east-1.s3",
  "VpcId": "vpc-12345",
  "SubnetIds": ["subnet-1a", "subnet-1b"],
  "SecurityGroupIds": ["sg-s3-endpoint"],
  "PrivateDnsEnabled": true
}
```

**Benefits:**
- No egress charges (data through endpoint is free)
- Route traffic through AWS backbone (private network)
- AWS PrivateLink technology (isolated to your VPC)

**Architecture:**
```
EC2 Instance (172.31.0.10)
   ↓ (via route table: 0.0.0.0/0 → vpce-123)
VPC Endpoint (private IP 172.31.0.1)
   ↓ (through AWS backbone, not internet)
S3 Bucket
```

**Real-world VPC Endpoint Endpoint Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "AWS": "arn:aws:iam::123456789:role/ec2-app-role"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::my-app-bucket/*",
      "Effect": "Allow"
    }
  ]
}
```

**Cost Savings:** Gateway endpoint saves $0.09/GB per GB of data transferred (significant for data lake workloads)

**Limitation:** Only works for services within VPC; on-premises cannot use

---

**Approach 3: VPN + VPC Endpoint (Hybrid On-Prem to S3)**

For on-premises applications needing S3 access:

```
On-Premises Data Center
  ↓ (IPSec VPN Tunnel, encrypted)
AWS VPN Connection (vpn-12345)
  ↓
Virtual Private Gateway (vgw-123)
  ↓
VPC (172.31.0.0/16)
  ↓
EC2 Bastion/NAT instance (routes S3 requests)
  ↓
VPC Endpoint
  ↓
S3 Bucket
```

**VPN Configuration:**

```bash
# On-premises side (strongSwan or OpenVPN)
./ipsec up aws-vpn-connection

# Verify tunnel
ipsec status
# aws-vpn-connection: 172.31.0.0/16 === 10.0.0.0/16

# Test connectivity
ping 172.31.0.10  # EC2 instance in VPC
# Should reach with VPN up

# Route S3 through VPC tunnel
route add -net 0.0.0.0 gw 10.0.0.1
# All traffic (including S3) routes through VPN
```

**On-Premises App Code:**

```python
import boto3
from botocore.config import Config

# Application connects as if S3 is local resource
s3 = boto3.client('s3',
    endpoint_url='http://vpc-endpoint-dns.us-east-1.vpce.amazonaws.com',
    config=Config(
        s3={'addressing_style': 'virtual'},  # Important for VPC endpoint
        region_name='us-east-1'
    )
)

response = s3.get_object(Bucket='datalake', Key='data/file.parquet')
# Request flows: on-prem app → VPN tunnel → VPC Instance → VPC Endpoint → S3
```

**Cost Model:**
```
VPN Charges:
- VPN Connection: $36/month
- Data Transfer: $0.09/GB (IN), $0.09/GB (OUT)
- Total for 1TB/month transfer: $36 + $180 = $216/month

vs.

Internet Gateway:
- No connection charge
- Data Transfer: $0.09/GB (OUT only, IN is free)
- Total for 1TB/month: $90/month

Breakeven: When using VPN, only saves vs IG if data transfer < 1TB/month
(encryption/security benefits offset cost for smaller datasets)
```

---

**Approach 4: AWS Direct Connect (Production-Grade Hybrid)**

Dedicated network connection (1Gbps, 10Gbps, or 100Gbps):

```
On-Premises Data Center
  ↓ (Dedicated fiber, not encrypted by default)
AWS Direct Connect Endpoint (physical location)
  ↓
Virtual Interface (VIF) - Layer 3 connection
  ↓
VPC (172.31.0.0/16)
  ↓
VPC Endpoint or Direct Routing
  ↓
S3 Bucket
```

**Real-world Hybrid Setup:**

A financial institution with strict low-latency requirements:
- Direct Connect: 10 Gbps connection to us-east-1
- Private Virtual Interface (VIF): 172.31.0.0/16 routed directly
- S3 reachable with 8ms latency (vs 45ms over VPN)

```
Network Performance Comparison:
                    Latency    Throughput    Cost/Month    Use Case
Internet (public)   50-100ms   1-10 Mbps     $90          Dev/Test
VPN                 25-40ms    100Mbps       $216         Secure, small data
Direct Connect      5-15ms     10Gbps        $9000        Production, high-volume
```

**Architecture Recommendation Matrix:**

| Scenario | Solution | Reason |
|---|---|---|
| Dev/test, < 10 GB/mo | Public S3 API | Cost-effective |
| EC2 ↔ S3, same region | VPC Gateway Endpoint | FREE, low latency, no internet |
| On-prem ↔ VPC, < 100 GB/mo | Site-to-Site VPN | Affordable security |
| On-prem ↔ S3, production | Direct Connect + Private VIF | Guaranteed latency, high throughput |
| Multi-region ↔ S3 | Direct Connect + VIF per region | Global connectivity |
| Compliant data (HIPAA/PCI) | Direct Connect + encryption | Dedicated connection for security |

**Real-world Incident: VPN Bandwidth Exhaustion**

One company's on-premises ETL jobs would intermittently fail:
- Setup: Site-to-Site VPN to S3 endpoint in VPC
- Problem: VPN tunnel became bottleneck during 3 parallel 2TB backups
- Each job would fail MFA timeout (trying to transfer 6TB total > VPN capacity)
- Investigation: `ipsec status --short` showed connection, but `nettop -n` showed packet loss
- Solution: Upgrade from VPN (single tunnel) to Direct Connect (10Gbps)
- Result: 3 jobs run simultaneously without contention

**Interview Tip:** Mention that Gateway Endpoints are most cost-effective for VPC, but VPN/Direct Connect required for on-premises access. Many candidates miss this distinction and lose credibility on hybrid architecture questions.

---

### Q8: Explain S3 Object Lock and how it prevents accidental or malicious deletion. What are the implications for compliance?

**Answer from Senior DevOps Engineer:**

**Object Lock Modes:**

**Mode 1: GOVERNANCE Mode (Default)**

Objects cannot be deleted during retention period UNLESS:
- User has `s3:BypassGovernanceRetention` IAM permission AND
- Includes `x-amz-bypass-governance-retention: true` header in delete request

```bash
# Normal delete attempt (DENIED)
aws s3api delete-object --bucket compliance-bucket --key data.json
# Error: Access Denied

# Bypass delete (ALLOWED only with special permission)
aws s3api delete-object \
  --bucket compliance-bucket \
  --key data.json \
  --bypass-governance-retention
# Requires IAM permission AND in-request header
```

**Use case:** "Default-deny but allow admins to bypass" (most common)

**Mode 2: COMPLIANCE Mode (Strict)**

Objects CANNOT be deleted by ANYONE during retention period, period. Even:
- AWS Account Owner cannot delete
- Root account cannot delete
- IAM role with `s3:*` permissions cannot delete
- Only way to delete: Wait for retention period to expire

```bash
# Compliance mode: DELETE IMPOSSIBLE until retention expires
aws s3api delete-object --bucket strict-bucket --key audit-log.txt
# Error: Access Denied (no workaround)

# Even with ALL services enabled:
aws s3api delete-object \
  --bypass-governance-retention \
  --bucket strict-bucket \
  --key audit-log.txt
# Still: Error: Object is in Compliance Mode (immutable)
```

**Use case:** Regulatory compliance (healthcare, financial records mandated to be immutable)

---

**Legal Hold:**

Independent of retention period. Once enabled, object cannot be deleted UNLESS legal hold is removed:

```json
{
  "ObjectLockConfiguration": {
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "GOVERNANCE",
        "Years": 7
      },
      "LegalHold": {
        "Status": "On"
      }
    }
  }
}
```

**Use case:** E-discovery in litigation (object locked until court releases it)

---

**Real-world Compliance Scenario: Healthcare HIPAA**

A healthcare provider requires 7-year HIPAA data retention:

```json
{
  "Bucket": "hipaa-patient-records",
  "ObjectLockConfiguration": {
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "COMPLIANCE",
        "Years": 7
      }
    }
  },
  "VersioningConfiguration": {
    "Status": "Enabled"
  },
  "BucketKey": true,
  "ServerSideEncryptionConfiguration": {
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:us-east-1:123456789:key/12345"
      }
    }]
  },
  "LoggingConfiguration": {
    "LoggingEnabled": true,
    "TargetBucket": "audit-logs"
  }
}
```

**Impact:**

Once object locked in COMPLIANCE mode:
- **Day 1:** Patient record uploaded (locked for 7 years)
- **Year 3:** Ransomware attack attempts deletion → DENIED
- **Year 7:** Retention expires automatically
- **Year 7 + 1 day:** Object deletable

**Cost Implication:**
- 100 million patient records × 3KB = 300 TB stored
- 7-year retention = constant storage cost
- Monthly cost: 300TB × $23.55/TB = $7,065/month
- 7-year cost: $593,460 (budgeting required)

---

**Ransomware Protection: Common Attack Prevention**

**Attack Scenario 1: Attacker deletes backups**

```
Normal Operation:
EC2 App → Writes to S3 bucket without Object Lock
Daily backup: S3 → S3 bucket with Object Lock

Ransomware Attack (T=0):
- Compromises EC2 app role (s3:DeleteObject permission)
- Deletes all backups in non-locked bucket
- Finds locked backup bucket, cannot delete
- Ransom demand: "Pay $1M or we encrypt more systems"
```

**Protection:** Object Lock prevents backup deletion even if EC2 app compromised

**Attack Scenario 2: Attacker modifies retention period**

```bash
# Normal attempt to shorten retention (DENIED in COMPLIANCE mode)
aws s3api put-object-retention \
  --bucket hipaa-bucket \
  --key patient-record.json \
  --retention Mode=GOVERNANCE,RetainUntilDate=2025-01-01T00:00:00Z
# Error: Cannot shorten retention in Compliance Mode
```

---

**Backup Retention vs. Object Lock Comparison:**

| Feature | Glacier Vault Lock | S3 Object Lock | Purpose |
|---|---|---|---|
| Lock type | Vault-level | Object-level |
| Retention enforcement | Permanent | Temporary (but extendable) |
| Can extend? | No | Yes (only backward compatible) |
| Deletion prevention | Absolute (48hr thaw required) | Absolute (Compliance Mode) |
| Cost | AWS Glacier | Standard S3 (or IA/Glacier after Lifecycle) |
| Use case | Off-site immutable backup | Compliance archives |

---

**Implementation Best Practice: Layered Immutability**

Combine Object Lock with IAM to prevent accidental deletion:

```json
{
  "Bucket": "critical-archives",
  "ObjectLockConfiguration": {
    "ObjectLockEnabled": "Enabled",
    "Rule": {
      "DefaultRetention": {
        "Mode": "GOVERNANCE",
        "Years": 7
      }
    }
  },
  "BucketPolicy": {
    "Effect": "Deny",
    "Action": [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:PutObjectRetention"
    ],
    "Principal": "*",
    "Condition": {
      "StringNotLike": {
        "aws:userid": "AIDA*"  // Only role with specific ID can bypass
      }
    }
  }
}
```

**Results:**
1. **Accidental deletion:** Prevented by Object Lock (no IAM workaround)
2. **Ransomware deletion:** Prevented by Object Lock (even with root credentials)
3. **Compliance audit:** CloudTrail shows all delete attempts blocked (audit trail preservation)

**Interview Depth:** Mention that Object Lock is a feature of **Object Lock-enabled buckets** (configuration choice at creation), whereas MFA Delete is per-object configuration. This distinction separates junior from senior engineers.

---

### Q9: How do you monitor EBS and EFS performance? What metrics are most critical for a production database?

**Answer from Senior DevOps Engineer:**

**EBS Metrics to Monitor:**

**Critical Metrics (Alarms Required):**

```json
{
  "DatabaseEBSMonitoring": {
    "VolumeReadOps": {
      "Unit": "Count",
      "Threshold": "Baseline + 50%",
      "Description": "Read operations per minute",
      "Action": "Indicates I/O contention; may need larger volume size or IOPS upgrade"
    },
    "VolumeWriteOps": {
      "Unit": "Count",
      "Threshold": "< provisioned IOPS",
      "Description": "Write operations per minute",
      "Action": "If > IOPS, writes will queue and add latency"
    },
    "VolumeQueueLength": {
      "Unit": "Count",
      "Threshold": "> 4 for io1, > 2 for gp3",
      "Description": "Operations waiting for I/O completion",
      "Action": "Queue forming = disk bandwidth saturation imminent"
    },
    "VolumeThroughputPercentage": {
      "Unit": "Percent",
      "Threshold": "> 90%",
      "Description": "Throughput (MB/s) as % of provisioned",
      "Action": "Approaching throughput limit; upgrade throughput capacity"
    },
    "VolumeConsumedReadOpsPercentage": {
      "Unit": "Percent",
      "Threshold": "> 80%",
      "Description": "Consumed read IOPS as % of burst capacity",
      "Action": "Burst credits depleting; workload exceeds baseline"
    }
  }
}
```

**Real-world EBS Monitoring Setup (MySQL Production Database):**

```bash
# CloudWatch custom metrics for database I/O pattern analysis
#!/bin/bash

# Every 60 seconds, collect metrics
VOLUME_ID="vol-0a1b2c3d4e5f6g7h8"
REGION="us-east-1"

while true; do
  # Get EBS metrics
  aws cloudwatch get-metric-statistics \
    --namespace AWS/EBS \
    --metric-name VolumeReadOps \
    --dimensions Name=VolumeId,Value=$VOLUME_ID \
    --statistics Average \
    --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --region $REGION % jq '.Datapoints[0].Average'
  
  # Get instance-level disk I/O (more detailed)
  iostat -dx 1 1 | grep nvme | awk '{
    print "Volume Read Latency:", $6, "ms"
    print "Volume Write Latency:", $7, "ms"
    print "Volume Util%:", $NF, "%"
  }'
  
  sleep 60
done
```

**EFS Metrics to Monitor:**

```json
{
  "EFSMetricsForPyArrow": {
    "ClientConnections": {
      "Threshold": "> 1000 per mount target",
      "Remediation": "Add NFS tuning, implement connection pooling"
    },
    "DataReadIOBytes": {
      "Threshold": "Monitor trend for capacity planning",
      "Remediation": "If exceeds throughput, upgrade from bursting to provisioned"
    },
    "DataWriteIOBytes": {
      "Threshold": "Same as read bytes",
      "Remediation": "Monitor for write-heavy workloads"
    },
    "BurstCreditBalance": {
      "Threshold": "Drop below 10% of max credits",
      "Remediation": "Indicates sustained throughput > baseline; upgrade to provisioned"
    },
    "MeteredIOBytes": {
      "Threshold": "Any non-zero value (pay-per-use)",
      "Remediation": "Consider provisioned throughput for predictable workloads"
    },
    "PermittedThroughputExceeded": {
      "Threshold": "> 0 (any value is bad)",
      "Remediation": "Workload exceeds provisioned throughput; increase allocation"
    },
    "PercentIOLimit": {
      "Threshold": "> 30% for bursting, > 80% for provisioned",
      "Remediation": "Monitor for capacity planning"
    }
  }
}
```

**Real-world EFS Monitoring: ML Training Workload**

```python
import boto3
import time
from datetime import datetime, timedelta

cloudwatch = boto3.client('cloudwatch')

def monitor_efs_for_ml_training(file_system_id, duration_hours=12):
    """
    Monitor EFS during ML training to detect performance degradation
    """
    start_time = datetime.utcnow()
    end_time = start_time + timedelta(hours=duration_hours)
    
    while datetime.utcnow() < end_time:
        metrics = {
            'BurstBalance': cloudwatch.get_metric_statistics(
                Namespace='AWS/EFS',
                MetricName='BurstCreditBalance',
                Dimensions=[{'Name': 'FileSystemId', 'Value': file_system_id}],
                StartTime=datetime.utcnow() - timedelta(minutes=5),
                EndTime=datetime.utcnow(),
                Period=300,
                Statistics=['Average']
            ),
            'Throughput': cloudwatch.get_metric_statistics(
                Namespace='AWS/EFS',
                MetricName='DataReadIOBytes',
                Dimensions=[{'Name': 'FileSystemId', 'Value': file_system_id}],
                StartTime=datetime.utcnow() - timedelta(minutes=5),
                EndTime=datetime.utcnow(),
                Period=300,
                Statistics=['Sum']
            ),
            'Connections': cloudwatch.get_metric_statistics(
                Namespace='AWS/EFS',
                MetricName='ClientConnections',
                Dimensions=[{'Name': 'FileSystemId', 'Value': file_system_id}],
                StartTime=datetime.utcnow() - timedelta(minutes=5),
                EndTime=datetime.utcnow(),
                Period=300,
                Statistics=['Average']
            )
        }
        
        # Parse metrics
        burst_balance = metrics['BurstBalance']['Datapoints'][0]['Average'] if metrics['BurstBalance']['Datapoints'] else None
        read_bytes = metrics['Throughput']['Datapoints'][0]['Sum'] if metrics['Throughput']['Datapoints'] else 0
        connections = metrics['Connections']['Datapoints'][0]['Average'] if metrics['Connections']['Datapoints'] else 0
        
        # Alert if concerning
        if burst_balance and burst_balance < 100 * 1024**4 * 0.1:  # 10% of max
            print(f"⚠️  Burst credits depleting: {burst_balance:.2e} bytes remaining")
            print("→ Consider upgrading to Provisioned Throughput mode")
        
        if read_bytes > 1000 * 1024**3:  # 1 TB in 5 min window
            print(f"🔥 High throughput: {read_bytes / (1024**3):.1f} GB in 5 minutes")
            print(f"→ ML training I/O pattern optimal, {connections:.0f} concurrent connections")
        
        time.sleep(300)  # Check every 5 minutes
```

---

**Critical Metrics Comparison: EBS vs. EFS**

| Metric | EBS (Database) | EFS (Shared Storage) | Action |
|---|---|---|---|
| Queue Length | > 4 ops | N/A | Increase volume IOPS/throughput |
| Latency | > 50ms p99 | > 5ms p99 | Needs investigation; possible network saturation |
| Throughput Util | > 80% | > 75% | Upgrade provisioned throughput |
| Burst Credits | < 20% | < 10% | Sustained workload exceeds baseline |

**Production Database Specific Recommendations:**

**For MySQL on EC2 with EBS:**

```ini
# MySQL Performance Schema monitoring
SELECT * FROM performance_schema.table_io_waits_summary_by_table 
WHERE OBJECT_SCHEMA != 'mysql' 
ORDER BY COUNT_READ + COUNT_WRITE DESC;

# Will show which tables are I/O-intensive
# Example output: 
# transactions table: 1M reads, 500K writes (hottest)
# action_logs table: 10M reads, 2M writes (bottleneck)
```

**CloudWatch Alarms for MySQL:**

```json
{
  "AlarmName": "DBLatencyHigh",
  "MetricName": "VolumeReadLatency",
  "Threshold": 50,
  "ComparisonOperator": "GreaterThanThreshold",
  "TreatMissingData": "notBreaching",
  "Actions": [
    "arn:aws:sns:us-east-1:123456789:pagerduty-critical",
    "arn:aws:lambda:us-east-1:123456789:function:auto-upgrade-ebs"
  ]
}
```

**When metrics indicate bottleneck, escalation path:**

1. **p99 latency > 50ms** → Check queue length
2. **Queue length > 4** → Increase IOPS (io1: $0.065/provisioned IOPS; gp3: cheaper for many workloads)
3. **Still slow after IOPS upgrade** → May be table/query level (MySQL issue, not storage)
4. **EFS permissions causing slowdown** → Check `allow_nfs_unsupported_attr = false` in mount options

**Interview Depth:** Mention "burst credits" for ephemeral spikes vs. provisioned for sustained. This shows understanding of cost vs. performance trade-offs.

---

### Q10: Compare EBS, EFS, and FSx. When would you choose each for different workloads?

**Answer from Senior DevOps Engineer:**

**Head-to-Head Comparison:**

| Feature | EBS | EFS | FSx Windows | FSx Lustre |
|---|---|---|---|---|
| **Access Method** | Block device (attached to EC2) | NFS (network protocol) | SMB 2.0/3.0 (Windows shares) | POSIX (POSIX compliance) |
| **Max Size** | 16 TB (io1/io2), 16TB (gp3) | Unlimited (elastic growth) | 32 TB | 3.2 TB - 100+ TB |
| **File Protocols** | None (block storage) | NFS v4.0/4.1 | SMB, NFS | POSIX (Linux native) |
| **Instances Served** | 1 (single attachment) | Hundreds (via NFS) | Hundreds (via SMB) | Hundreds (via POSIX) |
| **Latency** | **Sub-1ms** (lowest) | **1-5ms** (network) | **5-10ms** (network) | **<1ms** (HPC optimized) |
| **Cost (/TB/mo)** | $23.55 (standard) | $30.50 (growth) | $800+ (Windows license) | Varies ($0.5-5/GB) |
| **Shared Access** | ❌ No (attach to one EC2) | ✅ Yes (NFS mount) | ✅ Yes (Windows shares) | ✅ Yes (POSIX) |
| **On-Premises Access** | ❌ No | ❌ No | ✅ Yes (DirectConnect/VPN) | ❌ No |
| **Replication** | Snapshots only | EFS Replication | Backup & Restore | N/A (HPC) |

---

**Workload Decision Matrix:**

## **Scenario 1: Single EC2 Application (MySQL Database)**
```
Requirements:
- High IOPS (4000+), low latency
- No sharing needed
- Fast snapshots for backup
```

**Solution: EBS (io1 or gp3)**

Why:
- Lowest latency (SubI/O-critical)
- Provisioned IOPS for database guarantee
- Snapshots for point-in-time recovery
- Cost: 500GB io1 = $0.065/IOPS × 4000 + $100/month = $360/month

Real example: RDS (which uses EBS under the hood) for production databases

---

## **Scenario 2: Web App Needs Shared Content Directory**
```
Requirements:
- 10 Fargate tasks need shared /app/uploads
- 100+ GB storage
- Auto-scaling (tasks created/destroyed)
- Linux environment
```

**Solution: EFS**

Why:
- Multiple Fargate tasks mount same filesystem
- Auto-scale: new tasks instantly see shared data
- Network-based (works with containers)
- Cost: 100GB growth = 100GB × $0.30 = $30/month

Real example: Multi-tenant SaaS where each user's uploads live in shared /app/uploads

---

## **Scenario 3: Windows File Server Migration**
```
Requirements:
- 200 users needing shared drive (G:\data)
- Active Directory integration
- NTFS permissions
- On-premises + AWS hybrid
```

**Solution: FSx for Windows File Server**

Why:
- Native SMB protocol (Windows users see \\fsx-server\share)
- Direct AD integration (no user re-authentication needed)
- Hybrid: accessible from on-prem via VPN/Direct Connect
- Cost: 500GB FSx = $1.50/GB × 500 + 1512/month (license) = $2262/month

Real example: Manufacturing company migrating legacy Visual Basic apps (Scenario 5 earlier)

---

## **Scenario 4: HPC/Machine Learning Training**
```
Requirements:
- 50+ compute nodes need shared /data
- 10 TB dataset
- Parallel access, very high throughput (GB/s)
- Training jobs run 4 hours, then data purged
```

**Solution: FSx for Lustre**

Why:
- POSIX parallel filesystem (built for HPC)
- Throughput optimized (GB/s not MB/s)
- Integrate with S3 (auto-upload results: `hsm_archive` command)
- Cost: 50TB Lustre = $1/GB/month = $50,000/month (but worth it for 100 Nvidia H100 GPUs)

Real example: Training 100B parameter LLM models; throughput bottleneck on standard filesystems

---

**Real-world Cost Analysis:**

Company running 3 workloads simultaneously:

```
Workload 1: Production MySQL (5TB)
├─ EBS io1 5000 IOPS
├─ 5TB * $23.55 = $117.75
├─ 5000 IOPS * $0.065 = $325
└─ Total: $443/month

Workload 2: Web app shared uploads (500GB)
├─ EFS Standard
├─ 500GB * $0.30 = $150
└─ Total: $150/month

Workload 3: Windows file sharing (200 users, 2TB)
├─ FSx Single-AZ
├─ 2TB * $1.50 = $3000
├─ Windows license: $1512
└─ Total: $4512/month

TOTAL MONTHLY: $5,105

Incorrect approach (all EBS):
├─ MySQL EBS: $443/month
├─ Shared uploads via EBS SnapMirror: N/A (not possible, can't share)
├─ Windows shares via EBS: N/A (not possible)
└─ Would need MANUAL workaround architecture = 10+ hours engineering time
```

---

**Advanced: Combining Storages for Optimal Architecture**

**Hybrid Approach for Recommendation Engine:**

```
Architecture:
┌─────────────────────────────────────────────────────┐
│ S3 (cold training data: 100TB) ← Lifecycle          │
│ ↓ (daily nightly batch)                             │
│ FSx Lustre (hot training: 10TB) ← nightly sync      │
│ ↓ (ML training jobs)                                │
│ EBS (intermediate checkpoints) ← High I/O           │
│ ↓ (model saved)                                     │
│ EBS Snapshots → Glacier (long-term backups)         │
│ ↓ (inference runs)                                  │
│ EFS (serving layer) ← Shared inference endpoints    │
└─────────────────────────────────────────────────────┘

Cost savings: S3 Glacier (coldest) → Lustre (hottest) pipeline
ensures cheapest storage for dormant data, HPC filesystems 
for performance-critical operations
```

**Interview Tip:** Mention "sticky workloads" (stay in same tier) vs. "hot/cold data patterns" (move through lifecycle). This separates engineers who understand storage as a system from those who see databases in isolation.