# OpenShift: Troubleshooting, Best Practices & Production Patterns - Study Guide

**Level:** Senior DevOps Engineers (5-10+ years experience)  
**Continuation of:** Study Guides 1 & 2  
**Focus:** Operational excellence, incident response, production optimization

---

# Part 3: ADVANCED OPERATIONS & EXCELLENCE

---

## 9. OpenShift Troubleshooting - Comprehensive Guide

### 9.1 Cluster Health Diagnostics

#### Textual Deep Dive

**Internal Working Mechanism:**

Troubleshooting OpenShift requires understanding the health signals at each layer:

```
Health Layer Analysis:
┌─────────────────────────────────┐
│ Application Layer (Pods)        │
│ Health: Pod status, restart cnt │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│ Kubernetes Layer (Deployments)  │
│ Health: Ready replicas, events  │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│ Node Layer (kubelets)           │
│ Health: Node ready, allocatable │
└────────────┬────────────────────┘
             │
┌────────────▼────────────────────┐
│ Control Plane (API, etcd)       │
│ Health: API latency, etcd disk  │
└─────────────────────────────────┘

Troubleshooting methodology:
Start at layer where symptom appears.
Walk DOWN layers to find root cause.
Example: Pod failing → check deployment → check node → check API
```

**Core Diagnostics Script:**

```bash
#!/bin/bash
# cluster-health-check.sh - comprehensive health diagnostics

set -e
NAMESPACE=${1:-default}
KUBECONFIG=${KUBECONFIG:-$HOME/.kube/config}

echo "=== OpenShift Cluster Health Check ==="
echo ""

# 1. Control Plane Health
echo "--- CONTROL PLANE HEALTH ---"
oc get clusteroperators | grep -E "NAME|kube-apiserver|etcd|scheduler"
echo ""

# 2. API Server Health
echo "--- API SERVER LATENCY (p99) ---"
oc get --raw /metrics | grep apiserver_request_duration_seconds_bucket | \
  awk '{print $1, $2}' | tail -5
echo ""

# 3. etcd Health
echo "--- ETCD QUORUM STATUS ---"
ETCD_POD=$(oc get pods -n openshift-etcd -o name | head -1)
oc exec -n openshift-etcd $ETCD_POD -- etcdctl endpoint health
echo ""

# 4. Node Health
echo "--- NODE STATUS ---"
oc get nodes --no-headers | awk '{
  print $1 ": Ready=" $2 ", CPU=" $5 ", Memory=" $6
}'
echo ""

# 5. Node Pressure Conditions
echo "--- NODE PRESSURE CONDITIONS ---"
oc get nodes -o json | jq '.items[] | 
  {name: .metadata.name, conditions: [.status.conditions[] | 
  select(.type=="MemoryPressure" or .type=="DiskPressure" or .type=="PIDPressure") | 
  {type: .type, status: .status}]}'
echo ""

# 6. Pod Health in Namespace
echo "--- POD STATUS IN NAMESPACE: $NAMESPACE ---"
oc get pods -n $NAMESPACE --no-headers | awk '{
  if ($3 != "Running") print $1 ": Status=" $3 ", RestartCount=" $4
}'
echo ""

# 7. PVC Status (storage health)
echo "--- PERSISTENT VOLUMES ---"
oc get pvc -n $NAMESPACE --no-headers 2>/dev/null | while read line; do
  if [[ $line == *"Pending"* ]]; then
    echo "PENDING: $line"
  fi
done
echo ""

# 8. Network Connectivity Test
echo "--- NETWORK DIAGNOSTIC ---"
TEST_POD=$(oc get pod -n $NAMESPACE -o name | head -1)
if [ -z "$TEST_POD" ]; then
  echo "No pods to test network"
else
  echo "Testing DNS resolution from pod:"
  oc exec -n $NAMESPACE $TEST_POD -- nslookup kubernetes.default.svc.cluster.local
fi

echo ""
echo "=== END HEALTH CHECK ==="
```

**Practical Diagnostics:**

```bash
# 1. Check cluster operators health
oc get clusteroperators
# If any show DEGRADED: 
oc describe clusteroperator <NAME>

# 2. Check control plane component status
oc get pods -n openshift-apiserver
oc get pods -n openshift-etcd
oc get pods -n openshift-controller-manager
# Look for NotReady, CrashLoopBackOff, etc.

# 3. Check node readiness
oc get nodes -o wide
# Expected: All nodes show "Ready" status

# 4. Check for pod failures
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded
# Lists all non-running pods across cluster

# 5. Check event logs (recent cluster events)
oc get events --all-namespaces --sort-by='.lastTimestamp' | tail -20

# 6. Check storage provisioner health
oc describe storageclass ebs-gp3
oc get pvc --all-namespaces | grep -i pending

# 7. Check network overlay health
oc get pods -n openshift-sdn              # OpenShift SDN
oc get pods -n openshift-ovn-kubernetes   # OVN-Kubernetes

# 8. Check monitoring stack
oc get pods -n openshift-monitoring | grep -E "prometheus|grafana|alertmanager"
```

### 9.2 Pod Troubleshooting Workflow

#### Textual Deep Dive

**Pod Failure Analysis:**

