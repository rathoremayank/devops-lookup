# AWS Load Balancing Services: Senior DevOps Study Guide

**Last Updated:** March 7, 2026  
**Audience:** DevOps Engineers with 5–10+ years of Experience  
**Level:** Advanced / Senior

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [ALB vs NLB vs CLB vs Gateway Load Balancer](#alb-vs-nlb-vs-clb-vs-gateway-load-balancer)
4. [Target Groups & Health Checks](#target-groups--health-checks)
5. [Sticky Sessions & Load Balancing Algorithms](#sticky-sessions--load-balancing-algorithms)
6. [SSL Termination & Certificate Management](#ssl-termination--certificate-management)
7. [Cross-Region Load Balancing & Global Accelerator](#cross-region-load-balancing--global-accelerator)
8. [Monitoring & Troubleshooting Load Balancers](#monitoring--troubleshooting-load-balancers)
9. [Hands-on Scenarios](#hands-on-scenarios)
10. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Load balancers are critical infrastructure components that distribute incoming application traffic across multiple targets (EC2 instances, containers, on-premises servers, or Lambda functions) to ensure no single endpoint becomes a bottleneck. AWS provides four primary load balancing services, each optimized for different use cases and layers of the OSI model.

This guide explores enterprise-grade load balancing architectures, from basic distribution mechanisms to advanced patterns like cross-region failover, real-time monitoring, and certificate lifecycle management.

### Why It Matters in Modern DevOps Platforms

**High Availability & Fault Tolerance:**
- Load balancers enable zero-downtime deployments and graceful instance termination
- Automatic failover mechanisms detect and remove unhealthy targets
- Multi-AZ deployments provide resilience against zone-level failures

**Performance Optimization:**
- Connection pooling, HTTP keep-alive, and algorithmic distribution reduce latency
- NLB handles millions of requests per second for ultra-high-throughput applications
- ALB provides advanced routing (path-based, hostname-based, header-based) for microservices

**Cost Efficiency:**
- Efficient traffic distribution prevents over-provisioning
- Auto-scaling groups coupled with load balancers reduce idle capacity
- Pay-per-LCU (Load Balancer Capacity Unit) billing aligns costs with actual usage

**Security & Compliance:**
- SSL/TLS termination offloads encryption overhead from application servers
- WAF integration provides DDoS and application-layer attack protection
- VPC endpoints and PrivateLink enable private cross-account connectivity

**Operational Visibility:**
- CloudWatch metrics, access logs, and request tracing provide deep insights
- Health check status enables proactive remediation
- Integration with AWS services (Auto Scaling, ECS, Lambda) enables infrastructure-as-code patterns

### Real-World Production Use Cases

1. **Microservices on ECS/EKS:**
   - ALB with multiple target groups routing `/api/users` to user-service, `/api/products` to product-service
   - Advanced routing rules based on HTTP headers (tenant isolation) or query parameters

2. **Ultra-Low Latency Trading Platforms:**
   - NLB preserving 5-tuple hashing for connection persistence across financial institutions
   - UDP load balancing for custom protocols (not possible with ALB)

3. **Database Proxy Patterns:**
   - NLB in front of database clusters (MySQL, PostgreSQL read replicas)
   - Connection reuse via sticky sessions preventing connection pool exhaustion

4. **IoT & Real-Time Applications:**
   - NLB handling millions of MQTT connections from IoT devices
   - Preserve connection state across rebalancing events

5. **Global SaaS Applications:**
   - Global Accelerator directing traffic to nearest region based on geographic proximity
   - Cross-region failover for disaster recovery scenarios

6. **Mixed Protocol Environments:**
   - Gateway Load Balancer for packet inspection and network appliance chains
   - Transparent proxy patterns for security analysis

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Internet / End Users                                       │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────▼──────────┐
        │ AWS Global          │
        │ Accelerator         │ (Geographic routing)
        └──────────┬──────────┘
                   │
        ┌──────────▼───────────────────────────────┐
        │     Internet Gateway / Route 53          │
        │  (DNS resolution & geolocation)          │
        └────────────┬─────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  Elastic Load Balancer  │
        │  (ALB/NLB/CLB/GLB)      │
        └────────┬────────────────┘
                 │
        ┌────────▼─────────────────────────────┐
        │   Target Groups                     │
        │  ┌───────────┐  ┌───────────┐      │
        │  │ EC2 / ECS │  │  Lambda   │      │
        │  │ Container │  │ Functions │      │
        │  │ Instances │  │           │      │
        │  └───────────┘  └───────────┘      │
        └─────────────────────────────────────┘
```

---

## Foundational Concepts

### 1. OSI Layer Context

Understanding load balancing requires clarity on the layer at which each balancer operates:

| Layer | Name | Protocol | Balancer | Examples |
|-------|------|----------|----------|----------|
| 4 | Transport | TCP/UDP | NLB | Raw TCP connections, UDP protocols, QUIC |
| 7 | Application | HTTP/HTTPS | ALB | URL routing, hostname routing, header inspection |
| 3/4 | Network | IP/TCP | GLB | Packet inspection, packet modification, DDoS filtering |
| 2 | Data Link | Ethernet | CLB (Legacy) | Basic TCP balancing; deprecated |

**Key Insight:** Layer 7 (ALB) has access to HTTP content and can make routing decisions based on request paths, but this depth requires more CPU. Layer 4 (NLB) operates on raw TCP/UDP and is extremely fast but context-unaware.

### 2. Load Distribution: Connection vs. Request

**Connection-Level Balancing (NLB, CLB):**
- All packets from a single client IP are routed to one target
- Ideal for stateful protocols (non-HTTP, raw TCP)
- Example: A long-lived WebSocket connection remains with one backend server

**Request-Level Balancing (ALB):**
- Each HTTP request can be routed to different targets
- HTTP keep-alive means multiple requests over one connection may hit different backends
- Ideal for stateless, HTTP-based microservices

**Implication:** A performance-critical application that reuses connections may have uneven load distribution on ALB if some requests are heavier than others. NLB would distribute by connection count.

### 3. Health Check Architecture

Load balancers continuously verify target health to prevent routing traffic to failed instances.

**Two-Tier Health Check Model:**

```
┌──────────────────┐
│  Load Balancer   │
├──────────────────┤
│  Registered      │
│  Targets         │
└──────────────────┘
         ↓ (Active Health Checks)
┌──────────────────┐
│  Target Group    │
│  Health Status   │
│  (Healthy/      │
│   Unhealthy)    │
└──────────────────┘
         ↓
┌──────────────────┐
│  Auto Scaling    │
│  Group (optional)│
│  Termination     │
│  of Unhealthy    │
│  Instances       │
└──────────────────┘
```

**Health Check Protocol Options:**
- **HTTP/HTTPS:** Application-level handshake; returns HTTP status codes
- **TCP:** Network-level; measures if port is accepting connections (no application validation)
- **gRPC:** Validates gRPC health check protocol (RFC)

**Critical Parameters:**
- **Interval:** 30s (default) — balance between responsiveness and overhead
- **Timeout:** 5s (default) — time to wait for response before marking as failed
- **Healthy Threshold:** 2 (default) — consecutive successful checks before marking healthy
- **Unhealthy Threshold:** 2 (default) — consecutive failed checks before marking unhealthy

### 4. Target Registration Model

Targets are registered with **Target Groups**, not directly with Load Balancers.

**Benefits of Target Group Abstraction:**
1. **Flexibility:** Reuse same target group across multiple ALBs for canary deployments
2. **Decoupling:** Auto Scaling Groups manage target lifecycle; load balancer references the group
3. **A/B Testing:** Route subset of traffic to new target group running canary version

### 5. Stickiness & Session Affinity

**HTTP Cookie-Based Stickiness (ALB):**
- Load balancer generates `AWSALB` cookie, binding client to target for duration
- Survives instance restart (bound to target IP/port, not instance identity)
- Useful for applications with in-memory sessions (legacy systems)

**Source IP-Based Stickiness (NLB):**
- All traffic from same source IP goes to same target (permanent mapping)
- Derived from TCP 5-tuple (protocol, source IP, source port, dest IP, dest port)
- Cannot be overridden; inherent to NLB architecture

**Modern DevOps Perspective:**
- Sticky sessions are a code smell in microservices architectures
- Better approach: Distributed session stores (ElastiCache, DynamoDB)
- Sticky sessions limit auto-scaling benefits and create single-target hotspots

### 6. Connection Draining & Deregistration Delay

When deregistering a target (instance shutdown), the load balancer enters **deregistration delay** (default 300s).

**Lifecycle:**

```
1. Deregistration Initiated
   ↓
2. No NEW connections accepted
   ↓
3. Existing connections allowed to complete
   ↓
4. After timeout period → Force close remaining connections
   ↓
5. Target fully removed from load balancer
```

**Critical Decision:** If your request timeout is 60s, set deregistration delay to at least 90–120s to allow graceful drains.

### 7. Load Balancing Algorithms (NLB/ALB)

**Round Robin:**
- Distributes requests sequentially: Target 1 → Target 2 → Target 3 → Target 1
- Often uneven due to varying response times; not suitable for interactive applications

**Least Outstanding Requests:**
- Directs request to target with fewest in-flight requests
- Adapts dynamically if one backend is slower
- ALB defaults to this under HTTP/HTTPS

**Flow Hash (5-Tuple):**
- NLB uses hash of (protocol, source IP, source port, dest IP, dest port)
- Deterministic; same client always routes to same target
- Excellent for stateful protocols

### 8. Capacity Units & Billing

**Load Balancer Capacity Unit (LCU):**

ALB/NLB charge based on:
- **New Connections:** Per minute
- **Active Connections:** Per minute
- **Processed Bytes:** GB per hour
- **Rule Evaluations (ALB only):** Per second per rule

`LCU = maximum(connections, requests, bytes processed, rule evals) / threshold`

**DevOps Implication:** Connections from persistent clients (keep-alive) cost less than short-lived connections (new TCP 3-way handshake overhead).

### 9. Multi-AZ Architecture

Load balancers are inherently multi-AZ:

- **Subnets:** Deploy load balancer in subnets across ≥2 AZs
- **Node Distribution:** AWS provisions load balancer nodes in each AZ
- **Health Check Propagation:** If one AZ's node becomes unhealthy, traffic rebalances to other AZs

**Anti-Pattern:** Registering targets in only one AZ defeats multi-AZ benefits.

### 10. Security Considerations

**At Rest (Network):**
- All traffic inside VPC; not exposed to internet unless explicitly configured
- Security groups control ingress/egress

**In Transit:**
- HTTP: Unencrypted; avoid for sensitive data
- HTTPS: TLS 1.2+ recommended; certifications managed by ACM
- Mutual TLS (mTLS): Verify client certificates (advanced use case)

**Best Practice:**
- ALB enforces HTTPS within corporate VPC via security group rules
- Public-facing ALBs redirect HTTP → HTTPS
- NLB preserves raw TLS negotiations; ideal for custom TLS implementations

---

## Key Terminology Reference

| Term | Definition | Context |
|------|-----------|---------|
| **Target** | EC2, ECS, Lambda, on-premises server receiving traffic | Endpoint |
| **Target Group** | Logical group of targets with shared health check & routing config | Routing Rule |
| **Listener** | Port + protocol combo on load balancer (e.g., TCP:443) | Ingress Point |
| **Listener Rule** | Conditions (path, hostname, header) routing to target groups | Routing Logic |
| **Deregistration Delay** | Connection draining timeout (default 300s) | Graceful Shutdown |
| **Health Check** | Periodic validation of target availability | Availability |
| **LCU** | Load Balancer Capacity Unit billing metric | Cost |
| **Stickiness** | Session persistence mechanism | Affinity |
| **Cross-Zone Load Balancing** | Traffic distribution across AZs | High Availability |

---

## Architecture Principles for Senior Engineers

### 1. Defense in Depth

```
┌──────────────────────────────────────┐
│ Internet Gateway / Route 53           │
│ (Geo-routing, DDoS scattering)       │
└────────────┬─────────────────────────┘
             │
┌────────────▼──────────────────┐
│ WAF (Application Protection)   │
│ (OWASP Top 10 blocking)        │
└────────────┬──────────────────┘
             │
┌────────────▼─────────────────────────┐
│ Load Balancer Security Group         │
│ (Restrict source IPs if corporate)   │
└────────────┬──────────────────────────┘
             │
┌────────────▼──────────────────────────┐
│ Load Balancer                         │
│ (Connection limiting, keep-alive)    │
└────────────┬──────────────────────────┘
             │
┌────────────▼──────────────────────────┐
│ Application Layer Security            │
│ (API auth, rate limiting, encryption)│
└──────────────────────────────────────┘
```

### 2. Observability-First Design

Every load balancer should emit:
- CloudWatch metrics (request count, latency, target health)
- Access logs (S3 bucket, analyzed by Athena/QuickSight)
- Request tracing (X-Ray integration for end-to-end visibility)

### 3. Cost-Aware Architecture

- NLB: $0.006/LCU-hour (highest cost, justified only for ultra-high throughput)
- ALB: $0.0225/LCU-hour (most cost-effective for web applications)
- Cross-zone load balancing: Free on ALB, $0.006/LCU-hour extra on NLB

**Decision:** If not exceeding ~100k requests/minute per AZ, ALB is more economical.

---

## ALB vs NLB vs CLB vs Gateway Load Balancer

### Textual Deep Dive

#### Application Load Balancer (ALB) – Layer 7

**Internal Working Mechanism:**

ALB operates at the application layer (Layer 7) and inspects HTTP/HTTPS request details before making routing decisions.

1. **Request Parsing:** ALB parses incoming HTTP request headers, body (optional), path, hostname, and query parameters
2. **Rule Evaluation:** Listener rules are evaluated in priority order against parsed request attributes:
   - **Host-based routing:** `example.com` → Target Group A, `api.example.com` → Target Group B
   - **Path-based routing:** `/api/*` → Backend API service, `/images/*` → S3 origin
   - **Header-based routing:** `X-Tenant-ID: premium` → Premium tier infrastructure
   - **Query parameter routing:** `?version=v2` → Canary deployment target
   - **HTTP method routing:** `POST /orders` → Order processing service, `GET /orders` → Query service
3. **Target Selection:** Once rule matches, request routes to specified target group
4. **Connection Management:** HTTP keep-alive reuses TCP connections; multiple requests may hit different targets

**Architecture Role:**

- **Microservices Gateway:** Intelligently routes requests to specialized services
- **API Gateway Substitute:** Content-based routing eliminates need for reverse-proxy layer
- **Canary Deployment Platform:** Route percentage of traffic to new version without code changes

**Production Usage Patterns:**

```
Use ALB when:
✓ Building microservices architectures
✓ Need URL/hostname/header-based routing
✓ Typical HTTP request rate < 1M req/sec
✓ Sub-100ms latency acceptable (processing overhead ~1-5ms)
✓ Cost-sensitive; need sub-second scaling
✓ Deploying containerized workloads (ECS/EKS)

Avoid ALB when:
✗ Handling non-HTTP protocols (MQTT, IoT, proprietary)
✗ Ultra-high throughput (>1M req/sec per instance)
✗ Sub-millisecond latency critical
✗ UDP-based services
✗ Need to preserve raw TCP connections
```

**DevOps Best Practices:**

1. **Rule Ordering:** Place most specific rules first; catch-all rules last
   ```
   Priority 1: /api/v2/premium/* → Premium service
   Priority 2: /api/v2/* → Standard service
   Priority 3: /* → Default service
   ```

2. **Target Group Separation:** Isolate different service tiers
   - Create distinct target groups for each microservice
   - Enables independent scaling and health check configurations

3. **Connection Draining:** Set appropriate deregistration delay
   - Short-lived request workloads: 30–60 seconds
   - Long-polling APIs: 120–300 seconds

4. **HTTP/2 & gRPC Support:** Enable modern protocols
   - ALB supports HTTP/2 for improved performance
   - gRPC routing available; use gRPC target type for proper health checks

5. **Access Logs & Request Tracing:** Enable by default
   - S3-backed logs for audit trails
   - X-Ray integration for request tracing

**Common Pitfalls:**

1. **Unordered Rules:** Multiple rules matching same request create non-deterministic behavior
   - **Fix:** AWS enforces priority ordering; verify in console

2. **Connection Exhaustion:** Misconfiguring keep-alive timeouts
   - **Symptom:** "Connection reset by peer" errors after idle period
   - **Fix:** Set keep-alive timeout > client idle timeout

3. **Health Check False Positives:** Checking `/` when service serves no root path
   - **Symptom:** Targets marked unhealthy despite serving traffic
   - **Fix:** Health check path should return 200 OK (e.g., `/health`, `/api/health`)

4. **Sticky Session Overuse:** Binding clients to single target defeats scaling benefits
   - **Anti-pattern:** Using `AWSALB` cookie for session tracking
   - **Better approach:** Distributed session store (ElastiCache)

5. **Cross-Zone Load Balancing Disabled:** Leaving traffic imbalanced across AZs
   - **Impact:** 2 AZs with 3–1 target distribution creates 3x load in zone 1
   - **Fix:** Enable cross-zone load balancing (free feature)

---

#### Network Load Balancer (NLB) – Layer 4

**Internal Working Mechanism:**

NLB operates at the transport layer (Layer 4) and makes forwarding decisions based on TCP/UDP headers, not content.

1. **5-Tuple Parsing:** Extracts (protocol, source IP, source port, dest IP, dest port)
2. **Flow Hash Algorithm:** Uses MD5 hash of 5-tuple to determine target
   ```
   target = hash(protocol, src_ip, src_port, dst_ip, dst_port) % num_targets
   ```
3. **Connection Affinity:** All packets in flow deterministically route to same target
4. **Ultra-High Performance:** Direct packet forwarding with minimal overhead (~100 microseconds)

**Architecture Role:**

- **High-Performance Gateway:** Millions of connections per second
- **Stateful Service Load Balancer:** Database replicas, caching layers
- **Custom Protocol Gateway:** MQTT, AMQP, custom binary protocols
- **Raw TCP/UDP Proxy:** Preserve client IP without proxy overheads

**Production Usage Patterns:**

```
Use NLB when:
✓ Non-HTTP protocols (MQTT, gRPC, QUIC, custom)
✓ Ultra-high throughput (>1M req/sec)
✓ Sub-millisecond latency critical (<1ms SLA)
✓ UDP load balancing required
✓ Gaming, financial trading, IoT platforms
✓ Database cluster proxying
✓ DDoS mitigation (capacity > ALB)

Avoid NLB when:
✗ Simple web application (higher cost: $0.006/LCU vs $0.0225)
✗ Content-based routing needed
✗ Don't need connection-level affinity
✗ Typical traffic < 100k req/sec
```

**DevOps Best Practices:**

1. **Flow Hashing Stability:** Hash ensures deterministic routing; don't rely on round-robin
   - Great for: Database connection pooling, stateful caches
   - Bad for: Expecting even distribution across connection count variations

2. **Cross-Zone Load Balancing Trade-off:**
   - **Enabled:** Even distribution, but inter-AZ traffic costs $0.006/LCU-hour
   - **Disabled:** Free, but creates hot targets in smaller AZs
   - **Decision:** Enable for critical workloads; disable for cost-sensitive IoT

3. **Preserve Source IP:** NLB preserves client IP; exploit this
   - Backend sees real client IP (not LB IP)
   - Logging, rate limiting, geolocation work naturally
   - ALB proxies request → backend sees LB IP (requires `X-Forwarded-For`)

4. **Connection Limits:** Manage per-target connection limits
   - High-throughput services may exhaust target connection table
   - Monitor via CloudWatch: `ActiveConnectionCount`

5. **Health Check Configuration:** TCP level only (no application awareness)
   - Use fast interval (5–10 seconds) for rapid failover
   - Even "healthy" targets may drop packets (monitor via CloudWatch)

**Common Pitfalls:**

1. **Assuming Even Distribution by Request Count:**
   - **Reality:** Flow hash distributes by connection, not request count
   - **Symptom:** Long-lived WebSocket connections load one target heavily
   - **Fix:** Use ALB if request-level balancing needed

2. **Ignoring Connection Draining:**
   - **Issue:** Terminating instance drops active connections (no graceful drain by default)
   - **Fix:** Implement application-level connection draining; don't rely on load balancer

3. **UDP Timeout Misconfig:**
   - NLB default UDP timeout: 120 seconds
   - **Issue:** Stateless UDP clients may timeout before server
   - **Fix:** Adjust timeout to match application needs (available in seconds)

4. **TLS Passthrough Misconfiguration:**
   - NLB can preserve TLS handshake to backend (not terminating)
   - **Problem:** Missing security group rules blocking TLS port
   - **Fix:** Backend security group must allow ingress on TLS port from load balancer

5. **Wildcard Certificate Issues:**
   - If using TLS termination on NLB, certificate must match backend domain
   - **Issue:** Backends with differing TLS certs require SNI support
   - **Better approach:** Use ALB for TLS termination with SNI

---

#### Classic Load Balancer (CLB) – Layer 4 (Legacy)

**Status:** Deprecated; AWS recommends migration to ALB/NLB

**When CLB Still Appears:**

1. **Legacy Applications:** Pre-2015 deployments still using established CLBs
2. **EC2-Classic Migration:** Rare; mostly obsolete
3. **Mixed Environment Holdouts:** Cost-justifiable only if <100k req/sec and no routing needs

**Migration Path:**

| CLB Capability | Recommended Replacement |
|---|---|
| Basic TCP/HTTP balancing | ALB (for HTTP/HTTPS) or NLB (for TCP) |
| Sticky sessions | Use distributed session store; avoid stickiness |
| Zone-redundancy | ALB/NLB with multi-AZ enabled |

**DevOps Action:** If managing CLB, prioritize migration to ALB/NLB within 6–12 months.

---

#### Gateway Load Balancer (GLB)

**Internal Working Mechanism:**

GLB enables **appliance chaining** — traffic flows through third-party security/inspection appliances before reaching application targets.

1. **GENEVE Encapsulation:** GLB encapsulates traffic in GENEVE protocol (UDP 6081)
2. **Appliance Processing:** Traffic routes to inspection appliances (IDS, firewall, DPI)
3. **Transparent Return:** Appliances return processed traffic to GLB
4. **Final Delivery:** GLB forwards to application targets

```
Client Traffic
    ↓
Gateway Load Balancer
    ↓
[Encapsulated in GENEVE]
    ↓
Appliance Fleet
(Firewalls, IDS, DPI, WAF)
    ↓
[De-encapsulated]
    ↓
Application Targets
```

**Architecture Role:**

- **Packet Inspection & Filtering:** Third-party firewalls, network appliances
- **Transparent Proxy:** DPI (Deep Packet Inspection) for security
- **Service Chaining:** Multiple appliance types in sequence

**Production Usage Patterns:**

```
Use GLB when:
✓ Third-party appliances required (Fortinet, Palo Alto, CheckPoint)
✓ Regulatory requirement for packet inspection
✓ DPI-based threat detection needed
✓ Multi-stage inspection pipeline

Almost Never Use GLB:
✗ AWS native WAF available (use WAF + ALB instead)
✗ Network ACLs sufficient (no appliance needed)
✗ Standard security groups adequate
```

**DevOps Considerations:**

1. **Appliance Compatibility:** Not all appliances support GENEVE; verify beforehand
2. **Latency Impact:** Appliance inspection adds 5–50ms depending on DPI depth
3. **Cost:** Higher than ALB/NLB; used only when appliance mandatory

---

### Comparison Matrix

| Attribute | ALB | NLB | CLB | GLB |
|-----------|-----|-----|-----|-----|
| **OSI Layer** | 7 (Application) | 4 (Transport) | 4 (Transport) | 3/4 (Network) |
| **Protocol Support** | HTTP, HTTPS, HTTP/2 | TCP, UDP, TLS, QUIC | TCP, HTTP | IP, TCP, UDP |
| **Max Throughput** | ~1M req/sec | 25M+ pps (packets/sec) | ~4M req/sec | 25M+ pps |
| **Latency** | 1–5ms | 100µs–1ms | 100µs–1ms | 1–5ms (+ appliance) |
| **Path-based Routing** | ✓ | ✗ | ✗ | ✗ |
| **Host-based Routing** | ✓ | ✗ | ✗ | ✗ |
| **Connection Affinity** | Cookie-based | Hash-based (automatic) | Hash-based | Via appliance |
| **Pricing/LCU** | $0.0225/h | $0.006/h | $0.0225/h (+ legacy) | $0.006/h |
| **Multi-AZ** | ✓ (free) | ✓ (+ $0.006/h) | ✓ | ✓ |
| **Typical Use Case** | Microservices | High-throughput, non-HTTP | ← Don't use → | Appliance chaining |

---

### Practical Code Examples

#### Terraform: ALB with Host-Based Routing

```hcl
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection = false
  enable_http2              = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "example-alb"
  }
}

# Target Groups
resource "aws_lb_target_group" "api_service" {
  name     = "api-service-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
    port                = "traffic-port"
  }

  deregistration_delay = 90

  tags = {
    Name = "api-service-tg"
  }
}

resource "aws_lb_target_group" "web_service" {
  name     = "web-service-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200-499"
  }

  tags = {
    Name = "web-service-tg"
  }
}

# Listener Rules
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action: redirect to HTTPS
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.tls_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_service.arn
  }
}

# Host-based routing rule
resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_service.arn
  }

  condition {
    host_header {
      values = ["api.example.com"]
    }
  }
}

# Path-based routing rule
resource "aws_lb_listener_rule" "admin_routing" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_service.arn
  }

  condition {
    path_pattern {
      values = ["/admin/*"]
    }
  }
}
```

#### Terraform: NLB with TCP Passthrough

```hcl
# Network Load Balancer
resource "aws_lb" "nlb" {
  name               = "example-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "example-nlb"
  }
}

# Target Group for Database
resource "aws_lb_target_group" "db_cluster" {
  name     = "db-cluster-tg"
  port     = 3306
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = "3306"
    protocol            = "TCP"
  }

  stickiness {
    type            = "source_ip"
    enabled         = true
  }

  deregistration_delay = 120

  tags = {
    Name = "db-cluster-tg"
  }
}

# NLB Listener
resource "aws_lb_listener" "db_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "3306"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.db_cluster.arn
  }
}

# Register targets (RDS replicas)
resource "aws_lb_target_group_attachment" "db_replica1" {
  target_group_arn = aws_lb_target_group.db_cluster.arn
  target_id        = aws_instance.db_replica1.id
  port             = 3306
}
```

#### Terraform: Gateway Load Balancer with Appliance Fleet

```hcl
# Gateway Load Balancer
resource "aws_lb" "glb" {
  name               = "example-glb"
  internal           = true
  load_balancer_type = "gateway"
  subnets            = [aws_subnet.private1.id, aws_subnet.private2.id]

  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "example-glb"
  }
}

# Target Group for Appliances
resource "aws_lb_target_group" "appliance_fleet" {
  name     = "appliance-fleet-tg"
  port     = 6081
  protocol = "GENEVE"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    port                = "6081"
    protocol            = "GENEVE"
  }

  deregistration_delay = 60

  tags = {
    Name = "appliance-fleet-tg"
  }
}

# GLB Listener
resource "aws_lb_listener" "appliance_listener" {
  load_balancer_arn = aws_lb.glb.arn
  port              = "6081"
  protocol          = "GENEVE"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.appliance_fleet.arn
  }
}

# Register appliance instances
resource "aws_lb_target_group_attachment" "appliance1" {
  target_group_arn = aws_lb_target_group.appliance_fleet.arn
  target_id        = aws_instance.appliance1.id
  port             = 6081
}
```

#### CloudFormation: ALB with HTTPS Listener

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'ALB with HTTPS listener and path-based routing'

Resources:
  # Security Group for Load Balancer
  LoadBalancerSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ALB
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

  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Type: application
      Scheme: internet-facing
      IpAddressType: ipv4
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref LoadBalancerSecurityGroup
      Tags:
        - Key: Name
          Value: example-alb

  # Target Group for API Service
  APITargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: api-service-tg
      Port: 8080
      Protocol: HTTP
      VpcId: !Ref VPC
      HealthCheckEnabled: true
      HealthCheckPath: /health
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 2
      TargetDeregistrationDelay:
        Timeout: 90
      Tags:
        - Key: Name
          Value: api-service-tg

  # Target Group for Web Service
  WebTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: web-service-tg
      Port: 3000
      Protocol: HTTP
      VpcId: !Ref VPC
      HealthCheckEnabled: true
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 30
      HealthCheckTimeoutSeconds: 5
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 2
      Tags:
        - Key: Name
          Value: web-service-tg

  # HTTP Listener (Redirect to HTTPS)
  HTTPListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: redirect
          RedirectConfig:
            Protocol: HTTPS
            Port: '443'
            StatusCode: HTTP_301
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 80
      Protocol: HTTP

  # HTTPS Listener
  HTTPSListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !Ref WebTargetGroup
      LoadBalancerArn: !Ref ApplicationLoadBalancer
      Port: 443
      Protocol: HTTPS
      Certificates:
        - CertificateArn: !Ref TLSCertificateARN
      SslPolicy: ELBSecurityPolicy-TLS-1-2-2017-01

  # Listener Rule: Route /api/* to API Service
  APIListenerRule:
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      Actions:
        - Type: forward
          TargetGroupArn: !Ref APITargetGroup
      Conditions:
        - Field: path-pattern
          Values:
            - /api/*
      ListenerArn: !Ref HTTPSListener
      Priority: 1

  # Listener Rule: Route api.example.com to API Service
  APIHostListenerRule:
    Type: AWS::ElasticLoadBalancingV2::ListenerRule
    Properties:
      Actions:
        - Type: forward
          TargetGroupArn: !Ref APITargetGroup
      Conditions:
        - Field: host-header
          Values:
            - api.example.com
      ListenerArn: !Ref HTTPSListener
      Priority: 2

Outputs:
  LoadBalancerDNS:
    Description: DNS name of the load balancer
    Value: !GetAtt ApplicationLoadBalancer.DNSName
    Export:
      Name: !Sub '${AWS::StackName}-LoadBalancerDNS'
  
  APITargetGroupArn:
    Description: ARN of API Target Group
    Value: !Ref APITargetGroup
    Export:
      Name: !Sub '${AWS::StackName}-APITargetGroup'
```

#### Shell Script: Load Balancer Diagnostics

```bash
#!/bin/bash
# Load Balancer Health Check & Diagnostics Script

set -euo pipefail

LB_NAME="${1:-}"
REGION="${AWS_REGION:-us-east-1}"

if [[ -z "$LB_NAME" ]]; then
  echo "Usage: $0 <load-balancer-name>"
  exit 1
fi

echo "========================================="
echo "Load Balancer Diagnostics: $LB_NAME"
echo "Region: $REGION"
echo "========================================="

# Get Load Balancer Details
echo ""
echo "1. Load Balancer Configuration:"
aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?LoadBalancerName=='$LB_NAME'].[LoadBalancerArn, LoadBalancerName, Type, Scheme, State.Code]" \
  --output table

# Get Listener Configuration
echo ""
echo "2. Listener Configuration:"
LB_ARN=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?LoadBalancerName=='$LB_NAME'].LoadBalancerArn" \
  --output text)

aws elbv2 describe-listeners \
  --region "$REGION" \
  --load-balancer-arn "$LB_ARN" \
  --query 'Listeners.[Port, Protocol, DefaultActions[0].Type]' \
  --output table

# Get Target Groups
echo ""
echo "3. Target Groups:"
aws elbv2 describe-target-groups \
  --region "$REGION" \
  --load-balancer-arn "$LB_ARN" \
  --query 'TargetGroups.[TargetGroupName, Port, Protocol, HealthCheckPath, HealthyThresholdCount, UnhealthyThresholdCount]' \
  --output table

# Get Target Health Status
echo ""
echo "4. Target Health Status:"
TG_ARNS=$(aws elbv2 describe-target-groups \
  --region "$REGION" \
  --load-balancer-arn "$LB_ARN" \
  --query 'TargetGroups[].TargetGroupArn' \
  --output text)

for TG_ARN in $TG_ARNS; do
  TG_NAME=$(aws elbv2 describe-target-groups \
    --region "$REGION" \
    --target-group-arns "$TG_ARN" \
    --query 'TargetGroups[0].TargetGroupName' \
    --output text)
  
  echo ""
  echo "Target Group: $TG_NAME"
  aws elbv2 describe-target-health \
    --region "$REGION" \
    --target-group-arn "$TG_ARN" \
    --query 'TargetHealthDescriptions.[Target.Id, TargetHealth.State, TargetHealth.Reason, TargetHealth.Description]' \
    --output table
done

# CloudWatch Metrics
echo ""
echo "5. CloudWatch Metrics (Last 1 Hour):"
TIMESTAMP=$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)
aws cloudwatch get-metric-statistics \
  --region "$REGION" \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value="${LB_NAME/*\///}" \
  --start-time "$TIMESTAMP" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
  --period 300 \
  --statistics Sum \
  --output table

# Security Group Analysis
echo ""
echo "6. Load Balancer Security Groups:"
SECURITY_GROUPS=$(aws ec2 describe-load-balancers \
  --region "$REGION" \
  --load-balancer-arns "$LB_ARN" \
  --query 'LoadBalancers[0].SecurityGroups[]' \
  --output text)

for SG in $SECURITY_GROUPS; do
  echo ""
  echo "Security Group: $SG"
  aws ec2 describe-security-group-rules \
    --region "$REGION" \
    --filters "Name=group-id,Values=$SG" \
    --query 'SecurityGroupRules.[IpProtocol, FromPort, ToPort, CidrIpv4, Description]' \
    --output table
done
```

---

### ASCII Diagrams

#### ALB Request Routing Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Request                           │
│            https://api.example.com/users/123                │
└────────────────────┬────────────────────────────────────────┘
                     │ (HTTPS on port 443)
                     ▼
        ┌────────────────────────────┐
        │   Application Load         │
        │   Balancer                 │
        │ (Layer 7 - HTTP/HTTPS)     │
        └────────┬───────────────────┘
                 │ (Parse request headers, path, hostname)
                 ▼
        ┌────────────────────────────┐
        │ Listener: 443 / HTTPS      │
        │ SSL Certificate: example   │
        └────────┬───────────────────┘
                 │
                 ▼
    ┌────────────────────────────────────┐
    │   Evaluate Listener Rules           │
    │   Priority Order:                   │
    │                                     │
    │   Rule 1: Host = api.example.com    │
    │   → Forward to API Target Group ✓   │
    │   (MATCH - Use this rule)           │
    │                                     │
    │   Rule 2: Path = /admin/*           │
    │   →(not evaluated, rule matched)    │
    │                                     │
    │   Default: Pool = Web Target Group  │
    │   (not used, rule matched)          │
    └────────┬─────────────────────────────┘
             │
             ▼
   ┌─────────────────────────────────────┐
   │  API Target Group (port 8080)       │
   │  Protocol: HTTP                     │
   │  Deregistration Delay: 90s          │
   │  Sticky: DISABLED                   │
   │                                     │
   │  ┌──────────────────────────────┐  │
   │  │ Healthy Targets:             │  │
   │  │  • i-0abc123 (10.0.1.10)    │  │
   │  │  • i-0def456 (10.0.1.11)    │  │
   │  │  • i-0ghi789 (10.0.2.22)    │  │
   │  │                              │  │
   │  │ Unhealthy Targets:           │  │
   │  │  ✗ i-0jkl012 (10.0.2.23)   │  │
   │  └──────────────────────────────┘  │
   └────────┬─────────────────────────────┘
            │ (Round-robin to healthy targets)
            ▼
 ┌──────────────────────────────────────┐
 │  Backend Service (API Server)        │
 │  Port: 8080                          │
 │  Route: /users/123                   │
 │  Response: 200 OK {"user": {...}}    │
 └────────┬─────────────────────────────┘
          │ (Response forwarded via ALB)
          ▼
  ┌────────────────────────────┐
  │  Client Receives Response   │
  │  Status: 200 OK            │
  └────────────────────────────┘
```

#### NLB Connection Affinity (5-Tuple Hashing)

```
┌─────────────────────────────────────┐
│         Client Machine              │
│    IP: 203.0.113.5                  │
│    Random Port: 54321               │
└────────┬────────────────────────────┘
         │ TCP SYN
         │ dst_port: 3306 (MySQL)
         ▼
┌─────────────────────────────────────┐
│   Network Load Balancer             │
│   Virtualservice IP: 10.0.0.100     │
│   Listener: TCP port 3306           │
│   Load Balancing Algorithm: Flow    │
│   Hash                              │
└────────┬────────────────────────────┘
         │ Calculate hash of 5-tuple:
         │ • Protocol: TCP (6)
         │ • Source IP: 203.0.113.5
         │ • Source Port: 54321
         │ • Dest IP: 10.0.0.100
         │ • Dest Port: 3306
         │
         │ Hash = MD5(203.0.113.5:54321 →
         │           10.0.0.100:3306) % 3
         │ Hash Result: 1
         ▼
 ┌──────────────────────────────────┐
 │  Route to Target Index 1          │
 │                                   │
 │  Target Pool (Port 3306):         │
 │  [0] 10.0.1.50 (Zone-a)          │
 │  [1] 10.0.2.75 (Zone-b) ←──┐     │
 │  [2] 10.0.3.22 (Zone-c)    │     │
 │                             │     │
 │  Selected: 10.0.2.75        │     │
 │  (Deterministic routing)────┘     │
 └──────────┬───────────────────────┘
            │ All packets in flow
            │ route to SAME target
            ▼
┌──────────────────────────────────────┐
│   MySQL Replica (Zone-b)             │
│   IP: 10.0.2.75:3306                │
│                                      │
│   Connection Pool per Client:        │
│   • 203.0.113.5:54321 ←→ Replica    │
│   • (Connection persists for query)  │
│   • (No connection reuse overhead)   │
└──────────────────────────────────────┘

┌─────────────────────────────────────┐
│  Different Client                    │
│  IP: 203.0.113.99                   │
│  Random Port: 55555                 │
└────────┬────────────────────────────┘
         │ Hash = MD5(...) % 3 = 0
         │ (Different hash → Different target)
         ▼
    Route to Target Index 0:
    10.0.1.50 (Zone-a)
    (Completely different target)
```

#### Gateway Load Balancer with Appliance Chain

```
┌────────────────────────────────────────┐
│         Client Traffic                 │
│     203.0.113.0/24 → Web Server        │
│     TCP:443, Payload: HTTPS            │
└────────┬──────────────────────────────┘
         │
         ▼
     ┌─────────────────────┐
     │ VPC Endpoint        │
     │ (GLB traffic target)│
     └────────┬────────────┘
              │ GENEVE encapsulation
              │ (UDP 6081)
              ▼
    ┌──────────────────────────────┐
    │ Gateway Load Balancer        │
    │ (Layer 3/4 network appliance)│
    └────────┬─────────────────────┘
             │
             │ Flow hash determines
             │ appliance target
             ▼
   ┌──────────────────────────────────┐
   │ Appliance Fleet (Auto Scaling)   │
   │                                   │
   │ ┌──────────────────────────────┐ │
   │ │ Instance 1: i-0abc123        │ │
   │ │ • Palo Alto Networks PAN-OS  │ │
   │ │ • Listens on UDP port 6081   │ │
   │ │ • Processes GENEVE packets   │ │
   │ │ • IDS, Threat detection      │ │
   │ │ • Returns processed packet   │ │
   │ └──────────────────────────────┘ │
   │                                   │
   │ ┌──────────────────────────────┐ │
   │ │ Instance 2: i-0def456        │ │
   │ │ (Same appliance cluster)     │ │
   │ └──────────────────────────────┘ │
   │                                   │
   │ ┌──────────────────────────────┐ │
   │ │ Instance 3: i-0ghi789        │ │
   │ │ (for redundancy)             │ │
   │ └──────────────────────────────┘ │
   └────────┬──────────────────────────┘
            │ Appliance response
            │ (de-encapsulated)
            │ Traffic approved/denied
            ▼
     ┌──────────────────────────────┐
     │ Back to GLB                  │
     │ (Packet inspection complete) │
     └────────┬─────────────────────┘
              │
              ▼
    ┌───────────────────────────────┐
    │ Application Target Group      │
    │ (Web servers behind appliance)│
    │                               │
    │ ┌──────────────┐             │
    │ │ 10.0.1.20:80│             │
    │ │ (Healthy)   │             │
    │ └──────────────┘             │
    │                               │
    │ ┌──────────────┐             │
    │ │ 10.0.2.30:80│             │
    │ │ (Healthy)   │             │
    │ └──────────────┘             │
    └────────┬────────────────────┘
             │ Traffic delivered
             │ to application
             ▼
    ┌────────────────────┐
    │ Web Application    │
    │ (Protected by      │
    │  appliance chain)  │
    └────────────────────┘
```

---

## Target Groups & Health Checks

### Textual Deep Dive

#### Target Group Fundamentals

**What is a Target Group?**

A Target Group is a logical grouping of targets (EC2 instances, ECS tasks, Lambda functions, on-premises servers, or IP addresses) that share:
- Routing destination (ALB/NLB references target group, not individual targets)
- Health check configuration
- Stickiness settings (if applicable)
- Deregistration delay

**Why Abstraction Matters:**

Instead of tight-coupling load balancer → specific instance, the target group abstraction enables:

```
Traditional Approach (Anti-Pattern):
Load Balancer → Instance A
         \   → Instance B
          \
           → Instance C
(If Instance B fails, need to reconfigure LB)

Target Group Approach (Modern):
Load Balancer → Target Group "Web Tier"
                     ↓
                [Instances A, B, C]
                     ↓
              Auto Scaling Group manages
              instance membership dynamically
(If Instance B fails, ASG replaces it; LB unaware)
```

#### Target Types

AWS supports four target types; each has different registration mechanism:

**1. Instance Type (EC2 Instances)**
- Register by EC2 instance ID
- Supports health checks via HTTP/HTTPS/TCP/gRPC
- Ideal for: Traditional EC2-based applications
- State: Instance can be in `running`, `stopped`, `terminated` states

```hcl
# Terraform Example
resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}
```

**2. IP Type (Custom IPs)**
- Register by IP address:port
- Enables load balancing to:
  - On-premises data center servers
  - AWS servers in different VPC (via VPC peering)
  - ECS tasks with custom networking
  - Lambda@Edge functions
- Useful for: Hybrid cloud, third-party providers

```hcl
# On-premises server target
resource "aws_lb_target_group_attachment" "on_prem" {
  target_group_arn = aws_lb_target_group.hybrid.arn
  target_id        = "192.168.1.100"  # On-premises IP
  port             = 8080
}
```

**3. Lambda Type**
- Single Lambda function per target
- Automatic invoke with event payload
- Useful for: Serverless web applications without traditional servers
- Limitation: Cannot use multiple Lambda functions in same target group

```hcl
resource "aws_lambda_function" "api_handler" {
  filename = "lambda_function.zip"
  function_name = "web_api_handler"
  role = aws_iam_role.lambda_role.arn
  handler = "index.handler"
}

resource "aws_lb_target_group" "lambda_tg" {
  name        = "lambda-api-tg"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda_tg.arn
  target_id        = aws_lambda_function.api_handler.arn
}
```

**4. ALB Type (for Nested Load Balancers)**
- Target group contains another ALB
- Enables: Service chaining, transparent routing
- Advanced pattern; rarely used

---

#### Health Check Deep Dive

Health checks are critical for load balancer reliability. Let's explore each aspect:

**Health Check Types:**

| Type | Protocol | Behavior | Use Case |
|------|----------|----------|----------|
| **HTTP/HTTPS** | HTTP(S) | Sends GET request to path; expects 200-399 status | Web applications, REST APIs |
| **TCP** | TCP SYN | Verifies port accepting connections (no app logic validation) | Databases, non-HTTP services |
| **gRPC** | gRPC | Invokes `/grpc.health.v1.Health/Check` method | gRPC services (requires handler) |
| **UDP** (NLB) | UDP | Sends ECHO request; expects response | Custom UDP protocols |

**Health Check Lifecycle:**

```
┌──────────────────────────────────────────────┐
│  NewTarget Registered                        │
│  State: OutOfService (not yet validated)     │
└─────────────┬────────────────────────────────┘
              │
              ▼
    ┌─────────────────────────────────┐
    │ Health Check Interval Timer     │
    │ (Default: 30 seconds)           │
    │ (Range: 5–300 seconds)          │
    └────────┬────────────────────────┘
             │ Interval elapsed
             ▼
  ┌────────────────────────────────────────┐
  │ Send Health Check Request               │
  │ • HTTP GET /health                      │
  │ • Timeout: 5 seconds (configurable)     │
  │ • Expects status 200-399                │
  └────┬───────────────────────────────────┘
       │
       ├─ SUCCESS (200 OK)
       │  └─→ Count towards healthy threshold
       │
       ├─ FAILURE (timeout / 4xx/5xx)
       │  └─→ Count towards unhealthy threshold
       │
       └─ INITIAL (application still starting)
          └─→ Ignore until timeout (30s default)
```

**State Machine:**

```
┌─────────────────────┐
│   OutOfService      │  (Initial state)
│   (Target starting) │
└──────────┬──────────┘
           │ healthy_threshold consecutive successes
           │ (default: 2)
           ▼
┌──────────────────────────────┐
│  Healthy                     │
│  (Traffic routed to target)  │
└──────────┬───────────────────┘
           │ unhealthy_threshold consecutive failures
           │ (default: 2)
           ▼
┌─────────────────────────────┐
│  Unhealthy                  │
│  (Traffic blocked)          │
│  Targets enter draining     │
└─────────────────────────────┘
```

**Configuration Best Practices:**

1. **Interval vs. Timeout Trade-off:**
   - **Aggressive (5s interval, 2s timeout):** Detects failures in 15s (5s + 2s×2 failures), but higher CPU load
   - **Conservative (30s interval, 5s timeout):** Detects failures in 70s (30s + 5s×2), but lower overhead
   - **Decision:** For critical services, use aggressive; for cost-sensitive, use conservative

2. **Path Selection:**
   ```
   ✗ WRONG: /           (Returns entire homepage; slow)
   ✓ RIGHT: /health     (Lightweight; milliseconds)
   ✓ RIGHT: /api/health (Application-specific status)
   ✗ WRONG: /login      (Authentication required; complex)
   ```

3. **Status Code Matching:**
   - ALB default: 200–399 (success range)
   - Can customize: 200, 201, 301 (if redirect is acceptable)
   - **Tip:** Use 503 for graceful degradation; ALB marks unhealthy

4. **gRPC Health Checks:**
   Requires application to implement gRPC health check service:
   ```go
   // Go example
   import "google.golang.org/grpc/health"
   
   grpc_health_v1.RegisterHealthServer(grpcServer, &HealthServer{})
   ```

---

#### Target Registration Patterns

**1. Manual Registration**

```hcl
# Terraform: Register EC2 instances
resource "aws_lb_target_group_attachment" "web_servers" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
```

**Pros:** Explicit control
**Cons:** Manual management; error-prone at scale

---

**2. Auto Scaling Group Integration (Recommended)**

```hcl
# ASG automatically registers/deregisters targets
resource "aws_autoscaling_group" "web" {
  name                = "web-asg"
  vpc_zone_identifier = [aws_subnet.public1.id, aws_subnet.public2.id]
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"  # Use LB health checks, not EC2 status checks
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}
```

**Pros:** Automatic lifecycle management; highly available
**Cons:** Requires ASG setup

---

**3. ECS Service Integration**

```hcl
# ECS automatically manages target group membership
resource "aws_ecs_service" "api" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3
  
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api-container"
    container_port   = 8080
  }
}
```

**Pros:** Container-native integration; scales with containers
**Cons:** Requires ECS; adds another abstraction layer

---

**4. Lambda Integration**

```hcl
# ALB invokes Lambda directly
resource "aws_lb_target_group" "lambda" {
  name        = "lambda-api"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda" {
  target_group_arn = aws_lb_target_group.lambda.arn
  target_id        = aws_lambda_function.api_handler.arn
}

# Required: Lambda must be invokable from ALB
resource "aws_lambda_permission" "alb" {
  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda.arn
}
```

**Pros:** Serverless; no servers to manage
**Cons:** Cold starts (100–500ms); concurrent execution limits; higher latency

---

**5. IP-Based Registration (Hybrid/Multi-Cloud)**

```bash
#!/bin/bash
# Register on-premises server by IP address

AWS_REGION="us-east-1"
TG_ARN="arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/hybrid/abc123"
ON_PREM_IP="203.0.113.50"
PORT="8080"

aws elbv2 register-targets \
  --region "$AWS_REGION" \
  --target-group-arn "$TG_ARN" \
  --targets Id="$ON_PREM_IP:$PORT"

echo "Registered on-premises target: $ON_PREM_IP:$PORT"
```

**Pros:** Enables hybrid cloud; multi-cloud deployments
**Cons:** Requires network connectivity (VPN/Direct Connect)

---

### Practical Code Examples

#### Terraform: Advanced Target Group Configuration

```hcl
# Advanced ALB Target Group with detailed health checks
resource "aws_lb_target_group" "advanced_api" {
  name     = "advanced-api-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  # Health Check Configuration
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
    path                = "/api/health"
    matcher             = "200,202"  # Accept both 200 and 202
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Deregistration (Connection Draining)
  deregistration_delay = 120

  # Stickiness
  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400  # 24 hours
  }

  # Preserve Source IP
  preserve_source_ip = true

  # Load Balancing Algorithm
  load_balancing_algorithm_type = "least_outstanding_requests"

  tags = {
    Name = "advanced-api-tg"
  }
}

# Register targets by instance ID
resource "aws_lb_target_group_attachment" "api_instance1" {
  target_group_arn = aws_lb_target_group.advanced_api.arn
  target_id        = aws_instance.api_server1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "api_instance2" {
  target_group_arn = aws_lb_target_group.advanced_api.arn
  target_id        = aws_instance.api_server2.id
  port             = 8080
}

# Lambda Target Group
resource "aws_lb_target_group" "lambda_api" {
  name        = "lambda-api-tg"
  target_type = "lambda"

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_lb_target_group_attachment" "lambda_attachment" {
  target_group_arn = aws_lb_target_group.lambda_api.arn
  target_id        = aws_lambda_function.api_handler.arn
}

# Allow ALB to invoke Lambda
resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda_api.arn
}

# NLB Target Group with gRPC Health Checks
resource "aws_lb_target_group" "grpc_service" {
  name             = "grpc-service-tg"
  port             = 50051
  protocol         = "TCP"
  target_type      = "instance"
  vpc_id           = aws_vpc.main.id
  ip_address_type  = "ipv4"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    path                = ""
    port                = "traffic-port"
    protocol            = "TCP"
    # For gRPC, would be "GRPC" instead of "TCP"
  }

  deregistration_delay = 90
}
```

#### Shell Script: Target Group Health Management

```bash
#!/bin/bash
# Target Group Health Check Monitor & Status Reporter

set -euo pipefail

TG_ARN="${1:-}"
REGION="${AWS_REGION:-us-east-1}"
WATCH_MODE="${2:-false}"

if [[ -z "$TG_ARN" ]]; then
  echo "Usage: $0 <target-group-arn> [watch]"
  echo "Example: $0 arn:aws:elasticloadbalancing:us-east-1:123...:targetgroup/api/abc watch"
  exit 1
fi

# Function to display health status
display_health_status() {
  echo "========================================"
  echo "Target Group Health Status Report"
  echo "Target Group: $TG_ARN"
  echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "========================================"
  
  # Get target health
  HEALTH_DATA=$(aws elbv2 describe-target-health \
    --region "$REGION" \
    --target-group-arn "$TG_ARN" \
    --output json)
  
  # Parse and display
  echo ""
  echo "Target Health Summary:"
  echo "$HEALTH_DATA" |  jq '.TargetHealthDescriptions[] |
    {
      Target: .Target.Id,
      Port: .Target.Port,
      State: .TargetHealth.State,
      Reason: .TargetHealth.Reason,
      Description: .TargetHealth.Description
    }' -r | column -t -s ':'
  
  # Statistics
  HEALTHY=$(echo "$HEALTH_DATA" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')
  UNHEALTHY=$(echo "$HEALTH_DATA" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "unhealthy")] | length')
  DRAINING=$(echo "$HEALTH_DATA" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "draining")] | length')
  
  echo ""
  echo "Statistics:"
  echo "  Healthy: $HEALTHY"
  echo "  Unhealthy: $UNHEALTHY"
  echo "  Draining: $DRAINING"
  
  return 0
}

# Function to deregister unhealthy targets
deregister_unhealthy() {
  echo ""
  echo "Deregistering unhealthy targets..."
  
  aws elbv2 describe-target-health \
    --region "$REGION" \
    --target-group-arn "$TG_ARN" \
    --query 'TargetHealthDescriptions[?TargetHealth.State==`unhealthy`].[Target.Id,Target.Port]' \
    --output text | while read TARGET_ID PORT; do
      echo "Deregistering: $TARGET_ID:$PORT"
      aws elbv2 deregister-targets \
        --region "$REGION" \
        --target-group-arn "$TG_ARN" \
        --targets Id="$TARGET_ID" Port="$PORT"
    done
}

# Watch mode: continuous monitoring
if [[ "$WATCH_MODE" == "watch" ]]; then
  while true; do
    clear
    display_health_status
    echo ""
    echo "Refreshing in 10 seconds... (Press Ctrl+C to exit)"
    sleep 10
  done
else
  display_health_status
fi
```

#### CloudFormation: Lambda Target Group Setup

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Lambda-backed Target Group for ALB'

Resources:
  # Lambda Execution Role
  LambdaExecutionRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: lambda.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

  # Lambda Function
  APIHandler:
    Type: AWS::Lambda::Function
    Properties:
      FunctionName: alb-api-handler
      Runtime: python3.11
      Role: !GetAtt LambdaExecutionRole.Arn
      Handler: index.lambda_handler
      Code:
        ZipFile: |
          import json
          def lambda_handler(event, context):
              print(f"Received event: {json.dumps(event)}")
              return {
                  'statusCode': 200,
                  'statusDescription': '200 OK',
                  'isBase64Encoded': False,
                  'body': json.dumps({'message': 'Hello from Lambda'}),
                  'headers': {
                      'Content-Type': 'application/json'
                  }
              }

  # Lambda Permission (allow ALB to invoke)
  ALBInvokeLambdaPermission:
    Type: AWS::Lambda::Permission
    Properties:
      FunctionName: !Ref APIHandler
      Principal: elasticloadbalancing.amazonaws.com
      Action: lambda:InvokeFunction

  # Lambda Target Group
  LambdaTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: lambda-api-tg
      TargetType: lambda
      HealthCheckEnabled: true
      HealthCheckPath: /
      HealthCheckProtocol: HTTP
      HealthCheckIntervalSeconds: 35
      HealthCheckTimeoutSeconds: 30
      HealthyThresholdCount: 2
      UnhealthyThresholdCount: 2

  # Target Group Attachment
  LambdaTargetGroupAttachment:
    Type: AWS::ElasticLoadBalancingV2::TargetGroupAttachment
    Properties:
      TargetGroupArn: !Ref LambdaTargetGroup
      TargetId: !GetAtt APIHandler.Arn

Outputs:
  TargetGroupArn:
    Description: Arn of Lambda Target Group
    Value: !Ref LambdaTargetGroup
    Export:
      Name: !Sub '${AWS::StackName}-TargetGroupArn'
```

---

### ASCII Diagrams

#### Target Group Registration Lifecycle

```
┌──────────────────────────────────────┐
│  Auto Scaling Group (ASG)            │
│  Min: 2, Max: 10, Desired: 3         │
└──────────┬───────────────────────────┘
           │ ASG_ScaleUpEvent
           ▼
┌──────────────────────────────────────┐
│ Launch EC2 Instance                  │
│ • i-0abc123 (10.0.1.20)              │
│ State: pending → running (2-3 min)   │
└──────────┬───────────────────────────┘
           │ Once running
           ▼
┌─────────────────────────────────────┐
│ ASG Registers Target                │
│ • Target Group: api-service-tg      │
│ • Target ID: i-0abc123              │
│ • Port: 8080                        │
│ • State: OutOfService               │
└──────────┬────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│ Health Check Starts (every 10s)      │
│                                      │
│ Attempt 1: GET /health               │
│ Response: Connection refused         │
│ (Application still starting)         │
│                                      │
│ Attempt 2: GET /health               │
│ Response: 200 OK ✓ (Count: 1)        │
│                                      │
│ Attempt 3: GET /health               │
│ Response: 200 OK ✓ (Count: 2)        │
│ healthy_threshold = 2 MET            │
└──────────┬───────────────────────────┘
           │ Healthy threshold reached
           ▼
┌─────────────────────────────────────┐
│ Target State: Healthy               │
│ • Traffic routed to target          │
│ • LB sends requests every 10–30s    │
│ • ALB balances load across healthy  │
│   targets in TG                     │
└──────────┬────────────────────────────┘
           │
           │ (During normal operation)
           │ Periodic health checks continue
           │
           ▼
┌──────────────────────────────────────┐
│ Scale Down Triggered                 │
│ • Desired capacity: 3 → 2            │
│ • Select target for termination:    │
│   i-0abc123                         │
└──────────┬───────────────────────────┘
           │ Deregister target
           ▼
┌──────────────────────────────────────┐
│ Target State: Draining              │
│ • No NEW requests sent              │
│ • Existing requests: Complete       │
│ • Deregistration Delay Timer: 120s  │
│                                     │
│ ┌──────────────────────────────────┐│
│ │ In-flight requests:              ││
│ │ • GET /api/users (30s elapsed)   ││
│ │ • POST /api/orders (5s elapsed)  ││
│ │ (Others complete)                ││
│ └──────────────────────────────────┘│
└──────────┬───────────────────────────┘
           │ 120 seconds passed
           │ or all requests completed
           ▼
┌──────────────────────────────────────┐
│ Target Fully Deregistered           │
│ • State: OutOfService              │
│ • Instance: Terminated by ASG       │
│ • Resources: Cleaned up             │
└──────────────────────────────────────┘
```

#### Health Check State Transitions

```
                INITIAL STATE
                    │
                    │ New target registered
                    ▼
            ┌───────────────────┐
            │  OutOfService     │
            │ (Initializing)    │
            └─────────┬─────────┘
                      │
                      │ Health check interval elapsed
                      │ Send first health check
                      ▼
        ┌─────────────────────────────┐
        │ Checking                    │
        │ (Awaiting response)         │
        └─────────┬───────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
    SUCCESS             FAILURE
    (200 OK)          (timeout/error)
        │                   │
        ▼                   ▼
    ┌──────────────┐  ┌──────────────┐
    │ Count+1 →    │  │ Count = 0    │
    │Healthy Count │  │ Reset        │
    └──────┬───────┘  └──────┬───────┘
           │                 │
   healthy_threshold  Threshold not met
        reached         Try again at
           │            next interval
           │                 │
           ▼                 ▼
        ┌──────────┐    Back to Checking
        │ Healthy  │
        │ ✓        │
        └────┬─────┘
             │
             │ (Traffic flows)
             │
             │ Health check continues...
             │
             ├─ SUCCESS → Count remains high (no change)
             │
             └─ FAILURE → Count: 1, 2, 3...
                          (unhealthy_threshold approaching)
                             │
                             ▼
                         ┌──────────────┐
                         │ Unhealthy    │
                         │ ✗            │
                         │ No traffic   │
                         └──────────────┘
```

---

## Sticky Sessions & Load Balancing Algorithms

### Textual Deep Dive

#### Sticky Sessions & Session Affinity

**What is Session Affinity?**

Session affinity (or "stickiness") ensures that requests from the same client consistently route to the same backend target. This solves a specific problem:

```
Modern Web App (Stateless):
┌──────────────┐     ┌──────────────┐
│   Request 1  │────▶│   Backend A   │
└──────────────┘     └──────────────┘
   (User: john)        Session: NONE
                       (All data in database)
┌──────────────┐     ┌──────────────┐
│   Request 2  │────▶│   Backend B   │ (Different server)
└──────────────┘     └──────────────┘
   (User: john)        Session: NONE
                       (Reads same data from DB)

Result: ✓ Works seamlessly (databases handle shared state)

─────────────────────────────────────────

Legacy App (Stateful):
┌──────────────┐     ┌──────────────┐
│   Request 1  │────▶│   Backend A   │
└──────────────┘     └──────────────┘
   (User: john)        Session Details
                       (loginToken, cart, etc)
                       In-memory
┌──────────────┐     ┌──────────────┐
│   Request 2  │────▶│   Backend B   │ (Different server)
└──────────────┘     └──────────────┘
   (User: john)        NO Session Data
                       (Can't find cart from Req1)
                       HTTP 401 Unauthorized

Result: ✗ BREAKS (Session data lost on server switch)
```

**Solution: Sticky Sessions**

Sticky sessions bind a client to a single backend for the duration of their session, preserving in-memory state.

---

#### ALB Cookie-Based Stickiness

**Mechanism:**

1. **First Request:** Client sends request to ALB without cookies
2. **ALB Creates Cookie:** ALB selects target, generates `AWSALB` cookie with target binding
3. **Response:** ALB returns cookie to client (`Set-Cookie: AWSALB=...`)
4. **Subsequent Requests:** Client includes `AWSALB` cookie; ALB decodes and routes to same target
5. **Cookie Expiration:** Binding expires after timeout (default: 1 day)

```
Client Perspective:
──────────────────

GET /product/123
Host: shop.example.com
(No cookies yet)
        │
        ▼
ALB selects Target B
        │
        ▼
HTTP 200 OK
Set-Cookie: AWSALB=abc123def456; Path=/; Expires=...
Content: <product page>
        │ Browser stores cookie
        ▼

GET /order
Host: shop.example.com
Cookie: AWSALB=abc123def456
        │
        ▼
ALB decodes cookie → Route to Target B (same as before)
        │
        ▼
HTTP 200 OK
Content: <checkout page>
```

**Configuration:**

```hcl
resource "aws_lb_target_group" "web" {
  name = "web-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id

  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_duration = 86400  # 1 day (in seconds)
  }
}
```

**Important Caveat:** ALB sticky cookies are bound to **target IP:port**, NOT instance identity:

```
Scenario: Backend instance i-0abc123 restarts
┌────────────────┐
│ Instance       │
│ i-0abc123      │  Original IP: 10.0.1.50
│ (Running)      │  Sticky cookie: AWSALB=binds_to_10.0.1.50:80
└────┬───────────┘
     │ Instance restart triggered
     ▼
┌────────────────┐
│ Instance       │
│ i-0abc123      │  Instance ID SAME
│ (Rebooting)    │  But IP UNCHANGED (reboot preserves EIP)
└────┬───────────┘
     │ Application restarts
     ▼
┌────────────────────────┐
│ Instance recovered     │
│ IP still 10.0.1.50:80  │
│ Application re-started │
│ PREVIOUS IN-MEMORY     │
│ STATE = LOST (new PID) │
└────────────────────────┘

Customer with AWSALB cookie still routes to 10.0.1.50:80
BUT: Session data lost (in-memory state destroyed on restart)
Result: HTTP 401 or "session not found"
```

**Best Practice:** Never rely on sticky sessions for critical state. Use distributed session stores (Redis, DynamoDB) instead.

---

#### NLB Source-IP-Based Stickiness

**Mechanism:**

NLB uses **Flow Hash Algorithm** (5-tuple hashing), which is automatic and permanent for the connection lifetime:

```
Hash Input: (protocol, src_ip, src_port, dst_ip, dst_port)
          = (TCP, 203.0.113.5, 54321, 10.0.0.100, 3306)

Hash Output: MD5(...) = 0xab12cd34...
Target Index: 0xab12cd34 % 3 = 1 (out of 3 targets)

Result: Always routes to Target 1 (deterministic)
```

**Key Difference:** NLB stickiness is:
- **Automatic:** No configuration needed; inherent to NLB design
- **Connection-level:** All packets in a flow hash to same target
- **Permanent:** For lifetime of TCP connection (hours/days possible)
- **NOT configurable:** Cannot disable 5-tuple hashing

**Use Case Example: Database Replication**

```
Client: 203.0.113.100:42000
Connects to: NLB (10.0.0.100:3306)

Connection 1: (TCP, 203.0.113.100, 42000, 10.0.0.100, 3306)
→ Hash = 1 → MySQL Replica (10.0.2.75)
→ All data operations on same replica

Connection 2: (TCP, 203.0.113.100, 42001, 10.0.0.100, 3306)
→ Hash = 2 → MySQL Replica (10.0.1.50) [Different target!]
→ Separate connection, different replica

Result: Connection pooling works; each conn reads from consistent replica
```

**Implication:** If target dies, in-flight connections *drop* (TCP RST). No graceful migration to new target.

---

#### Modern DevOps Perspective: Why Stickiness is Anti-Pattern

**Problems with Stickiness:**

1. **Uneven Load Distribution:**
   ```
   Scenario: 100 clients, 3 backends
   
   Without Stickiness (Request-Level):
   ┌────────────────────────────────────┐
   │  Requests distributed evenly       │
   │  Backend A: ~33 requests/sec      │
   │  Backend B: ~33 requests/sec      │
   │  Backend C: ~33 requests/sec      │
   │  Load: Even across all targets    │
   └────────────────────────────────────┘
   
   With Stickiness (Persistent Binding):
   ┌────────────────────────────────────┐
   │  Clients pinned to targets         │
   │  Client 1-40 → Backend A (40 req)  │
   │  Client 41-70 → Backend B (30 req) │
   │  Client 71-100 → Backend C (30)   │
   │  Load: Imbalanced                  │
   └────────────────────────────────────┘
   ```

2. **Scaling Inefficiency:**
   ```
   Scenario: Scale down from 5 to 3 backends
   
   Without Stickiness:
   - Old backend removed
   - Requests redistributed to 3 remaining (automatic load balancing)
   - No user impact (requests stateless)
   
   With Stickiness:
   - Clients stuck on old backend during drain timeout (120s)
   - Other clients see no issue on their backends
   - Reduces elasticity
   ```

3. **Failure Impact:**
   ```
   Scenario: Backend crashes mid-session
   
   Without Stickiness:
   - Request fails
   - Retry routed to healthy backend (stateless recovery)
   - User impact: Single slow request
   
   With Stickiness:
   - Client bound to dead backend
   - Connection timeout (no automatic failover)
   - Next request after timeout: Reroutes to healthy backend
   - User impact: 30+ second delay, connection reset
   ```

---

#### Load Balancing Algorithms

AWS load balancers support different algorithms for distributing traffic:

**1. Round Robin**

Distributes requests sequentially across targets:

```
Target Pool: [A, B, C]

Request 1 → A
Request 2 → B
Request 3 → C
Request 4 → A
Request 5 → B
...
```

**Pros:** Simple; minimal CPU

**Cons:** Ignores request complexity; uneven load if requests vary in duration

**Example:**
```
Request 1: GET /health (1ms) → Backend A
Request 2: GET /report (5000ms) → Backend B (CPU-heavy)
Request 3: GET /status (1ms) → Backend C

Backend A: Idle after fast request, ready for next
Backend B: Processing for 5 seconds (CPU saturated)
Backend C: Idle

Result: Uneven distribution
```

**When Used:** Not recommended for modern ALB; included for compatibility

---

**2. Least Outstanding Requests (ALB Default)**

Routes each request to the target with fewest in-flight requests:

```
At time T:
Target A: 2 in-flight requests (GET /users, GET /products)
Target B: 5 in-flight requests (heavy POST operations)
Target C: 1 in-flight request

New Request arrives
┌────────────────────────────────┐
│ ALB Count Outstanding Requests │
│ A: 2                           │
│ B: 5                           │
│ C: 1 ← Minimum               │
└────────────────────────────────┘
Decision: Route to C

Result: Even distribution by request count (adaptive)
```

**Pros:**
- Adapts to varying request duration
- Prevents overloading slow backends
- No configuration needed

**Cons:**
- Requires ALB to track request count (minor overhead)
- Not suitable for long-lived connections (WebSocket)

**When Used:** **Default and recommended for ALB**

---

**3. Flow Hash (NLB Default)**

Routes all packets in a flow to same target based on 5-tuple hash:

```
Flow: (TCP, 203.0.113.5, 54321, 10.0.0.100, 3306)

Hash = MD5(protocol || src_ip || src_port || dst_ip || dst_port) % num_targets
     = 0x...af3c % 3
     = 1

Result: Always target 1 (deterministic, no rebalancing)
```

**Pros:**
- Extremely fast (hash lookup O(1))
- Preserves connection state
- Suitable for stateful protocols

**Cons:**
- No adaptive load distribution
- Target failure = connection drop
- Not suitable for request-level balancing

**When Used:** **Only option for NLB (automatic)**

---

### Practical Code Examples

#### Terraform: Session Stickiness Configuration

```hcl
# ALB with Sticky Sessions ENABLED (Legacy)
resource "aws_lb_target_group" "stateful_legacy_app" {
  name     = "legacy-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  # Enable stickiness (NOT RECOMMENDED for modern apps)
  stickiness {
    type            = "lb_cookie"
    enabled         = true
    cookie_name     = "AWSALB"           # AWS-managed
    cookie_duration = 86400              # 1 day
  }

  deregistration_delay = 30

  tags = {
    Name = "legacy-app-tg"
  }
}

# ALB WITHOUT Stickiness (RECOMMENDED)
resource "aws_lb_target_group" "modern_stateless_app" {
  name     = "modern-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  # Stickiness DISABLED (default)
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }

  # Use distributed session store instead
  # Example: ElastiCache Redis
  
  deregistration_delay = 60

  tags = {
    Name = "modern-app-tg"
  }
}

# NLB with Connection Affinity (Automatic)
resource "aws_lb_target_group" "nlb_stateful" {
  name     = "nlb-db-cluster-tg"
  port     = 3306
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
    port                = "3306"
    protocol            = "TCP"
  }

  # NLB Flow Hash is AUTOMATIC (5-tuple)
  # Configuration not exposed in Terraform
  # (but inherent to NLB design)

  deregistration_delay = 120  # Graceful connection drain

  tags = {
    Name = "nlb-db-tg"
  }
}

# ALB with Load Balancing Algorithm Configuration
resource "aws_lb_target_group" "lob_adaptive" {
  name     = "alb-adaptive-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    matcher             = "200"
  }

  # Load Balancing Algorithm (ALB specific)
  # Options: "round_robin" (default) or "least_outstanding_requests"
  load_balancing_algorithm_type = "least_outstanding_requests"

  deregistration_delay = 60

  tags = {
    Name = "alb-adaptive-tg"
  }
}
```

#### Python Script: Simulating Stickiness vs Non-Stickiness

```python
#!/usr/bin/env python3
"""
Simulation: Load distribution with/without sticky sessions
"""

import random
from collections import defaultdict

class LoadBalancer:
    def __init__(self, num_backends=3):
        self.num_backends = num_backends
        self.backends = [f"Backend-{i}" for i in range(num_backends)]
        self.request_count = defaultdict(int)
        self.client_sessions = {}  # Maps client_id -> backend
    
    def route_round_robin(self, request_id):
        """Simple round-robin (breaks with varying request duration)"""
        target = self.backends[request_id % self.num_backends]
        self.request_count[target] += 1
        return target
    
    def route_least_outstanding(self, in_flight_counts):
        """Route to backend with fewest in-flight requests"""
        target = min(self.backends, key=lambda b: in_flight_counts[b])
        return target
    
    def route_sticky(self, client_id):
        """Sticky session: bind client to backend"""
        if client_id not in self.client_sessions:
            # First request: assign backend
            self.client_sessions[client_id] = random.choice(self.backends)
        
        target = self.client_sessions[client_id]
        self.request_count[target] += 1
        return target
    
    def route_non_sticky(self, client_id):
        """Non-sticky: each request can go to any backend"""
        target = random.choice(self.backends)
        self.request_count[target] += 1
        return target
    
    def print_distribution(self, label):
        """Print load distribution statistics"""
        print(f"\n{label}")
        print("=" * 50)
        total = sum(self.request_count.values())
        for backend, count in sorted(self.request_count.items()):
            pct = (count / total * 100) if total else 0
            bar = "█" * int(pct / 5)
            print(f"{backend:15} {count:5} ({pct:5.1f}%) {bar}")
        
        if self.request_count:
            avg = sum(self.request_count.values()) / len(self.request_count)
            max_load = max(self.request_count.values())
            imbalance = ((max_load - avg) / avg * 100) if avg else 0
            print(f"\nAvg Load per Backend: {avg:.1f}")
            print(f"Max Load: {max_load}")
            print(f"Imbalance Factor: {imbalance:.1f}%")

# Scenario 1: Varying Request Duration (Vulnerable to Round-Robin)
print("\n" + "=" * 70)
print("SCENARIO 1: Varying Request Durations")
print("=" * 70)
print(\"""
100 Clients, 3 Backends
Client 1-33 with 10ms requests
Client 34-66 with 100ms requests  
Client 67-100 with 500ms requests
\""")

lb = LoadBalancer(num_backends=3)
for client_id in range(1, 101):
    for _ in range(5):  # Each client makes 5 requests
        target = lb.route_round_robin(client_id)

lb.print_distribution("Round-Robin Result (VULNERABLE):")

# Scenario 2: Sticky Session Over-Concentration
print("\n" + "=" * 70)
print("SCENARIO 2: Sticky Session Binding")
print("=" * 70)

lb = LoadBalancer(num_backends=3)
for client_id in range(1, 101):
    for req_num in range(10):
        target = lb.route_sticky(client_id)

lb.print_distribution("Sticky Session Result (UNEVEN):")

# Scenario 3: Non-Sticky Random Distribution
lb = LoadBalancer(num_backends=3)
for client_id in range(1, 101):
    for req_num in range(10):
        target = lb.route_non_sticky(client_id)

lb.print_distribution("Non-Sticky Random Result (EVEN):")

# Scenario 4: Least Outstanding Requests (Adaptive)
print("\n" + "=" * 70)
print("SCENARIO 4: Least Outstanding Requests (Simulated)")
print("=" * 70)

in_flight = defaultdict(int)
lb = LoadBalancer(num_backends=3)

# Simulate varying request durations
request_durations = [10, 10, 10, 10] * 25  # Average clients with 10ms
for i, duration in enumerate(request_durations):
    # Reduce in-flight counts (requests completing)
    for backend in lb.backends:
        if in_flight[backend] > 0:
            in_flight[backend] -= 1
    
    # Route new request to backend with fewest in-flight
    target = lb.route_least_outstanding(in_flight)
    in_flight[target] += 1

lb.print_distribution("Least Outstanding Requests (ADAPTIVE):")

print("\n" + "=" * 70)
print("CONCLUSION")
print("=" * 70)
print("""
✓ Modern applications should use stateless design + ALB
✗ Avoid sticky sessions (causes uneven distribution, scaling issues)
✓ ALB default algorithm (Least Outstanding) is optimal for HTTP
✓ NLB flow hash is optimal for stateful protocols (TCP/UDP)
""")
```

#### Shell Script: Load Balancer Algorithm Monitoring

```bash
#!/bin/bash
# Monitor ALB request distribution vs target capacity

set -euo pipefail

ALB_NAME="${1:-}"
REGION="${AWS_REGION:-us-east-1}"
INTERVAL="${2:-60}"
DURATION="${3:-300}"  # 5 minutes default

if [[ -z "$ALB_NAME" ]]; then
  echo "Usage: $0 <alb-name> [interval-seconds] [duration-seconds]"
  exit 1
fi

echo "Monitoring ALB: $ALB_NAME"
echo "Interval: ${INTERVAL}s, Duration: ${DURATION}s"
echo ""

get_lb_metrics() {
  local LB_ARN=$(aws elbv2 describe-load-balancers \
    --region "$REGION" \
    --query "LoadBalancers[?LoadBalancerName=='$ALB_NAME'].LoadBalancerArn" \
    --output text)
  
  local LB_SHORT_NAME="${LB_ARN##*/}"
  
  # Get RequestCount metric
  aws cloudwatch get-metric-statistics \
    --region "$REGION" \
    --namespace AWS/ApplicationELB \
    --metric-name RequestCount \
    --dimensions Name=LoadBalancer,Value="$LB_SHORT_NAME" \
    --start-time "$(date -u -d "10 minutes ago" +%Y-%m-%dT%H:%M:%S)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
    --period 60 \
    --statistics Sum \
    --query 'Datapoints | sort_by(@, &Timestamp)' \
    --output json
}

monitor_distribution() {
  local start_time=$(date +%s)
  local end_time=$((start_time + DURATION))
  
  while [[ $(date +%s) -lt $end_time ]]; do
    clear
    echo "ALB Load Distribution Monitor"
    echo "=============================="
    echo "Time: $(date)"
    echo "ALB: $ALB_NAME"
    echo ""
    
    # Get target groups and health status
    local LB_ARN=$(aws elbv2 describe-load-balancers \
      --region "$REGION" \
      --query "LoadBalancers[?LoadBalancerName=='$ALB_NAME'].LoadBalancerArn" \
      --output text)
    
    aws elbv2 describe-target-groups \
      --region "$REGION" \
      --load-balancer-arn "$LB_ARN" \
      --query 'TargetGroups[0].TargetGroupName' \
      --output text | while read TG_NAME; do
        
        echo "Target Group: $TG_NAME"
        local TG_ARN=$(aws elbv2 describe-target-groups \
          --region "$REGION" \
          --load-balancer-arn "$LB_ARN" \
          --query "TargetGroups[?TargetGroupName=='$TG_NAME'].TargetGroupArn" \
          --output text)
        
        # Get target health
        aws elbv2 describe-target-health \
          --region "$REGION" \
          --target-group-arn "$TG_ARN" \
          --query 'TargetHealthDescriptions.[Target.Id, TargetHealth.State]' \
          --output text | while read TARGET_ID STATE; do
            printf "  %s: %s\n" "$TARGET_ID" "$STATE"
          done
        
        echo ""
      done
    
    # Get request count metric
    local METRICS=$(get_lb_metrics)
    if [[ $(echo "$METRICS" | jq 'length') -gt 0 ]]; then
      echo "Request Count (Last 10 minutes):"
      echo "$METRICS" | jq -r '.[] | "\(.Timestamp): \(.Sum) requests"'
    fi
    
    sleep "$INTERVAL"
  done
}

monitor_distribution
```

---

### ASCII Diagrams

#### Sticky Session vs Non-Sticky Distribution

```
SCENARIO: 100 clients, 3 backends, 10 requests each = 1000 total requests

┌──────────────────────────────────────────────────────────────────────┐
│ WITH STICKY SESSIONS ENABLED (Cookie-Based Binding)                 │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Round 1: First request from each client                             │
│  ┌───────────────────────────────────────────────────────────┐       │
│  │ Client 1-40  → Cookie → Backend A                        │       │
│  │ Client 41-70 → Cookie → Backend B                        │       │
│  │ Client 71-100 → Cookie → Backend C                       │       │
│  └───────────────────────────────────────────────────────────┘       │
│                                                                       │
│  Round 2-10: Subsequent requests (ALL use same backend)              │
│  ┌───────────────────────────────────────────────────────────┐       │
│  │ Client 1     → Cookie AWSALB=xyz → Backend A              │       │
│  │ Client 2     → Cookie AWSALB=xyz → Backend A (same!)      │       │
│  │ ...                                                        │       │
│  │ Client 40    → Cookie AWSALB=abc → Backend A (same!)      │       │
│  │ Client 41    → Cookie AWSALB=def → Backend B (different)  │       │
│  │ ...                                                        │       │
│  └───────────────────────────────────────────────────────────┘       │
│                                                                       │
│  FINAL DISTRIBUTION:                                                 │
│  Backend A: (40 clients × 10 requests) = 400 requests        ████████│
│  Backend B: (30 clients × 10 requests) = 300 requests        ██████  │
│  Backend C: (30 clients × 10 requests) = 300 requests        ██████  │
│                           Total: 1000 requests                       │
│                         Imbalance: 33% overload on A                 │
│                                                                       │
│  PROBLEM: Backend A handles 40% of traffic (potential bottleneck)   │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ WITHOUT STICKY SESSIONS (Stateless, ALB decides per-request)         │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Each request independently routed (Least Outstanding Requests)      │
│  ┌───────────────────────────────────────────────────────────┐       │
│  │ Client 1, Request 1  → Check in-flight: A=5, B=4, C=6    │       │
│  │                      → Route to B (minimum)              │       │
│  │                                                           │       │
│  │ Client 2, Request 1  → Check in-flight: A=4, B=5, C=6   │       │
│  │                      → Route to A (minimum)              │       │
│  │                                                           │       │
│  │ Client 1, Request 2  → Check in-flight: A=5, B=5, C=6   │       │
│  │                      → Route to A (can be different      │       │
│  │                         from first request)              │       │
│  └───────────────────────────────────────────────────────────┘       │
│                                                                       │
│  FINAL DISTRIBUTION (after 1000 requests):                           │
│  Backend A: ~333 requests                                    ███████ │
│  Backend B: ~333 requests                                    ███████ │
│  Backend C: ~334 requests                                    ███████ │
│                           Total: 1000 requests                       │
│                         Imbalance: <1% (nearly perfect)              │
│                                                                       │
│  BENEFIT: Even load distribution; backends can scale/fail gracefully│
└──────────────────────────────────────────────────────────────────────┘
```

#### NLB 5-Tuple Hashing Determinism

```
NLB FLOW HASH ALGORITHM
═══════════════════════

Client A (203.0.113.10:12345)
         │
         ▼
┌──────────────────────────────────────────────────┐
│ 5-Tuple Extraction                               │
│ Protocol: TCP (6)                                │
│ Source IP: 203.0.113.10                          │
│ Source Port: 12345                               │
│ Dest IP: 10.0.0.100 (NLB VIP)                   │
│ Dest Port: 3306 (MySQL)                         │
└─────────────┬────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Hash Function                                    │
│ Input: TCP|203.0.113.10|12345|10.0.0.100|3306  │
│ Algorithm: MD5                                   │
│ Output: 0x7f3a9c2e1b5d...                      │
└─────────────┬────────────────────────────────────┘
              │
              ▼
┌──────────────────────────────────────────────────┐
│ Modulo Operation                                 │
│ Hash % num_targets                               │
│ 0x7f3a9c2e1b5d... % 3                           │
│ Result: 1                                        │
└─────────────┬────────────────────────────────────┘
              │
              ▼
┌────────────────────────────────────────────────┐
│ Target Selection                                │
│ Index 0: 10.0.2.60 (Zone B)                   │
│ Index 1: 10.0.1.40 (Zone A) ← Selected        │
│ Index 2: 10.0.3.20 (Zone C)                   │
└─────────────┬──────────────────────────────────┘
              │
              ▼
    ┌──────────────────────────┐
    │ All packets in flow:     │
    │ • Client A → Server X    │
    │ • Client A → Server X    │
    │ • (Always same target)   │
    │ DETERMINISTIC ROUTING   │
    └──────────────────────────┘

NEXT CONNECTION FROM SAME CLIENT:
─────────────────────────────────

Client A (203.0.113.10:12346)  ← DIFFERENT port
         │
         ▼
5-Tuple: TCP|203.0.113.10|12346|10.0.0.100|3306
Hash: MD5(...) = 0x4a8e...
Result: 0x4a8e... % 3 = 2

Target Selection: Index 2 → 10.0.3.20 (Zone C)
                            ← DIFFERENT TARGET

Result: New connection can hash to different target
        (Each connection independent)
```

---

## SSL Termination & Certificate Management

### Textual Deep Dive

#### SSL/TLS Termination Fundamentals

**What is SSL/TLS Termination?**

SSL/TLS termination (also called "SSL offloading") moves the burden of encryption/decryption from backend application servers to the load balancer.

Without termination:
```
Client (HTTPS) 
    ↓ (encrypted: TLS handshake, cipher negotiation)
Backend Server (must decrypt, process, re-encrypt)
    ↓ (high CPU cost; blocks request processing)
```

With termination:
```
Client (HTTPS)
    ↓ (encrypted)
Load Balancer (decrypt once, manage TLS)
    ↓ (HTTP internally)
Backend Servers (process unencrypted HTTP; O(1) CPU cost)
    ↓ (network-internal communication)
```

**Why Termination Matters:**

1. **Performance:** TLS handshake (256-bit elliptic curve ~5-10ms latency per client) shifts from backend to LB
2. **Scale:** Centralizes certificate management; no need to distribute certs across 100+ backend servers
3. **Cost:** Backend CPU freed for business logic instead of encryption operation
4. **Compliance:** Inspect traffic for security (WAF integration) only possible with decrypted access
5. **Certificate Rotation:** Update single LB certificate instead of redeploying 100+ instances

---

#### TLS Versions & Cipher Suites

**AWS Load Balancer TLS Support:**

| TLS Version | Status | Use Case |
|---|---|---|
| TLS 1.3 | ✓ Recommended | Modern clients (>99% browsers); lowest latency |
| TLS 1.2 | ✓ Acceptable | Legacy support; still secure |
| TLS 1.1 | ✗ Deprecated (AWS removed) | PCI-DSS prohibits |
| TLS 1.0 | ✗ Never supported | Security risk |

**Security Policies (AWS Predefined):**

ALB/NLB include security policies that bundle TLS version + cipher suites:

| Policy | TLS Versions | Ciphers | Use Case |
|---|---|---|---|
| `ELBSecurityPolicy-TLS-1-2-2017-01` | 1.2 only | ~10 legacy ciphers | Legacy apps, broad compatibility |
| `ELBSecurityPolicy-TLS-1-2-Ext-2018-06` | 1.2 only | Modern ciphers (ECDHE, RSA-PSS) | Standard production |
| `ELBSecurityPolicy-FS-1-2-Res-2019-08` | 1.2+ | Forward secret ciphers only | High security (recommended) |
| `ELBSecurityPolicy-FS-1-2-2-2021-06` | 1.2+ | Advanced modern suites | Maximum security + TLS 1.3 |

**Best Practice Selection:**

```
Modern web app (99% modern clients):
  → Use: ELBSecurityPolicy-FS-1-2-2021-06
  → Adds TLS 1.3 support; forward secrecy ensures 
     leaked key ≠ past traffic decryption

Legacy enterprise app (IE 11, old APIs):
  → Use: ELBSecurityPolicy-TLS-1-2-2017-01
  → Broad compatibility; accept lower security
  
Regulatory requirement (PCI-DSS, HIPAA):
  → Use: ELBSecurityPolicy-FS-1-2-Res-2019-08
  → Forward secret ciphers prevent legacy server compromise
```

---

#### AWS Certificate Manager (ACM) Integration

**ACM Role in Load Balancing:**

AWS Certificate Manager provides:
- **Free certificate issuance** for domains you own
- **Auto-renewal** (90 days before expiry)
- **Automatic provisioning** to ALB/NLB/CloudFront
- **Public and private CA** support
- **BYOC (Bring Your Own Certificate)** via manual import

**Certificate Types in ALB/NLB:**

1. **Public Certificates:**
   ```
   Issued by: AWS-managed CA (DigiCert)
   Validity: 13 months
   Renewal: Automatic (if domain validation via DNS/email succeeds)
   Cost: Free for AWS-issued; paid if third-party imports
   Required for: Internet-facing ALB/NLB serving HTTPS
   ```

2. **Private Certificates:**
   ```
   Issued by: AWS Private CA
   Validity: Customizable (1-10 years)
   Renewal: Manual or auto-renew via ACM
   Cost: ~$0.75/month per private CA + $0.40 per cert
   Required for: Internal service-to-service TLS
   ```

3. **BYOC (Bring Your Own Certificate):**
   ```
   Issued by: Any CA (DigiCert, Let's Encrypt, internal PKI)
   Import to: ACM manually
   Cost: $1/certificate per month
   Renewal: Manual before expiration
   Complexity: Higher; requires cert rotation playbook
   ```

---

#### SNI (Server Name Indication) in Load Balancers

**SNI Problem & Solution:**

Traditional TLS:
```
Client: "Hello, I want to connect to server X"
    ↓
Load Balancer: "Which certificate do I use?"
    ↓ (Server TLS record uses ONE certificate per IP)
Problem: Multiple domains (api.example.com, app.example.com)
         Cannot serve both with single certificate
```

SNI (TLS 1.0+ feature):
```
Client: "Hello, I want SNI for 'api.example.com'"
    ↓ (Client sends target hostname in TLS ClientHello)
Load Balancer: "Certificate requested is api.example.com"
    ↓
Load Balancer: "Serve api.example.com certificate"
    ↓
Result: ✓ Multiple domains, single IP
```

**ALB SNI Support:**

ALB automatically uses SNI if:
- Certificate has Subject Alternative Names (SANs)
- Or multiple certificates bound to listener (each matches domain)

Example:
```
Listener: HTTPS:443
  Certificate 1: *.example.com (SANs: api.example.com, app.example.com)
  Certificate 2: *.partner.com (SAN: partner.com)

Request: api.example.com → ALB extracts SNI name → Matches Cert1 → Success ✓
Request: partner.com → ALB extracts SNI name → Matches Cert2 → Success ✓
Request: unknown.com → No matching cert → TLS error ✗
```

**NLB SNI Limitations:**

NLB supports SNI **only if TLS passthrough enabled** (no termination):
```
NLB with TLS Termination:
  ✗ Cannot use SNI; picks one certificate for listener
  ✗ Only domain in certificate accepted
  
NLB with TLS Passthrough (TCP, no decryption):
  ✓ Preserves SNI from client
  ✓ Backend handles certificate selection
  ✗ Cannot inspect traffic (WAF unavailable)
```

---

#### Certificate Renewal & Rotation Strategy

**ACM Auto-Renewal (Public Certificates):**

AWS automatically renews 90 days before expiry if:
1. **Domain Validation:** DNS CNAME validation succeeds
   - ACM creates DNS record in Route 53
   - **Requirement:** Domain's zones must be in Route 53
   
2. **Email Validation:** Not recommended for auto-renewal
   - Requires manual response to emails
   - Prone to delivery failures

**DevOps Best Practice: DNS Validation Pipeline**

```hcl
# Terraform: Request certificate with auto-renewal
resource "aws_acm_certificate" "main" {
  domain_name       = "example.com"
  validation_method = "DNS"
  
  subject_alternative_names = [
    "*.example.com",
    "api.example.com"
  ]

  tags = {
    Name = "example-certificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route 53 DNS validation records (auto-created by Terraform)
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# Trigger validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn

  timeouts {
    create = "5m"
  }
}
```

**Monitoring Certificate Expiration:**

```bash
#!/bin/bash
# Alert if certificate expires in < 30 days

REGION="us-east-1"

aws acm describe-certificate \
  --region "$REGION" \
  --certificate-arn "arn:aws:acm:us-east-1:123456789012:certificate/abc123" \
  --query 'Certificate.NotAfter' \
  --output text | while read EXPIRY_DATE; do
    
    EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    if [[ $DAYS_UNTIL_EXPIRY -lt 30 ]]; then
      echo "⚠ ALERT: Certificate expires in $DAYS_UNTIL_EXPIRY days: $EXPIRY_DATE"
    else
      echo "✓ Certificate valid for $DAYS_UNTIL_EXPIRY days"
    fi
  done
```

---

#### Common Pitfalls

1. **Mismatched Certificate Domain:**
   - **Problem:** Cert for `example.com`, ALB receives `api.example.com`
   - **Symptom:** Browser warning "Certificate doesn't match domain"
   - **Fix:** Use wildcard `*.example.com` or add SANs

2. **TLS Handshake Timeout:**
   - **Problem:** Old cipher suites timeout on modern clients
   - **Symptom:** "TLS_ALERT_TIMEOUT" errors; connection refused
   - **Fix:** Use modern policy `ELBSecurityPolicy-FS-1-2-2021-06`

3. **Expired Certificate Blocking Traffic:**
   - **Problem:** Certificate expires; auto-renewal failed (DNS validation missing)
   - **Symptom:** All HTTPS connections fail; no graceful fallback
   - **Fix:** Monitor expiration dates; ensure Route 53 zones accessible for validation

4. **Certificate Import Cost Surprise:**
   - **Problem:** Importing third-party certificates costs $1/month/cert
   - **Symptom:** Unexpected AWS bill after importing many certs
   - **Fix:** Use ACM-issued certificates (free); BYOC only when necessary

5. **NLB TLS Passthrough Limitations:**
   - **Problem:** Thinking NLB supports SNI with TLS termination
   - **Symptom:** All traffic fails; only first domain works
   - **Fix:** For multi-domain TLS, use ALB; for NLB, use TLS passthrough

---

### Practical Code Examples

#### Terraform: ALB with HTTPS & ACM Certificate

```hcl
# Request and validate ACM certificate
resource "aws_acm_certificate" "alb_cert" {
  domain_name             = "example.com"
  subject_alternative_names = ["*.example.com", "www.example.com"]
  validation_method       = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "alb-certificate"
  }
}

# Create Route 53 validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options : dvo.domain => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

# Validate certificate
resource "aws_acm_certificate_validation" "alb_cert" {
  certificate_arn = aws_acm_certificate.alb_cert.arn
  timeouts {
    create = "5m"
  }
}

# Create ALB
resource "aws_lb" "main" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Name = "example-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}

# HTTP Listener (Redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener with TLS Termination
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.alb_cert.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Host-based routing with TLS SNI
resource "aws_lb_listener_rule" "api_https" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  condition {
    host_header {
      values = ["api.example.com", "*.example.com"]
    }
  }
}
```

#### Terraform: NLB with TLS Passthrough

```hcl
# NLB with TLS Passthrough (preserve client TLS to backend)
resource "aws_lb" "nlb_tls_passthrough" {
  name               = "nlb-tls-passthrough"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "nlb-tls-passthrough"
  }
}

# Target Group (TCP, not TLS)
resource "aws_lb_target_group" "tls_servers" {
  name     = "tls-servers-tg"
  port     = 443
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    port                = "443"
    protocol            = "TCP"
  }
}

# Listener (TCP, preserves TLS handshake)
resource "aws_lb_listener" "tls_passthrough" {
  load_balancer_arn = aws_lb.nlb_tls_passthrough.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tls_servers.arn
  }
}

# Register backend servers (handle their own TLS)
resource "aws_lb_target_group_attachment" "backend1" {
  target_group_arn = aws_lb_target_group.tls_servers.arn
  target_id        = aws_instance.backend1.id
  port             = 443
}
```

#### Shell Script: Certificate Monitoring & Renewal

```bash
#!/bin/bash
# Monitor ACM certificate expiration and trigger manual renewal if needed

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
CERT_ARN="${1:-}"
ALERT_DAYS="${2:-30}"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"

if [[ -z "$CERT_ARN" ]]; then
  echo "Usage: $0 <certificate-arn> [days-before-alert]"
  exit 1
fi

# Get certificate details
CERT_INFO=$(aws acm describe-certificate \
  --region "$REGION" \
  --certificate-arn "$CERT_ARN" \
  --query 'Certificate.[DomainName, NotAfter, Status, RenewalEligibility]' \
  --output json)

DOMAIN=$(echo "$CERT_INFO" | jq -r '.[0]')
EXPIRY=$(echo "$CERT_INFO" | jq -r '.[1]')
STATUS=$(echo "$CERT_INFO" | jq -r '.[2]')
RENEWAL_ELIGIBLE=$(echo "$CERT_INFO" | jq -r '.[3]')

EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
NOW_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))

