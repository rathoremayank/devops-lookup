# OpenShift Advanced Topics - Deep Dive Study Guide

**Level:** Senior DevOps Engineers (5-10+ years experience)  
**Continuation of:** 1_OpenShift_Architecture_Installation_Networking_StudyGuide.md  
**Focus:** Production-grade deep dives with practical operational patterns

---

# PART 2: OPENSHIFT ARCHITECTURE DEEP DIVE

## 1. OpenShift Architecture

### 1.1 OpenShift Components Overview

#### Textual Deep Dive

**Internal Working Mechanism:**

OpenShift extends Kubernetes by adding a layer of enterprise-grade components that provide developer-focused tooling, integrated container registry, build automation, and deployment orchestration. The architecture operates in concentric layers:

**Layer 1: Kubernetes Core (Inherited)**
```
Kubernetes components provide foundation:
• etcd: Distributed key-value store for cluster state
• API Server: RESTful interface for cluster state management
• Scheduler: Pod placement algorithm based on resource requests, constraints
• Controller Manager: Reconciliation loops ensuring desired state
• Kubelet: Node agent managing container lifecycle on each node
```

**Layer 2: OpenShift Operators (Extensibility)**
```
Kubernetes Custom Resources + Controllers define custom application types:
• Cluster Version Operator: Manages OpenShift component versions, upgrades
• Machine Config Operator: Manages node configuration at scale
• Network Operator: Manages SDN deployment and configuration
• Storage Operator: Manages storage plugin lifecycle
• Monitoring Operator: Manages Prometheus/AlertManager deployment
```

**Layer 3: Developer Experience (Productivity)**
```
OpenShift-specific components ease deployment:
• BuildConfig: Automated container image building from source (S2I, Docker, Custom)
• ImageStream: Container image versioning and tagging abstraction
• Route: Layer 7 load balancing with TLS termination, traffic splitting
• Template: Parameterized manifests enabling environment specialization
```

**Layer 4: Security & Compliance (Hardening)**
```
Enhanced security above Kubernetes defaults:
• Security Context Constraints (SCCs): Pod runtime security policies
• RBAC: Fine-grained permission model integrated with OAuth
• Pod Security Standards: Admission controller enforcing security boundaries
• Audit: Comprehensive API audit logging for compliance
```

**Architecture Role:**

OpenShift acts as the **abstraction layer** between infrastructure (IaaS: AWS, Azure, on-premise) and applications. The relationship:

```
┌─────────────────────────────────────────────────────┐
│         Application Teams                           │
│  (Deploy via `oc deploy`, S2I, CI/CD pipelines)    │
└────────────────────────┬────────────────────────────┘
                         │
        ┌────────────────▼────────────────┐
        │   OpenShift Platform            │
        │ (Projects, RBAC, Network, etc.) │
        └────────────────┬────────────────┘
                         │
        ┌────────────────▼────────────────┐
        │   Kubernetes Core               │
        │ (Scheduling, etcd, control)     │
        └────────────────┬────────────────┘
                         │
        ┌────────────────▼────────────────┐
        │   Infrastructure Layer          │
        │ (IaaS: AWS EC2, Azure VMs, etc.)│
        └────────────────────────────────┘

Application teams interact with OpenShift API.
OpenShift translates to Kubernetes objects.
Kubernetes schedules containers on infrastructure.
```

**Production Usage Patterns:**

**Pattern 1: Multi-Tenant SaaS Platform**
```
Organization: SaaS vendor serving 100+ customers

Configuration:
├── Each customer = separate project (namespace)
├── Project quotas: CPU/memory limits per customer
├── Project team: customer's DevOps team
├── Network policies: Customer A can't reach Customer B
├── Storage: Separate PVCs per customer (data isolation)

Benefits:
• Cost chargeback per customer
• Blast radius: one customer's outage doesn't affect others
• Security: Customer data isolated via network policies + RBAC
• Compliance: Customer audits don't expose other customers' data
```

**Pattern 2: CI/CD Automation for Rapid Deployments**
```
Organization: FinTech trading platform, 200+ deployments/day

Workflow:
1. Developer commits code to Git
2. Webhook triggers OpenShift build (S2I or Docker build)
3. Image scanned for vulnerabilities
4. If passed, pushed to internal registry
5. ImageStream tag updated → deployment automatically updated
6. Canary route sends 5% traffic to new version
7. Monitoring detects issues → automated rollback
8. On success, route shifts 100% traffic to new version

Result: Fully automated deployment, human approval optional, rollback in seconds
```

**Pattern 3: Hybrid Multi-Cloud Deployments**
```
Organization: Enterprise with on-premise + cloud presence

Architecture:
├── On-Premise OpenShift: payment processing, legacy systems
├── AWS OpenShift: API layer, batch processing
├── Azure OpenShift: customer-facing web services
├── Unified management: ArgoCD pulls from Git, deploys to all clusters
├── Cross-cluster DNS: Service mesh routes traffic efficiently

Benefits:
• Consistent platform everywhere (same deployment, same RBAC)
• Workload mobility: can move pods between clusters
• Disaster recovery: failover to another cluster automatic via DNS
```

**DevOps Best Practices:**

**1. Maintain Cluster Configuration in Git (GitOps)**
```
Repository structure:
├── /clusters
│   ├── prod/
│   │   ├── kustomization.yaml
│   │   ├── cluster-config/
│   │   │   ├── rbac.yaml
│   │   │   ├── network-policies.yaml
│   │   │   └── storage-classes.yaml
│   │   └── namespaces/
│   │       ├── payments-prod/kustomization.yaml
│   │       ├── api-services-prod/kustomization.yaml
│   │       └── shared-services/kustomization.yaml
│   └── staging/
│       └── [similar structure]

Workflow:
Dev → Git PR → Peer review → Merge → ArgoCD detects change → Auto-deploy
Rollback: Revert Git commit → ArgoCD rolls back cluster

Result: All cluster changes auditable, reversible, peer-reviewed
```

**2. Monitor Component Health via Cluster Health Dashboard**
```
Production indicators:
• Control plane: etcd quorum status, API latency (p99 < 100ms target)
• Worker nodes: Ready/NotReady status, disk pressure, memory pressure
• Network: SDN pod network availability
• Storage: Storage class readiness, provisioner health
• Operators: Cluster Version Operator health, MachineConfigOperator health

Alerting thresholds:
- API latency p99 > 200ms → investigate load, etcd performance
- etcd < 3 members → manual intervention required (quorum lost)
- > 20% nodes NotReady → drain nodes, investigate
- Storage provisioner unhealthy → new PVCs will fail
```

**3. Implement Observability for All Components**
```
Metrics collection from:
• API Server: request latency, error rates, admission webhook latency
• etcd: commit duration, disk IO, memory usage
• Scheduler: scheduling latency, binding latency
• Kubelet: pod creation time, image pull duration
• Storage: provisioning time, mount/unmount operations

SLOs derived from metrics:
- API latency p99 ≤ 100ms
- etcd commit duration p99 ≤ 50ms
- Scheduler binding latency p99 ≤ 1s
- Pod creation to running ≤ 10s (p99)

Alerting:
- SLO breach → page DevOps team
- Trend analysis: degradation within 1 week → proactive upgrade
```

**Common Pitfalls:**

**Pitfall 1: Undersized etcd Storage**
```
❌ Problem:
• etcd stores all cluster state (pods, services, configs)
• Default 2GB disk limit in some deployments
• As cluster grows: 10,000 pods × 5KB avg = 50MB+ state
• Eventually etcd disk fills → writes blocked → cluster broken

✓ Solution:
• Pre-size etcd storage: 2GB minimum (better: 25GB for 10K pods)
• Monitor etcd disk: alert at 80% capacity
• Regular etcd compaction (removes old revisions): `etcdctl compact`
• Backup etcd before major cluster operations
```

**Pitfall 2: Single Master Cluster in Production**
```
❌ Problem:
• Single master = single point of failure
• Master node failure = cluster unavailable
• Upgrades require downtime

✓ Solution:
• Minimum 3 masters (recommended 5 for >1000 nodes)
• Load balancer in front of API endpoints
• etcd: 3-member quorum (survives 1 member failure)
• Test failure scenarios in staging
```

**Pitfall 3: No Pod Disruption Budgets (PDBs)**
```
❌ Problem:
• During cluster upgrades: nodes drained, pods evicted
• Without PDB: all replicas evicted simultaneously
• Brief period where no pods running = outage

✓ Solution:
• Every production deployment must have PDB
• minAvailable = 50% (or calculate based on SLO)
• Test: manually drain node, verify app availability maintained
```

---

### 1.2 OpenShift Control Plane Deep Dive

#### Textual Deep Dive

**Internal Working Mechanism:**