```
Pod Status progression:
Pending → Running → {Succeeded|Failed|CrashLoopBackOff|EvictionWarning}
                           ↓
                     Causes per state
                     
PENDING: Pod waiting to be scheduled
├─ Likely cause: Resource constraints (not enough CPU/memory on nodes)
├─ Diagnosis: oc describe pod <pod>
│  Look for: "Insufficient cpu", "Insufficient memory"
└─ Fix: Increase cluster size or reduce pod requests

RUNNING (but unhealthy):
├─ Liveness probe failing? Pod restarts
├─ Readiness probe failing? Traffic removed but pod doesn't restart
├─ Diagnosis: oc describe pod <pod>
│  Look for: LastProbeTime, Message in probe section
└─ Fix: Check application logs, health endpoint

CRASHLOOPBACKOFF: Pod crashes, kubelet restarts, crashes again
├─ Likely cause: Application bug, missing config, permission denied
├─ Diagnosis: oc logs <pod> --previous
│  (--previous shows logs from crashed container)
└─ Fix: Review application startup logs, check environment

EVICTIONWARNING: Node running out of resources
├─ Likely cause: Node disk/memory pressure
├─ Diagnosis: oc describe node <node>
│  Look for: "MemoryPressure", "DiskPressure"
└─ Fix: Free disk space, kill memory-consuming pods, add nodes

IMAGEPULLBACKOFF: Can't download container image
├─ Likely cause: Image doesn't exist, wrong registry, auth failed
├─ Diagnosis: oc describe pod <pod>
│  Look for: "Error response from daemon"
└─ Fix: Check image name spelling, push to registry, add pull secret
```

**Production Pod Diagnostic Script:**

```bash
#!/bin/bash
# troubleshoot-pod.sh <namespace> <pod_name>

NAMESPACE=$1
POD=$2

if [ -z "$POD" ]; then
  echo "Usage: troubleshoot-pod.sh <namespace> <pod_name>"
  exit 1
fi

echo "=== POD TROUBLESHOOTING: $NAMESPACE/$POD ==="
echo ""

# 1. Pod status
echo "--- POD STATUS ---"
oc get pod -n $NAMESPACE $POD -o wide
echo ""

# 2. Pod events (why pod is pending/failing)
echo "--- RECENT EVENTS ---"
oc describe pod -n $NAMESPACE $POD | grep -A 10 "Events:"
echo ""

# 3. Pod logs (application output)
echo "--- POD LOGS (last 50 lines) ---"
oc logs -n $NAMESPACE $POD --tail=50 --timestamps=true 2>/dev/null || \
  echo "No logs available (pod not running)"
echo ""

# 4. Previous logs (if pod crashed)
echo "--- PREVIOUS POD LOGS (from crash) ---"
oc logs -n $NAMESPACE $POD --previous --tail=50 2>/dev/null || \
  echo "No previous logs"
echo ""

# 5. Container resource limits vs actual usage
echo "--- RESOURCE ALLOCATION ---"
oc describe pod -n $NAMESPACE $POD | grep -A 5 "Limits\|Requests"
echo ""

# 6. Node assignment
echo "--- ASSIGNED NODE ---"
NODE=$(oc get pod -n $NAMESPACE $POD -o jsonpath='{.spec.nodeName}')
echo "Node: $NODE"
if [ ! -z "$NODE" ]; then
  echo "Node status:"
  oc describe node $NODE | grep -A 2 "Conditions:"
fi
echo ""

# 7. Environment variables (may reveal config issues)
echo "--- ENVIRONMENT VARIABLES ---"
oc exec -n $NAMESPACE $POD -- env | grep -i config || echo "N/A"
echo ""

# 8. Container filesystem check
echo "--- FILESYSTEM USAGE ---"
oc exec -n $NAMESPACE $POD -- df -h 2>/dev/null | head -5 || echo "N/A"
echo ""

# 9. Network connectivity test
echo "--- NETWORK DIAGNOSTICS ---"
oc exec -n $NAMESPACE $POD -- ping -c 1 8.8.8.8 2>/dev/null && \
  echo "External connectivity: OK" || \
  echo "External connectivity: FAILED (network policy or firewall)"

oc exec -n $NAMESPACE $POD -- nslookup kubernetes.default.svc.cluster.local 2>/dev/null | grep -q "Server:" && \
  echo "Cluster DNS: OK" || \
  echo "Cluster DNS: FAILED"
echo ""

echo "=== END TROUBLESHOOTING ==="
```

### 9.3 Node Troubleshooting

#### Textual Deep Dive

**Node Status Analysis:**

```bash
#!/bin/bash
# troubleshoot-node.sh <node_name>

NODE=$1

# 1. Node status
echo "--- NODE STATUS ---"
oc describe node $NODE | head -30

# 2. Node conditions
echo "--- CONDITIONS ---"
oc get node $NODE -o json | jq '.status.conditions[] | {type: .type, status: .status, reason: .reason, message: .message}'

# 3. Node resource allocation
echo "--- RESOURCE ALLOCATION ---"
oc describe node $NODE | grep -A 20 "Allocated resources"

# 4. Critical kubelet logs
echo "--- KUBELET LOGS (last 50 lines) ---"
oc debug node/$NODE -- chroot /host journalctl -u kubelet -n 50 --no-pager

# 5. Check kernel issues
echo "--- KERNEL ISSUES (OOM killer, etc) ---"
oc debug node/$NODE -- chroot /host dmesg | tail -20 | grep -i "oom\|killed\|segfault"

# 6. Check disk space
echo "--- DISK USAGE ---"
oc debug node/$NODE -- chroot /host df -h | tail -10

# 7. Container runtime check (CRI-O, containerd)
echo "--- CONTAINER RUNTIME STATUS ---"
oc debug node/$NODE -- chroot /host systemctl status crio 2>/dev/null || \
  oc debug node/$NODE -- chroot /host systemctl status containerd

# 8. Network connectivity from node
echo "--- NODE NETWORK ---"
oc debug node/$NODE -- chroot /host ip addr show | grep -E "inet "
```

### 9.4 Storage Troubleshooting

#### Textual Deep Dive

**Storage Issue Diagnosis:**

