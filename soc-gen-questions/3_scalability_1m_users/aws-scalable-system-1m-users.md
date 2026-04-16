# Designing a Scalable System in AWS for 1 Million Users

**Audience:** DevOps Engineers with 5–10+ years of experience  
**Difficulty Level:** Senior/Architect  
**Duration:** Comprehensive deep-dive guide  

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Defining Load and Performance Requirements](#1-defining-load-and-performance-requirements)
4. [High Level Scaling Architecture](#2-high-level-scaling-architecture)
5. [Edge Layer Design](#3-edge-layer-design)
6. [Entry Layer - Routing & Throttling](#4-entry-layer---routing--throttling)
7. [Compute Layer](#5-compute-layer)
8. [Caching Layer](#6-caching-layer)
9. [Database Layer](#7-database-layer)
10. [Asynchronous Processing Layer](#8-asynchronous-processing-layer)
11. [Storage Layer](#9-storage-layer)
12. [Monitoring and Observability](#10-monitoring-and-observability)
13. [Cost Optimization Strategies](#11-cost-optimization-strategies)
14. [TL;DR Architecture Flow](#12-tldr-architecture-flow)
15. [Example Scaled Flow](#13-example-scaled-flow)
16. [Hands-on Scenarios](#hands-on-scenarios)
17. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Designing a scalable system for 1 million concurrent users represents one of the most demanding challenges in modern cloud architecture. At this scale, no single component can be a bottleneck—from the network edge to the database layer, every service must be architected for horizontal scalability, resilience, and cost efficiency.

This study guide addresses the comprehensive design decisions required to:
- Handle unprecedented traffic volumes without degradation
- Maintain sub-second latency across global regions
- Achieve fault tolerance and disaster recovery at scale
- Optimize costs while maintaining performance guarantees
- Ensure observability and rapid incident response

Unlike smaller systems where vertical scaling or monolithic architectures might suffice, a system for 1 million users demands **distributed systems thinking**, **database sharding strategies**, **intelligent caching**, and **sophisticated traffic management**.

### Why it Matters in Modern DevOps Platforms

Scaling to 1 million users is no longer theoretical—it's a business reality for companies ranging from emerging SaaS platforms to established enterprises. The DevOps discipline sits at the intersection of this challenge:

- **Automation & Infrastructure as Code**: At this scale, manual provisioning becomes impossible. IaC frameworks (Terraform, CloudFormation) are non-negotiable.
- **Observability & Alerting**: With hundreds of services and thousands of instances, traditional monitoring breaks down. You need distributed tracing, structured logging, and intelligent alerting.
- **CI/CD & Deployment Safety**: Deploying to thousands of instances requires canary deployments, feature flags, and automated rollback mechanisms.
- **Cost Control**: A poorly optimized system at this scale can cost millions annually. DevOps engineers must continuously balance performance and cost.
- **Incident Response**: Outages affect millions of users. DevOps engineers need runbooks, blameless postmortems, and rapid incident response procedures.

### Real-World Production Use Cases

#### E-Commerce Platform (Amazon, eBay)
- Peak concurrent users during sales events: 1M+
- Requirement: Sub-100ms latency on product searches
- Challenge: Catalog of billions of items; need sophisticated caching and indexing
- Solution: CDN for static content, ElastiCache for product metadata, DynamoDB for catalog reads

#### Video Streaming Service (Netflix, YouTube)
- Concurrent viewers: 1M+
- Requirement: Smooth playback without buffering; adaptive bitrate streaming
- Challenge: Massive video file distribution; variable bandwidth consumption
- Solution: CloudFront for video delivery, S3 + EFS for storage, Lambda for transcoding

#### Social Media Platform (Twitter, LinkedIn)
- Active concurrent users: 1M+
- Requirement: Real-time feeds; sub-second notification delivery
- Challenge: Graph-like data access patterns; complex denormalization
- Solution: Multiple databases (RDS for transactions, DynamoDB for feeds), Redis for sessions, SNS/EventBridge for events

#### Financial Services (Payment Processing)
- Concurrent transactions: 100K-1M per second
- Requirement: Strong consistency; audit trails; regulatory compliance
- Challenge: Fraud detection at high throughput; zero data loss
- Solution: Partitioned RDS (read replicas), SQS for message queuing, DynamoDB for audit logs

### Where it Typically Appears in Cloud Architecture

Scaling to 1 million users affects **every layer** of your system:

| Layer | Components | Scale Challenges |
|-------|-----------|-----------------|
| **Edge** | CloudFront, WAF, Lambda@Edge, Route 53 | Global distribution; DDoS capacity |
| **Entry** | API Gateway, ALB, NLB | Request routing; rate limiting; SSL termination |
| **Compute** | EC2, Lambda, Fargate, EKS | Auto-scaling; instance orchestration; cold starts |
| **Session/Cache** | ElastiCache (Redis/Memcached), DAX | Eviction policies; cache miss storms |
| **Data** | RDS, Aurora, DynamoDB, Redshift | Sharding; replication; hot keys |
| **Queue/Stream** | SQS, SNS, Kinesis, EventBridge | Message throughput; ordering guarantees |
| **Storage** | S3, EFS, FSx | Durability; concurrent access patterns |
| **Observability** | CloudWatch, X-Ray, Prometheus, ELK | Log volume; metric cardinality |

---

## Foundational Concepts

### Key Terminology

#### Concurrency vs. Throughput
- **Concurrency (1M users)**: Number of simultaneous active users or connections
- **Throughput (RPS)**: Requests per second generated by those concurrent users
- **Formula**: Throughput (RPS) = Concurrency × (Requests per User per Second)
  - 1M concurrent users × 10 RPS average = 10M RPS system capacity needed

#### Request Latency Tiers
| Metric | Target | Impact |
|--------|--------|--------|
| P50 Latency | <100ms | Most users happy |
| P95 Latency | <500ms | 95% of users experience acceptable performance |
| P99 Latency | <2s | 1% of users see degradation (often power users doing heavy work) |
| Tail Latency | <5s | Threshold for automatic timeout/retry |

#### Load Distribution Terms
- **Hotspot/Hot Key**: A data item accessed disproportionately more than others (e.g., celebrity user profile)
- **Thundering Herd**: Multiple clients requesting the same expired cache entry simultaneously
- **Cache Stampede**: Sudden spike in cache misses causing database overload
- **Connection Pooling Exhaustion**: Running out of available database connections

#### Scaling Patterns
- **Horizontal Scaling**: Adding more instances (stateless services)
- **Vertical Scaling**: Upgrading instance size (has hard limits; less flexible)
- **Sharding**: Distributing data across multiple databases by a shard key (user ID, tenant ID)
- **Replication**: Copying data across instances for high availability and read scaling
- **Partitioning**: Logical division of data for parallel processing

### Architecture Fundamentals

#### The CAP Theorem at Scale
At 1 million users, you cannot have all three CAP properties simultaneously:

| Property | Definition | At 1M Users |
|----------|-----------|------------|
| **Consistency** | All nodes see the same data | RDS, Aurora offer strong consistency but limited throughput |
| **Availability** | System always responds | DynamoDB can't guarantee consistency during partitions |
| **Partition Tolerance** | System continues despite network failures | Mandatory in distributed systems; choose C vs A |

**Practical Decision**: Most 1M+ user systems choose **AP** (Available + Partition-tolerant) with **eventual consistency**, using:
- DynamoDB/Cassandra for high-throughput, eventually-consistent data
- RDS Aurora read replicas with replication lag accepted
- Event-driven architectures to propagate state changes

#### Distributed Systems Hazards

1. **Network Unreliability**
   - Assume 1 in 1000 network packets will be lost or delayed
   - Implement retries with exponential backoff
   - Use circuit breakers to fail fast

2. **Clock Skew**
   - Servers' clocks drift by milliseconds
   - Never rely on absolute ordering; use logical clocks (Lamport timestamps) or sequence numbers
   - Impact: Distributed transactions, event ordering, TTL calculations

3. **Cascading Failures**
   - One service degradation causes dependent services to fail
   - Implement bulkheads (circuit breakers), timeouts, rate limiting
   - Example: Slow database → requests pile up → connection pool exhausted → entire application hangs

4. **Byzantine Failures**
   - A component returns incorrect data rather than failing cleanly
   - Validation at every layer is critical
   - Checksums on data, digital signatures on transactions

### Important DevOps Principles at Scale

#### Principle 1: Statelessness
**Definition**: Individual instances hold no user session data; all state lives in external stores.

**Why it Matters at 1M Users**:
- Any instance can die without data loss
- Load balancer can route requests arbitrarily
- Auto-scaling becomes trivial (spin up/down instances without coordination)

**Implementation**:
```
❌ BAD: In-memory sessions on web servers
✅ GOOD: Sessions stored in Redis/ElastiCache, referenced by token
```

#### Principle 2: Observability Over Visibility
**Definition**: Instrument systems to ask arbitrary questions about behavior, not just look at predefined dashboards.

**Why it Matters at 1M Users**:
- You cannot test every pathway; some failures only occur in production
- Distributed tracing (X-Ray) shows request paths across 100+ services
- Structured logging enables rapid root cause analysis
- Metrics cardinality explodes (millions of time series)

**Implementation**:
- Log every request with trace ID, user ID, service name, duration
- Export metrics for latency P50/P95/P99, error rates, queue depths
- Implement distributed tracing across service boundaries

#### Principle 3: Fault Isolation
**Definition**: Gracefully degrade when one component fails; don't cascade.

**Why it Matters at 1M Users**:
- At this scale, something is always failing
- A single slow database query should not bring down the entire platform
- Require redundancy at every critical path

**Implementation**:
- Circuit breakers: If calls to Service B fail 50% of the time, stop calling it temporarily
- Bulkheads: Dedicate thread pools to different workloads; one slow workload doesn't block others
- Fallbacks: Return stale cache data if real-time data unavailable

#### Principle 4: Immutable Infrastructure
**Definition**: Instead of updating servers, replace them with new versions.

**Why it Matters at 1M Users**:
- 1000 instances means 1000x the configuration drift risk
- Rolling updates reduce deploy risk
- One bad configuration doesn't propagate to all instances instantly

**Implementation**:
- Docker images with fixed application version
- Infrastructure as Code (Terraform) versions infrastructure
- Blue-green deployments or canary deployments

#### Principle 5: Cost-Aware Architecture
**Definition**: Every architectural decision has cost implications; track and optimize them.

**Why it Matters at 1M Users**:
- A 10% efficiency gain across 1000 instances = massive monthly savings
- Over-provisioning for "safety" is unsustainable at scale
- Spot instances, reserved instances, savings plans require careful orchestration

**Implementation**:
- Right-size instances using cost/performance metrics
- Use Spot instances for non-critical workloads (29-90% discount)
- Implement auto-scaling to match demand, not peak capacity

### Best Practices

#### 1. Design for Failure, Not Against It
- Redundancy at every layer (multi-AZ deployment minimum)
- Graceful degradation: Users experience reduced functionality, not total outage
- Chaos engineering: Regularly kill instances, databases, networks to test resilience

#### 2. Implement Rate Limiting at Multiple Layers
- API Gateway: Throttle at 10M RPS per account
- ALB: Protect backend servers with per-target rate limits
- Application Layer: Implement sliding window counters per user/IP
- Goal: Prevent cascading failures from traffic spikes

#### 3. Design Databases for Read-Heavy Workloads
- Most systems are 95% reads, 5% writes (read-write ratio)
- Sharding on write-heavy dimension; replicas for reads
- DynamoDB's on-demand pricing scales automatically; RDS requires manual replica provisioning

#### 4. Cache Intelligently, Not Blindly
- Cache miss happens → database gets slow → cache fills with slow responses
- Use cache aside pattern with version stamps
- Implement cache invalidation strategy: TTL, event-driven, or write-through
- Monitor cache hit rates; aim for >95% for user-facing reads

#### 5. Monitor Cost Alongside Performance
- Extract instance metrics: CPU %, memory %, network throughput
- If instance <30% CPU, you're over-provisioned
- If instance >80% CPU, scale up before customers feel it
- Use Reserved Instances for baseline; Spot for burst

#### 6. Build for Multi-Region from Day 1 (If Required)
- Single region is acceptable for 1M users IF you accept regional failure
- Multi-region requires: data replication lag, consistency challenges, cross-region routing
- Only move to multi-region when single-region limits are hit

### Common Misunderstandings

#### Misunderstanding 1: "More Caching = Better Performance"
**Reality**: Uncontrolled caching creates:
- Thundering herd: 10K clients request expired cache entry simultaneously
- Stale data issues: Users see outdated information
- Memory exhaustion: Cache eviction policies can thrash

**Correct Approach**: Cache with TTLs; monitor hit rates and latency impact

#### Misunderstanding 2: "Horizontal Scaling is Free"
**Reality**: Scaling creates new problems:
- Data consistency: Which replica is source of truth?
- Network overhead: More instances = more inter-service communication
- Debugging complexity: Bug might only appear on specific shard
- 10 instances is harder than 1; 100 is exponentially harder

**Correct Approach**: Vertical scale first (within instance limits); scale horizontally only when necessary

#### Misunderstanding 3: "Load Balancing Solves Everything"
**Reality**: Load balancing is just traffic distribution; it doesn't prevent:
- Uneven load distribution (some servers get more traffic)
- Connection state problems (session stickiness)
- Slow client uploads (slow client problem persists)

**Correct Approach**: Load balance at multiple layers (DNS, ALB, service mesh); monitor per-instance metrics

#### Misunderstanding 4: "Optimize for P50 Latency"
**Reality**: Users care about their experience:
- P50: Average user's experience (good metric for resource planning)
- P99: Power users' experience (determines patience threshold)
- Max latency: Determines timeout thresholds; timeouts create cascading failures

**Correct Approach**: Meet P50 targets; optimize P99 and tail latency separately

#### Misunderstanding 5: "Auto-Scaling Fixes Over-Provisioning"
**Reality**: Auto-scaling has limitations:
- Scale-up lag: Takes 2-5 minutes to provision new instances
- Without predictive scaling, you're always playing catch-up
- Rapidly scaling up/down increases cost and waste

**Correct Approach**: Use auto-scaling with predictive metrics; reserve capacity for base load; scale for burst

#### Misunderstanding 6: "Microservices Automatically Scale"
**Reality**: Microservices architecture introduces:
- Network latency: Service-to-service calls > function calls
- Operational complexity: 100 services = 100 deployment pipelines
- Distributed transaction challenges: ACID transactions impossible

**Correct Approach**: Monolith first, then break into microservices when specific service becomes bottleneck

---

## 1. Defining Load and Performance Requirements

### Textual Deep Dive

#### Internal Working Mechanism

Defining load and performance requirements is the **foundational step** before designing any architecture. Without clear requirements, you'll either under-provision (causing outages) or over-provision (wasting money). This phase involves:

1. **Capacity Planning**: Translating business goals ("serve 1 million users") into infrastructure metrics
2. **Bottleneck Identification**: Determining which layers will hit limits first
3. **SLA Definition**: Establishing contractual performance guarantees

#### Breaking Down 1 Million Concurrent Users

**Concurrent Users ≠ Total Registered Users**

- Total users: 100-500M (full user base)
- Daily active users (DAU): 10-50M (users who log in daily)
- **Concurrent users**: 500K-2M (simultaneously online at peak hours)
- Off-peak concurrent: 100-200K

**Example: Video Streaming Platform**
```
Total Registered Users: 200M
DAU: 50M
Peak Concurrent: 1M (9 PM UTC)
Off-peak Concurrent: 200K (6 AM UTC)
```

#### Translating to Requests Per Second (RPS)

**Formula**:
```
RPS = Concurrent Users × Requests per User per Second
```

**Breakdown by User Type**
| User Type | Concurrent Users | Req/sec per User | Total RPS |
|-----------|-----------------|------------------|-----------|
| Active (gaming/streaming) | 100K | 100 | 10M |
| Moderate (browsing) | 600K | 5 | 3M |
| Idle (background) | 300K | 0.1 | 30K |
| **Total** | **1M** | **~13** | **~13M RPS** |

**Important**: RPS varies drastically by workload type:
- Video streaming: High bandwidth, lower RPS (100-1K RPS per user)
- Chat application: Many requests, lower data volume (5-20 RPS per user)
- Trading platform: Extreme RPS during market hours (100+ RPS per user)

#### Read vs. Write Ratio

Most systems exhibit **95% read / 5% write** patterns.

**Example Breakdown**
| Operation | Percentage | RPS (out of 13M) |
|-----------|-----------|-----------------|
| Read operations | 95% | 12.35M RPS |
| Write operations | 5% | 650K RPS |

**Why this matters**:
- **Reads scale horizontally** (add read replicas)
- **Writes create bottlenecks** (single writer in ACID databases)
- Sharding strategy changes based on write-heavy vs. read-heavy workloads

**Write-Heavy Example: Financial Trading**
```
Read operations: 60% (market data queries)
Write operations: 40% (trade executions, order updates)
Challenge: Must replicate writes to ensure consistency
Solution: DynamoDB global tables, sharded RDS with synchronous replication
```

#### Latency Requirements

**Defining Latencies**

| SLA Tier | P50 | P95 | P99 | Max | User Impact |
|----------|-----|-----|-----|-----|------------|
| **Premium Tier** | <50ms | <200ms | <500ms | <2s | High-frequency traders, real-time dashboards |
| **Standard Tier** | <100ms | <500ms | <1s | <5s | Browsing, normal transactions |
| **Best-Effort** | <500ms | <2s | <5s | <10s | Background jobs, async operations |

**Budgeting Latency Across Layers**
```
Total P99 Latency Budget: 1 second
├─ DNS Resolution: 10ms
├─ Network (Client to CloudFront): 20ms
├─ CloudFront Cache: 5ms (hit) or 100ms (miss)
├─ API Gateway: 20ms
├─ ALB: 5ms
├─ Application Processing: 400ms
├─ Database Query: 200ms
├─ Cache Check: 5ms
└─ Response Network: 20ms
```

**Important**: Every hop adds latency. A 13M RPS system with 100K requests in flight simultaneously creates queuing delays.

#### Data Throughput Requirements

**Calculating Data Volume**

Average payload sizes:
- API response (JSON): 5-50 KB
- Video frame: 100-500 KB
- Large file: 1-1000 MB

**Example: Streaming Service**
```
1M concurrent users × 1 Mbps per user = 1 Terabit per second ingress
This is 125 GB per second = 10.8 MB per second per availability zone

Reality: Distribute across 3 AZs = 3.6 MB/sec per AZ
Critical: Network interface supports 30 Gbps; ALB supports 25 Gbps
```

**Storage Needs**

| Component | Data Volume | Scale Factor |
|-----------|------------|--------------|
| User profiles | 100 bytes × 100M users | 10 GB |
| Session data | 1 KB × 1M concurrent | 1 GB |
| User feed/activity | 10 KB × 100M × 30 days | 30 TB (compressed) |
| Media files | 100M users × varies widely | 100+ PB for video |
| Logs | 1 KB × 13M RPS × 86400sec | 1.1 PB per day |

#### Scalability Targets

**Identifying Bottlenecks by Breaking Down System**

| Layer | Component | Capacity | Scaling Strategy |
|-------|-----------|----------|-----------------|
| **Edge** | CloudFront | Unlimited (AWS capacity) | Auto-scales |
| **Entry** | API Gateway | 10K RPS/account (soft limit) | Request increase, use NLB |
| | ALB | 25 Gbps per AZ | Add more ALBs or NLBs |
| **Compute** | Single EC2 | 200-500K connections | Autoscaling groups |
| | Lambda | 1000 concurrent executions (soft) | Concurrent execution quota |
| **Cache** | ElastiCache node | 200K ops/sec (redis r6g) | Add nodes, cluster mode |
| **Database** | RDS single instance | 100K connections max | Read replicas, sharding |
| | DynamoDB | 40K RCU/WCU per partition | On-demand or provisioned |
| **Queue** | SQS | 300 messages/sec per queue | Multiple queues + sharding |

### Practical Code Examples

#### AWS Lambda for Load Estimation

```python
#!/usr/bin/env python3
"""
Load estimation calculator for 1M concurrent users
"""

class LoadEstimator:
    def __init__(self, concurrent_users=1_000_000):
        self.concurrent_users = concurrent_users
    
    def estimate_rps(self, requests_per_user_per_sec=13):
        """Calculate RPS from concurrent users"""
        return self.concurrent_users * requests_per_user_per_sec
    
    def estimate_read_write_split(self, read_ratio=0.95):
        """Split RPS into reads and writes"""
        total_rps = self.estimate_rps()
        return {
            'total_rps': total_rps,
            'read_rps': int(total_rps * read_ratio),
            'write_rps': int(total_rps * (1 - read_ratio))
        }
    
    def estimate_storage(self, avg_data_per_user_gb=0.5, 
                        compression_ratio=0.7):
        """Estimate storage needed for user data"""
        raw_storage = self.concurrent_users * avg_data_per_user_gb
        compressed = raw_storage * compression_ratio
        return {
            'raw_gb': int(raw_storage),
            'compressed_gb': int(compressed),
            'with_3x_replication_gb': int(compressed * 3)
        }
    
    def estimate_bandwidth(self, avg_payload_mb=5, rps=None):
        """Estimate bandwidth requirements"""
        if rps is None:
            rps = self.estimate_rps()
        
        bytes_per_sec = rps * avg_payload_mb * 1_000_000
        gbps = bytes_per_sec / (1000 * 1_000_000 * 1000)
        return {
            'bytes_per_sec': int(bytes_per_sec),
            'mbps': int(bytes_per_sec / (1000 * 1000)),
            'gbps': round(gbps, 2)
        }

# Example usage
estimator = LoadEstimator(concurrent_users=1_000_000)

print("=== LOAD ESTIMATION FOR 1M CONCURRENT USERS ===\n")

print("RPS Estimates:")
print(f"  Total RPS: {estimator.estimate_rps():,}\n")

split = estimator.estimate_read_write_split()
print("Read/Write Split (95% reads, 5% writes):")
print(f"  Read RPS: {split['read_rps']:,}")
print(f"  Write RPS: {split['write_rps']:,}\n")

storage = estimator.estimate_storage()
print("Storage Estimates (0.5GB per user):")
print(f"  Raw: {storage['raw_gb']:,} GB")
print(f"  Compressed: {storage['compressed_gb']:,} GB")
print(f"  With 3x replication: {storage['with_3x_replication_gb']:,} GB\n")

bandwidth = estimator.estimate_bandwidth(avg_payload_mb=5)
print("Bandwidth Estimates (5MB avg payload):")
print(f"  {bandwidth['mbps']:,} Mbps ({bandwidth['gbps']} Gbps)")
```

#### CloudFormation Template for Capacity Monitoring

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Monitoring for capacity planning (1M users)'

Resources:
  CapacityDashboard:
    Type: AWS::CloudWatch::Dashboard
    Properties:
      DashboardName: SystemCapacity
      DashboardBody: !Sub |
        {
          "widgets": [
            {
              "type": "metric",
              "properties": {
                "metrics": [
                  ["AWS/ApplicationELB", "TargetResponseTime", {"stat": "Average"}],
                  ["AWS/ApplicationELB", "RequestCount", {"stat": "Sum"}],
                  ["AWS/RDS", "DatabaseConnections"],
                  ["AWS/ElastiCache", "CPUUtilization"],
                  ["AWS/DynamoDB", "ConsumedWriteCapacityUnits"],
                  ["AWS/Lambda", "Duration", {"stat": "Average"}],
                  ["AWS/Lambda", "Errors", {"stat": "Sum"}]
                ],
                "period": 60,
                "stat": "Average",
                "region": "${AWS::Region}",
                "title": "System Capacity Metrics"
              }
            }
          ]
        }

  # Alert when approaching RDS connection limit
  RDSConnectionAlert:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: RDSConnectionApproachingLimit
      MetricName: DatabaseConnections
      Namespace: AWS/RDS
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80  # 80% of max connections
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref SNSTopic

  # Alert when DynamoDB hot partition detected
  DynamoDBHotPartitionAlert:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: DynamoDBHotPartition
      MetricName: ConsumedWriteCapacityUnits
      Namespace: AWS/DynamoDB
      Dimensions:
        - Name: TableName
          Value: !Ref YourTable
      Statistic: Maximum
      Period: 60
      EvaluationPeriods: 1
      Threshold: 30000  # Per-partition limit
      ComparisonOperator: GreaterThanThreshold

  SNSTopic:
    Type: AWS::SNS::Topic
    Properties:
      TopicName: CapacityAlerts
      DisplayName: Alerts for capacity issues
```

### ASCII Diagrams

#### Request Scaling Model
```
CONCURRENT USERS → RPS CALCULATION
═════════════════════════════════════════════════════════════

1,000,000 Concurrent Users
        │
        ├─→ Peak Active (10%): 100,000 × 100 req/sec = 10M RPS
        │
        ├─→ Moderate (60%): 600,000 × 5 req/sec = 3M RPS
        │
        └─→ Idle (30%): 300,000 × 0.1 req/sec = 30K RPS
        
                TOTAL: ~13 Million RPS


READ/WRITE SPLIT (95/5)
═════════════════════════════════════════════════════════════

13M Total RPS
   │
   ├─→ Read Operations: 12.35M RPS (95%)
   │   ├─ Cache hits: 11M (89%)
   │   └─ Cache misses: 1.35M (11%)
   │
   └─→ Write Operations: 650K RPS (5%)
       ├─ Primary DB: 650K (sync)
       └─ Replicas: 650K (async, with lag)


LATENCY BUDGET DISTRIBUTION
═════════════════════════════════════════════════════════════

Total Budget: 1000ms (P99 target)

Network (Client→CloudFront)    [20ms] ░░
CloudFront Cache Processing    [50ms] ░░░░
API Gateway                    [20ms] ░░
Load Balancer                  [5ms]  ░
Application Processing         [400ms] ░░░░░░░░░░░░░░░░░░░░░░░
Database/Cache                 [200ms] ░░░░░░░░░░░░
Response Network (→Client)     [20ms] ░░
Queuing/Unexpected            [285ms] ░░░░░░░░░░░░░░░░░

                            Total: 1000ms
```

#### Storage Growth Over Time
```
STORAGE CAPACITY PLANNING
═════════════════════════════════════════════════════════════

100M User Profiles × 500 bytes per user = 50 GB
1M Concurrent Sessions × 1 KB = 1 GB
Activity Log (30 days) = 30 TB (compressed from 100 TB raw)

                 WITH 3X CROSS-AZ REPLICATION:
User Data:       50 GB × 3 = 150 GB
Session Data:    1 GB × 3 = 3 GB
Activity Logs:   30 TB × 3 = 90 TB

        TOTAL FIRST MONTH: ~90.15 TB replicated storage

Year 1 Projection (monthly growth 5%):
Month 1:  90 TB
Month 3:  100 TB
Month 6:  115 TB
Month 12: 170 TB
```

---

## 2. High Level Scaling Architecture

### Textual Deep Dive

#### Internal Working Mechanism: The Request Journey

Understanding how a request flows through your architecture reveals where bottlenecks occur and how to prevent cascading failures.

**Critical Path for a User Request**
```
User Client (Web/Mobile)
        ↓
    [1. DNS] → Route53 (geo-routing)
        ↓
    [2. TLS/SSL] → Certificate validation, session resumption
        ↓
    [3. Edge] → CloudFront (cache or originate)
        ↓
    [4. Security] → WAF (DDoS, SQL injection, rate limiting)
        ↓
    [5. Entry] → API Gateway / ALB (routing, throttling)
        ↓
    [6. Compute] → EC2/Lambda (request processing)
        ↓
    [7. Cache Layer] → ElastiCache (local cache, distributed cache)
        ↓
    [8. Data Layer] → RDS/DynamoDB/Redshift (persistent storage)
        ↓
    [9. Queue] → SQS/SNS (async processing)
        ↓
    [10. Storage] → S3/EFS (object/file storage)
        ↓
    Response sent back through same path
```

**Each layer must handle the full 13M RPS:**
- If edge layer drops 1%, that's 130K failed requests/sec
- If caching layer has 10% miss rate, 1.3M cache misses hit database per second
- If compute layer processes at 100K RPS per instance, need 130+ instances

#### Architecture Role of Each Layer

**Edge Layer (CloudFront, WAF, Lambda@Edge)**
- **Purpose**: Filter and cache before load reaches origin
- **Capacity**: Unlimited (AWS scales automatically)
- **Optimization**: Reduce origin load by 50-80% through caching

**Entry Layer (API Gateway, ALB)**
- **Purpose**: Route, authenticate, rate-limit at scale
- **Capacity**: API Gateway ~10K RPS; ALB ~25 Gbps per AZ
- **Decision Point**: If RPS > 10K, use NLB + WAF instead

**Compute Layer (EC2, Lambda, Fargate, EKS)**
- **Purpose**: Execute application business logic
- **Capacity**: Varies by instance type; auto-scales
- **Patterns**: Stateless design; connection pooling

**Cache Layer (ElastiCache, DAX)**
- **Purpose**: Reduce database load by 80-95%
- **Capacity**: redis r6g node ~200K ops/sec
- **Pattern**: Cache-aside with TTL; monitor hit rates

**Data Layer (RDS, DynamoDB, Redshift)**
- **Purpose**: Persistent storage with consistency guarantees
- **Capacity**: RDS ~100K connections; DynamoDB scales to billions of items
- **Bottleneck**: Write throughput; sharding required

**Async Layer (SQS, SNS, EventBridge)**
- **Purpose**: Decouple components; fan-out writes
- **Capacity**: SQS ~300 msg/sec per queue
- **Pattern**: Circuit breaker; exponential backoff

**Storage Layer (S3, EFS)**
- **Purpose**: Object/file storage with unlimited capacity
- **Capacity**: Unlimited objects; eventual consistency
- **Pattern**: Multipart uploads for large files

#### Production Usage Patterns

**Pattern 1: Cache-Intensive (Video Streaming)**
```
13M RPS Input
   │
   ├─→ 95% hit CloudFront → 12.35M RPS served (0ms latency)
   │
   └─→ 5% miss CloudFront → 650K RPS to origin
       │
       ├─→ 90% hit ElastiCache → 585K RPS cached (1ms latency)
       │
       └─→ 10% miss ElastiCache → 65K RPS to database

Net: Database handles only 0.5% of original load (65K from 13M)
```

**Pattern 2: Database-Centric (Real-time Chat)**
```
13M RPS Input
   │
   ├─→ 50% simple queries (can cache) → 6.5M to ElastiCache
   │   └─→ Cache handles all, 0 to database
   │
   └─→ 50% complex queries (can't cache) → 6.5M to database
       └─→ Database must handle 6.5M RPS
           └─→ Requires sharding across 100+ database instances

Solution: Shard by user_id; each shard handles 65K RPS
```

**Pattern 3: Asynchronous Processing (E-commerce Order)**
```
User submits order (write)
   │
   ├─→ API writes to DB immediately (1 write RPS)
   │
   └─→ Event published to SNS/EventBridge
       │
       ├─→ Email service subscriber (async, can batch)
       │
       ├─→ Inventory service subscriber (async)
       │
       └─→ Analytics service subscriber (async)

Result: All writes are fast (database doesn't block); 
        dependent services process independently
```

#### DevOps Best Practices

**Practice 1: Capacity Planning & Load Testing**
```bash
# Generate load in staging to measure bottlenecks
locust -f loadtest.py --host https://api.staging.example.com \
  --users 100000 --spawn-rate 1000 --run-time 10m

# Measure P99 latency
tail -f app.log | \
  jq '.duration_ms' | \
  percentile 99
```

**Practice 2: Circuit Breaker Pattern**
```
Normal: Request → Service → Response
        Success rate: 99.9%

Degraded: Service returning 50% errors
  ├─→ After 10 consecutive errors
  │
  ├─→ Breaker opens: Stop sending requests
  │
  ├─→ Return fallback/cached response immediately
  │
  └─→ Retry every 30 seconds; close if successful

Impact: Users see stale data but don't wait; prevents cascading failures
```

**Practice 3: Blue-Green Deployments**
```
Blue (Current):  Serving 100% of 13M RPS ✓
Green (New):     Running in parallel, getting 0% traffic

Deploy → Green version tested with 1% traffic
         If healthy → Shift 100% to Green
         If errors → Instant rollback to Blue

Downtime: 0 minutes
```

**Practice 4: Quota Management**
```
API Gateway: Set quota = 10M RPS (soft limit)
            Burst limit = 15M RPS (5 minutes)

Once hitting quota:
  ├─→ New requests get 429 (Too Many Requests)
  │
  ├─→ Client implements exponential backoff
  │
  └─→ Server gradually drains queue without crashing
```

#### Common Pitfalls

**Pitfall 1: Cascading Timeout Failure**
```
Scenario: Database becomes slow (1000ms responses)

Without timeouts:
  Request 1 arrives → waits for database → thread blocked
  Request 2 arrives → waits for database → thread blocked
  ... (repeat until all threads blocked)
  Application becomes unresponsive to new requests (cascade)

With timeouts (100ms):
  Request arrives → database times out after 100ms
  Application returns error immediately
  User retries or sees fallback
  Threads free up for other requests
```

**Pitfall 2: Cache Stampede**
```
Popular item: Cache expires
  ├─→ Request 1 tries to fetch: Cache miss
  │   ├─→ Request database (slow, 100ms)
  │   └─→ Database now overloaded with 1000s of simultaneous queries
  │
  ├─→ All waiting requests finally get response
  │   └─→ All write same data to cache (waste)
  │
  └─→ Latency spikes for all users

Solution: Use cache-with-lock pattern
  When miss detected, lock and fetch once
  Other requests wait for first fetch, use same result
```

**Pitfall 3: Overprovisioning for "Safety"**
```
Bad: "Let's provision for 100M RPS just in case"
  └─→ 77% of resources sit idle
  └─→ Monthly AWS bill: $5M
  └─→ Wasteful

Good: Provision for 13M RPS
  ├─→ Set auto-scaling alarms at 60% utilization
  │
  ├─→ Auto-scaling adds capacity in 2-5 minutes
  │
  └─→ Monthly AWS bill: $1M
```

**Pitfall 4: Incorrect Read/Write Ratio Assumptions**
```
Assumption: "95% reads, 5% writes"
Actual: Write-heavy workload (stock trading)
  ├─→ Replicate to all read replicas synchronously
  │
  └─→ Database write latency: 50-100ms (worse than expected)
  └─→ Users experience slow transactions

Solution: Measure actual read/write ratio in your system
          Adjust caching strategy and replication accordingly
```

### Practical Code Examples

#### Load Testing Script (Python/Locust)

```python
from locust import HttpUser, task, between
import random
import json

class APIUser(HttpUser):
    wait_time = between(0.5, 2)
    
    @task(7)  # 70% read operations
    def read_user_profile(self):
        """Simulate reading user profile"""
        user_id = random.randint(1, 100_000_000)
        self.client.get(
            f"/api/users/{user_id}",
            headers={"X-User-ID": str(user_id)},
            name="/api/users/[id]"
        )
    
    @task(2)  # 20% search operations
    def search_products(self):
        """Simulate product search (cache-heavy)"""
        query = random.choice(["laptop", "phone", "shoes", "book"])
        self.client.get(
            f"/api/search?q={query}&limit=10",
            name="/api/search"
        )
    
    @task(1)  # 10% write operations
    def create_order(self):
        """Simulate order creation"""
        user_id = random.randint(1, 100_000_000)
        order_data = {
            "user_id": user_id,
            "items": [
                {"product_id": random.randint(1, 10000), "qty": 1}
            ],
            "total": round(random.uniform(10, 500), 2)
        }
        self.client.post(
            "/api/orders",
            json=order_data,
            name="/api/orders"
        )
    
    def on_start(self):
        """Called when user starts"""
        self.headers = {
            "User-Agent": "APIClient/1.0",
            "Accept": "application/json"
        }
```

**Run load test:**
```bash
locust -f locustfile.py \
  --host https://api.example.com \
  --users 100000 \
  --spawn-rate 5000 \
  --run-time 5m \
  --headless \
  --csv=results
```

#### Circuit Breaker Implementation (Python)

```python
import time
from enum import Enum
from functools import wraps
from typing import Callable, Any

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing, block requests
    HALF_OPEN = "half_open"  # Testing if recovered

class CircuitBreaker:
    def __init__(
        self,
        failure_threshold: int = 5,
        recovery_timeout: int = 60,
        expected_exception: Exception = Exception
    ):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
    
    def call(self, func: Callable, *args: Any, **kwargs: Any) -> Any:
        """Execute function with circuit breaker protection"""
        
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        
        except self.expected_exception as e:
            self._on_failure()
            raise
    
    def _on_success(self):
        """Handle successful call"""
        self.failure_count = 0
        self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        """Handle failed call"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
    
    def _should_attempt_reset(self) -> bool:
        """Check if recovery timeout has passed"""
        return (
            time.time() > (self.last_failure_time + self.recovery_timeout)
        )

# Usage example
breaker = CircuitBreaker(
    failure_threshold=5,
    recovery_timeout=60,
    expected_exception=ConnectionError
)

def call_slow_service():
    """Simulated service call"""
    pass

try:
    result = breaker.call(call_slow_service)
except Exception as e:
    print(f"Service unavailable: {e}")
    # Return cached/fallback response
```

#### CloudFormation for Multi-Layer Architecture

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Scalable architecture for 1M concurrent users'

Parameters:
  DesiredCapacity:
    Type: Number
    Default: 100
    Description: 'Desired number of EC2 instances'
  
  MaxCapacity:
    Type: Number
    Default: 500
    Description: 'Maximum EC2 instances for autoscaling'

Resources:
  # VPC with multiple availability zones
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: ScalableVPC

  # Application Load Balancer for Layer 3-4
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: api-alb
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
        - !Ref PublicSubnet3
      SecurityGroups:
        - !Ref ALBSecurityGroup
      Scheme: internet-facing
      Type: application
      IpAddressType: ipv4

  # Autoscaling Group for Compute Layer
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        ImageId: ami-0c55b159cbfafe1f0  # Amazon Linux 2
        InstanceType: t3.large
        SecurityGroupIds:
          - !Ref AppSecurityGroup
        UserData:
          Fn::Base64: |
            #!/bin/bash
            yum update -y
            yum install -y docker
            systemctl start docker
            docker run -d \
              -p 8080:8080 \
              --name api-service \
              your-registry/api-service:latest

  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: 50
      MaxSize: !Ref MaxCapacity
      DesiredCapacity: !Ref DesiredCapacity
      VPCZoneIdentifier:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3
      TargetGroupARNs:
        - !Ref TargetGroup

  # Scale-up policy (CPU > 70%)
  ScaleUpPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !Ref AutoScalingGroup
      Cooldown: 300
      EstimatedWarmupSeconds: 60
      MetricAggregationType: Average
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70.0

  # ElastiCache Cluster (Redis)
  CacheSubnetGroup:
    Type: AWS::ElastiCache::SubnetGroup
    Properties:
      Description: Subnet group for cache
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2

  ElastiCacheCluster:
    Type: AWS::ElastiCache::ReplicationGroup
    Properties:
      Engine: redis
      CacheNodeType: cache.r6g.xlarge  # Memory-optimized
      NumCacheClusters: 3  # Multi-AZ
      AutomaticFailoverEnabled: true
      MultiAZEnabled: true
      CacheSubnetGroupName: !Ref CacheSubnetGroup
      SecurityGroupIds:
        - !Ref CacheSecurityGroup

  # RDS Database (Read Replicas)
  DBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: Subnet group for RDS
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3

  PrimaryDatabase:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: primary-db
      Engine: mysql
      EngineVersion: '8.0.35'
      DBInstanceClass: db.r6i.2xlarge  # Optimized for reads
      AllocatedStorage: 500
      StorageType: gp3
      StorageEncrypted: true
      DBSubnetGroupName: !Ref DBSubnetGroup
      VPCSecurityGroups:
        - !Ref DBSecurityGroup
      EnableCloudwatchLogsExports:
        - error
        - general
        - slowquery
      BackupRetentionPeriod: 30
      EnableIAMDatabaseAuthentication: true
      EnableMultiAZ: true

  # Read Replica for scaling reads
  ReadReplica1:
    Type: AWS::RDS::DBInstance
    Properties:
      SourceDBInstanceIdentifier: !Ref PrimaryDatabase
      DBInstanceIdentifier: read-replica-1
      DBInstanceClass: db.r6i.2xlarge
      PubliclyAccessible: false

  ReadReplica2:
    Type: AWS::RDS::DBInstance
    Properties:
      SourceDBInstanceIdentifier: !Ref PrimaryDatabase
      DBInstanceIdentifier: read-replica-2
      DBInstanceClass: db.r6i.2xlarge
      AvailabilityZone: us-east-1b

Outputs:
  LoadBalancerDNS:
    Description: DNS name of load balancer
    Value: !GetAtt ApplicationLoadBalancer.DNSName
  
  CacheEndpoint:
    Description: ElastiCache cluster endpoint
    Value: !GetAtt ElastiCacheCluster.PrimaryEndPoint.Address
  
  DatabaseEndpoint:
    Description: RDS endpoint
    Value: !GetAtt PrimaryDatabase.Endpoint.Address
```

### ASCII Diagrams

#### Request Path Through All Layers
```
REQUEST FLOW FOR 13M RPS SYSTEM
═════════════════════════════════════════════════════════════

                             1M CONCURRENT USERS
                                    │
                                    ↓
                    [1] ROUTE 53 (Geo-routing)
                    Distribute to nearest CloudFront edge
                                    │
                                    ↓
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
    US-EAST-1 CF              EU-WEST-1 CF              AP-SE-1 CF
    (400K users)              (300K users)              (300K users)
          │                         │                         │
          ↓                         ↓                         ↓
    [2] CloudFront             CloudFront              CloudFront
    Cache 95% of traffic       Cache 95% of traffic    Cache 95% of traffic
    Serve 380K RPS locally     Serve 285K RPS          Serve 285K RPS
          │ (5% hits origin)        │ (5%)                   │ (5%)
          │                         │                        │
          ├─────────────────────────┼────────────────────────┤
                          ↓
        [3] WAF Rate Limiting & DDoS
        Passes 95K RPS (after filtering 5%)
                          ↓
        [4] API Gateway + Authentication
        Distributes to regional ALBs
                          ↓
        ┌─────────────────┼──────────────────┐
        │                 │                  │
    ALB AZ-1          ALB AZ-2          ALB AZ-3
    (32K RPS)         (32K RPS)         (31K RPS)
        │                 │                  │
        ↓                 ↓                  ↓
    [5] Target Group 1  Target Group 2  Target Group 3
    50 EC2 instances    50 instances    30 instances
        │                 │                  │
        ↓                 ↓                  ↓
    [6] Application Processing
    ├─ Auth/validation:    20K RPS
    ├─ Cache lookup:       20K RPS (2K miss)
    └─ Business logic:     20K RPS
        │
        ├─────────────────────────┐
        │                         │
        ↓                         ↓
    [7] ElastiCache         [8] Database/Queue
    Cache hits: 18K RPS     Misses: 2K RPS
    5ms latency             100ms latency
        │
        └─────────────────────────┤
                                  │
                                  ↓
                    [9] Storage (S3, EFS)
                    Large object retrieval
                                  │
                                  ↓
                        Response sent back
```

#### Scaling Dimensions
```
VERTICAL SCALING (Single Component)
═════════════════════════════════════════════════════════════

t3.large → m5.2xlarge → c5.4xlarge → can't go bigger
(8 GB)     (32 GB)      (64 GB)     (hard limit)

Typical capacity per instance type:
  t3.large:       5K - 10K RPS
  m5.2xlarge:     20K - 30K RPS
  c5.4xlarge:     50K - 70K RPS (CPU-optimized)


HORIZONTAL SCALING (Multiple Components)
═════════════════════════════════════════════════════════════

13M RPS System

Approach 1 (Compute Layer):
  c5.4xlarge handles 50K RPS
  Need: 13,000,000 ÷ 50,000 = 260 instances
  With autoscaling: 100-500 instances based on load

Approach 2 (Database Layer with Sharding):
  RDS instance handles 100K connections
  For 13M RPS, need to shard because:
    • Connection limit: 100K
    • Write throughput: Limited by single instance
  Sharding strategy:
    Shard by user_id (mod 1000)
    Each shard: smaller dataset, faster queries
    1000 shards × 100 users each = 100M users total capacity
```

---

## 3. Edge Layer Design

### Textual Deep Dive

#### Internal Working Mechanism

The edge layer is your first and most critical defense against overwhelming origin servers. At 1 million concurrent users, the edge layer must:

1. **Cache static content** (CSS, JS, images): 95%+ cache hit rate
2. **Distribute traffic geographically** to reduce latency
3. **DDoS protection** at scale (volumetric attacks up to 720 Gbps)
4. **Optimize SSL/TLS** to avoid handshake delays
5. **Execute compute** (Lambda@Edge) before reaching origin

**Critical Insight**: Every percent of traffic that hits your origin costs exponentially more in infrastructure. If 1% of traffic bypasses the edge cache, that's 130K RPS hitting your database.

#### CloudFront: The AWS CDN

**Architecture**
```
CloudFront = 450+ Points of Presence (PoPs) worldwide
             ├─ 300+ edge locations (cache)
             ├─ 13+ regional edge caches (more capacity)
             └─ 1 origin (your ALB/API Gateway)
```

**Key Metrics for 1M Users**
| Metric | Value | Implication |
|--------|-------|------------|
| Cache Hit Ratio | 95% | Only 5% of traffic hits origin |
| Edge Cache TTL | 3600s (1 hour) | Revalidate hourly |
| Regional Cache TTL | 86400s (1 day) | Serves regional misses |
| Max object size | 20 GB | Larger files go to origin |
| Request rate | Unlimited | Auto-scales to Gbps |

**Cache Efficiency Calculation**
```
1M users × 10 req/sec = 10M RPS input
├─ 95% CloudFront hits = 9.5M RPS (served locally, <50ms)
│
└─ 5% CloudFront misses = 500K RPS
   ├─ 90% Regional edge hits = 450K RPS (medium latency, <200ms)
   │
   └─ 10% Regional edge misses = 50K RPS (hit origin database)

Net origin load: 50K RPS from 10M RPS = 0.5% (200x reduction)
```

**Cache Invalidation Strategies**

1. **TTL-Based (Time To Live)**
   - Set Cache-Control headers with max-age
   - Stale-while-revalidate: Return stale while revalidating
   - Risk: Users see outdated content

2. **Event-Driven Invalidation**
   - On database write, publish SNS message
   - Lambda invalidates CloudFront cache
   - Risk: Invalidation lag (5-10 minutes for global distribution)

3. **Version-Based (Recommended)**
   - Append version hash to URL: `/images/logo-v123.png`
   - Change URL whenever content updates
   - No explicit invalidation needed; old version stays cached

#### WAF (Web Application Firewall)

At 1M users, DDoS attacks are inevitable. AWS WAF protects against:

**Rate-Based Protection**
```
IP makes > 2000 requests/5 mins → Block for 15 mins
```

At 1M concurrent users:
- Legitimate user: 10 req/sec = 300 req/5 min (safe)
- Attacker: 1000 req/sec = 5000 req/5 min (blocked)

**SQL Injection/XSS Protection**
```
Request: /api/users?id=1 OR 1=1--
WAF detects malicious pattern
Action: Block + log + alert

Cost of missing this: Database admin access, data exfiltration
```

**Geo-Blocking**
```
Business operates in EU + US only
Requests from China → Block (reduce 10% of DDoS traffic)
Savings: Reduced bandwidth charges
```

#### Lambda@Edge: Compute at the Edge

For 1M users, some decisions can be made at edge without hitting origin:

**Use Case 1: Bot Detection**
```
Edge receives 100K RPS
├─ 90K from trusted clients → Forward to origin
└─ 10K from bots → Return 403 Forbidden immediately
     Benefit: Prevents 10K RPS of useless Origin load
```

**Use Case 2: Cookie-Based Routing**
```
User has "beta=true" cookie
├─ Route to /beta-api.example.com (testing environment)
└─ Other users route to /api.example.com (production)
     Benefit: A/B testing without modifying application
```

**Use Case 3: Image Optimization On-the-Fly**
```
Edge receives request: /image.jpg?width=200&format=webp
Lambda@Edge intercepts:
├─ Resize to 200px width (on-the-fly, no storage)
├─ Convert to WebP (modern format, 30% smaller)
├─ Cache resized version for next request
└─ Return 30% smaller response
     Benefit: 30% less bandwidth × 1M users = massive savings
```

**Performance Consideration**
```
Lambda@Edge execution time adds latency
  Typical: 5-10ms for simple operations
  Benefit: Must exceed CloudFront cache hit latency to justify
  
  CloudFront hit latency: 20ms
  Lambda@Edge latency: 15ms + function execution (5-10ms)
  
  Only use Lambda@Edge for:
    • High-frequency decisions (routing, bot detection)
    • Compute cheaper on edge than origin
    • Cache invalidation optimization
```

#### Production Usage Patterns

**Pattern 1: Static Content Distribution**
```
Website traffic breakdown:
  HTML pages: 2%
  CSS/JS: 18%
  Images: 70%
  Video: 10%

Caching strategy:
  HTML: TTL 5 mins (frequently updated)
  CSS/JS: TTL 365 days (versioned URLs)
  Images: TTL 365 days (immutable)
  Video: TTL 30 days (streaming quality varies)

Result: 95%+ cache hit ratio; Origin sees only 2% of traffic
```

**Pattern 2: Geographic Optimization**
```
Users worldwide (1M concurrent)
├─ 400K in USA (us-west-1, us-east-1)
├─ 300K in EU (eu-west-1)
├─ 300K in Asia (ap-southeast-1)

Route 53 Geolocation Routing:
  USA traffic → ALB in us-east-1
  EU traffic → ALB in eu-west-1  
  Asia traffic → ALB in ap-southeast-1

Benefit: Reduced latency (CDN serves locally)
         Each region's infrastructure fits its traffic
```

**Pattern 3: DDoS Mitigation at Scale**
```
Legitimate traffic: 10M RPS
Under attack: 50M RPS attempted inbound

AWS WAF rate limiting:
  IP rate limit: 2000 req/5 min per IP
  ├─ Blocks attackers (1000+ req/sec per IP)
  └─ Allows legitimate users (10-40 req/sec)

Volumetric attack (720 Gbps):
  ├─ CloudFront autoscales to billions of requests/sec capacity
  │
  └─ AWS absorbs attack + charges for bandwidth only
      (Attacker loses money, not you)
```

#### DevOps Best Practices

**Practice 1: Cache Header Management**
```
Incorrect:
  Cache-Control: max-age=0  (no cache)
  Result: Every request hits origin, 13M RPS load

Correct:
  Static: Cache-Control: max-age=31536000 (1 year, immutable)
  Dynamic: Cache-Control: max-age=300, stale-while-revalidate=3600
  Result: 95% cached, reduces origin load 20x
```

**Practice 2: Origin Shield (Additional Cache Layer)**
```
Standard CloudFront:
  ├─ Edge cache (450 locations)
  └─ Origin (1 location)
  
  Problem: 5% cache miss × 10M RPS = 500K RPS hitting origin
  Each miss = additional latency

With Origin Shield:
  ├─ Edge cache (450 locations)
  ├─ Regional shield (13 locations)
  └─ Origin
  
  Effect: 9.9% cache hit; only 0.1% hits origin (50x reduction)
  Cost: +$0.01 per 10K requests
  ROI: Saves 1 database instance per 10M RPS (~$1000/month)
```

**Practice 3: Monitoring Cache Metrics**
```
CloudFront Console provides:
  CacheHitRate (%) = Hits / (Hits + Misses)
  Target: 95%+ for static content, 60%+ for dynamic

If CacheHitRate < 80%:
  ├─ Increase TTL (if stale content acceptable)
  ├─ Change cache key (reduce key variations)
  └─ Check origin headers (Cache-Control being respected?)

If CacheHitRate = 99%:
  └─ Check TTL isn't too long (might serve stale data)
```

#### Common Pitfalls

**Pitfall 1: Query String Proliferation**
```
Request 1: /api/users?id=123&format=json&timezone=UTC
Request 2: /api/users?format=json&id=123&timezone=UTC
Request 3: /api/users?timezone=UTC&id=123&format=json

Same data, different cache keys → 0% hit rate
Solution: Normalize query string order or exclude from cache key
Result: 95%+ cache hit rate instead of <5%
```

**Pitfall 2: Cache Poisoning**
```
Attacker injects malicious response:
  /api/users/profile → HTML with JavaScript injection
  
CloudFront caches malicious response
  → All 1M users get XSS attack
  → Data theft, credential hijacking
  
Solution:
    ├─ Validate origin response (WAF inspection of origin response)
    ├─ Sign responses (HMAC, timestamps)
    └─ Monitor cache for anomalies (sudden increases in cache size)
```

**Pitfall 3: Insufficient DDoS Capacity**
```
Attack: 200 Gbps volumetric assault
  └─ Attackers amplify traffic using DNS servers

Without proper DDoS protection:
  ├─ CloudFront fills up
  ├─ Legitimate traffic gets dropped
  └─ Website unreachable (even though origin is fine)

Solution: AWS Shield Advanced + WAF rate limiting
  └─ Absorbs attacks; charges only for legitimate traffic
```

### Practical Code Examples

#### CloudFront + Origin Shield CloudFormation

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'CloudFront distribution with Origin Shield for 1M users'

Resources:
  # S3 bucket for static content
  StaticContentBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Sub 'static-content-${AWS::AccountId}'
      VersioningConfiguration:
        Status: Enabled
      PublicAccessBlockConfiguration:
        BlockPublicAcls: true
        BlockPublicPolicy: true
        IgnorePublicAcls: true
        RestrictPublicBuckets: true

  # CloudFront Origin Access Identity
  CloudFrontOAI:
    Type: AWS::CloudFront::CloudFrontOriginAccessIdentity
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: OAI for static content

  # S3 bucket policy (CloudFront only)
  StaticBucketPolicy:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket: !Ref StaticContentBucket
      PolicyText:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${CloudFrontOAI}'
            Action: 's3:GetObject'
            Resource: !Sub '${StaticContentBucket.Arn}/*'

  # WAF ACL for DDoS protection
  WAFACLEdge:
    Type: AWS::WAFv2::WebACL
    Properties:
      Scope: CLOUDFRONT
      DefaultAction:
        Allow: {}
      Rules:
        # Rate limiting rule (2000 req/5 min per IP)
        - Name: RateLimitRule
          Priority: 0
          Statement:
            RateBasedStatement:
              Limit: 2000
              AggregateKeyType: IP
          Action:
            Block: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: RateLimitMetric
        
        # AWS Managed Rules for common attacks
        - Name: AWSManagedRulesCommonRuleSet
          Priority: 1
          Statement:
            ManagedRuleGroupStatement:
              VendorName: AWS
              Name: AWSManagedRulesCommonRuleSet
          OverrideAction:
            None: {}
          VisibilityConfig:
            SampledRequestsEnabled: true
            CloudWatchMetricsEnabled: true
            MetricName: AWSManagedRulesMetric

      VisibilityConfig:
        SampledRequestsEnabled: true
        CloudWatchMetricsEnabled: true
        MetricName: WAFEdgeMetric

  # CloudFront Distribution with Origin Shield
  CDNDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Enabled: true
        Comment: 'CDN for 1M concurrent users'
        HttpVersion: http2and3
        WebACLId: !GetAtt WAFACLEdge.Arn
        
        Origins:
          # S3 origin for static content
          - Id: S3StaticOrigin
            DomainName: !GetAtt StaticContentBucket.RegionalDomainName
            S3OriginConfig:
              OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${CloudFrontOAI}'
            OriginShield:
              Enabled: true
              OriginShieldRegion: us-east-1
          
          # Application origin (ALB)
          - Id: ApplicationOrigin
            DomainName: api.internal.example.com
            CustomOriginConfig:
              HTTPPort: 80
              HTTPSPort: 443
              OriginProtocolPolicy: https-only
              OriginSSLProtocols:
                - TLSv1.2
            OriginShield:
              Enabled: true
              OriginShieldRegion: us-east-1

        DefaultCacheBehavior:
          # Route to Application origin by default
          TargetOriginId: ApplicationOrigin
          ViewerProtocolPolicy: redirect-to-https
          AllowedMethods:
            - GET
            - HEAD
            - OPTIONS
            - PUT
            - POST
            - PATCH
            - DELETE
          CachePolicyId: 4135ea3d-c35d-46eb-81d7-rewrite_83a2fd50  # Custom policy
          OriginRequestPolicyId: 30b04647-74a8-47d6-a186-0505staticpolicy
          Compress: true
          
        CacheBehaviors:
          # Static content (images, CSS, JS)
          - PathPattern: '/static/*'
            TargetOriginId: S3StaticOrigin
            ViewerProtocolPolicy: https-only
            AllowedMethods:
              - GET
              - HEAD
            CachePolicyId: '658327ea-f89d-4fab-a63d-7e88639e58f6'  # Managed-CachingOptimized
            Compress: true
          
          # API responses (short cache)
          - PathPattern: '/api/*'
            TargetOriginId: ApplicationOrigin
            ViewerProtocolPolicy: https-only
            AllowedMethods:
              - GET
              - HEAD
              - OPTIONS
              - PUT
              - POST
              - PATCH
              - DELETE
            CachePolicy:
              Id: '4135ea3d-c35d-46eb-81d7-7ac180a65980'  # Managed-CachingDisabled
            OriginRequestPolicy:
              Id: '216adef5-5c7f-47e4-b989-5492eafa07d3'  # AllViewerExceptHostHeader
            Compress: true

        ViewerCertificate:
          AcmCertificateArn: arn:aws:acm:us-east-1:ACCOUNT:certificate/ID
          SslSupportMethod: sni-only
          MinimumProtocolVersion: TLSv1.2_2021

        Logging:
          Bucket: !Sub '${LoggingBucket}.s3.amazonaws.com'
          IncludeCookies: false
          Prefix: 'cloudfront-logs/'

Outputs:
  DistributionDomain:
    Description: CloudFront distribution domain
    Value: !GetAtt CDNDistribution.DomainName
  
  CacheHitRateAlarm:
    Description: Alarm for low cache hit ratio
    Value: !Ref CacheHitRateAlarm
```

#### Lambda@Edge for Bot Detection

```python
# Deploy to Lambda@Edge (trigger on CloudFront viewer request)

def lambda_handler(event, context):
    request = event['Records'][0]['cf']['request']
    headers = request['headers']
    
    # Extract user agent and IP
    user_agent = next(
        (h['value'] for h in headers.get('user-agent', []) 
         if h.get('key') == 'User-Agent'),
        ''
    ).lower()
    
    # Known bot user agents
    bot_patterns = [
        'curl', 'wget', 'python', 'scrapy', 'selenium',
        'bot', 'crawler', 'spider', 'robot', 'scraper'
    ]
    
    # Check if request matches bot patterns
    is_bot = any(pattern in user_agent for pattern in bot_patterns)
    
    if is_bot:
        return {
            'status': '403',
            'statusDescription': 'Forbidden',
            'headers': {
                'content-type': [{'key': 'Content-Type', 'value': 'text/html'}]
            },
            'body': '<html><body><h1>Access Denied</h1></body></html>'
        }
    
    # Allow legitimate traffic
    return request
```

#### CloudFront Cache Invalidation Script

```bash
#!/bin/bash
# Invalidate CloudFront cache on application deploy

DISTRIBUTION_ID="E3EXAMPLE"
PATHS_TO_INVALIDATE=("/" "/api/*" "/static/*")

echo "Invalidating CloudFront cache..."

INVALIDATION_ID=$(aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "${PATHS_TO_INVALIDATE[@]}" \
  --query 'Invalidation.Id' \
  --output text)

echo "Invalidation created: $INVALIDATION_ID"

# Wait for invalidation to complete
echo "Waiting for invalidation to complete..."
aws cloudfront wait invalidation-completed \
  --distribution-id $DISTRIBUTION_ID \
  --id $INVALIDATION_ID

echo "Cache invalidation complete!"

# Verify new version is being served
echo "Verifying new version is cached..."
curl -I https://cdn.example.com/api/status | grep "ETag"
```

### ASCII Diagrams

#### Edge Layer Architecture
```
CLOUDFRONT EDGE LAYER FOR 1M CONCURRENT USERS
═════════════════════════════════════════════════════════════

                 1 MILLION CONCURRENT USERS
                    ├─ 400K USA
                    ├─ 300K EU
                    └─ 300K Asia
                            │
            ┌───────────────┼───────────────┐
            ↓               ↓               ↓
        US Edge        EU Edge         Asia Edge
        (200+ PoP)     (150+ PoP)      (100+ PoP)
            │               │             │
            ├─ Static cache ├─ Static cache ├─ Static cache
            │ (350K RPS)    │ (250K RPS)    │ (200K RPS)
            │               │              │
            ├─ 95% HIT      ├─ 95% HIT     ├─ 95% HIT
            │ = 332K RPS    │ = 237K RPS   │ = 190K RPS
            │               │              │
            └─ 5% MISS      └─ 5% MISS     └─ 5% MISS
              = 18K RPS        = 13K RPS      = 10K RPS
              (to shield)      (to shield)    (to shield)
              │                │              │
              └────────────────┼──────────────┘
                               ↓
                    ORIGIN SHIELD (Regional)
                   (13 regional locations)
                               │
                        41K RPS (5% of 820K)
                               │
                    ┌───────────┼───────────┐
                    ↓           ↓           ↓
                Shield      Shield      Shield
                US-East     EU-West     AP-SE
                            │
                       30K RPS (90% hit)
                       11K RPS (10% miss)
                            │
                    ORIGIN (ALB in us-east-1)
                    Only 11K RPS (0.1% of input!)
```

#### Cache Hit Ratio Impact
```
CACHE PERFORMANCE IMPACT
═════════════════════════════════════════════════════════════

Scenario A: Poor caching (60% hit ratio)
  10M RPS input
  ├─ 6M RPS cached (60%)
  └─ 4M RPS to origin (40%)
     └─ Origin must handle 4M RPS
        └─ Needs 100+ large instances ($50K/month)

Scenario B: Good caching (90% hit ratio)
  10M RPS input
  ├─ 9M RPS cached (90%)
  └─ 1M RPS to origin (10%)
     └─ Origin must handle 1M RPS
        └─ Needs 25 large instances ($12.5K/month)

Scenario C: Excellent caching (98% hit ratio)
  10M RPS input
  ├─ 9.8M RPS cached (98%)
  └─ 0.2M RPS to origin (2%)
     └─ Origin must handle 0.2M RPS
        └─ Needs 5 large instances ($2.5K/month)

DIFFERENCE: 8% better cache → 40% cost savings
```

---

## 4. Entry Layer - Routing & Throttling

### Textual Deep Dive

#### Internal Working Mechanism

The entry layer is where traffic enters your AWS infrastructure. At 1 million concurrent users, the entry layer must:

1. **Route requests** to the right backend (path-based, hostname-based, weight-based)
2. **Throttle** to prevent overwhelming downstream services
3. **Authenticate** requests before expensive processing
4. **Balance load** across multiple backend instances
5. **Failover** if backends become unhealthy

**The Challenge**: Most AWS services have built-in limits. API Gateway maxes out at ~10K RPS per account (soft limit). For 13M RPS, you need multiple entry points or a Network Load Balancer.

#### API Gateway vs. ALB vs. NLB

| Feature | API Gateway | ALB | NLB |
|---------|------------|-----|-----|
| Throughput | ~10K RPS | 25 Gbps | 100 Gbps |
| Latency | Medium (50-100ms) | Low (5-10ms) | Very Low (< 5ms) |
| Layer | Application (L7) | Application (L7) | Network (L4) |
| Cost | Pay per request | Hourly + data | Hourly + data |
| For 13M RPS | Requires workarounds | Sharding (multiple) | Preferred |
| HTTP/2 | Yes | Yes | Yes |
| WebSocket | Yes | No | No |
| Authentication | Built-in | No | No |

**Recommendation**: Use NLB for throughput-heavy systems; API Gateway for REST APIs with < 10K RPS.

#### Rate Limiting Strategies

**Strategy 1: Token Bucket Algorithm**
```
Each user has a "bucket" of tokens
- Bucket capacity: 1000 requests
- Tokens replenish at: 100 req/sec (rate limit)

User A arrives with 800 tokens:
  ├─ Request 1 (50 tokens): 750 tokens remain
  ├─ Request 2 (50 tokens): 700 tokens remain
  ├─ Request 3 (50 tokens): 650 tokens remain
  └─ Small delay between requests doesn't matter (token bank absorbs bursts)

User B (attacker) tries 10K requests:
  ├─ Request 1-1000: Succeed (consume 50 tokens each)
  ├─ Request 1001: REJECTED (0 tokens)
  └─ Must wait 10 seconds for bucket to refill

Benefit: Allows bursts; prevents sustained attacks
Cost: Low (few bytes of state per user)
```

**Strategy 2: Sliding Window**
```
Current time window: 12:34:00 - 12:34:59
User's requests this window: 450 (out of 1000/sec limit)
Remaining requests:  550

Time advances to 12:34:01
Previous window (12:33:00-12:33:59) rolls off
Requests reset to 0 (if previous window ended)
```

**Strategy 3: Leaky Bucket**
```
Requests arrive
  │
  └─→ Bucket (fixed size: 100 requests)
      │
      ├─ If full: NEW REQUEST REJECTED ("Too Many Requests" 429)
      │
      └─ Processed at constant rate (1000 req/sec)
         └─ Requests leak out at fixed rate

Benefit: Prevents bursty traffic; smooths load on downstream services
Drawback: Low burst tolerance (sudden spike rejected)
```

**Throttling Implementation at Entry Layer**

```
Request arrives:
  │
  ├─ Identify client (IP, API key, user ID)
  │
  ├─ Check rate limit for client
  │   ├─ If OK: forward to backend
  │   └─ If exceeded: return 429 (Too Many Requests)
  │
  └─ Log for monitoring
     └─ Alert if any client exceeds quota
```

#### Failover & Health Checks

**Health Check Flow**
```
ALB every 30 seconds:
  ├─ HTTP GET / (or custom endpoint)
  │   └─ Healthy if response 200-299 and timeout < 5s
  │
  ├─ If unhealthy (3 consecutive failures):
  │   └─ Stop routing traffic to instance
  │
  └─ Mark unhealthy; replace with new instance
    (Autoscaling group launches replacement)

Cost of bad health check:
  ├─ Excessive checks: Overload application
  └─ Insufficient checks: Traffic routes to failing instance

Optimal: Health check every 30-60 seconds on lightweight endpoint
```

**Failover Types**

1. **Instance Failure** (5-10% failure rate at scale)
   ```
   Healthy instances: 100
   Failed instances: 5
   
   ALB detects failure (30 sec max)
   ├─ Removes failed instance from pool
   └─ Reroutes traffic to remaining 95 instances
   
   Cost: Temporary 5.26% latency increase (100/95 = 1.05x)
   Autoscaling launches replacement within 2-5 minutes
   ```

2. **AZ Failure** (annual probability ~0.5%)
   ```
   3-AZ deployment (us-east-1a, 1b, 1c)
   Scenario: us-east-1a becomes unreachable
   
   Affected: 33 instances (1/3 of 100)
   Surviving: 67 instances
   
   New ratio: 100/67 = 1.49x latency penalty
   Recovery: 5-10 minutes to fully restore
   
   Solution: Over-provision for N-1 AZ failure
   ```

3. **Region Failure** (rare, planned for)
   ```
   Primary region: us-east-1 (1M RPS)
   Standby region: us-west-2 (scaled to handle traffic)
   
   Route 53 health checks:
     ├─ Primary healthy? Use primary (low latency)
     └─ Primary down? Failover to standby
        └─ Users get 100-200ms higher latency (acceptable)
   
   Setup: Active-passive (warm standby) or active-active (complex)
   ```

#### Production Usage Patterns

**Pattern 1: Gradual Rollout (Canary Deployment)**
```
New version in testing
  ├─ 99% traffic to stable version
  └─ 1% traffic to new version (canary)
  
Monitor canary:
  ├─ Error rate < 0.5%: expand to 10%
  ├─ Error rate < 0.1%: expand to 50%
  └─ Error rate > 1%: Rollback immediately

Cost: Almost zero; canary uses existing capacity
Benefit: Bugs caught before reaching 1M users
```

**Pattern 2: Traffic Shaping for Load Shedding**
```
Under extreme load (13M RPS vs. capacity 12M RPS):

ALB rate limiting:
  ├─ Requests from "premium" users: Always accept
  ├─ Requests from "standard" users: Accept 60%
  └─ Requests from "free" users: Accept 5%
  
Result: System stays stable; free users get degraded service (not down)
Better than: Crashing completely and affecting everyone
```

#### DevOps Best Practices

**Practice 1: Multi-Region Entry Points**
```
Single region failure impact: Catastrophic (1M users offline)

Multi-region:
  ├─ Route 53 active-active across regions
  │   ├─ us-east-1: 50% traffic
  │   └─ eu-west-1: 50% traffic
  │
  └─ If us-east-1 fails:
      └─ eu-west-1 automatically handles 100% (has standby capacity)

Requirement: Data replication lag acceptable for your use case
```

**Practice 2: Request Logging for Debugging**
```
Every request logs:
  ├─ Trace ID (correlates across services)
  ├─ User ID
  ├─ Timestamp
  ├─ Request path
  ├─ Response code
  ├─ Response time
  └─ Backend instance ID

Storage: CloudWatch Logs
  └─ 50K+ log lines/sec for 1M users
  
Query examples:
  └─ "Find all 500 errors for user 12345 on 2024-01-15"
  └─ "Show P99 latency by endpoint"
  └─ "Identify slowest backend instances"
```

**Practice 3: Distributed Tracing**
```
Request enters API Gateway → Trace ID generated
  ├─ API Gateway → adds span (10ms)
  ├─ ALB → adds span (2ms)
  ├─ Application → adds span (400ms)
  ├─ Database → adds span (100ms)
  └─ Total: 512ms

After request completes:
  X-Ray dashboard shows:
    └─ Database is slowest (100/512 = 20% of time)
    
Actionable: Optimize database query; add caching
```

#### Common Pitfalls

**Pitfall 1: API Gateway Soft Limit Hit**
```
Soft limit: 10K RPS per account
System needs: 13M RPS

Request: Increase limit to AWS
AWS: "That's our architecture limit, use ALB instead"

Timeline:
  ├─ Day 1: Hit limit, requests rejected
  ├─ Day 2: Migrate to ALB (takes hours)
  └─ Cost: Lost revenue, angry customers

Solution: Plan for 13M RPS architecture from start (use NLB/ALB)
```

**Pitfall 2: Insufficient Health Check Tuning**
```
Problem 1: Health check too aggressive
  ├─ Checks every 5 seconds × 100 instances = 1200 requests/min
  │   
  └─> Application health endpoint overloaded
      └─> Becomes unhealthy due to load (self-fulfilling prophecy)

Solution: Health check every 30 seconds; lightweight endpoint

Problem 2: Health check timeout too short
  ├─ Timeout: 2 seconds
  ├─ Under load, endpoint takes 3 seconds
  │   
  └─> Healthy instance marked unhealthy
      └─> Sudden failover = thundering herd (remaining instances overloaded)

Solution: Timeout 5+ seconds; monitor actual health endpoint latency
```

**Pitfall 3: Forgetting to Disable Sticky Sessions**
```
Sticky sessions (ALB cookie affinity):
  ├─ User → Route to same instance always
  │
  ├─ Problem: Load imbalance
  │   └─ Heavy user gets same instance for days
  │       └─ That instance's CPU = 90%, others = 20%
  │
  └─ Broken failover:
      └─ User's instance dies
          └─ Cookie points to dead instance
              └─ New request gets 503 (not auto-routed)

Solution: Keep sessions in Redis; route to any instance
Result: True load balancing; automatic failover
```

### Practical Code Examples

#### NLB with Autoscaling CloudFormation

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Network Load Balancer for 13M RPS system'

Parameters:
  DesiredCapacity:
    Type: Number
    Default: 130
    Description: 'Number of EC2 instances (100K RPS each)'
  
  MinCapacity:
    Type: Number
    Default: 100
  
  MaxCapacity:
    Type: Number
    Default: 300

Resources:
  # VPC and Subnets (3 AZs for redundancy)
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true

  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']

  PublicSubnet3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [2, !GetAZs '']

  # Network Load Balancer (Layer 4, ultra-high throughput)
  NetworkLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: entry-point-nlb
      Type: network
      Scheme: internet-facing
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
        - !Ref PublicSubnet3
      IpAddressType: ipv4
      Tags:
        - Key: Name
          Value: EntryPoint

  # Target Group for backend instances
  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: api-servers
      Port: 8080
      Protocol: TCP
      VpcId: !Ref VPC
      TargetType: instance
      HealthCheckProtocol: TCP
      HealthCheckPort: 8080
      HealthCheckIntervalSeconds: 30
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 3
      TargetGroupAttributes:
        - Key: deregistration_delay.timeout_seconds
          Value: '30'
        - Key: preserve_client_ip.enabled
          Value: 'true'

  # NLB Listener (Port 443 with TLS)
  TCPListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      LoadBalancerArn: !GetAtt NetworkLoadBalancer.LoadBalancerArn
      Protocol: TLS
      Port: 443
      Certificates:
        - CertificateArn: !Sub 'arn:aws:acm:${AWS::Region}:${AWS::AccountId}:certificate/CERTIFICATE_ID'
      DefaultActions:
        - Type: forward
          TargetGroupArn: !GetAtt TargetGroup.TargetGroupArn

  # Launch Template for EC2 instances
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: api-server-template
      LaunchTemplateData:
        ImageId: ami-0c55b159cbfafe1f0  # Amazon Linux 2
        InstanceType: c5.4xlarge  # 100K RPS per instance
        SecurityGroupIds:
          - !Ref AppSecurityGroup
        TagSpecifications:
          - ResourceType: instance
            Tags:
              - Key: Name
                Value: APIServer
        UserData:
          Fn::Base64: |
            #!/bin/bash
            yum update -y
            yum install -y docker cloud-watch-agent
            systemctl enable docker
            systemctl start docker
            
            # Pull and run application
            docker run -d \
              --name api-server \
              -p 8080:8080 \
              -e LOG_LEVEL=warn \
              your-registry/api-service:latest
            
            # CloudWatch agent for monitoring
            /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
              -a fetch-config \
              -m ec2 \
              -s

  # Autoscaling Group
  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: api-servers-asg
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: !Ref MinCapacity
      MaxSize: !Ref MaxCapacity
      DesiredCapacity: !Ref DesiredCapacity
      VPCZoneIdentifier:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3
      TargetGroupARNs:
        - !GetAtt TargetGroup.TargetGroupArn
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300
      Tags:
        - Key: Name
          Value: APIServer
          PropagateAtLaunch: true

  # Scaling Policy: Scale up when CPU > 70%
  ScaleUpPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !Ref AutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70.0

  # Scaling Policy: Scale down when CPU < 40%
  ScaleDownPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !Ref AutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 40.0

  # CloudWatch Alarm: Warn if more than 200 instances needed
  HighCapacityAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: HighCapacityRequired
      MetricName: GroupDesiredCapacity
      Namespace: AWS/AutoScaling
      Statistic: Average
      Period: 300
      EvaluationPeriods: 1
      Threshold: 200
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: AutoScalingGroupName
          Value: !Ref AutoScalingGroup
      AlarmActions:
        - !Ref AlertTopic

Outputs:
  LoadBalancerDNS:
    Description: NLB endpoint
    Value: !GetAtt NetworkLoadBalancer.DNSName
  
  TargetGroupArn:
    Description: Target group for routing
    Value: !GetAtt TargetGroup.TargetGroupArn
```

#### Rate Limiting Middleware (Python Flask)

```python
from flask import Flask, request, jsonify
from collections import defaultdict
import time
import threading

app = Flask(__name__)

class RateLimiter:
    """Token bucket rate limiter"""
    
    def __init__(self, rate_limit=1000, refill_time=60):
        self.rate_limit = rate_limit
        self.refill_time = refill_time
        self.buckets = defaultdict(lambda: rate_limit)
        self.last_refill = defaultdict(time.time)
        self.lock = threading.Lock()
    
    def is_allowed(self, client_id):
        """Check if client is within rate limit"""
        with self.lock:
            now = time.time()
            last = self.last_refill[client_id]
            
            # Refill tokens based on time elapsed
            elapsed = now - last
            refill_amount = (elapsed / self.refill_time) * self.rate_limit
            
            self.buckets[client_id] = min(
                self.rate_limit,
                self.buckets[client_id] + refill_amount
            )
            self.last_refill[client_id] = now
            
            # Check if client has tokens
            if self.buckets[client_id] >= 1:
                self.buckets[client_id] -= 1
                return True
            
            return False

limiter = RateLimiter(rate_limit=100/60)  # 100 req per minute

@app.before_request
def check_rate_limit():
    """Enforce rate limiting on all requests"""
    
    # Identify client (prefer API key > user ID > IP)
    client_id = (
        request.headers.get('X-API-Key') or
        request.headers.get('X-User-ID') or
        request.remote_addr
    )
    
    if not limiter.is_allowed(client_id):
        return jsonify(
            error="Rate limit exceeded",
            retry_after=60
        ), 429

@app.route('/api/data', methods=['GET'])
def get_data():
    return jsonify(data="Response data")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

### ASCII Diagrams

#### Multi-AZ NLB Architecture
```
NETWORK LOAD BALANCER FOR ENTRY LAYER
═════════════════════════════════════════════════════════════

                      13 MILLION RPS
                            │
                      ROUTE 53 DNS
                      (Geo-routing)
                            │
        ┌───────────────────┼───────────────────┐
        ↓                   ↓                   ↓
    NLB in AZ-1        NLB in AZ-2        NLB in AZ-3
    (25 Gbps)          (25 Gbps)          (25 Gbps)
    ~4.3M RPS          ~4.3M RPS          ~4.3M RPS
        │                   │                   │
        ├─────────────────────────────────────┤
        │           Rate Limiting              │
        │       (Token bucket per IP)           │
        │                                      │
        ├─────────────────────────────────────┤
        │        Health Check (every 30s)      │
        │                                      │
        ├─────────────────────────────────────┤
        ↓                   ↓                   ↓
    Target Group A     Target Group B     Target Group C
    (50 instances)     (40 instances)     (40 instances)
    (100K RPS each)    (100K RPS each)    (100K RPS each)
        │                   │                   │
        ├─────────────────────────────────────┤
        │      Distributed Load (round-robin)  │
        │                                      │
        ├─────────────────────────────────────┤
        ↓
    Individual EC2 Instances
    (Application servers)
```

---

## 5. Compute Layer

### Textual Deep Dive

#### Internal Working Mechanism

The compute layer executes your application logic. At 1 million concurrent users generating 13 million RPS, the compute layer must:

1. **Execute requests efficiently** (sub-100ms per request)
2. **Scale horizontally** (add instances as load increases)
3. **Maintain statelessness** (any instance can handle any request)
4. **Minimize cold starts** (if using Lambda)
5. **Monitor resource utilization** (CPU, memory, disk)

**Compute Options Comparison**

| Option | Startup Time | Scalability | Cost | Ideal Use Case |
|--------|------------|-------------|------|-------------|
| **EC2** | Warm in minutes | Manual or ASG | Hourly | Baseline steady load |
| **Lambda** | Cold: 500-5000ms; Warm: <50ms | Auto (1000 concurrent soft limit) | Per request | Sporadic/variable load |
| **Fargate** | 30-60 seconds | Auto via ECS | Per second | Containerized, scaling |
| **EKS** | 1-2 minutes | Auto via HPA | Per second | Complex microservices |

**Key Metric**: Requests per instance varies wildly:
- Simple API (validation + cache): 100K RPS per instance
- Complex processing (ML inference, transformation): 1K RPS per instance
- CPU-bound workload: Limited by vCPU, not requests

#### Stateless Design

**Why Statelessness Matters**

```
Stateful (WRONG):
  ├─ User session stored in-memory on Instance A
  ├─ Request 1 → Instance A (success)
  ├─ Instance A crashes
  ├─ Request 2 → Instance B (session lost)
  └─ User must re-login

Stateless (CORRECT):
  ├─ Session stored in Redis (external)
  ├─ Request 1 → Instance A (retrieves session from Redis)
  ├─ Instance A crashes
  ├─ Request 2 → Instance B (retrieves same session from Redis)
  └─ User experience uninterrupted
```

**Statelessness Checklist**
```
✅ HTTP sessions stored in external cache (Redis, DynamoDB)
✅ No local file uploads (use S3/EFS)
✅ No in-memory queues (use SQS)
✅ No scheduled jobs in application (use Lambda + EventBridge)
✅ Instance can be killed at any time without data loss
✅ Any instance can handle any request
```

#### Autoscaling Mechanisms

**Metric-Based Autoscaling (Most Common)**
```
CloudWatch metric: Average CPU > 70%
├─ Trigger: True
├─ Add: 5 instances
├─ Cooldown: 300 seconds (wait before scaling again)
└─ New desired capacity: 130 + 5 = 135 instances

Timeline:
  T+0: 130 instances, 73% CPU
  T+1: Scale signal triggers
  T+2-5: New instances launch (2-5 min startup)
  T+7: New instances healthy, 100 instances now active
  T+10: 135 instances ready, CPU drops to 65%
  
Problem: Lag time means overload before scaling occurs
```

**Predictive Autoscaling (Newer)**
```
ML model observes patterns:
  ├─ 8 AM: CPU rises to 80% (morning peak)
  ├─ 6 PM: CPU rises to 85% (evening peak)
  ├─ Weekends: CPU stays at 50%

Predictive scaling proactively scales:
  ├─ 7:55 AM: Pre-scale to 140 instances (before peak)
  ├─ 8:00 AM: Peak hits 130 instances already running
  └─ 8:10 AM: CPU = 65% (smooth, no spike)

Benefit: Avoid overload during scaling lag
Cost: Additional charges for predictive scaling
```

**Lambda Autoscaling (Unique Challenges)**
```
Lambda soft limits:
  ├─ Concurrent executions: 1000 per account (default)
  ├─ Cold start: 500-5000ms for Python/Java
  ├─ Warm start: <50ms

13M RPS with Lambda:
  ├─ RPS / 50ms per request = 260K concurrent executions needed
  ├─ Soft limit=1000 means 13M RPS / 1000 = 13K per function
  └─ Need ~1000 functions or request limit increase

Alternative: API Gateway -> ECS/Fargate (better for high throughput)
```

#### Connection Pooling

**The Problem: Connection Exhaustion**
```
EC2 instance to RDS database:
  ├─ Max connections per instance: 100 (configured)
  ├─ Incoming requests: 100K RPS=
  ├─ Each request opens 1 DB connection
  │   └─ After 100ms: 100 connections used
  │   └─ After 200ms: 100 connections used (100 others waiting)
  │   └─ After 1 second: Queue = 900K pending requests
  │
  └─ Database hit by 100K concurrent connections
      (Database max = 600 connections; crashes)

Solution: Connection pooling
  ├─ Connection pool: 50 connections per instance
  ├─ Queue: 1000max request queue
  ├─ If queue full: Return 503 (Service Unavailable)
  └─ Requests wait for available connection; fail fast if queue full
```

**Connection Pooling Best Practices**
```
Max pool size = (RPS × DB operation latency) / 1000

Example:
  RPS per instance: 100K
  DB operation latency: 100ms
  
  Max pool size needed = (100K × 0.1s) / 1000 = 10 connections
  Actual setting = 10 × 2 = 20 (buffer for variability)
```

#### Spot Instances for Cost Optimization

**Spot Instances 101**
```
On-Demand: $1.00/hour
Spot Instance: $0.30/hour (70% cheaper!)

Tradeoff: AWS can interrupt with 2-minute warning

For 130 instances at $1/hour = $130/hour = $94K/month baseline
With 70% spot discount = $28K/month (66% savings)

Challenge: Interruption handling
  ├─ Set autoscaling termination policy: Oldest first
  ├─ New instances launch to replace interrupted ones
  └─ Microservice architecture needed (stateless)
```

**Hybrid Approach (Recommended for Steady + Burst)**
```
Baseline (On-Demand): 80 instances = always available
  └─ Cost: $80/hour

Burst capacity (Spot): 50 instances (only during peak)
  └─ Cost: $0.30 × 50 = $15/hour (during peak only)
  
Peak load distribution:
  ├─ Base load: 80 instances
  ├─ Predicted peak: +50 Spot instances
  └─ Unexpected spike: +30 On-Demand (emergency)

Monthly cost:
  ├─ On-Demand baseline: 80 × 24 × 30 = $57.6K
  ├─ Spot usage (peak 4hrs/day): 50 × 0.3 × 4 × 30 = $1.8K
  ├─ Emergency On-Demand (rare): ~$1K
  └─ **Total: ~$60K (vs. $94K all on-demand)**
```

#### Container Scheduling (ECS/EKS)

**ECS (Elastic Container Service)**
```
Simpler; AWS-managed
├─ EC2 launch type: Manage EC2 instances yourself
├─ Fargate launch type: AWS manages infrastructure
│   └─ Pay per vCPU-second (similar to Lambda pricing)
│
Ideal for:
  ├─ <1000 RPS per service (smaller scale)
  └─ Consistent workloads
```

**EKS (Kubernetes)**
```
Complex; industry standard
├─ Horizontal Pod Autoscaling (HPA)
├─ Advanced traffic routing (service mesh)
├─ Multi-cluster federation
│
Ideal for:
  ├─ >10K RPS (large scale)
  └─ Complex microservices
```

**For 13M RPS system**:
- If monolithic: EC2 with autoscaling
- If microservices: EKS with HPA + service mesh

#### DevOps Best Practices

**Practice 1: Blue-Green Deployments**
```
Blue (running): 100% of 13M RPS
Green (new version): 0% traffic

Deploy:
  ├─ Green launches with new code
  ├─ Health checks confirm green healthy
  ├─ Shift 100% traffic to green (atomic switch)
  └─ Roll back blue if issues

Downtime: 0 seconds
Rollback speed: < 1 minute
```

**Practice 2: Canary Deployments**
```
Stable version: 99% traffic (13M RPS)
Canary version: 1% traffic (130K RPS)

Monitor canary:
  ├─ Error rate: Should match stable (<0.1%)
  ├─ P99 latency: Should match stable (<1sec)
  └─ Custom metrics: Business-dependent

If good: Expand to 10%, 50%, 100%
If bad: Rollback immediately
```

**Practice 3: Graceful Shutdown**
```
Instance receiving termination notice (2-minute warning):
  ├─ Stop accepting NEW requests
  ├─ Wait for IN-FLIGHT requests to complete (max 30 sec)
  ├─ Close database connections gracefully
  └─ Terminate

Without graceful shutdown:
  ├─ In-flight requests killed abruptly
  └─ Database transactions left incomplete (data corruption possible)
```

#### Common Pitfalls

**Pitfall 1: Insufficient Connection Pooling**
```
Symptom: "Connection timeout" errors appearing randomly
Cause:
  ├─ Connection pool size = 5 (too small!)
  ├─ Request spike: 1000 concurrent requests
  └─ Queue fills; requests rejected

Solution: Set pool size = (average RPS × P99 latency) / 1000
          Formula: (100K × 0.1) / 1000 = 10, set to 20
```

**Pitfall 2: Monitoring Only CPU, Ignoring Memory**
```
Symptom: System crashes despite CPU 30%
Cause:
  ├─ Memory leak in application
  ├─ Memory usage: 95% (4GB / 4.2GB)
  ├─ JVM can't allocate → OutOfMemory exception
  └─ Process crashes (CPU still low because crashed)

Solution: Monitor MEM %, disk I/O, request queue depth
          Set alerts at 70% utilization for graceful scaling
```

**Pitfall 3: Not Testing Scaling Speed**
```
Assumption: Autoscaling adds 10 instances/minute
Reality: Check actual launch time!
  ├─ AMI download: 30-60 seconds
  ├─ Instance boot: 20-30 seconds
  ├─ Application startup: 30-60 seconds
  ├─ Health check: 30 seconds
  └─ Total: 2-5 minutes per instance!
  
Impact: Peak arrives before scaling complete
Solution: Pre-warm; use predictive scaling
```

### Practical Code Examples

#### EC2 Launch Template with Autoscaling

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'High-throughput compute layer for 13M RPS'

Parameters:
  DesiredCapacity:
    Type: Number
    Default: 130

Resources:
  ComputeSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Allow ALB traffic
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          SourceSecurityGroupId: !Ref ALBSecurityGroup
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 10.0.0.0/16  # Internal only

  ComputeLaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateName: high-throughput-compute
      LaunchTemplateData:
        ImageId: ami-0c55b159cbfafe1f0  # Amazon Linux 2
        InstanceType: c5.4xlarge  # 16 vCPU, 32 GB RAM
        KeyName: !Ref KeyName
        EbsOptimized: true
        IamInstanceProfile:
          Arn: !GetAtt InstanceProfile.Arn
        SecurityGroupIds:
          - !Ref ComputeSecurityGroup
        BlockDeviceMappings:
          - DeviceName: '/dev/xvda'
            Ebs:
              VolumeSize: 100
              VolumeType: gp3
              Iops: 3000
              Throughput: 125
              DeleteOnTermination: true
        TagSpecifications:
          - ResourceType: instance
            Tags:
              - Key: Name
                Value: ComputeServer
              - Key: Environment
                Value: Production
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            set -ex
            
            # Update system
            yum update -y
            yum install -y docker amazon-cloudwatch-agent
            
            # Configure Docker
            systemctl enable docker
            systemctl start docker
            
            # Increase file descriptors (for MySQL connections)
            sysctl -w fs.file-max=2097152
            sysctl -w net.core.somaxconn=65535
            
            # Pull and run application
            docker login -u $AWS_ACCOUNT_ID -p $(aws ecr get-login-password --region ${AWS::Region}) ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com
            
            docker run -d \
              --name api-server \
              --restart unless-stopped \
              -p 8080:8080 \
              -e DATABASE_POOL_SIZE=20 \
              -e CACHE_CONNECTIONS=50 \
              -e JAVA_OPTS="-Xms24g -Xmx24g -XX:+UseG1GC" \
              ${AWS::AccountId}.dkr.ecr.${AWS::Region}.amazonaws.com/api-service:latest
            
            # CloudWatch agent
            cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'EOF'
            {
              "agent": {"metrics_collection_interval": 60},
              "metrics": {
                "namespace": "ComputeLayer",
                "metrics_collected": {
                  "cpu": {
                    "measurement": [{"name": "cpu_usage_active"}],
                    "metrics_collection_interval": 60,
                    "totalcpu": true
                  },
                  "mem": {
                    "measurement": [{"name": "mem_used_percent"}],
                    "metrics_collection_interval": 60
                  },
                  "disk": {
                    "measurement": [{"name": "used_percent"}],
                    "metrics_collection_interval": 60,
                    "resources": ["/"]
                  },
                  "netstat": {
                    "measurement": [
                      {"name": "tcp_established"},
                      {"name": "tcp_time_wait"}
                    ],
                    "metrics_collection_interval": 60
                  }
                }
              }
            }
            EOF
            
            /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
              -a fetch-config \
              -m ec2 \
              -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json \
              -s

  ComputeAutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: compute-asg
      LaunchTemplate:
        LaunchTemplateId: !Ref ComputeLaunchTemplate
        Version: !GetAtt ComputeLaunchTemplate.LatestVersionNumber
      MinSize: 100
      MaxSize: 300
      DesiredCapacity: !Ref DesiredCapacity
      VPCZoneIdentifier:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3
      TargetGroupARNs:
        - !GetAtt TargetGroup.TargetGroupArn
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300
      TerminationPolicies:
        - OldestInstance
        - OldestLaunchTemplate
      VPCZoneIdentifier:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3
      MetricsCollection:
        - Granularity: 1Minute

  # TargetTracking: Scale based on CPU
  ScalePolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref ComputeAutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70.0
        ScaleOutCooldown: 60
        ScaleInCooldown: 300

  # Custom metric: Scale based on request queue depth
  QueueDepthPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AutoScalingGroupName: !Ref ComputeAutoScalingGroup
      PolicyType: TargetTrackingScaling
      TargetTrackingConfiguration:
        CustomizedMetricSpecification:
          MetricName: TargetResponseTime
          Namespace: AWS/ApplicationELB
          Statistic: Average
          Unit: Milliseconds
        TargetValue: 100  # Target P50 latency
        ScaleOutCooldown: 30
        ScaleInCooldown: 300

  # Lifecycle hook for graceful shutdown
  TerminationHook:
    Type: AWS::AutoScaling::LifecycleHook
    Properties:
      AutoScalingGroupName: !Ref ComputeAutoScalingGroup
      LifecycleTransition: autoscaling:EC2_INSTANCE_TERMINATING
      DefaultResult: CONTINUE
      HeartbeatTimeout: 300
      NotificationTargetARN: !Ref SNSTopic
      RoleARN: !GetAtt LifecycleRole.Arn

Outputs:
  AutoScalingGroupName:
    Value: !Ref ComputeAutoScalingGroup
  
  LaunchTemplateId:
    Value: !Ref ComputeLaunchTemplate
```

#### graceful Shutdown Handler (Python)

```python
import signal
import sys
import time
import threading
from flask import Flask, jsonify
from waitress import serve
from threading import Event

app = Flask(__name__)
shutdown_event = Event()
active_requests = 0
active_requests_lock = threading.Lock()

def handle_shutdown_signal(sig, frame):
    """Handle SIGTERM for graceful shutdown"""
    global active_requests
    
    print("["Shutdown signal received. No longer accepting requests...")
    shutdown_event.set()
    
    # Wait for in-flight requests to complete (max 30 seconds)
    shutdown_start = time.time()
    while active_requests > 0 and time.time() - shutdown_start < 30:
        print(f"[{active_requests} active requests, waiting...")
        time.sleep(1)
    
    print("Shutting down...")
    sys.exit(0)

# Register signal handlers
signal.signal(signal.SIGTERM, handle_shutdown_signal)
signal.signal(signal.SIGINT, handle_shutdown_signal)

@app.before_request
def check_shutdown():
    """Reject new requests during shutdown"""
    if shutdown_event.is_set():
        return jsonify(error="Server shutting down"), 503

@app.before_request
def track_request_start():
    """Increment active request counter"""
    global active_requests
    with active_requests_lock:
        active_requests += 1

@app.teardown_request
def track_request_end(exception):
    """Decrement active request counter"""
    global active_requests
    with active_requests_lock:
        active_requests -= 1

@app.route('/api/data', methods=['GET'])
def get_data():
    """Slow operation to simulate real-world request"""
    time.sleep(0.1)  # Simulate DB query
    return jsonify(data="Hello World")

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    if shutdown_event.is_set():
        return jsonify(status="shutting_down"), 503
    return jsonify(status="healthy")

if __name__ == '__main__':
    # Run with Waitress for production
    serve(app, host='0.0.0.0', port=8080, threads=100)
```

### ASCII Diagrams

#### Autoscaling Timeline
```
AUTOSCALING RESPONSE TIME
═════════════════════════════════════════════════════════════

T=0:00  Traffic spikes: 120 instances, CPU = 73%
        └─ Scale-up threshold (70%) exceeded

T=0:00-0:01  Metrics evaluated; scale trigger fires
            └─ Add 5 new instances

T=0:01-0:05  EC2 instances launching
            ├─ AMI download: 1 min
            ├─ Instance boot: 0.5 min
            ├─ Application start: 0.5 min
            └─ Health check green: 0.5 min

T=0:05      5 new instances online
            └─ 125 instances active

T=0:06      Still at 71% CPU; next scale fires
            └─ Add 5 more instances

T=0:10      130 instances now online
            └─ CPU drops to 65%

Result: ~10 minute lag from spike detection to recovery
        Users see elevated latency during 0:00-0:05 window

Solution: Predictive scaling (pre-scale before spike)
          or On-Demand + Spot hybrid (capacity ready)
```

---

## 6. Caching Layer

### Textual Deep Dive

#### Internal Working Mechanism

Caching is your second line of defense (after CloudFront at the edge). At 1 million concurrent users, the cache layer must:

1. **Store hot data** in-memory for sub-1ms access
2. **Survive instance failures** (distributed cache, not local)
3. **Manage eviction** when memory approaches limits
4. **Maintain freshness** through TTL and invalidation

**Cache Math at 1M Users**
```
Database capacity: 100K RPS
Without cache: 13M RPS → database → overload
Cache hit rate: 95% → 12.35M RPS served from cache
Database load: 650K RPS (5% miss rate) → still 6.5x over capacity!

Need larger cache or sharding:
  ├─ Cache hit rate 99%: 130K RPS to DB (acceptable)
  ├─ Cache hit rate 98%: 260K RPS to DB (acceptable)
  └─ Measure actual hit rate; adjust TTL/strategy accordingly
```

#### ElastiCache (Redis vs. Memcached)

**Redis**
```
Data structures: Strings, Lists, Sets, Sorted Sets, Hashes, Streams
Persistence: RDB snapshots, AOF (append-only file)
Replication: Synchronous (across AZs)
Throughput: ~200K ops/sec per r6g.xlarge node
TTL: Supported (per-key or global)
Use cases:
  ├─ Session storage (user contexts, auth tokens)
  ├─ Leaderboards (sorted sets = fast ranking)
  ├─ Pub/Sub messaging
  └─ Rate limiting (increment counter, expiry)
```

**Memcached**
```
Data structures: Strings only (simple key-value)
Persistence: None (in-memory only; restart = data loss)
Replication: None (horizontal sharding via client)
Throughput: ~300K ops/sec per cache.r6g.xlarge node
TTL: Supported (server-side)
Use cases:
  ├─ Session cache (not critical)
  ├─ Object cache (calculated values)
  ├─ Computed results
  └─ Temporary data
```

**For 13M RPS System**: Redis recommended due to persistence and pub/sub.

#### Cache Patterns

**Pattern 1: Cache-Aside (Most Common)**
```
Application needs data:
  ├─ Check cache first
  │   └─ CACHE HIT: Return immediately (1ms)
  │
  └─ Cache miss: Fetch from database
      ├─ Write to cache (set with TTL)
      └─ Return to application (100ms)

Advantage: Simple; no cache invalidation complexity
Disadvantage: Cache misses always slow; cold cache on restart

Implementation:
  get(key):
    value = redis.get(key)
    if value is None:
      value = database.query(key)
      redis.set(key, value, ex=3600)  # 1-hour TTL
    return value
```

**Pattern 2: Write-Through**
```
Application writes data:
  ├─ Write to CACHE
  └─ Write to DATABASE (in parallel or serial)

Advantage: Cache always fresh; reads are fast
Disadvantage: Slower writes (must wait for both stores)
             Cache failure = write failure

Implementation:
  set(key, value):
    redis.set(key, value)  # Cache write
    database.insert(key, value)  # DB write
    if database.insert fails:
      redis.delete(key)  # Rollback cache
```

**Pattern 3: Write-Back (Dangerous)**
```
Application writes data:
  ├─ Write to CACHE only
  └─ Asynchronously flush to DATABASE

Advantage: Fastest writes (1ms)
Disadvantage: Data loss if cache dies before flush
             Stale data possible

Use case: Analytics; non-critical data (like likes/views)
NOT for: Transactions, financial data, user-critical data
```

#### Eviction Policies

When ElastiCache reaches memory limit, it evicts entries:

```
LRU (Least Recently Used) - Default
  Evict: Key not accessed recent = deleted first
  Benefit: Keep hot keys
  Example: User 1 (accessed 5 min ago) → Evicted
           User 2 (accessed 30 sec ago) → Kept

LFU (Least Frequently Used)
  Evict: Key accessed least times = deleted first
  Benefit: Keep frequently accessed
  Example: Popular course (1000 accesses) → Kept
           Niche course (10 accesses) → Evicted

FIFO (First In First Out)
  Evict: Oldest entry deleted
  Benefit: Predictable; simple
  Example: Batch processing queue
```

#### DevOps Best Practices

**Practice 1: Monitor Cache Metrics**
```
Key metrics to track:
  ├─ Cache hit ratio (target: >95%)
  │   └─ If <80%: TTL too short or cache undersized
  │
  ├─ Evictions per second
  │   └─ If >0: Cache is full; scale up nodes
  │
  ├─ Network bytes in/out
  │   └─ If high: Might indicate large values (optimize data structure)
  │
  └─ CPU utilization
      └─ If >80%: Scale up instance size or add nodes

Alert thresholds:
  ├─ Hit ratio < 85% for 5 min → page on-call
  ├─ Evictions > 100/sec → page on-call
  └─ CPU > 80% for 10 min → auto-scale up
```

**Practice 2: Cluster Mode for Sharding**
```
Single node:
  └─ 200K ops/sec capacity
  └─ Single-node failure = cache miss storm

Cluster mode (10 shards):
  ├─ Shard 1: Keys 0-99999...
  ├─ Shard 2: Keys 100000-199999...
  └─ ... 10 shards total
  └─ 2M ops/sec capacity (10× throughput)
  └─ Automatic failover per shard

Implementation:
  redis.set("user_123", data)
  Client hashes "user_123" → shard 4
  Send request to shard 4 replica
```

**Practice 3: Cache Warming**
```
On application startup:
  ├─ Load frequently accessed data into cache
  │   └─ Top 1000 users
  │   └─ Configuration data
  │
  └─ Benefit: No cold cache on restart

Without warming:
  Day 1 after restart: Hit ratio 5% (cold cache)
    └─ Database overloaded; users see slowness
  Day 2 after restart: Hit ratio 95% (warm cache)
    └─ Database normal; users happy

With warming:
  Day 1 after restart: Hit ratio 90% (pre-warmed)
    └─ Minimal impact
```

#### Common Pitfalls

**Pitfall 1: Cache Stampede (Thundering Herd)**
```
Popular key expires:
  ├─ 1000 concurrent requests all check cache
  ├─ All get cache miss
  ├─ All try to fetch from database
  └─ Database hit with 1000 simultaneous queries (overload!)

Solution 1: Use cache-with-lock pattern
  First thread acquires lock, fetches DB
  Other 999 threads wait for lock
  All 1000 threads get same result from cache

Solution 2: Use stale-while-revalidate
  Return 1-second-old value while fetching fresh data asynchronously
  Users see slightly stale data (acceptable for many use cases)
```

**Pitfall 2: Forgotten Invalidation**
```
Scenario:
  ├─ User profile cached: name_123 = "Alice"
  ├─ User updates: name_123 = "Alice Smith"
  ├─ Database updated
  ├─ Cache still shows: "Alice" (stale!)
  └─ User sees old name (confusing)

Solution:
  On data update:
    ├─ Update database
    ├─ Invalidate cache (redis.delete(key))
    └─ Next request refills cache with fresh data

Cost: Delete faster than update; safer
```

**Pitfall 3: Serialization Overhead**
```
Bad: Cache large JSON strings (1MB each)
  ├─ Serialization: 10ms
  ├─ Network: 50ms
  ├─ Deserialization: 5ms
  └─ Total: 65ms (not much faster than DB query!)

Good: Cache smaller relevant fields (10KB)
  ├─ Serialization: 1ms
  ├─ Network: 5ms
  ├─ Deserialization: 0.5ms
  └─ Total: 6.5ms (10x faster!)

Lesson: Cache what's needed, not everything
```

### Practical Code Examples

#### ElastiCache CloudFormation

```yaml
Resources:
  CacheSubnetGroup:
    Type: AWS::ElastiCache::SubnetGroup
    Properties:
      Description: Subnet group for Redis
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3

  RedisCluster:
    Type: AWS::ElastiCache::ReplicationGroup
    Properties:
      ReplicationGroupDescription: Cache for 1M users
      Engine: redis
      EngineVersion: '7.0'
      CacheNodeType: cache.r6g.xlarge
      NumCacheClusters: 3  # Primary + 2 replicas
      AutomaticFailoverEnabled: true
      MultiAZEnabled: true
      AtRestEncryptionEnabled: true
      TransitEncryptionEnabled: true
      CacheSubnetGroupName: !Ref CacheSubnetGroup
      LogDeliveryConfigurations:
        - DestinationType: cloudwatch-logs
          LogFormat: json
          LogType: slow-log
      Tags:
        - Key: Name
          Value: ProductionCache
```

#### Cache-Aside Pattern (Python)

```python
import redis
import json
from typing import Optional

class CachedDatabase:
    def __init__(self, redis_client: redis.Redis, db_client):
        self.redis = redis_client
        self.db = db_client
        self.default_ttl = 3600  # 1 hour
    
    def get_user(self, user_id: int) -> Optional[dict]:
        """Get user with cache-aside pattern"""
        cache_key = f"user_{user_id}"
        
        # Try cache first
        cached_value = self.redis.get(cache_key)
        if cached_value:
            return json.loads(cached_value)
        
        # Cache miss: fetch from database
        user = self.db.query("SELECT * FROM users WHERE id = ?", user_id)
        if user:
            # Write to cache
            self.redis.setex(
                cache_key,
                self.default_ttl,
                json.dumps(user)
            )
        
        return user
    
    def update_user(self, user_id: int, data: dict) -> bool:
        """Update user and invalidate cache"""
        # Update database
        success = self.db.update("users", user_id, data)
        
        if success:
            # Invalidate cache
            cache_key = f"user_{user_id}"
            self.redis.delete(cache_key)
        
        return success
    
    def get_with_lock(self, user_id: int) -> Optional[dict]:
        """Get user with lock to prevent thundering herd"""
        cache_key = f"user_{user_id}"
        lock_key = f"lock_{user_id}"
        
        # Try cache
        cached_value = self.redis.get(cache_key)
        if cached_value:
            return json.loads(cached_value)
        
        # Try to acquire lock
        if self.redis.set(lock_key, "1", ex=5, nx=True):
            try:
                # This thread fetches DB
                user = self.db.query("SELECT * FROM users WHERE id = ?", user_id)
                if user:
                    self.redis.setex(cache_key, self.default_ttl, json.dumps(user))
                return user
            finally:
                self.redis.delete(lock_key)
        else:
            # Another thread is fetching; wait and retry
            import time
            for _ in range(50):  # Wait up to 5 seconds
                time.sleep(0.1)
                cached_value = self.redis.get(cache_key)
                if cached_value:
                    return json.loads(cached_value)
            
            # Fallback to direct DB query
            return self.db.query("SELECT * FROM users WHERE id = ?", user_id)
```

### ASCII Diagrams

#### Cache Topology for 1M Users
```
ELASTICACHE CLUSTER FOR 13M RPS
═════════════════════════════════════════════════════════════

Primary Node                 Replica 1              Replica 2
(us-east-1a)               (us-east-1b)           (us-east-1c)
                                                  
200K ops/sec          200K ops/sec          200K ops/sec
100% writes from      Read from              Read from
application           app (failover)         app (failover)

    ↑ Sync replication
    │ (every update)
    ├──→ Replica 1 (100ms replication lag)
    ├──→ Replica 2 (100ms replication lag)

Cluster Mode (Sharded):
═════════════════════════════════════════════════════════════

Shard 1 (Keys 0-999999)
├─ Primary: 200K ops/sec
└─ Replica: 200K ops/sec

Shard 2 (Keys 1000000-1999999)
├─ Primary: 200K ops/sec
├─ Replica: 200K ops/sec

... (10 shards total)

Total capacity: 2M ops/sec (10x single node)
Failure impact: Only 1 shard affected (10% of traffic)
```

---

## 7. Database Layer

### Textual Deep Dive

#### Internal Working Mechanism

The database layer is the source of truth for your system. At 1 million concurrent users with 13M RPS, the database must:

1. **Handle read throughput** (12.35M RPS reads)
2. **Maintain write consistency** (650K RPS writes)
3. **Replicate reliably** (zero data loss)
4. **Query efficiently** (sub-100ms P99 latency)
5. **Scale horizontally** (sharding for writes, replicas for reads)

**Database Capacity Challenge**
```
Single RDS instance: 100K RPS capacity maximum
System needs: 12.35M reads + 650K writes = 12.98M ops/sec
Ratio: 12.98M / 100K = 130x over single instance capacity

Solutions:
  ├─ Read replicas (scale reads horizontally)
  ├─ Sharding (scale writes)
  └─ DynamoDB (no operational overhead; scales automatically)
```

#### RDS (Relational Database Service) vs. DynamoDB

**RDS (MySQL, PostgreSQL)**
```
Strengths:
  ├─ ACID transactions (strong consistency)
  ├─ Complex queries (JOINs, aggregations)
  ├─ Familiar SQL
  └─ Normalized data

Weaknesses:
  ├─ Scaling writes requires sharding (complex)
  ├─ Max ~100K RPS per instance
  ├─ Maintenance overhead
  └─ Scaling > 1TB requires partitioning

For 1M users: RDS + sharding for read-heavy, few writes scenarios
```

**DynamoDB (NoSQL)**
```
Strengths:
  ├─ Scales to unlimited throughput (auto-scales)
  ├─ Serverless (no instance management)
  ├─ Single-digit millisecond latency at scale
  ├─ Built-in replication (multi-AZ, multi-region)
  └─ Pay-per-request or provisioned capacity

Weaknesses:
  ├─ Eventually consistent (by default)
  ├─ No complex JOINs (denormalization needed)
  ├─ Item size limit: 400KB
  ├─ No transactions across tables (single table only)
  └─ Learning curve for key-value thinking

For 1M users: DynamoDB if eventual consistency acceptable
             RDS if strong consistency required
```

#### Read Replicas for Scaling Reads

**Architecture**
```
Primary database (writes): 650K RPS writes
                           ├─ Sync replication (100ms lag)
                           │
Read Replica 1: 2M RPS reads
Read Replica 2: 2M RPS reads
Read Replica 3: 2M RPS reads
Read Replica 4: 2M RPS reads
... (7 total read replicas)

Total read capacity: 14M RPS (covers 12.35M RPS need)
Read distribution: Round-robin across replicas
```

**Challenges**
```
Replication lag: Primary → Replica takes 100-500ms
  ├─ During lag, replica shows stale data
  ├─ User reads data; cache saves it
  ├─ If reads own data immediately, sees stale value
  │
  └─ Solution: Read-after-write consistency
      ├─ Writes go to primary
      ├─ Next read for same user goes to primary (not replica)
      ├─ Subsequent reads go to replicas
      └─ Ensures users always see their own changes

Example (E-commerce):
  ├─ User updates profile: "email@newdomain.com"
  ├─ Database: Primary updated, replicas lag 200ms
  ├─ User searches for themselves
  ├─ Must query primary (replicas show old email)
  └─ Cost: Extra primary load during lag window
```

#### Sharding for Write Scaling

**Sharding Strategy**
```
Single database can't handle 650K RPS writes
Solution: Shard by user_id

Shard 1 (user_id % 10 == 0):
  ├─ Users: 0, 10, 20, 30, ...
  ├─ Load: 65K writes/sec
  └─ With replicas: 2M read capacity

Shard 2 (user_id % 10 == 1):
  ├─ Users: 1, 11, 21, 31, ...
  ├─ Load: 65K writes/sec

... (10 shards total)

Total: 10 shards × 100K capacity = 1M capacity >> 650K writes needed
```

**Sharding Challenges**
```
1. Cross-shard queries (expensive)
   Query: "Get all users with name='Alice'"
   ├─ Must query all 10 shards
   ├─ Combine results (might be thousands)
   └─ Higher latency than single-shard query

2. Hot shards (uneven load)
   ├─ Shard containing popular user gets 10x more traffic
   ├─ Single shard becomes bottleneck
   │
   └─ Solution: Monitor per-shard metrics; re-shard if needed

3. Data consistency (harder)
   Transaction across shards = distributed transaction
   └─ Multiple shards must commit atomically
   └─ Complex; slow (anti-pattern at scale)
```

#### Production Usage Patterns

**Pattern 1: OLTP (Online Transaction Processing)**
```
User-facing queries: Simple, fast
Examples:
  ├─ Get user profile (single query)
  ├─ Update user settings (single write)
  ├─ Check order status (single query)

Optimizations:
  ├─ Denormalize for speed (store fields together)
  ├─ Index heavily (search fields)
  ├─ Cache results
  └─ Database: Read replicas + sharding

Latency target: P99 < 100ms
```

**Pattern 2: OLAP (OnlineAnalytical Processing)**
```
Analytics queries: Complex, slow
Examples:
  ├─ "Revenue by region this quarter"
  ├─ "User retention over time"
  ├─ "Top products by views"

Challenge:
  ├─ Full-table scans
  ├─ Complex JOINs
  ├─ Aggregations across millions of rows
  └─ Would block user-facing queries if run on primary

Solution: Data warehouse (Redshift)
  ├─ Star schema (fact/dimension tables)
  ├─ Columnar storage (compress; fast aggregations)
  ├─ Separate from OLTP database
  └─ Batch ETL pipeline copies data nightly
```

**Pattern 3: Time-Series Data**
```
Examples:
  ├─ User activity timestamps
  ├─ Server metrics (CPU, memory)
  ├─ Trading prices

Characteristics:
  ├─ Immutable (once written, not updated)
  ├─ Append-only
  ├─ Queried by time range
  └─ High volume (100M+ events/day)

Storage:
  ├─ Not RDS (too slow for billion rows)
  ├─ Not DynamoDB (expensive for long-term)
  └─ Best: ElasticSearch, InfluxDB, or time-series database

Query example:
  "Give me all user logins between 2024-01-01 and 2024-01-31"
  → Time-series DB can answer in 100ms
  → RDS would take 1+ minute (full table scan)
```

#### DevOps Best Practices

**Practice 1: Query Performance Monitoring**
```
Enable slow query logs:
  ├─ Log all queries taking > 100ms
  ├─ Examples:
  │   └─ SELECT * FROM users WHERE name LIKE '%foo%' (no index!)
  │   └─ Complex JOIN without proper indexes
  │   └─ Implicit type conversion
  │
  └─ Action: Add index or rewrite query

For 13M RPS system:
  ├─ Expect 10K slow queries per second (healthy)
  ├─ Alert if > 100K slow queries per second (investigate)
  └─ Most cause: Missing index or inefficient subquery
```

**Practice 2: Automated Backups & Point-in-Time Recovery**
```
RDS backup strategy:
  ├─ Daily snapshots (incremental after first)
  ├─ Retention: 35 days (AWS default)
  ├─ Automated backups enable PITR
  │   └─ Recover database to any second in past 35 days
  │
  └─ Cost: ~1% of instance cost (negligible)

Recovery time (RTO):
  ├─ Snapshot restore: 5-15 minutes
  ├─ PITR from backup:10-20 minutes
  └─ Acceptable for most systems
```

**Practice 3: Parameter Groups for Tuning**
```
Key parameters for MySQL under heavy load:

max_connections = 1000 (default 100)
  └─ Allows 1000 concurrent connections

innodb_buffer_pool_size = 24GB (for 32GB instance)
  └─ Cache table data; reduces disk I/O

innodb_log_file_size = 2GB
  └─ Write-ahead log; larger = better throughput, longer recovery

slow_query_log = 1
  └─ Log all queries > long_query_time (set to 100ms)

Query cache OFF (MySQL 5.7+)
  ├─ Cache invalidated on every write
  └─ Not worth overhead at scale

Monitor:
  ├─ Connections: Should be <50% of max
  ├─ Buffer pool hit ratio: Should be >95%
  └─ Slow queries: Should be minimal
```

#### Common Pitfalls

**Pitfall 1: N+1 Query Problem**
```
Symptom: Database CPU 100% despite < 10K RPS
Cause:
  ├─ Retrieve 1000 users
  ├─ For each user, fetch their orders (1000 queries!)
  ├─ Total: 1 + 1000 = 1001 database roundtrips
  │
  └─ In Python:
      users = db.query("SELECT * FROM users LIMIT 1000")
      for user in users:
          orders = db.query("SELECT * FROM orders WHERE user_id = ?", user.id)
          # Process orders

Solution:
  ├─ Use JOINs in SQL
  └─ Or: Load users, then n bulk load all orders in 1 query
      
      users = db.query("SELECT * FROM users LIMIT 1000")
      user_ids = [u.id for u in users]
      orders = db.query("SELECT * FROM orders WHERE user_id IN (...)", user_ids)
```

**Pitfall 2: Forgetting to Index**
```
Symptom: Query response time: 5 seconds (for simple operation)
Cause:
  Query: SELECT * FROM users WHERE email = 'user@example.com'
  └─ Full table scan (1B rows) = slow!

Fix:
  CREATE INDEX idx_users_email ON users(email);
  └─ Query time: 1ms (index lookup)

For 1M users: Index all frequently searched fields
  ├─ user_id (primary key - automatic)
  ├─ email (login queries)
  ├─ created_at (time-range queries)
  └─ status (filtering)

Cost: Index space (~1B rows × 20 bytes = 20GB)
     is worth the speed

Rule: If a column is in WHERE clause; index it
```

**Pitfall 3: No Monitoring of Replica Lag**
```
Symptom: Random "stale data" reports from users
Cause:
  Replica lag: Primary updated; replica hasn't replicated yet
  
  Timeline:
    ├─ T=0: Write to primary
    ├─ T=100ms: Replica still syncing
    ├─ T=100ms: Read request hits replica (stale!)
    ├─ T=200ms: Replica finally synced
    └─ T=200ms: Next read gets fresh data

Solution:
  Monitor replication lag continuously
  └─ Alert if lag > 1 second
  
  Implement read-after-write consistency
  └─ Writes go to primary; next read for that user also from primary
```

### Practical Code Examples

#### RDS Sharding Docker Compose

```yaml
version: '3.8'
services:
  # Primary database
  mysql-shard-0:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: app_shard_0
    ports:
      - "3306:3306"
    volumes:
      - shard0_data:/var/lib/mysql
    command: --max_connections=1000 --innodb_buffer_pool_size=4G

  mysql-shard-1:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: app_shard_1
    ports:
      - "3307:3306"
    volumes:
      - shard1_data:/var/lib/mysql

  # Read replica for shard 0
  mysql-shard-0-replica:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root123
    ports:
      - "3308:3306"
    volumes:
      - shard0_replica_data:/var/lib/mysql
    depends_on:
      - mysql-shard-0

volumes:
  shard0_data:
  shard1_data:
  shard0_replica_data:
```

#### Python Database Router with Sharding

```python
import hashlib
import mysql.connector
from typing import Dict, List

class ShardedDatabase:
    def __init__(self, num_shards=10):
        self.num_shards = num_shards
        self.connections: Dict[int, mysql.connector.MySQLConnection] = {}
        
        # Initialize connections to all shards
        for shard_id in range(num_shards):
            self.connections[shard_id] = mysql.connector.connect(
                host=f"shard-{shard_id}",
                user="root",
                password="root123",
                database=f"app_shard_{shard_id}"
            )
    
    def get_shard_id(self, user_id: int) -> int:
        """Determine which shard a user belongs to"""
        return user_id % self.num_shards
    
    def insert_user(self, user_id: int, name: str, email: str):
        """Insert user into correct shard"""
        shard_id = self.get_shard_id(user_id)
        conn = self.connections[shard_id]
        
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO users (id, name, email) VALUES (%s, %s, %s)",
            (user_id, name, email)
        )
        conn.commit()
        cursor.close()
    
    def get_user(self, user_id: int) -> Dict:
        """Retrieve user from correct shard"""
        shard_id = self.get_shard_id(user_id)
        conn = self.connections[shard_id]
        
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT * FROM users WHERE id = %s",
            (user_id,)
        )
        result = cursor.fetchone()
        cursor.close()
        
        return result
    
    def cross_shard_query(self, query_template: str) -> List[Dict]:
        """Execute query on all shards; combine results"""
        results = []
        
        for shard_id in range(self.num_shards):
            conn = self.connections[shard_id]
            cursor = conn.cursor(dictionary=True)
            
            # Execute same query on each shard
            cursor.execute(query_template)
            results.extend(cursor.fetchall())
            cursor.close()
        
        return results
    
    def get_all_users_by_name(self, name: str) -> List[Dict]:
        """Find all users with given name (cross-shard query)"""
        query = f"SELECT * FROM users WHERE name = '{name}'"
        return self.cross_shard_query(query)

# Usage
db = ShardedDatabase(num_shards=10)

# Write to appropriate shard
db.insert_user(user_id=123, name="Alice", email="alice@example.com")

# Read from appropriate shard (fast)
user = db.get_user(user_id=123)
print(user)

# Cross-shard query (slow, hits all 10 shards)
users_named_alice = db.get_all_users_by_name("Alice")
print(f"Found {len(users_named_alice)} users named Alice")
```

### ASCII Diagrams

#### Database Scaling Strategy
```
SCALING READS AND WRITES AT 1M USERS
═════════════════════════════════════════════════════════════

System Load: 12.98M RPS
├─ 12.35M RPS reads
└─ 650K RPS writes

SCALING READS (Read Replicas):
═════════════════════════════════════════════════════════════

Primary Database              Read Replicas
(Write: 650K RPS)            (Read: 2M each)
                |
                ├─→ Replica 1 (2M RPS)
                ├─→ Replica 2 (2M RPS)
                ├─→ Replica 3 (2M RPS)
                ├─→ Replica 4 (2M RPS)
                ├─→ Replica 5 (2M RPS)
                ├─→ Replica 6 (2M RPS)
                ├─→ Replica 7 (2M RPS)
                └─→ Replica 8 (2M RPS)

Total read capacity: 16M RPS (covers 12.35M RPS demand)


SCALING WRITES (Sharding):
═════════════════════════════════════════════════════════════

Application Router
        |
        └─→ Shard 0 (65K writes/sec) ─→ Replica 0
        └─→ Shard 1 (65K writes/sec) ─→ Replica 1
        └─→ Shard 2 (65K writes/sec) ─→ Replica 2
        ... (10 shards total)
        └─→ Shard 9 (65K writes/sec) ─→ Replica 9

Routing Logic: user_id % 10 determines shard

Total write capacity: 10 shards × 100K = 1M (covers 650K demand)
```

---

## 8. Asynchronous Processing Layer

### Textual Deep Dive

#### Internal Working Mechanism

Asynchronous processing decouples time-sensitive operations from expensive background tasks. At 1 million concurrent users, async processing:

1. **Avoids blocking users** while expensive tasks run
2. **Scales independent services** (email, analytics, notifications)
3. **Handles failures gracefully** (failed tasks retry)
4. **Distributes work** across multiple workers

**Why Async Matters at 1M Users**
```
Synchronous (BAD):
  User hits "submit order" button
  ├─ Insert into database (10ms)
  ├─ Send confirmation email (1000ms) ← BLOCKS USER!
  ├─ Update inventory (20ms)
  ├─ Log analytics (100ms)
  ├─ Charge credit card (500ms)
  └─ Return response (1630ms total)

  1M users × 1630ms = 1.63M seconds = 4600 hours = impossible!

Asynchronous (GOOD):
  User hits "submit order" button
  ├─ Insert into database (10ms)
  ├─ Publish "order.created" event to SQS
  └─ Return response to user (10ms) ← immediate!

  Background workers:
  ├─ Worker 1: Send email (async, 1000ms/order)
  ├─ Worker 2: Update inventory (async, 20ms/order)
  ├─ Worker 3: Log analytics (async, 100ms/order)
  ├─ Worker 4: Charge card (async, 500ms/order)

  Total user wait: 10ms (vs 1630ms)
  Workers handle backlog independently
```

#### SQS (Simple Queue Service)

**Architecture**
```
SQS queue: FIFO (first-in-first-out)
Features:
  ├─ Throughput: 3000 messages/sec per queue (with batch)
  ├─ Latency: Sub-millisecond delivery
  ├─ Durability: 3 replicas across AZs
  ├─ Auto-scaling: Add queues for higher throughput
  │
  └─ Limitations:
      ├─ Message size: 256 KB max (use S3 for large payloads)
      ├─ Retention: 4 days default (14 days max)
      └─ Visibility timeout: 30 seconds default (set based on worker time)
```

**Example: Order Processing**
```
Order received from user
  ├─ SQS message: {"order_id": 123, "user_id": 456}
  └─ Sent to "orders" queue

Order workers (EC2/Lambda)
  ├─ Poll SQS every 1 second
  ├─ Consume up to 10 messages per poll
  ├─ Process order (email, inventory, payment)
  └─ Delete message when complete

If worker fails:
  ├─ Message visibility expires (after 30 sec)
  └─ Message becomes available again for retry
```

**Scaling with SQS**
```
Max throughput per queue: 3000 msg/sec

For 650K writes/sec (orders):
  Queues needed: 650K / 3K = 217 queues

Or: Use SQS FIFO with sharding:
  ├─ Queue 0: Orders for user shards 0-99
  ├─ Queue 1: Orders for user shards 100-199
  └─ ... 217 queues with sharding key partitioning
```

#### SNS (Simple Notification Service)

**Publisher-Subscriber Pattern**
```
One event published to SNS topic
  ├─ Order.created event published
  │
  └─→ Fan-out to multiple subscribers:
      ├─ Email service subscribes (gets copy of event)
      ├─ Inventory service subscribes (gets copy)
      ├─ Analytics service subscribes (gets copy)
      └─ Notification service subscribes (gets copy)

Advantage: One publish; many subscribers (loose coupling)
Disadvantage: Eventual consistency (subscribers process at different speeds)
```

#### EventBridge (Advanced)

**Event-Driven Architecture**
```
EventBridge allows:
  ├─ Complex routing rules (route based on event content)
  ├─ Multiple targets (cross-service events)
  ├─ Dead-letter queues (failed events)
  ├─ Retry policies (exponential backoff)
  └─ Time-based triggers (scheduled tasks)

Example rule:
  IF event.type == "order.created" AND amount > $1000
  THEN
    ├─ Invoke fraud-detection Lambda
    ├─ Send SNS alert
    └─ Call third-party fraud API
```

#### DevOps Best Practices

**Practice 1: Dead-Letter Queues (DLQ)**
```
Normal flow:
  Order message → SQS queue → Worker processes → Success

Failure flow:
  Order message → SQS queue → Worker fails
                             ├─ Retry 1 (fail)
                             ├─ Retry 2 (fail)
                             ├─ Retry 3 (fail)
                             └─ Move to DLQ

DLQ analysis:
  ├─ Review why messages failed
  ├─ Fix code/data
  ├─ Manually replay from DLQ if needed

Without DLQ: Failed messages lost forever (data loss)
```

**Practice 2: Visibility Timeout**
```
Message visibility timeout = max time to process
  Default: 30 seconds
  
If worker takes > timeout:
  ├─ Message becomes visible again (other workers process it too!)
  └─ Duplicate processing (bad)

Setting: visibility_timeout = 2 × max_expected_processing_time

Example: Email sending takes max 5 seconds
  Timeout = 2 × 5 = 10 seconds
```

**Practice 3: Idempotent Processing**
```
Challenge:
  Worker A processes order 123
    ├─ Sends email
    ├─ Updates inventory
    ├─ Crashes before deleting SQS message

  Worker B gets same message
    ├─ Sends email AGAIN (duplicate!)
    └─ Updates inventory AGAIN (wrong count)

Solution: Idempotent processing
  ├─ Process same message twice = same result
  ├─ Track processed messages: redis.set(f"processed_{order_id}", 1)
  ├─ On retry: Check if already processed
  └─ If yes: Skip; just delete message

Example:
  if redis.get(f"processed_{order_id}"):
      sqs.delete_message(order_message)  # Skip; already done
  else:
      process_order(order_id)
      redis.set(f"processed_{order_id}", 1)
      sqs.delete_message(order_message)
```

#### Common Pitfalls

**Pitfall 1: No Dead-Letter Queue**
```
Messages keep failing
  └─ Retry 3 times (built-in)
  └─ Message disappears (silently lost!)
  
  No visibility into failures:
    └─ Can't debug; can't recover

Setup DLQ:
  └─ Failed messages move to DQL
  └─ Can inspect, debug, replay
```

**Pitfall 2: Not setting visibility timeout correctly**
```
Email sending takes 30 seconds randomly
  └─ Visibility timeout: 10 seconds (too short!)
  
  On slow sends:
    ├─ Message visible after 10 seconds
    ├─ Another worker picks it up
    ├─ Both workers send email (duplicate to user!)
    └─ Complaints increase
```

**Pitfall 3: Not idempotent**
```
Charge credit card twice for same order
  ├─ User annoyed
  ├─ Refund process
  ├─ Support tickets surge
  ├─ Revenue impact (refund fees)

Prevention: Track processed order IDs
  └─ Second attempt skips charge; deletes message
```

### Practical Code Examples

#### SQS Order Processing (Python)

```python
import json
import boto3
import time
from datetime import datetime

sqs = boto3.client('sqs')
redis_client = redis.Redis(host='localhost', port=6379)

QUEUE_URL = 'https://sqs.us-east-1.amazonaws.com/123456/orders'
DLQ_URL = 'https://sqs.us-east-1.amazonaws.com/123456/orders-dlq'

def process_order_worker():
    """Worker process that consumes messages from SQS"""
    
    while True:
        try:
            # Receive batch of messages
            response = sqs.receive_message(
                QueueUrl=QUEUE_URL,
                MaxNumberOfMessages=10,
                VisibilityTimeout=60,  # 60 seconds to process
                WaitTimeSeconds=20      # Long polling
            )
            
            messages = response.get('Messages', [])
            
            for message in messages:
                try:
                    body = json.loads(message['Body'])
                    order_id = body['order_id']
                    user_id = body['user_id']
                    
                    # Check if already processed (idempotency)
                    if redis_client.exists(f"processed_order_{order_id}"):
                        print(f"Order {order_id} already processed; skipping")
                        sqs.delete_message(
                            QueueUrl=QUEUE_URL,
                            ReceiptHandle=message['ReceiptHandle']
                        )
                        continue
                    
                    # Process order
                    print(f"Processing order {order_id} for user {user_id}")
                    
                    send_confirmation_email(user_id)
                    update_inventory(order_id)
                    charge_payment(order_id, body['amount'])
                    log_analytics(order_id, user_id)
                    
                    # Mark as processed
                    redis_client.set(f"processed_order_{order_id}", 1, ex=86400)
                    
                    # Delete message from queue
                    sqs.delete_message(
                        QueueUrl=QUEUE_URL,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    
                    print(f"✓ Order {order_id} processed successfully")
                
                except Exception as e:
                    print(f"✗ Error processing order: {e}")
                    # Message will be retried after visibility timeout
                    # If fails 3 times, moves to DLQ automatically
        
        except Exception as e:
            print(f"Error fetching messages: {e}")
            time.sleep(5)

def send_confirmation_email(user_id):
    """Simulate sending email"""
    time.sleep(0.5)  # Simulate email API call
    print(f"  → Email sent to user {user_id}")

def update_inventory(order_id):
    """Update inventory database"""
    time.sleep(0.02)
    print(f"  → Inventory updated")

def charge_payment(order_id, amount):
    """Charge credit card"""
    time.sleep(0.3)  # API call
    print(f"  → Charged ${amount}")

def log_analytics(order_id, user_id):
    """Log to analytics"""
    time.sleep(0.05)
    print(f"  → Analytics logged")

if __name__ == '__main__':
    print("Starting order processing worker...")
    process_order_worker()
```

#### EventBridge Rules for Complex Routing

```bash
#!/bin/bash

# Create SNS targets for fraud orders
aws events put-rule \
  --name high-value-orders \
  --event-pattern '{
    "source": ["order.service"],
    "detail-type": ["Order"],
    "detail": {
      "amount": [{"numeric": [">", 1000]}]
    }
  }' \
  --state ENABLED

# Add fraud detection Lambda as target
aws events put-targets \
  --rule high-value-orders \
  --targets "Id"="1","Arn"="arn:aws:lambda:us-east-1:123456:function:fraud-detector"

# Create scheduled rule for daily reconciliation
aws events put-rule \
  --name daily-order-reconciliation \
  --schedule-expression 'cron(0 2 * * ? *)' \
  --state ENABLED

# Add Step Functions as target
aws events put-targets \
  --rule daily-order-reconciliation \
  --targets "Id"="1","Arn"="arn:aws:stepfunctions:us-east-1:123456:stateMachine:reconciliation"
```

### ASCII Diagrams

#### Async Message Flow for Order Processing
```
ASYNCHRONOUS ORDER PROCESSING
═════════════════════════════════════════════════════════════

User clicks "Submit Order"
          │
          ↓
    [API Handler]
    ├─ Validate order (10ms)
    ├─ Insert DB (10ms)  
    ├─ Publish to SNS (5ms)
    └─ Return 200 OK (25ms total)
          │
          ↓
    User sees "Order Processing"
    
    Meanwhile, background workers process asynchronously:
    
          │
          └→ SNS Topic: "order.created"
             │
             ├─→ Email Worker
             │   ├─ Consume message from SQS
             │   ├─ Send email (1000ms)
             │   ├─ Mark processed
             │   └─ Delete SQS message
             │
             ├─→ Inventory Worker
             │   ├─ Consume message from SQS
             │   ├─ Update stock (20ms)
             │   ├─ Mark processed
             │   └─ Delete SQS message
             │
             ├─→ Payment Worker
             │   ├─ Consume message from SQS
             │   ├─ Charge credit card (500ms)
             │   ├─ Mark processed
             │   └─ Delete SQS message
             │
             └─→ Analytics Worker
                 ├─ Consume message from SQS
                 ├─ Log to data warehouse (100ms)
                 ├─ Mark processed
                 └─ Delete SQS message


FAILURE HANDLING:
═════════════════════════════════════════════════════════════

Payment Worker fails on charge:
  ├─ Catch exception
  ├─ Retry (max 3 times with backoff)
  ├─ All retries fail
  └─ Move to Dead-Letter Queue
     └─ On-call reviews; manually processes
     └─ If payment fails, can refund + retry later
```

---

## 9. Storage Layer

### Textual Deep Dive

#### Internal Working Mechanism

Storage at 1 million users requires:

1. **Object storage** (S3 for user-generated content)
2. **File storage** (EFS for shared access)
3. **Block storage** (EBS for databases)
4. **Cost optimization** (lifecycle policies, compression)

**Storage Needs at 1M Users**
```
User-generated content:
  ├─ 1M users × 100MB average = 100 PB (petabytes!)
  │
  └─ S3 pricing: $0.023 per GB per month
     └─ 100PB = 100 million GB × $0.023 = $2.3M/month!

Optimization needed:
  ├─ Compression (50% reduction typical)
  ├─ Deduplication (30% reduction)
  └─ Tiered storage (move old data to Glacier = $0.004/GB)
```

#### S3 (Simple Storage Service)

**Architecture**
```
S3 bucket:
  ├─ Regional (data stays in one region by default)
  ├─ 99.999999999% (11 nines) durability
  ├─ Unlimited objects; ~5.12TB max/object
  ├─ Throughput: 3500 PUT/sec, 5500 GET/sec per partition key
  │
  └─ Pricing tiers:
      ├─ Standard: $0.023/GB (accessed frequently)
      ├─ Infrequent Access: $0.0125/GB (accessed monthly)
      ├─ Glacier Flexible: $0.004/GB (archived, retrieval hours)
      └─ Glacier Instant: $0.01/GB (archived, instant retrieval)
```

**Production Usage Patterns**

1. **User-Generated Content (Photos, Videos)**
   ```
   Use case: Instagram-like system
   
   Upload flow:
     ├─ User uploads image
     ├─ API validates (size, format)
     ├─ Lambda resizes for thumbnails (3 sizes)
     │   ├─ Small  (100px): 50KB
     │   ├─ Medium (500px): 200KB
     │   └─ Large  (2000px): 1MB
     │
     ├─ Upload to S3
     │   ├─ user-uploads/123/original.jpg
     │   ├─ user-uploads/123/small.jpg
     │   ├─ user-uploads/123/medium.jpg
     │   └─ user-uploads/123/large.jpg
     │
     └─ Return CloudFront URL
         └─ https://cdn.example.com/user-uploads/123/medium.jpg
   
   Tier after 30 days:
     └─ Move to Infrequent Access (save 50% on storage)
   ```

2. **Database Backups**
   ```
   Daily snapshots: 500GB compressed
     ├─ S3 Standard: $11.50/month first 30 days
     ├─ After 30 days → Glacier: $2/month
     ├─ Retention: 12 months
     │
     └─ Cost over year: ~$60 (vs $140 Standard)
   ```

3. **Log Archival**
   ```
   Logs generated: 1.1 PB per day
     ├─ Keep 30 days in standard (hot)
     │   └─ 30 PB × $0.023 = $690K/month
     │
     ├─ Keep 1 year in Glacier (cold)
     │   └─ 365 PB × $0.004 = $1.46M/year ($122K/month)
     │
     └─ Delete after 2 years (compliance)
   ```

#### EFS (Elastic File System)

**Use Case: Shared Storage**
```
Multiple compute instances need shared access

Example: Video transcoding farm
  ├─ Upload video to S3 (original)
  ├─ Trigger transcoding Lambda
  ├─ Lambda mounts EFS
  ├─ Reads original from S3
  ├─ Transcodes to multiple formats
  ├─ Writes intermediate to EFS (shared)
  ├─ EC2 instance reads from EFS
  ├─ Converts to different codec
  ├─ Uploads to S3 (final)
  │
  └─ Cost: EFS mount, throughput charges
```

**Characteristics**
```
Pricing:
  ├─ Standard Storage: $0.30/GB-month
  ├─ Infrequent Access: $0.025/GB-month (if < 50% accessed)
  │
  └─ Throughput: Bursting (default) or provisioned
      └─ For 13M RPS system: Need provisioned mode

Latency: Lower than S3; higher than EBS
  ├─ EFS: 1-2ms (network storage)
  ├─ EBS: <1ms (block device)
  └─ S3: 50-100ms (internet gateway)
```

#### BlockStorage (EBS)

**EBS Volumes for Databases**
```
High-throughput applications:
  ├─ RDS instances use EBS (gp3 or io2)
  ├─ Throughput: 1000 MB/sec (gp3) to 4000 MB/sec (io2)
  └─ Cost: $0.10/GB-month (gp3)

Sizing example:
  ├─ Database: 500GB
  ├─ IOPS needed: 100K (for 13M RPS)
  └─ EBS cost: 500 × $0.10 + IOPS charges = ~$150/month
```

#### DevOps Best Practices

**Practice 1: S3 Lifecycle Policies**
```
Auto-tier storage as data ages:

Day 0-30: S3 Standard ($0.023/GB)
  ├─ Actively accessed
  └─ Hot tier

Day 31-90: S3 Intelligent-Tiering ($0.0125/GB average)
  ├─ Accessed occasionally
  └─ Auto-moves based on access patterns

Day 91-365: Glacier Flexible ($0.004/GB)
  ├─ Rarely accessed
  ├─ 3-5 hour retrieval lag (acceptable)
  └─ Cold tier

After 365 days: Delete / Archive to cold storage

Savings: 83% vs always keeping in Standard
```

**Practice 2: S3 Versioning & Locking**
```
Enable versioning:
  ├─ Protects against accidental deletes
  ├─ Each "delete" just marks deleted (previous version stays)
  ├─ Can restore old versions
  │
  └─ Cost: pays for all versions (could be expensive)

Object Lock (for compliance):
  ├─ Prevent deletion for X days (WORM = write-once, read-many)
  ├─ Required for PCI-DSS, HIPAA, SOX compliance
  │
  └─ Cost: Minimal (small overhead)
```

**Practice 3: S3 Cross-Region Replication**
```
Replicate to second region for disaster recovery:

Primary Bucket (us-east-1)
        ├─ New object uploaded
        │
        └→ Automatic replication to Backup (us-west-2)
           ├─ Replication lag: 15 seconds
           ├─ If primary region fails: Failover to backup
           │
           └─ Cost: Data transfer charges (egress)
              └─ $0.02 per GB (significant at scale)
```

#### Common Pitfalls

**Pitfall 1: Request Rate Limits on S3 Prefix**
```
S3 has a limit per partition key (prefix):
  └─ 3500 PUT/s, 5500 GET/s per prefix

Bad design:
  ├─ All users uploaded to: uploads/image_123.jpg
  ├─ Prefix: uploads/
  └─ 13M RPS trying to same prefix = throttled!

Good design:
  ├─ Shard by user: uploads/{user_id}/image_{timestamp}.jpg
  ├─ 1M users distributed across thousand prefixes
  ├─ Each prefix: 13K RPS (well within limits)
  │
  └─ If still bottleneck: Add randomness
    └─ uploads/{shard_id}/{user_id}/image_{timestamp}.jpg
       (compute shard from user_id)
```

**Pitfall 2: Not Using Multipart Upload for Large Files**
```
Uploading 1GB file as single request:
  ├─ If network hiccup midway: Restart from beginning
  ├─ Takes 100 seconds (slow)
  ├─ Failed retries waste bandwidth

Multipart upload:
  ├─ Split into 5GB parts
  ├─ If part fails: Retry only that part
  ├─ Parallel upload (5 parts at once = 5x speed)
  │
  └─ Cost: Same; benefit: Much faster & resilient
```

**Pitfall 3: Not Deleting Incomplete Multipart Uploads**
```
Scenario:
  ├─ User starts uploading 5GB file (5 parts)
  ├─ Part 1-4 uploaded successfully
  ├─ User closes browser (part 5 never uploaded)
  ├─ Incomplete upload sits in S3
  │
  └─ S3 still charges for parts 1-4!

Solution:
  ├─ Set lifecycle policy
  │   └─ Delete incomplete multipart uploads after 7 days
  │
  └─ Saves storage costs from partial uploads
```

### Practical Code Examples

#### S3 Lifecycle Policy Configuration

```bash
#!/bin/bash

# Create S3 lifecycle policy JSON
cat > lifecycle-policy.json <<'EOF'
{
  "Rules": [
    {
      "Id": "Archive old backups",
      "Status": "Enabled",
      "Prefix": "backups/",
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
        "NoncurrentDays": 365
      }
    },
    {
      "Id": "Delete incomplete multipart uploads",
      "Status": "Enabled",
      "AbortIncompleteMultipartUpload": {
        "DaysAfterInitiation": 7
      }
    },
    {
      "Id": "Archive and delete user uploads",
      "Status": "Enabled",
      "Prefix": "user-uploads/",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 180,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 730
      }
    }
  ]
}
EOF

# Apply to S3 bucket
BUCKET_NAME="my-app-storage"

aws s3api put-bucket-lifecycle-configuration \
  --bucket $BUCKET_NAME \
  --lifecycle-configuration file://lifecycle-policy.json

echo "Lifecycle policy applied to $BUCKET_NAME"
```

#### S3 Upload with Sharding (Python)

```python
import hashlib
import boto3
from botocore.exceptions import ClientError

s3_client = boto3.client('s3')
BUCKET_NAME = 'user-uploaded-content'

class ShardedS3Upload:
    def __init__(self, num_shards: int = 100):
        self.num_shards = num_shards
        self.bucket = BUCKET_NAME
    
    def get_shard_id(self, user_id: int) -> str:
        """Distribute user uploads across shards"""
        shard_num = user_id % self.num_shards
        return f"shard-{shard_num:03d}"
    
    def upload_file(self, user_id: int, file_data: bytes, 
                    filename: str) -> str:
        """Upload file with sharded prefix"""
        
        shard = self.get_shard_id(user_id)
        key = f"{shard}/user-{user_id}/{filename}"
        
        try:
            # Upload with server-side encryption
            s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=file_data,
                ServerSideEncryption='AES256',
                Metadata={
                    'user-id': str(user_id),
                    'upload-time': datetime.now().isoformat()
                }
            )
            
            # Return CloudFront URL
            cloudfront_url = f"https://cdn.example.com/{key}"
            return cloudfront_url
        
        except ClientError as e:
            print(f"Upload failed: {e}")
            raise
    
    def upload_large_file(self, user_id: int, file_path: str,
                         filename: str) -> str:
        """Upload large file using multipart upload"""
        
        shard = self.get_shard_id(user_id)
        key = f"{shard}/user-{user_id}/{filename}"
        
        # Multipart upload
        mpu = s3_client.create_multipart_upload(
            Bucket=self.bucket,
            Key=key,
            ServerSideEncryption='AES256'
        )
        upload_id = mpu['UploadId']
        
        try:
            parts = []
            part_size = 5 * 1024 * 1024  # 5MB parts
            
            with open(file_path, 'rb') as f:
                part_num = 1
                while True:
                    data = f.read(part_size)
                    if not data:
                        break
                    
                    # Upload part
                    response = s3_client.upload_part(
                        Bucket=self.bucket,
                        Key=key,
                        PartNumber=part_num,
                        UploadId=upload_id,
                        Body=data
                    )
                    
                    parts.append({
                        'PartNumber': part_num,
                        'ETag': response['ETag']
                    })
                    part_num += 1
            
            # Complete multipart upload
            s3_client.complete_multipart_upload(
                Bucket=self.bucket,
                Key=key,
                UploadId=upload_id,
                MultipartUpload={'Parts': parts}
            )
            
            return f"https://cdn.example.com/{key}"
        
        except ClientError as e:
            # Abort incomplete upload
            s3_client.abort_multipart_upload(
                Bucket=self.bucket,
                Key=key,
                UploadId=upload_id
            )
            raise
```

### ASCII Diagrams

#### Storage Tiering Over Data Lifecycle
```
S3 STORAGE TIERING STRATEGY
═════════════════════════════════════════════════════════════

Cost vs. Accessibility Timeline:

Price per GB/month:
$0.023  ┌─ Standard
        │ (Immediate access)
        │ Days 0-30
        │ ████
$0.0125 ├─ Intelligent-Tiering
        │ (Auto-managed)
        │ Days 31-90
        │ ███
$0.004  ├─ Glacier Flexible
        │ (5-hour recovery)
        │ Days 91-365
        │ ██
$0       └─ Deleted
         Days 365+
         
Assuming 100TB of data:
  ├─ 30 days Standard:   30TB × $0.023  = $690
  ├─ 60 days InFreq:     60TB × $0.0125 = $750
  ├─ 275 days Glacier:   275TB × $0.004 = $1,100
  └─ Total Year 1: $2,540 (vs $26,840 if all Standard)
  
  **Savings: 90.5%**
```

---

## 10. Monitoring and Observability

### Textual Deep Dive

#### Internal Working Mechanism

At 1 million concurrent users, you cannot fix what you cannot see. Monitoring and observability require:

1. **Metrics** (CPU, latency, error rate)
2. **Logs** (detailed request information)
3. **Traces** (cross-service request paths)
4. **Alerts** (notify when thresholds exceeded)
5. **Dashboards** (visualize system health)

**The Three Pillars**
```
Metrics (quantitative):
  ├─ Request latency: P50=100ms, P95=500ms, P99=2sec
  ├─ Error rate: 0.05%
  ├─ Throughput: 13M RPS
  ├─ CPU utilization: 65%
  └─ Database connections: 8000/10000

Logs (textual):
  ├─ "2024-04-17 12:34:56 INFO User 123 logged in"
  ├─ "2024-04-17 12:34:57 ERROR Database connection timeout"
  └─ "2024-04-17 12:34:58 WARN Cache miss for key user_456"

Traces (request flow):
  ├─ Request ID: abc123def456
  ├─ API Gateway: 10ms
  ├─ Application: 400ms
  ├─ Database: 100ms
  ├─ Cache: 5ms
  └─ Total: 515ms
```

#### CloudWatch (AWS Native)

**Metrics**
```
Standard metrics (auto-collected):
  ├─ CPU Utilization
  ├─ Network Bytes In/Out
  ├─ Disk Operations
  └─ Status Checks

Custom metrics (application-emitted):
  ├─ Request latency
  ├─ Business metrics (orders per minute)
  ├─ Application errors
  └─ Cache hit ratio

Dashboard example:
  ├─ Row 1: Request latency (P50, P95, P99)
  ├─ Row 2: Error rate by service
  ├─ Row 3: Database connections + replication lag
  ├─ Row 4: Cache hit ratio
  └─ Row 5: Auto-scaling metrics
```

**Logs**
```
CloudWatch Logs stores application logs

Cost:
  ├─ 1.1 PB per day at 1M users
  └─ $0.50 per GB ingested = $550K/month!

Optimization:
  ├─ Sample logs (keep 1% of requests)
  ├─ Filter log levels (ERROR + WARN, not DEBUG)
  ├─ Use structured logging (JSON for easy querying)
  │
  └─ Cost with sampling: $55K/month (10% of unsampled)
```

**Alarms**
```
Create alarms for anomalies:

CPU Alarm:
  IF CPU > 80% for 5 minutes
  THEN send SNS alert

P99 Latency Alarm:
  IF P99 latency > 2 seconds for 5 minutes
  THEN auto-scale compute layer

Error Rate Alarm:
  IF error rate > 1% for 2 minutes
  THEN page on-call engineer
  
DLQ Alarm:
  IF messages in dead-letter queue > 100
  THEN page on-call engineer
```

#### X-Ray (Distributed Tracing)

**Request Tracing Across Services**
```
User  API  Service A  Service B  Database
│     │        │           │          │
├────→│        │           │          │
│  request_id=abc123def456  │          │
│     ├───────→│           │          │
│     │    10ms│           │          │
│     │        ├──────────→│          │
│     │        │      5ms  │          │
│     │        │           ├─────────→│
│     │        │           │    100ms │
│     │        │           │←─────────┤
│     │        │←──────────┤          │
│     │←───────┤          │          │
│←────┤        │          │  Total: 115ms

X-Ray shows:
  ├─ API → Service A: 10ms
  ├─ Service A → Service B: 5ms
  ├─ Service B → Database: 100ms
  └─ Total: 115ms

Identifies bottleneck: Database (87% of time)
Action: Optimize database query or add cache
```

**Implementation**
```
# Python Flask integration
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

app = Flask(__name__)
XRayMiddleware(app, xray_recorder)

@app.route('/api/users/<user_id>', methods=['GET'])
@xray_recorder.capture('get_user')
def get_user(user_id):
    # Automatic tracing in this function
    user = database.query(user_id)
    return jsonify(user)
```

#### Prometheus (Open Source)

**Time-Series Metrics Database**
```
Prometheus + Grafana stack:
  ├─ Prometheus: Scrapes metrics from applications
  ├─ Grafana: Visualizes Prometheus data
  └─ AlertManager: Sends alerts

Advantages:
  ├─ Open source (no vendor lock-in)
  ├─ Flexible querying (PromQL)
  ├─ Community support
  └─ Works with Kubernetes

Disadvantages:
  ├─ Self-hosted (operational burden)
  ├─ Retention: Default 15 days (need long-term storage)
  └─ Scaling: Complex for 1M metric time-series
```

#### DevOps Best Practices

**Practice 1: SLOs and Error Budgets**
```
SLO (Service Level Objective): 99.9% uptime
  └─ Acceptable downtime: 0.1% = 43.2 minutes/month

Error budget:
  ├─ If no incidents: Can deploy new version (high risk)
  ├─ If 1 incident already: Must be very careful
  ├─ If error budget exhausted: Freeze deployments
  │
  └─ Forces trade-off between velocity and stability

Example dashboard:
  ├─ Error budget status: 26 minutes remaining (60%)
  ├─ Incident history: 1 incident in past 30 days
  ├─ Deployment risk: MEDIUM (proceed with caution)
  └─ Recommendation: Wait before next deploy
```

**Practice 2: Meaningful Alerting (Avoid Alert Fatigue)**
```
BAD: Alert on CPU > 75% for 1 minute
  ├─ Triggers 100 times per day
  ├─ Engineers ignore alarms (alert fatigue)
  │
  └─ Result: Real outage gets missed

GOOD: Alert if P99 latency > 2 sec for 5 minutes
  ├─ Triggers only on actual pain
  ├─ Engineers respond immediately
  │
  └─ Result: Real outages caught quickly

Alerting best practices:
  ├─ Alert on business metrics (latency, error rate)
      NOT infrastructure metrics (CPU, disk)
  ├─ Avoid flapping (same alert multiple times)
  ├─ Include runbook in alert (action to take)
  └─ Route to correct team (not all-hands alert)
```

**Practice 3: Observability-Driven Development**
```
Instrument from the start:
  ├─ Every database query logs: query, time, result count
  ├─ Every API call logs: request ID, user ID, latency
  ├─ Every error logs: stack trace, context, user impact
  │
  └─ Cost: Small overhead; huge debugging benefit

When production issue occurs:
  ├─ Query logs for request ID
  ├─ See full request path (all services involved)
  ├─ Identify slow service
  ├─ Check slow queries in that service
  └─ Root cause found in minutes (vs hours)
```

#### Common Pitfalls

**Pitfall 1: Not Sampling High-Volume Metrics**
```
1M concurrent users × 10 req/sec = 10M requests/sec
Log all requests: 10M log lines per second

CloudWatch cost:
  ├─ 10M lines/sec × 86400 sec/day × 30 days
  ├─ 25.9B log lines per month
  ├─ Cost: $500K/month (at $0.50 per GB ingested)
  │
  └─ Unsustainable at scale!

Solution: Sample
  ├─ Log 1% of requests = 100K lines/sec
  ├─ For errors: Log 100% (errors are rare)
  ├─ For slow queries: Log 100% (slow queries are rare)
  │
  └─ Cost: $5K/month (100x reduction)
```

**Pitfall 2: Alarms with No Runbook**
```
3 AM alert: "Error rate > 2%"

Engineer oncall:
  ├─ Groggy from sleep
  ├─ What do I do now?
  ├─ Check logs... (slow; logs massive)
  ├─ Try rollback... (might not be code issue)
  └─ Call senior engineer for help (more people awake)

Without runbook: 1+ hour MTTR (mean time to recovery)

With runbook:
  1. Check database connection pool (likely culprit)
  2. If pool exhausted, increase and restart
  3. If not, check recent deployments
  4. Rollback if code deployed recently
  
With runbook: 5 minute MTTR
```

**Pitfall 3: Not Monitoring the Monitoring System**
```
Scenario:
  ├─ Production is fine
  ├─ But CloudWatch agent crashes
  ├─ Monitoring stops
  ├─ No alarms firing (because monitoring dead!)
  ├─ Production has outage
  └─ Nobody notices for hours

Solution: Monitor the monitor!
  ├─ Alert if CloudWatch agent not reporting
  ├─ Alert if Prometheus scrape fails
  ├─ Alert if log ingestion stops
  └─ Treat same as application alerts
```

### Practical Code Examples

#### CloudWatch Custom Metrics (Python Flask)

```python
import boto3
from flask import Flask, request
from datetime import datetime
import time
import functools

app = Flask(__name__)
cloudwatch = boto3.client('cloudwatch')

def log_metric(metric_name, value, unit='Count', dimensions=None):
    """Send custom metric to CloudWatch"""
    try:
        cloudwatch.put_metric_data(
            Namespace='MyApplication',
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Timestamp': datetime.utcnow(),
                    'Dimensions': dimensions or []
                }
            ]
        )
    except Exception as e:
        # Log but don't crash application
        print(f"Failed to send metric: {e}")

def track_request_metrics(f):
    """Decorator to track request latency and errors"""
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        start_time = time.time()
        
        try:
            result = f(*args, **kwargs)
            success = True
            return result
        except Exception as e:
            success = False
            # Log error metric
            log_metric('RequestError', 1, dimensions=[
                {'Name': 'Function', 'Value': f.__name__}
            ])
            raise
        finally:
            # Log latency metric
            duration_ms = (time.time() - start_time) * 1000
            log_metric('RequestLatency', duration_ms, 'Milliseconds',
                       dimensions=[
                           {'Name': 'Function', 'Value': f.__name__},
                           {'Name': 'Success', 'Value': str(success)}
                       ])
    
    return decorated_function

@app.route('/api/users/<user_id>', methods=['GET'])
@track_request_metrics
def get_user(user_id):
    # Automatic metric tracking
    user = database.query(user_id)
    return jsonify(user)

@app.route('/api/orders', methods=['POST'])
@track_request_metrics
def create_order():
    data = request.json
    order = database.create_order(data)
    
    # Log business metric
    log_metric('OrderCreated', 1, dimensions=[
        {'Name': 'OrderValue', 'Value': str(data['amount'])}
    ])
    
    return jsonify(order), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

#### X-Ray Service Map Configuration

```bash
#!/bin/bash

# Enable X-Ray daemon on EC2
yum install aws-xray-daemon

# Configure X-Ray daemon
cat > /etc/amazon/xray/cfg.yaml <<'EOF'
LogLevel: "info"
LogRotation: true
LocalAddr: "127.0.0.1:2000"

UseSSL: true
TLSCertPath: ""
TLSKeyPath: ""

ResourceARN: ""
RoleARN: ""
ProxyAddress: ""

LogFormat: "json"

Concurrency: 32

# Service map options
ServiceVersion: "1.0"
InstanceId: ""
EOF

# Start X-Ray daemon
systemctl start xray
systemctl enable xray

# In application code (Python)
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Patch all supported libraries
patch_all()

# Configure recorder
xray_recorder.configure(
    service='MyAPI',
    context_missing='LOG_ERROR'
)

# Your application code now traced automatically
```

#### Prometheus Job Configuration for App Metrics

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'api-servers'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['localhost:8080', 'localhost:8081', 'localhost:8082']
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance

  - job_name: 'databases'
    metrics_path: '/metrics'
    consul_sd_configs:
      - server: 'localhost:8500'
        datacenter: 'dc1'
        services: ['mysql']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - 'alert_rules.yml'
```

#### Alert Rules (Prometheus)

```yaml
# alert_rules.yml
groups:
  - name: application
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: |
          (sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
           / sum(rate(http_requests_total[5m])) by (service)) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected in {{ $labels.service }}"
          runbook_url: "https://wiki.example.com/runbooks/high-error-rate"

      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, http_request_duration_seconds_bucket) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency > 2 seconds"
```

### ASCII Diagrams

#### Observabilty Stack Architecture
```
OBSERVABILITY STACK FOR 1M USERS
═════════════════════════════════════════════════════════════

Application Layer
  ├─ API Gateway → EmitMetrics
  ├─ Compute → EmitMetrics + Logs
  ├─ Database → EmitMetrics + Slow Query Log
  └─ Cache → EmitMetrics

            │
            │ (Emit)
            ↓

Collection Layer
  ├─ CloudWatch Logs Agent
  │   └─ Collects application logs
  │
  ├─ CloudWatch Metrics (custom)
  │   └─ Application metrics
  │
  ├─ X-Ray Daemon
  │   └─ Request traces
  │
  └─ Prometheus Scraper
      └─ Time-series metrics

            │
            │ (Store)
            ↓

Storage Layer
  ├─ CloudWatch Logs
  │   └─ 30 days retention (searchable)
  │
  ├─ CloudWatch Metrics
  │   └─ 15 months retention
  │
  ├─ X-Ray Service Map
  │   └─ 30 days tracing data
  │
  └─ Prometheus
      └─ Local 15 days (+ long-term storage)

            │
            │ (Query & Visualize)
            ↓

Visualization Layer
  ├─ CloudWatch Dashboards
  │   ├─ Request latency (P50, P95, P99)
  │   ├─ Error rate by service
  │   └─ Resource utilization
  │
  ├─ X-Ray Service Map
  │   └─ Shows dependencies and latencies
  │
  ├─ Grafana
  │   ├─ Time-series graphs
  │   ├─ Heatmaps
  │   └─ Alerts

            │
            │ (Alert)
            ↓

Alerting Layer
  ├─ CloudWatch Alarms
  │   └─ Trigger SNS topics
  │
  ├─ Prometheus AlertManager
  │   ├─ Email
  │   ├─ Slack
  │   └─ PagerDuty

            │
            │ (Notify)
            ↓

On-Call Engineer → Investigate → Fix → Verify
```

---

## 11. Cost Optimization Strategies

### Textual Deep Dive

#### Internal Working Mechanism

At 1 million concurrent users generating 13M RPS, your monthly AWS bill could reach:

```
Compute (130 c5.4xlarge instances + ASG): $200K/month
Database (shards + replicas): $150K/month
Cache (ElastiCache cluster): $50K/month
Storage (100PB S3 + lifecycle): $200K/month
Data Transfer (inter-region): $100K/month
Monitoring (CloudWatch logs): $50K/month
Other (networking, firewalls): $50K/month
═══════════════════════════════════════════════════════════
TOTAL: $800K/month ($9.6M/year)

Without optimization, this balloons to $2M+/month
With optimization, possible to achieve $500K/month (40% savings)
```

**Cost Optimization Levers**

1. **Compute Optimization**
   - Use Spot instances (70% cheaper)
   - Right-size instances (monitor actual CPU usage)
   - Use Fargate for variable workloads

2. **Database Optimization**
   - Defer infrequently accessed data to S3
   - Use On-Demand DynamoDB instead of provisioned RDS
   - Archive old data to Glacier

3. **Storage Optimization**
   - Compress data (50% reduction typical)
   - Use S3 Intelligent-Tiering
   - Deduplicate data

4. **Data Transfer Optimization**
   - Minimize inter-AZ transfers ($0.01/GB)
   - Minimize cross-region transfers ($0.02/GB)
   - Use CloudFront (reduce origin load 80%+)

#### Savings Plans and Reserved Instances

**Reserved Instances (RIs)**
```
Commitment: 1 or 3 years upfront
Discount: 30-50% off on-demand

Example: EC2 c5.4xlarge in us-east-1
  On-Demand: $0.68/hour × 730 hours/month = $496/month
  1-year RI: $0.51/hour × 730 = $372/month (25% savings)
  3-year RI: $0.39/hour × 730 = $285/month (43% savings)

For 130 instances:
  On-Demand: $130 × $496 = $64K/month
  1-year RI: $130 × $372 = $48K/month (savings: $16K)
  3-year RI: $130 × $285 = $37K/month (savings: $27K)

Caveat: Must predict usage 1-3 years in advance
        If usage drops, can't reduce commitment
```

**Savings Plans**
```
Commitment: Hourly spend (not specific instance)
Flexibility: Can change instance type, region, OS

Example: 1-year commitment to spend $100/hour on compute
  Covers: Mix of m5, c5, t3 instances
  Discount: 30% off on-demand rates
  
Advantage: More flexible than RIs
  └─ Can switch instance types without penalty
```

**Spot Instances**
```
Pricing: 70-90% discount vs on-demand
Tradeoff: AWS can terminate with 2-minute notice

For 130 instances:
  ├─ 80 on-demand (baseline): 80 × $496 = $40K
  ├─ 50 spot (peak capacity): 50 × $150 = $7.5K
  └─ Total: $47.5K (vs $64K on-demand) = 26% savings

Risk mitigation:
  ├─ Diversify across instance types (multiple options)
  ├─ Target multiple AZs
  └─ Set max price at 1.5x current spot (guarantees availability)
```

#### Data Transfer (Often Forgotten Cost)

**Inter-AZ Data Transfer**
```
Within AZ: Free
Between AZ: $0.01 per GB out

Example: 1TB data transfer between AZs/day
  Cost: 1000 GB × $0.01 × 30 = $300/month

Optimization:
  ├─ Keep data in single AZ (less resilient)
  ├─ Use local caches to reduce inter-AZ traffic
  └─ Shard by AZ (user data in single AZ)
```

**Cross-Region Data Transfer**
```
Within region: $0 (with few exceptions)
Between regions: $0.02 per GB out

Example: Replicate data across regions
  1TB/day × $0.02 = 30TB/month × $0.02 = $600/month

For 1M users with global reach:
  ├─ If NOT replicated: Users must request from primary (high latency)
  ├─ If replicated: Higher costs but better UX
  │
  └─ Cost vs. benefit: Usually worth it for global apps
```

**CloudFront Egress** (Already Discussed)
```
CloudFront reduces origin load 80%+
  ├─ Saves compute & database costs
  ├─ Costs $0.085/GB for data out
  │
  └─ Net: Saves money (avoided origin traffic costs more)
```

#### DevOps Best Practices

**Practice 1: Cost Allocation Tags**
```
Tag all resources:
  ├─ Team: backend, frontend, data-science
  ├─ Environment: production, staging, development
  ├─ Application: orders, payments, users
  └─ CostCenter: engineering, marketing

AWS Cost Explorer lets you filter:
  "Show me costs by Team"
  ├─ backend: $500K/month
  ├─ frontend: $50K/month
  └─ data-science: $100K/month

Accountability:
  └─ Each team sees their costs; incentivized to optimize
```

**Practice 2: Auto-Scaling Policies with Predictive Scaling**
```
Standard Target Tracking:
  If CPU > 70% → Add instances
  If CPU < 40% → Remove instances

Problem: Lag time means overprovisioning

Predictive Scaling (ML-based):
  ├─ ML model learns patterns:
  │   └─ Tuesdays 8 AM: CPU always spikes
  │
  ├─ Proactively scale at 7:55 AM (before spike)
  │
  └─ Cost savings: 20-30% (less over-provisioning)
```

**Practice 3: Right-Sizing**
```
Instance monitoring:
  ├─ Track actual CPU, memory usage (not peak)
  ├─ Identify under-utilized instances
  ├─ Downsize if consistent low usage

Example:
  c5.2xlarge (8 vCPU, 16 GB RAM) with avg 20% CPU, 30% memory
  └─ Downsize to c5.large (2 vCPU, 4 GB RAM)
  
Cost: $0.34/hour down from $0.34/hour = $0 (same?!)
No wait: c5.large = $0.09/hour (correct)

Savings: $0.34 - $0.09 = $0.25/hour × 730 hours = $183/month
For 50 under-sized instances: $9,150/month
```

#### Common Pitfalls

**Pitfall 1: Ignoring Data Transfer Costs**
```
Scenario:
  ├─ Daily ETL process transfers 100GB from RDS to S3
  ├─ Then lambda processes from S3
  ├─ Cost seems low (RDS + Lambda cheap)
  │
  └─ Hidden cost: Data transfer = $3,000/month!

Solution:
  ├─ Use AWS Glue (internal transfer is free)
  ├─ Or use S3 Select to filter data (reduce transfer)
  └─ Or consolidate to S3 from start
```

**Pitfall 2: Over-Provisioning for "Safety"**
```
Scenario:
  ├─ System needs 10M RPS capacity
  ├─ "What if traffic doubles?" (never has in 3 years)
  ├─ Provision for 20M RPS capacity "just in case"
  │
  └─ 50% of infrastructure sits idle 99% of time
  └─ Cost: $400K/month instead of $300K ($100K waste)

Solution:
  ├─ Provision for measured demand
  ├─ Use auto-scaling for contingency
  └─ Monitor auto-scaling metrics
```

**Pitfall 3: Not Cleaning Up Old Resources**
```
Scenario (surprisingly common):
  ├─ EBS snapshots from 2 years ago: 100 TB × $0.05/GB = $5K/month
  ├─ Old RDS databases (testing): $10K/month
  ├─ Unused NAT gateways: $3K/month (not using)
  ├─ Old CloudFormation stacks (abandoned): $5K/month
  │
  └─ Total waste: $23K/month!

Solution:
  ├─ Monthly cleanup of unused resources
  ├─ Tag resources with "expiration date"
  ├─ Auto-delete after 30 days (unless renewed)
  └─ Cost savings: $23K/month
```

### Practical Code Examples

#### AWS Cost Explorer via Python

```python
import boto3
import json
from datetime import datetime, timedelta

ce_client = boto3.client('ce')

def get_daily_costs(days=90):
    """Get daily cost breakdown"""
    
    end_date = datetime.now().date()
    start_date = end_date - timedelta(days=days)
    
    response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': start_date.isoformat(),
            'End': end_date.isoformat()
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )
    
    # Parse and display
    for result in response['ResultsByTime']:
        date = result['TimePeriod']['Start']
        print(f"\n{date}")
        print("─" * 50)
        
        costs = {}
        for group in result['Groups']:
            service = group['Keys'][0]
            amount = float(group['Metrics']['UnblendedCost']['Amount'])
            costs[service] = amount
        
        # Sort and display
        for service, amount in sorted(costs.items(), 
                                     key=lambda x: -x[1])[:10]:
            print(f"  {service:30s}: ${amount:8.2f}")
        
        total = sum(costs.values())
        print(f"  {'TOTAL':30s}: ${total:8.2f}")

def get_reserved_instance_recommendations():
    """Get RI recommendations for cost savings"""
    
    response = ce_client.get_reservation_purchase_recommendation(
        Service='EC2',
        LookbackPeriod='THIRTY_DAYS',
        PaymentOption='ALL_UPFRONT',
        TermInYears='ONE_YEAR'
    )
    
    print("\nReserved Instance Recommendations:")
    print("─" * 80)
    
    for recommendation in response['Recommendations'][:10]:
        metadata = recommendation['RecommendationDetails'][0]['Metadata']
        
        instance_type  = metadata
        current_cost = float(recommendation['CurrentRunningCost'])
        estimated_savings = float(recommendation['EstimatedMonthlySavings'])
        
        print(f"Save ${estimated_savings:.2f} ({estimated_savings/current_cost*100:.0f}%)")

def identify_unused_resources():
    """Use CloudWatch to find unused resources"""
    
    cw = boto3.client('cloudwatch')
    
    # Find RDS instances with low CPU
    print("\nUnderutilized RDS Instances:")
    print("─" * 50)
    
    rds = boto3.client('rds')
    response = rds.describe_db_instances()
    
    for db in response['DBInstances']:
        db_id = db['DBInstanceIdentifier']
        
        # Check CPU utilization
        metrics = cw.get_metric_statistics(
            Namespace='AWS/RDS',
            MetricName='CPUUtilization',
            Dimensions=[
                {
                    'Name': 'DBInstanceIdentifier',
                    'Value': db_id
                }
            ],
            StartTime=datetime.now() - timedelta(days=7),
            EndTime=datetime.now(),
            Period=86400,  # Daily
            Statistics=['Average']
        )
        
        if metrics['Datapoints']:
            avg_cpu = sum(d['Average'] for d in metrics['Datapoints']) / len(metrics['Datapoints'])
            
            if avg_cpu < 20:  # Very low CPU
                instance_class = db['DBInstanceClass']
                hourly_cost = estimate_rds_cost(instance_class)
                monthly_waste = hourly_cost * 730 * (1 - avg_cpu/100)
                
                print(f"{db_id:30s}: {avg_cpu:5.1f}% CPU - Waste: ${monthly_waste:.0f}/mo")

def estimate_rds_cost(instance_class):
    """Rough hourly cost estimate"""
    # Simplified pricing map
    pricing = {
        'db.t3.micro': 0.017,
        'db.t3.small': 0.034,
        'db.t3.medium': 0.068,
        'db.m5.large': 0.192,
        'db.m5.xlarge': 0.384,
        'db.r5.large': 0.25,
        'db.r6i.2xlarge': 0.78,
    }
    return pricing.get(instance_class, 0.1)

if __name__ == '__main__':
    print("=" * 80)
    print("AWS COST OPTIMIZATION ANALYSIS")
    print("=" * 80)
    
    get_daily_costs(days=30)
    get_reserved_instance_recommendations()
    identify_unused_resources()
```

#### Auto-Scaling with Cost Optimization

```bash
#!/bin/bash

# CloudFormation for cost-optimized autoscaling

cat > autoscaling-cost-optimized.yaml <<'EOF'
AWSTemplateFormatVersion: '2010-09-09'

Resources:
  CostOptimizedASG:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: cost-optimized-asg
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      
      # Minimum: baseline on-demand instances
      MinSize: 50
      MaxSize: 300
      DesiredCapacity: 150
      
      VPCZoneIdentifier:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
        - !Ref PrivateSubnet3
      
      # Mixed instances: Combine on-demand + spot
      MixedInstancesPolicy:
        InstancesDistribution:
          # On-demand allocation
          OnDemandAllocationStrategy: prioritized
          OnDemandBaseCapacity: 50  # First 50 on-demand
          OnDemandPercentageAboveBaseCapacity: 30  # 30% on-demand above 50
          
          # Spot allocation
          SpotAllocationStrategy: capacity-optimized
          SpotInstancePools: 6  # Diversify across instances
          SpotMaxPrice: ""  # Use current price
        
        # Multiple instance types (flexibility for spot)
        LaunchTemplate:
          LaunchTemplateSpecification:
            LaunchTemplateId: !Ref LaunchTemplate
            Version: !GetAtt LaunchTemplate.LatestVersionNumber
          Overrides:
            - InstanceType: c5.4xlarge
            - InstanceType: c5a.4xlarge
            - InstanceType: m5.2xlarge
            - InstanceType: m5a.2xlarge
            - InstanceType: c6i.4xlarge
      
      TargetGroupARNs:
        - !GetAtt TargetGroup.TargetGroupArn

  # Predictive scaling (ML-based)
  PredictiveScalingPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !Ref CostOptimizedASG
      PolicyType: TargetTrackingScaling
      PredictiveScalingMaxCapacityBehavior: SetForecastCapacityAboveMaxCapacity
      TargetTrackingConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ASGAverageCPUUtilization
        TargetValue: 70.0
        ScaleOutCooldown: 60
        ScaleInCooldown: 300

Outputs:
  ASGName:
    Value: !Ref CostOptimizedASG
EOF

aws cloudformation create-stack \
  --stack-name cost-optimized-compute \
  --template-body file://autoscaling-cost-optimized.yaml
```

### ASCII Diagrams

#### Cost Breakdown and Optimization Opportunities
```
MONTHLY AWS BILL: $800K
═════════════════════════════════════════════════════════════

Compute: $200K (25%)
  ├─ 130 c5.4xlarge on-demand
  │
  └─ OPTIMIZATION:
      ├─ 80 on-demand + 50 spot: Save 26% ($52K)
      └─ Use Savings Plan 1-yr: Save 30% ($60K)
      └─ Potential: $120K-150K (40% savings)

Database: $150K (19%)
  ├─ 10 RDS shards + replicas
  │
  └─ OPTIMIZATION:
      ├─ Use Aurora (better scaling): Save 15% ($22K)
      └─ Defer cold data to S3: Save 20% ($30K)
      └─ Potential: $95K-120K (20-30% savings)

Cache: $50K (6%)
  └─ ElastiCache for hot data; already optimized

Storage: $200K (25%)
  ├─ 100PB raw = $0.023/GB
  │
  └─ OPTIMIZATION:
      ├─ Compress (50%): $100K
      ├─ Intelligent-tiering: Save 20%: $40K
      └─ Move to Glacier: Save 80% for archive: $100K
      └─ Potential: $100K-140K (30-50% savings)

Data Transfer: $100K (13%)
  ├─ Inter-region + inter-AZ transfers
  │
  └─ OPTIMIZATION:
      ├─ Reduce cross-region: Save 30% ($30K)
      └─ Use CloudFront: Save 50% ($50K)
      └─ Potential: $40K-70K (30-70% savings)

Monitoring: $50K (6%)
  └─ Already low; cloudwatch logs sampled

Other: $50K (6%)
  └─ Networking, support, misc

═════════════════════════════════════════════════════════════

OPTIMIZED BILL: $480K-550K
Savings: 250K-320K (31-40% reduction)
```

---

## 12. TL;DR Architecture Flow

### System Design Summary for 1 Million Concurrent Users

**Request Path (Happy Path)**
```
User Request
    ↓
[1] Route 53 (DNS)
    └─→ Geo-routing to nearest region
    ↓
[2] CloudFront (Edge Cache)
    ├─ 95% cache hit → Return immediately (50ms)
    └─ 5% cache miss → Continue to origin
    ↓
[3] WAF (DDoS Protection)
    └─→ Rate limiting, blacklist filtering
    ↓
[4] NLB (Network Load Balancer)
    └─→ Route to 130 EC2 instances
    ↓
[5] API Gateway / ALB
    └─→ Authentication, validation, routing
    ↓
[6] Application (EC2/Lambda)
    ├─ Check ElastiCache (99% hit rate)
    ├─ If miss → Query RDS (with read replica)
    └─ Return response
    ↓
[7] Async Tasks (SQS/SNS)
    ├─ Email service processes
    ├─ Analytics service logs
    ├─ Inventory service updates
    └─ All async (user doesn't wait)
    ↓
User receives response (25-515ms)
```

**Database Architecture**
```
Write: 650K RPS
  └─→ Primary RDS (writes only)
      └─→ Sync replicate to Shards 1-10
          └─→ Async replicate to Read Replicas

Read: 12.35M RPS
  └─→ Application queries Read Replicas (round-robin)
      ├─ Shard 0 Replica: 1.2M RPS
      ├─ Shard 1 Replica: 1.2M RPS
      └─ ... 10 replicas
```

**Cost Structure**
```
Baseline (always running):  $400K-500K/month
  ├─ On-demand compute
  ├─ Database + backups
  ├─ Cache + storage
  └─ Monitoring

Peak traffic (additionalspotting):  $100-200K/month
  ├─ Spot instances (50+ instances, 70% cheaper)
  └─ Auto-scaling capacity

Total: $500K-700K/month (vs $800K unoptimized)
```

---

## 13. Example Scaled Flow: E-Commerce Checkout

### User Login Flow (Detailed Request Trace)

**Scenario**: User logs in during Black Friday sale (1M concurrent users)

**Timeline**
```
T=0ms: User enters email + password

T=2ms: Browser DNS query
  └─→ Route 53 responds: 54.239.28.30 (CloudFront edge in NYC)

T=5ms: TLS handshake with CloudFront
  └─→ Uses cached certificate; resumption optimization

T=10ms: HTTP POST /api/auth/login sent to CloudFront
  └─→ CloudFront cache miss (auth endpoints not cached)
  └─→ Forward to origin

T=15ms: Request reaches WAF
  └─→ Rate limiting check: user IP 120 req/5min (OK, limit is 2000)
  └─→ Allow

T=17ms: NLB receives request
  └─→ Route to EC2 instance #42 (round-robin)

T=18ms: ALB receives request
  └─→ Route to application port 8080

T=20ms: Application validates input
  └─→ Email format valid
  └─→ Proceed to authentication

T+22ms: Check ElastiCache for user session
  └─→ Cache miss (new login)

T+25ms: Query RDS Read Replica #3
  └─→ SQL: "SELECT * FROM users WHERE email = ?"
  └─→ Index hit on email column (instant)
  └─→ Result: user_id=12345, password_hash=...

T+110ms: Password verification (bcrypt, 10 iterations)
  └─→ user_provided_password matches

T+115ms: Generate JWT token
  └─→ Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

T+117ms: Store session in ElastiCache
  └─→ Key: session_abc123
  └─→ Value: {user_id: 12345, roles: [user], created: now}
  └─→ TTL: 24 hours

T+157ms: Send async events
  └─→ Publish to SNS: "user.logged_in" event
  └─→ EventBridge routes to:
      ├─ Analytics service (async)
      ├─ Notification service (async)
      └─ Fraud detection (async)

T+160ms: Return response
  └─→ HTTP 200 {session_id: abc123, user: {name: "Alice"}}

Total latency: 160ms

CloudWatch logs: ✓ Login successful for user_12345 from IP 203.0.113.45
X-Ray trace: ✓ Trace ID: abc123def456; shows database query was slow (85ms)
```

**If Database Slow (Replication Lag Scenario)**
```
T+110ms: Query read replica for user
  └─→ Replication lag: 500ms (network congestion)
  └─→ Old data: {user_id: 12345, email: "old_email@example.com"}

T+115ms: Verification with stale data
  └─→ User recently changed password; replica doesn't have new one
  └─→ Login fails: "Invalid credentials"

Problem: User confused (password is correct, but replica has old data)

Solution (Read-after-write consistency):
  ├─ Application detects password validation failed
  ├─ On retry: Route to primary database (not replica)
  └─ Primary has new password → Login succeeds
```

**At 1 Million Concurrent Users**
```
1M users logging in simultaneously:
  ├─ 1M queued requests
  ├─ NLB distributes to 130 instances
  ├─ Each instance handles 7,700 RPS
  ├─ At 160ms per login, ~1,200 active processing per instance
  │
  └─ Bottleneck analysis:
      ├─ EC2 processing: 160ms (primary)
      ├─ Database: 85ms (inside the 160ms)
      ├─ Network latency: 15ms (both directions)
      │
      └─ Action: Query needs optimization
          └─ Already indexed; can't get faster
          └─ Scale read replicas horizontally
          └─ Users spread across 10 replicas (divide cost)
```

---

## Hands-on Scenarios

### Scenario 1: Implementing Cache-Aside Pattern

**Requirements**
- Cache misses for popular products
- Thundering herd problem during flash sales
- Need idempotent multi-level caching

**Implementation Steps**
```python
from functools import wraps
import redis
import time

cache = redis.Redis(host='elasticache', port=6379)

def cached_with_lock(ttl=3600):
    """Decorator combining cache-aside + lock pattern"""
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            key = f"cache_{f.__name__}_{args}_{kwargs}"
            
            # Try cache
            value = cache.get(key)
            if value:
                return json.loads(value)
            
            # Acquire lock
            lock_key = f"lock_{key}"
            if cache.set(lock_key, "1", ex=5, nx=True):
                try:
                    value = f(*args, **kwargs)
                    cache.setex(key, ttl, json.dumps(value))
                    return value
                finally:
                    cache.delete(lock_key)
            else:
                # Wait for lock to be released
                for _ in range(50):
                    time.sleep(0.1)
                    value = cache.get(key)
                    if value:
                        return json.loads(value)
                # Fallback
                return f(*args, **kwargs)
        
        return wrapper
    return decorator

@cached_with_lock(ttl=3600)
def get_product(product_id):
    return database.query(f"SELECT * FROM products WHERE id = {product_id}")
```

### Scenario 2: Handling Database Failover

**Situation**: Primary RDS fails; application must switch to read replica

**Implementation**
```python
from sqlalchemy import create_engine
from sqlalchemy.pool import NullPool

class FailoverDatabasePool:
    def __init__(self):
        self.primary_engine = create_engine(
            'mysql+pymysql://user:pass@primary-rds:3306/app',
            pool_size=20,
            max_overflow=40
        )
        self.replica_engines = [
            create_engine(f'mysql+pymysql://user:pass@replica-{i}:3306/app')
            for i in range(8)
        ]
        self.current_engine = self.primary_engine
    
    def execute_read(self, query):
        """Execute read with replica failover"""
        try:
            return self.current_engine.execute(query)
        except Exception as e:
            print(f"Primary read failed: {e}")
            # Failover to replica
            self.current_engine = random.choice(self.replica_engines)
            return self.current_engine.execute(query)
    
    def execute_write(self, query):
        """Writes always go to primary"""
        try:
            return self.primary_engine.execute(query)
        except Exception as e:
            print(f"Write failed: {e}")
            raise  # Don't failover writes
```

---

## Interview Questions

### Senior-Level Questions

1. **Explain the trade-offs between strong consistency (RDS) and eventual consistency (DynamoDB) for a 1M user system. When would you choose one over the other?**

   Answer framework:
   - RDS: Use when financial transactions, real-time data critical
   - DynamoDB: Use when scale unlimited needed, eventual consistency acceptable
   - Hybrid: Use RDS for writes (strong), DynamoDB for reads (eventual)

2. **Your system logs 1.1 PB per day. How do you manage this at scale while staying under budget?**

   Answer framework:
   - Sampling (1% of all requests)
   - Structured logging (JSON for easy queries)
   - Filter levels (ERROR + WARN only)
   - Archive old logs to S3 + Glacier
   - Use log aggregationtools (ELK, Splunk)

3. **Design a solution for the "thundering herd" cache problem that occurs when a popular cache key expires.**

   Answer framework:
   - Implement cache-with-lock pattern
   - Use `SET NX` atomic operation
   - stale-while-revalidate approach
   - Background refresh before expiry

4. **How would you implement global traffic routing for a 1M user system across multiple regions with sub-100ms latency requirement?**

   Answer framework:
   - Route 53 geolocation routing
   - CloudFront for content distribution
   - Lambda@Edge for edge processing
   - DynamoDB global tables for data
   - Master-slave replication lag mitigation

5. **You're asked to reduce the monthly AWS bill from $800K to $500K without degrading performance. What optimizations would you prioritize?**

   Answer framework:
   - Spot instances (70% discount): Biggest impact
   - Reserved instances (30% discount): Stable baseline
   - S3 Intelligent-Tiering: Storage cost reduction
   - CloudFront caching: Reduce origin load 80%
   - Database optimization: Sharding, read replicas

6. **Explain the trade-offs between strong consistency (RDS) and eventual consistency (DynamoDB) for a 1M user system. When would you choose each?**

   Answer framework:
   - Strong consistency: RDS for transactions, financial data
   - Eventual consistency: DynamoDB for scalability, high throughput
   - Hybrid approach: RDS for critical data, DynamoDB for non-critical
   - Replication lag: 100-500ms acceptable for most use cases
   - Real-world examples: User profiles (eventual OK), payments (strong required)

7. **Design a blue-green deployment strategy for deploying new application code to 130 EC2 instances handling 13M RPS with zero downtime.**

   Answer framework:
   - Blue environment: Running current version
   - Green environment: New version, fully tested, ready
   - Traffic shift: ALB switches 100% traffic from blue to green
   - Rollback strategy: Keep blue running; revert if green has issues
   - Deployment time: 5-15 minutes for testing + switch
   - Health checks: Ensure green healthy before switching

8. **Walk through your response to a production incident where database replicas are lagging by 5 seconds behind the primary, causing stale data for users.**

   Answer framework:
   - Symptom: User updates profile; sees old data for 5 seconds
   - Root cause: High write load overwhelming replication
   - Immediate action: Implement read-after-write consistency (writes use primary, next read for user uses primary)
   - Long-term: Add read replicas; investigate replication slowness
   - Monitoring: Alert if replication lag > 1 second

9. **Describe how you would troubleshoot and resolve a situation where your cache layer is evicting keys too aggressively, causing only 40% cache hit ratio.**

   Answer framework:
   - Investigate: Check eviction rate (should be near 0)
   - Likely causes: Cache too small, TTL too short, keys accessed sporadically
   - Quick fix: Check max-evicted-keys metric; increase node size
   - Analysis: Review slow-log; identify hottest keys
   - Long-term: Implement cache-warming on startup; adjust TTL based on access patterns
   - Business impact: Every 1% cache improvement = 20% database load reduction

10. **A new feature requires processing 1 million messages/day, where each message triggers database writes, email sends, and API calls. Design this async processing pipeline.**

    Answer framework:
    - System needs: 11.6 messages/sec (1M/day ÷ 86,400 sec)
    - Entry: API receives message → publishes to SQS/SNS
    - Processing: Workers consume messages asynchronously
    - Monitoring: CloudWatch alarms for queue depth, processing latency
    - Failure handling: Dead-letter queues for failed messages
    - Idempotency: Track processed message IDs to prevent duplicates
    - Scaling: Add worker EC2 instances as queue depth increases

---

## Hands-on Scenarios

### Scenario 1: Cache Stampede Prevention

**Problem**: Popular product cache expires at peak traffic (9 AM daily); 10K concurrent requests all miss cache; database overloaded; P99 latency spikes to 500ms.

**Solution**: Implement cache-with-lock pattern using Redis SET NX atomic operation. First thread acquires lock, fetches from database, and caches result. Remaining 9,999 threads wait on lock and use cached result.

**Result**: Cache misses reduced from 10K to 1; database load normalized; P99 latency restored to 50ms.

---

### Scenario 2: Database Replication Lag Inconsistency

**Problem**: User updates balance in RDS primary; immediately reads from replica (200ms lag); sees stale data ($1000 instead of $900); confusion and support tickets.

**Solution**: Implement read-after-write consistency. Mark users who just wrote data in Redis (1-second TTL). Route their next read to primary database. Subsequent reads use replicas after data is replicated.

**Result**: Users see their own changes immediately; other users experience eventual consistency (acceptable); primary load increase minimal (~5%).

---

### Scenario 3: Autoscaling Lag During Spike

**Problem**: Black Friday traffic jumps 3x (100K → 300K RPS). Autoscaling takes 5-10 minutes to provision new instances. Users experience 2+ second latency during lag window.

**Solution**: Use predictive scaling (ML learns patterns; pre-scales 1 hour before predicted peak) + manual override capability + test scaling before major events.

**Result**: Next Black Friday, system pre-scales at 11:55 AM (before noon peak); full capacity ready when traffic arrives; P99 latency remains normal (50ms).

---

### Scenario 4: Regional Failover During Outage

**Problem**: us-east-1 data center power failure. Manual failover takes 15-30 minutes. 1 million users offline.

**Solution**: Automate with Route 53 health checks + Lambda function to promote read replica + auto-scale warm standby region.

**Result**: Automatic failover within 2-3 minutes (vs 15-30 min manual). Users reconnect to us-west-2. Service restored with minimal outage.

---

## Most Asked Interview Questions for Senior Engineers

### Q1: Strong vs. Eventual Consistency
**Key points**: RDS (strong, limited scale), DynamoDB (eventual, unlimited scale), hybrid approach, read-after-write pattern, real-world examples.

### Q2: Sharding Strategy for 650K Writes/Second
**Key points**: Shard key selection, number of shards, cross-shard queries, hot shard problem, distributed transactions, schema changes complexity.

### Q3: Monitoring Strategy for 13M RPS
**Key points**: Alert on user impact (P99 latency, errors), not infrastructure (CPU); dashboard organization; alert routing; avoiding alert fatigue.

### Q4: Cost Optimization ($800K → $500K)
**Key points**: Compute (spot + reserved), database (replicas, DynamoDB), data transfer (caching), logging (sampling), storage (tiering); $238K+ total savings.

### Q5: Incident Response - Database Failover
**Key points**: RPO/RTO definitions; detection; automated response; database promotion; region scaling; recovery steps.

### Q6: Graceful Degradation Under Extreme Load
**Key points**: Circuit breaker pattern; traffic shedding; prioritization (critical vs non-critical); emergency scaling.

### Q7: P99 Latency Bottleneck Analysis
**Key points**: P50 normal ≠ P99 normal; slow queries; GC pauses; hot keys; correlation analysis; indexing + caching solutions.

### Q8: Caching Strategy for 95% Read Ratio
**Key points**: Cache-aside pattern; TTL tuning; eviction policies; stampede prevention; warmup; monitoring hit ratio.

### Q9: Geo-Distributed System Design
**Key points**: Route 53 geolocation; CloudFront CDN; Lambda@Edge; multi-region data; complexity tradeoffs.

### Q10: Autoscaling Design for Predictable + Unpredictable Load
**Key points**: Predictive (ML pre-scaling); target-tracking (reactive); hybrid (baseline + burst + emergency); testing; cooldown tuning.

---

## Document Information

- **Last Updated**: April 2026  
- **Version**: 2.5 - Complete Guide with Hands-on Scenarios + Interview Prep
- **Difficulty**: Senior/Architect Level  
- **Time Investment**: 6-8 hours reading + 2-3 hours hands-on practice
- **Audience**: DevOps Engineers with 5-10+ years experience
- **Coverage**: 13 subtopics, 4 hands-on scenarios, 10 interview questions, 50+ code examples, 30+ diagrams

### How to Use This Guide

1. **First Pass (2 hours)**: Skim all sections; understand architecture blocks and layers
2. **Deep Dive (2 hours)**: Focus on weak areas; study code examples closely
3. **Hands-On (2-3 hours)**: Implement Scenario 1 & 2 in your environment; test solutions
4. **Interview Prep (1-2 hours)**: Practice answering questions out loud; time yourself
5. **Reference**: Bookmark; use for future architecture decisions; share with team
6. **Advanced**: Read hands-on scenarios multiple times; understand "why" behind each decision

### Key Takeaways

✓ **Concurrency ≠ Throughput**: 1M concurrent users = ~13M RPS (not 1M RPS)
✓ **Caching is critical**: 95% hit ratio reduces database load 20x; implement with distributed locking
✓ **Horizontal scaling has lag**: Autoscaling takes 5-10 minutes; use predictive scaling for known peaks
✓ **Choose consistency strategically**: RDS for critical/financial (strong), DynamoDB for eventual (scale), hybrid for true scale
✓ **Monitor user impact, not infrastructure**: Alert on P99 latency, error rates; don't alert on CPU 75%
✓ **Cost optimization is architectural**: Spot instances + reserved instances + smart caching saves 35-40% without downtime
✓ **Automate failover**: Route 53 + Lambda provides 2-3 minute RTO (vs 15-30 min manual)
✓ **Idempotency prevents disasters**: Async processing retries; always track processed message IDs

---
