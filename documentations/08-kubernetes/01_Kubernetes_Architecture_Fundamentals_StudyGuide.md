# Kubernetes Architecture Fundamentals - Senior DevOps Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Kubernetes Architecture](#overview-of-kubernetes-architecture)
   - [Why Kubernetes Architecture Matters in Modern DevOps](#why-kubernetes-architecture-matters-in-modern-devops)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Where Kubernetes Fits in Cloud Architecture](#where-kubernetes-fits-in-cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Kubernetes Architecture Overview - Master and Worker Nodes](#kubernetes-architecture-overview---master-and-worker-nodes)

4. [Master Components - API Server, etcd, Scheduler, Controller Manager](#master-components---api-server-etcd-scheduler-controller-manager)

5. [Node Components - Kubelet, Kube Proxy, Container Runtime](#node-components---kubelet-kube-proxy-container-runtime)

6. [kubeconfig and Cluster Access Management](#kubeconfig-and-cluster-access-management)

7. [Authentication and Authorization in Kubernetes](#authentication-and-authorization-in-kubernetes)

8. [Hands-on Scenarios](#hands-on-scenarios)

9. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Kubernetes Architecture

Kubernetes is a production-grade, open-source container orchestration platform that automates deployment, scaling, and operations of containerized applications across clusters of machines. At its core, Kubernetes implements a distributed system architecture composed of:

- **Control Plane (Master)**: The decision-making brain of the cluster, responsible for cluster state management, scheduling decisions, and maintaining desired state
- **Worker Nodes**: Compute resources that run containerized workloads and report their status back to the control plane
- **Networking & Storage Abstractions**: Decoupled layers enabling seamless communication and persistent data management

The architecture is deliberately decoupled, distributed, and resilient—designed to operate at scale across hybrid and multi-cloud environments while maintaining high availability and fault tolerance.

### Why Kubernetes Architecture Matters in Modern DevOps

As a DevOps engineer, understanding Kubernetes architecture is foundational for several reasons:

1. **Infrastructure as Code (IaC) Implementation**: Kubernetes declarative model enables complete infrastructure definition and version control, aligning with GitOps principles and infrastructure-as-code paradigms.

2. **Self-Healing Infrastructure**: The control plane's reconciliation loop continuously monitors actual vs. desired state, automatically recovering from node failures, pod crashes, and service disruptions without manual intervention.

3. **Multi-Tenancy & Resource Management**: Kubernetes provides namespaces, RBAC, network policies, and resource quotas—essential for managing multiple teams, applications, and cost allocation in shared infrastructure.

4. **Observability & Troubleshooting**: Deep understanding of architecture enables effective debugging of pod scheduling issues, network connectivity problems, authentication failures, and persistent performance problems.

5. **Production Reliability**: Knowledge of how the control plane reaches consensus, how data is persisted in etcd, and how failover mechanisms work is critical for designing highly available Kubernetes clusters.

6. **Security Posture**: Architecture understanding directly impacts your ability to implement proper RBAC, network segmentation, secrets management, and compliance controls.

### Real-World Production Use Cases

**Scenario 1: Multi-Tenant SaaS Platform**
- Organization runs multiple customer applications on shared Kubernetes cluster
- Uses namespaces for isolation, RBAC for access control, resource quotas for fair allocation
- Network policies enforce tenant-to-tenant traffic restrictions
- etcd replication ensures customer data consistency across cluster failures

**Scenario 2: Hybrid Cloud Deployment**
- Primary workloads run on on-premises Kubernetes cluster
- Burst capacity configured on cloud (AWS EKS, Azure AKS, GCP GKE)
- kubeconfig federation enables unified cluster access
- Controller manager handles pod placement across infrastructure boundaries

**Scenario 3: Zero-Downtime Application Upgrades**
- Deployment rolling updates orchestrated by Kubernetes scheduler and controller manager
- Multiple API server replicas and etcd cluster ensure continuous cluster API availability
- Node graceful shutdown procedures allow in-flight requests completion
- kubelet health checks enable pod failure recovery

**Scenario 4: Compliance-Driven Architecture**
- RBAC implements least-privilege access for audit compliance
- API server audit logging tracks all state changes
- etcd encryption at rest and in transit protects sensitive data
- ServiceAccounts with short-lived tokens manage pod identity

### Where Kubernetes Fits in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloud Platform (AWS/Azure/GCP/Hybrid)    │
├─────────────────────────────────────────────────────────────┤
│                   Kubernetes Cluster                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │            Control Plane (Master Components)           │ │
│  │  - API Server | etcd | Scheduler | Controller Manager  │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────┬──────────────┬──────────────────────┐   │
│  │  Worker Node 1 │ Worker Node 2 │   Worker Node N     │   │
│  │ - Kubelet      │ - Kubelet     │  - Kubelet          │   │
│  │ - Kube-proxy   │ - Kube-proxy  │  - Kube-proxy       │   │
│  │ - CRI (Docker/ │ - CRI (Docker/│  - CRI (Docker/     │   │
│  │   containerd)  │   containerd) │    containerd)      │   │
│  └────────────────┴──────────────┴──────────────────────┘   │
│                                                              │
│  Persistent Storage Layer    Networking Layer               │
│  - etcd (state)             - CNI (networking)              │
│  - PVs (application data)   - Service mesh (optional)       │
└─────────────────────────────────────────────────────────────┘
        ↓
User Applications (Deployments, StatefulSets, DaemonSets, Jobs)
```

---

## Foundational Concepts

### Key Terminology

**Control Plane (Master)**
The cluster's central management system. Runs API server, etcd, scheduler, and controller manager. Makes scheduling decisions and maintains cluster state. Does not run user applications (though can be configured to in single-node clusters).

**Worker Node**
Compute resource where containerized workloads execute. Runs kubelet (node agent), kube-proxy (networking), and container runtime. Reports status and receives instructions from control plane.

**API Server**
RESTful gateway to cluster state. All Kubernetes operations (create, read, update, delete) funnel through the API server. Acts as the authoritative source of cluster state and implements authentication/authorization.

**etcd**
Strongly-consistent, distributed key-value store. Single source of truth for entire cluster state. All cluster data persists here. Backbone of cluster consistency and disaster recovery.

**Scheduler**
Control plane component that watches for newly created Pods without assigned nodes. Makes intelligent decisions about which worker node should run each Pod based on resource requests, affinity rules, node constraints, and current cluster state.

**Controller Manager**
Runs collection of control loops (controllers) that watch cluster state and make changes to reach desired state. Examples: ReplicaSet controller (maintains Pod replicas), Deployment controller (manages Rolling Updates), Node controller (handles node failures).

**Kubelet**
Node agent running on every worker node. Ensures containers run in Pods. Registers node with control plane, executes Pod definitions, reports node/Pod status, handles volume mounting, executes container restart policies.

**Kube-Proxy**
Network proxy running on every worker node. Maintains network rules for Pod-to-Pod and external-to-Pod communication. Implements Service abstraction as virtual IPs with load balancing.

**Container Runtime Interface (CRI)**
Abstraction layer separating Kubernetes from specific container runtimes (Docker, containerd, CRI-O). Allows **any** container runtime implementation as long as it satisfies CRI specification.

**kubeconfig**
Configuration file (typically `~/.kube/config`) containing cluster definitions, authentication credentials, and context information. Enables kubectl to connect to and authenticate with specific clusters.

### Architecture Fundamentals

#### 1. **Declarative vs. Imperative**

Kubernetes operates on **declarative model**—you declare desired state, Kubernetes figures out how to achieve it.

```yaml
# Declarative: "I want 3 replicas of this application"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.0
```

Control plane continuously works to maintain this state. If a Pod crashes, kubelet automatically restarts it. If a node fails, controller manager reschedules Pods elsewhere.

#### 2. **Distributed Consensus & Eventual Consistency**

- **API Server** acts as single coordinator, but state persists to **etcd**
- **etcd** uses Raft consensus algorithm ensuring all replicas eventually reach same state
- Cluster-wide changes go through **Raft voting** before committing
- This guarantees **no split-brain scenarios** and **consistent state** across failures

#### 3. **Reconciliation Loop (Control Loop Pattern)**

The fundamental pattern driving Kubernetes:

```
┌─────────────────────────┐
│  Read Current State     │
│  (from API Server)      │
└────────────┬────────────┘
             │
             ↓
┌─────────────────────────┐
│  Compare with Desired   │
│  State (from etcd)      │
└────────────┬────────────┘
             │
             ↓
┌─────────────────────────┐
│  If Different:          │
│  Take Corrective Action │
└────────────┬────────────┘
             │
             ↓
        (repeat forever)
```

Every controller runs this loop. If a ReplicaSet should have 3 Pods but only 2 exist, the controller creates another.

#### 4. **Layered Security Model**

Kubernetes implements defense-in-depth:
- **Authentication**: "Who are you?" (certificates, tokens, webhooks)
- **Authorization**: "What are you allowed to do?" (RBAC, ABAC, webhooks)
- **Admission Control**: "Should we allow this action?" (network policies, pod security policies, webhook validators)
- **Encryption**: Data at rest (etcd) and in transit (TLS)

#### 5. **Service Abstraction & Virtual IPs**

Services provide stable endpoints even as underlying Pods change:
- Service creates virtual IP (ClusterIP)
- kube-proxy maintains iptables/IPVS rules mapping virtual IP to real Pod IPs
- Clients connect to stable IP; kube-proxy handles routing to available endpoints

### Important DevOps Principles

#### 1. **Infrastructure as Code**
Every Kubernetes resource is a **declarative manifest** that can be version controlled, Code-reviewed, and deployed through CI/CD pipelines. Enables GitOps workflows where Git is source of truth.

#### 2. **High Availability by Default**
- Run **multiple control plane replicas** to survive component failures
- **etcd cluster** (3, 5, or 7 nodes) tolerates minority failures
- **Multiple worker nodes** so pod failures don't take down applications
- Kubernetes assumes failure is normal state of distributed systems

#### 3. **Graceful Degradation**
Kubernetes degrades gracefully rather than catastrophically failing:
- Single API server failure → other servers handle requests
- Single node failure → pods reschedule elsewhere
- Network partition → controllers stop making changes (prevents split-brain)

#### 4. **Shift-Left Philosophy**
Push configuration, policy, and compliance decisions to deployment time rather than runtime:
- Define resource limits/requests upfront
- Enforce network policies via declarative rules
- Implement RBAC before users gain access

#### 5. **Observability-First Design**
- Every component exposes metrics (Prometheus format)
- Audit logging tracks all API operations
- Structured logging from all components
- Health checks (liveness, readiness) inform scheduling decisions

### Best Practices

#### 1. **Control Plane High Availability**
- Deploy **at least 3 API server replicas** with load balancer in front
- Use **odd-numbered etcd cluster** (3, 5, 7) for quorum—never even numbers
- Separate etcd cluster from other control plane components for isolation
- Distribute control plane across multiple zones for geographic resilience

#### 2. **kubeconfig Management**
- **Never commit kubeconfig to version control** (contains credentials)
- Use **short-lived tokens** via external identity providers (OIDC, AD)
- Implement **RBAC with service accounts** for pod authentication
- Rotate kubeconfig credentials regularly

#### 3. **Node Resource Capacity Planning**
- **Under-subscribe node resources** (e.g., allocate 80% capacity to pods)
- Reserve resources for kubelet, OS, and system daemons
- Use resource requests/limits to guide scheduler and prevent OOM kills
- Monitor actual vs. requested resources; adjust requests based on data

#### 4. **Cluster Networking Design**
- Implement **CNI plugin** supporting network policies (Calico, Cilium)
- Enforce **NetworkPolicy rules** for pod-to-pod communication
- Use **service mesh** (Istio, Linkerd) for advanced traffic control in production
- Isolate cluster network from external networks via ingress controllers

#### 5. **RBAC Implementation Strategy**
- Default-deny RBAC rules (explicit allow)
- Create **dedicated service accounts** per application/team
- Avoid using default service account
- Regular RBAC audits to identify over-privileged accounts

### Common Misunderstandings

#### Misunderstanding #1: "Control Plane = Single Master Node"
**Reality**: Modern production Kubernetes runs **multiple API servers, multiple etcd replicas, and multiple controller manager/scheduler instances** for high availability. "Master" is a misnomer from older Kubernetes versions.

#### Misunderstanding #2: "etcd Stores Everything"
**Reality**: etcd stores **only metadata and desired state** (resource definitions). **Actual image packages, build artifacts, and application data** live in image registries and persistent volumes. etcd deletion ≠ data loss, but prevents recovery of state.

#### Misunderstanding #3: "Scheduler Places Every Pod on a Node"
**Reality**: Scheduler only **makes scheduling decision** (selects node). **Kubelet actually pulls the image and starts the container**. If kubelet fails to pull image or start container, pod never actually runs despite being "scheduled."

#### Misunderstanding #4: "kubeconfig Stores Cluster State"
**Reality**: kubeconfig is **only connection configuration** (API server address, credentials, clusters/contexts). Cluster state lives **exclusively in API server's etcd**. kubeconfig loss doesn't affect running cluster, only your ability to manage it.

#### Misunderstanding #5: "Kubernetes is Serverless"
**Reality**: Kubernetes **still requires you to manage nodes, networking, storage, cluster upgrades, security**. It abstracts container management, not infrastructure. Compare to actual serverless (AWS Lambda, Azure Functions) which abstracts everything.

#### Misunderstanding #6: "Multiple Control Plane Instances Means They Compete"
**Reality**: Multiple API servers, schedulers, and controller managers **work in coordination**:
- **API servers**: All write to same etcd; read-consistent across all replicas
- **etcd**: Consensus ensures only one version of truth
- **Schedulers & Controllers**: Use **leader election** to ensure only active instance makes decisions (prevents conflicting actions)

#### Misunderstanding #7: "Network Policies = Firewalls"
**Reality**: Network policies are **pod-level routing rules**, not traditional firewalls. They control east-west traffic (pod-to-pod) but typically don't directly control north-south (external ingress). Ingress controllers and load balancers handle that.

---

## Kubernetes Architecture Overview - Master and Worker Nodes

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes clusters consist of two distinct node types operating in a **tightly coupled control loop architecture**:

**Control Plane (Master) Node Workflow:**
1. **State Reception**: API server receives declarative resource definitions (Deployments, Services, ConfigMaps, etc.)
2. **Persistence**: Requests validated and written to etcd (atomic, strongly-consistent)
3. **Observation**: Controllers continuously watch etcd for desired state changes
4. **Decision Making**: Schedulers and controllers compare actual vs. desired state
5. **Command Issuance**: Controllers write operational commands (Pod creation, constraint updates)
6. **Status Monitoring**: Control plane continuously polls worker nodes for execution status

**Worker Node Workflow:**
1. **Node Registration**: Kubelet registers itself with API server, reporting capacity (CPU, memory, labels)
2. **Pod Assignment**: Receives Pod specifications from API server
3. **Container Execution**: Kubelet instructs container runtime to pull image and start container
4. **Health Monitoring**: Liveness/readiness probes executed; results reported to API server
5. **Status Reporting**: Regular heartbeats maintain node connectivity and Pod status updates
6. **Graceful Shutdown**: Kubelet drains Pods during node termination

**Critical Communication Pattern:**
- **Control plane → Worker**: API server pushes Pod definitions, controllers watch for changes
- **Worker → Control plane**: Kubelet **pulls** Pod specs and **pushes** status updates (not push from control plane)
- **etcd**: Single source of truth for all desired and observed state

#### Architecture Role

**Master Node Responsibilities:**
- Cluster API endpoint and request validation gateway
- Persistent state management (etcd)
- Scheduling decisions (resource-aware Pod placement)
- Self-healing orchestration (replication management, failure recovery)
- Declarative state reconciliation (control loops)
- Policy enforcement (admission webhooks, network policies)

**Worker Node Responsibilities:**
- Container execution (via CRI)
- Network rule implementation (iptables/IPVS via kube-proxy)
- Local resource management (disk space, memory, CPU)
- Volume mounting and persistent data access
- Health monitoring and failure detection
- Node capacity reporting

#### Production Usage Patterns

**Pattern 1: High Availability Master**
```
Production clusters run 3-5 control plane nodes for fault tolerance:
- Odd numbers ensure Raft quorum (3 survives 1 failure, 5 survives 2 failures)
- Distributed across availability zones/data centers
- Load balancer fronts multiple API servers
- etcd cluster separate from other control plane components
```

**Pattern 2: Heterogeneous Worker Pools**
Multiple worker node classes based on workload requirements:
- **General compute**: Standard instance types for typical workloads
- **GPU nodes**: Specialized instances for ML/deep learning
- **Memory-optimized**: For in-memory databases and caching
- **Spot/preemptible**: Cost-optimized instances for fault-tolerant workloads

**Pattern 3: Taint & Toleration Management**
Control which workloads run on which nodes:
```yaml
# Production nodes tainted to prevent non-critical pods
kubectl taint nodes production-node workload=prod:NoSchedule

# Only Pods with matching toleration can schedule
kubectl taint nodes infra-node dedicated=infra:NoExecute
```

**Pattern 4: Node Affinity for Availability**
```
Spread workloads across nodes to prevent single-node failures:
- Pod Affinity: Co-locate pods on same node (cache locality)
- Pod Anti-Affinity: Spread replicas across different nodes (HA)
- Node Affinity: Restrict pods to node subset (GPU, specific regions)
```

#### DevOps Best Practices

1. **Master Node Isolation**
   - Dedicate separate nodes for control plane components
   - Prevent user workloads from scheduling on master (taint with `node-role.kubernetes.io/control-plane:NoSchedule`)
   - Enables predictable control plane performance and security boundary

2. **Multi-Zone Master Distribution**
   - Spread API server, etcd, and controller manager replicas across different zones
   - Survives complete zone failure
   - Monitor cross-zone latency (etcd consensus sensitive to latency)

3. **Worker Node Capacity Management**
   - Reserve 5-10% cluster capacity as buffer
   - Use resource requests/limits to prevent overcommitment
   - Implement cluster autoscaling based on pending pods
   - Monitor actual vs. requested resources; adjust requests based on production metrics

4. **Node Lifecycle Management**
   - Implement **graceful node draining** during maintenance:
     ```bash
     kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
     ```
   - Cordons nodes (`kubectl cordon`) before draining to prevent new pod scheduling
   - Implements **PodDisruptionBudgets** for availability during disruptions

5. **Master Component Monitoring**
   - Monitor etcd latency (p99 < 25ms critical for responsiveness)
   - Track API server request latency
   - Alert on scheduler blocked-on, binding errors
   - Monitor controller manager working queue depth

#### Common Pitfalls

**Pitfall 1: Single Control Plane Node**
- **Impact**: Cluster-wide outage when API server fails
- **Fix**: Minimum 3 control plane replicas with load balancer
- **Why Happens**: Development/test clusters cut corners; not scaling to production

**Pitfall 2: etcd on Same Nodes as Other Control Plane Components**
- **Impact**: API server failure impacts etcd availability; I/O from scheduler/controller manager starves etcd
- **Fix**: Dedicated etcd cluster (3-7 nodes)
- **Why Happens**: Misunderstanding of etcd criticality; cost optimization

**Pitfall 3: Poor Node Capacity Planning**
- **Impact**: Pods chronically pending; cluster appears broken but isn't scheduling-constrained
- **Fix**: Implement cluster autoscaling; use metrics to right-size nodes
- **Why Happens**: Difficulty predicting resource usage; operations overhead

**Pitfall 4: Master Nodes Running User Workloads**
- **Impact**: User pod crash destabilizes control plane; noisy neighbor problem
- **Fix**: Taint master nodes; implement admission webhooks to enforce
- **Why Happens**: Pressure to consolidate infrastructure; inadequate taint/toleration understanding

**Pitfall 5: Insufficient Network Bandwidth for etcd Replication**
- **Impact**: etcd consensus latency increases; API server becomes slow; cluster appears hung
- **Fix**: Dedicated network for etcd; monitor cross-zone bandwidth; optimize etcd snapshot frequency
- **Why Happens**: Multi-zone deployments without network analysis; etcd state explosion

### Architecture Flow Diagram

```
╔════════════════════════════════════════════════════════════════════╗
║                    KUBERNETES CLUSTER ARCHITECTURE                   ║
╚════════════════════════════════════════════════════════════════════╝

┌───────────────────────────────────────────────────────────────────┐
│                   CONTROL PLANE (MASTER NODES)                     │
│                    (Runs on dedicated nodes)                        │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  API Server (3x replicas)                                   │  │
│  │  ├─ Validates requests                                      │  │
│  │  ├─ Enforces authentication/authorization                  │  │
│  │  ├─ Writes desired state to etcd                           │  │
│  │  └─ Serves cluster API on :6443                            │  │
│  └──────────────────┬───────────────────────────────────────┬─┘  │
│                      │                                        │      │
│  ┌──────────────────┴──────────────┬──────────────────────┐  │    │
│  │                                  │                      │  │    │
│  v                                  v                      v  │    │
│  ┌──────────────────────────────────────────────────────────┐ │    │
│  │  etcd Cluster (3x nodes - persistent store)             │ │    │
│  │  ├─ All cluster state (desired & observed)              │ │    │
│  │  ├─ Raft consensus for fault tolerance                 │ │    │
│  │  ├─ Watch API for state change notifications            │ │    │
│  │  └─ Snapshot/restore for backup                         │ │    │
│  └──────────────────────────────────────────────────────────┘ │    │
│                                                                │    │
│  ┌─────────────────────┐  ┌─────────────────────────────────┐│    │
│  │ Scheduler (2x)      │  │ Controller Manager (2x)         ││    │
│  ├─ Reads Pod specs   │  ├─ ReplicaSet Controller          ││    │
│  ├─ Evaluates nodes   │  ├─ Deployment Controller          ││    │
│  ├─ Binding decision  │  ├─ StatefulSet Controller         ││    │
│  └─ Writes binding    │  ├─ Node Controller                ││    │
│    to etcd             │  ├─ Endpoints Controller           ││    │
│                        │  └─ Service Account Controller     ││    │
│                        │  (All use leader election)          ││    │
│  ┌─────────────────────┴──────────────────────────────────┐ ││    │
│  │ Cloud Controller Manager (if cloud-provider)           │ ││    │
│  ├─ LoadBalancer services                                │ ││    │
│  ├─ Node initialization                                  │ ││    │
│  └─ Volume attachment                                    │ ││    │
│  └─────────────────────┬──────────────────────────────────┘ ││    │
│                        │                                      ││    │
└────────────────────────┼──────────────────────────────────────┘│    │
        WATCH etcd &     │                                        │    │
        POLL status      │                                        │    │
                         │                                        │    │
         ┌───────────────┴─────────────┐                         │    │
         │                             │                         │    │
         v                             v                         │    │
┌──────────────────────┐     ┌──────────────────────┐           │    │
│  WORKER NODE #1      │     │  WORKER NODE #2      │ ...       │    │
│                      │     │                      │           │    │
│  ┌──────────────────┐│     │ ┌──────────────────┐ │           │    │
│  │ Kubelet          ││     │ │ Kubelet          │ │           │    │
│  ├─ Registers node  ││     │ ├─ Registers node  │ │           │    │
│  ├─ Watches API srv ││     │ ├─ Watches API srv │ │           │    │
│  ├─ Pulls Pod specs ││     │ ├─ Pulls Pod specs │ │           │    │
│  ├─ Manages CRI     ││     │ ├─ Manages CRI     │ │           │    │
│  └─ Reports status  ││     │ └─ Reports status  │ │           │    │
│  └──────────────────┘│     │ └──────────────────┘ │           │    │
│                      │     │                      │           │    │
│  ┌──────────────────┐│     │ ┌──────────────────┐ │           │    │
│  │ Kube-proxy       ││     │ │ Kube-proxy       │ │           │    │
│  ├─ iptables/IPVS   ││     │ ├─ iptables/IPVS   │ │           │    │
│  ├─ Service VIP     ││     │ ├─ Service VIP     │ │           │    │
│  └─ Load balancing  ││     │ └─ Load balancing  │ │           │    │
│  └──────────────────┘│     │ └──────────────────┘ │           │    │
│                      │     │                      │           │    │
│  ┌──────────────────┐│     │ ┌──────────────────┐ │           │    │
│  │ Container Runtime││     │ │ Container Runtime │ │           │    │
│  │ (Docker/         ││     │ │ (Docker/          │ │           │    │
│  │ containerd)      ││     │ │ containerd)       │ │           │    │
│  └──────────────────┘│     │ └──────────────────┘ │           │    │
│                      │     │                      │           │    │
│  ┌──────────────────┐│     │ ┌──────────────────┐ │           │    │
│  │ PODS             ││     │ │ PODS              │ │           │    │
│  │                  ││     │ │                   │ │           │    │
│  │ [app-container]  ││     │ │ [app-container]   │ │           │    │
│  │ [logging-sidecar]││     │ │ [logging-sidecar] │ │           │    │
│  └──────────────────┘│     │ └──────────────────┘ │           │    │
│                      │     │                      │           │    │
└──────────────────────┘     └──────────────────────┘           │    │
        │                             │                          │    │
        └─────────────────────────────┘                          │    │
                PUSH status                                      │    │
             (lease-based heartbeat)                             │    │
                                                                 │    │
                  ↑                                              │    │
                  └──────────────────────────────────────────────│────┘
                   PULL config (watch + list)

---

## Master Components - API Server, etcd, Scheduler, Controller Manager

### Textual Deep Dive

#### API Server: Request Processing & Governance

**Internal Mechanism:**
The API server implements a sophisticated request pipeline ensuring all cluster changes are validated, authorized, and persisted atomically:

1. **TLS Termination** (port 6443)
   - mTLS validates client certificates or tokens
   - Uses CA certificate to validate kubelet, kubectl, system components

2. **Authentication** ("Who are you?")
   - Multiple strategies: x509 certificates, service account tokens, OIDC, webhook
   - Produces authenticated user identity (username, UID, groups)

3. **Authorization** ("Are you allowed?")
   - RBAC evaluates: user/serviceaccount, verb (get/list/create/delete/watch), resource, namespace
   - Returns allow/deny/no-opinion; no-opinion delegates to next authorizer

4. **Admission Control** ("Should we do this?")
   - Mutating webhooks: Modify request (inject sidecar, set defaults, add labels)
   - Validating webhooks: Reject invalid requests
   - Built-in: PodSecurityPolicy, ResourceQuota, LimitRanger, NamespaceLifecycle

5. **Etcd Write** (Atomic)
   - Validates schema (OpenAPI validation)
   - Checks resource uniqueness (no duplicate names in namespace)
   - Writes to etcd with optimistic locking (prevents concurrent modification conflicts)
   - Watch clients notified of all state changes

6. **Response** 
   - Returns created/updated resource with server-generated fields (uid, resourceVersion)

**Architecture Role:**
The API server is the **single point of truth** and **control plane gateway**. Enforces security, consistency, and authoritative state management. No component directly modifies etcd except API server.

**Production Usage:**
- **Load Balanced**: Multiple API server replicas (3-5) behind load balancer
- **Client TLS**: kubectl, kubelet, controllers all use mTLS
- **Audit Logging**: Track all API calls to etcd (WHO, WHAT, WHEN, SUCCESS/FAILURE)

#### etcd: Distributed State Machine

**Internal Mechanism:**
etcd provides **strongly-consistent replication** using Raft consensus algorithm.

```
Raft Consensus Process:

1. Client sends write request to leader
2. Leader appends entry to log
3. Leader sends AppendEntries RPC to followers
4. Followers append entry to log (uncommitted)
5. Followers acknowledge receipt
6. When majority acknowledge, leader commits entry
7. Leader notifies followers entry is committed
8. Followers apply committed entry to state machine

Result: Write visible to all servers simultaneously
```

**Critical Properties:**
- **Consensus**: Requires majority (quorum) to agree before committing write (odd numbers essential)
- **Durability**: Write only returns to client after persisted to disk
- **Ordering**: Entries applied exactly once, in order
- **Consistency**: All servers have identical state after entry commits

**Failure Tolerance:**
- 3-node cluster: tolerates 1 node failure
- 5-node cluster: tolerates 2 node failures
- 7-node cluster: tolerates 3 node failures
- **Never use even numbers**: No quorum advantage (3 vs. 4 cluster both tolerate 1 failure)

**Architecture Role:**
isé source of truth for all Kubernetes state:
- Resource definitions (Pods, Services, Deployments)
- Desired state (replica counts, update strategies)
- Observed state (pod assignments, node status)
- Configuration (ConfigMaps, Secrets)

**Production Usage Patterns:**

1. **Separate etcd Cluster**
   - Not colocated with other control plane components
   - Prevents I/O interference
   - Enables independent scaling

2. **Multi-Zone Distribution**
   - Spread across availability zones
   - Survives complete zone failure
   - Monitor network latency: Raft sensitive to latency spikes

3. **Snapshot & Restore**
   ```bash
   # Create snapshot
   etcdctl --endpoints=https://etcd.example.com:2379 snapshot save backup.db
   
   # Restore from snapshot
   etcdctl snapshot restore backup.db --data-dir=/var/lib/etcd-new
   ```

**Common Pitfall: etcd Performance Degradation**
- Symptom: API server becomes slow, watch events lag
- Root causes:
  - Missing disk fsync (data persisted but acknowledged prematurely)
  - Network latency > 100ms between replicas
  - Compaction disabled (etcd size grows unbounded)
  - CRD explosion (thousands of CR instances per namespace)
- Solution: Monitor etcd latency, implement revision history cleanup, consider watch-only etcd proxy

#### Scheduler: Intelligent Pod Placement

**Internal Mechanism:**
The scheduler continuously watches for unscheduled Pods and evaluates which node each should run on.

```
Scheduling Cycle:

1. [Infeasible Phase] Filter nodes
   - Node has labels matching nodeSelector? YES
   - Pod fits in available resources (CPU, memory)? YES  
   - Pod tolerates node taints? YES
   → Feasible node set

2. [Scoring Phase] Rank feasible nodes
   - Prefer nodes with more available resources (resource efficiency)
   - Prefer nodes not running pod replicas (anti-affinity)
   - Prefer node affinity preferred expressions
   → Score nodes 0-100

3. [Selection Phase] Pick highest score
   - Ties broken by:
     - Least Pod count (spreads load)
     - Random selection among identical scores
   → Binding decision

4. [Binding Phase] Atomically write Pod → Node assignment
   → kubelet now sees Pod and begins container startup
```

**Constraints Evaluated:**

| Constraint | Type | Effect |
|-----------|------|--------|
| nodeSelector | Hard | Pod only schedules if labels match |
| NodeAffinity (required) | Hard | Pod only on nodes matching expression |
| NodeAffinity (preferred) | Soft | Prefer nodes, but override if needed |
| PodAffinity | Hard/Soft | Co-locate Pods on same node |
| PodAntiAffinity | Hard/Soft | Spread Pods across different nodes |
| Taints & Tolerations | Hard | Block Pods without matching toleration |
| PodDisruptionBudget | Soft | Prevent eviction; advisory only |

**Production Constraints & Considerations:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: production-pod
spec:
  # Hard constraint: Pod ONLY on these nodes
  nodeSelector:
    workload: prod
  
  affinity:
    # Hard: Pod only on nodes with "zone: us-east-1a"
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: zone
            operator: In
            values: ["us-east-1a"]
    
    # Soft: Prefer spreading replicas across different nodes
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values: ["my-app"]
          topologyKey: kubernetes.io/hostname
  
  # Must have matching tolerations to schedule on tainted nodes
  tolerations:
  - key: gpu
    operator: Equal
    value: "true"
    effect: NoSchedule
  
  # Resource requirements guide scheduler AND kubelet
  containers:
  - name: app
    resources:
      requests:
        cpu: "1"
        memory: "2Gi"
      limits:
        cpu: "2"
        memory: "4Gi"
```

**Common Pitfall: CPU/Memory Requests Don't Match Reality**
- Symptom: Pods pending despite available "capacity"
- Cause: Requests too optimistic; actual usage lower
- Solution: Monitor actual resource usage; adjust requests to match production metrics

#### Controller Manager: Self-Healing Orchestration

**Internal Mechanism:**
Controller manager runs multiple **independent control loops** (controllers), each responsible for specific resource type.

```
Control Loop Pattern (runs continuously for each controller):

1. Watch API server for changes to resource type (e.g., Deployments)
2. For each change:
   a. Read current state from API server
   b. Compare with desired state
   c. If different, take corrective action
      - Create missing Pods
      - Delete extra replicas
      - Update Pod template
   d. Write updated status back to API server
3. Repeat forever (watches are long-lived; new watch on reconnect)
```

**Key Controllers & Responsibilities:**

| Controller | Watches | Action | Example |
|-----------|---------|--------|----------|
| ReplicaSet | ReplicaSets, Pods | Creates/deletes Pods to match replica count | Ensures 3 copies always running |
| Deployment | Deployments, ReplicaSets | Creates new RS on update, scales old RS down | Rolling updates, version control |
| StatefulSet | StatefulSets, Pods | Ordered, stable Pod names and identity | Databases, distributed storage |
| DaemonSet | DaemonSets, Pods | One Pod per eligible node | Logging agents, monitoring, networking |
| Job | Jobs, Pods | Runs Pods to completion (one or more) | Batch processing, one-off tasks |
| CronJob | CronJobs, Jobs | Creates Jobs on schedule | Scheduled tasks, reports, backups |
| Service | Services, Endpoints | Updates Endpoints as Pods come/go | Load balancing across Pods |
| Node | Nodes, Pods | Evicts Pods during node failure | Failure recovery, eviction policies |

**Production Usage Example: Deployment Rolling Update**

```
Original State:
- Deployment "web-app" desired replicas: 3
- ReplicaSet (v1) owns 3 Pods all running v1.0

User runs: kubectl set image deployment/web-app app=myv2.0

Controller Actions:
1. Creates new ReplicaSet (v2) with updated template
2. Scales v2 ReplicaSet up: 0→1 Pod
3. Waits for v2 Pod ready
4. Scales v1 ReplicaSet down: 3→2 Pods
5. Repeats: 1→2, then 2→1, then 2→3, then 1→0
6. Old v1 ReplicaSet retained for rollback

Result: 0 downtime, controlled replacement of Pods
```

**Leader Election: Preventing Concurrent Decisions**
When multiple controller manager replicas run, they use **leader election** to ensure only one actively makes decisions:

```
1. Each instance tries to acquire lease in API server
2. First to acquire becomes leader
3. Leader renews lease periodically (heartbeat)
4. If leader fails (lease expires), another instance becomes leader
5. Prevents duplicate Pod creation, conflicting decisions
```

### Practical Examples

#### Monitoring etcd Health

```bash
#!/bin/bash
# Check etcd cluster status
etcdctl member list

# Monitor etcd latency (p99 should be < 25ms)
etcdctl endpoint health
etcdctl endpoint status

# Check database size
etcdctl endpoint status --write-out=table

# Compact history to free space
# Get latest revision first
REV=$(etcdctl endpoint status --write-out=json | jq '.header.revision')

# Compact older revisions
etcdctl compact $((REV - 100000))

# Defragment after compaction
etcdctl defrag
```

#### Custom Scheduler Configuration

```yaml
# scheduler-config.yaml - Custom scoring plugin
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
  plugins:
    preFilter:
      enabled:
      - name: "NodeAffinity"
      - name: "TaintToleration"
    filter:
      enabled:
      - name: "NodeAffinity"
      - name: "TaintToleration"
      - name: "ResourceFit"
    score:
      enabled:
      - name: "NodeAffinity"
        weight: 100
      - name: "NodeResourcesFit"
        weight: 50
      - name: "ImageLocality"
        weight: 25
```

#### Controller Manager Configuration for HA

```bash
#!/bin/bash
# Start multiple controller manager replicas with leader election
# (Kubernetes automatically configures leader election)

kube-controller-manager \
  --kubeconfig=/etc/kubernetes/controller-manager.conf \
  --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt \
  --cluster-signing-key-file=/etc/kubernetes/pki/ca.key \
  --leader-elect=true \
  --leader-elect-namespace=kube-system \
  --leader-elect-id=kube-controller-manager \
  --use-service-account-credentials=true \
  --v=2
```

### Disaster Recovery: etcd Snapshot

```bash
#!/bin/bash
# Automated etcd backup script for production

BACKUP_DIR="/backups/etcd"
RETENTION_DAYS=30
ETCD_ENDPOINT="https://etcd-server:2379"
ETCD_CERT="/etc/kubernetes/etcd-client.crt"
ETCD_KEY="/etc/kubernetes/etcd-client.key"
ETCD_CA="/etc/kubernetes/etcd-ca.crt"

# Create backup
BACKUP_FILE="${BACKUP_DIR}/etcd-$(date +%Y%m%d-%H%M%S).db"
etcdctl --endpoints=$ETCD_ENDPOINT \
  --cert=$ETCD_CERT \
  --key=$ETCD_KEY \
  --cacert=$ETCD_CA \
  snapshot save $BACKUP_FILE

# Verify backup integrity
etcdctl snapshot status $BACKUP_FILE

# Upload to S3
aws s3 cp $BACKUP_FILE s3://my-backups/etcd/

# Cleanup old backups
find $BACKUP_DIR -name "etcd-*.db" -mtime +$RETENTION_DAYS -delete
```

### Scheduler Testing

```bash
#!/bin/bash
# Test scheduler behavior with different node conditions

# Create test nodes with different labels
kubectl label node node-1 workload=batch
kubectl label node node-2 workload=prod

# Pod with hard constraint
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: batch-pod
spec:
  nodeSelector:
    workload: batch
  containers:
  - name: app
    image: busybox
    command: ["sleep", "3600"]
EOF

# Check scheduling result
kubectl get pod batch-pod -o wide
kubectl describe pod batch-pod

# Test affinity preferences
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread-test
spec:
  replicas: 3
  selector:
    matchLabels:
      app: spread
  template:
    metadata:
      labels:
        app: spread
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - spread
            topologyKey: kubernetes.io/hostname
      containers:
      - name: app
        image: busybox
EOF

# Verify pods spread across nodes
kubectl get pods -o wide -l app=spread
```

### ASCII Diagrams

#### API Server Request Pipeline

```
┌──────────────────────────────────────────────────────────────┐
│                      CLIENT REQUEST                          │
│           (kubectl, kubelet, controller, webhook)           │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │   TLS Termination             │
        │   (mTLS, x509 validation)    │
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │  Authentication               │
        │  (Who are you?)               │
        │  → x509, token, OIDC, webhook│
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │  Authorization (RBAC/ABAC)    │
        │  (Are you allowed?)           │
        │  User×Verb×Resource×Namespace│
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │   Admission Control           │
        │   (Should we allow this?)     │
        │   → Mutating (modify)         │
        │   → Validating (reject)       │
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │   OpenAPI Schema Validation   │
        │   (Valid resource spec?)      │
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │   ATOMIC ETCD WRITE           │
        │   (Persist desired state)     │
        │   → Optimistic locking        │
        │   → Resource versioning       │
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │   NOTIFICATION                │
        │   (watchers notified)         │
        │   → Controllers see change    │
        │   → kubelet sees change       │
        └───────────────┬───────────────┘
                        │
                        v
        ┌───────────────────────────────┐
        │   RESPONSE TO CLIENT          │
        │   (resource + server fields)  │
        │   → uid, resourceVersion      │
        │   → status.phase              │
        └───────────────┬───────────────┘
                        │
                        v
        [Controllers use watch to observe and act]
        [Kubelet continuously reconciles assigned pods]
        [Scheduler binds pods to nodes]
```

#### etcd Replication Across Zones

```
                   KUBERNETES CLUSTER
         (Multi-zone for disaster recovery)

┌──────────────────────────────────────────────────────┐
│                                                      │
├──────────────── Zone A ──────────────┬──────────────┤
│                                      │              │
│  API Server #1                       │ etcd Node #1 │
│    ↓                                 │ (leader)     │
│  [validate→auth→admit→write etcd]   │              │
│                                      │ Latency: 5ms │
└──────────────────────────────────────┼──────────────┘
          ↓                             ↓    ↑
       [TLS mTLS]                [Raft RPC]
          ↓                             ↓    ↑
┌──────────────── Zone B ──────────────┼──────────────┐
│                                      │              │
│  API Server #2                       │ etcd Node #2 │
│    ↓                                 │ (follower)   │
│  [validate→auth→admit→write etcd]   │              │
│                                      │ Latency: 8ms │
└──────────────────────────────────────┼──────────────┘  
          ↓                             ↓    ↑
       [TLS mTLS]                [Raft RPC]
          ↓                             ↓    ↑
┌──────────────── Zone C ──────────────┼──────────────┐
│                                      │              │
│  API Server #3                       │ etcd Node #3 │
│    ↓                                 │ (follower)   │
│  [validate→auth→admit→write etcd]   │              │
│                                      │ Latency: 10ms│
└──────────────────────────────────────┴──────────────┘

Consensus: 3 nodes = quorum 2 = tolerate 1 failure
All writes go through leader → AppendEntries to followers
Once 2 nodes acknowledge → committed → applied to state machine
```

#### Scheduler Placement Decision Tree

```
              UNSCHEDULED POD ARRIVES
                        │
                        v
          ┌─────────────────────────────┐
          │  [FILTER PHASE]             │
          │  Does node satisfy Pod      │
          │  requirements?              │
          └─────────────────────────────┘
                   YES   │   NO
                        │
        ┌───────────────┴─────────────────┐
        │                                 │
        v                                 v
   ┌─────────────────┐              [Try next node]
   │ Has label match?│
   └─────────────────┘
        YES   │   NO
           ┌──┴──┐
           │     → FILTER OUT
           v
    ┌──────────────────┐
    │ Fits CPU/Memory? │
    └──────────────────┘
        YES   │   NO
           ┌──┴──┐
           │     → FILTER OUT
           v
    ┌──────────────────┐
    │ Toleration match?│
    └──────────────────┘
        YES   │   NO
           ┌──┴──┐
           │     → FILTER OUT
           v
   ┌──────────────────────────────┐
   │ NODE IS FEASIBLE             │
   │ (Passes all hard constraints)│
   └────────────┬─────────────────┘
                │
        [Continue filtering other nodes]
                │
                v
   ┌──────────────────────────────┐
   │  [SCORING PHASE]             │
   │  Rank all feasible nodes     │
   └──────────────────────────────┘
     ↓                             ↓
 [soft preferences]          [ranking algorithm]
 - PodAffinity weight           score 0-100
 - NodeAffinity preference      per node
 - Spread preference
     ↓                             ↓
   ┌──────────────────────────────┐
   │  [SELECTION PHASE]           │
   │  Pick highest score          │
   │  (ties = random)             │
   └──────────────────────────────┘
           │
           v
   ┌──────────────────────────────┐
   │  [BINDING PHASE]             │
   │  Write Pod.spec.nodeName     │
   │  Atomically in API server    │
   └──────────────────────────────┘
           │
           v
   [Kubelet sees Pod, starts container]
```

---

## Node Components - Kubelet, Kube Proxy, Container Runtime

### Textual Deep Dive

#### Kubelet: Node Agent & Pod Manager

**Internal Mechanism:**
Kubelet runs continuously on each worker node, acting as the node's local orchestrator.

**Kubelet Lifecycle:**

```
1. [Node Registration]
   - Register node with API server
   - Report node capacity (CPU, memory, disk)
   - Apply node labels (zone, instance-type, etc.)
   - Create node lease (heartbeat)

2. [Pod Watch Loop]
   - Watch API server: "Give me Pod specs for this node"
   - Also check static Pod manifests (/etc/kubernetes/manifests)
   - Build desired Pod set

3. [Pod Reconciliation Loop] (runs continuously)
   a. Compare desired Pods (from API server) vs. actual containers
   b. For each missing Pod: pull image, start containers
   c. For each extra container: stop it
   d. Monitor containers: health probes (liveness, readiness)
   e. Report Pod status back to API server
   f. Handle Pod termination gracefully

4. [Eviction Monitor]
   - Monitor node resource pressure (CPU, memory, disk, PIDs)
   - If resources below thresholds, evict lower-priority Pods
   - Trigger kubelet restart if critical resources exhausted
```

**Critical Kubelet Responsibilities:**

| Responsibility | Mechanism | Purpose |
|---|---|---|
| **Node Registration** | Create Node object in API server | Cluster visibility, capacity tracking |
| **Pod Admission** | Validate pod spec locally | Prevent node from loading impossible pods |
| **Image Management** | Pull image from registry | Prerequisite for container startup |
| **Container Management** | Interface with CRI | Actual container lifecycle |
| **Health Monitoring** | Execute liveness/readiness probes | Detect unhealthy containers |
| **Resource Limits** | Set cgroup limits on containers | Prevent runaway resource usage |
| **Volume Management** | Mount/unmount volumes to pods | Persistent storage access |
| **Status Reporting** | Update Pod.status in API server | Controllers know Pod state |
| **Graceful Shutdown** | Drain Pods during node termination | Minimize connection disruption |

**Production Usage Patterns:**

1. **Health Probes for Intelligent Load Balancing**
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: app-pod
   spec:
     containers:
     - name: app
       image: myapp:v1
       
       # Liveness: "Is the app still working?"
       # If fails 3x, kubelet restarts container
       livenessProbe:
         httpGet:
           path: /healthz
           port: 8080
         initialDelaySeconds: 10
         periodSeconds: 10
         failureThreshold: 3
       
       # Readiness: "Is the app ready for traffic?"
       # If fails, remove from load balancer (Service endpoints)
       readinessProbe:
         httpGet:
           path: /ready
           port: 8080
         initialDelaySeconds: 5
         periodSeconds: 5
   ```

2. **Resource Limits Preventing Node Degradation**
   ```yaml
   resources:
     requests:      # What kubelet reserves (guide for scheduler)
       cpu: "500m"  # 0.5 CPU cores
       memory: "256Mi"
     limits:        # Hard cap enforced by cgroup (OOM kills if exceeded)
       cpu: "1"
       memory: "512Mi"
   ```

3. **Static Pods for Control Plane Reliability**
   ```bash
   # Place manifest in /etc/kubernetes/manifests
   # Kubelet automatically starts, monitors, restarts
   # (No API server dependency)
   
   cat > /etc/kubernetes/manifests/etcd.yaml <<EOF
   apiVersion: v1
   kind: Pod
   metadata:
     name: etcd-server
   spec:
     containers:
     - name: etcd
       image: k8s.gcr.io/etcd:3.5.0
       command:
       - etcd
       - --listen-client-urls=https://127.0.0.1:2379
       volumeMounts:
       - name: etcd-data
         mountPath: /var/lib/etcd
     volumes:
     - name: etcd-data
       hostPath:
         path: /var/lib/etcd
   EOF
   ```

**Common Pitfall: CRI Unavailable**
- Symptom: All Pods stuck in "ContainerCreating", none ever ready
- Root cause: Container runtime (Docker/containerd) not running or misconfigured
- Debug: `kubectl describe node` shows "NotReady"; `kubelet logs` show CRI errors
- Fix: Restart container runtime; check kubelet configuration

#### Kube-Proxy: Service Load Balancing

**Internal Mechanism:**
Kube-proxy implements Service abstraction (virtual IPs) using kernel-level routing rules.

```
Service Abstraction Without Kube-Proxy:
┌──────────────────┐
│ My Pod (10.0.1.5)│
│                  │
│ My Pod (10.0.2.7)│
│                  │
│ My Pod (10.0.3.3)│
└──────────────────┘
   (3 real IPs, constantly changing)
   → Impossible for clients to track
   → Need stable endpoint


With Kube-Proxy:
┌──────────────────────────────────────────────┐
│     Service VIP (10.96.0.100:80)             │
│     (Stable, single entry point)             │
│           ↓                                  │
│  [kube-proxy iptables rules]                │
│  │   Destination NAT (DNAT)                 │
│   → 10.0.1.5:80   (40% of packets)          │
│   → 10.0.2.7:80   (30% of packets)          │
│   → 10.0.3.3:80   (30% of packets)          │
└──────────────────────────────────────────────┘
```

**Kube-Proxy Modes:**

1. **iptables Mode** (default, stable)
   - Uses kernel iptables rules (Linux in-kernel packet filter)
   - Each Service rule chains multiple endpoints
   - Stateless: kernel handles routing automatically
   - Limitation: Large number of services (>5000) degrades linearly
   - Randomness: iptables random DNAT mode for load spreading

2. **IPVS Mode** (better scalability)
   - Uses Linux IPVS (IP Virtual Server, kernel LB)
   - Hash table lookups (O(1) complexity), scales to 40k+ services
   - Better RoundRobin algorithms (consistent hashing available)
   - Requires `ip_vs` kernel module
   - Production choice for large-scale clusters

3. **userspace Mode** (legacy, deprecated)
   - kube-proxy userspace process intercepts traffic (slow)
   - Only fallback if kernel modules unavailable
   - Overhead: context switch to userspace

**Architecture Role:**
- Maps Service VIP → Pod IPs (load balancing)
- Enables Pod-to-Pod communication (via ClusterIP services)
- Implements external LoadBalancer traffic routing
- Combines with CNI plugin for full networking

**Production Configuration:**

```bash
#!/bin/bash
# Configure kube-proxy for high-scale cluster

cat > /etc/kubernetes/kube-proxy-config.yaml <<EOF
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs  # IPVS for >5k services
ipvs:
  strictARP: true  # For ARP-based load balancing
  scheduler: "sh"  # Shortest hash (good distribution)
clusterCIDR: "10.0.0.0/8"
EOF

kube-proxy --config=/etc/kubernetes/kube-proxy-config.yaml
```

**Common Pitfall: Service Latency Spikes**
- Symptom: Occasional 10-100ms latency on requests to Service VIP
- Root cause: iptables rule lookup scales linearly with rule count
- Solution: Migrate to IPVS mode

#### Container Runtime Interface (CRI)

**Architecture Role:**
CRI abstracts container runtime from Kubernetes, allowing pluggable implementations.

**CRI-Compliant Runtimes:**

| Runtime | Characteristics | Use Case |
|---------|---|---|
| **Docker** | Industry standard, full-featured | Traditional (being phased out in K8s) |
| **containerd** | Minimal, fast, CNCF graduated | Production standard, cloud-native |
| **CRI-O** | Lightweight Kubernetes-specific | Production where minimal overhead critical |
| **rkt** | Security-focused, pod-native | Deprecated but available |

**CRI Methods Called by Kubelet:**

```protobuf
// Pull image from registry
PullImage(image: string) → ImageID

// Create container from image
CreateContainer(config: ContainerConfig) → ContainerID

// Start previously created container
StartContainer(containerID: string)

// Stop container gracefully
StopContainer(containerID: string, timeout: Duration)

// Remove container
RemoveContainer(containerID: string)

// Get container status (running, exited, etc.)
ContainerStatus(containerID: string) → Status

// Execute command inside container
ExecSync(containerID: string, cmd: string) → output

// Stream logs
GetContainerLogs(containerID: string) → LogResponse
```

**Image Pull Secrets:**
Kubelet must authenticate to private registries:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: dockercfg
type: kubernetes.io/dockercfg
data:
  .dockercfg: eyJyZWdpc3RyeS5leGFtcGxlLmNvbSI...  # base64-encoded
---
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  imagePullSecrets:
  - name: dockercfg
  containers:
  - name: app
    image: registry.example.com/my-app:v1.0
```

**Common Pitfall: Image Pull Backoff**
- Symptom: Pod stuck in "ImagePullBackOff"
- Root causes:
  - Credentials missing or invalid (imagePullSecrets)
  - Image doesn't exist or typo in image name
  - Registry network unreachable
  - Container runtime not running
- Debug: `kubectl describe pod` shows pull error details

#### Node Lifecycle & Graceful Shutdown

**Node States:**

```
Node lifecycle:

1. [Uninitialized]
   ↓ (manifest placed, kubelet starts)
2. [NotReady]
   - Container runtime initializing
   - Network plugin not ready
   ↓ (all components ready)
3. [Ready]
   - Node operational
   - Pods can schedule
   ↓ (kubectl delete node, or shutdown)
4. [NotReady → TerminatingPhase]
   - Kubelet begins graceful shutdown
   - No new pods scheduled
   - Evicts existing pods
   ↓
5. [Deleted]
```

**Graceful Node Drain Procedure:**

```bash
#!/bin/bash
# SafelyPrepare node for maintenance

# 1. Cordon: Stop new pods from scheduling
kubectl cordon node-1

# 2. Drain: Evict ALL pods
kubectl drain node-1 \
  --ignore-daemonsets \            # Don't evict DaemonSet pods (node-local)
  --delete-emptydir-data \         # OK to delete emptyDir volumes
  --grace-period=300 \             # 5 min for pods to terminate gracefully
  --timeout=600s

# 3. Maintenance (upgrade kubelet, update kernel, etc.)
# ...

# 4. Uncordon: Resume pod scheduling
kubectl uncordon node-1
```

**How Graceful Termination Works:**

```
1. kubelet receives termination signal
2. kubelet sends SIGTERM to containers
3. Containers have gracePeriod (default 30s) to shut down
   - App stops accepting new connections
   - Existing connections complete (connection draining)
   - Logs flushed, resources released
4. If not terminated after gracePeriod, SIGKILL sent
5. Pod removed from API server
```

**Application Implementation:**

```python
# Flask app with graceful shutdown handler
import signal
import sys
from flask import Flask

app = Flask(__name__)

def handle_sigterm(sig, frame):
    """Gracefully handle SIGTERM from kubelet."""
    print("SIGTERM received, beginning graceful shutdown...")
    # Stop accepting new requests
    # Wait for in-flight requests to complete
    # Close database connections
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_sigterm)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

#### Resource Management & Eviction Policies

**QoS Classes:**
Kubernetes categorizes pods based on resource configurations:

| QoS Class | Definition | Eviction Priority |
|-----------|---|---|
| **Guaranteed** | All containers have requests = limits | Never evicted (unless node dies) |
| **Burstable** | Container limits > requests (can burst) | Evicted if node under pressure |
| **BestEffort** | No requests/limits | Evicted first when pressure detected |

```yaml
# Guaranteed Pod (never evicted)
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed
spec:
  containers:
  - name: app
    image: myapp:v1
    resources:
      requests:
        cpu: "1"
        memory: "1Gi"
      limits:
        cpu: "1"        # Same as requests
        memory: "1Gi"   # Same as requests

---
# Burstable Pod (evicted if node pressure)
apiVersion: v1
kind: Pod
metadata:
  name: burstable
spec:
  containers:
  - name: app
    image: myapp:v1
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "1"        # Higher than requests
        memory: "1Gi"   # Higher than requests

---
# BestEffort Pod (evicted first)
apiVersion: v1
kind: Pod
metadata:
  name: besteffort
spec:
  containers:
  - name: app
    image: myapp:v1
    # No requests or limits
```

**Eviction Thresholds:**

```bash
# Kubelet monitors these signals
kubelet \
  --eviction-soft="memory.available<2Gi,nodefs.available<10Gi" \
  --eviction-soft-grace-period="memory.available=1m,nodefs.available=2m" \
  --eviction-hard="memory.available<500Mi,nodefs.available<1Gi" \
  --eviction-max-pod-grace-period=30
```

When soft threshold exceeded with grace period elapsed, evict lowest-QoS pods.
When hard threshold exceeded, immediately evict.

### Practical Examples

#### Monitoring Kubelet Health

```bash
#!/bin/bash
# Check kubelet status on node

kubectl get node node-1 -o yaml | grep -A 20 "status:"

# Check Node readiness condition
kubectl get node node-1 | grep -E "NAME|Ready"

# Detailed node information
kubectl describe node node-1

# Check kubelet logs (if systemd)
sudo journalctl -u kubelet -n 100 --no-pager

# Check kubelet metrics
curl http://localhost:10255/stats/summary

# Check Kubelet API metrics (Prometheus format)
curl http://localhost:10255/metrics
```

#### Testing Eviction Policies

```bash
#!/bin/bash
# Create pods to test eviction behavior

# High-priority guaranteed pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: critical-app
spec:
  priorityClassName: system-cluster-critical
  containers:
  - name: app
    image: busybox
    resources:
      requests:
        cpu: "1"
        memory: "256Mi"
      limits:
        cpu: "1"
        memory: "256Mi"
    command: ["sleep", "3600"]
EOF

# Low-priority besteffort pod (will be evicted)
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: background-job
spec:
  containers:
  - name: job
    image: busybox
    command: ["sh", "-c", "while true; do dd if=/dev/zero; done"]
EOF

# Monitor evictions
watch kubectl get pods --all-namespaces -o wide

# Check eviction events
kubectl describe pod background-job
```

#### Service Load Balancing Verification

```bash
#!/bin/bash
# Test kube-proxy service load balancing

# Create service with multiple backends
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: app
        image: mynginx:1.0
        ports:
        - containerPort: 8080
EOF

# Check Service endpoints
kubectl get endpoints backend
kubectl get service backend -o wide

# Test load balancing from pod
kubectl run -it --rm curl --image=curlimages/curl --restart=Never -- \
  sh -c 'for i in {1..10}; do curl backend; echo ""; done'

# Verify iptables rules (on node)
sudo iptables-save | grep backend

# Check IPVS rules (if using IPVS mode)
sudo ipvsadm -L -n
```

### ASCII Diagrams

#### Kubelet Pod Reconciliation Loop

```
┌──────────────────────────────────────────────────────┐
│       KUBELET POD RECONCILIATION LOOP (continuous)  │
└──────────────────────────────────────────────────────┘

     ↑                                          ┌─ 10s refresh
     │    (Every 10 seconds, or on API watch)  │
     │                                          └─ API watcher
┌────┴─────────────────────────────────────────────┐
│  1. READ DESIRED STATE                           │
│     - Watch API server for Pod assignments      │
│     - Check /etc/kubernetes/manifests (static) │
│     → Desired Pod set                           │
└────────┬─────────────────────────────────────────┘
         │
         v
┌──────────────────────────────────────────────────┐
│  2. READ ACTUAL STATE                            │
│     - Query CRI for running containers           │
│     - Check local volumes                        │
│     - Check health probe results                │
│     → Actual container set                       │
└──────────┬───────────────────────────────────────┘
           │
           v
┌──────────────────────────────────────────────────┐
│  3. COMPARE STATES                               │
│     - Desired ≠ Actual?                          │
│       YES: Take action (below)                   │
│       NO:  Wait for next iteration               │
└──────────┬───────────────────────────────────────┘
           │
     ┌─────┴────────┬────────────────┬─────────────┐
     │              │                │             │
     v              v                v             v
┌──────┐      ┌────────┐      ┌──────────┐   ┌─────────┐
│PULL  │      │CREATE  │      │UPDATE    │   │DELETE   │
│IMAGE │      │CONT.   │      │POLICY    │   │CONT.    │
│      │      │        │      │          │   │         │
│ CRI  │      │ CRI    │      │ CRI      │   │ CRI     │
└──────┘      └────────┘      └──────────┘   └─────────┘
     │              │                │             │
     └──────────────┴────────────────┴─────────────┘
                    │
                    v
         ┌────────────────────────┐
         │  4. HEALTH MONITORING  │
         │  - Liveness probe      │
         │  - Readiness probe     │
         │  - Startup probe       │
         │  (Every 10-30 seconds) │
         └────────────┬───────────┘
                      │
                      v
         ┌────────────────────────┐
         │  5. STATUS REPORTING   │
         │  - Pod.status phase    │
         │  - Container states    │
         │  - Condition messages  │
         │  → Write to API server │
         └────────────┬───────────┘
                      │
                      ↑ (loop back to step 1)
```

#### Service to Pod Routing (iptables mode)

```
┌────────────────────────────────────────────────────────────┐
│  CLIENT SENDS PACKET TO SERVICE VIP 10.96.0.100:80        │
└───────────────────────┬──────────────────────────────────┘
                        │
                        v
          ┌─────────────────────────────────────┐
          │ Kernel Network Stack                │
          │ (iptables DNAT rule)                │
          │                                     │
          │ Destination: 10.96.0.100:80         │
          │      ↓ (iptables DNAT)              │
          │ Replace with Pod IP + port          │
          └─────────────────────────────────────┘
                        │
     ┌──────────────────┼──────────────────┐
     │                  │                  │
     → Randomly select (iptables random) → Round-robin partition
     │                  │                  │
     v                  v                  v
┌──────────┐      ┌──────────┐      ┌──────────┐
│Pod A     │      │Pod B     │      │Pod C     │
│10.0.1.5  │      │10.0.2.7  │      │10.0.3.3  │
│:8080     │      │:8080     │      │:8080     │
│          │      │          │      │          │
│ request  │      │ request │       │ request │
│ handled  │      │ handled │       │ handled │
└──────────┘      └──────────┘      └──────────┘
     │                  │                  │
     └──────────────────┼──────────────────┘
                        │
                        v
         ┌─────────────────────────────┐
         │ Kernel (reverse SNAT)       │
         │ Reply packets → Service VIP │
         │ Client sees response from   │
         │ 10.96.0.100 (stable!)      │
         └─────────────────────────────┘
                        │
                        v
         ┌─────────────────────────────┐
         │ CLIENT RECEIVES RESPONSE    │
         │ FROM SERVICE VIP (stable)   │
         │                             │
         │ Actual backend transparent  │
         │ to client                   │
         └─────────────────────────────┘
```

#### Node Drain Graceful Shutdown

```
┌────────────────────────────────────────────────┐
│  kubectl drain node-1                          │
└────────────────────┬───────────────────────────┘
                     │
                     v
         ┌───────────────────────────┐
         │ 1. CORDON NODE            │
         │ Mark as SchedulingDisabled│
         │ No NEW pods scheduled     │
         └───────────────┬───────────┘
                         │
                         v
         ┌───────────────────────────┐
         │ 2. LIST ALL PODS          │
         │ On this node              │
         │ Except DaemonSet pods     │
         └───────────────┬───────────┘
                         │
         ┌───────────────┴─────────────┐
         │                             │
     For each Pod:                 For each Pod:
         │                             │
         v                             v
    ┌────────────┐              ┌────────────┐
    │Pod A       │              │Pod B       │
    │PDB allows  │              │PDB forbids │
    │eviction    │              │eviction    │
    └──────┬─────┘              └──────┬─────┘
           │                          │
           v                          v
     ┌──────────┐              ┌──────────┐
     │Evict OK  │              │ Skip     │
     │Send      │              │(or force)│
     │delete    │              └──────────┘
     └────┬─────┘
          │
          v
     ┌──────────────────────┐
     │ POD TERMINATION      │
     │ 1. Container SIGTERM │
     │ 2. Grace period 30s  │
     │ 3. SIGKILL if needed │
     │ 4. Pod removed from  │
     │    API server        │
     │ 5. Kubelet reports   │
     │    removal           │
     └──────────┬───────────┘
                │ (repeat for all eligible pods)
                │
                v
     ┌──────────────────────┐
    │ NODE EMPTIED          │
     │ Ready for maintenance│
     └──────────┬───────────┘
                │
       (perform upgrades)
                │
                v
     ┌──────────────────────┐
     │ kubectl uncordon     │
     │ Resume pod schedule  │
     └──────────────────────┘
```

---

## kubeconfig and Cluster Access Management

### Textual Deep Dive

#### kubeconfig Structure & Architecture

**Purpose:**
kubeconfig files bridge the gap between client workstations/CI/CD systems and Kubernetes clusters by providing:
- Cluster endpoints (API server address)
- Authentication credentials (certificates, tokens, OAuth)
- Context bundles linking user+cluster+namespace

**File Location & Precedence:**
```bash
# kubectl searches in order:
1. --kubeconfig flag (highest priority)
2. KUBECONFIG env var (file paths, colon-separated on Unix, semicolon on Windows)
3. ~/.kube/config (default location)

# Combine multiple kubeconfigs
export KUBECONFIG=~/.kube/config:~/.kube/prod-config:~/.kube/staging-config
kubectl config view --merge  # Shows merged config
```

**kubeconfig Anatomy:**

```yaml
apiVersion: v1
kind: Config

# Multiple cluster definitions
clusters:
- name: production-us-east
  cluster:
    server: https://api.prod.example.com:6443    # API server endpoint
    certificate-authority: /path/to/ca.crt       # Trust CA for server certificate
    certificate-authority-data: LS0tLS1CRUdJTi... # OR base64-encoded CA cert
    insecure-skip-tls-verify: false            # NEVER true in production

- name: development-local  
  cluster:
    server: https://localhost:6443
    certificate-authority-data: LS0tLS1CRUdJTi...

# Multiple user/credential definitions
users:
- name: admin@production
  user:
    client-certificate: /path/to/client.crt       # x509 client cert
    client-key: /path/to/client.key              # Client private key
    # OR
    client-certificate-data: LS0tLS1CRUdJTi...   # base64-encoded cert
    client-key-data: LS0tLS1CRUdJTi...

- name: ci-system
  user:
    token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... # Bearer token

- name: dev-oidc
  user:
    exec:                                         # External identity provider
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args: ["eks", "get-token", "--cluster-name", "my-cluster"]

# Contexts bundle: cluster + user + namespace
contexts:
- name: production-us-east  
  context:
    cluster: production-us-east          # From clusters[] name
    user: admin@production              # From users[] name
    namespace: default                  # Default namespace for commands

- name: development-local
  context:
    cluster: development-local
    user: dev-oidc
    namespace: kube-system

# Current active context
current-context: production-us-east
```

**kubeconfig Operations:**

```bash
# View merged config from all sources
kubectl config view

# Switch context
kubectl config use-context development-local
kubectl config current-context

# Add new cluster
kubectl config set-cluster staging \
  --server=https://staging.example.com:6443 \
  --certificate-authority=/path/to/ca.crt

# Create context
kubectl config set-context staging-admin \
  --cluster=staging \
  --user=admin

# List all contexts
kubectl config get-contexts
```

#### Authentication Methods

**Method 1: x509 Client Certificates**

Most common for human operators and stateful services.

```bash
#!/bin/bash
# Generate client certificate key pair

# 1. Private key
openssl genrsa -out user.key 2048

# 2. Certificate signing request (CSR)
openssl req -new \
  -key user.key \
  -out user.csr \
  -subj "/CN=alice@example.com/O=developers"
  # CN = username (extracted by API server)
  # O = group (extracted by API server)

# 3. Sign with cluster CA (Kubernetes CA, not public PKI)
kubectl certificate approve <csr-name>  # CSR object in API server
# OR manually
openssl x509 -req \
  -in user.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -CAcreateserial \
  -out user.crt \
  -days 365

# 4. Add to kubeconfig
kubectl config set-credentials alice \
  --client-certificate=user.crt \
  --client-key=user.key
```

**Method 2: Service Account Tokens**

For pods and CI/CD systems (automated access).

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-deployer
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployer
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployer-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployer
subjects:
- kind: ServiceAccount
  name: ci-deployer
  namespace: default
```

```bash
# Extract token for CI/CD (Kubernetes 1.24+)
token=$(kubectl create token ci-deployer --duration=24h)
echo $token | base64 -d | jq  # Inspect JWT claims

# Kubernetes 1.23 and earlier (legacy)
secret=$(kubectl get secret -l serviceaccount=ci-deployer -o jsonpath='{.items[0].metadata.name}')
token=$(kubectl get secret $secret -o jsonpath='{.data.token}' | base64 -d)
```

**Kubeconfig for Service Account:**

```bash
#!/bin/bash
# Create kubeconfig using service account token

SA_TOKEN=$(kubectl create token ci-deployer)
CA_CERT=$(kubectl config view --raw --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
API_SERVER=$(kubectl config view --raw --flatten -o jsonpath='{.clusters[0].cluster.server}')

kubectl config set-cluster my-cluster \
  --server=$API_SERVER \
  --certificate-authority-data=$CA_CERT \
  --embed-certs

kubectl config set-credentials ci-deployer --token=$SA_TOKEN

kubectl config set-context ci-context \
  --cluster=my-cluster \
  --user=ci-deployer
```

**Method 3: OpenID Connect (OIDC) / OAuth**

For human operators using enterprise identity (AD, Okta, Auth0).

```bash
# Configure API server for OIDC
kube-apiserver \
  --oidc-issuer-url=https://auth.example.com \
  --oidc-client-id=kubernetes \
  --oidc-username-claim=email \
  --oidc-groups-claim=groups \
  --oidc-ca-file=/path/to/oidc-ca.crt
```

```yaml
# kubeconfig with OIDC integration (exec plugin)
users:
- name: developer
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubectl-oidc-login  # Third-party plugin
      args:
      - get-token
      - --oidc-issuer-url=https://auth.example.com
      - --oidc-client-id=kubernetes
      - --oidc-client-secret=secret123
```

**Method 4: Bootstrap TokensOAuth (Kubelet Initial Registration)**

FOR BOOTSTRAPPING ONLY (initial node join).

```bash
# Create bootstrap token
kubectl create token bootstrap --duration=24h bootstrap

# kubelet uses during join (temporary, short-lived)
kubelet \
  --kubeconfig=/var/lib/kubelet/kubeconfig.yaml \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubeconfig.yaml \
  --rotate-certificates=true
```

#### Credential Storage Best Practices

**❌ Never do this:**
```bash
# Don't commit to Git
git add ~/.kube/config  # kubeconfig has credentials!

# Don't echo tokens
echo "API_TOKEN=$MY_TOKEN"  # Visible in shell history

# Don't embed in environment variables for long
export KUBECONFIG=/tmp/kubeconfig.yaml  # Plain text credentials
```

**✓ Do this instead:**

```bash
#!/bin/bash
# 1. Use credential plugins (external providers)
#    Credentials never stored in kubeconfig
exec:
  apiVersion: client.authentication.k8s.io/v1beta1
  command: aws
  args: ["eks", "get-token", "--cluster-name", "my-cluster"]

# 2. Short-lived tokens (hours, not days/years)
kubectl create token deployer --duration=2h

# 3. Certificate rotation automated
kubelet --rotate-certificates=true

# 4. Audit who accessed kubeconfig
ls -la ~/.kube/config
chmod 600 ~/.kube/config  # Only user readable

# 5. Separate kubeconfigs per environment
~/.kube/prod-config    # Production credentials
~/.kube/staging-config # Staging credentials
# Different access levels per kubeconfig
```

#### Multi-Cluster Access Patterns

**Pattern 1: Single kubeconfig, Multiple Contexts**

```bash
#!/bin/bash
# Manage multiple clusters with one file

kubectl config get-contexts
# NAME                CLUSTER              AUTHINFO         NAMESPACE
# prod-us-east       prod-us-east         admin           default
# prod-us-west       prod-us-west         admin           default  
# staging-us-east    staging-us-east      deployer        default

# Switch between clusters
kubectl config use-context prod-us-east
kubectl get pods  # prod-us-east cluster

kubectl config use-context staging-us-east
kubectl get pods  # staging cluster
```

**Pattern 2: Environment-Specific kubeconfigs**

```bash
#!/bin/bash
# Segregate credentials by environment blast radius

export KUBECONFIG=~/.kube/prod-config:~/.kube/staging-config

# Explicitly set per command
kubectl --kubeconfig ~/.kube/prod-config get pods
kubectl --kubeconfig ~/.kube/staging-config get pods

# Alias for safety
alias kprod='kubectl --kubeconfig ~/.kube/prod-config'
alias kstaging='kubectl --kubeconfig ~/.kube/staging-config'
```

**Pattern 3: CI/CD Access (Separate SA per pipeline)**

```yaml
# Multiple service accounts: deployer, reader, admin roles
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: github-actions-deployer
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deployer
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: github-actions-deployer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: deployer
subjects:
- kind: ServiceAccount
  name: github-actions-deployer
  namespace: kube-system
```

Each CI/CD pipeline gets unique token:
```bash
# GitHub Actions secret
token=$(kubectl create token github-actions-deployer --duration=24h)
echo "KUBECONFIG_TOKEN=$token" >> ~/.github/secrets
```

### Practical Examples

#### Creating Kubeconfig for New User

```bash
#!/bin/bash
# Complete workflow: user→cert→kubeconfig

USERNAME="alice"
GROUP="developers"
CLUSTER_NAME="production"
API_SERVER="https://api.example.com:6443"
CA_CERT_PATH="/etc/kubernetes/pki/ca.crt"
CA_KEY_PATH="/etc/kubernetes/pki/ca.key"

# 1. Generate private key
openssl genrsa -out ${USERNAME}.key 2048

# 2. Create CSR
openssl req -new \
  -key ${USERNAME}.key \
  -out ${USERNAME}.csr \
  -subj "/CN=${USERNAME}/O=${GROUP}"

# 3. Sign certificate (10 year validity)
openssl x509 -req \
  -in ${USERNAME}.csr \
  -CA ${CA_CERT_PATH} \
  -CAkey ${CA_KEY_PATH} \
  -CAcreateserial \
  -out ${USERNAME}.crt \
  -days 3650 \
  -sha256

# 4. Create kubeconfig
kubectl config set-cluster ${CLUSTER_NAME} \
  --server=${API_SERVER} \
  --certificate-authority=${CA_CERT_PATH} \
  --kubeconfig=kubeconfig-${USERNAME}

kubectl config set-credentials ${USERNAME} \
  --client-certificate=${USERNAME}.crt \
  --client-key=${USERNAME}.key \
  --kubeconfig=kubeconfig-${USERNAME}

kubectl config set-context ${USERNAME}@${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=${USERNAME} \
  --kubeconfig=kubeconfig-${USERNAME}

kubectl config use-context ${USERNAME}@${CLUSTER_NAME} \
  --kubeconfig=kubeconfig-${USERNAME}

# 5. Distribute securely
echo "Kubeconfig created: kubeconfig-${USERNAME}"
ls -l kubeconfig-${USERNAME}
chmod 600 kubeconfig-${USERNAME}

# 6. Test access
kubectl --kubeconfig=kubeconfig-${USERNAME} get pods
```

#### Multi-Cluster Kubeconfig Management

```bash
#!/bin/bash
# Manage kubeconfigs for 5 clusters: 2 prod, 2 staging, 1 dev

KUBECONFIG_DIR=~/.kube/clusters
mkdir -p $KUBECONFIG_DIR

# Initialize combined kubeconfig
export KUBECONFIG=""

# Production East
kubectl config set-cluster prod-us-east \
  --server=https://prod-us-east.example.com:6443 \
  --certificate-authority=$KUBECONFIG_DIR/prod-us-east-ca.crt \
  --kubeconfig=$KUBECONFIG_DIR/prod-us-east-config

# Production West
kubectl config set-cluster prod-us-west \
  --server=https://prod-us-west.example.com:6443 \
  --certificate-authority=$KUBECONFIG_DIR/prod-us-west-ca.crt \
  --kubeconfig=$KUBECONFIG_DIR/prod-us-west-config

# Staging East
kubectl config set-cluster stg-us-east \
  --server=https://stg-us-east.example.com:6443 \
  --certificate-authority=$KUBECONFIG_DIR/stg-us-east-ca.crt \
  --kubeconfig=$KUBECONFIG_DIR/stg-us-east-config

# Development
kubectl config set-cluster dev-local \
  --server=https://localhost:6443 \
  --certificate-authority=$KUBECONFIG_DIR/dev-ca.crt \
  --kubeconfig=$KUBECONFIG_DIR/dev-config

# Merge all kubeconfigs
export KUBECONFIG=$(
  find $KUBECONFIG_DIR -name '*-config' -type f | tr '\n' ':'
)kubeconfig

# View all contexts from all clusters
kubectl config get-contexts

# alias for quick access
alias kprod-east='kubectl config use-context prod-us-east && kubectl'
alias kprod-west='kubectl config use-context prod-us-west && kubectl'
alias kstg-east='kubectl config use-context stg-us-east && kubectl'
alias kdev='kubectl config use-context dev-local && kubectl'
```

#### OIDC Integration for Enterprise SSO

```bash
#!/bin/bash
# Integrate with corporate Okta for SSO

cat > ~/.kube/config <<EOF
apiVersion: v1
kind: Config
clusters:
- name: prod-with-sso
  cluster:
    server: https://api.example.com:6443
    certificate-authority: /etc/kubernetes/pki/ca.crt
users:
- name: developer@example.com
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubectl-oidc-login
      args:
      - get-token
      - --oidc-issuer-url=https://example.okta.com
      - --oidc-client-id=kubernetes-cli
      - --oidc-client-secret=xxxx
contexts:
- name: prod
  context:
    cluster: prod-with-sso
    user: developer@example.com
current-context: prod
EOF

# First run opens browser for Okta login
kubectl get pods
# Token automatically obtained and used
```

### ASCII Diagrams

#### kubeconfig Authentication Flow

```
┌────────────────────────────────────────────────────────┐
│ CLIENT (kubectl, helm, operator)                       │
└────────────────────┬─────────────────────────────────┘
                     │
                     v
         ┌───────────────────────────┐
         │ Load kubeconfig file       │
         │ (merge if multiple)        │
         └────────────┬───────────────┘
                      │
                      v
         ┌─────────────────────────────────────────┐
         │ Read context = cluster + user +namespace│
         └────────────┬────────────────────────────┘
                      │
         ┌────────────┴──────────────┐
         │                           │
         v                           v
    ┌─────────────┐           ┌──────────────┐
    │API Server   │           │Extract creds │
    │Address      │           │from user {}  │
    │             │           └──────┬───────┘
    │https://     │                  │
    │api.example  │                  │
    │.com:6443    │          ┌───────┴─────────────┐
    └─────────────┘          │                     │
                             │                     │
          ┌──────────────────┴────┐       ┌────────┴─────────┐
          │                       │       │                  │
          v                       v       v                  v
    ┌────────────┐         ┌──────────┐ ┌──────────────┐ ┌──────────┐
    │x509 cert + │         │Service   │ │OIDC Exec     │ │  Token   │
    │private key │         │Account   │ │oauth2-proxy  │ │  (JWT)   │
    │            │         │Token     │ │              │ │          │
    │ File       │         │          │ │open browser  │ │ Encoded  │
    │            │         │          │ │exchange code │ │ in       │
    │            │         │   JWT    │ │→ get token   │ │ header   │
    │            │         │ (short-  │ │              │ │          │
    │            │         │  lived)  │ │              │ │          │
    └──────┬─────┘         └────┬─────┘ └───────┬──────┘ └────┬─────┘
           │                    │               │            │
           └────────┬───────────┴───────────────┴────────────┘
                    │
                    v
         ┌────────────────────────┐
         │ Build HTTP request     │
         │ TLS mTLS or Bearer    │
         │ headers                │
         └────────────┬───────────┘
                      │
                      v
         ┌────────────────────────┐
         │ Send to API server     │
         │ API server validates:  │
         │ 1. TLS certificate OK? │
         │ 2. Token valid?        │
         │ 3. User authenticated? │
         └────────────┬───────────┘
                      │
         ┌────────────┴──────────────────┐
         │                               │
         v                               v
    ┌──────────────┐            ┌────────────────┐
    │ Authorization│            │ Authentication │
    │ Check        │            │ Failed         │
    │ (RBAC)       │            │ 401 Unauthorized
    │ Does the user│            │ error          │
    │ have               │            │                │
    │ permission for│            └────────────────┘
    │ this action? │
    └────────┬─────┘
             │
     ┌───────┴────────┐
     │                │
     v                v
 ┌────────┐     ┌──────────────┐
 │ Allow  │     │ Deny         │
 │        │     │ 403 Forbidden│
 │Execute │     │              │
 │action  │     └──────────────┘
 └────────┘
```

#### Multi-Cluster Kubeconfig Context Guide

```
┌──────────────────────────────────────────────────────────┐
│ ~/.kube/config (or KUBECONFIG env var)                  │
└──────────────────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        v              v              v
   ┌─────────┐   ┌──────────┐   ┌──────────┐
   │clusters │   │  users   │   │contexts  │
   │         │   │          │   │          │
   │ [*]     │   │ [*]      │   │ [*]CURR  │
   │         │   │          │   │          │
   └────┬────┘   └─────┬────┘   └────┬─────┘
        │              │             │
   ┌────┴────────┐ ┌───┴──────┐ ┌───┴────────────┐
   │             │ │          │ │                │
   v             v v          v v                v
Prod-  Staging Dev  Alice   Bob  GitOps  Alice@  Bob@
East   West   Local admin   ci  Deployer Prod    Stg
                                       │    │
                ├────────────────────┘│    │
                │                     │    │
         Current context = ──────────┘    │
         Links:                           │
         - Cluster: Prod-East            │
         - User: Alice admin             │
         - Namespace: default       

┌─────────────────────────────────────────────┐
│      COMMAND REFERENCE                      │
├─────────────────────────────────────────────┤
│ SWITCH CONTEXT:                             │
│ $ kubectl config use-context alice@prod    │
│                                             │
│ VIEW CURRENT CONTEXT:                       │
│ $ kubectl config current-context             │
│ → alice@prod                                │
│                                             │
│ LIST ALL CONTEXTS:                          │
│ $ kubectl config get-contexts               │
│ →  alice@prod         prod-east  alice      │
│    bob@staging        staging    bob        │
│    *gitops@prod       prod-east  gitops     │
│                                             │
│ Override single command:                    │
│ $ kubectl --context=bob@staging get pods   │
│                                             │
│ Override user:                              │
│ $ kubectl --as=bob get pods                │
│                                             │
│ Override namespace:                         │
│ $ kubectl -n kube-system get pods          │
└─────────────────────────────────────────────┘
```

---

## Authentication and Authorization in Kubernetes

### Textual Deep Dive

#### Authentication: "Who Are You?"

Authentication verifies the identity of clients accessing the Kubernetes API. Multiple mechanisms can be enabled simultaneously; the first successful authenticator grants access.

**1. x509 Client Certificates**

Cluster PKI-based authentication (used by kubelet, controllers).

```
Flow:
1. Client sends TLS ClientHello with certificate
2. API server verifies certificate chain against cluster CA
3. CN field = username; O field = group memberships
4. Example:
   - Subject: CN=alice,O=developers,O=admins
   → User: alice
   → Groups: [developers, admins]
```

**2. Bearer Tokens**

Simple token-based authentication (service accounts, bootstrap).

```bash
# Authorization header
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ServiceAccount token automatically mounted in pod
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

**3. Basic Authentication (DEPRECATED)**

Username + password (insecure,​ strongly discouraged).

```bash
# Authorization header
Authorization: Basic dXNlcm5hbWU6cGFzc3dvcmQ=

# Do NOT use in production
```

**4. OpenID Connect (OIDC)**

External identity provider integration (enterprise IdP, cloud provider).

```bash
# API server delegates authentication to external provider
kube-apiserver \
  --oidc-issuer-url=https://accounts.google.com \
  --oidc-client-id=myapp.apps.googleusercontent.com \
  --oidc-username-claim=email \
  --oidc-groups-claim=groups

# User flow:
# 1. kubectl-oidc-login opens browser
# 2. User authenticates with Google/Okta/etc
# 3. OIDC provider returns ID token (JWT)
# 4. kubectl includes ID token in Authorization header
# 5. API server validates JWT signature and claims
```

**5. Webhook Authentication**

Custom authentication logic via HTTP webhook.

```bash
kube-apiserver \
  --authentication-token-webhook-config-file=/etc/k8s/webhook-auth.yaml

# For each request, API server POSTs:
{
  "apiVersion": "authentication.k8s.io/v1",
  "kind": "TokenReview",
  "spec": {
    "token": "<bearer-token>"
  }
}

# Webhook responds:
{
  "apiVersion": "authentication.k8s.io/v1",
  "kind": "TokenReview",
  "status": {
    "authenticated": true,
    "user": {
      "username": "alice",
      "uid": "1234",
      "groups": ["developers"]
    }
  }
}
```

**6. Proxy Headers (X-Remote-User)**

Authentication handled externally (reverse proxy, load balancer).

```bash
kube-apiserver \
  --requestheader-client-ca-file=/etc/k8s/front-proxy-ca.crt \
  --requestheader-username-headers=X-Remote-User \
  --requestheader-group-headers=X-Remote-Group

# Proxy injects authenticated user in headers
# X-Remote-User: alice
# X-Remote-Group: developers
```

#### Authorization: "What Are You Allowed To Do?"

AuthorizationDetermines WHICH API Operations an authenticated user can perform.

**Three Questions Answered:**
1. **What is the resource type?** (Pods, Services, Deployments)
2. **What is the verb?** (get, create, delete, watch, list)
3. **In what namespace?** (kube-system, default, custom-ns)

**Authorization Modes (multiple can be enabled in sequence):**

```bash
# API server evaluates in order; first allow/deny wins
kube-apiserver --authorization-mode=RBAC,Webhook,Node

# Request flow:
# 1. RBAC: Check ClusterRoles/Roles → Deny/Allow/NoOpinion
# 2. If NoOpinion, Webhook: Ask external system
# 3. If Webhook allows → Authorize
# 4. If Webhook says NoOpinion, Node: Check kubelet rules
# 5. If all NoOpinion → Deny (default-deny)
```

**Mode 1: RBAC (Role-Based Access Control)**

Most common. Grants permissions based on roles assigned to users.

```yaml
# Role = permissions for namespace-scoped resources
apiVersion: rbac.authorization.k8s.io/v1
kind: Role  
metadata:
  name: pod-reader
  namespace: default
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  # Optionally restrict to specific resources:
  # resourceNames: ["my-pod"]  # Only these pod names

---
# RoleBinding = attach Role to users/groups/serviceaccounts
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-pod-reader
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: User
  name: "alice@example.com"
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: "developers"
- kind: ServiceAccount
  name: my-app
  namespace: kube-system

---
# ClusterRole = permissions for cluster-scoped resources 
# (Nodes, PersistentVolumes, Namespace)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin  # Built-in
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]

---
# ClusterRoleBinding = attach ClusterRole to users (cluster-wide)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ops-can-view-nodes
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # Built-in role
subjects:
- kind: Group
  name: "ops-team"
```

**RBAC Decision Tree:**

```
User:  alice
Action: GET /api/v1/namespaces/default/pods

1. Find all RoleBindings/ClusterRoleBindings for "alice"
2. Collect all Roles referenced
3. For each Role, check if rule matches:
   - apiGroup matches? ("") ✓
   - resource matches? (pods) ✓
   - verb matches? (get in [get, list]) ✓
   → ALLOW

4. If no rule matches:
   → DENY (default-deny)
```

**Mode 2: ABAC (Attribute-Based Access Control - Legacy)**

Grant/deny based on resource attributes. Less flexible than RBAC, generally avoid.

```json
// /etc/kubernetes/abac-policy.json
{"apiVersion":"abac.authorization.kubernetes.io/v1beta1",
"kind":"Policy","spec":{"user":"alice","action":""*","resource":"pods"}}
```

**Mode 3: Node Authorization**

Special authorization for kubelets (system:nodes group).

```
Kubelet (system:nodes) requires special permissions:
- Read/create Pod objects for assigned pods only
- Read ConfigMap/Secret mounted in pods
- Write pod status updates

Node mode prevents kubelet from:
- Accessing other pods' data
- Modifying unassigned pods
```

**Mode 4: Webhook Authorization**

Delegate authorization to external system.

```bash
kube-apiserver --authorization-mode=Webhook \
  --authorization-webhook-config-file=/etc/k8s/webhook-authz.yaml

# API server POSTs SubjectAccessReview to webhook:
{
  "apiVersion": "authorization.k8s.io/v1",
  "kind": "SubjectAccessReview",
  "spec": {
    "user": "alice",
    "groups": ["developers"],
    "verb": "create",
    "resource": "pods",
    "namespace": "default"
  }
}

# Webhook responds (allow/deny/no-opinion):
{
  "status": {
    "allowed": true
  }
}
```

#### Service Accounts: Pod Identity

**Architecture:**
Service accounts provide identity for pods. kubelet injects token at runtime.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
---
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  serviceAccountName: my-app  # Use service account
  
  containers:
  - name: app
    image: myapp:v1
    env:
    - name: KUBERNETES_SERVICE_HOST
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
    volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: token
      readOnly: true
  
  volumes:
  - name: token
    projected:  # Kubernetes 1.21+: bound service account token
      sources:
      - serviceAccountToken:
          audience: api
          expirationSeconds: 3600  # 1-hour expiry
          path: token
```

**Token Binding (Kubernetes 1.21+):**

Tokens are **bound to specific Pod/Node**, preventing token reuse.

```bash
# Extract token from pod
token=$(kubectl exec my-pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Token claims include:
jq -R 'split(".")[1] | @base64d | fromjson' <<< "$token"

# Output:
{
  "aud": ["api"],
  "exp": 1234567890,
  "iat": 1234567890,
  "iss": "https://kubernetes.default.svc.cluster.local",
  "kubernetes.io": {
    "namespace": "default",
    "pod": {
      "name": "my-pod",
      "uid": "abc123"
    },
    "serviceaccount": {
      "name": "my-app",
      "uid": "def456"
    }
  },
  "sub": "system:serviceaccount:default:my-app"
}
```

**RBAC + ServiceAccount Pattern:**

```yaml
# ServiceAccount for application
apiVersion: v1
kind: ServiceAccount
metadata:
  name: deployment-reader
  namespace: default
---
# Role: read deployments only
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-reader
  namespace: default
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
---
# Binding: grant role to service account
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: deployment-reader
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployment-reader
subjects:
- kind: ServiceAccount  
  name: deployment-reader
  namespace: default
---
# Pod uses service account
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: deployment-reader
      containers:
      - name: app
        image: myapp:v1
        # App can now:
        # kubectl get deployments (allowed)
        # kubectl delete pods (forbidden - RBAC denies)
```

### Practical Examples

#### Testing RBAC Rules

```bash
#!/bin/bash
# Verify RBAC rules using kubectl auth can-i

SA=test-user

# Can view pods?
kubectl auth can-i \
  --as=system:serviceaccount:default:${SA} \
  get pods --namespace=default
# ✓ yes (if allowed)
# ✗ no (if denied)

# Can delete deployments?
kubectl auth can-i \
  --as=system:serviceaccount:default:${SA} \
  delete deployments --namespace=default

# Can impersonate others?
kubectl auth can-i \
  --as=alice \
  impersonate users

# Dry-run request to see if it would succeed
kubectl get pods --dry-run=server \
  --as=system:serviceaccount:default:${SA}
```

#### Creating Read-Only User

```bash
#!/bin/bash
# Create user "viewer" with read-only cluster access

# 1. Create user certificate
openssl genrsa -out viewer.key 2048
openssl req -new \
  -key viewer.key \
  -out viewer.csr \
  -subj "/CN=viewer"

openssl x509 -req \
  -in viewer.csr \
  -CA /etc/kubernetes/pki/ca.crt \
  -CAkey /etc/kubernetes/pki/ca.key \
  -out viewer.crt \
  -days 365

# 2. Add to kubeconfig
kubectl config set-credentials viewer \
  --client-certificate=viewer.crt \
  --client-key=viewer.key

kubectl config set-context viewer \
  --cluster=kubernetes \
  --user=viewer

# 3. Grant view role (read-only)
kubectl create rolebinding viewer-readonly \
  --clusterrole=view \
  --user=viewer

# 4. Test
kubectl --context=viewer get pods  # ✓ Works
kubectl --context=viewer delete pod mypod  # ✗ Denied
```

#### Limiting Access to Single Namespace

```yaml
# Create user with access to only "app-ns" namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-developer
  namespace: app-ns
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch", "create", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-app-developer
  namespace: app-ns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-developer
subjects:
- kind: User
  name: "alice@example.com"
---
# alice CAN:
# - kubectl get pods -n app-ns ✓
# - kubectl delete pods -n app-ns ✓
# - kubectl get pods -n kube-system ✗ (different namespace)
# - kubectl get nodes ✗ (cluster-scoped, requires ClusterRole)
```

### ASCII Diagrams

#### Authentication Mechanisms Decision Tree

```
┌─────────────────────────────────────────────────────┐
│     CLIENT REQUEST WITH CREDENTIALS                 │
└──────────────────────┬────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │  
        │              │              v
        │              │    ┌──────────────────┐
        │              │    │TLS Certificate   │ 
        │              │    │(x509)            │
        │              │    │                  │
        │              │    │CN field = user   │
        │              │    │O field = groups  │
        │              │    └────────┬─────────┘
        │              │             │
        │              v             v
        │    ┌──────────────────┐┌───────────┐
        │    │Bearer Token      ││Verified?  │
        │    │                  ││Signature  │
        │    │JWT (OIDC)        │├──┐        │
        │    │Service Account   ││YES│Identify:
        │    │Bootstrap token   ││   │user, groups
        │    │Custom           ││NO │REJECT
        │    │(webhook)         │└──┘
        │    └────────┬─────────┘
        │             │
        │             v
        │    ┌──────────────────┐
        │    │Webhook auth      │
        │    │External system   │
        │    │(LDAP, SAML, etc) │
        │    │                  │
        │    │POST auth request │
        │    │Wait for response │
        │    └────────┬─────────┘
        │             │
        v             v
 ┌─────────────┐┌──────────────┐
 │Proxy Header ││Result:       │
 │             ││AUTHENTICATED │
 │X-Remote-User││+ User info:  │
 │X-Remote-Grp ││- username    │
 │             ││- uid         │
 │Trusted by   ││- groups      │
 │front-proxy? ││              │
 └─────────────┘└──────┬───────┘
                       │
                       v
         ┌─────────────────────────┐
         │ PASS TO AUTHORIZATION   │
         │ ("What can this user do?")│
         └─────────────────────────┘
```

#### RBAC Authorization Decision Flow

```
┌──────────────────────────────────────────────┐
│ REQUEST: User=alice, Action=GET /pods        │
└──────────────────────┬───────────────────────┘
                       │
                       v
    ┌──────────────────────────────────────┐
    │ 1. FIND ROLES for alice              │
    │    Check RoleBindings + ClusterRole │
    │    Bindings where subject=alice      │
    │                                      │
    │    RoleBinding: pod-reader           │
    │    → Role: pod-reader                │
    │                                      │
    │    ClusterRoleBinding: reader        │ 
    │    → ClusterRole: reader             │
    └──────────────┬───────────────────────┘
                   │
                   v
    ┌──────────────────────────────────────┐
    │ 2. COLLECT RULES from all roles      │
    │                                      │
    │    From pod-reader Role:             │
    │    rule:                             │
    │    - apiGroups: [""]                 │
    │    - resources: ["pods"]             │
    │    - verbs: ["get","list"]           │
    │    - namespaces: [default]           │
    │                                      │
    │    From reader ClusterRole:          │
    │    (similar rules, cluster-wide)     │
    └──────────────┬───────────────────────┘
                   │
                   v
    ┌──────────────────────────────────────┐
    │ 3. CHECK RULE MATCH                  │
    │                                      │
    │    Request attributes:               │
    │    - apiGroup: "" (core API)          │
    │    - resource: "pods"                │
    │    - verb: "get"                     │
    │    - namespace: "default"            │
    │                                      │
    │    Rule from pod-reader:             │
    │    ✓ apiGroup "" matches ""          │
    │    ✓ "pods" in ["pods"]              │
    │    ✓ "get" in ["get","list"]        │
    │    ✓ namespace=default match         │
    └──────────────┬───────────────────────┘
                   │
                   ├─ ALL MATCH ──┐
                   │              │
                   v              v
             ┌──────────┐    ┌──────────┐
             │ ALLOW    │    │  NO      │
             │Permission│   │ Matching │  
             │Granted   │   │Rules     │
             └──────────┘   │ DENY     │
                            └──────────┘
```

---

## Hands-on Scenarios

### Scenario 1: Debugging Pod Scheduling Failures in Production

**Problem Statement:**
Your team deployed 50 new application pods in the production cluster at 9 AM. Within minutes, on-call alerts fire: 35 pods stuck in "Pending" state. Users report degraded service. You have 5 minutes to stabilize.

**Architecture Context:**
- Production cluster: 100 nodes, 95% resource utilization (tight capacity planning)
- Nodes spread across 3 availability zones
- Deployment requests 2 CPU cores, 4GB RAM per pod
- No pod anti-affinity rules defined

**Investigation & Root Cause:**
The deployment spec requests 2 CPU + 4GB RAM per pod. Cluster has:
- Average 850m CPU available per node
- Average 3.2GB RAM available per node

Problem: **Overcommitted cluster + pessimistic resource requests**

Scheduler cannot place pods because:
1. 50 pods × 2 CPU = 100 CPU cores needed, only ~85 available
2. 50 pods × 4GB = 200GB RAM needed, only ~320GB available, but fragmented

**Immediate Mitigation:**
```bash
# Scale down non-critical workloads to free capacity
kubectl scale deployment analytics-processor --replicas=0 -n batch
# Frees up ~15 CPU + 20GB RAM (sacrifice non-critical service temporarily)

# Right-size pod requests based on actual metrics
kubectl set resources deployment myapp \
  --requests=cpu=1200m,memory=2Gi \
  --limits=cpu=1500m,memory=3Gi
```

**Long-Term Fixes:**
- Fix resource requests based on actual metrics using kubectl top
- Implement ResourceQuota per namespace to prevent over-provisioning
- Use cluster autoscaling for dynamic workloads
- Define pod anti-affinity for critical workloads (spread replicas)
- Right-size based on actual metrics (Prometheus + custom dashboards)

**Best Practices:** Right-size resource requests, implement ResourceQuota, monitor scheduler logs, use cluster autoscaling.

---

### Scenario 2: etcd Leader Election Failure Causing API Degradation

**Problem Statement:**
At 3 AM, monitoring alerts: API server latency spike to 5+ seconds (normally 50ms). Kubelet logs show "connection refused" errors.

**Root Cause (Discovered):**
- Network maintenance window introduced 150ms+ latency between zones
- Raft heartbeat timeout (ms-level) exceeded
- Leader lost quorum (3-node cluster, needs 2-node quorum; 1 node couldn't reach other 2)
- 30 seconds later, new leader elected, but clients had disconnected

**Recovery:**
```bash
# Wait for election to complete (usually 2-3 seconds)
watch etcdctl endpoint health

# If no leader after 30 seconds, check member list
etcdctl member list

# Monitor cluster convergence
kubectl logs -n kube-system etcd-control-1 | grep "became leader\|became follower"
```

**Prevention (Long-Term):**
- Separate etcd cluster on dedicated nodes with low-latency network
- Configure higher heartbeat/election timeouts for high-latency environments
- Monitor etcd latency metrics (p99 < 1s critical)
- Regular etcd backup (hourly, retention=30 days)
- Graceful shutdown before network maintenance

**Best Practices:** Dedicated etcd infrastructure, monitor latency as leading indicator, multi-zone deployment.

---

### Scenario 3: RBAC Misconfiguration Causing Deploy Pipeline Failures

**Problem Statement:**
CI/CD pipeline (GitOps) suddenly fails all deployment approvals. Error: "serviceaccount 'argocd-deployer' cannot create deployment 'myapp'". Manual kubectl by ops works fine.

**Root Cause:**
Recent RBAC change accidentally replaced deployer binding with monitoring role binding.

**Recovery:**
```bash
# Verify service account has correct permissions
kubectl auth can-i create deployments \
  --as=system:serviceaccount:argocd:argocd-deployer \
  -n app-ns

# Restore correct RoleBinding
kubectl apply -f /correct-rbac.yaml

# Trigger deployment retry
kubectl rollout restart deployment/argocd-application-controller -n argocd
```

**Prevention:**
- Version control all RBAC manifests with code review requirements
- Use `kubectl auth can-i` in test/staging before production
- Implement admission webhook to warn/block RBAC changes
- Regular RBAC audits to find unused roles

**Best Practices:** RBAC in version control, test permissions before production, audit regularly.

---

### Scenario 4: Multi-Zone Control Plane Network Partition

**Problem Statement:**
Network partition between us-east-1a and us-east-1b. Worker nodes in different zones report "NotReady".

**Key Insight:**
Kubernetes architecture **prevents split-brain by design**. With odd-numbered etcd clusters:
- 3-node: can tolerate 1 failure (needs 2-node quorum)
- 5-node: can tolerate 2 failures (needs 3-node quorum)

Network partition automatically creates majority + minority. **Minority cannot write** (safe). Majority continues operating.

**Best Practices:** Odd-numbered etcd, multi-zone spread, monitor latency and member failures.

---

### Scenario 5: Pod Eviction During Node Drain - Handling Stateful Workloads

**Problem Statement:**
Scheduled maintenance requires `kubectl drain node-52` but MySQL StatefulSet pod won't drain gracefully. Hangs for 45+ minutes.

**Proper Procedure:**
```yaml
# Define PodDisruptionBudget for stateful workloads
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: mysql-pdb
  namespace: database
spec:
  minAvailable: 1  # Keep at least 1 replica running
  selector:
    matchLabels:
      app: mysql
---
# Configure graceful shutdown
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  terminationGracePeriodSeconds: 300  # 5 minutes for shutdown
  template:
    spec:
      containers:
      - name: mysql
        lifecycle:
          preStop:
            exec:
              command: ["mysqladmin", "flush-tables"]
```

**Drain with respect for PDB:**
```bash
kubectl drain node-52 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=300
# Respects PDB: keeps min_available replicas running
```

**Best Practices:** PodDisruptionBudget for all critical workloads, preStop hooks for graceful shutdown, adequate terminationGracePeriodSeconds.

---

## Interview Questions

### Foundational Understanding (Level 1-2)

**1. Walk me through what happens from `kubectl apply` a Deployment, all the way through to a running Pod.**

*Senior DevOps Answer Should Include:*
- kubectl sends request to API server (TLS, authentication, authorization)
- API server validates against OpenAPI schema, runs admission webhooks
- Atomically writes to etcd (Raft consensus ensures persistence)
- API server notifies watchers of new Deployment object
- ReplicaSet controller watches, sees new Deployment, creates ReplicaSet
- Scheduler watches Pods (unscheduled), evaluates node constraints, binds Pod.spec.nodeName
- kubelet watches API server, sees new Pod assigned to its node
- kubelet instructs CRI (container runtime) to pull image, start container
- kubelet probes container health (readiness/liveness), reports status back to API server
- Service controller watches Endpoints, updates virtual IPs
- kube-proxy watches Services, updates iptables rules for load balancing
- Pod becomes ready, traffic routed through Service VIP

---

**2. You have a 5-node etcd cluster. One node completely fails. Walk me through recovery without data loss.**

*Senior DevOps Answer Should Include:*
- 5-node cluster: quorum=3. Failed node means 4 remaining nodes (quorum=3 still satisfied)
- etcd cluster continues operating without intervention
- Access remaining etcd nodes normally
- After 5-10 minutes of confirmed failure:
  ```bash
  etcdctl member remove <failed-member-id>
  ```
- 4-node cluster quorum drops to 3 (still safe but no redundancy)
- Start new etcd instance with `etcdctl member add`, allocate new node
- New member joins, automatically copies state from leader
- Verify `etcdctl endpoint health` shows all members healthy
- Return to 5-node cluster (quorum=3, can tolerate 2 failures again)

*Gotcha:* Never remove a member and add a new one simultaneously. If you do, you briefly lose quorum redundancy.

---

**3. Describe the difference between Pod resource requests and limits. When would limits < requests be valid?**

*Senior DevOps Answer Should Include:*
- **Requests**: CPU/memory guaranteed reserved for Pod (scheduler uses for placement decisions)
- **Limits**: Hard cap enforced by kernel cgroups (OOM kill if exceeded)
- Generally: requests ≤ limits, but limits < requests is valid (though unusual)
  - Use case: limit burst CPUs for preventing noisy-neighbor, while reserving guaranteed capacity
  - Example: request=1 CPU, limit=500m CPU = pod gets 1 CPU slot, but capped to 0.5 actual usage
- QoS classes determined by requests/limits:
  - Guaranteed: requests=limits, never evicted
  - Burstable: requests<limits, evicted when node under pressure
  - BestEffort: no requests/limits, evicted first

*Production Insight:* Set request=limit for all production workloads. Eliminates surprise evictions, makes capacity planning deterministic.

---

### Advanced Architecture (Level 3-4)

**4. Design a Kubernetes cluster that tolerates the simultaneous failure of one entire AWS availability zone.**

*Senior DevOps Answer Should Include:*
- Spread control plane across 3 AZs minimum (one per zone)
- 5-node etcd cluster: distribute as 2-2-1 across zones (NOT 3-1-1)
- 5 API servers: same distribution as etcd
- Worker nodes: spread evenly across AZs
- Network: low latency < 50ms (Raft heartbeat sensitive to latency)

*Failure Scenario:*
- AZ fails: lose 2 etcd nodes, 2 API servers, many workers
- Remaining 3 etcd nodes achieve quorum (3 nodes) → cluster continues
- Remaining 3 API servers → cluster API accessible
- New pods automatically schedule to healthy AZs
- When AZ recovered, nodes automatically rejoin

*Critical Avoid:* Never do 3-node etcd per zone across 3 zones. Zone failure often cascades to network issues, risking worse partitions than expected.

---

**5. Design a critical service (99.95% uptime SLA). Walk through the architecture, failure modes, and mitigations.**

*Senior DevOps Answer Should Include:*

| Component | Failure Mode | Mitigation |
|---|---|---|
| **API Server** | Crashes | 3 replicas in 3 zones, load balancer |
| **etcd** | Member fails | 5-node cluster, quorum=3 (tolerates 2 failures) |
| **Scheduler** | Down | 2+ replicas with leader election |
| **nodes** | Fail | Pod Disruption Budgets, pod anti-affinity |
| **pod** | Crashes | Liveness probe restarts, ReplicaSet creates replacement |
| **storage** | Fails | Replicated 2+ zones, automatic failover |

*SLA Calculation:*
- Single cluster at ~99.4% (below SLA)
- Multi-cluster failover (2 clusters): ~99.8% (meets SLA)
- Additional: local cache, retry logic, exponential backoff

---

**6. Describe a time when you had to troubleshoot a cluster issue that violated assumptions. What was the gotcha?**

*Real Expert Answer Examples:*
- "Assumed kubelet always pulls 'latest' tag if `imagePullPolicy=Always`. Reality: kubelet caches manifests. Fixed by using digests instead of tags."
- "Assumed `kubectl drain` gracefully handles all pods. Nope—pods with emptyDir don't drain unless `--delete-emptydir-data`. Pods without requests get killed violently."
- "Assumed network policy would enforce isolation. Deployed, pods still talking. Root cause: CNI plugin didn't support network policies. Switched to Cilium with eBPF enforcement."

---

### Operational Expertise (Level 4-5)

**7. You have autoscaling enabled. Describe scenarios where autoscaler scales up incorrectly and scales down incorrectly. How do you prevent both?**

*Senior DevOps Answer Should Include:*

*Unwanted Scale-Up:*
- Pods with large memory requests (not actual usage) trigger scale-up
- Remedy: PodDisruptionBudget with minAvailable prevents this
- Use `kubectl top pods` to verify actual vs. requested
- Adjust requests downward based on metrics

*Unwanted Scale-Down (Pod Evictions):*
- Autoscaler sees low utilization, drains node, deletes it
- Stateful pods get killed before graceful shutdown completes
- Prevention:
  - PodDisruptionBudget minAvailable (prevents scale-down if violated)
  - terminationGracePeriodSeconds configured for all pods
  - Add node affinity to prevent co-locating multiple replicas

*Advanced Trick:* Configure `--scale-down-delay-after-add=10m` to prevent oscillation.

---

**8. Describe the difference between pod-to-pod communication vs. external-to-pod communication. Why are they different?**

*Senior DevOps Answer Should Include:*

**Pod-to-Pod (East-West):**
- Direct IP routing via CNI network plugin
- Every pod gets routable IP from cluster CIDR
- No DNAT needed (pod IP is real IP)
- Kube-proxy manages Service VIP → Pod IPs via iptables DNAT
- Network policy enforced at CNI layer (iptables, eBPF)
- Fast, direct path

**External-to-Pod (North-South):**
- Traffic arrives at node (ingress controller or load balancer)
- Ingress controller routes to Service ClusterIP
- Service ClusterIP (virtual, non-routable) DNATed to Pod IP
- Pod unicasts response
- Requires SNAT back through load balancer
- Slower path with extra hops

*Why Different:* Pod-to-pod is internal cluster routing. External traffic comes from outside, can't use cluster CIDRs, needs stable entry point.

*Gotcha:* NodePort service with external load balancer: payload might contain node IP in headers (HTTP Location header). If node drained, client connections break. Use Ingress instead.

---

**9. You have 100 namespaces (multi-tenant SaaS). A customer's admin creates a ClusterRole granting themselves cluster admin access. Design security controls to prevent this.**

*Senior DevOps Answer Should Include:*

```bash
# Multiple layers of defense:

# 1. RBAC: Bind cluster-admin ONLY to platform ops, not customers
kubectl create clusterrolebinding platform-ops-admin \
  --clusterrole=cluster-admin \
  --group=platform-ops-team

# 2. Limit customers to namespace admin only
kubectl create rolebinding customer1-admin \
  --role=namespace-admin \
  --user=customer1-admin \
  -n customer1  # Only their namespace

# 3. Admission webhook prevents customers from creating ClusterRoles
# (ValidatingWebhookConfiguration denies CREATE/UPDATE on clusterroles/clusterrolebindings)

# 4. Regular RBAC audits
kubectl get clusterroles,clusterrolebindings -o json | jq '.items[] | .metadata.name'
```

*Multi-layer Defense:*
- Layer 1: RBAC prevents customer binding to cluster-admin
- Layer 2: Admission webhook prevents customer from creating ClusterRole
- Layer 3: Regular audits of permissions
- Layer 4: Network policies isolate namespaces

---

**10. etcd grows to 8GB and cluster becomes sluggish. Diagnose and recover, explaining trade-offs.**

*Senior DevOps Answer Should Include:*

```bash
#!/bin/bash
# STEP 1: Identify problem
etcdctl endpoint status --write-out=table
# Shows DB Size: 8GB (large), Revision: 5,000,000

# STEP 2: Compact old revisions
REV=$(etcdctl endpoint status --write-out=json | jq '.header.revision')
etcdctl compact $((REV - 100000))
# Trade-off: old revisions unreadable (watch clients must re-watch)

# STEP 3: Defragment (reclaim disk space)
foreach member in etcd-1 etcd-2 etcd-3; do
  etcdctl --endpoints=https://$member:2379 defrag
  sleep 30
done

# STEP 4: Enable auto-compaction to prevent recurrence
etcd --auto-compaction-mode=revision --auto-compaction-retention=100000
```

*Operational Discipline:* In production, auto-compaction SAVES YOU. Without it, etcd grows linearly. Defrag monthly to keep disk usage reasonable.

---

**11. Design a GitOps-based upgrade strategy for Kubernetes control plane with zero downtime. What can go wrong?**

*Senior DevOps Answer Should Include:*

**Strategy:**
1. Blue-green deployment: 2 identical control planes
   - Blue: current version
   - Green: new version, pre-warmed
   - DNS/load balancer points to Blue
2. Test Green against staging cluster
3. Gradually shift traffic Blue → Green
4. Rollback: immediate reverse if issues

**Failure Detection:**
```bash
while true; do
  etcdctl endpoint health                    # Check etcd
  curl -k https://api-server:6443/healthz  # Check API server
  pending_pods=$(kubectl get pods --field-selector=status.phase=Pending | wc -l)
  if [ $pending_pods -gt 10 ]; then
    echo "ALERT: Too many pending pods"
    trigger_rollback
  fi
  sleep 10
done
```

**Gotchas:**
- API server version skew: kubectl should be within N±1 minor versions
- etcd compatibility: different etcd versions might not sync properly
- CRD schema changes: old API server might not understand new CRDs

---

**12. You have Guaranteed QoS pods (request=limit). Node hits 100% memory. What happens, and in what order? Why?**

*Senior DevOps Answer Should Include:*

"Guaranteed pods have hard memory limits. At 100%, kernel enforces cgroup limit, OOM killer activates.

OOM killer's algorithm:
1. Calculate 'badness' score for each process (memory usage / importance)
2. Kill process with highest badness score
3. Repeat until under pressure

Kubernetes hint: BestEffort pods have no oom_score_adj (highest badness) → killed first
Burstable pods: medium oom_score_adj → killed if BestEffort insufficient
Guaranteed pods: low oom_score_adj → killed last

BUT: within Guaranteed pods, if one exceeds limit:
- Kernel kills that single pod's container
- Other Guaranteed pods continue

REALITY: This is chaotic. When hitting hard OOM on node:
1. Kubelet detects unschedulable pod
2. Maybe evicts a Burstable pod
3. But kernel OOM killer acts independently
4. Might kill random processes, not just pods

Prevention:
- Reserve kubelet memory: `--reserved-memory` flag
- Always have some Burstable pods as 'eviction buffer'
- Never overcommit cluster to 100% (keep 10-15% free)"

---

---

## Summary & Next Steps

This comprehensive study guide covers Kubernetes architecture fundamentals at a depth suitable for senior DevOps engineers operating production clusters. Key takeaways:

**Architectural Principles:**
- Declarative desired-state model drives self-healing
- Distributed consensus (etcd Raft) ensures consistency
- Control loops separate decision-making (control plane) from execution (worker nodes)
- Security enforced at multiple layers (authentication → authorization → admission → network policies)

**Operational Realities:**
- Kubernetes prevents split-brain by design (quorum-based consensus)
- Failures are expected and mostly handled transparently
- Capacity planning becomes critical at scale
- RBAC is powerful but error-prone; requires discipline
- Performance issues almost always trace to resource over-commitment

**Production Preparation:**
1. Design multi-zone, multi-node control planes
2. Automate etcd backups and verify restore procedures
3. Implement resource quotas and requests/limits comprehensively
4. Monitor cluster health (API latency, scheduler queue depth, etcd commit latency)
5. Practice failure scenarios regularly (failure drills)
6. Maintain runbooks for common incidents

**Continued Learning:**
- Deep-dive into specific components: study source code (kubernetes/kubernetes)
- Deploy test clusters and intentionally cause failures
- Read post-mortems from K8s incidents (Kubernetes Blog)
- Participate in Kubernetes community (SIG-Architecture discussions)
- Stay current: minor version upgrade patterns change with each release

---

*Document Version: 3.0*
*Last Updated: March 10, 2026*
*Target Audience: Senior DevOps Engineers (5-10+ years experience)*
*Status: Complete - All sections with practical examples, production scenarios, and interview preparation*
*Total Length: 3,600+ lines of comprehensive Kubernetes architecture documentation*