```bash
#!/bin/bash
# troubleshoot-storage.sh <namespace> <pvc_name>

NAMESPACE=$1
PVC=$2

echo "=== STORAGE TROUBLESHOOTING: $NAMESPACE/$PVC ==="

# 1. PVC status
echo "--- PVC STATUS ---"
oc describe pvc -n $NAMESPACE $PVC

# 2. PV status
PV=$(oc get pvc -n $NAMESPACE $PVC -o jsonpath='{.spec.volumeName}')
if [ ! -z "$PV" ]; then
  echo "--- PV STATUS ---"
  oc describe pv $PV
else
  echo "PVC not bound to PV (stuck in Pending)"
  
  # Check storage provisioner
  echo "--- STORAGE CLASS ---"
  STORAGE_CLASS=$(oc get pvc -n $NAMESPACE $PVC -o jsonpath='{.spec.storageClassName}')
  oc describe storageclass $STORAGE_CLASS
fi

# 3. Pod using PVC (if any)
echo "--- PODS USING PVC ---"
oc get pods -n $NAMESPACE -o json | jq '.items[] | 
  select(.spec.volumes[]? | select(.persistentVolumeClaim.claimName=="'$PVC'")) | 
  {name: .metadata.name, status: .status.phase}'

# 4. Mount point check
echo "--- MOUNT ISSUES ---"
PODS=$(oc get pods -n $NAMESPACE -o json | jq -r '.items[] | 
  select(.spec.volumes[]? | select(.persistentVolumeClaim.claimName=="'$PVC'")) | 
  .metadata.name')

for POD in $PODS; do
  echo "Checking pod: $POD"
  oc exec -n $NAMESPACE $POD -- mount | grep -E '/mnt/|/data/' || echo "  No mounts found"
  oc exec -n $NAMESPACE $POD -- df -h | grep -E 'Used|/mnt/|/data/' || echo "  No storage usage"
done

# 5. Storage provisioner health
echo "--- STORAGE PROVISIONER STATUS ---"
oc get pods -n kube-system -l app=ebs-csi-controller  # AWS example
```

### 9.5 Network Troubleshooting

#### Textual Deep Dive

**Network Connectivity Issues:**

```bash
#!/bin/bash
# troubleshoot-network.sh <namespace> <pod_name>

NAMESPACE=$1
POD=$2

echo "=== NETWORK TROUBLESHOOTING: $NAMESPACE/$POD ==="

# 1. Pod IP assignment
echo "--- POD NETWORK INFO ---"
oc get pod -n $NAMESPACE $POD -o wide
POD_IP=$(oc get pod -n $NAMESPACE $POD -o jsonpath='{.status.podIP}')
echo "Pod IP: $POD_IP"

# 2. Container network interfaces
echo "--- NETWORK INTERFACES ---"
oc exec -n $NAMESPACE $POD -- ip addr show

# 3. DNS resolution
echo "--- DNS TESTS ---"
oc exec -n $NAMESPACE $POD -- nslookup kubernetes.default
oc exec -n $NAMESPACE $POD -- nslookup <service-name>.<namespace>.svc.cluster.local

# 4. Route to pod
echo "--- ROUTES ---"
oc exec -n $NAMESPACE $POD -- ip route show

# 5. Network policies affecting pod
echo "--- NETWORK POLICIES ---"
oc get networkpolicies -n $NAMESPACE -o wide

# 6. Test connectivity to another pod
TARGET_POD=$(oc get pods -n $NAMESPACE -o name | head -2 | tail -1)
TARGET_IP=$(oc get pod -n $NAMESPACE $(basename $TARGET_POD) -o jsonpath='{.status.podIP}')
echo "Testing connectivity to $TARGET_POD ($TARGET_IP):"
oc exec -n $NAMESPACE $POD -- nc -zv $TARGET_IP 8080 || echo "Connection refused"

# 7. Service DNS and endpoints
SERVICE="svc-name"
echo "--- SERVICE DISCOVERY ---"
oc get service -n $NAMESPACE $SERVICE -o wide
oc get endpoints -n $NAMESPACE $SERVICE

# 8. Iptables rules (kube-proxy load balancing)
echo "--- KUBE-PROXY RULES ---"
# Run on node with network namespace debugging
oc debug node/worker-1 -- chroot /host iptables -t nat -L SERVICES | head -20

# 9. Packet capture (tcpdump)
echo "--- PACKET CAPTURE (10 packets) ---"
oc exec -n $NAMESPACE $POD -- tcpdump -i any -c 10 'tcp port 8080'
```

### 9.6 API Server & etcd Troubleshooting

#### Textual Deep Dive

**Control Plane Diagnostics:**

```bash
#!/bin/bash
# troubleshoot-control-plane.sh

echo "=== CONTROL PLANE TROUBLESHOOTING ==="

# 1. API Server health
echo "--- API SERVER HEALTH ---"
oc get pods -n openshift-apiserver
oc describe pod -n openshift-apiserver -l app=openshift-apiserver

# 2. API Server latency (from metrics)
echo "--- API SERVER LATENCY ---"
oc get --raw /metrics | grep -E 'apiserver_request_duration_seconds_bucket|apiserver_client_certificate_expiration' | head -10

# 3. etcd health
echo "--- ETCD HEALTH ---"
ETCD_POD=$(oc get pods -n openshift-etcd -o name --field-selector status.phase=Running | head -1)
oc exec -n openshift-etcd $(basename $ETCD_POD) -- etcdctl endpoint health
oc exec -n openshift-etcd $(basename $ETCD_POD) -- etcdctl member list

# 4. etcd database size
echo "--- ETCD DB SIZE ---"
oc exec -n openshift-etcd $(basename $ETCD_POD) -- du -sh /var/lib/etcd
oc exec -n openshift-etcd $(basename $ETCD_POD) -- etcdctl alarm list

# 5. Scheduler status
echo "--- SCHEDULER HEALTH ---"
oc get pods -n openshift-kube-scheduler
oc logs -n openshift-kube-scheduler -l app=openshift-kube-scheduler --tail=50 | tail -20

# 6. Controller Manager status
echo "--- CONTROLLER MANAGER HEALTH ---"
oc get pods -n openshift-controller-manager
oc logs -n openshift-controller-manager -l app=openshift-controller-manager --tail=50 | tail -20

# 7. API audit logs (recent operations)
echo "--- API AUDIT LOGS ---"
oc debug node/master-0 -- chroot /host tail -20 /var/log/audit/audit.log | jq '.verb, .objectRef.name' 2>/dev/null || echo "Raw logs:"

# 8. Webhook latency (if admission webhooks in use)
echo "--- ADMISSION WEBHOOK LATENCY ---"
oc get --raw /metrics | grep admission_webhook | head -5
```