echo "Certificate Check: $DOMAIN"
echo "Status: $STATUS"
echo "Expires: $EXPIRY"
echo "Days until expiry: $DAYS_UNTIL_EXPIRY"
echo "Renewal eligible: $RENEWAL_ELIGIBLE"
echo ""

if [[ $DAYS_UNTIL_EXPIRY -lt $ALERT_DAYS ]]; then
  ALERT_MSG="⚠ ALERT: Certificate '$DOMAIN' expires in $DAYS_UNTIL_EXPIRY days ($(date -d "$EXPIRY" '+%Y-%m-%d'))"
  echo "$ALERT_MSG"
  
  # Send Slack notification
  if [[ -n "$SLACK_WEBHOOK" ]]; then
    curl -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{
        \"text\": \"$ALERT_MSG\",
        \"blocks\": [{
          \"type\": \"section\",
          \"text\": {
            \"type\": \"mrkdwn\",
            \"text\": \"*Certificate Expiration Alert*\n*Domain:* $DOMAIN\n*Expires:* $EXPIRY\n*Days Remaining:* $DAYS_UNTIL_EXPIRY\"
          }
        }]
      }"
  fi
else
  echo "✓ Certificate is valid for $DAYS_UNTIL_EXPIRY more days"
fi

# Check renewal status
if [[ "$RENEWAL_ELIGIBLE" == "INELIGIBLE" ]]; then
  echo "⚠ WARNING: Certificate is NOT eligible for renewal"
  echo "  Reason: Check domain validation DNS records in Route 53"
