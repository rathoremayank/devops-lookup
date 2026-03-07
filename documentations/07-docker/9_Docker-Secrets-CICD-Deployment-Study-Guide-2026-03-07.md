# Docker Secrets, CICD Pipelines, Production Deployment Patterns, Failure Scenarios & Troubleshooting
## Senior DevOps Study Guide

**Target Audience:** DevOps Engineers with 5–10+ years of experience  
**Last Updated:** March 7, 2026  
**Level:** Advanced / Senior

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [2.1 Secret Management Architecture](#21-secret-management-architecture)
   - [2.2 Build Pipeline Fundamentals](#22-build-pipeline-fundamentals)
   - [2.3 Deployment Strategy Principles](#23-deployment-strategy-principles)
   - [2.4 Observability & Failure Recovery](#24-observability--failure-recovery)
3. [Docker Secret Management](#docker-secret-management)
   - [3.1 Docker Secrets (Swarm Mode)](#31-docker-secrets-swarm-mode)
   - [3.2 HashiCorp Vault Integration](#32-hashicorp-vault-integration)
   - [3.3 AWS Secrets Manager Integration](#33-aws-secrets-manager-integration)
   - [3.4 Environment Variables & Runtime Injection](#34-environment-variables--runtime-injection)
   - [3.5 Secret Management Best Practices](#35-secret-management-best-practices)
4. [Docker Build Automation](#docker-build-automation)
   - [4.1 BuildKit Essentials](#41-buildkit-essentials)
   - [4.2 Multi-Stage Build Optimization](#42-multi-stage-build-optimization)
   - [4.3 Build Caching Strategies](#43-build-caching-strategies)
   - [4.4 Build Secrets & Build Args](#44-build-secrets--build-args)
   - [4.5 Security Scanning in Build Pipelines](#45-security-scanning-in-build-pipelines)
5. [Docker in CICD Pipelines](#docker-in-cicd-pipelines)
   - [5.1 Pipeline Architecture & Integration Patterns](#51-pipeline-architecture--integration-patterns)
   - [5.2 Build & Push Automation](#52-build--push-automation)
   - [5.3 Artifact Registry Management](#53-artifact-registry-management)
   - [5.4 Caching Layers in CICD](#54-caching-layers-in-cicd)
   - [5.5 Security Scanning & Compliance](#55-security-scanning--compliance)
6. [Production Deployment Patterns](#production-deployment-patterns)
   - [6.1 Blue-Green Deployments](#61-blue-green-deployments)
   - [6.2 Canary Deployments](#62-canary-deployments)
   - [6.3 Rolling Updates](#63-rolling-updates)
   - [6.4 A/B Testing & Feature Flags](#64-ab-testing--feature-flags)
   - [6.5 Service Mesh Integration](#65-service-mesh-integration)
7. [Failure Scenarios & Recovery](#failure-scenarios--recovery)
   - [7.1 Container Health Checks](#71-container-health-checks)
   - [7.2 Common Failure Modes](#72-common-failure-modes)
   - [7.3 Debugging Techniques](#73-debugging-techniques)
   - [7.4 Performance Bottlenecks](#74-performance-bottlenecks)
   - [7.5 Resource Constraints & OOMKilled](#75-resource-constraints--oomkilled)
8. [Hands-On Scenarios](#hands-on-scenarios)
9. [Interview Questions for Senior DevOps Engineers](#interview-questions-for-senior-devops-engineers)
10. [References & Further Reading](#references--further-reading)

---

## Introduction

### Overview of Topic

In modern containerized environments, the ability to manage secrets securely, automate builds efficiently, orchestrate deployments safely, and troubleshoot production failures is critical to enterprise DevOps operations. This study guide covers the advanced patterns and practices that senior DevOps engineers must master to design, implement, and operate resilient Docker-based systems at scale.

The five pillars addressed in this guide—secret management, build automation, CICD integration, deployment patterns, and failure recovery—form the backbone of modern cloud-native infrastructure. Together, they enable organizations to:

- **Maintain security compliance** while accelerating delivery pipelines
- **Reduce human error** through automation and standardized practices
- **Minimize downtime** using progressive deployment strategies
- **Recover quickly** from failures using proper observability and debugging

### Why It Matters in Modern DevOps Platforms

#### Security & Compliance
In containerized environments, secrets (API keys, database passwords, certificates) can easily leak through:
- Committed source code
- Docker images and layer history
- Container logs and environment variables
- Artifact registries without access controls

Senior DevOps engineers must implement defense-in-depth approaches using secret management systems (Docker Secrets, Vault, cloud-native secret managers) and never rely on single-point solutions.

#### Build Efficiency & Cost
Docker build optimization directly impacts:
- CI/CD pipeline duration (faster feedback loops)
- Artifact storage costs (smaller images, fewer layers)
- Registry bandwidth consumption
- Developer productivity and iteration cycles

BuildKit and advanced caching strategies can reduce build times by 70-90%, delivering significant ROI at scale.

#### Deployment Safety & Zero-Downtime Operations
Progressive deployment strategies (blue-green, canary, rolling) enable:
- Zero-downtime updates
- Immediate rollback capability if issues arise
- Gradual traffic migration to verify new versions
- Reduced blast radius of failed deployments

At scale, a single failed deployment can impact millions of users; deployment pattern selection is not optional.

#### Failure Observability & Recovery
Production failures are inevitable. The difference between a 5-minute incident and a 5-hour outage is:
- Proper health checks that detect failures early
- Instrumentation and logging that pinpoint root causes
- Runbooks and automation for rapid recovery
- Resource management preventing cascading failures

### Real-World Production Use Cases

**E-commerce Platform Example:**
An online retailer deploying Black Friday updates must:
- Deploy payment service updates with zero downtime (blue-green)
- Scale order processing 10x during traffic spikes (horizontal scaling, resource management)
- Detect failed payment processors within 10 seconds (health checks, monitoring)
- Rollback bad deployments instantly if payment failures detected (canary metrics)
- Protect API keys and database credentials across dev/staging/prod environments (secret management)

**Fintech Microservices Example:**
A financial services platform requires:
- Regulatory compliance (secret audit trails, encrypted storage)
- Sub-second failure detection (health checks, circuit breakers)
- Multi-region deployment with minimal latency (service mesh, traffic management)
- Build automation preventing security vulnerabilities (image scanning, SBOM generation)
- Automatic recovery without human intervention (self-healing, resource limits)

**High-Traffic SaaS Example:**
A platform serving millions of concurrent users must:
- Deploy code changes 10-50 times per day without downtime
- Validate new features with A/B testing before full rollout
- Detect performance regressions immediately (metrics-based canary gates)
- Manage secrets across thousands of clusters globally
- Recover from partial failures (circuit breakers, graceful degradation)

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Source Code Repository                     │
│                    (GitHub, GitLab, Bitbucket)                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │ Webhook Trigger
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│                  ┌─ CICD Pipeline (GitHub Actions, GitLab CI)   │
│   Build Stage    │  ├─ Code checkout & lint                    │
│ (Docker Build)   │  ├─ Run unit/integration tests              │
│                  │  ├─ Build Docker image with BuildKit        │
│                  │  ├─ Scan for vulnerabilities                │
│                  │  └─ Push to Artifact Registry (ECR, ACR)    │
└──────────────────────────────────────────────────────────────────┘
                       │
            ┌──────────┴──────────┐
            ▼                     ▼
    ┌──────────────────┐  ┌────────────────────┐
    │ Dev/Staging Env  │  │ Production Env      │
    │  (Blue-Green)    │  │  (Canary → Final)  │
    └──────────────────┘  └────────────────────┘
            │                     │
        ┌───▼─────┬──────────┬────▼────┬─────────┐
        │ Secrets │ Logging  │ Metrics │ Tracing │
        │ Manager │ (ELK)    │(Prom)   │ (Jaeger)│
        └─────────┴──────────┴─────────┴─────────┘
```

The architecture above shows where each component fits:

1. **Source Code → CICD Pipeline:** Developers push code; webhooks trigger automated build
2. **CICD Pipeline:** Orchestrates docker build, testing, scanning, and push
3. **Artifact Registry:** Stores built images with metadata (signatures, vulnerabilities, labels)
4. **Deployment Targets:** Receive and run Docker images using deployment patterns
5. **Observability Stack:** Monitors health, logs, metrics, and traces for troubleshooting

---

## Foundational Concepts

### 2.1 Secret Management Architecture

#### Core Principles

**Defense in Depth:** Never rely on a single layer of security. Implement multiple controls:
- Encryption at rest (in vault/manager)
- Encryption in transit (TLS/mTLS)
- Access control (RBAC, least privilege)
- Audit logging (who accessed what, when)
- Rotation policies (reduce blast radius of compromised secrets)

**Zero Trust Model:** 
- Assume secrets can be compromised at any time
- Implement certificate-based authentication for service-to-service communication
- Rotate short-lived credentials frequently (minutes to hours, not years)
- Never trust implicit identity; always verify cryptographically

#### Secret Lifecycle

Secrets follow a lifecycle that determines where and how they're stored:

```
Development → Testing → Staging → Production
    │            │          │          │
 Plaintext   Environment   Vault    Vault + mTLS
 in Config   Variables   + RBAC    + Short TTL
             (temporary)          + Audit Logs
```

**Development:** Secrets in local `.env` files (never committed)  
**Testing/Staging:** Vault with limited access; rotated monthly  
**Production:** Vault with mTLS authentication; TTLs 1-24 hours; full audit trail  

#### Secret Injection Methods

| Method | Use Case | Security | Complexity |
|--------|----------|----------|-----------|
| Environment Variables | Simple apps, dev/test | ⭐ Low | ⭐ Low |
| Docker Secrets (Swarm) | Multi-tenant swarms | ⭐⭐ Medium | ⭐⭐ Medium |
| Vault | Enterprise, multi-cloud | ⭐⭐⭐ High | ⭐⭐⭐ High |
| Cloud Secret Managers | AWS/Azure/GCP native | ⭐⭐⭐ High | ⭐⭐ Medium |
| Init Containers | Kubernetes-native | ⭐⭐⭐ High | ⭐⭐ Medium |

---

### 2.2 Build Pipeline Fundamentals

#### Build Pipeline Architecture

A production-grade Docker build pipeline balances **speed, security, and reproducibility**:

```
Code Commit
    │
    ▼
┌──────────────────────────────────────┐
│ 1. Source Code Fetch & Validation    │
│    - Clone repo                      │
│    - Verify commit signature         │
└──────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────┐
│ 2. Build Phase (BuildKit)            │
│    - Parallel layer builds           │
│    - Build cache reuse               │
│    - Build secrets isolation         │
└──────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────┐
│ 3. Security Scanning                 │
│    - Image vulnerability scan        │
│    - SBOM (Software Bill of Materials)
│    - License compliance              │
│    - Container signing (Cosign)      │
└──────────────────────────────────────┘
    │
    ▼
┌──────────────────────────────────────┐
│ 4. Artifact Management               │
│    - Push to registry with metadata  │
│    - Tag with version/commit         │
│    - Sign images                     │
└──────────────────────────────────────┘
```

#### Key Performance Metrics

- **Build Duration:** Target < 5 minutes for typical applications (heavily depends on tests)
- **Cache Hit Rate:** >= 80% (indicates effective layer reuse)
- **Image Size:** Baseline + 100MB per additional layer (minimize with multi-stage)
- **Security Vulnerabilities:** 0 critical, < 5 high before production

---

### 2.3 Deployment Strategy Principles

#### Progressive Delivery Framework

Modern deployments follow a progression from safe-but-slow to fast-but-risky:

```
Rolling Updates      Canary              Blue-Green         Feature Flags
────────────────────────────────────────────────────────────────────
5-20 min deploy     5-30 min deploy     Instant cutover    Instant toggle
All users affected   1-5% users first    Zero downtime      Subset of users
Observable drift     Metrics-driven      Easy rollback       Business control
Medium risk         Low risk             High complexity     No infra outage
```

**Selection Criteria:**

- Use **Rolling Updates** for: Stateless services, non-critical applications, frequent deployments
- Use **Canary** for: Payment services, critical infrastructure, high-traffic systems
- Use **Blue-Green** for: Database migrations, large infrastructure changes, regulatory requirements
- Use **Feature Flags** for: A/B testing, gradual feature rollout, kill switches

#### Deployment Safety Principles

1. **Immutability:** Once an image is built, never change it. Redeploy with new versions only.
2. **Idempotency:** Running deployment N times = running it once (safe retries)
3. **Quick Feedback:** Know within 2-5 minutes if deployment is failing
4. **Automatic Rollback:** Failed metrics trigger instant rollback; no manual intervention
5. **Blast Radius:** Limit scope (one region, one service, one percentage of traffic)

---

### 2.4 Observability & Failure Recovery

#### Observability Pillars

Production systems require four types of observability:

| Pillar | Purpose | Example Tools |
|--------|---------|----------------|
| **Metrics** | Numerical measurements of system state | Prometheus, Datadog, CloudWatch |
| **Logging** | Detailed event records for debugging | ELK, Splunk, CloudWatch Logs |
| **Traces** | Request-level execution paths | Jaeger, Zipkin, DataDog APM |
| **Health Checks** | Binary pass/fail signals | Kubernetes probes, ALB health checks |

#### Failure Recovery Hierarchy

```
Level 1: Prevention
├─ Image scanning (catch vulnerabilities before deploy)
├─ Health checks (detect failures early)
└─ Resource limits (prevent cascading failures)

Level 2: Protection
├─ Circuit breakers (stop calling failing services)
├─ Retry policies (temporary failures)
└─ Request timeouts (prevent hanging)

Level 3: Recovery
├─ Auto-restart containers (self-healing)
├─ Auto-scaling (handle load spikes)
├─ Failover (switch to healthy instances)
└─ Rollback (undo bad deployment)

Level 4: Mitigation
├─ Graceful degradation (serve with reduced features)
├─ Cache fallback (use stale data)
├─ Service isolation (prevent cascade)
└─ Incident runbooks (manual intervention)
```

---

## Key Terminology

### Build & Image Terms
- **Layer:** Immutable filesystem snapshot in Docker image inheritance chain
- **BuildKit:** Modern Docker build engine enabling parallel, efficient builds
- **Build Cache:** Reusable intermediate images between builds
- **Multi-Stage Build:** Dockerfile with multiple `FROM` statements reducing final image size
- **Build Args:** Variables passed during image build (compile-time)
- **Build Secrets:** Sensitive data passed during build but not stored in image

### Deployment Terms
- **Blue-Green:** Two identical production environments; instant cutover from blue to green
- **Canary:** Gradual traffic shift to new version (5% → 25% → 50% → 100%)
- **Rolling Update:** Gradual container replacement (1 old, 1 new → both new)
- **Zero Downtime:** Deployment without service interruption
- **Rollback:** Revert to previous version if new version fails

### Operational Terms
- **Health Check:** Periodic readiness/liveness probe determining container fitness
- **OOMKilled:** Out-of-memory termination due to resource limit exceeded
- **Circuit Breaker:** Temporarily stop retrying failing dependencies
- **Graceful Shutdown:** Clean application termination with connection drainage
- **MTTR:** Mean Time To Recovery; how quickly systems recover from failures

### Architecture Terms
- **Service Mesh:** Networking infrastructure managing inter-service communication (Istio, Linkerd)
- **Artifact Registry:** Centralized image storage and distribution (Docker Hub, ECR, ACR)
- **Secret Manager:** Centralized sensitive data storage with access controls (Vault, AWS Secrets Manager)
- **SBOM (Software Bill of Materials):** Complete list of dependencies and licenses in artifact

---

## Architecture Fundamentals

### Secret Flow Through the System

```
┌─────────────────────────────────────────────────────────────────┐
│                        Secret Manager                           │
│                    (Vault/AWS Secrets Mgr)                      │
│              Encrypted, Rotated, Audited                        │
└──────────────────┬──────────────────────────────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
    ┌────────┐ ┌────────┐ ┌──────────┐
    │ CICD   │ │ Init   │ │ Service  │
    │ Runner │ │Container│ │ Startup  │
    └────┬───┘ └────┬───┘ └────┬─────┘
         │          │          │
         └──────────┼──────────┘
                    │
                    ▼
          ┌──────────────────┐
          │   Running        │
          │    Container     │
          │  (In-Memory)     │
          └──────────────────┘
         
         ✓ Secret never in:
           - Source code
           - Environment variables
           - Container image layer
           - Logs or stdout
```

### Build Pipeline Security Architecture

```
Untrusted Input              Build Execution           Trusted Output
    │                             │                         │
    ├─ Source code          ┌─────────────────┐         ├─ Signed image
    ├─ Build args           │ BuildKit        │         ├─ Vulnerability scan
    └─ Build secrets        │ ├─ Layer cache  │         ├─ SBOM
                           │ ├─ Isolation    │         └─ Metadata
                           │ └─ Secret purge  │
                           └─────────────────┘
                                   │
                           Scanning Pipeline
                                   │
                           ├─ Trivy (vulnerabilities)
                           ├─ Policy check (compliance)
                           ├─ License scan (legal)
                           └─ Sign image (Cosign)
```

---

## Important DevOps Principles

### 1. Shift Left: Catch Issues Early

| Stage | Action | Benefit |
|-------|--------|---------|
| Development | Lint Docker files, run unit tests | Fix issues before commit |
| Build | Scan images, analyze SBOM | Prevent vulnerable artifacts |
| Registry | Policy enforcement, access controls | Block bad deployments |
| Deployment | Health checks, canary validation | Quick failure detection |
| Production | Monitoring, alerting, runbooks | Rapid response |

**Cost Impact:** Fixing a security vulnerability in development costs $100; in production costs $10,000.

### 2. Infrastructure as Code: Deployments Are Repeatable

- Deployment specifications (Kubernetes manifests, docker-compose, Terraform) are version-controlled
- Same manifest can be deployed 1000 times identically
- Changes are reviewed, tested, and audited before deployment
- Rollback is "deploy previous version" not "click undo"

### 3. Observability Over Assumption: Trust Metrics, Not Hopes

- Never assume a deployment is successful
- Health checks and metrics prove success/failure
- Decisions (rollback, scale) are data-driven, not manual
- Every failure is analyzed for root cause and prevention

### 4. Blast Radius Minimization: Contain Failures

- A single region/zone failure doesn't bring down the entire system
- Canary deployments affect 1-5% of users first
- Resource limits prevent one replica consuming all CPU
- Circuit breakers prevent cascade failures across microservices

### 5. Secrets Separation: Minimal Privilege

- Applications only get secrets they need
- Rotated frequently (hours/days, not years)
- Audit logs show who accessed what
- Compromised secret immediately revoked; blast radius tiny

---

## Best Practices

### Secret Management
✓ **DO:**
- Store all secrets in a secret manager (never in source code)
- Rotate credentials every 30-90 days minimum
- Use short-lived tokens (1-24 hours) where possible
- Log all secret access for compliance/audit
- Implement least-privilege access (app only gets secrets it needs)

✗ **DON'T:**
- Commit secrets to git (you can't "unring the bell")
- Use the same secret across environments
- Store secrets in environment variables in production
- Log secret values (even in debug mode)
- Trust secrets in Docker image layers

### Build Optimization
✓ **DO:**
- Use BuildKit for parallel, efficient builds
- Leverage multi-stage builds to minimize image size
- Order Dockerfile commands from least-changed to most-changed
- Cache external dependencies separately from code
- Scan images for vulnerabilities before push

✗ **DON'T:**
- Build debugging tools into production images
- Store large temporary files without cleanup
- Run multiple services in one container
- Commit large binaries; use build artifacts only
- Ignore layer history; unused layers cost storage

### Deployment Strategy
✓ **DO:**
- Use canary/rolling deployments for critical services
- Validate deployments with health checks and metrics
- Implement automatic rollback on health check failure
- Test deployment process in staging environment
- Have documented runbooks for incident response

✗ **DON'T:**
- Deploy directly to 100% of production
- Manual verification instead of automated health checks
- Ignore previous version availability for quick rollback
- Deploy during peak traffic hours
- Skip staging environment testing

### Observability
✓ **DO:**
- Implement health checks (readiness, liveness)
- Log structured events with timestamps/IDs for tracing
- Collect metrics at service and infrastructure level
- Monitor deployment progress with SLOs/SLIs
- Set up alerting for anomalies (not just thresholds)

✗ **DON'T:**
- Rely on humans to detect failures
- Log raw data; structure with key=value pairs
- Monitor only infrastructure (network, CPU); ignore application metrics
- Alert on every metric; tune alerts to actionable events
- Use "on-call engineer checking the dashboard" as incident response

---

## Common Misunderstandings

### Misunderstanding #1: "Env Variables Are Secure Enough"
**Reality:** Environment variables are visible to anyone who can:
- Access the process (ps command)
- View container logs/stdout
- Inspect running container metadata
- Access deployment manifest files

**Correct Approach:** Use secret managers with access controls and rotation.

### Misunderstanding #2: "Bigger Images Are More Feature-Complete"
**Reality:** Larger images increase attack surface, deployment time, and storage costs without proportional benefit.

Example: A Node.js app in a full Ubuntu image (1.2GB) vs. Alpine (150MB) has 8x the vulnerabilities to patch.

**Correct Approach:** Use minimal base images; multi-stage builds to discard build dependencies.

### Misunderstanding #3: "Blue-Green Is Always Better Than Rolling Updates"
**Reality:** Blue-green doubles infrastructure cost. For stateless services, rolling updates with health checks are equally safe and more cost-efficient.

Blue-green is necessary for: database migrations, breaking API changes, compliance requirements.

**Correct Approach:** Choose deployment strategy based on risk profile and cost constraints.

### Misunderstanding #4: "If a Container Restarts, Everything Is Fine"
**Reality:** Frequent restarts indicate underlying problems (memory leaks, crashes, misconfiguration).

A service that crashes and restarts 10x per minute is "running" but completely broken.

**Correct Approach:** Implement observability to detect failures, fix root causes; restarts are emergencies, not operating mode.

### Misunderstanding #5: "Secrets Rotation Is 'Nice to Have'"
**Reality:** Compromised secrets that rotate daily limit blast radius to that day. Secrets that rotate annually compromise everything for a year.

PCI-DSS, HIPAA, and SOC 2 require rotation; many breaches succeed because stale credentials were still valid.

**Correct Approach:** Rotate all secrets monthly minimum; use short-lived tokens where possible.

---

---

## Docker Secret Management

### 3.1 Docker Secrets (Swarm Mode)

#### Internal Working Mechanism

Docker Secrets is the native secret management system in Docker Swarm. Secrets are stored in the Swarm's distributed state (Raft consensus) and encrypted at rest using the manager node's encryption key.

**Storage Architecture:**
```
┌─────────────────────────────────────┐
│     Docker Swarm Manager            │
│  ┌──────────────────────────────┐  │
│  │ Raft Consensus Store         │  │
│  │ ├─ Secret name: db_password  │  │
│  │ ├─ Value: [encrypted blob]   │  │
│  │ ├─ Version: 5                │  │
│  │ ├─ Created: 2026-03-07...    │  │
│  │ └─ Metadata                  │  │
│  └──────────────────────────────┘  │
│           │                         │
│           ▼ (Replication)           │
│  ┌──────────────────────────────┐  │
│  │ Manager 2 (Replica)          │  │
│  │ [Encrypted Copy]             │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
           │
           ▼ (On service deploy)
    ┌──────────────┐
    │ Worker Node  │
    │ Running      │
    │ Container    │
    │ Secret at:   │
    │ /run/secrets/│
    │ [secret_name]│
    └──────────────┘
```

**Key Characteristics:**
- Secrets stored only on manager nodes; encrypted with per-manager keys
- Only services explicitly granted access receive secrets
- Secrets appear as tmpfs mounts in container `/run/secrets/` directory
- Read-only files; applications must read at startup
- Cannot be updated; new version = new secret with versioning

#### Architecture Role

Docker Secrets sit at the **Swarm orchestration layer**, separate from images and container runtime. This design ensures:

1. **Isolation:** Secrets never baked into images; safe to push images to public registries
2. **Least Privilege:** Secrets only mounted when needed (Swarm granting access)
3. **Encryption:** Encrypted in storage (manager nodes) and in transit (TLS)
4. **Rollout Control:** Deploy new secret version without redeploying images

#### Production Usage Patterns

**Pattern 1: Database Credentials for Multi-Tier App**

```bash
# DevOps engineer creates secrets in Swarm
docker secret create db_user - <<< "app_user"
docker secret create db_password - <<< "super_secure_pw_$(openssl rand -base64 24)"
docker secret create db_host - <<< "postgres.internal:5432"

# Deployed via stack YAML
version: '3.1'
services:
  app:
    image: myapp:latest
    secrets:
      - db_user
      - db_password
      - db_host
    environment:
      DB_USER_FILE: /run/secrets/db_user
      DB_PASSWORD_FILE: /run/secrets/db_password
      DB_HOST_FILE: /run/secrets/db_host

secrets:
  db_user:
    external: true
  db_password:
    external: true
  db_host:
    external: true
```

**Application startup code (Go example):**
```go
package main

import (
    "io/ioutil"
    "log"
    "strings"
)

func loadSecret(path string) (string, error) {
    data, err := ioutil.ReadFile(path)
    if err != nil {
        return "", err
    }
    return strings.TrimSpace(string(data)), nil
}

func main() {
    dbUser, _ := loadSecret("/run/secrets/db_user")
    dbPass, _ := loadSecret("/run/secrets/db_password")
    dbHost, _ := loadSecret("/run/secrets/db_host")
    
    // Connect to database with loaded credentials
    connStr := fmt.Sprintf("postgres://%s:%s@%s/mydb", dbUser, dbPass, dbHost)
    // ... establish connection
}
```

**Pattern 2: TLS Certificates for HTTPS Services**

```bash
# Create certificates (typically done once, renewed annually)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Load into Swarm
docker secret create tls_cert - < cert.pem
docker secret create tls_key - < key.pem

# Service manifest
services:
  webserver:
    image: nginx:latest
    ports:
      - "443:443"
    secrets:
      - tls_cert
      - tls_key
    configs:
      - nginx.conf  # References secrets paths
```

Nginx configuration:
```nginx
server {
    listen 443 ssl;
    ssl_certificate /run/secrets/tls_cert;
    ssl_certificate_key /run/secrets/tls_key;
    # ... rest of config
}
```

#### DevOps Best Practices

✓ **DO:**
- Rotate secrets every 90 days (create new secret, redeploy service, delete old secret)
- Use secrets only for sensitive data (passwords, keys, tokens)
- Implement secret versioning (e.g., `db_password_v1`, `db_password_v2`)
- Document secret lifecycle in runbooks
- Audit secret access using `docker secret inspect` and logs

✗ **DON'T:**
- Use secrets for non-sensitive config (use configs instead)
- Store plaintext secrets in compose files or source control
- Mount entire `/run/secrets/` directory if app only needs one secret
- Forget to remove old secrets after rotation

**Backup & Disaster Recovery:**
```bash
# Export all secrets (encrypted)
for secret in $(docker secret ls --format "{{.Name}}"); do
    docker secret inspect "$secret" > "backup_$secret.json"
done

# If Swarm compromised, manually re-create from secure backup location
docker secret create db_password - < /secure/backup_location/db_password
```

---

### 3.2 HashiCorp Vault Integration

#### Internal Working Mechanism

Vault is the industry-standard secret manager providing:
- **Dynamic Secrets:** Generate temporary credentials on-demand (reduces rotation overhead)
- **Encryption as a Service:** Encrypt/decrypt without storing secrets
- **Audit Logging:** Complete trail of who/what/when for compliance
- **Multi-cloud Support:** Works across AWS, Azure, GCP, on-prem

**Vault Architecture with Docker:**
```
                    Developer/App Request
                            │
                            ▼
                    ┌──────────────────┐
                    │  Vault Client    │
                    │  (In container)  │
                    └────────┬─────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
    ┌────────────────┐ ┌───────────────┐ ┌──────────────┐
    │ Transit Engine │ │ Secret Engine │ │ Auth Method  │
    │ (Encrypt/Dec) │ │ (Store secret)│ │ (Verify ID)  │
    └────────┬───────┘ └───────┬───────┘ └──────┬───────┘
             │                 │                │
             └─────────────────┼────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Audit Backend      │
                    │  [WHO/WHAT/WHEN]    │
                    └─────────────────────┘
```

**Dynamic Secret Example (Database Credentials):**

When an app requests credentials for PostgreSQL:
```
1. App → Vault: "Give me creds for postgres database"
2. Vault → Consul: "Generate random username/password"
3. Consul → PostgreSQL: "CREATE ROLE app_temp_123 WITH PASSWORD 'xyz'"
4. Vault → App: "Username: app_temp_123, Password: xyz, TTL: 1 hour"
5. After 1 hour: Vault → PostgreSQL: "DROP ROLE app_temp_123"
```

**Advantages over static secrets:**
- Credentials automatically expire; compromise window is 1 hour, not 90 days
- Audit log shows which app used which credentials
- Revocation is instant (drop role immediately if suspected breach)

#### Architecture Role

Vault provides **centralized secret management across all infrastructure layers:**

```
┌──────────────────────────────────────────────────────┐
│            Multi-Cloud Infrastructure                 │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │   Docker     │  │  Kubernetes  │  │ Traditional│ │
│  │   Swarm      │  │  Cluster     │  │   VMs      │ │
│  │              │  │              │  │            │ │
│  │  App ──┐     │  │  App ──┐     │  │ App ──┐    │ │
│  │        │     │  │        │     │  │       │    │ │
│  └────────┼─────┘  └────────┼─────┘  └───────┼────┘ │
│           │                 │                │      │
│           └─────────────────┼────────────────┘      │
│                             │                       │
│                             ▼                       │
│                    ┌──────────────────┐             │
│                    │  HashiCorp Vault │             │
│                    │  (Centralized)   │             │
│                    └──────────────────┘             │
│                                                     │
└──────────────────────────────────────────────────────┘
```

#### Production Usage Patterns

**Pattern 1: Docker Container with Vault Agent**

Vault provides an agent that runs as sidecar or init container, automatically renewing secrets:

```dockerfile
# Dockerfile with Vault Agent
FROM vault:latest as vault
FROM myapp:latest

# Copy Vault binary
COPY --from=vault /bin/vault /usr/local/bin/vault

# Copy agent config and entrypoint
COPY vault-agent.hcl /etc/vault/agent.hcl
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

Agent configuration (`vault-agent.hcl`):
```hcl
vault {
  address = "https://vault.company.internal:8200"
}

auto_auth {
  method {
    type = "approle"
    
    config = {
      role_id_file_path = "/var/run/secrets/kubernetes.io/serviceaccount/role-id"
      secret_id_file_path = "/var/run/secrets/kubernetes.io/serviceaccount/secret-id"
    }
  }
}

cache {
  use_auto_auth_token = true
  enforce_consistency = "always"
  when_inconsistent = "retry"
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}

template {
  source = "/etc/vault/templates/db-config.tpl"
  destination = "/etc/app/db-config.json"
  command = "pkill -HUP -f myapp"  # Signal app to reload
}
```

Template (`/etc/vault/templates/db-config.tpl`):
```json
{
  "db_host": "{{ with secret "database/config/postgres" }}{{ .Data.data.host }}{{ end }}",
  "db_user": "{{ with secret "database/roles/app" }}{{ .Data.data.username }}{{ end }}",
  "db_password": "{{ with secret "database/roles/app" }}{{ .Data.data.password }}{{ end }}"
}
```

Entrypoint script:
```bash
#!/bin/bash
set -e

# Start Vault Agent in background
/usr/local/bin/vault agent -config=/etc/vault/agent.hcl &
AGENT_PID=$!

# Wait for secrets to be rendered
sleep 2
while [ ! -f /etc/app/db-config.json ]; do
  sleep 1
done

# Start main application
exec myapp --config=/etc/app/db-config.json
```

**Pattern 2: Vault AppRole for Docker Swarm Services**

AppRole is designed for service-to-service authentication:

```hcl
# Vault configuration (one-time setup)
path "secret/data/docker-app/*" {
  capabilities = ["read", "list"]
}

path "database/creds/readonly" {
  capabilities = ["read"]
}
```

Swarm service deployment with init container:
```yaml
version: '3.1'

services:
  app:
    image: myapp:latest
    depends_on:
      vault-init:
        condition: service_completed_successfully
    volumes:
      - vault-token:/tmp/vault/token
    environment:
      VAULT_ADDR: "https://vault.company.internal:8200"
      VAULT_TOKEN_FILE: "/tmp/vault/token/.vault-token"

  vault-init:
    image: vault:latest
    volumes:
      - vault-token:/tmp/vault/token
    environment:
      VAULT_ADDR: "https://vault.company.internal:8200"
      ROLE_ID: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
      SECRET_ID: "ffffffff-0000-1111-2222-333333333333"
    command: |
      sh -c '
        vault write -field=client_token auth/approle/login \
          role_id=$ROLE_ID secret_id=$SECRET_ID > /tmp/vault/token/.vault-token
        chmod 644 /tmp/vault/token/.vault-token
      '
```

**Pattern 3: Vault for Database Credential Rotation**

```bash
#!/bin/bash
# Setup: One-time configuration

# Enable database engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  allowed_roles="app-role,backup-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres.internal:5432/postgres" \
  username="vault_admin" \
  password="$(openssl rand -base64 24)"

# Create dynamic app role (TTL: 1 hour)
vault write database/roles/app-role \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Application requests credentials
while true; do
  CREDS=$(vault kv get -format=json database/creds/app-role)
  DB_USER=$(echo $CREDS | jq -r '.data.data.username')
  DB_PASS=$(echo $CREDS | jq -r '.data.data.password')
  
  # Connect with temporary credentials
  psql -h postgres.internal -U "$DB_USER" -p 5432 mydb <<< "SELECT * FROM users LIMIT 10;"
  
  # Secrets auto-expire after 1 hour
  sleep 3600
done
```

#### DevOps Best Practices

✓ **DO:**
- Use Vault HA cluster with persistent storage (Consul, DynamoDB, PostgreSQL)
- Implement AppRole for service authentication; rotate secret IDs regularly
- Store Vault unseal keys in different locations (geographic/social separation)
- Monitor Vault audit logs for anomalies (failed auth, mass secret access)
- Use dynamic secrets for databases/cloud APIs; shorter TTL = safer

✗ **DON'T:**
- Run Vault in single-instance mode in production
- Hard-code static AppRole credentials; use init containers or orchestrator auth
- Leave audit logging disabled
- Ignore Vault security updates; patch immediately
- Use same secret for multiple services—each service gets own credentials

---

### 3.3 AWS Secrets Manager Integration

#### Internal Working Mechanism

AWS Secrets Manager is the cloud-native secret management service providing:
- Automatic rotation via Lambda-based rotation functions
- Encryption using KMS (keys managed by AWS or customer)
- Fine-grained IAM access control
- Audit logging via CloudTrail

**Architecture:**

```
┌────────────────────────────────────────────────────┐
│          AWS Account                               │
│  ┌────────────────────────────────────────────┐   │
│  │        Secrets Manager Service             │   │
│  │  ┌──────────────────────────────────────┐  │   │
│  │  │ Secret: prod/db-password             │  │   │
│  │  │ ├─ Current: [encrypted with KMS]     │  │   │
│  │  │ ├─ Previous: [encrypted with KMS]    │  │   │
│  │  │ ├─ RotationFunction: lambda-rotate   │  │   │
│  │  │ ├─ RotationRules: 30 days            │  │   │
│  │  │ └─ LastRotated: 2026-02-07 10:30:00  │  │   │
│  │  └──────────────┬───────────────────────┘  │   │
│  │                │                            │   │
│  │                ▼ (Encryption)              │   │
│  │  ┌──────────────────────────────────────┐  │   │
│  │  │ AWS KMS (Key Management Service)    │  │   │
│  │  │ ├─ Customer Master Key (CMK)        │  │   │
│  │  │ ├─ Key rotation policy: annual      │  │   │
│  │  │ └─ CloudTrail logging: enabled      │  │   │
│  │  └──────────────────────────────────────┘  │   │
│  │                                            │   │
│  │  ┌──────────────────────────────────────┐  │   │
│  │  │ Rotation Lambda                      │  │   │
│  │  │ └─ Triggered automatically every 30d │  │   │
│  │  └──────────────────────────────────────┘  │   │
│  └────────────────────────────────────────────┘   │
│                     │                              │
│       ┌─────────────┼─────────────┐               │
│       │             │             │               │
│       ▼             ▼             ▼               │
│   EC2/ECS   RDS Database    Lambda Function      │
│   Container  (auto-update)   (gets secret)       │
└────────────────────────────────────────────────────┘
```

**Rotation Flow:**

```
Step 1: Rotation Triggered
  └─> Lambda function creates new DB password
      └─> Update database user password
          └─> Verify new password works

Step 2: Metadata Update
  └─> Update Secrets Manager metadata
      └─> Current = new_password
          Previous = old_password
          VersionStaged = [date]

Step 3: Verification
  └─> Lambda confirms application can authenticate
      └─> Applications automatically get new secret

Step 4: Cleanup
  └─> After 7 days, old password marked for deletion
  └─> Previous password still available for emergency access
```

#### Architecture Role in Docker/Kubernetes

Secrets Manager is the **default choice in AWS environments** because:
1. **Native Integration:** ECS, EKS, Lambda can directly fetch secrets
2. **Automatic Rotation:** No manual intervention needed
3. **Audit Trail:** Every access logged to CloudTrail
4. **IAM Integration:** Secrets protected using existing IAM policies

Docker/K8s integration approaches:

**Approach 1: External Secrets Operator (Kubernetes native)**
```yaml
apiVersion: v1
kind: SecretStore
metadata:
  name: aws-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
    - secretKey: username
      remoteRef:
        key: prod/database/username
    - secretKey: password
      remoteRef:
        key: prod/database/password
```

**Approach 2: Docker with AWS SDK**
```dockerfile
FROM python:3.11

RUN pip install boto3

COPY app.py /app/app.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
```

Entrypoint that fetches secret at runtime:
```bash
#!/bin/bash
set -e

# Fetch secret from AWS Secrets Manager
# Uses EC2 instance IAM role or ECS task role for authentication
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id prod/database-credentials \
  --region us-east-1 \
  --query SecretString \
  --output text)

# Export as environment variables (in-memory only)
export DB_HOST=$(echo $SECRET | jq -r '.host')
export DB_USER=$(echo $SECRET | jq -r '.username')
export DB_PASS=$(echo $SECRET | jq -r '.password')

# Start application
exec python /app/app.py
```

#### Production Usage Patterns

**Pattern 1: Automatic RDS Password Rotation**

```bash
# One-time setup: Create secret for RDS database
aws secretsmanager create-secret \
  --name prod/rds-mysql-password \
  --description "RDS MySQL master password" \
  --kms-key-id arn:aws:kms:us-east-1:123456789:key/12345678-1234-1234-1234-123456789012 \
  --secret-string '{
    "username": "admin",
    "password": "'$(openssl rand -base64 32)'",
    "engine": "mysql",
    "host": "mydb.c9akciq32.us-east-1.rds.amazonaws.com",
    "port": 3306,
    "dbname": "mydb"
  }'

# Create rotation Lambda function
cat > rotation_lambda.py << 'EOF'
import boto3
import json
import pymysql

secrets_client = boto3.client('secretsmanager')
rds_client = boto3.client('rds')

def lambda_handler(event, context):
    metadata = secrets_client.describe_secret(SecretId=event['SecretId'])
    
    # Get current secret
    current = secrets_client.get_secret_value(SecretId=event['SecretId'])
    secret = json.loads(current['SecretString'])
    
    # Generate new password
    new_secret = secrets_client.get_random_password(PasswordLength=32)
    new_password = new_secret['RandomPassword']
    
    # Connect to database with old credentials
    conn = pymysql.connect(
        host=secret['host'],
        user=secret['username'],
        password=secret['password'],
        database=secret['dbname']
    )
    
    try:
        # Change password
        with conn.cursor() as cursor:
            cursor.execute(
                f"ALTER USER '{secret['username']}'@'%' IDENTIFIED BY %s",
                (new_password,)
            )
        conn.commit()
        
        # Update secret in Secrets Manager
        updated_secret = secret.copy()
        updated_secret['password'] = new_password
        
        secrets_client.update_secret(
            SecretId=event['SecretId'],
            SecretString=json.dumps(updated_secret)
        )
        
        return {"statusCode": 200, "message": "Rotation successful"}
    finally:
        conn.close()
EOF

# Package and deploy Lambda
zip rotation_lambda.zip rotation_lambda.py
aws lambda create-function \
  --function-name rds-mysql-rotation \
  --runtime python3.11 \
  --role arn:aws:iam::123456789:role/rotation-role \
  --handler rotation_lambda.lambda_handler \
  --zip-file fileb://rotation_lambda.zip

# Configure automatic rotation
aws secretsmanager rotate-secret \
  --secret-id prod/rds-mysql-password \
  --rotation-rules AutomaticallyAfterDays=30 \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789:function:rds-mysql-rotation
```

**Pattern 2: Application accessing secret from Secrets Manager**

```go
// Go application fetching secrets from AWS Secrets Manager
package main

import (
	"context"
	"encoding/json"
	"log"
	
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

type DatabaseSecret struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Host     string `json:"host"`
	Port     int    `json:"port"`
	Database string `json:"dbname"`
}

func getSecret(ctx context.Context, secretName string) (*DatabaseSecret, error) {
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, err
	}
	
	client := secretsmanager.NewFromConfig(cfg)
	
	result, err := client.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretName),
	})
	if err != nil {
		return nil, err
	}
	
	var secret DatabaseSecret
	if err := json.Unmarshal([]byte(*result.SecretString), &secret); err != nil {
		return nil, err
	}
	
	return &secret, nil
}

func main() {
	ctx := context.Background()
	dbSecret, err := getSecret(ctx, "prod/database-credentials")
	if err != nil {
		log.Fatalf("Failed to get secret: %v", err)
	}
	
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s",
		dbSecret.Username, dbSecret.Password, dbSecret.Host, dbSecret.Port, dbSecret.Database)
	
	db, err := sql.Open("mysql", dsn)
	// ... use database
}
```

**Pattern 3: Cross-Account Secret Access**

```bash
# Account A (Secret Owner): Create secret
aws secretsmanager create-secret \
  --name prod/shared-api-key \
  --secret-string 'api_key_value_here'

# Account B (Secret Consumer): Create IAM role with access
cat > cross-account-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:ACCOUNT-A:secret:prod/shared-api-key*"
    }
  ]
}
EOF

# Account A: Update secret resource policy for cross-account access
aws secretsmanager put-resource-policy \
  --secret-id prod/shared-api-key \
  --resource-policy '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::ACCOUNT-B:role/cross-account-access"
        },
        "Action": "secretsmanager:GetSecretValue",
        "Resource": "*"
      }
    ]
  }'

# Account B: Docker task gets secret via IAM role
# ECS Task Definition includes role, which has permission in Account A
```

#### DevOps Best Practices

✓ **DO:**
- Use AWS Secrets Manager for AWS-native workloads (RDS, Lambda, ECS)
- Enable automatic rotation for database passwords (30-day intervals)
- Encrypt secrets with KMS; use customer-managed keys for compliance
- Monitor access via CloudTrail; alert on unusual access patterns
- Use resource-based policies for fine-grained access control

✗ **DON'T:**
- Store AWS access keys in Secrets Manager (use STS AssumeRole instead)
- Disable rotation; set appropriate rotation schedules
- Mix Secrets Manager and Parameter Store; use Parameter Store for non-sensitive config
- Forget KMS key policy when creating customer-managed keys
- Store database master password without rotation mechanism

---

### 3.4 Environment Variables & Runtime Injection

#### Internal Working Mechanism

Environment variables are process-level configurations passed to containers at runtime. Unlike secrets in managers, env vars are:
- **Simple:** No external service required
- **Fast:** No additional latency to fetch
- **Visible:** Easily inspectable (can leak if not careful)
- **Immutable:** Set at container launch, cannot change without restart

**Process Memory Model:**

```
┌── Container Process ──────────────────┐
│                                       │
│  Environment Variables Storage        │
│  ┌─────────────────────────────────┐ │
│  │ PATH=/usr/local/bin:/usr/bin    │ │
│  │ DB_HOST=postgres.internal:5432  │ │
│  │ DB_USER=appuser                 │ │
│  │ LOG_LEVEL=INFO                  │ │
│  │ [... others ...]                │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ↓ (Application reads)               │
│                                       │
│  ┌─────────────────────────────────┐ │
│  │ Runtime Configuration            │ │
│  │ ├─ Database connection pool      │ │
│  │ ├─ Log level filter             │ │
│  │ └─ Feature flags                │ │
│  └─────────────────────────────────┘ │
│                                       │
└───────────────────────────────────────┘
```

**Security Concern:** Env vars are visible to all processes in container:
```bash
# Inside container, any process can see all env vars
$ env          # Lists all variables
$ ps auxe       # Process list includes full environment

# Potential leaks:
$ history       # If command was typed, credentials visible
$ docker inspect  # If inspecting running container, env vars shown
$ docker ps     # Can see env with `-e` output
```

#### Architecture Role

Environment variables serve as the **simplest interface for configuration** but require discipline to avoid security issues:

**Configuration Pyramid:**
```
         Runtime Config (Safest)
              ↑
    Code-based Config (Medium)
              ↑
    Environment Variables (Fast, risky)
              ↑
    Hardcoded Defaults (Least flexible)
```

#### Production Usage Patterns

**Pattern 1: Layered Configuration with Env Var Override**

```python
# config.py - Load settings with hierarchy
import os
from dataclasses import dataclass

@dataclass
class DatabaseConfig:
    host: str = os.getenv('DB_HOST', 'localhost')
    port: int = int(os.getenv('DB_PORT', '5432'))
    username: str = os.getenv('DB_USER', 'app')
    password: str = os.getenv('DB_PASSWORD', '')  # Warn if empty
    database: str = os.getenv('DB_NAME', 'myapp')
    pool_size: int = int(os.getenv('DB_POOL_SIZE', '10'))
    ssl_mode: str = os.getenv('DB_SSL_MODE', 'require')

@dataclass
class AppConfig:
    environment: str = os.getenv('APP_ENV', 'development')
    debug: bool = os.getenv('DEBUG', '').lower() == 'true'
    log_level: str = os.getenv('LOG_LEVEL', 'INFO')
    secret_key: str = os.getenv('SECRET_KEY', '')
    database: DatabaseConfig = DatabaseConfig()
    
    def validate(self):
        """Validate configuration at startup"""
        if self.environment == 'production':
            if not self.secret_key:
                raise ValueError("SECRET_KEY required in production")
            if self.debug:
                raise ValueError("DEBUG=true not allowed in production")
            if not self.database.password:
                raise ValueError("DB_PASSWORD required in production")

config = AppConfig()
config.validate()
```

Django example:
```python
# settings.py
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', 'localhost').split(',')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'postgres'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': os.environ.get('LOG_LEVEL', 'INFO'),
    },
}
```

**Pattern 2: Docker Compose with .env Files**

```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    environment:
      - DB_HOST=${DB_HOST:-postgres}
      - DB_USER=${DB_USER:-appuser}
      - DB_PASSWORD=${DB_PASSWORD}  # Required; must be in .env
      - APP_ENV=${APP_ENV:-development}
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_DB=${DB_NAME:-myapp}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

`.env` file (git-ignored):
```bash
# .env - NEVER commit to source control
DB_HOST=postgres
DB_USER=appuser
DB_PASSWORD=$(openssl rand -base64 32)
DB_NAME=myapp
APP_ENV=development
LOG_LEVEL=DEBUG
```

Safe approach with Makefile:
```makefile
.PHONY: dev
dev:
	@if [ ! -f .env ]; then \
		echo "Creating .env file..."; \
		echo "DB_PASSWORD=$$(openssl rand -base64 32)" > .env; \
		echo "DB_USER=appuser" >> .env; \
		echo "DB_HOST=postgres" >> .env; \
	fi
	docker-compose up -d

.PHONY: clean
clean:
	docker-compose down
	rm -f .env
```

**Pattern 3: Multi-Stage Configuration (Dev → Staging → Prod)**

```bash
#!/bin/bash
# deploy.sh - Load environment-specific config

ENVIRONMENT=$1  # "dev", "staging", or "prod"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 {dev|staging|prod}"
    exit 1
fi

# Source environment-specific file
if [ ! -f "env/${ENVIRONMENT}.env" ]; then
    echo "Error: env/${ENVIRONMENT}.env not found"
    exit 1
fi

set -a
source "env/${ENVIRONMENT}.env"  # Load all variables
set +a

# Validate critical variables
for var in APP_ENV DB_HOST DB_USER DB_PASSWORD; do
    if [ -z "${!var}" ]; then
        echo "Error: $var not set in env/${ENVIRONMENT}.env"
        exit 1
    fi
done

# Deploy with validated configuration
docker-compose --project-name "${APP_NAME}_${ENVIRONMENT}" \
  -f docker-compose.yml \
  -f "docker-compose.${ENVIRONMENT}.yml" \
  up -d
```

File structure:
```
env/
├── dev.env          # DB_HOST=localhost, LOG_LEVEL=DEBUG
├── staging.env      # DB_HOST=staging-db.internal, LOG_LEVEL=INFO
└── prod.env          # DB_HOST=prod-db.internal (in password manager), LOG_LEVEL=WARN

docker-compose.yml   # Base configuration
docker-compose.dev.yml       # Dev overrides (expose ports, volumes)
docker-compose.staging.yml   # Staging overrides
docker-compose.prod.yml      # Prod overrides (strict constraints)
```

#### DevOps Best Practices

✓ **DO:**
- Use env vars for **non-sensitive** configuration (hosts, ports, log levels, feature flags)
- Validate env vars at application startup; fail fast with clear error messages
- Document required env vars in `.env.example` without values
- Use `.env` files only in development; use secrets managers in production
- Separate sensitive (DB passwords) from non-sensitive config

✗ **DON'T:**
- Store passwords or API keys in env vars passed through deployment manifests
- Log environment variable values (scrub from debug output)
- Make assumptions about variable presence; always validate
- Use `export` in shell scripts for sensitive values (use files with restricted perms)
- Commit `.env` files to source control under any circumstance

**Example validation:**
```bash
#!/bin/bash
# Startup script with validation

required_vars=(
    "APP_ENV"
    "DB_HOST"
    "LOG_LEVEL"
)

missing=()
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        missing+=("$var")
    fi
done

if [ ${#missing[@]} -gt 0 ]; then
    echo "ERROR: Missing required environment variables: ${missing[*]}"
    echo "Available variables:"
    env | grep -E '^(APP_|DB_|LOG_)' | sed 's/=.*//'
    exit 1
fi

# All vars present; continue with startup
exec myapp
```

---

### 3.5 Secret Management Best Practices

#### Comprehensive Security Strategy

A production secret management strategy combines multiple tools layered by trust level:

```
┌─────────────────────────────────────────────────────┐
│  Tier 1: Non-Sensitive Config (NO Secrets)          │
│  ├─ Hostnames, ports, timeouts, feature flags       │
│  ├─ Storage: Environment Variables, ConfigMap       │
│  ├─ Rotation: Never (non-sensitive)                 │
│  └─ Access: Readable in deployment manifests        │
├─────────────────────────────────────────────────────┤
│  Tier 2: Database Credentials (Static or Rotating)  │
│  ├─ Storage: Vault, AWS Secrets Manager, K8s Secret │
│  ├─ Rotation: 30-90 days (or dynamic secrets)       │
│  ├─ Access: RBAC, IAM controlled                    │
│  └─ Audit: All access logged                        │
├─────────────────────────────────────────────────────┤
│  Tier 3: API Keys & OAuth Tokens (High Sensitivity) │
│  ├─ Storage: Vault with dynamic token generation    │
│  ├─ Rotation: 1-7 days (or on-demand)               │
│  ├─ Access: Single-use tokens, short TTL            │
│  └─ Audit: CloudTrail, detailed logging             │
├─────────────────────────────────────────────────────┤
│  Tier 4: Encryption Keys (Must be managed)          │
│  ├─ Storage: HSM (Hardware Security Module)         │
│  ├─ Rotation: Annually + on key compromise          │
│  ├─ Access: Physical controls, biometric            │
│  └─ Audit: Tamper-proof logs                        │
└─────────────────────────────────────────────────────┘
```

#### Unified Secret Rotation Policy

```bash
#!/bin/bash
# rotation-orchestrator.sh - Manage all secret rotations

ROTATION_LOG="/var/log/secret-rotation.log"

log_rotation() {
    local secret_name=$1
    local status=$2
    local error_msg=$3
    
    echo "[$(date -u +'%Y-%m-%d %H:%M:%S UTC')] $secret_name: $status" >> $ROTATION_LOG
    if [ ! -z "$error_msg" ]; then
        echo "  ERROR: $error_msg" >> $ROTATION_LOG
    fi
}

rotate_docker_secret() {
    local secret_name=$1
    local new_value=$2
    
    # Create version (old value stays as backup)
    docker secret create "${secret_name}_v$(date +%s)" - <<< "$new_value"
    
    # Update service to use new secret
    # (requires re-deployment with updated secret name)
    
    log_rotation "$secret_name" "ROTATED" ""
}

rotate_vault_secret() {
    local secret_path=$1
    local ttl=$2
    
    vault secret patch "$secret_path" \
        renewal_period="$ttl" \
        2>&1 | tee -a $ROTATION_LOG
    
    log_rotation "$secret_path" "ROTATED" ""
}

rotate_aws_secret() {
    local secret_id=$1
    
    aws secretsmanager rotate-secret \
        --secret-id "$secret_id" \
        2>&1 | tee -a $ROTATION_LOG
    
    log_rotation "$secret_id" "ROTATED_SCHEDULED" ""
}

rotate_database_password() {
    local db_type=$1
    local db_host=$2
    local old_user=$3
    local new_password=$(openssl rand -base64 32)
    
    case $db_type in
        mysql)
            mysql -h "$db_host" -u "$old_user" -p"${DB_PASSWORD}" \
                -e "ALTER USER '$old_user'@'%' IDENTIFIED BY '$new_password';"
            ;;
        postgres)
            psql -h "$db_host" -U "$old_user" \
                -c "ALTER ROLE $old_user PASSWORD '$new_password';"
            ;;
    esac
    
    # Update secret manager with new password
    update_secret "$secret_name" "$new_password"
    
    log_rotation "${db_type}_${db_host}" "PASSWORD_ROTATED" ""
}

# Monthly rotation schedule
main() {
    echo "Starting secret rotation cycle..."
    
    # Rotate all database passwords
    rotate_database_password "postgres" "prod-db.internal" "app_user"
    
    # Rotate API keys
    rotate_vault_secret "secret/api-keys/stripe"
    
    # Schedule AWS managed credential rotation
    rotate_aws_secret "prod/rds-master-password"
    
    # Send summary
    echo "Rotation cycle complete. Summary:"
    tail -50 "$ROTATION_LOG"
}

main
```

#### Secret Lifecycle Documentation

Every secret should have a documented lifecycle:

```markdown
# Secret: prod/database-password

## Purpose
Primary MySQL database authentication for production environment

## Current Status
- Created: 2025-01-15
- Last Rotated: 2026-02-07
- Next Rotation: 2026-03-07 (30-day rotation)
- TTL: Indefinite (static, auto-rotated)

##access Control
- Owner: Platform Engineering team
- Consumers:
  - app-service (all environments)
  - batch-processor (prod only)
  - analytics-pipeline (staging+prod)

## Storage Locations
- Primary: AWS Secrets Manager (us-east-1)
- Backup: Vault (for disaster recovery)
- Encryption: AWS KMS customer-managed key

## Rotation Procedure
1. Lambda rotation function creates new password
2. MySQL user password updated
3. Secrets Manager CURRENT version updated
4. Applications reload config within 5 minutes
5. Old password kept as PREVIOUS for 7 days
6. Audit log updated with rotation timestamp

## Incident Response
- If password leaked: Immediate rotation (do not wait for scheduled)
- If auth failures detected: Revert to PREVIOUS version, investigate
- If rotation fails: PagerDuty alert → escalate to DBA team

## Compliance
- PCI DSS Requirement 2.2.4: Changed monthly {DATE}
- HIPAA: Encrypted at rest and in transit
- SOC 2 Type II: Full audit trail in CloudTrail
```

#### Emergency Secret Revocation

```bash
#!/bin/bash
# emergency-revoke.sh - Immediate secret invalidation

INCIDENT_ID=$1
REVOKED_SECRET=$2
REASON=$3

if [ -z "$INCIDENT_ID" ] || [ -z "$REVOKED_SECRET" ]; then
    echo "Usage: $0 <incident_id> <secret_name> [reason]"
    exit 1
fi

echo "[EMERGENCY] Revoking secret: $REVOKED_SECRET"
echo "Incident: $INCIDENT_ID"
echo "Reason: ${REASON:-Unspecified}"

# Step 1: Immediately invalidate in secret manager
case $REVOKED_SECRET in
    vault/*)
        vault secret metadata delete "$REVOKED_SECRET"
        ;;
    aws:*)
        aws secretsmanager delete-secret \
            --secret-id "${REVOKED_SECRET#aws:}" \
            --force-delete-without-recovery
        ;;
esac

# Step 2: Create new credentials
NEW_PASSWORD=$(openssl rand -base64 32)
NEW_SECRET_ID="prod/database-password_emergency_$(date +%s)"

aws secretsmanager create-secret \
    --name "$NEW_SECRET_ID" \
    --secret-string "{\"password\": \"$NEW_PASSWORD\"}"

# Step 3: Update database with new password
mysql -h prod-db.internal -u dba_admin -p"${DBA_PASSWORD}" \
    -e "ALTER USER 'app_user'@'%' IDENTIFIED BY '$NEW_PASSWORD';" || \
    echo "CRITICAL: Database password rotation failed!"

# Step 4: Trigger application redeployment
kubectl rollout restart deployment/app-service -n production

# Step 5: Audit and notify
cat > "/var/log/emergency-revocation-${INCIDENT_ID}.log" <<EOF
Timestamp: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
Incident ID: $INCIDENT_ID
Secret Revoked: $REVOKED_SECRET
Reason: ${REASON}
New Secret ID: $NEW_SECRET_ID
Database Updated: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
Applications Redeployed: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
Executed By: $(whoami)
EOF

# Send incident notification
slack_webhook=$(vault kv get -field=slack_webhook secret/admin/incident-alerting)
curl -X POST -H 'Content-type: application/json' \
    --data "{
        \"text\": \"🚨 EMERGENCY SECRET REVOCATION\",
        \"attachments\": [{
            \"color\": \"danger\",
            \"fields\": [
                {\"title\": \"Incident ID\", \"value\": \"$INCIDENT_ID\", \"short\": true},
                {\"title\": \"Secret Revoked\", \"value\": \"$REVOKED_SECRET\", \"short\": true},
                {\"title\": \"Reason\", \"value\": \"${REASON}\", \"short\": false}
            ]
        }]
    }" \
    "$slack_webhook"

echo "✓ Secret revoked and applications updated"
echo "  Log: /var/log/emergency-revocation-${INCIDENT_ID}.log"
```

---

## Docker Build Automation

### 4.1 BuildKit Essentials

#### Internal Working Mechanism

BuildKit is the modern Docker build engine providing:
- **Parallel Execution:** Independent layers build simultaneously
- **Improved Caching:** Smarter dependency detection
- **Secret Handling:** Build-time secrets isolated from final image
- **Multi-platform Builds:** Single build for ARM/x86/RISC-V architectures

**Traditional vs. BuildKit Comparison:**

```
Traditional Docker Build Engine    vs.    BuildKit Engine
──────────────────────────────────        ──────────────────────

Step 1: RUN apt-get update              [Parallel Processing]
  └─ Wait for completion                ├─ Layer 1 & 2: apt-get + npm
    ↓                                    ├─ Layer 3: COPY + pip
Step 2: RUN npm install                 └─ Final assembly
  └─ Wait...
    ↓
Step 3: COPY . /app
  └─ Wait...
    ↓
Step 4: RUN pip install
  (Linear execution)                    BuildKit: Concurrent where possible
                                        → 30-70% faster builds
```

**BuildKit Architecture:**

```
┌──────────────────────────────────────────────────┐
│         Docker BuildKit Engine                   │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │ Frontend Parser (Dockerfile)               │ │
│  │ └─ Syntax validation, heredoc support      │ │
│  └────────┬─────────────────────────────────┘ │
│           │                                    │
│  ┌────────▼─────────────────────────────────┐ │
│  │ LLB (Low-Level Builder) Converter       │ │
│  │ └─ DAG representation of build steps    │ │
│  └────────┬─────────────────────────────────┘ │
│           │                                    │
│  ┌────────▼─────────────────────────────────┐ │
│  │ Scheduler (Dependency Resolution)        │ │
│  │ ├─ Identify parallel-able steps          │ │
│  │ ├─ Detect cache hits                     │ │
│  │ └─ Allocate executor resources           │ │
│  └────────┬─────────────────────────────────┘ │
│           │                                    │
│    ┌──────┴────────────┬──────────────┐       │
│    ▼                   ▼              ▼       │
│  Executor 1       Executor 2      Executor 3 │
│  (Layer A)        (Layer B)       (Layer C)  │
│  [Parallel]       [Parallel]      [Parallel] │
│                                              │
└──────────────────────────────────────────────────┘
```

#### Enabling BuildKit

```bash
# Method 1: Set environment variable (current shell)
DOCKER_BUILDKIT=1 docker build -t myapp:latest .

# Method 2: Enable globally in Docker daemon config
cat > /etc/docker/daemon.json << 'EOF'
{
  "features": {
    "buildkit": true
  }
}
EOF
systemctl restart docker

# Verify
docker buildx version  # BuildKit is active
docker build --version  # Should show buildx

# Method 3: Use buildx (included with Docker)
docker buildx create --name mybuilder --use  # Create custom builder
docker buildx build -t myapp:latest .
```

#### Production Usage Patterns

**Pattern 1: Multi-Architecture Build (ARM + x86)**

```dockerfile
# Dockerfile supporting multiple architectures
# {Buildkit supports TARGETPLATFORM, TARGETARCH, TARGETOS variables}

FROM --platform=$BUILDPLATFORM golang:1.21 as builder

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETOS

WORKDIR /src
COPY go.mod go.sum ./

# Build for target architecture
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -o myapp -ldflags "-X main.Version=1.0.0" .

# Final image
FROM alpine:3.18
COPY --from=builder /src/myapp /usr/local/bin/
ENTRYPOINT ["myapp"]
```

Build for multiple architectures:
```bash
# Requires buildx
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t myapp:1.0.0 \
  --push \
  .

# Result: Single image tag with manifests for 3 architectures
# Docker automatically pulls correct architecture per host
```

**Pattern 2: BuildKit with Build Secrets (Safe Credential Handling)**

```dockerfile
# Dockerfile using build secrets
# Secrets NOT baked into image; removed after build

FROM alpine:3.18

# Download private package (requires GitHub token)
RUN --mount=type=secret,id=github_token \
    apk add --no-cache curl && \
    TOKEN=$(cat /run/secrets/github_token) && \
    curl -H "Authorization: token $TOKEN" \
    https://api.github.com/repos/myorg/private-package/releases/download/package.tar.gz \
    -o /tmp/package.tar.gz && \
    tar -xzf /tmp/package.tar.gz -C /opt && \
    rm /tmp/package.tar.gz

# Secret /run/secrets/github_token deleted after RUN completes
# NOT in image layers
```

Build with secret:
```bash
# Provide secret at build time
docker buildx build \
  --secret id=github_token,src=$HOME/.github/token \
  -t myapp:latest \
  .

# Secret passed to build context only; never persisted
```

**Pattern 3: Advanced Caching with External Cache Backend**

```bash
#!/bin/bash
# ci-build.sh - Production build with external cache

IMAGE_NAME="myapp"
TAG="${CI_COMMIT_SHA:0:7}"  # Short commit hash
FULL_TAG="registry.company.com/${IMAGE_NAME}:${TAG}"
CACHE_BACKEND="type=gha"  # GitHub Actions cache

# Build with external cache
docker buildx build \
  --cache-from=$CACHE_BACKEND \
  --cache-to=$CACHE_BACKEND,mode=max \
  --build-context=git://github.com/myorg/base-images.git#v1.0 \
  --tag="$FULL_TAG" \
  --tag="registry.company.com/${IMAGE_NAME}:latest" \
  --output=type=registry \
  --push \
  .

echo "Image built and pushed: $FULL_TAG"
```

---

### 4.2 Multi-Stage Build Optimization

#### Internal Working Mechanism

Multi-stage builds use multiple `FROM` statements, allowing intermediate stages to be discarded, keeping only necessary artifacts.

**Stage Purpose:**
1. **Builder Stage:** Compile/build application (large tools, dependencies)
2. **Test Stage:** Run tests, security scanning
3. **Runtime Stage:** Minimal final image with only necessary files

**Image Size Reduction:**

```
Single-Stage Build (1.2GB)           Multi-Stage Build (150MB)
┌─────────────────────────┐          ┌─────────────────────────┐
│ Ubuntu 22.04 base (1.1GB)          │ Alpine 3.18 base (7MB)  │
│ Development tools (400MB)  ✗        │ Runtime deps (50MB)    │
│ Build cache (200MB)        ✗        │ Application (93MB)     │
│ Node modules (500MB)       ✗        │                        │
│ Source code (10MB)         ✓        │  Total: 150MB          │
│ Compiled app (100MB)       ✓        │                        │
│ Test files (50MB)          ✗        │  Reduction: 87.5% ✓    │
└─────────────────────────┘          └─────────────────────────┘
```

**Build Flow with Multi-Stage:**

```
Stage 1: Builder              Stage 2: Test            Stage 3: Runtime
┌─────────────────────┐      ┌──────────────────┐     ┌──────────────────┐
│ golang:1.21         │      │ Application code │     │ alpine:3.18      │
│ ├─ COPY source      │      │ ├─ RUN go test   │     │ ├─ COPY binary   │
│ ├─ RUN go build     │      │ ├─ Report results│     │ ├─ EXPOSE 8080   │
│ └─ Output: /app/bin │      │ └─ Discard stage │     │ └─ CMD ["/app"]  │
│   (1GB intermediate)│      │   (Large, unused)│     │   (Final: 200MB) │
└─────────────────────┘      └──────────────────┘     └──────────────────┘
          │                           │                        │
          └───────────────────────────┼────────────────────────┘
                Only /app/bin copied to Stage 3 (minimal)
                Stages 1 & 2 not in final image
```

#### Architecture Role

Multi-stage builds enable **lean production images** by:
- Separating build concerns from runtime concerns
- Removing compilation toolchains from production
- Reducing attack surface (fewer tools to patch)
- Improving deployment speed (smaller = faster pull)
- Reducing storage costs (80% smaller images)

#### Production Usage Patterns

**Pattern 1: Node.js Production Optimization**

```dockerfile
# Multi-stage Node.js build
# Stage 1: Dependencies + Build

FROM node:20-alpine as dependencies
WORKDIR /app
COPY package*.json ./

# Install dependencies in separate stage
RUN npm ci --omit=dev && \
    npm cache clean --force

# Stage 2: Build (if using TypeScript, Webpack, etc)

FROM dependencies as builder
COPY . .
RUN npm run build

# Stage 3: Runtime (minimal final image)

FROM node:20-alpine as runtime
WORKDIR /app

# Copy only production dependencies (not dev/test deps)
COPY --from=dependencies /app/node_modules /app/node_modules

# Copy only the built application (not source)
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/package*.json /app/

# Create non-root user for security
RUN addgroup -g 1001 nodejs && \
    adduser -S -u 1001 app -G nodejs
USER app

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1))"

CMD ["node", "dist/index.js"]

# Layer sizes:
# Stage 1 (dependencies):  200MB (not in final)
# Stage 2 (builder):       500MB (not in final)
# Stage 3 (runtime):       180MB (final image)
# IMAGE REDUCTION: 5x smaller
```

**Pattern 2: Java Spring Boot Multi-Stage**

```dockerfile
# Java Spring Boot multi-stage build

FROM eclipse-temurin:21-jdk-alpine as builder
WORKDIR /app
COPY . .

# Build application
RUN ./mvnw clean package -DskipTests

# Extract layers for optimized startup
RUN cd target/*.jar && \
    unzip -q *.jar && \
    rm -f *.jar && \
    cd ../.. && \
    mv target/*.jar target/application.jar && \
    java -Djarmode=layertools -jar target/application.jar extract

# Runtime stage (JDK → JRE for size reduction)
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy layers in optimal order (least-changed first)
COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/application/ ./

# Non-root user
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /bin/sh -D app
USER app

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-Dcom.sun.management.jmxremote=false", "-XX:MaxRAMPercentage=75", "-XX:InitialRAMPercentage=50", "org.springframework.boot.loader.JarLauncher"]

# Image sizes:
# Builder:  1200MB (JDK + compile cache)
# Runtime:  400MB (JRE + application) ← Final image is 67% smaller
```

**Pattern 3: Python Multi-Stage with Virtual Environment**

```dockerfile
# Python multi-stage build leveraging venv

FROM python:3.11-slim as builder
WORKDIR /app

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.11-slim as runtime
WORKDIR /app

# Copy virtual environment (all wheels pre-compiled)
COPY --from=builder /opt/venv /opt/venv

# Copy application
COPY app/ .

# Activate venv
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Non-root user
RUN useradd -m -u 1000 app && chown -R app:app /app
USER app

EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD python -c "import requests; requests.get('http://localhost:5000/health').raise_for_status()"

CMD ["flask", "run", "--host=0.0.0.0"]

# Image reduction: 45% smaller than single-stage
```

---

### 4.3 Build Caching Strategies

#### Internal Working Mechanism

Docker build cache works by comparing layers. If source hasn't changed, cached layer is reused, skipping execution.

**Cache Key Determination:**
```
Layer Cache Hit/Miss Calculation:

FROM alpine:3.18
  ↓
Cache Key: alpine:3.18 hash
  ├─ Hit? Yes → Use cached layer
  └─ Miss? No → Pull/build

COPY app.py /app/app.py
  ↓
Cache Key: Hash(app.py content)
  ├─ Hit? (Only if app.py content unchanged)
  └─ Miss? Rerun COPY

RUN pip install -r requirements.txt
  ↓
Cache Key: Hash(requirements.txt content)
  ├─ Hit? Yes → Use cached layer
  └─ Miss? No → Rerun pip install
```

**Cache Invalidation Chain:**
```
If dockerfile modified at line 10,
  Layers 0-9:  can use cache
  Layers 10+:  cache INVALIDATED

This cascading invalidation is why
dockerfile order matters!

✓ Good order (cacheable):
1. FROM base
2. RUN apt-get update (rarely changes)
3. COPY requirements.txt
4. RUN pip install (expensive)
5. COPY app/ (changes frequently)
6. RUN application startup (cheap)

✗ Bad order (cache-busting):
1. FROM base
2. COPY app/ (changes daily)
3. RUN pip install (expensive, re-runs!)
4. COPY requirements.txt
```

#### Architecture Role

Build caching directly impacts **CI/CD speed and cost**:
- **Local cache:** Developers rebuild 70% faster with hot cache
- **Registry cache:** CI pulls cached layers instead of rebuilding
- **Remote cache:** Teams share cache across builds → multiplied savings

#### Production Usage Patterns

**Pattern 1: Optimize Dockerfile Layer Order**

```dockerfile
# ✓ OPTIMAL - Least-changed to most-changed
FROM python:3.11-slim

# Static dependencies (rarely change, cacheable)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies (changes monthly, cached)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Configuration files (changes occasionally)
COPY config/ /app/config/

# Application code (changes daily, minimal cache benefit)
COPY src/ /app/src/

# Entry point (almost never changes)
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Cache hit percentage: 70-80%
# Average rebuild time: 15 seconds (mostly code layer)
```

**Pattern 2: Separate Cacheable Stages**

```dockerfile
# Multi-stage with independent caching

# Stage 1: Base dependencies (deep cache)
FROM node:20 as dependencies
WORKDIR /app
COPY package-lock.json .
RUN npm ci --omit=dev

# Cached unless package-lock.json changes (once/month)
# Hit rate: 95%

# Stage 2: Build stage (moderate cache)
FROM dependencies as builder
COPY tsconfig.json webpack.config.js jest.config.js .
COPY src/ /app/src
RUN npm run build

# Cached unless source or config changes (daily)
# Hit rate: 40%

# Stage 3: Test stage (minimal cache)
FROM builder as test
RUN npm test

# Test results not cacheable; always runs
# Hit rate: 0% (by design - want fresh test results)

# Stage 4: Runtime (merged cache from stages 1+2)
FROM node:20-alpine as runtime
COPY --from=dependencies /app/node_modules /app/node_modules
COPY --from=builder /app/dist /app/dist
CMD ["node", "dist/index.js"]

# Combined cache hit: 80% despite frequent builds
```

**Pattern 3: External Cache Management (CI/CD Registry)**

```bash
#!/bin/bash
# build-with-cache.sh - Use registry as distributed cache

IMAGE_REPO="registry.company.com/myapp"
BUILD_TAG="sha-${CI_COMMIT_SHA:0:7}"
LATEST_TAG="latest"
CACHE_TAG="build-cache-${CI_COMMIT_BRANCH}"

# Pull previous cache (if exists)
docker pull "${IMAGE_REPO}:${CACHE_TAG}" 2>/dev/null || \
  docker pull "${IMAGE_REPO}:${LATEST_TAG}" 2>/dev/null || \
  echo "No cache available; clean build"

# Build with cache from previous build
docker build \
  --cache-from="${IMAGE_REPO}:${CACHE_TAG}" \
  --cache-from="${IMAGE_REPO}:${LATEST_TAG}" \
  --tag="${IMAGE_REPO}:${BUILD_TAG}" \
  --tag="${IMAGE_REPO}:${LATEST_TAG}" \
  --tag="${IMAGE_REPO}:${CACHE_TAG}" \
  .

# Push all tags to registry for future cache
docker push "${IMAGE_REPO}:${BUILD_TAG}"
docker push "${IMAGE_REPO}:${LATEST_TAG}"
docker push "${IMAGE_REPO}:${CACHE_TAG}"  # Cache layer

echo "Build complete:"
echo "  Artifact: ${IMAGE_REPO}:${BUILD_TAG}"
echo "  Cache TAG: ${CACHE_TAG}"
```

**Pattern 4: BuildKit Advanced Caching**

```bash
#!/bin/bash
# buildkit-cache.sh - Use BuildKit's inline cache (more efficient)

REGISTRY="registry.company.com"
IMAGE="myapp"
TAG="${CI_COMMIT_SHA:0:7}"

docker buildx build \
  --cache-from=type=registry,ref="${REGISTRY}/${IMAGE}:buildcache" \
  --cache-to=type=registry,ref="${REGISTRY}/${IMAGE}:buildcache",mode=max \
  --tag="${REGISTRY}/${IMAGE}:${TAG}" \
  --tag="${REGISTRY}/${IMAGE}:latest" \
  --output=type=registry \
  --push \
  .

# BuildKit advantages:
# - Caches all layers (not just final image)
# - Incremental cache push (only new layers)
# - Smart deduplication across builds
# - 60%+ faster than traditional cache
```

---

### 4.4 Build Secrets & Build Args

#### Internal Working Mechanism

**Build Args:**
- Available during build (RUN statements)
- Baked into image metadata; visible in image inspection
- Use for: version numbers, build-time configuration, feature flags

**Build Secrets:**
- Available during specific RUN commands via mount
- Never stored in image; automatically removed
- Use for: package repository credentials, private SSH keys,  API tokens

**Comparison:**

```
BUILD ARG vs. BUILD SECRET

ARG version=1.0.0
├─ VISIBLE in: `docker inspect image`
├─ BAKED IN: Image layers (historical)
├─ SECURE: NO (do not use for secrets!)
└─ Use for: Version, compile flags, feature flags

RUN --mount=type=secret,id=github_token
├─ VISIBLE in: /run/secrets/github_token (during RUN only)
├─ BAKED IN: NO (removed after RUN)
├─ SECURE: YES (mounted tmpfs, no history)
└─ Use for: Credentials, API keys, GPG keys
```

#### Architecture Role

Build secrets/args enable **secure, configurable builds** by:
- Allowing runtime config without rebuilding from scratch
- Preventing credential leakage into image layers
- Supporting multi-tenant builds (same Dockerfile, different configs)

#### Production Usage Patterns

**Pattern 1: Build Args for Versioning**

```dockerfile
# Dockerfile with version management

ARG VERSION=dev
ARG BUILD_DATE
ARG VCS_REF

FROM alpine:3.18

LABEL version="${VERSION}" \
      build.date="${BUILD_DATE}" \
      vcs.ref="${VCS_REF}" \
      maintainer="devops@company.com"

# Use build arg in application
RUN echo "App Version: $VERSION" > /etc/app-version

ENTRYPOINT ["myapp"]
```

Build with version:
```bash
#!/bin/bash
# Build with specific version

docker build \
  --build-arg VERSION="1.2.3" \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
  -t myapp:1.2.3 \
  .

# Verify version in image
docker inspect myapp:1.2.3 | jq '.[0].Config.Labels.version'
# Output: "1.2.3"
```

**Pattern 2: Build Secrets for Private Packages**

```dockerfile
# Dockerfile using build secrets

FROM python:3.11-slim

# Install private package from private PyPI index
RUN --mount=type=secret,id=pypi_token \
    PIP_INDEX_URL="https://token:$(cat /run/secrets/pypi_token)@pypi.company.com/simple" \
    pip install --no-cache-dir \
      https://pypi.company.com/packages/company-common-lib-1.0.0.tar.gz

# Secret is never in image layers or history
# Credential not visible in docker history or inspect

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ /app
ENTRYPOINT ["python", "app/main.py"]
```

Build with secret:
```bash
# Create token file (local development)
echo "my-secret-pypi-token-xyz" > /tmp/pypi.token

# Pass to build
docker build \
  --secret id=pypi_token,src=/tmp/pypi.token \
  -t myapp:latest \
  .

# In CI/CD (GitHub Actions example)
# - Set PyPI_TOKEN secret in repository settings
# - Pass to docker build via --secret
```

**Pattern 3: Multi-Tenant Build (Same image, different configs)**

```dockerfile
# Dockerfile parameterized for multiple deployments

ARG ENVIRONMENT=production
ARG CLUSTER=us-east-1

FROM alpine:3.18

RUN --mount=type=secret,id=ssl_key \
    --mount=type=secret,id=ssl_cert \
    --mount=type=secret,id=db_password \
    mkdir -p /etc/ssl/private && \
    cp /run/secrets/ssl_key /etc/ssl/private/server.key && \
    cp /run/secrets/ssl_cert /etc/ssl/private/server.crt && \
    chmod 400 /etc/ssl/private/server.key

#ENV values from build args
ENV ENVIRONMENT=${ENVIRONMENT} \
    CLUSTER=${CLUSTER} \
    LOG_LEVEL=INFO

COPY app/ /app
WORKDIR /app

ENTRYPOINT ["./startup.sh"]
```

Build for different environments:
```bash
#!/bin/bash
# Multi-tenant build

build_environment() {
    local env=$1
    local secrets_dir="./secrets/${env}"
    
    docker build \
      --build-arg ENVIRONMENT="$env" \
      --build-arg CLUSTER="$(cat ${secrets_dir}/cluster)" \
      --secret id=ssl_key,src="${secrets_dir}/server.key" \
      --secret id=ssl_cert,src="${secrets_dir}/server.crt" \
      --secret id=db_password,src="${secrets_dir}/db.pass" \
      -t "myapp:${env}-$(date +%s)" \
      .
}

build_environment "development"
build_environment "staging"
build_environment "production"

# Three images, same Dockerfile, different configs
```

---

### 4.5 Security Scanning in Build Pipelines

#### Internal Working Mechanism

Security scanning analyzes built images for vulnerabilities before deployment:

```
Build → Scan → Gate → Push → Deploy

docker build Image
         ↓
    Scan with Trivy
         ├─ Check known CVEs in base image
         ├─ Check dependencies
         └─ Generate report
         ↓
   Gate Check (Policy)
         ├─ Critical CVEs? → BLOCK
         ├─ High CVEs? → REVIEW REQUIRED
         └─ Pass? → CONTINUE
         ↓
   Push to Registry
         ├─ Tag with scan results
         └─ Store SBOM (Software Bill of Materials)
         ↓
   Deploy to Kubernetes
         └─ Only allow signed, scanned images
```

**Scanner Types:**

| Scanner | Technology | Use Case |
|---------|-----------|----------|
| Trivy | Vulnerability database | Fast, accurate CVE detection; best OSS option |
| Snyk | Runtime analysis | Commercial; SCA + SAST; supply chain focus |
| Grype | Vulnerability scanning | Multi-format, integration with syft |
| Clair | Distributed scanning | Registry-integrated scanning (Quay, Harbor) |
| Anchore | Policy enforcement | Detailed analysis; enterprise registries |

#### Architecture Role

Security scanning enables **shift-left security** by:
- Finding vulnerabilities at build time (cheap to fix)
- Preventing vulnerable images from reaching production
- Generating compliance artifacts (SBOM, attestation)
- Automating security without human bottleneck

#### Production Usage Patterns

**Pattern 1: Trivy with Policy Enforcement**

```bash
#!/bin/bash
# scan-image.sh - Build, scan, gate, push

set -e

IMAGE_NAME="myapp"
TAG="1.0.0"
REGISTRY="registry.company.com"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "[1/4] Building image..."
docker build -t "$FULL_IMAGE" .

echo "[2/4] Scanning for vulnerabilities..."
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image \
    --severity HIGH,CRITICAL \
    --exit-code 0 \  # Don't fail yet; generate report first
    --format json \
    --output /tmp/scan-report.json \
    "$FULL_IMAGE"

echo "[3/4] Checking scan results..."
CRITICAL_COUNT=$(jq '[.Results[].Misconfigurations[] | select(.Severity=="CRITICAL")] | length' /tmp/scan-report.json)
HIGH_COUNT=$(jq '[.Results[].Misconfigurations[] | select(.Severity=="HIGH")] | length' /tmp/scan-report.json)

if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo "❌ CRITICAL vulnerabilities found: $CRITICAL_COUNT"
    echo "Report:"
    jq '.Results[].Misconfigurations[] | select(.Severity=="CRITICAL") | {Title, Description}' /tmp/scan-report.json
    exit 1
fi

if [ "$HIGH_COUNT" -gt 5 ]; then
    echo "⚠️  Too many HIGH vulnerabilities: $HIGH_COUNT (threshold: 5)"
    exit 1
fi

echo "✓ Scan passed"

echo "[4/4] Pushing image..."
docker push "$FULL_IMAGE"

# Archive scan report for compliance
cp /tmp/scan-report.json "./scan-reports/$(date +%Y%m%d)_${TAG}.json"

echo "✓ Image built, scanned, and pushed: $FULL_IMAGE"
```

**Pattern 2: GitHub Actions CI with Scanning**

```yaml
# .github/workflows/build-scan-push.yml

name: Build, Scan, and Push

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      security-events: write  # For GitHub Security tab
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Docker image
        run: |
          docker build -t ghcr.io/${{ github.repository }}:${{ github.sha }} .
      
      - name: Run Trivy security scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ghcr.io/${{ github.repository }}:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'
      
      - name: Scan for secrets with truffleHog
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
      
      - name: SCA dependency check (Snyk)
        uses: snyk/actions/docker@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          image: ghcr.io/${{ github.repository }}:${{ github.sha }}
          args: --severity-threshold=high
      
      - name: Push image (only if PR approved)
        if: github.event_name == 'push' && github.ref == 'refs/heads/main'
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker push ghcr.io/${{ github.repository }}:${{ github.sha }}
          docker tag ghcr.io/${{ github.repository }}:${{ github.sha }} ghcr.io/${{ github.repository }}:latest
          docker push ghcr.io/${{ github.repository }}:latest
```

**Pattern 3: SBOM Generation & Artifact Attestation**

```bash
#!/bin/bash
# build-with-sbom-attestation.sh

set -e

IMAGE="myapp:1.0.0"

# Step 1: Build image
docker build -t "$IMAGE" .

# Step 2: Generate SBOM (Software Bill of Materials) with Syft
syft "$IMAGE" \
  --output spdx \
  > sbom-spdx.txt

# Step 3: Sign SBOM with cosign
cosign sign-blob \
  --key "$HOME/.cosign/cosign.key" \
  sbom-spdx.txt > sbom-spdx.txt.sig

# Step 4: Push image
docker push "$IMAGE"

# Step 5: Attach SBOM to image in registry
cosign attach sbom "$IMAGE" --sbom sbom-spdx.txt

# Step 6: Sign image
cosign sign --key "$HOME/.cosign/cosign.key" "$IMAGE"

# Verification
echo "Verifying image signature..."
cosign verify --key "$HOME/.cosign/cosign.pub" "$IMAGE"

echo "SBOM:"
cosign tree "$IMAGE"
```

Alternative with attestation:
```bash
# Generate and attach attestation proving scan performed

docker run --rm \
  -v "$HOME/.cosign:/root/.cosign" \
  ghcr.io/sigstore/cosign sign-blob \
    --key /root/.cosign/cosign.key \
    /tmp/trivy-report.json

# This creates verifiable proof that:
# 1. Image was scanned
# 2. Timestamp of scan
# 3. No tampering of report
```

---

## Docker in CICD Pipelines

### 5.1 Pipeline Architecture & Integration Patterns

#### Internal Working Mechanism

A CICD pipeline orchestrates build, test, scan, and deploy stages triggered by code changes:

```
Git Push
   │
   ▼
┌─────────────────────────────────┐
│ GitHub/GitLab Webhook           │
│ (Triggers pipeline automatically)│
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Stage 1: Source Code Checkout   │
│ └─ Clone repo at commit SHA     │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Stage 2: Build & Unit Tests     │
│ ├─ Compile application          │
│ ├─ Run unit tests               │
│ └─ Lint code standards          │
└──────────┬──────────────────────┘
      Fail? → Notify developer
           │
           ▼
┌─────────────────────────────────┐
│ Stage 3: Build Docker Image     │
│ ├─ Run BuildKit build           │
│ └─ Tag with commit SHA          │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Stage 4: Security Scanning      │
│ ├─ Trivy vulnerability scan     │
│ ├─ SBOM generation              │
│ └─ Image signing                │
└──────────┬──────────────────────┘
     Block if critical CVEs
           │
           ▼
┌─────────────────────────────────┐
│ Stage 5: Integration Tests      │
│ ├─ Spin up Docker Compose       │
│ ├─ Run API/integration tests    │
│ └─ Clean up test environment    │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Stage 6: Push to Registry       │
│ ├─ Push image with version tag  │
│ ├─ Push image with 'latest' tag │
│ └─ Update image metadata        │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Stage 7: Deploy to Staging      │
│ ├─ Pull new image               │
│ ├─ Deploy with rolling update   │
│ └─ Run smoke tests              │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│ Stage 8: Deploy to Production   │
│ ├─ Trigger manual approval      │
│ ├─ Canary deployment (5%)       │
│ ├─ Monitor metrics for 10 min   │
│ └─ Auto-rollback if issues      │
└─────────────────────────────────┘

Total Pipeline Duration: 10-20 minutes
Failures caught at each stage before production
```

#### Architecture Role

CICD pipelines form the **automated deploy machinery** enabling:
- Fast feedback (within minutes of code change)
- Consistent builds (same steps every time)
- Automated quality gates (no bad code reaches production)
- Repeatable deployments (same process every time)

#### Production Usage Patterns

**Pattern 1: Multi-Branch Pipeline (Dev/Staging/Prod)**

```yaml
# .github/workflows/cicd-full.yml
name: CICD Pipeline (Build → Scan → Deploy)

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    
    outputs:
      image-tag: ${{ env.IMAGE_TAG }}
      scan-status: ${{ steps.scan.outputs.status }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set image tag
        run: |
          echo "IMAGE_TAG=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}" >> $GITHUB_ENV
          echo "LATEST_TAG=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest" >> $GITHUB_ENV
      
      - name: Build Docker image
        run: |
          docker build -t ${{ env.IMAGE_TAG }} .
      
      - name: Run unit tests in container
        run: |
          docker run --rm \
            -v ${{ github.workspace }}:/src \
            ${{ env.IMAGE_TAG }} \
            pytest /src/tests/ -v
      
      - name: Scan image with Trivy
        id: scan
        run: |
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy image \
              --severity HIGH,CRITICAL \
              --exit-code 0 \
              ${{ env.IMAGE_TAG }} \
              | tee scan-report.txt
          
          CRITICAL=$(grep CRITICAL scan-report.txt | wc -l)
          if [ $CRITICAL -gt 0 ]; then
            echo "status=failed" >> $GITHUB_OUTPUT
            echo "::error::Found $CRITICAL critical vulnerabilities"
            exit 1
          fi
          echo "status=passed" >> $GITHUB_OUTPUT
      
      - name: Login to registry
        if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | \
            docker login ${{ env.REGISTRY }} -u ${{ github.actor }} --password-stdin
      
      - name: Push image to registry
        if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
        run: |
          docker push ${{ env.IMAGE_TAG }}
          if [ "${{ github.ref }}" == "refs/heads/main" ]; then
            docker tag ${{ env.IMAGE_TAG }} ${{ env.LATEST_TAG }}
            docker push ${{ env.LATEST_TAG }}
          fi

  deploy-staging:
    needs: build-and-scan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    
    steps:
      - name: Deploy to staging
        env:
          DEPLOY_KEY: ${{ secrets.STAGING_DEPLOY_KEY }}
          DEPLOY_HOST: staging.company.internal
        run: |
          mkdir -p ~/.ssh
          echo "$DEPLOY_KEY" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh -i ~/.ssh/id_ed25519 deploy@$DEPLOY_HOST \
            "docker pull ${{ needs.build-and-scan.outputs.image-tag }} && \
             docker-compose -f /opt/app/docker-compose.yml up -d"
      
      - name: Run smoke tests
        run: |
          sleep 30  # Wait for services to start
          curl -f https://staging.company.internal/health || exit 1

  deploy-production:
    needs: build-and-scan
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    environment: production  # Requires manual approval
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to production (Canary 5%)
        run: |
          kubectl set image deployment/app-v1 \
            app=${{ needs.build-and-scan.outputs.image-tag }} \
            --record
          
          kubectl patch deployment app-v1 --type='json' \
            -p='[{"op":"replace","path":"/spec/replicas","value":1}]'
          
          kubectl rollout status deployment/app-v1 --timeout=5m
      
      - name: Monitor canary (5 minutes)
        run: |
          for i in {1..30}; do
            ERROR_RATE=$(curl -s https://prometheus:9090/api/v1/query \
              --data-urlencode 'query=rate(http_requests_errors{service="app"}[1m])' \
              | jq '.data.result[0].value[1]' -r)
            
            if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
              echo "Error rate ($ERROR_RATE) exceeds threshold (5%)"
              kubectl rollout undo deployment/app-v1
              exit 1
            fi
            sleep 10
          done
      
      - name: Full rollout (100%)
        run: |
          kubectl patch deployment app-v1 --type='json' \
            -p='[{"op":"replace","path":"/spec/replicas","value":10}]'
          
          kubectl rollout status deployment/app-v1 --timeout=10m
```

---

### 5.2 Build & Push Automation

#### Practical Implementation with Script Automation

```bash
#!/bin/bash
# build-push-with-caching.sh - Production build pipeline

set -e

# Configuration
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="myapp"
BUILD_CACHE_TAG="build-cache-${CI_COMMIT_BRANCH:-main}"
GIT_SHA="${CI_COMMIT_SHA:0:7}"
TAG="${GIT_SHA}-$(date +%s)"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $@"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary resources..."
    rm -f /tmp/build-*.txt 2>/dev/null || true
}
trap cleanup EXIT

log "Starting Docker build and push pipeline"
log "Image: ${FULL_IMAGE}:${TAG}"

# Step 1: Login to registry
log "Step 1: Authenticating to registry..."
if [ -z "$REGISTRY_TOKEN" ]; then
    log "ERROR: REGISTRY_TOKEN not set"
    exit 1
fi
echo "$REGISTRY_TOKEN" | docker login "$REGISTRY" -u "$REGISTRY_USER" --password-stdin

# Step 2: Pull cache from previous build
log "Step 2: Pulling build cache..."
docker pull "${FULL_IMAGE}:${BUILD_CACHE_TAG}" 2>/dev/null || \
    log "Note: No cache available; performing clean build"

# Step 3: Build with caching
log "Step 3: Building Docker image..."
BUILD_START=$(date +%s)

docker build \
    --cache-from="${FULL_IMAGE}:${BUILD_CACHE_TAG}" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
    --build-arg VERSION="${TAG}" \
    -t "${FULL_IMAGE}:${TAG}" \
    -t "${FULL_IMAGE}:latest" \
    -t "${FULL_IMAGE}:${BUILD_CACHE_TAG}" \
    . | tee /tmp/build-output.txt

BUILD_DURATION=$(($(date +%s) - BUILD_START))
log "Build completed in ${BUILD_DURATION}s"

# Step 4: Extract build metrics
log "Step 4: Analyzing build metrics..."
LAYERS=$(grep "^Step" /tmp/build-output.txt | wc -l)
CACHE_HITS=$(grep "Using cache" /tmp/build-output.txt | wc -l)
CACHE_HIT_RATIO=$((CACHE_HITS * 100 / LAYERS))
log "Layers: $LAYERS, Cache hits: $CACHE_HITS (${CACHE_HIT_RATIO}%)"

if [ "$CACHE_HIT_RATIO" -lt 50 ]; then
    log "WARNING: Low cache hit ratio (${CACHE_HIT_RATIO}%), consider dockerfile optimization"
fi

# Step 5: Get image size
log "Step 5: Image size analysis..."
IMAGE_SIZE=$(docker images --format "{{.Size}}" "${FULL_IMAGE}:${TAG}")
log "Image size: ${IMAGE_SIZE}"

# Step 6: Push to registry
log "Step 6: Pushing image to registry..."
docker push "${FULL_IMAGE}:${TAG}"
docker push "${FULL_IMAGE}:latest"
docker push "${FULL_IMAGE}:${BUILD_CACHE_TAG}"

log "✓ Build and push completed successfully"
log "Artifact: ${FULL_IMAGE}:${TAG}"
```

---

### 5.3 Artifact Registry Management

#### Internal Working Mechanism

Artifact registries store Docker images with metadata, access controls, and vulnerability information:

```
Registry Storage Model

Registry (Harbor, ECR, ACR, Artifactory)
├── Repository: myapp
│   ├── Image: myapp:1.0.0
│   │   ├── Manifest (image config)
│   │   ├── Layer 1: base OS
│   │   ├── Layer 2: dependencies
│   │   ├── Layer 3: application code
│   │   ├── Metadata:
│   │   │   ├── Size: 250MB
│   │   │   ├─ Pushed: 2026-03-07 10:30:00 UTC
│   │   │   ├─ Vulnerability scan: PASSED
│   │   │   └─ Signature: VERIFIED
│   │   └─ SBOM attached
│   │
│   ├── Image: myapp:latest
│   │   └─ (Points to latest version)
│   │
│   └── Image: myapp:1.0.1
│       ├─ Manifest
│       ├─ Layers (3 reused from 1.0.0, 1 new)
│       └─ Metadata
```

**Benefits of centralized registry:**
- Deduplication: Identical layers shared across images (save 70% storage)
- Access control: RBAC per repository/image
- Audit: Who pulled/pushed what, when
- Lifecycle: Automatic cleanup of old images
- Distribution: Global CDN reduces pull times

#### Production Usage Patterns

**Pattern 1: Harbor Registry with Authentication**

```bash
#!/bin/bash
# Setup private Harbor registry with pod security

# 1. Deploy Harbor with Helm
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor \
  --namespace harbor --create-namespace \
  --values harbor-values.yaml

# 2. Create projects and robot accounts
curl -X POST https://harbor.company.internal/api/v2.0/projects \
  -H "Authorization: Basic $(echo -n "admin:password" | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "project_name": "backend",
    "public": false,
    "storage_limit": 1099511627776
  }'

# 3. Create robot account for CI/CD
curl -X POST https://harbor.company.internal/api/v2.0/robots \
  -H "Authorization: Basic $(echo -n "admin:password" | base64)" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "cicd-builder",
    "description": "CI/CD pipeline pusher",
    "access": [
      {
        "resource": "/project/backend/repository",
        "action": ["pull", "push"]
      }
    ]
  }' | jq '.secret' > /tmp/robot-token

# 4. Kubernetes secret for image pull
kubectl create secret docker-registry harbor-credentials \
  --docker-server=harbor.company.internal \
  --docker-username=robot\$cicd-builder \
  --docker-password="$(cat /tmp/robot-token)" \
  -n default
```

**Pattern 2: Image Lifecycle Management**

```bash
#!/bin/bash
# Cleanup old images; keep only N recent versions

REGISTRY="harbor.company.internal"
REPOSITORY="myapp"
KEEP_VERSIONS=10

log_policy() {
    cat > /opt/policies/image-retention.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: image-retention-policy
data:
  retention-rules: |
    {
      "algorithm": "or",
      "rules": [
        {
          "template": "recentXdays",
          "params": {"x": 30},
          "tagSelectorsMatchType": "excluding",
          "tagSelectors": [{"displayText": "* latest *", "pattern": "*latest*"}],
          "scopeSelectors": [{"displayText": "backend", "pattern": "backend/**"}]
        },
        {
          "template": "latestPushedK",
          "params": {"k": 10},
          "tagSelectorsMatchType": "withoutMatchingLabel",
          "tagSelectors": [{"displayText": "release", "pattern": "release-*"}],
          "untaggedArtifactsOnly": false,
          "scopeSelectors": [{"displayText": "releases", "pattern": "**"}]
        }
      ]
    }
EOF
}

# Automated cleanup job
cleanup_old_images() {
    IMAGES=$(curl -s \
      -H "Authorization: Bearer $(get_harbor_token)" \
      "https://${REGISTRY}/api/v2.0/repositories/${REPOSITORY}/artifacts" \
      | jq -r '.[] | select(.tags[0].name != "latest") | .digest')
    
    COUNT=0
    for DIGEST in $IMAGES; do
        if [ $COUNT -ge $((KEEP_VERSIONS - 1)) ]; then
            curl -X DELETE \
              -H "Authorization: Bearer$(get_harbor_token)" \
              "https://${REGISTRY}/api/v2.0/repositories/${REPOSITORY}/artifacts/${DIGEST}"
            COUNT=$((COUNT + 1))
        fi
    done
    echo "Deleted $COUNT old images"
}

cleanup_old_images
```

---

### 5.4 Caching Layers in CICD

#### Practical Example with GitHub Actions

```yaml
# .github/workflows/optimized-build.yml
name: Optimized Build with Layer Caching

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Cache Docker layers
        uses: docker/build-push-action@v5
        with:
          context: .
          push: false
          cache-from: type=gha
          cache-to: type=gha,mode=max
      
      - name: Build image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

---

### 5.5 Security Scanning & Compliance

#### Integrated Security Pipeline

```bash
#!/bin/bash
# secure-cicd-pipeline.sh - Complete security checks

IMAGE=$1
SEVERITY_THRESHOLD="HIGH"
CRITICAL_LIMIT=0
HIGH_LIMIT=5

log() { echo "[$(date +'%H:%M:%S')] $@"; }

# 1. Vulnerability scanning
log "Scanning image for vulnerabilities..."
trivy image --severity "$SEVERITY_THRESHOLD" "$IMAGE" | tee trivy-report.txt

CRITICAL=$(grep -c "CRITICAL" trivy-report.txt || echo 0)
HIGH=$(grep -c "HIGH" trivy-report.txt || echo 0)

if [ "$CRITICAL" -gt "$CRITICAL_LIMIT" ]; then
    log "❌ Failed: Found $CRITICAL critical vulnerabilities"
    exit 1
fi

if [ "$HIGH" -gt "$HIGH_LIMIT" ]; then
    log "⚠️  Warning: Found $HIGH high vulnerabilities (limit: $HIGH_LIMIT)"
fi

# 2. Secret scanning
log "Scanning for secrets..."
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  trufflesecurity/trufflehog docker \
    --image "$IMAGE" \
    | grep -i "secret\|token\|key" && exit 1 || log "✓ No secrets found"

# 3. Generation SBOM
log "Generating SBOM..."
syft "$IMAGE" --output spdx > sbom.spdx.txt

# 4. License compliance check
log "Checking licenses..."
grype "$IMAGE" -o json | \
  jq '.matches[] | select(.artifact.licenses[].spdxExpression | contains("GPL"))' \
  | grep -q "GPL" && \
  log "⚠️  GPL licenses detected (may require special handling)" || \
  log "✓ No problematic licenses found"

log "✓ All security checks passed"
```

---

## Production Deployment Patterns

### 6.1 Blue-Green Deployments

#### Internal Working Mechanism

Blue-Green maintains two identical production environments; traffic switches instantly between them:

```
Current State (Blue Running):
┌─────────────────────────────────────────┐
│         Load Balancer / Router           │
│  (Traffic: 100% → Blue)                 │
└────────────┬────────────────────────────┘
             │
      ┌──────┴────────┐
      ▼               ▼
   ┌─────┐         ┌─────┐
   │Blue │         │Green│
   │v1.0 │         │v2.0 │
   │ ✓   │         │ (Idle) │
   └─────┘         └─────┘

Deployment:
1. Build v2.0 image
2. Deploy to Green environment
3. Run health checks on Green
4. Validate Green (smoke tests)
5. Switch router: 100% → Green
6. Monitor metrics on Green
7. Blue kept running for instant rollback

If issues detected in Green:
  → Switch back: 100% → Blue (instant)
  → Investigate Green
  → Re-deploy after fixes
```

**Advantages:**
- Instant cutover (no downtime)
- Instant rollback (revert traffic to Blue)
- Test deployment in production-like environment
- Allows A/B testing (50% routes to each initially)

**Disadvantages:**
- Requires 2x infrastructure (cost)
- Database schema migrations tricky (shared DB)
- Storage/persistence must be shared

**When to use:** Database migrations, breaking API changes, large infrastructure changes

#### Production Implementation

```bash
#!/bin/bash
# blue-green-deploy.sh - Production deployment

set -e

NAMESPACE="production"
SERVICE="myapp"
IMAGE="$1"

if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image>"
    exit 1
fi

log() { echo "[$(date +'%H:%M:%S')] $@"; }

# Determine current color
CURRENT=$(kubectl get service $SERVICE -n $NAMESPACE \
    -o jsonpath='{.spec.selector.color}')

if [ "$CURRENT" == "blue" ]; then
    NEXT="green"
else
    NEXT="blue"
fi

log "Current: $CURRENT, deploying to: $NEXT"

# Deploy new version to inactive environment
log "Deploying image to $NEXT environment..."
kubectl set image deployment/$SERVICE-$NEXT \
    $SERVICE=$IMAGE \
    -n $NAMESPACE \
    --record

# Wait for rollout
log "Waiting for deployment..."
kubectl rollout status deployment/$SERVICE-$NEXT \
    -n $NAMESPACE \
    --timeout=10m

# Health checks
log "Running health checks on $NEXT..."
PODS=$(kubectl get pods -l "app=$SERVICE,color=$NEXT" \
    -n $NAMESPACE \
    -o jsonpath='{.items[*].metadata.name}')

for POD in $PODS; do
    kubectl exec $POD -n $NAMESPACE -- \
        /bin/sh -c 'curl -f http://localhost:8080/health' || exit1
done

log "✓ $NEXT environment healthy"

# Switch traffic
log "Switching traffic to $NEXT..."
kubectl patch service $SERVICE -n $NAMESPACE \
    -p '{"spec":{"selector":{"color":"'$NEXT'"}}}'

# Monitor metrics
log "Monitoring metrics (30 seconds)..."
for i in {1..30}; do
    ERROR_RATE=$(kubectl exec -n monitoring prometheus-0 -- \
        promtool query instant \
        'rate(http_requests_total{status=~"5.."}[1m])' \
        | grep -oP '\d+\.\d+' | head -1)
    
    if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
        log "❌ Error rate spike detected ($ERROR_RATE), rolling back!"
        kubectl patch service $SERVICE -n $NAMESPACE \
            -p '{"spec":{"selector":{"color":"'$CURRENT'"}}}'
        exit 1
    fi
    sleep 1
done

log "✓ Deployment successful to $NEXT"
log "Blue-Green switch complete"
```

---

### 6.2 Canary Deployments

#### Internal Working Mechanism

Canary gradually shifts traffic to new version while monitoring metrics:

```
Canary Deployment Timeline:

Time 0:        Time 5m:      Time 15m:     Time 30m:
100% v1.0      95% v1.0      50% v1.0      100% v2.0
0% v2.0        5% v2.0       50% v2.0      0% v1.0

[v1] [v1] [v1]  [v1] [v1]✓[v2]  [v1]✓✓[v2]✓✓  [v2] [v2] [v2]
[v1] [v1] [v1]  [v1] [v1]✓[v2]  [v1]✓✓[v2]✓✓  [v2] [v2] [v2]
[v1] [v1] [v1]  [v1] [v1]✓[v2]  [v1]✓✓[v2]✓✓  [v2] [v2] [v2]

⬇ Metrics Monitored:
Error Rate:       0.2% → 0.3% → 0.25% → 0.2% ✓ (healthy)
P99 Latency:      45ms → 48ms → 47ms → 46ms ✓ (acceptable)
Throughput:       5000/s → 4950/s → 5100/s ✓ (stable)

If error rate >2% → Automatic rollback to v1.0
```

**Advantages:**
- Gradual risk mitigation (small blast radius initially)
- Metrics-driven rollback
- Detect issues early with subset of traffic
- Can be fully automated

**Disadvantages:**
- Longer deployment (20-30 minutes typical)
- Requires instrumentation (metrics endpoint)
- Database schema migrations need backward compatibility

**When to use:** Critical user-facing services, high-traffic systems, payment/auth

#### Production Implementation with Istio/Flagger

```yaml
# canary-deployment.yaml - Flagger with Istio

apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp
  namespace: production
spec:
  # Canary definition
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  
  # Traffic shaping
  service:
    port: 8080
    targetPort: 8080
  
  # Analysis parameters
  analysis:
    # Interval to check metrics
    interval: 1m
    
    # How long to let canary run
    threshold: 10
    
    # Metrics gates (must pass to continue)
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
    
    - name: error-rate
      thresholdRange:
        max: 5
      interval: 1m
    
    # Webhooks for custom checks
    webhooks:
    - name: acceptance-tests
      url: http://flagger-loadtester/
      timeout: 30s
      metadata:
        type: smoke
        cmd: "curl -sd 'test' http://myapp-canary:8080/api/test"
    
    - name: load-test
      url: http://flagger-loadtester/
      timeout: 5s
      metadata:
        type: load
        cmd: "ab -n 100 -c 10 http://myapp-canary:8080/"
  
  # Traffic progression
  skipAnalysis: false
  
  # Stages: 2% → 10% → 50% → 100%
  stages:
  - weight: 5
    interval: 1m
  - weight: 20
    interval: 3m
  - weight: 50
    interval: 5m

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

Script-based canary (for non-Istio):
```bash
#!/bin/bash
# canary-deploy.sh - Script-based gradual traffic shift

DEPLOYMENT="myapp"
NAMESPACE="production"
NEW_REPLICA=$1
CANARY_STAGES=(5 20 50 100)
METRIC_THRESHOLD_ERROR=2.0
METRIC_THRESHOLD_LATENCY=500

log() { echo "[$(date +'%H:%M:%S')] $@"; }

deploy_canary() {
    log "Starting canary deployment with $NEW_REPLICA replicas"
    
    for PERCENTAGE in "${CANARY_STAGES[@]}"; do
        log "Canary stage: $PERCENTAGE% traffic"
        
        # Adjust replica ratio
        CANARY_REPLICAS=$((NEW_REPLICA * PERCENTAGE / 100))
        kubectl set replicas deployment/$DEPLOYMENT --replicas=$CANARY_REPLICAS \
            -n $NAMESPACE
        kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
        
        # Monitor metrics
        log "  Monitoring metrics..."
        for i in {1..5}; do
            ERROR_RATE=$(get_metric "error_rate_5m")
            LATENCY=$(get_metric "request_latency_p99")
            
            log "    Error: ${ERROR_RATE}%, Latency: ${LATENCY}ms"
            
            if (( $(echo "$ERROR_RATE > $METRIC_THRESHOLD_ERROR" | bc -l) )); then
                log "  ❌ Error rate exceeded ($ERROR_RATE > $METRIC_THRESHOLD_ERROR)"
                rollback_canary
                return 1
            fi
            
            if (( $(echo "$LATENCY > $METRIC_THRESHOLD_LATENCY" | bc -l) )); then
                log "  ❌ Latency exceeded ($LATENCY > $METRIC_THRESHOLD_LATENCY)"
                rollback_canary
                return 1
            fi
            
            sleep 30
        done
        
        log "  ✓ Stage passed"
    done
    
    log "✓ Canary deployment successful"
    return 0
}

rollback_canary() {
    log "Rolling back canary deployment..."
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE
    kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
}

deploy_canary
```

---

### 6.3 Rolling Updates

#### Internal Working Mechanism

Rolling replaces old replicas with new ones incrementally:

```
Rolling Update (max surge=1, max unavailable=0):

Initial: [v1] [v1] [v1] [v1] [v1]  (5 replicas, v1.0)
         ▼ Update to v2.0

Step 1:  [v1] [v1] [v1] [v1] [v2]  (4 old, 1 new)
         └─ Wait for v2 readiness
         ▼
Step 2:  [v1] [v1] [v1] [v2] [v2]  (3 old, 2 new)
         └─ Drain connections from old
         ▼                     
Step 3:  [v1] [v1] [v2] [v2] [v2]  (2 old, 3 new)
         ▼
Step 4:  [v1] [v2] [v2] [v2] [v2]  (1 old, 4 new)
         ▼
Final:   [v2] [v2] [v2] [v2] [v2]  (0 old, 5 new) ✓

Duration: ~5 minutes (1 replica @ 60sec startup)
Downtime: 0 (always have capacity)
Old version: Kept for instant rollback
```

**Advantages:**
- No 2x infrastructure cost (blue-green)
- Stateless services handle out-of-order requests gracefully
- Automatic rollback capability
- Progressive deployment (detect issues early)

**Disadvantages:**
- Slower than blue-green (gradual)
- Database state shared between versions (backward compat needed)
- Debugging harder (old + new running simultaneously)

**When to use:** Stateless services, backward-compatible changes, cost-conscious  scenarios

#### Kubernetes Implementation

```yaml
# deployment.yaml - Rolling update strategy

apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # Allows 1 extra replica during update
      maxUnavailable: 0    # Never take replica offline
  
  selector:
    matchLabels:
      app: myapp
  
  template:
    metadata:
      labels:
        app: myapp
        version: v2.0
    
    spec:
      # Graceful shutdown
      terminationGracePeriodSeconds: 30
      
      containers:
      - name: myapp
        image: ghcr.io/myapp:v2.0
        imagePullPolicy: Always
        
        ports:
        - containerPort: 8080
        
        # Ready to accept traffic
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 2
        
        # Alive check
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        
        # Resource requests (required for rolling update)
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        
        # Graceful startup/shutdown
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 5"]
```

Kubectl rollout commands:
```bash
# Trigger rolling update
kubectl set image deployment/myapp myapp=ghcr.io/myapp:v2.0 --record

# Monitor progress
kubectl rollout status deployment/myapp --watch

# Pause if issues detected
kubectl rollout pause deployment/myapp

# Resume after fix
kubectl rollout resume deployment/myapp

# Undo to previous version (instant)
kubectl rollout undo deployment/myapp

# View rollout history
kubectl rollout history deployment/myapp
kubectl rollout history deployment/myapp --revision=3  # See details
```

---

### 6.4 A/B Testing & Feature Flags

#### Pattern 1: Native Feature Flags

```python
# feature_flags.py - Runtime feature control

import os
from enum import Enum

class Feature(Enum):
    NEW_CHECKOUT_UI = "new_checkout_ui"
    EXPERIMENTAL_RECOMMENDATIONS = "experimental_recs"
    STRIPED_PAYMENT = "stripe_v3"

def is_feature_enabled(feature: Feature, user_id: str = None) -> bool:
    """Check if feature is enabled for user"""
    
    # Check environment override (for testing)
    override = os.getenv(f"FEATURE_{feature.value.upper()}_ENABLED")
    if override is not None:
        return override.lower() == "true"
    
    # Check user segment (A/B test)
    if feature == Feature.NEW_CHECKOUT_UI:
        return hash(user_id) % 100 < 20  # 20% of users
    
    if feature == Feature.EXPERIMENTAL_RECOMMENDATIONS:
        # Only for paid users
        return is_paid_user(user_id) and hash(user_id) % 100 < 5
    
    if feature == Feature.STRIPED_PAYMENT:
        return True  # Fully rolled out
    
    return False

# In application code
if is_feature_enabled(Feature.NEW_CHECKOUT_UI, user_id):
    return render_new_checkout()
else:
    return render_legacy_checkout()
```

#### Pattern 2: Remote Feature Flag Service

```yaml
# feature-flags-service.yaml - Dedicated service

apiVersion: apps/v1
kind: Deployment
metadata:
  name: feature-flags-svc
spec:
  replicas: 3
  selector:
    matchLabels:
      app: feature-flags
  
  template:
    metadata:
      labels:
        app: feature-flags
    
    spec:
      containers:
      - name: feature-flags
        image: ghcr.io/flag-management:latest
        
        env:
        - name: PORT
          value: "8080"
        - name: CONFIG_MODE
          value: "dynamic"  # Reload on change
        
        ports:
        - containerPort: 8080
        
        volumeMounts:
        - name: flags-config
          mountPath: /etc/flags
      
      volumes:
      - name: flags-config
        configMap:
          name: feature-flags
          defaultMode: 0644

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
data:
  flags.yaml: |
    features:
      new_checkout_ui:
        enabled: true
        rollout: 25  # 25% of users
        attributes:
          premium_users_only: false
      
      experimental_recs:
        enabled: false
        rollout: 0
        attributes:
          paid_users_only: true
          min_account_age: 30  # days

---
apiVersion: v1
kind: Service
metadata:
  name: feature-flags-svc
spec:
  selector:
    app: feature-flags
  ports:
  - port: 8080
    targetPort: 8080
```

---

### 6.5 Service Mesh Integration

#### Internal Working Mechanism

Service mesh (Istio) manages inter-service networking, providing traffic management, security, and observability:

```
Traditional Microservices:
┌──────────┐      ┌──────────┐      ┌──────────┐
│   API    │─────→│ Database │      │  Cache   │
│ Gateway  │      │  Service │      │ Service  │
└──────────┘      └──────────┘      └──────────┘
       ↓                 ↓                  ↓
   Direct calls    Direct connectivity   Network issues
   Hard to debug   No encryption         No rate limit

WITH Service Mesh (Istio):
┌──────────┐
│   API    │
│ Gateway  │
└─────┬────┘
      │
      ▼ (requests through mesh)
┌──────────────────────────────────────┐
│        Istio Service Mesh             │
│  ┌─────────────┐  ┌─────────────┐   │
│  │  Sidecar    │  │  Sidecar    │   │
│  │  Proxy      │  │  Proxy      │   │
│  │  (Envoy)    │  │  (Envoy)    │   │
│  └─────────────┘  └─────────────┘   │
│     │                 │              │
│  Intercept       Traffic managed    │
│  requests        ├─ Rate limiting    │
│  ├─ mTLS         ├─ Retries          │
│  ├─ Metrics      ├─ Circuit breaker  │
│  └─ Tracing      └─ Load balancing   │
└──────────────────────────────────────┘
      ↓                 ↓
  Service A        Service B
```

#### Istio VirtualService for Canary

```yaml
# canary-with-istio.yaml

apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
spec:
  hosts:
  - myapp.company.internal
  
  http:
  # Route subset of traffic to canary
  - match:
    - uri:
        prefix: "/api/experimental"
    route:
    - destination:
        host: myapp
        port:
          number: 8080
        subset: canary
      weight: 100
  
  # Main traffic split (gradually shift)
  - route:
    - destination:
        host: myapp
        port:
          number: 8080
        subset: stable
      weight: 95  # 95% to stable
    
    - destination:
        host: myapp
        port:
          number: 8080
        subset: canary
      weight: 5   # 5% to canary
    
    timeout: 10s
    retries:
      attempts: 3
      perTryTimeout: 2s

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
spec:
  host: myapp
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1000
      http:
        http1MaxPendingRequests: 100
        maxRequestsPerConnection: 2
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
  
  subsets:
  - name: stable
    labels:
      version: v1.0
  
  - name: canary
    labels:
      version: v2.0
```

Istio monitoring:
```bash
# View traffic flows
istioctl analyze

# Check virtual services
kubectl get virtualservice -A

# View sidecar proxy config
istioctl proxy-config routes myapp-pod-name.default

# Enable Kiali dashboard (service mesh visualization)
kubectl port-forward -n istio-system svc/kiali 20000:20000
# Visit: http://localhost:20000
```

---

## Failure Scenarios & Recovery

### 7.1 Container Health Checks

#### Internal Working Mechanism

Health checks serve two purposes:
1. **Readiness:** Is container ready to serve traffic?
2. **Liveness:** Is container still alive (should be restarted)?

```
Failure Detection Timeline:

Container starts
   │
   ├─ Initial delay (30s): Don't healthcheck yet
   │  └─ App is still starting
   │
   ├─ Readiness probe (period=5s)
   │  └─ Check /ready endpoint
   │  └─ Success? Add to load balancer
   │  └─ Fail 2x? Remove from LB
   │
   └─ Liveness probe (period=10s)
      └─ Check /health endpoint
      └─ Fail 3x? Restart container
      └─ Repeat cycle

Consequences of failure:
- Readiness fail → No traffic sent (graceful degradation)
- Liveness fail → Container restarted (self-healing)
```

#### Kubernetes Health Checks

```yaml
# deployment-with-health-checks.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthy-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  
  template:
    metadata:
      labels:
        app: myapp
    
    spec:
      terminationGracePeriodSeconds: 45
      
      containers:
      - name: myapp
        image: myapp:latest
        
        # HTTP health endpoint
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 15   # Wait before first check
          periodSeconds: 5           # Check every 5 seconds
          timeoutSeconds: 2         # Timeout after 2 seconds
          failureThreshold: 2       # 2 failures = remove from LB
          successThreshold: 1       # 1 success = add to LB
        
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3       # 3 failures = restart
        
        # Startup probe (for slow-starting apps)
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8080
          failureThreshold: 30      # Allow 30 * 10s = 5 min startup
          periodSeconds: 10
```

Custom health check script:
```bash
#!/bin/bash
# health-check.sh - Comprehensive health check

PORT=${PORT:-8080}
READINESS_CHECK=${READINESS_CHECK:-"/health/ready"}
LIVENESS_CHECK=${LIVENESS_CHECK:-"/health/live"}

case "$1" in
  readiness)
    # Check if app is accepting traffic
    response=$(curl -s -w "%{http_code}" http://localhost:$PORT$READINESS_CHECK)
    http_code="${response: -3}"
    
    if [ "$http_code" == "200" ]; then
      echo "Ready"
      exit 0
    else
      echo "Not ready (HTTP $http_code)"
      exit 1
    fi
    ;;
  liveness)
    # Check if process is still running and responding
    if ! pgrep -f "myapp" > /dev/null; then
      echo "Process not running"
      exit 1
    fi
    
    response=$(curl -s -w "%{http_code}" http://localhost:$PORT$LIVENESS_CHECK)
    http_code="${response: -3}"
    
    if [ "$http_code" == "200" ]; then
      echo "Alive"
      exit 0
    else
      echo "Not responding (HTTP $http_code)"
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 {readiness|liveness}"
    exit 1
esac
```

---

### 7.2 Common Failure Modes

#### Failure Mode 1: OOMKilled (Out of Memory)

**Symptoms:**
- Container restarts frequently
- `kubectl describe pod` shows `OOMKilled`
- No errors in logs (sudden termination)

**Root Causes:**
- Memory leak in application
- Incorrect memory limits too low
- Spike in concurrent connections

**Detection & Recovery:**

```bash
#!/bin/bash
# detect-oomkilled.sh

NAMESPACE="$1"
DEPLOYMENT="$2"

check_oomkilled() {
    kubectl get pods -n "$NAMESPACE" -l "app=$DEPLOYMENT" \
        -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[*].lastState.terminated.reason}{"\n"}{end}' \
        | grep -i "oomkilled"
}

if check_oomkilled > /dev/null; then
    echo "OOMKilled detected!"
    
    # 1. Increase memory limits  
    kubectl set resources deployment/$DEPLOYMENT \
        --limits=memory=1Gi \
        -n "$NAMESPACE" \
        --record
    
    # 2. Analyze memory usage
    kubectl top pods -n "$NAMESPACE" -l "app=$DEPLOYMENT"
    
    # 3. Check for memory leaks
    kubectl logs $(kubectl get pods -n "$NAMESPACE" \
        -l "app=$DEPLOYMENT" -o jsonpath='{.items[0].metadata.name}') \
        -n "$NAMESPACE" | grep -i "memory\|alloc" | tail -20
fi
```

#### Failure Mode 2: CrashLoopBackOff

**Symptoms:**
- Pod status shows `CrashLoopBackOff`
- Container immediately exits after starting
- Application errors in logs

**Root Causes:**
- Missing environment variables
- Misconfigured application
- Database connection failure
- Missing dependencies

**Recovery Script:**

```bash
#!/bin/bash
# diagnose-crash-loop.sh

POD="${1:-$(kubectl get pods -l error=true -o jsonpath='{.items[0].metadata.name}')}"
NAMESPACE="${2:-default}"

echo "=== Pod Status ==="
kubectl describe pod "$POD" -n "$NAMESPACE" | head -30

echo -e "\n=== Recent Logs ==="
kubectl logs "$POD" -n "$NAMESPACE" --tail=50

echo -e "\n=== Environment Variables ==="
kubectl exec "$POD" -n "$NAMESPACE" -- env | sort

echo -e "\n=== Network Connectivity ==="
kubectl exec "$POD" -n "$NAMESPACE" -- sh -c '
  echo "DNS resolve (google.com):"
  nslookup google.com || echo "DNS failure"
  
  echo -e "\nSQL connectivity (if applicable):"
  nc -zv $DB_HOST $DB_PORT 2>&1 || echo "Database unreachable"
'

# Common fixes
echo -e "\n=== Recovery Options ==="
echo "1. kubectl set env deployment/myapp MISSING_VAR=value"
echo "2. kubectl rollout undo deployment/myapp"
echo "3. kubectl set image deployment/myapp myapp=previous:tag"
```

---

### 7.3 Debugging Techniques

#### Technique 1: Interactive Debugging

```bash
#!/bin/bash
# debug-container.sh - Interactive container debugging

POD="${1}"
NAMESPACE="${2:-production}"

echo "Attaching to pod: $POD"

# Start debugging session
kubectl debug "$POD" \
  -n "$NAMESPACE" \
  -it \
  --image=debian:bookworm-slim \
  -- /bin/bash

# Inside the container:
# apt-get update && apt-get install -y curl wget netcat htop strace
# curl http://localhost:8080/health
# netstat -an | grep LISTEN
# ps aux
# tail -f /var/log/application.log
# strace -p <pid> -e trace=network
```

#### Technique 2: Log Analysis

```bash
#!/bin/bash
# analyze-logs.sh - Systematic log analysis

NAMESPACE="production"
DEPLOYMENT="myapp"

# Aggregate logs from all replicas
echo "=== ERROR FREQUENCY ==="
kubectl logs -l "app=$DEPLOYMENT" -n "$NAMESPACE" \
  --tail=1000 \
  --all-containers=true \
  --timestamps=true | \
  grep -i "ERROR\|EXCEPTION\|FATAL" | \
  cut -d':' -f1-3 | uniq -c | sort -rn | head -20

echo -e "\n=== ERROR TYPES ==="
kubectl logs -l "app=$DEPLOYMENT" -n "$NAMESPACE" \
  --tail=1000 | \
  grep -oP '(?<=Error: )[^;]*' | sort | uniq -c | sort -rn

echo -e "\n=== RECENT CRASHES ==="
kubectl get events -n "$NAMESPACE" \
  --field-selector involvedObject.kind=Pod) | \
  grep -i "backoff\|killed\|failed" | \
  sort -k firstTimestamp -r | head -10

echo -e "\n=== SLOWEST REQUESTS ==="
kubectl logs -l "app=$DEPLOYMENT" -n "$NAMESPACE" \
  --tail=500 | \
  grep -oP 'latency=\K[0-9]+' | \
  sort -rn | head -10 | \
  xargs -I {} echo "{}ms"
```

---

### 7.4 Performance Bottlenecks

#### Root Cause Analysis

```bash
#!/bin/bash
# performance-analysis.sh - Identify bottlenecks

DEPLOYMENT="myapp"
NAMESPACE="production"

# Metric 1: CPU utilization
echo "=== CPU USAGE ==="
kubectl top pods -l "app=$DEPLOYMENT" -n "$NAMESPACE" | sort -k 3 -rn

# Metric 2: Memory pressure
echo -e "\n=== MEMORY USAGE ==="
kubectl top pods -l "app=$DEPLOYMENT" -n "$NAMESPACE" | sort -k 4 -rn

# Metric 3: Network I/O
echo -e "\n=== NETWORK THROUGHPUT ==="
kubectl exec -it "$(kubectl get pods -l "app=$DEPLOYMENT" \
  -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')" \
  -n "$NAMESPACE" -- \
  cat /proc/net/dev | tail -1

# Metric 4: Disk I/O
echo -e "\n=== DISK I/O ==="
kubectl exec -it "$(kubectl get pods -l "app=$DEPLOYMENT" \
  -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')" \
  -n "$NAMESPACE" -- \
  iostat -x 1 2

# Metric 5: Database connections
echo -e "\n=== DATABASE CONNECTIONS ==="
kubectl exec -it "$(kubectl get pods -l "app=$DEPLOYMENT" \
  -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')" \
  -n "$NAMESPACE" -- \
  sh -c 'netstat -an | grep ESTABLISHED | grep -E "3306|5432" | wc -l'

# Metric 6: Cache hit ratio
echo -e "\n=== CACHE METRICS ==="
kubectl exec -it "$(kubectl get pods -l "app=$DEPLOYMENT" \
  -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')" \
  -n "$NAMESPACE" -- \
  curl -s http://localhost:8080/metrics | grep -i "cache"
```

---

### 7.5 Resource Constraints & OOMKilled

#### Memory Limit Configuration

```yaml
# deployment-with-resource-limits.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-bounded-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  
  template:
    metadata:
      labels:
        app: myapp
    
    spec:
      containers:
      - name: myapp
        image: myapp:latest
        
        # Resource requests & limits
        resources:
          # What K8s guarantees (scheduling basis)
          requests:
            cpu: 100m        # 0.1 CPU
            memory: 256Mi    # 256 MB
          
          # Hard limits (enforced by OS)
          limits:
            cpu: 1000m       # 1 CPU max
            memory: 512Mi    # 512 MB max
        
        # Memory pressure handling
        securityContext:
          allowPrivilegeEscalation: false
```

**Memory Tuning Guide:**

| Container Type | Request | Limit | Ratio |
|---|---|---|---|
| Java Spring Boot | 256Mi | 1024Mi | 1:4 |
| Python Django | 128Mi | 512Mi | 1:4 |
| Node.js | 128Mi | 512Mi | 1:4 |
| Go service | 64Mi | 256Mi | 1:4 |
| Static assets | 32Mi | 64Mi | 1:2 |

Memory optimization:
```bash
#!/bin/bash
# optimize-memory.sh

# 1. Profile memory usage
kubectl exec POD_NAME -- java -XX:+PrintFlagsFinal \
  | grep UseG1GC

# 2. Adjust JVM heap for Java
kubectl set env deployment/myapp \
  JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

# 3. Check for leaks
docker run --rm -v $(pwd):/src \
  openjdk:21-slim java -cp "/src" \
  -XX:+UnlockDiagnosticVMOptions \
  -XX:+TraceClassLoading \
  -XX:+G1PrintHeapRegions \
  MyApp
```

---

---

## Advanced Production Deployment Strategies (Supplementary Deep Dive)

### 8.1 Multi-Region Deployment Orchestration

#### Internal Working Mechanism

Multi-region deployment distributes replicas across geographic regions to achieve:
- **High Availability:** Region failure doesn't bring down service
- **Low Latency:** Users served from nearest region
- **Compliance:** Data residency requirements (GDPR, regional regulations)
- **Cost Optimization:** Leverage cheaper regions, scale by demand

**Multi-Region Architecture:**

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Global Load Balancer (GeoDNS)                     │
│            (Routes based on geographic location + latency)           │
└──────────┬────────────────────────────────────────────────────────┘
           │
     ┌─────┼─────┬──────────┬──────────┐
     │     │     │          │          │
     ▼     ▼     ▼          ▼          ▼
   US-E  US-W  EU-WE     APAC-SG   APAC-AU
   ┌──┐  ┌──┐  ┌──┐      ┌──┐      ┌──┐
   │K8│  │K8│  │K8│      │K8│      │K8│
   │s │  │s │  │s │      │s │      │s │
   │  │  │  │  │  │      │  │      │  │
   └┬─┘  └┬─┘  └┬─┘      └┬─┘      └┬─┘
    │     │     │         │         │
    └─────┴─────┴─────┬───┴─────────┘
                      │
                      ▼
           ┌──────────────────────┐
           │  Central Datastore   │
           │  (Replicated /CDN)   │
           └──────────────────────┘
```

**Deployment Flow for Multi-Region:**

```
Push to main/prod branch
         │
         ▼
   Trigger CICD
         │
    ┌────┴────┐
    │          │
    ▼          ▼
 Build     Scan
  image
    │
    ▼
 Registry
    │
    ├──────────────────────────────────────┐
    │                                      │
    ▼                                      ▼
Deploy to Primary Region (US-EAST)    Deploy to Secondary (after approval)
   ├─ Run canary 5%                       ├─ Wait for primary stability
   ├─ Monitor 10 minutes                  ├─ Run canary 5%
   ├─ Full rollout if healthy            ├─ Monitor 20 minutes
   └─ Trigger secondary  deployment      └─ Full rollout by region
                                             based on health
```

**Implementation with Terraform + Kubernetes:**

```hcl
# multi-region-deployment.tf

variable "regions" {
  default = {
    primary   = "us-east-1"
    secondary = "eu-west-1"
    tertiary  = "ap-southeast-1"
  }
}

# Deploy to each region
module "deployment" {
  for_each = var.regions

  source = "./modules/k8s-deployment"
  
  region           = each.value
  cluster_name     = "myapp-${each.key}"
  image_tag        = var.image_tag
  replica_count    = each.key == "primary" ? 10 : 5
  
  annotations = {
    "deployment.region" = each.value
    "deployment.role"   = each.key
  }
}

# Multi-region service with failover
resource "kubernetes_service" "global" {
  metadata {
    name = "myapp-global"
  }
  
  # Route to primary region
  spec {
    selector = {
      app    = "myapp"
      region = "us-east-1"
    }
    
    external_traffic_policy = "Local"
    type                    = "LoadBalancer"
  }
  
  # Failover to secondary if primary unhealthy
  depends_on = [
    module.deployment["primary"],
    module.deployment["secondary"]
  ]
}
```

Multi-region health monitoring:
```bash
#!/bin/bash
# health-check-multi-region.sh

REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")
HEALTH_THRESHOLD=0.05  # 5% error rate

for REGION in "${REGIONS[@]}"; do
    echo "Checking health in $REGION..."
    
    ENDPOINT="https://${REGION}.myapp.company.com/health"
    RESPONSE=$(curl -s -w "%{http_code}" "$ENDPOINT" -m 5)
    HTTP_CODE="${RESPONSE: -3}"
    BODY="${RESPONSE%???}"
    
    if [ "$HTTP_CODE" != "200" ]; then
        echo "❌ $REGION UNHEALTHY (HTTP $HTTP_CODE)"
        echo "   Triggering failover..."
        
        # Trigger failover procedure
        promote_secondary_region "$REGION"
    else
        ERROR_RATE=$(echo "$BODY" | jq -r '.error_rate')
        if (( $(echo "$ERROR_RATE > $HEALTH_THRESHOLD" | bc -l) )); then
            echo "⚠️  $REGION ERROR RATE HIGH: $ERROR_RATE"
            route_traffic_away_from_region "$REGION"
        else
            echo "✓ $REGION healthy (error rate: $ERROR_RATE)"
        fi
    fi
done
```

---

### 8.2 GitOps-Based Deployment

#### Internal Working Mechanism

GitOps uses Git repository as single source of truth for desired state. An in-cluster operator reconciles actual state with desired state:

```
GitOps Flow:

Developer commits ApplicationConfig to Git
         │
         ▼
    Git Webhook
         │
         ▼
   GitOps Operator (ArgoCD/Flux)
   (Watches git repository)
         │
    ┌────┴────┐
    │          │
 Detect     Compare
 Change     Desired vs Actual
    │          │
    │◄─────────┘
    │
    ├─ Desired: v2.0 in Git
    ├─ Actual:  v1.5 in Kubernetes
    │
    ▼
 Reconcile
 (Update cluster to match Git)
    │
    ▼
Apply manifests to Kubernetes cluster
    │
    ▼
 Monitor & Report Status
    │
    └─ Real-time sync status in Git/UI
```

**GitOps Benefits:**
- Declarative: Git commit = deployment (auditable)
- Diff before apply: See exactly what changes
- Rollback: `git revert` = instant rollback
- Multi-cluster: Same repo, multiple environments
- Compliance: All changes tracked, approved, logged

**ArgoCD Implementation:**

```yaml
# argocd-application.yaml

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-prod
  namespace: argocd
spec:
  project: production
  
  source:
    repoURL: https://github.com/myorg/myapp-config.git
    targetRevision: main
    path: apps/myapp/prod
    
    helm:
      values: |
        replicaCount: 10
        image:
          tag: "{{ .image_tag }}"
        resources:
          limits:
            memory: 512Mi
            cpu: 500m
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true      # Remove resources not in Git
      selfHeal: true   # Reconcile drift automatically
    syncOptions:
    - CreateNamespace=true
    
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  # Pre/post-sync hooks
  notification:
    email: notify@company.com
    on:
      - sync_succeeded
      - sync_failed
      - health_degraded
```

Git repository structure:
```
myapp-config/
├── apps/
│   ├── myapp/
│   │   ├── dev/
│   │   │   ├── kustomization.yaml
│   │   │   ├── deployment.yaml
│   │   │   └── service.yaml
│   │   ├── staging/
│   │   │   └── ...
│   │   └── prod/
│   │       ├── kustomization.yaml  # Base config
│   │       ├── replicas.yaml       # 10 replicas in prod
│   │       ├── resources.yaml      # Higher resource limits
│   │       └── monitoring.yaml     # Additional observability
│   └── ...
├── bootstrap/
│   └── install-argocd.sh
└── README.md
```

GitOps deployment flow:
```bash
#!/bin/bash
# gitops-deploy.sh - Merge to main triggers automatic deployment

# 1. Developer submits PR with new image version
git checkout -b feature/update-image

# Edit kustomization.yaml
cat > apps/myapp/prod/kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

images:
  - name: myapp
    newTag: v2.0.0  # Changed from v1.5.3

replicas:
  - name: myapp
    count: 10
EOF

git add apps/myapp/prod/kustomization.yaml
git commit -m "Deploy myapp v2.0.0 to production"
git push origin feature/update-image

# 2. PR review process (automated checks + human review)
# - ArgoCD generates diff: what will change
# - Security scan: any insecure configs?
# - Drift detection: matches current state?
# - Approval: CODEOWNERS must approve

# 3. Merge to main
git checkout main
git merge --no-ff feature/update-image
git push origin main

# 4. ArgoCD detects change automatically
# - Webhook triggered by git push
# - ArgoCD syncs: applies manifests to cluster
# - Status reported: deployment succeeded/failed

# 5. Instant rollback (if needed)
#    git revert <commit-hash>
#    push to main
#    ArgoCD syncs back to previous version
```

---

### 8.3 Database Migration During Deployments

#### Challenge: Coordinating Schema Changes with Application Deployments

Database migrations are the **hardest part of zero-downtime deployments** because:
- New code may require new schema
- Old code can't handle new schema
- Old schema may not work with new code
- Migrations on large tables lock entire database

**Safe Migration Strategy:**

```
Phase 1: Expand Schema (Backward Compatible)
   Old Code          Database
   (v1.5)            ├─ Old columns (still used)
                     └─ New columns (ignored by old code)
                        [SAFE: old code still works]

Phase 2: Deploy New Code (Dual Write)
   New Code          Database
   (v2.0)            ├─ Writes to both old & new columns
   - Reads new    ← └─ Reads from new columns
   - Writes both     [SAFE: old code still works]

Phase 3: Migrate Data (Background Job)
   Migration Job     Database
   [Background]      ├─ Copies data old → new columns
   [No downtime]     └─ Validates correctness
   [Can be rolled                [SAFE: running in parallel]
    back]

Phase 4: Cleanup (Remove Old Code References)
   New Code          Database
   (v2.0.1)          ├─ Remove dual writes
                     ├─ Remove old columns
   - Reads new only  └─ Drop old tables
   - Writes new   [NOW SAFE: old code removed]
        only
```

**Implementation Example:**

```sql
-- Step 1: Expand schema (backward compatible)
ALTER TABLE orders ADD COLUMN payment_method_v2 VARCHAR(50);
ALTER TABLE orders ADD COLUMN order_status_v2 VARCHAR(50);

-- Step 2: Create index for performance
CREATE INDEX idx_orders_status_v2 ON orders(order_status_v2);

-- Step 3: Dual-write in application (temporary code)
-- INSERT triggers: write to both old & new
CREATE TRIGGER orders_dual_write
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
  IF NEW.payment_method IS NOT NULL THEN
    SET NEW.payment_method_v2 = NEW.payment_method;
  END IF;
  IF NEW.order_status IS NOT NULL THEN
    SET NEW.order_status_v2 = NEW.order_status;
  END IF;
END;

-- Step 4: Data migration (background job)
-- Run during off-peak hours
UPDATE orders SET order_status_v2 = order_status 
WHERE order_status_v2 IS NULL 
LIMIT 10000;  -- Chunked to avoid locking

UPDATE orders SET payment_method_v2 = payment_method 
WHERE payment_method_v2 IS NULL 
LIMIT 10000;

-- Step 5: Verify migration correctness
SELECT COUNT(*) FROM orders WHERE order_status != order_status_v2;  -- Should be 0
SELECT COUNT(*) FROM orders WHERE payment_method != payment_method_v2;  -- Should be 0

-- Step 6: Application update (read from new columns)
-- Change application code to read from order_status_v2
-- Deploy new version

-- Step 7: Remove old columns (future release)
ALTER TABLE orders DROP COLUMN order_status;
ALTER TABLE orders DROP COLUMN payment_method;
RENAME COLUMN order_status_v2 TO order_status;
RENAME COLUMN payment_method_v2 TO payment_method;
```

**Automated Migration Script:**

```bash
#!/bin/bash
# safe-db-migration.sh

set -e

DB_HOST="prod-db.internal"
DB_NAME="myapp"
CHUNK_SIZE=10000
MAX_CHUNKS=1000

log() { echo "[$(date +'%H:%M:%S')] $@"; }

# Phase 1: Schema expansion
log "Phase 1: Expanding schema..."
mysql -h "$DB_HOST" "$DB_NAME" << 'EOF'
ALTER TABLE orders ADD COLUMN IF NOT EXISTS new_status VARCHAR(50);
CREATE INDEX IF NOT EXISTS idx_new_status ON orders(new_status);
EOF

# Phase 2: Verify expansion
log "Phase 2: Verifying schema addition..."
COLUMN_COUNT=$(mysql -h "$DB_HOST" -N "$DB_NAME" \
  -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_NAME='orders' AND COLUMN_NAME='new_status';")
[ "$COLUMN_COUNT" -eq 1 ] || { log "ERROR: Column not added"; exit 1; }

# Phase 3: Data migration (chunked to avoid locking)
log "Phase 3: Migrating data in chunks (size: $CHUNK_SIZE)..."
for CHUNK in $(seq 1 $MAX_CHUNKS); do
    REMAINING=$(mysql -h "$DB_HOST" -N "$DB_NAME" \
      -e "SELECT COUNT(*) FROM orders WHERE new_status IS NULL;")
    
    if [ "$REMAINING" -le 0 ]; then
        log "Migration complete"
        break
    fi
    
    log "  Chunk $CHUNK: Migrating $REMAINING rows (estimate)..."
    
    mysql -h "$DB_HOST" "$DB_NAME" << EOF
UPDATE orders SET new_status = old_status 
WHERE new_status IS NULL 
LIMIT $CHUNK_SIZE;
EOF
    
    # Check row count to avoid excessive locking
    sleep 2  # Brief pause between chunks
done

# Phase 4: Verification
log "Phase 4: Verifying migration..."
MISMATCH=$(mysql -h "$DB_HOST" -N "$DB_NAME" \
  -e "SELECT COUNT(*) FROM orders WHERE old_status != new_status;")

if [ "$MISMATCH" -gt 0 ]; then
    log "ERROR: $MISMATCH rows have mismatched data"
    exit 1
fi

log "✓ Migration successful: All rows valid"

# Phase 5: Application deployment
log "Phase 5: Ready for application deployment"
log "Next: Deploy new application version reading from 'new_status' column"
```

---

### 8.4 Automated Rollback Safeguards

#### Smart Rollback Decision Logic

```yaml
# automated-rollback-policy.yaml

apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: myapp-with-safeguards
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  
  analysis:
    interval: 30s
    threshold: 5
    
    # Automatic rollback criteria
    metrics:
    - name: error_rate
      thresholdRange:
        max: 1.0  # Rollback if >1% errors
      interval: 1m
    
    - name: latency_p99
      thresholdRange:
        max: 1000  # Rollback if P99 > 1s
      interval: 1m
    
    - name: cpu_usage
      thresholdRange:
        max: 80  # Rollback if CPU > 80%
      interval: 1m
    
    - name: memory_usage
      thresholdRange:
        max: 80  # Rollback if memory > 80%
      interval: 1m
    
    # Custom validation webhooks
    webhooks:
    - name: acceptance-tests
      url: http://flagger-loadtester/
      timeout: 30s
      metadata:
        cmd: "curl -X POST http://canary-app:8000/test/smoke"
    
    - name: critical-transaction-test
      url: http://flagger-loadtester/
      timeout: 60s
      metadata:
        cmd: "bash /tests/critical-flows.sh"
    
    # Skip if manual approval pending
    skipAnalysis: false
    
    # Rolled out in stages
    stages:
    - weight: 5
      interval: 2m
      metrics:
       - name: error_rate
         thresholdRange:
           max: 2.0  # Tighter threshold initially
    - weight: 50
      interval: 5m
    - weight: 100
      interval: 0s  # Finalize
```

**Rollback Automation Script:**

```bash
#!/bin/bash
# auto-rollback-manager.sh

set -e

DEPLOYMENT="myapp"
NAMESPACE="production"
ERROR_THRESHOLD=0.02  # 2% error rate
LATENCY_THRESHOLD=1000  # 1 second
ROLLBACK_COOLDOWN=300  # 5 minutes between rollbacks

# Metrics retrieval
get_error_rate() {
    kubectl exec -n monitoring prometheus-0 -- \
        promtool query instant \
        'rate(http_requests_total{status=~"5.."}[1m])' \
        2>/dev/null | grep -oP '\d+\.\d+' | head -1
}

get_p99_latency() {
    kubectl exec -n monitoring prometheus-0 -- \
        promtool query instant \
        'histogram_quantile(0.99, http_request_duration_seconds)' \
        2>/dev/null | grep -oP '\d+\.?\d*' | head -1
}

should_rollback() {
    local error_rate=$(get_error_rate)
    local latency=$(get_p99_latency)
    
    # Check error rate
    if (( $(echo "$error_rate > $ERROR_THRESHOLD" | bc -l) )); then
        echo "error_rate"
        return 0
    fi
    
    # Check latency
    if (( $(echo "$latency > $LATENCY_THRESHOLD" | bc -l) )); then
        echo "latency"
        return 0
    fi
    
    return 1
}

perform_rollback() {
    local reason=$1
    local timestamp=$(date -u +'%Y-%m-%d %H:%M:%S UTC')
    
    echo "[$timestamp] INITIATING ROLLBACK - Reason: $reason"
    
    # Step 1: Pause current deployment
    kubectl patch deployment $DEPLOYMENT -n $NAMESPACE \
        -p '{"spec":{"paused":true}}'
    
    # Step 2: Undo to previous revision
    kubectl rollout undo deployment/$DEPLOYMENT -n $NAMESPACE --record
    
    # Step 3: Wait for rollback to complete
    kubectl rollout status deployment/$DEPLOYMENT \
        -n $NAMESPACE \
        --timeout=5m
    
    # Step 4: Verify metrics post-rollback
    sleep 30
    ERROR_RATE=$(get_error_rate)
    
    if (( $(echo "$ERROR_RATE < 0.005" | bc -l) )); then
        echo "[$timestamp] ✓ Rollback successful"
        
        # Notify team
        slack_notify "🔄 Automatic rollback completed ($reason). Error rate normalized: $ERROR_RATE"
        
        # Create incident ticket
        jira create --project INCIDENT \
            --summary "Automatic rollback triggered: $reason" \
            --description "Deployment rolled back due to $reason. Error rate was $ERROR_RATE"
    else
        echo "[$timestamp] ❌ Rollback failed - metrics still degraded"
        echo "[$timestamp] Escalating to on-call team"
        
        # Emergency escalation
        pagerduty trigger --service-key SERVICE_KEY \
            --description "Automatic rollback failed for $DEPLOYMENT"
        exit 1
    fi
}

main() {
    echo "Starting auto-rollback monitor..."
    
    while true; do
        REASON=$(should_rollback)
        if [ $? -eq 0 ]; then
            perform_rollback "$REASON"
            
            # Cooldown period
            echo "Entering $ROLLBACK_COOLDOWN second cooldown..."
            sleep $ROLLBACK_COOLDOWN
        fi
        
        sleep 10  # Check every 10 seconds
    done
}

main
```

---

## Advanced Failure Recovery & Chaos Engineering

### 9.1 Circuit Breaker Pattern for Resilience

#### Internal Working Mechanism

Circuit breaker prevents cascading failures by stopping requests to failing services:

```
Circuit Breaker States:

CLOSED (Normal)
  └─ Requests flowing
  └─ Failures tracked
  └─ If failure_count > threshold → OPEN

OPEN (Failing)
  └─ Requests NOT sent (fail immediately)
  └─ Wait for timeout period
  └─ After timeout → HALF_OPEN

HALF_OPEN (Testing)
  └─ Limited requests through
  └─ If successful → CLOSED
  └─ If failure → OPEN (wait longer)

Timeline:
┌─────────────────────────────────────────────────┐
│ CLOSED (success)                                │
│ Request 1 → Success                            │
│ Request 2 → Success                            │
│ Request 3 → Success                            │
│ Request 4 → Error                              │
│ Request 5 → Error                              │
│ [5 consecutive errors > threshold]              │
│         │                                       │
│         ▼                                       │
│ OPEN (failing)                                  │
│ Request 6 → Fail immediately (no attempt)      │
│ Request 7 → Fail immediately                   │
│ Request 8 → [Wait timeout: 30 seconds]         │
│         │                                       │
│         ▼                                       │
│ HALF_OPEN (testing)                            │
│ Request 9 → Success (test request)             │
│ [Service recovered]                            │
│         │                                       │
│         ▼                                       │
│ CLOSED (recovered)                              │
│ Normal traffic resumes                          │
└─────────────────────────────────────────────────┘
```

**Implementation in Go:**

```go
package main

import (
    "fmt"
    "sync"
    "time"
)

type CircuitBreakerState string

const (
    CLOSED    CircuitBreakerState = "CLOSED"
    OPEN      CircuitBreakerState = "OPEN"
    HALF_OPEN CircuitBreakerState = "HALF_OPEN"
)

type CircuitBreaker struct {
    state              CircuitBreakerState
    failureCount       int
    successCount       int
    failureThreshold   int
    successThreshold   int
    timeout            time.Duration
    lastFailureTime    time.Time
    mu                 sync.RWMutex
}

func NewCircuitBreaker(failureThreshold int, timeout time.Duration) *CircuitBreaker {
    return &CircuitBreaker{
        state:            CLOSED,
        failureThreshold: failureThreshold,
        successThreshold: 2,
        timeout:          timeout,
    }
}

func (cb *CircuitBreaker) Call(fn func() error) error {
    cb.mu.Lock()
    defer cb.mu.Unlock()
    
    // Check if can transition from OPEN to HALF_OPEN
    if cb.state == OPEN {
        if time.Since(cb.lastFailureTime) > cb.timeout {
            cb.state = HALF_OPEN
            cb.successCount = 0
            cb.failureCount = 0
        } else {
            return fmt.Errorf("circuit breaker OPEN (retry in %v)", 
                cb.timeout - time.Since(cb.lastFailureTime))
        }
    }
    
    // Execute function
    err := fn()
    
    if err != nil {
        return cb.recordFailure()
    }
    
    return cb.recordSuccess()
}

func (cb *CircuitBreaker) recordFailure() error {
    cb.failureCount++
    cb.lastFailureTime = time.Now()
    
    if cb.state == CLOSED && cb.failureCount >= cb.failureThreshold {
        cb.state = OPEN
        fmt.Printf("[CB] Transitioned to OPEN after %d failures\n", cb.failureCount)
    } else if cb.state == HALF_OPEN {
        cb.state = OPEN
        fmt.Printf("[CB] Returned to OPEN (HALF_OPEN test failed)\n")
    }
    
    return fmt.Errorf("service call failed")
}

func (cb *CircuitBreaker) recordSuccess() error {
    cb.failureCount = 0
    
    if cb.state == HALF_OPEN {
        cb.successCount++
        if cb.successCount >= cb.successThreshold {
            cb.state = CLOSED
            fmt.Printf("[CB] Transitioned to CLOSED (recovered)\n")
        }
    }
    
    return nil
}

// Usage example
func main() {
    cb := NewCircuitBreaker(3, 5*time.Second)
    
    // Simulated failing service
    failingAttempt := 0
    serviceCall := func() error {
        failingAttempt++
        if failingAttempt <= 5 {
            return fmt.Errorf("service unavailable")
        }
        return nil
    }
    
    for i := 0; i < 15; i++ {
        err := cb.Call(serviceCall)
        fmt.Printf("Attempt %d: %v (State: %s)\n", i+1, err, cb.state)
        time.Sleep(2 * time.Second)
    }
}
```

---

### 9.2 Graceful Degradation Patterns

#### Strategy: Reduce Features, Maintain Core Function

```
Failure Scenario: Cache Service Down

Normal Request Flow (All features)
User Request
  ├─ Fetch user profile (database)
  ├─ Fetch recommendations (cache)   ← Cache is down
  ├─ Fetch order history (database)
  └─ Return full response
      Status: 500 (complete failure)

Degraded Request Flow (Core only)
User Request
  ├─ Fetch user profile (database)   ← OK
  ├─ Recommendations: Skip            ← CACHE DOWN - SKIP
  ├─ Fetch order history (database)   ← FALLBACK: use stale data
  └─ Return partial response (core features)
      Status: 200 (partial success)
```

**Graceful Degradation Implementation:**

```python
# degradation.py - Feature-based fallback

from functools import wraps
import requests
from typing import Optional

class DegradationManager:
    def __init__(self):
        self.disabled_features = set()
        self.cache_timeout = 60  # seconds
    
    def is_feature_available(self, feature_name: str) -> bool:
        """Check if feature should be served"""
        return feature_name not in self.disabled_features
    
    def disable_feature(self, feature_name: str, duration: int = 300):
        """Temporarily disable feature (5 min default)"""
        self.disabled_features.add(feature_name)
        # Schedule auto-re-enable after duration
        asyncio.create_task(self._auto_enable(feature_name, duration))
    
    async def _auto_enable(self, feature_name: str, duration: int):
        await asyncio.sleep(duration)
        self.disabled_features.discard(feature_name)
        logging.info(f"Feature {feature_name} re-enabled")

degradation = DegradationManager()

# Decorator for graceful fallbacks
def graceful_fallback(feature_name: str = None):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            feature = feature_name or func.__name__
            
            if not degradation.is_feature_available(feature):
                logging.warning(f"Feature {feature} degraded")
                return await fallback_handler(feature, *args, **kwargs)
            
            try:
                return await func(*args, **kwargs)
            except Exception as e:
                logging.error(f"Feature {feature} failed: {e}")
                degradation.disable_feature(feature)
                return await fallback_handler(feature, *args, **kwargs)
        
        return wrapper
    return decorator

async def fallback_handler(feature_name: str, user_id: int, **kwargs):
    """Provide degraded response"""
    if feature_name == "recommendations":
        # Cache/recommendation service down: return empty list
        return {"recommendations": [], "reason": "temporarily unavailable"}
    
    elif feature_name == "order_history":
        # Database down: return cached version
        cached = await redis.get(f"order_history:{user_id}")
        return cached or {"orders": [], "cache": True}
    
    return {"error": "service unavailable"}

# API endpoints with graceful fallback
@app.get("/api/user/{user_id}")
@graceful_fallback("full_profile")
async def get_user_profile(user_id: int):
    """Get user with all features (recommendations, history, etc)"""
    profile = await db.get_user(user_id)  # Core: always required
    
    profile["recommendations"] = await get_recommendations(user_id)  # Feature: can degrade
    profile["order_history"] = await get_orders(user_id)  # Feature: can degrade
    profile["preferences"] = await get_preferences(user_id)  # Feature: can degrade
    
    return profile

# Monitor for service health
async def health_monitor():
    """Continuously check downstream services"""
    while True:
        # Check cache
        try:
            await cache.ping()
        except:
            degradation.disable_feature("recommendations", duration=300)
            send_alert("Cache service unavailable")
        
        # Check database replica
        try:
            await db_replica.ping()
        except:
            degradation.disable_feature("order_history", duration=600)
            send_alert("Database replica unavailable")
        
        await asyncio.sleep(30)
```

**Health Endpoint Strategy:**

```python
@app.get("/health")
async def health_check():
    """Comprehensive health with degradation status"""
    
    health = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "2.0.0",
        "checks": {
            "core_database": await check_core_db(),
            "cache": await check_cache(),
            "external_api": await check_external_api(),
        }
    }
    
    # Determine overall status
    if all(c["status"] == "healthy" for c in health["checks"].values()):
        return {"status": "healthy", "http_code": 200}
    
    elif all(c["status"] in ["healthy", "degraded"] for c in health["checks"].values()):
        # Core services ok; some features degraded
        return {"status": "degraded", "http_code": 200}
    
    else:
        return {"status": "unhealthy", "http_code": 503}
```

---

### 9.3 Chaos Engineering for Resilience Testing

#### Controlled Failure Injection

```bash
#!/bin/bash
# chaos-test.sh - Verify system handles failures gracefully

set -e

NAMESPACE="production"
DEPLOYMENT="myapp"
CHAOS_DURATION=120  # 2 minutes

log() { echo "[$(date +'%H:%M:%S')] $@"; }

# Test 1: Pod Crash
log "Test 1: Simulating pod crash..."
kubectl delete pod -l "app=$DEPLOYMENT" -n "$NAMESPACE" --grace-period=0 &
CRASH_PID=$!

sleep 30
ERROR_RATE=$(get_current_error_rate)
if (( $(echo "$ERROR_RATE > 0.1" | bc -l) )); then
    log "⚠️  High error rate ($ERROR_RATE) during pod crash"
fi

wait $CRASH_PID 2>/dev/null || true

# Verify recovery
sleep 30
RECOVERED_ERROR_RATE=$(get_current_error_rate)
if (( $(echo "$RECOVERED_ERROR_RATE < 0.01" | bc -l) )); then
    log "✓ Recovery successful"
else
    log "❌ Recovery failed"
    exit 1
fi

# Test 2: Network Partition
log -e "\nTest 2: Simulating network partition..."
kubectl exec -it $(kubectl get pods -l "app=$DEPLOYMENT" \
    -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}') \
    -n "$NAMESPACE" -- \
    tc qdisc add dev eth0 root netem loss 100%  # 100% packet loss

sleep 30
PARTITION_ERROR_RATE=$(get_current_error_rate)

# Remove partition
kubectl exec -it $(kubectl get pods -l "app=$DEPLOYMENT" \
    -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}') \
    -n "$NAMESPACE" -- \
    tc qdisc del dev eth0 root

sleep 30
if (( $(echo "$PARTITION_ERROR_RATE > 0.05" | bc -l) )); then
    log "⚠️  Network partition caused errors: $PARTITION_ERROR_RATE"
fi

# Test 3: Resource Constraint
log -e "\nTest 3: Simulating resource pressure..."
kubectl set resources deployment/$DEPLOYMENT \
    --limits=memory=128Mi \
    -n "$NAMESPACE"

sleep 30
CONSTRAINT_ERROR_RATE=$(get_current_error_rate)

# Restore resources
kubectl set resources deployment/$DEPLOYMENT \
    --limits=memory=512Mi \
    -n "$NAMESPACE"

if [ "$CONSTRAINT_ERROR_RATE" != "0" ]; then
    log "⚠️  Resource constraint impact: $CONSTRAINT_ERROR_RATE error rate"
fi

# Test 4: Dependency Failure (External API)
log -e "\nTest 4: Simulating external API failure..."
kubectl set env deployment/$DEPLOYMENT \
    EXTERNAL_API_ENDPOINT=http://nonexistent.invalid \
    -n "$NAMESPACE"

kubectl rollout status deployment/$DEPLOYMENT -n "$NAMESPACE" --timeout=5m

sleep 30
FALLBACK_ERROR_RATE=$(get_current_error_rate)

# Restore endpoint
kubectl set env deployment/$DEPLOYMENT \
    EXTERNAL_API_ENDPOINT=https://api.external.com \
    -n "$NAMESPACE"

if (( $(echo "$FALLBACK_ERROR_RATE > 0.05" | bc -l) )); then
    log "❌ Service doesn't degrade gracefully on API failure"
    exit 1
else
    log "✓ Service handled API failure gracefully"
fi

log -e "\n✓ All chaos tests completed"
```

Using Chaos Mesh (Kubernetes-native):

```yaml
# chaos-mesh-experiments.yaml

apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: kill-random-pod
spec:
  action: kill
  mode: one
  selector:
    namespaces:
      - production
    labelSelectors:
      app: myapp
  duration: 2m
  scheduler:
    cron: "*/10 * * * *"  # Every 10 minutes

---
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-latency
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: myapp
  delay:
    latency: "100ms"
    jitter: "10ms"
  duration: 1m

---
apiVersion: chaos-mesh.org/v1alpha1
kind: IOChaos
metadata:
  name: disk-io-pressure
spec:
  action: latency
  mode: all
  selector:
    namespaces:
      - production
    labelSelectors:
      app: myapp
  duration: 5m
  value: "100ms"
```

---

### 9.4 Incident Response & Post-Mortems

#### Automated Incident Creation & Tracking

```bash
#!/bin/bash
# incident-automation.sh

SEVERITY=$1      # critical, high, medium
SERVICE=$2       # myapp, database, cache, etc.
ISSUE=$3         # Brief description

create_incident() {
    local ticket_id=$(jira create \
        --project INCIDENT \
        --type Incident \
        --priority "$SEVERITY" \
        --summary "[$SERVICE] $ISSUE" \
        --description "Automated incident for $SERVICE: $ISSUE" \
        | jq -r '.key')
    
    echo "$ticket_id"
}

create_runbook() {
    local ticket_id=$1
    local service=$2
    
    case $service in
        database)
            echo "RUNBOOK: Database Issue
1. Check connection pool: SELECT COUNT(*) FROM information_schema.PROCESSLIST
2. Identify long queries: SELECT * FROM information_schema.PROCESSLIST WHERE TIME > 300
3. Restart connection pool: /opt/db/restart-pool.sh
4. Monitor recovery: watch 'mysql -e SELECT COUNT(*)'
5. If not resolved: Failover to replica"
            ;;
        cache)
            echo "RUNBOOK: Cache Issue
1. Check Redis health: redis-cli ping
2. Check memory: redis-cli info memory
3. Clear cache if needed: redis-cli FLUSHALL
4. Restart service: kubectl rollout restart deployment/cache
5. Backfill cache: python /scripts/cache-warmup.py"
            ;;
        *)
            echo "See standard runbook: /docs/runbooks/$service.md"
            ;;
    esac
}

escalate_if_needed() {
    local severity=$1
    
    case $severity in
        critical)
            pagerduty trigger --service-key KEY \
                --description "CRITICAL incident detected"
            slack_notify "#critical-incidents" \
                "🚨 CRITICAL: Check Jira for details"
            ;;
        high)
            slack_notify "#incidents" \
                "🔴 HIGH priority incident created"
            ;;
        *)
            echo "Notification sent to #on-call"
            ;;
    esac
}

main() {
    TICKET=$(create_incident)
    echo "Created incident: $TICKET"
    
    create_runbook "$TICKET" "$SERVICE" | jq -R -s '.' | \
        xargs -I {} jira update "$TICKET" --body '{}'
    
    escalate_if_needed "$SEVERITY"
    
    echo "Incident ready for response: $TICKET"
}

main
```

**Post-Mortem Template:**

```markdown
# Post-Mortem: [Incident Title]

**Date:** [Date]  
**Duration:** [Start Time] - [End Time] (X hours)  
**Impact:** Users affected: [number], Revenue impact: $[amount], Services: [list]

## Executive Summary
Brief 1-2 sentence overview of what happened

## Timeline

| Time | Event |
|------|-------|
| HH:MM | Issue started |
| HH:MM | Alert fired (detection latency: X min) |
| HH:MM | On-call engineer notified |
| HH:MM | Root cause identified |
| HH:MM | Mitigation applied |
| HH:MM | Service recovered |

## Root Cause Analysis

### What Happened
[Detailed technical explanation]

### Why It Happened
[Root factor - not surface symptom]

### Why We Didn't Catch It
[Prevention/detection gaps]

## Who / What
- **Trigger:** [What initiated the issue]
- **System(s) Affected:** [Services]
- **Contributors:** [What systems/configs combined to cause issue]

## Resolution
- **Immediate Mitigation:** [What fixed the immediate issue]
- **Permanent Fix:** [Long-term solution PR/ticket]
- **Testing:** [How to prevent recurrence]

## Preventive Actions (Action Items)

| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Implement circuit breaker for X service] | [Name] | [Date] | Open |
| [Add monitoring alert for Y metric] | [Name] | [Date] | Open |
| [Update runbook for Z failure] | [Name] | [Date] | Open |

## Lessons Learned

### What Went Well
- Alert fired quickly
- Team communicated effectively
- Rollback procedure worked

### What Could Be Better
- Monitoring detects  issue  5 min earlier
- Documentation was incomplete
- Debugging tools could be more accessible

## Follow-Up
- [ ] Review follow-up actions [deadline]
- [ ] Update runbook
- [ ] Train team on prevention
- [ ] Verify fix in staging
```

---

## Hands-On Scenarios

### Scenario 1: Emergency Secret Rotation & Incident Recovery

**Problem Statement:**
A developer accidentally commits an AWS access key to a public GitHub repository. Within 5 minutes, the key is discovered by internal security scanning. You're on-call and need to:
1. Immediately revoke the compromised key
2. Ensure all services smoothly transition to new credentials
3. Prevent similar incidents in the future
4. Provide audit trail for compliance

**Architecture Context:**
- 15 microservices across 3 environments (dev/staging/prod)
- Services use AWS Secrets Manager with automatic rotation (30-day cycle)
- Credentials cached locally for 5 minutes to reduce API calls
- 200 EC2 instances + 50 ECS tasks using credentials
- Kubernetes cluster with 8 namespaces monitoring secret changes

**Step-by-Step Resolution (30 minutes target):**

```bash
#!/bin/bash
# emergency-credential-rotation.sh

set -e
LOG_FILE="/var/log/incident-$(date +%s).log"
INCIDENT_START=$(date -u +'%Y-%m-%d %H:%M:%S UTC')

log() {
    echo "[$(date +'%H:%M:%S')] $@" | tee -a "$LOG_FILE"
}

alert_team() {
    local msg=$1
    curl -X POST https://hooks.slack.com/services/... \
        -d "{\"text\": \"🚨 SECURITY INCIDENT: $msg\"}"
}

# PHASE 1: Immediate containment (2 minutes)
log "=== PHASE 1: IMMEDIATE CONTAINMENT ==="

alert_team "AWS access key exposed in GitHub - initiating emergency rotation"

# Step 1: Revoke all sessions using old key
aws iam put-user-policy --user-name ci-system \
    --policy-name DenyAllActions \
    --policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*"
        }]
    }'
log "✓ Blocked all access from compromised key"

# Step 2: Create new access key immediately
NEW_KEY=$(aws iam create-access-key --user-name ci-system \
    | jq -r '.AccessKey | "\(.AccessKeyId):\(.SecretAccessKey)"')
log "✓ Created new access key: $(echo $NEW_KEY | cut -d: -f1)"

# Store in Secrets Manager
aws secretsmanager update-secret \
    --secret-id prod/ci-system-credentials \
    --secret-string "{\"access_key\": \"$(echo $NEW_KEY | cut -d: -f1)\", \"secret_key\": \"$(echo $NEW_KEY | cut -d: -f2)\"}"
log "✓ Updated Secrets Manager with new credentials"

# PHASE 2: Service rotation (5 minutes)
log -e "\n=== PHASE 2: SERVICE ROTATION ==="

SERVICES=$(kubectl get secrets -A -o json | \
    jq -r '.items[] | select(.data.AWS_ACCESS_KEY_ID | @base64d | contains("AKIAIOSFODNN7EXAMPLE")) | .metadata.namespace' | \
    sort -u)

log "Services using compromised key: $SERVICES"

for NAMESPACE in $SERVICES; do
    log "Rotating credentials in namespace: $NAMESPACE"
    
    kubectl patch secret ci-credentials -n "$NAMESPACE" \
        -p '{"metadata":{"annotations":{"rotation-timestamp":"'$(date -u +'%Y-%m-%dT%H:%M:%SZ')'"}}}'
    
    kubectl rollout restart deployment -n "$NAMESPACE" --all
    kubectl wait --for=condition=available \
        --timeout=300s \
        deployment -n "$NAMESPACE" --all
done

# PHASE 3: Verification (3 minutes)
log -e "\n=== PHASE 3: VERIFICATION ==="

FAILURES=0
for NAMESPACE in $SERVICES; do
    PODS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
    
    for POD in $PODS; do
        TEST=$(kubectl exec $POD -n "$NAMESPACE" -- \
            aws sts get-caller-identity 2>&1)
        
        if echo "$TEST" | grep -q "AKIA"; then
            log "✓ $NAMESPACE/$POD: Successfully authenticated with new key"
        else
            log "❌ $NAMESPACE/$POD: AUTH FAILED - needs manual intervention"
            FAILURES=$((FAILURES + 1))
        fi
    done
done

if [ $FAILURES -gt 0 ]; then
    log "WARNING: $FAILURES pods failed to authenticate - escalating"
    alert_team "ERROR: $FAILURES services failed rotation - manual intervention needed"
    exit 1
fi

# PHASE 4: Cleanup & audit (5 minutes)
log -e "\n=== PHASE 4: CLEANUP & AUDIT ==="

sleep 300
OLD_KEY_ID=$(aws iam list-access-keys --user-name ci-system | \
    jq -r '.AccessKeyMetadata[] | select(.Status=="Active") | .AccessKeyId' | \
    head -1)

aws iam delete-access-key --user-name ci-system --access-key-id "$OLD_KEY_ID"
log "✓ Deleted compromised access key: $OLD_KEY_ID"

log "=== INCIDENT RESOLVED ==="
```

**Best Practices Applied:**
- ✓ Immediate containment (deny all, don't wait for rotation)
- ✓ Parallel rather than sequential service updates
- ✓ Verification after each phase with automated escalation
- ✓ Comprehensive audit trail and post-incident report

---

### Scenario 2: Production Outage - Cascading Failures & Recovery

**Problem Statement:**
A deployment at 3 PM triggers a cascade of failures. New code has a memory leak that's slow at first. After 30 minutes, memory usage reaches limits and pods OOMKill. The load balancer removes them, overloading remaining replicas. HPA scales up with more leaking containers. You must restore service within 30 minutes.

**Architecture Context:**
- 10 pod replicas (HPA min=5, max=20) with memory limit 512MB
- Readiness probe only checks database, not memory
- No startup probe configured
- Canary deployment hadn't completed (10% traffic only)
- P99 latency SLO: 500ms (spiking to 5s)

**Emergency Response:**

```bash
#!/bin/bash
# cascade-failure-recovery.sh

set -e
NAMESPACE="production"
DEPLOYMENT="payment-service"
ALERT_TIME="15:31:00"

log() { echo "[$(date +'%H:%M:%S')] $@"; }

# STEP 1: Immediate triage (30 seconds)
log "=== STEP 1: TRIAGE ==="

ERROR_RATE=$(kubectl exec prometheus -- \
    promtool query instant 'rate(http_requests_total{status=~"5.."}[1m])' | \
    grep -oP '\d+\.\d+' | head -1)

MEMORY_UTIL=$(kubectl top pods -n "$NAMESPACE" --no-headers | \
    awk '{sum+=$2; count++} END {print sum/count}')

log "Current state: Error=${ERROR_RATE}%, Memory=${MEMORY_UTIL}%"

# DIAGNOSIS: Cascading memory exhaustion pattern
if (( $(echo "$ERROR_RATE > 5" | bc -l) )) && [ "$MEMORY_UTIL" == "100" ]; then
    log "DIAGNOSIS: Cascading memory exhaustion"
fi

# STEP 2: Immediate rollback (60 seconds)
log -e "\n=== STEP 2: IMMEDIATE ROLLBACK ==="

kubectl rollout undo deployment/$DEPLOYMENT -n "$NAMESPACE" --record=true
kubectl rollout status deployment/$DEPLOYMENT -n "$NAMESPACE" --timeout=5m
log "✓ Rollback completed"

# STEP 3: Stabilization (60 seconds)
log -e "\n=== STEP 3: STABILIZATION ==="

for i in {1..30}; do
    NEW_ERROR_RATE=$(kubectl exec prometheus -- \
        promtool query instant 'rate(http_requests_total{status=~"5.."}[1m])' | \
        grep -oP '\d+\.\d+' | head -1)
    
    if (( $(echo "$NEW_ERROR_RATE < 0.5" | bc -l) )); then
        log "✓ Metrics normalized"
        break
    fi
    
    log "  Waiting... (error: ${NEW_ERROR_RATE}%)"
    sleep 2
done

# STEP 4: Prevent HPA cascade (30 seconds)
log -e "\n=== STEP 4: HPA PROTECTION ==="

kubectl autoscale deployment $DEPLOYMENT \
    --min=5 --max=5 \
    -n "$NAMESPACE" \
    --overwrite

log "✓ Fixed replica count to 5 (prevents cascade)"

# STEP 5: Verification & fixes
log -e "\n=== STEP 5: FIXES ==="

# Update readiness probe to check memory
kubectl patch deployment $DEPLOYMENT -n "$NAMESPACE" \
    --type merge --patch '{
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "'$DEPLOYMENT'",
                        "readinessProbe": {
                            "httpGet": {
                                "path": "/health/ready",
                                "port": 8080
                            },
                            "periodSeconds": 5,
                            "failureThreshold": 2
                        },
                        "startupProbe": {
                            "httpGet": {
                                "path": "/health/startup",
                                "port": 8080
                            },
                            "failureThreshold": 30,
                            "periodSeconds": 10
                        }
                    }]
                }
            }
        }
    }'

log "✓ Updated health checks and startup probe"
log "=== INCIDENT COMPLETE ==="
```

**Best Practices Demonstrated:**
- ✓ Immediate rollback over troubleshooting
- ✓ Triage to understand failure type
- ✓ Prevention of cascading failures (HPA limiter)
- ✓ Automated preventive measures

---

### Scenario 3: Multi-Region GitOps Deployment Synchronization

**Problem Statement:**
Deploy a payment service to 3 regions simultaneously using GitOps (ArgoCD):
- US-East: Primary (10 replicas)
- EU-West: Secondary (5 replicas)
- APAC-SG: Tertiary (3 replicas)

Requirements: Database migrations coordinated, secrets rotated per region, health checks must pass before promotion.

**Implementation:**

```bash
#!/bin/bash
# multi-region-gitops-deployment.sh

set -e

REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")
GIT_REPO="https://github.com/myorg/app-deployment"
IMAGE_TAG="v2.3.0"
SYNC_TIMEOUT=600

log() { echo "[$(date +'%H:%M:%S')] [$1] $2"; }

# PHASE 1: Pre-deployment validation
log "GLOBAL" "=== PHASE 1: VALIDATION ==="

for REGION in "${REGIONS[@]}"; do
    log "$REGION" "Validating cluster connectivity..."
    
    kubectl config use-context "argocd-$REGION"
    
    ARGOCD_HEALTH=$(kubectl get pod -n argocd \
        -l app=argocd-server \
        -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
    
    [ "$ARGOCD_HEALTH" == "True" ] || \
        { log "$REGION" "❌ ArgoCD not healthy"; exit 1; }
    
    log "$REGION" "✓ Vault and ArgoCD accessible"
done

# PHASE 2: Update Git repository
log "GLOBAL" -e "\n=== PHASE 2: GIT UPDATE ==="

git clone "$GIT_REPO" /tmp/app-deployment
cd /tmp/app-deployment

BRANCH="deploy/payment-v2.3.0-$(date +%s)"
git checkout -b "$BRANCH"

for REGION in "${REGIONS[@]}"; do
    OVERLAY_PATH="overlays/$REGION/kustomization.yaml"
    sed -i "s/newTag: .*/newTag: $IMAGE_TAG/g" "$OVERLAY_PATH"
    git add "$OVERLAY_PATH"
done

git commit -m "Deploy payment-service $IMAGE_TAG to all regions"
git push origin "$BRANCH"
log "GLOBAL" "✓ Git branch pushed: $BRANCH"

# PHASE 3: Staged deployment
log "GLOBAL" -e "\n=== PHASE 3: STAGED DEPLOYMENT ==="

PRIMARY_REGION="us-east-1"
kubectl config use-context "argocd-$PRIMARY_REGION"

argocd app create payment-service-$PRIMARY_REGION \
    --repo "$GIT_REPO" \
    --path "overlays/$PRIMARY_REGION" \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace payment \
    --revision "$BRANCH" \
    2>/dev/null || true

argocd app sync payment-service-$PRIMARY_REGION --async

SYNC_START=$(date +%s)
while true; do
    HEALTH=$(argocd app get payment-service-$PRIMARY_REGION \
        -o json | jq -r '.status.operationState.phase')
    
    [ "$HEALTH" == "Succeeded" ] && break
    [ "$HEALTH" == "Failed" ] && { log "$PRIMARY_REGION" "❌ Sync failed"; exit 1; }
    [ $(($(date +%s) - SYNC_START)) -gt $SYNC_TIMEOUT ] && { log "$PRIMARY_REGION" "❌ Timeout"; exit 1; }
    
    sleep 5
done

log "$PRIMARY_REGION" "✓ Deployment complete"

# PHASE 4: Secondary regions
log "GLOBAL" -e "\n=== PHASE 4: SECONDARY REGIONS ==="

sleep 120  # Wait for primary stability

for REGION in "${REGIONS[@]}"; do
    [ "$REGION" == "$PRIMARY_REGION" ] && continue
    
    log "$REGION" "Starting deployment..."
    kubectl config use-context "argocd-$REGION"
    
    argocd app sync "payment-service-$REGION" --async
    
    SYNC_START=$(date +%s)
    while true; do
        HEALTH=$(argocd app get "payment-service-$REGION" \
            -o json | jq -r '.status.operationState.phase')
        [ "$HEALTH" == "Succeeded" ] && break
        [ $(($(date +%s) - SYNC_START)) -gt $SYNC_TIMEOUT ] && exit 1
        sleep 5
    done
    
    log "$REGION" "✓ Deployment complete"
done

# PHASE 5: Finalize
git checkout main
git merge "$BRANCH" --no-ff -m "Deploy payment-service $IMAGE_TAG to all regions [COMPLETED]"
git push origin main

log "GLOBAL" "✓ Multi-region deployment complete and merged"
```

**Best Practices Demonstrated:**
- ✓ Staged deployment (primary before secondary)
- ✓ Region-specific health checks
- ✓ Git as audit trail
- ✓ Timeout protection against hanging deployments

---

### Scenario 4: Production Performance Crisis - Latency Optimization

**Problem Statement:**
P99 latency spike from 100ms to 2000ms during peak hours. Users report checkout timeouts (critical path). Goal: Identify bottleneck and reduce latency below 500ms within 45 minutes.

**Layer-by-Layer Diagnosis:**

```bash
#!/bin/bash
# latency-crisis-diagnosis.sh

NAMESPACE="production"
LATENCY_THRESHOLD=500

log() { echo "[$(date +'%H:%M:%S')] $@"; }

# STEP 1: Latency attribution (5 min)
log "=== Step 1: Latency Attribution ==="

for ENDPOINT in "checkout" "payment-processor" "fraud-check" "database"; do
    LATENCY=$(kubectl exec prometheus-0 -- \
        promtool query instant "histogram_quantile(0.99, request_duration{endpoint=\"$ENDPOINT\"})" | \
        grep -oP '\d+')
    log "  $ENDPOINT: ${LATENCY}ms"
done

# STEP 2: Distributed tracing (5 min)
log -e "\n=== Step 2: Request Trace Analysis ==="

SLOW_TRACES=$(kubectl exec jaeger-query-0 -- \
    curl http://localhost:16686/api/traces?service=checkout&minDuration=1000ms)

log "Most time spent in: $(echo "$SLOW_TRACES" | jq -r '.data[0].spans | group_by(.operationName) | sort_by(length) | reverse | .[0][0].operationName')"

# STEP 3: Database query analysis (10 min)
log -e "\n=== Step 3: Database Performance ==="

SLOW_QUERIES=$(kubectl exec postgres-primary -- \
    psql -U admin -c "
        SELECT query, mean_exec_time 
        FROM pg_stat_statements 
        WHERE mean_exec_time > 100
        ORDER BY mean_exec_time DESC LIMIT 5;" \
    -t -A -F'|')

while IFS='|' read -r query exec_time; do
    log "  Slow: $query (${exec_time}ms)"
done < <(echo "$SLOW_QUERIES")

# DIAGNOSIS
log -e "\n=== DIAGNOSIS ==="
log "Primary: Database queries (55% of request time)"
log "Secondary: Network latency to fraud-check (30%)"
log "Tertiary: Cache misses on fraud rules (N+1 queries)"

# OPTIMIZATION
log -e "\n=== OPTIMIZATION ==="

# Add missing index
kubectl exec postgres-primary -- psql -U admin -c \
    "CREATE INDEX CONCURRENTLY idx_payments_status_user_id 
     ON payments(status, user_id) WHERE status='pending';"
log "✓ Created database index"

# Warm cache
kubectl run cache-warmup --rm -it \
    --image=python:3.11 \
    --command -- python3 << 'PYTHON'
import redis
import requests

r = redis.Redis(host='redis-cache', port=6379, db=0)
rules = requests.get('http://fraud-service/api/rules').json()
for rule in rules:
    r.set(f"fraud_rule:{rule['id']}", rule, ex=3600)
print(f"Cached {len(rules)} fraud rules")
PYTHON

log "✓ Cache warmed with fraud rules"

# Monitor recovery
for i in {1..60}; do
    NEW_LATENCY=$(kubectl exec prometheus-0 -- \
        promtool query instant 'histogram_quantile(0.99, request_duration)' | \
        grep -oP '\d+')
    
    if [ "$NEW_LATENCY" -lt "$LATENCY_THRESHOLD" ]; then
        log "✓ Latency recovered to ${NEW_LATENCY}ms"
        break
    fi
    
    sleep 10
done
```

**Performance Results:**
- Index creation: -40% query time
- Cache warming: -30% fraud check latency
- Total: P99 reduced from 2000ms → 350ms ✓

---

## Interview Questions for Senior DevOps Engineers

### Category 1: Secret Management

1. **Compare Docker Secrets vs. Vault vs. AWS Secrets Manager for a production environment with 200+ microservices spread across AWS, GCP, and on-premises. Include cost, operational overhead, and security considerations.**

2. **Design a secrets rotation strategy for database credentials that minimizes blast radius, supports zero-downtime updates, and provides complete audit trails for SOC 2 Type II compliance.**

3. **You discover a database password used by your entire platform has been exposed in a public GitHub repository. Walk through your emergency response in the next 2 hours, including immediate mitigation, investigation, and long-term prevention.**

4. **How would you handle a scenario where different microservices need different levels of access to shared services, and show how you'd implement this with Vault and IAM policies?**

5. **Explain the tradeoffs between static secrets (rotated quarterly) vs. dynamic secrets (1-hour TTL) in a regulated financial institution. Include performance, compliance, and operational complexity.**

### Category 2: Build Automation

6. **A team reports their Docker build time has degraded from 5 minutes to 18 minutes over the past month. Walk through your diagnostic approach and optimization strategy, including how you'd measure cache effectiveness.**

7. **Design a multi-stage Dockerfile for a Node.js microservice that optimizes for: (a) image size, (b) build cache hit rate, (c) security scanning, and (d) startup time. Explain each decision.**

8. **How would you implement a build pipeline that supports building the same codebase for multiple platforms (x86-64, ARM64, RISC-V) while optimizing build time? Include registry caching strategy.**

9. **A critical vulnerability (CVE-2025-XXXXX) is discovered in a base image. Your platform has 5,000+ images cached in registries. Design a strategy to rebuild, scan, and redeploy efficiently.**

10. **Explain how you'd prevent secrets from accidentally being baked into Docker images during the build process. Include both technical controls and process safeguards.**

### Category 3: CICD Pipelines

11. **Design a CICD pipeline for a financial services application that must support: 50+ deployments per day, <5 minute feedback loop, multiple AWS regions, and full audit trail. Include failure handling.**

12. **Your CICD pipeline occasionally fails randomly with "connection timeout" errors during the scan phase. How would you troubleshoot this, and what would you implement to prevent it?**

13. **A team wants to migrate from daily batch deployments to continuous deployments. What testing strategy, infrastructure changes, and monitoring would you recommend?**

14. **How would you design a "split-brained" deployment system where developers can safely test production-like scenarios without affecting live traffic, including database access and third-party APIs?**

### Category 4: Deployment Patterns

15. **For a payment processing service, compare blue-green vs. canary vs. rolling deployments. For each one, explain when you'd choose it and what would cause a rollback.**

16. **Design a deployment strategy for an API that must achieve: zero downtime, database schema migrations across versions, and sub-second rollback capability. What constraints does this impose?**

17. **A canary deployment shows a 2% error rate increase over the baseline. Is this enough to trigger rollback? How would you make this decision programmatically?**

18. **How would you implement A/B testing for an experiment running on 10% of users that lasts 2 weeks, with the ability to split metrics by user segment, geography, and browser type?**

### Category 5: Failure & Observability

19. **You receive a p99 latency alert at 3 AM showing latency spiking from 50ms to 500ms on your order service. Walk through your troubleshooting approach and how you'd prevent this in the future.**

20. **Design a comprehensive health check strategy for a microservice architecture with 20+ services. What would you check and how would you decide between readiness/liveness/startup probes?**

21. **A service is in a CrashLoopBackOff state during peak traffic. Standard debugging is failing because the container doesn't stay up long enough. How would you debug this?**

22. **How would you detect and remediate a slow memory leak in production that takes 48 hours to cause OOMKilled? Include monitoring, alerting, and automated recovery.**

23. **Your service mesh (Istio) is intercepting traffic with 10ms latency overhead per request. For a high-frequency trading platform, this is unacceptable. How would you optimize or redesign?**

### Category 6: Real-World Scenarios

24. **Walk through how you'd handle a scenario where: (1) you deploy a bad version to production, (2) the automated rollback fails, and (3) manual rollback also fails. What's your escalation procedure and prevention strategy?**

25. **Design a complete cost optimization strategy for a Docker-based platform running 200+ production services, including image size, registry storage, artifact caching, and log retention.**

26. **You're asked to implement "immutable infrastructure" for a regulated healthcare provider. What does this mean, how does Docker fit, and what are the operational implications?**

27. **How would you implement network encryption (mTLS) for all inter-service communication in a Kubernetes cluster with 100+ microservices without downtime?**

28. **Design a disaster recovery strategy for your Docker registry that recovers from: (a) image corruption, (b) registry compromise, (c) regional data center failure, and (d) human error deletion.**

---

### Additional Advanced Questions (29-45)

29. **You need to reduce MTTR (Mean Time To Recovery) from 30 minutes to 5 minutes for your platform. What architectural, procedural, and tooling changes would you implement? Provide specific metrics and monitoring strategies.**

**Expected Answer:**
- Architectural: Circuit breakers, feature flags, redundancy, multi-region failover (< 1 min autonomous detection)
- Automation: Self-healing (pod restarts, HPA scale-up), automated rollback triggers (error rate > 5% + latency > 2s)
- Observability: Distributed tracing for rapid root cause analysis, custom metrics for business-critical flows
- Process: Runbooks automated 95%, escalation paths pre-defined, incident post-mortems within 24 hours
- Tools: Chaos engineering for failure injection testing, auto-remediation with PagerDuty integration
- Real example: Payment system recovers from pod crash in 45 seconds through kebelet auto-restart + readiness probe + health check feedback loop

---

30. **Design a secrets management system for a multi-cloud platform (AWS + GCP + on-premises Kubernetes) with different compliance requirements per region (SOC 2, HIPAA, GDPR, PCI-DSS). How would you minimize operational complexity while maintaining security?**

**Expected Answer:**
- Abstract layer: Unified interface hiding backend differences (use External Secrets Operator in K8s, AWS Secrets Manager SDK for Lambda)
- Region-specific: Vault for on-prem + managed secrets (AWS Secrets Manager, GCP Secret Manager) with cross-cloud sync policies
- Compliance mapping: Automated policy validation (secrets not logged, audit trails immutable, encryption-at-rest verified)
- Example: Data residency: Never copy HIPAA secrets to non-HIPAA regions; GDPR: European data processed only in EU regions
- Challenge: Prevent accidental cross-region leaks (policy-as-code validation, automated testing of region isolation)

---

31. **Your organization has 5,000+ Docker images in production. A critical vulnerability (CVE-2025-12345) is discovered in OpenSSL base image used by 40% of images. Design an end-to-end remediation process that identifies affected images, rebuilds them, rescans for new vulnerabilities, manages dependencies, handles breaking changes, and deploys to production within 48 hours while maintaining service continuity.**

**Expected Answer:**
- Identification: Query image metadata (Syft SBOM) in registry → identify 2,000 affected images + transitive dependencies
- Grouping: Categorize by criticality (payment → tier-1, analytics → tier-3) to optimize deployment order
- Rebuild: Parallel rebuild (max 50 concurrent jobs) with dependency resolution (Maven, npm, pip tree walk)
- Rescan: Trivy + SBOM re-generation → compare against baseline (expected new CVE list)
- Testing: Automated smoke tests (10% sample per tier before full rollout)
- Deployment: Canary per tier (5% → 20% → 50% → 100%) with automatic rollback on error spike
- Documentation: Generate SBOM diffs to track what changed between old/new build

---

32. **Compare and contrast Docker Secrets (Swarm), Kubernetes Secrets, HashiCorp Vault, and AWS Secrets Manager for a SaaS platform that scales from 2 to 200+ microservices. Include operational burden, audit compliance, disaster recovery, and cost implications for each.**

**Expected Answer:**

| Aspect | Docker Secrets | K8s Secrets | Vault | AWS SecretsM |
|--------|---|---|---|---|
| **Scalability** | Limited to Swarm | K8s-native | Unlimited | Cloud-scale |
| **Encryption** | Raft + TLS | etcd encryption | Transit + rest | AWS KMS |
| **Rotation** | Manual | CronJob | Automatic | Lambda automation |
| **Multi-region** | No | Per cluster | Manual sync | Native |
| **Cost (100 svc)** | $200/mo (master) | $0 (K8s included) | $1000+ (HA) | $400+ (APIs) |
| **Compliance** | Limited trail | Limited trail | Full audit | CloudTrail |
| **Best fit** | Simple monoliths | K8s-only | Multi-region | AWS-native |

**Recommendation flow:** Start with K8s Secrets → outgrow auth → use Vault → mature → AWS SecretsM for operational simplicity

---

33. **Your payment processing service experiences 10% latency variance (p50: 50ms, p99: 500ms) during peak traffic. Walk through a complete observability strategy to isolate the root cause, including specific metrics, logging strategies, tracing, and tools.**

**Expected Answer:**
- Metrics: Histogram latency per endpoint/operation/client (RED method: Rate, Errors, Duration)
- Logs: Structured JSON with request ID correlation (trace all components from ingress → database)
- Tracing: Distributed tracing (Jaeger) showing span breakdown per service (e.g., auth: 5ms, fraud-check: 200ms, DB: 250ms)
- Deep dive: Flamegraph analysis for hotspots within single service (CPU/memory/lock contention)
- Root cause: Often database (slow query without index) or external service (fraud API p99 spike)
- Prevention: Continuous profiling (pprof), load testing, chaos injection of slow endpoints

---

34. **Design an end-to-end GitOps deployment system for a multi-team organization (5 teams, 30+ services, 3 environments) that enforces policy (image scanning, deployment approval, infrastructure compliance) while maintaining velocity. How would conflict resolution, secret management, and disaster recovery work?**

**Expected Answer:**
- Git structure: Monorepo (single source of truth) vs multi-repo (team autonomy) trade-off → recommendation: monorepo with RBAC
- Policy: Pre-commit hooks (lint, scan) + PR checks (approval, deployment gates) + post-sync checks (health verification)
- Secrets: External Secrets Operator syncs from vault to K8s secrets (not committed to git)
- Conflict: Teams edit different files (prometheus.yaml, app deployments) → PR review + test in staging
- Rollback: Git revert = automatic cluster restore (declarative advantage)
- Disaster: If git/cluster diverge → kubectl apply -f git (reconciliation enforces git state)
- Tools: ArgoCD (controller) + GitHub (repo) + Vault (secrets) + Sealed Secrets (git-committable encrypted values)

---

35. **Your organization wants to migrate from Docker Swarm (40+ services) to Kubernetes without downtime. Plan a 6-month transition including: identifying services, building K8s readiness, staged migration, networking changes, persistent state handling, and rollback procedures.**

**Expected Answer:**
- Phase 1 (Month 1): Audit Swarm services → categorize by complexity (stateless → stateful, monolith → microservice)
- Phase 2 (Month 2): K8s cluster setup + networking (pod CIDR isolation, load balancer config)
- Phase 3 (Months 3-4): Migrate stateless services (0 risk) in parallel to reduce blast radius
- Phase 4 (Months 4-5): Migrate stateful services (database, cache) with replication/backup
- Phase 5 (Month 6): Final cutover + monitoring, rollback capability maintained
- Mistakes to avoid: Don't migrate monoliths as-is (decompose first), don't decommission Swarm immediately (6-month fallback window)
- Rollback: Keep Swarm cluster running throughout, health checks detect failures, instant DNS switchback

---

36. **A security audit requires isolating payment service from batch processing. Currently they share the same cluster and Docker network. Design the isolation while maintaining performance and operational simplicity. Include networking, secrets, resource constraints, and compliance verification.**

**Expected Answer:**
- Network isolation: Kubernetes NetworkPolicy (payment namespace → only approved services)
- Resource isolation: Separate resource quotas per namespace (payment: high priority, batch: best-effort)
- Secrets isolation: Different secret stores per namespace (payment uses Vault, batch uses K8s secrets)
- Compute isolation: Dedicated node pools + taints (payment pods only run on secure nodes)
- Compliance: Audit logging enabled per namespace, network flows logged, secret access logged
- Testing: Penetration testing (verify batch cannot reach payment), chaos injection (network partition tolerance)

---

37. **Design a self-healing Kubernetes platform that automatically recovers from: pod crashes, node failures, network partitions, stuck deployments, and cascading failures. Include operator design, circuit breakers, timeout policies, and graceful degradation.**

**Expected Answer:**
- Pod crashes: Kubernetes native (liveness probe → restart)
- Node failures: DaemonSet ensures node agent health, auto-node-replacement via cluster-autoscaler
- Network partitions: Circuit breaker pattern (Go implementation), fallback caches, rate limiting
- Stuck deployments: Startup probe timeout → retry with exponential backoff, max retries before escalation
- Cascading failures: Bulkhead patterns (separate resources per component), feature flag to disable non-critical features
- Custom operator: Watches for degradation patterns → automatically applies remediation playbooks
- Example: Payment service detects fraud API timeout → circuit breaker opens → serves cached fraud rules → customer impact minimal

---

38. **Your organization processes sensitive financial data. Design a complete "zero-trust" Docker and Kubernetes security model from image build → runtime, including secrets, networking, compliance, and incident response.**

**Expected Answer:**
- Build: Signed base images (Cosign), container scanning (Trivy), build attestation logs (SLSA)
- Registry: Private (ECR/GCR), image signing verification, immutable tags, pull-through cache
- Runtime: Pod security policies (PSP) + network policies, mTLS for inter-service communication, RBAC per service
- Secrets: Never in environment variables (use Vault/SecretsManager), encryption-at-rest, encryption-in-transit
- Monitoring: Every API call to secrets manager logged + audited, network traffic encrypted/logged, container behavior monitored (Falco)
- Compliance: ISO 27001 controls mapped to technical controls, continuous compliance checking, automated remediation
- Incident: Breach detected → immediate pod isolation + network kill → investigation without data loss

---

39. **You're responsible for observability of 100+ microservices. Design a complete observability strategy including: metrics, logging, tracing, alerting, dashboards, and incident correlation. How would you balance breadth (all services) vs. depth (critical services)?**

**Expected Answer:**
- Metrics: Prometheus + Thanos (long-term storage). Export RED + USE metrics. Sample critical services comprehensively, others at 10% sampling
- Logging: Structured JSON, ELK stack with cost optimization (expensive log retention = 1 week, cheaper = 30 days archived)
- Tracing: Jaeger with 1-5% sampling ratio (100% for errors), trace context propagation across services
- Alerting: Alert on SLI/SLO breaches (error budget), not raw metrics (reduces alert fatigue)
- Dashboards: Service dashboards auto-generated from service discovery, custom dashboards for complex business flows
- Correlation: When alert fires → automatically correlate logs + traces + metrics by request ID
- Cost: Log sampling strategy reduces ELK cost 5x. Metric cardinality management prevents Prometheus explosion

---

40. **Design a FinTech compliance and audit system for Docker/Kubernetes workloads covering: PCI-DSS, SOC 2, GDPR. Include automated policy enforcement, continuous compliance checking, audit logging, and remediation.**

**Expected Answer:**
- PCI-DSS: Network segmentation (payment service on dedicated cluster), encryption in transit (mTLS), access logging (all API calls)
- SOC 2: Immutable audit logs (S3 with versioning), change tracking (git history), incident response with post-mortems
- GDPR: Data residency (EU data processed in EU K8s clusters), data deletion (PVC cleanup, secret rotation), user consent tracking
- Automation: Config policies validated on deployment (Kyverno/OPA), continuous compliance scanning (trivy, falco), auto-remediation
- Example: Payment service tries to read beyond its network policy → auto-violation → rollback deployment → alert security + incident creation
- Testing: Compliance rules automatically tested against all environments monthly

---

41. **A competitor's Docker image is available on Docker Hub. How would you ensure your team only uses approved base images and dependencies? What about supply chain security of the images themselves?**

**Expected Answer:**
- Approved base images: Maintain internal list → base image scanning with Trivy → whitelist hash only (immutable verification)
- Deployment gate: Registry webhook rejects images built on non-approved bases (OPA/Kyverno policy)
- Supply chain: Cosign signatures on base images (verify signed by trusted publisher), SBOM scanning (identify transitive dependencies)
- Dependency updates: Automated PRs when dependencies have vulnerabilities (Dependabot)
- Incident: If base image compromised → registry webhook rejects all dependent images automatically

---

42. **Design a disaster recovery strategy for a platform with 500+ Docker containers across 3 regions, where RTOs are 30 min (recovery time) and RPOs are 2 hours (data loss acceptable is 2 hours). Include backup strategy, failover automation, testing, and costs.**

**Expected Answer:**
- Backup: Container configs (K8s etcd backups every 15 minutes), persistent data (database replication + snapshots every 30 min)
- Failover: Active-active across regions (DNS failover < 1 min), multi-region Kubernetes ("kube-coredns" see across regions)
- Automation: Detect region failure via health check → automatically switch traffic to secondary region
- Testing: Monthly DR drills (actually failover to secondary to verify 30-min RTO is achievable)
- Costs: 3x compute (3 regions), 2x storage (backups), totaling 3-4x baseline vs. 60% uplift for active-active. Recommendation: Reserve instances per region for cost optimization
- Validation: After failover → automated smoke tests (payment flow, API response times) ensure service quality

---

43. **Your organization's Docker images are 500 MB on average. Licensing costs $200/month per GB of registry storage. Design an end-to-end image optimization strategy that reduces size 50-80% while maintaining feature parity.**

**Expected Answer:**
- Baseline: Multi-stage builds (reduce dev tools) → typical 300MB. Advanced: Alpine base images (reduce 50%), app-specific stripping (remove man pages, docs)
- Monorepo consolidation: 100 services with duplicate dependencies → shared base layers → 30% reduction
- Layer analysis: Use `docker history` to identify bloated layers, moving large artifacts to volumes (never in image)
- Scan: Trivy checks minimal base images, ensure no regressions from optimization
- Testing: Performance testing (startup time, memory footprint) to ensure optimizations don't break functionality
- Example: Java app 600MB → openjdk:21-slim (base) → jlink for custom runtime → 120MB. Savings: 80%, $160/month saved × 200 images = $32k/year

---

44. **Compare container runtimes (Docker, containerd, CRI-O, Kata, gVisor, Firecracker). For a multi-user SaaS platform with untrusted code, which would you choose and why? What are the trade-offs?**

**Expected Answer:**

| Runtime | Security | Performance | Isolation | Use Case |
|---------|----------|-------------|-----------|----------|
| Docker | Medium | High | OS-level | Standard workloads |
| containerd | Medium | High | OS-level | K8s default (minimal overhead) |
| CRI-O | High | High | OS-level | K8s alternative |
| Kata | Very High | Medium | VM-level | Untrusted code, multi-tenant |
| gVisor | Very High | Lower | Syscall filtering | Isolation without VM overhead |
| Firecracker | Very High | Very High | Lightweight VMs | Serverless (Lambda uses it) |

Recommendation for multi-user SaaS: gVisor (better than VM overhead, better security than containers) or Kata (hardware isolation but performance tolerant). Test both in staging first.

---

45. **You need to implement "GitOps 2.0" where developers push Dockerfile changes and infrastructure changes via unified pull requests. Design the tooling, validation, testing, and rollback strategy. How would you handle conflicts between app and infra teams?**

**Expected Answer:**
- Single repo: Dockerfile + K8s manifests + Helm charts in monorepo (single source of truth)
- PR workflow: App change → Dockerfile rebuild → push image → PR updates image tag in K8s manifest
- Automation: PR validation (Dockerfile lint, K8s yaml syntax, image scan) + staging deploy (test before merge)
- Conflict resolution: Different files by team (app/ and infra/ directories) → separate RBAC. Infra updates only deployments, not code
- Testing: Merged to main → auto-deploy to staging → health checks → auto-promote to production if passing canary
- Rollback: `git revert` the PR → cluster automatically reconciles to parent commit version
- Challenge: If infra team needs emergency config change (resource limit) → override deployment → diverge from git → scheduled reconciliation job to realign

---

## References & Further Reading

### Official Documentation
- Docker Official Documentation: https://docs.docker.com/
- Kubernetes Security: https://kubernetes.io/docs/concepts/security/
- HashiCorp Vault: https://www.vaultproject.io/docs/
- AWS Secrets Manager: https://docs.aws.amazon.com/secretsmanager/

### Tools & Projects
- BuildKit: https://github.com/moby/buildkit
- Trivy: https://github.com/aquasecurity/trivy
- Istio: https://istio.io/
- Flagger: https://flagger.app/
- External Secrets Operator: https://external-secrets.io/
- Cosign: https://docs.sigstore.dev/cosign/overview/

### Best Practices & Standards
- NIST Container Security: https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf
- CIS Docker Benchmark: https://www.cisecurity.org/benchmark/docker/
- OWASP Container Security Top 10: https://owasp.org/www-project-container-security/
- SLSA Framework: https://slsa.dev/

### Learning Resources
- "The Docker Book" by James Turnbull
- "Kubernetes in Action" by Marko Lukša
- "Security Engineering" by Ross Anderson
- Linux Academy Container Security Course

---

**Document Version:** 1.0  
**Last Updated:** March 7, 2026  
**Audience:** Senior DevOps Engineers (5-10+ years)  
**Total Content:** ~40,000 words  

This study guide is designed to be a comprehensive reference for mastering Docker secrets, CICD automation, production deployment patterns, and failure recovery in enterprise environments. Use the interview questions for self-assessment and preparation for senior-level technical interviews.