### Common Troubleshooting Patterns & Solutions

```
PATTERN 1: "Pod Pending" → Resource Unavailable
═════════════════════════════════════════════
Symptom: oc get pods shows pod in Pending status for > 5 minutes
Root Cause: Requested resources not available on any node
Fix:
  1. Check pod resource requests: oc describe pod <pod>
  2. Check node allocatable: oc describe node <node>
  3. If requests realistic, scale cluster (add nodes)
  
PATTERN 2: "ImagePullBackOff" → Registry Access Issue
═════════════════════════════════════════════════════
Symptom: Pod won't run, status shows ImagePullBackOff
Root Cause: Image not found, typo, auth failed
Fix:
  1. Verify image exists: oc debug pod -it --image=<image> --overrides='{"spec":{"containers":[{"name":"debug","image":"<image>"}]}}'
  2. Check pull secret: oc get secret -n prod deployer-token -o yaml
  3. If auth issue, update secret: kubectl patch secret -p='{"data":{".dockerconfigjson": <base64-encoded-auth>}}'

PATTERN 3: "CrashLoopBackOff" → Application Bug
═══════════════════════════════════════════════
Symptom: Pod starts, crashes immediately, restarts loop
Root Cause: Application error, missing config, permission issue
Fix:
  1. Check logs: oc logs <pod> --previous (from crashed container)
  2. Check env: oc exec <pod> -- env (missing config vars?)
  3. Check permissions: oc get pod <pod> -o json | jq '.spec.securityContext'
  4. Test locally: docker run <image> (run container locally to debug)

PATTERN 4: "Pod CrashLoopBackOff" but No Logs
═════════════════════════════════════════════
Symptom: Pod crashes but oc logs returns nothing
Root Cause: App crashed before logging initialized, or logs to file not stdout
Fix:
  1. Get pod events: oc describe pod <pod> | grep Events
  2. Check if app writes to file: oc exec <pod> -- cat /var/log/app.log
  3. Force stdout logging: modify app config or entrypoint script

PATTERN 5: "Certificate Expired" → API Connection Failed
════════════════════════════════════════════════════════
Symptom: All API operations fail, TLS certificate error
Root Cause: TLS certificate expired
Fix:
  1. Check cert expiry: oc get secret apiserver-cert -n openshift-apiserver -o json | jq '.data["tls.crt"]' | base64 -d | openssl x509 -noout -dates
  2. If expired, initiate cert rotation (automatic in v4.5+): oc rollout restart deployment apiserver -n openshift-apiserver
  3. Monitor cert renewal: watch oc get secret apiserver-cert -n openshift-apiserver -o json | jq '.data'

PATTERN 6: "Connection Refused" Between Services
═════════════════════════════════════════════════
Symptom: Pod A can't connect to Pod B, connection refused
Root Cause: Network policy blocking, wrong port, service doesn't exist
Fix:
  1. Verify destination runs: oc get pod <pod-b> (should show Running)
  2. Check port: oc get pod <pod-b> -o json | jq '.spec.containers[].ports'
  3. Test DNS: oc exec <pod-a> -- nslookup <service-b>
  4. Check network policy: oc get networkpolicy -n prod (might block traffic)
  5. Temporarily allow all: oc delete networkpolicy --all (DEBUG ONLY, not production)

PATTERN 7: "Eviction Warning" → Node Running Out of Resources
═════════════════════════════════════════════════════════════
Symptom: Pods evicted, node shows MemoryPressure or DiskPressure
Root Cause: Memory leak, disk filling up, too many pods per node
Fix:
  1. Identify memory hog: oc top pods -n prod --sort-by=memory
  2. Check node disk: oc debug node/<node> -- chroot /host df -h
  3. Clean up: delete old images, logs, or scale deployments
  4. Add memory-optimized nodes if genuine need
```

---

## 10. OpenShift Best Practices - Operational Excellence

### 10.1 Cluster Design Best Practices

#### Textual Deep Dive

**Best Practice 1: Node Topology for Scalability**

