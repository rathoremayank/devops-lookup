# Network Policies, RBAC & Security Basics, Debugging & Troubleshooting, Resource Failures

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Core Terminology](#core-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [DevOps Principles & Best Practices](#devops-principles--best-practices)
   - [Common Misunderstandings](#common-misunderstandings)
3. [Network Policies](#network-policies)
   - [Network Segmentation](#network-segmentation)
   - [Ingress and Egress Rules](#ingress-and-egress-rules)
   - [Policy Types](#policy-types)
   - [How Network Policies Work Under the Hood](#how-network-policies-work-under-the-hood)
   - [Network-level Firewalls](#network-level-firewalls)
   - [Segmentation Strategies](#segmentation-strategies)
   - [Best Practices for Network Policies](#best-practices-for-network-policies)
4. [RBAC & Security Basics](#rbac--security-basics)
   - [Role-Based Access Control](#role-based-access-control)
   - [ClusterRoles and Roles](#clusterroles-and-roles)
   - [Role Bindings and ClusterRoleBindings](#role-bindings-and-clusterrolebindings)
   - [Service Accounts](#service-accounts)
   - [Authentication vs Authorization](#authentication-vs-authorization)
   - [Best Practices for RBAC](#best-practices-for-rbac)
   - [Common Security Pitfalls](#common-security-pitfalls)
5. [Debugging & Troubleshooting](#debugging--troubleshooting)
   - [Common Issues in Kubernetes Clusters](#common-issues-in-kubernetes-clusters)
   - [Kubectl Describe](#kubectl-describe)
   - [Events and Event Correlation](#events-and-event-correlation)
   - [Crashloops](#crashloops)
   - [Logs Analysis](#logs-analysis)
   - [Exec into Pods](#exec-into-pods)
   - [Pending Pods](#pending-pods)
   - [Network Troubleshooting](#network-troubleshooting)
   - [Resource Usage Troubleshooting](#resource-usage-troubleshooting)
   - [Best Practices for Debugging](#best-practices-for-debugging)
6. [Resource Failures](#resource-failures)
   - [OOMKilled](#oomkilled)
   - [CPU Throttling](#cpu-throttling)
   - [Node Pressure](#node-pressure)
   - [Disk Pressure](#disk-pressure)
   - [Scheduling Failures](#scheduling-failures)
   - [Node Failures](#node-failures)
   - [Pod Eviction](#pod-eviction)
   - [Resource Limits and Requests](#resource-limits-and-requests)
   - [Best Practices for Handling Resource Failures](#best-practices-for-handling-resource-failures)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

In modern Kubernetes-based infrastructure, three critical dimensions of cluster management converge: **network isolation and security**, **access control and authorization**, **operational visibility and debugging**, and **resource health and lifecycle management**. These topics form the backbone of production-grade Kubernetes deployments and are essential for DevOps engineers operating at scale.

This study guide consolidates expertise in four interdependent domains:

- **Network Policies**: Implementing microsegmentation at the Kubernetes networking layer to enforce zero-trust principles
- **RBAC & Security Basics**: Granular access control across cluster and namespace boundaries using Kubernetes' native RBAC model
- **Debugging & Troubleshooting**: Methodical approaches to diagnosing and resolving cluster-level and application-level issues
- **Resource Failures**: Understanding resource constraints, pod lifecycle events, and node health states that directly impact availability

These four pillars are not isolated; they deeply interconnect:
- Network Policies affect debugging complexity and observability requirements
- RBAC decisions influence what troubleshooting data teams can access
- Resource failures often manifest as symptoms requiring network and security policy adjustments
- Debugging capabilities depend on proper RBAC configuration to access logs and metrics

### Why It Matters in Modern DevOps Platforms

#### Multi-Tenant Security
In cloud-native environments where multiple teams, applications, and tenants share cluster resources, **security boundaries become operational necessities**, not optional features. Network Policies enforce microsegmentation; RBAC ensures privilege separation.

#### Compliance and Governance
Regulatory frameworks (PCI-DSS, HIPAA, SOC 2) require:
- Audit trails of who accessed what (RBAC audit logging)
- Network-level traffic isolation (Network Policies)
- Resource allocation guardrails preventing noisy neighbor problems

#### Operational Reliability
Resource failures and network connectivity issues are the leading causes of production incidents. Mature debugging capabilities reduce MTTR (Mean Time To Resolution) from hours to minutes.

#### Cost Optimization
Understanding resource limits/requests and node pressure prevents both:
- Over-provisioned clusters with wasted capacity
- Under-provisioned services experiencing cascading failures

### Real-World Production Use Cases

#### Case 1: Financial Services Platform
- **Scenario**: Multi-tenant payment processing with PCI-DSS requirements
- **Requirements**: Strict network isolation between tenant applications, audit trails for RBAC changes, rapid incident response for transaction failures
- **Solution**: Network Policies isolating tenant namespaces, fine-grained RBAC with ServiceAccount-level isolation, comprehensive debugging dashboards tracking pod evictions and resource contention

#### Case 2: SaaS Platform Rapid Scaling
- **Scenario**: Microservices experiencing unexpected OOMKilled failures during traffic spikes
- **Requirements**: Quick identification of resource-constrained services, fair resource allocation across tenants, automated incident detection
- **Solution**: Resource request/limit optimization, node pressure monitoring, RBAC-gated access to metrics to prevent unauthorized viewing of competitor data

#### Case 3: Multi-Region Cloud Migration
- **Scenario**: Migrating legacy infrastructure to Kubernetes across regions with hybrid cloud security zones
- **Requirements**: Network egress controls preventing data exfiltration, RBAC synchronization with corporate identity providers, troubleshooting tools for cross-region latency
- **Solution**: NetworkPolicy enforcement at cluster entry/exit points, integration with external authentication providers, advanced network debugging with tcpdump and CNI-level inspection

#### Case 4: Zero-Trust Architecture Implementation
- **Scenario**: Enterprise moving from perimeter-based security to zero-trust where every pod-to-pod communication is explicitly authorized
- **Requirements**: Explicit allow-list policies, audit of all network connections, rapid troubleshooting when legitimate traffic is blocked
- **Solution**: NetworkPolicy deny-all default with explicit allow rules, enhanced observability of policy violations, debugging frameworks for policy-related connectivity issues

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Cloud Platform (AWS, Azure, GCP)                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Kubernetes Cluster                              │   │
│  │                                                 │   │
│  │  ┌─────────────────────────────────────────┐    │   │
│  │  │ Namespace: production                   │    │   │
│  │  │                                         │    │   │
│  │  │  ┌────────────────────────────────┐     │    │   │
│  │  │  │ Network Policies (Layer 1)     │     │    │   │
│  │  │  │ - Ingress/Egress rules         │     │    │   │
│  │  │  │ - Pod-to-pod isolation         │     │    │   │
│  │  │  └────────────────────────────────┘     │    │   │
│  │  │           ↓                             │    │   │
│  │  │  ┌────────────────────────────────┐     │    │   │
│  │  │  │ RBAC & Service Accounts        │     │    │   │
│  │  │  │ (Layer 2)                      │     │    │   │
│  │  │  │ - Who can access what          │     │    │   │
│  │  │  │ - Principle of least privilege │     │    │   │
│  │  │  └────────────────────────────────┘     │    │   │
│  │  │           ↓                             │    │   │
│  │  │  ┌────────────────────────────────┐     │    │   │
│  │  │  │ Pod Resource Allocation        │     │    │   │
│  │  │  │ - Limits & Requests            │     │    │   │
│  │  │  │ - QoS Classes                  │     │    │   │
│  │  │  └────────────────────────────────┘     │    │   │
│  │  │           ↓                             │    │   │
│  │  │  ┌────────────────────────────────┐     │    │   │
│  │  │  │ Debugging & Observability      │     │    │   │
│  │  │  │ - Logs, Metrics, Events        │     │    │   │
│  │  │  │ - Pod troubleshooting          │     │    │   │
│  │  │  └────────────────────────────────┘     │    │   │
│  │  │                                         │    │   │
│  │  └─────────────────────────────────────────┘    │   │
│  │                                                 │   │
│  │  ┌─────────────────────────────────────────┐    │   │
│  │  │ Cluster-wide Infrastructure              │    │   │
│  │  │ - Nodes, Storage, Networking             │    │   │
│  │  │ - kube-apiserver, scheduler, kubelet    │    │   │
│  │  └─────────────────────────────────────────┘    │   │
│  │                                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Core Terminology

#### 1. **Network Policies (Layer 3-4 Control)**
Network Policies are Kubernetes objects that define traffic rules between pods and external endpoints. Unlike traditional firewalls that operate at the VM/host boundary, Network Policies operate at the pod level within the Kubernetes networking model.

**Key distinction**: Network Policies are **not required** by the Kubernetes specification—they only work if your CNI (Container Network Interface) plugin supports them. However, they are **de facto standard** in production clusters.

#### 2. **RBAC (Role-Based Access Control)**
RBAC is the Kubernetes authorization mechanism controlling which identities (users, ServiceAccounts) can perform which actions (verbs) on which resources (pods, services, etc.) in which scopes (cluster-wide or namespace-specific).

**Critical concept**: RBAC operates **after** authentication. Authentication answers "who are you?"; RBAC answers "what are you allowed to do?"

#### 3. **ServiceAccount**
A Kubernetes identity used by workloads (pods) to authenticate with the kube-apiserver. Every pod receives a default ServiceAccount token mounted as a volume, enabling pod-to-API authentication without explicit credential management.

#### 4. **QoS Class (Quality of Service)**
Kubernetes assigns each pod to one of three QoS classes based on its resource requests and limits:
- **Guaranteed**: Requests == Limits (highest priority during eviction)
- **Burstable**: Requests < Limits (medium priority)
- **BestEffort**: No requests or limits (evicted first)

#### 5. **Node Pressure**
Signals indicating a node is under resource stress:
- **MemoryPressure**: Node running out of memory
- **DiskPressure**: Node's filesystem approaching capacity
- **PIDPressure**: Process ID limit reached
- **NetworkUnavailable**: Network not ready

#### 6. **Pod Phase vs. Container State**
Often conflated, but distinct:
- **Pod Phase**: Lifecycle state (Pending, Running, Succeeded, Failed, Unknown)
- **Container State**: Detailed state with exit codes (Running, Waiting, Terminated)

#### 7. **Event-driven Observability**
Kubernetes Events are the primary mechanism for understanding why something happened. Unlike logs (which are application-generated), events are **system-generated signals** corresponding to state transitions.

### Architecture Fundamentals

#### The Kubernetes Security Model: Defense in Depth

Kubernetes security operates across multiple layers:

```
Layer 1: Authentication & API Server
  └─ TLS certificates, bearer tokens, service account tokens
  └─ kube-apiserver request validation

Layer 2: Authorization (RBAC)
  └─ Role definitions (collection of permissions)
  └─ RoleBindings (attach roles to subjects)

Layer 3: Admission Control
  └─ Pod Security Policies / Pod Security Standards
  └─ Network Policy enforcement
  └─ Custom webhooks

Layer 4: Network-level Security
  └─ NetworkPolicies (pod-to-pod)
  └─ Calico/Cilium network enforcement
  └─ Egress controls to external systems

Layer 5: Application-level Security
  └─ mTLS (mutual TLS) between services
  └─ Service meshes (Istio, Linkerd)
```

This layered approach means:
- **No single point of failure**: Compromising RBAC doesn't automatically grant network access
- **Fail-secure defaults**: Kubernetes denies by default (with few exceptions)
- **Auditable at each layer**: Separate audit logs for auth, RBAC, network policies

#### The Kubernetes Networking Model

Understanding networking is prerequisite for both Network Policies and debugging:

1. **Pod Networking Assumptions** (from the original design):
   - Every pod gets a unique, routable IP address
   - Pods can communicate with all other pods without NAT
   - Kubelets can communicate with all pods without NAT
   - Agents on a node (e.g., daemonsets) can communicate with all pods

2. **CNI Plugins implement this model** (Calico, Cilium, Weave)
   - Allocate IP addresses from a pool
   - Configure routing tables
   - Implement Network Policies by intercepting traffic

3. **Service Abstraction** (ClusterIP, NodePort, LoadBalancer)
   - virtual IP that load-balances to pod endpoints
   - kube-proxy translates Service IPs to pod IPs using iptables/IPVS
   - Traffic between services uses DNS round-robin

#### Pod Lifecycle: The State Machine

```
Pending ─────────> Running ─────────> Succeeded
  │                  │ │                   ▲
  │                  │ │                   │
  │                  └─┼─────────────────────
  │                    │
  │                    └──────> CrashLoopBackOff
  │                       │
  │                       └──────> Failed
  │
  └──────────────────────────────> Failed
     (Unschedulable)
```

Each state has associated conditions and container status details that aid troubleshooting.

#### Resource Management: Requests vs. Limits

| Dimension | Request | Limit |
|-----------|---------|-------|
| **Purpose** | Scheduler guarantee (resource reserved) | Hard cap (eviction trigger) |
| **CPU behavior** | Throttling if exceeded | Throttling at limit |
| **Memory behavior** | Used in scheduling decisions | OOMKilled if exceeded |
| **Impact on QoS** | Determines QoS class | Determines QoS class |

This distinction is fundamental: **requests enable fair scheduling; limits prevent noisy neighbor problems**.

#### Debugging Information Sources

Kubernetes provides debugging data at multiple levels:

```
Level 1: Pod-centric
  ├─ kubectl describe pod
  ├─ kubectl logs
  ├─ kubectl exec
  └─ kubectl top

Level 2: Event-based
  ├─ kubectl get events --all-namespaces
  ├─ kubectl get events --sort-by='.lastTimestamp'
  └─ Custom event parsers

Level 3: Node-level
  ├─ Node status and conditions
  ├─ kubelet logs
  └─ systemd journal

Level 4: Cluster-level
  ├─ kube-apiserver logs
  ├─ Metrics server data
  ├─ Audit logs (if enabled)
  └─ Network CNI logs
```

### DevOps Principles & Best Practices

#### 1. **Principle of Least Privilege (Zero-Trust)**

**Definition**: Grant minimal necessary permissions; deny by default, explicitly allow by exception.

**Application in Kubernetes**:

- **RBAC**: Create fine-grained roles tied to specific use cases
- **Network Policies**: Start with deny-all ingress/egress, add specific allow rules
- **ServiceAccounts**: Use per-application ServiceAccounts, not shared defaults

**Anti-pattern**:
```yaml
# ❌ DANGEROUS: Cluster-admin for everyone
kind: ClusterRoleBinding
metadata:
  name: all-admins
subjects:
- kind: Group
  name: "developers"
roleRef:
  kind: ClusterRole
  name: cluster-admin
```

**Better pattern**:
```yaml
# ✓ BETTER: Granular permissions
kind: Role
metadata:
  namespace: development
  name: developer
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/logs"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
```

#### 2. **Observability-First Debugging**

**Principle**: Before fixing a problem, understand its root cause through structured observation.

**Implementation**:
- Centralize logs from all components (application, kubelet, CNI plugin)
- Instrument business logic and infrastructure with metrics
- Correlate events with pod lifecycle changes
- Maintain audit logs for security-related actions

**Senior-level consideration**: Customize audit logging to reduce noise while capturing security events:
```yaml
rules:
- level: RequestResponse
  verbs: ["create", "delete", "patch"]
  resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
  
- level: Metadata  # Less verbose for read-heavy operations
  verbs: ["list", "get", "watch"]
  resources: ["pods"]

- level: None  # Suppress noise
  userAgents: ["kube-probe"]
```

#### 3. **Resource Reservation as a Safety Mechanism**

**Concept**: Resource requests aren't just hints to the scheduler—they're **commitments** that influence pod eviction order.

**Best practice flow**:
1. Set **requests** to match observed 99th percentile usage
2. Set **limits** to prevent noisy neighbor effects (typically requests × 2-4)
3. Monitor for OOMKilled and CPU throttling
4. Adjust if throttling approaches limits (indicates requests were too low)

#### 4. **Network Policy as Incident Prevention**

Network Policies aren't primarily for compliance—they're for **preventing cascading failures**:
- If a compromised pod can't reach the database, damage is limited
- If a misconfigured service can't reach unintended backends, data leakage stops
- If a runaway process can't flood external APIs, customer-facing services remain available

#### 5. **Immutable Debugging Pattern**

**Concept**: Avoid modifying cluster state to debug; instead, collect data and analyze offline.

**Anti-pattern**: `kubectl set env deployment/app DEBUG=true` and hoping logs appear

**Better pattern**:
```bash
# Capture current state
kubectl describe pod <pod-name> > pod-state.txt
kubectl logs <pod-name> --all-containers=true > pod-logs.txt
kubectl logs <pod-name> --previous > pod-previous-logs.txt
kubectl get events --all-namespaces > events.txt

# Debug locally with collected data
grep -i error pod-logs.txt
grep -i warning pod-state.txt
```

#### 6. **Shift-Left Security & Testing**

**Concept**: Validate security configurations and resource allocation **before** production deployment.

**Implementation**:
- Test Network Policies in staging with realistic traffic patterns
- Validate RBAC via `kubectl auth can-i` commands in CI/CD
- Load-test resource configurations to identify limits inadequacy
- Review pod events in staging environments

### Common Misunderstandings

#### 1. **"Network Policies are firewalls"**

**Misunderstanding**: Network Policies work like traditional firewalls, filtering all traffic.

**Reality**: 
- Network Policies only work if a CNI plugin supports them
- If the CNI doesn't enforce policies, they're ignored (no error)
- They operate at Layer 3-4 (IP/TCP), not application layer
- They filter based on pod labels and namespaces, not traditional IP CIDR ranges

**Implication**: Always verify your CNI supports policies (Calico, Cilium, Weave do; kubenet doesn't).

#### 2. **"RBAC prevents pod-to-pod communication"**

**Misunderstanding**: RBAC controls which pods can talk to each other.

**Reality**:
- RBAC controls API server access (e.g., whether a pod can list services via the API)
- Pod-to-pod communication is controlled by **Network Policies and CNI configuration**
- RBAC doesn't restrict network traffic; Network Policies do

**Implication**: Need both for security:
- RBAC: "Can ServiceAccount X read the secret?" (API access)
- NetworkPolicy: "Can pod A send traffic to pod B?" (network access)

#### 3. **"Adding resource requests/limits makes your app faster"**

**Misunderstanding**: Setting limits improves performance.

**Reality**:
- Requests enable fair scheduling but don't improve individual app performance
- Limits prevent other apps from harming yours, but can throttle your own app
- Requests too low → pod evicted or unschedulable
- Limits too low → CPU throttling or OOMKilled
- Optimal configuration = requests match actual usage, limits match acceptable max

**Implication**: Profile your applications in staging first, then set requests/limits.

#### 4. **"Pending pods will start when resources become available"**

**Misunderstanding**: Pending pods always succeed when cluster resources free up.

**Reality**: A pod remains Pending if:
- No node has the requested resources (will wait forever unless new nodes are added)
- Pod has node selectors or affinity that no node satisfies
- Taints on nodes don't tolerate the pod
- PVC is not bound
- Service account token can't be mounted

**Implication**: Always check `kubectl describe pod` for the scheduling reason; don't assume resources are the issue.

#### 5. **"kubectl logs gives complete application state"**

**Misunderstanding**: Application logs tell the full story of what happened.

**Reality**:
- Logs only capture what the app chose to log
- System events provide the context (scheduled, started, killed, etc.)
- Container state changes (exit code) indicate what the system did
- Pod events show why a pod was evicted or rescheduled

**Implication**: Always correlate logs with events, kubectl describe, and container state.

#### 6. **"Evicted pods will restart automatically"**

**Misunderstanding**: When a pod is evicted due to resource pressure, the Deployment automatically recreates it.

**Reality**:
- Pod eviction is graceful (by design); the pod itself terminates
- If the pod is managed by a Deployment, a new pod is created (eventually)
- But if the cluster still has resource or taint issues, the new pod also gets evicted
- This creates a **restart loop** that looks like a failure, not temporary resource pressure

**Implication**: Fix the underlying resource/scheduling issue first (add nodes, adjust requests, add tolerations).

#### 7. **"Network Policy deny-all means nothing gets in or out"**

**Misunderstanding**: A NetworkPolicy with no rules blocks all traffic.

**Reality**:
- An empty ingress rule still allows traffic if no rules are defined
- To block all, define: `ingress: [{}]` (empty selector)
- Traffic to ports not covered by Egress rules depends on CNI implementation

**Implication**: Explicitly define deny-all rules; don't assume defaults.

---

## Next Sections (To Be Generated)

This foundation establishes the prerequisites for detailed exploration of:
- **Network Policies** (implementation, CNI interactions, debugging)
- **RBAC & Security Basics** (role design, binding strategies, audit)
- **Debugging & Troubleshooting** (systematic approaches, tool mastery)
- **Resource Failures** (diagnosis, remediation, prevention patterns)

---

## Network Policies

Network Policies are the primary mechanism for implementing microsegmentation in Kubernetes clusters. They define rules governing traffic between pods, namespaces, and external endpoints at Layer 3-4 (IP/TCP/UDP).

### Network Segmentation

#### Textual Deep Dive

**Internal Mechanism**: Network Policies are objects in the Kubernetes API that the CNI plugin (Calico, Cilium, etc.) watches via the API server. When a NetworkPolicy is created, the CNI plugin translates it into lower-level networking rules:
- **Calico**: Uses BGP and iptables rules
- **Cilium**: Uses eBPF programs in the Linux kernel for enforcement
- **Weave**: Uses vxlan tunneling with firewall rules

The CNI plugin hooks into the kernel at different levels:
- Traditional CNIs (Calico, Weave) use iptables → evaluated for every packet
- Modern CNIs (Cilium) use eBPF → executed directly in kernel without context switches (lower latency, better performance)

**Architecture Role**: Network Policies are **declarative security boundaries** rather than procedural firewall commands. They describe "what" should be allowed, not "how" to enforce it. This allows:
1. CNI-agnostic definitions (same YAML works with different CNIs)
2. Reconciliation: If enforcement rules are accidentally deleted, the CNI restores them
3. Auditability: The source of truth is the Kubernetes API, not iptables rules

**Production Usage Patterns**:

1. **Multi-tenant Isolation**: Each tenant gets a namespace with:
   ```yaml
   - Default deny-all policy
   - Explicit allow rules for tenant's services
   - No cross-tenant communication
   ```

2. **Microsegmentation by Function**: Default deny, then allow specific:
   - Web tier → API tier communication
   - API tier → Database tier communication
   - Services → Logging/Monitoring system communication

3. **Egress Controls**: Prevent:
   - Unauthorized external API calls (exfiltration)
   - Unintended cloud metadata service access
   - Misconfigured service discovery leaking data

**DevOps Best Practices**:
- Start with **deny-all ingress** policies in new namespaces
- Add **explicit allow rules** for known communication paths
- Test Network Policies in staging with real traffic patterns
- Use **pod selectors** (not IP addresses) for portability across upgrades
- Document the business reason for each policy in comments
- Monitor policy violations via CNI logs (Calico: `/var/log/calico/deny.log`)

**Common Pitfalls**:
- Assuming Network Policies work without verifying CNI support
- Creating overly broad selectors (e.g., `matchLabels: {}` = all pods)
- Forgetting that DNS queries must be allowed (port 53 UDP)
- Not accounting for kubelet→API communication (health checks, pod logs)
- Policies not enforcing unless explicitly named in Deployment spec
- Assuming stateless policy (Network Policies are stateless; connections must be bidirectional)

#### Practical Code Examples

**Example 1: Default Deny with Explicit Allows**
```yaml
---
# Step 1: Default deny ALL ingress
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}  # Matches all pods
  policyTypes:
  - Ingress
  # No rules = no ingress allowed

---
# Step 2: Allow frontend access to API
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-frontend-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api  # Target: API pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend  # Source: Frontend pods
    ports:
    - protocol: TCP
      port: 8080

---
# Step 3: Allow API to database
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-api-to-db
  namespace: production
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
# Step 4: Allow DNS queries (critical!)
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-dns-egress
  namespace: production
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

**Example 2: Cross-Namespace Communication**
```yaml
---
# Backend service account in 'backend' namespace
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app
  namespace: backend

---
# API service account in 'api' namespace
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api
  namespace: api

---
# Allow API (in 'api' namespace) to reach Backend (in 'backend' namespace)
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-api-to-backend
  namespace: backend  # Policy lives in target namespace
spec:
  podSelector:
    matchLabels:
      app: backend-service
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: api  # Namespace selector (requires label)
      podSelector:
        matchLabels:
          app: api-service
    ports:
    - protocol: TCP
      port: 5000
```

**Example 3: Egress Control to External Services**
```yaml
---
# Prevent accidental external API calls
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: api-egress-control
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Egress
  egress:
  # Allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow database
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  # Allow allowed-external-service
  - to:
    - podSelector:
        matchLabels:
          external-service: "true"
    ports:
    - protocol: TCP
      port: 443
  # DENY everything else (implicit)
```

**Example 4: Debugging Script**
```bash
#!/bin/bash
# Verify Network Policy enforcement

NAMESPACE=${1:-default}
POD_NAME=${2:-}

echo "=== NetworkPolicy Status in $NAMESPACE ==="
kubectl get networkpolicies -n $NAMESPACE -o wide

echo -e "\n=== Pods in $NAMESPACE with Labels ==="
kubectl get pods -n $NAMESPACE --show-labels

if [ ! -z "$POD_NAME" ]; then
  echo -e "\n=== Testing connectivity from $POD_NAME ==="
  
  TARGET_SERVICE=${3:-}
  TARGET_PORT=${4:-80}
  
  if [ ! -z "$TARGET_SERVICE" ]; then
    echo "Testing: $POD_NAME -> $TARGET_SERVICE:$TARGET_PORT"
    
    # Install netcat if not present
    kubectl exec -it $POD_NAME -n $NAMESPACE -- \
      sh -c "command -v nc >/dev/null 2>&1 || (apt-get update && apt-get install -y netcat-openbsd)" || true
    
    # Test connectivity
    kubectl exec -it $POD_NAME -n $NAMESPACE -- \
      nc -zv -w 5 $TARGET_SERVICE $TARGET_PORT
  fi
fi

echo -e "\n=== CNI Policy Logs (if Calico) ==="
# On Calico nodes:
# kubectl logs -n calico-system -l k8s-app=calico-node
```

#### ASCII Diagrams

```
Network Segmentation with Policies:

┌─────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (10.0.0.0/16)                            │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Namespace: production (NetworkPolicies enforced)    │   │
│  │                                                     │   │
│  │  ┌──────────────┐     ┌──────────────┐             │   │
│  │  │ Frontend Pod │     │ Frontend Pod │             │   │
│  │  │ (10.1.1.5)   │     │ (10.1.1.6)   │             │   │
│  │  │ tier: frontend│     │ tier: frontend│            │   │
│  │  └──────────────┘     └──────────────┘             │   │
│  │         │                   │                       │   │
│  │         └───────────────────┘                       │   │
│  │                 ↓                                    │   │
│  │          Can Connect to:                            │   │
│  │          tier: api (port 8080)                      │   │
│  │                                                     │   │
│  │  ┌──────────────┐     ┌──────────────┐             │   │
│  │  │ API Pod      │     │ API Pod      │             │   │
│  │  │ (10.1.2.5)   │     │ (10.1.2.6)   │             │   │
│  │  │ tier: api    │     │ tier: api    │             │   │
│  │  └──────────────┘     └──────────────┘             │   │
│  │         │                   │                       │   │
│  │         └───────────────────┘                       │   │
│  │                 ↓                                    │   │
│  │          Can Connect to:                            │   │
│  │          tier: database (port 5432)                 │   │
│  │                                                     │   │
│  │  ┌──────────────┐     ┌──────────────┐             │   │
│  │  │ DB Pod       │     │ DB Pod       │             │   │
│  │  │ (10.1.3.5)   │     │ (10.1.3.6)   │             │   │
│  │  │ tier: database│     │ tier: database│            │   │
│  │  └──────────────┘     └──────────────┘             │   │
│  │                                                     │   │
│  │  DEFAULT DENY: All other traffic blocked           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

Network Policy Enforcement Flow:

    [Packet arrives at Pod Interface]
                    ↓
    [CNI reads NetworkPolicy objects]
                    ↓
    [Filter based on:]
    ├─ Source pod labels
    ├─ Destination pod labels
    ├─ Namespace selectors
    ├─ Port/Protocol
    └─ CIDR blocks (if specified)
                    ↓
    ┌──────────────────────────────┐
    │ Policy allows? → FORWARD pkt │
    └──────────────────────────────┘
                    ↓
    ┌──────────────────────────────┐
    │ Policy denies?  → DROP pkt   │
    └──────────────────────────────┘
```

---

### Ingress and Egress Rules

#### Textual Deep Dive

**Internal Mechanism**: 

Kubernetes Network Policies distinguish between two directions:
- **Ingress**: Incoming traffic to the pod (inbound)
- **Egress**: Outgoing traffic from the pod (outbound)

When no `policyTypes` are specified, both are assumed. When specified, only that direction is controlled.

**Critical insight**: A NetworkPolicy is **unidirectional**. An ingress rule on Pod A doesn't automatically allow egress from Pod B:

```
Pod A → Pod B (blocked unless egress rule on A allows)
Pod B ← Pod A (blocked unless ingress rule on B allows)
```

For bidirectional communication, **both** rules must exist.

**Stateless nature**: Kubernetes Network Policies don't track connection state (unlike traditional stateful firewalls). This means:
- A return packet from a server must have an explicit egress rule on the server
- "Allow established connections" doesn't exist in NetworkPolicy
- Both directions need explicit rules (or implicit denial)

**Architecture Role**: Ingress/Egress rules enforce the **principle of least privilege** at the network level:
- Ingress rules define what can communicate **into** the pod
- Egress rules define what the pod can communicate **with**

This separation enables:
1. **Security boundaries**: Compromise of one pod doesn't automatically propagate to services it connects to
2. **Multi-directional trust**: Team A trusts team B for inbound, but doesn't trust any outbound destinations
3. **Compliance auditing**: Explicit allowlists create audit trails

**Production Usage Patterns**:

1. **Implicit Deny Pattern** (Recommended):
   - Default policy: deny all ingress at namespace level
   - Per-service policies: explicit ingress rules for each service
   - Explicit egress: each service declares what it needs to reach

2. **Deny External Access Pattern**:
   ```yaml
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     ingress:
     - from:
       - namespaceSelector: {}  # Only from pods in this cluster
   ```

3. **Egress to Specific External IPs**:
   ```yaml
   spec:
     podSelector:
       matchLabels:
         app: exporter
     policyTypes:
     - Egress
     egress:
     - to:
       - ipBlock:
           cidr: 203.0.113.0/24  # External monitoring system
       ports:
       - protocol: TCP
         port: 9090
   ```

**DevOps Best Practices**:
- Always test ingress + egress together (test requires both directions to work)
- Use **selector-based** rules, not CIDR blocks (more resilient to IP changes)
- Document each rule with business justification
- Monitor denied packets via CNI logs
- Implement gradual rollout (warn-mode if CNI supports it, e.g., Cilium policy audit mode)
- Test failover paths (e.g., secondary database) in staging

**Common Pitfalls**:
- Defining only ingress, forgetting responses need egress rules
- Using `ipBlock` for dynamic services (IP changes break policy)
- Allowing `from: []` + `to: []` = allows all (meant to restrict)
- Not excluding kubelet→API communication (liveness/readiness probes fail)
- Assuming egress to external services works without testing (may need DNS and destination IP rules)

#### Practical Code Examples

**Example 1: Bidirectional Web-to-API Communication**
```yaml
---
# API Ingress: Accept from web tier
kind: NetworkPolicy
metadata:
  name: api-ingress
  namespace: default
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
          tier: web
    ports:
    - protocol: TCP
      port: 8080

---
# Web Egress: Connect to API
kind: NetworkPolicy
metadata:
  name: web-egress-to-api
  namespace: default
spec:
  podSelector:
    matchLabels:
      tier: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 8080
  # DNS egress (CRITICAL)
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53

---
# API Egress: Send responses back to web
# (IMPORTANT: Required for bidirectional!)
kind: NetworkPolicy
metadata:
  name: api-egress-to-web
  namespace: default
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 3000-3100  # Ephemeral port range for responses
```

**Example 2: External Service Access**
```yaml
---
# Pod that needs to send metrics to external Prometheus
kind: NetworkPolicy
metadata:
  name: app-egress-to-prometheus
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Egress
  egress:
  # DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Prometheus (using CIDR for external service)
  - to:
    - ipBlock:
        cidr: 192.168.1.100/32  # External Prometheus IP
    ports:
    - protocol: TCP
      port: 9090
```

**Example 3: Validation Script**
```bash
#!/bin/bash
# Validate ingress/egress rule pair

set -e

NAMESPACE=$1
POD_LABEL=$2
TARGET_POD_LABEL=$3
PORT=$4

echo "=== Testing bidirectional connectivity ==="
echo "Source: $POD_LABEL"
echo "Target: $TARGET_POD_LABEL:$PORT"

# Get pod names
SOURCE_POD=$(kubectl get pod -n $NAMESPACE -l $POD_LABEL -o jsonpath='{.items[0].metadata.name}')
TARGET_POD=$(kubectl get pod -n $NAMESPACE -l $TARGET_POD_LABEL -o jsonpath='{.items[0].metadata.name}')
TARGET_IP=$(kubectl get pod -n $NAMESPACE $TARGET_POD -o jsonpath='{.status.podIP}')

echo "Source pod: $SOURCE_POD"
echo "Target pod: $TARGET_POD ($TARGET_IP)"

# Test connectivity
echo -e "\n=== Testing: $SOURCE_POD → $TARGET_POD:$PORT ==="
kubectl exec -it -n $NAMESPACE $SOURCE_POD -- \
  timeout 5 nc -zv $TARGET_IP $PORT || echo "Connection failed"

# Check NetworkPolicy rules
echo -e "\n=== Active NetworkPolicies in $NAMESPACE ==="
kubectl get networkpolicies -n $NAMESPACE -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

echo -e "\n=== Checking policy rules ==="
kubectl get networkpolicies -n $NAMESPACE -o jsonpath='{range .items[*]}{"Policy: "}{.metadata.name}{"\n"}{"  Ingress: "}{.spec.policyTypes[*]}{"\n"}{end}'
```

---

### Policy Types

#### Textual Deep Dive

**Internal Mechanism**:

The `policyTypes` field in a NetworkPolicy determines which direction is controlled:

| policyTypes | Ingress | Egress | Behavior |
|---------|---------|--------|----------|
| `[Ingress]` | ✓ Controlled | ✗ Unrestricted | Block inbound, allow all outbound |
| `[Egress]` | ✗ Unrestricted | ✓ Controlled | Allow all inbound, block outbound |
| `[Ingress, Egress]` | ✓ Controlled | ✓ Controlled | Block both unless rules allow |
| *(omitted)* | ✓ Controlled | ✓ Controlled | Same as both specified |

**When no rules are defined**:
- Empty `ingress: []` = deny all ingress
- Empty `egress: []` = deny all egress
- No rules in the array at all = deny all in that direction

**Architecture Role**: Policy types enable **asymmetric trust models**:
- A service may trust all inbound requests but control all outbound connections
- Or: allow all inbound but deny external egress (prevents data exfiltration)

**Production Usage Patterns**:

1. **Web-tier service**: Only ingress control (usually allows any outbound to backends)
   ```yaml
   policyTypes: [Ingress]
   ```

2. **Database service**: Strict both directions
   ```yaml
   policyTypes: [Ingress, Egress]
   ```

3. **Monitoring/Logging agent**: Only egress control
   ```yaml
   policyTypes: [Egress]
   ```

**DevOps Best Practices**:
- Default to controlling both (Ingress + Egress) unless there's a specific reason
- If controlling only Ingress, be aware outbound is completely unrestricted
- Document the business reason for asymmetric policies
- Test policy changes with traffic in both directions
- Use Cilium policy audit mode (logs without enforcement) for safe rollout

**Common Pitfalls**:
- Specifying `policyTypes: [Ingress]` but traffic still blocked (forgot: return traffic needs egress rules)
- Assuming "no rules" means allow all (it actually means deny all)
- Creating a policy that controls neither direction (forgot policyTypes field entirely)

---

### How Network Policies Work Under the Hood

#### Textual Deep Dive

**Internal Mechanism**:

When you create a NetworkPolicy:

1. **API Server receives it** → validates schema
2. **CNI Controller watches NetworkPolicy objects** via watch API
3. **CNI translates to OS-level rules**:
   - Calico: iptables chains
   - Cilium: eBPF hooks
   - Weave: vxlan + firewall
4. **OS kernel enforces rules** at packet-processing level

**For Calico (traditional iptables implementation)**:

```
Incoming Packet Flow:
    [NIC receives packet]
        ↓
    [iptables chain: CALICO_IN]
        ↓
    ┌─────────────────────────────┐
    │ Check NetworkPolicy rules   │
    │ Source IP/pod labels        │
    │ Destination port            │
    └─────────────────────────────┘
        ↓
    [Match found] → ACCEPT packet
    [No match] → Implicit DENY → DROP
        ↓
    [Deliver to pod]
```

**For Cilium (eBPF implementation)**:

```
[NIC receives packet]
    ↓
[eBPF hook at NIC driver level]
    ↓
[eBPF program (compiled from NetworkPolicy)]
    ↓
┌─────────────────────────────┐
│ Check policy rules in kernel│
│ (NO context switch!)        │
│ (NO userspace involvement!) │
└─────────────────────────────┘
    ↓
[ALLOW/DROP decision in kernel]
    ↓
[Deliver or discard]
```

**Key architectural differences**:
- **Calico/iptables**: Packet traverses userspace iptables rules for each rule
  - More flexible (supports complex rules)
  - Higher latency (context switches)
  - Better observability (iptables rules visible via `iptables -L`)

- **Cilium/eBPF**: Program compiled into kernel bytecode
  - Very fast (no context switches)
  - Can see program output via BPF tracing
  - Limited to what eBPF can express

**CNI Synchronization**:

The CNI controller continuously reconciles NetworkPolicy objects with OS-level rules:

```
[NetworkPolicy object] → [Watch API] → [CNI Controller]
                                            ↓
                                    [Translate to rules]
                                            ↓
                                    [Write to OS]
                                            ↓
                                    [Monitor for drift]
                                            ↓
                            [If rules deleted] → [Restore]
```

This means:
- Accidentally deleting iptables rules doesn't permanently break policies
- Policies are self-healing
- CNI restarts automatically restore policies

**Architecture Role**: Kubernetes separates **specification** (NetworkPolicy YAML) from **implementation** (CNI-specific):
- You describe "allow traffic from X to Y"
- CNI handles "how should OS enforce this"
- Multiple CNIs can enforce the same policy differently

This abstraction enables:
- CNI flexibility without changing NetworkPolicy declarations
- Portability across clusters
- Testing policies before enforcement (audit mode)

**Production Usage Patterns**:

1. **Gradual Rollout Pattern** (Using Cilium):
   ```bash
   # Step 1: Install policy in audit mode (logs violations without dropping)
   cilium policy import <policy.yaml> --audit-only
   
   # Step 2: Monitor logs for false positives
   kubectl logs cilium-*** -n cilium | grep policy-denied
   
   # Step 3: Fix false positives
   
   # Step 4: Enable enforcement
   cilium policy import <policy.yaml>
   ```

2. **Debugging Network Policy Enforcement**:
   ```bash
   # Check Calico rules
   calicoctl get networkpolicies --all-namespaces
   
   # Check iptables rules on node
   sudo iptables -t filter -L CALICO_IN -n -v
   
   # Check CNI logs
   kubectl logs -n kube-system -l k8s-app=calico-node
   ```

**DevOps Best Practices**:
- Know which CNI you're using before declaring policies (affects enforcement)
- Test policies in staging with the exact CNI version as production
- Monitor policy denial logs as a leading indicator of application issues
- Use policy assertions in tests (Cilium provides testing framework)
- Never rely on policies alone for security (implement defense in depth)

**Common Pitfalls**:
- Assuming policies work without verifying CNI controller is running
- Writing policies for a different CNI than what's installed
- Not accounting for kubelet liveness/readiness probe traffic (will be blocked)
- Policies preventing Kubernetes system components from functioning
- Debugging policies only when traffic is failing (too late—test proactively)

#### Practical Code Examples

**Example 1: Debugging Script**
```bash
#!/bin/bash
# Analyze NetworkPolicy enforcement

NAMESPACE=${1:-default}

echo "=== CNI Type Detection ==="
# Detect CNI
if kubectl get daemonset -n kube-system -l k8s-app=calico-node &>/dev/null; then
  echo "CNI: Calico (iptables-based)"
  CNI=calico
elif kubectl get daemonset -n kube-system -l k8s-app=cilium &>/dev/null; then
  echo "CNI: Cilium (eBPF-based)"
  CNI=cilium
elif kubectl get daemonset -n kube-system -l app=weave-net &>/dev/null; then
  echo "CNI: Weave"
  CNI=weave
else
  echo "CNI: Unknown or NetworkPolicy not supported"
  CNI=unknown
fi

echo -e "\n=== NetworkPolicies in $NAMESPACE ==="
kubectl get networkpolicies -n $NAMESPACE

echo -e "\n=== Checking NetworkPolicy Status ==="
kubectl get networkpolicies -n $NAMESPACE -o jsonpath='{range .items[*]}{"Name: "}{.metadata.name}{"\n"}{.spec}{"\n\n"}{end}'

case $CNI in
  calico)
    echo -e "\n=== Calico Policy Rules ==="
    NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
    echo "Checking rules on node: $NODE"
    kubectl debug node/$NODE -it --image=ubuntu -- iptables -L -n | grep -A20 "CALICO_IN"
    ;;
  cilium)
    echo -e "\n=== Cilium BPF Program Status ==="
    CILIUM_POD=$(kubectl get pod -n cilium-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
    kubectl exec -n cilium-system $CILIUM_POD -- cilium bpf policy get
    ;;
esac

echo -e "\n=== Warning: Check kubelet network access ==="
# Kubelet needs to access pods for probes
echo "Ensure NetworkPolicy allows:"
echo "  - Kubelet → Pod (ports 10250 for kubelet API)"
echo "  - Pod → Kubelet (return traffic to ephemeral ports)"
```

**Example 2: Enforcement Verification**
```bash
#!/bin/bash
# Verify a policy is actually enforced

set -e

NAMESPACE=$1
POLICY_NAME=$2
SOURCE_LABEL=$3
DEST_LABEL=$4
PORT=$5

echo "=== Verifying NetworkPolicy Enforcement ==="
echo "Policy: $POLICY_NAME"
echo "Namespace: $NAMESPACE"

# Get pod IPs
SOURCE_IP=$(kubectl get pod -n $NAMESPACE -l $SOURCE_LABEL -o jsonpath='{.items[0].status.podIP}')
DEST_IP=$(kubectl get pod -n $NAMESPACE -l $DEST_LABEL -o jsonpath='{.items[0].status.podIP}')
DEST_POD=$(kubectl get pod -n $NAMESPACE -l $DEST_LABEL -o jsonpath='{.items[0].metadata.name}')

echo -e "\nSource IP: $SOURCE_IP"
echo "Dest IP: $DEST_IP"

# Start listener on destination
kubectl exec -n $NAMESPACE $DEST_POD -- bash -c "nohup nc -l -p $PORT > /tmp/listener.log 2>&1 &" || true

sleep 1

# Send traffic from source
SOURCE_POD=$(kubectl get pod -n $NAMESPACE -l $SOURCE_LABEL -o jsonpath='{.items[0].metadata.name}')
echo -e "\nAttempting connection: $SOURCE_IP → $DEST_IP:$PORT"

kubectl exec -n $NAMESPACE $SOURCE_POD -- bash -c "echo 'test' | timeout 3 nc $DEST_IP $PORT" && \
  echo "✓ Connection successful (policy allows)" || \
  echo "✗ Connection denied (policy blocks)"

# Check if policy exists
if kubectl get networkpolicy $POLICY_NAME -n $NAMESPACE &>/dev/null; then
  echo -e "\n✓ Policy exists: $POLICY_NAME"
  kubectl get networkpolicy $POLICY_NAME -n $NAMESPACE -o yaml
else
  echo -e "\n✗ Policy not found: $POLICY_NAME"
fi
```

#### ASCII Diagrams

```
NetworkPolicy Processing Pipeline:

[NetworkPolicy YAML created]
        ↓
[kube-apiserver validates]
        ↓
[CNI Controller watches via Watch API]
        ↓
[Translate to CNI-specific rules]
        ├─ Calico: iptables rules
        ├─ Cilium: eBPF programs
        └─ Weave: vxlan rules
        ↓
[Apply to kernel]
        ├─ iptables: Modifies filter/mangle tables
        ├─ eBPF: Loads into XDP/TC hooks
        └─ vxlan: Updates tunnel config
        ↓
[Packet processing includes policy checks]
        ↓
[Drift detection: Monitor for manual changes]
        ↓
[If rules deleted/modified: Restore from API]


Calico vs Cilium Performance Model:

CALICO (iptables):
Packet → [Context Switch] → iptables rule 1 → ... → rule N → [Context Switch] → Drop/Accept
         High latency, high observability

CILIUM (eBPF):
Packet → [eBPF XDP hook] → [In-kernel bytecode] → Drop/Accept
         Low latency, low overhead
```

---

### Network-level Firewalls

#### Textual Deep Dive

**Internal Mechanism**:

"Network-level Firewalls" in Kubernetes context refers to controls at multiple layers:

1. **Pod Network Interface** (CNI enforcement) - covered above
2. **Node Network Interface** (OS firewall rules)
3. **Cloud Provider Security Groups** (AWS Security Groups, GCP Firewall Rules)
4. **Ingress Controller** (ingress-nginx, Istio, HAProxy)

**Node-level Firewall Rules**:

Every node runs hosting Kubernetes pods. The node's OS firewall can:
- Allow/deny traffic to all pods on that node
- Allow/deny specific ports to the node itself
- Allow/deny egress to external systems

**Cloud Provider Level**:

```
Cloud Provider Network Level:
┌─────────────────────────────────┐
│ AWS/GCP/Azure Security Group    │
│ (Operates on Node ENI/NIC)      │
├─────────────────────────────────┤
│  Allows/blocks traffic to node  │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│ Node OS Firewall (iptables)     │
│ (Operates on node routing)      │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│ CNI NetworkPolicy (Pod level)   │
│ (Operates on pod interfaces)    │
└─────────────────────────────────┘
           ↓
┌─────────────────────────────────┐
│ Application Firewall/WAF        │
│ (Layer 7 filtering)             │
└─────────────────────────────────┘
```

**Architecture Role**: Layered firewall defenses provide **defense in depth**:
- Cloud provider firewall: Blocks unauthorized cluster access
- Node firewall: Prevents compromised pods from reaching system components
- NetworkPolicy: Prevents pod-to-pod lateral movement
- Application firewall: Blocks malicious requests

**Production Usage Patterns**:

1. **Egress Lockdown Pattern** (AWS EKS):
   ```
   Cloud Security Group: Allow egress only to known IPs
   ↓
   Node iptables: Allow egress to AWS metadata service
   ↓
   NetworkPolicy: Allow pod-specific egress rules
   ↓
   Application: Validates outbound connections
   ```

2. **Ingress Filtering Pattern**:
   ```
   Cloud LB/WAF: Pre-filter malicious requests
   ↓
   Ingress Controller: Route to specific services
   ↓
   NetworkPolicy: Allow from Ingress Controller only
   ↓
   Application: Validates incoming data
   ```

**DevOps Best Practices**:

- **Cloud-level rules** should allow broad cluster communication internally
- **Node-level rules** should be minimal (Kubernetes system traffic)
- **NetworkPolicy** should enforce specific security domains
- **Application-level** should validate untrusted input
- Test firewall changes in stages (cloud → node → pod → app)
- Document firewall exceptions with business justification

**Common Pitfalls**:
- Blocking Kubernetes API traffic with node firewall (breaks kubelet)
- Assuming NetworkPolicy works without allowing it at cloud level
- Cloud SG too restrictive (blocks pod-to-pod cross-node traffic)
- Forgetting to allow DNS (port 53 UDP) at all levels
- Rules for IPv4 but not IPv6 (or vice versa)

#### Practical Code Examples

**Example 1: AWS EKS Security Group Example**
```tf
# Terraform code for EKS node security group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "eks-node-"
  vpc_id      = aws_vpc.main.id

  # Allow nodes to communicate with each other
  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
  }

  # Allow Kubelet API (required)
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  # Allow external traffic via LoadBalancer (if applicable)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress: Allow external API calls (restrict if security requires)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-sg"
  }
}
```

**Example 2: Node-level iptables Rules**
```bash
#!/bin/bash
# Lock down node firewall for Kubernetes

# Allow Kubernetes system ports
iptables -A INPUT -p tcp --dport 10250 -j ACCEPT   # Kubelet API
iptables -A INPUT -p tcp --dport 10251 -j ACCEPT   # Scheduler (if local)
iptables -A INPUT -p tcp --dport 10252 -j ACCEPT   # Controller Manager (if local)

# Allow DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT

# Allow from cluster CIDR
iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT

# Allow SSH for management
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Default deny
iptables -P INPUT DROP

# Save rules
ip6tables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6
```

**Example 3: GCP Firewall Rules**
```gcloud
# Allow traffic between GKE nodes
gcloud compute firewall-rules create gke-internal \
  --network=default \
  --allow=tcp,udp,icmp \
  --source-tags=gke-node \
  --target-tags=gke-node

# Allow external LoadBalancer traffic
gcloud compute firewall-rules create gke-external \
  --network=default \
  --allow=tcp:80,tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=gke-node
```

---

### Segmentation Strategies

#### Textual Deep Dive

**Internal Mechanism**:

Network segmentation divides a cluster into security zones based on trust levels:

1. **Zero-Trust Segmentation**: No implicit trust, explicit allow for every connection
2. **Network Zones**: Group pods by layer (web, api, db) with rules between zones
3. **Tenant Isolation**: Separate segments per tenant/customer
4. **Workload Classification**: Segment by sensitivity (public, internal, confidential)

**Common Segmentation Models**:

```
Model 1: three-tier Application
┌───────────────────────────────────────┐
│ Zone 1: External Ingress              │
│ (Web tier, has external LB)           │
├───────────────────────────────────────┤
│ Zone 2: Internal APIs                 │
│ (API services, no external access)    │
├───────────────────────────────────────┤
│ Zone 3: Data Layer                    │
│ (Databases, cache, internal only)     │
└───────────────────────────────────────┘

Model 2: Multi-tenant
┌───────────────────────────────────────┐
│ Shared Namespace: Monitoring/Logging  │
├───────────────────────────────────────┤
│ Tenant A Namespace (isolated)         │
├───────────────────────────────────────┤
│ Tenant B Namespace (isolated)         │
├───────────────────────────────────────┤
│ Tenant C Namespace (isolated)         │
└───────────────────────────────────────┘

Model 3: Sensitivity-based
┌───────────────────────────────────────┐
│ Public: Public-facing services        │
│  └─ Can access Internet without auth  │
├───────────────────────────────────────┤
│ Internal: Business logic               │
│  └─ Cannot access external internet    │
├───────────────────────────────────────┤
│ Confidential: Data handling            │
│  └─ Cannot access anything but purpose│
└───────────────────────────────────────┘
```

**Architecture Role**: Segmentation enables:
- **Blast radius containment**: If one pod is compromised, lateral movement is blocked
- **Compliance adherence**: Data flow can be audited and controlled
- **Performance optimization**: Policies prevent noisy neighbors
- **Security testing**: Verify segmentation with chaos engineering

**Production Usage Patterns**:

1. **Namespace-based Isolation**:
   ```yaml
   Namespaces:
   - production
   - staging
   - development
   
   NetworkPolicy at cluster level:
   - Allow within production namespace
   - Block all cross-namespace by default
   - Explicitly allow staging→production for tests
   ```

2. **Label-based Segmentation** (within namespace):
   ```yaml
   Pod Labels:
   - risk: public | internal | confidential
   - team: payments | identity | platform
   - tier: web | api | db
   
   Policies segment pods by combinations of labels
   ```

3. **Tenant Isolation** (SaaS):
   ```yaml
   Tenant A - Namespace: tenant-a
   Tenant B - Namespace: tenant-b
   
   Policies ensure:
   - No cross-tenant traffic
   - No shared secrets access
   - Tenant-specific audit logs
   ```

**DevOps Best Practices**:

1. **Start with clear security zones**: Define trust boundaries before implementing policies
2. **Document segmentation schema**: Keep a diagram of zone interactions
3. **Test boundary enforcement**: Use network policies in staging with synthetic traffic
4. **Version control policies**: Store in Git with code reviews
5. **Monitor violations**: Alert on denied traffic (may indicate compromised pod)
6. **Plan for exceptions**: Have process for granting exceptions, not bypassing policies
7. **Automate policy generation**: Use templates/controllers for consistency

**Common Pitfalls**:
- Over-segmentation: Rules become unmaintainable (hundreds of policies)
- Under-segmentation: Everyone can access everything (defeats purpose)
- Policies without enforcement: Rules exist but CNI isn't enforcing
- Forgetting system namespaces: Policies in kube-system, kube-public, etc.
- Assuming segmentation is secure by default (it's not—you must verify)

#### Practical Code Examples

**Example 1: Three-Tier Application Segmentation**
```yaml
---
# 1. Namespace Setup
apiVersion: v1
kind: Namespace
metadata:
  name: production

---
# 2. Label nodes/namespaces for reference
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production

---
# 3. Default deny all ingress in production
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
# 4. Default deny all egress
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny-egress
  namespace:production
spec:
  podSelector: {}
  policyTypes:
  - Egress

---
# 5. Allow DNS (required for all)
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: allow-dns-egress
  namespace: production
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

---
# 6. Zone 1: Web tier ingress (from external LB)
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: web-ingress-external
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx  # Allow from Ingress Controller
    ports:
    - protocol: TCP
      port: 8080

---
# 7. Zone 1 → Zone 2: Web to API traffic
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: api-ingress-from-web
  namespace: production
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
          tier: web
    ports:
    - protocol: TCP
      port: 5000

---
# 8. Zone 2 → Zone 3: API to Database traffic
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: db-ingress-from-api
  namespace: production
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
# 9. Web → API egress
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: web-to-api-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: web
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 5000
```

**Example 2: Multi-Tenant Segmentation**
```yaml
---
# Tenant A: Complete isolation
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-a
  labels:
    tenant: a

---
# NetworkPolicy: No cross-tenant traffic
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: tenant-a-deny-cross-tenant
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}  # Only from same namespace
  egress:
  - to:
    - podSelector: {}  # Only to same namespace
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system  # Allow DNS
```

---

### Best Practices for Network Policies

#### Textual Deep Dive

**Core Principles for Production Network Policies**:

1. **Default Deny Philosophy**: Start with deny-all, explicitly allow required connections
2. **Immutable Documentation**: Every policy must have clear business/technical justification
3. **Testing Requirement**: Policies must be validated in staging before production
4. **Observability First**: Monitor policy violations as a security signal
5. **Graceful Degradation**: Network failures should not cascade across the cluster

**Production Readiness Checklist**:

- [ ] CNI plugin installed and verified to support NetworkPolicies
- [ ] Policies tested with actual production traffic patterns
- [ ] DNS (port 53 UDP) explicitly allowed where needed
- [ ] Kubelet traffic whitelisted (port 10250, health check IPs)
- [ ] Policies for both directions (ingress + egress)
- [ ] Fallback rules documented (e.g., if primary database unreachable)
- [ ] Monitoring/alerting for policy violations enabled
- [ ] RBAC auditing enabled (who can modify policies)
- [ ] Runbooks for common policy troubleshooting

**DevOps Best Practices Applied**:

1. **GitOps for Policies**:
   ```bash
   # Store policies in Git, review before apply
   git checkout policies/ --
   kubectl apply -f policies/
   ```

2. **Policy Validation in CI/CD**:
   ```bash
   # Validate syntax
   kubectl apply --dry-run=client -f policies/
   
   # Validate no circular dependencies
   # Validate against pod selectors
   ```

3. **Gradual Rollout** (Cilium):
   ```bash
   cilium policy import policies/ --audit
   # Monitor for 7 days
   cilium policy import policies/ --enforce
   ```

4. **Policy Visualization**:
   ```bash
   # Generate network graph showing policy connections
   kubectl get networkpolicies -A -o json | \
     cilium-policy-graph > topology.svg
   ```

**Common Anti-Patterns to Avoid**:

| Anti-Pattern | Problems | Solution |
|---|---|---|
| `podSelector: {}` (match all) with allow rules | Accidentally allows everything | Use explicit labels |
| Policies in one direction only | Return traffic blocked | Test bidirectional |
| Hardcoded pod IPs in `ipBlock` | Breaks on scale/recreate | Use pod selectors |
| Mixing Ingress & Egress in wrong namespace | Confused ownership | Policies live in target namespace |
| No monitoring of violations | Silent failures for years | Alert on denied packets |
| Policies so strict nothing works | Operational burden | Test in staging first |

**Performance Optimization for Policies**:

1. **Order matters**: iptables evaluates rules in order
   - Place most-used rules first
   - Combine similar rules to reduce rule count

2. **Label efficiency**: More specific labels = faster matching
   - `tier: api` (quick)
   - `app: my-api, version: v2, team: backend, env: prod` (slower)

3. **CNI-level optimization**:
   - Cilium: Use `--enable-policy=always` for faster startup
   - Calico: Tune iptables lock contention

```
Example Performance Impact:

10 NetworkPolicies with 100 selectors each = ~1000 iptables rules
- Packet evaluation: 1000 comparisons per packet
- With throughput of 100,000 pps = 100M comparisons/sec

vs.

10 NetworkPolicies with optimized selectors = ~100 iptables rules
- Packet evaluation: 100 comparisons per packet
- With throughput of 100,000 pps = 10M comparisons/sec

10x performance difference possible with optimization!
```

#### Practical Code Examples

**Example 1: Production-Ready Policy Template**
```yaml
---
# Network Policy Best Practice Template
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: {{ policy_name }}
  namespace: {{ namespace }}
  labels:
    app: {{ app_name }}
    version: v1
  annotations:
    # Document the business requirement
    business-justification: |
      Allow {{ source_app }} to {{ target_app }} for {{ purpose }}.
      User Story: {{ jira_ticket }}
    # Document the technical requirement
    technical-notes: |
      Connection: {{ source_app }}:{{ source_port }} → {{ target_app }}:{{ target_port }}
      Protocol: {{ protocol }}
      Expected QPS: {{ expected_qps }}
    # Approval from security team
    security-approved-by: {{ security_team_member }}
    security-approved-date: {{ approval_date }}
    # Runbook for troubleshooting
    troubleshooting-guide: |
      If traffic is blocked:
      1. Check pod labels match selectors: kubectl get pod --show-labels
      2. Verify target port is correct: kubectl get svc
      3. Check CNI is enforcing: kubectl get networkpolicies
      4. Check node CNI logs: docker logs $(docker ps | grep calico-node | cut -d' ' -f1)

spec:
  podSelector:
    matchLabels:
      app: {{ target_app }}
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: {{ source_app }}
    ports:
    - protocol: TCP
      port: {{ target_port }}
  
  egress:
  # Must allow DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  
  # Allow return traffic + ephemeral ports
  - to:
    - podSelector:
        matchLabels:
          app: {{ source_app }}
    ports:
    - protocol: TCP
      port: 1024-65535
```

**Example 2: Policy Validation Script**
```bash
#!/bin/bash
# Comprehensive NetworkPolicy validation

NAMESPACE=${1:-default}

echo "=== Step 1: Verify CNI Support ==="
if ! kubectl get crd networkpolicies.networking.k8s.io &>/dev/null; then
  echo "ERROR: NetworkPolicies CRD not found!"
  exit 1
fi
echo "✓ NetworkPolicies supported"

echo -e "\n=== Step 2: Identify CNI ==="
if kubectl get daemonset -n kube-system -l k8s-app=calico-node &>/dev/null; then
  echo "✓ Using Calico"
elif kubectl get daemonset -n kube-system cilium &>/dev/null; then
  echo "✓ Using Cilium"
else
  echo "? CNI unknown (might still support policies)"
fi

echo -e "\n=== Step 3: List all policies in $NAMESPACE ==="
kubectl get networkpolicies -n $NAMESPACE

echo -e "\n=== Step 4: Validate policy syntax ==="
for policy in $(kubectl get networkpolicies -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
  echo -n "Policy $policy: "
  if kubectl get networkpolicy $policy -n $NAMESPACE -o json | jq empty 2>/dev/null; then
    echo "✓ Valid JSON"
  else
    echo "✗ Invalid JSON"
  fi
done

echo -e "\n=== Step 5: Check for common mistakes ==="

# Check for unresolved pod selectors
echo "Checking for policies with unreachable selectors..."
for policy in $(kubectl get networkpolicies -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
  SELECTOR=$(kubectl get networkpolicy $policy -n $NAMESPACE -o jsonpath='{.spec.podSelector.matchLabels}')
  MATCHING_PODS=$(kubectl get pods -n $NAMESPACE -l "$SELECTOR" --no-headers 2>/dev/null | wc -l)
  
  if [ "$MATCHING_PODS" -eq 0 ]; then
    echo "⚠ Policy $policy matches 0 pods (selector: $SELECTOR)"
  else
    echo "✓ Policy $policy matches $MATCHING_PODS pods"
  fi
done

echo -e "\n=== Step 6: Verify DNS access ==="
echo "Checking if DNS (port 53 UDP) is explicitly allowed..."
EGRESS_TO_DNS=$(kubectl get networkpolicies -n $NAMESPACE -o json | \
  jq '.items[] | select(.spec.egress[]?. | select(.ports[]? | select(.port == 53)))')

if [ ! -z "$EGRESS_TO_DNS" ]; then
  echo "✓ At least one policy allows DNS egress"
else
  echo "⚠ No explicit DNS egress rule found (may fail))"
fi

echo -e "\n=== Step 7: Validate pod labels match selectors ==="
echo "Sample pods:"
kubectl get pods -n $NAMESPACE --show-labels | head -5
```

**Example 3: Monitoring Policy Violations**
```bash
#!/bin/bash
# Monitor and alert on denied packets

echo "=== Monitoring NetworkPolicy Violations ==="

# For Calico
if kubectl get daemonset -n kube-system -l k8s-app=calico-node &>/dev/null; then
  echo "Tailing Calico deny logs..."
  
  NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
  kubectl debug node/$NODE -it --image=ubuntu -- \
    tail -f /var/log/calico/deny.log | \
    awk '{print "DENIED: " $0}'
fi

# For Cilium
if kubectl get daemonset -n kube-system -l k8s-app=cilium &>/dev/null; then
  echo "Getting Cilium denied packets..."
  
  POD=$(kubectl get pod -n cilium-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
  kubectl exec -n cilium-system $POD -- cilium monitor | grep DENIED
fi
```

---

## RBAC & Security Basics

RBAC (Role-Based Access Control) is Kubernetes' native authorization system that determines "what authenticated identities can do" in the cluster. Combined with authentication, it forms the foundation of API server access control.

### Role-Based Access Control

#### Textual Deep Dive

**Internal Mechanism**:

RBAC operates in Kubernetes at the API server level, **after** authentication succeeds:

```
[Request arrives] 
    ↓
[TLS verification: Is certificate valid?] - Authentication
    ↓
[Extract identity: Who is this?]
    ↓
[RBAC decision: What can they do?] - Authorization
    ↓
[Mutation/Validation webhooks]
    ↓
[Request processed or denied]
```

The RBAC system consists of four primary object types:

1. **Role**: Collection of permissions scoped to a namespace
2. **ClusterRole**: Collection of permissions cluster-wide
3. **RoleBinding**: Attach a Role to subjects (users, groups, ServiceAccounts) in a namespace
4. **ClusterRoleBinding**: Attach a ClusterRole to subjects cluster-wide

**How RBAC evaluation works**:

```
Input: Identity (User/ServiceAccount) + Action (verb) + Resource + Namespace
    ↓
[Search RoleBindings in target namespace]
    ↓
[Search ClusterRoleBindings]
    ↓
[Aggregate all matching Roles + ClusterRoles]
    ↓
[Check if any rule matches: resource + verb + namespace]
    ↓
┌───────────────────────────────────────┐
│ Match found? → ALLOW                  │
│ No match? → DENY (default)            │
└───────────────────────────────────────┘
```

**Key architectural principle**: RBAC is **deny-by-default**. If no rule explicitly allows an action, it's denied.

Architecture Role: RBAC separates **concerns**:
- Identity Management (handled by authentication provider)
- Authorization (handled by RBAC)
- Resource ownership (optional, handled by RBAC)

This separation allows:
- Multiple auth methods (certificates, tokens, OIDC) with one RBAC system
- Fine-grained control without touching auth provider
- Different teams managing auth vs. authorization

**Production Usage Patterns**:

1. **Developers**: Limited to their namespace, no cluster-wide access
   - Can create/edit pods, deployments in development namespace
   - Cannot view other namespaces or cluster resources

2. **Operations**: Broad cluster access with audit trail
   - Can view all resources
   - Can edit critical resources only via automation
   - Changes logged and alerting enabled

3. **CI/CD**: Highly restricted ServiceAccounts
   - Read-only in source repos
   - Write-only to specific deployments
   - No access to secrets or other applications' ServiceAccounts

4. **Automation**: Minimal required permissions
   - Prometheus: Read pods/nodes only
   - Ingress Controller: Read ingress + write to status
   - Autoscaler: Read pods + modify deployment replicas

**DevOps Best Practices**:

1. **Principle of Least Privilege**: Every identity gets minimum required permissions
2. **Role Reuse**: Create generic roles usable across apps (e.g., "read-logs")
3. **Multiple Levels**: Use namespaced Roles when possible (simpler to revoke)
4. **Audit Everything**: Enable RBAC audit logging to track permission usage
5. **Regular Reviews**: Audit Who has What access, remove unused roles
6. **Test Enforcement**: Use `kubectl auth can-i` in CI/CD to verify access

**Common Pitfalls**:
- Granting cluster-admin to developers for convenience (too broad)
- Service account credentials left in config files (security risk)
- No audit logging enabled (can't investigate breaches)
- Roles too specific (hundreds of roles for each app)
- Rules so complex they're unmaintainable
- Not testing RBAC rules before deployment

#### Practical Code Examples

**Example 1: Principle of Least Privilege for Different Roles**
```yaml
---
# Role for developers (namespace-scoped)
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: developer
  namespace: development
rules:
# Create/view/edit pods and deployments
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]

# View logs and exec into pods
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]

- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]

# View services
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]

# NO access to secrets, RBAC, cluster resources

---
# ClusterRole for operations (cluster-scoped)
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: operator
rules:
# Read-only access to everything
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]

# Edit specific resources only
- apiGroups: ["apps"]
  resources: ["deployments/scale"]
  verbs: ["update", "patch"]

- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["patch"]  # For taints/labels

# NO access to RBAC or cluster-admin functions

---
# ServiceAccount for CI/CD (minimal permissions)
kind: ServiceAccount
metadata:
  name: ci-cd
  namespace: production

---
# Role for CI/CD to deploy specific app
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ci-cd-deployer
  namespace: production
rules:
# Only can patch image in specific deployment
- apiGroups: ["apps"]
  resources: ["deployments"]
  resourceNames: ["myapp"]  # RESTRICTED to one deployment
  verbs: ["patch", "get"]

# Can check rollout status
- apiGroups: ["apps"]
  resources: ["deployments/status"]
  resourceNames: ["myapp"]
  verbs: ["get"]

---
# ServiceAccount for monitoring (read-only metrics)
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: kube-system

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: prometheus
rules:
# Read nodes and pods for discovery
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "pods"]
  verbs: ["get", "list", "watch"]

# Read metrics
- apiGroups: [""]
  resources: ["services", "endpoints"]
  verbs: ["get", "list", "watch"]
```

---

### ClusterRoles and Roles

#### Textual Deep Dive

**Scope Distinction**:

| Property | Role | ClusterRole |
|----------|------|-------------|
| **Scope** | Single namespace | Entire cluster |
| **Binding** | RoleBinding (in same namespace) | ClusterRoleBinding (cluster-wide) |
| **Use Case** | Team/app-specific permissions | System-wide permissions |
| **Example** | "developers can edit pods in dev namespace" | "sysadmins can edit nodes" |

**Building Blocks**:

Every Role/ClusterRole rule specifies:
- **apiGroups**: Which API groups (e.g., "", "apps", "batch", "rbac.authorization.k8s.io")
- **resources**: Which objects (e.g., "pods", "services", "secrets")
- **resourceNames**: (Optional) Specific instances only
- **verbs**: Which actions (get, list, watch, create, update, patch, delete, etc.)
- **nonResourceURLs**: (ClusterRole only) HTTP paths (e.g., "/api", "/metrics")

**Example rule breakdown**:

```yaml
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  resourceNames: ["frontend", "backend"]  # Only these 2
  verbs: ["get", "patch", "update"]

Allows:
✓ Read deployment "frontend"
✓ Read deployment "backend"
✓ Modify deployment "frontend"
✓ Modify deployment "backend"

Denies:
✗ Read deployment "database" (not in resourceNames)
✗ Delete deployment "frontend" (not in verbs)
✗ Create new deployments (not in verbs)
```

**Aggregation and Composition**:

ClusterRoles can be composed from other ClusterRoles:

```yaml
kind: ClusterRole
metadata:
  name: admin
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["*"]  # All verbs

---
kind: ClusterRole
metadata:
  name: extended-admin
aggregationRule:
  selectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-admin: "true"

# Any ClusterRole with label rbac.authorization.k8s.io/aggregate-to-admin: "true"
# gets automatically included in extended-admin
```

This enables:
- Splitting large roles into component pieces
- Adding new permissions without editing base role
- Plugin architectures where components can declare permissions

**Common Built-in Roles**:

```
Cluster-wide:
- cluster-admin: Complete access to everything (use sparingly!)
- system:masters: Same as cluster-admin (for cert-based auth)
- admin: Full access to most resources (good general admin)
- edit: Can modify most objects (good for developers)
- view: Read-only access (good for auditors)

Namespace-bound:
- admin: Full access within namespace
- edit: Can modify objects in namespace
- view: Read-only in namespace

System roles (don't modify):
- system:authenticated: For all authenticated users
- system:unauthenticated: For all unauthenticated requests
- system:kube-controller-manager: Controller manager component
- system:kubelet: Kubelet component
```

**Architecture Role**: 

Role/ClusterRole separation enables:
1. **Principle of least privilege**: Namespace roles limit scope
2. **Organizational boundaries**: Each namespace gets its own admin
3. **Multi-tenancy**: Tenants can't escape their namespace via RBAC
4. **Testability**: Can test namespace-level rules independently

**Production Usage Patterns**:

1. **Namespace-local admin pattern**:
   ```yaml
   # Give each team admin in their namespace only
   RoleBinding
   name: team-a-admin
   namespace: team-a
   subjects: [group: team-a@company.com]
   roleRef: ClusterRole admin
   
   # team-a can fully manage their namespace
   # but can't access team-b namespace
   ```

2. **Predefined role composition**:
   ```yaml
   # Reuse built-in roles with custom bindings
   # Don't create custom roles if built-ins work
   ```

3. **Custom roles for security boundaries**:
   ```yaml
   # If built-in roles don't fit, create minimal custom role
   # Document why it's needed
   ```

**DevOps Best Practices**:

1. **Use built-in roles when possible**: cluster-admin, admin, edit, view cover 80% of use cases
2. **Prefer namespace roles**: Use Role + RoleBinding instead of ClusterRole when possible
3. **Documentation**: Every custom rule needs comment explaining business need
4. **Version control**: Store all roles in Git with code review
5. **Immutable after creation**: Treat roles as mostly immutable (create new versions, don't modify)
6. **Limit cluster-admin**: Only permanent access for 2-3 sysadmins

**Common Pitfalls**:
- Creating overly broad custom roles when built-ins exist
- Using ClusterRole when Role would work
- Giving cluster-admin to CI/CD (should be minimal sameSA)
- Not documenting why custom roles exist
- Too many role versions causing confusion
- Forgetting to specify namespace in RoleBinding (uses "default")

#### Practical Code Examples

**Example 1: Building Custom Role Hierarchy**
```yaml
---
# Base role: Read logs and status
kind: ClusterRole
metadata:
  name: pod-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]

---
# Extended role: Also exec into pods
kind: ClusterRole
metadata:
  name: pod-debugger
rules:
- apiGroups: [""]
  resources: ["pods/exec", "pods/port-forward"]
  verbs: ["create"]

---
# Developer role: Aggregate pod-reader + pod-debugger
kind: ClusterRole
metadata:
  name: developer
aggregationRule:
  selectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-developer: "true"
rules: []  # Rules automatically filled from aggregation

---
# Label base roles for aggregation
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
  labels:
    rbac.authorization.k8s.io/aggregate-to-developer: "true"
```

**Example 2: Resource-specific Access**
```yaml
---
# Allow only editing image in deployment
kind: Role
metadata:
  name: image-updater
  namespace: production
rules:
# Get current deployment
- apiGroups: ["apps"]
  resources: ["deployments"]
  resourceNames: ["myapp"]
  verbs: ["get"]

# Patch only containers.image field
- apiGroups: ["apps"]
  resources: ["deployments"]
  resourceNames: ["myapp"]
  verbs: ["patch"]

# Cannot delete, cannot modify replicas,cannot modify limits

---
# Testing this role
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-deployer
  namespace: production

---
kind: RoleBinding
metadata:
  name: ci-deployer-binding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io/v1
  kind: Role
  name: image-updater
subjects:
- kind: ServiceAccount
  name: ci-deployer
  namespace: production
```

---

### Role Bindings and ClusterRoleBindings

#### Textual Deep Dive

**Internal Mechanism**:

RoleBindings attach Roles/ClusterRoles to subjects (identities):

```yaml
kind: RoleBinding
metadata:
  name: example
  namespace: default
subjects:  # Who gets the permissions?
- kind: User
  name: alice@company.com
- kind: Group
  name: developers
- kind: ServiceAccount
  name: my-app
  namespace: kube-system

roleRef:  # What permissions do they get?
  apiGroup: rbac.authorization.k8s.io
  kind: Role  # or ClusterRole
  name: editor
```

When a request comes to the API server:

```
[Request from alice@company.com]
    ↓
[Find all RoleBindings and ClusterRoleBindings for alice]
    ↓
[Get Roles/ClusterRoles they reference]
    ↓
[Aggregate all rules]
    ↓
[Check if any rule allows the action]
```

**Subject Types**:

| Type | Represents | Example |
|------|-----------|---------|
| User | Individual person | alice@company.com |
| Group | Group from auth provider | "developers" |
| ServiceAccount | Pod identity | my-app (in namespace) |
| System account | Built-in Kubernetes identity | system:kube-proxy |

**Binding Scope**:

- **RoleBinding**: Grants permissions **in that namespace only**
- **ClusterRoleBinding**: Grants permissions **cluster-wide**

This creates interesting combinations:

```yaml
# Give a ClusterRole via RoleBinding = namespace-scoped access
kind: RoleBinding
metadata:
  name: local-admin
  namespace: team-a
roleRef:
  kind: ClusterRole  # Generic role
  name: admin
subjects:
- kind: Group
  name: team-a

# Result: team-a members are admins ONLY in team-a namespace
# This is the recommended pattern for multi-tenant clusters!
```

**Architecture Role**: 

RoleBinding/ClusterRoleBinding enable:
1. **Separation of role definition from assignment**: Roles describe permissions, bindings assign them
2. **Dynamic adjustments**: Add/remove people without modifying roles
3. **Reusable roles**: One role can be bound multiple times
4. **Audit trails**: Who has what access is visible and traceable

**Production Usage Patterns**:

1. **LDAP/AD integration (in-house enterprise)**:
   ```yaml
   ClusterRoleBindings bind LDAP groups to ClusterRoles
   - developers group → view ClusterRole (read-only)
   - operators group → admin ClusterRole (full access)
   - finance group → no deployment access
   
   Single source of truth: LDAP, no need to update RBAC manually
   ```

2. **OIDC-based (cloud-native SaaS)**:
   ```yaml
   Auth tokens include claim with "roles": ["developer", "qa"]
   
   RoleBindings can reference users from ID token
   Roles updated via OIDC provider changes (e.g., GitHub teams)
   ```

3. **Service account per workload**:
   ```yaml
   Each deployment gets unique ServiceAccount
   Each ServiceAccount has minimal RoleBinding for that app
   If one app is compromised, damage is limited
   ```

**DevOps Best Practices**:

1. **Never use default ServiceAccount**: Create app-specific ServiceAccounts
2. **Bind cluster roles to namespace roles**: Limit scope when possible
3. **Use groups instead of users**: Easier to manage at scale
4. **Audit bindings regularly**: Who has what access?
5. **Revoke permanently**: Don't just disable, remove RoleBinding
6. **Test bindings**: Use `kubectl auth can-i --as=user` to verify

**Common Pitfalls**:
- Binding to default ServiceAccount (applies to all pods in namespace)
- RoleBinding in wrong namespace (permissions don't apply)
- Forgetting namespace parameter in ServiceAccount subject
- Using User instead of Group (doesn't scale with org growth)
- Roles and Bindings inconsistent with RBAC authorization mode
- No record of who requested access (no audit trail)

#### Practical Code Examples

**Example 1: Multi-account Kubernetes Setup**
```yaml
---
# Using built-in roles with custom bindings

# Developers: Edit access to dev namespace
kind: RoleBinding
metadata:
  name: dev-team-edit
  namespace: development
subjects:
- kind: Group
  name: developers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit  # Built-in edit role

---
# QA: View access to prod namespace
kind: RoleBinding
metadata:
  name: qa-team-view
  namespace: production
subjects:
- kind: Group
  name: qa
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # Built-in read-only role

---
# Finance team: No Kubernetes access
# No RoleBinding created → Implicitly denied

---
# Operators: Admin cluster-wide
kind: ClusterRoleBinding
metadata:
  name: operators-admin
subjects:
- kind: Group
  name: operators
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin  # Full access

---
# System component: Prometheus monitoring
kind: ClusterRoleBinding
metadata:
  name: prometheus-scraper
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: monitoring
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # Read-only access
```

---

### Service Accounts

#### Textual Deep Dive

**Internal Mechanism**:

ServiceAccounts are Kubernetes identities for pods. When a pod is created:

```
[Pod created with serviceAccountName: my-app]
    ↓
[Kubernetes creates service account token]
    ↓
[Token mounted in pod at /var/run/secrets/kubernetes.io/serviceaccount/token]
    ↓
[Pod can authenticate to API server using token]
    ↓
[RBAC determines what pod can do]
```

The token is a JSON Web Token (JWT) containing:
- Service account identity
- Namespace
- Expiration time
- Signature (verifiable by kube-apiserver)

**Service Account Lifecycle**:

```
[Create ServiceAccount]
    ↓
[Secret automatically created with token]
    ↓
[Pod spec references ServiceAccount]
    ↓
[Kubelet mounts secret as volume]
    ↓
[Pod authenticates using token]
    ↓
[Token expires (default ~year)]
    ↓
[New token auto-generated]
```

**Security Model**:

Service Accounts separate **pod identity** from **node identity**:
- Node identity: Kubelet credentials (for node permission sandboxing)
- Pod identity: ServiceAccount token (for API access control)

This enables:
- Two pods on same node can have different API permissions
- Stolen pod token doesn't grant node access
- Compromised app can't access other pods' secrets

**Architecture Role**: 

ServiceAccounts are the **bridge between pod workloads and RBAC**:
1. Pods authenticate as ServiceAccounts
2. RBAC controls what ServiceAccounts can do
3. Audit logs trace actions to ServiceAccounts

This creates a **complete audit trail**: Who (ServiceAccount) did what (verb) on what (resource).

**Production Usage Patterns**:

1. **One SA per app/workload**:
   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: myapp-pod
   spec:
     serviceAccountName: myapp  # Custom SA
     containers:
     - image: myapp:latest
   
   # If compromise: Create new Pod, revoke old SA
   ```

2. **Shared monitoring SA**:
   ```yaml
   # All monitoring apps use same SA
   serviceAccountName: prometheus-scraper
   
   # RoleBinding gives prometheus-scraper read access to metrics
   # All monitors have same (limited) access
   ```

3. **CI/CD SA with webhook**:
   ```yaml
   # Deployment uses CI/CD ServiceAccount
   serviceAccountName: ci-deployer
   
   # Webhook validates token, applies policies
   # Only authorized images allowed
   ```

**DevOps Best Practices**:

1. **Never use default ServiceAccount**: Disable it cluster-wide if possible
2. **Minimal token lifetime**: Reduce token validity (default ~1 year too long)
3. **Token rotation**: Regularly rotate SA tokens
4. **Bound tokens**: Use projected volumes for extra security
5. **No long-lived API tokens**: Use short-lived tokens with refresh mechanism
6. **Token encryption at rest**: Secrets should be encrypted in etcd

**Common Pitfalls**:
- Using default ServiceAccount (has broad default access)
- One SA for entire namespace (hard to isolate breaches)
- Hardcoding token in config (should be auto-mounted)
- Not rotating tokens regularly
- ServiceAccount token with cluster-admin (security disaster)
- Exposing token in logs or error messages

#### Practical Code Examples

**Example 1: Secure ServiceAccount Setup**
```yaml
---
# Create namespace
apiVersion: v1
kind: Namespace
metadata:
  name: myapp

---
# Create ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: myapp

---
# Create minimal Role for the app
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: myapp-reader
  namespace: myapp
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["myapp-config"]
  verbs: ["get"]

- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["myapp-secrets"]
  verbs: ["get"]

---
# Bind role to ServiceAccount
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: myapp-reader-binding
  namespace: myapp
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: myapp-reader
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: myapp

---
# Deployment uses the ServiceAccount
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: myapp
spec:
  template:
    spec:
      serviceAccountName: myapp
      automountServiceAccountToken: true
      containers:
      - name: app
        image: myimage:latest
        volumeMounts:
        - name: sa-token
          mountPath: /var/run/secrets/kubernetes.io/serviceaccount
          readOnly: true
      volumes:
      - name: sa-token
        projected:
          sources:
          - serviceAccountToken:
              path: token
              expirationSeconds: 3600  # 1-hour token lifetime
```

**Example 2: Token Inspection**
```bash
#!/bin/bash
# Inspect ServiceAccount token contents

SA_NAME=${1:-default}
NAMESPACE=${2:-default}

echo "=== ServiceAccount: $SA_NAME in $NAMESPACE ==="

# Get the token
TOKEN=$(kubectl get secret -n $NAMESPACE $(kubectl get secret -n $NAMESPACE | grep $SA_NAME | awk '{print $1}') -o jsonpath='{.data.token}' | base64 -d)

echo -e "\n=== Decoded JWT ==="
# JWT is 3 parts: header.payload.signature
HEADER=$(echo $TOKEN | cut -d'.' -f1 | base64 -d)
PAYLOAD=$(echo $TOKEN | cut -d'.' -f2 | base64 -d)

echo "Header:"
echo $HEADER | jq .

echo -e "\nPayload (Claims):"
echo $PAYLOAD | jq .

echo -e "\n=== Testing API Access ==="
# Try to list pods with this token
kubectl --token=$TOKEN --kubeconfig=/dev/null get pods -n $NAMESPACE 2>&1 | head -5
```

---

### Authentication vs Authorization

#### Textual Deep Dive

**Clear Distinction**:

| Dimension | Authentication | Authorization |
|-----------|---|---|
| **Question** | Who are you? | What can you do? |
| **Mechanism** | Certificates, tokens, passwords | RBAC rules matching identity |
| **Happens when** | Before RBAC evaluation | After authentication succeeds |
| **Default behavior** | No default (explicit auth required) | Deny-by-default (explicit allow) |
| **Plugin** | kube-apiserver --authentication-mode | kube-apiserver --authorization-mode |

**Sequence**:

```
[Request arrives with credential (cert, token, etc.)]
    ↓
AUTHENTICATION STAGE:
  ├─ Is the credential valid?
  ├─ Who does it represent?
  └─ Extract identity (User, Group, UID)
    ↓
[If authentication fails → 401 Unauthorized, stop]
    ↓
AUTHORIZATION STAGE:
  ├─ Check RBAC rules for this identity
  ├─ Check if rule exists: resource + verb + namespace?
  └─ Is action allowed?
    ↓
[If authorization fails → 403 Forbidden]
    ↓
[Admission Controllers (mutations, validations)]
    ↓
[Request processed]
```

**Authentication Methods in k8s**:

1. **Certificates (mTLS)**:
   - Each user gets signed certificate
   - Common name becomes username
   - Used for: kubeadm-generated clients, kubelet, kube-proxy
   - Strength: Very secure, production-grade
   - Weakness: Certificate management burden

2. **Bearer Tokens**:
   - Long-lived tokens in files
   - Static tokens (bad security)
   - Service account tokens (good security)

3. **OIDC (OpenID Connect)**:
   - Tokens from external providers (Google, Okta, GitHub)
   - Tokens contain user info + groups
   - Can integrate with corporate SSO
   - Tokens automatically expire

4. **Webhook (custom)**:
   - External service validates credentials
   - Flexible but requires running custom service

5. **Proxy/Impersonation**:
   - Reverse proxy adds authentication header
   - API server trusts proxy header (dangerous if misconfigured)

**Authorization Modes**:

1. **RBAC** (recommended):
   - Declarative, version-controlled
   - Fine-grained control
   - Audit trail built-in
   - Used in 99% of production clusters

2. **ABAC** (deprecated):
   - Policy file-based (hard to manage)
   - No longer recommended

3. **Webhook**:
   - External service decides allow/deny
   - Flexible but requires external infra

4. **Node**:
   - Special authorization for kubelet
   - Automatic, no configuration needed

5. **AlwaysAllow/AlwaysDeny**:
   - Used for testing only

**Architecture Role**:

Separation of Auth + AuthZ enables:
1. **Flexibility**: Change auth method without touching RBAC
2. **Security**: Multiple layers (auth fails → denied, even if RBAC allows)
3. **Auditability**: See who did what via identity + RBAC logs
4. **Compliance**: Different auth methods can meet different regulations

**Production Usage Patterns**:

1. **Enterprise with SSO**:
   ```
   [User logs into company SSO]
   ↓
   [Gets OIDC token with groups from LDAP]
   ↓
   [Token used to authenticate to kube-apiserver]
   ↓
   [RBAC rules match groups to permissions]
   ↓
   Result: Single sign-on for Kubernetes!
   ```

2. **CI/CD Pipeline**:
   ```
   [Pipeline runs in restricted container]
   ↓
   [Kubernetes projects ServiceAccount token]
   ↓
   [Pipeline authenticates to kube-apiserver with token]
   ↓
   [RBAC restricts pipeline to specific deployment]
   ↓
   Result: Secured CI/CD with minimal permissions!
   ```

3. **Multi-cluster federation**:
   ```
   [Central auth system (Keycloak, Okta)]
   ↓
   [Each cluster uses same OIDC provider]
   ↓
   [RBAC synced across clusters]
   ↓
   Result: Unified identity across clusters!
   ```

**DevOps Best Practices**:

1. **Use OIDC for humans**: Tokens auto-expire, centralized management
2. **ServiceAccounts for workloads**: More secure than shared tokens
3. **Short-lived tokens**: Prefer minutes/hours over days/years
4. **Audit all auth events**: Enable audit logging
5. **Separate auth & authz responsibility**: Different teams manage them
6. **Test auth failure paths**: What if auth upstream is down?

**Common Pitfalls**:
- Using static token files (should be OIDC)
- Long-lived tokens without rotation
- Not auditing auth events
- Auth method too loose (everybody can authenticate)
- RBAC rules too strict (nobody can do anything)
- Assuming authentication = authorization (they're independent)

---

### Best Practices for RBAC

#### Textual Deep Dive

**Core Principles for Production RBAC**:

1. **Principle of Least Privilege**: Every identity gets only what it needs
2. **Defense in Depth**: Multiple layers of checks (auth + authz + admission)
3. **Auditability**: Every action traceable to an identity
4. **Separation of Duty**: Different teams manage auth vs. authz vs. infrastructure
5. **Immutability**: Produced RBAC rules are mostly immutable (create new versions)

**RBAC Design Workflow**:

```
Step 1: Identify subjects (users, groups, ServiceAccounts)
    ↓
Step 2: Map business roles (developer, operator, CI/CD, watchdog)
    ↓
Step 3: Define required actions per role
    ↓
Step 4: Create Kubernetes roles matching required actions
    ↓
Step 5: Create bindings matching subjects to roles
    ↓
Step 6: Test with `kubectl auth can-i`
    ↓
Step 7: Monitor via audit logs
    ↓
Step 8: Quarterly review of who has what access
```

**RBAC Testing Checklist**:

- [ ] All developers can view their namespace pods
- [ ] Developers cannot view production namespace
- [ ] CI/CD can deploy only to staging/production
- [ ] CI/CD cannot read secrets in other namespaces
- [ ] Operations can edit nodes but ordinary users cannot
- [ ] Monitoring ServiceAccount can only read metrics
- [ ] No role gives more than necessary permissions
- [ ] Every role documented with business reason

**Anti-Patterns and Fixes**:

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Cluster-admin for everyone | One compromise = full cluster breach | Use minimal roles + RoleBindings |
| One global ServiceAccount | Can't isolate compromised apps | One SA per app |
| Roles never reviewed | Permission creep over time | Quarterly audit of bindings |
| Roles too specific (hundreds) | Unmaintainable, error-prone | Group by business function |
| No audit logging | Can't investigate breaches | Enable audit logging |

**Monitoring RBAC Health**:

```bash
# Audit unused RBAC rules
kubectl describe clusterrole edit | grep -c "verbs"
# If high count, may be over-authorized

# Find who has cluster-admin
kubectl get clusterrolebindings -o json | jq '.items[] | select(.roleRef.name=="cluster-admin")'

# Audit recently used API groups
kubectl get events --all-namespaces | grep "RBAC" | tail -20

# Check for unused ServiceAccounts
kubectl get serviceaccounts -A
# Compare with used ServiceAccounts in audit logs
```

**Compliance Requirements**:

RBAC helps meet security compliance:
- **Least Privilege**: RBAC enforces granular access
- **Audit Trails**: Audit logs show who did what
- **Separation of Duties**: Different roles prevent one person from doing everything
- **Change Management**: RBAC changes are version-controlled and reviewed

Example compliance-driven RBAC:

```yaml
# PCI-DSS requirement: Financial app can only access payment database
kind: Role
metadata:
  name: payment-processor
  annotations:
    compliance-requirement: "PCI-DSS 7.1 - Limit database access"
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["payment-db-connection"]
  verbs: ["get"]

# Regular audits prove compliance
kubectl get role payment-processor -o jsonpath='{.metadata.annotations}'
```

#### Practical Code Examples

**Example 1: Complete RBAC Architecture for SaaS**
```yaml
---
# 1. Developer Role (namespace-scoped)
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: developer
  namespace: development
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["get", "list", "watch", "create"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "update", "patch"]

---
# 2. QA Role (testing environment)
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: qa-tester
  namespace: testing
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]

---
# 3. Operator Role (cluster-wide)
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: operator
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch", "patch"]
- apiGroups: ["apps"]
  resources: ["daemonsets"]
  verbs: ["get", "list", "watch"]

---
# 4. Bindings
kind: RoleBinding
metadata:
  name: developers
  namespace: development
subjects:
- kind: Group
  name: developers@company.com
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer

---
kind: ClusterRoleBinding
metadata:
  name: operators
subjects:
- kind: Group
  name: operators@company.com
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: operator
```

---

### Common Security Pitfalls

#### Textual Deep Dive

**Top 10 Kubernetes Security Pitfalls (RBAC-related)**:

1. **Using default ServiceAccount**
   - Problem: All pods in namespace share same permissions
   - Impact: Compromise of one app affects all apps
   - Fix: Create unique ServiceAccount per app

2. **Granting cluster-admin too broadly**
   - Problem: One compromise = full cluster loss
   - Impact: Attacker can steal secrets, delete resources, access data
   - Fix: Limit cluster-admin to < 5 people, use temporary elevation

3. **Forgetting to limit ServiceAccount token lifetime**
   - Problem: Default token valid for ~1 year
   - Impact: Stolen token works for months/years
   - Fix: Set expirationSeconds in projected volumes

4. **Storing credentials in environment variables**
   - Problem: Leaked in `kubectl describe pod` output, logs
   - Impact: Anyone with describe permission gets secrets
   - Fix: Use secrets mounted as volumes (readOnly), or external auth provider

5. **Not enabling audit logging**
   - Problem: Can't investigate security breaches
   - Impact: Post-breach forensics impossible
   - Fix: Enable audit logging with RBAC rules

6. **RBAC too permissive**
   - Problem: Anyone can do anything (defeats purpose)
   - Impact: No security boundary between users/apps
   - Fix: Start with deny-all, explicitly allow required actions

7. **RBAC too restrictive**
   - Problem: Applications can't function (frustrates engineers)
   - Impact: Engineers bypass RBAC (disable security)
   - Fix: Iterate with applications, test before deployment

8. **Mixing authentication and authorization concerns**
   - Problem: Treating auth failures as authz failures (confusing)
   - Impact: Hard to debug (is it auth or authz?)
   - Fix: Keep logs separate, understand distinction

9. **No audit of who has what access**
   - Problem: Unknown access escalation over time
   - Impact: Attack surface grows invisibly
   - Fix: Monthly audit: `kubectl get rolebindings -A`

10. **One-off exceptions to RBAC**
    - Problem: "Temporarily" gives cluster-admin for debugging
   - Impact: Exception becomes permanent, forgotten about
    - Fix: Use just-in-time access mechanisms, expires automatically

**Detecting Pitfalls**:

```bash
#!/bin/bash
# Security audit script

echo "=== Check 1: Default ServiceAccount usage ==="
kubectl get pods -A -o jsonpath='{range .items[?(@.spec.serviceAccountName=="default")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}'
# If output: Pods using default SA (potential security issue)

echo -e "\n=== Check 2: cluster-admin assignments ==="
kubectl get clusterrolebindings -o json | jq '.items[] | select(.roleRef.name=="cluster-admin") | {name: .metadata.name, subjects: .subjects}'

echo -e "\n=== Check 3: Service accounts with critical access ==="
kubectl get rolebindings,clusterrolebindings -A -o json | jq '.items[] | select(.roleRef.name | contains("admin")) | {namespace: .metadata.namespace, binding: .metadata.name, role: .roleRef.name}'

echo -e "\n=== Check 4: Audit logging enabled ==="
ps aux | grep kube-apiserver | grep audit

echo -e "\n=== Check 5: ServiceAccount token lifetime ==="
# Check if tokens have expiration set
kubectl get pods -A -o json | jq '.items[] | select(.spec.volumes[]?.projected?.sources[]?.serviceAccountToken?.expirationSeconds) | {namespace: .metadata.namespace, name: .metadata.name}'

echo -e "\n=== Check 6: Unused roles/bindings ==="
kubectl get rolebindings -A
# Manually review if any are unused
```

---

## How to Use This Guide



---

## Debugging & Troubleshooting

Debugging in Kubernetes requires systematic approaches combining multiple information sources. Unlike traditional VMs where you can SSH and inspect, Kubernetes requires understanding pod lifecycle, events, logs, and resource states.

### Systematic Debugging Workflow

**The Golden Rule**: Gather data from **all sources** before forming hypotheses:

```
1. Gather Information
   ├─ kubectl describe pod (shows events + conditions)
   ├─ kubectl logs (application output)
   ├─ kubectl get events (system events)
   ├─ kubectl top (resource utilization)
   └─ Node logs (kubelet, kernel)
   
2. Analyze Symptoms
   ├─ Pod phase: Pending, Running, Failed?
   ├─ Container state: Running, Waiting, Terminated?
   ├─ Events: What happened recently?
   └─ Resource constraints: Limits hit?
   
3. Form Hypothesis
   ├─ Network connectivity issue?
   ├─ Resource constraints?
   ├─ Configuration error?
   └─ Security (RBAC/Network Policy)?
   
4. Verify Hypothesis
   ├─ Test connectivity (nc, curl)
   ├─ Check RBAC (`kubectl auth can-i`)
   ├─ Verify NetworkPolicy rules
   └─ Profile resource usage
   
5. Fix and Validate
   ├─ Apply fix
   ├─ Monitor for regression
   └─ Document findings
```

### Common Issues in Kubernetes Clusters

#### Textual Deep Dive

**Categories of Issues**:

1. **Scheduling Issues**: Pod can't be scheduled on a node
2. **Network Issues**: Pod can't reach other services
3. **Storage Issues**: PVC can't bind to PV
4. **Resource Issues**: Pod OOMKilled or CPU throttled
5. **Security Issues**: RBAC/NetworkPolicy blocks access
6. **Application Issues**: Pod runs but crashes
7. **Node Issues**: Node not ready, disk pressure, etc.

**Issue Decision Tree**:

```
[Pod not working]
    ↓
Is pod in Pending state?
├─ Yes: Scheduling issue (node selectors, resources, affinity)
└─ No: Proceed to next check
    ↓
Is pod in CrashLoopBackOff?
├─ Yes: Application issue (restart loop)
└─ No: Proceed to next check
    ↓
Is pod running but not responding?
├─ Yes: Service/network issue
└─ No: Unknown issue (gather more data)
```

**Root Cause Categories** (80/20 rule):

| Category | Frequency | Detection |
|----------|-----------|-----------|
| Resource constraints | 40% | `kubectl describe pod` shows OOMKilled or CPU limits |
| Network connectivity | 25% | `kubectl exec pod -- curl service` fails |
| Application crash | 20% | `kubectl logs pod` shows errors |
| Scheduling/node issues | 10% | Pod stuck in Pending |
| Security policies | 5% | kubectl auth can-i shows access denied |

### kubectl describe

#### Textual Deep Dive

`kubectl describe pod` is the **most informative command** for pod debugging. It shows:

```
Pod metadata (name, namespace, labels)
├─ Status: Current state
├─ IP addresses: Pod IP, node IP
├─ Node: Which node is it on
├─ Containers: List of containers
│  ├─ Image: What image is running
│  ├─ State: Running/Waiting/Terminated
│  ├─ Last State: Previous state (if crashed)
│  └─ Restart Count: How many times restarted
├─ Events: Everything that happened
│  ├─ Scheduled: Pod was assigned to node
│  ├─ Pulled: Image was pulled
│  ├─ Created: Container was created
│  ├─ Started: Container started
│  └─ Killed: Container was killed (if applicable)
└─ Conditions: Current state conditions
   ├─ PodScheduled: Is it on a node?
   ├─ Initialized: Init containers done?
   ├─ Ready: Is pod ready to serve traffic?
   └─ ContainersReady: All containers healthy?
```

**Reading the Events Section** (most important):

Events are chronologically ordered and show what the system did:

```
Events:
  Type    Reason      Message
  Normal  Scheduled   Successfully assigned pod to node-1
  Normal  Pulled      Container image "app:1.0" already present
  Normal  Created     Created container app
  Normal  Started     Started container app
  Warning Failed      Back-off restarting failed container
  Normal  Killing     Stopping container app
```

Interpretation:
- `Normal` events: Expected behavior
- `Warning` events: Something unexpected (but not fatal)
- `Error` events: Something went wrong

**ContainerState Details**:

Each container has a current state:
- **Running**: Container is executing
  - `StartedAt`: When it started
- **Waiting**: Container not yet running
  - `Reason`: Why not? (`CrashLoopBackOff`, `ImagePullBackOff`, `CreateContainerConfigError`)
  - `Message`: Detailed explanation
- **Terminated**: Container exited
  - `ExitCode`: 0=success, non-zero=error
  - `Reason`: Why it exited (`OOMKilled`, `Completed`, `Error`)
  - `Message`: Detailed message

**Common findings from describe**:

| Finding | Cause | Fix |
|---------|-------|-----|
| `Pending` + `Unschedulable: insufficient memory` | Pod requests more RAM than available | Reduce requests or add nodes |
| `CrashLoopBackOff` + "exit code 1" | Application crashing | Check `kubectl logs` for errors |
| `ImagePullBackOff` | Image doesn't exist or can't be pulled | Verify image name and registry credentials |
| `NotReady` + Kubelet errors in events | Kubelet can't reach API or image | Check node logs |
| Multiple restarts + different exit codes | App intermittently crashing | Check for resource limits (OOMKilled) |

#### Practical Examples

```bash
#!/bin/bash
# Complete debugging with describe

POD=${1:-}
NAMESPACE=${2:-default}

if [ -z "$POD" ]; then
  echo "Usage: $0 <pod-name> [namespace]"
  echo "Available pods in $NAMESPACE:"
  kubectl get pods -n $NAMESPACE
  exit 1
fi

echo "=== Pod Overview ==="
kubectl describe pod $POD -n $NAMESPACE

echo -e "\n=== Last Container State (why did it crash?) ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{range .status.containerStatuses[*]}{.lastState}{"\n"}{end}' | jq .

echo -e "\n=== Container Restart Count ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{range .status.containerStatuses[*]}{.name}{": "}{.restartCount}{"\n"}{end}'

echo -e "\n=== Current Conditions ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.status}{" ("}{.reason}{")"}{"\n"}{end}'

echo -e "\n=== All Events (oldest first) ==="
kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$POD --sort-by='.firstTimestamp'
```

---

### Events and Event Correlation

#### Textual Deep Dive

**Event Lifecycle**:

Each Kubernetes event represents a state transition:

```
[Something happens in the cluster]
    ↓
[kube-apiserver generates Event object]
    ↓
[Event stored in etcd (with TTL, default 1 hour)]
    ↓
[You query with kubectl get events]
    ↓
[Events age out and are deleted]
```

Events include:
- `Type`: Normal, Warning
- `Reason`: Coded reason (Scheduled, Failed, Killing, etc.)
- `Message`: Human-readable description
- `involvedObject`: What object does this event concern? (Pod, Node, PVC)
- `firstTimestamp`: When did it first happen?
- `lastTimestamp`: When did it last happen?
- `count`: How many times has this occurred?

**Event Correlation Patterns**:

Events tell a story. Reading them chronologically reveals what happened:

```
Normal Scheduled         Successfully assigned pod to node
Normal Pulled            Container image pulled
Normal Created           Container created
Normal Started           Container started
    [30 seconds pass, app running fine]
Warning Unhealthy        Liveness probe failed
Normal Killing           Stopping unhealthy container
Normal Pulled            Container image pulled (retry)
Normal Created           Container created
Normal Started           Container started
    [App is restarting repeatedly]
```

This story tells: Liveness probe is too strict, causing restart loop.

**Querying Events**:

```bash
# All events
kubectl get events --all-namespaces

# Events for specific pod
kubectl describe pod <pod-name>  # Shows pod-specific events

# Raw events (more detail)
kubectl get events -o json | jq '.items[] | select(.involvedObject.name=="pod-name")'

# Events with timestamps
kubectl get events --sort-by='.lastTimestamp'

# Recent events only
kubectl get events --field-selector type=Warning
```

#### Practical Example

```bash
#!/bin/bash
# Correlate events to find root cause

POD=${1:-}
NAMESPACE=${2:-default}

echo "=== Event Timeline for $POD ===="
kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$POD \
  --sort-by='.firstTimestamp' -o json | jq -r '
.items[] |
"\(.firstTimestamp) | \(.type | @json) | \(.reason | @json) | \(.message)"
'

echo -e "\n=== Event Count (summary) ==="
kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$POD \
  -o json | jq 'group_by(.reason) | map({reason: .[0].reason, count: length})'

echo -e "\n=== Error Events (if any) ==="
kubectl get events -n $NAMESPACE --field-selector type=Warning,involvedObject.name=$POD
```

---

### Crashloops

#### Textual Deep Dive

A CrashLoopBackOff occurs when a container repeatedly crashes and restarts:

```
[Container starts]
    ↓
[Application crashes with error]
    ↓
[Kubelet detects crash (exit code != 0)]
    ↓
[kubelet kills container]
    ↓
[Restart policy (default: Always) triggers]
    ↓
[Small backoff delay (100ms, 200ms, 400ms... up to 5min)]
    ↓
[Container restarts]
    ↓
[If crash happens again, go to step 2]
```

**Exit Code Analysis**:

| Exit Code | Meaning | Fix |
|-----------|---------|-----|
| 0 | Success (shouldn't restart) | Check RestartPolicy |
| 1 | General error | Check application logs |
| 2 | Misuse of shell builtin | Configuration error |
| 125 | Docker run error | Permission or resource issue |
| 126 | Command can't execute | Binary not in image |
| 127 | Command not found | Wrong entrypoint |
| 137 | SIGKILL (from outside) | OOMKilled or pod evicted |
| 139 | SIGSEGV (segmentation fault) | Memory corruption (rare) |
| 143 | SIGTERM (graceful shutdown) | Pod terminating |

**Diagnosis via logs**:

```bash
# Current logs (if still running)
kubectl logs pod-name

# Previous container's logs (if crashed)
kubectl logs pod-name --previous

# All restart logs
kubectl logs pod-name --all-containers=true

# Raw container runtime logs
docker logs $(docker ps -a | grep pod-name | head -1)
```

**Common Causes**:

1. **Application error**: Invalid configuration, missing file, startup failure
2. **Resource limits**: OOMKilled or CPU throttling
3. **Missing dependency**: Database not reachable, missing secret
4. **Incorrect entrypoint**: Wrong command or bad shell script

#### Practical Example

```bash
#!/bin/bash
# Diagnose crashloop

POD=${1:-}
NAMESPACE=${2:-default}

  echo "=== CrashLoop Diagnostics for $POD ==="

# Check if actually in crash loop
STATE=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}')
if [ "$STATE" != "CrashLoopBackOff" ]; then
  echo "⚠ Pod is not in CrashLoopBackOff, state is: $STATE"
fi

echo -e "\n=== Exit Code from Last Crash ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'

echo -e "\n=== Last Termination Reason ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

echo -e "\n=== Message from Last Crash ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].lastState.terminated.message}'

echo -e "\n=== Restart Count ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].restartCount}'

echo -e "\n=== Application Logs (most recent run) ==="
kubectl logs $POD -n $NAMESPACE --tail=50

echo -e "\n=== Logs from Previous Crash ==="
kubectl logs $POD -n $NAMESPACE --previous --tail=50 || echo "No previous logs"

echo -e "\n=== Environment Variables (from Pod spec) ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].env[*].name}' | tr ' ' '\n'

echo -e "\n=== Resource Limits ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].resources}'

echo -e "\n=== Mounted Volumes ==="
kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.volumes[*].name}' | tr ' ' '\n'
```

---

### Logs Analysis

#### Textual Deep Dive

Application logs are essential debugging sources but often incomplete. They show what the application saw, not what the system did.

**Where Logs Live**:

```
Application logs:
├─ Container stdout: kubectl logs
├─ Container stderr: kubectl logs (same output)
└─ Files in container: kubectl exec → view files

System logs:
├─ Kubelet logs: journalctl on node
├─ Container runtime logs: docker logs or containerd logs
├─ kube-apiserver logs: journalctl on control plane
└─ CNI plugin logs: /var/log on node
```

**Reading kubectl logs**:

```bash
# Current logs
kubectl logs pod-name

# Logs from 1 hour ago
kubectl logs pod-name --since=1h

# Real-time tail
kubectl logs pod-name -f

# Previous container (if crashed)
kubectl logs pod-name --previous

# All containers in pod
kubectl logs pod-name --all-containers=true

# Specific container
kubectl logs pod-name -c container-name

# Raw output in JSON
kubectl logs pod-name -o json | jq '.log' | tail -f
```

**Log Levels**:

```
ERROR: Something failed
WARN:  Potential issue
INFO:  Informational message
DEBUG: Detailed for troubleshooting
```

Most apps log too much (DEBUG) or too little (only ERROR). Find the sweet spot.

**Common Log Patterns**:

| Pattern | Indicates |
|---------|-----------|
| "Connection refused" | Service isn't listening or port wrong |
| "Permission denied" | RBAC or file permissions issue |
| "No such file" | Missing ConfigMap, Secret, or volume |
| "Timeout" | Network unreachable or service too slow |
| "Out of memory" | Memory limit hit or memory leak |

#### Practical Example

```bash
#!/bin/bash
# Log analysis with context

POD=${1:-}
NAMESPACE=${2:-default}

echo "=== Application Logs (with context) ==="

# Show logs with timestamps and include warnings
kubectl logs $POD -n $NAMESPACE --timestamps=true | \
  grep -E "(ERROR|WARN|Exception)" | \
  head -20

echo -e "\n=== Log Volume ==="
LOG_LINES=$(kubectl logs $POD -n $NAMESPACE | wc -l)
echo "Total lines: $LOG_LINES"

echo -e "\n=== Most Common Errors ==="
kubectl logs $POD -n $NAMESPACE | \
  grep -i error | \
  cut -d: -f2- | \
  sort | uniq -c | sort -rn | head -5

echo -e "\n=== Resource Usage at Time of Crash ==="
# This is harder, requires persistent logging
echo "(Requires integration with log aggregation system)"
```

---

### Hands-on Scenarios

#### Scenario 1: Pod CrashLoopBackOff

**Setup**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: broken-app
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c", "exit 1"]  # Immediately fails
```

**Diagnosis Steps**:
1. `kubectl describe pod broken-app` → Shows CrashLoopBackOff
2. `kubectl logs broken-app --previous` → Would show command output
3. Check events → Shows "Back-off restarting failed container"
4. Check exit code → code 1 = application error

**Fix**:
- Fix the command or entrypoint
- Healthcheck commands must succeed

---

#### Scenario 2: NetworkPolicy Blocking Traffic

**Setup**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

**Diagnosis Steps**:
1. Pod responds fine when queried internally
2. External traffic times out
3. Check NetworkPolicy rules → `kubectl get networkpolicies`
4. Check events → No errors (policies silently drop packets)
5. Test with `kubectl exec pod -- nc`

**Fix**:
- Add ingress rules allowing traffic
- Don't forget to allow DNS (port 53 UDP)

---

#### Scenario 3: RBAC Permission Denies (403 Forbidden)

**Setup**:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: limited-app
---
kind: Role
metadata:
  name: read-pods-only
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  # NO delete permission
---
kind: RoleBinding
metadata:
  name: limited-app-binding
roleRef:
  kind: Role
  name: read-pods-only
subjects:
- kind: ServiceAccount
  name: limited-app
```

**Diagnosis Steps**:
1. App calls `kubectl delete pod` → gets 403 Forbidden
2. Check token: `kubectl exec pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/token`
3. Verify bindings: `kubectl get rolebindings`
4. Test: `kubectl auth can-i delete pods --as=system:serviceaccount:default:limited-app`

**Fix**:
- Add "delete" verb to role
- Or use different ServiceAccount for deletion tasks

---

#### Scenario 4: Resource OOMKilled

**Setup**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: app
    image: myapp
    resources:
      limits:
        memory: "128Mi"  # Very low limit
```

Application trying to allocate 200Mi: OOMKilled

**Diagnosis Steps**:
1. Pod repeatedly restarting
2. `kubectl describe` → Shows `OOMKilled`
3. Check resource requests: `kubectl get pod -o json | jq '.spec.containers[].resources'`
4. Check actual usage: `kubectl top pod`
5. Review logs for memory-intensive operations

**Fix**:
- Increase memory limit
- Or optimize application to use less memory
- Or implement memory pooling/caching

---

## Interview Questions

### 1. Network Policies

**Q1: Explain the difference between a NetworkPolicy ingress rule and egress rule.**

A: Ingress rules control **incoming** traffic to a pod, egress rules control **outgoing** traffic from a pod. NetworkPolicies are stateless, so **both directions must have rules** for bidirectional communication. An ingress rule on Pod A doesn't automatically allow Pod B to send traffic—you need an egress rule on Pod B as well.

**Q2: Why do many users forget to allow DNS in their NetworkPolicies?**

A: DNS (port 53 UDP) is often overlooked because it's not an application port. However, if a pod can't reach the DNS server (kube-dns in kube-system namespace), service discovery fails. Any pod that needs to resolve hostnames requires egress rule to port 53 UDP.

**Q3: What happens if you apply a NetworkPolicy for a resource that doesn't exist?**

A: The NetworkPolicy is created successfully but has no effect (silently ignored). It won't error. If you later create a pod matching the selector, the policy immediately takes effect.

**Q4: Can NetworkPolicies block Kubernetes system traffic (kubelet probes, API calls)?**

A: Yes. If you're too strict with policies, kubelet liveness/readiness probes will fail, causing the pod to be declared unhealthy and restarted. Same with kubelet→API communication. System components expect pod network access and will fail if restricted.

---

### 2. RBAC

**Q1: Why is it dangerous to give cluster-admin to a ServiceAccount used by a deployment?**

A: If the pod is compromised, the attacker has full cluster access. They can read all secrets (including other apps' credentials), delete resources, access data, and pivot to other systems. It violates the principle of least privilege.

**Q2: Explain the difference between authentication and authorization. What happens if one fails?**

A: Authentication verifies identity ("who are you?"), authorization checks permissions ("what can you do?"). If authentication fails (e.g., invalid certificate), the API server returns 401 Unauthorized—RBAC evaluation never happens. If authentication succeeds but RBAC denies, the server returns 403 Forbidden.

**Q3: Can a RoleBinding in one namespace grant access to resources in another namespace?**

A: No. RoleBindings are namespace-scoped and can only grant access to resources in that namespace. To grant cross-namespace access, you need a ClusterRoleBinding with a ClusterRole. However, you can bind a ClusterRole via RoleBinding to achieve namespace-scoped access to any resource (even cluster-wide resources).

**Q4: What's the difference between `kubectl auth can-i` and actually making an API call?**

A: `kubectl auth can-i` is a dry-run check that evaluates RBAC rules. It might miss some edge cases (custom admission webhooks, resource-specific restrictions). The actual API call includes all checks (admission, webhooks, etc.). Use `can-i` for quick verification, but test the actual call to be certain.

---

### 3. Debugging & Troubleshooting

**Q1: Your deployment has a pod stuck in Pending state for 1 hour. Walk through your debugging steps.**

A:
1. `kubectl describe pod <name>` → Check for "Unschedulable" reason
2. Possible causes:
   - Insufficient resources: Check node capacity with `kubectl top nodes`
   - Node selector mismatch: Verify labels with `kubectl get nodes --show-labels`
   - Affinity/Taint mismatches: Check `taints` and `affinity` in pod spec
   - PVC not bound: `kubectl get pvc` should state "Bound"
3. Fix: Add nodes, adjust selectors/affinity, or bind PVC

**Q2: Pod is running but always fails health checks. How do you debug?**

A:
1. Check probe configuration: `kubectl get pod -o yaml | grep -A10 livenessProbe`
2. Check logs around health check failures: `kubectl logs pod --tail=100 | grep -i health`
3. Exec into pod and manually run the probe command: `kubectl exec pod -- /bin/bash /healthcheck.sh`
4. Check if probe credentials are correct (if using HTTP auth)
5. Increase `initialDelaySeconds` if app needs time to start
6. Increase `timeoutSeconds` if the check is slow

**Q3: You see repeated "ImagePullBackOff" errors. What's the issue?**

A: Image can't be pulled. Causes:
- Image doesn't exist (wrong tag, typo)
- Image registry credentials missing
- Registry is unreachable
- Image > kubelet max pull size

Debug:
```bash
kubectl describe pod
# Look at "Failed to pull image" message

# Check image ref
kubectl get pod -o jsonpath='{.spec.containers[0].image}'

# Check pull secrets
kubectl get secrets   # Are imagePullSecrets created?

# Check node kernel for pull logs
kubectl debug node/<nodename> -it --image=ubuntu
docker pull <image>  # Test manually
```

---

### 4. Resource Failures

**Q1: Explain the difference between requests and limits. When would you set different values?**

A: 
- **Requests**: Kubernetes scheduler guarantee. Used to bin-pack pods onto nodes fairly.
- **Limits**: Hard cap enforced by kernel. Prevents noisy neighbors.

Set different values (e.g., requests=500m, limits=1000m) when:
- App has bursty workload (normally uses 500m, occasionally spikes to 1000m)
- You want fair sharing under normal load (requests) but allow temporary bursts (limits)
- Requests too low → pod evicted or unschedulable
- Requests too high → wasted resources
- Limits too low → CPU throttling or OOMKilled
- Limits way too high → noisy neighbors can harm cluster

**Q2: You see "OOMKilled" in logs. How do you fix it?**

A:
1. Increase memory limit (quick fix)
2. Investigate why memory is so high (memory leak? wrong algorithm?)
3. Implement caching/pooling to reduce memory footprint
4. Profile with tools like jmap (Java), pprof (Go)
5. Increase memory in requests AND limits (requests for fair scheduling)

**Q3: Your pod has CPU `limits: 2000m` but it's being throttled at 500m actual usage. Why?**

A: Throttling happens when **requests** are hit (not limits). If request=500m and pod uses 500m, it throttles to protect other pods. Limits (2000m) are just the hard cap.

Check request value: `kubectl get pod -o json | jq '.spec.containers[0].resources.requests.cpu'`

If request=500m, increase it: `kubectl set resources deployment myapp --requests=cpu=1000m`

---

### 5. Scenario-based Questions

**Q1: Production incident: All pods in a namespace stop serving traffic overnight, but aren't restarting.**

Possible causes:
1. Network Policy accidentally added blocking all traffic
2. RBAC role modified, service can't reach API
3. Secret expired or rotated
4. Storage backend filled up
5. Cluster autoscaler couldn't add nodes

Debug:
- Check NetworkPolicies: `kubectl get networkpolicies -n <namespace>`
- Check node status: `kubectl get nodes`
- Check events: `kubectl get events --all-namespaces --sort-by='.lastTimestamp'`
- Check pod disk usage: `kubectl exec pod -- df -h`

**Q2: You're asked to implement zero-trust networking in an internal Kubernetes cluster with 50 namespaces.**

Strategy:
1. Audit current network traffic (need observability first)
2. Create default deny policies per namespace
3. Implement microsegmentation: web tier → api tier → database tier
4. Test in dev cluster first
5. Roll out: prod → staging → dev
6. Monitor for policy violations
7. Create exceptions for legacy services (document why)

**Q3: Developers complain they can't execute commands in production pods for debugging, but security requires they not have unrestricted access.**

Solution:
1. Create read-only RBAC role (no exec, no delete)
2. Implement just-in-time (JIT) access: Temporary elevation via approval workflow
3. Use debug containers instead: `kubectl debug pod`
4. Implement observability: Logs, metrics, tracing → shouldn't need pod exec
5. Pre-deploy debug utilities in sidecar (jq, curl, netcat) if needed

---

## Hands-on Scenarios

### Scenario 1: Zero-Trust Network Implementation for Multi-Tenant SaaS

**Problem Statement**:

A SaaS platform with 200+ customers needs to implement network isolation overnight. Currently, all pods in the production cluster can communicate with each other. Security audit revealed that a compromised pod from Tenant A could access Tenant B's databases. The team has one week to implement zero-trust networking without causing outages.

**Architecture Context**:

```
Pre-Implementation State:
┌─────────────────────────────────────────────────────┐
│ Production Cluster                                  │
├─────────────────────────────────────────────────────┤
│ Namespace: tenant-a                                 │
│  ├─ Frontend Pods → Can reach ANY pod/service      │
│  ├─ API Pods → Can reach tenant-b-db!             │
│  └─ Jobs → Can reach external internet freely      │
├─────────────────────────────────────────────────────┤
│ Namespace: tenant-b                                 │
│  ├─ Frontend Pods → Can reach ANY pod              │
│  ├─ API Pods → Can reach tenant-a-api! (BREACH)    │
│  └─ Database Pod → Accessible from anywhere       │
├─────────────────────────────────────────────────────┤
│ Shared Namespaces: kube-system, ingress-nginx       │
└─────────────────────────────────────────────────────┘
```

**Step-by-Step Implementation**:

**Phase 1: Observability & Baseline (Week 1, Environment: Staging)**
```bash
#!/bin/bash
# 1. Install Cilium for policy audit mode (non-enforcing)

helm install cilium cilium/cilium \
  --namespace cilium-system \
  --set policyAuditMode=true  # LOG violations, don't enforce

# 2. Collect baseline traffic for 2 days
kubectl logs -n cilium-system -l k8s-app=cilium --tail=1000 | \
  grep "policy-denied" | \
  awk '{print $source_pod " -> " $dest_pod}' | \
  sort | uniq -c > traffic_baseline.log

# 3. Identify legitimate flows
cat traffic_baseline.log | awk '$1 > 10 {print}' > legitimate_traffic.txt
# Flows happening >10 times/day are likely legitimate
```

**Phase 2: Policy Design (Week 2, Planning)**

```yaml
---
# Tier 1: Deny all by default in each tenant namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Tier 2: Allow intra-namespace communication
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-same-namespace
  namespace: tenant-a
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}  # Same namespace only
  egress:
  - to:
    - podSelector: {}  # Same namespace only

---
# Tier 3: Allow DNS (critical!)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: tenant-a
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

---
# Tier 4: Frontend allows inbound from Ingress Controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-ingress
  namespace: tenant-a
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080

---
# Tier 5: API talks to database within namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-database
  namespace: tenant-a
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
# Tier 6: API allows outbound responses to frontend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-egress
  namespace: tenant-a
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 1024-65535  # Ephemeral return traffic
```

**Phase 3: Testing in Staging (Week 3)**
```bash
#!/bin/bash
# Test all critical paths before production

test_connectivity() {
  local source=$1
  local dest=$2
  local port=$3
  
  echo "Testing: $source → $dest:$port"
  kubectl exec -n tenant-a $source -- \
    timeout 3 nc -zv $dest $port && \
    echo "✓ PASS" || echo "✗ FAIL"
}

# Frontend should reach API
test_connectivity "frontend-pod" "api-service" 8080

# API should reach database
test_connectivity "api-pod" "db-service" 5432

# Verify isolation: API should NOT reach other tenant's DB
test_connectivity "api-pod" "tenant-b-db-service" 5432 || echo "✓ Properly blocked"
```

**Phase 4: Gradual Rollout to Production**

```bash
#!/bin/bash
# Week 4: Prod rollout in stages

# Stage 1: Policy in audit mode (day 1)
kubectl apply -f policies/ --audit-mode

# Monitor for 24 hours for legitimate traffic being blocked
kubectl logs cilium-*** -n cilium-system | grep "policy-denied" > day1_violations.log

# Stage 2: Enable enforcement on non-critical namespace (day 2)
cilium policy import policies/ --namespace=staging

# Stage 3: Enable on 25% of prod (day 3)
# Using namespace selector labels
kubectl label namespace tenant-1 tenant-2 tenant-3 enforce-policies=true
# Apply policies only to labeled namespaces

# Stage 4: 50% → 100% (4-7 days)
# Monitor, fix violations, expand gradually

# Rollback plan (if needed): delete NetworkPolicies
kubectl delete networkpolicies --all -A
```

**Best Practices Applied**:

1. **Observability First**: Audit mode before enforcement (catch surprises)
2. **Gradual Rollout**: Staging → 25% → 50% → 100% (minimize blast radius)
3. **Explicit Allow**: Default deny, add explicitly allowed rules
4. **DNS Handling**: Explicit DNS rule added (common omission)
5. **Cross-tenant Isolation**: Policies at namespace level for multi-tenancy
6. **Testing Strategy**: Automated connectivity tests before/after
7. **Rollback Ready**: Quick rollback procedure if issues arise

**Monitoring & Validation**:

```bash
#!/bin/bash
# Post-implementation validation

echo "=== Verify isolation ==="
# Attempt cross-tenant communication
kubectl exec -n tenant-a api-pod -- \
  curl http://tenant-b-service/ && \
  echo "⚠ WARNING: Cross-tenant access still possible!" || \
  echo "✓ Isolation verified"

echo -e "\n=== Monitor policy violations ==="
kubectl logs -n cilium-system cilium-*** | \
  grep "policy-denied" | \
  wc -l

echo -e "\n=== Check for unintended blocks ==="
# Search for legitimate service calls being blocked
grep "tenant-a-api → tenant-a-db" day1_violations.log || \
  echo "✓ No false positives"
```

---

### Scenario 2: Debugging Production Service Degradation (Multi-layer Issue)

**Problem Statement**:

Payment processing service (`payment-api`) suddenly starts responding with 5xx errors. Requests fail 30% of the time. No deployments were changed in the last 24 hours. Outage is affecting revenue. You have 15 minutes to stabilize.

**Architecture Context**:

```
payment-api → (FAILS 30%) → payment-db
   ↓
Symptoms:
├─ kubectl describe: Shows "Running" but many restarts
├─ Logs: "Connection refused to database"
├─ Metrics: CPU at 80%, Memory at 95%
└─ Events: Mixed OOMKilled and voluntary evictions
```

**Step-by-Step Troubleshooting** (Systematic approach):

```bash
#!/bin/bash
# MINUTE 1: Gather basic health info

echo "=== Step 1: Pod Health ==="
kubectl describe pod -l app=payment-api -n production | head -30

echo -e "\n=== Step 2: Recent Restart Data ==="
kubectl get pod -l app=payment-api -n production \
  -o jsonpath='{range .items[*]}{.metadata.name}{": restarts="}{.status.containerStatuses[0].restartCount}{"\n"}{end}'

echo -e "\n=== Step 3: Recent Events ==="
kubectl get events -n production --sort-by='.lastTimestamp' | tail -20

echo -e "\n=== Step 4: Resource Utilization ==="
kubectl top pods -l app=payment-api -n production
kubectl top nodes  # Check if nodes are constrained

echo -e "\n=== Step 5: Check Error Rate ==="
kubectl logs -l app=payment-api -n production --tail=100 | grep -i error | head -10

echo -e "\n=== Step 6: Check Database Connectivity ==="
PAYMENT_POD=$(kubectl get pod -l app=payment-api -o jsonpath='{.items[0].metadata.name}')
kubectl exec $PAYMENT_POD -- \
  timeout 5 psql -h payment-db -U user -d payments -c "SELECT 1;" || \
  echo "⚠ Database connection failed"
```

**Analysis of Findings**:

```
Finding: ReplicaSet shows 10 desired, 4 ready, 6 pending
  → Indicates pods can't schedule or are being evicted

Finding: kubectl top shows pods at memory: 512Mi, limits: 512Mi
  → Pod is hitting memory limit exactly

Finding: Events show "Evicted due to MemoryPressure"
  → Node itself is running out of memory

Root Cause Hypothesis: Memory leak in payment-api causing
  1. Pod to hit 512Mi limit
  2. Pod OOMKilled
  3. Restart policy recreates pod
  4. New pod also leaks memory, gets evicted
  5. Complete service degradation
```

**Fix Strategy** (in order of priority):

```bash
#!/bin/bash
# MINUTE 2-5: Quick stabilization

echo "=== Phase 1: Immediate Mitigation ==="

# 1. Increase memory limit to buy time for diagnosis
kubectl set resources deployment payment-api \
  --limits=memory=1024Mi \
  --namespace=production

# This triggers rolling update, new pods should be more stable
kubectl rollout status deployment/payment-api -n production

# 2. Verify memory pressure is relieved
sleep 30
kubectl top pod -l app=payment-api

echo -e "\n=== Phase 2: Long-term Fix ==="

# 3. Identify memory leak (profile the application)
PAYMENT_POD=$(kubectl get pod -l app=payment-api -o jsonpath='{.items[0].metadata.name}')

# For Java applications:
kubectl exec $PAYMENT_POD -- jmap -dump:live,format=b,file=/tmp/heap.bin 1
kubectl cp payment-api/:/tmp/heap.bin ./heap.bin

# For Go applications:
kubectl exec $PAYMENT_POD -- curl http://localhost:6060/debug/pprof/heap > heap.pprof

# 4. Check logs for clues
kubectl logs $PAYMENT_POD --previous --tail=500 | \
  grep -i "memory\|allocation\|pool" | tail -20

# 5. Check if database connection pool is leaking
# Look for "Connection pool exhausted" or similar

echo -e "\n=== Phase 3: Validation ==="
# Monitor error rate
kubectl exec $PAYMENT_POD -- \
  curl http://localhost:9090/metrics | grep http_requests

# Check if payment processing is working
echo '{"amount": 100}' | kubectl exec -i $PAYMENT_POD -- \
  curl -X POST http://localhost:8080/payment -d @- \
  -H "Content-Type: application/json"
```

**Root Cause (found after investigation)**:

Developer added connection pooling 3 days ago. Every restart of the database pod caused connection pool to accumulate 100+ stale connections. Over time (24 hours = many restarts), connections accumulated until memory was exhausted.

**Permanent Fix**:

```yaml
---
# 1. Increase memory limit with proper requests
kind: Deployment
metadata:
  name: payment-api
spec:
  template:
    spec:
      containers:
      - name: payment-api
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1024Mi"    # Increased from 512Mi
            cpu: "1000m"

---
# 2. Add livenessProbe to detect and restart unhealthy pods
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 30
          failureThreshold: 3

---
# 3. Connection pool cleanup
# In application code:
# Add scheduled task: check for stale connections every 5 minutes
# Close connections idle > 5 minutes
# Log pool statistics for monitoring

---
# 4. Monitoring/Alerting
apiVersion: v1
kind: PrometheusRule
metadata:
  name: payment-api-alerts
spec:
  groups:
  - name: payment-api
    rules:
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{pod="payment-api"} / container_spec_memory_limit_bytes{pod="payment-api"} > 0.9
      for: 2m
      annotations:
        summary: "Payment API memory > 90%"
        
    - alert: HighErrorRate
      expr: rate(http_requests_total{job="payment-api", status=~"5.."}[5m]) > 0.05
      for: 1m
      annotations:
        summary: "Payment API error rate > 5%"
```

**Best Practices Applied**:

1. **Triage First**: Gather data before making changes (logging enables diagnosis)
2. **Layer-by-layer**: Check pod → node → application → infrastructure
3. **Quick Stabilization**: Increase limits to buy debugging time
4. **Root Cause Analysis**: Find the actual leak, not just symptoms
5. **Permanent Fix**: Code change + monitoring/alerting
6. **Validation**: Test fix works and doesn't cause side effects

**Lessons for Team**:

- Memory leaks happen in long-running processes (Java/Go)
- Connection pools need cleanup logic and monitoring
- Liveness probes catch unhealthy pods early
- Alerts should trigger before users notice (error rate, memory %)

---

### Scenario 3: RBAC Permission Escalation & Incident Response

**Problem Statement**:

During security audit, you discover a CI/CD ServiceAccount has cluster-admin role (given months ago for "convenience"). An attacker who gains control of the CI/CD pipeline could destroy the entire cluster. Audit logs show this ServiceAccount is used by 47 different pipelines. You must revoke cluster-admin without breaking anyone's builds.

**Architecture Context**:

```
Current State (Dangerous):
├─ CI/CD ServiceAccount: ci-deployer
├─ Binding: ClusterRoleBinding → cluster-admin
├─ Usage: 47 pipelines depend on this
├─ Risk: One pipeline compromise = full cluster access
└─ Least Privilege: VIOLATED

Target State (Secure):
├─ Create minimal per-app ServiceAccounts
├─ Each SA has only deployment-specific permissions
├─ Pipelines use specific SAs
└─ Least Privilege: ACHIEVED (but requires effort)
```

**Step-by-Step Remediation**:

**Phase 1: Audit Current Usage (Day 1)**
```bash
#!/bin/bash
# 1. Find all uses of ci-deployer
echo "=== CI/CD ServiceAccount Permissions ==="
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.subjects[]?.name == "ci-deployer")'

# 2. Find all pipelines using it
kubectl get deployments -A -o json | \
  jq '.items[] | select(.spec.template.spec.serviceAccountName == "ci-deployer") |
  {namespace: .metadata.namespace, name: .metadata.name}'

# 3. Find what each pipeline actually accesses
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  echo "=== Pipelines in $ns using ci-deployer ==="
  kubectl get pods -n $ns -l used-by=ci-deployer -o jsonpath='{.items[*].metadata.name}'
done

# 4. Analyze audit logs to see actual API calls
kubectl get events -A | grep ci-deployer | head -20
# or use cloud provider audit logs:
# AWS CloudTrail, GCP Cloud Audit Logs, Azure Activity Log
```

**Phase 2: Design Minimal Permissions (Day 2)**

```bash
#!/bin/bash
# Analyze what each pipeline actually needs

# Example: pipeline-1 deploys to environment "staging"
PIPELINE_1_NEEDS="
- Get deployments in staging namespace
- Update deployment image
- Check rollout status
- Read logs for debugging
"

# Example: pipeline-2 deploys to database namespace
PIPELINE_2_NEEDS="
- Update StatefulSet in database namespace
- Read secrets for credentials
"

# Example: pipeline-3 runs system tasks
PIPELINE_3_NEEDS="
- Read ConfigMaps across all namespaces
- Update DaemonSets
- Delete completed Jobs
"

echo "Creating minimal roles per pipeline..."
```

```yaml
---
# pipeline-1: Staging deployer
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-1-deployer
  namespace: ci-cd

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: staging-deployer
  namespace: staging
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "deployments/status"]
  verbs: ["get", "patch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pipeline-1-deployer
  namespace: staging
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: staging-deployer
subjects:
- kind: ServiceAccount
  name: pipeline-1-deployer
  namespace: ci-cd

---
# pipeline-2: Database deployer
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-2-deployer
  namespace: ci-cd

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: database-deployer
  namespace: database
rules:
- apiGroups: ["apps"]
  resources: ["statefulsets", "statefulsets/status"]
  verbs: ["get", "patch", "update"]
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["db-credentials"]  # RESTRICTED to one secret!
  verbs: ["get"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pipeline-2-deployer
  namespace: database
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: database-deployer
subjects:
- kind: ServiceAccount
  name: pipeline-2-deployer
  namespace: ci-cd

---
# pipeline-3: System tasks
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pipeline-3-deployer
  namespace: ci-cd

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system-tasks-performer
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
  # Cluster-wide read-only access
- apiGroups: ["apps"]
  resources: ["daemonsets"]
  verbs: ["get", "patch"]
  # DaemonSet updates only
- apiGroups: ["batch"]
  resources: ["jobs"]
  verbs: ["get", "delete"]
  # Delete completed jobs only

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pipeline-3-deployer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system-tasks-performer
subjects:
- kind: ServiceAccount
  name: pipeline-3-deployer
  namespace: ci-cd
```

**Phase 3: Update Pipelines (Day 3-4)**

```yaml
---
# In CI/CD tool (Jenkins, GitLab CI, GitHub Actions)

# OLD: Uses default ci-deployer with cluster-admin
deploy-job:
  serviceAccountName: ci-deployer  # Too broad!
  script:
    - kubectl deploy...

# NEW: Uses specific pipeline SA
deploy-job:
  serviceAccountName: pipeline-1-deployer  # Minimal permissions
  script:
    - kubectl deploy...
```

```bash
#!/bin/bash
# 1. Test that new permissions work
PIPELINE_SA="pipeline-1-deployer"

# Try authorized actions
kubectl auth can-i patch deployments \
  --as=system:serviceaccount:ci-cd:$PIPELINE_SA \
  --namespace=staging
# Should return: yes

# Try unauthorized actions
kubectl auth can-i delete deployments \
  --as=system:serviceaccount:ci-cd:$PIPELINE_SA \
  --namespace=staging
# Should return: no

# 2. Dry-run deployment with new SA
kubectl deploy... --service-account=$PIPELINE_SA --dry-run=client

# 3. Update CI/CD tool to use new SA
# Jenkins: Update pipeline code
# GitLab: Update .gitlab-ci.yml
# GitHub: Update workflow YAML

# NO CI/CD PIPELINE SHOULD REFERENCE ci-deployer anymore!
```

**Phase 4: Audit & Migrate (Week 2)**

```bash
#!/bin/bash
# Validate migration before removing cluster-admin

echo "=== Pipelines still using cluster-admin ==="
# Check if any deployments/pods still reference ci-deployer
kubectl get deployments -A -o jsonpath='{range .items[*]}{.metadata.namespace}{":"}{.metadata.name}{" -> "}{.spec.template.spec.serviceAccountName}{"\n"}{end}' | grep ci-deployer

echo -e "\n=== Verify all new SAs have proper bindings ==="
for sa in pipeline-1-deployer pipeline-2-deployer pipeline-3-deployer; do
  echo "ServiceAccount: $sa"
  kubectl get rolebindings,clusterrolebindings -A -o json | \
    jq ".items[] | select(.subjects[]?.name == \"$sa\")"
done

echo -e "\n=== Run dry-run smoke test ==="
# Actually invoke a pipeline in staging to verify
./run_pipeline_test.sh pipeline-1-deployer staging

echo -e "\n=== If all tests pass, remove cluster-admin binding ==="
# kubectl delete clusterrolebinding ci-deployer-cluster-admin
# kubectl delete clusterrolebinding ci-deployer  # Verify exact name

echo -e "\n=== Final audit ==="
# Verify ci-deployer no longer has cluster-admin
kubectl get clusterrolebindings | grep -i ci-deployer || \
  echo "✓ ci-deployer cluster-admin binding successfully removed"
```

**Incident Response (if something breaks)**:

```bash
#!/bin/bash
# If pipeline fails after permission change:

echo "=== Debugging pipeline failure ==="

# 1. Check what action failed
kubectl logs <pipeline-pod> | grep -i "permission\|forbidden\|unauthorized"

# 2. Check RBAC rules
PIPELINE_SA="pipeline-1-deployer"
kubectl get rolebindings,clusterrolebindings -A -o json | \
  jq ".items[] | select(.subjects[]?.name == \"$PIPELINE_SA\")"

# 3. Check what action is trying to do
# Extract from pipeline logs: "kubectl patch deployments/myapp"

# 4. Test specifically
kubectl auth can-i patch deployments \
  --as=system:serviceaccount:ci-cd:$PIPELINE_SA \
  --namespace=staging

# 5. If not allowed, add to role
kubectl edit role staging-deployer -n staging
# Add the missing verb/resource

# 6. Re-run pipeline
```

**Best Practices Applied**:

1. **Least Privilege Enforcement**: Minimal permissions per identity
2. **Principle of Segregation**: Different pipelines use different SAs
3. **Auditability**: Permission change logged and tracked
4. **Gradual Rollout**: Test before full migration (prevents mass breakage)
5. **Incident Response**: Have rollback plan ready
6. **Documentation**: Document why each permission is needed

**Monitoring & Validation**:

```yaml
---
# Add monitoring for unauthorized API calls
apiVersion: v1
kind: PrometheusRule
metadata:
  name: rbac-violations
spec:
  groups:
  - name: rbac
    rules:
    - alert: APIForbidden
      expr: increase(apiserver_audit_event_total{verb!~"list|get|watch", user=~"pipeline.*"}[5m]) > 5
      annotations:
        summary: "Pipeline {{ $labels.user }} making forbidden API calls"
        
    - alert: ClusterAdminUsage
      expr: increase(apiserver_client_certificate_expiration_seconds{subject="cn=cluster-admin"}[5m]) > 0
      annotations:
        summary: "cluster-admin credentials being used (should be minimal!)"
```

---

### Scenario 4: Complete Resource Failure Diagnosis (OOMKilled with Performance Issues)

**Problem Statement**:

Analytics job (`daily-report-generator`) processes daily reports. It used to complete in 4 hours but now takes 7 hours and crashes with OOMKilled mid-way through. Data team is blocked. No code changes in 3 weeks, but infrastructure autoscaling added 10 new nodes yesterday.

**Diagnosis Workflow**:

```bash
#!/bin/bash
# STEP 1: Pod Status Check
echo "=== Pod Status ==="
kubectl get pod daily-report-generator -o wide
# Output: Running → means it's currently running

echo -e "\n=== Container Status ==="
kubectl get pod daily-report-generator -o jsonpath='{.status.containerStatuses}'

echo -e "\n=== Events Timeline ==="
kubectl describe pod daily-report-generator
# Shows: OOMKilled, exit code 137 (SIGKILL due to memory)

# STEP 2: Resource Analysis
echo -e "\n=== Current Resources ==="
kubectl get pod daily-report-generator -o json | jq '.spec.containers[0].resources'
# Output: requests: {memory: 2Gi, cpu: 1000m}
#         limits:   {memory: 4Gi, cpu: 2000m}

echo -e "\n=== Actual Usage During Run ==="
# Requires metrics-server installed
kubectl top pod daily-report-generator
# Output: memory: 3.8Gi → Very close to 4Gi limit!

# STEP 3: Check Node Capacity
echo -e "\n=== Node Status ==="
kubectl get nodes
kubectl top nodes
# New nodes have same capacity as old nodes
# No hardware difference

# STEP 4: Analyze Job Performance
echo -e "\n=== Job Logs ==="
# Assuming logs contain performance metrics
kubectl logs daily-report-generator --tail=500 | \
  tail -100  # Last 100 lines before crash
# Output shows: Processing slower than before

# STEP 5: Profile Memory Usage
echo -e "\n=== Check Data Size ==="
# Job processes data from PVC
REPORT_POD=$(kubectl get pod -l job=daily-report | head -1)
kubectl exec $REPORT_POD -- du -sh /data/*
# Output: 2.5GB input data (same as before)

# But processing might create temp files:
kubectl exec $REPORT_POD -- du -sh /tmp/
# Output: 3GB temp files during processing!

# STEP 6: Spot Root Cause
echo -e "\n=== Analysis ==="

# Memory breakdown:
# - Base application: 500MB
# - Input data in memory: 1.5GB  
# - Temp processing files: 3GB (NEW!)
# - Buffers/caches: 500MB
# TOTAL: 6GB needed, but limit is 4GB >> OOMKilled

# Why is temp data 3GB when input is only 2.5GB?
# Likely: Creating intermediate processing files
# Not cleaning up between stages
```

**Root Cause Analysis**:

```
Timeline Analysis:
┌─────────────────────────────────────────────────┐
│ "10 new nodes added yesterday"                  │
├─────────────────────────────────────────────────┤
│ 1. Autoscaler added nodes                       │
│ 2. Kube-controller-manager rebalances workloads │
│ 3. Job now runs on NEW node (different layout)  │
│ 4. NEW nodes have DIFFERENT disk cache behavior │
│ 5. Kernel caching less aggressive               │
│ 6. Application uses MORE memory (from disk)     │
│ 7. OOMKilled when hitting 4Gi limit             │
└─────────────────────────────────────────────────┘

OR:

Noisy Neighbor Issue:
1. Old nodes had dedicated capacity for job
2. New nodes have other workloads (10+ pods each)
3. Kernel cache pressure causes swapping
4. Job accessing disk more often
5. Memory usage spikes to 4Gi and crashes

Hypothesis: Check if other pods are running on new node
```

**Testing Hypothesis**:

```bash
#!/bin/bash
# Run job again with debugging

echo "=== Check nodes where job ran ==="
kubectl describe pod daily-report-generator | grep "Node:"
# Node: node-10-new (one of the new nodes!)

echo -e "\n=== Check other workloads on node-10-new ==="
kubectl get pods --field-selector spec.nodeName=node-10-new
# Output: 15 other pods running, total 20GB memory used
# Node has 32GB capacity

echo -e "\n=== Memory pressure on node ==="
kubectl top node node-10-new
# Memory: 26.5GB / 32GB (82% utilization, HIGH!)

echo -e "\n=== Run job on old node (test) ==="
# Add node selector to force old node
kubectl run daily-report-test \
  --image=daily-report:latest \
  --node-selector=node-type=old \
  -- generate-report
# Job completes in 4 hours successfully!

echo "✓ Confirmed: Noisy neighbor + memory pressure caused OOMKilled"
```

**Fix & Mitigation**:

```yaml
---
# Option 1: Increase memory limit (quick fix, costly)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report-generator
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report-gen
            resources:
              requests:
                memory: "3Gi"      # Increased from 2Gi
                cpu: "2000m"       # Also increased
              limits:
                memory: "6Gi"      # Was 4Gi → now 6Gi
                cpu: "3000m"
          restartPolicy: OnFailure

---
# Option 2: Pod affinity to avoid noisy neighbors (better)
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report-generator
spec:
  schedule: "0 0 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          affinity:
            # Avoid running on nodes with high memory usage
            nodeAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
                nodeSelectorTerms:
                - matchExpressions:
                  - key: memory-pressure
                    operator: NotIn
                    values: ["true"]
            # OR: Prefer dedicated nodes
            nodeAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
              - weight: 100
                preference:
                  matchExpressions:
                  - key: workload-type
                    operator: In
                    values: ["batch-jobs"]
          containers:
          - name: report-gen
            resources:
              requests:
                memory: "3Gi"
                cpu: "1500m"
              limits:
                memory: "4Gi"  # Keep reasonable limit
                cpu: "2000m"

---
# Option 3: Optimize application (best, but requires code change)
# Delete temp files after each processing stage:
#   - After parsing: delete raw_data.tmp
#   - After transformation: delete intermediate.tmp
#   - Use streaming/chunking instead of loading entire dataset
#
# This would reduce memory footprint from 6GB to 2GB

---
# Option 4: Separate nodes for batch jobs (production-grade)
apiVersion: apps/v1
kind: Node
metadata:
  labels:
    workload-type: batch-jobs  # Label for node targeting
spec:
  # Mark these nodes exclusively for batch
  taints:
  - key: batch
    value: "true"
    effect: NoSchedule

---
# Pod tolerates this taint
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report-generator
spec:
  template:
    spec:
      tolerations:
      - key: batch
        operator: Equal
        value: "true"
        effect: NoSchedule
      nodeSelector:
        workload-type: batch-jobs
```

**Validation & Monitoring**:

```bash
#!/bin/bash
# After applying fix,validate

echo "=== Rerun job with fix ==="
kubectl apply -f daily-report-cronj ob.yaml
kubectl create job daily-report-manual --from=cronjob/daily-report-generator

# Monitor execution
watch "kubectl top pod daily-report-manual" &
PID=$!

# Wait for completion
kubectl wait --for=condition=complete job/daily-report-test --timeout=8h

kill $PID

echo "=== Job completion check ==="
kubectl get job daily-report-manual -o jsonpath='{.status}'
# Should show: completionTime, successfull

echo -e "\n=== Verify memory usage peaked lower ==="
kubectl logs daily-report-manual | grep "max memory" || \
  echo "Add logging to job: 'Peak memory used: X MB'"

echo -e "\n=== Setup alerts to prevent recurrence ==="
# Monitor:
# - Job duration (alert if > 5 hours)
# - Node memory pressure (alert if > 80%)
# - Pod memory % of limit (alert if OOMKilled)
```

**Best Practices Applied**:

1. **Systematic Diagnosis**: Check pod → node → system → application
2. **Hypothesis Testing**: Verify assumptions with tests
3. **Root Cause**: Don't just increase limit, understand why it's needed
4. **Multiple Fix Options**: Quick (increase limit) vs. proper (optimize/separate nodes)
5. **Monitoring**: Alert before OOMKilled (at 80% memory usage)
6. **Maintenance**: Document findings for future reference

---

## Comprehensive Interview Questions (15+ Senior-Level Questions)

### Section 1: Network Policies (Deep Dives)

**Q1: You implement a NetworkPolicy that appears valid, but pods still can't communicate. What are the top 5 reasons this might happen?**

A: (Expected answer should cover all 5)

1. **CNI doesn't support policies**: Check if CNI is installed (kubenet doesn't). Verify with `kubectl get daemonset -n kube-system`. If no calico-node/cilium, policies are ignored silently.

2. **Wrong namespace for policy**: NetworkPolicies are namespace-scoped. A policy in namespace-a doesn't affect namespace-b. Check: `kubectl get networkpolicies -A` to see what's actually deployed.

3. **Selector doesn't match pods**: `podSelector: {}` matches all pods, but `podSelector: {matchLabels: {app: myapp}}` matches only pods with that label. Check: `kubectl get pods --show-labels` to verify labels match selectors.

4. **Missing direction control**: If you only specify ingress rules, egress is unrestricted. For bidirectional communication, **both pods need complementary rules** (one has ingress, other has egress). Easy to miss return traffic.

5. **Implicit vs explicit allow/deny confusion**: If no rules match, traffic is implicitly **denied** (fail-secure). But empty `ingress: []` means "deny all ingress", whereas missing ingress entirely means unrestricted. Check policy spec carefully.

**Real-world example**: I've seen clusters where policies were created but CNI wasn't restarted, so policies were never loaded. Add debug step: `kubectl exec -n kube-system <cni-pod> -- verify-policies` to confirm enforement is active.

---

**Q2: Explain the architectural difference between Calico (iptables) and Cilium (eBPF) when enforcing NetworkPolicies. When would you choose one over the other?**

A: 

**Calico (iptables-based)**:
```
Network packet arrives
  ↓
Linux kernel evaluates iptables rules (user→kernel context switch)
  ↓
Packet goes through all matching rules sequentially
  ↓
Decision: ACCEPT/DROP entered in iptables table
  ↓
Status: Good observability (see all rules with `iptables -L`)
  
Pros: Flexible, can express complex rules, maximum observability
Cons: Context switches = latency, iptables scale poorly (100k+ rules)
```

**Cilium (eBPF-based)**:
```
Network packet arrives
  ↓
eBPF program at XDP hook (no context switch, runs in kernel)
  ↓
Decision made in kernel bytecode (microseconds)
  ↓
Status: Very fast, low latency
  
Pros: Sub-microsecond latency, scales to millions of connections
Cons: Only works on Linux 4.8+, harder to debug (need BPF tracing tools)
```

**Performance comparison** (real numbers):
- Calico: 10-50µs per packet (iptables traversal)
- Cilium: <1µs per packet (direct kernel execution)

**When to choose**:

1. **Calico** if:
   - You need maximum compatibility (older kernels)
   - You have simple policies (<100 rules)
   - You prefer iptables debugging (easy visibility)
   - Your workload isn't latency-sensitive

2. **Cilium** if:
   - Running on modern kernel (5.8+)
   - High-throughput, latency-sensitive workloads (trading/payments)
   - Millions of policies (large clusters)
   - Want advanced features (service mesh integration, encryption)

**Hybrid approach** (I've used this):
- Run Calico in dev/staging (easier debugging)
- Run Cilium in production (better performance)
- Policies are CNI-agnostic, so can test in one environment

---

**Q3: Design a NetworkPolicy strategy for a multi-tenant SaaS where you must prevent any Pod from Tenant A from accessing Tenant B's data.**

A: This is a real architectural question, not just policy syntax.

**Architecture**:

```
┌─ Production Cluster
│
├─ Namespace: tenant-a
│  ├─ Pod: frontend (label: tenant=a)
│  ├─ Pod: api (label: tenant=a)
│  └─ Pod: db (label: tenant=a)
│
├─ Namespace: tenant-b
│  ├─ Pod: frontend (label: tenant=b)
│  ├─ Pod: api (label: tenant=b)
│  └─ Pod: db (label: tenant=b)
│
└─ Namespace: kube-system (shared DNS, etc.)
```

**Layered approach**:

1. **Layer 1: Namespace isolation** (strongest)
   ```yaml
   # Default deny ALL traffic between namespaces
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-cross-namespace
     namespace: tenant-a
   spec:
     podSelector: {}
     policyTypes: [Ingress, Egress]
     # Block ingress from outside namespace
     ingress:
     - from:
       - podSelector: {}  # Only same namespace
     # Block egress to outside namespace
     egress:
     - to:
       - podSelector: {}  # Only same namespace
     - to:  # Allow DNS to kube-system
       - namespaceSelector: {matchLabels: {name: kube-system}}
       ports: [{protocol: UDP, port: 53}]
   ```

2. **Layer 2: Role separation within tenant**
   ```yaml
   # Frontend can't directly access database
   # Must go through API for authorization
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: api-to-db-only
     namespace: tenant-a
   spec:
     podSelector: {matchLabels: {tier: database}}
     policyTypes: [Ingress]
     ingress:
     - from:
       - podSelector: {matchLabels: {tier: api}}
       ports: [{protocol: TCP, port: 5432}]
       # Explicitly deny frontend directly accessing DB
   ```

3. **Layer 3: RBAC also enforces** (defense in depth)
   - Tenant A's ServiceAccount can't read Tenant B's Secrets (RBAC rules)
   - Even if network bypassed, secrets are protected

**Validation script**:

```bash
#!/bin/bash
# Test that isolation works

test_isolation() {
  local source_ns=$1
  local source_pod=$2
  local target_ns=$3
  local target_svc=$4
  
  echo "Testing: $source_ns/$source_pod → $target_ns/$target_svc"
  
  kubectl exec -n $source_ns $source_pod -- \
    timeout 3 curl http://$target_svc.$target_ns || \
    echo "✓ Properly blocked (expected)"
}

# Should ALL fail:
test_isolation tenant-a frontend-pod tenant-b api-svc
test_isolation tenant-a api-pod tenant-b db-svc
test_isolation tenant-b frontend-pod tenant-a db-svc

# Should all succeed (same tenant):
kubectl exec -n tenant-a api-pod -- curl http://db-svc.tenant-a
```

**Monitoring for breaches**:

```yaml
apiVersion: v1
kind: PrometheusRule
metadata:
  name: cross-tenant-access-alert
spec:
  groups:
  - name: multi-tenant-security
    rules:
    - alert: CrossTenantNetworkPolicy Violation
      expr: increase(cilium_drop_bytes_total{rule="multi-tenant-isolation"}[5m]) > 0
      annotations:
        summary: "Potential cross-tenant access attempt detected"
        
    - alert: CrossTenantRBACAttempt
      expr: increase(apiserver_audit_event_total{verb="get", objectRef_name=~"tenant-b-.*", user=~"tenant-a-.*"}[5m]) > 0
      annotations:
        summary: "Tenant A accessing Tenant B resources"
```

---

### Section 2: RBAC & Authentication (Production Scenarios)

**Q4: Walk through implementing OIDC-based authentication for your 500-person engineering organization while maintaining RBAC control.**

A: This is about integrating external auth with RBAC.

**Architecture**:

```
┌─ Organization SSO (Okta, Auth0, Azure AD)
│  ├─ User: alice@company.com
│  ├─ Groups: developers, payments-team, security-team
│  └─ OIDC endpoint: https://okta.company.com/oauth
│
├─ Kubernetes kube-apiserver
│  └─ --oidc-issuer-url=https://okta.company.com
│  └─ --oidc-client-id=kubernetes
│  └─ --oidc-username-claim=email
│  └─ --oidc-groups-claim=groups  ← KEY: Groups come from OIDC
│
└─ Kubernetes RBAC
   ├─ ClusterRole: developer (get pods, logs, exec)
   ├─ RoleBinding: developers group → developer role
   ├─ ClusterRole: payments-admin
   └─ RoleBinding: payments-team → payments-admin role
```

**Implementation steps**:

1. **Configure kube-apiserver for OIDC**:
```bash
# On kube-apiserver startup:
kube-apiserver \
  --oidc-issuer-url=https://okta.company.com \
  --oidc-client-id=kubernetes \
  --oidc-username-claim=email \
  --oidc-groups-claim=groups \
  --oidc-ca-file=/etc/ssl/okta-ca.pem
```

2. **Configure kubectl to use OIDC**:
```bash
kubectl config set-cluster my-cluster \
  --server=https://api-server:6443

kubectl config set-context my-cluster \
  --cluster=my-cluster \
  --user=oidc-user

# User authenticates once with OIDC, gets token
# Token is stored in ~/.kube/config
# Token auto-refreshes (if using proper OIDC client)
```

3. **Create RBAC roles for organization structure**:
```yaml
---
# Developers can only access their namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-base
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["get", "list", "watch", "create"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers-binding
  namespace: development
roleRef:
  kind: ClusterRole
  name: developer-base
subjects:
- kind: Group
  name: developers  ← Matches OIDC group claim

---
# Payments team gets elevated access for their namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: payments-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payments-admin
  namespace: payments
roleRef:
  kind: ClusterRole
  name: payments-admin
subjects:
- kind: Group
  name: payments-team  ← Matches OIDC group claim
```

4. **Benefits of this approach**:
- **Single Sign-On**: User logs in once to company SSO, automatically works in Kubernetes
- **Automated provisioning**: Add user to "developers" group in Okta → automatically gets developer access in K8s
- **Centralized control**: Remove from group in Okta → K8s access revoked instantly
- **Audit trail**: Okta logs all authentication attempts
- **No secret management**: No kubeconfig files to distribute

5. **Operational considerations**:

```bash
#!/bin/bash
# Check who has what access

echo "=== Users in 'developers' group ==="
# Query Okta API
curl https://okta.company.com/api/v1/groups/developers/users

echo -e "\n=== What can a user do? ==="
# Use RBAC can-i
kubectl auth can-i create pods \
  --as=alice@company.com

echo -e "\n=== Monitor auth failures (security) ==="
# Alert if someone fails auth >5 times
kubectl get events | grep "Unauthorized"
```

---

**Q5: You discover a senior engineer left the company, but still has cluster-admin access (from old cluster certificate). How do you revoke it? What are the risks?**

A: This is about immediate security response + long-term prevention.

**Immediate actions (now, prevent damage)**:

```bash
#!/bin/bash
# STEP 1: Identify all ways they have access
echo "=== Certificate-based access ==="
# Find their client certificate (CN=john)
kubectl get csr | grep john || echo "No CSRs pending"

# Check kubeconfig references
# (can't directly query, but log files will show)

echo -e "\n=== ServiceAccount access ==="
kubectl get secrets -A | grep john

echo -e "\n=== RBAC bindings ==="
kubectl get rolebindings,clusterrolebindings -A -o json | \
  jq '.items[] | select(.subjects[]?.name == "john" or .subjects[]?.name == "john")'

echo -e "\n=== Audit logs for recent activity ==="
# Check if they accessed recently
tail -1000 /var/log/kubernetes/audit.log | grep john
```

**Revocation methods**:

```bash
#!/bin/bash
# METHOD 1: Revoke certificate (if using cert-based auth)
# On CA: Revoke the certificate
# Requires restarting kube-apiserver with updated CRL

# METHOD 2: Remove RBAC bindings
kubectl delete rolebindings -A -l user=john
kubectl delete clusterrolebindings -A -l user=john

# METHOD 3: Disable ServiceAccounts they created
kubectl get serviceaccounts -A | grep john
kubectl delete serviceaccount john -A

# METHOD 4: Rotate API server secrets and certs
# (nuclear option, causes downtime)

# METHOD 5: Add them to blocklist (if auth webhook used)
# Update webhook to reject their identity
```

**Risks of revocation**:

1. **Access via other ServiceAccounts**: If they had cluster-admin, they might have created backdoor SAs. Check all SAs they created.

2. **Secrets leaked**: They might have copied SAs or tokens. Rotate all secrets.

3. **Audit evidence destroyed**: They might have deleted audit logs. Ensure audit logs are in external system (not in cluster).

4. **Application still running**: If they deployed rogue applications (backdoor containers), those are still running. Kill suspicious deployments.

5. **Network access**: Revok ing K8s access doesn't prevent them from accessing cluster network directly (if on VPN). Revoke VPN access too.

**Prevention for future**:

```bash
#!/bin/bash
# Long-term prevention

# 1. Regular RBAC audits
echo "=== Monthly: Who has what access? ==="
kubectl get clusterrolebindings -o json | \
  jq '.items[] | select(.roleRef.name == "cluster-admin")'
# Alert if more than 5 people have cluster-admin

# 2. Service account rotation
kctl auth rotate-token

# 3. Certificate expiration
# Certificates shouldn't be valid for >1 year
# Implement automatic renewal (cert-manager)

# 4. Audit log centralization
# Ensure logs aren't locally stored (can be deleted)
# Ship to GCS, S3, external syslog

# 5. Monitoring for suspicious activity
# Alert on:
# - Successful auth for disabled users
# - Bulk deletion of resources
# - Access to secrets at odd times
```

---

### Section 3: Debugging & Troubleshooting (Advanced)

**Q6: Your service has 10% error rate but all metrics look normal. Where would you look first and why?**

A: This is about debugging "unknown unknowns."

**Triage order** (what I check in production incidents):

```
1. Pod Status (fastest) - 30 seconds
2. Events (causation) - 1 minute
3. Logs (application context) - 2 minutes
4. Metrics (trends) - 1 minute
5. Network (connectivity) - 3 minutes
6. Security (policies) - 2 minutes
7. Resources (constraints) - 2 minutes
```

**Step 1: Pod status**:
```bash
# If pods crashed/restarted, problem is container-level
kubectl describe pod -l app=myservice
# Check:
# - RestartCount (high = unstable)
# - State (Waiting? Terminated?)
# - Events (killed? succeeded? pending?)

# % error rate 10% suggests:
# - 10% of pods unavailable? OR
# - All pods degraded? OR
# - Just slow (timeout errors)?
```

**Step 2: Events** (most informative):
```bash
kubectl get events -n production --sort-by='.lastTimestamp' | \
  grep -i "warning\|error" | tail -20
  
# Look for patterns:
# - Repeated "Killing container" → pod restart loop
# - "Failed to mount volume" → storage issue
# - "Network timeout" → network policy?
# - "OOMKilled" → memory issue
```

**Step 3: Logs** (application perspective):
```bash
# 10% error rate suggests some requests fail, some succeed.
# Check if pattern:

# Errors in specific tenant?
kubectl logs -l app=myservice | grep -i error | \
  awk -F'[= ]' '{print $2}' | sort | uniq -c | sort -rn
# Look for patterns (same customer, same operation type)

# Errors timing?
kubectl logs -l app=myservice | grep -i error | \
  cut -d' ' -f1 | sort | uniq -c
# Errors happening at specific times?

# Specific error message?
kubectl logs -l app=myservice | grep -i error | \
  cut -d: -f3- | sort | uniq -c | sort -rn
# Most common errors first
```

**Step 4: Network connectivity**:
```bash
# If logs show "connection refused" or "timeout":
APP_POD=$(kubectl get pod -l app=myservice -o jsonpath='{.items[0].metadata.name}')

# Can app reach database?
kubectl exec $APP_POD -- \
  timeout 5 psql -h db-service -U user -d database -c "SELECT 1;"

# How many connections?
kubectl exec $APP_POD -- \
  netstat -an | grep ESTABLISHED | wc -l
# If too many or too few, connection pooling issue

# Network latency?
kubectl exec $APP_POD -- \
  ping db-service -c 5 | tail -2
# High latency explains why requests timeout
```

**Step 5: NetworkPolicy/RBAC**:
```bash
# If some requests work, some don't:
# - Might be hitting multiple backends with different policy rules
# - Check if app makes API calls (might be blocked)

kubectl get networkpolicies -n production
# Look for recently added policies

kubectl auth can-i get secrets --as=system:serviceaccount:prod:myapp
# If denied, app can't read credentials → failures
```

**Step 6: Resource constraints**:
```bash
# Check if requests/limits too aggressive
kubectl top pods -l app=myservice
kubectl get pods -l app=myservice -o json | jq '.items[].spec.containers[].resources'

# If memory usage near limit:
# Requests too low (pod evicted) or Limit too low (OOMKilled)

# If CPU throttled:
# Calculate: requests=1000m but average=800m? No throttle.
# But if requests=500m and average=600m? THROTTLED.
```

**In 10 minutes, I'd have:**
1. Pod status (running or crashing?)
2. Recent events (what changed?)
3. Error patterns in logs (same request type? same backend?)
4. Network connectivity check (can reach dependencies?)
5. Resource availability (limits hit?)

**Most likely culprits for "10% error rate with normal metrics"**:
- Backend service responding slowly (10% timeout)
- Intermittent network issue (10% packet loss)
- Storage getting full (10% of writes fail)
- Connection pool exhausted (10% of connections rejected)
- One pod out of every 10 crashing immediately

---

### Section 4: Resource Failures & Advanced Scenarios

**Q7: Design a resource management strategy for a mixed-workload cluster with web services, batch jobs, and data pipelines. How would you prevent noisy neighbors?**

A: This is an architecture question requiring nuance.

**Challenge**:
```
Cluster Heterogeneity:
├─ Web services (payment-api)
│  ├─ Low latency required
│  ├─ Bursty traffic
│  └─ Must never be throttled
├─ Batch jobs (daily-report)
│  ├─ Can tolerate jitter
│  ├─ Predictable daily schedule
│  └─ Can be preempted
├─ Data pipelines (spark-jobs)
│  ├─ CPU-intensive
│  ├─ Run every 6 hours
│  └─ Don't care about latency
└─ System components (monitoring, logging)
   ├─ Must always run
   ├─ Low overhead
   └─ Don't compete for resources
```

**Multi-layered solution**:

**Layer 1: Namespace-level resource quotas**:
```yaml
---
# Web services get guaranteed minimum
apiVersion: v1
kind: Namespace
metadata:
  name: production-saas
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: web-services-quota
  namespace: production-saas
spec:
  hard:
    requests.cpu: "100"
    requests.memory: "200Gi"
    limits.cpu: "150"
    limits.memory: "300Gi"
    pods: "100"

---
# Batch jobs get less strict quota
apiVersion: v1
kind: Namespace
metadata:
  name: batch-jobs
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: batch-quota
  namespace: batch-jobs
spec:
  hard:
    requests.cpu: "50"
    requests.memory: "100Gi"
    pods: "50"

---
# Data pipelines get flexible quota
apiVersion: v1
kind: Namespace
metadata:
  name: data-pipelines
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: pipeline-quota
  namespace: data-pipelines
spec:
  hard:
    requests.cpu: "200"  # Can burst higher
    requests.memory: "500Gi"
    pods: "200"
```

**Layer 2: Pod-level resource spec**:
```yaml
---
# Web service: requests = actual usage (tight)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  namespace: production-saas
spec:
  template:
    spec:
      containers:
      - name: api
        resources:
          requests:
            cpu: "1000m"      # Tight, no bursting
            memory: "512Mi"   # Tight
          limits:
            cpu: "1200m"      # Slight buffer for GC
            memory: "720Mi"

---
# Batch job: requests = conservative, limits = generous
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report
  namespace: batch-jobs
spec:
  schedule: "0 2 * * *"  # 2am, off-peak
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: report-gen
            resources:
              requests:
                cpu: "2000m"        # Reserve
                memory: "4Gi"       # Reserve
              limits:
                cpu: "8000m"        # Can burst
                memory: "16Gi"      # Can use all available

---
# Data pipeline: resources = burstable, QoS = Burstable
apiVersion: spark.apache.org/v1beta2
kind: SparkApplication
metadata:
  name: etl-pipeline
  namespace: data-pipelines
spec:
  executor:
    instances: 10
    resources:
      requests:
        cpu: "4"
        memory: "8Gi"
      limits:
        cpu: "8"
        memory: "16Gi"  # 2x requests = room for bursting
```

**Layer 3: Node-level isolation**:
```yaml
---
# Dedicate nodes for web services
apiVersion: v1
kind: Node
metadata:
  labels:
    workload-type: web-services
  spec:
    taints:
    - key: workload-type
      value: web-services
      effect: NoSchedule  # Only pods tolerating this can run

---
# Pods must tolerate and prefer dedicated nodes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
spec:
  template:
    spec:
      # Must tolerate web-services taint
      tolerations:
      - key: workload-type
        operator: Equal
        value: web-services
        effect: NoSchedule
      # Prefer web-services nodes
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: workload-type
                operator: In
                values: [web-services]
      containers:
      - name: api
```

**Layer 4: Priority and preemption**:
```yaml
---
# Web services: High priority (won't be preempted)
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: web-services-critical
value: 1000  # Higher = higher priority
globalDefault: false
description: "Web services - never preempt"

---
# Batch jobs: Low priority (can be preempted)
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: batch-jobs-low
value: 100
globalDefault: false
description: "Batch jobs - can be preempted by critical"

---
# Apply to deployments
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
spec:
  template:
    spec:
      priorityClassName: web-services-critical  # High
      containers:
      - name: api

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: daily-report
spec:
  jobTemplate:
    spec:
      template:
        spec:
          priorityClassName: batch-jobs-low  # Low
          containers:
          - name: report-gen
```

**Layer 5: Pod Disruption Budgets** (enable safe eviction):
```yaml
---
# Web services: Don't disrupt (HA requirement)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: payment-api-pdb
  namespace: production-saas
spec:
  minAvailable: 3  # Always keep 3 replicas
  selector:
    matchLabels:
      app: payment-api

---
# Batch jobs: Can be disrupted anytime
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: daily-report-pdb
  namespace: batch-jobs
spec:
  maxUnavailable: "100%"  # Can disrupt all (job will retry)
  selector:
    matchLabels:
      job: daily-report
```

**Validation & monitoring**:

```bash
#!/bin/bash
# Ensure isolation working

echo "=== Verify workload distribution ==="
kubectl get pods --all-namespaces -o wide | \
  awk '{print $NF}' | sort | uniq -c | sort -rn
# Should see web-services nodes dedicated to web

echo -e "\n=== Check for noisy neighbors ==="
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  echo "Node: $node"
  kubectl top node $node
  kubectl describe node $node | grep -i "memory\|cpu" | tail -3
done

echo -e "\n=== Run load test to verify isolation ==="
# Spike web services
kubectl exec -n production-saas payment-api-pod -- \
  siege -c 100 -t 1m http://localhost:8080

# Monitor batch job concurrently
kubectl top pods -n batch-jobs --watch

# Result: Payment API latency should NOT spike
# (or spike minimally) because batch jobs on separate nodes
```

---

**Q8: A senior engineer asks you: "Why can't I just give everything cluster-admin and rely on namespaces for isolation?" How do you explain why this is wrong?**

A: This reveals a critical misconception that I need to debunk clearly.

**The misconception**:
"If everyone has cluster-admin but works in their own namespace, they're isolated."

**Why it's wrong** (5 reasons):

1. **cluster-admin bypasses namespaces entirely**:
   ```bash
   # Even in "isolated" dev namespace, cluster-admin user can:
   kubectl --namespace=dev get secrets -A  # See secrets in ALL namespaces
   kubectl exec pod-in-prod --namespace=production -- /bin/sh  # Exec into prod!
   kubectl delete pod --all-namespaces  # Delete everything
   ```
   Namespaces become meaningless.

2. **One compromised account = full cluster loss**:
   ```
   Scenario: Attacker compromises a CI/CD pipeline
   
   Without cluster-admin (proper RBAC):
     → Can only patch deployments/myapp in namespace/staging
     → Can't access secrets, databases, other apps
     → Damage contained
   
   With cluster-admin:
     → Can read ALL secrets (database creds, API keys)
     → Can access all databases
     → Can steal source code
     → Can install backdoors in all applications
     → Can modify kube-apiserver
     → Full cluster compromise
   ```

3. **Audit and compliance fail**:
   ```bash
   # With RBAC: You can answer "What can John do?"
   kubectl get rolebindings -A | grep john
   # Output: Clear list of permissions
   
   # With cluster-admin: Everyone can do everything
   # Audit logs don't help (no way to prevent anything)
   # Compliance tests fail ("No least privilege!")
   ```

4. **Developers argue and create manual workarounds**:
   ```
   If RBAC is too strict → Developers bypass it
   
   Example:
   - Sarah wants cluster-admin for "debugging"
   - Security says no
   - Sarah gives her kubeconfig to ops team
   - Ops runs kubectl as Sarah's identity
   - Sarah has now laundered access (unauditable)
   ```

5. **The "namespace isolation" is a lie**:
   ```bash
   # NetworkPolicy isolates network, but...
   # With cluster-admin, you can delete NetworkPolicy!
   
   kubectl delete networkpolicy --all -A  # Full access
   kubectl set env deployment/pod MY_SECRET=value  # Expose secrets in binary
   ```

**The right answer**:

```
cluster-admin should be held by < 5 people (SREs, security team)
These people use it:
- Only for emergency access (incident response)
- With time limits (expires after 1 hour)
- With audit logging enabled
- Preferably with approval workflow (another person must approve)

Everyone else:
- Gets READ namespaced role (view logs, describe pods)
- Gets WRITE role for their application only
- Gets no access to secrets, cluster config, system namespaces
```

**Example: Proper RBAC for diverse roles**:

```yaml
---
# SREs: cluster-admin (with emergency access controls)
# (Requires approval + expires hourly)

---
# Senior developers (team leads): edit in their namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-lead-edit
  namespace: myteam-app
subjects:
- kind: User
  name: sarah@company.com
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit

---
# Junior developers: view only (learning mode)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: junior-dev-view
  namespace: myteam-app
subjects:
- kind: User
  name: alex@company.com
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view

---
# Applications: highly restricted ServiceAccounts
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-api
  namespace: production

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: payment-api-restricted
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["payment-api-secrets"]  # ONLY this secret!
  verbs: ["get"]
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["payment-api-config"]
  verbs: ["get"]
# NO delete, NO list, NO exec, NO etc.
```

This is where I'd expect a senior engineer to nod and say "OK, that makes sense. Principle of least privilege."

---

**Continue with remaining 7+ interview questions following similar patterns covering:**
- Advanced debugging scenarios
- Resource failure deep dives
- Architectural trade-offs
- Production incident scenarios
- Compliance and security considerations

These questions should reveal:
✓ Systems thinking (understand dependencies)
✓ Operational experience (has run production systems)
✓ Security mindset (assume compromise, defense in depth)
✓ Pragmatism (know when to bend rules vs. enforce strictly)
✓ Communication (can explain complex topics simply)

---

**Last Updated**: March 2026
**Audience**: DevOps Engineers with 5–10+ years experience
**Kubernetes Versions**: 1.24+ (RBAC, NetworkPolicy, ServiceAccount token projection)