fi
```

#### CloudFormation: ALB with Certificate

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'ALB with HTTPS and automatic certificate management'

Parameters:
  DomainName:
    Type: String
    Description: Domain name for certificate
    Default: example.com

Resources:
  # ACM Certificate
  ALBCertificate:
    Type: AWS::CertificateManager::Certificate
    Properties:
      DomainName: !Ref DomainName
      SubjectAlternativeNames:
        - !Sub 'www.${DomainName}'
        - !Sub '*.${DomainName}'
      ValidationMethod: DNS
      DomainValidationOptions:
        - DomainName: !Ref DomainName
          ValidationDomain: !Ref DomainName

  # Application Load Balancer
  ApplicationLoadBalancer:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Type: application
      Scheme: internet-facing
      Subnets:
        - !Ref PublicSubnet1
        - !Ref PublicSubnet2
      SecurityGroups:
        - !Ref ALBSecurityGroup
      Tags:
        - Key: Name
          Value: alb-with-https

  # Security Group
  ALBSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for ALB
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

  # Target Group
  WebTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      Name: web-tg
      Port: 80
      Protocol: HTTP
      VpcId: !Ref VPC
      HealthCheckPath: /
      HealthCheckProtocol: HTTP

  # HTTP Listener (Redirect to HTTPS)
  HTTPListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: redirect
          RedirectConfig:
            Protocol: HTTPS
            Port: '443'
            StatusCode: HTTP_301
      LoadBalancerArn: !GetAtt ApplicationLoadBalancer.LoadBalancerArn
      Port: 80
      Protocol: HTTP

  # HTTPS Listener
  HTTPSListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - Type: forward
          TargetGroupArn: !GetAtt WebTargetGroup.TargetGroupArn
      LoadBalancerArn: !GetAtt ApplicationLoadBalancer.LoadBalancerArn
      Port: 443
      Protocol: HTTPS
      Certificates:
        - CertificateArn: !GetAtt ALBCertificate.CertificateArn
      SslPolicy: ELBSecurityPolicy-FS-1-2-2021-06

Outputs:
  LoadBalancerDNS:
    Description: DNS name of the ALB
    Value: !GetAtt ApplicationLoadBalancer.DNSName

  CertificateArn:
    Description: ACM Certificate ARN
    Value: !GetAtt ALBCertificate.CertificateArn
```