```
Production cluster layout:

┌──────────────────────────────────────────────────┐
│         OpenShift Cluster (1000+ pods)           │
├──────────────────────────────────────────────────┤
│ MASTER NODES (Control Plane) - 3 to 5 nodes     │
│ ├─ Instance: m5.2xlarge (8 CPU, 32 GB)         │
│ ├─ Storage: 500 GB root, 50 GB /var/data/etcd   │
│ ├─ Taints: node-role.kubernetes.io/master      │
│ └─ Workload: Only system components             │
├──────────────────────────────────────────────────┤
│ INFRA NODES - 3 nodes (one per zone)            │
│ ├─ Instance: m5.xlarge (4 CPU, 16 GB)          │
│ ├─ Labels: node-role.kubernetes.io/infra       │
│ ├─ Workload: Monitoring, logging, router       │
│ └─ Resources: 10 CPU, 40 GB total for platform │
├──────────────────────────────────────────────────┤
│ COMPUTE NODES - 10-100 nodes (auto-scale)      │
│ ├─ Instance: m5.2xlarge (8 CPU, 32 GB)         │
│ ├─ Labels: node-role.kubernetes.io/worker      │
│ ├─ Workload: Application pods                  │
│ └─ Scaling: based on CPU > 75% or memory > 80% │
├──────────────────────────────────────────────────┤
│ SPECIALIZED NODES (optional)                    │
│ ├─ GPU Nodes: g4dn.12xlarge (for ML)           │
│ ├─ Memory Nodes: r5.4xlarge (for caching)      │
│ └─ Storage Nodes: i3.4xlarge (for databases)   │
└──────────────────────────────────────────────────┘

Rules:
• Master nodes: Never run application workloads
• Infra nodes: Separate from compute to prevent noisy neighbors
• Compute nodes: Auto-scale to optimize cost
• Specialized: Right-size for workload type (GPU expensive)
```

**Best Practice 2: Resource Requests and Limits**

```yaml
# ✓ CORRECT: Realistic requests and limits
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  template:
    spec:
      containers:
      - name: api
        image: api:v1
        resources:
          requests:           # What scheduler uses for placement
            cpu: 250m         # 0.25 CPU
            memory: 256Mi     # 256 MB
          limits:             # Hard cap (pod killed if exceeded)
            cpu: 1000m        # 1 CPU
            memory: 512Mi     # 512 MB
        # Requests: 1/4 of limits (leaves room to scale)
        # Limits: realistic max for app under load

# ✗ WRONG PATTERN 1: No requests/limits (random placement)
---
containers:
- name: app
  image: app:v1
  # Scheduler has no info, places on random nodes
  # App can consume entire node → crashes other apps

# ✗ WRONG PATTERN 2: Requests too high (pods pending forever)
---
containers:
- name: app
  image: app:v1
  resources:
    requests:
      cpu: 999
      memory: 1000Gi
  # No node can satisfy → Pending status forever

# ✗ WRONG PATTERN 3: Limits way below requests (app crashes)
---
containers:
- name: app
  image: app:v1
  resources:
    requests:
      cpu: 4000m
      memory: 4Gi
    limits:
      cpu: 500m         # Half of request!
      memory: 512Mi     # 1/8th of request!
  # App scaled up past limits → OOMKilled (memory) or throttled (CPU)
```

**Best Practice 3: Health Checks (Liveness & Readiness)**

```yaml
# ✓ CORRECT: Comprehensive health checks
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-service
spec:
  template:
    spec:
      containers:
      - name: web
        image: web:v1
        ports:
        - containerPort: 8080
          name: http
        
        # Readiness: Can pod handle traffic? (before running, after crash)
        readinessProbe:
          httpGet:
            path: /health/ready
            port: http
          initialDelaySeconds: 5      # Wait 5s after start
          periodSeconds: 2            # Check every 2s
          failureThreshold: 3         # 3 failures = NotReady
          timeoutSeconds: 1           # Give endpoint 1s to respond
        
        # Liveness: Is pod alive? (restart if dead)
        livenessProbe:
          httpGet:
            path: /health/live
            port: http
          initialDelaySeconds: 30     # Give app 30s to startup
          periodSeconds: 10           # Check every 10s
          failureThreshold: 3         # 3 failures = restart pod
          timeoutSeconds: 1           # Give endpoint 1s
          
        # Startup: Container initializing (for slow startups)
        startupProbe:
          httpGet:
            path: /health/startup
            port: http
          failureThreshold: 30        # 30 failures × 10s = 5 min max startup
          periodSeconds: 10

# ✗ WRONG: No health checks (unhealthy pods get traffic)
---
containers:
- name: web
  image: web:v1
  # Pod crashes but still routes traffic to dead instance
  # Users see "500 Internal Server Error"

# ✗ WRONG: Liveness too aggressive (readiness soup)
---
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 1           # Check every second (too much load!)
  failureThreshold: 1        # Kill pod on first failure
  # App has garbage collection pause: liveness fails, pod restarts
```

**Best Practice 4: Pod Disruption Budgets**

```yaml
# ✓ CORRECT: Protect critical workloads during updates
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-service-pdb
  namespace: prod
spec:
  minAvailable: 2            # Always keep ≥2 pods running
  selector:
    matchLabels:
      app: api-service
  unhealthyPodEvictionPolicy: AlwaysAllow  # Evict unhealthy pods

# During cluster upgrade:
# 1. Worker node cordon (no new pods)
# 2. Drain: evict existing pods
# 3. Scheduler checks PDB: are ≥2 api-service pods running elsewhere?
# 4. If yes: safe to evict from this node
# 5. If no: wait until ≥2 pods running before evicting

# ✗ WRONG: No PDB (no protection during updates)
---
# Deployment with 3 replicas
# During upgrade: all 3 pods evicted simultaneously
# Brief period: 0 pods running = full outage
# PDB prevents this catastrophe
```

### 10.2 Deployment Patterns Best Practices

#### Textual Deep Dive

**Pattern 1: Blue-Green Deployments (Zero Downtime)**

