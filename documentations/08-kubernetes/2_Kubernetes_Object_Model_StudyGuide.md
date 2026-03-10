# Kubernetes Object Model - Senior DevOps Study Guide

**Level:** Senior DevOps Engineer (5-10+ years experience)  
**Last Updated:** March 2026  
**Focus Areas:** Production-grade understanding of K8s declarative patterns

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)
3. [Declarative Configuration and Desired State Management](#declarative-configuration-and-desired-state-management)
4. [YAML Structure and Best Practices](#yaml-structure-and-best-practices)
5. [Labels and Selectors](#labels-and-selectors)
6. [Annotations and Metadata](#annotations-and-metadata)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

The **Kubernetes Object Model** is the foundational abstraction layer that defines how you declare, manage, and operate workloads, infrastructure, and policies within Kubernetes clusters. Unlike imperative approaches where you command Kubernetes to perform specific actions, the object model enables declarative infrastructure—you define the desired state, and Kubernetes continuously reconciles the actual state toward that goal.

Every entity in Kubernetes—Pods, Services, Deployments, ConfigMaps, PersistentVolumes—is represented as a **Kubernetes Object**. These objects are:
- **Persistent:** Stored in etcd and survive API server restarts
- **Versioned:** Support multiple API versions for backward compatibility
- **Queryable:** Accessible via kubectl and the Kubernetes API
- **Reconcilable:** Subject to active control loops that drive convergence

### Why It Matters in Modern DevOps Platforms

Understanding the Kubernetes Object Model is critical for several reasons:

1. **Infrastructure as Code (IaC) Foundation:**
   - Enables version-controlled, auditable infrastructure declarations
   - Forms the basis for GitOps workflows (Flux, ArgoCD)
   - Supports multi-environment promotion pipelines

2. **Operational Reliability:**
   - Declarative approach reduces configuration drift
   - Enables predictable scaling, rolling updates, and rollbacks
   - Supports complex orchestration without manual intervention

3. **Security & Compliance:**
   - RBAC policies are themselves Kubernetes Objects
   - Policy engines (OPA/Gatekeeper) operate on object definitions
   - Audit trails track object mutations for compliance

4. **Multi-tenancy & Resource Governance:**
   - Namespace isolation and quota management require understanding object hierarchies
   - Label-based cost allocation and resource scheduling
   - Cross-cluster federation relies on consistent object models

5. **Observability & Troubleshooting:**
   - Understanding object lifecycle, conditions, and status fields enables effective monitoring
   - Events and logs are correlated to specific objects
   - Controllers expose metrics about object reconciliation

### Real-World Production Use Cases

#### Case 1: Blue/Green Deployments with Label Selectors
A financial services organization runs dual Deployments (blue and green) with identical configurations but different labels. They use DNS CNAME records and Service selectors to switch traffic between versions. When blue is stale, they update the Service selector label to point to green, achieving instant traffic cutover without downtime.

**Object Interactions:**
- 2× Deployments (blue, green) with distinct labels
- 1× Service with dynamic selector
- 1× ConfigMap with shared configuration

#### Case 2: Multi-Cluster Resource Quotas with Annotations
A SaaS platform manages 15 regional clusters. Each Namespace carries annotations specifying cost center, SLA tier, and auto-scaling constraints. Custom webhooks and controllers read these annotations to:
- Enforce pod resource requests/limits
- Route workloads to appropriate clusters
- Generate cost reports from annotation metadata

#### Case 3: Progressive Delivery with Custom Objects
A telecommunications provider extends the Kubernetes API with custom objects (`CanaryDeployment`). The control plane watches these custom objects and manages underlying Deployments, Services, and VirtualServices (from Istio). This enables declarative canary specifications independent of underlying infrastructure details.

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   GitOps Repository                          │
│  (Kubernetes Object YAML definitions version-controlled)     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         Kubernetes Control Plane (kube-apiserver)            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Object Store (etcd)                                 │   │
│  │  ├─ Deployments, StatefulSets, DaemonSets           │   │
│  │  ├─ Services, Ingresses, NetworkPolicies            │   │
│  │  ├─ ConfigMaps, Secrets                              │   │
│  │  ├─ PersistentVolumes, PersistentVolumeClaims       │   │
│  │  └─ Custom Resources (CRDs)                          │   │
│  └──────────────────────────────────────────────────────┘   │
│                       │                                      │
│  ┌──────────────────┴──────────────────┐                   │
│  ▼                                     ▼                     │
│  Controllers & Operators          Admission Controllers      │
│  (Reconciliation Loops)           (Validation & Mutation)    │
│  - Deployment Controller          - ValidatingWebhooks      │
│  - Service Controller             - MutatingWebhooks        │
│  - StatefulSet Controller         - Custom Validators       │
│  - Custom Controllers             - Policy Engines          │
└─────────────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│         Kubernetes Worker Nodes (kubelet)                    │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Pod Runtime (Containers)                             │   │
│  │  ├─ Business logic containers                        │   │
│  │  ├─ Sidecar containers                               │   │
│  │  └─ Init containers                                  │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

In modern architectures, Kubernetes Objects serve as the **single source of truth** for desired state across:
- **Development pipelines:** CI/CD systems read/modify objects
- **Observability platforms:** Prometheus, Grafana correlate metrics to objects
- **Service meshes:** Istio/Linkerd extend with custom objects
- **Cost management tools:** Parse object annotations for chargeback
- **Disaster recovery:** Backup solutions work at the object level

---

## Foundational Concepts

### Key Terminology

#### Object (Kubernetes Object)
A persistent record in the cluster defining an intended state. Every object has:
- **APIVersion:** API group and version (e.g., `apps/v1`)
- **Kind:** Object type (e.g., `Deployment`, `Pod`, `ConfigMap`)
- **Metadata:** Unique identification and system-assigned values
- **Spec:** Desired configuration
- **Status:** Observed current state (read-only for end-users)

#### Kind
A classification of Kubernetes objects. Standard kinds include:
- **Core:** Pod, Service, Namespace, ConfigMap, Secret
- **Workload:** Deployment, StatefulSet, DaemonSet, Job, CronJob
- **Policy:** NetworkPolicy, PodSecurityPolicy, ResourceQuota
- **Custom:** User-defined kinds via CustomResourceDefinitions (CRDs)

#### API Group
A logical collection of API versions and kinds. Examples:
- `core` (no prefix, legacy)
- `apps` (workload objects)
- `batch` (Job, CronJob)
- `networking.k8s.io` (Ingress, NetworkPolicy)
- `custom.mycompany.io` (custom resources)

#### Manifest
A YAML or JSON document declaring an object. Often called "resource definition" in industry parlance. A single manifest file may contain one or more objects separated by `---`.

#### Reconciliation (Control Loop)
The process where a controller observes the current state of objects and takes actions to converge toward the desired state defined in the spec. Example: Deployment controller ensures the correct number of Pod replicas are running.

#### Desired State vs. Actual State
- **Spec (Desired):** What you declare in the object manifest
- **Status (Actual):** What the controller observes in the cluster
- **Reconciliation:** The continuous effort to minimize the gap

#### Owner References & Garbage Collection
Objects can have owner references, creating parent-child relationships. When a parent is deleted, Kubernetes automatically cleans up owned children (configured via `ownerReferences` and `cascadePolicy`).

---

### Architecture Fundamentals

#### The Declarative Model

Unlike traditional infrastructure tools (SSH-based, imperative), Kubernetes uses **declarative infrastructure:**

```
┌─────────────────────────────────────────────────────────────────┐
│              Imperative (Traditional)                             │
├─────────────────────────────────────────────────────────────────┤
│  1. Connect to host                                              │
│  2. Run: apt-get install nginx                                   │
│  3. Run: systemctl start nginx                                   │
│  4. Edit: /etc/nginx/nginx.conf                                  │
│  5. Run: systemctl reload nginx                                  │
│  # Problem: If some steps fail, no rollback; state is implicit   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│              Declarative (Kubernetes)                             │
├─────────────────────────────────────────────────────────────────┤
│  apiVersion: apps/v1                                             │
│  kind: Deployment                                                │
│  metadata:                                                       │
│    name: nginx                                                   │
│  spec:                                                           │
│    replicas: 3                                                   │
│    template:                                                     │
│      spec:                                                       │
│        containers:                                               │
│        - name: nginx                                             │
│          image: nginx:1.25                                       │
│  # Problem: None. State is explicit, idempotent, and auditable   │
└─────────────────────────────────────────────────────────────────┘
```

**Benefits of Declarative Model:**
- **Idempotency:** Applying the same manifest multiple times produces the same state
- **Auditability:** Version control tracks all changes
- **Rollback:** Previous versions can be reapplied instantly
- **Automation:** Controllers implement desired→actual convergence
- **Predictability:** No hidden state or manual side effects

#### The Watch-and-Reconcile Pattern

Every Kubernetes controller follows this loop:

```
┌───────────────────────────────────────────────────────────────────┐
│  1. Controller starts and registers with API server               │
│     Watch: "Notify me of all Deployment objects"                  │
├───────────────────────────────────────────────────────────────────┤
│  2. Event received: "New Deployment created"                       │
│     ├─ Extract spec: replicas=3, image=nginx:1.25                 │
│     ├─ Query current state: "How many Pod replicas exist?"         │
│     ├─ If actual < desired: Create new Pods                       │
│     └─ If actual > desired: Delete excess Pods                    │
├───────────────────────────────────────────────────────────────────┤
│  3. Update object status field with current Pod count             │
│     status.replicas: 3                                            │
│     status.updatedReplicas: 3                                     │
│     status.availableReplicas: 3                                   │
├───────────────────────────────────────────────────────────────────┤
│  4. Continue watching for:                                        │
│     - Spec changes (e.g., replicas updated to 5)                  │
│     - Pod failures (trigger recreation)                           │
│     - Node failures (trigger rescheduling)                        │
└───────────────────────────────────────────────────────────────────┘
```

This pattern is implemented by every controller in Kubernetes and enables **self-healing** without manual intervention.

#### Hierarchical Object Relationships

Objects form implicit hierarchies through ownership:

```
Deployment (user-created)
├─ ReplicaSet (created by Deployment controller)
│  ├─ Pod (created by ReplicaSet controller)
│  │  └─ Container (created by kubelet)
│  │     ├─ Volume mount
│  │     └─ Network interface
```

When a parent object is deleted with `cascadePolicy: background`, children are automatically garbage-collected.

#### API Server as Single Source of Truth

The Kubernetes API server (backed by etcd) is the central hub:
- All object mutations go through etcd
- All reads are served from etcd (with optional caching)
- Webhooks intercept mutations
- Controllers watch object changes
- Clients query object state

This design ensures **strong consistency** and **auditability** across the cluster.

---

### Important DevOps Principles

#### 1. Separation of Concerns

Kubernetes Objects enforce clear separation between:

| Layer | Object | Responsibility |
|-------|--------|-----------------|
| **Compute** | Deployment, Pod | "What container image, with what resources?" |
| **Networking** | Service, Ingress | "How is this workload exposed?" |
| **Storage** | PVC, PV, StorageClass | "Where is data persisted?" |
| **Configuration** | ConfigMap, Secret | "What environment variables and credentials?" |
| **Policy** | RBAC, NetworkPolicy, ResourceQuota | "Who can do what to which resources?" |

This separation allows teams to operate independently:
- Developers define Pods and Deployments
- Platform engineers own ServiceAccounts and RBAC
- Storage teams manage StorageClasses and PersistentVolumes
- Network teams manage NetworkPolicies and Ingresses

#### 2. Immutability Wherever Possible

Key principle: Once an object is created, certain fields should not change:
- Pod spec is immutable (prevent runtime mutation surprises)
- Image digests (not tags) should be immutable in production
- ConfigMap data should be versioned (create new ConfigMap rather than mutate)

Benefits:
- Prevents security footguns (e.g., container image swapped at runtime)
- Forces explicit updates through object recreation
- Simplifies debugging (known state at creation time)

#### 3. Workload Identity Over Credentials

Traditional approach: Inject credentials into Pods  
Kubernetes approach: Uses ServiceAccounts + RBAC

**Why this matters:**
- ServiceAccounts are Kubernetes Objects, auditable and rotatable
- RBAC policies are Kubernetes Objects, subject to kubectl and GitOps
- Credentials never appear in manifests
- Integration with cloud provider IAM (AWS IRSA, Azure Workload Identity)

#### 4. Resource Requests and Limits as Policy

Every production workload should declare resource requests and limits:

```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: "100m"          # Minimum guaranteed CPU
        memory: "256Mi"      # Minimum guaranteed RAM
      limits:
        cpu: "500m"          # Maximum allowed CPU (throttled if exceeded)
        memory: "512Mi"      # Maximum allowed RAM (OOMKilled if exceeded)
```

Why this is non-negotiable for senior engineers:
- **Scheduler:** Uses requests to bin-pack Pods onto nodes
- **QoS Classes:** Determines eviction order under resource pressure
- **Multi-tenancy:** Prevents noisy neighbors from consuming all resources
- **Cost:** Enables accurate chargeback and capacity planning

#### 5. Observability Through Object State

Don't just monitor metrics; monitor object health:

```bash
kubectl get deployment -o wide
kubectl describe pod <name>
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

These commands reveal:
- Pod phase (`Pending`, `Running`, `CrashLoopBackOff`)
- Container readiness/liveness probe status
- Events explaining why an object is in a given state
- Last transition times (performance diagnosis)

---

### Best Practices

#### 1. Always Specify API Versions Explicitly

❌ **Bad:**
```yaml
kind: Deployment
metadata:
  name: app
```

✅ **Good:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
```

**Why:** Different Kubernetes versions support different API versions. Explicit versions ensure manifests work across cluster versions and upgrades.

#### 2. Use Namespaces for Logical Isolation

❌ **Bad:** All objects in `default` namespace
```bash
kubectl apply -f deployment.yaml
# Creates in 'default' namespace
```

✅ **Good:** Logical namespaces per team/environment
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: production
  name: app
```

**Benefits:**
- Resource quotas per namespace
- RBAC policies scoped to namespaces
- Network policies isolate inter-namespace traffic
- Easy environment separation (multiple manifests, one cluster)

#### 3. Label Every Object Thoughtfully

Labels are queryable metadata enabling filtering and orchestration:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
    version: v2.1.0
    team: backend
    cost-center: engineering
    environment: production
```

Use standard label conventions:
- `app`: Application name
- `version`: Release version
- `environment`: Environment (prod/staging/dev)
- `component`: Service component
- `team`: Owning team
- `cost-center`: For chargeback

#### 4. Document with Annotations

Annotations are non-queryable but valuable for tooling and documentation:

```yaml
metadata:
  annotations:
    description: "API server handling payment transactions"
    runbook: "https://wiki.company.com/runbooks/api-server"
    slack-channel: "#backend-oncall"
    monitoring-slo: "99.9%"
    backup-policy: "daily-incremental"
```

Don't overuse annotations for queryable data—use labels instead.

#### 5. Separate Configuration from Code

Configuration (that varies per environment) should not be baked into container images:

❌ **Bad:**
- Hardcode database URL in application
- Environment-specific config in source code

✅ **Good:**
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  database-url: "postgres://prod-db.internal:5432"
  log-level: "INFO"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:v2.1.0
        envFrom:
        - configMapRef:
            name: app-config
```

#### 6. Use Owner References for Logical Cleanup

When creating objects programmatically, set owner references to ensure cleanup:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: job-worker-abc123
  ownerReferences:
  - apiVersion: batch/v1
    kind: Job
    name: batch-processor
    uid: 12345-67890
```

When the Job is deleted, the Pod is automatically garbage-collected.

#### 7. Validate Manifests Before Applying

Use tools to catch errors early:

```bash
# Syntax validation
kubectl apply --dry-run=client -f deployment.yaml

# Server-side validation
kubectl apply --dry-run=server -f deployment.yaml

# Full validation with admission webhooks
kubectl apply -f deployment.yaml --validate=true
```

For GitOps, validate in CI/CD pipelines before committing.

---

### Common Misunderstandings

#### Misunderstanding 1: "kubectl apply" Directly Modifies the Cluster

**False Assumption:**
```
kubectl apply ← directly mutates cluster state
```

**Reality:**
```
kubectl apply 
├─ Sends manifest to API server
├─ API server stores in etcd (spec field)
├─ Controllers watch for changes
└─ Controllers drive cluster changes (by creating/deleting/updating objects)
```

**Implication:** Manual `kubectl edit` or `kubectl patch` bypassing manifests is anti-pattern. Always use manifests as source of truth.

#### Misunderstanding 2: "Status Fields Can Be Edited by Users"

**False Assumption:**
```yaml
status:
  observedGeneration: 10
  replicas: 5
```

**Reality:** Status fields are **read-only for users**. They are written exclusively by controllers:
- `status.replicas`: Written by Deployment controller
- `status.conditions`: Written by various controllers
- `status.phase`: Written by kubelet

Attempting to edit status fields fails with an API error. Only controllers and system components can write status.

#### Misunderstanding 3: "Deleting a Pod Deletes Associated Volumes"

**False Assumption:** Pod deletion cascades to PersistentVolumeClaims and PersistentVolumes.

**Reality:**
```
Pod deleted
├─ If StatefulSet: PVC is retained (by design, for data safety)
├─ If Deployment: PVC is deleted (Pod is ephemeral)
└─ PV behavior: Depends on storageClass reclaim policy
   ├─ Retain: PV remains (manual cleanup needed)
   ├─ Delete: PV auto-deleted
   └─ Recycle: PV data wiped (deprecated)
```

**For senior engineers:** Always explicitly specify `persistentVolumeReclaimPolicy` to avoid accidental data loss.

#### Misunderstanding 4: "I Can Use Any Image Tag in Production"

**False Assumption:** Image tags like `latest` or `v2.1` are sufficient for reproducible deployments.

**Reality:**
- Image tag can be re-pushed (same tag, different image)
- Kubernetes cache pulls new image if tag points to new SHA
- Rolling deployments may have mixed image versions mid-rollout
- Pod spec shows tag, not the actual image SHA

**Best practice:** Pin to image digests:
```yaml
image: myapp@sha256:abc123def456  # Immutable image identifier
```

#### Misunderstanding 5: "Labels Are for Organization Only"

**False Assumption:** Labels are just for UI organization.

**Reality:** Labels drive critical functionality:
- **Service selectors:** Determine which Pods receive traffic
- **NetworkPolicy:** Uses labels to define allowed traffic
- **ResourceQuota:** Limits applied via label selectors
- **Pod affinity:** Pods schedule based on labels of other Pods
- **Cost allocation:** Cloud providers use labels for chargeback

Losing or changing labels can break networking and scheduling.

#### Misunderstanding 6: "Namespace Isolation is Security"

**False Assumption:** Namespaces provide strong isolation.

**Reality:** Namespaces are **logical separation, not security boundary**:
- By default, Pods in different namespaces can communicate
- ResourceQuota prevents resource exhaustion (not malicious acts)
- RBAC controls who can access objects (not what Pods can do)
- NetworkPolicy (separate feature) actually blocks inter-Pod traffic

Proper security requires: RBAC + NetworkPolicy + Pod Security Standards + Service Mesh.

---

## Declarative Configuration and Desired State Management

### Textual Deep Dive

#### Internal Working Mechanism

The declarative model is implemented through a sophisticated control-plane architecture that continuously enforces desired state:

```
User Intent (Manifest) ───► API Server ───► etcd (Persistent Store)
                                  │
                                  ▼
                        Admission Controllers
                        ├─ ValidatingWebhooks
                        ├─ MutatingWebhooks
                        └─ Built-in policies
                                  │
                                  ▼
                        Object stored in etcd
                                  │
                                  ▼
                        API Server emits event
                                  │
                    ┌───────────────────────────────┐
                    ▼                               ▼
            Controller 1 watches              Controller 2 watches
                 (e.g., Deployment)               (e.g., ReplicaSet)
                    │                               │
                    ▼                               ▼
            Read current state             Compare Spec vs Status
            Compare Spec vs Status              │
                    │                           ▼
                    └──────────────────► Take Action (create/update/delete)
                                              │
                                              ▼
                                        Update object status
                                              │
                                              ▼
                                        Emit event for next controller
```

The key insight: **Controllers do not directly execute commands; they emit events and create new objects that trigger downstream controllers.**

Example flow for a Deployment:

1. User applies: `Deployment: nginx with replicas=3`
2. API Server stores Deployment in etcd
3. Deployment Controller watches for new Deployments
4. Deployment Controller creates: `ReplicaSet: nginx-abc123` (with replicas=3)
5. ReplicaSet Controller watches for new ReplicaSets
6. ReplicaSet Controller creates: 3× `Pod: nginx-abc123-xxxxx`
7. Kubelet (node agent) watches for Pods scheduled to its node
8. Kubelet creates: Container runtime (via CRI) and mounts volumes
9. Container runtime pulls image and starts container

**Critical Design Principle:** No direct imperative commands (`container.run()` or `vm.start()`). Everything is object creation, and downstream controllers decide what to do.

#### Architecture Role

Declarative configuration serves as the **glue binding multiple distributed systems:**

| Role | Description |
|------|-------------|
| **Single Source of Truth** | All infrastructure state lives in etcd, queryable and auditable |
| **State Reconciliation Engine** | Controllers continuously drive actual → desired state |
| **Self-Healing Foundation** | Failures trigger automatic recovery loops |
| **Change Management** | Version control tracks all mutations; rollback is object re-apply |
| **Multi-Controller Orchestration** | Complex behaviors emerge from simple, composable controllers |
| **Operator Pattern Enabler** | Custom controllers extend Kubernetes with domain-specific logic |

Without declarative configuration, Kubernetes would require:
- Manual imperative commands after every failure
- Stateful tracking of what should be running
- Complex rollback procedures
- No self-healing capability

#### Production Usage Patterns

**Pattern 1: Progressive Rollouts with Reconciliation**

Scenario: Deploy version 2 of an API while version 1 handles traffic.

```yaml
# Step 1: Create new Deployment for v2
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v2
spec:
  replicas: 0  # Start with 0 replicas
  template:
    spec:
      containers:
      - name: api
        image: myapi:v2.0.0

# Step 2: Watch status, gradually increase replicas
# kubectl patch deployment api-v2 --type merge -p '{"spec":{"replicas":1}}'
# kubectl watch deployment api-v2
# Once healthy, continue...
# kubectl patch deployment api-v2 --type merge -p '{"spec":{"replicas":3}}'

# Step 3: Old Deployment still running
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-v1  # Old deployment
spec:
  replicas: 3
```

The declarative model enables intelligent orchestration tools (Flux, ArgoCD) to:
- Monitor both Deployments
- Adjust replica counts based on metrics
- Rollback if v2 has errors
- All through manifest mutations, no imperative commands

**Pattern 2: GitOps-Driven State**

```
Git Repository (Source of Truth)
├─ main branch: Production manifests
├─ staging branch: Staging manifests
└─ feature branches: Experimental configurations
        │
        ▼
   CI/CD Pipeline
   ├─ Validate YAML syntax
   ├─ Lint for best practices
   ├─ Test admission webhooks
   └─ Merge to main
        │
        ▼
   GitOps Agent (ArgoCD/Flux)
   ├─ Polls Git every 3 minutes (or webhook-triggered)
   ├─ Detects manifest changes
   ├─ Applies new manifests to cluster
   └─ Syncs cluster state to Git state
        │
        ▼
   Kubernetes API Server
   ├─ Receives manifest from GitOps agent
   ├─ Stores in etcd
   └─ Emits events to controllers
        │
        ▼
   Controllers take action
   ├─ Deployment Controller: Create new ReplicaSets
   ├─ Service Controller: Update load balancer
   └─ Ingress Controller: Update reverse proxy
```

**Key benefit:** All changes flow through Git (audit trail, PR reviews) and are declaratively applied to cluster.

**Pattern 3: Multi-Environment State Management**

```
Production Cluster          Staging Cluster
┌──────────────────┐       ┌──────────────────┐
│ Namespace: prod  │       │ Namespace: staging│
│                  │       │                  │
│ Deployment:      │       │ Deployment:      │
│ api-v2.1.0       │       │ api-v2.0.5       │ (testing v2)
│ replicas: 10     │       │ replicas: 2      │
│                  │       │                  │
│ Service:         │       │ Service:         │
│ lb-prod          │       │ lb-staging       │
│ (endpoint: v2.1) │       │ (endpoint: v2.0)│
└──────────────────┘       └──────────────────┘
        ▲                           ▲
        └──────────┬────────────────┘
                   │
        Single Git Repository
        ├─ manifests/prod/ ────► applies to prod cluster
        ├─ manifests/staging/ ──► applies to staging cluster
        └─ manifests/common/ ───► shared config (reused in both)
```

**Benefit:** Same infrastructure code, different configurations per environment. Promotion is as simple as updating version in prod manifest and committing to Git.

#### DevOps Best Practices

**1. Idempotency: Apply Safely, Repeatedly**

Every manifest application must be safe to repeat:

```yaml
# ✅ Idempotent: Safe to apply multiple times
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  log_level: INFO
  database_url: postgres://db:5432

# Applying this 10 times = same result (no duplicates, no conflicts)
```

Compare with imperative:
```bash
# ❌ Non-idempotent: Applying twice creates 2 services
kubectl expose deployment api --port=8080 --type=LoadBalancer
# First apply: Creates Service
# Second apply: ERROR "Service already exists" OR creates duplicate
```

**2. Use Server-Side Apply for Conflicts**

When multiple tools manage the same object:

```bash
# ❌ Old way: Client-side merge (can lose changes)
kubectl apply -f deployment.yaml

# ✅ Better: Server-side apply (conflict detection)
kubectl apply -f deployment.yaml --server-side
# Kubernetes tracks field ownership; safe concurrent updates
```

Server-side apply enables:
- Multiple controllers managing non-conflicting fields
- Clear ownership semantics
- Automatic cleanup when controllers are removed

**3. Use Three-Way Merge Strategy**

When updating an object with local changes:

```
Last Applied (in manifest file)
    ▲
    │
    ├─────────────── Current (in cluster)
    │
    └─────────────── Modified (manual kubectl edit)
```

Kubernetes uses three-way merge to determine:
- If a field was explicitly changed by user
- If a field drifted due to a controller
- Safe way to merge the update

**4. Enable Audit Logging for Compliance**

Record all object mutations for compliance:

```yaml
# In kube-apiserver manifest
- --audit-log-path=/var/log/audit/audit.log
- --audit-policy-file=/etc/kubernetes/audit-policy.yaml
```

Audit log entries:
```json
{
  "level": "RequestResponse",
  "timestamp": "2026-03-10T14:55:30.123456Z",
  "verb": "create",
  "user": {"username": "alice@company.com"},
  "objectRef": {
    "apiVersion": "apps/v1",
    "kind": "Deployment",
    "name": "api-server",
    "namespace": "production"
  },
  "requestObject": {"spec": {"replicas": 3}},
  "responseStatus": {"code": 201}
}
```

Every change is auditable: Who changed what, when, and what was the before/after state.

#### Common Pitfalls

**Pitfall 1: Applying Incomplete Manifests**

❌ **Mistake:**
```yaml
# Only the Deployment, missing Service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: api
        image: myapi:v2.0.0

# Expected: kubectl apply -f *.yaml (includes service.yaml)
# Actual: kubectl apply -f deployment.yaml (missing service.yaml)
# Result: Pod is running, but Service still points to old version
```

✅ **Better:**
```bash
# Apply all manifests atomically
kubectl apply -f /path/to/manifests/

# Or use Kustomize to ensure all related manifests applied together
kubectl apply -k /path/to/kustomize/
```

**Pitfall 2: Manual Edits Overwriting Manifest Intent**

❌ **Mistake:**
```bash
# Manifest says replicas: 3
kubectl patch deployment api -p '{"spec":{"replicas":5}}'
# Now cluster has 5 replicas, manifest still says 3
# Next apply of manifest: reverts to 3 (confusing!)
```

✅ **Better:**
```bash
# Update manifest first, then apply
vi deployment.yaml  # Change replicas: 3 → replicas: 5
kubectl apply -f deployment.yaml
```

**Pitfall 3: Assuming Spec Changes Trigger Immediate Rollout**

❌ **Mistake:**
```bash
kubectl set image deployment/api api=myapi:v2.0.1  # Imperative
# Pods are killed and restarted immediately
```

✅ **Better:** Updated manifests allow orchestration tools to control rollout:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # One extra Pod during rollout
      maxUnavailable: 0    # All Pods always available
  template:
    spec:
      containers:
      - name: api
        image: myapi:v2.0.1  # Changed from manifest, not imperative
```

**Pitfall 4: Not Using Field Selectors for Cleanup**

❌ **Mistake:**
```bash
# Delete everything
kubectl delete all --all
# Oops, this also deleted PVCs, ConfigMaps, Secrets, Ingresses
```

✅ **Better:**
```bash
# Only delete what the manifest created
kubectl delete -f deployment.yaml

# Or use labels for selective cleanup
kubectl delete pods -l app=api,version=v1.0.0
```

---

### Practical Code Examples

#### Example 1: Canary Deployment with Declarative Control

```yaml
---
# Stable production deployment (90% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-stable
  namespace: production
  labels:
    app: api
    version: stable
spec:
  replicas: 9
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  selector:
    matchLabels:
      app: api
      version: stable
  template:
    metadata:
      labels:
        app: api
        version: stable
    spec:
      containers:
      - name: api
        image: mycompany/api:v2.1.0
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api
              topologyKey: kubernetes.io/hostname

---
# Canary deployment (10% traffic, new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-canary
  namespace: production
  labels:
    app: api
    version: canary
spec:
  replicas: 1  # Start with 1, increase to 3 after validation
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api
      version: canary
  template:
    metadata:
      labels:
        app: api
        version: canary
      annotations:
        prometheus-scrape: "true"
        prometheus-port: "8080"
    spec:
      containers:
      - name: api
        image: mycompany/api:v3.0.0  # New version
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi

---
# Service selects from both stable and canary
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: api  # Selects both stable and canary Pods
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP

---
# Virtual Service for traffic splitting (requires Istio)
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api
  namespace: production
spec:
  hosts:
  - api
  http:
  - match:
    - headers:
        user-agent:
          regex: ".*Mobile.*"
    route:
    - destination:
        host: api
        port:
          number: 80
        subset: canary  # Route mobile users to canary
      weight: 10
    - destination:
        host: api
        port:
          number: 80
        subset: stable  # Route others to stable
      weight: 90

---
# Destination Rule for subset routing
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api
  namespace: production
spec:
  host: api
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1000
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
        maxRequestsPerConnection: 2
  subsets:
  - name: stable
    labels:
      version: stable
  - name: canary
    labels:
      version: canary
```

**Reconciliation flow:**
1. Apply manifests → API Server stores in etcd
2. Deployment Controllers create new ReplicaSets
3. ReplicaSet Controllers create Pods
4. Kubelet starts containers on nodes
5. Service Controller updates DNS and load balancer endpoints
6. Istio controllers inject sidecar proxies into Pods
7. Istio VirtualService controller configures traffic splitting
8. Metrics collected; if canary has errors, manually delete canary Deployment, automatic rollback

**To promote canary to stable:**
```bash
# 1. Monitor canary metrics (review dashboards)
# 2. Increase canary replicas
kubectl patch deployment api-canary -p '{"spec":{"replicas":3}}'

# 3. Update ManifestFile: change stable to canary image
vi deployment.yaml  # api-stable image: v3.0.0
kubectl apply -f deployment.yaml

# 4. Delete old canary Deployment
kubectl delete deployment api-canary

# 5. Commit updated manifest to Git
git add deployment.yaml && git commit -m "Promote v3.0.0 to stable"
```

#### Example 2: Configuration Management with ConfigMap

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
  labels:
    app: api
    version: v2.1.0
data:
  # application.properties format
  application.properties: |
    server.port=8080
    server.servlet.context-path=/api
    spring.application.name=api-server
    spring.datasource.url=jdbc:postgresql://postgres-prod.internal:5432/api
    spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.PostgreSQLDialect
    spring.jpa.hibernate.ddl-auto=validate
    logging.level.root=INFO
    logging.level.com.mycompany.api=DEBUG
    management.endpoints.web.exposure.include=health,metrics,prometheus
    management.metrics.export.prometheus.enabled=true
    
  # nginx configuration
  nginx.conf: |
    user nginx;
    worker_processes auto;
    error_log /var/log/nginx/error.log warn;
    pid /var/run/nginx.pid;

    events {
      worker_connections 2048;
      use epoll;
    }

    http {
      include /etc/nginx/mime.types;
      default_type application/octet-stream;

      log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

      access_log /var/log/nginx/access.log main;
      sendfile on;
      tcp_nopush on;
      keepalive_timeout 65;
      gzip on;

      upstream api {
        least_conn;
        server api-1:8080 max_fails=3 fail_timeout=30s;
        server api-2:8080 max_fails=3 fail_timeout=30s;
        server api-3:8080 max_fails=3 fail_timeout=30s;
      }

      server {
        listen 80 default_server;
        server_name api.example.com;

        location /health {
          access_log off;
          return 200 'OK';
          add_header Content-Type text/plain;
        }

        location / {
          proxy_pass http://api;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_connect_timeout 5s;
          proxy_send_timeout 10s;
          proxy_read_timeout 10s;
        }
      }
    }

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
      annotations:
        config-hash: "abc123def456"  # Change triggers Pod restart
    spec:
      serviceAccountName: api-server
      containers:
      - name: api
        image: mycompany/api:v2.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
        envFrom:
        - configMapRef:
            name: app-config  # Mount all ConfigMap keys as env vars
        volumeMounts:
        - name: config
          mountPath: /etc/app/config
          readOnly: true
        - name: logs
          mountPath: /var/log/app
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        livenessProbe:
          httpGet:
            path: /api/actuator/health/liveness
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/actuator/health/readiness
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
      volumes:
      - name: config
        configMap:
          name: app-config
          defaultMode: 0644
          items:
          - key: application.properties
            path: application.properties
      - name: logs
        emptyDir: {}  # Temporary storage, lost on Pod restart
```

**How declarative config works:**
1. Ops team updates ConfigMap with new database URL
2. `kubectl apply -f configmap.yaml` → stored in etcd
3. Pods mount ConfigMap as volume (file) or environment variables
4. Application reads configuration at startup or watches for changes
5. Rolling restart of Deployments to pick up new config
6. All changes audited in Kubernetes API audit logs

**Rollback if config is wrong:**
```bash
# Step 1: Get previous ConfigMap version
kubectl rollout history cm/app-config

# Step 2: Restore previous ConfigMap
git show HEAD~1:configmap.yaml | kubectl apply -f -

# Step 3: Watch Pods restart with old config
kubectl rollout restart deployment/api-server
kubectl rollout status deployment/api-server
```

---

### ASCII Diagrams

#### Diagram 1: Reconciliation Loop from Manifest to Running Pod

```
User writes manifest to Git
        │
        ▼
┌──────────────────────────────────────────────┐
│  Manifest in Git Repository                   │
│  apiVersion: apps/v1                          │
│  kind: Deployment                             │
│  metadata: name=api                           │
│  spec: replicas=3, image=api:v2.1.0          │
└──────────────────────────────────────────────┘
        │
        │ git push (or manual apply)
        ▼
┌──────────────────────────────────────────────┐
│  Kube-API Server (REST endpoint)              │
│  POST /apis/apps/v1/deployments               │
│  (Accepts manifest)                           │
└──────────────────────────────────────────────┘
        │
        ├─────────────────────┬─────────────────┐
        ▼                     ▼                 ▼
┌───────────────┐  ┌──────────────────┐  ┌─────────────────┐
│  Validation   │  │  Admission       │  │  Authorization  │
│  Webhooks     │  │  Webhooks        │  │  (RBAC Check)   │
│  └ syntax OK? │  │  └ Enforce       │  │  └ Can create?  │
│  └ refs valid?│  │    policies      │  │                 │
└───────────────┘  └──────────────────┘  └─────────────────┘
        │                     │                 │
        └─────────────────────┴─────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Persist in etcd  │
                    │  (Durable store)  │
                    └──────────────────┘
                              │
                              ▼
                    ┌──────────────────────────────┐
                    │  Emit Event:                  │
                    │  "Deployment 'api' created"  │
                    └──────────────────────────────┘
                              │
                    ┌─────────┴──────────┬─────────────┐
                    ▼                    ▼             ▼
        ┌────────────────────┐  ┌─────────────┐  ┌──────────────┐
        │ Deployment Ctrl    │  │ Other Ctrls │  │ Webhooks     │
        │ watches for events │  │             │  │              │
        └────────────────────┘  └─────────────┘  └──────────────┘
                    │
                    │ "I need to create a ReplicaSet"
                    │ to reach desired replicas=3
                    ▼
        ┌────────────────────────────────────┐
        │ POST /apis/apps/v1/replicasets     │
        │ Create ReplicaSet: api-abc123      │
        │ with replicas=3                    │
        └────────────────────────────────────┘
                    │
                    ▼
        ┌────────────────────┐
        │ (ReplicaSet stored) │
        └────────────────────┘
                    │
                    ▼
        ┌────────────────────┐
        │ Emit Event:        │
        │ "ReplicaSet created"│
        └────────────────────┘
                    │
                    ▼
        ┌────────────────────────┐
        │ ReplicaSet Controller   │
        │ "I need to create 3 Pods"│
        └────────────────────────┘
                    │
                    │ POST /api/v1/pods (×3)
                    │ Create Pods: api-abc123-xxxxx
                    ▼
        ┌────────────────────┐
        │ (Pods stored)      │
        │ status: Pending    │
        └────────────────────┘
                    │
                    ▼
        ┌────────────────────┐
        │ Emit Events:       │
        │ "Pod created" (×3) │
        └────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    ▼               ▼               ▼
┌───────────┐  ┌───────────┐  ┌───────────┐
│  Kubelet  │  │  Kubelet  │  │  Kubelet  │
│  Node-1   │  │  Node-2   │  │  Node-3   │
│  "Pod     │  │  "Pod     │  │  "Pod     │
│  assigned │  │  assigned │  │  assigned │
│  to me"   │  │  to me"   │  │  to me"   │
└───────────┘  └───────────┘  └───────────┘
    │               │               │
    │ PATCH status  │ PATCH status  │ PATCH status
    │ phase:Running │ phase:Running │ phase:Running
    ▼               ▼               ▼
  Pod Running    Pod Running    Pod Running
  Container→     Container→     Container→
  Ready (pass     Ready (pass    Ready (pass
   health check)   health check)  health check)
    │               │               │
    └───────────────┼───────────────┘
                    │
                    ▼
        ┌────────────────────────┐
        │ Deployment status:     │
        │ replicas: 3            │
        │ ready: 3               │
        │ updated: 3             │
        │ generation: 1          │
        └────────────────────────┘
```

#### Diagram 2: Desired vs. Actual State Reconciliation

```
┌─────────────────────────────────────────────────────────────┐
│                   DESIRED STATE (Spec)                      │
│                                                             │
│  Deployment: api-server                                    │
│  ├─ replicas: 3                                            │
│  ├─ image: api:v2.1.0                                      │
│  ├─ cpu request: 100m, limit: 500m                         │
│  ├─ memory request: 256Mi, limit: 512Mi                    │
│  └─ liveness probe: /healthz every 10s                     │
└─────────────────────────────────────────────────────────────┘
         △
         │
    User applies manifest
    kubectl apply -f deployment.yaml
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   API SERVER / ETCD                          │
│                                                             │
│  ├─ Receives manifest                                      │
│  ├─ Validates schema                                       │
│  ├─ Stores in etcd                                         │
│  └─ Emits events to controllers                            │
└─────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   CONTROLLERS (Reconciliation Loop)          │
│                                                             │
│  Deployment Controller:                                    │
│  while (true) {                                            │
│    desiredReplicas = spec.replicas           // 3          │
│    actualReplicas = pods.count()             // 0          │
│    if (actual < desired) {                                 │
│      createReplicaSet(name="api-abc123", replicas=3)       │
│      updateStatus(                                         │
│        replicas: 3,                                        │
│        ready: 0,    // waiting for readiness probe         │
│        updated: 3                                          │
│      )                                                      │
│    }                                                        │
│    sleep(5 seconds)  // Check again                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
         │
         ├─ Creates ReplicaSet
         ├─ ReplicaSet creates Pods
         ├─ Kubelet starts containers
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   ACTUAL STATE (Objects in Cluster)         │
│                                                             │
│  Pod: api-abc123-xxxxx-1                                   │
│  ├─ status: Running                                        │
│  ├─ image: api:v2.1.0   ✓ (matches desired)               │
│  ├─ cpu usage: 45m       ✓ (under 100m request)           │
│  ├─ memory usage: 210Mi  ✓ (under 256Mi request)          │
│  └─ liveness probe: PASS                                   │
│                                                             │
│  Pod: api-abc123-xxxxx-2                                   │
│  ├─ status: Running                                        │
│  ├─ image: api:v2.1.0   ✓ (matches desired)               │
│  └─ liveness probe: PASS                                   │
│                                                             │
│  Pod: api-abc123-xxxxx-3                                   │
│  ├─ status: Running                                        │
│  ├─ image: api:v2.1.0   ✓ (matches desired)               │
│  └─ liveness probe: PASS                                   │
└─────────────────────────────────────────────────────────────┘
         △
         │
   STATUS FIELD UPDATED
   status: {
     replicas: 3,
     ready: 3,
     updated: 3,
     observedGeneration: 1
   }
         │
         └─────────────── CONVERGENCE ACHIEVED ───────────────


         If a Pod FAILS:
         ├─ kubelet detects crash
         ├─ updates Pod.status = Failed
         ├─ ReplicaSet Controller sees actual < desired
         ├─ Creates new Pod
         └─ Convergence restored

         If user EDITS manifest (replicas: 3 → replicas: 5):
         ├─ kubectl apply -f deployment.yaml
         ├─ spec.replicas updated to 5
         ├─ Deployment Controller detects mismatch
         ├─ Creates 2 new Pods
         └─ Convergence restored with new replica count
```

---

## YAML Structure and Best Practices

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes objects are serialized as YAML (or JSON) documents that are parsed by the API server and stored in etcd. The YAML structure is NOT arbitrary—it must conform to the OpenAPI schema defined for each Kind.

```
┌──────────────────────────────────────┐
│  YAML Document                        │
│  (human-readable)                    │
│                                      │
│  apiVersion: apps/v1                │
│  kind: Deployment                   │
│  metadata:                           │
│    name: api                         │
│  spec:                               │
│    replicas: 3                       │
└──────────────────────────────────────┘
            │
            │ kubectl parses YAML
            ▼
┌──────────────────────────────────────┐
│  Internal Structure (Go struct)       │
│  {                                    │
│    apiVersion: "apps/v1",             │
│    kind: "Deployment",                │
│    metadata: {                        │
│      name: "api",                     │
│      namespace: "default"             │
│    },                                 │
│    spec: {                            │
│      replicas: 3                      │
│    }                                  │
│  }                                    │
└──────────────────────────────────────┘
            │
            │ Validate against OpenAPI schema
            ▼
┌──────────────────────────────────────┐
│  Schema Validation                    │
│  ├─ Required fields present?          │
│  ├─ Field types correct?              │
│  ├─ Enum values valid?                │
│  ├─ Cross-field dependencies?         │
│  └─ Custom validation rules?          │
└──────────────────────────────────────┘
            │
            │ If valid: serialize to JSON
            ▼
┌──────────────────────────────────────┐
│  JSON Document                        │
│  (compact for storage)               │
│  {"apiVersion":"apps/v1",            │
│   "kind":"Deployment",               │
│   "metadata":{...},                  │
│   "spec":{...}}                      │
└──────────────────────────────────────┘
            │
            │ Send to API Server
            ▼
┌──────────────────────────────────────┐
│  Kubernetes API Server                │
│  ├─ Store in etcd                    │
│  ├─ Record in audit log              │
│  └─ Emit watch events                │
└──────────────────────────────────────┘
```

Critical insight: **YAML is just a serialization format. It's the schema that enforces structure.**

#### Schema Validation Layers

When you apply a manifest, validation happens in multiple layers:

```
YAML Manifest
    │
    ▼
① CLIENT-SIDE VALIDATION (kubectl)
   └─ Basic YAML syntax
   └─ API version availability
   └─ Kind recognition
   └─ Field name spelling
      (Does NOT validate values yet)
    │
    ├─ If fails: kubectl rejects before reaching API server
    │  Error: "apiVersion: apps/v2 not found"
    │
    ▼
② API SERVER STATIC VALIDATION
   └─ OpenAPI schema validation
   └─ Type checking
   └─ Required/optional field validation
   └─ Enum validation
      (Standard Kubernetes validation rules)
    │
    ├─ If fails: API returns 422 Unprocessable Entity
    │  Error: "spec.replicas: must be integer"
    │
    ▼
③ ADMISSION WEBHOOKS (ValidatingWebhook)
   └─ Custom policies
   └─ Business logic validation
   └─ Cross-cluster consistency
      (Run by admission webhook controllers)
    │
    ├─ If fails: API returns 400 Bad Request
    │  Error: "Image pull policy must be IfNotPresent in production"
    │
    ▼
④ PERSISTENT STORAGE (etcd)
   └─ Object stored durably
    │
    ▼
⑤ ADMISSION WEBHOOKS (MutatingWebhook)
   └─ Modify object after storage
   └─ Inject defaults
   └─ Add annotations
      (Run asynchronously, idempotent)

Final Result: Object in cluster + Event emitted to controllers
```

#### Architecture Role

YAML structure enables:

1. **Declarative Intent Expression:** YAML is human-readable; easier to review changes than imperative scripts
2. **Version Control:** Text format for Git-based workflows
3. **Schema-Driven Validation:** Enforces consistency across all objects
4. **API Evolution:** New fields can be added without breaking old manifests
5. **Tooling Ecosystem:** Kustomize, Helm, Jsonnet all operate on YAML
6. **Documentation:** Self-documenting infrastructure (manifest IS the documentation)

#### Production Usage Patterns

**Pattern 1: Multi-Document Manifests (---  Separator)**

```yaml
---  # Separator
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  config.json: '{"level": "INFO"}'

---  # Separator
apiVersion: v1
kind: Secret
metadata:
  name: db-password
type: Opaque
stringData:
  password: supersecret

---  # Separator
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      containers:
      - name: api
        image: myapi:v2.1.0
        envFrom:
        - configMapRef:
            name: app-config
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-password
              key: password
```

**Pattern 2: Kustomize Bases and Overlays**

```
├─ base/
│  ├─ kustomization.yaml  (Defines reusable components)
│  ├─ deployment.yaml
│  ├─ service.yaml
│  └─ configmap.yaml
│
├─ overlays/
│  ├─ development/
│  │  └─ kustomization.yaml  (Override for dev)
│  │     └─ image tag: dev
│  │     └─ replicas: 1
│  │     └─ resources limits: low
│  │
│  ├─ staging/
│  │  └─ kustomization.yaml  (Override for staging)
│  │     └─ image tag: rc-1
│  │     └─ replicas: 2
│  │
│  └─ production/
│     └─ kustomization.yaml  (Override for production)
│        └─ image tag: v2.1.0
│        └─ replicas: 10
│        └─ resources limits: high
│        └─ Add pod disruption budgets
│        └─ Add HPA
```

**Benefits:**
- Base defines common structure once
- Overlays customize per environment without duplication
- Changes to base propagate automatically to all overlays
- DRY (Don't Repeat Yourself) principle applied to infrastructure

**Pattern 3: Helm Charts with Templates**

```
chart/
├─ Chart.yaml              (Chart metadata)
├─ values.yaml             (Default values)
├─ values-prod.yaml        (Production overrides)
├─ values-staging.yaml     (Staging overrides)
└─ templates/
   ├─ deployment.yaml      (Templated)
   ├─ service.yaml         (Templated)
   ├─ ingress.yaml         (Templated)
   ├─ configmap.yaml       (Templated)
   └─ _helpers.tpl         (Helper functions)
```

Helm template rendering:
```
values.yaml (image: myapi:{{ .Values.image.tag }})
    +
values-prod.yaml (image.tag: v2.1.0)
    │
    ▼
Helm template engine
    │
    ▼
Rendered.yaml (image: myapi:v2.1.0)
    │
    ▼
kubectl apply -f rendered.yaml
```

#### DevOps Best Practices

**1. Use Explicit Field Names (Avoid Abbreviations)**

❌ **Bad:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  n: api                    # Non-standard abbreviation
  ns: prod                  # Should be 'namespace'
spec:
  rep: 3                    # Should be 'replicas'
  sel:                      # Should be 'selector'
    ml:                     # Should be 'matchLabels'
      a: api                # Should be 'app'
```

✅ **Good:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
```

**2. Structure for Readability and Maintainability**

✅ **Good:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
    version: v2.1.0
  annotations:
    "description": "Payment processing API"

spec:
  # Replica strategy
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0

  # Selector
  selector:
    matchLabels:
      app: api-server

  # Template
  template:
    metadata:
      labels:
        app: api-server
        version: v2.1.0

    spec:
      serviceAccountName: api-server
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000

      # Init containers
      initContainers:
      - name: migrate-db
        image: myapi:v2.1.0
        command: ["/bin/sh"]
        args: ["-c", "npm run migrate"]

      # Application containers
      containers:
      - name: api
        image: myapi:v2.1.0
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP

        # Environment configuration
        env:
        - name: NODE_ENV
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: db-host
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password

        # Resource requests and limits
        resources:
          requests:
            cpu: "200m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"

        # Health checks
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3

        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2

        # Volume mounts
        volumeMounts:
        - name: config
          mountPath: /etc/app/config
          readOnly: true
        - name: cache
          mountPath: /tmp/cache

      # Sidecar containers
      - name: logging-sidecar
        image: fluent-bit:1.9
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
          readOnly: true

      # Volumes
      volumes:
      - name: config
        configMap:
          name: app-config
      - name: cache
        emptyDir:
          sizeLimit: 1Gi
      - name: logs
        emptyDir:
          medium: Memory
          sizeLimit: 500Mi

      # Pod-level scheduling
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api-server
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: workload-class
                operator: In
                values:
                - compute-optimized

      # Tolerations for taints
      tolerations:
      - key: workload-class
        operator: Equal
        value: compute-optimized
        effect: NoSchedule

      # Termination
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
```

**3. Validate YAML Before Committing to Git**

```bash
# Syntax validation
yaml-lint deployment.yaml

# Schema validation against Kubernetes API
kubectl apply -f deployment.yaml --dry-run=server --validate=strict

# Linting against best practices
kubectl-score deployment.yaml

# Check for security issues
kubesec deployment.yaml
```

**4. Use Custom Resource Definitions (CRDs) for Domain Objects**

Instead of creating free-form ConfigMaps, define structured CRDs:

```yaml
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: canarydeployments.deploy.example.com
spec:
  group: deploy.example.com
  names:
    kind: CanaryDeployment
    plural: canarydeployments
  scope: Namespaced
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              stableVersion:
                type: string
                pattern: '^v[0-9]+\.[0-9]+\.[0-9]+$'
              canaryVersion:
                type: string
                pattern: '^v[0-9]+\.[0-9]+\.[0-9]+$'
              canaryTrafficPercent:
                type: integer
                minimum: 0
                maximum: 100
              successThreshold:
                type: number
                minimum: 0.95
                maximum: 1.0
              maxRetries:
                type: integer
                minimum: 1
                maximum: 10

---
# Now use the CRD
apiVersion: deploy.example.com/v1
kind: CanaryDeployment
metadata:
  name: api-promotion
spec:
  stableVersion: v2.0.0
  canaryVersion: v2.1.0
  canaryTrafficPercent: 10
  successThreshold: 0.99
  maxRetries: 3
```

---

### Practical Code Examples

#### Example 1: Complex YAML with All Best Practices

```yaml
---
# ConfigMap for application configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-server-config
  namespace: production
  labels:
    app: api-server
    version: v2.1.0
  annotations:
    description: "Application configuration for API server v2.1.0"
data:
  application.yml: |
    server:
      port: 8080
      servlet:
        context-path: /api
    spring:
      application:
        name: api-server
      profiles:
        active: production
      jpa:
        hibernate:
          ddl-auto: validate
    logging:
      level:
        root: INFO
        com.mycompany.api: DEBUG

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: api-server-secrets
  namespace: production
  labels:
    app: api-server
type: Opaque
stringData:
  database-password: "${DB_PASSWORD}"  # Injected at deployment time
  api-key: "${API_KEY}"

---
# ServiceAccount for Pod identity
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server

---
# Role for RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: api-server
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]

---
# RoleBinding to attach Role to ServiceAccount
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: api-server
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: api-server
subjects:
- kind: ServiceAccount
  name: api-server
  namespace: production

---
# Deployment with full best practices
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
    version: v2.1.0
    team: backend
    cost-center: engineering
  annotations:
    deployment.kubernetes.io/revision: "1"
    fluxcd.io/automated: "true"
    fluxcd.io/tag.api: semver:~2.1
spec:
  replicas: 3
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api-server
  template:
    metadata:
      labels:
        app: api-server
        version: v2.1.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/actuator/prometheus"
    spec:
      serviceAccountName: api-server
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: api
        image: mycompany/api:v2.1.0  # Use digest in production
        imagePullPolicy: IfNotPresent
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
              - ALL
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        env:
        - name: JAVA_OPTS
          value: "-XX:+UseG1GC -XX:MaxGCPauseMillis=200"
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: api-server-secrets
              key: database-password
        envFrom:
        - configMapRef:
            name: api-server-config
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
            ephemeral-storage: 100Mi
          limits:
            cpu: 1000m
            memory: 1Gi
            ephemeral-storage: 500Mi
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: http
            httpHeaders:
            - name: X-Probe-Type
              value: Kubernetes
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 2
        startupProbe:
          httpGet:
            path: /actuator/health/startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 10
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 30
        volumeMounts:
        - name: config
          mountPath: /etc/api/config
          readOnly: true
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /tmp/cache
      volumes:
      - name: config
        configMap:
          name: api-server-config
          defaultMode: 0444
      - name: tmp
        emptyDir:
          medium: Memory
          sizeLimit: 100Mi
      - name: cache
        emptyDir:
          sizeLimit: 500Mi
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api-server
              topologyKey: kubernetes.io/hostname
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 50
            preference:
              matchExpressions:
              - key: node-type
                operator: In
                values:
                - compute-optimized
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: api-server
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
        - name: ndots
          value: "1"

---
# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 10
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
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
      - type: Pods
        value: 4
        periodSeconds: 60
      selectPolicy: Max

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: production
  labels:
    app: api-server
  annotations:
    service.spec.clusterIP: "10.0.0.100"  # Optional static IP
spec:
  type: ClusterIP
  selector:
    app: api-server
  ports:
  - port: 80
    targetPort: http
    protocol: TCP
    name: http
  sessionAffinity: None

---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-server
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.example.com
    secretName: api-server-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-server
            port:
              number: 80
```

---

### ASCII Diagrams

#### Diagram 1: YAML Parsing Pipeline

```
┌────────────────────────────────┐
│  Raw YAML File (Text)          │
│                                │
│ apiVersion: apps/v1            │
│ kind: Deployment               │
│ metadata:                      │
│   name: api                    │
│ spec:                          │
│   replicas: 3                  │
└────────────────────────────────┘
         │
         │ kubectl apply -f deployment.yaml
         ▼
┌────────────────────────────────────────────┐
│  YAML Parser (PyYAML / Go YAML library)    │
│                                            │
│  Converts indented text to data structure  │
│                                            │
│  Input:  "spec:\n  replicas: 3"           │
│  Output: {"spec": {"replicas": 3}}        │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  API Group & Version Resolution            │
│                                            │
│  apiVersion: apps/v1                       │
│  ├─ API Group: apps                        │
│  └─ Version: v1                            │
│                                            │
│  Look up Kind "Deployment" in apps/v1      │
│  GVK (Group, Version, Kind) identified     │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  OpenAPI Schema Lookup                     │
│                                            │
│  GET /openapi/v2 (or v3) from API server   │
│                                            │
│  Schema defines for Deployment:            │
│  ├─ Type: object                           │
│  ├─ Required fields: ["apiVersion",        │
│  │                   "kind",               │
│  │                   "metadata"]           │
│  ├─ Properties:                            │
│  │  ├─ apiVersion: type=string             │
│  │  ├─ kind: type=string                   │
│  │  ├─ metadata: type=object (nested)      │
│  │  ├─ spec: type=object (nested)          │
│  │  │  ├─ replicas: type=integer           │
│  │  │  │            minimum=0              │
│  │  │  ├─ template: type=object (nested)   │
│  │  │  └─ ... (hundreds more fields)       │
│  │  └─ status: type=object (read-only)     │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  Static Validation Against Schema          │
│                                            │
│  ✓ apiVersion: "apps/v1" (string) ✓       │
│  ✓ kind: "Deployment" (string) ✓          │
│  ✓ metadata.name: "api" (string) ✓        │
│  ✓ spec.replicas: 3 (integer) ✓           │
│  ✓ metadata.namespace: "default" (auto)   │
│                                            │
│  If validation fails:                      │
│  ✗ spec.replicas: "three" (not integer)   │
│  └─ ERROR: 422 Unprocessable Entity        │
└────────────────────────────────────────────┘
         │
         ├─ If fails: Stop, return error
         │
         ▼
┌────────────────────────────────────────────┐
│  Admission Webhooks (Validation)           │
│                                            │
│  Custom validation policies                │
│  ├─ Image must be pinned to digest         │
│  ├─ Must have resource requests/limits     │
│  ├─ Must have labels                       │
│  ├─ CPU request must be < 2000m            │
│  └─ ... (domain-specific rules)            │
│                                            │
│  If validation fails:                      │
│  ✗ Image is "nginx:latest" (not pinned)   │
│  └─ ERROR: 400 Bad Request                 │
│     "Image tag 'latest' not allowed"      │
└────────────────────────────────────────────┘
         │
         ├─ If fails: Stop, return error
         │
         ▼
┌────────────────────────────────────────────┐
│  Serialize to JSON                         │
│                                            │
│  Python dict → JSON string                 │
│  {"apiVersion":"apps/v1",                  │
│   "kind":"Deployment",                    │
│   "metadata":{"name":"api"},              │
│   "spec":{"replicas":3}}                  │
│                                            │
│  (More compact than YAML for storage)      │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  Send to Kubernetes API Server             │
│                                            │
│  POST https://kube-apiserver:443/          │
│    /apis/apps/v1/namespaces/default/       │
│    /deployments                            │
│                                            │
│  Headers:                                  │
│  Authorization: Bearer <token>             │
│  Content-Type: application/json            │
│                                            │
│  Body: JSON serialized object              │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  API Server Validates Again                │
│  (Server-side validation)                  │
│                                            │
│  Defensive: validate again even though     │
│  kubectl already validated                 │
│                                            │
│  Checks:                                   │
│  ├─ RBAC: Can this user create objects?    │
│  ├─ Schema: Is this still valid?           │
│  ├─ Admission webhooks run again           │
│  └─ ... (server may have different         │
│        validation rules than client)       │
└────────────────────────────────────────────┘
         │
         ├─ If fails: Return 4xx error
         │
         ▼
┌────────────────────────────────────────────┐
│  Store in etcd                             │
│                                            │
│  Object persisted durably                  │
│  ├─ Key: /deployments/default/api          │
│  └─ Value: JSON object                     │
│                                            │
│  Replication: 3 etcd nodes by default      │
│  Backup: Regular snapshots from etcd       │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  Emit Watch Events                         │
│                                            │
│  Event: ADDED                              │
│  Object: Deployment/default/api            │
│  Generation: 1                             │
│  Timestamp: 2026-03-10T15:00:00Z           │
│                                            │
│  Controllers watching for  "Deployment"   │
│  events receive notification               │
└────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────┐
│  Controllers Wake Up & Reconcile           │
│  (Deployment Controller, Service           │
│   Controller, etc.)                        │
│                                            │
│  "New Deployment created"                  │
│  "I need to create a ReplicaSet"           │
│  "I need to ensure 3 Pods exist"           │
│                                            │
│  Reconciliation loop triggered             │
└────────────────────────────────────────────┘
```

#### Diagram 2: YAML Indentation and Nesting Rules

```
Incorrect Indentation Examples:

✗ Bad:  "spaces vs tabs" (mixed)
apiVersion: apps/v1
kind: Deployment           <- tab character (will fail)
metadata:
  name: api              <- space characters

✓ Good: Consistent spacing (2 or 4 spaces)
apiVersion: apps/v1
kind: Deployment         <- spaces
metadata:                <- spaces
  name: api              <- 2 spaces indented
  namespace: default     <- 2 spaces indented
  labels:                <- 2 spaces indented
    app: api             <- 4 spaces indented (nested under labels)
    version: v2.1.0      <- 4 spaces indented (same level as app)

spect:
  replicas: 3            <- 2 spaces indented
  selector:              <- 2 spaces indented
    matchLabels:         <- 4 spaces indented (nested)
      app: api           <- 6 spaces indented (nested under matchLabels)


List Indentation:

✗ Bad: Incorrect list marker placement
containers:
  - name: api           <- list item at wrong indentation
    image: myapi:v2.1.0
  - name: sidecar
   image: sidecar:1.0   <- inconsistent indentation

✓ Good: Consistent list formatting
containers:
- name: api             <- list item at 0 offset from parent
  image: myapi:v2.1.0   <- properties of list item indented further
- name: sidecar
  image: sidecar:1.0    <- consistent indentation

portS:
- containerPort: 8080
  protocol: TCP
  name: http
- containerPort: 9090
  protocol: TCP
  name: metrics


Common YAML Nesting Patterns in Kubernetes:

metadata (always present)
└─ name: string                     <- 2 spaces
└─ namespace: string                <- 2 spaces (omitted = default)
└─ labels: map                      <- 2 spaces
   └─ key: value                    <- 4 spaces
   └─ key: value
└─ annotations: map                 <- 2 spaces
   └─ key: value                    <- 4 spaces

spec (varies by Kind)
└─ for Deployment:
   ├─ replicas: integer             <- 2 spaces
   ├─ selector: object              <- 2 spaces
   │  └─ matchLabels: map           <- 4 spaces
   │     └─ key: value              <- 6 spaces
   └─ template: object              <- 2 spaces
      └─ spec: object               <- 4 spaces (Pod spec)
         ├─ containers: list        <- 6 spaces
         │  - name: string          <- 8 spaces (list item)
         │    image: string         <- 10 spaces (property of list item)
         └─ volumes: list           <- 6 spaces
            - name: string          <- 8 spaces
              emptyDir: object       <- 10 spaces
```

---

## Labels and Selectors

### Textual Deep Dive

#### Internal Working Mechanism

Labels are arbitrary key-value pairs attached to Kubernetes objects. They are queryable, unlike annotations. The API server maintains an index of label keys and values for efficient filtering.

```
Object in etcd:
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "api-pod-1",
    "labels": {
      "app": "api",
      "version": "v2.1.0",
      "environment": "production"
    }
  }
}
       │
       ▼
API Server Index (in-memory)
┌──────────────────────────────────┐
│ Label Index                             │
│                                         │
│ app=api                                 │
│ └─ api-pod-1                          │
│ └─ api-pod-2                          │
│ └─ api-deployment                      │
│                                         │
│ version=v2.1.0                          │
│ └─ api-pod-1                          │
│                                         │
│ version=v2.0.0                          │
│ └─ api-pod-old-1                      │
│                                         │
│ environment=production                   │
│ └─ api-pod-1                          │
│                                         │
│ environment=staging                      │
└─ └─ api-pod-2-staging               │ (different object)
└──────────────────────────────────┘
       │
       ▼
Label Selector Query
Kubectl: "Give me all Pods where app=api"
       │
       ▼
API Server uses index for O(1) lookup
Returns: [api-pod-1, api-pod-2, ...]
```

**Selector Types:**

1. **Equality-based:** `app=api`, `version!=v1.0.0`
2. **Set-based:** `app in (api, web)`, `tier not in (frontend)`
3. **Existence:** `environment`, `!deprecated`

#### Selectors Drive Key Functionality

```
Label Selector Used By:

├─ Service Selector
│  "Give me all Pods with app=api, and load-balance traffic to them"
│  Service endpoint discovery is label-based
│  If label changes, Pod is instantly removed from Service
│
├─ NetworkPolicy Selector
│  "Allow traffic only from Pods with team=backend"
│  Pod-to-Pod networking is controlled by label selectors
│
├─ PodAffinity/AntiAffinity
│  "Schedule this Pod only on nodes where another Pod with
│   app=database exists (spread across zones)"
│
├─ Deployment matchLabels
│  "ReplicaSet owns all Pods matching app=api, version=v2.1.0"
│  Label change triggers Pod recreation
│
├─ Node Affinity
│  "Schedule this Pod on nodes with gpu=nvidia"
│  Node label selectors control workload placement
│
├─ ResourceQuota
│  "Limit CPU to 1000m for all Pods with team=engineering"
│  Quota enforcement is label-based
│
├─ HPA Metrics
│  "Monitor Pods with app=api and scale if CPU > 70%"
│  Metrics collection uses selector
│
├─ RBAC Role Binding
│  "Give 'view' role to serviceaccounts with team=platform"
│  (Newer RBAC uses ServiceAccount subjects, but concept applies)
│
└─ Kyverno Policies
   "Reject Pods that don't have security-scan=passed label"
   Policy enforcement driven by label presence/value
```

#### Architecture Role

Labels are the **mechanism through which Kubernetes achieves dynamic service discovery and orchestration:**

- **Service Discovery:** Services discover endpoints via selectors, not hardcoded lists
- **Multi-tenancy:** Isolation via label selectors (namespace + labels)
- **Cost Allocation:** Cloud providers use labels for chargeback (cost center, team, environment)
- **Monitoring:** Prometheus scrapes metrics per labels
- **GitOps:** ArgoCD syncs objects based on label matching
- **Scheduling:** Controllers place workloads based on node/pod labels
- **Policy Enforcement:** Admission webhooks require/validate labels

#### Production Usage Patterns

**Pattern 1: Organized Label Hierarchy**

```yaml
metadata:
  labels:
    # Standard labels (recommended by Kubernetes)
    app: api-server
    app.kubernetes.io/name: api-server        # Semantic versioning
    app.kubernetes.io/instance: api-prod
    app.kubernetes.io/version: v2.1.0
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: payment-system
    app.kubernetes.io/managed-by: terraform
    
    # Organizational labels
    team: backend
    cost-center: engineering
    business-unit: payments
    
    # Operational labels
    environment: production
    region: us-east-1
    zone: us-east-1a
    
    # Data classification
    data-sensitivity: confidential
    compliance: pci-dss
    
    # Workload characteristics
    workload-type: stateless-api
    tier: application
    criticality: mission-critical
```

**Pattern 2: Label-Based Cross-Cluster Discovery**

```yaml
# In cluster-1 (production)
apiVersion: v1
kind: Pod
metadata:
  name: api-prod
  labels:
    app: api
    cluster-name: prod-us-east  # Label identifies source cluster
    environment: production

---
# In cluster-2 (staging)
apiVersion: v1
kind: Pod
metadata:
  name: api-staging
  labels:
    app: api
    cluster-name: staging-us-west  # Different cluster
    environment: staging

---
# Federation controller selects from all clusters
# "Get all Pods where app=api and environment=production"
# Returns: api-prod from cluster-1
#
# "Get all Pods where app=api (no environment filter)"
# Returns: api-prod + api-staging (from both clusters)
```

**Pattern 3: Dynamic Deployment Using Label Changes**

```bash
# Blue-green deployment
# Blue is currently receiving traffic
kubectl get pods -l app=api,version=blue
# Output: api-blue-1, api-blue-2, api-blue-3

# Green is ready but not receiving traffic yet
kubectl get pods -l app=api,version=green
# Output: api-green-1, api-green-2, api-green-3

# Service selector
kubectl get svc api -o yaml | grep -A2 selector
# Selector:
#   app: api
#   version: blue  # Currently pointing to blue

# When green is ready, change label on Service selector
kubectl patch service api -p '{"spec":{"selector":{"version":"green"}}}'
# Instant traffic cutover! All traffic now goes to green Pods

# Old blue Pods are no longer reached
kubectl get pods -l app=api,version=blue
# Still exist, but not receiving traffic
# Can be safely kept for quick rollback
```

#### DevOps Best Practices

**1. Always Use Labels, Never Depend on Names**

❌ **Bad:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  type: ClusterIP
  endpoints:  # ❌ WRONG: hardcoded list
  - 10.0.0.1
  - 10.0.0.2
  - 10.0.0.3
```

✅ **Good:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  type: ClusterIP
  selector:   # ✓ Dynamic selection
    app: api
  ports:
  - port: 80
    targetPort: 8080
```

**2. Standardize Label Keys Across Workloads**

❌ **Bad:**
```yaml
# Deployment uses different label keys
kind: Deployment
metadata:
  labels:
    name: api        # ❌ Should be 'app'
    ver: v2.1.0      # ❌ Should be 'version'
    env: prod        # ❌ Should be 'environment'

---
# Service uses different keys
kind: Service
metadata:
  labels:
    app: api         # Different from Deployment!
    version: v2.1.0
    environment: production
```

✅ **Good:**
```yaml
# All objects use consistent label schema
kind: Deployment
metadata:
  labels:
    app: api
    version: v2.1.0
    environment: production

---
kind: Service
metadata:
  labels:
    app: api
    version: v2.1.0
    environment: production
```

**3. Use Label Validation Webhooks**

Enforce that required labels are present:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: enforce-labels
webhooks:
- name: labels.example.com
  clientConfig:
    service:
      name: webhook-service
      namespace: gatekeeper
      path: "/validate"
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["apps"]
    apiVersions: ["v1"]
    resources: ["deployments"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
```

Webhook validates that every Deployment has these labels:
- `app`
- `version`
- `team`
- `environment`

If missing, webhook rejects the object: `"Deployment must have 'team' label"`

**4. Monitor Label Changes**

```bash
# Alert when critical labels are removed
kubectl get pods -l app=api \
  --watch-only \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels}{"\n"}{end}'

# Alert on label value mutations
kubectl get deployments \
  --all-namespaces \
  -o custom-columns=\
NAME:.metadata.name,\
APP:.metadata.labels.app,\
VERSION:.metadata.labels.version \
  --sort-by=.metadata.labels.app
```

#### Common Pitfalls

**Pitfall 1: Labels That Should Be Immutable Change at Runtime**

❌ **Problem:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  selector:
    matchLabels:
      app: api
      version: v2.0.0  # Lockdown selector to v2.0.0
  template:
    metadata:
      labels:
        app: api
        version: v2.0.0

# Later, someone manually patches:
kubectl label pod api-abc-123 version=v2.1.0
# Now Pod is no longer owned by ReplicaSet!
# ReplicaSet sees: actual=2 (lost one), desired=3
# Creates a new Pod to fill gap
# Result: More Pods than expected
```

✅ **Solution:**
Set `immutable` flag or use admission webhooks to prevent label mutations:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: immutable-labels
webhooks:
- name: immutable.example.com
  rules:
  - operations: ["UPDATE"]
  failurePolicy: Fail
```

**Pitfall 2: Label Selectors Only Partially Match Application Topology**

❌ **Problem:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api  # Only one label selector
  # Missing: version selector
  # Result: Service routes to BOTH v2.1.0 and v1.0.0 Pods
  # During deployment transition, mixed versions receive traffic!
```

✅ **Solution:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-v2  # Version-specific service
spec:
  selector:
    app: api
    version: v2.1.0  # Explicit version selector
  ports:
  - port: 80
    targetPort: 8080
```

**Pitfall 3: Label-Based Quota Prevents Workload Deployment**

❌ **Problem:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-backend-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"        # 10 CPUs total for team-backend
    requests.memory: "20Gi"    # 20GB total
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values: ["high-priority"]

# Deployment missing label
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-api
spec:
  template:
    spec:
      priorityClassName: high-priority  # Has this
      containers:
      - resources:
          requests:
            cpu: "5"  # Uses 5 CPUs
      # Missing: team=backend label

# Result: Quota applies, Pod is rejected!
# "Exceeded quota for team-backend: cpu"
```

---

### Practical Code Examples

#### Example 1: Multi-Stage Deployment with Label-Based Service Discovery

```yaml
---
# Canary deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-canary
  namespace: production
  labels:
    app: api
    version: v3.0.0
    stage: canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
      version: v3.0.0
      stage: canary
  template:
    metadata:
      labels:
        app: api
        version: v3.0.0
        stage: canary
    spec:
      containers:
      - name: api
        image: myapi:v3.0.0
        resources:
          requests:
            cpu: 100m
            memory: 256Mi

---
# Stable deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-stable
  namespace: production
  labels:
    app: api
    version: v2.1.0
    stage: stable
spec:
  replicas: 10
  selector:
    matchLabels:
      app: api
      version: v2.1.0
      stage: stable
  template:
    metadata:
      labels:
        app: api
        version: v2.1.0
        stage: stable
    spec:
      containers:
      - name: api
        image: myapi:v2.1.0
        resources:
          requests:
            cpu: 100m
            memory: 256Mi

---
# Service selects from BOTH stable and canary (all app=api)
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: production
spec:
  type: LoadBalancer
  selector:
    app: api  # Selects all Pods with app=api (90% stable, 10% canary)
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP

---
# Monitoring: Scrape metrics only from stable
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-stable-metrics
  namespace: production
spec:
  selector:
    matchLabels:
      app: api
      stage: stable
  endpoints:
  - port: metrics
    interval: 30s

---
# Monitoring: Separate dashboard for canary
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-canary-metrics
  namespace: production
spec:
  selector:
    matchLabels:
      app: api
      stage: canary
  endpoints:
  - port: metrics
    interval: 5s  # More frequent metrics for canary

---
# NetworkPolicy: Only allow backend services to call api
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api  # All api Pods (stable + canary)
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web-frontend  # Only allow from web frontend
    ports:
    - protocol: TCP
      port: 8080
```

---

### ASCII Diagrams

#### Diagram 1: Label-Based Service Discovery Flow

```
┌──────────────────────────────────────────────┐
│  Pod: web-frontend (wants to reach api service)          │
│                                                         │
│  DNS Query: api.production.svc.cluster.local            │
└──────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│  CoreDNS (Kubernetes DNS service)                       │
│  Resolves: api.production.svc.cluster.local             │
│  → Returns: <Service ClusterIP>                         │
└──────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│  Service Controller (watching for Pods)                 │
│                                                         │
│  Query: "Find all Pods where app=api"                   │
│  (Uses label selector from Service spec)               │
└──────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│  etcd (searches label index)                            │
│                                                         │
│  Found Pods matching app=api:                           │
│  ├─ Pod: api-stable-1-abc123                           │
│  │  └─ labels: {app: api, version: v2.1.0, ...}   │
│  ├─ Pod: api-stable-2-def456                           │
│  │  └─ labels: {app: api, version: v2.1.0, ...}   │
│  ├─ Pod: api-stable-3-ghi789                           │
│  │  └─ labels: {app: api, version: v2.1.0, ...}   │
│  ├─ Pod: api-canary-1-jkl012                            │
│  │  └─ labels: {app: api, version: v3.0.0, ...}   │
└──────────────────────────────────────────────┘
        │
        │ Results returned to Service Controller
        ▼
┌──────────────────────────────────────────────┐
│  Service spec.clusterIP = 10.0.0.100                    │
│                                                         │
│  Endpoints (maintained by Service Controller):          │
│  10.1.1.10:8080  (api-stable-1)                         │
│  10.1.2.10:8080  (api-stable-2)                         │
│  10.1.3.10:8080  (api-stable-3)                         │
│  10.1.4.10:8080  (api-canary-1)                         │
│                                                         │
│  ┃ Any Pods removed? Their IP removed from endpoints │
│  ┃ Any Pods added? Their IP added to endpoints       │
└──────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│  kube-proxy (on each node)                              │
│  Programs iptables/ipvs rules:                          │
│                                                         │
│  If packet destined for 10.0.0.100:80                   │
│  └─ DNAT to one of the endpoints (round-robin)        │
│      10.1.1.10:8080, 10.1.2.10:8080, ...              │
└──────────────────────────────────────────────┘
        │
        ▼
┌──────────────────────────────────────────────┐
│  Web Frontend Pod receives traffic delivered to api    │
│  via load-balanced endpoint (stable or canary)          │
│                                                         │
│  └─ All without hardcoding IP addresses                │
│  └─ All dynamic based on label selectors              │
└──────────────────────────────────────────────┘
```

---

## Annotations and Metadata

### Textual Deep Dive

#### Internal Working Mechanism

Annotations are key-value pairs that are **NOT indexed and NOT queryable** by the API server. They are used for:
- Tool-specific data (that other users don't need to query)
- Metadata that tools inject at runtime
- Documentation strings
- Integration with external systems

```
Object in etcd:
{
  "metadata": {
    "name": "payment-api",
    "labels": {              # ✓ Indexed by server, queryable
      "app": "payment-api"
    },
    "annotations": {         # ✗ NOT indexed, NOT queryable
      "prometheus.io/scrape": "true",
      "description": "Payment transaction processor",
      "runbook": "https://wiki.example.com/runbooks/payment-api",
      "slack-channel": "#payments-team"
    }
  }
}
       │
       │ kubectl get pods -l app=payment-api   ✔ Works (labels indexed)
       │ kubectl get pods -l prometheus.io/scrape=true  ✗ Fails
       │                                      (not a label, it's annotation)
```

#### Metadata Fields Beyond Labels

Kubernetes objects have several metadata categories:

```
metadata:
  ┌─ Identity Fields (immutable after creation)
  ├─ name: string (unique within namespace)
  ├─ namespace: string (logical isolation)
  ├─ uid: UUID (globally unique)
  │
  ├─ Generation Fields (tracking object mutations)
  │  ├─ generation: integer (incremented on spec changes)
  │  ├─ observedGeneration: integer (tracked by controllers)
  │  └─ resourceVersion: string (for optimistic locking)
  │
  ├─ Owner References (garbage collection)
  │  ├─ ownerReferences[].kind = Deployment
  │  ├─ ownerReferences[].name = api-server
  │  └─ ownerReferences[].uid = 12345
  │
  ├─ Time Fields (for history and tracking)
  │  ├─ creationTimestamp: RFC3339 (immutable)
  │  └─ deletionTimestamp: RFC3339 (set when deletion starts)
  │
  ├─ Deletion Fields (graceful shutdown)
  │  ├─ deletionGracePeriodSeconds: integer (how long before force-delete)
  │  └─ finalizers: list (cleanup tasks before object removed from etcd)
  │
  ├─ Query and Filtering
  │  ├─ labels: map (queryable by label selectors)
  │  └─ annotations: map (not queryable, tool metadata)
  │
  ├─ Managed Fields (server-side apply tracking)
  │  ├─ managedFields[].manager: string (who last modified)
  │  ├─ managedFields[].time: RFC3339
  │  └─ managedFields[].fieldsV1: object (field ownership)
  │
  └─ Finalizers (soft-delete mechanism)
     └─ Prevents object deletion until finalizers cleared
```

#### Architecture Role

Metadata serves as the **operational backbone** of Kubernetes objects:

1. **Object Identity:** `name` + `namespace` uniquely identifies an object
2. **Change Tracking:** `generation` and `observedGeneration` track spec mutations
3. **Lifecycle Management:** `ownerReferences` enable automatic cleanup
4. **Tool Integration:** Annotations allow external tools to store data
5. **Multi-Tenancy:** `namespace` provides logical isolation
6. **Auditability:** `creationTimestamp`, `deletionTimestamp` for compliance
7. **Concurrency Control:** `resourceVersion` prevents conflicting updates

#### Production Usage Patterns

**Pattern 1: Tool-Specific Annotations**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  annotations:
    # Prometheus metrics collection
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    
    # Fluentd log aggregation
    fluentd.io/parse: json
    fluentd.io/exclude_logs: healthz,ready
    
    # OPA/Gatekeeper policy reference
    policies.gatekeeper.sh/constraints: |-
      K8sRequiredLabels,K8sRequiredAnnotations
    
    # Istio sidecar injection
    sidecar.istio.io/inject: "true"
    
    # Cert-manager certificate
    cert-manager.io/cluster-issuer: letsencrypt-prod
    
    # Custom business logic
    deployment.example.com/cost-center: engineering
    deployment.example.com/sla-tier: premium
    deployment.example.com/data-classification: confidential
    
    # Documentation
    description: "API server handling payment transactions"
    runbook: "https://wiki.example.com/runbooks/api-server"
    slack-channel: "#payments-team"
    owner-email: "api-team@example.com"
    oncall-schedule: "https://pagerduty.example.com/schedules/api-server"
```

**Pattern 2: Finalizers for Cleanup Before Deletion**

```yaml
# Deployment with finalizers
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  finalizers:
  - custom-finalizer.example.com/cleanup-databases  # Prevents deletion
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: api
        image: myapi:v2.1.0

---
# Custom controller watches for deletions
# When deletion starts (deletionTimestamp != null):
# 1. Wait for all Pod connections to drain (graceful shutdown)
# 2. Run database cleanup (DELETE FROM sessions WHERE ...)
# 3. Notify external load balancers
# 4. Remove finalizer from object
# 5. Object is then deleted from etcd

# If something goes wrong (can't reach DB):
# Controller cannot remove finalizer
# Deployment is stuck in Terminating state indefinitely
# Requires manual intervention: kubectl patch deployment ... --type json -p='[{"op": "remove", "path": "/metadata/finalizers"}]'
```

**Pattern 3: Owner References for Hierarchical Cleanup**

```yaml
# Parent: Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  uid: 12345-abc-67890

---
# Child: ReplicaSet (automatically created by Deployment)
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: api-server-abc123
  ownerReferences:  # Set by Deployment Controller
  - apiVersion: apps/v1
    kind: Deployment
    name: api-server
    uid: 12345-abc-67890
    controller: true  # This owner "controls" the object
    blockOwnerDeletion: true  # Prevent deletion before owner

---
# Child's child: Pods
apiVersion: v1
kind: Pod
metadata:
  name: api-server-abc123-xxxxx
  ownerReferences:
  - apiVersion: apps/v1
    kind: ReplicaSet
    name: api-server-abc123
    uid: 54321-def-98765
    controller: true
    blockOwnerDeletion: true

# Deletion flow:
# kubectl delete deployment api-server
#   │
#   ▼ Deployment deleted
#   ├─ Find all objects with ownerReferences to this Deployment
#   ├─ ReplicaSet api-server-abc123 has owner reference
#   ├─ Delete ReplicaSet
#   │  └─ Find all Pods with ownerReferences to this ReplicaSet
#   │     └─ Pods api-server-abc123-xxxxx deleted
#   └─ Deletion cascades automatically
#      (No orphaned objects left behind)
```

#### DevOps Best Practices

**1. Use resourceVersion  for Optimistic Locking (Conflict Detection)**

```bash
# Scenario: Two controllers updating the same object

# Controller A reads object
kubectl get deployment api-server -o json | jq .metadata.resourceVersion
# Output: "12345"

# Controller B reads object
kubectl get deployment api-server -o json | jq .metadata.resourceVersion
# Output: "12345"

# Controller A patches (changes replicas: 3 -> 5)
kubectl patch deployment api-server --type merge \
  -p '{"metadata":{"resourceVersion":"12345"},"spec":{"replicas":5}}'
# Success, object updated

# Server increments resourceVersion to "12346"

# Controller B tries to patch (changes replicas: 3 -> 10)
kubectl patch deployment api-server --type merge \
  -p '{"metadata":{"resourceVersion":"12345"},"spec":{"replicas":10}}'
# ERROR: Conflict detected (resourceVersion mismatch)
# Controller B must re-read object, apply patch to new version
# Final state: replicas=10 (later update wins)
```

**2. Document with Runbooks and Team Info in Annotations**

✅ **Pattern:**
```yaml
metadata:
  annotations:
    # Documentation links
    runbook: "https://wiki.example.com/runbooks/payment-api"
    incident-response-guide: "https://wiki.example.com/guides/payment-api-outage"
    architectural-diagram: "https://miro.com/app/board/payment-api-architecture"
    
    # Team information
    owner-team: "payments-team"
    owner-slack: "https://slack.example.com/#payments-team"
    owner-email: "payments-team@example.com"
    oncall-schedule: "https://pagerduty.example.com/schedules/payments"
    
    # SLO information
    slo-availability: "99.99%"
    slo-latency-p99: "200ms"
    rppo: "recovery-point-objective: 5 minutes"
    rto: "recovery-time-objective: 15 minutes"
    
    # Security and compliance
    data-classification: "confidential"
    pii-processed: "true"
    pci-scope: "true"
    encryption-in-transit: "tls-1.3"
    encryption-at-rest: "aws-kms"
```

Tools can extract these programmatically:
```python
# Python controller reading annotations
import kopf

@kopf.on.event('apps', 'v1', 'deployments')
def handle_deployment(event, **kwargs):
    obj = event['object']
    annotations = obj['metadata'].get('annotations', {})
    
    owner_team = annotations.get('owner-team')
    runbook_url = annotations.get('runbook')
    slo_latency = annotations.get('slo-latency-p99')
    
    if owner_team:
        send_notification(f"Deployment {obj['metadata']['name']} \
                          owned by {owner_team}")
```

**3. Use managedFields to Track Field Ownership (Server-Side Apply)**

```yaml
# When using server-side apply
kubectl apply -f deployment.yaml --server-side --field-manager=terraform

# Result in object.metadata.managedFields:
managedFields:
- manager: terraform             # Terraform manages certain fields
  operation: Apply
  time: 2026-03-10T15:00:00Z
  fieldsV1:
    f:spec:
      f:replicas: {}            # Terraform owns 'replicas' field
      f:selector: {}
      f:template: {}
- manager: prometheus-operator   # Prometheus operator manages other fields
  operation: Update
  time: 2026-03-10T15:05:00Z
  fieldsV1:
    f:metadata:
      f:annotations:
        f:prometheus.io/scrape: {}

# Benefit: Multiple controllers can manage non-conflicting fields
# Terraform controls replicas, Prometheus operator adds monitoring annotations
# No conflicts, no field ownership wars
```

#### Common Pitfalls

**Pitfall 1: Storing Queryable Data in Annotations**

❌ **Problem:**
```yaml
metadata:
  annotations:
    team: backend              # ❌ Stored in annotation (not queryable)
    environment: production    # ❌ Stored in annotation (not queryable)

# Try to query:
kubectl get deployments -l team=backend
# ERROR: team is not a label
```

✅ **Solution:**
```yaml
metadata:
  labels:         # Use labels for queryable metadata
    team: backend  # ✅ Queryable
    environment: production
  annotations:    # Use annotations for tool-specific data
    runbook: "https://wiki.example.com/runbooks/api"
    slo-tier: "premium"
```

**Pitfall 2: Forgetting to Handle Finalizers in Deletion**

❌ **Problem:**
```yaml
metadata:
  finalizers:
  - custom-cleanup.example.com/database-connections

# Delete the object
kubectl delete deployment api-server
# Object stuck in Terminating state
# Because the finalizer controller crashed and never removed the finalizer
# Now: stuck forever, can't clean up
```

✅ **Solution:**
1. Design finalizers to be idempotent (safe to run multiple times)
2. Implement exponential backoff (don't crash loop)
3. Add timeout (if cleanup takes > 5 minutes, give up and remove finalizer)
4. Monitor finalizer queue for stuck objects

```python
import kopf
import asyncio

@kopf.on.delete('apps', 'v1', 'deployments',
                annotations={'cleanup-databases': 'true'})
async def cleanup_deployment(name, namespace, **kwargs):
    try:
        # Cleanup logic
        await drain_database_connections(name, namespace)
        await delete_records_in_db(name, namespace)
        print(f"Cleanup complete for {name}")
    except Exception as e:
        # Log error but don't re-raise
        # Try again on next reconciliation
        print(f"Cleanup failed: {e}, will retry...")
        await asyncio.sleep(5)  # Back off before retry
        raise kopf.TemporaryError(f"Cleanup failed: {e}", delay=60)
```

**Pitfall 3: Assuming Annotations Persist Across Updates**

❌ **Problem:**
```bash
# Add annotation
kubectl annotate deployment api-server custom-key="custom-value"

# Update deployment via kubectl apply (from manifest without annotation)
kubectl apply -f deployment.yaml

# Result: Annotation is REMOVED (not in manifest)
# Because kubectl apply follows "manifest is source of truth"
```

✅ **Solution:**
Include annotations in manifests if you want them to persist:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  annotations:
    custom-key: "custom-value"  # In manifest, persists
spec:
  replicas: 3
```

Or use server-side apply (which respects unmanaged fields):
```bash
kubectl annotate deployment api-server custom-key="custom-value" —-overwrite
kubectl apply -f deployment.yaml --server-side
# Annotation preserved because terraform doesn't manage it
```

---

### Practical Code Examples

#### Example 1: Complete Metadata Structure with all Fields

```yaml
apiVersion: v1
kind: Pod
metadata:
  # Identity (immutable)
  name: api-server-abc123
  namespace: production
  uid: 12345-67890-abcde-fghij  # Globally unique identifier
  
  # Self link (deprecated, but informational)
  selfLink: /api/v1/namespaces/production/pods/api-server-abc123
  
  # Resource version for optimistic locking
  resourceVersion: "987654"  # Incremented on every change
  generation: 2              # Incremented when spec changes
  
  # Owner references (for garbage collection)
  ownerReferences:
  - apiVersion: apps/v1
    kind: Deployment
    name: api-server
    uid: 11111-22222-33333-44444
    controller: true          # This owner controls the Pod
    blockOwnerDeletion: true  # Don't delete if owner exists
  
  # Timestamps
  creationTimestamp: "2026-01-15T10:00:00Z"
  deletionTimestamp: null  # Set when deletion begins
  deletionGracePeriodSeconds: 30  # How long before force-delete
  
  # Finalizers (soft delete mechanism)
  finalizers:
  - custom-controller.example.com/cleanup
  # Before etcd deletion:
  # 1. deletionTimestamp set
  # 2. Controllers process deletionTimestamp
  # 3. Controllers remove finalizers
  # 4. When all finalizers removed, object deleted from etcd
  
  # Query and filter metadata
  labels:
    app: api-server
    version: v2.1.0
    environment: production
    team: backend
    tier: application
  
  annotations:
    # Monitoring
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    
    # Service mesh
    sidecar.istio.io/inject: "true"
    
    # Documentation
    description: "API server handling payment transactions"
    runbook: "https://wiki.example.com/runbooks/api-server"
    
    # Team info
    owner-team: "payments-team"
    owner-slack: "#payments-team"
    owner-email: "payments@example.com"
    
    # SLO
    slo-availability: "99.95%"
    slo-latency-p99: "500ms"
    
    # Backup
    backup-enabled: "true"
    backup-frequency: "daily"
    
    # Custom business logic
    cost-center: "payments"
    data-classification: "confidential"
    pci-scope: "true"
  
  # Managed fields (server-side apply)
  managedFields:
  - manager: kubectl
    operation: Apply
    apiVersion: v1
    time: "2026-01-15T10:00:00Z"
    fieldsV1:
      f:metadata:
        f:labels:
          f:app: {}
      f:spec:
        f:containers:
          k:{"name":"api"}:
            f:image: {}
            f:ports: {}
  
  - manager: prometheus-operator
    operation: Update
    apiVersion: v1
    time: "2026-01-15T10:05:00Z"
    fieldsV1:
      f:metadata:
        f:annotations:
          f:prometheus.io/scrape: {}

spec:
  containers:
  - name: api
    image: myapi:v2.1.0
    ports:
    - containerPort: 8080
      name: http
    - containerPort: 9090
      name: metrics

status:
  phase: Running
  conditions:
  - type: Initialized
    status: "True"
    lastProbeTime: null
    lastTransitionTime: "2026-01-15T10:00:05Z"
  - type: Ready
    status: "True"
    lastProbeTime: null
    lastTransitionTime: "2026-01-15T10:00:05Z"
  containerStatuses:
  - name: api
    ready: true
    restartCount: 0
    state:
      running:
        startedAt: "2026-01-15T10:00:05Z"
```

---

### ASCII Diagrams

#### Diagram 1: Lifecycle of Deletion with Finalizers

```
1. NORMAL STATE (Object exists, no deletion)

┌─────────────────────────────────┐
│  Deployment: api-server                      │
│  metadata:                                   │
│    finalizers:                               │
│    - cleanup.example.com/database            │
│    deletionTimestamp: null                   │
│                                              │
│  Status: ACTIVE                              │
└─────────────────────────────────┘

│
│ User: kubectl delete deployment api-server
│
▼

2. DELETION INITIATED (graceful shutdown)

┌─────────────────────────────────┐
│  Deployment: api-server                      │
│  metadata:                                   │
│    finalizers:                               │
│    - cleanup.example.com/database            │
│    deletionTimestamp: 2026-03-10T15:00:00Z   │  ← SET BY SERVER
│    deletionGracePeriodSeconds: 30            │
│                                              │
│  Status: TERMINATING                         │
│    │
│    └─ Cannot delete yet (has finalizers)       │
└─────────────────────────────────┘

│
│ Controllers watching for deletionTimestamp
│ │
│ ├─ cleanup.example.com/database controller
│ │  │
│ │  ▼ (wakes up, sees deletionTimestamp set)
│ │
│ │  "Deployment is being deleted"
│ │  "I need to drain database connections"
│ │  "I need to run cleanup scripts"
│ │
│ ┃
│ ▼

3. CLEANUP IN PROGRESS

┌─────────────────────────────────┐
│  Cleanup Controller Tasks:                    │
│  ✓ Drain active requests (wait 2 sec)        │
│  ✓ Commit pending transactions (wait 1 sec)  │
│  ✓ Close DB connections gracefully           │
│  ⏳ Delete DB records (in progress)            │
│                                              │
│  Deployment still in TERMINATING state       │
└─────────────────────────────────┘

│
│ 5 seconds later...
│
▼

4. CLEANUP COMPLETE

┌─────────────────────────────────┐
│  Cleanup Controller:                          │
│  ✓ All tasks complete                         │
│  ✂ Remove finalizer from object                │
│                                              │
│  kubectl patch deployment api-server \       │
│   --type json -p='[{                         │
│     "op": "remove",                           │
│     "path": "/metadata/finalizers/0"          │
│   }]'                                         │
└─────────────────────────────────┘

│
│ Finalizers list is now empty []
│
▼

5. FINAL DELETION (from etcd)

┌─────────────────────────────────┐
│  API Server:                                  │
│  ┃                                           │
│  ┃ "All finalizers removed"                  │
│  ⌃                                           │
│  │ Delete object from etcd                    │
│  ▼                                           │
│                                              │
│  Object no longer exists in cluster          │
│  kubectl get deployment api-server           │
│  # Error: not found                          │
└─────────────────────────────────┘


WHAT IF CLEANUP FAILS?

3b. CLEANUP FAILED
┌─────────────────────────────────┐
│  Cleanup Controller Error:                    │
│  ✗ Cannot reach database                     │
│  ✗ Cannot delete records                     │
│  ✗ Operation times out                        │
│                                              │
│  Controller retries cleanup                   │
│  Finalizer still present                     │
│  Object stays in TERMINATING state           │
│                                              │
│  "Stuck forever" (requires manual fix)      │
└─────────────────────────────────┘

│
│ Manual intervention required:
│ kubectl patch deployment api-server --type json -p='[
│   {"op": "remove", "path": "/metadata/finalizers/0"}
│ ]'
│ 
│ WARNING: Database cleanup didn't happen!
│ You may have orphaned records.
│
```

---

## Hands-on Scenarios

### Scenario 1: Troubleshooting a "Stuck" Deployment

**Situation:** Your production `payment-api` Deployment shows:
```bash
$ kubectl get deployment payment-api -n production
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
payment-api   0/3     0            0           5m

$ kubectl describe deployment payment-api
...
Conditions:
  Type             Status  Reason
  ----             ------  ------
  Progressing      False   NewReplicaSetAvailable

ReplicaSets:
  payment-api-abc123   0         3         0        5m
  payment-api-def456   3         3         3        1h

$ kubectl get rs payment-api-abc123 -o yaml | grep -A5 conditions
```

**Your Investigation Steps (as a senior engineer):**

1. **Check ReplicaSet status** (the object between Deployment and Pod):
```bash
kubectl get rs payment-api-abc123 -n production -o yaml | tail -50
# Look for:
#   status.condition[].message = "unable to create pods"
#   Reason: "FailedCreate"
```

2. **Examine Pod events** (why Pods can't start):
```bash
kubectl describe pod payment-api-abc123-xxxxx -n production
# Look in Events section:
#   Type: Warning
#   Reason: FailedScheduling
#   Message: "0/10 nodes are available: 10 Insufficient memory"
```

3. **Analyze the root cause** (three possibilities):

**Root Cause A: Image Pull Error**
```bash
kubectl get pods -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].state}{"\n"}{end}'
# Output might show:
# payment-api-abc123-xxxxx   {"waiting":{"reason":"ImagePullBackOff","message":"..."}}