---

### ASCII Diagrams

#### SSL/TLS Termination Flow

```
CLIENT ↔ LOAD BALANCER ↔ BACKEND SERVERS

WITHOUT TERMINATION:
────────────────────

Client                  Load Balancer             Backend Server
│                           │                           │
├─ TLS Handshake 1 ────────►│                           │
│  (ClientHello)           │                           │
│                          │                           │
│◄───── ServerHello 2 ─────┤                           │
│       (Certificate)      │                           │
│                          │                           │
├─ CertificateVerify 3 ───►│                           │
│  (Client Finished)       │                           │
│                          │ TLS Termination         │
│                          │ Required Backend TLS   │
│                          │ Handshake ────────────►│
│                          │                  ┌─────┐│
│                          │                  │TLS  ││
│                          │                  │Hand ││
│                          │                  │shake││
│                          │                  └─────┘│
│                          │◄───────────── Encrypted Traffic
│ Encrypted ────────────────────────────────────────────►Backend
│ HTTP/1.1                  │                           │sends:
│ GET /api/users           │ (Proxy forwards)           │"200 OK"
│                          │                           │
│ Backend must:             │                           │
│ • Decrypt with CPU      │                           │
│ • Process request       │                           │
│ • Re-encrypt response   │                           │
│ TOTAL LATENCY: 30-50ms  │                           │
└────────────────────────────────────────────────────┘


WITH TERMINATION (RECOMMENDED):
───────────────────────────────

Client                  Load Balancer             Backend Server
│                           │                           │
├─ TLS Handshake ──────────►│ (Terminate here)         │
│  (ClientHello)           │ • Decrypt                 │
│                          │ • Manage certs            │
│◄─ ServerHello ─────────┤ (NO TLS)                  │
│   (Certificate)         │                           │
│                          │                           │
├─ CertificateVerify ────►│──── HTTP (plaintext) ───►│
│  (Finished)              │ GET /api/users             │
│                          │                           │
│◄─ HTTP/1.1 200 ────── ─ ◄│◄─ HTTP 200 OK ─────────┤
│   (plaintext to client)   │                           │
│                          │                           │
│                          │   Backend:               │
│ TOTAL LATENCY: 10-15ms   │   • Zero TLS CPU        │
│ (TLS done once, not      │   • Faster processing   │
│  repeated per request)   │   • Scales better       │
└────────────────────────────────────────────────────┘
```

#### Certificate Management Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│ ACM CERTIFICATE LIFECYCLE (Public Certificate)             │
└─────────────────────────────────────────────────────────────┘

Month 0: Certificate Issued
┌─────────────────────────┐
│ • Certificate created   │
│ • Domain validated      │
│ • Status: ISSUED        │
│ • Validity: 13 months   │
│ • Valid for days: 396   │
└─────────────────────────┘
         │
         └──────────────────── (Months 0-3)
                              ✓ Domain is verified
                              ✓ Grace period
                              ✗ Auto-renewal doesn't start

Month 3: Auto-Renewal Eligible
┌────────────────────────────────────────┐
│ 90 days until expiration = 306 days    │
│ AWS begins renewal attempts            │
├────────────────────────────────────────┤
│ Renewal Process:                       │
│ 1. Request new certificate              │
│ 2. Validate domain (DNS/Email)         │
│ 3. If SUCCESS: New cert issued         │
│ 4. If FAILURE: Alert, manual action    │
└────────────────────────────────────────┘
         │
         └── (Daily checks until success or expiry)
             ✓ DNS CNAME record in Route 53
             ✓ Email validation responding
             ✗ Zone deleted / Records missing = FAILS

Month 12.5: Certificate Renewed (or about to expire)
┌─────────────────────────────────────────┐
│ Scenario 1: Renewal Succeeded           │
│ • New certificate issued automatically  │
│ • ALB automatically uses new cert       │
│ • Old certificate deprecated            │
│ • Zero downtime                         │
│ • New validity: 13 months               │
│                                         │
│ Scenario 2: Renewal Failed              │
│ • Domain validation failed              │
│ • Certificate expires in 30 days        │
│ • Manual renewal required               │
│ • ⚠️ Potential service downtime         │
│ • Manual certificate import needed      │
└─────────────────────────────────────────┘
         │
         └── Month 13: Certificate Expires
             ┌─────────────────┐
             │ ✗ EXPIRED       │
             │ All HTTPS       │
             │ connections fail│
             │ Browser warning │
             │ Service down    │
             └─────────────────┘

PREVENTION: 
✓ Monitor expiration via CloudWatch Alarms
✓ Ensure Route 53 zones accessible for validation
✓ Validate renewal 30 days before expiry
```

#### SNI (Server Name Indication) in ALB

```
SCENARIO: ALB serving multiple domains with HTTPS

┌──────────────────────────────────────────────────────────┐
│ Listener Configuration:                                  │
│ Port: 443, Protocol: HTTPS                              │
│ Certificates:                                            │
│   • *.example.com (SANs: api.example.com, app.example)  │
│   • *.partner.com (SAN: partner.com)                    │
└──────────────────────────────────────────────────────────┘

REQUEST 1: Client connects to api.example.com
────────────────────────────────────────────

Client Browser              ALB                        Route
     │                       │                           │
     │ TLS ClientHello       │                           │
     │ SNI: api.example.com  │                           │
     ├──────────────────────►│                           │
     │                       │ ALB extracts SNI          │
     │                       │ SNI = "api.example.com"   │
     │                       │                           │
     │                       │ Certificate Lookup:       │
     │                       │ Does *.example.com exist? │
     │                       │ YES ✓                     │
     │                       │                           │
     │                       │ Use Certificate:          │
     │◄──────────────────────│ *.example.com             │
     │ ServerHello          │                           │
     │ Certificate          │                           │
     │ (matches SNI)        │                           │
     │                       │                           │
     │ TLS Handshake Complete│                           │
     │                       │                           │
     ├─ HTTP GET /users ────►├─ Route to Target Group   │
     │ (encrypted)           │ based on path/host rule   │
     │                       │                           │
     │◄─ 200 OK ────────────┤                           │
     │ Content: {"user1": {}}│                           │
     │                       │                           │
     └─────────────────────────────────────────────────┘

REQUEST 2: Client connects to partner.com
──────────────────────────────────────────

Client Browser              ALB                        Route
     │                       │                           │
     │ TLS ClientHello       │                           │
     │ SNI: partner.com      │                           │
     ├──────────────────────►│                           │
     │                       │ ALB extracts SNI          │
     │                       │ SNI = "partner.com"       │
     │                       │                           │
     │                       │ Certificate Lookup:       │
     │                       │ Does *.partner.com exist? │
     │                       │ YES ✓                     │
     │                       │                           │
     │                       │ Use Certificate:          │
     │◄──────────────────────│ *.partner.com             │
     │ ServerHello          │                           │
     │ Certificate          │                           │
     │ (matches SNI)        │                           │
     │                       │                           │
     ├─ HTTP GET /products ─►├─ Route to Partner        │
     │ (encrypted)           │ Service (Target Group 2)  │
     │                       │                           │
     │◄─ 200 OK ────────────┤                           │
     └─────────────────────────────────────────────────┘

RESULT: Multiple domains, single ALB, single public IP
        SNI enables certificate selection at TLS layer
```

---

## Cross-Region Load Balancing & Global Accelerator

### Textual Deep Dive

#### Cross-Region Load Balancing Patterns

**Why Cross-Region?**

Single-region deployment risks:
```
Problem 1: Regional Failure
Region: us-east-1 (Availability Zone outage, AWS service issue)
Impact: All users worldwide experience outage
RTO: 30-60 minutes (manual failover) or hours (ASG recovery)

Problem 2: Geographic Latency  
User in Tokyo: Routes to us-east-1 (~150ms latency)
User in us-west-2: Routes to us-east-1 (~60ms latency)
Result: Inconsistent performance by region

Problem 3: Data Residency Compliance
Regulation: Data must remain in EU
Issue: Single region (us-east-1) violates compliance
Fix: Deploy duplicate infrastructure in eu-west-1
```

**Cross-Region Architecture:**

```
┌───────────────┐         ┌──────────────────┐
│  US-East-1   │         │  EU-West-1      │
│  ALB + Targets│  ←Link→ │  ALB + Targets   │
│  (Primary)   │         │  (Secondary)     │
└───────────────┘         └──────────────────┘
         ↑                         ↑
         │ (Active)               │ (Standby)
         │                        │
         └────────── Route 53 ────┘
                (DNS routing policy)
                Geo-proxim / Failover
```

---

#### Route 53 Routing Policies for Load Balancing

**1. Simple Routing**

Single resource; no failover.

```
Route 53 Record:
  example.com A 203.0.113.10 (ALB IP)

Result: All traffic → Single ALB
Failover: Manual intervention required if ALB fails
```

**Rarely used; too simplistic.**

---

**2. Weighted Routing**

Distribute traffic across endpoints by percentage.

```hcl
# Route 53 configuration
resource "aws_route53_record" "weighted_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  weighted_routing_policy {
    weight = 70  # 70% traffic
  }
  
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "primary-region"
}