The control plane is the **decision-making center** of the cluster. It receives requests, stores state, makes scheduling decisions, and monitors cluster health. The interaction flow:

```
User → oc command → API Server (REST endpoint)
        ↓
    Authentication (OAuth token, certificates)
        ↓
    Authorization (RBAC: is user allowed?)
        ↓
    Admission Control (webhook validation: is resource valid?)
        ↓
    Persist to etcd (stored on disk, replicated to other masters)
        ↓
    Return response to user
        ↓
    Controllers watch for changes
        ↓
    Scheduler places pods on nodes
        ↓
    Kubelet (on nodes) acts on pod assignments
```

**Control Plane Components:**

| Component | Role | Failure Impact |
|-----------|------|-----------------|
| **API Server** | RESTful interface to cluster state; handles all user requests | Cluster unresponsive; can't deploy, delete, or update resources |
| **etcd** | Distributed key-value store; single source of truth for cluster state | Cluster state corrupted or lost; cluster becomes brain-dead |
| **Scheduler** | Algorithm assigns pods to nodes based on resources/constraints | New pods can't be scheduled; stuck in Pending state |
| **Controller Manager** | Runs controllers (Deployment, StatefulSet, DaemonSet) ensuring desired state | Deployments don't scale; pods don't recover on failure |
| **Cloud Controller Manager** | Integrates with cloud provider (AWS, Azure) for LBs, storage | Can't create cloud resources; LoadBalancer services hang |

**etcd (Critical Component):**

etcd is the **single source of truth**. If etcd fails, cluster becomes read-only (queries work, writes blocked). etcd architecture:

```
┌─────────────────────────────────────────┐
│       OpenShift Cluster (3 Masters)     │
├──────────┬──────────────┬───────────────┤
│ Master-1 │  Master-2    │  Master-3     │
├──────────┼──────────────┼───────────────┤
│ etcd:2379│ etcd:2379    │ etcd:2379     │
│ (member) │ (member)     │ (member)      │
└────┬─────┴───┬──────────┴────┬──────────┘
     │         │               │
     └─────────┼───────────────┘
               │
    Raft Consensus Protocol:
    • All writes replicated to 3 members
    • Quorum required for writes: need 2/3 members alive
    • If 1 member fails: 2/3 quorum maintained ✓
    • If 2 members fail: 1/3 quorum lost ✗ (cluster read-only)
```

**Architecture Role:**

The control plane enables **declarative infrastructure**:

1. Developer declares desired state (Deployment YAML)
2. Control plane accepts, stores in etcd
3. Controllers monitor and reconcile until state achieved
4. Enables self-healing (pod crashes → controller restarts)
5. Enables automatic scaling (pods needed → scheduler places new ones)

**Production Usage Patterns:**

**Pattern 1: High Availability Control Plane**
```
Deployment: 5-master cluster (across 3 availability zones)

Master topology:
├── Master-1: us-east-1a (zone 1)
├── Master-2: us-east-1b (zone 2)
├── Master-3: us-east-1c (zone 3)
├── Master-4: us-east-1a (zone 1) - extra capacity
└── Master-5: us-east-1b (zone 2) - extra capacity

Quorum analysis:
• Zone 1 disaster: 2 masters down, 3 online → quorum maintained ✓
• Zone 2 disaster: 2 masters down, 3 online → quorum maintained ✓
• Zone 3 disaster: 1 master down, 4 online → quorum maintained ✓

Benefit: Cluster survives any single zone failure
```

**Pattern 2: Control Plane Monitoring & Metrics**
```
Alerting rules:
• etcd leader changes > 5 in 1 hour → leader flapping indicator
• etcd fsync duration p99 > 50ms → disk IO bottleneck
• API server request latency p99 > 100ms → load issue
• Admission webhook latency > 10s → webhook misconfigured

Diagnostics:
```bash
# Check etcd health
etcdctl endpoint health

# Check etcd members
etcdctl member list

# Check etcd db size (disk usage)
etcdctl alarm list
```
```

**DevOps Best Practices:**

**1. Regular etcd Backups**
```bash
# Backup etcd (must run on master with cert access)
#!/bin/bash
BACKUP_DIR="/root/etcd-backups"
sudo mkdir -p $BACKUP_DIR

# Using OpenShift cluster-backup command (v4.6+)
sudo ./cluster-backup.sh /root/etcd-backups

# Verify backup
ls -lh /root/etcd-backups/*.db

# Test restore in staging cluster (never skip this step!)
./cluster-restore.sh /root/etcd-backups/snapshot_UTC_*

# Automated daily backup via CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: openshift-etcd
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: quay.io/openshift-release-dev/ocp-v4.0:cluster-backup
            command:
            - /bin/bash
            - -c
            - /usr/local/bin/cluster-backup.sh /backups
            volumeMounts:
            - name: etcd-certs
              mountPath: /etc/kubernetes/static-pod-resources/etcd-certs
          volumes:
          - name: etcd-certs
            hostPath:
              path: /etc/kubernetes/static-pod-resources/etcd-certs
```

**2. Monitor Control Plane Components via Prometheus**
```yaml
# Query critical metrics
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: control-plane-alerts
spec:
  groups:
  - name: control.plane.rules
    rules:
    # Alert: etcd too many leader changes
    - alert: EtcdTooManyLeaderChanges
      expr: rate(etcd_server_leader_changes_total[1h]) > 3
      for: 5m
      annotations:
        summary: "etcd leader flapping detected"
        
    # Alert: API server latency
    - alert: APIServerHighLatency
      expr: histogram_quantile(0.99, rate(apiserver_request_duration_seconds_bucket[5m])) > 0.1
      for: 5m
      annotations:
        summary: "API server p99 latency > 100ms"
        
    # Alert: etcd db size too large
    - alert: EtcdDbSizeTooLarge
      expr: etcd_debugging_store_compact_total == 0 and etcd_disk_backend_bytes > 5e9
      for: 10m
      annotations:
        summary: "etcd database > 5GB, compaction recommended"
```

**Common Pitfalls:**

**Pitfall 1: Control Plane on Compute Nodes (Wrong Topology)**
```
❌ Problem:
Master-worker hybrid node:
• Control plane components (etcd, API server) compete for resources with app workloads
• App spike: CPU/memory consumed by app → control plane latency increases
• Can't upgrade: draining node evicts etcd leader → cluster unavailable

✓ Solution:
• Master nodes: dedicated, run only control plane
• Infra nodes: dedicated, run infrastructure (monitoring, logging, routing)
• Compute nodes: dedicated, run app workloads
• Separation prevents noisy-neighbor issues
```

**Pitfall 2: Insufficient etcd Storage Pre-allocation**
```
❌ Problem:
Default 2GB etcd storage in some environments.
Large clusters (10K+ pods) exceed this allocation → etcd fails.

✓ Solution:
• Pre-size etcd: 25-50GB for large clusters
• Monitor: `etcdctl member list; du -sh /var/data/etcd`
• Alert at 80% capacity
• Maintenance window: grow disk, restart etcd
```

**Pitfall 3: No Admission Control Webhook Timeout**
```
❌ Problem:
Admission webhook fails to respond within minutes.
All pod creation requests hang → cluster appears broken.

✓ Solution:
# Set timeoutSeconds in webhook config
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: custom-validation
webhooks:
- name: validation.example.com
  timeoutSeconds: 2        # Fail fast, don't wait forever
  failurePolicy: Fail      # Reject pod if webhook times out
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
```

---

### 1.3 OpenShift Worker Nodes Deep Dive

#### Textual Deep Dive

**Internal Working Mechanism:**

Worker nodes are the **execution layer** where application containers actually run. Each node runs:

```
Node (VM or physical machine)
├── OS: RHCOS (Red Hat CoreOS) - immutable, minimal footprint
├── Container Runtime: CRI-O or containerd - manages container lifecycle
├── Kubelet: Node agent communicating with control plane
├── kube-proxy: Network proxy managing service networking
└── Plugins: CNI (networking), CSI (storage), device plugins (GPU)
```

**Kubelet Lifecycle Management:**

Kubelet continuously monitors pod state and ensures containers are running:

```
1. Kubelet watches API server for pod assignments
2. Pod scheduled on node → API server assigns to kubelet
3. Kubelet pulls container image from registry
4. Kubelet creates container via CRI runtime
5. Container processes start, Kubelet reports status
6. If process exits → Kubelet restarts (restart policy)
7. If pod deleted → Kubelet stops and removes container
8. Kubelet periodically runs probes (liveness, readiness)
```

**Node Resource Allocation:**

Not all node resources available to pods:

