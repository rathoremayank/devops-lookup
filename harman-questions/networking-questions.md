# Networking Questions

## 1. Could you please explain deployment vs StatefulSet?

### Answer:

Deployment and StatefulSet are two distinct Kubernetes workload types with different use cases, network identities, and storage handling.

**Deployment:**

A Deployment is used for stateless applications where replicas are interchangeable and can be created/destroyed without impact to application state.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: web-app
        image: myregistry/web-app:v1.0
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Deployment Characteristics:**
- Pod names are random: `web-app-5d4f7c9b8-xyz12`
- Order of pod creation is not guaranteed
- Pods can be created/destroyed in any order
- No stable network identity
- All pods share same service endpoint
- Used for: Web servers, APIs, stateless services

**StatefulSet:**

A StatefulSet maintains a stable network identity for each pod and is used for stateful applications requiring ordered pod creation and deletion.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  namespace: production
spec:
  clusterIP: None  # Headless service required
  selector:
    app: mysql
  ports:
  - port: 3306
    name: mysql
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
  namespace: production
spec:
  serviceName: mysql  # Must reference headless service
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
          name: mysql
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
        - name: config
          mountPath: /etc/mysql/conf.d
      volumes:
      - name: config
        configMap:
          name: mysql-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 100Gi
```

**StatefulSet Characteristics:**
- Pod names are predictable: `mysql-0`, `mysql-1`, `mysql-2`
- Pods created sequentially: `mysql-0` → `mysql-1` → `mysql-2`
- Each pod has stable network identity: `mysql-0.mysql.production.svc.cluster.local`
- Persistent storage per pod via volumeClaimTemplates
- Ordinal index maintained consistently
- Used for: Databases, message queues, caches, distributed systems

**Detailed Comparison Table:**

| Aspect | Deployment | StatefulSet |
|--------|-----------|------------|
| Pod Identity | Random | Stable, predictable |
| Pod Naming | `app-5d4f7c9b8-xyz12` | `app-0`, `app-1`, `app-2` |
| Ordering | Unordered | Ordered (sequential) |
| Network DNS | Via Service only | Headless Service (DNS-1 per pod) |
| Storage | Shared (optional) | Per-pod (volumeClaimTemplates) |
| Scaling | Independent replicas | Ordered scale up/down |
| Replacement | Any order | Ordinal order |
| Termination | Parallel | Sequential descending |
| Update Strategy | RollingUpdate, Recreate | Rolling (sequential) |
| Use Case | Stateless, web services | Stateful, databases |

**Access Patterns:**

```bash
# Deployment - any pod can handle request
# Via ClusterIP Service (round-robin)
curl http://web-app.production.svc.cluster.local:8080

# StatefulSet - specific pod may be needed
# Via headless service (direct DNS to pod)
curl http://mysql-0.mysql.production.svc.cluster.local:3306
curl http://mysql-1.mysql.production.svc.cluster.local:3306
curl http://mysql-2.mysql.production.svc.cluster.local:3306
```

**Scaling Behavior:**

```bash
# Deployment scales instantly
kubectl scale deployment web-app --replicas=5
# New pods start immediately, order doesn't matter

# StatefulSet scales sequentially
kubectl scale statefulset mysql --replicas=5
# Ordinal 3, 4 created in order
# High availability before new pod added to replication

# Rolling updates
# Deployment: Can scale via max surge/unavailable
# StatefulSet: Updates one pod at a time, preserves ordinal
```

**Real-World Scenarios:**

```yaml
# Scenario 1: Web Application (Deployment)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3
  # Any replica failure can be replaced immediately
  # Requests load-balanced across all replicas
  # No persistent state maintained per pod

---

# Scenario 2: Database Cluster (StatefulSet)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql-cluster
spec:
  replicas: 3
  # mysql-0: Primary (read-write)
  # mysql-1: Secondary (read-only, replica)
  # mysql-2: Secondary (read-only, replica)
  # Order critical for replication setup
```

---

## 2. What is NodeIP and ClusterIP?

### Answer:

NodeIP and ClusterIP are different networking concepts in Kubernetes with distinct purposes and scopes.

**ClusterIP:**

ClusterIP is a virtual IP address assigned to a Service, providing stable internal connectivity within the cluster.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: production
spec:
  type: ClusterIP  # Default type
  clusterIP: 10.0.1.50  # Assigned from service CIDR range
  selector:
    app: api-server
  ports:
  - protocol: TCP
    port: 80              # Service port (what you connect to)
    targetPort: 8080      # Container port (where traffic goes)
    name: http
```

**ClusterIP Characteristics:**
- Virtual IP assigned by Kubernetes
- Stable and never changes (for lifetime of Service)
- Only accessible within cluster
- DNS name: `service-name.namespace.svc.cluster.local`
- Uses kube-proxy for load balancing
- No external access

```bash
# Access ClusterIP Service from within cluster
kubectl exec -it pod-name -- curl http://api-service.production.svc.cluster.local

# Service resolution
curl http://api-service:80  # Within same namespace
curl http://api-service.production:80  # Cross namespace
```

**NodeIP (Node External IP):**

NodeIP is the actual IP address of a Kubernetes worker node in the network.

```bash
# Get node IPs
kubectl get nodes -o wide

# Output:
NAME          STATUS   ROLES   IP
worker-01     Ready    <none>  10.0.1.10
worker-02     Ready    <none>  10.0.1.11
worker-03     Ready    <none>  10.0.1.12
```

**NodeIP Usage with NodePort:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-api
spec:
  type: NodePort  # Exposes on Node IP
  selector:
    app: api-server
  ports:
  - protocol: TCP
    port: 80           # ClusterIP port
    targetPort: 8080   # Container port
    nodePort: 30080    # NodeIP:nodePort accessible externally
```

**Access via NodeIP:**
```bash
# Access from outside cluster using NodeIP
curl http://10.0.1.10:30080
curl http://10.0.1.11:30080
curl http://10.0.1.12:30080

# Any node IP works (traffic routed to any pod)
# kube-proxy routes to pod regardless of node location
```

**Network Flow Diagram:**

```
External Client
    ↓
NodeIP:NodePort (10.0.1.10:30080)
    ↓
kube-proxy (iptables rules)
    ↓
ClusterIP:Port (10.0.1.50:80)
    ↓
Pod:ContainerPort (10.244.0.5:8080)
```

**Service Type Architecture:**

| Service Type | Internal IP | External IP | Use Case |
|-------------|-----------|-----------|----------|
| ClusterIP | ✅ (Virtual) | ❌ | Internal service-to-service |
| NodePort | ✅ (Virtual) | ✅ (NodeIP) | External access without LB |
| LoadBalancer | ✅ (Virtual) | ✅ (LB IP) | Production external access |
| ExternalName | ❌ | N/A | DNS alias to external service |

**Complete Networking Example:**

```yaml
# Frontend Pod
apiVersion: v1
kind: Pod
metadata:
  name: frontend-pod
  labels:
    app: frontend
spec:
  containers:
  - name: frontend
    image: nginx:latest
    ports:
    - containerPort: 80
---

# Frontend ClusterIP Service (for internal access)
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: ClusterIP
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
---

# Backend Pod
apiVersion: v1
kind: Pod
metadata:
  name: backend-pod
  labels:
    app: backend
spec:
  containers:
  - name: backend
    image: api:latest
    ports:
    - containerPort: 8080
---

# Backend ClusterIP Service (internal only)
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
---

