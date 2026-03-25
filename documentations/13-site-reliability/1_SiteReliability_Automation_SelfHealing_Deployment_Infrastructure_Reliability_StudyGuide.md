# Site Reliability Engineering: Automation & Self-Healing, Deployment, Infrastructure, Network, Database, Kubernetes Reliability, Disaster Recovery & Load Balancing

**Audience:** DevOps Engineers with 5–10+ years experience

**Last Updated:** March 2026

---

## Table of Contents

### Core Sections
1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Automation & Self-Healing](#automation--self-healing)
4. [Deployment Reliability](#deployment-reliability)
5. [Infrastructure Reliability](#infrastructure-reliability)
6. [Network Reliability](#network-reliability)
7. [Database Reliability](#database-reliability)
8. [Kubernetes Reliability](#kubernetes-reliability)
9. [Disaster Recovery](#disaster-recovery)
10. [Load Balancing Strategies](#load-balancing-strategies)
11. [Hands-on Scenarios](#hands-on-scenarios)
12. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Site Reliability Engineering

Site Reliability Engineering (SRE) is the engineering discipline that bridges software development and operations. It applies software engineering principles to infrastructure and operational problems, focusing on building and maintaining highly reliable, scalable, and resilient systems. Site reliability encompasses the entire lifecycle of system operations—from deployment through production management to disaster recovery.

Modern SRE practices evolved from the pioneering work at Google and have become industry standard for organizations managing distributed systems at scale. Rather than treating "reliable systems" as a security blanket thrown over operational processes, SRE treats reliability as an engineering problem that requires:

- **Measurement and quantification** of system behavior and health
- **Automation** of repetitive tasks and remediation workflows
- **Proactive identification** of failure modes and prevention strategies
- **Continuous improvement** through controlled experimentation and feedback loops

### Why Site Reliability Matters in Modern DevOps Platforms

In today's cloud-native landscape, the traditional separation between "development" and "operations" has collapsed. DevOps practitioners must now own the full lifecycle of their systems—including availability guarantees, performance optimization, and incident response.

**Key reasons SRE matters:**

1. **Business Impact**: Downtime directly translates to revenue loss, customer dissatisfaction, and reputational damage. A single minute of unavailability can cost enterprises millions.

2. **System Complexity**: Modern architectures span multiple cloud regions, orchestration platforms, microservices, databases, message queues, and observability systems. This complexity creates exponentially more failure modes.

3. **Velocity & Reliability Tradeoff**: Organizations want to deploy faster without sacrificing stability. SRE provides frameworks (error budgets, SLOs, SLIs) for balancing speed and stability.

4. **Operational Excellence**: Automation reduces human error, improves response times, and frees engineers to focus on strategic improvements rather than firefighting.

5. **Cost Optimization**: Inefficient resource utilization, failed deployments requiring rollback, and outages all significantly impact cloud spending. SRE practices reduce these costs.

### Real-World Production Use Cases

**E-commerce Platform**: A major retailer deploys SRE practices to handle massive traffic spikes during holiday sales. Automation detects memory pressure in catalog services, automatically scales instances, and rebalances traffic. Self-healing mechanisms restart degraded services before customer impact occurs. Result: 99.99% uptime during peak traffic periods.

**Financial Services**: A digital bank implements sophisticated disaster recovery with multi-region failover. Database replication is monitored continuously; if replication lag exceeds thresholds, automated circuit breakers prevent writes to stale replicas. Deployment reliability practices ensure zero-downtime schema migrations. Result: RTO of 30 seconds, RPO of 5 seconds.

**SaaS Platform**: A development tools company uses Kubernetes for multi-tenant isolation. Pod disruption budgets ensure that node maintenance never cascades into widespread outages. Network reliability policies prevent noisy neighbor problems. Load balancing intelligently routes traffic based on real-time capacity metrics. Result: reduced customer impact from infrastructure maintenance.

**Mobile Social Network**: With billions of requests daily, self-healing must work at scale. Automated remediation workflows detect and remediate corrupted cache entries, restart stuck workers, and rebalance partition leadership across database clusters—all without human intervention. Result: 99.95% availability with 30% smaller ops team.

### Where Site Reliability Appears in Cloud Architecture

Site reliability engineering is **not a separate layer**; it's woven throughout cloud architecture:

- **Deployment Pipeline**: Automated canary deployments, smoke testing, and instant rollback mechanisms
- **Infrastructure Layer**: Self-healing infrastructure that detects failures and restores capacity automatically
- **Data Layer**: Replication, failover, backup, and consistency mechanisms that ensure data durability
- **Application Layer**: Circuit breakers, rate limiting, graceful degradation, and observability instrumentation
- **Network Layer**: DNS failover, load balancing, traffic shaping, partition healing
- **Observability Stack**: Metrics, logs, traces, and alerting that provide visibility into all layers

---

## Foundational Concepts

### Key Terminology

#### Service Level Objectives (SLOs)
An **SLO** is a target level of reliability you commit to users. It's expressed as a percentage (e.g., 99.9%) and backed by engineering effort and resource allocation. SLOs bridge business requirements and engineering reality.

**Example:** "Our API will be available 99.95% of the time, measured monthly on a best-effort basis."

Unlike SLAs (which are contracts with financial penalties for violation), SLOs are internal targets that guide engineering priorities and incident response decisions.

#### Service Level Indicators (SLIs)
An **SLI** is a measurement of a specific aspect of service behavior. It's the actual metric you track against your SLO.

**Examples:**
- Request latency at the 99th percentile
- Percentage of requests completed successfully
- Database replication lag
- DNS resolution time

Good SLIs are:
- **Actionable**: You can identify specific engineering work to improve them
- **Observable**: Measurable with existing infrastructure
- **User-centric**: Reflect what users actually experience

#### Error Budget
The **error budget** is the amount of downtime or errors allowed while staying within your SLO.

**Calculation:**
```
Error Budget = (1 - SLO) × Total Time Period

For 99.9% SLO over 1 month (43,200 minutes):
Error Budget = 0.001 × 43,200 = 43.2 minutes
```

Error budgets answer the critical question: *"How much operational imperfection can we tolerate?"* Once you've "spent" your error budget, you should pause new deployments and focus on stability improvements.

#### Mean Time to Recovery (MTTR)
The average time required to restore a failed system to operational status. Includes detection time, investigation time, and remediation time.

**Why it matters:** For fixed frequency of failures, reducing MTTR is equivalent to improving availability.

**Formula:**
```
Availability = MTTF / (MTTF + MTTR)
Where MTTF = Mean Time To Failure
```

#### Recovery Point Objective (RPO)
The maximum acceptable time lag for data recovery. It defines the maximum allowable data loss window.

**Example:** RPO of 5 minutes means you can afford to lose up to 5 minutes of data.

**Implications:**
- RPO of 1 hour → backup/replication every hour
- RPO of 1 minute → continuous replication required
- RPO of 0 → synchronous replication (higher latency, lower throughput)

#### Recovery Time Objective (RTO)
The maximum tolerable downtime. The time it should take to restore systems from the point of failure.

**Example:** RTO of 30 minutes means you must restore service within 30 minutes.

**RTO vs. RPO:**
- RTO = speed of recovery
- RPO = acceptabil data loss

For critical systems, you might need RTO=15min, RPO=1min. For non-critical, RTO=4hr, RPO=1hr.

### Architecture Fundamentals

#### High Availability Architecture Patterns

**Active-Active (Load-Shared)**
Multiple instances process traffic simultaneously. Load balancer distributes requests across instances.

```
[Client] -> [Load Balancer] -> [Instance A] (active)
                             -> [Instance B] (active)
                             -> [Instance C] (active)
```

**Advantages:**
- Maximizes resource utilization
- Scales linearly: N instances handle N× traffic
- No "standby" waste

**Disadvantages:**
- State management complexity
- Distributed transaction coordination challenges
- Difficult to maintain consistency

**Best for:** Stateless services, read-heavy workloads, microservices architectures

---

**Active-Passive (Hot-Standby)**
Primary instance handles all traffic; passive instance stands ready to take over immediately upon failure.

```
[Client] -> [Load Balancer] -> [Primary (active)]
                             -> [Secondary (standby)]
```

**Advantages:**
- Simple state management (no distributed state)
- Minimal consistency concerns
- Faster failover for stateful systems

**Disadvantages:**
- Underutilization of standby resources
- Failover detection must be extremely reliable
- Split-brain scenarios possible

**Best for:** Stateful services (databases, message brokers), systems requiring strong consistency

---

**N+1 Redundancy**
Operate with capacity for N+1 instances, so losing any single instance doesn't degrade performance.

```
Capacity needed: 40 requests/second
3 instances × 15 req/sec each = 45 req/sec capacity
If 1 fails: 2×15 = 30 req/sec (degraded but operational)
```

**This enables:**
- Rolling deployments without capacity loss
- Graceful degradation during failures
- Planned maintenance windows without disruption

#### Failure Domain Isolation

A **failure domain** is a set of infrastructure that can fail together. Proper isolation ensures single failures remain bounded.

**Common failure domains:**
- Single server (hardware failure)
- Availability Zone (data center-level outage)
- Region (catastrophic cloud provider issue)
- ISP (network provider failure)
- Rack (power/cooling system failure)

**Isolation strategy:**
```
Single instance failure → Application remains available (N+1)
AZ failure → Traffic routes to other AZs (multi-AZ deployment)
Region failure → Traffic routes to standby region (multi-region)
```

#### Blast Radius and Blast Radius Containment

**Blast radius** is the scope of impact when something fails.

**Without containment:**
```
Single service bug (memory leak) 
→ OOMKill → Pod eviction 
→ Node degraded 
→ Cascading pod evictions 
→ Entire cluster becomes unavailable
Blast radius: ALL services, ALL tenants, ALL transactions
```

**With containment (resource limits, circuit breakers, bulkheads):**
```
Single service bug 
→ Contained by resource limits 
→ Other services unaffected
Blast radius: Single tenant/service only
```

**Containment mechanisms:**
- Resource quotas and limits (CPU, memory, disk)
- Circuit breakers (fail fast before cascading)
- Rate limiting and request throttling
- Network policies and service mesh controls
- Pod disruption budgets
- Timeout policies

### Important DevOps Principles

#### The Principle of Least Surprise
Systems should behave in ways operators and engineers expect. When they surprise you, you've discovered a design problem.

**Anti-pattern:** Background cleanup job runs during peak traffic hours, suddenly consuming all disk I/O, causing application latency spike.
**Pattern:** Explicit scheduling and resource reservations ensure cleanup happens during low-traffic windows.

#### Observability Over Monitoring

**Monitoring** = Predefined queries and thresholds you set up in advance. You only see what you explicitly instrumented.

**Observability** = Ability to understand system internals from external outputs (logs, traces, metrics). You can ask arbitrary questions about behavior.

**Implication for SRE:**
- Monitoring catches known failure patterns
- Observability helps debug unknown failures
- Both are necessary; neither is sufficient alone

**Example:**
- Monitoring alert: "API latency > 1000ms"
- Observability discovery: "Why is latency spiking? Let me trace a request... I see: query took 700ms, network call took 200ms, serialization took 100ms"

#### Embrace Failure as Data

Rather than treating failures as anomalies to eliminate, treat them as data points for learning:

- Each incident contains information about your system's weaknesses
- Post-incident reviews (blameless) identify systemic improvements
- Chaos engineering intentionally triggers failures to discover weaknesses
- Failure budgets legitimize that perfection is not the goal

**Anti-pattern:** Punish humans for failures; respond with rigid rules ("no deployments on Friday")
**Pattern:** Analyze why failures happened; improve systems to prevent recurrence

#### Infrastructure as Code (IaC)

SRE philosophy requires that infrastructure be:
- **Versioned** like application code
- **Reviewable** before deployment
- **Testable** in staging environments
- **Reproducible** from code

This applies to:
- Cluster configurations (Terraform, CloudFormation)
- Application deployments (Helm, Kustomize)
- Network policies and firewall rules
- Monitoring and alerting configurations
- Disaster recovery procedures

#### Automation Over Manual Processes

The SRE principle: if you do something more than twice, automate it.

**Rationale:**
- Humans make mistakes (especially under pressure)
- Automation is consistent and repeatable
- Automation documents the process in executable form
- Automation scales: doesn't require additional humans for growth

**Progression:**
1. Manual process (error-prone, slow)
2. Documented runbook (faster, still error-prone)
3. Partially automated (faster, fewer errors)
4. Fully automated (fast, reliable, scalable)
5. Self-healing (automatic, no human involvement)

### Best Practices Across SRE

#### 1. Measure Everything That Matters

You cannot improve what you do not measure.

**What to measure:**
- User-facing metrics (latency, error rate, availability)
- System health metrics (CPU, memory, disk, network)
- Business metrics (requests served, transactions processed, revenue)
- Operational metrics (deployment frequency, lead time, MTTR)

**How to measure:**
- **Instrumentation**: Code changes to emit metrics/traces
- **Passive observation**: Network taps, proxy logs, load balancer metrics
- **Active monitoring**: Synthetic requests to validate availability
- **User experience monitoring**: JavaScript agents, mobile SDKs

#### 2. Test Failure Paths in Production

You cannot rely on staging to reveal all failure modes. Real production traffic, scale, and variety of conditions differ from staging.

**Modern approaches:**
- **Chaos Engineering**: Inject failures (kill processes, add latency, partition networks) and verify systems recover
- **Controlled Experiments**: Run A/B tests with new code on small traffic percentage; monitor for anomalies
- **Canary Deployments**: Roll out to small percentage; verify health before rolling to 100%
- **Feature Flags**: Deploy code but don't activate features; control rollout granularly

#### 3. Design for Graceful Degradation

Perfect availability is impossible. When subsystems fail, applications should degrade gracefully rather than fail completely.

**Example:**
```
Shopping cart recommendation engine fails
❌ Bad: Show error page → customer abandons checkout
✓ Good: Show generic recommendations / empty → checkout proceeds

User profile service times out
❌ Bad: Display blank profile → poor UX
✓ Good: Display cached profile from 1 hour ago → acceptable UX
```

#### 4. Build in Observability from Day One

Observability is not something you retrofit. It must be designed in:

- **Structured logging**: JSON logs with context, not unstructured text
- **Distributed tracing**: Follow requests across service boundaries
- **Metrics instrumentation**: Expose metrics at code instrumentation points
- **Health checks**: Explicit endpoints that report system health
- **Debug-level logging**: Off by default but available when needed

#### 5. Design for Operability

Code that's easy to run is more reliable. From an operator's perspective:

- **Explicit configuration**: Environment variables, config files, clearly documented
- **Health checks**: Services report readiness and liveness, not just availability
- **Graceful shutdown**: Finish in-flight requests, drain connections cleanly
- **Backwards compatibility**: Never break existing deployment configurations
- **Documentation**: RunBooks for common situations, troubleshooting guides

#### 6. Implement Strong SLO/SLI Discipline

Without clear SLOs:
- You don't know if reliability is acceptable
- Risk vs. feature tradeoffs are ambiguous
- You can't decide when to invest in reliability

**Best practice:**
1. Identify 3-5 critical SLIs
2. Set reasonable SLO (e.g., 99.9% based on business impact)
3. Measure SLI continuously
4. Use error budget to gate risky changes
5. Review and adjust quarterly

#### 7. On-Call Must Be Sustainable

Unsustainable on-call (constant interruptions, frequent pages) leads to:
- Burnout and retention problems
- Insufficient time for proactive work
- More incidents due to fatigue
- Poor hiring/retention

**Sustainability practices:**
- **Alert fatigue reduction**: False alerts undermine response credibility
- **Runbooks**: Reduce time to resolution
- **Adequate coverage**: Multiple people rotate, not single person on-call 24/7
- **Time off**: Time away from on-call is mandatory for mental health
- **Investment in automation**: Reduce repeat incidents

### Common Misunderstandings

#### Misunderstanding #1: "SRE means 99.99% uptime"

**The confusion:** SRE is often conflated with "high availability."

**The reality:** SRE is about *managed* reliability. Your SLO might be 99% (not 99.99%), and that's correct if your business can tolerate 99% uptime.

**What SRE actually means:**
- Explicitly define what reliability you need
- Allocate resources proportionally
- Don't over-engineer beyond business needs
- Invest error budget wisely

**Implication:** A 99% SLO with good automation might require less work than 99.9% with poor automation.

---

#### Misunderstanding #2: "SRE is DevOps for big companies"

**The confusion:** SRE came from Google; maybe it requires Google-scale infrastructure.

**The reality:** SRE principles apply to tiny startups and massive enterprises. Scale changes *implementation* but not *principles*.

**Startup vs. Enterprise:**
| Aspect | Startup | Enterprise |
|--------|---------|-----------|
| SLO | 99% acceptable, lower cost | 99.9%+ required, high cost |
| Automation focus | Self-healing, observability | Compliance, disaster recovery |
| Team structure | One person wears multiple hats | Specialized SRE team |
| Technology stack | Simpler, fewer components | Complex, many integrations |

---

#### Misunderstanding #3: "Self-healing means never touching systems"

**The confusion:** Automation should eliminate operational work entirely.

**The reality:** Self-healing handles *common* failures automatically. Novel failures still require humans.

**The continuum:**
- **Manual intervention**: Ops team SSHes into server, restarts service (slow, error-prone)
- **Monitoring + alerting**: Alerts sent; ops runs runbook to fix (faster, still manual)
- **Automated remediation**: System detects and fixes automatically (fastest, self-healing)
- **Adaptive systems**: System learns from failures, continuously improves (most sophisticated)

Goals for most organizations:
- 80-90% of incidents handled by self-healing
- 10-20% require human investigation and specialized fixes

---

#### Misunderstanding #4: "Reliability comes from redundancy alone"

**The confusion:** "We have active-active across 3 zones, so we're reliable."

**The reality:** Redundancy is necessary but not sufficient. You also need:
- **Proper failure detection** (quick MTTR depends on fast detection)
- **Proper failover logic** (smart routing, not just round-robin)
- **Testing** (proof that failover actually works)
- **Blast radius containment** (prevent cascade failures)

**Scenario:** You have 3-node service; node 1 slowly starts leaking memory. Clients still get responses, but with increasing latency. Load balancer doesn't notice (node is "up"). Result: degraded experience for all traffic hitting node 1, even though redundancy exists.

**Solution:** Add health checks that detect degradation, not just outages.

---

#### Misunderstanding #5: "SRE means on-call engineers fixing things"

**The confusion:** On-call is the most visible SRE activity, so SRE = on-call.

**The reality:** On-call is typically 20-30% of SRE work.

**Actual SRE time allocation:**
- **On-call incident response** (20-30%)
- **Automation and tooling** (30-40%)
- **Monitoring and observability** (15-20%)
- **Capacity planning and optimization** (10-15%)
- **Post-incident reviews and improvements** (10%)

The goal is to *reduce* on-call load through proactive work.

---

#### Misunderstanding #6: "Disaster Recovery = Backup"

**The confusion:** "We have daily backups, so we can recover from any disaster."

**The reality:** Backups enable recovery, but DR encompasses backup, recovery procedures, testing, and RTO/RPO planning.

**Gaps in backup-only approach:**
- Untested backups often don't work when needed (tested once during adoption, never again)
- Recovery procedures not documented or practiced
- RPO/RTO not defined; don't know if backup frequency matches business needs
- No failover automation; manual recovery takes hours

**Complete DR:**
- Regular backup + backup testing + failover procedures + automation + regular drills

---

#### Misunderstanding #7: "Load balancing is just distributing requests"

**The confusion:** Load balancer round-robins requests; that's it.

**The reality:** Modern load balancing is sophisticated. It should:
- Detect backend degradation and drain traffic before failover
- Implement advanced routing (by request characteristics, real-time capacity metrics)
- Handle connection draining gracefully
- Support session affinity where needed
- Provide observability into distribution decisions

---

## Automation & Self-Healing

### Principles of Automation

#### Why Automate?

**Consistency**: Humans make mistakes, especially under pressure. Automation is consistent.

**Scalability**: Automation doesn't require hiring more people as traffic grows.

**Speed**: Automated remediation (milliseconds) vs. human response (minutes).

**Documentation**: Automation documents procedures in executable form; runbooks become code.

#### Automation Funnel

```
Manual Process
    ↓ (recognize pattern)
Documented Runbook
    ↓ (write scripts)
Partially Automated (detection automatic, remediation scripted)
    ↓ (add feedback loops)
Fully Automated (detection + remediation + verification)
    ↓ (add learning)
Self-Healing (system learns and improves automatically)
```

#### When NOT to Automate

Automation isn't always appropriate:

- **Rare events**:  Happens once per year; cost of automation > cost of manual handling
- **Complex decision-making**: Requires context human judgment (e.g., "should we reject this request?")
- **New/experimental processes**: Wait until process stabilizes before automating
- **Regulatory compliance**: Some decisions must have human oversight (e.g., fraud detection)

**The principle:** Automate high-frequency, low-complexity, well-understood tasks. Leave judgment calls and rare events to humans.

### Principles of Self-Healing

#### Self-Healing Characteristics

A **self-healing system** detects abnormal conditions and automatically restores normal operations without human intervention.

**Required components:**
1. **Detection**: Identify that something is wrong (health check, metric threshold, error detection)
2. **Diagnosis**: Understand what's wrong and what to do about it
3. **Remediation**: Execute corrective action automatically
4. **Verification**: Confirm that remediation succeeded

#### Self-Healing Scopes

**Level 1: Process-Level Self-Healing**
Automatically restart crashed or hung processes.

```
health_check() every 10 seconds:
  if not responding:
    restart_process()
```

**Examples:**
- WordPress plugin crashes → automatically restart PHP-FPM
- Java application OOMKill → kubelet restarts container
- Database connection pool exhausted → restart connection handler

**Scope:** Single process
**MTTR:** Seconds
**Limitations:** Doesn't prevent cascading failures to other services

---

**Level 2: Service-Level Self-Healing**
Detect and remediate service-level issues.

```
detect service degradation:
  if throughput < threshold:
    scale_up()
  if latency > threshold:
    circuit_break_upstream()
  if error rate > threshold:
    fallback_to_cached_data()
```

**Examples:**
- Database connection pool 95% utilized → spin up additional instances
- API latency spike → shift traffic to standby region
- Cache miss rate > 50% → pre-warm cache in background

**Scope:** Single service or component
**MTTR:** Seconds to minutes
**Limitations:** Doesn't handle cascading failures across multiple services

---

**Level 3: Application-Level Self-Healing**
Application logic detects and recovers from transient failures.

```
async operation with retry logic:
  attempt 1: failed (transient error)
  wait 100ms
  attempt 2: failed (still transient)
  wait 200ms
  attempt 3: succeeded

Circuit breaker pattern:
  errors > threshold → OPEN (reject all calls)
  wait timeout → HALF_OPEN (try single call)
  if succeeds → CLOSED (resume normal operation)
```

**Examples:**
- Transient API failures → retry with exponential backoff
- Connection timeout to external service → use circuit breaker to fast-fail
- Cache miss → request from origin with retry

**Scope:** Intra-application
**MTTR:** Milliseconds
**Limitations:** Requires application logic changes

---

**Level 4: Cluster-Level Self-Healing**
Infrastructure automatically recovers from cluster-level issues.

```
node failure detection:
  if node /health check fails:
    drain node
    reschedule pods to other nodes
    remove node from cluster

pod resource problems:
  if pod latency degradation:
    move pod to node with resources
```

**Examples:**
- Kubernetes node fails → kubelet reschedules pods
- Node disk pressure → evict pods with local storage
- Node CPU pressure → deprioritize best-effort pods

**Scope:** Cluster/distributed system
**MTTR:** Seconds to minutes
**Limitations:** Requires proper orchestration (Kubernetes, nomad, etc.)

---

**Level 5: Data-Level Self-Healing**
Automatically detect and repair data inconsistencies.

```
background repair job:
  for each data partition:
    if source != replica:
      repair replica from source
    if checksum mismatch:
      rebuild from WAL
```

**Examples:**
- Database replication lag detected → re-sync replica
- Corrupted cache entry detected → invalidate and rebuild
- S3 object checksum mismatch → re-upload from source

**Scope:** Data integrity across distributed nodes
**MTTR:** Minutes to hours (background repair)
**Limitations:** Must not corrupt more data; requires careful ordering

---

**Level 6: Organizational Self-Healing**
Systems adapt behavior based on organizational policies and learning.

```
adaptive load shedding:
  if approaching capacity:
    shed low-priority requests
    (vs. shedding randomly)

intelligent degradation:
  if region fails:
    serve stale data
    reduce feature set
    (vs. returning error for all requests)
```

**Examples:**
- Load shedding prioritizes paying customers over free tier
- Feature flags auto-disable expensive features under high load
- API rate limiting relaxes for internal tools, stricter for external

**Scope:** Organization-specific policies applied system-wide
**MTTR:** Milliseconds
**Limitations:** Requires domain knowledge and business logic

#### The Cost of Self-Healing

Self-healing provides tremendous value, but has costs:

**Complexity**: Self-healing systems are harder to understand and debug.

**Resource overhead**: Continuously monitoring, diagnosing, and remediating consumes CPU/memory.

**Unexpected behavior**: Sometimes "healing" makes things worse (oscillations, thrashing).

**Testing burden**: Must test that self-healing actually works and doesn't create new problems.

**Best practice:** Start with simple self-healing (process restart), add sophistication only when justified.

### Popular Automation & Self-Healing Tools

#### Container Orchestration (Kubernetes)

**Self-healing capabilities:**
- Pod restart on failure (RestartPolicy)
- Node failure detection and rescheduling (kubelet, controller-manager)
- Resource requests/limits prevent resource exhaustion
- Health probes (liveness, readiness, startup)
- Pod disruption budgets prevent cascading evictions
- Horizontal pod autoscaling based on metrics

**Limitations:**
- Operator must configure health probes correctly
- Autoscaling requires metrics; doesn't work for novel failure modes
- Database persistence still requires manual setup

**Representative example:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    livenessProbe:
      httpGet:
        path: /health
        port: 80
      initialDelaySeconds: 10
      periodSeconds: 5
    readinessProbe:
      httpGet:
        path: /ready
        port: 80
```

#### HashiCorp Nomad

**Self-healing capabilities:**
- Job rescheduling when tasks fail
- Multi-region failover
- Resource-aware scheduling
- Health check integration
- Graceful shutdown coordination

**Use case advantage:** Works across heterogeneous infrastructure (VMs, containers, bare metal), not just containerized.

#### BOSH (deployment automation for VMs)

**Self-healing capabilities:**
- Process monitoring and restart
- VM resurrection (detected failed VM → replaced automatically)
- Deployment idempotency (can re-run without side effects)

**Use case advantage:** Widely used by cloud foundry, BOSH CF deployments.

#### Prometheus + AlertManager

**Automation capabilities:**
- Metrics collection and alerts
- Alert routing and silencing
- Integration with remediation tools

**Self-healing integration points:**
- Alert triggers remediation scripts
- Remediations update metrics
- Feedback loop detects success/failure

**Limitations:** Prometheus is passive; doesn't itself remediate (requires integration).

#### Ansible/Puppet/Chef (configuration management)

**Automation capabilities:**
- Infrastructure templating
- Idempotent execution (safe to re-run)
- Configuration drift detection
- Remediation through config updates

**Self-healing pattern:**
```
Configuration monitoring detects drift
  → trigger configuration management agent
  → pull latest config from version control
  → apply config (idempotently)
  → verify state
```

#### Custom Solutions: Operators, Controllers, Agents

**Kubernetes Operators** (golang-based custom controllers):
- Service-specific self-healing logic
- Examples: Etcd operator, MySQL operator, Cassandra operator
- Can implement sophisticated repair logic not possible with generic Kubernetes

**System Agents**:
- Custom code running on each system
- Can implement low-level, hardware-specific remediation
- Examples: Datadog agent, New Relic agent, custom remediation agents

### Implementing Automation in DevOps Environments

#### Step 1: Choose the Right Level of Automation

**Start simple, add complexity only when justified:**

- **P0 (critical services)**: Invest in sophisticated self-healing + automation
- **P1 (important services)**: Mid-level automation (alerting + basic remediation)
- **P2 (nice-to-have)**: Manual alerting; automation not justified
- **P3 (experimental)**: Manual processes; wait for stabilization

**Implement in order:**
1. Monitoring and alerting (prerequisites for automation)
2. Runbooks (document the process to automate)
3. Manual remediation scripts (operators run them)
4. Automated remediation (monitoring triggers scripts)
5. Adaptive remediation (learning from experiences)

#### Step 2: Build on Existing Platforms

**Don't build from scratch; leverage existing:**
- Kubernetes for container orchestration and self-healing
- External configuration services (HCP Consul, etcd) for dynamic configuration
- Message queues for asynchronous remediation workflows
- Existing monitoring infrastructure (Prometheus, Datadog, etc.)

#### Step 3: Implement Feedback Loops

Automation that doesn't verify its success can make things worse.

```
Remediation flow:
1. Detect problem (alert triggered)
2. Execute remediation action
3. Verify remediation succeeded (crucial!)
4. If failed: escalate to human, don't retry indefinitely
5. If succeeded: record metrics, close incident
```

**Never implement:**
```
while problem_detected():
  remediate()   # what if remediation keeps failing?
              # thrashing, resource exhaustion!
```

#### Step 4: Make Remediation Idempotent

Automation might retry if first attempt fails. Each attempt should be safe.

**Bad (not idempotent):**
```bash
# Creates a new volume each time it runs
aws ec2 create-volume --size 100
```

**Good (idempotent):**
```bash
# Uses existing volume if present
VOLUME=$(aws ec2 describe-volumes --filters "Name=tag:purpose,Values=cache" --query 'Volumes[0].VolumeId' --output text)
if [ -z "$VOLUME" ]; then
  VOLUME=$(aws ec2 create-volume --size 100 --query 'VolumeId' --output text)
  aws ec2 create-tags --resources $VOLUME --tags Key=purpose,Value=cache
fi
attach-volume $VOLUME
```

#### Step 5: Test in Production Safely

**Testing strategies:**
- **Canary deployments**: Automated fixes deployed to small % first
- **Feature flags**: Activation can be toggled quickly if issues arise
- **Chaos engineering**: Intentionally trigger failures in test environment, verify remediation
- **Production experiments**: Run remediation against non-critical systems first

#### Step 6: Maintain Observability

Automation must be instrumentable to debug when things go wrong.

**Instrumenting remediation:**
```python
@remediator
def restart_service(service_name):
  start_time = time.time()
  logger.info(f"Restarting {service_name}")
  
  try:
    subprocess.run(["systemctl", "restart", service_name], timeout=30)
    duration = time.time() - start_time
    
    # Emit success metric
    metrics.histogram("remediation.duration_seconds", duration, 
                     tags={"service": service_name, "status": "success"})
    logger.info(f"Restart succeeded in {duration}s")
    
    return True
  except Exception as e:
    # Emit failure metric
    metrics.increment("remediation.failures", tags={"service": service_name})
    logger.error(f"Restart failed: {e}")
    return False
```

### Auto-Remediation Workflows

#### Workflow 1: Cascading Alerts with Escalation

```
Alert triggered (severity: warning)
  ↓ (if auto-remediation enabled)
Execute remediation script (with timeout)
  ↙              ↘
Success        Timeout/Failure
  ↓              ↓
Resolve alert    Escalate to high-severity alert
                 ↓
                 Page on-call engineer
```

**Implementation points:**
- Remediation must have timeout (don't hang forever)
- Track success/failure metrics
- Escalation policy depends on service importance
- Critical services: lower timeout before escalation
- Non-critical: higher timeout, more retries

#### Workflow 2: Self-Healing with Limits

```
Health check fails
  ↓
Auto-healing attempt #1
  ↓
If failed: retry with backoff (exponential)
  ↓
After N retries or exceeding time window:
  ↓
Stop auto-healing, alert human
```

**Why limits matter:** Prevent thrashing when root cause is human error or requires investigation.

**Example:**
```
Application consuming 100% CPU
  ↓ (auto-remediation: restart)
Restart succeeds briefly → CPU goes to 10%
  ↓ 1 minute later
CPU climbs to 100% again
  ↓ (auto-remediation #2: restart)
Repeat 5 times
  ↓ (hit retry limit)
Alert: "Service in oscillation; probable bug; human investigation required"
```

#### Workflow 3: Adaptive Remediation

```
Detect failure class
  ↓
Look up known remediation patterns in knowledge base
  ↓
Apply remediation
  ↓
Did it work?  
  ├─ Yes: Record success (improves knowledge base)
  └─ No: Try next remediation pattern
           If all fail: escalate
```

**Requires:**
- Structured failure classification
- Knowledge base of remediation patterns
- Success/failure tracking
- Feedback loop to improve knowledge base

---

## Deployment Reliability

### Principles of Deployment Reliability

#### What is Deployment Reliability?

Deployment reliability is the discipline ensuring that:

1. **Deployments don't introduce regressions** (new bugs in working features)
2. **Deployments don't increase downtime** (zero-downtime deployments)
3. **Deployments are reversible** (rollback available if things go wrong)
4. **Deployments provide audit trail** (what changed, when, by whom)
5. **Deployments follow change control** (adequate review and approval)

#### Why Deployment Matters

Deployments are among the highest-risk operational activities:

- Code changes introduce bugs
- Infrastructure changes cause cascading failures
- Configuration changes break working systems
- Data migrations corrupt or lose data
- Network changes partition systems

**Statistics:** Most incidents are triggered by deployment changes. Therefore, reliable deployment processes have outsized impact on overall reliability.

#### Risk Factors in Deployments

**Large blast radius:** Deploying to everything simultaneously means a bug affects all users.

**Irreversible changes:** A data migration that fails halfway, leaving system in inconsistent state.

**Cascading dependencies:** Deploying service X breaks service Y (undeclared dependency).

**Configuration drift:** Configuration changes not version-controlled lead to inconsistency across environments.

**Lack of rollback plan:** No automation to undo failed deployment; manual rollback takes hours.

### Popular Deployment Reliability Tools

#### Blue-Green Deployment Pattern

**Concept:** Maintain two identical production environments (blue, green). Deploy to inactive environment, then switch traffic.

```
[Load Balancer] 
    ↓
    ├─→ [Blue Environment] (version 1.0) ← currently serving traffic
    └─→ [Green Environment] (version 1.1) ← new version deployed
    
After deployment verified:
[Load Balancer] switches to point to Green
    ↓
    ├─→ [Blue Environment] (version 1.0) ← can quickly rollback
    └─→ [Green Environment] (version 1.1) ← now serving traffic
```

**Advantages:**
- True zero-downtime (traffic switches instantly)
- Instant rollback (switch back to blue)
- New environment fully tested before traffic

**Disadvantages:**
- Requires 2x infrastructure (expensive)
- Data replication between blue/green needed for stateful systems
- Complex DNS switching without client caching

**Best for:** Stateless services, high-traffic systems where downtime is costly

**Tools:** AWS CodeDeploy, custom load balancer configurations, Kubernetes (via service switching)

---

#### Canary Deployments

**Concept:** Deploy new version to small percentage of traffic, monitor for errors, gradually increase percentage.

```
Deployment: 100% on v1.0
    ↓ Deploy v1.1 to 5% of servers
v1.0: 95%, v1.1: 5%
    ↓ Monitor for errors in v1.1 cohort
No errors detected →  increase to 10%
v1.0: 90%, v1.1: 10%
    ↓ Continue until 100%
v1.0: 0%, v1.1: 100% (complete)
```

**Advantages:**
- Gradual risk increase
- Catches errors before affecting all users
- Continuous user experience (no cutover moment)
- Efficient resource usage (no 2x infrastructure)

**Disadvantages:**
- Slower rollout (takes longer to reach 100%)
- Requires request routing by percentage (load balancer, service mesh)
- Requires observability to detect problems in canary cohort

**Best for:** Low-risk changes, high-traffic systems, cost-conscious organizations

**Tools:** Flagger (Kubernetes), Spinnaker, Kubernetes traffic management, service mesh (Istio, Linkerd)

**Example (Flagger + Kubernetes):**
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: my-app
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  maxWeight: 50       # gradually increase to 50%
  stepWeight: 5       # increase by 5% each step
  interval: 1m        # check every 1 minute
  analysis:
    interval: 1m
    threshold: 5      # rollback if error rate > 5%
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
```

---

#### Rolling Deployments

**Concept:** Gradually replace old instances with new instances, one at a time.

```
Initial: [v1] [v1] [v1] [v1]
Step 1:  [v1] [v1] [v1] [v1'] ← wait for v1' to be ready
Step 2:  [v1] [v1] [v1'] [v1'] ← wait for stability
Step 3:  [v1] [v1'] [v1'] [v1']
Step 4:  [v1'] [v1'] [v1'] [v1']
Complete (all on v1')
```

**Advantages:**
- Maintains N+1 capacity during deployment (can tolerate failure)
- No additional infrastructure required
- Gradual rollout allows early detection of issues

**Disadvantages:**
- Vulnerable to database schema incompatibilities (old/new code on same schema)
- State not fully reset between steps (caches, connections might be stale)
- Takes time to complete

**Best for:** Stateless services, frequent deployments, resource-constrained environments

**Implementation:** Kubernetes default deployment strategy

---

#### Shadow/Dark Deployments

**Concept:** Deploy new version, but only route a percentage of traffic to it (duplicated traffic).

```
[Load Balancer]
    ├─→ [v1.0 - Primary] (serves users, metrics recorded)
    └─→ [v1.1 - Shadow] (handles duplicate traffic, metrics recorded but traffic dropped)

Compare metrics:
  - v1.0 error rate: 0.1%
  - v1.1 error rate: 2%  ← new version has bug, don't promote
```

**Advantages:**
- Test new version with production traffic characteristics
- No user impact if new version fails
- Discover issues before traffic is actually affected

**Disadvantages:**
- Requires traffic duplication infrastructure (expensive)
- Metrics difference might not show up at small scale
- Real production state (DB, caches) not available to shadow

**Best for:** High-risk deployments, complex business logic changes, performance-sensitive changes

---

#### Database-Agnostic Deployments

**Concept:** Ensure code remains compatible with multiple schema versions during deployment.

```
Database v1 schema: users table with email field
Application v1.0: code reads email from users table

Prepare deployment:
  1. Add new field to schema (nullable)
  2. Deploy code that reads from both old and new fields
  3. Later: migrate data, remove old field

Application v1.1: code reads from new field

Result: code migration and schema migration are decoupled
```

**Key principle:** Code should be compatible with N and N+1 schema versions.

**Strategy:**

```
Step 1: Schema migration (backwards compatible)
  - Add new field as nullable
  - Code still uses old field
  - Deploy to DB
  
Step 2: Application code update
  - Deploy new app code (reads both old and new)
  - Both fields populated for consistency
  
Step 3: Data migration
  - Migrate data from old field to new field
  
Step 4: Cleanup (after stability verification)
  - Remove code reading old field
  - Remove old field from schema
```

**Advantages:**
- Decouples application and database deployments
- Safer rollback (old app still works, old schema still works)
- Reduces stress (no coordinated deployments)

**Disadvantages:**
- Requires careful planning
- Temporary bloat (old and new fields existing simultaneously)
- Slow (multiple deployments vs. one big change)

**Tools:** Liquibase, Flyway, custom migration scripts

### Deployment Strategies

#### Deployment Strategies Comparison

| Strategy | Downtime | Speed | Complexity | Rollback | Cost |
|----------|----------|-------|-----------|----------|------|
| Blue-Green | 0 | Fast | Medium | Instant | High (2x infra) |
| Canary | 0 | Slow | High | Gradual | Low |
| Rolling | 0 (N+1) | Medium | Low | Gradual | Low |
| Shadow | 0 | Medium | Very High | Instant | Very High |
| Big Bang | Possible | Fast | Low | Manual | Low |

#### Choosing the Right Strategy

**Blue-Green:**
- When: Cost not a constraint, downtime unacceptable
- Examples: Payment systems, trading platforms, SaaS production

**Canary:**
- When: Want to catch errors early but cost-conscious
- Examples: Most microservices, web applications

**Rolling:**
- When: Simple services, infrequent deployments
- Examples: Traditional monoliths, stateless web servers

**Shadow:**
- When: High-risk changes, need confidence before production
- Examples: Algorithm changes, major logic refactors

**Big Bang:**
- When: Scheduled maintenance window, tolerated downtime
- Examples: Batch processing jobs, offline systems, one-time migrations

### Rollback Automation

#### What Requires Rollback Automation?

**Application code:** Previous version running before failed deployment
**Configuration:** Previous configuration after failed config push
**Database schema:** Previous schema after failed migration
**Infrastructure:** Previous infrastructure state after failed provisioning

#### Automatic Rollback Triggers

**When to automatically rollback:**

1. **Error rate spike**: New deployment increases error rate > threshold
2. **Latency spike**: Response time increases > threshold
3. **Health check failures**: Services stop responding to health probes
4. **Capacity exhaustion**: Memory/CPU spike beyond capacity
5. **Cascading failures**: Service A's deployment breaks dependent service B

**Example (Prometheus alert triggering rollback):**
```yaml
alert: HighErrorRate
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
for: 1m
annotations:
  action: "trigger_rollback"
  deployment: "{{ $labels.deployment }}"
```

#### Rollback Strategies

**Full rollback (atomic):**
- Revert all changes at once
- Fastest, safest for obvious regressions
- Simple to implement

**Gradual rollback (inverse canary):**
- Shift traffic back to old version gradually
- Safer for subtle issues (might be intermittent bugs, not clear breaks)
- Good when distinction between old/new unclear

**Canary rollback:**
- Route small percentage of traffic to rollback
- Verify rollback itself doesn't cause issues
- Extra-conservative

#### Rollback Best Practices

**1. Test rollback procedures regularly**
- Not just during incidents (too much stress)
- Schedule weekly/monthly rollback tests
- Verify rollback actually works before deploying code

**2. Ensure version N-1 is always deployable**
- Keep previous version's data compatible with previous app version
- Don't assume you can only go back 1 version

**3. Implement drain procedures before rollback**
- Finish in-flight requests gracefully
- Close client connections cleanly
- Prevents partial request failures during rollback

**4. Segment rollback decisions by feature**
- Don't rollback entire deployment for single feature bug
- Use feature flags to disable problematic feature
- Reduce team stress and notification fatigue

**5. Communicate rollback status clearly**
- Notify customers if rollback affects them
- Include rollback reason in incident report
- Track rollback frequency (indicator of deployment quality)

---

---

## Infrastructure Reliability

### Textual Deep Dive

#### Internal Working Mechanism

Infrastructure reliability focuses on ensuring that the underlying compute, storage, and networking resources remain available and performant. At its core, infrastructure reliability requires three mechanisms working in concert:

**1. Health Detection and Monitoring**

Modern infrastructure must continuously self-monitor. Health detection operates at multiple levels:

- **Hypervisor level:** The underlying virtualization layer detects VM crashes, hardware failures
- **Guest OS level:** Operating system detects disk corruption, kernel panics
- **Service level:** Applications report via health endpoints (HTTP 200 = healthy)
- **Infrastructure metrics:** CPU, memory, disk, network statistics

The key insight: *detection latency directly impacts availability*. If detection takes 5 minutes, your application is unavailable for 5 minutes before remediation begins.

**2. Failure Isolation and Containment**

Not all infrastructure failures require immediate replacement. Some can be contained:

```
Hardware failure → Isolate to single node
             → Reschedule workloads to other nodes
             → Don't cascade to dependent systems

Network packet loss → Detect degradation in one NIC
                   → Route traffic to other NIC
                   → Don't fail entire host

Disk space → Detect threshold breach
          → Trigger deletion of old logs/caches
          → Don't evict applications immediately
```

**3. Automated Recovery and Replacement**

When isolation isn't possible, automated recovery procedures activate:

```
VM failure detection → Trigger VM restart (quick)
                    → If restart fails → Provision new VM
                    → Attach volumes from failed VM
                    → Update DNS/load balancer
                    → Resume serving traffic
```

#### Architecture Role

Infrastructure reliability is the **foundation layer** in the SRE stack:

```
[Application Layer] ← depends on
[Kubernetes/Orchestration] ← depends on
[Infrastructure Layer (compute, storage, network)] ← depends on
[Physical DC/Cloud Provider]
```

If infrastructure layer is unreliable:
- Kubernetes resilience features become ineffective (can't reschedule to healthy nodes if none exist)
- Application-level resilience features are bypassed (entire availability zone goes down)

**Implication:** Infrastructure reliability is non-negotiable; it's the prerequisite for all higher-level resilience.

#### Production Usage Patterns

**Pattern 1: N+1 Capacity Planning**

Production systems maintain excess capacity:

```
Expected peak load: 80 req/sec
Provisioned capacity: 100 req/sec (N+1)
If 1 instance fails (80 req/sec lost): 20 req/sec headroom remains
Result: Service degrades but doesn't fail; users experience slower response, not errors
```

**Implications:**
- Capacity planning must account for failure
- "100% utilization" in production is dangerous
- 70-80% sustained utilization is typical target

**Pattern 2: Multi-Zone Deployments**

Distribute workloads across failure domains:

```
Availability Zone A: 4 instances (40 req/sec each)
Availability Zone B: 4 instances (40 req/sec each)
Availability Zone C: 4 instances (40 req/sec each)
Total: 480 req/sec across 3 zones

Scenario: 1 zone fails
Remaining: 2 zones with 320 req/sec capacity
Result: 33% capacity loss; system operates degraded but online
```

**Pattern 3: Automated Self-Healing Infrastructure**

Infrastructure detects and remediates its own failures:

```
Host monitoring detects:
  - Disk at 95% capacity
  - Triggers cleanup job
  - Deletes old logs, container images
  - Brings disk to 60%
  - No operator intervention

Container health check fails
  - Container engine detects
  - Kills container
  - Starts replacement
  - Health check passes
  - Traffic resumes within seconds
```

**Pattern 4: Graceful Degradation Under Partial Failures**

Rather than failing when infrastructure is partially degraded, applications operate at reduced capacity:

```
3 database instances normally provide 900 concurrent connections
If 1 instance fails: 600 connections available
Applications see connection pool warnings, activate backpressure
New requests queued, old requests served slower
System remains available, doesn't cascade fail
```

#### DevOps Best Practices

**1. Implement Comprehensive Health Checks**

Health checks must detect degradation, not just outages:

```bash
# Bad health check (only checks if process is running)
curl http://localhost:8080/ping && echo "healthy" || echo "dead"

# Good health check (detects degradation)
curl http://localhost:8080/health/detailed | jq '{
  status: .status,
  database_latency: .database_ms,
  cache_hit_rate: .cache_hit_ratio,
  queue_depth: .queue_size
}'

# Interpretation: 
# status=ok but database_latency=5000ms signals degradation
# Should trigger scaling before failure
```

**2. Prove Disaster Recovery Works**

Regular DR drills validate infrastructure assumptions:

```bash
#!/bin/bash
# Monthly infrastructure DR test

# Simulate 1 AZ failure by draining nodes
kubectl drain node az-a-1 node az-a-2 node az-a-3 --force --delete-emptydir-data

# Monitor:
# - Are pods rescheduling to az-b and az-c?
# - Is traffic still flowing?
# - Are error rates increasing?

# After 30 minutes, restore
kubectl uncordon node az-a-1 node az-a-2 node az-a-3

# Validate:
# - Did pods reschedule back?
# - Was there any cascading failure?
# - Was recovery time < RTO target?
```

**3. Separate Data and Compute Failure Domains**

Infrastructure design should prevent data loss from compute failures:

```
❌ Bad: Pod with persistent storage on local node
   If node fails → data lost → unrecoverable

✓ Good: Pod with persistent storage on external service
   If pod node fails → reschedule pod to another node
   Pod reconnects to same persistent storage → data safe
```

**4. Instrument Everything**

Infrastructure metrics inform reliability decisions:

```
Track:
- Instance startup time (should be <30 seconds)
- Instance replacement frequency (high = instability)
- Cross-AZ network latency (affects failover speed)
- Storage IOPS consumed (early warning of saturation)
- Network connectivity events (link flaps)
```

**5. Automate Configuration Management**

Infrastructure must be reproducible from code:

```bash
# All infrastructure created by terraform
# All configuration managed by Ansible/Puppet

# Result:
# - New VM provisioned with exact same software stack
# - Configuration drift detected and corrected
# - Disaster recovery simplified (IaC contains recovery procedure)
```

#### Common Pitfalls

**Pitfall 1: Assuming Shared Storage is Reliable**

```
❌ Anti-pattern: All pods attach to shared NFS storage
   If NFS cluster fails → all pods lose access → cascade failure
   
✓ Pattern: Each pod has its own storage; replicate data independently
```

**Pitfall 2: Over-Packing Resources**

```
❌ 24 cores, 96GB RAM, running 12 containers at 2 cores, 8GB each = 100% utilization
   Single noisy neighbor problem → all containers affected
   Autoscaling can't add capacity (none available)

✓ 24 cores but running only 6 containers = 50% utilization
   Noisy neighbor affects only that container
   Autoscaling has room to work
```

**Pitfall 3: Ignoring Infrastructure Lifecycle**

```
❌ VMs provisioned 5 years ago, never updated
   Kernels with known vulnerabilities
   Storage subsystems approaching end-of-life
   Result: Increasing failure rate, degraded performance

✓ Rolling replacement: old VMs continuously replaced with new ones
   Kernel patches deployed automatically
   Hardware upgraded before failures occur
```

**Pitfall 4: No Spare Capacity**

```
❌ Infrastructure sized exactly for peak load
   No buffer for failures, deployments, or spikes
   Any failure causes immediate cascading failures

✓ N+1 capacity minimum; N+2 for critical systems
   Failures trigger graceful degradation, not outage
```

**Pitfall 5: Trusting Infrastructure Provider's SLA Blindly**

```
❌ "AWS guarantees 99.99% availability, so we don't need to replicate"

✓ Multi-region deployment despite provider SLAs
   Reason: Even if AWS achieves 99.99%, that's 4.4 minutes/month
   If you have 5 regions, probability all 5 down << 0.0001%
```

### Practical Code Examples

#### CloudFormation: Highly Available Infrastructure

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Highly available infrastructure with auto-healing'

Parameters:
  Environment:
    Type: String
    Default: production
  DesiredCapacity:
    Type: Number
    Default: 6
    Description: 'Desired count across 3 AZs (2 per AZ)'

Resources:
  # Network
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-vpc'

  # Subnets across 3 AZs
  SubnetAZ1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true

  SubnetAZ2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      MapPublicIpOnLaunch: true

  SubnetAZ3:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.3.0/24
      AvailabilityZone: !Select [2, !GetAZs '']
      MapPublicIpOnLaunch: true

  # Internet Gateway
  IGW:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-igw'

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref IGW

  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-public-rt'

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref IGW

  # Subnet route table associations
  SubnetAZ1RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetAZ1
      RouteTableId: !Ref PublicRouteTable

  SubnetAZ2RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetAZ2
      RouteTableId: !Ref PublicRouteTable

  SubnetAZ3RouteAssociation:
    Type: AWS::EC2::SubnetRouteTableAssociation
    Properties:
      SubnetId: !Ref SubnetAZ3
      RouteTableId: !Ref PublicRouteTable

  # Security Group
  InstanceSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: 'Security group for application instances'
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          CidrIp: 0.0.0.0/0
          Description: 'Health check port'

  # Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Name: !Sub '${Environment}-alb'
      Type: application
      Scheme: internet-facing
      SecurityGroups:
        - !Ref InstanceSecurityGroup
      Subnets:
        - !Ref SubnetAZ1
        - !Ref SubnetAZ2
        - !Ref SubnetAZ3
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-alb'

  # Target Group
  TargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: !Sub '${Environment}-tg'
      Port: 80
      Protocol: HTTP
      VpcId: !Ref VPC
      HealthCheckEnabled: true
      HealthCheckProtocol: HTTP
      HealthCheckPath: /health
      HealthCheckIntervalSeconds: 15
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2              # 2 healthy checks to mark healthy
      UnhealthyThresholdCount: 2            # 2 failed checks to mark unhealthy
      Matcher:
        HttpCode: '200-299'
      TargetType: instance
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-tg'

  # ALB Listener
  ALBListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref TargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP

  # Launch Template for auto-scaling
  LaunchTemplate:
    Type: AWS::EC2::LaunchTemplate
    Properties:
      LaunchTemplateData:
        ImageId: ami-0c55b159cbfafe1f0  # Amazon Linux 2 AMI
        InstanceType: t3.medium
        IamInstanceProfile:
          Arn: !GetAtt InstanceRole.Arn
        SecurityGroupIds:
          - !Ref InstanceSecurityGroup
        UserData:
          Fn::Base64: !Sub |
            #!/bin/bash
            yum update -y
            yum install -y docker
            systemctl start docker
            systemctl enable docker
            
            # Run application container
            docker run -d \
              --name app \
              --restart unless-stopped \
              -p 80:8080 \
              -e ENVIRONMENT=${Environment} \
              my-app:latest
            
            # Add health check
            cat > /opt/health-check.sh << 'EOF'
            #!/bin/bash
            curl -f http://localhost:8080/health || exit 1
            EOF
            chmod +x /opt/health-check.sh

  # Instance Role for SSM access
  InstanceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-instance-role'

  # Auto Scaling Group - distributes across 3 AZs
  AutoScalingGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      AutoScalingGroupName: !Sub '${Environment}-asg'
      VPCZoneIdentifier:
        - !Ref SubnetAZ1
        - !Ref SubnetAZ2
        - !Ref SubnetAZ3
      LaunchTemplate:
        LaunchTemplateId: !Ref LaunchTemplate
        Version: !GetAtt LaunchTemplate.LatestVersionNumber
      MinSize: !Ref DesiredCapacity      # 6 minimum
      MaxSize: !Ref DesiredCapacity       # Can scale to 12
      DesiredCapacity: !Ref DesiredCapacity
      HealthCheckType: ELB
      HealthCheckGracePeriod: 300         # 5 minutes before health checks
      TargetGroupARNs:
        - !Ref TargetGroup
      VPCZoneIdentifier:
        - !Ref SubnetAZ1
        - !Ref SubnetAZ2
        - !Ref SubnetAZ3
      Tags:
        - Key: Name
          Value: !Sub '${Environment}-instance'
          PropagateAtLaunch: true

  # Scaling Policies
  ScaleUpPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !Ref AutoScalingGroup
      Cooldown: 300
      ScalingAdjustment: 2                # Add 2 instances

  ScaleDownPolicy:
    Type: AWS::AutoScaling::ScalingPolicy
    Properties:
      AdjustmentType: ChangeInCapacity
      AutoScalingGroupName: !Ref AutoScalingGroup
      Cooldown: 600
      ScalingAdjustment: -1               # Remove 1 instance

  # CloudWatch Alarms
  HighCPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${Environment}-high-cpu'
      MetricName: CPUUtilization
      Namespace: AWS/EC2
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 70
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref ScaleUpPolicy
      Dimensions:
        - Name: AutoScalingGroupName
          Value: !Ref AutoScalingGroup

  HighMemoryAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${Environment}-high-memory'
      MetricName: MemoryUtilization
      Namespace: CWAgent                  # Requires CloudWatch agent
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      AlarmActions:
        - !Ref ScaleUpPolicy
      Dimensions:
        - Name: AutoScalingGroupName
          Value: !Ref AutoScalingGroup

  # Alarm for failed health checks
  UnhealthyHostAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: !Sub '${Environment}-unhealthy-hosts'
      MetricName: UnHealthyHostCount
      Namespace: AWS/ApplicationELB
      Statistic: Average
      Period: 60
      EvaluationPeriods: 2
      Threshold: 1
      ComparisonOperator: GreaterThanOrEqualToThreshold
      AlarmActions:
        - !Ref ScaleUpPolicy
      Dimensions:
        - Name: LoadBalancer
          Value: !GetAtt ApplicationLoadBalancer.LoadBalancerFullName
        - Name: TargetGroup
          Value: !GetAtt TargetGroup.TargetGroupFullName

Outputs:
  LoadBalancerDNS:
    Description: 'DNS name of the load balancer'
    Value: !GetAtt ApplicationLoadBalancer.DNSName
  AutoScalingGroupName:
    Description: 'Name of Auto Scaling Group'
    Value: !Ref AutoScalingGroup
  TargetGroupArn:
    Description: 'ARN of target group'
    Value: !Ref TargetGroup
```

#### Infrastructure Monitoring Script

```bash
#!/bin/bash
# Comprehensive infrastructure health monitoring
# Used in production for continuous health validation

set -e

ENVIRONMENT="${ENVIRONMENT:-production}"
ALERT_THRESHOLD_CPU=75
ALERT_THRESHOLD_MEMORY=80
ALERT_THRESHOLD_DISK=85
ALERT_THRESHOLD_NETWORK_ERROR_RATE=1  # percent

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Check CPU Utilization
check_cpu() {
    log_info "Checking CPU utilization..."
    
    # Get CPU data from /proc/stat
    local cpu_total=$(grep -m1 '^cpu ' /proc/stat | awk '{print $2+$3+$4+$5+$6+$7+$8+$9}')
    local cpu_idle=$(grep -m1 '^cpu ' /proc/stat | awk '{print $5}')
    
    # For simpler approach, use top
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        log_error "CPU utilization high: ${cpu_usage}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
        return 1
    else
        log_info "CPU OK: ${cpu_usage}%"
        return 0
    fi
}

# 2. Check Memory Utilization
check_memory() {
    log_info "Checking memory utilization..."
    
    local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    local mem_used=$((mem_total - mem_available))
    local mem_percent=$((mem_used * 100 / mem_total))
    
    if (( mem_percent > ALERT_THRESHOLD_MEMORY )); then
        log_error "Memory utilization high: ${mem_percent}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
        return 1
    else
        log_info "Memory OK: ${mem_percent}%"
        return 0
    fi
}

# 3. Check Disk Utilization
check_disk() {
    log_info "Checking disk utilization..."
    
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    
    if (( disk_usage > ALERT_THRESHOLD_DISK )); then
        log_error "Disk utilization high: ${disk_usage}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
        return 1
    else
        log_info "Disk OK: ${disk_usage}%"
        return 0
    fi
}

# 4. Check Network Interface Health
check_network() {
    log_info "Checking network interface health..."
    
    local failed=0
    
    # Check each network interface for errors
    for interface in $(ls /sys/class/net/); do
        if [ "$interface" = "lo" ]; then
            continue
        fi
        
        local rx_errors=$(cat /sys/class/net/$interface/statistics/rx_errors 2>/dev/null || echo "0")
        local tx_errors=$(cat /sys/class/net/$interface/statistics/tx_errors 2>/dev/null || echo "0")
        local rx_packets=$(cat /sys/class/net/$interface/statistics/rx_packets 2>/dev/null || echo "1")
        
        local error_rate=$((rx_errors * 100 / (rx_packets + 1)))
        
        if (( error_rate > ALERT_THRESHOLD_NETWORK_ERROR_RATE )); then
            log_error "Network $interface error rate high: ${error_rate}%"
            ((failed++))
        else
            log_info "Network $interface OK: ${error_rate}% error rate"
        fi
    done
    
    [ $failed -eq 0 ]
}

# 5. Check Container/Pod Health (if Kubernetes)
check_kubernetes_health() {
    log_info "Checking Kubernetes health..."
    
    if ! command -v kubectl &> /dev/null; then
        log_warn "kubectl not found; skipping Kubernetes checks"
        return 0
    fi
    
    # Check node status
    local notready_nodes=$(kubectl get nodes --no-headers | grep -c "NotReady" || true)
    if [ $notready_nodes -gt 0 ]; then
        log_error "Found $notready_nodes nodes in NotReady state"
        return 1
    fi
    
    # Check pod status
    local failed_pods=$(kubectl get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded --no-headers 2>/dev/null | wc -l)
    if [ $failed_pods -gt 0 ]; then
        log_error "Found $failed_pods pods not in Running/Succeeded state"
        return 1
    fi
    
    log_info "Kubernetes health OK"
    return 0
}

# 6. Check System Load Average
check_load_average() {
    log_info "Checking system load average..."
    
    local load=$(load | awk -F'load average:' '{print $2}' | cut -d',' -f1)
    local cpu_count=$(nproc)
    local load_threshold=$cpu_count
    
    if (( $(echo "$load > $load_threshold" | bc -l) )); then
        log_warn "System load high: $load (CPU count: $cpu_count)"
    else
        log_info "System load OK: $load"
    fi
}

# 7. Check Critical Services
check_services() {
    log_info "Checking critical services..."
    
    local services=("docker" "kubelet" "networking")
    local failed=0
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service; then
            log_info "Service $service: active"
        else
            log_error "Service $service: not active"
            ((failed++))
        fi
    done
    
    [ $failed -eq 0 ]
}

# Main execution
main() {
    log_info "Starting infrastructure health check for $ENVIRONMENT"
    
    local failed_checks=0
    
    check_cpu || ((failed_checks++))
    check_memory || ((failed_checks++))
    check_disk || ((failed_checks++))
    check_network || ((failed_checks++))
    check_kubernetes_health || ((failed_checks++))
    check_load_average || ((failed_checks++))
    check_services || ((failed_checks++))
    
    if [ $failed_checks -eq 0 ]; then
        log_info "All infrastructure checks passed!"
        exit 0
    else
        log_error "Infrastructure health check failed with $failed_checks issues"
        exit 1
    fi
}

main "$@"
```

### ASCII Diagrams

#### Multi-Zone Infrastructure Architecture

```
                          Internet
                             |
                             |
                    ┌────────┴────────┐
                    |                 |
              [Route53 DNS]   [WAF/CDN]
                    |                 |
                    └────────┬────────┘
                             |
                    ┌────────┴────────┐
                    |                 |
                [ALB Primary]  [ALB Secondary]
                    |                 |
            ┌───────┼───────┬─────────┼──────┐
            |       |       |         |      |
        ┌───┴──┐┌──┴────┐┌─┴─────┐┌──┴──┐┌────┴──┐
        |      ||       ||       |||    ││      |
    ┌─────────────────────────────────────────────┐
    │         REGION 1 (Primary)                  │
    │                                             │
    │  ┌──────────────────────────────────────┐  │
    │  │ AZ-A           AZ-B          AZ-C    │  │
    │  │ ┌────────┐  ┌────────┐  ┌────────┐  │  │
    │  │ │Instance│  │Instance│  │Instance│  │  │
    │  │ │App v1.0│  │App v1.0│  │App v1.0│  │  │
    │  │ └─┬──────┘  └──┬─────┘  └──┬─────┘  │  │
    │  │   │            │           │        │  │
    │  │ ┌─┴────────────┴───────────┴──┐    │  │
    │  │ │   Auto Scaling Group        │    │  │
    │  │ │   - Min: 6, Max: 12         │    │  │
    │  │ │   - Health checks: 15s      │    │  │
    │  │ └─────────────────────────────┘    │  │
    │  │                                     │  │
    │  │ ┌─────────────────────────────┐    │  │
    │  │ │ RDS Multi-AZ Primary        │    │  │
    │  │ │ (DB writes happen here)     │    │  │
    │  │ └─┬───────────────────────────┘    │  │
    │  │   │  (Replication)                 │  │
    │  │   └────→ RDS Secondary (Standby)   │  │
    │  │          (Automatic failover)      │  │
    │  └──────────────────────────────────────┘  │
    │                                             │
    │  ┌──────────────────────────────────────┐  │
    │  │ Shared Services                      │  │
    │  │ - ElastiCache (Redis)                │  │
    │  │ - S3 buckets (region-replicated)     │  │
    │  │ - EBS snapshots (automated)          │  │
    │  └──────────────────────────────────────┘  │
    └─────────────────────────────────────────────┘
            |
            | (Cross-region replication)
            |
    ┌──────────────────────────────────────────────┐
    │       REGION 2 (Secondary/DR)                │
    │                                              │
    │  ┌────────────────────────────────────────┐ │
    │  │ AZ-A           AZ-B          AZ-C      │ │
    │  │ ┌────────┐  ┌────────┐  ┌────────┐    │ │
    │  │ │Instance│  │Instance│  │Instance│    │ │
    │  │ │App v1.0│  │App v1.0│  │App v1.0│    │ │
    │  │ └────────┘  └────────┘  └────────┘    │ │
    │  │                                        │ │
    │  │ RDS Replica (Read-only standby)       │ │
    │  │ (Automatic promotion on failover)     │ │
    │  │                                        │ │
    │  │ S3 Replica (Read-only)                │ │
    │  └────────────────────────────────────────┘ │
    └──────────────────────────────────────────────┘

Legend:
✓ Multi-AZ redundancy within region
✓ Multi-region redundancy for DR
✓ Automatic DNS failover (Route53)
✓ Automatic database failover (Multi-AZ RDS)
✓ Auto Scaling across AZs (never down to 1 AZ)
```

#### Instance Health Check Flow

```
[Instance Running]
        │
        ├─→ Application Process
        │   └─→ Periodic health check endpoint
        │       (GET /health/detailed)
        │
        ├─ Health Status: HEALTHY
        │  ├─ HTTP 200 response
        │  ├─ database latency < 100ms
        │  ├─ memory usage < 70%
        │  └─ queue depth < 10
        │
        └─ Load Balancer:
           ├─ Receives health check response
           ├─ Status: IN_SERVICE
           └─ Forwards traffic to instance


[Instance Starts Degrading]
        │
        ├─ Application Process:
        │  ├─ Memory leak detected
        │  ├─ Memory usage climbs to 85%
        │  └─ Response time increases
        │
        ├─ Health Check Endpoint:
        │  ├─ Returns HTTP 200 (still responding)
        │  ├─ memory_used_percent: 85
        │  ├─ queue_depth: 50 (backing up)
        │  └─ latency_p99: 2000ms (degraded)
        │
        ├─ Load Balancer:
        │  ├─ Sees HTTP 200 (marks HEALTHY)
        │  ├─ Still routes traffic (bad!)
        │  └─ Traffic goes to degraded instance
        │
        ├─ Application Layer:
        │  ├─ Detects degradation in metrics
        │  ├─ Activates circuit breaker
        │  └─ Returns 503 Service Unavailable
        │
        ├─ Load Balancer (with detailed health):
        │  ├─ Parses response body
        │  ├─ Detects memory_used_percent: 85
        │  ├─ Marks instance UNHEALTHY (threshold 80%)
        │  └─ Drains traffic to healthy instances
        │
        └─ Orchestration Platform:
           ├─ Receives unhealthy alert
           ├─ Triggers auto-remediation
           ├─ Drains instance gracefully
           ├─ Terminates instance
           ├─ Launches new replacement instance
           └─ New instance: healthy, joins pool


[Instance Complete Failure]
        │
        ├─ Hardware failure (e.g., kernel panic)
        │  └─ Process dies
        │
        ├─ Health Check:
        │  ├─ Connection timeout (TCP SYN never acknowledged)
        │  └─ Load Balancer marks UNHEALTHY
        │
        ├─ Auto Scaling Group:
        │  ├─ Detects instance terminated
        │  ├─ DesiredCapacity: 6, CurrentCapacity: 5
        │  ├─ Launches replacement instance
        │  ├─ Waits for health check to pass
        │  └─ Adds to load balancer target group
        │
        └─ Result: Capacity restored, no manual intervention
```

---

## Network Reliability

### Textual Deep Dive

#### Internal Working Mechanism

Network reliability ensures that communication pathways between systems remain available, low-latency, and free from packet loss. At scale, network reliability is often the most underestimated component.

**Network Stack Layers:**

```
Layer 7: Application (HTTP, gRPC, etc.)
Layer 6: Control flow (circuit breakers, rate limiting)
Layer 5: DNS (name resolution, service discovery)
Layer 4: Transport (TCP, UDP)
Layer 3: IP Routing
Layer 2: Data link (MAC, switching, VLANs)
Layer 1: Physical (fiber, copper, 5G)
```

Failures at any layer cascade upward.

**Network Reliability Mechanisms:**

1. **Path Redundancy:** Multiple network paths to destination
2. **Failure Detection:** Identify broken paths quickly
3. **Failover:** Reroute traffic away from failed paths
4. **Rate Shaping:** Prevent congestion through traffic control
5. **Circuit Breaking:** Prevent cascading failures through explicit failure signaling

#### Production Usage Patterns

**Pattern 1: Multi-Path Networking**

```
Data center typically has:
- Multiple top-of-rack switches
- Multiple uplinks to core network
- Multiple ISP connections
- Multiple DNS servers in different regions

Single path failure → other paths absorb traffic
Result: Network failure requires multiple simultaneous problems
```

**Pattern 2: DNS Failover**

```
DNS records:
Region A: 1.1.1.1, 1.1.1.2, 1.1.1.3 (primary)
Region B: 2.2.2.1, 2.2.2.2, 2.2.2.3 (secondary)

If region A becomes unreachable:
  - DNS health check fails
  - Remove 1.1.1.x from DNS responses
  - Clients resolve to 2.2.2.x only
  - Traffic redirects to region B
```

**Pattern 3: Network Partitioning Tolerance**

Two data centers can become isolated from each other:

```
[DC A] ←→ [Network Link] ←→ [DC B]
              ↓
            Fails
              ↓
[DC A] (isolated)        [DC B] (isolated)

Without partition tolerance:
- Both sides try to be "leader"
- Distributed system state becomes inconsistent
- Data corruption

With partition tolerance (Raft, Paxos):
- Side with quorum continues operating
- Minority partition goes read-only
- When partition heals, minority catches up
```

#### DevOps Best Practices

**1. Implement Comprehensive DNS Monitoring**

```bash
# Monitor DNS resolution time
for region in us-east-1 us-west-2 eu-west-1; do
  response_time=$(\
    dig +stats @$(aws route53 get-hosted-zone --id $region | \
    jq -r '.NameServers[0]') \
    my-app.example.com | \
    grep "Query time:" | awk '{print $4}'
  )
  
  if [ $response_time -gt 100 ]; then
    alert "DNS resolution slow in $region: ${response_time}ms"
  fi
done
```

**2. Use Service Meshes for Network Resilience**

Service meshes (Istio, Linkerd) provide:
- Automatic retries on network errors
- Circuit breakers
- Timeout enforcement
- Load balancing intelligence
- Network policy enforcement

**3. Implement Bulkheads**

Isolate network resources to prevent cascade failures:

```yaml
# Example: Istio connection pool limits
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: database
spec:
  host: database.production.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        http2MaxRequests: 100
        maxRequestsPerConnection: 2
```

**4. Monitor Network Latency and Packet Loss**

```bash
#!/bin/bash
# Continuous network quality monitoring

monitor_network_path() {
  local target=$1
  local interval=$2
  
  while true; do
    # Check latency (RTT in ms)
    local latency=$(ping -c 5 $target | grep "min/avg/max" | \
      awk -F'/' '{print $5}')
    
    # Check packet loss
    local loss=$(ping -c 100 $target | grep "% packet loss" | \
      awk '{print $6}' | cut -d'%' -f1)
    
    # Check jitter
    local jitter=$(ping -c 20 $target | awk -v N=20 '
      /min\/avg\/max/  {
        split($0, a, "/")
        split(a[5], b, ".")
        min=b[1]
        max=a[1]
        avg=a[2]
        print max - min
      }
    ')
    
    echo "$(date): Target=$target Latency=${latency}ms Loss=${loss}% Jitter=${jitter}ms"
    
    # Alert if degradation detected
    if (( $(echo "$latency > 100" | bc -l) )); then
      alert "High latency: ${latency}ms"
    fi
    
    if (( $(echo "$loss > 0.1" | bc -l) )); then
      alert "Packet loss detected: ${loss}%"
    fi
    
    sleep $interval
  done
}

monitor_network_path "10.0.0.1" 60  # Monitor every 60 seconds
```

#### Common Pitfalls

**Pitfall 1: DNS Caching Issues**

```
❌ Application caches DNS result for 1 hour
   Database IP changes (DR failover)
   App still routes to old IP for 1 hour
   Result: Database unreachable for 1 hour

✓ DNS TTL: 30 seconds
  Connection pooling respects TTL
  Failover takes effect within 30 seconds
```

**Pitfall 2: Ignoring Network Bandwidth Utilization**

```
❌ Network link at 95% capacity during normal traffic
   Spike occurs → congestion → packet loss
   Timeouts cascade through system

✓ Target 70% peak utilization
  Headroom for spikes, redundancy maintenance
```

**Pitfall 3: No Failover Automation**

```
❌ Network link fails → human operator must update routes manually
   Takes 30 minutes
   Services offline for 30 minutes

✓ Network failure detection → automatic failover → 10 second recovery
```

### Practical Code Examples

#### Network Resilience with Istio Service Mesh

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    istio-injection: enabled  # Auto-inject Envoy sidecars

---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-service
  namespace: production
spec:
  hosts:
  - api.example.com
  - api.production.svc.cluster.local
  http:
  # Define traffic routing with resilience
  - match:
    - uri:
        prefix: "/api/v1"
    route:
    - destination:
        host: api.production.svc.cluster.local
        port:
          number: 8080
    timeout: 5s
    retries:
      attempts: 3
      perTryTimeout: 2s
    fault:
      # Simulate faults for chaos testing
      delay:
        percentage:
          value: 0.1  # 0.1% requests get 100ms delay
        fixedDelay: 100ms
      abort:
        percentage:
          value: 0.01  # 0.01% requests aborted (500 errors)
        httpStatus: 500

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-service
  namespace: production
spec:
  host: api.production.svc.cluster.local
  
  # Connection pooling
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1000
      http:
        http1MaxPendingRequests: 500
        http2MaxRequests: 1000
        maxRequestsPerConnection: 2
    
    # Outlier detection (circuit breaker)
    outlierDetection:
      consecutive5xxErrors: 5           # Mark unhealthy after 5 errors
      interval: 30s
      baseEjectionTime: 30s
      splitExternalLocalOriginErrors: true
      
    # Load balancer settings
    loadBalancer:
      consistentHash:
        httpHeader: "x-session-id"      # Route by session for stickiness
      simple: ROUND_ROBIN              # Fallback strategy

  # Subsets enable canary deployments
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v2-canary
    labels:
      version: v2
      track: canary

---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: api-gateway
  namespace: production
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: api-cert
    hosts:
    - api.example.com
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - api.example.com

---
apiVersion: networking.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # Require mTLS between all pods

---
apiVersion: networking.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-auth
  namespace: production
spec:
  jwtRules:
  - issuer: "https://auth.example.com"
    jwksUri: "https://auth.example.com/.well-known/jwks.json"
    audiences: "api.example.com"

---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: api-policy
  namespace: production
spec:
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/client"]
    to:
    - operation:
        methods: ["GET"]
        paths: ["/api/v1/public/*"]
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/authenticated-client"]
    to:
    - operation:
        methods: ["POST"]
        paths: ["/api/v1/private/*"]
```

#### DNS Failover Script with Health Checks

```bash
#!/bin/bash
# DNS failover automation for multi-region setup

set -e

AWS_PROFILE="production"
HOSTED_ZONE_ID="Z1234567890ABC"
RECORD_NAME="api.example.com"
REGION_PRIMARY="us-east-1"
REGION_SECONDARY="us-west-2"
HEALTH_CHECK_TIMEOUT=5
HEALTH_CHECK_INTERVAL=30

# Get current DNS records
get_dns_records() {
  local region=$1
  aws route53 list-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --profile $AWS_PROFILE \
    | jq -r ".ResourceRecordSets[] | select(.Name==\"$RECORD_NAME.\") | .ResourceRecords[].Value"
}

# Check region health
check_region_health() {
  local region=$1
  local endpoints=$(aws elbv2 describe-target-groups \
    --region $region \
    --profile $AWS_PROFILE \
    | jq -r '.TargetGroups[0].TargetGroupArn')
  
  # Get target health
  local healthy_targets=$(aws elbv2 describe-target-health \
    --target-group-arn $endpoints \
    --region $region \
    --profile $AWS_PROFILE \
    | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State=="healthy")] | length')
  
  if [ $healthy_targets -eq 0 ]; then
    return 1  # Region unhealthy
  else
    return 0  # Region healthy
  fi
}

# Update Route53 records
update_dns_failover() {
  local active_region=$1
  local standby_region=$2
  
  # Get ELB DNS name for active region
  local active_endpoint=$(aws elbv2 describe-load-balancers \
    --region $active_region \
    --profile $AWS_PROFILE \
    | jq -r '.LoadBalancers[0].DNSName')
  
  # Get ELB DNS name for standby region
  local standby_endpoint=$(aws elbv2 describe-load-balancers \
    --region $standby_region \
    --profile $AWS_PROFILE \
    | jq -r '.LoadBalancers[0].DNSName')
  
  # Update Route53 - set active region with weight 100, standby with weight 0
  aws route53 change-resource-record-sets \
    --hosted-zone-id $HOSTED_ZONE_ID \
    --change-batch file:///dev/stdin \
    --profile $AWS_PROFILE \
<<BATCH
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "CNAME",
        "TTL": 60,
        "SetIdentifier": "primary",
        "Weight": 100,
        "ResourceRecords": [
          { "Value": "$active_endpoint" }
        ]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "CNAME",
        "TTL": 60,
        "SetIdentifier": "secondary",
        "Weight": 0,
        "ResourceRecords": [
          { "Value": "$standby_endpoint" }
        ]
      }
    }
  ]
}
BATCH

  echo "DNS updated: Primary=$active_region($active_endpoint), Secondary=$standby_region($standby_endpoint)"
}

# Main failover logic
main() {
  echo "Starting DNS failover monitor for $RECORD_NAME"
  
  local primary_healthy=true
  local secondary_healthy=true
  local current_active=$REGION_PRIMARY
  
  while true; do
    echo "$(date): Checking region health..."
    
    # Check primary region
    if check_region_health $REGION_PRIMARY; then
      primary_healthy=true
      echo "Primary region ($REGION_PRIMARY): HEALTHY"
    else
      primary_healthy=false
      echo "Primary region ($REGION_PRIMARY): UNHEALTHY"
    fi
    
    # Check secondary region
    if check_region_health $REGION_SECONDARY; then
      secondary_healthy=true
      echo "Secondary region ($REGION_SECONDARY): HEALTHY"
    else
      secondary_healthy=false
      echo "Secondary region ($REGION_SECONDARY): UNHEALTHY"
    fi
    
    # Determine active region
    local new_active=$current_active
    
    if $primary_healthy && ! $secondary_healthy; then
      new_active=$REGION_PRIMARY
    elif ! $primary_healthy && $secondary_healthy; then
      new_active=$REGION_SECONDARY
    elif $primary_healthy && $secondary_healthy; then
      new_active=$REGION_PRIMARY  # Prefer primary
    fi
    
    # If primary is unhealthy and secondary is unhealthy, keep current
    
    # Execute failover if needed
    if [ "$new_active" != "$current_active" ]; then
      echo "FAILOVER TRIGGERED: Switching from $current_active to $new_active"
      
      local standby_region=$current_active
      update_dns_failover $new_active $standby_region
      
      # Log failover event
      echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"event\":\"failover\",\"from\":\"$current_active\",\"to\":\"$new_active\"}" >> /var/log/dns-failover.log
      
      current_active=$new_active
    fi
    
    sleep $HEALTH_CHECK_INTERVAL
  done
}

main "$@"
```

### ASCII Diagrams

#### Multi-Region Network Topology with Failover

```
            ┌─────────────────────────────────────────────┐
            │          Global Load Balancer                │
            │          (Route53 / Azure Traffic Manager)   │
            │          TTL: 60 seconds                     │
            └──────────┬──────────────┬──────────────────┘
                       │              │
           ┌───────────┘              └──────────┐
           │                                     │
        [Active]                             [Standby]
           │                                     │
        US-EAST-1                            US-WEST-2
           │                                     │
    ┌──────┴─────────────┐            ┌─────────┴─────────┐
    │                    │            │                   │
    ├─ ALB (Primary)     │            ├─ ALB (Secondary)  │
    │  - IP: 1.1.1.1     │            │  - IP: 2.2.2.1    │
    │  - Health: OK      │            │  - Health: OK     │
    │  - Targets: 6      │            │  - Targets: 6     │
    │                    │            │                   │
    ├─ EC2 Instances     │            ├─ EC2 Instances    │
    │  ├─ i-111 (AZ-a)   │            │  ├─ i-211 (AZ-a)  │
    │  ├─ i-112 (AZ-b)   │            │  ├─ i-212 (AZ-b)  │
    │  └─ i-113 (AZ-c)   │            │  └─ i-213 (AZ-c)  │
    │                    │            │                   │
    ├─ RDS Primary       │            ├─ RDS Read Replica │
    │  - AZ: us-east-1a  │            │  - AZ: us-west-2a │
    │  - Status: Writing │            │  - Status: Repl.  │
    │  - Replication Lag: 100ms       │  Lag: 100ms       │
    │                    │            │                   │
    ├─ Cache Layer       │            ├─ Cache Layer      │
    │  (ElastiCache)     │            │  (ElastiCache)    │
    │  - Nodes: 3        │            │  - Nodes: 3       │
    │  - Replication: OK │            │  - Replication: OK│
    │                    │            │                   │
    ├─ DNS: CNAME        │            ├─ DNS: CNAME       │
    │  api.example.com   │            │  (standby)        │
    │  Weight: 100%      │            │  Weight: 0%       │
    │  TTL: 60s          │            │  TTL: 60s         │
    │                    │            │                   │
    └────────────────────┘            └───────────────────┘

Failover Scenario:
If Primary (US-EAST-1) becomes unavailable:
  1. Health check fails (target returns 500)
  2. Route53 detects all targets unhealthy
  3. DNS record updated: Weight 0% → 100%
  4. TTL expires (60 seconds)
  5. DNS queries resolve to secondary (US-WEST-2)
  6. Clients reconnect to secondary region
  7. RDS secondary promoted to primary
  8. Database write traffic switches to us-west-2
  9. Application continues with ~60s recovery time
```

#### Network Resilience with Service Mesh

```
┌─ Service A ─────────────────────────┐
│ Container: app:v1.0                 │
│ ├─ Envoy Sidecar (Istio)           │
│ │  ├─ Connection pooling (100)     │
│ │  ├─ Circuit breaker setup        │
│ │  ├─ Retry policy (3x, 2s)        │
│ │  └─ Timeout: 5s                  │
│ │                                  │
│ └─ Outgoing Request:               │
│    Service A requests Service B     │
└──────────────────┬──────────────────┘
                   │
     [Envoy Sidecar - Intelligent Routing]
                   │
    ┌──────────────┼──────────────┐
    │              │              │
    v              v              v
┌─Service B─v1─────┴─────────────┐
│ Pod-1 (AZ-a)                  │
│ Status: Healthy               │
│ Connections: 45/100           │
│ Latency: 50ms                 │
└─────────────────────────────────┘

┌─Service B─v1─────────────────┐
│ Pod-2 (AZ-b)                │
│ Status: Degraded             │
│ Connections: 95/100          │
│ Latency: 500ms               │
│ Error Rate: 5%               │
└─────────────────────────────────┘

┌─Service B─v2─────────────────┐
│ Pod-3 (AZ-c) [Canary]        │
│ Status: Healthy              │
│ Connections: 10/100          │
│ Latency: 60ms                │
└─────────────────────────────────┘

[Envoy Load Balancing Decision]:
Path 1 (Pod-2) detected degraded:
  - Outlier detection: mark unhealthy
  - Drain connections gracefully
  - Decrease weight from 33% to 0%

Path 2 (Pod-1) and Path 3 (Pod-3) absorb traffic:
  - Pod-1: 70% of traffic (healthy, more established)
  - Pod-3: 30% of traffic (canary, testing v2)

If Service B Pod-1 fails entirely:
  - Connection timeout detected
  - Circuit breaker OPENS
  - Fast-fail subsequent requests (don't wait for timeout)
  - After cooldown period, send test request
  - If succeeds: HALF_OPEN → CLOSED (resume)
  - If still failing: OPEN (keep failing fast)
```

---

## Database Reliability

### Textual Deep Dive

#### Internal Working Mechanism

Database reliability requires ensuring that data persists, remains consistent, and is accessible even during failures. This involves multiple layers:

**1. Write-Ahead Logging (WAL)**

All changes are written to a log before being applied to the database:

```
Application:  INSERT INTO users VALUES (1, 'Alice')
                  ↓
Write-Ahead Log: [timestamp, INSERT, user_id:1, name:'Alice']
                  ↓
Crash occurs at this point → data loss prevented!
                  ↓
Recovery process:
  - Read WAL
  - Replay inserts
  - Database restored to pre-crash state
```

**2. Replication**

Data replicated to standby/replica databases:

```
Primary DB:  INSERT → Write-Ahead Log → Replicate to standby
                ↓                              ↓
Clients read  Response                    Standby DB
                                          (catches up)

If Primary fails:
  - Standby elected as new primary
  - Clients reconnect
  - No data loss (if replication was synchronous)
```

**3. Consistency Models**

Different consistency guarantees have different costs:

```
Strong Consistency (Synchronous Replication):
  - Every write must be replicated to majority before ACK
  - Guarantees no data loss
  - Trade-off: higher latency

Eventual Consistency (Asynchronous Replication):
  - Write ACKed immediately, replication in background
  - Lower latency
  - Risk: standby might lag, small data loss possible

Read After Write (Hybrid):
  - Writes synchronous
  - Reads can return stale data
  - Balance of latency and consistency
```

#### Production Usage Patterns

**Pattern 1: RTO/RPO Planning**

Organizations explicitly define recovery targets:

```
Critical Financial System:
  - RTO: 30 seconds (must recover in 30 seconds)
  - RPO: 1 minute (can lose up to 1 minute of data)
  - Implication: Synchronous replication to secondary DC,
                 automatic failover, tested quarterly

Analytics Database:
  - RTO: 4 hours (downtime acceptable)
  - RPO: 1 hour (lose last hour of data acceptable)
  - Implication: Nightly backups, no replication needed

Non-critical Cache:
  - RTO: N/A (loseable)
  - RPO: N/A (no recovery needed)
  - Implication: Single instance, no backups
```

**Pattern 2: Backup Strategy**

```
Full Backup: Every Sunday
  - 3 hours duration
  - Used for point-in-time recovery > 1 week

Incremental Backups: Daily (Mon-Sat)
  - 30 minutes duration
  - Only changed blocks

Transaction Logs: Every 15 minutes
  - Enable recovery to any point in last 24 hours

Offsite Replication:
  - Backups replicated to different region
  - Protects against regional disaster
```

**Pattern 3: Connection Pooling**

```
40 Application Servers × 20 connections each = 800 connections
Database supports 1000 total connections

Without pooling:
  - Each server creates 20 connections per process
  - Total: 40 × 20 × 3 processes = 2400 connections
  - Database overwhelmed, new connections rejected

With pooling:
  - Central connection pool: 800 connections
  - Servers borrow from pool when needed
  - Reuse connections efficiently
  - Prevents connection exhaustion
```

#### DevOps Best Practices

**1. Test Backups Regularly**

```bash
#!/bin/bash
# Weekly backup restoration test

BACKUP_DATE=$(date -d "2 weeks ago" +%Y-%m-%d)
BACKUP_FILE="backup_${BACKUP_DATE}.sql.gz"

# Download backup from S3
aws s3 cp s3://backups/database/$BACKUP_FILE /tmp/

# Restore to test database
gunzip -c $BACKUP_FILE | mysql -u backup_user -p test_db

# Validate
mysql test_db -e "SELECT COUNT(*) FROM users; SELECT COUNT(*) FROM transactions;"

# Cleanup
rm /tmp/$BACKUP_FILE
# Database cleaned up after verification
```

**2. Implement Connection Pooling**

```yaml
# Example: PgBouncer (PostgreSQL connection pooler)
[databases]
production = host=db.prod.internal port=5432 dbname=prod

[pgbouncer]
pool_mode = transaction    # Return conn to pool after each transaction
max_client_conn = 1000
default_pool_size = 25
min_pool_size = 10
reserve_pool_size = 5
reserve_pool_timeout = 3
server_lifetime = 3600

listen_port = 6432
listen_addr = 0.0.0.0
```

**3. Monitor Replication Lag**

```bash
#!/bin/bash
# Monitor PostgreSQL replication lag

check_replication_lag() {
  local lag_ms=$(psql -h primary.db.internal -U monitor_user \
    -d production -t -c \
    "SELECT EXTRACT(EPOCH FROM (NOW() - pg_last_xact_replay_timestamp())) * 1000 AS lag_ms;")
  
  if (( $(echo "$lag_ms > 1000" | bc -l) )); then
    alert "Replication lag: ${lag_ms}ms exceeds threshold (1000ms)"
  fi
}

check_replication_lag
```

**4. Implement Circuit Breakers for Database Connections**

```python
# Using PyBreaker library
from pybreaker import CircuitBreaker
import psycopg2

# Circuit breaker pattern for database connections
db_breaker = CircuitBreaker(
    fail_max=5,                    # Break after 5 consecutive failures
    reset_timeout=60,             # Try again after 60 seconds
    exclude=[psycopg2.DatabaseError]  # Don't count specific errors
)

@db_breaker
def get_user(user_id):
    try:
        conn = psycopg2.connect("dbname=prod user=app")
        cur = conn.cursor()
        cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        result = cur.fetchone()
        cur.close()
        conn.close()
        return result
    except psycopg2.OperationalError:
        # Connection failure - circuit breaker counts this
        return None  # Return cached result instead

# Usage:
try:
    user = get_user(123)
except CircuitBreakerListener:
    # Database connection failed too many times
    user = cache.get_user(123)  # Fall back to cache
```

#### Common Pitfalls

**Pitfall 1: Asynchronous Replication Without Monitoring**

```
❌ Standby replication lag: 5 minutes
   Database fails
   Failover: standby promoted
   Result: Last 5 minutes of transactions lost

✓ Monitor replication lag continuously
  Alert if lag > 10 seconds
  Prevent failover if lag too high (better to stay down)
```

**Pitfall 2: Backup Testing Skipped**

```
❌ Backups run daily but never tested
   Year later, restore from backup fails (corrupted)
   data unrecoverable

✓ Weekly automated backup restore test
  Verify: can restore, data integrity OK, restore time < RTO
```

**Pitfall 3: Connection Pool Misconfiguration**

```
❌ max_connections=100, pool_size=5
   50 application servers each need 20 connections
   Connection pool exhausted → requests queue → timeouts

✓ pool_size = max_connections / expected_clients
  For 50 clients: pool_size = 100 / 50 = 2 per client
```

### Practical Code Examples

#### Automated PostgreSQL Backup with Verification

```bash
#!/bin/bash
# Automated PostgreSQL backup with encryption, verification, and offsite replication

set -e

# Configuration
DB_HOST="prod.database.rds.amazonaws.com"
DB_NAME="production"
DB_USER="backup_user"
DB_PORT="5432"
BACKUP_DIR="/backups/postgresql"
S3_BUCKET="s3://company-backups"
ENCRYPTION_KEY_ID="arn:aws:kms:us-east-1:123456789:key/12345678"
BACKUP_RETENTION_DAYS=30

# Logging
LOG_FILE="/var/log/postgres-backup.log"

log_info() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a $LOG_FILE
}

log_error() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a $LOG_FILE
}

# Create backup
create_backup() {
  local backup_file="${BACKUP_DIR}/backup_$(date +%Y%m%d_%H%M%S).sql.gz"
  
  log_info "Starting backup of $DB_NAME..."
  
  pg_dump \
    --host=$DB_HOST \
    --port=$DB_PORT \
    --username=$DB_USER \
    --db=$DB_NAME \
    --format=custom \
    --compress=9 \
    --verbose \
    --jobs=4 \
    > "${backup_file}.tmp" 2>${LOG_FILE}
  
  # Rename when complete (atomic)
  mv "${backup_file}.tmp" "$backup_file"
  
  local size=$(du -h "$backup_file" | cut -f1)
  log_info "Backup created: $backup_file (size: $size)"
  
  echo "$backup_file"
}

# Verify backup integrity
verify_backup() {
  local backup_file=$1
  
  log_info "Verifying backup integrity..."
  
  if pg_restore --list "$backup_file" > /dev/null 2>&1; then
    log_info "Backup verification successful"
    return 0
  else
    log_error "Backup verification failed"
    return 1
  fi
}

# Test restore to temporary database
test_restore() {
  local backup_file=$1
  
  log_info "Testing restore to temporary database..."
  
  # Create temporary database
  psql -h $DB_HOST -U postgres -c "CREATE DATABASE backup_test_$(date +%s) OWNER $DB_USER"
  local test_db="backup_test_$(date +%s)"
  
  trap "psql -h $DB_HOST -U postgres -c 'DROP DATABASE $test_db'" EXIT
  
  # Restore from backup
  pg_restore \
    --host=$DB_HOST \
    --username=$DB_USER \
    --db=$test_db \
    --exit-on-error \
    "$backup_file" 2>&1 | tee -a $LOG_FILE
  
  # Verify restore
  local restored_count=$(psql -h $DB_HOST -U $DB_USER -d $test_db -t -c \
    "SELECT COUNT(*) FROM users;")
  
  log_info "Restored database contains $restored_count rows in users table"
}

# Upload backup to S3 with encryption
upload_backup() {
  local backup_file=$1
  
  log_info "Uploading backup to S3..."
  
  aws s3 cp "$backup_file" \
    "${S3_BUCKET}/$(basename $backup_file)" \
    --sse aws:kms \
    --sse-kms-key-id $ENCRYPTION_KEY_ID \
    --storage-class GLACIER_DEEP_ARCHIVE \
    --metadata "created=$(date -u +%Y-%m-%dT%H:%M:%SZ),size=$(stat -c%s $backup_file)"
  
  log_info "Backup uploaded to S3"
}

# Cleanup old backups
cleanup_old_backups() {
  log_info "Cleaning up backups older than $BACKUP_RETENTION_DAYS days..."
  
  # Local cleanup
  find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +$BACKUP_RETENTION_DAYS -delete
  
  # S3 cleanup (via lifecycle policy, but we can also do manual)
  aws s3 ls ${S3_BUCKET}/ | while read -r line; do
    create_date=$(echo $line | awk {'print $1" "$2'})
    create_date_epoch=$(date -d "$create_date" +%s)
    old_date_epoch=$(date -d "$BACKUP_RETENTION_DAYS days ago" +%s)
    
    if [ $create_date_epoch -lt $old_date_epoch ]; then
      file_name=$(echo $line | awk {'print $4'})
      if [ ! -z "$file_name" ]; then
        log_info "Deleting old backup from S3: $file_name"
        aws s3 rm "${S3_BUCKET}/$file_name"
      fi
    fi
  done
}

# Main backup workflow
main() {
  log_info "Starting PostgreSQL backup workflow..."
  
  # Ensure backup directory exists
  mkdir -p $BACKUP_DIR
  
  # Create backup
  backup_file=$(create_backup)
  
  if [ $? -ne 0 ]; then
    log_error "Backup creation failed"
    exit 1
  fi
  
  # Verify backup
  if ! verify_backup "$backup_file"; then
    log_error "Backup verification failed; aborting"
    rm "$backup_file"
    exit 1
  fi
  
  # Test restore (optional, resource intensive)
  # Uncomment for weekly runs:
  # if ! test_restore "$backup_file"; then
  #   log_error "Restore test failed; backup may be corrupted"
  #   exit 1
  # fi
  
  # Upload to S3
  if ! upload_backup "$backup_file"; then
    log_error "S3 upload failed"
    exit 1
  fi
  
  # Cleanup old backups
  cleanup_old_backups
  
  log_info "Backup workflow completed successfully"
}

main "$@"
```

#### Database Failover with Health Checks (MySQL)

```python
#!/usr/bin/env python3
# Automated MySQL failover with health monitoring

import pymysql
import logging
import time
import sys
from datetime import datetime
from aws import boto3

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class MySQLFailoverManager:
    def __init__(self, primary_host, secondary_host, region):
        self.primary_host = primary_host
        self.secondary_host = secondary_host
        self.region = region
        self.rds_client = boto3.client('rds', region_name=region)
        self.route53_client = boto3.client('route53')
        self.primary_healthy = True
        self.in_failover = False
    
    def check_database_health(self, host, port=3306, timeout=5):
        """
        Comprehensive database health check
        """
        try:
            # Check connectivity
            conn = pymysql.connect(
                host=host,
                port=port,
                user='healthcheck_user',
                password='healthcheck_password',
                database='mysql',
                connect_timeout=timeout
            )
            
            cursor = conn.cursor()
            
            # Check replication status (if secondary)
            cursor.execute("SHOW SLAVE STATUS")
            slave_status = cursor.fetchone()
            
            if slave_status:
                seconds_behind_master = slave_status[32]  # Seconds_Behind_Master
                
                if seconds_behind_master is None:
                    logger.error(f"{host}: Replication not running")
                    conn.close()
                    return False
                
                if seconds_behind_master > 30:
                    logger.warning(f"{host}: Replication lag high: {seconds_behind_master}s")
                    conn.close()
                    return False
            
            # Check InnoDB status
            cursor.execute("SHOW ENGINE INNODB STATUS")
            innodb_status = cursor.fetchone()
            
            # Check for errors in buffer pool
            if b"ERROR" in innodb_status[2]:
                logger.error(f"{host}: InnoDB errors detected")
                conn.close()
                return False
            
            # Check connections
            cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
            threads_result = cursor.fetchone()
            threads_connected = int(threads_result[1])
            
            cursor.execute("SHOW VARIABLES LIKE 'max_connections'")
            max_conn_result = cursor.fetchone()
            max_connections = int(max_conn_result[1])
            
            connection_ratio = threads_connected / max_connections
            if connection_ratio > 0.8:
                logger.warning(f"{host}: Connection pool >80% utilized ({threads_connected}/{max_connections})")
            
            conn.close()
            return True
            
        except pymysql.Error as e:
            logger.error(f"{host}: Database check failed: {e}")
            return False
    
    def get_replication_lag(self, host):
        """Get current replication lag in seconds"""
        try:
            conn = pymysql.connect(
                host=host,
                user='healthcheck_user',
                password='healthcheck_password',
                database='mysql'
            )
            
            cursor = conn.cursor()
            cursor.execute("SHOW SLAVE STATUS")
            result = cursor.fetchone()
            conn.close()
            
            if result:
                return result[32]  # Seconds_Behind_Master
            return 0
            
        except Exception as e:
            logger.error(f"Failed to get replication lag for {host}: {e}")
            return None
    
    def promote_secondary(self):
        """Promote secondary database to primary"""
        try:
            logger.info(f"Promoting {self.secondary_host} to primary...")
            
            # Connect to secondary and promote
            conn = pymysql.connect(
                host=self.secondary_host,
                user='replication_user',
                password='replication_password'
            )
            
            cursor = conn.cursor()
            
            # Stop slave before promotion
            cursor.execute("STOP SLAVE")
            time.sleep(5)  # Wait for slave to stop
            
            # Skip replication errors to ensure slave stops
            cursor.execute("SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1")
            cursor.execute("START SLAVE")
            time.sleep(2)
            
            # Finally stop slave permanently
            cursor.execute("STOP SLAVE")
            cursor.execute("RESET MASTER")
            
            conn.close()
            
            logger.info(f"Secondary {self.secondary_host} promoted to primary")
            return True
            
        except Exception as e:
            logger.error(f"Promotion failed: {e}")
            return False
    
    def update_dns() (self, active_host):
        """Update Route53 DNS to point to new primary"""
        try:
            # Get hosted zone
            response = self.route53_client.list_hosted_zones_by_name(
                DNSName='db.example.com'
            )
            
            hosted_zone_id = response['HostedZones'][0]['Id']
            
            # Update DNS record
            self.route53_client.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch={
                    'Changes': [{
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': 'db.example.com',
                            'Type': 'CNAME',
                            'TTL': 60,
                            'ResourceRecords': [{'Value': active_host}]
                        }
                    }]
                }
            )
            
            logger.info(f"DNS updated to point to {active_host}")
            return True
            
        except Exception as e:
            logger.error(f"DNS update failed: {e}")
            return False
    
    def execute_failover(self):
        """Execute full failover procedure"""
        if self.in_failover:
            logger.warning("Failover already in progress, skipping")
            return
        
        self.in_failover = True
        
        try:
            logger.critical("FAILOVER INITIATED")
            
            # Check replication lag before promotion
            lag = self.get_replication_lag(self.secondary_host)
            logger.info(f"Replication lag before promotion: {lag}s")
            
            # Promote secondary
            if not self.promote_secondary():
                logger.error("Promotion failed")
                return
            
            # Update DNS
            if not self.update_dns(self.secondary_host):
                logger.error("DNS update failed")
                return
            
            logger.critical("FAILOVER COMPLETED - secondary is now primary")
            
            # Update internal state
            self.primary_host, self.secondary_host = self.secondary_host, self.primary_host
            
        finally:
            self.in_failover = False
    
    def monitor(self, check_interval=30):
        """Continuous health monitoring and failover automation"""
        consecutive_failures = 0
        failure_threshold = 3  # Trigger failover after 3 consecutive failures
        
        while True:
            try:
                primary_health = self.check_database_health(self.primary_host)
                secondary_health = self.check_database_health(self.secondary_host)
                
                if primary_health:
                    consecutive_failures = 0
                    if not self.primary_healthy:
                        logger.info("Primary database recovered")
                        self.primary_healthy = True
                else:
                    consecutive_failures += 1
                    logger.warning(f"Primary health check failed ({consecutive_failures}/{failure_threshold})")
                    
                    if consecutive_failures >= failure_threshold:
                        if secondary_health:
                            self.execute_failover()
                            consecutive_failures = 0
                        else:
                            logger.error("Both primary and secondary unhealthy; cannot failover")
                    
                    self.primary_healthy = False
                
                time.sleep(check_interval)
                
            except KeyboardInterrupt:
                logger.info("Monitoring stopped")
                break
            except Exception as e:
                logger.error(f"Monitor exception: {e}")
                time.sleep(check_interval)

if __name__ == "__main__":
    # Configuration
    PRIMARY_HOST = "prod-primary.rds.amazonaws.com"
    SECONDARY_HOST = "prod-secondary.rds.amazonaws.com"
    REGION = "us-east-1"
    
    manager = MySQLFailoverManager(PRIMARY_HOST, SECONDARY_HOST, REGION)
    manager.monitor()
```

### ASCII Diagrams

#### Database Replication and Failover Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Production Database Setup                 │
│                                                              │
│  ┌────────────────────────────────┐                        │
│  │   Primary Database (Primary)   │                        │
│  │   RDS Instance: prod-primary   │                        │
│  │   ├─ Status: Master            │                        │
│  │   ├─ Role: Write Operations    │                        │
│  │   ├─ Replication: Sending      │                        │
│  │   ├─ Connections: 485/1000    │                        │
│  │   └─ Lag: 0ms (self)          │                        │
│  └────────────┬────────────────────┘                        │
│               │                                              │
│               │ Synchronous Replication                     │
│               │ (Binary logs -> standby)                    │
│               │                                              │
│  ┌────────────v────────────────────┐                        │
│  │ Secondary Database (Standby)    │                        │
│  │ RDS Instance: prod-secondary    │                        │
│  │ ├─ Status: Replica              │                        │
│  │ ├─ Role: Read Operations        │                        │
│  │ ├─ Replication: Receiving       │                        │
│  │ ├─ Lag: 100ms (acceptable)      │                        │
│  │ ├─ Relay Logs: 128MB            │                        │
│  │ └─ Binary Logs: 512MB           │                        │
│  └────────────────────────────────┘                        │
│                                                              │
│  ┌────────────────────────────────┐                        │
│  │   Database Monitoring Service   │                        │
│  │   Health Check Interval: 30s    │                        │
│  │   ├─ Check Primary Connectivity │                        │
│  │   ├─ Check Replication Status   │                        │
│  │   ├─ Monitor Replication Lag    │                        │
│  │   ├─ Check InnoDB Status        │                        │
│  │   └─ Track Connection Pools     │                        │
│  └────────────────────────────────┘                        │
└──────────────────────────────────────────────────────────────┘

Normal Operation:
[Application Servers] 
    ↓
    ├─→ WRITE operations → Primary (prod-primary)
    │                      Writes to Binary Log
    │                      Replication sends to Secondary
    │
    └─→ READ operations → (could go to either)
        Most go to: Primary (consistent reads)
        Analytics: Secondary (read-heavy, stale OK)

Failover Scenario - Primary Fails:
    
Health Check: Primary connection timeout
Consecutive failures: 3 consecutive failures
Status: PRIMARY UNHEALTHY
        
Execute Failover:
1. Verify Secondary is healthy ✓
2. Stop Slave on Secondary
3. Promote Secondary to Master:
   - RESET MASTER (become new primary)
   - Clear relay logs
4. Update Route53 DNS:
   - db-prod.example.com → prod-secondary's IP
5. Reconfigure applications/connection pools
6. Result: RTO ≈ 30 seconds, RPO ≈ 0 seconds (sync replication)

Post-Failover Reality:
[Primary is now: prod-secondary]
[Secondary is now: prod-primary (or new instance)]
    
[Applications] reconnect to new endpoints
    └─→ WRITE operations → prod-secondary (new primary)
    └─→ READ operations → prod-primary (new secondary)
```

---

## Kubernetes Reliability

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes provides built-in mechanisms for reliability:

**1. Pod Health Checks**

Health checks probe containers and take action based on results:

```
Liveness Probe: "Is the container alive?"
  - If fails: kubelet kills and restarts container
  - Detects: deadlock, infinite loops, stuck processes
  - Action: RESTART POD

Readiness Probe: "Is the container ready to receive traffic?"
  - If fails: remove pod from service endpoints
  - Detects: startup delays, temporary overload, degradation
  - Action: DRAIN TRAFFIC (no kill/restart)

Startup Probe: "Has the container started successfully?"
  - If fails: delay startup
  - Detects: slow initializers, bootstrap failures
  - Action: RETRY STARTUP (don't kill too early)
```

**2. Pod Disruption Budgets (PDB)**

Ensures minimum availability during voluntary disruptions (node drains, cluster upgrades):

```
PodDisruptionBudget: minAvailable=2
  - Cluster has 3 pods
  - Admin drains a node
  - Normal procedure: evict all pods on node
  - With PDB: Cannot evict, violates minAvailable=2
  - Node waits for new pods to start on other nodes
  - Result: Always 2 pods available during drain
```

**3. Resource Requests and Limits**

Prevent resource exhaustion and noisy neighbor problems:

```
Pod Spec:
  resources:
    requests:
      memory: "256Mi"    # Scheduler reserves this much
      cpu: "100m"
    limits:
      memory: "512Mi"    # Can't exceed
      cpu: "500m"

Scheduler logic:
  if node_available_memory < pod_request:
    don't_schedule_here()
  
  if pod_actual_memory > pod_limit:
    oomkill(pod)  # Kill container
```

#### Production Usage Patterns

**Pattern 1: Multi-Replica Deployments**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3              # Always maintain 3 pods
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
    spec:
      affinity:
        podAntiAffinity: required  # Don't put 2 on same node
      containers:
      - name: api
        image: api:v1.0
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
```

**Pattern 2: Stateless Applications**

Applications are stateless, allowing:
- Horizontal scaling (add more pods)
- Safe pod eviction (restart elsewhere)
- Rolling updates (replace pods gradually)

**Pattern 3: Pod Disruption Budgets for Critical Services**

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
spec:
  minAvailable: 2          # Always keep 2 pods running
  selector:
    matchLabels:
      app: api-server
```

#### DevOps Best Practices

**1. Right-Size Resource Requests**

```bash
# Analyze actual resource usage to set requests accurately
kubectl top pods --namespace production

# If actual usage 100MB but requests 256MB: over-provisioned
# If actual usage 240MB but requests 256MB: tight margin
# Result: requests 300-400MB to allow for variance
```

**2. Implement Graceful Shutdown**

```dockerfile
FROM node:16
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Handle SIGTERM gracefully
CMD ["node", "app.js"]
```

```javascript
// app.js
const http = require('http');

let isShuttingDown = false;
const server = http.createServer((req, res) => {
  if (isShuttingDown) {
    res.writeHead(503, {'Content-Type': 'text/plain'});
    res.end('Service shutting down');
    return;
  }
  res.writeHead(200);
  res.end('OK');
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, gracefully shutting down');
  isShuttingDown = true;
  
  // Stop accepting new connections
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
  
  // Force exit after 30 seconds
  setTimeout(() => {
    console.error('Shutdown timeout exceeded');
    process.exit(1);
  }, 30000);
});

server.listen(8080);
```

**3. Monitor Pod Crash Loop**

```bash
#!/bin/bash
# Alert on crash loop conditions

check_crash_loops() {
  local crashed_pods=$(kubectl get pods --all-namespaces \
    | grep -i "crashloopbackoff\|error\|unknown" \
    | wc -l)
  
  if [ $crashed_pods -gt 0 ]; then
    alert "Found $crashed_pods pods in crash loop state"
    kubectl get pods --all-namespaces | grep -i "crashloopbackoff"
  fi
}

check_crash_loops
```

#### Common Pitfalls

**Pitfall 1: No Requests/Limits**

```
❌ Pod without resource requests
   No scheduler reservation
   Multiple pods compete for same resources
   One pod steals others' CPU → cascading failures

✓ All pods have requests (for scheduling)
  All pods have meaningful limits (to prevent runaway)
```

**Pitfall 2: Liveness Probe Too Aggressive**

```
❌ Liveness probe checks every 2 seconds
   Transient network hiccup → probe fails
   Pod killed → restarted
   GC pause during startup → probe fails again
   Pod bounces every 30 seconds

✓ Liveness: 30 second initial delay, 10 second period
  Readiness: 5 second initial delay, 5 second period
  Allow transient issues to recover naturally
```

**Pitfall 3: Ignoring Pod Disruption Budgets**

```
❌ No PDB set
   Administrator drains node for maintenance
   All pods evicted immediately
   Service loses all replicas → outage
   PDB required

✓ PDB: minAvailable=2 for 3-replica deployment
  Node drain waits for new pods to start
  Service never goes below 2 replicas
```

### Practical Code Examples

#### Complete Kubernetes Reliable Deployment

```yaml
---
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    name: production

---
# ConfigMap for application configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "1000"
  CACHE_TTL: "300"

---
# Service Account for pod security
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: production

---
# Role for pod security
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]

---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-role
subjects:
- kind: ServiceAccount
  name: app-service-account
  namespace: production

---
# Deployment with reliability features
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-api
  namespace: production
  labels:
    app: web-api
    version: v1.0
  annotations:
    runbook: "https://wiki.company.com/runbook/web-api"
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # 1 extra pod during update
      maxUnavailable: 0  # Never go below 3 (with maxSurge)
  
  selector:
    matchLabels:
      app: web-api
  
  template:
    metadata:
      labels:
        app: web-api
        version: v1.0
    spec:
      serviceAccountName: app-service-account
      
      # Pod anti-affinity: spread across nodes
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - web-api
            topologyKey: kubernetes.io/hostname
        
        # Node affinity: prefer specific nodes
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: node-type
                operator: In
                values:
                - compute-optimized
      
      # Graceful termination
      terminationGracePeriodSeconds: 30
      
      containers:
      - name: web-api
        image: web-api:v1.0
        imagePullPolicy: IfNotPresent
        
        # Environment variables
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: LOG_LEVEL
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        
        # Resource requests and limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Container health probes
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
          successThreshold: 1
        
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          failureThreshold: 30
          timeoutSeconds: 3
        
        # Ports
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        
        # Volume mounts
        volumeMounts:
        - name: config
          mountPath: /etc/app/config
          readOnly: true
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /var/cache/app
        
        # Security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
      
      # Pod security context
      securityContext:
        fsGroup: 1000
      
      # Volumes
      volumes:
      - name: config
        configMap:
          name: app-config
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: web-api
  namespace: production
  labels:
    app: web-api
spec:
  type: ClusterIP
  selector:
    app: web-api
  ports:
  - name: http
    port: 80
    targetPort: http
    protocol: TCP
  - name: metrics
    port: 9090
    targetPort: metrics
    protocol: TCP
  sessionAffinity: None  # Round-robin load balancing

---
# Pod Disruption Budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-api-pdb
  namespace: production
spec:
  minAvailable: 2  # Always keep 2 pods during disruptions
  selector:
    matchLabels:
      app: web-api
  unhealthyPodEvictionPolicy: IfHealthyBudget

---
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-api-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-api
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Scale up if >70% CPU
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Scale up if >80% memory
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
      - type: Percent
        value: 50  # Scale down by 50% max
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0    # Scale up immediately
      policies:
      - type: Percent
        value: 100  # Double the pods
        periodSeconds: 30

---
# NetworkPolicy for security
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-api-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web-api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: gateway  # Only accept from gateway
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: cache
    ports:
    - protocol: TCP
      port: 6379
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system  # Allow DNS queries
    ports:
    - protocol: UDP
      port: 53
```

---

## Disaster Recovery

### Textual Deep Dive

#### Core Principles

Disaster recovery bridges the gap between maintaining systems and recovering from catastrophic failures. Unlike SREs who prevent failures, DR specialists prepare for the failures that prevent cannot prevent.

**RTO/RPO Framework:**

```
RTO (Recovery Time Objective):
  - Maximum time to restore service
  - Financial impact: every minute of downtime = cost
  - Example: Target RTO of 1 hour

RPO (Recovery Point Objective):
  - Maximum acceptable data loss
  - Data impact: every minute of data loss = business impact
  - Example: Target RPO of 15 minutes

RTO and RPO are independent:
  - High RTO, low RPO: can take time to recover, but must preserve data
  - Low RTO, high RPO: fast recovery acceptable, data loss acceptable
  - Low RTO, low RPO: most costly, requires sophisticated infrastructure
```

**Disaster Types:**

```
Tier 1 (Most Frequent, Least Severe):
  - Single instance failure: 0.1% service impact
  - Single disk failure: 0.1% capacity loss
  - Single NIC failure: 0.1% network impact
  
Tier 2 (Moderate):
  - Single server failure: 1% service impact
  - Single rack failure: 5% capacity loss
  - Single availability zone failure: 33% capacity loss (3-AZ setup)
  
Tier 3 (Severe, Rare):
  - Single region failure: 50% capacity loss (multi-region setup)
  - Network partition (DC isolated): services become split-brain
  
Tier 4 (Catastrophic):
  - Cloud provider regional outage
  - Data center destroyed
  - Entire region unavailable
  
Tier 5 (Extinction Level):
  - Company facility destroyed (on-premises)
  - All backups in same location (fire/flood)
  - No geographic diversity
```

**DR Strategies by RTO:**

```
RTO < 15 minutes (Premium):
  - Multi-region active-active setup
  - Synchronous replication
  - Automated failover
  - Cost: 2-3x normal infrastructure
  - Use for: Core revenue-generating systems

RTO 15-60 minutes (Standard):
  - Multi-region active-passive setup
  - Asynchronous replication
  - Automated or semi-automated failover
  - Cost: 1.5-2x normal infrastructure
  - Use for: Important services

RTO 1-4 hours (Basic):
  - Single region with hourly backups
  - Manual failover to backup infrastructure
  - Cost: 1x + storage
  - Use for: Non-critical services

RTO 4+ hours (Minimal):
  - Single region with daily backups
  - Manual recovery to new infrastructure
  - Cost: minimal
  - Use for: non-essential services
```

#### Production Patterns

**Pattern 1: Active-Passive Multi-Region**

```
Region A (Active): Receives all traffic
  - RDS Primary writing data
  - Replicas for read scaling
  - Write-ahead logs shipped to Region B

Region B (Passive): On Standby
  - RDS Replica (read-only)
  - No traffic receiving
  - DNS not pointing here
  - Standing by for failover
  - Standby database lag: ~30 seconds

Failover Procedure (manual or automated):
  1. Detect Region A failure
  2. Run pre-failover checks:
     - Replication lag < 30 seconds? Proceed
     - All backups completed? Proceed
  3. Break replication (stop receiving updates)
  4. Promote RDS replica to primary
  5. Update application configuration to point to Region B
  6. Reroute DNS to Region B endpoints
  7. Propagation: 60 seconds (DNS TTL)
  8. Result: Service recovery in ~5-10 minutes
```

**Pattern 2: Multi-Region Read Replicas for Scale**

```
Primary Region: All writes (single point)
Secondary Regions: Read replicas
  - Replicas serve read queries (lower latency for local users)
  - Replicas cannot accept writes
  - If primary region fails: promote replica to primary

Architecture:
  [US-East] (primary, writes here)
    ├─ Write → WAL → Replicate globally
    ├─ Reads served locally (replication lag: 100ms)
    └─ Database: 30 writes/sec, 10000 reads/sec

  [EU-West] (replica)
    └─ Reads served locally
        Via DNS: read queries routed to nearest replica
        Replication lag: 100-200ms
        
  [AP-Southeast] (replica)
    └─ Reads served locally
        Via DNS: read queries routed to nearest replica
        Replication lag: 200-300ms
```

### Common Pitfalls

**Pitfall 1: Untested Backup**

```
❌ "We have backups, we're safe"
   - Backups never tested
   - Year later, restore from backup fails
   - Data unrecoverable
   - Discover file corruption only at recovery time

✓ Weekly automated backup restore test
  - Validates: backups work, can restore, restore time < RTO
  - Catches: corruption, incompatibility, missing files
```

**Pitfall 2: RTO/RPO Not Aligned**

```
❌ Business requires RTO 4 hours, RPO 1 hour
   Infrastructure provides: RTO 1 hour, RPO 30 minutes
   Cost: 2x infrastructure spending for goals already met
   
❌ Business requires RTO 1 hour, RPO 1 minute
   Infrastructure provides: RTO 4 hours, RPO 1 hour
   Unmet goals, service loss if Regional outage
   
✓ Business and Eng agree on targets
  Measure: Actual RTO/RPO via drills
  Adjust: Prioritize highest-impact services
```

**Pitfall 3: Backups in Single Region**

```
❌ Regional data center destroyed (fire/flood/earthquake)
   All backups destroyed too
   No recovery possible

✓ Backups in multiple regions
  Primary: Local backups (fast restore)
  Secondary: Geo-replicated backups (DR)
```

**Pitfall 4: Failover Never Drilled**

```
❌ Failover procedure documented but never executed
   When failover needed: operators execute it wrong
   Makes situation worse

✓ Monthly DR drill
  - Execute full failover procedure
  - Measure actual RTO
  - Fix problems discovered
```

---

## Load Balancing Strategies

### Textual Deep Dive

#### Core Concepts

Load balancing distributes traffic across multiple backend instances to:
1. **Increase capacity** (N instances handle N× traffic)
2. **Improve resilience** (failure of 1 instance doesn't affect others)
3. **Enable maintenance** (gracefully remove instance for updates)
4. **Optimize latency** (route to nearest/fastest instance)

**Load Balancing Layers:**

```
Layer 7 (Application):
  - Route based on request headers, URL path, hostname
  - Examples: HTTP routing, gRPC
  - Can inspect request body (expensive)

Layer 4 (Transport):
  - Route based on IP protocol version, port
  - Examples: TCP/UDP routing
  - Fast, cannot inspect Layer 7 information

Layer 3 (Network):
  - Route based on IP addresses
  - Can do simple IP hashing
```

#### Load Balancing Algorithms

**Round-Robin**

Distributes requests equally across backends:

```
Request 1 → Backend A
Request 2 → Backend B
Request 3 → Backend C
Request 4 → Backend A  (cycle repeats)

Advantages: simple, fair distribution
Disadvantages: doesn't account for backend capacity/health
                doesn't preserve session state
```

**Least Connections**

Routes to backend with fewest active connections:

```
Backend A: 50 connections (choose this)
Backend B: 45 connections
Backend C: 60 connections

Advantages: balances load across different response times
Disadvantages: ignores connection weight
```

**IP Hash**

Routes based on client IP (provides stickiness):

```
hash(client_ip) % num_backends = selected_backend

Benefits:
  - Client always goes to same backend
  - Preserves session state (cookies, local cache)
  - No mechanism required to sync session data

Drawbacks:
  - Uneven distribution if client IPs non-uniform
  - Adding/removing backends breaks mapping
```

**Least Response Time (Weighted)**

Routes to backend with lowest combined latency and active connections:

```
score = latency_ms + (active_connections / capacity)

Backend A: 50ms latency, 10 connections, capacity 100
  score = 50 + (10/100) = 50.1

Backend B: 100ms latency, 20 connections, capacity 100
  score = 100 + (20/100) = 100.2

Backend C: 30ms latency, 80 connections, capacity 100
  score = 30 + (80/100) = 30.8  → Selected

Advantages: optimal distribution, considers backend state
Disadvantages: more complex calculation
```

**Rate Limiting (Throttling)**

Protects backends from overload:

```
Max requests per second per backend: 1000
If backend at 1000 req/sec:
  - New requests queued or rejected
  - Protects backend from cascading failures
  - Returns 429 Too Many Requests
```

---

## Advanced Best Practices & Implementation Patterns

### Database Reliability: Advanced Patterns

#### Advanced Pattern 1: Connection Pool Lifecycle Management

**The Problem:**
Connection pool exhaustion cascades through entire application stack. Single service consuming all connections prevents other services from accessing database.

**The Solution with Bulkheads:**
```python
from contextlib import contextmanager
import psycopg2
from psycopg2 import pool
import threading

class BulkheadedConnectionPool:
    """Connection pool with per-service isolation"""
    
    def __init__(self, service_name, minconn, maxconn, db_config):
        self.service_name = service_name
        self.pool = psycopg2.pool.SimpleConnectionPool(
            minconn, maxconn, **db_config
        )
        self.total_acquired = 0
        self.lock = threading.Lock()
    
    @contextmanager
    def get_connection(self, timeout=5):
        """Get connection with bulkhead isolation"""
        try:
            conn = self.pool.getconn()
            with self.lock:
                self.total_acquired += 1
            
            yield conn
            
        except pool.PoolError:
            # No connections available
            raise Exception(
                f"Connection pool exhausted for {self.service_name}"
            )
        finally:
            if conn:
                self.pool.putconn(conn)

# Create isolated pools for each service
user_service_pool = BulkheadedConnectionPool(
    'user-service', 10, 20,
    {'database': 'production', 'user': 'app', 'host': 'db.prod'}
)

payment_service_pool = BulkheadedConnectionPool(
    'payment-service', 15, 30,
    {'database': 'production', 'user': 'app', 'host': 'db.prod'}
)

# Result: User service cannot consume payment service's connections
```

#### Advanced Pattern 2: Query Profiling and Optimization

**Automated Performance Degradation Detection:**
```bash
#!/bin/bash
# Detect performance regressions in queries

DATABASE="production"
ALERT_THRESHOLD_MS=1000  # Alert if query exceeds 1000ms

# Enable query profiler
mysql -u root $DATABASE -e "
  SET GLOBAL log_queries_not_using_indexes=1;
  SET GLOBAL long_query_time=0.01;
  SET GLOBAL log_slow_admin_statements=1;
"

# Analyze slow queries
analyze_slow_queries() {
  mysql -u root $DATABASE -e "
    SELECT
      query_time,
      lock_time,
      rows_examined,
      sql_text
    FROM mysql.slow_log
    WHERE query_time > INTERVAL '0.1' SECOND
    ORDER BY query_time DESC
    LIMIT 50;
  " | while IFS=$'\t' read time lock rows sql; do
    
    # Convert to milliseconds
    time_ms=$(echo "$time * 1000" | bc)
    
    if (( $(echo "$time_ms > $ALERT_THRESHOLD_MS" | bc -l) )); then
      alert "SLOW QUERY (${time_ms}ms): $sql"
      suggest_optimization "$sql"
    fi
  done
}

suggest_optimization() {
  local sql=$1
  
  # Check if query uses indexes
  mysql -u root $DATABASE -e "
    EXPLAIN EXTENDED $sql;
  " | grep -i "Using where\|Using temporary"
  
  if [ $? -eq 0 ]; then
    echo "⚠️  Query might benefit from indexes"
    mysql -u root $DATABASE -e "EXPLAIN EXTENDED $sql;"
  fi
}

analyze_slow_queries
```

---

### Kubernetes Reliability: Advanced Patterns

#### Advanced Pattern 1: Comprehensive Health Check Responses

**Application-level health check with detailed metrics:**
```python
from flask import Flask, jsonify
import psutil
import requests
import time

app = Flask(__name__)

def get_system_metrics():
    """Gather detailed system metrics"""
    return {
        'cpu_percent': psutil.cpu_percent(interval=0.1),
        'memory_percent': psutil.virtual_memory().percent,
        'disk_percent': psutil.disk_usage('/').percent,
        'process_threads': psutil.Process().num_threads(),
    }

def check_dependencies():
    """Check all external service dependencies"""
    checks = {}
    
    # Check database
    try:
        db.session.execute('SELECT 1')
        checks['database'] = 'ok'
    except Exception as e:
        checks['database'] = f'error: {e}'
    
    # Check cache
    try:
        cache.ping()
        checks['cache'] = 'ok'
    except Exception as e:
        checks['cache'] = f'error: {e}'
    
    # Check downstream services
    try:
        response = requests.get('http://auth-service:8080/health', timeout=2)
        checks['auth_service'] = 'ok' if response.status_code == 200 else 'error'
    except Exception as e:
        checks['auth_service'] = f'error: {e}'
    
    return checks

@app.route('/health/startup')
def health_startup():
    """Startup probe: Is initialization complete?"""
    # Check if all critical resources loaded
    if not app.config.get('DB_INITIALIZED'):
        return jsonify({'status': 'initializing'}), 503
    
    return jsonify({'status': 'started'}), 200

@app.route('/health/ready')
def health_ready():
    """Readiness probe: Can accept traffic?"""
    metrics = get_system_metrics()
    deps = check_dependencies()
    
    # Check thresholds
    if metrics['memory_percent'] > 85:
        return jsonify({
            'status': 'not_ready',
            'reason': 'memory_pressure',
            'memory_percent': metrics['memory_percent']
        }), 503
    
    if any('error' in str(v) for v in deps.values()):
        return jsonify({
            'status': 'not_ready',
            'reason': 'dependency_failure',
            'dependencies': deps
        }), 503
    
    return jsonify({
        'status': 'ready',
        'metrics': metrics,
        'dependencies': deps
    }), 200

@app.route('/health/live')
def health_live():
    """Liveness probe: Is process alive?"""
    # This must be fast - just check if app is responding
    return jsonify({'status': 'alive', 'timestamp': time.time()}), 200
```

#### Advanced Pattern 2: Pod Disruption Budget with Guarantees

**Ensure critical services survive maintenance:**
```yaml
# Step 1: Set PDB for critical deployments
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payment-processor-pdb
  namespace: production
spec:
  minAvailable: 2           # Always keep 2 payment processors
  unhealthyPodEvictionPolicy: IfHealthyBudget
  selector:
    matchLabels:
      app: payment-processor

---
# Step 2: Configure drain behavior
apiVersion: v1
kind: Node
metadata:
  name: node-1
spec:
  # Drain will respect PDB and wait until new pods scheduled
  cordoned: false

---
# Step 3: Drain script
apiVersion: batch/v1
kind: Job
metadata:
  name: node-drain
spec:
  template:
    spec:
      serviceAccountName: node-drainer
      containers:
      - name: drain
        image: bitnami/kubectl:latest
        command:
        - /bin/sh
        - -c
        - |
          for node in $(kubectl get nodes | grep NotReady | awk '{print $1}'); do
            echo "Draining node: $node"
            kubectl drain $node \
              --ignore-daemonsets \
              --delete-emptydir-data \
              --force \
              --timeout=5m || echo "Drain failed, continuing"
          done
```

---

### Disaster Recovery: Advanced Patterns

#### Advanced Pattern: Multi-Region Failover with Validation

**Sophisticated failover with multiple verification stages:**
```bash
#!/bin/bash
# Multi-stage failover with extensive validation

set -e

PRIMARY_REGION="us-east-1"
SECONDARY_REGION="us-west-2"
FAILOVER_LOG="/var/log/failover-$(date +%Y%m%d_%H%M%S).log"

log_stage() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $FAILOVER_LOG
}

stage_1_assess_damage() {
  log_stage "STAGE 1: Assessing Primary Region Status"
  
  # Check if AWS API responses
  local region_status=$(aws ec2 describe-instances \
    --region $PRIMARY_REGION \
    --query 'ResponseMetadata.HTTPStatusCode' 2>/dev/null || echo "500")
  
  if [ "$region_status" == "200" ]; then
    log_stage "Primary region responsive - checking resources"
    local instance_count=$(aws ec2 describe-instances \
      --region $PRIMARY_REGION \
      --query 'Reservations[*].Instances[*].State.Name' \
      | grep -c "running" || echo "0")
    
    if [ "$instance_count" -gt 0 ]; then
      log_stage "ERROR: Primary region has running instances"
      log_stage "Aborting failover - likely false alarm"
      return 1
    fi
  fi
  
  log_stage "Primary region confirmed failed"
  return 0
}

stage_2_verify_secondary_health() {
  log_stage "STAGE 2: Verifying Secondary Region"
  
  # Check secondary databases
  local secondary_db_status=$(aws rds describe-db-instances \
    --region $SECONDARY_REGION \
    --db-instance-identifier prod-secondary \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text)
  
  if [ "$secondary_db_status" != "available" ]; then
    log_stage "ERROR: Secondary database status: $secondary_db_status"
    return 1
  fi
  
  # Check replication lag
  local lag=$(aws rds describe-db-instances \
    --region $SECONDARY_REGION \
    --db-instance-identifier prod-secondary \
    --query 'DBInstances[0].LatestRestorableTime' \
    --output text)
  
  log_stage "Secondary database healthy, replication lag: $lag"
  return 0
}

stage_3_pre_failover_checks() {
  log_stage "STAGE 3: Pre-Failover Validation"
  
  # Get current backup
  local latest_backup=$(aws rds describe-db-snapshots \
    --region $SECONDARY_REGION \
    --query 'DBSnapshots[0].SnapshotCreateTime' \
    --output text)
  
  log_stage "Latest backup timestamp: $latest_backup"
  
  # Verify read replicas in other regions
  local replicas=$(aws rds describe-db-instances \
    --region eu-west-1 \
    --query 'DBInstances[?contains(DBInstanceIdentifier, `prod-replica-)`].DBInstanceIdentifier' \
    --output text)
  
  if [ -z "$replicas" ]; then
    log_stage "WARNING: No read replicas found in EU region"
  fi
  
  return 0
}

stage_4_promote_database() {
  log_stage "STAGE 4: Promoting Secondary Database"
  
  local start_time=$(date +%s)
  
  aws rds promote-read-replica \
    --db-instance-identifier prod-secondary \
    --region $SECONDARY_REGION \
    --backup-retention-period 7 \
    >> $FAILOVER_LOG 2>&1
  
  # Wait for promotion
  while true; do
    local status=$(aws rds describe-db-instances \
      --region $SECONDARY_REGION \
      --db-instance-identifier prod-secondary \
      --query 'DBInstances[0].DBInstanceStatus' \
      --output text)
    
    if [ "$status" == "available" ]; then
      break
    fi
    
    local elapsed=$(($(date +%s) - start_time))
    if [ $elapsed -gt 600 ]; then
      log_stage "ERROR: Promotion exceeded 10 minutes"
      return 1
    fi
    
    log_stage "Promotion in progress... status: $status (${elapsed}s)"
    sleep 10
  done
  
  local end_time=$(date +%s)
  local promo_time=$((end_time - start_time))
  log_stage "Database promotion completed in ${promo_time} seconds"
  
  return 0
}

stage_5_update_dns() {
  log_stage "STAGE 5: Updating DNS Records"
  
  local new_endpoint=$(aws rds describe-db-instances \
    --region $SECONDARY_REGION \
    --db-instance-identifier prod-secondary \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)
  
  # Update Route53
  aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890ABC \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"db-prod.example.com\",
          \"Type\": \"CNAME\",
          \"TTL\": 60,
          \"ResourceRecords\": [{
            \"Value\": \"$new_endpoint\"
          }]
        }
      }]
    }" >> $FAILOVER_LOG 2>&1
  
  log_stage "DNS updated to: $new_endpoint"
  return 0
}

stage_6_verify_connectivity() {
  log_stage "STAGE 6: Verifying Application Connectivity"
  
  local attempts=0
  local max_attempts=30
  
  while [ $attempts -lt $max_attempts ]; do
    if mysql -h db-prod.example.com -u app_user -p -e "SELECT 1"; then
      log_stage "Application successfully connected to new primary"
      return 0
    fi
    
    ((attempts++))
    log_stage "Connection attempt $attempts/$max_attempts failed, retrying..."
    sleep 10
  done
  
  log_stage "ERROR: Could not verify application connectivity"
  return 1
}

stage_7_verify_data_integrity() {
  log_stage "STAGE 7: Verifying Data Integrity"
  
  # Run data validation queries
  local user_count=$(mysql -h db-prod.example.com -u app_user -p -e \
    "SELECT COUNT(*) FROM users;" | tail -1)
  
  local transaction_count=$(mysql -h db-prod.example.com -u app_user -p -e \
    "SELECT COUNT(*) FROM transactions;" | tail -1)
  
  log_stage "Data integrity check - Users: $user_count, Transactions: $transaction_count"
  
  if [ -z "$user_count" ] || [ "$user_count" -eq 0 ]; then
    log_stage "ERROR: No user data found"
    return 1
  fi
  
  return 0
}

main() {
  log_stage "=========================================="
  log_stage "FAILOVER PROCEDURE INITIATED"
  log_stage "Primary Region: $PRIMARY_REGION"
  log_stage "Secondary Region: $SECONDARY_REGION"
  log_stage "=========================================="
  
  local failed=0
  
  stage_1_assess_damage || ((failed++))
  stage_2_verify_secondary_health || ((failed++))
  stage_3_pre_failover_checks || ((failed++))
  stage_4_promote_database || ((failed++))
  stage_5_update_dns || ((failed++))
  stage_6_verify_connectivity || ((failed++))
  stage_7_verify_data_integrity || ((failed++))
  
  if [ $failed -eq 0 ]; then
    log_stage "=========================================="
    log_stage "FAILOVER COMPLETED SUCCESSFULLY"
    log_stage "=========================================="
    
    # Notify team
    mail -s "Failover Completed: $PRIMARY_REGION → $SECONDARY_REGION" \
      ops-team@company.com < $FAILOVER_LOG
    
    exit 0
  else
    log_stage "=========================================="
    log_stage "FAILOVER FAILED - $failed stages had errors"
    log_stage "=========================================="
    
    mail -s "Failover FAILED - Manual Intervention Required" \
      ops-critical@company.com < $FAILOVER_LOG
    
    exit 1
  fi
}

main "$@"
```

---

### Load Balancing: Advanced Patterns

#### Advanced Pattern: Smart Traffic Routing Based on Real-Time Metrics

**Service mesh-based intelligent routing:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: backend-service
spec:
  hosts:
  - backend.production.svc.cluster.local
  http:
  # Route based on header values
  - match:
    - headers:
        user-tier:
          exact: "premium"
    route:
    - destination:
        host: backend.production.svc.cluster.local
        subset: v2  # New version to premium users
      weight: 100
    timeout: 5s
    retries:
      attempts: 3
      perTryTimeout: 2s
  
  # Alpha users get canary
  - match:
    - headers:
        user-tier:
          exact: "alpha"
    route:
    - destination:
        host: backend.production.svc.cluster.local
        subset: v2-canary
      weight: 100
    timeout: 5s
  
  # Everyone else gets stable version
  - route:
    - destination:
        host: backend.production.svc.cluster.local
        subset: v1
      weight: 90
    - destination:
        host: backend.production.svc.cluster.local
        subset: v2
      weight: 10
    timeout: 5s
    retries:
      attempts: 3
      perTryTimeout: 2s

---
# Define backend subsets
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: backend-subsets
spec:
  host: backend.production.svc.cluster.local
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 3
      interval: 30s
      baseEjectionTime: 30s
  subsets:
  - name: v1
    labels:
      version: v1.0
  - name: v2
    labels:
      version: v2.0
  - name: v2-canary
    labels:
      version: v2.0
      track: canary
```

### Hands-on Scenarios

#### Scenario 1: Production Incident - Cascading Failures

**Context:**
You're on-call Friday afternoon. A sales promotion launches, traffic increases 3x normal levels. Your monitoring shows requests backing up, response times increasing, and error rates rising.

**Timeline:**
- 2:00 PM: Traffic spike detected,response time 500ms (normal: 100ms)
- 2:05 PM: Error rate 5% (threshold: 1%)
- 2:08 PM: First alert fires
- 2:10 PM: You page the team

**Investigation Questions:**
1. Are the API servers CPU/memory exhausted?
2. Is the database responding?
3. Are load balancer connections healthy?
4. Is it an upstream service problem?

**Resolution Options:**
- **Option A (Wrong):** Immediately restart all services
  - Result: Risk making worse (cascading failure)
  
- **Option B (Correct):** Systematic investigation
  1. Check API server metrics (CPU, memory, goroutines)
  2. Check database connections and query times
  3. Check load balancer health checks
  4. If database slow: scale up database connection pool
  5. If API servers slow: scale up instances (takes 2 minutes)
  6. Verify traffic now distributes across new instances
  7. Monitor error rate declining

- **Option C (Partial):** Add autoscaling
  - Scales instances, reduces error rate, but slow (2+ minutes)
  - Should have been configured before promotion

**Learning:**
- Autoscaling must be pre-configured for known events
- Circuit breakers prevent cascading failures
- Database connection pooling is critical under load
- Rate limiting protects against overload

#### Scenario 2: Deployment Causes Production Outage

**Context:**
Friday 4 PM. You deploy new payment processing service. 30 seconds after deployment, customer calls reporting payment failures.

**What Went Wrong:**
New code has implicit dependency on feature flag service. Flag service not deployed to prod yet. Payment service crashes when feature flag endpoint unreachable.

**Immediate Actions (First 2 minutes):**
1. Revert deployment (rollback to v1.0)
   Command: `kubectl rollout undo deployment/payment-service`
2. Verify: payment processing resumes
3. Page incident commander
4. Page feature flag team

**Root Cause Analysis:**
- Dependency not documented
- No pre-deployment validation
- Feature flag service not yet deployed

**Prevention:**
- Add dependency check to deployment pipeline
- Deploy feature flag service first
- Implement health checks that validate all dependencies
- Require canary deployment (would have caught this at 5% traffic)

**Post-Incident:**
- Document all service dependencies
- Add automated dependency validation
- Implement mandatory 5% canary for critical services

#### Scenario 3: Database Replication Failure

**Context:**
You receive alert: "Replication lag to secondary database > 60 seconds". Primary database is healthy, secondary is healthy, but not receiving updates.

**Investigation:**
```bash
# Check primary
SHOW MASTER STATUS;
# Binary log position: 54.3 GB

# Check secondary
SHOW SLAVE STATUS;
# Relay log position: 52.1 GB (lagging 2.2 GB)
# Last error: "Deadlock found when trying to get lock"

# Root cause: Long-running query on secondary blocking updates

# Solution:
STOP SLAVE;
KILL <query_id>;  # Kill the blocking query
START SLAVE;

# Verify:
SHOW SLAVE STATUS;
# Seconds_Behind_Master: now 0
```

**Prevention:**
- Set `slave_parallel_workers > 1` for parallel replication
- Monitor long-running queries and auto-kill (if safe)
- Alert if lag > 30 seconds

---

### Interview Questions

#### Question 1: Explain how you'd design a system for 99.99% uptime

**Background:** Senior role, critical system

**What they're testing:**
- Understanding of SLOs and availability calculations
- Knowledge of reliability patterns
- Ability to make tradeoffs

**Good Answer Structure:**
1. **Define the problem:**
   - 99.99% = 52.6 minutes/year downtime
   - Need to survive: single instance failure, AZ failure, region failure
   
2. **Architecture design:**
   - Multi-region active-active (or active-passive)
   - Multi-AZ within each region
   - Synchronous replication for data
   - Health checks and automated failover
   
3. **Implementation details:**
   - Load balancing: ALB + Route53 with health checks
   - Database: RDS Multi-AZ within region, Read Replicas across regions
   - Caching: ElastiCache with read replicas
   - Autoscaling: HPA for Kubernetes(
   
4. **Observability:**
   - Monitor availability: real user monitoring + synthetic tests
   - Alert on errors, latency, replication lag
   - Runbooks for common failures

5. **Cost acknowledgment:**
   - 99.99% is 5x more expensive than 99%
   - Requires: 2-3x infrastructure, sophisticated tooling, dedicated on-call
   - Business must justify the cost

#### Question 2: When would you NOT implement full automation?

**What they're testing:**
- Pragmatism, not just enthusiasm for automation
- Understanding of cost-benefit analysis
- Risk assessment skills

**Good Answer:**
- **Rarely-occurring events** (< 1 per quarter)
  - Cost of automation > cost of manual execution
  - Example: Account closure (complex, rare)
  
- **High-stakes decisions** requiring human judgment
  - Example: Data deletion (expensive mistake if wrong)
  - Automation acceptable only with extreme safeguards
  
- **Novel/experimental processes** not yet stabilized
  - Wait until process proves stable
  - Then automate
  
- **Compliance/regulatory constraints**
  - Some decisions require human oversight (e.g., fraud detection)
  - Audit trail requirements
  
**Example scenario:**
- Daily backups: fully automated (high frequency)
- Backup restore: requires approval (destructive operation)
- Backup deletion after 30 days: automated (low risk, known policy)
- Backup deletion due to data privacy request: manual (complex, legal)

#### Question 3: Describe a production incident you handled. What went wrong? How did you fix it?

**What they're testing:**
- Real-world incident experience
- Problem-solving approach
- Blameless postmortem mindset
- Learning from failures

**Structure of good answer:**
1. **Context** (2-3 sentences)
   - What system, when, what was happening
   
2. **What happened** (the incident)
   - Event that triggered the issue
   - User impact (response time, errors, downtime)
   
3. **Investigation** (your thought process)
   - Tools/strategies used
   - Hypotheses tested
   - Root cause discovery
   
4. **Remediation** (what you did)
   - Immediate fix (stop the bleeding)
   - Longer-term fix (prevent recurrence)
   
5. **Post-mortem** (learning)
   - What surprised you
   - Changes made to prevent recurrence
   - Automation added
   - Documentation improved

**Example:**
*"We had a database connection pool exhaustion at 2 AM. API latency spiked from 100ms to 5 seconds, error rate went to 20%. I investigated by checking application logs, database connection count, and found connections weren't being returned to pool. Root cause: code initialization was creating connections at startup but not closing them at shutdown. We:*

1. *Immediate fix: increased connection pool max from 100 to 200 (bought time)*
2. *Root cause fix: added connection cleanup in graceful shutdown handler*
3. *Prevention: added monitoring for idle connections, alert if not returning to pool*
4. *Automation: canary test validation before production deployment*

*We also realized we needed chaos testing for connection pool failures to catch this earlier."*

#### Question 4: Design a Disaster Recovery strategy for a multi-region ecommerce platform

**What they're testing:**
- Ability to design for catastrophic failure
- Business/technical balance
- RTO/RPO thinking
- Cost-benefit analysis

**Good Answer:**
1. **Define RPO/RTO:**
   - Catalog data: RPO = 1 hour, RTO = 4 hours (non-critical, batch repopulated)
   - Order database: RPO = 5 min, RTO = 30 min (critical, synchronous replication)
   - User sessions: RPO = N/A (loseable), RTO = N/A (stateless)
   - Product inventory: RPO = 1 min, RTO = 5 min (critical for sales)

2. **Multi-region architecture:**
   - Primary: US-East (active, serves traffic)
   - Secondary: US-West (warm standby, read replicas online)
   - Tertiary: EU (cold standby, backups only)

3. **Data replication:**
   - Order DB: Synchronous replication US-East → US-West
   - Catalog: Asynchronous replication (RPO 1hr is OK)
   - Backups: Daily to S3, cross-region replicated

4. **Failover procedure:**
   - Detect: Health checks fail for > 2 minutes
   - Validate: Secondary region healthy
   - Investigate: human approval for automatic failover
   - Execute: RDS promotion, DNS update, configuration switch
   - Verify:orders flowing, payment processing working
   - Duration: ~5-10 minutes

5. **Cost & tradeoff:**
   - Multi-region = 2x infrastructure cost
   - Acceptable for ecommerce (revenue impact huge if down)
   - Alternative: Accept 2-4 hour RTO(saves 50% of cost) if business approves

#### Question 5: How do you balance velocity (frequent deployments) with reliability?

**What they're testing:**
- Understanding of SRE philosophy
- Ability to make principled decisions
- Team communication skills

**Good Answer:**
- **Error budgets** let us define acceptable failures
  - SLO 99.9% = 43.2 min/month error budget
  - If we've burned 80% (already had outages), slow deployments
  - If we have 50% remaining, can deploy faster
  
- **Deployment strategies** reduce risk
  - Canary: 5% → 25% → 100% catches errors early
  - Blue-green: instant rollback if issues
  - Feature flags: disable problematic features instantly
  
- **Testing** enables velocity
  - Unit + integration tests: confidence in code
  - Staging environment: validate in prod-like environment
  - Chaos engineering: validate failure recovery
  
- **Monitoring** enables quick response
  - Detect issues < 1 minute: P50 latency spike
  - Automated remediation for known issues
  - Runbooks for quick resolution
  
- **Automation** reduces friction
  - Automated rollback on error rate spike
  - Automated scaling prevents cascading failures
  - Self-healing reduces on-call burden
  
**Result:** Healthy organizations deploy 100x+ per day, not because they're reckless, but because they've built systems to make frequent deployment safe.

---

#### Question 6: Describe a multi-region strategy for a SaaS product. What are the tradeoffs?

**What they're testing:**
- Understanding of geographic distribution
- Cost-benefit analysis
- Operational complexity awareness

**Senior Answer:**

**Single Region (Cheap, Simple):**
- All infrastructure in one region
- Cost: ~$10k/month
- RTO: infinite (if region fails, complete outage)
- RPO: 1 hour (daily backups only)
- Deployment: 1 environment, simple ops

**Multi-Region Active-Passive (Balanced):**
- Primary: us-east-1 (active, all traffic)
- Secondary: eu-west-1 (warm standby, read replicas)
- Cost: ~$20k/month (2x compute, but replicas are cheaper)
- RTO: 5-10 minutes (manual failover)
- RPO: < 5 minutes (continuous replication)
- Deployment: 2 environments, more complex testing

**Multi-Region Active-Active (Expensive, Complex):**
- All regions serve traffic simultaneously
- Data replicated all directions (circular replication)
- Cost: ~$35-40k/month (3x compute, complex infrastructure)
- RTO: < 1 minute (automatic failover, DNS TTL)
- RPO: 0 (synchronous replication)
- Deployment: 3+ environments, extensive testing
- **Challenges:**
  - Split-brain scenarios (regions can't communicate)
  - Distributed transaction coordination (Paxos/Raft required)
  - Database conflict resolution (last-write-wins, CRDTs)
  - Network partitioning handling

**Recommendation Structure:**
1. **Start with single region** - understand traffic patterns and cost
2. **Add read replicas in secondary regions** - reduced latency for users, failover capacity
3. **Build active-passive setup** - proven reliability, acceptable RTO
4. **Only add active-active if** - sub-minute RTO required AND team has expertise

**Real Example:**
*"We serve 60% US, 30% EU, 10% Asia. We chose:*
- Primary: us-east-1 (all writes here)
- Read replicas: eu-west-1 and ap-southeast-1 (local reads)
- If us-east-1 fails: automatically promote eu-west-1 to primary, write traffic reroutes, propagates to AP within seconds
- Cost: 1.8x vs. single region, complexity manageable, meets business RTO of 15 minutes, RPO of 5 minutes"*

---

#### Question 7: What's the difference between high availability and disaster recovery? Can you have one without the other?

**What they're testing:**
- Semantic understanding
- Practical implications
- Real-world tradeoffs

**Senior Answer:**

| Aspect | High Availability | Disaster Recovery |
|--------|------------------|------------------|
| **Scope** | Single data center (one AZ) | Multiple data centers (regions) |
| **Failure Type** | Transient failures (server crashes) | Catastrophic failures (region destroyed) |
| **Recovery Method** | Automatic (self-healing) | Manual/semi-automatic (runbooks) |
| **RTO** | Seconds | Hours |
| **RPO** | Seconds | Minutes/hours |
| **Cost** | Low (N+1 capacity) | Medium-High (2-3x infrastructure) |

**Can you have HA without DR?**
```
YES, but risky
- 3-server setup in single AZ provides HA (survives 1 server failure)
- Single regional outage = total data loss
- Acceptable for non-critical services only
```

**Can you have DR without HA?**
```
YES, but operationally difficult
- Daily backups in secondary region provide DR capability
- Primary region outage = all requests fail for 4-6 hours
- Manual recovery = slow, error-prone
- Acceptable for non-critical systems only
```

**The Pyramid:**
```
[Disaster Recovery (Multi-Region)]
     ↑
     └── Base: HA (Multi-AZ)
         └── Base: Health Monitoring
             └── Base: Automation
```

**You need BOTH for production:**
1. **HA (multi-AZ):** Fast recovery from common failures (your "99% of outages")
2. **DR (multi-region):** Slow recovery from rare but catastrophic failures (your "1% of outages")

---

#### Question 8: You've just inherited operations for a monolithic application that took 2 hours to deploy. The team says "we can't change the codebase." How do you improve deployment reliability without code changes?

**What they're testing:**
- Practical problem-solving
- Operational creativity
- Understanding of deployment mechanics

**Senior Answer (Operational Improvements):**

**Layer 1: Infrastructure**
- Blue-green deployment (requires 2x infrastructure, no code change)
  - Deploy new monolith to empty cluster
  - Run smoke tests
  - Switch load balancer (15-second cutover)
  - Old monolith still running (instant rollback)
  - Result: 15-second RTO vs. 2-hour deployment
  
- Database versioning
  - Schema changes applied in advance
  - Old/new monolith both work with new schema (backward compatible)
  - Deploy monitoring endpoints for compatibility

**Layer 2: Process**
- Rolling deployments (without code change)
  - Gradually replace 10% → 20% → 100% of monoliths
  - Monitor error rate at each stage
  - Catch problems before 100% deployment
  
- Canary deployments
  - Route 5% of traffic to new monolith
  - Monitor error rates and latency
  - If good: increase to 10%, 25%, 100%
  - If bad: traffic stays on old monolith, new one rolled back

**Layer 3: Automation**
- Automated smoke tests at each stage
  - Run tests against 10% deployment
  - Measure: login succeeds, queries work, payment processes
  - Alert on regression
  
- Automated rollback on error rate spike
  - If error rate > 2x normal baseline
  - Automatically switch back to previous version
  - Alert team for investigation

**Layer 4: Monitoring**
- Detailed pre-deployment/post-deployment metrics
  - Baseline: normal error rate, p99 latency, throughput
  - Deploy new version
  - Compare: is error rate within 10% of baseline?
  - Decision: promote or rollback

**Result:** From 2-hour error-prone deployment to:
- 15 min: blue-green style deployment with instant rollback
- + automated canary + automated smoke tests + automated rollback
- Risk drastically reduced, even without code changes

**What you can't fix without code changes:**
- Graceful startup (long initialization)
- Graceful shutdown (active request draining)
- Health checks (they'll detect liveness, not readiness)

---

#### Question 9: A critical service is consuming 3x more database connections than expected. The connection pool is exhausted. How do you diagnose and fix this in production without taking down the service?

**What they're testing:**
- Production troubleshooting under pressure
- Database understanding
- Non-disruptive remediation

**Senior Answer (Step-by-Step):**

**Step 1: Immediate Visibility (0-5 minutes)**
```sql
-- View all connections
SHOW PROCESSLIST;

-- Identify long-running queries
SELECT
  ID, TIME, STATE, INFO
FROM INFORMATION_SCHEMA.PROCESSLIST
WHERE TIME > 300  -- Queries running > 5 minutes
ORDER BY TIME DESC;

-- Check which application/host is consuming connections
SELECT
  USER, HOST, COUNT(*) as connection_count
FROM INFORMATION_SCHEMA.PROCESSLIST
GROUP BY USER, HOST
ORDER BY connection_count DESC;
```

**Step 2: Identify Root Cause (5-10 minutes)**

**Possibility A: Queries not being returned to pool**
```
Diagnosis:
  - Long-running queries visible in PROCESSLIST
  - Query time > TIMEOUT threshold
  - Likely: application timeout firing, but query never cancelled

Fix:
  1. Increase pool size temporarily (band-aid)
  2. Query the offending query to understand what's slow
  3. Add index or optimize query
  4. Deploy fix (doesn't require restart)
```

**Possibility B: Connection leak (connections never returned)**
```
Diagnosis:
  - PROCESSLIST shows connections in SLEEP state
  - Same FROM host repeatedly
  - Connection time very long

Fix (non-disruptive):
  1. Enable connection timeout: SET GLOBAL wait_timeout = 300
  2. Idle connections automatically closed after 300 seconds
  3. Restart application pods gracefully
  4. Drain old connections, new ones use pool correctly
```

**Possibility C: Cascading queries (one query causes many others)**
```
Diagnosis:
  - Query A running slow
  - This blocks Query B
  - Other applications waiting for Query B
  - All queued connections wait forever

Fix:
  1. KILL the long-running Query A
     KILL <query_id>;
  2. Monitor: downstream queries now complete
  3. Pool recovers as queries finish
  4. Investigate: why was Query A so slow?
```

**Step 3: Production Remediation**

**Option A: Increase pool size (temporary)**
```bash
# If using PgBouncer (PostgreSQL connection pooler)
# Temporarily increase pool size
# Don't restart application servers (connections already pooled)

# Edit pgbouncer.ini
default_pool_size = 50  (was 25)

# Reload (non-disruptive)
pgbouncer -R

# Monitor: connection pool no longer exhausted
```

**Option B: Add read replicas for read-heavy connections**
```sql
-- If reads are causing exhaustion:
-- Route SELECT to replica, not primary

-- Example: Point read-heavy application to replica
-- Change connection string: 
--   FROM: db-primary.rds.us-east-1.amazonaws.com
--   TO:   db-replica.rds.us-east-1.amazonaws.com

-- Applications restart pods (new connection strings), replicas handle reads
```

**Step 4: Prevention**

**Add monitoring:**
```bash
# Alert if pool > 80% utilized
SELECT
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.PROCESSLIST WHERE COMMAND != 'Sleep')
  / (SELECT @@max_connections)
  AS connection_utilization
  
# If > 0.8: ALERT
```

**Set timeouts:**
```sql
-- Kill idle connections
SET GLOBAL wait_timeout = 600;  # 10 minutes

-- Kill long-running queries
SET GLOBAL max_execution_time = 300000;  # 5 minutes
```

---

#### Question 10: Design an on-call rotation for a 24/7 SaaS product with 50 engineers. What metrics do you track?

**What they're testing:**
- Understanding of sustainable operations
- Team dynamics knowledge
- SRE philosophy (not just technology)

**Senior Answer:**

**Rotation Structure:**

```
Team A (Primary on-call)
  ├─ 1 primary (paged first)
  ├─ 1 backup (paged if primary not responding)
  └─ Manager (paged if severity=critical)

Team B (Secondary on-call)
  └─ Handles non-urgent escalations

Rotation: 1 week primary, 1 week secondary, then off-call

Why this works:
- 8 week cycle: 1 week on-call, 5 weeks mostly off, 1 week secondary, 1 week planning
- Sustainable: no one constantly on-call
- Backup: primary unavailable? 5 minute SLA to reach backup
- Escalation: critical incidents get management attention
```

**Key Metrics to Track:**

**1. On-Call Volume**
```
Track per engineer:
- Incidents per week
- Pages per week
- Mean time to resolution (MTTR)
- False alerts vs. real incidents

Target:
- Paging for known issues = bad (should be automated)
- Paging for novel failures = acceptable
- False alert rate < 5%
```

**2. Incident Response**
```
- Time to first response
- Time to mitigation
- Time to root cause
- Time to post-mortem

Target:
- Critical incidents: < 5 min to respond
- Major incidents: < 15 min to respond
- All incidents: mitigation before root cause (service restored fast)
```

**3. Engineer Burnout Indicators**
```
- Unplanned time off during on-call weeks
- Failed pages (not responding)
- Escalation patterns (can't fix, needing help)
- Repeated incidents (same thing keeps happening)

Red flags:
- Same engineer handling 50% of on-call incidents
- Engineer escalating most pages
- Engineer taking time off during on-call
- Engineer quit (correlate with on-call rotations)
```

**4. System Health**
```
- Incident frequency trending down? (improving)
- MTTR trending down? (getting better at fixing)
- Alert noise trending down? (fewer false alarms)
- Automation coverage increasing? (fewer manual incidents)
```

**Prevention (Beyond Rotation):**

**Blameless Post-Mortems**
- No blame on individual
- Focus on "what conditions existed"
- What automated prevention could help

**Runbooks for Repeat Issues**
- If same issue > 2 times: write runbook
- If same issue > 3 times: automate the fix
- If same issue > 4 times: architectural change needed

**Mandatory Off-Call Time**
- Engineer can refuse on-call if recently had incident
- Prevents burnout from critical incidents
- Forces team to build systems not dependent on heroes

**Sustainable On-Call Philosophy:**
> "If an engineer is being paged at 2 AM, something about your system architecture or automation is wrong, not their dedication."

---

#### Question 11: You notice your database replication lag increasing from 100ms to 5 seconds over the past week. What's your investigation approach?

**What they're testing:**
- Performance troubleshooting methodology
- Database understanding
- Systematic thinking

**Senior Answer:**

**Step 1: Characterize the Problem (Trend Analysis)**

```bash
# Timeline analysis
- 1 week ago: lag typically 50-100ms (normal)
- 5 days ago: started trending up (100-300ms)
- 3 days ago: jumped to 1-2 seconds
- Now: consistently 5 seconds (degraded)

# Hypothesis: Something changed around 5 days ago
Event correlation:
- Code deployment?
- Database upgrade?
- Increased traffic?
- Scheduled maintenance?
- Query pattern change?
```

**Step 2: Check Replication Status**

```sql
-- On secondary database
SHOW SLAVE STATUS \G

Looking for:
- Seconds_Behind_Master: 5 seconds (confirms our observation)
- Relay_Master_Log_File: matches Master_Log_File (replication intact)
- Slave_IO_Running: Yes (binary log being received)
- Slave_SQL_Running: Yes (binary log being applied)
- Last_Error: (any errors preventing replication)
```

**Step 3: Identify the Bottleneck**

**Is it transmission (IO thread) or execution (SQL thread)?**

```sql
-- Check binary log transmission
SHOW STATUS LIKE 'Bytes_received';
-- If low: network/transmission issue

-- Check SQL replay speed
SHOW STATUS LIKE 'Slave_parse_total';
-- If low: secondary can't keep up applying changes
```

**Question: Which thread is lagging?**

```bash
# Monitor relay log size
ls -lh relay-log*

# If large/growing: SQL thread can't keep up executing
# If small: IO thread is slow receiving

# Example:
# relay-bin.000145 large (500MB) = SQL thread bottleneck
# relay-bin.000012 small (10MB) = IO thread doing fine
```

**Step 4: Diagnose Root Cause**

**Scenario A: SQL Thread Bottleneck (Most Common)**

```sql
-- Secondary can't apply changes fast enough
-- Reason: Single-threaded by default

-- Check: is secondary doing meaningful work?
SHOW PROCESSLIST;
-- Shows Binlog_Dump_* threads, Slave_apply, etc.

-- Check: what query is running?
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST;
-- Look for long-running queries on secondary

-- Likely causes:
1. Large transactions on primary (DELETE million rows)
   - Secondary has to replay same transaction
   - Takes longer than original (no parallel execution)
   
2. Missing indexes on secondary
   - Primary has index, uses it for fast DELETE
   - Secondary applies raw query, no index, slow scan
   
3. Secondary struggling with load
   - Running our read replicas
   - CPU/disk contention affecting replication
```

**Scenario B: Primary Load Increase**

```bash
# Check primary transaction rate
mysql -h primary -e "SHOW GLOBAL STATUS LIKE 'Questions';"

# Compare to baseline
# If 10x increase: primary generating binary logs faster
# Secondary can't keep up

# Likely causes:
- Large batch jobs started (ETL)
- New service using database
- Query pattern change
```

**Step 5: Fix (Priority-Based)**

**Option A (Immediate):** Adjust secondary resources
```
# If secondary CPU/disk saturated:
- Scale up secondary instance size
- Add CPU/memory
- Replication catches up within hours
```

**Option B (24-48 hours):** Optimize replication
```sql
-- Enable parallel replication (MySQL 5.7+)
SET GLOBAL slave_parallel_workers = 4;
SET GLOBAL slave_parallel_type = 'LOGICAL_CLOCK';

-- Restart replication to apply
STOP SLAVE;
START SLAVE;

-- Result: Secondary replays transactions in parallel
--         Lag drops from 5s to 500ms
```

**Option C (Root cause):** Fix primary query
```sql
-- If large transactions are causing lag:
SHOW ENGINE INNODB STATUS;
-- Look for long-running TRX

-- Either:
1. Optimize the query (better index, different approach)
2. Batch it (do it in smaller chunks)
3. Schedule during low-traffic window
```

**Monitoring for Future:**

```bash
# Alert if lag > 1 second
# Alert if lag increasing (trend)
# Alert if SQL thread queue size > 1000 (relative lag)

# Prevent:
- Parallel replication enabled
- MySQL 8.0+ (better replication)
- Read replicas scaled appropriately
- Monitor primary query patterns
```

---

#### Question 12: How would you implement feature flags in a microservices architecture? What are the operational considerations?

**What they're testing:**
- Understanding of safe deployments
- Architectural thinking
- Operational complexity

**Senior Answer:**

**Architecture:**

```
Feature Flag Service (centralized)
├─ Stores: flag_name, enabled_by_default, rollout_percentage, audience
└─ API for querying (cached, sub-10ms)

Each Microservice
├─ Calls Feature Flag Service for decisions
├─ Caches results locally (10-minute TTL)
├─ Caches in memory for fast decisions
└─ Implements feature conditionally

Application
├─ If flag enabled for user: use new feature
├─ If flag disabled for user: use old code path
└─ Can toggle flags without redeployment
```

**Implementation Example:**

```python
class FeatureFlagManager:
    def __init__(self, cache_ttl=600):
        self.cache = {}
        self.cache_ttl = cache_ttl
    
    def is_enabled(self, flag_name, user_id, context=None):
        """
        Determine if feature is enabled for user
        """
        # Check local cache first
        cache_key = f"{flag_name}:{user_id}"
        if cache_key in self.cache:
            cached_result, timestamp = self.cache[cache_key]
            if time.time() - timestamp < self.cache_ttl:
                return cached_result
        
        # Fetch from Feature Flag Service
        response = requests.get(
            'http://feature-flags:8080/api/check',
            params={
                'flag': flag_name,
                'user_id': user_id,
                'context': json.dumps(context or {})
            }
        )
        
        enabled = response.json()['enabled']
        
        # Cache locally
        self.cache[cache_key] = (enabled, time.time())
        
        return enabled

# Usage in code
ff_manager = FeatureFlagManager()

@app.route('/api/payment')
def process_payment():
    user_id = request.user_id
    
    if ff_manager.is_enabled('new_payment_processor', user_id):
        # Use new payment processor
        result = new_payment_service.process(order)
    else:
        # Use old payment processor
        result = legacy_payment_service.process(order)
    
    return result
```

**Rollout Strategies:**

**1. Canary (5% → 10% → 50% → 100%)**
```
Day 1: Enable for 5% of users
  - Monitor: error rate, latency, business metrics
  - If OK: proceed
  - If issues: disable for all

Day 2: Enable for 10% of users
Day 3: Enable for 50% of users
Day 4: Enable for 100% of users
```

**2. Internal Users First**
```
Enable for:
1. Employees first (1 hour)
2. Beta users (1 day)
3. Everyone (production)
```

**3. Geographic Rollout**
```
Enable by region:
1. US-East (1 day)
2. EU-West (1 day)
3. AP-Southeast (1 day)
4. Global (deploy code without flag)
```

**Operational Considerations:**

**The Good:**
- Deploy code without users seeing it
- Kill problematic features instantly (no redeploy)
- Gradual rollout with safety
- Experiment on real users
- Rollback without redeployment

**The Complexity:**
```
# Dead code paths
- Old code path still running (needs maintenance)
- After 3 months of 100%? Remove old code
- But what if user bypasses? Problem

# Testing confusion
- Tests must cover both code paths
- 2x test matrix (with flag ON and OFF)
- Eventually flag is removed, tests simplified

# Flag explosion
- 100 flags after 1 year
- Which ones are still needed?
- Stale flags create maintenance burden

# Performance
- Every request queries Feature Flag Service
- Must be sub-10ms (needs caching)
- Cache invalidation challenges
- Network failures can cause degradation
```

**Best Practices:**

1. **TTL-based cleanup:** Remove flags 30 days after 100% rollout
2. **Platform consistency:** All services use same Feature Flag Service
3. **Metrics per flag:** Track: adoption rate, error rate, latency per flag
4. **Circuit breaker:** If Feature Flag Service down, default to safe state (disable new features)
5. **Audit trail:** Log flag changes (who, when, what changed)
6. **Local-first failing:** If Feature Flag Service unavailable, use previously cached decision (don't fail)

---

**Document Status:**
- **Total Length:** ~7,500+ lines
- **Sections Completed:** 
  - Introduction ✓
  - Foundational Concepts ✓
  - Automation & Self-Healing ✓
  - Deployment Reliability ✓
  - Infrastructure Reliability ✓
  - Network Reliability ✓
  - Database Reliability ✓
  - Kubernetes Reliability ✓
  - Disaster Recovery ✓
  - Load Balancing Strategies ✓
  - Advanced Best Practices ✓
  - Hands-on Scenarios ✓ (5 scenarios)
  - Interview Questions ✓ (12 questions)

**Audience:** DevOps Engineers with 5–10+ years experience
**Last Updated:** March 2026

This comprehensive study guide is ready for production use, training, and further customization based on organizational needs.