```yaml
# Blue: Current production version (v1.0)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway-blue
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
      version: blue
  template:
    metadata:
      labels:
        app: api-gateway
        version: blue
    spec:
      containers:
      - name: gateway
        image: api-gateway:v1.0

---
# Green: New version (v2.0) ready to deploy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway-green
  namespace: prod
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-gateway
      version: green
  template:
    metadata:
      labels:
        app: api-gateway
        version: green
    spec:
      containers:
      - name: gateway
        image: api-gateway:v2.0

---
# Service routes to blue (production)
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: prod
spec:
  selector:
    app: api-gateway
    version: blue      # Routes to blue (current production)
  ports:
  - port: 80
    targetPort: 8080

---
# Deployment process:
# 1. Both blue and green running (2x resources temporarily)
# 2. Run smoke tests against green
# 3. If green healthy: update service selector
#    Service routes 100% to green (instant cutover)
# 4. If green fails: rollback (service still routes to blue)
# 5. Delete blue after success window

# Benefits:
# • Instant rollback (revert selector)
# • No traffic during transition
# • Full testing of new version before cutover
# • Can compare metrics between versions
```

**Pattern 2: Canary Deployments (Progressive Traffic Shift)**

```yaml
# Canary via Service Mesh (Istio/OpenShift Service Mesh)
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
      weight: 95        # 95% traffic to v1 (stable)
    - destination:
        host: api-gateway
        subset: v2
      weight: 5         # 5% traffic to v2 (canary)

---
# Automated canary progression (via Flagger operator)
# 1. Metrics collection: error rate, latency from v2
# 2. If error_rate < 0.1%: increment weight (v2: 5→10->20...)
# 3. If error_rate > 1%: rollback
# 4. After success period: v2 becomes stable (100% weight)

# Benefits vs. rolling update:
# • Issues detected on 1% users (not 100%)
# • Instant rollback if errors appear
# • Real traffic validation (load testing can't match)
```

**Pattern 3: Rolling Updates (Traditional)**

```yaml
# Default Kubernetes strategy
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # 1 extra pod (up to 4 total)
      maxUnavailable: 0  # 0 pods down (always 3+ available)
  template:
    spec:
      containers:
      - name: gateway
        image: api-gateway:v2.0

# Progression:
# Time 0:   [v1][v1][v1]              (3 pods, v1)
# Time 1:   [v1][v1][v1][v2]          (4 pods, 1x v2)
# Time 2:   [v1][v1][v2][v2]          (4 pods, 2x v2)
# Time 3:   [v1][v2][v2][v2]          (4 pods, 3x v2)
# Time 4:   [v2][v2][v2]              (3 pods, v2)

# If v2 has bugs:
# Time 3:   Error detected during update
# Rollout stop: stops deploying more v2
# Current: mix of v1 and v2 (some users see errors)
# Rollback: manually revert to v1

# Drawbacks:
# • Brief window with mixed versions
# • Harder to debug (which version got this error?)
# • Not suitable for breaking API changes
```

### 10.3 Security Best Practices

#### Textual Deep Dive

**Best Practice: Zero Trust Network Model**

```yaml
# Default: Deny all ingress and egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---
# Allow frontend pods ONLY from ingress controller
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-to-frontend
  namespace: prod
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
          name: openshift-ingress  # Only from ingress controller
    ports:
    - protocol: TCP
      port: 8080

---
# Allow frontend to backend API
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-api
  namespace: prod
spec:
  podSelector:
    matchLabels:
      tier: api
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---
# Allow backend to database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-database
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
          name: database
    ports:
    - protocol: TCP
      port: 5432

---
# Allow DNS for all (otherwise cluster.local resolution fails)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53

---
# RBAC: Least privilege
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-deployer
  namespace: prod
rules:
# Can deploy applications
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["create", "get", "list", "patch", "update"]
# Can't delete (prevents accidental in-office deletion)
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get"]
  # Intentionally NO "delete" verb
# Can't access secrets
# Can't create other roles (prevent privilege escalation)
```

**Best Practice: Image Security**

```yaml
# Container image scanning in CI/CD
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: api-service-build
  namespace: prod
spec:
  source:
    git:
      uri: https://github.com/example/api-service
  strategy:
    dockerStrategy:
      from:
        kind: ImageStreamTag
        name: rhel8:latest
  output:
    to:
      kind: ImageStreamTag
      name: api-service:latest
  postCommit:
    script: |
      # Scan image for vulnerabilities
      trivy image --exit-code 1 \
        --severity HIGH,CRITICAL \
        $DOCKER_REGISTRY_HOST/api-service:$BUILD_COMMIT
      
      # Exit code 1 = vulnerabilities found, build fails
      # Image NOT pushed to registry
      # Developer notified, must update dependencies

---
# Pod Security Standards (enforce at namespace level)
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

---
# Pod-level security context
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true        # Must not be root
        runAsUser: 1000           # Run as uid 1000
        fsGroup: 2000             # File ownership
        seccompProfile:
          type: RuntimeDefault    # Restrict syscalls
      containers:
      - name: app
        image: app:v1
        securityContext:
          allowPrivilegeEscalation: false  # Can't become root
          readOnlyRootFilesystem: true     # Read-only /
          capabilities:
            drop:
            - ALL                          # Remove all Linux caps
```

### 10.4 Monitoring & Observability Best Practices

#### Textual Deep Dive

**Best Practice: SLO-Driven Alerting**

```yaml
# SLO definition: "99.95% request success rate"
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: api-gateway-slo
spec:
  groups:
  - name: api.slo.rules
    rules:
    # Calculate error rate
    - record: api:error_rate
      expr: |
        rate(http_requests_total{status=~"5.."}[5m]) /
        rate(http_requests_total[5m])
    
    # SLO alert: breach 99.95% threshold
    - alert: APIGateway99.95SLOBreach
      expr: api:error_rate > 0.0005  # 0.05% = 1 - 0.9995
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "API error rate {{ $value | humanizePercentage }}"

---
# Service Level Indicator (query)
# GET /metrics?query=api:error_rate
# Expected: < 0.0005 (0.05%)

# Alerting policy:
# • Error rate < 0.05% for 7 days → No alert (meeting SLO)
# • Error rate > 0.05% for 5+ minutes → Alert (breaching SLO)
# • Error rate > 1% for 1 minute → Critical (severe breach)
```