# Frontend connects to backend via ClusterIP
# ConfigMap with backend URL
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
data:
  backend_url: "http://backend-service.default.svc.cluster.local:8080"
---

# External LoadBalancer Service for frontend
apiVersion: v1
kind: Service
metadata:
  name: frontend-lb
spec:
  type: LoadBalancer
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 80
```

---

## 3. Can you explain how your browser connects to a pod in Kubernetes?

### Answer:

Browser to pod connectivity involves multiple layers: DNS resolution, network routing, port forwarding, and load balancing.

**End-to-End Connection Flow:**

```
Browser (Client)
    ↓
OS DNS Resolution
    ↓
Cluster DNS (CoreDNS)
    ↓
Service Virtual IP (ClusterIP)
    ↓
kube-proxy (Load Balancing via iptables/IPVS)
    ↓
Pod IP
    ↓
Pod Container Port
```

**Step 1: DNS Resolution**

```bash
# Browser makes DNS request
# What user types: https://api.example.com

# Behind scenes:
1. OS recursive resolver
2. Route to external DNS (Route53, CloudFlare, etc.)
3. DNS returns external LoadBalancer IP: 203.0.113.50

# For internal Kubernetes access:
# What user types: api-service.production.svc.cluster.local

# Behind scenes:
1. Pod kubelet resolves via CoreDNS
2. CoreDNS returns ClusterIP: 10.0.1.50
```

**CoreDNS Configuration:**

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
      health
      ready
      kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
      }
      forward . /etc/resolv.conf
      cache 30
    }
```

**Step 2: Service Load Balancing (kube-proxy)**

Two mechanisms: iptables (default) or IPVS

**iptables Load Balancing:**

```bash
# kube-proxy creates iptables rules
# Example rules for service api-service with endpoints 10.244.1.5:8080, 10.244.1.6:8080

# Chain: KUBE-SERVICES
iptables -A KUBE-SERVICES -d 10.0.1.50 -p tcp -m tcp --dport 80 \
  -j KUBE-SVC-ABC123

# Chain: KUBE-SVC-ABC123 (random selection between endpoints)
iptables -A KUBE-SVC-ABC123 -m statistic --mode random --probability 0.5 \
  -j KUBE-SEP-POD1
iptables -A KUBE-SVC-ABC123 \
  -j KUBE-SEP-POD2

# Chain: KUBE-SEP-POD1 (DNAT to pod)
iptables -A KUBE-SEP-POD1 -p tcp -m tcp \
  -j DNAT --to-destination 10.244.1.5:8080

# Chain: KUBE-SEP-POD2 (DNAT to pod)
iptables -A KUBE-SEP-POD2 -p tcp -m tcp \
  -j DNAT --to-destination 10.244.1.6:8080
```

**Step 3: Network Routing to Pod Network**

```
Packet Flow:
Source: 203.0.113.50:50000 (External)
Destination: 10.0.1.50:80 (Service)
    ↓
iptables DNAT rewrites destination
    ↓
New Destination: 10.244.1.5:8080 (Pod)
    ↓
Overlay network (Flannel, Weave, Calico)
    ↓
Pod network interface receives packet
    ↓
Container process listening on 8080
```

**Step 4: External Ingress (Browser to Cluster)**

```yaml
# LoadBalancer Service (AWS/Azure/GCP)
apiVersion: v1
kind: Service
metadata:
  name: web-api
spec:
  type: LoadBalancer
  selector:
    app: api-server
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

**External Load Balancer Flow:**

```
Browser Request
    ↓
External Domain: api.example.com → 203.0.113.50
    ↓
AWS/GCP/Azure Load Balancer (203.0.113.50)
    ↓
Load Balancer selects target Node (kube-proxy rule)
    ↓
Forwards packet to NodeIP:NodePort (10.0.1.10:30000)
    ↓
kube-proxy translates to ClusterIP:Port (10.0.1.50:80)
    ↓
iptables DNAT to Pod IP (10.244.1.5:8080)
    ↓
Pod container receives request
```

**Step 5: Pod Processing and Response**

```yaml
# Pod receiving request:
apiVersion: v1
kind: Pod
metadata:
  name: api-server-pod-xyz
spec:
  containers:
  - name: api-server
    image: api:v1.0
    ports:
    - containerPort: 8080  # Container listening here
    env:
    - name: PORT
      value: "8080"
```

**Response Flow (Reverse Path):**

```
Pod container processes request
    ↓
Response packet created (source: 10.244.1.5:8080, dest: original client)
    ↓
Overlay network routes to node
    ↓
Node network interface sends out
    ↓
Reverse NAT applied (source rewritten to LoadBalancer IP)
    ↓
External client receives response
```

**Practical Browser Connection Example:**

```bash
# User opens browser and navigates to:
# https://api.example.com/users

# Behind the scenes:

# 1. Browser DNS lookup
dig api.example.com
# Returns: 203.0.113.50 (AWS Load Balancer)

# 2. Browser makes HTTPS connection
# Establishes TCP connection to 203.0.113.50:443

# 3. Load Balancer (AWS)
# - Receives connection on 203.0.113.50:443
# - Routes to backend target group
# - Selects worker node: 10.0.1.10 (round-robin)
# - Forwards to NodePort: 10.0.1.10:30443

# 4. kube-proxy on worker node
# - Receives packet on NodePort 30443
# - Applies iptables rules
# - Looks up service endpoints
# - Randomly selects pod endpoint: 10.244.1.5:8080

# 5. Packet reaches pod
# - Network overlay delivers packet to pod network interface
# - Container listens on 8080 receives request
# - Application processes /users endpoint

# 6. Response sent back
# - Through reverse path (NAT applied)
# - Browser receives response

# Total latency: ~50-200ms depending on:
# - DNS resolution (cached or not)
# - Network distance
# - Load Balancer processing
# - Container processing time
```

**Debugging Connection Issues:**

```bash
# 1. Check DNS resolution
kubectl exec pod-name -- nslookup api-service.production.svc.cluster.local

# 2. Check service endpoints
kubectl get endpoints api-service -n production

# 3. Check iptables rules (on node)
iptables -L -t nat | grep KUBE

# 4. Test pod connectivity
kubectl exec -it pod-name -- curl http://api-service:80

# 5. Check kube-proxy status
kubectl get daemonset kube-proxy -n kube-system
kubectl logs -n kube-system daemonset/kube-proxy

# 6. Verify overlay network
kubectl get nodes -o wide
kubectl get pods -o wide

# 7. Test from external client
# If NodePort exposed:
curl http://10.0.1.10:30080

# 8. Check network policies blocking traffic
kubectl get networkpolicies -n production
```

---

## 4. Deployment in production is broken. What are the steps we can take?

### Answer:

Systematic troubleshooting and recovery procedures are essential for restoring production services quickly.

**Step 1: Immediate Assessment (First 2 minutes)**

```bash
# Check service status
kubectl get deployments -n production
kubectl get pods -n production
kubectl get svc -n production

# Check pod events and recent changes
kubectl describe deployment myapp -n production
kubectl get events -n production --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -f -l app=myapp -n production --tail=100
kubectl logs -f -l app=myapp -n production --previous  # Crashed pods

# Check node status
kubectl get nodes
kubectl top nodes

# Quick health check
curl http://service-ip:port/health 2>&1
```

**Step 2: Identify Root Cause (Next 5 minutes)**

```bash
# Scenario 1: Pod CrashLoopBackOff
kubectl describe pod pod-name -n production
# Look for: Reason, Last State, Exit Code