resource "aws_route53_record" "weighted_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  weighted_routing_policy {
    weight = 30  # 30% traffic
  }
  
  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "secondary-region"
}
```

**Use Case:** Canary deployments (90% to prod, 10% to canary)

---

**3. Failover Routing (Active-Standby)**

Active region serves traffic; if health check fails, failover to standby.

```
Primary Region (us-east-1):
  ALB ───Route 53────►100% Traffic
  ↓ (health check)
  ✓ Healthy? YES
  
Secondary Region (eu-west-1):
  ALB ───Route 53────►0% Traffic
  (Standby, waiting)

IF Primary health check fails (ALB unreachable):
  Primary: ✗ Unhealthy
  Secondary: ✓ Automatic failover
  New traffic: 100% → Secondary

RTO: ~30 seconds (DNS TTL + Route 53 health check)
```

**Configuration:**

```hcl
# Primary (active)
resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "primary"
}

# Secondary (standby)
resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "secondary"
}

# Health check for failover
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  measure_latency   = true
  
  tags = {
    Name = "primary-alb-health"
  }
}
```

**Use Case:** Disaster recovery with automatic failover

---

**4. Geolocation Routing**

Route based on geographic location (country, continent, state).

```
Query from Japan:
  Route 53 geoIP lookup
  Geographic match: Asia
  Policy: Route to ap-northeast-1 (Tokyo)
  Lower latency; data residency compliance

Query from Germany:
  Route 53 geoIP lookup
  Geographic match: Europe
  Policy: Route to eu-west-1 (Ireland)
  GDPR compliance (data stays in EU)

Query from US:
  Route 53 geoIP lookup
  Geographic match: North America
  Policy: Route to us-east-1
  Lowest latency for region
```

**Configuration:**

```hcl
# Japan routing
resource "aws_route53_record" "geo_asia" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  geolocation_routing_policy {
    continent = "AS"
  }
  
  alias {
    name                   = aws_lb.tokyo.dns_name
    zone_id                = aws_lb.tokyo.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "asia-pacific"
}

# Europe routing (GDPR)
resource "aws_route53_record" "geo_europe" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  geolocation_routing_policy {
    continent = "EU"
  }
  
  alias {
    name                   = aws_lb.ireland.dns_name
    zone_id                = aws_lb.ireland.zone_id
    evaluate_target_health = true
  }
  
  set_identifier = "europe"
}
```

**Use Case:** Global SaaS with data residency requirements

---

#### AWS Global Accelerator

**What is Global Accelerator?**

Global Accelerator is a networking service that:
1. Provides **static anycast IP addresses** for global traffic
2. Routes traffic via **AWS backbone network** (not internet)
3. Enables **active-active multi-region** (unlike Route 53 failover passive-passive)
4. Optimizes latency via **geographic proximity + routing policies**

**Comparison: Route 53 vs Global Accelerator**

| Aspect | Route 53 | Global Accelerator |
|---|---|---|
| **Layer** | DNS (Layer 7) | Network (Layer 4) |
| **Resolution** | Domain → IP address | Static IPs → Backends |
| **Multi-Region** | Passive failover | Active-active load balancing |
| **Latency Optimization** | DNS-based (geo) | Networking backbone + routing |
| **Cost** | Per-query billing | Fixed + per-GB Data transfer |
| **Use Cases** | Cross-region failover, geo-routing | Ultra-high throughput, gaming, financial |

**Global Accelerator Architecture:**

```
┌──────────────────────────────────────────────────────┐
│ Client (Anywhere in world)                           │
│ example.com resolves to Static IP: 52.84.10.x       │
└──────────┬───────────────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────────────────────────┐
│ AWS Global Accelerator (Anycast IP)                 │
│ Routes via AWS backbone network (not internet)      │
│ Intelligent routing based on geolocation + health   │
└──────────┬──────────────────┬────────────────────────┘
           │                  │
   ┌───────▼────────┐  ┌──────▼──────────┐
   │ us-east-1      │  │ eu-west-1      │
   │ ALB (Primary)  │  │ ALB (Secondary)│
   │ Targets: 100%  │  │ Targets: 100%  │
   │ (active)       │  │ (active)       │
   └────────────────┘  └─────────────────┘

Client in US: Route primarily to us-east-1 (lowest latency)
Client in EU: Route primarily to eu-west-1 (lowest latency)
If us-east-1 fails: Automatic failover to eu-west-1
```

**Endpoint Groups & Traffic Dials:**

```hcl
# Global Accelerator with endpoint groups
resource "aws_globalaccelerator_accelerator" "main" {
  name            = "example-ga"
  enabled         = true
  ip_address_type = "IPV4"

  tags = {
    Name = "example-ga"
  }
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.arn
  port_ranges {
    from_port = 80
    to_port   = 80
  }
  protocol = "TCP"
}

# US East Endpoint Group
resource "aws_globalaccelerator_endpoint_group" "us_east" {
  listener_arn          = aws_globalaccelerator_listener.main.arn
  endpoint_group_region = "us-east-1"
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = aws_lb.primary.arn
    weight      = 100
  }

  health_check_interval_seconds = 30
  health_check_path             = "/health"
  health_check_protocol         = "HTTP"
  health_check_port             = 80
  threshold_count               = 3
}

# EU West Endpoint Group
resource "aws_globalaccelerator_endpoint_group" "eu_west" {
  listener_arn          = aws_globalaccelerator_listener.main.arn
  endpoint_group_region = "eu-west-1"
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = aws_lb.secondary.arn
    weight      = 100
  }
}
```

**Benefits:**

1. **Static IPs:** Clients use fixed IPs (enables IP whitelisting)
2. **Active-Active:** All regions serve traffic simultaneously
3. **Intelligent Routing:** Uses AWS backbone + latency measurements
4. **DDoS Protection:** Integrated AWS Shield Standard + enhanced
5. **Consistent IP:** Works across clients (no DNS TTL issues)

**Cost:** $0.025/hour + data transfer charges (no query-based billing)

---

### Practical Code Examples

#### Terraform: Route 53 Failover with Health Checks

```hcl
# Primary Region (us-east-1)
resource "aws_lb" "primary" {
  name               = "primary-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.primary1.id, aws_subnet.primary2.id]

  tags = {
    Name = "primary-alb"
  }
}

# Secondary Region (eu-west-1)
resource "aws_lb" "secondary" {
  name               = "secondary-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.secondary1.id, aws_subnet.secondary2.id]
  provider           = aws.eu_west_1

  tags = {
    Name = "secondary-alb"
  }
}

# Health Check for Primary Region
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 2
  measure_latency   = true

  tags = {
    Name = "primary-health"
  }
}

# Health Check for Secondary Region
resource "aws_route53_health_check" "secondary" {
  fqdn              = aws_lb.secondary.dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 2
  measure_latency   = true

  tags = {
    Name = "secondary-health"
  }
}

# Failover Record: Primary (Active)
resource "aws_route53_record" "failover_primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }

  set_identifier = "primary-region"
  health_check_id = aws_route53_health_check.primary.id
}

# Failover Record: Secondary (Standby)
resource "aws_route53_record" "failover_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "example.com"
  type    = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }

  set_identifier = "secondary-region"
  health_check_id = aws_route53_health_check.secondary.id
}

# CloudWatch Alarm for failover alerting
resource "aws_cloudwatch_metric_alarm" "health_check_failed" {
  alarm_name          = "route53-failover-triggered"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

#### Terraform: AWS Global Accelerator

```hcl
# Global Accelerator
resource "aws_globalaccelerator_accelerator" "main" {
  name            = "example-ga"
  ip_address_type = "IPV4"
  enabled         = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = aws_s3_bucket.ga_logs.id
    flow_logs_s3_prefix = "flow-logs/"
  }

  tags = {
    Name = "example-ga"
  }
}

# Listener
resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.arn
  
  port_ranges {
    from_port = 80
    to_port   = 80
  }

  port_ranges {
    from_port = 443
    to_port   = 443
  }

  protocol = "TCP"
}

# US East Endpoint Group
resource "aws_globalaccelerator_endpoint_group" "us_east" {
  listener_arn          = aws_globalaccelerator_listener.main.arn
  endpoint_group_region = "us-east-1"
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = aws_lb.us_east.arn
    weight      = 100
  }

  health_check_interval_seconds = 10
  health_check_path             = "/health"
  health_check_protocol         = "HTTPS"
  health_check_port             = 443
  threshold_count               = 3
}

# EU West Endpoint Group
resource "aws_globalaccelerator_endpoint_group" "eu_west" {
  listener_arn          = aws_globalaccelerator_listener.main.arn
  endpoint_group_region = "eu-west-1"
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = aws_lb.eu_west.arn
    weight      = 100
  }

  health_check_interval_seconds = 10
  health_check_path             = "/health"
  health_check_protocol         = "HTTPS"
  health_check_port             = 443
  threshold_count               = 3
}

# APAC Endpoint Group
resource "aws_globalaccelerator_endpoint_group" "ap_southeast" {
  listener_arn          = aws_globalaccelerator_listener.main.arn
  endpoint_group_region = "ap-southeast-1"
  traffic_dial_percentage = 100

  endpoint_configuration {
    endpoint_id = aws_lb.ap_southeast.arn
    weight      = 100
  }
}

# Route 53: Alias to Global Accelerator
resource "aws_route53_record" "ga_alias" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "global.example.com"
  type    = "A"

  alias {
    name                   = aws_globalaccelerator_accelerator.main.dns_name
    zone_id                = aws_globalaccelerator_accelerator.main.zone_id
    evaluate_target_health = false  # GA has built-in health checks
  }
}

# Output static IPs
output "ga_static_ips" {
  value = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
}
```

#### Shell Script: Cross-Region Failover Monitoring

```bash
#!/bin/bash
# Monitor Route 53 failover status and endpoint health

set -euo pipefail

ZONE_ID="${1:-}"
DOMAIN="${2:-}"
REGION="${AWS_REGION:-us-east-1}"

if [[ -z "$ZONE_ID" ]] || [[ -z "$DOMAIN" ]]; then
  echo "Usage: $0 <route53-zone-id> <domain>"
  exit 1
fi

echo "Route 53 Failover Status Monitor"
echo "=================================="
echo "Domain: $DOMAIN"
echo "Zone: $ZONE_ID"
echo ""

# Get all records for domain
RECORDS=$(aws route53 list-resource-record-sets \
  --region "$REGION" \
  --hosted-zone-id "$ZONE_ID" \
  --query "ResourceRecordSets[?Name=='${DOMAIN}.']" \
  --output json)

# Filter failover records
echo "Failover Records:"
echo "$RECORDS" | jq -r '.[] | select(.Failover != null) | 
  {
    Type: .Type,
    SetId: .SetIdentifier,
    Failover: .Failover,
    HealthCheckId: .HealthCheckId,
    AliasTarget: .AliasTarget.DNSName
  }' | jq -r '@csv'

echo ""
echo "Health Check Status:"

# Get health check IDs from records
HEALTH_CHECK_IDS=$(echo "$RECORDS" | jq -r '.[] | select(.HealthCheckId != null) | .HealthCheckId' | sort -u)

for HEALTH_CHECK_ID in $HEALTH_CHECK_IDS; do
  HEALTH_STATUS=$(aws route53 get-health_check_status \
    --region "$REGION" \
    --health_check_id "$HEALTH_CHECK_ID" \
    --query 'HealthCheckObservations[0].[StatusReport.Status, StatusReport.Description]' \
    --output text)
  
  STATUS=$(echo "$HEALTH_STATUS" | awk '{print $1}')
  DESC=$(echo "$HEALTH_STATUS" | cut -d' ' -f2-)
  
  if [[ "$STATUS" == "Success" ]]; then
    ICON="✓"
  else
    ICON="✗"
  fi
  
  echo "$ICON Health Check: $HEALTH_CHECK_ID - $STATUS"
done

echo ""
echo "Current Active Region:"

# Query DNS; resolve to IP
RESOLVED_IP=$(dig +short "$DOMAIN" @8.8.8.8 | head -1)

if [[ -n "$RESOLVED_IP" ]]; then
  echo "Resolved IP: $RESOLVED_IP"
  
  # Identify which region (simplified; would require IP-to-region mapping)
  echo "Region: [Lookup from Route 53 alias targets]"
else
  echo "✗ Unable to resolve domain"
fi
```

---

### ASCII Diagrams

#### Route 53 Failover Architecture

```
┌────────────────────────────────────────────────────────────────┐
│ ROUTE 53 FAILOVER: Active-Standby Architecture                │
└────────────────────────────────────────────────────────────────┘

NORMAL OPERATION (Healthcare Check Passing):
═════════════════════════════════════════════

     Client Query                           Route 53 Zone
          │                                      │
     "What is example.com?"   ───query───────►  │
          │                                      │
          │  ┌────────────────────────────────┐ │
          │  │ Failover Record Set:           │ │
          │  │ PRIMARY: example.com           │ │
          │  │  └─ Target: ALB-us-east-1    │ │
          │  │  └─ Health Check: PASSING ✓  │ │
          │  │ SECONDARY: example.com        │ │
          │  │  └─ Target: ALB-eu-west-1    │ │
          │  │  └─ (Standby, unused)        │ │
          │  └────────────────────────────────┘ │
          │                                      │
          │◄──────return ALB-us-east-1───────────
     "example.com = 203.0.113.10 (us-east-1)" 
          │
     203.0.113.10 = ALB Primary (us-east-1)
          │
          ▼
     ┌─────────────────┐
     │  us-east-1 ALB  │
     │  Serving Traffic│
     │  ✓ Healthy      │
     └─────────────────┘


FAILOVER CONDITION (Primary Region Down):
═══════════════════════════════════════════

     Client Query                           Route 53 Zone
          │                                      │
     "What is example.com?"   ───query───────►  │
          │                                      │
          │  ┌────────────────────────────────┐ │
          │  │ Failover Record Set:           │ │
          │  │ PRIMARY: example.com           │ │
          │  │  └─ Target: ALB-us-east-1    │ │
          │  │  └─ Health Check: FAILING ✗  │ │
          │  │  └─ (Exclude from response)  │ │
          │  │                                │ │
          │  │ SECONDARY: example.com        │ │
          │  │  └─ Target: ALB-eu-west-1    │ │
          │  │  └─ Health Check: PASSING ✓  │ │
          │  │  └─ (Return this one)        │ │
          │  └────────────────────────────────┘ │
          │                                      │
          │◄──────return ALB-eu-west-1────────────
     "example.com = 198.51.100.20 (eu-west-1)"
          │
     198.51.100.20 = ALB Secondary (eu-west-1)
          │
          ▼
     ┌──────────────────┐
     │  eu-west-1 ALB   │
     │  Serving Traffic │
     │  (Failover)      │
     │  ✓ Healthy       │
     └──────────────────┘

RECOVERY (Primary Back Online):
════════════════════════════════

     Health Check: ALB-us-east-1
          │
          ▼
     Consecutive Healthy Checks: 2/2
          │
          ▼
     Status: PASSING ✓
          │
          ▼
     Next Client Query:
     Route 53 returns: ALB-us-east-1
          │
          ▼
     Traffic automatically shifts back to Primary
     (Optional: Gradual weighted shift)
```

#### Global Accelerator Multi-Region Routing

```
┌────────────────────────────────────────────────────────────┐
│ GLOBAL ACCELERATOR: Active-Active Multi-Region            │
└────────────────────────────────────────────────────────────┘

GLOBAL ACCELERATOR IP: 52.84.10.5 (Anycast)

┌─────────────────────────────────────────────────────────┐
│  Clients Worldwide                                      │
│  all.use.example.com resolves to 52.84.10.5 (Anycast) │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴──────────────────┬─────────┐
        │                                │         │
   Client in USA              Client in EU     Client in APAC
   (Virginia)                (Frankfurt)       (Singapore)
        │                         │               │
        ▼                         ▼               ▼
   
   AWS Backbone Network
   (Not Internet)
        │                         │               │
   Anycast IP Edge               |              |
   (Closest to client)            │              │
        │                         │              │
        │ (Intelligent           │              │
        │  Routing based on      │              │
        │  Latency + Health)     │              │
        │                        │              │
        ▼                        ▼              ▼
   
   ┌──────────────┐      ┌──────────────┐  ┌──────────────┐
   │  us-east-1   │      │ eu-west-1    │  │ap-southeast-1│
   │  ALB         │      │ ALB          │  │ALB           │
   │  Endpoint    │      │ Endpoint     │  │Endpoint      │
   │  Group       │      │ Group        │  │Group         │
   │              │      │              │  │              │
   │  Traffic: 45%│      │ Traffic: 30% │  │Traffic: 25%  │
   │  (per dial)  │      │ (per dial)   │  │(per dial)    │
   └──────────────┘      └──────────────┘  └──────────────┘
        │                     │                  │
        ▼                     ▼                  ▼
   
   Target Groups:           Target Groups:     Target Groups:
   • EC2 instances in us-e1 • EC2 instances in • EC2 instances
   • (Serving content)      eu-w1              in apac
   • ✓ Healthy              • ✓ Healthy         • ✓ Healthy
   • 100% active (not       • 100% active      • 100% active
   standby)


KEY ADVANTAGES:
───────────────

1. ACTIVE-ACTIVE: All regions serve traffic simultaneously
   (vs Route 53 failover: one primary, others standby)

2. STATIC IP: 52.84.10.5 never changes
   (vs Route 53: IPs change during failover)

3. INTELLIGENT ROUTING:
   • Measures latency to each endpoint
   • Routes through AWS backbone (lowest latency)
   • Automatic health-based failover

4. DDoS PROTECTION:
   • Static IPs enable WAF IP allowlisting
   • AWS Shield Standard included
   • Enhanced Shield optional

5. TRAFFIC DIALS:
   • Adjust percentage per region on-the-fly
   • Canary deployments: 95% to prod, 5% to canary
   • No code/certificate changes


FAILOVER EXAMPLE: us-east-1 Region Failure
───────────────────────────────────────────

Before:
  Client in USA → GA → Route to us-east-1 ALB (Lowest latency)

After (us-east-1 health check fails):
  Global Accelerator detects unhealthy endpoint
        │
        ▼
  Excludes us-east-1 from routing
        │
        ▼
  Routes to next-best region (eu-west-1 or apac)
        │
        ▼
  Higher latency (user experiences slower performance)
        │
        ▼
  Manual operator intervention:
  • Scale up standby region
  • Investigate us-east-1 failure
  • Restore or permanently shift workload
```

---

## Monitoring & Troubleshooting Load Balancers

### Textual Deep Dive

#### CloudWatch Metrics for Load Balancers

**Key Metrics Categories:**

1. **Request-Level Metrics (ALB/NLB):**

| Metric | Definition | Interpretation | Alert Threshold |
|---|---|---|---|
| **RequestCount** | Total requests processed | Traffic volume | N/A (informational) |
| **TargetResponseTime** | Time from LB sends request to response received | Backend latency | >500ms indicates slow backend |
| **RequestCountPerTarget** | Average requests per healthy target | Load distribution | >(TotalRequests/TargetCount)*1.25 = skewed |
| **HTTPCode_Target_5XX_Count** | HTTP 5xx errors from backends | Application errors | >1% of total requests |
| **HTTPCode_Target_4XX_Count** | HTTP 4xx errors from backends | Client/validation errors | Monitor for unusual spikes |
| **HTTPCode_ELB_5XX_Count** | HTTP 5xx errors from load balancer | LB misconfiguration | Any non-zero value suspicious |

2. **Connection-Level Metrics (NLB):**

| Metric | Definition | Interpretation |
|---|---|---|
| **ActiveConnectionCount** | Concurrent connections | Persistent connections (WebSocket, SSH) |
| **NewConnectionCount** | New connections / minute | Connection churn |
| **ProcessedBytes** | Bytes processed | Throughput indicator |

3. **Target Health Metrics:**

| Metric | Definition | Alert Threshold |
|---|---|---|
| **HealthyHostCount** | Targets in "healthy" state | =0 = total outage |
| **UnhealthyHostCount** | Targets in "unhealthy" state | >25% = partial outage risk |

---

#### Access Logging for Deep Investigation

ALB/NLB can log every request to S3 for forensic analysis.

**Access Log Format (ALB):**

```
type time elb client:port target:port request_processing_time target_processing_time response_processing_time elb_status_code target_status_code received_bytes sent_bytes request trace_id domain_name domain_name_encoded choose_port trace_id matched_rule_priority new_field

Example:
http 2024-03-07T10:15:23.123456Z app-lb-123456789.us-east-1.elb.amazonaws.com 203.0.113.10:54321 10.0.1.50:80 0.001 0.043 0.0003 200 200 34 1256 GET http://example.com:80/api/users?id=123 HTTP/1.1 curl/7.64.1 - - arn:aws:... - Root=1-5e64a8b3-0000000000000000 example.com example.com - -
```

**Parsing Access Logs with Athena:**

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS alb_logs (
    etype STRING,
    time STRING,
    elb STRING,
    client_ip STRING,
    client_port INT,
    target_ip STRING,
    target_port INT,
    request_processing_time DOUBLE,
    target_processing_time DOUBLE,
    response_processing_time DOUBLE,
    elb_status_code INT,
    target_status_code INT,
    received_bytes INT,
    sent_bytes INT,
    request_verb STRING,
    request_url STRING,
    request_proto STRING,
    user_agent STRING,
    ssl_cipher STRING,
    ssl_protocol STRING,
    target_group_arn STRING,
    trace_id STRING
)
PARTITIONED BY (region STRING, year STRING, month STRING, day STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
    'serialization.format' = '1',
    'input.regex' = 
    '([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^ ]*) ([^ ]*) (- |[^ ]*)\" \"([^\"]*)\" ([A-Z0-9-]+) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^ ]*)\" \"([^\s]*)\" \"([^ ]*)\" \"([^ ]*)\"'
)
LOCATION 's3://your-bucket/prefix/AWSLogs/your-account-id/elasticloadbalancing/us-east-1/'

-- Find slow requests
SELECT 
    client_ip,
    request_url,
    target_processing_time,
    target_ip
FROM alb_logs
WHERE 
    day = '07'
    AND month = '03'
    AND year = '2024'
    AND target_processing_time > 1.0  -- Requests taking >1 second
ORDER BY target_processing_time DESC
LIMIT 100;

-- Find 5xx errors
SELECT 
    target_ip,
    target_status_code,
    COUNT(*) as error_count,
    ROUND(100.0 * COUNT(*) / SUM(1) OVER (), 2) as error_pct
FROM alb_logs
WHERE 
    day = '07'
    AND target_status_code >= 500
GROUP BY target_ip, target_status_code
ORDER BY error_count DESC;
```

---

#### CloudWatch Alarms & Anomaly Detection

```hcl
# Alarm: High Error Rate
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "alb-high-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10  # >10 errors/minute
  alarm_description   = "Alert if backend error rate exceeds 10 errors/min"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# Alarm: Slow Response Times
resource "aws_cloudwatch_metric_alarm" "high_latency" {
  alarm_name          = "alb-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0.5  # >500ms average
  alarm_description   = "Alert if average response time >500ms"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# Alarm: Unhealthy Targets
resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "alb-unhealthy-targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1  # Any unhealthy target
  alarm_description   = "Alert if any target becomes unhealthy"
  alarm_actions       = [aws_sns_topic.page_oncall.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.web.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

# Anomaly Detection Alarm
resource "aws_cloudwatch_metric_alarm" "anomaly_request_count" {
  alarm_name          = "alb-anomaly-request-count"
  comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "Alert if request rate deviates from baseline"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "m1"
    return_data = true
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"  # 2 std devs
    return_data = true
  }
}
```

---

#### Common Troubleshooting Scenarios

**Scenario 1: All Targets Unhealthy**

```
Symptom: HTTP 504 Gateway Timeout

Root Causes:
1. Security Group misconfiguration
   - Backend SG doesn't allow traffic from ALB SG
   - Fix: aws ec2 authorize-security-group-ingress \
            --group-id sg-target \
            --source-group sg-alb \
            --protocol tcp --port 80
       
2. Health Check Failing
   - Wrong path: GET /health returns 404
   - Port mismatch: ALB checks :8080, backend on :80
   - Fix: Verify path returns 200 OK; match ports
   
3. Network ACL blocking
   - Ephemeral port range (1024-65535) for outbound
   - Fix: Allow 0.0.0.0/0 on ephemeral range

4. Backend application crashed
   - Process not running
   - Out of memory (OOM kill)
   - Fix: SSH to instance; check logs; restart service
```

**Scenario 2: Intermittent Failures (Flapping Targets)**

```
Symptom: Targets alternate between healthy/unhealthy

Root Causes:
1. Health Check Timeout Too Aggressive
   - Timeout: 2s, Backend slow on startup (>2s)
   - Fix: Increase timeout to 5s
   
2. Undersized Backend
   - CPU at 100%; health check times out
   - Fix: Scale up instance type or add more targets
   
3. Database Connection Exhaustion
   - Backend makes DB connections, pool exhausted
   - Fix: Check DB connection limits; enable pooling
   
4. Network Congestion
   - Inter-AZ traffic bottleneck
   - Fix: Monitor network metrics; scale load balancer
```

**Scenario 3: Uneven Load Distribution**

```
Symptom: RequestCountPerTarget varies 3x across targets

Root Causes:
1. Stickiness Enabled
   - Clients bound to specific targets
   - Fix: Disable stickiness unless required
   
2. Wrong Algorithm
   - Using Round Robin instead of Least Outstanding Requests
   - Fix: Set load_balancing_algorithm_type = "least_outstanding_requests"
   
3. Request Duration Variance
   - Heavy requests (image upload) vs light (status check)
   - Fix: Use Least Outstanding Requests algorithm
   
4. Cross-Zone Load Balancing Disabled
   - All targets in AZ A exhausted; AZ B idle
   - Fix: Enable cross-zone (ALB free; NLB costs $0.006/LCU-hour)
```

---

### Practical Code Examples

#### Terraform: Comprehensive Monitoring Setup

```hcl
# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  bucket = "alb-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Enable ALB logging
resource "aws_lb" "main" {
  name               = "monitored-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    enabled = true
    prefix  = "alb-logs"
  }

  tags = {
    Name = "monitored-alb"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = "alb-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", { stat = "Sum", label = "Total Requests" }],
            [".", "HTTPCode_Target_5XX_Count", { stat = "Sum", label = "5XX Errors" }],
            [".", "TargetResponseTime", { stat = "Average", label = "Avg Response Time" }],
            [".", "UnhealthyHostCount", { stat = "Average", label = "Unhealthy Targets" }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ALB Performance Metrics"
          yAxis = {
            left  = { min = 0 }
            right = { min = 0 }
          }
        }
      },
      {
        type = "log"
        properties = {
          query   = "fields @timestamp, target_processing_time | stats avg(target_processing_time) as avg_latency"
          region  = var.region
          title   = "Backend Latency (from Logs)"
        }
      }
    ]
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alb_alerts" {
  name = "alb-monitoring-alerts"
}

resource "aws_sns_topic_subscription" "alb_alerts_email" {
  topic_arn = aws_sns_topic.alb_alerts.arn
  protocol  = "email"
  endpoint  = "devops@example.com"
}

# Alarms
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "alb-http-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert on >5 5XX errors per minute"
  alarm_actions       = [aws_sns_topic.alb_alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "alb-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alert if any target becomes unhealthy"
  alarm_actions       = [aws_sns_topic.alb_alerts.arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.web.arn_suffix
    LoadBalancer = aws_lb.main.arn_suffix
  }
}
```

#### Shell Script: Comprehensive LB Troubleshooting

```bash
#!/bin/bash
# Comprehensive Load Balancer Diagnostics

