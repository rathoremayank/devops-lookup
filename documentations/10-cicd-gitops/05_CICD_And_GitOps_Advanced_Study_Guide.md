# Senior DevOps Study Guide: CI/CD & GitOps
## Cost Optimization, Pipeline Security, Production Failures, Scaling, Best Practices, Tool Comparison, Legacy App Integration, and MLOps

---

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Topic](#overview-of-topic)
   - [Why It Matters in Modern DevOps](#why-it-matters-in-modern-devops)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Where It Appears in Cloud Architecture](#where-it-appears-in-cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices Framework](#best-practices-framework)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Cost Optimization in CI/CD Pipelines](#cost-optimization-in-cicd-pipelines)
   - [Optimizing Pipeline Efficiency](#optimizing-pipeline-efficiency)
   - [Resource Management Strategies](#resource-management-strategies)
   - [Cloud Cost Monitoring and Analysis](#cloud-cost-monitoring-and-analysis)
   - [Cost-Saving Strategies](#cost-saving-strategies)
   - [Serverless CI/CD Solutions](#serverless-cicd-solutions)

4. [Pipeline Security](#pipeline-security)
   - [Securing CI/CD Pipelines](#securing-cicd-pipelines)
   - [Secrets Management](#secrets-management)
   - [Access Control and Authentication](#access-control-and-authentication)
   - [Vulnerability Scanning and SAST/DAST](#vulnerability-scanning-and-sastdast)
   - [Secure Artifact Storage](#secure-artifact-storage)
   - [Compliance in Pipelines](#compliance-in-pipelines)

5. [Production Failures and Failure Analysis](#production-failures-and-failure-analysis)
   - [Common Causes of Production Failures](#common-causes-of-production-failures)
   - [Failure Case Studies](#failure-case-studies)
   - [Troubleshooting Strategies](#troubleshooting-strategies)
   - [Post-Mortem Analysis and Blameless Culture](#post-mortem-analysis-and-blameless-culture)
   - [Failure Prevention Best Practices](#failure-prevention-best-practices)

6. [Scaling CI/CD Pipelines](#scaling-cicd-pipelines)
   - [Challenges of Scaling CI/CD](#challenges-of-scaling-cicd)
   - [Scaling Strategies and Patterns](#scaling-strategies-and-patterns)
   - [Distributed CI/CD Architectures](#distributed-cicd-architectures)
   - [Cloud-Native CI/CD Solutions](#cloud-native-cicd-solutions)
   - [Performance Optimization for Large Teams](#performance-optimization-for-large-teams)

7. [GitOps Best Practices](#gitops-best-practices)
   - [Core GitOps Principles](#core-gitops-principles)
   - [Repository Structure and Organization](#repository-structure-and-organization)
   - [Branching Strategies](#branching-strategies)
   - [Deployment Strategies](#deployment-strategies)
   - [Monitoring, Alerting, and Observability](#monitoring-alerting-and-observability)
   - [Team Collaboration Patterns](#team-collaboration-patterns)

8. [GitOps Tools Comparison](#gitops-tools-comparison)
   - [Argo CD vs Flux vs Jenkins X](#argo-cd-vs-flux-vs-jenkins-x)
   - [Feature Comparison Matrix](#feature-comparison-matrix)
   - [Pros and Cons Analysis](#pros-and-cons-analysis)
   - [Use Case Suitability](#use-case-suitability)
   - [Community Support and Ecosystem](#community-support-and-ecosystem)

9. [GitOps for Legacy Applications](#gitops-for-legacy-applications)
   - [Applying GitOps to Legacy Systems](#applying-gitops-to-legacy-systems)
   - [Challenges and Solutions](#challenges-and-solutions)
   - [Refactoring Strategies](#refactoring-strategies)
   - [Integration with Existing CI/CD](#integration-with-existing-cicd)
   - [Case Studies](#case-studies)

10. [GitOps for MLOps](#gitops-for-mlops)
    - [GitOps in Machine Learning Operations](#gitops-in-machine-learning-operations)
    - [Managing ML Models with GitOps](#managing-ml-models-with-gitops)
    - [CI/CD for ML Workflows](#cicd-for-ml-workflows)
    - [MLOps-Specific Challenges](#mlops-specific-challenges)
    - [Case Studies and Best Practices](#case-studies-and-best-practices)

11. [Hands-On Scenarios](#hands-on-scenarios)

12. [Interview Questions for Senior DevOps Engineers](#interview-questions-for-senior-devops-engineers)

---

## Introduction

### Overview of Topic

CI/CD (Continuous Integration/Continuous Delivery) and GitOps represent the modern evolution of software deployment and infrastructure management. **CI/CD** automates the building, testing, and deployment of applications, reducing manual errors and accelerating release cycles. **GitOps** extends this paradigm by treating infrastructure and application configuration as code stored in Git repositories, with Git serving as the single source of truth.

This study guide addresses enterprise-scale concerns: optimizing costs in pipelines consuming significant cloud resources, securing complex deployment chains against increasingly sophisticated threats, handling production failures with resilience patterns, scaling systems across hundreds of deployments daily, and adapting these practices for specialized domains like legacy modernization and machine learning operations.

### Why It Matters in Modern DevOps

**Scale and Complexity**: Organizations deploying thousands of microservices across multiple cloud platforms require automated, repeatable, and verifiable deployment mechanisms. Manual deployment processes become infeasible at this scale.

**Business Continuity**: Production failures directly impact revenue, user experience, and brand reputation. CI/CD enables rapid remediation, while GitOps provides audit trails and rollback capabilities.

**Cost Efficiency**: Cloud resources are consumed during every build, test, and deployment cycle. Unoptimized pipelines waste thousands in infrastructure costs monthly. Senior engineers must understand cost-tracking, resource pooling, and serverless alternatives.

**Security Posture**: Supply chain attacks increasingly target build pipelines. Securing CI/CD has become as critical as application security. This includes secrets management, artifact integrity, and access controls.

**Velocity and Reliability Trade-off**: High-performing organizations achieve both rapid deployments AND low failure rates through sophisticated practice of CI/CD and GitOps. This is non-trivial and requires deep understanding of tradeoffs.

### Real-World Production Use Cases

**E-Commerce Platforms**: Deploy thousands of services across regions, handle traffic spikes (Black Friday), perform canary deployments to real traffic, detect anomalies within seconds, and rollback automatically. GitOps enables declarative infrastructure matching application versions.

**Financial Services**: Require audit trails for every deployment, compliance with regulatory frameworks (SOX, PCI), immutable audit logs in Git, approval workflows for production changes, and strict access controls. GitOps naturally provides Git-based auditability.

**SaaS Platforms**: Multi-tenant architectures require tenant-specific configurations, feature flags per deployment, costs tracked per customer. Cost optimization becomes a direct P&L concern. Pipeline security prevents competitor data access.

**Enterprise Cloud Migration**: Legacy monoliths transitioning to microservices require gradual GitOps adoption, integration with existing deployment tools, and risk mitigation for business-critical systems.

**Machine Learning Platforms**: Model versioning parallels code versioning. Data pipelines require reproducibility. Model deployment triggers retraining pipelines. GitOps provides the declarative framework for ML lifecycle management.

### Where It Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                        │
│  (Push code → PR → Review → Merge)                          │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │   Git Repository        │
        │   (Source of Truth)     │
        └────────────┬────────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
    ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  CI Pipeline │ │ GitOps Agent │ │ Policy as    │
│  (Build,     │ │ (Argo/Flux)  │ │ Code Engine  │
│   Test,      │ │              │ │ (OPA/Kyverno)
│   Package)   │ │ Watches Git  │ │              │
└──────┬───────┘ │ Applies Diffs│ └──────┬───────┘
       │         └──────────────┘        │
       │                                  │
       ├──────────────┬──────────────────┤
       │              │                  │
       ▼              ▼                  ▼
    ┌─────────┐  ┌──────────┐  ┌────────────────┐
    │Artifact │  │Kubernetes│  │Config/Policy  │
    │Registry │  │Cluster   │  │ Enforcement    │
    └─────────┘  └──────────┘  └────────────────┘
       │              │
       └──────┬───────┘
              ▼
       ┌────────────────┐
       │   Monitoring   │
       │   & Alerting   │
       │   (Feedback)   │
       └────────────────┘
```

CI/CD appears in the left pipeline (build and test stages). GitOps appears as the declarative synchronization layer ensuring cluster state matches Git truth. Both directly impact the deployed infrastructure and application behavior.

---

## Foundational Concepts

### Key Terminology

**Continuous Integration (CI)**
- Automated merging of code changes from multiple developers into a shared repository
- Immediate automated build and test of merged code
- Rapid feedback on integration issues
- Gatekeepers: linters, unit tests, integration tests block broken merges

**Continuous Delivery (CD)**
- Automated packaging and staging of validated code for production
- Manual approval gate before production deployment (differs from Continuous Deployment)
- Ensures code is "deployment-ready" at all times
- Focus on artifact quality and reproducibility

**Continuous Deployment**
- Automatic deployment to production without manual approval
- Every passing commit to main branch deploys to production
- Requires sophisticated monitoring and automated rollback
- Higher risk, higher velocity

**GitOps**
- Declarative infrastructure and application configuration stored in Git
- Git commit history as audit trail
- Automated synchronization (GitOps agent) ensures cluster state matches Git
- Pull vs Push models: Pull-based (preferred) has agents watching Git; Push-based has CI/CD triggering deployments

**Immutable Infrastructure**
- Infrastructure components are never modified after deployment
- Changes required rolling new versions, not patching in-place
- Enables reproducibility, easier rollback, cleaner testing
- Foundation for infrastructure-as-code practices

**Infrastructure as Code (IaC)**
- Infrastructure defined programmatically (Terraform, CloudFormation, Helm, etc.)
- Human-readable, version-controlled infrastructure definitions
- Enables repeatability, reduces configuration drift
- Crucial for GitOps

**Artifact Repository/Registry**
- Centralized storage for built outputs: container images, JARs, binaries, libraries
- Immutable once published (semantic versioning or content addressing)
- Supply chain security: scan images for vulnerabilities, verify signatures
- Examples: Docker Registry, ECR, GCR, Artifactory, Nexus

**Deployment Pipeline**
- Sequence of automated stages transforming source code to running services
- Typical stages: Build → Unit Test → SAST → Integration Test → DAST → Staging Deploy → Production Deploy
- Each stage has quality gates; failure blocks progression
- Provides feedback loop enabling rapid iteration

**Secrets Management**
- Secure handling of sensitive credentials outside version control
- Solutions: Kubernetes Secrets, AWS Secrets Manager, HashiCorp Vault, Azure Key Vault
- Injection at deployment time, rotation policies, audit logging
- Never commit to Git; never expose in logs

**Blast Radius**
- Scope of potential impact from a deployment failure
- Canary deployments reduce blast radius (1% traffic initially)
- Blue-green deployments enable instant rollback
- Feature flags enable gradual rollout without deployment

**Observability**
- Logs, Metrics, Traces (three pillars)
- Enables understanding of system behavior without pre-defining all questions
- Critical for detecting and responding to production failures
- Prerequisite for confident deployments

### Architecture Fundamentals

**Traditional Deployment Model (Pre-CI/CD)**
```
Developer → Manual Testing → Deploy Script → Production
```
Issues:
- Long feedback cycles (days/weeks)
- Manual error-prone steps
- Deployment anxiety (unpredictable outcomes)
- Difficult rollbacks
- Unclear what's running in production

**Modern CI/CD Model**
```
Developer → Git Push → Automated: Build/Test/Security Scan → Staging → Approval → Automated Deploy → Monitoring
```
Benefits:
- Minutes from commit to production
- Consistency through automation
- Comprehensive audit trail
- Rapid rollbacks via versioning
- Confidence through comprehensiveness

**GitOps Architecture (Pull-Based)**
```
Git Repository (Desired State) ← Monitored by GitOps Agent → Kubernetes Cluster ↔ Observability
                                                    ↑
                                          (Pulls every 30s)
                                          (Syncs drift)
```

Key distinction from traditional push-based CD:
- **Push Model**: CI/CD pipeline triggers deployment. Security risk: pipeline has cluster credentials
- **Pull Model**: GitOps agent in cluster watches Git. More secure: only Git credentials needed in pipeline

**Multi-Environment Architecture**
```
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  Dev Cluster │   │ Staging Clus │   │ Prod Cluster │
│  (Fast, $$)  │   │ (Test mirror)│   │  (HA, SLA)   │
└──────────────┘   └──────────────┘   └──────────────┘
       ↑                   ↑                   ↑
       └───────────────────┼───────────────────┘
                           │
                    Git Repository
                    (Single truth)
                    Different Git
                    branches/paths
                    per environment
```

### Important DevOps Principles

**1. Version Everything**
- Application code in Git (obvious)
- Infrastructure as code in Git
- Configuration as code in Git
- Container images with tags matching git commits
- Database schema versions
- Enable reproducibility, rollback, audit

**2. Automate the Repetitive**
- Every manual step is error-prone and doesn't scale
- Every repeated task should be a pipeline stage
- Test automation is prerequisite for velocity
- Static analysis (linting, SAST) catches issues faster than humans

**3. Fail Fast**
- Quick feedback loops enable rapid iteration
- Build artifacts quickly; fail fast on errors
- Unit tests run before integration tests before deployment
- Shift-left philosophy: catch issues as early as possible

**4. Immutability Over Mutation**
- Immutable artifacts: once built, never changed
- Poison-pill prevention: corrupted artifact requires new build, not patch
- Reproducibility: same code always produces same artifact
- Simplifies caching and distribution

**5. Progressive Delivery**
- Production deployments not binary (all-or-nothing)
- Canary: 5% traffic → 50% → 100%
- Blue-green: instant switchover/rollback
- Feature flags: decouple deployment from release
- Risk reduction through gradual validation

**6. Observability Driven**
- Can't improve what you don't measure
- Logs: what happened (events)
- Metrics: system state over time (trends, alerts)
- Traces: request flow across services
- Enable post-hoc analysis and alerting

**7. Security by Default**
- Secrets never in code or config
- Least privilege access (RBAC, service accounts)
- Supply chain validation (container image signatures)
- Vulnerability scanning in CI/CD
- Compliance as code

### Best Practices Framework

**Source Control Discipline**
- Single source of truth: all production configuration in Git
- No configuration drift: what's in Git matches what's running
- Branching strategy: commit to main = production-ready
- Pull request culture: peer review before merge
- Commit as documentation: clear messages enable debugging

**Testing Strategy Pyramid**
```
        /\
       /  \     Manual Testing
      /────\
     /Tests \  E2E/Integration Tests
    /────────\
   /Contracts \  Contract Tests
  /────────────\
 /Unit Testing  \  Unit Tests (>70% coverage)
/────────────────\
```

- Unit tests: Fast, comprehensive, catch logic errors
- Contract tests: Verify service interfaces
- Integration tests: Validate service interactions
- E2E tests: Selective, slow, high value
- Manual testing: Exploratory, edge cases, UX validation (humans better than automation)

**Release Engineering**
- Semantic versioning: MAJOR.MINOR.PATCH
- Artifact immutability: version tag tied to exact commit/content
- Release notes: what changed, why, migration steps
- Maintenance windows: planned deprecation, notice to users
- Rollback plan: always know how to revert

**Infrastructure Patterns**
- Immutable infrastructure: containers/AMIs, never SSH to prod
- Declarative configuration: Kubernetes manifests, Terraform, not imperative scripts
- GitOps synchronization: automated enforcement of Git state
- Policy as Code: Kyverno/OPA enforce organization standards
- Cost allocation tags: track spending per application/team/cost center

### Common Misunderstandings

**❌ Myth 1: "GitOps means we use Git"**
- **Reality**: GitOps is specific architecture pattern: Git as source of truth + automated synchronization
- Many teams use Git but not GitOps (push-based CI/CD is NOT GitOps)
- Pull-based synchronization is the critical distinction
- Just committing to Git doesn't provide declarative synchronization

**❌ Myth 2: "CI/CD means we deploy every commit"**
- **Reality**: CI/CD is a practice; Continuous Deployment is a specific strategy
- Continuous Delivery (manual production gate) is more common in enterprises
- Risk tolerance, change frequency, and business model determine deployment cadence
- High-frequency deployments require sophisticated monitoring and rollback

**❌ Myth 3: "Monorepo or polyrepo doesn't matter"**
- **Reality**: Profound architectural implications
- Monorepo: atomic deploys, easier refactoring, complex CI (coupling)
- Polyrepo: independent autonomy, simpler CI, complex orchestration
- Git submodules and Git subtrees are half-measures with substantial overhead
- Organizational structure (Conway's Law) should drive repository structure

**❌ Myth 4: "Immutable infrastructure eliminates state"**
- **Reality**: No! Stateless applications run on immutable infrastructure
- Databases, caches, configuration are still state
- Immut infra means state external to compute (database, object storage, config service)
- Simplifies infrastructure but requires better state management

**❌ Myth 5: "Secrets in `.gitignore` are safe"**
- **Reality**: High false confidence
- Git history persists; removing file doesn't erase from history
- Require: never commit (pre-commit hooks), external secret store, regular audits
- Assumes discipline across all team members; humans are unreliable

**❌ Myth 6: "GitOps agent constantly polling is inefficient"**
- **Reality**: Polling is surprisingly efficient
- 30-second interval with 1000 clusters = 33 requests/sec (trivial load on Git)
- Webhook model requires bidirectional connectivity (more complex)
- Polling provides reliability (if cluster restarts, sync resumes automatically)
- Common pattern: polling with webhook acceleration (fast sync on webhook, slow safety polling)

**❌ Myth 7: "Chaos engineering is for large companies"**
- **Reality**: Chaos testing surface incompleteness of observability
- Small blast radius failures from chaos testing save you from large blast radius production incidents
- Property-based testing (chaos) finds bugs that conventional testing misses
- Cost of learning from production failures >> cost of chaos experiments

**❌ Myth 8: "Rollbacks are always safe"**
- **Reality**: Rollbacks are NOT risk-free
- Database migrations can't always rollback (data loss scenario)
- Canary deployments more common than full rollbacks
- Rollback procedure requires testing (exercise rollback path regularly)
- Some failures require forward fixes, not rollbacks (e.g., data corruption)

---

## Cost Optimization in CI/CD Pipelines

### Optimizing Pipeline Efficiency

**Resource Utilization Analysis**

Pipeline stages consume cloud resources proportional to duration and compute requirements. A 30-minute full test suite executed by 100 developers weekly = 50 hours of compute weekly = significant infrastructure cost.

**Parallelization**
- Unit tests: embarrassingly parallel; split across test runners
- Integration tests: often sequential (database setup/teardown); batch for efficiency
- Building multiple artifacts: independent builds run in parallel
- Matrix strategies: test across Python 3.8, 3.9, 3.10 simultaneously

**Caching Strategies**
- **Dependency caching**: ~/.m2 (Maven), ~/.npm (NPM), vendor/ directory
  - Layer caches in Docker images (separate layers for dependencies vs code)
  - Cache hit reduces build from 5min to 30sec
  - Trade-off: stale cache vs cache invalidation complexity
- **Build artifact caching**: compiled binaries enable faster downstream stages
- **Docker layer caching**: unchanged base layers cached; reduces rebuild times
- Implementation: Most CI/CD platforms provide built-in caching

Cost benefit example:
```
Without caching: 10 builds/day × 5 minutes = 50 minutes/day
With caching (80% hit rate): 10 builds @ (1 min cache miss + 0.5 min cache hit avg) = 7 min/day
Savings: 43 minutes compute/day = 10+ hours/month per developer
```

**Pruning Unnecessary Steps**

Common waste:
- Running full test suite for documentation-only changes (lint/format, not logic)
- Building all artifacts for branches that won't deploy
- Expensive security scans (DAST) for non-production environments
- Running tests sequentially when independence allows parallel execution

Optimization: Conditional execution based on changed files
```yaml
# GitLab CI example
test:unit:
  script: npm test
  only:
    changes:
      - src/**/*.js
      - test/**/*.js

build:docs:
  script: npm run build:docs
  only:
    changes:
      - docs/**/*
      - README.md
```

### Resource Management Strategies

**Shared Resource Pools**

Enterprise teams run 1000s of concurrent pipelines. Dedicated runners per team leads to resource islands and waste.

**Solution: Shared pool with priority queuing**
- Single pool of runners across organization
- Priority-based queuing (emergency production fixes > feature development)
- Namespaced isolation (Pod Security Policies in Kubernetes)
- Cost: ~$X/hour for pool; shared across 100 teams = $X/100hour per team

Example: GitLab runner infrastructure
```
┌─────────────────────────────────────┐
│ Shared Runner Pool (100 runners)    │
│                                     │
│ Priority Queue:                     │
│  P0: Production hotfixes            │
│  P1: Main branch CI                 │
│  P2: Feature branch CI              │
│  P3: Scheduled jobs                 │
└─────────────────────────────────────┘
  ↑      ↑      ↑      ↑
Team1  Team2  Team3  Team4
```

**Right-Sizing Container Resources**

Containers default to unlimited CPU/memory. Under heavy load, single pipeline consumes full node resources, starving others.

**Optimal sizing:**
```yaml
resources:
  requests:     # Kubernetes scheduler uses for placement
    memory: 512Mi
    cpu: 500m
  limits:       # Hard enforcement; exceeding terminates pod
    memory: 1Gi
    cpu: 1000m
```

Avoid:
- Setting limits too high (waste; resource hoarding)
- Missing requests (unschedulable; scheduler can't allocate)
- Unlimited requests (job steals all resources)

**Spot Instances and Preemptible VMs**

Non-critical workloads (CI/CD parallelization, testing) tolerate interruptions.
- AWS Spot instances: 60-90% cost reduction
- Google Preemptible VMs: ~70% cost reduction
- Azure Spot VMs: ~80% cost reduction
- Trade-off: 2-5% interruption rate (acceptable for build jobs)

Configuration:
```terraform
# Terraform: Use preemptible instances for CI/CD runners
resource "google_compute_instance" "ci_runner" {
  scheduling {
    automatic_restart      = false  # Don't retry on preemption
    preemptible            = true   # Opt-in to preemption
    on_host_maintenance    = "TERMINATE"
  }
}
```

**Scheduled Pipeline Execution**

Non-blocking integration tests (performance tests, extended test suites) scheduled off-peak:
```yaml
# Run expensive tests at 2 AM when cloud prices are lower
extended_tests:
  schedule: "0 2 * * *"
  only:
    - schedules
```

Cost savings: 30% cheaper off-peak compute in many regions.

### Cloud Cost Monitoring and Analysis

**Allocation and Visibility**

Blind spend is common: CI/CD infrastructure cost treated as general IT overhead. DevOps team unaware of per-pipeline cost.

**Implementation:**
- **Tagging discipline**: Tag every compute resource with cost center, application, pipeline
  ```yaml
  # Example AWS tags on EC2 runner instances
  tags:
    CostCenter: "engineering"
    Application: "api-service"
    Pipeline: "build-and-test"
    Owner: "platform-team"
  ```
- **Cloud-native cost monitoring**: AWS Cost Explorer, GCP Cost Management, Azure Cost Analysis
- **Monthly cost reports**: Automated reports per team/application
- **Chargeback model**: Charge teams proportionally for CI/CD consumption

Example cost visibility output:
```
Team A: $2,500/month
  - Build parallelization: $1,200 (unit tests × 5 parallel runners)
  - Security scanning: $800 (SAST/DAST)
  - Artifact storage: $500 (container images)

Team B: $15,000/month
  - GPU-based testing: $10,000
  - Load testing infrastructure: $5,000
```

**Cost Baselines and Anomaly Detection**

Sudden cost spikes indicate issues:
- Runaway pipeline loop consuming resources
- Misconfigured container consuming excessive memory
- Forgotten scheduled job running repeatedly

Automated alerts:
```
Alert: CI/CD cost exceeded baseline by 50% this week
Likely cause: Commit loop testing pipeline configuration
Action: Review commits to .gitlab-ci.yml from Tuesday
```

### Cost-Saving Strategies

**Artifact Lifecycle Management**

Binary artifacts accumulate: container images from every commit.
- Default: retain all artifacts indefinitely
- Cost: 10,000 images × 100 MB = 1 TB storage (AWS: $23/month)

Strategy: Intelligent retention
```yaml
retention_policy:
  keep_latest_images: 10        # Recent builds
  keep_tagged_images: unlimited # Release tags: v1.2.3
  keep_merge_commit_images: 5   # Merge commits
  delete: >30 days old
```

**Consolidating Test Infrastructure**

Multiple test pipelines may test overlapping functionality:
- Unit tests run on every commit (fast)
- Integration tests run on merge to main (medium)
- Smoke tests run in staging (lightweight)

Consolidation: Deduplicate test execution
- Centralized test library used by all pipelines
- Once tested, don't retest in downstream stages
- Reduces total test time by 30-50%

**Container Image Optimization**

Unoptimized images waste storage and transfer bandwidth:
- Fat image: 500 MB (base OS + all language runtimes)
- Optimized multi-stage build: 50 MB (only runtime deps)
- 10x size reduction = 10x faster deployment, 10x cheaper storage

Example Dockerfile optimization:
```dockerfile
# ❌ Fat image (500 MB)
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3 python3-pip build-essential
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY app.py .
CMD ["python3", "app.py"]

# ✅ Optimized image (50 MB)
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
USER nobody
CMD ["python3", "app.py"]
```

Size comparison: 500 MB vs 50 MB = 90% reduction.

**Scheduled Infrastructure Scaling**

Predictable peaks: higher pipeline volume during business hours.

Auto-scaling policy:
```
9 AM - 6 PM: Max 50 runners (heavy development)
6 PM - 9 AM: Max 10 runners (background jobs only)
Weekend: Max 5 runners (on-call emergency only)
```

Savings: Unused capacity elimination during predictable off-peak.

### Serverless CI/CD Solutions

**Motivation**

Traditional CI/CD runners are VMs running continuously:
- AWS EC2 runner: $0.05/hour × 730 hours/month = $36.50/month (unused)
- 20 runners across organization × $36.50 = $730/month unused capacity

Serverless model: Pay only for execution time
- AWS CodePipeline + AWS CodeBuild: $0.005/build minute
- GitHub Actions: 3000 free minutes/month, then $0.008/minute
- Typical 5-minute build × 100 commits/day = 500 minutes/day = $2.40/day (vs $24.16/day for dedicated)

**Serverless CI/CD Platforms**

| Service | Model | Scaling | Cost Model | Best For |
|---------|-------|---------|-----------|----------|
| GitHub Actions | Event-triggered | Auto (unlimited) | Free tier + $0.008/min | GitHub-native, small-medium teams |
| AWS CodePipeline | Event-triggered | Auto | $1/pipeline/month + CodeBuild $0.005/min | AWS ecosystem, complex pipelines |
| Google Cloud Build | Container-native | Auto | 120 free build-minutes/day, $0.003/min | GCP-native, container-heavy |
| Azure Pipelines | Workflow-based | Scalable | Free tier + $40/parallel job | Microsoft ecosystem, on-prem integration |
| GitLab CI (SaaS) | Built-in | Auto | Free tier + $9/month | GitLab-native users |

**Serverless vs Managed Runners Trade-offs**

| Aspect | Serverless | Managed Runners |
|--------|-----------|-----------------|
| **Startup time** | 30-60 sec (warm-up + scale) | <5 sec (pre-started) |
| **Predictability** | Variable (cold starts) | Consistent (pre-allocated) |
| **Cost efficiency** | High (pay per use) | Medium (fixed baseline) |
| **Customization** | Limited (platform restrictions) | High (full VM control) |
| **Compliance** | Provider-managed (less control) | Full control (on-prem option) |
| **Multi-cloud** | Difficult (vendor lock-in) | Feasible (self-hosted runners) |

**Hybrid Approach: Best of Both**

Many organizations use hybrid:
```
GitHub Actions for:
  - Quick feature branch CI (free tier, fast)
  - Non-critical builds (acceptable cold starts)
  - Cost-optimized secondary workloads

Managed runners for:
  - Production main-branch builds (consistency)
  - Expensive operations (GPU tests, etc.)
  - Compliance workloads (on-prem)
```

---

## Pipeline Security

### Securing CI/CD Pipelines

**Threat Model: CI/CD Supply Chain Attacks**

Attackers increasingly target pipelines because:
1. Single compromise provides code injection at scale
2. Artifacts trusted due to build provenance
3. Access to deployment credentials enables lateral movement
4. Logs reveal infrastructure configuration

Real-world examples:
- **SolarWinds (2020)**: Compromised build pipeline injected backdoor into ~18,000 customers
- **3CX Supply Chain (2023)**: Malicious DLL injected in build process compromised ~600k customers
- **npm package hijacking**: Compromised credentials push malicious packages to registry

**Pipeline Security Layers**

```
┌──────────────────────────────────────┐
│ Access Control Layer                 │
│ (Who can commit, review, approve)    │
├──────────────────────────────────────┤
│ Build Integrity Layer                │
│ (Signed commits, artifact signatures)│
├──────────────────────────────────────┤
│ Secrets Layer                        │
│ (Credentials, API keys never exposed)│
├──────────────────────────────────────┤
│ Scanning Layer                       │
│ (Vulnerability, malware, compliance) │
├──────────────────────────────────────┤
│ Deployment Control Layer             │
│ (Approval workflows, audit logging)  │
└──────────────────────────────────────┘
```

**Source Code Integrity**

Malicious commits appear to come from trusted developers (spoofing with `--author`).

Protection:
```bash
# Force signed commits
git config --global user.signingkey <GPG_KEY_ID>
git commit -S -m "Fix: xyz"

# Enforce in repository
# GitHub: Settings → Rules → Require signed commits
# GitLab: Settings → Security & Compliance → Require signed commits
```

Branch protection requirements:
- Code review (≥2 approvals)
- Status checks (all CI/CD checks pass)
- Dismissal of stale reviews (requires fresh approval)
- Require up-to-date branch before merge

### Secrets Management

**The Problem: Secrets in Code**

Secrets (API keys, database credentials, certificates) sometimes leak into repositories:
```python
# ❌ WRONG: Secret hardcoded
class Database:
    PASSWORD = "super_secret_password"  # Exposed in Git history

# ❌ STILL WRONG: Even in .gitignore
# .gitignore added AFTER password pushed
# Commit history still contains the secret
```

Why it's severe:
- Commits are permanent; removing from `.gitignore` doesn't erase
- Secret in public GitHub is compromised instantly (bots scan)
- Force-pushing loses history; doesn't erase from forks
- Cost of rotation: Often requires full infrastructure update

**Secrets Platforms**

Purpose: Centralized secure storage with rotation and audit logging.

| Platform | Features | Best For |
|----------|----------|----------|
| **HashiCorp Vault** | Dynamic secrets, encryption as a service, audit logging, multi-cloud | Enterprise, complex workflows |
| **AWS Secrets Manager** | AWS integration, automatic rotation, JSON structure | AWS-native deployments |
| **Azure Key Vault** | Azure integration, HSM backing, managed identity | Azure-primary organizations |
| **Google Secret Manager** | GCP integration, IAM-driven access, versioning | GCP-native deployments |
| **sealed-secrets / sops** | Lightweight, GitOps-friendly, encrypted in Git | Kubernetes-based deployments |
| **Kubernetes Secrets** | Native, easy to use, ⚠️ base64 (not encrypted by default) | Dev/test only, configure encryption-at-rest for prod |

**Secret Injection Patterns**

Deploy time injection prevents credentials in container image:
```yaml
# ❌ Don't do this
ENV DB_PASSWORD=secret123

# ✅ Inject at runtime from secrets platform
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

**Secret Rotation Automation**

Rotated regularly (30-90 days) to limit damage from compromise:
```hcl
# Terraform: Auto-rotate RDS password every 30 days
resource "aws_secretsmanager_secret_rotation" "db" {
  secret_id           = aws_secretsmanager_secret.db_password.id
  rotation_enabled    = true
  
  rotation_rules {
    automatically_after_days = 30
  }
  
  rotation_lambda_arn = aws_lambda_function.rotate_db_password.arn
}
```

**Secret Scanning in CI/CD**

Prevent secrets leaking forward:
```yaml
# Pre-commit hook: Prevent secret commits
- repo: https://github.com/Yelp/detect-secrets
  hooks:
    - id: detect-secrets
      args: ['--baseline', '.secrets.baseline']
```

Platform-native scanning:
- GitHub: Secret scanning detects and alerts on leaked credentials
- GitLab: Secret detection scans commits
- TruffleHog: Scans Git history for high-entropy strings (likely secrets)

### Access Control and Authentication

**Pipeline Credentials Complexity**

Pipeline needs credentials to:
1. Push container images to registry
2. Deploy to Kubernetes/cloud platform
3. Trigger downstream pipelines
4. Report test results to external systems

Naive approach: Single shared credential for everything
- Impossible to revoke one permission without affecting others
- Violates least-privilege principle
- Single compromise exposes entire pipeline

**Least-Privilege Pattern**

Each pipeline stage gets minimal permissions required:
```yaml
# GitLab CI example: Separate service accounts per stage
build:
  image: docker:latest
  variables:
    DOCKER_AUTH_CONFIG: $DOCKER_REGISTRY_CREDENTIALS  # Minimal: only push to registry
  script:
    - docker build -t myapp:$CI_COMMIT_SHA .
    - docker push myapp:$CI_COMMIT_SHA

deploy_dev:
  image: bitnami/kubectl:latest
  variables:
    KUBECONFIG: $DEV_CLUSTER_KUBECONFIG  # Minimal: only deploy to dev cluster
  script:
    - kubectl set image deployment/myapp myapp=myapp:$CI_COMMIT_SHA -n dev

deploy_prod:
  image: bitnami/kubectl:latest
  variables:
    KUBECONFIG: $PROD_CLUSTER_KUBECONFIG  # Separate credentials for prod
  script:
    - kubectl set image deployment/myapp myapp=myapp:$CI_COMMIT_SHA -n prod
  when: manual  # Require explicit approval
```

**Workload Identity / Service Accounts**

Modern cloud platforms support workload identity eliminating long-lived credentials:

AWS IRSA (IAM Roles for Service Accounts):
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-pipeline
  namespace: cicd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/CIPipelineRole

---
apiVersion: v1
kind: Pod
metadata:
  name: build-job
spec:
  serviceAccountName: ci-pipeline  # Pod automatically gets AWS credentials
```

Benefits over storing credentials:
- No credentials to rotate
- Fine-grained IAM policies
- Audit trail (CloudTrail logs which pod accessed what)
- Temporary tokens (1-hour expiration by default)

**GitHub Actions OIDC (OpenID Connect)**

GitHub can exchange short-lived OIDC tokens for cloud credentials without storing secrets:

```yaml
name: Deploy to AWS
on: [push]

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Request OIDC token
      contents: read

    steps:
      - uses: actions/checkout@v3
      
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
          aws-region: us-east-1
          # No AWS_SECRET_ACCESS_KEY stored!
      
      - run: aws s3 ls  # Complete with temporary STS credentials
```

### Vulnerability Scanning and SAST/DAST

**SAST (Static Application Security Testing)**

Analysis of source code without execution. Finds issues before deployment.

Common tools:
- **SonarQube**: Language-agnostic, detects bugs/vulns/code smells
- **Semgrep**: Language-specific rules, fast, easy to customize
- **Checkmarx**: Enterprise SAST, comprehensive
- **Snyk**: Developer-friendly, SCA + SAST

Example pipeline integration:
```yaml
analyze:
  stage: test
  image: returntocorp/semgrep:latest
  script:
    - semgrep --json --output=semgrep-report.json ./src
  artifacts:
    reports:
      sast: semgrep-report.json  # GitLab SAST integration
```

Issues caught:
- SQL injection vulnerabilities
- Hard-coded credentials
- Unsafe cryptography (MD5, weak TLS)
- Logic errors (null dereference, infinite loops)
- License compliance violations

**DAST (Dynamic Application Security Testing)**

Testing of running application. Finds runtime vulnerabilities not visible in code.

Common tools:
- **OWASP ZAP**: Open source, web app scanning
- **Burp Suite**: Commercial, comprehensive
- **StackHawk**: Continuous DAST, pipeline-friendly

DAST workflow:
```
1. Deploy application to temporary staging environment
2. DAST scanner crawls endpoints, submits payloads
3. Scanner detects vulnerabilities (XSS, CSRF, etc.)
4. Results reported back to pipeline
5. If critical vulns: block deployment
```

Pipeline configuration:
```yaml
security_scan:
  stage: test
  image: owasp/zap2docker-stable:latest
  script:
    - zap-baseline.py -t http://staging.example.com -r dast-report.html
  artifacts:
    reports:
      dast: dast-report.json
    paths:
      - dast-report.html
  allow_failure: true  # Don't block deployment for informational findings
```

**SCA (Software Composition Analysis)**

Scans dependencies for known vulnerabilities.

Tools:
- **Snyk**: Continuous monitoring, remediation suggestions
- **OWASP Dependency Check**: Open source, Java/Python/Node
- **Black Duck**: Enterprise SCA
- **JFrog Xray**: Artifact scanning

Integration:
```yaml
dependencies:
  stage: test
  script:
    - snyk test --json > snyk-report.json
    - snyk monitor  # Continuous monitoring for future vulns in dependencies
  artifacts:
    reports:
      dependency_scanning: snyk-report.json
```

### Secure Artifact Storage

**Container Image Registry Security**

Container images are critical artifacts (shipped to production). Security posture:

1. **Image signing**: Verify image originated from trusted build
   ```bash
   # Sign image with Cosign (CNCF tool)
   cosign sign --key cosign.key myregistry.azurecr.io/myapp:v1.2.3
   
   # Verify before deployment
   cosign verify --key cosign.pub myregistry.azurecr.io/myapp:v1.2.3
   ```

2. **Image scanning**: Detect vulnerable dependencies
   ```bash
   # Trivy: lightweight vulnerability scanner
   trivy image myregistry.azurecr.io/myapp:v1.2.3
   ```

3. **Admission controllers**: Block unsigned/vulnerable images in Kubernetes
   ```yaml
   apiVersion: admissionregistration.k8s.io/v1
   kind: ValidatingWebhookConfiguration
   metadata:
     name: image-verification
   webhooks:
   - name: verify-image-signature
     rules:
     - operations: ["CREATE", "UPDATE"]
     clientConfig:
       service:
         name: sigstore-verification
   ```

4. **Registry authentication**:
   - No anonymous access
   - Service-account level credential (not shared humans)
   - Immutable image tags (prevent tag re-use for different code)

### Compliance in Pipelines

**Audit Logging**

All pipeline actions must be auditable:
```
2024-03-18 14:32:15 User@example.com approved deployment to production
2024-03-18 14:32:22 Deployment started (image: myapp:abc123)
2024-03-18 14:32:45 Deployment completed successfully
2024-03-18 14:33:01 Health check passed (10/10 replicas ready)
```

Aggregate to SIEM system (Splunk, ELK, DataDog) for retention and alerting.

**Regulatory Compliance**

Different industries have compliance requirements:

| Regulation | Key Requirement | Pipeline Impact |
|-----------|-----------------|-----------------|
| **SOX** (Finance) | Segregation of duties, audit trails | Manual approval gates, immutable logs |
| **PCI-DSS** | Secure change management | Approved security scanning, minimal secrets exposure |
| **HIPAA** | Access control, encryption, audit | Encrypted artifacts, identity-based access, encrypted logs |
| **GDPR** | Data protection, consent | Minimize data in logs, right to deletion |

Compliance checklist:
- [ ] All production deployments require review and approval
- [ ] Audit logs retained ≥1 year
- [ ] Secrets never appear in logs
- [ ] Deployment credentials rotated regularly
- [ ] Access based on role (least privilege)
- [ ] Regular vulnerability scanning
- [ ] Change management process (emergency changes documented)

---

## Production Failures and Failure Analysis

### Textual Deep Dive: Common Causes and Prevention

**Internal Mechanism: Failure Propagation Paths**

Production failures rarely occur in isolation. Modern distributed systems exhibit cascading failure patterns where a single component failure triggers secondary failures across the system.

**Primary failure categories in CI/CD-driven deployments:**

1. **Configuration Drift Failures**
   - Infrastructure configuration diverges from declared state (manual SSH changes, skipped IaC updates)
   - GitOps prevents this: Git is source of truth
   - Detection: Regular `kubectl diff` audit against Git, kyverno policy enforcement
   - Example: Database connection string updated manually, new deployment reverts it causing connection failures

2. **Artifact Integrity Failures**
   - Corrupted container image, missing dependency, unsigned artifact
   - Incomplete testing catches 70% pre-deployment
   - Recovery: Rapid rollback to previous known-good version
   - Example: Build cache poisoned; all deployments from cached layer fail

3. **Resource Exhaustion**
   - Memory leak in container, runaway loop in initialization
   - CPU throttling cascades to missed health check deadlines
   - Timeout of one service triggers cascading timeouts upstream
   - Prevention: Resource limits (memory, CPU), realistic health check timeouts

4. **Deployment Sequencing Errors**
   - Database schema migration runs after application expects new columns
   - Blue-green deployment creates database lock preventing cutover
   - Service B expects API v2 from Service A, but A rolled back to v1
   - Solution: Backward compatibility, database versioning, coordinated deployments

5. **Security Breach During Deployment**
   - Compromised image injected during build
   - Secrets exposed through logs/environment
   - Lateral movement via deployment credentials
   - Prevention: Image scanning, signed artifacts, minimal credentials

**Architecture Role: Failure Detection and Response**

```
┌─────────────────────────────────────────────────────────────┐
│ Observability Layer (Detects Failures)                      │
│  - Metrics (latency, error rate, throughput)               │
│  - Logs (errors, stack traces, audit)                      │
│  - Traces (request flow, latency breakdown)                │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  Alerting System        │
        │  (Policy: alert if err  │
        │   rate > 1% for 2 min)  │
        └────────────┬────────────┘
                     │
        ┌────────────▼──────────────────┐
        │ Response Automation            │
        │  - Automatic rollback          │
        │  - Scale up replicas           │
        │  - Trigger runbooks            │
        │  - Page on-call engineer       │
        └────────────┬──────────────────┘
                     │
        ┌────────────▼──────────────────┐
        │ Remediation Execution         │
        │  - Rollback running           │
        │  - Symptoms resolving         │
        │  - Root cause investigation   │
        └──────────────────────────────┘
```

**Production Usage Patterns**

**Pattern 1: Blue-Green Deployment with Automatic Rollback**
```
Time 0:  BLUE (v1.2.0) serving 100% traffic
Time 1:  Deploy GREEN (v1.2.1) with 0% traffic
Time 2:  Route 5% traffic to GREEN
Time 3:  Monitor GREEN error rate
Time 4a: If error rate < 0.1%: Continue 25% → 50% → 100%
Time 4b: If error rate > 1%: ROLLBACK 100% to BLUE (within 30 sec)
```

Benefits:
- Instant rollback (not waiting for pod restart)
- A/B comparison (v1.2.0 vs v1.2.1 side-by-side)
- Risk: Double resource consumption during deployment

**Pattern 2: Health Check Driven Remediation**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-server
spec:
  containers:
  - name: app
    image: myapp:v1.2.3
    
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30      # Allow app startup
      periodSeconds: 10            # Check every 10s
      failureThreshold: 3           # Kill after 3 failures (30s)
      
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      failureThreshold: 1           # Remove from service immediately if fails
      
    resources:
      requests:
        memory: 256Mi
        cpu: 100m
      limits:
        memory: 512Mi
        cpu: 500m
```

Kubernetes response:
- Readiness fails → Service endpoints remove pod (requests routed away)
- Liveness fails → Pod killed and restarted
- If persistent failure: Deployment shows 0/3 ready; monitoring alerts

**DevOps Best Practices**

1. **Comprehensive Observability**
   - Log levels: ERROR (failures), WARN (degradation), INFO (state transitions)
   - Structured logging: JSON with fields (user_id, transaction_id, service, latency)
   - Distributed tracing: Jaeger, Datadog, or cloud-native (X-Ray, Cloud Trace)

2. **Failure Injection Testing (Chaos Engineering)**
   ```bash
   # Simulate 10% packet loss to external API
   tc qdisc add dev eth0 root netem loss 10%
   
   # Observe: Does application retry? Does it fail gracefully?
   # Then remove: tc qdisc del dev eth0 root
   ```

3. **Clear Failure Detection Thresholds**
   ```
   Error rate > 5%:        P4 (low-priority alert)
   Error rate > 10%:       P3 (normal alert)
   Error rate > 25%:       P2 (urgent, page on-call)
   Error rate > 50%:       P1 (critical, all hands on deck)
   ```

4. **Defined Escalation Paths**
   - P1 critical: Page entire on-call rotation + notify leadership
   - P2 urgent: Page on-call engineer + post to Slack incident channel
   - P3 normal: Auto-remediation attempt, then alert if unsuccessful
   - P4 low: Create ticket, no alert

5. **Runbook Automation**
   - Common failures have documented automated responses
   - Example: "Deployment error rate > 10%" → Auto-rollback to previous version
   - Higher-confidence failures are fully automated; uncertain failures get human approval

**Common Pitfalls**

❌ **Alert Fatigue**: Too many alerts (> 100/day) cause engineers to ignore
→ **Fix**: Tune thresholds; consolidate related alerts into composite

❌ **Silent Failures**: No observability means no detection until customer complains
→ **Fix**: Mandatory instrumentation; logs/metrics required in code review

❌ **Slow Mean Time To Recovery (MTTR)**: 2-hour debugging per production issue
→ **Fix**: Automated rollback, runbook automation, pre-defined escalations

❌ **Cascading Failures**: One component failure triggers downstream failures
→ **Fix**: Timeouts, circuit breakers, bulkheads (isolate failure domains)

❌ **Database Lock During Deployment**: Schema migration locks table, blocks reads/writes
→ **Fix**: Zero-downtime migrations (online DDL, backward-compatible changes, separate deployment from schema change)

### Practical Code Examples

**Terraform: Multi-Region Deployment with Automatic Failover**

```hcl
# Primary region
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

# Secondary region for redundancy
provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}

# Primary load balancer
resource "aws_lb" "primary" {
  provider = aws.primary
  name     = "app-primary-lb"

  health_check {
    path                = "/healthz"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200"
  }
}

# Route53 health check
resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port              = 443
  type              = "HTTPS"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "primary-region-health"
  }
}

# Failover routing: Route to primary, failover to secondary if unhealthy
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  set_identifier = "Primary"
  failover_routing_policy {
    type = "PRIMARY"
  }
  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
  health_check_id = aws_route53_health_check.primary.id
}

resource "aws_route53_record" "app_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"

  set_identifier = "Secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
}
```

**Kubernetes: Automated Rollback on Failed Deployment**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-server
spec:
  replicas: 3
  revisionHistoryLimit: 10  # Keep last 10 rollouts
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # 1 extra pod during rollout
      maxUnavailable: 0     # Don't take pods offline
  
  selector:
    matchLabels:
      app: api-server
  
  template:
    metadata:
      labels:
        app: api-server
      annotations:
        prometheus.io/scrape: "true"  # Monitoring
    
    spec:
      containers:
      - name: app
        image: myapp:v1.2.3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 1  # Immediately remove if fails
        
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          periodSeconds: 10
          failureThreshold: 3  # Give 30 seconds before kill
        
        resources:
          requests:
            memory: 256Mi
            cpu: 100m
          limits:
            memory: 512Mi
            cpu: 500m

---
# Monitor deployment and auto-rollback on failure
apiVersion: batch/v1
kind: CronJob
metadata:
  name: deployment-monitor
spec:
  schedule: "*/1 * * * *"  # Every minute
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: monitor
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              # Check if deployment is progressing
              READY=$(kubectl get deployment app-server -o jsonpath='{.status.readyReplicas}')
              DESIRED=$(kubectl get deployment app-server -o jsonpath='{.spec.replicas}')
              
              if [ "$READY" -lt "$DESIRED" ]; then
                # Deployment stuck; check if recent rollout caused issue
                CURRENT_ROLLOUT=$(kubectl get deployment app-server -o jsonpath='{.metadata.generation}')
                OBSERVED=$(kubectl get deployment app-server -o jsonpath='{.status.observedGeneration}')
                
                if [ "$CURRENT_ROLLOUT" -gt "$OBSERVED" ]; then
                  echo "Deployment pending; waiting..."
                else
                  echo "Deployment failed; rolling back to previous version"
                  kubectl rollout undo deployment/app-server
                fi
              fi
          restartPolicy: Never
```

**Shell Script: Canary Deployment with Automatic Rollback**

```bash
#!/bin/bash
# canary-deploy.sh: Deploy new version to small traffic percentage, monitor, auto-rollback

set -euo pipefail

NAMESPACE="production"
DEPLOYMENT="api-server"
NEW_IMAGE="myregistry.azurecr.io/api-server:${CI_COMMIT_SHA:0:8}"
OLD_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}')
CANARY_PERCENTAGE=5

echo "Starting canary deployment"
echo "Old image: $OLD_IMAGE"
echo "New image: $NEW_IMAGE"

# Step 1: Create canary with new image (5% traffic via Istio/Linkerd)
kubectl set image deployment/$DEPLOYMENT \
  $DEPLOYMENT=$NEW_IMAGE \
  -n $NAMESPACE

echo "Deployed new image; sleeping 30 seconds for pod startup..."
sleep 30

# Step 2: Monitor error rate for 2 minutes
ERROR_THRESHOLD=1.0  # Alert if error rate exceeds 1%
MONITORING_DURATION=120
POLL_INTERVAL=10
ELAPSED=0

while [ $ELAPSED -lt $MONITORING_DURATION ]; do
  ERROR_RATE=$(curl -s http://prometheus:9090/api/v1/query \
    --data-urlencode 'query=rate(http_requests_total{status=~"5.."}[1m])' \
    | jq '.data.result[0].value[1]' | tr -d '"')
  
  echo "Elapsed: ${ELAPSED}s, Error rate: ${ERROR_RATE}%"
  
  if (( $(echo "$ERROR_RATE > $ERROR_THRESHOLD" | bc -l) )); then
    echo "ERROR RATE EXCEEDED THRESHOLD; ROLLING BACK"
    kubectl set image deployment/$DEPLOYMENT \
      $DEPLOYMENT=$OLD_IMAGE \
      -n $NAMESPACE
    echo "Rollback complete; old image restored"
    exit 1
  fi
  
  sleep $POLL_INTERVAL
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

echo "Canary monitoring complete; error rate stable"
echo "Proceeding with full deployment (100% traffic)"
# Additional validation and traffic shift steps would follow
```

### ASCII Diagrams

**Failure Detection and Recovery Flow**

```
┌────────────────────────────────────────────────────────────────┐
│ Normal Operation (0-5 min)                                     │
│ • Healthy replicas serving traffic                            │
│ • Error rate < 0.1%                                           │
│ • P95 latency < 100ms                                         │
└────────────────────┬───────────────────────────────────────────┘
                     │
        ┌────────────▼──────────────┐
        │ New deployment triggered │
        │ (v1.2.3 → v1.2.4)       │
        └────────────┬──────────────┘
                     │
        ┌────────────▼──────────────────────────────────┐
        │ Rolling update begins (maxSurge=1)           │
        │ • Pod 1: v1.2.3 → v1.2.4                     │
        │ • Pod 2: v1.2.3                              │
        │ • Pod 3: v1.2.3                              │
        │ Traffic: 60% v1.2.3 + 40% v1.2.4             │
        └────────────┬──────────────────────────────────┘
                     │
                     ├─► ERROR DETECTED ◄──────────────┐
                     │                                 │
        ┌────────────▼──────────────┐    ┌────────────┴──────────┐
        │ Pod 1 (v1.2.4) fails      │    │ Alert triggered:      │
        │ • Readiness probe fails   │    │ error_rate > 2%       │
        │ • Removed from endpoints  │    │ for 30 seconds        │
        │ • Kubectl creates new Pod │    │                       │
        │ [SAME ERROR]              │    │ Automatic response:   │
        └────────────┬──────────────┘    │ BEGIN ROLLBACK        │
                     │                   └────────────┬──────────┘
                     │                                │
        ┌────────────▼──────────────────────────────▼────────┐
        │ Status: Rollout stuck at 1 ready pods            │
        │ • Prometheus detects: replicas != ready          │
        │ • CronJob executes recovery script               │
        │ • Script detects generation mismatch             │
        │ • Executes: kubectl rollout undo deployment/app  │
        └────────────┬─────────────────────────────────────┘
                     │
        ┌────────────▼──────────────────────────────┐
        │ Rollback in progress                      │
        │ • Pod 1: Terminate v1.2.4                 │
        │ • Pod 1: Start v1.2.3                     │
        │ • Pod 2: Terminate v1.2.4 (didn't get far)
        │ • Pod 3: Terminate v1.2.4                 │
        │ • All Pods: v1.2.3                        │
        └────────────┬──────────────────────────────┘
                     │
        ┌────────────▼──────────────────────┐
        │ Recovery complete (within 90 sec) │
        │ • All pods healthy (v1.2.3)       │
        │ • Traffic: 100% v1.2.3            │
        │ • Error rate: < 0.1%              │
        │ • Page on-call for investigation  │
        └───────────────────────────────────┘
```

**Cascading Failure Example: Service Dependency Chain**

```
Service A (Auth)              Service B (Order)              Service C (Inventory)
    │                              │                               │
    ├─ Connects to                 ├─ Calls A for auth             ├─ Calls B for order
    │  PostgreSQL               │  Calls C for stock             │ Calls A for verification
    │                              │  10s timeout                 │ 5s timeout
    │                              │                               │
    ▼                              ▼                               ▼
PostgreSQL                     [Pod 1] [Pod 2]                 [Pod 1] [Pod 2]
(DB connection pool              │        │                       │        │
 exhaustion)                      └────┬───┘                       └────┬───┘
    │                                  │                               │
    │ (All connections consumed)       │                               │
    │                                  │                               │
    ├─────────────────────────► Auth fails                            │
         (A cannot verify users)      │                               │
                                      │                               │
                            (B gets "service unavailable")           │
                                      │                               │
                            Response time increases:                  │
                            100ms → 1s → 10s timeout                 │
                                      │                               │
                                      ├────────► C timeout            │
                                      │          (B never gets response)
                                      │          │
                                      │          Error rate: 100%
                                      │          │
                                      │          C pod restart
                                      │          [Still no A service]
                                      │          │
                                      └─────► Cascading failure
                                               (all services down)

RECOVERY REQUIRES:
1. Fix root cause (PostgreSQL connection pool)
2. Restart A (once DB responds)
3. B recovers (A available again)
4. C recovers (B answering again)
Typical MTTR: 10-15 minutes (if root cause obvious)
                May extend to hours (if root cause unclear)
```

---

## Scaling CI/CD Pipelines

### Textual Deep Dive: Challenges and Strategies

**Internal Mechanism: Pipeline Bottlenecks**

As organizations grow from 5 developers to 500, CI/CD scaling challenges emerge:

**Stage 1: Small Team (< 20 developers)**
```
10 commits/day per developer × 20 = 200 commits/day
× 5 minute average build time = 1000 compute-minutes/day
1 shared runner at $50/month sufficient
```

**Stage 2: Growing Team (20-100 developers)**
```
15 commits/day per developer × 50 = 750 commits/day
× 5 minute average build time = 3750 compute-minutes/day

Issues:
- Queue: Developers wait 15+ minutes for build results
- Feedback loops: Slow; developers lose context
- Infrastructure: Single runner becomes SPOF

Solution: Parallel executor infrastructure
```

**Stage 3: Enterprise Scale (100-1000+ developers)**
```
20 commits/day per developer × 200 = 4000 commits/day
× 8 minute average build time (parallel testing) = 32,000 compute-minutes/day
= 533 compute-hours/day

Issues:
- Infrastructure cost: $30k+/month at cloud rates
- Distributed systems complexity: Race conditions, eventual consistency
- Resource contention: Networks saturated; storage bottlenecked
- Dependency hell: Monorepo coupling; long builds

Solution: Multi-region federation, smart caching, compute optimization
```

**Scaling Bottlenecks**

1. **Compute Resources**
   - Single region saturated; need multi-region execution
   - Container scheduler (Kubernetes) reaches resource limits
   - GPU scarcity: ML teams monopolize GPU nodes

2. **Network I/O**
   - Artifact downloads: 1000 builds/day × 500 MB = 500 GB/day traffic
   - Registry push/pull: Bandwidth becomes expensive
   - Inter-service communication: Microservice test suites involve many services

3. **Storage**
   - Build caches: Gigabytes per project
   - Artifact storage: Container images accumulate
   - Log retention: Compliance requires archival

4. **Database**
   - Pipeline metadata grows: 10 years of builds = TBs of history
   - Query performance: "Show me failed builds involving service X" slow on massive dataset

5. **Dependency Graph Complexity**
   - Monorepo: 500k files; build touches 10% = 50k file diffs to analyze
   - Service dependencies: 200 microservices; change propagation causes cascading rebuilds
   - Test dependencies: New test framework requires re-running all tests

**Architecture Role: Distributed Execution Model**

```
┌─────────────────────────────────────────────────────────┐
│ Global Coordination Layer                               │
│ (Central CI/CD controller)                             │
│ Responsibilities:                                       │
│ • Parse pipeline definition                            │
│ • Determine what needs to build                        │
│ • Schedule jobs to available capacity                  │
│ • Collect results                                      │
└─────────────┬───────────────────────────────────────────┘
              │
    ┌─────────┼─────────┬──────────────┐
    │         │         │              │
    ▼         ▼         ▼              ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────────┐
│Region 1│ │Region 2│ │Region 3│ │GPU Pool    │
│us-east │ │eu-west│ │ap-south│ │(Specialized)
│        │ │        │ │        │ │            │
│ 50 exec│ │ 30 exec│ │ 20 exec│ │ 10 GPU     │
└───┬────┘ └────┬───┘ └────┬───┘ └──────┬─────┘
    │           │          │            │
    ├────────── Agent communicates with central controller
    │           │          │            │
    ▼           ▼          ▼            ▼
 Executor    Executor   Executor   Executor
 [1-50]      [1-30]     [1-20]     [GPU1-10]

Central controller:
• Monitors available capacity in each executor pool
• Routes job to nearest/least-busy executor
• Handles failure (retry, failover)
• Aggregates results
```

**Production Usage Patterns**

**Pattern 1: Fan-Out Parallelization**
```
┌──────────────────────────┐
│ Single commit event      │
│ (push to main branch)    │
└───────────┬──────────────┘
            │
    ┌───────┴────────┐
    │                │
    ▼                ▼
build:unit-tests   build:integration-tests    [Parallel]
    │ 2 min         │ 5 min
    │               │
    ├───────┬───────┤
    │       │       │
    ▼       ▼       ▼
  SAST    DAST   Unit Coverage             [Parallel]
  2 min   8 min   1 min
    │       │       │
    └───────┴───────┘
            │
            ▼
     deploy:staging
         3 min
         [Sequential after all tests pass]

Total time: 8 min (critical path)
Without parallelization: 2+5+2+8+1+3 = 21 min
Speedup: 21/8 = 2.6x faster
```

**Pattern 2: Distributed Monorepo Build**
```
Repository: 200 microservices
Commit touches: services/auth, services/payment, shared-lib

Dependency analysis:
  shared-lib is imported by: auth, payment, billing, order-service
  Affected services: auth, payment, billing, order-service

Build matrix:
  Build each affected service in parallel
  ├─ services/auth + shared-lib
  ├─ services/payment + shared-lib
  ├─ services/billing + shared-lib
  └─ services/order-service + shared-lib

Only 4 services rebuild (vs 200)
All 4 build simultaneously
Total build time: max(auth_build, payment_build, billing_build, order_build)
Instead of: sum of 4 sequential builds
```

**Pattern 3: Incremental Artifact Distribution**

Problem: Push 500 MB image to 3 regions
- Sequential: 500 MB × 3 = 1500 MB transfer = 5+ minutes
- Parallel: 500 MB pushed to all 3 simultaneously = < 2 minutes

Solution:
```yaml
# Push image to nearest registry (central US)
registry:push:central

# Distribute to edge registries asynchronously
registry:distribute:eu
registry:distribute:ap
registry:distribute:sa

# Webhook triggers as distribution completes
# Regional deployments can proceed independently
```

### Practical Code Examples

**Terraform: Multi-Region Kubernetes Executor Pool**

```hcl
# Central CI/CD controller
resource "aws_ec2_instance" "cicd_controller" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.xlarge"
  availability_zone      = "us-east-1a"
  iam_instance_profile   = aws_iam_instance_profile.controller.name
  
  user_data = base64encode(<<-EOF
            #!/bin/bash
            apt-get update
            apt-get install -y python3 docker.io
            
            # Install GitLab Runner controller
            curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash
            apt-get install -y gitlab-runner
            
            # Register controller
            gitlab-runner register \
              --url https://gitlab.example.com/ \
              --registration-token $GITLAB_TOKEN \
              --executor kubernetes \
              --kubernetes-host https://kubernetes.example.com:6443
            
            # Scale configuration
            gitlab-runner service install
            systemctl restart gitlab-runner
            EOF
  )
}

# Executor pool region 1 (us-east-1)
resource "aws_eks_cluster" "executor_us_east" {
  name    = "executor-us-east-1"
  version = "1.28"
  
  role_arn = aws_iam_role.eks.arn
  
  vpc_config {
    subnet_ids = aws_subnet.executor_us_east[*].id
  }
}

resource "aws_eks_node_group" "executor_us_east" {
  cluster_name    = aws_eks_cluster.executor_us_east.name
  node_group_name = "executor-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.executor_us_east[*].id

  scaling_config {
    desired_size = 20
    max_size     = 50
    min_size     = 5
  }

  instance_types = ["c5.4xlarge"]
  
  tags = {
    Name = "executor-pool-us-east-1"
  }
}

# GPU-specialized pool
resource "aws_eks_node_group" "executor_us_east_gpu" {
  cluster_name    = aws_eks_cluster.executor_us_east.name
  node_group_name = "gpu-executor-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.executor_us_east[*].id

  scaling_config {
    desired_size = 5
    max_size     = 20
    min_size     = 1
  }

  instance_types = ["g4dn.2xlarge"]  # NVIDIA GPU instances
  
  labels = {
    workload_type = "gpu"
  }
  
  tags = {
    Name = "executor-pool-us-east-1-gpu"
  }
}

# Kubernetes Job for CI/CD execution
resource "kubernetes_job" "build_job" {
  depends_on = [aws_eks_cluster.executor_us_east]
  
  metadata {
    name      = "build-${var.ci_commit_sha}"
    namespace = "cicd"
  }

  spec {
    ttl_seconds_after_finished = 3600  # Clean up after 1 hour
    
    template {
      metadata {
        labels = {
          job = "ci-build"
        }
      }
      
      spec {
        node_selector = {
          workload_type = "gpu"  # Route to GPU nodes if gpu_build = true
        }
        
        container {
          name  = "builder"
          image = "myregistry.azurecr.io/builder:latest"
          
          resources {
            requests = {
              cpu    = "2"
              memory = "4Gi"
            }
            limits = {
              cpu    = "4"
              memory = "8Gi"
            }
          }
          
          env {
            name  = "CI_COMMIT_SHA"
            value = var.ci_commit_sha
          }
          
          env {
            name = "REGISTRY_CREDENTIALS"
            value_from {
              secret_key_ref {
                name = "registry-credentials"
                key  = "auth"
              }
            }
          }
        }
        
        restart_policy = "Never"
      }
    }
  }
}
```

**Shell Script: Intelligent Dependency-Based Build Scheduling**

```bash
#!/bin/bash
# smart-build.sh: Analyzes affected services and parallelizes builds

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
BASE_BRANCH="${CI_MERGE_REQUEST_TARGET_BRANCH_NAME:-main}"

# Get list of changed files
CHANGED_FILES=$(git diff --name-only origin/$BASE_BRANCH...HEAD)

echo "Changed files:"
echo "$CHANGED_FILES"

# Find services affected by changes
find_affected_services() {
  local services=()
  
  for file in $CHANGED_FILES; do
    # service-name comes from services/SERVICE_NAME/...
    if [[ $file =~ ^services/([^/]+)/ ]]; then
      services+=("${BASH_REMATCH[1]}")
    fi
    
    # shared-lib affects all services
    if [[ $file =~ ^shared-lib/ ]]; then
      services=($(ls -d services/*/ | xargs basename -a))
      break
    fi
  done
  
  # Deduplicate
  printf '%s\n' "${services[@]}" | sort | uniq
}

AFFECTED=$(find_affected_services)
echo "Affected services:"
echo "$AFFECTED"

# Build each service in parallel using GNU Parallel
echo "$AFFECTED" | parallel --jobs 4 '
  service={}
  echo "Building: $service"
  
  cd services/$service
  
  # Run tests in parallel
  npm test --coverage &
  npm run lint &
  npm run type-check &
  
  wait
  
  # Build image
  docker build -t myregistry.azurecr.io/services/$service:${CI_COMMIT_SHA:0:8} .
  docker push myregistry.azurecr.io/services/$service:${CI_COMMIT_SHA:0:8}
  
  echo "Completed: $service"
'

echo "All affected services built successfully"
```

### ASCII Diagrams

**Monorepo Build Optimization: Dependency Graph Analysis**

```
File Change: src/shared-lib/database.ts

┌─────────────────────────────────────────────────────────┐
│ Dependency Graph Analysis                              │
└─────────────────────────────────────────────────────────┘

        ┌──────────────────┐
        │ shared-lib/*     │  (CHANGED)
        └────────┬─────────┘
                 │
    ┌────────────┼────────────┬───────────┐
    │            │            │           │
    ▼            ▼            ▼           ▼
┌─────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐
│  auth   │ │ billing  │ │ payment │ │  order  │
│ service │ │ service  │ │service  │ │ service │
└────┬────┘ └────┬─────┘ └────┬────┘ └────┬────┘
     │           │            │            │
     └─────┬─────┴────┬───────┘            │
           │          │                    │
           ▼          ▼                    ▼
      ┌─────────┐ ┌──────────┐      ┌──────────┐
      │ API GW  │ │ Reporting│      │Dashboard │
      │         │ │ Service  │      │Service   │
      └─────────┘ └──────────┘      └──────────┘

Build Plan (Parallel):
┌─────────────────────┬─────────────────────┬──────────────┐
│  Batch 1 (5 min)    │  Batch 2 (4 min)    │  Batch 3 (6min)
│ - Build auth       │ - Build API Gateway  │  - Build Dashboard
│ - Build billing    │ - Build Reporting    │  - Build integration tests
│ - Build payment    │   Service            │    (depends on all above)
│ - Build order      │                      │
│ (All in parallel)  │                      │
└─────────────────────┴──────────────────────┴──────────────┘
Total time: max(5, 4, 6) = 6 min (vs 20 min sequential)
```

**Multi-Region Execution Distribution**

```
User in San Francisco commits to GitHub
      │
      ▼
 Webhook triggers CI
      │
      ├─────────────────────────────────────┐
      │                                     │
      ▼                                     ▼
 Global Controller (us-east-1)        Artifact Cache
      │ "Need 4 parallel builds"            │
      │                                     │
      ├─ Context 1 (service A) ──────────┐  │
      │  Route to: us-west (closest)      │  │
      │                                   │  │
      ├─ Context 2 (service B) ──────────┼──┼─► Distributed to:
      │  Route to: us-west (0 overload)  │  │   • us-west (50 MB, 2 sec)
      │                                   │  │   • eu-west (50 MB, 5 sec)
      ├─ Context 3 (service C) ──────────┤  │   • ap-south (50 MB, 8 sec)
      │  Route to: eu-west (user sleeping)   │
      │                                       │
      └─ Context 4 (service D) ──────────┐   │
         Route to: ap-south (load balance)   │

Execution Timeline:
Time 0:   All builds start
Time 5:   Builds complete (parallel)
          Results aggregated
Time 6:   Deploy to staging
          (vs sequential: 5 × 4 = 20 minutes)
```

---

## GitOps Best Practices

### Textual Deep Dive: Repository Structure and Workflows

**Internal Mechanism: Declarative Infrastructure Synchronization**

GitOps inverts traditional deployment paradigm. Instead of "push changes to cluster," GitOps says "cluster continuously converges to Git state."

```
Traditional CI/CD (PUSH):
git push → CI Pipeline → Build → Test → Deploy script (kubectl apply) → Cluster

GitOps (PULL):
Developers commit to Git → Git serves as authoritative source
                              ↓
                        GitOps Agent watches Git
                              ↓
                        Every 30 seconds: diff Git state vs cluster state
                              ↓
                        If divergent: agent applies Git state to cluster
```

**Why This Matters:**

1. **Security**: GitOps agent (running in cluster) needs Git read access, not cluster write access from external pipeline
2. **Auditability**: All changes tracked in Git history; revert by reverting commit
3. **Drift Detection**: Automatic synchronization prevents manual drift (someone SSHing in)
4. **Repeatability**: Immutable Git history enables exact reproduction of any past state

**Repository Structure Patterns**

**Pattern 1: Mono-Repo with Environment Directories**
```
git repository/
├── apps/
│   ├── payment-service/
│   │   ├── source/
│   │   │   ├── main.py
│   │   │   ├── requirements.txt
│   │   │   └── Dockerfile
│   │   └── k8s/
│   │       └── deployment.yaml
│   ├── order-service/
│   │   ├── source/
│   │   └── k8s/
│   │       └── deployment.yaml
│   └── auth-service/
│       └── ...
├── infrastructure/
│   ├── prod/
│   │   ├── payment-service-deployment.yaml
│   │   ├── payment-service-service.yaml
│   │   ├── secrets.yaml  (encrypted)
│   │   └── configmap.yaml
│   ├── staging/
│   │   └── ...
│   └── dev/
│       └── ...
├── shared/
│   ├── base-deployment-template.yaml
│   ├── ingress-rules.yaml
│   └── rbac-definitions.yaml
└── .gitlab-ci.yml
```

Advantages:
- Single repo easier to manage access
- Atomic changes (code + k8s config commited together)

Disadvantages:
- Tightly coupled; hard to deploy independently
- Merge conflicts if many teams commit simultaneously

**Pattern 2: Poly-Repo with Central Configuration**

```
payment-service/ repository:
├── src/
├── Dockerfile
├── .gitlab-ci.yml (builds image, tags with commit SHA)
└── kustomization.yaml (describes K8s deployment)

# Commit triggers: Build image, push to registry
# Kustomization.yaml is reference, not source of truth

---

infrastructure/ repository (separate, central):
├── base/
│   ├── payment-service/
│   │   ├── deployment.yaml (references image tag)
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── order-service/
│   │   └── ...
│   └── shared/
│       └── ...
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml (dev-specific patches)
│   │   ├── config.env
│   │   └── secrets.yaml
│   ├── staging/
│   │   └── ...
│   └── prod/
│       ├── kustomization.yaml (replica count, resource limits)
│       ├── config.env
│       ├── secrets.yaml (encrypted with sealed-secrets)
│       └── network-policies.yaml
└── .gitlab-ci.yml (updates image tag on payload webhook from app repo)

# GitOps agent watches this repo
# On commit: agent applies overlays/prod/ to prod cluster
```

Advantages:
- Decoupling: service teams manage their repo; platform team manages infra repo
- Reusability: shared/ base configs used across services

Disadvantages:
- Coordination: code release and config release must synchronize

**Production Usage Patterns**

**Pattern 1: GitOps with Approval Gates**
```
Developer commits to feature branch
     │
     ▼
Create MR (Merge Request)
     │
     ├─ CI runs: build, test
     │
     ├─ Manager approves
     │
     ├─ Merge to main branch
     │
     ▼
GitOps agent detects change
     │
     ├─ Apply to dev (automatic)
     │
     ├─ Smoke tests pass?
     │ ├─ YES → Apply to staging
     │ └─ NO → Halt; create incident
     │
     ├─ Apply to staging
     │ ├─ Integration tests in staging?
     │ ├─ Performance tests?
     │ ├─ Approval gate (manual for prod)
     │
     └─ [MANUAL APPROVAL] → Apply to prod
```

**Pattern 2: Continuous Deployment with Feature Flags**
```
Developer commits feature with feature flag OFF
     │
     ▼
Merge to main (automatic CI/CD)
     │
     ├─ Build image: v1.5.0
     │
     ├─ Automated deploy to prod (GitOps)
     │
     ├─ Feature flag = OFF
     │
     └─ Users see no change (feature inactive)

     [30 minutes later...]

Product Manager enables feature flag via admin panel
     │
     └─ Users gradually see feature
     │ (flag controls rollout %, A/B testing)

If issues detected:
     │
     └─ Flag disabled (no deployment needed)
     
Feature stable after 2 weeks:
     │
     └─ Code cleanup: remove flag
```

### Practical Code Examples

**Kustomize-based GitOps Repository**

```yaml
# infrastructure/base/payment-service/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: payment-system

commonLabels:
  app: payment-service
  version: v1

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

secretGenerator:
  - name: payment-db-credentials
    envs:
      - secrets.env

configMapGenerator:
  - name: payment-config
    files:
      - config.yaml

patches:
  - target:
      kind: Deployment
      name: payment-service
    patch: |
      - op: replace
        path: /spec/template/spec/containers/0/imagePullPolicy
        value: Always

---
# infrastructure/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: payment-prod

bases:
  - ../../base/payment-service

namePrefix: prod-

commonLabels:
  environment: production

replicas:
  - name: payment-service
    count: 5  # High availability

patchesStrategicMerge:
  - deployment-prod.yaml

resources:
  - network-policy.yaml
  - pod-disruption-budget.yaml

configMapGenerator:
  - name: payment-config
    behavior: merge
    literals:
      - LOG_LEVEL=ERROR
      - METRICS_ENABLED=true
      - DB_POOL_SIZE=50

secretGenerator:
  - name: payment-db-credentials
    behavior: merge
    envs:
      - secrets-prod.env

---
# infrastructure/overlays/prod/deployment-prod.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  template:
    spec:
      containers:
      - name: payment-service
        resources:
          requests:
            memory: 512Mi
            cpu: 500m
          limits:
            memory: 1Gi
            cpu: 1000m
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          failureThreshold: 1
```

**GitOps Workflow: ArgoCD ApplicationSet**

```yaml
# GitOps controller watches this; syncs applications automatically
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: payment-service-all-environments
spec:
  generators:
    # Matrix generator: create applications for all env × region combinations
    - matrix:
        generators:
          - list:
              elements:
                - name: dev
                  environment: development
                - name: staging
                  environment: staging
                - name: prod
                  environment: production
          
          - list:
              elements:
                - region: us-east-1
                - region: eu-west-1
                - region: ap-south-1
  
  template:
    metadata:
      name: "payment-service-{{ name }}-{{ region }}"
    spec:
      project: default
      
      sources:
        # Source 1: Application source code
        - repoURL: https://github.com/myorg/payment-service
          path: k8s/
          targetRevision: main
        
        # Source 2: Overlay configuration from central repo
        - repoURL: https://github.com/myorg/infrastructure
          path: "overlays/{{ name }}"
          targetRevision: main

      destination:
        server: "https://{{ region }}.kubernetes.example.com"
        namespace: payment-system

      syncPolicy:
        automated:
          prune: true        # Delete resources no longer in Git
          selfHeal: true     # Periodic reconciliation
          allowEmpty: false  # Prevent accidental deletion of all resources
        
        syncOptions:
          - CreateNamespace=true
        
        retry:
          limit: 5
          backoff:
            duration: 5s
            factor: 2
            maxDuration: 3m
```

**Helm-based GitOps with Values Override**

```bash
#!/bin/bash
# deploy-with-gitops.sh: Update Helm values in Git, trigger GitOps sync

set -euo pipefail

ENVIRONMENT="${1:-prod}"
SERVICE="payment-service"
NEW_IMAGE_TAG="$CI_COMMIT_SHA"
REPO="git@github.com:myorg/infrastructure.git"
BRANCH="main"

# Clone infrastructure repo (GitOps source of truth)
git clone --branch "$BRANCH" "$REPO" /tmp/infrastructure
cd /tmp/infrastructure

# Update values file with new image tag
HELM_VALUES="overlays/$ENVIRONMENT/$SERVICE/values.yaml"

if ! test -f "$HELM_VALUES"; then
  echo "Values file not found: $HELM_VALUES"
  exit 1
fi

# Update image tag
yq eval ".image.tag = \"$NEW_IMAGE_TAG\"" -i "$HELM_VALUES"

# Commit and push (triggers GitOps sync)
git config user.email "ci-bot@example.com"
git config user.name "CI Bot"

git add "$HELM_VALUES"
git commit -m "Deploy $SERVICE:$NEW_IMAGE_TAG to $ENVIRONMENT"
git push origin "$BRANCH"

echo "✓ Infrastructure updated in Git"
echo "✓ GitOps agent will sync within 30 seconds"
echo "Track deployment: gitops-controller logs"
```

### ASCII Diagrams

**GitOps Reconciliation Loop**

```
TIME 0: Desired state (Git) = Cluster state
┌──────────────────┐
│   Git Repository │
│                  │
│ kind: Deployment │
│ replicas: 3      │
│ image: v1.2.3    │
└──────────────────┘
         │
         │ (GitOps agent watches every 30s)
         │
         ▼
┌──────────────────────────────┐
│  Kubernetes Cluster          │
│                              │
│ Deployment:                  │
│  - 3 replicas running        │
│  - image: v1.2.3             │
│  - Status: all healthy       │
└──────────────────────────────┘

NO CHANGE NEEDED ✓


TIME 1: Developer commits new version
┌──────────────────┐
│   Git Repository │
│                  │
│ kind: Deployment │
│ replicas: 3      │
│ image: v1.2.4    │  ← CHANGED
└──────────────────┘
         │
         ├─(30 second polling interval)─┐
         │                              │
         │ MISMATCH DETECTED ✗           │
         │ Git: v1.2.4                   │
         │ Cluster: v1.2.3               │
         │                              │
         ▼                              ▼
┌──────────────────────────────────────────┐
│ GitOps Agent (ArgoCd/Flux)               │
│                                          │
│ Action: kubectl set image deployment... │
│ deployment/api-server=$image:v1.2.4     │
│                                          │
│ Status: Applying...                      │
└──────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────┐
│  Kubernetes Cluster          │
│                              │
│ Deployment:                  │
│  - rolling update in progress│
│  - Pod 1: v1.2.4 [starting] │
│  - Pod 2: v1.2.3 [running]  │
│  - Pod 3: v1.2.3 [running]  │
└──────────────────────────────┘

SYNC IN PROGRESS...


TIME 2: Sync complete
┌──────────────────┐
│   Git Repository │
│                  │
│ image: v1.2.4    │
└──────────────────┘
         │
         │ MATCH ✓
         │
         ▼
┌──────────────────────────────┐
│  Kubernetes Cluster          │
│                              │
│ Deployment:                  │
│  - 3 replicas running        │
│  - image: v1.2.4             │
│  - Status: all healthy       │
│  - Sync complete: true       │
└──────────────────────────────┘

DESIRED STATE REACHED ✓


TIME 3: Manual SSH change (drift introduced)
Human: kubectl set image deployment/api-server image=v1.2.3 --record
         │
         ▼
┌──────────────────────────────┐
│  Kubernetes Cluster          │
│                              │
│ image: v1.2.3 (DRIFTED)      │  ← Manual change
└──────────────────────────────┘

         │
         ├─(30 second polling interval)─┐
         │                              │
         │ MISMATCH DETECTED ✗           │
         │ Git: v1.2.4                   │
         │ Cluster: v1.2.3               │
         │                              │
         ▼                              ▼
┌──────────────────────────────────────────┐
│ GitOps Agent Self-Healing                │
│                                          │
│ Revert manual change to Git state        │
│ kubectl set image deployment/api-server  │
│   image=v1.2.4                           │
└──────────────────────────────────────────┘

DRIFT CORRECTED ✓
(Git remains source of truth)
```

---

## GitOps Tools Comparison

### Textual Deep Dive: Argo CD vs Flux vs Jenkins X

**Internal Architecture Comparison**

| Aspect | Argo CD | Flux | Jenkins X |
|--------|---------|------|-----------|
| **Project Type** | Kubernetes controller + UI | Kubernetes operators | End-to-end CI/CD platform |
| **Core Model** | Pull-based (recurring polling + webhooks) | Pull-based (agents watch Git) | Push-based (triggers deployment from pipeline) |
| **Architecture** | Centralized (single controller) | Distributed (multi-tenant Flux instances) | GitOps within broader CI/CD |
| **First Commit** | 2018 (Intuit) | 2016 (Weaveworks) | 2018 (CloudBees) |
| **Community** | Large, CNCF incubating | Active, CNCF graduated | Smaller, enterprise-focused |

**Argo CD: The Declarative Synchronization Leader**

Argo CD treats Kubernetes applications as "applications" with visibility into health, diff, and sync status.

Advantages:
- **Intuitive UI**: Visual dashboard showing application state vs Git state
- **Rollout Management**: Hands-on progress indicators during deployments
- **Multi-cluster**: Single controller manages multiple clusters (multi-tenancy via projects)
- **Progressive Delivery**: Argo Rollouts integration for canary/blue-green
- **Extensibility**: Plugins for custom health assessment, notifications

Disadvantages:
- **RBAC Complexity**: Managing permissions across projects complex
- **Observability**: Reliant on separate logging stack for troubleshooting
- **CRD Sprawl**: Many custom resources; steep learning curve
- **Scale Limitations**: Single controller becomes bottleneck at 100+ clusters

When to use:
- Organization needs centralized control + visibility
- Multi-cluster management from single pane of glass
- Teams unfamiliar with GitOps (UI reduces friction)
- Complex deployments requiring fine-grained progress tracking

Example Argo Application:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payment-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/infrastructure
    targetRevision: main
    path: overlays/prod/payment-service
  destination:
    server: https://kubernetes.default.svc
    namespace: payment
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**Flux: Lightweight and Distributed**

Flux deploys Kubernetes operators into each cluster; no centralized controller.

Advantages:
- **Multi-tenancy by design**: Each team can manage their own Flux instance
- **GitOps first philosophy**: Every aspect versioned (includes Flux config itself)
- **Lightweight**: Low resource footprint (< 100 MB memory)
- **Plug-and-play**: Works with any Git platform, not tightly coupled
- **CNCF Graduated**: Production-proven, vendor-neutral

Disadvantages:
- **No centralized UI**: Debugging requires `flux` CLI; less visual
- **Operator overhead**: Each cluster runs full Flux controllers
- **Image update complexity**: Manual or image-scanning sidecar required
- **Learning curve**: Less intuitive for GitOps newcomers

When to use:
- Distributed teams managing independent clusters
- Cost-sensitive deployments (lighter footprint)
- Strict requirement for audit trails in Git (even Flux upgrades)
- Multi-tenant SaaS platform

Example Flux setup:
```bash
# Install Flux into cluster
flux bootstrap github \
  --owner=myorg \
  --repo=infrastructure \
  --path=clusters/prod \
  --personal

# Flux creates GitHub branch, commits Flux manifests
# From that point, everything in Git is truth
```

**Jenkins X: CI/CD with GitOps as Component**

Jenkins X treats GitOps as one part of comprehensive CI/CD landscape. Less pure GitOps, more operational convenience.

Advantages:
- **Batteries included**: Integrated CI, CD, environments, promotion
- **Environment promotion**: Automatic promotion from dev → staging → prod via GitOps
- **Pull request integration**: Automatic PR creation for environment updates
- **Secrets management**: Integrated with external vaults
- **Helm-native**: First-class Helm integration

Disadvantages:
- **Opinionated**: Prescriptive workflow; less flexibility
- **Complexity**: Many moving parts; harder to troubleshoot
- **Community smaller**: Fewer third-party integrations
- **Documentation gaps**: Less comprehensive than Argo/Flux
- **Push-based model**: Slightly higher security footprint than pure pull-based

When to use:
- Organizations want integrated CI + CD (not bolting tools together)
- Teams comfortable with Jenkins ecosystem
- Helm-heavy deployments
- Prefer automation over fine-grained control

### Feature Comparison Matrix

| Feature | Argo CD | Flux | Jenkins X |
|---------|---------|------|-----------|
| **Pull-based sync** | ✓ Webhook + polling | ✓ Native | ✗ (No; push-based) |
| **Centralized UI** | ✓✓ Excellent | ✗ (No) | ✓ (Yes) |
| **Multi-cluster** | ✓✓ Easy | ✓ (Flux per cluster) | ✓ (With config) |
| **GitOps web UI** | ✓ Visual diff + sync | ✗ (CLI only) | ✓ (Integrated) |
| **Progressive delivery** | ✓ Rollouts integration | ~ (Manual) | ✓ (Built-in) |
| **Image scanning** | ✗ (Requires sidecar) | ✓ Flux Image Automation | ✓ (Built-in) |
| **Monorepo support** | ✓ Multiple Applications | ✓ Multiple Kustomizations | ✓ (Mono-friendly) |
| **RBAC** | ✓✓ Projects + AppProjects | ✓ (Cluster RBAC) | ✓✓ (Jenkins RBAC) |
| **Secrets integration** | ✓ External secret operators | ✓ Sealed-secrets | ✓ Vault integration |
| **Learning curve** | Medium (UI helps) | Steep (~GitOps purist) | High (many concepts) |
| **Resource overhead** | Medium (centralized) | Low (per-cluster agents) | High (Jenkins + K8s) |
| **Operational complexity** | Medium | Low | High |

### Pros and Cons Analysis

**Argo CD Pros:**
- Unmatched UI/UX for visual debugging
- Excellent for teams adding GitOps to existing Kubernetes
- Strength in multi-cluster visibility
- Diffs before sync (reduce surprises)

**Argo CD Cons:**
- RBAC complexity steeep
- Central controller as SPOF (mitigated withHA)
- Ecosystem fragmented (Argo Rollouts, Argo Workflows separate)
- Steep learning curve for complex deployments

**Flux Pros:**
- Distributed architecture scales naturally
- Minimal overhead (cluster operations unattenuated)
- GitOps-first philosophy (including Flux config)
- Excellent for autonomous teams

**Flux Cons:**
- Requires CLI comfort (no UI)
- Debugging requires querying cluster (logs + resources)
- Community support smaller than Argo
- Image update process less intuitive

**Jenkins X Pros:**
- From-source CI + CD in single platform
- Environment promotion workflow excellent
- Helm native support
- PR-based review workflows

**Jenkins X Cons:**
- Opinionated (hard to customize)
- Complex (many components to operate)
- Community smaller
- Not pure GitOps (push-based)

### Use Case Suitability

**Use Argo CD if:**
- Multiple teams management from central hub
- Hands-on deployment progress tracking required
- Multi-cluster with different environments
- Compliance: centralized audit/approval workflow
- Organizations with DevOps-focused teams

**Use Flux if:**
- Distributed teams with cluster autonomy
- Cost-sensitivity (< 10 MB memory per cluster)
- Emphasis on GitOps philosophy (everything audited)
- Multi-tenant SaaS (high isolation)
- Cloud-native organizations

**Use Jenkins X if:**
- Monolithic Jenkins usage (familiar)
- Source code → production in single platform
- Environment promotion workflow important
- Helm deployments (deep integration)
- Teams prefer opinionated path

### Community Support and Ecosystem

**Argo CD Community:**
- 11k+ GitHub stars, 2k+ commits/year
- Large Slack community (2k+ active)
- CNCF sandbox → incubating (growing project)
- Strong vendor support (Codefresh, Intuit, others)
- Comprehensive documentation
- Active ecosystem (ArgoCD plugins, integrations)

**Flux Community:**
- 6k+ GitHub stars, 1.5k+ commits/year
- CNCF graduated (mature, stable)
- Active mailing list + Slack
- Smaller but deeply committed community
- Growing enterprise adoption
- Integration with Weave ecosystem

**Jenkins X Community:**
- 2k+ GitHub stars, <500 commits/year
- Declining activity vs Argo/Flux
- Community smaller but dedicated
- Documentation adequate but less comprehensive
- CloudBees commercial offerings available

**Recommendation**: For greenfield projects, Argo CD or Flux; Flux if distributed autonomy priority, Argo if centralized control + visibility priority. Jenkins X if existing Jenkins investment.

---

## GitOps for Legacy Applications

### Textual Deep Dive: Modernization Strategy

**Internal Challenge: Breaking Monolithic Coupling**

Legacy applications rarely align with GitOps assumptions:
- Single database serving entire app (schema versioning complex)
- Manual deployment procedures (not declarative)
- Configuration scattered (config files, environment variables, database flags)
- State management implicit (not external)

GitOps requires:
- Declarative infrastructure + applications
- Immutable deployments (rolling updates)
- External state (stateless compute)
- Reproducible builds

**Refactoring Strategy**

**Phase 1: Assessment (2-4 weeks)**
```
1. Identify deployment process
   Documenting: How currently deployed?
   Output: Runbook capturing manual steps

2. Identify state and configuration
   Where is state? (Database, filesystem, memory)
   Where is configuration? (Config files, env vars, DB flags)
   Scope: What's immutable vs mutable?

3. Assess monorepo vs polyrepo fit
   Can services be deployed independently?
   Or are deployments tightly coupled?

4. Container readiness audit
   Does app containerize? (Dependencies, initialization)
   What health checks are needed?
   What startup procedures?
```

**Phase 2: Containerization (4-8 weeks)**
```
1. Create Dockerfile
   Start with base image matching runtime
   Copy dependencies
   Copy application code
   Define health checks
   Expose port(s)

2. Test container locally
   Container builds
   Container starts
   Health checks pass
   Application responds

3. Publish to registry
   Tag with commit SHA
   Tag with version
   Store securely

Example for .NET legacy app:
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8
WORKDIR /app
COPY ./bin/Release/ .
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s \
  CMD powershell -Command try { $response = Invoke-WebRequest http://localhost:80/health -UseBasicParsing; if ($response.StatusCode -eq 200) { exit 0 } else { exit 1 }} catch { exit 1 }
ENTRYPOINT ["C:\\app\\MyApp.exe"]
```

**Phase 3: Kubernetes Manifests (2-4 weeks)**
```
1. Write deployment manifest
   Image source (registry)
   Replicas
   Resources (memory, CPU)
   Health checks
   Configuration injection

2. Write service manifest
   Service type (ClusterIP, LoadBalancer)
   Port mapping
   Selector labels

3. Write configuration manifests
   ConfigMaps (non-secret data)
   Secrets (encrypted data)

4. Test in dev cluster
   Manifest applies cleanly
   Pod starts
   Service routes traffic
   Configuration loads correctly
```

**Phase 4: State Externalization (4-12 weeks)**
```
Most critical: Database

Current: App + DB tightly coupled
├─ Schema updates with app releases
├─ Rollback requires schema rollback
├─ State not independent from compute

GitOps approach:
├─ Database external service (RDS, Cloud SQL)
├─ Schema migrations separate from app deployment
├─ App version N supports schema N and N-1 (backward compat)
├─ Database independent: scale, backup, restore separately

Example:
App v1.2.0 introduced new columns (user_profile)
├─ Schema migration: Add columns
├─ App relies on columns: SELECT * FROM user_profile  
├─ Deploy App v1.2.0: Works immediately (columns exist)

Rollback from v1.2.0 to v1.1.9:
├─ App v1.1.9 doesn't reference user_profile
├─ Schema still has columns (not removed)
├─ Rollback is clean (no inverse migration needed)
```

### Practical Code Examples

**Docker Containerization for Java Legacy App**

```dockerfile
# Legacy Java application (war deployed on Tomcat)
FROM tomcat:9.0-jdk11-openjdk-slim

# Remove default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy application
COPY my-legacy-app.war /usr/local/tomcat/webapps/ROOT.war

# Custom startup script
COPY startup.sh /

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["/startup.sh"]
```

```bash
#!/bin/bash
# startup.sh: Pre-deployment setup

set -euo pipefail

# Wait for database
echo "Waiting for database..."
until nc -z database.default.svc.cluster.local 5432; do
  echo "Database not ready; sleeping..."
  sleep 5
done

# Run migrations
echo "Running database migrations..."
java -jar /liquibase.jar \
  --changeLogFile=db/changelog.xml \
  --url=jdbc:postgresql://database.default.svc.cluster.local:5432/appdb \
  --username=appuser \
  --password=$DB_PASSWORD \
  update

# Start Tomcat
echo "Starting Tomcat..."
exec catalina.sh run
```

**Kubernetes Manifests for Staged Migration**

```yaml
# Stage 1: Blue-Green with manual cutover
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app-blue
spec:
  replicas: 3
  strategy:
    type: Recreate  # Legacy app not designed for rolling updates
  selector:
    matchLabels:
      app: legacy-app
      version: blue
  template:
    metadata:
      labels:
        app: legacy-app
        version: blue
    spec:
      containers:
      - name: app
        image: myregistry.azurecr.io/legacy-app:v2.5.0
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          value: postgres.production.svc.cluster.local
        - name: DB_PORT
          value: "5432"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 60  # Legacy app slow to startup
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          failureThreshold: 3

---
apiVersion: v1
kind: Service
metadata:
  name: legacy-app
spec:
  selector:
    app: legacy-app
    version: blue  # Switch to "green" when ready
  ports:
  - port: 80
    targetPort: 8080
```

**Database Migration Safe for Rollback**

```sql
-- MySQL: Zero-downtime migration
-- Step 1: Add new column with default (no locking)
ALTER TABLE users ADD COLUMN phone_verified BOOLEAN DEFAULT FALSE;

-- Step 2: Verify data (old app still works)
SELECT COUNT(*) FROM users WHERE phone_verified = 1;  -- Should be 0

-- Step 3: Deploy new app (uses phone_verified)
-- App handles both: with and without column (backward compat)

-- Step 4: Backfill-opulation (optional; app handles missing data)
UPDATE users SET phone_verified = FALSE WHERE phone_verified IS NULL;

-- ROLLBACK SCENARIO:
-- If new app has critical bug:
-- Option 1: Revert deployment (app ignores phone_verified; old column remains)
-- Option 2: Remove column (if needed): ALTER TABLE users DROP COLUMN phone_verified;
```

**GitOps Gradual Adoption Script**

```bash
#!/bin/bash
# gradual-gitops-adoption.sh: Migrate legacy app to GitOps

set -euo pipefail

LEGACY_APP="my-app"
GIT_REPO="https://github.com/myorg/infrastructure"
ENVIRONMENT="${1:-staging}"

echo "=== Phase 1: Assessment ==="
# Extract current deployment from production
kubectl get deployment $LEGACY_APP -n production -o yaml > /tmp/current-deployment.yaml
echo "Current deployment exported: /tmp/current-deployment.yaml"

echo ""
echo "=== Phase 2: Containerization ==="
# Build container
docker build -t myregistry.azurecr.io/$LEGACY_APP:$(git rev-parse --short HEAD) .
docker push myregistry.azurecr.io/$LEGACY_APP:$(git rev-parse --short HEAD)
echo "✓ Container built and pushed"

echo ""
echo "=== Phase 3: GitOps Preparation ==="
# Create GitOps directory structure
mkdir -p gitops/$ENVIRONMENT/$LEGACY_APP
cp /tmp/current-deployment.yaml gitops/$ENVIRONMENT/$LEGACY_APP/
git add gitops/
git commit -m "Add GitOps manifests for $LEGACY_APP"
git push origin main

echo "✓ Manifests committed to Git"

echo ""
echo "=== Phase 4: Deploy from GitOps ==="
# Configure GitOps controller (e.g., Argo CD)
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $LEGACY_APP-$ENVIRONMENT
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $GIT_REPO
    path: gitops/$ENVIRONMENT/$LEGACY_APP
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: $ENVIRONMENT
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "✓ GitOps application created"
echo "✓ Deployment will synchronize from Git within 30 seconds"
echo ""
echo "Monitor with: argocd app get $LEGACY_APP-$ENVIRONMENT"
```

### ASCII Diagrams

**Legacy App Transformation Journey**

```
BEFORE: Traditional Deployment
┌────────────────────────────────┐
│ Developer commits code          │
└────────────────┬────────────────┘
                 │
         ┌───────▼────────┐
         │ Manual Process:│
         │ 1. SSH to VM   │
         │ 2. git pull    │
         │ 3. Run script  │
         │ 4. Restart app │
         │ (Error-prone)  │
         └───────┬────────┘
                 │
         ┌───────▼──────────┐
         │ (30 min manual) │
         │ Pray it works   │
         │ (often doesn't) │
         └───────┬──────────┘
                 │
         ┌───────▼────────────────┐
         │ App running on VM       │
         │ State: ???              │
         │ Config: scattered       │
         │ Version: unclear        │
         │ Rollback: terrifying    │
         └────────────────────────┘


AFTER: GitOps Deployment
┌────────────────────────────────┐
│ Developer commits:              │
│ - Code (GitHub)                │
│ - Kubernetes manifests (Git)    │
└────────────────┬────────────────┘
                 │
        ┌────────▼──────────┐
        │ CI Pipeline:       │
        │ 1. Build container│
        │ 2. Test           │
        │ 3. Push to reg    │
        │ 4. Update Git ref │
        │ (Automated)       │
        └────────┬──────────┘
                 │
        ┌────────▼──────────────────┐
        │ Git: source of truth      │
        │ ├─ image: v1.2.3          │
        │ ├─ replicas: 3            │
        │ └─ resources: defined     │
        └────────┬──────────────────┘
                 │
                 │ GitOps agent watches every 30s
                 │ (Auto-sync if drifted)
                 │
        ┌────────▼──────────────────┐
        │ Kubernetes Cluster        │
        │ ├─ Pod 1: v1.2.3 ✓        │
        │ ├─ Pod 2: v1.2.3 ✓        │
        │ └─ Pod 3: v1.2.3 ✓        │
        │                           │
        │ Status: in-sync, healthy  │
        └───────────────────────────┘

Benefits:
• Repeatable (same every time)
• Auditable (Git history)
• Rollback: git revert
• Observable: what's running matches Git
```

---

## GitOps for MLOps

### Textual Deep Dive: ML Model and Data Versioning

**Internal Challenge: Model as mutable artifact**

Traditional deployment: Code (immutable) → Container → Kubernetes

ML delivery: Code (immutable) + Model (versioned) + Data (evolving) → Container → Kubernetes

**New complexity:**
1. **Model versioning**: Which model version is in production? How to rollback?
2. **Data dependency**: Model accuracy depends on training data. Data changes require model retraining.
3. **Training pipeline**: CI/CD for models (reproducibility, versioning, governance)
4. **Experiment tracking**: 100 model variations; which is best?
5. **Serving**: Inference servers, batch prediction, A/B testing models

**GitOps Approach to MLOps**

Extend GitOps ideology to ML pipeline:
- Git as source of truth for code, model references, data versions
- Declarative model serving (deployment configuration)
- GitOps agent manages model rollouts (canary, blue-green)
- Automated training triggered by data/code changes

```
Git Repository (ML Project)
├── src/           # Training code
├── models/        # Model artifacts (large files)
│   └── current.pkl (reference to model storage)
├── data/          # Training datasets (versioned)
├── k8s/           # Serving deployment
└── mlflow/        # Experiment tracking

Model Storage (Separate):
├── models/v1.0/weights.pkl
├── models/v1.1/weights.pkl    (deprecated)
├── models/v2.0/weights.pkl    (current in staging)
└── models/v2.1/weights.pkl    (current in prod)

Git points to correct model version:
In Git commit: model_version: v2.1
GitOps agent ensures: deployment uses v2.1 weights
```

**Training Pipeline CI/CD**

```
Data changes (e.g., new labeled samples)
         │
         └─ Webhook triggers training pipeline
            │
            ├─ Fetch code from Git (commit SHA)
            ├─ Fetch training data (version)
            ├─ Train model (reproducible, versioned)
            ├─ Evaluate metrics (accuracy, latency)
            ├─ Upload model to storage
            │
            └─ If improved:
               └─ Create PR updating Git reference
                  ├─ "Update model to v2.2"
                  ├─ Attach metrics
                  ├─ Require review
                  │
                  └─ On merge:
                     └─ GitOps: automatic deployment
```

### Practical Code Examples

**DVC (Data Version Control) with GitOps**

```yaml
# dvc.yaml: ML Pipeline definition (versioned in Git)
stages:
  prepare:
    cmd: python src/prepare.py --input data/raw --output data/prepared
    deps:
      - src/prepare.py
      - data/raw
    outs:
      - data/prepared

  train:
    cmd: python src/train.py --input data/prepared --model models/current.pkl
    deps:
      - src/train.py
      - data/prepared
    outs:
      - models/current.pkl
    metrics:
      - metrics.json:
          cache: false  # Metrics always shown, not cached

  evaluate:
    cmd: python src/evaluate.py --model models/current.pkl
    deps:
      - models/current.pkl
    metrics:
      - eval_metrics.json:
          cache: false

---
# .dvc/config: Configure remote storage
['remote "storage"']
    url = s3://my-bucket/models
    
['remote "data"']
    url = s3://my-bucket/datasets
```

```bash
#!/bin/bash
# training-pipeline.sh: Automated model training with GitOps

set -euo pipefail

REPO="https://github.com/myorg/ml-project"
BRANCH="main"
COMMIT_SHA=$(git rev-parse HEAD)
MODEL_REGISTRY="s3://models-registry"

echo "=== ML Training Pipeline ==="

# Step 1: Reproduce training
echo "Running DVC pipeline..."
dvc repro --all

# Step 2: Evaluate model
echo "Evaluating model..."
ACCURACY=$(python -c "import json; print(json.load(open('metrics.json'))['accuracy'])")
echo "Model accuracy: $ACCURACY"

# Step 3: If improved, register model
PROD_ACCURACY=$(aws s3 cp s3://$MODEL_REGISTRY/prod-metrics.json - | jq '.accuracy')

if (( $(echo "$ACCURACY > $PROD_ACCURACY" | bc -l) )); then
  echo "✓ New model is better ($ACCURACY > $PROD_ACCURACY)"
  
  # Register in MLflow
  MODEL_ID=$(mlflow models register-model \
    --model-uri=s3://$MODEL_REGISTRY/models/current \
    --name=fraud-detection \
    --tags="commit=$COMMIT_SHA,accuracy=$ACCURACY")
  
  # Create PR to update serving config
  git checkout -b "auto/update-model-$COMMIT_SHA"
  
  cat > k8s/model-serving/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

replicas:
  - name: model-serving
    count: 3

configMapGenerator:
  - name: model-config
    literals:
      - MODEL_VERSION=$(mlflow models describe --model-name fraud-detection --stage=Production | jq -r '.model_version.version')
      - ACCURACY=$ACCURACY
      - TRAINED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
  
  git add k8s/model-serving/
  git commit -m "Auto: Update model to $MODEL_ID (accuracy: $ACCURACY)"
  git push origin "auto/update-model-$COMMIT_SHA"
  
  # Create PR (automation would create actual PR)
  echo "✓ Created branch: auto/update-model-$COMMIT_SHA"
  echo "Next: Review metrics and approve PR for deployment"
else
  echo "✗ New model not better; skipping deployment"
  exit 1
fi
```

**Kubernetes Deployment for ML Model Serving**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fraud-detection-model
  namespace: ml-serving
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: fraud-detection
  template:
    metadata:
      labels:
        app: fraud-detection
      annotations:
        model-version: v2.1
        trained-date: "2024-03-15T10:30:00Z"
    spec:
      initContainers:
      # Download model from registry before starting server
      - name: download-model
        image: amazon/aws-cli:latest
        command:
        - sh
        - -c
        - |
          aws s3 cp s3://models-registry/fraud-detection/v2.1/model.pkl /models/
          echo "Model downloaded successfully"
        volumeMounts:
        - name: model-storage
          mountPath: /models
        env:
        - name: AWS_REGION
          value: us-east-1

      containers:
      - name: model-server
        image: myregistry.azurecr.io/ml-serving:python-3.9
        ports:
        - name: http
          containerPort: 8000
        - name: metrics
          containerPort: 8001
        
        env:
        - name: MODEL_PATH
          value: /models/model.pkl
        - name: BATCH_SIZE
          value: "32"
        
        volumeMounts:
        - name: model-storage
          mountPath: /models
          readOnly: true
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          failureThreshold: 3
        
        resources:
          requests:
            memory: 2Gi
            cpu: 1000m
          limits:
            memory: 4Gi
            cpu: 2000m

      volumes:
      - name: model-storage
        emptyDir: {}

---
apiVersion: v1
kind: Service
metadata:
  name: fraud-detection
spec:
  selector:
    app: fraud-detection
  ports:
  - name: http
    port: 80
    targetPort: 8000
  - name: metrics
    port: 8001
    targetPort: 8001

---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: fraud-detection-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: fraud-detection-model
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### ASCII Diagrams

**ML Model GitOps Workflow**

```
Data Changes Detected
    │
    ▼
┌─────────────────────────────────────┐
│ Trigger Training Pipeline           │
│ (Data version, commit SHA)          │
└─────────────┬───────────────────────┘
              │
    ┌─────────▼──────────┐
    │ DVC Reproducible   │
    │ Training:          │
    │ 1. Prepare         │
    │ 2. Extract         │
    │ 3. Train           │
    │ 4. Evaluate        │
    └─────────┬──────────┘
              │
    ┌─────────▼──────────────────────┐
    │ Compare with Production Model:  │
    │ Current: accuracy 0.94          │
    │ New:     accuracy 0.96          │
    │ Status: ✓ IMPROVED              │
    └─────────┬──────────────────────┘
              │
    ┌─────────▼───────────────────────┐
    │ Register in Model Registry      │
    │ (MLflow, SageMaker, etc.)       │
    │ Model ID: v2.2                  │
    └─────────┬───────────────────────┘
              │
    ┌─────────▼────────────────────────┐
    │ Create Git Commit                │
    │ • Update k8s/model-serving.yaml  │
    │ • Reference: v2.2                │
    │ • Attach: metrics (accuracy)     │
    └─────────┬────────────────────────┘
              │
    ┌─────────▼──────────────┐
    │ Create & Merge PR      │
    │ (Auto or manual review)│
    └─────────┬──────────────┘
              │
    ┌─────────▼──────────────────────┐
    │ GitOps Detects Change:          │
    │ Git: model-serving:v2.2         │
    │ Cluster: model-serving:v2.0     │
    │ MISMATCH → Sync needed          │
    └─────────┬──────────────────────┘
              │
    ┌─────────▼──────────────────────────┐
    │ Rolling Update (Canary):           │
    │ • Pod 1: Start v2.2                │
    │ • Route 10% traffic to v2.2        │
    │ • Monitor: latency, accuracy       │
    │ • If good: 50% → 100%              │
    │ • If bad: revert (fast rollback)   │
    └─────────┬──────────────────────────┘
              │
    ┌─────────▼──────────────┐
    │ Production:            │
    │ All traffic: v2.2      │
    │ Status: Healthy        │
    └────────────────────────┘
```

---

## Hands-On Scenarios

### Scenario 1: Implement GitOps for Multi-Service Application

**Objective**: Set up GitOps pipeline for 3 microservices across 3 environments

**Prerequisites**: Kubernetes cluster, Argo CD, Git repository

**Steps:**
1. Create directory structure
2. Define base Kustomizations
3. Create environment overlays
4. Install Argo CD
5. Create ApplicationSet
6. Verify sync
7. Perform rollback

[Implementation left for student execution with Terraform/kubectl]

### Scenario 2: Troubleshoot Production Deployment Failure

**Objective**: Diagnose why deployment failed and implement recovery

**Failure scenario:**
```
Deployed application update at 3:45 PM
Error rate increased to 5% by 3:50 PM
Deployment not rolling back automatically
Database connections exhausting
```

**Root cause analysis:**
1. Check pod startup logs
2. Verify database connectivity
3. Check resource limits
4. Identify connection pool exhaustion
5. Determine if new code introduced leak
6. Execute rollback
7. Scale database connections
8. Re-deploy with fix
9. Post-mortem

---

## Interview Questions for Senior DevOps Engineers

### Foundational Knowledge

**Q1: Explain the key difference between CI/CD and GitOps. When would you use each?**

Expected answer should cover:
- CI/CD: Build automation + deployment automation (push-based)
- GitOps: Git as source of truth + pull-based sync
- Both can coexist (CI builds artifacts; GitOps deploys)
- GitOps advantages: auditability, drift detection, rollback via git
- When to use CI/CD alone: monolithic deployments, not using Kubernetes
- When to add GitOps: Kubernetes-based infrastructure, multiple teams

**Q2: You have a database schema change that needs deployment alongside code changes. How would you handle this with CI/CD?**

Expected answer:
- Database migrations separate from code deployment - with backward compatibility (code v2 understand both old & new schemas)
- Test rollback paths
- Zero-downtime migrations (online DDL)
- Consider monorepo vs polyrepo constraints
- Discuss canary deployment with database validation

**Q3: A production deployment failed silently; monitoring didn't alert. What went wrong in your observability setup?**

Expected answer:
- Missing metrics (app didn't expose key metric)
- Alert threshold too high (errors not triggering alert)
- Health checks insufficient (pod marked healthy but not serving traffic)
- Missing distributed tracing (request latency breakdown hidden)
- Log sampling (errors sampled out)
- Solution: mandate observability in code review, testing with chaos engineering

### Advanced Scenarios

**Q4: Your team wants to scale from 50 to 500 developers. How do you scale CI/CD pipelines?**

Expected answer should cover:
- Bottleneck analysis (compute, network, storage, database)
- Multi-region executor pools
- Intelligent caching (dependency, build artifact, Docker layers)
- Parallel execution architecture
- Distributed monorepo builds
- Cost monitoring and chargeback
- Infrastructure elasticity
- Runaway job detection/termination

**Q5: A competitor's CI/CD pipeline was compromised; artifacts were injected with malware. How would you prevent this?**

Expected answer:
- Container image signing and verification
- Artifact content-hash validation
- Code review process (peer approval before merge)
- Secret scanning in CI/CD
- Least-privilege credentials (per stage, not global)
- Workload identity (no long-lived credentials)
- Supply chain SBOM (Software Bill of Materials)
- Regular security scanning of dependencies
- Immutable artifact storage (write-once)
- Audit logging of all access

**Q6: GitOps agent polling Git every 30 seconds. You have 1000 clusters. Is this scalable?**

Expected answer:
- Math: 1000 clusters × 1 poll/30 sec = 33 API calls/sec to Git
- Trivial load (GitHub/GitLab handle ~1000s req/sec)
- Mitigations: webhook-driven immediate sync, polling as safety net
- Scale considerations: Not the bottleneck
- Real bottleneck: GitOps agent syncing 1000 clusters (orchestrator limits)
- Solution: Federation (multiple Argo CDs, each managing subset of clusters)

**Q7: You're migrating a legacy monolithic Rails app to Kubernetes using GitOps. What are the challenges?**

Expected answer:
- Monolith not typically designed for rolling updates (state, sessions)
- Database schema coupling to code
- Containerization challenges (dependencies, initialization)
- Configuration scattered (config files, environment, database flags)
- State externalization required (sessions in Redis, not memory)
- Strategy: Blue-green deployment (not rolling), backward-compatible schemas, phased refactoring
- Consider: Is containerization right first step, or refactor to microservices first?

**Q8: Pipeline regularly violates SLA due to resource exhaustion. Exec wants 99.9% CI/CD availability. How?**

Expected answer:
- Root cause: shared pool overload during peak hours
- Solution 1: Auto-scale executors (peak 50 → off-peak 10)
- Solution 2: Priority queues (production hotfix > feature development)
- Solution 3: SLA monitoring (track pipeline latency percentiles)
- Solution 4: Capacity planning (forecast demand, provision ahead)
- Solution 5: Serverless (GitHub Actions has unlimited parallelism vs managed runners)
- Trade-off: Cost vs latency

### Leadership and Decision-Making

**Q9: Your organization uses Jenkins X for CI/CD. Team wants to migrate to Argo CD + Flux. Business case?**

Expected answer should present both sides:
Jenkins X advantages:
- Integrated (source to production in one platform)
- Opinionated (good for teams liking guardrails)

Argo CD + Flux advantages:
- Best-of-breed approach (specialized tools for specific jobs)
- Flexibility (mix and match with other tools)
- Lower complexity (less moving parts)
- Lower learning curve (focused responsibility per tool)
- Cost (Flux lighter weight; Argo has optional SaaS)

Decision factors:
- Organization size (small: Jenkins X; large: Argo + Flux)
- Team expertise (Jenkins-comfortable: Jenkins X; K8s-focused: Argo)
- Vendor lock-in concerns (Jenkins = CloudBees; Argo/Flux = vendor-independent)
- Pilot project approach

**Q10: 3-month project timeline; CEO wants "we're doing GitOps." How do you scope?**

Expected answer:
- Be realistic about scope
- "GitOps" buzzword doesn't mean full transformation
- Phased approach:
  * Month 1: Containerize app, write K8s manifests
  * Month 2: Set up Argo CD, manual apps
  * Month 3: API-driven deployment, tie to CI/CD
- Define MVP (minimum viable product):
  * GitOps for 1-2 critical services (not everything)
  * Manual approval gates (not fully automated)
  * Monitoring in place (observability first)
- Don't do:
  * Refactor monolith to microservices (out of scope)
  * Infrastructure migration (separate project)
  * Team reorganization (assumes Conway's Law compliance)
- Success metrics:
  * Deployment time < 15 min
  * Rollback time < 5 min
  * Audit trail complete (Git history)

---

## Progressive Delivery

### Textual Deep Dive: Canary, Feature Flags, and Automated Rollout

**Internal Mechanism: Risk-Stratified Deployment**

Traditional all-or-nothing deployment:
```
V1.2.0 running (100% traffic)
    ↓
Deploy V1.2.1 to all pods
    ↓
All traffic now on V1.2.1
    ↓
If error: rollback entire fleet (30+ minutes)
```

Progressive Delivery: Incremental traffic shift with automated validation
```
Time 0:   V1.2.0 [100% traffic]    V1.2.1 [0%]
Time 1:   V1.2.0 [95% traffic]     V1.2.1 [5%]   → Monitor metrics
Time 3:   V1.2.0 [50% traffic]     V1.2.1 [50%]  → Validate
Time 5:   V1.2.0 [0% traffic]      V1.2.1 [100%] → Stable
```

If error rate spike detected at Time 1:
```
Automatic rollback: V1.2.1 traffic → 0%, V1.2.0 → 100%
Recovery time: < 60 seconds (vs 30+ minutes)
Affected users: ~5% (vs 100%)
Blast radius: minimized
```

**Architecture Role: Multi-Version Coexistence**

Progressive delivery requires both old and new versions running simultaneously:

```
┌──────────────────────────────────────────────┐
│ Load Balancer / Service Mesh                 │
│                                              │
│ Routing logic:                               │
│  - If user_id % 100 < 5: route to V1.2.1    │
│  - Else: route to V1.2.0                    │
│  (Consistent: same user always same version)│
└──────┬─────────────────────────────────┬─────┘
       │                                 │
       ▼                                 ▼
    [Pod V1.2.0]              [Pod V1.2.1]
    [Pod V1.2.0]              [Pod V1.2.1]
    [Pod V1.2.0]
       │                         │
       └─────────────┬───────────┘
                     ▼
            Shared Database
            (Schema backward compatible)
```

**Production Usage Patterns**

**Pattern 1: Canary with Automated Rollback Based on Error Rate**

```
DeploymentConfig:
  canary:
    step_duration: 2m
    increment: 10%  # Increase traffic 10% every 2 min
    error_rate_threshold: 2%
    evaluation_interval: 30s

Timeline:
T+0:    Deploy V1.2.1 pod, route 10% traffic
T+2:    Eval: error_rate=0.5% < 2% ✓ → increase to 20%
T+4:    Eval: error_rate=0.8% < 2% ✓ → increase to 30%
T+6:    Eval: error_rate=3.2% > 2% ✗ → ROLLBACK to 0%
        Keep monitoring; alert on-call
```

**Pattern 2: Feature Flags with Percentage Rollout**

```
Feature: PaymentV3 (new payment processor)

Code:
if should_use_feature("payment_v3", user_id):
    processor = PaymentV3()
else:
    processor = PaymentV2()

Feature flag config (Git):
features:
  payment_v3:
    rollout_percentage: 10  # 10% of users see V3
    exclude_groups: ["qa", "staging"]  # QA keeps V2
    tracking: true  # Log all V3 usage

Result:
- 90% users: payment_v2 (old, stable)
- 10% users: payment_v3 (new, monitored)
- Independent of deployment (no new deployment if feature changes)
```

**Pattern 3: A/B Testing with Shadow Traffic**

```
ProductPage:
  Version A: old algorithm (shown to 50% users)
  Version B: new algorithm (shown to 50% users)

Also: Unknown to users, shadow Version B to 100%
  Purpose: Validate latency, error rate without impacting user experience

If Shadow B performance bad:
  Can roll back before public release
  Users unaffected (shadow failed, not served)
```

**DevOps Best Practices**

1. **Baseline Metrics Before Canary**
   - Know V1.2.0 error rate, latency, throughput
   - Canary metrics compared to baseline
   - Threshold: error_rate(V1.2.1) < baseline + 1%

2. **Consistent User Routing**
   - Same user always routed to same version (no flip-flopping)
   - Prevents customer experience inconsistency
   - Hash-based routing: route based on user_id hash

3. **Automated Rollback Triggers**
   - Error rate threshold
   - Latency threshold (p99 latency > baseline × 1.5)
   - Custom metrics (business metrics: checkout_failure_rate)
   - Manual rollback (on-call judgment)

4. **Observability Per Version**
   - Tag all metrics with version label
   - Separate dashboards for V1.2.0 vs V1.2.1
   - Track: error_rate, latency, throughput per version
   - Distributed tracing: identify version in trace

5. **Database Compatibility**
   - Schema changes backward compatible
   - V1.2.0 understands columns V1.2.1 added
   - Rollback doesn't break data integrity

**Common Pitfalls**

❌ **Canary Underspecified**: Error rate threshold too high
→ V1.2.1 with 5% error rate gets promoted because threshold is 10%
→ Fix: Threshold relative to baseline, not absolute

❌ **Inconsistent User Experience**: User hits V1.2.0 then V1.2.1 in same session
→ Fix: Hash-based routing ensures consistency (route(user_id) always goes to same version)

❌ **No Monitoring During Canary**: Deploy V1.2.1, but no alerts configured
→ Errors silently happen; not detected until 50% traffic
→ Fix: Mandatory alerting before canary; smoke tests in canary deploy

❌ **Canary Takes Too Long**: Increment 1% every 5 minutes = 500 minutes = 8+ hours to full rollout
→ Deployment feels slow; blocks next deployment
→ Fix: Aggressive timeline if confidence high (10% every 2 min)

### Practical Code Examples

**Argo Rollouts: Canary Deployment with Automated Rollback**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: payment-service
spec:
  replicas: 5
  selector:
    matchLabels:
      app: payment-service
  
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment-service
        image: myregistry.azurecr.io/payment-service:v1.2.1
        ports:
        - containerPort: 8080
  
  strategy:
    canary:
      steps:
      - setWeight: 10    # Start with 10% traffic
      - pause: {duration: 2m}  # Wait 2 minutes
      - setWeight: 25
      - pause: {duration: 2m}
      - setWeight: 50
      - pause: {duration: 2m}
      - setWeight: 75
      - pause: {duration: 2m}
      
      # Analysis: automated decision to promote or rollback
      analysis:
        interval: 30s           # Evaluate every 30 seconds
        threshold: 5            # If 5+ failures: rollback
        successCriteria:
        - metricName: error_rate
          interval: 30s
          successCriteria: "lessThan"
          value: "2"            # Error rate must be < 2%
          
        - metricName: p99_latency
          interval: 30s
          successCriteria: "lessThan"
          value: "150"          # P99 latency < 150ms
      
      trafficRouting:
        istio:
          virtualservice:
            name: payment-vs
          destinationRules:
          - name: payment-stable
          - name: payment-canary

---
# Metric provider integration
apiVersion: v1
kind: ConfigMap
metadata:
  name: argo-rollouts-config
  namespace: argo-rollouts
data:
  metricsServer: "prometheus"  # Use Prometheus for metrics
  prometheus:
    address: http://prometheus:9090

---
# Prometheus ServiceMonitor for metrics collection
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: payment-service
spec:
  selector:
    matchLabels:
      app: payment-service
  endpoints:
  - port: metrics
    interval: 30s
```

**Feature Flag Management with LaunchDarkly Integration**

```bash
#!/bin/bash
# feature-flag-migration.sh: Gradually roll out PaymentV3 feature

set -euo pipefail

ENVIRONMENT="${1:-production}"
FEATURE_KEY="payment_v3"
API_KEY="$LAUNCHDARKLY_API_KEY"

echo "=== Progressive Feature Flag Rollout ==="

# Function to update rollout percentage
update_rollout() {
  local percentage=$1
  echo "Setting $FEATURE_KEY rollout to $percentage%"
  
  curl -X PATCH "https://api.launchdarkly.com/api/v2/flags/$ENVIRONMENT/$FEATURE_KEY" \
    -H "Authorization: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "environments": {
        "'$ENVIRONMENT'": {
          "rollout": {
            "kind": "gradual",
            "seed": 12345,
            "rolloutPercentage": '$percentage',
            "bucketByUserKey": true
          }
        }
      }
    }'
}

# Monitor metrics via Prometheus
get_error_rate() {
  curl -s 'http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~"5.."}[5m])' \
    | jq '.data.result[0].value[1]' | tr -d '"'
}

# Progressive rollout
for percentage in 1 5 10 25 50 75 100; do
  echo ""
  echo ">>> Rolling out to $percentage%"
  update_rollout $percentage
  
  # Wait and monitor
  sleep 120
  
  ERROR_RATE=$(get_error_rate)
  echo "Current error rate: $ERROR_RATE%"
  
  if (( $(echo "$ERROR_RATE > 2.0" | bc -l) )); then
    echo "ERROR RATE TOO HIGH; ROLLING BACK"
    update_rollout 0
    exit 1
  fi
done

echo "✓ Feature $FEATURE_KEY fully rolled out"
```

**Istio VirtualService for Canary Traffic Splitting**

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: payment-service
  namespace: production
spec:
  hosts:
  - payment-service
  http:
  # Canary route: 5% to v1.2.1, 95% to v1.2.0
  - match:
    - sourceLabels:
        version: canary
    route:
    - destination:
        host: payment-service
        subset: v1-2-1
      weight: 100
  # Regular route: split traffic
  - route:
    - destination:
        host: payment-service
        subset: v1-2-0
      weight: 95
    - destination:
        host: payment-service
        subset: v1-2-1
      weight: 5
    timeout: 10s
    retries:
      attempts: 3
      perTryTimeout: 3s

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: payment-service
  namespace: production
spec:
  host: payment-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1000
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
  subsets:
  - name: v1-2-0
    labels:
      version: v1.2.0
  - name: v1-2-1
    labels:
      version: v1.2.1
```

### ASCII Diagrams

**Progressive Delivery Timeline with Automated Decisions**

```
Hours:  0    1    2    3    4    5    6
Canary: 0%   ├─5%─│ 10% │ 25% │ 50% │ 100%
Status: ───────────────────────────────────
        DEPLOY
           │
           ├─(30s monitoring interval)────┐
           │ Error rate: 0.3% [✓]          │
           │ P99 latency: 95ms [✓]         │
           │ VERDICT: Ready for next step  │
           └──────► Increase to 5%
                        │
                   (30s monitoring)
                        │
           ┌────────────┴─────────────┐
           │ Error rate: 0.6% [✓]     │
           │ Custom metric SLA: OK [✓]│
           │ VERDICT: Ready           │
           └────► Increase to 10%
                       │
                  (30s monitoring)
                       │
         ┌─────────────┴──────────────┐
         │ Error rate: 2.1% [✗]       │
         │ > Threshold 2.0%           │
         │ VERDICT: ROLLBACK!         │
         └────► Traffic back to 10%
                (Wait 5min for stability)
                       │
              ┌────────┴───────────┐
              │ Error rate: 0.5% [✓]
              │ VERDICT: Resume   │
              └─► Increase to 25%
                      ... continue
```

**Feature Flag Visibility Across Services**

```
User Session Tracking:
┌────────────────────────────────────────────┐
│ User ID: 12345                             │
│ Feature payment_v3 enabled: YES (10% rollout)
│                                            │
│ HTTP Requests:                             │
│                                            │
│ 1. GET /cart                               │
│    [Service: Cart]                         │
│    [Feature: payment_v3]                   │
│    [Value]: False (user 12345 not in 10%)  │
│    [Result]: Show PaymentV2 option ────────┼──► User sees option A
│                                            │
│ 2. POST /checkout                          │
│    [Service: Checkout]                     │
│    [Feature: payment_v3]                   │
│    [Value]: False                          │
│    [Result]: Process with PaymentV2        │
│                                            │
│ [Later: Flag percentage increased to 15%]  │
│                                            │
│ 3. POST /cart/update                       │
│    [Service: Cart]                         │
│    [Feature: payment_v3]                   │
│    [Value]: True (now in 15%)    ─────────┼──► User sees option B
│    [Result]: Show PaymentV3 option         │
└────────────────────────────────────────────┘
```

---

## Security in GitOps

### Textual Deep Dive: Secrets, RBAC, and GitOps-Specific Threats

**Internal Mechanism: Three-Layer Security Model**

```
Layer 1: Git Access Control
         ├─ Who can commit to main?
         ├─ Who can approve PRs?
         └─ Who can access Git repository?

Layer 2: Secrets Protection
         ├─ Never store secrets in Git
         ├─ Use external secret provider
         ├─ Inject at deployment time
         └─ Audit access to secrets

Layer 3: Cluster Access Control
         ├─ RBAC: pod can only access its own secrets
         ├─ Network policies: restrict traffic
         ├─ Pod security policies: block privileged pods
         └─ Admission webhooks: validate deployments
```

**Threat Model: GitOps-Specific Attack Vectors**

1. **Git Repository Compromise**
   - Attacker gains access to Git repo
   - Commits malicious manifest (new pod with backdoor)
   - GitOps agent auto-applies (bad commit = bad cluster)
   - Impact: Full cluster compromise

   **Protection:**
   - Branch protection (require reviews, status checks pass)
   - Signed commits (verify code came from trusted developer)
   - Audit logging (who committed what, when)
   - Limited write access (only limited developers)

2. **Secrets Exposure in Git**
   - Developer accidentally commits `.env` with API key
   - Key in Git forever (even if removed, Git history persists)
   - Attacker finds old commit, extracts key
   - Key used to access external services

   **Protection:**
   - Pre-commit hooks scanning for secrets
   - `git-secrets` tool blocks high-entropy strings
   - Sealed-secrets: encrypt secrets before commit
   - External secret provider (Vault, AWS Secrets Manager)

3. **Supply Chain Attack: Image Digest Mismatch**
   - Attacker gains access to registry
   - Pushes malicious image with same tag (v1.2.3)
   - GitOps manifest pulls image by tag (not digest)
   - Bad image deployed

   **Protection:**
   - Immutable tags (commit SHA = immutable reference)
   - Image signing (cosign verifies signature)
   - Manifests reference by digest (image@sha256:abc...)
   - Policy engines block unsigned images

4. **RBAC Bypass**
   - Service account with excessive permissions
   - Pod compromised; attacker uses service account
   - Can access all secrets in cluster
   - Lateral movement to other services

   **Protection:**
   - Least-privilege RBAC (each pod gets minimum needed)
   - Network policies restrict pod-to-pod communication
   - Workload identity (pods assume AWS/Azure role)
   - Secret encryption at rest in etcd

**Architecture Role: Secret Injection Pipeline**

```
Secure Secret Flow (CORRECT):
┌──────────────────────────────────────────┐
│ External Secret Provider                 │
│ (AWS Secrets Manager, HashiCorp Vault)   │
│ ├─ database_password = "xyz123"          │
│ └─ api_key = "secret_key_abc"            │
└────────┬─────────────────────────────────┘
         │ (Secure API call)
         │ (Credentials in ServiceAccount token)
         │
    ┌────▼──────────────────────────────┐
    │ External Secrets Operator          │
    │ (Watches ExternalSecret CRD)       │
    │                                    │
    │ Fetches from provider periodically │
    │ Stores in Kubernetes Secret        │
    └────┬───────────────────────────────┘
         │
    ┌────▼────────────────────────┐
    │ Kubernetes Secret (encrypted)│
    │ data:                        │
    │   database_password: [enc]   │
    │   api_key: [enc]             │
    └────┬────────────────────────┘
         │ (Mounted as volume or env var)
         │
    ┌────▼────────────────┐
    │ Pod at Runtime       │
    │ Env vars injected:   │
    │ DB_PASSWORD=xyz123   │
    │ API_KEY=secret_abc   │
    └──────────────────────┘
```

**Common Pitfalls**

❌ **Storing Secrets in Git**
→ Even in `.gitignore`, still accessible in history
→ Fix: External secret provider; never commit

❌ **Service Account with Cluster-Admin**
→ Compromised pod can access everything
→ Fix: RBAC with least-privilege per pod

❌ **Image Pulled by Tag Only**
→ Tag can be re-assigned to different image
→ Fix: Reference by digest (image@sha256:...)

❌ **No Image Validation**
→ Unsigned, unscanned images deployable
→ Fix: Admission webhook blocks unsigned images

### Practical Code Examples

**ExternalSecrets Operator Setup**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets
  namespace: external-secrets

---
# IAM Role for EKS (uses IRSA: IAM Role for Service Accounts)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/ExternalSecretsRole

---
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets
  namespace: production
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
  name: api-credentials
  namespace: production
spec:
  refreshInterval: 1h  # Rotate every hour
  secretStoreRef:
    name: aws-secrets
    kind: SecretStore
  
  target:
    name: api-credentials  # Kubernetes Secret name
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        database_url: "postgresql://{{ .db_user }}:{{ .db_password }}@db.internal:5432/app"
  
  data:
  - secretKey: db_user
    remoteRef:
      key: db/user
  - secretKey: db_password
    remoteRef:
      key: db/password

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      serviceAccountName: external-secrets-sa
      containers:
      - name: api
        image: myregistry.azurecr.io/api:v1.2.3
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: api-credentials
              key: database_url
```

**Image Signature Verification with Cosign and Kyverno**

```yaml
# Install Kyverno policy engine
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-images
spec:
  validationFailureAction: enforce  # Block violations
  background: false
  
  rules:
  - name: verify-image-signature
    match:
      resources:
        kinds:
        - Pod
        - Deployment
    verifyImages:
    - imageReferences:
      - "myregistry.azurecr.io/*"
      attestations:
      - name: check-signature
        attestationFormat: cosign
        attestationLocation: ghcr.io/myorg/sbom
      # Public key for verification
      publicKeys: |
        -----BEGIN PUBLIC KEY-----
        MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
        -----END PUBLIC KEY-----

---
# Example: Deploy signed image (allowed)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trusted-app
spec:
  template:
    spec:
      containers:
      # Image signature verified by Kyverno
      - name: app
        image: myregistry.azurecr.io/api@sha256:abc123...  # Using digest, not tag
```

**RBAC: Least Privilege Service Accounts**

```yaml
# Payment Service: minimal permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-service
  namespace: production

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: payment-service-role
  namespace: production
rules:
# Only read own namespace's configmaps and secrets
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
  resourceNames: ["payment-config", "payment-secrets"]  # Only specific resources

# Read-only access to status subresource
- apiGroups: [""]
  resources: ["pods/status"]
  verbs: ["get"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payment-service-binding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: payment-service-role
subjects:
- kind: ServiceAccount
  name: payment-service
  namespace: production
```

### ASCII Diagrams

**Secret Security Layers**

```
THREAT VECTORS and DEFENSES:

┌─────────────────────────────────────────────────────────┐
│ LAYER 1: Git Repository                               │
│                                                        │
│ Threat: Attacker commits malicious manifest            │
│ Defense:                                               │
│  ├─ Branch protection (require reviews)               │
│  ├─ Signed commits (GPG signatures)                   │
│  ├─ Limited write access (4 admins only)              │
│  └─ Audit logging (log every commit)                  │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│ LAYER 2: Secrets Protection                            │
│                                                        │
│ Threat: Secrets accidentally committed to Git          │
│ Defense:                                               │
│  ├─ Pre-commit hooks (detect secrets)                 │
│  ├─ Sealed-secrets (encrypt before commit)            │
│  ├─ External provider (Vault, AWS SecretsManager)     │
│  └─ No secrets in manifests ever                      │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│ LAYER 3: Deployment Validation                         │
│                                                        │
│ Threat: Malicious image or non-compliant manifest      │
│ Defense:                                               │
│  ├─ Image signing verification (Cosign)               │
│  ├─ Image vulnerability scanning (Trivy, Aqua)        │
│  ├─ Policy enforcement (Kyverno, OPA)                 │
│  └─ Admission webhooks (validate before apply)        │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│ LAYER 4: Runtime Security                              │
│                                                        │
│ Threat: Pod gets compromised; uses service account     │
│ Defense:                                               │
│  ├─ RBAC: per-pod minimum permissions                 │
│  ├─ Network policies: restrict pod communication      │
│  ├─ Pod Security Policy: block privileged              │
│  ├─ Runtime monitoring (Falco)                        │
│  └─ Workload Identity (assume IAM role)               │
└─────────────────────────────────────────────────────────┘
```

---

## Policy as Code

### Textual Deep Dive: Automated Compliance and Guardrails

**Internal Mechanism: Declarative Policy Evaluation**

Traditional: Humans review manifests for compliance
```
Developer writes K8s manifest
  ↓
Developer submits PR
  ↓
[Human reviewer manually checks]
  - Is CPU request set? 
  - Is image registry allowed?
  - Are security contexts correct?
  ↓
Reviewer approves/rejects (subjective, inconsistent)
```

Policy as Code: Automated rules
```
Rego policy (OPA):
----
allow {
  input.spec.containers[0].resources.requests.cpu  # CPU request must exist
  input.spec.containers[0].securityContext.runAsNonRoot == true
  startswith(input.spec.containers[0].image, "myregistry.azurecr.io/")
}
----

Developer writes manifest
  ↓
Commit → CI Pipeline → Policy check
  ├─ Parse manifest → JSON
  ├─ Evaluate against policies
  ├─ PASS: merge allowed
  ├─ FAIL: block merge with clear errors
  ↓
Consistent, objective enforcement
```

**Architecture Role: Policy Enforcement Points**

```
Multiple Enforcement Levels:

Level 1: Pre-Commit (Developer Machine)
│        ├─ git hook: git-secrets, kubeval
│        └─ Fail locally before pushing
│
Level 2: CI Pipeline (Pre-Merge)
│        ├─ Policy evaluation (OPA, Kyverno)
│        ├─ Fail PR if non-compliant
│        └─ Require fix before merge
│
Level 3: GitOps Agent (Pre-Apply)
│        ├─ Validating webhook
│        ├─ Reject non-compliant manifests
│        └─ Prevent deployment of policy violators
│
Level 4: Runtime (Pod Creation)
│        ├─ Mutating webhook (fix violations auto)
│        ├─ Pod Security Policies
│        └─ Example: auto-add security context if missing
```

**Production Usage Patterns**

**Pattern 1: Shift-Left Enforcement (Fail Fast)**
```
Mandatory policies apply during development:
├─ All pods must have resource requests/limits
├─ All images must come from approved registries
├─ Database access requires secrets (not env vars)
├─ Liveness/readiness probes required for web services

Developer violates: Image from Docker Hub (not approved registry)
├─ Local git hook catches (fail immediately)
├─ Developer fixes locally (< 1 minute)
├─ vs catching in PR review (wasted review time)
├─ vs catching in production (outage!)
```

**Pattern 2: Progressive Severity (Warnings → Errors)**
```
Deprecation phase:
├─ New policy: images must be signed
├─ Severity: WARN (existing images exempt)
├─ Grace period: 3 months
├─ Alerts: daily reports of unsigned images

Enforcement phase:
├─ Upgrade policy: images must be signed
├─ Severity: FAIL (block deployments)
├─ Exempt: legacy apps (grace period extension)
├─ Delete unsigned images from registry
```

**Pattern 3: Compliance Audit Trail**
```
Policy:
├─ rule_id: PCI-DSS-2.2.4
├─ description: Workload must encrypt data in transit (TLS)
├─ verification: manifest includes tls in Ingress
├─ auditor: annual compliance review

Deployment:
├─ Evaluated: 2024-03-18 10:30:00Z
├─ Result: PASS (Ingress tls: true)
├─ Evidence: stored in audit log
├─ Auditor can later retrieve: which version, when, who approved

Compliance report: "100% of workloads compliant with TLS requirement"
```

### Practical Code Examples

**OPA (Open Policy Agent) with Kyverno**

```rego
# payment-service-policies.rego
# Enforcement rules for payment service

package kubernetes

deny[msg] {
    input.request.kind.kind == "Deployment"
    not input.request.object.spec.template.spec.containers[0].resources.limits.cpu
    msg := "CPU limits required"
}

deny[msg] {
    input.request.kind.kind == "Deployment"
    not input.request.object.spec.template.spec.containers[0].resources.requests.memory
    msg := "Memory requests required"
}

deny[msg] {
    input.request.kind.kind == "Pod"
    not startswith(input.request.object.spec.containers[0].image, "myregistry.azurecr.io/")
    msg := sprintf("Image not from approved registry: %v", [input.request.object.spec.containers[0].image])
}

deny[msg] {
    name := input.request.object.metadata.name
    name_parts := split(name, "-")
    count(name_parts) < 2
    msg := "Pod name must follow convention: <service>-<component>"
}
```

**Kyverno ClusterPolicy for Enforcement**

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: enforce  # Block if fails
  background: true  # Apply to existing resources too
  
  rules:
  - name: check-cpu-memory
    match:
      resources:
        kinds:
        - Deployment
        - StatefulSet
        - DaemonSet
    validate:
      message: "CPU and memory limits required"
      pattern:
        spec:
          template:
            spec:
              containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"

---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-registry-prefix
spec:
  validationFailureAction: enforce
  rules:
  - name: check-registry
    match:
      resources:
        kinds:
        - Pod
        - Deployment
    validate:
      message: "Images must come from myregistry.azurecr.io"
      pattern:
        spec:
          containers:
          - image: "myregistry.azurecr.io/*"

---
apiaVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-securitycontext
spec:
  validationFailureAction: audit  # Warn only; don't block
  background: false
  
  rules:
  - name: add-security-context
    match:
      resources:
        kinds:
        - Deployment
    mutate:  # Auto-fix violations
      patchStrategicMerge:
        spec:
          template:
            spec:
              securityContext:
                runAsNonRoot: true
                fsReadOnlyRootFilesystem: true
                capabilities:
                  drop:
                  - ALL
```

**Compliance Report Generation Script**

```bash
#!/bin/bash
# generate-compliance-report.sh: Audit policy compliance

set -euo pipefail

REPORT_FILE="compliance-report-$(date +%Y%m%d).md"
NAMESPACE="production"

echo "# Compliance Report" > "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "## Policy Violations" >> "$REPORT_FILE"

# Check for pods without resource limits
echo "### Missing Resource Limits" >> "$REPORT_FILE"
kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] | 
  select(.spec.containers[0].resources.limits == null) |
  "\(.metadata.name): NO LIMITS"' >> "$REPORT_FILE"

# Check for non-compliant images
echo "### Non-Approved Registry Images" >> "$REPORT_FILE"
kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] |
  select(.spec.containers[0].image | startswith("myregistry") | not) |
  "\(.metadata.name): \(.spec.containers[0].image)"' >> "$REPORT_FILE"

# Check for privileged pods
echo "### Privileged Containers" >> "$REPORT_FILE"
kubectl get pods -n $NAMESPACE -o json | jq -r '.items[] |
  select(.spec.containers[0].securityContext.privileged == true) |
  "\(.metadata.name): PRIVILEGED"' >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "## Summary" >> "$REPORT_FILE"
echo "Total violations: $(grep -c ":" "$REPORT_FILE" || echo 0)" >> "$REPORT_FILE"

echo "✓ Report generated: $REPORT_FILE"
cat "$REPORT_FILE"
```

### ASCII Diagrams

**Policy Enforcement Timeline**

```
Development Phase:
┌─────────────────────────────────────────┐
│ Developer writes manifest               │
└────────────────┬────────────────────────┘
                 │
             git commit
                 │
┌────────────────▼────────────────────────┐
│ Pre-commit Hook (Local Machine)         │
│  - Run: kubeval, kube-linter, OPA      │
│  - Check: resource limits, image source│
└────────────────┬────────────────────────┘
                 │ ✓ PASS
                 │
             git push
                 │
┌────────────────▼────────────────────────┐
│ CI Pipeline (GitHub/GitLab)             │
│  - Lint: kubeval, OPA policies          │
│  - Security: trivy, cosign verify       │
│  - Review: static analysis              │
└────────────────┬────────────────────────┘
                 │ ✓ PASS
                 │
            Create PR
                 │
┌────────────────▼────────────────────────┐
│ Peer Review + Policy Report             │
│  - Show: policy compliance matrix       │
│  - Ask: reviewers approve               │
└────────────────┬────────────────────────┘
                 │ ✓ Approved
                 │
            Merge to main
                 │

Deployment Phase:
┌────────────────▼────────────────────────┐
│ GitOps Agent (Argo CD)                  │
│  - Read manifests from Git              │
│  - Submit to Kubernetes API             │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│ Validating Webhook (Kyverno/OPA/AdmissionController)
│  - Validate: all policies               │
│  - Enforce: BLOCK if violation          │
│  - Mutate: auto-fix simple violations   │
└────────────────┬────────────────────────┘
                 │ ✓ PASS
                 │
        ┌────────▼────────────┐
        │ Pod Created         │
        │ Compliant           │
        └─────────────────────┘
```

---

## Observability in GitOps

### Textual Deep Dive: Monitoring Sync State and Health

**Internal Mechanism: Three-Pillar Observability**

Traditional monitoring focuses on application (Logs, Metrics, Traces).

GitOps adds infrastructure-level observability:
```
Pillar 1: Application Metrics
├─ Error rate, latency, throughput
├─ Business metrics (checkout success rate)
└─ Collected via Prometheus, Datadog, New Relic

Pillar 2: Infrastructure Health
├─ Pod ready status
├─ Node capacity
├─ Persistent volume usage
└─ Kubernetes metrics server

Pillar 3: GitOps Sync Status (NEW)
├─ Is cluster state = Git state?
├─ Last sync time
├─ Drift detection (manual changes)
├─ Sync errors or warnings
└─ Custom resource status (Argo Application CRD)
```

**What Syncing Means:**
```
Desired State (Git):
├─ deployment.yaml: replicas=3, image=v1.2.3
├─ service.yaml: port=8080
└─ kustomization.yaml: applies overlays

Actual State (Cluster):
├─ Running: 3 pods, image=v1.2.3
├─ Service listening on port 8080
└─ Network policies enforced

SYNCED: Desired == Actual
OUT_OF_SYNC: Desired != Actual (drift detected)
```

**Architecture Role: Holistic Health Scoring**

```
GitOps Health = Sync Status + Pod Health + App Metrics

Example:
┌────────────────────────────────────────┐
│ Application: payment-service           │
├────────────────────────────────────────┤
│ Sync Status: IN_SYNC ✓                 │
│ └─ Git state matches cluster state     │
│                                        │
│ Pod Health: 3/3 READY ✓                │
│ └─ All pods running, passing readiness│
│                                        │
│ Application Metrics: HEALTHY ✓         │
│ └─ Error rate: 0.1% (< 1% threshold) │
│ └─ P99 latency: 95ms (< 200ms)       │
│ └─ Throughput: 1000 req/s             │
│                                        │
│ OVERALL STATUS: FULLY HEALTHY ✓        │
└────────────────────────────────────────┘

Contrasts with:
┌────────────────────────────────────────┐
│ Application: legacy-service            │
├────────────────────────────────────────┤
│ Sync Status: OUT_OF_SYNC ⚠             │
│ └─ Manual SSH changed config           │
│                                        │
│ Pod Health: 2/3 READY ⚠                │
│ └─ One pod pending (image pull error) │
│                                        │
│ Application Metrics: DEGRADED ✗        │
│ └─ Error rate: 5% (> 1% threshold)   │
│                                        │
│ OVERALL STATUS: REQUIRES ATTENTION     │
└────────────────────────────────────────┘
```

**Production Usage Patterns**

**Pattern 1: Drift Detection and Alerting**
```
GitOps Reconciliation Loop:
T+0min:  Check Git state vs cluster state
         › Desired: replicas=3
         › Actual: replicas=3
         › Status: IN_SYNC

T+5min:  Human manually scales down:
         kubectl scale deployment payment-service --replicas=2
         › Actual: replicas=2 (manual change)
         › Drift introduced

T+30min: GitOps reconciliation detects drift
         › Desired: replicas=3
         › Actual: replicas=2
         › Status: OUT_OF_SYNC
         › Alert: "Configuration drift detected"
         › Auto-remediate: scale back to 3

T+31min: State re-synced
         › Actual: replicas=3
         › Status: IN_SYNC
```

**Pattern 2: Deployment Progress Tracking**

```
Deploy new version (image v1.2.3):
├─ T+0s:   Commit to Git → GitOps detects change
├─ T+10s:  New pod created, pulling image
├─ T+20s:  Pod starting, health checks pending
├─ T+30s:  Pod ready, traffic shifting
├─ T+40s:  Old pod terminating
├─ T+50s:  Deployment complete
│
Status (viewable in dashboard):
├─ Sync Phase: Syncing
├─ Condition: ProgressDeadlineExceeded (if > 10min)
├─ Observed Gen: matches latest spec gen
├─ Resource Tree: shows pod status
│  ├─ New Pod: Running ✓
│  ├─ Old Pod: Terminating →
│  └─ Old Pod: Terminated ✓
```

**Common Pitfalls**

❌ **Alerting on Drift Without Context**
→ Alert: "Drift detected: 1 replica missing"
→ Cause: Intentional manual scale for testing
→ Fix: Manual approval before auto-remediate; context-aware alerts

❌ **Metrics from Pre-Scale Period**
→ Alert: "95th percentile latency: 500ms"
→ Cause: Alert looks at 10-min window including scale-down period
→ Fix: Skip metrics during known scaling events; adjust thresholds

❌ **Ignoring Sync Warnings**
→ Application synced but with warnings
→ Example: "Unable to create pod; insufficient resources"
→ Fix: Treat warnings as actionable (humans required)

### Practical Code Examples

**Prometheus + Argo CD Sync Metrics**

```yaml
# Argo CD ServiceMonitor for Prometheus scraping
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argo-cd-metrics
  namespace: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
    interval: 30s

---
# Prometheus rules: Alert on sync failures
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: argocd-alerts
  namespace: monitoring
spec:
  groups:
  - name: argocd
    rules:
    - alert: ArgocdSyncFailed
      expr: argocd_app_status_sync_failed > 0
      for: 5m
      annotations:
        summary: "Argo CD application sync failed"
        description: "Application {{ $labels.name }} in namespace {{ $labels.namespace }} failed to sync"
    
    - alert: ArgocdAppOutOfSync
      expr: argocd_app_status_out_of_sync > 0
      for: 30m  # Allow 30 min drift before alerting
      annotations:
        summary: "Application drifted from Git"
        description: "Application {{ $labels.name }} out-of-sync for >30 minutes"
    
    - alert: ArgocdSyncDuration
      expr: histogram_quantile(0.99, argocd_app_sync_duration_seconds) > 600
      annotations:
        summary: "Sync taking too long (>10 min)"
        description: "Application {{ $labels.name }} sync duration exceeds 600 seconds"

---
# Grafana Dashboard ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-dashboard
  namespace: monitoring
data:
  argocd-dashboard.json: |
    {
      "dashboard": {
        "title": "ArgoCD Sync Status",
        "panels": [
          {
            "title": "Sync Status",
            "targets": [
              {
                "expr": "argocd_app_status_sync_total{sync_status=\"Synced\"}"
              }
            ],
            "type": "graph"
          },
          {
            "title": "Drift Detection",
            "targets": [
              {
                "expr": "argocd_app_status_out_of_sync"
              }
            ]
          }
        ]
      }
    }
```

**Custom Sync Status Controller**

```bash
#!/bin/bash
# monitor-gitops-sync.sh: Track Argo CD application sync status

set -euo pipefail

NAMESPACE="argocd"
ALERT_THRESHOLD_MIN=30

echo "Checking GitOps sync status..."

# Get all Argo CD applications
kubectl get applications -n $NAMESPACE -o json | jq -r '.items[] | .metadata.name' |
while read app; do
  SYNC_STATUS=$(kubectl get app $app -n $NAMESPACE -o jsonpath='{.status.sync.status}')
  LAST_SYNC=$(kubectl get app $app -n $NAMESPACE -o jsonpath='{.status.operationState.finishedAt}')
  HEALTH=$(kubectl get app $app -n $NAMESPACE -o jsonpath='{.status.health.status}')
  
  # Parse last sync time and calculate age
  LAST_SYNC_EPOCH=$(date -d "$LAST_SYNC" +%s 2>/dev/null || echo 0)
  NOW_EPOCH=$(date +%s)
  AGE_MIN=$(( (NOW_EPOCH - LAST_SYNC_EPOCH) / 60 ))
  
  # Output status
  echo "App: $app"
  echo "  Sync Status: $SYNC_STATUS"
  echo "  Health: $HEALTH"
  echo "  Last Sync: ${AGE_MIN}m ago"
  
  # Alert conditions
  if [ "$SYNC_STATUS" != "Synced" ]; then
    echo "  ⚠ WARNING: Out of sync"
  fi
  
  if [ "$AGE_MIN" -gt "$ALERT_THRESHOLD_MIN" ]; then
    echo "  ⚠ WARNING: Last sync >$ALERT_THRESHOLD_MIN minutes ago"
  fi
  
  if [ "$HEALTH" != "Healthy" ]; then
    echo "  ⚠ WARNING: Health status not healthy"
  fi
  
  echo ""
done
```

### ASCII Diagrams

**GitOps Observability Dashboard**

```
┌─────────────────────────────────────────────────────────────────┐
│ GitOps Observability Dashboard                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ SYNC STATUS BY ENVIRONMENT:                                    │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            │
│ │ Dev Cluster  │ │Staging Clus. │ │ Prod Cluster │            │
│ ├──────────────┤ ├──────────────┤ ├──────────────┤            │
│ │ IN_SYNC ✓    │ │IN_SYNC ✓     │ │OUT_OF_SYNC ⚠ │            │
│ │ Health: OK   │ │Health: OK    │ │Health: WARN  │            │
│ │ Last: 1m ago │ │Last: 5m ago  │ │Last: 45m ago │            │
│ └──────────────┘ └──────────────┘ └──────────────┘            │
│                                                                 │
│ SYNC DURATION (Last 7 Days):                                   │
│ ┌────────────────────────────────────────────────────────────┐│
│ │                                                          ││
│ │     Avg: 45s              Max: 120s              Min: 20s││
│ │  ════════════════════════════════════════════════════════││
│ │  Mon Tue Wed Thu Fri Sat Sun                             ││
│ │  45s 48s 52s 44s 46s 43s 41s                             ││
│ └────────────────────────────────────────────────────────────┘│
│                                                                 │
│ TOP ALERTS (Last 24h):                                         │
│ ┌────────────────────────────────────────────────────────────┐│
│ │ 1. ArgocdAppOutOfSync (payment-service) - 45m ago        ││
│ │    Status: IN_PROGRESS (remediating)                     ││
│ │ 2. ArgocdSyncDuration (auth-service) - 2h ago           ││
│ │    Status: RESOLVED                                      ││
│ │ 3. DriftDetected (legacy-app) - 5h ago                  ││
│ │    Status: ACKNOWLEDGED (manual change approved)         ││
│ └────────────────────────────────────────────────────────────┘│
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Multi-cluster Deployments

### Textual Deep Dive: Federation and Application Promotion

**Internal Mechanism: Cluster Fleet Management**

Single cluster architecture:
```
One Kubernetes cluster (us-east-1)
├─ Compute: 30 nodes
├─ Replicas: 3-5 per service
└─ Failure mode: region-wide outage = global downtime
```

Multi-cluster architecture:
```
┌──────────────────────────────────────────────┐
│ Global Load Balancer (GeoDNS)                │
│ Routes traffic to nearest healthy cluster    │
└─────────┬──────────────────────┬─────────────┘
          │                      │
    ┌─────▼─────────┐    ┌──────▼──────────┐
    │ US East 1     │    │ EU West 1       │
    │ 8 services    │    │ 8 services      │
    │ v1.2.3 active │    │ v1.2.3 active   │
    └───────────────┘    └─────────────────┘
          │                      │
          └──────┬───────────────┘
                 │
            ┌────▼────┐
            │ AP South │
            │ Standby  │
            │ v1.2.2   │
            └──────────┘
```

**Cluster Federation Topologies**

1. **Hub-and-Spoke**
   ```
   Central Hub (Central US):
   ├─ Policy enforcement
   ├─ Secret storage
   └─ Gitops controller
         │
         ├─ Spoke 1 (US East)
         ├─ Spoke 2 (EU West)
         └─ Spoke 3 (AP South)
   
   Used for: Centralized governance + distributed deployment
   ```

2. **Peer-to-Peer**
   ```
   Each cluster autonomous:
   ├─ Cluster 1: owns regions [US]
   ├─ Cluster 2: owns regions [EU]
   ├─ Cluster 3: owns regions [AP]
   
   Cross-cluster service discovery
   
   Used for: High autonomy + cost optimization
   ```

3. **Cluster-Per-Environment**
   ```
   Dev cluster (local development)
   Staging cluster (mirror production)
   Production-Primary cluster (active)
   Production-Secondary cluster (standby/failover)
   
   Used for: Environment isolation + rapid deployment
   ```

**Application Promotion Workflow**

```
Developer commits code
         │
         ▼
CI Build & Test
         │
    ┌────▼────┐
    │ Dev Env  │ (auto-deploy)
    │ Cluster  │
    └────┬────┘
         │ Smoke tests pass?
    ┌────▼────┐
    │ Stage    │ (manual approval)
    │ Cluster  │
    └────┬────┘
         │ Load tests pass?
    ┌────▼────┐
    │ Prod     │ (scheduled)
    │ Cluster  │
    └──────────┘
```

### Practical Code Examples

**KubeFed: Kubernetes Cluster Federation**

```yaml
# Install KubeFed
# kubeadm join automatically handles cluster federation

apiVersion: types.kubefed.io/v1beta1
kind: KubeFedCluster
metadata:
  name: cluster-us-east
  namespace: kube-federation-system
spec:
  apiEndpoint: https://us-east.kubernetes.example.com
  caBundle: |
    -----BEGIN CERTIFICATE-----
    ... CA certificate ...
    -----END CERTIFICATE-----
  secretRef:
    name: cluster-us-east-credentials  # ServiceAccount token

---
# Federated Deployment: Deploy to multiple clusters simultaneously
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: payment-service
  namespace: production
spec:
  template:
    metadata:
      name: payment
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: payment-service
      template:
        metadata:
          labels:
            app: payment-service
        spec:
          containers:
          - name: payment
            image: myregistry.azurecr.io/payment:v1.2.3
  
  placement:
    clusters:
    - name: cluster-us-east
    - name: cluster-eu-west
    - name: cluster-ap-south

  overrides:
  # Cluster-specific overrides
  - clusterName: cluster-us-east
    clusterOverrides:
    - path: /spec/replicas
      value: 5  # More capacity in primary region
  
  - clusterName: cluster-ap-south
    clusterOverrides:
    - path: /spec/replicas
      value: 2  # Less capacity in secondary

---
# Federated Service: Cross-cluster DNS resolution
apiVersion: types.kubefed.io/v1beta1
kind: FederatedService
metadata:
  name: payment
  namespace: production
spec:
  template:
    metadata:
      name: payment
    spec:
      type: ClusterIP
      ports:
      - port: 80
        targetPort: 8080
      selector:
        app: payment-service
  
  placement:
    clusters:
    - name: cluster-us-east
    - name: cluster-eu-west
    - name: cluster-ap-south

---
# IngressDNS: Geographic routing
apiVersion: ingressdns.kubefed.io/v1beta1
kind: IngressDNS
metadata:
  name: payment-service
  namespace: production
spec:
  serviceName: payment
  recordType: CNAME
  geoProximityLocation: true  # Route based on user geography
```

**Argocd ApplicationSet for Multi-Cluster Promotion**

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: payment-service-rollout
spec:
  generators:
  # Generate applications for each environment
  - list:
      elements:
      - cluster: dev
        env: development
        approval: automatic
      - cluster: staging
        env: staging
        approval: manual
      - cluster: prod-primary
        env: production
        approval: manual
      - cluster: prod-secondary
        env: production
        approval: manual

  template:
    metadata:
      name: "payment-service-{{ cluster }}"
    spec:
      project: default
      
      source:
        repoURL: https://github.com/myorg/payment-service
        path: "k8s/{{ env }}"
        targetRevision: main
      
      destination:
        server: "https://{{ cluster }}.kubernetes.example.com:6443"
        namespace: payment
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true

---
# Manual promotion step: Argo Workflow
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: payment-service-promotion
spec:
  entrypoint: promote-to-prod
  
  templates:
  - name: promote-to-prod
    steps:
    - - name: test-staging
        template: run-tests
        arguments:
          parameters:
          - name: environment
            value: staging
    
    - - name: manual-approval
        template: approval-gate
        arguments:
          parameters:
          - name: message
            value: "Ready to promote to production?"
    
    - - name: deploy-prod-primary
        template: promote-cluster
        arguments:
          parameters:
          - name: target-cluster
            value: prod-primary
    
    - - name: monitor-prod-primary
        template: monitor-health
        arguments:
          parameters:
          - name: cluster
            value: prod-primary
          - name: duration
            value: "300"  # Monitor for 5 minutes
    
    - - name: deploy-prod-secondary
        template: promote-cluster
        arguments:
          parameters:
          - name: target-cluster
            value: prod-secondary
  
  - name: run-tests
    inputs:
      parameters:
      - name: environment
    script:
      image: myregistry.azurecr.io/test-runner:latest
      command: [bash]
      source: |
        echo "Running tests in {{ inputs.parameters.environment }}"
        ./run-integration-tests.sh --environment={{ inputs.parameters.environment }}
  
  - name: approval-gate
    inputs:
      parameters:
      - name: message
    script:
      image: alpine:latest
      command: [echo]
      args: ["{{ inputs.parameters.message }}"]
  
  - name: promote-cluster
    inputs:
      parameters:
      - name: target-cluster
    script:
      image: bitnami/kubectl:latest
      command: [bash]
      source: |
        kubectl patch application payment-service-{{ inputs.parameters.target-cluster }} \
          --type='json' \
          -p='[{"op": "replace", "path": "/spec/source/targetRevision", "value":"main"}]'
  
  - name: monitor-health
    inputs:
      parameters:
      - name: cluster
      - name: duration
    script:
      image: myregistry.azurecr.io/monitor:latest
      command: [bash]
      source: |
        end=$((SECONDS + {{ inputs.parameters.duration }}))
        while [ $SECONDS -lt $end ]; do
          kubectl get pods -n payment --context={{ inputs.parameters.cluster }}
          sleep 30
        done
```

### ASCII Diagrams

**Multi-Cluster Failover Topology**

```
Internet Traffic (User Requests)
           │
           ▼
    ┌──────────────┐
    │ GeoDNS / GSLB│
    │ (Global LB)  │
    └──────┬────┬──┴──────┐
           │    │         │
        (Healthy zones are active; unhealthy routed away)
           │    │         │
    ┌──────▼─┐ ┌┴────────┐ ┌─────────────┐
    │US-EAST │ │EU-WEST  │ │AP-SOUTHEAST │
    │ ACTIVE │ │ACTIVE   │ │ (STANDBY)   │
    │        │ │         │ │             │
    │ 5 pods │ │ 5 pods  │ │ 1 pod       │
    │ v1.2.3 │ │ v1.2.3  │ │ v1.2.3 cold │
    │ 100%   │ │ 100%    │ │ 0% traffic  │
    │Health: │ │Health:  │ │Health: OK   │
    │HEALTHY │ │HEALTHY  │ │             │
    └────┬───┘ └────┬────┘ └─────┬───────┘
         │          │             │
         └──────────┼─────────────┘
                    │
            (Shared Database)
         PostgreSQL RDS Multi-AZ
         ├─ Replication: US → EU (async)
         ├─ Failover: automatic if US down
         └─ Standby: AP can promote if needed

FAILURE SCENARIO:
┌─────────────────────────────────────┐
│ US-EAST cluster becomes unhealthy   │
│ (Pod crash loop, network partition) │
└─────────────────────────────────────┘
         │
         ▼
    ┌──────────────┐
    │ GeoDNS GSLB  │
    │ Detects: US  │
    │ unhealthy    │
    │ (via health  │
    │  probe fails)│
    └──────┬───────┘
           │
    Route traffic:
    50% → US-EAST (attempting recovery)
    50% → EU-WEST (absorb traffic)
       ├─ New connections → EU
       ├─ Existing → gradually close
       └─ Client retry → EU succeeds
           │
           ▼
    MTTR: <30 seconds
    Users affected: <5% (session loss possible)
```

*(Continuing with remaining sections...)*

---

## CICD + GitOps Integration

### Textual Deep Dive: Pipeline-Driven GitOps Triggers

**Internal Mechanism: Declarative Deployment Automation**

Pure CI/CD (Push-based):
```
Code commit → Build → Test → RUN: kubectl apply
Pipeline responsible for deployment
Risk: Pipeline has cluster credentials; if compromised = cluster compromised
```

Pure GitOps (Pull-based):
```
Code commit → Build → Test → Update Git reference
GitOps agent watches Git → Deploys automatically
Risk: Git credentials; if compromised = deployment issue (not cluster access)
```

**Integrated Approach: CI/CD Triggers GitOps**

```
Code commit → Build → Test → Pipeline updates Git
                                       │
                                       ▼
                            Git commit: update image tag
                                       │
                                       ▼
                         GitOps agent detects → deploys
                                       │
                                       ▼
                         Git remains source of truth
                         Pipeline doesn't need cluster credentials
                         GitOps handles deployment
```

**Architecture Role: Separation of Concerns**

```
CI/CD Pipeline:
├─ Responsibilities: Build, test, publish artifacts
├─ Credentials: Registry push token, repo write access
├─ Scope: Code → Artifacts (no deployment)

GitOps Agent:
├─ Responsibilities: Watch Git, sync cluster
├─ Credentials: Git read, cluster apply
├─ Scope: Git → Cluster state (no building)
```

### Practical Code Examples

**GitHub Actions: Build and Request GitOps Update**

```yaml
name: Build and Deploy

on:
  push:
    branches:
      - main

env:
  REGISTRY: myregistry.azurecr.io
  IMAGE: myregistry.azurecr.io/api-server

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      packages: write
      id-token: write  # For OIDC token
    
    steps:
    - uses: actions/checkout@v3
    
    # Build container image
    - name: Build image
      run: |
        docker build -t ${{ env.IMAGE }}:${{ github.sha }} .
    
    # Push to registry (via OIDC, no secrets stored!)
    - name: Login to registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ secrets.ACR_USERNAME }}
        password: ${{ secrets.ACR_PASSWORD }}
    
    - name: Push image
      run: |
        docker push ${{ env.IMAGE }}:${{ github.sha }}
        docker tag ${{ env.IMAGE }}:${{ github.sha }} ${{ env.IMAGE }}:latest
        docker push ${{ env.IMAGE }}:latest
    
    # Trigger GitOps deployment
    - name: Update GitOps repository
      env:
        GITHUB_TOKEN: ${{ secrets.GITOPS_REPO_TOKEN }}
        GITOPS_REPO: github.com/myorg/infrastructure
      run: |
        # Clone GitOps repo
        git clone https://${{ env.GITHUB_TOKEN }}@${{ env.GITOPS_REPO }} /tmp/gitops
        cd /tmp/gitops
        
        # Update image tag in Kustomization
        cd overlays/prod/api-server
        kustomize edit set image myregistry.azurecr.io/api-server=${{ env.IMAGE }}:${{ github.sha }}
        
        # Commit and push
        git config user.email "github-actions@example.com"
        git config user.name "GitHub Actions"
        git add kustomization.yaml
        git commit -m "Update api-server image to ${{ github.sha }}"
        git push origin main
        
        echo "GitOps updated; ArgoCD will sync within 30 seconds"
```

**Webhook-Triggered Deployment Update**

```python
#!/usr/bin/env python3
# webhook-handler.py: Triggered by registry webhook when new image pushed

from fastapi import FastAPI, Request
import json
import subprocess
import logging

app = FastAPI()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.post("/webhooks/image-pushed")
async def image_pushed(request: Request):
    """
    Webhook triggered by container registry (Docker Hub, ACR, GCR)
    when new image is pushed
    """
    payload = await request.json()
    
    # Extract image details
    image = payload['repository']['repo_name']
    tag = payload['push_data']['tag']
    digest = payload['push_data']['image_id']  # SHA256 digest
    
    logger.info(f"New image pushed: {image}:{tag} (digest: {digest})")
    
    # Map image to service
    service_mapping = {
        'myorg/api-server': 'api-server',
        'myorg/payment': 'payment-service',
        'myorg/auth': 'auth-service',
    }
    
    service = service_mapping.get(image)
    if not service:
        logger.error(f"Unknown image: {image}")
        return {"status": "ignored"}
    
    # Only deploy if tag is release version (not 'latest')
    if tag == 'latest' or not tag.startswith('v'):
        logger.info(f"Skipping non-release tag: {tag}")
        return {"status": "skipped"}
    
    try:
        # Update GitOps repository
        update_gitops_manifest(service, tag, digest)
        logger.info(f"Updated GitOps for {service}:{tag}")
        
        return {"status": "updated", "service": service, "version": tag}
    
    except Exception as e:
        logger.error(f"Failed to update GitOps: {e}")
        return {"status": "failed", "error": str(e)}, 500

def update_gitops_manifest(service, tag, digest):
    """Commit updated image reference to Git"""
    
    # Clone repo (or use existing cache)
    subprocess.run([
        'git', 'clone',
        'https://github.com/myorg/infrastructure.git',
        f'/tmp/gitops-{service}'
    ], check=True)
    
    repo_path = f'/tmp/gitops-{service}'
    
    # Update Kustomization
    kustomization_path = f'{repo_path}/overlays/prod/{service}/kustomization.yaml'
    
    with open(kustomization_path, 'r') as f:
        content = f.read()
    
    # Update image with both tag and digest (digest = immutable reference)
    content = content.replace(
        f'image: myregistry.azurecr.io/{service}:*',
        f'image: myregistry.azurecr.io/{service}:{tag}@{digest}'
    )
    
    with open(kustomization_path, 'w') as f:
        f.write(content)
    
    # Git commit and push
    subprocess.run(['git', '-C', repo_path, 'config', 'user.email', 'automation@example.com'], check=True)
    subprocess.run(['git', '-C', repo_path, 'config', 'user.name', 'Automation'], check=True)
    subprocess.run(['git', '-C', repo_path, 'add', '.'], check=True)
    subprocess.run([
        'git', '-C', repo_path,
        'commit', '-m', f'Update {service} to {tag} (digest: {digest})'
    ], check=True)
    subprocess.run(['git', '-C', repo_path, 'push', 'origin', 'main'], check=True)
```

### ASCII Diagrams

**CI/CD + GitOps Integration Flow**

```
┌────────────────────────────────────────────────────┐
│ Developer: git push to main                        │
└─────────────┬──────────────────────────────────────┘
              │
         ┌────▼─────────────────┐
         │ GitHub Webhook       │
         │ (Push event)         │
         └────┬─────────────────┘
              │
         ┌────▼──────────────────┐
         │ CI Pipeline Starts    │
         │ (GitHub Actions)      │
         └────┬──────────────────┘
              │
        ┌─────┴─────────────┐
        │                   │
    ┌───▼────┐         ┌────▼──────┐
    │Build   │         │Test       │
    │Node.js │         │npm test   │
    │Docker  │         │jest       │
    │image   │         │coverage   │
    └───┬────┘         └────┬──────┘
        │                   │
        └─────────┬─────────┘
                  │ All tests pass ✓
                  │
        ┌─────────▼──────────────┐
        │ Push Image             │
        │ Registry: ACR          │
        │ Image: api-server:abc3 │
        │ Digest: sha256:xyz...  │
        └─────────┬──────────────┘
                  │
        ┌─────────▼─────────────────┐
        │ Registry Webhook          │
        │ (Image Pushed)            │
        └─────────┬─────────────────┘
                  │
        ┌─────────▼──────────────────────┐
        │ Webhook Handler Update Git     │
        │ (Automation script)            │
        │ • Clone infrastructure repo    │
        │ • Update kustomization        │
        │ • image: api-server:abc3      │
        │ • git commit + push           │
        └─────────┬───────────────────────┘
                  │
        ┌─────────▼──────────────────┐
        │ Git Repository Updated     │
        │ infrastructure/overlays/   │
        │ prod/api-server/           │
        │ kustomization.yaml         │
        └─────────┬──────────────────┘
                  │
        ┌─────────▼───────────────────┐
        │ GitOps Agent (Argo CD)      │
        │ Detects change via polling  │
        │ (or webhook trigger)        │
        │ Syncs cluster to Git state  │
        └─────────┬───────────────────┘
                  │
        ┌─────────▼──────────────────────┐
        │ Kubernetes Deployment Updated  │
        │ • Rolling update in progress   │
        │ • Pods updating: api-server:abc3
        │ • Health checks passing        │
        │ • Service routing traffic      │
        └────────────────────────────────┘

Total time: Build (3min) + Sync (1min) = 4 minutes code to prod
No manual deployment; fully automated
Git remains single source of truth
```

---

## Self Service Platforms

### Textual Deep Dive: Developer-Focused Deployment Workflows

**Internal Mechanism: Abstraction Over Complexity**

Raw Kubernetes deployment:
```
Developer writes:
├─ Deployment manifests (YAML)
├─ Service definitions
├─ Ingress rules
├─ RBAC policies
├─ Network policies
├─ Pod disruption budgets
├─ Vertical pod autoscaling

Learning curve: Steep
Common mistakes: Forgotten resource limits, bad readiness probes, etc.
Onboarding time: 2-3 weeks
```

Self-service platform:
```
Developer fills form:
├─ Service name
├─ Container image
├─ Environment variables
├─ Replicas/scaling policy
├─ Health check endpoints

Platform generates:
├─ All manifests with guardrails
├─ Sensible defaults
├─ Policy enforcement built-in
├─ Pre-validated configurations

Learning curve: Shallow  (Web form instead of YAML)
Onboarding time: 1 day
Quality: Higher (platform prevents common mistakes)
```

**Architecture Role: Guardrails and Defaults**

```
Developer Intent:
"I want to deploy payment-service"
        │
        ▼
┌─────────────────────────────────┐
│ Self-Service Portal             │
│ ├─ Web form with validation     │
│ ├─ Dropdown: staging or prod    │
│ ├─ Input: image tag             │
│ ├─ Limit: replicas 1-10         │
│ ├─ Memory: preset options only  │
│ │  (256Mi, 512Mi, 1Gi, 2Gi)    │
│ └─ Submit                       │
└─────────────┬───────────────────┘
              │
        ┌─────▼──────────┐
        │ Validation     │
        ├─ Image exists? │
        ├─ Tag released? │
        ├─ Quota free?   │
        └─────┬──────────┘
              │
        ┌─────▼──────────────────────┐
        │ Generate K8s Manifest      │
        │ (From Jinja template)      │
        │ ├─ Health checks added     │
        │ ├─ Resource limits set     │
        │ ├─ Security contexts added │
        │ ├─ RBAC auto-provisioned   │
        │ └─ Policies pre-applied    │
        └─────┬──────────────────────┘
              │
        ┌─────▼──────────────────┐
        │ Create PR in GitOps repo│
        │ (For review + audit)   │
        │                        │
        │ Title:                 │
        │ "Deploy payment-service│
        │  to staging"           │
        │                        │
        │ Description:           │
        │ "Image: v2.1"          │
        │ "Replicas: 3"          │
        │ "Memory: 512Mi"        │
        └─────┬──────────────────┘
              │
        ┌─────▼───────────────────┐
        │ Code Review Required?   │
        ├─ Staging: maybe (team)  │
        ├─ Prod: yes (platform)   │
        └─────┬───────────────────┘
              │
        ┌─────▼──────────────────┐
        │ Merge → Git commit      │
        │ GitOps agent syncs      │
        │ Done!                  │
        └────────────────────────┘
```

**Golden Pipelines: Standardized Workflows**

```
Organization Standard:
"Deployment is: Build → Test → Staging → (Approval) → Production"

Golden Pipeline Template:
├─ Stage 1: Build (Docker)
├─ Stage 2: Unit & Integration Tests
├─ Stage 3: Security Scanning (SAST, container scan)
├─ Stage 4: Deploy to Staging (automatic)
├─ Stage 5: Smoke Tests in Staging
├─ Stage 6: Load Testing (optional)
├─ Stage 7: Manual Approval (production gate)
├─ Stage 8: Deploy to Production
└─ Stage 9: Smoke Tests in Production

Teams don't reinvent: just use the template
Consistency: all teams follow same workflow
Compliance: policies enforced at pipeline level
Reduced toil: template handles plumbing
```

### Practical Code Examples

**Backstage Portal Configuration**

```yaml
# Backstage is open-source developer portal
# Enables self-service deployments, documentation, etc.

apiVersion: backstage.io/v1alpha1
kind: ComponentTemplate
metadata:
  name: python-microservice
  title: Python Microservice
  description: Deploy a Python microservice with sensible defaults
spec:
  owner: platform-engineering
  type: service
  
  parameters:
  - title: Service Details
    required:
    - name
    - description
    properties:
      name:
        title: Service Name
        type: string
        pattern: ^[a-z0-9-]+$
        description: "Kebab-case service name (e.g., payment-processor)"
      
      description:
        title: Description
        type: string
      
      owner:
        title: Team Owner
        type: string
        enum:
          - platform-team
          - backend-team
          - payments-team
  
  - title: Deployment Configuration
    properties:
      environment:
        title: Target Environment
        type: string
        enum:
          - staging
          - production
        default: staging
      
      pythonVersion:
        title: Python Version
        type: string
        enum:
          - "3.9"
          - "3.10"
          - "3.11"
        default: "3.11"
      
      replicas:
        title: Number of Replicas
        type: integer
        minimum: 1
        maximum: 10
        default: 3
      
      memory:
        title: Memory per Pod
        type: string
        enum:
          - "256Mi"
          - "512Mi"
          - "1Gi"
          - "2Gi"
        default: "512Mi"
      
      cpu:
        title: CPU per Pod
        type: string
        enum:
          - "100m"
          - "250m"
          - "500m"
          - "1000m"
        default: "250m"
  
  steps:
  # Create repository
  - id: fetch-base
    name: Fetch Base
    action: fetch:template
    input:
      url: ./templates/python-microservice
      targetPath: ./site/${{ parameters.name }}
      values:
        name: ${{ parameters.name }}
        description: ${{ parameters.description }}
        owner: ${{ parameters.owner }}
  
  # Register in Backstage catalog
  - id: publish
    name: Publish
    action: publish:github
    input:
      allowedHosts: ['github.com']
      description: "This is ${{ parameters.name }}"
      repoUrl: github.com?owner=myorg&repo=${{ parameters.name }}
      repoVisibility: private
  
  # Create deployment manifest in GitOps repo
  - id: create-deployment
    name: Create Deployment Manifest
    action: github:branch:create
    input:
      repoUrl: github.com/myorg/infrastructure
      branchName: "feature/${{ parameters.name }}-init"
      title: "Auto: Initialize ${{ parameters.name }} deployment"
      description: |
        Bootstrapped via Backstage self-service portal
        Service: ${{ parameters.name }}
        Owner: ${{ parameters.owner }}
        Environment: ${{parameters.environment}}
      fileOperations:
      - action: create
        path: "overlays/${{ parameters.environment }}/${{ parameters.name }}/kustomization.yaml"
        content: |
          apiVersion: kustomize.config.k8s.io/v1beta1
          kind: Kustomization
          
          namespace: ${{ parameters.name }}
          
          resources:
          - ../../base/python-app
          
          replicas:
          - name: app
            count: ${{ parameters.replicas }}
          
          images:
          - name: python-app
            newTag: latest
          
          commonLabels:
            app: ${{ parameters.name }}
            owner: ${{ parameters.owner }}
      
      - action: create
        path: "overlays/${{ parameters.environment }}/${{ parameters.name }}/patches.yaml"
        content: |
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: app
          spec:
            template:
              spec:
                containers:
                - name: app
                  resources:
                    requests:
                      memory: ${{ parameters.memory }}
                      cpu: ${{ parameters.cpu }}
                    limits:
                      memory: ${{ parameters.memory }}
                      cpu: ${{ parameters.cpu }}
  
  # Output summary
  - id: log
    name: Log Message
    action: debug:log
    input:
      message: |
        ✓ Service created: ${{ parameters.name }}
        ✓ Repository: https://github.com/myorg/${{ parameters.name }}
        ✓ Next steps:
          1. Clone repository: git clone https://github.com/myorg/${{ parameters.name }}
          2. Update source code
          3. Push to trigger CI/CD
          4. Deployment created automatically in ${{ parameters.environment }}
```

**Self-Service Deployment Script**

```bash
#!/bin/bash
# deploy-self-service.sh: CLI for self-service deployments

set -euo pipefail

INTERACTIVE="${1:-}"

if [ -z "$INTERACTIVE" ]; then
  # Interactive mode
  echo "=== Self-Service Deployment Portal ==="
  echo ""
  
  # Prompt for inputs
  read -p "Service name: " SERVICE_NAME
  read -p "Container image tag: " IMAGE_TAG
  read -p "Target environment (staging/prod): " ENVIRON
  read -p "Number of replicas (1-10): " REPLICAS
  read -p "Team owner: " OWNER
else
  # CLI mode: read from arguments
  SERVICE_NAME="${2:-}"
  IMAGE_TAG="${3:-}"
  ENVIRON="${4:-}"
  REPLICAS="${5:-1}"
  OWNER="${6:-}"
fi

# Validation
[ -z "$SERVICE_NAME" ] && echo "Error: service name required" && exit 1
[ -z "$IMAGE_TAG" ] && echo "Error: image tag required" && exit 1
[ -z "$ENVIRON" ] && echo "Error: environment required" && exit 1

# Sanitize inputs
SERVICE_NAME=$(echo "$SERVICE_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

echo ""
echo "Creating deployment:"
echo "  Service: $SERVICE_NAME"
echo "  Image: myregistry.azurecr.io/$SERVICE_NAME:$IMAGE_TAG"
echo "  Environment: $ENVIRON"
echo "  Replicas: $REPLICAS"
echo "  Owner: $OWNER"
echo ""

# Clone infrastructure repo
TMP_DIR=$(mktemp -d)
git clone --depth=1 https://github.com/myorg/infrastructure "$TMP_DIR"

cd "$TMP_DIR"

PATH_OVERLAY="overlays/$ENVIRON/$SERVICE_NAME"
mkdir -p "$PATH_OVERLAY"

# Create kustomization
cat > "$PATH_OVERLAY/kustomization.yaml" <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: $SERVICE_NAME

bases:
- ../../base/microservice

replicas:
- name: app
  count: $REPLICAS

images:
- name: microservice
  newTag: $IMAGE_TAG

commonLabels:
  app: $SERVICE_NAME
  owner: $OWNER
  env: $ENVIRON
EOF

# Create patch for resources
cat > "$PATH_OVERLAY/deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    metadata:
      labels:
        version: "$IMAGE_TAG"
    spec:
      containers:
      - name: app
        resources:
          requests:
            memory: 512Mi
            cpu: 250m
          limits:
            memory: 1Gi
            cpu: 500m
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          failureThreshold: 2
EOF

# Commit and create PR
git config user.email "selfservice@example.com"
git config user.name "Self-Service Deployment"

git checkout -b "feature/$SERVICE_NAME-$ENVIRON"
git add "overlays/$ENVIRON/$SERVICE_NAME/"
git commit -m "Deploy $SERVICE_NAME:$IMAGE_TAG to $ENVIRON

Service: $SERVICE_NAME
Image: myregistry.azurecr.io/$SERVICE_NAME:$IMAGE_TAG
Environment: $ENVIRON
Team: $OWNER
Replicas: $REPLICAS

Generated via self-service portal"

git push origin "feature/$SERVICE_NAME-$ENVIRON"

echo ""
echo "✓ Deployment configuration created"
echo "✓ Branch: feature/$SERVICE_NAME-$ENVIRON"
echo "✓ Create PR at: https://github.com/myorg/infrastructure/pull/new/feature/$SERVICE_NAME-$ENVIRON"
echo ""
echo "Next:"
echo "  1. Review deployment manifest"
echo "  2. Merge PR to deploy"
echo "  3. GitOps will sync automatically"
```

---

## Disaster Recovery with GitOps

### Textual Deep Dive: Cluster Bootstrap and State Recovery

**Internal Mechanism: Infrastructure from Git**

Traditional DR (pre-GitOps):
```
Cluster disasters:
├─ Etcd database corrupted
├─ All Kubernetes nodes down
├─ External API misconfigured

Recovery:
├─ Restore from backups (if available)
├─ Restore typically = 4-6 hours
├─ Backup outdated (RPO = 24 hours)
├─ Data loss = 24 hours of configurations
```

GitOps DR:
```
Cluster disaster
        │
        ▼
Git has authoritative state
(code, manifests, configurations)
        │
        ▼
Bootstrap new cluster
├─ kubectl apply -f gitops/
├─ GitOps agent starts watching Git
├─ Agent syncs Git state → cluster
        │
        ▼
New cluster matches old cluster
RTO: 20-30 minutes (cluster provisioning + sync)
RPO: < 5 minutes (last Git commit)
```

**Architecture Role: Infrastructure Immutability**

```
Disaster Recovery Hierarchy:

Level 1: Git Repository (SOURCE OF TRUTH)
├─ Immutable (write-once-read-many)
├─ Backed up daily to cold storage
├─ Geo-redundant replication
└─ Infinite retention

Level 2: Kubernetes Cluster
├─ Compute (stateless)
├─ Storage (for databases, etc.)
├─ Easily recreated from Git
└─ If lost: provision new, apply Git state

Level 3: External Services (Database, Cache)
├─ Separately backed up
├─ Restore separately if needed
├─ Cluster references via secrets/config
```

**Production Usage Patterns**

**Pattern 1: Cluster Disaster Recovery**

```
Scenario: Kubernetes control plane corruption
├─ API server unresponsive
├─ Etcd database corrupted
├─ Node OS issues

Requirements:
├─ RTO (Recovery Time Objective): < 30 minutes
├─ RPO (Recovery Point Objective): < 5 minutes
├─ Minimal data loss

Recovery Steps:
1. Provision new cluster (cloud provider API = 5 min)
   ├─ Same region or different region
   ├─ Same node specs (terraform module)
2. Bootstrap GitOps (kubeadm + argo install = 2 min)
3. Sync Git state (argocd app sync = 3 min)
4. Validate: health checks passing, services responding
   Total: ~15 minutes
```

**Pattern 2: Regional Failure Recovery**

```
Active: us-east-1
Standby: us-west-2 (cold)

On us-east-1 failure:
1. DNS failover (Route53 health checks detect)
2. Traffic routed to us-west-2
3. Warm up us-west-2 (minutes)
4. Provision on us-west-2 from Git
Total: < 1 minute traffic failover + full recovery< 10 min
```

### Practical Code Examples

**Terragrunt Infrastructure as Code Bootstrap**

```hcl
# terragrunt.hcl: Root configuration for multi-region setup

remote_state {
  backend = "azurerm"
  config = {
    resource_group_name  = "terraform-state"
    storage_account_name = "tfstateaccount"
    container_name       = "state"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite"
  contents = <<-EOF
    terraform {
      required_version = ">= 1.0"
      required_providers {
        azurerm = {
          source = "hashicorp/azurerm"
          version = "~> 3.0"
        }
        kubernetes = {
          source = "hashicorp/kubernetes"
          version = "~> 2.0"
        }
      }
    }

    provider "azurerm" {
      features {}
      subscription_id = var.subscription_id
    }

    provider "kubernetes" {
      host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
      client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_certificate)
      client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].client_key)
      cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
    }
  EOF
}

# Cluster configuration modules
locals {
  environment = "production"
  region = "us-east-1"
}

---
# clusters/us-east-1/terragrunt.hcl
terraform {
  source = "cloud::${get_repo_root()}/terraform-modules/aks"
}

inputs = {
  cluster_name       = "k8s-us-east-1"
  location           = "East US"
  node_count         = 3
  node_vm_size       = "Standard_D4s_v3"
  kubernetes_version = "1.28"
  
  # Enable GitOps
  enable_gitops = true
  gitops_repo   = "https://github.com/myorg/infrastructure"
  gitops_branch = "main"
  
  # Networking
  vnet_cidr  = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
  
  # Addons
  addons = {
    ingress_nginx    = true
    cert_manager     = true
    metric_server    = true
    kube_prometheus  = true
    argocd           = true
  }
}

---
# clusters/us-west-2/terragrunt.hcl (Standby cluster)
terraform {
  source = "cloud::${get_repo_root()}/terraform-modules/aks"
}

inputs = {
  cluster_name       = "k8s-us-west-2"
  location           = "West US"
  node_count         = 1      # Minimal: scale up as needed
  node_vm_size       = "Standard_D2s_v3"
  kubernetes_version = "1.28"
  
  enable_gitops = true
  gitops_repo   = "https://github.com/myorg/infrastructure"
  gitops_branch = "main"
  
  # Lower cost: fewer nodes
  autoscale_min_count = 1
  autoscale_max_count = 5
}
```

**Disaster Recovery Automation Script**

```bash
#!/bin/bash
# disaster-recovery.sh: Automated cluster recovery

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
NEW_CLUSTER_REGION="${1:-us-west-2}"
NEW_CLUSTER_NAME="k8s-dr-$(date +%s)"

echo "=== Starting Disaster Recovery ==="
echo "New cluster region: $NEW_CLUSTER_REGION"
echo ""

# Step 1: Provision new cluster from Terraform
echo "[1/5] Provisioning new cluster from IaC..."
cd "$REPO_ROOT/terraform/clusters/$NEW_CLUSTER_REGION"

terraform init
terraform apply -auto-approve -var="cluster_name=$NEW_CLUSTER_NAME"

NEW_KUBECONFIG=$(terraform output -raw kubeconfig_path)
export KUBECONFIG="$NEW_KUBECONFIG"

echo "✓ Cluster provisioned: $NEW_CLUSTER_NAME"
echo "✓ Kubeconfig: $NEW_KUBECONFIG"

# Step 2: Wait for cluster readiness
echo "[2/5] Waiting for cluster to be ready..."
until kubectl get nodes | grep -q "Ready"; do
  echo "Waiting for nodes to be ready..."
  sleep 10
done

kubectl wait --for=condition=Ready nodes --all --timeout=300s
echo "✓ All nodes ready"

# Step 3: Install GitOps controller
echo "[3/5] Installing ArgoCD (GitOps controller)..."
kubectl create namespace argocd
kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml -n argocd

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
echo "✓ ArgoCD installed"

# Step 4: Create main ApplicationSet (GitOps will handle everything else)
echo "[4/5] Creating ApplicationSet..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: github-credentials
  namespace: argocd
type: Opaque
stringData:
  password: $GITHUB_TOKEN
  username: git
---
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: infrastructure
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - env: production
        path: overlays/prod
  
  template:
    metadata:
      name: infrastructure-{{ env }}
    spec:
      project: default
      source:
        repoURL: https://github.com/myorg/infrastructure
        path: {{ path }}
        targetRevision: main
      
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
EOF

echo "✓ ApplicationSet created"

# Step 5: Validate recovery
echo "[5/5] Validating recovery..."
sleep 30  # Allow argocd to detect and sync

# Check sync status
SYNC_STATUS=$(kubectl get applicationset infrastructure -n argocd -o jsonpath='{.status.conditions[0].status}')
echo "ApplicationSet sync status: $SYNC_STATUS"

# Check running pods
echo ""
echo "Running workloads:"
kubectl get pods --all-namespaces --field-selector=status.phase=Running

echo ""
echo "=== Disaster Recovery Complete ==="
echo "Cluster: $NEW_CLUSTER_NAME"
echo "Region: $NEW_CLUSTER_REGION"
echo "Status: All workloads restored from Git"
echo ""
echo "Next steps:"
echo "1. Validate application functionality"
echo "2. Restore databases (separate from cluster)"
echo "3. Update DNS to point to new cluster"
echo "4. Decommission old cluster when safe"
```

**Backup and Restore Script Using Velero**

```bash
#!/bin/bash
# velero-backup-restore.sh: Backup cluster using Velero, restore if disaster

set -euo pipefail

NAMESPACE="velero"
BACKUP_LOCATION="azure-backup"  # Azure Blob Storage
RESTORE_FROM="${1:-latest}"

# Install Velero (runs once)
install_velero() {
  velero install \
    --provider azure \
    --plugins velero/velero-plugin-for-azure:v1.8.0 \
    --bucket velero-backups \
    --secret-file ./credentials-velero \
    --namespace $NAMESPACE
}

# Create scheduled backup
backup_cluster() {
  velero schedule create daily \
    --schedule="0 2 * * *" \
    --include-namespaces "*" \
    --exclude-namespaces kube-system,kube-node-lease \
    --ttl 720h  # Keep 30 days
  
  echo "✓ Scheduled daily backups at 2 AM"
}

# Restore from backup
restore_cluster() {
  RESTORE_NAME="restore-$(date +%s)"
  
  velero restore create $RESTORE_NAME \
    --from-backup $RESTORE_FROM \
    --namespace-mappings default:default \
    --wait
  
  # Monitor restore
  velero restore describe $RESTORE_NAME
  velero restore logs $RESTORE_NAME
  
  echo "✓ Restore completed: $RESTORE_NAME"
}

# Main menu
case "${1:-backup}" in
  install)
    install_velero
    ;;
  backup)
    backup_cluster
    ;;
  restore)
    restore_cluster
    ;;
  list)
    velero backup get
    ;;
  *)
    echo "Usage: $0 {install|backup|restore|list}"
    exit 1
esac
```

### ASCII Diagrams

**Disaster Recovery Timeline: Git-Based Recovery**

```
11:30 AM: DISASTER STRIKES
          Kubernetes control plane corrupted
          ├─ API server down
          ├─ Etcd unrecoverable
          └─ Cluster unreachable

11:31 AM: Detect Incident
          ├─ Monitoring alert: API server unreachable
          ├─ Page on-call engineer
          └─ Incident channels opened

11:35 AM: Start Recovery
          ├─ Decision: provision new cluster
          ├─ Execute: terraform apply [us-west-2]
          └─ Cloud provider: spinning up nodes (5 min)

11:40 AM: Cluster Online
          ├─ Kubernetes API responding
          ├─ Nodes registering
          ├─ Control plane migration complete
          └─ Install GitOps agent (2 min)

11:42 AM: GitOps Agent Active
          ├─ Argo CD installed
          ├─ Watch: Git repository
          ├─ Detect: applications to deploy
          └─ Begin sync: (3 min)

11:45 AM: Full Recovery
          ├─ All deployments synced from Git
          ├─ Pods running (health checks passing)
          ├─ Services responding to traffic
          ├─ DNS updated (Route53 failover)
          └─ RECOVERY COMPLETE

Total Recovery Time: 15 minutes
Data Loss: ~2 minutes (last Git commit)
User Impact: DNS failover + app startup = <5 min reachability

COMPARISON:
┌─────────────────────────┬──────────┬────────┐
│ Recovery Method         │ RTO      │ RPO    │
├─────────────────────────┼──────────┼────────┤
│ Manual (no plan)        │ 4-6 hrs  │ 24 hrs │
│ VM snapshot restore     │ 1-2 hrs  │ 1 hr   │
│ Velero backup restore   │ 30 min   │ 1 hr   │
│ GitOps (Infrastructure) │ 15 min   │ 5 min  │
└─────────────────────────┴──────────┴────────┘

GitOps minimal RTO & RPO!
```

---

## Document Metadata and Summary

- **Audience**: Senior DevOps Engineers (5-10+ years experience)
- **Version**: 3.0
- **Last Updated**: March 2026
- **Status**: COMPLETE (all 20 foundational + advanced sections)
- **Total Content**: 25,000+ words
- **Sections Included**: 20 major sections with deep dives, practical examples, ASCII diagrams

### Complete Section List

**Foundation (Sections 1-3)**
1. Introduction, Overview, Business Impact
2. Foundational Concepts, Terminology, Architecture
3. Common Misunderstandings, Best Practices Framework

**Core Technologies (Sections 4-8)**
4. Cost Optimization (pipeline efficiency, serverless, resource management)
5. Pipeline Security (secrets, RBAC, artifact integrity, compliance)
6. Production Failures (detection, remediation, case studies)
7. Scaling CI/CD (multi-region, distributed, cloud-native)
8. GitOps Best Practices (repository structure, deployment strategies)

**Advanced Implementation (Sections 9-15)**
9. GitOps Tools Comparison (Argo CD, Flux, Jenkins X)
10. GitOps for Legacy Applications (modernization strategy)
11. GitOps for MLOps (model versioning, training pipelines)
12. Progressive Delivery (canary, feature flags, A/B testing)
13. Security in GitOps (secrets, RBAC, policy enforcement)
14. Policy as Code (OPA, Kyverno, automation, compliance)
15. Observability in GitOps (monitoring, sync status, drift detection)

**Enterprise Patterns (Sections 16-20)**
16. Multi-cluster Deployments (federation, promotion, failover)
17. CICD + GitOps Integration (pipeline-driven deployments)
18. Self-Service Platforms (Backstage, golden pipelines, guardrails)
19. Disaster Recovery with GitOps (cluster bootstrap, state recovery)
20. Interview Questions (10 senior-level assessment questions)

### Key Strategic Insights

1. **CI/CD → GitOps Evolution**: Shift from push-based pipelines to pull-based Git-driven synchronization
2. **Cost Optimization**: 50-70% reduction through intelligent parallelization, caching, and resource management
3. **Security Posture**: Defense-in-depth with signed commits, image verification, policy enforcement, RBAC
4. **Operational Reliability**: Observability-first with automated remediation, progressive delivery, feature flags
5. **Scaling Strategy**: Multi-region federation, distributed execution, cluster federation for horizontal scale
6. **GitOps Architecture**: Git as single source of truth; GitOps agents ensure cluster convergence
7. **Tool Landscape**: 
   - **Argo CD**: Best for centralized visibility, multi-cluster; ideal for platform teams
   - **Flux**: Best for distributed autonomy, cost-sensitive; ideal for independent teams
   - **Jenkins X**: Best for integrated end-to-end; traditional Jenkins organizations
8. **Legacy Modernization**: Phased approach with containerization, state externalization, backward-compatible schemas
9. **MLOps Integration**: Extend GitOps to model versioning, training pipelines, serving infrastructure
10. **Enterprise Patterns**: Multi-cluster federation, self-service portals, disaster recovery automation

### Practical Implementation Paths

**Path 1: Start with GitOps (Greenfield)**
1. Choose GitOps tool (Argo CD for visibility, Flux for autonomy)
2. Structure repository (base + overlays pattern)
3. Implement CI → Git trigger pattern
4. Add progressive delivery (canary, feature flags)
5. Enforce policies (OPA/Kyverno)
6. Multi-cluster expansion
Timeline: 3-6 months to production maturity

**Path 2: Add GitOps to Existing CI/CD**
1. Assess current pipeline (inventory bottlenecks)
2. Containerize workloads (Docker, dependencies)
3. Write Kubernetes manifests (start simple)
4. Install GitOps controller (Argo/Flux)
5. Transition: CI builds → updates Git → GitOps deploys
6. Improve observability (add monitoring, drift detection)
Timeline: 6-12 months for full adoption

**Path 3: Legacy App Modernization**
1. Assessment phase: document current deployment
2. Containerization: create Dockerfile, test locally
3. State externalization: move state to managed services
4. Kubernetes manifests: write deploy configs
5. Database refactoring: backward-compatible migrations
6. GitOps adoption: infrastructure as code
Timeline: 12-24 months (phased per service)

### Common Pitfalls to Avoid

❌ **Assuming GitOps === Just Using Git**
→ GitOps requires pull-based agents, declarative state, continuous reconciliation

❌ **Secrets in Git (Even with gitignore)**
→ Use external secret providers (Vault, AWS SM, Azure KV); never commit

❌ **One Size Fits All Tool**
→ Argo CD, Flux, Jenkins X serve different needs; choose based on org structure

❌ **Ignoring Observability**
→ Deploy without monitoring = flying blind; observability non-negotiable

❌ **Skipping Security Layers**
→ Image signing, RBAC, policy enforcement, secrets management all critical

❌ **Monolithic Deployments**
→ Avoid all-or-nothing deployments; use canary, blue-green, feature flags

❌ **Manual Changes (Configuration Drift)**
→ All changes through Git; GitOps auto-corrects drift; humans never SSH prod

---

## Hands-On Scenarios

These situations require troubleshooting production issues under time pressure while customers are affected. Each scenario includes step-by-step diagnosis and resolution.

### Scenario 1: Automatic Rollback Failure in Canary Deployment

**Problem:** Deployment to 5% canary shows 2% error rate (below threshold but legitimate corruption issue). Automatic rollback fails because database schema changed, not reverted.

**Root Cause Analysis:**
- App v2.1.0 expects database schema v2.1.0
- Deployment happened before schema migration
- Rollback to v2.0.0 succeeds, but database still at v2.1.0
- v2.0.0 code references non-existent columns → crashes

**Resolution Steps (Timeline: 30 minutes):**
1. Identify mismatch (5 min): Check app version vs DB schema version
2. Run pending migrations (10 min): liquibase update to v2.1.0
3. Error rate drops as DB schema matches app expectations
4. Continue canary progression to production

**Lessons:**
- Database migrations must precede app deployment
- App code must handle both old and new schema (backward compat)
- Rollback scenarios must include database considerations

---

### Scenario 2: Multi-Cluster Cascade Failure

**Problem:** Master cluster fails (network partition). All worker clusters lose auth services. Within 30s, all dependent microservices timeout attempting cross-cluster auth. RTO breaches 5min SLA; actual 45 minutes due to cascading effects.

**Root Cause:**
- Master cluster network unreachable
- IRSA (workload identity) credentials invalidated
- Worker clusters unable to assume IAM roles
- Service-to-service calls with auth dependencies fail atomically

**Resolution Steps (Timeline: 45 minutes):**
1. Detect master failure immediately (automated mon alert)
2. Isolate services; gracefully degrade (return 503, don't hang)
3. Provision replacement master cluster (15 min with Terraform)
4. Restore etcd from snapshot (5 min)
5. Worker clusters auto-recover and re-authenticate
6. Full recovery as KubeFed sync resumes

**Lessons:**
- Master cluster is SPOF in hub-and-spoke; plan multi-master
- Graceful degradation beats silent timeouts
- Test failover regularly (DR drills catch gaps)
- Monitor master availability from every worker cluster

---

### Scenario 3: GitOps Drift Detection Failure

**Problem:** Three nodes reboot (VM maintenance). Kubelet starts pods from cached images (old version). Git declares v2.5.0 deployed, but pods running v2.4.0. GitOps agent doesn't correct (custom health webhook muted alerts).

**Root Cause:**
- Node cache-hit during kubelet restart
- Custom health assessment webhook disabled alerts
- GitOps syncPolicy didn't have aggressive drift correction

**Resolution Steps (Timeline: 20 minutes):**
1. Detect drift: argocd app diff shows image mismatch
2. Trigger sync: argocd app sync (rolling update to v2.5.0)
3. Monitor: kubectl rollout status (wait for pods ready)
4. Prevent: Enable aggressive drift detection, remove custom webhook

**Lessons:**
- Force imagePullPolicy=Always (prevent cache hits)
- Aggressive drift detection + auto-correction non-negotiable
- Custom health assessments risky (prefer Kubernetes native probes)
- Block manual mutations (only GitOps agent modifies resources)

---

### Scenario 4: Cross-Cluster Promotion Confusion

**Problem:** Staging passes tests (v2.3.0 approved). Ops team asleep; prod approval delayed. Meanwhile staging advances to v2.3.1. When prod approval finally comes through, Git has v2.3.1 in staging but prod approval targets v2.3.0. Versions mismatch.

**Root Cause:**
- Implicit promotion (staging main → prod main)
- Timing drift (async approval process)
- No explicit version lock during promotion

**Resolution Steps (Timeline: infrastructure refactoring):**
1. Use explicit promotion branches (not implicit main branch)
2. Lock versions during promotion (explicit commit with audit trail)
3. Automate approval checks (no human waiting)

**Lessons:**
- Separate approval gates per environment (staging auto, prod manual)
- Create promotion branches not main-to-main merges
- Audit trail essential (who approved, what version, when)

---

### Scenario 5: Performance Regression Undetected by Load Tests

**Problem:** Payment checkout v2.4.0 deployed. P99 latency increases 4x (200ms → 800ms). Canary stuck at 5%; monitoring alert missed because latency threshold not set. Business loses $50k/hour in abandoned checkouts. Root cause: N+1 query pattern under high load (10 concurrent load test; 1000+ in production).

**Root Cause:**
- Load test unrealistic (10 vs 1000 concurrent users)
- Latency not monitored in canary
- N+1 query hidden until production scale

**Resolution Steps (Timeline: 1 hour):**
1. Pause canary (immediate traffic freeze at 5%)
2. Profile with distributed tracing (identify DB bottleneck)
3. Find root cause (N+1 queries in checkout)
4. Instant rollback (latency drops 800ms → 200ms instantly)
5. Fix code (batch queries to single JOIN)
6. Re-deploy with load test at 1000 concurrent users

**Lessons:**
- Load tests must match production scale
- Latency as first-class canary metric (not just error rate)
- Performance testing in CI/CD is essential
- Make rollback fast and easy

---

## Interview Questions for Senior DevOps Engineers

### Q1: Walk me through a critical production incident you handled. What went wrong, how did you respond?

**Answer Framework:**
1. **Incident trigger**: Specific symptom (latency spike, 100% errors)
2. **Detection**: Time to detect (monitoring? customer complaints?)
3. **Response timeline**: Paged? Escalation? Communication?
4. **Root cause**: Technical deep dive (connection pool exhaustion, cascading failures)
5. **Remediation**: Immediate fix vs permanent fix
6. **Postmortem**: Prevent recurrence (code changes, monitoring improvements)

**Key Points Assessor Looks For:**
- Discipline in response (not panicked)
- Root cause analysis (not surface-level)
- Systemic improvement (prevented recurrence)
- Team communication (kept organization informed)

---

### Q2: Compare GitOps (pull-based) vs traditional CI/CD (push-based). When would you choose each?

**Answer Framework:**

**GitOps Advantages:** Audit trail, drift detection, disaster recovery (provision from Git), security (cluster credentials never leave cluster)

**GitOps Disadvantages:** Adds complexity, slower feedback loop, requires Git discipline

**CI/CD Advantages:** Immediate feedback, simpler tooling, familiar to ops teams

**CI/CD Disadvantages:** Credentials sprawl, configuration drift possible, less auditability

**When to Use:**
- **GitOps**: Large org, multi-cluster, compliance-heavy, stability over velocity
- **CI/CD**: Small team, single cluster, high deployment frequency

**Real-world Hybrid:** Use GitOps for infrastructure (daily changes), CI/CD for application (hourly changes)

---

### Q3: Argo CD vs Flux for GitOps. How would you evaluate? What would drive your decision?

**Answer Framework:**
Create decision matrix:
- Criterion: Multi-cluster, UI/UX, Scalability, Learning curve, Community
- Weight: importance (multi-cluster 20%, UI 15%, etc.)
- Score: each tool
- Recommendation: based on weighted scores

**Key Points:**
- Argo CD: Excellent UI, centralized control, good for 1-50 clusters
- Flux: Distributed agents, lower resource, scales to 100+ clusters
- Decision should match org structure and scale

---

### Q4: Kubernetes cluster corruped (etcd issues). You have Git manifests as backup. Recover procedure?

**Answer Framework:**
1. **Provision new cluster** (terraform apply, 10 min)
2. **Install GitOps agent** (Argo CD, 2 min)
3. **GitOps reconciliation** begins (pulls from Git, 5 min)
4. **Workloads recovering** (pods starting, 5-10 min)
5. **Full recovery** (30 min total)

**What could go wrong:**
- Terraform fails (quota, network)
- Image pull fails (registry down)
- Database connection fails (replica lag)
- Order dependency issues (DB before app)

**Testing:** Run DR drills quarterly (test, measure RTO, fix gaps)

---

### Q5: Secrets management in GitOps. How do you balance security and operability?

**Answer Framework:**
1. **Never in Git** (non-negotiable)
2. **External secret store** (Vault, AWS Secrets Manager, Azure KV)
3. **Access control** (RBAC, IRSA)
4. **Rotation** (automated monthly)
5. **Trade-offs:** More complex, but audit trail improves

**Key Points:**
- Pre-commit hooks block secrets submission
- External secret operator syncs periodically
- Pod sees injected secret from Kubernetes (never Git)

---

### Q6: Multi-cluster strategy. How would you design? Federated vs independent?

**Answer Framework:**
- **Independent clusters**: Simple, resilient, autonomous (content delivery)
- **Hub-and-spoke federation**: Centralized, consistent, but master is SPOF
- **Peer-to-peer federation**: Resilient, scales many clusters, eventual consistency

**Recommendation:** Start independent. Add federation when configuration consistency becomes burden.

---

### Q7: Database corruption causes data loss. Recover procedure?

**Answer Framework:**
1. **Immediate containment** (stop app writes, snapshot state)
2. **Assess damage** (scope, timeline)
3. **Restore from backup** (point-in-time recovery or snapshot)
4. **Verify integrity** (checksums, row counts match)
5. **Restore application** (restart pods)

**Prevention:**
- Automated backups (daily full, hourly incremental)
- Test recovery monthly (restore to test env, verify)
- Access control (limited privileges, pre-commit hooks)
- Monitoring (corruption detection alerts)

---

### Q8: Terraform vs Kubernetes manifests. When use each?

**Answer Framework:**
- **Terraform**: Cloud resources outside cluster (DB, VPC, IAM)
- **Kubernetes**: Container orchestration inside cluster (deployments, services)

**Layered architecture:**
```
GitOps (watches Git, deploys manifests)
    ↓
Kubernetes (runs applications)
    ↓
Terraform (provisons infrastructure + cluster)
```

**Recommendation:** Separate concerns. Terraform for infrastructure, GitOps for applications.

---

### Q9: Database migration without downtime (add column, backfill, deploy).

**Answer Framework:**
1. **Add column with default** (online DDL, no locking)
2. **Deploy app v2** (reads new column, handles absence gracefully)
3. **Canary v2** (5 min monitor)
4. **Backfill column** (if needed)
5. **Cleanup** (remove compatibility code in v3)

**Key:** Backward compatibility (v2 handles old schema), forward compatibility (v1 ignores new column)

---

### Q10: SLOs (Service Level Objectives). How do you implement? Balance velocity vs stability?

**Answer Framework:**
1. **Define SLI** (measurable: availability, latency, correctness)
2. **Set SLO target** (99.95% = 1.2 hrs downtime/month)
3. **Monitor continuously** (alert when trending toward breach)
4. **Use error budget** (spare capacity for risky deployments)

**Trade-off Logic:**
- High error budget: ship freely
- Medium error budget: balanced features+stability
- Low error budget: small changes only
- Depleted: code freeze

**Key:** SLO prevents recklessness AND prevents paralysis

---

### Q11: Observability philosophy. Logs vs metrics vs traces?

**Answer Framework:**

**Logs:** Events (what happened); debugging specific transaction

**Metrics:** Trends (system state); alerting, SLOs, capacity planning

**Traces:** Distribution (request flow); debug latency bottlenecks across services

**Why all three:**
- Logs alone: 10k events, hard to find pattern
- Metrics alone: know latency high, don't know why
- Traces alone: see service dependency, don't know which SQL query
- Together: complete picture

---

## Document Status

✅ **Complete** 
- 20 foundational + advanced sections (25,000+ words)
- 5 hands-on scenarios with troubleshooting steps
- 11 senior-level interview questions with detailed answers
- 50+ code examples (Terraform, YAML, Bash, Python)
- 25+ ASCII architecture diagrams
- Production-ready patterns and practical guidance

**Audience:** Senior DevOps Engineers (5-10+ years experience)
