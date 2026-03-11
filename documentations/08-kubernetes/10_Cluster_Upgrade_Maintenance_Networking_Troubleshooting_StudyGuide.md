# Advanced Kubernetes: Cluster Upgrade & Maintenance, Networking Deep Dive, and Production Troubleshooting

**Audience:** Senior DevOps Engineers (5-10+ years experience)  
**Level:** Advanced/Expert  
**Date:** March 2026

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [2.1 Key Terminology](#21-key-terminology)
   - [2.2 Architecture Fundamentals](#22-architecture-fundamentals)
   - [2.3 DevOps Principles](#23-devops-principles)
   - [2.4 Best Practices Overview](#24-best-practices-overview)
   - [2.5 Common Misunderstandings](#25-common-misunderstandings)
3. [Cluster Upgrade & Maintenance](#cluster-upgrade--maintenance)
   - [3.1 Upgrade Strategies](#31-upgrade-strategies)
   - [3.2 Node Draining](#32-node-draining)
   - [3.3 Cordon and Uncordon Operations](#33-cordon-and-uncordon-operations)
   - [3.4 Maintenance Windows](#34-maintenance-windows)
   - [3.5 Version Compatibility](#35-version-compatibility)
   - [3.6 Backup and Recovery](#36-backup-and-recovery)
   - [3.7 Rollback Procedures](#37-rollback-procedures)
   - [3.8 Best Practices for Cluster Maintenance](#38-best-practices-for-cluster-maintenance)
4. [Cluster Networking Deep Dive](#cluster-networking-deep-dive)
   - [4.1 DNS Flow Architecture](#41-dns-flow-architecture)
   - [4.2 kube-dns and CoreDNS](#42-kube-dns-and-coredns)
   - [4.3 Service Discovery](#43-service-discovery)
   - [4.4 Service Mesh Introduction](#44-service-mesh-introduction)
   - [4.5 Troubleshooting Network Issues](#45-troubleshooting-network-issues)
   - [4.6 Best Practices for Kubernetes Networking](#46-best-practices-for-kubernetes-networking)
5. [Production Troubleshooting Methodologies](#production-troubleshooting-methodologies)
6. [Hands-on Scenarios](#hands-on-scenarios)
7. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

This study guide addresses three critical pillars of enterprise Kubernetes operations that distinguish senior DevOps engineers from intermediate practitioners:

1. **Cluster Upgrade & Maintenance** – Managing Kubernetes cluster lifecycle with zero or minimal downtime
2. **Cluster Networking Deep Dive** – Deep understanding of service discovery, DNS, and inter-pod communication
3. **Production Troubleshooting Methodologies** – Systematic approaches to diagnosing and resolving complex distributed system issues

These topics are interconnected; a failed upgrade can expose networking issues, and poor network understanding leads to misdiagnosis of production outages.

### Why It Matters in Modern DevOps Platforms

#### Business Impact
- **Availability:** Poorly executed cluster upgrades cause extended downtime; studies show 15–30% of production incidents involve upgrade-related issues
- **Cost:** Inefficient troubleshooting extends MTTR (Mean Time To Resolution) by 300–500% in some organizations
- **Compliance:** Many regulatory frameworks (SOC2, PCI-DSS) require documented maintenance windows and change control procedures

#### Technical Impact
- **Kubernetes Version Fragmentation:** Clusters running 2–3 versions behind current face CVEs and deprecated API versions
- **Network Complexity:** 60–80% of production incidents in Kubernetes are network-related (DNS, service discovery, CNI issues)
- **Operational Overhead:** Organizations without structured troubleshooting methodologies require 2–3x more on-call engineers

### Real-World Production Use Cases

#### Use Case 1: Kubernetes Minor Version Upgrade (1.28 → 1.29)
**Scenario:** Enterprise SaaS platform with 500 nodes across 3 regions, 2000+ pods, financial transaction processing

**Challenge:** Upgrade window must be <2 hours; cannot lose established connections; must validate compatibility with third-party operators

**Solution:** Rolling blue-green node upgrades with connection draining, pre-upgrade API audit, and staged operator updates

**Outcome:** Zero downtime, 1.5-hour execution, discovered deprecated API usage before production impact

#### Use Case 2: Network Partition in Production
**Scenario:** Multi-zone cluster experiences unplanned network latency between control plane and worker nodes; pods fail intermittently

**Challenge:** Which layer failed? DNS? CNI? kubelet? Is it transient or persistent?

**Solution:** Systematic investigation using DNS query debugging, network policy audits, and CNI metrics; identified misconfigured network ACLs

**Outcome:** 5-minute MTTR, permanent fix applied within weekly maintenance window

#### Use Case 3: CoreDNS Performance Degradation
**Scenario:** Cluster experiences 10x increase in DNS query latency; triggers cascading application timeouts at 3 AM

**Challenge:** How do you debug DNS at scale without rolling restart?

**Solution:** CoreDNS query logging, metrics analysis, cache statistics; identified upstream recursive resolver timeout misconfiguration

**Outcome:** Configuration hotfix applied in 15 minutes without cluster restart

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────┐
│         Enterprise Cloud Platform                    │
├─────────────────────────────────────────────────────┤
│  Load Balancer (Ingress)                             │
│         ↓                                             │
│  ┌─────────────────────────────────────────────┐   │
│  │  Kubernetes Cluster (Production)             │   │
│  │  ┌────────────────────────────────────┐  │   │
│  │  │ Control Plane (HA - 3 nodes)       │  │   │
│  │  │  - API Server                      │  │   │
│  │  │  - etcd (cluster state)            │  │   │
│  │  │  - Controller Manager              │  │   │
│  │  │  - Scheduler                       │  │   │
│  │  └────────────────────────────────────┘  │   │
│  │         ↓ (Network Plane)                 │   │
│  │  ┌────────────────────────────────────┐  │   │
│  │  │ Worker Nodes (20-100+ nodes)       │  │   │
│  │  │  - kubelet (agent)                 │  │   │
│  │  │  - CNI Plugin (networking)         │  │   │
│  │  │  - kube-proxy (service routing)    │  │   │
│  │  │  - CoreDNS (service discovery)     │  │   │
│  │  │  ┌──────────────────────────────┐ │  │   │
│  │  │  │ Pods (application workloads) │ │  │   │
│  │  │  └──────────────────────────────┘ │  │   │
│  │  └────────────────────────────────────┘  │   │
│  │         ↓ (Maintenance Path)               │   │
│  │  ┌────────────────────────────────────┐  │   │
│  │  │ Upgrade Management:                │  │   │
│  │  │  - Version planning                │  │   │
│  │  │  - Node draining/cordoning         │  │   │
│  │  │  - Rolling updates                 │  │   │
│  │  │  - Rollback capabilities           │  │   │
│  │  └────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────┤
│  Storage (etcd backup, persistent volumes)         │
│  Monitoring (metrics, logs, traces)                 │
│  Observability (debugging production issues)        │
└─────────────────────────────────────────────────────┘
```

These three pillars appear at the intersection of reliability, operations, and architecture decisions.

---

## Foundational Concepts

### 2.1 Key Terminology

#### Cluster-Level Operations
- **Control Plane:** The management layer (API server, etcd, controller manager, scheduler) that orchestrates the entire cluster
- **Data Plane / Worker Nodes:** The compute nodes running actual workloads
- **HA Control Plane:** Production-grade setup with 3 (or odd number) control plane nodes for fault tolerance
- **etcd:** Distributed KV store holding all cluster state; consistency depends on quorum (3 nodes = tolerates 1 failure)

#### Upgrade & Maintenance Terminology
- **Version Skew:** The difference between kubelet, API server, and kubectl versions; Kubernetes guarantees support for N and N-1 versions only
- **Drain:** Gracefully evict all pods from a node (respecting PodDisruptionBudgets)
- **Cordon:** Mark a node as unschedulable (prevents new pods, doesn't remove existing ones)
- **Taint:** Node-level rejection criterion; pods can tolerate taints
- **Node Lease:** Lightweight heartbeat mechanism (more efficient than pod status updates)
- **Disruption Budget (PDB):** SLA defining how many pod replicas can be simultaneously disrupted during maintenance

#### Networking Terminology
- **Service Discovery:** Mechanism by which clients find and connect to backend pods
- **DNS Query Path:** Domain lookup sequence (coredns → upstream resolver → external DNS)
- **Network Policy:** Kubernetes firewall rules (L3/L4) restricting pod-to-pod communication
- **CNI (Container Network Interface):** Pluggable standard for allocating IP addresses and managing pod networking
- **kube-proxy:** Network service proxy managing iptables/IPVS rules for Service routing
- **Service Mesh:** Sidecar-based layer handling cross-pod communication policies (Istio, Linkerd)
- **Endpoint:** Individual pod IP address backing a Service

#### Troubleshooting Terminology
- **MTTR (Mean Time To Resolution):** Average time from incident detection to full recovery
- **RCA (Root Cause Analysis):** Systematic investigation method to identify underlying failure cause
- **Golden Signals:** Four key metrics (latency, traffic, errors, saturation) for system health
- **Observability:** Ability to understand system state from external outputs (logs, metrics, traces)

### 2.2 Architecture Fundamentals

#### Kubernetes Cluster Architecture Layers

**Layer 1: Control Plane (Management)**
```
┌────────────────────────────────────┐
│    Kubernetes API Server           │
│  (Request validation, admission)   │
└─────────────────┬──────────────────┘
                  ↓
┌────────────────────────────────────┐
│         etcd (State Store)         │
│  (Strongly consistent, quorum-based)
└────────────────────────────────────┘
         ↗ (lease updates)
┌────────────────────────────────────┐
│  Controller Manager & Scheduler    │
│  (Desired state → actual state)    │
└────────────────────────────────────┘
```

**Key Point:** Control plane is the "brain" but doesn't run workloads directly; worker nodes execute decisions.

**Layer 2: Data Plane (Execution)**
```
┌──────────────────────────────────────┐
│        Worker Node                   │
├──────────────────────────────────────┤
│ kubelet (agent)                      │
│  - Watches API for pod assignments   │
│  - Manages container lifecycle       │
│  - Reports node status               │
│  - Health checks & probes            │
├──────────────────────────────────────┤
│ Container Runtime (Docker/containerd)│
│  - Executes containers               │
│  - Manages images                    │
├──────────────────────────────────────┤
│ kube-proxy (network service layer)   │
│  - Implements Services via iptables  │
│  - Load balances traffic             │
├──────────────────────────────────────┤
│ CNI Plugin (network provider)        │
│  - Assigns pod IP addresses          │
│  - Manages pod networking            │
│  - Examples: Calico, Flannel, Cilium │
└──────────────────────────────────────┘
```

#### Critical Dependency Chain for Cluster Health

```
API Server Health
         ↓
   etcd Quorum (3+ nodes healthy)
         ↓
   Controller Job Completions
         ↓
   kubelet → Container Runtime
         ↓
   Pod Scheduling & Execution
         ↓
   DNS/CoreDNS (Service Discovery)
         ↓
   Application Availability
```

**Why This Matters:** A single point of failure early in the chain cascades downstream. Upgrade sequencing must respect dependencies.

#### Version Compatibility Matrix

```
┌─────────────────────────────────────────┐
│     Kubernetes Version Support          │
├─────────────────────────────────────────┤
│ Current Version:  1.29                  │
│ N-1 Supported:    1.28 (same features) │
│ N-2 Deprecated:   1.27 (APIs removed)  │
│ N-3+ Unsupported: 1.26 and earlier     │
└─────────────────────────────────────────┘

kubelet → API Server Compatibility:
  - kubelet can be N or N-1 vs API server
  - This allows rolling updates WITHOUT downtime
  - Never skip minor versions (1.27 → 1.29 is risky)
```

### 2.3 DevOps Principles

#### 1. Infrastructure as Code (IaC) for Cluster Upgrades
- Cluster configuration (versions, node counts, taints) should be declarative and version-controlled
- Enables rollback: if upgrade fails, apply prior configuration state
- Example: Terraform, CloudFormation, or GitOps tools (ArgoCD, FluxCD)

#### 2. Observability-Driven Troubleshooting
Traditional approach:
```
Problem Detected → Check logs → Try fixing → Check logs → Success/Rollback
```

Modern approach:
```
Symptoms (alerts) → Golden signals (latency, error rate, saturation)
  ↓
Distributed traces → Identify failing component
  ↓
Structured logs + context → Root cause (e.g., DNS timeouts, network policy)
  ↓
Remediation (fix, config update, or rollback)
```

#### 3. Chaos Engineering Mindset
Production clusters must survive:
- Node failures (not if, but when)
- Network partitions (split-brain scenarios)
- DNS query storms (cache invalidation)
- Resource exhaustion (memory, CPU, disk)

Proactive testing prevents production surprises.

#### 4. Change Management & Blast Radius
- Never upgrade all nodes simultaneously
- Use canary deployments (5% → 25% → 100%)
- Maintain documented rollback procedures
- Require post-change runbooks (validation steps)

#### 5. Security in the Update Pipeline
- Scan new container images before promoting to production
- Verify kubelet and control plane version signatures
- Audit cluster API access during maintenance windows
- Ensure IAM/RBAC policies survive upgrades (common failure)

### 2.4 Best Practices Overview

#### Upgrade Best Practices Summary
1. **Pre-Upgrade:** Backup etcd, audit API deprecations, test in staging identical to production
2. **Execution:** Control plane first, then nodes in waves (5–10% at a time)
3. **Post-Upgrade:** Validate all critical services, run integration tests, monitor error rates for 24 hours

#### Networking Best Practices Summary
1. **DNS:** Set appropriate TTLs, configure multiple upstream resolvers, monitor query latency
2. **Service Discovery:** Use headless services for stateful workloads, implement health checks
3. **Network Policies:** Default-deny ingress, explicit allow rules, test with network policy testing tools
4. **Observability:** Monitor Endpoint health, track connection churn, alert on DNS timeouts

#### Troubleshooting Best Practices Summary
1. **Systematic:** Gather symptoms → check each layer systematically (network → DNS → application)
2. **Non-intrusive:** Use kubectl debugging tools, network analysis without restarts when possible
3. **Reproducible:** Capture metrics/logs before remediating; enables RCA
4. **Documented:** Create runbooks; future incidents speed up resolution

### 2.5 Common Misunderstandings

#### Misunderstanding #1: "I can upgrade a node by rebooting it directly"
**Reality:** Direct reboot causes sudden pod eviction without respecting PodDisruptionBudgets. You may orphan stateful workloads.

**Correct:** `kubectl drain node-x` → reboot → node rejoins automatically

**Why It Matters:** Stateful applications (databases, caches) expect graceful shutdown; abrupt termination = data loss risk

---

#### Misunderstanding #2: "CoreDNS failures only affect external DNS lookups"
**Reality:** CoreDNS is internal service discovery. Failure = pods can't reach other services; entire cluster becomes unreachable internally

**Example Impact:** 
- Pod A tries to reach Pod B via Service B's IP
- CoreDNS returns NXDOMAIN (not found)
- Application times out immediately
- User sees "connection refused" even though Pod B is healthy

---

#### Misunderstanding #3: "Network Policies prevent all external traffic"
**Reality:** Network Policies are microsegmentation rules. Without explicit allow rules, traffic is rejected, BUT:
- Default is "allow all" if NO policies exist
- Policies only apply to pods with matching labels
- Policies DON'T protect against internal pod → pod attacks

**Correct Mental Model:** Network Policies are like firewall rules; you need someone actually running them

---

#### Misunderstanding #4: "Service mesh eliminates the need for Network Policies"
**Reality:** Service mesh (Istio, Linkerd) operates at L7 (application layer) and requires:
- Network connectivity (L3/L4) to be working first
- Network Policies to be less permissive for defense in depth
- sidecar injection to be consistent across namespaces

**Correct Relationship:** Network Policies (L3/L4) + Service Mesh (L7) = defense in depth

---

#### Misunderstanding #5: "Drain only stops new pod scheduling"
**Reality:** Drain gracefully evicts ALL pods from a node (except static pods). Process:
```
1. Cordon node (stop new scheduling)
2. Evict pod 1 (respects termination grace period)
   - Pod enters Terminating state
   - Container receives SIGTERM
   - After grace period, SIGKILL sent
3. Repeat for all pods
4. Wait for eviction to complete
```

If a pod doesn't respect termination signals, `drain --ignore-daemonsets --force` may be needed (last resort)

---

## Cluster Upgrade & Maintenance

*Detailed subsections for upgrade strategies, draining, cordoning, maintenance windows, version compatibility, backup/recovery, rollback, and best practices will follow in the next section.*

### 3.1 Upgrade Strategies

#### 3.1.1 In-Place Upgrade (NOT Recommended for Production)
- Control plane components upgraded in sequence
- Worker nodes upgraded one at a time
- etcd upgraded carefully to avoid quorum loss

**Risks:**
- Single node failure during upgrade = cluster enters degraded state
- Rollback is complex (state changes during upgrade)
- No way to quickly revert to previous version if issues occur

**When Used:** Smaller clusters, non-critical environments, or when infrastructure doesn't support other methods

---

#### 3.1.2 Blue-Green Cluster Upgrade (Recommended)
Create parallel cluster infrastructure, then switch traffic.

**Process:**
```
Production Cluster (Blue)    New Cluster (Green)
   v1.28                           v1.29
   500 nodes              →  upgrade in parallel
   healthy
   
   Switch traffic (DNS/LB update)
   
   Old cluster retained 24-48 hours as rollback option
```

**Advantages:**
- Instant rollback (switch back to blue cluster)
- Zero downtime (traffic switches after validation)
- Tests upgrades in parallel without affecting production
- Allows A/B testing application behavior with new Kubernetes version

**Disadvantages:**
- 2x infrastructure cost (temporary)
- Requires stateless storage or cross-cluster storage replication
- Complex GitOps/IaC orchestration

**Typical Timeline:**
- t=0: Start green cluster creation
- t=30m: Green cluster ready, new nodes draining resources
- t=45m: Post-upgrade validation begins
- t=60m: Traffic switch begins (canary routing: 5% traffic)
- t=75m: 100% traffic on green; blue retained as rollback
- t=48h: Blue cluster decommissioned

---

#### 3.1.3 Rolling Node Upgrade (Most Common)
Upgrade nodes sequentially while keeping cluster operational.

**Process:**
```
1. Cordon node (no new pods scheduled)
2. Drain node (gracefully evict running pods)
3. Upgrade kubelet + OS patches
4. Join node back to cluster
5. Wait for ready state
6. Repeat for next node (respecting PDB constraints)
```

**Advantages:**
- Single infrastructure footprint
- Most cost-efficient
- Simple to implement with tools (kops, kubeadm, cloud provider node pools)

**Disadvantages:**
- Temporary reduction in cluster capacity (N-1 nodes available)
- Longer total upgrade time (hours → days for large clusters)
- Risk if not properly orchestrated (concurrent pod evictions can violate PDB)

**Typical Timeline (50-node cluster):**
- Node upgrade time: 10 minutes per node
- Pod eviction + rescheduling: 5-10 minutes per node
- Total: 50 nodes × 15 min = ~12.5 hours (can parallelize 4-5 nodes)

---

#### 3.1.4 Canary Upgrade (Hybrid Approach)
Upgrade subset of nodes, validate, then proceed with rest.

**Process:**
```
Wave 1 (5% nodes):  3 nodes → upgrade → validate → ✓
Wave 2 (20% nodes): 12 nodes → upgrade → validate → ✓
Wave 3 (100%):      35 nodes → roll forward
```

**Validation Criteria:**
- Pod restart count stable
- Error rates normal
- API response times < baseline + 10%
- No deprecated API warnings in logs

**Advantages:**
- Rapid feedback if issues occur (only 3 nodes affected in Wave 1)
- Can halt upgrade immediately
- Suitable for critical, highly-loaded clusters

---

### 3.2 Node Draining

#### 3.2.1 Drain Mechanics (Deep Dive)

**Command:**
```bash
kubectl drain <node> \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --grace-period=300 \
  --timeout=10m
```

**Step-by-step Execution:**

1. **Cordon:** Mark node as unschedulable
   - New Deployments/StatefulSets won't schedule pods to this node
   - Existing pods **remain** until explicitly evicted

2. **Pod Eviction:**
   - For each pod on the node:
     - If pod has local ephemeral storage (emptyDir), check `--delete-emptydir-data`
     - If pod has PVC (persistent volume), check if PVC is mounted elsewhere (not allowed to move)
     - Send eviction request to kubelet

3. **Graceful Shutdown (Termination):**
   - Pod receives SIGTERM signal
   - Application has `terminationGracePeriodSeconds` (default 30s) to shut down cleanly
   - After grace period, kubelet sends SIGKILL (forceful termination)

4. **Pod Rescheduling:**
   - Controller regenerates pod on another eligible node
   - Respects pod anti-affinity, node selectors, resource requests

5. **Node Recovery:**
   - Reboot/upgrade happens
   - Kubelet rejoins cluster
   - Node automatically transitions from NotReady → Ready
   - Node is uncordoned (new pods can schedule again)

**Timeout Handling:**
- If drain timeout exceeded, use `--force` flag
- Force drain ignores pod disruption budgets (dangerous!)
- Force drain terminates immediately (no grace period)

---

#### 3.2.2 PodDisruptionBudget (PDB) Interactions

**PDB Definition:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2  # At least 2 web pods must be running
  selector:
    matchLabels:
      app: web
```

**Drain Respect for PDB:**
- Drain will NOT evict pods if it violates PDB
- If 3 web pods and minAvailable=2, only 1 pod evicted per wave
- Drain will wait (respecting timeout) for pod disruptions to settle

**Critical Scenario:**
```
Cluster State: 10 nodes, each with 1 critical pod
PDB: minAvailable: 8 (requires 8 replicas always running)

Node drain order: must evict max 2 pods at a time
Drain duration for all nodes: 10 nodes × 5 min (per node) = 50 minutes
```

---

#### 3.2.3 Common Drain Scenarios & Solutions

**Scenario A: Pod Won't Drain (stuck in Terminating)**
```bash
# Check why pod stuck
kubectl get pod <pod> -o yaml | grep -A5 "preStop"
kubectl describe pod <pod>  # Check events

# Common cause: preStop hook hanging
# Solution: Increase terminationGracePeriodSeconds or fix hook

# Last resort: force delete
kubectl delete pod <pod> --grace-period=0 --force
```

**Scenario B: Drain Timeout (long pod startup time)**
```bash
# Solution: Increase timeout
kubectl drain <node> --timeout=30m

# Or: Evict pods with longer timeout in PDB
# Then manually drain remaining critical pods
```

**Scenario C: StatefulSet Pods not rescheduled**
```bash
# Reason: StatefulSet requires persistent volume backing multiple nodes
# Solution: Ensure volume is accessible from all nodes (network storage)

# Verify:
kubectl get pvc <pvc-name> -o yaml | grep -i "storageClassName"
```

---

### 3.3 Cordon and Uncordon Operations

#### 3.3.1 Cordon: Purpose and Effects

**Command:**
```bash
kubectl cordon <node>
```

**What Happens:**
- Node marked with taint: `node.kubernetes.io/unschedulable:NoSchedule`
- New pods **will not** schedule to this node
- **Existing pods remain running** (key difference from drain)
- Node still participates in load balancing (kube-proxy active)

**Use Cases:**
1. **Planned Maintenance:** "I'm rebooting this node in 5 minutes, stop sending new work"
2. **Debugging:** "Keep this node's state intact while I investigate"
3. **Gradual Drain:** Pause before starting eviction (allows graceful pod eviction)

**Validation:**
```bash
kubectl get nodes
# STATUS will show "Ready,SchedulingDisabled" to indicate cordoned node
```

---

#### 3.3.2 Uncordon: Bringing Node Back Online

**Command:**
```bash
kubectl uncordon <node>
```

**What Happens:**
- Removes taint `node.kubernetes.io/unschedulable:NoSchedule`
- Node can receive new pods immediately
- Existing pods are **not** rescheduled (they stay where they are)

**Important:** Uncordon does NOT rebalance pods; new pods go to this node, taking capacity.

**Common Misconception:** "Uncordoning will rebalance pods back"
- **False.** Pods stay where they landed unless you manually delete/restart them
- Manual rebalancing: delete pod replicas from other nodes to force rescheduling

---

#### 3.3.3 Cordon/Uncordon in Upgrade Process

```
Node Ready state: Ready
         ↓
    CORDON node
         ↓
    DRAIN node (respects PDB)
         ↓
    Reboot/Upgrade (now safe, no running pods)
         ↓
    Kubelet restarts, joins cluster
         ↓
    Verify node Ready again
         ↓
    UNCORDON node
         ↓
    Node Ready,SchedulingDisabled → Ready (only status message change)
```

---

### 3.4 Maintenance Windows

#### 3.4.1 Maintenance Window Planning

**Factors:**
1. **RTO/RPO constraints** (Recovery Time/Point Objectives)
   - If RTO = 1 hour, can't run 4-hour upgrade
   - RPO = acceptable data loss window (etcd backup interval)

2. **Business impact analysis**
   - Which services are critical? (finance, auth, payment)
   - What's the peak vs. off-peak traffic pattern?
   - When is team available (time zone coverage)?

3. **Blast radius mitigation**
   - Upgrade non-critical clusters first
   - Stage critical cluster upgrade after success

**Maintenance Window Template:**
```
┌────────────────────────────────────────────────────┐
│  Kubernetes v1.28 → v1.29 Upgrade                  │
├────────────────────────────────────────────────────┤
│ Status Page: Mark maintenance (alerts suppressed)   │
│ Time: 2024-03-16 02:00 UTC (off-peak)              │
│ Duration: 3 hours (estimate)                        │
│ Affected Services: Web API, internal tooling        │
│ Unaffected: Database tier (separate cluster)        │
│ Rollback: Blue cluster ready (instant switch)       │
│ SME Contact: DevOps on-call, SRE lead              │
│ Communication: Status page updates every 15 min     │
└────────────────────────────────────────────────────┘
```

#### 3.4.2 Pre-Maintenance Checklist

```
7 days before:
  ☐ Announce maintenance window
  ☐ Review Kubernetes changelog for breaking changes
  ☐ Audit custom controllers/webhooks for API changes
  
3 days before:
  ☐ Test upgrade in staging (identical to prod config)
  ☐ Prepare rollback procedure documentation
  ☐ Brief on-call team
  
Day before:
  ☐ Final etcd backup
  ☐ Health check baseline metrics (latency, error rate)
  ☐ Chaos test: kill pods, verify auto-recovery
  
2 hours before:
  ☐ Blue cluster ready for failover (if using blue-green)
  ☐ Team assembled
  ☐ Monitoring dashboards open
  ☐ Slack/war room channel active
  
During maintenance:
  ☐ Log all actions with timestamps
  ☐ Monitor every 2 minutes
  ☐ Update status page every 15 minutes
  
Post-maintenance:
  ☐ Run full integration tests
  ☐ Verify critical SLOs met
  ☐ Document deviations from plan
  ☐ Debrief meeting within 24 hours
```

---

### 3.5 Version Compatibility

#### 3.5.1 Kubernetes Version Skew Policy

**Official Policy:**
```
API Server: v1.29
kubelet:    v1.29, v1.28 (N or N-1)
kubectl:    v1.30, v1.29, v1.28 (N+1, N, or N-1)
```

**Why N-1 Kubelet:** Allows rolling updates without control plane downtime
- Upgrade API server first (doesn't affect running workloads)
- Then upgrade kubelet (pods continue running during kubelet restart)
- If kubelet = API server version, kubelet upgrade would require pod restarts

**Consequence:** You **cannot skip minor versions**
```
Valid upgrade path:    v1.27 → v1.28 → v1.29 (safe)
Invalid upgrade path:  v1.27 → v1.29 (risk of API incompatibility)
```

---

#### 3.5.2 API Deprecation Timeline

Kubernetes API versions deprecate in phases:

```
v1.X:   API is introduced (default API group version)
        
v1.(X+1) → v1.(X+4):  Grace period (API still works)
        Optional: New version of API introduced
        
v1.(X+5): Removal (API deleted, no longer accepted)
```

**Example: Deployment API Group**
```
v1.8:   extensions/v1beta1 introduced for Deployments
v1.9:   apps/v1beta1 introduced (extension API deprecated)
v1.10:  apps/v1 introduced (final stable version)
v1.15:  extensions/v1beta1 removal (applications fail if using old API)
```

**Why It Matters:** If you skip 5+ minor versions without updating manifests, deployments fail post-upgrade.

**Pre-Upgrade Audit:**
```bash
# Find all deprecated API usage
kubectl api-resources --verbs=list --namespaced=true -o wide | grep "v1beta1"

# Use tools: kubelet-upgrade-checker, kubesec, or API deprecation scanner
# Scan all YAML files in git for deprecated versions
grep -r "apiVersion.*v1beta1" ./k8s/
```

---

#### 3.5.3 Component Version Verification

**Before Upgrade:**
```bash
# Check current versions
kubectl version
kubectl get nodes -o wide  | grep -i "kubelet\|kernel"

# Get API server version
kubectl get deployment/apiserver -n kube-system -o yaml | grep image:

# Get etcd version
kubectl get pod/etcd-master-1 -n kube-system -o yaml | grep image:
```

**Post-Upgrade Validation:**
```bash
# Verify all components upgraded
kubectl version --short

# Check node status
kubectl get nodes -o wide
# All nodes should be Ready and have new kernel version

# Verify no failed controllers
kubectl get pods -n kube-system --field-selector=status.phase!=Running
```

---

### 3.6 Backup and Recovery

#### 3.6.1 etcd Backup Strategy

**Why etcd Backup is Critical:**
- etcd is the **single source of truth** for entire cluster configuration
- All Deployments, ConfigMaps, Secrets, RBAC policies stored in etcd
- Disk corruption = loss of entire cluster state
- etcd is NOT replicated to S3/cloud storage automatically

**Backup Types:**

**1. Point-in-Time Snapshot (Full Backup)**
```bash
# While etcd is running
ETCDCTL_API=3 etcdctl \
  --endpoints https://127.0.0.1:2379 \
  --cacert /etc/kubernetes/pki/etcd/ca.crt \
  --cert /etc/kubernetes/pki/etcd/server.crt \
  --key /etc/kubernetes/pki/etcd/server.key \
  snapshot save backup.db

# Verify backup
ETCDCTL_API=3 etcdctl \
  --endpoints https://127.0.0.1:2379 \
  snapshot status backup.db
```

**2. Incremental Backup (Changes Only)**
- etcd WAL (write-ahead log) contains every state change
- Can replay WAL from snapshot up to any point in time
- More efficient than full snapshots every hour

**Backup Frequency:**
```
Cluster Size          Backup Frequency
< 10 nodes           Every 4 hours (or daily)
10-50 nodes          Every 2 hours
50+ nodes            Every 1 hour
Critical system      Every 15 minutes + incremental WAL
```

**Storage Policy:**
```
✓ Store on separate node (not etcd member)
✓ Encrypt backups at rest (AES-256)
✓ Replicate to cloud storage (S3, GCS, ABS)
✓ Test restore procedure monthly
✓ Retain backups for 30 days minimum
✓ Tag backups with: version, date, checksum
```

---

#### 3.6.2 Full Cluster Backup

Beyond etcd, backup all persistent state:

```bash
# 1. Export all Kubernetes manifests
kubectl get all --all-namespaces -o yaml > full-backup.yaml
kubectl get customresourcedefinition -o yaml >> full-backup.yaml
kubectl get rbac.authorization.k8s.io -o yaml >> full-backup.yaml

# 2. Backup persistent volumes
# (depends on storage backend: Ceph, NetApp, cloud provider)
# Example: AWS EBS snapshots for all PVs

# 3. Backup etcd
ETCDCTL_API=3 etcdctl snapshot save full-backup.db

# 4. Store credentials (sealed-secrets, external-secrets configs)
# (if using GitOps secret management, this is tracked in git)
```

---

#### 3.6.3 Recovery Procedure

**Scenario: etcd corruption, cluster unresponsive**

**Recovery Steps:**

```
1. Identify healthy etcd member
   - Check logs: /var/log/pods/kube-system_etcd-*/
   
2. Backup current (corrupted) state
   ETCDCTL_API=3 etcdctl snapshot save corrupted-backup.db
   
3. Restore from known-good backup
   ETCDCTL_API=3 etcdctl snapshot restore \
     --data-dir=/var/lib/etcd-restored \
     backup.db
   
4. Stop API server, controller manager (prevent writes during restore)
   systemctl stop kubelet
   
5. Replace etcd data directory
   rm -rf /var/lib/etcd
   mv /var/lib/etcd-restored /var/lib/etcd
   
6. Restart etcd member
   systemctl start kubelet
   
7. Verify cluster is responsive
   kubectl get nodes
   kubectl get pods --all-namespaces
   
8. If multi-member etcd (HA):
   - Restore each member from same snapshot
   - Verify quorum re-established (all members healthy)
```

**Recovery Time:** 15-60 minutes depending on cluster size

---

### 3.7 Rollback Procedures

#### 3.7.1 Rollback Strategy Selection

**Option A: Blue-Green Cluster Rollback (FASTEST)**
- **Time:** 5 minutes (DNS update + traffic switch)
- **Risk:** Minimum
- **Cost:** Retain old cluster 24-48 hours

```
Production traffic on v1.29 (new) → issue detected
Switch back to v1.28 (old) cluster (pre-tested, fully functional)
Issue resolved immediately
```

**Option B: In-Place Rollback (SLOWEST/RISKIEST)**
- **Time:** 2-6 hours
- **Risk:** High (data may have changed during new version)
- **Process:** Downgrade kubelet, API server, etcd (reverse order of upgrade)

```
Implications:
  - Pods created since upgrade may be incompatible with v1.28
  - etcd doesn't support downgrades (version metadata embedded)
  - App deployments may use v1.29 API → YAML invalid in v1.28
```

**Option C: Configuration Rollback (SAFEST)**
- **Time:** 5 minutes
- **Risk:** Zero
- **Caveat:** Only works if issue is in config/controller logic, not Kubernetes version

```
Upgrade complete, but new controller version broke something
Rollback controller deployment to previous image
Cluster version stays at v1.29, bug fix applied
```

---

#### 3.7.2 Before-Upgrade Preparation for Rollback

**Backup:**
```bash
# Day before upgrade
kubectl get all --all-namespaces -o yaml > pre-upgrade-backup.yaml
ETCDCTL_API=3 etcdctl snapshot save pre-upgrade-backup.db

# Store in multiple locations
aws s3 cp pre-upgrade-backup.yaml s3://cluster-backups/
aws s3 cp pre-upgrade-backup.db s3://cluster-backups/
```

**Pre-Upgrade Metrics Snapshot:**
```bash
# Baseline metrics for comparison post-upgrade
kubectl top nodes > baseline-nodes.txt
kubectl top pods --all-namespaces > baseline-pods.txt

# Application SLOs
curl https://prometheus/api/v1/query?query=p99_latency > baseline-slos.json
```

**Blue Cluster Ready:**
If using blue-green:
```bash
# Blue cluster (v1.28) must be fully healthy
kubectl get nodes -o wide  # status=Ready
kubectl get pods -n kube-system | wc -l  # All critical pods running
kubectl get events -n kube-system | tail -20  # No warnings
```

---

#### 3.7.3 Rollback Decision Criteria

**When to Rollback (Red Flags):**
```
✗ Control plane API unresponsive (kubectl get nodes → timeout)
✗ > 10% of pods CrashLoopBackOff
✗ Error rate spike > 5% above baseline
✗ P99 latency > 2x baseline
✗ Critical system pods (DNS, kube-proxy) failing
✗ etcd quorum loss
✗ Data loss (PVC mount failures)
✗ Security issue discovered in new version (CVE)
```

**When NOT to Rollback (Acceptable Issues):**
```
✓ Deprecated API warnings (expected, has grace period)
✓ Minor performance variance (< 2%)
✓ New features don't work as expected (restart the feature, don't rollback)
✓ One node unhealthy (restart that node, don't rollback entire cluster)
```

---

#### 3.7.4 Rollback Execution

**Blue-Green Rollback (Recommended):**
```bash
# Prerequisite: Blue cluster running v1.28 ready
# Currently: Green cluster v1.29 serving 100% traffic

# Switch 5% traffic to blue (canary)
kubectl patch service/api-ingress -p '{"spec":{"trafficPolicy":"canary","weight":5}}'

# Monitor for 5 minutes
kubectl logs -f deployment/api --since=1m | grep -i error

# Decision point: issues detected → full rollback
# Switch 100% traffic back to blue
kubectl patch service/api-ingress -p '{"spec":{"weight":0}}'

# Keep green cluster running for 24h (root cause analysis)
# Then decommission
```

**In-Place Rollback (Last Resort):**
```bash
# Only if blue-green not available
# Downgrade in reverse order: nodes first, then control plane, then etcd

for node in node-1 node-2 node-3; do
  kubectl cordon $node
  kubectl drain $node --ignore-daemonsets
  # SSH to node, downgrade kubelet
  ssh $node 'sudo apt-get install kubelet=1.28.0-00'
  ssh $node 'sudo systemctl restart kubelet'
  kubectl uncordon $node
  sleep 5m  # Wait for pod rescheduling
done

# Downgrade control plane
# (most complex, may require manual etcd intervention)
```

---

### 3.8 Best Practices for Cluster Maintenance

#### 3.8.1 Maintenance Automation

**GitOps-Based Upgrade Orchestration:**
```yaml
# FluxCD or ArgoCD automatically orchestrates upgrades
apiVersion: helm.fluxcd.io/v1
kind: HelmRelease
metadata:
  name: kube-upgrade
spec:
  chart:
    repository: https://charts.example.com
    name: kube-upgrade
  values:
    kubernetesVersion: "1.29"
    nodeGroups:
      - name: worker-1
        count: 10
        maxUnavailable: 1  # Auto-drain 1 node at a time
      - name: worker-2
        count: 10
        maxUnavailable: 1
```

**Lifecycle Hooks:**
```yaml
# Trigger actions before/after upgrade
spec:
  lifecycle:
    preUpgrade:
      - name: healthcheck
        script: ./scripts/pre-upgrade-validate.sh
      - name: backup
        script: ./scripts/backup-etcd.sh
    postUpgrade:
      - name: smoke-tests
        script: ./scripts/smoke-tests.sh
      - name: notify
        webhook: "https://slack.example.com/..."
```

---

#### 3.8.2 PodDisruptionBudget Strategy

**Recommended Configuration:**
```yaml
# For deployment with 3+ replicas
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 2  # OR
  maxUnavailable: 1  # At most 1 pod down simultaneously
  selector:
    matchLabels:
      app: critical-app
---
# For stateful workloads (databases)
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: database-pdb
spec:
  minAvailable: "100%"  # NEVER disrupt
  selector:
    matchLabels:
      app: database
  unhealthyPodEvictionPolicy: "AlwaysAllow"  # Unless stuck
```

---

#### 3.8.3 Monitoring & Alerting During Maintenance

**Critical Metrics to Monitor:**
```
1. Pod Restart Count
   - Alert if > 2x baseline during maintenance
   - Indicates resource squeeze or cascading failures

2. API Server Response Times
   - P95: < 100ms, P99: < 500ms (baseline)
   - Spike during maintenance expected, but should stay < 200ms

3. etcd Commit Duration
   - Measured in milliseconds
   - If > 1000ms during upgrade, quorum in trouble

4. Kubelet Readiness
   - Track NotReady nodes
   - All nodes should reach Ready within 5 minutes of upgrade completion

5. Application SLOs
   - Error rate, P99 latency, throughput
   - Monitor for cascading failures (one pod down → all pods overloaded)

6. PVC Mount Failures
   - Quick indicator of storage connectivity issues
   - Common during node reboots
```

**Example Alert Rules:**
```yaml
groups:
  - name: cluster-upgrade
    rules:
      - alert: PodRestartSpike
        expr: rate(kubelet_pod_worker_Duration_seconds_count[5m]) > 0.1
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Pod restart rate {{ $value }} pods/sec"
      
      - alert: APIServerLatency
        expr: histogram_quantile(0.99, rate(apiserver_request_duration_seconds_bucket[5m])) > 0.5
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "API server P99 latency {{ $value }}s (baseline: 0.1s)"
      
      - alert: EtcdCommitDuration
        expr: histogram_quantile(0.99, etcd_fslibio_writeDuration_seconds_bucket) > 1
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "etcd commit duration {{ $value }}s"
```

---

#### 3.8.4 Documentation & Change Management

**Upgrade Runbook Template:**
```markdown
# Kubernetes 1.28 → 1.29 Upgrade Runbook

## Pre-Upgrade (7 days before)
- [ ] Review changelog
- [ ] Test in staging
- [ ] Identify deprecated APIs
- [ ] Prepare rollback procedures

## During Upgrade
- [ ] Start maintenance window
- [ ] Update status page
- [ ] Upgrade control plane
- [ ] Monitor for 5 minutes
- [ ] Upgrade nodes in waves
- [ ] Verify each wave

## Post-Upgrade
- [ ] Run smoke tests
- [ ] Verify SLOs
- [ ] Document issues
- [ ] Schedule debrief

## Rollback (If Needed)
- [ ] Switch traffic to blue cluster
- [ ] Monitor for 10 minutes
- [ ] If stable, decommission green
```

**Change Log Entry:**
```
Date: 2024-03-16 02:00 UTC
Change: Kubernetes upgrade v1.28 → v1.29
Reason: Security patches, performance improvements
Status: Successful
Duration: 2 hours 45 minutes
Issues: None
Risk: Low (blue-green, tested in staging)
Owner: DevOps Team
```

---

## Cluster Networking Deep Dive

*Next sections: DNS flow architecture, kube-dns/CoreDNS, service discovery, service mesh, troubleshooting, best practices*

### 4.1 DNS Flow Architecture

#### 4.1.1 Kubernetes DNS Query Path

**Typical Pod-to-Service DNS Resolution:**

```
Pod (App Container)
       ↓ (DNS query: "my-service.default.svc.cluster.local")
kubelet's DNS resolver (127.0.0.11:53)
       ↓ (forwards to)
CoreDNS Service (10.96.0.10:53 - Kubernetes DNS)
       ↓ (if .cluster.local - internal)
       → CoreDNS in-memory lookup table
       ↓ (if not found, upstream recursion)
       → Upstream Resolver (8.8.8.8 or corporate DNS)
       ↓
Root nameserver
       ↓
TLD nameserver
       ↓
Authoritative nameserver
       ↓ (returns IP)
       ← CoreDNS receives response
       ← Pod receives IP address
```

**DNS Configuration in Pod:**
```bash
# Inside any pod's /etc/resolv.conf
cat /etc/resolv.conf
```
```
nameserver 10.96.0.10  # CoreDNS service IP
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

**What This Means:**
- All DNS queries first go to 10.96.0.10 (CoreDNS)
- Queries appended with search domains if no dots
- `ndots:5` means only FQDN queries (5+ dots) skip search appending

---

#### 4.1.2 CoreDNS Query Processing

**Internal Query (my-service.default):**

1. Query arrives at CoreDNS
2. CoreDNS checks configured zones (Corefile)
3. Matches against Kubernetes zone (cluster.local)
4. Queries Kubernetes API: "What Endpoints back my-service?"
5. Returns A record with backing pod IPs
6. Caches result (TTL: 30 seconds default)

**External Query (google.com):**

1. Query arrives at CoreDNS
2. Doesn't match internal zones
3. Forwards to upstream resolver (8.8.8.8 or configured)
4. Caches result (TTL: 300 seconds default)

**CoreDNS ConfigMap (typical):**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
          lameduck 5s
        }
        ready
        log
        prometheus :9153
        cache 30  # Cache TTL 30 seconds
        forward . /etc/resolv.conf  # Upstream resolver
        reload
        loop
        loadbalance
    }
```

---

#### 4.1.3 DNS Caching Layers

**Multiple caching levels exist:**

```
Pod Container (glibc DNS cache)
    ↓ (TTL: DNS TTL or APP default)
kubelet's dnsmasq or systemd-resolved (if enabled)
    ↓ (TTL: OS resolver cache, ~600 seconds)
CoreDNS in-process cache
    ↓ (TTL: 30 seconds for internal, 300 for external)
Upstream resolver (ISP or corporate)
    ↓ (TTL: authoritative DNS TTL)
Authoritative nameserver
```

**Implication:** TTL in DNS record reflects authoritative server TTL, but actual pod caching may be different.

**TTL Override:**
```yaml
# Service update: IP changed from 10.1.1.1 → 10.1.1.2
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: my-app
status:
  loadBalancer:
    ingress:
      - ip: 10.1.1.2
```

**Real-time Impact:**
- Pod tries to reach 10.1.1.1 (old cached IP)
- Connection times out
- After 30 seconds (CoreDNS cache TTL), next DNS query gets 10.1.1.2
- Pod retries, succeeds

**Best Practice:** Set DNS TTL low for transient services (30 seconds), higher for stable services (300 seconds)

---

### 4.2 kube-dns and CoreDNS

#### 4.2.1 Evolution: kube-dns → CoreDNS

**kube-dns (Legacy, deprecated v1.13):**
```
SkyDNS (Go DNS library)
    ↗ watches Kubernetes API
    ↗ responds to DNS queries
    ↗ forwards upstream
```

**Limitations:**
- Single-threaded, CPU bottleneck
- No caching layer (all queries upstream)
- Limited configurability
- Replaced by CoreDNS in v1.11+

**CoreDNS (Current standard v1.13+):**
```
Caddy server (Go framework)
    ↗ plugin architecture (highly extensible)
    ↗ built-in caching, logging, metrics
    ↗ multi-threaded, high performance
    ↗ Prometheus metrics native
```

---

#### 4.2.2 CoreDNS Plugins (Deep Dive)

**Essential Plugins:**

| Plugin | Purpose | Example Config |
|--------|---------|-----------------|
| **kubernetes** | Watches K8s API, responds to internal queries | `kubernetes cluster.local` |
| **forward** | Upstream DNS recursion | `forward . 8.8.8.8:53` |
| **cache** | Response caching with TTL | `cache 30` |
| **log** | Query logging for debugging | `log {format {common}}` |
| **prometheus** | Expose metrics for monitoring | `prometheus :9153` |
| **loadbalance** | Round-robin between endpoints | `loadbalance round_robin` |
| **errors** | Log errors to stderr | `errors` |
| **loop** | Detect DNS loops (CNAME chains) | `loop` |
| **rewrite** | Modify queries (CNAME forwarding) | `rewrite stop {name regex pattern to}` |
| **autopath** | Enable SRV record search paths | `autopath @kubernetes` |

**Advanced Corefile Example:**
```yaml
data:
  Corefile: |
    .:53 {
        errors
        health {
          lameduck 5s
        }
        ready
        
        # Internal zone
        kubernetes cluster.local in-addr.arpa ip6.arpa {
          pods insecure
          fallthrough in-addr.arpa ip6.arpa
          ttl 30
        }
        
        # External queries
        forward . /etc/resolv.conf {
          policy sequential  # Use first upstream resolver
        }
        
        # Response caching
        cache 30
        
        # DNSSec validation
        dnssec
        
        # Monitoring
        prometheus :9153
        
        # Logging
        log
    }
    
    # Separate zone for corporate DNS
    internal.corp:53 {
        forward . 10.0.0.1:53 {
            policy round_robin  # Load balance queries
        }
        cache 60
    }
```

---

#### 4.2.3 CoreDNS Deployment Architecture

**Typical Kubernetes Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  template:
    spec:
      priorityClassName: system-cluster-critical
      containers:
      - name: coredns
        image: coredns:1.10.1
        resources:
          requests:
            cpu: 100m
            memory: 70Mi
          limits:
            cpu: 100m
            memory: 170Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8181
          initialDelaySeconds: 0
          periodSeconds: 2
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          capabilities:
            drop:
              - ALL
            add:
              - NET_BIND_SERVICE
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.96.0.10  # Fixed IP (critical!)
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  - name: metrics
    port: 9153
    protocol: TCP
```

**Key Points:**
- CoreDNS IP (10.96.0.10) is **hardcoded** in every pod's /etc/resolv.conf (kubelet configures this)
- If CoreDNS service disappears = entire cluster DNS breaks
- Replicas = 2 minimum (HA)
- PDB should prevent eviction of both replicas simultaneously

---

#### 4.2.4 CoreDNS Scaling Considerations

**CPU/Memory Usage Factors:**
- Query rate (QPS - queries per second)
- Zone complexity (number of services, endpoints)
- Upstream resolver performance/latency
- Query logging verbosity

**Typical Scalability:**
```
Cluster Size    Recommended Replicas    Expected QPS
10-50 nodes     2                       1K-5K QPS
50-100 nodes    2-3                     5K-20K QPS
100-500 nodes   3-4                     20K-100K QPS
500+ nodes      4-5 + horizontal scaling 100K+ QPS
```

**Horizontal Scaling (HPA):**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: coredns-hpa
  namespace: kube-system
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: coredns
  minReplicas: 2
  maxReplicas: 3
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
        averageUtilization: 75
```

---

### 4.3 Service Discovery

#### 4.3.1 Service Discovery Mechanisms

**Mechanism 1: DNS (Most Common)**

```
Client Pod needing database access:
┌──────────────────────────────────────────┐
│ import redis client                       │
│ client = redis.Redis(host="db-service")  │
└─────────────────┬────────────────────────┘
                  ↓
            DNS query: "db-service"
                  ↓
            CoreDNS resolves to IP: 10.1.1.100
                  ↓
            Pod connects to 10.1.1.100:6379
```

**Mechanism 2: Environment Variables (Legacy)**

Kubelet injects service IPs as ENV vars:

```bash
# Inside pod
echo $DB_SERVICE_HOST  # 10.1.1.100
echo $DB_SERVICE_PORT  # 6379

# Connection uses ENV instead of DNS
```

**Mechanism 3: Headless Service (Stateful Workloads)**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None  # ← No cluster IP! (headless)
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
```

**DNS Returns Multiple IPs:**
```
mysql.default.svc.cluster.local → [10.1.1.1, 10.1.1.2, 10.1.1.3]
mysql-0.mysql.default.svc.cluster.local → 10.1.1.1  (StatefulSet pod)
mysql-1.mysql.default.svc.cluster.local → 10.1.1.2
mysql-2.mysql.default.svc.cluster.local → 10.1.1.3
```

**Use Case:** StatefulSets needing pod-specific identities (databases, message queues)

---

#### 4.3.2 Endpoint Lifecycle

**Behind the Scenes of a Service:**

```yaml
# User creates Service
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
    - port: 80
---
# User creates Deployment (creates Pods matching selector)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web  # ← Matches Service selector
    spec:
      containers:
      - name: web
        image: nginx:latest
```

**What Kubernetes Does Automatically:**

```
1. Service Controller watches for services
   ↓
2. "web" service has selector "app: web"
   ↓
3. Endpoint Controller queries: "Find all pods with label app=web"
   ↓
4. Finds 3 pods with IPs: 10.2.1.1, 10.2.1.2, 10.2.1.3
   ↓
5. Creates Endpoints object:
   apiVersion: v1
   kind: Endpoints
   metadata:
     name: web
   subsets:
     - addresses:
         - ip: 10.2.1.1
           targetRef:
             kind: Pod
             name: web-xxx-yyy
         - ip: 10.2.1.2
           targetRef:
             kind: Pod
             name: web-abc-def
       ports:
         - port: 80
   ↓
6. CoreDNS watches Endpoints, updates DNS records
   ↓
7. Pod queries "web" → CoreDNS returns all 3 IPs
```

**Endpoint Health:**

```
Pod Status Changes:
  Healthy (Ready) → Endpoint.addresses.ip
  Unhealthy (NotReady) → Endpoint.notReadyAddresses.ip (excluded from DNS)
  
Real-time Impact:
  Pod crashes → kubelet marks NotReady
  → Endpoint Controller removes from addresses
  → CoreDNS stops returning this IP
  → New connections bypass this pod
  → Old connections eventually timeout
```

---

#### 4.3.3 Service Discovery Failure Modes

**Failure Mode 1: Endpoint Not Created**

```
Symptoms: kubectl get endpoints → NAME shows up but no IPs
Diagnosis:
  1. Check Service selector matches Pod labels
     kubectl get svc web -o yaml | grep selector
     kubectl get pods --show-labels | grep app=web
  
  2. Check no label typo (case-sensitive)
     kubectl get svc web -o jsonpath='{.spec.selector}'
  
  3. Check Service and Pods in same namespace
     kubectl get svc web -n production
     kubectl get pods -n production --show-labels
```

**Failure Mode 2: DNS Returns Wrong IP**

```
Symptoms: kubectl exec pod -- nslookup web → returns old IP
Diagnosis:
  1. Check cached DNS
     kubectl exec pod -- nslookup -d2 web  (verbose debugging)
  
  2. CoreDNS cache might be stale
     Solution: Restart CoreDNS (clears cache)
  
  3. Application caches DNS result
     Solution: Configure application DNS TTL,客户端重试
```

**Failure Mode 3: kube-proxy Not Updating iptables**

```
Symptoms: telnet web 80 → connection refused (but pod healthy)
Diagnosis:
  1. Check kube-proxy running
     kubectl get pods -n kube-system | grep proxy
  
  2. Check iptables rules updated
     kubectl get endpoints web -o yaml | grep ip:
     # Compare to: sudo iptables -t nat -L KUBE-SERVICES | grep web
  
  3. kube-proxy logs
     kubectl logs -n kube-system -l k8s-app=kube-proxy | tail -50
```

---

### 4.4 Service Mesh Introduction

#### 4.4.1 What is a Service Mesh?

Service mesh is a dedicated infrastructure layer handling service-to-service communication.

**Traditional Load Balancing (Kubernetes Service):**
```
┌─────────┐ DNS Query: web.default.svc.cluster.local → 10.1.1.100 (ClusterIP)
│ Pod A   │
├─────────┤ TCP Connect: 10.1.1.100:80
│         │ 
│ Connect │ kube-proxy iptables rule: ClusterIP 10.1.1.100 → Pod IP:port
│ to web  │
│         │ Random pod selected: 10.2.1.5:8080
└─────────┘
     ↓
   TCP connection direct to 10.2.1.5
   No retry logic
   No observability
   No circuit breaking
```

**Service Mesh (Istio Example):**
```
┌─────────┐ TCP Connect: web (mesh-enabled DNS)
│ Pod A   │
├─────────┤ Envoy sidecar proxies request (mTLS)
│ Envoy   │ Applies retry logic (up to 3 times)
│ sidecar │ Circuit breaking (fail fast if pod unhealthy)
│         │ Distributed tracing (see full request flow)
│         │ Rate limiting (100 req/sec)
│ Connect │ Canary routing (5% to staging, 95% to prod)
│ to web  │
│ traffic │ Load balancing algorithm: least_request
└─────────┘
     ↓
   Envoy selects endpoint with least active connections
   Retries on failure
   Traces request through all microservices
   Metrics logged: latency, errors, bytes transferred
```

---

#### 4.4.2 Comparing Kubernetes Built-in Network to Service Mesh

| Feature | Kubernetes Native | Service Mesh (Istio) |
|---------|-------------------|----------------------|
| **Service Discovery** | DNS | DNS + Advanced routing |
| **Load Balancing** | Round-robin (kube-proxy) | Weighted, least request, consistent hash |
| **Retries** | Application code | Automatic (sidecar configures) |
| **Timeouts** | Application code | Automatic |
| **Circuit Breaking** | Manual health checks | Automatic |
| **Observability** | Logs, metrics, traces (if app instruments) | Automatic distributed tracing |
| **Security (mTLS)** | Manual TLS cert management | Automatic cert rotation |
| **A/B Testing / Canary** | Infrastructure code (Deployments) | Traffic management rules |
| **Rate Limiting** | Ingress controller or app | Service Mesh enforcer |
| **Cost** | Minimal | Extra CPU/memory (sidecars) |
| **Complexity** | Lower | Higher (new abstraction layer) |

---

#### 4.4.3 Service Mesh Architecture (Istio Example)

```
┌─────────────────────────────────────────────────────────────┐
│         Service Mesh Control Plane (Istiod)                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Service Registry (watches K8s API)                  │  │
│  │ Policy Engine (security, traffic policies)          │  │
│  │ Telemetry Collector (metrics, tracing)             │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
              ↓ (PushConfig - updated continuously)
┌─────────────────────────────────────────────────────────────┐
│         Data Plane (Envoy Sidecars in each pod)             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Pod 1              Pod 2              Pod 3                │
│ ┌─────────┐  ┌──────────────┐  ┌──────────────┐            │
│ │ App     │  │ App          │  │ App          │            │
│ │ (web)   │  │ (database)   │  │ (cache)      │            │
│ ├─────────┤  ├──────────────┤  ├──────────────┤            │
│ │ Envoy   │  │ Envoy        │  │ Envoy        │            │
│ │ sidecar │  │ sidecar      │  │ sidecar      │            │
│ │         │──→(mTLS)───────→│  │              │            │
│ │ :15000│  │ :15000       │  │ :15000      │             │
│ └─────────┘  └──────────────┘  └──────────────┘            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

**Key:** All inter-pod traffic flows through sidecar proxies; original network is unused.

---

#### 4.4.4 Service Mesh Use Cases

**When to Use Service Mesh:**

1. **Large polyglot microservices (20+ services, multiple languages)**
   - Istio brings consistency (same timeouts, retries, security across all languages)
   - Without mesh, every language (Java, Python, Go, Node) implements own retry logic (bugs!)

2. **Strict security requirements (zero trust, mTLS)**
   - Service mesh auto-manages certificates
   - Transparent encryption between all pods
   - Policy enforcement (which services can talk)

3. **Complex traffic patterns**
   - Canary deployments (5% new version)
   - A/B testing (route based on headers)
   - Blue-green deployments

4. **Observability demands**
   - Automatic distributed tracing
   - Service dependency graph
   - Cross-service latency metrics

**When NOT to Use Service Mesh:**

1. **Simple applications (< 5 microservices)**
   - Complexity not justified
   - Kubernetes native + application-level logic sufficient

2. **Performance requirements (sub-millisecond latency)**
   - Envoy sidecars add 5-15ms latency
   - CPU overhead ~200m per pod (bare app costs ~10m)

3. **Legacy monoliths migrating to containers**
   - Mesh assumes cloud-native, container-per-service architecture

---

### 4.5 Troubleshooting Network Issues

#### 4.5.1 Systematic Network Debugging Methodology

**Debugging Framework (Layer by Layer):**

```
Layer 1: Pod Connectivity (Can pod reach host?)
   ├─ kubectl exec pod -- ping <pod-ip>
   └─ Check MTU, network interface state

Layer 2: Service DNS (Does DNS work?)
   ├─ kubectl exec pod -- nslookup my-service
   └─ Check CoreDNS responding, Endpoints created

Layer 3: Service Routing (Does kube-proxy route correctly?)
   ├─ kubectl exec pod -- telnet my-service 80
   └─ Check iptables rules on node

Layer 4: Pod-to-Pod (Can I reach other pods directly?)
   ├─ kubectl exec pod-a -- curl http://pod-b-ip:8080
   └─ Check Network Policies allowing traffic

Layer 5: Application Layer (Is application listening?)
   ├─ kubectl logs pod (check for bind errors)
   └─ kubectl describe pod (check readiness probes)
```

---

#### 4.5.2 Common Network Issues & Solutions

**Issue #1: Service Not Found (NXDOMAIN)**

```bash
# Symptom: Application error "nslookup my-service" → NXDOMAIN
SYMPTOM_CHECK:
  kubectl exec pod -- nslookup my-service  
  # Output: NXDOMAIN (non-existent domain)

# Diagnosis Steps:
1. Check Service exists
   kubectl get svc my-service --all-namespaces
   
2. Check Service in correct namespace
   # If service in "production" ns but pod in "default" ns:
   kubectl exec pod -- nslookup my-service.production.svc.cluster.local
   
3. Check CoreDNS running
   kubectl get pods -n kube-system | grep coredns
   kubectl logs -n kube-system -l k8s-app=kube-dns | tail -20
   
4. Check Endpoints created
   kubectl get endpoints my-service
   # If empty, service selector doesn't match any pods
   
5. Check pod labels match service selector
   kubectl get svc my-service -o jsonpath='{.spec.selector}'
   kubectl get pods --show-labels | grep my-app

SOLUTION:
  Fix service selector or pod labels to match
  kubectl label pods pod-name app=my-app
```

---

**Issue #2: Service IP Reachable but Connection Refused**

```bash
# Symptom: DNS works, telnet my-service 80 → connection refused

DIAGNOSIS:
1. Check Pod running/ready
   kubectl get pod -o wide | grep my-service
   kubectl get pod pod-name -o yaml | grep -A5 "conditions"
   # readinessProbe: success? (status=True)
   
2. Check port number correct
   kubectl get svc my-service -o yaml | grep -A2 "ports:"
   # Is containerPort correct in Deployment?
   
3. Check pod actually listening on port
   kubectl exec pod-name -- ss -tlnp | grep :80
   # Should see process listening on :80
   
4. Check kube-proxy iptables rules
   kubectl get svc my-service -o jsonpath='{.spec.clusterIP}'
   # Now on node: sudo iptables -t nat -L KUBE-SERVICES | grep my-service
   # Should see rules directing traffic
   
5. Check pod firewall (securityContext)
   kubectl get pod pod-name -o yaml | grep -A10 "securityContext"
   # Check capabilities, restrictive policies

SOLUTION:
  Check container logs: kubectl logs pod-name -c container-name
  Check readiness probe logic
  Verify application listening on 0.0.0.0 (not 127.0.0.1)
```

---

**Issue #3: DNS Slow (Timeouts 5+ seconds)**

```bash
# Symptom: nslookup takes 5+ seconds every time

DIAGNOSIS:
1. Check CoreDNS response time
   kubectl exec my-pod -- time nslookup external-site.com
   # Compare internal vs external DNS time
   # Internal should be < 100ms, external < 500ms
   
2. Check upstream resolver
   kubectl -n kube-system exec coredns-xxx -- cat /etc/resolv.conf
   # Check nameserver is responding
   kubectl -n kube-system exec coredns-xxx -- timeout 2 dig google.com @8.8.8.8
   
3. Check CoreDNS logs
   kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50
   # Look for "upstream timeout" or query errors
   
4. Check CoreDNS cache hitting
   # Restart CoreDNS pod forces cache clear
   kubectl delete pod -n kube-system -l k8s-app=kube-dns
   # Restart invalidates cache, may improve next query
   # Then again check: time nslookup
   
5. Monitor CoreDNS metrics
   kubectl port-forward -n kube-system svc/prometheus 9090:9090
   # Query: coredns_dns_request_duration_seconds
   # P99 should be < 100ms

SOLUTION:
  - Decrease TTL for frequently-accessed services
  - Add DNS caching proxy on nodes (dnsmasq)
  - Increase CoreDNS replicas
  - Configure multiple upstream resolvers
  - Add DNS query monitoring/alerting
```

---

**Issue #4: Pod-to-Pod Connection Sporadic (Flakiness)**

```bash
# Symptom: kubectl exec pod-a -- curl pod-b:8080 works 80% of time, fails 20%

DIAGNOSIS:
1. Check Network Policies
   kubectl get networkpolicies --all-namespaces
   kubectl describe networkpolicy <policy>
   # May be randomly rejecting packets
   
2. Check pod restarts / cascading failures
   kubectl get pods -A --sort-by=.status.containerStatuses[0].restartCount
   # High restart count → pod crashing, getting rescheduled
   
3. Check node resource pressure
   kubectl top nodes
   # If memory/CPU at 80%+, kernel may drop packets
   
4. Check conntrack table exhaustion
   kubectl debug node/<node> -it --image=ubuntu
   # sudo sysctl net.netfilter.nf_conntrack_count
   # Compare to nf_conntrack_max
   
5. Check MTU mismatch (packets too large)
   kubectl exec pod-a -- ping -M do -s 1472 pod-b-ip
   # If fails, MTU might be smaller than 1500

SOLUTION:
  - Review and simplify Network Policies
  - Monitor node resources, trigger autoscaler alerts
  - Tune kernel conntrack parameters
  - Increase MTU if possible (typically pre-cluster-setup)
  - Implement connection pooling in application
```

---

#### 4.5.3 Network Debugging Tools

**Essential Debugging Commands:**

```bash
# Inside pod (if netcat in image)
kubectl exec pod -- nc -zv my-service 80  # Check open port
kubectl exec pod -- timeout 2 bash -c 'cat < /dev/null > /dev/tcp/my-service/80' # TCP check

# DNS debugging from pod
kubectl exec pod -- nslookup my-service
kubectl exec pod -- dig +trace my-service.default.svc.cluster.local
kubectl exec pod -- getent hosts my-service

# Network debugging from node
kubectl debug node/<node> -it --image=ubuntu
  # Now inside node, can run tcpdump, iptables, ss

# Persistent debugging (ephemeral container)
kubectl debug pod/<pod> -it --image=ubuntu
  # Non-disruptive; debugger runs in separate container in same pod

# CoreDNS query logging
kubectl logs -n kube-system -l k8s-app=kube-dns --all-containers=true -f

# kube-proxy logs (check for service routing errors)
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Check Service Endpoints
kubectl describe svc my-service
# Includes Endpoints section showing backing pod IPs
```

---

### 4.6 Best Practices for Kubernetes Networking

#### 4.6.1 DNS Best Practices

**1. Set Appropriate TTLs:**
```yaml
# For frequently-accessed services (often changing replicas)
spec:
  clusterIP: 10.1.1.100
  sessionAffinity: None  # Enable for stateful services
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours

# Service TTL in CoreDNS: 30 seconds (allows rapid detection)
# External DNS TTL: 300 seconds (stable records)
```

**2. Configure Multiple Upstream Resolvers:**
```yaml
# CoreDNS Corefile
.:53 {
    forward . 8.8.8.8:53 8.8.4.4:53 {
        policy round_robin  # Distribute load
    }
    cache 30  # Cache results locally
}
```

**3. Monitor DNS Performance:**
```yaml
# Prometheus rule
- alert: CoreDNSQueryLatency
  expr: |
    histogram_quantile(0.99, rate(coredns_dns_request_duration_seconds_bucket[5m]))
    > 0.1  # > 100ms is concerning
  for: 3m
```

---

#### 4.6.2 Service Design Best Practices

**1. Use Headless Services for Stateful Workloads:**
```yaml
# ✗ BAD: StatefulSet using regular Service (round-robin)
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  selector:
    app: mysql
  clusterIP: 10.1.1.100  # Load balanced
  ports:
    - port: 3306

# ✓ GOOD: Headless Service (pod-specific lookup)
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  selector:
    app: mysql
  clusterIP: None  # No load balancing
  ports:
    - port: 3306
```

**2. Use Service Selectors Carefully:**
```yaml
# ✗ BAD: Overly broad selector
spec:
  selector:
    environment: production  # Matches 100 pods from 5 different apps!

# ✓ GOOD: Specific, scoped selector
spec:
  selector:
    app: my-app
    tier: backend
```

**3. Health Checks for Reliable Service Discovery:**
```yaml
spec:
  containers:
  - name: app
    image: my-app:latest
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 2
      successThreshold: 1
      failureThreshold: 2
```

---

#### 4.6.3 Network Policy Best Practices

**1. Default-Deny Ingress:**
```yaml
# Block all incoming traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  # Empty ingress rules = deny all
```

**2. Explicit Allow Rules:**
```yaml
# Then explicitly allow needed traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
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
```

**3. Test Network Policies:**
```bash
# Before deploying to production, test policies
# Using tools like: nsenter, network-policy-simulator
kubectl apply -f network-policy.yaml
kubectl exec pod-a -- curl pod-b:8080
# Verify: succeeds for allowed, fails for denied
```

---

#### 4.6.4 CNI Plugin Selection

**Common CNI Plugins:**

| Plugin | Strengths | Weaknesses | Best For |
|--------|-----------|-----------|----------|
| **Calico** | High performance, network policies, BGP | Complex setup | Large clusters, strict security |
| **Flannel** | Simple, minimal deps, VXLAN/host-gw | Limited policies | Simple dev/test clusters |
| **Cilium** | eBPF performance, fine-grained policies | Kernel requirements | Modern Linux, high throughput |
| **AWS VPC CNI** | Native AWS integration, no overlay | AWS-only, cost | AWS EKS clusters |
| **Azure CNI** | Native Azure integration | Azure-only | Azure AKS clusters |

**Selection Criteria:**
```
Small dev cluster (<10 nodes)   → Flannel (simple)
Production <50 nodes            → Calico (features + performance)
Large scale (100+ nodes, 1000+) → Cilium (eBPF performance)
public cloud (AWS/Azure)        → Native CNI (cost, performance)
```

---

## Production Troubleshooting Methodologies

### 5.1 Incident Response Framework

#### 5.1.1 Incident Classification & Severity

**Severity Levels:**

```
┌────────────────────────────────────────────────────────────┐
│ SEVERITY P1 (Critical)                                     │
│ Impact: Complete service unavailability                    │
│ Duration threshold: Begin incident response immediately   │
│ Example: All API pods crashed, DB connection pool expired │
│ SLA: < 1 hour resolution                                  │
├────────────────────────────────────────────────────────────┤
│ SEVERITY P2 (High)                                         │
│ Impact: Major functionality degraded, significant latency  │
│ Example: 50% error rate, P99 latency 5x baseline          │
│ SLA: < 4 hours resolution                                 │
├────────────────────────────────────────────────────────────┤
│ SEVERITY P3 (Medium)                                       │
│ Impact: Minor functionality affected, user impact noticed │
│ Example: Specific endpoint slow, one region impacted      │
│ SLA: < 24 hours resolution                                │
├────────────────────────────────────────────────────────────┤
│ SEVERITY P4 (Low)                                          │
│ Impact: No user-facing impact, internal issue             │
│ Example: Deprecated API warnings, unused controller logs  │
│ SLA: < 1 week resolution                                  │
└────────────────────────────────────────────────────────────┘
```

**Automated Alert Routing:**
```yaml
# AlertManager routing
groups:
- name: kubernetes-alerts
  rules:
  - alert: KubeletNotReady
    expr: kube_node_status_condition{condition="Ready",status="true"} == 0
    for: 5m
    annotations:
      severity: P2
      oncall_group: kubernetes-team
      runbook: "https://wiki/runbooks/kubelet-not-ready"
      
  - alert: PodCrashLooping
    expr: rate(kube_pod_container_status_restarts_total[15m]) > 0.1
    for: 2m
    annotations:
      severity: P2
      oncall_group: application-team
      runbook: "https://wiki/runbooks/pod-crash-loop"
      dashboard: "https://grafana/d/pod-health"
```

---

#### 5.1.2 Incident Response Flow

**Incident Timeline:**

```
t=0min: Alert fired
   ├─ Monitoring system detects anomaly
   ├─ PagerDuty/Opsgenie notification sent
   └─ On-call engineer paged

t=2min: Alert acknowledged
   ├─ Engineer opens incident channel (Slack war room)
   ├─ Status page updated: "Investigating"
   └─ SME (subject matter expert) notified if escalation needed

t=5min: Initial triage
   ├─ Quick health check: kubectl get nodes, get pods
   ├─ Customer impact assessment
   ├─ Determine if rollback vs forward fix
   └─ If no obvious cause, begin structured debugging

t=15min: Decision point
   ├─ If root cause clear & simple fix → Execute fix
   ├─ If root cause unclear → Escalate to senior engineer
   ├─ If widespread impact & fix risky → Consider rollback
   └─ Update status page every 5 minutes

t=30min: Resolution or escalation
   ├─ If fixed: Monitor for 10 minutes (verify stability)
   ├─ If not fixed: Escalate severity, involve architecture review
   └─ Status page: "Mitigated" or "Investigating"

t=60min: Emergency escalation
   ├─ If still unresolved: VP/Director notified
   ├─ Consider partial workarounds (degrade gracefully)
   ├─ Prepare rollback readiness
   └─ Communicate ETA to customers

Post-incident:
   ├─ Declare resolved in status page
   ├─ Monitor for regression (24 hours)
   ├─ Schedule post-mortem (within 48 hours)
   └─ Create action items for prevention
```

**Example War Room Responses:**

```
[11:23] oncall: Alert: APIServerLatencyP99 > 5s (baseline: 100ms)
[11:23] sre1: kubectl get nodes → all Ready, no recent changes
[11:24] sre1: kubectl top nodes → CPU 85%, memory 70% (normal)
[11:24] sre2: Check recent deployments → app-v2.4 rolled out 5 min ago
[11:25] oncall: Correlate: deployment → latency spike
[11:25] sre1: Rollback app to v2.3
[11:26] sre1: kubectl rollout undo deployment/app -n production
[11:27] sre2: Latency recovering, P99 now 150ms
[11:28] oncall: Status page: "Incident mitigated, monitoring"
[11:29] sre1: Charts normal, error rate = 0
[11:35] oncall: Incident resolved
[11:40] oncall: Post-mortem scheduled for 2024-03-17 10:00
```

---

### 5.2 Root Cause Analysis (RCA) Deep Dive

#### 5.2.1 RCA Methodology: The 5 Whys Technique

**Framework:**

```
Problem Statement: "API endpoints return 500 errors"

Why 1: Why are endpoints returning 500 errors?
Applied 5m ago: database connection credentials changed

Why 2: Why did credentials change?
Automated vault rotation policy triggered early due to security advisory

Why 3: Why wasn't the pod updated with new credentials?
Service mesh secret injection was disabled during upgrade

Why 4: Why was secret injection disabled during upgrade?
Release notes didn't mention this breaking change

Why 5: Why didn't we catch this in staging?
Staging uses static credentials, not vault rotation

ROOT CAUSE: Staging environment not mirroring production (vault + secret injection)

PREVENTION: Enforce staging parity, test secret injection in pre-production
```

**Advanced RCA: Timeline Analysis**

```
Timeline of Events:

10:00 - Vault rotation scheduled (security advisory)
10:01 - Service mesh control plane updated (v1.14 → v1.15)
10:02 - Secret injection sidecar not restarted (old version cached)
10:03 - API pod requested new credential from vault via old sidecar
10:04 - Old sidecar can't inject new secret (version mismatch)
10:05 - Pod uses stale credential with vault
10:06 - Vault denies access: "Credential rotated"
10:07 - Database connections fail
10:08 - Application exhausts connection pool
10:09 - Requests timeout, API returns 500
10:10 - Monitoring alert fires
10:12 - Alert reaches on-call
```

**Causal Chain Identified:**
```
Version mismatch (control plane ≠ sidecar)
       ↓
Secret injection broken
       ↓
Stale credentials used
       ↓
Database authentication fails
       ↓
Connection exhaustion
       ↓
API errors
```

---

#### 5.2.2 RCA Tools & Techniques

**Distributed Tracing for RCA:**

```yaml
# Jaeger/Zipkin integration: Trace end-to-end request flow
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  template:
    spec:
      containers:
      - name: api
        image: api:v1.0
        env:
        - name: JAEGER_AGENT_HOST
          value: jaeger-collector.observability.svc
        - name: JAEGER_AGENT_PORT
          value: "6831"
        - name: JAEGER_SAMPLER_TYPE
          value: "const"
        - name: JAEGER_SAMPLER_PARAM
          value: "1"  # Sample 100% during incidents
        ports:
        - name: http
          containerPort: 8080
        - name: metrics
          containerPort: 8081
```

**Trace Analysis (Jaeger UI):**
```
Request: GET /api/users/123
  ├─ Service: api-gateway (2ms)
  │  └─ validate-jwt (1ms)
  │  └─ route-decision (1ms)
  │
  ├─ Service: user-service (150ms) ← SLOW
  │  ├─ auth-check (5ms)
  │  ├─ database-query (140ms) ← ROOT CAUSE
  │  │   └─ Connection pool wait: 100ms
  │  │   └─ Query execution: 40ms
  │  └─ serialize-response (5ms)
  │
  │ Error: "Connection pool timeout"
  │ Stack trace: java.sql.SQLException: Timeout waiting for ideal object
  │
  └─ Response: 500 Internal Server Error
```

**Prometheus Query Analysis (Observability):**

```promql
# Query 1: Request latency by service during incident window
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
# Shows: api-service P99 = 150ms (normal), user-service P99 = 5000ms (5x increase)

# Query 2: Error rate
rate(http_requests_total{status=~"5.."}[5m])
# Shows: error rate spike at 10:09

# Query 3: Database connection pool exhaustion
mysql_connections_in_use / mysql_connections_max
# Shows: 100% at incident time (pool saturated)

# Query 4: Service mesh latency (sidecar overhead)
histogram_quantile(0.99, rate(envoy_http_downstream_rq_time_bucket[5m]))
# Shows: Sidecar latency spiked (possible version issue)
```

---

#### 5.2.3 Common RCA Failure Modes

**Failure Mode 1: Blaming the recent change**
```
"API latency increased after re-deployment"
Assumption: Code change caused issue
Reality: Deployment happened 5 hours earlier, latency spiked 30 min ago
Actual cause: Cron job triggering backup, consuming disk I/O

Prevention:
  - Correlate timing precisely (within 5 minute window)
  - Check ALL recent changes (deployments, config updates, infra changes)
  - Use transaction logs: what changed in the last 15 minutes?
```

**Failure Mode 2: Fixing symptom instead of root cause**
```
Symptom: Pod memory usage at 80%, pods OOMKilled
Reaction: Increase memory requests
Reality: Memory leak in application (keeps growing)

After increase:
  - Pods will OOMKill again after 2-3 days
  - Problem repeats, customers frustrated

Correct approach:
  - Application profiling: memory.prof in Go
  - Identify memleak: unclosed connection, retained references
  - Fix code, not infrastructure
```

**Failure Mode 3: Incomplete RCA (stopping too early)**
```
RCA stopped at:
  "Database connection pool exhausted"
  
Fix applied:
  Increase connection pool from 20 → 50
  
Result: 
  Incident repeats in 1 hour (higher load)
  
Complete RCA required:
  Why is pool exhausted? → Why are queries slow? → Why is query slow?
  Underlying issue: Missing database index on frequently-queried column
  
Correct fix:
  Add index, query completes in 10ms (vs 500ms)
  Connection pool no longer exhausted
```

---

### 5.3 Post-Mortem Process

#### 5.3.1 Post-Mortem Meeting Structure

**Timing:** Schedule within 24-48 hours of incident resolution

**Participants:**
- Incident commander (facilitator)
- Engineers involved in recovery
- Service owner
- SRE/platform team lead
- Product/business stakeholder (if customer impact)

**Meeting Agenda (60 minutes):**

```
[0-5 min]   Opening remarks
            - This is not blame-focused
            - Goal: System improvement, not individual accountability

[5-15 min]  Incident Summary
            - Timeline of events
            - Severity & impact (revenue loss, usage %, SLA breach)
            - Duration: detection → resolution

[15-30 min] Root Cause Analysis
            - 5 Whys breakdown
            - System diagram showing failure chain
            - Why monitoring didn't catch it earlier

[30-45 min] Action Items
            - Immediate fixes (already deployed)
            - Short-term improvements (1-2 weeks)
            - Long-term architectural changes (1-3 months)
            - Prevention mechanisms

[45-55 min] Action Item Assignment
            - Owner for each action item
            - Target completion date
            - Success criteria

[55-60 min] Retrospective on response
            - What went well
            - What could improve
            - Process improvements
```

---

#### 5.3.2 Post-Mortem Document Template

```markdown
# Post-Mortem: API Service Unavailability - 2024-03-16

**Severity:** P1 (Complete outage)  
**Duration:** 47 minutes (10:08 - 10:55)  
**Impact:** 15,000 affected users, 0.8% revenue loss  
**Participants:** @alice (SRE), @bob (API team), @carol (DBA)

## Timeline

| Time | Event |
|------|-------|
| 10:00 | Vault rotation starts |
| 10:01 | Service mesh control plane upgraded |
| 10:02 | Secret injection version mismatch |
| 10:09 | First 500 error returned |
| 10:10 | Alert fires (error rate > 1%) |
| 10:12 | On-call acknowledges |
| 10:25 | Root cause identified |
| 10:40 | Control plane downgraded |
| 10:55 | Full recovery, error rate = 0 |

## Root Cause
Service mesh control plane (v1.15) updated without corresponding sidecar restart.
Secret injection sidecar (v1.14) incompatible with v1.15 control plane.
Old sidecar couldn't inject rotated vault credentials.
Database authentication failed, cascading to all pods.

## Action Items

| Priority | Item | Owner | Target | Status |
|----------|------|-------|--------|--------|
| P0 | Downgrade control plane (DONE) | @alice | 10:40 | ✅ |
| P1 | Fix upgrade orchestration: sidecar restart on control plane upgrade | @bob | 2024-03-17 | 🔄 |
| P2 | Add pre-flight check: verify control plane ↔ sidecar compatibility | @carol | 2024-03-20 | ⏳ |
| P3 | Improve staging: enable vault rotation in staging replica | @alice | 2024-03-30 | ⏳ |

## Prevention

1. **Upgrade orchestration:** Service mesh upgrades must restart adjacent sidecars
2. **Testing:** Pre-prod environment must replicate ALL production infrastructure
3. **Monitoring:** Alert on control plane ↔ sidecar version skew
4. **Documentation:** Upgrade runbook must include sidecar restart step

## Lessons Learned

✓ What went well:
  - Alert fired immediately (2 min)
  - On-call responded quickly
  - Tracing identified vault credential error

✗ What could improve:
  - Staging didn't catch version incompatibility
  - Upgrade runbook incomplete
  - No pre-flight compatibility check

## References

- Incident ticket: JIRA-12345
- Deployment log: `kubectl rollout history deploy/api -n production`
- Grafana dashboard: http://grafana/d/service-mesh-health
```

---

### 5.4 Monitoring & Alerting Best Practices

#### 5.4.1 Golden Signals Framework

**Concept:** Monitor 4 key metrics that indicate system health

```
┌──────────────────────────────────────┐
│     Golden Signals (SRE)             │
├──────────────────────────────────────┤
│ 1. LATENCY                           │
│    (Response time: p50, p95, p99)   │
│    Alert: P99 > baseline × 2        │
│                                      │
│ 2. TRAFFIC                           │
│    (Requests per second, throughput) │
│    Alert: QPS spike > 150% or dip   │
│                                      │
│ 3. ERRORS                            │
│    (Error rate, failed requests)     │
│    Alert: Error rate > 1%            │
│                                      │
│ 4. SATURATION                        │
│    (Resource utilization: CPU, mem)  │
│    Alert: CPU > 80%, memory > 85%   │
│                                      │
└──────────────────────────────────────┘

Relationship:
  Saturation ↑ → Latency ↑ → Errors ↑
```

**Prometheus Rules for Golden Signals:**

```yaml
groups:
  - name: golden-signals
    interval: 30s
    rules:
    
    # LATENCY: API P99
    - record: api:request_latency_p99:5m
      expr: |
        histogram_quantile(0.99, 
          rate(http_request_duration_seconds_bucket[5m]))
    
    - alert: HighAPILatency
      expr: api:request_latency_p99:5m > 0.5  # > 500ms
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "API P99 latency {{ $value }}s (baseline: 0.1s)"
        dashboard: "https://grafana/d/api-health"
    
    # TRAFFIC: Request rate
    - record: api:requests_total:5m
      expr: rate(http_requests_total[5m])
    
    - alert: APITrafficSpike
      expr: |
        api:requests_total:5m > 2 * avg_over_time(api:requests_total:5m[1h])
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: "API traffic {{ $value }} req/s (baseline: 100 req/s)"
    
    # ERRORS: Error rate
    - record: api:error_rate:5m
      expr: |
        rate(http_requests_total{status=~"5.."}[5m]) /
        rate(http_requests_total[5m])
    
    - alert: HighErrorRate
      expr: api:error_rate:5m > 0.01  # > 1%
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Error rate {{ $value | humanizePercentage }}"
    
    # SATURATION: Resource utilization
    - alert: HighCPUUtilization
      expr: |
        container_cpu_usage_seconds_total /
        container_spec_cpu_quota > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod CPU {{ $value | humanizePercentage }} (pod: {{ $labels.pod }})"
```

---

#### 5.4.2 SLI/SLO/SLA Definitions

**Terminology:**

```
SLI (Service Level Indicator):
  Measurable metric
  Example: "API endpoint returns response < 500ms"
  
SLO (Service Level Objective):
  Target for SLI
  Example: "99% of requests < 500ms"
  
SLA (Service Level Agreement):
  Contractual commitment to customers
  Example: "99.9% uptime, $10/month credit if missed"
```

**SLI/SLO Definition for Critical Service:**

```yaml
# Service: Payment API
# SLOs define risk budget for on-call decisions

name: payment-api
slos:
  - name: availability
    window: 30d
    target: 99.95%  # Max 22 minutes downtime/month
    sli:
      metric: uptime
      calculation: |
        successful_requests / total_requests
        where status in [200, 202]
    
  - name: latency
    window: 30d
    target: 99%  # 99% of requests < 500ms
    sli:
      metric: request_duration_p99
      calculation: |
        count(request_duration_ms < 500) / 
        count(total_requests)
  
  - name: error_rate
    window: 30d
    target: 99%  # < 1% error rate
    sli:
      metric: error_rate
      calculation: |
        (total_requests - failed_requests) / total_requests

# Error budget: How much SLO can I violate?
error_budget:
  availability: 
    max_downtime: 22 minutes/month
    remaining: 15 minutes (used by incident)
    
  latency:
    max_violations: 1% of requests
    remaining: 0.5% (used by degradation)
    
  action_on_spend:
    > 50% spent: freeze all non-critical features
    > 75% spent: on-call paged for any new issue
    100% spent: emergency response (fix or rollback)
```

**Error Budget Decision Making:**

```
Scenario 1: New feature rollout planned
Error budget spent: 60%
Decision: BLOCK feature, fix issues first

Scenario 2: Critical performance optimization available
Error budget spent: 20%
Decision: APPROVE, low risk with buffer remaining

Scenario 3: Regular maintenance (non-impacting)
Error budget spent: 85%
Decision: DELAY, wait for SLO reset (next month)
```

---

#### 5.4.3 Alert Fatigue Prevention

**Problem:** Too many alerts → on-call ignores notifications

**Alert Tuning:**

```yaml
# ❌ BAD: Alert fires 100 times/hour
- alert: PodMemoryHigh
  expr: container_memory_usage_bytes > 1Gi
  for: 1m  # Too short, fires on every memory spike

# ✓ GOOD: Alert fires only for sustained problems
- alert: PodMemoryHigh
  expr: container_memory_usage_bytes > 1Gi
  for: 10m  # Fires after memory stays high for 10 minutes

# ❌ BAD: Alerts on every transient condition
- alert: APILatencyHigh
  expr: http_request_duration_seconds > 1s

# ✓ GOOD: Alerts on trends, not spikes
- alert: APILatencyTrend
  expr: |
    rate(http_request_duration_seconds[5m]) >
    rate(http_request_duration_seconds offset 1d) * 1.5
  for: 15m  # Only alert if latency sustained 50% higher than yesterday

# Alert grouping to reduce notifications
route:
  receiver: 'team-pagerduty'
  group_by: ['service', 'severity']
  group_wait: 10s        # Wait 10s to batch similar alerts
  group_interval: 5m     # Re-send after 5m if unresolved
  repeat_interval: 24h   # Don't re-send unless acknowledged
```

**Alert Severity Matrix:**

```
┌────────────────────────────────────────────────────┐
│         Alert Severity Decision Tree               │
├────────────────────────────────────────────────────┤
│ Customer Impact?                                   │
│ ├─ YES                                             │
│ │  ├─ Impact > 1% users → CRITICAL/P1             │
│ │  ├─ Impact 0.1-1% users → HIGH/P2               │
│ │  └─ Impact < 0.1% users → MEDIUM/P3             │
│ │                                                  │
│ └─ NO                                              │
│    ├─ Could impact soon? → MEDIUM/P3              │
│    ├─ Preventive (monitoring) → LOW/P4            │
│    └─ Informational → INFO (no page)              │
└────────────────────────────────────────────────────┘

Paging rules:
  P1 → Page immediately (SMS + call)
  P2 → Page within 5 minutes (Slack + email)
  P3 → Slack only (no page)
  INFO → Logging only
```

---

### 5.5 Common Troubleshooting Tools & Techniques

#### 5.5.1 Essential kubectl Debugging Commands

**Pod Inspection:**

```bash
# Describe pod with full event history
kubectl describe pod <pod> -n <ns>
# Shows: status, phase, conditions, volumes, containers, events

# Get pod manifest at current state
kubectl get pod <pod> -n <ns> -o yaml

# Check pod logs (current)
kubectl logs <pod> -n <ns> -c <container>

# Check pod logs (previous instance if crashed)
kubectl logs <pod> -n <ns> -c <container> --previous

# Follow logs realtime (like tail -f)
kubectl logs <pod> -n <ns> -f

# Get logs from multiple pods
kubectl logs -n <ns> -l app=my-app --all-containers=true

# Debug pod with ephemeral container (non-disruptive)
kubectl debug pod/<pod> -n <ns> -it --image=ubuntu
# Can install tools (curl, dig, netcat) in debug container
```

**Node Inspection:**

```bash
# Debug entire node
kubectl debug node/<node> -it --image=ubuntu
# System pods still running on node
# Can use chroot to access host filesystem

# Check node conditions
kubectl get nodes -o wide
kubectl describe node <node>

# Get node resource usage
kubectl top node
kubectl top node <node> --containers

# Check kubelet status (from node debug)
systemctl status kubelet
journalctl -u kubelet -n 50
```

**Service & Endpoint Debugging:**

```bash
# Check service exists and has endpoints
kubectl get svc <svc> -n <ns> -o wide
kubectl get endpoints <svc> -n <ns>

# Detailed endpoint inspection (includes condition)
kubectl get ep <svc> -n <ns> -o yaml

# Test service connectivity
kubectl exec <pod> -n <ns> -- curl <svc>:80
kubectl exec <pod> -n <ns> -- nslookup <svc>

# Check service DNS from within pod
kubectl exec <pod> -n <ns> -- cat /etc/resolv.conf
```

---

#### 5.5.2 Network Debugging Commands

**DNS Debugging:**

```bash
# From inside pod
kubectl exec <pod> -- nslookup my-service
kubectl exec <pod> -- dig my-service +short
kubectl exec <pod> -- getent hosts my-service

# With verbose output
kubectl exec <pod> -- nslookup -d2 my-service
kubectl exec <pod> -- dig +trace my-service

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check CoreDNS cache hit rate
kubectl exec -n kube-system <coredns-pod> -- \
  curl localhost:9153/metrics | grep coredns_dns_request_total
```

**Connectivity Testing:**

```bash
# Test TCP port reachability
kubectl exec <pod> -- timeout 2 bash -c 'cat < /dev/null > /dev/tcp/my-service/80'
# Exit code 0 = port open, 1 = refused

# Test with netcat (if available)
kubectl exec <pod> -- nc -zv my-service 80

# Package capture from pod
kubectl exec <pod> -- tcpdump -i eth0 -n -c100 'tcp port 80'

# Check iptables rules on node
kubectl debug node/<node> -it --image=ubuntu
# hostnsenter -n -t 1 iptables -t nat -L KUBE-SERVICES | grep my-service
```

---

#### 5.5.3 Performance Profiling Tools

**Memory Profiling (Go applications):**

```bash
# Get memory profile from running pod
kubectl port-forward <pod> 6060:6060 &
go tool pprof http://localhost:6060/debug/pprof/heap

# Commands in pprof:
# top10         - Show top 10 memory consumers
# list <func>   - Show line-by-line breakdown
# show <func>   - Assembly view
```

**CPU Profiling:**

```bash
# Get CPU profile (30s sample)
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Or from deployed container
kubectl exec <pod> -- curl http://localhost:6060/debug/pprof/profile > profile.out
go tool pprof profile.out
```

**Resource Metrics:**

```bash
# Real-time metrics per pod
kubectl top pod -n <ns>

# Detailed container breakdown
kubectl top pod -n <ns> --containers

# Node resource allocation
kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, cpu: .status.allocatable.cpu, memory: .status.allocatable.memory}'
```

---

#### 5.5.4 Log Aggregation & Search

**Kubernetes Event Analysis:**

```bash
# Get cluster events sorted by time
kubectl get events -A --sort-by='.lastTimestamp'

# Find errors in events
kubectl get events -A --field-selector=type!=Normal

# Events for specific resource
kubectl describe pod <pod> -n <ns>
# (shows Events section at bottom)
```

**Log Search Pattern:**

```bash
# Find all pods that crashed with OOMKill
kubectl get pods -A -o json | \
  jq '.items[] | select(.status.containerStatuses[].lastState.terminated.reason=="OOMKilled") | .metadata.name'

# Find pods with many restarts
kubectl get pods -A --sort-by='.status.containerStatuses[0].restartCount'

# Find recent pod creations (indicates churn)
kubectl get pods -A -o json | \
  jq '.items[] | select(.status.startTime > "2024-03-16T10:00:00Z") | .metadata.name'
```

---

## Hands-on Scenarios

### Scenario 1: Node Failure Recovery with PodDisruptionBudget

**Objective:** Gracefully handle node failure with minimal service disruption

**Environment:**
```
Cluster: 3 worker nodes (node-1, node-2, node-3)
Application: web deployment (3 replicas)
PDB: minAvailable: 2 (always keep 2+ replicas)
```

**Failure Simulation Script:**

```bash
#!/bin/bash
# simulate-node-failure.sh

set -e

# 1. Check initial state
echo "=== Initial State ==="
kubectl get nodes
kubectl get pods -o wide
kubectl get pdb

# 2. Simulate node failure (power loss)
echo "=== Cordoning node-1 ==="
kubectl cordon node-1

# 3. Watch pod eviction
echo "=== Observing pod migration ==="
watch kubectl get pods -o wide --all-namespaces

# 4. Drain node (respects PDB)
echo "=== Draining node-1 ==="
kubectl drain node-1 --ignore-daemonsets --timeout=2m

# 5. Verify pods moved
echo "=== Post-drain state ==="
kubectl get pods -o wide
kubectl get pdb
# Should show: 2 pods on node-2, 1 pod on node-3
# minAvailable: 2 maintained throughout

# 6. Simulate node recovery
echo "=== Simulating node recovery ==="
# In real scenario: reboot node, fix hardware, rejoin cluster
# For simulation: just uncordon
kubectl uncordon node-1

# 7. Monitor pod rescheduling
echo "=== Watching pod rebalancing ==="
watch kubectl get pods -o wide
```

**Expected Output:**

```
=== Initial State ===
NAME      STATUS   ROLES   
node-1    Ready    worker  
node-2    Ready    worker  
node-3    Ready    worker  

web-aaa   1/1     Running    node-1
web-bbb   1/1     Running    node-2
web-ccc   1/1     Running    node-3

=== After drain ===
NAME      STATUS                     
node-1    Ready,SchedulingDisabled   

web-aaa   1/1     Running    node-2    (migrated)
web-bbb   1/1     Running    node-2    
web-ccc   1/1     Running    node-3    

minAvailable: 2 ✓ (2 pods still running)

=== After uncordon ===
(No automatic rebalancing; pods stay on node-2/3)
(New pods would schedule to node-1)
```

---

### Scenario 2: DNS Timeout Incident Investigation

**Objective:** Diagnose and fix CoreDNS performance issues

**Problem:** Pods report "connection timeout" → Application cascades

**Investigation Steps:**

```bash
#!/bin/bash
# debug-dns-timeout.sh

echo "=== Step 1: Check CoreDNS Running ==="
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get svc -n kube-system kube-dns

echo "=== Step 2: Test DNS from pod ==="
kubectl run -it --rm debug --image=ubuntu --restart=Never -- bash
# Inside pod:
time nslookup kubernetes    # Should be < 100ms
time nslookup google.com    # Should be < 500ms

echo "=== Step 3: Check CoreDNS logs ==="
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50 | grep -i "timeout\|error"

echo "=== Step 4: Monitor CoreDNS metrics ==="
kubectl port-forward -n kube-system svc/prometheus 9090:9090 &
# Visit: http://localhost:9090/graph
# Query: coredns_dns_request_duration_seconds_bucket (should be < 100ms p99)

echo "=== Step 5: Check upstream resolver ==="
kubectl exec -it -n kube-system <coredns-pod> -- bash
# Inside coredns:
dig google.com @8.8.8.8 +short  # Test external resolver
dig google.com @1.1.1.1 +short  # Test alternate resolver

echo "=== Step 6: Identify slow zone ==="
# CoreDNS debug logs
kubectl logs -n kube-system -l k8s-app=kube-dns -f | grep -i "slow query"

echo "=== Step 7: Check pod resource ==="
kubectl top pod -n kube-system -l k8s-app=kube-dns
# High CPU → increase replicas
# High memory → memory leak or excessive caching

echo "=== Remediation ==="
# If CoreDNS pod slow:
kubectl scale deployment coredns -n kube-system --replicas=3

# If upstream resolver slow:
# Update Corefile to use multiple resolvers
kubectl edit configmap coredns -n kube-system
# Change: forward . 8.8.8.8 → forward . 8.8.8.8 8.8.4.4 1.1.1.1
```

**Expected Findings & Solutions:**

```
Finding 1: Upstream resolver slow
  Evidence: External DNS queries > 2s, internal < 100ms
  Solution: Add multiple upstream resolvers, enable aggressive caching

Finding 2: CoreDNS pod overloaded
  Evidence: CPU 95%, QPS 50K/sec
  Solution: Add CoreDNS replicas, enable query caching

Finding 3: Network policy blocking DNS
  Evidence: DNS works sometimes, intermittent failures
  Solution: Verify NetworkPolicy allows 53/UDP to CoreDNS pods
```

---

### Scenario 3: Cluster Upgrade Canary Rollout

**Objective:** Safely upgrade cluster from v1.28 → v1.29 using canary approach

**Setup:**

```bash
#!/bin/bash
# cluster-upgrade-canary.sh

CLUSTER="production"
OLD_VERSION="1.28"
NEW_VERSION="1.29"
TOTAL_NODES=10

echo "=== Pre-Upgrade Validation ==="
# Check deprecated APIs
kubectl api-resources --verbs=list -o wide | grep deprecat

# Backup etcd
ETCDCTL_API=3 etcdctl snapshot save backup-v1.28.db
aws s3 cp backup-v1.28.db s3://cluster-backups/

# Baseline metrics
kubectl get nodes -o wide
kubectl top nodes

echo "=== Wave 1: Canary (2 nodes) ==="
for node in node-1 node-2; do
  echo "Upgrading $node..."
  kubectl cordon $node
  kubectl drain $node --ignore-daemonsets --timeout=5m
  
  # SSH to node and perform upgrade
  # (actual commands depend on cluster setup: kubeadm, cloud provider, etc.)
  ssh $node "sudo apt-get update && sudo apt-get install kubelet=1.29.0"
  ssh $node "sudo systemctl restart kubelet"
  
  # Wait for ready
  kubectl wait --for=condition=Ready node/$node --timeout=5m
  kubectl uncordon $node
  
  echo "Validating $node..."
  sleep 30  # Wait for pod startup
  
  # Check error rate
  ERROR_RATE=$(curl http://prometheus:9090/api/v1/query?query='increase(errors_total[5m])' | jq '.data.result[0].value[1]')
  if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
    echo "ERROR RATE SPIKE! Rolling back..."
    kubectl rollout undo deployment/app
    exit 1
  fi
done

echo "=== Wave 1 Success: Error rate normal"

sleep 5m  # Monitor wave 1 for 5 minutes

echo "=== Wave 2: 50% (5 nodes) ==="
for node in node-3 node-4 node-5 node-6 node-7; do
  # ... same upgrade process ...
done

echo "=== Wave 3: 100% (remaining 3 nodes) ==="
for node in node-8 node-9 node-10; do
  # ... same upgrade process ...
done

echo "=== Post-Upgrade Validation ==="
kubectl version
kubectl get nodes -o wide
kubectl top nodes

echo "=== Testing ==="
# Run smoke tests
./smoke-tests.sh

echo "✓ Upgrade successful!"
```

**Expected Timeline:**

```
t=0:   Start Wave 1 (canary)
t=15:  Wave 1 nodes upgraded & validated
t=20:  Monitoring confirms stability
t=45:  Wave 2 begun (50% nodes)
t=90:  Wave 3 begun (remaining nodes)
t=150: All nodes upgraded, validation complete
t=180: Smoke tests pass, upgrade declared successful
```

---

## Interview Questions & Detailed Answers

### Question 1: "Walk me through a cluster upgrade from v1.28 to v1.29. What checks do you do before, during, and after?"

**Expected Answer Structure:**

**Pre-Upgrade (1 week before):**
```
1. Review Kubernetes 1.29 changelog for breaking changes
2. Audit custom resources/controllers for deprecated APIs
   kubectl api-resources --verbs=list | grep v1beta1
3. Test upgrade in staging (exact infra as production)
4. Backup etcd:
   ETCDCTL_API=3 etcdctl snapshot save backup-1.28.db
5. Export cluster state:
   kubectl get all --all-namespaces -o yaml > cluster-backup.yaml
6. Notify team, prepare runbook, schedule maintenance window
```

**During Upgrade:**
```
1. Upgrade control plane first (API server, controller manager, scheduler)
   - Verify API server responds: kubectl cluster-info
   - Check etcd health: ETCDCTL_API=3 etcdctl endpoint health

2. Upgrade kubelet on nodes in waves:
   - Wave 1 (canary): 2 nodes → validate → monitor 15 min
   - Wave 2 (25%): 3 nodes → validate → monitor 10 min
   - Wave 3 (100%): remaining nodes

3. Per node:
   - Cordon (no new scheduling)
   - Drain (graceful eviction, respect PDB)
   - Upgrade binaries
   - Reboot if kernel updated
   - Uncordon (rejoin cluster)

4. While upgrading:
   - Monitor metrics: latency, error rate, pod restarts
   - Watch events: kubectl get events -A --sort-by='.lastTimestamp'
```

**Post-Upgrade (24 hours):**
```
1. Verify all nodes Ready:
   kubectl get nodes -o wide | grep -v Ready
   
2. Run integration tests:
   ./test-suite.sh
   
3. Check for deprecated API usage:
   kubectl get all --all-namespaces -o json | grep apiVersion | grep v1beta1
   
4. Verify SLOs met:
   - Error rate < 0.1%
   - P99 latency < baseline
   - Pod restart count normal
   
5. Monitor for 24 hours (catch delayed issues)
   - Data corruption (etcd)
   - Cascading failures (app incompatibility)
```

---

### Question 2: "You have 100 pods, 3 critical with minAvailable: 2. You drain a node with 20 pods. Walk through what happens."

**Expected Answer:**

```
Pod Distribution:
  Node-A (20 pods): 2 critical (minAvailable: 2), 18 normal
  Other nodes: 80 pods

Drain Sequence:
  t=0: kubectl drain node-A
  
  t=1: Evict non-critical pod #1
       Evict non-critical pod #2
       ... evict #3-#18 (normal pods)
       Pod #18 → rescheduled to node-B
       
  t=2: Ready to evict first critical pod
       BUT: PDB check: If I evict 1, only 1 critical left (violates minAvailable: 2)
       → WAIT (drain blocks)
       
  t=3: On other nodes, controller recreates critical pod (new replica)
       New critical pod starts on node-B
       Now: 2 critical running elsewhere, 1 on node-A
       
  t=4: drain resumes, evicts critical pod from node-A
       → rescheduled to node-C
       
  t=5: All 20 pods evicted from node-A
       Total: Still 3 critical pods (2 elsewhere + 1 on node-A, then node-A's gets rescheduled)
       minAvailable: 2 maintained throughout ✓

Key Point: 
  Drain respects PDB: doesn't evict pods that would violate constraint
  This ensures high availability during maintenance
```

---

### Question 3: "CoreDNS is returning NXDOMAIN for some services. Troubleshoot systematically."

**Expected Answer (Layer-by-Layer):**

```
Layer 1: Verify CoreDNS running
  kubectl get pods -n kube-system -l k8s-app=kube-dns
  Expected: 2+ pods in Running state
  If not: Why crashed? kubectl logs -n kube-system -l k8s-app=kube-dns

Layer 2: Verify Service exists
  kubectl get svc <service-name>
  If not found: Wrong namespace? kubectl get svc --all-namespaces

Layer 3: Verify Endpoints created
  kubectl get endpoints <service-name>
  If empty: Service selector doesn't match any pods
    kubectl get svc <service-name> -o yaml | grep selector
    kubectl get pods --show-labels | grep matching-label

Layer 4: Check DNS from pod
  kubectl exec <pod> -- nslookup <service-name>
  If NXDOMAIN: Continue to next step
  If times out (> 2s): Different issue (DNS slow, not missing)

Layer 5: Check DNS from CoreDNS
  kubectl exec -n kube-system <coredns-pod> -- dig <service-name> @10.96.0.10
  If fails: CoreDNS configuration issue
    kubectl logs -n kube-system <coredns-pod> | grep -i "error"

Layer 6: Check Corefile config
  kubectl get configmap coredns -n kube-system -o yaml
  Verify: "kubernetes cluster.local" plugin loaded
  Verify: upstream resolver configured

Layer 7: Check DNS cache (might be stale)
  Restart CoreDNS pod: kubectl delete pod -n kube-system <coredns-pod>
  Retry DNS query

Root causes (in order of probability):
  1. Service selector doesn't match pods (typo in labels)
  2. Service in different namespace than query
  3. CoreDNS pod crashed or not running
  4. Endpoints not created (controller issue)
  5. CoreDNS cache stale (needs restart)
  6. Network policy blocking DNS
```

---

### Question 4: "A pod can reach Service A but not Service B. Service B pods appear healthy. What layers do you check?"

**Expected Answer:**

```
Network Connectivity Debugging Flowchart:

┌─────────────────────────────────────────────┐
│ Can pod-A reach service-B DNS?              │
├─────────────────────────────────────────────┤
│ kubectl exec pod-a -- nslookup service-b   │
│ ├─ YES: Continue below                      │
│ └─ NO: DNS issue (see question 3)           │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ Does DNS return IP for service-b?           │
├─────────────────────────────────────────────┤
│ kubectl exec pod-a -- curl http://service-b:80
│ ├─ Connection refused: check port number    │
│ ├─ Timeout: network routing issue           │
│ ├─ Success: working (but question says no?) │
│ └─ Unknown host: DNS issue                  │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ Check kube-proxy iptables rules             │
├─────────────────────────────────────────────┤
│ From node (kubectl debug node/<node>):      │
│ iptables -t nat -L KUBE-SERVICES | grep service-b
│ Should show rules directing traffic to     │
│ backing pod IPs                             │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ Check Network Policy blocking traffic       │
├─────────────────────────────────────────────┤
│ kubectl get networkpol --all-namespaces    │
│ Check: Does any policy reject pod-a → service-b?
│ kubectl describe networkpol <policy>        │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ Check Service B pod listening on port       │
├─────────────────────────────────────────────┤
│ kubectl exec service-b-pod -- ss -tlnp     │
│ Should show: LISTEN 0.0.0.0:80              │
│ Not 127.0.0.1:80 (localhost only)           │
└─────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────┐
│ Check CNI networking between nodes          │
├─────────────────────────────────────────────┤
│ If pods on same node: check pod interface   │
│ kubectl exec pod-a -- ip addr show eth0    │
│ If pods on diff nodes: check node routing   │
│ kubectl debug node/<node> -- route -n       │
└─────────────────────────────────────────────┘

Most likely causes (likelihood):
  1. Service not found (DNS issue) — 40%
  2. Service port number wrong — 30%
  3. Pod not listening (app issue) — 15%
  4. Network policy blocking — 10%
  5. CNI routing broken — 5%
```

---

### Question 5: "Explain the relationship between Kubernetes Native networking and Service Mesh. When would you use each?"

**Expected Answer:**

```
Kubernetes Native Networking:
  What: Built-in DNS/Service discovery via CoreDNS + kube-proxy
  How: 
    Client pod → DNS query → CoreDNS returns Service IP
    Client pod → TCP to Service IP → kube-proxy's iptables rules
    → kube-proxy load balances to backing pod IPs
  Layers: L3/L4 (network/transport)
  Control: Via Service object, NetworkPolicy, Ingress

Service Mesh:
  What: Sidecar proxies (Envoy) in every pod intercepting traffic
  How:
    Client pod → sends traffic normally
    Envoy sidecar intercepts (iptables redirect)
    Envoy applies policies: retry logic, circuit breaking, tracing
    Envoy forwards to backing pod
  Layers: L7 (application)
  Control: Via VirtualService, DestinationRule, PeerAuthentication

Dependency Relationship:
  Service Mesh REQUIRES Kubernetes Native networking
  Both can coexist: Mesh policies wrap around native networking
  
  Example:
    1. Service A pod needs to reach Service B
    2. Kubernetes DNS resolves "service-b" → IP
    3. Service A's Envoy intercepts outbound connection
    4. Envoy applies mesh policy: "retry on failure"
    5. Envoy forwards to Service B pod
    6. Service B pod -> Envoy sidecar enforces mTLS
    7. Actual TCP goes through native kube-proxy iptables

When to use Kubernetes Native only:
  ✓ Simple architectures (< 5 microservices)
  ✓ Performance critical (latency < 1ms)
  ✓ Insufficient team expertise for mesh
  ✓ Legacy monoliths

When to add Service Mesh:
  ✓ Large polyglot (20+ services, multiple languages)
  ✓ Strict security (zero trust, mTLS)
  ✓ Complex traffic patterns (canaries, A/B testing)
  ✓ Observability critical (distributed tracing)
  ✓ Team has Kubernetes + networking expertise
```

---

### Scenario 4: Multi-Cluster Failover with Network Policy Misconfig

**Problem Statement:** 
After deploying cluster in second region (DR), failover traffic to the new cluster results in immediate cascading failures. Applications report "connection refused" to databases. Primary cluster shows 0% error rate.

**Architecture Context:**
```
Primary Cluster (us-east-1)        Secondary Cluster (us-west-1)
├─ API Service (100 req/s)        ├─ API Service (standby)
├─ Database (RDS cross-region)    ├─ Database (RDS cross-region)
├─ Cache (ElastiCache)             ├─ Cache (ElastiCache)
└─ Message Queue (shared stream)   └─ Message Queue (shared stream)

Traffic routing (DNS-based):
  Primary: 100% → us-east-1
  Failover: 100% → us-west-1 (triggered by incident)
```

**Failure Symptoms:**
```
Error logs from secondary cluster:
  2024-03-16 15:30:45 ERROR connection timeout to database:5432
  2024-03-16 15:30:46 ERROR connection refused from api pod
  2024-03-16 15:30:47 ERROR unable to reach cache service
  
Metrics:
  Error rate: 0% → 95% (instant)
  API latency: 100ms → 5000ms (timeout)
  Pod restart count: 0 → 20 (CrashLoopBackOff)
```

**Troubleshooting Process:**

```bash
#!/bin/bash
# diagnose-failover-failure.sh

CLUSTER_CONTEXT="us-west-1-prod"
kubectl config use-context $CLUSTER_CONTEXT

echo "=== Step 1: Verify pods are running ==="
kubectl get pods -n production -o wide
# Result: All pods Running, status appears healthy

echo "=== Step 2: Test pod-to-service connectivity ==="
kubectl exec <api-pod> -n production -- curl http://database:5432 -v
# Result: connection refused (TCP reset)

echo "=== Step 3: Check network policies ==="
kubectl get networkpolicies -n production
kubectl describe networkpolicy <policy-name>
# Result: Policy found, but...

echo "=== Step 4: Detailed policy inspection ==="
kubectl get networkpolicy api-to-db -o yaml
# Output shows:
# spec:
#   podSelector:
#     matchLabels:
#       app: api
#   policyTypes:
#   - Egress
#   egress:
#   - to:
#     - podSelector:
#         matchLabels:
#           app: database
#     ports:
#     - protocol: TCP
#       port: 5432

echo "=== Step 5: Check pod labels ==="
kubectl get pods -n production --show-labels
# API pods: labels app=api ✓
# Database pods: labels app=db (NOT app=database!) ✗

echo "=== Step 6: Identify label mismatch ==="
# Network policy targets: app=database
# Actual pods labeled: app=db
# Result: Policy doesn't match database pods → traffic blocked by CNI

echo "=== Root Cause Identified ==="
# Network policy created with app=database label selector
# Secondary cluster pods labeled app=db (copy-paste error in terraform)
# Policy silently rejects traffic (no matching target pods)
```

**Root Cause:**
```
Network policy has label selector: app=database
Database pods labeled as: app=db
Policy finds zero matching pods → Egress rule doesn't apply
kube-proxy allows traffic to Service IP (policy applies to pods, not Services)
But database pods reject connection (not listening? wrong port?)

Wait - re-examine...

Actually:
Network policy targets OUT GOING traffic from API pods
Selector for Egress: app=database
But database pods are labeled: app=db
So policy says: "Allow API egress to app=database pods"
No pods match → implicitly block egress to ANY pods matching different labels
BUT Service endpoint resolution still happens...

The REAL issue:
Network policy created with TYPO: app=database should be app=db
Secondary cluster terraform uses older values file with correct labels: app=db
Primary cluster has MANUAL label fix (not in terraform)

Solution:
  Fix network policy: change selector to app=db
  OR: relabel database pods to app=database (consistent with policy)
```

**Implementation Fix:**

```bash
#!/bin/bash

# Option 1: Fix the network policy
kubectl get networkpolicy api-to-db -n production -o yaml | \
  sed 's/app: database/app: db/g' | \
  kubectl apply -f -

# Option 2: Verify fix (test connectivity)
kubectl exec <api-pod> -n production -- timeout 5 curl database:5432 || echo "still failing"

# Option 3: Check if traffic flows
kubectl logs -n production <api-pod> | grep -i "database connection\|connection refused"

# Option 4: Monitor recovery
kubectl top pods -n production | grep -E "api|database"
kubectl get pods -n production -w
```

**Best Practices Applied:**
```
1. Label standardization:
   Use consistent labels across clusters
   Automate via infrastructure-as-code
   Don't allow manual label changes

2. Policy testing:
   Test network policies in staging with identical labels
   Use tools like network-policy-logger to audit policy decisions
   
3. Failover validation:
   Dry-run failover in dev/staging
   Test DNS switch doesn't introduce latency
   Verify secondary cluster labels match primary

4. Documentation:
   Document label naming convention
   Create runbook for failover (includes label validation step)
```

---

### Scenario 5: Persistent Volume Mount Failure During Node Drain

**Problem Statement:**
Initiated planned node drain for maintenance. Pod with persistent volume entered "Pending" state and never rescheduled to another node. Persistent volume (EBS) stuck in "Bound" but not available to any pod.

**Architecture Context:**
```
Cluster: 3 nodes (node-1, node-2, node-3)
Persistent Volume (StatefulSet): EBS volume (gp3, 10GB)
Application: Database pod using EBS for /data

Deployment: StatefulSet with 1 replica
  Pod: database-0
  Volume: ebs-data-vol
  Mount: /var/lib/mysql
```

**Failure Sequence:**

```
t=0:   kubectl drain node-1 --ignore-daemonsets
t=1:   Pod database-0 receives eviction notice
t=5:   Pod in "Terminating" state
t=15:  Pod deleted from node-1
t=20:  StatefulSet controller attempts to recreate pod
t=25:  Pod created on node-2 (where capacity available)
t=30:  Pod attempts to mount EBS volume
t=35:  Mount FAILS: "failed to attach volume: timeout"
t=60:  Pod in CrashLoopBackOff
       Volume stuck: "Bound" (shows as attached, but inaccessible)
```

**Diagnosis Process:**

```bash
#!/bin/bash
# troubleshoot-pv-mount-failure.sh

echo "=== Step 1: Check PVC status ==="
kubectl get pvc -n production
# Output: ebs-data-vol | Bound | pvc-xxx | standard

echo "=== Step 2: Check PV status ==="
kubectl get pv | grep ebs-data-vol
# Output: pvc-xxx | 10Gi | RWO | Bound | namespace/ebs-data-vol

echo "=== Step 3: Describe PVC for events ==="
kubectl describe pvc ebs-data-vol -n production
# Events:
#   WARNINGFailedAttachVolume: timeout waiting for volume attach
#   pod failed to attach EBS volume

echo "=== Step 4: Check pod events ==="
kubectl describe pod database-0 -n production
# Events:
#   FailedScheduling: 1 node(s) had volume node affinity conflict
#   FailedAttachVolume: timeout

echo "=== Step 5: Identify AWS issue ==="
# EBS volume exists (verified in AWS console)
# BUT: Associated with node-1 (original node-1)
# Pod scheduled to node-2, but EBS attached to node-1
# AWS: cannot detach volume (still has lingering attachment)

echo "=== Step 6: Check AWS EC2 attachment state ==="
aws ec2 describe-volumes --volume-ids vol-xxx --region us-east-1 | \
  jq '.Volumes[0].Attachments'
# Output:
# "Device": "/dev/sdb"
# "InstanceId": "i-node1id"  ← Still attached to OLD node
# "State": "attached" (even though instance is gone!)
# "Time": "2024-03-16T15:00:00+00:00"

echo "=== Step 7: Manual intervention needed ==="
# EBS volume attachment entry orphaned
# Solution: Force detach from AWS (Kubernetes can't resolve this)
aws ec2 detach-volume \
  --volume-id vol-xxx \
  --force \
  --region us-east-1

# After detach, pod should auto-retry attach
echo "=== Step 8: Verify recovery ==="
kubectl describe pvc ebs-data-vol -n production
# Should show: "SuccessfullyAttached" event
```

**Root Cause Analysis:**

```
Causal Chain:
  1. Node drain initiates pod eviction
  2. Pod terminated without proper volume cleanup
  3. EBS attachment lingered (AWS bug or timing issue)
  4. StatefulSet recreates pod on different node
  5. Kubernetes requests EBS attach to new node
  6. AWS returns: "volume already attached"
  7. Attach fails (can't have one volume on two nodes simultaneously)
  8. Pod stuck pending forever

Why it happened:
  - drain didn't wait for volume detach before killing pod
  - EBS detach handler timed out or didn't trigger
  - AWS didn't clean up orphaned attachment
```

**Prevention & Implementation:**

```yaml
# StatefulSet configuration preventing issue:
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
spec:
  serviceName: database
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      # Add pod disruption budget
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: database
            topologyKey: kubernetes.io/hostname
      
      # Adequate termination grace period for volume cleanup
      terminationGracePeriodSeconds: 300  # 5 min to unmount/detach
      
      # Persistent volume claim
      volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          accessModes: [ "ReadWriteOnce" ]
          storageClassName: ebs-gp3
          resources:
            requests:
              storage: 10Gi
      
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
```

**Best Practices:**

```
1. Volume cleanup on node drain:
   - Ensure terminationGracePeriodSeconds ≥ 5 minutes
   - For EBS volumes, Kubernetes needs time to:
     a) Signal pod termination (SIGTERM)
     b) Application gracefully shutdown
     c) Filesystem unmount
     d) AWS EBS detach (can take 1-2 minutes)

2. Pre-drain validation:
   kubectl get pvc -A  # Ensure volumes healthy
   kubectl get pv -A   # Check attachment status (AWS console)

3. Node drain best practices:
   kubectl drain $NODE --ignore-daemonsets \
     --delete-emptydir-data \
     --timeout=10m  # Adequate timeout for large volumes
   
4. Monitoring volumes:
   - Alert on VolumeAttachmentStatus != "Attached"
   - Monitor EBS attachment attempts/failures
   - Track PVC/PV status changes
```

---

### Scenario 6: Cascading Failure: CoreDNS Restart Triggers Outage

**Problem Statement:**
Updated CoreDNS configuration and restarted pods. Within 10 seconds, 50% of pods unable to reach any external services. Application error rates spike to 95%. Incident lasts 8 minutes until automatic rollout reversal.

**Architecture Context:**
```
CoreDNS:        2 replicas, HA setup
Cache TTL:      30 seconds (internal), 300 seconds (external)
Pod DNS config: 127.0.0.11:53 (kubelet's DNS resolver)

Deployment:
  - web (50 pods)
  - api (30 pods)
  - worker (20 pods)
  - coredns (2 pods) - CRITICAL
```

**Failure Timeline:**

```
t=0:00   kubectl set image deployment/coredns \
           coredns=coredns:1.10.1 -n kube-system
         Pod 1 terminating
         Pod 2 still serving

t=0:10   Pod 1 fully down
         Pod 2 receiving ALL DNS traffic (50K req/s spike)
         Pod 2 CPU: 200% (overloaded)
         
t=0:15   Pod 1 new replica starting (pulling image)
         
t=0:30   Pod 1 ready, serving traffic
         But: Pod 1 cache empty (no prior queries cached)
         All queries → upstream resolver (8.8.8.8)
         
t=0:45   Upstream resolver timeout (overwhelmed)
         DNS queries fail silently (timeout)
         Pods retry DNS → exponential backoff
         
t=1:00   Cascade effect:
         - Pod requires DNS to reach database
         - DNS fails → connection error
         - Pod retries
         - All 100 pods retrying simultaneously
         - Load on upstream resolver × 100
         
t=1:30   Web pods unable to reach external APIs
         Application logic: "if external API unreachable, fail request"
         Error rate: 95%
         
t=8:00   Automated rollout revert triggers
         CoreDNS reverted to previous version
         Pods get fresh DNS responses from restored cache
         Error rate recovers → 0%

Total outage: 8 minutes
Customer impact: Significant (95% error rate for 8 minutes)
```

**Root Cause:**

```
Immediate cause:
  - CoreDNS rolling update with only 2 replicas
  - No rolling update strategy (killed old pod immediately)
  - New pod started with empty cache
  - Single pod couldn't handle load

Underlying causes:
  - No PDB for CoreDNS (was allowed to evict both?)
  - No CPU limits preventing overload
  - Upstream resolver not designed for spike
  - Application not handling DNS degradation
```

**Prevention & Remediation:**

```yaml
# Correct CoreDNS deployment (HA):
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
spec:
  replicas: 3  # ← Increased to 3 (was 2)
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1         # Add 1 pod, don't kill old until new ready
      maxUnavailable: 0   # Never drop below 3 pods
  template:
    spec:
      # Critical pod requires guaranteed resources
      priorityClassName: system-cluster-critical
      
      containers:
      - name: coredns
        image: coredns:1.10.1
        resources:
          requests:
            cpu: 150m      # Ensure allocation
            memory: 100Mi
          limits:
            cpu: 200m      # Prevent runaway
            memory: 200Mi
        # Long deployment to ensure cache warm
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 5"]  # Drain existing queries
---
# PodDisruptionBudget protecting CoreDNS
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: coredns-pdb
  namespace: kube-system
spec:
  minAvailable: 2  # Always keep 2+ pods running
  selector:
    matchLabels:
      k8s-app: kube-dns
---
# Application-side resilience (retry DNS)
apiVersion: v1
kind: ConfigMap
metadata:
  name: dns-retry-config
data:
  dns_retry_count: "3"
  dns_retry_delay: "100ms"
  dns_timeout: "2s"
```

**Operational Process:**

```bash
#!/bin/bash
# safe-coredns-update.sh

echo "=== Pre-update checks ==="
kubectl get pdb -n kube-system  # Verify PDB exists
kubectl describe pdb coredns-pdb -n kube-system
# Should show: minAvailable: 2

echo "=== Monitor CoreDNS during update ==="
kubectl rollout status deployment/coredns -n kube-system \
  --timeout=5m &
ROLLOUT_PID=$!

kubectl logs -n kube-system -l k8s-app=kube-dns -f &
LOGS_PID=$!

# Terminal 2: Monitor DNS performance
watch -n 1 'kubectl top pod -n kube-system -l k8s-app=kube-dns'

# Terminal 3: Monitor application error rate
watch -n 1 'curl http://prometheus:9090/api/v1/query?query=rate(errors_total[1m])'

echo "=== Perform rolling update ==="
kubectl set image deployment/coredns \
  coredns=coredns:1.10.1 \
  -n kube-system \
  --record

# Wait for completion
wait $ROLLOUT_PID
echo "=== Update complete ==="

# Monitor for 5 minutes post-update
echo "=== Post-update validation (5 minutes) ==="
sleep 300

# Check metrics
ERROR_RATE=$(curl -s http://prometheus:9090/api/v1/query?query='rate(errors_total[5m])' | jq '.data.result[0].value[1]')
echo "Current error rate: $ERROR_RATE"

if (( $(echo "$ERROR_RATE > 0.05" | bc -l) )); then
  echo "ERROR RATE HIGH! Rolling back..."
  kubectl rollout undo deployment/coredns -n kube-system
else
  echo "✓ Update successful"
fi
```

**Lessons Learned:**

```
1. Critical cluster components (CoreDNS, etcd, kube-proxy):
   - Always use PodDisruptionBudget
   - Keep minimum 3 replicas (tolerates 1 failure)
   - Use maxUnavailable: 0 in rolling updates

2. Cache-heavy services:
   - Consider cache pre-warming on pod start
   - Monitor cache hit rate during failover
   - Configure upstream resolver redundancy

3. Application resilience:
   - Implement DNS retry logic (exponential backoff)
   - Don't cascade failures (DNS failure ≠ request failure)
   - Cache DNS results locally (TTL-aware)

4. Monitoring during updates:
   - Watch error rates in real-time
   - Set low alert thresholds (detect issues in seconds)
   - Have pre-tested rollback ready
```

---

## Additional Interview Questions

### Question 6: "Describe a time when an upgrade caused unexpected problems. How would you prevent it?"

**Expected Answer:**

```
Real scenario: Kubernetes 1.25 upgrade introduced stricter pod security policy defaults.
Pods without compatible securityContext failed to schedule.

What happened:
  1. Upgraded control plane without testing against actual workloads
  2. 48 hours later, rolling out new pods failed
  3. Took 2 hours to diagnose (security policy audit logs not enabled)
  4. Fix: Added securityContext to 30+ deployments

Prevention approach I'd implement:
  - Pre-upgrade API audit: scan all manifests for deprecated features
    kubectl get all -A -o json | jq '[.items[] | select(.apiVersion | contains("beta"))]'
  
  - Test upgrade in staging (must have representative workloads)
    - Clone prod manifests to staging
    - Run prod workload patterns
    - Watch for 24 hours pre-upgrade validation
  
  - API deprecation tracking (automation):
    - Run deprecation scanner in CI/CD
    - Flag use of v1beta1, alpha APIs
    - Create tickets for remediation before upgrade
  
  - Infrastructure as code (IaC):
    - All cluster configs in git
    - Pre-upgrade: dry-run apply against new version
    - Catch issues before production impact
  
  - Post-upgrade process:
    - Integration tests on all critical paths
    - Canary upgrade: 5% nodes → monitor 30 min → 100%
    - Keep previous cluster for rollback (24-48 hours)
    - SRE on-call for 48 hours post-upgrade
```

---

### Question 7: "How would you optimize cluster network for 500 services at scale? What are the bottlenecks?"

**Expected Answer:**

```
Bottlenecks I've encountered:

1. DNS Bottleneck (CoreDNS)
   Problem: 500 services = potential 50K+ DNS queries/sec
   - Each pod queries service discovery N times (creation, restarts, app retries)
   - Default 2 CoreDNS pods can't sustain > 20K QPS
   - No query caching at application level
   
   Solutions applied:
   - Increase CoreDNS replicas: 2 → 4 (or HPA: min=4, max=10)
   - Enable aggressive caching (TTL: external=300s, internal=30s)
   - Implement client-side DNS caching (app instrumentation)
   - Configure upstream resolver: 2-3 redundant resolvers
   - Monitor: coredns_dns_request_duration_seconds (P99 < 100ms)

2. kube-proxy Bottleneck (Service routing)
   Problem: iptables rules grow exponentially
   - 500 services × 10 replicas = 5000 iptables rules per node
   - Rule lookup time O(rules) = slow connection establishment
   - Conntrack table exhaustion (tracking 100K+ connections)
   
   Solutions applied:
   - Switch from iptables → IPVS (O(1) lookup vs O(n))
     kube-proxy argument: --proxy-mode=ipvs
   - Tune kernel: net.netfilter.nf_conntrack_max = 1M+
   - Monitor conntrack utilization, alert at 80%
   - Consider Cilium CNI (eBPF replaces both)

3. Network Policy Bottleneck
   Problem: Evaluating 500 policies on every connection
   - If using default-deny model, policies applied per pod
   - Calico evaluates all policies (can be slow for 10K+ rules)
   - Default policies on every namespace = 500 evaluations/connection
   
   Solutions applied:
   - Organize policies by namespace (isolation)
   - Use label selectors efficiently (avoid wildcard matches)
   - Monitor: network_policy_evaluation_duration_ms
   - Dedicated network policy nodes (large clusters)
   - Consider Cilium (eBPF evaluation, much faster)

4. etcd Bottleneck (State store)
   Problem: 500 services = thousands of watch channels
   - Each service creates watch on endpoints (Kubernetes list-watch API)
   - Controllers watch all resources
   - Heavy etcd load during updates
   
   Solutions applied:
   - Etcd cluster: 3 → 5 members for large clusters
   - Monitor etcd commit duration (should be < 100ms)
   - Implement etcd resource quotas (prevent runaway)
   - Use client-side caching (reduce etcd loads)

Optimization architecture:
```
```
┌─────────────────────────────────────────┐
│ Application Layer (500 services)        │
├─────────────────────────────────────────┤
│ Client-side DNS caching (TTL=30s)       │
│ Connection pooling (multiplexing)       │
│ gRPC with keepalive (vs frequent DNS)   │
└──────────────┬──────────────────────────┘
               ↓ (reduced DNS queries 50%)
┌─────────────────────────────────────────┐
│ Pod Network Layer                       │
├─────────────────────────────────────────┤
│ CoreDNS (4→10 pods, HPA enabled)        │
│ Cache: 30s internal, 300s external      │
│ Upstream: 3x resolvers (failover)       │
└──────────────┬──────────────────────────┘
               ↓ (resolved services)
┌─────────────────────────────────────────┐
│ Node Network Layer                      │
├─────────────────────────────────────────┤
│ kube-proxy in IPVS mode (not iptables)  │
│ Cilium CNI (eBPF bypass for high perf)  │
│ Tuned kernel: conntrack, buffers        │
└──────────────┬──────────────────────────┘
               ↓ (optimized routing)
┌─────────────────────────────────────────┐
│ Service Layer                           │
├─────────────────────────────────────────┤
│ Network policies (cilium-specific)      │
│ Service mesh (Cilium for L7 if needed)  │
│ Endpoint health checks (ready pods only)│
└─────────────────────────────────────────┘
```

Monitoring key metrics:
  - DNS query latency (P99 < 100ms)
  - Service connection latency (< 50ms)
  - iptables/IPVS rule count (track growth)
  - Conntrack utilization (< 80%)
  - etcd commit duration (< 100ms)
```

---

### Question 8: "Explain your experience with service mesh. When would you NOT recommend it?"

**Expected Answer:**

```
Experience: Deployed Istio v1.12 → v1.15 in production (100+ microservices)

What I learned about service mesh:

Initial expectations (Before):
  - Instant observability
  - Automatic resilience patterns
  - Transparent encryption between services
  
Reality (After):
  - Added 200MB RAM per pod (sidecar overhead)
  - Increased deployment complexity significantly
  - New failure modes (sidecar crashes, mTLS issues)
  - Debugging became harder (traffic goes through proxy)

When I'd recommend service mesh:
  ✓ 20+ microservices across 3+ languages
  ✓ Distributed team (need consistent patterns)
  ✓ Complex traffic routing (canaries, A/B tests)
  ✓ Mature Kubernetes practice (team experienced)
  ✓ Security requirements (zero-trust, mTLS)
  
When I would NOT use service mesh:
  ✗ < 5 microservices (overkill, add complexity)
  ✗ All services single language (implement patterns in app)
  ✗ Performance critical (< 1ms latency). Sidecars add 5-15ms
  ✗ Early-stage startup (cognitive overhead too high)
  ✗ Team lacks Kubernetes expertise (dangerous combination)
  ✗ Legacy monolith (not cloud-native ready)

Real example (my mistake):
  - Started Istio for 8 microservices
  - Felt forced due to maintenance burden
  - Spent 3 months managing sidecar issues
  - Reverted after 6 months (not worth complexity)
  - Implemented resilience patterns in application instead
  
Lesson: Service mesh isn't always the right answer

Alternative approaches:
  1. Application-level patterns (Resilience4j, Polly)
  2. Ingress controller for traffic routing
  3. Manual istio (just for critical services)
  4. Lightweight mesh (Linkerd, lighter than Istio)
```

---

### Question 9: "Compare backup strategies for etcd. What's your recommendation for a production cluster?"

**Expected Answer:**

```
Comparison of etcd backup strategies:

┌──────────────────────────────────────────────────────────────┐
│ Strategy 1: Point-in-Time Snapshot (Full Backup)            │
├──────────────────────────────────────────────────────────────┤
│ Frequency: Hourly                                            │
│ Mechanism: etcdctl snapshot save (while running)             │
│ Storage: S3 + local NFS                                      │
│ Recovery time: 15-30 minutes                                 │
│ Pros:                                                        │
│  ✓ Simple, reliable                                          │
│  ✓ Tested & proven approach                                  │
│  ✓ Point-to-point recovery (restore to any timestamp)       │
│ Cons:                                                        │
│  ✗ Space inefficient (full snapshot each time)              │
│  ✗ Backup window (if backups fail, lose 1 hour data)        │
│ Risk: 1 hour data loss if incident at end of backup window  │
│ Cost: ~10GB/month storage (for hourly backups)              │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Strategy 2: Incremental WAL + Snapshots (Hybrid)            │
├──────────────────────────────────────────────────────────────┤
│ Frequency: Snapshot every 6 hours + WAL every 5 min         │
│ Mechanism: WAL (write-ahead log) tracks all changes          │
│ Storage: S3 with lifecycle policies                          │
│ Recovery time: 5 minutes (restore snapshot + replay WAL)    │
│ Pros:                                                        │
│  ✓ Low RPO (recover to within 5 min of incident)            │
│  ✓ Space efficient (only deltas stored)                      │
│  ✓ Fast point-in-time recovery                              │
│ Cons:                                                        │
│  ✗ More complex (manage snapshots + WAL)                    │
│  ✗ WAL can get large (100MB+ per hour at scale)             │
│  ✗ Requires careful testing (WAL replay bugs)               │
│ Risk: 5 minute data loss maximum                             │
│ Cost: ~3GB/month storage (compressed WAL + snapshots)       │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Strategy 3: Continuous Replication (Cluster-level)          │
├──────────────────────────────────────────────────────────────┤
│ Mechanism: 3-member etcd cluster across 3 AZs (quorum)     │
│ Recovery: Automatic (if 1 member fails)                     │
│ Risk: Zero data loss (quorum-based)                         │
│ RPO: 0 (no data loss, fully replicated)                     │
│ RTO: < 1 minute (member rejoins automatically)              │
│ Pros:                                                        │
│  ✓ Highest availability (tolerates 1 member loss)           │
│  ✓ Zero data loss                                            │
│  ✓ Automatic recovery                                        │
│ Cons:                                                        │
│  ✗ Requires 3+ nodes (infrastructure cost)                  │
│  ✗ Doesn't protect against logical corruption               │
│  ✗ All members must be healthy (quorum risk)                │
│ Risk: Partial loss if majority members fail simultaneously  │
│ Cost: 3x etcd node cost                                     │
└──────────────────────────────────────────────────────────────┘

My Recommendation (Production):

Hybrid approach:
  1. Maintain 3-member HA etcd cluster (quorum/redundancy)
     - Protects against instance failures
     - Achieves zero data loss under normal circumstances
  
  2. Add Point-in-Time snapshots (hourly to S3)
     - Addresses logical corruption scenarios
     - Protects against operator mistakes
     - Enables point-in-time recovery
  
  3. Test restore procedure (monthly)
     - Ensures snapshots actually work
     - Find issues before real incident
     - Update runbook if needed
  
  4. Monitor backup freshness
     - Alert if no backup in 90 minutes
     - Alert if restore test fails
     - Alert if cluster members unhealthy

Implementation:
```
```yaml
# etcd cluster backup cronjob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: kube-system
spec:
  schedule: "0 * * * *"  # Hourly
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: etcd:3.5
            command:
            - /bin/sh
            - -c
            - |
              ETCDCTL_API=3 etcdctl \
                --endpoints=https://etcd:2379 \
                --cacert=/etc/etcd/pki/ca.crt \
                --cert=/etc/etcd/pki/server.crt \
                --key=/etc/etcd/pki/server.key \
                snapshot save /backups/etcd-$(date +%s).db
              
              # Upload to S3
              aws s3 cp /backups/ s3://cluster-backups/etcd/ --recursive
              
              # Cleanup old backups (retain 30 days)
              aws s3 rm s3://cluster-backups/etcd/ --recursive \
                --exclude "*" \
                --include "etcd-*" \
                --older-than 30
            volumeMounts:
            - name: etcd-certs
              mountPath: /etc/etcd/pki
            - name: backup-storage
              mountPath: /backups
          volumes:
          - name: etcd-certs
            secret:
              secretName: etcd-certs
          - name: backup-storage
            emptyDir: {}
          restartPolicy: OnFailure
```

Validation procedure (monthly):
```bash
#!/bin/bash
# test-etcd-restore.sh

# 1. Get latest backup
BACKUP=$(aws s3 ls s3://cluster-backups/etcd/ | tail -1 | awk '{print $4}')
aws s3 cp s3://cluster-backups/etcd/$BACKUP ./test-restore.db

# 2. Perform restore in test environment
ETCDCTL_API=3 etcdctl snapshot restore \
  --data-dir=/var/lib/etcd-test \
  ./test-restore.db

# 3. Verify restored data
# Check number of keys, critical resources present
etcdctl --data-dir=/var/lib/etcd-test \
  get "" --prefix | wc -l

# 4. Alert if restore failed
if [ $? -ne 0 ]; then
  echo "ALERT: etcd restore test failed!"
  # Page on-call engineer
fi
```

This approach balances:
  - Availability (3-member cluster)
  - Data protection (point-in-time saves)
  - Operational simplicity (automated)
  - Cost effectiveness
```

---

### Question 10: "You inherit a cluster with undocumented networking. How would you assess & improve it?"

**Expected Answer:**

```
Assessment approach (what I've done):
  
Phase 1: Discovery (1 week)
  1. Map existing architecture:
     kubectl get all -A -o json | jq ... (export all manifests)
     kubectl get networkpolicy -A (audit policies)
     kubectl describe service --all-namespaces (service overview)
     
  2. Trace traffic flow:
     Pick critical service → where does traffic come from?
     kubectl logs <pod> | grep "incoming" (client IPs)
     tcpdump on pod → identify upstream services
     
  3. Identify bottlenecks:
     kubectl describe nodes (resource utilization)
     kubectl logs -n kube-system -l k8s-app=kube-proxy (errors?)
     kubectl logs -n kube-system -l k8s-app=kube-dns (DNS issues?)
     
  4. Chart current state (ASCII diagram):
     ┌─ External Traffic
     │
     ├─ Ingress Controller (how many replicas?)
     │  └─ Routes to Services
     │     └─ How are Endpoints discovered?
     │
     ├─ Internal Service-to-Service (headless services? ClusterIP?)
     │
     ├─ Network Policies (default-deny or allow-all?)
     │
     └─ External Egress (how do pods reach outside?)

Phase 2: Documentation (2 weeks)
  1. Create network diagram (draw.io):
     - Service dependencies
     - DNS flow
     - Network policies (if any)
     - Ingress paths
  
  2. Build traffic matrix:
     Service A → Service B (protocol, port)
     Service B → Service C
     (identify unused paths, unexpected flows)
  
  3. Document current state:
     - DNS strategy (CoreDNS replicas, cache config)
     - Service mesh status (none? partial? full?)
     - CNI plugin (which one? version?)
     - Network policies (how enforced?)

Phase 3: Gap Analysis (2 weeks)
  1. Security gaps:
     Network policies exist? 
     If not: no microsegmentation
     If yes: Does default-deny exist?
     Are unused paths blocked?
  
  2. Reliability gaps:
     CoreDNS resilient?
     Service mesh for resiliency?
     Egress failover?
  
  3. Observability gaps:
     Can you trace request path?
     Are network policies being enforced?
     Can you detect DNS issues?

Phase 4: Improvement Plan (prioritize)
  
Priority 1 (Immediate - safety):
    ☐ Add network policies (default-deny + explicit allow)
    ☐ Test policies (audit mode first, then enforce)
    ☐ Document policy intent per team
  
Priority 2 (Short-term - reliability):
    ☐ Ensure CoreDNS HA (3+ replicas, PDB)
    ☐ Add PodDisruptionBudgets (prevent cascading failures)
    ☐ Monitor DNS latency, service connectivity
  
Priority 3 (Medium-term - performance):
    ☐ Optimize kube-proxy (IPVS mode)
    ☐ Add service mesh if 20+ services (Cilium or Istio)
    ☐ Implement client-side DNS caching
  
Priority 4 (Long-term - modernization):
    ☐ Migrate to declarative networking (infrastructure-as-code)
    ☐ Implement GitOps for network configs
    ☐ Establish network policy framework

Implementation example (network policies):
```
```yaml
# Step 1: Enable audit mode (log, don't enforce)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: audit-all-traffic
spec:
  podSelector: {}  # All pods
  policyTypes:
  - Ingress
  - Egress
  # Empty rules = audit (no actual blocking yet)

# Step 2: After 2 weeks of audit logs, add default-deny
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  # Empty rules = deny all

# Step 3: Add specific allow rules based on audit data
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
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
```

Validation & Testing:
```bash
# Post-policy deployment verification
kubectl exec <web-pod> -- curl <api-service>  # Should work ✓
kubectl exec <other-pod> -- curl <api-service>  # Should fail ✓

# Monitor policy enforcement
kubectl logs -l k8s-app=calico-node | grep policy_decision

# Check network policy metrics
curl prometheus:9090/api/v1/query?query='network_policy_blocks_total'
```

Outcome (after 3 months):
  - Documented network architecture
  - Default-deny policies with explicit allow rules
  - 95%+ service-to-service connectivity confirmed
  - Zero unintended traffic flows
  - Security posture significantly improved
  - Team understands network dependencies
  - Process established for future network policy changes
```

---

### Question 11: "Design a resilient, maintainable Kubernetes network architecture for 1000+ microservices."

**Expected Answer:**

```
Design Principles:
  1. Defense in depth (multiple layers of resilience)
  2. Observability first (understand before optimizing)
  3. Progressive enforcement (audit → warn → block)
  4. Operator experience (team can maintain this)

Proposed Architecture:

┌─────────────────────────────────────────────────────────────┐
│                     Ingress Layer (Edge)                     │
├─────────────────────────────────────────────────────────────┤
│ - Load balancer (3+ replicas across AZs)                    │
│ - DDoS protection tier                                       │
│ - TLS termination (managed certificates)                    │
│ - Rate limiting (1000 req/s per client)                     │
│ - Request filtering (block obvious attacks)                 │
└──────────────┬──────────────────────────────────────────────┘
               │ (authenticated traffic)
┌──────────────┴──────────────────────────────────────────────┐
│                    Service Mesh Layer (L7)                   │
├─────────────────────────────────────────────────────────────┤
│ - Cilium or Istio (for observability + security)            │
│ - mTLS enforcement (pod-to-pod encrypted)                   │
│ - Observability: request tracing, metrics                   │
│ - Policies: L7 authorization, rate limiting                 │
│ - Canary deployment support                                 │
│ - Circuit breaking (prevent cascades)                       │
└──────────────┬──────────────────────────────────────────────┘
               │ (encrypted, observably-tracked traffic)
┌──────────────┴──────────────────────────────────────────────┐
│                 Network Policy Layer (L3/L4)                 │
├─────────────────────────────────────────────────────────────┤
│ - Default-deny at namespace level                           │
│ - Pod-level microsegmentation                               │
│ - Egress policies (which services can talk to external?)    │
│ - Layer 4 filtering (port/protocol level)                   │
│ - Audit mode for 2-weeks, then enforce                      │
└──────────────┬──────────────────────────────────────────────┘
               │ (explicitly allowed, policy-based)
┌──────────────┴──────────────────────────────────────────────┐
│            CoreDNS Layer (Service Discovery)                 │
├─────────────────────────────────────────────────────────────┤
│ - 4-6 CoreDNS replicas (HPA: min=4, max=10)                │
│ - Headless services (for stateful: databases, queues)       │
│ - DNS TLS (for privacy)                                      │
│ - Split DNS: internal (.cluster.local) + external           │
│ - Multiple upstream resolvers (failover)                    │
│ - Client-side caching (reduce CoreDNS load)                 │
│ - PDB: minAvailable: 2 (never below 2 pods)                │
└──────────────┬──────────────────────────────────────────────┘
               │ (service names resolved consistently)
┌──────────────┴──────────────────────────────────────────────┐
│            Data Plane (kube-proxy/IPVS)                      │
├─────────────────────────────────────────────────────────────┤
│ - kube-proxy: IPVS mode (not iptables, better scale)       │
│ - Cilium eBPF (bypass kernel entirely for performance)      │
│ - Conntrack optimization (1M+ tracking)                     │
│ - MTU tuning (avoid fragmentation)                          │
│ - Node affinity for data locality                           │
└──────────────┬──────────────────────────────────────────────┘
               │ (efficient, low-latency routing)
┌──────────────┴──────────────────────────────────────────────┐
│              Monitoring & Observability                      │
├─────────────────────────────────────────────────────────────┤
│ - Prometheus: network metrics                                │
│ - Jaeger: distributed tracing                                │
│ - Cilium Hubble: eBPF-based network observability           │
│ - Network policy audit logs                                  │
│ - Service mesh metrics (latency, errors, throughput)        │
│ - Custom alerts: DNS latency, policy violations, errors     │
└─────────────────────────────────────────────────────────────┘

Resilience Mechanisms:

Failure Scenario 1: CoreDNS pod crashes
  Impact without mitigation: Pods can't resolve services (5-30s)
  Mitigation: 4 replicas + auto-restart
  Recovery time: < 5 seconds

Failure Scenario 2: Node network partition
  Impact: Traffic to that node fails temporarily
  Mitigation: Pod anti-affinity spreads replicas
            PDB ensures min replicas elsewhere
  Recovery time: < 30 seconds (pod reschedules)

Failure Scenario 3: Upstream DNS resolver down
  Impact: External DNS lookups timeout
  Mitigation: Multiple upstream resolvers
            Client-side retry (app responsibility)
  Recovery time: < 2 seconds (failover to next resolver)

Failure Scenario 4: Service mesh control plane issue
  Impact: New policy changes don't apply
  Mitigation: Data plane (iptables/eBPF) still works
            Mesh is optimization, not required for traffic flow
  Recovery time: Control plane auto-recovery (5-10 min)

Scalability Metrics:

At 1000 microservices:
  - Service density: 3 services/team × 333 teams
  - Network policies: 2000+ policies (default-deny + per-team rules)
  - Endpoints per service: 10 replicas × 1000 = 10K Endpoints
  - Aggregate DNS QPS: 50K QPS (5 QPS × 10K pods)
  - CoreDNS replicas needed: 4-6 (20K QPS per replica)
  - kube-proxy iptables rules: 15K+ (could be 50K+)
  - Switch to IPVS/eBPF to handle scale

Implementation Timeline:

Week 1-2: Foundation
  - Deploy CoreDNS HA (3→6 replicas)
  - Implement network policies (audit mode)
  - Add observability (Prometheus, Jaeger)

Month 1: Enforcement
  - Graduate network policies from audit → enforce
  - Deploy Cilium for eBPF + observability
  
Month 2-3: Optimization
  - Fine-tune policies based on audit data
  - Optimize upstream resolvers
  - Implement client-side caching
  
Month 3-4: Service Mesh
  - Deploy Cilium service mesh or Istio
  - Add mTLS enforcement
  - Implement canary deployment pipelines

Maintenance Model:

Teams own their policies:
  - Team A: Define allow rules for their services
  - Team B: Define egress rules for external APIs
  - Platform team: Enforce defaults + audit

Policy review process:
  - Quarterly: Audit unused rules
  - Monthly: Review violations & update policies
  - Weekly: New service onboarding (add to policies)

Documentation:
  - Network diagram (keep updated)
  - Policy intent (why does this rule exist?)
  - Runbooks (recover from network failures)
  - Team-specific guides (how to debug network issues)
```

---

### Question 12: "What metrics/alerts would you set up for Kubernetes networking?"

**Expected Answer:**

```
Critical Metrics (alert immediately):

┌──────────────────────────────────────────────┐
│ Layer 1: DNS/Service Discovery               │
├──────────────────────────────────────────────┤
│ 1. coredns_dns_request_duration_seconds     │
│    Alert: P99 > 100ms (internal) or > 500ms │
│    Reason: DNS slow = app latency spike     │
│                                              │
│ 2. coredns_dns_request_total (by response)  │
│    Alert: NXDOMAIN rate > 1%               │
│    Reason: Services disappearing?           │
│                                              │
│ 3. endpoint_count (per service)             │
│    Alert: Endpoint count = 0 for 2 min    │
│    Reason: All backing pods down?           │
│                                              │
│ 4. pod_dns_query_latency (app instrumented)│
│    Alert: P95 > 200ms                      │
│    Reason: App-level DNS caching bad?      │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ Layer 2: Service Connectivity                │
├──────────────────────────────────────────────┤
│ 5. kube_service_status_load_balancer_...   │
│    Monitor: Are services reachable?         │
│    Alert: Service shows 0 endpoints         │
│                                              │
│ 6. envoy_cluster_upstream_cx_total         │
│    Monitor: Connection establishment time   │
│    Alert: Failed connections > 1%          │
│                                              │
│ 7. http_request_total (by service)         │
│    Monitor: Traffic per service             │
│    Alert: Sudden traffic shift               │
│                                              │
│ 8. tcp_connection_count (by pod)            │
│    Monitor: Connection leaks                │
│    Alert: Connections grow unbounded        │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ Layer 3: Network Policies                    │
├──────────────────────────────────────────────┤
│ 9. network_policy_enforcement_actions       │
│    Monitor: Policy blocks/allows            │
│    Alert: Unexpected allow/block patterns   │
│                                              │
│ 10. network_policy_audit_total              │
│     Monitor: Policy violations in audit mode│
│     Alert: High violation rate (setup issue)│
│                                              │
│ 11. cilium_policy_evaluation_duration_ms    │
│     Monitor: Policy evaluation speed         │
│     Alert: > 100ms (slow policies)          │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ Layer 4: Infrastructure                      │
├──────────────────────────────────────────────┤
│ 12. node_hostname_mtu                        │
│     Monitor: MTU consistency across nodes   │
│     Alert: MTU mismatch (fragmentation risk)│
│                                              │
│ 13. net_conntrack_count / conntrack_max     │
│     Monitor: Connection tracking saturation │
│     Alert: > 80% utilization                │
│                                              │
│ 14. etcd_commit_duration_seconds             │
│     Monitor: etcd latency                    │
│     Alert: P99 > 100ms (service changes slow)
│                                              │
│ 15. kubelet_network_plugin_operations_total │
│     Monitor: CNI add/remove operations       │
│     Alert: High failure rate                │
└──────────────────────────────────────────────┘
```

Prometheus rules (example):

```yaml
groups:
  - name: kubernetes-networking
    interval: 30s
    rules:
    
    # DNS latency alert
    - record: coredns:latency_p99:5m
      expr: |
        histogram_quantile(0.99, 
          rate(coredns_dns_request_duration_seconds_bucket[5m]))
    
    - alert: CoreDNSLatencyHigh
      expr: coredns:latency_p99:5m > 0.1
      for: 2m
      labels:
        severity: warning
        component: dns
      annotations:
        summary: "CoreDNS P99 latency {{ $value }}s"
        runbook: "https://wiki/runbooks/coredns-latency-high"
    
    # NXDOMAIN spike (services disappearing)
    - record: coredns:nxdomain_rate:5m
      expr: |
        rate(coredns_dns_request_total{rcode="NXDOMAIN"}[5m]) /
        rate(coredns_dns_request_total[5m])
    
    - alert: CoreDNSNXDOMAINHigh
      expr: coredns:nxdomain_rate:5m > 0.01
      for: 1m
      labels:
        severity: critical
        component: dns
      annotations:
        summary: "{{ $value | humanizePercentage }} queries returning NXDOMAIN"
    
    # Connection failures
    - alert: ServiceConnectionFailureRate
      expr: |
        (rate(http_requests_total{status=~"5.."}[5m]) /
         rate(http_requests_total[5m])) > 0.05
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Error rate {{ $value | humanizePercentage }}"
        dashboard: "https://grafana/d/services"
    
    # Conntrack exhaustion
    - alert: ConntrackNearExhaustion
      expr: |
        (net.netfilter.nf_conntrack_count / 
         net.netfilter.nf_conntrack_max) > 0.8
      labels:
        severity: warning
      annotations:
        summary: "Conntrack {{ $value | humanizePercentage }} full"
        runbook: "https://wiki/runbooks/conntrack-exhaustion"
```

Dashboard Organization:

```
Tier 1: Golden Signal Dashboard
  ├─ DNS latency (P50, P95, P99)
  ├─ Service connectivity (errors, timeouts)
  ├─ Network policy blocks
  └─ CNI operation latency

Tier 2: Deep Dive (per service)
  ├─ Service: <service-name>
  │  ├─ Endpoints: (show backing pods)
  │  ├─ Latency: (request flow)
  │  ├─ Errors: (by error type)
  │  └─ Network policies (applied rules)
  └─ (repeat for each critical service)

Tier 3: Operational (for on-call)
  ├─ CoreDNS health
  ├─ Network policy audit log
  ├─ Node network status
  └─ Incident runbooks (quick links)
```

Alerting strategy:

```
Severity P1 (Page immediately):
  - DNS completely unavailable (NXDOMAIN > 50%)
  - Service error rate > 10%
  - All endpoints down for critical service
  
Severity P2 (Alert in 5 min):
  - DNS latency P99 > 500ms
  - Service error rate 1-10%
  - Conntrack near exhaustion (> 80%)
  
Severity P3 (Daily digest):
  - Policy violations in audit logs
  - Slow policy evaluation (100-500ms)
  - MTU mismatch on nodes
  
No alert (just logging):
  - Normal policy allows/blocks
  - DNS cache hits (expected)
```
```

---

## References & Further Reading

- [Kubernetes Official Documentation - Cluster Admin](https://kubernetes.io/docs/tasks/administer-cluster/)
- [Kubernetes Networking Deep Dive](https://kubernetes.io/docs/concepts/services-networking/)
- [CoreDNS Documentation](https://coredns.io/)
- [Istio Service Mesh](https://istio.io/)
- [Cilium Network Policies & eBPF](https://cilium.io/)
- [Calico Network Policies](https://www.tigera.io/project-calico/)
- [Kubernetes Failure Stories](https://k8s.af/)
- [SRE Book: Monitoring and Alerting](https://sre.google/sre-book/monitoring-distributed-systems/)
- [etcd Backup & Recovery](https://etcd.io/docs/v3.5/op-guide/recovery/)
- [Prometheus Operator for Kubernetes Monitoring](https://prometheus-operator.dev/)

---

**Document Version:** 2.0  
**Last Updated:** March 2026  
**Audience:** Senior DevOps Engineers (5-10+ years)  
**Total Content:** 25,000+ words  
**Status:** Complete and Ready for Production Use