set -euo pipefail

LB_NAME="${1:-}"
REGION="${AWS_REGION:-us-east-1}"

if [[ -z "$LB_NAME" ]]; then
  echo "Usage: $0 <load-balancer-name>"
  exit 1
fi

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║         Load Balancer Comprehensive Diagnostics Report             ║"
echo "║                     Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)                      ║"
echo "╚════════════════════════════════════════════════════════════════════╝"

# Get LB details
LB_ARN=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --query "LoadBalancers[?LoadBalancerName=='$LB_NAME'].LoadBalancerArn" \
  --output text)

echo ""
echo "━━━ 1. LOAD BALANCER CONFIGURATION ━━━"
aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --load-balancer-arns "$LB_ARN" \
  --query 'LoadBalancers[0].[LoadBalancerName, LoadBalancerArn, Type, Scheme, State.Code, DNSName]' \
  --output table

# Listeners
echo ""
echo "━━━ 2. LISTENERS ━━━"
aws elbv2 describe-listeners \
  --region "$REGION" \
  --load-balancer-arn "$LB_ARN" \
  --query 'Listeners.[Port, Protocol, DefaultActions[0].Type]' \
  --output table

# Target Groups
echo ""
echo "━━━ 3. TARGET GROUPS ━━━"
TG_ARNS=$(aws elbv2 describe-target-groups \
  --region "$REGION" \
  --load-balancer-arn "$LB_ARN" \
  --query 'TargetGroups[].TargetGroupArn' \
  --output text)

for TG_ARN in $TG_ARNS; do
  TG_NAME=$(aws elbv2 describe-target-groups \
    --region "$REGION" \
    --target-group-arns "$TG_ARN" \
    --query 'TargetGroups[0].TargetGroupName' \
    --output text)
  
  echo ""
  echo "Target Group: $TG_NAME"
  
  # Target health
  HEALTH=$(aws elbv2 describe-target-health \
    --region "$REGION" \
    --target-group-arn "$TG_ARN" \
    --query 'TargetHealthDescriptions.[Target.Id, TargetHealth.State, TargetHealth.Reason, TargetHealth.Description]' \
    --output json)
  
  HEALTHY=$(echo "$HEALTH" | jq '[.[] | select(.State == "healthy")] | length')
  UNHEALTHY=$(echo "$HEALTH" | jq '[.[] | select(.State == "unhealthy")] | length')
  DRAINING=$(echo "$HEALTH" | jq '[.[] | select(.State == "draining")] | length')
  
  echo "  Status: $HEALTHY healthy, $UNHEALTHY unhealthy, $DRAINING draining"
  
  if [[ $UNHEALTHY -gt 0 ]]; then
    echo "  ⚠ Unhealthy Targets:"
    echo "$HEALTH" | jq -r '.[] | select(.State != "healthy") | "    - \(.Target.Id): \(.State) (\(.Description // "no description"))"'
  fi
done

# CloudWatch Metrics (Last Hour)
echo ""
echo "━━━ 4. CLOUDWATCH METRICS (Last 1 Hour) ━━━"

LB_SHORT=$(echo "$LB_ARN" | awk -F: '{print $NF}')

aws cloudwatch get-metric-statistics \
  --region "$REGION" \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value="$LB_SHORT" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
  --period 300 \
  --statistics Sum Average \
  --query 'Datapoints | sort_by(@, &Timestamp)' \
  --output json | jq -r '.[] | "\(.Timestamp): Sum=\(.Sum) Avg=\(.Average)"'

# Get 5XX error metrics
echo ""
echo "Target 5XX Errors (Last Hour):"
aws cloudwatch get-metric-statistics \
  --region "$REGION" \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value="$LB_SHORT" \
  --start-time "$(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
  --period 300 \
  --statistics Sum \
  --query 'Datapoints | sort_by(@, &Timestamp) | reverse(@)[0]' \
  --output json | jq '.Sum // "No errors"'

# Security Group Rules
echo ""
echo "━━━ 5. SECURITY GROUP RULES ━━━"
SG_IDS=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --load-balancer-arns "$LB_ARN" \
  --query 'LoadBalancers[0].SecurityGroups[]' \
  --output text)

for SG in $SG_IDS; do
  echo ""
  echo "Security Group: $SG"
  aws ec2 describe-security-group-rules \
    --region "$REGION" \
    --filters "Name=group-id,Values=$SG" "Name=is-egress,Values=false" \
    --query 'SecurityGroupRules.[IpProtocol, FromPort, ToPort, CidrIpv4, Description]' \
    --output table
done

# Recommendations
echo ""
echo "━━━ 6. RECOMMENDATIONS ━━━"

# Check for unhealthy targets
TOTAL_UNHEALTHY=0
for TG_ARN in $TG_ARNS; do
  UNHEALTHY=$(aws elbv2 describe-target-health \
    --region "$REGION" \
    --target-group-arn "$TG_ARN" \
    --query 'TargetHealthDescriptions | length(@)' \
    --output text)
  TOTAL_UNHEALTHY=$((TOTAL_UNHEALTHY + UNHEALTHY))
done

if [[ $TOTAL_UNHEALTHY -gt 0 ]]; then
  echo "⚠ Action Required: Investigate unhealthy targets"
  echo "  - Check backend application logs"
  echo "  - Verify security group ingress rules"
  echo "  - Check health check configuration"
fi

echo ""
echo "✓ Diagnostics complete. Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---

### ASCII Diagrams

#### CloudWatch Metrics Dashboard View

```
┌─────────────────────────────────────────────────────────────────────┐
│ ALB MONITORING DASHBOARD (CloudWatch)                              │
└─────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────┬────────────────────────────────┐
│  Request Count (All Time)          │  Response Time (Last Hour)     │
│      ┌─────────────────┐           │      ┌─────────────────┐      │
│ 5K  │█████████████    │           │ 1.0s │          ╱╲      │      │
│ 4K  │███████████████  │           │      │        ╱  ╲___  │      │
│ 3K  │██████████████   │           │ 0.5s │      ╱        ╲ │      │
│ 2K  │█████████        │           │      │    ╱            │      │
│ 1K  │████             │           │  0s  │──────────────── │      │
│  0  └─────────────────┘           │      └─────────────────┘      │
│     ▁▂▃▄▅▆▇█ (time)               │     ▁▂▃▄▅▆▇█ (time)           │
│     SUM = 48,245 req/hr           │     AVG = 123ms, P99 = 456ms  │
└────────────────────────────────────┴────────────────────────────────┘

┌────────────────────────────────────┬────────────────────────────────┐
│  Target Health Status              │  Error Rate (5XX Count)        │
│                                    │                                │
│  Total Targets: 6                  │      ┌─────────────────┐       │
│  ✓ Healthy: 6                      │    5 │                 │       │
│  ✗ Unhealthy: 0                    │      │  ●●●            │       │
│  ⟳ Draining: 0                     │    0 │  ● ●            │       │
│                                    │      └─────────────────┘       │
│  Health Check Pass Rate: 99.9%     │      Peak: 3 errors @ 14:32   │
└────────────────────────────────────┴────────────────────────────────┘

ALARM STATUS:
─────────────
[⌛] ALB-HTTP-5XX-ERRORS ........ OK (threshold: >5/min)
[⌛] ALB-UNHEALTHY-HOSTS ........ OK (threshold: >=1)
[⌛] ALB-HIGH-LATENCY ........... OK (threshold: >500ms avg)
[✓] ALB-ANOMALY-REQUEST-COUNT .. OK (within normal range)

RECENT LOGS:
────────────
14:35:22 | 203.0.113.100 | GET /api/users | 200 | 45ms
14:35:21 | 203.0.113.101 | POST /orders  | 500 | 2100ms ⚠
14:35:20 | 203.0.113.102 | GET /health   | 200 | 2ms
14:35:19 | 203.0.113.103 | GET /products | 200 | 78ms
```

#### Troubleshooting Decision Tree

```
┌──────────────────────────────────────────────────────────┐
│  Load Balancer Not Responding / Errors Occurring        │
└──────────────────────────────┬───────────────────────────┘
                               │
             ┌─────────────────┼─────────────────┐
             │                 │                 │
        HTTP Status?      CloudWatch          SG Rules?
         /    |    \       Metrics?         /        \
      500  503  502     /        \       Allow   Blocked
       │     │    │    /          \       │         │
       ▼     ▼    ▼   ▼            ▼      ▼         ▼
                                                     
    Server  Gateway No         5XX      Fix:
    Error   Timeout Route      Errors    aws ec2 authorize-
            │       │          │         security-group-
            │       │          │         ingress \
            │       │          │         --group-id sg-target \
            ▼       ▼          ▼         --protocol tcp \
                                        --port 80
    Backend Health     No
    App down check      Route
            │          pass
            │              │
            ▼              ▼
                           
    SSH to      All      Some      
    instance    Pass     Fail
    Check:        │         │
    • Logs        │         ▼
    • Process     │      Health Check
    • Disk        │      Issue:
    • Memory      │      • Wrong path
                  │      • port mismatch
                  │      • timeout too low
                  │      
                  ▼      Fix: Update
                         health check
            All Healthy   config
                  │
                  ▼
            
            Check Load
            Distribution
                  │
        ┌─────────┼──────────┐
        │         │          │
      Even    Uneven    Flapping
        │         │          │
        ✓OK      Fix:       Fix:
        │      • Disable    • Increase
        │        stickiness   timeout
        │      • Algo =     • Scale up
        │        least_out  • Check DB
        │        standing   • Check SG
        │      • Enable
        │        cross-zone
        │
        ▼
    Full Diagnostics
    Passed ✓
```

---

## Hands-on Scenarios

### Scenario 1: Emergency Failover - Regional Outage Mitigation

**Problem Statement:**

Your company runs a critical SaaS platform serving 50M requests/day from a single ALB in us-east-1. At 02:45 UTC, an AWS networking incident cascades through the region, affecting load balancer node communication. Health checks start failing; within 3 minutes, all traffic to your application is returning HTTP 504 Gateway Timeout.

**Architecture Context:**

- **Primary Region:** us-east-1 with 12-target ALB
- **Secondary Region:** eu-west-1 with standby ALB (identical configuration, no traffic)
- **DNS:** Route 53 hosted zone with failover records
- **Database:** RDS Multi-AZ (us-east-1), read replicas in eu-west-1
- **SLA:** 4-nines availability (52 minutes downtime/year allowed)

**Step-by-Step Troubleshooting & Resolution:**

**1. Initial Detection (T+0:00)**

```bash
# Alert fires: "Unhealthy Host Count > 0"
# Dashboards show:
# - All 12 targets marked UNHEALTHY
# - RequestCount nearly zero
# - Error rate: 100%

# First action: Verify ALB is operational
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[?LoadBalancerName==`prod-alb`].State.Code' \
  --output text
# Result: "active" (ALB itself is fine)

# Check target health
aws elbv2 describe-target-health \
  --region us-east-1 \
  --target-group-arn arn:aws:... \
  --query 'TargetHealthDescriptions[0:3]'
# Result:
# {Target.Id: i-0abc123, State: "unhealthy", 
#  Reason: "Health checks failed",
#  Description: "Health checks have failed with these codes: [Timeout]"}
```

**2. Diagnosis (T+0:05)**

The issue: Health check timeouts. Possible causes:
1. Network connectivity issue (ALB → targets)
2. Target application crashed
3. Backend security group misconfigured
4. Network ACL blocking

```bash
# SSH to one target instance
ssh -i key.pem ec2-user@10.0.1.50

# Check application on target
curl -v http://localhost:80/health
# Result: TIMEOUT (connection hangs)

# Check if application is running
ps aux | grep apache
# Result: No processes; application crashed
# (Could also be: networking issue if process is running)

# Check system logs
tail -100 /var/log/httpd/error_log
# Result: OOM (Out of Memory) killed the process
```

**3. Decision Point (T+0:15)**

**Option A: Fix locally** (30–60 minutes)
- Restart application on all 12 instances
- Investigate root cause of OOM
- Risk: Temporary fix; issue may reoccur

**Option B: Failover to secondary region** (5–10 minutes recommended)
- Activate eu-west-1 ALB
- Shift Route 53 DNS to secondary
- Post-incident: analyze root cause; prepare for return
- Risk: Some customers may experience 30-60 second DNS caching delay

**RCA indicates:** Memory leak in new application deployment (pushed 2 hours ago)

**Decision:** Failover immediately; rollback new version (5-minute deploy)

---

**4. Execute Failover (T+0:20)**

```bash
# Step 1: Verify eu-west-1 ALB & targets are healthy
aws elbv2 describe-target-health \
  --region eu-west-1 \
  --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:123:targetgroup/prod/abc \
  --query 'TargetHealthDescriptions[*].[Target.Id, TargetHealth.State]' \
  --output text
# Result: All 12 targets: HEALTHY ✓

# Step 2: Update Route 53 failover records
# BEFORE: Primary (us-east-1) was active
# AFTER: At Route 53 console OR via CLI

aws route53 change-resource-record-sets \
  --hosted-zone-id Z123ABC \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "api.example.com",
          "Type": "A",
          "FailoverRoutingPolicy": {"Type": "PRIMARY"},
          "SetIdentifier": "us-east-1",
          "HealthCheckId": "xxxxxxxxx",
          "AliasTarget": {
            "HostedZoneId": "Z123...",
            "DNSName": "alb-us-east-1.elb.amazonaws.com",
            "EvaluateTargetHealth": true
          }
        }
      }
    ]
  }'

# Step 3: Manually deregister all targets from primary ALB
# (Prevents any residual traffic if DNS TTL hasn't expired)
for target_id in i-0abc123 i-0def456 ... i-0xyz999; do
  aws elbv2 deregister-targets \
    --region us-east-1 \
    --target-group-arn arn:aws:... \
    --targets Id=$target_id
done

# Step 4: Monitor DNS propagation
dig api.example.com @8.8.8.8
# Should eventually resolve to eu-west-1 ALB IP
```

**5. Verification (T+1:00 Failover Complete)**

```bash
# Verify traffic is flowing to correct region
aws cloudwatch get-metric-statistics \
  --region eu-west-1 \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=prod-alb-eu \
  --start-time 2026-03-07T02:55:00Z \
  --end-time 2026-03-07T03:00:00Z \
  --period 60 \
  --statistics Sum
# Result: RequestCount increasing to 500k+/min ✓

# Verify us-east-1 has no traffic
aws cloudwatch get-metric-statistics \
  --region us-east-1 \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=prod-alb-us \
  --start-time 2026-03-07T02:55:00Z \
  --end-time 2026-03-07T03:00:00Z \
  --period 60 \
  --statistics Sum
# Result: Nearly zero ✓

# Check CloudWatch alarms
# Should see: "ALB-UNHEALTHY-HOSTS" alarm cleared
# Should see: "DNS-FAILOVER-TRIGGERED" alarm fired
```

**Best Practices Applied:**

1. **Pre-incident Preparation:**
   - Secondary region maintained in sync
   - Route 53 failover records configured
   - Regular failover drills (monthly)
   - Documentation updated

2. **Incident Response:**
   - Rapid detection (automated alerting)
   - Quick decision (5 minutes vs 60 minute local fix)
   - Executed failover (no manual DNS changes to get wrong)
   - Monitored migration

3. **Post-incident:**
   - RCA: Memory leak in new deploy
   - Fix: Revert deployment
   - Prevention: Add memory monitoring; set per-process limits
   - Runbook: Failover procedure documented & tested

**RTO Achieved:** 8 minutes (vs 52-minute annual budget)

---

### Scenario 2: Debugging Uneven Load Distribution in Microservices

**Problem Statement:**

Your DevOps team recently migrated from weighted round-robin load balancing to ALB with path-based routing. Performance dashboards show latency increased 40% for `/api/reports` endpoints. Investigation reveals:

- `/api/users` requests: ~30ms average latency
- `/api/reports` requests: ~250ms average latency
- Load is uneven: One backend server in `/api/reports` cluster is handling 60% of traffic (while others handle 20% each)

**Architecture Context:**

- **ALB with path-based routing** (not sticky)
- **Target Group 1:** `/api/users/*` → 4 instances (t3.small)
- **Target Group 2:** `/api/reports/*` → 3 instances (t3.small)
- **Algorithm:** Least Outstanding Requests (default ALB)
- **Latency baseline before migration:** ~40ms

**Root Cause Analysis:**

```bash
# Step 1: Verify configuration
aws elbv2 describe-target-groups \
  --region us-east-1 \
  --query 'TargetGroups[?contains(TargetGroupName, `reports`)]' \
  --output json

# Result:
# {
#   "TargetGroupName": "api-reports-tg",
#   "LoadBalancingAlgorithmType": "least_outstanding_requests",
#   "TargetType": "instance",
#   "Stickiness": {"Enabled": false}
# }
# (Configuration looks correct)

# Step 2: Check if targets are healthy
aws elbv2 describe-target-health \
  --region us-east-1 \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123:targetgroup/api-reports-tg/abc
  --output json

# Result: All 3 targets HEALTHY ✓

# Step 3: Get request distribution from logs
aws s3 cp s3://alb-logs/prefix/2026/03/07/200000Z.log - | \
  grep "/api/reports" | \
  awk -F' ' '{print $6}' | sort | uniq -c
# Result:
# 600 10.0.1.50:8080 (60%)
# 200 10.0.2.75:8080 (20%)
# 200 10.0.3.22:8080 (20%)
# (Confirms uneven distribution)

# Step 4: Check if one target is slow (should be distributed by least outstanding)
# Query ALB access logs for latency per target
aws athena start-query-execution \
  --query-string "
    SELECT 
      target_ip,
      COUNT(*) as request_count,
      ROUND(AVG(target_processing_time), 3) as avg_latency,
      ROUND(PERCENTILE_CONT(0.95) 
            WITHIN GROUP (ORDER BY target_processing_time), 3) as p95_latency
    FROM alb_logs
    WHERE 
      day = '07' 
      AND request_url LIKE '/api/reports%'
    GROUP BY target_ip
    ORDER BY avg_latency DESC
  " \
  --result-configuration OutputLocation=s3://query-results/
  
# Result (from Athena):
# target_ip       | request_count | avg_latency | p95_latency
# 10.0.1.50       |         600    |     0.250   |     2.100  ← SLOW
# 10.0.2.75       |         200    |     0.035   |     0.120
# 10.0.3.22       |         200    |     0.035   |     0.120
```

**Diagnosis:** One target (10.0.1.50) is processing requests 7x slower. This causes ALB's "least outstanding requests" algorithm to route MORE traffic there (because it's overloaded, connection count doesn't drop).

**Root Cause:**

```bash
# SSH to slow instance
ssh -i key.pem ec2-user@10.0.1.50

# Check resource usage
top -n1 | head -15
# Result:
# CPU: 95%
# Memory: 87%
# (System resource constrained)

# Check process
ps aux | grep java
result: java -Xmx512m -jar api-reports.jar
# (Only 512MB heap; other instances have 1GB)

# Check deployment history
cat /var/log/deploy.log | tail -50
# Result:
# 2026-03-07 08:30:00 Deployed new JVM version
# 2026-03-07 08:30:05 Instance i-0abc123: java launch script bug
# i-0abc123: ENV_MEMORY=-Xmx512m (hardcoded, not inherited)
# Other instances got correct -Xmx1024m from ASG launch template
```

**Root Cause:** Deployment bug set incorrect JVM heap size on one instance.

---

**Resolution Strategy:**

**Option A: Fix in-place (10 minutes)**
```bash
# Update JVM args and restart
ssh -i key.pem ec2-user@10.0.1.50
sudo systemctl stop api-reports
vi /etc/api-reports/config
# Change: -Xmx512m → -Xmx1024m
sudo systemctl start api-reports

# Verify
ps aux | grep java
# Should show: -Xmx1024m ✓
```

**Option B: Replace instance via ASG (2 minutes)**
```bash
# Terminate unhealthy instance (ASG will auto-replace)
aws ec2 terminate-instances \
  --region us-east-1 \
  --instance-ids i-0abc123

# Wait for ASG to launch replacement
aws autoscaling describe-auto-scaling-groups \
  --region us-east-1 \
  --auto-scaling-group-names api-reports-asg

# New instance will get correct config from launch template ✓
```

**Chosen:** Option B (faster; avoids human error; maintains immutable infrastructure)

---

**Verification Post-Fix:**

```bash
# Monitor traffic distribution immediately after new instance is healthy
while true; do
  aws elbv2 describe-target-health \
    --region us-east-1 \
    --target-group-arn arn:aws:... \
    --output text | awk '{print $1, $2}'
  sleep 10
done

# Check latency distribution after 5 minutes
aws athena start_query_execution \
  --query-string "
    SELECT 
      target_ip,
      ROUND(AVG(target_processing_time), 3) as avg_latency
    FROM alb_logs
    WHERE created_time > now() - interval '5' minute
      AND request_url LIKE '/api/reports%'
    GROUP BY target_ip
  "
  
# Expected result:
# 10.0.1.50 (new)   | 0.035  ✓ (matches other instances)
# 10.0.2.75         | 0.035
# 10.0.3.22         | 0.035
# (Even distribution restored)
```

**Best Practices Applied:**

1. **Configuration Management:**
   - Instance launch templates enforced
   - No manual configuration on instances
   - All configs from code (IaC)

2. **Monitoring:**
   - Access log analysis (Athena)
   - Per-target latency tracking
   - Automated anomaly detection

3. **Rapid MTTR:**
   - Chose ASG replacement over manual fix
   - Prevented human error
   - Maintained infrastructure consistency

---

### Scenario 3: Zero-Downtime Deployment with Canary & Rollback

**Problem:**

Your team is deploying a new API version with database schema changes. Risks:
- Backward compatibility: new code needs old schema temporarily
- Database migration: 30-second operation while handling live traffic
- Rollback: If issues detected, revert quickly

**Goal:** Deploy to <2% of traffic first (canary); monitor for errors; gradually shift to 100%.

**Architecture:**

```
ALB (80% → V2 Canary, 20% → V1 Latest)
├─ Target Group A (V2 Canary): 1 instance
└─ Target Group B (V1 Latest): 4 instances
```

**Step 1: Prepare Canary Environment**

```bash
# Build and test new API (V2)
docker build -t api:v2 .
docker run -it api:v2 bash
# Run tests...

# Push to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin ...
docker tag api:v2 123456789012.dkr.ecr.us-east-1.amazonaws.com/api:v2
docker push ...

# Create canary target group
aws elbv2 create-target-group \
  --name api-v2-canary-tg \
  --port 8080 \
  --protocol HTTP \
  --vpc-id vpc-xxx \
  --health-check-path /health \
  --health-check-protocol HTTP

# Launch 1 EC2 instance with V2 image
aws ec2 run-instances \
  --image-id ami-v2-app \
  --instance-type t3.medium \
  --user-data file://launch-v2.sh

# Register to target group
aws elbv2 register-targets \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123:targetgroup/api-v2-canary-tg/xyz \
  --targets Id=i-0canary123 Port=8080

# Wait for health checks to pass
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123:targetgroup/api-v2-canary-tg/xyz \
  --query 'TargetHealthDescriptions[0].TargetHealth.State'
# Result (after 1-2 min): "healthy" ✓
```

**Step 2: Add Canary Listener Rule (Weighted Routing)**

```hcl
# Terraform: Create weighted routing
resource "aws_lb_listener_rule" "api_v2_canary" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_v2_canary.arn
    weight           = 5  # 5% traffic
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "api_v1_stable" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 6

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_v1_stable.arn
    weight           = 95  # 95% traffic
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
```

**Step 3: Monitor Canary Deployment**

```bash
# CloudWatch metrics for canary
watch -n 10 'aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=TargetGroup,Value=api-v2-canary-tg \
  --start-time $(date -u -d "10 minutes ago" +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum'

# Expected: 0 errors during canary phase

# Check error rate by target group
aws athena start-query-execution \
  --query-string "
    SELECT 
      target_group_arn,
      status_code,
      COUNT(*) as count,
      ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY target_group_arn), 2) as pct
    FROM alb_logs
    WHERE created_time > now() - interval '5' minute
    GROUP BY target_group_arn, status_code
    ORDER BY target_group_arn, status_code
  "

# Expected for V2 canary: 99%+ 2xx responses
# Expected for V1 stable: 99%+ 2xx responses (no regression)
```

**Step 4: Gradual Shift (if canary healthy)**

```bash
# Monitor for 10 minutes; if error rate < 0.1%:

# Shift 20% to canary
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,ForwardConfig={TargetGroups=[{TargetGroupArn=tg-v2,Weight=20},{TargetGroupArn=tg-v1,Weight=80}]}

# Sleep 5 minutes; monitor errors

# Shift 50% to canary
# Modify again: Weight 50/50

# Shift 100% to canary
# Modify again: Weight 100/0
```

**Step 5: Rollback (if errors detected)**

```bash
# If at any point error rate > 1%:

# INSTANT rollback to V1
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions Type=forward,ForwardConfig={TargetGroups=[{TargetGroupArn=tg-v2,Weight=0},{TargetGroupArn=tg-v1,Weight=100}]}

# Result: All traffic back to V1 (< 1 second)

# Investigate V2 errors
# Revert schema migration if needed
# Deploy V2.1 with fix
# Retry canary
```

**Best Practices Applied:**

1. **Risk Mitigation:**
   - Tested canary before production traffic
   - Data migration didn't block requests
   - Instant rollback available

2. **Gradual Shift:**
   - Start at 5% (lower blast radius)
   - Monitor before advancing
   - Total ramp time: 30 minutes (safe)

3. **Monitoring:**
   - Per-target-group error rate tracking
   - Automated rollback triggers (optional)
   - Clear decision criteria (error rate threshold)

---

### Scenario 4: Resolving Cross-Region Database Replication Lag with NLB

**Problem Statement:**

You operate a database cluster spanning two regions (us-east-1 → eu-west-1 replication). An NLB distributes read queries across 3 replica instances per region. However, recent monitoring reveals:

- Writes applied in us-east-1 immediately (< 5ms)
- Same data in eu-west-1 appears 500–2000ms later
- Customers querying eu-west-1 occasionally see stale data (old order status, outdated user profile)

**Architecture Context:**

```
┌─────────────────────────────────────────────────────┐
│  READ-HEAVY APPLICATION                            │
│  • 90% SELECT queries → NLB distributed             │
│  • 10% WRITE queries → Primary (us-east-1)         │
└─────────────────────────────────────────────────────┘
         │
         ├─ NLB (us-east-1)
         │  ├─ Replica 1: 10.0.1.50
         │  ├─ Replica 2: 10.0.1.51
         │  └─ Replica 3: 10.0.1.52
         │
         └─ NLB (eu-west-1)
            ├─ Replica 1: 10.0.2.50
            ├─ Replica 2: 10.0.2.51
            └─ Replica 3: 10.0.2.52
            
Replication: Primary (us-east-1) → Replicas (eu-west-1)
Lag: 500–2000ms (variable)
```

**Root Cause Investigation:**

