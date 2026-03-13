# Linux Administration: High Availability, Observability, Disaster Recovery & Production Troubleshooting
## Senior DevOps Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [High Availability & Reliability](#high-availability--reliability)
4. [Observability & Monitoring Integration](#observability--monitoring-integration)
5. [Disaster Recovery & Backup Strategies](#disaster-recovery--backup-strategies)
6. [Production Troubleshooting Methodologies](#production-troubleshooting-methodologies)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

High Availability (HA), Observability, Disaster Recovery (DR), and Production Troubleshooting form the backbone of enterprise-grade Linux systems in modern DevOps environments. These interconnected disciplines ensure that systems remain operational, maintainable, and recoverable in the face of failures, degradation, and unexpected incidents.

At the senior level, this isn't about implementing individual tools—it's about designing resilient architectures that gracefully degrade under stress, providing visibility into system behavior in real-time, recovering from catastrophic failures with minimal data loss, and systematically diagnosing and resolving production incidents before they impact business metrics.

### Why It Matters in Modern DevOps Platforms

**Business Impact:**
- **Availability SLOs/SLAs**: Modern SaaS and enterprise applications require 99.9% to 99.99% uptime. This directly translates to revenue protection and customer trust
- **MTTR (Mean Time to Recovery)**: The cost of downtime is measured in seconds and minutes. A 15-minute outage across a platform serving millions can cost hundreds of thousands of dollars
- **Observability Compliance**: Regulatory requirements (SOC 2, HIPAA, PCI-DSS) mandate audit trails, traceability, and incident documentation
- **Disaster Recovery RTO/RPO**: Business continuity and disaster recovery aren't optional—they're strategic imperatives

**Technical Complexity:**
- Microservices architectures with 50-200+ interdependent services require sophisticated monitoring
- Container orchestration platforms (Kubernetes) introduce dynamic infrastructure that traditional monitoring struggles to capture
- Distributed tracing across service boundaries is essential for diagnosing latency and failures
- Backup and recovery must be automated, tested, and documented to be trustworthy

### Real-World Production Use Cases

1. **E-commerce Platform During Black Friday**
   - HA prevents cascading failures when traffic spikes 10x normal levels
   - Observability detects database connection pool exhaustion within seconds
   - Automatic failover switches to standby infrastructure before customers notice
   - Incident post-mortems use distributed traces to identify the root cause (a poorly indexed query)

2. **Financial Services Batch Processing**
   - Daily reconciliation batch jobs must complete within a 4-hour window
   - Monitoring detects when a job deviates from normal resource consumption patterns
   - DR procedures ensure restarts don't duplicate transactions or lose partial results
   - Audit logs prove to regulators that all transactions were processed correctly

3. **SaaS Multi-Tenant Application**
   - Tenant isolation requires careful HA design so one customer's failure doesn't cascade
   - Custom exporters track per-tenant metrics to prevent one tenant from hogging resources
   - Backup encryption and offsite replication protect sensitive customer data
   - Structured logging enables rapid diagnosis of customer-specific issues

4. **Healthcare Provider Infrastructure**
   - Patient record systems have 99.99% uptime requirements (network-critical)
   - HIPAA compliance requires immutable audit trails and encryption at rest/in transit
   - Disaster recovery includes geographic separation (different data centers) with defined RTOs
   - Ransomware protection strategies include immutable backups and air-gapped recovery systems

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer (HA)                        │
│                  (Active-Active Config)                      │
└────────────────┬────────────────┬────────────────────────────┘
                 │                │
        ┌────────▼────────┐     ┌─────▼──────────────┐
        │  Compute Tier   │     │  Compute Tier      │  ← Clustering & Failover
        │  (App Servers)  │     │  (Standby/Active)  │
        │  Monitoring     │     │  Monitoring        │
        └────────┬────────┘     └─────┬──────────────┘
                 │                    │
        ┌────────▼────────────────────▼────────┐
        │    Storage Layer (Shared/Replicated) │  ← HA Design
        │    - Database (Primary/Secondary)    │
        │    - Cache Layer (Redis Cluster)     │
        │    - Shared Filesystems (NFS/GlusterFS)
        └────────┬─────────────────────────────┘
                 │
        ┌────────▼────────────────────────────────┐
        │   Observability Stack                   │
        │   - Prometheus/Node Exporter ─────┐    │
        │   - ELK Stack (Logs) ──────────────┤────┤ ← Monitoring
        │   - Jaeger (Traces) ───────────────┤────┤
        │   - Grafana (Visualization) ────────┐   │
        └────────┬────────────────────────────────┘
                 │
        ┌────────▼────────────────────────────────┐
        │   Backup & DR Infrastructure           │
        │   - Primary Backup (Local/Cloud) ──┐   │
        │   - Offsite Replication ───────────┼───┤ ← DR
        │   - Encrypted Snapshots ───────────┼───┤
        │   - Point-in-Time Recovery ────────┐   │
        └────────────────────────────────────────┘
```

---

## Foundational Concepts

### Key Terminology

**Availability & Reliability Terms:**

| Term | Definition | What It Means in Practice |
|------|-----------|---------------------------|
| **RTO (Recovery Time Objective)** | Maximum acceptable time to restore service after failure | If RTO is 1 hour, you have 60 minutes to get systems back online |
| **RPO (Recovery Point Objective)** | Maximum acceptable data loss measured in time | If RPO is 15 minutes, you can lose up to 15 minutes of transactions |
| **MTTR (Mean Time to Recovery)** | Average time to fix a failed system | Metric to track incident response effectiveness |
| **MTBF (Mean Time Between Failures)** | Statistical average time before next failure | Drives maintenance scheduling and HA investment |
| **Failover** | Automatic switch to redundant system when primary fails | Active-passive: switch to standby; Active-active: seamless redistribution |
| **Failback** | Return to primary system after repair | Can be manual or automatic; carries risk of thrashing if primary instable |
| **SLO (Service Level Objective)** | Internal target for availability | "99.95% availability across all systems" |
| **SLA (Service Level Agreement)** | Contractual commitment with penalties for violation | "Guaranteed 99.9% uptime; 30% credit if lower" |

**Observability & Monitoring Terms:**

| Term | Definition | Example |
|------|-----------|---------|
| **Metric** | Quantitative measurement point-in-time or over interval | CPU usage, request latency (p95), queue depth |
| **Log** | Timestamped event record with context | "2026-03-13T14:32:51Z ERROR: Database connection timeout" |
| **Trace** | Request path through distributed system showing latency | Trace request from API → DB → Cache showing 250ms total |
| **Cardinality** | Number of unique combinations of label/tag values | If service has 1000 instances × 10 endpoints = 10k cardinality |
| **Exporter** | Process that exposes metrics in Prometheus format | Node Exporter exposes `node_cpu_seconds_total`, `node_memory_MemFree_bytes` |
| **Scrape** | Prometheus pulling metrics from exporter at interval | Every 15 seconds, Prometheus fetches metrics from each exporter |
| **Alerting** | Automatic notification when conditions breached | "PagerDuty alert when p99 latency > 500ms for 5 minutes" |
| **Cardinality Explosion** | Unbounded label values causing memory/query performance issues | Using unique user IDs as labels instead of customer IDs → OOM crash |

**Disaster Recovery & Backup Terms:**

| Term | Definition | Tradeoff |
|------|-----------|----------|
| **Full Backup** | Complete copy of all data | Resource intensive; fast restore; large storage footprint |
| **Incremental Backup** | Only changes since last backup | Fast backup; complex restore; requires chain of backups |
| **Differential Backup** | Changes since last full backup | Middle ground; moderately fast backup; linear restore dependency |
| **Snapshot** | Point-in-time filesystem state (usually copy-on-write) | Fast creation; enables instant restore; storage overhead |
| **Immutable Backup** | After creation, cannot be modified/deleted for period | Ransomware protection; prevents accidental deletion; compliance friendly |
| **3-2-1 Backup Rule** | 3 copies of data, 2 different media, 1 offsite | Gold standard; protects against media failure, site disaster, malware |
| **WORM (Write Once, Read Many)** | Data written once, read unlimited times | Immutability enforced by hardware/object storage; no deletion |

**Troubleshooting Terms:**

| Term | Definition | When Used |
|------|-----------|-----------|
| **Root Cause Analysis (RCA)** | Identification of underlying cause, not just symptoms | Post-mortem: "We added 2000 users but didn't scale database" |
| **Blameless Post-Mortem** | Incident review focusing on systems, not individuals | Encourages learning; prevents defensive behavior |
| **Anomaly Detection** | Identification of behavior deviation from baseline | Alerting on "request latency is 3σ above normal" |
| **Correlation** | Finding common factors in multiple failures | "All failed servers had Java process restart 30 seconds prior" |
| **Causation** | Proving that one event caused another | Hard to prove; correlation often mistaken for causation |

---

### Architecture Fundamentals

#### 1. The Reliability Pyramid

Enterprise systems must be designed in layers, with each layer contributing to overall reliability:

```
                    ┌──────────────────┐
                    │   Observability  │  (Can you see problems?)
                    └────────┬─────────┘
                    ┌────────▼─────────┐
                    │  Alerting & On-  │  (Do you know immediately?)
                    │     Call         │
                    └────────┬─────────┘
                    ┌────────▼─────────┐
                    │  Rapid Recovery  │  (Can you fix it fast?)
                    │  & Automation    │
                    └────────┬─────────┘
                    ┌────────▼─────────┐
                    │  Redundancy &    │  (Does system degrade gracefully?)
                    │  Failover        │
                    └────────┬─────────┘
                    ┌────────▼─────────┐
                    │  Loose Coupling  │  (Can components fail independently?)
                    │  & Isolation     │
                    └────────┬─────────┘
                    ┌────────▼─────────┐
                    │  Immutable       │  (Can you return to known-good state?)
                    │  Infrastructure  │
                    └──────────────────┘
```

**Key principle**: You cannot skip layers. A system with perfect observability but no redundancy is still unavailable. A system with perfect redundancy but no observability is unavailable AND undiagnosable.

#### 2. Failure Domains

Systems fail in nested domains. High availability requires understanding these boundaries:

```
Failure Modes by Domain:
├─ Hardware Failures
│  ├─ Disk: Sector failure, complete drive failure, controller failure
│  ├─ CPU: Thermal throttling, core failure
│  ├─ Memory: Single bit flip (ECC catches), full DIMM failure
│  └─ NIC: Speed degradation, complete loss of connectivity
│
├─ Datacenter Failures
│  ├─ Power: PSU failure, UPS exhaustion, utility provider outage
│  ├─ Cooling: AC failure, hot spot development
│  ├─ Network: TOR switch failure, link failure
│  └─ Building: Fire, flooding, natural disaster
│
├─ Software Failures
│  ├─ Application: Memory leak, deadlock, exception crash
│  ├─ OS: Kernel panic, runaway process consuming CPU
│  ├─ Library: Dependency upgraded with incompatibility
│  └─ Configuration: Typo enabling wrong behavior at scale
│
└─ Dependency Failures
   ├─ External APIs: Rate limits, timeouts, permanent shutdown
   ├─ Databases: Connection pool exhaustion, cascading locks
   ├─ Queues: Backlog accumulation, consumer lag
   └─ Caches: Stampede when cache invalidates
```

HA design must address failures at each level independently. Relying on higher levels to prevent lower-level failures is fragile.

#### 3. The CAP Theorem Applied to HA Systems

When a network partition occurs, you must choose:

- **Consistency** (C): All nodes see same data
- **Availability** (A): System responds to every request
- **Partition Tolerance** (P): System works despite network partition

You cannot have all three. HA systems typically sacrifice immediate consistency:

| System Type | Choice | Example | Tradeoff |
|-------------|--------|---------|----------|
| Strong HA (CP) | Consistency + Partition | PostgreSQL quorum write | Unavailable if quorum lost (worse availability) |
| Eventual Consistency (AP) | Availability + Partition | DynamoDB, Cassandra | Client may see stale data until replication catches up |
| No Partition (CA) | Consistency + Availability | Single-node database | Fails catastrophically if network partition occurs |

**Senior insight**: There's no "best" choice. Your choice depends on business impact of inconsistency vs. unavailability. Financial transactions prefer CP. Social media feeds prefer AP.

#### 4. Observability vs. Monitoring

These terms are often conflated but have distinct meanings:

**Monitoring** = Checking known-good metrics against thresholds
- Structured, rule-based
- "Alert if CPU > 85%"
- Catches known problems
- Reactive

**Observability** = Ability to understand unknown-unknowns from system outputs
- Requires rich data (metrics, logs, traces)
- "Why is latency high when CPU is only 50%?"
- Enables root cause analysis
- Proactive

**Mature systems have both:**
1. Monitoring for baseline health (PagerDuty alerts)
2. Observability for investigation (Grafana dashboards, Jaeger traces, ELK searches)

---

### Important DevOps Principles

#### Principle 1: Everything Fails

This isn't pessimism—it's foundational. Plan for:
- Every piece of hardware to fail
- Every service to go down
- Every backup to be corrupted
- Every failover to fail

This drives architecture decisions:
- Use redundancy (multiple of everything)
- Test recovery procedures (untested backups are worthless)
- Automate failover (humans are too slow)
- Monitor thoroughly (so you know when it happens)

#### Principle 2: Graceful Degradation

When components fail, the system shouldn't fail catastrophically. Design for partial failure:

```
Good Design:
Failed A → System responds slower, with reduced features
         → SLA: 99.9% latency p99 < 500ms becomes 2000ms

Bad Design:
Failed A → Entire system down
         → SLA: 0% availability
```

Example: If your image CDN goes down, cache headers and local fallbacks let the system continue (slowly).

#### Principle 3: Observability as a Feature, Not Afterthought

Mature teams instrument code during development:
- Add logging at decision points
- Export metrics for business logic (not just infrastructure)
- Trace relationships between components
- Build dashboards alongside code

This is NOT work done post-deployment. It's part of the feature.

#### Principle 4: Automation Over Manual Processes

Manual runbooks are failure points:
- Humans make mistakes under pressure
- Procedures drift from documentation
- Scaling manual processes doesn't work

Automate:
- Failover decisions and execution
- Backup verification (restore tests)
- Incident response workflows
- Remediation actions

#### Principle 5: Immutable Infrastructure

Systems should be:
- Deployed as complete units (no in-place changes)
- Disposable (failure = replacement, not repair)
- Versioned (know exactly what's running)

This drastically improves:
- Reproducibility (failure on prod = reproduce on dev)
- Rollback capability (previous version always available)
- Configuration management (no "machine state drift")

---

### Best Practices

#### HA Best Practices

1. **Design for Multi-AZ/Multi-Region from Day 1**
   - NOT an afterthought
   - Assume single AZ will fail (and it regularly does)
   - Synchronous replication to standby increases latency; async increases RPO

2. **Test Failover Regularly**
   - Failover untested in production is untested forever
   - Monthly: Force failover to standby, return to primary
   - Chaos engineering: Kill random instances, observe recovery

3. **Monitor Replication Lag**
   - In async replication, lag is your RPO
   - 10-second lag = up to 10 seconds of data loss acceptable?
   - Alert when lag exceeds SLO

4. **Separate Read and Write Paths**
   - Reads can tolerate slight staleness
   - Writes must be immediately visible on next read
   - Multiple read replicas can scale reads without impacting write latency

#### Observability Best Practices

1. **Cardinality Control**
   - High cardinality labels explode storage/query performance
   - Don't use: user IDs, request IDs, timestamps as labels
   - Do use: service name, instance role, customer tier as labels
   - Use annotations/logs for high-cardinality details

2. **Standardize Naming Conventions**
   - Prometheus metric names: `app_http_requests_total`, `app_db_connection_errors_total`
   - Log field names: `@timestamp`, `log.level`, `service.name` (ECS standard)
   - Trace names: `GET /api/users/{id}` (with ID templated)

3. **Alert on Symptoms, Not Causes**
   - Bad: Alert on disk usage > 80% (cause)
   - Good: Alert on write latency > 100ms (symptom from customer POV)
   - Causes vary; symptoms are consistent

4. **Use Structured Logging**
   - Bad: "Error processing request"
   - Good: `{"error": "database_connection_timeout", "user_id": 123, "retry_count": 3, "duration_ms": 5000}`
   - Enables aggregation, searching, correlation

#### Disaster Recovery Best Practices

1. **3-2-1 Rule (Mandatory)**
   - 3 copies of critical data
   - 2 different storage media (e.g., disk + object storage)
   - 1 offsite copy (different geographic region)
   - Regularly verify copies are restorable

2. **Automate Everything**
   - Snapshots: scheduled automatically
   - Offsite replication: continuous, not manual
   - Restore tests: weekly automated dry-runs
   - Encryption keys: distributed separately from data

3. **Document and Test RPO/RTO**
   - RTO 4 hours? Ensure you can actually restore in 4 hours
   - RPO 1 hour? Test that backup cycle completes in < 1 hour
   - Include network time, decryption time, verification time

4. **Encryption with Key Off-site**
   - Backup encrypted? Where are keys?
   - Keys in same location as backups? That's not protection against theft/ransomware
   - Enterprise: Use HSM in different datacenter, or cloud key management (AWS KMS, Azure Key Vault)

#### Production Troubleshooting Best Practices

1. **Establish Baseline Metrics**
   - You cannot troubleshoot "slow" without knowing fast baseline
   - Collect metrics during normal load 24/7
   - Use percentiles (p50, p95, p99) not averages
   - Store baseline for comparison during incidents

2. **Standardize Troubleshooting Process**
   - Runbooks document steps; follow them during incidents
   - Measure in minutes: MTTR is time from alert to resolution
   - Use oncall rotation with escalation policy

3. **Preserve Evidence**
   - Before restarting failed service, collect logs/dumps
   - Save heap dumps, core dumps, packet traces
   - Analysis happens post-incident; evidence is ephemeral

4. **Blameless Post-Mortems**
   - Focus: "What systems/processes failed?" not "Who failed?"
   - Output: Changes to monitoring, automation, documentation to prevent recurrence
   - If same incident happens twice, process was inadequate

---

### Common Misunderstandings

#### Misunderstanding 1: "We Have HA, So Backups Are Optional"

**Wrong.** HA and backups serve different purposes:

| Failure Type | HA Handles | Backups Handle |
|--------------|-----------|-----------------|
| Single disk failure | ✓ (replicas available) | ✓ (corrupt data not replicated) |
| Application bug corrupting data | ✗ | ✓ (restore to pre-corruption point) |
| Ransomware encrypting all copies | ✗ | ✓ (immutable offsite copy) |
| Accidental DELETE query | ✗ | ✓ (point-in-time recovery) |
| Multi-AZ failure | ✗ (all AZs fail) | ✓ (recovery from different region) |

**Reality**: Enterprise needs BOTH. HA prevents downtime; backups prevent data loss.

#### Misunderstanding 2: "High Cardinality Labels Are Fine; Just Buy More Storage"

**Wrong.** Cardinality explosion causes:
- Query timeouts (Prometheus struggles with millions of series)
- Memory exhaustion (metrics server OOM)
- Slow scrapes (10-second scrape interval becomes 60+ seconds)

This is not a storage problem; it's a **fundamental performance problem**. More storage doesn't fix it.

**Example**: Using pod IP as label when you have 5000 pods:
- 5000 pods × 50 metrics = 250,000 time series
- 250,000 × 1 week of data × ~1KB per point = 1.75 TB storage
- Queries checking "how many pods in a bad state?" must aggregate 5000 series → timeout

#### Misunderstanding 3: "Log Aggregation Is for Compliance; It's Not Useful for Troubleshooting"

**Wrong.** Logs are critical for troubleshooting AND compliance:
- Metrics tell you *that* something is wrong; logs tell you *why*
- Distributed traces show *how* a request flowed; logs show *what* each component did
- Post-mortems require logs; they're the evidence trail

System without good logging:
- Alert: "Database queries are slow"
- Investigation: Blind (no query logs, no slow query log; just raw metrics)
- Resolution: Guess and restart (50/50 chance it helps)

#### Misunderstanding 4: "We'll Handle Failover Manually When It Happens"

**Wrong.** Manual failover:
- Takes 10+ minutes (human reaction time, decision-making, execution)
- Relies on person being available (2 AM, person on vacation?)
- Error-prone (typos, wrong service stopped, forgot step 5)

Modern HA requires **automated failover**:
- Health checks detect failure < 30 seconds
- Failover decision made automatically
- New routes established/traffic redirected automatically
- Human only involved for post-incident investigation

#### Misunderstanding 5: "We Don't Need Distributed Tracing; We Have Logs and Metrics"

**Wrong.** Each tells part of the story:

Scenario: API latency spiked to 5 seconds (p99)
- **Metrics** tell you: database queries went from 50ms to 2000ms
- **Logs** tell you: "Database query took 2000ms"
- **Traces** tell you: 
  - Client → API gateway (5ms)
  - API gateway → service A (100ms, 1 retry)
  - Service A → service B (2000ms)
  - Service B → cache (10ms)
  - Service B → database (1900ms) ← **This is where time was spent**

Without traces, you see "database slow" but don't know why. With traces, you see the exact request path and timing breakdown.

---

### Key Metrics and Their Meanings

#### For HA Systems:

| Metric | Good Range | Warning | Critical |
|--------|-----------|---------|----------|
| Replication Lag (async systems) | < 100ms | > 1 sec | > 30 sec |
| Failover Time (failure detection + switchover) | < 1 min | 5-10 min | > 10 min |
| Health Check Interval | 10-30 sec | 1 min+ | 5+ min |
| Quorum Size (for consensus HA) | Odd (3, 5, 7) | Even (unstable) | Too large (slow) |

#### For Observability:

| Metric | Good Range | Warning | Critical |
|--------|-----------|---------|----------|
| Metrics Scrape Success Rate | 99%+ | 95-99% | < 95% |
| Log Ingestion Latency | < 2 sec | 5-10 sec | > 30 sec |
| Trace Sampling Rate (at scale) | 0.1-1% | 0.01% (too sparse) | 100% (Goggin) |
| Alert Response Time (detected to notified) | < 1 min | 5 min | > 10 min |

#### For Disaster Recovery:

| Metric | Good Range | Warning | Critical |
|--------|-----------|---------|----------|
| Backup Completion Time | < RPO/2 | Approaching RPO | Exceeds RPO |
| Offsite Sync Lag | < 1 hour | > 1 hour | > 24 hours |
| Last Successful Restore Test | < 1 month | > 1 month | Never |
| Encryption Key Accessibility | Documented + tested | Undocumented | Unknown/missing |

#### For Production Troubleshooting:

| Metric | Good Range | Warning | Critical |
|--------|-----------|---------|----------|
| MTTD (Mean Time to Detect) | < 1 min | 5 min | > 30 min |
| MTTR (Mean Time to Repair) | < 15 min | 30-60 min | > 2 hours |
| RCA Completion | < 1 week | > 1 week | No RCA done |
| Incident Recurrence Rate | 0 (after fix) | > 2x | > 5x in 6 months |

---

This foundational section provides the conceptual framework for the deeper technical content that follows. Senior engineers use these principles to design systems that remain operational when failure is inevitable.

---

## High Availability & Reliability

### Textual Deep Dive

#### Internal Working Mechanisms

High Availability systems operate on three core mechanics:

**1. Health Checking**
Systems continuously verify that dependencies are responsive:
- **Liveness checks**: Is the process still running? (TCP port listening, HTTP endpoint responding)
- **Readiness checks**: Is the service ready to handle traffic? (Database reachable, cache warm, cache initialized)
- **Custom checks**: Business logic validation (queue depth acceptable, sync lag within SLO)

Health checks are typically implemented as:
```
Application → Health Check Endpoint (every 10-30 seconds)
                     ↓
            Response: 200 OK (healthy) or 503 Service Unavailable (unhealthy)
```

Kubernetes implements this natively:
- **livenessProbe**: Restarts container if fails
- **readinessProbe**: Removes from load balancer if fails
- **startupProbe**: Waits for application startup before checking liveness/readiness

**2. Failover Decision-Making**
Once a component is detected as unhealthy, the system must decide: "Should we failover?"

Naive approach: One failed check → failover immediately
- Problem: Transient issues (network blip) cause unnecessary failover
- Solution: Threshold-based triggering

```
Unhealthy State Detection:
├─ Single check failure → Intermediate state (degraded)
├─ 3 consecutive failures (over 30 seconds) → Marked unhealthy
└─ Leader election triggers failover to standby
```

In quorum-based systems (Pacemaker, etcd):
- Need majority votes to declare failure
- Prevents split-brain (two leaders) if network partitions
- Example with 5 nodes and 2 failed:
  - Remaining 3 have quorum (> 5/2)
  - Can make decisions independently

**3. Traffic Steering & Connection Draining**
Once failover is triggered, traffic must be intelligently redirected:

```
Before Failover:
Client → Load Balancer → [Primary Server] (handling 100 connections)
                       → [Secondary Server] (idle)

Failover Detected:
1. Health check fails on Primary (3 retries over 30 seconds)
2. Load balancer marks Primary as "draining"
3. New connections route to Secondary
4. Existing connections on Primary: wait for completion or kill after timeout
5. After drain period, Primary fully offline

After Failover:
Client → Load Balancer → [Secondary Server] (now active, 100 connections incoming)
                       → [Primary Server - OFFLINE]
```

Connection draining prevents:
- Data corruption (mid-request termination)
- Cascading failures (failed requests affecting downstream systems)
- Bad customer experience (abrupt disconnection)

#### Architecture Role

HA is the **buffer layer** between inevitable failures and service downtime:

```
Failure Event (e.g., server hardware failure)
         ↓
[HA Layer Detects & Acts]
  ├─ Failover to redundant instance
  ├─ Redistribute load
  └─ Update routing
         ↓
Business Logic (application) unaware of failure
         ↓
Observability Layer (detects incident, alerts oncall)
         ↓
Troubleshooting Layer (root cause analysis)
```

**Key insight**: HA is transparent. Applications SHOULDN'T know about failover; they just see "request succeeded."

#### Production Usage Patterns

**Pattern 1: Active-Passive with Manual Failback**
```
Normal Operation:
Primary (Active) → Standby (Passive)
  ↓ Processing traffic
  ↓ Async replication

Failure:
Primary fails
Standby detected failure → becomes Active
Manual failback (after primary repaired):
  ├─ Verify data consistency
  ├─ Promote Primary back to active
  └─ Monitor for replication issues

Use case: Databases with slow failover (RTO > 5 min acceptable)
Risk: Human error during manual failback; data divergence possible
```

**Pattern 2: Active-Active with Automatic Failover**
```
Normal Operation:
Node A ← → Node B
  ↓         ↓
Both processing traffic simultaneously
Sync replication (slightly higher latency, but data safe)

Failure:
Node A fails
Node B detects (health check timeout)
Node B: "I'm quorum (2 nodes, I'm 1, other 1 node dead)"
Node B continues serving both workloads
New request: routes to Node B only
Automatic failback (when Node A recovered):
  ├─ Node A joins cluster
  ├─ Replication catches up in background
  ├─ Traffic gradually redistributed after warmup

Use case: Front-end services, APIs (RTO < 1 min required)
Advantage: No manual intervention; higher uptime
Tradeoff: More complex state management
```

**Pattern 3: Multi-Region with DNS Failover**
```
Normal Operation:
DNS: service.example.com
  ├─ Route53 (AWS) / Traffic Manager (Azure)
  ├─ Health check to Region A primary
  ├─ Health check to Region B primary
  └─ Returns IP of healthy region

User Query:
  User → DNS → "Response: Region A IP address"
  User → Region A → Gets response

Region A Complete Failure:
  Route53 detects: Region A health check timeout
  Route53 updates DNS:
    User → DNS → "Response: Region B IP address"
  User → Region B → Gets response
  
Latency impact: DNS TTL (usually 60 seconds) + detection time (30-60 seconds) = 60-120 seconds
Use case: Critical SaaS, regulated financial systems
RTO: 2-5 minutes acceptable
```

#### DevOps Best Practices

**1. Systemd Restart Policies for HA**

Services in Linux are managed by systemd. HA is achieved by:

```ini
# Critical service that must restart if fails
[Service]
Restart=on-failure           # Restart only on non-zero exit
RestartSec=5s                # Wait 5 seconds between restarts
StartLimitIntervalSec=60     # Measure restart attempts in 60-second window
StartLimitBurst=3            # Allow max 3 restarts per 60 seconds

# If more than 3 restarts in 60 seconds, stop trying
# This prevents restart loops that waste resources
```

Systemd provides:
- Automatic restart (no need for external watchdog)
- Exponential backoff (first restart faster, subsequent slower)
- Integration with other units via `After=`, `Wants=`, `BindsTo=`

**2. Watchdog Implementation**

Watchdogs prevent "zombie" processes (running but unresponsive):

```
Application Process
  ↓
Periodically patting watchdog: "I'm alive"
  ↓
Watchdog: "Last pat 5 seconds ago... still within interval, OK"
  ↓
If no pat for 30 seconds → Watchdog triggers hardware reset
```

In systemd:
```ini
[Service]
Type=notify                  # Application notifies systemd it's ready
WatchdogSec=30s             # systemd watchdog timeout
ExecStart=/usr/bin/myapp    # Must call sd_notify("WATCHDOG=1") periodically
```

Application code:
```c
while (true) {
    process_request();
    sd_notify(0, "WATCHDOG=1");  // Tell systemd "I'm alive"
    usleep(10000000);             // Sleep 10 seconds
}
```

**3. Failover Testing**

Untested failover = failover that doesn't work. Testing strategies:

```bash
# Monthly failover test
1. Document current primary/secondary
2. Force primary to fail (stop service, kill process, etc.)
3. Verify:
   - Secondary detected failure (within SLA)
   - Failover completed (within RTO)
   - No data corruption
   - No duplicate transactions
4. Restore primary to secondary role
5. Document results + deviations
6. Adjust SLOs if needed
```

In production, use chaos engineering:
```bash
#!/bin/bash
# Weekly chaos test: kill random service instances
for i in {1..10}; do
  RANDOM_POD=$(kubectl get pods | shuf -n 1 | awk '{print $1}')
  kubectl delete pod $RANDOM_POD
  sleep 5
  # Verify pod restarted and service still responding
  curl -f https://api.service.local/health || exit 1
done
```

#### Common Pitfalls

**Pitfall 1: Synchronous Replication Kills Performance**

```
Bad: Every write requires confirmation from standby
Write → Primary → Round-trip to Standby → Ack to Client
  Latency: 10ms (Primary) + 10ms network + 10ms standby = 30ms per write

Good: Write confirmed by primary only; standby catches up async
Write → Primary → Ack to Client (5ms)
        → Background thread replicates to Standby (10ms later)
```

In production:
- Strong HA (CP): Synchronous replication required for cluster consensus
- Relaxed HA (AP): Asynchronous replication acceptable, eventual consistency OK

**Pitfall 2: Not Testing Failover "Because It's Too Risky"**

This guarantees failover will fail when you need it:
- Configuration drift (standby config out of date)
- Procedures forgotten/undocumented
- Scripts with hardcoded hostnames that don't exist

Fix: **Scheduled failover testing** (monthly, automated if possible)

**Pitfall 3: Assuming DNS Updates Are Instant**

```
You update DNS: Remove failed server IP
Client caches DNS for 300 seconds (TTL)
Client still sends requests to failed server for 5 minutes

Fix:
- Use low TTL (60 seconds) for critical services
- Implement client-side retry + circuit breaker
- Use service discovery (Consul, etcd) instead of DNS
  when sub-second failover required
```

**Pitfall 4: Forgetting about Stateful Connections**

```
Bad HA for stateful services:
Client (TCP connection) → Load Balancer → Server A

Primary Server A fails → Load balancer fails over to Server B
Client's TCP connection is dead (connected to Server A, now Server B)
Client must reconnect (application break)

Good HA for stateful services:
├─ Session replication: Both servers have same session state
├─ Sticky sessions: Client → same server always (until failover)
├─ Stateless design: Each request self-contained, no server-side session
└─ Connection pooling: App handles reconnect automatically
```

---

### Practical Code Examples

#### Systemd Service with HA Configuration

```ini
# /etc/systemd/system/app.service
[Unit]
Description=Critical Web Application
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=notify
User=appuser
ExecStart=/opt/app/bin/server --config=/etc/app/server.conf
ExecReload=/bin/kill -HUP $MAINPID

# HA Configuration
Restart=on-failure
RestartSec=5s

# Watchdog: if app doesn't call sd_notify every 30 seconds, restart it
WatchdogSec=30s

# Start limit: don't restart more than 3 times in 60 seconds
StartLimitIntervalSec=60
StartLimitBurst=3

# Environment variables
Environment="LOG_LEVEL=info"
Environment="REPLICATE_TO=secondary.internal:5432"

# Resource limits prevent resource exhaustion
LimitNOFILE=65536
LimitNPROC=4096

# Standard output to journald for observability
StandardOutput=journal
StandardError=journal
SyslogIdentifier=app

# Health check integration
ExecStartPost=/opt/app/bin/health-register.sh

[Install]
WantedBy=multi-user.target
```

#### Pacemaker/CoroSync HA Cluster Configuration

```xml
<!-- /etc/corosync/corosync.conf -->
totem {
  version: 2
  cluster_name: production-ha
  transport: udpu
  interface {
    ringnumber: 0
    bindnetaddr: 10.0.1.0
    broadcast yes
    mcastport: 5405
    ttl: 1
  }
  nodelist {
    node {
      ring0_addr: 10.0.1.10
      nodeid: 1
    }
    node {
      ring0_addr: 10.0.1.11
      nodeid: 2
    }
  }
}

quorum {
  provider: corosync_votequorum
  expected_votes: 2
  two_node: 1      # Special handling for 2-node clusters
}

logging {
  timestamp: on
  fileline: off
  to_logfile: yes
  logfile: /var/log/corosync/corosync.log
  to_syslog: yes
}
```

```xml
<!-- /etc/pacemaker/corosync.xml -->
<cib crm_feature_set="3.0.x">
  <configuration>
    <crm_config>
      <cluster_property_set id="cib-settings">
        <nvpair id="stonith-enabled" name="stonith-enabled" value="true"/>
        <nvpair id="no-quorum-policy" name="no-quorum-policy" value="stop"/>
      </cluster_property_set>
    </crm_config>

    <resources>
      <!-- Virtual IP for clients to connect to -->
      <primitive id="vip" class="ocf" provider="heartbeat" type="IPaddr2">
        <instance_attributes id="vip-attrs">
          <nvpair id="ip-addr" name="ip" value="10.0.1.100"/>
          <nvpair id="cidr_netmask" name="cidr_netmask" value="24"/>
        </instance_attributes>
        <operations>
          <op id="vip-monitor" name="monitor" interval="30s"/>
        </operations>
      </primitive>

      <!-- Application service -->
      <primitive id="webapp" class="systemd" type="app">
        <operations>
          <op id="webapp-monitor" name="monitor" interval="30s" timeout="30s" on-fail="restart"/>
        </operations>
      </primitive>

      <!-- Filesystem check on shared storage -->
      <primitive id="shared-storage" class="ocf" provider="heartbeat" type="Filesystem">
        <instance_attributes id="storage-attrs">
          <nvpair id="device" name="device" value="/dev/mapper/shared-lvm"/>
          <nvpair id="directory" name="directory" value="/mnt/shared"/>
          <nvpair id="fstype" name="fstype" value="ext4"/>
        </instance_attributes>
      </primitive>
    </resources>

    <constraints>
      <!-- VIP must be on same node as webapp -->
      <rsc_colocation id="vip-with-webapp" rsc="vip" with-rsc="webapp" score="INFINITY"/>
      <!-- Webapp on same node as shared storage -->
      <rsc_colocation id="webapp-with-storage" rsc="webapp" with-rsc="shared-storage" score="INFINITY"/>
      <!-- VIP starts after shared-storage -->
      <rsc_order id="start-order" first="shared-storage" then="vip" kind="Mandatory"/>
    </constraints>
  </configuration>
</cib>
```

#### Shell Script: Automated Failover Check

```bash
#!/bin/bash
# ha-failover-monitor.sh
# Monitors primary/standby pair and triggers failover if needed

set -euo pipefail

PRIMARY_HOST="primary.internal"
STANDBY_HOST="standby.internal"
HEALTH_CHECK_ENDPOINT="http://localhost:8080/health"
MAX_RETRIES=3
RETRY_INTERVAL=10
FAILOVER_THRESHOLD=30

# Logging with timestamps
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/ha-monitor.log
}

# Check if a host is healthy
check_health() {
    local host=$1
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$host" \
            "curl -sf $HEALTH_CHECK_ENDPOINT > /dev/null" 2>/dev/null; then
            return 0
        fi
        ((retries++))
        [ $retries -lt $MAX_RETRIES ] && sleep $RETRY_INTERVAL
    done
    
    return 1
}

# Promote standby to primary
promote_standby() {
    log "CRITICAL: Primary $PRIMARY_HOST failed. Promoting $STANDBY_HOST"
    
    ssh "$STANDBY_HOST" /opt/ha/bin/promote-to-primary.sh || {
        log "ERROR: Promotion failed"
        return 1
    }
    
    # Update DNS/load balancer to point to new primary
    aws route53 change-resource-record-sets \
        --hosted-zone-id Z123 \
        --change-batch file:///tmp/failover-dns.json
    
    # Notify oncall
    curl -X POST https://hooks.slack.com/... \
        -d '{"text": "Failover occurred: '"$STANDBY_HOST"' is now primary"}'
    
    log "Promotion complete"
}

# Main monitoring loop
main() {
    local consecutive_failures=0
    
    while true; do
        if check_health "$PRIMARY_HOST"; then
            consecutive_failures=0
            log "Primary $PRIMARY_HOST healthy"
        else
            ((consecutive_failures++))
            log "WARNING: Primary health check #$consecutive_failures failed"
            
            if [ $consecutive_failures -ge 3 ]; then
                # Verify standby is healthy before failover
                if check_health "$STANDBY_HOST"; then
                    promote_standby
                    exit 0
                else
                    log "ERROR: Standby also unhealthy, manual intervention required"
                    exit 1
                fi
            fi
        fi
        
        sleep 10
    done
}

main
```

#### Load Balancer Configuration (HAProxy)

```
# /etc/haproxy/haproxy.cfg
global
    maxconn 4096
    log /dev/log local0 notice
    chroot /var/lib/haproxy
    stats socket /var/lib/haproxy/stats

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

# Monitoring endpoint for Kubernetes/orchestration
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats show-legends

# Main application with HA servers
frontend app_front
    bind *:80
    default_backend app_servers

backend app_servers
    balance roundrobin
    option httpchk GET /health HTTP/1.1
    
    # Primary server
    server app1 10.0.1.10:8080 check inter 10s fall 3 rise 2 weight 100
    
    # Standby (weight 0 means receives no traffic until primary fails)
    server app2 10.0.1.11:8080 check inter 10s fall 3 rise 2 weight 0 backup
    
    # Stick session for stateful connections (5 minute expiry)
    cookie SERVERID insert indirect nocache
    
    # Connection draining (30 second timeout before killing connections)
    timeout server-fin 30s
```

---

### ASCII Diagrams

#### HA Failover Timeline

```
Timeline: Primary Server Failure and Failover

T=0s: Normal Operation
┌──────────────────────────────────────────┐
│ Client → [Load Balancer] → Primary       │
│                        → Standby (idle)  │
│ Replication: Primary → Standby: OK       │
└──────────────────────────────────────────┘

T=5s: Primary Hardware Failure
┌──────────────────────────────────────────┐
│ Client → [Load Balancer] → Primary (DEAD)│
│                        → Standby (idle)  │
│ Replication: FAILED                      │
│ Health check: TIMEOUT                    │
└──────────────────────────────────────────┘

T=10s: Replication Lag Alert
┌──────────────────────────────────────────┐
│ Client → [Load Balancer] → Primary (DEAD)│
│                        → Standby (idle)  │
│ Health check attempt #2: TIMEOUT         │
│ Prometheus alert firing:                 │
│   "primary replication lag > 30 seconds" │
└──────────────────────────────────────────┘

T=15s: Failover Decision Made
┌──────────────────────────────────────────┐
│ Load Balancer detects:                   │
│   - 3 consecutive health check failures  │
│   - Standby healthy                      │
│   - Initiating FAILOVER                  │
│                                          │
│ DRAIN: New connections → Standby         │
│ Existing connections: Allow graceful end │
└──────────────────────────────────────────┘

T=20s: Failover Execution
┌──────────────────────────────────────────┐
│ Client → [Load Balancer] → Primary (DEAD)│
│                        → Standby (ACTIVE)│
│                                          │
│ Standby: Promoting to primary role       │
│   ├─ Stop read-only mode                 │
│   ├─ Start accepting writes              │
│   ├─ Update service discovery            │
│   └─ Notify dependent services           │
└──────────────────────────────────────────┘

T=30s: Post-Failover
┌──────────────────────────────────────────┐
│ Client → [Load Balancer] → Former Standby│
│                            (now Primary) │
│                                          │
│ Pagerduty: Alert "Failover Occurred"     │
│ Slack: "#incidents: Failover completed" │
│ Metrics: failover_duration = 25 seconds  │
└──────────────────────────────────────────┘
```

#### Multi-AZ Active-Active Architecture

```
                      DNS Query
                           │
                           ▼
              ┌────────────────────────┐
              │  Route53 Health Check  │
              │  AZ-A: 10.0.1.* (OK)   │
              │  AZ-B: 10.0.2.* (OK)   │
              │  AZ-C: 10.0.3.* (OK)   │
              └──────────┬─────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
    ┌─────────┐    ┌─────────┐    ┌─────────┐
    │  AZ-A   │    │  AZ-B   │    │  AZ-C   │
    │         │    │         │    │         │
    │ ┌─────┐ │    │ ┌─────┐ │    │ ┌─────┐ │
    │ │App 1│ │    │ │App 2│ │    │ │App 3│ │
    │ └──┬──┘ │    │ └──┬──┘ │    │ └──┬──┘ │
    │    │    │    │    │    │    │    │    │
    │ ┌──▼──┐ │    │ ┌──▼──┐ │    │ ┌──▼──┐ │
    │ │Cache│ │    │ │Cache│ │    │ │Cache│ │
    │ └──┬──┘ │    │ └──┬──┘ │    │ └──┬──┘ │
    │    │    │    │    │    │    │    │    │
    │ ┌──▼──────────────────────────────┐ │
    │ │  Shared RDS (Multi-AZ Primary)  │ │
    │ │  All AZs can read/write         │ │
    │ └────────────────────────────────┘ │
    │                                     │
    │  Replication: AZ-A ←→ AZ-B ←→ AZ-C │
    │              (Synchronous)         │
    └──────────────────────────────────────┘
            ↑
    Connected via:
    ├─ Private subnet routing
    ├─ VPC peering (if multi-region)
    └─ AWS Direct Connect (if on-premise)

If AZ-A fails:
  ├─ Route53 removes AZ-A IPs
  ├─ DNS TTL expiry (60 seconds)
  └─ Clients automatically switch to AZ-B or AZ-C

Graceful degradation:
  ├─ 3 AZs: 1 failure = 67% capacity
  ├─ 2 AZs: 1 failure = 50% capacity
  └─ Alerts fire if capacity drops below threshold
```

#### Quorum-Based Failover Decision

```
5-Node Pacemaker Cluster Quorum States

Normal Operation (All 5 nodes online):
┌─────────────────────────────────────────┐
│  Node 1 (Primary) ───RH───→ Node 2      │
│         ↑                   ↓            │
│         └───────RH────────Node 3        │
│                /\                       │
│              RH  RH        ↓             │
│              /    \     Node 4           │
│            Node 5  \      ↓             │
│              ↑     RH    RH              │
│              └─────→ Corosync Ring      │
│                                         │
│ Quorum calculation:                     │
│   Total nodes: 5                        │
│   Required for quorum: 3 (> 5/2)        │
│   Current: 5 online → Have quorum ✓    │
│   Primary: Can make decisions           │
│                                         │
│ All services RUNNING                    │
└─────────────────────────────────────────┘

One Node Fails (4 nodes online):
┌─────────────────────────────────────────┐
│  Node 1 (Primary) ───RH───→ Node 2      │
│         ↑                   ↓            │
│         └───────RH────────Node 3        │
│                /\                       │
│              RH  RH        ↓             │
│              /    \     Node 4           │
│            Node 5  \      ↓             │
│              ↑     RH    RH              │
│              └─────→ Corosync Ring      │
│                                         │
│ [X] Node 5: OFFLINE (failed)             │
│                                         │
│ Quorum calculation:                     │
│   Total nodes: 5                        │
│   Required: 3                           │
│   Current: 4 online → Have quorum ✓    │
│                                         │
│ Pacemaker: "Still have quorum"          │
│   Continue operations normally          │
│   Resource on Node 5 →→→ Restart elsewhere
│ All services RUNNING (with rebalance)  │
└─────────────────────────────────────────┘

Two Nodes Fail (3 nodes online):
┌─────────────────────────────────────────┐
│  Node 1 (Primary) ───RH───→ Node 2      │
│         ↑                   ↓            │
│         └───────RH────────Node 3        │
│                                         │
│ [X] Node 4: OFFLINE (failed)             │
│ [X] Node 5: OFFLINE (failed)             │
│                                         │
│ Quorum calculation:                     │
│   Total nodes: 5                        │
│   Required: 3                           │
│   Current: 3 online → Have quorum ✓    │
│                                         │
│ Pacemaker: "Borderline - have quorum"   │
│   Can continue, but no redundancy       │
│   Reduced capacity; resources moved     │
│ All services RUNNING (overloaded)      │
└─────────────────────────────────────────┘

Three Nodes Fail (2 nodes online):
┌─────────────────────────────────────────┐
│  Node 1 (Primary) ───RH───→ Node 2      │
│                                         │
│ [X] Node 3: OFFLINE (failed)             │
│ [X] Node 4: OFFLINE (failed)             │
│ [X] Node 5: OFFLINE (failed)             │
│                                         │
│ Quorum calculation:                     │
│   Total nodes: 5                        │
│   Required: 3                           │
│   Current: 2 online → NO QUORUM ✗      │
│                                         │
│ Pacemaker: "LOST QUORUM!"               │
│   Cannot make decisions safely          │
│   Reason: Can't distinguish from split  │
│   brain (other partition might have 3+) │
│                                         │
│ ⚠ Services STOPPED                      │
│   Better to stop than corrupt data      │
└─────────────────────────────────────────┘

RH = Redundant Heartbeat (corosync ring)
```

---

## Observability & Monitoring Integration

### Textual Deep Dive

#### Internal Working Mechanisms

Observability systems work by extracting signals from applications and infrastructure:

**1. Metrics Collection (Pull Model)**

Prometheus uses a pull-based model:

```
Scrape Schedule (every 15 seconds):
  ┌─────────────────────────────────────┐
  │ Prometheus Server                    │
  │  └─ Config: scrape_configs {         │
  │       targets: ['10.0.1.10:9090'],   │
  │       interval: 15s                  │
  │     }                                │
  └──────────────┬────────────────────────┘
                 │ HTTP GET /metrics
                 ▼
  ┌─────────────────────────────────────┐
  │ Node Exporter (10.0.1.10:9090)       │
  │  └─ Collect from kernel:             │
  │     /proc/stat → CPU usage           │
  │     /proc/meminfo → Memory           │
  │     /proc/diskstats → Disk I/O       │
  │     /proc/net/dev → Network          │
  │  └─ Expose as text format:           │
  │     node_cpu_seconds_total{...}      │
  │     node_memory_MemAvailable_bytes... │
  └──────────────┬────────────────────────┘
                 │ Response (text format)
                 ▼
  ┌─────────────────────────────────────┐
  │ Prometheus Storage (TSDB)            │
  │  └─ Commit to disk every 30s         │
  │     metrics.db (16KB chunks)         │
  └─────────────────────────────────────┘
```

**2. Log Collection (Push Model)**

ELK/log aggregation uses push or pull:

```
Application → Logging Library
    (Python logging, Java Log4j, Go logrus)
    │
    ├─ Stdout/Stderr
    │   ▼
    │ Filebeat/Fluentd
    │   ├─ Parse logs: "2026-03-13T14:32:51Z ERROR: ..."
    │   ├─ Enrich metadata: {hostname, pod_name, namespace}
    │   └─ Buffer locally (if network down)
    │       ▼
    └──→ Logstash (optional processing)
        ├─ Grok patterns: Extract fields from raw text
        ├─ Mutate: Add/remove/rename fields
        └─ Filter: Only forward certain logs
            ▼
        Elasticsearch
        ├─ Index shards: Distribute data across nodes
        ├─ Replicas: N+1 redundancy
        └─ Retention: Delete logs older than 30 days
            ▼
        Kibana
        ├─ Query DSL: Find logs matching criteria
        ├─ Visualizations: Build dashboards
        └─ Alerting: Fire alerts on log patterns

Example Elasticsearch query:
  {
    "query": {
      "bool": {
        "must": [
          {"match": {"log.level": "ERROR"}},
          {"range": {"@timestamp": {"gte": "now-1h"}}}
        ]
      }
    },
    "size": 10000
  }
```

**3. Distributed Tracing (Request Genealogy)**

Jaeger traces a request across service boundaries:

```
User Request Lifecycle:

Client
  │ POST /api/users
  │
  ├─ Span: "APIGateway.HandleRequest"
  │  ├─ Duration: 250ms
  │  ├─ Status: ok
  │  └─ Tags: {method: POST, path: /api/users}
  │
  ├─ RPCs to services (child spans):
  │  │
  │  ├─ Span: "AuthService.ValidateToken"
  │  │  ├─ Duration: 10ms
  │  │  ├─ Status: ok
  │  │  └─ Logs: {message: "Token valid for user:123"}
  │  │
  │  ├─ Span: "UserService.CreateUser"
  │  │  ├─ Duration: 100ms
  │  │  ├─ Status: ok
  │  │  ├─ Child Span: "Database.INSERT"
  │  │  │  ├─ Duration: 80ms
  │  │  │  ├─ Status: ok
  │  │  │  └─ Tags: {query: "INSERT INTO users ..."}
  │  │  │
  │  │  └─ Child Span: "Cache.Invalidate"
  │  │     ├─ Duration: 5ms
  │  │     └─ Status: ok
  │  │
  │  └─ Span: "NotificationService.SendEmail"
  │     ├─ Duration: 60ms
  │     ├─ Status: error (SMTP timeout)
  │     └─ Error: {type: "TimeoutError"}
  │
  └─ Response to client: 250ms total

Trace Context Header (passed between services):
  X-Trace-ID: a2fb4a1d19956c6f
  X-Parent-ID: 8448eb211c80319c
  X-Span-ID: f7511bf760b3312e

Benefits:
- Pinpoint which service is slow (NotificationService took 60ms)
- See error details (SMTP timeout in NotificationService)
- Track execution path through microservices
```

#### Architecture Role

```
Application Metrics & Logs & Traces
         │
         ├─ Collection Agent (Prometheus scrape, Fluentd push, Jaeger agent)
         │
         ├─ Storage Layer
         │  ├─ Prometheus (time series)
         │  ├─ Elasticsearch (documents/logs)
         │  └─ Jaeger (traces)
         │
         ├─ Query Layer
         │  ├─ PromQL (for metrics)
         │  ├─ Kibana DSL (for logs)
         │  └─ Jaeger UI (for traces)
         │
         └─ Presentation
            ├─ Grafana dashboards (metrics)
            ├─ Kibana dashboards (logs)
            ├─ Jaeger UI (trace view)
            └─ Pagerduty/Slack alerts
```

#### Production Usage Patterns

**Pattern 1: Metrics-Driven Alerting**

Most common pattern in production:

```
Prometheus → Alert Rules → Alertmanager → Slack/PagerDuty

Rules Example:
  - name: HighCPUUsage
    expr: node_cpu_usage > 0.85
    for: 5m
    annotations:
      summary: "Host {{ $labels.hostname }} high CPU"
      
  - name: DatabaseQuerySlow
    expr: mysql_slow_query_duration_seconds > 5
    for: 2m
    annotations:
      summary: "Slow query on {{ $labels.instance }}"

Action: Alert fires → On-call engineer sees notification → Begins investigation
```

**Pattern 2: Logs for Debugging Post-Incident**

Logs are not for real-time alerting; they're for investigation:

```
Incident Timeline:

T=0:  Prometheus alert: "High latency detected (p99 > 500ms)"
      → Pagerduty notifies on-call
      → On-call opens dashboards, sees latency spike

T=5:  On-call investigates Grafana: "What service caused latency?"
      → Sees all services equally slow, but specific endpoint slow

T=10: On-call queries logs in Kibana:
      ```
      severity: ERROR
      @timestamp: [2026-03-13T14:30:00 to 14:35:00]
      endpoint: "/api/expensive-operation"
      ```
      → Finds error logs from expensive operation
      → Logs show "Database connection timeout"

T=15: Hypothesis formed: "Connection pool exhaustion"
      → Checks database server:
      ```bash
      mysql -h db.internal
      mysql> SHOW FULL PROCESSLIST | grep Sleep;
      ```
      → Confirms 500 idle connections (normal max 100)

T=20: Traces (Jaeger) confirm: requests to database hanging
      → Database disk full, causing connection hangs

T=25: Fix applied: clean up old logs on database server
      → Connections drop, latency normalizes
      → Alert resolves

RCA: "Automated log cleanup job deleted wrong directory"
      → Add monitoring: alert on free disk space
      → Fix automation script to validate before deleting
```

**Pattern 3: Observability for Security Events**

Track security-relevant events:

```
Unauthorized access attempts:
  Log pattern: "authentication failed" via SSH
  Metrics: suspicious_login_attempts_total
  Action: Alert if > 5 per minute from one IP
           → Block IP temporarily
           → Alert security team

Privilege escalation attempts:
  Log pattern: "sudo: user not in sudoers"
  Action: Alert on first occurrence
          → Immediate manual review required

Unexpected file modifications:
  File integrity monitoring (auditd)
  Log: "inode changed for /etc/passwd"
  Action: Alert immediately, trigger incident response
```

#### DevOps Best Practices

**1. Cardinality Management**

Cardinality = number of unique combinations of label values.

```
Bad (High cardinality):
  http_requests_total{endpoint, user_id, request_id, service}
  
  With:
  - 100 endpoints
  - 1000000 users
  - Unique request IDs
  - 10 services
  
  Result: 100 × 1000000 × 10 = 1 BILLION metric series
  Storage: 1 billion × 1KB per day = ~1TB/day (unsustainable)
  Query impact: Any query aggregating across users = timeouts

Good (Low cardinality):
  http_requests_total{endpoint, service, status_code}
  
  With:
  - 100 endpoints
  - 10 services
  - 3 status codes (2xx, 4xx, 5xx)
  
  Result: 100 × 10 × 3 = 3000 metric series
  Storage: 3000 × 1KB per day = ~3MB/day
  Queries: Fast, even with complex aggregations

Strategy:
  ├─ Cardinality explosion prevented by label design
  ├─ Use annotations/logs for high-cardinality details
  │  Example: Include user_id in log, not as metric label
  ├─ Use tags in Elasticsearch for high-cardinality log fields
  └─ Monitor cardinality growth: alert if > 10% month-over-month
```

**2. Structured Logging**

JSON logs enable searching, aggregation, and correlation:

```
Bad (Unstructured):
  "2026-03-13T14:32:51Z ERROR Processing request from 192.168.1.1 failed"

Good (Structured):
  {
    "@timestamp": "2026-03-13T14:32:51Z",
    "severity": "ERROR",
    "service": "payment-api",
    "handler": "ProcessPayment",
    "user_id": 12345,
    "amount_cents": 9999,
    "currency": "USD",
    "error_code": "INSUFFICIENT_FUNDS",
    "error_message": "User account balance too low",
    "request_id": "req-abc123",
    "remote_addr": "192.168.1.1",
    "duration_ms": 250
  }

Kibana Query:
  severity:ERROR AND service:payment-api AND error_code:INSUFFICIENT_FUNDS

Result:
  - Find all payment failures due to insufficient funds
  - Correlate with user list (who ran out of funds)
  - Estimate revenue impact
  - Group by currency or region
```

**3. Alerting Best Practices**

Alert fatigue kills observability. Alert on symptoms, not causes:

```
Bad Alerts (Alert Fatigue):
  - CPU > 80%           (causes CPU alerts even when unnecessary)
  - Disk usage > 90%    (false positives during data backups)
  - API response time > 100ms  (triggers during normal load spikes)

Good Alerts (Symptom-Based):
  - User-facing latency p99 > SLO_THRESHOLD for 5 minutes
  - Error rate > 1% for 2 minutes
  - Database connection pool exhaustion (connections > 95)
  - Disk free space < 10% AND usage rate > 100MB/hour (projected to fill)

Alert tuning:
  ├─ Threshold: Set based on actual SLO (not round numbers like "80%")
  ├─ For: Minimum duration before alerting (prevent flapping)
  │  Example: "5m" means condition must be true for 5 consecutive minutes
  ├─ Severity: Critical, Warning, Info (based on impact)
  └─ Aggregation: Group related alerts to prevent notification spam

Example Alert Rule:
  - alert: HighLatency
    expr: histogram_quantile(0.99, http_request_duration_seconds) > 0.5
    for: 5m
    annotations:
      severity: critical
      summary: "API latency above SLO"
      runbook: "https://wiki.company/incident/high_latency"
```

**4. Metrics Naming Convention**

Standardized naming enables cross-service correlation:

```
Prometheus Convention: <namespace>_<subsystem>_<name>_<unit>

Examples:
  - http_requests_total        (counter, total requests)
  - http_request_duration_seconds  (histogram, latency)
  - http_request_size_bytes     (gauge, request payload size)
  - database_connection_errors_total (counter, DB conn failures)
  - database_connections_active (gauge, current connections)
  - cache_hit_ratio            (gauge, % of cache hits)

Standard Units:
  Latency: _seconds
  Size: _bytes
  Count: _total (for counters), or count (for gauges)
  Ratio: none (0-1 range)
  Percentage: none (0-100 range)

Labels (attached to metrics):
  - service: "payment-api"
  - instance: "server-1"
  - method: "GET", "POST"
  - status_code: "200", "500"
  - region: "us-east-1"
  - environment: "production"
```

#### Common Pitfalls

**Pitfall 1: Metrics Without Context**

```
Alert fires: "CPU at 90%"
On-call: "Which service? Which host? Why?"

Better:
Alert includes hostname, service, threshold
Grafana dashboard link shows recent history
Can drill-down to which process consuming CPU
```

**Pitfall 2: Logs Stored Indefinitely (Cost Explosion)**

```
Elasticsearch storing 5 years of logs:
  - 1000 nodes
  - 100KB per node per day = 100GB/day
  - 100GB × 365 × 5 years = 182.5TB
  - Storage cost: ~$10k/month (S3 lifecycle to Glacier)
  
Solution:
  - Hot tier (7 days): Quick search, high cost
  - Warm tier (30 days): Slower search, medium cost
  - Cold tier (90 days, searchable): Very slow, low cost
  - Archive tier (> 1 year, not searchable): Glacier, minimal cost
  
  ILM policy: Auto-transition based on age
```

**Pitfall 3: Scrape Interval Too Aggressive**

```
Misconfiguration: scrape_interval = 5 seconds

Result:
  - Prometheus scrapes 10000 exporters every 5 seconds
  - 10000 × 12 per minute = 120,000 HTTP requests/minute
  - Network saturation
  - Exporter CPU maxed out serving metrics
  - Prometheus disk I/O becomes bottleneck

Better:
  scrape_interval = 30-60 seconds (standard)
  For high-resolution metrics: use push (batched) instead of pull
```

**Pitfall 4: Tracing Sampling Not Configured**

```
Naive approach: Trace every request (sample_rate = 100%)

Result (at Google-scale):
  - 1 million requests/second
  - Each trace stored: ~10KB
  - 1M × 10KB = 10GB/second = 864TB/day
  - Jaeger storage: Bankruptcy

Solution:
  - Probabilistic sampling: sample ~0.1% (1 in 1000 requests)
  - Tail sampling: Sample based on latency/errors
  - Error sampling: 100% of errors, 10% of successes
  - Head sampling: Server-side decision on span ingestion
  
Config for Jaeger:
  samplingServerURL: "http://jaeger-agent:5778/sampling"
  sampler:
    type: probabilistic
    param: 0.001  # Sample 0.1%
```

---

### Practical Code Examples

#### Prometheus Configuration with Scrape Targets

```yaml
# /etc/prometheus/prometheus.yml
global:
  scrape_interval: 30s       # How often to scrape targets
  scrape_timeout: 10s        # Timeout per scrape
  evaluation_interval: 15s   # How often to evaluate rules
  external_labels:
    cluster: 'production'
    environment: 'prod'

# Remote storage (for long-term retention)
remote_write:
  - url: https://prometheus-remote.example.com/api/v1/write
    write_relabel_configs:
      - source_labels: [__name__]
        regex: '.*_bucket|.*_count|.*_sum'  # Only send aggregate histograms
        action: keep

# Alerting rules
rule_files:
  - '/etc/prometheus/rules/*.yml'

# Alert routing
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 'alertmanager.internal:9093'

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    honor_timestamps: true
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (Linux host metrics)
  - job_name: 'node'
    static_configs:
      - targets: ['10.0.1.10:9100', '10.0.1.11:9100', '10.0.1.12:9100']
        labels:
          group: 'production-servers'
    relabel_configs:
      # Extract hostname from target address
      - source_labels: [__address__]
        target_label: hostname
        regex: '([^:]+):.*'
        replacement: '${1}'
    metric_relabel_configs:
      # Drop high-cardinality metrics
      - source_labels: [__name__]
        regex: '.*_info|.*_created'
        action: drop

  # Application metrics (custom app on port 8080)
  - job_name: 'app'
    metrics_path: '/metrics'
    scrape_interval: 15s      # More frequent for app metrics
    static_configs:
      - targets: ['10.0.1.20:8080']
        labels:
          app: 'payment-service'
          environment: 'production'
    relabel_configs:
      # Relabel instance to include port
      - source_labels: [__address__]
        target_label: instance
        regex: '([^:]+):\d+'
        replacement: '${1}'

  # Database metrics (MySQL exporter)
  - job_name: 'mysql'
    static_configs:
      - targets: ['10.0.2.10:9104']
        labels:
          database: 'main-db'

  # Kubernetes API Server (if deploying with K8s)
  - job_name: 'kubernetes-apiservers'
    kubernetes_sd_configs:
      - role: endpoints
    scheme: https
    tls_config:
      ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
    relabel_configs:
      - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
        action: keep
        regex: 'default;kubernetes;https'
```

#### Alert Rules for Critical Services

```yaml
# /etc/prometheus/rules/production.yml
groups:
  - name: application_alerts
    interval: 30s
    rules:
      # High latency alert
      - alert: HighAPILatency
        expr: |
          histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{service="payment-api"}[5m])) > 0.5
        for: 5m
        labels:
          severity: critical
          service: payment-api
        annotations:
          summary: "{{ $labels.service }} high latency (p99 > 500ms)"
          description: "Service {{ $labels.service }} on {{ $labels.instance }} has p99 latency of {{ $value }}</s"
          runbook: "https://wiki.internal/incident/high-latency"
          dashboard: "https://grafana.internal/d/payment-api"

      # Error rate alert
      - alert: HighErrorRate
        expr: |
          rate(http_requests_total{status_code=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.01
        for: 2m
        labels:
          severity: critical
          service: "{{ $labels.service }}"
        annotations:
          summary: "{{ $labels.service }} error rate > 1%"
          description: "Error rate is {{ $value | humanizePercentage }}"
          slack_channel: "#incidents"

      # Database connection pool exhaustion
      - alert: DBConnectionPoolExhausted
        expr: |
          mysql_global_status_threads_connected / mysql_global_variable_max_connections > 0.95
        for: 1m
        labels:
          severity: critical
          component: database
        annotations:
          summary: "Database at {{ $labels.instance }} connection pool nearly full"
          description: "{{ $value | humanizePercentage }} of max connections in use"
          runbook: "https://wiki.internal/incident/db-connection-pool"

      # Memory usage alert
      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          component: system
        annotations:
          summary: "High memory usage on {{ $labels.hostname }}"
          description: "Memory usage is {{ $value | humanize }}%"

      # Disk space alert with projection
      - alert: DiskSpaceRunningOut
        expr: |
          (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) < 0.1
          AND
          (rate(node_filesystem_size_bytes{mountpoint="/"}[1h]) - rate(node_filesystem_avail_bytes{mountpoint="/"}[1h])) > 1073741824  # > 1GB/hour
        for: 10m
        labels:
          severity: critical
          component: disk
        annotations:
          summary: "Disk space running out on {{ $labels.hostname }}"
          description: "{{ $value | humanize }}% free, projected to fill within 24 hours"

      # Certificate expiration alert
      - alert: CertificateExpiringSoon
        expr: |
          ssl_cert_not_after - time() < 86400 * 30  # Expires in < 30 days
        for: 1h
        labels:
          severity: warning
          component: security
        annotations:
          summary: "SSL certificate expiring soon for {{ $labels.hostname }}"
          description: "{{ $value | humanize }} days until expiration"
```

#### Shell Script: Custom Metrics Exporter

```bash
#!/bin/bash
# custom-app-metrics.sh
# Exposes custom application metrics in Prometheus format
# Designed to be scraped by Prometheus at :8080/metrics

PORT=8080
METRICS_FILE="/tmp/app_metrics.txt"

# Function to generate Prometheus formatted output
generate_metrics() {
    local timestamp=$(date +%s)000
    cat > "$METRICS_FILE" << EOF
# HELP app_requests_processed_total Total requests processed
# TYPE app_requests_processed_total counter
app_requests_processed_total{service="payment-api",status_code="200"} 1234567
app_requests_processed_total{service="payment-api",status_code="400"} 1234
app_requests_processed_total{service="payment-api",status_code="500"} 5678

# HELP app_request_duration_seconds Request latency histogram
# TYPE app_request_duration_seconds histogram
app_request_duration_seconds_bucket{service="payment-api",le="0.1"} 500000
app_request_duration_seconds_bucket{service="payment-api",le="0.5"} 950000
app_request_duration_seconds_bucket{service="payment-api",le="1.0"} 1200000
app_request_duration_seconds_bucket{service="payment-api",le="+Inf"} 1241245
app_request_duration_seconds_sum{service="payment-api"} 125000
app_request_duration_seconds_count{service="payment-api"} 1241245

# HELP app_active_connections Current number of active connections
# TYPE app_active_connections gauge
app_active_connections{service="payment-api"} 45
app_active_connections{service="user-api"} 123
app_active_connections{service="auth-service"} 67

# HELP app_db_query_duration_seconds Database query latency
# TYPE app_db_query_duration_seconds histogram
app_db_query_duration_seconds_bucket{operation="INSERT",le="0.1"} 450000
app_db_query_duration_seconds_bucket{operation="INSERT",le="0.5"} 490000
app_db_query_duration_seconds_bucket{operation="INSERT",le="1.0"} 500000
app_db_query_duration_seconds_sum{operation="INSERT"} 25000
app_db_query_duration_seconds_count{operation="INSERT"} 500000

# HELP app_cache_hits_total Cache hits counter
# TYPE app_cache_hits_total counter
app_cache_hits_total{cache_name="session"} 500000

# HELP app_cache_misses_total Cache misses counter
# TYPE app_cache_misses_total counter
app_cache_misses_total{cache_name="session"} 50000

# HELP app_background_job_duration_seconds Background job completion time
# TYPE app_background_job_duration_seconds histogram
app_background_job_duration_seconds_bucket{job_name="nightly-backup",le="300"} 20
app_background_job_duration_seconds_bucket{job_name="nightly-backup",le="600"} 28
app_background_job_duration_seconds_bucket{job_name="nightly-backup",le="+Inf"} 30
app_background_job_duration_seconds_sum{job_name="nightly-backup"} 12345
app_background_job_duration_seconds_count{job_name="nightly-backup"} 30

# HELP app_up Application is up
# TYPE app_up gauge
app_up{service="payment-api"} 1
EOF
}

# HTTP server using socat
start_metrics_server() {
    while true; do
        generate_metrics
        
        {
            echo -ne "HTTP/1.1 200 OK\r\n"
            echo -ne "Content-Type: text/plain; version=0.0.4\r\n"
            echo -ne "Content-Length: $(wc -c < "$METRICS_FILE")\r\n"
            echo -ne "\r\n"
            cat "$METRICS_FILE"
        } | socat - TCP4-LISTEN:$PORT,reuseaddr,fork
    done
}

# Health check endpoint
health_check() {
    if curl -sf "http://localhost:8080/metrics" > /dev/null; then
        echo "✓ Metrics endpoint healthy"
        return 0
    else
        echo "✗ Metrics endpoint failed"
        return 1
    fi
}

# Graceful shutdown
cleanup() {
    echo "Shutting down metrics server..."
    pkill -P $$
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main
echo "Starting metrics server on port $PORT"
start_metrics_server
```

#### Grafana Dashboard JSON (Partial Example)

```json
{
  "dashboard": {
    "title": "Payment API - Production Monitoring",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate (by Status Code)",
        "targets": [
          {
            "expr": "rate(http_requests_total{service=\"payment-api\"}[5m])",
            "legendFormat": "{{ status_code }}"
          }
        ],
        "type": "graph"
      },
      {
        "id": 2,
        "title": "Latency (p50, p95, p99)",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket{service=\"payment-api\"}[5m]))",
            "legendFormat": "p50"
          },
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{service=\"payment-api\"}[5m]))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{service=\"payment-api\"}[5m]))",
            "legendFormat": "p99"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

---

### ASCII Diagrams

#### Observability Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    Application Services                          │
│                                                                  │
│  ┌─────────────────┐    ┌──────────────────┐    ┌────────────┐  │
│  │  Payment API    │    │   User Service   │    │ Auth Svc   │  │
│  │                 │    │                  │    │            │  │
│  │ stdout logs ────┼────┼──► Fluent Bit ───┼────┼─────┐      │  │
│  │ @metrics ───────┼────┼────────────────────────┼─────┼──┐   │  │
│  │ (port 8080)     │    │                  │    │  |  │  │   │  │
│  │ /metrics        │    │ :9100 (exporter) │    │  |  │  │   │  │
│  └─────────────────┘    └──────────────────┘    └────────────┘  │
│        │                                              │       │   │
│  HTTP GET                                           │       │   │
│  POST → Jaeger Agent                              │   ▼   │   │
│        (tracing)                                    │       │   │
│                                                     │       │   │
└─────────────────────────────────────────────────────┼───────┼───┘
              │                                        │       │
              │                         Fluent Bit ────       │
              │                         (log ShipR)          │
              │                                │              │
              │ /metrics HTTP               │              │
              │ (polls every 30s)           ▼              │
              │                    ┌──────────────────┐   │
              │ Jaeger spans ─────► │  Elasticsearch  │   │
              │                     │                │   │
              │                     │ (indexes logs) │   │
              │                     └────────────────┘   │
              │                                │         │
   ┌──────────▼──────────┐                    │         │
   │   Prometheus        │                    │         │
   │                     │                    │         │
   │ - Scrapes targets   │                    │         │
   │ - TSDB storage      │                    │         │
   │ - Rules evaluation  │      ┌─────────────▼──────┐ │
   │ - Alert routing     │      │    Kibana UI       │ │
   └──────────┬──────────┘      │                    │ │
              │                 │ - Search logs      │ │
              │                 │ - Build dashboards │ │
    ┌─────────▼──────────┐      │ - Set alerts       │ │
    │  Grafana           │      └────────────────────┘ │
    │  Dashboards &      │                             │
    │  Alert firing      │      ┌────────────────────┐ │
    └────────┬───────────┘      │   Jaeger UI        │ │
             │                  │                    │ │
             ▼                  │ - Trace visualization
    ┌──────────────────┐        │ - Latency analysis │ │
    │  Alertmanager    │        │ - Error tracking   │ │
    │  Routes alerts   │        └────────────────────┘ │
    └────────┬─────────┘
             │
    ┌────────▼──────────────┐
    │  PagerDuty/Slack      │
    │  Notify on-call       │
    └───────────────────────┘
```

#### Metrics Collection Timing (15-second scrape interval)

```
Time Progression (seconds):

T=0   ┌──────────────────────────────────────────────┐
      │ Prometheus Schedule:                         │
      │ "Next scrape in 30 seconds"                  │
      │                                              │
      │ Exporter: metrics collected locally          │
      │ CPU samples, memory snapshots, etc.          │
      └──────────────────────────────────────────────┘

T=5   │ (No action - collecting metrics)             │

T=15  │ (Metrics still being collected)              │

T=30  ┌──────────────────────────────────────────────┐
      │ Prometheus initiates HTTP GET                │
      │ /metrics endpoint                            │
      └────┬─────────────────────────────────────────┘
           │
           ▼ (TCP + TLS handshake: 10ms)
      ┌────────────────────────────────────────────┐
      │ Exporter responds with:                    │
      │   - node_cpu_seconds_total {...}           │
      │   - node_memory_MemAvailable_bytes {..}    │
      │   - (1000 lines of metrics text)           │
      │ Transfer time: 50ms                        │
      └────────────────────────────────────────────┘
           │
           ▼
      Prometheus receives response (T=30.06s)
      ├─ Parse metrics text
      ├─ Validate format
      ├─ Append to local TSDB
      └─ Time sample as T=30.00s (not T=30.06s)

T=35  │ (Metrics ingested, new collection starts)   │

T=60  ┌──────────────────────────────────────────────┐
      │ Second scrape cycle begins...                │
      │                                              │
      │ Prometheus compares T=30 vs T=60 metrics:    │
      │   - Calculate rate: (T=60 - T=30) / 30      │
      │   - Identify anomalies                       │
      │   - Evaluate alert rules                     │
      └──────────────────────────────────────────────┘

T=90  │ (Third scrape)                               │

...continuing indefinitely
```

---

## Disaster Recovery & Backup Strategies

### Textual Deep Dive

#### Internal Working Mechanisms

**1. Full Backup vs. Incremental vs. Differential**

Backup styles differ in how they store changes:

```
Original Data (T=0):
  ├─ File A: 100MB (created T=0)
  ├─ File B: 50MB (created T=0)
  └─ File C: 75MB (created T=0)
  Total: 225MB

Changes (T=1 day):
  ├─ File A: modified (10MB changed)
  ├─ File B: unchanged
  ├─ File C: modified (5MB changed)
  ├─ File D: created (25MB new)
  └─ Total changed: 40MB

====================================
FULL BACKUP (T=1):
  Backup storage size: 225MB
  Contains: All files (A, B, C)
  Restore time: Fast (only need T=1 backup)
  ├─ T=0: 225MB (full)
  ├─ T=1: 225MB (full) ← New copy
  └─ Storage: 450MB total (2x original)
  
  Use case: Weekly backup to ensure restore history

====================================
INCREMENTAL BACKUP (T=1):
  Backup storage size: 40MB (only changes since T=0)
  Contains: Only changes (A diff: 10MB, C diff: 5MB, D new: 25MB)
  Restore time: SLOW (need T=0 + T=1)
  
  T=0: 225MB (full base)
  T=1: 40MB (incremental: delta from T=0)
    T=2: 15MB (incremental: delta from T=1) ← More changes
    T=3: 8MB
  
  Storage: 225 + 40 + 15 + 8 = 288MB total
  
  Recovery scenario:
    - Restore T=0: 225MB
    - Apply T=1 delta: 40MB
    - Apply T=2 delta: 15MB
    - Apply T=3 delta: 8MB
    - Result: Full system state at T=3
  
  Risk: If one backup in chain corrupted, everything after fails
  Use case: Daily incremental (cheap storage), weekly full (fast recovery)

====================================
DIFFERENTIAL BACKUP (T=1):
  Backup storage size: 40MB (only changes since last FULL)
  Contains: Only changes since T=0 (A: 10MB, C: 5MB, D: 25MB)
  
  T=0: 225MB (full base)
  T=1: 40MB (differential from T=0)
    T=2: 18MB (differential from T=0, includes T=1 changes + new)
    T=3: 12MB (differential from T=0)
  
  Storage: 225 + 40 + 18 + 12 = 295MB total
  
  Recovery: Only need T=0 + latest differential (T=3)
    - Restore T=0: 225MB
    - Apply T=3 differential: 12MB
    - Result: Full system state at T=3
  
  Advantage: Simpler restore (2-step vs chain)
  Use case: Daily differential, weekly full
```

**2. Snapshot Mechanics (LVM)**

Snapshots create point-in-time copies without duplicating data:

```
Normal Filesystem (before snapshot):

Logical Volume (LV):
  ├─ Block 0: File A data (inode 100)
  ├─ Block 1: File A data
  ├─ Block 2: File B data (inode 101)
  ├─ Block 3: Free
  └─ Block 4: File C data (inode 102)

Physical Volumes (PV): 100GB total

================================
CREATE SNAPSHOT:

lvcreate -L10G -s -n backup_snap /dev/vg0/prod_lv

Logical Volume (original):
  ├─ Block 0: File A data (shared)
  ├─ Block 1: File A data (shared)
  ├─ Block 2: File B data (shared)
  ├─ Block 3: Free
  └─ Block 4: File C data (shared)

Snapshot:
  ├─ Block 0: -> points to original block 0
  ├─ Block 1: -> points to original block 1
  ├─ Block 2: -> points to original block 2
  ├─ Block 3: -> points to original block 3
  └─ Block 4: -> points to original block 4
  
  Extra metadata: Copy-on-write (COW) journal (10GB allocated)

File Modified on Original (File A changes):

Original now:
  ├─ Block 0: NEW data (modified)
  ├─ Block 1: File A data (original, unchanged)
  └─ ...

Snapshot still sees:
  ├─ Block 0: OLD data (in COW area)
  ├─ Block 1: File A data (pointing to original block 1)
  └─ ...

Storage consumption:
  ├─ Original: ~100GB (unchanged)
  ├─ Snapshot: 10GB (only changed blocks)
  └─ Snapshot COW area: tracks 10GB of changes
```

**3. Backup Encryption Architectures**

Where encryption keys live determines security posture:

```
Architecture 1: Keys IN SAME Location (BAD for ransomware)

  Data Storage: /data/database.db
  Encrypted with key: /data/.backup_key
  
  Ransomware attack:
    Attacker gains root → finds /data/.backup_key
    Can decrypt all backups
    Result: No protection

Architecture 2: Keys in Different DC/Region (GOOD)

  Data Storage (Primary): /data/database.db
  Backup Storage: s3://backups/database.db.enc
  Encryption Key: AWS KMS (separate account, different region)
  
  Ransomware attack on Primary:
    Attacker: Full access to Primary + S3 backup
    Missing: AWS KMS keys (in different account/region)
    Result: Backups are encrypted, attacker can't decrypt
  
  Authorized restore:
    Request key from AWS KMS → Decrypt backup
    (requires IAM credentials, MFA, audit logging)

Architecture 3: Hardware Security Module (HIGHEST security)

  Data Storage: Encrypted with KMS
  Backup Storage: Encrypted with HSM
  
  HSM: Tamper-proof hardware vault
    - Key never leaves device unencrypted
    - All encrypt/decrypt happens inside device
    - Network protocols: Encrypted always
    
  Ransomware attack:
    Attacker: Has encrypted backups
    Missing: Physical HSM device
    Result: Impossible to decrypt without device/root password
```

#### Architecture Role

```
Application Data
      │
      ├─ Real-time Replication (HA layer)
      │  └─ Protects against sudden failures
      │
      ├─ Scheduled Backups (DR layer) ← [THIS SECTION]
      │  ├─ Local backups (fast restore)
      │  ├─ Offsite backups (geo-disaster recovery)
      │  └─ Archive tier (long-term retention/compliance)
      │
      ├─ Snapshots (middle ground)
      │  └─ Quick recovery + space-efficient
      │
      └─ Immutable Copies (ransomware protection)
         └─ Can't be modified/deleted by attacker
```

#### Production Usage Patterns

**Pattern 1: 3-2-1 Rule (Gold Standard)**

```
Backup Strategy: 3 copies, 2 media types, 1 offsite

Example for E-commerce Database:

COPY 1 (Hot): Local NAS disk
  Size: 1TB database
  Retention: 30 days
  RPO: 1 hour (hourly snapshots)
  RTO: 15 minutes
  Cost: ~$1000/month
  Use: Daily restores for "oops" deletes

COPY 2 (Warm): S3 Standard (same region)
  Size: 1TB database × 7 weeks = 7TB
  Retention: 90 days
  RPO: 6 hours (daily backups)
  RTO: 1 hour (download + restore)
  Cost: ~$150/month
  Use: Disaster recovery (primary DC down)

COPY 3 (Cold): S3 Glacier (different region)
  Size: 1TB database × 52 weeks = 52TB
  Retention: 1 year
  RPO: 1 day (weekly backups)
  RTO: 4 hours (restore from Glacier)
  Cost: ~$100/month (archival pricing)
  Use: Long-term compliance + 1-year-back recovery

Total cost: ~$1250/month
Total storage: 7TB + 52TB = 59TB
Recovery time: 15min (local) → 1hr (regional) → 4hr (cross-region)
```

**Pattern 2: Backup and Restore Testing (Critical)**

```
Monthly Restore Verification:

Pick random backup from archive:
  $ aws s3 ls s3://backups/ | shuf | head -1
  backup_2026_02_13_database.tar.gz.enc

Restore to isolated environment:
  ├─ Decrypt backup
  ├─ Extract to test database
  ├─ Run consistency checks (table counts, checksums)
  ├─ Run sample queries (ensure data integrity)
  └─ Compare data to production (if possible)

Result:
  ✓ Backup is valid and restorable
  ✗ Backup corrupted (need different backup)
  ✗ Key not accessible (access problem)
  ✗ Restore time exceeded RTO (automation needed)

Document results in postmortem:
  "2026-03-13: Restored Feb 13 backup in 45 minutes"
  "Data integrity check: PASSED"
  "Time to restore to writable state: 30 minutes"

This practice catches:
  - Silent backup failures (backup created but corrupted)
  - Key inaccessibility (discovered only at restore time)
  - Restore time significantly different from estimated
```

**Pattern 3: RPO Planning (How Much Data Loss Is Acceptable?)**

```
RPO = Maximum acceptable time since last backup

Database Backup Strategy:

Strategy A: Full daily backup
  RPO: 24 hours (lose up to 24h of transactions)
  Cost: Low (1 backup/day)
  Use: Acceptable for non-critical data
  
  2026-03-01: Full backup 11:00pm (contains data up to 11:00pm)
  2026-03-02: Database fails at 2:00pm
  Data loss: 2:00pm - 11:00pm previous day = 15 hours
  Actually lose: 15 hours of transactions ✗

Strategy B: Daily full + hourly incremental
  RPO: 1 hour (lose up to 1h of transactions)
  Cost: Medium (1 full + 23 incremental/day)
  Use: Most production systems
  
  2026-03-02 2:00pm: Failure
  Latest backup: 2026-03-02 1:00pm incremental
  Data loss: 1 hour (1:00pm - 2:00pm)
  Acceptable ✓

Strategy C: Continuous replication + hourly backup
  RPO: 5-10 minutes (lose < 10min transactions)
  Cost: High (replication overhead + backups)
  Use: Critical financial/healthcare systems
  
  Replication captures changes every 5 minutes
  Backup captures snapshot hourly
  Failure: <10 minutes loss ✓
```

#### DevOps Best Practices

**1. Automated Backup Verification (Don't Trust Backups)**

```bash
#!/bin/bash
# test-restore.sh
# Run weekly to verify backups are restorable

BACKUP_DATE=$(date -d "1 week ago" +%Y-%m-%d)
BACKUP_FILE="s3://backups/database_${BACKUP_DATE}.sql.gz.gpg"
DECRYPT_KEY="~/.backup_key.gpg"

# Verify backup exists
if ! aws s3 ls "$BACKUP_FILE" > /dev/null; then
  echo "CRITICAL: Backup $BACKUP_DATE missing"
  exit 1
fi

# Download backup
aws s3 cp "$BACKUP_FILE" /tmp/backup.sql.gz.gpg --quiet

# Decrypt and extract to test database
gpg --decrypt --output /tmp/backup.sql.gz < "$DECRYPT_KEY" /tmp/backup.sql.gz.gpg
gunzip /tmp/backup.sql.gz

# Connect to TEST database (not production!)
mysql -h test-db.internal -u restore_user -p"$TEST_DB_PASS" < /tmp/backup.sql

# Verify data integrity
mysql -h test-db.internal -u verify_user << EOF
SELECT
  (SELECT COUNT(*) FROM users) as user_count,
  (SELECT COUNT(*) FROM orders) as order_count,
  (SELECT MAX(created_at) FROM orders) as latest_order;
EOF

# Check results match expected ranges
USERS=$(mysql -h test-db.internal -uverify_user -Nse "SELECT COUNT(*) FROM users")
if [ "$USERS" -lt 100000 ]; then
  echo "WARNING: Backup may be incomplete (only $USERS users)"
  exit 1
fi

echo "SUCCESS: Backup $BACKUP_DATE verified and restorable"
# Clean up
rm -f /tmp/backup.sql* /tmp/backup.sql.gz.gpg
```

**2. Backup Encryption at Rest and in Transit**

```bash
#!/bin/bash
# backup-with-encryption.sh

DB_NAME="production"
BACKUP_DIR="/mnt/backup"
DEPLOY_KMS_ARN="arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

# 1. Create backup
mysqldump \
  --host=primary.db.internal \
  --user=backup_user \
  --password="$DB_PASSWORD" \
  --single-transaction \
  --lock-tables=false \
  "$DB_NAME" > /tmp/backup.sql

# 2. Compress
gzip -9 /tmp/backup.sql

# 3. Encrypt locally with GPG (offline key)
# Generate one-time symmetric key
CIPHER_KEY=$(openssl rand -hex 32)
echo "$CIPHER_KEY" | gpg --symmetric --cipher-algo AES256 /tmp/backup.sql.gz

# Encrypt the key with KMS (can be stored with file)
ENCRYPTED_KEY=$(echo "$CIPHER_KEY" | aws kms encrypt \
  --key-id "$DEPLOY_KMS_ARN" \
  --plaintext fileb:///dev/stdin \
  --query CiphertextBlob \
  --output text)

# 4. Upload to S3 (encrypted in transit)
BACKUP_FILE="${BACKUP_DIR}/db_$(date +%Y%m%d_%H%M%S).sql.gz.gpg"

aws s3 cp /tmp/backup.sql.gz.gpg "$BACKUP_FILE" \
  --sse aws:kms \
  --sse-kms-key-id "$DEPLOY_KMS_ARN" \
  --storage-class GLACIER

# 5. Store encrypted KMS key separately (in S3 metadata or different location)
echo "$ENCRYPTED_KEY" | aws s3 cp - "${BACKUP_FILE}.key"

echo "Backup encrypted and uploaded: $BACKUP_FILE"
echo "KMS Key ID: $DEPLOY_KMS_ARN"

# Clean up plaintext
shred -u /tmp/backup.sql.gz /tmp/backup.sql.gz.gpg
```

**3. Immutable Backup (Ransomware Protection)**

```bash
#!/bin/bash
# immutable-backup.sh
# Create WORM (Write Once, Read Many) backup copies

# Option 1: Using S3 Object Lock (AWS)
BACKUP_BUCKET="immutable-backups"
BACKUP_FILE="database_$(date +%Y-%m-%d).tar.gz"

# Enable Object Lock on bucket (per AWS S3 docs)
# aws s3api create-bucket with --object-lock-enabled-for-bucket

# Upload with WORM retention
aws s3api put-object \
  --bucket "$BACKUP_BUCKET" \
  --key "$BACKUP_FILE" \
  --body backup.tar.gz \
  --object-lock-mode GOVERNANCE \
  --object-lock-retain-until-date "$(date -u -d '+90 days' +%Y-%m-%dT%H:%M:%SZ)" \
  --server-side-encryption AES256

# Verify object cannot be deleted or modified
aws s3api head-object \
  --bucket "$BACKUP_BUCKET" \
  --key "$BACKUP_FILE" | grep ObjectLockRetainUntilDate

echo "Backup is immutable until $(date -d '+90 days')"

# Option 2: Using airgapped server (completely disconnected)
# IMMUTABLE_BACKUP_SERVER="192.168.100.50" (only connects for receive)
# 
# rsync -avz --delete-after \
#   /data/backups/ \
#   immutable_backup@$IMMUTABLE_BACKUP_SERVER:/mnt/immutable/
#
# Server receives but CANNOT:
#   - Initiate outbound connections
#   - Modify received files (read-only mount)
#   - Delete received backups
```

---

### Practical Code Examples

#### Incremental Backup Script with `rsync`

```bash
#!/bin/bash
# incremental-backup.sh
# Creates incremental backups using rsync with hardlinks

set -euo pipefail

SOURCE_DIR="/data/application"
BACKUP_BASE="/mnt/backups/app"
LATEST_LINK="$BACKUP_BASE/latest"
TODAY=$(date +%Y-%m-%d)
TODAY_BACKUP="$BACKUP_BASE/$TODAY"

# Create newest backup directory
mkdir -p "$BACKUP_BASE/$TODAY"

# If this is not the first backup, use latest as hardlink base
# This means only new/changed files consume disk space
if [ -L "$LATEST_LINK" ]; then
    # Create hardlink copy of latest backup directory
    cp -al "$(readlink "$LATEST_LINK")" "$TODAY_BACKUP.tmp"
    mv "$TODAY_BACKUP.tmp" "$TODAY_BACKUP"
else
    # First backup; nothing to hardlink
    mkdir -p "$TODAY_BACKUP"
fi

# Sync changes (will overwrite hardlinks with new data only for changed files)
rsync -av --delete \
    --exclude=".cache" \
    --exclude="*.tmp" \
    "$SOURCE_DIR/" \
    "$TODAY_BACKUP/"

# Update symlink to latest
rm -f "$LATEST_LINK"
ln -s "$TODAY_BACKUP" "$LATEST_LINK"

# Show disk usage
echo "Backup completed:"
du -sh "$TODAY_BACKUP"
du -sh "$BACKUP_BASE"

# Clean up backups older than 30 days
find "$BACKUP_BASE" -maxdepth 1 -type d -mtime +30 -exec rm -rf {} + || true

echo "Incremental backup of $SOURCE_DIR completed in $TODAY_BACKUP"
```

#### LVM Snapshot-Based Backup

```bash
#!/bin/bash
# snapshot-backup.sh
# Create point-in-time backup using LVM snapshots

set -euo pipefail

LV_PATH="/dev/vg0/data_lv"
SNAPSHOT_NAME="backup_snap"
SNAPSHOT_SIZE="20G"
MOUNT_POINT="/mnt/snapshot"
BACKUP_DEST="s3://backups/"

# Check if snapshot already exists
if lvs "$LV_PATH/$SNAPSHOT_NAME" 2>/dev/null; then
    echo "Removing existing snapshot..."
    lvremove -f "$LV_PATH/$SNAPSHOT_NAME"
fi

# Create snapshot
echo "Creating snapshot..."
lvcreate -L "$SNAPSHOT_SIZE" \
    -s \
    -n "$SNAPSHOT_NAME" \
    "$LV_PATH"

# Mount snapshot (read-only)
mkdir -p "$MOUNT_POINT"
mount -o ro "/dev/vg0/$SNAPSHOT_NAME" "$MOUNT_POINT"

# Create backup
echo "Creating backup..."
BACKUP_FILE="/tmp/data_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$BACKUP_FILE" -C "$MOUNT_POINT" . \
    --exclude='.cache' \
    --exclude='*.tmp'

# Upload to S3
echo "Uploading to S3..."
aws s3 cp "$BACKUP_FILE" "$BACKUP_DEST" \
    --sse AES256 \
    --storage-class GLACIER

# Cleanup
umount "$MOUNT_POINT"
lvremove -f "/dev/vg0/$SNAPSHOT_NAME"
rm -f "$BACKUP_FILE"

echo "Backup completed: $(basename "$BACKUP_FILE")"
```

#### Borg Backup (Deduplication + Compression)

```bash
#!/bin/bash
# borg-backup.sh
# Automated backup using Borg for efficient deduplication

set -euo pipefail

BORG_REPO="/mnt/borg_repo"
SOURCE_DIRS=("/data/app" "/data/database" "/etc")
BACKUP_NAME="automatic_$(date +%Y-%m-%d_%H-%M-%S)"

# Initialize Borg repository (one-time)
if ! borg list "$BORG_REPO" &>/dev/null; then
    echo "Initializing Borg repository..."
    borg init --encryption=repokey-blake2 "$BORG_REPO"
fi

# Create backup with progress
echo "Creating archive: $BACKUP_NAME"
borg create \
    --verbose \
    --progress \
    --stats \
    --compression zstd,22 \
    --exclude-caches \
    --exclude-from ~/.borg_excludes \
    "$BORG_REPO::$BACKUP_NAME" \
    "${SOURCE_DIRS[@]}"

# Prune old archives (keep daily for 7 days, weekly for 4 weeks)
echo "Pruning old archives..."
borg prune \
    --verbose \
    --list \
    --keep-daily=7 \
    --keep-weekly=4 \
    --keep-monthly=12 \
    "$BORG_REPO"

# Check repository integrity
echo "Checking repository integrity..."
borg check --progress "$BORG_REPO"

# List archived backups
echo "Archived backups:"
borg list "$BORG_REPO"

echo "Backup completed successfully"
```

#### Disaster Recovery Plan Document

```markdown
# Database Disaster Recovery Plan

## RTO and RPO Targets

| Service | RTO | RPO | Justification |
|---------|-----|-----|---------------|
| Production Database | 1 hour | 1 hour | SLA: 99.9% availability |
| Cache Layer | 30 minutes | 5 minutes | Can rebuild from DB if needed |
| File Storage | 4 hours | 1 day | Low priority, can re-upload |

## Backup Strategy: 3-2-1 Rule

### Copy 1: Hot (Local NAS)
- **Where**: /mnt/nfs/backups/
- **Frequency**: Hourly snapshots
- **Retention**: 7 days
- **RTO**: 15 minutes
- **Use**: Daily recovery for data errors

### Copy 2: Warm (Cloud)
- **Where**: S3 Standard (us-west-2)
- **Frequency**: Daily full backup
- **Retention**: 90 days
- **RTO**: 1 hour
- **Use**: Regional disaster recovery

### Copy 3: Cold (Archive)
- **Where**: S3 Glacier (us-east-1)
- **Frequency**: Weekly
- **Retention**: 2 years (compliance)
- **RTO**: 4 hours
- **Use**: Long-term retention

## Recovery Procedures

### Scenario 1: Database Corruption (Data Restored)

1. **Detection** (T+0)
   - Monitoring: Checksums mismatch
   - Verification: Connect to database, query validation

2. **Assessment** (T+5min)
   - Extent of corruption: 1 table? Multiple tables?
   - Point-in-time needed?
   - Can we use point-in-time recovery (PITR)?

3. **Recovery Option A: PITR (Preferred)**
   - Database supports point-in-time recovery: YES
   - Restore to 1 minute before corruption: ~2 hours
   - RTO: 2 hours
   - RPO: 1 minute

   ```bash
   mysql -h recovery-db.internal
   mysql> RESTART SERVER_ID 10 WITH RESTORE FROM '/backup/backup_log_*';
   ```

4. **Recovery Option B: Full Backup Restore**
   - If PITR unavailable or too old
   - Restore latest backup: ~30 minutes
   - RTO: 30 minutes
   - RPO: 1 hour (data loss possible)

### Scenario 2: Data Center Failure

1. **Detection** (T+0)
   - Multiple service health checks timeout
   - DNS queries to primary region fail
   - Monitoring: All alertants fire

2. **Failover Decision** (T+5min)
   - Primary DC completely offline: YES
   - Standby DC operational: Verify YES
   - Initiate failover: YES

3. **Failover Steps** (T+5-30min)
   - Update DNS: Primary → Secondary (3-5min propagation)
   - Restore database from S3: 30-60min
   - Run data consistency checks: 10-15min

4. **Verification** (T+45min)
   - Database restored and accessible
   - Application servers online
   - Monitoring shows normal operation
   - Notify stakeholders

### Scenario 3: Ransomware Attack

1. **Detection & Containment** (T+0-30min)
   - Alert: Unusual file deletion/encryption
   - Action: Isolate infected server (change IP, block traffic)
   - Preserve evidence: Don't restart

2. **Assess Damage** (T+30-60min)
   - How many servers affected?
   - Which backup copies are readable?
   - Check immutable backups (cloud Object Lock): Status?

3. **Recovery** (T+60-240min)
   - Provision fresh servers from golden images
   - Restore data from clean backups (immutable copies)
   - Restore database from Glacier (immutable)
   - Verify integrity before going live

4. **Post-Incident** (T+4hrs+)
   - Forensics: Determine attack vector
   - Remediation: Patch vulnerability
   - Backup improvements: Add more immutable copies

## Testing Schedule

- **Monthly**: Restore test from one random backup
  - Restore to isolated test environment
  - Verify data integrity
  - Document restore time
  - Report to stakeholders

- **Quarterly**: Full disaster recovery drill
  - Simulate complete server failure
  - Execute full recovery procedure
  - Measure actual RTO vs. target
  - Identify process gaps

- **Annually**: Disaster recovery plan review
  - Meet with all stakeholders
  - Update RTO/RPO if needed
  - Update recovery procedures if technology changed
  - Training for new team members

## Key Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| DBA Lead | Alice Johnson | +1-555-0100 | alice@company.com |
| Infrastructure | Bob Smith | +1-555-0101 | bob@company.com |
| Security | Carol White | +1-555-0102 | carol@company.com |
```

---

### ASCII Diagrams

#### Incremental Backup Chain Timeline

```
Full Backup Chain (Example: 7-day retention)

T=0 (Monday 11:00pm):  FULL BACKUP (500GB)
  Contents: All files (A, B, C, D, ...)
  ├─ File A: 100GB
  ├─ File B: 50GB
  ├─ File C: 75GB
  ├─ File D: 25GB
  ├─ File E: 100GB
  ├─ File F: 50GB
  └─ File G: 100GB
  Total: 500GB
  Restore: Need ONLY this backup

T=1 (Tuesday 11:00pm):  INCREMENTAL #1 (35GB)
  Changes since Monday:
  ├─ File A: modified 10GB
  ├─ File B: DELETED -50GB
  ├─ File E: modified 20GB
  ├─ File H: NEW 5GB
  Rest: unchanged
  Storage: 35GB
  Restore: Need Monday FULL + Tuesday INCREMENTAL

T=2 (Wednesday 11:00pm): INCREMENTAL #2 (22GB)
  Changes since Tuesday:
  ├─ File C: modified 5GB
  ├─ File D: modified 2GB
  ├─ File G: modified 3GB
  ├─ File I: NEW 12GB
  Rest: unchanged
  Storage: 22GB
  Restore: Need Monday FULL + Tuesday INCR + Wednesday INCR

T=3-T=6: Continue INCREMENTAL ...

Total Storage Used:
  Full + Incr1 + Incr2 + Incr3 + Incr4 + Incr5 + Incr6
  = 500GB + 35GB + 22GB + 15GB + 18GB + 12GB + 20GB
  = 622GB (vs. 500GB × 7 = 3500GB for all full backups)

Restore Dependency Chain:

Monday FULL (500GB)
    ├─ Tuesday INCR (35GB) 
    │      ├─ Wednesday INCR (22GB)
    │      │      ├─ Thursday INCR (15GB)
    │      │      │      ├─ Friday INCR (18GB)
    │      │      │      │      ├─ Saturday INCR (12GB)
    │      │      │      │      │      └─ Sunday INCR (20GB) ← Latest point in time

To restore state at Sunday 11:59pm:
  Step 1: Restore Monday FULL
  Step 2: Apply Tuesday INCR
  Step 3: Apply Wednesday INCR
  Step 4: Apply Thursday INCR
  Step 5: Apply Friday INCR
  Step 6: Apply Saturday INCR
  Step 7: Apply Sunday INCR
  
  Total time: ~4 hours (depends on disk speed)

If any backup in chain corrupted:
  Unable to restore beyond that point
  Example: Wednesday INCR corrupted
    → Can restore to Tuesday (Mon + Tue only)
    → Cannot restore to Wed/Thu/Fri/Sat/Sun
  
Solution: Differential or periodic full backups
```

#### 3-2-1 Backup Architecture Diagram

```
┌─1─┐     ┌─2─┐     ┌──────────────┐
│HOT│ AMI │WRM│ SNUG │    COLD      │
└───┘     └───┘     └──────────────┘
  │         │            │
  │ NAS     │ AWS        │ AWS
  │ Disk    │ S3 Std     │ Glacier
  │         │            │
  ▼         ▼            ▼
┌──────────────────────────────────┐
│ Application Database (Primary)   │
│ Size: 1TB                        │
│ Update rate: 10GB/hour           │
│ Failure probability: 1% per year │
└──────────────────────────────────┘
         ▲ ▲                ▲
         │ │                │
    ┌────┘ │                │
    │      └────────────────┘
    │
    │
  ┌─────────────────────────────────────────┐
  │ Backup Strategy Comparison              │
  ├─────────────────────────────────────────┤
  │                                         │
  │ HOT Backup (Copy #1):                  │
  │   Location: Local NAS (/mnt/backups)   │
  │   Frequency: Every 1 hour (24 copies)  │
  │   Retention: 1 month                   │
  │   Total size: 24 × 1TB = 24TB          │
  │   RTO: 5 minutes (local disk)          │
  │   RPO: 1 hour                          │
  │   Cost: ~$2000/month                  │
  │   Use: "Oh no, I deleted the table!"   │
  │                                        │
  │ WARM Backup (Copy #2):                 │
  │   Location: AWS S3-Standard (same AZ)  │
  │   Frequency: Every 6 hours              │
  │   Retention: 90 days                   │
  │   Total size: ~4.5TB (60 backups)      │
  │   RTO: 1 hour                          │
  │   RPO: 6 hours                         │
  │   Cost: ~$100/month                   │
  │   Use: "Primary server died"           │
  │                                        │
  │ COLD Backup (Copy #3):                 │
  │   Location: AWS Glacier (different AZ)│
  │   Frequency: Every week (52 copies)    │
  │   Retention: 2 years                   │
  │   Total size: ~60TB (52 backups)       │
  │   RTO: 4-24 hours (Glacier retrieval)  │
  │   RPO: 1 week                          │
  │   Cost: ~$50/month                    │
  │   Use: Compliance, long-term history   │
  │                                        │
  │ Combined (3-2-1):                      │
  │   Total storage: 24TB + 4.5TB + 60TB   │
  │   ~= 90TB                              │
  │   Total cost: ~$2150/month              │
  │   Recovery options:                    │
  │     ├─ 5 min: HOT (hourly)            │
  │     ├─ 1 hour: WARM (6-hourly)        │
  │     └─ 4-24 hours: COLD (weekly)      │
  │                                        │
  │ Media Diversity (2-2-1):               │
  │   Copy 1: Disk (NAS)                   │
  │   Copy 2: Cloud Object Storage (S3)    │
  │   Copy 3: Cloud Archive (Glacier)      │
  │                                        │
  │   Failure scenarios covered:           │
  │   ├─ One disk type fails: Use other   │
  │   ├─ Primary DC burns down: Use cloud │
  │   ├─ Cloud region down: Use other AZ  │
  │   ├─ All same media fails: Unlikely   │
  │   └─ Ransomware deletes local: Cloud  │
  │                                        │
  └─────────────────────────────────────────┘


Data Flow:

          ┌─── Hourly ───┐
          │              │
          ▼              ▼
    Application  ► NAS Backup (HOT)
    Data (1TB)         │
          │            │ Every 6 hours
          │            ▼
          ├─────────► S3 Standard (WARM)
          │           │
          │           │ Every week
          │           ▼
          ├────────────► Glacier (COLD)
          │
          └─────► Replication 
                  (to Standby DB)
                  
Recovery Priority:

  Tier 1 (RTO < 1 hour):
    ├─ Can I restore from HOT? → 5 min restore
    └─ If HOT corrupted, use WARM? → 1 hour restore
  
  Tier 2 (RTO 1-4 hours):
    └─ Use WARM if COLD needed
  
  Tier 3 (RTO 4-24 hours):
    └─ Use COLD (Glacier)

Cost vs. Recovery Time:

  Fast recovery = high cost (HOT = expensive local storage)
  Slow recovery = low cost (COLD = cheap cloud archive)
  
  3-2-1 balances both:
    ├─ Most backups go to COLD (cheap)
    ├─ Recent backups on WARM (moderate)
    └─ Latest on HOT (expensive, but small window)
```

---

## Production Troubleshooting Methodologies

### Textual Deep Dive

#### Internal Working Mechanisms

**1. Systematic Troubleshooting Framework**

Unlike guessing, systematic troubleshooting follows the scientific method:

```
Incident Occurs: "API is slow"

Step 1: Define the Problem Precisely
  - Vague: "API is slow"
  - Precise: "GET /api/users endpoint: p99 latency 2000ms (SLO: 500ms)
             Started 2026-03-13T14:32:00Z
             Affects 10% of user base
             Not all endpoints slow (POST /api/users is normal)"
  
  Tool: Grafana dashboard showing latency over time
  Goal: Establish baseline and deviation

Step 2: Gather Data (Don't Make Assumptions)
  - System metrics: CPU, memory, disk I/O, network
  - Application metrics: Request rate, error rate, queue depth
  - Logs: Error messages, warnings, specific timestamps
  - Traces: Distributed traces for affected requests
  
  Tool: Prometheus, Grafana, ELK, Jaeger
  Anti-pattern: "It must be database" (without evidence)

Step 3: Form Hypothesis
  - Hypothesis A: Database query slow (evidence: all requests to /users endpoint slow)
  - Hypothesis B: Network latency to dependency (evidence: requests to external API timeout)
  - Hypothesis C: Cache behavior changed (evidence: cache hit rate dropped 3 hours ago)
  
  Goal: Multiple hypotheses ranked by likelihood

Step 4: Test Hypothesis
  - Hypothesis A testing: Check database slow query log, explain query plans
  - Hypothesis B testing: Check network latency to external API, test connectivity
  - Hypothesis C testing: Check cache hit rate, invalidation logs
  
  Tool: strace, lsof, tcpdump, database explain
  Goal: Elimination of unlikely hypotheses

Step 5: Identify Root Cause
  - Root cause: "Database query on /users endpoint changed 14 days ago during deployment"
  - Evidence: Old query: 50ms, new query: 1800ms
  - Why: Missing database index on filtering column
  
  Anti-pattern: "We added more load" (proximate cause, not root)
  Goal: Why did the application change? (root cause)

Step 6: Fix
  - Solution A: Add missing index (1 minute, 50% latency reduction)
  - Solution B: Roll back deployment (5 minutes, 100% resolution)
  - Solution C: Increase database resources (20 minutes, temporary)
  
  Trade-off: Fast rollback (Solution B) vs. permanent fix (Solution A)
  Typical approach: Rollback now (restore service) + fix later (root cause)

Step 7: Verify Fix
  - P99 latency returns to < 500ms: YES
  - No side effects introduced: Check
  - No increase in error rate: OK
  - Rollback verified: Done

Step 8: Document & Learn
  - RCA: Deployment caused missing index
  - Process improvement: Add automated index health checks
  - Monitoring: Alert on query latency increase month-over-month
```

**2. Common Tools & What They Show**

```
strace (System Call Tracer):
  Purpose: See every system call a process makes
  
  Command: strace -p 1234 (attach to PID 1234)
  
  Output:
    open("/var/log/app.txt", O_CREAT|O_APPEND, 0644) = 5
    write(5, "Request processed\n", 18)   = 18
    select(0, NULL, NULL, NULL, {...})   = 1 (timeout)  ← Sleeping
    read(3, buffer, 4096)                 = 0            ← EOF on socket
    close(3)                              = 0
    exit_group(0)                         = ?
  
  What it shows:
    - File opens/closes (resource leaks)
    - Network reads/writes (blocking on slow socket)
    - System calls timing out (hanging)
    - Context switches (scheduling issues)
  
  Interpretation: "Process opened 1000 file handles and never closed them"
  - Diagnosis: File descriptor leak

lsof (List Open Files):
  Purpose: See all files, sockets, pipes a process has open
  
  Command: lsof -p 1234
  
  Output:
    COMMAND    PID     USER      FD      TYPE              DEVICE SIZE/OFF NODE NAME
    python    1234    appuser   10u     REG              8,1   524288  1001 /var/log/app.log
    python    1234    appuser   11u     IPv4            0x1234   0t0    TCP localhost:8080->client.ip:55123
    python    1234    appuser   12r    FIFO              0x567  4096    789 pipe
    python    1234    appuser  1024u    IPv4            0x1235   0t0    TCP localhost:8080->db.local:5432
  
  Shows:
    - Open files and their size
    - Network connections (source and destination)
    - Pipes, sockets, character devices
    - File modes (r=read, w=write, u=read/write)
  
  Interpretation: "Process has 1024 open TCP connections to database"
  - Diagnosis: Connection leak (app creating connections, not returning to pool)

netstat (Network Statistics):
  Purpose: Show network connections and statistics
  
  Common variations:
    netstat -tnp              # TCP connections (-t), numeric (-n), process (-p)
    netstat -an | grep LISTEN # All listening ports
    netstat -s                # Network statistics (packets sent/received/retransmitted)
  
  Output:
    Proto Recv-Q Send-Q Local Address     Foreign Address   State       PID/Program
    tcp      0     0     0.0.0.0:8080     0.0.0.0:*        LISTEN      1234/python
    tcp      1     0     10.0.1.10:53278  10.0.2.5:5432    ESTABLISHED 1234/python
    tcp      0  47840   10.0.1.10:53280  10.0.2.5:5432    ESTABLISHED 1234/python
  
  Key fields:
    Recv-Q: Data in receive buffer NOT yet read by application (backlog)
    Send-Q: Data in send buffer waiting to be sent (congestion)
  
  Interpretation: "Send-Q=47840 on DB connection = writes backing up"
  - Diagnosis: Network issue OR database slow to process queries

tcpdump (Packet Capture):
  Purpose: Capture and analyze network packets
  
  Command: tcpdump -i eth0 -w capture.pcap 'tcp port 5432'
  
  Shows:
    - Exact bytes sent/received
    - TCP retransmissions (packet loss)
    - Connection state transitions (SYN, ACK, FIN)
    - Timing between packets
  
  Interpretation: "1000 retransmissions on database connection = packet loss"
  - Diagnosis: Network infrastructure issue (bad switch, cable, ISP)

ps (Process Status):
  Purpose: Snapshot of processes
  
  Command: ps aux | grep python
  
  Output:
    USER     PID %CPU %MEM    VSZ    RSS STAT START   TIME COMMAND
    appuser 1234 150.0 25.4 2048000 262144 R  10:00  1000 python server.py
  
  Key fields:
    %CPU: CPU usage (can exceed 100% if multi-core)
    %MEM: Memory as percentage of total RAM
    VSZ: Virtual memory size (includes swapped out)
    RSS: Resident set (actual RAM used)
    STAT: R=runnable, S=sleeping, Z=zombie
  
  Interpretation: "%CPU=150% = using 1.5 cores, %MEM=25% = 25GB RAM = high"
  - Diagnosis: Process consuming too many resources

dd (Disk Diagnostics):
  Purpose: Measure disk read/write speed
  
  Command: dd if=/dev/zero of=/tmp/test.dat bs=1M count=1000
  
  Output:
    1000+0 records in
    1000+0 records out
    1048576000 bytes (1.0 GB) copied, 10.5478 s, 99.5 MB/s
  
  Shows: Disk write speed (normal ~100-500 MB/s, slow < 50 MB/s)
  
  Interpretation: "99.5 MB/s = expected for spinning disk"
  - Diagnosis: Disk slow if < 10 MB/s (failing device)
```

#### Architecture Role

Troubleshooting is the **reactive** counterpart to observability's **proactive** stance:

```
Observability (Proactive):
  Monitoring continuously runs → Alert fires → Incident begins
  Goal: Catch problems before customers notice

Troubleshooting (Reactive):
  Customer report or alert → Incident begins
  Troubleshooting starts → RCA → Fix deployed

Timeline:
  T=0:    Alert: "High latency"
  T=1min: Oncall page
  T=5min: Oncall begins investigation (TROUBLESHOOTING STARTS)
  T=10min: RCA complete: "Missing index"
  T=15min: Fix deployed
  T=20min: Customer service restored

Troubleshooting effectiveness depends on:
  ├─ Speed of data collection (good metrics + logs = fast)
  ├─ Quality of instrumentation (well-logged code = understandable)
  ├─ Documentation (runbooks for common issues = faster diagnosis)
  └─ Team experience (senior engineer = more hypotheses, faster elimination)
```

#### Production Usage Patterns

**Pattern 1: Incident Severity Levels**

```
CRITICAL (S1): Business-impacting, multiple customers
  ├─ SLO violated for > 5 minutes
  ├─ Revenue-impacting (payment processing down)
  ├─ Data loss detected
  └─ MTTD target: < 1 minute (automated alerts)
  └─ MTTR target: < 15 minutes
  
  Response:
    - Page senior engineer immediately
    - Declare SEV1 incident
    - Skip normal approval processes
    - Focus on rollback/failover (fast) then RCA (thorough)

HIGH (S2): Single customer affected or partial outage
  ├─ SLO violated for 10-30 minutes
  ├─ One feature broken but core service up
  ├─ Single customer data loss
  └─ MTTD target: < 5 minutes
  └─ MTTR target: < 1 hour
  
  Response:
    - Page on-call engineer
    - Assign dedicated person for investigation
    - Follow standard troubleshooting procedures

MEDIUM (S3): Degradation, no customer impact yet
  ├─ Performance issue (200ms slower)
  ├─ Error rate < 1%
  ├─ Single component failing (but redundancy covers)
  └─ MTTD target: < 30 minutes
  └─ MTTR target: < 4 hours
  
  Response:
    - Create ticket
    - Assign to next available engineer
    - Schedule for during business hours

LOW (S4): Potential improvements, no urgency
  ├─ Unused code, dead configuration, etc.
  ├─ Process improvements
  └─ MTTR target: whenever convenient
  
  Response:
    - Document for future improvement
    - No immediate action required
```

**Pattern 2: Blameless Post-Mortem**

```
Post-Mortem Structure (happens within 1 week of incident):

1. Timeline of Events (facts only, no judgment)
   - T=2026-03-13T14:30:00Z: Deployment of v1.2.3 completed
   - T=14:32:15Z: First alert fires: "High latency"
   - T=14:35:00Z: Oncall pages
   - T=14:39:00Z: Incident declared SEV1
   - T=14:45:00Z: Rollback to v1.2.2
   - T=14:47:00Z: Latency returns to normal
   - T=15:30:00Z: Customer communication sent
   
   No question: "Who made the mistake?" ONLY: "What happened?"

2. Root Cause Analysis (5 Whys Technique)

   Symptom: API latency 2000ms (SLO 500ms)
   
   Why 1: Query execution time increased
   → Deployment v1.2.3 changed query logic
   
   Why 2: Query logic changed but query performance not tested
   → Code review didn't catch: "SELECT with N+1 problem"
   
   Why 3: N+1 problem not caught by code review
   → Code review checklist existed, but database performance not included
   
   Why 4: Checklist incomplete
   → Database performance is "team responsibility" but no owner
   
   Root Cause: No clear ownership of database query performance
              + Code review process didn't include performance checklist
   
   NOT "engineer wrote bad query"  ← Points to person (blame)
   BUT "process didn't catch bad query" ← Points to system (improvement)

3. Impact Assessment
   - Customers affected: ~10% (1M users)
   - Duration: 17 minutes (14:30 - 14:47)
   - Revenue loss: ~$50,000 (estimate)
   - Data loss: None
   - Follow-on incidents: None

4. Action Items (Lessons Learned)

   Immediate (Fix Now - This Month):
     [ ] Add database query performance tests to CI/CD
     [ ] Review and optimize queries in v1.2.3
     [ ] Update code review checklist to include "database performance"
   
   Short-term (Next 90 Days):
     [ ] Assign database performance owner
     [ ] Establish query timeout alerts
     [ ] Document query optimization best practices
   
   Long-term (Next Year):
     [ ] Implement automatic query analysis (identify N+1 problems)
     [ ] Training: All engineers on query optimization

5. Retrospective Questions (Never assigned to people)

   "What could've helped?"
   - Better database monitoring (would alert earlier)
   - Automated query performance tests (would catch in CI)
   - Chaos engineering (would test under load)
   
   "What went well?"
   - Automated rollback (restored service in 2 minutes)
   - Clear escalation path (oncall responded immediately)
   - Communication to customers (transparent about outage)

6. Distribution
   - Shared with entire engineering team
   - Discussed in all-hands meeting
   - Action items added to sprint planning
   - Results tracked: all action items must have owners + deadlines
```

---

### Practical Code Examples

#### Troubleshooting Runbook Script

```bash
#!/bin/bash
# troubleshoot-api.sh
# Interactive troubleshooting runbook for API service

set -euo pipefail

API_HOST="${1:-api.service.local}"
GRAFANA_URL="https://grafana.internal/d/api-overview"

log() { echo "[$(date +'%H:%M:%S')] $*"; }
error() { echo "[ERROR] $*" >&2; exit 1; }

main() {
    log "API Troubleshooting Runbook - $API_HOST"
    echo
    
    # Step 1: Service Health
    log "Step 1: Checking service health..."
    if curl -sf "http://$API_HOST/health" > /dev/null 2>&1; then
        log "✓ Service responding to health checks"
    else
        log "✗ Service NOT responding"
        echo "  → Try: systemctl restart api-service"
        echo "  → If persists, check logs: journalctl -u api-service -f"
        exit 1
    fi
    echo
    
    # Step 2: System Resources
    log "Step 2: Checking system resources..."
    
    # CPU
    CPU=$(ps aux | grep "[a]pi-service" | awk '{print $3}')
    if [ -z "$CPU" ]; then
        error "api-service process not found"
    fi
    log "  CPU usage: $CPU%"
    if (( $(echo "$CPU > 80" | bc -l) )); then
        log "    ⚠ WARNING: High CPU usage"
        echo "    → Check: ps aux | grep api-service"
        echo "    → Profile: sudo perf record -p <PID> -g sleep 10"
    fi
    
    # Memory
    MEMORY=$(ps aux | grep "[a]pi-service" | awk '{print $4}')
    log "  Memory usage: $MEMORY%"
    if (( $(echo "$MEMORY > 50" | bc -l) )); then
        log "    ⚠ WARNING: High memory usage"
        echo "    → Check: jmap -histo <PID> (if Java)"
        echo "    → Restart service: systemctl restart api-service"
    fi
    
    # Disk
    DISK=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    log "  Disk usage: $DISK%"
    if [ "$DISK" -gt 85 ]; then
        error "Disk usage >85% - free up space immediately"
    fi
    echo
    
    # Step 3: Network Connectivity
    log "Step 3: Checking dependencies..."
    
    # Database
    if ! nc -z db.internal 5432 2>/dev/null; then
        error "Cannot reach database (db.internal:5432)"
    fi
    log "  ✓ Database reachable"
    
    # Cache
    if ! timeout 2 bash -c "echo 'PING' | nc cache.internal 6379" >/dev/null 2>&1; then
        log "  ✗ Cache unreachable (non-critical)"
    else
        log "  ✓ Cache reachable"
    fi
    
    # External API
    if ! curl -sf --max-time 5 "https://external-api.com/health" > /dev/null 2>&1; then
        log "  ⚠ WARNING: External API unreachable"
        echo "    → Check: curl -v https://external-api.com/health"
        echo "    → Fallback: Implement circuit breaker in code"
    else
        log "  ✓ External API reachable"
    fi
    echo
    
    # Step 4: Request Latency
    log "Step 4: Testing request latency..."
    
    RESPONSE_TIME=$(curl -w '%{time_total}' -o /dev/null -s "http://$API_HOST/api/users" | head -c 4)
    log "  Response time: ${RESPONSE_TIME}s"
    
    if (( $(echo "$RESPONSE_TIME > 0.5" | bc -l) )); then
        log "  ⚠ WARNING: Latency above SLO (target: 500ms)"
        echo "  → Dashboard: $GRAFANA_URL"
        echo "  → Check for:"
        echo "     - Database query latency"
        echo "     - Cache hit rate (if low, increase cache)"
        echo "     - External API calls timing out"
        echo "     - Slow disk I/O"
    fi
    echo
    
    # Step 5: Error Rate
    log "Step 5: Checking error rate..."
    ERROR_RATE=$(curl -s "http://$API_HOST/metrics" | grep 'http_requests_total{status_code="500"}' | awk -F'} ' '{print $NF}' || echo "0")
    log "  500 errors (recent): $ERROR_RATE"
    
    if [ "$ERROR_RATE" -gt 100 ]; then
        log "  ⚠ WARNING: High error rate"
        echo "  → Check: journalctl -u api-service | tail -100 | grep ERROR"
        echo "  → Logs in Kibana: https://kibana.internal (filter: service=api)"
    fi
    echo
    
    # Step 6: Summary
    log "Troubleshooting summary:"
    echo "  ✓ Service healthy"
    echo "  ✓ Dependencies reachable"
    echo "  ✓ Performance within SLO"
    echo
    echo "No issues found. If problem persists:"
    echo "  1. Check Grafana: $GRAFANA_URL"
    echo "  2. Check logs: journalctl -u api-service -n 1000 | less"
    echo "  3. Run: strace -p <PID> (see system calls)"
    echo "  4. Check traces: $GRAFANA_URL/jaeger (look for slow spans)"
}

main
```

#### Performance Analysis - strace Output

```bash
# Running: strace -c curl http://api.service.local/api/users

% time     seconds  usecs/call     calls    errors name
------ ----------- ----------- --------- --------- ----------------
 45.23    0.123456      15432         8           epoll_wait  ← Process sleeping on network
 23.45    0.064123        8015         8           read        ← Reading from socket
 18.92    0.051654        6456         8           write       ← Writing to socket
  8.10    0.022134      11067         2           connect     ← TCP handshake
  2.88    0.007862        789        10           mmap        ← Memory allocation
  0.45    0.001234         41        30           brk         ← Userspace memory
  0.23    0.000634         79         8           mprotect    ← Memory protection
------ ----------- ----------- --------- --------- ----------------
100.00    0.273097                   74           total

Interpretation:
  - 45% epoll_wait: Process sleeping, waiting for I/O (NORMAL for network calls)
  - 23% read: Reading from network socket (NORMAL)
  - 18% write: Writing to network socket (NORMAL)
  - 8% connect: TCP connection overhead
  
  Total time: 273ms
  
  Problem identification: If too much time in mmap/brk, might be memory issue
```

#### Log Analysis Pattern

```bash
#!/bin/bash
# analyze-logs.sh
# Correlate error patterns in logs

LOGS_DIR="/var/log"
ERROR_PATTERN="ERROR|CRITICAL|Exception"
TIME_WINDOW="1 hour"

# Find most common errors in last hour
grep -h "$ERROR_PATTERN" $LOGS_DIR/app/*.log \
  | sed 's/.*ERROR: //' \
  | sort | uniq -c | sort -rn \
  | head -10

# Example output:
#      125 Database connection timeout
#       98 User authentication failed
#       45 File not found: /data/upload/missing.txt
#       12 Slow query detected (duration > 5s)
#        5 Memory allocation failed

# Interpretation:
# 1. Database connection timeout (125 occurrences) is primary issue
# 2. Check: Is database online? netstat -tnp | grep 5432
# 3. Check: Connection pool exhausted? SELECT count(*) FROM information_schema.processlist
# 4. Solution: Increase connection pool size or add connection pooling

# Advanced: Find errors around specific time
TARGET_TIME="2026-03-13T14:32"
grep "$TARGET_TIME" /var/log/app/error.log | tail -50

# Result:
# 2026-03-13T14:30:00Z ERROR Starting database migration
# 2026-03-13T14:31:00Z ERROR Database query timeout (no migration complete)
# 2026-03-13T14:32:00Z ERROR Connection pool full (migration blocking)
# 2026-03-13T14:33:00Z ERROR Cascade failures: all requests timing out
# 2026-03-13T14:35:00Z ERROR Recovery: connections returning

# RCA: Database migration held connections, causing pool exhaustion
# Fix: Run migrations during maintenance window with scheduled downtime
```

---

### ASCII Diagrams

#### Troubleshooting Decision Tree

```
API Latency Alert Fired (p99 > 500ms)

                            START
                              │
                    Is API responding?
                         /        \
                       YES         NO
                       │            │
            Check Grafana       Check service status
            Dashboard         (systemctl status api)
                │              │
                │         Service running?
                │         /         \
                │       YES         NO
                │        │           │
                │        │    Restart service
                │        │    (systemctl start api)
                │        │
                │        └──→ Check logs
                │             (journalctl -u api)
                │
            Metric Review:
              ├─ CPU usage
              ├─ Memory usage
              ├─ Disk I/O
              ├─ Network latency
              └─ Request rate
                │
         ┌──────┴──────┬────────────┬────────────┐
         │             │            │            │
    Is CPU high?   Is Memory    Is DB slow?  Is External
    (>80%)         high? (>50%)  (p99 > 1s)   API slow?
        │              │            │            │
       YES             YES          YES          YES
        │              │            │            │
    Check which   Check memory   Check DB     Check external
    process       leaks:         query log:   API status:
    (ps aux)      (jmap -histo)  (slow query) (curl healthcheck)
        │              │            │            │
        │              │            │            │
    Profile:      Kill process:   Optimize:   Fallback logic:
    (perf           and restart    ├─ Add index  ├─ Implement
    record)         (systemctl)    ├─ Rewrite    │  circuit breaker
                                   │  query      ├─ Cache response
                                   └─ Scale DB   └─ Retry with
                                                   exponential
                                                   backoff
                │
                └─→ HYPOTHESIS ELIMINATED or IDENTIFIED
                    │
            Repeat elimination until ROOT CAUSE found
                    │
                ROOT CAUSE
                    │
                Apply FIX
                    │
            Verify fix worked:
              1. Latency trend down?
              2. No new errors?
              3. Customers notified?
                    │
                   YES
                    │
              POST-MORTEM
                    │
         Document in RCA:
         ├─ What happened
         ├─ Why it happened
         ├─ How to prevent
         └─ Follow-up items
```

#### Mean Time to Recovery (MTTR) Breakdown

```
Incident Timeline (Example):

T=0:00 
    Alert threshold breached
    "p99 latency > 500ms"
    
    ────────────────
    MTTD (Mean Time to Detect)
    ────────────────
    
T=0:15
    Oncall engineer paged
    Opens Grafana to investigate
    
    ────────────────
    MTTE (Mean Time to Engage)
    ────────────────
    
T=2:30
    Root cause identified:
    "Missing database index on user_id column"
    
    ────────────────
    MTTD + Troubleshooting Time
    ────────────────
    
T=3:00
    Fix deployed:
    "CREATE INDEX idx_user_id ON users(id)"
    
    ────────────────
    MTTF (Mean Time to Fix)
    ────────────────
    
T=3:15
    Latency returns to normal
    Verification complete
    
    ────────────────
    MTTR (Mean Time to Recovery) = 3 min 15 sec
    ────────────────
    
T=4:30
    Post-mortem meeting
    Root cause analysis documented
    
    ────────────────
    MTTC (Mean Time to Close) = 4 min 30 sec
    ────────────────

Total incident impact: 3 min 15 sec of degraded service
Acceptable? Depends on SLA:
  ├─ 99.9% SLA: Allows 3 min downtime/month → Already used up
  ├─ 99.95% SLA: More forgiving
  └─ 99.99% SLA: Nearly impossible

Improvements:
  1. Reduce MTTD: Better alerting (alert at p99 > 300ms not 500ms)
  2. Reduce MTTE: Alert to oncall within 30 seconds (automated)
  3. Reduce troubleshooting: Better observability (traces would show DB slow immediately)
  4. Reduce MTTF: Automated rollback vs. manual fix

Optimized Timeline:
  T=0:00: Alert (p99 > 300ms)
  T=0:05: Oncall engaged (automated notification)
  T=0:30: Root cause identified (traces show DB query slow)
  T=1:00: Rollback deployed (automated)
  T=1:15: Service recovered
  MTTR: 1 min 15 sec (4x improvement)
```

---

## Hands-on Scenarios

### Scenario 1: Multi-AZ Database Failover in Production

**Problem Statement:**
You have a PostgreSQL primary database in us-west-2a with a standby replica in us-west-2b. The primary fails unexpectedly at 2:00 PM. Your SLA requires recovery within 15 minutes with zero data loss for committed transactions.

**Architecture Context:**
```
Primary DB (us-west-2a)          Standby DB (us-west-2b)
    ↓                                 ↑
    └─ Synchronous replication ──────┘
    
Application tier (3 instances) → Route53 DNS → Primary connection
Monitoring: Prometheus + Alertmanager
Backup: S3-based WAL archiving
```

**Step-by-Step Implementation:**

1. **Setup Health Checks (5 minutes)**
   ```bash
   # On primary database
   CREATE EXTENSION pg_stat_statements;
   CREATE FUNCTION health_check() RETURNS boolean AS $$
   BEGIN
     RETURN (SELECT extract(epoch from (now() - pg_postmaster_start_time())) > 10);
   END;
   $$ LANGUAGE plpgsql;
   
   # Prometheus scrape job
   - job_name: 'postgres_health'
     metrics_path: '/health'
     static_configs:
       - targets: ['primary-db.internal:5432', 'standby-db.internal:5432']
   ```

2. **Configure Standby for Automatic Promotion (10 minutes)**
   ```bash
   # On standby: /etc/postgresql/recovery.conf
   standby_mode = 'on'
   primary_conninfo = 'host=primary-db.internal port=5432 user=replication'
   recovery_target_timeline = 'latest'
   wal_retrieve_retry_interval = '5s'
   
   # Promotion trigger
   touch /var/lib/postgresql/promote  # Triggers promotion to primary
   ```

3. **Implement Failover Detection (15 minutes)**
   ```bash
   #!/bin/bash
   # failover-check.sh (runs every 10 seconds)
   
   PRIMARY="primary-db.internal:5432"
   STANDBY="standby-db.internal:5432"
   
   # Check primary health
   if ! pg_isready -h $PRIMARY -t 5 > /dev/null; then
     # Primary failed, invoke failover
     ssh standby-db "pg_ctl promote -D /var/lib/postgresql/12/main"
     
     # Update DNS to point to standby
     aws route53 change-resource-record-sets \
       --hosted-zone-id Z123 \
       --change-batch file:///tmp/failover-dns.json
     
     # Notify monitoring
     curl -X POST https://pagerduty.com/api/incidents \
       -d '{"service": "database", "severity": "critical"}'
   fi
   ```

4. **Test Failover (20 minutes)**
   ```bash
   # In staging environment: Simulate primary failure
   sudo systemctl stop postgresql
   
   # Verify standby promotes
   pg_isready -h standby-db.internal -t 5
   
   # Verify no data loss
   SELECT max(transaction_id) FROM commits;
   
   # Verify applications reconnect (update connection strings)
   curl -sf http://app-server:8080/api/health  # Should succeed
   ```

**Best Practices Used:**
- Synchronous replication ensures zero data loss for committed transactions
- Automated health checks enable rapid detection (< 30 seconds)
- Automatic promotion triggered bypasses human latency
- DNS update ensures all clients switch to new primary
- Post-failover verification confirms success
- RTO: 2-3 minutes; RPO: 0 transactions

---

### Scenario 2: Resolving Metrics Cardinality Explosion

**Problem Statement:**
Prometheus is consuming 500GB of disk space and queries timeout within 24 hours. You have 50 million active time series. Prometheus crashes during query evaluation against recent data. You need to reduce cardinality by 90% while maintaining visibility.

**Architecture Context:**
```
Application (Python) creates metrics with labels:
  http_requests_total{endpoint, user_id, request_id, service}
  
User IDs: 1 million unique values
Request IDs: Unique per request (100 million per day)
Result: 1M users × 100M requests = impossible to store
```

**Step-by-Step Diagnosis & Fix:**

1. **Identify Cardinality Explosion (10 minutes)**
   ```bash
   # Query to find highest cardinality metrics
   curl -s 'http://prometheus:9090/api/v1/label/__name__/values' | \
   for metric in $(jq -r '.[] | select(startswith("http_"))'); do
     series_count=$(curl -s "http://prometheus:9090/api/v1/query_range?query=count($metric)" | jq '.data.result[0].value[1]')
     echo "$metric: $series_count series"
   done
   
   # Result:
   # http_requests_total: 50,000,000 series (TOO HIGH)
   # Cache requests by endpoint + status only: 100 endpoints × 5 statuses = 500 series
   ```

2. **Fix Application Code (30 minutes)**
   ```python
   # BAD: Creates millions of series
   from prometheus_client import Counter
   http_requests = Counter('http_requests_total', 'Total requests',
     labelnames=['endpoint', 'user_id', 'request_id', 'service'])
   
   http_requests.labels(
     endpoint='/api/users',
     user_id=user.id,           # ← Cardinality: 1M
     request_id=uuid.uuid4(),   # ← Cardinality: 100M  
     service='user-api'
   ).inc()
   
   # GOOD: Low cardinality
   http_requests = Counter('http_requests_total', 'Total requests',
     labelnames=['endpoint', 'status_code', 'service'])
   
   http_requests.labels(
     endpoint='/api/users',           # ← Cardinality: 100
     status_code=response.status,     # ← Cardinality: 10
     service='user-api'
   ).inc()
   
   # HIGH-CARDINALITY DATA → LOGS INSTEAD
   structlog.info('request_completed',
     endpoint='/api/users',
     user_id=user.id,          # ← In logs, not metrics
     request_id=request_id,    # ← In logs, not metrics
     duration_ms=elapsed)
   ```

3. **Reconfigure Prometheus Scraping (15 minutes)**
   ```yaml
   # prometheus.yml
   global:
     scrape_interval: 60s  # Changed from 15s to reduce ingestion rate
   
   metric_relabel_configs:
     # Drop metrics with unbounded labels
     - source_labels: [__name__, user_id]
       regex: '(http_requests_total);.*'
       action: drop
     
     # Keep only essential metrics
     - source_labels: [__name__]
       regex: 'http_requests_total|http_request_duration_seconds|app_.*'
       action: keep
   
   # Limit cardinality per job
   - job_name: 'app'
     sample_limit: 10000  # Scrape fails if > 10k samples
   ```

4. **Migrate Old Data (Storage optimization)**
   ```bash
   # Delete old Prometheus data
   sudo systemctl stop prometheus
   rm -rf /var/lib/prometheus/wal
   
   # Compact storage (creates new TSDB from wal)
   prometheus --storage.tsdb.path=/var/lib/prometheus \
     --storage.tsdb.max-block-duration=2h \
     --storage.tsdb.min-block-duration=2h
   ```

5. **Verify Cardinality Reduction (5 minutes)**
   ```bash
   # Check new cardinality
   curl 'http://prometheus:9090/api/v1/query?query=count(http_requests_total)' | jq '.data.result[0].value'
   
   # Result: 500 series (vs. 50M previously) → 99.999% reduction
   
   # Query performance
   time curl 'http://prometheus:9090/api/v1/query_range?query=http_requests_total&start=..&end=..&step=60s'
   
   # Result: 50ms (vs. timeout previously)
   ```

**Best Practices Used:**
- Low-cardinality labels for metrics (max 10 values each)
- High-cardinality details in logs, not metrics
- Regular cardinality audits and monitoring
- Sample limits to catch unexpected explosions
- Logs + metrics + traces for complete observability

---

### Scenario 3: Disaster Recovery Test Failure Uncovered

**Problem Statement:**
During a routine monthly backup restore test, the restore fails with "Key not accessible". You have immutable backups in AWS S3 Object Lock, but cryptographic keys stored in AWS KMS are in a different region. Testing reveals the key access is broken. Production has no backup.

**Architecture Context:**
```
Backup Location: S3 Glacier (us-west-2)
Encryption Key: AWS KMS (us-east-1, different account)
Keys: Stored in CloudFormation stack (deleted accidentally last quarter)

Current date: March 13, 2026
Encryption key: DELETED 3 months ago
Knowledge: No one remembers this

Backup status: ENCRYPTED and IMMUTABLE but UNRECOVERABLE
```

**Step-by-Step Recovery:**

1. **Detect Problem (5 minutes)**
   ```bash
   # Monthly restore test starts
   aws s3 cp s3://production-backups/db.sql.gz.gpg /tmp/ --region us-west-2
   # Success
   
   # Decrypt backup
   aws kms decrypt \
     --ciphertext-blob fileb:///tmp/encrypted_key \
     --region us-east-1
   # ERROR: InvalidKeyId.NotFound
   ```

2. **Investigate Key Deletion (15 minutes)**
   ```bash
   # Check CloudFormation stack
   aws cloudformation describe-stacks --stack-name kms-keys --region us-east-1
   # Result: Stack DELETE_COMPLETE (deleted 2026-01-15)
   
   # Check KMS key in CloudTrail
   aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=arn:aws:kms:us-east-1:123456789012:key/12345678 --region us-east-1
   
   # Result: ScheduledKeyDeletion event 2026-01-15
   # Key scheduled for deletion: 2026-02-15 (30-day waiting period)
   # Current deletion status: ???
   ```

3. **Check Key State (10 minutes)**
   ```bash
   aws kms describe-key --key-id arn:aws:kms:us-east-1:123456789012:key/12345678
   
   # Possible results:
   # ├─ State: PendingDeletion → Can still recover (cancel deletion)
   # └─ State: Disabled → Can enable (if not deleted yet)
   ```

4. **If Key Still Recoverable (30 minutes)**
   ```bash
   # Cancel key deletion if within 7-day waiting period
   aws kms cancel-key-deletion --key-id arn:aws:kms:us-east-1:123456789012:key/12345678
   
   # Re-enable key if disabled
   aws kms enable-key --key-id arn:aws:kms:us-east-1:123456789012:key/12345678
   
   # Verify key works
   aws kms decrypt \
     --ciphertext-blob fileb:///tmp/encrypted_key \
     --region us-east-1
   # Result: PlaintextBlob (success!)
   
   # Retry backup recovery
   gpg --decrypt /tmp/encrypted_key | gunzip | mysql < restore.sql
   # Success
   ```

5. **If Key Permanently Deleted (Business Impact Assessment)**
   ```bash
   # Check if multiple key copies exist
   aws s3api head-object --bucket production-backups --key db.sql.gz.gpg.key
   # If key stored as S3 object: can recover from there
   
   # Check if unencrypted backup copies exist
   aws s3 ls s3://backup-staging/ | grep "db.sql"
   # If unencrypted copy exists: can restore without key
   
   # Check if Glacier archives are restorable
   aws s3 ls s3://archive-backups/ | grep db
   # May not have key for these either
   
   # Last resort: RTO becomes hours/days (restore from older backup)
   ```

6. **Prevention Measures Implemented**
   ```bash
   # 1. Backup encryption key in separate account/region
   # 2. Backup encryption key outside Terraform/CloudFormation
   #    (Store in password manager, hardware wallet, etc.)
   # 3. MONTHLY restore tests (would have caught this immediately)
   # 4. Alerts when KMS keys scheduled for deletion
   # 5. CloudTrail logging for all KMS operations
   
   # Example: CloudTrail alert
   aws cloudtrail create-trail --name kms-monitoring \
     --s3-bucket-name kms-audit-logs
   
   # Alert rule: Any KMS key deletion = immediate PagerDuty alert
   ```

**Best Practices Violated:**
- ✗ Encryption keys not backed up separately
- ✗ No restore testing (would have caught immediately)
- ✗ Keys managed in IaC without backup
- ✗ 30-day deletion window not monitored

**Lessons Learned:**
- RTO: 24+ hours (recovery from older unencrypted backup)
- RPO: 1 month (oldest accessible backup)
- Fix: Restore testing monthly catches all issues before they hit production
- Process: Encryption key management is critical path; treat like fire escape

---

### Scenario 4: Troubleshooting Cascade Failure Under Load

**Problem Statement:**
At 9:00 PM, traffic spikes (1.5x normal load). Within 2 minutes, API latency jumps from 100ms to 5000ms. Customers report timeouts. Services cascade: API → Database → Cache. You have 4 minutes before SLA breach.

**Timeline & Actions:**

```
T=0:00 - Alert fires: "p99 latency > 500ms"
  Oncall pages
  Dashboard shows: All endpoints equally slow
  
T=0:45 - Oncall begins investigation
  ├─ Check Grafana: CPU 95%, Disk I/O 100%, Memory 85%
  ├─ Check deployment: No recent changes
  ├─ Check traffic: 1.5x normal (expected, marketing campaign)
  └─ Hypothesis: System under-provisioned for load
  
  MISTAKE: Jump to "add more servers" without understanding bottleneck
  
T=2:00 - Start scaling up (wrong choice, too late to help)
  └─ Launch 5 new instances (will take 3-5 minutes)
  
T=3:00 - Still degraded, customers complaining
  └─ New instances still initializing
  
T=4:30 - SLA breached, incident escalates
```

**Better Troubleshooting Approach:**

1. **First 30 Seconds: Triage (what's happening?)**
   ```bash
   # Check what changed
   git log --oneline -5  # Recent deployments?
   
   # Check infrastructure metrics
   PromQL queries:
     - node_cpu_usage > 90%? YES
     - disk_io_util > 90%? YES
     - database_connections > max? Check
     - cache_hit_rate (dropped)? Check
   
   # Decision: Load spike or degradation? LOAD SPIKE
   # Action: Check if intentional (marketing campaign, batch job)
   ```

2. **Next 1 Minute: Identify Bottleneck**
   ```bash
   # Distributed traces (Jaeger) show:
   GET /api/products spans:
   ├─ Gateway (5ms) ✓
   ├─ Auth service (10ms) ✓
   ├─ API service (50ms) ✓
   └─ Database query (4900ms) ✗ ← BOTTLENECK
   
   # Database metrics confirm:
   SELECT count(*) FROM information_schema.processlist;
   # Result: 500 connections (max pool: 100) BOTTLENECK FOUND
   ```

3. **Next 30 Seconds: Root Cause**
   ```bash
   # Why are connections exhausted?
   # Check active queries
   SHOW FULL PROCESSLIST WHERE TIME > 60;
   # Result: 400 connections sleeping (not executing)
   
   # Why are connections sleeping?
   # Connection leak in application (connections not returning to pool)
   
   # Evidence: Application doesn't have explicit connection.close()
   # Connections hanging after query returns
   ```

4. **Immediate Fix (< 30 seconds)**
   ```bash
   # Option A: Increase connection pool size (temporary, masks problem)
   # Option B: Restart application (flushes connections, restores service)
   # Option C: Add connection timeout (closes idle connections)
   
   # BEST: Option B (restart) + B (drain connections gracefully)
   
   # Drain connections (graceful shutdown)
   curl -X POST http://api-server:8080/admin/shutdown
   # App stops accepting new connections
   # Waits 30 seconds for existing connections to complete
   # Process exits
   # Load balancer routes to healthy instance
   
   # Result: API responds again
   T=5:30: Latency returns to 100ms
   ```

5. **Post-Incident Fix (permanent)**
   ```python
   # Add explicit connection cleanup
   from contextlib import contextmanager
   
   @contextmanager
   def get_db_connection():
       conn = pool.get_connection()
       try:
           yield conn
       finally:
           conn.close()  # ← Explicitly return to pool
   
   # OR use connection pooling with timeout
   pool = ConnectionPool(
       max_connections=100,
       connection_timeout=30,  # Close idle connections after 30s
       validate_connection=lambda conn: conn.is_open()
   )
   ```

**Lessons:**
- RTO achieved: 5.5 minutes (acceptable)
- Root cause: Application not returning connections to pool
- Prevention: Connection pool monitoring, graceful shutdown procedures
- Better observability would have pinpointed database bottleneck in 30 seconds

---

## Interview Questions

### Category: High Availability & Reliability

**1. Design a High Availability architecture for a relational database serving 1M concurrent users. What are the critical decisions and tradeoffs?**

*Expected answer (Senior level):*

"I'd design for multi-AZ with synchronous primary-standby replication:

Architecture:
```
Primary DB (AZ-1) ← SYN REPL → Standby DB (AZ-2)
     ↑                              
  Clients                      Read replicas (AZ-2, AZ-3)
     ↓                              for readonly queries
Router (Route53)
```

Critical decisions:

1. **Replication Style**: Synchronous (stronger consistency) vs. Async (lower latency)
   - I choose synchronous because data loss is catastrophic (financial transactions)
   - Latency impact: +10-20ms per write (acceptable for 99.9% SLA)
   - Backup: Standby catches up if primary fails

2. **Quorum Decisions**: Who decides if primary is dead?
   - Avoid split-brain (two primaries corrupting data)
   - Need odd number of nodes: 3-node cluster minimum
   - Primary + Standby + Witness (cheap third node for quorum)

3. **RPO vs. RTO**:
   - RPO (data loss): Synchronous replication = 0 seconds
   - RTO (downtime): Automatic failover = 30-60 seconds
   - Manual failover = 5-10 minutes (human latency)

4. **Read Scaling**: Standby can't handle reads (replication lag)
   - Deploy read replicas (asynchronous) for reporting/analytics
   - Separate from HA primary-standby
   - Accept eventual consistency for reads

5. **Automatic Failover**: Must be automated
   - Health checks every 10 seconds
   - Failover decision within 30 seconds
   - If takes >60 seconds, SLA already violated

6. **Testing**: Failover tested monthly
   - Scheduled failover during maintenance window
   - Measure actual RTO (is it 30s or 5min?)
   - Bring failed primary back as standby

Tradeoffs I'm making:
- ✓ Zero data loss for committed transactions
- ✓ Automatic failover (no manual work)
- ✗ Slightly higher write latency (acceptable)
- ✗ More complex than single database (necessary for SLA)
- ✗ More expensive (3+ nodes instead of 1)"

---

**2. Your synchronous replication is causing 100ms latency increase in writes. Users complain. How do you fix it without losing data?**

*Expected answer:*

"Root cause analysis first:
- Synchronous replication: Primary must wait for standby ACK
- Network RTT to standby: 5ms each way = 10ms baseline
- But we're seeing 100ms extra, not 10ms

Questions to investigate:
1. Is standby actually synchronous or did it degrade to async?
2. Is standby overloaded, causing slow ACKs?
3. Are there network issues causing ACK delays?
4. Is disk I/O on standby slow (fsync latency)?

Solutions (ranked by preference):

**Option A: Keep sync, optimize standby**
- Profile standby: Why is it slow?
  - Check: strace -e fsync -p <postgres_pid>
  - Disk I/O bottleneck? Upgrade SSD
  - CPU bottleneck? Scale standby resources
  - Network? Check 'netstat -an | grep ESTABLISHED'
- Result: 100ms → 20-30ms latency
- Benefit: Still zero data loss

**Option B: Group commit (semi-sync)**
- Wait for standby ACK only every 1000ms (batching)
- Latency improvement: 100ms → 10-20ms
- RPO compromise: Could lose 1 second of transactions in forced failover
- Trade: Acceptable for most (not banking)

**Option C: Async replication + continuous WAL archiving**
- Primary doesn't wait for standby
- Latency: Back to baseline (no added latency)
- RPO: Lost transactions if primary fails before WAL shipped to S3
- Benefit: Better for analytics databases where eventual consistency OK
- Risk: Data loss possible (standby needs WAL recovery from S3)

**Option D: Dedicated synchronous network**
- Separate low-latency network for replication
- Current: Shared network with application traffic
- Would reduce contention but expensive

My choice: **Start with Option A** (profile and optimize standby)
- Most likely issue is standby being underprovisioned
- Fixes root cause, keeps strongest consistency
- If that doesn't work, move to Option B (semi-sync)"

---

**3. How do you test your HA system without causing outage? What happens if failover test fails?**

*Expected answer:*

"Testing strategy (different approaches by environment):

**Staging Environment (safest, monthly)**
```
Staging Primary ← SYN REPL → Staging Standby
   Stop Primary        Standby auto-promotes
   Verify Standby is now primary
   Verify no data loss (transaction counts match)
   Restart Primary as new standby
   Verify replication catches up
```

**Production (careful, monthly during maintenance window)**
1. Scheduled maintenance window announced (30 min downtime)
2. Drain connections gracefully (stop accepting new connections)
3. Wait for existing customers to finish (timeout = force kill after 2 min)
4. Force failover to standby
5. Measure RTO: Should be < 1 minute
6. Restart primary as new standby
7. Verify replication catches up
8. Monitor for issues (30 min post-failover)
9. Document actual RTO vs. promised SLA

**Chaos Engineering (weekly, light failures)**
```bash
# Kill random database instances
for i in {1..5}; do
  INSTANCE=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?Tags[?Key==\`Database\`]].InstanceId' | shuf -n 1)
  aws ec2 terminate-instances --instance-ids $INSTANCE
  sleep 30
  # Verify application still running (health check)
  curl -f https://api.internal/health || alert_oncall
done
```

**What happens if failover test FAILS:**

Scenario 1: Standby fails to promote
→ Action: Immediately stop test, revert to primary
→ Post-mortem: Why did promotion fail?
   - Standby configuration corrupted?
   - Witness unreachable (quorum broken)?
   - Promotion script changed without testing?

Scenario 2: Failover succeeds but causes data corruption
→ Action: Restore from backup (CRITICAL)
→ RCA: How did replication allow corruption?
   - Replication lag? (data not fully synced)
   - Concurrent modifications? (missed locking)
   - Hardware issue on primary?

Scenario 3: Failover succeeds but no one can connect
→ Action: Revert DNS to old primary if possible
→ RCA: DNS propagation delay?
   - TTL too high (clients cached old IP)?
   - Connection pooling holding old connections?
   - Load balancer routing outdated?

**Key learned:** Every failed failover test is gold. Better to fail in controlled manner monthly than in production under crisis pressure."

---

### Category: Observability & Monitoring

**4. Paint a picture: You have Prometheus scraping 500 exporters, 10K time series/exporter. What breaks first and why?**

*Expected answer:*

"Math: 500 exporters × 10K series = 5M time series total

At 30-second scrape interval:
- 5M series × 12 scrapes/hour = 60M data points/hour
- 60M × 1KB per point = 60GB/hour ingestion rate
- 60GB × 24 hours = 1.44TB/day storage

Hardware limits:
1. **Prometheus ingestion**: Limited by single-threaded scraper
   - Can only scrape ~1000 targets in series
   - 500 targets OK, 5000 targets would bottleneck
   - Solution: Sharding (federated Prometheus instances)

2. **TSDB compression**: Prometheus chunks data
   - 2 hours per chunk, ~1MB per chunk per series
   - 5M series × 1MB = 5GB per chunk cycle
   - Checkpoint every 2 hours → write spikes
   - Solution: Increase block size or SSD faster I/O

3. **Query performance**: What breaks first
   - Query: count(up) on 500 exporters
   - Prometheus must load all series at once (memory)
   - 5M series × 100 bytes metadata = 500MB memory for one query
   - Two concurrent queries = 1GB memory (on 8GB machine)
   - Third query → OOM kill → Prometheus crashes
   
   THIS IS THE BOTTLENECK (not storage, not scraping)

4. **Cardinality limits**: 10K series per exporter is suspicious
   - Typical Node Exporter: 500-1000 series
   - 10K means: Using high-cardinality labels (user IDs, host IPs)
   - First break: Prometheus memory → query timeout → partial results

5. **What actually fails**:
   - T=0-3 months: Works fine, storage grows
   - T=3 months: Queries slow (load all series into memory)
   - T=4 months: Queries timeout (> 30 second limit)
   - T=5 months: OOM kill Prometheus (crash during large query)
   - T=6 months: Can't restart Prometheus (WAL corruption)

**Prevention:**
- Monitor cardinality: alert if > 10K series per exporter
- Set sample_limit per job: scrapers rejected if > limit
- Use federation: Separate Prometheus per team/region
- Drop high-cardinality: Drop user_id, host_ip labels
- Upgrade hardware: NVMe SSD vs. spinning disk (10x faster)"

---

**5. You're paying $80K/month for Elasticsearch. Logs are stored indefinitely. What decisions did you make wrong?**

*Expected answer:*

"Wrong decisions ranking by severity:

**Wrong Decision #1: No ILM (Index Lifecycle Management) Policy**
- Every log indexed in 'hot' tier (expensive)
- Hot tier: NVMe SSD, 3 replicas, optimized for search
- Older logs: Still on hot tier (waste)
- Fixed by: Move logs to warm tier after 7 days, cold after 30 days
- Cost reduction: $80K → $20K/month

**Wrong Decision #2: Stored ALL logs forever**
- Compliance: May require only 90 days
- Operational: No one queries logs > 30 days old
- Fixed by: Delete after 90 days (or move to cold storage)
- Cost reduction: $20K → $8K/month

**Wrong Decision #3: Storing all fields in original logs**
- Logs include: Stack traces, request bodies, response payloads
- Each can be 10KB+ but rarely searched
- Fixed by: Compress or exclude from index
- Example: Only index {timestamp, level, service, error_code}
- Cost reduction: $8K → $5K/month

**Wrong Decision #4: Sampling strategy non-existent**
- Logging every single request at INFO level
- 1M requests/second × 1KB per log = 1GB/sec ingestion
- Could sample: Log 10% of successful requests, 100% of errors
- Cost reduction: $5K → $2K/month

**Wrong Decision #5: No log retention policy per service**
- Noisy services log excessively
- Example: Background jobs log every microsecond
- Fixed by: Set per-service log level (DEBUG for dev, WARN for prod)
- Cost reduction: $2K → $1K/month

**Actual decision-making (what I'd do):**

1. **First week: Stop the bleeding**
   - Implement ILM policy immediately (hot → warm → cold)
   - Set 30-day retention (delete older)
   - Estimated savings: $60K/month

2. **Week 2-3: Right-size storage**
   - Audit which logs actually generate value
   - Drop fields no one searches (request bodies, stack traces)
   - Estimated savings: $15K/month

3. **Month 2: Implement sampling**
   - Sample non-critical logs (50% of INFO, 100% of ERROR)
   - Estimated savings: $5K/month

4. **Ongoing: Monitor and optimize**
   - Alert if ingestion > threshold (prevents runaway costs)
   - Quarterly review: Are we storing logs we actually use?
   - Target: $15-20K/month for that scale

**Real answer:** Prior team didn't understand cost model
- No one was owning Elasticsearch budget
- Storage grew gradually (no one noticed $80K bill)
- No governance (any service can log indefinitely)

**Improvement:** Governance + monitoring + cost attribution"

---

**6. You implemented custom metrics exporter. It works in staging. In production with 10x load, Prometheus scrape_timeout. What went wrong?**

*Expected answer:*

"Stages of diagnosis:

**Root causes (most to least likely):**

1. **Exporter is slow under load** (Most likely)
   - In staging: Low request rate → exporter responds fast
   - In production: 10x load → exporter can't keep up
   - Cause: N+1 database queries, inefficient metric calculation
   
   Diagnosis:
   ```bash
   curl -w '@timing.txt' http://exporter:9090/metrics
   # Staging: 50ms
   # Production: 30000ms (exceeds 10s timeout)
   ```
   
   Fix:
   ```python
   # Bad: Calculates metrics on each scrape
   @app.route('/metrics')
   def metrics():
       result = ""
       for user in get_all_users():  # N+1 query
           result += metric_line(...)
       return result
   
   # Good: Cache metrics, update in background
   cached_metrics = ""
   
   def update_metrics():
       global cached_metrics
       metrics = {}
       for user in get_all_users():  # Still N query, but once
           metrics[...] = ...
       cached_metrics = format_metrics(metrics)
   
   @app.route('/metrics')
   def metrics():
       return cached_metrics  # Instant response
   
   # Background thread: Update every 30 seconds
   threading.Thread(target=lambda: update_metrics() repeatedly).start()
   ```

2. **Sample limit reached** (Likely)
   - Exporter exposed more metrics than configured
   - Prometheus scraper rejected (sample_limit > 50000)
   - Tried to rescrape, timing out again
   
   Fix:
   ```yaml
   - job_name: 'custom_exporter'
     scrape_timeout: 30s     # Increase from 10s
     sample_limit: 100000    # Increase from 50k
   ```

3. **Prometheus disk too slow** (Less likely)
   - Prometheus under-provisioned for 10x load
   - Disk I/O bottleneck during write
   - Scraper timeout while waiting for disk
   
   Diagnosis:
   ```bash
   iostat 1 | grep sda  # Check disk wait %
   ```

4. **Network issue** (Least likely)
   - Network path to exporter congested
   - Timeouts are 10+ seconds, network RTT is <100msec
   - But possible if packet loss

**Prevention:**
- Load test in staging (should mimic production)
- Profile exporter under load: curl | time
- Set scrape_timeout > expected response time + buffer
- Monitor scrape duration: alert if > 5 seconds"

---

### Category: Disaster Recovery

**7. You have immutable backups in AWS S3 with WORM (Write Once, Read Many). Ransomware encrypts your primary database. How long until you're recovered?**

*Expected answer:*

"Recovery timeline:

**T=0: Ransomware detected**
```
Primary database files encrypted
Application can't read data
Alert: Database corruption detected
```

**T=0-10 min: Assessment phase**
```
Scope: Which data encrypted? (all or partial?)
Is backup accessible?
  ├─ S3 Object Lock immutable? YES
  ├─ Can we list objects? YES (metadata not encrypted)
  ├─ Can we download backup? YES (S3 not encrypted)
  └─ Encryption key accessible? (KEY QUESTION)

Where are keys?
  ├─ In same account? BAD (ransomware might have access)
  ├─ In different account? OK (ransomware limited to one account)
  └─ In AWS KMS? GOOD (keys never leave AWS)
```

**T=10-30 min: Backup selection**
```
Which backup to restore?
  ├─ Latest backup (produced T=0) → might have ransomware
  ├─ Backup from T-27 hours → clean backup
  ├─ Backup from T-7 days → older, works

Timeline:
  ├─ Realized at T=0 (1 day after encryption started)
  ├─ Latest clean: 24 hours ago (RPO = 1 day)
  └─ Choose: 24-hour-old backup
```

**T=30-90 min: Recovery execution**
```
1. Provision new database server (15 min)
2. Download backup from S3 (depends on size)
   - 500GB backup: Upload took 6 hours initially
   - But S3: 100GB/min = 5 minutes download
3. Decrypt backup (10 min, if key accessible)
4. Restore to new database (30-60 min, depends on size/complexity)
5. Verify data integrity (10 min)
   - SELECT count(*) FROM tables
   - Check checksums
6. DNS cutover (instant, <30 sec propagation)
```

**T=90-180 min: Total recovery**
```
RTO: 90 minutes to 3 hours
RPO: 1 day of data loss (latest clean backup - 1 day back)

Cost:
  ├─ Backup storage: $100/month, worth it
  ├─ Recovery testing: $500/month, worth it
  └─ Downtime: $50K per minute (implicit cost)
```

**Critical assumptions (all must be true):**
1. ✓ Backups are in separate account (ransomware can't delete them)
2. ✓ Encryption keys not in primary account (KMS in different account)
3. ✓ Backup tested monthly (know it actually works)
4. ✓ Offsite copies exist (not just local/same-region)
5. ✓ Recovery procedure documented (not improvising)

**If any assumption is FALSE:**
- No encryption keys → Backups unrecoverable → RTO = days/weeks
- Keys in same account → Ransomware deletes them too → RTO = weeks
- Backups in same account → Ransomware deletes them → RTO = weeks
- No testing → Backups corrupted (silent failure) → RTO = weeks

**Real story (happened):**
- Company had backups, but keys in same AWS account
- Ransomware had AWS credentials from hacked dev laptop
- Attacker deleted all backups AND encryption keys
- Recovery time: 6 weeks (rebuilt from oldest recovery point in archived tapes)

**Lesson:** Keys + Backups separation is not optional"

---

### Category: Production Troubleshooting

**8. Service has memory leak. Heap grows from 500MB to 8GB over 24 hours. How do you find the leak?**

*Expected answer:*

"Diagnosis process:

**Step 1: Confirm memory leak (vs. normal growth)**
```bash
# Check memory over time
for i in {1..10}; do
  ps aux | grep java
  sleep 1h
done

# If memory consistently 500MB → 8GB: Leak confirmed
# If memory reaches 500MB then stable: False alarm (normal JVM behavior)
```

**Step 2: Identify object types consuming memory**

Option A: Heap dump analysis
```bash
# Capture heap dump
jmap -dump:live,format=b,file=heap.bin <PID>

# Analysis (using Eclipse MAT or similar)
# Shows: Object type → retained memory
# Example result:
#   String[]              → 2GB
#   User object           → 1.5GB
#   Cache entry           → 1GB
#   
# High suspicion: Cache growing unbounded
```

Option B: Profiling under production load
```bash
# Record 10 minutes of allocation
jcmd <PID> JFR.start name=memory_leak duration=600s
jcmd <PID> JFR.dump filename=profile.jfr

# Analysis shows: Where are allocations happening?
# Top allocation sites:
#   1. Cache.put() → 80% allocations
#   2. String.concat() → 15%
#   3. Normal business logic → 5%
```

**Step 3: Identify root cause of leak**

Likely causes (ranked by probability):

```
Most common: Unbounded cache
├─ Cache grows indefinitely
├─ Example: Static HashMap<String, Data> cache
├─ Accessed by: Request ID, User ID (high cardinality)
└─ Fix: Add TTL or LRU eviction

Second: Circular references
├─ Object A holds reference to B
├─ B holds reference to A
├─ GC can't collect if unreachable from main code
└─ Fix: Use weak references, or break cycle

Third: Request-scoped objects not cleaned up
├─ ThreadLocal variables not cleared
├─ Request contexts accumulating
├─ Example: Security context stored in ThreadLocal
└─ Fix: Add try-finally to clean up ThreadLocal

Fourth: Library bug (external library leaking)
├─ Logging framework buffering
├─ HTTP client holding connections
├─ ORM caching queries
└─ Fix: Upgrade library or work around

Production example (real incident):
  Thread pool executor submits task
  Task stores reference to request object
  Request completed but task finished later
  Request object can't be GC'd
  Accumulates over hours
  Fix: Clear request reference when task done
```

**Step 4: Implement fix**

Bad (mask symptom):
```bash
# Just restart service every 4 hours
@Scheduled(fixedRate = 240*60*1000)
void restartService() {
  System.exit(0);  // Process manager restarts
}

# Problem: Uptime requirements violated, customer sees blips
```

Good (fix root cause):
```python
# If unbounded cache:
from functools import lru_cache
import time

# Before: No limit
cache = {}  # Grows forever

# After: LRU cache with TTL
class TTLCache:
  def __init__(self, max_size=10000, ttl_seconds=3600):
    self.cache = {}
    self.max_size = max_size
    self.ttl = ttl_seconds
    self.access_time = {}
  
  def get(self, key):
    if key not in self.cache:
      return None
    
    # Check if expired
    if time.time() - self.access_time[key] > self.ttl:
      del self.cache[key]
      return None
    
    return self.cache[key]
  
  def put(self, key, value):
    # Evict if at max
    if len(self.cache) >= self.max_size:
      # Remove oldest (by access time)
      oldest = min(self.access_time, key=self.access_time.get)
      del self.cache[oldest]
      del self.access_time[oldest]
    
    self.cache[key] = value
    self.access_time[key] = time.time()
```

**Step 5: Verification**
```bash
# Deploy fix
# Monitor memory over next 24 hours
# Expected: Memory stable at 500-600MB
# If still growing: Different root cause, repeat diagnosis
```

**Key learning:** Memory leaks in Java are usually concurrency bugs, not lost pointers. Always look at concurrent collections (HashMap with multiple threads = corruption → unbounded growth)."

---

**9. Post-mortem: CDN cache invalidation broke and served stale data for 2 hours. 100 engineers each cached wrong version. How do you prevent?**

*Expected answer:*

"Analysis of failure modes:

**What happened:**
```
T=0:00    Deployment v2.1.0
          ├─ Include CSS changes: colors.css
          ├─ CDN config: Cache CSS for 24 hours
          └─ Invalidate cache: POST /invalidate (expected to work)

T=0:05    Users get updated colors.css from origin
          CDN serves updated CSS

T=0:15    CDN cache invalidation fails (silent)
          ├─ Invalidation API timeout
          ├─ No alerting on failed invalidation
          └─ Cached version not cleared

T=0:30    Cache TTL expires on origin
          New request → origin returns v2.1.0
          CDN updates cache: v2.1.0

T=1:00    Developer reverts deployment: v2.0.9
          Origin now serves v2.0.9
          But: CDN still has v2.1.0 cached

T=2:00    Realize mismatch: v100 users on v2.1, users v2.0.9
          Inconsistent behavior, frontend breaks
          Manually clear CDN cache (finally)
```

**Root causes (why did it break?):**
1. Cache invalidation assumed to be instantaneous (not checked)
2. No alerting on failed invalidation (silent failure)
3. Manual invalidation process (human forgetting to do it)
4. No validation that users actually got cache-clear

**Prevention strategies:**

**Strategy 1: Immutable deployments (best)**
```
Instead of:
  /css/colors.css → Cache 24 hours (content changes, filename doesn't)

Do this:
  /css/colors.abc123def456.css → Cache 1 year (content-hash in filename)

When deploying:
  ├─ Generate new filename with content hash
  ├─ HTML references new filename
  ├─ Old filename still cached, but no one uses it
  └─ No invalidation needed (new URL = new cache key)

Benefit: Cache invalidation becomes impossible (by design)
```

**Strategy 2: Short TTL + validation**
```
CDN configuration:
  Cache-Control: max-age=300, must-revalidate
                 ↑ 5 minutes only    ↑ Check if changed
  
Deployment process:
  1. Deploy code
  2. HTTP POST /api/invalidate-caches
  3. Verify all CDN endpoints confirm invalidation
     (not just assume it works)
  4. Monitor: Check that users get new version
     Query analytics: Any requests to CDN still returning old version?
```

**Strategy 3: Automated verification**
```bash
#!/bin/bash
# post-deployment-check.sh

DEPLOYMENT_ID=$(git rev-parse --short HEAD)
EXPECTED_VERSION=$(cat package.json | jq .version)

# Check CDN serves correct version
for CDN_URL in $CDN_URLS; do
  VERSION=$(curl -s $CDN_URL/version.txt)
  if [ "$VERSION" != "$EXPECTED_VERSION" ]; then
    echo "ERROR: CDN $CDN_URL serving stale version: $VERSION"
    # Auto-invalidate or rollback
    exit 1
  fi
done

# Check browsers actually get correct version
VERSION=$(curl -s https://api.internal/app-version)
if [ "$VERSION" != "$EXPECTED_VERSION" ]; then
  echo "ERROR: Browser getting stale version"
  exit 1
fi
```

**Strategy 4: Version headers**
```html
<!-- Include version in HTML -->
<script src="app.js?v=abc123"></script>
<!--                    ↑ Version hash -->

<!-- Browsers: View source → see what version is loaded -->
<!-- Helpful for debugging "users stuck on old version" -->
```

**My recommendation:**
Start with Strategy 1 (immutable filenames) + Strategy 2 (short TTL).
- Content hash in filename = permanent cacheability
- Short TTL on HTML = index updates quickly
- Never need manual invalidation

Example deployment:
```yaml
version: v2.1.0
files:
  - name: colors.abc123.css  (NEW hash each deploy)
  - name: app.def456.js      (NEW hash each deploy)
  - name: index.html         (Cache: 1 hour, must-revalidate)
    # HTML updates within 1 hour
    # CSS/JS cached forever (new filename = new cache key)
```

**Why this matters:**
- Immutable deployments = deterministic (same hash = same content)
- No possibility of serving wrong version
- Post-mortems become "Why was invalidation missing?" Not "How do we invalidate?"
- Fundamentally different approach: Make invalidation unnecessary"

---

**10. You're on-call Saturday night. p99 latency spikes to 5 seconds for 10 minutes, then recovers on its own. What do you do?**

*Expected answer (emphasizes incident response discipline):*

"Approach: Treat as real incident even though it self-healed.

**Immediate response (while degradation happening):**
```
T=0:00  Alert fires: p99 latency > 500ms
        Oncall pages (me)

T=0:30  Investigation begins
        ├─ Check Grafana: spike at exact time
        ├─ Check deployment: No recent changes
        ├─ Check traffic: Spike coincides with API latency
        ├─ Check database: No connection pool exhaustion
        | Check logs: Unexpected errors? No
        └─ Check traces: Requests hanging on specific service
        
T=0:45  Spike resolves on its own
        ├─ p99 latency drops to normal
        ├─ No manual action taken
        ├─ Database connection pool returned to normal
        └─ No errors in logs

My inclination: "Issue resolved, go back to sleep"
WRONG MOVE
```

**Why this is still important:**
- Self-healing != no problem
- Likely: Temporary resource exhaustion (which could happen again)
- Maybe: Application bug that cleared itself (by chance)
- Risk: Happens again during business hours (bigger impact)

**Correct response (even though resolved):**

1. **Immediate: Preserve evidence (right now, while details fresh)**
   ```bash
   # Capture logs around T=0:00
   # Capture metrics around T=0:00
   # Capture distributed traces for any slow requests
   # Don't wait until Monday (logs rotated, traces expired)
   
   # Download from Kibana/Grafana/Jaeger
   # Save to incident ticket
   ```

2. **First hour: Quick diagnosis**
   ```bash
   # Was it load spike?
   # Check: request rate 10 minutes before incident
   - Was it higher than normal Saturday night?
   
   # Was it code-based (query, algorithm)?
   # Check: Did any services deploy in last 24 hours?
   - If yes: Might be new code triggering on specific conditions
   
   # Was it infrastructure (database, network)?
   # Check: Did any infrastructure change recently?
   - Server reboot? NIC reset? Network maintenance?
   ```

3. **Create ticket (document for daytime crew)**
   ```markdown
   # Incident: Unexplained p99 latency spike 2026-03-13 01:30 UTC
   
   ## Timeline
   - T=01:30: p99 latency jumped from 100ms to 5000ms
   - T=01:40: Spike persisted
   - T=01:45: Spike resolved on its own
   
   ## Evidence
   - [Grafana link to spike](...)
   - [Traces for slow requests](...)
   - [Log excerpt](...)
   
   ## Hypothesis
   - Database connection pool exhausted momentarily?
   - Temporary resource spike? (CPU, memory, disk)
   - Garbage collection pause in application?
   
   ## Action Items (for Monday)
   - [ ] Daytime engineer: Investigate root cause
   - [ ] Check application GC logs (pause for 5 seconds?)
   - [ ] Check database metrics (are there hidden spikes?)
   - [ ] Implement alerting for self-healing incidents
   - [ ] If code-based: What deploys happened in last 24h?
   ```

4. **On Monday morning: Full investigation**
   ```bash
   # Daytime engineer picks up ticket
   # Hypothesis testing:
   
   # Was it GC pause?
   grep -i "GC.*5 seconds" /var/log/app/gc.log
   # Result: "Full GC: 4.8 seconds" at exact time!
   
   # Root cause: Heap became fragmented
   # Something allocated large object (100MB) momentarily
   # Triggered full GC → 5 sec pause → latency spike
   
   # Hypothesis: Weekly batch job
   - Runs Saturday night 1:30am
   - Allocates 200MB for data processing
   - Triggers full GC
   - Job completes → memory freed → GC stops
   
   # Fix:
   # Option A: Run batch job during off-peak (less risky)
   # Option B: Reduce batch memory usage (fix root cause)
   # Option C: Tune GC (use low-pause collector)
   # Chosen: Option A (simplest, immediate solution)
   ```

5. **Why incident discipline matters:**
   - Even if self-healed, recurrence is probable
   - Next time might not self-heal (could require manual failover)
   - Data collection now (before logs rotate) vs. never
   - Pattern recognition: "Same spike happens every Saturday" = scheduled job

**Key learning:** 
Self-healing problems are the most dangerous because:
- Feel like non-issues (no customer impact)
- But repeat until root cause fixed
- Eventually happen when you're unavailable (on vacation)
- Or happen at scale (1000x load) and DON'T self-heal

Discipline: Treat all incidents the same (even ones that resolved). That's how you build reliable systems."

---

## Conclusion

This study guide has covered the interconnected disciplines that form the foundation of enterprise-grade Linux administration:

- **High Availability** ensures systems remain operational despite inevitable failures
- **Observability** provides visibility into what's actually happening (vs. what we assume)
- **Disaster Recovery** protects against data loss and organizational catastrophe
- **Troubleshooting** systematically identifies and resolves production incidents

Senior DevOps engineers synthesize all four. A highly available system without observability is unavailable AND undiagnosable. Perfect observability without disaster recovery leaves organization vulnerable to ransomware. Excellent troubleshooting without HA means perpetually fighting fires.

The most mature operations organizations make these practices culture, not checklists:
- Monitoring is built during development, not added post-deployment
- Failover is tested monthly, not "when disaster strikes"
- Backups are verified automatically, not trusted blindly
- Incident post-mortems focus on system improvements, not blame
- Every production incident generates lasting operational improvements

Your job as Senior DevOps is to architect and test for failures that others haven't imagined yet.