```
Node: 16 CPU, 64 GB RAM (total)

├── System reserved (kubelet, CRI runtime, OS):
│   ├── CPU: 500m
│   ├── Memory: 500Mi
│   
├── Pod Eviction Threshold (kubelet protects node):
│   ├── If memory < 5% available: evict pods (highest mem consumers first)
│   ├── If disk < 5% available: evict pods
│   
└── Allocatable (available for pods):
    ├── CPU: 15.5
    ├── Memory: 62 GB
```

**Architecture Role:**

Worker nodes provide the **compute, storage, and network** infrastructure. The node's responsibilities:

1. **Compute**: Run containers at requested CPU/memory
2. **Storage**: Mount PVs and provide ephemeral storage
3. **Networking**: Route traffic to pods via kube-proxy
4. **Monitoring**: Report node and pod health

**Production Usage Patterns:**

**Pattern 1: Heterogeneous Node Types**
```
Cluster topology for specialized workloads:

├── Compute Nodes (General purpose apps):
│   ├── Instance type: m5.2xlarge (8 CPU, 32GB RAM)
│   ├── Labels: node-type=compute
│   ├── Workloads: API servers, web services
│   ├── Scaling: Auto-scale 5-50 based on load
│   
├── Memory-Optimized Nodes (Caching, in-memory DBs):
│   ├── Instance type: r5.4xlarge (16 CPU, 128GB RAM)
│   ├── Labels: node-type=memory-optimized
│   ├── Workloads: Redis, Memcached, cache layers
│   ├── Scaling: Fixed 3 nodes (min for HA)
│   
├── GPU Nodes (ML/analytics workloads):
│   ├── Instance type: g4dn.12xlarge (4 NVIDIA GPUs, 48GB RAM)
│   ├── Labels: accelerator=nvidia-gpu
│   ├── Workloads: TensorFlow training, inference
│   ├── Scaling: Fixed 2 nodes (expensive, minimal demand)
│   
└── NVMe Optimized Nodes (Database nodes):
    ├── Instance type: i3.4xlarge (NVMe SSD storage)
    ├── Labels: storage-optimized=true
    ├── Workloads: Cassandra, MongoDB, time-series DBs
    ├── Scaling: Fixed 6 nodes (3-way replication)
```

**Pattern 2: Worker Node Health Monitoring**
```
Critical metrics per node:

Node readiness:
• Ready: Node healthy, accepting pods
• NotReady: Network/kubelet/CRI issue
• Unknown: No heartbeat from node > 5 minutes

Capacity vs. allocatable:
αν node has:
• 16 CPU total capacity
• 1 CPU reserved (system)
• If pods request 15.5 CPU: node full, new pods pending
• Alert if > 80% allocated

Disk pressure:
• Alert if root filesystem > 85% full
• Alert if pod ephemeral storage > 80% full

Memory pressure:
• Node evicts pods when memory pressure critical (< 5% available)
• Need high-memory workloads to request memory accurately

Pod eviction scenario:
Node memory: 64GB total
  │
  ├── System reserved: 1GB (OS, kubelet, CRI)
  ├── Pod A (app): 30GB (requests 25GB)
  ├── Pod B (app): 30GB (requests 25GB)
  └── Eviction threshold: 5% = 3.2GB
  
Result: Only 1GB free, < 3.2GB threshold
• Node signals "MemoryPressure"
• Kubelet sorts pods by (requests - actual usage)
• Highest memory consumer evicted first (Pod B, 30GB actual)
• After eviction: ~30GB free, pressure relieved
• Scheduler reschedules Pod B to another node

Query node status:
$ oc describe node worker-1
Status:
  Conditions:
    Type             Status LastHeartbeat         Reason
    Ready            True   Wed, 01 Jan 2025      kubelet is posting ready status
    MemoryPressure   False  Wed, 01 Jan 2025      kubelet has sufficient memory available
    DiskPressure     False  Wed, 01 Jan 2025      kubelet has sufficient disk space available
    PIDPressure      False  Wed, 01 Jan 2025      kubelet has sufficient PID available
  Allocatable:
    cpu:                15500m
    memory:             62Gi
    ephemeral-storage:  1000Gi
```

**DevOps Best Practices:**

**1. Pre-size Nodes for Workload Isolation**
```yaml
# Taints prevent pod placement; tolerations allow exceptions
apiVersion: v1
kind: Node
metadata:
  name: gpu-node-1
spec:
  taints:
  - key: accelerator
    value: nvidia-gpu
    effect: NoSchedule      # Pod must tolerate or won't be scheduled

---
# GPU workload pod
apiVersion: v1
kind: Pod
metadata:
  name: ml-training
spec:
  tolerations:
  - key: accelerator
    operator: Equal
    value: nvidia-gpu
    effect: NoSchedule
  containers:
  - name: trainer
    image: tensorflow/tensorflow:latest-gpu
    resources:
      requests:
        nvidia.com/gpu: 1    # Request GPU
  nodeSelector:
    accelerator: nvidia-gpu  # Only schedule on GPU nodes
```

**2. Monitor Node Performance Metrics**
```bash
# Check node CPU/memory allocation
oc describe node worker-1 | grep -A 10 "Allocated resources"

# Monitor real-time node metrics
watch -n 2 'oc describe node worker-1 | tail -20'

# Identify problematic nodes
oc get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEM:.status.allocatable.memory,PODS:.status.allocatable.pods

# Check for node pressure conditions
oc get nodes -o json | jq '.items[] | {name: .metadata.name, conditions: .status.conditions[]}'
```

**3. Graceful Node Draining for Maintenance**
```bash
#!/bin/bash
NODE=$1

# Cordon: prevent new pods from being scheduled
oc adm cordon $NODE

# Drain: evict existing pods (except daemonsets/static pods)
oc adm drain $NODE \
  --delete-emptydir-data \
  --ignore-daemonsets \
  --ignore-daemonsets \
  --grace-period=300

# Perform maintenance (update kernel, patch OS, etc.)
sudo systemctl reboot

# Wait for node to rejoin
while ! oc get node $NODE | grep -q "Ready"; do
  echo "Waiting for $NODE to be ready..."
  sleep 10
done

# Uncordon: resume normal scheduling
oc adm uncordon $NODE
```

**Common Pitfalls:**

**Pitfall 1: Node Resource Starvation**
```
❌ Problem:
Pods request 15 CPU on 16-CPU node.
No reserved capacity for system processes.
Result: Node becomes unresponsive → cluster control loop delayed

✓ Solution:
# Configure systemReserved (kubelet config)
apiVersion: kubeadm.k8s.io/v1beta2
kind: KubeletConfiguration
systemReserved:
  cpu: "1"           # Reserve 1 CPU for OS/kubelet
  memory: "1Gi"
  ephemeral-storage: "10Gi"
kubeReserved:
  cpu: "500m"
  memory: "500Mi"
```

**Pitfall 2: Nodes NotReady After Cluster Upgrade**
```
❌ Problem:
Upgrade completes but kubelet can't restart (old config incompatible).
Nodes stay NotReady, pods can't be rescheduled.

✓ Solution:
# Pre-upgrade: drain all pods
oc adm drain $NODE --ignore-daemonsets

# After upgrade: verify kubelet running
sudo systemctl status kubelet

# If failed: check logs
sudo journalctl -u kubelet -n 100 --no-pager
```

---

### 1.4 OpenShift API Server Deep Dive

#### Textual Deep Dive

**Internal Working Mechanism:**

The API Server is the **REST gateway** for all cluster operations. Every `oc` command, every deployment update, every secret read goes through the API Server. The request flow:

```
User: oc apply -f deployment.yaml
  │
  ├─→ API Server validates HTTPS certificate
  ├─→ Authentication: extract user identity from token/cert
  ├─→ Authorization: RBAC check - does user have permission?
  ├─→ Admission: webhook validation - is YAML valid?
  ├─→ Persist: etcd stores manifest
  ├─→ Watch: controllers notified of change
  └─→ Response: API returns success/error to user
```

**API Server Load:**

The API Server handles multiple request types:

```
Request Types:
├── Get/List: queries (read-only, don't modify state)
├── Watch: long-lived connections streaming state changes (controllers use this)
├── Create/Update/Patch: writes to etcd (must be serialized for consistency)
├── Delete: removal (triggers garbage collection)
└── Exec/Log/Port-forward: streaming (ssh-like interactions)
```

**Production Metrics:**

```
API Server metrics to monitor:
• Request latency (p50, p99, p999)
• Request rate (requests/sec)
• Error rate (4xx, 5xx responses)
• Etcd write latency (storage.etcd.io_duration_seconds)
• Admission webhook latency (admission process time)
• Certificate expiry (TLS cert expiration warnings)

Typical SLO: p99 latency < 100ms (Get/List), < 1s (Create/Update)
```

**Architecture Role:**

API Server enforces the **declarative model**. Every operation is a transaction:

1. Request received
2. State modification proposed (YAML applied)
3. etcd updated (atomic operation)
4. Controllers react to change
5. New state propagates through cluster

**Production Usage Patterns:**

**Pattern 1: High API Load from Monitoring Stack**
```
Scenario: 1000-pod cluster, hundreds of monitoring agents

Problem:
Each monitoring agent queries API every 30 seconds for pod metrics.
1000 pods / 30 sec = ~33 requests/sec from monitoring alone.
Multiplied by 10 metrics agents = 330 requests/sec.
API Server p99 latency increases > 1s → monitoring delayed → alerts missed

Solution:
Use metrics aggregation servers instead of direct API queries.
├── kubelet exposes /metrics endpoint (metrics directly from node)
├── Prometheus scrapes kubelet, not API Server
├── API Server query load drops 90%
└── Monitoring becomes faster and more scalable
```

**Pattern 2: etcd Quota Exhaustion vs. API Load**
```
Scenario: Development team creates 50K temporary pods daily

Monitoring:
etcd database grows: 10MB + 50K pods × 5KB = 260MB daily
After 30 days: 7.8GB database size
After 60 days: 15.6GB (etcd quota typically 8-10GB)

Failure: etcd quota exceeded → all writes blocked → cluster broken

Solution:
1. Implement pod garbage collection
2. Set default TTL for temporary pods
3. Alert at 80% etcd database size
4. Trigger compaction when exceeded threshold
```

**DevOps Best Practices:**

**1. Monitor API Server Request Latency**
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: apiserver-rules
spec:
  groups:
  - name: apiserver.rules
    interval: 30s
    rules:
    # Alert: API latency spike
    - alert: APIServerHighLatency
      expr: |
        histogram_quantile(0.99, 
          sum(rate(apiserver_request_duration_seconds_bucket[5m])) 
          by (le, verb)
        ) > 0.1
      for: 5m
      annotations:
        summary: "API Server {{ $labels.verb }} latency > 100ms"
        
    # Alert: Etcd write latency
    - alert: EtcdHighWriteLatency
      expr: |
        histogram_quantile(0.99,
          rate(etcd_disk_backend_commit_duration_seconds_bucket[5m])
        ) > 0.05
      for: 5m
      annotations:
        summary: "Etcd commit duration > 50ms"
        
    # Alert: High admission webhook latency
    - alert: AdmissionWebhookHighLatency
      expr: |
        histogram_quantile(0.99,
          sum(rate(apiserver_admission_webhook_admission_duration_seconds_bucket[5m]))
          by (le, name)
        ) > 5
      for: 5m
      annotations:
        summary: "Webhook {{ $labels.name }} latency > 5s"
```

**2. Rate Limiting API Requests**
```yaml
# MaxInFlightRequests prevents API overload
# APIServer config on control plane
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
apiServer:
  extraArgs:
    max-requests-inflight: "1500"      # Concurrent requests
    max-mutating-requests-inflight: "500"  # Concurrent writes
    # If exceeded, API returns 429 (Too Many Requests)
```

**3. Implement Priority & Fairness**
```yaml
# User A (high priority): guaranteed 50 requests/sec
# User B (normal priority): best effort
apiVersion: flowcontrol.apiserver.k8s.io/v1beta1
kind: FlowSchema
metadata:
  name: high-priority
spec:
  priorityLevelConfiguration:
    name: high-priority-pl
  matchingPrecedence: 1
  rules:
  - subjects:
    - kind: ServiceAccount
      serviceAccount:
        name: critical-service
        namespace: prod
    resourceRules:
    - verbs: ["*"]
      apiGroups: ["*"]
      resources: ["*"]

---
apiVersion: flowcontrol.apiserver.k8s.io/v1beta1
kind: PriorityLevelConfiguration
metadata:
  name: high-priority-pl
spec:
  type: Guaranteed
  guaranteed:
    concurrencyShares: 100      # Relative weight
    limitResponse:
      type: Queue
      queuing:
        queues: 5
        handSize: 10
        queueLengthLimit: 100
```

**Common Pitfalls:**

**Pitfall 1: No API Audit Logging for Compliance**
```
❌ Problem:
Regulatory audit asks: "Who created the production database?"
Without audit logs: no answer = compliance violation

✓ Solution:
# Enable audit logging
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Log everything at verbose level
- level: RequestResponse
  omitStages:
  - RequestReceived
  
# Log secret creation
- level: RequestResponse
  verbs: ["create"]
  resources:
  - group: ""
    resources: ["secrets"]
    
# Redirect audit logs to external logging system
# Check: /etc/kubernetes/audit/audit.log (grows rapidly!)
```

**Pitfall 2: Certificate Expiration Causing API Outages**
```
❌ Problem:
API Server certificate expires → new connections fail → cluster unavailable.

✓ Solution:
# Alert on certificate expiry
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cert-expiry
spec:
  groups:
  - name: cert.rules
    rules:
    - alert: KubernetesServerCertificateExpirySoon
      expr: kubelet_certificate_manager_server_ttl_seconds < 7 * 24 * 3600
      annotations:
        summary: "API Server cert expires in {{ $value}} days"
        
# Rotate certificates before expiry (within 1 year)
oc get secret apiserver --namespace openshift-apiserver -o json | jq '.data.tls\.crt'
# Decode and check expiry date
```

---

### 1.5-1.8 (Scheduler, Controller Manager, etcd, Real-world Examples)

#### 1.5 Scheduler Deep Dive - Textual

**Internal Working Mechanism:**

The Scheduler is the **matchmaker** between pods and nodes. When a pod is created with no node assignment, the scheduler determines which node is the best fit.

```
Scheduling algorithm:
1. Filter: Which nodes CAN run this pod?
   • Enough CPU/memory? (resource requests)
   • Node not cordoned? (cordon prevents scheduling)
   • Pod tolerates node taints? (no taint conflicts)
   • Affinity rules satisfied? (preferred node locations)
   
2. Score: Which node is BEST?
   • Spread pods across nodes? (anti-affinity)
   • Prefer nodes with lower usage? (bin-packing)
   • Prefer nodes with existing pod from same app? (pod affinity)
   • Prefer specific zones? (topology spread)
   
3. Bind: Assign pod to chosen node
   • Kubelet on node notices assignment
   • Kubelet downloads image and starts container
```

**Scheduling Decisions:**

```yaml
# Bad scheduling: pod requests too much
apiVersion: v1
kind: Pod
metadata:
  name: greedy-app
spec:
  containers:
  - name: app
    image: myapp:v1
    resources:
      requests:
        cpu: "999"          # No node has 999 CPU!
        memory: "1000Gi"    # No node has 1000GB RAM!
        