# Fix: Check image registry credentials
kubectl get secrets -n production
kubectl describe secret <image-pull-secret>
```

**Root Cause B: Resource Constraints**
```bash
# Check node capacity
kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(Mi)   MEMORY%
node-1     3950m        99%    7500Mi       99%
node-2     3800m        95%    7200Mi       98%
node-3     2100m        53%    5000Mi       62%

# Pod needs: requests.memory: 512Mi
# All nodes are full!
# Fix: Scale cluster or reduce Pod requests
kubectl edit deployment payment-api -n production
# Change: requests.memory: 512Mi -> 256Mi
# (Or add more nodes)
```

**Root Cause C: Spec Error**
```bash
# Deployment created with typo in selector
kubectl get deployment payment-api -n production -o yaml | grep -A3 selector
  selector:
    matchLabels:
      app: payment-api
      version: v2.0.0

# Pod template has different labels
kubectl get deployment payment-api -n production -o yaml | grep -A3 "labels:"
  labels:
    app: payment-api
    version: v2.0.0-rc1  # MISMATCH!

# Fix: Update template labels to match selector
kubectl patch deployment payment-api -n production -p '{"spec":{"template":{"metadata":{"labels":{"version":"v2.0.0"}}}}}'
```

**Validation Commands (verify fix):**
```bash
# Watch rollout progress
kubectl rollout status deployment/payment-api -n production