**Best Practice: Golden Signals Monitoring**

```yaml
# Four golden signals: Latency, Traffic, Errors, Saturation
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: golden-signals
spec:
  groups:
  - name: app.signals
    rules:
    # 1. LATENCY (p99, p95)
    - record: api:latency:p95
      expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
    
    - record: api:latency:p99
      expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
    
    - alert: APILatencyHigh
      expr: api:latency:p99 > 1
      annotations:
        summary: "API p99 latency > 1s"
    
    # 2. TRAFFIC (requests per second)
    - record: api:rps
      expr: rate(http_requests_total[5m])
    
    - alert: APITrafficSpike
      expr: rate(api:rps[5m]) > rate(api:rps[1h] offset 1h) * 2
      annotations:
        summary: "API traffic 2x baseline"
    
    # 3. ERRORS (error rate percentage)
    - record: api:error_rate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
    
    - alert: APIErrorRateHigh
      expr: api:error_rate > 0.01
      annotations:
        summary: "API error rate > 1%"
    
    # 4. SATURATION (resource utilization)
    - record: node:cpu:saturation
      expr: rate(node_cpu_seconds_total{mode!="idle"}[5m])
    
    - alert: NodeCPUSaturation
      expr: node:cpu:saturation > 0.85
      annotations:
        summary: "Node CPU > 85%"
```

### 10.5 Disaster Recovery Best Practices

#### Textual Deep Dive

**Best Practice: Automated Backups & Recovery**

```bash
#!/bin/bash
# backup-restore-strategy.sh

# 1. ETCD BACKUP (cluster state)
echo "=== DAILY ETCD BACKUP (2 AM UTC) ==="
# Automated via CronJob
# Runs: /usr/local/bin/cluster-backup.sh /backups/etcd
# Stores: /backups/etcd/snapshot_UTC_<timestamp>.db

# Test restore (weekly)
BACKUP="/backups/etcd/snapshot_UTC_2025-01-01-020000.db"
./cluster-restore.sh $BACKUP
# Verify: oc get pods --all-namespaces (should show cluster state)

# 2. APPLICATION DATA BACKUP (Velero)
echo "=== APPLICATION DATA BACKUP (Velero) ==="
# Install Velero: oc apply -f velero-namespace.yaml

# Create backup schedule
cat <<EOF | oc apply -f -
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"               # Daily 2 AM UTC
  template:
    includedNamespaces:
    - prod
    - staging
    ttl: "720h"                        # Keep 30 days
    storageLocation: aws-s3
    volumeSnapshotLocation: aws-ebs
    snapshotVolumes: true              # Include PVs
EOF

# 3. DISASTER RECOVERY TEST (Monthly)
echo "=== DR TEST (Staging Cluster) ==="
# Restore backup to staging cluster
velero restore create --from-schedule daily-backup

# Validate: all apps running, data intact
oc get pods -n prod
psql -h database-prod -U admin -d mydb -c "SELECT COUNT(*) FROM users;"

# 4. FAILOVER PROCEDURE (On failure)
echo "=== FAILOVER PROCEDURE ==="
# If production cluster fails:
# 1. Health check confirms unavailable
# 2. Activate standby cluster (or restore from backup)
# 3. Update DNS to point to new cluster
# 4. Application reconnects automatically
# 5. RTO: 15-30 minutes (depends on restore speed)

# 5. MONITORING FOR DATA LOSS
echo "=== BACKUP MONITORING ==="
# Alert if backup older than 25 hours
cat <<EOF | oc apply -f -
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backup-alerts
spec:
  groups:
  - name: backup.rules
    rules:
    - alert: VeleroBackupFailed
      expr: velero_backup_duration_seconds{status="Failed"} > 0
      for: 1h
      annotations:
        summary: "Velero backup failed"
    
    - alert: VeleroBackupOld
      expr: time() - velero_backup_last_successful_timestamp > 90000
      annotations:
        summary: "Last backup > 24 hours old"
EOF
```

### 10.6 Cost Optimization Best Practices

#### Textual Deep Dive

**Best Practice: Resource Optimization**

```yaml
# Right-size nodes and workloads
# 1. CPU: Measure actual usage vs. requested
# 2. Memory: Watch for memory leaks, optimize requests
# 3. Storage: Use tiered storage (hot/cold), garbage collection

---
# Example: Find over-requested resources
$ oc top pods -n prod --sort-by=memory
# Shows actual memory usage

$ oc get pods -n prod -o json | jq '.items[].spec.containers[].resources.requests.memory'
# Shows requested memory

# If actual << requested: reduce requests
# Example: pod uses 150 MB, requests 1 GB → reduce to 250 MB request

---
# Storage cost optimization
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-tiered
provisioner: ebs.csi.aws.com
parameters:
  type: gp3              # General purpose (cheaper than io1)
  iops: "3000"           # Minimum IOPS
  throughput: "125"      # Minimum throughput
reclaimPolicy: Delete    # Cost: delete unused volumes
allowVolumeExpansion: true

---
# Snapshot retention: minimize stored snapshots
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-backup
spec:
  schedule: "0 2 * * *"
  template:
    ttl: "168h"          # Keep 7 days only (not 30)

---
# Example cost impact:
# Without optimization:
#   • Compute: 50 nodes × $0.50/hr = $25/hr = $18,250/month
#   • Storage: 100 PVCs × 100 GB × $0.10/GB = $1,000/month
#   • Total: $19,250/month

# With optimization:
#   • Compute: 30 nodes × $0.50/hr = $15/hr = $10,950/month (70% utilized)
#   • Storage: 60 PVCs × 50 GB × $0.08/GB = $240/month
#   • Total: $11,190/month (42% savings)
```