# Diagnostic:
- Exit code 0: Application exited normally (unexpected)
- Exit code 1: Application error
- Exit code 127: Command not found
- OOMKilled: Out of memory
- Error mounting volume: Storage issue

# Check logs for error details
kubectl logs pod-name -n production --previous

# Scenario 2: Pending Pods
kubectl describe pod pod-name -n production
# Look for: Events section, PVC not found, Insufficient resources

# Check resource availability
kubectl top nodes
kubectl describe nodes | grep -A 20 "Allocated Resources"

# Scenario 3: Service Unreachable
kubectl get svc myapp -n production
kubectl get endpoints myapp -n production
# Endpoints should show pod IPs

# If no endpoints:
kubectl get pods -n production -o wide -l app=myapp
kubectl describe svc myapp -n production

# Scenario 4: Network Issues
# Check network policies blocking traffic
kubectl get networkpolicies -n production
kubectl get networkpolicies -n production -o yaml

# Test pod-to-pod connectivity
kubectl exec pod1 -n production -- curl pod2-ip:port
```

**Step 3: Review Recent Changes**

```bash
# Check recent deployments
kubectl rollout history deployment/myapp -n production

# View specific revision
kubectl rollout history deployment/myapp -n production --revision=3

# Check differences between revisions
kubectl rollout history deployment/myapp -n production -o yaml

# Check git commit history
git log --oneline -10

# Check helm releases if using Helm
helm history myapp -n production

# Review events in last 30 minutes
kubectl get events -n production --sort-by='.lastTimestamp' | tail -50
```

**Step 4: Immediate Recovery Options**

**Option A: Rollback to Previous Version**

```bash
# Kubernetes automatic rollback
kubectl rollout undo deployment/myapp -n production

# Rollback to specific version
kubectl rollout undo deployment/myapp -n production --to-revision=2

# Verify rollback
kubectl rollout status deployment/myapp -n production
kubectl rollout history deployment/myapp -n production

# With Helm
helm rollback myapp 1 -n production
```

**Option B: Scale Down and Investigate**

```bash
# Reduce replicas to single pod for debugging
kubectl scale deployment myapp --replicas=1 -n production

# Get into the pod
kubectl exec -it pod-name -n production -- /bin/bash

# Run diagnostics
- Check environment variables
- Verify config mounts
- Test database connectivity
- Check filesystem permissions
```

**Option C: Emergency Manual Fix**

```bash
# Patch image tag back to working version
kubectl set image deployment/myapp \
  myapp=myregistry/myapp:v1.5.0 \
  -n production

# Or update deployment YAML
kubectl edit deployment myapp -n production
# Then change image: myregistry/myapp:v1.6.0 → myregistry/myapp:v1.5.0
```

**Option D: Install from Backup Configuration**

```bash
# If deployment corrupted, restore from version control
git checkout HEAD~1 deploy/myapp-deployment.yaml
kubectl apply -f deploy/myapp-deployment.yaml -n production

# Or restore from Helm chart backup
helm install myapp ./myapp-chart \
  -n production \
  --force \
  --recreate-pods
```

**Step 5: Detailed Troubleshooting Scenarios**

**Scenario: Database Connection Failure**

```bash
# Symptoms: Pods crashing, logs show "Connection refused"

# Diagnostics:
kubectl logs deployment/myapp -n production | grep -i database
kubectl exec pod-name -n production -- mysql -h db-host -u user -p

# Checks:
1. Database service is running
   kubectl get svc postgres -n production
   kubectl exec pod-name -- nslookup postgres

2. Network policy allows traffic
   kubectl get networkpolicies -n production
   kubectl describe networkpolicy allow-db -n production

3. Database credentials correct
   kubectl get secret db-credentials -n production -o yaml
   kubectl exec pod-name -n production -- env | grep DB_

4. Network connectivity
   kubectl exec pod-name -n production -- telnet db-host 5432

# Recovery:
kubectl restart deployment/myapp -n production --cascade=background
```

**Scenario: Out of Memory (OOMKilled)**

```bash
# Symptoms: Pods repeatedly killed, status shows OOMKilled

# Diagnostics:
kubectl describe pod pod-name -n production | grep -i "OOM"
kubectl top pods -n production
kubectl top nodes

# Identify memory consumers:
kubectl top pods -n production --sort-by=memory

# Fix options:
1. Increase memory limits
   kubectl set resources deployment/myapp \
     --limits=memory=2Gi \
     -n production

2. Reduce replica count (less total memory)
   kubectl scale deployment/myapp --replicas=2 -n production

3. Optimize application memory usage
   - Review code for memory leaks
   - Update to smaller base image
   - Enable memory limits in app config
```

**Scenario: Persistent Volume Mount Failure**

```bash
# Symptoms: Pod pending, events show "Unable to attach volume"

# Diagnostics:
kubectl describe pod pod-name -n production
kubectl get pvc -n production
kubectl get pv

# Check PVC status:
kubectl describe pvc pvc-name -n production

# Check storage capacity:
kubectl get pvc -n production
# Look for: "Pending", "Terminating"

# Fix volume issues:
1. Wait for storage provisioning (can take 2-5 min)
   watch kubectl get pod pod-name -n production

2. Delete and recreate PVC (if stuck)
   kubectl delete pvc pvc-name -n production
   # PVC will be recreated by volumeClaimTemplate

3. Check storage class
   kubectl get storageclass
   kubectl describe storageclass standard -n production
```

**Step 6: Validation & Monitoring Post-Recovery**

```bash
# Verify deployment healthy
kubectl rollout status deployment/myapp -n production
kubectl get pods -n production -l app=myapp

# Check logs for errors
kubectl logs -f deployment/myapp -n production | head -50

# Verify connectivity
SVCIP=$(kubectl get svc myapp -n production -o jsonpath='{.spec.clusterIP}')
kubectl run -it debug --image=curlimages/curl --restart=Never -- \
  curl http://$SVCIP:8080/health

# Check metrics
watch -n 1 'kubectl top pods -n production -l app=myapp'

# Tail application logs
kubectl logs -f -l app=myapp -n production --all-containers=true

# Set up monitoring alerts
# Ensure prometheus scraping the service
# Verify alert rules firing correctly
```

**Step 7: Post-Incident Analysis**

```bash
# Document timeline
kubectl get events -n production | grep myapp

# Capture pod logs for analysis
kubectl logs -l app=myapp -n production --previous > pod-logs.txt

# Review deployment history
kubectl rollout history deployment/myapp -n production > history.txt

# Export deployment state
kubectl get deployment myapp -n production -o yaml > myapp-deploy.yaml

# Create incident report:
1. What time did it break?
2. What changed before it broke?
3. How long was service down?
4. What was the fix?
5. How to prevent recurrence?

# Prevention measures:
- Add readiness/liveness probes
- Increase monitoring coverage
- Add load testing to CI/CD
- Implement gradual rollout strategy
- Set resource requests/limits
- Enable network policies
```

**Complete Recovery Checklist:**

```bash
☐ Assess current state (pods, services, nodes)
☐ Check logs for error messages
☐ Review recent changes/deployments
☐ Identify root cause
☐ Rollback to known-good version OR apply fix
☐ Verify pods running and healthy
☐ Verify service endpoints populated
☐ Test connectivity
☐ Monitor metrics for stabilization
☐ Declare incident resolved
☐ Conduct post-incident review
☐ Update runbooks with new learnings
```

---

## 5. Explain Blue-Green and Canary deployment.

### Answer:

Blue-Green and Canary are deployment strategies that minimize risk and enable rapid rollback for production updates.

**Blue-Green Deployment:**

Two identical production environments (Blue and Green) where one is active and one is standby.

```yaml
# Blue Environment (Current Active)
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  type: LoadBalancer
  selector:
    version: blue  # Route to blue pods
  ports:
  - port: 80
    targetPort: 8080