# Confirm Pods are running
kubectl get pods -n production -l app=payment-api

# Verify new ReplicaSet is active
kubectl get rs -n production -l app=payment-api
```

---

### Scenario 2: Implementing a Zero-Downtime Deployment

**Goal:** Deploy a new version (`v3.0.0`) of an API currently running v2.1.0 without losing a single request.

**Architecture Before:**
```
┌─────────────────────────────────────────────┐
│  Service: api (ClusterIP 10.0.0.50)         │
│  Selector: app=api                          │
└────────────────┬──────────────────────────┘
                 │
      ┌──────────┼──────────┐
      │          │          │
   Pod-1      Pod-2      Pod-3
 (v2.1.0)   (v2.1.0)   (v2.1.0)
 Running    Running    Running
```

**Step 1: Create the Deployment with readiness/liveness probes (already in manifest)**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1      # Allow 1 extra Pod during rollout
      maxUnavailable: 0  # ZERO downtime: all Pods always available
  template:
    spec:
      containers:
      - name: api
        image: myapi:v3.0.0
        readinessProbe:  # Determines if Pod should receive traffic
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        livenessProbe:   # Determines if Pod is alive (restart if fails)
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

**Step 2: Execute the deployment**
```bash
kubectl apply -f api-deployment.yaml