Result: Pod stuck in Pending forever (scheduler can't find node)

# Good scheduling: realistic requests
apiVersion: v1
kind: Pod
metadata:
  name: realistic-app
spec:
  containers:
  - name: app
    image: myapp:v1
    resources:
      requests:
        cpu: "500m"         # 0.5 CPU
        memory: "256Mi"     # 256MB RAM
      limits:
        cpu: "1000m"        # Max 1 CPU
        memory: "512Mi"     # Max 512MB RAM
        
Result: Scheduled on node with available capacity
```

**Production Usage Patterns:**

**Pattern: Priority Pods & Pod Priority Classes**
```yaml
# High-priority workloads (payment processing) should schedule first
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: critical-production
value: 1000000                    # Highest priority
globalDefault: false
description: "Critical production payment processing"

---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: normal-production
value: 100000
description: "Normal production workloads"

---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch-processing
value: 1000
description: "Batch jobs, can be evicted"

---
# Pod using priority class
apiVersion: v1
kind: Pod
metadata:
  name: payment-processor
spec:
  priorityClassName: critical-production    # Highest priority
  containers:
  - name: processor
    image: payment-processor:v1
    
# When cluster full and new pod needs to schedule:
# Scheduler evicts batch-processing pods first
# Then normal-production pods
# Never evicts critical-production pods
```

**DevOps Best Practices:**

**1. Use Pod Affinity for Co-location**
```yaml
# Place api server pods near cache pods (reduce latency)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - cache
            topologyKey: kubernetes.io/hostname
            
# Result: Every API server pod scheduled on same node as cache pod
```

**Common Pitfalls:**

**Pitfall: Impossible Scheduling Constraints**
```
❌ Problem:
Pod A requires node label "gpu=true"
Pod B requires node label "gpu=false"
Pod C requires pod affinity with Pod A
Pod C also requires anti-affinity with Pod B
Result: Pod C impossible to schedule (contradictory constraints)

✓ Solution:
Use soft affinity constraints (preferred, not required)
and clear constraint naming to avoid conflicts
```

---

#### 1.6 Controller Manager & etcd Configuration

**Controller Manager** role: Runs controllers ensuring desired state.

**etcd Configuration** for production:

```yaml
# High-availability etcd configuration
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
etcd:
  local:
    dataDir: /var/lib/etcd
    extraArgs:
      # Increase election timeout for slow networks
      heartbeat-interval: "100"
      election-timeout: "1000"
      # Increase max size of etcd database
      quota-backend-bytes: "17179869184"  # 16GB
      # Enable auth for secure access
      client-auto-tls: "false"
      peer-auto-tls: "false"
      # Metrics endpoint for monitoring
      metrics: basic
```

---

### 1.8 Real-world Architecture Examples

#### Example 1: Financial Services OpenShift Deployment (High Security)

```
┌─────────────────────────────────────────────────────────────┐
│      Financial Services Trading Platform on OpenShift       │
└─────────────────────────────────────────────────────────────┘

Infrastructure:
├── Region: us-east-1 (primary)
├── Backup Region: us-west-2
├── Air-gapped: no internet access from cluster
├── Compliance: PCI-DSS level 1, SOX compliance

Cluster Architecture:
┌──────────────────────────────────┐
│  OpenShift Control Plane (HA)    │
│  5 Master nodes                  │
│  (3 across zones, 2 standby)     │
└────────────────────┬─────────────┘
                     │
    ┌────────────────┼────────────────┐
    │                │                │
┌───▼────┐      ┌───▼─────┐    ┌────▼──────┐
│ Infra  │      │ Compute  │    │   GPU     │
│ Nodes  │      │ Nodes    │    │  Nodes    │
│ (3x)   │      │ (50x)    │    │  (2x)     │
└────────┘      └──────────┘    └───────────┘

Infra Nodes (dedicated infrastructure):
├── Node Count: 3 (one per zone)
├── Instance Type: m5.xlarge
├── Workload: Monitoring, logging, routing
├── Network: Infra nodes have public endpoints

Compute Nodes (application workloads):
├── Node Count: 50 (auto-scaling min 30, max 100)
├── Instance Type: m5.2xlarge
├── Workload: Trading apps, data processing
├── Network: Private only, no internet access
├── Auto-scaling: Based on CPU > 75%

GPU Nodes (ML/analytics):
├── Node Count: 2 (fixed, expensive)
├── Instance Type: g4dn.12xlarge
├── Workload: Model training, backtests
├── Network: Private

Networking:
├── SDN: OVN-Kubernetes (default, recommended for security)
├── Service Mesh: OpenShift Service Mesh (Istio) for:
│   ├── mTLS between pods (encrypted service-to-service)
│   ├── Traffic management (canary deployments)
│   ├── Distributed tracing (compliance audits)
├── Network Policies: Strict (deny-all default)
│   ├── Payment service → Database only
│   ├── Risk service → Market data feed only
│   ├── Audit service → All services (read-only)
├── External: Proxy/bastion for external API access

Security:
├── Pod Security: Restricted (no root, read-only filesystem)
├── RBAC: Least privilege (traders can't modify infrastructure)
├── Secrets: Vault integration (automatic credential rotation)
├── Image Scanning: Scanning on build, rejecting CVE >= severity 7
├── Network Encryption: mTLS for all pod-to-pod communication
├── Audit: All API calls logged to Splunk

Storage:
├── Application Data: EBS gp3 (fast, encrypted)
├── Time-series Data: S3 (durable, archived)
├── Database: RDS (AWS managed, encrypted)
├── Backups: Velero automated snapshots (daily)

Observability:
├── Metrics: Prometheus (SLA metrics)
├── Logs: EFK stack (Elasticsearch, Fluent Bit, Kibana)
├── Tracing: Jaeger (distributed traces for audits)
├── SLO Dashboard: "99.99% transaction success"

Incident Response:
├── On-call: Red team rotates weekly
├── Alerting: Pagerduty escalation for critical alerts
├── Runbooks: Automated response for common issues
├── Postmortem: Mandatory within 2 hours of incident

Result:
• PCI-DSS compliance achieved, audit passed first attempt
• 99.97% uptime (exceeds 99.95% SLA)
• Zero data breaches in 5 years (strong security posture)
• 40% infrastructure cost reduction vs. traditional VMs
• Weekly deployments vs. quarterly releases before
```

---

## 2. OpenShift Installation & Configuration

### 2.1 Installation Methods

#### IPI (Installer-Provisioned Infrastructure)

**Best for:** Cloud deployments (AWS, Azure, Google Cloud)

```bash
#!/bin/bash
# IPI installation walkthrough for AWS

# 1. Download installer
cd /tmp
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-install-linux.tar.gz
tar xzf openshift-install-linux.tar.gz

# 2. Create install-config.yaml
./openshift-install create install-config --dir=./cluster

# Edit install-config.yaml
cat cluster/install-config.yaml
---
apiVersion: v1
baseDomain: example.com
metadata:
  name: prod-cluster
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
  platform:
    aws:
      zones:
      - us-east-1a
      - us-east-1b
      - us-east-1c
      rootVolume:
        iops: 4000
        size: 500
        type: io1
      type: m5.2xlarge
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0                    # Auto-scale from 0
  platform:
    aws:
      zones:
      - us-east-1a
      - us-east-1b
      - us-east-1c
      rootVolume:
        iops: 3000
        size: 120
        type: io1
      type: m5.2xlarge
networking:
  clusterNetworks:
  - cidr: 10.128.0.0/14          # Pod network (16384 pods)
    hostPrefix: 23               # /23 per node (510 pods/node)
  serviceNetwork:
  - 172.30.0.0/16                # Service network
  networkType: OVNKubernetes     # SDN type
platform:
  aws:
    region: us-east-1
    userTags:
      environment: production
      department: trading
pullSecret: 'your-pull-secret-here'
sshKey: 'your-ssh-key-here'
---

# 3. Install cluster
./openshift-install create cluster --dir=./cluster

# Installer creates:
# • VPC with public/private subnets
# • Security groups and network policies
# • Load balancer for API endpoint
# • VMs for 3 master + 3 worker nodes
# • Storage: encrypted, encrypted, provisioners
# Expected time: 30-45 minutes

# 4. Verify installation
export KUBECONFIG=./cluster/auth/kubeconfig
oc get nodes
# NAME                           STATUS   ROLES    AGE
# ip-10-0-10-100.ec2.internal   Ready    master   20m
# ip-10-0-10-101.ec2.internal   Ready    master   20m
# ip-10-0-10-102.ec2.internal   Ready    master   20m
# ip-10-0-20-100.ec2.internal   Ready    worker   18m
# ip-10-0-20-101.ec2.internal   Ready    worker   18m
# ip-10-0-20-102.ec2.internal   Ready    worker   18m

# 5. POST installation configuration
# Add infra nodes, storage, networking, etc. (see section 2.2)
```

#### UPI (User-Provisioned Infrastructure)

**Best for:** On-premise, specific network requirements, multi-cloud

```bash
#!/bin/bash
# UPI installation on vSphere (or on-premise)

# 1. Download pull secret and ISO
mkdir -p ~/ocp-upi
cd ~/ocp-upi
wget https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/latest/rhcos-openstack.x86_64.qcow2.gz

# 2. Prepare infrastructure
# • Create DHCP/DNS records for cluster hosts
# • Configure load balancer for API endpoints
# • Create firewall rules

# 3. Boot RHCOS VMs with kernel parameters
# Example: provision-host.sh
#!/bin/bash
VM_NAME="master-0"
IGNITION_CONFIG="master.ign"
CLUSTER_NAME="prod"
BASE_DOMAIN="example.com"

# Create VM
virt-install \
  --name=$VM_NAME \
  --disk path=/var/lib/libvirt/images/$VM_NAME.qcow2,size=120 \
  --memory=16384 \
  --vcpus=8 \
  --os-type=linux \
  --cdrom=/root/rhcos-4.x.x-live.x86_64.iso \
  --network bridge=br0 \
  --graphics none \
  --console=pty,target_type=serial \
  --noautoconsole

# Boot with ignition parameters (automated)
# coreos.inst.install_dev=/dev/sda
# coreos.inst.ignition_url=http://192.168.1.100:8080/master.ign

# 4. Generate ignition configs
$ ./openshift-install create ignition-configs --dir=./cluster

# Files generated:
# • bootstrap.ign - temporary node for cluster initialization
# • master.ign - master node configuration
# • worker.ign - worker node configuration

# 5. Start cluster
# Boot bootstrap node, masters, workers with their respective ignition configs
# Cluster formation: ~30 minutes

# 6. Monitor installation
# Follow logs until `openshift-install install-complete` appears
./openshift-install wait-for install-complete
```

---

### 2.2-2.7 Cluster Configuration Examples

#### Post-Installation Configuration

```yaml
# 1. Configure Storage Backend
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-fast
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true
reclaimPolicy: Delete
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  fstype: ext4
volumeBindingMode: WaitForFirstConsumer

---
# 2. Configure Network Policy (Deny All Default)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# 3. Configure Resource Quotas (Prevent Resource Hogging)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: prod
spec:
  hard:
    requests.cpu: "100"              # Max 100 CPU total
    requests.memory: "200Gi"         # Max 200GB RAM total
    pods: "500"                      # Max 500 pods
    persistentvolumeclaims: "50"     # Max 50 PVCs
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values:
      - production
      - batch

---
# 4. Configure Pod Security Standards
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

---
# 5. Configure RBAC (Least Privilege)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-deployer
  namespace: prod
rules:
# Can deploy applications
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "get", "list", "patch"]
# Can read logs
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
# Cannot delete deployments
# Cannot access secrets
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-deployer
  namespace: prod
subjects:
- kind: User
  name: dev@example.com
roleRef:
  kind: Role
  name: developer-deployer

---
# 6. Configure Machine Config (Node-level Configuration)
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 99-worker-kernel-tuning
  labels:
    machineconfiguration.openshift.io/role: worker
spec:
  config:
    ignition:
      version: 3.2.0
    storage:
      files:
      - path: /etc/sysctl.d/99-worker-tuning.conf
        mode: 0644
        contents:
          source: data:,net.core.somaxconn%3D32768%0Anet.ipv4.tcp_fin_timeout%3D30%0A
    systemd:
      units:
      - name: tuned.service
        enabled: true
        contents: |
          [Unit]
          Description=Kernel tuning service
          
          [Service]
          Type=oneshot
          ExecStart=/sbin/sysctl -p /etc/sysctl.d/99-worker-tuning.conf
```

---

## 3. OpenShift Networking Deep Dive

### 3.1 SDN Concepts

#### Textual Deep Dive

**Pod Networking Model:**

Every pod gets its own IP address on the cluster network. Pods can communicate directly without port mappings:

```
┌─────────────────────────────────────────┐
│        OpenShift Cluster Network         │
│        10.128.0.0/14 (16,384 pods)      │
├──────────────────┬──────────────────────┤
│ Node-1 (10.0.1.x)│ Node-2 (10.0.2.x)   │
├──────────────────┼──────────────────────┤
│ Pod A: 10.128.1.5│ Pod B: 10.128.2.5   │
│ (app: payment)   │ (app: cache)        │
├──────────────────┼──────────────────────┤
│ Pod C: 10.128.1.10 │ Pod D: 10.128.2.10│
│ (app: auth)      │ (app: api-gateway)  │
└──────────────────┴──────────────────────┘

Pod A (10.128.1.5) can directly connect to Pod B (10.128.2.5):
curl http://10.128.2.5:6379  # Direct pod IP communication

Across nodes: SDN overlay network handles routing
```

**Service Network (Abstraction Layer):**

Services provide stable DNS names and load balancing:

```
Service: cache-service (172.30.0.100)
├── Selector: app=cache
├── Endpoints: [10.128.1.5, 10.128.2.5]
└── Ports: 6379 → 6379

Connection from Pod A to Service:
$ redis-cli -h cache-service -p 6379

DNS resolution:
cache-service.prod.svc.cluster.local → 172.30.0.100 (virtual IP)

kube-proxy (on each node) intercepts connections to 172.30.0.100
Selects backend: 10.128.1.5 or 10.128.2.5 (round-robin)
Forwards connection to selected backend
```

### 3.2 OpenShift SDN vs. OVN-Kubernetes

```yaml
# OVN-Kubernetes (default in v4.3+, recommended)
---
apiVersion: operator.openshift.io/v1
kind: Network
metadata:
  name: cluster
spec:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  serviceNetwork:
  - 172.30.0.0/16
  networkType: OVNKubernetes    # Modern, scalable
  additionalNetworks: []
  
  # Network policies
  defaultNetwork:
    type: OVNKubernetes
    ovnKubernetesConfig:
      mtu: 1500
      genevePort: 6081
      # Enable network policies
      policyAuditConfig:
        destination: "null"

---
### 3.3 Service Mesh with OpenShift Service Mesh (Istio)

#### Textual Deep Dive

**Internal Working Mechanism:**

Service Mesh sits between pods, managing inter-pod communication:

```
Pod A (application)
  │
  │ (localhost:8080 connection)
  │
  ├─→ Envoy Proxy (sidecar, intercepts ALL traffic)
  │   ├─→ Authentication (mTLS certificate check)
  │   ├─→ Authorization (who can communicate?)
  │   ├─→ Load balancing (which backend to forward to?)
  │   ├─→ Retry logic (automatic retries on failure)
  │   └─→ Observability (metrics, traces, logs)
  │
  ├─→ Network (encrypted mTLS to Pod B)
  │
  └─→ Pod B (Envoy Proxy)
      ├──→ Pod B (application)

Result:
• Pod A doesn't know encryption details (handled by Envoy)
• Pod A doesn't manage retries (handled by Envoy)
• Pod A doesn't do service discovery (handled by Envoy)
• Uniform traffic management across all services
```

**Installation & Configuration:**

```bash
#!/bin/bash
# Install OpenShift Service Mesh operator

# 1. Install operator via OperatorHub (UI or CLI)
oc apply -f <operator subscription manifest>

# 2. Create ServiceMeshControlPlane
cat <<EOF | oc apply -f -
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: basic
  namespace: istio-system
spec:
  version: v2.2
  telemetry:
    v2:
      enabled: true
  tracing:
    sampling: 10000
    type: Jaeger
  policy:
    type: Istiod
EOF

# 3. Create ServiceMeshMemberRoll (enroll namespaces)
cat <<EOF | oc apply -f -
apiVersion: maistra.io/v1
kind: ServiceMeshMemberRoll
metadata:
  name: default
  namespace: istio-system
spec:
  members:
  - prod                      # Enroll 'prod' namespace
  - staging
EOF

# 4. After enrollment, pods in 'prod' namespace:
# Envoy proxies injected automatically
# mTLS encryption enabled automatically

# 5. Deploy VirtualService for traffic management
cat <<EOF | oc apply -f -
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-gateway
  namespace: prod
spec:
  hosts:
  - api-gateway
  http:
  - match:
    - headers:
        user-type:
          exact: "premium"
    route:
    - destination:
        host: api-gateway
        subset: v2             # Send premium users to v2 (newer version)
      weight: 100
  - route:
    - destination:
        host: api-gateway
        subset: v1             # Send others to v1
      weight: 100

---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-gateway
  namespace: prod
spec:
  host: api-gateway
  trafficPolicy:
    connectionPool:
      http:
        http1MaxPendingRequests: 100
        maxRequestsPerConnection: 2
      tcp:
        maxConnections: 100
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
EOF
```

**Production Usage Patterns:**

**Pattern: Canary Deployments via Service Mesh**

```yaml
# Deploy new version (v2) alongside existing (v1)
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway-v2
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-gateway
      version: v2
  template:
    metadata:
      labels:
        app: api-gateway
        version: v2
    spec:
      containers:
      - name: api
        image: api-gateway:v2.0.0

---
# Route 10% traffic to v2, 90% to v1
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-gateway
  namespace: prod
spec:
  hosts:
  - api-gateway
  http:
  - route:
    - destination:
        host: api-gateway
        subset: v1
      weight: 90
    - destination:
        host: api-gateway
        subset: v2
      weight: 10

---
# Monitor error rates from v2
# If errors < 0.1% for 1 hour, increase to 50/50
# If errors < 0.01% for 2 hours, go to 0/100 (full cutover)
# If errors > 1% at any point, immediate rollback (0/100 to v1)

# This automation can be scripted or use Flagger (GitOps canary operator)
```

---

### 3.4-3.9 Network Policies, Ingress/Egress, Load Balancing, DNS, Troubleshooting

#### 3.4 Network Policies Deep Dive

```yaml
# Deny-all default, then explicit allow-list
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: prod
spec:
  podSelector: {}            # Applies to all pods
  policyTypes:
  - Ingress                  # Deny all ingress
  - Egress                   # Deny all egress

---
# Allow API pods to receive traffic from frontend pods
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-api
  namespace: prod
spec:
  podSelector:
    matchLabels:
      tier: api              # Applies to pods with tier=api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend     # Allow traffic from frontend pods
    ports:
    - protocol: TCP
      port: 8080

---
# Allow API pods to reach database (external)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
  namespace: prod
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database     # Allow egress to 'database' namespace
    ports:
    - protocol: TCP
      port: 5432

---
# Allow all traffic to logging stack (observability must work)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-to-logging
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: openshift-logging
    ports:
    - protocol: TCP
      port: 24224  # Fluent Bit
```

**Practical Network Policy Debugging:**

```bash
#!/bin/bash
# Troubleshoot connectivity issues

# 1. Test pod-to-pod connectivity (DNS resolution)
oc exec -it deployment/api-gateway -- \
  nslookup cache-service.prod.svc.cluster.local
# Expected: returns cluster IP (e.g., 172.30.0.100)

# 2. Test network path exists (netcat)
oc exec -it deployment/api-gateway -- \
  nc -zv cache-service.prod.svc.cluster.local 6379
# Expected: "Connection succeeded" (or shows connection refused if service doesn't have port 6379)

# 3. Check network policy rules applied to pod
oc get networkpolicy -n prod
oc describe networkpolicy --namespace=prod

# 4. Check if traffic is actually blocked (tcpdump on node)
oc debug node/worker-1 -- chroot /host tcpdump -i any 'dst port 5432'
# Capture packets destined for PostgreSQL to verify traffic path

# 5. Test egress to external service
oc exec -it deployment/api-gateway -- \
  curl -v https://example.com
# If hangs/times out: network policy likely denies egress
```

---

#### 3.5 Ingress & Egress Configuration

```yaml
# Ingress: External traffic entering cluster
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: prod
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.example.com
    secretName: api-tls-cert       # cert-manager auto-renews
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1/payments
        pathType: Prefix
        backend:
          service:
            name: payment-service
            port:
              number: 8080
      - path: /v1/accounts
        pathType: Prefix
        backend:
          service:
            name: account-service
            port:
              number: 8080

---
# OpenShift Route (extends Ingress, adds traffic splitting, rewrite rules)
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: api-route
  namespace: prod
spec:
  host: api.example.com
  port:
    targetPort: 8080
  tls:
    termination: edge           # TLS termination at router
    insecureEdgeTerminationPolicy: Redirect
  to:
    kind: Service
    name: api-service
    weight: 100
  alternateBackends:
  - kind: Service
    name: api-service-canary
    weight: 0                   # Can be increased for canary deployments

---
# Egress: Pod traffic to external services
# Manage via EgressIP (OpenShift feature)
apiVersion: network.openshift.io/v1
kind: EgressIP
metadata:
  name: payment-egress-ip
spec:
  egressIPs:
  - 203.0.113.1
  namespaceSelector:
    matchLabels:
      name: prod
  podSelector:
    matchLabels:
      tier: payment

# Result: All pods in 'prod' namespace with tier=payment label
# will appear to have source IP 203.0.113.1 when reaching external networks
# (Useful for whitelisting IPs in firewalls)
```

---

## 4. OpenShift Storage Deep Dive

### 4.1-4.3 Storage Concepts, Persistent Volumes, Storage Classes

```yaml
# Persistent Volume (PV) - Cluster resource
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ebs-pv-001
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteOnce                # Only one pod can mount (read-write)
  persistentVolumeReclaimPolicy: Retain  # Keep volume after PVC deleted
  storageClassName: ebs-gp3
  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef
    fsType: ext4

---
# Persistent Volume Claim (PVC) - Pod requests storage
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
  namespace: prod
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: ebs-gp3
  resources:
    requests:
      storage: 50Gi

---
# Storage Class (automated provisioning)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true
reclaimPolicy: Delete               # Delete volume when PVC deleted
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  fstype: ext4
volumeBindingMode: WaitForFirstConsumer  # Bind after pod scheduled

---
# Pod using PVC
apiVersion: v1
kind: Pod
metadata:
  name: database-pod
  namespace: prod
spec:
  containers:
  - name: postgres
    image: postgres:14
    volumeMounts:
    - name: data
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: database-pvc    # References PVC above
```

**Production Storage Patterns:**

```yaml
# Pattern 1: StatefulSet with persistent storage
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: cassandra
  namespace: prod
spec:
  serviceName: cassandra
  replicas: 3
  selector:
    matchLabels:
      app: cassandra
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
      - name: cassandra
        image: cassandra:4.0
        volumeMounts:
        - name: cassandra-data
          mountPath: /var/lib/cassandra
  volumeClaimTemplates:
  - metadata:
      name: cassandra-data
    spec:
      accessModes:
      - ReadWriteOnce
      storageClassName: ebs-io1
      resources:
        requests:
          storage: 100Gi

# Result: 
# cassandra-0 → cassandra-data-0 (persistent volume)
# cassandra-1 → cassandra-data-1 (persistent volume)
# cassandra-2 → cassandra-data-2 (persistent volume)
```

---

## 5. OpenShift Security Deep Dive

### 5.1-5.7 Security Concepts, RBAC, Pod Security, Secrets, Image Security

```yaml
# Comprehensive Security Setup
---
# 1. Pod Security Standards (enforce restricted pods)
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

---
# 2. RBAC: Role for developers
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: prod
rules:
# Deployments: full control
- apiGroups: ["apps"]
  resources: ["deployments", "deployments/scale"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
# Pod logs
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
# NO secrets access
# NO node access
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers
  namespace: prod
subjects:
- kind: Group
  name: developers@example.com
roleRef:
  kind: Role
  name: developer

---
# 3. Security Context (pod-level security policies)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: prod
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true         # Container must run as non-root user
        runAsUser: 1000
        fsGroup: 2000              # Volume mount permissions
        seccompProfile:
          type: RuntimeDefault     # Enable seccomp restricting syscalls
      containers:
      - name: app
        image: myapp:v1
        securityContext:
          allowPrivilegeEscalation: false  # Cannot become root
          readOnlyRootFilesystem: true     # Filesystem read-only
          capabilities:
            drop:
            - ALL                          # Remove all Linux capabilities
```

**Image Security Scanning:**

```yaml
# Image policy: reject images with CVE severity >= 7
---
apiVersion: images.openshift.io/v1alpha1
kind: ImageSecurityPolicy
metadata:
  name: reject-high-cve
spec:
  matchImageTransportNames:
  - docker
  policy:
  - name: reject-high-severity-cve
    conditions:
    - type: ImageScanResult
      reason: HighSeverityCVE
      message: "Image has CVE severity >= 7"
    action:
      type: Reject

# Build time scanning (pipeline rejects vulnerable images)
---
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: secure-build
  namespace: prod
spec:
  source:
    git:
      uri: https://github.com/example/app
  strategy:
    dockerStrategy:
      dockerfilePath: Dockerfile
  postCommit:
    command:
    - /bin/sh              # Scan image after build
    - -c
    - |
      skopeo inspect --creds user:pass docker://registry.example.com/app:${BUILD_COMMIT}
      # If CVE found, this fails
      # Build marked FAILED
      # Image NOT pushed to registry
```

---

## 6. OpenShift CI/CD Pipelines

### 6.1-6.6 CI/CD Concepts, Pipeline Components, Configuration, Best Practices

```yaml
# OpenShift Pipelines (based on Tekton)
---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: build-image
  namespace: prod
spec:
  params:
  - name: GIT_REPO
  - name: GIT_REVISION
    default: main
  - name: IMAGE_NAME
  steps:
  - name: build
    image: quay.io/buildah/stable:latest
    script: |
      #!/usr/bin/env bash
      cd /workspace
      git clone $(params.GIT_REPO) .
      git checkout $(params.GIT_REVISION)
      
      buildah build -f Dockerfile -t $(params.IMAGE_NAME):$(GIT_COMMIT) .
      buildah push $(params.IMAGE_NAME):$(GIT_COMMIT)

---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: scan-image
  namespace: prod
spec:
  params:
  - name: IMAGE_NAME
  steps:
  - name: trivy-scan
    image: aquasec/trivy:latest
    script: |
      trivy image --exit-code 1 --severity HIGH,CRITICAL $(params.IMAGE_NAME)
      # Exit code 1 = vulnerabilities found, pipeline fails

---
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: deploy
  namespace: prod
spec:
  params:
  - name: IMAGE_NAME
  - name: DEPLOYMENT_NAME
  - name: NAMESPACE
  steps:
  - name: update-deployment
    image: bitnami/kubectl:latest
    script: |
      kubectl set image deployment/$(params.DEPLOYMENT_NAME) \
        app=$(params.IMAGE_NAME) \
        -n $(params.NAMESPACE)
      
      kubectl rollout status deployment/$(params.DEPLOYMENT_NAME) \
        -n $(params.NAMESPACE) --timeout=5m

---
# Pipeline orchestrates tasks
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-test-deploy
  namespace: prod
spec:
  params:
  - name: GIT_REPO
  - name: IMAGE_NAME
  - name: DEPLOYMENT_NAME
  tasks:
  - name: build
    taskRef:
      name: build-image
    params:
    - name: GIT_REPO
      value: $(params.GIT_REPO)
    - name: IMAGE_NAME
      value: $(params.IMAGE_NAME)
      
  - name: scan
    runAfter: ["build"]          # Only run after build succeeds
    taskRef:
      name: scan-image
    params:
    - name: IMAGE_NAME
      value: $(params.IMAGE_NAME)
      
  - name: deploy
    runAfter: ["scan"]           # Only deploy after scan passes
    taskRef:
      name: deploy
    params:
    - name: IMAGE_NAME
      value: $(params.IMAGE_NAME)
    - name: DEPLOYMENT_NAME
      value: $(params.DEPLOYMENT_NAME)

---
# PipelineRun: triggered by Git webhook
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  name: build-test-deploy-run
  namespace: prod
spec:
  pipelineRef:
    name: build-test-deploy
  params:
  - name: GIT_REPO
    value: https://github.com/example/app.git
  - name: IMAGE_NAME
    value: registry.example.com/app
  - name: DEPLOYMENT_NAME
    value: my-app
```

**Git Webhook Trigger:**

```yaml
# EventListener: Git webhooks trigger PipelineRuns
---
apiVersion: triggers.tekton.dev/v1alpha1
kind: EventListener
metadata:
  name: github-webhook
  namespace: prod
spec:
  triggers:
  - name: github-push
    interceptors:
    - ref:
        name: "github"
      params:
      - name: eventTypes
        value: ["push"]
    bindings:
    - ref: github-binding
    template:
      ref: pipeline-template

---
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerBinding
metadata:
  name: github-binding
  namespace: prod
spec:
  params:
  - name: gitcloneurl
    value: $(body.repository.clone_url)
  - name: gitrevision
    value: $(body.head_commit.id)

---
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerTemplate
metadata:
  name: pipeline-template
  namespace: prod
spec:
  params:
  - name: gitcloneurl
  - name: gitrevision
  resourcetemplates:
  - apiVersion: tekton.dev/v1beta1
    kind: PipelineRun
    metadata:
      generateName: build-test-deploy-
    spec:
      pipelineRef:
        name: build-test-deploy
      params:
      - name: GIT_REPO
        value: $(tt.params.gitcloneurl)
```

---

## 7. OpenShift Source-to-Image (S2I)

### 7.1-7.5 S2I Concepts, Workflow, Best Practices

```yaml
# BuildConfig using S2I
---
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: nodejs-app
  namespace: prod
spec:
  source:
    git:
      uri: https://github.com/example/nodejs-app
      ref: main              # Git branch/tag
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: nodejs:16     # S2I builder image (includes Node.js, npm)
        namespace: openshift
      env:
      - name: NPM_BUILD_SCRIPT
        value: build
  output:
    to:
      kind: ImageStreamTag
      name: nodejs-app:latest  # Output image tag
  successfulBuildsHistoryLimit: 5  # Keep last 5 successful builds
  failedBuildsHistoryLimit: 2
  triggers:
  - type: GitHub
    github:
      secret: my-secret
  - type: ImageChange
    imageChange:
      from:
        kind: ImageStreamTag
        name: nodejs:16      # Rebuild when builder image updated
```

**S2I Build Process (Behind the Scenes):**

```
S2I Workflow:
1. Git clone: Repository downloaded to /tmp/build
2. assemble: Builder image entrypoint runs assemble script
   └─ npm install                (dependencies)
   └─ npm run build              (build app)
3. Result: /opt/app-root/src contains built application
4. Run: Builder image entrypoint runs run script
   └─ npm start                  (process manager)
5. Output image: Built application + runtime (Node.js)

Example Dockerfile equivalence for Node.js S2I:
FROM node:16
WORKDIR /opt/app-root/src
COPY . .
RUN npm install && npm run build
EXPOSE 8080
CMD ["npm", "start"]
```

**Custom S2I Builder Image:**

```dockerfile
# Dockerfile: Custom S2I builder image
FROM rhel8:latest

LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i
LABEL io.openshift.s2i.destination=/opt/app-root

# Install build tools
RUN yum install -y gcc python3-pip

# Copy S2I scripts
COPY s2i/bin/assemble /usr/libexec/s2i/assemble
COPY s2i/bin/run /usr/libexec/s2i/run
RUN chmod +x /usr/libexec/s2i/*

WORKDIR /opt/app-root
EXPOSE 8080
CMD ["/usr/libexec/s2i/run"]

---
# s2i/bin/assemble script
#!/bin/bash
set -e

echo "Building application..."
cd /tmp/build
pip install -r requirements.txt
python setup.py build

# Copy built artifacts to runtime location
mv dist/* /opt/app-root/app/

---
# s2i/bin/run script
#!/bin/bash
exec python /opt/app-root/app/server.py
```

---

## 8. OpenShift Monitoring & Logging

### 8.1-8.9 Monitoring Concepts, Tools, Metrics Collection, Alerting, Logging

```yaml
# Prometheus integration (pre-installed)
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: application-alerts
  namespace: prod
spec:
  groups:
  - name: application.rules
    interval: 30s
    rules:
    # Application metrics (custom instrumentation)
    - alert: APIErrorRateHigh
      expr: |
        rate(http_requests_total{status=~"5\\d\\d"}[5m]) / 
        rate(http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "API error rate > 5% ({{ $value | humanizePercentage }})"
        
    # Infrastructure alerts
    - alert: NodeCPUUsageHigh
      expr: |
        (1 - (avg by (node) (rate(node_cpu_seconds_total{mode="idle"}[5m])))) > 0.8
      for: 10m
      labels:
        severity: critical
      annotations:
        summary: "Node {{ $labels.node }} CPU > 80%"

---
# AlertManager routes alerts to destinations
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: openshift-monitoring
data:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
    route:
      receiver: 'default'
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      routes:
      - match:
          severity: critical
        receiver: 'pagerduty'
        continue: true
      - match:
          severity: warning
        receiver: 'slack'
    receivers:
    - name: 'default'
    - name: 'pagerduty'
      pagerduty_configs:
      - service_key: 'your-pagerduty-key'
    - name: 'slack'
      slack_configs:
      - api_url: 'your-slack-webhook'
        channel: '#alerts'

---
# Logging: EFK stack (Elasticsearch, Fluent Bit, Kibana)
---
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  managementState: Managed
  logStore:
    type: elasticsearch
    elasticsearch:
      nodeCount: 3
      storage:
        storageClassName: ebs-gp3
        size: 200Gi
      resources:
        limits:
          memory: "8Gi"
        requests:
          memory: "8Gi"
  collection:
    logs:
      type: fluentbit        # Lightweight log collector
  visualization:
    type: kibana
    kibana:
      replicas: 1
```

**Production Logging Configuration:**

```yaml
# Fluent configuration for structured logging
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentbit-config
  namespace: openshift-logging
data:
  fluent-bit.conf: |
    [INPUT]
      Name              tail
      Path              /var/log/containers/*_prod_*.log
      Parser            docker
      Tag               prod.*
      RefreshInterval   5
      Mem_Buf_Limit     5MB
      Skip_Long_Lines   On
      
    [FILTER]
      Name                kubernetes
      Match               prod.*
      Kube_URL            https://kubernetes.default.svc:443
      Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
      Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
      Labels              On
      Annotations         On
      
    [OUTPUT]
      Name   es
      Match  prod.*
      Host   elasticsearch.openshift-logging
      Port   9200
      HTTP_User    elastic
      HTTP_Passwd  ${ELASTICSEARCH_PASSWORD}
      Retry_Limit  3
      Index  prod-%Y.%m.%d
      Type   _doc
```

**Query logs via Kibana/CLI:**

```bash
# CLI: query logs from pod
oc logs deployment/api-service -n prod --tail=50 --timestamps=true

# Query logs from all pods in namespace
oc logs -n prod -l app=api-service --all-containers --tail=100

# Stream logs (like tail -f)
oc logs -f deployment/api-service -n prod

# Previous logs (for crashed pods)
oc logs -p deployment/api-service -n prod
```

---

## Summary

This advanced guide has covered:

✅ **Architecture Deep Dives**: Control plane, worker nodes, components, HA patterns  
✅ **Installation Methods**: IPI for cloud, UPI for on-premise  
✅ **Networking**: SDN, service mesh, network policies, ingress/egress  
✅ **Storage**: PV, PVC, StorageClass, StatefulSets  
✅ **Security**: RBAC, pod security, image scanning, secrets  
✅ **CI/CD**: Tekton pipelines, S2I, automated deployments  
✅ **Observability**: Prometheus metrics, EFK logging, alerting  

**Key TakeAway**: OpenShift is Kubernetes + enterprise features (developer experience, security, observability). Master these concepts to operate production-grade clusters at scale.

**Next Steps**: Move to hands-on scenarios section for practical exercises.