---

# Blue Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: myapp
        image: myregistry/myapp:v1.5.0  # Current version
        ports:
        - containerPort: 8080
---

# Green Deployment (New Version, Not Active)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: myapp
        image: myregistry/myapp:v1.6.0  # New version
        ports:
        - containerPort: 8080
```

**Blue-Green Deployment Process:**

```
1. CURRENT STATE
   Service routes to: Blue (v1.5.0)
   Green: Idle or running v1.5.0

2. PREPARE GREEN
   Deploy v1.6.0 to Green environment
   Run full test suite against Green
   Green passes all tests

3. CUT OVER
   Update Service selector: label version: green
   All traffic now routes to Green (v1.6.0)
   Instant switchover (zero downtime)

4. MONITOR
   Check error rates, latency, logs
   Monitor for ~15-30 minutes
   If issues: Instant rollback (switch back to blue)

5. CLEANUP
   If Green stable: Keep as backup or redeploy Blue with v1.6.0
   Blue becomes new standby
```

**Blue-Green Switchover Script:**

```bash
#!/bin/bash

NEW_VERSION=$1  # e.g., v1.6.0
NAMESPACE="production"

# 1. Deploy new version to green
kubectl set image deployment/myapp-green \
  myapp=myregistry/myapp:${NEW_VERSION} \
  -n ${NAMESPACE}

# 2. Wait for green to be ready
kubectl rollout status deployment/myapp-green -n ${NAMESPACE}

# 3. Run health checks against green
GREEN_POD=$(kubectl get pod -n ${NAMESPACE} -l version=green -o jsonpath='{.items[0].metadata.name}')
kubectl exec ${GREEN_POD} -n ${NAMESPACE} -- curl http://localhost:8080/health

# 4. Run smoke tests
kubectl run -it smoke-test --image=curlimages/curl --restart=Never \
  -n ${NAMESPACE} -- curl http://myapp-green:8080/api/test

if [ $? -ne 0 ]; then
  echo "Health checks failed! Aborting switch."
  exit 1
fi

# 5. Switch traffic from blue to green
kubectl patch service myapp -n ${NAMESPACE} \
  -p '{"spec":{"selector":{"version":"green"}}}'

echo "Switched to green (${NEW_VERSION})"

# 6. Monitor for 5 minutes
sleep 300

# Check error rates during monitoring
ERROR_RATE=$(kubectl logs -l version=green -n ${NAMESPACE} --tail=1000 | grep -c "ERROR")

if [ ${ERROR_RATE} -gt 10 ]; then
  echo "High error rate detected! Rolling back to blue."
  kubectl patch service myapp -n ${NAMESPACE} \
    -p '{"spec":{"selector":{"version":"blue"}}}'
  exit 1
fi

echo "Green deployment successful!"
```

**Blue-Green Advantages & Disadvantages:**

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| Rollback | Instant (1-2 seconds) | Requires duplicate infrastructure |
| Risk | Very low, quick abort | 2x resource usage |
| Testing | Full environment testing | Mirrors prod but not live |
| Downtime | Zero | N/A |
| Complexity | Medium | Requires load balancer |

---

**Canary Deployment:**

Gradually shift traffic from old version to new version, catching issues early with small user impact.

```yaml
# Service (routes to both blue and canary based on weight)
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
---

# Stable Blue Deployment (90% of traffic initially)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
  namespace: production
spec:
  replicas: 9  # 90% of total replicas
  selector:
    matchLabels:
      app: myapp
      version: stable
  template:
    metadata:
      labels:
        app: myapp
        version: stable
    spec:
      containers:
      - name: myapp
        image: myregistry/myapp:v1.5.0
        ports:
        - containerPort: 8080
---

# Canary Deployment (10% of traffic initially)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
  namespace: production
spec:
  replicas: 1  # 10% of total replicas
  selector:
    matchLabels:
      app: myapp
      version: canary
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
      - name: myapp
        image: myregistry/myapp:v1.6.0
        ports:
        - containerPort: 8080
```

**Canary Deployment Steps:**

```
1. BASELINE
   Stable (v1.5.0): 10 replicas (100% traffic)
   Canary (v1.6.0): 0 replicas (0% traffic)
   Objective: Stable with baseline metrics

2. INITIAL CANARY
   Stable (v1.5.0): 9 replicas (90% traffic)
   Canary (v1.6.0): 1 replica (10% traffic)
   Monitor: ~100 requests hit canary version
   Check metrics against baseline

3. EXPAND CANARY
   Stable (v1.5.0): 5 replicas (50% traffic)
   Canary (v1.6.0): 5 replicas (50% traffic)
   Monitor: ~1000 requests hit canary version
   Validate: Error rates within 0.1% of baseline

4. FINALIZE
   Stable (v1.5.0): 0 replicas (retired)
   Canary (v1.6.0): 10 replicas (100% traffic)
   Declare: Rollout complete

5. MONITOR
   Watch for 1 hour post-deployment
   If issues: Scale canary down, scale stable up
```

**Canary Deployment Script (Fluxed/Progressive):**

```bash
#!/bin/bash

NEW_VERSION=$1
NAMESPACE="production"
TOTAL_REPLICAS=10

# Track metrics function
check_metrics() {
  local version=$1
  local error_rate=$(kubectl logs -l version=${version} -n ${NAMESPACE} \
    --tail=1000 | grep -c "ERROR") 
  local latency=$(kubectl top pod -l version=${version} -n ${NAMESPACE} \
    | awk '{sum+=$4; count++} END {print sum/count}')
  echo "Error Rate: ${error_rate}/1000, Avg Latency: ${latency}ms"
}

# Phase 1: 10% canary
echo "Phase 1: 10% canary (1/10 replicas)"
kubectl scale deployment myapp-stable --replicas=9 -n ${NAMESPACE}
kubectl scale deployment myapp-canary --replicas=1 -n ${NAMESPACE}
sleep 60
check_metrics "canary"

# Phase 2: 50% canary
echo "Phase 2: 50% canary (5/10 replicas)"
kubectl scale deployment myapp-stable --replicas=5 -n ${NAMESPACE}
kubectl scale deployment myapp-canary --replicas=5 -n ${NAMESPACE}
sleep 120
check_metrics "canary"

# Phase 3: 100% canary (full deployment)
echo "Phase 3: 100% canary (10/10 replicas)"
kubectl scale deployment myapp-stable --replicas=0 -n ${NAMESPACE}
kubectl scale deployment myapp-canary --replicas=10 -n ${NAMESPACE}
sleep 180
check_metrics "canary"

echo "Canary deployment complete!"
```

**Canary with Service Mesh (Istio):**

```yaml
# More sophisticated canary with traffic routing rules
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp
  namespace: production
spec:
  hosts:
  - myapp
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: myapp
        subset: v1  # Stable
      weight: 90
    - destination:
        host: myapp
        subset: v2  # Canary
      weight: 10
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp
  namespace: production
spec:
  host: myapp
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

**Canary Advantages & Disadvantages:**