# Watch real-time progress
kubectl rollout status deployment/api --watch
```

**What Kubernetes does automatically:**
```
Time T=0s: Desired: 3 (v2.1.0), Actual: 3 (v2.1.0)
            Service still routes to 3 Pods
            No traffic loss

Time T=5s: Create new Pod (v3.0.0) on best-fit node
           Deployment: desired: 3+1=4, actual: 3+1=4
           new-Pod-1: status=Pending (container starting)
           Service: still routes to 3 v2.1.0 Pods

Time T=15s: new-Pod-1 passes readiness probe
            new-Pod-1: status=Running, Ready=True
            Service updates endpoints: now routes to 3 v2.1.0 + 1 v3.0.0
            4 Pods receiving traffic
            Traffic distributed 75% v2.1.0, 25% v3.0.0 (proportional)

Time T=20s: Delete one v2.1.0 Pod (old-Pod-1)
            Deployment ensures: actual-count = desired-count
            new-Pod-2 starts simultaneously (maxSurge=1)
            Service endpoints: 2 v2.1.0 + 2 v3.0.0
            Traffic now 50/50

Time T=30s: old-Pod-2 gracefully shuts down (30s grace period)
            new-Pod-2 passes readiness
            Service: 1 v2.1.0 + 3 v3.0.0
            Traffic 25/75

Time T=40s: old-Pod-3 deleted, new-Pod-3 running and ready
            Service: 0 v2.1.0 + 3 v3.0.0
            Rollout complete

Throughout:
- Readiness probes control when traffic goes to new Pods
- If v3.0.0 fails health check: doesn't receive traffic (reverts to v2.1.0)
- No unavailable Pods at any point (maxUnavailable: 0)
- No dropped connections (grace period for draining)
```

**Monitoring the rollout:**
```bash
# Terminal 1: Watch Deployment
kubectl get deployment api --watch
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
api    3/3     2            3           0s
api    3/3     3            3           5s  # All new Pods ready

# Terminal 2: Watch Pods (version distribution)
watch 'kubectl get pods -l app=api -o wide | awk "{print \$1, \$3}"'
api-abc-xxxxx        myapi:v2.1.0
api-abc-yyyyy        myapi:v2.1.0
api-abc-zzzzz        myapi:v2.1.0
---
api-def-aaaaa        myapi:v3.0.0  # New version appearing
api-abc-xxxxx        myapi:v2.1.0  # Old version being removed
api-abc-yyyyy        myapi:v2.1.0
---
api-def-aaaaa        myapi:v3.0.0
api-def-bbbbb        myapi:v3.0.0
api-abc-zzzzz        myapi:v2.1.0  # Last old Pod
---
api-def-aaaaa        myapi:v3.0.0
api-def-bbbbb        myapi:v3.0.0
api-def-ccccc        myapi:v3.0.0   # All new version

# Terminal 3: Monitor traffic and errors from application
kubectl logs -l app=api -n production --tail=20 --all-containers -f
# Watch for any error spikes during rollout
# If v3.0.0 causes errors: readiness probe fails, traffic stops going to it
```

**Rollback if needed:**
```bash
# If v3.0.0 has bugs, rollback is just one command
kubectl rollout undo deployment/api
# Kubernetes immediately starts rolling back:
# - New Pods with v2.1.0 created
# - v3.0.0 Pods removed (in reverse order)
# - Service continues receiving traffic (zero downtime)
```

---

### Scenario 3: Debugging Label Selector Mismatches

**Problem:** You updated a Deployment, but Pods aren't being created.

**Manifest Applied:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:  # Selector specifies which Pods this Deployment owns
    matchLabels:
      app: web
      environment: production
  template:
    metadata:
      labels:
        app: web
        # BUG: Missing environment label!
```

**Debugging:**
```bash
# Step 1: Check Deployment status
$ kubectl describe deployment web
Conditions:
  Type             Status  Reason
  ----             ------  ------
  Available        False   MinimumReplicasUnavailable
  Progressing      False   NewReplicaSetAvailable

ReplicaSets:
  web-abc123   0   3   0   5m  (Can't create Pods)

# Step 2: Check ReplicaSet (owns Pods)
$ kubectl describe rs web-abc123
Status:
  Replicas: Desired: 3, Actual: 0, Ready: 0, Updated: 0

# Step 3: Find the root cause - check Pod template labels
$ kubectl get deployment web -o yaml | grep -A10 "template:"
template:
  metadata:
    labels:
      app: web              # Label present
      # environment missing!

# Step 4: Compare with selector
$ kubectl get deployment web -o yaml | grep -A3 "selector:"
selector:
  matchLabels:
    app: web
    environment: production  # Selector expects this!

# The mismatch:
# Selector expects: {app: web, environment: production}
# Pods have:       {app: web}
# Result: Pods don't match selector, not owned by Deployment
```

**Fix and Verify:**
```bash
# Option 1: Update manifest and reapply
vim deployment.yaml
# Add missing label under template.metadata.labels
kubectl apply -f deployment.yaml

# Option 2: Patch on the fly
kubectl patch deployment web --type merge -p '
spec:
  template:
    metadata:
      labels:
        environment: production
'

# Verify fix
$ kubectl get pods -l app=web,environment=production
NAME                 READY   STATUS    RESTARTS   AGE
web-abc123-xxxxx     1/1     Running   0          1s
web-abc123-yyyyy     1/1     Running   0          1s
web-abc123-zzzzz     1/1     Running   0          1s

# Verify Deployment now shows Pods
$ kubectl get deployment web
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
web    3/3     3            3           1m
```

---

### Scenario 4: Cross-Namespace Service Discovery with Labels

**Challenge:** Your `web-frontend` Pod in the `default` namespace needs to call `api-server` in the `production` namespace.

**Setup:**
```bash
# api-server running in production namespace
kubectl get pods -n production -l app=api-server
NAME                  READY   STATUS    RESTARTS   AGE
api-server-abc-xxxxx  1/1     Running   0          2h
api-server-abc-yyyyy  1/1     Running   0          2h
api-server-abc-zzzzz  1/1     Running   0          2h

# web-frontend running in default namespace
kubectl get pods -l app=web-frontend
NAME                    READY   STATUS    RESTARTS   AGE
web-frontend-123-aaaaa  1/1     Running   0          1h
```

**Service in production namespace:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-server
  namespace: production
spec:
  selector:
    app: api-server  # Selects Pods in same namespace
  ports:
  - port: 80
    targetPort: 8080
```

**How web-frontend discovers api-server:**

```bash
# DNS name for cross-namespace service:
# api-server.production.svc.cluster.local

# Inside web-frontend Pod
$ curl http://api-server.production.svc.cluster.local

# DNS resolution:
# coredns sees: api-server.production.svc Cluster.local
# Looks up service in production namespace
# Finds Service with selector: app=api-server
# Returns all Pod IPs matching that selector
# Returns ClusterIP as virtual endpoint

# kube-proxy on all nodes maintains iptables rules:
# If packet destination = api-server.production.svc IP
# -> DNAT to one of the Pod IPs (round-robin)
```

**NetworkPolicy scenario (restrict access):**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-server-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api-server  # Protects api-server Pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: default  # Allow from pods in default namespace
      podSelector:
        matchLabels:
          app: web-frontend  # Specifically from web-frontend
    ports:
    - protocol: TCP
      port: 8080
```

**Script to verify label-based connectivity:**
```bash
#!/bin/bash
# verify-cross-namespace-labels.sh

# 1. Check Service exists and has correct selector
echo "=== Service Configuration ==="
kubectl get svc -n production api-server -o jsonpath='{.spec.selector}'
# Expected: {"app":"api-server"}

# 2. Find all Pods matching Service selector
echo "\n=== Backing Pods ==="
kubectl get pods -n production -l app=api-server

# 3. Check Service endpoints (selected Pods)
echo "\n=== Service Endpoints ==="
kubectl get endpoints -n production api-server
# Should list all api-server Pod IPs

# 4. Verify cross-namespace DNS works
echo "\n=== DNS Resolution Test ==="
kubectl run -it --rm debug --image=busybox --restart=Never -n default -- \
  nslookup api-server.production.svc.cluster.local

# 5. Test curl to service (from default namespace)
echo "\n=== Network Connectivity Test ==="
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -n default -- \
  curl -v http://api-server.production.svc.cluster.local

# 6. Check if NetworkPolicy blocks the request
if [ $? -ne 0 ]; then
    echo "Connection failed - checking NetworkPolicy..."
    kubectl get networkpolicy -n production
fi
```

---

---

### Scenario 5: Multi-Region High Availability and Failover

**Situation:** Your organization runs a critical e-commerce platform across AWS us-east-1 and us-west-2 regions with independent Kubernetes clusters. Each cluster runs the same Deployment manifests, but traffic should automatically shift during regional outages. Currently:

```bash
$ kubectl --context=us-east1 get pods -l app=checkout-service
NAME                        READY   STATUS    RESTARTS   AGE
checkout-service-xyzab      1/1     Running   0          3d
checkout-service-plmno      1/1     Running   0          3d

$ kubectl --context=us-west2 get pods -l app=checkout-service  
NAME                        READY   STATUS    RESTARTS   AGE
checkout-service-qwert      1/1     Running   0          3d
checkout-service-asdfg      1/1     Running   0          3d

# But during a us-east-1 outage:
$ curl https://api.example.com/health
# 60 second timeout, then fail over
```

**Architecture Challenge:** You're using DNS failover (TTL 30s) but traffic is still routing to the dead region. Developers ask: "Why don't labels automatically shift traffic between regions?"

**Senior DevOps Analysis:**

Labels are **intra-cluster only** - Service selectors only match Pods in the **same Kubernetes cluster**. Multi-region failover requires a different pattern:

1. **Label Strategy per Region:**
```yaml
# us-east-1/checkout-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service
  namespace: production
  labels:
    app: checkout-service
    region: us-east-1              # CRITICAL: Region label
    failover-group: checkout-ha    # Logical grouping
  annotations:
    ha.example.com/active-region: "us-east-1"
    ha.example.com/standby-region: "us-west-2"
spec:
  replicas: 2
  selector:
    matchLabels:
      app: checkout-service
  template:
    metadata:
      labels:
        app: checkout-service
        region: us-east-1              # Pod inherits region label
        version: "v2.14.0"
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: topology.kubernetes.io/region
                operator: In
                values:
                - us-east-1              # Pin to region
      containers:
      - name: checkout
        image: checkout:v2.14.0
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 5
          failureThreshold: 2          # Fail fast on region outage
```