```bash
# Step 1: Verify replication lag
mysql -h replica.eu-west-1.rds.amazonaws.com -u admin -p$PASS \
  -e "SHOW REPLICA STATUS\G" | grep -i Seconds_Behind_Master
# Result: Seconds_Behind_Master: 1.5 (1.5 seconds lag)

# Step 2: Check if network bandwidth is saturated
# (High replication lag often indicates network bottleneck)
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name NetworkReceiveThroughput \
  --dimensions Name=DBInstanceIdentifier,Value=replica-eu-west-1 \
  --start-time 2026-03-07T14:00:00Z \
  --end-time 2026-03-07T14:10:00Z \
  --period 60 \
  --statistics Average
# Result: Average throughput: 950 Mbps (of 1Gbps limit)
# (Not saturated; internal MySQL replication lag)

# Step 3: Check MySQL replication thread status
mysql -h replica.eu-west-1.rds.amazonaws.com -u admin -p$PASS \
  -e "SHOW REPLICA STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Seconds_Behind"
# Result:
# Slave_IO_Running: Yes
# Slave_SQL_Running: Yes
# Seconds_Behind_Master: 1–2 seconds (variable)

# Step 4: Identify slow queries on PRIMARY that are replicating
mysql -h primary.us-east-1.rds.amazonaws.com -u admin -p$PASS \
  -e "SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE COMMAND != 'Sleep';"
# Result: Shows long-running queries impacting replication
# (e.g., ANALYZE TABLE running 10+ seconds)
```

**Root Cause:** Administrative operations (ANALYZE TABLE, ALTER TABLE) on primary are blocking replication on replica.

---

**Solution: Query Routing Strategy**

**Problem with NLB 5-tuple hashing:**
```
Current behavior (5-tuple hash):
1. Client makes WRITE: INSERT order
   → Routes to Primary (via application logic)
   
2. Client makes READ: SELECT order
   → NLB hashes (client_ip, client_port, dest_ip, dest_port)
   → Could hash to ANY replica (us-east-1 or eu-west-1)
   → If replica in eu-west-1: Gets stale data (1.5s lag)
   
3. Result: Inconsistent reads (client sees new data, then old data on refresh)
```

**Solution 1: Read-Your-Writes Consistency (Application-Level)**

```python
# Application code: Track write timestamps
import time

class OrderService:
    def create_order(self, user_id, items):
        # Write to primary
        order = self.primary_db.insert_order(user_id, items)
        order_id = order['id']
        
        # Track write time on client
        write_timestamp = time.time()
        
        # Store in session (for this client only)
        session['last_write_time'] = write_timestamp
        session['min_replica_lag'] = 2.0  # RDS EU estimated lag
        
        return {'order_id': order_id, 'status': 'created'}
    
    def get_order(self, order_id):
        # Check if recent write
        if session.get('last_write_time'):
            time_since_write = time.time() - session['last_write_time']
            
            # If write was < 2 seconds ago:
            if time_since_write < session.get('min_replica_lag', 2.0):
                # Read from primary (or wait for replica)
                return self.primary_db.select_order(order_id)
        
        # Otherwise, read from replica (NLB distributed)
        return self.replica_nlb_db.select_order(order_id)
```

**Solution 2: Read from Primary After Write (Simplest)**

```python
class OrderService:
    def create_order(self, user_id, items):
        order = self.primary_db.insert_order(user_id, items)
        session['use_primary_reads'] = True  # Flag next reads
        session['primary_read_expires'] = time.time() + 5  # 5 seconds
        return order
    
    def get_order(self, order_id):
        if session.get('use_primary_reads') and \
           session.get('primary_read_expires', 0) > time.time():
            return self.primary_db.select_order(order_id)
        return self.replica_nlb_db.select_order(order_id)
```

**Solution 3: Read from Local Region Only**

```python
# Client's region is us-east-1; always read from us-east-1 replicas
# (eu-west-1 clients read from eu-west-1 replicas)

class OrderService:
    def __init__(self, region):
        self.region = region
        if region == 'us-east-1':
            self.replica_db = NLB(endpoint='nlb-us-east-1.example.com')
        elif region == 'eu-west-1':
            self.replica_db = NLB(endpoint='nlb-eu-west-1.example.com')
    
    def get_order(self, order_id):
        # Always read from local replica (same region as client)
        # Replication lag is within acceptable range (< 1 second) locally
        return self.replica_db.select_order(order_id)
```

**Chosen Solution:** Solution 2 (read-from-primary for 5 seconds after write)

---

**Implementation & Monitoring:**

```bash
# Update application config
# Set PRIMARY_READ_TIMEOUT = 5  (seconds)

# Monitor replica lag post-fix
watch -n 30 'mysql -h replica.eu-west-1.rds.amazonaws.com \
  -u admin -p$PASS \
  -e "SHOW REPLICA STATUS\G" | grep Seconds_Behind'

# Expected: Seconds_Behind_Master: 0–500ms (acceptable)

# Monitor application for stale-data complaints
# Query logs for: "Order not found" errors
# Should decrease to near zero

# Verify read-from-primary trigger
# Application logs should show: "Using PRIMARY read" for 5 seconds after write
```

**Best Practices Applied:**

1. **Architecture Understanding:**
   - NLB can't enforce affinity to region
   - Database replication inherently has lag
   - Application must handle eventual consistency

2. **Solution Designed for Trade-offs:**
   - Stronger consistency (read from primary after write)
   - Minimal latency impact (only 5 seconds)
   - Simple implementation (no complex state machine)

3. **Monitoring:**
   - Track replica lag continuously
   - Monitor application consistency errors
   - Alert if lag exceeds threshold (> 5 seconds globally)

---

### Scenario 5: Debugging SSL/TLS Certificate Expiration Affecting Production

**Problem Statement:**

At 17:30 UTC on a Friday, your company's mobile app starts reporting widespread connection errors:
- iOS users: "Certificate validation failed"
- Android users: "CERTIFICATE_VERIFY_FAILED"
- Web users: No issues (browser shows minor warning, auto-continues)

**Initial Information:**

- Application endpoints: api.example.com, socket.example.com
- ALB HTTPS listener configured with ACM certificate
- Latest deployment: 3 days ago (no TLS-related changes)
- No on-call engineer immediately available (weekend)

**Root Cause Investigation (T+0–15 minutes):**

```bash
# Step 1: Check certificate expiration
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn arn:aws:acm:us-east-1:123:certificate/abc123 \
  --query 'Certificate.[DomainName, NotAfter, NotBefore, Status, RenewalEligibility]' \
  --output json

# Result:
# {
#   "DomainName": "api.example.com",
#   "NotAfter": "2026-03-07T17:00:00Z",  ← EXPIRED 30 MIN AGO!
#   "NotBefore": "2025-03-07T00:00:00Z",
#   "Status": "EXPIRED",
#   "RenewalEligibility": "INELIGIBLE"
# }

# Step 2: Check which domains are affected
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn arn:aws:acm:us-east-1:123:certificate/abc123 \
  --query 'Certificate.SubjectAlternativeNames' \
  --output json
# Result: ["api.example.com", "*.example.com", "socket.example.com"]

# Step 3: Check if certificate is bound to ALB
aws elbv2 describe-listeners \
  --region us-east-1 \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123:loadbalancer/app/prod-alb/abc \
  --query 'Listeners[?Protocol==`HTTPS`].Certificates' \
  --output json
# Result:
# [
#   {
#     "CertificateArn": "arn:aws:acm:us-east-1:123:certificate/abc123"
#   }
# ]
# (Confirmed: expired cert is active on ALB)
```

**Root Cause:** Certificate expired 30 minutes ago.

**Why auto-renewal failed:**

```bash
# Step 4: Check domain validation status
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn arn:aws:acm:us-east-1:123:certificate/abc123 \
  --query 'Certificate.DomainValidationOptions[*].[DomainName, ValidationStatus, LastValidationEmailDate]' \
  --output json

# Result:
# [
#   {
#     "DomainName": "api.example.com",
#     "ValidationStatus": "FAILED",
#     "LastValidationEmailDate": "2026-02-06T15:30:00Z"
#   }
# ]

# Step 5: Check Route 53 DNS records for validation
aws route53 list-resource-record-sets \
  --zone-id Z123ABC \
  --query 'ResourceRecordSets[?contains(Name, `_acm-chall`)]' \
  --output json

# Result: No ACM challenge records found!
# (DNS validation records were deleted or never created)
```

**Root Cause:** DNS validation records were absent (possibly deleted during infrastructure refactor 2 weeks ago).

---

**Immediate Mitigation (T+15–25 minutes):**

**Option A: Request new certificate + immediate issue (5 minutes)**

```bash
# Request new certificate (DNS validation)
aws acm request-certificate \
  --region us-east-1 \
  --domain-name api.example.com \
  --subject-alternative-names "*.example.com" "socket.example.com" \
  --validation-method DNS \
  --idempotency-token prod-cert-$(date +%s)

# Result: CertificateArn = arn:aws:acm:us-east-1:123:certificate/xyz789

# Get validation records to add to Route 53
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn arn:aws:acm:us-east-1:123:certificate/xyz789 \
  --query 'Certificate.DomainValidationOptions[*].[DomainName, ResourceRecord.Name, ResourceRecord.Value, ResourceRecord.Type]' \
  --output json

# Result:
# [
#   {
#     "DomainName": "api.example.com",
#     "ResourceRecord": {
#       "Name": "_acm-chall.api.example.com",
#       "Type": "CNAME",
#       "Value": "_validation.acm-validations.aws"
#     }
#   }
# ]

# Create DNS records in Route 53
aws route53 change-resource-record-sets \
  --zone-id Z123ABC \
  --change-batch file://dns-changes.json

# dns-changes.json:
# {
#   "Changes": [
#     {
#       "Action": "CREATE",
#       "ResourceRecordSet": {
#         "Name": "_acm-chall.api.example.com",
#         "Type": "CNAME",
#         "TTL": 300,
#         "ResourceRecords": [{"Value": "_validation.acm-validations.aws."}]
#       }
#     }
#   ]
# }

# Wait for ACM validation (1–3 minutes)
aws acm describe-certificate \
  --region us-east-1 \
  --certificate-arn arn:aws:acm:us-east-1:123:certificate/xyz789 \
  --query 'Certificate.Status'
# Result (after 2 min): "ISSUED" ✓

# Update ALB listener with new certificate
aws elbv2 modify-listener \
  --region us-east-1 \
  --listener-arn arn:aws:elasticloadbalancing:us-east-1:123:listener/app/prod-alb/abc/50001b7c4f00a46d/def456 \
  --certificates CertificateArn=arn:aws:acm:us-east-1:123:certificate/xyz789

# Verify certificate is active
aws elbv2 describe-listeners \
  --region us-east-1 \
  --listener-arn ... \
  --query 'Listeners[0].Certificates[0].CertificateArn'
# Result: arn:aws:acm:us-east-1:123:certificate/xyz789 ✓
```

**Result:** Certificate updated; mobile apps reconnect successfully (< 25 minutes MTTR)

---

**Root Cause Analysis & Prevention:**

```bash
# Step 1: Why was old cert not renewed?
# Answer: DNS validation records were deleted during infrastructure refactor

# Step 2: Set up monitoring to prevent recurrence
# Create CloudWatch alarm for certificate expiration

aws cloudwatch put-metric-alarm \
  --alarm-name certificate-expiration-alert \
  --alarm-description "Alert if ACM certificate expires in < 30 days" \
  --metric-name DaysToExpiry \
  --namespace AWS/CertificateManager \
  --statistic Average \
  --period 3600 \
  --threshold 30 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=CertificateArn,Value=arn:aws:acm:us-east-1:123:certificate/xyz789 \
  --alarm-actions arn:aws:sns:us-east-1:123:alerts

# Step 3: Automate certificate renewal
# Use AWS Systems Manager / automation to:
# 1. Detect expiring certificates
# 2. Request new certificate
# 3. Create validation DNS records automatically
# 4. Bind new certificate to ALB/NLB

# Step 4: Document DNS records as "critical infrastructure"
# Terraform state: Mark as protected
terraform state lock

# Implementation:
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : 
    dvo.domain => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
  
  lifecycle {
    create_before_destroy = true  # Prevent accidental deletion
  }
}
```

**Best Practices Applied:**

1. **Pre-incident Prevention:**
   - Regular certificate audits (monthly)
   - Automated monitoring (DNS validation check)
   - Documentation of critical DNS records

2. **Incident Response:**
   - Rapid detection (automated alerting)
   - Quick mitigation (new cert + DNS validation)
   - Zero service downtime (25 minutes vs SLA violation)

3. **Post-incident:**
   - RCA documented
   - Terraform state protection enabled
   - Monitoring expanded
   - Team training on certificate lifecycle

---

## Most Asked Interview Questions

### Q1: Explain the difference between ALB and NLB, and when you'd choose each. Walk through a real production example.

**Expected Senior-Level Answer:**

"ALB (Layer 7) and NLB (Layer 4) target different workloads based on the decision between request-level and connection-level routing.

**ALB Use Cases (Layer 7 / HTTP/HTTPS):**
- Microservices architectures requiring content-based routing
- Example: 100k req/sec web application with path-based routing (`/api/*` → API service, `/images/*` → CDN)
- Latency: 1–5ms processing overhead (request parsing)
- Cost: $0.0225/LCU-hour (cheaper for typical workloads)

**NLB Use Cases (Layer 4 / TCP/UDP):**
- Ultra-high throughput: 1M+ requests per second
- Non-HTTP protocols: MQTT (IoT), gaming protocols, custom binary
- Extreme low latency critical: Sub-millisecond requirements (financial trading, stock exchanges)
- Database proxies: MySQL replication requires connection affinity (5-tuple hashing)
- Example: AWS Lambda Event Source Mapping uses NLB for real-time IoT data ingestion (100k MQTT connections → backend)

**Real Production Example:**

In my previous role at [Company], we managed both:

1. **E-commerce Platform (ALB):**
   - 50M req/day, multiple microservices
   - ALB for path/host routing: /api/users → user-service, /orders/* → order-service
   - Least Outstanding Requests algorithm balanced load even with varying request duration (image upload queries slower than status checks)
   - HTTPS termination offloaded TLS CPU from app servers
   - Result: Horizontal scaling was straightforward; adding instances automatically load-balanced

2. **Time-Series Database Cluster (NLB):**
   - 2M writes/sec, 10M reads/sec to InfluxDB cluster
   - NLB with TCP connection affinity (5-tuple hash) ensured client connections routed to consistent replica
   - Connection pooling worked; no connection limits exhausted
   - Sub-5ms latency critical for real-time alerting
   - ALB couldn't achieve this (request-level balancing would fragment connection state)
   - Result: Stable throughput, predictable latency

**Decision Tree I use:**
- Is HTTP/HTTPS the protocol? → ALB
- Do you need content-based routing (paths, hostnames)? → ALB
- Is throughput > 500k req/sec per availability zone? → NLB
- Non-HTTP protocol? → NLB
- Latency < 1ms requirement? → NLB
- Database or stateful protocol? → NLB

If unsure: Start with ALB (simpler, cheaper). Migrate to NLB if performance testing reveals latency or throughput constraints."

---

### Q2: Walk me through troubleshooting unhealthy targets in an ALB. What would you check first, and why?

**Expected Senior-Level Answer:**

"When targets are unhealthy, I follow a systematic approach (not just 'check security groups'):

**Diagnostic Priority (based on deployment frequency):**

1. **Did application code change recently?** (Most likely cause, ~60% of incidents)
   ```bash
   # Check deployment history
   git log --oneline -10
   # Check application logs on target
   tail -100 /var/log/application/error.log
   # Look for: OOM errors, unhandled exceptions, dependency failures
   ```

2. **Is the health check path correct?** (~15%)
   ```bash
   # Verify health check configuration
   aws elbv2 describe-target-groups \
     --query 'TargetGroups[].HealthCheckPath'
   # Manually curl health endpoint
   curl -v http://10.0.1.50:80/health
   # If 404: wrong path or endpoint not implemented
   ```

3. **Security group blocking?** (~10%)
   ```bash
   # Check ALB → Target security group rules
   aws ec2 describe-security-groups \
     --group-ids sg-target \
     --query 'SecurityGroups[].IpPermissions[].[FromPort, ToPort, IpRanges[].CidrIp]'
   # Verify ingress rule: Protocol=TCP, Port=80 (or custom), Source=ALB security group
   ```

4. **Network/Infrastructure-level:**
   - VPC ACLs blocking ephemeral ports (unlikely, but check)
   - EC2 instance has lost network connectivity (even rarer)
   - Target port mismatch (ALB checking port 80, app listening on 8080)

**Specific Example I Debugged:**
  
Customer reported 50% targets unhealthy post-deployment. I found:
- Health checks timing out (not returning 404, just hanging)
- Application startup sequence had dependency on RDS; RDS security group wasn't updated
- App listening; RDS unreachable → health check hangs → timeout

Fix:
```bash
# Add application-level timeout to health check endpoint
# GET /health → 5s timeout
# If RDS unreachable → return 503 (unhealthy, faster detection)
# Instead of hanging → timeout at ALB level

# Also fixed root cause:
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --source-group sg-app \
  --protocol tcp \
  --port 3306
```

**Key insight:** The health check is a contract between ALB and application. If health checks hang (not fail), it suggests app is waiting on a blocked resource, not a simple connection issue."

---

### Q3: Your ALB is showing high latency (p99 = 2 seconds). Targets are all healthy. Walk me through the diagnosis.

**Expected Senior-Level Answer:**

"High latency with all targets healthy suggests problem is either backend application or ALB overload. Let me investigate systematically:

**Step 1: Isolate the bottleneck**

```bash
# Get latency breakdown from ALB access logs
aws athena execute-statement \
  --query-string "
    SELECT 
      AVG(request_processing_time) as alb_latency,
      AVG(target_processing_time) as backend_latency,
      AVG(response_processing_time) as response_latency,
      PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY target_processing_time) as p99_backend
    FROM alb_logs
    WHERE created_time > now() - interval '10' minute
  "

# Result tells us:
# • ALB latency 1–10ms (normal)
# • Backend latency 1500–2000ms (problem!)
# • Response latency < 50ms (normal)
# Conclusion: Backend application is slow
```

**Step 2: Backend Investigation**

```bash
# SSH to target; check resource usage
top -n1 | head -5
# Check:
# - CPU: Is it 99%+ (CPU bound)
# - Memory: Is it near capacity (OOM risk)
# - Disk I/O: Is iostat showing high await

# Check for slow queries / long-running operations
# (MySQL example)
mysql -e "SHOW PROCESSLIST\G" | grep Time | sort -rn | head -5
# Look for: Queries running >5 seconds

# Check application thread/goroutine count
# (Java example)
jstack $(pgrep java) | grep "tid" | wc -l
# If thread count >> expected, there's a resource leak
```

In a real incident: Customer's batch job (ANALYZE TABLE) ran during peak traffic, blocking queries for 30+ seconds. Health checks still passed (they don't hit locked tables), but user queries queued behind locks.

**Solution:**
```sql
-- Reschedule maintenance to off-peak window
-- OR use ANALYZE TABLE /* 30 */ for streaming analysis
```

**Step 3: Load Imbalance**

```bash
# Even if targets healthy, one might be slower
aws athena execute-statement \
  --query-string "
    SELECT 
      target_ip,
      AVG(target_processing_time) as avg_latency,
      COUNT(*) as request_count
    FROM alb_logs
    WHERE created_time > now() - interval '10' minute
    GROUP BY target_ip
    ORDER BY avg_latency DESC
  "

# If one target's avg >> others:
# • That instance is undersized (wrong instance type)
# • That instance is running different code version (partial deployment)
# • Network saturation for that instance (check VPC bandwidth)
```

**Step 4: ALB Itself**

```bash
# Check if ALB is at capacity
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetTLSNegotiationTime \
  --dimensions Name=LoadBalancer,Value=prod-alb \
  --statistics Average
  
# If TLS handshake time > 100ms: ALB CPU saturation possible
# (ALB competing with other workloads in shared VPC NAT gateway, etc.)

# Check LCU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name BackendTLSHandshakeTime
  
# If approaching ALB capacity limits, scale up
```

**Root Cause in that example:** None of the above! Investigation revealed caching layer (local Redis on each target) was evicting entries under load. Application made cache miss → database query → slow. Solution: Increased Redis memory on targets."

---

### Q4: You're deploying a new service to production. Design a load balancing strategy that minimizes blast radius if things go wrong.

**Expected Senior-Level Answer:**

"I'd implement a multi-stage canary deployment with traffic shifting and automated rollback:

**Stage 1: Shadow Traffic (0% user traffic, 100% shadowed)**
```
ALB Listener Rule (path=/api/new-service):
  • 0% → V2 (canary; no real impact)
  • 100% → V1 (current production)

BUT also: Mirror 10% of traffic to V2 (shadow)
  • Monitor V2 responses (errors, latency)
  • V2 errors DON'T affect users
  • Early detection of bugs
```

**Stage 2: Gradual Shift (1% → 50% → 100%)**
```
Once shadow traffic error rate < 0.1%:

aws elbv2 modify-listener \
  --default-actions ForwardConfig={
    TargetGroups=[
      {TargetGroupArn=v2, Weight=1},
      {TargetGroupArn=v1, Weight=99}
    ]
  }

Monitor for 5 minutes:
  • Error rate in V2 target group: < 0.5%?
  • Latency p99 increase: < 50ms?
  
If YES: Shift to 5%, then 25%, then 50%

If NO: Rollback to 100% V1 (instant, < 10 seconds)
```

**Stage 3: Health Check Automation**

```hcl
# Terraform: Automated rollback trigger
resource "aws_cloudwatch_integration_action" "canary_rollback" {
  alarm_name = "canary-error-rate-high"
  
  triggers {
    metric_name = "HTTPCode_Target_5XX_Count"
    threshold   = 5  # > 5 errors/min → rollback
    operator    = "GreaterThan"
  }
  
  action = "shift_traffic_to_v1"  # Custom Lambda
}

# Lambda function:
def shift_traffic_to_v1():
    elbv2.modify_listener(
      ListenerArn=...,
      DefaultActions=[{
        Type='forward',
        TargetGroupArn=v1_tg
      }]
    )
    # Notify team
    sns.publish(Subject="Canary Failed - Automatic Rollback")
```

**Stage 4: Post-Deployment Monitoring**

```bash
# Track metrics per target group for 30 minutes post-deployment
watch 'aws cloudwatch get-metric-statistics \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=TargetGroup,Value=v2-tg \
  --stats Sum'

# If error rate stable and < 0.1%, declare success
# If error rate creeping up (memory leak, etc.), catch before it affects 100% of users
```

**Real Example from My Career:**

At [Company], we deployed V2 payment processing on Black Friday without proper canary. Bug in VAT calculation affected 5% of orders (we discovered too late). Cost: $2M refunds + customer trust damage.

Now we:
- Always canary-deploy critical services (Stage 1 shadow + gradual shift)
- Set aggressive error thresholds for automatic rollback
- Test with representative traffic volume (not just smoke tests)

Result: 3 subsequent deployments caught bugs during canary phase (< 1% blast radius) vs. post-production incidents."

---

### Q5: An ALB is processing 1M req/sec. You need to scale to 2M req/sec. What do you change, and what are the trade-offs?

**Expected Senior-Level Answer:**

"Scaling load balancers is complex because they're not traditional servers you just add replicas of:

**Scaling Options & Trade-offs:**

| Option | Implementation | Trade-offs |
|--------|---|---|
| **Cross-Zone LB** | `enable_cross_zone_load_balancing = true` | Adds inter-AZ traffic ($0.006/LCU on NLB); ALB free; slight latency increase (10–50ms) |
| **Add More Targets** | ASG: increase desired_capacity from 10 → 20 instances | Helps if backend is bottleneck, not ALB; cost increases; management complexity |
| **Switch to NLB** | Replace ALB with NLB; simpler routing | Loses HTTP/HTTPS content routing; requires app refactor |
| **Multiple ALBs** | Geo-distribute ALBs (us-east, eu-west, apac); Route 53 geolocation routing | Complex failover; higher cost; more operational burden |
| **Shard by Client** | Using Route 53 weighted routing: 50% to ALB1, 50% to ALB2 | Some clients always route to same ALB; doesn't provide true redundancy |

**My Approach (in order of implementation):**

1. **Enable Cross-Zone Load Balancing (instant, free for ALB)**
   - If traffic concentrated in one AZ, this distributes load
   - Cost impact: Near zero for ALB

2. **Verify Targets Aren't Saturated**
   ```bash
   aws cloudwatch get-metric-statistics \
     --metric-name CPUUtilization \
     --dimensions Name=AutoScalingGroupName,Value=backend-asg \
     --stats Average
   # If < 60%: Targets have capacity; ALB isn't bottleneck
   # If > 80%: Need more targets first
   ```

3. **Check ALB itself (rare bottleneck)**
   ```bash
   # AWS monitors this; if ALB reaches capacity:
   # • New connections get longer latency
   # • Can't scale ALB up (it's managed)
   # Solution: Create second ALB; use Route 53 to split traffic
   ```

4. **Parallelism via Route 53 Weighted Routing**
   ```hcl
   # Two ALBs, each handling 1M req/sec
   resource "aws_route53_record" "api_split" {
     # ALB1: 50% traffic
     weighted_routing_policy { weight = 50 }
     alias { name = aws_lb.alb1.dns_name }
     
     # ALB2: 50% traffic
     weighted_routing_policy { weight = 50 }
     alias { name = aws_lb.alb2.dns_name }
   }
   ```
   
   Problem: Client-sticky (if ALB1 fails, Route 53 still sends requests → 504)
   
   Better: Use AWS Global Accelerator (active-active multi-region).

**Real-World Case:**

We had a spike from 500k to 2M req/sec within 6 hours (viral moment). Steps:

1. **Minute 0:** Status: 500k req/sec across 3 AZs, ALB healthy
2. **Minute 30:** Traffic spike detected; ASG scaling too slow (launch_template booting instances)
   - Quick fix: Manually launch 20 instances in each AZ (CLI)
   - Cost: ~$300 for 60 instances for 4 hours
3. **Minute 60:** 1M req/sec hitting ALB; increased latency (p99 = 500ms)
   - Enabled cross-zone load balancing (already enabled, so wasn't the issue)
   - Problem: Targets CPU-bound; couldn't add more instances fast enough
4. **Minute 90:** Crunched decision:
   - Lower quality threshold (image compression, feature flags off)
   - Shed non-critical traffic (internal tools, batch jobs)
   - Temporarily limited API rate to existing customers
5. **Hour 2:** Stable at 1.5M req/sec, customers happy, site responsive

**Lessons:**
- ALB scaling isn't about the load balancer; it's about the ecosystem
- Targets often the bottleneck, not the ALB
- Sharding/shedding load sometimes faster than provisioning
- Global Accelerator useful for true multi-region scaling"

---

### Q6: Describe your approach to certificate management at scale. How do you handle renewals, rotations, and compliance?

**Expected Senior-Level Answer:**

"Certificate management is critical but often neglected. I've seen companies lose 7-figure customers due to expired certifications.

**My Comprehensive Approach:**

**1. Acquisition (ACM Preferred)**
```hcl
# Use AWS ACM (free, auto-renewal)
resource "aws_acm_certificate" "main" {
  domain_name             = "example.com"
  subject_alternative_names = ["*.example.com", "api.example.com"]
  validation_method       = "DNS"  # Not email!
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags {
    ManagedBy = "terraform"
    Compliance = "required"  # Helps with audits
  }
}

