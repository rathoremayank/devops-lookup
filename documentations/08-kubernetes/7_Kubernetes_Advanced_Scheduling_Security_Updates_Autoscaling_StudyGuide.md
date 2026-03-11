# Advanced Kubernetes: Scheduling, Security, Updates & Autoscaling

**Study Guide for Senior DevOps Engineers** | Kubernetes 1.28+

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Scheduling & Placement](#scheduling--placement)
4. [Pod Security & Runtime Security](#pod-security--runtime-security)
5. [Rolling Updates & Rollbacks](#rolling-updates--rollbacks)
6. [Autoscaling](#autoscaling)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions for Senior Engineers](#interview-questions-for-senior-engineers)

---

## Introduction

### Overview of Topic

This study guide addresses four critical dimensions of production-grade Kubernetes cluster management that distinguish senior platform engineers from intermediate practitioners:

- **Scheduling & Placement**: The intelligent distribution of workloads across heterogeneous infrastructure
- **Pod Security & Runtime Security**: Multi-layered defense mechanisms protecting containerized workloads and the cluster
- **Rolling Updates & Rollbacks**: Zero-downtime deployment strategies and recovery mechanisms
- **Autoscaling**: Dynamic resource adaptation at pod, node, and cluster levels

### Why It Matters in Modern DevOps Platforms

In enterprise Kubernetes deployments, these four capabilities form the operational backbone:

1. **Cost Optimization**: Proper scheduling and autoscaling reduce cloud spend by 40-60% while maintaining SLA compliance
2. **Security Posture**: Most container breaches exploit runtime vulnerabilities—layered pod security prevents privilege escalation
3. **Reliability**: Rolling updates and built-in rollback mechanisms enable safe deployments with zero downtime
4. **Resource Efficiency**: Advanced placement ensures heterogeneous workload distribution across infrastructure tiers (GPU, ARM, spot instances)

### Real-World Production Use Cases

**E-commerce Platform**: During Black Friday traffic spikes, HPA scales checkout service from 10 to 200 pods based on custom metrics (cart abandonment rate > 5%). Node autoscaler simultaneously provisions additional nodes. A misconfigured pod affinity rule would cause pods to queue on full nodes, negating autoscaling—this is where advanced scheduling expertise prevents cascading failures.

**Financial Services**: A trading platform running 500-pod deployments cannot tolerate 5-minute update windows. Blue-green deployments with traffic splitting ensure zero-packet loss during canary rollouts. Pod security policies enforce non-root containers and read-only filesystems—regulatory compliance demands this.

**Machine Learning Platform**: GPU-intensive training jobs require node affinity to specific GPU types. VPA continuously optimizes request/limit ratios based on actual consumption. Pod disruption budgets ensure training jobs aren't terminated during cluster maintenance scaling.

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────┐
│        CLUSTER AUTOSCALER (Node Level)                  │
│  ┌────────────────────────────────────────────────────┐ │
│  │  Kubernetes Scheduler (Pod Placement)              │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │ [Pod] ← Affinity, Taints/Tolerations         │ │ │
│  │  │ [Pod] ← Pod Topology Spread Constraints     │ │ │
│  │  │ [Pod] ← Resource Requests/Limits             │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │ Pod Security Policies & Security Contexts    │ │ │
│  │  │ Runtime Security Tools (Falco, OPA)          │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │ Rolling Updates (Canary/Blue-Green)          │ │ │
│  │  │ HPA/VPA (Pod Autoscaling)                    │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Key Terminology

#### Scheduling-Related Terms

- **Node Selector**: Simple key-value label matching for pod-to-node assignment
- **Taint**: Node-level constraint marking a node as unsuitable for certain workloads
- **Toleration**: Pod-level permission to be scheduled on tainted nodes
- **Node Affinity**: Advanced node selection using label expressions (In, NotIn, Exists, DoesNotExist, Gt, Lt)
- **Pod Affinity**: Co-location of pods based on label matching (affinity or anti-affinity)
- **Pod Topology Spread Constraints**: Enforcement of pod distribution across topology domains (zones, regions, nodes)
- **Scheduler Framework Plugins**: Extensibility points allowing custom scheduling logic

#### Security-Related Terms

- **Pod Security Policy (PSP)**: Cluster-wide policy enforcing security standards (deprecated in 1.25+)
- **Pod Security Standards (PSS)**: Replacement for PSP using three levels: Unrestricted, Baseline, Restricted
- **Security Context**: OS-level security attributes applied to containers (runAsUser, runAsNonRoot, readOnlyRootFilesystem, capabilities)
- **Network Policy**: Microsegmentation controlling inbound/outbound traffic between pods
- **Runtime Security**: Real-time threat detection during container execution (syscall auditing, behavior monitoring)
- **Seccomp**: Secure Computing Mode restricting allowed syscalls at kernel level
- **AppArmor**: Mandatory Access Control (MAC) enforcing fine-grained permissions

#### Update & Rollback Terms

- **Deployment Strategy**: Mechanism for rolling out new versions (Rolling, Recreate, Blue-Green, Canary)
- **Rolling Update**: Gradual replacement of old pods with new versions, controlled by maxUnavailable/maxSurge
- **Canary Deployment**: Release to subset of users/nodes first, expanding based on metrics
- **Blue-Green Deployment**: Running two identical production environments, switching traffic atomically
- **Revision**: Immutable snapshot of deployment state; each rollout creates a new revision
- **Surge**: Temporary excess replicas allowed during rolling updates (maxSurge parameter)
- **Unavailable**: Pods allowed to be offline during rolling updates (maxUnavailable parameter)

#### Autoscaling Terms

- **Horizontal Pod Autoscaler (HPA)**: Increases/decreases pod count based on metrics (CPU, custom metrics)
- **Vertical Pod Autoscaler (VPA)**: Right-sizes container requests/limits based on actual usage
- **Cluster Autoscaler**: Adds/removes nodes based on unschedulable pods or resource utilization
- **Metric Server**: Component collecting resource metrics (CPU, memory) from kubelets
- **Custom Metrics**: Application-specific metrics (requests/sec, message queue depth) driving autoscaling
- **Target Utilization**: Threshold triggering scale-up (e.g., 70% CPU triggers scale-up)
- **Scaling Policy**: Controls rate of scaling (min/max replicas, percentage-based increases)

### Architecture Fundamentals

#### The Kubernetes Control Plane's Role in These Domains

The Kubernetes control plane orchestrates all four capabilities through specialized components:

```
CONTROL PLANE ARCHITECTURE
├── API Server: Central hub receiving all configuration
│   ├── Validates & stores desired state
│   └── Broadcasts events to controllers
├── Scheduler: Pod placement decision engine
│   ├── Filters nodes based on resource, affinity, taints
│   ├── Scores remaining nodes
│   └── Assigns pod to highest-scoring node
├── Controller Manager: Enforces desired state
│   ├── Deployment Controller (manages rolling updates)
│   ├── StatefulSet Controller
│   └── Node Lifecycle Controller
├── kubelet (on each node): Enforces pod-level policies
│   ├── Executes security contexts
│   ├── Maintains pod health
│   └── Reports node/pod metrics
└── etcd: Persistent state store
    ├── Stores all objects (pods, nodes, policies)
    └── Enables audit logging & recovery
```

#### Request/Limit Paradigm Impact on All Four Domains

Every advanced feature depends on accurate resource requests and limits:

```
Pod Specification
├── resources.requests: Scheduler uses for placement
│   ├── cpu: Cores assigned to pod (scheduling guarantee)
│   └── memory: RAM reserved for pod
├── resources.limits: Enforce hard caps (OOMKill, CPU throttling)
└── Impact chain:
    ├── Scheduling: Pod can't fit without sufficient requests
    ├── Autoscaling: HPA reacts to % of request utilization
    ├── Security: Memory limits prevent DoS attacks
    └── Disruption: PDB respects resource pressure
```

#### Control Plane Communication Flow

```
User kubectl apply
    ↓
API Server validates & stores in etcd
    ↓
Watchers/Controllers notified
    ├── Deployment Controller: Creates ReplicaSets
    ├── Scheduler: Assigns unscheduled pods → nodes
    └── kubelet: Pulls image, starts container, enforces security context
    ↓
kubelet executes rolling update strategies
kubelet reports metrics → metrics-server
HPA/VPA controllers watch metrics, adjust replicas
```

### Important DevOps Principles

#### 1. **Infrastructure as Code (IaC) for Policies**

Senior engineers treat scheduling policies, security policies, and autoscaling rules as code:

```yaml
# ✅ GOOD: Policy as declarative, version-controlled resource
apiVersion: policy.k8s.io/v1
kind: PodDisruptionBudget
metadata:
  name: critical-service-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      tier: critical
```

- Enables peer review, audit trails, and rollback
- Prevents drift from manual kubectl apply commands
- Integrates with GitOps workflows (ArgoCD, Flux)

#### 2. **Defense in Depth (Security Layers)**

No single security mechanism is sufficient:

```
Layer 1: Pod Security Standards (admission controller)
    ↓
Layer 2: Security Contexts (runtime enforcement)
    ↓
Layer 3: Network Policies (microsegmentation)
    ↓
Layer 4: Runtime Security Tools (syscall monitoring)
    ↓
Layer 5: Image scanning (registry security)
    ↓
Layer 6: RBAC (authorization)
```

Compromising one layer shouldn't compromise the system.

#### 3. **Observability-Driven Operations**

Safe rolling updates, autoscaling decisions, and security responses depend on metrics:

- **Metrics**: CPU, memory, disk, network (provided by metrics-server)
- **Custom Metrics**: Business KPIs (orders/sec, error rate, latency p99)
- **Traces**: Distributed traces showing per-request flow
- **Logs**: Container stdout/stderr, audit logs, security events

Without observability, you're flying blind during autoscaling events.

#### 4. **Canary-Based Change Management**

Senior engineers default to canary deployments for risky changes:

```
0-5% of traffic   → Canary (new version)
95-100% of traffic → Stable (current version)
    ↓
Monitor error rate, latency SLI
    ↓
If healthy: Gradually shift 5% → 25% → 50% → 100%
If unhealthy: Rollback immediately (50ms recovery time possible)
```

#### 5. **Cost Optimization Through Autoscaling**

```
Static provisioning: 8 p95 load × 3 (buffer) = 24 nodes always running
Dynamic autoscaling: Runs 3 nodes baseline, scales to 15 during peak = 50% cost reduction
    + Pod disruption budgets ensure graceful scale-down
    + VPA prevents over-provisioning individual pods
```

### Best Practices

#### Scheduling Best Practices

1. **Always define resource requests and limits**
   - Request: Scheduler guarantee; what node must provide
   - Limit: Hard cap preventing resource starvation
   - Without these, scheduling becomes random

2. **Use appropriate affinity levels**
   - `preferredDuringScheduling`: Soft constraint (failures acceptable)
   - `requiredDuringScheduling`: Hard constraint (pod can't run without it)
   - Too many required affinities = scheduling failures; too few = suboptimal placement

3. **Implement pod topology spread for resilience**
   - Spreads replicas across zones/nodes
   - Prevents single failure domain from affecting threshold of pods
   - Example: 9 replicas spread across 3 zones = 3/zone = 1 zone failure tolerated

4. **Use taints for node specialization**
   - Dedicated nodes for GPU/memory-intensive workloads
   - Isolated nodes for compliance-sensitive workloads
   - Prevent accidental pod-to-node mismatches

#### Security Best Practices

1. **Adopt Pod Security Standards (PSS) as minimum**
   - Apply at namespace level: `pod-security.kubernetes.io/enforce: restricted`
   - Set audit mode separately: `pod-security.kubernetes.io/audit: restricted`
   - Phase out Pod Security Policies (deprecated 1.25+)

2. **Implement network policies for all namespaces**
   - Default-deny ingress: pods unreachable until explicitly allowed
   - Explicit pod-to-pod communication rules
   - Prevent lateral movement in case of compromise

3. **Use Seccomp and AppArmor profiles**
   - Restrict syscalls available to containers
   - Prevent container escape attempts
   - AppArmor more mature but Linux-specific

4. **Enforce read-only root filesystems**
   - Prevents persistent compromise
   - Forces attackers to target ephemeral layers
   - `readOnlyRootFilesystem: true` in security context

5. **Run containers as non-root**
   - Prevents accidental/intentional privilege escalation
   - `runAsNonRoot: true` in security context

6. **Use runtime security tools for continuous monitoring**
   - Falco: Behavioral threat detection
   - OPA/Gatekeeper: Policy enforcement at admission time
   - Sysdig Secure: Container threat intelligence

#### Rolling Update Best Practices

1. **Define maxUnavailable and maxSurge appropriately**
   ```
   Budget available during update:
   maxUnavailable: 1     (1 pod can be down)
   maxSurge: 1           (1 extra pod allowed temporarily)
   Total replicas: 5
   
   Update process: 5→4→5→4→5 (replaces 1 at a time)
   Alternative (faster): maxUnavailable: 2, maxSurge: 2 → 5→5→3→5 (riskier)
   ```

2. **Implement pod disruption budgets**
   - Protects against involuntary disruptions (node drains, evictions)
   - Ensures minimum replicas always available
   - Works with rolling updates, node autoscaling, cluster upgrades

3. **Run readiness probes before considering pod healthy**
   - Prevents sending traffic to not-yet-ready pods
   - Extends health check beyond simple startup
   - Example: Wait for database connections to warm up

4. **Use canary deployments in production**
   - Route subset of traffic to new version
   - Monitor error rates, latency
   - Automatic rollback on anomaly detection

5. **Test rollback procedures regularly**
   - Don't assume rollback will work under stress
   - Archive old container images (don't delete immediately)

#### Autoscaling Best Practices

1. **HPA requires stable metrics baseline**
   - Requires 3-5 minutes of stable metrics before scaling
   - Scaling thresholds: target 70-80% CPU (not 99%)
   - Prevents flapping (rapid scale-up/down cycles)

2. **Set minimum and maximum replica bounds**
   ```yaml
   minReplicas: 2      # Always at least 2 (HA guarantee)
   maxReplicas: 100    # Prevent runaway scaling
   ```

3. **Use custom metrics for business-relevant scaling**
   - CPU/memory scaling insufficient for many workloads
   - Message queue depth, requests per second, latency percentile
   - Example: Scale checkout pods based on shopping cart count

4. **Combine HPA and VPA carefully**
   - Using both simultaneously causes interaction issues
   - HPA adjusts replica count; VPA adjusts request/limits
   - Solution: Use VPA for right-sizing, then let HPA manage replicas

5. **Account for autoscaling latency**
   - Scaling new pod: 5-30 seconds (image pull, initialization)
   - Node provisioning: 2-4 minutes (cloud API roundtrip)
   - Over-provision baseline to account for queue time

### Common Misunderstandings

#### Misunderstanding #1: "Node Selectors Are Sufficient for Placement"

❌ **Wrong**: Using only nodeSelector for all scheduling needs
```yaml
spec:
  nodeSelector:
    disktype: ssd
  # Missing: what if no SSD nodes available?
```

✅ **Correct**: Layered approach combining nodeSelector, affinity, and topology constraints
```yaml
spec:
  nodeSelector:              # Hard constraint: must have label
    workload: batch
  affinity:
    nodeAffinity:
      preferredDuringScheduling:  # Soft: try to prefer this, don't fail if impossible
        - weight: 100
          preference:
            matchExpressions:
            - key: disktype
              operator: In
              values: [ssd]
  topologySpreadConstraints:  # Distribute across zones
    - maxSkew: 1
      topologyKey: topology.kubernetes.io/zone
```

#### Misunderstanding #2: "Pod Security Policies Replaced Are Still Useful"

❌ **Wrong**: Still deploying PSP in Kubernetes 1.25+
```yaml
apiVersion: policy/v1beta1  # Deprecated!
kind: PodSecurityPolicy
```

✅ **Correct**: Migrate to Pod Security Standards (PSS) via admission controller
```yaml
# In namespace labels:
pod-security.kubernetes.io/enforce: restricted
pod-security.kubernetes.io/audit: restricted
pod-security.kubernetes.io/warn: restricted
```

#### Misunderstanding #3: "Limits Prevent Autoscaling Issues"

❌ **Wrong**: Assuming CPU limits prevent HPA mistakes
```yaml
resources:
  requests:
    cpu: 100m
  limits:
    cpu: 1      # Limits don't prevent HPA from scheduling too many pods!
```

✅ **Correct**: Requests determine scheduling; limits prevent starvation
- Requests = scheduler guarantee = what node must have available
- Limits = hard cap = prevents pod from consuming more
- HPA scales based on % of request utilization: if 100m request, 70% used = 70m actual

#### Misunderstanding #4: "Rolling Updates Guarantee Zero Downtime"

❌ **Wrong**: Assuming rolling update = no traffic loss
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 50%   # Half your pods disappear mid-update!
```

✅ **Correct**: Rolling updates require proper pod disruption budgets and multiple replicas
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2  # Guarantee always 2 up, even during updates
```

#### Misunderstanding #5: "More Nodes = Better Autoscaling"

❌ **Wrong**: Over-provisioning nodes to avoid autoscaling latency
- Wastes budget
- Masks efficiency problems
- Unpredictable cost

✅ **Correct**: Right-size cluster baseline + accept autoscaling latency
- Baseline: nodes for average load
- Autoscaling buffer: anticipated burst capacity
- Cost: Save 40% vs static provisioning

#### Misunderstanding #6: "HPA+VPA Can Work Together Unmodified"

❌ **Wrong**: Running HPA and VPA on same deployment
```yaml
---
# HPA adjusts replicas
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
spec:
  scaleTargetRef:
    kind: Deployment
---
# VPA adjusts request/limits
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
spec:
  targetRef:
    kind: Deployment
  updatePolicy:
    updateMode: "Auto"  # Causes conflicts!
```

✅ **Correct**: Use VPA in "recommend" mode or exclusively design
```yaml
# Option 1: VPA recommendation only (no auto-update)
updateMode: "Off"
# Manual review and update requests/limits

# Option 2: VPA handles vertical, HPA handles horizontal
updateMode: "Auto"  # Allowed to update requests/limits
# HPA responds to % of adjusted requests
```

---

## Scheduling & Placement

Kubernetes scheduling determines intelligent pod-to-node assignment in heterogeneous clusters. This section covers node selection mechanisms (selectors, affinity, taints), the scheduler algorithm, and production patterns.

### Textual Deep Dive

#### How the Kubernetes Scheduler Works (Internal Architecture)

The scheduler is a stateless, event-driven component in the control plane that watches for unscheduled pods and assigns them to nodes. The scheduling cycle consists of three phases:

**Phase 1: Filtering**
```
ALL NODES (10 total)
    ↓
Apply Predicates (now called "Filtering")
├── Node has sufficient CPU/memory? → Filter out undersized nodes
├── Pod has nodeSelector label matching? → Filter out mismatched labels
├── Pod has taint toleration? → Filter out tainted nodes
├── PVC available in node's zone? → Filter out region-mismatched nodes
└── Result: CANDIDATE NODES (3 remaining)
```

The scheduler filters nodes based on hard constraints (must match). If no nodes pass filtering, the pod remains unscheduled and enters a backoff retry queue (exponential backoff: 100ms → 1s → 5s → 10s max).

**Phase 2: Scoring**
```
CANDIDATE NODES (3 qualifying)
    ↓
Apply Priority Functions (now called "Scoring")
├── LeastRequestedPriority: Score nodes using least reserved resources
│   Node A: 40% allocated → Score 60
│   Node B: 20% allocated → Score 80
│   Node C: 50% allocated → Score 50
├── NodeAffinityPriority: Score based on `preferredDuringScheduling` rules
├── InterPodAffinityPriority: Score based on pod affinity/anti-affinity rules
├── BalancedResourceAllocation: Prefer nodes with balanced CPU/memory usage
└── Result: SCORED NODES
    Node B: 80+15+20+10 = 125 (highest score)
    Node A: 60+50+30+5 = 145 (wait, could be higher!)
```

Scoring uses weighted plugins. Each plugin returns 0-100, multiplied by weight (default 1), summed across all plugins. The scheduler picks the highest-scoring node.

**Phase 3: Binding**
```
Winning Node: Node B (highest score)
    ↓
Bind pod to node (atomic operation)
    ├── Update etcd: pod.spec.nodeName = "node-b"
    └── Trigger kubelet on node-b to start pod
```

#### Node Selectors: The Simplest Placement Mechanism

Node selectors use label matching to assign pods to specific nodes:

```yaml
spec:
  nodeSelector:
    disktype: ssd     # Pod only runs on nodes labeled disktype=ssd
    gpu: "true"       # AND nodes labeled gpu=true
```

**How it works internally:**
1. Pod created with nodeSelector
2. Scheduler enters filtering phase
3. Checks each node's labels against selector
4. Only nodes with BOTH labels are candidates
5. If no match: Pod stays Pending indefinitely

**Production usage:**
- Simple, predictable constraints (e.g., workload → tier)
- Hardware affinity (GPU, high-memory, ARM)
- Compliance zones (data must stay in region)

**Limitations:**
- Only supports equality matching (no "greater than" or "not equal")
- Not enough for complex multi-constraint scenarios
- Can't express "prefer SSD if available, fall back to HDD"

#### Taints and Tolerations: Cluster-Level Access Control

Taints mark nodes as unavailable to certain workloads. Tolerations allow pods to schedule on tainted nodes.

**Taint Types:**

```
Taint: <key>=<value>:<effect>

Effects:
1. NoSchedule: Pod cannot schedule on this node (hard constraint)
2. NoExecute: Pod cannot schedule AND existing pods evicted (if not tolerated)
3. PreferNoSchedule: Kubernetes prefers not to schedule (soft constraint)
```

**Real-world example:**
```bash
# Mark a node as reserved for GPU workloads
kubectl taint nodes gpu-node1 gpu=nvidia:NoSchedule

# Only pods with matching toleration can schedule here
apiVersion: v1
kind: Pod
metadata:
  name: gpu-job
spec:
  tolerations:
  - key: gpu
    operator: Equal
    value: nvidia
    effect: NoSchedule
  containers:
  - name: trainer
    image: tf:latest
```

**Production patterns:**
1. **Dedicated nodes**: Reserve hardware for specific workloads (machine learning)
2. **Maintenance windows**: Taint nodes with `NoExecute`, trigger graceful drain
3. **Multi-tenancy**: Taint with tenant ID; tenants only tolerate their own taint
4. **Spot instances**: Taint `spot-instance=true:PreferNoSchedule`; non-critical only

**Scheduler workflow with taints:**
```
Pod arrives: gpu-job
    ↓
Filtering phase:
├── Node A (no taints) → PASS
├── Node B (taint: gpu=nvidia:NoSchedule) → Check tolerations
│   ├── gpu-job has toleration? YES → PASS
│   └── (If NO → FAIL, filtered out)
└── Result: Candidate nodes
```

#### Node Affinity: Advanced Matching Rules

Node affinity supports label expressions beyond simple equality. Two types:

**1. Required (Hard Constraint)**
```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values: [ssd, nvme]    # Pod MUST run on nodes with ssd OR nvme
          - key: cpu-class
            operator: NotIn
            values: [shared]       # AND NOT on shared CPU nodes
```

If no node matches, pod stays Pending (scheduler can't fulfill it).

**2. Preferred (Soft Constraint)**
```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values: [ssd]          # Prefer SSD if available
      - weight: 50
        preference:
          matchExpressions:
          - key: region
            operator: In
            values: [us-west]      # Prefer us-west (lower weight)
```

Preferred rules adjust scoring; higher weight = stronger preference.

**Operators supported:**
```
In:           label value in set {a, b, c}
NotIn:        label value NOT in set
Exists:       label key exists (ignores value)
DoesNotExist: label key does NOT exist
Gt:           label value > integer (for numerical labels like cpu-count=4)
Lt:           label value < integer
```

#### Pod Affinity and Anti-Affinity: Pod-to-Pod Placement

Pod (anti-)affinity schedules pods relative to other pods:

**Pod Affinity (co-locate):**
```yaml
spec:
  affinity:
    podAffinity:
      requiredDuringScheduling:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values: [database]
        topologyKey: kubernetes.io/hostname
        # Result: This pod MUST run on same node as any pod labeled app=database
```

**Pod Anti-Affinity (spread):**
```yaml
spec:
  affinity:
    podAntiAffinity:
      preferredDuringScheduling:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values: [frontend]
          topologyKey: topology.kubernetes.io/zone
          # Result: Prefer to avoid scheduling on same zone as frontend pods
```

**topologyKey: The Scope Level**

The `topologyKey` defines at what level affinity applies:

```
topologyKey: kubernetes.io/hostname      → Affinity between specific NODES
topologyKey: topology.kubernetes.io/zone → Affinity within AVAILABILITY ZONES
topologyKey: topology.kubernetes.io/region→ Affinity within REGIONS
topologyKey: beta.kubernetes.io/instance-type → Affinity by NODE TYPE (GPU vs standard)
```

**Real pattern: Database + Cache co-location**
```yaml
# Deploy database pod (pod A)
apiVersion: v1
kind: Pod
metadata:
  name: postgres
  labels:
    tier: database

# Deploy cache pod (pod B) on same node
---
apiVersion: v1
kind: Pod
metadata:
  name: redis
spec:
  affinity:
    podAffinity:
      requiredDuringScheduling:
      - labelSelector:
          matchLabels:
            tier: database
        topologyKey: kubernetes.io/hostname
        # Result: Redis runs on same node as database (high-speed communication)
```

#### Pod Topology Spread Constraints: Enforcing Distribution

Topology spread prevents pod clustering by enforcing uniform distribution across topology domains:

```yaml
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: payment-processor
    # Effect: Each zone has at most (min replicas per zone + 1) pods
```

**How it works:**
```
3 zones, 9 replicas
├── Zone A: 3 pods
├── Zone B: 3 pods
└── Zone C: 3 pods

maxSkew=1 check:
├── Max pods in any zone: 3
├── Min pods in any zone: 3
├── Difference: 0 ≤ maxSkew (1) → SATISFIED
└── Result: All new pods rejected (else we'd violate constraint)

If one zone had 4:
├── Max: 4, Min: 3
├── Difference: 1 ≤ maxSkew (1) → Still satisfied
└── Result: Can schedule one more pod in zone with min (3)
```

**whenUnsatisfiable options:**
- `DoNotSchedule`: Hard constraint; pod stays Pending if can't satisfy
- `ScheduleAnyway`: Soft constraint; schedule even if violates (other constraints prioritized)

#### Scheduler Algorithm: Walkthrough Example

```
REQUEST: Deploy 5-replica stateless API
CLUSTER STATE: 3 nodes, partially filled
┌─────────────────────────────────┐
│ Node A: 60% used (2 of 3 pods)  │
├─────────────────────────────────┤
│ Node B: 40% used (1 of 3 pods)  │
├─────────────────────────────────┤
│ Node C: 20% used (0 of 3 pods)  │
└─────────────────────────────────┘

POD TEMPLATE:
  resources.requests: cpu=200m, memory=512Mi
  nodeSelector: none
  affinity: preferredDuringScheduling disktype=ssd (weight 50)
  podAntiAffinity: prefer different nodes from other api pods

SCHEDULER CYCLE (Replica 1):

───────────────────────────────────
FILTERING PHASE:
───────────────────────────────────
Check Node A: 60% used
  ✓ Has 40% free → Sufficient resources
  ✓ No nodeSelector → Match
  ✓ No taints, no tolerations needed → Match
Result: PASS (candidate)

Check Node B: 40% used
  ✓ Has 60% free → Sufficient resources
  ✓ No nodeSelector → Match
  ✓ No taints → Match
Result: PASS (candidate)

Check Node C: 20% used
  ✓ Has 80% free → Sufficient resources
  ✓ No nodeSelector → Match
  ✓ No taints → Match
Result: PASS (candidate)

CANDIDATES: {A, B, C}

───────────────────────────────────
SCORING PHASE:
───────────────────────────────────

LeastRequestedPriority (Weight: 1):
  Node A: 40% free → Score 40
  Node B: 60% free → Score 60
  Node C: 80% free → Score 80

NodeAffinityPriority (Weight: 50): Check disktype=ssd preference
  (Nodes unlabeled with disktype) → All score 50

InterPodAntiAffinityPriority (Weight: 1): No other api pods yet
  All nodes score equally → 50

BalancedResourceAllocation (Weight: 1):
  Node A: imbalanced (high usage) → Score 40
  Node B: balanced → Score 70
  Node C: very light load → Score 30

FINAL SCORES:
  Node A: (40×1 + 50×50 + 50×1 + 40×1) = 40+2500+50+40 = 2630
  Node B: (60×1 + 50×50 + 50×1 + 70×1) = 60+2500+50+70 = 2680
  Node C: (80×1 + 50×50 + 50×1 + 30×1) = 80+2500+50+30 = 2660

WINNER: Node B (highest score: 2680)

───────────────────────────────────
BINDING PHASE:
───────────────────────────────────
Bind replica 1 → Node B
├── Update etcd: pod.spec.nodeName = "node-b"
└── kubelet on node-b pulls image, starts container

After Replica 1, cluster state updated:
  Node A: 60%, Node B: 50%, Node C: 20%

REPEAT FOR REPLICAS 2-5
```

### Production Usage Patterns

**Pattern 1: Multi-tier Infrastructure (Cost Optimization)**

```yaml
# Reserved instances (always on, predicted baseline)
apiVersion: v1
kind: Node
metadata:
  labels:
    instance-type: reserved
    cost-tier: cheap

---
# On-demand/spot instances (burst capacity)
apiVersion: v1
kind: Node
metadata:
  labels:
    instance-type: spot
    cost-tier: expensive

---
# Cheap apps prefer reserved; payment service requires reserved
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-processor
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringScheduling:
          - weight: 100
            preference:
              matchExpressions:
              - key: instance-type
                operator: In
                values: [reserved]      # Prefer cheap
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringScheduling:
            nodeSelectorTerms:
            - matchExpressions:
              - key: cost-tier
                operator: In
                values: [cheap]         # MUST be reserved (SLA)
```

**Pattern 2: Colocation for Performance (Database + Cache)**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: elasticsearch
  labels:
    tier: storage
spec:
  affinity:
    podAffinityTopology:
      requiredDuringScheduling:
      - labelSelector:
          matchLabels:
            tier: cache            # Must colocate with cache
        topologyKey: kubernetes.io/hostname

---
apiVersion: v1
kind: Pod
metadata:
  name: redis-cache
  labels:
    tier: cache
spec:
  affinity:
    podAffinityTopology:
      requiredDuringScheduling:
      - labelSelector:
          matchLabels:
            tier: storage          # Must colocate with ES
        topologyKey: kubernetes.io/hostname
  # Result: ES and Redis run on SAME physical node (sub-millisecond latency)
```

**Pattern 3: Zone-Resilient Deployments**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 9
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: api
      # Results in: Zone A=3, Zone B=3, Zone C=3
      # If 1 zone fails: 6 pods still operational (67% uptime guaranteed)
```

### Best Practices for Scheduling

1. **Always define resource requests and limits**
   - Request without limit = scheduler lies (might oversubscribe)
   - Limit without request = scheduler pessimistic (won't schedule)
   - Both required for accurate placement

2. **Use appropriate affinity strictness**
   - Default: NoSchedule, soft affinity (tolerates failures)
   - Strict: RequiredDuringScheduling (pod can't run without it)
   - Only use RDS when truly necessary (harder to schedule)

3. **Implement topology spread for resilience**
   - Mandatory for production crTical services
   - Prevents single-node/zone failure affecting too many replicas

4. **Avoid circular dependencies**
   ```yaml
   # ❌ BAD: Pod A must be with B, Pod B must be with A
   # Creates scheduling deadlock
   
   # ✅ GOOD: Pod B prefers to be with A; A can run independently
   ```

5. **Label nodes consistently**
   - Adopt naming schema: `tier`, `workload`, `gpu-model`, `region`
   - Document in ClusterIP or ConfigMap for reference

### Common Pitfalls

**Pitfall 1: Over-tight constraints creating scheduling gridlock**

```yaml
# ❌ This can cause 100% unschedulable pods if topology changes
spec:
  affinity:
    podAffinity:
      requiredDuringScheduling:     # TOO STRICT
      - labelSelector:
          matchLabels:
            app: foo
        topologyKey: kubernetes.io/hostname
```

**Pitfall 2: Scheduler sees different labels than operator expects**

```bash
# Problem: Operator labels manually, scheduler can't find
kubectl label node node-1 disktype=ssd
# But node definition shows: disktype=HDD from cloud provider

# Result: Pod with nodeSelector disktype=ssd won't schedule!

# Solution: Validate labels with `kubectl get nodes --show-labels`
```

**Pitfall 3: Taint without tolerance causes instant Pending**

```bash
kubectl taint nodes gpu-node gpu=true:NoSchedule
# All existing pods (even non-GPU) now evicted if NoExecute used!

# Solution: Add tolerance to existing workloads first, then taint
```

**Pitfall 4: Forgetting topology key leads to host affinity misunderstandings**

```yaml
# ❌ Confusing: topologyKey omitted, defaults to hostname
spec:
  podAffinity:
    requiredDuringScheduling:
    - labelSelector:
        matchLabels:
          app: db        # Searches for db pod...
          # ...on the same HOSTNAME (only 1 pod per hostname usually)
          # If db pod moves or pod density > 1, breaks
    # topologyKey defaults to kubernetes.io/hostname (single node)

# ✅ Better: Explicit
    topologyKey: topology.kubernetes.io/zone
    # Now db and app spread across zones, not cramped on single host
```

### Practical Code Examples

#### Example 1: Multi-Region Failover Setup

```yaml
# Deploy API in each region, let scheduler distribute
apiVersion: apps/v1
kind: Deployment
metadata:
  name: global-api
spec:
  replicas: 12
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringScheduling:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: api
              topologyKey: topology.kubernetes.io/zone
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: api
      containers:
      - name: api
        image: myapp:v1.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
```

#### Example 2: GPU Job with CPU Fallback

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: model-training
spec:
  parallelism: 3
  completions: 3
  template:
    metadata:
      labels:
        app: training
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: accelerator
                operator: In
                values: [nvidia-a100, nvidia-v100]   # Prefer high-end GPU
          - weight: 50
            preference:
              matchExpressions:
              - key: accelerator
                operator: In
                values: [nvidia-t4]                   # Fallback to cheaper GPU
      containers:
      - name: trainer
      image: tensorflow:latest-gpu
        resources:
          requests:
            cpu: 4
            memory: 16Gi
        env:
        - name: CUDA_VISIBLE_DEVICES
          value: "0"
      restartPolicy: OnFailure
```

#### Example 3: Cluster Autoscaler with Node Affinity

```bash
#!/bin/bash
# This script configures node groups for autoscaling with affinity rules

# Create cluster with multiple node groups (AWS EKS example)
aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name gpu-nodes \
  --instance-types g4dn.xlarge \
  --tags "workload=gpu,tier=compute"

aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name standard-nodes \
  --instance-types t3.large \
  --tags "workload=general,tier=compute"

# Label nodes post-creation (if not auto-labeled)
kubectl label nodes -l "workload=gpu" gpu-type=nvidia
kubectl label nodes -l "workload=general" cpu-only=true

# Scale policies (Cluster Autoscaler respects node group limits)
# CA will add nodes from gpu-nodes only when unschedulable pod with GPU affinity exists
```

### ASCII Diagrams

**Scheduler Decision Flow**
```
┌─ Pod Created (api:v1) ────────────────┐
│ requests: {cpu: 100m, mem: 128Mi}     │
│ nodeSelector: {tier: general}         │
│ affinity: preferredZone=us-west-1     │
└────────────┬────────────────────────┘
             │
             ▼
    ┌─────────────────────┐
    │  FILTERING PHASE    │
    ├─────────────────────┤
    │ Sufficient resources?│
    │ Labels match?       │
    │ Tolerations OK?     │
    │ PVC available?      │
    └────┬────────────────┘
         │
    ┌────▼──────────────────────────────┐
    │ CANDIDATE NODES: {A, B, C}        │
    │ A: 40% used, Zone: us-west-1      │
    │ B: 70% used, Zone: us-west-2      │
    │ C: 20% used, Zone: us-west-3      │
    └────┬──────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────┐
    │     SCORING PHASE                   │
    ├─────────────────────────────────────┤
    │ Priority Functions (with weights):  │
    │ • LeastRequested: A→60, B→30, C→80 │
    │ • ZonePreference: A→100, B→0, C→0  │
    │ • PodAntiAffinity: ~equal          │
    │                                     │
    │ Final Scores:                       │
    │  A: (60×1 + 100×50) = 5060        │
    │  B: (30×1 + 0×50) = 30            │
    │  C: (80×1 + 0×50) = 80            │
    └────┬────────────────────────────────┘
         │
    ┌────▼──────────────────────────────┐
    │  BINDING PHASE                     │
    │  Winner: Node A (highest score)    │
    │  Bind pod.spec.nodeName = "node-a"│
    │  Update etcd                       │
    └────┬──────────────────────────────┘
         │
         ▼
    Pod Running on Node A (in target zone)
```

**Affinity & Taint Layered Architecture**
```
CLUSTER
├─ Node A (taint: gpu=nvidia:NoSchedule, label: tier=compute)
│  ├─ Pod 1 (toleration: gpu=nvidia, affinity: tier=compute) ✓
│  └─ Pod 2 (no tolerations) ✗ REJECTED
│
├─ Node B (label: tier=service, disktype=ssd)
│  ├─ Pod 3 (nodeSelector: disktype=ssd) ✓
│  ├─ Pod 4 (affinity: nodeAffinity tier=service) ✓
│  └─ Pod 5 (topology spread constraint) checks zone distribution
│
└─ Node C (no special labels/taints)
   └─ Pod 6 (no constraints) ✓
      Pod 7 (preferred zone affinity) tries here second/fallback
```

---

## Pod Security & Runtime Security

Pod security involves preventing privilege escalation, enforcing containerization boundaries, and detecting runtime anomalies. This section covers Pod Security Standards (replacement for PSP), Security Contexts, Network Policies, and runtime threat detection.

### Textual Deep Dive

#### Evolution: From Pod Security Policies to Standards

**Pod Security Policies (PSP)** - Deprecated in Kubernetes 1.25

Pod Security Policies were cluster-wide policies enforcing security constraints:

```yaml
# Old, deprecated approach
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
  - ALL
  runAsUser:
    rule: 'MustRunAsNonRoot'
  fsGroup:
    rule: 'RunAsAny'
  readOnlyRootFilesystem: true
```

**Issues with PSP:**
1. Stateless: Applied at admission time, no tracking
2. Complex scoping: Required RBAC + namespace annotations
3. Binary enforcement: Allow or deny, no "warn"
4. Hard to rollout: Breaking existing pods without feedback

**Pod Security Standards (PSS)** - Current Approach (1.25+)

PSS are three built-in levels applied via namespace labels, with three modes (enforce/audit/warn):

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    # Enforce mode: Pods violating standard won't be created
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    
    # Audit mode: Violations logged, pod created anyway
    pod-security.kubernetes.io/audit: restricted
    
    # Warn mode: User warned, pod created anyway
    pod-security.kubernetes.io/warn: restricted
```

**Three PSS Levels**

1. **Unrestricted** - No restrictions (legacy apps)
   - Allows: `privileged: true`, `runAsUser: 0`, `allowPrivilegeEscalation: true`
   - Use case: Legacy non-containerized apps

2. **Baseline** - Minimal restrictions (common default)
   - Prohibits: Privileged containers, privilege escalation
   - Allows: Non-root (recommended but not required), shared namespaces
   - Use case: Most modern applications

3. **Restricted** - Strict security (security-critical systems)
   - Requires: Non-root user, read-only root filesystem, dropped capabilities
   - Prohibits: Privilege escalation, unsafe defaults
   - Use case: Security-sensitive workloads, compliance (FinServ, HealthCare)

**PSS Migration Workflow**

```
Phase 1: Audit (warn mode)
├── Set warn: restricted on namespace
├── Deploy workloads
├── Check logs for warnings (not blocking)
└── Fix non-compliant workloads

Phase 2: Enforce (monitor compliance)
├── Set enforce: baseline on namespace
├── Monitor for admission rejections
├── Workloads failing moved to restricted namespace temporarily
└── Engineers fix security issues

Phase 3: Hardening (restricted mode)
├── Set enforce: restricted
├── Only truly secure workloads admitted
├── Legacy workloads in separate namespace with lower standard
└── SLA: 99%+ workloads in restricted
```

#### Security Contexts: OS-Level Security Attributes

Security context applies OS-level controls at pod or container level:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:          # Pod-level (inherited by all containers)
    runAsUser: 1000         # Run as user ID 1000
    runAsGroup: 3000        # Primary group 3000
    fsGroup: 2000           # Files created with group 2000
    seLinuxOptions:         # SELinux labels (if enabled)
      level: "s0:c123,c456"
    seccompProfile:         # Restrict syscalls
      type: RuntimeDefault
    supplementalGroups: [4000, 5000]  # Additional groups
    fsGroupChangePolicy: "OnRootMismatch"  # Fix ownership only if needed

  containers:
  - name: app
    image: myapp:latest
    securityContext:        # Container-level (overrides pod-level)
      allowPrivilegeEscalation: false   # Prevent uid 0  exec
      readOnlyRootFilesystem: true      # Root filesystem immutable
      runAsNonRoot: true                # Enforce non-root
      capabilities:
        drop:
        - ALL                 # Remove all Linux capabilities
        add:
        - NET_BIND_SERVICE   # Add only needed capability
      seccompProfile:
        type: Localhost
        localhostProfile: "my-profile.json"
    volumeMounts:
    - name: writable
      mountPath: /tmp
  
  volumes:
  - name: writable
    emptyDir: {}
```

**Security Context Mechanisms**

1. **runAsUser / runAsNonRoot**
   - Controls process UID
   - `runAsNonRoot: true` + no explicit runAsUser = error if uid=0
   - Prevents accidental root process creation

2. **Capabilities**
   - Linux gives processes granular privileges (not just root/non-root)
   - Example capabilities: `CAP_NET_BIND_SERVICE` (bind ports < 1024), `CAP_SYS_ADMIN`
   - Drop ALL, add back only needed ones (principle of least privilege)
   - Container with `CAP_SYS_ADMIN` can escape to host → never drop selectively without auditing

3. **readOnlyRootFilesystem**
   - Root filesystem mounted read-only (immutable)
   - Prevents post-compromise persistence (can't modify binaries, install backdoors)
   - Forces app to write to explicitly mounted volumes (`/tmp`, `/var/log`)

4. **allowPrivilegeEscalation**
   - If `false`, setuid/setgid binaries can't run
   - If true + runAsNonRoot, container can elevate (huge security hole)
   - Usually set to `false` to match PSS restricted

5. **SELinux / AppArmor Options**
   - Linux kernel MAC (Mandatory Access Control)
   - SELinux: Type enforcement (process can only access labeled resources)
   - AppArmor: Profile-based (define allowed /usr/bin/python access, /etc/passwd read, etc.)
   - Requires kernel support + policy configuration

6. **Seccomp Profile**
   - Restricts allowed syscalls (system calls from application to kernel)
   - Example: Remove `execve`, `fork` → container can't spawn processes
   - `RuntimeDefault`: Kubernetes default profile (prevents most useful escapes)
   - `Localhost`: Custom profile for advanced scenarios

#### Network Policies: Microsegmentation

Network policies control inbound/outbound traffic between pods (L3/L4 firewall rules).

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}  # Applies to ALL pods in namespace
  policyTypes:
  - Ingress
  ingress: []      # Empty ingress list = no ingress allowed (explicit deny-all)

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-from-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:        # From pods labeled frontend=true
        matchLabels:
          frontend: "true"
      namespaceSelector:  # AND in namespace labeled tier=frontend
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---
# Allow API pods to reach database on port 5432
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

**Network Policy Evaluation**

```
Packet arrives at Pod A (app: api)
    ↓
Check NetworkPolicies selecting Pod A
    ├─ Policy: allow-api-from-frontend
    │  ├─ Source pod has label frontend=true? YES
    │  ├─ Source namespace has label tier=frontend? YES
    │  ├─ Destination port 8080 (matches rule)? YES
    │  └─ Allow ✓
    ├─ Policy: deny-all-ingress
    │  ├─ podSelector: {} (matches all)
    │  ├─ ingress: [] (allow list empty)
    │  └─ Deny (unless previous rule allowed) ✓
    └─ Result: If ANY policy allows + NO deny-all lower priority = Allow

Order:
├── Cumulative match = Allow (OR logic between policies)
└── No match + implicit deny-all = Deny
```

**Production Best Practices with Network Policies**

1. **Default deny ingress**
   ```yaml
   # First policy: Deny all
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: default-deny-ingress
     namespace: production
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     # Empty ingress = deny all
   ```

2. **Explicit allow rules**
   ```yaml
   # Second policy: Allow only frontend
   # (all other pods remain denied from #1)
   ```

3. **Default deny egress** (more restrictive, requires more rules)
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: default-deny-egress
   spec:
     podSelector: {}
     policyTypes:
     - Egress
     # Empty egress = no outbound traffic allowed
   ```

#### Runtime Security Tools: Detecting Anomalies

Runtime security monitors container behavior at execution time, detecting:
- Unexpected process spawning (shell inside running container)
- File modifications (unauthorized changes)
- Network connections (data exfiltration)
- Privilege escalation attempts

**Falco: Behavioral Threat Detection**

Falco uses eBPF (extended Berkeley Packet Filter) to capture syscalls and alert on anomalies:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-rules
  namespace: falco
data:
  falco-rules.yaml: |
    - rule: Unauthorized Process in Container
      desc: Detect shell spawned inside container
      condition: |
        spawned_process and
        container and
        (proc.name in (bash, sh, dash))
      output: |
        Suspicious process started
        (user=%user.name command=%proc.cmdline container=%container.info)
      priority: WARNING

    - rule: Read Sensitive File
      desc: Process reads /etc/passwd
      condition: |
        open_read and
        fd.name = /etc/passwd and
        container
      output: |
        Sensitive file read
        (process=%proc.name file=%fd.name container=%container.info)
      priority: CRITICAL
```

**OPA/Gatekeeper: Policy-as-Code Enforcement**

OPA (Open Policy Agent) evaluates policies before resources are admitted:

```rego
# opa-policy.rego
package kubernetes.admission

default allow = false

allow {
    input.request.kind.kind == "Pod"
    pod := input.request.object
    # Deny if running as root
    pod.spec.securityContext.runAsNonRoot == true
}

allow {
    input.request.kind.kind == "Pod"
    pod := input.request.object
    # Allow only whitelisted image registries
    image := pod.spec.containers[_].image
    startswith(image, "dockerhub.com/internal/"  )
}

deny[msg] {
    pod := input.request.object
    containers := pod.spec.containers[_]
    containers.resources.requests.memory == null
    msg := "Container must have memory request"
}
```

#### Runtime Isolation Techniques

**1. SELinux (Linux Security Modules)**

Enforces file access controls via labels:

```yaml
securityContext:
  seLinuxOptions:
    type: "spc_t"            # Separated container type
    level: "s0:c100,c200"    # Category-based isolation
```

**2. AppArmor (Mandatory Access Control)**

Profile-based access control (easier than SELinux):

```yaml
securityContext:
  appArmorProfile:
    type: Localhost
    localhostProfile: "container-profile"
```

**3. Seccomp (Secure Computing Mode)**

Syscall filtering:

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "archMap": [
    {
      "architecture": "SCMP_ARCH_X86_64",
      "subArchitectures": [
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
      ]
    }
  ],
  "syscalls": [
    {
      "names": ["read", "write", "open", "close"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["execve"],
      "action": "SCMP_ACT_ERRNO",
      "errnoRet": 1
    }
  ]
}
```

### Common Security Pitfalls

**Pitfall 1: Assuming PSS Restricted solves all security issues**

PSS Restricted prevents privilege escalation but doesn't protect against:
- Logic flaws in application (SQL injection)
- Unpatched vulnerabilities (CVE)
- Insufficient authorization checks
- Network-level attacks

**Pitfall 2: Wide-open Network Policies**

```yaml
# ❌ BAD: Allows all traffic from any namespace
ingress:
- from:
  - namespaceSelector: {}
  ports:
  - protocol: TCP
    port: 8080
```

**Pitfall 3: readOnlyRootFilesystem without writable volumes**

```yaml
securityContext:
  readOnlyRootFilesystem: true
# App tries to write to /var/tmp, fails silently or crashes!
# Must provide volumeMounts for app's write paths
```

**Pitfall 4: Insufficient Seccomp profiles (breaks functionality)**

```yaml
seccompProfile:
  type: Localhost
  localhostProfile: "ultra-restrictive"  # Blocks needed syscalls
  # App crashes with EACCES or ENOSYS
```

### Practical Code Examples

#### Example 1: Restricted PSS Production Namespace

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: v1.28
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Compliant deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-api
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: secure-api
  template:
    metadata:
      labels:
        app: secure-api
    spec:
      serviceAccountName: secure-api
      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault

      containers:
      - name: app
        image: myapp:v1.0
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5

        volumeMounts:
        - name: cache
          mountPath: /tmp
        - name: logs
          mountPath: /var/log

      volumes:
      - name: cache
        emptyDir: {}
      - name: logs
        emptyDir: {}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secure-api
  namespace: production
```

#### Example 2: Network Policy Rules for Microservices

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: services
  labels:
    tier: services
---
# Default deny all ingress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: services
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow frontend pods to reach API
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-api
  namespace: services
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
---
# Allow API to reach database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: services
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 5432
---
# Allow database to reach cache
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-db-to-cache
  namespace: services
spec:
  podSelector:
    matchLabels:
      tier: cache
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 6379
---
# Allow external DNS resolution (egress on port 53)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: services
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
      port: 53
```

#### Example 3: Falco Rules for Incident Detection

```bash
#!/bin/bash
# Install and configure Falco for runtime monitoring

# Add Falco Helm repo
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Install Falco with custom rules
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set falco.grpc.enabled=true \
  --set falco.grpcOutput.enabled=true \
  -f - <<EOF
falco:
  rulesFile:
  - /etc/falco/rules.d
  
  customRules: |
    - rule: Sensitive File Access
      desc: Process accessing /etc/shadow
      condition: open and fd.name="/etc/shadow" and container
      output: Sensitive file accessed (user=%user.name file=%fd.name container=%container.name)
      priority: CRITICAL

    - rule: Privilege Escalation Attempt
      desc: Binary execution from /tmp
      condition: execve and container and fd.dir="/tmp"
      output: Suspicious binary execution (binary=%proc.name source=/tmp container=%container.name)
      priority: CRITICAL

alerting:
  syslog_output:
    enabled: true
  http_output:
    enabled: true
    url: http://alertmanager:9093/api/v1/alerts
EOF

# Validate Falco is capturing syscalls
kubectl logs -n falco -l app=falco -f | grep -i "suspicious"
```

### ASCII Diagrams

**Security Layers in Pod**
```
┌────────────────────────────────────────────────────┐
│ POD CONTAINER                                      │
├────────────────────────────────────────────────────┤
│ Layer 1: Pod Security Standards (Admission)        │
│  ├─ Enforced: runAsNonRoot=true, no privileged    │
│  └─ Rejected: uid=0, CAP_SYS_ADMIN                │
│                                                    │
│ Layer 2: Security Context (Runtime)                │
│  ├─ readOnlyRootFilesystem=true (immutable)       │
│  ├─ capabilities: [drop ALL, add NET_BIND]        │
│  └─ seLinuxOptions: type=spc_t (MAC)              │
│                                                    │
│ Layer 3: Seccomp (Syscall Filter)                 │
│  ├─ Allowed: read, write, open, close             │
│  └─ Blocked: execve (can't spawn shell)           │
│                                                    │
│ Layer 4: Runtime Security (Falco)                 │
│  ├─ Monitor: Unexpected process creation          │
│  ├─ Monitor: File modifications                   │
│  └─ Alert: Suspicious behavior detected           │
│                                                    │
│ Layer 5: Network Policies (Ingress/Egress)        │
│  ├─ Ingress: Only from frontend pods              │
│  ├─ Egress: Only to database (port 5432)          │
│  └─ DNS: Allowed to kube-system on port 53        │
└────────────────────────────────────────────────────┘
```

**Network Policy Flow**
```
Request arrives at Pod (API Server)
    ↓
┌─────────────────────────────────────────────┐
│ Evaluate INGRESS NetworkPolicies             │
├─────────────────────────────────────────────┤
│ Policy 1: default-deny-ingress               │
│  └─ podSelector: {} (matches all)            │
│  └─ ingress: [] (empty = deny all)           │
│                                              │
│ Policy 2: allow-frontend-to-api              │
│  ├─ podSelector: {tier: api} (matches!)      │
│  ├─ from: {tier: frontend}                   │
│  ├─ Check source pod has label? YES          │
│  └─ Allow ✓                                  │
│                                              │
│ Result: Allow (matches allow rule)           │
└─┬───────────────────────────────────────────┘
  │ (If NO allow rule matched, implicit drop)
  ▼
Request reaches container
```

---

## Rolling Updates & Rollbacks

Zero-downtime deployments require careful orchestration of pod termination, startup, and traffic routing. This section covers deployment strategies (rolling, canary, blue-green), rollback mechanisms, and SLA-aware update configurations.

### Textual Deep Dive

#### Deployment Strategies: Mechanisms and Trade-offs

**1. Rolling Update (Default)**

Gradually replaces old pods with new ones:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1              # Allow 1 extra pod temporarily
      maxUnavailable: 0        # Don't allow any to be down
  # Result: 5 pods → [5,6,5,5,5] → [5,5,6,5,5] → [5,5,5,6,5] → [5,5,5,5,6]
```

**Timeline**
```
Before: [old, old, old, old, old] (5 replicas, all v1)

Step 1: maxSurge=1 allows temporary oversupply
  [old, old, old, old, old, new]  (6 pods, 1 new)

Step 2: Old pod killed (maxUnavailable=0, so must be ready first)
  [old, old, old, old, new]       (5 pods, but new might not be ready yet)

Step 3: Another new pod created
  [old, old, old, old, new, new]  (6 pods, 2 new)

Step 4: Another old killed
  [old, old, old, new, new]       (5 pods, 3 new)

Continue until: [new, new, new, new, new]  (5 pods, all v2)

Duration: Depends on pod startup time (usually 1-5 minutes for 5 replicas)
Traffic impact: Minimal if readiness probes set correctly
Rollback time: Kill all new, start old (fast, <1 minute)
```

**Advantages**
- Simple, straightforward
- Automatic rollback available
- Minimal cluster resource overhead

**Disadvantages**
- During transition, traffic goes to both old and new versions
- Backward compatibility required if schema changed
- No controlled blast-radius

**2. Recreate Strategy**

Kill all old pods, then create new ones (causes downtime):

```yaml
strategy:
  type: Recreate
```

```
Before: [old, old, old, old, old]
Delete old: []                     (DOWNTIME STARTS - 0% uptime)
Create new: [new, new, new, new, new]
           (DOWNTIME ENDS when first pod ready)

Downtime duration: Pod startup time (30 seconds to 2+ minutes)
```

**Use cases:**
- Database schema incompatibility (old version can't read new schema, must coordinate)
- File format changes (can't have old/new coexisting reading same data)
- Batch jobs (downtime acceptable)

**3. Canary Deployment**

Release to small percentage of traffic, monitor, then expand:

```yaml
# Using Flagger (GitOps-friendly)
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api-canary
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  progressDeadlineSeconds: 60
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5              # Max 5% error rate to continue
    maxWeight: 50             # Max 50% traffic to canary
    stepWeight: 5             # Shift 5% traffic per interval
    metrics:
    - name: request_success_rate
      thresholdRange:
        min: 99               # Canary must have 99%+ success
      interval: 1m
    webhooks:
    - name: healthcheck
      url: http://flagger-loadtester/
      timeout: 5s
      metadata:
        cmd: "curl -s http://api-canary:80/health"
```

**Canary Timeline**
```
Time  | Stable (v1) | Canary (v2) | Total | Status
──────┼─────────────┼─────────────┼───────┼──────────────
0m    | 5 (100%)    | 0 (0%)      | 5     | Canary pod starting
5m    | 5 (95%)     | 1 (5%)      | 5     | Canary: 100% success rate
10m   | 4 (90%)     | 1 (10%)     | 5     | Canary: 99.5% success rate
15m   | 3 (75%)     | 2 (25%)     | 5     | Canary: 98% success rate ⚠️ Below 99%
      | Error detected! Automatic rollback triggered
20m   | 5 (100%)    | 0 (0%)      | 5     | Canary pod killed, v1 restored
```

**Advantages**
- Precision targeting (1% of users affected by bugs)
- Automated rollback on metrics deviation
- Confidence before full rollout
- Safe for risky changes

**Disadvantages**
- Requires service mesh or ingress controller (traffic splitting)
- Longer deployment timeline (10-60 minutes)
- Careful metric selection required

**4. Blue-Green Deployment**

Run two complete environments, switch traffic atomically:

```yaml
# Blue Deployment (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-blue
spec:
  replicas: 5
  template:
    metadata:
      labels:
        version: blue
    spec:
      containers:
      - name: api
        image: myapp:v1.0
---
# Green Deployment (new version, not in traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-green
spec:
  replicas: 5
  template:
    metadata:
      labels:
        version: green
    spec:
      containers:
      - name: api
        image: myapp:v2.0
---
# Service routes traffic to 'blue' initially
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    version: blue    # Traffic to blue pods
  ports:
  - port: 80
    targetPort: 8080
```

**Switching Traffic**
```
Pre-switch: Blue running, Green deployed + tested, no traffic

kubectl patch svc api -p '{"spec":{"selector":{"version":"green"}}}'

Post-switch: Traffic instantly routes to Green
  - <1 second delay (DNS cache, but usually cached)
  - Zero new connections to Blue
  - In-flight connections continue to Blue (may see brief errors)

Rollback: Reverse the selector update
kubectl patch svc api -p '{"spec":{"selector":{"version":"blue"}}}'
```

**Advantages**
- Atomic traffic switch (predictable)
- Complete environment testing before traffic (integration tests possible)
- Fast rollback (1 second)
- No gradual shift (simpler)

**Disadvantages**
- Double infrastructure cost (2x pods + 2x stateful resources)
- Requires manual testing/smoke tests before switch
- No gradual confidence building
- Stateful interactions between environments risky

**Comparison Table**
```
Strategy      | Duration  | Downtime | Rollback | Risk    | Cost
──────────────┼───────────┼──────────┼──────────┼─────────┼────────
Rolling       | 2-5 min   | None     | Fast (1m)| Medium  | 1x
Recreate      | 2-5 min   | High     | Slow (5m)| High    | 1x
Canary        | 20-60 min | None     | Auto (1m)| Very low| 1.1x
Blue-Green    | 30-120 min| <1s      | Fast (1s)| Low     | 2x
```

#### How Rollbacks Work

**Automatic Rollback (Rolling Updates)**

Kubernetes Deployment controller tracks "revisions" (ReplicaSets):

```bash
# View revision history
kubectl rollout history deployment/api
REVISION  CHANGE-CAUSE
1         kubectl apply --filename=api-v1.yaml
2         kubectl apply --filename=api-v2.yaml
3         kubectl apply --filename=api-v3-broken.yaml

# Automatic detection of broken revision (if using readiness probes)
# Pods from revision 3 fail readiness → controller detects
# If maxUnavailable exceeded, controller pauses rollout

# Manual rollback to previous working revision
kubectl rollout undo deployment/api --to-revision=2
# Triggers new rolling update: v3 → v2

# Automatic rollback via readiness/liveness probes
# If new pod repeatedly fails liveness → kubelet kills it
# Deployment controller notices replicas down, retries with old version
```

**Manual Rollback (Canary/Blue-Green)**

```bash
# Canary automatic rollback (via Flagger/service mesh)
# Canary detects metrics degradation → automatically reverts selector

# Blue-Green manual rollback
kubectl patch svc api -p '{"spec":{"selector":{"version":"blue"}}}'
# (Requires operator to decide)
```

**Revision Tracking Mechanism**

```
Deployment YAML change
    ↓
Controller detects spec change (ObservedGeneration)
    ↓
Creates new ReplicaSet (with new pod template)
    ├─ ReplicaSet.metadata.ownerReference: Deployment
    ├─ ReplicaSet.spec.template: Updated image
    └─ ReplicaSet.metadata.annotations: revision=N
    ↓
Updates Deployment with new revision:
  status.observedGeneration = new
  status.conditions: "RollingUpdateInProgress"
    ↓
Controller scales new RS up, old RS down (respects maxSurge/maxUnavailable)
    ↓
When complete:
  status.conditions: "RollingUpdateComplete"
  Older ReplicaSets kept for rollback (default: 10 revisions)
```

#### Pod Disruption Budgets: Safeguarding Updates

Pod Disruption Budgets (PDB) guarantee minimum pod availability during changes:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 2              # At least 2 replicas always available
  selector:
    matchLabels:
      app: api
```

**How PDB Affects Rolling Updates**

```
Scenario: 5-replica deployment with PDB minAvailable: 2

Rolling update wants to kill pod (maxUnavailable=1)
    ↓
Check PDB:
├─ Current ready replicas: 5
├─ PDB specifies: minimum 2 available
├─ If kill 1: 5 → 4 (still ≥ 2) → Allow ✓
└─ If kill 2: 5 → 3 (still ≥ 2) → Allow ✓

But with maxUnavailable: 3:
├─ If kill 3: 5 → 2 (still ≥ 2) → Allow ✓
├─ If kill 4: 5 → 1 (< 2) → Deny ✗
└─ Update blocked until pods become ready
```

**PDB + Node Drain (Cluster Maintenance)**

```bash
# Drain node for maintenance (evict all pods)
kubectl drain node1

Draining processes:
├─ Find all pods on node1
├─ For each pod:
│  ├─ Check PDB: If evicting would violate, skip pod
│  ├─ Otherwise: Send SIGTERM (gracefulTerminationPeriod)
│  └─ Wait for pod termination (default 30s)
├─ Pod respects PDB → drain waits for other nodes to healthily absorb pods
└─ Once safe: Node cordoned (no new pods), existing pods evicted

Timeline with PDB:
  Drain starts while 3/5 replicas running
  ├─ Kill pod-1 → 4 left (still ≥ 2) → other nodes start pod-1-new
  ├─ Kill pod-2 → 3 left (still ≥ 2) → pod-2-new pending schedule
  ├─ Kill pod-3 → 2 left (= 2 minimum) → BLOCKED until pod-1-new ready!
  ├─ pod-1-new becomes ready → 2 local + 1 new = safe
  ├─ Kill pod-4 → 2 left (still safe)
  └─ Kill pod-5 → 1 left → Wait until pod-2-new and pod-4-new ready
```

**PDB Challenges**

```
Deadlock scenario:
├─ PDB minAvailable: 3 (out of 5 total)
├─ Drain node1 (has 2 pods)
├─ Killing 1 would leave 4 pods (still ≥ 3) → allow
├─ Killing 2 would leave 3 pods (= 3 minimum) → allow, but...
│
├─ New pods can't schedule on node1 (it's cordoned)
├─ Other nodes full, can't absorb 2 new pods
└─ Deadlock: Drain waits to evict 2nd pod, but no room to schedule replacement

Solution:
├─ Increase node capacity temporarily
├─ Or reduce PDB minAvailable temporarily
├─ Or allow graceful termination (don't wait for new pod to be ready)
```

#### Readiness and Liveness Probes: Traffic Safety

Readiness probes prevent sending traffic to uninitialized pods:

```yaml
spec:
  containers:
  - name: app
    image: myapp:v1.0
    
    # Readiness: Is this pod ready for traffic?
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5    # Wait 5s after start before checking
      periodSeconds: 10         # Check every 10s
      failureThreshold: 3       # 3 failed checks = not ready
      timeoutSeconds: 1         # Timeout after 1s
    
    # Liveness: Is this pod alive or should kubelet restart it?
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30   # Wait 30s before first check (let app start)
      periodSeconds: 10         # Check every 10s
      failureThreshold: 3       # 3 failed checks = restart container
      timeoutSeconds: 1
```

**Probe Flow During Rolling Update**

```
Rolling update wants to switch traffic to new pod
    ↓
New pod created + started
    ↓
Wait initialDelaySeconds (5s) for readiness probe
    ↓
First readiness check: /ready endpoint
├─ Returns 200 OK → Pod is READY
│  └─ Service adds pod to endpoints (traffic sent)
├─ Returns 503 Ready → Pod not READY
│  └─ Service DOESN'T add pod to endpoints (traffic NOT sent)
└─ Connection timeout → Pod not READY
    └─ Service DOESN'T add pod
    ↓
Check every periodSeconds (10s)
    ↓
If 3 consecutive failures → Pod marked NotReady
├─ Service removes from endpoints (traffic redirected)
└─ Liveness probe may kill container (restart)

During rolling update:
├─ Old pod still has traffic (still in Service endpoints)
├─ New pod waits until readiness passes
├─ Service routes NEW traffic to ready pod (old continues with in-flight)
├─ Old pod terminates gracefully (preStop hook + gracefulTerminationPeriod)
└─ New pod fully takes over
```

### Production Update Patterns

**Pattern 1: Zero-Downtime Update with Health Checks**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1              # 1 extra pod allowed
      maxUnavailable: 0        # Never drop below desired count
  replicas: 5

  template:
    metadata:
      labels:
        app: api
        version: v2.0          # Change to v2.0 to trigger update
    spec:
      terminationGracePeriodSeconds: 30  # Graceful shutdown window

      containers:
      - name: api
        image: myapp:v2.0
        ports:
        - containerPort: 8080

        # Readiness: Allow time to initialize connections
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 2

        # Liveness: Restart if deadlocked
        livenessProbe:
          httpGet:
            path: /alive
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3

        # Graceful shutdown: Drain connections
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # Wait for LB to deregister

        resources:
          requests:
            cpu: 100m
            memory: 128Mi

---
# Guarantee service availability
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 3              # Always keep at least 3 pods running
```

**Pattern 2: Canary with Custom Metrics**

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api-canary
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  
  # Do NOT change replicas (handled by HPA if used)
  skipAnalysis: false
  
  service:
    port: 80
    targetPort: 8080

  analysis:
    interval: 30s
    threshold: 5              # Max 5 failed metrics checks
    maxWeight: 50             # Scale up to 50% traffic
    stepWeight: 5             # Increase by 5% every interval
    
    metrics:
    - name: error-rate
      query: |
        100 - (sum(rate(http_requests_total{status=~"2..",version="{{ .Version }}"}[5m])) 
               / sum(rate(http_requests_total{version="{{ .Version }}"}[5m])) * 100)
      thresholdRange:
        max: 1                 # Error rate <= 1%

    - name: latency
      query: |
        histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket{version="{{ .Version }}"}[5m])) by (le))
      thresholdRange:
        max: 500               # P99 latency <= 500ms

    # Webhook for custom checks
    webhooks:
    - name: acceptance-tests
      url: http://flagger-loadtester/
      timeout: 5s
      metadata:
        type: "bash"
        cmd: "curl -s http://api-canary/api/test"

  # Automatic rollback on failure
  skipAnalysis: false
```

### Common Pitfalls

**Pitfall 1: Zero maxUnavailable with slow startup**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0      # Don't kill old until new ready
```

If new pod takes 2 minutes to start, rolling update stalls for 2 minutes per pod.
For 5 pods: 10 minutes total, cluster runs at 6 pods temporarily (cost spike).

**Solution:** Either accept small maxUnavailable, or increase maxSurge.

**Pitfall 2: Readiness probe checks wrong thing**

```yaml
readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - test -f /healthy    # Checks file existence, not actual readiness!
```

Probe might pass while database connections still initializing.

**Solution:** HTTP endpoints that actually validate dependencies.

**Pitfall 3: PDB minAvailable too high causes scheduling deadlock**

```yaml
spec:
  minAvailable: 5          # All 5 pods must stay up
```

One node fails → 3 pods lost → trying to schedule 3 new pods
But maxSurge prevents temporary oversupply.
Deadlock: Can't start new pods (would violate PDB), can't evict old (would violate PDB).

**Solution:** minAvailable should be < total replicas - expected node downtime.

### Practical Code Examples

#### Example 1: Automated Canary with Flagger + Prometheus

```bash
#!/bin/bash
# Setup canary deployment with automatic metric-driven rollback

# 1. Install Flagger
helm repo add flagger https://flagger.app
helm install flagger flagger/flagger \
  --namespace flagger-system \
  --create-namespace \
  --set prometheus.install=true

# 2. Install Linkerd (service mesh, enables traffic splitting)
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh
linkerd install | kubectl apply -f -
linkerd inject deployment/api | kubectl apply -f -

# 3. Define Canary resource
cat <<EOF | kubectl apply -f -
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api-canary
  namespace: default
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  service:
    port: 80
  analysis:
    interval: 1m
    threshold: 5
    maxWeight: 50
    stepWeight: 5
    metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
      interval: 1m
    - name: request-duration
      thresholdRange:
        max: 500
      interval: 1m
EOF

# 4. Trigger canary by updating image
kubectl set image deployment/api api=myapp:v1.1

# 5. Watch canary progress
kubectl describe canary api-canary
# Shows traffic percentage,metrics, phase (Initializing → Progressing → Succeeded or Failed)
```

#### Example 2: Blue-Green Deployment Script

```bash
#!/bin/bash
# Atomically switch between blue and green deployments

CURRENT_VERSION=$(kubectl get svc api -o jsonpath='{.spec.selector.version}')

if [ "$CURRENT_VERSION" == "blue" ]; then
  echo "Currently running BLUE. Deploying GREEN..."
  NEXT_VERSION="green"
  CURRENT="blue"
else
  echo "Currently running GREEN. Deploying BLUE..."
  NEXT_VERSION="blue"
  CURRENT="green"
fi

# Deploy new version
kubectl set image deployment/api-$NEXT_VERSION api=myapp:$NEW_TAG

# Wait for rollout
kubectl rollout status deployment/api-$NEXT_VERSION --timeout=5m

# Run smoke tests
echo "Running smoke tests on $NEXT_VERSION..."
curl -f http://api-$NEXT_VERSION:8080/health || exit 1
curl -f http://api-$NEXT_VERSION:8080/api/users || exit 1

# Switch traffic
echo "Switching traffic from $CURRENT to $NEXT_VERSION..."
kubectl patch svc api -p '{"spec":{"selector":{"version":"'$NEXT_VERSION'"}}}'

echo "✅ Deployment complete! Now running $NEXT_VERSION"
echo "To rollback: kubectl patch svc api -p '{\"spec\":{\"selector\":{\"version\":\"'$CURRENT'\"}}}'  "
```

### ASCII Diagrams

**Rolling Update Timeline**
```
Deployment update triggered (new image version)
    ↓
┌─────────────────────────────────────────────────┐
│ Time 0: [old1, old2, old3, old4, old5]          │
│         maxSurge=1, maxUnavailable=0            │
├─────────────────────────────────────────────────┤
│ Create new1                                      │
│ [old1, old2, old3, old4, old5, new1-pending]   │
├─────────────────────────────────────────────────┤
│ new1 starts, waits for readiness                │
│ [old1, old2, old3, old4, old5, new1-loading]   │
├─────────────────────────────────────────────────┤
│ new1 passes readiness, service routes traffic   │
│ [old1, old2, old3, old4, old5, new1-ready]     │
├─────────────────────────────────────────────────┤
│ Kill old1 (1 pod becomes unavailable)           │
│ [old2, old3, old4, old5, new1]                  │
├─────────────────────────────────────────────────┤
│ Create new2 (surge allowed again)               │
│ [old2, old3, old4, old5, new1, new2-pending]   │
├─────────────────────────────────────────────────┤
│ new2 ready                                       │
│ [old2, old3, old4, old5, new1, new2]            │
├─────────────────────────────────────────────────┤
│ Kill old2                                        │
│ [old3, old4, old5, new1, new2]                  │
├─────────────────────────────────────────────────┤
│ Repeat until all old pods replaced              │
│ [new1, new2, new3, new4, new5]                  │
└─────────────────────────────────────────────────┘

Total time: 5 × (readiness time + kill time) ≈ 5-10 minutes
Uptime: 100% (always 5 replicas available)
```

**Canary Traffic Shift**
```
Interval 1 (0-1 min):        Interval 2 (1-2 min):
[Stable: 95%]                [Stable: 90%]
[Canary: 5%]  ← OK           [Canary: 10%] ← OK
Metrics: 99.8% success        Metrics: 98.5% success

Interval 3 (2-3 min):        Interval 4 (3-4 min):
[Stable: 85%]                AUTOMATIC ROLLBACK!
[Canary: 15%] ← ERROR!       [Stable: 100%]
Metrics: 96.2% success        [Canary: 0%]
(Below 99% threshold)         Error rate restored
```

---

## Autoscaling

Autoscaling dynamically adjusts resources based on demand. Three levels exist: pod (HPA/VPA), cluster (node autoscaling), and custom metrics. This section covers all three with production patterns.

### Textual Deep Dive

#### Horizontal Pod Autoscaler (HPA): Replica Count

HPA automatically scales pod replicas based on metrics:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  
  minReplicas: 2              # Never scale below 2
  maxReplicas: 100            # Never scale above 100
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70       # Scale up if avg CPU > 70%
  
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80       # Scale up if avg memory > 80%
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100                    # Double replicas every 15s
        periodSeconds: 15
      - type: Pods
        value: 10                     # Or add 10 pods every 15s (pick max)
        periodSeconds: 15
      selectPolicy: Max               # Use whichever increases more
    
    scaleDown:
      stabilizationWindowSeconds: 300 # Wait 5 min before scaling down
      policies:
      - type: Percent
        value: 50                     # Max 50% reduction per 60s
        periodSeconds: 60
      - type: Pods
        value: 2                      # Max 2 pod reduction per 60s
        periodSeconds: 60
      selectPolicy: Min               # Use whichever reduces less (conservative)
```

**HPA Algorithm**

```
METRIC COLLECTION (every 15 seconds):
  Metrics server → kubelet → node resources
  Collects: pod CPU, memory for last 1 minute
  
SCALE DECISION CALCULATION:
  desiredReplicas = ceil(currentReplicas × (currentMetric / targetMetric))
  
  Example:
  ├─ Current replicas: 10
  ├─ Current CPU: 750m (avg per pod: 75m if 10 pods = 750m)
  │  Wait, that's not how it works. HPA measures % of REQUEST
  │
  ├─ Pod CPU request: 100m
  ├─ Actual CPU usage: 75m per pod (average across 10 pods)
  ├─ Utilization: 75m / 100m = 75%
  ├─ Target: 70%
  ├─ Desired replicas: ceil(10 × (75% / 70%)) = ceil(10.7) = 11
  │  (Add 1 pod)
  │
  └─ Scale action: 10 → 11 (if subject to policies)

POLICIES APPLICATION:
  ├─ scaleUp: Can increase by 100% (max every 15s)
  │  ├─ 10 → 20 allowed (10 × 2 = Percent policy)
  │  ├─ 10 + 10 allowed (Pods policy)
  │  └─ Pick Max: 20
  ├─ But desiredReplicas = 11, so: 10 → 11 (below max allowed)
  └─ Final: Scale to 11

METRIC STABILIZATION:
  ├─ scaleUp: No stabilization (immediate reaction)
  ├─ scaleDown: 300s stabilization (wait 5 min before considering scale-down)
  │  ├─ Even if metrics fall, wait 300s
  │  └─ Prevents flapping (rapid scale-up/down cycles)
  └─ Purpose: Single traffic dip shouldn't spark scale-down
```

**Metrics Types**

1. **Resource Metrics** (CPU/Memory)
   ```yaml
   type: Resource
   resource:
     name: cpu
     target:
       type: Utilization
       averageUtilization: 70        # % of request
       # OR
       type: AverageValue
       averageValue: 75m             # 75 millicores per pod
   ```

2. **Custom Metrics** (Application-specific)
   ```yaml
   type: Pods
   pods:
     metric:
       name: http_requests_per_second
       selector:
         matchLabels:
           instance-type: singleton   # Optional: filter by pod label
     target:
       type: AverageValue
       averageValue: 100              # 100 req/s per pod
   ```

3. **External Metrics** (Cloud provider metrics)
   ```yaml
   type: External
   external:
     metric:
       name: queue_depth
       selector:
         matchLabels:
           queue-name: payment-jobs
     target:
       type: AverageValue
       averageValue: 50               # Average 50 items per pod
   ```

**Utilization vs. Absolute Value**

```
Request = 100m CPU per pod

Scenario A: Utilization target
  target.averageUtilization: 70%
  Actual CPU: 70m per pod
  Calc: 10 pods × (70/100) = 7 pods would satisfy 70m/(100m request) = 70%
  Action: Scale UP to increase denominator (reduce utilization %)

Scenario B: Absolute Value target  
  target.averageValue: 70m
  Actual CPU: 70m per pod
  Calc: 10 pods × 70m = 700m total, divided across N pods
  If 700m total needed, 70m per pod → 700/70 = 10 pods needed
  Action: Maintain
```

#### Vertical Pod Autoscaler (VPA): Right-sizing Requests/Limits

VPA adjusts pod resource requests/limits based on actual usage:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       api
  
  # Control VPA behavior
  updatePolicy:
    updateMode: "Auto"         # Auto-update pods (restart if needed)
    # OR "Off" (recommendation only)
    # OR "Recreate" (delete pod, scheduler creates new with updated requests)
    # OR "Initial" (only update on creation, not existing pods)
  
  # Exclude specific containers
  resourcePolicy:
    containerPolicies:
    - containerName: api
      minAllowed:
        cpu: 50m               # Don't go below 50m (even if using less)
        memory: 64Mi
      maxAllowed:
        cpu: 500m              # Don't go above 500m (even if using more)
        memory: 512Mi
      controlledResources:
      - cpu
      - memory
```

**VPA Algorithm**

```
RECENT RESOURCE HISTORY (30 days):
  ├─ Collect CPU, memory usage per pod
  ├─ Filter outliers (99th percentile)
  └─ Calculate: mean, standard deviation, percentiles

RECOMMENDATION CALCULATION:
  target_cpu = (p50_usage + p95_usage) / 2          # Conservative estimate
  buffer     = std_dev(usage) × safety_factor       # Account for variance
  recommended_request = target_cpu + buffer
  recommended_limit   = recommended_request × 2.5   # Limits usually 2.5-3x requests

EXAMPLE:
  ├─ Pod CPU history: [30m, 35m, 32m, 80m, 28m, 31m] (80m is spike outlier)
  ├─ Filtered: [30m, 35m, 32m, 28m, 31m]
  ├─ Mean: 31m, Std Dev: 2.5m
  ├─ P50: 31m, P95: 35m
  ├─ Recommended request: (31 + 35) / 2 + 2.5×1.5 = 37.75m ≈ 40m
  ├─ Recommended limit: 40m × 2.5 = 100m
  └─ Current request: 100m (OVER-provisioned by 60%)

UPDATE MODES:
  ├─ Auto: Update requests, restart pods to apply
  ├─ Recreate: Delete pod, let scheduler create new with updated requests
  ├─ Initial: Only apply to new pods, not existing ones
  └─ Off: Recommendation only (VPA compute but doesn't apply)

RESTRICTIONS:
  ├─ Cannot update CPU requests while HPA scaling replicas
  │  └─ Interaction: HPA = horizontal, VPA = vertical, conflicts on target sizing
  ├─ Cannot update StatefulSet requests (persistent identity conflicts)
  └─ minAllowed/maxAllowed bounds recommendations
```

**HPA vs VPA vs Cluster Autoscaler**

```
HPA (Horizontal):             VPA (Vertical):            Cluster Autoscaler:
├─ Scales: Pod count          ├─ Scales: Request/limits   ├─ Scales: Node count
├─ Metrics: CPU, memory       ├─ Metrics: Resource usage  ├─ Trigger: Unschedulable pods
├─ Speed: Fast (1-5 min)      ├─ Speed: Medium (hours)    ├─ Speed: Slow (2-4 min)
├─ Cost: Helps efficiency     ├─ Cost: Prevents waste     ├─ Cost: Manages infrastructure
└─ Use: Scale replicas up     └─ Use: Fit pods properly   └─ Use: Add nodes
```

**When NOT to use VPA**

```
VPA issues with:
├─ StatefulSet → Persistent identity + changing request = data loss risk
├─ DaemonSet → Pod must run on every node, changing request might not fit
├─ Batch jobs → Short-lived, insufficient history for recommendations
├─ Frequently restarting apps → Will cause extra restarts
└─ HPA enabled on same deployment → Conflicts in scaling decision
```

#### Cluster Autoscaler: Node Provisioning

Cluster Autoscaler (CA) automatically scales the cluster's node count based on pod scheduling requirements:

```bash
# Install Cluster Autoscaler (AWS EKS example)
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=my-cluster \
  --set awsRegion=us-east-1 \
  --set cloudProvider=aws
```

**Cluster Autoscaler Algorithm**

```
SCALE-UP LOGIC (every 10 seconds):
  ├─ Scan for Pending pods (unschedulable)
  ├─ Try to schedule on existing nodes
  │  ├─ Enough resources? YES → scheduler will schedule
  │  └─ Not enough? Continue...
  ├─ Estimate new node cost + requirements
  ├─ Pick cheapest node type that fits pods
  └─ Request new node from cloud provider (ASG/node pool)

SCALE-DOWN LOGIC (every 10 seconds, but skipped if recent scale-up):
  ├─ Flag "unneeded" nodes:
  │  ├─ Node has <50% allocated resources
  │  ├─ ALL pods on node can fit elsewhere (no affinity)
  │  └─ No managed workloads (Deployment, StatefulSet, etc.) pods
  ├─ Wait 10 minutes (scale-down delay)
  │  └─ Prevents thrashing (rapid add/remove cycle)
  ├─ Drain node (evict pods)
  │  ├─ Respects PDB (doesn't over-evict)
  │  └─ Respects node drain logic (preStop hooks)
  └─ Delete node (ASG terminates instance)

SCALE-DOWN DELAY:
  ├─ Default: 10 minutes
  ├─ Purpose: Avoid thrashing
  ├─ Example: Node becomes unneeded after scale-up (initial overshoot)
  │  └─ Wait 10m before attempting removal
```

**Cluster Autoscaler Constraints**

```
Pods CA cannot move (won't scale-down if present):
├─ Pods with local storage (emptyDir, hostPath)
├─ Pods with affinity/topology constraints to specific nodes
├─ Kube-system pods (except those in allowed list)
├─ Pods with resource limits preventing scheduling
└─ StatefulSet pods (persistent identity)

Node pool constraints:
├─ minSize: Minimum nodes (CA won't scale below)
├─ maxSize: Maximum nodes (CA won't scale above)
├─ maxTotalNodes: Cluster-wide node limit
└─ EC2 Instance Limits: AWS quota constraints
```

#### Preventing HPA Flapping

Flapping occurs when HPA repeatedly scales up/down due to metric threshold oscillation:

```
10 replicas, target 70% CPU, current 71%
  ├─ Scale to 11 replicas
  ├─ CPUs dilute: 71% × 10/11 = 64.5%
  ├─ Below target → Scale-down triggered immediately
  ├─ Scale back to 10 replicas
  ├─ CPUs concentrate again: 64.5% × 11/10 = 71%
  ├─ Above target → Scale-up again
  └─ Infinite loop: 10 ↔ 11 ↔ 10 ↔ 11...
```

**Prevention Mechanisms**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0         # Immediate scale-up
      policies:
      - type: Percent
        value: 100                          # Or 200%, multiple at once
        periodSeconds: 15
    
    scaleDown:
      stabilizationWindowSeconds: 300       # CRITICAL: Wait 5 minutes
      policies:
      - type: Percent
        value: 50                           # Conservative 50% reduction
        periodSeconds: 60                   # Check only every 60s
```

**Stabilization Window Effect**

```
Scale-up at T=0 (10→20 replicas)
  ├─ Metrics drop due to dilution (71% → 50%)
  ├─ T=60s: Metric check says scale-down needed
  ├─ T=120s: Still below threshold
  ├─ T=300s (5 min): stabilizationWindow expires, scale-down allowed
  │  ├─ Check: Below threshold for full 300s? YES
  │  └─ Act: Scale down: 20 → 10 replicas
  └─ Wait 5 min before considering scale-down again
```

### Common Autoscaling Pitfalls

**Pitfall 1: Mismatched Requests and HPA Target**

```yaml
spec:
  containers:
  - resources:
      requests:
        cpu: 100m          # Updated here
        
spec:
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70     # But HPA still targets 70%
```

Now HPA calculates based on 100m request, but if you changed request expecting HPA to adjust, it won't.

**Solution**: Always update HPA target when changing requests, or use VPA + HPA together carefully.

**Pitfall 2: Insufficient Baseline Capacity**

```yaml
minReplicas: 1              # ← Dangerous
maxReplicas: 100
```

At minReplicas=1, any pod failure = 100% downtime (until CA scales up).
CA can take 2-4 minutes to provision node.
Meanwhile, single pod handles 100% traffic.

**Solution**: Set minReplicas to at least 2 for HA.

**Pitfall 3: Custom Metrics with Gaps**

If your application doesn't export metrics consistently, HPA can't scale:
- Startup: Metrics missing first 30s
- Rolling update: Metrics briefly unavailable
- Pod crashes: Metrics stop

**Solution**: Use multiple metrics (fallback), add health checks before metrics exposure.

**Pitfall 4: Not accounting for startup latency**

```yaml
HPA scales from 10 → 20 replicas
├─ New pod startup: 5-30 seconds
├─ Container startup: 10-20 seconds (wait for readiness)
├─ Traffic ramps: First requests fail (not ready)
└─ Real capacity increase: 60+ seconds AFTER scale decision
```

Meanwhile, queue depth keeps growing.

**Solution**: Pre-scale conservatively, accept slightly higher error rate temporarily.

### Practical Code Examples

#### Example 1: HPA with Custom Metrics (Shopping Cart)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout-service
  
  minReplicas: 3
  maxReplicas: 100
  
  metrics:
  # Primary: Shopping cart count
  - type: Pods
    pods:
      metric:
        name: shopping_carts_active
      target:
        type: AverageValue
        averageValue: "10"           # 10 carts per pod
  
  # Fallback: CPU if custom metric unavailable
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 75
  
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 200                   # Triple pods every 15s
        periodSeconds: 15
      - type: Pods
        value: 20                    # Or add 20 pods
        periodSeconds: 15
      selectPolicy: Max
    
    scaleDown:
      stabilizationWindowSeconds: 600  # 10 min (don't hurt UX)
      policies:
      - type: Percent
        value: 25                    # Max 25% reduction per minute
        periodSeconds: 60
```

**Metrics Instrumentation** (Python/Prometheus)

```python
from prometheus_client import Gauge, Counter
import time

# Export active shopping carts
shopping_carts_gauge = Gauge('shopping_carts_active', 'Active shopping carts')

# Simulate cart activity
active_carts = set()

@app.route('/api/cart/add/<cart_id>')
def add_item(cart_id):
    active_carts.add(cart_id)
    shopping_carts_gauge.set(len(active_carts))
    return {'status': 'ok'}, 200

@app.route('/metrics')
def metrics():
    # Prometheus scrapes this endpoint
    return generate_latest()
```

#### Example 2: VPA with HPA (Correct Configuration)

```yaml
# Step 1: Deploy VPA in "recommend" mode (no auto-update)
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: api-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  updatePolicy:
    updateMode: "Off"              # Recommendations only
  resourcePolicy:
    containerPolicies:
    - containerName: api
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1000m
        memory: 1Gi

---
# Step 2: HPA scales horizontally based on current requests
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  
  minReplicas: 2
  maxReplicas: 50
  
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300

---
# Step 3: Manually apply VPA recommendations weekly
# Workflow:
# 1. kubectl describe vpa api-vpa          # View recommendations
# 2. Update Deployment requests (IaC)
# 3. Commit, merge, deploy
# RESULT: Vertical sizing manual, Horizontal sizing automatic
```

#### Example 3: Cluster Autoscaler + Node Pools

```bash
#!/bin/bash
# Setup multi-node-pool autoscaling with cost optimization

# AWS EKS: Create cluster with multiple node pools
aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name on-demand-nodes \
  --instance-types t3.large m5.large \
  --desired-size 3 \
  --min-size 2 \
  --max-size 20 \
  --tags 'cost-tier=standard,workload=general'

aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name spot-nodes \
  --instance-types t3.large m5.large \
  --desired-size 2 \
  --min-size 0 \
  --max-size 10 \
  --capacity-type SPOT \
  --tags 'cost-tier=cheap,workload=batch'

# Install Cluster Autoscaler
helm install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=my-cluster \
  --set cloudProvider=aws \
  --set awsRegion=us-east-1

# Deploy workloads with node affinity
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-api
spec:
  replicas: 5
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringScheduling:
            nodeSelectorTerms:
            - matchExpressions:
              - key: cost-tier
                operator: In
                values: [standard]    # Must use on-demand
      containers:
      - name: api
        image: myapp:latest
        resources:
          requests:
            cpu: 200m
            memory: 256Mi

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-processor
spec:
  replicas: 10
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringScheduling:   # Prefer cheap, tolerate failure
          - weight: 100
            preference:
              matchExpressions:
              - key: cost-tier
                operator: In
                values: [cheap]
      containers:
      - name: batch
        image: batch-job:latest
        resources:
          requests:
            cpu: 1
            memory: 1Gi
EOF

# Monitor scaling
watch kubectl top nodes
kubectl logs -n kube-system -l app=cluster-autoscaler -f
```

### ASCII Diagrams

**HPA Scaling Decision Loop**
```
┌─────────────────────────────────────────────┐
│ METRICS-SERVER collects pod metrics         │
│ (CPU, memory from kubelet)                  │
└──────────────┬──────────────────────────────┘
               │ 15 seconds
               ▼
┌─────────────────────────────────────────────┐
│ HPA CONTROLLER evaluates metrics            │
│ ├─ Is there another controller holding lock?│
│ │  (Prevents simultaneous scaling)          │
│ └─ Calculate desired replicas               │
└──────────────┬──────────────────────────────┘
               │
         ┌─────▼──────┐
         │ desiredN = │
         │ current ×  │
         │ (actual/   │
         │  target)   │
         └─────┬──────┘
               │
         ┌─────▼────────────┐
         │ Apply policies   │
         │ ├─ scaleUp/Down  │
         │ ├─ percent/pods  │
         │ └─ stabilization │
         └─────┬────────────┘
               │
        ┌──────▼──────────┐
        │ new replicas =  │
        │ apply policies  │
        │ to current      │
        └─────┬───────────┘
              │
        ┌─────▼────────────────────────┐
        │ Replicas changed? YES        │
        │ Scale deployment: 10 → 12    │
        ├─────────────────────────────┤
        │ Deployment controller:       │
        │ ├─ Update spec.replicas      │
        │ ├─ Create new ReplicaSet     │
        │ └─ Launch 2 new pods         │
        └──────────────┬───────────────┘
                       │ 30 seconds
                       ▼
        Pods ready, traffic increasing
        HPA loop repeats every 15 seconds
```

**VPA Recommendation Update Timeline**
```
Phase 1: DATA COLLECTION (Continuous)
┌──────────────────────────────────┐
│ VPA accumulates pod metrics:     │
│ ├─ Week 1: [30m, 35m, 32m, ...] │
│ ├─ Week 2: [28m, 31m, 34m, ...] │
│ └─ Week 4: [32m, 33m, 31m, ...] │
└──────────────┬───────────────────┘
               │
Phase 2: RECOMMENDATION (Daily)
┌──────────────────────────────────┐
│ VPA Recommender calculates:      │
│ ├─ P50 CPU: 31m                  │
│ ├─ P95 CPU: 35m                  │
│ ├─ Recommendation: 40m           │
│ └─ Updates VPA.status.recommend  │
└──────────────┬───────────────────┘
               │
Phase 3: APPLY (If updateMode != Off)
┌──────────────────────────────────┐
│ VPA Updater:                     │
│ ├─ Pod running with 100m request │
│ ├─ Recommended: 40m              │
│ ├─ Kill pod (if Auto mode)       │
│ ├─ Scheduler creates new pod     │
│ └─ New pod spec: request 40m     │
└──────────────────────────────────┘
```

---


## Hands-on Scenarios

### Scenario 1: Multi-Zone Resilience with Topology Spreading

**Objective**: Deploy 9-replica service across 3 zones with no zone having more than 4 replicas.

**Challenge**: Without topology spread, scheduler may pack pods in single zone, creating single-point-of-failure.

**Implementation**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resilient-api
spec:
  replicas: 9
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      topologySpreadConstraints:
      - maxSkew: 1              # Difference between zones: max 1 pod
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: api
      containers:
      - name: api
        image: api:v1.0
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
```

**Validation**:
```bash
kubectl get pods -o wide | grep resilient-api
# Should see 3 pods per zone [us-east-1a, us-east-1b, us-east-1c]
```

### Scenario 2: GPU Pod Affinity with Fallback

**Objective**: Schedule ML training on GPU nodes, fallback to CPU without failing.

**Challenge**: Not all nodes have GPU; required affinity would fail scheduling.

**Implementation**:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: training-job
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:  # Soft constraint
          - weight: 100
            preference:
              matchExpressions:
              - key: accelerator
                operator: In
                values: [nvidia-a100]
          - weight: 50
            preference:
              matchExpressions:
              - key: accelerator
                operator: In
                values: [nvidia-v100]
      containers:
      - name: trainer
        image: ml-trainer:v1
        resources:
          requests:
            cpu: 4
            memory: 16Gi
            # nvidia.com/gpu: 1  # Uncomment to request GPU
      restartPolicy: Never
```

### Scenario 3: Canary Deployment with Automated Rollback

**Objective**: Roll out new version to 10% of traffic, auto-rollback if error rate exceeds 1%.

**Challenge**: Orchestrate canary + monitoring + automatic rollback.

**Implementation** (using Flagger + Prometheus):
```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: api-canary
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  progressDeadlineSeconds: 60
  service:
    port: 80
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: error-rate
      thresholdRange:
        max: 1  # Abort if error rate > 1%
      interval: 1m
    - name: latency
      thresholdRange:
        max: 500  # Abort if p99 latency > 500ms
      interval: 1m
  skipAnalysis: false
```

### Scenario 4: Pod Disruption Budget for Cluster Maintenance

**Objective**: Cluster upgrade drains nodes; ensure critical service maintains minimum replicas.

**Challenge**: Node drain could kill too many pods, causing outage.

**Implementation**:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-api-pdb
spec:
  minAvailable: 2          # Must keep 2 pods running
  selector:
    matchLabels:
      tier: critical
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-api
spec:
  replicas: 5              # Total 5, minimum 2 = 3 can be disrupted
  selector:
    matchLabels:
      tier: critical
  template:
    metadata:
      labels:
        tier: critical
    spec:
      terminationGracePeriodSeconds: 30
      containers:
      - name: api
        image: api:v1
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # Graceful drain period
```

### Scenario 5: Horizontal Pod Autoscaling on Custom Metrics

**Objective**: Scale checkout pods based on active shopping cart count (business metric), not CPU.

**Challenge**: CPU/memory metrics irrelevant; must consume custom Prometheus metric.

**Implementation**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout
  minReplicas: 2
  maxReplicas: 50
  metrics:
  - type: Pods
    pods:
      metric:
        name: shopping_carts_active
      target:
        type: AverageValue
        averageValue: "10"      # Scale up when avg carts per pod > 10
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60       # Max 50% reduction per minute
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15       # Can double every 15 seconds
      - type: Pods
        value: 10
        periodSeconds: 15       # Or add 10 pods every 15 seconds
      selectPolicy: Max          # Pick whichever results in larger increase
```

**Metrics Exposition** (in instrumentation):
```python
# In checkout pod application (Prometheus Python client)
shopping_carts_metric = Gauge('shopping_carts_active', 'Active shopping carts')
shopping_carts_metric.set(len(active_carts))
```

### Scenario 6: Restricted Pod Security Standard Enforcement

**Objective**: Enforce that all pods in production namespace follow restricted PSS.

**Challenge**: Prevent privilege escalation, require non-root execution, enforce read-only filesystems.

**Implementation**:
```yaml
# Apply to production namespace
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
# Compliant pod example
apiVersion: v1
kind: Pod
metadata:
  name: compliant-app
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    image: app:v1
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: writable
      mountPath: /tmp
  volumes:
  - name: writable
    emptyDir: {}
```

---

## Interview Questions for Senior Engineers

### Scheduling & Placement (3 questions)

**Q1: You have a 3-zone Kubernetes cluster with 5 replicas of a high-traffic API. One zone goes down (10 nodes lost). Using only pod topology spread constraints and no pod disruption budget, what happens? How would you prevent this?**

Expected Answer:
- Without PDB, the 10 nodes drain simultaneously, potentially killing all 5 replicas if they happened to land in that zone
- Topology spread ensures distribution but only during scheduling; doesn't prevent simultaneous drain
- Solution: Add `minAvailable: 3` Pod Disruption Budget to guarantee 3 always run, preventing full zone loss from killing service
- Advanced: Mention preferred topology spread vs. required; required prevents scheduling if skew unavoidable

**Q2: A machine learning pipeline requires GPU nodes, but you have 5 worker nodes total (1 GPU, 4 CPU-only). Your job uses `nodeAffinity: requiredDuringScheduling` to target GPU. What's the downside of this approach? Propose an alternative.**

Expected Answer:
- Single GPU node becomes bottleneck; if it's down for maintenance, job fails scheduling
- Zero fault tolerance for GPU node failures
- Alternative: Use `preferredDuringScheduling` to prefer GPU but allow fallback to CPU; degrade gracefully
- Advanced answer: Use node auto-scaling + multiple GPU node pools; if GPU pool full, scale up

**Q3: Explain why a pod with `requests: cpu: 500m` might cause HPA to behave unexpectedly when scaled across heterogeneous nodes (3GHz and 4GHz CPUs). How should you handle this?**

Expected Answer:
- CPU requests use absolute millicores, not percentage of node CPU
- 500m on 3GHz node = 16.7% utilization; on 4GHz = 12.5%
- HPA target is % of request (e.g., 70%), so same pod reports different CPU% on different nodes
- If node has less capacity, percentage trigger fires unpredictably
- Solutions: Use node capacity-aware autoscaling, separate node pools by type, use VPA to adjust requests per machine

### Pod Security & Runtime Security (3 questions)

**Q4: You've implemented Pod Security Standards with "restricted" level on your production namespace. A legacy application requires `runAsUser: 0` (root) and `allowPrivilegeEscalation: true`. How would you handle this without downgrading the PSS policy?**

Expected Answer:
- Don't downgrade PSS; maintains security posture for all other pods
- Solution: Create dedicated namespace with "baseline" or "unrestricted" PSS for legacy app
- Quarantine the legacy app with network policies, runtime security monitoring (Falco)
- Alternative: Run legacy app on isolated nodes (node pool) without access to cluster secrets
- Best: Containerize legacy app properly (non-root user, minimal capabilities); argue for modernization
- Advanced: Use OPA/Gatekeeper custom policies for exceptions with audit/approval workflow

**Q5: Your cluster runs Falco for runtime security. It detected a process inside a container executing `/bin/sh`. How would you determine if this is a compromise vs. legitimate debugging?**

Expected Answer:
- Check Falco rule context: process parent (sshd, kubectl exec, or attacker?)
- Check execution path: from within container startup scripts (legitimate) vs. dynamically spawned (suspicious)
- Examine process ancestry/user context
- Correlate with deployment timeline: did this process appear after rollout (new bug) or during quiet period (breach)?
- Check for network exfiltration indicators (unexpected outbound connections)
- Response: isolate pod immediately, preserve logs, investigate, update Falco rules to prevent recurrence
- Advanced: Implement behavior baseline using machine learning; alert on anomalous process chains

**Q6: You want to adopt Seccomp profiles to restrict syscalls in your microservices but fear breaking legitimate functionality. What's a safe rollout strategy?**

Expected Answer:
- Phase 1: Audit mode recording actual syscalls used by application
  - Deploy Seccomp profile with `defaultAction: SCMP_ACT_LOG`
  - Run production load for hours/days
  - Analyze audit logs to identify required syscalls
- Phase 2: Create permissive Seccomp profile allowing identified syscalls only
  - Test in staging with `defaultAction: SCMP_ACT_ERRNO`
  - Run integration tests, load tests
- Phase 3: Canary deployment in production with Seccomp
  - Monitor for EPERM errors (syscall denied)
  - Gradually increase percent of pods using Seccomp
  - Fallback strategy: revert deployment if errors spike
- Ongoing: Tighten rules as application functionality stabilizes

### Rolling Updates & Rollbacks (3 questions)

**Q7: A rolling update of a StatefulSet is hung: 2 of 5 replicas updated, 3 waiting. A pod disruption budget specifies `minAvailable: 3`. Why is the update blocked, and how do you recover?**

Expected Answer:
- StatefulSet updates pods sequentially by ordinal (unlike Deployment)
- Update waits for pod-0 → pod-2 to become ready
- PDB `minAvailable: 3` prevents 2 more pods from being updated simultaneously
- At point: 3 old ready + 2 updating = 5 total, but only 3 of those are "available" (old ones)
- Updating would drop available to 2, violating PDB
- Solution: Either:
  1. Update PDB to `maxUnavailable: 2` (temporarily relax availability)
  2. Manually delete pod to trigger replacement
  3. Ensure update wait period covers pod startup time
- Advanced: Explain why PDB + sequential updates can deadlock; recommend relaxing during rollouts

**Q8: You implemented a canary deployment that rolled back after 10%, but some traffic still hit the old version during rollout. Why did traffic shift occur before canary completed analysis?**

Expected Answer:
- Canary process: 1) Scale new version, 2) Shift traffic, 3) Monitor metrics, 4) Decide rollback
- If monitoring interval is long (e.g., 1-minute), traffic shifted immediately to new version
- Metrics collected over 1 minute, then rollback decision made (already sent bad traffic)
- Timeline: Minute 0 shift traffic → Minute 1 rollback (too late)
- Solution: Increase `threshold` and `maxWeight` for gradual shift
  - `maxWeight: 10` ensures at most 10% traffic before next analysis
  - `threshold: 10` requires 10 successful metrics before advancing
  - `interval: 10s` checks every 10 seconds (tighter feedback loop)
- Advanced: Implement immediate rollback on first error using custom Prometheus alert rules

**Q9: After rolling back a deployment from v2 to v1, users report persistent session loss. v1's pod logs show connection errors to a new database schema (deployed in v2). Why is rollback insufficient, and what's the correct sequence?**

Expected Answer:
- Database schema changes are often not backward-compatible
- Rolling back only the application leaves new schema in place
- v1 application can't read new schema → connection failures
- Correct sequence:
  1. Plan reversibility during schema design: support both old + new schema simultaneously
  2. On rollback: Schema stays new (v1 reads from new schema), OR
  3. Reverse schema migration explicitly before application rollback
- Prevention: Use blue-green deployments for schema changes
  - Deploy new schema in separate database
  - Gradually shift traffic
  - Keep old database until rollback window closes
- Post-incident: Infrastructure-as-code schema migrations with rollback scripts

### Autoscaling (3 questions)

**Q10: HPA with `targetCPUUtilizationPercentage: 70%` shows pods using only 50% actual CPU, but HPA already scaled to `maxReplicas: 100`. Where is the request misconfiguration, and how do you fix it?**

Expected Answer:
- HPA calculates: `current CPU usage / requested CPU = 50% / requests`
- If `targetCPU: 70%` but actual CPU is 50%, HPA has already scaled up excessively
- Problem diagnosis: `requested CPU too low`
  - If pod requests 100m but uses 50m: 50/100 = 50% → Below target, scale up
  - Keep scaling until 70m actual / 100m requested = 70% target met
  - But 50m actual on 100m requested wastes 50m per pod
- Root cause: Requests don't match actual usage (VPA would help here)
- Fix: Use VPA to right-size requests based on actual usage, or manually increase requests to match actual CPU
  - Example: If actual CPU is 50m, set request to 70m (target will trigger at 50m actual)
- Advanced: Explain HPA's target utilization calculation and how it can cause waste with misaligned requests

**Q11: You're using HPA with custom metrics from application-instrumented Prometheus. Metrics are missing for 30 seconds during pod restarts. How does HPA react, and what problems can this cause?**

Expected Answer:
- HPA's `--horizontal-pod-autoscaler-sync-period` (default 30s) polls metrics
- If metrics missing: HPA can't calculate utilization → doesn't scale
- Cascading effect: Without scaling response, more pods restart → more missing metrics
- Or: HPA treats missing metrics as zero → scale-down when shouldn't
- Recovery: HPA falls back to another metric if available (multi-metric HPA)
- Solution: Add metric collection redundancy
  1. Add healthcheck to ensure pod delays reporting startup (don't report until ready)
  2. Use `scaleTargetRef` reliability: monitor multiple metrics (CPU + custom)
  3. Increase `scaleDownStabilization: 300s` to prevent thrashing during metric gaps
  4. Monitoring: Alert if HPA stuck unable to query metrics
- Advanced: Explain how metric-less gaps cause oscillation in workloads with high churn

**Q12: Cluster Autoscaler shows "scale-up blocked: node capacity exceeded" but your cloud account quota for instances is 100 and you're only using 20. What's preventing scale-up?**

Expected Answer:
- Queue diagnostics: Could be multiple issues
  1. **Resource quota on cluster**: Kubernetes ResourceQuota blocking pod scheduling
  2. **PVCs/EBS constraints**: Persistent volumes can't attach to new nodes (zone affinity, disk quota)
  3. **Cluster Autoscaler config**: `maxTotalNodes` or `maxNodeGroupSize` limiting the cluster
  4. **Node group capacity**: ASG/MIG has lower limit than cloud quota
  5. **Subnet exhaustion**: Not enough IP addresses in VPC subnets for new nodes
  6. **IAM permissions**: Cluster Autoscaler lacks permission to provision new instances
- Debugging:
  ```bash
  kubectl logs -n kube-system deployment/cluster-autoscaler | grep "scale-up blocked"
  # Should indicate specific reason (check logs for node group limits, quota)
  kubectl top nodes  # See current node usage
  kubectl describe nodes  # Check node allocatable capacity
  ```
- Fix: Identify bottleneck (usually subnet IPs or ASG limits), resolve, autoscaling resumes
- Advanced: Multi-region autoscaling, cost-aware scaling prioritizing cheaper node types

---

**Document Version**: 1.0 (Kubernetes 1.28+)  
**Last Updated**: March 2026  
**Target Audience**: Senior DevOps Engineers (5-10+ years)  
**Prerequisites**: Kubernetes fundamentals, container networking, resource management basics

---

