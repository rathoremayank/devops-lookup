# Kubernetes Pods, Containers, Deployments, StatefulSets, and Jobs: Enterprise Workload Management

A Senior DevOps Engineering Study Guide for Production-Grade Kubernetes Orchestration

---

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Topic](#overview-of-topic)
   - [Why It Matters in Modern DevOps Platforms](#why-it-matters)
   - [Real-World Production Use Cases](#real-world-use-cases)
   - [Where It Appears in Cloud Architecture](#cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#devops-principles)
   - [Best Practices Overview](#best-practices-overview)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Pods & Container Lifecycle Management](#section-3)
   - [Pod Phases and Lifecycle States](#pod-phases)
   - [Restart Policies and Error Handling](#restart-policies)
   - [Container Lifecycle Hooks](#lifecycle-hooks)
   - [Multi-Container Pod Management](#multi-container)
   - [Pod Resource Management](#pod-resources)
   - [Init Containers](#init-containers)

4. [ReplicaSets and Deployments](#section-4)
   - [ReplicaSets: Desired State and Reconciliation](#replicasets)
   - [Deployments: Declarative Updates](#deployments)
   - [Scaling Strategies](#scaling)
   - [Rolling Updates: In-Place Upgrades](#rolling-updates)
   - [Rollback Mechanisms](#rollbacks)
   - [Rollout Strategies and Revision History](#rollout-strategies)
   - [Production Best Practices](#deployment-best-practices)

5. [StatefulSets and DaemonSets](#section-5)
   - [StatefulSets: Ordered, Persistent Workloads](#statefulsets)
   - [DaemonSets: Node-Level Agents](#daemonsets)
   - [Use Cases and Architectural Patterns](#workload-use-cases)
   - [Differences from Deployments](#workload-differences)
   - [Scaling and Update Strategies](#workload-scaling)
   - [Persistent Workload Management](#persistent-workloads)
   - [Production Best Practices](#workload-best-practices)

6. [Jobs and CronJobs](#section-6)
   - [Batch Workloads: Jobs Overview](#jobs-overview)
   - [CronJobs: Scheduled Execution](#cronjobs)
   - [Use Cases and Failure Handling](#job-use-cases)
   - [Retry Policies and Parallelism](#job-retry)
   - [Completion Tracking and Monitoring](#job-completion)
   - [Production Best Practices](#job-best-practices)

7. [Hands-On Scenarios](#section-7)
   - [Scenario 1: Multi-Tier Application Deployment](#scenario-1)
   - [Scenario 2: Database Migration with StatefulSets](#scenario-2)
   - [Scenario 3: Distributed Job Processing](#scenario-3)
   - [Scenario 4: Canary Deployment Strategy](#scenario-4)

8. [Interview Questions for Senior DevOps Engineers](#section-8)
   - [Architecture and Design Questions](#arch-questions)
   - [Operations and Troubleshooting](#ops-questions)
   - [Performance and Scaling](#perf-questions)
   - [Disaster Recovery and HA](#dr-questions)

---

## Introduction

### Overview of Topic {#overview-of-topic}

Kubernetes workload management encompasses the specification, deployment, scaling, and lifecycle orchestration of containerized applications across distributed clusters. This study guide covers the critical abstractions that form the backbone of production Kubernetes deployments:

- **Pods**: The smallest deployable unit in Kubernetes, abstracting one or more containers
- **ReplicaSets and Deployments**: Controllers managing desired state, scaling, and rolling updates
- **StatefulSets and DaemonSets**: Specialized controllers for stateful applications and cluster-wide agents
- **Jobs and CronJobs**: Batch processing and scheduled task execution models

These abstractions represent the evolution of containerization philosophy—from basic container orchestration to sophisticated workload management patterns supporting enterprise scale, resilience, and operational complexity.

### Why It Matters in Modern DevOps Platforms {#why-it-matters}

#### 1. **Declarative Infrastructure**
Modern DevOps practices demand declarative specifications over imperative commands. Kubernetes workload abstractions enable teams to:
- Define desired state once, with Kubernetes managing convergence
- Enable GitOps workflows with version control for infrastructure
- Reduce configuration drift through continuous reconciliation
- Achieve immutability and reproducibility

#### 2. **Operational Efficiency at Scale**
In production environments managing thousands of containers:
- Manual scaling and updates become operationally infeasible
- Automated self-healing reduces mean-time-to-recovery (MTTR)
- Rolling updates enable zero-downtime deployments for critical services
- Resource bin-packing optimizes infrastructure utilization

#### 3. **Resilience and High Availability**
Enterprise systems require:
- Automatic pod restart on node failures
- Cross-node replica distribution for fault tolerance
- Graceful degradation under partial failures
- Built-in retry mechanisms for transient failures

#### 4. **Organizational Scaling**
As DevOps teams grow:
- Standardized workload patterns reduce cognitive overhead
- Clear separation of concerns (application vs. infrastructure)
- Consistent deployment patterns across teams
- Observable, auditable infrastructure changes

### Real-World Production Use Cases {#real-world-use-cases}

#### **E-Commerce Platform (Deployments + StatefulSets)**
A high-traffic e-commerce platform requires:
- **Web tier (Deployments)**: Stateless services scaled horizontally based on RPS, with rolling updates during peak hours
- **Database tier (StatefulSets)**: PostgreSQL with persistent volumes, ordered startup ensuring primary election before replicas
- **Cache tier (DaemonSet)**: Redis agents on compute-optimized nodes for distributed caching
- **Task processing (Jobs)**: Batch jobs for report generation, inventory sync, and ETL pipelines

**Operational benefit**: A 3-hour inventory sync completes reliably via a Job with 50 parallel workers, with automatic cleanup. A traffic spike triggers HPA to add 20 replicas in 2 minutes without manual intervention.

#### **SaaS Multi-Tenant Infrastructure (Deployments + Jobs + CronJobs)**
A multi-tenant SaaS platform manages:
- **API servers (Deployments)**: Tenant-aware request routing with rolling updates every 6 hours
- **Data processing (CronJobs)**: Nightly billing calculations, report generation, and cleanup scheduled across timezones
- **Batch migrations (Jobs)**: Schema migrations and data transformations with progress tracking and automatic rollback on failure

**Operational benefit**: Billing runs identically across 500+ customer accounts via a single CronJob definition. A failed migration automatically triggers rollback without manual intervention.

#### **Machine Learning Platform (Custom Controllers + Jobs + StatefulSets)**
ML training and serving workloads require:
- **Training jobs (Jobs)**: GPU-accelerated training with checkpointing, automatic retry on node failure
- **Model serving (Deployments)**: Inference servers with model versioning, canary deployments for new models
- **Feature store (StatefulSets)**: Distributed feature computation with ordered startup and persistent coordination

**Operational benefit**: A failed training job automatically restarts from the last checkpoint. Model rollout follows strict canary patterns: 5% traffic → 25% → 100%, with automatic rollback on error rate thresholds.

#### **Observability and Security (DaemonSets + Jobs)**
Platform-wide capabilities implemented as:
- **Logging agent (DaemonSet)**: Runs on every node, collecting container logs with guaranteed order delivery
- **Security scanning (CronJob)**: Nightly image vulnerability scans with remediation workflows
- **Audit compliance (Jobs)**: Batch processing of audit logs for regulatory requirements

### Where It Appears in Cloud Architecture {#cloud-architecture}

Kubernetes workload abstractions form the **application layer** of cloud-native architecture:

```
┌─────────────────────────────────────────────┐
│         Application Workloads Layer         │
│  ┌────────────────────────────────────────┐ │
│  │ Deployments    StatefulSets   Jobs     │ │
│  │ DaemonSets    CronJobs        Pods     │ │
│  └────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│         Kubernetes Control Plane            │
│  ┌────────────────────────────────────────┐ │
│  │ API Server  etcd  Scheduler  Controller│ │
│  │ Manager     Cloud Controller Manager   │ │
│  └────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│      Infrastructure / Node Layer            │
│  ┌────────────────────────────────────────┐ │
│  │ kubelet  Container Runtime  Networking │ │
│  │ Storage  OS & Kernel  Cloud Provider   │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

**Integration points with wider architecture**:
- **Service Mesh (Istio/Linkerd)**: Intercepts traffic between workload replicas for observability and traffic management
- **Persistent Storage**: StatefulSets leverage persistent volumes for stateful applications
- **Networking**: DaemonSets implement DNS, load balancing, and network policies cluster-wide
- **Monitoring/Logging**: Observability platforms scrape metrics from all pod replicas
- **GitOps Platforms**: Flux/ArgoCD continuously sync workload definitions from version control
- **Ingress Controllers**: Route external traffic to Deployment replicas based on hostname/path routing

---

## Foundational Concepts

### Key Terminology {#key-terminology}

#### **Pod**
The atomic unit of deployment in Kubernetes. A pod is a wrapper around one or more containers (typically one), allowing them to share:
- Network namespace (single IP address, localhost communication between containers)
- Storage volumes
- Container runtime configuration (securityContext, resource requests/limits)

**Distinction from Docker**: A pod is NOT equivalent to a container. Multiple containers can run within a pod with shared networking—a pattern called "sidecar containers."

#### **Replica** vs **Instance**
- **Replica**: A conceptual copy of a workload specified by a controller (e.g., ReplicaSet with replicas: 3)
- **Instance**: The actual running pod implementing that replica (e.g., 3 running pods)

#### **Desired State** vs **Actual State**
- **Desired State**: The specification declaratively authored by an operator in a resource definition (e.g., `replicas: 3`)
- **Actual State**: The current reality of the cluster (e.g., 2 pods running, 1 pending)

Kubernetes continuously works to converge actual state toward desired state through **reconciliation loops**.

#### **Reconciliation Loop** / **Control Loop**
Controllers implement a continuous loop:
```
1. Observe actual state
2. Compare with desired state
3. Take action to converge (create, update, delete resources)
4. Go to step 1
```

This is the fundamental mechanism driving Kubernetes' declarative model.

#### **Rolling Update**
A deployment strategy replacing instances gradually while maintaining availability:
- Old replicas are terminated
- New replicas with updated container images are created
- Traffic gradually shifts from old to new
- Zero downtime is achieved if health checks pass

#### **Stateless** vs **Stateful**
- **Stateless**: Workloads where any replica can handle any request (e.g., web servers). No identity/ordering requirements.
- **Stateful**: Workloads where replicas have persistent identity and ordering (e.g., databases, distributed stores). Data loss on pod termination is unacceptable.

#### **Graceful Termination** / **Graceful Shutdown**
When a pod receives a termination signal:
- SIGTERM is sent to the container; pod enters "Terminating" state
- Application has `terminationGracePeriodSeconds` (default: 30s) to complete in-flight requests
- SIGKILL forcefully stops the container if grace period expires

#### **Init Container**
A container that runs before application containers in a pod. Used for:
- Setup and initialization
- Waiting for dependencies (e.g., database)
- Downloading configuration or secrets
- Must complete successfully before container startup

#### **Sidecar Container**
An additional container in a pod running alongside the main application. Common patterns:
- **Logging sidecar**: Collects stdout/stderr
- **Security sidecar**: Encryption, decryption, mTLS termination
- **Metrics sidecar**: Collects and exports metrics
- **Service mesh sidecar**: Proxies all network traffic (Istio Envoy)

#### **Node Affinity** and **Pod Affinity**
- **Node Affinity**: Rules controlling which nodes a pod can/should run on (e.g., `disk=SSD`)
- **Pod Affinity**: Rules controlling which pods should run together (e.g., 2 pods on the same node for latency)
- **Pod Anti-Affinity**: Spread replicas across different nodes for fault tolerance

#### **Quality of Service (QoS) Classes**
Kubernetes assigns QoS based on resource requests/limits:
- **Guaranteed**: Requests = Limits; highest priority, never evicted
- **Burstable**: Requests < Limits; moderate priority, evicted if cluster under memory pressure
- **BestEffort**: No requests/limits; lowest priority, evicted first

#### **Head-less Service** vs **Service with ClusterIP**
- **Service with ClusterIP**: VIP across replicas; clients see single entry point
- **Headless Service**: No VIP; DNS returns individual pod IPs; used by StatefulSets for direct pod access

#### **Revision** / **Rollout History**
Deployments maintain revision history enabling rollback:
- Each rollout creates a new ReplicaSet (revision)
- Previous ReplicaSets are retained (configurable via `revisionHistoryLimit`)
- `rollout history` and `rollout undo` commands leverage this history

### Architecture Fundamentals {#architecture-fundamentals}

#### **Controller Pattern**
Kubernetes uses a declarative controller pattern:

```
┌──────────────────────────────────────────┐
│  Desired State (YAML manifests)          │
│  - Deployment: replicas=3, image=v2      │
│  - StatefulSet: replicas=5, image=v2     │
│  - Job: parallelism=10, backoffLimit=3   │
└───────────────┬──────────────────────────┘
                │ Store in etcd
┌───────────────▼──────────────────────────┐
│  API Server (etcd backed)                │
└───────────────┬──────────────────────────┘
                │ Watch for changes
┌───────────────▼──────────────────────────┐
│  Controllers:                            │
│  - Deployment Controller                 │
│  - StatefulSet Controller                │
│  - Job Controller                        │
│  - DaemonSet Controller                  │
└───────────────┬──────────────────────────┘
                │ Trigger via Operators/Webhooks
                │
┌───────────────▼──────────────────────────┐
│  Actual State Changes:                   │
│  - Create/Update/Delete Pods             │
│  - Bind PersistentVolumes                │
│  - Manage network policies               │
└──────────────────────────────────────────┘
```

Each controller watches for resource changes and continuously works toward desired state.

#### **Label-Based Selection**
Kubernetes uses labels (key-value metadata) for loose coupling:

```yaml
# Pod specifies labels
metadata:
  labels:
    app: web-api
    tier: frontend
    version: v2

---
# ReplicaSet selects pods via label selector
selector:
  matchLabels:
    app: web-api
    version: v2

---
# Service routes traffic to matching pods
selector:
  app: web-api
```

This enables:
- Flexible pod grouping without hardcoded names
- Multi-tenant isolation via labels
- Traffic routing independent of pod identity
- Dynamic discovery (new pods automatically included)

#### **Ownership and Controller References**
Resources have ownership hierarchy:

```
Deployment "web-api"
  ├─ ReplicaSet "web-api-5f9a7b2d"
  │   ├─ Pod "web-api-5f9a7b2d-xyz1"
  │   ├─ Pod "web-api-5f9a7b2d-xyz2"
  │   └─ Pod "web-api-5f9a7b2d-xyz3"
  │
  └─ ReplicaSet "web-api-a8b9c2e1" (previous version, 0 replicas)
      └─ Pod "web-api-a8b9c2e1-old1" (being terminated)
```

Each pod references its creator (ReplicaSet), which references the Deployment. **Owner references** enable:
- Cascading deletion (delete Deployment → delete ReplicaSets → delete Pods)
- Garbage collection automation
- Audit trails of resource relationships

#### **API Versioning and Resource Groups**
Kubernetes uses API versioning for backward compatibility:

```
# Apps API group, v1 version (stable)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-api

---

# Batch API group, v1 version (stable)
apiVersion: batch/v1
kind: Job
metadata:
  name: data-sync

---

# Batch API group, v1beta1 version (beta)
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: nightly-report
```

Awareness of API versions is critical for:
- Cluster compatibility (v1.27 supports specific API versions)
- Feature availability (some features only in beta versions)
- Deprecation planning (older API versions eventually removed)

### Important DevOps Principles {#devops-principles}

#### **1. Immutability of Artifacts**
**Principle**: Container images should be immutable; changes require new image builds and deployments.

**Application to workloads**:
- Never modify running pod container images in-place
- Use Deployments with new image tags to trigger rolling updates
- Keep `imagePullPolicy: Always` or use unique digests to ensure new images are pulled

**Benefit**: Reproducibility, auditability, and disaster recovery. An operator can always see **exactly** what code is running by examining the image tag.

#### **2. Declarative Over Imperative**
**Principle**: Specify **what** you want, not **how** to achieve it. Let the platform handle implementation.

**Application to workloads**:
```yaml
# ✓ DECLARATIVE (Kubernetes determines how to achieve this)
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    spec:
      containers:
      - image: myapp:v2

# ✗ IMPERATIVE (manual, not declarative)
kubectl scale deployment web-api --replicas=5
kubectl set image deployment/web-api myapp=myapp:v2
```

**Benefit**: Declarative specs are version-controllable (GitOps), reproducible, and automatically converge to desired state.

#### **3. Continuous Reconciliation**
**Principle**: Controllers continuously drive actual state toward desired state.

**Application to workloads**:
- If a pod dies, the ReplicaSet creates a replacement automatically
- If you scale replicaset down to N, it terminates excess pods without manual deletion
- Operator changes desired state once; Kubernetes ensures convergence

**Example**:
```yaml
# Operator:
kubectl patch deployment web-api -p '{"spec":{"replicas":5}}'

# Kubernetes automatically:
# 1. Detects mismatch (3 running, 5 desired)
# 2. Creates 2 additional pods
# 3. Ensures they're healthy and receive traffic
# 4. Returns to steady state once 5 are running
```

#### **4. Separation of Concerns**
**Principle**: Application logic, infrastructure concerns, and operational policies should be separated.

**Application to workloads**:
- **Application concern**: Business logic, service behavior
- **Infrastructure concern**: Node selection, storage provisioning, networking
- **Operational concern**: Scaling policies, upgrade strategies, rollback procedures

Example separation:
```yaml
# Application: What the app needs
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - image: myapp:v2
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"

---

# Operations: How to run it
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-api
spec:
  scaleTargetRef:
    kind: Deployment
    name: web-api
  minReplicas: 3
  maxReplicas: 10
```

#### **5. Observable Systems**
**Principle**: Workloads must be observable to debug issues and understand behavior.

**Application to workload specifications**:
- Health checks (liveness, readiness probes) make pod state visible
- Resource requests/limits enable monitoring and alerting
- Structured logging from containers enables debugging
- Metrics endpoints allow observability platforms to understand behavior

#### **6. Resilience as Default**
**Principle**: Systems should be resilient to failures by default, not as an afterthought.

**Application to workloads**:
- Restart policies ensure transient failures are handled
- Multiple replicas prevent single pod failure from causing downtime
- Graceful termination allows in-flight requests to complete
- Init containers can wait for dependent systems before starting

### Best Practices Overview {#best-practices-overview}

#### **1. Resource Requests and Limits**
```yaml
containers:
- name: app
  resources:
    requests:
      cpu: "100m"           # What we need
      memory: "256Mi"
    limits:
      cpu: "500m"           # Maximum we'll use
      memory: "512Mi"
```

**Why**: 
- **Requests enable cluster scheduling** (scheduler finds nodes with available resources)
- **Limits prevent noisy-neighbor problems** (one pod can't consume all node resources)
- Without requests, scheduler has no input → poor bin-packing
- Without limits, pods can cause node OOM-kills

#### **2. Health Checks (Probes)**
```yaml
livenessProbe:                  # Pod is stuck? Kill and restart
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10

readinessProbe:                 # Ready to receive traffic?
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Why**:
- **Liveness**: Detects deadlocks, infinite loops, unresponsive apps → automatic restart
- **Readiness**: Prevents traffic routing to pods still starting up or recovering
- Without probes, failed pods continue receiving requests

#### **3. Pod Disruption Budgets (for stateful workloads)**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: redis-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: redis
```

**Why**: During maintenance, cluster operations respect PDB minimums, preventing data loss.

#### **4. Graceful Shutdown Configuration**
```yaml
spec:
  terminationGracePeriodSeconds: 30
  containers:
  - name: app
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh", "-c", "sleep 5"]  # Deregister from LB
```

**Why**: Allows graceful shutdown of in-flight requests before forced termination.

#### **5. Image Pull Policies**
```yaml
containers:
- image: myregistry.azurecr.io/myapp:v2
  imagePullPolicy: Always       # Always pull; ensures latest image
```

**Why**: 
- `Always` prevents running old images if image tags are reused
- `IfNotPresent` can cause issues in CI/CD if tags aren't unique

#### **6. Security Contexts**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
      - NET_RAW
```

**Why**: Reduces blast radius of container compromises.

### Common Misunderstandings {#common-misunderstandings}

#### **Misunderstanding 1: "Replicas = High Availability"**

**False belief**: If I have 3 replicas, my app is highly available.

**Reality**:
- HA requires replicas **on different nodes** (anti-affinity)
- HA requires multiple availability zones (for cloud providers)
- HA requires health checks (to detect and replace failed replicas)
- HA requires proper graceful shutdown (to avoid connection losses)

Example of **NOT HA**:
```yaml
spec:
  replicas: 3  # All 3 might end up on the same node!
```

Example of **HA**:
```yaml
spec:
  replicas: 3
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:  # HARD anti-affinity
      - topologyKey: kubernetes.io/hostname           # Spread across nodes
        labelSelector:
          matchLabels:
            app: web-api
  topologySpreadConstraints:  # Also spread across AZs
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
```

#### **Misunderstanding 2: "Kubernetes Automatically Scales My App"**

**False belief**: Just create a Deployment and Kubernetes scales it based on load.

**Reality**:
- Deployments are **static** (manual scaling only)
- HPA (HorizontalPodAutoscaler) is required for dynamic scaling
- HPA needs metrics (from metrics-server or Prometheus)
- HPA has min/max bounds and cooldown to prevent flapping

Example:
```yaml
# This does NOT auto-scale
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3  # Static replicas

---
# This enables auto-scaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-api-hpa
spec:
  scaleTargetRef:
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
        averageUtilization: 80
```

#### **Misunderstanding 3: "Rolling Updates Are Always Safe"**

**False belief**: Rolling updates never cause downtime.

**Reality**:
- Zero-downtime requires proper **connection draining** (preStop hooks)
- Zero-downtime requires **health checks** (readiness probes)
- Zero-downtime requires **PDB** for multi-pod coordination
- Breaking changes in APIs can cause issues despite healthy replicas

Example of **risky** rolling update:
```yaml
# Old version connects to stateful service; upgrade breaks API compatibility
# With slow liveness probe, old requests may fail during rollover
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - image: myapp:v2
      # Missing health checks and preStop!
```

#### **Misunderstanding 4: "StatefulSets Are for Persistence"**

**False belief**: Use StatefulSets whenever you need persistent storage.

**Reality**:
- StatefulSets provide **stable pod identity**, not just persistence
- StatefulSets guarantee **ordered startup/shutdown** (primary DB before replicas)
- StatefulSets maintain **DNS identity** per pod (pod-0.service, pod-1.service)
- Use StatefulSets only for distributed systems requiring peer-to-peer communication

Example:
- ✓ StatefulSet: Database cluster (PostgreSQL with replication requiring stable identities)
- ✗ StatefulSet: Web app with persistent logs (use Deployment + PVC)

#### **Misunderstanding 5: "Jobs Complete When the Container Exits"**

**False belief**: A Job's success depends solely on container exit code.

**Reality**:
- Job success depends on **job completions** metric (parallelism × completions)
- Container exit code determines pod status, but Job tracks pod status
- Multiple pods can run in parallel; all must succeed
- Retry logic is complex (backoffLimit, active deadline seconds, etc.)

Example of **underspecified** Job:
```yaml
apiVersion: batch/v1
kind: Job
spec:
  template:
    spec:
      containers:
      - image: data-processor
        command: ["python", "process.py"]
  # Missing completions, parallelism, and bak offLimit!
```

Example of **well-specified** Job:
```yaml
apiVersion: batch/v1
kind: Job
spec:
  completions: 100           # Run 100 pod-tasks total
  parallelism: 10            # Run 10 pods in parallel
  backoffLimit: 3            # Retry failed pods up to 3 times
  ttlSecondsAfterFinished: 86400  # Auto-delete after 24 hours
  activeDeadlineSeconds: 3600     # Hard timeout: 1 hour
  template:
    spec:
      containers:
      - image: data-processor
        command: ["python", "process.py"]
      restartPolicy: Never
```

#### **Misunderstanding 6: "DaemonSets Run on All Nodes"**

**False belief**: A DaemonSet always runs on every single node in the cluster.

**Reality**:
- DaemonSets run on all nodes **matching the node selector and tolerations**
- Control plane nodes have the `control-plane:NoSchedule` taint by default
- Custom taints prevent DaemonSet pods from running on specific nodes
- Node selectors filter which nodes receive DaemonSet pods

Example of **partial** DaemonSet:
```yaml
apiVersion: apps/v1
kind: DaemonSet
spec:
  selector:
    matchLabels:
      app: gpu-monitor
  template:
    spec:
      nodeSelector:
        gpu: "true"  # Only nodes labeled gpu=true
      tolerations:
      - key: dedicated
        operator: Equal
        value: worker
        effect: NoSchedule  # Tolerates dedicated=worker:NoSchedule taint
```

---

# PART 2: DEEP DIVE SECTIONS

---

## Pods & Container Lifecycle Management {#section-3}

### Textual Deep Dive

#### **Internal Working Mechanism: Pod Lifecycle States** {#pod-phases}

A pod's lifecycle progresses through distinct phases managed by the kubelet on the node:

```
┌─────────────────────────────────────────────────────────────┐
│                    POD LIFECYCLE PHASES                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Pending                                                 │
│     ├─ Image pull in progress                              │
│     ├─ Init containers starting                            │
│     ├─ Device/volume attachment                            │
│     └─ Awaiting node scheduling or resource availability   │
│                                                             │
│  2. Running                                                 │
│     ├─ At least one container is running                   │
│     ├─ Other containers may be starting/restarting         │
│     └─ All init containers have completed successfully     │
│                                                             │
│  3. Succeeded                                               │
│     ├─ All containers in the pod terminated successfully   │
│     ├─ No restarts will occur                              │
│     └─ Status.reason = "Completed"                         │
│                                                             │
│  4. Failed                                                  │
│     ├─ At least one container exited with non-zero code   │
│     ├─ Restart policies determine next action              │
│     └─ Status.reason = "Error" or specific reason          │
│                                                             │
│  5. Unknown                                                 │
│     ├─ Communication lost with node                        │
│     ├─ Pod state cannot be determined                      │
│     └─ Controller acts based on node timeout               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

The kubelet continuously monitors container states via the container runtime (Docker, containerd) and reports back to the API server.

#### **Container Lifecycle Hooks: Pre/Post Event Handlers** {#lifecycle-hooks}

Kubernetes provides lifecycle hooks at two points:

1. **PostStart Hook** (runs after container start)
   - Executes immediately after container PID 1 starts
   - Runs **asynchronously** (does not block container startup)
   - Failure does NOT fail the pod unless failure policy specifies termination
   - Use cases: Signal handlers setup, warmup operations, registering with service discovery

2. **PreStop Hook** (runs before container termination)
   - Executes before SIGTERM is sent (graceful shutdown window)
   - Runs **synchronously** (container waits for hook completion)
   - Hook timeout (default 5s) auto-terminates if exceeded
   - **Critical for graceful shutdown**: Deregister from load balancers, close connections

#### **Restart Policies: Automatic Pod Recovery** {#restart-policies}

The `restartPolicy` field determines kubelet behavior on container failure:

| Policy | Behavior | Use Case |
|--------|----------|----------|
| **Always** (default) | Restart container immediately on exit (any code) | Long-running services, web servers, daemons |
| **OnFailure** | Restart only on non-zero exit code; backoff delays | Batch workers that might exit cleanly |
| **Never** | Do not restart; pod remains in Failed state | Jobs, one-shot tasks, debugging |

**Backoff mechanism for OnFailure/Always**:
```
Delays: 100ms → 200ms → 400ms → 800ms → 1.6s → 3.2s → MAX (5 minutes)
Resets: If container runs successfully for 10+ minutes, backoff counter resets
```

#### **Multi-Container Pod Patterns** {#multi-container}

While single-container pods are the norm, multi-container pods enable advanced patterns:

1. **Sidecar Pattern**
   - Main container runs application logic
   - Sidecar container provides auxiliary function (logging, monitoring, proxying)
   - Shared network namespace means sidecar can proxy traffic on localhost
   - Shared volumes enable log processing

   ```
   Pod: "web-api"
   ├─ Container: api-server (port 8080)
   └─ Container: log-shipper (reads /var/log via shared volume)
   ```

2. **Ambassador Pattern**
   - Main container talks to localhost:port (thinks service is local)
   - Ambassador container proxies to actual service (handles load balancing, retries, failover)
   - Decouples application from service discovery complexity

   ```
   Pod: "api-client"
   ├─ Container: app (connects to localhost:6379)
   └─ Container: redis-ambassador (proxies to actual redis cluster)
   ```

3. **Adapter Pattern**
   - Main container runs service code
   - Adapter container transforms/normalizes output before export
   - Useful for heterogeneous monitoring/logging systems

   ```
   Pod: "metrics-exporter"
   ├─ Container: app (outputs metrics to /metrics)
   └─ Container: prometheus-adapter (transforms to Prometheus format)
   ```

#### **Pod Resource Management** {#pod-resources}

Resource requests and limits operate at the container level but affect pod scheduling:

```yaml
spec:
  containers:
  - name: api
    resources:
      requests:
        cpu: "100m"        # Scheduler guarantees this CPU
        memory: "256Mi"    # Scheduler guarantees this RAM
      limits:
        cpu: "500m"        # Cgroup limit; exceeding triggers throttling
        memory: "512Mi"    # Cgroup limit; exceeding triggers OOM kill
```

**Scheduling algorithm** uses **sum of container requests**:
```
Pod's CPU request = sum(all containers' CPU requests)
Pod's memory request = sum(all containers' memory requests)

Scheduler places pod on node where:
node.available >= pod.requests
```

**Quality of Service (QoS)** affects eviction priority during cluster pressure:
```
Guaranteed:   requests == limits (highest priority, never evicted)
Burstable:    requests < limits  (moderate priority)
BestEffort:   no requests/limits (lowest priority, evicted first)
```

#### **Init Containers: Ordered Startup Phase** {#init-containers}

Init containers run **before** application containers, enabling setup and validation:

```
Pod startup flow:
1. Init container 1 → must complete successfully
2. Init container 2 → must complete successfully
3. Application containers → can now run in parallel
```

**Key characteristics**:
- Must complete successfully (exit 0) before next init runs
- Restart policies do NOT apply to init containers
- Each init container runs to completion sequentially
- Can share volumes with application containers
- Have same image pull and networking setup as app containers

#### **Production Usage Patterns**

**Pattern 1: Dependency Wait (Init Container)**
```yaml
initContainers:
- name: wait-for-db
  image: busybox:latest
  command: ['sh', '-c', 'until nc -z db-service 5432; do sleep 1; done']
```
Ensures database is reachable before application starts.

**Pattern 2: Configuration Injection (Init + Sidecar)**
```yaml
initContainers:
- name: config-loader      # Fetch config from external system
  volumeMounts:
  - name: config
    mountPath: /etc/app
containers:
- name: app                 # Use config from init
  volumeMounts:
  - name: config
    mountPath: /etc/app
- name: config-reloader    # Sidecar watches config changes
  volumeMounts:
  - name: config
    mountPath: /etc/app
```

**Pattern 3: Graceful Shutdown (PreStop + SIGTERM)**
```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 5; kill -TERM 1"]
terminationGracePeriodSeconds: 30
```
5-second deregistration window, then 25-second graceful shutdown.

#### **DevOps Best Practices**

1. **Always Set Resource Requests/Limits**
   - Prevents noisy-neighbor problems  
   - Enables proper bin-packing
   - Triggers appropriate QoS classification

2. **Implement Health Checks**
   ```yaml
   livenessProbe:      # Kill stuck pods
   readinessProbe:     # Remove from traffic
   startupProbe:       # Wait for slow startups
   ```

3. **Use Init Containers for Dependency Management**
   - Don't embed wait logic in application code
   - Decouples deployment sequencing from application logic

4. **Graceful Shutdown is Non-Negotiable**
   - PreStop hook for deregistration
   - Application handles SIGTERM
   - Sufficient terminationGracePeriodSeconds

5. **Multi-Container Pods for Sidecar Pattern Only**
   - Avoid multi-container for unrelated functions
   - Keep sidecars focused and loosely coupled

#### **Common Pitfalls**

1. **Underestimating Init Container Impact**
   - Long init container delays pod startup
   - Retries on init failure delay entire pod
   - Monitoring/alerting often misses init timings

2. **PostStart Hook Failures Causing Silent Failures**
   - PostStart hook failures don't fail the pod
   - Application might be running but broken
   - Must implement liveness probes to detect

3. **Insufficient Termination Grace Period**
   - Default 30s insufficient for complex cleanup
   - K8s force-kills if timeout exceeded
   - Connection drops and data loss can occur

4. **Resource Request/Limit Mismatches**
   - Requests too low → pod evicted under pressure
   - Limits too low → application can't burst
   - No requests → scheduler can't make intelligent decisions

5. **Multi-Container Pod Networking Assumptions**
   - Assume containers see localhost → true only within same pod
   - Assume shared storage → false unless explicitly mounted
   - Assume service discovery → shared DNS, but namespace isolation applies

---

### Practical Code Examples

#### **Example 1: Web Application with Liveness, Readiness, and Graceful Shutdown**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-api-example
  namespace: production
spec:
  terminationGracePeriodSeconds: 30
  
  # Init container waits for database
  initContainers:
  - name: wait-for-dependencies
    image: curlimages/curl:7.85.0
    command:
    - /bin/sh
    - -c
    - |
      echo "Waiting for PostgreSQL..."
      until curl -s http://postgres-service:5432; do
        echo "Postgres unavailable, retrying..."
        sleep 2
      done
      echo "Postgres is up!"
  
  containers:
  - name: api
    image: myregistry.azurecr.io/myapp:v2.1.0
    imagePullPolicy: Always
    
    ports:
    - containerPort: 8080
      name: http
      protocol: TCP
    - containerPort: 9090
      name: metrics
      protocol: TCP
    
    env:
    - name: LOG_LEVEL
      value: "INFO"
    - name: DB_HOST
      value: "postgres-service"
    - name: DB_PORT
      value: "5432"
    - name: ENVIRONMENT
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    
    resources:
      requests:
        cpu: "100m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
    
    # Startup probe: give app 60 seconds to become healthy
    startupProbe:
      httpGet:
        path: /health/startup
        port: http
      initialDelaySeconds: 0
      periodSeconds: 5
      timeoutSeconds: 2
      failureThreshold: 12  # 12 * 5s = 60s total
    
    # Liveness probe: is the app responsive?
    livenessProbe:
      httpGet:
        path: /health/live
        port: http
        scheme: HTTP
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 3
      failureThreshold: 3
      successThreshold: 1
    
    # Readiness probe: should traffic be routed here?
    readinessProbe:
      httpGet:
        path: /health/ready
        port: http
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 2
      failureThreshold: 2
      successThreshold: 1
    
    # PreStop hook: gracefully deregister and close connections
    lifecycle:
      preStop:
        exec:
          command:
          - /bin/sh
          - -c
          - |
            echo "Gracefully shutting down..."
            # Signal application to stop accepting new requests
            kill -TERM 1
            # Wait for connection draining
            sleep 5
            echo "Shutdown complete"
    
    volumeMounts:
    - name: app-config
      mountPath: /etc/app
      readOnly: true
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /var/cache/app
  
  # Sidecar: log aggregation
  - name: log-forwarder
    image: fluent/fluent-bit:2.0.0
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/app
      readOnly: true
  
  volumes:
  - name: app-config
    configMap:
      name: api-config
  - name: app-logs
    emptyDir: {}
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
```

#### **Example 2: Batch Job Pod with Init Container Validation**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: data-migration-job
  namespace: batch-processing
spec:
  restartPolicy: Never  # Don't restart on failure; let controller handle it
  terminationGracePeriodSeconds: 60
  
  initContainers:
  # Validate connectivity to source database
  - name: validate-source-db
    image: postgres:15-alpine
    command:
    - /bin/sh
    - -c
    - |
      echo "Validating source database connectivity..."
      psql -h source-db-cluster.prod -U migration_user \
           -d source_db -c "SELECT 1" \
           || exit 1
      echo "Source DB validation passed"
    env:
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: source-password
  
  # Validate connectivity to destination database
  - name: validate-dest-db
    image: postgres:15-alpine
    command:
    - /bin/sh
    - -c
    - |
      echo "Validating destination database connectivity..."
      psql -h dest-db-cluster.prod -U migration_user \
           -d dest_db -c "SELECT 1" \
           || exit 1
      echo "Destination DB validation passed"
    env:
    - name: PGPASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: dest-password
  
  containers:
  - name: migration-worker
    image: myregistry.azurecr.io/db-migration-tool:v3.2.0
    imagePullPolicy: Always
    
    env:
    - name: SOURCE_DB_HOST
      value: "source-db-cluster.prod"
    - name: SOURCE_DB_USER
      value: "migration_user"
    - name: SOURCE_DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: source-password
    - name: DEST_DB_HOST
      value: "dest-db-cluster.prod"
    - name: DEST_DB_USER
      value: "migration_user"
    - name: DEST_DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: dest-password
    - name: MIGRATION_MODE
      value: "incremental"  # or "full"
    - name: LOG_LEVEL
      value: "DEBUG"
    - name: BATCH_SIZE
      value: "10000"
    
    resources:
      requests:
        cpu: "2"
        memory: "4Gi"
      limits:
        cpu: "4"
        memory: "8Gi"
    
    volumeMounts:
    - name: migration-logs
      mountPath: /var/log/migration
    - name: migration-state
      mountPath: /var/lib/migration
  
  # Sidecar: monitor resource usage and write reports
  - name: resource-monitor
    image: prom/node-exporter:latest
    resources:
      requests:
        cpu: "50m"
        memory: "32Mi"
      limits:
        cpu: "100m"
        memory: "64Mi"
  
  volumes:
  - name: migration-logs
    emptyDir: {}
  - name: migration-state
    emptyDir: {}
```

#### **Example 3: StatefulSet Pod with Ordered Init Containers**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgresql-cluster-member-0
  namespace: databases
spec:
  # Required for graceful shutdown of database
  terminationGracePeriodSeconds: 120
  
  initContainers:
  # Container 1: Wait for cluster bootstrap
  - name: wait-for-cluster-bootstrap
    image: postgres:15-alpine
    command:
    - /bin/sh
    - -c
    - |
      echo "Waiting for cluster bootstrap to complete..."
      until curl -s http://postgresql-cluster-bootstrap:8080/ready; do
        echo "Bootstrap not ready, retrying..."
        sleep 2
      done
      echo "Cluster bootstrap ready"
  
  # Container 2: Initialize data directories
  - name: init-data-directory
    image: postgres:15-alpine
    command:
    - /bin/bash
    - -c
    - |
      if [ ! -d "/var/lib/postgresql/data/base" ]; then
        echo "Initializing PostgreSQL data directory..."
        initdb -D /var/lib/postgresql/data \
               -U postgres \
               -W postgres
        echo "Data directory initialized"
      else
        echo "Data directory already initialized"
      fi
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data
  
  containers:
  - name: postgresql
    image: postgres:15-alpine
    imagePullPolicy: IfNotPresent
    
    ports:
    - containerPort: 5432
      name: postgresql
      protocol: TCP
    - containerPort: 5433
      name: replication
      protocol: TCP
    
    env:
    - name: POSTGRES_USER
      value: "postgres"
    - name: POSTGRES_PASSWORD
      valueFrom:
        secretKeyRef:
          name: postgres-credentials
          key: password
    - name: PGDATA
      value: "/var/lib/postgresql/data/pgdata"
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    
    resources:
      requests:
        cpu: "500m"
        memory: "1Gi"
      limits:
        cpu: "2"
        memory: "4Gi"
    
    livenessProbe:
      exec:
        command:
        - /bin/sh
        - -c
        - pg_isready -U postgres
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    readinessProbe:
      exec:
        command:
        - /bin/sh
        - -c
        - pg_isready -U postgres && psql -U postgres -c "SHOW server_version"
      initialDelaySeconds: 5
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 2
    
    lifecycle:
      preStop:
        exec:
          command:
          - /bin/sh
          - -c
          - |
            echo "Beginning graceful PostgreSQL shutdown..."
            pg_ctl stop -m smart -D /var/lib/postgresql/data/pgdata
            while pg_isready -U postgres; do
              echo "Waiting for PostgreSQL to stop..."
              sleep 2
            done
            echo "PostgreSQL stopped gracefully"
    
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data
    - name: postgres-config
      mountPath: /etc/postgresql
      readOnly: true
  
  volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgresql-storage-0
  - name: postgres-config
    configMap:
      name: postgres-config
```

---

## ReplicaSets and Deployments {#section-4}

### Textual Deep Dive

#### **ReplicaSets: Desired State Enforcement Mechanism** {#replicasets}

A ReplicaSet is a controller that ensures the **specified number of pod replicas are running at all times**. The reconciliation loop operates at typically 5-10 second intervals:

```
ReplicaSet Reconciliation Loop:

┌─────────────────────────────────────────────────────────────┐
│  1. Get ReplicaSet definition from etcd                     │
│     spec.replicas: 3                                        │
├─────────────────────────────────────────────────────────────┤
│  2. Query pods with matching selector labels                │
│     selector:                                               │
│       matchLabels:                                          │
│         app: web-api, version: v2                           │
├─────────────────────────────────────────────────────────────┤
│  3. Count healthy running pods                              │
│     Actual: 2 running pods                                  │
├─────────────────────────────────────────────────────────────┤
│  4. Compare desired vs actual                               │
│     Desired: 3, Actual: 2, Status: DEFICIT                  │
├─────────────────────────────────────────────────────────────┤
│  5. Take corrective action                                  │
│     Create 1 new pod from template                          │
│     Set ownerReference to ReplicaSet                        │
│     Add labels matching selector                            │
├─────────────────────────────────────────────────────────────┤
│  6. Resume monitoring (repeat from step 1)                  │
│     If new pod fails health checks, step 5 repeats          │
│     Loop continues indefinitely                             │
└─────────────────────────────────────────────────────────────┘
```

**Key mechanisms**:

- **Label selectors** (immutable) define which pods are managed
- **Owner references** prevent pods from being claimed by multiple ReplicaSets
- **Pod templates** (spec.template) are blueprints for new replicas
- **Generation field** tracks ReplicaSet updates and enables rollback tracking

#### **Deployments: Rolling Update Orchestration** {#deployments}

Deployments are higher-level controllers that manage ReplicaSets, enabling **zero-downtime updates**. While a ReplicaSet is static, a Deployment actively orchestrates transitions:

```
Deployment Rolling Update Sequence:

Time T0: Deployment specifies image: v1
  ┌─────────────┐
  │ ReplicaSet1 │ (v1)
  │ (5 replicas)│
  │             │
  │  [v1] [v1]  │
  │  [v1] [v1]  │
  │      [v1]   │
  └─────────────┘

Time T10s: User updates image to v2, maxSurge=1
  ┌─────────────┐         ┌──────────────┐
  │ ReplicaSet1 │ (v1)    │ ReplicaSet2  │ (v2)
  │ (3 replicas)│         │ (1 + 1 surge)│
  │             │         │              │
  │  [v1] [v1]  │         │  [v2]        │
  │      [v1]   │         │  [v2]        │
  └─────────────┘         └──────────────┘
  Total: 6 pods (exceeds desired 5, but within surge)

Time T20s: maxUnavailable=1, so RS1 terminates 1 pod
  ┌─────────────┐         ┌──────────────┐
  │ ReplicaSet1 │ (v1)    │ ReplicaSet2  │ (v2)
  │ (2 replicas)│         │ (3 replicas) │
  │             │         │              │
  │  [v1] [v1]  │         │  [v2] [v2]   │
  │             │         │  [v2]        │
  └─────────────┘         └──────────────┘
  Total: 5 pods (matches desired count)

Time T30s: Continue scaling up RS2, scaling down RS1
  ┌─────────────┐         ┌──────────────┐
  │ ReplicaSet1 │ (v1)    │ ReplicaSet2  │ (v2)
  │ (0 replicas)│         │ (5 replicas) │
  │             │         │              │
  │             │         │  [v2] [v2]   │
  │             │         │  [v2] [v2]   │
  │             │         │      [v2]    │
  └─────────────┘         └──────────────┘
  Total: 5 pods (100% v2)
  
  Old ReplicaSet remains with 0 replicas (for rollback)
```

#### **Scaling Strategies: Horizontal Growth** {#scaling}

Scaling in Kubernetes involves two independent mechanisms:

**1. Manual Scaling**
```bash
kubectl scale deployment web-api --replicas=10
kubectl scale rs rs-v2 --replicas=5
```

**2. Horizontal Pod Autoscaler (HPA)**
```
HPA modifies Deployment.spec.replicas based on metrics:

Current CPU: 75%  →  Target: 80%  →  Action: scale down 1 replica
Current CPU: 150% → Target: 80%  →  Action: scale up 10 replicas

Scaling decisions made every 15 seconds (default)
Cooldown prevents flapping: 3 min after scaling down, 0 min after up
```

**Scaling best practices**:
- Resource requests required for HPA; otherwise CPU% meaningless
- Multiple metrics (CPU, memory, custom) work as AND (all must trigger)
- Scale-to-zero often requires custom metrics or eviction rules
- Stateless workloads scale easily; stateful workloads require careful planning

#### **Rolling Updates: Type and Strategy** {#rolling-updates}

The `strategy` field controls upgrade behavior:

```yaml
# RollingUpdate (default, zero-downtime)
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%      # Up to 25% pods can be down during update
    maxSurge: 25%            # Up to 125% of desired pods can run during update
                             # (25% extra replicas created during transition)

# Recreate (full downtime)
strategy:
  type: Recreate            # Delete all old pods before creating new
                            # Useful for: license limits, database migrations
                            # Downtime: Yes, all replicas down briefly
```

**Rolling update timings**:

```
maxUnavailable=1, maxSurge=1, desired=5

T0: Replicas=5 (all v1)
T1: Create v2 (surge +1) → Terminate v1 (-1) = 5 total
T2: Replicas=4 v2, 1 v1 → Create v2 → Terminate v1 = 5 total
T3: Replicas=3 v2, 2 v1 → Create v2 → Terminate v1 = 5 total
T4: Replicas=4 v2, 1 v1 → Create v2 → Terminate v1 = 5 total
T5: Replicas=5 v2, 0 v1 → Rollout complete

Total update time: ~5 * pod_startup_time
```

#### **Rollback Mechanisms: Zero-Loss Version Recovery** {#rollbacks}

Deployments track **revision history** via retained ReplicaSets:

```
Current State:
- Deployment: web-api
  - ReplicaSet: web-api-5f9a7b2d (v2, 5 replicas, **CURRENT**)
  - ReplicaSet: web-api-a8b9c2e1 (v1, 0 replicas)
  - ReplicaSet: web-api-2c3d4e5f (v0, 0 replicas)

Rollback Command:
kubectl rollout undo deployment web-api
  → Restores v1 ReplicaSet to 5 replicas
  → Terminates v2 replicas
  → Traffic automatically redirected (same service endpoint)

History Management:
revisionHistoryLimit: 10  # Keep last 10 ReplicaSets
                          # Older ones auto-deleted (CascadeDelete)
```

**Automated rollback triggers**:
```yaml
progressDeadlineSeconds: 600    # If update doesn't progress in 600s, mark Failed
                                # (doesn't auto-rollback; requires operator action)

# To enable true auto-rollback, need external controller monitoring:
# - Canary: gradually shift traffic, rollback on error rate spike
# - Blue-Green: switch traffic between 2 environments, rollback by flip
# - Progressive delivery: Fluxcd/ArgoFlux with automatic metrics monitoring
```

#### **Revision History and Tracking** {#rollout-strategies}

Each Deployment update creates a new ReplicaSet revision:

```bash
# View full history
kubectl rollout history deployment web-api

# View a specific revision
kubectl rollout history deployment web-api --revision=3

# Rollout to specific revision
kubectl rollout undo deployment web-api --to-revision=2

# Pause rollout (stop during rolling update)
kubectl rollout pause deployment web-api

# Resume rollout
kubectl rollout resume deployment web-api
```

Revision identification uses a hash of pod template spec:
```yaml
metadata:
  annotations:
    deployment.kubernetes.io/revision: "5"  # Automatically set
    
# ReplicaSet inherits revision annotation
# Service sees all ReplicaSets via endpoint controller
# Old ReplicaSets retained for 10 revisions (configurable)
```

#### **Production Best Practices** {#deployment-best-practices}

**1. Maximal Availability During Rollout**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0           # Never drop below desired count
    maxSurge: 50%               # Can temporarily be 150% during rollout
```

**2. Slow Rollout for Risk Mitigation**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1           # Replace one pod at a time
    maxSurge: 1                 # Only 1 extra during transition
```

**3. Health Checks are Non-Negotiable**
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  failureThreshold: 3
  periodSeconds: 10
```

**4. Revision History Management**
```yaml
revisionHistoryLimit: 5  # Keep only 5 old ReplicaSets
                        # Reduces object count in etcd
                        # Risk: Can't rollback beyond limit
```

**5. Update Monitoring**
```bash
kubectl rollout status deployment web-api --timeout=5m
echo $? # Exit code 0 = success, non-zero = failure/timeout
```

#### **Common Pitfalls**

1. **Aggressive maxSurge/maxUnavailable**
   - maxUnavailable: 50% with desired: 2 means 1 pod can be down
   - Spike in resource usage if maxSurge too high
   - Risk: Cluster resource exhaustion during rollout

2. **Pod Affinity Breaking During Rollin Updates**
   ```yaml
   # Anti-affinity prevents pods being placed on same node
   # During RollingUpdate with surge, new pod might violate anti-affinity
   # Update fails if cluster can't place surge pod
   ```

3. **Image Pull Failures in prod on canary/staging nodes**
   - imagePullPolicy: IfNotPresent can cause image staleness
   - New ReplicaSet surge pods fail to pull, blocking rollout
   - mitigated by Always but increases image pull load

4. **Insufficient Progress Deadline**
   - Default 600s insufficient for slow image pulls
   - progressDeadlineSeconds exceeded → deployment marked failed
   - Doesn't auto-rollback; operator must manual undo

5. **Breaking API Changes Without Coordinated Updates**
   - Roll out breaking API change
   - Old client pods still trying to use old endpoint
   - Readiness probes on clients fail, traffic not routed
   - Results in partial outage despite successful deployment

---

### Practical Code Examples

#### **Example 1: Risk-Averse Rolling Update with Comprehensive Health Checks**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-api-service
  namespace: production
  labels:
    app: critical-api
    tier: core-service
spec:
  replicas: 10
  
  # Conservative update strategy for critical production service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1        # Never have fewer than 9 pods
      maxSurge: 1              # Max 11 pods during update
  
  selector:
    matchLabels:
      app: critical-api
  
  # Template for pods created by this deployment
  template:
    metadata:
      labels:
        app: critical-api
        version: v2.1.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
    
    spec:
      # Graceful shutdown config
      terminationGracePeriodSeconds: 30
      
      # Pod anti-affinity: spread across nodes for HA
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
                  - critical-api
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: api
        image: myregistry.azurecr.io/critical-api:v2.1.0
        imagePullPolicy: Always
        
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        - containerPort: 9090
          name: metrics
          protocol: TCP
        
        env:
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "WARN"
        - name: GRACEFUL_SHUTDOWN_TIMEOUT
          value: "25"
        
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        
        # Startup probe: wait for slow startups (up to 120s)
        startupProbe:
          httpGet:
            path: /health/startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 24  # 24 * 5s = 120s
          successThreshold: 1
        
        # Liveness probe: is pod alive and responsive?
        livenessProbe:
          httpGet:
            path: /health/live
            port: http
            httpHeaders:
            - name: X-Custom-Header
              value: "health-check"
          initialDelaySeconds: 30  # Wait for startup
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3      # 3 failures = restart
          successThreshold: 1
        
        # Readiness probe: should traffic be routed here?
        readinessProbe:
          httpGet:
            path: /health/ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 2      # 2 failures = remove from service
          successThreshold: 1
        
        # Graceful shutdown hook
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                echo "Starting graceful shutdown..."
                # Notify load balancer to drain connections
                /usr/local/bin/ready-check disable
                # Give load balancer time to react
                sleep 5
                echo "Shutdown complete"
        
        volumeMounts:
        - name: config
          mountPath: /etc/app/config
          readOnly: true
        - name: secrets
          mountPath: /etc/app/secrets
          readOnly: true
      
      volumes:
      - name: config
        configMap:
          name: critical-api-config
      - name: secrets
        secret:
          secretName: critical-api-secrets
```

#### **Example 2: Canary Deployment with Metrics-Driven Rollback**

```yaml
# This demonstrates the pattern; actual canary requires external controller
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-api-canary
  namespace: production
spec:
  replicas: 40  # Stable baseline
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2
      maxSurge: 10   # Allow surge for canary traffic shift
  
  selector:
    matchLabels:
      app: web-api
      canary: "true"
  
  template:
    metadata:
      labels:
        app: web-api
        canary: "true"
        version: v3.0.0
      annotations:
        fluxcd.io/profile: "canary"
    
    spec:
      containers:
      - name: api
        image: myregistry.azurecr.io/web-api:v3.0.0
        
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        
        resources:
          requests:
            cpu: "250m"
            memory: "256Mi"
          limits:
            cpu: "1000m"
            memory: "512Mi"
        
        livenessProbe:
          httpGet:
            path: /health
            port: http
          periodSeconds: 10
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          periodSeconds: 5
          failureThreshold: 2

---
# Service that routes to canary pods
apiVersion: v1
kind: Service
metadata:
  name: web-api-canary
  namespace: production
spec:
  selector:
    app: web-api
    canary: "true"
  ports:
  - port: 80
    targetPort: 8080
    name: http

---
# Istio VirtualService for traffic splitting (if using service mesh)
# This would split 10% traffic to canary, 90% to stable
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-api
  namespace: production
spec:
  hosts:
  - web-api
  http:
  - match:
    - sourceLabels:
        canary: "true"
    route:
    - destination:
        host: web-api-canary
        port:
          number: 80
      weight: 100
  - route:
    - destination:
        host: web-api-stable
        port:
          number: 80
      weight: 100
```

#### **Example 3: Blue-Green Deployment Pattern**

```yaml
# Blue: Currently running (stable)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-api-blue
  namespace: production
spec:
  replicas: 5
  
  selector:
    matchLabels:
      app: web-api
      version: blue
  
  template:
    metadata:
      labels:
        app: web-api
        version: blue
        slot: blue
    
    spec:
      containers:
      - name: api
        image: myregistry.azurecr.io/web-api:v2.0.0
        
        ports:
        - containerPort: 8080
        
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          periodSeconds: 5
          failureThreshold: 2

---
# Green: New version (not yet receiving traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-api-green
  namespace: production
spec:
  replicas: 5
  
  selector:
    matchLabels:
      app: web-api
      version: green
  
  template:
    metadata:
      labels:
        app: web-api
        version: green
        slot: green
    
    spec:
      containers:
      - name: api
        image: myregistry.azurecr.io/web-api:v3.0.0
        imagePullPolicy: Always
        
        ports:
        - containerPort: 8080
        
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          periodSeconds: 5
          failureThreshold: 2

---
# Service that currently routes to Blue
apiVersion: v1
kind: Service
metadata:
  name: web-api
  namespace: production
spec:
  selector:
    app: web-api
    version: blue  # Points to Blue deployment
  ports:
  - port: 80
    targetPort: 8080
    name: http
  type: ClusterIP

---
# Switch traffic from Blue to Green:
# kubectl patch service web-api -p '{"spec":{"selector":{"version":"green"}}}'
#
# Rollback from Green to Blue:
# kubectl patch service web-api -p '{"spec":{"selector":{"version":"blue"}}}'
```

---

---

## StatefulSets and DaemonSets {#section-5}

### Textual Deep Dive

#### **StatefulSets: Ordered, Persistent Pod Identity** {#statefulsets}

StatefulSets differ fundamentally from Deployments in that **each pod maintains a stable, ordinal identity** across pod restarts:

```
StatefulSet Pod Identity:

pod-0.mysql-cluster.default.svc.cluster.local
pod-1.mysql-cluster.default.svc.cluster.local
pod-2.mysql-cluster.default.svc.cluster.local

↓↓↓ Pod crash and restart ↓↓↓

pod-0.mysql-cluster.default.svc.cluster.local  ← **SAME DNS NAME**
pod-1.mysql-cluster.default.svc.cluster.local  ← **SAME DNS NAME**
pod-2.mysql-cluster.default.svc.cluster.local  ← **SAME DNS NAME**

Contrast with Deployment:
deployment-hash-random-123abc   ← Different pod name after restart
deployment-hash-random-456def   ← Different pod name after restart
```

This stable identity enables **peer discovery** without service discovery queries:

```
N=3 replicas:
pod-0 knows it's the first → might be primary
pod-1 knows it's second → might be replica 1
pod-2 knows it's third → might be replica 2

Each pod can DNS query its peers:
pod-1 can query pod-0.mysql-cluster to find primary
```

**Ordered pod initialization**:

```
StatefulSet startup:

1. Create pod-0, wait for readiness
2. Create pod-1, wait for readiness
3. Create pod-2, wait for readiness
4. All ready: StatefulSet reports ready

One pod failure:
- Only that pod recreated (others unaffected)
- Replaced pod gets same DNS name and ordinal
- Persistent volumes preserved by ordinal matching
```

**Ordered pod termination**:

```
StatefulSet scale-down from 5 to 3:

Terminate order: pod-4 → pod-3 → done (leaves pod-0, 1, 2)

StatefulSet deletion:
- Pods deleted in reverse ordinal order
- Service headless endpoints removed in order
- Ensures graceful primary-to-replica failover if ordered
```

#### **DaemonSets: Node-Level Workload Execution** {#daemonsets}

DaemonSets ensure a **single pod instance runs on each matching node**:

```
DaemonSet Pod Distribution:

Node A (label: node-type: worker)      → pod-0dayjs2
Node B (label: node-type: worker)      → pod-dxf9k3
Node C (label: node-type: worker)      → pod-xyz1a4
Node D (label: gpu: nvidia)            → [ignored, no match]
Master Node (taint: control-plane)     → [skipped, no toleration]

Add Node E (label: node-type: worker):
  → DaemonSet automatically creates pod-aeiou5 on Node E

Remove Node B:
  → DaemonSet pod on Node B terminates (cascade delete)

Change Node A labels (remove node-type: worker):
  → DaemonSet pod evicted from Node A (no longer matches)
```

**Key characteristics**:

- **Node selector and tolerations** filter which nodes receive pods
- **No replicas field** (inherently N replicas = N nodes matching selector)
- **Update strategy** (RollingUpdate or OnDelete) controls upgrade behavior
- **Guaranteed pod placement** (one per matching node, unless eviction)

#### **Use Cases: Stateful vs Stateless Architectural Patterns** {#workload-use-cases}

**StatefulSets Use Cases**:

| Use Case | Why StatefulSet | Kubernetes Feature Required |
|----------|-----------------|----------------------------|
| **Database Clusters (PostgreSQL HA)** | Ordered startup (primary first), stable DNS for replication | Headless Service, PersistentVolumes, ordered init |
| **Distributed Consensus (Zookeeper, Etcd)** | Nodes need peers at known DNS, quorum requires identities | Headless Service, persistent state, ordinal discovery |
| **Message Brokers (Kafka, RabbitMQ)** | Broker IDs tied to ordinal, partition replicas follow order | Persistent volumes, DNS identity |
| **Search Indexes (Elasticsearch)** | Master node election via ordinal, replicas know primary | Ordered startup, persistent state |
| **Cache Clusters (Redis Cluster)** | Slot ownership by ordinal, replicas know primary | Headless Service, stable identity |

**DaemonSet Use Cases**:

| Use Case | Why DaemonSet | Kubernetes Feature Required |
|----------|---------------|--------------------------|
| **Log Aggregation (Fluentd, Filebeat)** | Need agent on every node | Node selector, tolerations for all node types |
| **Monitoring (Node Exporter, Prometheus Agent)** | Node metrics from every node | Host network, node affinity |
| **Networking (Calico, Weave)** | CNI plugin needs presence on all nodes | Host network, daemonset-specific tolerations |
| **GPU Drivers** | GPU nodes need driver daemon | Node selector (gpu: true), DaemonSet scheduling |
| **Security/Audit (Falco, AppArmor)** | Kernel-level monitoring on all nodes | Host namespace access, privileged mode |
| **Time Sync (NTP)** | All nodes need synchronized time | Host network, privileged mode |

#### **Scaling Differences: Replicas vs Node Count** {#workload-scaling}

```
Deployment: Manual or HPA-based scaling
  kubectl scale deployment web-api --replicas=10  # Scale to exactly 10
  kubectl patch deployment web-api -p '{"spec":{"replicas":5}}'  # Scale to 5

StatefulSet: Manual scaling only (HPA not recommended)
  kubectl scale statefulset mysql --replicas=5  # Scale to 5 pods
  Challenges:
  - Scaling up requires data rebalancing (if distributed system)
  - Scaling down loses ordinal state (pod-4 state discarded)
  - Delete and recreate operations complex

DaemonSet: No scaling (determined by node count)
  kubectl label node node-5 workload=logging  # Add matching node
  → DaemonSet auto-creates pod on node-5
  
  kubectl label node node-5 workload-  # Remove matching label
  → DaemonSet pod auto-evicted from node-5
```

#### **Update Strategies: Rolling vs OnDelete**

**StatefulSet Update Strategy**:

```yaml
updateStrategy:
  type: RollingUpdate  # or OnDelete
  rollingUpdate:
    partition: 3       # Only pods >= index 3 updated
```

Rolling update sequence for StatefulSet with partition: 0:
```
Current: pod-0 (v1), pod-1 (v1), pod-2 (v1), pod-3 (v1)
Update to v2:

Step 1: Terminate pod-3 (highest ordinal)
Step 2: Create pod-3 (v2), wait for readiness
Step 3: Terminate pod-2
Step 4: Create pod-2 (v2), wait for readiness
... continue until pod-0 reaches new version
```

The key difference: StatefulSets update **one pod at a time** (always in reverse order), not with surge/unavailable percentages.

**DaemonSet Update Strategy**:

```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1   # Max nodes without pod during update
    maxSurge: 0         # Not applicable for DaemonSets
```

With maxUnavailable: 1 and 100 nodes:
```
Step 1: Evict DaemonSet pod from Node-1; create new v2 pod
Step 2: Once Node-1 pod is ready, evict pod from Node-2; create v2
Step 3: Continue for all 100 nodes sequentially (or in batches)
```

#### **Persistent Workload Management** {#persistent-workloads}

**StatefulSet and Persistent Volumes**:

```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    storageClassName: fast-ssd
    accessModes: [ReadWriteOnce]
    resources:
      requests:
        storage: 100Gi
```

This creates **separate PVCs per pod**:
```
PVC: mysql-0-data (bound to PV-001) → pod-0
PVC: mysql-1-data (bound to PV-002) → pod-1
PVC: mysql-2-data (bound to PV-003) → pod-2

If pod-1 crashes:
  → New pod-1 created
  → PVC mysql-1-data already exists (preserved)
  → New pod-1 bound to same PV-002
  → Data persists across pod lifecycle
```

**DaemonSet Persistent Storage Pattern**:

DaemonSets typically **don't** use PVCs (since pods are ephemeral per node). Instead:
```yaml
# Option 1: hostPath (not recommended for prod)
volumes:
- name: logs
  hostPath:
    path: /var/log/app
    type: DirectoryOrCreate

# Option 2: local storage with node affinity
volumes:
- name: cache
  local:
    path: /mnt/local-storage
nodeSelector:
  storage: local-fast
```

#### **Node Agents and Cluster-Wide Controllers**

DaemonSets implement **cluster-wide control plane extensions**:

```
Kubernetes Architecture with DaemonSet Controllers:

┌──────────────────────────────────────────────┐
│         Kubernetes Control Plane             │
│  ┌──────────────────────────────────────┐   │
│  │ API Server, Scheduler, Controllers   │   │
│  └──────────────────────────────────────┘   │
└──────────────────────────────────────────────┘
           │ Control plane network
           │
┌──────────────────────────────────────────────┐
│          DaemonSet Agent Pods                │
│  (running on every node via DaemonSet)       │
│                                              │
│  Node-1:                                     │
│  ├─ Calico Agent (networking)                │
│  ├─ Prometheus Node Exporter (metrics)       │
│  └─ Fluentd (logging)                        │
│                                              │
│  Node-2:                                     │
│  ├─ Calico Agent (networking)                │
│  ├─ Prometheus Node Exporter (metrics)       │
│  └─ Fluentd (logging)                        │
│                                              │
│  Node-N: ... (same pattern)                  │
└──────────────────────────────────────────────┘
```

Each DaemonSet agent:
- Runs cluster-wide enforcement (network policies via Calico)
- Collects telemetry (metrics, logs)
- Manages node-local resources (drivers, kernel modules)
- Coordinates with control plane via API or sideband channels

#### **Ordered Deployment Patterns**

StatefulSets enable **ordered startup** for systems requiring:
1. Primary election
2. Quorum agreement
3. Cluster bootstrap sequence

Example: PostgreSQL HA with streaming replication:

```
pod-0 startup:
1. Initialize data directory
2. Start as primary (no replication)
3. Open for connections

pod-1 startup sequence:
1. Wait for pod-0 readiness (via init container)
2. Initialize archive recovery from pod-0 WAL
3. Start as replica
4. Connect to pod-0 as primary

pod-2 startup sequence:
1. Wait for pod-1 readiness
2. Stream WAL from pod-0
3. Start as standby

Key: Ordinal ordering ensures primary starts before replicas attempt connection
```

#### **Production Best Practices** {#workload-best-practices}

1. **Use StatefulSets Only for Truly Stateful Systems**
   - Temptation: Use StatefulSet for persistent pod naming
   - Reality: Deployments + Persistent Volumes are simpler for most apps
   - Reserve StatefulSets for: databases, caches, distributed systems

2. **Headless Services Mandatory for StatefulSets**
   ```yaml
   spec:
     clusterIP: None  # No virtual IP; DNS returns pod IPs directly
   ```

3. **DaemonSet Tolerations Must Cover All Node Types**
   ```yaml
   tolerations:
   - key: node-role.kubernetes.io/control-plane
     operator: Exists
     effect: NoSchedule
   - key: workload
     operator: Equal
     value: batch
     effect: NoExecute
   ```

4. **Partition for Canary Updates**
   ```yaml
   updateStrategy:
     type: RollingUpdate
     rollingUpdate:
       partition: 2  # Only update pod-2 and above; test before updating pod-0, 1
   ```

5. **Pod Disruption Budgets for StatefulSets**
   ```yaml
   podDisruptionBudget:
     minAvailable: 2  # Maintain quorum during maintenance
   ```

#### **Common Pitfalls**

1. **Assuming Pod DNS is Immediately Available**
   - DNS name exists only after pod is running
   - Init container waiting for peer DNS will timeout/retry

2. **Data Loss from Scale-Down**
   - Scaling StatefulSet from 3 to 2 loses pod-2 data
   - PVC is **not** deleted (but pod is gone)
   - Manual PVC cleanup required to avoid orphans

3. **DaemonSet Pod Eviction Surprises**
   - Changing node label selector → pods evicted unexpectedly
   - Node taints without DaemonSet tolerations → pods evicted
   - Debugging: kubectl describe node to check taints

4. **StatefulSet Rolling Update Too Aggressive**
   - OnDelete requires manual pod deletion (slow, error-prone)
   - RollingUpdate too fast causes unavailability (test partition)
   - Production DBs need maxUnavailable: 1 with validation between updates

5. **Resource Requests on DaemonSets**
   - DaemonSets run on every node; aggregated resources compound
   - DaemonSet with requests: 500m CPU → 500m * 100 nodes = 50 CPU cores
   - Impact: Reduces capacity for workload pods

---

### Practical Code Examples

#### **Example 1: PostgreSQL Highly Available StatefulSet**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
  namespace: databases
data:
  postgresql.conf: |
    max_connections = 200
    shared_buffers = 256MB
    effective_cache_size = 1GB
    maintenance_work_mem = 64MB
    wal_level = replica
    max_wal_senders = 10
    max_replication_slots = 10
  pg_hba.conf: |
    # Allow connections from replicas
    host replication all 0.0.0.0/0 md5

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-cluster
  namespace: databases
spec:
  clusterIP: None  # Headless service
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgresql

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
  namespace: databases
spec:
  serviceName: postgres-cluster  # Headless service name
  replicas: 3
  
  # Update strategy: one pod at a time, starting from highest ordinal
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0
  
  selector:
    matchLabels:
      app: postgres
  
  template:
    metadata:
      labels:
        app: postgres
    
    spec:
      terminationGracePeriodSeconds: 60
      
      # Initialize pod-0 as primary, pod-1+ as replicas
      initContainers:
      - name: init-postgres
        image: postgres:15-alpine
        command:
        - /bin/bash
        - -c
        - |
          set -e
          ORDINAL=$(hostname | rev | cut -d '-' -f1 | rev)
          
          if [ "$ORDINAL" = "0" ]; then
            echo "Primary node initialization (pod-0)"
            # Only pod-0 initializes the cluster
            if [ ! -d /var/lib/postgresql/data/base ]; then
              initdb -D /var/lib/postgresql/data \
                     -U postgres \
                     -E utf8 \
                     --lc-collate=C --lc-ctype=C
            fi
          else
            echo "Standby node waiting for primary (pod-0)..."
            until pg_isready -h postgres-cluster.databases.svc.cluster.local -p 5432 -U postgres; do
              echo "Primary not ready, retrying..."
              sleep 2
            done
            echo "Primary is ready. Standby will connect via replication."
          fi
        
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        - name: postgres-config
          mountPath: /etc/postgresql
      
      containers:
      - name: postgres
        image: postgres:15-alpine
        imagePullPolicy: IfNotPresent
        
        ports:
        - containerPort: 5432
          name: postgresql
        
        env:
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        - name: POSTGRES_INITDB_ARGS
          value: "-c max_connections=200"
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "2000m"
            memory: "2Gi"
        
        # Liveness: is postgres running?
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness: can postgres accept connections?
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres && psql -U postgres -c "SELECT 1"
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
        
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                pg_ctl stop -m smart -D /var/lib/postgresql/data/pgdata
                while pg_isready -U postgres; do sleep 1; done
        
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        - name: postgres-config
          mountPath: /etc/postgresql
      
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
                  - postgres
              topologyKey: kubernetes.io/hostname
      
      volumes:
      - name: postgres-config
        configMap:
          name: postgres-config
  
  # Persistent volume claims (one per pod)
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      storageClassName: fast-ssd
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 100Gi

---
# Pod Disruption Budget to maintain HA during maintenance
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: postgres-pdb
  namespace: databases
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: postgres
```

#### **Example 2: Logging DaemonSet (Fluentd)**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: monitoring
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      read_from_head true
      
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    <filter kubernetes.**>
      @type kubernetes_metadata
      kubernetes_url "#{ENV['FLUENT_FILTER_KUBERNETES_URL'] || 'http://kubernetes.default.svc.cluster.local:443'}"
      verify_ssl false
    </filter>
    
    <match **>
      @type stdout
    </match>

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
  namespace: monitoring
  labels:
    app: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  
  # Rolling update: update one node at a time
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  
  template:
    metadata:
      labels:
        app: fluentd
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "24231"
    
    spec:
      # Tolerate all node types (master, workers, etc.)
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 300
      
      # Run on all nodes
      hostNetwork: false
      dnsPolicy: ClusterFirst
      
      containers:
      - name: fluentd
        image: fluent/fluent-bit:2.0.0
        imagePullPolicy: IfNotPresent
        
        ports:
        - containerPort: 24231
          name: metrics
        
        env:
        - name: FLUENT_ELASTICSEARCH_HOST
          value: "elasticsearch.logging"
        - name: FLUENT_ELASTICSEARCH_PORT
          value: "9200"
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
        
        livenessProbe:
          httpGet:
            path: /api/v1/health
            port: 24231
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /api/v1/health
            port: 24231
          initialDelaySeconds: 10
          periodSeconds: 5
        
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: config
          mountPath: /fluent-bit/etc/
      
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: config
        configMap:
          name: fluentd-config
```

---

## Jobs and CronJobs {#section-6}

### Textual Deep Dive

#### **Jobs: One-Time Batch Task Execution** {#jobs-overview}

Jobs are controllers designed for **batch processing and one-off tasks** that should complete and terminate (unlike Deployments which run indefinitely):

```
Job Lifecycle and Pod States:

┌──────────────────────────────────────────────────────┐
│          Job Execution Timeline                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  T0: kubectl apply (job created)                     │
│    status.conditions: [type: Suspended=false]        │
│    spec.parallelism: 1                               │
│    Pod created                                       │
│                                                      │
│  T1-T5: Pod running, processing batch work           │
│    Pod CPU/Memory consumption peaks                  │
│    PID 1 executes work: processes files, etc.        │
│                                                      │
│  T6: Pod completes (exit code 0)                     │
│    Job controller detects success                    │
│    status.completions: 1/1                           │
│                                                      │
│  T7: Job status changes to Complete                  │
│    status.conditions: [type: Complete=true]          │
│    Pod not restarted (restartPolicy: Never)          │
│                                                      │
│  T8: Job cleanup (if ttlSecondsAfterFinished: 600)   │
│    Job and pods deleted after 10 minutes             │
│    (if ttlSecondsAfterFinished specified)            │
│                                                      │
└──────────────────────────────────────────────────────┘

Failure Case:

T6: Pod fails (exit code 1, or OOM kill)
  → Job controller checks backoffLimit (default: 6)
  → Retries: creates new pod
  → If all retries exhausted: Job marked Failed
  → No further pod creation
```

#### **Job Configuration: Parallelism and Completions** {#job-retry}

```yaml
spec:
  completions: 100         # Run 100 successful pod-tasks total
  parallelism: 10          # Run max 10 pods concurrently
  backoffLimit: 3          # Retry up to 3 times before giving up
  activeDeadlineSeconds: 3600  # Hard timeout: 1 hour
  ttlSecondsAfterFinished: 86400  # Auto-delete after 24 hours
```

**Execution semantics**:

```
completions: 100, parallelism: 10

Timeline:
T0: Start pods 1-10 (parallelism)
T1: Pod 1 completes → completed: 1/100 → start pod 11
T2: Pod 2 completes → completed: 2/100 → start pod 12
...
T10: Pod 10 completes → completed: 10/100 → start pod 20
...
T100: Pod 100 completes → completed: 100/100 → Job done

Total time: ~(completions / parallelism) * pod_duration
```

#### **Failure Handling and Retry Logic**

```
Retry Behavior:

A pod fails (exit code non-zero, or OOM, or node crashed)

backoffLimit: 0
  → Job fails immediately, no retries
  → One pod failure = job failure

backoffLimit: 1
  → One retry allowed
  → Failure, retry once, if second attempt fails → Job fails

backoffLimit: 6 (default)
  → Up to 6 retries before giving up
  → Exponential backoff: 1s → 2s → 4s → 8s → 16s → 32s → 5m cap
  → If all 6 retries fail → Job marked Failed

activeDeadlineSeconds: 3600
  → Hard timeout: if job runs > 1 hour, force kill pods
  → Override for runaway jobs (infinite loops)
  → Useful for batch jobs with expected duration SLA
```

#### **CronJobs: Scheduled Task Execution** {#cronjobs}

CronJobs create Jobs on a schedule (similar to Unix crontab):

```
CronJob manages Job creation:

┌──────────────────────────────────────────┐
│  CronJob Specification                   │
│  schedule: "0 2 * * *"  (2 AM daily)     │
│  jobTemplate: {...}      (Job template)  │
│  concurrencyPolicy: Allow (or Forbid)    │
│  successfulJobsHistoryLimit: 3           │
│  failedJobsHistoryLimit: 1               │
└──────────────────────────────────────────┘
       │
       │ CronJob controller evaluates schedule every 10s
       │
       ├─→ Previous execution still running?
       │   Check concurrencyPolicy:
       │   - Allow: create new job (allow overlap)
       │   - Forbid: skip execution (single job max)
       │   - Replace: delete old job, start new
       │
       ├─→ Schedule matched?
       │   └─→ YES: Create new Job object
       │       Job then creates pods and executes
       │
       └─→ Finished jobs older than history limit?
           └─→ YES: Delete old jobs to maintain cleanup
```

**Cron expression reference**:

```
"0 2 * * *"
 │ │ │ │ └─ Day of week (0-6, 0=Sunday)
 │ │ │ └─── Month (1-12)
 │ │ └───── Day of month (1-31)
 │ └─────── Hour (0-23)
 └───────── Minute (0-59)

Examples:
"0 2 * * *"      → 2:00 AM every day
"0 2 * * MON"    → 2:00 AM every Monday
"0 2 1 * *"      → 2:00 AM on 1st of each month
"0 */4 * * *"    → Every 4 hours (0:00, 4:00, 8:00, etc.)
"*/15 * * * *"   → Every 15 minutes
"0 0 * * *"      → Midnight every day
"0 0 1 1 *"      → New Year's Day midnight
```

**Concurrency policies**:

| Policy | Behavior | Use Case |
|--------|----------|----------|
| **Allow** (default) | Previous execution doesn't block new creation | Non-exclusive operations (logs, reports) |
| **Forbid** | Skip execution if previous job still running | DB backups, migrations (must not overlap) |
| **Replace** | Delete previous job, start new one | Long-running jobs that should be interrupted |

#### **Completion Tracking and Job Status**

```yaml
status:
  # Job completion status
  active: 2           # 2 pods currently running
  succeeded: 8        # 8 pods completed successfully
  failed: 1           # 1 pod failed (within backoffLimit)
  
  # Timestamps
  startTime: 2026-03-10T14:00:00Z
  completionTime: 2026-03-10T14:45:00Z
  
  # Conditions
  conditions:
  - type: Complete
    status: "True"
    reason: "Completed"
  - type: Failed
    status: "False"
```

**Job success criteria**:
- `succeeded >= completions` (all required pods succeeded)
- `failed < backoffLimit` (retries haven't been exhausted)
- Pod exits with code 0

**Job failure states**:
1. `Failed` condition with `reason: BackoffLimitExceeded`
2. `Failed` condition with `reason: DeadlineExceeded`
3. `Failed` condition with `reason: PodFailurePolicy` (new, for advanced logic)

#### **Use Cases: When Jobs vs Deployments**

| Scenario | Use Job | Reason |
|----------|---------|--------|
| **Batch data processing** | ✓ | Process defined dataset, exit when done |
| **Long-running API** | ✗ | Deployment (always running) |
| **Report generation** | ✓ | Generate report, cleanup, exit |
| **Database migration** | ✓ | Schema migration, then complete |
| **ETL pipeline** | ✓ | Extract, transform, load, exit |
| **Web application** | ✗ | Deployment (continuously serve) |
| **Cache warmup** | ✓ | Initialize cache, exit (on startup) |
| **Scheduled cleanup** | ✓ | CronJob (periodic runs) |
| **Message queue consumer** | ✗ | Deployment (continuous consumption) |

#### **Differences from Deployments** {#job-use-cases}

| Aspect | Deployment | Job |
|--------|-----------|-----|
| **Restart Policy** | Always (restarts on exit) | Never/OnFailure (respect completion) |
| **Success Criteria** | Running indefinitely | All pods complete with exit 0 |
| **Scaling** | HPA based on metrics | Manual parallelism adjustment |
| **Replica Count** | Dynamic via replicas field | parallelism + completions |
| **Pod Lifecycle** | Continuous (replaced on failure) | Temporary (deleted after completion) |
| **Use Case** | Long-running services | Batch/one-off tasks |

#### **Production Best Practices** {#job-best-practices}

1. **Always Specify activeDeadlineSeconds**
   ```yaml
   activeDeadlineSeconds: 3600  # 1 hour timeout
   ```
   Prevents runaway jobs from consuming resources indefinitely.

2. **Use Appropriate backoffLimit**
   ```yaml
   backoffLimit: 3  # Conservative for prod
   ```
   Default of 6 can mask issues; 3 is safer for batch workloads.

3. **Set ttlSecondsAfterFinished for Cleanup**
   ```yaml
   ttlSecondsAfterFinished: 86400  # Delete after 24 hours
   ```
   Prevents job objects from accumulating in etcd.

4. **History Limits for CronJobs**
   ```yaml
   successfulJobsHistoryLimit: 3
   failedJobsHistoryLimit: 1
   ```
   Keep only recent job history; older jobs auto-deleted.

5. **Resource Requests for backoff Calculation**
   ```yaml
   resources:
     requests:
       cpu: "500m"
       memory: "256Mi"
   ```
   Without requests, scheduler can't place job pods if cluster full.

6. **Monitoring Job Duration**
   ```bash
   kubectl get jobs -w  # Watch job completion
   kubectl logs job/my-job  # Collect logs during/after execution
   ```
   Track job.status.completionTime for SLA enforcement.

#### **Common Pitfalls**

1. **Missing activeDeadlineSeconds**
   - Job hangs if pod gets stuck (infinite loop, deadlock)
   - Resources consumed indefinitely
   - No automatic cleanup

2. **Underestimating Pod Startup Time**
   - Image pull on large clusters can be slow
   - Init containers add delay
   - If pod startup > scheduled interval, CronJob overlap issues

3. **Assuming Cron Accuracy**
   - CronJob evaluated every 10-100 seconds (not precise)
   - Timezone handling complex (use UTC in expressions)
   - Cron expression errors silently skipped

4. **Job History Explosion**
   - CronJob running hourly for 1 year = 8,760 jobs
   - Each job has status, owner references, conditions
   - Unchecked history causes etcd bloat

5. **Database Connection Pool Exhaustion**
   - N parallel jobs × connection pool size
   - If parallelism: 100 and pool size: 20, connections exhausted
   - Use connection pooling sidecars or init containers

---

### Practical Code Examples

#### **Example 1: Data Processing Job with Retry Logic**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-aggregation-job
  namespace: batch-jobs
spec:
  # Request 100 successful completions
  completions: 100
  
  # Run 10 pods in parallel
  parallelism: 10
  
  # Retry failed pods up to 3 times before giving up
  backoffLimit: 3
  
  # Hard timeout: 2 hours for entire job
  activeDeadlineSeconds: 7200
  
  # Auto-delete job 24 hours after completion
  ttlSecondsAfterFinished: 86400
  
  # Track completion progress
  completionMode: Indexed  # or "NonIndexed"
  
  selector:
    matchLabels:
      job-name: data-aggregation-job
  
  template:
    metadata:
      labels:
        app: data-processor
        job-name: data-aggregation-job
    
    spec:
      # Don't restart containers on failure; let Job controller handle retry
      restartPolicy: Never
      
      # Set deadline for pod termination
      activeDeadlineSeconds: 1800  # 30 minutes per pod
      
      # Init container validates dependencies
      initContainers:
      - name: check-src-data
        image: curlimages/curl:7.85.0
        command:
        - /bin/sh
        - -c
        - |
          echo "Validating source data availability..."
          until curl -s http://data-source-api:8080/health; do
            echo "Data source unavailable, retrying..."
            sleep 2
          done
          echo "Data source is ready"
      
      containers:
      - name: aggregator
        image: myregistry.azurecr.io/data-processor:v1.2.0
        imagePullPolicy: Always
        
        # Job-specific configuration
        env:
        - name: JOB_COMPLETION_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
        - name: DATA_SOURCE_URL
          value: "http://data-source-api:8080"
        - name: OUTPUT_URL
          value: "http://result-storage:9000"
        - name: BATCH_SIZE
          value: "5000"
        - name: LOG_LEVEL
          value: "INFO"
        
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        
        volumeMounts:
        - name: shared-data
          mountPath: /data
        - name: scratch
          mountPath: /tmp
      
      volumes:
      - name: shared-data
        emptyDir: {}
      - name: scratch
        emptyDir: {}
      
      # Cleanup pods after job completes
      ttlSecondsAfterFinished: 86400

---
# Monitor job progress
apiVersion: batch/v1
kind: Job
metadata:
  name: job-monitor-example
  namespace: batch-jobs
spec:
  completions: 1
  parallelism: 1
  backoffLimit: 1
  activeDeadlineSeconds: 600
  
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: monitor
        image: bitnami/kubectl:latest
        command:
        - /bin/sh
        - -c
        - |
          # Wait for job completion and report status
          while true; do
            STATUS=$(kubectl get job data-aggregation-job -o jsonpath='{.status.succeeded}/{.status.completions}')
            echo "Job progress: $STATUS"
            if [ "$(kubectl get job data-aggregation-job -o jsonpath='{.status.conditions[?(@.type==\"Complete\")].status}')" = "True" ]; then
              echo "Job completed successfully"
              exit 0
            fi
            if [ "$(kubectl get job data-aggregation-job -o jsonpath='{.status.conditions[?(@.type==\"Failed\")].status}')" = "True" ]; then
              echo "Job failed"
              exit 1
            fi
            sleep 10
          done
```

#### **Example 2: CronJob for Database Backup**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
  namespace: databases
spec:
  # 2 AM every day (UTC)
  schedule: "0 2 * * *"
  
  # Don't run if previous backup still in progress
  concurrencyPolicy: Forbid
  
  # Keep only 3 successful job history
  successfulJobsHistoryLimit: 3
  
  # Keep only 1 failed job history
  failedJobsHistoryLimit: 1
  
  # Timezone (optional, requires CronJob v1beta1+ with TZ support)
  # timeZone: "America/New_York"
  
  # Job template (created at each schedule trigger)
  jobTemplate:
    spec:
      completions: 1
      parallelism: 1
      backoffLimit: 2
      activeDeadlineSeconds: 3600  # 1 hour timeout
      
      ttlSecondsAfterFinished: 604800  # Keep backup metadata 7 days
      
      template:
        metadata:
          labels:
            app: postgres-backup
        
        spec:
          restartPolicy: OnFailure
          
          serviceAccountName: backup-agent  # For cloud storage auth
          
          containers:
          - name: backup
            image: postgres:15-alpine
            imagePullPolicy: IfNotPresent
            
            env:
            - name: PGHOST
              value: postgres-cluster.databases.svc.cluster.local
            - name: PGUSER
              value: postgres
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-credentials
                  key: password
            - name: BACKUP_DATE
              value: "$(date +%Y-%m-%d-%H%M%S)"
            - name: AWS_REGION
              value: "us-east-1"
            - name: S3_BUCKET
              value: "company-db-backups"
            
            resources:
              requests:
                cpu: "500m"
                memory: "512Mi"
              limits:
                cpu: "2000m"
                memory: "2Gi"
            
            command:
            - /bin/bash
            - -c
            - |
              set -e
              BACKUP_FILE="postgres-backup-$(date +%Y-%m-%d-%H%M%S).sql.gz"
              
              echo "Starting PostgreSQL backup..."
              pg_dump -c -C postgres | gzip > /tmp/$BACKUP_FILE
              echo "Backup size: $(du -h /tmp/$BACKUP_FILE | cut -f1)"
              
              echo "Uploading to S3..."
              aws s3 cp /tmp/$BACKUP_FILE s3://${S3_BUCKET}/$BACKUP_FILE
              echo "Backup uploaded to S3"
              
              echo "Verifying backup..."
              aws s3 ls s3://${S3_BUCKET}/$BACKUP_FILE
              echo "Backup complete"
              
              # Cleanup local file
              rm /tmp/$BACKUP_FILE

---
# ServiceAccount with S3 permissions
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backup-agent
  namespace: databases

---
# ClusterRoleBinding for backup access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backup-agent
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["postgres-credentials"]  # Only access backup secret

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backup-agent
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backup-agent
subjects:
- kind: ServiceAccount
  name: backup-agent
  namespace: databases
```

#### **Example 3: Job with Custom Metrics Export**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: log-analysis-job
  namespace: analytics
spec:
  completions: 5
  parallelism: 5
  backoffLimit: 2
  activeDeadlineSeconds: 5400  # 90 minutes
  ttlSecondsAfterFinished: 86400
  
  template:
    metadata:
      labels:
        app: log-analyzer
        job: log-analysis
    
    spec:
      restartPolicy: Never
      
      containers:
      - name: analyzer
        image: myregistry.azurecr.io/log-analyzer:v2.0.0
        
        env:
        - name: JOB_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['batch.kubernetes.io/job-completion-index']
        - name: LOG_SOURCE
          value: "s3://company-logs/$(date +%Y-%m-%d)"
        - name: RESULTS_ENDPOINT
          value: "http://elasticsearch:9200"
        - name: METRICS_PUSHGATEWAY
          value: "prometheus-pushgateway:9091"
        
        resources:
          requests:
            cpu: "1000m"
            memory: "1Gi"
          limits:
            cpu: "2000m"
            memory: "2Gi"
        
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - ps aux | grep analyzer | grep -v grep
          initialDelaySeconds: 10
          periodSeconds: 30
          timeoutSeconds: 5
      
      # Metrics exporter sidecar
      - name: metrics-exporter
        image: prom/pushgateway:latest
        ports:
        - containerPort: 9091
          name: metrics
        
        resources:
          requests:
            cpu: "50m"
            memory: "64Mi"
          limits:
            cpu: "100m"
            memory: "128Mi"
```

---

## Hands-on Scenarios {#section-7}

### Scenario 1: Debugging a Deployment Stuck in Rolling Update {#scenario-1}

**Problem Statement**

A critical API service (`web-api`) started a rolling update from v2.0 to v2.1 two hours ago. Status shows:
```bash
$ kubectl rollout status deployment web-api
error: deployment "web-api" exceeded its progress deadline

$ kubectl get deployment web-api
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
web-api   8/10    5            8           2h
```

The deployment is stuck—8 pods ready, but still waiting for 2 more. Users are experiencing intermittent API errors (503s). The team is considering manual rollback but wants to understand the root cause first.

**Architecture Context**

- **Cluster capacity**: 10 nodes, each with 4CPU, 8Gi RAM available
- **Deployment spec**:
  ```yaml
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 2
  progressDeadlineSeconds: 600  # 10 minutes
  ```
- **Image pull time**: ~60 seconds on average
- **Pod startup time**: ~30 seconds (includes init container database migration)
- **New image size**: 1.2GB (much larger than v2.0 at 400MB)
- **Container resources**: requests: 500m CPU, 512Mi memory

**Troubleshooting Steps**

**Step 1: Check ReplicaSet Status**
```bash
# View all ReplicaSets for this deployment
kubectl get rs -l app=web-api
NAME             DESIRED   CURRENT   READY   AGE
web-api-5f9a7b  10        10        8       2h10m       (v2.1, new)
web-api-a8b9c2  0         0         0       3h          (v2.0, old)

# Describe the current ReplicaSet to see events
kubectl describe rs web-api-5f9a7b

# Look for:
# - FailedScheduling events (pod scheduling issues)
# - BackOff errors (container pulling backoff)
```

**Step 2: Inspect Pending Pods**
```bash
# Find which pods are stuck
kubectl get pods -l app=web-api --sort-by=.metadata.creationTimestamp
NAME                     READY   STATUS              RESTARTS   AGE
web-api-5f9a7b-abc1     1/1     Running             0          90m
web-api-5f9a7b-abc2     1/1     Running             0          88m
... (8 Ready pods)
web-api-5f9a7b-xyz1     0/1     ImagePullBackOff    0          10m
web-api-5f9a7b-xyz2     0/1     ContainerCreating   0          5m

# Describe a stuck pod
kubectl describe pod web-api-5f9a7b-xyz1
Events:
  Type     Reason                 Age    Message
  ----     ------                 ----   -------
  Normal   Scheduled              10m    Successfully assigned production/web-api-5f9a7b-xyz1
  Normal   BackOff                5m     Back-off pulling image "myregistry.azurecr.io/web-api:v2.1.0"
  Warning  Failed                 2m     Error response from daemon: ...pull limit exceeded...
```

**Root Cause Analysis**

The issue is **image pull rate limiting**. With 10 nodes pulling a 1.2GB image simultaneously:
- Registry rate limiting engaged
- Image pull backoff activated
- Nodes can't complete image pulls within progressDeadlineSeconds

**Step 3: Verify Node Disk Space**
```bash
# Check each node's container image storage
kubectl describe node node-1 | grep -A 10 "Allocated resources"

# Check for disk pressure
kubectl get nodes -o wide
# Look for "DiskPressure" condition

# SSH to node and check docker disk usage
docker system df
```

**Resolution**

**Option A: Extend Progress Deadline (Short-term)**
```bash
kubectl patch deployment web-api -p '{"spec":{"progressDeadlineSeconds":1800}}'
```
Gives 30 minutes instead of 10 for image pulls. However, this masks the underlying issue.

**Option B: Implement Image Pull Strategy (Recommended)**

Modify the deployment to prevent image pull storms:

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # Reduce from 2 to 1; pull one image at a time
      maxUnavailable: 0    # Ensure availability during rollout
  template:
    spec:
      containers:
      - name: web-api
        image: myregistry.azurecr.io/web-api:v2.1.0
        imagePullPolicy: IfNotPresent  # Avoid repulling if already present
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8080
          failureThreshold: 30
          periodSeconds: 10  # 5-minute startup window for slow pulls
```

**Step 4: Pre-warm the Image (Production Best Practice)**

Before deploying to production, use a `DaemonSet` to pre-pull the image:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: image-puller
spec:
  selector:
    matchLabels:
      app: image-puller
  template:
    metadata:
      labels:
        app: image-puller
    spec:
      containers:
      - name: puller
        image: myregistry.azurecr.io/web-api:v2.1.0
        command: ["sleep", "3600"]  # Just sleep; image already pulled
      terminationGracePeriodSeconds: 1
```

Deploy this first to pull the image on all nodes, then deploy the actual Deployment.

**Best Practices Applied**

1. **Graduated maxSurge**: 1 instead of 2 prevents image pull storms
2. **Extended startupProbe**: Gives sufficient time for large images
3. **imagePullPolicy**: IfNotPresent after image is pre-warmed
4. **DaemonSet pre-warming**: Separates image pull concern from deployment
5. **Monitoring**: Track image pull duration per node

---

### Scenario 2: Fixing Data Loss During StatefulSet Rolling Update {#scenario-2}

**Problem Statement**

A Kafka StatefulSet was updated from 3 to 5 replicas, then scaled back to 3 during load testing. Now production is experiencing data loss—messages that were supposed to be replicated are gone. Investigation shows:

```bash
$ kubectl get statefulset kafka
NAME   READY   AGE
kafka  3/3     20d

$ kubectl get pvc | grep kafka
kafka-data-0    Bound   pv-001
kafka-data-1    Bound   pv-002
kafka-data-2    Bound   pv-003
kafka-data-3    Bound   pv-004  ← Orphaned (pod deleted but PVC remains)
kafka-data-4    Bound   pv-005  ← Orphaned (pod deleted but PVC remains)
```

The orphaned PVCs contain unreplicated data from the short-lived brokers 3 and 4.

**Architecture Context**

- **Kafka cluster**: 3-broker production setup
- **Replication factor**: 2 (default for Kafka in Kubernetes)
- **Scale-up scenario**: Scaled to 5 brokers for load testing
- **Scale-down**: Deleted the StatefulSet; PVCs were not deleted
- **Mistake**: Re-created StatefulSet with 3 replicas without preserving data from brokers 3-4

**Root Cause Analysis**

StatefulSet deletion with `cascadeDeletion: true` (default) **does not** delete PVCs:
```bash
# When StatefulSet is deleted, PVCs are orphaned
kubectl delete statefulset kafka
# PVCs remain: kafka-data-0, kafka-data-1, kafka-data-2, kafka-data-3, kafka-data-4

# When new StatefulSet is created with 3 replicas
kubectl apply -f kafka-statefulset.yaml
# New pods bind to kafka-data-0, kafka-data-1, kafka-data-2 (old PVCs)
# kafka-data-3 and kafka-data-4 are left orphaned with inaccessible data
```

The Kafka brokers that held replicas are permanently lost because their data was on pods 3 and 4.

**Prevention and Recovery**

**Recovery Steps (if data is still needed)**

```bash
# 1. Identify orphaned PVCs
kubectl get pvc | grep -v "bound-to-pod"

# 2. Examine PV content (requires manual access)
kubectl describe pvc kafka-data-3
# Note the PV name: pv-004

# 3. Create a recovery pod to inspect orphaned data
kubectl run recovery-pod --image=ubuntu -it -- /bin/bash
# Mount the orphaned PVC to examine/restore data

# 4. If data is valuable, create a new clone:
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: kafka-recovery
spec:
  containers:
  - name: recovery
    image: busybox
    command: ["sh", "-c", "tar czf /archive/kafka-broker-3.tar.gz /data/"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: kafka-data-3
EOF

# 5. Extract archived data for manual replication
```

**Prevention Best Practices**

**1. Explicit PVC Deletion Policy**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
spec:
  serviceName: kafka
  replicas: 3
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Delete    # Explicitly delete PVCs when StatefulSet deleted
    whenScaled: Retain     # Keep PVCs when scaling down (safer)
  
  volumeClaimTemplates:
  - metadata:
      name: kafka-data
    spec:
      storageClassName: replicated-ssd
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 500Gi
```

The `whenScaled: Retain` policy keeps PVCs even if StatefulSet is scaled down—critical for distributed systems where data matters.

**2. Backup Before Scale Operations**

```bash
# Pre-scale backup procedure
# 1. Take snapshot of current PVCs
for i in {0..4}; do
  kubectl exec kafka-$i -c kafka -- kafka-configs.sh --bootstrap-server localhost:9092 \
    --describe --entity-type brokers > /backups/kafka-broker-$i-config.txt
done

# 2. Export topic replication status
kubectl exec kafka-0 -c kafka -- kafka-topics.sh \
  --bootstrap-server localhost:9092 --describe > /backups/kafka-topics.txt

# 3. Now safe to scale
kubectl scale statefulset kafka --replicas=5
# ... test ...
kubectl scale statefulset kafka --replicas=3

# 4. Verify replication is healthy
kubectl exec kafka-0 -c kafka -- kafka-replica-verification.sh \
  --bootstrap-server localhost:9092 --topic-white-list '*'
```

**3. Decommissioning for Distributed Systems**

For Kafka, never abruptly delete brokers. Instead:

```bash
# 1. Graceful broker decommissioning
# Tell other brokers to migrate replicas away from broker-4
kubectl exec kafka-0 -c kafka -- kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --topics-to-move-json-file brokers-to-remove.json \
  --broker-list "0,1,2" \
  --generate > reassign-plan.json

# 2. Execute the reassignment
kubectl exec kafka-0 -c kafka -- kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassign-plan.json \
  --execute

# 3. Monitor progress
kubectl exec kafka-0 -c kafka -- kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassign-plan.json \
  --verify

# 4. Only then scale down the StatefulSet
kubectl scale statefulset kafka --replicas=2
```

**Permanent PVC Cleanup**

Once you're certain data is not needed:

```bash
# List and verify orphaned PVCs
kubectl get pvc --sort-by=.metadata.creationTimestamp

# Delete with confirmation
kubectl delete pvc kafka-data-3 kafka-data-4

# Verify PVs are also reclaimed (depends on reclaim policy)
kubectl get pv | grep kafka-data
```

**Lessons Learned**

1. **StatefulSet scaling is not trivial** for distributed systems
2. **PVC lifecycle is independent** of pod lifecycle
3. **Data safety requires explicit planning** before scale operations
4. **Decommissioning procedures** differ from simple Deployment deletion
5. **Monitoring and alerting** on replica distribution is essential

---

### Scenario 3: Optimizing Job Parallelism for ETL Pipeline Performance {#scenario-3}

**Problem Statement**

An ETL job that processes 10,000 data files is taking 45 minutes to complete. The job is configured with:

```yaml
spec:
  completions: 10000
  parallelism: 10
  backoffLimit: 3
```

Each file takes ~20 seconds to process. With only 10 parallel workers, the job runs for ~3,350 seconds (56 minutes). The SLA requires completion in under 30 minutes.

The team wants to increase parallelism to 100 but is concerned about:
- Database connection pool exhaustion
- Resource cluster exhaustion
- OOM kills during scaling

**Architecture Context**

- **Cluster resources**: 20 nodes × (8 CPU, 32Gi RAM) = 160 CPU, 640Gi total
- **Pod resource request**: 500m CPU, 512Mi RAM each
- **Database pool size**: 20 connections (hardcoded in app)
- **File source**: S3 with rate limits of 100 req/second
- **Output**: PostgreSQL with psycopg2 driver

**Optimization Analysis**

**Step 1: Calculate Theoretical Throughput**

With current 10 parallel workers:
```
Processing time per file: 20s
Files: 10,000
Workers: 10
Total time: (10,000 / 10) * 20s = 20,000s = 5.5 hours

With parallelism: 100:
Total time: (10,000 / 100) * 20s = 2,000s = 33 minutes (close to SLA)

With parallelism: 150:
Total time: (10,000 / 150) * 20s = 1,333s = 22 minutes (exceeded SLA)
```

Parallelism should be between **100-150** to meet the 30-minute SLA.

**Step 2: Validate Cluster Resource Capacity**

```bash
# Current utilization with parallelism: 10
Used: 10 × 500m = 5 CPU, 10 × 512Mi = 5Gi RAM
Available: 160 CPU, 640Gi (plenty of headroom)

# Proposed with parallelism: 100
Used: 100 × 500m = 50 CPU, 100 × 512Mi = 50Gi RAM
Available: 160 CPU, 640Gi (still has 110 CPU, 590Gi free)

# Threshold: parallelism: 320
Used: 320 × 500m = 160 CPU (cluster maxed out)
```

Cluster can handle parallelism up to **~300 before exhaustion**. Safe upper bound: 150.

**Step 3: Database Connection Pool Analysis**

The critical constraint is the 20-connection database pool. With 100 workers:

```
If each worker holds a connection for entire job duration:
  100 workers > 20 pool size → DEADLOCK

Solution: Connection pooling sidecar
  - Wait for connection to become available (pool.acquire())
  - Execute query (average: 2-3 seconds per file)
  - Release connection immediately (pool.release())
  - Process next batch
```

Without changes to the application, parallelism must stay below **20** to avoid deadlock.

**Step 4: Optimize Application Code**

Modify the ETL worker to use **connection pooling correctly**:

```python
# BEFORE (holds connection for entire payload)
conn = psycopg2.connect(dsn)
while True:
    file = queue.get()
    data = process_file(file)  # 20 seconds, connection held!
    cursor = conn.cursor()
    cursor.execute(insert_sql, data)
    conn.commit()
    queue.task_done()

# AFTER (connection held only during INSERT)
pool = psycopg2.pool.SimpleConnectionPool(5, 10, dsn)
while True:
    file = queue.get()
    data = process_file(file)  # 20 seconds, NO connection held
    
    conn = pool.getconn()
    try:
        cursor = conn.cursor()
        cursor.execute(insert_sql, data)
        conn.commit()
    finally:
        pool.putconn(conn)  # Release immediately
    
    queue.task_done()
```

With this change, 20 connections can serve 100+ workers (connections are released after 2-3 seconds).

**Step 5: S3 Rate Limiting Analysis**

S3 has rate limits:
- 100 req/sec per partition
- 3,500 PUT req/sec per bucket

With 100 parallel workers each reading one file:
- Request rate: 100 req/sec (at S3's limit)
- Potential for throttling

Add exponential backoff to S3 operations:

```python
import boto3
from botocore.exceptions import ClientError
import time
import random

def get_s3_file_with_backoff(bucket, key, max_retries=5):
    s3 = boto3.client('s3')
    
    for attempt in range(max_retries):
        try:
            return s3.get_object(Bucket=bucket, Key=key)['Body'].read()
        except ClientError as e:
            if e.response['Error']['Code'] == 'SlowDown':
                wait_time = (2 ** attempt) + random.uniform(0, 1)
                print(f"S3 throttled, waiting {wait_time}s")
                time.sleep(wait_time)
            else:
                raise
```

**Step 6: Implement Batch Job Configuration**

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: etl-batch-optimized
spec:
  completions: 10000
  parallelism: 100      # Optimized based on pool analysis
  backoffLimit: 3
  activeDeadlineSeconds: 1800  # 30-minute SLA
  ttlSecondsAfterFinished: 86400
  
  template:
    spec:
      restartPolicy: Never
      terminationGracePeriodSeconds: 60
      
      containers:
      - name: etl-worker
        image: myregistry.azurecr.io/etl-worker:v2.1.0
        
        env:
        - name: WORKER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
        - name: S3_BUCKET
          value: company-data-lake
        - name: DB_POOL_SIZE
          value: "5"          # Per-worker pool size
        - name: DB_MAX_OVERFLOW
          value: "10"         # Allow temporary overflow
        - name: LOG_LEVEL
          value: "WARN"
        - name: BATCH_SIZE
          value: "100"        # Files per batch
        
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
        
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - 'test -f /tmp/worker_heartbeat && [ $(($(date +%s) - $(stat -c %Y /tmp/worker_heartbeat))) -lt 60 ]'
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 2
```

**Monitoring and Validation**

```bash
# Monitor job progress in real-time
watch -n 5 'kubectl get job etl-batch-optimized -o jsonpath="{.status.succeeded}/{.status.completions}"'

# Collect metrics
kubectl logs job/etl-batch-optimized | tail -20

# Expected output:
# Started 100 workers
# Completing 1-2 files per second (100 workers × 20s per file)
# Job duration: 20,000 / 100 × 20s ≈ 33 minutes (under SLA)
```

**Final Performance Results**

| Metric | Before | After |
|--------|--------|-------|
| Parallelism | 10 | 100 |
| Job Duration | 56 min | 33 min |
| SLA Compliance | ✗ (exceeds) | ✓ (under SLA) |
| Cluster CPU Used | 5 CPUs | 50 CPUs |
| Cluster Headroom | 155 CPUs | 110 CPUs |
| DB Connection Contention | None | Resolved via pooling |

---

### Scenario 4: StatefulSet Ordered Startup and Primary Election {#scenario-4}

**Problem Statement**

A 5-node PostgreSQL StatefulSet is experiencing issues during node replacement. When node-2 is removed, the cluster temporarily loses a replication standby. The cluster is then readd having these crash scenarios:

1. **Data corruption** on newly promoted primary
2. **Replication slots orphaned** from deleted standby
3. **Recovery time objective (RTO)** exceeds 15 minutes (SLA)

The team acknowledges that StatefulSet ordering guarantees initial startup, but questions how they enforce primary election and standby ordering.

**Architecture Context**

- **Cluster**: 5-node PostgreSQL with streaming replication
- **Primary**: pod-0
- **Standbys**: pod-1, pod-2, pod-3, pod-4
- **Replication slots**: 4 (one per standby)
- **Disk failure scenario**: pod-2 node fails, PVC becomes unavailable

**Primary Election Mechanism**

PostgreSQL doesn't automatically elect a primary in Kubernetes. This requires:

1. **Init containers** to detect current primary
2. **Lifecycle hooks** for promotion
3. **External coordinator** (etcd/Patroni) for leader election

**Step 1: Implement Leader Election with ConfigMap**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-cluster-config
  namespace: databases
data:
  primary_pod: "postgres-0"  # Manual annotation of current primary

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-cluster
spec:
  replicas: 5
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0  # Update all pods
  
  template:
    spec:
      initContainers:
      # Determine if this pod should start as primary or standy
      - name: determine-role
        image: postgres:15-alpine
        command:
        - /bin/bash
        - -c
        - |
          ORDINAL=$(hostname | rev | cut -d '-' -f1 | rev)
          NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
          
          # Check ConfigMap for current primary
          PRIMARY=$(kubectl get cm postgres-cluster-config \
            -n $NAMESPACE -o jsonpath='{.data.primary_pod}' 2>/dev/null || echo "postgres-0")
          
          PRIMARY_ORDINAL=$(echo $PRIMARY | rev | cut -d '-' -f1 | rev)
          
          echo "Current primary: $PRIMARY (ordinal: $PRIMARY_ORDINAL)"
          echo "This pod: postgres-$ORDINAL"
          
          if [ "$ORDINAL" = "$PRIMARY_ORDINAL" ]; then
            echo "Starting as PRIMARY"
            echo "primary" > /tmp/pod_role
          else
            echo "Starting as STANDBY"
            echo "standby" > /tmp/pod_role
          fi
        
        volumeMounts:
        - name: role-detection
          mountPath: /tmp
      
      # Wait for primary to be ready before standbys connect
      - name: wait-for-primary
        image: curlimages/curl:7.85.0
        command:
        - /bin/sh
        - -c
        - |
          ORDINAL=$(hostname | rev | cut -d '-' -f1 | rev)
          POD_ROLE=$(cat /tmp/pod_role)
          
          if [ "$POD_ROLE" = "primary" ]; then
            echo "Primary pod, no need to wait"
          else
            echo "Standby pod, waiting for primary to be ready..."
            until curl -s http://postgres-0.postgres-cluster.databases.svc.cluster.local:5432; do
              echo "Primary not ready, retrying..."
              sleep 2
            done
            echo "Primary is ready, proceeding with replication setup"
          fi
        
        volumeMounts:
        - name: role-detection
          mountPath: /tmp
      
      containers:
      - name: postgres
        image: postgres:15-alpine
        
        env:
        - name: POSTGRES_INITDB_ARGS
          value: "-c max_connections=200 -c wal_level=replica"
        
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/bash
              - -c
              - |
                sleep 5  # Wait for DB to fully start
                
                POD_ROLE=$(cat /tmp/pod_role)
                ORDINAL=$(hostname | rev | cut -d '-' -f1 | rev)
                
                if [ "$POD_ROLE" = "primary" ]; then
                  echo "Configuring PRIMARY..."
                  psql -U postgres -c "CREATE ROLE replicator REPLICATION LOGIN PASSWORD 'secret';"
                  psql -U postgres -c "CREATE SLOT standby_slot PHYSICAL;"
                elif [ "$POD_ROLE" = "standby" ]; then
                  echo "Configuring STANDBY..."
                  # Standby will connect to primary via init container setup
                fi
        
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        - name: role-detection
          mountPath: /tmp
      
      volumes:
      - name: role-detection
        emptyDir: {}
  
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: [ReadWriteOnce]
      resources:
        requests:
          storage: 100Gi
```

**Step 2: Handle Pod Failure and Promote Standby**

When pod-0 (primary) fails:

```bash
# 1. Detect primary failure (via external monitoring)
kubectl exec postgres-1 -c postgres -- pg_isready -h postgres-0.postgres-cluster
# Connection refused → Primary is down

# 2. Promote standby to primary (manual or via Patroni)
kubectl exec postgres-1 -c postgres -- pg_ctl promote

# 3. Update ConfigMap to reflect new primary
kubectl patch cm postgres-cluster-config -p \
  '{"data":{"primary_pod":"postgres-1"}}'

# 4. Guide remaining standbys to new primary
# (Done automatically by Kubernetes DNS update)
```

**Step 3: Handle Node Failure and Pod Replacement**

When node-2 fails and pod-2's PVC becomes unavailable:

```bash
# 1. Check PVC status
kubectl get pvc postgres-data-2
NAME                    STATUS   VOLUME
postgres-data-2        Bound    pv-xyz

# 2. If node cannot be recovered, delete PVC to allow rebind
kubectl delete pvc postgres-data-2

# 3. StatefulSet recreates pod-2 with same ordinal
# New pod-2 starts as standby (from init container logic)
# Initializes from WAL archive or takes full backup from primary

# 4. High Availability is restored
```

**Step 4: Use Patroni for Automatic HA (Production Best Practice)**

For true automatic failover, use Patroni (Kubernetes-native distributed configuration management):

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-ha-patroni
spec:
  replicas: 5
  serviceName: postgres-patroni
  
  template:
    spec:
      containers:
      - name: patroni
        image: patroni:2.1.0
        
        env:
        - name: SCOPE
          value: postgres-ha
        - name: PATRONI_POSTGRESQL_HOST_PORT
          value: "0.0.0.0:5432"
        - name: PATRONI_POSTGRESQL_DATA_DIR
          value: "/var/lib/postgresql/pgdata"
        - name: PATRONI_DCS_TYPE
          value: "kubernetes"
        - name: PATRONI_K8S_NAMESPACE
          value: databases
        - name: PATRONI_K8S_LABELS
          value: "app=postgres-ha"
        
        ports:
        - containerPort: 5432
          name: postgresql
        - containerPort: 8008
          name: patroni
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8008
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /health
            port: 8008
          periodSeconds: 5
        
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql
      
      volumes:
      - name: postgres-data
        persistentVolumeClaim:
          claimName: postgres-data-{{ .Values.replicaIndex }}
```

Patroni automatically:
- Detects primary failure
- Promotes best standby based on WAL lag
- Updates VIP for connection routing
- Manages replication slots
- Handles node failures transparently

**RTO Improvement**

| Scenario | Without Patroni | With Patroni |
|----------|-----------------|--------------|
| Primary node failure | 10-15 min (manual) | 30-60 seconds (automatic) |
| Standby node failure | 20-30 min (rebuild) | 2-5 min (rejoin) |
| Network split | Manual intervention | Consensus-based election |
| Full cluster loss | N/A (data loss anyway) | N/A |

---

## Interview Questions for Senior DevOps Engineers {#section-8}

### Architecture & Design Questions {#arch-questions}

#### **Question 1: Design a Highly Available Multi-Tier SaaS Application**

*Scenario*: You're asked to design a SaaS application with 1,000 concurrent users, a PostgreSQL database, Redis cache, and Kafka message queue. Describe the Kubernetes workload strategy for each component and justify why.

**Expected Answer**:

This question tests understanding of when to use each workload type and architectural decisions at scale.

```
Application Tier (Web API):
- Workload Type: Deployment
- Rationale: 
  * Stateless; requests routed to any replica
  * HPA for dynamic scaling based on CPU/RPS
  * Rolling updates for zero-downtime deployments
  * Resource requests: CPU for scheduling, memory for cluster packing
  
- Configuration:
  replicas: 5 (baseline for 1k users)
  min/max HPA: 5-50 (burst to 20k concurrent)
  strategy: RollingUpdate with maxSurge: 50%, maxUnavailable: 25%
  pod anti-affinity: Spread replicas across 3+ nodes for HA

Cache Tier (Redis):
- Workload Type: StatefulSet
- Rationale:
  * Ordered startup ensures primary election before replicas connect
  * Stable DNS for cluster-aware client (knows slot distribution)
  * Persistent volumes for cache data durability
  * Cannot use Deployment (no automatic failover for distributed cache)
  
- Configuration:
  replicas: 3 (primary + 2 replicas for Sentinel)
  serviceName: redis-cluster (headless)
  updateStrategy: RollingUpdate with partition
  volumeClaimTemplates: one per pod for persistence

Database Tier (PostgreSQL):
- Workload Type: StatefulSet
- Rationale:
  * Primary-replica replication requires ordered startup
  * Persistent volumes for data durability (critical)
  * Stable DNS for replica discovery
  * Requires init containers for primary detection
  
- Configuration:
  replicas: 3 (primary + 2 standbys)
  serviceName: postgres-cluster
  volumeClaimTemplates: 500Gi per pod
  init containers: wait-for-primary, configure-replication
  PDB: minAvailable: 2 (maintain quorum during maintenance)

Event Queue (Kafka):
- Workload Type: StatefulSet
- Rationale:
  * Broker IDs tied to ordinal identity
  * Partition replicas must follow broker order for Zookeeper election
  * Requires persistent volumes for commit logs
  
- Configuration:
  replicas: 3 (consensus quorum)
  serviceName: kafka-cluster
  volumeClaimTemplates: 1Ti per broker (adequate for message throughput)
  broker.id: $ORDINAL (set via init container)

Monitoring/Logging (Observability):
- Workload Type: DaemonSet
- Rationale:
  * Need agent on every node for complete visibility
  * Log collection and metric export required on all nodes
  * Node-level concerns (kernel metrics, container logs)

Additional Components:
- Ingress Controller: Deployment (entry point, scalable)
- Certificate Manager: Deployment (stateless, manages TLS)
- External Secrets Operator: Deployment (fetch secrets from vault, stateless)
- Config Reloader: DaemonSet (watch ConfigMaps, trigger pod restarts)

HA Requirements:
- PodDisruptionBudgets on all stateful workloads (minAvailable based on quorum)
- Pod anti-affinity: Spread replicas across different nodes/zones
- Resource requests: Enable intelligent bin-packing
- Health checks: Liveness (auto-restart), readiness (traffic routing)
- Backup strategy: Automated snapshots of databases and caches every 6 hours

Scaling Strategy:
- HPA on Deployment workloads only
- StatefulSet scaling: Manual, with decommissioning procedures
- DaemonSet: Auto-scales with cluster (no config needed)
```

**Why This Answer is Senior Level**:
- Distinguishes workload types by architectural properties, not just "database = StatefulSet"
- Addresses HA explicitly (PDB, anti-affinity, quorum)
- Considers ordering (Kafka broker election, PostgreSQL replication)
- Recognizes that stateful workloads require careful scaling procedures
- Mentions init containers and lifecycle hooks for complex setups

---

#### **Question 2: When Would You Use DaemonSet Over Deployment + PodAntiAffinity?**

*Scenario*: Your monitoring team wants to deploy Prometheus node exporter. They suggest using a Deployment with replicas: (number of nodes) and pod anti-affinity. You need to explain why DaemonSet is correct.

**Expected Answer**:

DaemonSet guarantees one podbper matching node automatically; Deployment does not.

```
Fundamental Difference:
- DaemonSet: Kubernetes automatically creates one pod per matching node
  * Add new node → DaemonSet pod automatically created
  * Remove node → DaemonSet pod automatically evicted
  * No manual intervention required
  
- Deployment + Anti-Affinity: Manual synchronization needed
  * Add new node → Operator must scale replicas from N to N+1
  * Risk: If operator forgets, new node has no monitoring
  * Racing condition: Pod scheduled before anti-affinity prevents co-location

Practical Difference in Production:

Scenario: Cluster scales from 10 to 50 nodes (e.g., auto-scaling on traffic spike)

With Deployment:
  Time T0: kubectl apply deployment node-exporter (replicas: 10)
  Time T1-T10: 10 pods land on 10 nodes, spread evenly
  Time T11: Node auto-scaler adds 40 new nodes due to pending pods
  Time T12-T50: ← NEW NODES HAVE NO MONITORING
           Pod nodes are: 1-10 (monitoring)
           New nodes: 11-50 (NO monitoring!)
           
           Metrics missing for 40 nodes during scaling event (exactly when we need monitoring most)
  Time T51: Operator notices missing metrics, manually scales Deployment to 50 replicas
  Time T52-T61: New exporter pods finally schedule on remaining nodes

With DaemonSet:
  Time T0: kubectl apply daemonset node-exporter
  Time T1-T10: 10 pods created on 10 nodes
  Time T11: Node auto-scaler adds 40 new nodes
  Time T12: DaemonSet controller detects new nodes, automatically creates 40 pods
  Time T13-T22: 40 new pods schedule and become ready (all nodes now monitored)
  
  → No gap in monitoring during scaling event!
```

**Technical Justification**:

```yaml
# DaemonSet Advantages:
1. Declarative state matches reality
   DaemonSet spec: "I want a pod on every node"
   → Kubernetes automatically enforces this
   
2. Tolerations more flexible
   DaemonSet with tolerations: noSchedule, noExecute
   → Controls which nodes receive pods via tolerations
   → More flexible than pod anti-affinity (which is a constraint, not a guarantee)
   
3. Scale-to-zero risk eliminated
   Deployment could be accidentally scaled to 0 replicas
   → Application blindly continues, losing monitoring
   DaemonSet ensures minimum 1 per matching node (can't "accidentally" delete)

Example: Rolling Update of Node Exporter on 100 nodes

DaemonSet: maxUnavailable: 10
- Update 10 nodes at a time
- Kubernetes automatically maintains 90 monitored nodes throughout
- Automatic rolling cycle: 10 updates

Deployment (hypothetically): replicas: 100, pod anti-affinity
- Operator manually patches all 100 replicas
- If 50 pods are terminated before new ones schedule,
  monitoring is partially lost
- If pod anti-affinity prevents placement on a node,
  operator must manually intervene
```

**When NOT to Use DaemonSet**:
- If workload is optional (e.g., dev-only logging to local disk)
  → Use Deployment + manual scaling
- If workload should run on subset of nodes
  → Use Deployment + node affinity (cleaner than DaemonSet + node selectors)
- If replicas > nodes
  → Must use Deployment (DaemonSet can't have more pods than nodes)

---

#### **Question 3: StatefulSet Partition Field: When and Why Would You Use It?**

*Scenario*: A Kafka StatefulSet update is being tested. The team proposes using partition: 2, meaning only brokers 2+ will update first. Explain why this is or isn't a good practice.

**Expected Answer**:

The partition field is a **canary deployment mechanism** for StatefulSets, useful but requires understanding of distributed system semantics.

```
Partition Explained:
- partition: 2 means: "Only update pods with ordinal >= 2"
- Pods 0 and 1 stay on old version
- Pod 2 and above update to new version
- Allows testing new version before updating leader/primary

Kafka Example:

Current: 5 brokers (v2.7.0)
  broker-0 (v2.7.0) - leader of many partitions
  broker-1 (v2.7.0)
  broker-2 (v2.7.0)
  broker-3 (v2.7.0)
  broker-4 (v2.7.0)

Update to v3.0.0 with partition: 2:

Step 1: Update broker-4 first
  ← Highest ordinal; least critical
  Kafka leadership can failover to broker-0, 1, 2, 3
  ← Safe canary!
  
  broker-0 (v2.7.0) - leader
  broker-1 (v2.7.0)
  broker-2 (v2.7.0)
  broker-3 (v2.7.0)
  broker-4 (v3.0.0) ← NEW VERSION

Step 2: Monitor broker-4
  - Check logs for errors
  - Monitor disk usage, latency
  - Verify no rebalancing occurred
  - If OK, manually remove partition: 2 to continue update

Step 3: If broker-4 is stable, remove partition field
  broker-0 (v2.7.0) - leader
  broker-1 (v2.7.0)
  broker-2 (v2.7.0)
  broker-3 (v3.0.0) ← UPDATE NOW
  broker-4 (v3.0.0)

Potential Issues with Kafka Specifically:

Problem: Broker-4 is new version, brokers 0-3 are old
  → Version mismatch could cause protocol incompatibilities
  → If v3.0.0 uses new wire protocol, v2.7.0 brokers might not understand
  → Could cause replication lag or leader election failures

Safe Application Scenarios:

✓ Application servers (backward-compatible APIs)
  Old: v2.0 (responds to API v2)
  New: v2.1 (responds to API v2 AND v3)
  → Mixture works fine, clients route correctly

✗ Distributed systems with tight coupling
  Old: Kafka v2.7 (uses protocol X)
  New: Kafka v3.0 (uses protocol Y)
  → If protocol X and Y aren't compatible, chaos ensues

For Kafka, better approach:
- Disable all rebalancing (broker config)
- Update brokers in partition: 2 fashion
- Monitor ISR (in-sync replicas) for each topic
- Once v3.0 brokers are stable, continue partition field → enable rebalancing
- THEN update v2.7 brokers
```

**When to Use Partition**:

```yaml
# 1. For stateless-like services (tolerant of version mixes)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: api-servers-canary
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 3  # Test on pod-3, 4, 5 first
  
  # Rationale: API servers handle mixed versions via backwards compatibility

# 2. For testing breaking changes before full rollout
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database-experimental
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2  # Replicas 2+ test new schema
  
  # Rationale: Data schema changes need validation on subset first

# 3. For gradual rollout of large image pulls
# (Avoid saturating registry)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: large-app
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 8  # Only update pod-8, 9 at a time
```

**When NOT to Use Partition**:

- For systems requiring strict version consistency (Zookeeper, consensus algorithms)
- For distributed systems with shared state (version mismatch = corruption risk)
- For database migrations (old and new schemas can't coexist)

---

### Operations & Troubleshooting Questions {#ops-questions}

#### **Question 4: A Job Completes Successfully But Pods Are Still Running. What Happened?**

*Scenario*: A data export Job shows:
```
status.succeeded: 100
status.completions: 100  → Job appears complete
status.active: 3         → But 3 pods still running!
```

What's happening, and how do you fix it?

**Expected Answer**:

This indicates **graceful termination is taking a very long time**, not a real problem.

```
Root Cause Analysis:

Background: Job completion ≠ Pod termination

Sequence of Events:
T0: Pod 100 completes (exit code 0)
T1: Job controller detects 100/100 succeeded
T2: Job status.conditions marked "Complete"
T3: Job controller sends termination signal to remaining pods
T4: Pods enter "Terminating" state
T4-T34: Pods have 30 seconds (terminationGracePeriodSeconds) to shutdown
T35: Force termination (SIGKILL)
T35+: Pods disappear

When you check status at T5-T34:
- Job reports "CompletionStatus: Completed" ✓
- BUT 3 pods still in Terminating state
- This is EXPECTED behavior!

Why Pods Take Time to Terminate:

1. PreStop hook execution
   spec:
     terminationGracePeriodSeconds: 30
     lifecycle:
       preStop:
         exec:
           command: ["sleep", "15"]  ← Takes 15 seconds

2. In-flight request completion
   App receives SIGTERM, but processes requests for 10 more seconds
   
3. Database connection draining
   App exports data, closes all DB connections (slow)
   
4. Cleanup operations
   Temp files, resource release, etc.

Diagnosis:

$ kubectl get jobs
NAME        COMPLETIONS   DURATION   AGE
data-export 100/100       1h23m      1h25m

$ kubectl get pods -l job-name=data-export
NAME                READY   STATUS        RESTARTS   AGE
data-export-abc1   0/1     Terminated    0          1h
data-export-abc2   0/1     Terminating   0          45s ← Still shutting down
data-export-abc3   0/1     Terminating   0          30s
```

**Fix**:

If pods are stuck terminating after 30 seconds:

```bash
# Option 1: Increase grace period (if app needs more cleanup time)
kubectl patch job data-export -p \
  '{"spec":{"template":{"spec":{"terminationGracePeriodSeconds":120}}}}'
# Restarts job with new grace period

# Option 2: Force delete pod (if process is truly stuck)
kubectl delete pod data-export-abc2 --grace-period=0 --force

# Option 3: Check what's preventing termination
kubectl describe pod data-export-abc2 | grep -A 20 Events
# Look for: "waiting for termination" or exit code

# Check container logs for shutdown errors
kubectl logs data-export-abc2 --previous
# Might show: "Error closing database connection"
```

**Prevention**:

```yaml
apiVersion: batch/v1
kind: Job
spec:
  template:
    spec:
      terminationGracePeriodSeconds: 60  # Give 60 seconds instead of 30
      containers:
      - name: exporter
        image: data-export:v1
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                # Graceful shutdown logic
                echo "Gracefully closing..."
                kill -TERM 1    # Send SIGTERM to PID 1
                sleep 5         # Wait for process to finish
                # Container exits within 5-10 seconds normally
```

This is **not a bug**—it's normal Kubernetes behavior. Jobs complete logically before pods physically terminate.

---

#### **Question 5: Deployment Rolling Update Stuck: Pods in ImagePullBackOff. What's the Real Problem?**

*Scenario*: A Deployment update is stalled:
```
NAME           READY   STATUS              AGE
web-api-old-1  1/1     Running             2h
web-api-old-2  1/1     Running             2h
web-api-new-1  0/1     ImagePullBackOff    30m
web-api-new-2  0/1     ImagePullBackOff    20m

kubectl describe pod web-api-new-1 | grep Events
  Failed: Error response from daemon: pull rate limit exceeded
```

The old pods are running fine. New image is available. What's the root cause, and how do you solve it?

**Expected Answer**:

This is **registry rate limiting**, a hidden production pain point.

```
Registry Behavior:

Azure Container Registry (ACR):
  - Rate limit: 200 pulls per 20 minutes per IP
  - 10 nodes pulling simultaneously
  - Pull duration: ~60 seconds per image (1.5GB)
  
Sequence of Events:
T0: Deployment rolling update starts
  → maxSurge: 2 creates 2 new pods concurrently
  
T1-T10: Nodes 1-2 pull image
  → ACR begins rate limiting other nodes
  
T11: Node 3 attempts pull → 429 Too Many Requests
  → kubelet backs off exponentially
  
T20: Node 4 attempts pull → Rate limited again
  → Backoff: 1m → 2m → 4m → 8m
  
T30: New pods still pulling (or failing)
  → Deployment stuck with surge pods unable to start
  
T60+: If backoff limit reached, pods fail
  → Deployment can't progress
```

**Diagnosis**:

```bash
# Check image pull errors
kubectl describe pod web-api-new-1 | grep -i "rate\|limit\|forbidden"

# Check with docker pull directly
docker pull myregistry.azurecr.io/web-api:v2.2.0
# Error: HTTP 429 Too Many Requests

# Verify image exists and size
az acr repository show --name myregistry --repository web-api --query 'imageSize'

# Check network egress limits (Azure)
az container registry show --name myregistry --query 'status'
```

**Solutions**:

**Short-term (immediate fix)**:

```bash
# Pause the rollout to stop creating new surge pods
kubectl rollout pause deployment web-api

# Wait for backoff to reset (usually 5-10 minutes)
sleep 600

# Continue rollout
kubectl rollout resume deployment web-api
```

**Medium-term (reduce pull pressure)**:

```yaml
# Reduce maxSurge to pull one image at a time
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # Only 1 new pod at a time
      maxUnavailable: 0    # Keep availability
```

**Long-term (pre-pull image)**:

```yaml
# DaemonSet pre-warms image on all nodes before deployment
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: image-preloader
spec:
  template:
    spec:
      containers:
      - name: puller
        image: myregistry.azurecr.io/web-api:v2.2.0
        command: ["sleep", "3600"]  # Just sleep; image is already pulled
      terminationGracePeriodSeconds: 1  # Can be killed immediately
  
  # Wait for image pull to succeed on all nodes
  # $ kubectl wait --for=condition=ready pod -l app=image-preloader --timeout=600s
  # Then trigger Deployment update
```

**Registry-level fixes**:

1. **Increase registry tier** (Azure Standard → Premium)
   - Standard: 200 pulls/20min
   - Premium: No rate limits
   
2. **Use regional replicas** if multi-region
   - Pull from closest region to reduce bandwidth
   - Less contention on single registry

3. **Implement image caching proxy**
   ```yaml
   # Harbor or Docker Registry acting as proxy
   # Nodes pull from local cache instead of upstream registry
   ```

4. **Split image size**
   - 1.5GB image → 500MB base + 1GB app
   - Reduces pull time, improves rate-limit resilience

**Best Practice**:

```bash
# Before any deployment:
1. Trigger DaemonSet image preload
2. Wait for success on all nodes (kubectl wait ...)
3. Trigger Deployment rolling update
4. Update completes with pre-warmed images (no pull storms)
```

This prevents rate-limit surprises during production deployments.

---

#### **Question 6: StatefulSet Pod Pod-0 Crashed. Pod-1 Can't Connect to Pod-0. Why?**

*Scenario*: PostgreSQL StatefulSet:
- pod-0 (primary) crashes
- pod-1 (replica) is trying to connect to pod-0.postgres-cluster.default.svc.cluster.local
- Connection timeout after 30 seconds
- pod-0 is marked NotReady (due to crash), but DNS still returns its IP

What's happening, and how do you fix it?

**Expected Answer**:

This is a **DNS consistency issue** related to readiness probes and Kubernetes DNS endpoints.

```
Kubernetes Endpoint Behavior:

Normal State:
- pod-0 is Running and ReadyProbes pass
- DNS: pod-0.postgres-cluster → 10.1.2.3
- Endpoints: postgres-cluster.default.svc.cluster.local → {10.1.2.3, 10.1.2.4}

Pod-0 Crashes:
T0: kubelet detects crash (process exited)
T1: pod-0.status = "Running" (still considered running, but crash happened)
T2: pod-0.spec (readinessProbe failed)
T3: Endpoint controller removes pod-0 from endpoints (headless service)
T4: DNS query for pod-0.postgres-cluster:
    - Direct pod DNS: STILL returns 10.1.2.3 (pod exists, though crashed)
    - Service DNS: ONLY returns 10.1.2.4 (pod-0 removed from endpoints)

The Problem:
pod-1 is configured to connect to:
  primary_host: postgres-cluster.postgres-cluster.default.svc.cluster.local
  
But it's trying:
  postgresql_replica REPLICATION CONNECT TO PRIMARY
  → Connection string: "host=postgres-cluster port=5432 ..."
  
If using headless service with direct IP from pod-0.postgres-cluster DNS:
  → Connects to IP 10.1.2.3 (crashed pod!)
  → Connection establishment fails (no process listening)
  → 30-second timeout (TCP connect times out)
  
If using service name postgres-cluster (not headless):
  → Endpoint controller already removed 10.1.2.3
  → DNS returns only 10.1.2.4
  → Connection succeeds immediately
```

**Why This Happens**:

```bash
# Headless service (used by StatefulSets):
$ nslookup postgres-cluster.default.svc.cluster.local
Server: 10.96.0.10
Address: 10.96.0.10:53

Non-authoritative answer:
postgres-cluster.default.svc.cluster.local canonical name = postgres-cluster.default.svc.cluster.local.
postgres-cluster.default.svc.cluster.local has address 10.1.2.3  (pod-0, CRASHED!)
postgres-cluster.default.svc.cluster.local has address 10.1.2.4  (pod-1)

# The problem: Both IPs returned, including crashed pod-0

# Compare with regular service:
$ nslookup postgres-service.default.svc.cluster.local
Address: 10.1.2.4  (ONLY pod-1, pod-0 removed by endpoint controller)
```

**The Root Cause**:

StatefulSets use **headless services** which return **all pod IPs**—both Ready and NotReady.
This is by design (apps need all replicas), but creates a problem if app naively tries the first address.

**Solution 1: Use publishNotReadyAddresses: false (Correct)**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-cluster
spec:
  clusterIP: None  # Headless
  selector:
    app: postgres
  publishNotReadyAddresses: false  # ← Default, but explicit is better
  ports:
  - port: 5432
```

With this setting:
- pod-0 notReady → DNS does not return its IP
- pod-1 connects to available replicas only

**Solution 2: Application Listens to Init Container Logic**

If using headless service (returns all IPs), app must handle NotReady replicas:

```python
# Instead of connecting to: postgres-cluster
# PostgreSQL replica must connect to CURRENT PRIMARY only

import socket
import subprocess

# Determine primary (from ConfigMap or election logic)
primary_host = get_primary_from_configmap()  # "pod-0.postgres-cluster"

# Try to connect; on failure, try backup
primary_hosts = ["pod-0.postgres-cluster", "pod-1.postgres-cluster", "pod-2.postgres-cluster"]

for host in primary_hosts:
    try:
        conn = psycopg2.connect(
            host=host,
            port=5432,
            connect_timeout=5  # Reduce from 30 to 5 seconds
        )
        replication_slot = f"standby_{socket.gethostname()}"
        psycopg2.baseconn = conn
        break
    except psycopg2.OperationalError:
        continue
else:
    raise Exception("No reachable primary")
```

Better: Use a **DNS **SRV record** for DNS-SD (Service Discovery):

```yaml
# StatefulSet creates SRV records automatically
# postgres-0-postgres-cluster.default.svc.cluster.local._tcp

# Postgres connection string supports SRV lookup:
# postgresql://replicator:password@(SRV=_postgresql._tcp.postgres-cluster.default.svc.cluster.local)/
```

**Solution 3: Use Patroni (Best for HA)**

Patroni manages primary election and updates a **virtual IP** (VIP) for connection:

```yaml
# Patroni automatically:
# - Elects a primary among running pods
# - Updates a ConfigMap or Ingress with primary address
# - App connects to VIP, which always points to current primary
```

**Best Practice for Production**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-cluster
spec:
  clusterIP: None
  selector:
    app: postgres
  publishNotReadyAddresses: false  # ← Prevent NotReady DNS returns

---
apiVersion: v1
kind: Service
metadata:
  name: postgres-primary
spec:
  type: ClusterIP
  selector:
    app: postgres
    role: primary  # Only primary matches this label
  ports:
  - port: 5432

# In StatefulSet init container:
# - Primary stays labeled: role: primary
# - Replicas labeled: role: replica
# - Apps connect to postgres-primary (only primary endpoint active)
```

---

### Scaling & Performance Questions {#perf-questions}

#### **Question 7: HPA Scaling Deployment to 100 Replicas Causes Cluster Exhaustion. How Do You Prevent This?**

*Scenario*: During traffic spike, HPA aggressively scales Deployment `api-server` from 10 to 100 replicas in 5 minutes. This causes:
- Cluster runs out of CPU and memory
- New pods stuck in Pending state
- Whole cluster degrades (existing services starved)

How do you prevent this cascade failure?

**Expected Answer**:

Multiple layers of protection are needed: HPA limits, resource requests, PDB, and node autoscaling coordination.

```
The Problem: Unbounded Scaling

HPA Logic:
  current_cpu: 85% → target: 80%
  Mismatch: Scale UP
  
  calculation_interval: 15 seconds
  scaling_decision: Add 90% more replicas
  
  Replicas: 10 → 19 → 35 → 64 → 100 (in 60 seconds)
  
Cluster Capacity:
  Available: 50 CPUs
  Each pod needs: 500m (request) + 1000m (limit)
  Only 100 pods fit: 100 * 500m = 50 CPU used
  
  After HPA scales to 100:
  100 * 500m = 50 CPU ✓ (technically fits)
  
  BUT: Limits are 1000m per pod
  100 * 1000m = 100 CPU limit (exceeds available 50 CPU!)
  
  → Linux cgroup enforces limits → CPU throttling
  → All pods (new and existing) get throttled
  → Performance degrades cluster-wide
```

**Layer 1: HPA Limits and Behavior**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  
  # Limit replica count
  minReplicas: 5
  maxReplicas: 50     # ← Hard cap, prevents runaway scaling
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  
  # Control scaling speed (CRITICAL)
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 100      # Can scale down 100% of replicas
        periodSeconds: 15  # But only once per 15 seconds
      - type: Pods
        value: 2        # Or max 2 pods per 15 seconds
        periodSeconds: 15  # Whichever is MORE CONSERVATIVE
      selectPolicy: Min  # Choose least aggressive
    
    scaleUp:
      stabilizationWindowSeconds: 0  # No wait before scaling up
      policies:
      - type: Percent
        value: 100      # Scale up 100% (double) every 15 seconds
        periodSeconds: 15
      - type: Pods
        value: 5        # Or add 5 pods max per 15 seconds
        periodSeconds: 15
      selectPolicy: Max  # Choose most aggressive
```

With this config and 10 initial replicas during CPU spike:

```
T0: Replicas = 10, CPU = 85%
T15: HPA decision: Scale 100%
      → 10 * 2 = 20, BUT max 5 pods allowed per 15s
      → Scale to 15 (add 5)
T30: Replicas = 15, CPU = 84% (lower due to more replicas)
T45: CPU = 80% (target reached)
T60: CPU = 79% (slight overshoot, but no scale down yet)
      stabilizationWindow: 300s (don't scale down for 5 min)
T300+: If CPU still below 80%, start scaling down

Result: Gradual ramp-up from 10 → 15 → 20 → 25 ... (controlled)
```

**Layer 2: Resource Requests Enable Cluster Protection**

```yaml
# Without resource requests: (BAD)
containers:
- name: app
  image: myapp:v1
  # No resources specified!
  # Scheduler places pod as long as ANY capacity exists
  
# With resource requests: (GOOD)
containers:
- name: app
  image: myapp:v1
  resources:
    requests:
      cpu: "500m"
      memory: "512Mi"  # Scheduler will only place pod if cluster has free 500m CPU, 512Mi RAM
    limits:
      cpu: "1000m"
      memory: "1Gi"
```

With resource requests, HPA scaling is limited by **actual cluster capacity**:
```
Cluster: 50 CPU, 250Gi RAM available
Pod request: 500m CPU, 512Mi RAM

Max safe pods: 50 CPU / 500m = 100 pods
           AND: 250Gi / 512Mi = 500 pods
           
Minimum: 100 pods (CPU is bottleneck)

HPA maxReplicas: 50 (safely under 100)
HPA reserves capacity for: cluster operations, system pods, monitoring
```

**Layer 3: Vertical Pod Autoscaler (VPA) for Resource Tuning**

If request estimates are wrong:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-server-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  updatePolicy:
    updateMode: "Off"  # Don't auto-update, only recommend
  
  # VPA examines actual usage and recommends:
  # "You requested 500m but only use 200m average"
  # "You requested 512Mi but spikes use 800Mi"
```

After VPA recommendations:

```yaml
# Actual recommended values:
resources:
  requests:
    cpu: "200m"       # Reduced from 500m (less waste)
    memory: "768Mi"   # Increased from 512Mi (avoid OOM)
  limits:
    cpu: "500m"       # Increased from 1000m (allow bursting)
    memory: "1Gi"
```

With corrected requests, cluster can support more replicas without exhaustion.

**Layer 4: Pod Disruption Budgets (Prevent Cascading Failures)**

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
spec:
  minAvailable: 3  # At least 3 pods must be available (avoid eviction cascade)
  selector:
    matchLabels:
      app: api-server
```

During cluster pressure (CPU exhaustion):
- Kubelet can't evict pods arbitrarily (PDB prevents)
- Pending pods fail to schedule (gracefully wait)
- No cascading failures (existing pods keep running)

**Layer 5: Node Autoscaling Coordination**

If using cluster autoscaler (AWS/GCP/Azure):

```yaml
# HPA scales pods, Cluster Autoscaler scales nodes
# Coordination problem: HPA might overshoot before nodes spin up

# Solution: Reserve extra node capacity via Descheduler
# Descheduler removes low-utilization pods to trigger node scaling
# before demand becomes urgent

# Or use Karpenter (AWS) for faster node provisioning
```

**Complete Safe Configuration**:

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 5  # Baseline
  
  template:
    spec:
      containers:
      - name: api
        image: myapp:v1
        # Resource requests/limits required
        resources:
          requests:
            cpu: "200m"      # Updated via VPA
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"

---
# HPA with controlled scaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
spec:
  maxReplicas: 50  # Hard cap (less than cluster capacity)
  minReplicas: 5
  scaleTargetRef:
    kind: Deployment
    name: api-server
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 80
  behavior:
    scaleUp:
      policies:
      - type: Pods
        value: 5
        periodSeconds: 60  # Add 5 pods max per minute (slow)
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5min before scaling down
      policies:
      - type: Pods
        value: 1
        periodSeconds: 60  # Remove 1 pod max per minute

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
spec:
  minAvailable: 3

---
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-server-vpa
spec:
  targetRef:
    kind: Deployment
    name: api-server
  updatePolicy:
    updateMode: "Off"
```

Result: Graceful scaling from 5 → 50 replicas over 5+ minutes, with cluster protection and no cascading failures.

---

#### **Question 8: Job Parallelism Too Low (Taking 10 Hours) vs Too High (Database Connection Storms). How Do You Find the Sweet Spot?**

*Scenario*: A batch job processes 100,000 records. Currently:
```
parallelism: 10
Job duration: 10 hours
SLA: 4 hours

parallelism: 100
Job fails: "Too many connections" error
Database pool: 20 max connections
```

How would you find the optimal parallelism?

**Expected Answer**:

This requires understanding the bottleneck: CPU, I/O, or resource contention.

```
Analysis Framework:

Step 1: Identify bottleneck
  
  Current parallelism: 10
  Job duration: 10 hours
  Theoretical max: (100,000 records) / 10 workers = 10,000 records per worker
  If each record takes 5 seconds: 10,000 * 5s = 50,000s = 13.8 hours
  Actual: 10 hours → slightly better than theoretical (some overlap)
  
  Bottleneck: Likely CPU/processing time (not I/O wait)

Step 2: Calculate processing rate
  
  100,000 records / 10 workers / 10 hours = 100 records/worker/hour
  = 1.67 records/worker/minute
  = 0.028 records/worker/second
  
  Time per record: 1 / 0.028 = ~36 seconds (includes network latency, serialization)

Step 3: Find the constraint
  
  Parallelism: 100
  Workers trying to connect: 100
  Database pool: 20 max
  Pool exhaustion: YES → leads to "Too many connections"
  
  Maximum sustainable parallelism: 20 (equal to database pool size)

Step 4: Calculate optimal parallelism
  
  To meet 4-hour SLA:
  Processing time per record: 36 seconds
  Total time: 100,000 * 36s / parallelism = 3,600,000s / parallelism
  3,600,000s / 3,600,000s (4 hours) = parallelism 1
  
  WAIT! This assumes serial. Let's recalculate:
  
  Total work: 100,000 records * 36s = 3,600,000 seconds of work
  Available worker-hours: 4 hours * parallelism workers
  
  required parallelism: 3,600,000s / (4 hours * 3,600 s/hour)
                      = 3,600,000 / 14,400
                      = 250 workers needed
  
  BUT database pool only supports 20!
  
  So: Limited by database pool to parallelism: 20
  
  With parallelism: 20:
  Duration: 3,600,000s / (20 * 3,600 s/hour) = 50 hours
  
  This EXCEEDS the 4-hour SLA! → Need to optimize database access

Step 5: Fix the bottleneck (Database)
  
  Option A: Increase connection pool
    Current: 20
    Needed: 250
    → Likely not feasible (DB resource limit)
  
  Option B: Reduce connection requirements per worker
    Instead of: 1 connection per worker held for 36s
    Use: Connection pooling, return connection after query (2s)
    
    With pooling:
      36s total job duration per record
      2s actual DB time
      34s processing (no connection held)
      
      Multiple workers can share connections:
      250 workers * (2s DB time / 36s) = 13.9 connections needed
      → Well under 20 pool limit!
  
  Option C: Batch inserts
    Instead of: 1 record per connection
    Use: INSERT 1000 records per connection
    
    36s * 1000 = 36,000 seconds per batch
    Connection needed: 2s per 1000 records
    
    Batching reduces DB contention dramatically

Recommended Optimization:

# Use connection pooling + batching
```

**Code Pattern: Connection Pool with Batching**

```python
# BEFORE (parallelism: 10, 10 hours, inefficient)
def process_record(record):
    conn = psycopg2.connect(dsn)
    try:
        cursor = conn.cursor()
        data = transform(record)  # 34 seconds
        cursor.execute("INSERT INTO table VALUES (%s, %s, %s)", data)
        conn.commit()  # 2 seconds
    finally:
        conn.close()

# Execution:
for i in range(100000):
    process_record(records[i])

# AFTER (parallelism: 50+, 4 hours, efficient)
from queue import Queue
import threading

def worker_with_batching(input_queue, batch_size=100):
    pool = psycopg2.pool.SimpleConnectionPool(2, 5, dsn)
    batch = []
    
    while True:
        record = input_queue.get()
        if record is None:
            break
        
        data = transform(record)  # 34 seconds (no DB connection held)
        batch.append(data)
        
        if len(batch) >= batch_size:
            # Execute batch insert (DB connected only here)
            conn = pool.getconn()
            try:
                cursor = conn.cursor()
                cursor.executemany(
                    "INSERT INTO table VALUES (%s, %s, %s)",
                    batch
                )
                conn.commit()  # 0.1 seconds for 100 records
            finally:
                pool.putconn(conn)
            batch = []
    
    if batch:
        # Final partial batch
        conn = pool.getconn()
        try:
            cursor = conn.cursor()
            cursor.executemany(..., batch)
            conn.commit()
        finally:
            pool.putconn(conn)

# Execution:
input_queue = Queue()
for worker_id in range(50):  # 50 workers
    threading.Thread(target=worker_with_batching, args=(input_queue=input_queue,)).start()
```

**Kubernetes Job Configuration with Optimal Parallelism**:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: records-batch-optimized
spec:
  completions: 100000
  parallelism: 50        # Increased from 10, under database limit
  backoffLimit: 3
  activeDeadlineSeconds: 14400  # 4-hour hard timeout
  ttlSecondsAfterFinished: 86400
  
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: processor
        image: batch-processor:v2-optimized
        env:
        - name: BATCH_SIZE
          value: "100"  # Insert 100 records per transaction
        - name: DB_POOL_SIZE
          value: "5"    # 50 workers * 5 connections = 250, but shared
        
        resources:
          requests:
            cpu: "500m"    # Processing (CPU bound)
            memory: "512Mi"
          limits:
            cpu: "1000m"
            memory: "1Gi"
```

**Expected Results**:

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Parallelism | 10 | 50 | 5x |
| Job Duration | 10 hours | 2 hours | 5x faster |
| Database Connections | 10 | <5 (shared) | Prevents pool exhaustion |
| SLA Compliance | ✗ (exceeds) | ✓ (under 4h) | Success |

The key insight: **Connection pooling decouples parallelism from database connections**, allowing high parallelism without pool exhaustion.

---

### Disaster Recovery & High Availability Questions {#dr-questions}

#### **Question 9: Disaster Recovery: StatefulSet Data Loss During Node Failure. How Do You Architect for Recovery?**

*Scenario*: A Kafka StatefulSet loses a broker (node crashes, PVC unavailable). Data on that broker is lost. How do you:

1. Prevent data loss in first place (RTO/RPO)?
2. Detect and alert on loss?
3. Recover gracefully?

**Expected Answer**:

RTO/RPO decisions differ between broker types (Kafka ≠ Database).

```
RTO (Recovery Time Objective): Time to restore to working state
RPO (Recovery Point Objective): Maximum acceptable data loss

For Kafka Broker:
  RTO SLA: 15 minutes (acceptable downtime)
  RPO SLA: 0 (no data loss acceptable)

Architecture Decisions:

1. PREVENTION (Replication)

Kafka Topic Configuration:
  replication_factor: 3 (partition replicated on 3 brokers)
  min_insync_replicas: 2 (requires 2 replicas acknowledge write)
  
  Scenario: Broker 2 loses disk
  - Leader: Broker 0
  - Replica 1: Broker 1
  - Replica 2: Broker 2 (GONE)
  
  Data Status:
  - All data on Broker 0 and 1 (unaffected)
  - Replication slot on Broker 2 orphaned
  
  Result: NO DATA LOSS (2 of 3 replicas survive)
  
  Trade-off: Storage usage tripled (3x replication)
  Benefit: Survive 1 broker loss with zero-downtime

Kafka Cluster Configuration:
  # Minimum viable cluster
  brokers: 3
  replication_factor: 3 (or 2 for non-critical topics)
  
  # Can lose: 1 broker and still quorum-elect leader
  # Can't lose: 2+ brokers simultaneously (quorum loss)

2. DETECTION (Monitoring)

Prometheus Metrics:

  # Alert if broker offline
  kafka_brokers_offline{broker="broker-2"} > 0
  alert: "Kafka broker offline for > 5 minutes"
  
  # Alert if ISR (in-sync replicas) reduced
  kafka_topic_partition_in_sync_replicas < replication_factor
  alert: "Replication factor reduced; data at risk"
  
  # Alert if underreplicated partitions exist
  kafka_controller_controller_metrics_underreplicatedpartitions > 0
  alert: "Partitions underreplicated; loss risk"

3. RECOVERY (Graceful Failover)

Scenario: Broker-2 node failure (catastrophic failure)

Timeline:

T0: Node 2 crashes (Kubernetes detects after node-monitor-grace-period: 40s)
T40: kubernetes marks node NotReady
T41-T45: StatefulSet controller detects pod-2 lost
         Creates new pod-2 (but PVC is orphaned/unavailable)
T45: New pod-2 PVC never attaches
     Pod stuck in Pending state

Manual Recovery:

$ kubectl delete pvc kafka-data-2  # Delete orphaned PVC
$ kubectl delete pod kafka-2       # Force pod restart

$ kubectl get pods -w              # Watch new pod-2 startup
  kafka-2 will:
  1. Initialize empty directory (no data)
  2. Join cluster as broker-2
  3. Leader assigns partitions to rebuild
  4. Followers send WAL to broker-2
  5. ISR restored

Duration: 5-15 minutes (depending on how much data)

# Verify recovery
$ kafka-topics --bootstrap-server localhost:9092 --describe
# Check: Min ISR >= 2, all partitions have >= 2 replicas
```

**Advanced: Automated Recovery (Operators)**

Use **Strimzi** (Kafka Operator):

```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kafka-cluster
spec:
  kafka:
    version: 3.5.0
    replicas: 3
    
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      min.insync.replicas: 2  # Prevent quorum loss
      log.retention.hours: 168  # 1 week of logs
    
    # Storage configuration with automata recovery
    storage:
      type: persistent-claim
      size: 500Gi
      deleteClaim: false  # Keep PVC even if pod deleted
    
    # Affinity to spread brokers across nodes
    affinity:
      podAntiAffinity:
        preferredDuringScheduling:
        - topologyKey: kubernetes.io/hostname  # One pod per node
        - topologyKey: topology.kubernetes.io/zone  # One per AZ if multi-az
```

Strimzi automatically:
- Detects broker failure
- Reassigns partitions away from failed broker
- Recreates replica on healthy brokers
- Validates replication health
- Zero-downtime failover (producer/consumer see single endpoint)

4. PREVENTION STRATEGY (Comprehensive)

```yaml
# Multi-layer protection
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: kafka-pdb
spec:
  minAvailable: 2  # Prevent voluntary disruption below 2 replicas
  selector:
    matchLabels:
      app: kafka

---
# Cross-AZ pod distribution (if multi-AZ cluster)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - key: kubernetes.io/hostname
        operator: In
        topologyKey: kubernetes.io/hostname

---
# Backup of offsets and metadata (external)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kafka-backup
spec:
  schedule: "0 * * * *"  # Hourly
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: kafka-backup:v1
            command:
            - /bin/sh
            - -c
            - |
              # Export Consumer Group offsets
              kafka-consumer-groups \
                --bootstrap-server kafka:9092 \
                --group mygroup \
                --reset-offsets \
                --to-offset 0 \
                --export > /backups/offsets-$(date +%Y%m%d-%H%M%S).csv
              
              # Archive to S3
              aws s3 sync /backups s3://kafka-backups/
```

**Disaster Recovery Process**

If catastrophic loss (full cluster failure):

```bash
# 1. Restore from external backup
aws s3 cp s3://kafka-backups/latest /restore/

# 2. Redeploy Kafka cluster (same 3 brokers)
kubectl apply -f kafka-statefulset.yaml

# 3. Re-import metadata
kafka-topics --bootstrap-server kafka:9092 --create \
  --topics mysource $(cat /restore/topic-definitions.json)

# 4. Reset consumer group offsets
kafka-consumer-groups --bootstrap-server kafka:9092 \
  --group mygroup \
  --reset-offsets \
  --from-file /restore/offsets.csv \
  --execute

# 5. Validate (produce/consume test messages)
kafka-producer-perf-test ...
kafka-consumer-perf-test ...
```

**RTO/RPO Trade-offs**:

| Configuration | Data Loss Risk | RTO | Performance Impact |
|---|---|---|---|
| replication_factor: 1 | Complete loss (1 failure) | N/A | Best (no repl) |
| replication_factor: 2 | Partial (1 failure) | 15 min | Moderate |
| replication_factor: 3 | Zero (1 failure) | 2 min | High (3x storage) |
| + Cross-AZ spread | Zero (node + AZ failure) | <30s | Very High |
| + External Backup | Near-zero (multiple failures) | Hours | Storage cost |

For SaaS: **Choose replication_factor: 3 + Strimzi operator** for automatic failover with zero-downtime.

---

#### **Question 10: Graceful Update with Zero Data Loss: Multi-Tier Coordination**

*Scenario*: Update a complex system: API → Cache (Redis) → Database (PostgreSQL). Each layer has different update constraints:

- **API (Deployment)**: Can be updated in rolling fashion without coordination
- **Cache (Redis StatefulSet)**: Master + replicas; must coordinate to avoid cache invalidation storms
- **Database (PostgreSQL StatefulSet)**: Mission-critical; data loss risk; requires careful orchestration

How do you orchestrate an update across all three layers to achieve zero-downtime, no data loss, and minimal degradation?

**Expected Answer**:

This question tests understanding of distributed system coordination and careful update ordering.

```
The Challenge:

If you update in wrong order:
  Update API first (v2) + old Cache (v1) → Cache protocol mismatch, cache misses
  Update Cache first → Old API (v1) can't use new cache format, cascading failures
  Update Database first → data format incompatible with old API, data corruption

Correct Update Sequence:

┌─────────────────────────────────────────────────────────┐
│      PRE-UPDATE VALIDATION (no downtime)                │
├─────────────────────────────────────────────────────────┤
│  1. Backup database (full export to S3)                 │
│  2. Snapshot Redis data                                 │
│  3. Pre-warm all nodes with new images (DaemonSet)      │
│  4. Run integration tests in canary environment          │
│  5. Collect authorization from ops/compliance           │
└─────────────────────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────────────────┐
│    PHASE 1: DATABASE SCHEMA MIGRATION (critical path)   │
├─────────────────────────────────────────────────────────┤
│  Timeline: 2:00 AM (low-traffic window)                 │
│  Duration: ~30 minutes                                  │
│                                                         │
│  Constraint: Must be reversible in < 5 minutes          │
│  Reason: If migration fails, quick rollback needed      │
│                                                         │
│  Steps:                                                 │
│  1. Stop write traffic to database (API stop accepting) │
│  2. Drain in-flight transactions (30 sec grace period)  │
│  3. Run schema migration (ALTER TABLE, CREATE INDEX)    │
│  4. Validate schema (checksums match expected)          │
│  5. If failure → restore from pre-migration snapshot    │
│  6. If success → resume write traffic (API restart)     │
│                                                         │
│  Kubernetes implementation:                             │
│  - Job runs migration script                            │
│  - Pre-migration: kubectl patch service api-server      │
│    to route to no pods (stop writes)                    │
│  - Migration runs                                       │
│  - Post-migration: Patch service back to route to API   │
└─────────────────────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────────────────┐
│    PHASE 2: DATABASE VERSION UPGRADE TO V2              │
├─────────────────────────────────────────────────────────┤
│  Timeline: Post schema migration, staggered              │
│  Duration: ~1 hour (rolling update, 1 pod at a time)   │
│                                                         │
│  Update order:                                          │
│  1. Update standby-1 (spare replica, safest)            │
│  2. Monitor for 10 minutes (check replication health)   │
│  3. Update standby-2 (second replica)                   │
│  4. Monitor promoted standby-1 → new primary            │
│  5. Update old primary (now standby, low risk)          │
│                                                         │
│  Validation at each step:                               │
│  - Replication lag < 100ms                              │
│  - No slow queries                                      │
│  - Disk I/O stable                                      │
└─────────────────────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────────────────┐
│    PHASE 3: CACHE LAYER UPDATE (stateless now)          │
├─────────────────────────────────────────────────────────┤
│  Timeline: Post-DB upgrade                              │
│  Duration: ~15 minutes                                  │
│                                                         │
│  Why after DB?: Cache is dependent layer                │
│    If cache uses new protocol, API handles it           │
│    But data format must match database                  │
│                                                         │
│  Update order (rolling):                                │
│  1. Update replica-1 (read-only, no data loss)          │
│  2. Update replica-2 (secondary replica)                │
│  3. Failover to replica-2 as master                     │
│  4. Update old master (now replica)                     │
│                                                         │
│  Cache-specific concerns:                               │
│  - Invalidate cache before update (prevent stale data)  │
│  - Monitor hit rate (should not drop > 10%)             │
│  - Verify replication sync (no gaps)                    │
└─────────────────────────────────────────────────────────┘
            ↓
┌─────────────────────────────────────────────────────────┐
│    PHASE 4: API LAYER UPDATE (safest, can rollback)     │
├─────────────────────────────────────────────────────────┤
│  Timeline: Final phase, safest                          │
│  Duration: ~30 minutes (rolling update, 2 pods at time) │
│                                                         │
│  Why last?: API depends on both DB and Cache            │
│    If both upgraded first, API can safely talk to them  │
│                                                         │
│  Rolling update config:                                 │
│  maxUnavailable: 0 (zero downtime)                      │
│  maxSurge: 50% (creates surge pods for quick update)    │
│                                                         │
│  Strategy: Canary → Progressive → Full rollout          │
│  1. Update 1 pod (canary)                               │
│  2. Send 10% test traffic to canary for 5 min           │
│  3. If metrics OK, update 2 more pods                   │
│  4. Monitor error rates, latency                        │
│  5. If drift detected, automatic rollback (see next)    │
│  6. Continue until 100% updated                         │
└─────────────────────────────────────────────────────────┘
```

**Implementation: Orchestrated Update Script**

```bash
#!/bin/bash
# Orchestrated multi-tier update with rollback
# Run with: ./update.sh postgres:v2 redis:v2 api:v2

set -e

POSTGRES_VERSION=$1
REDIS_VERSION=$2
API_VERSION=$3

LOG="/var/log/update-$(date +%Y%m%d-%H%M%S).log"
ROLLBACK_PLAN=""

log() {
  echo "[$(date)] $*" | tee -a $LOG
}

error() {
  log "ERROR: $*"
  if [ ! -z "$ROLLBACK_PLAN" ]; then
    log "Executing rollback plan..."
    eval "$ROLLBACK_PLAN"
  fi
  exit 1
}

# Phase 1: Pre-flight checks
log "Phase 1: Pre-flight validation"
kubectl get nodes -o wide | tee -a $LOG
kubectl get deployment,statefulset -A | tee -a $LOG

# Take backups
log "Taking database backup..."
kubectl exec postgres-0 -c postgres -- pg_dump -U postgres postgres \
  | gzip > /backups/postgres-$(date +%Y%m%d-%H%M%S).sql.gz
ROLLBACK_PLAN+="restore_postgres_backup; "

log "Taking Redis snapshot..."
kubectl exec redis-0 -c redis -- redis-cli --rdb /data/snapshot.rdb
kubectl exec redis-0 -c redis -- redis-cli bgsave
ROLLBACK_PLAN+="restore_redis_snapshot; "

# Phase 2: Database schema migration
log "Phase 2: Database migration"
log "Stopping write traffic to database..."
kubectl patch deployment api-server --type='json' -p='[
  {"op": "add", "path": "/spec/template/spec/terminationGracePeriodSeconds", "value": 120},
  {"op": "add", "path": "/spec/replicas", "value": 0}
]'
sleep 5  # Let in-flight requests drain

log "Running schema migration..."
if ! kubectl exec postgres-0 -c postgres -- psql -U postgres -f /migration/v2.sql; then
  error "Schema migration failed in postgres-0"
fi

log "Validating schema..."
SCHEMA_HASH=$(kubectl exec postgres-0 -c postgres -- \
  psql -U postgres -t -c "SELECT md5(string_agg(s, '|')) FROM (SELECT * FROM information_schema.columns) t(s)")

if [ "$SCHEMA_HASH" != "$(cat /expected-schema-hash)" ]; then
  error "Schema mismatch after migration"
fi

log "Resuming write traffic..."
kubectl patch deployment api-server --type='json' -p='[
  {"op": "replace", "path": "/spec/replicas", "value": 5}
]'

# Phase 3: Database upgrade (rolling)
log "Phase 3: PostgreSQL rolling update"
for i in 1 0; do  # Update standby-1, standby-2, then master
  log "Updating postgres-$i..."
  kubectl set image statefulset/postgres postgres=postgres:$POSTGRES_VERSION --record
  kubectl rollout status statefulset/postgres --timeout=10m
  
  # Validate replication
  LAG=$(kubectl exec postgres-0 -c postgres -- \
    psql -U postgres -t -c "SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))")
  if [ "$LAG" -gt "1" ]; then
    error "Replication lag > 1 second: $LAG"
  fi
  
  log "postgres-$i update successful, replication lag: ${LAG}s"
  sleep 60
done

ROLLBACK_PLAN+="kubectl set image statefulset/postgres postgres=postgres:v1; "

# Phase 4: Cache update (rolling)
log "Phase 4: Redis rolling update"
log "Invalidating cache..."
kubectl exec redis-0 -c redis -- redis-cli FLUSHALL

log "Rolling update Redis..."
kubectl set image statefulset/redis redis=redis:$REDIS_VERSION --record
kubectl rollout status statefulset/redis --timeout=5m

log "Validating cache..."
CACHE_SIZE=$(kubectl exec redis-0 -c redis -- redis-cli DBSIZE | grep keys)
log "Cache size after update: $CACHE_SIZE"

ROLLBACK_PLAN+="kubectl set image statefulset/redis redis=redis:v1; "

# Phase 5: API update (rolling with canary)
log "Phase 5: API rolling update (canary strategy)"
log "Deploying canary pod..."
kubectl set image deployment/api-server api=api:$API_VERSION --record

# Canary: Wait for 1 pod, send test traffic
kubectl rollout pause deployment/api-server
kubectl rollout status deployment/api-server --timeout=2m

log "Canary pod deployed, running integration tests..."
if ! kubectl exec deployment/api-server --container=api -- \
  /tests/integration-test.sh; then
  error "Canary integration tests failed, rolling back API"
  kubectl rollout undo deployment/api-server
fi

log "Canary successful, resuming full rollout..."
kubectl rollout resume deployment/api-server
kubectl rollout status deployment/api-server --timeout=15m

# Final validation
log "Final validation..."
log "Checking application health..."
for i in {1..10}; do
  if curl -f http://api-server:8080/health; then
    log "Health check passed"
    break
  fi
  if [ $i -eq 10 ]; then
    error "Health check failed after 10 retries"
  fi
  sleep 10
done

log "Checking data consistency..."
EXPECTED_ROWS=$(kubectl exec postgres-0 -c postgres -- \
  psql -U postgres -t -c "SELECT count(*) FROM messages")
if [ "$EXPECTED_ROWS" -lt "1000000" ]; then
  error "Data corruption detected: only $EXPECTED_ROWS rows vs expected > 1M"
fi

log "✓ Update completed successfully!"
ROLLBACK_PLAN=""  # Clear rollback plan on success
```

**Rollback Procedure**

If any phase fails:

```bash
# Immediate rollback (within 5 minutes)
kubectl rollout undo deployment/api-server               # API
kubectl rollout undo statefulset/redis                  # Cache
kubectl rollout undo statefulset/postgres               # Database

# Restore data if needed
psql -U postgres < /backups/postgres-20260310.sql.gz  # From pre-migration backup
```

**Key Principles for Zero-Downtime, No-Loss Updates**:

1. **Backup before each phase** (database → cache → API)
2. **Update dependencies first** (DB before API)
3. **Use canary for API** (stateless layer, can rollback easily)
4. **Validate between phases** (don't proceed if health checks fail)
5. **Graceful termination** (terminationGracePeriodSeconds: 120+)
6. **Monitoring** (watch CPU, memory, latency, error rates)
7. **Rehearsal** (test full procedure in staging first)

This approach enables **zero-downtime updates** with **guaranteed data integrity**, critical for production SaaS systems.

---

*Study Guide Version: 1.3*  
*All sections completed: Foundational (Sections 1-3), Deep Dives (Sections 4-6), Hands-on Scenarios (Section 7), Interview Questions (Section 8)*  
*Total Content: 25,000+ words, 60+ code examples, 30+ diagrams*  
*Latest Updated: March 2026*  
*Audience: Senior DevOps Engineers (5-10+ years experience)*  
*This study guide is suitable for Kubernetes Professional Certification (CKA/CKAD), production architecture design, and enterprise operations.*
