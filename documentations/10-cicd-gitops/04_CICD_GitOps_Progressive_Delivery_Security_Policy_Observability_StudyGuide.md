# CICD & GitOps: Progressive Delivery, Security, Policy as Code, Observability, Multi-Cluster Deployments, Integration, Self-Service Platforms, and Disaster Recovery

**Target Audience:** DevOps Engineers with 5–10+ years experience  
**Difficulty Level:** Senior/Architect  
**Last Updated:** March 2026

---

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of CICD & GitOps](#overview-of-cicd--gitops)
   - [Why It Matters in Modern DevOps Platforms](#why-it-matters-in-modern-devops-platforms)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Where It Appears in Cloud Architecture](#where-it-appears-in-cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Progressive Delivery](#progressive-delivery)
   - Canary Releases
   - Feature Flags and Flags Management
   - A/B Testing and Experimentation
   - Automated Rollout Strategies
   - Traffic Shaping and Gradual Rollouts

4. [Security in GitOps](#security-in-gitops)
   - Secrets Management in GitOps
   - RBAC and Access Control
   - Compliance and Audit Trails
   - Vulnerability Scanning and Artifact Security
   - Signed Commits and Cryptographic Verification
   - Policy Enforcement Mechanisms

5. [Policy as Code](#policy-as-code)
   - Automated Policy Enforcement
   - Compliance Checks as Code
   - Approval Workflows and Governance
   - Open Policy Agent (OPA) Deep Dive
   - Kyverno in CI/CD Pipelines

6. [Observability in GitOps](#observability-in-gitops)
   - Monitoring and Metrics Collection
   - Logging and Log Aggregation
   - Alerting Strategies
   - Sync Status and Health Checks
   - Performance Monitoring and SLIs/SLOs

7. [Multi-Cluster Deployments](#multi-cluster-deployments)
   - Managing Multiple Clusters
   - Cluster Federation Patterns
   - Cluster Fleets and Fleet Management
   - Application Promotion Strategies
   - Cross-Cluster Deployments and Communication

8. [CICD + GitOps Integration](#cicd--gitops-integration)
   - Combining CI/CD Pipelines with GitOps Workflows
   - Automated Deployment Triggers
   - Webhook-Driven Synchronization
   - Build-to-Deploy Automation

9. [Self-Service Platforms](#self-service-platforms)
   - Developer Self-Service Portals
   - Platform Engineering Principles
   - Golden Pipelines and Templates
   - Guardrails and Policy as Guardrails

10. [Disaster Recovery with GitOps](#disaster-recovery-with-gitops)
    - Redeployment via Git as Single Source of Truth
    - Cluster Bootstrap and Recovery Automation
    - Backup and Restore Strategies
    - Failover Mechanisms and Cross-Region Deployments
    - Disaster Recovery Automation and Testing

11. [Hands-On Scenarios](#hands-on-scenarios)
    - Lab 1: Canary Rollout with Flagger
    - Lab 2: Multi-Cluster GitOps with ArgoCD
    - Lab 3: Policy Enforcement with OPA/Kyverno
    - Lab 4: Secrets Management in GitOps
    - Lab 5: Disaster Recovery Drill

12. [Interview Questions](#interview-questions)
    - Conceptual Questions
    - Architecture and Design Questions
    - Troubleshooting and Real-World Scenarios
    - Advanced Implementation Questions

---

## Introduction

### Overview of CICD & GitOps

CICD (Continuous Integration/Continuous Deployment) and GitOps represent two complementary paradigms that have transformed how organizations deliver software at scale:

- **CICD** encompasses the automated processes of building, testing, and deploying code changes continuously from commit to production.
- **GitOps** is a declarative approach to DevOps that uses Git as the single source of truth for infrastructure and application configuration, with automated synchronization to desired state.

When combined, **CICD + GitOps** creates a powerful framework where:
- Developers push code to Git repositories
- CI pipelines automatically build and test
- Deployment manifests (Kubernetes, infrastructure) are versioned in Git
- GitOps operators continuously reconcile cluster state with Git state
- All changes are auditable, reversible, and traceable

This study guide covers advanced patterns for modern DevOps platforms, including how to:
- Deploy gradually and safely (Progressive Delivery)
- Secure the entire pipeline and secrets
- Enforce policy and compliance automatically
- Observe system behavior and sync health
- Scale across multiple clusters globally
- Enable self-service for platform users
- Recover from disasters using Git as the recovery mechanism

### Why It Matters in Modern DevOps Platforms

**Speed and Reliability:** Organizations deploying hundreds of changes per day require automation that balances velocity with safety. CICD + GitOps enables both.

**Auditability and Compliance:** Regulated industries (fintech, healthcare, defense) require complete audit trails of what changed, who approved it, and when. Git provides cryptographic history and signed commits.

**Declarative Infrastructure:** Managing infrastructure as code (IaC) versions in Git eliminates configuration drift and enables easy rollbacks—critical for production stability.

**Platform Scalability:** As teams grow from 10 to 1000 engineers, self-service platforms with guardrails prevent chaos while maintaining autonomy. GitOps operators scale horizontally to manage thousands of clusters.

**Disaster Recovery:** When production fails, Git becomes the recovery tool. No manual runbooks, no state inconsistencies—just redeploy from the known-good Git state.

**Developer Experience:** Modern developers expect Git-based workflows. CICD + GitOps enables "normal" Git operations (`git push`) to trigger production changes, reducing cognitive load.

### Real-World Production Use Cases

#### 1. **Cloud-Native SaaS Company**
- 50+ microservices across 3 regions
- 500+ deployments per day
- Requirement: Canary deployments, zero-downtime updates
- **Solution:** CICD builds artifacts, GitOps with progressive delivery gates for canary rollouts to 5% of users, auto-rollback on metrics degradation

#### 2. **Financial Services Firm**
- PCI-DSS and SOX compliance requirements
- Multiple clusters across geographic regions
- Requirement: Audit every change, signed commits, policy enforcement
- **Solution:** Signed commits with hardware security keys, OPA policies enforce least privilege RBAC, all changes logged to immutable Git history, automatic compliance scanning

#### 3. **Enterprise Multi-Team Platform**
- 100+ teams with independent services
- Shared infrastructure and platform
- Requirement: Self-service deployment, prevent teams from misconfiguring each other
- **Solution:** Self-service portal templates (golden pipelines), Kyverno policies prevent privileged containers, CICD validates before GitOps sync

#### 4. **Global E-Commerce Platform**
- Millions of users across 10 regions
- Feature flags for A/B testing new checkout flows
- Requirement: Safe rollouts, fast rollbacks
- **Solution:** Feature flags in CICD, progressive delivery with traffic shaping, sync GitOps state to new regions within minutes, canary analysis before full rollout

#### 5. **Healthcare Provider**
- HIPAA compliance with disaster recovery requirements
- RPO=5 minutes, RTO=30 minutes
- Requirement: Rapid recovery from regional failure
- **Solution:** IaC in Git for all infrastructure, multi-cluster architecture, Git serves as backup source of truth, automated failover via GitOps, cluster bootstrap from Helm charts

### Where It Appears in Cloud Architecture

CICD & GitOps sits at the intersection of several critical cloud architecture layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workstation                      │
│                   (Push code to git push)                     │
└─────────────────────────────────┬───────────────────────────┘
                                  │
┌─────────────────────────────────▼───────────────────────────┐
│              Git Repository (GitHub, GitLab)                 │
│            (Source of Truth for Code & Config)               │
└─────────────────────────────────┬───────────────────────────┘
                                  │
                ┌─────────────────┴─────────────────┐
                │                                   │
    ┌───────────▼──────────┐         ┌─────────────▼────────┐
    │   CICD Pipeline      │         │   GitOps Operator    │
    │  (Jenkins, GitHub    │         │  (ArgoCD, Flux CD,   │
    │   Actions, GitLab   │         │   Flux)              │
    │   CI)                │         │                      │
    │                      │         │                      │
    │ • Build             │         │ • Sync Config        │
    │ • Test              │         │ • Apply Manifests    │
    │ • Scan              │         │ • Monitor Health     │
    │ • Push Artifacts    │         │                      │
    └──────────┬───────────┘         └──────────┬───────────┘
               │                                │
    ┌──────────▼────────────────────────────────▼──────────┐
    │         Container Registry (ECR, Harbor, GCR)        │
    │              (Artifact Storage)                       │
    └──────────┬────────────────────────────────────────────┘
               │
    ┌──────────▼────────────────────────────────────────────┐
    │         Kubernetes Clusters (Production)              │
    │  ┌────────────────────────────────────────────────┐   │
    │  │  Workloads synced by GitOps Operator           │   │
    │  │  (Watched by observability stack)              │   │
    │  └────────────────────────────────────────────────┘   │
    └──────────────────────────────────────────────────────┘
```

**Key Architectural Touchpoints:**

| Layer | Component | Role |
|-------|-----------|------|
| **Developer** | IDE, Git client | Commits code, pushes to Git |
| **VCS** | GitHub, GitLab, Gitea | Single source of truth, webhook triggers |
| **CI** | CI Pipeline Executor | Builds, tests, scans, publishes artifacts |
| **Registry** | Container Registry | Stores built artifacts and verified images |
| **GitOps** | Declarative Operator | Continuously reconciles cluster ↔ Git state |
| **Cluster** | Kubernetes | Runs workloads, reports health/metrics |
| **Observability** | Prometheus, Loki, Jaeger | Monitors sync health, application metrics |
| **Policy Enforcement** | OPA, Kyverno | Validates config before deployment |
| **Secrets** | Vault, Sealed Secrets | Manages sensitive data securely |

---

## Foundational Concepts

### Key Terminology

#### **Git as Source of Truth (SSoT)**
All deployable artifacts—application manifests, infrastructure code, configuration—are versioned in a Git repository. The actual system state (`kubectl get pods`) should match what's declared in Git. Any divergence is an error.

**Example:** A developer mistakenly deletes a pod in production. The GitOps operator detects the divergence and recreates the pod from Git-stored manifest within seconds, restoring desired state.

#### **Declarative vs. Imperative**
- **Imperative:** "Run these steps to get to desired state" (run this script, execute these commands)
- **Declarative:** "This is what desired state looks like" (YAML manifests, Helm charts, Terraform)

GitOps is fundamentally **declarative**—you define what the system should be, and automation ensures it matches.

#### **Continuous Integration (CI)**
Automated testing and building triggered by code commits. Typically:
1. Developer commits code
2. Webhook triggers CI pipeline
3. Code is compiled, tested, scanned
4. Artifacts are built and published
5. Results are reported (pass/fail)

#### **Continuous Deployment (CD)**
Automatic deployment of tested code to production. Two flavors:
- **Continuous Delivery:** Automated deployment to staging; production requires manual approval
- **Continuous Deployment:** Fully automated to production (no manual gates)

#### **GitOps**
A declarative approach where:
1. Desired state is defined in Git
2. A GitOps operator (ArgoCD, Flux) runs inside the cluster
3. Operator continuously polls Git and syncs cluster state to match
4. All changes are auditable, version-controlled, and reversible

**Key difference from traditional CD:** Traditional CD might use a pipeline to push changes. GitOps uses a pull-based model—the operator in the cluster **pulls** from Git.

#### **Progressive Delivery**
Deploying changes to a subset of users/infrastructure first, validating, then expanding. Includes:
- **Canary deployments:** 5% of traffic → 10% → 100%
- **Blue-green deployments:** Two identical environments, switch routing
- **Feature flags:** Code is deployed but feature is off until enabled

#### **Secrets Management**
Secure handling of sensitive data (passwords, API keys, certificates) in a CICD + GitOps pipeline. Challenges:
- Secrets can't be plaintext in Git
- Every environment needs different secrets
- Rotation must be auditable

Solutions: Sealed Secrets, HashiCorp Vault, external secret operators.

#### **Policy as Code (PaC)**
Policies are written as executable code (OPA/Rego, Kyverno rules) rather than documents. Examples:
- "All container images must be from approved registries"
- "No privileged containers allowed"
- "All deployments must have resource limits"

Policies are enforced at commit time (in CI) and admission time (in cluster).

#### **Multi-Cluster**
Many organizations run multiple Kubernetes clusters:
- **High Availability:** Multiple clusters in case one fails
- **Geographic Distribution:** Clusters near users (latency)
- **Scaling:** Load distributed across clusters
- **Blast Radius Limitation:** Failure in one cluster doesn't take down entire system

GitOps extends to managing all clusters from a single Git repository.

#### **Sync Status and Drift Detection**
The GitOps operator continuously checks: "Does cluster state match Git state?"
- **In Sync:** Cluster matches Git declaration
- **Out of Sync:** Cluster diverged (manual change, failed deployment, etc.)
- **Unknown:** Operator can't communicate with cluster

#### **Observability**
Visibility into system behavior through three pillars:
- **Metrics:** Quantitative measurements (CPU, latency, error rate)
- **Logs:** Discrete events (deployment started, error occurred)
- **Traces:** End-to-end request flows across services

In CICD + GitOps context: observability of deployment processes, sync health, application behavior post-deployment.

---

### Architecture Fundamentals

#### **1. The CICD Flow**

```
Developer    VCS         CI Pipeline    Registry    GitOps      Cluster
  │          │              │            │           │            │
  ├──push──→ │              │            │           │            │
  │          ├──webhook───→ │            │           │            │
  │          │              │            │           │            │
  │          │              ├──build───→ │           │            │
  │          │              │          (image)       │            │
  │          │              ├──test────│            │            │
  │          │              │          │            │            │
  │          │              ├──scan────│            │            │
  │          │              │          │            │            │
  │          │              ├──Push artifact        │            │
  │          │              │                       │            │
  │          │              └──Update manifest──→ │ │            │
  │          │                (in git-repo)       │ │            │
  │          │                                     │ ├─sync────→ │
  │          │                                     │ ├─apply────│
  │          │                                     │ │          │
  │          │                                     │ └─monitor─│
  │          │                                     │           │
```

**Key Insight:** The CI pipeline doesn't directly apply manifests to the cluster. Instead, it **updates Git**, and the GitOps operator applies them.

#### **2. Pull-Based vs. Push-Based Deployment**

**Traditional Push-Based (CD Pipeline models):**
```
CI Pipeline
    ↓
Directly applies to Kubernetes via kubectl apply / helm install
    ↓
Cluster updated
```
**Problems:** External tool has credentials to cluster; hard to audit from Git history; harder to recover state.

**GitOps Pull-Based:**
```
Git Repository ← Updated by CI pipeline
    ↓
GitOps Operator (in cluster) continuously pulls
    ↓
Operator applies changes
    ↓
Cluster state matches Git
```
**Advantages:** No external tool needs cluster credentials; all changes in Git; operator can be RBAC-constrained; easy rollback (revert Git commit).

#### **3. The GitOps Loop (Reconciliation)**

The GitOps operator runs a continuous loop:

```
LOOP:
  1. Read desired state from Git
  2. Read current state from cluster (kubectl get)
  3. DIFF(desired, current)
  4. IF diff exists:
       - Apply changes to cluster
       - Update status in Git or operator dashboard
  5. Sleep 3-5 minutes
  6. GOTO LOOP
```

**Example Scenario:**
- **Git state:** Nginx pod with 3 replicas
- **Cluster state:** Only 2 replicas (one crashed)
- **Action:** Operator detects mismatch, creates third replica
- **Benefit:** Self-healing; no manual intervention needed

#### **4. Multi-Cluster Architecture Pattern**

```
┌─────────────────────────────────────────────────────┐
│              Git Repository (Central SSoT)          │
│  ├─ kubernetes/us-west/
│  ├─ kubernetes/us-east/
│  ├─ kubernetes/eu-central/
│  └─ kubernetes/ap-southeast/
└─────────────────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
    ┌───▼────┐      ┌───▼────┐     ┌───▼────┐
    │ US-West│      │ US-East│     │EU-Cent │
    │Cluster │      │Cluster │     │Cluster │
    │        │      │        │     │        │
    │GitOps  │      │GitOps  │     │GitOps  │
    │Operator│      │Operator│     │Operator│
    └────────┘      └────────┘     └────────┘
```

Each cluster runs a GitOps operator watching its directory in Git. Single Git repo is source of truth for all clusters.

---

### Important DevOps Principles

#### **1. Infrastructure as Code (IaC)**
All infrastructure—networking, databases, Kubernetes manifests, firewall rules—is defined as code, versioned in Git, and reviewed like application code.

**In CICD + GitOps context:**
- Manifests (Deployment, Service, ConfigMap) are code
- IaC tools (Terraform, Pulumi) manage cloud resources
- Changes go through code review, not undocumented manual CLI commands

#### **2. Immutability**
Once an artifact is built and tagged, it never changes. For containers:
- Image SHA is immutable
- Config is versioned in Git
- Can't "edit in place"; must rebuild and redeploy

**Benefit:** Reproducibility; you can always rebuild the exact same artifact.

#### **3. Observability over Monitoring**
- **Monitoring:** Checking if something is broken (is CPU > 80%?)
- **Observability:** Understanding why it's broken (trace the request path, examine logs, check metrics)

In CICD + GitOps: Observe deployment processes, sync status, and application health post-deployment.

#### **4. Shift Left / Fail Fast**
Problems should be caught as early as possible:
- **Unit tests:** Developers, on their machines
- **Integration tests:** CI pipeline before merge
- **Policy checks:** Before deployment (OPA, Kyverno)
- **Scan: Vulnerability scanning before container is deployed

**Failing at commit time is infinitely cheaper than failing in production.**

#### **5. Single Source of Truth (SSoT)**
One authoritative source for each piece of information. In CICD + GitOps:
- **Git** = single source of truth for code and manifests
- **Container Registry** = single source for built artifacts
- **Cluster** = current running state (should match Git if synced)

Reduces confusion, enables recovery, simplifies audit.

#### **6. Least Privilege Access**
Users/services have only the minimum permissions needed.

In CICD + GitOps context:
- RBAC: Developers can deploy to staging, not production
- Kubernetes RBAC: Service accounts have minimal permissions
- Secrets: Encrypted, rotated, audited
- CI pipeline credentials: Scoped to specific repositories

#### **7. Immutable Delivery**
Once code passes tests and is merged to `main`, deployment to production is automatic and deterministic. No manual "pick which commit to deploy."

#### **8. Auditability**
Every change must be traceable: who approved it, what changed, when, why.

Git provides this naturally: `git log`, `git blame`, signed commits.

---

### Best Practices

#### **1. Git Repository Structure**

**Single Repo vs. Multiple Repos:**
- **Single**: One mega-repo with all code and config
  - Pros: Atomic commits across services
  - Cons: Scaling challenges, merge conflicts
  
- **Multiple**: Separate repos for code and deployment configs
  - Pros: Teams own their repos, clear separation
  - Cons: Coordination needed

**Recommended structure for multi-team:**
```
gitops-config-repo/
├── bases/
│   ├── nginx/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   └── postgres/
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── patch.yaml
│   ├── staging/
│   └── production/
└── clusters/
    ├── us-west-prod/
    │   └── kustomization.yaml
    ├── us-east-prod/
    └── eu-central-prod/
```

**Benefits:** DRY (Don't Repeat Yourself), easy to patch per environment.

#### **2. CICD Pipeline Best Practices**

**a) Cache Aggressively**
- Cache dependencies (npm, pip, Maven)
- Cache Docker layers
- Saves 10-15 minutes per pipeline run

**b) Parallelize Tests**
- Unit tests on changes
- Integration tests on merge to main
- Full stack tests only for release branches

**c) Early Scanning**
- Lint on every commit
- Security scan (SAST) on every commit
- Container scan before pushing to registry

**d) Fail Fast**
- If lint fails, don't run tests
- If tests fail, don't build image
- If image scan fails, don't push

**Pseudocode:**
```
IF lint FAILS → EXIT 1
IF test FAILS → EXIT 1
IF scan FAILS → EXIT 1
BUILD image
PUSH to registry
```

#### **3. GitOps Sync Strategies**

**a) Automated Sync (Default)**
- GitOps operator continuously syncs Git → Cluster
- Drift is auto-corrected
- Good for: Reliable deployments

**b) Manual Sync**
- Operator detects drift but doesn't fix
- Human must click "Sync" in UI
- Good for: High-change environments where auto-correct might be risky

**c) Selective Sync**
- Operator can be configured to ignore certain fields
- Example: Don't override HPA-scaled replicas in Git
- Good for: Environments with dynamic scaling

**Recommendation:** Start with automated sync; move to selective/manual only if you have specific reasons.

#### **4. Secrets Management Best Practices**

**What NOT to do:**
```
# ❌ WRONG - Never commit secrets to Git
apiVersion: v1
kind: Secret
metadata:
  name: db-password
stringData:
  password: "super-secret-123"
```

**What TO do:**
```
# ✅ Use Sealed Secrets
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: db-password
spec:
  encryptedData:
    password: AgAs7t4Dh... (encrypted with cluster's public key)
```

The GitOps operator decrypts using the cluster's private key at sync time.

**Even better:** Use an external secret operator that fetches from Vault at runtime:
```
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-password
spec:
  secretStoreRef:
    name: vault
  target:
    name: db-password
  data:
  - secretKey: password
    remoteRef:
      key: secret/database
      property: password
```

#### **5. Testing GitOps Changes**

Always test in a lower environment before production:
- **Dev branch** → dev cluster
- **Staging branch** → staging cluster
- **Main branch** → production cluster

Validate:
- Manifest syntax (kustomize build, helm template)
- Policy compliance (OPA/Kyverno validation)
- Actual behavior (smoke tests in staging)

#### **6. Rollback Strategies**

**Git-based rollback:**
```bash
# Revert the commit
git revert abc123
git push
# GitOps operator automatically syncs the reverted state
```

**Speed:** Rollback in <2 minutes if GitOps operator has short sync interval.

**Never:**
```bash
# ❌ Don't do this - manual kubectl
kubectl set image deployment/app app=image:old-version
# This breaks Git as SSoT!
```

#### **7. Monitoring Deployment Health**

Post-deployment, automatically check:
- Pod startup time (should stabilize within 30s)
- Error rate (should stay < 0.1%)
- Latency (should not spike)
- Custom metrics (business KPIs)

If health checks fail, automatically rollback:
```
Deploy new version
  ↓
Monitor metrics for 5 minutes
  ↓
IF error_rate > threshold OR latency > threshold
  → git revert
  → operator syncs
  → old version running
```

---

### Common Misunderstandings

#### **Misconception #1: GitOps = Deploying Only with Git**
**Reality:** GitOps is about using Git as the source of truth for desired state and having operators reconcile to it. The **mechanism** of change application doesn't have to be exclusively Git-based.

Example: You can have CICD update deployment image in Git, and GitOps applies it. That's GitOps. You can also have an operator watch for new images and auto-update Git. That's also GitOps.

---

#### **Misconception #2: GitOps = No CI Pipeline**
**Reality:** GitOps doesn't replace CI; it **complements** it. You still need:
- CI to build and test code
- CI to build container images
- CI to scan for vulnerabilities
- CI to validate manifests

GitOps just handles deployment. It's **not** "no CI," it's "decoupled from deployment."

---

#### **Misconception #3: GitOps Means Everything is Declarative**
**Reality:** Imperative operations still happen; they're just minimized and observed.

Example: A StatefulSet running Postgres. Upgrades require:
1. Declarative: Update manifests in Git
2. Imperative: Run migration scripts (must happen in order, can't be idempotent for all operations)

GitOps operators (ArgoCD) can pause sync, run imperative steps, then resume. Or you can use Flux with Helm hooks for imperative operations.

---

#### **Misconception #4: GitOps = Slower Than Imperative**
**Reality:** GitOps can be faster:
- No manual approval step (if policy allows)
- Automated rollbacks on health check failure
- Self-healing (drift correction)
- Consistent across environments

Perceived slowness happens when adding manual approval gates for compliance, but that's a **choice**, not a limitation of GitOps.

---

#### **Misconception #5: Pull-Based Deployment Can't Handle Secrets**
**Reality:** Secrets can be pulled by operators:
- External Secret Operator fetches from Vault
- Sealed Secrets are decrypted in-cluster
- Both support rotation and auditing

---

#### **Misconception #6: All Clusters Must Use the Same GitOps Tool**
**Reality:** You could have:
- **Cluster A:** ArgoCD (because your team knows it)
- **Cluster B:** Flux (because another team prefers it)
- Both pulling from **same Git repo**

Not recommended due to complexity, but technically possible.

---

#### **Misconception #7: GitOps Prevents Manual Changes**
**Reality:** GitOps **detects** manual changes (drift) and can auto-correct, but doesn't technically prevent them (unless you lock down Kubernetes RBAC very strictly).

A safer approach: Detect drift in monitoring/alerts and notify teams rather than auto-correct (for sensitive environments).

---

#### **Misconception #8: Policy as Code = Denying Everything**
**Reality:** Policy as Code can be **enablers**, not just restrictive:
- "Auto-approve deployments to dev environments"
- "Auto-inject monitoring sidecars"
- "Auto-add network policies based on labels"

It's not just "no, no, no"—it's "yes, automatically."

---

## Summary

This foundational section has covered:

1. **Terminology** that senior engineers must internalize
2. **Architecture fundamentals** of how CICD and GitOps interact
3. **DevOps principles** that underpin the entire approach
4. **Best practices** proven in production environments
5. **Common misunderstandings** that could lead to anti-patterns

You should now understand:
- Why Git is the source of truth
- How CICD and GitOps are complementary
- The pull-based (reactive) model of GitOps vs. push-based deployment
- The continuous reconciliation loop that keeps systems in desired state
- Why multi-cluster deployments benefit from centralized Git
- The principles that govern modern DevOps platforms

In the following sections, we'll deep-dive into each subtopic: Progressive Delivery, Security, Policy as Code, Observability, Multi-Cluster Deployments, Integration, Self-Service Platforms, and Disaster Recovery.

---

**Next Steps:**
1. Review the key terminology until it's second nature
2. Identify which architectural patterns match your current environment
3. Prepare for the Progressive Delivery section, which builds on these fundamentals

---

# 3. Progressive Delivery

## Textual Deep Dive

### Internal Working Mechanism

Progressive delivery is a risk reduction strategy that deploys changes to a **subset of users or infrastructure**, validates behavior, and **gradually expands** the rollout. Unlike blue-green or rolling updates that either pass or fail entirely, progressive delivery introduces intermediate validation gates:

```
100% Old → 5% New → 10% New → 50% New → 100% New
         ↓         ↓         ↓         ↓
       Monitor  Monitor  Monitor  Monitor
       (Pass)   (Pass)   (Pass)   (Pass)
```

The mechanism has three layers:

**1. Traffic Management Layer**
Controls how traffic is distributed between old and new versions. Techniques:
- **Weight-based:** 95% to v1, 5% to v2
- **Header-based:** If user-agent contains "Tester", send to v2
- **Geographic:** Send Japan traffic to v2, rest to v1
- **Canary:** Small percentage to v2, increasing over time

**2. Metrics Analysis Layer**
Continuously compares old vs. new version metrics:
- Error rate: `error_rate(v2) < error_rate(v1) + 0.5%`
- Latency: `p99_latency(v2) < p99_latency(v1) + 50ms`
- Custom metrics: Checkout success rate, conversion, etc.

**3. Automation Layer**
Makes decisions based on metrics:
- If metrics pass: Increase weight to 10%, continue monitoring
- If metrics fail: Immediately rollback to v1
- If metrics are inconclusive: Hold at current weight, escalate to human

**Execution Flow:**
```
Deployment triggered
    ↓
Create v2 pods (but don't route traffic yet)
    ↓
Route 5% of traffic to v2
    ↓
Monitor metrics for 5 minutes
    ↓
IF metrics degraded → Rollback (delete v2, stop)
IF metrics improved → Route 10% traffic
    ↓
Repeat until 100% traffic on v2
    ↓
Delete v1 pods
```

### Architecture Role

Progressive delivery sits **between CI/CD and the user**:

```
CI Pipeline builds image
        ↓
Git manifest updated (image tag)
        ↓
GitOps sync (ArgoCD) applies new deployment
        ↓
Progressive delivery controller (Flagger, ArgoRollouts) intercepts
        ↓
Controls traffic split (via Istio/Linkerd service mesh)
        ↓
Monitors application metrics (Prometheus, DataDog)
        ↓
Makes rollback/proceed decision
        ↓
Updates routing rules to shift traffic gradually
        ↓
When 100%, proceeds to complete
```

**Key Components:**
- **Service Mesh** (Istio, Flagger, ArgoRollouts, LinkerdRollout): Manages traffic splitting
- **Metrics Provider** (Prometheus, DataDog, New Relic): Supplies health metrics
- **GitOps Operator** (ArgoCD): Applies manifests
- **Progressive Delivery Controller** (Flagger, ArgoRollouts): Orchestrates the rollout

### Production Usage Patterns

#### **Pattern 1: Canary Deployment (Most Common)**
Gradually increase traffic to new version while monitoring metrics.

**When to use:** Microservice deployments, low-risk changes, frequent deployments

**Example:** Deploying updated checkout service
- 0 min: 5% traffic to v2
- 10 min: If error rate < 0.5%, move to 25%
- 20 min: If latency stable, move to 50%
- 30 min: If all metrics good, move to 100%
- Time to full rollout: ~30 minutes

#### **Pattern 2: Blue-Green**
Two identical production environments; switch routing from blue (old) to green (new).

**When to use:** Stateful services, database migrations, coordinated changes, risk-averse organizations

**Example:** Database schema upgrade
- Blue environment running on v1 database schema
- Green environment with v2 schema deployed
- Data migration scripts run (blocking)
- Once validated, switch router from blue → green
- Old environment kept for rollback

**Pros:** Instant switch, easy rollback (switch back to blue)
**Cons:** double infrastructure cost, coordinated rollback complexity

#### **Pattern 3: Rolling Updates**
Gradually replace old pods with new ones (native to Kubernetes).

**When to use:** Simple deployments, no advanced metrics, non-critical services

```
5 replicas of v1
        ↓
Delete 1 v1, create 1 v2 (4 v1, 1 v2)
        ↓
Delete 1 v1, create 1 v2 (3 v1, 2 v2)
        ↓
...
        ↓
All 5 are v2
```

**Pros:** No extra infrastructure
**Cons:** No metrics-based decision; if v2 crashes, requests fail

#### **Pattern 4: Feature Flags**
Deploy code to 100% of users but feature is off; gradually enable.

**When to use:** Large feature development, decoupling deployment from feature activation, A/B testing

**Example:** New recommendation engine
```
Deploy code to all pods (feature flag = false)
        ↓
Enable flag for 5% of users via feature flag API
        ↓
Monitor usage and metrics
        ↓
If good, enable for 100%
```

**Advantage:** Deployment and release are decoupled; rollback is just changing a config value (no redeployment).

#### **Pattern 5: A/B Testing**
Route different user segments to different versions, measure business metrics.

**When to use:** When you want to measure user behavior impact (NOT operational health), checkout flows, UI changes

**Example:** Two checkout flows
```
Group A (50%): Old checkout (3-step process)
Group B (50%): New checkout (2-step process)

Measure:
- Conversion rate
- Cart abandonment
- Time to checkout

If Group B > Group A → Roll out new checkout
```

**Difference from canary:** Canary is about operational metrics (error rate, latency). A/B is about business metrics (conversion, revenue).

### DevOps Best Practices

#### **1. Always Define Success Criteria**
Before rolling out, specify:
```yaml
Metrics:
  - Error rate: must stay < 0.5%
  - Latency p99: must stay < baseline + 100ms
  - Memory: must stay < 500Mi per pod
  
Thresholds:
  - Rollback if error rate > 1% for 2 consecutive checks
  - Pause (don't auto-rollback) if latency > baseline + 150ms
  - Skip to 100% if all metrics good for 15 minutes
```

#### **2. Start Slow, Then Accelerate**
```
Weight progression: 5% → 10% → 25% → 50% → 100%

OR for very stable services:
Weight progression: 10% → 50% → 100%
```

Ratio: The higher the service's change frequency and stability, the more aggressive you can be.

#### **3. Monitor Both Cluster and Application Metrics**
Don't just look at "error rate." Monitor:
- **Cluster metrics:** CPU, memory, network
- **Application metrics:** Business KPIs, custom instrumentation
- **Dependency metrics:** Database connections, external API latency

#### **4. Implement Circuit Breakers**
Prevent cascading failures when canary version fails:
```
IF error_rate(v2) > 5%:
  Stop sending traffic immediately
  Don't wait for next monitoring interval
```

#### **5. Use Observability (Not Just Metrics)**
Error rate tells you **that** something broke. Logging and tracing tell you **why**.
- Logs: "Connection refused to database"
- Trace: User request → service A → service B (timeout) → service C (never called)

Log the failing requests so you can investigate post-rollback.

#### **6. Rollback Window**
Define how long you'll keep v1 pods running before deleting them:
```
Deploy v2
Monitor for 30 minutes
If good after 30 min, delete v1
If bad, rollback within 30 min window
```

Longer window = more confidence before cleanup, but more infrastructure cost.

#### **7. Stateless is Easier**
Services that don't hold state (caches, connections, sessions) canary far more safely than stateful services.

If stateful:
- Ensure connection draining
- Validate in-flight requests complete
- Database migration patterns allow back-and-forth

### Common Pitfalls

#### **Pitfall 1: Monitoring the Wrong Metrics**
```
❌ WRONG: Monitoring only infrastructure metrics
- CPU up to 80%
- Memory up to 700Mi
- Network 10mbps

✅ RIGHT: Monitor business and application metrics
- Error rate (4xx, 5xx)
- Latency (p50, p95, p99)
- Custom: Checkout success rate, user session time
- Upstream/downstream impact metrics
```

#### **Pitfall 2: Canary Too Small (False Confidence)**
```
❌ WRONG: 0.1% canary
- Only 10 users see v2 out of 10,000
- Not enough traffic to detect issues
- Takes too long to reach 100%

✅ RIGHT: 5% canary minimum
- 500 users see v2 out of 10,000
- Enough to detect latency, errors
- Still limited blast radius
```

#### **Pitfall 3: Too Aggressive Weight Increases**
```
❌ WRONG: 5% → 25% → 100%
- Jumps from 50 users to 5000 users
- Large jump risks missing issues

✅ RIGHT: 5% → 10% → 25% → 50% → 100%
- Smaller steps, more confidence
- More monitoring points
```

#### **Pitfall 4: No Rollback Automation**
```
❌ WRONG: Canary fails, PagerDuty alert, human logs in and manually rolls back

✅ RIGHT: Canary fails, system automatically reverts Git commit
- Rollback in < 30 seconds
- No human reaction time
```

#### **Pitfall 5: Feature Flags Without Coordination**
Multiple feature flags interacting unexpectedly:
```
❌ WRONG:
- Flag A: New auth (enabled 50%)
- Flag B: New caching (enabled 50%)
- No clear guidance which combinations are tested

✅ RIGHT:
- Define tested combinations
- Test A=on, B=on; A=on, B=off; A=off, B=on
- Document interactions
```

#### **Pitfall 6: Ignoring Upstream Dependencies**
```
❌ WRONG: Deploy v2 of service-a, which calls service-b v1
- v2 might use new API that v1 doesn't provide
- Canary fails with 500s

✅ RIGHT: Coordinate deployments
- Deploy service-b first (backward compatible)
- Then deploy service-a
- Ensure API contracts are versioned
```

---

## Practical Code Examples

### Example 1: Flagger Canary Rollout (Istio Service Mesh)

Flagger is a progressive delivery controller that automates canary deployments on Kubernetes with service meshes.

**Architecture:**
```yaml
# File: deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: test
spec:
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
      - name: podinfo
        image: ghcr.io/stefanprodan/podinfo:6.2.0  # CI will update this
        ports:
        - containerPort: 9898
        resources:
          requests:
            cpu: 100m
            memory: 64Mi
```

**Flagger Canary Resource:**
```yaml
# File: canary.yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: podinfo
  namespace: test
spec:
  # Target deployment
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: podinfo

  # Service config
  service:
    port: 9898
    targetPort: 9898

  # Analysis config - how to roll out
  analysis:
    # Interval between checks
    interval: 1m
    
    # How long to wait before marking as failed
    threshold: 5
    
    # Max weight for canary before automatic promotion
    maxWeight: 50
    
    # Step size for weight increase
    stepWeight: 5

  # Metrics to monitor
  metrics:
  - name: request-success-rate
    thresholdRange:
      min: 99  # At least 99% success rate
    interval: 1m

  - name: request-duration
    thresholdRange:
      max: 500  # Latency must stay < 500ms
    interval: 1m

  # Webhooks for more complex checks (optional)
  webhooks:
  - name: smoke-tests
    url: http://flagger-loadtester/
    timeout: 30s
    metadata:
      type: smoke
      cmd: "curl -sd 'test' http://podinfo-canary:9898/token | grep token"

  # Traffic management via Istio VirtualService
  skipAnalysis: false
```

**GitOps Update Trigger:**
When CI pipeline builds a new image, it updates the deployment:
```bash
# In CI pipeline (GitHub Actions)
- name: Update image in Git
  run: |
    sed -i 's|ghcr.io/stefanprodan/podinfo:.*|ghcr.io/stefanprodan/podinfo:6.3.0|g' deployment.yaml
    git add deployment.yaml
    git commit -m "Update podinfo to 6.3.0"
    git push
```

**What Happens:**
1. Git is updated with new image tag
2. ArgoCD detects change, applies new deployment
3. Flagger detects new deployment (ReplicaSet revision change)
4. Flagger creates canary ReplicaSet with new image (weight=0)
5. Flagger gradually increases traffic weight: 5% → 10% → 15% → ...
6. For each step, Flagger waits 1 minute and checks metrics
7. If metrics pass: increase weight
8. If metrics fail: rollback (delete canary ReplicaSet, restore traffic to old)
9. When weight reaches 50% and all metrics good, promote (delete old ReplicaSet)

---

### Example 2: Feature Flags with LaunchDarkly

Feature flags enable decoupling deployment from feature release.

**Deployment (always includes feature):**
```yaml
# deployment.yaml - deployed with v6.3.0
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service
spec:
  containers:
  - name: checkout
    image: myregistry.azurecr.io/checkout:v6.3.0  # Includes new 2-step checkout
    env:
    - name: LD_SDK_KEY  # LaunchDarkly SDK key
      valueFrom:
        secretKeyRef:
          name: launchdarkly-secrets
          key: sdk-key
```

**Application Code (using feature flag):**
```python
# checkout.py
from ldclient import Context, get_client

ld_client = get_client("SDK_KEY")

@app.route('/checkout', methods=['POST'])
def checkout():
    user_id = request.json.get('user_id')
    
    # Create context for feature flag
    context = Context.builder(user_id).build()
    
    # Check if user has new checkout flow enabled
    use_new_checkout = ld_client.variation(
        flag_key="new-two-step-checkout",
        context=context,
        default=False  # Default to old flow
    )
    
    if use_new_checkout:
        return new_checkout_flow(request.json)
    else:
        return old_three_step_checkout(request.json)
```

**GitOps for Feature Flag Configuration:**
While the feature flag service is external (LaunchDarkly), you can version your configuration in Git:

```yaml
# File: feature-flags-config.yaml
# This is synced to LaunchDarkly via CI pipeline
features:
  - name: "new-two-step-checkout"
    description: "New simplified 2-step checkout process"
    rollouts:
      - percentage: 5    # Enable for 5% of users
        targetSegment: "beta-testers"
      - percentage: 25
        startTime: "2026-03-18T00:00:00Z"
      - percentage: 100
        startTime: "2026-03-20T00:00:00Z"
    metrics:
      - conversion_rate
      - checkout_time
    rollbackTrigger:
      metric: conversion_rate
      threshold: "< baseline * 0.95"  # Rollback if conversion drops 5%
```

**CI Pipeline to apply flags:**
```bash
#!/bin/bash
# Script: push-feature-flags.sh

# Parse feature-flags-config.yaml and push to LaunchDarkly API
curl -X PATCH \
  https://app.launchdarkly.com/api/v2/flags/default/new-two-step-checkout \
  -H "Authorization: $LD_API_KEY" \
  -d '{
    "rules": [
      {
        "variation": 1,
        "trackEvents": true,
        "rollout": {
          "kind": "rollout",
          "variations": [
            {"variation": 0, "weight": 95000},
            {"variation": 1, "weight": 5000}
          ]
        }
      }
    ]
  }'
```

---

### Example 3: Argo Rollouts with Traffic Analysis

ArgoRollouts is a Kubernetes controller that provides more advanced rollout strategies than native rolling updates.

**ArgoRollout Manifest:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: recommendation-engine
  namespace: production
spec:
  replicas: 10
  revisionHistoryLimit: 5

  selector:
    matchLabels:
      app: recommendation-engine

  template:
    metadata:
      labels:
        app: recommendation-engine
    spec:
      containers:
      - name: engine
        image: myregistry.azurecr.io/recommendation-engine:v2.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"

  strategy:
    canary:
      steps:
      # Step 1: Route 10% of traffic to new version
      - setWeight: 10
      # Step 2: Pause for analysis
      - pause: {duration: 10m}
      # Step 3: Increase to 25%
      - setWeight: 25
      - pause: {duration: 5m}
      # Step 4: Increase to 50%
      - setWeight: 50
      - pause: {duration: 5m}
      # Step 5: Increase to 75%
      - setWeight: 75
      - pause: {duration: 5m}
      # Step 6: Full rollout
      - setWeight: 100

      # Traffic management (requires Istio/Linkerd)
      trafficWeight:
        canary: 10
        stable: 90

      # Metrics analysis to auto-rollback
      analysis:
        # Which canary to use for analysis
        # This references an AnalysisTemplate
        templates:
        - name: recommendation-metrics

      # If analysis fails, terminate rollout
      timeout: 30m

  # Service that receives traffic
  selector:
    matchLabels:
      app: recommendation-engine
```

**AnalysisTemplate for Metrics:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: recommendation-metrics
spec:
  # Metrics from Prometheus
  metrics:
  - name: error_rate
    provider:
      prometheus:
        address: http://prometheus:9090
        # Query: compare canary vs stable error rates
        query: |
          rate(http_requests_total{job="recommendation-engine",status=~"5.."}[5m]) 
    
    # Success criteria
    successCriteria: "{{ $value < 0.05 }}"  # Less than 5% errors
    failureLimit: 3  # Allow 3 failures before rollback
    interval: 1m
    count: 10  # Run 10 times

  - name: latency_p99
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          histogram_quantile(0.99, 
            rate(http_request_duration_seconds_bucket{job="recommendation-engine"}[5m]))
    
    # Latency must not exceed 500ms
    successCriteria: "{{ $value < 0.5 }}"
    failureLimit: 5
    interval: 1m
    count: 10

  - name: success_rate
    provider:
      prometheus:
        address: http://prometheus:9090
        query: |
          sum(rate(http_requests_total{job="recommendation-engine",status=~"2.."}[5m])) 
          / sum(rate(http_requests_total{job="recommendation-engine"}[5m]))
    
    # Track success rate of recommendations
    successCriteria: "{{ $value > 0.98 }}"  # 98% or higher
    failureLimit: 2
    interval: 1m
    count: 10
```

**Automated Rollback on Failure:**
If analysis fails (e.g., error rate > 5%), ArgoRollouts:
1. Stops weight increase
2. Immediately routes all traffic back to stable version
3. Marks rollout as failed
4. Keeps new ReplicaSet for debugging
5. Sends alert to PagerDuty

---

### Example 4: A/B Testing with Helm and Kustomize

Separate deployments for A and B variants, controlled via routing.

**Base Application:**
```yaml
# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-app
  labels:
    app: checkout
spec:
  replicas: 5
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
      spec:
        containers:
        - name: checkout
          image: myregistry.azurecr.io/checkout:latest
          ports:
          - containerPort: 8080
```

**Kustomization for A/B:**
```yaml
# overlays/ab-test/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Include both deployments
resources:
  - ../../base

# Create TWO deployments with patches
replicas:
  - name: checkout-app
    count: 5

# Patch to create variant A (old checkout)
patchesStrategicMerge:
  - checkout-a-patch.yaml

# Also patch for variant B
  - checkout-b-patch.yaml
```

**Patch for Variant A (old 3-step checkout):**
```yaml
# overlays/ab-test/checkout-a-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-app-a
spec:
  selector:
    matchLabels:
      variant: a
  template:
    metadata:
      labels:
        variant: a  # Label to identify this variant
    spec:
      containers:
      - name: checkout
        image: myregistry.azurecr.io/checkout:v5.0.0  # Old version
        env:
        - name: CHECKOUT_FLOW
          value: "three-step"
```

**Patch for Variant B (new 2-step checkout):**
```yaml
# overlays/ab-test/checkout-b-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-app-b
spec:
  selector:
    matchLabels:
      variant: b
  template:
    metadata:
      labels:
        variant: b
    spec:
      containers:
      - name: checkout
        image: myregistry.azurecr.io/checkout:v6.0.0  # New version
        env:
        - name: CHECKOUT_FLOW
          value: "two-step"
```

**Traffic Routing (Istio):**
```yaml
# istio/virtual-service.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: checkout
spec:
  hosts:
  - checkout.example.com
  http:
  # Route 50% to variant A
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: checkout-app-a
        port:
          number: 8080
      weight: 50
    # Route 50% to variant B
    - destination:
        host: checkout-app-b
        port:
          number: 8080
      weight: 50
```

**Monitoring A/B Results:**
```yaml
# monitoring/prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ab-test-metrics
spec:
  groups:
  - name: ab-test.rules
    interval: 30s
    rules:
    # Track conversion rate by variant
    - expr: |
        sum(rate(checkout_completed_total{variant="a"}[5m]))
        / sum(rate(checkout_initiated_total{variant="a"}[5m]))
      record: ab_test:conversion_rate:variant_a

    - expr: |
        sum(rate(checkout_completed_total{variant="b"}[5m]))
        / sum(rate(checkout_initiated_total{variant="b"}[5m]))
      record: ab_test:conversion_rate:variant_b

    # Alert if variant B significantly worse
    - alert: VariantBUnderperforming
      expr: |
        ab_test:conversion_rate:variant_b < (ab_test:conversion_rate:variant_a * 0.95)
      for: 10m
      annotations:
        summary: "Variant B conversion rate dropped 5% vs Variant A"
        runbook: "Roll back to variant A only"
```

---

## ASCII Diagrams

### Progressive Delivery Timeline

```
Time ──────────────────────────────────────────────────────────────────────────>

Manual Deployment (Traditional)
  ┌─ Deploy ─┐  ┌─ Validate ─┐  ┌─ Issues ─┐
  │  v1→v2   │  │  T+30 min  │  │ Rollback │
  └──────────┘  └────────────┘  └──────────┘
  
  Risk: ALL USERS affected immediately if v2 broken


Canary Deployment (Progressive)
  ┌─ 5% traffic ─┐
  │  Monitor 5m  │
  │   (Pass ✓)   │
  └───────────────┴─ 10% traffic ─┐
                    │ Monitor 5m  │
                    │  (Pass ✓)   │
                    └───────────────┴─ 50% traffic ─┐
                                      │ Monitor 5m │
                                      │ (Pass ✓)  │
                                      └─────────────┴─ 100% traffic ─┐
                                                      │ Stable ✓     │
                                                      └───────────────
                                                      
  Risk: Limited to 5%, then 10%, then 50% users (gradually increasing)
  Benefit: Early detection + limited blast radius


Feature Flag Deployment (Fastest)
  ┌─ Deploy all code ─────────────────────────┐
  │  (Feature disabled in config)              │
  │  Enable flag: 0%                           │
  └──────────────────┬────────────────────────
                     │
                     └─ Enable 5% users
                        │ Monitor 5m
                        │ (Pass ✓)
                        └─ Enable 100%
```

### Flagger Canary State Machine

```
                        ┌─────────────────────┐
                        │   Created Canary    │
                        │   (Weight=0)        │
                        └──────────┬──────────┘
                                   │
                                   ▼
                        ┌─────────────────────┐
                        │  Analyzing Metrics  │
                        │  (Weight=5%)        │
                        │  Wait 1 min         │
                        └──────────┬──────────┘
                                   │
                    ┌──────────────┴───────────────┐
                    │                              │
                    ▼                              ▼
         ┌────────────────────┐        ┌─────────────────────┐
         │  Metrics PASSED    │        │  Metrics FAILED     │
         │  Increase weight   │        │  or Threshold Met   │
         │  Weight=10%        │        │  ROLLBACK INITIATED │
         └────────────┬───────┘        └──────────┬──────────┘
                      │                           │
              (Loop until                ┌─────────▼────────┐
              weight=100%)               │  Delete Canary   │
                      │                 │  Delete ReplicaSet│
                      ▼                 │  Route 100% to old│
         ┌────────────────────┐         └──────────┬────────┘
         │ Weight=100%        │                    │
         │ Metrics OK for 5m  │                    ▼
         └────────────┬───────┘         ┌─────────────────────┐
                      │                 │ ROLLBACK COMPLETE   │
         ┌────────────▼────────┐        │ Users on old version│
         │                     │        └─────────────────────┘
         │ PROMOTION COMPLETE  │
         │ Delete Old ReplicaSet
         │ Users 100% on new   │
         └─────────────────────┘
```

### Traffic Split During Canary

```
Istio VirtualService with Weight-Based Routing

              Client Requests
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
   95% Weight    5% Weight
      │              │
   ┌─▼──────────┐ ┌──▼─────────┐
   │  Stable    │ │  Canary    │
   │  Pod A     │ │  Pod B     │
   │  (v5.0)    │ │  (v6.0)    │
   └──────────┬─┘ └──────┬─────┘
              │          │
              └────┬─────┘
                   ▼
            Response to Client

Progression Over Time:

Minute 0-5:  95% → Stable,  5% → Canary
Minute 5-10: 90% → Stable, 10% → Canary
Minute 10-15: 75% → Stable, 25% → Canary
Minute 15-20: 50% → Stable, 50% → Canary
Minute 20-25: 0% → Stable, 100% → Canary (old deleted)
```

---

# 4. Security in GitOps

## Textual Deep Dive

### Internal Working Mechanism

Security in GitOps operates at multiple layers:

**Layer 1: Source Code Repository Security**
Git commit history is cryptographically verified via signed commits:
```
Standard commit (unsigned):
  commit abc123
  Author: alice@example.com
  Message: Deploy v2.0

Signed commit:
  commit abc123
  Author: alice@example.com
  Signature: -----BEGIN PGP SIGNATURE-----
             version: GnuPG
             ...base64-encoded-signature...
             -----END PGP SIGNATURE-----
```

When syncing, GitOps operator verifies the signature before applying:
```
ArgoCD on cluster
  ├─ Fetch commit from Git
  ├─ Verify signing key is authorized
  ├─ Verify signature matches commit
  └─ IF signature valid
       ├─ Apply manifests
       └─ Record "applied by alice at 2026-03-17 10:25 UTC"
     ELSE (signature invalid)
       └─ REJECT, log security event
```

**Layer 2: Secrets Management**
Secrets can't be stored plaintext in Git. Instead:

```
Git Repository (plaintext)
  deployment.yaml:
    apiVersion: v1
    kind: Secret
    metadata:
      name: db-password
    encryptedData:
      password: AgAs7t4Dh...encrypted...xyz  # Sealed Secret

Cluster (has decryption key)
  On sync:
  1. ArgoCD fetches encrypted secret
  2. Sealed Secrets controller in cluster
  3. Decrypts using cluster's private key (stored in /etc/sealed-secrets/)
  4. Creates actual Secret object
  5. Pod can now read plaintext secret from Secret object
```

This ensures:
- Git contains no plaintext secrets
- Only the cluster with the private key can decrypt
- Different clusters have different keys (can't share secrets)

**Layer 3: RBAC and Access Control**
GitOps operators respect Kubernetes RBAC:

```
GitOps Operator runs with ServiceAccount "argocd-application-controller"

ServiceAccount has ClusterRole:
  rules:
  - apiGroups: [""]
    resources: ["deployments", "services", "configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["secrets"]   # Note: same permissions
    verbs: ["get", "list", "watch", "create", "update", "patch"]

When ArgoCD applies manifest:
  IF manifest contains DaemonSet privileged container
    AND ServiceAccount doesn't have permission to create privileged containers
    THEN apply fails (RBAC denial)
```

**Layer 4: Policy Enforcement**
OPA (Open Policy Agent) and Kyverno run before resources are admitted:

```
Manifest in Git → ArgoCD sync → Kyverno/OPA validation

Kyverno rule:
  apiVersion: kyverno.io/v1
  kind: ClusterPolicy
  metadata:
    name: require-resource-limits
  spec:
    validationFailureAction: audit  # Can be 'audit' or 'enforce'
    rules:
    - name: check-resources
      match:
        resources:
          kinds:
          - Pod
      validate:
        message: "CPU and memory limits required"
        pattern:
          spec:
            containers:
            - resources:
                limits:
                  memory: "?"  # ? = field must exist
                  cpu: "?"

Sync flow:
  manifest in git → ArgoCD reads → Kyverno evaluates
    ├─ IF passes → apply to cluster
    └─ IF fails → reject (can auto-remediate or just warn)
```

**Layer 5: Audit Logging**
All GitOps operations are logged and immutable:

```
Git commits (in ./git/logs)
  2026-03-17T10:25:30Z alice    Pushed commit abc123
  2026-03-17T10:25:35Z argocd   Applied deployment
  2026-03-17T10:30:00Z alice    Pushed commit def456

Kubernetes audit log (on API server)
  {
    "stage": "ResponseComplete",
    "requestID": "uuid",
    "user": {"username": "system:serviceaccount:argocd:argocd-application-controller"},
    "verb": "create",
    "objectRef": {"apiVersion": "apps/v1", "kind": "Deployment", "name": "app", ...},
    "timestamp": "2026-03-17T10:25:35Z",
    "responseStatus": {"code": 201, "message": "Created"}
  }
```

Compliance needs to verify:
✓ Who authorized the change (Git commit author)
✓ When was it deployed (Git timestamp + API server timestamp)
✓ What exactly changed (diff in Git)
✓ Did it pass policy checks (ArgoCD/Kyverno logs)

### Architecture Role

Security in GitOps sits at the **entry point and enforcement point** of the deployment pipeline:

```
Developer            Git              GitOps           Cluster
   │                 │                 │                 │
   ├─ Sign commit ─→ │                 │                 │
   │                 │                 │                 │
   │                 ├─ (signed)───→ ArgoCD            │
   │                 │ verify sig←──────┤                │
   │                 │                  ├─ check RBAC ──→│
   │                 │                  ├─ decrypt secrets→│
   │                 │                  ├─ validate policy→│
   │                 │                  ├─ (all pass)   │
   │                 │                  ├─ apply manifests→│
   │                 │                 │                 │
   │                 │◄────────────────┤─ audit log ────│
```

**Key Security Boundaries:**

| Boundary | Mechanism | Verification |
|----------|-----------|--------------|
| Code → Git | Signed commits | Digital signature verification |
| Git → Operator | Git authentication | SSH keys, HTTPS tokens |
| Operator → Cluster | RBAC ServiceAccount | Kubernetes API authorization |
| Config → Runtime | Policy admission | OPA/Kyverno intercept |
| Runtime → Secrets | Encryption at rest | Sealed Secrets/External Secrets |
| Operations → Audit | Immutable logs | Ensure audit logs can't be deleted |

### Production Usage Patterns

#### **Pattern 1: Pinned Versions with Signed Commits**
Every manual Git commit is signed by a key that's allowed to deploy to production.

**Scenario:** Financial services company with SOX compliance
```
Production security policy:
  ├─ All commits to main must be signed
  ├─ Only 5 authorized signing keys allowed
  ├─ Each key belongs to release manager
  ├─ Any unsigned commit → automatic rejection
  ├─ Audit log maintained for compliance
  └─ Key rotation every 90 days

Process:
  1. Developer commits to feature branch (unsigned)
  2. Code review in GitHub
  3. Release manager signs merge commit
  4. GitOps accepts signed commit
  5. Deployment proceeds
  6. Audit: "user:john signed on 2026-03-17 10:25"
```

#### **Pattern 2: Secrets Rotation**
Secrets are automatically rotated without humans touching plaintext.

**Scenario:** Database credentials, API keys, TLS certs
```
HashiCorp Vault + External Secrets Operator:

1. Operator watches Vault for secret updates
2. Vault rotates DB password every 30 days
3. External Secrets fetches new password
4. Kubernetes Secret is updated
5. Pod restarts to pick up new credential
6. Git remains unchanged (secret not in Git)

Benefit: No compromise to Git security while keeping secrets fresh
```

#### **Pattern 3: RBAC Preventing Privilege Escalation**
ServiceAccount running GitOps operator has minimal permissions.

**Scenario:** Shared cluster with multiple teams
```
Team A (runs ArgoCD in namespace argocd):
  ServiceAccount: argocd-app-controller
  Permissions:
    ├─ Can create/update Deployment in team-a namespace
    ├─ Can create/update Service in team-a namespace
    └─ CANNOT create ClusterRole (no cluster-wide privileges)
    └─ CANNOT read secrets from other namespaces
    └─ CANNOT modify RBAC

Team B (runs separate ArgoCD in namespace argocd-team-b):
  ServiceAccount: argocd-app-controller
  Permissions: (isolated, can't access team-a)

Result: Teams are isolated; misconfigured Team A deployment can't affect Team B
```

#### **Pattern 4: Policy as Security (Not Just Governance)**
Policies automatically prevent unsafe configurations.

**Scenario:** Preventing container escapes
```
Kyverno policy prevents privileged containers:
  metadata:
    name: block-privileged
  spec:
    rules:
    - name: deny-privileged
      match:
        resources:
          kinds:
          - Pod
      validate:
        pattern:
          spec:
            containers:
            - =(securityContext):
                =(privileged): false

Effect:
  Manifest with "privileged: true" → rejected
  Even if developer pushes to Git
  Even if GitOps operator tries to apply
  DevOps doesn't manually block; policy does
```

#### **Pattern 5: Vulnerability Scanning in Supply Chain**
Container images are scanned for CVEs before deployment.

**Scenario:** Preventing exploitation via software supply chain
```
CI Pipeline → Image Scan → Registry → GitOps

1. CI builds container image
2. Scan with Trivy:
   trivy image myregistry.azurecr.io/app:v2.0.0
3. If high/critical CVE found:
   ├─ Block push to registry
   └─ Fail the deployment (don't update Git)
4. If passed:
   ├─ Push certified image to registry
   ├─ Update Git with image tag
   ├─ GitOps syncs (can trust image)
5. Kyverno policy enforces:
   "Only images from approved registry allowed"
   (prevents someone manually changing image source to untrusted registry)
```

### DevOps Best Practices

#### **1. Commit Signing (NOT Optional for Prod)**
All production deployments must be signed commits.

```bash
# Configure Git to sign commits
git config --global user.signingkey GPGKEYID
git config --global commit.gpgsign true

# Now all commits are signed
git commit -m "Deploy v2.0"  # Automatically signed with GPG

# Verify commit is signed
git log --show-signature
```

**GitHub enforcement:**
```
Repository Settings → Branches → main branch → Require signed commits
```

#### **2. Rotate Signing Keys Regularly**
Compromise of one key shouldn't enable long-term attacks.

```
Key rotation schedule:
  ├─ Primary key: 1 year
  ├─ Backup key: 1 year (different person)
  └─ Annual: Audit who has keys
```

#### **3. Secret Rotation**
Secrets shouldn't last longer than credentials.

```yaml
# External Secret with rotation
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h  # Check Vault every hour
  secretStoreRef:
    name: vault-backend
  target:
    name: db-secret
  data:
  - secretKey: password
    remoteRef:
      key: database/prod
      property: password
```

#### **4. Least Privilege RBAC**
GitOps ServiceAccount should NOT have cluster-admin.

```yaml
# ❌ WRONG
roleRef:
  kind: ClusterRole
  name: cluster-admin

# ✅ RIGHT
roleRef:
  kind: ClusterRole
  name: argocd-application-controller
  # with limited rules specific to app deployment
```

#### **5. Immutable Audit Logs**
Logs can't be deleted after the fact.

```
Apply to API server:
  --audit-log-maxage=7  # Keep 7 days
  --audit-log-maxbackup=10  # Keep 10 backup files
  --audit-log-maxsize=100  # Rotate when 100MB

Apply to external audit sink (cannot be tampered):
  Storage in Azure Monitor, AWS CloudTrail, GCP Cloud Audit Logs
    ├─ Immutable (can only append)
    ├─ Separate account (not cluster admin can't delete)
    └─ Compliance: Tamper alert if modification attempted
```

#### **6. Encryption at Rest**
Secrets in etcd must be encrypted.

```bash
# Kubernetes with encryption at rest
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: <base64-encoded-32-byte-key>
    - identity: {}
```

#### **7. Network Policies**
Limit which pods can communicate.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-egress
spec:
  podSelector:
    matchLabels:
      app: argocd-server
  policyTypes:
  - Egress
  egress:
  # Allow to Github only
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
      host: github.com
   # Allow to cluster API
  - to:
    - podSelector: {}
```

### Common Pitfalls

#### **Pitfall 1: Secrets in Git (Plaintext)**
```yaml
# ❌ WRONG - NEVER do this
apiVersion: v1
kind: Secret
metadata:
  name: db-password
stringData:
  password: "MyS3cr3tP@ssw0rd"  # Plaintext in Git = disaster
```

**Why it's dangerous:**
- Git history is permanent (can't erase)
- Anyone with repo access sees password
- If repo becomes public, private credential exposed
- Rotation requires commit + push + new secret

**Correct approach:** Use Sealed Secrets or External Secrets Operator instead.

#### **Pitfall 2: Over-Permissive RBAC**
```yaml
# ❌ WRONG
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

This is cluster-admin, enabling any action.

#### **Pitfall 3: Unsigned Production Commits**
```bash
# ❌ WRONG
git commit -m "Deploy to production"
# (no signature, easy to spoof)

# ✅ RIGHT
git commit -S -m "Deploy to production"
# (automatically signed, can't be spoofed)
```

#### **Pitfall 4: No Audit Logging**
```bash
# ❌ WRONG: Running cluster without audit
kube-apiserver --audit-policy-file=...

# ✅ RIGHT: Audit enabled + immutable sink
kube-apiserver \
  --audit-policy-file=/etc/kubernetes/audit-policy.yaml \
  --audit-log-maxage=7 \
  --audit-log-maxbackup=10 \
  --audit-webhook-config=/etc/kubernetes/audit-webhook.yaml
```

#### **Pitfall 5: Same Secrets Across Environments**
```yaml
# ❌ WRONG: Same secret in dev, staging, prod
spec:
  encryptedData:
    password: AgAs7t4Dh...
    # Same value deployed everywhere
```

Each environment needs its own secrets (different database instances, API keys).

#### **Pitfall 6: Not Verifying GitOps Operator's Identity**
```yaml
# ❌ WRONG: Any certificate works
apiVersion: v1
kind: Secret
metadata:
  name: github-webhook-secret
stringData:
  webhook-secret: "any-secret-string"  # No verification
```

**Correct approach:** Verify webhook signature to ensure Git triggers only from GitHub:
```python
import hmac
import hashlib

def verify_github_webhook(payload, signature, secret):
    expected = 'sha256=' + hmac.new(
        secret.encode(),
        payload.encode(),
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(signature, expected)
```

---

## Practical Code Examples

### Example 1: Sealed Secrets for Secure GitOps

Sealed Secrets allow you to commit encrypted secrets to Git. Only the cluster with the sealing key can decrypt.

**Setup (one-time):**
```bash
# Install Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# Verify
kubectl get pod -n kube-system -l app.kubernetes.io/name=sealed-secrets-controller

# Get sealing key (for backup)
kubectl get sealed-secret-keys -o yaml -A > seal-key-backup.yaml
```

**Create Sealed Secret:**
```bash
# Create normal secret (from file, environment, or directly)
kubectl create secret generic db-password \
  --from-literal=password='MyDatabasePassword123!' \
  --dry-run=client \
  -o yaml > secret.yaml

# Seal the secret (encrypt with cluster's public key)
kubeseal -f secret.yaml -w sealed-secret.yaml

# View sealed secret (encrypted, safe to commit)
cat sealed-secret.yaml
```

**Sealed Secret Manifest:**
```yaml
# sealed-secret.yaml (can commit to Git)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: db-password
  namespace: default
spec:
  encryptedData:
    password: AgAs7t4Dh+VWk4RWo...=[LONG_ENCRYPTED_STRING]=...xyz  # Encrypted
  template:
    metadata:
      name: db-password
      namespace: default
    type: Opaque
```

**GitOps Sync:**
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  template:
    spec:
      containers:
      - name: app
        image: myregistry.azurecr.io/app:v1.0
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-password  # References decrypted secret
              key: password
```

**Sync Process:**
1. Git contains `sealed-secret.yaml` (encrypted)
2. ArgoCD pulls and applies sealed-secret.yaml
3. Sealed Secrets controller (in cluster) detects SealedSecret
4. Controller decrypts using cluster's private key (`/etc/sealed-secrets/keys.yaml`)
5. Controller creates Secret object (plaintext, but only in etcd)
6. Pod mounts Secret as environment variable

**Key Benefits:**
- Encrypted data in Git ✓
- Cluster-specific (can't use sealed-secret from Cluster A on Cluster B) ✓
- Rotation: Just update sealed-secret and re-push ✓
- Audit trail: Git shows when secret changed (but not the value) ✓

---

### Example 2: External Secrets with HashiCorp Vault

For managing secrets outside of Kubernetes (centralized secret management).

**Architecture:**
```
HashiCorp Vault (central secret store)
    ↓
External Secrets Operator (fetches from Vault)
    ↓
Kubernetes Secret (created dynamically)
    ↓
Pod uses Secret
```

**Vault Setup (one-time):**
```bash
# Start Vault
vault server -dev

# Login
export VAULT_ADDR='http://127.0.0.1:8200'
vault login s.abcdefghijklmnop  # Use dev token

# Store secret
vault kv put secret/database/prod\
  username=admin \
  password=SuperSecret123!

# Verify
vault kv get secret/database/prod
```

**Install External Secrets Operator:**
```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace
```

**Create SecretStore (Vault connection):**
```yaml
# secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: default
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      auth:
        # Kubernetes auth: Pod's ServiceAccount authenticates to Vault
        kubernetes:
          mountPath: "kubernetes"
          role: "app-role"  # ServiceAccount must have this role in Vault
```

**Create ExternalSecret:**
```yaml
# external-secret.yaml (can commit to Git - no sensitive data!)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h  # Sync every hour
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  
  # What Kubernetes Secret to create
  target:
    name: db-secret
    creationPolicy: Owner

  # What to fetch from Vault
  data:
  - secretKey: username  # Key in final Secret
    remoteRef:
      key: secret/database/prod
      property: username
  
  - secretKey: password
    remoteRef:
      key: secret/database/prod
      property: password
```

**Sync Process:**
1. ExternalSecret stays in Git (no plaintext values)
2. External Secrets controller runs in cluster
3. Controller periodically fetches from Vault
4. Vault authenticates via Kubernetes auth (Pod's ServiceAccount)
5. Controller creates/updates Secret object
6. Pod reads Secret (plaintext in etcd, but isolated to cluster)

**Advantages over Sealed Secrets:**
- ✓ Centralized management (multiple clusters, one Vault)
- ✓ Secret rotation in Vault immediately affects all clusters
- ✓ Audit in Vault (shows who fetched what when)
- ✓ RBAC in Vault (Dev team can only fetch dev secrets)

---

### Example 3: Signed Commits with GPG

Every production deployment must be signed by an authorized key.

**Configure GPG Signing:**
```bash
# List available GPG keys
gpg --list-secret-keys --keyid-format=long

# Or create new key
gpg --gen-key
# (follow prompts, set email to work email)

# Configure Git to use key
git config --global user.signingkey 1234567890ABCDEF  # Key ID
git config --global commit.gpgsign true  # Auto-sign commits

# Verify configuration
git config --global --list | grep gpg
```

**Signed Commit:**
```bash
# Create commit (automatically signed)
echo "app: myservice" > deployment.yaml
git add deployment.yaml
git commit -m "Deploy myservice v2.0"

# Verify it's signed
git log -1 --show-signature
```

**Output:**
```
commit abc123def456
gpg: Signature made Mon Mar 17 10:25:30 2026 UTC
gpg:                using RSA key 1234567890ABCDEF
gpg:                issuer "alice@example.com"
gpg: Good signature from "Alice Developer <alice@example.com>"
Author: Alice Developer <alice@example.com>
Date:   Mon Mar 17 10:25:30 2026 +0000

    Deploy myservice v2.0
```

**GitHub Verification (Enforce in Branch Protection):**
```
Repository Settings → Branches → main → Require signed commits ✓

Now:
- Any unsigned push → rejected
- Only commits signed with authorized keys → accepted
- GitOps can verify commits came from authorized signers
```

**Trusting GPG Keys in GitOps:**
```yaml
# argocd-values.yaml (Helm)
server:
  insecure: false

# Tell ArgoCD which GPG keys to trust
gpgkeys:
  - id: 1234567890ABCDEF  # Alice's key
    name: alice
  - id: FEDCBA9876543210  # Bob's key
    name: bob

# ArgoCD sync will reject commits signed by other keys
```

---

### Example 4: Network Policy Restricting GitOps Operator

Limit what the GitOps operator can communicate with.

**Network Policy for ArgoCD:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-network-policy
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  policyTypes:
  - Ingress
  - Egress
  
  # Ingress: Allow webhooks from GitHub
  ingress:
  - from:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          app: webhook-receiver
    ports:
    - protocol: TCP
      port: 8080
  
  # Ingress: Allow from ArgoCD UI
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: argocd-application-controller
    ports:
    - protocol: TCP
      port: 8080

  # Egress: Allow to GitHub only
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
      host: github.com
  
  # Egress: Allow to Kubernetes API
  - to:
    - podSelector:
        matchLabels:
          component: kube-apiserver
    ports:
    - protocol: TCP
      port: 443

  # Egress: Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

**Effect:**
- ArgoCD operator can ONLY talk to GitHub and Kubernetes API
- Can't initiate connections to databases, internal services, or external systems
- If compromised, attacker's options are limited

---

## ASCII Diagrams

### Signed Commit Verification

```
Developer                 Git Repository            GitOps Operator (ArgoCD)
   │                           │                             │
   ├─ Create commit ───────→ Commit (abc123)                │
   │  & sign with GPG       SHA: abc123                      │
   │                        Signature: (GPG signed)          │
   │                        Author: alice@example.com        │
   │                           │                             │
   │                           ├─ Webhook trigger ───────→ │
   │                           │ (on push to main)        │
   │                           │                             │
   │                           │                      Fetch commit
   │                           │                      fetch signature
   │                           │◄──────────────────────│
   │                           │                             │
   │                           ├─ Verify sig ────────────→ │
   │                           │ with GPG pubkey        │
   │                      ┌────▼────────────────────────┐   │
   │                      │ Is signature valid?         │◄──│
   │                      │ Is signer authorized?       │   │
   │                      │ Key in trusted list?        │   │
   │                      └────┬───────────────┬────────┘   │
   │                           │               │             │
   │                        valid          invalid          │
   │                           │               │             │
   │                           │               ├─ REJECT    │
   │                           │               ├─ Alert:    │
   │                           │               │ Unsigned   │
   │                           │               │ commit!    │
   │                           │               │             │
   │                           ├─ ACCEPT ──→ │ Apply       │
   │                           │  Read manifests           │
   │                           │  Decrypt secrets          │
   │                           │  Sync to cluster          │
   │                           │              Log:         │
   │                           │              "Applied by  │
   │                           │               alice at    │
   │                           │               2026-03-17" │
```

### Secrets Encryption at Rest

```
Developer                    Git Repo                Kubernetes Cluster
   │                            │                            │
   ├─ Create secret ──────→ Plaintext secret              │
   │                        (password: secret123)           │
   │                            │                            │
   │                            ├─ Encrypted ──────────→ │
   │                            │ [SEALED SECRET]        │
   │                            │ AgAs7t4Dh+VWk...       │
   │                            │ (encrypted with       │
   │                            │ cluster's pub key)    │
   │                            │                        │
   │                       SAFE IN GIT ✓                 │
   │                       • No plaintext               │
   │                       • Can commit                 │
   │                       • Audit trail: who,when      │
   │                            │                        │
   │                            ├─ ArgoCD reads       → │
   │                            │  encrypted            │
   │                            │  SealedSecret         │
   │                            │                        │
   │                            │                   Sealed-Secrets
   │                            │                   Controller reads:
   │                            │◄──────────────────────│
   │                            │                   • Encrypted secret
   │                            │                   • Cluster private key
   │                            │                   • Decrypt
   │                            │                   • Create plain
   │                            │                     Kubernetes Secret
   │                            │                        │
   │                            │                        ├─ Pod reads
   │                            │                        │ plaintext from
   │                            │                        │ env var
   │                            │                        │
   │                    ENCRYPTION AT REST ✓
   │                    • Only cluster with key
   │                      can decrypt
```

---

# 5. Policy as Code

## Textual Deep Dive

### Internal Working Mechanism

Policy as Code (PaC) enforces policies **programmatically** rather than relying on manual reviews or documentation:

```
Traditional approach (manual checks):
  Code review checklist:
    ☐ CPU requests set?
    ☐ Memory limits defined?
    ☐ No privileged containers?
    ☐ Security context correct?
  Human reviewer checks ☐☐☐☐ manually
  ❌ Error-prone, inconsistent

Policy as Code approach:
  Kyverno/OPA rule:
    containers[*].resources.requests.cpu exists?
    containers[*].resources.limits.memory exists?
    securityContext.privileged != true?
  Automatic enforcement at admission time
  ✓ Consistent, reliable, auditable
```

**Three Enforcement Points:**

```
                Developer's Machine
                      │
                (linting, testing)
                      ├─ Lint failures → Fix or bypass
                      │
                    Git Push
                      │
                    CI Pipeline
                      │
            (policy checks on manifests)
                      ├─ Policy violations → Block push
                      ├─ Can't merge without fix
                      │ 
                    Git Merge (passed review)
                      │
                    API Server (cluster)
                      │
            Policy enforcement (Kyverno/OPA)
                      ├─ Policy violation → Reject
                      ├─ Pod not created
                      │
                (Audit: policy rejection logged)
```

**How Kyverno and OPA Work:**

**Kyverno (Kubernetes-native):**
```
Kyverno runs as ValidatingWebhook + MutatingWebhook in cluster

When pod is created:
  1. Kubernetes API receives pod manifest
  2. API calls Kyverno webhook before admission
  3. Kyverno evaluates ClusterPolicy rules
  4. Each rule: validate OR mutate
     - Validate: Check if manifest meets policy
     - Mutate: Auto-modify manifest to match policy
  5. Return approve/deny to API
  6. Kubernetes creates pod or rejects
```

**OPA (Open Policy Agent):**
```
OPA runs as separate service, integrated via webhook

When pod is created:
  1. Kubernetes API receives pod manifest
  2. API calls OPA webhook with manifest
  3. OPA evaluates Rego rules (OPA's language)
  4. Rego: Query based on data and policy
  5. OPA returns allow/deny decision
  6. Kubernetes acts on decision

Rego example:
  default allow = false  # Deny by default
  
  allow {
    input.request.kind.kind == "Pod"
    input.request.object.spec.securityContext.runAsNonRoot == true
  }
```

### Architecture Role

Policy as Code sits at **the gate between intent and reality**:

```
Developer writes manifest
     ↓
CI Pipeline validates
     ↓
Git stores
     ↓
GitOps syncs to cluster
     ↓
========= ADMISSION POLICY GATE =========
     ↓
Kyverno/OPA evaluates
  ├─ Passes → Create resource
  └─ Fails → Reject, log, alert
     ↓
Resource runs (or doesn't)
     ↓
Post-deployment audit
```

Policy enforcement works at **two stages:**

**1. Pre-Admission (Preventive):**
```
User tries: kubectl apply -f pod.yaml (with privileged container)
                    ↓
Kyverno webhook intercepts
                    ↓
Rule: "Deny privileged containers"
                    ↓
Match: Pod has privileged: true
                    ↓
Action: DENY
                    ↓
User sees error: "Privileged containers forbidden by cluster policy"
Pod not created ✓
```

**2. Mutations (Auto-Fix):**
```
User applies: pod.yaml (no resource limits)
                    ↓
Kyverno webhook intercepts
                    ↓
Rule: "Inject default resource limits if missing"
                    ↓
Mutate: Add limits to specification
  resources:
    limits:
      cpu: 500m
      memory: 256Mi
                    ↓
Create pod with injected limits ✓
```

### Production Usage Patterns

#### **Pattern 1: Security Policies**
Enforce security best practices automatically.

**Use Case:** Preventing container escapes and privilege escalation

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: security-baseline
spec:
  validationFailureAction: enforce  # Block if violated
  rules:
  - name: require-non-root
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Container must run as non-root user"
      pattern:
        spec:
          containers:
          - securityContext:
              runAsNonRoot: true

  - name: deny-privileged
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Privileged containers not allowed"
      pattern:
        spec:
          containers:
          - =(securityContext):
              =(privileged): false

  - name: require-read-only-root
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Root filesystem must be read-only"
      pattern:
        spec:
          containers:
          - securityContext:
              readOnlyRootFilesystem: true
```

**Result:** ANY pod without these properties is rejected before creation.

#### **Pattern 2: Compliance Policies**
Enforce organizational/regulatory compliance.

**Use Case:** HIPAA/PCI-DSS compliance

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: compliance-encryption
spec:
  validationFailureAction: enforce
  rules:
  - name: require-encryption-in-transit
    match:
      resources:
        kinds:
        - Ingress
    validate:
      message: "HTTPS required (TLS configured)"
      pattern:
        spec:
          tls:
          - hosts:
            - ?
            secretName: ?

  - name: require-pod-disruption-budget
    match:
      resources:
        kinds:
        - Deployment
    validate:
      message: "PodDisruptionBudget required for availability"
      pattern:
        metadata:
          annotations:
            has-pod-disruption-budget: "true"
```

**Effect:** Deployments without PDB can't be created; violates compliance policy.

#### **Pattern 3: Image Provenance**
Ensure only approved/scanned images are deployed.

**Use Case:** Supply chain security

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-image-from-registry
spec:
  validationFailureAction: enforce
  rules:
  - name: verify-image-registry
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Images must come from approved registry"
      pattern:
        spec:
          containers:
          - image: myregistry.azurecr.io/*

  - name: verify-image-signed
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Image must be signed (Cosign signature required)"
      # Integration with Cosign for cryptographic verification
```

#### **Pattern 4: Resource Quota Policies**
Prevent resource exhaustion.

**Use Case:** Shared cluster with multiple teams

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: enforce
  rules:
  - name: cpu-limit
    match:
      resources:
        kinds:
        - Pod
      selector:
        matchLabels:
          enforceQuota: "true"
    validate:
      message: "CPU limit required (max 2 cores)"
      pattern:
        spec:
          containers:
          - resources:
              limits:
                cpu: "?<=2"
              requests:
                cpu: "?"
```

**Effect:** Teams can't create memory-hogging pods; cluster stays stable.

#### **Pattern 5: Mutation Policies (Auto-Fix)**
Automatically inject or modify configurations.

**Use Case:** Injecting monitoring sidecars, network policies

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-monitoring
spec:
  rules:
  - name: inject-prometheus-sidecar
    match:
      resources:
        kinds:
        - Pod
      selector:
        matchExpressions:
        - key: monitoring
          operator: In
          values: ["enabled"]
    mutate:
      patchStrategicMerge:
        spec:
          containers:
          - name: prometheus-agent
            image: prom-agent:latest
            ports:
            - containerPort: 9095
            resources:
              requests:
                cpu: 50m
                memory: 64Mi
```

**Effect:** Pods labeled `monitoring: enabled` automatically get sidecar.

### DevOps Best Practices

#### **1. Start with Audit Mode (Don't Block Immediately)**
```yaml
validationFailureAction: audit  # Log violations but don't block
# Later, switch to enforce once team is aware
validationFailureAction: enforce
```

**Reason:** Gives teams time to fix existing configs; prevents surprise failures.

#### **2. Prioritize High-Impact Rules**
Start with security-critical policies:
```
Priority 1: No privileged containers
Priority 2: Non-root containers
Priority 3: Resource limits
Priority 4: Read-only root
Priority 5: Network policies
```

#### **3. Cluster Admin Exemptions**
Cluster admins may need to bypass some policies:
```yaml
validationFailureAction: enforce
validationFailureExceptionSelector:
  matchExpressions:
  - key: bypass-policy
    operator: In
    values: ["true"]
```

**Usage:**
```yaml
# This pod bypasses the policy
apiVersion: v1
kind: Pod
metadata:
  labels:
    bypass-policy: "true"
spec:
  containers:
  - securityContext:
      privileged: true  # Normally denied, but allow here
```

#### **4. Communicate Policy Changes**
Before enforcing new policy, notify teams:
```bash
# Email or Slack
"Starting March 18, policy: 'no-privileged-containers' will be enforced.
Deadline to fix violations: March 16.
Affected deployments: Check dashboard at ...".
```

#### **5. Mutation Before Validation**
If you're going to auto-fix, don't then reject:
```yaml
rules:
- name: inject-defaults
  mutate: ...  # Auto-add defaults

- name: enforce-defaults
  validate: ...  # Then validate (now passes)
```

#### **6. Log All Policy Decisions**
Enable audit logging to track policy actions:
```bash
# Enable Kyverno audit logs
kubectl logs -n kyverno -l app=kyverno
```

#### **7. Allow Manual Overrides with Approval**
```yaml
validationFailureAction: enforce
# But allow exception via annotation + approval
```

**Approval process:**
```
Developer applies pod with exception
  ↓
Kyverno logs violation attempt
  ↓
Audit team reviews exception request
  ↓
Approve or deny
```

### Common Pitfalls

#### **Pitfall 1: Blocking Default Kubernetes Resources**
```yaml
# ❌ WRONG: Policy blocks kube-system namespace pods
validationFailureAction: enforce
matchResources:
  kinds:
  - Pod
  # Affects ALL pods including kube-system!
```

**Result:** Core cluster components fail to start; cluster becomes unmanageable.

**Fix:**
```yaml
# ✅ RIGHT: Exclude system namespaces
excludeResources:
  namespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: kube-system
```

#### **Pitfall 2: Policies That Interact Negatively**
```
Policy A: "Inject sidecar on all pods"
Policy B: "Resource limits required"
Sidecar doesn't set limits
  ↓
Final pod violates Policy B
  ↓
Pod rejected (even though user did nothing wrong)
```

**Fix:** Ensure mutations set all required fields.

#### **Pitfall 3: No Exception Mechanism**
```yaml
# ❌ WRONG: No way to override for legitimate needs
validationFailureAction: enforce
# (No exceptions allowed)
```

**Result:** Legitimate use cases (security testing, emergency fixes) are blocked.

**Fix:** Allow exceptions with audit trail:
```yaml
validationFailureExceptionSelector:
  matchExpressions:
  - key: exception-approved
    operator: In
    values: ["true"]
  # (Requires security team approval)
```

#### **Pitfall 4: Policies Based on Wrong Assumptions**
```yaml
# ❌ WRONG: Assumes all workloads are your applications
rule:
  deny containers without image::readiness probe
  # (System components might not have probes)
```

**Fix:** Refine match selectors:
```yaml
match:
  selector:
    matchLabels:
      compliance-required: "true"
  # (Only applies to workloads that need it)
```

#### **Pitfall 5: Silent Mutations (User Doesn't Know What Changed)**
```yaml
# ❌ WRONG: Silently inject without notification
mutate:
  patchStrategicMerge:
    spec:
      containers:
      - resources:
          limits:
            cpu: 500m
```

**Result:** Developer can't debug; thinks they didn't set limits.

**Fix:** Document mutations clearly or require explicit opt-in:
```yaml
# ✅ RIGHT: Only mutate if opt-in label
match:
  selector:
    matchLabels:
      auto-inject-limits: "true"
```

---

## Practical Code Examples

### Example 1: Kyverno Security Baseline

A real-world-ready security policy configuration.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: security-baseline
  namespace: kyverno
spec:
  # Start with audit, then enforce
  validationFailureAction: audit
  background: true  # Also check existing resources
  
  rules:
  # Rule 1: Containers must be non-root
  - name: enforce-non-root
    description: "Containers must run as non-root user"
    match:
      resources:
        kinds:
        - Pod
      excludeResources:
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-system
        namespaceSelector:
          matchLabels:
            kubernetes.io/metadata.name: kube-public
    validate:
      message: "runAsNonRoot must be true"
      pattern:
        spec:
          containers:
          - securityContext:
              runAsNonRoot: true
          ephemeralContainers:
          - securityContext:
              runAsNonRoot: true

  # Rule 2: No privileged containers
  - name: deny-privileged
    description: "Privileged containers are not allowed"
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Privileged containers are not allowed"
      pattern:
        spec:
          containers:
          - =(securityContext):
              =(privileged): "false"

  # Rule 3: Immutable root filesystem
  - name: readonly-rootfs
    description: "Root filesystem must be read-only"
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "readOnlyRootFilesystem must be true"
      pattern:
        spec:
          containers:
          - securityContext:
              readOnlyRootFilesystem: true

  # Rule 4: No host network, PID, IPC
  - name: deny-host-namespaces
    description: "Host namespaces are not allowed"
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Host network/PID/IPC not allowed"
      pattern:
        spec:
          =(hostNetwork): "false"
          =(hostPID): "false"
          =(hostIPC): "false"

  # Rule 5: Require resource limits
  - name: require-resource-limits
    description: "CPU and memory limits required"
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Resource limits required"
      pattern:
        spec:
          containers:
          - resources:
              limits:
                cpu: "?<=2"  # Max 2 cores
                memory: "?<=2Gi"  # Max 2GB

  # Rule 6: Require resource requests
  - name: require-resource-requests
    description: "CPU and memory requests required"
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Resource requests required"
      pattern:
        spec:
          containers:
          - resources:
              requests:
                cpu: "?"
                memory: "?"

  # Rule 7: No latest tag
  - name: disallow-latest-tag
    description: "Using latest tag is not allowed"
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Image tag must not be 'latest'"
      pattern:
        spec:
          containers:
          - image: "!*/latest"
```

**Apply to cluster:**
```bash
kubectl apply -f security-baseline.yaml

# Verify
kubectl get cpol security-baseline -o wide
```

**Test (will be rejected):**
```yaml
# test-violation.yaml
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
spec:
  containers:
  - name: app
    image: nginx:latest  # latest tag
    securityContext:
      privileged: true  # Privileged!
      runAsRoot: true   # Root user!
    # No resource limits
    # No read-only root
```

```bash
kubectl apply -f test-violation.yaml

# Output (with enforce mode):
error: pods "insecure-pod" is forbidden:
  pod validation failure:
  enforce-non-root: 'validation error: runAsNonRoot must be true'
  deny-privileged: 'validation error: Privileged containers are not allowed'
  disallow-latest-tag: 'validation error: Image tag must not be latest'
```

---

### Example 2: OPA/Conftest for CI Pipeline

Validate manifests before they reach the cluster.

**Installation:**
```bash
# Install Conftest (OPA CLI tool)
curl -L -o conftest https://github.com/open-policy-agent/conftest/releases/download/v0.40.0/conftest-Linux-x86_64
chmod +x conftest

# Or use Docker:
alias conftest='docker run --rm -v $(pwd):/project openpolicyagent/conftest'
```

**Rego Policy (OPA language):**
```rego
# policy/security.rego
package main

# Default deny
default allow = false

# Allow only if pods pass security checks
allow {
    input.kind == "Pod"
    input.spec.securityContext.runAsNonRoot == true
    input.spec.securityContext.readOnlyRootFilesystem == true
    no_privileged_containers
}

allow {
    input.kind == "Deployment"
    input.spec.template.spec.securityContext.runAsNonRoot == true
}

# Deny privileged containers
no_privileged_containers {
    containers := input.spec.containers[_]
    containers.securityContext.privileged == false
}
no_privileged_containers {
    not input.spec.containers
}

# Enforce resource limits
deny[msg] {
    container := input.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container %s has no memory limit", [container.name])
}

deny[msg] {
    container := input.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container %s has no CPU limit", [container.name])
}

# Deny latest tag
deny[msg] {
    container := input.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container %s uses 'latest' tag", [container.name])
}
```

**CI Pipeline (GitHub Actions):**
```yaml
# .github/workflows/validate-manifests.yaml
name: Validate Manifests

on:
  pull_request:
    paths:
    - '*.yaml'
    - 'k8s/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Setup Conftest
      uses: instrumenta/conftest-action@master
      with:
        files: k8s/**/*.yaml
        policy: policy/

    - name: Run Conftest
      run: |
        conftest test k8s/**/*.yaml -p policy/ -o json > results.json
        
        # Fail if violations found
        if [ $(jq '.[] | select(.failures) | length' results.json) -gt 0 ]; then
          echo "Policy violations found!"
          jq '.[] | select(.failures)' results.json
          exit 1
        fi
```

**Manual usage:**
```bash
# Validate single file
conftest test deployment.yaml -p policy/

# Validate all manifests
conftest test k8s/**/*.yaml -p policy/ -o json

# Output:
PASS - deployment.yaml
FAIL - insecure-pod.yaml
  - Container app has no memory limit
  - Container app has no CPU limit
  - Container app uses 'latest' tag
```

---

### Example 3: Kyverno Mutation (Auto-Inject Labels)

Automatically add labels to all deployments.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-metadata
spec:
  rules:
  - name: inject-labels
    description: "Inject required labels on all deployments"
    match:
      resources:
        kinds:
        - Deployment
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            app-version: "1.0"
            managed-by: "kyverno"
            compliance: "pci"

  - name: inject-annotations
    description: "Inject compliance annotations"
    match:
      resources:
        kinds:
        - Deployment
    mutate:
      patchStrategicMerge:
        metadata:
          annotations:
            compliance-scan-required: "true"
            backup-schedule: "daily"
```

**Before (user creates):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  # ... template
```

**After (Kyverno mutates):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app-version: "1.0"
    managed-by: "kyverno"
    compliance: "pci"
  annotations:
    compliance-scan-required: "true"
    backup-schedule: "daily"
spec:
  # ... template
```

---

## ASCII Diagrams

### Policy Evaluation Flow

```
Developer writes manifest (deployment.yaml)
                │
                ▼
    ┌───────────────────────┐
    │    Git Pre-Commit      │
    │   (Local Linting)      │
    │ Conftest/Pre-commit    │
    └───────────┬───────────┘
                │
         Policy OK?
         │      └─ Violations → Fix or --no-verify
         ▼
      Git Push
         │
         ▼
    ┌───────────────────────┐
    │   GitHub CI Pipeline   │
    │  Validate Manifests    │
    │ OPA/Conftest Rules     │
    └───────────┬───────────┘
                │
        Policy Pass?
    │      └─ Fail → Block PR merge
    ▼
  Git Commit
    (Manifest approved)
    │
    ▼
┌───────────────────────┐
│  GitOps Sync          │
│  ArgoCD applies to    │
│  cluster              │
└───────┬───────────────┘
        │
        ▼
┌───────────────────────────────┐
│  Kubernetes API Server        │
│  ┌─────────────────────────┐  │
│  │ Kyverno Webhook        │  │
│  │  (ValidatingWebhook)    │  │
│  │ ┌───────────────────┐   │  │
│  │ │ Evaluate rules    │   │  │
│  │ │ - non-root?      │   │  │
│  │ │ - resource limits?│  │  │
│  │ │ - read-only?      │   │  │
│  │ └───────────────────┘   │  │
│  └─────────────────────────┘  │
└───────┬───────────────────────┘
        │
   Pass?
   │     └─ Fail → Deny
   ▼
Create Pod / Resource
│
▼
┌───────────────────────┐
│ Audit Log             │
│ "2026-03-17 pod x     │
│  created, policies    │
│  ok, no violations"   │
└───────────────────────┘
```

### Kyverno Mutation Example

```
Original Manifest (User submits)
┌──────────────────────────┐
│ apiVersion: v1           │
│ kind: Pod                │
│ metadata:                │
│   name: app              │
│ spec:                    │
│   containers:            │
│   - name: app            │
│     image: nginx:latest  │
│     (no resource limit)  │
└──────────────────────────┘
         │
         ▼
    Kyverno intercepts
         │
    Policy: Inject limits
    + Inject non-root
    + Inject read-only
         │
         ▼
Mutated Manifest (Auto-fixed)
┌──────────────────────────┐
│ apiVersion: v1           │
│ kind: Pod                │
│ metadata:                │
│   name: app              │
│   labels:                │
│     managed-by: "kyverno"│ <- Added
│ spec:                    │
│   securityContext:       │ <- Added
│     runAsNonRoot: true   │
│   containers:            │
│   - name: app            │
│     image: nginx:latest  │
│     securityContext:     │ <- Added
│       readOnlyRootFS: true│
│     resources:           │ <- Added
│       limits:            │
│         cpu: 500m        │
│         memory: 256Mi    │
└──────────────────────────┘
         │
         ▼
   Kubernetes creates pod
   (All policies satisfied)
```

---

# 6. Observability in GitOps

## Textual Deep Dive

### Internal Working Mechanism

Observability in GitOps provides visibility into three critical domains:

**1. GitOps Sync Health**
```
GitOps Operator → Git → Cluster State Comparison

Are we in sync?
├─ In Sync: Git matches cluster
├─ OutOfSync: Divergence detected
├─ Unknown: Can't compare (network issue)
└─ Syncing: Currently applying changes
```

**2. Application Health**
```
Application metrics → Post-deployment validation

Did the deployment work?
├─ Healthy: Low error rate, normal latency
├─ Degraded: Increased error rate, latency spike
├─ Unknown: Can't reach metrics service
└─ Failed: Errors above threshold
```

**3. Operational Health**
```
Cluster resource usage → Capacity monitoring

Can the cluster sustain this version?
├─ Normal: CPU, memory, disk within limits
├─ WARNING: Trending towards limit
├─ CRITICAL: Approaching resource exhaustion
└─ Unknown: Metrics unavailable
```

**How They Work Together:**

```
Git Update
     ↓
GitOps detects change
     ↓
GitOps applies manifests
     ↓
Sync Status: "Syncing..." (Namespace: default, Revision: abc123)
     ├─ Resources created
     └─ Pods starting
     ↓
Health Check: "Pod Pending" (waiting for resources? image pull?)
     ├─ If image pull: Show image pull error
     ├─ If resources: Show resource request vs limits
     ├─ If timeout: Show "Pod stuck; likely misconfiguration"
     ↓
Sync Status: "In Sync" (Achieved desired state)
     ├─ Git matches cluster
     └─ All health checks pass
     ↓
Application Metrics: Error Rate, Latency, Custom Metrics
     ├─ Monitor for 5-30 minutes
     ├─ Compare vs baseline
     └─ If metrics poor: Rollback
     ↓
Health Status: "Healthy" or "Degraded"
     ├─ Record deployment success
     └─ Archive metrics for audit
```

### Architecture Role

Observability forms the **feedback loop** of the deployment system:

```
Desired State (Git)
     ↓ (GitOps applies)
     ↓
Actual State (Cluster)
     ↓ (Compare)
     ↓
Sync Status + Health Status
     ↓ (Observe metrics)
     ↓
Application Behavior
     ↓ (Analyze & Alert)
     ↓
Decision Engine
     ├─ Proceed (metrics good)
     ├─ Rollback (metrics bad)
     ├─ Pause & Escalate (metrics unclear)
     └─ Maintain (no change)
```

In this loop, **observability is the sensory system**. Without it:
- Can't detect failures
- Can't make rollback decisions
- Can't validate deployments worked
- Can't maintain compliance (no audit trail)

### Production Usage Patterns

#### **Pattern 1: Sync Status Monitoring**
Track whether GitOps is keeping cluster in desired state.

**Dashboard (ArgoCD UI):**
```
Application: production-app
├─ Sync Status: In Sync ✓
├─ Health Status: Healthy ✓
├─ Last Sync: 2 minutes ago
├─ Commit: abc123def456
├─ Author: alice@example.com
├─ Revision: v2.0.1
└─ Resources:
    ├─ Deployment: OK (3/3 pods running)
    ├─ Service: OK (LoadBalancer IP assigned)
    ├─ ConfigMap: OK
    └─ Secret: OK
```

**Alert Conditions:**
```
IF sync_status == "OutOfSync" for 5+ minutes
  → Alert: "Configuration drift detected"
     • Git expects deployment replica: 3
     • Cluster has: 2 (one pod crashed)
     • Manual remediation needed OR auto-sync will fix
```

#### **Pattern 2: Health Check Integration**
Verify pods are actually healthy, not just running.

**Health Check Types:**

```
Pod State:
├─ Pending: Waiting for resources (image pull, node scheduling)
├─ Running: Container started, but health unknown
├─ Succeeded: Completed successfully (for Jobs)
├─ Failed: Error occurred
└─ Unknown: Can't determine state

Probe Status:
├─ Startup Probe: Is the application starting?
│  └─ If fails after timeout, pod killed and restarted
├─ Readiness Probe: Is the application ready for traffic?
│  └─ If fails, pod stays running but removed from Service endpoints
└─ Liveness Probe: Is the application alive/responsive?
   └─ If fails, pod killed and restarted
```

**Example with Probes:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      containers:
      - name: api
        image: myregistry.azurecr.io/api:v2.0
        
        # Startup: Give application 30 seconds to start
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8080
          failureThreshold: 3
          periodSeconds: 10  # Check every 10 sec
          timeoutSeconds: 2

        # Readiness: Check if ready for requests
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          failureThreshold: 3
          periodSeconds: 5
          timeoutSeconds: 2

        # Liveness: Check if still running
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          failureThreshold: 3
          periodSeconds: 10
          timeoutSeconds: 2
```

**Health Status:**
```
Deployment: api-server
├─ Pods: 3/3 Running
├─ Probes:
│  ├─ Startup: 2 passed; 1 still probing
│  ├─ Readiness: 3/3 ready
│  └─ Liveness: 3/3 alive
├─ Status: Progressing
   └─ "2 replicas ready, 1 startup in progress"
└─ (After 30s)
   └─ Status: Healthy
      "All 3 replicas ready"
```

#### **Pattern 3: Metrics-Driven Rollback**
Automatically rollback if application metrics degraded.

**Metrics to Track Post-Deployment:**
```
Error Rate:
├─ Baseline: 0.1% (12 requests per hour with errors)
├─ Threshold: 0.5% or +0.4% absolute
├─ Check: If error_rate > threshold → ROLLBACK

Latency:
├─ Baseline p99: 250ms
├─ Threshold: 400ms or +100ms
├─ Check: If p99_latency > threshold → ROLLBACK

Success Rate:
├─ Baseline: 99.9%
├─ Threshold: < 99% (degradation)
├─ Check: If success_rate < threshold → ROLLBACK

Custom Metrics:
├─ Baseline: Checkout success 95%
├─ Threshold: < 93%
├─ Check: If checkout_success < threshold → ROLLBACK
```

**Decision Tree:**
```
Deployment finished
     ↓
Query Prometheus (Last 5 minutes of metrics)
     ├─ Get error_rate, latency_p99, custom_metrics
     ↓
Compare vs baseline:
  error_rate > threshold?  → FAIL
  latency_p99 > threshold? → FAIL
  checkout_success < threshold? → FAIL
     ↓
Decision:
├─ All metrics pass → "Deployment successful"
├─ Metrics failed → "Rollback initiated"
└─ Metrics unclear → "Manual approval required"
```

#### **Pattern 4: Deployment Timeline Visibility**
See exact timeline of what happened.

**Timeline View (ArgoCD):**
```
2026-03-17 10:00:00 User clicked "Sync" button

2026-03-17 10:00:05 Poll Git repository
                    → Detected commit abc123

2026-03-17 10:00:10 Diff deployment (v1.0 → v2.0)
                    → 3 replicas need resource updates

2026-03-17 10:00:15 Start manifest application

2026-03-17 10:00:20 Update Deployment manifest
                    → Old replica: 3
                    → New replica: 0 (starting rolling update)

2026-03-17 10:00:25 Waiting for pods to start
                    → Pod 1: ImagePullBackOff (image still pulling)

2026-03-17 10:00:45 Pod 1 running (image pulled)
                    → Startup probe checking...

2026-03-17 10:01:00 Readiness probe failed
                    └─ Error: POST /health → 503 Service Unavailable

2026-03-17 10:01:10 Log entry: "Pod failing readiness checks
                              Error: Database connection refused"

2026-03-17 10:01:15 Rollback initiated (max failures exceeded)

2026-03-17 10:01:20 Restore old replicas

2026-03-17 10:01:30 Sync Status: In Sync (reverted)
                    Status: Degraded
                    → Deployment failed; rolled back
                    → Error: "DB connection in new version"
```

### DevOps Best Practices

#### **1. Define Health Probes for Every Container**
Every container should have startup, readiness, and liveness probes.

```yaml
# ❌ WRONG: No probes
containers:
- name: api
  image: app:v1

# ✅ RIGHT: All probes defined
containers:
- name: api
  image: app:v1
  startupProbe: ...
  readinessProbe: ...
  livenessProbe: ...
```

#### **2. Monitor Both Cluster and Application Metrics**
Cluster metrics (CPU, memory) tell if infrastructure is healthy  Application metrics (error rate, latency) tell if deployment succeeded

```
Good practice:
├─ Cluster: CPU 45% (normal)
├─ App: Error rate 0.1% (normal)
→ Deployment successful

Problem 1:
├─ Cluster: CPU 85% (high)
├─ App: Error rate 0.1% (normal)
→ Deployment succeeded but scaling up needed

Problem 2:
├─ Cluster: CPU 45% (normal)
├─ App: Error rate 2% (high)
→ Deployment has bug; rollback needed
```

#### **3. Set Thresholds, Not Just Baselines**
Baselines tell you the normal state; thresholds tell you when to act.

```yaml
# ❌ WRONG: Just report, don't decide
Baseline: error_rate = 0.12%
Actual: error_rate = 0.5%
# (Is this bad? By 400%? But absolute is still small)

# ✅ RIGHT: Thresholds with decision logic
Baseline: error_rate = 0.12%
Threshold:
  - Absolute: > 0.5%
  - Relative: > baseline × 300%  (multiply by 3)
Actual: error_rate = 0.5%
Decision: REJECT (meets both thresholds)
```

#### **4. Alert on "Syncing" Duration**
If sync takes too long, infrastructure changed or git-to-cluster latency increased.

```bash
# Alert: Sync taking longer than normal
IF current_sync_duration > 2 × median_sync_duration
  AND sync_duration > 5 minutes
  THEN alert
```

#### **5. SLI/SLOs for GitOps Health**

Service Level Indicators (SLIs): Measurable aspects
- Sync success rate (% of syncs that succeeded)
- Sync speed (time from git commit to cluster applied)
- Availability (% time in healthy state)

Service Level Objectives (SLOs): Targets
```
SLO: 99% of syncs should succeed
SLO: 99% of time should be In Sync
SLO: 95th percentile sync time < 2 minutes
```

**Monitor:**
```bash
sync_success_rate = syncs_succeeded / total_syncs
  Target: > 99%

in_sync_ratio = time_in_sync / total_time
  Target: > 99%

sync_duration_p95 = percentile(sync_times, 95)
  Target: < 2 minutes
```

#### **6. Aggregate Observability Across Multiple Clusters**
In multi-cluster deployments, aggregate health.

```
Clusters: [us-west, us-east, eu-central]

Global Status:
├─ us-west: In Sync, Healthy ✓
├─ us-east: OutOfSync for 10m ⚠️
├─ eu-central: In Sync, Healthy ✓
├─ Overall: Degraded (1 cluster out of sync)
└─ Action: Investigate us-east sync delay
```

### Common Pitfalls

#### **Pitfall 1: No Probes (Blind Deployments)**
```yaml
# ❌ WRONG
containers:
- name: app
  image: app:v2
  # No probes; Kubernetes doesn't know if app is healthy

# Result: Pod running but not serving traffic
# GitOps shows: "Healthy"
# Reality: Users getting 500 errors
```

#### **Pitfall 2: Probes Too Restrictive**
```yaml
# ❌ WRONG
readinessProbe:
  httpGet:
    path: /api/v1/health
  periodSeconds: 1
  failureThreshold: 1
  timeoutSeconds: 10

# Result: Probe fails once → pod removed from LB
# Pod is still running but marked "NotReady"
# Kubernetes auto-restarts → pod restart loop
#Remedy: Increase failureThreshold
readinessProbe:
  failureThreshold: 3  # Allow 3 consecutive failures
```

#### **Pitfall 3: Metrics Thresholds Too Strict**
```
# ❌ WRONG
Threshold: error_rate > 0.01%
Baseline: error_rate = 0.004%

# Result: Normal operations trigger alerts
# Alert fatigue → alerts ignored
# Real issues missed
```

#### **Pitfall 4: No Baseline, Just Absolute Thresholds**
```
# ❌ WRONG
Threshold: latency > 100ms  (for all services)

# Result:
# - Fast service: normally 10ms; 100ms = 10x slower (bad)
# - Slow service: normally 200ms; 100ms = fast (good)
# Same threshold doesn't work for different services
```

#### **Pitfall 5: Observability Only in Production**
```
# ❌ WRONG
Monitoring enabled only in prod cluster
No observability in canary/staging clusters

# Result: Can't validate metrics before rollout
```

---

## Practical Code Examples

### Example 1: Prometheus Queries for GitOps Health

**Setup (already running Prometheus with Kubernetes metrics):**
```yaml
# prometheus-rules.yaml (Prometheus Rules)
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: gitops-slo
spec:
  groups:
  - name: gitops-health.rules
    interval: 30s
    rules:

    # Record: Sync Success Rate
    - expr: |
        sum(rate(argocd_app_sync_total{phase="Succeeded"}[5m]))
        / sum(rate(argocd_app_sync_total[5m]))
      record: gitops:sync_success_rate:5m

    # Record: Sync Duration (p95)
    - expr: |
        histogram_quantile(0.95,
          sum(rate(argocd_app_sync_duration_seconds_bucket[5m])) by (le)
        )
      record: gitops:sync_duration:p95

    # Alert: Sync Failures
    - alert: GitOps SyncFailureRate
      expr: gitops:sync_success_rate:5m < 0.95
      for: 10m
      annotations:
        summary: "GitOps sync success rate below 95%"
        description: "{{ $value | humanizePercentage }} success rate"

    # Alert: Sync Duration High
    - alert: GitOps SyncDurationHigh
      expr: gitops:sync_duration:p95 > 240  # 4 minutes
      for: 15m
      annotations:
        summary: "GitOps sync taking longer than 4 minutes"

    # Record: Application Health (from deployment status)
    - expr: |
        sum(kube_deployment_status_replicas_ready)
        / sum(kube_deployment_spec_replicas)
      record: app:ready_replica_ratio

    # Alert: Deployment Not Ready
    - alert: DeploymentNotReady
      expr: app:ready_replica_ratio < 1.0
      for: 5m
      annotations:
        summary: "Deployment not ready"
        description: "{{ $value | humanizePercentage }} replicas ready"
```

**Querying:**
```bash
# Current sync success rate
curl 'http://prometheus:9090/api/v1/query?query=gitops:sync_success_rate:5m'

# Sync duration (p95)
curl 'http://prometheus:9090/api/v1/query?query=gitops:sync_duration:p95'

# Historical sync success (last 7 days)
curl 'http://prometheus:9090/api/v1/query_range' \
  --data 'query=gitops:sync_success_rate&start=...'
```

---

### Example 2: Health Checks with Probes

Comprehensive example with all probe types.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-service
  template:
    metadata:
      labels:
        app: api-service
    spec:
      # Wait for graceful termination
      terminationGracePeriodSeconds: 30

      containers:
      - name: api
        image: myregistry.azurecr.io/api:v2.0.0
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 8081
          name: metrics

        # Resource Requests/Limits
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi

        # Startup Probe: Wait for application to start
        # (takes some time to initialize database connections)
        startupProbe:
          httpGet:
            path: /v1/health/startup
            port: http
            scheme: HTTP
          failureThreshold: 30  # 30 checks × 10 sec = 5 minutes max
          periodSeconds: 10
          timeoutSeconds: 2
          successThreshold: 1

        # Readiness Probe: Ready to serve requests?
        # (checks database connectivity)
        readinessProbe:
          httpGet:
            path: /v1/health/ready
            port: http
            scheme: HTTP
          failureThreshold: 3  # 3 failures = remove from LB
          periodSeconds: 5
          timeoutSeconds: 2
          initialDelaySeconds: 5  # Wait 5s after container starts
          successThreshold: 1

        # Liveness Probe: Still alive?
        # (checks if process is responsive)
        livenessProbe:
          httpGet:
            path: /v1/health/live
            port: http
            scheme: HTTP
          failureThreshold: 3  # 3 failures = restart container
          periodSeconds: 10
          timeoutSeconds: 2
          initialDelaySeconds: 10

        # Environment variables
        env:
        - name: LOG_LEVEL
          value: "info"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url

        # Graceful shutdown: receive SIGTERM
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # Time for connection draining

---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  type: LoadBalancer
  selector:
    app: api-service
  ports:
  - port: 80
    targetPort: 8080
    name: http
```

**Expected Behavior:**
1. Container starts
2. Startup probe checks `/v1/health/startup` every 10s for up to 5 minutes
3. Once startup passes, pod is ready to receive traffic
4. Readiness probe continuously checks (every 5s)
   - If fails 3 times in a row: Service LB removes pod
   - When ready again: Pod re-added to LB
5. Liveness probe continuously checks (every 10s)
   - If fails 3 times in a row: Container restarted
   - If restart fails: Pod enters CrashLoopBackOff

---

### Example 3: ArgoCD Application Health Monitoring

**GitOps Application Configuration:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: production-app
  namespace: argocd
spec:
  project: default

  source:
    repoURL: https://github.com/myorg/gitops-config
    targetRevision: main
    path: k8s/production

  destination:
    server: https://kubernetes.default.svc  # Current cluster
    namespace: production

  # Health Assessment
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas  # Don't sync replicas (HPA manages them)

  # Sync Policy
  syncPolicy:
    automated:
      prune: true  # Delete resources not in Git
      selfHeal: true  # Respond to resource drift
      allow_empty: false
    syncOptions:
    - CreateNamespace=true

  # Revise History
  revisionHistoryLimit: 10

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-health-checks
  namespace: argocd
data:
  # Custom health check script
  health.lua: |
    hs = {}
    if obj.status ~= nil then
      if obj.status.replicas == obj.spec.replicas then
        hs.status = "Healthy"
      else
        hs.status = "Progressing"
        hs.message = "Replicas not fully ready"
      end
    end
    return hs
```

**Monitoring the Application Health:**
```bash
# Watch sync status
argocd app get production-app --watch

# Get detailed application status
kubectl get application -n argocd production-app -o yaml

# Stream logs (Kubernetes audit log)
kubectl logs -n argocd deployment/argocd-application-controller -f
```

**Expected Output:**
```
NAME: production-app
SYNC STATUS: Synced
HEALTH STATUS: Healthy

REPO: https://github.com/myorg/gitops-config
TARGET REVISION: main
PATH: k8s/production

SYNC:
  REVISION: abc123def456
  AUTHOR: alice@example.com
  MESSAGE: Deploy v2.0.1
  SYNC TIME: 2026-03-17 10:05:30 UTC
  SYNC RESULT: Succeeded

PROJECT: default

RESOURCES:
  Group: apps
  ├─ Kind: Deployment
  │  Name: api-server
  │  Status: Synced
  │  Health: Healthy (3/3 replicas ready)
  ├─ Kind: Deployment
  │  Name: web-ui
  │  Status: Synced
  │  Health: Progressing (2/3 replicas ready)
  ├─ Kind: Service
  │  Name: api-lb
  │  Status: Synced
  │  Health: Healthy

LATEST ACTIVITY:
  TIME: 2026-03-17 10:05:30
  RESULT: Succeeded
  MESSAGE: successfully synced (3 resources created, 5 resources updated, 0 resources deleted)

NEXT SYNC: 2026-03-17 10:10:30 (5 minute interval)
```

---

## ASCII Diagrams

### GitOps Health Timeline

```
Time →

    Desired (Git)
        │ abc123
        │ v2.0.1
        │
    Actual (Cluster)
        │ v2.0.0
        │ 3 pods
        │
    Sync Status: "OutOfSync" ❌
        │
        └─ User clicks "Sync"
           ↓
           Syncing...
           ├─ Pulling manifests from Git
           ├─ Comparing: Desired vs Actual
           └─ Applying changes
           ↓
    Sync Status: "Syncing" 🔄
        │
    Health Status: "Progressing" 🟡
        ├─ Pod 1: Pulling image...
        ├─ Pod 2: Pulling image...
        └─ Pod 3: Pulling image...
        │
        ├─ Pod 1: ImagePullBackOff ❌
        │  (Image registry timeout)
        │
        ├─ Pod 1: Running 🟢
        │  ├─ Startup probe: Initializing...
        │  └─ Readiness probe: Not ready...
        │
    Sync Status: "Synced" ✓
        │ (Git matches cluster)
        │
    Health Status: "Healthy" 🟢
        ├─ Pod 1: Ready ✓
        ├─ Pod 2: Ready ✓
        └─ Pod 3: Ready ✓
        │
    Application Metrics (Monitor)
        ├─ Error rate: 0.08% ✓
        ├─ Latency p99: 245ms ✓
        ├─ CPU: 35% ✓
        └─ Memory: 280MB ✓
        │
    Final Status: "Healthy" 🟢
        │
        └─ Deployment complete & validated
```

---

# 7. Multi-Cluster Deployments

## Textual Deep Dive

### Internal Working Mechanism

Multi-cluster deployments extend GitOps across multiple Kubernetes clusters, treating them as a federated system:

```
Single Cluster GitOps:
  Git → [Cluster A] → Running Workloads

Multi-Cluster GitOps:
  Git → [Cluster A]
      ├─ /clusters/us-west/
      ├─ /clusters/us-east/
      └─ /clusters/eu-central/
      → [Cluster B]
      → [Cluster C]
      → Synchronized state across ALL
```

**Synchronization Mechanism:**

Each cluster runs its own GitOps operator:
```
ArgoCD Hub Cluster (Central)
├─ Watches Git: clusters/*/
├─ Manages argocd Applications
├─ Each Application points to one cluster
└─ Central view: all clusters' status

ArgoCD Spoke Cluster (Regional)
├─ Watches its directory in Git: clusters/us-west/
├─ Applies manifests locally
├─ Reports status back to hub
└─ Independent; can operate without hub
```

**Communication Pattern:**

```
Developer pushes → Git
                ↓
ArgoCD Hub detects change
                ├─ Cluster A needs update (out of sync)
                ├─ Cluster B needs update (out of sync)
                ├─ Cluster C in sync (no change)
                ↓
ArgoCD spokes sync independently
                ├─ Cluster A applies manifests
                ├─ Cluster B applies manifests
                └─ Cluster C no-op
                ↓
Hub collects status from all spokes
                ├─ Cluster A: In Sync ✓
                ├─ Cluster B: In Sync ✓
                └─ Cluster C: In Sync ✓
                ↓
Global Status: "All clusters synchronized"
```

### Architecture Role

Multi-cluster deployments enable:

**1. Geographic Distribution** - Low latency for users in different regions
**2. High Availability** - Failure in one cluster doesn't impact others
**3. Blue-Green Deployments** - Deploy to Cluster A first, validate, then Cluster B
**4. Disaster Recovery** - Cluster fails; instant failover to another
**5. Scaling** - Distribute load across clusters

### Production Usage Patterns

#### **Pattern 1: Hub-and-Spoke**
Central cluster manages configuration; regional clusters apply same config.

```
Hub (central)
├─ Runs ArgoCD
├─ Git repo as source of truth
├─ ApplicationSet generates Applications per cluster
└─ Aggregates status dashboard

Spokes (regional)
├─ Lightweight ArgoCD or Flux
├─ Apply manifests from Git
├─ Report back to hub
└─ Autonomous operation if hub fails
```

**Use Case:** Global SaaS with presence in 5+ regions.

#### **Pattern 2: Blue-Green Multi-Cluster**
Deploy to one set of clusters first; validate; switch traffic.

```
Blue Environment (Cluster A, B, C)
├─ Running v1.0
├─ 100% of traffic
└─ Production stable

Green Environment (Cluster D, E, F)
├─ Running v2.0 (freshly deployed)
├─ 0% of traffic
├─ Observability team validates
└─ If good, switch traffic; if bad, rollback
```

#### **Pattern 3: Progressive Rollout**
Deploy to increasing number of clusters gradually.

```
Rollout schedule:
├─ Minute 0: Deploy to Cluster A (1% of users)
├─ Minute 10: Deploy to Clusters B, C (5% of users)
├─ Minute 30: Deploy to Clusters D, E (25% of users)
└─ Minute 60: Deploy to F, G, H (100% of users)
```

#### **Pattern 4: Cluster Federation**
Federation API coordinates workload placement across clusters.

```
ApplicationSet (Kubernetes multi-cluster API)
  ├─ Template: Define one Deployment
  ├─ Generator: Generate per-cluster Application
  │  (Apply Kustomize patch per cluster)
  └─ Result: Same app running on all clusters
     with cluster-specific overrides (replicas, resources, etc.)
```

### DevOps Best Practices

#### **1. Consistent Cluster Configuration**
All clusters should have similar base setup (same Kubernetes version, CNI, storage class names).

```bash
# Verify consistency
for cluster in us-west us-east eu-central; do
  kubectl --context=$cluster get nodes
  kubectl --context=$cluster get storageclass
  kubectl --context=$cluster get crd
done
```

#### **2. Network Connectivity Between Clusters**
Clusters need to communicate for cross-cluster service discovery.

```yaml
# Service export (Kubernetes multi-cluster services)
apiVersion: net.gke.io/v1
kind: ServiceExport
metadata:
  name: api-service
  namespace: production
# This service is accessible from other clusters
```

#### **3. Separate Git Branches or Directories Per Cluster**
```
gitops-config/
├── clusters/
│   ├── us-west/
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml (west-specific patches)
│   ├── us-east/
│   │   ├── deployment.yaml
│   │   ├── kustomization.yaml (east-specific patches)
│   └── eu-central/
│       ├── deployment.yaml
│       └── kustomization.yaml (EU compliance patches)
└── base/
    └── deployment.yaml (shared across all)
```

#### **4. Traffic Management Across Clusters**
Use service mesh or DNS to distribute traffic:
```yaml
# Istio VirtualService (span multiple clusters)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api
  namespace: production
spec:
  hosts:
  - api.example.com
  http:
  - route:
    - destination:
        host: api.us-west.svc.cluster.local
      weight: 33
    - destination:
        host: api.us-east.svc.cluster.local
      weight: 33
    - destination:
        host: api.eu-central.svc.cluster.local
      weight: 34
```

#### **5. Backup and Restore Across Clusters**
Backup critical state; restore if cluster fails.

```bash
# Backup Cluster A state
velero backup create prod-backup \
  --include-cluster-resources \
  --ttl 720h

# If Cluster A fails, restore to Cluster D
velero restore create --from-backup prod-backup
```

### Common Pitfalls

#### **Pitfall 1: Assuming Same Behavior Across Clusters**
```
❌ WRONG: Deploy once to Cluster A, expect same result on B
- Cluster A has fast network
- Cluster B in slow region
- Same latency SLOs will fail
```

#### **Pitfall 2: No Cross-Cluster State Replication**
```
❌ WRONG: Database only in Cluster A
- Cluster B can't serve requests (needs DB)
- Cluster A fails → system down

✓ RIGHT: Database (RDS, CosmosDB) external to clusters
- All clusters connect to same DB
- Cluster A failure: Cluster B still queries DB
```

#### **Pitfall 3: GitOps Operator Requires Hub Cluster**
```
❌ WRONG: Spoke clusters can't operate without hub
- Hub fails → spokes can't sync
- Spokes become stale

✓ RIGHT: Spokes are autonomous
- Spoke has its own ArgoCD/Flux
- Continues syncing from Git even if hub down
- Hub only for aggregated dashboard
```

#### **Pitfall 4: No Consistency Checks**
```
❌ WRONG: Clusters drift over time
- Manual change in Cluster A
- Git config for Cluster B forgotten
- Clusters have different versions

✓ RIGHT: Continuous validation
- Policy checks cross-cluster consistency
- Alert if clusters diverge in config
```

---

## Practical Code Examples

### Example 1: ApplicationSet for Multi-Cluster Deployment

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: multi-cluster-app
  namespace: argocd
spec:
  generators:
  # Generator 1: Deploy to each cluster
  - clusters:
      selector:
        matchLabels:
          deploy: "true"

  template:
    metadata:
      name: '{{name}}-app'  # {{name}} = cluster name
    spec:
      project: default
      source:
        repoURL: https://github.com/myorg/gitops-config
        targetRevision: main
        path: apps/my-app
        
        # Kustomize with cluster-specific overlay
        kustomize:
          patches:
          - target:
              kind: Deployment
              name: my-app
            patch: |-
              - op: replace
                path: /spec/replicas
                value: '{{replicas}}'  # From cluster values
          
          - target:
              kind: Deployment
              name: my-app
            patch: |-
              - op: replace
                path: /spec/template/spec/resources/limits/cpu
                value: '{{cpu_limit}}'
      
      destination:
        server: '{{server}}'  # {{server}} = cluster API endpoint
        namespace: production
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true

---
# Clusters are registered with ArgoCD
apiVersion: v1
kind: Secret
metadata:
  name: us-west-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    deploy: "true"  # Generator will pick this up
stringData:
  name: us-west
  server: https://us-west-k8s.example.com
  config: |
    {
      "bearerToken": "...",
      "tlsClientConfig": {"insecure": false}
    }
  replicas: "3"
  cpu_limit: "1000m"

---
apiVersion: v1
kind: Secret
metadata:
  name: us-east-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    deploy: "true"
stringData:
  name: us-east
  server: https://us-east-k8s.example.com
  config: |
    {...}
  replicas: "5"  # Different config per region
  cpu_limit: "2000m"

---
apiVersion: v1
kind: Secret
metadata:
  name: eu-central-cluster
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: cluster
    deploy: "true"
stringData:
  name: eu-central
  server: https://eu-central-k8s.example.com
  config: |
    {...}
  replicas: "4"
  cpu_limit: "1500m"
```

**Result:** ApplicationSet generates 3 Applications (one per cluster), each with cluster-specific replica counts and resource limits.

---

### Example 2: Multi-Cluster Sync Script

```bash
#!/bin/bash
# sync-all-clusters.sh

set -e

CLUSTERS=("us-west" "us-east" "eu-central" "ap-southeast")
GIT_REPO="https://github.com/myorg/gitops-config"
GIT_BRANCH="main"

echo "=== Multi-Cluster Sync ==="

for cluster in "${CLUSTERS[@]}"; do
  echo ""
  echo "Syncing cluster: $cluster"
  
  # Get cluster context
  context=$(kubectl config get-contexts | grep $cluster | awk '{print $1}')
  
  if [ -z "$context" ]; then
    echo "ERROR: Context not found for $cluster"
    continue
  fi
  
  # Trigger ArgoCD sync (if using hub)
  argocd app sync "$cluster-app" --prune
  
  # Wait for sync to complete
  timeout=300
  elapsed=0
  while [ $elapsed -lt $timeout ]; do
    status=$(argocd app get "$cluster-app" -o json | jq -r '.status.operationState.phase')
    
    if [ "$status" = "Succeeded" ]; then
      echo "✓ $cluster sync successful"
      break
    elif [ "$status" = "Error" ]; then
      echo "✗ $cluster sync failed"
      argocd app get "$cluster-app" -o json | jq '.status.operationState.syncResult'
      break
    fi
    
    echo "... waiting for $cluster (elapsed: ${elapsed}s)"
    sleep 10
    ((elapsed+=10))
  done
done

echo ""
echo "=== Cluster Status Summary ==="
for cluster in "${CLUSTERS[@]}"; do
  sync_status=$(argocd app get "$cluster-app" -o json | jq -r '.status.sync.status')
  health_status=$(argocd app get "$cluster-app" -o json | jq -r '.status.health.status')
  
  echo "$cluster: Sync=$sync_status, Health=$health_status"
done
```

**Usage:**
```bash
./sync-all-clusters.sh
```

---

### Example 3: Cross-Cluster Failover

```bash
#!/bin/bash
# failover-to-backup-cluster.sh

PRIMARY_CLUSTER="us-west"
BACKUP_CLUSTER="us-east"
SERVICE_NAME="api-service"
NAMESPACE="production"

echo "Initiating failover from $PRIMARY_CLUSTER to $BACKUP_CLUSTER"

# 1. Check primary cluster health
echo "Checking primary cluster health..."
if ! kubectl --context=$PRIMARY_CLUSTER cluster-info &> /dev/null; then
  echo "Primary cluster unreachable. Proceeding with failover."
else
  echo "Primary cluster still available. Coordinate maintenance window."
  exit 1
fi

# 2. Update DNS to point to backup cluster
echo "Updating DNS (api.example.com) to backup cluster IP..."
BACKUP_LB_IP=$(kubectl --context=$BACKUP_CLUSTER get svc $SERVICE_NAME -n $NAMESPACE \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Update Route 53 / Azure DNS / GCP DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123ABC \
  --change-batch "
  {
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"api.example.com\",
        \"Type\": \"A\",
        \"TTL\": 60,
        \"ResourceRecords\": [{\"Value\": \"$BACKUP_LB_IP\"}]
      }
    }]
  }"

echo "DNS updated to $BACKUP_LB_IP"

# 3. Verify backup cluster has latest data
echo "Verifying backup cluster state..."
kubectl --context=$BACKUP_CLUSTER get deployment -n $NAMESPACE

# 4. Update Git to reflect new primary
echo "Updating deployment status in Git..."
git checkout main
git pull
echo "$BACKUP_CLUSTER" > clusters/current_primary.txt
git add clusters/current_primary.txt
git commit -m "Failover: $PRIMARY_CLUSTER -> $BACKUP_CLUSTER"
git push

# 5. Notify monitoring/alerting
echo "Creating incident incident record..."
curl -X POST https://incidents.example.com/api/incidents \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"Failover: $PRIMARY_CLUSTER to $BACKUP_CLUSTER\",
    \"severity\": \"critical\",
    \"cluster\": \"$BACKUP_CLUSTER\",
    \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }"

echo "✓ Failover complete"
```

---

## ASCII Diagrams

### Hub-and-Spoke Multi-Cluster

```
                     Git Repository
                        (SSoT)
                    /clusters/*/
                          │
                          ▼
                  ┌──────────────────┐
                  │   ArgoCD Hub     │
                  │  (Central)       │
                  ├──────────────────┤
                  │ ApplicationSet   │
                  │ Generates App    │
                  │ per cluster      │
                  └─────┬──────┬─────┘
                        │      │
            ┌───────────┘      └──────────┐
            │                             │
            ▼                             ▼
      ┌──────────────┐            ┌──────────────┐ 
      │ Cluster A    │            │ Cluster B    │
      │ (US-West)    │            │ (US-East)    │
      │ ArgoCD Spoke │            │ ArgoCD Spoke │
      │ Sync status: │            │ Sync status: │
      │ In Sync ✓    │            │ In Sync ✓    │
      └──────┬───────┘            └──────┬───────┘
             │                           │
        App running                  App running
        v2.0, 3 pods                 v2.0, 5 pods
             │                           │
             └──────────┬────────────────┘
                        │
                 Status aggregated
                 in Hub dashboard
                 "Global: Healthy ✓"
```

---

# 8. CICD + GitOps Integration

## Textual Deep Dive

### Internal Working Mechanism

CICD and GitOps form a two-stage deployment pipeline:

```
CICD Stage (Build & Test)
├─ Developer commits code
├─ Pipeline builds image
├─ Pipeline tests image
├─ Pipeline publishes image
└─ Pipeline updates Git manifests
   (Updates image tag in Deployment)

GitOps Stage (Deploy & Sync)
├─ ArgoCD/Flux detects manifest change
├─ GitOps reads updated manifests
├─ GitOps applies to cluster
├─ Operator continuously reconciles
└─ Cluster state matches Git
```

**The Key Difference:**

Traditional CD: Pipeline directly pushes to cluster
```
Pipeline → kubectl apply → Cluster
```

CICD + GitOps: Pipeline updates Git; GitOps watches Git
```
Pipeline → Update Git → GitOps watches → Apply to cluster
```

**Why This Matters:**

```
Direct push (❌):
- Pipeline needs cluster credentials
- If credential leaks, attacker can deploy anything
- Auditing: Who deployed what? Hard to trace (only logs in cluster)
- Rollback: Must have credential to roll back
- Recovery: Lost cluster? Lost history of what was deployed

Git-based push (✓):
- Pipeline never touches cluster (no credentials to leak)
- Git is audit trail (who approved? when? signed?)
- Rollback: git revert, GitOps syncs automatically
- Recovery: Git = source of truth; rebuild cluster, redeploy from Git
```

### Architecture Role

CICD + GitOps sits at the interface between code repo and deployment:

```
Code Repo (GitHub)
    │ (developer pushes code)
    ├─ Trigger CICD pipeline
    │
CICD Pipeline
    ├─ Build image
    ├─ Test image
    ├─ Publish image
    │ (to container registry)
    └─ Update Git config repo with image tag
       (Triggers webhook)
    │
Git Config Repo (GitOps source of truth)
    │ (manifest updated with new image tag)
    ├─ GitOps operator detects change
    │
Kubernetes Cluster
    ├─ GitOps applies manifests
    └─ Pods running new version
```

### Production Usage Patterns

#### **Pattern 1: Image Tag Update Trigger**
CI publishes image; Git manifest updated; GitOps deploys.

```yaml
# .github/workflows/build-and-deploy.yaml
name: Build and Deploy

on:
  push:
    branches: [main]
    paths: ['app/**']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build image
      run: docker build -t myregistry.azurecr.io/app:${{ github.sha }} .
    
    - name: Push image
      run: docker push myregistry.azurecr.io/app:${{ github.sha }}
    
    - name: Update Git manifest with new image
      run: |
        git clone https://github.com/myorg/gitops-config.git
        cd gitops-config
        
        # Update deployment with new image tag
        kustomize edit set image app=myregistry.azurecr.io/app:${{ github.sha }}
        
        git add .
        git commit -m "Deploy app:${{ github.sha }}"
        git push https://${{ secrets.GIT_TOKEN }}@github.com/myorg/gitops-config.git
```

**Result:** Manifest updated → GitOps picks up change → Cluster updated.

#### **Pattern 2: Tag Promotion (Dev → Staging → Prod)**
Image promoted through environments via Git updates.

```
Dev environment:
├─ Commit triggers CI
├─ Image published: app:dev-abc123
├─ Git manifest: app:dev-abc123
└─ ArgoCD syncs to dev cluster

Manual promotion (via PR approval):
├─ DevOps approves: "Promote to staging"
├─ Script/automation updates Git
├─ Manifest: app:staging-abc123
├─ ArgoCD syncs to staging cluster

Staging validation (automated):
├─ Smoke tests pass
├─ Performance tests OK
├─ Create PR: staging → main

Production deployment:
├─ PR merged to main
├─ Git manifest: app:prod-abc123
├─ ArgoCD syncs to prod cluster
```

#### **Pattern 3: Automated Rollback on CI Failure**
If tests fail, don't update Git (no deployment happens).

```
CI Pipeline:
├─ Build ✓
├─ Unit tests ✓
├─ Integration tests ✓
├─ Security scan ✗ (CVE detected)
└─ DON'T update Git
   (Image not tagged as "good")
   (No deployment)

OR if deployed:
├─ Deploy v2.0
├─ Monitor metrics 5 minutes
├─ Error rate: 5% (should be < 0.5%)
├─ Automatically: git revert
└─ ArgoCD syncs: Back to v1.0
```

#### **Pattern 4: Separate Build and Deploy Pipelines**
Build pipeline in one repo; Deploy in another.

```
Code Repo:
└─ .github/workflows/build.yaml
   ├─ Build image
   ├─ Test
   ├─ Publish
   └─ Dispatch event to config repo

Config Repo:
└─ .github/workflows/deploy.yaml
   ├─ Triggered by event from code repo
   ├─ Updates manifests
   ├─ Tests manifest validity
   └─ Commits and pushes
      (ArgoCD watches this repo)
```

**Benefit:** Code repo and config repo have different permission levels.

### DevOps Best Practices

#### **1. Never Store Secrets in CI Pipeline Logs**
```yaml
# ❌ WRONG
git config user.token "${{ secrets.GITHUB_TOKEN }}"
echo "Deployed with token: ${{ secrets.GIT_TOKEN }}"  # Logged!

# ✅ RIGHT
git config user.token "${{ secrets.GIT_TOKEN }}"
# (Secrets not echoed)
```

#### **2. Image Tagging Strategy**
Use semantic versioning or commit SHA, not "latest".

```bash
# ❌ WRONG
docker push app:latest

# ✅ RIGHT: Semantic version
docker push app:v2.1.0

OR: Commit SHA
docker push app:abc123def456
```

#### **3. Helm Values or Kustomize for Environment Differences**
Same image deployed to dev, staging, prod with different configs.

```yaml
bases/
└─ deployment.yaml (image: app:v2.1.0)

overlays/
├─ dev/
│  └─ kustomization.yaml
│     replicas: 1
│     resources/limits: 200m/256Mi
├─ staging/
│  └─ kustomization.yaml
│     replicas: 2
│     resources/limits: 500m/512Mi
└─ prod/
   └─ kustomization.yaml
      replicas: 5
      resources/limits: 2000m/2Gi
      podDisruptionBudget: minAvailable: 2
```

#### **4. Policy Checks in CICD**
Validate manifests before they reach Git (and thus cluster).

```bash
# CI pipeline validation steps
- name: Lint manifests
  run: kubeval k8s/**/*.yaml

- name: Policy check with OPA
  run: conftest test k8s/**/*.yaml -p policy/

- name: Image scan
  run: trivy image myregistry.azurecr.io/app:v2.1.0
```

If any check fails → don't update Git → no deployment.

#### **5. Drift Prevention**
Detect if cluster state diverges from Git.

```bash
# Manual check
argocd app diff production-app

# Automated alert: if out of sync for 30+ minutes
```

### Common Pitfalls

#### **Pitfall 1: CICD Has Cluster Credentials**
```
❌ WRONG: Pipeline runs kubectl apply
export KUBECONFIG=./prod-kubeconfig.yaml
kubectl apply -f deployment.yaml

Risk: Credentials in pipeline config; leaked in logs; pipeline compromise = cluster compromise
```

#### **Pitfall 2: No Version Control for Manifests**
```
❌ WRONG: Pipeline commits without structure
git commit -m "deploy"  # No clear version info

Later: What version ran when? Unknown.
```

#### **Pitfall 3: Image Promotion Without Validation**
```
❌ WRONG: Update prod manifest immediately after build
Pipeline builds → immediately updates prod manifest
No time to test in staging
Bugs go to production

✓ RIGHT: Multi-stage promotion
Build → test in automation → manual approval → staging → validate 24h → prod
```

#### **Pitfall 4: Secrets in Manifests**
```
❌ WRONG: Pipeline updates manifest with secrets
git commit "Update image and add API key"
API key in Git history permanently
```

---

## Practical Code Examples

### Example 1: End-to-End CICD + GitOps Pipeline

```yaml
# .github/workflows/cicd-gitops.yaml
name: Build, Test, and Deploy

on:
  push:
    branches: [main]
    paths: ['app/**']
  pull_request:
    branches: [main]

env:
  REGISTRY: myregistry.azurecr.io
  IMAGE_NAME: app
  GIT_CONFIG_REPO: https://github.com/myorg/gitops-config

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      
    steps:
    - uses: actions/checkout@v3

    - name: Set up Docker
      uses: docker/setup-buildx-action@v2

    - name: Log in to registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ secrets.AZURE_USERNAME }}
        password: ${{ secrets.AZURE_PASSWORD }}

    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=sha,prefix={{branch}}-
          type=semver,pattern={{version}}

    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  test:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3

    - name: Run unit tests
      run: npm test

    - name: Run integration tests
      run: docker run -v /var/run/docker.sock:/var/run/docker.sock ${{ needs.build.outputs.image-tag }} npm run test:integration

    - name: Security scan
      run: |
        wget https://github.com/aquasecurity/trivy/releases/download/v0.40.0/trivy_0.40.0_Linux-64bit.tar.gz
        tar zxvf trivy_0.40.0_Linux-64bit.tar.gz
        ./trivy image ${{ needs.build.outputs.image-tag }}

  deploy:
    needs: [build, test]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3

    - name: Clone GitOps config repo
      run: |
        git clone --depth 1 ${{ env.GIT_CONFIG_REPO }} gitops-config
        cd gitops-config

    - name: Update deployment manifests
      run: |
        cd gitops-config/k8s/production
        
        # Update image tag in deployment
        kustomize edit set image ${{ env.IMAGE_NAME }}=${{ needs.build.outputs.image-tag }}

    - name: Validate manifests
      run: |
        cd gitops-config
        kubeval k8s/**/*.yaml
        conftest test k8s/**/*.yaml -p policy/

    - name: Commit and push changes
      run: |
        cd gitops-config
        git config user.email "ci@example.com"
        git config user.name "CI Bot"
        
        git add k8s/
        git commit -m "Deploy ${{ env.IMAGE_NAME }}:${{ needs.build.outputs.image-tag }}

        Triggered by: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}
        Author: ${{ github.actor }}"
        
        git push https://x-access-token:${{ secrets.GIT_CONFIG_TOKEN }}@github.com/myorg/gitops-config.git main

    - name: Trigger ArgoCD sync
      run: |
        argocd app sync production-app \
          --insecure \
          --server ${{ secrets.ARGOCD_SERVER }} \
          --auth-token ${{ secrets.ARGOCD_TOKEN }}

    - name: Notify Slack
      if: success()
      uses: slackapi/slack-github-action@v1.24.0
      with:
        payload: |
          {
            "text": "✓ Deployed ${{ env.IMAGE_NAME }}:${{ needs.build.outputs.image-tag }} to production"
          }
        webhook-url: ${{ secrets.SLACK_WEBHOOK }}

    - name: Notify on failure
      if: failure()
      uses: slackapi/slack-github-action@v1.24.0
      with:
        payload: |
          {
            "text": "✗ Deployment failed: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          }
        webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

---

### Example 2: Image Promotion Script

```bash
#!/bin/bash
# promote-image.sh
# Usage: ./promote-image.sh app v2.1.0 dev staging

IMAGE_NAME=$1
VERSION=$2
FROM_ENV=$3
TO_ENV=$4

REGISTRY="myregistry.azurecr.io"
GIT_CONFIG_REPO="gitops-config"

echo "Promoting $IMAGE_NAME:$VERSION from $FROM_ENV to $TO_ENV"

# 1. Verify image exists in registry
echo "Verifying image..."
az acr repository show \
  --name myregistry \
  --image "$IMAGE_NAME:$VERSION" \
  || { echo "Image not found"; exit 1; }

# 2. Clone config repo
echo "Cloning config repository..."
git clone https://github.com/myorg/$GIT_CONFIG_REPO

cd $GIT_CONFIG_REPO

# 3. Create promotion branch
BRANCH="promote/$IMAGE_NAME/$VERSION-to-$TO_ENV"
git checkout -b $BRANCH

# 4. Update manifests for target environment
echo "Updating $TO_ENV manifests..."
cd k8s/$TO_ENV
kustomize edit set image $IMAGE_NAME=$REGISTRY/$IMAGE_NAME:$VERSION
cd ../..

# 5. Validate
echo "Validating manifests..."
kubeval k8s/$TO_ENV/**/*.yaml || { echo "Validation failed"; exit 1; }
conftest test k8s/$TO_ENV/**/*.yaml || { echo "Policy check failed"; exit 1; }

# 6. Commit
git add k8s/$TO_ENV/
git commit -m "Promote $IMAGE_NAME:$VERSION to $TO_ENV"

# 7. Push and create PR
git push origin $BRANCH

gh pr create \
  --base main \
  --head $BRANCH \
  --title "Promote $IMAGE_NAME:$VERSION to $TO_ENV" \
  --body "Promote $IMAGE_NAME:$VERSION from $FROM_ENV to $TO_ENV.

Image: $REGISTRY/$IMAGE_NAME:$VERSION
Manifest changes: $(git diff main...HEAD --numstat | wc -l) files"

echo "✓ Promotion PR created"
```

---

### Example 3: Automated Rollback on Metrics Failure

```bash
#!/bin/bash
# auto-rollback-on-metrics.sh

APP_NAME="production-app"
REVISION=$(argocd app get $APP_NAME -o json | jq -r '.status.sync.revision')
NAMESPACE="production"

echo "Monitoring deployment health for $APP_NAME (revision: $REVISION)"

# Monitor for 5 minutes
MONITOR_DURATION=300  # seconds
CHECK_INTERVAL=30
ELAPSED=0
THRESHOLD_BREACHED=false

while [ $ELAPSED -lt $MONITOR_DURATION ]; do
  ERROR_RATE=$(curl -s http://prometheus:9090/api/v1/query \
    --data-urlencode 'query=rate(http_requests_total{status=~"5.."}[5m])' | \
    jq '.data.result[0].value[1]' | tr -d '"')
  
  LATENCY_P99=$(curl -s http://prometheus:9090/api/v1/query \
    --data-urlencode 'query=histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))' | \
    jq '.data.result[0].value[1]' | tr -d '"')
  
  echo "[$((ELAPSED/60))m] Error rate: ${ERROR_RATE}%, Latency p99: ${LATENCY_P99}ms"
  
  # Check thresholds
  if (( $(echo "$ERROR_RATE > 1.0" | bc -l) )) || (( $(echo "$LATENCY_P99 > 500" | bc -l) )); then
    echo "⚠️ Threshold breached! Error: $ERROR_RATE%, Latency: ${LATENCY_P99}ms"
    THRESHOLD_BREACHED=true
    break
  fi
  
  sleep $CHECK_INTERVAL
  ((ELAPSED+=CHECK_INTERVAL))
done

if [ "$THRESHOLD_BREACHED" = true ]; then
  echo "🔴 Metrics degraded. Initiating rollback..."
  
  # Get previous revision from Git
  PREVIOUS_REV=$(git log --oneline | sed -n '2p' | awk '{print $1}')
  
  echo "Reverting to revision: $PREVIOUS_REV"
  git revert $REVISION --no-edit
  git push
  
  # ArgoCD detects the revert and syncs automatically
  echo "✓ Rollback committed. ArgoCD will sync within sync-interval."
  
  # Create incident
  curl -X POST https://incidents.example.com/api/incidents \
    -H "Content-Type: application/json" \
    -d "{
      \"title\": \"Automatic rollback: $APP_NAME\",
      \"description\": \"Error rate $ERROR_RATE%, latency $LATENCY_P99ms\",
      \"revision_rolled_back\": \"$REVISION\",
      \"rolled_back_to\": \"$PREVIOUS_REV\",
      \"severity\": \"high\"
    }"
else
  echo "✓ Deployment monitoring complete. Metrics healthy."
fi
```

---

## ASCII Diagrams

### CICD + GitOps Pipeline

```
Developer
   │
   └─ git push src/app.js
      │
      ▼
Code Repository (GitHub)
├─ Webhook trigger
│  └─ CICD Pipeline
│     ├─ Build Docker image
│     │  └─ myregistry/app:abc123
│     │
│     ├─ Test
│     │  ├─ Unit tests ✓
│     │  ├─ Integration tests ✓
│     │  └─ Security scan ✓
│     │
│     ├─ Publish image
│     │  └─ Push to registry ✓
│     │
│     └─ Update Git manifests
│        └─ k8s/deployment.yaml
│           image: app:abc123
│           └─ git push
│
▼
Config Repository (GitOps Source)
├─ Webhook to ArgoCD
│
▼
GitOps Operator (ArgoCD)
├─ Detect manifest change
├─ Apply to cluster
│
▼
Kubernetes Cluster
├─ Deployment with image: app:abc123
└─ Pods running ✓
```

---

# 9. Self-Service Platforms

## Textual Deep Dive

### Internal Working Mechanism

Self-service platforms enable developers to deploy without relying on DevOps team:

```
Traditional Model (Bottleneck):
Developer → "Can I deploy?"
            ↓
         DevOps Team
            ├─ Reviews request
            ├─ Deploys manually
            ├─ Takes 1-2 hours
            └─ Responds
            
Result: Slow deployment; DevOps is bottleneck

Self-Service Model (Scalable):
Developer → Self-Service Portal
            ├─ Select service
            ├─ Select environment
            ├─ Click "Deploy"
            └─ Deployment happens automatically
            
Result: Instant deployment; DevOps creates guardrails, not bottleneck
```

**The Mechanism:**

```
Developer Portal
├─ UI (Web interface)
├─ Backend (API)
└─ CI/CD Integration

When developer clicks "Deploy":
1. Portal validates inputs against policies (guardrails)
2. If valid: Triggers deployment pipeline
3. Pipeline builds, tests, deploys
4. Feedback to portal (success/failure)
5. Developer sees deployment status in real-time
```

### Architecture Role

Self-service sits at **the interface between developer intent and platform capability**:

```
Developer Needs
    ↓
"I want to deploy my app"
    ↓
Self-Service Portal
├─ Abstracts complexity (CICD, GitOps, K8s)
├─ Enforces guardrails (policies, limits)
└─ Integrates with CICD + GitOps
    ↓
Platform Automation
├─ Builds, tests, publishes
├─ Updates Git (GitOps source of truth)
└─ Cluster reconciles
    ↓
Application Running ✓
```

### Production Usage Patterns

#### **Pattern 1: Template-Based Deployment (Golden Pipelines)**
Developers choose a template; platform fills in details.

```
Template: "Node.js REST API"
├─ Default: 2 replicas, 200m CPU, 256Mi memory
├─ Auto-includes: Health probes, logging, metrics
├─ Dev provides: Service name, Git repo, port
└─ Result: Deployment manifest auto-generated
```

**Developer Experience:**
```
Portal form:
  ├─ Service name: my-api
  ├─ Repository: https://github.com/myorg/my-api
  ├─ Port: 8080
  └─ Environment: staging → [Deploy]

Result: Service running in 2 minutes
(No Kubernetes YAML needed; no DevOps approval)
```

#### **Pattern 2: Progressive Promotion**
Self-service controls promotion through environments with guardrails.

```
Developer deploys to dev (instant):
├─ Dev environment: Fewer restrictions
├─ Auto-approved: Test immediately
└─ No approval needed

Request promotion to staging (auto):
├─ Automated tests run in staging
├─ If tests pass: Auto-promote
├─ If tests fail: Alert developer

Request promotion to production (manual):
├─ Requires devops/platform team approval
├─ Manual review + validation
├─ Approval via Slack/email
└─ If approved: Auto-deploy to prod

Rollback (instant):
├─ Single button "Rollback"
├─ Git revert + sync
└─ Previous version running
```

#### **Pattern 3: Policy-Driven Approval Workflows**
Policies determine if approval needed.

```
Policy 1: "Staging upgrades auto-approved"
Developer requests Postgres 11→12 in staging
  → Auto-approved (test environment)
  → Deployment proceeds

Policy 2: "Production database changes require security review"
Developer requests Postgres 11→12 in production
  → Requires security team approval
  → Blocks until approved
  → Approval via recorded in Git

Policy 3: "Dev environments: no approval needed"
Developer requests anything in dev
  → Auto-approved
  → Instant feedback for fast iteration
```

#### **Pattern 4: Environment Parity**
Self-service enforces same configuration across environments.

```
Dev → Staging → Production

Policy: "Configuration must be identical"
├─ If dev has 2 replicas, staging must have 2 replicas
├─ If dev has 256Mi memory, staging must have 256Mi
├─ Production replicas/resources auto-calculated
│  (may be different for scale, not neglect)

Effect: Developers can't accidentally:
├─ Test on tiny resources but deploy to production
├─ Use beta libraries in staging but old versions in prod
└─ Create divergent configurations
```

### DevOps Best Practices

#### **1. Provide Sane Defaults**
Not every developer is Kubernetes expert.

```yaml
# Template defaults (developer can override)
replicas: 2  # Good for most services
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
readinessProbe:
  httpGet: /health
  initialDelaySeconds: 10
  periodSeconds: 5
```

#### **2. Guardrails, Not Gates**
Make hard to do wrong, not impossible.

```
❌ WRONG: "Developer must use dev environment first"
Result: Developer must remember; easy to skip

✓ RIGHT: "Portal only shows approved environments for each user"
Result: Developer automatically constrained
```

#### **3. Transparent Compliance**
Show developers what behind-the-scenes policies are enforced.

```
Deployment Summary:
├─ Service: my-api
├─ Environment: production
├─ Policies Enforced:
│  ├─ ✓ Resource limits set (cluster policy)
│  ├─ ✓ Non-root container (security policy)
│  ├─ ✓ Health probes configured (observability policy)
│  └─ ✓ PII data handling verified (compliance policy)
├─ Approvals Required:
│  ├─ ⏳ Security team (pending)
│  ├─ ✓ Platform team (approved)
│  └─ ⏳ Finance (cost check)
└─ Estimated Cost: $500/month
```

#### **4. Feedback Loops**
Show deployment progress in real-time.

```
"Deploying my-api:v2.1.0"
├─ ✓ Image built (1m 23s)
├─ ✓ Image scanned (45s, 0 vulnerabilities)
├─ ✓ Tests passed (3m 10s)
├─ ✓ Image published (12s)
├─ ⏳ Manifest update in progress...
├─ ⏳ Waiting for cluster sync...
├─ ✓ Pods starting
│  ├─ Pod 1: StartupProbe... (45s)
│  ├─ Pod 2: StartupProbe... (45s)
│  └─ Pod 3: StartupProbe... (45s)
├─ ✓ All pods ready
├─ ⏳ Health checks...
└─ ✓ Deployment successful (8m 20s total)
```

#### **5. Audit and Compliance**
Every action is auditable and tied to user.

```
Deployment Log:
├─ 2026-03-17 10:00:00 alice clicked "Deploy"
├─ 2026-03-17 10:00:15 CICD pipeline started
├─ 2026-03-17 10:02:30 Image published
├─ 2026-03-17 10:02:45 Git manifest updated (commit abc123)
├─ 2026-03-17 10:02:50 ArgoCD sync triggered
├─ 2026-03-17 10:03:15 Deployment successful
└─ Audit Trail:
   ├─ User: alice@example.com
   ├─ Action: Deployed service: my-api
   ├─ Environment: production
   ├─ Version: v2.1.0
   ├─ Approval Chain: security.approved@10:01, platform_lead@10:01
   └─ Compliance: ✓ All policies passed
```

### Common Pitfalls

#### **Pitfall 1: Self-Service Without Guardrails**
```
❌ WRONG: Developer can set any resource limits, image, replicas
├─ Developer uses latest tag (unreproducible)
├─ Developer sets cores: 100 (resource exhaustion)
├─ Developer sets replicas: 1 (no high availability)
→ System becomes unstable

✓ RIGHT: Self-service with policies
├─ Image must have semantic version tag
├─ CPU limited to 2 cores per container
├─ Minimum 2 replicas for production
```

#### **Pitfall 2: Hidden Policies**
```
❌ WRONG: Developer deploys, gets rejected without clear reason
Portal: "Deployment denied"
(No explanation why)

Developer confused; manual request to DevOps team

✓ RIGHT: Explicit policy feedback
Portal: "Deployment denied: Image must be from approved registry
        (your image: docker.io/custom, allowed: myregistry.azurecr.io)"
```

#### **Pitfall 3: Divergent Environments**
```
❌ WRONG: Self-service allows different configs per environment
Dev: 1 replica, 100m CPU, old PostgreSQL
Staging: Same
Production: Different setup (never tested)

Developer surprised: Works in staging, fails in production

✓ RIGHT: Enforce environment parity
Dev → Staging → Production
Same configuration except scaled replicas/resources
Guarantees production behavior predictable
```

#### **Pitfall 4: No Rollback Option**
```
❌ WRONG: Deployment portal has no rollback
Developer deploys v2.0
Issues found
Developer must contact DevOps to roll back

✓ RIGHT: One-click rollback in portal
Portal shows: "Rollback to v1.9.2" button
Developer clicks
Git reverts instantly
ArgoCD syncs
v1.9.2 running (< 1 minute)
```

---

## Practical Code Examples

### Example 1: Self-Service Portal (Backend API)

```python
# portal-api.py
from flask import Flask, request, jsonify
from github import Github
import subprocess
import time

app = Flask(__name__)

# Configuration
GIT_REPO = "myorg/gitops-config"
ALLOWED_ENVIRONMENTS = {
    "dev": {"replicas": 1, "cpu_limit": "500m", "requires_approval": False},
    "staging": {"replicas": 2, "cpu_limit": "1000m", "requires_approval": False},
    "production": {"replicas": 3, "cpu_limit": "2000m", "requires_approval": True}
}

@app.route('/api/deploy', methods=['POST'])
def deploy_service():
    """Self-service deployment endpoint"""
    
    user = request.headers.get('X-User-Email')  # From auth middleware
    data = request.json
    
    service_name = data.get('service_name')
    environment = data.get('environment')
    version = data.get('version')
    
    # 1. Validation
    if environment not in ALLOWED_ENVIRONMENTS:
        return jsonify({"error": f"Invalid environment: {environment}"}), 400
    
    if not version or not version.startswith('v'):
        return jsonify({"error": "Version must be semantic (v1.2.3)"}), 400
    
    # 2. Authorization
    allowed_envs = get_user_allowed_environments(user)
    if environment not in allowed_envs:
        return jsonify({"error": f"Not authorized for {environment}"}), 403
    
    # 3. Dry-run: Update manifest locally and validate
    try:
        manifest_content = generate_manifest(service_name, environment, version)
        validate_manifest(manifest_content)
    except Exception as e:
        return jsonify({"error": f"Manifest validation failed: {str(e)}"}), 400
    
    # 4. Check approval requirement
    env_config = ALLOWED_ENVIRONMENTS[environment]
    if env_config.get("requires_approval"):
        approval_status = get_approval_status(service_name, environment, version)
        if approval_status != "approved":
            return jsonify({
                "status": "pending_approval",
                "message": "This deployment requires approval",
                "approvers": ["security-team@example.com", "platform-lead@example.com"]
            }), 202  # Accepted but not yet processed
    
    # 5. Trigger deployment
    job_id = trigger_deployment(
        service_name=service_name,
        environment=environment,
        version=version,
        user=user,
        manifest=manifest_content
    )
    
    # 6. Return job tracking
    return jsonify({
        "status": "deployment_started",
        "job_id": job_id,
        "check_status_url": f"/api/deployment/{job_id}",
        "message": f"Deploying {service_name}:{version} to {environment}"
    }), 202


@app.route('/api/deployment/<job_id>', methods=['GET'])
def get_deployment_status(job_id):
    """Check deployment progress"""
    
    status = get_job_status(job_id)
    
    return jsonify({
        "job_id": job_id,
        "status": status['phase'],  # started, running, succeeded, failed
        "progress": status['progress'],  # 0-100%
        "logs": status['logs'],  # Live logs
        "error": status.get('error')
    })


@app.route('/api/rollback/<service>', methods=['POST'])
def rollback_service(service):
    """One-click rollback"""
    
    user = request.headers.get('X-User-Email')
    data = request.json
    environment = data.get('environment')
    
    # 1. Check authorization
    if environment == "production" and not is_admin(user):
        return jsonify({"error": "Not authorized to rollback production"}), 403
    
    # 2. Get previous version from Git
    previous_version = get_previous_deployment(service, environment)
    
    # 3. Trigger rollback deployment
    job_id = trigger_deployment(
        service_name=service,
        environment=environment,
        version=previous_version,
        user=user,
        is_rollback=True
    )
    
    # 4. Log incident
    log_incident(
        title=f"Rollback: {service} in {environment}",
        triggered_by=user,
        previous_version=previous_version,
        reason=data.get('reason', 'Manual rollback')
    )
    
    return jsonify({
        "status": "rollback_started",
        "job_id": job_id,
        "rolled_back_to": previous_version,
        "message": f"Rolling back {service} in {environment} to {previous_version}"
    }), 202


def generate_manifest(service, environment, version):
    """Generate Kubernetes manifest from template"""
    
    env_config = ALLOWED_ENVIRONMENTS[environment]
    
    manifest = f"""
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {service}
  namespace: {environment}
spec:
  replicas: {env_config['replicas']}
  selector:
    matchLabels:
      app: {service}
  template:
    metadata:
      labels:
        app: {service}
        version: {version}
    spec:
      containers:
      - name: {service}
        image: myregistry.azurecr.io/{service}:{version}
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: {env_config['cpu_limit']}
            memory: 512Mi
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          periodSeconds: 5
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          periodSeconds: 10
"""
    return manifest


def trigger_deployment(service_name, environment, version, user, manifest, is_rollback=False):
    """Trigger CI/CD pipeline to deploy"""
    
    # Call GitHub Actions API
    github = Github(os.getenv('GITHUB_TOKEN'))
    repo = github.get_repo(f"myorg/gitops-config")
    
    workflow = repo.get_workflow("deploy.yaml")
    
    run = workflow.create_dispatch(
        ref="main",
        inputs={
            "service": service_name,
            "environment": environment,
            "version": version,
            "triggered_by": user,
            "is_rollback": str(is_rollback)
        }
    )
    
    return run.id


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

---

### Example 2: Self-Service HTML Portal

```html
<!DOCTYPE html>
<html>
<head>
    <title>Self-Service Deployment Portal</title>
    <style>
        body { font-family: Arial; margin: 40px; }
        .form-group { margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input, select { padding: 8px; width: 300px; }
        button { padding: 10px 20px; background: #007bff; color: white; border: none; cursor: pointer; }
        .status { margin-top: 20px; padding: 15px; border: 1px solid #ccc; }
        .log { background: #f5f5f5; padding: 10px; margin-top: 10px; max-height: 300px; overflow-y: auto; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
    </style>
</head>
<body>
    <h1>Self-Service Deployment Portal</h1>
    
    <div class="form-group">
        <label>Service Name:</label>
        <select id="serviceSelect" onchange="loadVersions()">
            <option value="">-- Select Service --</option>
            <option value="api">api</option>
            <option value="web-ui">web-ui</option>
            <option value="worker">worker</option>
        </select>
    </div>
    
    <div class="form-group">
        <label>Version:</label>
        <select id="versionSelect">
            <option value="">-- Loading versions --</option>
        </select>
    </div>
    
    <div class="form-group">
        <label>Environment:</label>
        <select id="environmentSelect">
            <option value="dev">Development (1 replica)</option>
            <option value="staging">Staging (2 replicas)</option>
            <option value="production">Production (3 replicas) - Requires Approval</option>
        </select>
    </div>
    
    <div class="form-group">
        <button onclick="deployService()">Deploy</button>
        <button onclick="rollbackService()" style="background: #dc3545;">Rollback</button>
    </div>
    
    <div id="status" class="status" style="display: none;">
        <h3>Deployment Status</h3>
        <div id="statusMessage"></div>
        <div class="log" id="deploymentLog"></div>
        <div id="approvalMessage" style="display: none; margin-top: 10px; padding: 10px; background: #fff3cd; border: 1px solid #ffc107;">
            <strong>Approval Required</strong>
            <p id="approvalDetails"></p>
        </div>
    </div>
    
    <script>
        async function loadVersions() {
            const service = document.getElementById('serviceSelect').value;
            if (!service) return;
            
            const versions = await fetch(`/api/versions/${service}`).then(r => r.json());
            const select = document.getElementById('versionSelect');
            select.innerHTML = versions.map(v => `<option value="${v}">${v}</option>`).join('');
        }
        
        async function deployService() {
            const service = document.getElementById('serviceSelect').value;
            const version = document.getElementById('versionSelect').value;
            const environment = document.getElementById('environmentSelect').value;
            
            if (!service || !version) {
                alert('Please select service and version');
                return;
            }
            
            document.getElementById('status').style.display = 'block';
            document.getElementById('statusMessage').innerHTML = '⏳ Starting deployment...';
            document.getElementById('deploymentLog').innerHTML = '';
            
            const response = await fetch('/api/deploy', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ service_name: service, version, environment })
            });
            
            const result = await response.json();
            
            if (response.status === 202) {
                if (result.status === 'pending_approval') {
                    document.getElementById('approvalMessage').style.display = 'block';
                    document.getElementById('approvalDetails').innerHTML = `
                        Deployment requires approval from:<br>
                        ${result.approvers.join('<br>')}
                    `;
                } else {
                    pollDeploymentStatus(result.job_id);
                }
            } else {
                document.getElementById('statusMessage').innerHTML = `<span class="error">Error: ${result.error}</span>`;
            }
        }
        
        async function pollDeploymentStatus(jobId) {
            const pollInterval = setInterval(async () => {
                const response = await fetch(`/api/deployment/${jobId}`);
                const status = await response.json();
                
                document.getElementById('statusMessage').innerHTML = `
                    <span class="${status.status === 'succeeded' ? 'success' : 'warning'}">
                    Status: ${status.status} (${status.progress}%)
                    </span>
                `;
                
                document.getElementById('deploymentLog').innerHTML += status.logs + '\n';
                document.getElementById('deploymentLog').scrollTop = document.getElementById('deploymentLog').scrollHeight;
                
                if (status.status === 'succeeded' || status.status === 'failed') {
                    clearInterval(pollInterval);
                }
            }, 2000);
        }
        
        async function rollbackService() {
            const service = document.getElementById('serviceSelect').value;
            const environment = document.getElementById('environmentSelect').value;
            
            if (!confirm('Are you sure you want to rollback?')) return;
            
            const reason = prompt('Reason for rollback:');
            if (!reason) return;
            
            const response = await fetch(`/api/rollback/${service}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ environment, reason })
            });
            
            const result = await response.json();
            document.getElementById('statusMessage').innerHTML = `<span class="success">${result.message}</span>`;
            pollDeploymentStatus(result.job_id);
        }
    </script>
</body>
</html>
```

---

## ASCII Diagrams

### Self-Service Deployment Flow

```
Developer
   │
   └─ Opens Portal
      │
      ├─ Select Service
      ├─ Select Version
      ├─ Select Environment
      └─ Click "Deploy"
         │
         ▼
   Portal API
   ├─ Validate inputs
   ├─ Check permissions
   ├─ Verify version exists
   └─ Check compliance policies
      │
      ├─ If production env
      └─ Check approval status
         │
      Payment
      │ "Pending approval from security-team"
      │ │
      │ └─ Security team reviews in Slack
      │    ├─ /approve deploy-123
      │    └─ Approval recorded in audit log
      │
      ├─ Approval received
      │
      ▼
   Trigger CI Pipeline
   ├─ Build image
   ├─ Test
   ├─ Publish image
   └─ Update Git manifest
      │
      ▼
   GitOps Sync
   ├─ ArgoCD detects change
   ├─ Apply to cluster
      │
      ▼
   Real-time Feedback to Portal
   ├─ Image built ✓
   ├─ Tests passed ✓
   ├─ Pods starting (Pod 1/3)
   ├─ Pods ready ✓
   └─ Deployment successful ✓
```

---

# 10. Disaster Recovery with GitOps

## Textual Deep Dive

### Internal Working Mechanism

Disaster recovery (DR) in GitOps leverages Git as the ultimate recovery source:

```
Traditional DR:
├─ Backup systems (automated)
├─ Restore procedures (manual)
├─ Recovery Time Objective (RTO): 2-4 hours
└─ Recovery Point Objective (RPO): 1 hour

GitOps DR:
├─ Git = backup (version history)
├─ Restore = git clone + kubectl apply
├─ Recovery Time Objective (RTO): 15-30 minutes
└─ Recovery Point Objective (RPO): 5 minutes (last git commit)
```

**How It Works:**

```
Disaster Scenario: Cluster corruption / data loss

Step 1: Declare new cluster as recovery target
  New K8s cluster spins up (blank)
        ↓
Step 2: Point GitOps to recovery cluster
  ArgoCD context: new-cluster
  Git branch: main (same SSoT)
        ↓
Step 3: Reconcile Git state to new cluster
  ArgoCD syncs all manifests
  kubelet creates pods
        ↓
Step 4: Restore application data
  Database backup restored (external)
  Persistent volumes recovered
  Cache warmed up
        ↓
Step 5: Update DNS/traffic routing
  api.example.com → new-cluster-ip
        ↓
Result: Full recovery in ~20 minutes
        All applications running
        Data consistent
```

### Architecture Role

GitOps-based DR eliminates the "what state should we recover to?" problem:

```
Traditional Backup:
├─ What state to restore?
│  (Database as of when? App as of which version?)
├─ Dependency: Manual runbook
├─ Risk: Runbook outdated; recovery fails

GitOps DR:
├─ What state to restore?
│  (Exactly what's in Git at commit abc123)
├─ Dependency: Git history (immutable)
├─ Risk: Zero (Git is source of truth)
```

### Production Usage Patterns

#### **Pattern 1: Multi-Region Active-Active**
Two regions with same services; automatic failover.

```
Region 1 (Primary):
├─ Cluster A: api, web, worker
├─ RDS: Primary database

Region 2 (Standby):
├─ Cluster B: api, web, worker
├─ RDS: Read-only replica

Git + GitOps:
├─ Maintains identical state in both regions
├─ Automatic DNS failover on Region 1 failure
└─ No manual intervention needed

RTO: 1-2 minutes (DNS TTL)
RPO: Real-time (database synchronous replication)
```

#### **Pattern 2: Backup Cluster (Warm Standby)**
Backup cluster running same code; activate on disaster.

```
Production Cluster:
├─ Running v2.0
├─ 100% traffic
├─ All services healthy

Backup Cluster:
├─ Running v2.0 (same as production)
├─ Synced from same Git
├─ 0% traffic (idling)
├─ Resources reserved
└─ Ready to activate

On disaster:
├─ DNS updated to backup
├─ Backup cluster serves 100% traffic
└─ RTO: < 5 minutes
```

#### **Pattern 3: Cluster Bootstrap from Zero**
New cluster bootstrapps itself completely from Git.

```
Bare Kubernetes cluster (just installed)
├─ No applications
├─ No configurations

Install GitOps operator (ArgoCD/Flux)
├─ Point to Git repository
├─ Specify application manifests directory

GitOps reconciliation:
├─ Create namespaces
├─ Create ConfigMaps, Secrets
├─ Create Deployments
├─ Create Services, Ingress
├─ Pull Docker images
├─ Start pods
├─ Attach volumes
├─ Configure networking

Result: Complete application stack running
        Identical to source of truth in Git
```

#### **Pattern 4: Infrastructure Backup with IaC**
Terraform/Pulumi manifests for infrastructure recovery.

```
Infrastructure definitions in Git:
├─ Cluster configuration (nodes, networking, security groups)
├─ Database (RDS instance, backup retention)
├─ Load balancer (DNS, TLS certificates)
├─ Storage (EBS volumes, snapshots)
└─ Monitoring (CloudWatch, dashboards)

On infrastructure failure:
├─ Run: terraform apply -auto-approve
├─ New cluster infrastructure created
├─ Application bootstrap from Git
└─ Full recovery: infrastructure + applications
```

### DevOps Best Practices

#### **1. Regular DR Drills**
Test recovery process monthly; don't wait for real disaster.

```bash
# Monthly DR drill
- Deploy to backup cluster from Git
- Validate all apps running
- Run health checks
- Document any issues
- Clean up
```

#### **2. Immutable Infrastructure**
Don't modify clusters manually; always provision from code.

```
❌ WRONG:
ssh into node
Manual configuration
Hard to replicate

✓ RIGHT:
node_group.tf defines instance configuration
Terraform applies
No SSH needed
Identical nodes created on demand
```

#### **3. Automated Backups**
Snapshot data regularly for RPO (Recovery Point Objective).

```
Database backups:
├─ Automated hourly snapshots
├─ Kept for 30 days
├─ Tested monthly (restore to staging)

Persistent Volumes:
├─ CSI snapshots every 6 hours
├─ Stored in separate region
├─ Locked (can't be deleted)

Git history:
├─ Immutable (GitHub, GitLab keep forever)
├─ No deletion possible
└─ Full audit trail
```

#### **4. Document Recovery Procedures**
Even though Git is source of truth, document exact steps.

```
DR Runbook:
├─ Pre-disaster preparation
│  ├─ Backup account credentials
│  ├─ Document DNS providers
│  └─ Verify backup cluster size
├─ Disaster detection criteria
│  ├─ Cluster API unresponsive
│  ├─ 50%+ pods unhealthy
│  └─ Data corruption detected
├─ Failover procedure
│  ├─ Step 1: Verify disaster (don't act hastily)
│  ├─ Step 2: Spin up backup cluster
│  ├─ Step 3: Run bootstrap from Git
│  └─ Step 4: Update DNS
└─ Post-recovery
   ├─ Verify all services
   ├─ Run smoke tests
   ├─ Notify customers
   └─ Start root cause analysis
```

#### **5. Separate Configuration and Data**
Configuration in Git (recoverable); data external (backed up separately).

```
In Git (easily recovered):
├─ Application code
├─ Kubernetes manifests
├─ Infrastructure as Code
└─ Configuration files

External (separate backup strategy):
├─ Databases (RDS, CosmosDB backups)
├─ Object storage (S3 versioning + replication)
├─ Persistent volumes (EBS snapshots)
└─ Secrets (Vault backups)
```

### Common Pitfalls

#### **Pitfall 1: Untested DR Plan**
```
❌ WRONG: "We have backups; we're covered"
(Backups exist but recovery never tested)
(Real disaster: recovery fails)

✓ RIGHT: Regular DR drills
├─ Monthly full backup restore to staging
├─ Document actual recovery time
├─ Validate data integrity
└─ Update procedures if issues found
```

#### **Pitfall 2: No Cross-Region Replication**
```
❌ WRONG: All data in us-east-1
(us-east data center burns down)
(No backup exists; data lost)

✓ RIGHT: Cross-region replication
├─ RDS read replicas in eu-central
├─ S3 cross-region replication
├─ Git in multiple regions
└─ Can recover from any region's failure
```

#### **Pitfall 3: Manual Runbooks (Out of Date)**
```
❌ WRONG: "Follow the runbook to recover"
(Runbook written 2 years ago)
(Application architecture changed)
(Recovery procedure outdated)

✓ RIGHT: Automated recovery via IaC + GitOps
├─ Code-based recovery (always current)
├─ Version controlled
├─ Tested in CI/CD
```

#### **Pitfall 4: Single Point of Failure**
```
❌ WRONG: Git server in same region as cluster
(Region fails; both cluster and Git repo inaccessible)

✓ RIGHT: Distributed Git + multi-region
├─ Git mirrored in multiple regions (GitHub)
├─ Cluster in separate region
├─ Can always access Git for recovery
```

---

## Practical Code Examples

### Example 1: Automated Cluster Failover Script

```bash
#!/bin/bash
# failover.sh - Multi-region failover automation

set -e

PRIMARY_REGION="us-east-1"
BACKUP_REGION="eu-central-1"
SERVICE_NAME="api"
DATABASE_NAME="prod-db"
DNS_ZONE="example.com"
GIT_REPO="https://github.com/myorg/gitops-config"

echo "🚨 DISASTER RECOVERY INITIATED"

# 1. Confirm disaster
echo "Attempting to communicate with primary cluster..."
if kubectl --context=primary-us-east cluster-info &> /dev/null; then
  echo "⚠️ Primary cluster responding. Aborting failover."
  exit 1
fi
echo "✓ Primary cluster unreachable - failover confirmed"

# 2. Check backup cluster
echo "Verifying backup cluster readiness..."
if ! kubectl --context=backup-eu-central cluster-info &> /dev/null; then
  echo "❌ Backup cluster unreachable - recovery impossible"
  exit 1
fi
echo "✓ Backup cluster operational"

# 3. Ensure latest Git state
echo "Pulling latest Git configurations..."
cd /tmp/gitops-config
git pull https://github.com/myorg/gitops-config.git main
LATEST_COMMIT=$(git rev-parse HEAD)
echo "✓ Latest commit: $LATEST_COMMIT"

# 4. Restore database from backup
echo "Restoring database from backup..."
# Get most recent backup
LATEST_BACKUP=$(aws rds describe-db-snapshots \
  --db-instance-identifier "$DATABASE_NAME" \
  --query 'DBSnapshots[0].DBSnapshotIdentifier' \
  --output text)

echo "Restoring from snapshot: $LATEST_BACKUP"
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "${DATABASE_NAME}-failover" \
  --db-snapshot-identifier "$LATEST_BACKUP" \
  --db-instance-class db.t3.medium \
  --region "$BACKUP_REGION"

# Wait for restoration
AWS_MAX_ATTEMPTS=60
ATTEMPTS=0
while [ $ATTEMPTS -lt $AWS_MAX_ATTEMPTS ]; do
  STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier "${DATABASE_NAME}-failover" \
    --region "$BACKUP_REGION" \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text)
  
  if [ "$STATUS" = "available" ]; then
    echo "✓ Database restored and available"
    break
  fi
  
  echo "Waiting for database... (status: $STATUS)"
  sleep 30
  ((ATTEMPTS++))
done

# 5. Update application configuration
echo "Updating database connection string..."
NEW_DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "${DATABASE_NAME}-failover" \
  --region "$BACKUP_REGION" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Update Secret in backup cluster
kubectl --context=backup-eu-central \
  -n production \
  create secret generic db-config \
  --from-literal=endpoint="$NEW_DB_ENDPOINT" \
  --from-literal=port=5432 \
  --dry-run=client -o yaml | \
  kubectl --context=backup-eu-central apply -f -

# 6. Trigger full GitOps sync
echo "Triggering GitOps full sync..."
kubectl --context=backup-eu-central \
  -n argocd \
  patch app production-app --type merge \
  -p '{"spec":{"syncPolicy":{"automated":null}}}'

# Force sync
argocd app sync production-app \
  --context "$BACKUP_REGION" \
  --server argocd-backup.example.com \
  --auth-token $(cat /secrets/argocd-token)

# Wait for sync
argocd app wait production-app \
  --timeout 600 \
  --context "$BACKUP_REGION" \
  --server argocd-backup.example.com

# 7. Update DNS
echo "Updating DNS records..."
BACKUP_CLUSTER_IP=$(kubectl --context=backup-eu-central \
  -n ingress-nginx \
  get svc ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Update Route 53
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123456789ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$SERVICE_NAME'.'$DNS_ZONE'",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{"Value": "'$BACKUP_CLUSTER_IP'"}]
      }
    }]
  }'

echo "✓ DNS updated to $BACKUP_CLUSTER_IP"

# 8. Validate recovery
echo "Validating recovery..."
sleep 30  # Wait for DNS propagation

HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "https://$SERVICE_NAME.$DNS_ZONE/health")
if [ "$HEALTH_CHECK" = "200" ]; then
  echo "✓ Service responding (HTTP 200)"
else
  echo "⚠️ Service returned HTTP $HEALTH_CHECK"
fi

# 9. Document failover
echo "Recording failover event..."
FAILOVER_ID=$(date +%s)
cat > /tmp/failover-${FAILOVER_ID}.log <<EOF
Failover ID: $FAILOVER_ID
Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Reason: Primary cluster us-east-1 unreachable
Primary Cluster: primary-us-east
Backup Cluster: backup-eu-central
Git Commit: $LATEST_COMMIT
Database Restored From: $LATEST_BACKUP
Database Endpoint: $NEW_DB_ENDPOINT
New Service IP: $BACKUP_CLUSTER_IP
Status: COMPLETE
EOF

# Push incident to GitHub Issues
gh issue create \
  --repo myorg/incident-tracking \
  --title "Failover: Primary cluster US-East failed" \
  --body "See /tmp/failover-${FAILOVER_ID}.log"

# 10. Alert team
echo "⏰ Sending alert to team..."
curl -X POST $SLACK_WEBHOOK \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "🚨 FAILOVER COMPLETE: Primary cluster us-east-1 failed. Service now running on eu-central-1 backup cluster.",
    "attachments": [{
      "color": "danger",
      "fields": [
        {"title": "Service", "value": "'$SERVICE_NAME'", "short": true},
        {"title": "Region", "value": "'$BACKUP_REGION'", "short": true},
        {"title": "Git Commit", "value": "'$LATEST_COMMIT'", "short": false},
        {"title": "Runbook", "value": "https://wiki.example.com/dr-procedures"}
      ]
    }]
  }'

echo "✅ FAILOVER COMPLETE"
echo "Service running on backup cluster: $BACKUP_CLUSTER_IP"
echo "Incident tracking: /tmp/failover-${FAILOVER_ID}.log"
```

---

### Example 2: IaC for Disaster Recovery (Terraform)

```hcl
# main.tf - Disaster recovery infrastructure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

provider "aws" {
  region = var.backup_region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.backup.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.backup.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.backup.token
}

# ========================================
# Backup Cluster (Standby)
# ========================================

resource "aws_eks_cluster" "backup" {
  name     = "${var.cluster_name}-backup"
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = aws_subnet.backup[*].id
    security_group_ids = [aws_security_group.backup.id]
  }
}

resource "aws_eks_node_group" "backup" {
  cluster_name    = aws_eks_cluster.backup.name
  node_group_name = "${var.cluster_name}-backup-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.backup[*].id
  version         = var.kubernetes_version

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 3
  }

  instance_types = ["t3.large"]
}

# ========================================
# Database Backup (RDS Multi-AZ)
# ========================================

resource "aws_db_instance" "primary" {
  identifier       = "${var.db_name}-primary"
  engine           = "postgres"
  engine_version   = "15.0"
  instance_class   = "db.t3.medium"
  allocated_storage = 100

  # High Availability
  multi_az = true
  
  # Backup retention
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  
  # Enable automated backups
  copy_tags_to_snapshot = true
  enable_iam_database_authentication = true
  
  # Encryption
  storage_encrypted = true
  kms_key_id       = aws_kms_key.database.arn

  # Skip final snapshot on destroy (for testing)
  skip_final_snapshot = false
  final_snapshot_identifier = "${var.db_name}-final-snapshot-${formatdate("YYYY-MM-DD", timestamp())}"

  tags = merge(var.common_tags, { Name = "${var.db_name}-primary" })
}

# ========================================
# Database Read Replica (Backup Region)
# ========================================

resource "aws_db_instance" "backup_replica" {
  identifier          = "${var.db_name}-backup-replica"
  replicate_source_db = aws_db_instance.primary.identifier
  
  # Deploy in backup region
  availability_zone = "${var.backup_region}a"
  
  # If primary fails, promote to standalone
  skip_final_snapshot = true

  tags = merge(var.common_tags, { Name = "${var.db_name}-backup-replica" })
}

# ========================================
# Object Storage Backup (S3)
# ========================================

resource "aws_s3_bucket" "application_backup" {
  bucket = "${var.cluster_name}-backup-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, { Name = "${var.cluster_name}-backup-bucket" })
}

resource "aws_s3_bucket_versioning" "application_backup" {
  bucket = aws_s3_bucket.application_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "application_backup" {
  depends_on = [aws_s3_bucket_versioning.application_backup]

  bucket = aws_s3_bucket.application_backup.id

  role = aws_iam_role.s3_replication.arn

  rule {
    status = "Enabled"
    destination {
      bucket       = aws_s3_bucket.application_backup_replica.arn
      storage_class = "GLACIER"  # Cheaper long-term storage
    }
  }
}

# ========================================
# GitOps Operator (ArgoCD) on Backup Cluster
# ========================================

resource "helm_release" "argocd_backup" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
      configs = {
        repositories = {
          gitops = {
            url = var.gitops_repo
            usernameSecret = {
              name = "git-credentials"
              key  = "username"
            }
            passwordSecret = {
              name = "git-credentials"
              key  = "password"
            }
          }
        }
      }
    })
  ]
}

# ========================================
# Monitoring for Disaster Detection
# ========================================

resource "aws_cloudwatch_metric_alarm" "cluster_health" {
  alarm_name          = "${var.cluster_name}-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ClusterNodeCount"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"  # Alert if less than 2 nodes

  dimensions = {
    ClusterName = aws_eks_cluster.primary.name
  }

  alarm_actions = [aws_sns_topic.disaster_alert.arn]
}

resource "aws_sns_topic" "disaster_alert" {
  name = "${var.cluster_name}-disaster-alerts"

  tags = merge(var.common_tags, { Name = "${var.cluster_name}-disaster-alerts" })
}

# ========================================
# Output
# ========================================

output "backup_cluster_endpoint" {
  value       = aws_eks_cluster.backup.endpoint
  description = "Backup cluster API endpoint"
}

output "backup_database_endpoint" {
  value       = aws_db_instance.backup_replica.endpoint
  description = "Backup database endpoint"
}

output "backup_s3_bucket" {
  value       = aws_s3_bucket.application_backup.id
  description = "S3 bucket for application backups"
}
```

---

### Example 3: Cluster Bootstrap Script

```bash
#!/bin/bash
# bootstrap-cluster.sh - Bootstrap cluster  from Git

set -e

CLUSTER_NAME=$1
GIT_REPO=$2
GIT_BRANCH=${3:-main}
ARGOCD_NAMESPACE="argocd"

if [ -z "$CLUSTER_NAME" ] || [ -z "$GIT_REPO" ]; then
  echo "Usage: $0 <cluster-name> <git-repo> [git-branch]"
  exit 1
fi

echo "🚀 Bootstrapping cluster: $CLUSTER_NAME"

# 1. Setup kubectl context
echo "Setting up kubectl context..."
kubectl config use-context "$CLUSTER_NAME"
kubectl cluster-info

# 2. Create namespaces
echo "Creating namespaces..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
EOF

# 3. Install ArgoCD
echo "Installing ArgoCD..."
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argocd/argo-cd -n argocd \
  --set server.service.type=LoadBalancer

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m

# 4. Get ArgoCD auth token
ARGOCD_SERVER=$(kubectl -n argocd get svc argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD Server: $ARGOCD_SERVER"

# 5. Create ApplicationSet for Git repository
echo "Creating ApplicationSet to sync from Git..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: git-repo
  namespace: argocd
stringData:
  url: $GIT_REPO
  username: github-bot
  password: $GITHUB_TOKEN
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bootstrap
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $GIT_REPO
    targetRevision: $GIT_BRANCH
    path: k8s/base
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# 6. Monitor sync status
echo "Waiting for initial sync..."
for i in {1..60}; do
  SYNC_STATUS=$(kubectl -n argocd get app bootstrap -o jsonpath='{.status.sync.status}')
  
  if [ "$SYNC_STATUS" = "Synced" ]; then
    echo "✓ Sync complete!"
    break
  fi
  
  echo "Sync status: $SYNC_STATUS (attempt $i/60)"
  sleep 10
done

# 7. Verify deployment
echo "Verifying applications..."
kubectl get deployment -n production
kubectl get pods -n production

# 8. Health check
echo "Running health checks..."
READY_PODS=$(kubectl -n production get pods -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -o True | wc -l)
TOTAL_PODS=$(kubectl -n production get pods -o jsonpath='{.items | length}')

echo "Ready pods: $READY_PODS / $TOTAL_PODS"

if [ $READY_PODS -eq $TOTAL_PODS ]; then
  echo "✅ Cluster bootstrap COMPLETE"
else
  echo "⚠️ Some pods not ready. Investigating..."
  kubectl describe pods -n production | grep -A 5 "Not Ready"
fi

echo ""
echo "Next steps:"
echo "1. ArgoCD Server: $ARGOCD_SERVER"
echo "2. Default password: $ARGOCD_PASSWORD (change after login)"
echo "3. Git repo synced from: $GIT_REPO ($GIT_BRANCH)"
```

---

## ASCII Diagrams

### Multi-Region Active-Active Failover

```
Normal Operation
┌────────────────────────────────┬────────────────────────────────┐
│      Region 1 (US-East)        │    Region 2 (EU-Central)       │
├────────────────────────────────┼────────────────────────────────┤
│  Cluster A                     │  Cluster B                     │
│  ├─ api (3 pods)               │  ├─ api (3 pods)               │
│  ├─ web (3 pods)               │  ├─ web (3 pods)               │
│  └─ worker (2 pods)            │  └─ worker (2 pods)            │
│                                │                                │
│  GitOps: In Sync ✓             │  GitOps: In Sync ✓             │
│  Health: Healthy ✓             │  Health: Healthy ✓             │
└───────────────────┬────────────┴────────────────┬───────────────┘
                    │                            │
         ┌──────────▼────────────────────────────▼──────────┐
         │           DNS Load Balancing                     │
         │  50% traffic →  Cluster A                       │
         │  50% traffic →  Cluster B                       │
         └───────────────────────────────────────────────────┘
                            │
                            ▼
                      Users Served


Disaster: Region 1 Fails
┌────────────────────────────────┬────────────────────────────────┐
│      Region 1 (US-East) ❌    │    Region 2 (EU-Central)       │
├────────────────────────────────┼────────────────────────────────┤
│  Cluster A                     │  Cluster B                     │
│  ├─ api ❌ (pods evicted)      │  ├─ api (3 pods)               │
│  ├─ web ❌ (nodes unreachable) │  ├─ web (3 pods)               │
│  └─ worker ❌                  │  └─ worker (2 pods)            │
│                                │                                │
│  Unavailable                   │  GitOps: In Sync ✓             │
│                                │  Health: Healthy ✓             │
└────────────────────────────────┴───────────────────┬────────────┘
                                                     │
                         ┌──────────────────────────▼─────────────┐
                         │  Automatic Failover                    │
                         │  Route 100% traffic to Cluster B       │
                         └────────────────────────────────────────┘
                                        │
                                        ▼
                           All Users → Cluster B
                              (No data loss)
```

**Study Guide Complete** ✅

This guide is designed to be modular and scalable. Each section can be adapted to your organization's specific tools (ArgoCD vs Flux, Kyverno vs OPA, AWS vs Azure vs GCP) while maintaining the same conceptual foundations.

For hands-on practice, set up a test cluster and implement each pattern in sequence. The practical code examples provided serve as starting points for your own environment.

---

# 11. Hands-On Scenarios

## Production Incident Scenarios

These scenarios reflect real-world challenges DevOps engineers encounter. Each includes problem statement, architecture context, troubleshooting steps, and resolution.

---

## Scenario 1: Canary Deployment Gone Wrong - Automatic Rollback Decision

### Problem Statement

**Time: 2026-03-17 14:23 UTC**

Your team deployed version 2.5.0 of the payment service using canary deployment. Initial 5% traffic shift worked fine. Then at 10% traffic:

```
ERROR: Payment service error rate: 8.5%
       (Normal baseline: 0.3%)
       
DURATION: 3 minutes of degraded service
IMPACT: ~500 failed transactions
REVENUE: -$2,300
```

Your alerting fired, but the deployment isn't rolling back. The canary is stuck at 10% traffic. Investigation needed.

### Architecture Context

```
Deployment Strategy: Canary with Flagger
├─ Service: payment-api
├─ Previous version: 2.4.0 (98% traffic)
├─ Canary version: 2.5.0 (2% traffic at T0)
├─ Metrics source: Prometheus
├─ Analysis templates: HTTPRoutes to check error rate
└─ Service mesh: Istio

Git-based deployment:
├─ payment-api Deployment manifest in Git
├─ Flagger Canary manifest in Git
├─ promotion-controller watches Git for new versions
└─ ArgoCD syncs both manifests
```

### Troubleshooting Steps

**Step 1: Verify ArgoCD sync status**

```bash
# Check if manifests are synced
argocd app get payment-app -o json | jq '{
  sync_status: .status.sync.status,
  health: .status.health.status,
  last_sync: .status.operationState.finishedAt
}'

OUTPUT:
{
  "sync_status": "OutOfSync",
  "health": "Progressing",
  "last_sync": "2026-03-17T14:22:30Z"
}

# OutOfSync = manifests in cluster differ from Git
# This is preventing Flagger from updating
```

**Step 2: Check Flagger Canary status**

```bash
# Examine the Canary resource (what rolled out, not rolled back)
kubectl get canary payment-canary -o yaml | grep -A 20 "status:"

OUTPUT:
status:
  canaryWeight: 10
  failedChecks: 2
  lastTransitionTime: "2026-03-17T14:25:00Z"
  phase: "Failed"
  trackedConfigs:
  - name: payment-api-deployment-2-5-0  # Tracking new version
    uid: abc123

# phase: Failed = canary detected errors
# failedChecks: 2 = two consecutive Prometheus checks failed
# canaryWeight stuck at 10 = rollback not happening
```

**Step 3: Inspect AnalysisTemplate metrics**

```bash
# Check what metrics Flagger is analyzing
kubectl get analysistemplate payment-metrics -o yaml

OUTPUT:
metrics:
- name: error-rate
  interval: 1m
  thresholdRange:
    max: 1.0  # 1% max error rate
  query: |
    sum(rate(http_requests_total{status=~"5.."}[1m]))
    /
    sum(rate(http_requests_total[1m]))
```

**Step 4: Manually check Prometheus**

```bash
# Query the same metric Flagger uses
curl 'http://prometheus:9090/api/v1/query?query=error_rate_payment'

OUTPUT:
{
  "value": [1710691200, "0.085"]  # 8.5% error rate!
}

# Threshold is 1%, actual is 8.5%
# Flagger correctly detected the failure
```

**Step 5: Find root cause**

```bash
# Check payment-api logs
kubectl logs -n production deployment/payment-api-canary --tail=50 | grep -i "error"

OUTPUT:
ERROR database connection timeout
ERROR failed to connect to postgres:5432

# Ah! Database connection issue in 2.5.0
# New code has different connection pool settings
```

**Step 6: Investigate the code change**

```bash
# Review the deployment git diff
git diff v2.4.0..v2.5.0 -- payment-api/deployment.yaml

# Check environment variables in Deployment
kubectl get deployment payment-api-canary -o yaml | grep -A 10 env:

OUTPUT:
- name: DB_POOL_SIZE
  value: "100"  # Changed from 10 (in 2.4.0)
- name: DB_TIMEOUT
  value: "1000ms"  # Changed from 5000ms

# The connection pool size too high; hitting DB limits
# Timeout too aggressive; legitimate queries failing
```

### Resolution

**Option A: Rollback (Automatic)**

Flagger detected errors and should rollback. If it didn't, manually trigger:

```bash
# 1. Trigger rollback
kubectl patch canary payment-canary \
  -p '{"spec":{"suspend":true}}' \
  --type merge

# 2. ArgoCD reverts to previous version
git revert HEAD  # Commits revert
git push

# 3. ArgoCD detects Git change
# 4. Flagger syncs Canary manifest
# 5. Canary rolls back to v2.4.0

# Verify rollback
kubectl get canary payment-canary -o jsonpath='{.status.canaryWeight}'
# OUTPUT: 0  (canary deactivated)
```

**Option B: Fix Forward (Keep 2.5.0)**

If the bug is quickly fixable:

```bash
# 1. Fix the code
payment-api/src/database.py:
  - change DB_POOL_SIZE from 100 to 25
  - change DB_TIMEOUT from 1000ms to 3000ms

# 2. Build and test locally
docker build -t payment-api:2.5.1 .
docker run payment-api:2.5.1 npm test  # Tests pass

# 3. Push image
docker tag payment-api:2.5.1 myregistry.azurecr.io/payment-api:2.5.1
docker push myregistry.azurecr.io/payment-api:2.5.1

# 4. Update Git manifest
payment-api/deployment.yaml:
  image: payment-api:2.5.1
  env:
  - name: DB_POOL_SIZE
    value: "25"
  - name: DB_TIMEOUT
    value: "3000ms"

git add payment-api/
git commit -m "Fix DB pool configuration in payment-api:2.5.1"
git push

# 5. Flagger restarts canary with 2.5.1
```

### Best Practices Demonstrated

1. **Tight error thresholds** - 1% error rate caught fast (< 1 minute)
2. **Automated rollback** - No human intervention; policy-driven
3. **Metrics-driven decisions** - Not subjective; data-driven thresholds
4. **Git as recovery** - Rollback = git revert (repeatable)
5. **Configuration version control** - DB pool settings in Git (auditable)

### Post-Incident Actions

```
Root Cause: Database connection pool settings not tested under load

Action Items:
1. Add integration test: "payment-api with 100 concurrent DB connections"
2. Add pre-deployment load test: "Verify DB pool settings"
3. Review database capacity: "Can RDS handle new pool size?"
4. Update runbook: "How to rollback payment-api"
5. Schedule blameless postmortem

Timeline:
├─ 2026-03-17 14:23 UTC - Error rate spike
├─ 2026-03-17 14:25 UTC - Flagger detected (< 2 min response)
├─ 2026-03-17 14:26 UTC - Rollback initiated
├─ 2026-03-17 14:27 UTC - v2.4.0 serving 100% traffic
└─ Total incident: 4 minutes

Lessons:
- Canary deployment prevented wide-spread issue (only 10% saw error)
- Without canary: all users affected; much higher loss
- Policy-driven automation faster than manual intervention
```

---

## Scenario 2: Multi-Cluster Application Promotion with Drift Detection

### Problem Statement

**Time: 2026-03-18 09:15 UTC**

You're promoting the frontend service from staging cluster (EU) to production cluster (US). Promotion involves:

1. Code tested in EU staging
2. Deployed to EU production
3. Deployed to US production

However, after promotion to US production, ArgoCD reports the cluster is **out of sync** despite Git being correct.

```
ArgoCD Status: OutOfSync
              ↓
Cluster State: Different from Git
Reason: Unknown (manual change? drift?)
```

### Architecture Context

```
Multi-cluster setup:
├─ Cluster: eu-prod
│  ├─ frontend: v3.2.1
│  ├─ sync status: In Sync ✓
│  ├─ ArgoCD: healthy
│  └─ Last sync: 2 min ago

├─ Cluster: us-prod
│  ├─ frontend: ???  (different version?)
│  ├─ sync status: Out of Sync ❌
│  ├─ ArgoCD: healthy (but cluster drifted)
│  └─ Last sync: 10 min ago

Git (source of truth):
├─ clusters/eu-prod/frontend.yaml: image v3.2.1
├─ clusters/us-prod/frontend.yaml: image v3.2.1 (just updated)
└─ Both should be identical
```

### Troubleshooting Steps

**Step 1: Compare Git vs. Cluster State**

```bash
# What's in Git for US production
git show HEAD:clusters/us-prod/frontend.yaml | grep image:

OUTPUT:
image: frontend:v3.2.1

# What's actually running in US cluster
kubectl --context=us-prod get deployment frontend -o yaml | grep image:

OUTPUT:
image: frontend:v3.1.9  # WRONG! Old version still running

# Cluster has OLD version; Git has NEW version
# = Drift detected
```

**Step 2: Check ArgoCD sync details**

```bash
# Get ArgoCD application status
argocd app get us-prod-frontend -o json | jq '.status | {
  sync_status,
  health,
  resources: [.resources[] | {name: .name, kind: .kind, health: .health}]
}'

OUTPUT:
{
  "sync_status": "OutOfSync",
  "health": "Unknown",
  "resources": [
    {
      "name": "frontend",
      "kind": "Deployment",
      "health": "Progressing"  # Rolling update in progress?
    }
  ]
}

# Application detected drift; health=Progressing suggests update happening
```

**Step 3: Check Deployment rollout status**

```bash
# Is Kubernetes actually applying the new version?
kubectl --context=us-prod rollout status deployment/frontend

OUTPUT:
Waiting for rollout to finish: 1 out of 3 new replicas have updated...

# Ah! Rollout is happening but slow
# Let's check why
```

**Step 4: Inspect pod events**

```bash
# Check why new pods aren't starting
kubectl --context=us-prod describe pod -l app=frontend | grep -A 5 Events:

OUTPUT:
Events:
  Type    Reason            Message
  ----    ------            -------
  Warning ImagePullBackOff  Failed to pull image frontend:v3.2.1: manifest not found in registry

# IMAGE NOT IN REGISTRY!
# CI/CD built 3.2.1 but didn't push to container registry
# Kubernetes can't pull image → pods can't start
```

**Step 5: Check CI/CD pipeline**

```bash
# What happened in the build pipeline?
gh workflow log --name "build-frontend" --limit=1

OUTPUT:
Build Log (frontend:v3.2.1):
✓ Code built
✓ Tests passed
✓ Image built locally
✗ Image push failed: authentication error
  └─ Registry credentials expired

# Pipeline built image but failed to push
# So Git was updated (manifest points to v3.2.1)
# But image doesn't exist in registry
```

### Root Cause Analysis

```
Timeline of events:
├─ 09:00 UTC - Developer commits code
├─ 09:01 UTC - CI pipeline triggers
├─ 09:05 UTC - Build succeeds, tests pass
├─ 09:06 UTC - Image push to registry FAILS (cred expired)
├─ 09:07 UTC - Pipeline updates Git manifest anyway (BUG!)
│            └─ Points to non-existent v3.2.1 image
├─ 09:08 UTC - Git notification sent to ArgoCD
├─ 09:10 UTC - ArgoCD tries to deploy v3.2.1
│            └─ Can't pull image from registry
├─ 09:15 UTC - Alert fires: "Deployment OutOfSync"

ROOT CAUSE:
Pipeline should NOT update Git if image push fails
Current logic: "Update manifest regardless"
Correct logic: "Update manifest ONLY if image published"
```

### Resolution

**Option A: Rollback (Fastest)**

```bash
# 1. Revert problematic Git commit
git revert HEAD
git push

# 2. ArgoCD detects Git change
# 3. ArgoCD syncs cluster to previous version (v3.1.9)
# 4. Deployment valid image exists
# 5. Cluster syncs successfully

# Verify
kubectl --context=us-prod get deployment frontend -o jsonpath='{.spec.template.spec.containers[0].image}'
# OUTPUT: frontend:v3.1.9 ✓
```

**Option B: Fix Forward + Manual Sync**

```bash
# 1. Manually push image to registry
docker tag frontend:v3.2.1 myregistry/frontend:v3.2.1
docker push myregistry/frontend:v3.2.1
# ✓ Image published!

# 2. Update Git manifest (credentials renewed)
payment-api/deployment.yaml:
  spec:
    containers:
    - name: frontend
      image: myregistry/frontend:v3.2.1

git add .
git commit -m "Fix: publish missing image v3.2.1"
git push

# 3. Force ArgoCD sync
argocd app sync us-prod-frontend --force

# 4. Verify
kubectl --context=us-prod get deployment frontend -o jsonpath='{.spec.template.spec.containers[0].image}'
# OUTPUT: myregistry/frontend:v3.2.1 ✓
```

### Key Lessons

1. **Pipeline validation** - Don't update manifests if build/push fails
2. **Image availability** - Verify image exists before pointing manifests to it
3. **Drift detection** - ArgoCD caught the issue; cluster couldn't run outdated manifest
4. **Credential rotation** - CI/CD credentials should be rotated/monitored
5. **Multi-cluster consistency** - Same code should behave identically across clusters

### Prevention

```yaml
# Updated CI/CD pipeline (.github/workflows/build.yaml)
jobs:
  build-and-deploy:
    steps:
    - name: Build image
      run: docker build -t frontend:${{ github.sha }} .
    
    - name: Test image
      run: docker run frontend:${{ github.sha }} npm test
    
    - name: Push image to registry
      run: docker push myregistry.azurecr.io/frontend:${{ github.sha }}
      # If this fails, STOP. Don't proceed to manifest update.
    
    - name: Update manifest ONLY if push succeeded
      if: success()  # <-- Key: Only proceed if push succeeded
      run: |
        kustomize edit set image frontend=myregistry.azurecr.io/frontend:${{ github.sha }}
        git commit -m "Deploy frontend:${{ github.sha }}"
        git push
```

---

## Scenario 3: Secrets Rotation Across Environments Without Service Disruption

### Problem Statement

**Time: 2026-03-19 10:00 UTC**

Your organization's compliance policy requires rotating database passwords every 90 days. You have:

- Production database password (stored in Sealed Secret)
- 50+ pods that use this password
- Zero tolerance for downtime

Challenge: Rotate password without dropping active connections.

### Architecture Context

```
Database: PostgreSQL (RDS)
├─ Current password: abc123xyz (used by all 50 pods)
├─ Connection pool: 20 connections per pod = 1,000 total

Kubernetes Secret:
├─ Secret name: db-credentials
├─ Mounted as: /run/secrets/db-creds
├─ Sealed Secret version: v1alpha1

Deployment:
├─ App: api-service
├─ Replicas: 50
├─ Rolling update strategy: maxSurge=10%, maxUnavailable=0%
└─ Connection timeout: 5 seconds
```

### Troubleshooting / Implementation Steps

**Step 1: Verify current secret**

```bash
# Check current password in sealed secret
kubectl get sealedsecret db-credentials -o yaml

OUTPUT:
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: db-credentials
spec:
  encryptedData:
    password: AgBxK2vEp9... (encrypted)

# Unseal to verify (in local cluster only, never in prod log)
kubeseal -d < sealed-db-creds.yaml | jq '.data.password | @base64d'
# OUTPUT: abc123xyz (current password)
```

**Step 2: Rotate database password**

```bash
# 1. Connect to RDS
psql -h prod-db.c9akciq32.us-east-1.rds.amazonaws.com -U admin

# 2. Create new password
postgres=# ALTER USER app_user WITH PASSWORD 'newpass_xyz789';
# ✓ New password set in database
```

**Step 3: Prepare new kubernetes secret**

```bash
# 1. Create new secret (not yet sealed)
cat > new-db-creds.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: production
type: Opaque
stringData:
  password: "newpass_xyz789"
  username: "app_user"
  host: "prod-db.c9akciq32.us-east-1.rds.amazonaws.com"
  port: "5432"
EOF

# 2. Seal the secret
kubeseal -f new-db-creds.yaml -w new-db-creds-sealed.yaml

# 3. Update Git
git add new-db-creds-sealed.yaml
git commit -m "Rotate: db-credentials password (compliance policy)"
git push
```

**Step 4: Staged rollout (ensure old/new coexist)**

```bash
# Strategy: Keep old password valid while pods transition to new

# 1. Database now accepts BOTH passwords
# (Keep old password valid for 30 minutes)
# Application attempts new password first
# If fails, retries with old password
# (or: App maintains two connections - one with each password)

# 2. ArgoCD detects manifest change
# 3. Triggers rolling update on Deployment

# Verify the strategy:
$ kubectl get pods -l app=api-service | head -5
NAME                                READY
api-service-abc123-xyz789 (old)     1/1   <- Using old password
api-service-def456-uvw012 (new)     1/1   <- Using new password
api-service-ghi789-rst345 (new)     1/1
api-service-jkl012-opq678 (old)     1/1
```

**Step 5: Monitor connection pool**

```bash
# Watch for connection errors during transition
watch -n 5 'kubectl logs -l app=api-service --tail=5 | grep -i "connection\|password"'

# Expected: No errors; old and new pods coexisting
# Warning signs:
# - "invalid password"
# - "connection refused"
# - "pool exhausted"
```

**Step 6: Verify transition complete**

```bash
# 1. Check all pods running (none stuck in pending)
kubectl get pods -l app=api-service | grep -v "Running"
# (should return nothing)

# 2. Database telemetry: old password connections → 0
# Query RDS logs:
# "Authentication failed": 0
# "User app_user": online

# 3. Test new password access
kubectl run test-pod --rm -it --image=postgres --command -- \
  psql -h prod-db.c9akciq32.us-east-1.rds.amazonaws.com \
  -U app_user -d testdb -c "SELECT 1"
# Prompted for password; enter: newpass_xyz789
# Output: 1 ✓ (successful)
```

**Step 7: Remove old password from database**

```bash
# Once all pods transitioned (30 minutes later):
psql -h prod-db.c9akciq32.us-east-1.rds.amazonaws.com -U admin

postgres=# ALTER USER app_user WITH PASSWORD 'newpass_xyz789';
# (Now only new password works)

# Kubernetes secret automatically updated (via GitOps)
# Old password no longer needed anywhere
```

### Best Practices

```yaml
# Secrets Rotation Policy
rotation:
  frequency: "every 90 days"
  next_rotation: "2026-06-18"
  notification:
    - security-team@example.com
    - devops-oncall@example.com

# Implementation checklist
- [ ] Schedule rotation 1 week in advance
- [ ] Update infrastructure team (if external DB)
- [ ] Test rotation in dev/staging first
- [ ] Plan 1-hour maintenance window
- [ ] Have rollback password ready
- [ ] Monitor connections during rotation
- [ ] Verify zero connection failures
- [ ] Document completion in change log
- [ ] Update compliance audit trail
```

---

## Scenario 4: Policy Violation Prevention in Self-Service Portal

### Problem Statement

**Time: 2026-03-20 14:32 UTC**

Developer tries deploying to production via self-service portal and receives error:

```
❌ Deployment denied: Policy violation

Policy: "Resource requests must be set"
Your request:
  Service: billing-service
  Image: myregistry/billing-service:latest  # Wrong Tag
  Replicas: 20  # Too high
  CPU request: NOT SET  # Policy violation
  Memory limit: 512Mi
  
Violations:
1. Image tag 'latest' not allowed (use semantic version)
2. CPU request missing (required for all services)
3. Requested 20 replicas (max per service: 10)
```

Developer claims: "This worked yesterday! What changed?"

### Architecture Context

```
Self-Service Portal:
├─ Backend: Policy validation gate
├─ Policies: Kyverno + OPA
├─ Enforcement points:
│  ├─ Pre-deployment validation (Portal)
│  ├─ CI/CD pipeline checks
│  └─ Admission controller (cluster)

Policies enforced:
├─ Image sources: Only internal registry
├─ Image tags: No 'latest', only semantic versions
├─ Resource limits: Always set
├─ Replicas: Max 10 per environment
└─ Compliance: Non-root containers, network policies
```

### Troubleshooting Steps

**Step 1: Check policy enforcement history**

```bash
# When were policies last updated?
git log --oneline -- policies/ | head -5

OUTPUT:
abc1234 feat: Enforce image source policy (2026-03-20 08:00 UTC)  <-- Changed today!
def5678 feat: Add CPU request policy (2026-03-15)
ghi9012 feat: Add replica limits (2026-03-01)

# Policy was updated TODAY, 6 hours ago
# Developer committed code YESTERDAY with old assumptions
```

**Step 2: Review new policy**

```bash
# What changed in the policy?
git show abc1234 -- policies/image-sources.rego

OUTPUT:
# Old policy (allowed "latest"):
deny[msg] {
  image[tag]
  tag == "latest"
  msg := "Image tag 'latest' forbidden"
}
# (This was disabled)

# New policy (enforces semantic version):
deny[msg] {
  image[tag]
  not startsWith(tag, "v")
  not regex.match(`^[0-9]+\.[0-9]+\.[0-9]+`, tag)
  msg := "Image must be semantic version (v1.2.3 or 1.2.3)"
}

# Change approved by: security-team@example.com
# Rationale: Prevent accidental deployment of non-versioned images
```

**Step 3: Test policy in staging first**

```bash
# Developer can test deployment in staging (different policy set)
kubectl config use-context staging
k apply -f deployment.yaml

# Policy check in staging (simulated):
# This resource would be DENIED in production
# Suggestion: Update your manifest:
# 1. Change image tag from 'latest' to 'v2.4.0'
# 2. Add resource requests:
#    requests:
#      cpu: 250m
#      memory: 256Mi
# 3. Reduce replicas: 20 → 10
```

**Step 4: Update portal to show policy requirements**

Portal should display EXPECTED format:

```
Service Deployment Form:
├─ Service name: billing-service
├─ Image tag: [Text Input]
│  └─ Format: Must be semantic version (v1.2.3 or use 1.2.3)
│     Examples: v2.4.0, 3.1.0, 1.0.0-beta
├─ Replicas: [Number Input]
│  └─ Max: 10 (policy limit)
│  └─ Recommended: 2-5 for HA
├─ CPU request: [Required]
│  └─ Min: 100m, Max: 2000m
├─ Memory limit: [Required]
│  └─ Min: 128Mi, Max: 2Gi
└─ [Deploy] [Cancel]
```

### Resolution

**Option 1: Developer Updates Manifest**

```yaml
# Old (violated policies):
image: myregistry/billing-service:latest
replicas: 20
# No resources

# New (complies):
image: myregistry/billing-service:v2.4.0  # Semantic version
replicas: 10  # Within limit
resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

**Option 2: Portal Shows Policy Requirements Upfront**

```python
# Portal API should validate BEFORE submitting to cluster

@app.route('/api/validate-deployment', methods=['POST'])
def validate_deployment():
    data = request.json
    violations = []
    
    # Check image tag
    image_tag = data.get('image_tag', '')
    if image_tag == 'latest':
        violations.append({
            'field': 'image_tag',
            'violation': 'Cannot use "latest" tag',
            'suggestion': 'Use semantic version (v2.4.0)'
        })
    
    # Check resources
    if 'cpu_request' not in data or not data['cpu_request']:
        violations.append({
            'field': 'cpu_request',
            'violation': 'CPU request required',
            'suggestion': '250m recommended'
        })
    
    # Check replicas
    replicas = data.get('replicas', 1)
    if replicas > 10:
        violations.append({
            'field': 'replicas',
            'violation': f'Max 10 replicas allowed (you requested {replicas})',
            'suggestion': '10'
        })
    
    if violations:
        return jsonify({
            'valid': False,
            'violations': violations,
            'message': f'{len(violations)} policy violations found'
        }), 400
    
    return jsonify({'valid': True}), 200
```

### Key Lessons

1. **Policy as guardrails** - Prevents invalid deployments automatically
2. **Communication** - Policies should be transparent; show requirements upfront
3. **Grace period** - When policies change, give dev team time to adapt
4. **Testing in lower envs** - Staging uses different (looser) policies for development
5. **Documentation** - Every policy should explain "why" and "how to comply"

---

## Scenario 5: GitOps Cluster Recovery - Complete Cluster Loss

### Problem Statement

**Time: 2026-03-21 03:47 UTC (Mid-Night)**

AWS AZ fails completely. Auto-recovery didn't help. Kubernetes cluster gone. You have:

- 5 minute RTO (Recovery Time Objective)
- Complete data loss unacceptable
- 200 users impacted (business customer)

You must:
1. Bring up new cluster
2. Restore application state
3. Failover traffic
4. All within 5 minutes

### Architecture Context

```
Original Setup:
├─ Cluster: prod-us-east-1a
├─ Data: RDS with automated backups (hourly snapshots)
├─ Git: All manifests in GitHub
├─ Secrets: Sealed Secrets in Git

Recovery Options:
├─ Option A (Fastest): Recreate from IaC + restore DB
├─ Option B (Slower): Velero restore + re-sync
└─ Option C (Slowest): Manual recovery
```

### Recovery Steps (5-minute target)

**Minute 0: Disaster Declared**

```bash
# 1. Verify: Cluster truly down
kubectl cluster-info

OUTPUT:
error: Unable to connect to the server: dial tcp i/o timeout
# Yes, cluster gone

# 2. Declare incident
STATUS_PAGE_UPDATE: "Major incident: Attempting recovery"
SLACK_ALERT: "🚨 CRITICAL: prod-us-east cluster lost"
```

**Minute 0-1: Spin up replacement infrastructure**

```bash
# Pre-prepared: Terraform to create new cluster (cached modular config)
cd /home/devops/terraform/aks-cluster
terraform apply -auto-approve \
  -var="cluster_name=prod-us-east-recovery" \
  -var="region=us-east-1" \
  -var="node_count=5"

# Outputs bootstrap kubeconfig
# Save: export KUBECONFIG=/tmp/recovery-kubeconfig
```

**Minute 1-2: Bootstrap GitOps operator**

```bash
# Install minimal operator to sync from Git
helm repo add argocd https://argoproj.github.io/argo-helm
helm install argocd argocd/argo-cd -n argocd \
  --set server.service.type=LoadBalancer \
  --wait --timeout=60s

# Note: --wait ensures operator ready before proceeding
```

**Minute 2-3: Trigger full Git sync**

```bash
# Point operator to Git repository
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: recovery-all-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/gitops-config
    targetRevision: main
    path: k8s/production
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: false  # Be careful with auto-prune in recovery
      selfHeal: false
    syncOptions:
    - CreateNamespace=true
    # Force sync immediately
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 1m
EOF

# ArgoCD begins syncing all manifests
kubectl get app -A  # Monitor progress
```

**Minute 3-4: Restore database**

```bash
# Restore latest RDS snapshot
AWS_LATEST_SNAPSHOT=$(aws rds describe-db-snapshots \
  --query 'DBSnapshots[0].DBSnapshotIdentifier' \
  --output text)

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier "prod-us-east-recovery" \
  --db-snapshot-identifier "$AWS_LATEST_SNAPSHOT" \
  --db-instance-class db.t3.large \
  --publicly-accessible \
  --no-wait  # Don't wait; happens in parallel

# Update Secret in cluster with new endpoint (auto via GitOps)
NEW_DB_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier "prod-us-east-recovery" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Database secret already in Git (encrypted); ArgoCD will sync it
```

**Minute 4-5: Verify and failover**

```bash
# 1. Check pods running
kubectl get pods -n production | grep Running

OUTPUT:
pod/api-service-xyz789-01          1/1       Running
pod/api-service-xyz789-02          1/1       Running
pod/web-ui-abc123-01               1/1       Running
pod/worker-def456-01               1/1       Running

# 2. Health check
curl http://recovery-cluster-lb/health

OUTPUT:
HTTP 200 OK
{
  "status": "healthy",
  "version": "v2.4.0",
  "database": "connected"
}

# 3. Update DNS for failover
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.example.com",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{"Value": "'$NEW_LB_IP'"}]
      }
    }]
  }'

# 4. Verify traffic flowing
watch -n 2 'kubectl logs -n production pod/api-service-xyz789-01 | tail -1'
# Should show incoming requests
```

### Post-Recovery

```bash
# 1. Document timeline
INCIDENT_REPORT:
├─ 03:47 UTC - AZ failure detected
├─ 03:48 UTC - Cluster loss confirmed
├─ 03:49 UTC - Infrastructure provisioning started
├─ 03:51 UTC - GitOps operator running + syncing
├─ 03:52 UTC - Database restore initiated
├─ 03:54 UTC - Full system healthy
├─ 03:55 UTC - DNS updated; traffic failing over
└─ Total: 8 minutes (Target was 5, slightly over)

# 2. Root cause analysis (later)
├─ AWS AZ had underlying storage failure
├─ Auto-recovery kicked off but failed
├─ Recommended: Check with AWS on improvements

# 3. Improvements for next time
├─ Pre-warm recovery infrastructure (save 1 min)
├─ Cache Helm repos locally (save 30s)
├─ Use faster database restore options (save 1 min)
└─ Target: 3-minute recovery
```

---

# 12. Interview Questions for Senior DevOps Engineers

These questions target architects and senior operational engineers with 5-10+ years of experience. They emphasize reasoning, tradeoffs, and production wisdom rather than memorized facts.

---

## Question 1: Architecture Decision - Push vs. Pull-Based Deployments

**Question:**

"Your organization is choosing between push-based CD (pipeline directly deploys to cluster) and pull-based GitOps (cluster pulls from Git). Explain the security, operational, and auditability tradeoffs. Under what circumstances would you choose one or the other?"

### What Good Answers Address

**Security Considerations:**
- Push requires cluster credentials in pipeline (credential exposure risk)
- Pull keeps credentials localized to cluster
- But pull requires Git credentials in cluster (different risk profile)
- Compromise scenario differences matter

**Operational Considerations:**
- Push: Faster feedback (pipeline owns deployment)
- Pull: Slower, but operator can always view expected state (Git = SSoT)
- Recovery implications

**Auditability:**
- Push: "What version deployed? Grep the pipeline logs"
- Pull: "What version deployed? Check Git history"
- Compliance requirement implications

**Example Strong Answer:**

```
"Pull-based GitOps is operationally superior in 95% of cases because:

Security:
- Pipeline credentials never leave CI/CD system
- Cluster credentials only used for pulling manifests (read-only)
- Attack surface reduced; compromised pipeline doesn't auto-compromise cluster

Auditability:
- Git history IS the deployment audit trail
- Reverting deployment = 'git revert' (provenance clear)
- In push model, must dig through pipeline logs + PR approvals

Tradeoff - When I'd use push anyway:
- Feedback latency critical (< 1 minute RTO)
- Cluster can't reach Git reliably (air-gapped network)
- Cost: Push is slightly cheaper (no operator; periodic sync overhead)

Real scenario: One org required 'all deployment decisions captured in Git'
for compliance. They had 200+ deployments/day. Push model couldn't meet
this; they switched to GitOps even though it meant accepting 3-minute
deployment latency instead of 30-second direct push.
"
```

---

## Question 2: Multi-Cluster Strategy - Availability vs. Operational Burden

**Question:**

"Design a deployment strategy across 3 geographic regions for a financial services application. It must survive single-region failure. Walk through your reasoning on: data replication strategy, failover automation, testing?"

### What Good Answers Address

**Data Consistency vs. Availability:**
- Can you accept eventual consistency?
- What's acceptable RPO (Recovery Point Objective)?
- Synchronous vs. asynchronous replication tradeoffs

**Failover Automation:**
- Manual approval or automatic?
- How do you prevent false positives (avoiding thrashing)?
- How do you test without disrupting production?

**Operational Complexity:**
- More regions = more things to break
- How do you make this operationally manageable?
- Where does human judgment still needed?

**Example Strong Answer:**

```
"Financial services = strong consistency requirements.

Architecture:
- Primary: us-east-1 (active, 100% traffic)
- Secondary: eu-central (HA standby, 0% traffic)
- Tertiary: ap-southeast (backup only, not in active rotation)

Data Strategy:
- Database: RDS with synchronous read replicas (us-east → eu-central)
- RPO: ~0 (cross-region replication is synchronous)
- Tradeoff: Slightly higher latency for writes (wait for replica ack)
  But financial compliance > latency; acceptable tradeoff

Failover Automation:
I'd NOT make this fully automatic for financial services. Reasoning:
- Automatic failover risks split-brain (both regions think they're primary)
- Financial transactions can't double-process
- Regulatory: need human decision point for compliance

Instead: Semi-automated
- Automated detection (3 successive health check failures)
- Alerts to on-call + senior DevOps
- Human approval required (literal button click in Slack/portal)
- Once approved: automated traffic switch + database promotion

Testing Strategy:
- Monthly DR drill in secondary cluster
- Simulate primary failure (without actually destroying it)
- Run customer transaction scenarios
- Measure actual failover time (target: < 5 minutes)
- Document any gaps

Why I'd pick this vs. active-active:
- Active-active more complex (distributed locking, split-brain Prevention)
- Financial data integrity > absolute latency
- For insurance, same approach; for video streaming (lower $ sensitivity),
  I'd do active-active across more regions
"
```

---

## Question 3: Blast Radius and Progressive Delivery

**Question:**

"A production bug affected 5% of requests across all regions traffic shift to canary. You suspect it's a traffic pattern issue, not a code bug; happens only with specific request types. How do you safely test a fix without exposing more users?"

### What Good Answers Address

**Diagnosis Before Fix:**
- How do you isolate the problematic traffic pattern?
- Where do you test without risking prod blast radius?

**Progressive Rollout Precision:**
- Can you target specific traffic pattern (vs. just percent of traffic)?
- How does your progressivity get smarter (vs. uniform rolling)?

**Rollback Readiness:**
- If your fix is wrong, how fast can you rollback?
- What's your "abort threshold"?

**Example Strong Answer:**

```
"Diagnosis first. Here's my approach:

Step 1: Isolate Traffic Pattern
- Query app logs filtered by error: 'error rate by request path'
- Likely shows: POST /api/payments has 15% error rate
  (Normal paths: 0.2%)
- Root cause: Payment requests specifically affected

Step 2: Understand Why
- Look at deployment changes in last 2 hours
- Check: Did payment service dependencies change? Rate limiting?
- Hypothesis: New billing service has rate limit; first version hit it
- Proof: Monitor: 'RateLimitExceeded errors' in logs

Step 3: Test Fix Safely
- Fix: Payment service catches RateLimitExceeded, retries with exponential backoff
- Testing in canary: Can't just deploy; it's same code
- Instead: Feature flag approach
  - Deploy the fix but feature-flagged OFF
  - In canary traffic, enable the flag for 1% of payment requests
  - Monitor: RetryCount metrics; error rates
  - If working: Gradually increase flag exposure (10%, 50%, 100%)
  - This is MORE targeted than blind canary rollout

Step 4: Precise Metrics
- Instead of 'overall error rate < 1%', I'd use:
  'payment requests: error rate < 0.5%'
  'payment requests: p99 latency < 500ms'
  'retry success rate > 98%'
- These micro-metrics more predictive than macro

Step 5: Abort Plan
- If retry success rate drops below 90%: Auto-rollback
- If p99 latency exceeds 1s: Auto-rollback
- If after 30 min, metrics look good: promote to full prod

Why this approach over uniform canary:
- We KNOW it's payment traffic; blind 5% might miss it
- Feature flags let us test logic without redeploying
- More agile than waiting for traffic distribution
"
```

---

## Question 4: Secrets Management at Scale

**Question:**

"Your organization has 200 microservices across 3 clusters, each needing database credentials, API keys, and TLS certs. Passwords rotate quarterly. You need to: (a) ensure no secrets stored in Git, (b) allow developers to access secret names in manifests, (c) automate rotation. Describe your approach."

### What Good Answers Address

**Secret Storage vs. Git:**
- What stays in Git (manifests) vs. what doesn't (secrets)
- How do you reference secrets without storing them?

**Rotation Automation:**
- How does secret rotation not cause downtime?
- Coordination between secret store + application reload

**Developer Experience:**
- How do developers deploy without understanding secret complexity?
- How do you prevent developers from checking in secrets?

**Example Strong Answer:**

```
"Multi-layered approach:

Layer 1: Git + Sealed Secrets
- Git stores SEALED (encrypted) secrets; readable by cluster key only
- Problem: Manual seal/unseal tedious; doesn't auto-rotate

Layer 2: External Secrets Operator (ESO)
- Git stores: 'secretRef: db-passwords @ HashiCorp Vault'
- ESO runs in cluster; regularly fetches from Vault
- Vault = authoritative source; updates auto-propagate

Layer 3: HashiCorp Vault
- Vault stores actual secrets (DB passwords, API keys)
- Vault has RBAC: each service only has access to its secrets
- Vault audits all requests (compliance req)

Layer 4: Rotation Automation
- Vault plugin rotates passwords every 90 days
- Rotation flow:
  - Vault generates new password for DB
  - Vault tests new password works (connect to DB, run query)
  - Vault updates ServiceAccount in cluster
  - ESO detects ServiceAccount change
  - ESO fetches updated secret from Vault
  - Pods reload env vars on next startup
  
Problem: Stateful services (active DB connections)
Solution: Rolling restart with proper max-unavailable = 0
- Old pods use old password
- New pods use new password
- Both passwords valid during transition
- After all pods restarted: old password retired

Developer Flow:
1. DevOps sets up secret in Vault
2. DevOps creates ServiceAccount in cluster + ESO mapping
3. Developer references in YAML:
   env:
   - name: DB_PASSWORD
     valueFrom:
       secretKeyRef:
         name: db-credentials  # Populated by ESO
         key: password

4. Developer doesn't see actual password; can't accidentally check it in

Compliance/Auditability:
- Vault maintains audit log: 'who accessed secret when'
- Git maintains manifest history: 'what version deployed when'
- Rotation 'facts' recorded in Vault audit
- Together: Complete compliance picture

Why ESO + Vault vs. alternatives:
- Sealed Secrets alone: no rotation; still manual process
- AWS SecretsManager: ties you to AWS (lock-in risk)
- Vault: agnostic; works on-prem + clouds + GitOps
"
```

---

## Question 5: Observability - Knowing When Something's Wrong

**Question:**

"You deployed v2.0; canary metrics look good for 5 minutes. Then 90% of requests timeout gradually over the next hour. Your observability shows: (a) error rate still 0.5%, (b) response times normal, (c) CPU/memory normal, (d) but timeouts increasing. What's your systematic approach to identifying the root cause?"

### What Good Answers Address

**Metric Limitations:**
- What's misleading about 'error rate' (includes caught errors)?
- How do timeouts not show up in latency histograms?

**Systematic Diagnosis:**
- Where do you look when obvious metrics lie?
- How do you narrow it from "timeout" to "why"?

**Production Reality:**
- This happens in real systems; shows practical wisdom

**Example Strong Answer:**

```
"This is a classic 'Observability is Hard' scenario.

Why metrics look good but system failing:
- Error rate: App catches timeout, logs warning, returns cached response
  (Timeout still happening; not visible as error)
- Response time p50, p99: Affected requests time out; skipped from histogram
  (Histogram calculation can skip timed-out requests depending on implementation)
- CPU/memory: Normal; timeout isn't resource issue

My diagnostic steps:

Step 1: Understand the actual failures
- Check application logs directly (not just metrics)
- Search: 'timeout' or 'connection refused'
- Look for: NEW error types appearing over time

Step 2: Isolate timing of degradation
- When exactly did timeouts start increasing?
- Is it request-volume related? (did traffic spike coincide?)
- Is it time-of-day related? (cache eviction at midnight?)

Step 3: Check for resource exhaustion (non-obvious)
- Memory: Maybe GC running (shows up as pause, not memory %)
  Command: 'jstat -gc <pid>' or application metrics on pause time
- File descriptors: 'lsof | wc -l' or '/proc/sys/fs/file-max'
- Connection pool: 'netstat | grep ESTABLISHED | wc -l'
- My hunch here: Connection pool exhaustion or file descriptor limits

Step 4: Check downstream dependencies
- New version likely hit a NEW code path
- That path makes calls to: external API, database, cache
- Timeout could be: 'calling slow service; default timeout short'
- Check: Tail logs from THOSE services
- Look for: 'Query taking 5s' or 'API response slow'

Diagnosis in this scenario (actually happened to me):
- v2.0 introduced new batch processing feature
- Feature does: 'select * from orders' (no pagination!)
- Database hits query timeout; connection closes
- Connection not returned to pool
- Pool drains
- Subsequent requests: 'pool empty' timeout

Red flag: Error rate stayed low because app did:
try { query } catch { return cached_result }
So timeouts not visible, superficially looked fine

Fix:
- Add pagination to query
- Increase pool size
- More importantly: Add metric for 'UNCAUGHT timeouts' not just errors

Why it went unnoticed for 90 minutes:
- Canary alert used 5-minute window
- Degradation GRADUAL (not sudden spike)
- SLO was '90% requests < 1s'; this hit exactly 10% after 90 min
  But on canary (10% traffic), even 10% failure is small number of requests
  On full prod rollout : would be ~100 failed requests/minute == URGENT

Lesson: Aggregate metrics hide gradual degradation;
need per-service request metrics + trace-based observability
"
```

---

## Question 6: Cost Optimization in GitOps World

**Question:**

"Your GitOps-managed clusters are costing $500K/year. CFO wants 20% reduction. You can't reduce features or reliability. Where do you optimize, and what are the risks?"

### What Good Answers Address

**Tradeoff Awareness:**
- Cost vs. performance vs. reliability; can't reduce all
- What's truly wasteful vs. what's necessary

**Technical Opportunities:**
- Where's money wasted in typical setups?
- How do you optimize without breaking things?

**Organizational/Process Changes:**
- Sometimes the problem is process, not infrastructure

**Example Strong Answer:**

```
"$500K → $400K (20% reduction). Let me think through this systematically:

Cost Breakdown (educated guess, varies):
- Compute (nodes): 60% ($300K)
- Storage: 15% ($75K)
- Data transfer (egress): 10% ($50K)
- Services (databases, load balancers): 15% ($75K)

Optimization Opportunities (in order of impact):

Option A: Resize nodes (Compute 60%)
- Current: t3.2xlarge for stability
- Proposal: Right-size to actual utilization
- Query: Average CPU across nodes?
- If average < 30%, consolidate to t3.xlarge
- Estimated savings: 20-30% ($60-90K)
- Risk: Lower headroom; fragile to traffic spikes
- Mitigation: Increase HPA thresholds carefully; add buffer

Option B: Reserved Instances (Compute 60%)
- Current: On-demand at $X per hour
- Proposal: Buy 1-year reserved instances
- Savings: 20-40% ($60-120K)
- Risk: Locked in; can't downsize easily
- Mitigation: Reserve only baseline; keep surge capacity on-demand

Option C: Consolidate clusters (Compute + Management)
- Current: 3 clusters (US, EU, APAC), each $150-200K
- Proposal: Move to 1 larger cluster + regional node groups
- Savings: Reduce operational overhead, 1 control plane costs
- Estimated: 15% ($75K)
- Risk: Single control plane failure more severe
- Mitigation: HA control plane (3 components); backup procedures

Option D: Optimize storage (Storage 15%)
- Current: Snapshots + backups everywhere
- Proposal: Tiered strategy
  - Hot storage (30 days): Keep all
  - Cold storage (EBS Snapshots): Cheaper tier
  - Archive (1 year+): S3 Glacier
- Estimated savings: 10-20% ($10-15K)
- Risk: Recovery time increases for old backups
- Mitigation: RTO/RPO tradeoff acceptable for old backups

Option E: Data transfer optimization (Data egress 10%)
- Current: Cross-region traffic costs (us → eu for backup)
- Proposal: Evaluate actual backup frequency
  - Is backing up to far region necessary?
  - Can we use cheaper local replication?
- Estimated savings: 5% ($25K)
- Risk: Recovery slower from local failures
- Mitigation: Test RTO; adjust retention policy

Option F: Waste Elimination (Process)
- Audit: What workloads actually running?
- Finding: 15% pods never receive traffic
  (dev environments, forgotten test services, duplicate deployments)
- Proposal: Shut down or consolidate
- Estimated savings: 10-15% ($50-75K)
- Risk: Service actually needed somewhere
- Mitigation: Notify teams 30 days before shutdown

My recommendation (achieves 20% target):
1. Right-size nodes + consolidate: $60K
2. Reserved instances on baseline: $80K
3. Eliminate waste: $50K
   → Total: $190K (20% reduction)

Phased approach:
- Month 1: Waste elimination (quick win, low risk)
- Month 2-3: Reserved instances (need procurement time)
- Month 4-6: Right-sizing (requires monitoring + gradual rollout)

This achieves target WITHOUT cutting reliability or performance
because we're eliminating waste, not cutting muscle.

One more thing (meta-point): This conversation should be had business-side.
$500K spend is justified if it prevents $5M outage. Before cutting,
verify: 'Is our spend proportional to our risk tolerance?'
If spending is rational, cutting 20% might introduce unacceptable risk.
"
```

---

## Question 7: Incident Response - What Went Wrong?

**Question:**

"It's 3 AM. A critical service is down. You're on-call. Walk me through your first 10 minutes. What are your priorities? How do you decide: restart vs. rollback vs. look deeper?"

### What Good Answers Address

**Judgment Under Uncertainty:**
- You have incomplete information; must decide with confidence
- Different choices lead to very different outcomes

**Incident Command Mindset:**
- What you do first determines everything after
- Communication matters as much as technical action

**Real-World Wisdom:**
- What actually works when you're groggy at 3 AM?
- How do you avoid making things worse?

**Example Strong Answer:**

```
"3 AM. Critical service down.

My mental model: Fastest recovery is my job; understanding causation is secondary.

Minute 1: Assess Severity
- Is it really DOWN? (not just slow?)
- How many users impacted?
- Is it my service or dependency's fault?

Commands:
$ kubectl get pods -l app=myservice
(All crashed? Or just unhealthy? Or 0 pods?)

$ kubectl get svc myservice
(Service exists? Endpoint registered? Any pods behind it?)

$ curl -i http://myservice:8080/health
(Hard down? Returning errors?)

$ tail logs for ANY pod
(What does the error log say?)

Minute 2: Gather Context
Simultaneously (while assessing) - message oncall slack:
'myservice down, investigating...'

Check: What changed in last 30 minutes?
$ git log -1 -- deploy/myservice/
(Last deploy? When? By whom?)

$ argocd app get myservice --refresh
(Is ArgoCD reporting sync status? Is cluster drifted?)

Check with oncall database team:
'Did anything change in the last 30 min? (restart, config change, backup?)'

Minute 3: Make Initial Decision
Now I have data. My options:

Option A: Restart (safest first move)
- Hypothesis: Transient error; pod just needs restart
- Action: kubectl rollout restart deployment/myservice
- Time to recovery: 30 seconds
- Risk: Low (might fix immediately; if not, I'm no worse off)
- Downside: Still down for 30 seconds; but fast

Option B: Rollback (if recent deploy)
- Hypothesis: Recent deploy introduced bug
- Action: argocd app sync myservice --revision=previous
- Time to recovery: 1-2 minutes
- Risk: Could have had intent to stay on new version; hard to undo
- Upside: If bug is in code, this definitely fixes it
- Decision: DID deploy happen in last 30 min? YES? Consider rollback

Option C: Look deeper (dangerous at 3 AM)
- Hypothesis: Complex issue; need to debug
- Action: Start investigating, adding latency to recovery
- Time to recovery: 5-15+ minutes
- Risk: User impact extends while I'm debugging
- Downside: Might not even be my code (could be infrastructure)

Decision Matrix:
- If deploy happened < 30 min ago: Rollback (probably bug in new code)
- Else if pods crashing (no restart): Look for new errors in logs
  - Error = database down? Page DB oncall
  - Error = out of memory? Increase pod limits, restart
  - Error = auth code failure? Check if secret rotated unexpectedly
- Else restart pods (generic fix for most transient issues)

Mine: No recent deploy, so…

Minute 4: Action
kubectl rollout restart deployment/myservice

While that happens:

Minute 5: Prepare Communication
Message stakeholders:
'myservice restored via pod restart; investigating root cause'

Minute 6-10: Root Cause Triage
- Check pod logs from the crashed pod:
  $ kubectl logs <pod-name> --previous
  (What was happening before crash?)
- Check events:
  $ kubectl describe pod <crashed-pod>
  (Was it OOMKilled? Evicted? Unhealthy?)
- Check metrics around incident time:
  Prometheus query: 'CPU/memory at 3:00 AM?'
  (Traffic spike? GC pause?)

The goal of minutes 6-10: Figure out what in your brain will help with:
- Root cause post-incident
- Whether to stay on high alert
- Whether restart is sufficient or if something deeper broken

But the key: At 3 AM, your immediate goal is: Get service back.
Root cause analysis is important later, but not worth extended downtime now.

What I WON'T do at 3 AM:
- SSH into nodes and manually debug (slow, error-prone)
- Wait for code review before rolling back (decide fast; review after)
- Deep dive into metrics when restart might fix it (Occam's Razor)

One more thing: After service is up,
set a calendar for 2 PM (daylight):
'postmortem: understand root cause'

I've seen too many incidents where
'we fixed it' at 3 AM, but never understood why.
Sleep-deprived decisions aren't good decisions.
"
```

---

## Question 8: Team Dynamics - Should We Automate This?

**Question:**

"Your team spends 3 hours/week on manual deployment coordination (approvals, checking status, communication). You're considering building an automation tool to eliminate this. Estimate: (a) engineering cost to build it, (b) recurring toil savings, (c) when does ROI happen? (d) what could go wrong?"

### What Good Answers Address

**Business Thinking:**
- Not every problem needs technical solution
- When is automation too expensive for the problem?

**Real-World Estimation:**
- How do you estimate engineering effort?
- What underestimated risks kill projects?

**Organizational Wisdom:**
- Sometimes the answer is "just do it manually"
- Sometimes problem solves itself when org improves

**Example Strong Answer:**

```
"3 hours/week = 156 hours/year = management issue.

But let's do the math:

Engineering Cost to Build:
- Portal UI: 2 weeks
- Backend API: 2 weeks
- Integration (CICD, GitOps, Slack): 1 week
- Testing + deployment: 1 week
- Documentation + training: 1 week
- Incident response / edge cases: 2 weeks (always underestimated)
Total: ~9 weeks
Cost: 1 senior engineer: ~$40K-50K (loaded cost)
Add: 2 junior engineers helping = +$25K

Total build cost: ~$65K-75K

Savings:
- 3 hours/week * 52 weeks * $100/hour (engineer salary) = $15.6K/year
- But also: deployment errors reduced (hard to quantify): maybe $10K/year in avoided incidents
- Total savings: ~$25K/year

Payback: $75K / $25K = 3 years

ROI verdict: NEGATIVE (3-year payback where tool might be stale in 2 years)

But wait, I didn't account for:

Organizational factors that change the calculus:
- What's the actual engineers' bottleneck?
  (Are they waiting for manual coordination? Probably yes)
- Can those 3 hours/week be redirected to features? (Much higher value)
  (If yes: DOES automate. Feature work > toil reduction)
- Is this coordination a scaling problem?
  (Now 3 services, 5 teams; in 2 years, 20 services, 15 teams)
  (Then 3 hours becomes 15 hours; automation breaks even in 1 year)

Risks that kill projects:
- Scope creep: 'While we're building this, add feature X'
- Adoption: Built perfect tool; teams still use old process
- Maintenance: Tool works until it doesn't; now someone owns it forever
- Redundancy: Spend $75K; then adopt industry tool that does same thing

My recommendation:
WAIT 3-6 months. Reasons:

1. Hiring could change this problem:
   Add one person = coordination shifts; problem shrinks

2. Process could improve (no code needed):
   'All deployments Tue/Thu 10 AM' eliminates coordination need
   (Calendar-based > tool-based)

3. Existing tools advancing:
   ArgoCD's new features might handle this better
   Backstage (Spotify tool) might be good fit

4. You learn more in 6 months:
   'This is really needed' vs. 'We've gotten better at coordination'

Check in 6 months:
- If still 3 hours/week: Build the tool (you know it's worth it)
- If reduced to 1 hour/week: Not worth building
- If grown to 10 hours/week: Build aggressively

The meta-principle: Tech debt isn't solved by code;
it's solved by understanding why the debt exists first.
You might find the real issue isn't 'need automation'
but 'need clearer process' or 'need better hiring'.
"
```

---

## Question 9: When DevOps Policies Conflict with Velocity

**Question:**

"Developers want to deploy multiple times per day. Security team requires manual approval for all production changes. DevOps wants immutable infrastructure and GitOps. These seem to conflict. How do you design a system that respects all three while not becoming a bureaucratic nightmare?"

### What Good Answers Address

**Stakeholder Management:**
- Real-world: Everyone has valid constraints
- How do you satisfy constraints without system becoming inoperable?

**Principled Tradeoffs:**
- Where can you compromise?
- Where are you firm (security, reliability)?

**Human Factors:**
- Bottleneck often isn't technical; it's humans
- How do you enable human decision-making at scale?

**Example Strong Answer:**

```
"This is THE hard problem in DevOps culture.

The conflict is real:
- Developers: Want fast feedback (deploy 6x/day)
- Security: 'Every prod change requires approval (takes 1-2 hours)'
- DevOps: 'Git-based GitOps (requires code review + merge)'
Result: Deployed twice a day if lucky; developers frustrated

The trick: Decompose 'production change' into pieces with different approval needs

Tier 1: Configuration Changes (require approval)
- Database migrations
- Security group changes
- Secrets rotation
- These are risky; approval justified
- Approval model: Pull request + formal sign-off (1-2 hours, acceptable)

Tier 2: Deployment of Pre-approved Code (no approval needed)
- You're deploying code that:
  - Already passed security scan in CI/CD
  - Already passed integration tests
  - Was approved + merged into main branch 2 days ago
  - Just different version tag (already vetted)
- Rationale: If code was approved before, re-approving shouldn't be needed
  (Deployment != Change; code changing != deployment changing)
- Approval model:
  - Commit to main = code approved (once)
  - Tag v2.1.0 = deploy request (no second approval)
  - Deploy: Auto-approved if tag exists

Tier 3: Infrastructure Changes (Auto-approved if policy-backed)
- Adding new pod resource: Auto-approved if pod size within policy
- Scaling up/down: Auto-approved if within policy limits
- Rationale: Policies are approved once; subsequent approvals redundant
- Approval model: Policy written once (requires security review)
  Subsequent changes auto-approved if within policy

Implementation:
1. Security team writes policy (Kyverno/OPA):
   'All production containers must: non-root, read-only filesystem, resource limits'
   (This policy approved via formal process)

2. Developer commits code:
   'security-scanning finds: CVE in dependency'
   → Blocks merge; requires security team review
   (This merge is blocked by tech, not process)

3. Developer fixes CVE:
   Code review passes
   Security tests pass
   Merges to main
   (Approval not needed; tests already ran)

4. Developer tags: v2.1.0
   ArgoCD detects tag
   Deploys immediately (0 waiting)
   (No re-approval needed; code already vetted)

5. Deployment triggers:
   Kyverno admission controller checks: 'Does this pod violate policy?'
   If no violations: Admitted
   If violations: Blocked (policy = automatic gating)

Result:
- Security still controls what runs (via policy)
- Developers can deploy 6x/day (once policy-compliant)
- No human bottleneck (policy is automated)

What about actual risks?

Developer: 'I committed a bug; I want to rollback'
System: Rollback is 30 seconds (git revert + sync)
(No approval needed; this is UNDO, not new change)

Developer: 'I want to add new database port'
Kyverno: 'Network policies don't allow this port'
(Blocked automatically; they request exception from security)

Security: 'We need to audit who deployed what'
Git: 'Here's the complete audit trail'
(Every deploy tied to specific commit + developer + approval)

The philosophy:
- Approval makes sense for POLICY changes (once)
- Approval makes sense for CODE changes (once)
- Approval is redundant for DEPLOYMENT (just executing approved code)

Objections I've faced:

Security: 'But what if they merge bad code?'
Response: That's what code review is for; PR approval is the gate
(Merge = code approved; deployment doesn't require re-approval)

Developer: 'Security team is asleep when I code'
Response: Async approval possible time-zone friendly:
- Asia timezone: commits code (EU is offline)
- EU wakes up: reviews code immediately
- Code approved; deploy happens without waiting

Overhead: 'This is complex to set up'
Response: Yes, one-time cost; but amortizes to huge ROI
(Setup: 2 weeks; ongoing: zero bottleneck)
"
```

---

## Question 10: Disaster Recovery - RTO vs. RPO Tradeoffs

**Question:**

"Define the difference between RTO and RPO. Then design DR for a system where RTO must be < 30 minutes and RPO must be < 5 minutes. How much will this cost? What would change if RTO was 4 hours and RPO was 24 hours?"

### What Good Answers Address

**Definitions (Not Just Words):**
- Can show concrete impact of each?
- What's the operational consequence of missing target?

**Cost Scaling:**
- Tight RTO/RPO = expensive
- How do costs scale with these targets?
- Where's the money going?

**Tradeoff Reasoning:**
- Why would org accept 4-hour RTO but insist on 5-min RPO?
- Are some combinations impossible?

**Example Strong Answer:**

```
"RTO vs. RPO: Different dimensions of recovery, often confused.

RTO (Recovery Time Objective): Time from disaster to service running
├─ Example: Cluster fails at 10:00 AM
├─ RTO target: 30 minutes
├─ Means: Service running again by 10:30 AM
└─ Who cares: Business side (user impact = RTO)

RPO (Recovery Point Objective): How much data can you lose
├─ Example: Disaster at 10:00 AM
├─ RPO target: 5 minutes of data
├─ Means: Latest data backup is from 9:55 AM
├─ Data from 9:55-10:00: Lost forever
└─ Who cares: Everyone (data = money in most businesses)

Different scenarios:

Scenario A (RTO < 30 min, RPO < 5 min):
- This is CHALLENGING
- Requires: Multi-region active-active setup
- Infrastructure cost: $500K+ annual

Why expensive:
- RTO < 30 min: Can't build new infrastructure from zero
  (Building cluster takes 20-30 min; too slow)
  Requirement: MUST have backup cluster already running
  (Cost: 2x infrastructure = 2x expense)

- RPO < 5 min: Can't use async replication
  (Async means data accepted first, replicated later = gap)
  Requirement: Synchronous replication (wait for data ack)
  (Cost: network latency + reliability overhead)

Design:
- Cluster A (Primary): us-east-1 (running 100% traffic)
- Cluster B (Secondary): eu-central-1 (running, but 0% traffic)
- Database: RDS with synchronous read replica
  (Every write confirmed in both regions before OK)
- Caches: Redis with geo-replication
  (Every cache update synced immediately)

- DNS: Fast failover (Route 53 health checks every 10 sec)
  If primary unavailable: Switch traffic to secondary (10-30 sec)
  
- Application state: Stored externally (not in pod memory)
  (If pod crashes, new pod recovers state from DB)

Recovery flow:
├─ 10:00: Disaster (primary region fails)
├─ 10:00-10:10: Health check fails; DNS updated
├─ 10:10: Traffic flowing to secondary region
├─ 10:10-10:20: Application stabilizes on secondary
├─ 10:20: Service recovered (10 minute actual RTO)
├─ RPO: ~0 (synchronous replication means max 1-2 sec data loss)
└─ MEETS both targets

Cost estimate:
- Double infrastructure (primary + secondary): $400K/year
- Premium for synchronous replication: $50K/year
- Fast DNS failover service: $10K/year
- Operations (monitoring, DR drills): $40K/year
└─ Total: $500K/year

---

Scenario B (RTO < 4 hours, RPO < 24 hours):
- This is AFFORDABLE
- Much looser targets; different architecture

Why cheaper:
- RTO < 4 hours: Can afford to REBUILD from scratch
  (Terraform apply: 30 min + app boot + data restore: 2-3 hours)
  (No need for pre-running backup infrastructure)

- RPO < 24 hours: Can use overnight backups
  (Daily snapshot at 2 AM; if disaster at 10 AM, restore from 2 AM)
  (Data loss: 8 hours acceptable)

Design:
- Cluster A (Primary): us-east-1 (running)
  (Backup cluster DOESN'T need to run; just defined in IaC)
- Database: Daily snapshot to S3 (cheap storage)
- Infrastructure code: Stored in Git (AWS + K8s manifests)
- Automated restore tests: Monthly (test that IaC still works)

Recovery flow:
├─ 10:00: Cluster fails
├─ 10:30: On-call paged (don't rush)
├─ 11:00: Damage assessment (really a disaster?)
├─ 12:00: Decision made: "Start recovery"
├─ 12:30: New cluster provisioned via Terraform (fully automated)
├─ 1:30: Database restored from yesterday's 2AM snapshot
├─ 2:00: All apps synced from Git; running
├─ 2:30: DNS updated; traffic flowing
└─ 2:30: Service recovered (4.5 hours; MEETS < 4hr? NO; close)

Closer look:
Actually might be 5-6 hours including:
- DNS propagation lag
- Database recovery verification
- Application warmup (cache rebuilds)

If 4 hours is HARD requirement (not goal):
Add: Secondary cluster (warm, but not running)
Cost increase: +$200K (instead of $500K target, maybe $700K)

---

Cost scaling relationship:
RTO / RPO targets     | Architecture                  | Annual Cost
30 min / 5 min        | Multi-region active-active    | $500K-700K
2 hours / 1 hour      | Warm standby cluster          | $300K-400K
4 hours / 24 hours    | Cold standby (IaC rebuild)    | $50K-100K
(baseline prod cost only added costs for disaster readiness shown)

---

Key insight I always share:
'RTO and RPO are business decisions, not tech decisions.
Engineer should provide options:
  - 'This costs $X and gives you RTO/RPO targets'
Business partners decide: 'Is downtime acceptable?'

I've seen: org pays $500K extra for 30 min RTO
(Avoided one outage costing $2M; justified)

And: org refuses $50K for DR, despite $500K baseline cost
(Taking 24-hour RTO risk; accepted consciously)

Both decisions are defensible IF made consciously.
"
```

---

## Question 11: Technical Debt in GitOps

**Question:**

"After 2 years of GitOps, your manifests git repo has 50K lines of YAML. Developers complain: (a) hard to add services, (b) copy-paste errors spread, (c) rollbacks are risky. What architectural changes would you make?"

### What Good Answers Address

**Recognizing Debt:**
- Pattern recognition; when does a pattern become a problem?

**Refactoring Without Disruption:**
- Can't just rewrite; system must keep running

**Templating/Modularity:**
- When to use Helm vs. Kustomize vs. raw YAML?
- What's the sweet spot?

**Example Strong Answer:**

```
"50K lines of YAML is NOT scale; it's a SMELL.

The smell: 'We're copy-pasting too much'

Two-pronged fix:

Prong 1: Audit copy-paste
Find the PATTERNS (there are always patterns):
- 'Every microservice has: Deployment, Service, ConfigMap'
- 'Every prod service needs: 3 replicas, network policy, pod autoscaler'
- 'Every EU service needs: different affinity rules'

These patterns should be implemented ONCE, reused widely

Prong 2: Refactor to Helm templates
From:
```
/manifests/services/
├── api-service/
│   ├── deployment.yaml (200 lines)
│   ├── service.yaml (50 lines)
│   ├── configmap.yaml (100 lines)
│   ├── hpa.yaml (50 lines)
│   └── networkpolicy.yaml (40 lines)
│   Total: 440 lines per service
├── web-service/ (same pattern)
├── worker/ (same pattern)
...
└── ~100 services * 440 lines = 44K lines
```

To:
```
/helm/microservice-template/
├── Chart.yaml
├── values.yaml (schema)
└── templates/
    ├── deployment.yaml (generic, templated)
    ├── service.yaml (generic)
    ├── configmap.yaml (generic)
    ├── hpa.yaml (generic)
    └── networkpolicy.yaml (generic)
    Total: 600 lines for EVERY service

/deployments/
├── api-service/
│   ├── values.yaml (50 lines specific to api)
│   ├── Chart.yaml (reference to template)
├── web-service/
│   ├── values.yaml (50 lines specific to web)
├── worker/
   ├──, values.yaml (50 lines; specific to worker)
...
└── ~100 services * 50 lines = 5K lines
```

Result: 44K lines → 5.6K lines (87% reduction!)

Now: Adding new service = add 50 lines (values.yaml)
Old: Adding new service = copy 440 lines + find-replace mistakes

Additional architectural changes:

Change 1: Kustomize layers (vs. Helm)
If your services don't need complex templating:

```
base/
└── generic-microservice/ (350 lines)
   ├── deployment.yaml
   ├── service.yaml
   └── kustomization.yaml

overlays/
├── development/
│  └── kustomization.yaml (10 lines: 'set replicas 1, set CPU low')
├── staging/
│  └── kustomization.yaml (10 lines: 'set replicas 2, image-tag staging')
└── production/
   └── kustomization.yaml (10 lines: 'set replicas 5, add PDB')
```

Less powerful than Helm, but simpler; often sufficient

Change 2: Add admission controllers (remove defensive manifests)
Current problem: Copy-paste errors in network policies, pod security

Solution: Kyverno policies enforce standardized defaults
- Network policy: Automated for all pods (don't copy-paste)
- Security context: Enforced (not repeated in every manifest)
- Resource limits: Injected if missing (no copy-paste)

Result: Manifests simpler, more consistent

Change 3: Generator tools
Use tools to generate initial manifests (vs. copying):
- Tilt (local dev): generates manifests from code
- Kusion (IaC): generates manifests from schema
- Pulumi (procedural): write code, generates manifests

Example (Pulumi):
```python
for service in ['api', 'web', 'worker']:
    Deployment(
        name=service,
        image=f'myregistry/{service}:v2.0',
        replicas=5,
        resources=ResourceRequirements(cpu='500m', memory='512Mi')
    )
# Generates deployment manifests programmatically
```

Implementation plan (without disruption):
Month 1: Audit and document patterns
- Identify: What's repeated?
- Create: Standard template

Month 2: Migrate half of services to Helm
- Convert 50 services to use template
- Keep 50 services on old YAML (temporary)
- Parallel running; validate

Month 3: Migrate remaining services
- Convert 50 more to template
- Retire old copy-pasted YAMLs

Month 4: Add Kyverno (automatic enforcement)
- Removes defensive YAML (no longer needed)
- Further simplifies manifests

Result:
- 50K lines → 5.6K lines
- Add new service: 50 min + 50 lines
- Rollback risk: Lower (templates tested once; reused everywhere)
- Maintenance: Much easier

The wisdom:
Tech debt isn't bad code; it's repeated code.
Fix it by identifying patterns and extracting them.
"
```

---

# Conclusion

This study guide is designed to take you from understanding GitOps concepts to architecting and operating complex, multi-cluster, production-grade systems with high reliability, security, and developer velocity.

**Key Themes:**
- Git as source of truth enables recovery, auditability, and repeatability
- Progressive delivery reduces blast radius; metrics-driven decisions prevent disasters
- Security policies automated; not manual gates; scalable with organization
- Observability threaded through pipeline; know when something's wrong
- Multi-cluster, multi-region designs built from day one
- DevOps culture balances: speed vs. stability, automation vs. human judgment

**Recommended Reading:**
- "The Phoenix Project" (understand DevOps culture)
- "Site Reliability Engineering" (Google's take on production operations)
- ArgoCD/Flux CD documentation (hands-on with tools mentioned)
- "Observability Engineering" (understand metrics vs. dashboards vs. traces)

**Practice:** The scenarios provided are representative of real production issues. Review each as if you're on-call at 3 AM; develop your own diagnostic methodology.

---

**Study Guide Version:** 2.0 (March 2026)
**Last Updated:** 2026-03-21
**Status:** Complete and Ready for Production Use ✅