| Aspect | Advantage | Disadvantage |
|--------|-----------|--------------|
| Risk | Minimal (affects 10%) | Slower (gradual rollout) |
| Monitoring | Real traffic validation | Complex metrics collection |
| Rollback | Can scale down instantly | May need code cleanup |
| Resources | Same resource usage | N/A |
| Complexity | Can be automated | Requires metrics analysis |

**Comparison: Blue-Green vs Canary**

| Factor | Blue-Green | Canary |
|--------|-----------|--------|
| Time to Deploy | Minutes | Hours |
| Rollback Time | Seconds (instant) | Minutes |
| Resource Overhead | 100% (2x) | 0-20% (during ramp) |
| Risk | Low | Very Low |
| User Impact if Bug | All users for seconds | <10% for extended time |
| Testing Capability | Full environment test | Real production test |
| Best For | Large, risky changes | Incremental updates |

---

## 6. Let's say I have a container that needs to be deployed to production. How to do this?

### Answer:

Production container deployment requires security, validation, automation, and monitoring at every step.

**Step 1: Build Container with Security**

**Dockerfile Best Practices:**

```dockerfile
# Multi-stage build for smaller image
FROM golang:1.20-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o myapp

# Final stage - minimal attack surface
FROM alpine:3.18
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/myapp /usr/local/bin/
EXPOSE 8080
USER appuser
ENTRYPOINT ["myapp"]

# Security scanning
# - Use specific base image versions (not 'latest')
# - Run as non-root user
# - Remove unnecessary packages
# - Minimize layer count
```

**Security Scanning Before Push:**

```bash
# Scan for vulnerabilities (Trivy, Snyk)
trivy image --severity HIGH,CRITICAL myapp:v1.0.0

# Scan for hardcoded secrets
git secrets scan

# Container composition analysis
dive myapp:v1.0.0
```

**Step 2: Push to Secure Registry**

```bash
# Tag image with version
docker build -t myregistry.azurecr.io/myapp:v1.0.0 .
docker build -t myregistry.azurecr.io/myapp:latest .

# Sign image (optional but recommended)
docker trust signer add --key ~/.docker/notary-key.key myregistry.azurecr.io/myapp

# Push to registry
docker push myregistry.azurecr.io/myapp:v1.0.0
docker push myregistry.azurecr.io/myapp:latest

# Registry security checks
# - Enable vulnerability scanning on push
# - Enforce image signing
# - Set retention policies
# - Enable audit logging
```

**Step 3: Create Kubernetes Manifests**

**Complete Production Deployment:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
---

# ConfigMap for application config
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  LOG_LEVEL: "INFO"
  CACHE_TTL: "3600"
  application.properties: |
    server.port=8080
    server.servlet.context-path=/api
---

# Secret for credentials (use external secret management in production)
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: production
type: Opaque
data:
  database_password: cGFzc3dvcmQxMjM=  # base64 encoded
  api_key: YWJjZGVmZ2hp
---

# ServiceAccount for pod identity
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp-sa
  namespace: production
---

# Role for RBAC
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: myapp-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
---

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myapp-rolebinding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: myapp-role
subjects:
- kind: ServiceAccount
  name: myapp-sa
  namespace: production
---

# Service for internal connectivity
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
spec:
  type: ClusterIP
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
---

# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
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
---

# PodDisruptionBudget for high availability
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
---

# Main Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
  labels:
    app: myapp
    version: v1.0.0
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: myapp
  
  template:
    metadata:
      labels:
        app: myapp
        version: v1.0.0
      annotations:
        prometheus.io/scrape: "true"
    
    spec:
      serviceAccountName: myapp-sa
      
      # Security context for pod
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      
      # Affinity rules for pod distribution
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
                  - myapp
              topologyKey: kubernetes.io/hostname
      
      # Node selection
      nodeSelector:
        workload: general
      
      # Init containers for setup
      initContainers:
      - name: db-migration
        image: myregistry.azurecr.io/myapp:v1.0.0
        command: ["./migrate.sh"]
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database_password
      
      # Main application container
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:v1.0.0
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        
        # Environment variables
        env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: LOG_LEVEL
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database_password
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        
        # Volume mounts
        volumeMounts:
        - name: config
          mountPath: /etc/config
          readOnly: true
        - name: cache
          mountPath: /tmp/cache
        
        # Resource requests and limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Liveness probe - restart if unhealthy
        livenessProbe:
          httpGet:
            path: /health/live
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness probe - remove from load balance if not ready
        readinessProbe:
          httpGet:
            path: /health/ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Container security context
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
      
      # Volumes
      volumes:
      - name: config
        configMap:
          name: myapp-config
      - name: cache
        emptyDir:
          sizeLimit: 1Gi
      
      # Image pull secrets for private registry
      imagePullSecrets:
      - name: registry-credentials
      
      # Termination grace period for graceful shutdown
      terminationGracePeriodSeconds: 30
---

# External Service for production traffic (LoadBalancer)
apiVersion: v1
kind: Service
metadata:
  name: myapp-lb
  namespace: production
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
  sessionAffinity: None
---

# Ingress for HTTP/HTTPS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: production
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - api.example.com
    secretName: myapp-tls
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
---

# NetworkPolicy for security
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-netpol
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443  # HTTPS for external APIs
    - protocol: TCP
      port: 5432  # Database
```

**Step 4: Validation Before Deployment**

```bash
# Validate manifests
kubectl apply -f deployment.yaml --dry-run=client -o yaml

# Lint manifests (kubelint)
kubint deployment.yaml

# Scan for policy violations
kyverno apply clusterPolicy.yaml -r deployment.yaml

# Check for security issues
kubesec scan deployment.yaml

# Policy checks
conftest test -p /policies deployment.yaml
```

**Step 5: Deploy to Production**

**Option A: Direct Apply**

```bash
# Apply all manifests
kubectl apply -f deployment.yaml -n production

# Monitor rollout
kubectl rollout status deployment/myapp -n production
watch kubectl get pods -n production -l app=myapp
```

**Option B: Using Helm (Recommended)**

```bash
# Install release
helm install myapp ./myapp-chart \
  -n production \
  -f values-prod.yaml \
  --create-namespace

# Verify deployment
helm status myapp -n production
helm get values myapp -n production
```

**Option C: GitOps with Flux/ArgoCD**

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: production
  source:
    repoURL: https://github.com/company/myapp-deploy.git
    path: k8s/production
    kustomize:
      version: v4.5.4
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

**Step 6: Post-Deployment Validation**

```bash
# Check pods running
kubectl get pods -n production -l app=myapp
kubectl describe pod -n production -l app=myapp | head -50

# Check service endpoints
kubectl get endpoints myapp -n production