---

## 11. Production Hardware Sizing Guide

### For Small Production Cluster (< 100 pods)

```
Master Nodes (3):
├─ Instance: m5.xlarge (4 CPU, 16 GB RAM)
├─ Storage: 200 GB root, 20 GB etcd
└─ Cost: $0.192/hr × 3 × 730 hrs = $421/month

Infra Nodes (3):
├─ Instance: m5.large (2 CPU, 8 GB RAM)
├─ Storage: 100 GB root
└─ Cost: $0.096/hr × 3 × 730 hrs = $210/month

Compute Nodes (10 base, auto-scale to 20):
├─ Instance: m5.xlarge (4 CPU, 16 GB RAM)
├─ Storage: 100 GB root
└─ Cost: $0.192/hr × 15 avg × 730 hrs = $2,106/month

Total: ~$2,737/month
```

### For Large Production Cluster (1000+ pods)

```
Master Nodes (5):
├─ Instance: m5.2xlarge (8 CPU, 32 GB RAM)
├─ Storage: 500 GB root, 50 GB etcd
└─ Cost: $0.384/hr × 5 × 730 hrs = $1,403/month

Infra Nodes (9, spread across 3 zones):
├─ Instance: m5.2xlarge (8 CPU, 32 GB RAM)
├─ Storage: 200 GB root
└─ Cost: $0.384/hr × 9 × 730 hrs = $2,525/month

Compute Nodes (100 base, auto-scale to 200):
├─ Instance: m5.2xlarge (8 CPU, 32 GB RAM)
├─ Storage: 200 GB root
└─ Cost: $0.384/hr × 150 avg × 730 hrs = $42,048/month

Specialized (10 GPU nodes):
├─ Instance: g4dn.12xlarge (4 GPU)
└─ Cost: $4.92/hr × 10 × 730 hrs = $35,916/month

Total: ~$81,892/month
```

---

## 12. Conclusion & Certification Path

### Key Takeaways

**Architectural Excellence:**
1. Multi-master HA for control plane
2. Separate infra nodes for platform components
3. Auto-scaling compute nodes for cost optimization
4. Specialized nodes for specific workloads

**Operational Excellence:**
1. GitOps for all cluster configuration
2. Comprehensive monitoring (golden signals)
3. SLO-driven alerting
4. Automated disaster recovery

**Security Excellence:**
1. Zero-trust network model (deny-all default)
2. Pod Security Standards enforcement
3. RBAC least privilege
4. Image scanning in CI/CD

**Production Readiness Checklist:**
- [ ] High availability (3+ masters, PDBs, anti-affinity)
- [ ] Health checks (liveness, readiness, startup)
- [ ] Resource limits (requests, limits configured)
- [ ] Monitoring (Prometheus, Grafana, alerting)
- [ ] Logging (EFK, centralized log collection)
- [ ] Security (RBAC, network policies, pod security)
- [ ] Backup (etcd + application data)
- [ ] Disaster recovery (failover tested, RTO < 30 min)
- [ ] Cost optimization (resource utilization > 70%)

### Study Path Recommendation

**Phase 1 (Weeks 1-2): Foundational Concepts**
- Study Guide 1: Introduction + Foundational Concepts
- Labs: Deploy single pod, understand namespaces, RBAC basics

**Phase 2 (Weeks 3-6): Core Components**
- Study Guide 2: Architecture + Installation + Networking
- Labs: Build cluster (UPI), configure SDN, test network policies

**Phase 3 (Weeks 7-10): Operations**
- Study Guide 2: Storage + Security + CI/CD
- Labs: Deploy stateful apps, configure secrets, build pipelines

**Phase 4 (Weeks 11-14): Advanced Operations**
- Study Guide 3: Troubleshooting + Best Practices
- Labs: Incident simulations, optimization exercises, DR tests

**Phase 5 (Weeks 15-16): Hands-on Scenarios**
- Real cluster operations
- Incident response exercises
- Production readiness review

### Interview Preparation

**Common Senior DevOps Interview Questions:**

1. **"Describe how you would design a highly available OpenShift cluster for a financial services company with 99.99% uptime SLA."**

   Answer should include:
   - 3-5 master nodes (quorum analysis)
   - Multi-zone topology (AZ resilience)
   - Separate infra nodes (noisy neighbor prevention)
   - Auto-scaling compute (cost optimization)
   - Storage strategy (replicated, backed up)
   - Monitoring/alerting (SLO-driven)
   - Disaster recovery (< 30 min RTO)

2. **"You have a pod that's stuck in 'Pending' state for 2 hours. How do you troubleshoot?"**

   Answer should include:
   - `oc describe pod <pod>` (look for scheduling failures)
   - Check node resources: `oc describe node <node>`
   - Check storage class: `oc describe storageclass`
   - Network policy blocking? `oc get networkpolicies`
   - Quota exceeded? `oc describe resourcequota`
   - Eventually: scale cluster if resources insufficient

3. **"Walking through a incident: Service experiencing 5% error rate. What's your triage process?"**

   Answer should include:
   - Check pod status, logs, events
   - Check node health (CPU, memory, disk pressure)
   - Check API latency (control plane issue?)
   - Check network (network policy blocking?)
   - Check storage (PVC provisioning issues?)
   - Correlate with recent deployments/changes
   - Implement temporary fix (scale, restart)
   - Root cause analysis (logs, metrics, events)

This comprehensive study guide series provides everything needed for production-grade OpenShift operations at the senior level.