2. **Global Service Entry Point (Central DNS/API Gateway):**
```yaml
# global-loadbalancer.yaml (deployed in both regions, federated DNS)
apiVersion: v1
kind: ConfigMap
metadata:
  name: region-health-status
  namespace: production
  labels:
    app: checkout-service
    failover-group: checkout-ha
data:
  # Updated by external health check controller
  us-east-1: "healthy"     # or "unhealthy" / "degraded"
  us-west-2: "healthy"
---
apiVersion: v1
kind: Endpoints
metadata:
  name: checkout-service-global
  namespace: production
  labels:
    app: checkout-service
    scope: global
subsets:
  # Endpoints are manually managed by health-check controller
  - name: us-east-1
    addresses:
    - ip: 10.0.1.25      # Load balancer IP of us-east-1 service
      targetRef:
        kind: Node
        name: us-east-1-node
      nodeName: us-east-1-node
    ports:
    - port: 443
      protocol: TCP
  - name: us-west-2
    addresses:
    - ip: 10.1.1.30      # Load balancer IP of us-west-2 service
      targetRef:
        kind: Node
        name: us-west-2-node
      nodeName: us-west-2-node
    ports:
    - port: 443
      protocol: TCP
```

3. **External Health Check Controller (Manages Failover):**
```python
#!/usr/bin/env python3
# failover-controller.py - runs in central namespace

import os
import time
import requests
from kubernetes import client, config, watch
from datetime import datetime

config.load_incluster_config()
v1 = client.CoreV1Api()

REGIONS = {
    'us-east-1': 'https://checkout-us-east1.internal:443/health',
    'us-west-2': 'https://checkout-us-west2.internal:443/health'
}

while True:
    health_status = {}
    
    # 1. Health check each region
    for region, health_url in REGIONS.items():
        try:
            resp = requests.get(health_url, timeout=3)
            status = 'healthy' if resp.status_code == 200 else 'unhealthy'
        except Exception as e:
            status = 'unhealthy'
            print(f"Health check failed for {region}: {e}")
        
        health_status[region] = status
    
    # 2. Update ConfigMap with health status
    try:
        cm = v1.read_namespaced_config_map('region-health-status', 'production')
        cm.data = health_status
        v1.patch_namespaced_config_map('region-health-status', 'production', cm)
        print(f"[{datetime.now()}] Updated health: {health_status}")
    except Exception as e:
        print(f"Failed to update ConfigMap: {e}")
    
    # 3. Update Endpoints to point only to healthy regions
    try:
        ep = v1.read_namespaced_endpoints('checkout-service-global', 'production')
        healthy_regions = [r for r, status in health_status.items() if status == 'healthy']
        
        # Update subsets to only include healthy regions
        ep.subsets = [
            s for s in ep.subsets 
            if s.name in healthy_regions or not s.name  # Keep healthy ones
        ]
        
        v1.patch_namespaced_endpoints('checkout-service-global', 'production', ep)
        print(f"Active regions: {healthy_regions}")
    except Exception as e:
        print(f"Failed to update Endpoints: {e}")
    
    time.sleep(10)  # Check every 10s
```

4. **Verification and Failover Test:**
```bash
#!/bin/bash
# test-failover.sh

echo "=== Baseline: Both Regions Healthy ==="
kubectl get configmap region-health-status -n production -o jsonpath='{.data}' | jq .
# Expected: us-east-1: healthy, us-west-2: healthy

echo ""
echo "=== Simulating us-east-1 Outage ==="
# Kill us-east-1 service or network partition
sudo iptables -A OUTPUT -d 10.0.1.25 -j DROP  # Block us-east-1 LB IP

echo "Waiting 10 seconds for health check to detect failure..."
sleep 10

echo ""
echo "=== After Failover ==="
kubectl get configmap region-health-status -n production -o jsonpath='{.data}' | jq .
# Expected: us-east-1: unhealthy, us-west-2: healthy

echo ""
echo "=== Verify Endpoints Now Exclude us-east-1 ==="
kubectl get endpoints checkout-service-global -n production -o yaml | grep -A20 subsets

echo ""
echo "=== Test DNS/LB Routing ==="
curl -v https://api.example.com/checkout
# Should now succeed with us-west-2 Pods

echo ""
echo "=== Restore us-east-1 ==="
sudo iptables -D OUTPUT -d 10.0.1.25 -j DROP
sleep 10

echo ""
echo "=== Verify Both Regions Restored ==="
kubectl get configmap region-health-status -n production -o jsonpath='{.data}' | jq .
```

**Best Practices for HR Design:**
- **Never rely on label selectors for cross-cluster failover** - they only work within a single cluster API server
- **Use external health check controllers** to monitor region health and update central routing
- **Annotate with failover metadata** for operational clarity (ha.example.com/active-region, etc.)
- **Label Pods with region affinity** to understand deployment distribution
- **Test failover in chaos engineering drills** - TTL-based DNS failover introduces 30-300s latency during outages
- **Monitor failover controller health** - if it crashes, traffic doesn't shift
- **Track ownership with finalizers** - multi-region resources need coordinated cleanup

---

### Scenario 6: Configuration Drift Detection and Remediation

**Situation:** Your platform uses GitOps with Flux CD, but operators sometimes manually patch Deployments for hotfixes:

```bash
$ kubectl describe deployment web-app -n production
# Git declared: image: web-app:v1.2.3
# Actual cluster: image: web-app:v1.2.4 (manually patched)

$ kubectl get deployment web-app -n production -o json | jq '.spec.template.spec.containers[0].image'
"web-app:v1.2.4"

# But Git still shows:
$ git show HEAD:deployments/web-app.yaml | grep image:
  image: web-app:v1.2.3

# After 2 hours, Flux resync overwrites the hotfix back to v1.2.3
$ kubectl describe deployment web-app -n production
# 5 minutes later: image is v1.2.3 again (Flux resynced)
```

**Challenge:** How do you detect and prevent drift without breaking legitimate hotfixes?

**Senior DevOps Solution: Drift Detection via Labels and Annotations**

1. **Add Detection Metadata to Manifests:**
```yaml
# web-app-deployment.yaml (in Git)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
  labels:
    app: web-app
    version-control: flux         # Managed by GitOps
    drift-detection: enabled      # Enable drift detection
  annotations:
    gitops.example.com/last-sync-commit: "a1b2c3d" # Flux updates this
    gitops.example.com/drift-detector-threshold: "300" # Seconds
    config.example.com/expected-image: "web-app:v1.2.3"
    config.example.com/sealed: "false"   # Allow emergency updates
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
      env: production
  template:
    metadata:
      labels:
        app: web-app
        env: production
        image-sha256: "sha256:abc123..." # Immutable image hash
      annotations:
        image-timestamp: "2026-03-06T10:30:00Z"
    spec:
      containers:
      - name: web-app
        image: web-app:v1.2.3
        imagePullPolicy: IfNotPresent  # Enforce specificity
```

2. **Drift Detection Controller (Observes and Reports):**
```python
#!/usr/bin/env python3
# drift-detection-controller.py

import time
from kubernetes import client, config, watch
from datetime import datetime
import json

config.load_incluster_config()
apps_v1 = client.AppsV1Api()
annotations_api = client.CoreV1Api()

def check_drift(namespace, deployment_name):
    dep = apps_v1.read_namespaced_deployment(deployment_name, namespace)
    
    # Extract expected state from annotations
    annotations = dep.metadata.annotations or {}
    expected_image = annotations.get('config.example.com/expected-image')
    sealed = annotations.get('config.example.com/sealed', 'false') == 'true'
    
    # Get actual state
    actual_image = dep.spec.template.spec.containers[0].image
    
    # Check for drift
    if actual_image != expected_image and not sealed:
        drift = {
            'timestamp': datetime.now().isoformat(),
            'expected': expected_image,
            'actual': actual_image,
            'sealed': sealed,
            'drifted_by': 'manual_patch'  # or 'admission_webhook', 'external_sync'
        }
        
        print(f"[ALERT] Drift detected in {deployment_name}:")
        print(f"  Expected: {expected_image}")
        print(f"  Actual: {actual_image}")
        print(f"  Sealed: {sealed}")
        
        # Record drift event
        dep.metadata.annotations = annotations or {}
        dep.metadata.annotations['drift.example.com/last-detected'] = datetime.now().isoformat()
        dep.metadata.annotations['drift.example.com/last-drift'] = json.dumps(drift)
        
        apps_v1.patch_namespaced_deployment(deployment_name, namespace, dep)
        
        return True  # Drift detected
    
    return False

while True:
    try:
        deployments = apps_v1.list_namespaced_deployment('production', label_selector='drift-detection=enabled')
        
        for dep in deployments.items:
            if check_drift('production', dep.metadata.name):
                # Create Event for audit trail
                event_name = f"{dep.metadata.name}-drift-{int(time.time())}"
                print(f"Drift event created: {event_name}")
    except Exception as e:
        print(f"Error checking drift: {e}")
    
    time.sleep(30)  # Check every 30s
```

3. **Sealed Mode: Emergency Hotfix Mechanism:**
```bash
#!/bin/bash
# hotfix-with-drift-suppression.sh

# When you need to apply an emergency hotfix:
echo "Applying emergency hotfix to web-app..."

# 1. Seal the deployment (suppress drift detection)
kubectl patch deployment web-app -n production -p \
  '{"metadata":{"annotations":{"config.example.com/sealed":"true"}}}'

echo "Sealed deployment. Drift detection suppressed for 1 hour."

# 2. Apply your hotfix
kubectl set image deployment/web-app web-app=web-app:v1.2.4-hotfix -n production

# 3. Verify hotfix works
kubectl rollout status deployment/web-app -n production

# 4. Document the hotfix
kubectl annotate deployment web-app \
  "drift.example.com/hotfix-reason=critical-cve-fix" \
  "drift.example.com/hotfix-expires=$(date -d '+60 minutes' +%s)" \
  -n production --overwrite

# 5. Unseal after expiration (via automated controller)
echo "Hotfix applied. Sealed until expiration. Flux resync disabled."
```

4. **Verification and Rollback:**
```bash
#!/bin/bash
# verify-drift-detection.sh

echo "=== Check for Drifts ==="
kubectl get deployment -n production -l drift-detection=enabled -o json |\
  jq '.items[] | {name: .metadata.name, expected: .metadata.annotations["config.example.com/expected-image"], actual: .spec.template.spec.containers[0].image}'

echo ""
echo "=== View Drift History ==="
kubectl get deployment web-app -n production -o jsonpath='{.metadata.annotations.drift\.example\.com/last-drift}' | jq .

echo ""
echo "=== Seal Status ==="
kubectl get deployment web-app -n production -o jsonpath='{.metadata.annotations.config\.example\.com/sealed}'

echo ""
echo "=== Auto-Remediate Drift (if unsealed) ==="
EXPECTED=$(kubectl get deployment web-app -n production -o jsonpath='{.metadata.annotations.config\.example\.com/expected-image}')
SEALED=$(kubectl get deployment web-app -n production -o jsonpath='{.metadata.annotations.config\.example\.com/sealed}')

if [ "$SEALED" = "false" ]; then
    echo "Remediation enabled. Forcing Flux resync..."
    kubectl annotate deployment web-app "fluxcd.io/sync-timestamp=$(date +%s)" \
      -n production --overwrite
    echo "Next Flux sync will enforce: $EXPECTED"
else
    echo "Deployment sealed. Flux resync suppressed."
fi
```

**Best Practices for Drift Detection:**
- **Label deployments with drift-detection=enabled** to identify drift-sensitive workloads
- **Annotate expected state** in manifests so controllers can compare
- **Implement sealed mode** for emergency hotfixes without losing Git truth
- **Track drift history** in annotations for audit trails and root cause analysis
- **Use immutable image tags** (sha256 digests) not floating tags like latest
- **Monitor drift events** via Prometheus metrics + alerting
- **Auto-remediate only for non-critical workloads** - sealed mode for production

---

### Scenario 7: Graceful Pod Eviction and Owner Reference Cleanup

**Situation:** You're upgrading node OS and need to gracefully evict Pods without losing in-flight requests:

```bash
$ kubectl drain node1 --delete-emptydir-data
error: unable to drain node due to pod not respecting PodDisruptionBudget: \
  default/critical-job-abc123

$ kubectl get pod critical-job-abc123 -o yaml | grep -A5 metadata.ownerReferences
ownerReferences:
- apiVersion: batch/v1
  kind: Job
  name: critical-job
  uid: abc123def456
  controller: true

# Job controller creates replacement Pods immediately
$ kubectl get pods -l job-name=critical-job
NAME                        READY  STATUS     RESTARTS  AGE
critical-job-abc123         1/1    Running    0         1h
critical-job-abc456         0/1    Pending    0         3s  (NEW - controller racing)
```

**Challenge:** How do you prevent race conditions between eviction and owner controllers?

**Senior DevOps Solution: PodDisruptionBudget + Finalizers + Owner References**

1. **Proper Pod Declaration with Owner References:**
```yaml
# job-definition.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: critical-job
  namespace: default
  labels:
    app: data-processor
    tier: critical
  annotations:
    pod.example.com/graceful-shutdown-period: "60"  # Seconds
spec:
  backoffLimit: 3
  completions: 1
  parallelism: 1
  template:
    metadata:
      labels:
        app: data-processor
        job-name: critical-job
        disruption-handling: graceful  # For PDB matching
      annotations:
        description: "Processes critical financial transactions"
    spec:
      serviceAccountName: job-executor
      terminationGracePeriodSeconds: 60  # CRITICAL: Allow 60s graceful shutdown
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: job-name
                  operator: In
                  values:
                  - critical-job
              topologyKey: kubernetes.io/hostname  # Don't co-locate on same node
      containers:
      - name: processor
        image: data-processor:v2.1
        lifecycle:
          preStop:  # CRITICAL: Graceful shutdown signal
            exec:
              command: ["/bin/sh", "-c", "sleep 15 && curl -X POST http://localhost:8080/drain"]
        ports:
        - containerPort: 8080
        env:
        - name: GRACEFUL_SHUTDOWN_ENABLED
          value: "true"
---
# Pod Disruption Budget: Protect critical Pods during eviction
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-job-pdb
  namespace: default
spec:
  # minAvailable: 1  # At least 1 Pod must be available
  maxUnavailable: 0   # 0 Pods can be unavailable (strictest)
  selector:
    matchLabels:
      app: data-processor
      disruption-handling: graceful
  unhealthyPodEvictionPolicy: AlwaysAllow  # Allow eviction of failing Pods
```

2. **Node Drain with Respect for PDB:**
```bash
#!/bin/bash
# graceful-node-drain.sh

NODE="node1"

echo "=== Phase 1: Identify Eviction-Sensitive Pods ==="
kubectl get pods --all-namespaces -o json |\
  jq '.items[] | select(.metadata.ownerReferences[]?.kind == "Job") | {name: .metadata.name, namespace: .metadata.namespace}'

echo ""
echo "=== Phase 2: Check PodDisruptionBudgets ==="
kubectl get pdb --all-namespaces -o wide

echo ""
echo "=== Phase 3: Initiate Cordon (prevent new scheduling) ==="
kubectl cordon $NODE
echo "Node $NODE is now unschedulable"

echo ""
echo "=== Phase 4: Drain Node with Respect for PDB ==="
kubectl drain $NODE \
  --delete-emptydir-data \
  --ignore-daemonsets \
  --grace-period=60 \
  --timeout=10m \
  --pod-selector='!critical-app=true'  # Optional: skip critical pods

echo ""
echo "=== Phase 5: Verify Pod Migration ==="
echo "Waiting for Pods to reschedule..."
sleep 30

kubectl get pods -n default -o wide | grep critical-job
# Should show Pods on different nodes now

echo ""
echo "=== Phase 6: Verify No Data Loss ==="
kubectl logs -l app=data-processor -n default --tail=20
# Check for 'gracefully shutdown' messages

echo ""
echo "=== Phase 7: Node is Ready for Maintenance ==="
echo "All Pods gracefully evicted. Node: $NODE ready for OS upgrade."
```

3. **Finalizer-Based Cleanup Controller:**
```python
#!/usr/bin/env python3
# finalizer-cleanup-controller.py

from kubernetes import client, config, watch
import json

config.load_incluster_config()
v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()

FINALIZER = "cleanup.example.com/eviction-handler"

def handle_pod_deletion(pod):
    """When eviction signal sent, clean up gracefully before allowing deletion."""
    
    metadata = pod.metadata
    
    # Check if finalizer exists
    if FINALIZER not in (metadata.finalizers or []):
        return
    
    # Pod is being terminated, but finalizer prevents immediate deletion
    # This gives us time to:
    # 1. Drain connections
    # 2. Flush caches
    # 3. Update load balancers
    
    owner_refs = metadata.owner_references or []
    for ref in owner_refs:
        if ref.kind == "Job":
            print(f"Pod {metadata.name} owned by Job {ref.name}")
            # Job controller will ignore this Pod and create a replacement
        elif ref.kind == "Deployment":
            print(f"Pod {metadata.name} owned by Deployment {ref.name}")
            # Deployment controller will ignore and recreate
    
    # Simulate cleanup work
    print(f"Cleaning up resources for {metadata.name}...")
    
    # Remove finalizer to allow deletion
    metadata.finalizers = [f for f in (metadata.finalizers or []) if f != FINALIZER]
    
    try:
        v1.patch_namespaced_pod(metadata.name, metadata.namespace, pod)
        print(f"Cleanup complete. Pod {metadata.name} can now be deleted.")
    except Exception as e:
        print(f"Failed to update finalizers: {e}")

# Watch for Pod deletions
w = watch.Watch()
for event in w.stream(v1.list_namespaced_pod, 'default', field_selector='metadata.deletionTimestamp!=null'):
    pod = event['object']
    handle_pod_deletion(pod)
```

4. **Verification During Drain:**
```bash
#!/bin/bash
# verify-graceful-eviction.sh

echo "=== Monitor Pod Eviction Progress ==="
watch -n 2 'kubectl get pods -n default -l app=data-processor -o wide'

echo ""
echo "=== Check Termination Reasons ==="
kubectl get pods -n default -l app=data-processor -o json |\
  jq '.items[] | {name: .metadata.name, phase: .status.phase, reason: .status.reason}'

echo ""
echo "=== Verify Graceful Shutdown Messages ==="
for pod in $(kubectl get pods -n default -l app=data-processor -o name); do
    echo "Logs for $pod:"
    kubectl logs $pod -n default --tail=5 | grep -i 'graceful\|shutdown\|drain'
done

echo ""
echo "=== Check PodDisruptionBudget Status ==="
kubectl get pdb critical-job-pdb -n default -o jsonpath='{.status}' | jq .
```

**Best Practices for Graceful Eviction:**
- **Always set terminationGracePeriodSeconds** (minimum 30s for production workloads)
- **Implement preStop hooks** to signal application shutdown
- **Use PodDisruptionBudget (PDB)** to protect critical workloads with maxUnavailable=0
- **Set owner references correctly** so controllers understand parent-child relationships
- **Avoid finalizers unless necessary** - they block deletion and can cause stuck Pods
- **Test node drain in chaos experiments** - don't discover issues in production
- **Monitor drain operations** - set timeout to prevent hanging indefinitely

---

### Scenario 8: Cost Allocation and Chargeback Using Annotations and Labels

**Situation:** Finance wants to allocate Kubernetes costs to departments:

```bash
$ kubectl top nodes
NAME      CPU(cores)  CPU%    MEMORY(Mi)  MEMORY%
node1     800m        40%     4096Mi      50%
node2     600m        30%     6144Mi      75%

# But which Pods belong to which cost center?
$ kubectl get pods --all-namespaces -o wide
namespace   pod-name     node   ...  (NO COST INFO)

# Finance can't allocate costs without knowing:
# - Which department owns this workload?
# - What's the SLA/priority?
# - Is this production or dev/test?
```

**Challenge:** Design a cost allocation system using labels and annotations.

**Senior DevOps Solution: Hierarchical Labels + Cost Annotations**

1. **Standardized Cost Labeling Scheme:**
```yaml
# team-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: team-api
  namespace: production
  labels:
    # Organizational labels
    app: team-api
    team: platform-eng         # Department/Team
    cost-center: CC-42001      # Finance cost center
    environment: production    # prod/staging/dev
    data-classification: confidential  # public/internal/confidential/restricted
    
    # Cost tracking labels
    cost-model: shared-node    # Or 'dedicated-node', 'serverless'
    cost-billable: "true"      # Don't bill for CI/CD, test workloads
  
  annotations:
    # Cost allocation metadata
    cost.example.com/owner: "john.smith@example.com"  # Primary contact
    cost.example.com/cost-center: "CC-42001"
    cost.example.com/department: "Platform Engineering"
    cost.example.com/business-unit: "Infrastructure"
    cost.example.com/chargeback-model: "fixed-30-percent" # % of node costs
    cost.example.com/budget-alert-threshold: "1000"     # $ per month
    cost.example.com/monthly-budget: "5000"             # $ cap
    
    # SLA and priority
    sla.example.com/availability: "99.99"  # % uptime SLA
    sla.example.com/response-time-p99: "200ms"
    priority.example.com/tier: "P1"  # P1=critical, P3=best-effort

spec:
  replicas: 3
  selector:
    matchLabels:
      app: team-api
      cost-billable: "true"  # Pod must have same label for cost tracking
  
  template:
    metadata:
      labels:
        app: team-api
        team: platform-eng
        cost-center: CC-42001
        environment: production
        cost-billable: "true"
      
      annotations:
        pod-label-hash: "sha256:xyz"  # For tracking label mutations
    
    spec:
      # Resource requests drive cost calculations
      containers:
      - name: api
        image: team-api:v1.2.3
        resources:
          requests:
            cpu: 500m           # 0.5 vCPU * $HOURLY_RATE
            memory: 512Mi       # 512MB RAM * $HOURLY_RATE
          limits:
            cpu: 1000m
            memory: 1Gi
---
# NetworkPolicy for cost isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: team-api-network-policy
  namespace: production
  labels:
    cost-center: CC-42001
spec:
  podSelector:
    matchLabels:
      app: team-api
      cost-center: CC-42001
  policyTypes:
  - Ingress
  - Egress
  # Policy definition continues...
```

2. **Cost Calculation Controller:**
```python
#!/usr/bin/env python3
# cost-calculator-controller.py

from kubernetes import client, config
import json
from datetime import datetime
from typing import Dict, List

config.load_incluster_config()
v1 = client.CoreV1Api()
apps_v1 = client.AppsV1Api()

# Pricing configuration (hourly rates)
PRICING = {
    'cpu': 0.0417,           # $ per vCPU per hour (AWS m5.large equivalent)
    'memory': 0.00555,        # $ per GB per hour
    'storage': 0.00005,       # $ per GB per month
    'network': 0.02,          # $ per GB transferred
}

def calculate_pod_cost(pod_requests: Dict) -> float:
    """Calculate hourly cost of a Pod based on resource requests."""
    
    cpu_requests = pod_requests.get('cpu', 0)
    memory_requests = pod_requests.get('memory', 0)
    
    # Convert to standard units
    # CPU: "500m" -> 0.5
    # Memory: "512Mi" -> 0.5 GB
    
    if isinstance(cpu_requests, str):
        if cpu_requests.endswith('m'):
            cpu_value = float(cpu_requests[:-1]) / 1000
        else:
            cpu_value = float(cpu_requests)
    else:
        cpu_value = cpu_requests
    
    if isinstance(memory_requests, str):
        if memory_requests.endswith('Mi'):
            memory_value = float(memory_requests[:-2]) / 1024  # Convert to GB
        elif memory_requests.endswith('Gi'):
            memory_value = float(memory_requests[:-2])
        else:
            memory_value = float(memory_requests) / (1024**3)
    else:
        memory_value = memory_requests
    
    cpu_cost = cpu_value * PRICING['cpu']
    memory_cost = memory_value * PRICING['memory']
    
    return cpu_cost + memory_cost

def process_deployments():
    """Calculate costs per cost-center and update annotations."""
    
    cost_by_center: Dict[str, Dict] = {}
    
    # List all Deployments
    deps = appsv1.list_namespaced_deployment(namespace='production')
    
    for dep in deps.items:
        labels = dep.metadata.labels or {}
        annotations = dep.metadata.annotations or {}
        
        # Skip non-billable workloads
        if labels.get('cost-billable') != 'true':
            continue
        
        cost_center = labels.get('cost-center', 'unknown')
        team = labels.get('team', 'unknown')
        
        # Extract resource requests from template
        container = dep.spec.template.spec.containers[0]
        requests = container.resources.requests if container.resources else {}
        
        # Calculate hourly cost
        hourly_cost = calculate_pod_cost(requests)
        replicas = dep.spec.replicas or 1
        total_hourly_cost = hourly_cost * replicas
        
        # Accumulate by cost center
        if cost_center not in cost_by_center:
            cost_by_center[cost_center] = {
                'deployments': [],
                'total_hourly_cost': 0,
                'replicas': 0,
                'teams': set()
            }
        
        cost_by_center[cost_center]['deployments'].append({
            'name': dep.metadata.name,
            'namespace': dep.metadata.namespace,
            'replicas': replicas,
            'hourly_cost': total_hourly_cost
        })
        cost_by_center[cost_center]['total_hourly_cost'] += total_hourly_cost
        cost_by_center[cost_center]['replicas'] += replicas
        cost_by_center[cost_center]['teams'].add(team)
        
        # Update Deployment with calculated cost
        annotations['cost.example.com/calculated-hourly-cost'] = str(total_hourly_cost)
        annotations['cost.example.com/calculated-monthly-cost'] = str(total_hourly_cost * 730)  # 30 days * 24h
        annotations['cost.example.com/last-calculated'] = datetime.now().isoformat()
        
        dep.metadata.annotations = annotations
        
        try:
            v1.patch_namespaced_deployment(dep.metadata.name, dep.metadata.namespace, dep)
        except Exception as e:
            print(f"Failed to update {dep.metadata.name}: {e}")
    
    return cost_by_center

def report_costs(cost_by_center: Dict):
    """Generate cost report per cost center."""
    
    report = {
        'timestamp': datetime.now().isoformat(),
        'pricing': PRICING,
        'cost_centers': []
    }
    
    for cc, data in cost_by_center.items():
        monthly_cost = data['total_hourly_cost'] * 730
        
        report['cost_centers'].append({
            'cost_center': cc,
            'teams': list(data['teams']),
            'workloads': data['deployments'],
            'total_replicas': data['replicas'],
            'hourly_cost': round(data['total_hourly_cost'], 2),
            'daily_cost': round(data['total_hourly_cost'] * 24, 2),
            'monthly_cost': round(monthly_cost, 2)
        })
    
    print(json.dumps(report, indent=2))
    return report

if __name__ == '__main__':
    print(f"[{datetime.now()}] Starting cost calculation...")
    costs = process_deployments()
    report = report_costs(costs)
    print(f"[{datetime.now()}] Cost report generated.")
```