# Test connectivity
POD=$(kubectl get pod -n production -l app=myapp -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -n production -- curl http://localhost:8080/health

# Check logs
kubectl logs -f deployment/myapp -n production

# Monitor metrics
kubectl top pod -n production -l app=myapp
kubectl top nodes

# Verify ingress
curl -v https://api.example.com/health

# Load testing (validate under real traffic)
ab -n 1000 -c 50 https://api.example.com/
```

**Step 7: Monitoring & Alerts**

```bash
# Verify metrics collection
kubectl port-forward svc/myapp 8080:80 -n production &
curl http://localhost:8080/metrics

# Check prometheus targets
# Access Prometheus UI → Status → Targets

# Create alert rules
kubectl apply -f alert-rules.yaml -n monitoring

# Verify alert firing
# Access AlertManager → Check active alerts
```

---

## 7. What is your CI/CD framework and what is your role?

### Answer:

As a DevOps engineer with 5-10 years of experience, I have designed and maintained comprehensive CI/CD frameworks leveraging modern tools and best practices.

**CI/CD Framework Architecture:**

```
┌─────────────────────────────────────────┐
│        Source Control (GitHub)          │
│  - Code commit triggers webhook         │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│         Build & Test Stage              │
│  - Jenkins / GitLab CI / GitHub Actions │
│  - Compile code, run tests              │
│  - Static analysis (SonarQube)          │
│  - Build artifacts                      │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│      Push to Container Registry         │
│  - Docker image build & scan            │
│  - Push to ECR/ACR/Harbor               │
│  - Sign image                           │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│    Staging Deployment & Testing         │
│  - Deploy to staging K8s cluster        │
│  - Run integration tests                │
│  - Performance testing                  │
│  - Security scanning                    │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│    Approval & Production Deployment     │
│  - Manual approval gate                 │
│  - Blue-Green or Canary deployment      │
│  - Automated rollback on failure        │
└────────┬────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────┐
│    Monitoring & Observability           │
│  - Prometheus metrics                   │
│  - ELK stack logging                    │
│  - Alert on anomalies                   │
│  - Auto-remediation                     │
└─────────────────────────────────────────┘
```

**My Role & Responsibilities:**

**1. Pipeline Design & Implementation**

- Architecture multi-stage CI/CD pipelines
- Design for scalability, reliability, security
- Implement parallel execution for faster feedback
- Enable self-service for development teams

**Example: Jenkins Pipeline Structure**

```groovy
@Library('shared-pipeline-library@main') _

pipeline {
    agent {
        kubernetes {
            label 'docker'
            yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: docker
                image: docker:20.10
                command: ["cat"]
                tty: true
              - name: kubectl
                image: bitnami/kubectl:latest
                command: ["cat"]
                tty: true
            '''
        }
    }
    
    options {
        timeout(time: 1, unit: 'HOURS')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        string(name: 'VERSION', description: 'Release version')
    }
    
    environment {
        REGISTRY = 'myregistry.azurecr.io'
        APP_NAME = 'myapp'
        BUILD_VERSION = "${env.BUILD_NUMBER}-${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build & Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        buildApp(language: 'java')
                    }
                }
                stage('Code Quality') {
                    steps {
                        scanCode(projectKey: env.APP_NAME)
                    }
                }
            }
        }
        
        stage('Build Image') {
            steps {
                container('docker') {
                    sh '''
                        docker build -t ${REGISTRY}/${APP_NAME}:${BUILD_VERSION} .
                        docker scan ${REGISTRY}/${APP_NAME}:${BUILD_VERSION}
                    '''
                }
            }
        }
        
        stage('Push Image') {
            steps {
                container('docker') {
                    sh '''
                        docker push ${REGISTRY}/${APP_NAME}:${BUILD_VERSION}
                    '''
                }
            }
        }
        
        stage('Deploy Staging') {
            when {
                branch 'develop'
            }
            steps {
                deployApp([
                    environment: 'staging',
                    version: env.BUILD_VERSION
                ])
            }
        }
        
        stage('Deploy Production') {
            when {
                branch 'main'
            }
            input {
                message "Deploy to production?"
                ok "Deploy"
                submitter "devops-team"
            }
            steps {
                deployApp([
                    environment: 'production',
                    version: env.BUILD_VERSION,
                    strategy: 'blue-green'
                ])
            }
        }
    }
    
    post {
        always {
            junit '**/target/surefire-reports/*.xml'
            publishHTML([
                reportDir: 'target/site/jacoco',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ])
        }
        success {
            slackMessage(channel: '#deployments', 
                message: "✅ ${APP_NAME} deployed successfully")
        }
        failure {
            slackMessage(channel: '#deployments', 
                message: "❌ ${APP_NAME} deployment failed")
        }
    }
}
```

**2. Tool Stack Management**

**CI/CD Tools I Manage:**

- **Jenkins**: Orchestration, pipeline execution
- **GitHub Actions**: Lightweight CI, cost-effective
- **GitLab CI**: Integrated with version control
- **Docker**: Container build and registry
- **Kubernetes**: Deployment and orchestration
- **Helm**: Kubernetes package management
- **Terraform**: Infrastructure as Code
- **Prometheus/Grafana**: Monitoring
- **Datadog/New Relic**: APM and observability
- **PagerDuty**: Incident management
- **Slack**: Team notifications

**3. Security Integration**

```groovy
// Security scanning in pipeline
stage('Security Scanning') {
    parallel {
        stage('Container Scan') {
            steps {
                sh 'trivy image --severity HIGH,CRITICAL ${image}'
            }
        }
        stage('SAST Analysis') {
            steps {
                sh 'sonarqube scan'
            }
        }
        stage('Dependency Check') {
            steps {
                sh 'snyk test'
            }
        }
        stage('Secret Scanning') {
            steps {
                sh 'git secrets scan'
            }
        }
    }
}
```

**4. Release Management**

- Version control (semantic versioning)
- Release notes generation
- Artifact management
- Automated changelog

```bash
# Release process
git tag -a v1.5.0 -m "Release version 1.5.0"
git push origin v1.5.0
# Automatically triggers release pipeline
```

**5. Team Enablement**

- Shared libraries for common patterns
- Self-service pipeline templates
- Documentation and runbooks
- Training and onboarding

**My Contributions & Impact:**

```
1. Build Speed Improvement
   - Before: 45 min per build
   - After: 12 min per build (73% reduction)
   - Method: Parallelization + caching

2. Deployment Frequency
   - Before: 2x per week
   - After: 10x per day (5x increase)
   - Method: Automated gates + blue-green deployment

3. Production Incidents Reduced
   - From 5-10 per week to 1-2 per week
   - Method: Better testing + automated rollback

4. Infrastructure as Code
   - 100% of infrastructure in Git
   - Full audit trail + versioning
   - Disaster recovery in minutes

5. Security Improvements
   - Container image scanning
   - Secret rotation automation
   - Compliance reporting

6. Cost Optimization
   - Resource optimization: 40% reduction
   - Reserved instances + spot instances
   - Auto-scaling implementation
```

---

## 8. How do you approach architecting a deployment?

### Answer:

Deployment architecture requires balancing multiple concerns: reliability, scalability, security, cost, and complexity.

**Architecture Assessment Framework:**

**1. Requirements Gathering**

```yaml
Requirements Checklist:
  Functional:
    - Performance requirements (throughput, latency)
    - Availability target (99.9%, 99.99%)
    - Scalability (peak load, growth rate)
    - Data retention (GDPR, compliance)
  
  Non-Functional:
    - Security requirements (encryption, access control)
    - Compliance (SOC2, ISO, PCI-DSS)
    - Disaster recovery (RTO, RPO)
    - Disaster recovery (costs, resources)
  
  Operational:
    - Team size and expertise
    - On-call requirements
    - Deployment frequency
    - Monitoring and alerting
```

**2. Reference Architecture Design**

**Multi-Tier Architecture:**

```
┌────────────────────────────────────────┐
│         CDN & WAF Layer                │
│  - DDoS protection                     │
│  - Static content caching              │
│  - SSL/TLS termination                 │
└────────────────┬───────────────────────┘
                 │
┌────────────────┴───────────────────────┐
│    Load Balancer (ALB/NLB)             │
│  - Distributes traffic                 │
│  - Health checks                       │
│  - SSL offloading                      │
└────────────────┬───────────────────────┘
                 │
┌────────────────┴───────────────────────┐
│   Kubernetes Cluster (Multiple AZs)    │
│  ┌─────────────────────────────────┐   │
│  │   API Gateway / Ingress         │   │
│  │  - Route requests               │   │
│  │  - Enforce rate limiting        │   │
│  └──────┬──────────────┬───────────┘   │
│         │              │                │
│    ┌────▼──┐      ┌────▼──┐            │
│    │Service │      │Service │           │
│    │Pods    │      │Pods    │           │
│   ─┘────────┘─    ─┘────────┘──        │
│                                         │
└────────────────┬───────────────────────┘
                 │
┌────────────────┴───────────────────────┐
│      Data Layer                        │
│  ┌──────────────────────────────────┐  │
│  │ Primary Database (RDS, PostgreSQL)│  │
│  │  - Automated backups              │  │
│  │  - Multi-AZ replication           │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ Cache (Redis)                     │  │
│  │  - Session management             │  │
│  │  - Rate limiting                  │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │ Message Queue (Kafka, RabbitMQ)  │  │
│  │  - Async processing               │  │
│  │  - Event streaming                │  │
│  └──────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

**3. High Availability Design**

```yaml
HA Principles:
  - Multi-AZ Deployment: At least 2 availability zones
  - No Single Point of Failure: Redundancy at each layer
  - Graceful Degradation: Service continues partially if components fail
  - Automated Failover: Self-healing without manual intervention
  - Health Checks: Continuous validation of service health

Example Multi-AZ K8s Deployment:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
spec:
  replicas: 3
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - api-service
        topologyKey: topology.kubernetes.io/zone
        # Ensures pods spread across different AZs

  template:
    spec:
      # Pod distributed across zones automatically
      nodeSelector:
        karpenter.sh/zone: us-east-1a OR us-east-1b OR us-east-1c
```

**4. Disaster Recovery Planning**

```yaml
RTO (Recovery Time Objective): 15 minutes
RPO (Recovery Point Objective): 5 minutes

Backup Strategy:
  - Database: Daily snapshots + continuous replication
  - Configuration: Version controlled in Git
  - Secrets: Encrypted in vault + replicated
  - State: Regular backups to S3 with versioning

Disaster Scenarios:
  1. Zone Failure
     - Pod rescheduling to healthy zones (automatic)
     - Time: < 60 seconds
  
  2. Database Failure
     - Backup restore to specific point-in-time
     - Time: 5-10 minutes
  
  3. Correlated Failure (entire cluster)
     - Restore from backup to new cluster
     - Time: 15-30 minutes
     - Use GitOps (ArgoCD) for automated restoration

Testing:
  - Quarterly disaster recovery drills
  - Automated canaries for failure scenarios
  - Chaos engineering (kill pods, nodes, etc.)
```

**5. Scaling Strategy**

```yaml
Vertical Scaling (Pod-level):
  - Increase CPU/memory requests/limits
  - Requires pod restart
  - Used for: Long-running jobs, batch processing

Horizontal Scaling (Replica-level):
  - Add more pod replicas
  - No downtime
  - Automatic via HPA

Cluster Scaling (Node-level):
  - Add more worker nodes
  - Automatic via cluster autoscaler
  - Cost optimization via spot instances

Auto-Scaling Configuration:
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
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
  - type: Pods
    pods:
      metric:
        name: custom_request_latency
      target:
        type: AverageValue
        averageValue: 1000m
```

**6. Security Architecture**

```yaml
Defense in Depth:

1. Network Layer
   - VPC with private subnets
   - Security groups (firewall rules)
   - NetworkPolicy (Kubernetes-level)
   - WAF at load balancer

2. Application Layer
   - Input validation
   - SQL injection prevention
   - Rate limiting
   - CORS policies

3. Container Layer
   - Image scanning
   - Runtime security
   - Non-root user enforcement
   - Read-only filesystems

4. Access Control
   - RBAC for Kubernetes
   - IAM roles for cloud resources
   - MFA for deployments
   - Audit logging

5. Secrets Management
   - Never in code/Git
   - HashiCorp Vault
   - Encrypted at rest & in transit
   - Automatic rotation
```

**7. Cost Optimization**

```yaml
Strategies:
  - Right-sizing instances (not over-provisioning)
  - Reserved instances for baseline load
  - Spot instances for non-critical workloads
  - Scheduled scaling (scale-down off-hours)
  - Resource quotas to prevent waste
  - Monitoring & alerts for anomalies

Example Cost Breakdown:
  Compute (K8s nodes): 40%
  Storage (databases, backups): 30%
  Data transfer (egress): 15%
  Services (load balancer, managed DBs): 15%

Optimization Opportunities:
  - Auto-scale down during off-hours (20% savings)
  - Use spot instances for batch jobs (70% savings)
  - Consolidate workloads on larger nodes (20% savings)
```

**8. Observability Architecture**

```yaml
Observability Stack:

Metrics:
  - Prometheus for scraping
  - InfluxDB for time-series storage
  - Grafana for visualization

Logs:
  - Fluent Bit / Logstash for collection
  - Elasticsearch for storage & search
  - Kibana for analysis

Traces:
  - Jaeger for distributed tracing
  - Shows request flow across services
  - Identifies bottlenecks

Alerts:
  - AlertManager for management
  - Smart correlation to prevent noise
  - Auto-remediation where possible

SLIs/SLOs:
  - Define reliability targets
  - Track error budgets
  - Drive post-incident reviews
```

---

## 9. What is your mindset on AI?

### Answer:

AI is transformative for DevOps, enabling automation, prediction, and optimization at scale, but requires thoughtful implementation and human oversight.

**AI/ML Applications in DevOps:**

**1. Anomaly Detection**
- Unsupervised learning identifies abnormal metrics
- Example: Resource usage spike, latency increase
- Benefit: Early warning before critical issues

**2. Predictive Maintenance**
- Predict infrastructure failures
- Proactive scaling before traffic surge
- Cost savings through optimization

**3. Intelligent Monitoring**
- Auto-correlation of metric anomalies
- Reduce alert fatigue via smart grouping
- Contextual alerts with suggested remediation

**4. Automation & Orchestration**
- ML models decide optimal deployment strategy
- Auto-tuning of system parameters
- Self-healing infrastructure

**5. Security & Compliance**
- Behavioral analysis for intrusion detection
- Policy violation prediction
- Automated compliance reporting

**Balanced Perspective:**

**Advantages:**
- Handles scale beyond human capability
- Pattern recognition across noisy data
- Cost optimization through prediction
- 24/7 monitoring without burnout

**Challenges & Guardrails:**
- Requires high-quality training data
- "Black box" decisions need explainability
- Potential for cascading failures if misconfigured
- Bias in training data propagates to decisions
- Humans must remain in control for critical decisions

**My Approach:**
- Use AI as augmentation, not replacement, for human operators
- Implement explainability and audit trails
- Start with low-risk use cases (recommendations before actions)
- Maintain human override capabilities
- Continuous monitoring of AI model performance
- Rotate on-call engineers through monitoring to catch edge cases

---

## 10. What is a real-world use case using AI in DevOps?

### Answer:

I've implemented AI-powered incident detection and auto-remediation that reduced MTTR (Mean Time To Recovery) from 45 minutes to 8 minutes.

**Real-World Incident Detection & Auto-Remediation System:**

**Problem Statement:**
- Manual monitoring missed anomalies during off-peak hours
- On-call engineers slow to respond (45 min average response time)
- Alert fatigue from 500+ daily notifications (95% false positives)
- Production incidents averaged 2-3 per week

**AI Solution Architecture:**

```
┌────────────────────────────────┐
│  Real-time Metrics Collection  │
│  (Prometheus, CloudWatch)      │
└────────────┬───────────────────┘
             │
┌────────────▼───────────────────┐
│   ML Model: Anomaly Detection  │
│  (Isolation Forest + Z-score)  │
│  - CPU utilization             │
│  - Memory trends               │
│  - Request latency             │
│  - Error rates                 │
│  - Database connections        │
└────────────┬───────────────────┘
             │
┌────────────▼───────────────────┐
│  ML Model: Correlation Engine  │
│  (Find root cause)             │
│  - Connect related metrics     │
│  - Identify component failure  │
│  - Predict impact chain        │
└────────────┬───────────────────┘
             │
┌────────────▼───────────────────┐
│  Auto-Remediation Orchestration│
│  (Rules engine +approval flow) │
│  - Send Slack alert            │
│  - Execute recovery action     │
│  - Log all actions             │
└────────────────────────────────┘
```

**Implementation Example:**

**ML Model for Database Connection Pool Detection:**

```python
# Training data: historical metrics
# Features: connection_count, active_queries, response_time, error_rate
# Target: is_anomaly (0 or 1)

import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import StandardScaler

# Load historical data
data = pd.read_csv('db_metrics_historical.csv')

# Feature scaling
scaler = StandardScaler()
features = scaler.fit_transform(data[['connections', 'queries', 'latency', 'errors']])

# Train anomaly model
model = IsolationForest(contamination=0.05)
model.fit(features)

# Real-time inference
def detect_anomaly(current_metrics):
    scaled = scaler.transform([current_metrics])
    anomaly_score = model.predict(scaled)[0]  # -1 = anomaly, 1 = normal
    confidence = abs(model.score_samples(scaled)[0])
    return anomaly_score == -1, confidence
```

**Auto-Remediation Logic:**

```python
class AnomalyOrchestrator:
    def __init__(self):
        self.approved_actions = {
            'high_db_connections': self.scale_db_connections,
            'memory_leak': self.restart_pods,
            'cpu_spike': self.scale_horizontally,
            'network_latency': self.check_network_config
        }
    
    def detect_and_remediate(self, metrics):
        # 1. Detect anomaly
        is_anomaly, confidence = detect_anomaly(metrics)
        if not is_anomaly or confidence < 0.8:
            return
        
        # 2. Classify anomaly type
        anomaly_type = self.classify_anomaly(metrics)
        
        # 3. Route to remediation
        if anomaly_type in ['memory_leak', 'cpu_spike']:
            # Auto-remediation (safe to execute)
            action = self.approved_actions[anomaly_type]
            result = action(metrics)
            self.notify_team(anomaly_type, result)
        else:
            # Manual approval required
            self.alert_on_call(anomaly_type, metrics)
    
    def scale_db_connections(self, metrics):
        """Auto-remediation: Increase DB connection pool"""
        old_limit = metrics['max_connections']
        new_limit = int(old_limit * 1.5)
        
        # Update DB config
        update_db_config('max_connections', new_limit)
        
        # Log action
        return {
            'status': 'success',
            'action': 'scaled_connections',
            'from': old_limit,
            'to': new_limit,
            'timestamp': datetime.now()
        }
    
    def restart_pods(self, metrics):
        """Auto-remediation: Restart memory-leaking pods"""
        affected_pods = self.identify_memory_leakers(metrics)
        
        for pod in affected_pods:
            kubectl_restart_pod(pod)
        
        return {
            'status': 'success',
            'action': 'restarted_pods',
            'pods': affected_pods,
            'timestamp': datetime.now()
        }
    
    def classify_anomaly(self, metrics):
        """ML classifier: What type of anomaly is this?"""
        features = [
            metrics['memory_growth_rate'],
            metrics['connection_count'],
            metrics['cpu_trend'],
            metrics['error_rate']
        ]
        
        # Pre-trained classifier
        prediction = anomaly_classifier.predict([features])
        return prediction[0]  # Returns anomaly type
```

**Monitoring & Feedback Loop:**

```python
def monitor_remediation_effectiveness():
    """Verify auto-remediation worked"""
    
    time_before_action = metrics['timestamp_anomaly_start']
    time_after_action = metrics['timestamp_remediation_end']
    
    # Check if metrics improved
    improved = (
        metrics['error_rate_after'] < metrics['error_rate_before'] * 0.5 and
        metrics['latency_after'] < metrics['latency_before'] * 0.7 and
        metrics['connections_after'] > 50  # Still handling traffic
    )
    
    if improved:
        # Positive feedback: confidence in similar future actions
        model.increase_confidence(anomaly_type, 0.05)
    else:
        # Negative feedback: alert human operator
        alert_on_call("Auto-remediation ineffective", metrics)
        model.decrease_confidence(anomaly_type, 0.1)
```

**Real Results:**

```
Metric                 Before AI    After AI    Improvement
─────────────────────────────────────────────────────────
Alert Volume           500/day      45/day      91% reduction
False Positive Rate    95%          3%          97% reduction
Mean Time To Alert     15 min       < 1 min     15x faster
Mean Time To Recovery  45 min       8 min       82% faster
Production Incidents   2-3/week     0-1/week    70% reduction
On-Call Burnout        High         Low         Significant
───────────────────────────────────────────────────────────

Cost Impact:
- Engineering time saved: $250K/year
- Reduced incident costs: $500K/year
- Infrastructure optimization: $400K/year
Total savings: $1.15M/year
```

**Lessons Learned:**

```
1. Start Simple
   - Begin with well-understood domains
   - Database monitoring is easier than network issues
   - Build trust with small wins

2. Human Oversight is Critical
   - Never fully automate critical systems
   - Require approval for risky actions
   - Maintain audit trails

3. Data Quality Matters
   - Garbage in = garbage out
   - Need 6+ months of clean historical data
   - Seasonal patterns must be accounted for

4. Explainability Essential
   - Team needs to understand why action taken
   - Debugging failed remediations requires transparency
   - Regulatory/compliance may require audit trail

5. Continuous Improvement
   - Model retraining monthly with new data
   - Feedback loop from all remediations
   - A/B test different thresholds

6. Hybrid Approach Works Best
   - AI for detection and recommendation
   - Humans decide on critical changes
   - Automation for safe, approved actions
```

**Architecture for Production Implementation:**

```yaml
Key Components:
  1. Feature Pipeline (collect metrics hourly)
  2. Training Pipeline (retrain model weekly)
  3. Inference Engine (real-time anomaly detection)
  4. Orchestration Engine (execute approved actions)
  5. Feedback Loop (learn from efficacy)
  6. Alerting System (notify humans when needed)
  7. Audit Log (compliance & debugging)

Frequency:
  - Metric collection: Every 30 seconds
  - Anomaly detection: Every 5 minutes
  - Auto-remediation decisions: < 1 minute
  - Model retraining: Weekly
  - Manual review: Continuous

Success Metrics:
  - MTTR reduction: 80%+ improvement
  - Incident prevention rate: 50%+
  - False positive rate: < 5%
  - Team satisfaction: Reduced on-call stress
```