# Avoid BYOC (Bring Your Own Cert) unless required
# BYOC costs $1/month per cert; ACM free; harder to rotate
```

**2. Validation (DNS, not Email)**
```hcl
# DNS auto-validates in Route 53
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options :
      dvo.domain => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
  }
  
  zone_id = aws_route53_zone.main.zone_id
  ...
  
  lifecycle {
    create_before_destroy = true  # Critical: prevents orphaned records
  }
}

# Email validation fails ~5% of time (spam filters, employee left)
# DNS validation automatically retries until success
```

**3. Auto-Renewal Monitoring**
```python
import boto3
import time
from datetime import timedelta

def check_certificate_renewal():
    acm = boto3.client('acm')
    certs = acm.list_certificates()
    
    for cert_arn in certs['CertificateSummaryList']:
        cert = acm.describe_certificate(CertificateArn=cert_arn)
        
        expires_at = cert['Certificate']['NotAfter']
        days_until_expiry = (expires_at - datetime.now()).days
        
        # Alert if:
        # 1. Expires in < 7 days AND not in grace period (< 30 days, auto-renewing)
        # 2. Renewal failed (RenewalEligibility == INELIGIBLE)
        
        if days_until_expiry < 30:
            status = cert['Certificate']['RenewalEligibility']
            if status != 'ELIGIBLE':
                send_alert(f"Cert {cert['Certificate']['DomainName']} renewal at risk!")
                # Check DNS validation records
                dv_options = cert['Certificate']['DomainValidationOptions']
                for dv in dv_options:
                    if dv['ValidationStatus'] != 'SUCCESS':
                        recreate_dns_validation_record(dv)
```

**4. Binding to Load Balancers**
```hcl
# Always use latest ACM cert (auto-updated)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.main.arn  # Always latest
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2021-06"
  
  # Avoids manual certificate updates
}
```

**5. Rotation & Compliance**
```hcl
# For multi-certificate scenarios (compliance requirement):
resource "aws_lb_listener" "https_with_rotation" {
  ...
  certificates = [
    aws_acm_certificate.main.arn,           # Primary (auto-renewed)
    aws_acm_certificate.secondary.arn       # Secondary (for rotation window)
  ]
}

# During renewal:
# 1. Old cert still valid (< 30 min before expiry)
# 2. New cert issued (auto-renewal succeeds)
# 3. ALB has both certs; no downtime
# 4. Old cert expires; automatically removed (grace period)
```

**6. Monitoring & Alerting**
```hcl
# CloudWatch: Certificate expiration alarm
resource "aws_cloudwatch_metric_alarm" "cert_expiration" {
  alarm_name          = "acm-cert-expiring-soon"
  comparison_operator = "LessThanThreshold"
  threshold           = 14  # days
  evaluation_periods  = 1
  
  metric_query {
    id = "days_until_expiry"
    expression = "(cert_not_after - now()) / 86400"  # Calculated
  }
  
  alarm_actions = [aws_sns_topic.security_alerts.arn]
}
```

**7. Compliance & Audit Trail**
```bash
# Track all certificate changes for SOC2/PCI-DSS audits
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::CertificateManager::Certificate \
  --start-time 2026-01-01

# Terraform state: Mark certificate as sensitive
resource "aws_acm_certificate" "main" {
  ...
  lifecycle {
    prevent_destroy = true  # Catches accidental deletion before it happens
  }
}
```

**Real Incident I Managed:**

Company had BYOC (Bring Your Own Cert) from external CA. Employee managing it left; renewal process broken. Certificate expired 6 days later, 0:00 UTC on Sunday morning.

Fix I implemented:
1. Immediately switched to ACM (5-minute provisioning)
2. Set up DNS validation (preventing BYOC renewal issues)
3. Automated monitoring (alert at 30-day threshold)
4. Added runbook to Confluence (team-accessible)
5. Monthly certificate audit in incident review

Now: 4 years, zero certificate-related incidents.

**Key Principles:**
- **Automation > Manual:** ACM auto-renewal > BYOC manual
- **Monitoring >> Prevention:** Let systems catch problems, not humans
- **Policy Enforcement:** Terraform `prevent_destroy` prevents accidents
- **Backup Plan:** Keep secondary cert during rotation window"

---

### Q7: How do you handle a load balancer in a multi-tenant, regulated environment (PCI-DSS, HIPAA, GDPR)? Walk through your design.

**Expected Senior-Level Answer:**

"Compliance adds constraints to load balancer design. I've implemented this for healthcare/fintech platforms:

**PCI-DSS Requirements:**

1. **Encryption:** All traffic encrypted TLS 1.2+
   ```hcl
   # Enforce modern SSL policy
   resource "aws_lb_listener" "https" {
     ssl_policy = "ELBSecurityPolicy-FS-1-2-Res-2019-08"  # Forward secret only
     # PCI prohibits: RC4, MD5, Anonymous DH, Export-grade ciphers
   }
   ```

2. **Access Logging:** Every request logged for audit trail
   ```hcl
   resource "aws_lb" "main" {
     access_logs {
       bucket  = aws_s3_bucket.logs.id
       enabled = true
       prefix  = "alb-logs"
     }
   }
   
   # Store in S3 with:
   # - Encryption (SSE-S3)
   # - MFA delete enabled
   # - Lifecycle policy (90-day retention)
   # - Immutable flag for compliance
   ```

3. **Network Segmentation:** Isolate tenants
   ```hcl
   # Multi-tenant architecture
   resource "aws_lb" "tenant1" {
     # Separate ALB per tenant
     subnets = [aws_subnet.tenant1_private.id]
     security_groups = [aws_security_group.tenant1_alb.id]
   }
   
   resource "aws_lb" "tenant2" {
     subnets = [aws_subnet.tenant2_private.id]
     security_groups = [aws_security_group.tenant2_alb.id]
   }
   # Prevents one tenant's traffic from crossing to another
   ```

4. **WAF Integration:** Block malicious traffic
   ```hcl
   resource "aws_wafv2_web_acl" "pci_compliant" {
     name = "pci-compliant-waf"
     
     rule {
       name = "block-sql-injection"
       action = "BLOCK"
       statement {
         sqli_match_statement {}
       }
     }
     
     rule {
       name = "rate-limit-by-ip"
       action = "BLOCK"
       statement {
         rate_based_statement { limit = 2000 }  # 2k req/5min per IP
       }
     }
   }
   
   resource "aws_wafv2_web_acl_association" "alb" {
     resource_arn = aws_lb.main.arn
     web_acl_arn  = aws_wafv2_web_acl.pci_compliant.arn
   }
   ```

**GDPR Requirements:**

1. **Data Residency:** Ensure data stays in region
   ```hcl
   # EU customers' traffic:
   # - ALB in eu-west-1 (Ireland)
   # - Targets in eu-west-1
   # - Access logs in S3 eu-west-1
   # - NO cross-region replication
   
   # Route 53 geolocation routing enforces this
   resource "aws_route53_record" "eu_api" {
     geolocation_routing_policy { continent = "EU" }
     alias { name = aws_lb.eu.dns_name }
   }
   ```

2. **Right to be Forgotten:** Ability to delete customer data
   ```bash
   # Design allows:
   # - Delete customer record from DB
   # - ALB access logs auto-expire (lifecycle policy)
   # - Application logs purged
   # Problem: Access logs stored in S3, immu table flag
   # Solution: MFA delete (require approval before purge over 90 days)
   ```

3. **Data Processing Agreements:** Visibility into processing
   ```hcl
   # CloudTrail logs all ALB modifications (compliance audit)
   resource "aws_cloudtrail" "alb_audit" {
     enable_logging = true
     s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id
     
     event_selector {
       read_write_type = "All"
       include_management_events = true
       data_resources {
         type = "AWS::ElasticLoadBalancingV2::LoadBalancer"
         values = ["arn:aws:elasticloadbalancing:*:*:loadbalancer/*"]
       }
     }
   }
   ```

**HIPAA Requirements:**

1. **Encryption in Transit + at Rest:**
   ```hcl
   # ALB: TLS 1.2+ (transit)
   # S3 logs: SSE-S3 (at rest)
   # Database: Encrypted
   
   resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
     bucket = aws_s3_bucket.alb_logs.id
     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm = "AES256"  # SSE-S3 (AWS-managed keys)
         # HIPAA acceptable; cost-free
       }
     }
   }
   ```

2. **Audit Logging & Accountability:**
   ```bash
   # Every request logged with:
   # - Client IP
   # - Requested path
   # - Response status
   # - Response time
   # - Request size
   
   # Allows tracking who accessed PHI (Protected Health Information)
   # Queryable via Athena for compliance audits
   ```

3. **Backup & Disaster Recovery:**
   ```hcl
   # ALB not backed up (it's stateless, managed Service)
   # But configuration must be reproducible
   # Solution: Terraform state + CloudFormation templates
   # (backed up, versioned, tested for RTO < 1 hour)
   ```

**Real Compliance Incident I Managed:**

Financial services firm failed PCI-DSS audit because:
- ALB using deprecated TLS 1.0 (policy inherited from old config)
- Access logs not being retained (S3 bucket had no lifecycle policy)
- No WAF; open to SQL injection attacks

Solution:
1. Upgraded SSL policy: `ELBSecurityPolicy-FS-1-2-Res-2019-08` (45-min downtime during off-hours)
2. Enabled access logs with 90-day retention (no change)
3. Deployed WAF with common attack protections (zero downtime, ALB attached dynamically)
4. Passed re-audit 2 weeks later

Cost of compliance: ~$200/month (WAF) vs. cost of non-compliance (losing bank customers, fines, reputation damage): millions.

**Key Takeaway:** Compliance isn't added after the fact; it's built into the design from day one."

---

### Q8: You're investigating intermittent 502 Bad Gateway errors that don't correlate with high load. What's your systematic approach?

**Expected Senior-Level Answer:**

"502 Bad Gateway means ALB couldn't connect to backend or received invalid response. Intermittent nature suggests race condition, timeout, or resource exhaustion (not constant overload).

**Systematic Diagnosis:**

**Step 1: Characterize the Problem**
```bash
# When does it happen?
aws athena execute-query "
  SELECT 
    DATE_FORMAT(from_unixtime(time), '%H:%i:%s') as minute,
    COUNT(*) as count_502
  FROM alb_logs
  WHERE http_status_code = 502
  GROUP BY minute
  ORDER BY count_502 DESC
  LIMIT 10
"
# Result: 502s spike at specific times (e.g., 14:00:00, 14:15:00)
# Pattern suggests: scheduled job, cron task, batch operation

# Is it tied to specific targets?
aws athena execute-query "
  SELECT 
    target_ip,
    COUNT(*) as count_502,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY target_processing_time) as p95_latency
  FROM alb_logs
  WHERE http_status_code = 502
  GROUP BY target_ip
"
# Result: All targets equally affected? Or one target?
```

**Step 2: Check for Connection Pool Exhaustion**
```bash
# 502 often means: ALB can't establish connection to backend
# Reason 1: Target doesn't have port open
# Reason 2: TCP connection queue full

# SSH to target
netstat -tnap | grep LISTEN | grep :8080
# Result: Established connections count?
lsof -i :8080 | wc -l
# If approaching ulimit (ulimit -n), connection pool exhausted

# Check kernel TCP queue
cat /proc/sys/net/ipv4/tcp_max_syn_backlog
# Increase if too low (< 2048)
```

**Step 3: Application Hang / Slow Response**
```bash
# 502 can mean: ALB connects but app doesn't respond within timeout
# Default: 60 seconds

# Check application logs at time of 502s
grep "2026-03-07 14:00" /var/log/app/app.log | tail -50
# Look for: "Waiting for database", "Lock held", "GC Pause"

# Example real incident: Application thread pool exhausted
# Thread 1: Waiting for database (query slow)
# Thread 2: Waiting for Database
# ... (all 50 threads waiting)
# New request arrives: No threads available → 502

# Check thread count
jmax=$(jps -l | grep java)
jstack $jmax | grep "tid" | wc -l
# Compare to: -Xmx and thread pool settings
```

**Step 4: Intermittent Network Issues**
```bash
# If 502s are truly random:
# Cause 1: Packet loss on network link (rare)
# Cause 2: Cross-AZ latency spike (ALB in AZ-A sends to AZ-B; congestion)

# Check for cross-AZ traffic issues
aws ec2 describe-vpc-peering-connections \
  --filters Name=status-code,Values=active \
  --query 'VpcPeeringConnections[].VpcPeeringConnectionId'
# Verify peering connections don't have issues

# Check if cross-zone load balancing is helping
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[].LoadBalancerAttributes[?Key==`load_balancing.cross_zone.enabled`]'
# If false on ALB: Enable it (free for ALB)
```

**Step 5: Health Check False Negatives**
```bash
# Targets marked healthy but actually unhealthy
# Cause: Health check returns 200 OK, but app is hung

# Real example: Java GC pause
# App responds to health checks immediately (trivial endpoint)
# Regular requests hang (full app processing)
# Result: Healthy targets; user requests 502

# Solution: Health check should hit realistic code path
aws elbv2 describe-target-groups \
  --query 'TargetGroups[].HealthCheckPath'
# If path is /health or /status (trivial): It might miss issues
# Better: /api/healthcheck (exercises database, cache, etc.)
```

**Real Incident I Debugged (healthcare platform):**

502s exactly every 15 minutes (too regular to be load spike). Diagnosis:

1. Checked logs: 502s always at :00 and :15 seconds
2. Problem indication: Scheduled job (cron) every 15 minutes
3. Investigation: Backup job started every 15 minutes:
   ```bash
   */15 * * * * /usr/local/bin/backup.sh
   ```
4. Backup job:
   - Read lock on database (1–2 seconds)
   - Caused all queries to queue
   - After 10 seconds: ALB timeout → 502

5. Solution:
   ```bash
   # Run backup to separate replica, not primary
   # 0 3 * * * /usr/local/bin/backup.sh  # 3 AM, off-peak
   
   # Also: Add replica to read pool to distribute load better
   ```

**Key Insight:** Intermittent 502s are almost never ALB bugs. They're:
1. Backend overload/hang (app-level)
2. Connection exhaustion (infrastructure)
3. Resource contention (scheduled tasks)

Rarely: True network issues or ALB misconfiguration."

---

### Q9: You're designing a load balancer for a gaming platform with 100K concurrent connections and extremely latency-sensitive requirements. How would you architect this?

**Expected Senior-Level Answer:**

"Gaming platforms have extreme requirements: ultra-low latency (< 100ms critically), persistent connections, real-time interaction. ALB won't cut it.

**Architecture Decision:**

```
NLB (Layer 4) for primary load balancing
├─ UDP for real-time game updates (< 50ms latency)
├─ TCP for persistent connections (WebSocket)
└─ Multiple regional endpoints (us-east, us-west, eu, apac)
    with Global Accelerator for intelligent routing
```

**Design Rationale:**

1. **NLB vs ALB:**
   - ALB: 1–5ms overhead parsing HTTP (unacceptable for game)
   - NLB: 100µs–1ms (imperceptible; direct packet forwarding)
   - Gaming can't afford ALB latency + ALB doesn't support UDP

2. **Protocol Strategy:**
   ```
   • Game state updates: UDP (fast, okay if packet loss)
   • Critical actions: TCP (slower, guaranteed delivery)
   • Example: Character position updates via UDP, score updates via TCP
   ```

3. **Connection Affinity:**
   ```
   NLB 5-tuple hashing ensures:
   - Client [IP:Port] → Always same backend
   - Game server holds player state (position, inventory, etc.)
   - Switching servers mid-game = player kicked
   - 5-tuple ensures stability for hours-long sessions
   ```

**Architecture:**

```hcl
# Regional NLBs
resource "aws_lb" "game_us_east" {
  name               = "game-nlb-us-east-1"
  load_balancer_type = "network"
  subnets            = [aws_subnet.us_east_1a.id, aws_subnet.us_east_1b.id]
  
  # Preserve source IP (players see each other's true IPs)
  enable_cross_zone_load_balancing = false  # Latency-critical; no inter-AZ
}

# UDP Listener (Game state)
resource "aws_lb_listener" "game_udp" {
  load_balancer_arn = aws_lb.game_us_east.arn
  port              = 5555
  protocol          = "UDP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.game_servers.arn
  }
}

# TCP Listener (WebSocket fallback, chat)
resource "aws_lb_listener" "game_tcp" {
  load_balancer_arn = aws_lb.game_us_east.arn
  port              = 5556
  protocol          = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.game_servers.arn
  }
}

# Aggressive health checks (fast detection of dead servers)
resource "aws_lb_target_group" "game_servers" {
  name             = "game-servers"
  port             = 5555
  protocol         = "UDP"
  vpc_id           = aws_vpc.main.id
  
  health_check {
    protocol            = "UDP"
    interval            = 5      # Every 5 seconds (vs default 30)
    timeout             = 2      # 2-second timeout
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  
  deregistration_delay = 15  # Fast drain for dead servers
}

# Global Accelerator for intelligent geolocation routing
resource "aws_globalaccelerator_accelerator" "game" {
  name = "game-global"
  enabled = true
}

resource "aws_globalaccelerator_listener" "game" {
  accelerator_arn = aws_globalaccelerator_accelerator.game.arn
  
  port_ranges {
    from_port = 5555
    to_port   = 5556
  }
  
  protocol = "UDP"  # Game's primary protocol
}

resource "aws_globalaccelerator_endpoint_group" "us_east" {
  listener_arn          = aws_globalaccelerator_listener.game.arn
  endpoint_group_region = "us-east-1"
  
  endpoint_configuration {
    endpoint_id = aws_lb.game_us_east.arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "eu_west" {
  listener_arn          = aws_globalaccelerator_listener.game.arn
  endpoint_group_region = "eu-west-1"
  
  endpoint_configuration {
    endpoint_id = aws_lb.game_eu_west.arn
    weight      = 100
  }
}
```

**Key Optimizations:**

1. **Disable Cross-Zone (Counter-intuitive!):**
   ```hcl
   # Normally: cross-zone enabled for resilience
   # Gaming: Latency > Resilience
   # If AZ-A overloaded, accept 502 rather than route to AZ-B (high latency)
   enable_cross_zone_load_balancing = false
   
   # Trade-off: Higher per-AZ availability required
   # Run 2x redundancy in each AZ (not just 1)
   ```

2. **Health Check Timing:**
   - Normal: 30-second interval (acceptable down-time)
   - Gaming: 5-second interval (fast failure detection)
   - If server dies: Player disconnect in < 10 seconds, not 30+

3. **Deregistration Delay:**
   - Normal: 300 seconds (graceful drain)
   - Gaming: 15 seconds (fast recovery preferred)
   - Stale connections are worse than lost connections

4. **Global Accelerator:**
   - Uses AWS backbone (not internet)
   - Routes via lowest-latency path
   - Active-active: All regions serve load

**Connection State Management:**

```python
# Game server: Store minimal state
# (Player position, inventory, status)
# 
# On player disconnect:
# • Save state to Redis (fast access)
# • Next connection (same 5-tuple) resumes with state
# 
# If different player gets same IP:port (unlikely):
# • State doesn't transfer (stale data rejected)

# Redis: Single writer (game server)
#        Multiple readers (stats, matchmaking)
class GameServer:
    def on_player_position(self, player_id, x, y, z):
        # Update Redis immediately (1-2ms)
        redis.set(f"player:{player_id}:x", x)
        redis.set(f"player:{player_id}:y", y)
        
        # Broadcast to other players in region
        for other_player in region_players:
            send_udp_update(other_player, position)
    
    def on_disconnect(self, player_id):
        # Save state (Redis persists)
        # Next reconnect (same IP:port) resumes immediately
        pass
```

**Scaling Strategy:**

- Each NLB: ~50k concurrent connections
- 2 NLBs per region: 100k total
- 3 regions: 300k global capacity
- 5-tuple ensures stickiness; adding new NLB doesn't shuffle users

**Real Implementation Notes (from a gaming company):**

- Tested with 1M concurrent players across 4 regions
- Average latency: 42ms (US-East to US-West), 95ms (US to EU)
- 5-nines uptime achieved via redundancy + health checks
- Cost: ~$50k/month infrastructure (for 1M players)

**Common Mistakes:**

1. Using ALB for gaming: Too slow
2. Enabling cross-zone: Adds latency
3. Long deregistration delay: Stale connections hurt UX
4. Not using Global Accelerator: Random routing suboptimal

### Q10: You're involved in a cost optimization initiative. Identify ways to reduce load balancer costs by 30%. What's your approach?

**Expected Senior-Level Answer:**

"Load balancer costs come from several sources; I'd tackle them systematically:

**1. Right-sized LCU Consumption (~30% savings possible)**

```bash
# First: Understand current LCU usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name ProcessedBytes \
  --dimensions Name=LoadBalancer,Value=prod-alb \
  --start-time 2026-02-01 \
  --end-time 2026-03-07 \
  --period 86400 \
  --statistics Maximum \
  --query 'Datapoints[*].[Timestamp, Maximum]' \
  --output table | awk '{print $2}' | sort -rn | head -20

# Identify peak usage pattern
# LCU = MAX(connections/1K, requests/1M, processed_bytes/GB, etc.)

# Example result:
# Feb 15 (peak): 5 GB processed
# Feb 20: 2 GB processed
# Mar 5: 1.5 GB processed
# → Usage trending down; cost should too

# AWS bills on HIGHEST LCU dimension:
# Requests: 5M req/day = 5 LCU
# Bytes: 100 GB = 100 LCU
# → Billing bottleneck is bytes, not requests
```

**2. Consolidate Underutilized Load Balancers (~15% savings)**

```bash
# Audit: How many ALBs/NLBs do we have?
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName, Type, CreatedTime]' \
  --output table

# For each, check request count
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=prod-alb \
  --start-time 2026-02-01 \
  --end-time 2026-03-07 \
  --period 2592000  # 30 days
  --statistics Sum

# Example:
# legacy-api-alb: 100 req/day (< 1 LCU/month)
# → Consolidate to shared ALB
# Cost: $0.0225/LCU/hour = $16/month → eliminate

# Problem: Legacy app needs separate certificate?
# Solution: Use ALB host-based routing instead
```

Before:
```
ALB 1: legacy-api.example.com → internal target
ALB 2: modern-api.example.com → internal target
Cost: 2 × $16 = $32/month
```

After:
```
ALB 1 (shared):
  route /legacy/* → legacy-api targets
  route /modern/* → modern-api targets
Cost: $16/month (50% savings)
```

Terraform:
```hcl
resource "aws_lb_listener_rule" "legacy_api" {
  listener_arn = aws_lb.shared.listener_arn
  priority     = 1
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.legacy_api.arn
  }
  
  condition {
    path_pattern { values = ["/legacy/*"] }
  }
}

resource "aws_lb_listener_rule" "modern_api" {
  listener_arn = aws_lb.shared.listener_arn
  priority     = 2
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.modern_api.arn
  }
  
  condition {
    path_pattern { values = ["/modern/*"] }
  }
}
```

**3. Disable Unnecessary Features (~5% savings)**

```bash
# Access logs: $0.50 per 1M logs/day (optional)
# Are we using logs for monitoring?
aws s3 ls s3://alb-logs/ --summarize | tail -5
# If > 90 days old without access: Disable logging

aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn arn:aws:... \
  --attributes Key=access_logs.s3.enabled,Value=false

# Savings: ~$5–10/month per LB
```

```hcl
# X-Ray tracing: $0.50 per 1M traced requests (optional)
resource "aws_lb" "main" {
  # Only enable for debugging; disable in production
  # (Most issues resolvable via CloudWatch metrics + access logs)
}
```

**4. NLB → ALB Migration (if applicable) (~40% savings)**

```bash
# NLB cost: $0.006/LCU-hour (most expensive)
# ALB cost: $0.0225/LCU-hour (cheaper)
# Wait, that's backwards?

# Actually:
# ALB: $0.0225/LCU, but LCU calculation is different
# NLB: $0.006/LCU + $0.006/h per CZ if enabled

# Real cost comparison (100k req/sec):
# NLB: 100LCU × $0.006 × 730h =  $438/month
# ALB: 100LCU × $0.0225 × 730h = $1,642/month
# → NLB actually cheaper for high throughput!

# BUT: If using NLB for simple HTTP (could use ALB):
# • NLB unnecessary complexity
# • ALB handles 95% of cases for cheaper effective cost

# Decision: Check actual usage pattern
# If mostly simple HTTP routing: Switch ALB & consolidate
# If extreme throughput/low-latency: Keep NLB
```

**5. Cross-Zone Optimization (~10% savings)**

```bash
# Data transfer costs:
# NLB cross-zone: $0.006/LCU-hour extra
# ALB cross-zone: Free

# For NLB: Disable cross-zone if workload allows
aws elbv2 modify-load-balancer-attributes \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
 --attributes Key=load_balancing.cross_zone.enabled,Value=false

# Trade-off: If one AZ fails, remaining capacity is lower
# Cost savings: $0.006 × 730 × (max_LCU) ≈ $40–100/month per NLB

# BUT: Only if you have high-availability in each AZ already
# If 2 targets per AZ: Safe to disable
# If 1 target per AZ: Keep enabled (single point of failure)
```

**6. Lambda Functions for Simple Load Balancing (~20% savings in some cases)**

```python
# If ALB is only forwarding to 2 static targets
# (No complexity, no content-based routing)
# Consider ALB + Lambda for dynamic scaling

# Example: Session renewal service
# 10k req/day to 2 instances
# Cost of ALB: $16/month
# Cost of Lambda: $0.20/month (nearly free)

# Use: API Gateway + Lambda instead of ALB
# Savings: $15.80/month (not huge, but eliminates ALB)
```

**Real Cost Optimization I Did:**

Company had 15 ALBs for different services (each paying $0.0225/LCU/h):
- 12 underutilized
- 3 at peak capacity

Actions:
1. Consolidated 12 underutilized ALBs into 2 "shared" ALBs
   - Cost: 15 × $16 = $240/month → 5 × $16 = $80/month
   - Savings: $160/month

2. Disabled access logging (unused)
   - Cost: $8 × 15 = $120/month → $0
   - Savings: $120/month

3. Migrated one low-traffic service to API Gateway + Lambda
   - Cost: $16/month → $0.20/month
   - Savings: $15.80/month

4. Analyzed peak load; right-sized target group sizes
   - Before: 5 targets (avg 20% utilization)
   - After: 3 targets (avg 33% utilization, still healthy)
   - Ongoing cost reduction: $300/month (fewer compute instances)

**Total Savings: ~$600/month (30% of original load balancer costs)**

**Key Principle:** Load balancer costs are fixed (per-hour billing), so eliminating unnecessary ALBs has high impact. Prioritize consolidation + feature disablement over fine-tuning."

---

**End of Study Guide - Sections 1–10 Complete**

This comprehensive guide covers all 6 subtopics at senior DevOps level, including 5 hands-on scenarios and 10 interview questions with production-grade answers.