3. **Cost Allocation and Billing Report:**
```bash
#!/bin/bash
# generate-chargeback-report.sh

echo "=== Kubernetes Cost Chargeback Report ==="
echo "Report Date: $(date)"
echo ""

echo "=== Summary by Cost Center ==="
kubectl get deployments --all-namespaces -o json |\
  jq -r '.items[] | select(.metadata.labels["cost-billable"] == "true") | 
    [.metadata.labels["cost-center"], .metadata.annotations["cost.example.com/calculated-monthly-cost"]] | @csv' |\
  awk -F, '{cc[$1]+=$2} END {for (c in cc) print c ": $" cc[c]}' | sort -t: -k2 -rn

echo ""
echo "=== Top 10 Most Expensive Workloads ==="
kubectl get deployments --all-namespaces -o json |\
  jq -r '.items[] | select(.metadata.labels["cost-billable"] == "true") |
    [.metadata.namespace, .metadata.name, (.metadata.annotations["cost.example.com/calculated-monthly-cost"] | tonumber)] |
    @csv' |\
  sort -t, -k3 -rn | head -10 |\
  awk -F, '{printf "%-20s %-30s \$%.2f/month\n", $1, $2, $3}'

echo ""
echo "=== Cost Alerts (Near Budget) ==="
kubectl get deployments --all-namespaces -o json |\
  jq '.items[] | select(
    (.metadata.labels["cost-billable"] == "true") and
    ((.metadata.annotations["cost.example.com/calculated-monthly-cost"] | tonumber) >
     ((.metadata.annotations["cost.example.com/monthly-budget"] // "999999") | tonumber) * 0.8)
  ) | {namespace: .metadata.namespace, name: .metadata.name, team: .metadata.labels.team}'

echo ""
echo "=== Department Breakdown ==="
kubectl get deployments --all-namespaces -o json |\
  jq -r '.items[] | select(.metadata.labels["cost-billable"] == "true") |
    [.metadata.labels["team"], .metadata.annotations["cost.example.com/calculated-monthly-cost"]] |
    @csv' | \
  awk -F, '{team[$1]+=$2} END {for (t in team) printf "%-25s $%.2f/month\n", t, team[t]}' | sort -t$ -k2 -rn
```

**Best Practices for Cost Allocation:**
- **Label consistently** - cost-center, team, environment labels on every workload
- **Annotate financial metadata** - owner, SLA tier, budget limits
- **Request resources accurately** - requests drive cost, set them precisely
- **Skip CI/CD pipelines** - mark with cost-billable=false
- **Monitor budget overages** - alert when approaching monthly limits
- **Track by team, not by namespace** - teams span namespaces
- **Update pricing regularly** - cloud costs change with discounts/volume deals

---

## Interview Questions

### Question 1: Explain the difference between `kubectl apply` and `kubectl replace` in terms of object metadata and the THREE-WAY MERGE strategy.

**Expected Answer (5-10 minutes):**

A senior engineer should explain:

1. **kubectl apply (Three-Way Merge):**
   - Compares three states: last-applied config, current object in cluster, desired config
   - Preserves user's intentional changes
   - Implements field-level tracking (which user/tool owns which fields)
   - Safe for iterative updates

   ```
   kubectl apply -f deployment.yaml
                 │
                 ▼
   Three sources:
   1. Current manifest (deployment.yaml)  <- what you wrote
   2. Object in etcd                      <- what's currently stored
   3. Last manifest applied (stored in metadata.annotations.kubectl.kubernetes.io/last-applied-configuration)
                 │
                 ▼
   Three-way merge algorithm:
   - If field unchanged in (2) and (3): use (1)
   - If field changed in (3), unchanged in (2): keep (3) (user's manual change)
   - If field changed in both (1) and (2): conflict (error)
   - If field changed in (2), unchanged in (1): use (1) (manifest is source of truth)
   ```

2. **kubectl replace (Direct Replacement):**
   - Completely overwrites the object
   - Does NOT merge fields
   - Loses any fields not in the manifest
   - Dangerous if another tool manages fields

   ```bash
   kubectl replace -f deployment.yaml --overwrite
   # Entire object = manifest contents + system-managed fields only
   # Any annotations added by other tools = LOST
   ```

3. **Metadata Implications:**
   - `kubectl apply`: Stores manifest json in `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration`
   - `metadata.managedFields`: Tracks field ownership when using server-side apply
   - Label/annotation changes: `kubectl apply` merges them, `kubectl replace` overwrites

4. **Real-world scenario:**
   ```bash
   # Step 1: Deploy with kubectl apply
   kubectl apply -f deployment.yaml
   # metadata.annotations stores applied config

   # Step 2: Prometheus operator adds annotations (Istio, monitoring, etc.)
   # Deployment now has extra annotations not in deployment.yaml

   # Step 3: Update replicas in manifest
   kubectl apply -f deployment.yaml
   # Three-way merge preserves Prometheus annotations (since they can't be in manifest)

   # Step 4: Someone uses kubectl replace (WRONG)
   kubectl replace -f deployment.yaml --overwrite
   # Result: All Prometheus annotations DELETED, monitoring breaks
   ```

**Follow-up:** How would you prevent this issue?
- **Answer:** Use `kubectl apply --server-side` (field manager ownership) or GitOps tools that orchestrate application

---

### Question 2: A Deployment has `replicas: 3` in the spec, but `kubectl get pod` shows 5 Pods running. What are the possible explanations, and how would you troubleshoot each?

**Expected Answer (10+ minutes):**

A senior engineer should methodically explore:

1. **Multiple Deployments with similar labels:**
   ```bash
   # First check: are ALL 5 Pods owned by this Deployment?
   kubectl get pods -l app=api -o jsonpath='{range .items[*]}{.metadata.ownerReferences[*].name}{"\n"}{end}'
   
   # If results like:
   # deployment-v1
   # deployment-v1
   # deployment-v1
   # deployment-v2  <- Different owner!
   # deployment-v2
   # BUG: Multiple Deployments selecting same Pods (label collision)
   ```

2. **ReplicaSet mismatch (Deployment has orphaned ReplicaSets):**
   ```bash
   kubectl get rs -l app=api
   NAME                  DESIRED   CURRENT   READY   AGE
   api-abc123            3         3         3       1h
   api-def456            2         2         2       5m  <- Old ReplicaSet!
   api-ghi789            3         3         3       1s
   
   # Three ReplicaSets exist:
   # - Old ReplicaSet (2 Pods)
   # - Current ReplicaSet (3 Pods)
   # = 5 total
   
   # Fix: Delete old ReplicaSet
   kubectl delete rs api-def456
   # Pods owned by that RS are also deleted (cascade delete)
   ```

3. **maxSurge in RollingUpdate strategy:**
   ```bash
   kubectl get deployment api -o jsonpath='{.spec.strategy.rollingUpdate}'
   # Output: {"maxSurge":2,"maxUnavailable":0}
   # During rollout: desired=3, actual=3+2=5
   
   # This is TEMPORARY (waiting for old Pods to be deleted)
   # Check ReplicaSet status:
   kubectl get pods -o wide --show-labels
   # If you see: 3 new Pods + 2 old Pods
   # Rollout is in progress, wait for completion
   kubectl rollout status deployment/api --timeout=5m
   ```

4. **Orphaned Pods (no owner reference):**
   ```bash
   kubectl get pods -o json | jq '.items[] | select(.metadata.ownerReferences == null) | .metadata.name'
   # Shows Pods with no owner
   # These don't count toward Deployment replicas
   # Delete them: kubectl delete pod <orphaned-pod>
   ```

5. **Admission webhook mutating Pod specs:**
   ```bash
   # Some webhooks (Istio, SecretProvider) add sidecar containers
   # Could trigger unintended behavior
   
   # Check if webhooks are active:
   kubectl get mutatingwebhookconfiguration
   # Check webhook logs for side effects
   ```

**Structured debugging script:**
```bash
#!/bin/bash
# debug-replica-mismatch.sh

DEPLOYMENT=$1
NAMESPACE=${2:-default}

echo "=== Deployment Status ==="
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o wide

echo "\n=== ReplicaSets ==="
kubectl get rs -n $NAMESPACE -l app=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.selector.matchLabels.app}')

echo "\n=== All Pods ==="
kubectl get pods -n $NAMESPACE -l app=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.selector.matchLabels.app}') -o wide

echo "\n=== Owner References ==="
kubectl get pods -n $NAMESPACE -l app=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.selector.matchLabels.app}') -o jsonpath='{range .items[*]}{.metadata.name}{"->Owner: "}{.metadata.ownerReferences[0].name}{"\n"}{end}'

echo "\n=== Rollout Strategy ==="
kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.strategy}' | jq '.'
```

---

### Question 3: Describe a scenario where `finalizers` prevent object deletion, and explain how you would safely remove a stuck object without data loss.

**Expected Answer (10+ minutes):**

Scenario: PersistentVolumeClaim (PVC) has finalizer to prevent deletion before cleanup.

```bash
# Attempt to delete PVC
kubectl delete pvc database-claim -n production

# Check status
kubectl get pvc database-claim
NAME             STATUS        VOLUME              CAPACITY   ACCESS MODES
database-claim   Terminating   pvc-12345-claim     100Gi      RWO

# Why stuck?
kubectl get pvc database-claim -o yaml | grep finalizers
finalizers:
- custom.storage.io/backup-finalizer

# The finalizer controller needs to:
# 1. Backup the data
# 2. Notify external storage system
# 3. Remove finalizer
```

**Safe removal process:**

```bash
# Option 1: Wait for controller to complete (if reachable)
kubectl describe pvc database-claim
# Check Age and Events for why it's stuck
# If controller is working, just wait

# Option 2: Check if finalizer controller is running
kubectl get pods -n kube-system | grep  storage-controller
# If missing: redeploy controller

# Option 3: Manually remove finalizer (ONLY if you understand consequences)
# WARNING: Risk of orphaned external resources

# Safe method using kubectl patch with dry-run first:
kubectl get pvc database-claim -o yaml > pvc-backup.yaml
# Backup the manifest for restoration if needed

# Remove finalizer:
kubectl patch pvc database-claim --type json -p='[
  {"op": "remove", "path": "/metadata/finalizers/0"}
]'

# Verify finalizer removed:
kubectl get pvc database-claim -o yaml | grep finalizers
# Should be empty or missing

# Now object deletes:
kubectl delete pvc database-claim
```

**Prevention strategies:**

1. **Finalizers with exponential backoff:**
   ```python
   import kopf
   
   @kopf.on.delete('v1', 'persistentvolumeclaims')
   def cleanup_pvc(name, namespace, **kwargs):
       try:
           # Backup data
           backup_pvc_data(name, namespace)
       except TimeoutError:
           # Don't crash - retry will happen
           raise kopf.TemporaryError(
               f"Backup timed out, retrying...",
               delay=60  # Wait 60 seconds before retry
           )
       except Exception as e:
           # Unrecoverable error
           logger.error(f"Cannot backup {name}: {e}")
           # Remove finalizer to allow deletion (data loss!)
           # Alert ops team
           send_alert(f"PVC {name} finalizer removed due to error")
           # Let garbage collection proceed
   ```

2. **Monitor finalizers for stuck objects:**
   ```bash
   #!/bin/bash
   # Check for objects stuck in Terminating state > 10 minutes
   kubectl get pods --all-namespaces -o json | \
     jq '.items[] | select(.metadata.deletionTimestamp != null) | 
         select(.
         (.metadata.deletionTimestamp | fromdateiso8601) < (now - 600)) | 
         .metadata.name' | \
     while read pod; do
       echo "Alert: Pod $pod stuck for > 10 minutes"
       # Send to monitoring system
     done
   ```

3. **Set deletion grace period limits:**
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: api-server
   spec:
     terminationGracePeriodSeconds: 30  # Max 30 seconds to shut down
   # If finalizer takes > 30s, kubelet forces termination
   ```

---

### Question 4: How would you implement a custom webhook to enforce that all Deployments must have specific labels and that certain fields are immutable?

**Expected Answer (15+ minutes):**

Implement a ValidatingWebhook that:
1. Requires labels: `app`, `version`, `team`
2. Prevents changing `spec.selector.matchLabels` after creation
3. Enforces image digest (not tag)

```python
# validate-deployment-webhook.py
from flask import Flask, request, jsonify
import json
import base64

app = Flask(__name__)

@app.route('/validate-deployment', methods=['POST'])
def validate_deployment():
    admission_review = request.get_json()
    
    # Extract the Deployment object
    deployment = admission_review['request']['object']
    old_deployment = admission_review['request'].get('oldObject')
    uid = admission_review['request']['uid']
    
    allowed = True
    message = ""
    errors = []
    
    # Validation 1: Required labels
    labels = deployment.get('metadata', {}).get('labels', {})
    required = ['app', 'version', 'team']
    for label_key in required:
        if label_key not in labels:
            allowed = False
            errors.append(f"Missing required label: {label_key}")
    
    # Validation 2: Image must be pinned to digest (not tag)
    containers = deployment.get('spec', {}).get('template', {}).get('spec', {}).get('containers', [])
    for container in containers:
        image = container.get('image', '')
        if not image.startswith('sha256:') and '@sha256:' not in image:
            allowed = False
            errors.append(f"Image must be pinned to digest, got: {image}")
    
    # Validation 3: Immutable selector (don't allow changing after creation)
    if old_deployment:  # UPDATE request (old object exists)
        old_selector = old_deployment.get('spec', {}).get('selector', {}).get('matchLabels', {})
        new_selector = deployment.get('spec', {}).get('selector', {}).get('matchLabels', {})
        
        if old_selector != new_selector:
            allowed = False
            errors.append(f"Cannot modify selector after creation")
    
    # Build response
    response = {
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": {
            "uid": uid,
            "allowed": allowed,
            "status": {
                "message": "\n".join(errors) if errors else "Valid"
            }
        }
    }
    
    return jsonify(response)

if __name__ == '__main__':
    app.run(ssl_context=('tls.crt', 'tls.key'), port=8443)
```

Deploy the webhook:
```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: webhook

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webhook-server
  namespace: webhook
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webhook-server
  template:
    metadata:
      labels:
        app: webhook-server
    spec:
      containers:
      - name: webhook
        image: webhook-server:latest
        ports:
        - containerPort: 8443
        volumeMounts:
        - name: webhook-certs
          mountPath: /var/run/secrets/webhook
      volumes:
      - name: webhook-certs
        secret:
          secretName: webhook-certs

---
apiVersion: v1
kind: Service
metadata:
  name: webhook-service
  namespace: webhook
spec:
  ports:
  - port: 443
    targetPort: 8443
  selector:
    app: webhook-server

---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: deployment-validator
webhooks:
- name: deployments.example.com
  clientConfig:
    service:
      name: webhook-service
      namespace: webhook
      path: "/validate-deployment"
    caBundle: <base64-encoded-ca-certificate>
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["apps"]
    apiVersions: ["v1"]
    resources: ["deployments"]
  admissionReviewVersions: ["v1"]
  sideEffects: None
  failurePolicy: Fail  # Reject if webhook fails
  timeoutSeconds: 5
```

Test the webhook:
```bash
# This should FAIL (missing labels)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-api
  template:
    metadata:
      labels:
        app: test-api
    spec:
      containers:
      - name: api
        image: myapi:latest  # Also no digest!
EOF
# Error: validation failed: "Missing required label: version"

# This should SUCCEED (correct labels and digest)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-api
  labels:
    app: test-api
    version: v1.0.0
    team: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-api
  template:
    metadata:
      labels:
        app: test-api
    spec:
      containers:
      - name: api
        image: myapi@sha256:abc123def456  # Pinned digest
EOF
# deployment.apps/test-api created
```

---

### Question 5: Design an object model for a custom resource that represents a "CanaryDeployment" with progressive traffic shifting, automated rollback, and audit trail.

**Expected Answer (20+ minutes):**

A senior engineer should design a CRD that:
- Declares desired outcome (not imperative steps)
- Includes automatic rollback triggers
- Tracks history for audit compliance

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: canarydeployments.deploy.example.com
spec:
  group: deploy.example.com
  names:
    kind: CanaryDeployment
    plural: canarydeployments
  scope: Namespaced
  versions:
  - name: v1alpha1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required:
            - stableVersion
            - canaryVersion
            properties:
              # Current stable and canary versions
              stableVersion:
                type: string
                pattern: '^(v)?[0-9]+\.[0-9]+\.[0-9]+$'
                example: "v2.1.0"
                description: "Production version receiving full traffic"
              
              canaryVersion:
                type: string
                pattern: '^(v)?[0-9]+\.[0-9]+\.[0-9]+$'
                example: "v3.0.0"
                description: "Candidate version for gradual rollout"
              
              # Gradual traffic shifting strategy
              trafficShiftingStrategy:
                type: object
                properties:
                  initialTrafficPercent:
                    type: integer
                    minimum: 1
                    maximum: 100
                    example: 10
                    description: "Start canary with 10% traffic"
                  
                  incrementPercent:
                    type: integer
                    minimum: 1
                    maximum: 100
                    description: "Increase canary traffic by X% every interval"
                  
                  incrementInterval:
                    type: string
                    pattern: '^[0-9]+(m|h|s)$'
                    example: "5m"
                    description: "Time between traffic increments (e.g., 5m, 2h)"
              
              # Automatic rollback triggers
              rollbackTriggers:
                type: object
                properties:
                  errorRateThreshold:
                    type: number
                    minimum: 0.01
                    maximum: 1.0
                    example: 0.05
                    description: "Rollback if canary error rate > 5%"
                  
                  latencyPercentileThresholdMs:
                    type: object
                    properties:
                      p99:
                        type: integer
                        minimum: 1
                        example: 500
                        description: "Rollback if p99 latency > 500ms"
                      p95:
                        type: integer
                        minimum: 1
                        example: 300
              
              # Deployment details
              deploymentRef:
                type: object
                required:
                - name
                properties:
                  name:
                    type: string
                    example: "api-server"
                  namespace:
                    type: string
                    example: "production"
              
              # Audit and compliance
              audit:
                type: object
                properties:
                  enableAuditTrail:
                    type: boolean
                    example: true
                    description: "Record all traffic shifts and rollbacks"
                  
                  auditLogDestination:
                    type: string
                    example: "s3://audit-logs/canary-deployments"
                  
                  slackNotifications:
                    type: boolean
                    example: true
          
          status:
            type: object
            properties:
              phase:
                type: string
                enum:
                - Pending
                - InProgress
                - Succeeded
                - RolledBack
                - Failed
              
              currentCanaryTrafficPercent:
                type: integer
                minimum: 0
                maximum: 100
              
              canaryErrorRate:
                type: number
                minimum: 0
                maximum: 1.0
              
              stableErrorRate:
                type: number
                minimum: 0
                maximum: 1.0
              
              lastTransitionTime:
                type: string
                format: date-time
              
              conditions:
                type: array
                items:
                  type: object
                  properties:
                    type:
                      type: string
                      enum:
                      - "TrafficShifting"
                      - "HealthChecking"
                      - "RollbackTriggered"
                      - "Completed"
                      - "Error"
                    status:
                      type: string
                      enum: ["True", "False", "Unknown"]
                    reason:
                      type: string
                    message:
                      type: string
                    lastTransitionTime:
                      type: string
                      format: date-time
              
              auditTrail:
                type: array
                items:
                  type: object
                  properties:
                    timestamp:
                      type: string
                      format: date-time
                    action:
                      type: string
                      enum:
                      - "TrafficShiftStarted"
                      - "TrafficShiftIncremented"
                      - "RollbackTriggered"
                      - "RollbackCompleted"
                    trafficPercent:
                      type: integer
                    reason:
                      type: string
                    errorRate:
                      type: number
```

Example usage:
```yaml
apiVersion: deploy.example.com/v1alpha1
kind: CanaryDeployment
metadata:
  name: api-server-canary
  namespace: production
spec:
  stableVersion: v2.1.0
  canaryVersion: v3.0.0
  
  trafficShiftingStrategy:
    initialTrafficPercent: 5      # Start with 5%
    incrementPercent: 10          # Increase by 10% every interval
    incrementInterval: 5m         # Every 5 minutes
  
  rollbackTriggers:
    errorRateThreshold: 0.01      # Rollback if canary errors > 1%
    latencyPercentileThresholdMs:
      p99: 750                    # Rollback if p99 > 750ms
      p95: 500
  
  deploymentRef:
    name: api-server
    namespace: production
  
  audit:
    enableAuditTrail: true
    auditLogDestination: "s3://company-audit"
    slackNotifications: true
```

Controller logic (pseudocode):
```python
@kopf.on.event('deploy.example.com', 'v1alpha1', 'canarydeployments')
def canary_controller(name, namespace, spec, status, patch, **kwargs):
    stable_version = spec['stableVersion']
    canary_version = spec['canaryVersion']
    
    # 1. Create two Deployments
    create_deployment_if_not_exists(
        name=f"{name}-stable",
        image=stable_version,
        replicas=calculate_stable_replicas(100 - current_canary_traffic)
    )
    create_deployment_if_not_exists(
        name=f"{name}-canary",
        image=canary_version,
        replicas=calculate_canary_replicas(current_canary_traffic)
    )
    
    # 2. Update Service selector to include both (load balance by replica count)
    # Service will automatically balance traffic proportional to Pod count
    
    # 3. Monitor canary metrics
    canary_error_rate = query_prometheus(f"api:error_rate{{version='{canary_version}'}}")
    canary_p99_latency = query_prometheus(f"api:latency_p99{{version='{canary_version}'}}")
    
    # 4. Check rollback conditions
    if canary_error_rate > spec['rollbackTriggers']['errorRateThreshold']:
        audit_log("RollbackTriggered", reason="Error rate exceeded")
        patch.status['phase'] = 'RolledBack'
        # Delete canary Deployment
        delete_deployment(f"{name}-canary")
        return
    
    # 5. If canary healthy, increment traffic
    if canary_healthy_for_duration(spec['trafficShiftingStrategy']['incrementInterval']):
        new_traffic = current_canary_traffic + spec['trafficShiftingStrategy']['incrementPercent']
        
        # Scale deployments to new traffic ratio
        scale_deployment(f"{name}-stable", replicas=...) # 100-new_traffic %
        scale_deployment(f"{name}-canary", replicas=...) # new_traffic %
        
        audit_log("TrafficShiftIncremented", trafficPercent=new_traffic)
        patch.status['currentCanaryTrafficPercent'] = new_traffic
    
```

---

### Q6: matchLabels vs. ownerReferences - When to Use Both?

**Question:**
You're designing a multi-tenant SaaS platform on Kubernetes. When defining object relationships and service discovery, when would you use label selectors (matchLabels) vs. owner references? Why not just pick one?

**Senior DevOps Answer:**

These solve **fundamentally different problems**:

**Label Selectors (matchLabels):**
- **Purpose**: Functional grouping - what objects work together
- **Scope**: Query-able across the cluster, indexed by API server
- **Lifecycle**: Queryable while object exists or deleted
- **Typical use**: Service discovery, scheduling, quotas, NetworkPolicy
- **Example relationship**: "Service finds all Pods serving this application"

**Owner References:**
- **Purpose**: Ownership hierarchy - parent-child relationships
- **Scope**: Direct parent-child only, not queryable
- **Lifecycle**: Triggers cascade deletion when parent deleted
- **Typical use**: Cleanup coordination, garbage collection, lifecycle tracking
- **Example relationship**: "Deployment owns ReplicaSets" or "Job owns Pods"

**Real-World Example: Multi-Tenant SaaS Cost Allocation**

```yaml
# Tenant-specific Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-acme-corp
  labels:
    tenant-id: "acme-corp"           # For Service discovery ACROSS tenants
    cost-center: CC-4001
    data-classification: confidential
  annotations:
    tenant.example.com/subscription-tier: "enterprise"
    tenant.example.com/owner: "admin@acme.com"
---
# Deployment with BOTH relationships
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tenant-api
  namespace: tenant-acme-corp
  labels:
    app: api
    tenant-id: "acme-corp"           # ← For Service selector
    billing-group: "api-services"    # ← For cost allocation queries
    data-owner: "john.smith@acme"    # ← For cross-tenant filtering
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
      tenant-id: "acme-corp"         # ← Service uses LABELS to find Pods
  template:
    metadata:
      labels:
        app: api
        tenant-id: "acme-corp"       # ← Pod inherits for discovery
        billing-group: "api-services"
      ownerReferences:                # ← Deployment is OWNER of Pods
      - apiVersion: apps/v1
        kind: Deployment
        name: tenant-api
        uid: <deployment-uid>
        controller: true              # ← Triggers cascade delete
    spec:
      containers:
      - name: api
        image: tenant-api:v1.2.3
---
# Service: Discovers Pods using LABELS
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: tenant-acme-corp
  labels:
    app: api
spec:
  selector:
    app: api                # ← Matches Pod labels (discovery)
    tenant-id: "acme-corp" # ← Ensures tenant isolation
  ports:
  - port: 80
    targetPort: 8080
---
# NetworkPolicy: ALSO uses labels for isolation
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: tenant-isolation
  namespace: tenant-acme-corp
spec:
  podSelector:
    matchLabels:
      tenant-id: "acme-corp"  # ← Selects Pods by label
  policyTypes:
  - Ingress
  - Egress
```

**Owner References: Cascade Delete Safety**

```bash
# Scenario: Deleting Deployment
$ kubectl delete deployment tenant-api -n tenant-acme-corp --cascade=background

# What happens:
# 1. Deployment object deleted 
# 2. Kubernetes sees all Pods have ownerReference.apiVersion=apps/v1, kind=Deployment, uid=<this-uid>
# 3. Garbage collector automatically deletes all child Pods
# 4. ReplicaSet also deleted (it's also owned by Deployment)

$ kubectl get pods -n tenant-acme-corp
# All pods deleted after ~30s

# Contrast: If we only used labels, Pods would persist orphaned:
$ kubectl describe pod <orphaned-pod>
# Service would still try to load-balance to it
# No automatic cleanup
```

**Cost Allocation Using BOTH Labels AND Owner References**

```yaml
# Cost Allocation ConfigMap (updated hourly)
apiVersion: v1
kind: ConfigMap
metadata:
  name: tenant-costs
  namespace: default
data:
  query-pod-costs: |
    # Query by labels (cross-cluster possible)
    kubectl get pods --all-namespaces \
      -l tenant-id=acme-corp,billing-group=api-services \
      -o json | jq '.items[].spec.containers[].resources.requests'
    
    # Sum costs by label
    # tenant-id acme-corp: $1,200/month (all workloads)
    # billing-group api-services: $800/month (API tier only)
  
  query-ownership-tree: |
    # Query ownership (single namespace)
    kubectl get pods -n tenant-acme-corp \
      -o json | jq '.items[].metadata.ownerReferences'
    
    # Shows: Pod → owned by ReplicaSet → owned by Deployment
    # Used for chargebackto deployment teams
```

**Decision Tree:**

```
Does object need to be:

├─ Discovered/Queried? (Service, NetworkPolicy, quota, metrics)
│  └─ USE LABELS (indexed in API server)
│  └─ Make queryable: service.spec.selector = {labels}
│
├─ Automatically Cleaned Up when parent deleted?
│  └─ USE OWNER REFERENCES (garbage collector enforces)
│  └─ Enables cascade deletion
│  └─ Typically: Deployments own Pods, Jobs own Pods
│
└─ Both?
   └─ Use BOTH (common pattern)
   ├─ Labels for: Service discovery, pod selection, quotas
   └─ Owner references for: Cleanup, lifecycle tracking
```

**Best Practices:**
- **Service discovery = labels** - matchLabels selectors don't understand ownership
- **Lifecycle control = owner references** - enables garbage collection
- **Cost allocation = labels** - owner references aren't queryable across clusters
- **Every Pod should have both** - labels for functionality, owner refs for cleanup
- **Test cascade deletion** - ensure owner references are set correctly

---

### Q7: Pod Deletion Order During Rolling Updates - How Much Control Do You Have?

**Question:**
You have a stateful API that cannot handle more than 50 concurrent connections. During a RollingUpdate with maxSurge=1 and maxUnavailable=1, the old Pod sometimes gets deleted before application connections drain gracefully. What mechanisms control Pod deletion order, and which is most reliable?

**Senior DevOps Answer:**

Pod deletion order is controlled by **multiple mechanisms** with different precedence:

1. **PodDisruptionBudget (PDB)** - Highest precedence
2. **Finalizers** - Blocks deletion until manually removed
3. **terminationGracePeriodSeconds** - Grace period before SIGKILL
4. **preStop hooks** - Custom shutdown sequence
5. **Pod priority/QoS** - Lower priority Pods deleted first

**Real-World Scenario: Stateful Connection Draining**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stateful-api
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # New Pod comes up
      maxUnavailable: 1     # Old Pod ready to be killed
  
  template:
    metadata:
      labels:
        app: stateful-api
        max-connections: "50"  # For external load balancers
    spec:
      # Mechanism 1: Grace period
      terminationGracePeriodSeconds: 45  # 45s before SIGKILL
      
      # Mechanism 2: Priority (lower = deleted first)
      priorityClassName: high-priority   # Kubernetes native
      
      containers:
      - name: api
        image: api:v2.1
        lifecycle:
          # Mechanism 3: preStop hook for graceful shutdown
          preStop:
            exec:
              command: ["/bin/bash", "-c", """
                # Signal to stop accepting new connections
                echo 'Draining connections...' > /tmp/shutdown
                
                # Wait for existing connections to close
                # (app checks this file and stops accepting new conns)
                for i in {1..30}; do
                  ACTIVE=$(curl -s http://localhost:8080/active-connections || echo 0)
                  echo "Active connections: $ACTIVE"
                  if [ $ACTIVE -eq 0 ]; then
                    echo "All connections drained"
                    break
                  fi
                  sleep 1
                done
                
                echo "Graceful shutdown complete"
              """]
        
        # Health check shows Pod is shutting down
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          failureThreshold: 2
          periodSeconds: 5
      
      # Mechanism 4: Finalizers (app controller sets this)
      # initContainers:
      # - name: add-finalizer
      #   image: finalizer-tool
      #   command: ["kubectl", "patch", "pod", ..., "-p",
      #     '{"metadata":{"finalizers":["connection-drainer.example.com/cleanup"]}}']

---
# Mechanism 5: PodDisruptionBudget (Prevents eviction)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: stateful-api-pdb
spec:
  minAvailable: 2      # At least 2 Pods must be available
  # OR maxUnavailable: 1 # At most 1 Pod can be unavailable
  selector:
    matchLabels:
      app: stateful-api
  unhealthyPodEvictionPolicy: AlwaysAllow  # But not if failing

---
# Finalizer-based connection drainer
apiVersion: v1
kind: ConfigMap
metadata:
  name: connection-drainer-script
