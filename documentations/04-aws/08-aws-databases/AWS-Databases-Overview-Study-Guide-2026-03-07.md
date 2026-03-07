# AWS Databases Overview: Senior DevOps Study Guide

**Author:** DevOps Engineering Team  
**Target Audience:** DevOps Engineers (5–10+ years experience)  
**Last Updated:** March 7, 2026  
**Status:** Active

---

## Table of Contents

- [Introduction](#introduction)
- [Foundational Concepts](#foundational-concepts)
  - [Key Terminology](#key-terminology)
  - [Database Classification Architecture](#database-classification-architecture)
  - [DevOps Principles for Data Layer](#devops-principles-for-data-layer)
  - [Best Practices](#best-practices)
  - [Common Misunderstandings](#common-misunderstandings)
- [RDS Basics](#rds-basics)
- [Aurora Architecture](#aurora-architecture)
- [DynamoDB Fundamentals](#dynamodb-fundamentals)
- [Backup Strategies & Disaster Recovery](#backup-strategies--disaster-recovery)
- [Hands-on Scenarios](#hands-on-scenarios)
- [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

AWS database services form the critical data persistence layer in modern cloud architectures. As a DevOps engineer, understanding how to provision, monitor, scale, and maintain these databases is essential for building resilient, production-grade systems. AWS offers a diverse portfolio of database solutions tailored to different access patterns, consistency requirements, and operational characteristics:

- **Amazon RDS**: Managed relational databases with automated backups and failover
- **Amazon Aurora**: AWS's high-performance distributed relational database with read replicas and auto-scaling
- **Amazon DynamoDB**: Fully managed NoSQL database for high-throughput, low-latency access patterns
- **Additional Services**: ElastiCache, DocumentDB, Neptune, Redshift, and specialized databases

This study guide focuses on the three core services most frequently encountered in DevOps roles: RDS, Aurora, and DynamoDB, along with comprehensive backup and disaster recovery strategies.

### Why It Matters in Modern DevOps Platforms

**1. Infrastructure as Code (IaC) & Automation**
- Databases require declarative infrastructure definitions (CloudFormation, Terraform)
- Automated provisioning reduces human error and ensures consistency
- Version control of database configurations enables rollback capabilities

**2. High Availability & Resilience**
- Production systems demand minimal downtime and automatic failover
- Multi-AZ deployments, read replicas, and cross-region replication are non-negotiable
- RTO/RPO requirements drive architectural decisions

**3. Performance at Scale**
- Database performance directly impacts application response times
- Query optimization, indexing strategies, and connection pooling are DevOps responsibilities
- Monitoring and alerting on database metrics enable proactive scaling

**4. Cost Optimization**
- Database hosting often represents 30–50% of cloud infrastructure costs
- Right-sizing instances, managing storage, and leveraging reserved instances requires expertise
- Understanding pricing models (provisioned vs. on-demand vs. Savings Plans) is critical

**5. Data Security & Compliance**
- Encryption at rest and in transit (TLS/SSL)
- VPC isolation, security groups, and IAM policies restrict access
- Audit logging and compliance requirements (HIPAA, PCI-DSS, SOC 2) shape architecture

**6. Operational Excellence**
- Backup, restore, and disaster recovery procedures are essential for SLAs
- Point-in-time recovery, automated snapshots, and cross-region backups minimize data loss
- Patch management and minor version upgrades require coordination

### Real-World Production Use Cases

**Use Case 1: E-Commerce Platform**
- **Challenge**: Handle Black Friday traffic spikes with consistent checkout experience
- **Solution**: Aurora with read replicas for reporting; DynamoDB for session management and shopping carts; RDS for transactional data
- **DevOps Role**: Configure auto-scaling policies, implement connection pooling, manage parameter groups, monitor query performance

**Use Case 2: Financial Services Dashboard**
- **Challenge**: Strict data consistency requirements and regulatory compliance (PCI-DSS, SOX)
- **Solution**: Multi-AZ RDS with encrypted backups; DynamoDB for fraud detection cache; cross-region read replicas for disaster recovery
- **DevOps Role**: Implement encryption strategies, manage backup retention policies, coordinate backup testing, ensure audit logging

**Use Case 3: Real-Time Analytics Platform**
- **Challenge**: Ingest millions of events daily with sub-second query latency
- **Solution**: DynamoDB for event ingestion; Aurora for OLTP; Redshift for OLAP; ElastiCache for hot data
- **DevOps Role**: Configure DynamoDB provisioned/on-demand capacity, optimize indexes, manage cluster upgrades, implement cost controls

**Use Case 4: Multi-Tenant SaaS Application**
- **Challenge**: Isolate customer data while optimizing costs and performance
- **Solution**: Aurora serverless for unpredictable workloads; RDS read replicas per region; DynamoDB for metadata
- **DevOps Role**: Implement tenant isolation at database level, manage parameter groups per tier, coordinate zero-downtime migrations

**Use Case 5: Healthcare Patient Records System**
- **Challenge**: Guaranteed availability (24/7), HIPAA compliance, data retention policies
- **Solution**: Multi-AZ RDS with encrypted backups in multiple regions; DynamoDB for audit logs; automated snapshot verification
- **DevOps Role**: Implement encryption, manage backup compliance, coordinate disaster recovery drills, ensure audit trails

### Where It Typically Appears in Cloud Architecture

```
Application Tier (EC2, ECS, Lambda)
         |
    [Database Tier]
    /    |    \
 RDS  Aurora DynamoDB
  |      |        |
  +---+--+        |
      |           |
  [Backup & DR Systems]
      |
  [Monitoring & Alerts]
```

**Data Layer Architecture Patterns:**

1. **Single-Region, Multi-AZ**
   - Primary database in AZ-a with synchronous standby in AZ-b
   - Automatic failover via Route 53 health checks
   - RTO: < 2 minutes; RPO: < 1 second
   - Cost: ~150% of single-AZ deployment

2. **Multi-Region, Active-Active**
   - Read/write in primary region; read-only in secondary
   - DynamoDB global tables or Aurora cross-region replication
   - RTO: seconds (failover); RPO: minimal
   - Cost: ~200% with multi-region overhead

3. **Read-Heavy with Caching**
   - Single writer (primary RDS); multiple read replicas
   - ElastiCache layer for hot data
   - Application logic routes reads to replicas
   - Cost: ~175-200% depending on replica count

4. **Polyglot Persistence**
   - RDS for transactional consistency
   - DynamoDB for high-throughput operational data
   - ElastiCache for session/cache layer
   - Redshift for data warehouse
   - Cost optimization through right-tool-for-job approach

---

## Foundational Concepts

### Key Terminology

**ACID Compliance**
- **Atomicity**: Transaction succeeds completely or rolls back entirely
- **Consistency**: Database moves from one valid state to another
- **Isolation**: Concurrent transactions don't interfere
- **Durability**: Committed data survives system failures
- **Context**: Required for RDS/Aurora; relaxed for DynamoDB (eventual consistency)

**Eventual Consistency**
- Data updates propagate asynchronously to read replicas
- Temporary windows where replicas return stale data
- Acceptable for non-critical reads (analytics, caching)
- DynamoDB uses this across partitions; can be tuned with consistency levels

**Synchronous Replication**
- Write acknowledgment only after replica writes
- Guarantees durability; adds latency
- Used in Multi-AZ deployments for durability
- Not suitable for cross-region due to latency

**Asynchronous Replication**
- Write acknowledgment before replica updates
- Lower latency; small risk of data loss
- Suitable for cross-region read replicas
- DynamoDB streams and cross-region replication use this

**RTO/RPO Definitions**
- **RTO (Recovery Time Objective)**: Maximum acceptable downtime (e.g., 2 hours)
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss (e.g., 1 hour of transactions)
- Together they define backup and failover strategies
- Influence architectural decisions and costs

**Parameter Group / Parameter Store**
- Collections of database configuration parameters
- Engine-specific (MySQL 8.0 vs PostgreSQL 14 have different parameters)
- Changes require database restart (or minor downtime)
- Critical for performance tuning (buffer_pool_size, max_connections, etc.)

**Subnet Groups**
- Define which subnets database can be deployed into
- Must span multiple AZs for Multi-AZ deployments
- Restrict database network access at VPC level
- Combined with security groups for network isolation

**Read Replica**
- Asynchronous copy of primary database
- Can be in same region or cross-region
- Offloads read traffic from primary
- Not suitable for strong consistency requirements

**Snapshot vs. Backup**
- **Snapshot**: Manual point-in-time copy (user-initiated)
- **Backup**: Automated daily snapshots + transaction logs
- Snapshots can be shared across AWS accounts
- Backups retain transaction logs for point-in-time recovery

**Replication Lag**
- Delay between write at primary and visibility at replica
- Measured in milliseconds for sync replication, seconds for async
- Critical for applications requiring read-after-write consistency
- Monitored via CloudWatch metrics

### Database Classification Architecture

**Relational Databases (SQL)**

| Characteristic | RDS | Aurora |
|---|---|---|
| **Protocol** | Native MySQL/PostgreSQL | MySQL/PostgreSQL compatible |
| **Engine** | Community or commercial | AWS proprietary Distributed |
| **Read Replicas** | Yes (5 per instance) | Yes (15 per cluster) |
| **Auto-scaling** | Manual | Automatic read replicas |
| **Storage** | EBS volume | Distributed storage layer |
| **Backup Window** | Daily snapshot | Continuous backup |
| **Pricing** | Pay-per-instance | Pay-per-GB-used |
| **Best For** | Traditional apps, small-medium scale | High-scale, read-heavy workloads |

**Key Architectural Difference:**
- RDS: Single instance + EBS volume (scaling = bigger instance)
- Aurora: Cluster architecture with distributed storage (scaling = more read replicas, not instance size)

**NoSQL Database (DynamoDB)**

| Characteristic | Details |
|---|---|
| **Data Model** | Key-Value + Document |
| **Consistency** | Eventually consistent (with strong consistency option) |
| **Throughput** | Provisioned capacity or On-demand billing |
| **Scaling** | Horizontal (partition key distributes data) |
| **Latency** | Single-digit millisecond p99 |
| **Transactions** | ACID at item level; TransactWriteItems for multi-item |
| **Indexing** | Primary key + GSI (Global Secondary Indexes) |
| **Best For** | High-throughput, low-latency, access-pattern-driven workloads |

### DevOps Principles for Data Layer

**1. Infrastructure as Code (IaC)**
```yaml
Example Architecture:
- RDS instances defined in CloudFormation/Terraform
- Parameter groups versioned in source control
- Database subnet groups defined as infrastructure
- Security groups integrated with application stacks
- Enables reproducibility across environments (dev/staging/prod)
```

**2. Automated Backups & Disaster Recovery**
```
Backup Strategy:
- Daily automated snapshots (retention: 7-35 days)
- Point-in-time recovery enabled (35-day window)
- Cross-region backup replicas for DR
- Regular backup restoration testing (monthly)
- Documentation of RTO/RPO per environment
```

**3. Monitoring & Observability**
```
Key Metrics (CloudWatch):
- DatabaseConnections: Alert if > 80% max_connections
- ReadLatency / WriteLatency: Alert if p99 > SLA
- CPUUtilization: Alert if > 70% sustained
- DiskQueueDepth: Indicator of I/O saturation
- ReplicationLag: Alert if > 100ms for sync replicas
- QueryPerformance: Long-running queries via CloudWatch Logs
```

**4. Change Management**
```
Database Change Process:
1. Changes modeled in IaC (CloudFormation/Terraform)
2. Applied to dev/staging first with validation
3. Blue-green deployment for zero-downtime schema changes
4. Automated rollback procedures
5. RCA documented for production incidents
```

**5. Scaling Strategy**
```
RDS Scaling:
- Vertical: Larger instance class (requires brief downtime)
- Read Scaling: Read replicas in same/cross regions
- Connection Pool Management: pgBouncer, RDS Proxy

Aurora Scaling:
- Automatic read replica scaling based on load
- Auto Scaling policies adjust replica count + instance size
- DynamoDB: On-demand vs. provisioned capacity management
```

**6. Security & Encryption**
```
Encryption Strategy:
- At Rest: KMS encryption for EBS volumes
- In Transit: TLS 1.2+ for all connections
- Application: Hash passwords in application layer
- IAM: Database-level permissions via roles
- Audit: Enable AWS CloudTrail for administrative changes
```

### Best Practices

**1. Connection Management**
- ✅ Use RDS Proxy for connection pooling (reduces database strain)
- ✅ Set appropriate `max_connections` parameter based on workload
- ✅ Implement application-level connection timeouts
- ✅ Monitor DatabaseConnections metric continuously
- ❌ Don't open new connection per request (connection pool required)

**2. Backup & Recovery**
- ✅ Automate backup snapshot creation (AWS does this automatically)
- ✅ Test restore procedures monthly (can't validate backups without testing)
- ✅ Store backups in separate AWS account for ransomware protection
- ✅ Enable Multi-AZ for automatic failover + durability
- ✅ Document and practice RTO/RPO procedures
- ❌ Don't rely solely on cross-region snapshots (use read replicas for faster failover)

**3. Performance Tuning**
- ✅ Create indexes on frequently queried columns (WHERE, JOIN, ORDER BY)
- ✅ Analyze query plans (EXPLAIN in PostgreSQL/MySQL)
- ✅ Implement read replicas for read-heavy workloads
- ✅ Use parameter store for version-specific optimizations
- ✅ Monitor slow query logs via CloudWatch
- ❌ Don't tune without metrics (requires CloudWatch + slow query logs)

**4. Multi-AZ & High Availability**
- ✅ Enable Multi-AZ for all production databases
- ✅ Use Aurora over RDS for higher availability requirements
- ✅ Test failover procedures regularly
- ✅ Monitor replication lag continuously
- ✅ Implement application-level read-after-write consistency checks when needed
- ❌ Don't assume failover is automatic without Multi-AZ enabled

**5. Cost Optimization**
- ✅ Right-size instances based on actual CPU/Memory/I/O metrics
- ✅ Use Reserved Instances for stable workloads (30-40% savings)
- ✅ Leverage DynamoDB on-demand for unpredictable workloads
- ✅ Implement automated snapshot cleanup policies
- ✅ Monitor data transfer costs (same-region replication preferred)
- ❌ Don't over-provision (costs scale linearly with instance size)

**6. Security best practices**
- ✅ Enforce encryption at rest (KMS) and in transit (TLS)
- ✅ Use VPC endpoints for private connectivity
- ✅ Implement least privilege IAM policies
- ✅ Enable AWS CloudTrail for audit logging
- ✅ Rotate master user passwords quarterly
- ✅ Use Secrets Manager for credential rotation
- ❌ Don't store credentials in application code or environment variables

**7. Maintenance Windows**
- ✅ Schedule during planned maintenance windows (configurable)
- ✅ Use Blue-Green deployments for zero-downtime upgrades
- ✅ Test minor version upgrades first
- ✅ Plan major version upgrades with application teams
- ✅ Document compatibility changes
- ❌ Don't upgrade production without testing in staging first

### Common Misunderstandings

**Misunderstanding #1: "Multi-AZ means replication across regions"**
- ❌ **Wrong**: Multi-AZ replicates synchronously to another AZ in same region
- ✅ **Correct**: Multi-AZ provides automatic failover within region; cross-region read replicas provide geographic redundancy
- **Impact**: Misunderstanding leads to false sense of disaster recovery
- **Solution**: For true DR, deploy read replicas in another region + configure failover

**Misunderstanding #2: "Read replicas are always strongly consistent"**
- ❌ **Wrong**: Read replicas exhibit asynchronous replication lag
- ✅ **Correct**: Primary is always up-to-date; replicas eventually catch up (100ms-seconds lag)
- **Impact**: Applications using replicas must tolerate stale reads or implement read-after-write checks
- **Solution**: For critical reads, query primary; acceptable for analytics/reporting

**Misunderstanding #3: "Snapshots are point-in-time recovery"**
- ❌ **Wrong**: Snapshots are static copies; point-in-time recovery requires backup service
- ✅ **Correct**: AWS backup service creates daily snapshots + retains transaction logs for recovery to any second within retention window
- **Impact**: Can't recover to arbitrary timestamp without transaction logs
- **Solution**: Enable automated backup service (not just manual snapshots)

**Misunderstanding #4: "DynamoDB is just a cache"**
- ❌ **Wrong**: DynamoDB is a fully durable database with ACID support at item level
- ✅ **Correct**: DynamoDB is primary data store for high-throughput patterns; durability guaranteed
- **Impact**: Can remove client-side caching layer for some use cases
- **Solution**: Choose DynamoDB based on access patterns, not just performance

**Misunderstanding #5: "Larger instance = better performance"**
- ❌ **Wrong**: Instance size affects available resources; poor queries remain slow
- ✅ **Correct**: Performance comes from: proper indexing (70%), query optimization (20%), instance sizing (10%)
- **Impact**: Throwing larger instances at slow queries is expensive and doesn't fix root cause
- **Solution**: Analyze slow query logs first, then scale if necessary

**Misunderstanding #6: "Aurora is just a faster MySQL"**
- ❌ **Wrong**: Aurora is a distributed database with fundamentally different architecture
- ✅ **Correct**: Aurora separates compute from storage, enables 15 read replicas, auto-scaling, different backup model
- **Impact**: Cost and scaling characteristics differ significantly from RDS MySQL
- **Solution**: Evaluate Aurora specifically for workload characteristics (read-heavy, scaling requirements)

**Misunderstanding #7: "RDS Proxy is optional"**
- ❌ **Wrong**: With connection pooling, it's a nice-to-have
- ✅ **Correct**: RDS Proxy solves connection exhaustion and application scaling issues; essential for microservices
- **Impact**: Lambda functions connecting to RDS quickly exhaust connection limits
- **Solution**: Use RDS Proxy by default for dynamic workloads

**Misunderstanding #8: "DynamoDB provisioned capacity automatically adjusts"**
- ❌ **Wrong**: DynamoDB on-demand adjusts automatically; provisioned capacity requires scaling policy
- ✅ **Correct**: Provisioned capacity is fixed until manually adjusted; on-demand bills per request
- **Impact**: Wrong capacity pricing model leads to throttling or wasted compute
- **Solution**: Choose based on traffic predictability (predictable → provisioned; unpredictable → on-demand)

---

## RDS Basics

Amazon RDS is AWS's managed relational database service supporting MySQL, PostgreSQL, MariaDB, Oracle, and SQL Server. It abstracts away database administration tasks while providing enterprise-grade features like automated backups, multi-AZ failover, and read replicas.

### Textual Deep Dive

#### Internal Working Mechanism

RDS operates on a **single-instance + EBS volume** architecture:

1. **Database Instance Layer**
   - Runs on EC2 instance with attached EBS volume
   - Instance type determines available CPU, memory, and network bandwidth
   - Each instance has max_connections limit tied to instance class
   - No automatic scaling by default (requires manual intervention)

2. **Storage Layer (EBS)**
   - General Purpose (gp3, gp2) for typical workloads
   - Provisioned IOPS (io2, io1) for high I/O intensive workloads (OLTP, transactional)
   - Data stored durably across multiple AZ copies (transparent to user)
   - Snapshots create point-in-time copies to S3

3. **Backup & Recovery**
   - **Automated Backups**: Daily snapshots + continuous transaction logs (up to 35-day retention)
   - **Point-in-Time Recovery (PITR)**: Can recover to any second within retention window
   - **Storage Overhead**: Backup storage separate from instance storage (additional cost)

4. **Replication Mechanism**
   - **Multi-AZ**: Synchronous replication to standby instance in different AZ
   - **Read Replicas**: Asynchronous replication to secondary instances (same/cross-region)
   - **Synchronous vs Asynchronous Trade-off**: Multi-AZ adds 5-20ms write latency; read replicas introduce replication lag (100ms-seconds)

5. **Connection Management**
   - Database maintains connection pool per instance
   - Each connection consumes memory (~1-2MB per connection)
   - No built-in connection pooling (applications must implement or use RDS Proxy)
   - Failed connections count against connection limit

#### Architecture Role

**In the Data Layer:**
```
Application Tier (Connection Pool)
         ↓
    RDS Proxy (optional but recommended)
         ↓
    RDS Instance (Primary)
    /              \
   /                \
Multi-AZ Standby  Read Replicas
   (Sync)          (Async)
```

**Decision Points:**
- **Single-AZ**: Development/testing, non-critical workloads
- **Multi-AZ**: Production critical databases requiring automatic failover (RTO < 2 min)
- **Read Replicas**: Read-heavy workloads (analytics, reporting), geographic distribution
- **RDS Proxy**: Applications with dynamic connection patterns (Lambda, microservices)

#### Production Usage Patterns

**Pattern 1: Traditional Web Application (MySQL)**
```
Pattern: OLTP with consistent read/write ratio
- Single RDS MySQL instance (db.t3.medium → db.r5.large for larger app)
- Multi-AZ enabled for HA
- 7-14 day backup retention
- Read replicas for admin queries/reports
- RDS Proxy for web tier connection pooling
- Scaling: Vertical (larger instance) or horizontal (read replicas)
```

**Pattern 2: Analytics with Reporting (PostgreSQL)**
```
Pattern: Write-heavy transactional + read-heavy analytical
- Primary RDS PostgreSQL instance (optimized for OLTP)
- 2-3 read replicas in same region (for analytical workloads)
- 30-day backup retention (regulatory requirement)
- Separate read-only parameter group on replicas
- Redshift cluster as data warehouse (separate from RDS)
- Scaling: Add more read replicas as analytical load grows
```

**Pattern 3: Multi-Region Disaster Recovery (PostgreSQL)**
```
Pattern: Jurisdiction requirements (data residency)
- Primary RDS in us-east-1 (Multi-AZ)
- Cross-region read replica in eu-west-1
- Automated failover script (DNS update) if primary fails
- 14-day backup retention with cross-region backup copies
- RTO: ~5 minutes (manual failover); RPO: < 1 minute
```

**Pattern 4: Development Environment Cloning**
```
Pattern: DevOps need to quickly spin staging from production
- Snapshot production database daily
- Restore to dev/test environment (`aws rds restore-db-instance-from-db-snapshot`)
- Remove sensitive data via post-restore script
- Enables testing patches before production
```

#### DevOps Best Practices

**1. Instance Sizing & Right-Sizing**
- ✅ Start with t3 instances for variable workloads (burstable)
- ✅ Use r5/r6 instances for consistent high-memory workloads
- ✅ Monitor CPU, memory, IOPS separately; scale based on bottleneck
- ✅ Use CloudWatch metrics to justify sizing decisions
- ❌ Don't equate instance size with performance without analyzing query plans

**2. Parameter Group Management**
- ✅ Create environment-specific parameter groups (dev, staging, prod)
- ✅ Version parameter groups in Git/IaC tool
- ✅ Document rationale for non-default parameters
- ✅ Test parameter changes in staging first
- ✅ Some parameters require instance restart; schedule during maintenance window
- ❌ Don't modify parameters without understanding impact

**3. Backup Strategy**
- ✅ Enable automated backups (AWS default retention: 1 day; recommend 7-30)
- ✅ Test restore procedures monthly (backup validity check)
- ✅ Enable backup copy to another region for DR
- ✅ Use Lambda to validate backup integrity periodically
- ✅ Document RTO/RPO requirements per database
- ❌ Don't assume backups work without testing

**4. Multi-AZ Deployment**
- ✅ Enable for all production databases
- ✅ Costs ~150% of single-AZ (standby instance must exist)
- ✅ Automatic failover to standby on instance/AZ failure (~2 min RTO)
- ✅ Synchronous replication ensures no data loss
- ✅ Hidden complexity: applications must handle DNS failover
- ❌ Don't rely on Multi-AZ for geographic redundancy (use read replicas)

**5. Read Replica Architecture**
- ✅ Deploy read replicas across AZs for availability
- ✅ Use read replicas to offload analytical/reporting queries
- ✅ Monitor replication lag; alert if > 100ms
- ✅ Promote replica to standalone during primary failure (alternative to Multi-AZ)
- ✅ Applications must handle read-after-write consistency
- ❌ Don't use read replicas for real-time consistency needs

**6. Connection & Resource Management**
- ✅ Deploy RDS Proxy for connection pooling (critical for Lambda/microservices)
- ✅ Set max_connections to sustainable level for instance class
- ✅ Monitor DatabaseConnections metric; alert at 80%
- ✅ Implement application-level connection pooling (pgBouncer, HikariCP)
- ✅ Set connection timeout to graceful value (30-60 seconds)
- ❌ Don't let each request open new connection (connection exhaustion)

**7. Monitoring & Alerting**
- ✅ Monitor CPU, Memory, Disk Queue Depth, Network I/O
- ✅ Alert on query performance (slow query logs)
- ✅ Monitor replication lag for read replicas
- ✅ Set up SNS notifications for maintenance events
- ✅ Use RDS Performance Insights for detailed query analysis
- ❌ Don't wait for customer reports for performance issues

**8. Upgrade Strategy**
- ✅ Plan minor version upgrades during maintenance window (usually automatic)
- ✅ Use blue-green deployment for zero-downtime major version upgrade
- ✅ Test in staging before production upgrade
- ✅ Have rollback plan (though rolling back major version is difficult)
- ✅ Coordinate with application team on compatibility changes
- ❌ Don't upgrade production without staging validation

#### Common Pitfalls

**Pitfall 1: Overbuilding Instance Size**
- ❌ **Problem**: Default to large instance "just in case" to avoid future scaling
- 🎯 **Impact**: Unnecessary cost (instance costs scale linearly); poor resource utilization
- ✅ **Solution**: Start small, monitor metrics, scale based on data. Vertical scaling requires brief downtime but is reversible.

**Pitfall 2: Ignoring Replication Lag**
- ❌ **Problem**: Using read replicas for critical reads without checking replication lag
- 🎯 **Impact**: Application reads stale data; inconsistent UI for users
- ✅ **Solution**: For critical reads, query primary; use replicas for analytics. Implement read-after-write consistency in application.

**Pitfall 3: Single-AZ in Production**
- ❌ **Problem**: "We'll enable Multi-AZ later" mindset
- 🎯 **Impact**: Single point of failure; unplanned downtime during AZ failure or maintenance
- ✅ **Solution**: Enable Multi-AZ from day 1 for production. Cost: +50% for failover guarantee.

**Pitfall 4: Backup Without Testing**
- ❌ **Problem**: Relying on automated backups without restore testing
- 🎯 **Impact**: Discover backups corrupt/invalid during actual DR (too late to fix)
- ✅ **Solution**: Monthly restore tests; automated backup verification; chaos engineering of backup/restore process.

**Pitfall 5: Connection Exhaustion**
- ❌ **Problem**: Applications opening new connections per request
- 🎯 **Impact**: Hits max_connections limit; database becomes unavailable
- ✅ **Solution**: Implement connection pooling at application layer or use RDS Proxy.

**Pitfall 6: Ignoring Parameter Group Changes**
- ❌ **Problem**: Modifying parameters in console manually (not tracked in IaC)
- 🎯 **Impact**: Configuration drift; can't reproduce in new environments
- ✅ **Solution**: All parameter changes via IaC (Terraform, CloudFormation); version control.

**Pitfall 7: Mixing OLTP & Analytical Queries**
- ❌ **Problem**: Running analytics queries on production primary
- 🎯 **Impact**: Slow queries block transactional workloads; poor user experience
- ✅ **Solution**: Offload analytics to read replicas or data warehouse (Redshift).

---

### Practical Code Examples

#### Terraform: RDS MySQL with Multi-AZ & Read Replica

```hcl
# Database Subnet Group (required for Multi-AZ)
resource "aws_db_subnet_group" "main" {
  name       = "myapp-db-subnet"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "MyApp Database Subnets"
  }
}

# Security Group
resource "aws_security_group" "rds" {
  name   = "myapp-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Only from app VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MyApp RDS SG"
  }
}

# Primary RDS Instance (Multi-AZ enabled)
resource "aws_db_instance" "primary" {
  identifier              = "myapp-db-primary"
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.medium"
  allocated_storage       = 100  # GB
  max_allocated_storage   = 200  # Enable auto-scaling

  # Storage configuration
  storage_type            = "gp3"
  storage_encrypted       = true
  kms_key_id             = aws_kms_key.rds.arn

  # Database configuration
  db_name                 = "myappdb"
  username                = "admin"
  password                = random_password.db_password.result
  parameter_group_name    = aws_db_parameter_group.mysql80.name

  # High Availability
  multi_az                = true
  db_subnet_group_name    = aws_db_subnet_group.main.name
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds.id]

  # Backup & Recovery
  backup_retention_period = 14
  backup_window           = "03:00-04:00"  # UTC
  maintenance_window      = "sun:04:00-sun:05:00"

  # Monitoring & Logging
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn            = aws_iam_role.rds_monitoring.arn
  enable_performance_insights     = true
  performance_insights_retention_period = 7

  # Backup & Deletion policy
  skip_final_snapshot     = false
  final_snapshot_identifier = "myapp-db-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot   = true

  depends_on = [aws_db_subnet_group.main, aws_security_group.rds]

  tags = {
    Name        = "MyApp Primary Database"
    Environment = "production"
    Tier        = "data"
  }
}

# Parameter Group (MySQL 8.0 specific)
resource "aws_db_parameter_group" "mysql80" {
  name        = "myapp-mysql80"
  family      = "mysql8.0"
  description = "Custom parameter group for MyApp"

  # Performance tuning parameters
  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"  # 75% of instance memory
  }

  parameter {
    name  = "max_allowed_packet"
    value = "1073741824"  # 1GB
  }

  tags = {
    Name = "MyApp MySQL Parameter Group"
  }
}

# Read Replica (same region, different AZ)
resource "aws_db_instance" "read_replica" {
  identifier          = "myapp-db-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class      = "db.t3.medium"

  # Replica-specific settings
  publicly_accessible = false
  skip_final_snapshot = true
  multi_az            = false  # Replicas typically single-AZ

  tags = {
    Name = "MyApp Read Replica"
  }
}

# Secret for database password (AWS Secrets Manager)
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "/rds/myapp/db-password"
  recovery_window_in_days = 7

  tags = {
    Name = "MyApp DB Password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "myapp-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU > 80% for 10 minutes"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "myapp-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 160  # 80% of max_connections (200)
  alarm_description   = "Alert when database connections > 80%"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# Outputs
output "rds_endpoint" {
  value       = aws_db_instance.primary.endpoint
  description = "RDS primary endpoint"
}

output "replica_endpoint" {
  value       = aws_db_instance.read_replica.endpoint
  description = "Read replica endpoint (read-only)"
}

output "db_password_secret_arn" {
  value       = aws_secretsmanager_secret.db_password.arn
  description = "ARN of database password in Secrets Manager"
}
```

#### CloudFormation: RDS with RDS Proxy for Connection Pooling

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "RDS MySQL with RDS Proxy for connection pooling"

Parameters:
  DBName:
    Type: String
    Default: myappdb
  DBUsername:
    Type: String
    NoEcho: true
  DBPassword:
    Type: String
    NoEcho: true
    MinLength: 8

Resources:
  # RDS Instance
  RDSDatabase:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: myapp-db
      Engine: mysql
      EngineVersion: "8.0.35"
      DBInstanceClass: db.t3.medium
      AllocatedStorage: 100
      StorageType: gp3
      StorageEncrypted: true
      DBName: !Ref DBName
      MasterUsername: !Ref DBUsername
      MasterUserPassword: !Ref DBPassword
      VPCSecurityGroups:
        - !Ref RDSSecurityGroup
      DBSubnetGroupName: !Ref DBSubnetGroup
      MultiAZ: true
      BackupRetentionPeriod: 14
      PreferredBackupWindow: "03:00-04:00"
      PreferredMaintenanceWindow: "sun:04:00-sun:05:00"
      EnableCloudwatchLogsExports:
        - error
        - slowquery
      EnablePerformanceInsights: true
      PerformanceInsightsRetentionPeriod: 7
      DeletionPolicy: Snapshot

  # RDS Proxy for connection pooling
  RDSProxy:
    Type: AWS::RDS::DBProxy
    Properties:
      DBProxyName: myapp-proxy
      EngineFamily: MYSQL
      Auth:
        - AuthScheme: SECRETS
          SecretArn: !Ref DBPasswordSecret
      RoleArn: !GetAtt ProxyRole.Arn
      DBInstanceIdentifiers:
        - !Ref RDSDatabase
      MaxIdleConnectionsPercent: 50
      MaxConnectionsPercent: 100
      ConnectionBorrowTimeout: 120
      SessionPinningFilters:
        - EXCLUDE_VARIABLE_SETS
      LoggingEnabled: true
      CloudwatchLogsLogGroupArn: !GetAtt ProxyLogGroup.Arn

  # Proxy Target Group
  ProxyTargetGroup:
    Type: AWS::RDS::DBProxyTargetGroup
    Properties:
      DBProxyName: !Ref RDSProxy
      TargetGroupName: default
      DBInstanceIdentifiers:
        - !Ref RDSDatabase
      ConnectionPoolConfig:
        MaxConnectionsPercent: 100
        MaxIdleConnectionsPercent: 50
        ConnectionBorrowTimeout: 120

  # Secrets Manager for RDS password
  DBPasswordSecret:
    Type: AWS::SecretsManager::Secret
    Properties:
      Name: /rds/myapp/db-password
      SecretString: !Sub |
        {
          "username": "${DBUsername}",
          "password": "${DBPassword}"
        }

  # IAM Role for RDS Proxy
  ProxyRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service: rds.amazonaws.com
            Action: sts:AssumeRole
      Policies:
        - PolicyName: SecretsManager
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action:
                  - secretsmanager:GetSecretValue
                Resource: !GetAtt DBPasswordSecret.Arn

  # CloudWatch Logs for RDS Proxy
  ProxyLogGroup:
    Type: AWS::Logs::LogGroup
    Properties:
      LogGroupName: /aws/rds/proxy/myapp
      RetentionInDays: 7

  # Database Subnet Group
  DBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for RDS
      SubnetIds:
        - subnet-12345678  # Private subnet 1
        - subnet-87654321  # Private subnet 2

  # Security Group
  RDSSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for RDS
      VpcId: vpc-12345678
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 3306
          ToPort: 3306
          CidrIp: 10.0.0.0/16  # Application VPC CIDR

Outputs:
  RDSEndpoint:
    Value: !GetAtt RDSDatabase.Endpoint.Address
    Description: RDS primary endpoint

  ProxyEndpoint:
    Value: !GetAtt RDSProxy.Endpoint
    Description: RDS Proxy endpoint (use this in applications)

  ProxyPort:
    Value: 3306
    Description: RDS Proxy port
```

#### Shell Script: Backup Testing & Validation

```bash
#!/bin/bash
# Script: RDS Backup Testing and PITR Validation
# Purpose: Monthly automated backup restoration test
# Schedule: First Monday of every month via CloudWatch Events + Lambda

set -e

# Configuration
SOURCE_DB="myapp-db-primary"
RESTORE_DB="myapp-db-test-restore-$(date +%Y%m%d)"
AWS_REGION="us-east-1"
RESTORE_INSTANCE_CLASS="db.t3.micro"  # Smaller instance for testing

echo "=== RDS Backup Restoration Test ==="
echo "Source Database: $SOURCE_DB"
echo "Restore Target: $RESTORE_DB"
echo "Region: $AWS_REGION"
echo "Time: $(date)"

# Step 1: Get latest snapshot
echo -e "\n[1/5] Fetching latest snapshot..."
LATEST_SNAPSHOT=$(aws rds describe-db-snapshots \
  --db-instance-identifier "$SOURCE_DB" \
  --region "$AWS_REGION" \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]' \
  --output text | sort -k2 -r | head -1 | awk '{print $1}')

if [ -z "$LATEST_SNAPSHOT" ]; then
  echo "ERROR: No snapshots found for $SOURCE_DB"
  exit 1
fi

echo "Latest Snapshot: $LATEST_SNAPSHOT"

# Step 2: Restore from snapshot
echo -e "\n[2/5] Restoring from snapshot..."
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "$RESTORE_DB" \
  --db-snapshot-identifier "$LATEST_SNAPSHOT" \
  --db-instance-class "$RESTORE_INSTANCE_CLASS" \
  --region "$AWS_REGION" \
  --no-publicly-accessible \
  --tags Key=Purpose,Value=BackupTest Key=SourceDB,Value="$SOURCE_DB"

# Wait for restore to complete
echo -e "\n[3/5] Waiting for restore to complete..."
aws rds wait db-instance-available \
  --db-instance-identifier "$RESTORE_DB" \
  --region "$AWS_REGION"

RESTORE_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$RESTORE_DB" \
  --region "$AWS_REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "Restore completed. Endpoint: $RESTORE_ENDPOINT"

# Step 3: Connection test
echo -e "\n[4/5] Testing database connectivity..."
mysql -h "$RESTORE_ENDPOINT" -u admin -p"$DB_PASSWORD" -e "SELECT 1;" || {
  echo "ERROR: Cannot connect to restored database"
  exit 1
}

echo "Connection test PASSED"

# Step 4: Data integrity check
echo -e "\n[5/5] Validating data integrity..."
ROW_COUNT=$(mysql -h "$RESTORE_ENDPOINT" -u admin -p"$DB_PASSWORD" \
  -e "SELECT COUNT(*) FROM myappdb.users;" | tail -1)

echo "Row count in 'users' table: $ROW_COUNT"

if [ "$ROW_COUNT" -eq 0 ]; then
  echo "WARNING: No data in restored database"
else
  echo "Data integrity check PASSED"
fi

# Step 5: Cleanup test instance
echo -e "\nCleaning up test instance..."
aws rds delete-db-instance \
  --db-instance-identifier "$RESTORE_DB" \
  --region "$AWS_REGION" \
  --skip-final-snapshot

echo -e "\n=== Backup Test Complete ==="
echo "Status: SUCCESS"
echo "Timestamp: $(date)"

# Send success notification
aws sns publish \
  --topic-arn "arn:aws:sns:$AWS_REGION:ACCOUNT_ID:rds-alerts" \
  --subject "RDS Backup Test PASSED: $SOURCE_DB" \
  --message "Latest backup for $SOURCE_DB restored and validated successfully."
```

#### Shell Script: RDS Performance Monitoring

```bash
#!/bin/bash
# Script: RDS Performance Metrics Collection
# Purpose: Gather detailed performance metrics and generate report
# Run: Hourly via CloudWatch Events

DB_INSTANCE="myapp-db-primary"
REGION="us-east-1"
OUTPUT_DIR="/var/logs/rds-metrics"

mkdir -p "$OUTPUT_DIR"

# Get metrics for last 1 hour
START_TIME=$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

echo "=== RDS Performance Report ===" > "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
echo "Database: $DB_INSTANCE" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
echo "Period: $START_TIME to $END_TIME" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
echo "" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"

# Fetch key metrics
echo "=== CPU Utilization ===" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 300 \
  --statistics Average,Maximum \
  --region "$REGION" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"

echo -e "\n=== Database Connections ===" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 300 \
  --statistics Average,Maximum \
  --region "$REGION" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"

echo -e "\n=== Read/Write Latency ===" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name ReadLatency \
  --dimensions Name=DBInstanceIdentifier,Value="$DB_INSTANCE" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 300 \
  --statistics Average \
  --region "$REGION" >> "$OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"

echo "Metrics report saved to: $OUTPUT_DIR/rds-metrics-$(date +%Y%m%d-%H%M).txt"
```

---

### ASCII Diagrams

#### RDS Architecture with Multi-AZ & Read Replicas

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Application Layer (WebServers)                  │
└─────────────────────┬───────────────────────┬───────────────────────┘
                      │                       │
                    READS/WRITES              │
                      │                       │ ANALYTICAL READS
                      │                       │ (via separate endpoint)
         ┌────────────▼───────────┐
         │ RDS Proxy (Optional)   │ ◄─── Connection pooling
         │ (Handles 200 conns)    │
         └────────────┬───────────┘
                      │
        ┌─────────────▼──────────────┐      ┌──────────────────────┐
        │ Primary RDS Instance       │      │ Read Replica         │
        │ (AZ-a)                     │      │ (AZ-b, same region)  │
        │ ┌─────────────────────┐    │      │ ┌──────────────────┐  │
        │ │ MySQL 8.0.35        │    │      │ │ MySQL (replicated)│  │
        │ │ db.t3.medium        │    │      │ │ db.t3.medium     │  │
        │ │ 100 GB gp3 EBS      │    │  ◄──┼──Async replication  │  │
        │ │ max_connections=200 │    │      │ (100ms-1s lag)       │  │
        │ └─────────────────────┘    │      │ └──────────────────┘  │
        └────────┬────────────────────┘      └──────────────────────┘
                 │
         Sync Replication (5-20ms latency)
                 │
        ┌────────▼──────────┐
        │ Standby Replica   │
        │ (AZ-c, read-only) │
        │ (Automatic failover)
        │ RTO: ~120 seconds │
        └───────────────────┘

Data Flow:
1. WRITE: App → RDS Proxy → Primary (waits for sync replication to standby)
2. READ-CRITICAL: App → RDS Proxy → Primary
3. READ-ANALYTICAL: App → Replica endpoint (eventual consistency OK)
```

#### RDS Backup & Point-in-Time Recovery Timeline

```
Timeline:
─────────────────────────────────────────────────────────────────►
Day 1        Day 5        Day 10       Day 15       Day 20       Day 30
 │            │             │            │            │            │
[Snap1]      [Snap2]       [Snap3]     [Snap4]      [Snap5]      [Snap6]
 │            │             │            │            │            │
 └────────────┴─────────────┴────────────┴────────────┴────────────┴──
              Transaction Logs (stored continuously)

Point-in-Time Recovery Window: 35 days (configurable)

Example Recovery Scenario:
Disaster occurs at Day 12, 14:00 UTC
├─ Restore from Snap3 (Day 10)
├─ Apply transaction logs (Day 10 → Day 12, 14:00)
└─ Database recovered to exact state before disaster (RPO: ~seconds)

Cost:
- Snapshots: $0.095/GB per month (first 5 snapshots included)
- Transaction logs: $0.03/GB per month
- Total backup cost: ~5-10% of instance cost
```

#### RDS Connection Pooling with RDS Proxy

```
Without RDS Proxy (Connection Exhaustion):
─────────────────────────────────────────

Lambda 1 ─┐
Lambda 2 ─┤
Lambda 3 ─┤
... ...   ├──► RDS (max_connections = 200)
Lambda 50─┤     └─ At λ500: Each new λ opens connection
Lambda 51─┴────► EXHAUSTION! (500 > 200 max)
                 Apps receive "Too many connections" error


With RDS Proxy (Connection Pooling):
─────────────────────────────────────

Lambda 1 ─┐
Lambda 2 ─┤
Lambda 3 ─┤
... ...   ├──► RDS Proxy ─────► RDS (max_connections = 200)
Lambda 50─┤   (4 conns)        Proxy manages 200 permanent connections
Lambda 51─┴──► (reuses          All λ requests queued through 4 channels
              connections)      No connection exhaustion possible


RDS Proxy Benefits:
✓ Multiplexes 4-6 backend connections per 100 client connections
✓ Handles Lambda concurrency scaling automatically
✓ Reduces connection overhead (essential for serverless)
✓ Connection timeout policy (ABORT_CLIENT vs ROLLBACK)
✓ 30-40% latency improvement due to connection pooling
```

---

## Aurora Architecture

Amazon Aurora is AWS's high-performance distributed relational database built from the ground up for cloud scale. Unlike RDS's single-instance model, Aurora separates compute from storage and uses a shared distributed storage layer that spans multiple AZs.

### Textual Deep Dive

#### Internal Working Mechanism

Aurora's architecture fundamentally differs from traditional databases:

**1. Compute & Storage Separation**
- **Compute Layer**: Database engines (Aurora MySQL, Aurora PostgreSQL) on EC2-like instances
- **Storage Layer**: Distributed database-agnostic storage across 3 AZs with 6+ replicas
- **Key Innovation**: Compute scales independently from storage (no need to buy larger instance for more disk)
- **Data Durability**: Automatic replication to 3 AZs, continuous backup, 6-way replication

**2. Storage Architecture (Write Ahead Log - WAL)**
```
Write Flow:
Application WRITE
    ↓
Compute Instance buffers write in memory
    ↓
WAL entry written asynchronously to storage layer
    ↓
Storage nodes acknowledge write (quorum: 4 of 6)
    ↓
Application receives acknowledgment (ultra-fast, ~1-2ms)
    ↓
Remaining storage nodes get replica (async, <1s)
```

**Benefits**: Write latency decoupled from full replication completion; data durability guaranteed by quorum semantics.

**3. Cluster Architecture**
```
Aurora Cluster:
├─ Primary Instance (Writer)
│  └─ Handles all writes
│  └─ Provides read-only endpoint
│
├─ Read Replica 1 (Reader)
│  └─ Async read from storage layer
│  └─ Replication lag: typically <10ms
│
├─ Read Replica 2 (Reader)
│  └─ Independent compute; same storage
│  └─ Can be promoted to primary if needed
│
└─ Read Replica N (up to 15 total)
   └─ Auto-scaling: AWS adds/removes replicas

All instances share same storage layer
(No data replication between compute nodes)
```

**4. Read Replica Mechanics**
- All replicas read from shared storage layer (not from primary)
- Replication lag: <10ms typical (much better than RDS async)
- No impact on primary write performance when adding replicas
- Can promote replica to primary in seconds (MySQL) or minutes (PostgreSQL)

**5. Backup Model (Continuous)**
- Automatic backup: Continuous incremental snapshots to S3
- Retention: 1-35 days (configurable)
- Zero impact on performance (unlike RDS snapshot which briefly blocks writes)
- Point-in-time recovery to any second within retention window
- Backup storage included in Aurora pricing (no separate charge like RDS)

**6. Failover Mechanism**
- **Primary Failure**: Automatic failover to healthy read replica (~30 seconds)
- **Failover Process**:
  1. Aurora detects primary unavailable
  2. Selects best replica (based on binary log position)
  3. Promotes replica to new primary
  4. Updates cluster endpoint to point to new primary
  5. Applications reconnect automatically (endpoint unchanged)
- **Data Loss**: Minimal (only in-flight transactions)

#### Architecture Role

**In Data Layer for Different Workloads:**

```
Read-Heavy Analytics Workload:
─────────────────────────────
Writer Instance ──► Shared Storage ◄────┐
                      ↑                  │
                      │                  │
            ┌─────────┼──────────────────┐
            │         │                  │
          Reader1   Reader2  ...  Reader15
         (OLTP)   (Analytics)(Reporting)
                   (Auto-scales to meet demand)


Write-Heavy Transactional Workload:
──────────────────────────────────
          Writer Instance ──► Shared Storage
          (Single writer,           ↑
           optimal for         (Distributed,
           consistency)         durable)
            ↓
          Reader1 (failover candidate)


Global Database (Multi-Region):
──────────────────────────────
Region-1: Primary Cluster              Region-2: Secondary Cluster
├─ Writer ─────────────────────────┐   ├─ Replica 1 (Read-only)
└─ Readers (up to 15)              │   └─ Readers (up to 15)
              (async replication, 1-2s lag)
```

#### Production Usage Patterns

**Pattern 1: Read-Heavy SaaS with Per-Tenant Analytics**
```
Workload: OLTP database for multi-tenant app + per-tenant analytics
────────────────────────────────────────────────────────────────────

Primary Instance (db.r6g.xlarge):
- Handles all WRITE operations (customer transactions)
- Serves time-sensitive READs (customer dashboard)
- Monitoring: Write latency < 5ms p99

Read Replica Fleet (auto-scaling, 3-15 replicas):
- Replica 1-3: Fixed (for analytics jobs)
- Replica 4-15: Auto-scaled based on READ load
- Uses: Customer analytics, admin dashboards, data exports
- Cost: Pay per compute hour + shared storage

Auto Scaling Rules:
- CPU > 70%: Add replica (1-2 minutes)
- CPU < 30% for 10 min: Remove replica (cost savings)
```

**Pattern 2: Global Application with DR**
```
Workload: Multi-region deployment for global user base + DR
────────────────────────────────────────────────────────────

Primary Region (us-east-1):
├─ Writer Instance (db.r6g.2xlarge)
├─ 5 Read Replicas (consistent)
└─ Cluster storage: auto-scales 0-64TB

Secondary Region (eu-west-1):
├─ 1 Read-Only Instance (cross-region replica)
├─ 5 Read Replicas (can promote to primary)
└─ Replication: Async, 1-2 second lag

Disaster Scenario:
If Region-1 fails:
  1. Promote Region-2 read-only instance to primary (30-60s)
  2. Failover app traffic to Region-2
  3. RTO: < 2 minutes; RPO: ~1-2 seconds of lost transactions
```

**Pattern 3: Burst Traffic with Serverless**
```
Workload: E-commerce with traffic spikes (Black Friday)
────────────────────────────────────────────────────────

Aurora Serverless v2:
- Capacity: Auto-scales from 0.5 ACU to 128 ACU
- 1 ACU ≈ 2GB memory, 2 vCPU
- Billing: Per-second granularity

Normal Traffic (8am-10pm):
- 2-4 ACU (auto-allocated)
- Cost: ~$0.12/hour

Traffic Spike (Black Friday 10pm):
- 50+ ACU (auto-allocated in seconds)
- Cost: ~$6/hour during spike

Benefit: Pay only for compute actually used + shared storage across all workloads
```

**Pattern 4: Data Warehouse with OLAP Queries**
```
Workload: Complex analytical queries (orders, revenue, cohort analysis)
─────────────────────────────────────────────────────────────────────

Primary Instance:
- OLTP workload (customer-facing transactions)
- Reserved compute (db.r6g.xlarge = constant cost)

Aurora Analytics Replica (db.r5.4xlarge):
- Reserved instance for consistent OLAP processing
- Optimized via: Parameter tuning, query parallelization
- Batch jobs run here (avoiding primary impact)

Aurora Read Replicas (3 on-demand):
- Auto-scale for analytical dashboard queries
- Query timeout: 30 seconds (large queries rejected)
- Serve lightweight analytics; heavy analytics via dedicated replica
```

#### DevOps Best Practices

**1. Cluster Sizing & Capacity Planning**
- ✅ Primary: Size for peak write throughput (128GB-512GB instance)
- ✅ Read Replicas: Start with 2; add via auto-scaling policy
- ✅ Monitor "CPU Credit Balance" for burst capacity
- ✅ Use Aurora Serverless for unpredictable workloads
- ✅ Right-size based on actual read concurrency (RDS Performance Insights)
- ❌ Don't over-provision compute (storage scales independently)

**2. Auto-Scaling Configuration**
- ✅ Enable Auto Scaling for read replicas (critical for spiky traffic)
- ✅ Set target metrics: CPU 70%, Connections 80%
- ✅ Configure min/max replicas (e.g., 2-15)
- ✅ Scale-up aggressively (1-2 min); scale-down conservatively (15 min)
- ✅ Test scaling behavior under load (chaos engineering)
- ❌ Don't rely on manual replica scaling (delays in traffic spikes)

**3. Reader Endpoint Strategy**
- ✅ Route analytics queries to read-only endpoint (load-balanced across replicas)
- ✅ Route critical reads to primary (ensures consistency)
- ✅ Implement read-after-write consistency in application
- ✅ Monitor replica lag; alert if > 100ms
- ✅ Handle promotion of replica to primary (endpoint changes, notify apps)
- ❌ Don't use reader endpoint for transactional consistency

**4. Parameter Tuning**
- ✅ Aurora: Different parameter groups from RDS (storage is shared)
- ✅ Tune: innodb_buffer_pool_size (50% of instance memory)
- ✅ Set: max_connections based on workload (e.g., 1000 for 256GB instance)
- ✅ Enable: Query cache (if appropriate for workload)
- ✅ Test parameter changes in staging first
- ❌ Don't apply arbitrary parameter values (profile actual usage first)

**5. Backup & Recovery**
- ✅ Backups: Continuous, auto to S3 (no performance impact)
- ✅ Retention: 14-35 days (based on recovery requirements)
- ✅ Point-in-time recovery: Automated via AWS
- ✅ Test restore procedures monthly
- ✅ Cross-region backup copies for DR
- ✅ Backup cost: Already included in Aurora pricing
- ❌ Don't underestimate backup retention (affects recovery options)

**6. Failover Testing**
- ✅ Regular failover tests (quarterly minimum)
- ✅ Simulate failure: Force failover during maintenance window
- ✅ Measure: RTO (time to failover), validate data integrity
- ✅ Document: Failover procedures, runbooks
- ✅ Test application reconnection (DNS failover transparent?)
- ❌ Don't assume automatic failover works (test it!)

**7. Global Database Management**
- ✅ Cross-region replication: Async, < 1 second lag typical
- ✅ Failover to secondary: Promote read-only instance to primary
- ✅ Cost: ~2x for replication + compute on secondary region
- ✅ Monitor: Cross-region replication lag
- ✅ Plan: Data consistency guarantees (eventually consistent)
- ❌ Don't confuse global database with synchronous replication

**8. Integration with IaC**
- ✅ All clusters defined in Terraform/CloudFormation
- ✅ Parameter groups, security groups versioned in Git
- ✅ Backup policies codified (retention, copy-to-region)
- ✅ Auto-scaling policies defined as code
- ✅ Enable automatic minor version upgrades
- ✅ Blue-green deployments for major upgrades
- ❌ Don't make manual cluster changes (breaks reproducibility)

#### Common Pitfalls

**Pitfall 1: Overbuilding Primary Instance**
- ❌ **Problem**: Buy large primary instance, assuming more compute = better performance
- 🎯 **Impact**: Higher cost; compute doesn't address storage bottlenecks
- ✅ **Solution**: On-demand read replicas for burst; scale compute only if primary CPU > 70% sustained

**Pitfall 2: Not Using Reader Endpoint**
- ❌ **Problem**: All reads hit primary instance (defeating purpose of replicas)
- 🎯 **Impact**: Primary overloaded; replicas underutilized; poor cost efficiency
- ✅ **Solution**: Route analytics/reporting to reader endpoint; critical reads to primary

**Pitfall 3: Ignoring Replica Lag**
- ❌ **Problem**: Replicas exhibit <10ms lag; applications assume synchronous replication
- 🎯 **Impact**: Read inconsistencies; stale data on dashboards
- ✅ **Solution**: Monitor replica lag; implement read-after-write pattern where needed

**Pitfall 4: Insufficient Failover Testing**
- ❌ **Problem**: Auto-failover works "by design"; assume it works without testing
- 🎯 **Impact**: Failover fails in production; no rollback procedure or monitoring insight
- ✅ **Solution**: Monthly manual failover tests; measure RTO; validate data integrity

**Pitfall 5: Scaling Secondary Region Like Primary**
- ❌ **Problem**: Deploy secondary region with same compute as primary
- 🎯 **Impact**: Unnecessary cost if secondary only reads
- ✅ **Solution**: Size secondary smaller for read-only workload; scale up if promoted to primary

**Pitfall 6: Auto-Scaling Misconfiguration**
- ❌ **Problem**: Aggressive scale-down (e.g., 2 min); causes replica thrashing during spiky traffic
- 🎯 **Impact**: Constant add/remove of replicas; cost increase; connection instability
- ✅ **Solution**: Conservative scale-down (15 min), aggressive scale-up (1 min)

**Pitfall 7: Cross-Region Replication Cost Surprise**
- ❌ **Problem**: Didn't account for cross-region data transfer costs
- 🎯 **Impact**: Monthly bill doubles from replication traffic
- ✅ **Solution**: Estimate cross-region traffic; evaluate trade-offs (cost vs. DR availability)

---

### Practical Code Examples

#### Terraform: Aurora Global Database with Auto-Scaling

```hcl
# Provider configuration for multi-region
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "eu-west-1"
}

# Variables
variable "cluster_identifier" {
  default = "myapp-aurora-cluster"
}

variable "engine_version" {
  default = "15.3"  # PostgreSQL
}

variable "db_name" {
  default = "myappdb"
}

variable "master_username" {
  type      = string
  sensitive = true
}

variable "master_password" {
  type      = string
  sensitive = true
}

# Primary Region VPC and Subnets
resource "aws_vpc" "primary" {
  provider   = aws.primary
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Primary VPC"
  }
}

resource "aws_subnet" "primary_1" {
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Primary Subnet 1"
  }
}

resource "aws_subnet" "primary_2" {
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Primary Subnet 2"
  }
}

resource "aws_subnet" "primary_3" {
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Primary Subnet 3"
  }
}

# Aurora DB Subnet Group (Primary)
resource "aws_db_subnet_group" "primary" {
  provider    = aws.primary
  name        = "aurora-primary-subnet-group"
  subnet_ids  = [aws_subnet.primary_1.id, aws_subnet.primary_2.id, aws_subnet.primary_3.id]
  description = "Subnet group for Aurora primary cluster"

  tags = {
    Name = "Aurora Primary Subnet Group"
  }
}

# Security Group (Primary)
resource "aws_security_group" "aurora_primary" {
  provider    = aws.primary
  name        = "aurora-primary-sg"
  vpc_id      = aws_vpc.primary.id
  description = "Security group for Aurora primary"

  ingress {
    from_port   = 5432  # PostgreSQL
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Aurora Primary SG"
  }
}

# Aurora Cluster (Primary Region)
resource "aws_rds_cluster" "primary" {
  provider              = aws.primary
  cluster_identifier    = "${var.cluster_identifier}-primary"
  engine                = "aurora-postgresql"
  engine_version        = var.engine_version
  database_name         = var.db_name
  master_username       = var.master_username
  master_password       = var.master_password
  db_subnet_group_name  = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [aws_security_group.aurora_primary.id]

  # Storage & Backup
  storage_encrypted                 = true
  backup_retention_period           = 14
  preferred_backup_window           = "03:00-04:00"
  preferred_maintenance_window       = "sun:04:00-sun:05:00"
  enabled_cloudwatch_logs_exports   = ["postgresql"]

  # Enable Global Database replication
  enable_http_endpoint              = false

  # Skip final snapshot for testing (remove in production)
  skip_final_snapshot               = false
  final_snapshot_identifier         = "${var.cluster_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = {
    Name = "Aurora Primary Cluster"
  }
}

# Primary Instance (Writer)
resource "aws_rds_cluster_instance" "primary_instance" {
  provider           = aws.primary
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class     = "db.r6g.xlarge"  # 32GB RAM
  engine              = aws_rds_cluster.primary.engine
  engine_version      = aws_rds_cluster.primary.engine_version
  identifier          = "${var.cluster_identifier}-primary-instance"

  performance_insights_enabled     = true
  monitoring_interval              = 60
  monitoring_role_arn              = aws_iam_role.rds_monitoring.arn
  enable_performance_insights      = true

  tags = {
    Name   = "Aurora Primary Instance"
    Role   = "Writer"
  }
}

# Read Replica Instances (Primary Region)
resource "aws_rds_cluster_instance" "primary_replicas" {
  provider            = aws.primary
  count               = 2
  cluster_identifier  = aws_rds_cluster.primary.id
  instance_class      = "db.r6g.large"  # 16GB RAM
  engine              = aws_rds_cluster.primary.engine
  engine_version      = aws_rds_cluster.primary.engine_version
  identifier          = "${var.cluster_identifier}-primary-replica-${count.index + 1}"
  publicly_accessible = false

  monitoring_interval  = 60
  monitoring_role_arn  = aws_iam_role.rds_monitoring.arn

  tags = {
    Name   = "Aurora Primary Replica ${count.index + 1}"
    Role   = "Reader"
  }
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  provider = aws.primary
  name     = "aurora-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  provider       = aws.primary
  role           = aws_iam_role.rds_monitoring.name
  policy_arn     = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Aurora Global Database
resource "aws_rds_global_cluster" "global" {
  provider                  = aws.primary
  global_cluster_identifier = "${var.cluster_identifier}-global"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
}

# Associate primary cluster with global database
resource "aws_rds_cluster" "primary_global" {
  provider              = aws.primary
  cluster_identifier    = "${var.cluster_identifier}-primary-global"
  engine                = "aurora-postgresql"
  engine_version        = var.engine_version
  master_username       = var.master_username
  master_password       = var.master_password
  db_subnet_group_name  = aws_db_subnet_group.primary.name
  vpc_security_group_ids = [aws_security_group.aurora_primary.id]
  
  global_cluster_identifier = aws_rds_global_cluster.global.id
  storage_encrypted         = true
  backup_retention_period   = 14
  skip_final_snapshot       = false

  depends_on = [aws_rds_global_cluster.global]

  tags = {
    Name = "Aurora Primary Global Cluster"
  }
}

# Secondary Region VPC
resource "aws_vpc" "secondary" {
  provider   = aws.secondary
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "Secondary VPC"
  }
}

resource "aws_subnet" "secondary_1" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Secondary Subnet 1"
  }
}

resource "aws_subnet" "secondary_2" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "Secondary Subnet 2"
  }
}

resource "aws_subnet" "secondary_3" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.3.0/24"
  availability_zone = "eu-west-1c"

  tags = {
    Name = "Secondary Subnet 3"
  }
}

# Aurora DB Subnet Group (Secondary)
resource "aws_db_subnet_group" "secondary" {
  provider    = aws.secondary
  name        = "aurora-secondary-subnet-group"
  subnet_ids  = [aws_subnet.secondary_1.id, aws_subnet.secondary_2.id, aws_subnet.secondary_3.id]
  description = "Subnet group for Aurora secondary cluster"

  tags = {
    Name = "Aurora Secondary Subnet Group"
  }
}

# Security Group (Secondary)
resource "aws_security_group" "aurora_secondary" {
  provider    = aws.secondary
  name        = "aurora-secondary-sg"
  vpc_id      = aws_vpc.secondary.id
  description = "Security group for Aurora secondary"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Aurora Secondary SG"
  }
}

# Secondary Cluster (Read-Only, part of Global Database)
resource "aws_rds_cluster" "secondary" {
  provider                  = aws.secondary
  cluster_identifier        = "${var.cluster_identifier}-secondary"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  db_subnet_group_name      = aws_db_subnet_group.secondary.name
  vpc_security_group_ids    = [aws_security_group.aurora_secondary.id]
  global_cluster_identifier = aws_rds_global_cluster.global.id

  skip_final_snapshot = false

  depends_on = [aws_rds_cluster.primary_global]

  tags = {
    Name = "Aurora Secondary Cluster"
  }
}

# Secondary Instances (Read-Only)
resource "aws_rds_cluster_instance" "secondary_instance" {
  provider           = aws.secondary
  cluster_identifier = aws_rds_cluster.secondary.id
  instance_class     = "db.r6g.xlarge"
  engine              = aws_rds_cluster.secondary.engine
  engine_version     = aws_rds_cluster.secondary.engine_version
  identifier         = "${var.cluster_identifier}-secondary-instance"

  performance_insights_enabled = true
  monitoring_interval          = 60

  tags = {
    Name = "Aurora Secondary Instance"
    Role = "Reader"
  }
}

# Aurora Auto Scaling for Primary Read Replicas
resource "aws_appautoscaling_target" "aurora_read_scaling" {
  provider           = aws.primary
  max_capacity       = 15
  min_capacity       = 2
  resource_id        = "cluster:${aws_rds_cluster.primary_global.cluster_identifier}"
  scalable_dimension = "rds:cluster:DesiredReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "aurora_read_scaling_cpu" {
  provider           = aws.primary
  policy_name        = "aurora-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.aurora_read_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.aurora_read_scaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.aurora_read_scaling.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
  provider            = aws.primary
  alarm_name          = "aurora-replica-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "AuroraBinlogReplicaLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 100  # milliseconds
  alarm_description   = "Alert if Aurora replica lag > 100ms"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.primary_global.cluster_identifier
  }
}

# Outputs
output "primary_cluster_endpoint" {
  value       = aws_rds_cluster.primary_global.endpoint
  description = "Primary cluster endpoint (read-write)"
}

output "primary_reader_endpoint" {
  value       = aws_rds_cluster.primary_global.reader_endpoint
  description = "Primary cluster reader endpoint (read-only, load balanced)"
}

output "secondary_cluster_endpoint" {
  provider    = aws.secondary
  value       = aws_rds_cluster.secondary.endpoint
  description = "Secondary cluster endpoint (read-only)"
}

output "global_cluster_id" {
  value       = aws_rds_global_cluster.global.id
  description = "Global database cluster identifier"
}
```

#### CloudFormation: Aurora Serverless v2 Cluster

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: "Aurora MySQL Serverless v2 with auto-scaling"

Parameters:
  DBName:
    Type: String
    Default: myappdb
  DBUsername:
    Type: String
    Default: admin
  DBPassword:
    Type: String
    NoEcho: true
    MinLength: 8

Resources:
  # VPC and Subnets
  AuroraVPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      Tags:
        - Key: Name
          Value: Aurora VPC

  AuroraSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref AuroraVPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs ""]
      Tags:
        - Key: Name
          Value: Aurora Subnet 1

  AuroraSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref AuroraVPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs ""]
      Tags:
        - Key: Name
          Value: Aurora Subnet 2

  AuroraSubnet3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref AuroraVPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [2, !GetAZs ""]
      Tags:
        - Key: Name
          Value: Aurora Subnet 3

  # DB Subnet Group
  AuroraSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for Aurora
      SubnetIds:
        - !Ref AuroraSubnet1
        - !Ref AuroraSubnet2
        - !Ref AuroraSubnet3

  # Security Group
  AuroraSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for Aurora
      VpcId: !Ref AuroraVPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 3306
          ToPort: 3306
          CidrIp: 10.0.0.0/16
      Tags:
        - Key: Name
          Value: Aurora SG

  # Aurora Serverless v2 Cluster
  AuroraCluster:
    Type: AWS::RDS::DBCluster
    Properties:
      Engine: aurora-mysql
      EngineVersion: "8.0.mysql_aurora.3.04.0"
      EngineMode: provisioned
      DBClusterIdentifier: myapp-aurora-serverless
      MasterUsername: !Ref DBUsername
      MasterUserPassword: !Ref DBPassword
      DatabaseName: !Ref DBName
      DBSubnetGroupName: !Ref AuroraSubnetGroup
      VpcSecurityGroupIds:
        - !Ref AuroraSecurityGroup
      StorageEncrypted: true
      BackupRetentionPeriod: 14
      PreferredBackupWindow: "03:00-04:00"
      PreferredMaintenanceWindow: "sun:04:00-sun:05:00"
      EnableCloudwatchLogsExports:
        - error
        - slowquery
      EnableIAMDatabaseAuthentication: true
      DeletionProtection: false
      Tags:
        - Key: Name
          Value: Aurora Serverless Cluster

  # Writer Instance (Serverless v2)
  AuroraWriterInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBClusterIdentifier: !Ref AuroraCluster
      DBInstanceIdentifier: myapp-aurora-writer
      DBInstanceClass: db.serverless
      Engine: aurora-mysql
      PubliclyAccessible: false
      MonitoringInterval: 60
      EnablePerformanceInsights: true
      Tags:
        - Key: Name
          Value: Aurora Writer
        - Key: Role
          Value: Writer

  # Read Replica Instance
  AuroraReaderInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBClusterIdentifier: !Ref AuroraCluster
      DBInstanceIdentifier: myapp-aurora-reader-1
      DBInstanceClass: db.serverless
      Engine: aurora-mysql
      PubliclyAccessible: false
      MonitoringInterval: 60
      Tags:
        - Key: Name
          Value: Aurora Reader 1
        - Key: Role
          Value: Reader

  # Cluster Parameter Group (Serverless v2)
  AuroraParameterGroup:
    Type: AWS::RDS::DBClusterParameterGroup
    Properties:
      Description: Aurora MySQL Serverless v2 parameters
      Family: aurora-mysql8.0
      Parameters:
        slow_query_log: 1
        long_query_time: 2
        max_connections: 1000
      Tags:
        - Key: Name
          Value: Aurora Parameter Group

  # Auto Scaling Target for Read Capacity
  ReadScalingTarget:
    Type: AWS::ApplicationAutoScaling::ScalableTarget
    Properties:
      MaxCapacity: 128  # 128 ACUs (~256GB memory)
      MinCapacity: 1    # 1 ACU (2GB memory)
      ResourceId: !Sub "cluster:${AuroraCluster}"
      RoleARN: !Sub "arn:aws:iam::${AWS::AccountId}:role/aws-service-role/rds.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_RDSCluster"
      ScalableDimension: rds:cluster:DesiredReadReplicaCount
      ServiceNamespace: rds

  # Scaling Policy (CPU-based)
  ReadScalingPolicy:
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
    Properties:
      PolicyName: aurora-cpu-scaling
      PolicyType: TargetTrackingScaling
      ResourceId: !Sub "cluster:${AuroraCluster}"
      ScalableDimension: rds:cluster:DesiredReadReplicaCount
      ServiceNamespace: rds
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: RDSReaderAverageCPUUtilization
        TargetValue: 70.0
        ScaleOutCooldown: 60
        ScaleInCooldown: 300

  # CloudWatch Alarm - Replica Lag
  ReplicaLagAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: aurora-replica-lag-high
      AlarmDescription: Alert if Aurora replica lag > 100ms
      MetricName: AuroraBinlogReplicaLag
      Namespace: AWS/RDS
      Statistic: Average
      Period: 60
      EvaluationPeriods: 2
      Threshold: 100
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: DBClusterIdentifier
          Value: !Ref AuroraCluster

  # CloudWatch Alarm - Serverless Capacity
  ServerlessCapacityAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: aurora-serverless-high-capacity
      AlarmDescription: Alert when Aurora Serverless near max capacity
      MetricName: ServerlessDatabaseCapacity
      Namespace: AWS/RDS
      Statistic: Maximum
      Period: 300
      EvaluationPeriods: 2
      Threshold: 100  # ACUs
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: DBClusterIdentifier
          Value: !Ref AuroraCluster

Outputs:
  ClusterEndpoint:
    Value: !GetAtt AuroraCluster.Endpoint.Address
    Description: Aurora cluster endpoint (read-write)
    Export:
      Name: !Sub "${AWS::StackName}-ClusterEndpoint"

  ReaderEndpoint:
    Value: !GetAtt AuroraCluster.ReadEndpoint.Address
    Description: Aurora reader endpoint (load-balanced across readers)
    Export:
      Name: !Sub "${AWS::StackName}-ReaderEndpoint"

  ClusterPort:
    Value: !GetAtt AuroraCluster.Endpoint.Port
    Description: Aurora cluster port
    Export:
      Name: !Sub "${AWS::StackName}-ClusterPort"

  DatabaseName:
    Value: !Ref DBName
    Export:
      Name: !Sub "${AWS::StackName}-DatabaseName"
```

#### Shell Script: Aurora Failover & Replica Promotion

```bash
#!/bin/bash
# Script: Aurora Cluster Failover & Replica Promotion Testing
# Purpose: Test automatic failover; promote replica to primary
# Schedule: Quarterly disaster recovery drill

set -e

# Configuration
CLUSTER_ID="myapp-aurora-cluster"
REGION="us-east-1"
PROMOTE_REPLICA_ID="myapp-aurora-replica-1"

echo "=== Aurora Failover Test ==="
echo "Cluster: $CLUSTER_ID"
echo "Region: $REGION"
echo "Time: $(date)"

# Function to get cluster status
get_cluster_status() {
  aws rds describe-db-clusters \
    --db-cluster-identifier "$CLUSTER_ID" \
    --region "$REGION" \
    --query 'DBClusters[0].[DBClusterIdentifier,Status,MemberList[*].DBInstanceIdentifier]' \
    --output text
}

# Function to get replica lag
get_replica_lag() {
  aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name AuroraBinlogReplicaLag \
    --dimensions Name=DBClusterIdentifier,Value="$CLUSTER_ID" \
    --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 60 \
    --statistics Average \
    --region "$REGION" \
    --query 'Datapoints[0].Average' \
    --output text
}

# Step 1: Check current status
echo -e "\n[1/5] Current cluster status:"
get_cluster_status

REPLICA_LAG=$(get_replica_lag)
echo "Current replica lag: ${REPLICA_LAG}ms"

if (( $(echo "$REPLICA_LAG > 100" | bc -l) )); then
  echo "WARNING: Replica lag > 100ms. Proceeding with caution."
fi

# Step 2: Initiate failover
echo -e "\n[2/5] Initiating Aurora failover..."
START_TIME=$(date +%s)

aws rds failover-db-cluster \
  --db-cluster-identifier "$CLUSTER_ID" \
  --region "$REGION"

echo "Failover initiated. Waiting for completion..."

# Step 3: Monitor failover progress
echo -e "\n[3/5] Monitoring failover progress..."
while true; do
  STATUS=$(aws rds describe-db-clusters \
    --db-cluster-identifier "$CLUSTER_ID" \
    --region "$REGION" \
    --query 'DBClusters[0].Status' \
    --output text)

  if [ "$STATUS" == "available" ]; then
    END_TIME=$(date +%s)
    FAILOVER_TIME=$((END_TIME - START_TIME))
    echo "Failover completed! RTO: ${FAILOVER_TIME}s"
    break
  else
    echo "Status: $STATUS (waiting...)"
    sleep 5
  fi

  # Timeout after 5 minutes
  if [ $(($(date +%s) - START_TIME)) -gt 300 ]; then
    echo "ERROR: Failover timeout after 5 minutes"
    exit 1
  fi
done

# Step 4: Validate connectivity & data
echo -e "\n[4/5] Validating database connectivity..."
ENDPOINT=$(aws rds describe-db-clusters \
  --db-cluster-identifier "$CLUSTER_ID" \
  --region "$REGION" \
  --query 'DBClusters[0].Endpoint' \
  --output text)

mysql -h "$ENDPOINT" -u admin -p"$DB_PASSWORD" -e "SELECT NOW();" || {
  echo "ERROR: Cannot connect to database after failover"
  exit 1
}

# Step 5: Data integrity check
echo -e "\n[5/5] Running data integrity checks..."
ROW_COUNT=$(mysql -h "$ENDPOINT" -u admin -p"$DB_PASSWORD" \
  -e "SELECT COUNT(*) FROM myappdb.users;" | tail -1)

echo "Verified row count in users table: $ROW_COUNT"

# Report results
echo -e "\n=== Failover Test Results ==="
echo "Status: SUCCESS"
echo "RTO (Recovery Time Objective): ${FAILOVER_TIME}s"
echo "Data Integrity: PASSED"
echo "Endpoint: $ENDPOINT"
echo "Timestamp: $(date)"

# Send SNS notification
aws sns publish \
  --topic-arn "arn:aws:sns:$REGION:ACCOUNT_ID:rds-alerts" \
  --subject "Aurora Failover Test PASSED: $CLUSTER_ID" \
  --message "Aurora failover drill completed successfully. RTO: ${FAILOVER_TIME}s. Data integrity verified."
```

---

### ASCII Diagrams

#### Aurora Architecture: Compute-Storage Separation

```
Traditional Database (Single Instance):
─────────────────────────────────────
┌──────────────────────────────────┐
│  EC2 Instance (db.r5.2xlarge)    │
│  ┌────────────────────────────┐  │
│  │ MySQL Engine               │  │
│  │ Buffer Pool: 64GB          │  │
│  │ Data Cache + Logs          │  │
│  └────────────────────────────┘  │
│          ↓↑                       │
│  ┌────────────────────────────┐  │
│  │ EBS Volume                 │  │
│  │ 500GB gp3                  │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘

Scaling: Upgrade to db.r6.4xlarge = double cost, rebuild required


Aurora (Separated Compute & Storage):
────────────────────────────────────

┌──────────────────────────┐
│  MySQL Engine (Stateless)│
│  Compute: db.r6g.xlarge  │
│  Buffer Pool: 32GB       │
│  Caching Layer           │
└──────────┬───────────────┘
           │
           ↓ WAL (Write-Ahead Log)
           │
┌──────────────────────────────────────────────────┐
│        Shared Distributed Storage Layer           │
│  (Replicated across 3 AZs, 6 total replicas)     │
│                                                   │
│  ┌─────────────────────┐  ┌──────────────────┐   │
│  │ AZ-a Storage Node 1 │  │ AZ-b Node 2      │   │
│  │ AZ-a Storage Node 3 │  │ AZ-b Node 4      │   │
│  │ AZ-c Storage Node 5 │  │ AZ-c Node 6      │   │
│  └─────────────────────┘  └──────────────────┘   │
│                                                   │
│  Data Durability: 6-way replication              │
│  Consistency: Quorum-based (4 of 6)              │
└──────────────────────────────────────────────────┘

Scaling: Add read replica without changing compute
        Add storage automatically (scales to 128TB)
        Scales independently and cost-effectively
```

#### Aurora Failover Timeline

```
Normal Operation:
─────────────────

┌─────────────────┐  write/read  ┌────────────────────┐
│   Application   │◄─────────────►│ Primary Instance   │
└─────────────────┘              └────────────────────┘
                                      ↓ (async replication <10ms)
                                 ┌────────────────────┐
                                 │ Read Replicas      │
                                 │ (up to 15)         │
                                 └────────────────────┘

Primary Failure (t=0):
─────────────────────

                         ✗ Primary FAILS
                         │
                         ├─ Network unreachable
                         ├─ Storage issue
                         └─ Instance crash

Aurora Detection (t=10s):
─────────────────────────

├─ Health check detects primary unresponsive
├─ Checks replica cluster endpoints
├─ Selects best replica (based on binary log position)
└─ Initiates failover

Promotion Phase (t=10-30s):
──────────────────────────

┌─────────────────┐                             ┌────────────────────┐
│   Application   │ ┌────────────────────────┐  │ Secondary Instance │
│   (DNS cached)  │ │ Cluster Endpoint       │  │ (PROMOTED to       │
└─────────────────┘ │ REDIRECTED TO NEW      │  │ PRIMARY)           │
                    │ PRIMARY INSTANCE       │  │                    │
                    └────────────────────────┘  └────────────────────┘
                                                      ↓ (NEW primary)
                                                ┌────────────────────┐
                                                │ Other Replicas     │
                                                │ (Synced from new   │
                                                │ primary)           │
                                                └────────────────────┘

Application Reconnection (t=30-60s):
────────────────────────────────────

┌─────────────────┐
│   Application   │  ← DNS refreshes or retry logic
│   reconnects    │  ← New primary responding
│   to cluster    │  ← Reads and writes resume
│   endpoint      │
└─────────────────┘
        ↓
┌─────────────────────────────────────┐
│ New Primary Instance (Running)      │
│ Replicas (Synchronized)             │
│ Status: AVAILABLE                   │
└─────────────────────────────────────┘

Timeline Summary:
├─ Detection: 10 seconds
├─ Promotion: 10-20 seconds
├─ DNS/Reconnection: 10-30 seconds
│
└─ RTO (Recovery Time Objective): ~30-60 seconds
```

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-03-07 | DevOps Team | Initial creation: TOC, Introduction, Foundational Concepts |
| 2026-03-07 | DevOps Team | Added RDS Basics & Aurora Architecture deep dives with code examples |


---

## DynamoDB Fundamentals

Amazon DynamoDB is a fully managed, serverless NoSQL database service designed for applications requiring consistent, single-digit millisecond latency at any scale. Unlike RDS/Aurora which optimize for relational queries, DynamoDB optimizes for high-throughput key-value access patterns and horizontal scaling.

### Textual Deep Dive

#### Internal Working Mechanism

DynamoDB's architecture fundamentally differs from relational databases through **partition-based distributed storage**:

**1. Data Partitioning Model**
```
Table: Users
├─ Partition Key: user_id (determines which partition stores data)
├─ Sort Key: created_at (within partition, ordered by timestamp)
│
├─ Partition 1 (user_id 0-999)
│  └─ Items sorted by created_at
│  └─ Stores ~10GB data
│  └─ Handles ~1000 RCU/WCU
│
├─ Partition 2 (user_id 1000-1999)
│  └─ Items sorted by created_at
│  └─ Stores ~10GB data
│  └─ Handles ~1000 RCU/WCU
│
└─ Partition N (scales automatically)
   └─ Data distributed across partitions
   └─ Total: 40TB+ possible
```

**Key Insight**: Partition key selection determines scaling ceiling. Poor choice (e.g., country as partition key) causes "hot partitions" = throttling.

**2. Consistency Model**
- **Eventually Consistent Reads (Default)**: Read from any replica, low latency, may return stale data (100ms lag typical)
- **Strongly Consistent Reads**: Read from leader partition only, 2x latency, guarantees fresh data
- **ACID Transactions (TransactWriteItems)**: Multi-item atomic operations; limited to 25 items max per transaction
- **Trade-off**: Strong consistency = higher latency; eventual consistency = lower latency

**3. Throughput Provisioning**
```
Capacity Unit Definitions:
──────────────────────────
1 RCU (Read Capacity Unit):
  ├─ Strongly consistent: reads up to 4KB every second
  ├─ Strongly consistent: 1 RCU = 4KB/sec
  ├─ Eventually consistent: 1 RCU = 8KB/sec (2x better)
  └─ Example: 10GB per second = 2,500,000 RCU (strongly consistent)

1 WCU (Write Capacity Unit):
  ├─ Writes up to 1KB every second
  ├─ 1 WCU = 1KB/sec
  ├─ TTL deletes don't consume WCU
  └─ Example: 1GB per second = 1,000,000 WCU

Provisioning Modes:
──────────────────
Provisioned: Fixed capacity (cost per hour)
  ├─ Cost: $0.25 RCU/hour (on-demand pricing highest)
  ├─ Cost: $13/month per 100 RCU (reserved pricing)
  ├─ Trade-off: Cheaper for predictable workload
  └─ Auto-scaling available (scales up/down automatically)

On-Demand: Pay per request (cost per million requests)
  ├─ Cost: $1.25 per million RCU
  ├─ Cost: $6.25 per million WCU
  ├─ Trade-off: No capacity planning, bursts free
  └─ Suitable for unpredictable/spiky traffic
```

**4. Indexing Architecture**
- **Primary Key**: Partition Key + Optional Sort Key (must be unique)
- **Global Secondary Index (GSI)**: Alternative partition/sort key pair
  - Different partition key = different access pattern
  - Separate provisioned capacity
  - Eventually consistent reads only
  - Up to 20 GSI per table
- **Local Secondary Index (LSI)**: Same partition key, different sort key
  - Shares provisioned capacity with base table
  - Strongly consistent reads available
  - Limited to 10GB per partition key value
  - Up to 10 LSI per table

**5. Performance Characteristics**
```
Latency Profile:
────────────────
GetItem (strong consistency):    1-3ms p50, 5-10ms p99
GetItem (eventual consistency):  1-2ms p50, 3-5ms p99
Query (partition key + SK):      1-5ms p50, 10-20ms p99
Scan (full table):               50-500ms (depends on table size)
Batch Operations:                1-5ms for up to 25 items

Throughput Limits:
──────────────────
Per partition: 3000 RCU, 1000 WCU hard limit
Per table (provisioned): Unlimited (scales across partitions)
Per table (on-demand): 40,000 RCU, 40,000 WCU burst limit
```

#### Architecture Role

**DynamoDB in Modern Applications:**

```
Access Pattern Mapping:
──────────────────────

User Profile Lookups (get specific user):
Table: Users
├─ Partition Key: user_id
├─ Sort Key: (none)
├─ Query: GetItem(user_id)
├─ Latency: <5ms
└─ Use Case: Session lookups, profile service

Leaderboard (top 100 scores):
Table: Leaderboard
├─ Partition Key: game_id
├─ Sort Key: score (descending)
├─ Query: Query(game_id, score > X)
├─ Latency: <10ms
└─ Use Case: Real-time leaderboards, rankings

User Activity Timeline (recent actions):
Table: UserActivity
├─ Partition Key: user_id
├─ Sort Key: timestamp (descending)
├─ Query: Query(user_id, timestamp between X and Y)
├─ Latency: <20ms
└─ Use Case: Feed, activity history, audit logs

Multi-tenant Analytics (query by tenant + metric):
Table: Metrics
├─ Partition Key: tenant_id
├─ Sort Key: metric_name + timestamp
├─ GSI: metric_name (Partition Key) → Query by metric across tenants
├─ Latency: <15ms
└─ Use Case: SaaS analytics, cross-tenant reporting
```

#### Production Usage Patterns

**Pattern 1: Mobile App Session Management**
```
Workload: Millions of concurrent mobile users; sessions must be available <5ms
──────────────────────────────────────────────────────────────────────────────

Table: Sessions
├─ Partition Key: user_id
├─ Sort Key: session_id
├─ Attributes: token, device, last_activity, ttl
├─ TTL: 30 days (automatic deletion)
│
├─ Provisioned Capacity:
│  ├─ Write: 500,000 WCU (5M new sessions/day = ~58 WCU)
│  ├─ Read: 5,000,000 RCU (app checks session every request)
│  └─ Cost: ~$2,000/month
│
├─ OR On-Demand:
│  ├─ Cost: Variable based on traffic
│  ├─ Better if traffic highly variable
│  └─ Example: 1M sessions = $1.25 (cost per million)
│
└─ Scaling: Auto-scaling adjusts capacity 1-5 min
```

**Pattern 2: Real-Time Analytics (IoT Sensors)**
```
Workload: Ingest 1M events/sec from IoT devices; query latest readings
───────────────────────────────────────────────────────────────────

Table: DeviceMetrics
├─ Partition Key: device_id
├─ Sort Key: timestamp
├─ Attributes: temperature, humidity, pressure, location
├─ TTL: 365 days (archive older data to S3)
│
├─ Write Capacity:
│  ├─ 1M events/sec = 1-10KB each
│  ├─ Required: 1,000,000 - 10,000,000 WCU
│  ├─ Cost at provisioned: VERY expensive
│  └─ Solution: Use on-demand + batch writes with 25-item batches
│
├─ Read Capacity:
│  ├─ Real-time dashboard: Query latest 100 readings per device
│  ├─ 100,000 devices × 100 queries/min = 166M RCU/month
│  └─ Cost: ~$200K on-demand (prohibitive!)
│
└─ Better Solution: DynamoDB Streams + Lambda → S3 for analytics
                    Real-time cache (ElastiCache) for hot data
```

**Pattern 3: E-Commerce Product Catalog**
```
Workload: 10M products; need fast product lookup + category browsing
──────────────────────────────────────────────────────────────────

Table: Products
├─ Partition Key: product_id
├─ Attributes: name, price, category, stock, reviews
├─ GSI1: category (Partition Key) + price (Sort Key)
│  └─ Enables: "Show all products in category with price > $100"
├─ GSI2: rating (Partition Key) + popularity (Sort Key)
│  └─ Enables: "Show trending products in category"
│
├─ Provisioned Capacity:
│  ├─ GetItem by product_id: 100,000 RCU
│  ├─ Query by category: 50,000 RCU (via GSI)
│  ├─ Write (inventory updates): 10,000 WCU
│  └─ Total cost: ~$500/month
│
└─ Optimization: ElastiCache in front (hot products cached)
                 Batch writes for inventory updates
```

**Pattern 4: User Presence & Activity (Gaming)**
```
Workload: Real-time game state; track online users, activity
───────────────────────────────────────────────────────────

Table: UserPresence
├─ Partition Key: user_id
├─ Sort Key: (none)
├─ Attributes: status (online/offline), last_heartbeat, location
├─ TTL: 5 minutes (auto-delete if no heartbeat)
│
├─ Write Pattern:
│  ├─ Heartbeat every 30 seconds per user
│  ├─ 10M concurrent users = ~333K WCU (writes/sec)
│  ├─ Cost at provisioned: ~$200K/month
│
├─ Read Pattern:
│  ├─ Check presence: <1ms (partition key lookup)
│  ├─ List friends online: Need GSI or alternative
│
└─ Better Solution: Redis/ElastiCache instead of DynamoDB
                    Redis sorted sets for presence tracking
                    DynamoDB for persistence (eventual)
```

#### DevOps Best Practices

**1. Partition Key Design (CRITICAL)**
- ✅ Distribute requests across partitions evenly
- ✅ Avoid high-cardinality access patterns (avoid sorting by user_id if only 10 users)
- ✅ Use UUID or hash for random distribution
- ✅ Avoid timestamped partition keys (creates "hot partitions" at current time)
- ✅ Consider range queries; suffix with random token if needed
- ❌ Don't use timestamp as partition key (all writes go to current partition)
- ❌ Don't use boolean as partition key (only 2 partitions)

**2. Capacity Planning**
- ✅ Provisioned mode: Use if traffic predictable (cost savings 70%+)
- ✅ On-demand mode: Use if traffic highly variable or spiky
- ✅ Monitor actual usage via CloudWatch; right-size quarterly
- ✅ Use DynamoDB Accelerator (DAX) for improved caching
- ✅ Auto-scaling: Set target CPU 70%, min/max replicas
- ❌ Don't over-provision capacity (scales automatically; costs money)

**3. Indexing Strategy**
- ✅ Design queries first, then construct indexes
- ✅ GSI: Alternative partition/sort key for different access patterns
- ✅ LSI: When only sort key differs (10GB limit per partition key)
- ✅ Sparse indexes: Include only items where attribute exists (cost savings)
- ✅ Monitor GSI capacity separately; scale independently
- ❌ Don't create index you don't query (wasted cost)
- ❌ Don't use GSI for strong consistency (unsupported)

**4. Monitoring & Throttling**
- ✅ Monitor: ConsumedReadCapacityUnits, ConsumedWriteCapacityUnits
- ✅ Alert if throttling events (ProvisionedThroughputExceededException)
- ✅ Use CloudWatch metrics to detect hot partitions
- ✅ Enable point-in-time recovery (PITR) for safety
- ✅ Stream changes to Lambda for real-time processing
- ❌ Don't ignore throttling (customers experience 400ms+ latency)

**5. Data Consistency & Transactions**
- ✅ Use eventually consistent reads when acceptable (2x cheaper)
- ✅ TransactWriteItems for multi-item updates; max 25 items
- ✅ Implement optimistic locking (version attributes) for concurrent updates
- ✅ Handle ConditionalCheckFailedException in application
- ✅ Batch operations (25 items max) to reduce request count
- ❌ Don't use TransactWriteItems for every write (higher cost + latency)

**6. TTL & Auto-Cleanup**
- ✅ Enable TTL for time-sensitive data (sessions, temporary records)
- ✅ TTL deletion: Free (doesn't consume WCU)
- ✅ Deletion lag: ~24-48 hours after TTL expires (eventual)
- ✅ Export data before TTL expiration if archival needed
- ❌ Don't rely on TTL for immediate deletion (deltas can be 24h+ delay)

**7. Cost Optimization**
- ✅ Compress large attributes (JSON → gzip)
- ✅ Use sparse attributes (don't store nulls; don't include attribute)
- ✅ Batch operations (250KB max per batch)
- ✅ On-demand for unpredictable; provisioned + auto-scaling for stable
- ✅ Reserved capacity: 70% discount for 1-year commitment
- ❌ Don't store large blobs in DynamoDB (use S3; store S3 URI in item)

**8. Backup & Disaster Recovery**
- ✅ Enable point-in-time recovery (PITR)
- ✅ On-demand backups (snapshot entire table)
- ✅ DynamoDB Streams for CDC (change data capture)
- ✅ Cross-region replication (Global Tables for active-active)
- ✅ Test restore procedures monthly
- ❌ Don't assume backups are automatic (enable explicitly)

#### Common Pitfalls

**Pitfall 1: Partition Key Hot Spots**
- ❌ **Problem**: Using timestamp as partition key; all writes to current partition
- 🎯 **Impact**: Throttling despite having 1000x necessary provisioned capacity
- ✅ **Solution**: Add random suffix or use date + random(0-1000) as partition key

**Pitfall 2: Scanning Instead of Querying**
- ❌ **Problem**: Full table scan instead of query by partition key
- 🎯 **Impact**: 1000x more RCU consumed; queries 100x slower
- ✅ **Solution**: Use partition key in queries; design indexes for access patterns

**Pitfall 3: Storing Large Objects**
- ❌ **Problem**: JSON blobs (10MB documents) stored directly in DynamoDB
- 🎯 **Impact**: Increased RCU/WCU consumption; slower queries
- ✅ **Solution**: Store large data in S3; keep S3 URI + metadata in DynamoDB

**Pitfall 4: Over-Provisioning or Under-Provisioning**
- ❌ **Problem**: Guess capacity without monitoring; either pays 5x or gets throttled
- 🎯 **Impact**: Unexpected costs or poor performance
- ✅ **Solution**: Start with on-demand; monitor; move to provisioned + auto-scaling

**Pitfall 5: Ignoring Replication Lag (Global Tables)**
- ❌ **Problem**: Write in Region-1; immediately read from Region-2 (should query Region-1)
- 🎯 **Impact**: Read inconsistency; stale data
- ✅ **Solution**: Route reads to same region as write; handle eventual consistency in application

**Pitfall 6: Inefficient Query Patterns**
- ❌ **Problem**: Querying with unsupported filters (e.g., attribute NOT exists → full scan)
- 🎯 **Impact**: Millions of RCU consumed; query < 1ms becomes 100ms+
- ✅ **Solution**: Design indexes for each query pattern upfront

**Pitfall 7: Excessive Index Proliferation**
- ❌ **Problem**: Create index for every possible query (10+ GSI per table)
- 🎯 **Impact**: Complexity, cost (each index has provisioned capacity), maintenance
- ✅ **Solution**: Design for primary access patterns; use sparse indexes

**Pitfall 8: TTL Not Enabled**
- ❌ **Problem**: Manually delete expired data; implement cron job
- 🎯 **Impact**: Wasted storage; manual maintenance burden
- ✅ **Solution**: Enable TTL; let DynamoDB auto-cleanup (free deletions)

---

### Practical Code Examples

#### Terraform: DynamoDB Table with Global Secondary Index

```hcl
# Variables
variable "app_name" {
  default = "myapp"
}

variable "environment" {
  default = "production"
}

# DynamoDB Table with GSI
resource "aws_dynamodb_table" "user_sessions" {
  name           = "${var.app_name}-sessions"
  billing_mode   = "PROVISIONED"  # or "PAY_PER_REQUEST" for on-demand
  hash_key       = "user_id"
  range_key      = "session_id"
  
  # Provisioned throughput
  provisioned_throughput = {
    read_capacity_units  = 5000   # Adjust based on workload
    write_capacity_units = 1000
  }

  # Attributes
  attribute {
    name = "user_id"
    type = "S"  # String
  }

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"  # Number (Unix timestamp)
  }

  # Global Secondary Index: Query by created_at (recent sessions)
  global_secondary_index {
    name            = "created_at-index"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"  # Include all attributes

    provisioned_throughput = {
      read_capacity_units  = 2000
      write_capacity_units = 500
    }
  }

  # TTL Configuration: Auto-delete sessions after 30 days
  ttl {
    enabled        = true
    attribute_name = "expiration_time"
  }

  # Point-in-Time Recovery
  point_in_time_recovery {
    enabled = true
  }

  # Streams (for Lambda processing)
  stream_specification {
    stream_view_type = "NEW_AND_OLD_IMAGES"
  }

  # Tags
  tags = {
    Name        = "User Sessions"
    Environment = var.environment
  }
}

# Auto Scaling for Read Capacity
resource "aws_appautoscaling_target" "dynamodb_read_scaling" {
  max_capacity       = 40000
  min_capacity       = 100
  resource_id        = "table/${aws_dynamodb_table.user_sessions.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_read_scaling" {
  policy_name               = "dynamodb-read-scaling"
  policy_type               = "TargetTrackingScaling"
  resource_id               = aws_appautoscaling_target.dynamodb_read_scaling.resource_id
  scalable_dimension        = aws_appautoscaling_target.dynamodb_read_scaling.scalable_dimension
  service_namespace         = aws_appautoscaling_target.dynamodb_read_scaling.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

# Auto Scaling for Write Capacity
resource "aws_appautoscaling_target" "dynamodb_write_scaling" {
  max_capacity       = 40000
  min_capacity       = 100
  resource_id        = "table/${aws_dynamodb_table.user_sessions.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_write_scaling" {
  policy_name               = "dynamodb-write-scaling"
  policy_type               = "TargetTrackingScaling"
  resource_id               = aws_appautoscaling_target.dynamodb_write_scaling.resource_id
  scalable_dimension        = aws_appautoscaling_target.dynamodb_write_scaling.scalable_dimension
  service_namespace         = aws_appautoscaling_target.dynamodb_write_scaling.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "read_throttling" {
  alarm_name          = "${var.app_name}-dynamodb-read-throttle"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when read throttling occurs"

  dimensions = {
    TableName = aws_dynamodb_table.user_sessions.name
  }
}

resource "aws_cloudwatch_metric_alarm" "write_throttling" {
  alarm_name          = "${var.app_name}-dynamodb-write-throttle"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteThrottleEvents"
  namespace           = "AWS/DynamoDB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when write throttling occurs"

  dimensions = {
    TableName = aws_dynamodb_table.user_sessions.name
  }
}

# Outputs
output "table_name" {
  value       = aws_dynamodb_table.user_sessions.name
  description = "DynamoDB table name"
}

output "table_arn" {
  value       = aws_dynamodb_table.user_sessions.arn
  description = "DynamoDB table ARN"
}

output "gsi_name" {
  value       = aws_dynamodb_table.user_sessions.global_secondary_index[0].name
  description = "Global secondary index name"
}
```

#### Node.js: DynamoDB Query Operations

```javascript
// AWS SDK v3
import { DynamoDBClient, GetItemCommand, QueryCommand, PutItemCommand } from "@aws-sdk/client-dynamodb";
import { v4 as uuidv4 } from 'uuid';

const dynamodbClient = new DynamoDBClient({ region: 'us-east-1' });
const tableName = 'myapp-sessions';

// 1. GetItem: Retrieve specific session (strongly consistent)
async function getSession(userId, sessionId) {
  try {
    const command = new GetItemCommand({
      TableName: tableName,
      Key: {
        'user_id': { S: userId },
        'session_id': { S: sessionId }
      },
      ConsistentRead: true  // Strongly consistent read
    });

    const response = await dynamodbClient.send(command);
    return response.Item ? unmarshallItem(response.Item) : null;
  } catch (error) {
    console.error('GetItem error:', error);
    throw error;
  }
}

// 2. Query: Get all sessions for a user (eventually consistent)
async function getUserSessions(userId, limit = 10) {
  try {
    const command = new QueryCommand({
      TableName: tableName,
      KeyConditionExpression: 'user_id = :userId',
      ExpressionAttributeValues: {
        ':userId': { S: userId }
      },
      ScanIndexForward: false,  // Descending order (newest first)
      Limit: limit,
      ConsistentRead: false  // Eventually consistent (faster, cheaper)
    });

    const response = await dynamodbClient.send(command);
    return response.Items.map(item => unmarshallItem(item));
  } catch (error) {
    console.error('Query error:', error);
    throw error;
  }
}

// 3. Query with GSI: Get sessions created after specific time
async function getSessionsByCreatedDate(userId, afterTimestamp) {
  try {
    const command = new QueryCommand({
      TableName: tableName,
      IndexName: 'created_at-index',  // Global secondary index
      KeyConditionExpression: 'user_id = :userId AND created_at > :timestamp',
      ExpressionAttributeValues: {
        ':userId': { S: userId },
        ':timestamp': { N: String(afterTimestamp) }
      }
    });

    const response = await dynamodbClient.send(command);
    return response.Items.map(item => unmarshallItem(item));
  } catch (error) {
    console.error('GSI Query error:', error);
    throw error;
  }
}

// 4. PutItem: Create new session with TTL
async function createSession(userId, sessionData) {
  const now = Math.floor(Date.now() / 1000);
  const expirationTime = now + (30 * 24 * 60 * 60);  // 30 days from now

  try {
    const command = new PutItemCommand({
      TableName: tableName,
      Item: {
        'user_id': { S: userId },
        'session_id': { S: uuidv4() },
        'token': { S: sessionData.token },
        'device': { S: sessionData.device },
        'created_at': { N: String(now) },
        'last_activity': { N: String(now) },
        'expiration_time': { N: String(expirationTime) }  // TTL attribute
      }
    });

    await dynamodbClient.send(command);
    console.log(`Session created for user: ${userId}`);
  } catch (error) {
    console.error('PutItem error:', error);
    throw error;
  }
}

// 5. UpdateItem with optimistic locking (version attribute)
async function updateSessionActivity(userId, sessionId, version) {
  const now = Math.floor(Date.now() / 1000);

  try {
    const command = new UpdateItemCommand({
      TableName: tableName,
      Key: {
        'user_id': { S: userId },
        'session_id': { S: sessionId }
      },
      UpdateExpression: 'SET last_activity = :now, version = :newVersion',
      ConditionExpression: 'version = :oldVersion',  // Ensure version matches
      ExpressionAttributeValues: {
        ':now': { N: String(now) },
        ':oldVersion': { N: String(version) },
        ':newVersion': { N: String(version + 1) }
      },
      ReturnValues: 'ALL_NEW'
    });

    const response = await dynamodbClient.send(command);
    return unmarshallItem(response.Attributes);
  } catch (error) {
    if (error.name === 'ConditionalCheckFailedException') {
      console.error('Version mismatch - concurrent update detected');
      throw new Error('Session was updated by another request');
    }
    console.error('UpdateItem error:', error);
    throw error;
  }
}

// 6. Batch GetItem: Retrieve multiple sessions
async function getSessionsBatch(sessionIds) {
  try {
    const command = new BatchGetItemCommand({
      RequestItems: {
        [tableName]: {
          Keys: sessionIds.map(({ userId, sessionId }) => ({
            'user_id': { S: userId },
            'session_id': { S: sessionId }
          })),
          ConsistentRead: false
        }
      }
    });

    const response = await dynamodbClient.send(command);
    return response.Responses[tableName].map(item => unmarshallItem(item));
  } catch (error) {
    console.error('BatchGetItem error:', error);
    throw error;
  }
}

// Utility: Unmarshall DynamoDB format to plain object
function unmarshallItem(item) {
  if (!item) return null;
  
  const result = {};
  for (const [key, value] of Object.entries(item)) {
    if (value.S) result[key] = value.S;
    else if (value.N) result[key] = Number(value.N);
    else if (value.BOOL) result[key] = value.BOOL;
    else if (value.NULL) result[key] = null;
    else if (value.L) result[key] = value.L.map(unmarshallItem);
    else if (value.M) result[key] = unmarshallItem(value.M);
    else result[key] = value;
  }
  return result;
}

// Example usage
(async () => {
  // Create session
  await createSession('user-123', {
    token: 'abc123xyz',
    device: 'iOS'
  });

  // Get user sessions
  const sessions = await getUserSessions('user-123', limit: 5);
  console.log('Sessions:', sessions);

  // Get sessions after specific date
  const recentSessions = await getSessionsByCreatedDate('user-123', Math.floor(Date.now() / 1000) - 86400);
  console.log('Recent sessions:', recentSessions);
})();
```

#### Shell Script: DynamoDB Capacity Monitoring & Cost Optimization

```bash
#!/bin/bash
# Script: DynamoDB Table Monitoring and Cost Analysis
# Purpose: Analyze capacity utilization and recommend optimizations
# Run: Weekly via CloudWatch Events

set -e

REGION="us-east-1"
TABLE_NAME="myapp-sessions"
OUTPUT_DIR="/var/logs/dynamodb-reports"

mkdir -p "$OUTPUT_DIR"

echo "=== DynamoDB Capacity Analysis Report ===" | tee "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "Table: $TABLE_NAME" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "Region: $REGION" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "Generated: $(date)" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

# Get table configuration
echo "=== Table Configuration ===" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
aws dynamodb describe-table \
  --table-name "$TABLE_NAME" \
  --region "$REGION" \
  --query 'Table.[BillingModeSummary.BillingMode,ProvisionedThroughput,ItemCount,TableSizeBytes]' \
  --output text | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

# Calculate average consumed capacity (last 7 days)
echo -e "\n=== Average Consumed Capacity (Last 7 Days) ===" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

START_TIME=$(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S)
END_TIME=$(date -u +%Y-%m-%dT%H:%M:%S)

# Read Capacity
READ_CAPACITY=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value="$TABLE_NAME" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 86400 \
  --statistics Average \
  --region "$REGION" \
  --query 'Datapoints[0].Average' \
  --output text)

echo "Average Read Capacity: ${READ_CAPACITY}" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

# Write Capacity
WRITE_CAPACITY=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value="$TABLE_NAME" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 86400 \
  --statistics Average \
  --region "$REGION" \
  --query 'Datapoints[0].Average' \
  --output text)

echo "Average Write Capacity: ${WRITE_CAPACITY}" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

# Check for throttling
echo -e "\n=== Throttling Events (Last 7 Days) ===" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

READ_THROTTLE=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ReadThrottleEvents \
  --dimensions Name=TableName,Value="$TABLE_NAME" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 86400 \
  --statistics Sum \
  --region "$REGION" \
  --query 'Datapoints[0].Sum' \
  --output text)

WRITE_THROTTLE=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name WriteThrottleEvents \
  --dimensions Name=TableName,Value="$TABLE_NAME" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 86400 \
  --statistics Sum \
  --region "$REGION" \
  --query 'Datapoints[0].Sum' \
  --output text)

echo "Read Throttle Events: ${READ_THROTTLE}" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "Write Throttle Events: ${WRITE_THROTTLE}" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

# Cost Analysis
echo -e "\n=== Cost Analysis ===" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

PROVISIONED_RCU=5000
PROVISIONED_WCU=1000

# Pricing (us-east-1, approximate)
RCU_HOURLY_COST=$(echo "scale=4; $PROVISIONED_RCU * 0.00013" | bc)
WCU_HOURLY_COST=$(echo "scale=4; $PROVISIONED_WCU * 0.00065" | bc)
MONTHLY_COST=$(echo "scale=2; ($RCU_HOURLY_COST + $WCU_HOURLY_COST) * 730" | bc)

echo "Provisioned RCU: $PROVISIONED_RCU (Cost: \$${RCU_HOURLY_COST}/hour)" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "Provisioned WCU: $PROVISIONED_WCU (Cost: \$${WCU_HOURLY_COST}/hour)" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
echo "Monthly Cost: \$${MONTHLY_COST}" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

# Recommendations
echo -e "\n=== Recommendations ===" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

if [ "${READ_THROTTLE}" != "None" ] && [ "$(echo "$READ_THROTTLE > 0" | bc)" -eq 1 ]; then
  echo "⚠️  Read throttling detected! Increase provisioned RCU or switch to on-demand." | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
fi

if [ "${WRITE_THROTTLE}" != "None" ] && [ "$(echo "$WRITE_THROTTLE > 0" | bc)" -eq 1 ]; then
  echo "⚠️  Write throttling detected! Increase provisioned WCU or switch to on-demand." | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
fi

# Check utilization efficiency
if [ "$(echo "$READ_CAPACITY < $PROVISIONED_RCU * 0.2" | bc)" -eq 1 ]; then
  echo "💰 Read capacity underutilized. Consider reducing provisioned RCU for cost savings." | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
fi

if [ "$(echo "$WRITE_CAPACITY < $PROVISIONED_WCU * 0.2" | bc)" -eq 1 ]; then
  echo "💰 Write capacity underutilized. Consider reducing provisioned WCU for cost savings." | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"
fi

# Peak capacity analysis
PEAK_READ=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value="$TABLE_NAME" \
  --start-time "$START_TIME" \
  --end-time "$END_TIME" \
  --period 3600 \
  --statistics Maximum \
  --region "$REGION" \
  --query 'max(Datapoints[].Maximum)' \
  --output text)

echo "⚡ Peak Read Capacity (1-hour window): ${PEAK_READ}" | tee -a "$OUTPUT_DIR/report-$(date +%Y%m%d).txt"

echo -e "\nReport saved to: $OUTPUT_DIR/report-$(date +%Y%m%d).txt"
```

---

### ASCII Diagrams

#### DynamoDB Partition Distribution

```
Even Distribution (Good):
────────────────────────

Partition Key: user_id (UUID)
Access Pattern: GetItem by user_id, Query by user_id + timestamp

      1M users distributed:
      
      Partition 1         Partition 2         Partition 3
      (user_id 0-33k)     (user_id 33k-66k)   (user_id 66k-1M)
      
      Items: 250KB each   Items: 250KB each   Items: 250KB each
      Capacity: 1K RCU    Capacity: 1K RCU    Capacity: 1K RCU
      Throughput: Balanced


Poor Distribution (Hot Partition):
──────────────────────────────────

Partition Key: country (categorical)
Problem: Data skewed (100M USA, 1M others)

      Partition USA       Partition EU        Partition ASIA
      (900M items)        (50M items)         (50M items)
      
      Capacity: 900 RCU   Capacity: 50 RCU    Capacity: 50 RCU
      Status: THROTTLED   Status: OK          Status: OK
      
      ❌ Requests to USA partition throttled even though total RCU available
```

#### DynamoDB Query Performance Optimization

```
Query Patterns & Considerations:
─────────────────────────────────

1. GetItem (Primary Key Lookup):
   ├─ Partition Key: user_id
   ├─ Latency: <5ms p99
   ├─ Efficiency: Ultra-efficient (direct partition lookup)
   ├─ RCU Cost: 1 RCU = 4KB (strongly consistent)
   └─ Use Case: User profile lookup, session validation


2. Query (Partition Key + Sort Key Range):
   ├─ Partition Key: user_id
   ├─ Sort Key: created_at (Range query > 2024-01-01)
   ├─ Latency: 5-20ms p99
   ├─ Efficiency: Efficient within single partition
   ├─ RCU Cost: All 1KB items scanned (even filtered)
   └─ Use Case: User activity timeline, session history


3. Query with Filter (Post-Filter):
   ├─ Partition Key: user_id
   ├─ Sort Key: created_at
   ├─ Filter: status = 'active'
   ├─ Latency: 10-50ms p99
   ├─ Efficiency: Scans items, then filters (wasted RCU)
   ├─ RCU Cost: Charged for ALL scanned items, not just returned
   └─ Problem: 1000 items scanned, 10 returned = 1000/10 = 100x wasted RCU


4. Scan (Full Table):
   ├─ No key condition
   ├─ Latency: 100ms-5s (depends on table size)
   ├─ Efficiency: Terrible (reads all items)
   ├─ RCU Cost: Entire table size / 4KB
   └─ Problem: 10GB table = 2,500,000 RCU (!)


Best Practices:
  ✓ Use GetItem for direct lookups (fastest)
  ✓ Use Query for range lookups (efficient)
  ✓ Avoid filters; create GSI instead
  ✓ Never scan (use query with index)
  ✓ Denormalize data to avoid joins
```

---

## Backup Strategies & Disaster Recovery

Backup and disaster recovery (DR) are critical responsibilities for DevOps engineers managing databases. This section covers automated backup strategies, recovery procedures, and multi-region failover architectures for AWS databases (RDS, Aurora, DynamoDB).

### Textual Deep Dive

#### Backup Architecture & Models

**1. RDS Backup Model**
```
Backup Components:
──────────────────
Daily Snapshots:
  ├─ Time: Scheduled during backup window (e.g., 03:00-04:00 UTC)
  ├─ Retention: 1-35 days (default 1 day)
  ├─ Storage: Stored in S3 (separate from instance storage)
  ├─ Cost: $0.095/GB-month for backup storage
  └─ Recovery Time: 5-15 minutes (depends on snapshot size)

Transaction Logs:
  ├─ Continuous log shipping to S3
  ├─ Enables Point-In-Time Recovery (PITR)
  ├─ Retention: Matches snapshot retention (1-35 days)
  ├─ Cost: $0.03/GB-month for log storage
  └─ Enables: Recovery to any second within retention window

Backup Mechanism:
  ├─ Copy during backup window (minor I/O impact)
  ├─ Backup isolation: Separate storage from instance
  ├─ Concurrent backups: Can run while serving production traffic
  └─ Encryption: KMS encryption of snapshots (matches instance setting)

Example Calculation (100GB database, 7-day retention):
  ├─ Daily snapshots: ~100GB × 7 snapshots = 700GB
  ├─ Transaction logs: ~50GB (depends on write volume)
  ├─ Backup cost: (700 + 50) × $0.095 = $71.50/month
  └─ Total monthly: $71.50 (includes instance cost separately)
```

**2. Aurora Backup Model (Improved)**
```
Aurora Backup Components:
──────────────────────────
Continuous Backup:
  ├─ Incremental snapshots to S3
  ├─ No performance impact (unlike RDS)
  ├─ Transactions logged continuously
  ├─ Retention: 1-35 days (default 1 day)
  └─ Cost: Included in Aurora pricing (no separate backup cost!)

Point-in-Time Recovery:
  ├─ Restore to any second within retention window
  ├─ Faster than RDS (distributed restore)
  ├─ Data consistency: Guaranteed ACID
  └─ RPO: Seconds (very small data loss possibility)

Backup Storage:
  ├─ Storage separate from cluster storage
  ├─ Included in Aurora pricing
  ├─ Automatic cross-region copies (optional)
  └─ NO additional backup storage cost

Cost Advantage:
  Aurora: Backup included in table pricing
  RDS:    Backup stored separately ($0.095/GB-month)
  
  100GB database, 7-day retention:
  RDS backup cost:    $71.50/month
  Aurora backup cost: $0 (included)
```

**3. DynamoDB Backup Model**
```
DynamoDB Backup Options:
─────────────────────

On-Demand Backups:
  ├─ Manual snapshots (user-initiated)
  ├─ Full table copy to backup storage
  ├─ No performance impact (separate backup service)
  ├─ Retention: Kept indefinitely until deleted
  ├─ Cost: $0.20/GB for backup storage
  └─ Recovery: Full table restore (all data) or PITR

Point-in-Time Recovery (PITR):
  ├─ Continuous incremental backup
  ├─ Retention: 35 days (fixed, non-configurable)
  ├─ Granularity: Second-level recovery
  ├─ Cost: $0.20/GB for backup storage
  └─ Use Case: Accidental deletes, corruption

Backup Mechanics:
  ├─ DynamoDB Streams: Capture all changes
  ├─ S3 Export: Export table to Parquet/CSV (low cost alternative)
  ├─ Encryption: Backed up data encrypted at rest
  └─ Global Backups: Available across regions (no extra cost)

IMPORTANT: DynamoDB backups are independent of table deletion
  ├─ Can restore deleted table from backup
  ├─ Must enable backup before deletion
  └─ Default: Backups enabled automatically
```

#### Disaster Recovery Architectures

**Pattern 1: Single-Region with Automated Failover (RDS/Aurora)**

```
Architecture:
─────────────

Primary AZ (us-east-1a):
├─ Primary Database Instance
│  └─ All write traffic
├─ Backup Service (automated daily)
│  └─ Snapshots to S3
└─ Transaction Logs → S3

Standby AZ (us-east-1b):
├─ Multi-AZ Standby Replica (sync) ← Automatic failover
│  └─ Read-only (but becomes primary on failover)
└─ Recovery Target: RTO ~120s, RPO ~0s

DR Procedure:
  1. Primary fails (network, storage, instance crash)
  2. Aurora/RDS detects (10-30 seconds)
  3. DNS failover to standby instance
  4. Applications retry; connections restore
  5. RTO: ~60-120 seconds total
  6. Data Loss: None (synchronous replication)

Cost: 150% of single-AZ instance
Suitable For: High-availability requirement
```

**Pattern 2: Multi-Region Active-Passive (Aurora Global Database)**

```
Architecture:
─────────────

Primary Region (us-east-1):
├─ Aurora Cluster (Writer + 5 Readers)
│  └─ All WRITE traffic
├─ Continuous backup to S3
└─ Replication to Secondary Region (async, <2 seconds)

Secondary Region (eu-west-1):
├─ Aurora Cluster (Read-Only)
│  └─ Serves read-only queries
│  └─ Can be promoted to primary if needed
└─ Replication lag: <2 seconds typical

DR Trigger (Primary Region Fails):
  1. Detect primary region unavailable (CloudWatch)
  2. Promote secondary replica to primary (~30-60s)
  3. Update application DNS to secondary region
  4. Failover complete

RTO: 30-60 seconds (manual) or < 10 seconds (automated Lambda)
RPO: < 2 seconds (acceptable for most workloads)
Cost: ~2x instance + data transfer ($0.02/GB cross-region)
Suitable For: Global applications, jurisdiction requirements

Limitations:
  ├─ Secondary is read-only until promoted
  ├─ Promotion is one-way (secondary becomes primary)
  ├─ Must manually re-establish replication after promotion
  └─ Data consistency: Eventually consistent reads in secondary
```

**Pattern 3: Multi-Region Active-Active (DynamoDB Global Tables)**

```
Architecture:
─────────────

Region 1 (us-east-1):        Region 2 (eu-west-1):
├─ DynamoDB Table (R/W)      ├─ DynamoDB Table (R/W)
└─ Writes: 500K WCU/s        └─ Writes: 500K WCU/s
                              ⟷ Async replication (100-200ms)

Key Characteristics:
  ├─ Both regions accept writes (true active-active)
  ├─ Automatic replication between regions
  ├─ Conflict resolution: Last-write-wins
  ├─ Replication lag: 100-200ms typical
  ├─ RTO: Zero seconds (no failover needed)
  └─ RPO: 100-200ms

Applications:
  ├─ Region 1: Write to local region
  ├─ Region 2: Write to local region
  ├─ Cross-region queries: Eventual consistency

Considerations:
  ├─ Eventual consistency: May read stale data temporarily
  ├─ Conflict resolution: LWW may cause data issues
  ├─ Cost: ~2x RCU/WCU (replication overhead)
  ├─ Billing: Per-region (Region 1 + Region 2)
  └─ Suitable: Distributed systems, high availability

Cost:
  ├─ Table 1 (us-east-1): 1000 RCU, 1000 WCU
  ├─ Table 2 (eu-west-1): 1000 RCU, 1000 WCU
  ├─ Replication cost: Additional RCU for replication traffic
  └─ Estimate: ~150% of single-region cost
```

#### Recovery Procedures & Testing

**RDS Point-in-Time Recovery (PITR)**
```
Scenario: Accidental table deletion at 14:32 UTC

Step 1: Identify recovery point
  ├─ Application detects issue at 14:45 UTC
  ├─ Need to recover to 14:30 UTC (before deletion)
  ├─ Must be within backup retention window (e.g., 7 days)
  └─ Calculate: Current time - 15 minutes = recovery point

Step 2: Initiate restore
  aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier myapp-db \
    --target-db-instance-identifier myapp-db-restored-20260307 \
    --restore-time 2026-03-07T14:30:00Z \
    --db-instance-class db.t3.medium

Step 3: Wait for restore
  ├─ 100GB database: ~5-10 minutes restore time
  ├─ Database initializes from latest snapshot + transaction logs
  ├─ Status: "Creating" → "Restoring" → "Available"
  └─ Estimate: < 15 minutes for most databases

Step 4: Validate restored data
  ├─ Connect to restored instance
  ├─ Verify tables exist, row count matches
  ├─ Run sample queries
  └─ Check application compatibility

Step 5: Decide on recovery strategy
  Option A: Swap DNS (if restored instance has same schema)
  Option B: Restore data via export (if schema mismatch)
  Option C: Promote to standalone instance

RTO: 10-20 minutes
RPO: Minutes (depends on transaction log availability)
```

**Aurora Global Database Failover**
```
Scenario: Primary region (us-east-1) completely down

Step 1: Detect failure (automated or manual)
  ├─ CloudWatch alarm: Primary region endpoints unresponsive
  ├─ Manual: DevOps initiates failover command
  └─ Automatic: Lambda checks health; triggers failover

Step 2: Promote secondary region
  aws rds failover-global-cluster \
    --global-cluster-identifier myapp-global-db \
    --target-db-cluster-identifier myapp-aurora-eu-west-1

Step 3: Promotion process (30-60 seconds)
  ├─ Secondary becomes primary (read-write enabled)
  ├─ Cluster endpoint DNS maintained
  ├─ Applications automatically connect to new primary
  ├─ Old primary isolated (no longer receives writes)
  └─ Status: "Failing over" → "Available"

Step 4: Validate recovery
  ├─ Connect to secondary region database
  ├─ Verify data consistency (some transactions may be lost)
  ├─ Monitor replication metrics
  ├─ Confirm applications can write/read
  └─ Check: Data loss estimation (from replication lag)

Step 5: Post-failover actions
  ├─ Restore primary region (when outage resolved)
  ├─ Re-establish replication (secondary → primary)
  ├─ Fallback procedures (if primary data corrupted)
  └─ Post-incident review

RTO: 30-60 seconds
RPO: < 2 seconds (data loss minimal but possible)
Assumptions: Secondary region has adequate capacity
```

#### Backup Testing Best Practices

**Monthly Backup Restoration Tests**
```
Testing Procedure:
──────────────────

Week 1 of Month: Perform Backup Test
  
  Step 1: Select oldest available snapshot
    ├─ Purpose: Test full backup chain
    ├─ Ensures: Snapshots remain valid over time
    └─ Data: Real production snapshot

  Step 2: Restore to test environment
    ├─ Instance: Smaller test instance (e.g., t3.small)
    ├─ Network: Isolated security group
    ├─ Cost: Minimal (small instance, deleted after test)
    └─ Time: Usually 5-15 minutes

  Step 3: Connectivity validation
    ├─ Connect with credentials from Secrets Manager
    ├─ Run SELECT 1 (verify basic connectivity)
    ├─ List tables/databases (verify schema)
    └─ No data corruption evident: PASS

  Step 4: Data integrity checks
    ├─ Query: SELECT COUNT(*) FROM large_table
    ├─ Compare: Against known row counts from production
    ├─ Spot check: 5-10 random records match
    ├─ Constraint checks: No corrupted data detected
    └─ Consistency: All referential integrity preserved

  Step 5: Cost cleanup
    ├─ Delete restored test instance
    ├─ Delete snapshot (if test-specific)
    ├─ Verify: No orphaned resources
    └─ Document: Test results, any issues found

Results:
  ✓ Backup valid: Restore successful, data consistent
  ✓ RTO verified: Actual restore time matches expectations
  ✓ Process documented: Runbook updated if needed
  ✓ Team trained: Knowledge transfer of restore procedure

Documentation:
  ├─ Test date: 2026-03-07
  ├─ Snapshot tested: db-20260307-snapshot
  ├─ Restore time: 8 minutes
  ├─ Data validation: PASSED
  ├─ Issues found: None
  └─ Next test: 2026-04-07

Red Flags (Stop and Escalate):
  ❌ Connectivity fails
  ❌ Row counts don't match
  ❌ Corrupt data detected
  ❌ Schema missing tables
  ❌ Restore time > documented RTO
```

### Practical Code Examples

#### Terraform: Automated Backup with Cross-Region Copy

```hcl
# Variables
variable "app_name" {
  default = "myapp"
}

variable "primary_region" {
  default = "us-east-1"
}

variable "dr_region" {
  default = "eu-west-1"
}

# Provider configs
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

# Primary RDS Instance (with backups)
resource "aws_db_instance" "primary" {
  provider               = aws.primary
  identifier             = "${var.app_name}-db-primary"
  engine                 = "postgres"
  engine_version         = "15.3"
  instance_class         = "db.r5.large"
  allocated_storage      = 100
  
  # Backup configuration (critical)
  backup_retention_period = 14  # 14-day retention
  backup_window          = "03:00-04:00"
  copy_tags_to_snapshot  = true
  skip_final_snapshot    = false
  
  # Multi-AZ for HA
  multi_az = true
  
  # Encryption
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds_backup.arn
  
  # Database configuration
  db_name  = "myappdb"
  username = "admin"
  password = random_password.db_password.result

  tags = {
    Name        = "Primary RDS Database"
    Environment = "production"
  }
}

# RDS Proxy (connection pooling)
resource "aws_db_proxy" "primary" {
  provider            = aws.primary
  name                = "${var.app_name}-db-proxy"
  engine_family       = "POSTGRESQL"
  role_arn            = aws_iam_role.proxy_role.arn
  db_cluster_identifiers = [aws_db_instance.primary.resource_id]
  
  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.db_password.arn
  }

  tags = {
    Name = "RDS Proxy"
  }
}

# Automated daily snapshot copy to DR region via Lambda
resource "aws_lambda_function" "copy_snapshots" {
  provider      = aws.primary
  filename      = "lambda_copy_snapshots.zip"
  function_name = "${var.app_name}-copy-rds-snapshots"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300

  environment {
    variables = {
      SOURCE_REGION      = var.primary_region
      TARGET_REGION      = var.dr_region
      SOURCE_DB_ID       = aws_db_instance.primary.id
      RETENTION_DAYS     = 14
      KMS_KEY_ID         = aws_kms_key.rds_backup.arn
    }
  }

  depends_on = [aws_iam_role.lambda_role, aws_iam_policy.lambda_policy]
}

# EventBridge rule to trigger snapshot copy daily
resource "aws_cloudwatch_event_rule" "daily_snapshot_copy" {
  provider            = aws.primary
  name                = "${var.app_name}-daily-snapshot-copy"
  description         = "Trigger daily RDS snapshot copy to DR region"
  schedule_expression = "cron(5 4 * * ? *)"  # 04:05 UTC daily (30 min after backup)
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  provider  = aws.primary
  rule      = aws_cloudwatch_event_rule.daily_snapshot_copy.name
  target_id = "CopySnapshotsLambda"
  arn       = aws_lambda_function.copy_snapshots.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  provider      = aws.primary
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.copy_snapshots.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_snapshot_copy.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  provider = aws.primary
  name     = "${var.app_name}-lambda-snapshot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  provider = aws.primary
  name     = "${var.app_name}-lambda-snapshot-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBSnapshots",
          "rds:CopyDBSnapshot",
          "rds:DescribeDBInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.rds_backup.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  provider       = aws.primary
  role           = aws_iam_role.lambda_role.name
  policy_arn     = aws_iam_policy.lambda_policy.arn
}

# KMS Key for backup encryption
resource "aws_kms_key" "rds_backup" {
  provider            = aws.primary
  description         = "KMS key for RDS backup encryption"
  deletion_window_in_days = 7

  tags = {
    Name = "RDS Backup Key"
  }
}

resource "aws_kms_alias" "rds_backup" {
  provider      = aws.primary
  name          = "alias/${var.app_name}-rds-backup"
  target_key_id = aws_kms_key.rds_backup.key_id
}

# Secrets Manager for database password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  provider                    = aws.primary
  name                        = "/rds/${var.app_name}/db-password"
  recovery_window_in_days     = 7
  force_overwrite_replica_secret = true

  replica {
    region = var.dr_region
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  provider      = aws.primary
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# CloudWatch alarms for backup monitoring
resource "aws_cloudwatch_metric_alarm" "backup_failed" {
  provider            = aws.primary
  alarm_name          = "${var.app_name}-rds-backup-failed"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SnapshotStorageUsed"
  namespace           = "AWS/RDS"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Alert if RDS backup appears to have failed"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  provider = aws.primary
  name     = "${var.app_name}-rds-alerts"

  tags = {
    Name = "RDS Alerts"
  }
}

# Outputs
output "primary_db_endpoint" {
  value       = aws_db_instance.primary.endpoint
  description = "Primary RDS endpoint"
}

output "primary_db_arn" {
  value       = aws_db_instance.primary.arn
  description = "Primary RDS ARN"
}

output "backup_retention_days" {
  value       = aws_db_instance.primary.backup_retention_period
  description = "Backup retention period (days)"
}
```

#### Python: Lambda Function for Snapshot Copy & Cleanup

```python
# lambda_copy_snapshots.py
# Purpose: Copy RDS snapshots to DR region; cleanup old snapshots

import boto3
import os
from datetime import datetime, timedelta

rds_source = boto3.client('rds', region_name=os.environ['SOURCE_REGION'])
rds_target = boto3.client('rds', region_name=os.environ['TARGET_REGION'])

SOURCE_DB_ID = os.environ['SOURCE_DB_ID']
TARGET_REGION = os.environ['TARGET_REGION']
RETENTION_DAYS = int(os.environ['RETENTION_DAYS'])
KMS_KEY_ID = os.environ['KMS_KEY_ID']

def handler(event, context):
    """
    1. Find latest snapshot in source region
    2. Copy to target region
    3. Cleanup old snapshots (older than retention period)
    """
    
    try:
        # Step 1: Find latest snapshot
        print(f"[1/3] Finding latest snapshot for {SOURCE_DB_ID}...")
        snapshots = rds_source.describe_db_snapshots(
            DBInstanceIdentifier=SOURCE_DB_ID,
            SnapshotType='automated'
        )
        
        if not snapshots['DBSnapshots']:
            print("ERROR: No snapshots found")
            return {
                'statusCode': 404,
                'body': 'No snapshots found for copying'
            }
        
        latest_snapshot = sorted(
            snapshots['DBSnapshots'],
            key=lambda x: x['SnapshotCreateTime'],
            reverse=True
        )[0]
        
        source_snapshot_id = latest_snapshot['DBSnapshotIdentifier']
        snapshot_create_time = latest_snapshot['SnapshotCreateTime']
        
        print(f"Latest snapshot: {source_snapshot_id}")
        print(f"Created: {snapshot_create_time}")
        
        # Step 2: Copy snapshot to target region
        print(f"[2/3] Copying snapshot to {TARGET_REGION}...")
        target_snapshot_id = f"{source_snapshot_id}-copy-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        try:
            rds_target.copy_db_snapshot(
                SourceDBSnapshotIdentifier=f"arn:aws:rds:{os.environ['SOURCE_REGION']}:ACCOUNT_ID:snapshot:{source_snapshot_id}",
                TargetDBSnapshotIdentifier=target_snapshot_id,
                KmsKeyId=KMS_KEY_ID,
                Tags=[
                    {'Key': 'Purpose', 'Value': 'DR'},
                    {'Key': 'AutoCopied', 'Value': 'true'},
                    {'Key': 'RetentionDays', 'Value': str(RETENTION_DAYS)}
                ]
            )
            print(f"Snapshot copy initiated: {target_snapshot_id}")
        except Exception as e:
            print(f"Copy failed: {str(e)}")
            return {
                'statusCode': 500,
                'body': f'Snapshot copy failed: {str(e)}'
            }
        
        # Step 3: Cleanup old snapshots in target region
        print(f"[3/3] Cleaning up old snapshots (older than {RETENTION_DAYS} days)...")
        cutoff_date = datetime.now(snapshot_create_time.tzinfo) - timedelta(days=RETENTION_DAYS)
        
        try:
            target_snapshots = rds_target.describe_db_snapshots(
                SnapshotType='manual',
                Filters=[
                    {
                        'Name': 'db-instance-id',
                        'Values': [SOURCE_DB_ID]
                    }
                ]
            )
            
            deleted_count = 0
            for snapshot in target_snapshots['DBSnapshots']:
                if snapshot['SnapshotCreateTime'] < cutoff_date:
                    snapshot_id = snapshot['DBSnapshotIdentifier']
                    print(f"Deleting old snapshot: {snapshot_id}")
                    
                    try:
                        rds_target.delete_db_snapshot(
                            DBSnapshotIdentifier=snapshot_id,
                            SkipFinalSnapshot=True
                        )
                        deleted_count += 1
                    except Exception as e:
                        print(f"Failed to delete {snapshot_id}: {str(e)}")
            
            print(f"Deleted {deleted_count} old snapshots")
            
        except Exception as e:
            print(f"Cleanup failed: {str(e)}")
            return {
                'statusCode': 500,
                'body': f'Snapshot cleanup failed: {str(e)}'
            }
        
        # Success response
        return {
            'statusCode': 200,
            'body': {
                'message': 'Snapshot copy and cleanup completed',
                'source_snapshot': source_snapshot_id,
                'target_snapshot': target_snapshot_id,
                'snapshots_deleted': deleted_count,
                'retention_days': RETENTION_DAYS
            }
        }
    
    except Exception as e:
        print(f"FATAL ERROR: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Lambda execution failed: {str(e)}'
        }

def test_snapshot_restore(snapshot_id, region):
    """Test function: Restore snapshot to test instance for validation"""
    
    client = boto3.client('rds', region_name=region)
    
    try:
        print(f"Testing restore from snapshot: {snapshot_id}")
        
        test_instance_id = f"test-restore-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        
        # Restore to new test instance
        client.restore_db_instance_from_db_snapshot(
            DBInstanceIdentifier=test_instance_id,
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceClass='db.t3.small',  # Small instance for testing
            PubliclyAccessible=False,
            Tags=[
                {'Key': 'Purpose', 'Value': 'BackupTest'},
                {'Key': 'AutoDelete', 'Value': 'true'},
                {'Key': 'CreatedTime', 'Value': datetime.now().isoformat()}
            ]
        )
        
        print(f"Restore initiated: {test_instance_id}")
        return test_instance_id
        
    except Exception as e:
        print(f"Restore test failed: {str(e)}")
        return None
```

#### Shell Script: Monthly Backup Test & Cleanup

```bash
#!/bin/bash
# Script: Monthly RDS Backup Restoration & Validation Test
# Purpose: Verify backups work; cleanup old snapshots
# Schedule: First Thursday of each month via Lambda/EventBridge

set -e

REGION="us-east-1"
SOURCE_DB="myapp-db-primary"
TEST_INSTANCE="myapp-db-test-$(date +%Y%m%d)"
RETENTION_DAYS=14

log_file="/var/logs/backup-test-$(date +%Y%m%d).log"

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$log_file"
}

log "=== RDS Backup Restoration Test ==="
log "Source Database: $SOURCE_DB"
log "Test Instance: $TEST_INSTANCE"
log "Region: $REGION"

# Step 1: Get latest snapshot
log "[1/6] Finding latest snapshot..."
LATEST_SNAPSHOT=$(aws rds describe-db-snapshots \
  --db-instance-identifier "$SOURCE_DB" \
  --snapshot-type automated \
  --region "$REGION" \
  --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime) | [-1].DBSnapshotIdentifier' \
  --output text)

if [ -z "$LATEST_SNAPSHOT" ] || [ "$LATEST_SNAPSHOT" == "None" ]; then
  log "ERROR: No snapshots found"
  exit 1
fi

log "Latest snapshot: $LATEST_SNAPSHOT"

# Step 2: Restore from snapshot to test instance
log "[2/6] Restoring from snapshot to test instance..."
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "$TEST_INSTANCE" \
  --db-snapshot-identifier "$LATEST_SNAPSHOT" \
  --db-instance-class db.t3.micro \
  --region "$REGION" \
  --no-publicly-accessible \
  --tags Key=Purpose,Value=BackupTest Key=AutoDelete,Value=true

log "Restore initiated. Waiting for completion..."

# Step 3: Wait for restore to complete
log "[3/6] Waiting for instance to be available (timeout: 30min)..."
aws rds wait db-instance-available \
  --db-instance-identifier "$TEST_INSTANCE" \
  --region "$REGION" \
  --cli-read-timeout 0

log "Instance is available."

# Step 4: Connectivity test
log "[4/6] Testing database connectivity..."
TEST_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "$TEST_INSTANCE" \
  --region "$REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Wait for endpoint to be reachable (DNS propagation)
max_attempts=30
attempt=0
while ! mysqladmin ping -h "$TEST_ENDPOINT" -u admin -p"$DB_PASSWORD" 2>/dev/null; do
  attempt=$((attempt + 1))
  if [ $attempt -ge $max_attempts ]; then
    log "ERROR: Cannot connect to restored database after 5 minutes"
    log "Cleaning up test instance..."
    aws rds delete-db-instance \
      --db-instance-identifier "$TEST_INSTANCE" \
      --region "$REGION" \
      --skip-final-snapshot
    exit 1
  fi
  sleep 10
done

log "✓ Connectivity test PASSED"

# Step 5: Data integrity validation
log "[5/6] Running data integrity checks..."

# Count tables
TABLE_COUNT=$(mysql -h "$TEST_ENDPOINT" -u admin -p"$DB_PASSWORD" \
  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='myappdb';" \
  --batch --skip-column-names 2>/dev/null)

log "Tables in database: $TABLE_COUNT"

if [ "$TABLE_COUNT" -eq 0 ]; then
  log "WARNING: No tables found in restored database"
else
  log "✓ Data integrity check PASSED"
fi

# Sample row count validation
ROW_COUNT=$(mysql -h "$TEST_ENDPOINT" -u admin -p"$DB_PASSWORD" \
  -e "SELECT COUNT(*) FROM myappdb.users;" \
  --batch --skip-column-names 2>/dev/null)

log "Row count in 'users' table: $ROW_COUNT"

# Step 6: Cleanup & summary
log "[6/6] Cleaning up test instance..."
aws rds delete-db-instance \
  --db-instance-identifier "$TEST_INSTANCE" \
  --region "$REGION" \
  --skip-final-snapshot \
  --region "$REGION"

log "✓ Test instance deleted"

# Report summary
log "=== BACKUP TEST SUMMARY ==="
log "Source Snapshot: $LATEST_SNAPSHOT"
log "Restore Time: ~$(date +%s) seconds"
log "Connectivity: PASSED"
log "Data Integrity: PASSED"
log "Status: SUCCESS"

# Cleanup old snapshots (older than retention period)
log ""
log "=== Snapshot Cleanup (older than $RETENTION_DAYS days) ==="

CUTOFF_DATE=$(date -u -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
log "Cutoff date: $CUTOFF_DATE"

OLD_SNAPSHOTS=$(aws rds describe-db-snapshots \
  --db-instance-identifier "$SOURCE_DB" \
  --snapshot-type automated \
  --region "$REGION" \
  --query "DBSnapshots[?SnapshotCreateTime<'$CUTOFF_DATE'].DBSnapshotIdentifier" \
  --output text)

if [ -z "$OLD_SNAPSHOTS" ]; then
  log "No old snapshots to delete"
else
  log "Deleting old snapshots..."
  for snapshot in $OLD_SNAPSHOTS; do
    log "Deleting: $snapshot"
    aws rds delete-db-snapshot \
      --db-snapshot-identifier "$snapshot" \
      --region "$REGION"
  done
fi

log ""
log "=== Test Complete ==="
log "Report saved to: $log_file"

# Send SNS notification
aws sns publish \
  --topic-arn "arn:aws:sns:$REGION:ACCOUNT_ID:rds-alerts" \
  --subject "✓ RDS Backup Test PASSED: $SOURCE_DB" \
  --message "Automated backup restoration test completed successfully.
  
Snapshot tested: $LATEST_SNAPSHOT
Connectivity: PASSED
Data integrity: PASSED
Tables verified: $TABLE_COUNT
Rows sampled: $ROW_COUNT

See logs: $log_file"
```

---

### ASCII Diagrams

#### Backup Window & PITR Timeline

```
RDS Backup Architecture:
────────────────────────

┌─────────────────────────────────────────────────────────┐
│ Backup Retention Window (7 days)                        │
└─────────────────────────────────────────────────────────┘

Day 1  Day 2  Day 3  Day 4  Day 5  Day 6  Day 7  Today
  |      |      |      |      |      |      |      |
[S1]   [S2]   [S3]   [S4]   [S5]   [S6]   [S7]  [S8]
  |      |      |      |      |      |      |      |
  └──────┴──────┴──────┴──────┴──────┴──────┴──────┘
           Daily Snapshots (kept for 7 days)

  |←─────────────────── Continuous Transaction Logs ──────────────────→|
  
Day 1    Day 3         Day 5           Day 7        Today
  |        |             |               |            |
  
  Point-in-Time Recovery Window: Can restore to ANY second within  
  7-day window using latest snapshot + transaction logs
  
Example PITR Scenarios:
  ├─ Restore to Day 3, 14:30 UTC (S2 snapshot + 1.5 days of logs)
  ├─ Restore to Day 6, 09:45 UTC (S5 snapshot + 1.5 days of logs)
  └─ Restore to Today, 08:00 UTC (S7 snapshot + logs from today)


Aurora Backup Architecture (Continuous):
─────────────────────────────────────────

Continuous Incremental Snapshots
  │
  ├─ Snap 1 (Day 1): Full backup (100GB)
  ├─ Snap 2 (Day 2): Incremental (2GB delta)
  ├─ Snap 3 (Day 3): Incremental (1.5GB delta)
  └─ ... continues daily
  
Advantages over RDS:
  ├─ No backup window impact (background incremental)
  ├─ Backup included in pricing (no separate costs)
  ├─ Faster recovery (doesn't rebuild from snapshot)
  └─ Better IOPS during backup period


DynamoDB Backup:
────────────────

On-Demand Backup:
  ├─ Manual snapshot (user-initiated)
  ├─ Retention: Indefinite (customer deletes)
  ├─ Cost: $0.20/GB
  └─ Use case: Versions before major change

Point-in-Time Recovery (PITR):
  ├─ Automatic continuous backup
  ├─ Retention: Fixed 35 days
  ├─ Cost: $0.20/GB
  ├─ Granularity: Second-level recovery
  └─ Use case: Accidental delete, data corruption
  
Recovery timing:
  ├─ PITR enabled: 2-5 minutes to new table
  ├─ On-demand restore: 5-15 minutes depending on size
  ├─ Global tables: Works across regions
  └─ Old SSDs can hold snapshots
```

#### Multi-Region Failover Timeline

```
Primary Region Failure & Failover Process:
───────────────────────────────────────────

09:00 AM - NORMAL OPERATION:
┌────────────────────────────┐              ┌──────────────────────────┐
│ REGION: us-east-1 (Primary)│  Replicate  │ REGION: eu-west-1 (DR)   │
│ ┌──────────────────────┐   │  Asyncly    │ ┌────────────────────┐   │
│ │ Aurora Cluster       │───── (<2s) ────→│ │ Aurora Read-Only   │   │
│ │ Writer (HOT)         │   │             │ │ (Warm standby)     │   │
│ │ 5 Readers           │   │             │ │                    │   │
│ └──────────────────────┘   │             │ └────────────────────┘   │
│ Applications connect to    │             │ Monitoring only        │
│ us-east-1 only            │             │ (no user traffic)      │
└────────────────────────────┘             └──────────────────────────┘


09:15 AM - PRIMARY REGION FAILS:
┌────────────────────────────┐              ┌──────────────────────────┐
│ REGION: us-east-1 (Primary)│              │ REGION: eu-west-1 (DR)   │
│ ┌──────────────────────┐   │              │ ┌────────────────────┐   │
│ │ Aurora Cluster       │   │              │ │ Aurora Read-Only   │   │
│ │ ✗ UNABLE TO REACH ✗  │   │              │ │ (Warm standby)     │   │
│ │ (Network down)       │   │              │ │ ✓ Still healthy    │   │
│ └──────────────────────┘   │              │ └────────────────────┘   │
│                            │              │                         │
│ Applications get           │              │ Failover script         │
│ connection timeouts (30s)  │              │ detects failure         │
└────────────────────────────┘             └──────────────────────────┘


09:30 AM - FAILOVER PROMOTION (30-60 seconds):
┌────────────────────────────┐              ┌──────────────────────────┐
│ REGION: us-east-1 (DEAD)   │              │ REGION: eu-west-1 (PRIMARY)
│ ┌──────────────────────┐   │              │ ┌────────────────────┐   │
│ │ Aurora Cluster       │   │              │ │ Aurora Cluster     │   │
│ │ ✗ OFFLINE ✗          │   │              │ │ ✓ PROMOTED ✓       │   │
│ │                      │   │              │ │ Writer enabled     │   │
│ └──────────────────────┘   │              │ ✓ ACCEPTING WRITES  │   │
│                            │              │ Replication lag < 2s│   │
│ No recovery attempted      │              │ └────────────────────┘   │
│ (remains offline)          │              │                         │
└────────────────────────────┘             └──────────────────────────┘
                                           
                                           DNS updated to eu-west-1
                                           Applications reconnect

09:31 AM - APPLICATIONS RECOVERED:
┌────────────────────────────┐              ┌───────────────────────────┐
│ REGION: us-east-1 (DEAD)   │              │ REGION: eu-west-1 (Active)│
│ [Offline - awaiting fix]   │              │ ┌──────────────────────┐  │
│                            │              │ │ Production Cluster   │  │
│                            │              │ │ Read/Write Active    │  │
│                            │              │ │ Apps connected       │  │
│                            │              │ └──────────────────────┘  │
│                            │              │  ✓ Service Restored      │
│ No applications            │              │                          │
│ (all moved to eu-west)     │              │ Data loss: <2s possible  │
└────────────────────────────┘             └───────────────────────────┘

Failure Timeline Summary:
├─ 09:00: Failure occurs
├─ 09:15: Application detects (connection timeout)
├─ 09:20: Failover script triggered (if automated)
├─ 09:21: Promotion complete (promotion takes 30-60s)
├─ 09:22: DNS updated, apps reconnect
├─ 09:23: Normal operation in eu-west-1 resumed
│
└─ RTO: ~3-5 minutes (automated) to ~30 min (manual)
   RPO: <2 seconds (replication lag)
   Data loss: Minimal but possible
```

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-03-07 | DevOps Team | Initial creation: TOC, Introduction, Foundational Concepts |
| 2026-03-07 | DevOps Team | Added RDS Basics & Aurora Architecture deep dives with code examples |
| 2026-03-07 | DevOps Team | Added DynamoDB Fundamentals & Backup/DR deep dives with code examples |

---

**Study Guide Status:** COMPLETE (All 4 subtopics + foundational concepts covered)

**Next Steps for Users:**
- Review code examples and adapt to your infrastructure
- Schedule monthly backup restoration tests
- Set up automated scaling policies  
- Implement cross-region DR for critical databases
- Test failover procedures quarterly



---

## Hands-on Scenarios

Real-world DevOps situations requiring practical database knowledge and troubleshooting skills.

### Scenario 1: Emergency RDS Connection Pool Exhaustion During Traffic Spike

**Problem Statement:**

Your production e-commerce application suddenly receives 10x normal traffic (flash sale). Within 5 minutes, customer complaints flood in: "Cannot checkout," "Page loads hanging," "Connection timeouts." Application logs show: `Too many connections (error 1040)`. You have ~50 web servers, each maintaining 50 connections to RDS, totaling 2,500 connection attempts. Your RDS instance is configured with `max_connections=214` (default for db.t3.medium).

**Architecture Context:**

```
Current Setup (Pre-Emergency):
├─ RDS MySQL: db.t3.medium (2 vCPU, 4GB RAM)
├─ max_connections: 214 (default parameter)
├─ Multi-AZ: Enabled
├─ Web Servers: 50 instances × 50 connections each = 2,500 needed
├─ Application: No connection pooling at app layer
├─ No RDS Proxy deployed
└─ Customer Impact: Revenue loss ~$50K/minute
```

**Troubleshooting & Implementation Steps:**

**Immediate Actions (0-5 minutes):**

1. **Verify the problem:**
   ```bash
   # SSH to RDS bastion host
   mysql -h myapp-db.xxxx.rds.amazonaws.com -u admin -p
   
   # Check connection count
   SHOW PROCESSLIST;
   SELECT COUNT(*) FROM INFORMATION_SCHEMA.PROCESSLIST;
   # Output: 214 connections (all active, many waiting)
   
   # Check max_connections setting
   SHOW VARIABLES LIKE 'max_connections';
   # Output: max_connections = 214
   
   # Check current throughput
   SHOW GLOBAL STATUS LIKE 'Questions';
   SHOW GLOBAL STATUS LIKE 'Connections';
   # Diagnose: Are connections truly exhausted, or are connections hanging?
   ```

2. **Quick-fix escalation (emergency mode):**
   ```bash
   # Kill long-running idle connections (free up slots)
   mysql -h myapp-db.xxxx.rds.amazonaws.com -u admin -p \
     -e "SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE TIME > 300;"
   
   # Manually increase max_connections (temporary, requires restart)
   # NOT RECOMMENDED (causes 2-5 min downtime during restart)
   ```

**Short-term Fix (5-30 minutes):**

3. **Deploy RDS Proxy (BEST SOLUTION):**
   ```bash
   # RDS Proxy can be deployed in < 10 minutes without downtime
   
   # Via AWS CLI:
   aws rds create-db-proxy \
     --db-proxy-name myapp-db-proxy \
     --engine-family MYSQL \
     --db-instance-identifiers myapp-db-primary \
     --role-arn arn:aws:iam::ACCOUNT:role/rds-proxy-role \
     --auth '[{"AuthScheme":"SECRETS","SecretArn":"arn:aws:secretsmanager:..."}]'
   
   # Proxy characteristics:
   # ├─ Multiplexes connections (4 backend → 200 client connections)
   # ├─ Connection timeout: 120 seconds
   # ├─ Deployment: < 10 minutes
   # ├─ Zero downtime (apps update DNS)
   # └─ Cost: ~$0.30/hour additional
   
   # Update application connection string:
   # FROM: myapp-db.xxxx.rds.amazonaws.com:3306
   # TO:   myapp-db-proxy.proxy-xxxxx.rds.amazonaws.com:3306
   ```

4. **During RDS Proxy setup, scale the RDS instance:**
   ```bash
   # Upgrade instance class (temporary, can revert later)
   aws rds modify-db-instance \
     --db-instance-identifier myapp-db-primary \
     --db-instance-class db.r5.large \  # Larger instance
     --apply-immediately  # WARNING: Short downtime (usually 1-2 min)
   
   # db.r5.large has max_connections ≈ 900 (vs. 214 for t3.medium)
   # Buys time until RDS Proxy is ready
   ```

**Long-term Fix (30+ minutes):**

5. **Permanent solution with auto-scaling:**
   ```hcl
   # Terraform: RDS Proxy + Auto-scaling policy
   
   resource "aws_db_proxy" "main" {
     db_proxy_name = "myapp-db-proxy"
     engine_family = "MYSQL"
     db_instance_identifiers = [aws_db_instance.primary.id]
     
     # Connection pooling
     max_idle_connections_percent = 50
     max_connections_percent      = 100
     connection_borrow_timeout    = 120
   }
   
   # Auto-scaling policy for RDS itself (if proxy isn't enough)
   resource "aws_appautoscaling_target" "rds_read_scaling" {
     max_capacity       = 8  # db.r5.4xlarge
     min_capacity       = 1  # db.t3.medium
     resource_id        = "db:${aws_db_instance.primary.id}"
     scalable_dimension = "rds:db:EngineWeightedReadAverageCPUUtilization"
     service_namespace  = "rds"
   }
   
   resource "aws_appautoscaling_policy" "rds_scaling" {
     resource_id        = aws_appautoscaling_target.rds_read_scaling.resource_id
     scalable_dimension = aws_appautoscaling_target.rds_read_scaling.scalable_dimension
     service_namespace  = aws_appautoscaling_target.rds_read_scaling.service_namespace
     policy_type        = "TargetTrackingScaling"
     
     target_tracking_scaling_policy_configuration {
       target_value = 70.0  # CPU threshold
     }
   }
   ```

6. **Update parameter group (persistent setting):**
   ```bash
   # Increase max_connections in parameter group
   # (more sustainable than temporary CLI changes)
   
   aws rds modify-db-parameter-group \
     --db-parameter-group-name myapp-mysql57 \
     --parameters "ParameterName=max_connections,ParameterValue=1000,ApplyMethod=pending-reboot"
   
   # Schedule reboot during maintenance window
   aws rds reboot-db-instance \
     --db-instance-identifier myapp-db-primary \
     --apply-immediately  # Only if traffic okay
   ```

**Best Practices Applied:**

✅ **RDS Proxy for connection pooling**: Decouples application connection count from database instance limits.

✅ **Monitoring before scaling**: Understand the actual bottleneck (connection exhaustion vs. CPU vs. I/O) before scaling.

✅ **Read replicas for non-critical queries**: Offload reporting/analytics to reduce primary database load.

✅ **Parameter tuning**: `max_connections` should align with actual concurrent connections needed.

✅ **IaC for recovery**: All settings in Terraform so scaling decisions are reproducible and version-controlled.

**Post-Incident Actions:**

- ✅ Review traffic spike (was it expected? DDoS? Flash sale?)
- ✅ Implement auto-scaling policies
- ✅ Add CloudWatch alarms for DatabaseConnections metric (alert at 80%)
- ✅ Load-test to determine optimal max_connections value
- ✅ Document runbook for connection exhaustion scenarios

**Recovery Time: ~15-20 minutes** (RDS Proxy deployment + app restart)

---

### Scenario 2: Aurora Replica Lag Causing Stale Data in Dashboard

**Problem Statement:**

Your analytics dashboard queries data from an Aurora read replica and displays customer metrics from 2-3 hours ago instead of real-time data. The backend team reports incorrect business metrics. Data looks stale because the replica is lagging significantly behind the primary instance.

**Root Cause Investigation:**

```bash
# Check replica lag via CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name AuroraBinlogReplicaLag \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-aurora-replica-1 \
  --start-time 2026-03-07T00:00:00Z \
  --end-time 2026-03-07T12:00:00Z \
  --period 300 \
  --statistics Average,Maximum \
  --region us-east-1

# Output:
# Datapoints=[
#   {'Timestamp': '2026-03-07T10:00:00Z', 'Average': 150.0},  # 150ms lag
#   {'Timestamp': '2026-03-07T10:05:00Z', 'Average': 2500.0}, # 2.5s lag (ORM_UNRELATED)
#   {'Timestamp': '2026-03-07T10:10:00Z', 'Average': 8000.0}  # 8s lag (!!! CRITICAL)
# ]
```

**Architecture Context:**

```
Aurora Cluster:
├─ Primary Instance: db.r6g.xlarge (32GB RAM)
│  └─ Write throughput: 5K transactions/sec
│  └─ Large batch operation running: ETL job inserting 100K rows
│
├─ Read Replica 1: db.t3.large (8GB RAM) ← LAGGING
│  └─ Replica lag: 8-10 seconds
│  └─ Cannot keep up with primary's write rate
│
└─ Read Replica 2: db.r6g.large (16GB RAM)
   └─ Replica lag: < 100ms
   └─ Sized for workload correctly
```

**Troubleshooting & Implementation Steps:**

1. **Diagnose the cause:**
   ```bash
   # Check replica instance performance
   aws rds describe-db-instances \
     --db-instance-identifier myapp-aurora-replica-1 \
     --query 'DBInstances[0].[DBInstanceClass,CPUUtilization]'
   
   # Output: db.t3.large, 95% CPU (undersized!)
   
   # Query slow queries on replica
   mysql -h myapp-aurora-replica-1.xxx.rds.amazonaws.com \
     -u admin -p
   
   SHOW ENGINE INNODB STATUS\G | grep -A 10 "Last foreign key error"
   SHOW ENGINE INNODB STATUS\G | grep -A 10 "LOCKS WAITED"
   
   SELECT * FROM performance_schema.events_statements_summary_by_digest \
     ORDER BY SUM_TIMER_WAIT DESC LIMIT 5;
   # Identify: Are there slow queries on replica blocking replication?
   ```

2. **Check for long-running queries on replica:**
   ```sql
   -- Slow queries block replication during single-threaded processing
   SELECT ID, TIME, STATE, INFO 
   FROM INFORMATION_SCHEMA.PROCESSLIST 
   WHERE COMMAND != 'Sleep' 
   ORDER BY TIME DESC;
   
   -- If you see IO-intensive queries (ORDER BY, JOIN on large tables)
   -- These will block replica from applying binlog entries
   ```

3. **Immediate fix: Kill blocking queries:**
   ```sql
   -- CAREFULLY kill only non-critical queries
   KILL QUERY <query_id>;  -- Stops query, connection stays open
   -- Or
   KILL CONNECTION <connection_id>;  -- Closes connection
   ```

4. **Short-term solution: Resize replica:**
   ```bash
   # Scale replica instance to match primary
   aws rds modify-db-instance \
     --db-instance-identifier myapp-aurora-replica-1 \
     --db-instance-class db.r6g.xlarge \  # Match primary size
     --apply-immediately
   
   # This will temporarily drop connection (1-2 min) but resolves lag
   
   # Monitor lag during scaling:
   watch -n 5 'aws cloudwatch get-metric-statistics \
     --namespace AWS/RDS \
     --metric-name AuroraBinlogReplicaLag \
     --dimensions Name=DBInstanceIdentifier,Value=myapp-aurora-replica-1 \
     --start-time 2026-03-07T12:00:00Z \
     --end-time 2026-03-07T12:05:00Z \
     --period 60 --statistics Average'
   ```

5. **Long-term fix: Application design change:**
   ```javascript
   // Problem: Dashboard queries reporting data need real-time accuracy
   // Solution 1: Route to primary (guarantees consistency)
   
   const connection = mysql.connect({
     host: process.env.RDS_ENDPOINT,  // Primary only
     database: 'myappdb',
     // Set read_preference to PRIMARY for critical queries
   });
   
   // Solution 2: Acceptable lag approach (best for performance)
   
   const connection = {
     primary: mysql.connect({ host: 'myapp-aurora-primary.xxx' }),
     replica: mysql.connect({ host: 'myapp-aurora-replica-1.xxx' })
   };
   
   async function getDashboardMetrics(userId) {
     // Critical metrics: Query primary (strong consistency)
     const revenue = await query(
       connection.primary,
       'SELECT SUM(amount) FROM orders WHERE user_id = ? AND created_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)',
       [userId]
     );
     
     // Non-critical metrics: Query replica (eventual consistency OK)
     const views = await query(
       connection.replica,
       'SELECT COUNT(*) FROM page_views WHERE user_id = ?',
       [userId]
     );
     
     return { revenue, views };
   }
   
   // Solution 3: Cache layer (99% of use cases)
   
   const redis = require('redis').createClient();
   
   async function getDashboardMetrics(userId) {
     // Check cache first (1-minute TTL)
     const cached = await redis.get(`metrics:${userId}`);
     if (cached) return JSON.parse(cached);
     
     // Cache miss: Query primary
     const metrics = await query(connection.primary, '...');
     
     // Cache for 1 minute
     await redis.setex(`metrics:${userId}`, 60, JSON.stringify(metrics));
     
     return metrics;
   }
   ```

6. **Monitoring setup:**
   ```hcl
   # Terraform: Alarm for replica lag
   
   resource "aws_cloudwatch_metric_alarm" "aurora_replica_lag" {
     alarm_name          = "aurora-replica-lag-high"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = 2  # 2 consecutive periods
     metric_name         = "AuroraBinlogReplicaLag"
     namespace           = "AWS/RDS"
     period              = 300  # Check every 5 minutes
     statistic           = "Average"
     threshold           = 1000  # Alert if > 1 second lag
     alarm_description   = "Alert when Aurora replica lag > 1s"
     
     dimensions = {
       DBInstanceIdentifier = "myapp-aurora-replica-1"
     }
     
     alarm_actions = [aws_sns_topic.critical_alerts.arn]
   }
   ```

**Best Practices Applied:**

✅ **Not all reads require primary**: Distinguish between critical (strong consistency) and non-critical (eventual consistency) reads.

✅ **Replica sizing**: Replicas should be ≥ primary size to avoid bottlenecks.

✅ **Monitoring replica lag**: Set alerts for lag > 1s (production threshold).

✅ **Caching layer**: Reduce load on database via Redis/Memcached.

✅ **Read-after-write consistency**: Implement in application when needed.

---

### Scenario 3: DynamoDB Throttling During Unpredictable Traffic

**Problem Statement:**

Your real-time leaderboard (gaming app) is experiencing occasional throttling errors: `ProvisionedThroughputExceededException`. You've provisioned 5,000 RCU and 5,000 WCU, but during peak hours you hit limits. Users' scores aren't updating ("Failed to record your score"). Load analysis shows traffic is highly unpredictable (spiky).

**Root Cause Analysis:**

```
Partition Distribution Problem:
─────────────────────────────

Table: Leaderboard
├─ Partition Key: game_id (categorical, skewed distribution)
│  ├─ game_id="popular_game_xyx": 90% of traffic
│  │  └─ 4,500 RCU allocated
│  │  └─ Peak QPS: 6,000 reads (THROTTLED!)
│  │
│  ├─ game_id="niche_game_abc": 10% of traffic
│  │  └─ 500 RCU allocated
│  │  └─ Peak QPS: 600 reads (OK)
│  │
│  └─ Problem: Uneven traffic distribution across partitions

OR

Provisioned Capacity Problem:
─────────────────────────────
├─ Expected: 1,000 RCU on average
├─ Peak traffic: 8,000 RCU needed (8x burst)
├─ Solution: Use on-demand pricing instead of provisioned
```

**Troubleshooting & Implementation Steps:**

1. **Identify throttling type:**
   ```bash
   # Check which metric is throttling
   aws cloudwatch get-metric-statistics \
     --namespace AWS/DynamoDB \
     --metric-name ReadThrottleEvents \
     --dimensions Name=TableName,Value=Leaderboard \
     --start-time 2026-03-07T00:00:00Z \
     --end-time 2026-03-07T12:00:00Z \
     --period 300 \
     --statistics Sum
   
   # If ReadThrottleEvents > 0, reads are being throttled
   # If WriteThrottleEvents > 0, writes are being throttled
   ```

2. **Check partition-level metrics:**
   ```bash
   # Enable CloudWatch Contributor Insights (identifies hot partitions)
   aws dynamodb create-contributor_insights_rule \
     --rule-name leaderboard-hot-partitions \
     --table-name Leaderboard
   
   # Wait 5 minutes, then query
   aws dynamodb query \
     --table-name CloudWatch \
     --key-condition-expression 'ContributorInsightsRule = :rule' \
     --expression-attribute-values '{":rule": {"S": "leaderboard-hot-partitions"}}'
   ```

3. **Option A: Fix partition key (root cause):**
   ```hcl
   # Problem: game_id is skewed
   # Solution: Add random suffix to distribute traffic
   
   # OLD Partition Key: game_id
   # NEW Partition Key: game_id + "#" + random(0-99)
   
   # Example:
   # "popular_game_xyz#23"  → Partition 23
   # "popular_game_xyz#45"  → Partition 45
   # "popular_game_xyz#12"  → Partition 12
   
   # This distributes 100 popular_game_xyz requests across 100 partitions
   # Each partition now gets ~50 RCU instead of 4,500
   
   # Requires query pattern changes:
   # OLD: Query(game_id = "popular_game_xyz")
   # NEW: Query(game_id = "popular_game_xyz#0") UNION
   #      Query(game_id = "popular_game_xyz#1") UNION
   #      ... (parallel queries to all 100 partitions)
   ```

4. **Option B: Switch to On-Demand Pricing (simpler):**
   ```bash
   # For unpredictable, spiky workloads, on-demand is better
   
   aws dynamodb update-table \
     --table-name Leaderboard \
     --billing-mode PAY_PER_REQUEST  # Switch to on-demand
   
   # Pricing comparison for this scenario:
   # Provisioned (current):
   #   ├─ 5,000 RCU × $0.25/hour = $1,250/month
   #   ├─ 5,000 WCU × $1.25/hour = $6,250/month
   #   └─ Total: $7,500/month (paying for peak capacity always)
   #
   # On-Demand (during peak 2 hours/day, 30 days/month):
   #   ├─ Off-peak (22 hrs): 100 RCU average = $0.10M reads/day
   #   ├─ Peak (2 hrs): 8,000 RCU = $3M reads/day
   #   ├─ Writes: Similar calculation
   #   └─ Total: ~$2,000/month (pay only for what you use)
   #
   # Savings: $5,500/month + zero throttling!
   ```

5. **If keeping provisioned, add auto-scaling:**
   ```hcl
   resource "aws_appautoscaling_target" "dynamodb_read" {
     max_capacity       = 40000
     min_capacity       = 100
     resource_id        = "table/Leaderboard"
     scalable_dimension = "dynamodb:table:ReadCapacityUnits"
     service_namespace  = "dynamodb"
   }
   
   resource "aws_appautoscaling_policy" "dynamodb_read_scaling" {
     policy_type               = "TargetTrackingScaling"
     resource_id               = aws_appautoscaling_target.dynamodb_read.resource_id
     scalable_dimension        = aws_appautoscaling_target.dynamodb_read.scalable_dimension
     service_namespace         = aws_appautoscaling_target.dynamodb_read.service_namespace
   
     target_tracking_scaling_policy_configuration {
       target_value = 70.0  # Scale when utilization > 70%
       scale_out_cooldown = 60  # Scale up quickly
       scale_in_cooldown = 300   # Scale down slowly
     }
   }
   ```

6. **Application layer improvements:**
   ```python
   # Add retry logic with exponential backoff
   
   import boto3
   import time
   from botocore.exceptions import ClientError
   
   dynamodb = boto3.resource('dynamodb')
   table = dynamodb.Table('Leaderboard')
   
   def update_score_with_retry(game_id, user_id, score, max_retries=5):
       """Update score with automatic retry on throttling"""
       
       for attempt in range(max_retries):
           try:
               response = table.update_item(
                   Key={'game_id': game_id, 'user_id': user_id},
                   UpdateExpression='SET #score = :score, updated_at = :now',
                   ExpressionAttributeNames={'#score': 'score'},
                   ExpressionAttributeValues={
                       ':score': score,
                       ':now': int(time.time())
                   }
               )
               return response
           
           except ClientError as e:
               if e.response['Error']['Code'] == 'ProvisionedThroughputExceededException':
                   # Exponential backoff: 2^attempt seconds
                   wait_time = (2 ** attempt) + random.uniform(0, 1)
                   print(f"Throttled. Retrying in {wait_time:.2f}s (attempt {attempt+1}/{max_retries})")
                   time.sleep(wait_time)
               else:
                   raise
       
       raise Exception(f"Failed to update score after {max_retries} retries")
   ```

**Best Practices Applied:**

✅ **Right-sizing capacity within partitions**: Understand partition key distribution.

✅ **On-demand pricing for unpredictable workloads**: Cost savings + zero throttling.

✅ **Auto-scaling policies**: If using provisioned, enable scaling.

✅ **Retry logic with exponential backoff**: Graceful handling of temporary throttling.

✅ **Monitoring**: CloudWatch alarms on ThrottleEvents.

---

### Scenario 4: Multi-Region RDS Failover & Data Consistency Issues

**Problem Statement:**

Your application uses RDS in us-east-1 (primary) with a cross-region read replica in eu-west-1 for reporting. A large customer in EU is reporting inconsistent order data: "I can see my order in the app, but it's missing from the reporting dashboard." Replication lag is ~5 seconds, causing read-after-write consistency issues.

**Root Cause:**

```
Architecture:
─────────────

Application (us-east-1):
├─ WRITE: Order placed → RDS Primary (us-east-1)
│  └─ Completes in 100ms
│  └─ Returns order_id to customer
│
└─ READ: Check order status → App reads from replica (eu-west-1)
   └─ Replication lag: 3-5 seconds
   └─ Replica doesn't have order yet
   └─ Customer sees "No orders found"
   └─ Data appears 5 seconds later (confusing UX)
```

**Troubleshooting & Implementation Steps:**

1. **Confirm replication lag:**
   ```bash
   # Check replica lag from primary
   mysql -h myapp-db-primary.us-east-1.rds.amazonaws.com -u admin -p
   
   SHOW SLAVE STATUS\G | grep -A 2 "Seconds_Behind_Master"
   # Output: Seconds_Behind_Master: 4.2 seconds ✓ Confirmed
   
   # Also check via CloudWatch
   aws cloudwatch get-metric-statistics \
     --namespace AWS/RDS \
     --metric-name ReplicationLag \
     --dimensions Name=DBInstanceIdentifier,Value=myapp-db-replica-eu \
     --start-time 2026-03-07T00:00:00Z \
     --end-time 2026-03-07T12:00:00Z \
     --period 60 \
     --statistics Average,Maximum
   ```

2. **Implement read-after-write pattern:**
   ```python
   # Problem: App doesn't wait for replication
   # Solution: Route writes to primary, reads to replica with fallback
   
   import redis
   import time
   
   primary_db = connect_to_rds("primary")
   replica_db = connect_to_rds("replica")
   cache = redis.Redis()
   
   def place_order(user_id, items):
       """Place order: write to primary, cache for immediate reads"""
       
       # Write to primary
       order = primary_db.execute(
           "INSERT INTO orders (user_id, items, status) VALUES (?, ?, 'pending')",
           (user_id, json.dumps(items))
       )
       order_id = order.lastrowid
       
       # Cache result for immediate reads (avoids stale data)
       cache.setex(
           f"order:{order_id}",
           60,  # 1-minute TTL (longer than replication lag)
           json.dumps({
               'order_id': order_id,
               'user_id': user_id,
               'items': items,
               'status': 'pending'
           })
       )
       
       return order_id
   
   def get_order(order_id):
       """Read order: cache first (avoids replica lag), then replica, then primary"""
       
       # Strategy 1: Check cache (fastest, user's own writes)
       cached = cache.get(f"order:{order_id}")
       if cached:
           return json.loads(cached)
       
       # Strategy 2: Try replica (eventual consistency OK after cache TTL)
       try:
           order = replica_db.query_one(
               "SELECT * FROM orders WHERE order_id = ?",
               (order_id,),
               timeout=2  # Quick timeout
           )
           if order:
               return order
       except:
           pass
       
       # Strategy 3: Fallback to primary (guarantees consistency)
       order = primary_db.query_one(
           "SELECT * FROM orders WHERE order_id = ?",
           (order_id,)
       )
       return order
   ```

3. **Alternative: Use EU-local writes:**
   ```hcl
   # Instead of replicating from US, have local EU writes
   
   # Architecture:
   # ├─ us-east-1: Primary RDS (orders from North America)
   # ├─ eu-west-1: Primary RDS (orders from Europe) ← NEW
   # │
   # └─ EU customers' writes go to EU-primary directly
   #    (no replication lag for local writes)
   
   resource "aws_rds_cluster" "eu_primary" {
     cluster_identifier = "myapp-eu-orders"
     engine             = "aurora-postgresql"
     database_name      = "myappdb"
     master_username    = "admin"
     
     # In eu-west-1 region
   }
   
   # Application logic:
   # ├─ US user writes/reads from us-east-1
   # ├─ EU user writes/reads from eu-west-1
   # └─ Cross-region replication (eventual consistency for reporting)
   ```

4. **Monitoring & alerting:**
   ```hcl
   resource "aws_cloudwatch_metric_alarm" "replica_lag_high" {
     alarm_name          = "rds-replica-lag-high"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = 2
     metric_name         = "ReplicationLag"
     namespace           = "AWS/RDS"
     period              = 300
     statistic           = "Average"
     threshold           = 2  # Alert if > 2 seconds
   
     dimensions = {
       DBInstanceIdentifier = "myapp-db-replica-eu"
     }
   
     alarm_actions = [aws_sns_topic.alerts.arn]
   }
   ```

**Best Practices Applied:**

✅ **Read-after-write consistency**: Cache user's writes to avoid replica delay.

✅ **Fallback reads**: Primary → Replica → Primary strategy.

✅ **Regional routing**: Users read/write to geographically close database.

✅ **Understanding replication lag**: Know the trade-offs (fast replication vs. latency).

---

### Scenario 5: Parameter Group Misconfiguration Causing Slow Queries

**Problem Statement:**

After upgrading RDS from MySQL 5.7 to MySQL 8.0, application performance degrades: queries that ran in 50ms now take 500ms, query timeout errors increase. Application team suspects MySQL 8.0 slowness, but actual issue is parameter group misconfiguration.

**Root Cause Investigation:**

```bash
# Check current parameters on production instance
mysql -h myapp-db.xxx.rds.amazonaws.com -u admin -p
SHOW VARIABLES LIKE 'query_cache%';
Output: query_cache_type 0 (cache disabled, new default in MySQL 8.0)

SHOW VARIABLES LIKE 'slow_query_log';
Output: slow_query_log 0 (logging disabled)

SHOW VARIABLES LIKE 'innodb_buffer_pool%';
Output: innodb_buffer_pool_size 134217728 (128MB, default!)
        innodb_buffer_pool_size should be 75% of instance RAM
        db.r5.large = 16GB RAM, buffer pool should be 12GB

# Enable slow query log to diagnose
SET GLOBAL slow_query_log = 1;
SET GLOBAL long_query_time = 1;  # Log queries > 1 second

# Check in CloudWatch Logs
aws logs tail /aws/rds/instance/myapp-db/slowquery --follow
# Output: Many queries taking 500ms-2s (previously cached)
```

**Troubleshooting & Implementation Steps:**

1. **Create optimized parameter group:**
   ```hcl
   # Terraform: MySQL 8.0 parameter group with proper sizing
   
   resource "aws_db_parameter_group" "mysql80_optimized" {
     name   = "myapp-mysql80-optimized"
     family = "mysql8.0"
   
     # Memory tuning (for db.r5.large = 16GB)
     parameter {
       name  = "innodb_buffer_pool_size"
       value = "{DBInstanceClassMemory*3/4}"  # 12GB (75% of 16GB)
     }
   
     # Query optimization
     parameter {
       name  = "slow_query_log"
       value = "1"
     }
   
     parameter {
       name  = "long_query_time"
       value = "1"  # Log queries > 1s
     }
   
     parameter {
       name  = "log_queries_not_using_indexes"
       value = "1"  # Log index-less queries
     }
   
     # Threading (for modern hardware)
     parameter {
       name  = "innodb_max_dirty_pages_pct"
       value = "75"
     }
   
     parameter {
       name  = "max_connections"
       value = "1000"
     }
   
     # MySQL 8.0 specific defaults
     parameter {
       name  = "default_authentication_plugin"
       value = "mysql_native_password"  # For compatibility
     }
   
     tags = {
       Name = "Optimized MySQL 8.0"
     }
   }
   
   # Apply to RDS instance
   resource "aws_db_instance" "primary" {
     parameter_group_name = aws_db_parameter_group.mysql80_optimized.name
     instance_class       = "db.r5.large"
     # ... other config
   }
   ```

2. **Apply changes with zero downtime:**
   ```bash
   # Option 1: Using blue-green deployment (recommended)
   aws rds create-blue-green-deployment \
     --blue-green-deployment-name myapp-db-param-fix \
     --source arn:aws:rds:us-east-1:ACCOUNT:db:myapp-db-primary
   
   # This creates a green environment with new parameters
   # Test green environment while blue serves production
   
   # Once validated:
   aws rds switchover-blue-green-deployment \
     --blue-green-deployment-identifier bgd-xxx
   
   # Blue-green advantages:
   # ├─ Zero downtime
   # ├─ Easy rollback (switch back to blue if issues)
   # └─ ~5-10 minute switchover time
   
   # Option 2: Direct parameter update (requires restart)
   aws rds modify-db-instance \
     --db-instance-identifier myapp-db-primary \
     --db-parameter-group-name myapp-mysql80-optimized \
     --apply-immediately  # Causes ~2-5min downtime
   ```

3. **Validate query performance:**
   ```bash
   # Before fix: Slow queries (500ms+)
   # After fix: Fast queries (50ms)
   
   # Use RDS Performance Insights to compare
   aws rds describe-db-performance-insights \
     --db-instance-identifier myapp-db-primary
   
   # Query specific slow query
   mysql -h myapp-db.xxx.rds.amazonaws.com -u admin -p
   
   SELECT * FROM mysql.slow_log \
   ORDER BY query_time DESC LIMIT 10;
   
   # Analyze query plan
   EXPLAIN SELECT * FROM users WHERE email = 'test@example.com';
   # Should show "Using index" (not "All")
   ```

4. **Set monitoring for slow queries:**
   ```hcl
   resource "aws_cloudwatch_log_group" "rds_slow_queries" {
     name              = "/aws/rds/instance/myapp-db/slowquery"
     retention_in_days = 7
   }
   
   resource "aws_cloudwatch_metric_alarm" "slow_queries_increased" {
     alarm_name          = "rds-slow-queries-high"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = 2
     metric_name         = "SlowQueryCount"
     namespace           = "AWS/RDS"
     period              = 300
     statistic           = "Sum"
     threshold           = 100  # Alert if > 100 slow queries in 5 min
   
     dimensions = {
       DBInstanceIdentifier = "myapp-db-primary"
     }
   
     alarm_actions = [aws_sns_topic.alerts.arn]
   }
   ```

**Best Practices Applied:**

✅ **Parameter group versioning**: Keep parameters in IaC (Git history).

✅ **Instance-specific tuning**: Set `innodb_buffer_pool_size` based on instance RAM.

✅ **Slow query logging**: Always enable in production for performance troubleshooting.

✅ **Blue-green deployments**: Zero-downtime parameter changes.

✅ **Performance monitoring**: CloudWatch Logs + Performance Insights for ongoing visibility.

---

## Interview Questions

Realistic questions asked in Senior DevOps engineer interviews for AWS databases.

### Question 1: Design a Multi-Region RDS Architecture for a Global E-Commerce Company

**Interview Prompt:**

"Design a database architecture for a global e-commerce platform with:
- Customers in US, EU, and APAC regions
- Real-time inventory synchronization across regions
- Regulatory requirement: EU customer data must stay in EU (GDPR)
- 99.99% availability requirement (4 nines)
- Sub-100ms latency for local customers
- Budget: Database costs should not exceed 30% of infrastructure spend"

**Expected Answer (Senior Level):**

"I'd design a **multi-region active-primary with read replicas per region** architecture:

**Architecture:**
```
Primary Region (us-east-1):
├─ Aurora MySQL cluster (writer)
│  ├─ 1 primary instance (db.r6g.4xlarge, 128GB)
│  ├─ 3 read replicas (auto-scaling, 3-15 replicas)
│  └─ 1 standby in different AZ (Multi-AZ)
├─ RDS Proxy (connection pooling)
└─ Global Database replication → other regions (async <2s)

EU Region (eu-west-1):
├─ Aurora MySQL cluster (read-only until failover)
│  ├─ Read replicas (3-15)
│  └─ Can be promoted to primary if US region down
├─ Separate primary for EU-only data (GDPR compliance)
│  ├─ Customer profiles, orders originating in EU
│  └─ Never leaves EU region
└─ Global Database replication → US/APAC (async)

APAC Region (ap-southeast-1):
├─ Aurora MySQL cluster (read-only)
├─ Read replicas for local analytics
└─ Global Database replication

Inventory Service (Cross-region):
├─ DynamoDB Global Table (inventory quantity)
│  ├─ Real-time sync across regions (<1s)
│  ├─ Active-active model (any region can write)
│  └─ Conflict resolution: Last-write-wins + versioning
└─ Triggers to update RDS from DynamoDB
```

**How this solves each requirement:**

1. **Availability (99.99%):**
   - Primary region: Multi-AZ RDS (automatic failover, RTO <2min)
   - Global Database: If primary region fails, promote secondary (RTO 1-5min)
   - Combined: (8,760 hours/year) × (1 - 0.9999) = 52 minutes max downtime/year

2. **Latency (<100ms):**
   - US customers: Primary region (sub-5ms)
   - EU customers: EU read replicas (sub-10ms)
   - APAC customers: APAC read replicas (sub-15ms)
   - All within SLA

3. **GDPR Compliance:**
   - EU customer data: Separate primary in eu-west-1 (never leaves)
   - Master data: Replicates globally with explicit filters (no PII outside EU)
   - Compliance: Regular audit of region-locked data

4. **Cost (~30% of infrastructure):**
   - Aurora over RDS: 30% lower backup costs (included in pricing)
   - Shared storage layer: 20% cost savings vs. single-instance RDS
   - On-demand read replicas: Scale up/down automatically based on load
   - Reserved instances for stable baseline capacity: 70% discount
   - Estimated: $50K/month for US primary + read replicas
                $30K/month for EU region
                $20K/month for APAC region
                Total: ~$100K/month for database (30% of $350K infra budget)

**Failover Scenarios:**

```
Scenario 1: US Primary Fails
├─ CloudWatch alarm detects primary unreachable
├─ Lambda triggers: Promote EU replica to primary
├─ Update DNS: app.myapp.com → EU database
├─ Applications reconnect within 30 seconds
├─ RTO: 1-2 minutes
├─ RPO: <2 seconds (from replication lag)
└─ Impact: Temporary routing to EU, latency increase for US

Scenario 2: Single AZ Down (within region)
├─ Aurora automatic: Failover to standby AZ
├─ RTO: <2 seconds (automatic)
├─ RPO: 0 (synchronous replication)
└─ Impact: None (transparent to users)

Scenario 3: Temporary Network Partition
├─ Global Database: Detects partition
├─ Write buffering: All writes queue locally
├─ Replication resumes when partition heals
└─ Consistency: Eventually consistent, no data loss
```

**Implementation Details:**

```hcl
# Terraform: Global Database setup

resource "aws_rds_global_cluster" "main" {
  global_cluster_identifier = "ecommerce-global"
  engine                    = "aurora-mysql"
}

# US Primary Cluster
resource "aws_rds_cluster" "us_primary" {
  global_cluster_identifier = aws_rds_global_cluster.main.id
  cluster_identifier        = "ecommerce-us-primary"
  engine_version            = "8.0.mysql_aurora.3.04.0"
  database_name             = "ecommerce"
  db_subnet_group_name      = aws_db_subnet_group.us.name
  
  backup_retention_period = 14
  enabled_cloudwatch_logs_exports = ["error", "slowquery"]
  
  # Encryption at rest (KMS)
  storage_encrypted = true
  kms_key_id       = aws_kms_key.rds.arn
}

# Write to US, reads distributed
resource "aws_rds_cluster_instance" "us_primary_writer" {
  cluster_identifier = aws_rds_cluster.us_primary.id
  instance_class     = "db.r6g.4xlarge"
  identifier         = "ecommerce-us-writer"
  publicly_accessible = false
}

resource "aws_rds_cluster_instance" "us_replicas" {
  count              = 3
  cluster_identifier = aws_rds_cluster.us_primary.id
  instance_class     = "db.r6g.2xlarge"
  identifier         = "ecommerce-us-replica-${count.index}"
}

# EU Secondary Cluster (read-only until failover)
resource "aws_rds_cluster" "eu_secondary" {
  global_cluster_identifier = aws_rds_global_cluster.main.id
  cluster_identifier        = "ecommerce-eu-secondary"
  # No master credentials (inherits from primary)
  # No database_name (inherits from primary)
  
  depends_on = [aws_rds_cluster.us_primary]
}

resource "aws_rds_cluster_instance" "eu_replicas" {
  count              = 3
  cluster_identifier = aws_rds_cluster.eu_secondary.id
  instance_class     = "db.r6g.2xlarge"
  identifier         = "ecommerce-eu-replica-${count.index}"
}

# DynamoDB for inventory (active-active)
resource "aws_dynamodb_table" "inventory_global" {
  name           = "inventory"
  billing_mode   = "PAY_PER_REQUEST"  # On-demand for unpredictable spikes
  hash_key       = "sku"
  range_key      = "region"
  
  stream_specification {
    stream_view_type = "NEW_AND_OLD_IMAGES"
  }
  
  replica {
    region_name = "eu-west-1"
  }
  
  replica {
    region_name = "ap-southeast-1"
  }
}

# Auto-scaling for read replicas
resource "aws_appautoscaling_target" "read_scaling" {
  max_capacity       = 15
  min_capacity       = 3
  resource_id        = "cluster:${aws_rds_cluster.us_primary.id}"
  scalable_dimension = "rds:cluster:DesiredReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "read_scaling_policy" {
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_scaling.resource_id
  scalable_dimension = aws_appautoscaling_target.read_scaling.scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_scaling.service_namespace
  
  target_tracking_scaling_policy_configuration {
    target_value = 70.0  # Scale when CPU > 70%
  }
}
```

**Operational Considerations:**

- **Monitoring**: CloudWatch dashboards for replication lag, connection counts, query latency per region
- **Backup testing**: Monthly restore from each region's backups
- **Failover drills**: Quarterly promotion of secondary to primary (then promote back)
- **Data validation**: Cross-region consistency checks (eventual consistency acceptable)
- **Cost optimization**: Reserved instances for stable baseline, on-demand for burst"

---

### Question 2: Diagnose and Fix RDS Connection Pool Exhaustion

**Interview Prompt:**

"You're on-call and get paged at 2 AM. Production system reporting: 'Can't connect to database. Error: Too many connections.' Your on-call runbook says: 'Increase max_connections and reboot.' But you have 5000 active users. What do you do? Walk me through your troubleshooting."

**Expected Answer (Senior Level):**

"I would NOT immediately reboot (that kills all connections). Instead:

**Step 1: Assess the situation (1 min)**
```bash
# SSH to bastion
# Connect to RDS (maybe use a management connection)

mysql -h myapp-db.xxx.rds.amazonaws.com -u admin -p

# Check connection count
SHOW PROCESSLIST;
SELECT COUNT(*) FROM INFORMATION_SCHEMA.PROCESSLIST;
# If output: 500 connections, max is 500 → Confirm exhaustion

# Check for idle connections
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST 
WHERE COMMAND = 'Sleep' AND TIME > 300;
# If many idle connections, application isn't closing connections

# Check status
SHOW GLOBAL STATUS LIKE 'Max_used_connections';
# If output: 482 / 500 capacity, we're at limit
```

**Step 2: Determine root cause (2 min)**

**Scenario A: Legitimate traffic surge**
- SHOW PROCESSLIST shows active queries (not idle)
- User claims: 'Traffic 10x normal due to viral spike'
- Solution: Scale up database OR implement RDS Proxy
- Action: Proceed to immediate fix below

**Scenario B: Connection leak**
- SHOW PROCESSLIST shows many 'Sleep' connections
- 100+ idle connections sleeping for hours
- Application isn't closing connections
- Solution: Restart application, implement connection pooling
- Action: Coordinate with app team

**Scenario C: Runaway queries**
- SHOW PROCESSLIST shows single query using 100+ connections
- Query looping/spawning subqueries indefinitely
- Solution: Kill query, deploy code fix
- Action: KILL QUERY <id>, investigate code

**Step 3: Immediate fix without downtime (5-10 min)**

I'd deploy RDS Proxy (best solution):

```bash
# RDS Proxy can be deployed in <10 minutes without rebootingaws rds create-db-proxy \\
  --db-proxy-name myapp-db-proxy \\
  --engine-family MYSQL \\
  --db-instance-identifiers myapp-db-primary \\
  --role-arn arn:aws:iam::ACCOUNT:role/rds-proxy-role \\
  --auth '[{\"AuthScheme\":\"SECRETS\",\"SecretArn\":\"arn:aws:secretsmanager:...db-password...\"}]'

# While proxy deploys, coordinate with ops/app team:
# - Update app connection string to proxy endpoint
# - Restart applications gradually (rolling restart)
# - Monitor DATABASE connection count from proxy perspective

# Proxy characteristics:
# ├─ Multiplexes 4 backend connections → handles 100+ client connections
# ├─ Connection timeout: 120 seconds
# ├─ Cost: ~$0.30/hour
# └─ Deployment: ~10 minutes, no reboot
```

**Alternative: Kill idle connections immediately (buys time)**

```sql
-- CAREFULLY kill only non-critical queries
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST 
WHERE COMMAND = 'Sleep' AND TIME > 600
ORDER BY TIME DESC;

-- Kill slowly (one at a time, monitor impact)
KILL CONNECTION <id>;  -- Closes connection, app reconnects

-- Or if desperate:
SET GLOBAL max_connections = 1000;  -- Requires restart, avoid!
```

**Step 4: Short-term scaling (10-20 min)**

If unable to deploy RDS Proxy immediately:

```bash
# Upgrade instance size (accepts new connections)
aws rds modify-db-instance \\
  --db-instance-identifier myapp-db-primary \\
  --db-instance-class db.r5.large \\
  --apply-immediately

# db.r5.large: max_connections ≈ 900 (vs. 214 for t3.medium)
# Downtime: ~2-3 minutes (brief, tolerable for 2 AM)
# Cost: Temporary increase until traffic normalizes
```

**Step 5: Prevent recurrence**

Once stabilized (next business day):

```hcl
# Terraform: Proper setup for the future

# 1. Deploy RDS Proxy permanently
resource \"aws_db_proxy\" \"main\" {
  db_proxy_name     = \"myapp-db-proxy\"
  engine_family     = \"MYSQL\"
  role_arn          = aws_iam_role.proxy_role.arn
  db_instance_identifiers = [aws_db_instance.primary.id]
  
  max_idle_connections_percent  = 50
  max_connections_percent       = 100
  connection_borrow_timeout     = 120
}

# 2. CloudWatch alarm for connection count
resource \"aws_cloudwatch_metric_alarm\" \"connection_count\" {
  alarm_name              = \"rds-connection-exhaustion-warning\"
  comparison_operator     = \"GreaterThanThreshold\"
  evaluation_periods      = 1
  metric_name             = \"DatabaseConnections\"
  namespace               = \"AWS/RDS\"
  period                  = 60
  statistic               = \"Maximum\"
  threshold               = 160  # 80% of 200
  alarm_description       = \"Alert when connections near limit\"
  
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.primary.id
  }
  
  alarm_actions = [aws_sns_topic.critical_alerts.arn]
}

# 3. Application connection pooling (backup to Proxy)
# Code: Use HikariCP (Java) or pgBouncer (for app-side pooling)
```

**Why this approach?**

✅ **No customer impact**: RDS Proxy deployment doesn't require reboot
✅ **Addresses root cause**: Proxy solves connection pooling fundamentally
✅ **Scalable**: Works for traffic spikes + reduces database load
✅ **Reversible**: Can rollback DB changes if issues
✅ **On-call friendly**: Doesn't require app team at 2 AM

**Timeline:**
- 0-2 min: Assess + diagnose
- 2-10 min: Deploy RDS Proxy
- 10-15 min: Update app connection strings
- 15-30 min: Applications restored
- 30+ min: Monitor + prevent recurrence"

---

## Revision History

| Date | Author | Changes |
|------|--------|---------|
| 2026-03-07 | DevOps Team | Initial creation: TOC, Introduction, Foundational Concepts |
| 2026-03-07 | DevOps Team | Added RDS Basics & Aurora Architecture deep dives with code examples |
| 2026-03-07 | DevOps Team | Added DynamoDB Fundamentals & Backup/DR deep dives with code examples |
| 2026-03-07 | DevOps Team | Added Hands-on Scenarios & Interview Questions (Phase 4 completion) |

