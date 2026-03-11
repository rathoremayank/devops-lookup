# Observability Fundamentals: Metrics, Logs, Traces, Prometheus, Grafana & OpenTelemetry
## Senior DevOps Study Guide

---

## Table of Contents

- [Table of Contents](#table-of-contents)
- [1. Introduction](#1-introduction)
  - [1.1 Overview of Topic](#11-overview-of-topic)
  - [1.2 Why it Matters in Modern DevOps Platforms](#12-why-it-matters-in-modern-devops-platforms)
  - [1.3 Real-World Production Use Cases](#13-real-world-production-use-cases)
  - [1.4 Where it Appears in Cloud Architecture](#14-where-it-appears-in-cloud-architecture)
- [2. Foundational Concepts](#2-foundational-concepts)
  - [2.1 Key Terminology](#21-key-terminology)
  - [2.2 The Three Pillars of Observability](#22-the-three-pillars-of-observability)
  - [2.3 Architecture Fundamentals](#23-architecture-fundamentals)
  - [2.4 Important DevOps Principles](#24-important-devops-principles)
  - [2.5 Best Practices](#25-best-practices)
  - [2.6 Common Misunderstandings](#26-common-misunderstandings)
- [3. Metrics Collection & Aggregation](#3-metrics-collection--aggregation)
  - [3.1 Metrics Fundamentals](#31-metrics-fundamentals)
  - [3.2 Types of Metrics](#32-types-of-metrics)
  - [3.3 Collection Strategies](#33-collection-strategies)
  - [3.4 Aggregation Patterns](#34-aggregation-patterns)
  - [3.5 Best Practices for Metrics Management](#35-best-practices-for-metrics-management)
- [4. Log Formats & Standards](#4-log-formats--standards)
  - [4.1 Log Fundamentals](#41-log-fundamentals)
  - [4.2 Structured vs Unstructured Logging](#42-structured-vs-unstructured-logging)
  - [4.3 Log Formats and Standards](#43-log-formats-and-standards)
  - [4.4 Log Levels and Severity](#44-log-levels-and-severity)
  - [4.5 Best Practices for Log Management](#45-best-practices-for-log-management)
- [5. Distributed Tracing Concepts](#5-distributed-tracing-concepts)
  - [5.1 Tracing Fundamentals](#51-tracing-fundamentals)
  - [5.2 Trace Context and Correlation](#52-trace-context-and-correlation)
  - [5.3 Sampling Strategies](#53-sampling-strategies)
  - [5.4 Trace Analysis Patterns](#54-trace-analysis-patterns)
  - [5.5 Best Practices for Distributed Tracing](#55-best-practices-for-distributed-tracing)
- [6. Prometheus Architecture & Monitoring](#6-prometheus-architecture--monitoring)
  - [6.1 Prometheus Architecture](#61-prometheus-architecture)
  - [6.2 Scrape Mechanism](#62-scrape-mechanism)
  - [6.3 PromQL Queries](#63-promql-queries)
  - [6.4 Recording Rules](#64-recording-rules)
  - [6.5 Alerting Rules](#65-alerting-rules)
  - [6.6 Remote Storage Integrations](#66-remote-storage-integrations)
  - [6.7 Best Practices for Prometheus](#67-best-practices-for-prometheus)
- [7. Grafana Dashboards & Visualization](#7-grafana-dashboards--visualization)
  - [7.1 Grafana Architecture](#71-grafana-architecture)
  - [7.2 Data Source Integrations](#72-data-source-integrations)
  - [7.3 Dashboard Design Principles](#73-dashboard-design-principles)
  - [7.4 Alerting with Grafana](#74-alerting-with-grafana)
  - [7.5 Performance Optimization](#75-performance-optimization)
  - [7.6 Best Practices for Grafana Visualization](#76-best-practices-for-grafana-visualization)
- [8. OpenTelemetry Standard & Implementation](#8-opentelemetry-standard--implementation)
  - [8.1 OpenTelemetry Architecture](#81-opentelemetry-architecture)
  - [8.2 Instrumentation Libraries](#82-instrumentation-libraries)
  - [8.3 Collector Components](#83-collector-components)
  - [8.4 Exporters](#84-exporters)
  - [8.5 Trace Context Propagation](#85-trace-context-propagation)
  - [8.6 Best Practices for OpenTelemetry](#86-best-practices-for-opentelemetry)
- [9. Tool Selection Criteria](#9-tool-selection-criteria)
  - [9.1 Evaluation Framework](#91-evaluation-framework)
  - [9.2 Comparative Analysis](#92-comparative-analysis)
  - [9.3 Integration Considerations](#93-integration-considerations)
  - [9.4 Cost and Scalability Analysis](#94-cost-and-scalability-analysis)
- [10. Hands-on Scenarios](#10-hands-on-scenarios)
- [11. Interview Questions](#11-interview-questions)

---

## 1. Introduction

### 1.1 Overview of Topic

**Observability** is the ability to understand the internal state of a system based on the data it produces. Unlike traditional monitoring, which focuses on predefined metrics and alerts, observability enables engineers to explore and understand complex, dynamic systems through three primary data types: **metrics, logs, and traces** (the "three pillars of observability").

This study guide covers:

1. **Metrics vs. Logs vs. Traces**: Understanding the distinct role each data type plays in system understanding
2. **Prometheus**: The de-facto standard for metrics collection and monitoring in modern cloud-native environments
3. **Grafana**: The visualization and dashboard platform that aggregates data from multiple sources
4. **OpenTelemetry**: The emerging standard for generating and collecting observability signals (metrics, logs, traces) in a vendor-agnostic way

For senior DevOps engineers, understanding these components is critical because:

- **System Complexity**: Modern distributed systems (microservices, Kubernetes, serverless) produce observability data at unprecedented scale
- **Troubleshooting**: Quick root cause analysis requires the ability to correlate signals across metrics, logs, and traces
- **Capacity Planning**: Metrics drive decisions about resource allocation, scaling policies, and cost optimization
- **Compliance**: Retention policies, sensitive data handling, and audit trails depend on proper observability implementation

### 1.2 Why it Matters in Modern DevOps Platforms

Modern cloud-native architectures present unique observability challenges:

#### **Scale and Complexity**
- Kubernetes clusters managing thousands of containers
- Microservices architectures with dozens or hundreds of services
- Multi-cloud and hybrid deployments
- Serverless functions with ephemeral lifecycles

#### **Velocity**
- Rapid application deployments (CI/CD pipelines)
- Fast-changing infrastructure (infrastructure-as-code)
- Zero-downtime deployments and rolling updates
- Feature flags and canary releases

#### **Cost Optimization**
- Data collection and storage at scale is expensive
- Organizations must balance observability comprehensiveness with cost
- Intelligent sampling and data retention policies are essential

#### **Operational Excellence**
- MTTR (Mean Time To Recovery) is directly tied to observability quality
- SLO/SLI/SLA frameworks depend on reliable metrics and tracing
- Post-incident analysis (blameless postmortems) requires detailed logs and traces

### 1.3 Real-World Production Use Cases

#### **Case Study 1: E-Commerce Platform During Black Friday**
- **Challenge**: Traffic increases 10x, need to detect performance degradation in milliseconds
- **Solution**: 
  - Prometheus scrapes critical metrics (request latency, error rates, database connections) every 15 seconds
  - Grafana dashboards alert when p95 latency exceeds thresholds
  - Distributed traces correlate slow requests across payment service → inventory service → database
  - Results: Incident detection in <2 minutes, root cause identified in <10 minutes

#### **Case Study 2: Kubernetes Cluster Resource Exhaustion**
- **Challenge**: Nodes running out of memory, but services report "healthy"
- **Solution**:
  - Prometheus metrics show node_memory_MemAvailable_bytes dropping
  - Pod-level logs reveal memory leak in specific service
  - OpenTelemetry traces show which requests trigger the leak
  - Results: Auto-scaling policy adjusted, leak patched in next release

#### **Case Study 3: Multi-Region API Latency Issues**
- **Challenge**: Customers in specific regions report slow API responses, headquarters (different region) doesn't see the problem
- **Solution**:
  - Prometheus metrics tagged with region show latency variance: US-East 50ms, EU-West 800ms
  - Logs filtered by region show "high DNS resolution time" in EU
  - Traces show the problematic DNS service
  - Results: DNS cache added, latency normalized

### 1.4 Where it Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────┐
│             Application Layer                        │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐             │
│  │ Service │  │ Service │  │ Service │             │
│  │   A     │  │   B     │  │   C     │ ← Instrument with OpenTelemetry
│  └────┬────┘  └────┬────┘  └────┬────┘             │
└───────┼────────────┼────────────┼──────────────────┘
        │            │            │
        └────────────┼────────────┘
                     │
        ┌────────────▼────────────┐
        │  Observability Backends │
        │                         │
        │  ┌──────────────────┐   │
        │  │ Prometheus       │   │ ← Scrapes metrics
        │  │ (Time-Series DB) │   │
        │  └──────────────────┘   │
        │                         │
        │  ┌──────────────────┐   │
        │  │ Log Aggregator   │   │ ← Collects logs
        │  │ (Loki/ELK/S3)    │   │
        │  └──────────────────┘   │
        │                         │
        │  ┌──────────────────┐   │
        │  │ Trace Backend    │   │ ← Stores traces
        │  │ (Jaeger/Tempo)   │   │
        │  └──────────────────┘   │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │  Grafana                │
        │  (Visualization Layer)  │ ← Queries all backends
        │                         │
        │  ┌──────────────────┐   │
        │  │ Dashboards       │   │
        │  │ Alerts           │   │
        │  │ Exploration      │   │
        │  └──────────────────┘   │
        └─────────────────────────┘
```

---

## 2. Foundational Concepts

### 2.1 Key Terminology

#### **Observability vs. Monitoring**
- **Monitoring**: Collecting predefined metrics and checking against thresholds (Red: CPU > 80%, alert)
- **Observability**: Ability to understand system state through generated data (Explore: Why is this service slow?)

#### **Signal Types**

| Term | Definition | Use Case |
|------|-----------|----------|
| **Metric** | Numeric value measured at a point in time | Count requests/sec, CPU usage %, latency p99 |
| **Log** | Discrete event record with timestamp and context | "User login failed: invalid password", error stack traces |
| **Trace** | Recording of request path through distributed system | Track payment request through 5 microservices |

#### **Cardinality**
- **High cardinality**: Many unique values (e.g., user_id, request_id) → Storage challenge
- **Low cardinality**: Few unique values (e.g., region, environment) → Easy to store and query

**Senior perspective**: "Our Prometheus instance crashed because engineers added a `user_id` label to every metric. With 1M unique users, that's 1M unique time series per metric. Unbounded cardinality is a silent killer."

#### **SAR vs. SERTe**
- **SAR** (Service Activity Rate): Requests/sec through a service
- **SER** (Service Error Rate): Failed requests as % of total
- **SLI/SLO**: Service-level indicators and objectives built from metrics

### 2.2 The Three Pillars of Observability

#### **Pillar 1: Metrics**
Aggregated, numeric measurements collected at regular intervals.

**Characteristics:**
- Lightweight to collect and store (compression-friendly)
- Time-series data (timestamp + value)
- Fast queries over historical periods
- Good for trending, alerting, capacity planning

**Examples:**
```
http_requests_total{service="payment", status="200"} 156432
http_request_duration_seconds_bucket{le="0.1", endpoint="/pay"} 890
node_memory_MemAvailable_bytes 4294967296
```

**When to use:**
- High-level system health (CPU, memory, network)
- Request rates and error rates across services
- Business metrics (orders/hour, revenue)
- Capacity planning and trend analysis

**Limitations:**
- Cannot answer "Show me all requests that took > 5 seconds" (too granular)
- Aggregation loses individual request context
- Requires predefined metrics (can't retroactively add new metrics)

#### **Pillar 2: Logs**
Unstructured or semi-structured text records of discrete events.

**Characteristics:**
- High volume (thousands to millions per second in large systems)
- Rich contextual information
- Queryable but less efficient than metrics
- Often used for debugging and audit trails

**Examples:**
```
2024-03-11T14:23:45.123Z service=payment level=ERROR trace_id=abc123 \
  request_id=req456 user_id=user789 msg="Payment processing failed" \
  error="insufficient_funds" processing_time_ms=1234
```

**When to use:**
- Debugging (understanding what happened at a specific time)
- Audit trails and compliance (who did what)
- Error investigation (error messages, stack traces)
- Business events (user signup, order placed)

**Limitations:**
- High storage costs at scale
- Text-based queries are slower than metric queries
- Structured logging requires discipline across organization
- Can contain sensitive data (PII, credentials)

#### **Pillar 3: Traces**
Records of a request's journey through a distributed system.

**Characteristics:**
- Captures causal relationships between services
- Shows latency at each hop
- Relatively low volume (sampled, not all requests)
- Excellent for understanding failures in distributed systems

**Examples:**
```
Trace: pay-request-123
├─ Span: API Gateway [0ms - 45ms]
│  └─ Span: Auth Service [2ms - 8ms]
│  └─ Span: Inventory Service [10ms - 30ms]
│     └─ Span: Database Query [15ms - 25ms]
│  └─ Span: Payment Service [35ms - 42ms]
```

**When to use:**
- Understanding request latency across services
- Failure analysis in microservices (which service is slow?)
- Performance optimization
- Dependencies discovery

**Limitations:**
- Cannot show the full picture with sampling (by design)
- Requires instrumentation across all services
- Backend storage is expensive
- Query language is less mature than metrics

### 2.3 Architecture Fundamentals

#### **The Observability Pipeline**

```
┌──────────────────────────────────────────────────────────┐
│ COLLECTION LAYER                                         │
│                                                          │
│  Prometheus Exporter  Log Agent  OpenTelemetry SDK     │
│  (scrapes metrics)    (ships logs) (instruments code)   │
└──────────────┬───────────┬──────────────┬───────────────┘
               │           │              │
┌──────────────▼────────────▼──────────────▼───────────────┐
│ TRANSMISSION LAYER                                       │
│                                                          │
│  Protocol: HTTP/HTTPS  gRPC  Syslog  Kafka             │
│  Compression: gzip, snappy, zstd                        │
│  Batching: Reduce overhead (e.g., 5000 events/batch)    │
└──────────────┬───────────┬──────────────┬───────────────┘
               │           │              │
┌──────────────▼────────────▼──────────────▼───────────────┐
│ BACKEND LAYER                                            │
│                                                          │
│  Prometheus  →  Time-Series Database (TSDB)            │
│  Logs        →  Log Aggregator (Loki, Elasticsearch)   │
│  Traces      →  Trace Backend (Jaeger, Tempo)          │
└──────────────┬───────────┬──────────────┬───────────────┘
               │           │              │
┌──────────────▼────────────▼──────────────▼───────────────┐
│ QUERY/VISUALIZATION LAYER                                │
│                                                          │
│  Grafana (dashboards, alerting, exploration)            │
│  AWS CloudWatch, DataDog, Honeycomb, etc.               │
└──────────────────────────────────────────────────────────┘
```

#### **Push vs. Pull Models**

| Aspect | Pull Model | Push Model |
|--------|-----------|-----------|
| **Direction** | Backend pulls from agent | Agent pushes to backend |
| **Default Port** | :9090 (prometheus) | :4317 (oltp gRPC), :4318 (otlp HTTP) |
| **Advantages** | Single pane of glass, discovery built-in | Works in restricted networks, lower latency |
| **Disadvantages** | Requires network access to all targets | More backend connections, harder to scale |
| **Example** | Prometheus scrapes :8080/metrics | OpenTelemetry collector pushes to backend |

**Senior decision**: "We use push for high-volume services (risk of overwhelming pull), pull for infrastructure metrics (more control, simpler debugging)."

### 2.4 Important DevOps Principles

#### **Principle 1: Instrumentation Consistency**
Every service must expose the same observability signals with consistent naming.

**Bad** (inconsistent):
```
Service A: request_count{endpoint="/api/v1/users"}
Service B: http_requests{path="/api/v2/users"}  
Service C: {requests_total}  # No labels at all
```

**Good** (consistent OpenTelemetry semantic conventions):
```
All Services: http.server.request.duration{http.url.path="/api/users", http.method="GET"}
```

#### **Principle 2: Cardinality Awareness**
High-cardinality labels (unique values per request) cause database bloat.

**Avoid:**
```
request_duration{user_id=user123, request_id=req456, ip_address=192.168.1.1}
↑ This creates unbounded cardinality
```

**Use instead:**
```
# Metrics with low cardinality
request_duration{service="payment", endpoint="/charge", status="200"}

# High cardinality in logs and traces
log: request_id=req456 user_id=user123 ip_address=192.168.1.1
trace: requestId="req456" userId="user123"
```

#### **Principle 3: Retention Policies**
Different data types have different retention needs and costs.

| Data Type | Retention | Reason | Storage Cost |
|-----------|-----------|--------|--------------|
| Metrics | 1-2 years | Build trends, capacity planning | **Low** (aggregated, compressed) |
| Raw Logs | 7-30 days | Debugging, compliance | **High** (verbose, high volume) |
| Sampled Traces | 48-72 hours | Recent root-cause analysis | **Very High** (very detailed) |
| Aggregated Traces | 90+ days | Historical analysis | **Medium** |

**Senior practice**: "We keep Prometheus metrics for 2 years, logs for 14 days, traces for 24 hours. Anything older goes to archive (S3) for compliance."

#### **Principle 4: Alerting Discipline**
Not every metric needs an alert. Alert fatigue leads to ignored alerts.

**Alert Quality Matrix:**

| Alert Type | Example | Actionable? | Keep? |
|-----------|---------|-------------|-------|
| **Smart** | "Disk will fill in 4 hours" | Yes, clear action | ✅ YES |
| **Smart** | "Error rate > 5% for 2 min" | Yes, page on-call | ✅ YES |
| **Noisy** | "CPU > 80%" (happens before autoscale) | No, autoscale handles it | ❌ Remove |
| **Noisy** | "Any error in logs" | No, only alert on patterns | ❌ Remove |
| **Noisy** | "Prometheus scrape latency > 1s" | Usually infrastructure issue | ⚠️ Tune |

### 2.5 Best Practices

#### **BP-1: Start Simple, Evolve Complexity**
Don't instrument everything on day one.

**Phase 1 (Week 1):**
- CPU, memory, disk across nodes
- HTTP request rate, error rate, latency (p50, p95, p99)
- Application startup time

**Phase 2 (Month 1):**
- Database connection pool usage
- Cache hit rates
- Third-party API call latencies

**Phase 3 (Month 3):**
- Distributed traces for slow paths
- Custom business metrics

#### **BP-2: Use Semantic Conventions**
Adopt OpenTelemetry semantic conventions to standardize naming.

```
# Good: Follows OTEL conventions
http.server.request.duration (metric)
http.request.body.size (metric)
db.client.connections.usage (metric)

# Bad: Non-standard naming
request_time_seconds
payload_size_bytes  
db_conn_in_use
```

**Benefit**: Tools and dashboards can auto-recognize metrics, reducing manual configuration.

#### **BP-3: Label-Value Strategy**
Use labels (tags) strategically for queryability without creating high cardinality.

**Good label selection:**
```
http_requests_total{
  service="payment",      # Low cardinality (5-10 services)
  endpoint="/charge",     # Low cardinality (20 endpoints)  
  status="200",           # Low cardinality (3-5 statuses)
  region="us-east-1"      # Low cardinality (3-5 regions)
}
```

**Cardinality calculation**: 10 services × 20 endpoints × 5 statuses × 5 regions = 5,000 time series (manageable)

**Bad:**
```
http_requests_total{
  user_id=user123,        # ❌ High cardinality (millions)
  city="Chicago"          # ❌ Medium cardinality (thousands)
}
# Results in millions of time series
```

#### **BP-4: Cost Optimization**
Observability at scale is expensive; optimize without losing visibility.

**Techniques:**
1. **Sampling**: Send 10% of traces, 100% of errors
2. **Aggregation**: Pre-aggregate metrics at source before sending
3. **Filtering**: Drop low-value metrics before transmission
4. **TTL Strategy**: Short TTL for debug logs (3 days), long TTL for critical logs (90 days)

**Cost example** (1000 RPS):
- **Without optimization**: 1000 traces/sec × $0.50/million spans = $1.6M/month 🔴
- **With 99% sampling**: 10 traces/sec × $0.50/million spans = $16K/month ✅
- **Smart sampling** (sample errors 100%, success 1%): ~$250K/month

### 2.6 Common Misunderstandings

#### **Misunderstanding #1: "Observability = Monitoring"**
**Wrong**: "We have Prometheus, so we have observability."

**Reality**: Prometheus provides metrics (visibility into **what** happened). Observability requires:
- Metrics (what)
- Logs (why)
- Traces (how)

**Fix**: "We'll add tracing and structured logging to complement our metrics."

---

#### **Misunderstanding #2: "More Data = Better Observability"**
**Wrong**: "Let's collect everything and store it forever."

**Reality**: 
- Storage is expensive (can exceed infrastructure costs)
- High-cardinality metrics cause database crashes
- Too much data makes troubleshooting harder, not easier

**Fix**: "We'll sample strategically and keep data for appropriate periods (metrics 2yr, logs 7-14d, traces 24-48h)."

---

#### **Misunderstanding #3: "Observability is only for debugging failures"**
**Wrong**: "We only look at metrics when things break."

**Reality**: 
- Proactive observability prevents incidents
- Capacity planning depends on historical trends
- Business decisions depend on observability data
- SLO achievement requires continuous measurement

**Fix**: "Observability is built into our SLO framework and reviewed in weekly architecture meetings."

---

#### **Misunderstanding #4: "We can build our own monitoring stack"**
**Wrong**: "Let's write custom collectors and dashboards."

**Reality**:
- Enterprise open-source stacks (Prometheus + Grafana) are battle-tested at scale
- Building custom adds maintenance burden without competitive advantage
- Industry convergence around Prometheus + OpenTelemetry + Grafana

**Fix**: "We'll use proven open-source + managed services, focusing engineering on business features."

---

#### **Misunderstanding #5: "Alerts should trigger on absolute thresholds"**
**Wrong**: "Alert when CPU > 80%."

**Reality**:
- Different services have different healthy CPU levels (batch job vs. latency-sensitive service)
- Alerts based on recent patterns (anomaly detection) > absolute thresholds
- Alert fatigue kills on-call culture

**Fix**: "We'll use dynamic thresholds based on service characteristics and historical behavior."

---

#### **Misunderstanding #6: "Trace sampling wastes data"**
**Wrong**: "We can't sample traces; we'll miss important requests."

**Reality**:
- **With 1000 RPS**, keeping 100% requires store/query latency in seconds
- **Smart sampling** captures 100% of errors + X% of success (you catch the problem)
- Long-tail latency issues still visible in aggregated metrics

**Fix**: "We'll use intelligent sampling: error rate 100%, latency errors 50%, success 1%."

---

## 3. Metrics Collection & Aggregation

### 3.1 Metrics Fundamentals

#### **Internal Working Mechanism**

Metrics collection operates in a continuous cycle:

1. **Instrumentation**: Application/system code exposes numeric values
2. **Exposition**: Metrics made available via pull endpoint (`:9090/metrics`) or push API
3. **Scraping**: Collector (typically Prometheus) retrieves metrics at interval (e.g., 15 seconds)
4. **Storage**: Time-series database stores (timestamp, value, labels)
5. **Aggregation**: Raw samples combined into higher-level summaries

**Example lifecycle** (HTTP request tracking):

```
Application Code:
  request_duration_ms = 145
  
Exposition (Prometheus format):
  http.server.request.duration_ms{endpoint="/api/users",status="200"} 145
  
Scraping (every 15s):
  14:00:00 → value: 145
  14:00:15 → value: 132
  14:00:30 → value: 156
  
Storage (TSDB):
  Time-series: http.server.request.duration_ms{endpoint="/api/users",status="200"}
    [14:00:00, 145]
    [14:00:15, 132]
    [14:00:30, 156]
    
Aggregation (PromQL):
  rate(http.server.request.duration_ms[1m]) = 143ms average
```

#### **Metric Types**

| Type | Purpose | Behavior | Example |
|------|---------|----------|---------|
| **Counter** | Track cumulative value | Only increases or resets | `http_requests_total: 1,000,000` |
| **Gauge** | Track fluctuating value | Goes up and down | `node_memory_MemAvailable_bytes: 4GB` |
| **Histogram** | Track distribution | Buckets + sum | `http_request_duration_seconds` (p50, p95, p99) |
| **Summary** | Track quantiles | Pre-calculated quantiles | `request_latency` with φ=0.5, 0.9, 0.99 |

**Production pattern** (request latency):

```
# BAD: Single gauge (loses distribution info)
request_latency_ms: 145

# GOOD: Histogram (can compute any quantile)
request_latency_seconds_bucket{le="0.005"}  10
request_latency_seconds_bucket{le="0.01"}   50
request_latency_seconds_bucket{le="0.025"}  200
request_latency_seconds_bucket{le="0.05"}   450
request_latency_seconds_bucket{le="0.1"}    890
request_latency_seconds_bucket{le="+Inf"}   1000
request_latency_seconds_sum              145.5
request_latency_seconds_count            1000
```

#### **Architecture Role**

```
┌──────────────────────────────────────────────────────┐
│ COLLECTION LAYER                                     │
│                                                      │
│  Host Agent (node_exporter)  ──┐                    │
│  Container (cadvisor, kubelet) ├─→ Pull Mechanism   │
│  Application (instrumentation) ──┤   (Prometheus    │
│  Database (DB exporter)        ──┘    scraper)      │
└──────────────────────────────────────────────────────┘
                    │
                    │ 15s interval
                    │
┌──────────────────▼──────────────────────────────────┐
│ TRANSMISSION (gzip, batching)                        │
└──────────────────┬──────────────────────────────────┘
                    │
┌──────────────────▼──────────────────────────────────┐
│ TIME-SERIES DATABASE (Local + Remote)                │
│                                                      │
│  In-Memory Index     ↔ WAL (Write-Ahead Log)        │
│  Compressed Blocks   ↔ Long-term Storage (S3)       │
└──────────────────┬──────────────────────────────────┘
                    │
         ┌──────────┴──────────┐
         │                     │
    PromQL Queries   Grafana Dashboards
    Custom Scripts   Alerting Engine
```

### 3.2 Types of Metrics

#### **Infrastructure Metrics**
Monitor physical/virtual resources:

```yaml
# Node-level
node_cpu_seconds_total{cpu="0",mode="user"}
node_memory_MemAvailable_bytes
node_memory_MemTotal_bytes
node_disk_io_time_seconds_total{device="sda"}
node_network_receive_bytes_total{device="eth0"}

# Kubernetes-specific
kubelet_node_name
container_memory_usage_bytes{pod_name="payment-xyz"}
container_cpu_usage_seconds_total{pod_name="payment-xyz"}
```

**Use case**: Capacity planning, cluster autoscaling decisions

#### **Application Metrics**
Generated by business logic:

```yaml
# HTTP/REST
http_requests_total{method="POST",endpoint="/charge",status="200"}
http_request_duration_seconds{quantile="0.95"}

# Application-specific
payment_processing_duration_seconds{currency="USD"}
orders_created_total{region="us-east-1"}
inventory_items_in_stock{sku="ABC123"}
```

**Use case**: Performance monitoring, business KPIs

#### **System Metrics**
Track software component health:

```yaml
# Database
pg_stat_statements_mean_time{query="SELECT * FROM users"}
pg_stat_replication_slot_retained_bytes
mysql_global_status_innodb_buffer_pool_free

# Cache
redis_connected_clients
redis_used_memory_bytes
redis_evicted_keys_total

# Message Queue
rabbitmq_queue_messages_ready
kafka_consumer_lag_sum{topic="payments"}
```

**Use case**: Component troubleshooting, SLA tracking

### 3.3 Collection Strategies

#### **Push vs. Pull Comparison (Detailed)**

**Pull Model** (Prometheus default):

```
Application exposes metrics port → Prometheus scraper → periodic collection
                                                        ↓
                                        Prometheus decides WHEN to collect
                                        
Advantage: Scraper has control over load (can back off if slow)
          Single source of truth for collection schedule
          Service discovery driven (Prometheus finds targets)
          
Disadvantage: Must open inbound ports (firewall complexity)
              Requires network access from Prometheus to all targets
              Loss of data if Prometheus can't reach target between scrapes
```

**Example** (Prometheus config):

```yaml
global:
  scrape_interval: 15s      # Collect every 15 seconds
  scrape_timeout: 10s       # Fail if endpoint doesn't respond in 10s

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: "true"
```

**Push Model** (OpenTelemetry, CloudWatch):

```
Application sends metrics → Backend collector → aggregation & storage
                            ↑
                   Application controls WHEN to send
                   
Advantage: Works behind firewalls (no inbound required)
          Lower latency (direct push vs. waiting for scrape)
          Application controls batch size & frequency
          
Disadvantage: Backend must handle variable load (could be hammered)
             Data loss if application fails before sending
             Requires authentication on collector endpoint
```

**Example** (Push with OpenTelemetry):

```python
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader

reader = PrometheusMetricReader()
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)

meter = metrics.get_meter("my_application")
request_counter = meter.create_counter("http_requests_total")

# Push happens when counter is incremented
request_counter.add(1, {"method": "POST", "status": "200"})
```

### 3.4 Aggregation Patterns

#### **Raw Metrics** → **High-Level Insights**

```
Raw sample:   http_request_duration_seconds = 0.145 (single request)
                                                      ↓
Scrape data:  [0.142, 0.145, 0.159, 0.148, 0.151]  (15s window, ~10 RPS)
                                                      ↓
Prometheus    rate() function: 10 requests/sec
PromQL:       histogram_quantile(0.95): 159ms       (95th percentile)
              sum() per service: combine 5 replicas
                                                      ↓
Grafana       "API has 10 req/sec, p95 latency 159ms"
Dashboard:    (High-level metric for alerting/SLO)
```

#### **Aggregation Rules** (Prometheus recording_rules.yml)

Pre-compute expensive queries and store results:

```yaml
groups:
  - name: microservices
    interval: 30s
    rules:
      # Compute request rate at scrape time (avoid recomputation in queries)
      - record: instance_requests:rate5m
        expr: rate(http_requests_total[5m])
        
      # Aggregated across replicas
      - record: services:request_rate:5m
        expr: sum(rate(http_requests_total[5m])) by (service)
        
      # Complex aggregation
      - record: services:latency:p95:5m
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
          by (service)
```

**Impact**: Recording rules reduce query load by 10-100x in production.

### 3.5 Best Practices for Metrics Management

#### **BP-3.1: Metric Naming**
Follow OpenTelemetry semantic conventions:

```
GOOD:   http.server.request.duration_seconds
        db.client.connection.usage
        process.runtime.go.goroutines

BAD:    request_time_ms
        db_conns_used
        goroutine_count
```

#### **BP-3.2: Cardinality Limits**
Prevent database explosion:

```yaml
# In Prometheus config
metric_relabel_configs:
  # Drop metrics from unhealthy services
  - source_labels: [__name__]
    regex: 'api_request_.*'
    target_label: __tmp_cardinality_limit
    
  # Limit high-cardinality labels
  - source_labels: [request_path]
    regex: '/api/users/[0-9]+'  # Replace user IDs with pattern
    target_label: request_path
    replacement: '/api/users/*'
```

**Result**: 1M unique paths → 1000 unique patterns (1000x reduction)

#### **BP-3.3: Metric Retention**
Balance storage and cost:

```
2 years of high-resolution metrics    = Infrastructure visibility, capacity planning
30 days of raw data + 2y aggregated   = Cost optimal for most orgs
7 days only                           = Very cost-sensitive, still works for alerts
```

---

## 4. Log Formats & Standards

### 4.1 Log Fundamentals

#### **Internal Working Mechanism**

Logs flow through multiple stages:

```
1. Application Code:
   logger.error("Payment failed", user_id=user123, amount=99.99, error="NSF")
   
2. Log Library Formatting:
   2024-03-11T14:23:45.123Z ERROR [payment-service] user_id=user123 amount=99.99 error=NSF
   
3. Transport (to aggregator):
   → Writes to stdout (container logs)
   → Istio/k8s captures → fluentd/fluent-bit
   → Ships to Elasticsearch/Loki
   
4. Storage:
   Index: timestamp, level, service
   Full text searchable
   
5. Query:
   SELECT * FROM logs WHERE service="payment" AND level="ERROR" 
     AND timestamp > now() - 1h
```

#### **Log Levels and Severity**

Standard hierarchy (lowest to highest):

| Level | When to Use | Example | Alert? |
|-------|-----------|---------|--------|
| **DEBUG** | Detailed tracing for development | "Cache hit for user:123" | No |
| **INFO** | Notable events, not errors | "Service started", "Job completed" | No |
| **WARNING** | Unexpected but handled | "Retry attempt 1/3", "Slow query detected" | No |
| **ERROR** | Recoverable errors | "Payment gateway timeout", "DB connection failed" | Yes |
| **CRITICAL/FATAL** | Unrecoverable errors | "Out of disk space", "Data corruption detected" | Yes (immediate) |

**Production practice**:
```
INFO logs in production → Only ~10% (log important events only)
ERROR logs in production → 100% (capture all errors)
DEBUG logs in production → Disabled (huge volume)
```

### 4.2 Structured vs Unstructured Logging

#### **Unstructured** (❌ Avoid in production)

```
2024-03-11 14:23:45 Payment processing failed for user 12345, 
order 67890, amount $99.99, error: gateway timeout after 5000ms, 
will retry in 30s
```

**Problem**: Cannot query reliably
```
# How do you find timeout issues?
grep "timeout" logs.txt  # Works but gets false positives
grep "gateway timeout" logs.txt  # Manual pattern
```

#### **Structured** (✅ Best practice)

```json
{
  "timestamp": "2024-03-11T14:23:45.123Z",
  "level": "ERROR",
  "service": "payment-service",
  "trace_id": "abc123def456",
  "span_id": "span789",
  "event": "payment_processing_failed",
  "user_id": "user12345",
  "order_id": "order67890",
  "amount_cents": 9999,
  "currency": "USD",
  "error_code": "GATEWAY_TIMEOUT",
  "error_message": "Payment gateway timeout",
  "retry_attempt": 1,
  "max_retries": 3,
  "retry_delay_ms": 30000,
  "duration_ms": 5000
}
```

**Advantage**: Queryable with structure
```bash
# Find timeout issues
curl -X POST "https://loki:3100/loki/api/v1/query_range" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'query={service="payment-service"} | json | error_code="GATEWAY_TIMEOUT"'

# Find slow payment processing
curl ... -d 'query={service="payment-service"} | json | duration_ms > 5000'
```

### 4.3 Log Formats and Standards

#### **Popular Log Formats**

| Format | Structure | Use Case | Parsing |
|--------|-----------|----------|---------|
| **JSON** | Key-value pairs | Cloud-native, structured indexing | Native JSON parser |
| **Logfmt** | `key=value key=value` | Lightweight, human readable | Regex/tokenizer |
| **CSV** | Comma-separated | Batch processing, data warehouses | CSV parser |
| **Syslog** | RFC3164/RFC5424 | Legacy systems, compliance | Syslog parser |

**Recommended for DevOps**: JSON (maximum tooling support)

#### **Log Context Fields** (OpenTelemetry Standard)

Every log should include:

```json
{
  "timestamp": "ISO8601",          # When it happened
  "level": "INFO/ERROR/DEBUG",     # Severity
  "service": "my-service",         # Which service (low-cardinality)
  "version": "v1.2.3",            # App version
  "environment": "prod",          # Environment
  "trace_id": "abc123",           # Distributed trace correlation
  "span_id": "span456",           # Specific operation within trace
  "message": "User login",         # Human-readable message
  "error": "...",                 # Error details if applicable
  
  # Optional high-cardinality (only if indexed separately)
  "user_id": "user789",
  "request_id": "req123",
  "session_id": "sess456"
}
```

### 4.4 Log Levels and Severity (Detailed)

**Sampling strategy** (reduce volume):

```yaml
# Fluent Bit sampling config
# For high-volume INFO logs, keep only 1 in 100
[FILTER]
    Name                  sampling
    Match                 service.logs.info
    Sample                100  # 1 out of 100

# For ERROR logs, keep all
[FILTER]
    Name                  sampling
    Match                 service.logs.error
    Sample                1  # All errors
```

### 4.5 Best Practices for Log Management

**BP-4.1: Structured Logging Library**

```python
# Using structlog (Python)
from structlog import get_logger

log = get_logger()

# Always include context
log.error(
    "payment_failed",
    user_id=user_id,
    amount=amount,
    reason="insufficient_funds",
    duration_ms=duration,
    retry_attempt=1
)

# Output: automatically formatted as JSON with context
```

**BP-4.2: Sensitive Data Handling**

```python
# BAD: Never log credentials
log.info(f"Database connection {db_password}")

# GOOD: Use redaction filters
log.info(
    "database_connection",
    host="db.example.com",
    user="admin",
    # password not logged
)

# In aggregator (Loki/ELK):
relabel_config:
  - source_labels: [password, api_key, token]
    regex: '.*'
    target_label: __tmp_redact
    replacement: "REDACTED"
```

**BP-4.3: Retention & Cost**

```yaml
# Different retention for different levels
Loki retention policies:
  - selector: '{level="DEBUG"}'
    period: 7d      # 7 days (development)
    
  - selector: '{level="INFO"}'
    period: 14d     # 14 days (operational)
    
  - selector: '{level=~"ERROR|CRITICAL"}'
    period: 90d     # 90 days (compliance, incidents)
    
  - selector: '{job="audit_logs"}'
    period: 2y      # 2 years (compliance requirement)
```

---

## 5. Distributed Tracing Concepts

### 5.1 Tracing Fundamentals

#### **Internal Working Mechanism**

A trace shows the complete journey of a request:

```
User Request: POST /checkout
│
├─ Span 1: API Gateway [0ms - 45ms]
│  │ Operation: "http.request"
│  │ Tags: method=POST, path=/checkout, status=200
│  │
│  ├─ Span 2: Auth Service [2ms - 8ms]
│  │  │ Operation: "auth.validate"
│  │  │ Tags: user_id=user123, status=valid
│  │  │ Event: "token_verified" at 5ms
│  │  │
│  │  └─ Span 3: Redis Cache [3ms - 4ms]
│  │      Operation: "cache.get"
│  │      Tags: key="session:user123", hit=true
│  │      Event: "cache_hit" at 3.5ms
│  │
│  ├─ Span 4: Inventory Service [10ms - 30ms]
│  │  │ Operation: "inventory.check"
│  │  │ Tags: sku="ABC123", status=available
│  │  │
│  │  └─ Span 5: PostgreSQL [12ms - 28ms]
│  │      Operation: "sql.query"
│  │      Tags: sql="SELECT * FROM inventory WHERE sku=?", duration=16ms
│  │      Event: "query_slow" (logged when exceeded 10ms threshold)
│  │
│  ├─ Span 6: Payment Service [35ms - 42ms]
│  │  │ Operation: "payment.process"
│  │  │ Tags: amount=99.99, currency=USD, status=success
│  │  │
│  │  └─ Span 7: Payment Gateway [37ms - 40ms]
│  │      Operation: "external.call"
│  │      Tags: provider="stripe", status=200
│  │      Event: "response_received" at 39ms
│  │
│  └─ Span 8: Notification Service [44ms - 44ms]
│      Operation: "notification.send"
│      Tags: type=email, status=queued
│
└─ Total: 45ms (User sees response)
```

#### **Key Concepts**

| Concept | Definition | Example |
|---------|-----------|---------|
| **Trace** | Complete request path through system | Entire checkout process (45ms) |
| **Span** | Single operation/service | "Auth validation" (8ms) |
| **Trace ID** | Unique request identifier | `abc1d3e4f5g6h7i8` |
| **Span ID** | Unique operation identifier | `xyz9abc1def2` |
| **Parent Span ID** | Caller's span | Links Auth → API Gateway |
| **Event** | Notable thing that happened | "cache_hit", "query_slow" |
| **Baggage** | Metadata propagated across spans | user_tier="premium" |

#### **Trace Context Standard**

W3C Trace Context specification:

```
Header: traceparent
Value:  00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
        └─ ──────────────────────────────────────────────────────
           Version / Trace ID / Span ID / Trace Flags

Every service must propagate traceparent:
  Service A → traceparent: xxx → Service B → traceparent: xxx → Service C
  ↓
  All three services share same trace_id
  ↓
Can reconstruct complete request path
```

### 5.2 Trace Context and Correlation

#### **How Correlation Works**

```
Request arrives at API Service:
  GET /users/123
  
1. API Service generates trace_id
   trace_id = "a1b2c3d4e5f6g7h8"
   span_id = "span_api_001"
   
2. API calls Auth Service
   POST /validate
   Headers: traceparent: 00-a1b2c3d4e5f6g7h8-span_api_001-01
   
3. Auth Service receives request
   Extracts: trace_id="a1b2c3d4e5f6g7h8"
            parent_span_id="span_api_001"
   Generates: span_id="span_auth_001"
   
4. Auth Service calls Redis
   Headers: traceparent: 00-a1b2c3d4e5f6g7h8-span_auth_001-01
   
5. All operations logged with trace_id
   Enabling search: Show me all spans where trace_id="a1b2c3d4e5f6g7h8"
   Result: Reconstruct entire request flow
```

**Manual Instrumentation** (for services without instrumentation):

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

def process_payment(user_id, amount):
    # Get current trace context (if present)
    current_trace = trace.get_current_span().get_span_context()
    trace_id = current_trace.trace_id
    
    # Log with trace_id for correlation
    log.info("Processing payment", 
             trace_id=hex(trace_id),
             user_id=user_id,
             amount=amount)
    
    # All downstream logs will use same trace_id
    # Enables: grep trace_id logs to see complete request sequence
```

### 5.3 Sampling Strategies

#### **Problem: Storage Explosion**

```
1000 requests/sec × 5 services × 10 spans per service = 50,000 spans/sec
50,000 spans/sec × 24 hours = 4.3 billion spans/day
4.3 billion spans × 1KB per span = 4.3 TB/day
4.3 TB × $0.10 per GB = $430/day = $157,000/year 🔴
```

#### **Solution: Smart Sampling**

```yaml
# In OpenTelemetry Collector
# Sample based on request attributes
samplers:
  - name: parentbased_always_on
    # Sample all errors, regardless of success rate
    
  - name: parentbased_always_off
    # Sample success requests at 1% rate
    
  - name: static
    sampling_percentage: 1  # 1% of all requests
```

**Implementation** (Python):

```python
from opentelemetry.sdk.trace.sampling import TraceIdRatioBased, \
    ParentBasedTraceIdRatioBased

# Sample 1% of requests, but 100% if parent already sampled
sampler = ParentBasedTraceIdRatioBased(
    root=TraceIdRatioBased(0.01),  # 1% of root requests
)
tracer_provider = TracerProvider(sampler=sampler)
```

**Result**: 
```
50,000 spans/sec with 1% sampling = 500 spans/sec
500 spans/sec × 86,400 seconds = 43M spans/day
43M × 1KB = 43GB/day = $4.30/day = $1,569/year ✅
(107x cost reduction while still catching most errors)
```

### 5.4 Trace Analysis Patterns

#### **Pattern 1: Latency Breakdown**

```
Find where time is spent:

Payment Service calls:
  ├─ Auth Service (2ms)    - FAST
  ├─ Inventory Service (20ms) - SLOW ← Focus here
  ├─ Payment Gateway (5ms)  - OK
  └─ Notification (2ms)    - FAST

Drill into Inventory:
  ├─ Database Query (18ms)  - SLOW ← Root cause
  │  └─ Full table scan (unindexed status field)
  └─ Cache (2ms)
```

**Action**: Add index on status column → 18ms → 2ms ✅

#### **Pattern 2: Error Tracing**

```
Dashboard shows: "x% of requests fail at random times"

Trace analysis:
  Every failed trace shows:
  Auth ✅ → Inventory ✅ → Payment ✅ → BUT Notification timeout ❌
  
  Notification Service logs unavailable

Result: Fix notification service → error rate drops ✅
```

#### **Pattern 3: Dependency Discovery**

```
"What services does payment-service depend on?"

Trace analysis: Follow all parent/child spans
  payment-service calls:
    ├─  auth-service
    ├─  inventory-service
    ├─  stripe (external)
    └─  kafka (event)
    
Use for:
  - Blast radius analysis ("if inventory fails, what breaks?")
  - Capacity planning ("inventory needs 2x more performance")
```

### 5.5 Best Practices for Distributed Tracing

**BP-5.1: Selective Instrumentation**

Don't instrument everything equal. Prioritize:

```
1. Critical user paths (payment, login, purchase)
2. Slow operations (database queries, external API calls)
3. Error paths (failure modes)

NOT:
- Cache gets (< 1ms usually)
- Config file reads
- Simple computations
```

**BP-5.2: Baggage for Context**

```python
# In API Gateway, set user info as baggage
baggage.set("user.tier", "premium")
baggage.set("user.region", "us-east-1")

# In downstream services, use baggage to make decisions
user_tier = baggage.get("user.tier")
if user_tier == "premium":
    max_retries = 5  # More lenient for premium users
else:
    max_retries = 1
```

**BP-5.3: Span Events for Detailed Debugging**

```python
with tracer.start_as_current_span("payment.process") as span:
    span.add_event("payment_started", {"amount": 99.99})
    
    try:
        result = call_payment_gateway()
        span.add_event("gateway_response", {
            "status": result.status,
            "response_time_ms": result.duration
        })
    except TimeoutError:
        span.add_event("gateway_timeout", {
            "retry_attempt": attempt,
            "timeout_ms": 5000
        })
        raise
```

---

## 6. Prometheus Architecture & Monitoring

### 6.1 Prometheus Architecture

#### **Internal Component Design**

```
┌─────────────────────────────────────────────────────────┐
│ PROMETHEUS SERVER (Single binary)                        │
│                                                         │
│  ┌─────────────────┐  ┌──────────────────┐            │
│  │ Scrape Manager  │  │  Query Engine    │            │
│  │                 │  │  (PromQL)        │            │
│  │ - Discovers     │  │  - Parse queries │            │
│  │   targets       │  │  - Evaluate      │            │
│  │ - Schedules     │  │  - Return results│            │
│  │   scrapes       │  │                  │            │
│  │ - Retries       │  │                  │            │
│  └────────┬────────┘  └────────┬─────────┘            │
│           │                    │                       │
│  ┌────────▼──────────────────▼──────┐                 │
│  │ Time-Series Database (TSDB)       │                 │
│  │                                   │                 │
│  │ ┌─────────────────────────────┐  │                 │
│  │ │ Immutable Blocks (2h)       │  │                 │
│  │ │ - Compressed snapshots      │  │                 │
│  │ │ - Index for fast lookups    │  │                 │
│  │ │ - WAL (recent data)         │  │                 │
│  │ └─────────────────────────────┘  │                 │
│  │                                   │                 │
│  │ ┌─────────────────────────────┐  │                 │
│  │ │ In-Memory Index             │  │                 │
│  │ │ - Metric names              │  │                 │
│  │ │ - Label combinations        │  │                 │
│  │ │ - Series cardinality        │  │                 │
│  │ └─────────────────────────────┘  │                 │
│  └───────────────────────────────────┘                 │
│                                                         │
│  ┌───────────────────────────────────┐                 │
│  │ Alerting Engine                   │                 │
│  │ - Evaluates alert rules           │                 │
│  │ - Generates alerts                │                 │
│  │ - Routes to AlertManager          │                 │
│  └───────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────┘

External Components:
  Targets (exporters, apps) → (scrape) → Prometheus
  Prometheus → (query) → Grafana, Alertmanager, clients
  Prometheus → (remote write) → S3, Cortex for long-term
```

#### **Data Flow**

```
1. Scrape Phase (every 15s default)
   Prometheus connects to :9090/metrics
   Receives text format:
   
   http_requests_total{service="api",status="200"} 1000
   http_request_duration_seconds_bucket{...} 0.5
   
2. Parsing
   - Parse metric name
   - Parse labels (as key-value pairs)
   - Parse value (float64)
   - Associate with timestamp (scrape time)

3. Relabeling
   - Apply metric_relabel_configs (drop, rename, keep/drop)
   - Example: drop sensitive labels, standardize names
   
4. Storage
   - Store in TSDB:
     Series key: metric_name + label_set
     Values: (timestamp, float64) pairs
   - Index created for fast lookups
   
5. WAL (Write-Ahead Log)
   - Recent data kept in append-only log
   - Survives crashes
   - Every 2h: compacted into immutable block
```

### 6.2 Scrape Mechanism (Detailed)

#### **Configuration**

```yaml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - default
            - monitoring
    
    # Only scrape pods with annotation
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: "true"
      
      # Extract port from annotation
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __param_port
        
      # Rename __address__ to include custom port
      - source_labels: [__address__, __param_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
        
      # Extract pod name as label
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
```

#### **Service Discovery (Auto-Discovery)**

Targets automatically discovered via:

| Method | Source | Example |
|--------|--------|---------|
| **static_configs** | Manual list | Hard-code IPs |
| **consul_sd** | Consul catalog | Services register, Prometheus discovers |
| **kubernetes_sd** | Kube API server | Pod, node, service discovery |
| **dns_sd** | DNS SRV records | Example.com:9090 |
| **ec2_sd** | AWS EC2 API | Auto-discover running instances |

**Kubernetes example** (auto-discover all pods):

```yaml
kubernetes_sd_configs:
  - role: pod

# This discovers:
# - All pods across all namespaces
# - Metadata: namespace, pod_name, labels, etc.
# Filter with relabel_configs
```

### 6.3 PromQL Queries

#### **Query Types**

| Type | Purpose | Example |
|------|---------|---------|
| **Instant** | Single point in time | `http_requests_total` (right now) |
| **Range** | Time series over interval | `http_requests_total[1h]` (last hour) |
| **Aggregation** | Combine series | `sum(http_requests_total)` (across services) |
| **Function** | Transform data | `rate(http_requests_total[5m])` (req/sec) |

#### **Essential Functions**

```promql
# Rate: Convert counter to per-second rate
rate(http_requests_total[5m])  # Average req/sec over 5min
irate(http_requests_total[5m]) # Instant rate (more volatile)

# Aggregation
sum(http_requests_total)       # Total across all series
sum by (service) (http_requests_total)  # Total per service
topk(5, http_requests_total)   # Top 5 services

# Percentiles (from histogram)
histogram_quantile(0.95, rate(http_duration_seconds_bucket[5m]))
# 95th percentile latency

# Selection
metric{label="value"}          # Filter by label
metric{label=~"value.*"}       # Regex matching
metric offset 1h               # Historical comparison

# Comparison
rate(errors_total[5m]) > 0.05  # Alert if error rate > 5%
```

**Complex Query Example** (Multi-service latency):

```promql
# Show 95th percentile latency per service, only for slow services
histogram_quantile(
  0.95,
  sum by (service, le) (
    rate(http_request_duration_seconds_bucket[5m])
  )
) > 0.1
```

### 6.4 Recording Rules

#### **Purpose**

Pre-compute expensive queries, store as new metrics:

```yaml
groups:
  - name: slos
    interval: 30s
    rules:
      # Raw data: compute rate at scrape-time
      - record: instance:requests:rate5m
        expr: rate(http_requests_total[5m])
        
      # Aggregated: sum across instances
      - record: job:requests:rate5m
        expr: sum by (job) (instance:requests:rate5m)
        
      # Complex: error rate SLO
      - record: job:error_rate:5m
        expr: |
          sum by (job) (rate(http_requests_total{status=~"5.."}[5m]))
          /
          sum by (job) (rate(http_requests_total[5m]))
```

**Result**:
```
Before recording rules:
  Query: complex aggregation → 2 second query time
  
After recording rules:
  Query: `job:error_rate:5m` → 10ms query time (pre-computed)
```

### 6.5 Alerting Rules

#### **Alert Configuration**

```yaml
groups:
  - name: payment_service
    interval: 30s
    rules:
      - alert: PaymentServiceDown
        expr: up{job="payment"} == 0
        for: 1m  # Alert only if true for 1 minute (prevent flapping)
        labels:
          severity: critical
          component: payment
        annotations:
          summary: "Payment service is down"
          description: "Payment service {{ $labels.instance }} is not responding"
          dashboard: "https://grafana.example.com/d/payment"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 2m
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          runbook: "https://wiki.example.com/high-error-rate"
```

#### **Alert States**

```
Firing  ← Active, needs attention (human response required)
Pending ← Condition true, but waiting for "for" duration
Inactive ← OK, no action needed
```

**Example** (Alert for disk full):

```
14:00 - Disk usage 70% (below threshold → Inactive)
14:15 - Disk usage 85% (exceeds 80% threshold → Pending)
14:16 - Disk usage 87% (still pending)
14:17 - Disk usage 90% (for > 2min → Firing 🚨)
       AlertManager sends to Slack, PagerDuty
14:18 - Disk usage suddenly 10% (operation freed space)
       → Resolved (alert closed)
```

### 6.6 Remote Storage Integrations

#### **Problem**

Prometheus stores 15 days by default (configurable):
- Old data deleted
- No long-term trend analysis
- Cannot compare year-over-year

#### **Solution Options**

| Option | Trade-offs | Cost | Use Case |
|--------|-----------|------|----------|
| **Thanos** | Complex, high availability | Low (opensource) | 10+ years retention, multi-cluster |
| **Cortex** | Managed clusters, best compliance | Medium | Cloud-native, multi-tenant |
| **AWS Timestream** | AWS-only, $0.5/M records | Medium | Simplicity, serverless |
| **VictoriaMetrics** | High compression, good query perf | Low (opensource) | Cost-optimized, high cardinality |
| **S3 + Glacier** | Manual glue code | Very Low | Archival, compliance holds |

**Thanos Architecture** (common choice):

```
┌──────────────────────────────────────────────────────┐
│ Prometheus 1  → Thanos Sidecar ──────┐              │
├──────────────────────────────────────────────────────┤
│ Prometheus 2  → Thanos Sidecar ──────┤              │
├──────────────────────────────────────────────────────┤
│ Prometheus 3  → Thanos Sidecar ──────┼─→ S3 Bucket  │
│                                      │  (Long-term) │
│                                      ├─→ Thanos     │
│                                      │   Query      │
│                                      │  (Frontend)  │
│                                      │              │
│ Thanos Compactor (dedup) ───────────┘              │
└──────────────────────────────────────────────────────┘
```

### 6.7 Best Practices for Prometheus

**BP-6.1: Monitor Prometheus itself**

```yaml
- alert: PrometheusOutOfMemory
  expr: node_memory_MemAvailable_bytes < 500e6  # 500MB free
  
- alert: PrometheusOptsDBSize
  expr: prometheus_tsdb_symbol_table_size_bytes > 500e9  # 500GB

- alert: PrometheusQueryLatency
  expr: histogram_quantile(0.95, rate(
    prometheus_http_request_duration_seconds_bucket{handler="/api/v1/query"}[5m]
  )) > 1.0  # Alert if 95th percentile > 1 second
```

**BP-6.2: Cardinality Monitoring**

```promql
# Check series count per job
count by (job) (count by (job, __name__) ({__name__=~".+"}))

# Find high-cardinality metrics
topk(10, count by (__name__) (count by (__name__, job_instance) ({__name__=~".+"})))
```

---

## 7. Grafana Dashboards & Visualization

### 7.1 Grafana Architecture

#### **Component Overview**

```
┌─────────────────────────────────────────────────────┐
│ GRAFANA (Frontend + Backend)                         │
│                                                     │
│ ┌───────────────────────────────────────────────┐  │
│ │ Backend (Go)                                   │  │
│ │  - Dashboard storage (SQL database)            │  │
│ │  - User management                             │  │
│ │  - Alert evaluation                            │  │
│ │  - RBAC (Role-Based Access Control)            │  │
│ │  - Plugin management                           │  │
│ └────────┬────────────────────────────────────┬──┘  │
│          │                                    │     │
│ ┌────────▼──────────────────────────────────▼──┐  │
│ │ Query Engine                                  │  │
│ │  - Execute queries on configured datasources │  │
│ │  - Cache results                              │  │
│ │  - Handle variables/templating                │  │
│ └────────┬──────────────────────────────────┬──┘  │
│          │                                  │     │
│ ┌────────▼──────────────────────────────────▼──┐  │
│ │ Datasources (Pluggable)                       │  │
│ │ ├─ Prometheus                                 │  │
│ │ ├─ Elasticsearch / Loki (logs)                │  │
│ │ ├─ Jaeger (traces)                            │  │
│ │ ├─ CloudWatch, DataDog (managed)              │  │
│ │ └─ Custom plugins                             │  │
│ └────────┬──────────────────────────────────┬──┘  │
│          │                                  │     │
│ ┌────────▼──────────────────────────────────▼──┐  │
│ │ Frontend (React)                              │  │
│ │  - Interactive dashboards                     │  │
│ │  - Alerting UI                                │  │
│ │  - Exploration view                           │  │
│ │  - Live update (subscriptions)                │  │
│ └─────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘

External Integrations:
  Grafana ←→ Prometheus (read metrics)
  Grafana ←→ AlertManager (read alert status)
  Grafana ←→ Slack/PagerDuty/etc (send notifications)
```

### 7.2 Data Source Integrations

#### **Prometheus Integration**

```json
{
  "uid": "prometheus",
  "type": "prometheus",
  "url": "http://prometheus:9090",
  "access": "proxy",  // Backend-proxied, can be "direct"
  "isDefault": true,
  "jsonData": {
    "timeInterval": "15s",  // Scrape interval
    "queryTimeout": "30s"
  }
}
```

**Query format** (PromQL):

```
Panel query: rate(http_requests_total[5m])
Grafana will:
  1. Send to Prometheus (every refresh)
  2. Parse response
  3. Render on graph
```

#### **Loki Integration** (Logs)

```json
{
  "uid": "loki",
  "type": "loki",
  "url": "http://loki:3100",
  "access": "proxy"
}
```

**Query format** (LogQL):

```
Panel query: {job="api-server"} | json | status_code="500"
Meaning:
  - Get logs with job label = "api-server"
  - Parse as JSON
  - Filter where status_code field = "500"
```

#### **Jaeger Integration** (Traces)

```json
{
  "uid": "jaeger",
  "type": "jaeger",
  "url": "http://jaeger:16686"
}
```

**Usage**: Search traces by service, operation, duration

### 7.3 Dashboard Design Principles

#### **Principle 1: Hierarchy of Information**

```
ROW 1: System Health (RED metrics)
├─ Overall system status
├─ Request rate (RPS)
├─ Error rate (%)
└─ Latency (p95)

ROW 2: By-Service Breakdown
├─ Service A: req rate, error rate, latency
├─ Service B: req rate, error rate, latency
├─ Service C: req rate, error rate, latency
└─ Service D: req rate, error rate, latency

ROW 3: Dependencies
├─ Database connections
├─ Cache hit rate
├─ External API latency
└─ Message queue depth

ROW 4: Resource Usage (under row 1 for context)
├─ CPU per pod
├─ Memory per pod
└─ Disk saturation
```

**Rationale**: 
- On-call sees health in first 3 seconds (Row 1)
- If problem, drill down row by row
- Reduces dashboard overload

#### **Principle 2: Color Coding**

```
Green: Healthy, expected behavior
Yellow: Warning, approaching limits or degradation
Red: Critical, SLA violated, human action needed
```

**Thresholds** (example):
```
Latency p95:
  Green:  < 100ms
  Yellow: 100-500ms
  Red:    > 500ms

Error rate:
  Green:  < 0.1%
  Yellow: 0.1-2%
  Red:    > 2%
```

#### **Principle 3: Show Trends**

```
Don't show:  Single number "1000 requests"
Show instead: Graph with 1h trend
              
Visual: ↗ (going up) vs. → (stable) vs. ↘ (declining)
Meaning: Helps predict "will this cause a problem?"
```

#### **Example Dashboard Panel** (JSON):

```json
{
  "title": "Request Latency (p95)",
  "targets": [
    {
      "expr": "histogram_quantile(0.95, rate(http_duration_seconds_bucket[5m]))",
      "refId": "A",
      "legendFormat": "{{ service }}"
    }
  ],
  "thresholds": [
    {
      "value": 0.1,
      "color": "green"
    },
    {
      "value": 0.5,
      "color": "red"
    }
  ],
  "type": "graph",
  "span": 6
}
```

### 7.4 Alerting with Grafana

#### **Grafana Alert Rules** (vs. Prometheus)

| Aspect | Prometheus | Grafana |
|--------|-----------|---------|
| **Evaluation** | Prometheus server | Grafana evaluator (distributed) |
| **Datasource** | Metrics only | Any datasource (metrics, logs, etc.) |
| **State** | Firing → Resolved | Alerting → Pending → Resolved |
| **History** | Limited | Full state history |
| **Notifications** | AlertManager | Contact points (Slack, PagerDuty, etc.) |

#### **Configuration**

```yaml
alert_rule:
  uid: payment-errors
  title: High Payment Error Rate
  condition: C  # Condition C is the alerter
  data:
    - ref_id: A
      query_type: metrics
      datasource: prometheus
      expr: rate(http_requests_total{status=~"5..", service="payment"}[5m])
    
    - ref_id: B
      query_type: metrics
      datasource: prometheus
      expr: rate(http_requests_total{service="payment"}[5m])
    
    - ref_id: C
      expr: $A / $B > 0.05  # Alert if error rate > 5%
      
  alerting:
    notify_when: state_changes
    wait_for_duration: 2m
    ref_id: C
```

### 7.5 Performance Optimization

#### **Query Performance**

```
Slow dashboard: Each panel takes 5s × 10 panels = 50s load time
                
Optimizations:
1. Use recording rules (pre-computed metrics)
   - Instead of: rate(http_requests...)[complex aggregation]
   - Use: job:error_rate:5m (pre-calculated)
   
2. Increase sampling
   - Instead of: 1 sample every second (60/min)
   - Use: 1 sample every 30s (2/min) for long time-range queries
   
3. Cache queries
   ```json
   {
     "cache": {
       "enabled": true,
       "ttl": "60s"
     }
   }
   ```

4. Reduce series cardinality
   - Use label filtering in queries
   - Exclude low-value metrics
```

#### **Storage Optimization**

```
Dashboard JSON stored in Grafana DB:
  Large dashboards: 50KB+ (lots of panels, queries)
  
Optimization:
  - Use variables to reduce copy-paste
  - Collapse unused rows
  - Archive old dashboards
```

### 7.6 Best Practices for Grafana Visualization

**BP-7.1: Template Variables**

```
Instead of 10 dashboards (one per service):
  Create 1 dashboard with variable $service

Then:
  - Query uses: rate(http_requests_total{service="$service"})
  - Dropdown allows: api-service, payment-service, inventory-service
  - Single source of truth
```

**BP-7.2: Shared Library Dashboards**

```yaml
# Store dashboards as code (git)
dashboards/
├── payment-service.json
├── api-service.json
├── shared-panels.json  # Common panels

On deploy:
  Git commit → Dashboard updated via API → Available in Grafana
```

---

## 8. OpenTelemetry Standard & Implementation

### 8.1 OpenTelemetry Architecture

#### **Three Pillars in OpenTelemetry**

```
SIGNALS:
  - Traces  → OpenTelemetry SDK
  - Metrics → Instrumentation library
  - Logs    → Auto-instrumentation

         ↓

COLLECTOR:
  - Receivers (gRPC, HTTP, Jaeger format)
  - Processors (batching, sampling, redaction)
  - Exporters (Prometheus, Jaeger, CloudWatch)

         ↓

BACKENDS:
  - Jaeger (traces)
  - Prometheus (metrics)
  - ELK Stack (logs)
```

#### **End-to-End Flow**

```
Python App:
  from opentelemetry import trace, metrics
  from opentelemetry.sdk.trace import TracerProvider
  from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
  
  exporter = OTLPSpanExporter(
    endpoint="otel-collector:4317",  # gRPC endpoint
  )
  tracer_provider = TracerProvider(span_processors=[
    BatchSpanProcessor(exporter)
  ])
  
  tracer = trace.get_tracer(__name__)
  with tracer.start_as_current_span("payment.process") as span:
    span.set_attribute("user_id", user_id)
    # Span sent to collector

         ↓

Collector (otel-collector):
  receivers:
    otlp:
      protocols:
        grpc:
          endpoint: 0.0.0.0:4317
  
  processors:
    batch:
      send_batch_size: 512
    sampling:  # Keep 10% of traces
      sampling_percentage: 10
  
  exporters:
    jaeger:
      endpoint: jaeger:14250
  
  service:
    pipelines:
      traces:
        receivers: [otlp]
        processors: [batch, sampling]
        exporters: [jaeger]

         ↓

Jaeger (Backend):
  - Stores traces in Elasticsearch
  - Provides query UI for exploration
  - Integration with Grafana for dashboard embedding
```

### 8.2 Instrumentation Libraries

#### **Automatic Instrumentation** (Easiest)

```python
# Minimal code changes required
pip install opentelemetry-auto-instrumentation

# For Python:
opentelemetry-bootstrap -a install

# Python app starts normally, tracing auto-enabled
python app.py
```

**What it covers automatically**:
- HTTP/gRPC requests (incoming and outgoing)
- Database connections (psycopg2, pymongo, etc.)
- Cache operations (redis, memcached)
- Message queues (kafka, rabbitmq)

#### **Manual Instrumentation** (For custom logic)

```python
from opentelemetry import trace, metrics

tracer = trace.get_tracer(__name__)
meter = metrics.get_meter(__name__)

# Traces
with tracer.start_as_current_span("payment.process") as span:
    span.set_attribute("amount", 99.99)
    try:
        result = payment_gateway.charge()
        span.set_attribute("status", "success")
    except Exception as e:
        span.record_exception(e)
        span.set_status(trace.Status(trace.StatusCode.ERROR))

# Metrics
request_counter = meter.create_counter(
    "http.requests",
    description="HTTP request count"
)
request_counter.add(1, {"method": "POST", "status": "200"})
```

#### **Language-Specific Libraries**

| Language | Instrumentation | Auto-instrumentation |
|----------|-----------------|--------|
| **Python** | opentelemetry-instrumentation-* | Yes (via agent) |
| **Java** | opentelemetry-javaagent | Yes (JVM agent) |
| **Go** | otelhttp, otelgrpc | No (manual only) |
| **JavaScript** | @opentelemetry/api | Limited (webpack wrapper) |
| **.NET** | OpenTelemetry NuGet packages | No (manual) |

### 8.3 Collector Components

#### **Receivers** (Input)

```yaml
receivers:
  # Receive spans via OTLP standardformat
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317  # gRPC
      http:
        endpoint: 0.0.0.0:4318  # HTTP
  
  # Receive Prometheus metrics
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 10s
  
  # Receive Jaeger spans (for forwarding)
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
```

#### **Processors** (Middle)

```yaml
processors:
  # Batch for efficiency
  batch:
    send_batch_size: 512
    timeout: 10s  # Max wait time
  
  # Sampling (reduce data volume)
  sampling:
    sampling_percentage: 10  # Keep 10% of traces
  
  # Memory limiter (protection)
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
  
  # Attribute processor (redaction)
  attributes:
    actions:
      - key: password
        action: delete  # Remove passwords
      - key: http.url
        pattern: 'bearer\s+[a-zA-Z0-9\.]+' # Redact tokens
        action: update
        from_attribute: http.url
```

#### **Exporters** (Output)

```yaml
exporters:
  # To Jaeger (traces)
  jaeger/grpc:
    endpoint: jaeger-collector:14250
  
  # To Prometheus (metrics)
  prometheusremotewrite:
    endpoint: "http://prometheus:9090/api/v1/write"
  
  # To AWS (managed)
  awsxray:
    num_workers: 8
    endpoint: ""  # Auto-detects region
  
  # To DataDog (managed)
  datadog:
    api:
      key: ${DATADOG_API_KEY}
```

### 8.4 Exporters (Detailed)

#### **Jaeger Exporter** (Traces)

```python
from opentelemetry.exporter.jaeger.thrift import JaegerExporter

jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger-agent",
    agent_port=6831,  # Thrift compact
)

tracer_provider = TracerProvider(
    span_processors=[
        BatchSpanProcessor(jaeger_exporter),
    ],
)
```

#### **Prometheus Exporter** (Metrics)

```python
from opentelemetry.exporter.prometheus import PrometheusMetricReader

reader = PrometheusMetricReader()
provider = MeterProvider(metric_readers=[reader])

# Prometheus scrapes this exporter at /metrics
# http://localhost:8000/metrics
```

### 8.5 Trace Context Propagation

#### **W3C Trace Context**

Standard header for correlation:

```
GET /api/checkout HTTP/1.1
Host: api.example.com
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
            │  │                    │               │
            │  └─ Trace ID         └─ Span ID      └─ Trace Flags
            └─ Version                            (sampled=1)
```

**Implementation** (Python):

```python
from opentelemetry.trace.propagation.tracecontext import TraceContextPropagator

propagator = TraceContextPropagator()

# When making outgoing request
headers = {}
propagator.inject(headers)  # Adds traceparent header

requests.get(
    "http://downstream-service/api",
    headers=headers  # ← Propagates trace context
)

# When receiving request
headers = request.headers
context = propagator.extract(headers)  # Extracts trace context
tracer_provider.set_span_context(context)  # Uses parent trace
```

### 8.6 Best Practices for OpenTelemetry

**BP-8.1: Semantic Conventions**

Adopt OTEL conventions for consistent naming:

```python
# Consistent naming across languages/services
span.set_attribute("http.method", "POST")       # NOT: method
span.set_attribute("http.url.path", "/api/users")  # NOT: path
span.set_attribute("db.system", "postgresql")   # NOT: database
span.set_attribute("db.statement", "SELECT...") # NOT: query
```

**BP-8.2: Context Propagation**

```python
# Every outgoing call must propagate context
def call_downstream():
    with tracer.start_as_current_span("downstream.call"):
        headers = {}
        propagator.inject(headers)  # MUST do this
        
        response = httpx.get(
            "http://service/api",
            headers=headers  # Enables trace correlation
        )
        return response
```

**BP-8.3: Sampling Strategy**

```python
sampler = ParentBasedTraceIdRatioBased(
    root=TraceIdRatioBased(0.10),  # 10% of root spans
    # But 100% if parent was sampled
)

# Results in:
# - High error rate paths: 100% sampled (parent=error-sampled)
# - Low error rate paths: 10% sampled (cost efficient)
```

---

## 9. Tool Selection Criteria

### 9.1 Evaluation Framework

#### **Decision Matrix**

```
Evaluate tools on:
  1. Functionality (does it solve the problem?)
  2. Scale (production-ready at your RPS?)
  3. Integration (works with your stack?)
  4. Operational Burden (can your team maintain?)
  5. Cost (capex + opex)
```

#### **Prometheus vs. Alternatives**

| Aspect | Prometheus | InfluxDB | CloudWatch |
|--------|-----------|----------|-----------|
| **Cost** | Free (infra) | Free (infra) | ~$0.50/1M API calls |
| **Scalability** | Vertical (single node) | Horizontal | Unlimited (AWS-managed) |
| **Query Language** | PromQL | InfluxQL | CloudWatch Insights |
| **Retention** | 15 days (configurable) | Configurable | 1yr (free tier) |
| **Best for** | General monitoring | High-cardinality analytics | AWS-only shops |

**Verdict**: Prometheus for on-premise, CloudWatch for AWS-native

### 9.2 Comparative Analysis

#### **Loki vs. Elasticsearch for Log Aggregation**

| Aspect | Loki | Elasticsearch |
|--------|------|---------------|
| **Index Strategy** | No index, labels only | Full-text index (expensive) |
| **Storage** | Very low | High (10-100x Loki) |
| **Query Speed** | Medium (label + stream search) | Fast (indexed search) |
| **Setup Complexity** | Simple (single binary) | Complex (cluster, ILM) |
| **Cardinality** | Low cardinality only | High cardinality friendly |
| **Cost** | $50-200/month on premises | $500-5000/month+ |

**Decision**: Use Loki if you have structured logs with low cardinality, Elasticsearch if you need full-text search.

#### **Jaeger vs. Tempo for Trace Storage**

| Aspect | Jaeger | Tempo |
|--------|--------|-------|
| **Backend Storage** | Elasticsearch, disk IO | S3, GCS, Azure Blob |
| **Query Performance** | Fast (memory index) | Slower (S3 lookups) |
| **Cost** | Low storage, high compute | Very low storage cost |
| **Scalability** | Horizontal (Elasticsearch) | Unlimited (cloud object store) |
| **Retention** | Weeks | Months/years |

**Decision**: Use Jaeger for interactive debugging (fast), Tempo for audit/compliance (cheap).

### 9.3 Integration Considerations

#### **Stack 1: Open Source On-Premise**
```
Prometheus (metrics)
↓
Node Exporter, Alertmanager
↓
Grafana
↓
Loki (logs), Jaeger (traces)
↓
PostgreSQL (config storage)
```

**Pros**: No vendor lock-in, full control, free  
**Cons**: Operator responsibility, infrastructure costs

#### **Stack 2: Cloud-Native (AWS)**
```
CloudWatch (metrics, logs)
↓
X-Ray (traces)
↓
Grafana (visualization via datasource plugins)
```

**Pros**: Managed service, auto-scaling, AWS integration  
**Cons**: Vendor lock-in, higher costs at scale

### 9.4 Cost and Scalability Analysis

#### **Cost Modeling** (1000 RPS application, 100 services)

| Component | On-Premise | AWS Managed | Cost Factor |
|-----------|-----------|-----------|------------|
| Prometheus metrics | $200/month (infra) | CloudWatch: $5K/month | 25x |
| Logs (100 GB/day) | Loki: $300 (infra) | CloudWatch Logs: $3K/month | 10x |
| Traces (10% sampled) | Jaeger: $500 (infra) | X-Ray: $2K/month | 4x |
| Visualization (Grafana) | $100 (infra) | Grafana Cloud: $500/month | 5x |
| **Total** | **$1,100/month** | **$10,500/month** | **9.5x** |

**Senior decision**: On-premise until 5000+ RPS, then evaluate cloud migration for managed benefits.

---

## 10. Hands-on Scenarios

### Scenario 1: Incident Response - API Latency Degradation

#### **Situation**
- **Time**: 14:32 UTC
- **Alert**: "API request latency p95 > 500ms" (normal: 150ms)
- **Impact**: 2000 users affected, customer support flooded
- **Time budget**: 5 minutes to diagnose, 15 minutes to mitigate

#### **Your Tasks**

**Step 1: System Health Check** (30 seconds)
```bash
# Query Prometheus for overall system status
curl -s 'http://prometheus:9090/api/v1/query?query=up' | jq '.data.result[] | select(.value[1]=="0")'

# Expected: All services should be up
# If down: Focus on downed service first
```

**Step 2: Identify Bottleneck Service** (1 minute)
```bash
# Query latency per service
curl -s 'http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) by (service)' | jq '.data.result'

# Look for service with p95 > 0.5s
# Example: payment-service shows 2.3s (normal: 0.08s)
```

**Step 3: Drill into Problem Service** (1.5 minutes)
```bash
# Check if service itself is slow or dependency
curl -s 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total{service="payment"}[5m]) by (status)' | jq '.data.result'

# Check error rate
curl -s 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total{service="payment",status=~"5.."}[5m])' | jq '.data.result'

# Expected: High error rate (5xx) indicates service problem
```

**Step 4: Trace Root Cause** (1.5 minutes)
```bash
# Query Jaeger for slow traces
# Search for traces where:
#   - service: payment-service
#   - duration > 500ms
#   - time range: last 5 mins

# Results show: All slow traces have Database span > 2 seconds
# Database latency: normal 50ms → now 2000ms
```

**Step 5: Check Database Resources** (1 minute)
```bash
# Query database metrics
curl -s 'http://prometheus:9090/api/v1/query?query=# Connection pool
mysql_global_status_innodb_open_files
mysql_global_status_innodb_buffer_pool_wait_free' | jq '.data.result'

# Results: Database has 0 free connections (normally: 50 available)
# Connection pool exhausted → all queries queue → timeout
```

#### **Root Cause**
A deployment 5 minutes ago changed timeout settings:
```diff
- connection_timeout: 300s
+ connection_timeout: 5s  # NEWLY DEPLOYED

Result: Connection acquisition timeouts → app queues → cascading latency
```

#### **Mitigation**
```bash
# Rollback deployment
kubectl rollout undo deployment/app-service -n production

# Verify recovery in Prometheus
# Within 1 minute, p95 latency returns to 150ms
```

#### **Post-Incident**
- Add integration test: "Verify database connection timeout setting"
- Add alert: "Database connection pool > 80% utilization"
- Document in runbook: Database connection pool exhaustion

---

### Scenario 2: Memory Leak Detection

#### **Situation**
- **Symptom**: Service restart every 6 hours
- **Root cause unknown**: No obvious errors in logs
- **Impact**: 30 second restart window, customers affected

#### **Investigation**

**Step 1: Confirm Memory Pattern**
```bash
# Query memory growth over 24 hours
curl -s 'http://prometheus:9090/api/v1/query_range?query=container_memory_usage_bytes{pod="payment-service"}' \
  '&start=2024-03-10T14:00:00Z&end=2024-03-11T14:00:00Z&step=300' | \
  jq '.data.result[0].values | .[] | .[1]'

# Graph memory: 0 → 512MB → 1GB → 1.5GB → 2GB (OOM kill) → restart
# Pattern: Linear growth over 6 hours
```

**Step 2: Identify Memory Leak Trigger**
```bash
# Correlate memory growth with requests
# Get request rate over same period
curl -s 'http://prometheus:9090/api/v1/query_range?query=rate(http_requests_total{pod="payment-service"}[5m])' \
  '&start=2024-03-10T14:00:00Z&end=2024-03-11T14:00:00Z&step=300' | \
  jq '.data.result[0].values | .[] | .[1]'

# Observation: Memory grows 1MB per 1000 requests
# Suggests: ~1KB of memory leaked per request
```

**Step 3: Find Problematic Code Path**
```bash
# Query traces for slow/failing requests that might hold resources
curl -X POST 'https://jaeger:16686/api/traces' \
  -d '{"service":"payment-service","minDuration":"1s","limit":100}'

# Review traces: All traces are fast (100ms)
# So memory leak is NOT in request path

# Review logs for background jobs
grep 'background\|job\|cache\|pool' logs/*.log

# Found: "Cache refresh job runs every minute, adds to cache"
```

**Step 4: Code Review**
```python
# Suspected code: cache_refresher.py
# ISSUE: Objects added to cache, never evicted

def refresh_cache():
    items = fetch_from_database()  # Returns 10,000 items
    for item in items:
        cache.set(item.id, item)  # NO TTL = Cache forever
        # Each call: 1KB × 10K items = 10MB added
        # Every 60s, another 10MB → Memory bloat

# FIX:
def refresh_cache():
    items = fetch_from_database()
    for item in items:
        cache.set(item.id, item, ttl=3600)  # 1 hour TTL
        # Old items auto-expire, memory constant
```

#### **Resolution**
1. Deploy fix with TTL
2. Verify memory plateaus in Prometheus
3. Remove restart restart schedule (no longer needed)
4. Add alert: "Memory growth rate > 100MB/hour"

---

### Scenario 3: Building an SLO Dashboard

#### **Business Requirement**
- API must have 99.9% uptime (SLO)
- Error budget: 43 seconds/day (0.1% × 86400s)
- Track on dashboard visible to customers

#### **Implementation**

**Step 1: Define SLI Metrics**
```yaml
# SLI 1: Availability = successful requests / total requests
availability_sli = 
  sum(rate(http_requests_total{status!~"5.."}[5m]))
  /
  sum(rate(http_requests_total[5m]))

# SLI 2: Latency = p95 < 500ms
latency_sli = 
  histogram_quantile(0.95, 
    rate(http_request_duration_seconds_bucket[5m])
  ) < 0.5

# SLI 3: Completeness = job runs successfully
completeness_sli = 
  rate(scheduler_jobs_succeeded_total[5m])
  /
  rate(scheduler_jobs_total[5m])
```

**Step 2: Create Recording Rules**
```yaml
# prometheus/recording_rules.yml
groups:
  - name: slo
    interval: 30s
    rules:
      - record: slo:availability:5m
        expr: |
          (sum(rate(http_requests_total{status!~"5.."}[5m])) 
           / sum(rate(http_requests_total[5m]))) * 100
        
      - record: slo:latency_ok:5m
        expr: |
          (histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket[5m])) < 0.5) * 100
            
      - record: slo:achievement:daily
        expr: |
          (slo:availability:5m + slo:latency_ok:5m + slo:completeness_sli) / 3
```

**Step 3: Grafana Dashboard Panel**
```json
{
  "title": "SLO Achievement",
  "targets": [
    {
      "expr": "slo:achievement:daily",
      "legendFormat": "Daily SLO %"
    }
  ],
  "thresholds": [
    { "value": 99.9, "color": "green" },
    { "value": 99.0, "color": "yellow" },
    { "value": 0, "color": "red" }
  ],
  "gauge": {
    "maxValue": 100,
    "minValue": 98
  }
}
```

**Step 4: Error Budget Tracking**
```sql
-- Track usage of error budget
budget_used = 100 - slo:achievement:daily
budget_remaining_today = (99.9 - budget_used) / 99.9 * 43_seconds

-- Query: How many seconds of errors can we tolerate today?
-- Result: 40 seconds remaining (used 3 of 43)
```

---

### Scenario 4: Multi-Cluster Observability and Trace Correlation

#### **Situation**
- **Architecture**: Payment service split across two Kubernetes clusters (us-east, eu-west)
- **Problem**: Users in EU report higher latency than US, but dashboards show same metrics
- **Root cause unknown**: Regional differences not visible in current observability
- **Challenge**: Implement correlation across clusters without lifting and shifting data

#### **Investigation**

**Step 1: Discover the Regional Variance**
```bash
# Query Prometheus with regional labels
curl -s 'http://prometheus:9090/api/v1/query?query=\
  histogram_quantile(0.95, \
    rate(http_request_duration_seconds_bucket[5m])) \
  by (region)' | jq '.data.result'

# Results:
# us-east: 120ms (healthy)
# eu-west: 850ms (degraded, 7x slower)
```

**Step 2: Drill into EU Regional Resources**
```bash
# Check if it's infrastructure or application
curl -s 'http://prometheus:9090/api/v1/query?query=\
  node_network_transmit_errors_total by (region)' | jq '.data.result'

# eu-west network errors: 15,000/min (abnormal)
# us-east network errors: 5/min (normal)

# Then check database connectivity
curl -s 'http://prometheus:9090/api/v1/query?query=\
  pg_stat_replication_slot_retained_bytes by (region)' | jq '.data.result'

# eu-west replication lag: 500MB (normal: <10MB)
```

**Step 3: Trace Analysis Across Regions**
```bash
# Query Jaeger for EU-region traces
curl -X GET 'https://jaeger:16686/api/traces?service=payment-service&tags=region%3Deu-west' | jq '.data[]'

# Trace breakdown:
# API → Payment Service (100ms, normal)
# Payment Service → Database (750ms, SLOW)
# Database → Replicate to Primary (50ms)

# Problem: Database replication path is slow
```

**Step 4: Root Cause Analysis**
```
Infrastructure:
  eu-west RDS is read-replica of us-east primary
  Replication lag: 500MB accumulated
  Network between regions: 200ms latency
  
Result:
  - EU payment service queries replica
  - Replica is 5 seconds behind (app retries)
  - Connection pooling backs up
  - Cascading latency
```

#### **Solution**

**Option A: Promote EU Replica to Independent Cluster** (Medium effort)
```bash
# AWS RDS:
# 1. Create read-only replica in eu-west
# 2. Promote replica to standalone instance (6-hour downtime)
# 3. Set up bidirectional replication with us-east

# Prometheus metric to verify:
curl -s '...' 'pg_stat_replication_slot_retained_bytes' < 10e6
```

**Option B: Cache Layer** (Quick, low-risk)
```python
# Add Redis cache in each region
# Cache payment verification results (1-minute TTL)

cache.set(f"payment:{order_id}:verified", True, ttl=60)

# Result:
# - Reduce database queries 90%
# - Latency p95: 850ms → 150ms
# - Deployment time: 2 hours
```

#### **Monitoring Post-Implementation**

```yaml
# New alerts for regional degradation
- alert: RegionalLatencySkew
  expr: |
    histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
    > 
    histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) * 2
  for: 2m

# Dashboard panel: Latency comparison by region
# Trace correlation: Filter by trace_id AND region tag
```

---

### Scenario 5: Observability During High-Traffic Surge and Cost Control

#### **Situation**
- **Event**: Black Friday sale starts, traffic spikes 10x (100 RPS → 1000 RPS)
- **Challenge**: Observability must scale without breaking budget
- **Current setup**: 
  - Prometheus local storage only (15-day retention)
  - Jaeger with 10% sampling
  - Full-resolution logs
- **Problem**: Storage and cost explodes during surge

#### **Pre-Event Preparation**

**Step 1: Calculate Surge Impact**
```
Normal state:
  Metrics: 50 GB/day
  Logs: 100 GB/day
  Traces: 5 GB/day (10% sampled)
  Total: 155 GB/day

During 10x surge:
  Metrics: 500 GB/day (cardinality explosion expected)
  Logs: 1000 GB/day (high verbosity)
  Traces: 50 GB/day (would need 100% sampling for debugging)
  Total: 1550 GB/day (WITHOUT optimization)

Cost impact: $5K/day → $50K/day
```

**Step 2: Implement Pre-Event Optimization**
```yaml
# prometheus.yml - Aggressive cardinality limiting
metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'customer_id|session_id|request_id'
    action: drop  # Drop high-cardinality in surge
    
  - source_labels: [path]
    regex: '/api/products/[0-9]+'
    replacement: '/api/products/*'
    target_label: path  # Reduce product ID cardinality
```

```yaml
# Fluentd - Log sampling during surge
<filter **>
  @type sampling
  sample_interval: 10  # Only 1 in 10 INFO logs during surge
</filter>

<filter **>
  @type detect_exceptions
  multiline_flush_interval 5s
  stream_key container_id
</filter>
```

```yaml
# Otel-collector - Trace sampling strategy
samplers:
  - name: parentbased_always_on
  
  - name: status_code
    sampling_percentage: 100   # All errors
    
  - name: latency
    min_duration_ms: 500
    sampling_percentage: 100   # 500ms+ latency
    
  - name: default
    sampling_percentage: 1     # 1% of normal requests
```

#### **During the Event**

**Step 1: Monitor Observability System Health**
```bash
# Check Prometheus is not swapping
curl -s 'http://prometheus:9090/api/v1/query?query=process_resident_memory_bytes' | jq '.data.result[0]'

# Expected: < node memory (no OOM)

# Check cardinality hasn't exploded
curl -s 'http://prometheus:9090/api/v1/query?query=\
  count(count by (__name__, job, instance, labels) ({__name__=~".+"}))' | jq '.'

# Expected: < 500K series (under control)
```

**Step 2: Emergency Retention Reduction** (if storage fills)
```bash
# Edit Prometheus retention policy on-the-fly
prometheus_flags="--storage.tsdb.retention.time=7d"  # Reduce from 15d to 7d

# Restart Prometheus (graceful shutdown)
curl -X POST http://prometheus:9090/-/quit

# Restart with new retention
systemctl start prometheus
```

**Step 3: Verify Query Performance**
```bash
# Check dashboard query latency
curl -s 'http://prometheus:9090/api/v1/query?query=\
  rate(prometheus_http_request_duration_seconds_sum[5m]) / \
  rate(prometheus_http_request_duration_seconds_count[5m])' | jq '.data.result'

# Expected: < 500ms for dashboard queries
# If > 2s: Need to reduce dashboard refresh rate or disable panels
```

#### **Post-Event Analysis**

**Step 1: Calculate Actual Cost Impact**
```bash
# Query metrics collection volume
cat prometheus-debug.log | grep -i "samples" | \
  awk '{print $NF}' | \
  awk '{sum+=$1} END {print "Total samples: " sum}'

# Example: 500M samples collected (instead of 5B without optimization)
```

**Step 2: Document Lessons Learned**
```markdown
# Black Friday Observability Report

## Optimization Effectiveness
| Component | Unoptimized | Optimized | Savings |
|-----------|-----------|-----------|---------|
| Prometheus | 500 GB/day | 50 GB/day | 90% |
| Logs | 1000 GB/day | 100 GB/day | 90% |
| Traces | 50 GB/day | 5 GB/day | 90% |
| Total Cost | $50K/day | $5K/day | 90% |

## What Broke
- High-cardinality customer_id metrics dropped (reduced debugging ability)
- Archive job delayed (not critical during surge)

## What Worked
- Trace sampling strategy caught all errors + slow requests
- Log sampling maintained visibility on failures
- Alerting remained effective (thresholds still hit)

## Next Year Improvements
- Add real-time cardinality monitoring
- Pre-allocate storage for known surge events
```

---

## 11. Interview Questions (Extended)

### Competency Level 1: Foundational Understanding

**Q1.1: Explain the difference between metrics and logs with a production example.**

*Expected Answer*:
- Metrics: Aggregated numeric values (CPU usage, request rate)
- Logs: Individual events with full context (error messages, user actions)
- Example: "Metrics show 'error rate 5%', logs show 'which specific requests failed and why'"
- Wrong answer: "Metrics are numbers, logs are text" (too simplistic)

**Q1.2: What is cardinality, and why does it matter in Prometheus?**

*Expected Answer*:
- Cardinality: Number of unique label value combinations
- High cardinality (e.g., user_id label): Millions of unique values
- Problem: One metric with high-cardinality labels = millions of time series = memory explosion
- Good answer includes: User ID should go in logs/traces, not metrics
- Wrong answer: "Cardinality is the number of metrics" (confuses dimensions with cardinality)

**Q1.3: Describe the three pillars of observability and when you'd use each.**

*Expected Answer*:
- **Metrics**: Trending, capacity planning, SLO tracking (aggregated view)
- **Logs**: Debugging, error investigation (detailed context)
- **Traces**: Request flow, latency breakdown, dependency discovery (causal relationships)
- Example: "Website slow → check metrics (p95), drill into logs (which service?), check traces (which hop slow?)"

---

### Competency Level 2: Architectural Understanding

**Q2.1: Design an observability stack for a microservices platform with 50 services, 1000 RPS.**

*Expected Answer Structure*:
```
Metrics: Prometheus + Grafana
├─ Scrape every 15s
├─ 2-week local retention
├─ Thanos for long-term storage (S3)

Logs: Loki
├─ 7-day retention (cost optimization)
├─ Only low-cardinality labels (service, environment)
├─ High-cardinality in log fields (user_id, request_id)

Traces: Jaeger + Elasticsearch
├─ 10% sampling (1000 RPS × 10% = 100 spans/sec)
├─ 100% sampling for errors (catch issues)
├─ 48-hour retention (high cost)
├─ Tempo for cheaper long-term retention

Correlation: All use trace_id (W3C traceparent)
```

Evaluation:
- ✅ Mentions sampling for traces (shows cost awareness)
- ✅ Differentiates log cardinality strategy
- ✅ Includes retention policies
- ❌ No mention of cost optimization = miss
- ❌ Uses high-cardinality labels in Prometheus = scalability risk

**Q2.2: Your Prometheus instance is consuming 100 GB of memory. How would you diagnose and fix?**

*Expected Answer*:
1. **Diagnose**:
   - Query `prometheus_tsdb_symbol_table_size_bytes` (index size)
   - Query `count by (__name__) (count by (__name__, job, instance, labels) ({__name__=~".+"}))` for cardinality per metric
   - Check WAL size: `prometheus_tsdb_wal_segment_bytes`

2. **Root Cause** (usually high cardinality):
   - Metric with unbounded label (user_id, request_id)
   - Service discovery adding too many targets

3. **Fix**:
   ```yaml
   metric_relabel_configs:
     - source_labels: [user_id]
       regex: '.*'
       action: drop  # Remove high-cardinality label
     
     - source_labels: [path]
       regex: '/api/users/[0-9]+'
       replacement: '/api/users/*'
       target_label: path  # Reduce cardinality
   ```

4. **Monitor**: Add alert `prometheus_tsdb_symbol_table_size_bytes > 50e9`

Evaluation:
- ✅ Methodical diagnosis approach
- ✅ Identifies cardinality as root cause
- ✅ Provides concrete fix (metric_relabel_configs)
- ❌ Doesn't mention restarting Prometheus (new cardinality limits take effect on restart)

---

### Competency Level 3: Production Troubleshooting

**Q3.1: Your SLO dashboard shows 99.5% uptime, breaching the 99.9% SLO. The error rate alert didn't fire. How do you investigate?**

*Expected Answer*:
1. **Why alert didn't fire**:
   - Alert threshold: `error_rate > 5%` (alert not sensitive enough)
   - Reality: Steady 0.5% error rate × 10 hours = SLO breach
   - Alert only catches spikes, misses gradual degradation

2. **Diagnosis**:
   ```promql
   # Check error rate over time
   rate(http_requests_total{status=~"5.."}[1h]) / rate(http_requests_total[1h])
   
   # Result: Baseline 0.1% → 0.5% (5x increase, under alert threshold)
   ```

3. **Root Cause**:
   - Gradual increase suggests: Resource leak, database performance degradation
   - Check: Memory growth, database connections, cache hit rate

4. **Fix**:
   - Improve alert: Use anomaly detection instead of fixed threshold
   - Example: Alert if error rate > (baseline * 2)

Evaluation:
- ✅ Understands SLO vs. alerting mismatch
- ✅ Methodical troubleshooting approach
- ✅ Suggests architectural fix (anomaly detection)
- ❌ Doesn't mention on-call communication (customer impact)

**Q3.2: You deployed a change that increased metric cardinality 100x. Prometheus is melting. You have 5 minutes to fix.**

*Expected Answer*:
1. **Immediate action** (Next 2 minutes):
   ```yaml
   # Add to prometheus.yml and reload
   metric_relabel_configs:
     - source_labels: [new_high_cardinality_label]
       action: drop  # Drop the problematic metric entirely
   
   # OR
   - source_labels: [high_cardinality]
       regex: 'value_[0-9]+'
       replacement: 'value_*'
       target_label: high_cardinality
   ```
   
   Reload: `curl -X POST http://prometheus:9090/-/reload`

2. **Medium-term** (Next 10 minutes):
   - Emergency rollback of the change
   - Review: Which service/metric added the label?
   - Fix code to use low-cardinality labels

3. **Long-term**:
   - Add CI/CD gate: Check metric cardinality before merging
   - Alert: `prometheus_tsdb_symbol_table_size_bytes > 30GB`

Evaluation:
- ✅ Immediate mitigation (metric_relabel_configs)
- ✅ Reload Prometheus (not restart = 0 downtime)
- ✅ Long-term prevention (CI/CD gate)
- ❌ Doesn't mention monitoring the fix (is it working?)

**Q3.3: A vendor push to production overwrote your Grafana dashboard. How do you recover?**

*Expected Answer*:
1. **Recovery (immediate)**:
   ```bash
   # Grafana has revision history
   # Navigate to: Dashboard Settings → Revision History
   
   # OR via API:
   curl -s 'http://grafana:3000/api/dashboards/uid/xyz/revisions' | jq '.[]'
   
   # Restore previous version:
   curl -X POST 'http://grafana:3000/api/dashboards/uid/xyz/restore' \
     -d '{"version": 5}'
   ```

2. **Prevention**:
   - Store dashboards in git (as JSON)
   - Use Grafana Provisioning (from YAML)
   - CI/CD pipeline validates dashboard changes
   - RBAC: Restrict who can edit production dashboards

3. **For future**:
   ```yaml
   # grafana-provisioning.yml
   dashboards:
     - provider: file
       name: 'prod-dashboards'
       type: file
       options:
         path: /etc/grafana/dashboards
         updateIntervalSeconds: 60
   
   # Dashboards auto-deployed from git
   ```

Evaluation:
- ✅ Knows revision history exists
- ✅ Provides recovery procedure
- ✅ Suggests infrastructure-as-code approach
- ❌ Doesn't mention notification of change (what if no revision history?)
- ⚠️ RBAC-based prevention is good but may be too restrictive

---

### Competency Level 4: Advanced Optimization and Edge Cases

**Q4.1: Design a cost-optimized observability strategy for a startup that will grow to 100+ services.**

*Expected Answer Structure*:

**Phase 1 (Current: 5 services, 100 RPS)**
```
- Prometheus (local, 7-day retention)
- Grafana (dashboards)
- ELK Stack (logs)
- Cost: $300/month on t3.medium instances
```

**Phase 2 (12 months: 20 services, 500 RPS)**
```
- Prometheus + Thanos (add long-term retention to S3)
- Loki (replace ELK, cost: 90% lower)
- Jaeger + Elasticsearch (add traces, 5% sampling)
- Cost: $800/month
- Action: Multi-cluster observability (align with expansion)
```

**Phase 3 (24 months: 100 services, 5000 RPS)**
```
- Prometheus + Cortex (managed multi-tenant)
- Loki (distributed, multi-tenant)
- Tempo (replace Jaeger, cost: 10x lower for same retention)
- Cost: Evaluate cloud managed vs. on-prem

Decision tree:
- Total RPS < 2000: On-premise (cheaper)
- Total RPS > 2000: Evaluate managed cloud
- Data governance requirements: On-premise
- Team size < 3: Managed cloud (less ops burden)
```

Evaluation:
- ✅ Phased approach (avoid over-engineering)
- ✅ Cost tracking and optimization
- ✅ Scaling decision tree based on concrete metrics
- ✅ Considers team size/ops burden
- ❌ Doesn't mention data retention compliance (GDPR, SOX)

**Q4.2: How would you implement intelligent sampling that adapts to traffic patterns?**

*Expected Answer*:
```python
# Scenario: 1000 RPS app, budget = 100 spans/sec stored

class AdaptiveSampler:
    def __init__(self, target_storage_budget=100):
        self.stored_spans = 0
        self.target_budget = target_storage_budget
        self.error_rate = 0.01  # 1% baseline
    
    def should_sample(self, span_context):
        # Always sample errors
        if span_context.has_error:
            return True  # 100% of errors (usually 1-2% of traffic)
        
        # Dynamically sample success based on error rate
        # If error rate 5%, allocate 5 spans to errors, 95 to success
        budget_for_success = (1 - self.error_rate) * self.target_budget
        success_sampling_rate = budget_for_success / (1000 * 0.99)
        
        return random() < success_sampling_rate
```

Evaluation:
- ✅ Understands sampling constraints
- ✅ Prioritizes errors (catches problems)
- ✅ Dynamically adapts to error rate changes
- ⚠️ Doesn't mention integration with OpenTelemetry SDK
- ❌ Doesn't address sampling decision communication (propagate in headers)

**Q4.3: Your organization collects 100TB of observability data/year costing $100K. The board wants a 50% cost reduction. Options?**

*Expected Answer*:
```
Option Analysis:

1. Reduce Data Collection (25% savings)
   - High-volume INFO logs → sampling (1/100)
   - Metrics cardinality reduction (drop low-value metrics)
   - Trace sampling from 10% → 5% (better sampling strategy, not across-the-board)
   - Estimated impact: $100K → $80K

2. Optimize Storage Format (30% savings)
   - Prometheus: Already compressed well
   - Logs: Move to Loki (indexes only labels)
   - Traces: Parquet format to S3 (vs. Elasticsearch)
   - Estimated impact: $100K → $70K

3. Tiered Retention (40% savings)
   - Hot (7 days): Full resolution (frequent queries)
   - Warm (30 days): Aggregated data (weekly reports)
   - Cold (1 year+): Archived to Glacier (compliance only)
   - Estimated impact: $100K → $60K

4. Combination Approach (50% savings)
   - Implement all three above
   - Expected: $100K → $50K
   - Trade-off: Slightly worse debugging for cold period
```

**Recommendation**: Go with combination, but maintain 50% sampling on errors (don't lose visibility).

Evaluation:
- ✅ Systematic approach (identifies multiple levers)
- ✅ Understands storage tiers
- ✅ Quantifies trade-offs
- ⚠️ Doesn't mention communicating change to on-call team
- ❌ Doesn't address customer/SLA impact of reduced traceability

---

### Competency Level 5: Strategic and Enterprise-Scale

**Q5.1: Your organization is deciding between DataDog, New Relic, and maintaining open-source Prometheus + Grafana. Make a recommendation and justify.**

*Expected Answer Framework*:

| Factor | Weight | Open-Source | DataDog | New Relic |
|--------|--------|-------------|---------|-----------|
| Cost @ 10K RPS | 30% | 3/5 | 1/5 | 2/5 |
| Setup effort | 20% | 2/5 | 5/5 | 5/5 |
| Data retention | 15% | 4/5 (Thanos) | 5/5 | 5/5 |
| Team expertise | 20% | 3/5 (existing) | 4/5 | 4/5 |
| Vendor lock-in | 15% | 5/5 | 1/5 | 1/5 |
| **Score** | | **3.3** | **2.7** | **3.1** |

**Recommendation**: Open-source if team can stomach ops; DataDog if budget allows and data retention critical.

Evaluation:
- ✅ Uses weighted scorecard (shows maturity)
- ✅ Considers total cost of ownership (not just licensing)
- ✅ Accounts for team constraints
- ⚠️ Should mention data residency/compliance
- ❌ Doesn't discuss hybrid approach (Prometheus + managed Grafana)

**Q5.2: Your observability system is storing 100 TB of trace data annually at $1000/month. How would you optimize?**

*Expected Answer*:
1. **Sampling Review**:
   - Current: 10% of all requests
   - Proposed: Error 100%, latency tail 10%, success 0.5%
   - Estimated reduction: 70% (6x cost savings)

2. **Retention Optimization**:
   - Traces: 7 days hot (frequent queries) → S3 Glacier
   - Aggregated traces: 1 year warm (monthly reviews)
   - Cost: 90% reduction for 1-year retention

3. **Storage Format**:
   - Current: Elasticsearch (expensive indexing)
   - Proposed: Parquet to S3 (query with Athena)
   - Cost: 95% reduction for historical analysis

4. **Result**: $1000 → $200/month (80% savings while retaining compliance)

Evaluation:
- ✅ Multi-layered optimization strategy
- ✅ Cost-benefit analysis
- ✅ Long-term compliance considerations
- ❌ Doesn't mention business impact (slower queries for historical analysis)

**Q5.3: Design observability compliance for GDPR/SOX with 10+ clusters across 3 continents.**

*Expected Answer*:
```
Requirement: Data residency, audit trails, retention policies

Architecture:
  US Data Centers
  ├─ Prometheus: Metrics (non-PII, legal to cross-border)
  ├─ Logs: Redacted, PII removed before egress
  └─ Traces: Context-only (IDs, not personal data)
  
  EU Data Centers
  ├─ Duplicate Prometheus (different retention policy: 3 years)
  ├─ Logs: Encrypted at rest, EU-only storage
  └─ Traces: EU-retained for disputes

Implementation:
  1. Tag all data with origin region+cluster
  2. Query routing: EU logs → EU cluster
  3. Encryption: AES-256 at rest, TLS in transit
  4. Audit: Log every query, every export
  5. Retention: Automated deletion per schedule
```

Evaluation:
- ✅ Understands data residency requirements
- ✅ Addresses encryption and audit trails
- ✅ Multi-cluster complexity acknowledgment
- ⚠️ Doesn't mention consent management
- ❌ No mention of incident response procedures (data breaches)

---

## Summary: Expected Competency by Level

| Level | Years Experience | Focus | Key Tests |
|-------|------------------|-------|-----------|
| 1 | 0-2 | Foundational concepts | Terminology, definitions |
| 2 | 2-5 | Architecture design | Stack selection, tradeoffs |
| 3 | 5-8 | Production troubleshooting | Incident response, root cause |
| 4 | 8-10 | Advanced optimization | Sampling, cost reduction |
| 5 | 10+ | Strategic decisions | Tooling evaluation, long-term planning |

---

**Document Version**: 4.0  
**Last Updated**: March 11, 2026  
**Target Audience**: DevOps Engineers with 5-10+ years experience  
**Prerequisites**: Knowledge of distributed systems, Kubernetes, Docker  
**Total Content**: 5200+ lines with 5 hands-on scenarios and 20+ interview questions  
**Topics Covered**: All major observability tools, patterns, and production strategies

### Competency Level 1: Foundational Understanding

**Q1.1: Explain the difference between metrics and logs with a production example.**

*Expected Answer*:
- Metrics: Aggregated numeric values (CPU usage, request rate)
- Logs: Individual events with full context (error messages, user actions)
- Example: "Metrics show 'error rate 5%', logs show 'which specific requests failed and why'"
- Wrong answer: "Metrics are numbers, logs are text" (too simplistic)

**Q1.2: What is cardinality, and why does it matter in Prometheus?**

*Expected Answer*:
- Cardinality: Number of unique label value combinations
- High cardinality (e.g., user_id label): Millions of unique values
- Problem: One metric with high-cardinality labels = millions of time series = memory explosion
- Good answer includes: User ID should go in logs/traces, not metrics
- Wrong answer: "Cardinality is the number of metrics" (confuses dimensions with cardinality)

**Q1.3: Describe the three pillars of observability and when you'd use each.**

*Expected Answer*:
- **Metrics**: Trending, capacity planning, SLO tracking (aggregated view)
- **Logs**: Debugging, error investigation (detailed context)
- **Traces**: Request flow, latency breakdown, dependency discovery (causal relationships)
- Example: "Website slow → check metrics (p95), drill into logs (which service?), check traces (which hop slow?)"

---

### Competency Level 2: Architectural Understanding

**Q2.1: Design an observability stack for a microservices platform with 50 services, 1000 RPS.**

*Expected Answer Structure*:
```
Metrics: Prometheus + Grafana
├─ Scrape every 15s
├─ 2-week local retention
├─ Thanos for long-term storage (S3)

Logs: Loki
├─ 7-day retention (cost optimization)
├─ Only low-cardinality labels (service, environment)
├─ High-cardinality in log fields (user_id, request_id)

Traces: Jaeger + Elasticsearch
├─ 10% sampling (1000 RPS × 10% = 100 spans/sec)
├─ 100% sampling for errors (catch issues)
├─ 48-hour retention (high cost)
├─ Tempo for cheaper long-term retention

Correlation: All use trace_id (W3C traceparent)
```

Evaluation:
- ✅ Mentions sampling for traces (shows cost awareness)
- ✅ Differentiates log cardinality strategy
- ✅ Includes retention policies
- ❌ No mention of cost optimization = miss
- ❌ Uses high-cardinality labels in Prometheus = scalability risk

**Q2.2: Your Prometheus instance is consuming 100 GB of memory. How would you diagnose and fix?**

*Expected Answer*:
1. **Diagnose**:
   - Query `prometheus_tsdb_symbol_table_size_bytes` (index size)
   - Query `count by (__name__) (count by (__name__, job, instance, labels) ({__name__=~".+"}))` for cardinality per metric
   - Check WAL size: `prometheus_tsdb_wal_segment_bytes`

2. **Root Cause** (usually high cardinality):
   - Metric with unbounded label (user_id, request_id)
   - Service discovery adding too many targets

3. **Fix**:
   ```yaml
   metric_relabel_configs:
     - source_labels: [user_id]
       regex: '.*'
       action: drop  # Remove high-cardinality label
     
     - source_labels: [path]
       regex: '/api/users/[0-9]+'
       replacement: '/api/users/*'
       target_label: path  # Reduce cardinality
   ```

4. **Monitor**: Add alert `prometheus_tsdb_symbol_table_size_bytes > 50e9`

Evaluation:
- ✅ Methodical diagnosis approach
- ✅ Identifies cardinality as root cause
- ✅ Provides concrete fix (metric_relabel_configs)
- ❌ Doesn't mention restarting Prometheus (new cardinality limits take effect on restart)

---

### Competency Level 3: Production Troubleshooting

**Q3.1: Your SLO dashboard shows 99.5% uptime, breaching the 99.9% SLO. The error rate alert didn't fire. How do you investigate?**

*Expected Answer*:
1. **Why alert didn't fire**:
   - Alert threshold: `error_rate > 5%` (alert not sensitive enough)
   - Reality: Steady 0.5% error rate × 10 hours = SLO breach
   - Alert only catches spikes, misses gradual degradation

2. **Diagnosis**:
   ```promql
   # Check error rate over time
   rate(http_requests_total{status=~"5.."}[1h]) / rate(http_requests_total[1h])
   
   # Result: Baseline 0.1% → 0.5% (5x increase, under alert threshold)
   ```

3. **Root Cause**:
   - Gradual increase suggests: Resource leak, database performance degradation
   - Check: Memory growth, database connections, cache hit rate

4. **Fix**:
   - Improve alert: Use anomaly detection instead of fixed threshold
   - Example: Alert if error rate > (baseline * 2)

Evaluation:
- ✅ Understands SLO vs. alerting mismatch
- ✅ Methodical troubleshooting approach
- ✅ Suggests architectural fix (anomaly detection)
- ❌ Doesn't mention on-call communication (customer impact)

**Q3.2: You deployed a change that increased metric cardinality 100x. Prometheus is melting. You have 5 minutes to fix.**

*Expected Answer*:
1. **Immediate action** (Next 2 minutes):
   ```yaml
   # Add to prometheus.yml and reload
   metric_relabel_configs:
     - source_labels: [new_high_cardinality_label]
       action: drop  # Drop the problematic metric entirely
   
   # OR
   - source_labels: [high_cardinality]
     regex: 'value_[0-9]+'
     replacement: 'value_*'
     target_label: high_cardinality
   ```
   
   Reload: `curl -X POST http://prometheus:9090/-/reload`

2. **Medium-term** (Next 10 minutes):
   - Emergency rollback of the change
   - Review: Which service/metric added the label?
   - Fix code to use low-cardinality labels

3. **Long-term**:
   - Add CI/CD gate: Check metric cardinality before merging
   - Alert: `prometheus_tsdb_symbol_table_size_bytes > 30GB`

Evaluation:
- ✅ Immediate mitigation (metric_relabel_configs)
- ✅ Reload Prometheus (not restart = 0 downtime)
- ✅ Long-term prevention (CI/CD gate)
- ❌ Doesn't mention monitoring the fix (is it working?)

---

### Competency Level 4: Advanced Architecture

**Q4.1: Design a cost-optimized observability strategy for a startup that will grow to 100+ services.**

*Expected Answer Structure*:

**Phase 1 (Current: 5 services, 100 RPS)**
```
- Prometheus (local, 7-day retention)
- Grafana (dashboards)
- ELK Stack (logs)
- Cost: $300/month on t3.medium instances
```

**Phase 2 (12 months: 20 services, 500 RPS)**
```
- Prometheus + Thanos (add long-term retention to S3)
- Loki (replace ELK, cost: 90% lower)
- Jaeger + Elasticsearch (add traces, 5% sampling)
- Cost: $800/month
- Action: Multi-cluster observability (align with expansion)
```

**Phase 3 (24 months: 100 services, 5000 RPS)**
```
- Prometheus + Cortex (managed multi-tenant)
- Loki (distributed, multi-tenant)
- Tempo (replace Jaeger, cost: 10x lower for same retention)
- Cost: Evaluate cloud managed vs. on-prem

Decision tree:
- Total RPS < 2000: On-premise (cheaper)
- Total RPS > 2000: Evaluate managed cloud
- Data governance requirements: On-premise
- Team size < 3: Managed cloud (less ops burden)
```

Evaluation:
- ✅ Phased approach (avoid over-engineering)
- ✅ Cost tracking and optimization
- ✅ Scaling decision tree based on concrete metrics
- ✅ Considers team size/ops burden
- ❌ Doesn't mention data retention compliance (GDPR, SOX)

**Q4.2: How would you implement intelligent sampling that adapts to traffic patterns?**

*Expected Answer*:
```python
# Scenario: 1000 RPS app, budget = 100 spans/sec stored

class AdaptiveSampler:
    def __init__(self, target_storage_budget=100):
        self.stored_spans = 0
        self.target_budget = target_storage_budget
        self.error_rate = 0.01  # 1% baseline
    
    def should_sample(self, span_context):
        # Always sample errors
        if span_context.has_error:
            return True  # 100% of errors (usually 1-2% of traffic)
        
        # Dynamically sample success based on error rate
        # If error rate 5%, allocate 5 spans to errors, 95 to success
        budget_for_success = (1 - self.error_rate) * self.target_budget
        success_sampling_rate = budget_for_success / (1000 * 0.99)
        
        return random() < success_sampling_rate
```

Evaluation:
- ✅ Understands sampling constraints
- ✅ Prioritizes errors (catches problems)
- ✅ Dynamically adapts to error rate changes
- ⚠️ Doesn't mention integration with OpenTelemetry SDK
- ❌ Doesn't address sampling decision communication (propagate in headers)

---

### Competency Level 5: Strategic Thinking

**Q5.1: Your organization is deciding between DataDog, New Relic, and maintaining open-source Prometheus + Grafana. Make a recommendation and justify.**

*Expected Answer Framework*:

| Factor | Weight | Open-Source | DataDog | New Relic |
|--------|--------|-------------|---------|-----------|
| Cost @ 10K RPS | 30% | 3/5 | 1/5 | 2/5 |
| Setup effort | 20% | 2/5 | 5/5 | 5/5 |
| Data retention | 15% | 4/5 (Thanos) | 5/5 | 5/5 |
| Team expertise | 20% | 3/5 (existing) | 4/5 | 4/5 |
| Vendor lock-in | 15% | 5/5 | 1/5 | 1/5 |
| **Score** | | **3.3** | **2.7** | **3.1** |

**Recommendation**: Open-source if team can stomach ops; DataDog if budget allows and data retention critical.

Evaluation:
- ✅ Uses weighted scorecard (shows maturity)
- ✅ Considers total cost of ownership (not just licensing)
- ✅ Accounts for team constraints
- ⚠️ Should mention data residency/compliance
- ❌ Doesn't discuss hybrid approach (Prometheus + managed Grafana)

**Q5.2: Your observability system is storing 100 TB of trace data annually at $1000/month. How would you optimize?**

*Expected Answer*:
1. **Sampling Review**:
   - Current: 10% of all requests
   - Proposed: Error 100%, latency tail 10%, success 0.5%
   - Estimated reduction: 70% (6x cost savings)

2. **Retention Optimization**:
   - Traces: 7 days hot (frequent queries) → S3 Glacier
   - Aggregated traces: 1 year warm (monthly reviews)
   - Cost: 90% reduction for 1-year retention

3. **Storage Format**:
   - Current: Elasticsearch (expensive indexing)
   - Proposed: Parquet to S3 (query with Athena)
   - Cost: 95% reduction for historical analysis

4. **Result**: $1000 → $200/month (80% savings while retaining compliance)

Evaluation:
- ✅ Multi-layered optimization strategy
- ✅ Cost-benefit analysis
- ✅ Long-term compliance considerations
- ❌ Doesn't mention business impact (slower queries for historical analysis)

---

## Summary: Expected Competency by Level

| Level | Years Experience | Focus | Key Tests |
|-------|------------------|-------|-----------|
| 1 | 0-2 | Foundational concepts | Terminology, definitions |
| 2 | 2-5 | Architecture design | Stack selection, tradeoffs |
| 3 | 5-8 | Production troubleshooting | Incident response, root cause |
| 4 | 8-10 | Advanced optimization | Sampling, cost reduction |
| 5 | 10+ | Strategic decisions | Tooling evaluation, long-term planning |

---

**Document Version**: 3.0  
**Last Updated**: March 11, 2026  
**Target Audience**: DevOps Engineers with 5-10+ years experience  
**Prerequisites**: Knowledge of distributed systems, Kubernetes, Docker  
**Total Content**: 4000+ lines with hands-on scenarios and interview prep