data:
  drain.sh: |
    #!/bin/bash
    POD_NAME=$1
    NAMESPACE=$2
    FINALIZER="connection-drainer.example.com/cleanup"
    
    # 1. Add finalizer (blocks deletion)
    kubectl patch pod $POD_NAME -n $NAMESPACE -p \
      '{"metadata":{"finalizers":["'$FINALIZER'"]}'
    
    # 2. Monitor connection draining
    DRAIN_TIMEOUT=45
    ELAPSED=0
    
    while [ $ELAPSED -lt $DRAIN_TIMEOUT ]; do
      ACTIVE=$(kubectl exec $POD_NAME -n $NAMESPACE -- \
        curl -s http://localhost:8080/active-connections 2>/dev/null || echo 0)
      
      if [ "$ACTIVE" = "0" ]; then
        echo "All connections drained"
        break
      fi
      
      echo "Waiting for connections to drain... ($ACTIVE active)"
      sleep 1
      ELAPSED=$((ELAPSED + 1))
    done
    
    # 3. Remove finalizer to allow deletion
    kubectl patch pod $POD_NAME -n $NAMESPACE -p \
      '{"metadata":{"finalizers":null}}'
```

**Deletion Precedence During Rolling Update:**

```
When Deployment decides to delete old Pod:

1. Check PodDisruptionBudget
   └─ If would violate minAvailable → BLOCK deletion
   └─ Otherwise → allow eviction signal

2. Send TERM signal to Pod
   └─ App receives SIGTERM
   └─ App should stop accepting connections

3. Execute preStop hook (if defined)
   └─ Runs in parallel with TERM
   └─ Has terminationGracePeriodSeconds to complete
   └─ If hangs → receives SIGKILL after timeout

4. Check for Finalizers
   └─ If finalizers present → Pod stuck in Terminating
   └─ Finalizer controller must remove before deletion

5. After grace period expires → SIGKILL
   └─ Hard kill (no cleanup)
```

**Testing Pod Deletion Order:**

```bash
#!/bin/bash
# test-pod-deletion-order.sh

echo "=== Current Pods ==="
kubectl get pods -n production -l app=stateful-api -o wide

echo ""
echo "=== Start Monitoring Connection Drain ==="
# In separate terminal:
watch -n 1 'kubectl logs -l app=stateful-api -n production --tail=3 | grep -i "drain\|connection"'

echo ""
echo "=== Trigger Rolling Update ==="
kubectl set image deployment/stateful-api api=api:v2.2 -n production

echo ""
echo "=== Monitor Deletion Events ==="
watch -n 2 'kubectl get pods -n production -l app=stateful-api -o wide; echo; kubectl get events -n production --sort-by=".lastTimestamp" | tail -5'

echo ""
echo "=== Check if PDB Blocked Deletion ==="
kubectl get pdb stateful-api-pdb -n production -o jsonpath='{.status}' | jq .
# Output:
# {
#   "disruptionsAllowed": 0,
#   "disruptedPods": null,
#   "observedGeneration": 1,
#   "totalPods": 3
# }
# If disruptionsAllowed=0, PDB is preventing simultaneous eviction
```

**Best Practices:**
- **Always set terminationGracePeriodSeconds ≥ 30** for production
- **Implement preStop hooks** for graceful connection draining
- **Use PodDisruptionBudget with minAvailable=N-1** to prevent cascading failures
- **Test rolling updates in staging** - don't discover issues in production
- **Avoid finalizers unless necessary** - they can cause stuck Pods
- **Monitor drain events** - alert if `Terminating` phase lasts >1minute

---

### Q8: kubectl apply vs. server-side apply vs. GitOps Tooling - Conflict Resolution

**Question:**
Your team uses Flux for GitOps, but developers sometimes run `kubectl apply -f` locally. This creates conflicting field managers. Recently:
- `kubectl apply` claims ownership of `spec.replicas`
- Flux also claims ownership and overwrites with Git truth
- Result: Replicas kept oscillating between values

How would you diagnose this and implement conflict resolution?

**Senior DevOps Answer:**

This is a **field manager conflict** - modern Kubernetes (1.18+) uses `server-side apply` to track ownership.

**Understanding Field Managers:**

```bash
# View field manager ownership
$ kubectl get deployment web-app -n production -o json | jq '.metadata.managedFields'

[
  {
    "apiVersion": "apps/v1",
    "fieldsV1": {
      "f:metadata": {
        "f:labels": {...},
        "f:annotations": {...}
      },
      "f:spec": {
        "f:replicas": {}      # kubectl apply claims this
      }
    },
    "manager": "kubectl",                    # ← Local developer
    "operation": "Update",
    "time": "2026-03-06T10:30:00Z"
  },
  {
    "apiVersion": "apps/v1",
    "fieldsV1": {
      "f:spec": {
        "f:selector": {},
        "f:template": {}       # Flux claims these
      }
    },
    "manager": "flux",                       # ← GitOps controller
    "operation": "Apply",
    "time": "2026-03-06T10:32:00Z"
  }
]
```

**Conflict Scenario Explained:**

```yaml
# Git truth (Flux manages)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3         # ← Flux declares

# Developer runs locally
$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 5         # ← Developer overrides
EOF

# Result:
# Time 1: kubectl apply (client-side merge) sets to 5
# Time 2: Flux resync (server-side apply) sets to 3
# Time 3: Developer reapplies, sets to 5
# → Oscillation
```

**Diagnosis: Check Managed Fields**

```bash
#!/bin/bash
# diagnose-field-conflicts.sh

echo "=== Check Field Managers ==="
kubectl get deployment web-app -n production -o json | \
  jq -r '.metadata.managedFields[] | "\(.manager): \(.operation) at \(.time)"'

echo ""
echo "=== Which Manager Controls replicas? ==="
kubectl get deployment web-app -n production -o json | \
  jq '.metadata.managedFields[] | select(.fieldsV1 | has("f:spec")) | 
    {manager: .manager, claims_replicas: (.fieldsV1["f:spec"]["f:replicas"] != null)}'

echo ""
echo "=== Conflict Indicators ==="
# Look for:
# 1. Multiple managers claiming same field
# 2. Rapid timestamp changes (oscillation)
# 3. Different operation types (Apply vs Update)

echo ""
echo "=== Check Deployment Conditions ==="
kubectl describe deployment web-app -n production | grep -A 20 Conditions
```

**Solution 1: Exclusive Field Manager (Recommended)**

```yaml
# flux-config.yaml - Enforce Flux as sole manager
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: web-app
  namespace: flux-system
spec:
  releaseName: web-app
  targetNamespace: production
  chart:
    spec:
      chart: web-app
      version: "1.2.3"
  values:
    replicaCount: 3
  install:
    crds: Create
  upgrade:
    crds: CreateReplace
  # CRITICAL: Force server-side apply
  postRenderers:
  - kustomize:
      patchesStrategicMerge:
      - apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: web-app
        spec:
          replicas: 3  # Flux manages exclusively
---
# kubectl configuration to prevent local applies
apiVersion: v1
kind: ConfigMap
metadata:
  name: kubectl-config
data:
  prevent-local-applies.sh: |
    #!/bin/bash
    # Git pre-commit hook to prevent local applies
    
    if git diff --cached --name-only | grep -E '\.yaml|\.yml'; then
      echo "ERROR: Cannot apply Kubernetes manifests directly"
      echo "Reason: All manifests managed by Flux"
      echo ""
      echo "Correct workflow:"
      echo "  1. Edit manifest"
      echo "  2. Commit to Git"
      echo "  3. Flux automatically syncs (~2 minutes)"
      echo ""
      echo "For emergencies, use sealed mode:"
      echo "  kubectl annotate deployment <name> 'gitops.example.com/sealed=true'"
      echo ""
      exit 1
    fi
```

**Solution 2: Server-Side Apply (Modern Approach)**

```bash
#!/bin/bash
# use-server-side-apply.sh

# Instead of: kubectl apply -f manifest.yaml
# Use (kubectl 1.18+):
kubectl apply -f manifest.yaml --server-side --force-conflicts

# This:
# 1. Sends ALL fields to server
# 2. Server determines ownership
# 3. Enforces single manager per field
# 4. Fails if conflict detected (doesn't silently overwrite)

# When conflicts exist:
$ kubectl apply -f manifest.yaml --server-side --force-conflicts
# Output: error: Apply failed with X conflicting fields: [spec.replicas]
# This forces you to resolve conflict

# Resolve by removing field:
$ kubectl patch deployment web-app --type merge -p \
  '{"metadata":{"managedFields":[{"fieldsV1":{"f:spec":{"f:replicas":{}}}}]}}'
# ^ This removes kubectl's claim on replicas
```

**Solution 3: Finalizer-Based Conflict Prevention**

```python
#!/usr/bin/env python3
# conflict-prevention-webhook.py

from flask import Flask, request, jsonify
import json

app = Flask(__name__)

FINALIZER = "gitops.example.com/flux-manager"

@app.route('/validate', methods=['POST'])
def validate_apply(req):
    """
    ValidatingWebhook: Prevent non-Flux managers from modifying
    Flux-managed fields.
    """
    
    admission_review = request.get_json()
    obj = admission_review['request']['object']
    
    # Check if Flux manages this resource
    finalizers = obj.get('metadata', {}).get('finalizers', [])
    
    if FINALIZER not in finalizers:
        # Not Flux-managed, allow
        return approve_webhook(admission_review)
    
    # User trying to apply?
    manager = admission_review['request'].get('userInfo', {}).get('username')
    
    if manager == 'system:serviceaccount:flux-system:flux':
        # Flux is allowed
        return approve_webhook(admission_review)
    
    # Non-Flux user trying to modify?
    admission_review['response'] = {
        'allowed': False,
        'status': {
            'message': f"Resource managed by Flux (finalizer: {FINALIZER}). "
                       "Apply changes via Git instead. "
                       "For emergencies, contact Platform team."
        }
    }
    
    return jsonify(admission_review), 403

def approve_webhook(review):
    review['response'] = {'allowed': True}
    return jsonify(review), 200

if __name__ == '__main__':
    app.run(ssl_context='adhoc', port=8443)
```

**Conflict Resolution Checklist:**

```bash
#!/bin/bash
# resolve-field-conflicts.sh

echo "Step 1: Identify conflicting fields"
kubectl get deployment web-app -o json | \
  jq -r '.metadata.managedFields[] | select(.manager != "flux") | .manager'
# Output: kubectl, helm, etc.

echo ""
echo "Step 2: Remove non-Flux managers"
# Option A: Delete and reapply
kubectl delete deployment web-app
kubectl apply -f <(git show HEAD:deployment.yaml)

# Option B: Clear field manager (1.20+)
kubectl apply -f manifest.yaml --server-side --force-conflicts --overwrite

echo ""
echo "Step 3: Verify single manager"
kubectl get deployment web-app -o json | \
  jq '.metadata.managedFields | length'  # Should be 1

echo ""
echo "Step 4: Enable Flux finalizer"
kubectl patch deployment web-app -p \
  '{"metadata":{"finalizers":["gitops.example.com/flux-manager"]}}'

echo ""
echo "Step 5: Verify no future conflicts"
watch 'kubectl get deployment web-app -o json | jq ".metadata.managedFields | length"'
```

**Best Practices:**
- **One manager per resource type** - designate Flux as sole manager
- **Use server-side apply (--server-side)** for explicit field ownership
- **Document in runbooks** - what to do if developers bypass Flux
- **Implement ValidatingWebhook** to prevent manual applies on Flux resources
- **Track who last modified** - for debugging
- **Test conflict resolution** - in non-prod first

---

### Q9: A/B Testing Implementation at Object Level

**Question:**
You want to run A/B tests on your checkout service without using Istio/service mesh. Using only Kubernetes objects (labels, selectors, Services), design a system where 10% of traffic routes to version B and 90% to version A. How would you implement this and what are the limitations?

**Senior DevOps Answer:**

You can approximate A/B testing using **label-based Pod count ratios** without a service mesh, but it requires careful design.

**Core Mechanism: Replica-Based Traffic Steering**

```yaml
# Version A: 9 replicas = 90% traffic
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-a
  namespace: production
  labels:
    app: checkout
    variant: a
    traffic-split: "90"  # For documentation
spec:
  replicas: 9  # 9 Pods out of 10
  selector:
    matchLabels:
      app: checkout
      variant: a
  template:
    metadata:
      labels:
        app: checkout
        variant: a
        ab-test-group: "control"
    spec:
      containers:
      - name: checkout
        image: checkout:v1.0  # Version A (stable)
        env:
        - name: VARIANT
          value: "a"
        - name: METRICS_LABEL
          value: "ab_test_variant=a"
---
# Version B: 1 replica = 10% traffic
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-b
  namespace: production
  labels:
    app: checkout
    variant: b
    traffic-split: "10"  # For documentation
spec:
  replicas: 1  # 1 Pod out of 10
  selector:
    matchLabels:
      app: checkout
      variant: b
  template:
    metadata:
      labels:
        app: checkout
        variant: b
        ab-test-group: "experiment"
    spec:
      containers:
      - name: checkout
        image: checkout:v1.1  # Version B (experimental)
        env:
        - name: VARIANT
          value: "b"
        - name: METRICS_LABEL
          value: "ab_test_variant=b"
---
# Service: Load-balances across ALL checkout Pods
# Traffic ratio = Pod count ratio
apiVersion: v1
kind: Service
metadata:
  name: checkout-service
  namespace: production
  labels:
    app: checkout
    tier: api
spec:
  type: LoadBalancer
  selector:
    app: checkout  # Matches BOTH variant A and B
    # Note: NO variant: label selector - includes all
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  sessionAffinity: ClientIP  # Sticky sessions (optional)
  sessionAffinityTimeout: 3600  # 1 hour
---
# ServiceMonitor : Track variant-specific metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: checkout-ab-test
  namespace: production
spec:
  selector:
    matchLabels:
      app: checkout
  endpoints:
  - port: metrics
    interval: 30s
    relabelings:
    # Extract variant from Pod label
    - source_labels: [__meta_kubernetes_pod_label_variant]
      target_label: variant
    - source_labels: [__meta_kubernetes_pod_label_ab_test_group]
      target_label: test_group
```

**Traffic Distribution Verification:**

```bash
#!/bin/bash
# verify-ab-traffic-split.sh

echo "=== Verify Pod Count Ratio ==="
echo "Version A (stable):"
kubectl get pods -l variant=a -n production --no-headers | wc -l
# Expected: 9

echo "Version B (experimental):"
kubectl get pods -l variant=b -n production --no-headers | wc -l
# Expected: 1

echo ""
echo "=== Verify Service Selects Both ==="
kubectl get endpoints checkout-service -n production -o yaml | grep -A20 subsets
# Should show ~10 total Pod IPs

echo ""
echo "=== Monitor Request Distribution ==="
# Query Prometheus to verify traffic split
echo "10-second traffic sample:"
curl -s 'http://prometheus:9090/api/v1/query' \
  --data-urlencode 'query=rate(http_requests_total{variant=~"a|b"}[10s])' | \
  jq '.data.result[] | {variant: .metric.variant, rate: .value[1]}'

# Expected output:
# {"variant": "a", "rate": "900"}    # ~90%
# {"variant": "b", "rate": "100"}    # ~10%

echo ""
echo "=== Error Rate Comparison ==="
curl -s 'http://prometheus:9090/api/v1/query' \
  --data-urlencode 'query=rate(http_errors_total{variant=~"a|b"}[5m]) / rate(http_requests_total{variant=~"a|b"}[5m])' | \
  jq '.data.result[] | {variant: .metric.variant, error_rate: .value[1]}'
```

**Scaling the Traffic Split:**

```python
#!/usr/bin/env python3
# auto-scale-ab-test.py
# Automatically adjust replica ratio based on error rates

from kubernetes import client, config
import requests
import json
from datetime import datetime

config.load_incluster_config()
apps_v1 = client.AppsV1Api()

PROMETHEUS_URL = "http://prometheus:9090/api/v1/query"
NAMESPACE = "production"

def get_error_rate(variant):
    """Query error rate for variant from Prometheus."""
    query = f'rate(http_errors_total{{variant="{variant}"}}[5m]) / rate(http_requests_total{{variant="{variant}"}}[5m])'
    
    resp = requests.get(PROMETHEUS_URL, params={'query': query})
    data = resp.json()['data']['result']
    
    if data:
        return float(data[0]['value'][1])
    return 0

def adjust_ab_split():
    """Adjust replica counts based on error rates."""
    
    error_a = get_error_rate('a')
    error_b = get_error_rate('b')
    
    print(f"[{datetime.now()}] Error rates: A={error_a:.4f}, B={error_b:.4f}")
    
    # Decision logic:
    # If B's error rate > A + threshold → reduce B traffic
    # If B's error rate < A - threshold → increase B traffic
    
    ERROR_THRESHOLD = 0.02  # 2% difference
    MAX_B_REPLICAS = 5      # Don't exceed 50% traffic
    MIN_B_REPLICAS = 1      # Keep for testing
    
    current_b = apps_v1.read_namespaced_deployment('checkout-b', NAMESPACE)
    current_replicas = current_b.spec.replicas
    
    if error_b > error_a + ERROR_THRESHOLD:
        # B is worse, reduce traffic
        new_replicas = max(MIN_B_REPLICAS, current_replicas - 1)
        print(f"B error rate too high. Reducing from {current_replicas} to {new_replicas} replicas")
    elif error_b < error_a - ERROR_THRESHOLD:
        # B is better, increase traffic (cautiously)
        new_replicas = min(MAX_B_REPLICAS, current_replicas + 1)
        print(f"B error rate acceptable. Increasing from {current_replicas} to {new_replicas} replicas")
    else:
        print(f"A/B split within tolerance. Keeping {current_replicas} replicas for B")
        return
    
    # Apply change
    current_b.spec.replicas = new_replicas
    apps_v1.patch_namespaced_deployment('checkout-b', NAMESPACE, current_b)
    print(f"Updated checkout-b to {new_replicas} replicas (total: {10 - new_replicas}+{new_replicas})")

if __name__ == '__main__':
    adjust_ab_split()
```

**Limitations of Label-Based A/B Testing:**

```
✓ Advantages:
  - No additional components (no Istio/service mesh)
  - Simple to understand and debug
  - Native Kubernetes objects only
  - Easy to monitor (per-Pod metrics)

✗ Limitations:
  - Traffic ratio = replica ratio only (can't do precise 99/1 split)
  - Cannot do per-request decisions (all traffic from client A goes to A)
  - No gradual canary (must jump by 1 replica increments)
  - Requires sticky sessions for user consistency (sessionAffinity)
  - Client IP-based affinity can't handle proxies/load balancers
  - Replicating at scale: 90/10 split = 90+10 Pod minimum
```

**When to Use vs. Service Mesh:**

| Scenario | Label-Based | Service Mesh |
|----------|------------|-------------|
| Quick A/B test (10-20 min) | ✓ | ✗ (overhead) |
| Precise traffic (e.g., 5%) | ✗ | ✓ |
| Per-user affinity needed | ✓ | ✓ |
| Production canary rollout | ✗ | ✓ |
| Multi-cluster A/B testing | ✗ | ✓ (with federation) |
| Minimal infrastructure | ✓ | ✗ |

**Best Practices:**
- **Use label-based for small-scale testing** (pilot features to internal users)
- **Graduate to service mesh for production canaries** (precise control needed)
- **Always tag Pods with ab_test_group label** - for filtering in dashboards
- **Monitor error rates per variant** - automated rollback if B degrades
- **Test with real traffic volume** - don't test with 1% of production scale
- **Document rollback procedure** - how to failover if test goes wrong

---

### Q10: Multi-Tenant Isolation Patterns - RBAC + NetworkPolicy + ResourceQuota

**Question:**
Different customers should be completely isolated. Customer A should never see Customer B's data, and their workloads shouldn't compete for resources. How would you layer RBAC, NetworkPolicy, and ResourceQuota to enforce this?

**Senior DevOps Answer:**

Multi-tenancy requires **three-layer defense**:
1. **RBAC** - Who can do what (API access control)
2. **NetworkPolicy** - Which Pods can talk to which Pods (network segmentation)
3. **ResourceQuota / LimitRange** - Resource fairness (prevent noisy neighbors)

**Full Multi-Tenant Architecture:**

```yaml
# Layer 1: Namespace Isolation
apiVersion: v1
kind: Namespace
metadata:
  name: customer-acme
  labels:
    tenant-id: acme
    environment: production
    isolation-level: strict  # For validation webhooks
  annotations:
    tenant.example.com/owner: "admin@acme.com"
    tenant.example.com/billing-contact: "billing@acme.com"
    tenant.example.com/support-tier: "enterprise"
---
# Layer 2a: RBAC - ServiceAccount with minimal permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-runner
  namespace: customer-acme
  labels:
    tenant-id: acme
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-runner
  namespace: customer-acme
rules:
# Only allow read-only access to in-namespace resources
- apiGroups: [""]
  resources: [pods, services, configmaps]
  verbs: [get, list, watch]
- apiGroups: ["apps"]
  resources: [deployments, statefulsets]
  verbs: [get, list, watch]
# Deny cross-namespace access
# Deny cluster-wide resources (nodes, pv, namespaces)
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-runner
  namespace: customer-acme
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-runner
subjects:
- kind: ServiceAccount
  name: app-runner
  namespace: customer-acme
---
# Layer 2b: Network Policy - Deny all by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: customer-acme-default-deny
  namespace: customer-acme
  labels:
    tenant-id: acme
spec:
  podSelector: {}  # Applies to all Pods
  policyTypes:
  - Ingress
  - Egress
  # Deny all traffic (implicit)
---
# Allow in-namespace traffic only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: customer-acme-internal
  namespace: customer-acme
spec:
  podSelector: {}  # All Pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: customer-acme  # Only same namespace
    - podSelector: {}         # Any Pod in this namespace
---
# Allow egress to DNS and kube-dns only (for service discovery)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: customer-acme-dns-only
  namespace: customer-acme
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53  # DNS
---
# Layer 3: ResourceQuota - Prevent resource hogging
apiVersion: v1
kind: ResourceQuota
metadata:
  name: customer-acme-quota
  namespace: customer-acme
spec:
  hard:
    # Pod limits
    pods: "50"                    # Max 50 Pods
    
    # CPU limits (sum of all Pod requests + limits)
    requests.cpu: "10"            # Max 10 vCPU total
    limits.cpu: "20"              # Max 20 vCPU limit
    
    # Memory limits
    requests.memory: "100Gi"      # Max 100 GB requested
    limits.memory: "200Gi"        # Max 200 GB limited
    
    # Storage
    requests.storage: "1Ti"       # Max 1 TB PVC requests
    
    # API objects
    persistentvolumeclaims: "20"  # Max 20 PVCs
    deployments.apps: "20"        # Max 20 Deployments
    statefulsets.apps: "10"       # Max 10 StatefulSets
    services.loadbalancers: "2"   # Max 2 LoadBalancers
    services.nodeports: "0"       # NO NodePort services
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values: ["default"]  # Only applies to default priority Pods
---
# Layer 4: LimitRange - Per-Pod constraints
apiVersion: v1
kind: LimitRange
metadata:
  name: customer-acme-limits
  namespace: customer-acme
spec:
  limits:
  # Per container limits
  - type: Container
    max:
      cpu: "4"                # No Pod can request >4 CPU
      memory: "8Gi"           # No Pod can request >8GB
    min:
      cpu: "100m"             # Minimum CPU request
      memory: "128Mi"         # Minimum memory request
    default:  # If container doesn't specify limits
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:  # If container doesn't specify requests
      cpu: "100m"
      memory: "128Mi"
  
  # Per Pod limits
  - type: Pod
    max:
      cpu: "8"                # Total across all containers
      memory: "16Gi"
---
# Validation Webhook: Ensure tenant metadata
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: tenant-validation
webhooks:
- name: tenant-labels.example.com
  rules:
  - operations: [CREATE, UPDATE]
    apiGroups: ["*"]
    apiVersions: ["*"]
    resources: ["*"]
  admissionReviewVersions: ["v1"]
  clientConfig:
    service:
      name: tenant-validator
      namespace: kube-system
      path: "/validate"
    caBundle: <base64-encoded-ca>
  failurePolicy: Fail  # Reject if validation fails
  timeoutSeconds: 5
  sideEffects: None
  # Only validate in tenant namespaces
  namespaceSelector:
    matchLabels:
      isolation-level: strict
```

**Multi-Tenant Isolation Verification:**

```bash
#!/bin/bash
# verify-multi-tenant-isolation.sh

echo "=== Test 1: RBAC Isolation ==="
echo "Attempt to list Pods in different namespace:"
kubectl get pods -n customer-example \
  --as=system:serviceaccount:customer-acme:app-runner
# Expected: Error - no access

echo ""
echo "=== Test 2: Network Policy Isolation ==="
echo "Launch test Pod in customer-acme:"
kubectl run debug --image=busybox -n customer-acme -- sleep 3600
sleep 5

echo "Try to reach Pod in different namespace:"
kubectl exec -it debug -n customer-acme -- \
  wget -O- http://test-pod.other-tenant.svc.cluster.local
# Expected: Timeout/connection refused (NetworkPolicy denies)

echo ""
echo "=== Test 3: ResourceQuota Enforcement ==="
echo "Current ResourceQuota usage:"
kubectl describe resourcequota -n customer-acme

echo ""
echo "Try to exceed CPU quota:"
for i in {1..15}; do
  kubectl create deployment large-$i \
    --image=nginx \
    --replicas=1 \
    -n customer-acme
done
# After ~10 deployments, quota enforcement prevents more

echo ""
echo "=== Test 4: Storage Isolation ==="
echo "List PVCs in namespace:"
kubectl get pvc -n customer-acme

echo ""
echo "=== Test 5: Cross-Tenant Traffic Test ==="
echo "From customer-acme, try to reach customer-example DNS:"
kubectl exec -it debug -n customer-acme -- \
  nslookup service.customer-example.svc.cluster.local
# Should still resolve (DNS allowed)
echo "But try HTTP connection:"
kubectl exec -it debug -n customer-acme -- \
  curl -m 5 http://service.customer-example.svc.cluster.local
# Should timeout (NetworkPolicy blocks)
```

**Failure Scenarios and Mitigations:**

```yaml
# Scenario 1: Customer creates privileged Pod
apiVersion: v1
kind: Pod
metadata:
  name: privilege-escalation-attempt
  namespace: customer-acme
spec:
  securityContext:
    privileged: true  # ← Violates security standards
  containers:
  - name: malicious
    image: node
---
# Prevention: PodSecurityPolicy (deprecated in 1.25, use PSS)
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-multi-tenant
spec:
  privileged: false         # Deny privileged Pods
  allowPrivilegeEscalation: false
  requiredDropCapabilities: [ALL]
  volumes: ["configMap", "emptyDir", "secret"]  # Whitelist safe volumes
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: "MustRunAsNonRoot"
  seLinux:
    rule: "MustRunAs"
  fsGroup:
    rule: "RunAsAny"
---
# Scenario 2: Customer escapes via kubelet API
# Mitigation: Disable kubelet on worker nodes for tenant Pods
# (Only used by system components)
```

**Multi-Tenant Monitoring:**

```yaml
# Monitor per-tenant resource usage
apiVersion: v1
kind: ConfigMap
metadata:
  name: tenant-monitoring
  namespace: monitoring
data:
  queries.yaml: |
    tenant_cpu_usage:
      query: 'sum by (namespace) (rate(container_cpu_usage_seconds_total[5m]))'
    
    tenant_memory_usage:
      query: 'sum by (namespace) (container_memory_usage_bytes)'
    
    tenant_api_calls:
      query: 'sum by (namespace) (rate(apiserver_request_total[5m]))'
    
    tenant_network_in:
      query: 'sum by (namespace) (rate(container_network_receive_bytes_total[5m]))'
    
    quota_remaining:
      query: 'kube_resourcequota_created / kube_resourcequota_created'
```

**Best Practices:**
- **Default deny** - Always start with NetworkPolicy deny-all, then allow specific traffic
- **Separate teams per namespace** - One namespace = one customer/team
- **Test isolation in staging** - Verify no cross-tenant leaks before prod
- **Audit all changes** - Enable audit logging for sensitive namespaces
- **Monitor noisy neighbors** - Alert if tenant exceeds resource quota
- **Regular penetration testing** - Verify isolation holds

---

### Q11: Database Failover Using ConfigMap-Based Connection Pooling

**Question:**
Your StatefulSet connects to an external managed database (RDS, Cloud SQL) via a connection string in a ConfigMap. During a failover from primary to replica, the connection string changes. How do you handle this without restarting all Pod connections? What happens to in-flight transactions?

**Senior DevOps Answer:**

This requires **connection pool coordination** - you can't rely on simple ConfigMap reloads.

**Architecture: Two-Tier Connection Management**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-endpoints
  namespace: production
  labels:
    app: api
    tier: data
data:
  # Primary connection string
  primary-host: "primary.db.internal"    # Can be changed during failover
  primary-port: "5432"
  
  # Read replica (for read-only queries)
  replica-host: "replica.db.internal"
  replica-port: "5432"
  
  # Connection pool settings
  pool-size: "20"
  connection-timeout-ms: "5000"
  idle-timeout-ms: "300000"
  
  # Failover configuration
  failover-enabled: "true"
  failover-detection-interval-ms: "10000"
  retry-attempts: "3"
  retry-backoff-ms: "1000"
---
# StatefulSet using ConfigMap for DB connection
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: api-server
  namespace: production
spec:
  serviceName: api-server
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        db-failover-aware: "true"
    spec:
      serviceAccountName: api-server
      terminationGracePeriodSeconds: 30
      
      # Init container: Set up connection pooler
      initContainers:
      - name: setup-pgbouncer
        image: pgbouncer:1.16
        volumeMounts:
        - name: pgbouncer-config
          mountPath: /etc/pgbouncer
        - name: pgbouncer-runtime
          mountPath: /var/run/pgbouncer
      
      containers:
      # Main application
      - name: api
        image: api:v2.1
        env:
        # Read from ConfigMap (gets updated on failover)
        - name: DB_PRIMARY_HOST
          valueFrom:
            configMapKeyRef:
              name: db-endpoints
              key: primary-host
        - name: DB_PRIMARY_PORT
          valueFrom:
            configMapKeyRef:
              name: db-endpoints
              key: primary-port
        - name: DB_CONNECTION_STRING
          value: "postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_PRIMARY_HOST):$(DB_PRIMARY_PORT)/mydb?sslmode=require"
        
        # Health check sensitive to connection status
        livenessProbe:
          httpGet:
            path: /health/db
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
      
      # Sidecar: Failover detection and routing
      - name: failover-manager
        image: failover-manager:v1
        env:
        - name: PRIMARY_HOST
          valueFrom:
            configMapKeyRef:
              name: db-endpoints
              key: primary-host
        - name: REPLICA_HOST
          valueFrom:
            configMapKeyRef:
              name: db-endpoints
              key: replica-host
        volumeMounts:
        - name: failover-state
          mountPath: /var/failover
        # Monitors DB health, triggers ConfigMap update on failover
      
      volumes:
      - name: pgbouncer-config
        configMap:
          name: pgbouncer-config
      - name: pgbouncer-runtime
        emptyDir: {}
      - name: failover-state
        emptyDir: {}
---
# ConfigMap: Connection pooler configuration
apiVersion: v1
kind: ConfigMap
metadata:
  name: pgbouncer-config
  namespace: production
data:
  pgbouncer.ini: |
    [databases]
    mydb = host=DB_PRIMARY_HOST port=5432 user=app password=app_pass
    
    [pgbouncer]
    pool_mode = transaction  # Release conn after each transaction
    max_client_conn = 100
    default_pool_size = 20
    min_pool_size = 5
    reserve_pool_size = 5
    reserve_pool_timeout = 5
```

**Sidecar Controller: Detect Failover and Update ConfigMap**

```python
#!/usr/bin/env python3
# failover-manager.py - Sidecar container

import os
import psycopg2
import json
from kubernetes import client, config
from datetime import datetime
import time

config.load_incluster_config()
v1 = client.CoreV1Api()

PRIMARY_HOST = os.getenv('PRIMARY_HOST')
REPLICA_HOST = os.getenv('REPLICA_HOST')
NAMESPACE = 'production'
POD_NAME = os.getenv('HOSTNAME')

def check_database_health(host, port=5432):
    """Check if database is responding."""
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database='mydb',
            connect_timeout=5
        )
        conn.close()
        return True
    except Exception as e:
        print(f"Health check failed for {host}: {e}")
        return False

def get_primary_status():
    """Get current primary from ConfigMap."""
    cm = v1.read_namespaced_config_map('db-endpoints', NAMESPACE)
    return cm.data.get('primary-host')

def update_primary(new_host):
    """Update ConfigMap with new primary (triggers Pod failover)."""
    cm = v1.read_namespaced_config_map('db-endpoints', NAMESPACE)
    
    print(f"[{datetime.now()}] FAILOVER TRIGGERED: {cm.data['primary-host']} → {new_host}")
    
    # Update ConfigMap
    cm.data['primary-host'] = new_host
    cm.metadata.annotations = cm.metadata.annotations or {}
    cm.metadata.annotations['failover.example.com/last-failover'] = datetime.now().isoformat()
    cm.metadata.annotations['failover.example.com/triggered-by'] = POD_NAME
    
    v1.patch_namespaced_config_map('db-endpoints', NAMESPACE, cm)
    
    # Log event for audit trail
    event = client.V1Event(
        metadata=client.V1ObjectMeta(
            name=f'db-failover-{datetime.now().strftime("%s")}',
            namespace=NAMESPACE
        ),
        reason='DatabaseFailover',
        message=f'Primary database changed from {cm.data["primary-host"]} to {new_host}',
        involved_object=client.V1ObjectReference(
            kind='ConfigMap',
            name='db-endpoints',
            namespace=NAMESPACE
        ),
        type='Warning'
    )
    # v1.create_namespaced_event(NAMESPACE, event)

def monitor_failover():
    """Continuously monitor primary DB health."""
    
    consecutive_failures = 0
    FAILURE_THRESHOLD = 3  # Trigger failover after 3 consecutive failures
    
    while True:
        current_primary = get_primary_status()
        
        # Check if primary is healthy
        if check_database_health(current_primary):
            consecutive_failures = 0
            print(f"[{datetime.now()}] Primary {current_primary} is healthy")
        else:
            consecutive_failures += 1
            print(f"[{datetime.now()}] Primary {current_primary} health check failed ({consecutive_failures}/{FAILURE_THRESHOLD})")
            
            if consecutive_failures >= FAILURE_THRESHOLD:
                # Promote replica to primary
                replica_healthy = check_database_health(REPLICA_HOST)
                
                if replica_healthy:
                    print(f"[{datetime.now()}] Primary failed, replica {REPLICA_HOST} is healthy. PROMOTING...")
                    update_primary(REPLICA_HOST)
                    consecutive_failures = 0
                else:
                    print(f"[{datetime.now()}] Both primary and replica unhealthy! Manual intervention required.")
                    # Alert operations team
        
        time.sleep(10)  # Check every 10 seconds

if __name__ == '__main__':
    print(f"[{datetime.now()}] Failover manager starting...")
    monitor_failover()
```

**In-Flight Transaction Handling:**

```python
# In Application Code
import psycopg2
from psycopg2 import OperationalError
from os import getenv
import time

class FailoverAwareConnPool:
    def __init__(self):
        self.conn = None
        self.retries = 0
        self.max_retries = 3
    
    def get_connection(self):
        """Get database connection with failover support."""
        
        for attempt in range(self.max_retries):
            try:
                host = getenv('DB_PRIMARY_HOST')  # Read fresh from env
                port = getenv('DB_PRIMARY_PORT')
                
                self.conn = psycopg2.connect(
                    host=host,
                    port=port,
                    user=getenv('DB_USER'),
                    password=getenv('DB_PASSWORD'),
                    connect_timeout=5
                )
                
                self.conn.autocommit = False  # Manual transaction control
                self.retries = 0
                return self.conn
            
            except OperationalError as e:
                self.retries += 1
                wait_time = 2 ** self.retries  # Exponential backoff
                print(f"Connection failed (attempt {attempt+1}): {e}. Retry in {wait_time}s")
                time.sleep(wait_time)
        
        raise Exception(f"Failed to connect after {self.max_retries} retries")
    
    def execute_transaction(self, queries):
        """Execute transaction with failover recovery."""
        
        max_transaction_retries = 3
        
        for attempt in range(max_transaction_retries):
            conn = self.get_connection()
            cursor = conn.cursor()
            
            try:
                # Begin transaction
                cursor.execute('BEGIN')
                
                # Execute all queries
                for query in queries:
                    cursor.execute(query)
                
                # Commit
                cursor.execute('COMMIT')
                conn.commit()
                
                print(f"Transaction committed successfully")
                return True
            
            except OperationalError as e:
                # Connection lost during transaction (failover happened)
                print(f"Transaction interrupted: {e}")
                try:
                    cursor.execute('ROLLBACK')
                    conn.rollback()
                except:
                    pass  # Connection already closed
                
                if attempt < max_transaction_retries - 1:
                    print(f"Retrying transaction (attempt {attempt+1}...)")
                    time.sleep(2 ** attempt)
                    continue
                else:
                    raise Exception(f"Transaction failed after {max_transaction_retries} attempts")
            
            finally:
                if cursor:
                    cursor.close()
                if conn:
                    conn.close()
```

**Verification and Testing:**

```bash
#!/bin/bash
# test-db-failover.sh

echo "=== Monitor Failover Process ==="
echo "Terminal 1: Watch ConfigMap"
watch kubectl get configmap db-endpoints -n production -o jsonpath='{.data.primary-host}'

echo ""
echo "Terminal 2: Trigger Failover"
echo "Simulate primary DB outage (in real env)"
kubectl patch configmap db-endpoints -n production -p \
  '{"data":{"primary-host":"replica.db.internal"}}'

echo ""
echo "Terminal 3: Monitor Pod Logs"
kubectl logs -f -l app=api -n production -c failover-manager

echo ""
echo "=== Verify Transaction Recovery ==="
echo "Check if any transactions failed:"
kubectl logs -l app=api -n production -c api | grep -i "rollback\|transaction failed" | wc -l
```

**Best Practices:**
- **Sideca rcontainers for monitoring** - Don't embed failover logic in app
- **ConfigMap for connection strings** - Allows dynamic updates without redeployment
- **Connection pooling required** - Single connection can't survive failover
- **Exponential backoff on retry** - Prevent hammering failed database
- **Transaction-level retry logic** - Catch OperationalError and retry
- **Test failovers regularly** - Don't discover issues in production

---

### Q12: Custom Scheduling via Labels vs. Node Names

**Question:**
Your Pods can be scheduled based on labels (nodeSelector, node affinity) or explicit node names. When would you use each, and what are the failure modes? What happens if you mix both approaches?

**Senior DevOps Answer:**

These are **fundamentally different strategies** with different guarantees:

**Node Names (Explicit):**
- **Binding**: Hard binding to specific node
- **Flexibility**: Zero (will not schedule if node doesn't exist or is unreachable)
- **Scale**: Breaks when nodes are replaced
- **Use case**: Debugging, specific hardware requirements (GPU), air-gapped environments

**Labels (Flexible):**
- **Binding**: Soft binding to node sets matching criteria
- **Flexibility**: High (can match any node with labels)
- **Scale**: Survives node replacement, cluster scaling
- **Use case**: Production workloads, cross-cloud/multi-region

**Comparison Table:**

```yaml
# Scenario 1: Hard binding to GPU node
apiVersion: v1
kind: Pod
metadata:
  name: gpu-training
spec:
  # Option A: Node name (NOT RECOMMENDED)
  nodeName: gpu-node-1  # ← Direct reference breaks:
                        # - If node deleted
                        # - If node renamed
                        # - During cluster upgrades
                        # - In multi-cloud
  
  # Option B: Label selector (RECOMMENDED)
  nodeSelector:
    accelerator: nvidia-gpu        # ← All nodes with this label
    machine-type: p3.8xlarge       # ← Can scale horizontally
  
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/arch
            operator: In
            values: [amd64]  # Cross-node compatibility
          - key: kubernetes.io/os
            operator: In
            values: [linux]
  
  containers:
  - name: training
    image: ml-training:latest
    resources:
      requests:
        nvidia.com/gpu: 1  # Request GPU resource
---
# Scenario 2: Zone-specific scheduling
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-zone-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      # Anti-affinity: Spread across zones
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - api
              topologyKey: topology.kubernetes.io/zone  # ← Spread across AZs
        
        nodeAffinity:
          # Prefer nodes in specific zones (doesn't hardcode node names)
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                - us-east-1a
                - us-east-1b
                - us-east-1c
---
# Scenario 3: ANTI-PATTERN - Mixing both
spec:
  nodeName: specific-node-123  # ← Hard binding
  nodeSelector:
    zone: us-east-1  # ← Will be ignored if node doesn't have label!
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        # This will conflict with nodeName
---
# Scenario 4: Debugging-only use of nodeName
metadata:
  name: debug-pod
spec:
  nodeName: debug-node  # Only for debugging, not production
  containers:
  - name: debug
    image: ubuntu
    command: [sleep, 3600]
```

**Failure Mode: Mixing nodeName + nodeSelector**

```bash
# Pod spec has BOTH:
spec:
  nodeName: gpu-node-1
  nodeSelector:
    zone: us-west-2

# What happens:
$ kubectl apply -f pod.yaml
$ kubectl get pod
NAME        READY   STATUS      RESTARTS   AGE
debug-pod   0/1     Pending     0          2m

# Why pending?
$ kubectl describe pod debug-pod
Status:  Pending
Wait for conditions to be accepted:
  Type          Status  Message
  ----          ------  -------
  Ready         False   Pod cannot be scheduled

Events:
Type    Reason             Message
----    ------             -------
Warning  FailedScheduling   0/10 nodes are suitable (node name "gpu-node-1" does not match nodeSelector zone: us-west-2)

# Issue:
# 1. nodeName forces scheduling to "gpu-node-1"
# 2. nodeSelector requires "zone: us-west-2"
# 3. If gpu-node-1 is in us-east-1, constraint conflict
# 4. Pod stuck in Pending
```

**Correct Label-Based Scheduling:**

```yaml
apiVersion: v1
kind: Node
metadata:
  name: gpu-node-1
  labels:
    # Standard Kubernetes labels (auto-added)
    kubernetes.io/hostname: gpu-node-1
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
    
    # Custom labels (added by infrastructure team)
    accelerator: nvidia-a100      # Hardware
    workload-type: ml-training    # Workload purpose
    zone: us-east-1c              # Location
    cost-type: on-demand          # Billing
    maintenance-window: sat-sun    # Maintenance rules
spec:
  # Taints prevent scheduling unless explicitly tolerated
  taints:
  - key: gpu
    value: "true"
    effect: NoSchedule  # Only Pods with matching toleration
---
# Pod that can schedule on GPU node
apiVersion: v1
kind: Pod
metadata:
  name: ml-job
spec:
  nodeSelector:
    accelerator: nvidia-a100  # Flexible - any GPU A100 node
    zone: us-east-1c          # Optional - prefer this zone
  
  tolerations:  # Required because node has taints
  - key: gpu
    operator: Equal
    value: "true"
    effect: NoSchedule
  
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: accelerator
            operator: In
            values: [nvidia-a100]
      
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100  # Prefer on-demand (cheaper)
        preference:
          matchExpressions:
          - key: cost-type
            operator: In
            values: [on-demand]
  
  containers:
  - name: training
    image: ml-training:latest
    resources:
      requests:
        nvidia.com/gpu: 1  # Request 1 GPU resource
```

**Debugging Label-Based Scheduling:**

```bash
#!/bin/bash
# debug-scheduling.sh

echo "=== View All Node Labels ==="
kubectl get nodes --show-labels

echo ""
echo "=== Show Labels for Specific Node ==="
kubectl get node gpu-node-1 --show-labels

echo ""
echo "=== Check Pod Scheduling Constraints ==="
kubectl get pod ml-job -o yaml | grep -A20 'nodeSelector:\|affinity:\|tolerations:'

echo ""
echo "=== Simulate Scheduling Decision ==="
# Find nodes matching Pod's constraints
RESUESTED_LABEL="accelerator=nvidia-a100"
kubectl get nodes -L accelerator | grep nvidia-a100

echo ""
echo "=== Check Taints and Tolerations ==="
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
kubectl get pod ml-job -o custom-columns=NAME:.metadata.name,TOLERATIONS:.spec.tolerations

echo ""
echo "=== Why Pod Not Scheduled ==="
kubectl describe pod ml-job | grep -A10 Events
```

**Production-Safe Practices:**

1. **Never use nodeName in manifests** (except debugging)
2. **Use nodeSelector for simple requirements** (e.g., zone, instance type)
3. **Use affinity for complex requirements** (spread across AZs, avoid specific nodes)
4. **Add taints to special nodes** (GPUs, high-memory) to prevent accidental scheduling
5. **Use tolerations to opt-in** - explicit is better than implicit
6. **Label consistently** across infrastructure
7. **Document label semantics** - what each label means
8. **Test scheduling constraints** in non-prod first

---

### Q13: Label Cardinality Impact on Performance

**Question:**
You add a label to every Pod: `request-id: "<unique-uuid>"`. Docker sees the label on and asks "Will this affect API server or etcd performance?" What's the cost of high-cardinality labels?

**Senior DevOps Answer:**

High-cardinality labels (unique or near-unique values per Pod) can significantly degrade API server performance.

**Why Labels Get Indexed:**

```
Kubernetes API server maintains an in-memory index for every label:

Label Index (in-memory hash)
├─ app: api                       ← Low cardinality (few values)
│  ├─ Pods: [pod-1, pod-2, ..., pod-1000]
│
├─ version: v1.2.3
│  ├─ Pods: [pod-500, pod-501, ..., pod-1010]
│
└─ request-id: <uuid>             ← High cardinality (ONE POD per value!)
   ├─ Pods: [pod-123]  ← Each UUID maps to ONE pod
   ├─ Pods: [pod-124]  ← Separate index entry
   ├─ Pods: [pod-125]  ← O(number_of_pods) memory!
```

**Performance Impact:**

```yaml
# GOOD: Low cardinality (<=50 unique values)
app: checkout        # 1 value
env: production      # 3 values (prod, staging, dev)
zone: us-east-1a     # ~10 values
team: platform-eng   # ~20 teams
# Total label combinations: ~600 index entries

---

# BAD: High cardinality (unique per Pod)
request-id: "550e8400-e29b-41d4-a716-446655440000"  # Unique UUID per Pod!
user-session-id: "sess_abc123..."                   # Different per user
transaction-id: "txn_xyz789..."                     # Unique per transaction
# Total label combinations: ONE PER POD (100,000+ for big cluster)
```

**Memory Cost Analysis:**

```
Assumptions:
· 1,000 Pods in cluster
- 50 unique values for low-cardinality labels
· High-cardinality label = 1 unique value per Pod

Memory cost of one label:

Low-cardinality (50 unique values):
  Index entry size: 32 bytes per label value + 64 bytes per Pod reference
  Total: 50 values * (32 + 64*1000) = 50 * 64,032 = 3.2 MB

High-cardinality (1,000 unique values = 1 per Pod):
  Index entry size: 32 bytes per label value + 64 bytes per Pod reference
  Total: 1,000 values * (32 + 64*1) = 1,000 * 96 = 96 KB

BUT: If you have 10 high-cardinality labels:
  96 KB * 10 = 960 KB (manageable)

BUT: If you have 100 Pods with unique request-id labels:
  Label index footprint = O(n_pods * n_unique_values)
  = 1,000 pods * 1,000 unique values = 1 BILLION index entries (theoretical max)
  Actual: ~100 MB per high-cardinality label
```

**Query Performance Impact:**

```bash
# Low-cardinality query (FAST)
$ kubectl get pods -l app=checkout
# Index lookup: O(1) - direct hash table lookup
# Returns: ~100 pods
# Time: <1ms

---

# High-cardinality query (SLOW if requesting specific value)
$ kubectl get pods -l request-id=550e8400-e29b-41d4
# Index lookup: Still O(1) per label value
# BUT: If filtering by partial/glob patterns - O(n) scan
kubectl get pods -l 'request-id~=550e8400.*'
# Time: >100ms with 100K+ index entries

---

# Cross-label query (WORST CASE)
$ kubectl get pods -l app=checkout,request-id=550e8400
# Must: 1. Find pods matching app=checkout (100 pods)
#       2. Cross-check against request-id (1 pod)
#       3. Intersect = 1 pod
# Time: Acceptable (<10ms) because both are indexed

---

# Range query (SLOW with high cardinality)
$ kubectl get pods -l 'request-id>550e8400,request-id<550e8500'
# No range index - must scan ALL request-id index entries
# Time: 50-200ms with high cardinality
```

**Reality Check: Kubernetes Limitations**

```bash
# Kubernetes enforces limits on label size and count
$ kubectl label pod test request-id=550e8400-e29b-41d4-a716-446655440000
# Works fine - labels can be large strings

# BUT: Too many labels cause issues
$ for i in {1..500}; do
    kubectl label pod test label-$i=value-$i
done
# At some point:
# error: the object has too many labels (total: 500, max: 63 per Kubernetes spec)
# (Actually it's 500+ allowed but becomes impractical)

# Actual issue: Each label increases API request size
metadata:
  labels:
    label-1: value-1       # 30 bytes
    label-2: value-2       # 30 bytes
    ... (500 labels)
  # Total: ~15 KB just for labels in metadata
  # API serialization becomes inefficient
```

**Best Practices to Avoid High Cardinality:**

```yaml
# DON'T:
apiVersion: v1
kind: Pod
metadata:
  labels:
    request-id: "550e8400..."   # ← Per-request!
    user-id: "user-12345"        # ← Per-user!
    session-id: "sess-abcd"      # ← Per-session!
---

# DO: Use annotations for high-cardinality data
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: checkout
    env: production
  annotations:  # ← For non-queryable metadata
    request-id: "550e8400-e29b-41d4-a716-446655440000"
    user-id: "user-12345"
    session-id: "sess-abcd"
```

**Monitoring Label Cardinality:**

```bash
#!/bin/bash
# check-label-cardinality.sh

echo "=== Label Cardinality Report ==="
echo "Label Name | Unique Values | Cardinality %"
echo "------|----------|-----"

for label in $(kubectl get pods --all-namespaces -o json | jq -r '.items[].metadata.labels | keys[]' | sort -u); do
    UNIQUE=$(kubectl get pods --all-namespaces -o json | \
      jq -r ".items[] | select(.metadata.labels[\"$label\"] != null) | .metadata.labels[\"$label\"]" | sort -u | wc -l)
    
    TOTAL=$(kubectl get pods --all-namespaces --no-headers | wc -l)
    PERCENTAGE=$((UNIQUE * 100 / TOTAL))
    
    if [ $PERCENTAGE -gt 50 ]; then
        echo "$label | $UNIQUE | ${PERCENTAGE}% ⚠️  (HIGH CARDINALITY)"
    else
        echo "$label | $UNIQUE | ${PERCENTAGE}%"
    fi
done
```

**Performance Tuning:**

```yaml
# If you need high-cardinality data, use a separate annotation store:
apiVersion: v1
kind: ConfigMap
metadata:
  name: pod-metadata-store
  namespace: default
data:
  # Map Pod -> high-cardinality fields
  pod-123-metadata: |
    {"request-id": "550e8400", "user-id": "user-123", "session-id": "sess-abc"}
  pod-124-metadata: |
    {"request-id": "550e8401", "user-id": "user-124", "session-id": "sess-def"}

# App reads from ConfigMap when needed (not indexed by Kubernetes)
```

**Best Practices:**
- **Keep labels low-cardinality** (<100 unique values per label)
- **Use annotations for non-queryable metadata**
- **Avoid request-id, session-id, etc. as labels**
- **Monitor label cardinality** - alert if >% 50 unique values
- **Document label semantics** - what each label is for
- **Use ConfigMaps for lookups** if you need massive metadata

---

## References & Further Reading

- [Kubernetes Official Documentation: Object Model](https://kubernetes.io/docs/concepts/overview/working-with-objects/)
- [Kubernetes API Conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Kubernetes Object Management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/)
- [Control Loop Patterns](https://kubernetes.io/docs/concepts/architecture/controller/)

---

**Status:** ✅ COMPLETE - All major sections delivered (Introduction, Foundational Concepts, 4 Subtopics, Hands-on Scenarios, Interview Questions)  
**Document Type:** Senior DevOps Engineer Study Guide (5-10+ years experience)  
**Last Updated:** March 2026
