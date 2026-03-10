# Kubernetes Services, Ingress & Traffic Management, and Networking Model
## Senior DevOps Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Common Misunderstandings](#common-misunderstandings)
3. [Service Types and Service Discovery](#service-types-and-service-discovery)
   - [ClusterIP Services](#clusterip-services)
   - [NodePort Services](#nodeport-services)
   - [LoadBalancer Services](#loadbalancer-services)
   - [ExternalName Services](#externalname-services)
   - [Headless Services](#headless-services)
   - [DNS-Based Service Discovery](#dns-based-service-discovery)
   - [Under-the-Hood Mechanics](#under-the-hood-mechanics)
   - [Use Cases and Best Practices](#service-use-cases-and-best-practices)
4. [Ingress and Traffic Management](#ingress-and-traffic-management)
   - [Ingress Controllers](#ingress-controllers)
   - [Ingress Resources](#ingress-resources)
   - [How Ingress Works Under the Hood](#how-ingress-works-under-the-hood)
   - [Routing Rules and Path-Based Routing](#routing-rules-and-path-based-routing)
   - [Host-Based Routing](#host-based-routing)
   - [TLS Termination and mTLS](#tls-termination-and-mtls)
   - [Load Balancing Strategies](#load-balancing-strategies)
   - [Ingress Best Practices](#ingress-best-practices)
5. [Kubernetes Networking Model](#kubernetes-networking-model)
   - [Pod-to-Pod Communication](#pod-to-pod-communication)
   - [Service Networking](#service-networking-detailed)
   - [Network Policies](#network-policies)
   - [CNI Plugins](#cni-plugins)
   - [Cluster Networking](#cluster-networking)
   - [Overlay vs Underlay Networks](#overlay-vs-underlay-networks)
   - [Networking Best Practices](#networking-best-practices)
6. [Hands-on Scenarios](#hands-on-scenarios)
7. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Services, Ingress, and the Kubernetes Networking Model form the backbone of how traffic flows through a Kubernetes cluster. At their core, these components solve a fundamental problem: **In a distributed system where pods are ephemeral and constantly being created/destroyed, how do we reliably route traffic to the right workload?**

The Kubernetes networking stack provides multiple layers of abstraction:
- **Services** handle internal and external service discovery and load balancing
- **Ingress** provides advanced layer 7 (application layer) routing and traffic management
- **The underlying networking model** ensures reliable pod-to-pod communication across nodes and clusters

### Why It Matters in Modern DevOps Platforms

In production environments, these components are critical for:

1. **High Availability**: Services provide automatic failover when pods restart or are rescheduled
2. **Scalability**: Load balancing distributes traffic across multiple replicas without client configuration changes
3. **Operational Simplicity**: No need to manage static host files or IP addresses; DNS-based discovery handles changes automatically
4. **Security**: Network policies enforce zero-trust networking and segment traffic flows
5. **Multi-Tenancy**: Ingress enables cost-efficient sharing of external load balancers across multiple applications
6. **Observability**: Understanding network flows is essential for troubleshooting, capacity planning, and security audits

### Real-World Production Use Cases

#### E-Commerce Platform
- **Services**: Multiple microservices (catalog, cart, payment) communicate internally via ClusterIP services
- **Ingress**: Single external entry point routes requests to different services based on path (/api/catalog → catalog service, /api/cart → cart service)
- **Network Policies**: Restrict payment service communication to only cart and auth services (zero-trust)
- **Challenge Solved**: Decouples external DNS from internal services; teams can deploy new microservices without reconfiguring external load balancers

#### Multi-Tenant SaaS
- **Services**: Each tenant deployed in different namespaces with their own service mesh
- **Ingress**: Virtual hosting routes requests based on Host header (tenant1.example.com vs tenant2.example.com) to the same deployment
- **Network Policies**: Strict segmentation between tenant namespaces
- **Challenge Solved**: Single cluster efficiently serves hundreds of isolated tenants with automatic scaling

#### CI/CD Pipeline Infrastructure
- **Services**: Jenkins workers, artifact stores, and container registries use ExternalName services for external dependencies
- **Ingress**: Temporary web UIs for build logs accessible via Ingress without managing multiple LoadBalancer services
- **Network Policies**: Only CI/CD nodes can access artifact registries and databases
- **Challenge Solved**: Reduces cloud costs by eliminating separate load balancers for development infrastructure

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    External Internet                         │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│            Cloud Load Balancer (AWS ELB, GCP LB)           │
│        ↓ LoadBalancer type Service OR Ingress Controller    │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│         Kubernetes Cluster (Ingress Controller/kube-proxy)  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │     Pods running application containers            │   │
│  │  (communicate via CNI, load balanced by Services)  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Key Terminology

**Service**: A Kubernetes API object that provides stable, virtual IP endpoint for accessing a set of pods. Acts as an abstraction layer hiding pod churn.

**Endpoint**: The actual network addresses (pod IPs and ports) that receive traffic for a service. Dynamically managed by the Endpoint controller.

**kube-proxy**: Node-level component responsible for implementing service routing. Watches Service and Endpoint objects and programs Linux networking rules.

**Ingress**: A Kubernetes API object defining how external HTTP/HTTPS traffic should be routed to services. Requires an Ingress Controller for actual implementation.

**Ingress Controller**: A pod(s) running application (e.g., NGINX, HAProxy) that reads Ingress objects and configures the actual reverse proxy/load balancer.

**CNI (Container Network Interface)**: Plugin architecture that defines how containers are connected to the host network. Examples: Flannel, Calico, Weave.

**Network Policy**: Kubernetes API object defining rules for pod-to-pod communication. Acts as a firewall at the network layer.

**Cluster DNS**: Internal DNS service (kube-dns, CoreDNS) providing service name resolution within the cluster.

**Service Selector**: Label selector identifying which pods belong to a service. Used to maintain Endpoints list.

**Virtual IP (Cluster IP)**: Stable, virtual IP address allocated to a service. Never changes, even as backing pods restart.

**iptables/nftables vs IPVS**: Different modes kube-proxy can use to implement service networkweighting forwarding rules.

### Architecture Fundamentals

#### The Service Abstraction Layer

Services exist at a critical abstraction boundary:
- **Above**: Application code and controllers that manage workloads
- **Below**: Linux kernel networking (iptables, routing, connection tracking)

When you create a Service, Kubernetes:
1. Allocates a stable Virtual IP (Cluster IP) from the service CIDR range
2. Creates an Endpoints object tracking matching pods
3. Instructs kube-proxy on every node to program forwarding rules
4. Registers DNS entries for the service name

**Why this matters for senior engineers**: Understanding this separation is critical for debugging network issues. A service might be "defined" but broken due to:
- Broken label selectors (wrong Endpoints)
- No pods matching the selector
- kube-proxy not properly running on nodes
- CNI not properly configured
- Firewall rules blocking between nodes

#### Traffic Flow for Different Service Types

**ClusterIP (Default)**:
```
Client Pod → Service VIP (10.0.0.1) → kube-proxy (iptables rules) 
  → Load balanced to backing Pod IP (e.g., 10.244.0.5)
```

**NodePort**:
```
External Client → Node IP:NodePort → kube-proxy → Service VIP → Pod
```

**LoadBalancer**:
```
External Client → Cloud LB:Port → Any Node:NodePort → Service VIP → Pod
```

**Headless Service**:
```
Client DNS Query → Returns Pod IPs directly (no VIP)
Client → Direct connection to Pod IP
```

#### The Ingress Layer vs Service Layer

- **Services**: Layer 4 (Transport) - load balance any protocol, understand connections
- **Ingress**: Layer 7 (Application) - inspect HTTP/HTTPS, understand paths, hostnames, certificates
- **Why both exist**: Services provide the foundation; Ingress adds application-aware routing on top

#### Network Architecture Patterns

**Flat Network Model** (Assumed by Kubernetes):
- Every pod can reach every other pod directly
- Enforced by CNI plugin (creates overlay network)
- No traditional firewalls between pods by default
- Network Policies are the "firewall" mechanism

**Why this matters**: Anyone assuming traditional network isolation within a cluster is building a security house of cards. Network Policies are not automatically enabled; you must actively implement them.

### Important DevOps Principles

#### 1. Treat Networking as Code
- Define all Ingress, Service, and Network Policy manifests in version control
- Use GitOps to sync actual cluster state with desired state
- Never manually configure services; always apply manifests
- Include network policies in your deployment pipeline

#### 2. Assume High Churn
- Pods restart constantly; code must not cache IP addresses
- Use service names (DNS) never hardcode pod IPs
- Clients must handle connection resets and automatic reconnection
- Session affinity should be avoided; make services stateless

#### 3. Defense in Depth
- Use Network Policies to segment namespaces and tenants
- Never rely solely on service selectors for security
- Combine Ingress TLS with mTLS for internal services
- Audit and monitor all network policy violations

#### 4. Observable by Default
- Every service should have observability instrumentation
- Export metrics for service latency, error rates, active connections
- Log Ingress access patterns for troubleshooting
- Use network policies with annotation-based auditing

#### 5. Fail Gracefully
- Services must handle uneven load distribution
- Use readiness probes to prevent traffic to starting pods
- Implement graceful shutdown (SIGTERM handling) to drain connections
- Configure termination grace periods appropriately

### Best Practices

1. **Always use readiness/liveness probes** with services to ensure traffic only goes to ready pods
2. **Label pods comprehensively** (app, version, tier) because service selectors depend on accurate labels
3. **Test network policies in audit mode first** before enforcing; blocking all traffic by mistake is a common outage
4. **Monitor kube-proxy logs** for errors; many network issues stem from kube-proxy failures
5. **Use DNS names, never IP addresses** in configuration; services provide the abstraction
6. **Implement resource limits and requests** to enable proper scheduling; networking scales with pod density
7. **Version your Ingress manifests** carefully; routing changes can break applications silently
8. **Use NetworkPolicy to implement zero-trust** by default; only explicitly allow required communication
9. **Test Ingress rule ordering** as some controllers match first-defined rules (not most-specific)
10. **Monitor service load distribution** to catch imbalance issues caused by connection affinity or session persistence

### Common Misunderstandings

#### Misconception 1: "Services are load balancers"
**Reality**: Services are traffic distribution mechanisms, not load balancers in the traditional sense. They don't understand traffic patterns, session affinity, or application-specific routing. They simply spread traffic across endpoints. True load balancing happens at the Ingress layer.

#### Misconception 2: "Pod IP addresses are stable"
**Reality**: Pod IP addresses are completely ephemeral. The service VIP is stable. Any code caching pod IPs will break on pod restart. Always use service DNS names.

#### Misconception 3: "Network Policies are automatically enabled"
**Reality**: Network Policies are disabled by default. Without an explicit Network Policy, all pods can communicate with all other pods. You must actively implement zero-trust networking.

#### Misconception 4: "ClusterIP services can't be accessed from outside the cluster"
**Reality**: ClusterIP services are inaccessible from outside by design. To expose services externally, use NodePort, LoadBalancer, or more commonly, Ingress. Some teams incorrectly use NodePort everywhere when Ingress would be more appropriate.

#### Misconception 5: "Ingress replaces Service"
**Reality**: Ingress cannot exist without Services. Ingress routes traffic to Services, which route to pods. They're complementary, not alternative. You need both.

#### Misconception 6: "DNS always works for service discovery"
**Reality**: Pod DNS configuration can be incomplete. Headless services expose different DNS semantics requiring client knowledge. Some legacy apps don't support DNS discovery. Always verify DNS resolution before assuming it works.

#### Misconception 7: "LoadBalancer services are free"
**Reality**: Every LoadBalancer service provisions a cloud load balancer (ELB, Cloud LB, etc.), costing money. Using many LoadBalancer services is expensive. Ingress (sharing a single LB) is cost-efficient for multiple services.

#### Misconception 8: "Updating Ingress rules has no downtime"
**Reality**: Ingress controller may take time to reload configuration. During this window, requests might fail or route incorrectly. Test changes and monitor during updates. Some controllers (Nginx) handle hot reload; others don't.

---

## Service Types and Service Discovery

### ClusterIP Services

**Definition**: The default service type. Creates a virtual IP accessible only from within the cluster.

#### How It Works

1. **VIP Allocation**: Kubernetes allocates from the service CIDR range (default: 10.0.0.0/24)
2. **Endpoint Tracking**: Controller watches pods matching the selector; maintains Endpoint object with pod IPs
3. **kube-proxy Programming**: Every node's kube-proxy configures iptables/IPVS rules to forward Service VIP traffic to pod IPs
4. **DNS Registration**: CoreDNS automatically registers `service-name.namespace.svc.cluster.local` pointing to the Service VIP

#### Under-the-Hood Mechanics

**iptables Implementation** (default for small clusters):

```
iptables rule on every node:
-A KUBE-SERVICES -d 10.0.0.5/32 -p tcp -m comment --comment "my-service:8080" 
  -j KUBE-SVC-XXXX

-A KUBE-SVC-XXXX -m statistic --mode random --probability 0.5 -j KUBE-SEP-POD1
-A KUBE-SVC-XXXX -j KUBE-SEP-POD2

-A KUBE-SEP-POD1 -p tcp -j DNAT --to-destination 10.244.0.5:8080
-A KUBE-SEP-POD2 -p tcp -j DNAT --to-destination 10.244.1.3:8080
```

**IPVS Implementation** (better for large clusters):

```
ipvsadm -Ln (viewing IPVS rules):
TCP  10.0.0.5:8080 rr
  -> 10.244.0.5:8080           Masq    1      0       
  -> 10.244.1.3:8080           Masq    1       0
```

**Key insight**: Once traffic is DNATed to a pod IP, the return traffic uses connection tracking to route back through the service. This is stateful translation at the kernel level.

**Session Affinity Mechanics**:
When `sessionAffinity: ClientIP` is set:
```
Hash(client IP) → Always route to same pod
Sticky connections maintained in conntrack table
Connection timeout after spec.sessionAffinityConfig.clientIP.timeoutSeconds
```

#### DNS Resolution Flow

```
1. Client pod resolves "my-service.default.svc.cluster.local"
2. CoreDNS query → Response: 10.0.0.5 (Service VIP)
3. Client connects to 10.0.0.5:8080
4. kube-proxy iptables translates to pod IP
5. Traffic reaches actual pod
```

**DNS Caching Pitfall**: Some applications cache DNS results aggressively. If a service VIP ever changes (rare), cached entries become stale. Use TTL values appropriately.

#### Configuration Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: default
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
  - name: http
    port: 8080           # The port the service listens on
    targetPort: 8080     # The port on the pod
    protocol: TCP
  sessionAffinity: None  # or "ClientIP" for sticky sessions
```

#### Use Cases

- **Internal service-to-service communication**: Frontend pods calling backend APIs
- **Default choice**: Most kubernetes services default to ClusterIP
- **Microservices architecture**: Decouples services from specific pod addresses
- **Internal caching layers**: Memcached, Redis accessed internally via ClusterIP

### NodePort Services

**Definition**: Exposes service on a static port on each node's IP address, making it accessible from outside the cluster.

#### How It Works

1. **Node Port Allocation**: Kubernetes allocates a port in the range 30000-32767 on every node
2. **Service VIP**: Still creates an internal Cluster IP for in-cluster communication
3. **Node Forwarding**: Kernel rules forward traffic from the NodePort to the service VIP, then to pod IPs
4. **No DNS**: No automatic DNS entry for NodePort; clients must know node IP and port

#### Under-the-Hood Mechanics

```
Client External → NodeIP:30080 → Node's iptables rules 
  → IF source not from cluster THEN SNAT to node IP (masquerade)
  → Forward to Service VIP (10.0.0.5:8080)
  → Forwarded to pod IP
```

**Return Path**: When source IP masquerading is enabled, return traffic is DNATed back to the node IP.

**Without masquerading** (if enabled): 
```
Pod sees source IP as client IP (true source IP preserved)
May be required for certain applications (web server logs, etc.)
But can cause asymmetric routing issues
```

#### Configuration Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport-service
spec:
  type: NodePort
  selector:
    app: my-app
  ports:
  - port: 8080          # Service port
    targetPort: 8080    # Pod port
    nodePort: 30080     # Node port (optional; Kubernetes auto-assigns if omitted)
```

#### Use Cases

- **Limited external access**: When you want to expose a service from specific nodes
- **Development/testing**: Quick external access without cloud load balancer
- **Legacy systems**: Integrating with systems that can't use cloud LBs
- **Building block for LoadBalancer**: LoadBalancer services internally use NodePort

#### Implications for Production

- **Security**: Nodeport exposes a service on every node; network security team may block
- **Scaling**: Adding nodes requires distributing traffic to new node ports (external LB must be aware)
- **High port numbers**: Clients must connect to :30000-32767 (not standard HTTP/HTTPS ports)

### LoadBalancer Services

**Definition**: Requests the cloud provider to allocate an external load balancer and automatically routes traffic through it to the service.

#### How It Works

1. **External LB Allocation**: Cloud provider (AWS, GCP, Azure) allocates a load balancer
2. **Node Port**: Internally creates a NodePort service
3. **LB → Nodes**: Cloud LB routes traffic to any node's NodePort
4. **DNS**: Cloud provider typically assigns a DNS name (e.g., `service-abc123.us-east-1.elb.amazonaws.com`)

#### Kubernetes to Cloud LB Integration

```yaml
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
```

Kubernetes service controller:
1. Calls cloud provider API to create load balancer
2. Sets up NodePort
3. Configures cloud LB to route `:80` → `AllNodes:NodePort`
4. Returns external IP/DNS name

```
External Internet → AWS ELB (1.2.3.4:80)
  → Node 1:30000 → Service VIP → Pod
  → Node 2:30000 → Service VIP → Pod  
  → Node 3:30000 → Service VIP → Pod
```

#### Configuration Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
  externalTrafficPolicy: Local  # Important for preserving source IP
```

#### External Traffic Policy: Important Detail

**`externalTrafficPolicy: Cluster`** (default):
```
External LB → Random node → kube-proxy → Any pod in cluster
+ All pods can receive traffic (better distribution)
- Source IP is masqueraded; pod sees node IP, not client IP
```

**`externalTrafficPolicy: Local`**:
```
External LB → Node with local pod → kube-proxy → Local pod only
+ Source IP preserved; pod sees actual client IP
- Potential imbalance if nodes have unequal pod counts
- Extra hop if no local pod
```

**Production consideration**: Analytics and logging often need real client IPs. Use `Local` unless load imbalance becomes a problem. Monitor metrics to detect imbalance.

#### Use Cases

- **Public APIs**: Primary way to expose services to internet
- **Multi-region deployments**: Each region gets external IP
- **Cost consideration**: Every LoadBalancer service costs money (AWS ELB ~$0.04/hour)

### ExternalName Services

**Definition**: Maps service to an external DNS name. No load balancing; pure DNS alias.

#### How It Works

```
Client pod → Resolves my-external-service.default.svc.cluster.local
  → Resolved alias → external-db.example.com
  → Actual connection to external-db.example.com
```

#### Configuration Example

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-external-db
  namespace: default
spec:
  type: ExternalName
  externalName: postgres.example.com
```

Now pods can connect to `my-external-db.default.svc.cluster.local` and it transparently connects to external database.

#### Use Cases

- **External databases**: Connect to RDS, managed PostgreSQL outside cluster
- **Legacy systems**: Maintain consistent namespace for external services
- **Hybrid cloud**: Connect to on-premises resources
- **CNAME aliasing**: Create simpler internal names for long external addresses

#### Limitations

- No pod monitoring; cluster doesn't know if external service is up
- No load balancing; just DNS forwarding
- No observability into connections; external service owns monitoring

### Headless Services

**Definition**: Service with `clusterIP: None`. No virtual IP. DNS returns pod IPs directly.

#### How It Works

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-db
spec:
  clusterIP: None  # Key difference
  selector:
    app: db
  ports:
  - port: 5432
    targetPort: 5432
```

**DNS Behavior**:
```
Query: my-db.default.svc.cluster.local
Response (A records): 
  10.244.0.5   # Pod 1 IP
  10.244.1.3   # Pod 2 IP
  10.244.2.7   # Pod 3 IP
```

Client must handle multiple IPs, determining which to connect to.

#### For Stateful Sets

Headless services with StatefulSets create predictable DNS names:
```
my-db-0.my-db.default.svc.cluster.local → 10.244.0.5
my-db-1.my-db.default.svc.cluster.local → 10.244.1.3
my-db-2.my-db.default.svc.cluster.local → 10.244.2.7
```

This allows:
- Connecting to specific replicas (leader/follower patterns)
- Constructing cluster membership automatically
- Orderly startup/shutdown sequences

#### Use Cases

- **Stateful Sets**: Database clusters where all replicas matter
- **Leadership elections**: Applications knowing all candidate nodes
- **DNS-based discovery**: Applications expecting multiple DNS entries
- **Ordered startup**: Ensuring replica N+1 starts only after replica N

### DNS-Based Service Discovery

#### CoreDNS in Kubernetes

CoreDNS is the standard cluster DNS in Kubernetes 1.14+. It handles service discovery through:

1. **Kubernetes Plugin**: Watches API server for Service/Pod objects
2. **DNS Zones**: Creates zones for `cluster.local` (default)
3. **Recursive Resolution**: Falls back to upstream for external domains

#### DNS Names

**Service DNS**:
```
<service>.<namespace>.svc.cluster.local
<service>.<namespace>.svc         # Also works
<service>                          # Works within same namespace
```

**Pod DNS** (for headless services):
```
<pod-ip-with-dashes>.<namespace>.pod.cluster.local
# Example: 10-244-0-5.default.pod.cluster.local
```

#### DNS Search Path

Pod's `/etc/resolv.conf` includes:
```
search default.svc.cluster.local svc.cluster.local cluster.local
```

This allows:
```
# All equivalent:
mysql.default.svc.cluster.local
mysql.default.svc
mysql.default
mysql (from within default namespace)
```

#### A Records vs SRV Records

**A Records** (standard):
```
nslookup my-service.default.svc.cluster.local
→ 10.0.0.5 (service VIP)
```

**SRV Records** (additional metadata):
```
_http._tcp.my-service.default.svc.cluster.local
→ Includes port information
→ Useful for applications supporting DNS SRV lookup
```

#### DNS Caching Considerations

- **CoreDNS default TTL**: Typically 30 seconds
- **Application-level caching**: May cache longer, causing stale entries
- **Connection-level caching**: Some clients open persistent connections, not respecting TTL
- **Implications**: Service VIP changes (rare) may not propagate immediately

**Best practice**: Design applications assuming long TTLs and use external signals (health checks, leadership elections) rather than DNS changes for detecting failures.

### Under-the-Hood Mechanics

#### Endpoint Controller Loop

```
1. Watch Service objects
2. Get label selector from Service
3. Query Pod list with selector
4. Generate Endpoint object (list of pod IPs + ports)
5. When pod starts/stops/restarts, update Endpoint
6. kube-proxy watches Endpoint, updates forwarding rules
```

**Implication**: If service selector doesn't match any pods, Endpoint is empty, service receives no traffic. This is the #1 cause of "service not working" issues.

#### kube-proxy Mode Comparison

**iptables Mode**:
- Default until Kubernetes 1.20
- Creates iptables rules per service
- O(n) service scaling; can become slow with 1000+ services
- Rules aren't efficiently ordered; rule matching can be slow
- Still sufficient for most clusters

**IPVS Mode**:
- Better performance for large clusters
- O(1) lookup using kernel hash table
- Load balancing algorithms: rr (round-robin, default), lc (least connection), ip (IP hash)
- Reduces CPU usage significantly in clusters with 1000+ services

**userspace Mode** (deprecated):
- Traffic passes through userspace kube-proxy process
- Slowest; rarely used anymore
- Can bypass as old as Kubernetes 1.0

**Windows HNS** (for Windows nodes):
- Uses Windows Host Networking Service
- Different implementation than Linux iptables/IPVS
- Slightly different semantics

#### Connection Tracking

Linux conntrack (connection tracking) table is critical:

```
iptables DNAT rule translates packet:
  Original: src=10.244.0.1 dst=10.0.0.5
  Translated: src=10.244.0.1 dst=10.244.1.3

Return packet from pod:
  Pod sends: src=10.244.1.3 dst=10.244.0.1
  Conntrack reverses DNAT: src=10.0.0.5 dst=10.244.0.1
```

**Implications**:
- iptables rules alone don't work; conntrack is essential
- If conntrack table is full, new connections fail mysteriously
- Monitor `nf_conntrack_count` vs `nf_conntrack_max` on nodes
- Scale considerations for high-connection-rate services

#### Service Lifecycle Events

**Service Creation**:
```
User applies Service manifest
  ↓
API server stores Service object
  ↓
Endpoint controller detects new Service
  ↓
Endpoint controller creates Endpoint object
  ↓
kube-proxy watchers detect new Endpoint
  ↓
kube-proxy reprograms iptables rules
  ↓
Traffic can now flow (typically <1 second delay)
```

**Pod Addition**:
```
Pod starts and becomes ready
  ↓
Pod added to matching Endpoints
  ↓
kube-proxy updates iptables
  ↓
New traffic distribution includes new pod
```

**Pod Deletion**:
```
Pod termination initiated
  ↓
Pod removed from Endpoint
  ↓
kube-proxy updates iptables
  ↓
Existing connections still routed to pod (until timeout)
  ↓
Pod has terminationGracePeriod seconds to drain connections
```

### Service Use Cases and Best Practices

#### Best Practice: Comprehensive Labels

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: backend
    version: v1.2.3
    tier: service
    component: api
```

**Why**: Service selectors depend on labels. Comprehensive labeling enables:
- Multiple services selecting different pod subsets
- Version canaries (service selecting v1.2.3 vs v1.3.0)
- Network policies based on tier/component
- Cost allocation by component

#### Best Practice: Define Service Before Pod Deployment

```yaml
# Apply Service first
kubectl apply -f service.yaml

# Then scale up deployment
kubectl apply -f deployment.yaml
```

**Why**: Prevents race conditions where pods might receive traffic before they're fully ready. Service definition ensures networking is ready to accept traffic.

#### Best Practice: Use Readiness Probes Religiously

```yaml
spec:
  containers:
  - name: app
    readinessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 10
```

**Why**: kube-proxy adds pods to service only when ready. Without readiness probes, broken pods receive traffic, causing user-facing errors.

#### Best Practice: Monitor Service Endpoint Changes

```bash
# Watch endpoint changes
kubectl get endpoints my-service -w

# See detailed endpoint info
kubectl describe endpoints my-service
```

**Troubleshooting technique**: If service not working, first check if Endpoint has any entries. Empty Endpoint = label selector wrong or no pods match.

#### Best Practice: Set Service Affinity Deliberately

```yaml
sessionAffinity: None  # Load balance every request
# OR
sessionAffinity: ClientIP
sessionAffinityConfig:
  clientIP:
    timeoutSeconds: 600
```

**Why**: Sticky sessions can cause performance issues (unbalanced load). Only use if application truly requires it (stateful, expensive session establishment). For HTTP, prefer stateless + load balancing.

#### Best Practice: Configure Health Check Levels

**Pod Level** (via readiness probe):
```
Service only routes to healthy pods
```

**Service Level** (via endpoint slice):
```
Service directly reflects endpoint health
Controlled by probe results
```

**Request Level** (via application):
```
App rejects requests if dependencies unavailable
Prevents cascading failures
```

All three levels together provide defense in depth.

---

## Ingress and Traffic Management

### Ingress Controllers

**Definition**: A controller pod running a reverse proxy/load balancer application configured by Ingress objects.

#### Available Ingress Controllers

**NGINX Ingress Controller** (most popular):
```
Opensource: kubernetes/ingress-nginx
Artifact Hub: ingress-nginx (community-maintained)
Features: Path-based routing, TLS termination, rate limiting, basic auth
Performance: Handles 10,000+ RPS per replica
Configuration: ConfigMap for global settings, annotations for per-Ingress settings
```

**AWS ALB Ingress Controller**:
```
AWS-provided, uses AWS Application Load Balancer
Features: AWS-specific (WAF integration, cognito auth)
Cost: Leverages existing AWS ALB infrastructure
Best for: AWS-native deployments
```

**GCS Ingress Controller**:
```
GCP-provided, uses Google Cloud Load Balancer
Integrations: Cloud Armor (DDoS), Cloud CDN
Best for: GCP environments
```

**HAProxy Ingress**:
```
HAProxy-based, high performance
Features: Advanced traffic shaping, detailed logging
Use case: When fine-grained traffic control needed
```

**Traefik**:
```
Modern, dynamic ingress controller
Features: Routes updates without restart, multiple backend support
Good for: Microservices, Kubernetes-native automatic discovery
```

**Istio Gateway** (service mesh alternative):
```
Part of Istio service mesh
Features: mTLS, traffic management, observability
Complexity: Heavier than traditional Ingress
Use case: Advanced traffic management + security requirements
```

#### Ingress Controller Deployment Models

**Single Replica** (development):
```
1 pod handles all ingress traffic
Simplicity: Easy to deploy
Problem: Single point of failure
Not suitable for production
```

**Multiple Replicas with Pod Disruption Budget**:
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ingress-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: ingress-nginx
```

**High Availability Setup**:
- Multiple Ingress controllers across nodes
- Each controller runs independently
- All route to same backend services
- External load balancer distributes traffic to controller pods

**Daemonset per Node**:
```
Each node runs Ingress controller pod
Traffic hits local controller (lower latency)
Requires node port or special network setup
Typically for extremely high throughput
```

### Ingress Resources

**Definition**: Kubernetes API object defining layer 7 routing rules.

#### Basic Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  namespace: default
spec:
  ingressClassName: nginx      # Specify which controller
  rules:
  - host: my-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

#### Ingress Class

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx  # Points to NGINX controller
---
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
spec:
  controller: ingress.k8s.aws/alb   # Points to AWS ALB controller
```

**Why multiple controllers?** Different ingress types may need different features. A cluster might have NGINX for general services and AWS ALB for resources needing AWS integrations.

#### TLS Configuration

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
spec:
  tls:
  - hosts:
    - my-app.example.com
    secretName: my-app-tls-cert  # Stored in Secret
  rules:
  - host: my-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

TLS certificate stored as Secret:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-tls-cert
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

#### Annotations for Advanced Features

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  annotations:
    # NGINX-specific annotations
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    # Cert-manager integration
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  rules:
  - host: my-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-app-service
            port:
              number: 80
```

### How Ingress Works Under the Hood

#### Ingress Controller Workflow

```
1. Ingress Controller starts
   ├─ Connects to API server
   ├─ Watches Ingress, Service, Secret objects
   └─ Sets up health endpoints

2. User creates Ingress resource
   └─ Controller detects via API watcher

3. Controller processes Ingress
   ├─ Parses rules (hosts, paths, backends)
   ├─ Resolves Services to pod IPs
   ├─ Loads TLS certificates from Secrets
   └─ Generates reverse proxy configuration

4. Reverse proxy reload
   ├─ Write config (e.g., /etc/nginx/nginx.conf)
   ├─ Validate config syntax
   ├─ Reload/restart reverse proxy process
   └─ Handle in-flight connections gracefully

5. Ongoing monitoring
   └─ Watch for changes (Ingress, Service, Secret modifications)
       Re-apply configuration on any change
```

#### NGINX Ingress Controller Specifically

```
Inside NGINX Ingress pod:
├─ nginx-ingress-controller (Go app)
│  └─ Watches Ingress objects
│     Generates /etc/nginx/nginx.conf
│     Hot-reloads NGINX
│
├─ NGINX worker processes
│  └─ Listens 0.0.0.0:80 (HTTP)
│  └─ Listens 0.0.0.0:443 (HTTPS)
│
└─ Periodic syncs
   └─ Every 10 seconds, re-read all Ingress objects
      Detect deletions, updates, additions
      Update reverse proxy config
```

**Key insight**: NGINX itself doesn't watch Kubernetes API. The Go controller watches API, generates NGINX config, and reloads NGINX.

#### Configuration Generation Example

**Ingress manifest**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /v1
        pathType: Prefix
        backend:
          service:
            name: api-v1
            port:
              number: 8080
      - path: /v2
        pathType: Prefix
        backend:
          service:
            name: api-v2
            port:
              number: 8080
```

**Generated NGINX config snippet**:
```nginx
server {
    server_name api.example.com;
    listen 80;
    
    location /v1 {
        proxy_pass http://api-v1.default.svc.cluster.local:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # Default timeout, retry, and buffering settings
    }
    
    location /v2 {
        proxy_pass http://api-v2.default.svc.cluster.local:8080;
        # Similar headers
    }
}
```

**What happens when service updates**:
1. New pod added to service → Service Endpoint updated
2. Controller detects Endpoint change (or watches Service)
3. Typically re-applies config (no change to NGINX config since it uses service DNS)
4. DNS resolves updated service IP, pods added automatically

#### Event-Driven vs Poll-Based

**Modern Ingress Controllers** (event-driven):
```
API Server Event → Controller Queue → Config Generation → Reload
(sub-second latency)
```

**Legacy Controllers** (polling):
```
Periodic poll of all Ingress objects (every 30s)
Only apply changes if detected
Higher latency; more CPU overhead
```

### Routing Rules and Path-Based Routing

#### Path Types

**Prefix**: `/api` matches `/api`, `/api/v1`, `/api/v1/users`
```yaml
pathType: Prefix
path: /api
```

**Exact**: `/api/users` matches only `/api/users`, not `/api/users/1`
```yaml
pathType: Exact
path: /api/users
```

**ImplementationSpecific**: Controller decides semantics
```yaml
pathType: ImplementationSpecific
```

#### Path Routing Example

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: routing-example
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      # Higher specificity should come first in Ingress
      - path: /api/v1/users/admin
        pathType: Exact
        backend:
          service:
            name: admin-service
            port:
              number: 8080
      
      - path: /api/v1/users
        pathType: Prefix
        backend:
          service:
            name: user-service
            port:
              number: 8080
      
      - path: /api/v1
        pathType: Prefix
        backend:
          service:
            name: api-v1-service
            port:
              number: 8080
      
      - path: /
        pathType: Prefix
        backend:
          service:
            name: default-service
            port:
              number: 8080
```

**Order matters**: Most specific paths should be listed first. Different controllers handle ordering differently:
- **NGINX**: Uses first-match semantics; order in Ingress matters
- **Other controllers**: May use most-specific-match; order doesn't matter

**Best practice**: Be explicit, don't rely on implicit ordering.

### Host-Based Routing

#### Virtual Hosting

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-tenant
spec:
  rules:
  - host: tenant1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tenant1-app
            port:
              number: 80
  
  - host: tenant2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: tenant2-app
            port:
              number: 80
  
  - host: "*.example.com"  # Wildcard
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: default-tenant-app
            port:
              number: 80
```

**How it works**:
```
Request: GET https://tenant1.example.com/path
Ingress controller extracts Host header: "tenant1.example.com"
Matches against rules
Routes to tenant1-app service
```

#### Wildcard Domains

```yaml
host: "*.example.com"  # Matches: api.example.com, web.example.com, etc.
host: "*.api.example.com"  # Matches: v1.api.example.com, v2.api.example.com
```

**DNS Requirement**: Wildcard DNS A record must point to Ingress IP:
```
example.com    A    1.2.3.4
*.example.com  A    1.2.3.4  # Same IP
```

#### Multi-Domain Ingress

Single Ingress managing multiple external domains:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-domain
spec:
  tls:
  - hosts:
    - example.com
    - www.example.com
    - api.example.com
    secretName: multi-domain-cert
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: web-service
            port:
              number: 80
  
  - host: www.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: web-service
            port:
              number: 80
  
  - host: api.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: api-service
            port:
              number: 80
```

### TLS Termination and mTLS

#### TLS Termination in Ingress

```
Client (HTTPS)
    ↓ (encrypted)
Ingress Controller (TLS endpoint)
    ↓ (decrypted, HTTP)
Service → Pod
    ↓ (unencrypted internally)
```

**Benefits**:
- Centralizes certificate management
- Reduces CPU on pods
- Ingress controller terminates and re-encrypts

**Certificate sources**:

1. **Static Secrets**:
```yaml
tls:
- hosts:
  - example.com
  secretName: my-tls-secret
```

2. **Automatic with cert-manager**:
```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
tls:
- hosts:
  - example.com
  secretName: example-com-tls  # Cert-manager creates this
```

#### mTLS (Mutual TLS)

**Traditional TLS**: Client verifies server certificate; server identifies itself to client but doesn't verify client.

**mTLS**: Client and server mutually verify each other's certificates.

#### mTLS Implementation Methods

**Istio Service Mesh Approach**:
```
Istio sidecar proxies handle mTLS automatically
No client code changes required
Certificates auto-rotated by Istio
Policy: PeerAuthentication defines mTLS enforcement per namespace/workload
```

**Manual mTLS at Application Level**:
```go
// Go code
tlsConfig := &tls.Config{
    Certificates: []tls.Certificate{clientCert},
    RootCAs: caCertPool,  // Server certificate verification
}
client := &http.Client{
    Transport: &http.Transport{
        TLSClientConfig: tlsConfig,
    },
}
```

**Manual mTLS at Ingress Level** (less common):
```yaml
# Ingress terminates client mTLS, backend services over HTTP
# Requires reverse proxy that supports client cert verification
```

#### Certificate Rotation Considerations

**Short-lived certificates** (recommended):
- Validity period: 30-90 days
- Rotation frequency: Automated
- Tool: cert-manager with LetsEncrypt
- Benefits: Reduces risk of leaked or misused certificates

**Long-lived certificates** (legacy):
- Validity period: 1-3 years
- Manual rotation required
- Risk: Leaked cert valid for long time
- Operational burden: Remember to rotate before expiry

**cert-manager automation**:
```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
```

cert-manager automatically:
- Creates certificate from LetsEncrypt
- Stores in Secret
- Refreshes before expiry
- Updates Secret when renewed

### Load Balancing Strategies

#### Round-Robin (Default)

```
POD 1 ← Request 1
POD 2 ← Request 2
POD 3 ← Request 3
POD 1 ← Request 4
```

```nginx
# NGINX config
upstream backend {
    server 10.244.0.1;
    server 10.244.1.2;
    server 10.244.2.3;
}
```

**Characteristics**: 
- Fair distribution
- No state required
- Works well for stateless services

#### Least Connections

```
POD 1: 5 active connections ← New request
POD 2: 10 active connections
POD 3: 8 active connections
```

```nginx
upstream backend {
    least_conn;
    server 10.244.0.1;
    server 10.244.1.2;
    server 10.244.2.3;
}
```

**Use case**: Long-lived connections (WebSockets, gRPC); balances current load not request count.

#### IP Hash

```
Hash(client IP) → Always same backend pod
Client 1.2.3.4 → POD 1 (always)
Client 1.2.3.5 → POD 2 (always)
```

```nginx
upstream backend {
    ip_hash;
    server 10.244.0.1;
    server 10.244.1.2;
}
```

**Use case**: Session affinity without sticky cookies. Client IPs map to consistent backend.

**Caveats**: 
- If pod count changes, mappings change (clients routed to different pod)
- Uneven distribution if certain client IPs frequently hit cluster

#### Weighted Load Balancing

```yaml
# Service with weighted endpoints (custom implementation needed)
# Not native Kubernetes; typically handled by Ingress controller
```

```nginx
upstream backend {
    server 10.244.0.1 weight=5;  # 5/8 of traffic
    server 10.244.1.2 weight=3;  # 3/8 of traffic
}
```

Use case: Canary deployments; route 10% to new version, 90% to stable.

#### Random

```nginx
upstream backend {
    random;
    server 10.244.0.1;
    server 10.244.1.2;
    server 10.244.2.3;
}
```

**Characteristics**: Randomly picks endpoint; can ensure distribution without affinity side effects.

### Ingress Best Practices

#### 1. Use Clear Naming and Organization

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  namespace: backend
  labels:
    app: api
    env: prod
spec:
  ingressClassName: nginx
  # Rest of config
```

**Why**: Multiple ingress resources can conflict; clear names prevent collisions.

#### 2. One Ingress per Logical Service

**Good**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-service
spec:
  rules:
  - host: api.example.com
    http:
      paths:
      - path: /
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

**Avoid**:
```yaml
# Single Ingress managing too many unrelated services
metadata:
  name: everything
spec:
  rules:
  - host: api.example.com
    # ...
  - host: web.example.com
    # ...
  - host: admin.example.com
    # ...
```

**Why**: Easier to reason about, update, version control.

#### 3. Automate Certificate Provisioning

```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
tls:
- hosts:
  - api.example.com
  secretName: api-tls
```

**Never manually manage certificates**. cert-manager handles renewals automatically.

#### 4. Use Health Checks and Readiness Probes

Ingress routes to services, which route to pods selected by labels. Ensure pods are ready:

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

**Why**: Broken pods shouldn't receive requests. Readiness probes ensure traffic only goes to healthy pods.

#### 5. Test Ingress Rule Changes Before Applying

```bash
# Create in separate namespace first
kubectl apply -f ingress.yaml -n staging

# Test endpoint
curl -H "Host: example.com" http://<ingress-ip>/api

# Once verified, apply to production
kubectl apply -f ingress.yaml -n prod
```

#### 6. Monitor Ingress Controller Metrics

- Request count per ingress rule
- P50/P95/P99 latency by path
- Error rate (4xx, 5xx)
- TLS certificate expiry

```bash
# NGINX Ingress metrics endpoint
curl localhost:10254/metrics  # Port varies by version
```

#### 7. Document Controller-Specific Behavior

Different Ingress controllers have different semantics:

```yaml
# Document in comments
metadata:
  annotations:
    # NGINX-specific: controls how paths are matched
    # Only relevant for nginx.ingress.kubernetes.io/rewrite-target
    nginx.ingress.kubernetes.io/rewrite-target: /v2$2
spec:
  # This ingress requires NGINX controller
  ingressClassName: nginx
```

#### 8. Use Ingress Over Multiple LoadBalancer Services

**Bad (expensive)**:
```yaml
# Creates cloud LB for each service (~$30-50/month each)
- Service type: LoadBalancer (api.example.com)
- Service type: LoadBalancer (web.example.com)
- Service type: LoadBalancer (admin.example.com)
```

**Good (cost-efficient)**:
```yaml
# Single cloud LB shared across all services
Ingress routes to multiple services based on Host/Path
All external traffic through single LB
```

#### 9. Rate Limit at Ingress Layer

```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"  # Per second
    nginx.ingress.kubernetes.io/rate-limit-by: "$binary_remote_addr"  # By client IP
```

**Why**: Protects backend from DDoS; prevents single misbehaving client from affecting others.

#### 10. Test Failover Scenarios

- What happens if Ingress controller pod dies?
- What happens if backend service is down?
- How long for Ingress to detect and route elsewhere?

```bash
# Test failover
kubectl kill pod <ingress-controller-pod>
# Traffic should still flow via backup controller

# Test backend failure
kubectl delete pods <backend-pod>
# Traffic should automatically route to remaining pods
```

---

## Kubernetes Networking Model

### Pod-to-Pod Communication

#### Flat Network Model

Kubernetes assumes a **flat network** where every pod can reach every other pod directly by IP address:

```
Pod A (10.244.0.5)
    ↓
[Network Plugin - CNI]
    ↓
Pod B (10.244.1.7) - direct connection, no gateway/router
```

**Key implication**: Kubernetes networking is not like traditional multi-network topologies. No VLAN tagging, subnetting, IP forwarding through gateways. Just: Pod A IP → Pod B IP → Direct delivery.

#### How the Flat Network is Implemented

**CNI Plugin Responsibilities**:

1. **Pod Network Setup** (when pod scheduled to node):
```
Pod created on Node 1
├─ Pod gets IP from cluster CIDR (e.g., 10.244.0.0/24 range for Node 1)
├─ Virtual network interface created in pod's netns
├─ Veth pair created: one end in pod, one end on host
└─ Host routing configured to route pod CIDR to the veth interface
```

2. **Inter-node Communication**:
```
Pod on Node 1 (10.244.0.5) sends to Pod on Node 2 (10.244.1.7)
├─ Pod sends packet to gateway (or directly if routes allow)
├─ Host routes to veth interface
├─ Veth forwards to host network
├─ Host-to-host tunnel/route (implemented by CNI)
│  ├─ Flannel: VXLAN tunnel between nodes
│  ├─ Calico: BGP routing between nodes
│  ├─ AWS VPC CNI: Native VPC routing
│  └─ Azure CNI: Native VNet routing
└─ Packet arrives at Node 2
    └─ Veth delivers to pod network interface
```

#### intra-Node vs Inter-Node Latency

**Intra-node** (pod on same node):
- Through veth pairs on host
- ~5-20 microseconds
- Single host, minimal hops

**Inter-node** (pods on different nodes):
- Through network plugin tunnel or routing
- ~100-500 microseconds
- Depends on network plugin, network latency, packet size

**Implication for latency-sensitive apps**: Affinity rules can keep related pods on same node.

#### Connection Lifecycle

```
1. Pod A initiates connection: socket(AF_INET, SOCK_STREAM)
2. Pod A connects to Pod B IP:Port
3. Network stack resolves Pod B IP to MAC address (ARP)
4. Packet forwarded through CNI network
5. Packet arrives at Pod B's veth
6. Pod B's network stack delivers to listening socket
7. TCP handshake completes
8. Data flows bidirectionally
9. Connection tracked in Linux conntrack
10. Graceful close or timeout
```

**Packet path breakdown**: Pod A process → Pod A network stack → Veth → Host network → CNI tunnel → Node B network → Veth → Pod B network stack → Pod B process.

### Service Networking (Detailed)

#### Service CIDR vs Pod CIDR

```
Pod CIDR: 10.244.0.0/16         (pods get IPs here)
Service CIDR: 10.0.0.0/24        (services get VIPs here)
Node CIDR: 10.128.0.0/24        (node IPs)
```

**Key difference**: Pod and service CIDRs must not overlap. Services route to pods, but they're in different subnets.

#### kube-proxy Service Logic

**For each Service**:
```
Service VIP: 10.0.0.5
Port: 8080
Endpoints: 10.244.0.5:8080, 10.244.1.3:8080, 10.244.2.7:8080

iptables rules on every node:
1. Match packets destined for 10.0.0.5:8080
2. Load balance across endpoints
3. DNAT to selected endpoint IP:port
4. Connection tracking memorizes translation for return packets
```

#### Endpoint Slice

Modern Kubernetes (1.18+) uses EndpointSlice instead of Endpoint:

```yaml
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: my-service-abc123
  ownerReferences:
  - name: my-service
    kind: Service
spec:
  addressType: IPv4
  ports:
  - name: http
    port: 8080
    protocol: TCP
  endpoints:
  - addresses:
    - "10.244.0.5"
    conditions:
      ready: true
      serving: true
      terminating: false
  - addresses:
    - "10.244.1.3"
    conditions:
      ready: true
  - addresses:
    - "10.244.2.7"
    conditions:
      ready: true
```

**Why EndpointSlice over Endpoint?**:
- Single Endpoint object had all Pod IPs
- Large services (1000s pods) meant huge Endpoint object and network churn
- EndpointSlice splits into multiple objects (default 100 endpoints per slice)
- Reduces API traffic, more efficient updates

#### Service to Pod Routing Deep Dive

**Scenario**: Client pod (10.244.0.1) connects to service (10.0.0.5:8080) with endpoints [10.244.1.3:8080, 10.244.2.7:8080]

**Step-by-step packet journey**:

```
1. Client initiates: connect(10.0.0.5, 8080)

2. Client pod's network stack sends packet:
   Source: 10.244.0.1, Dest: 10.0.0.5:8080

3. Kernel matches iptables rule:
   -d 10.0.0.5 -p tcp -m tcp --dport 8080 -j KUBE-SVC-XXXX

4. Load balancing decision (random or statistic):
   Route to endpoint 1 or 2
   Suppose endpoint: 10.244.1.3:8080

5. DNAT applied:
   Packet rewritten:
   Source: 10.244.0.1, Dest: 10.244.1.3:8080

6. Routing decision:
   10.244.1.3 is on Node 2
   Forward through CNI network to Node 2

7. Node 2 delivers to veth:
   Packet arrives at Pod on Node 2
   Pod's network stack delivers to socket

8. Pod processes request, sends response:
   Source: 10.244.1.3:8080, Dest: 10.244.0.1

9. Kernel's conntrack remembers translation:
   Reverse DNAT automatically applied:
   Source: 10.0.0.5:8080, Dest: 10.244.0.1

10. Return packet routed back to client pod
```

**Critical realization**: Client sees service IP as source in response due to conntrack reverse translation. Pod never sees client directly; sees service VIP.

### Network Policies

#### Why Network Policies?

By default, Kubernetes is "all pods can talk to all pods." This violates zero-trust principles. Network policies add an explicit firewall.

```
Default behavior (no policies): Allow all
With Network Policies: Deny all, then explicitly allow
```

#### Network Policy Rules

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}  # Applies to all pods in namespace
  policyTypes:
  - Ingress  # Block all ingress (incoming)
```

#### Selective Allow Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-from-frontend
  namespace: prod
spec:
  podSelector:
    matchLabels:
      tier: backend  # Apply to backend tier pods
      app: api
  
  policyTypes:
  - Ingress
  
  ingress:
  - from:
    # Allow from frontend pods in same namespace
    - podSelector:
        matchLabels:
          tier: frontend
    
    # Allow from monitoring namespace
    - namespaceSelector:
        matchLabels:
          name: monitoring
    
    ports:
    - protocol: TCP
      port: 8080
```

#### Egress Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-egress-policy
spec:
  podSelector:
    matchLabels:
      tier: api
  
  policyTypes:
  - Egress
  
  egress:
  # Allow to database
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  
  # Allow DNS (external)
  - to:
    - namespaceSelector: {}  # Any namespace
    ports:
    - protocol: UDP
      port: 53
  
  # Allow external HTTP/HTTPS (for updates, APIs)
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
```

#### Policy Selector Types

**podSelector**: Pods in same namespace
```yaml
podSelector:
  matchLabels:
    app: db
```

**namespaceSelector**: Entire namespace
```yaml
namespaceSelector:
  matchLabels:
    env: prod
```

**ipBlock**: Specific IP ranges (for external traffic)
```yaml
ipBlock:
  cidr: 203.0.113.0/24
  except:
  - 203.0.113.5/32  # Exclude specific IP
```

#### Common Network Policy Patterns

**Deny All Baseline**:
```yaml
# Apply to all namespaces
# Block everything, then explicitly allow needed traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Frontend-to-Backend Pattern**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      tier: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
```

**Prod-to-Dev Isolation**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: prod-isolation
  namespace: prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  # Only from within prod namespace
  - from:
    - podSelector: {}
    
    # Explicitly NOT allowing from dev namespace
```

#### Network Policy Implementation

**Two Modes**:

1. **Audit Mode** (not using network policy):
```
Network policy objects exist but unenforced
Useful for planning policies before enforcement
Monitor what would be blocked
```

2. **Enforcement Mode** (actual blocking):
```
Requires CNI plugin support
Calico: Full support via iptables/eBPF
Flannel: No support (need Calico/Cilium alongside)
Weave: Full support
Cilium: Full support + eBPF for advanced policies
```

**How enforcement works**:
```
Pod wants to send packet
├─ Check outgoing network policies
├─ Check CIDR/port against policy rules  
├─ If not explicitly allowed, drop packet
├─ If allowed, forward normally

Packet arrives at pod
├─ Check incoming network policies
├─ Check source (pod label, namespace, IP) against rules
├─ If not explicitly allowed, drop packet
└─ If allowed, deliver to socket
```

#### Common Network Policy Mistakes

**Mistake 1: Forgetting DNS traffic**
```yaml
# Policy blocks port 53 (DNS)
# Pods can't resolve service names
#FIX: Allow egress to port 53 UDP
- to:
  - namespaceSelector: {}
  ports:
  - protocol: UDP
    port: 53
```

**Mistake 2: Blocking inter-pod communication by accident**
```yaml
# Policy blocks all ingress
# Pods can't talk to each other even within same service
# FIX: Explicitly allow required traffic
- from:
  - podSelector:
      matchLabels:
        app: frontend
```

**Mistake 3: Not accounting for kubelet-to-pod communication**
```yaml
# Policy blocks all traffic
# Kubelet health checks fail
# Readiness probes can't reach pod
# FIX: Allow node's IP range or specific kubelet traffic
ipBlock:
  cidr: 10.128.0.0/24  # Node CIDR
```

**Mistake 4: Expecting immediate effect**
```
Policies take time to propagate
Test connectivity after applying, may fail initially
Wait 10-30 seconds, retest
Check logs for policy violations
```

### CNI Plugins

#### CNI Architecture

```
kubelet (node daemon)
    ↓
Calls CNI plugin when pod created/deleted
    ↓
CNI Plugin (executable: /opt/cni/bin/plugin-name)
    ├─ Configures pod network interface
    ├─ Configures cross-node routing
    └─ May store state (node routes) in Backend
```

#### Popular CNI Plugins

**Flannel** (simplest):
```
- Uses VXLAN tunnels between nodes
- Simple to deploy
- All traffic goes through tunnel (overhead)
- No network policies (need separate controller)
- Performance: ~1 Gbps per tunnel overhead
```

**Calico** (flexible):
```
- Uses BGP routing (native routing when possible)
- Network policies via iptables/eBPF
- Great for on-premises (can peer with routers)
- Performance: Near line-rate (minimal overhead)
- Can mix BGP with VXLAN on same cluster
```

**AWS VPC CNI** (native to AWS):
```
- Uses native VPC routing
- Pod IPs are actual VPC IPs
- No overlay network
- Best performance on AWS
- IP address limitation: Pods share node's secondary IPs
```

**Azure CNI** (native to Azure):
```
- Uses native VNet routing
- Pod IPs directly in VNet
- No overlay
- Best performance on Azure
```

**Cilium** (advanced):
```
- Uses eBPF for kernel-space implementation
- Very efficient, low latency
- Strong network policies
- Service mesh operations
- Latest eBPF features (requires Linux 4.19+)
```

**Weave** (balanced):
```
- Uses VXLAN or sleeve mode
- Lightweight
- Network policies supported
- Good for hybrid/multi-cloud
```

#### CNI vs Container Runtime

**Important distinction**:
```
Container Runtime (Docker, containerd, CRI-O)
- Creates container
- Configures container isolation (cgroups, namespaces)
- NOT responsible for networking

CNI Plugin
- Separate executable
- Configured by kubelet
- Responsible for connecting container to network
- Runs when pod is scheduled
```

**Sequence**:
```
1. kubelet receives pod schedule request
2. Tells container runtime "create container X"
3. Runtime creates container
4. kubelet calls CNI plugin "add this container to network"
5. CNI plugin:
   a. Gets container netns (namespace)
   b. Creates veth pair
   c. Adds one end to netns
   d. Configures routing
   e. Updates backend (BGP, VXLAN tunnels, etc.)
6. Container now has network connectivity
```

### Cluster Networking

#### Node-to-Node Communication Requirements

```
kubelet → API server (control plane connectivity)
kubelet → kubelet (pod networking inter-node)
kubelet → etcd (data storage)
CNI plugin → CNI backend (tunnel endpoints, routing info)
Kube-proxy → Kube-proxy (service routing coordination)
```

**Firewalls must allow**:
```
- Control plane → All nodes, port 10250 (kubelet API)
- Nodes → Nodes, configurable ports (CNI dependent)
- API server → All nodes
- For Calico BGP: IBGP, port 179
- For Flannel VXLAN: UDP 8472
```

#### Service CIDR and Pod CIDR Planning

**Pod CIDR**: Space allocated to pods
```
Example: 10.244.0.0/16 (65,536 IPs)
Per-node allocation: 10.244.0.0/24, 10.244.1.0/24, etc.
Larger clusters need larger CIDR
Recommendation: /16 minimum, /14 for large clusters
```

**Service CIDR**: Space for virtual IPs
```
Example: 10.0.0.0/24 (256 IPs)
Small number of services relative to pods
Recommendation: /24 sufficient for most clusters
```

**Constraints**:
- Must not overlap
- Must not conflict with worker node IPs
- Must not conflict with external networks you'll connect to
- On AWS with VPC CNI: Pod CIDR must fit in VPC subnet

#### Dual-Stack Networking (IPv4 + IPv6)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: dual-stack-service
spec:
  ipFamilies:
  - IPv4
  - IPv6
  ipFamilyPolicy: PreferDualStack  # Prefer dual, fallback to single
  # OR
  ipFamilyPolicy: RequireDualStack  # Must support both
  selector:
    app: myapp
  ports:
  - port: 80
```

**Use cases**:
- Gradual migration to IPv6
- Cloud providers requiring IPv6 support
- Next-generation network infrastructure

### Overlay vs Underlay Networks

#### Underlay Network

```
Physical network infrastructure (what exists)
  ├─ Switches, routers, cables
  └─ Layer 2: MAC addresses

Underlay networking:
  Pod A → Network directly
  No tunneling or encapsulation
  Uses native subnet routing
```

**Examples**: AWS VPC CNI, Azure CNI, on-premises with native routing

**Advantages**:
- High performance (no encapsulation overhead)
- Native support from routers/switches
- Easier debugging (standard networking tools work)

**Disadvantages**:
- Pod IPs must fit within physical network structure
- More network configuration required
- Less flexibility for multi-cloud

#### Overlay Network

```
Virtual network on top of physical (underlay)
  ├─ Encapsulates packets
  └─ Tunnel/VXLAN between endpoints

Example (VXLAN):
  Pod A packet:
    Src: 10.244.0.5, Dst: 10.244.1.3
  Encapsulated:
    Outer Src: Node1-IP, Outer Dst: Node2-IP
    Inner: Original packet
```

**Examples**: Flannel VXLAN, Calico VXLAN mode, Weave

**Advantages**:
- Flexibility: Pod CIDR independent of physical network
- Dynamism: Easy to add nodes without network config
- Multi-cloud friendly (same overlay works anywhere)

**Disadvantages**:
- Encapsulation overhead (~50 bytes per packet)
- Performance impact (CPU for encap/decap)
- More complex routing (tunnel management)

#### Choosing Underlay vs Overlay

**Use Underlay if**:
- Single data center, high-performance requirements
- Cloud provider offers native CNI (AWS VPC, Azure)
- Existing routing infrastructure can support it

**Use Overlay if**:
- Multi-cloud or hybrid cloud
- Need maximum portability
- Performance not primary concern
- Simplified operations (no network config per pod)

### Networking Best Practices

#### 1. Network Policy by Default: Deny All

```yaml
# First, apply deny-all to every namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: kube-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

Then explicitly allow required traffic. **Never operate in "allow all" mode in production.**

#### 2. Plan CIDRs Carefully

```
Cluster planning worksheet:
Max nodes: 100
Max pods per node: 100
Max pods total: 10,000

Pod CIDR selection:
  Need: 10,000 x 2 (overhead) = 20,000 IPs minimum
  Choose: 10.244.0.0/14 (262,144 IPs)

Service CIDR selection:
  Estimate: 500 services maximum
  Choose: 10.0.0.0/24 (256 IPs) or 10.0.0.0/20 (4096 IPs)

Node CIDR:
  VPC subnet: 10.128.0.0/24 (256 IPs)
  AWS recommendation: /23 or smaller for worker nodes
```

#### 3. Monitor Network Performance

```
Metrics to track:
- Pod-to-pod latency (P50, P99)
- Inter-node latency
- Packet loss rate
- CNI plugin errors (tunnel down, route failures)
- Network policy violation count
```

#### 4. Test Network Policies in Audit Mode

```bash
# Deploy policy with annotation
metadata:
  annotations:
    # Some CNI (Calico) supports audit mode
    calico.org/log-level: "Info"

# Monitor logs for blocked packets
kubectl logs -n calico-system <policy-controller-pod>
# See what WOULD be blocked
# Adjust policy rules
# Remove audit annotation
# Apply for real enforcement
```

#### 5. Use Affinity for Latency-Sensitive Workloads

```yaml
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchExpressions:
        - key: app
          operator: In
          values:
          - frontend
      topologyKey: kubernetes.io/hostname  # Same node
```

**Use case**: Database + application on same node = lower latency.

#### 6. Document CNI Plugin Choice

```yaml
# In cluster setup documentation or ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-networking-config
  namespace: kube-system
data:
  cni-plugin: "calico"
  pod-cidr: "10.244.0.0/16"
  service-cidr: "10.0.0.0/24"
  network-policy-enabled: "true"
  overlay-type: "vxlan"  # or "native" for underlay
```

#### 7. Verify Connectivity Before Production Deployment

```bash
# Test service discovery
kubectl run --rm -it debug --image=alpine --restart=Never -- \
  sh -c 'nslookup my-service.default.svc.cluster.local'

# Test inter-pod connectivity
kubectl run --rm -it client --image=alpine --restart=Never -- \
  sh -c 'wget -O- http://my-service.default.svc.cluster.local'

# Test network policies
# (Try connecting from non-authorized pod, should fail)
```

#### 8. Monitor kube-proxy Health

```bash
# Check kube-proxy metrics
kubectl describe daemonset kube-proxy -n kube-system

# Verify kube-proxy running on all nodes
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# Check kube-proxy logs for errors
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=50
```

Broken kube-proxy = services don't work. Always verify.

#### 9. Use NetworkPolicy for Compliance

```yaml
# Document compliance requirements
metadata:
  labels:
    compliance: hipaa
    pci-dss: "3.4"  # Segregate network access
spec:
  # Implementing segregation via network policy
```

Network policies are your mechanism for enforcing compliance requirements.

#### 10. Plan for Network Troubleshooting

**Common debugging commands**:

```bash
# Inside pod
ip addr show  # Pod IP and interfaces
ip route show  # Routes
netstat -an | grep ESTABLISHED  # Connections
traceroute <ip>  # Trace route to IP

# On node
iptables-save | grep KUBE  # Service rules
ipvsadm -Ln  # IPVS rules (if using IPVS mode)
ip link show  # Physical interfaces
bridge link show  # Bridge devices

# Ingress debugging
kubectl describe ingress my-ingress
kubectl logs -n ingress-nginx <controller-pod>
curl -v -H "Host: example.com" http://<ingress-ip>/
```

---

## Service Types and Service Discovery - Deep Dive

### Textual Deep Dive: Internal Working Mechanism

#### Service Type Selection Logic

When designing services for production, the selection matrix is critical:

```
Request origin → Service Type determination
├─ Internal pod-to-pod: ClusterIP
├─ Internal with session affinity: ClusterIP + sessionAffinity
├─ External on non-standard port: NodePort (legacy or simple cases)
├─ External on HTTP/HTTPS with routing: Ingress (over ClusterIP)
├─ External on arbitrary protocol: LoadBalancer
└─ Integration with external system: ExternalName
```

**ClusterIP Architecture Deep Dive**:

The ClusterIP service is the foundation. When created:
1. Control plane allocates VIP from service CIDR
2. Service object stored in etcd
3. Endpoint controller matches labels to pods
4. Endpoint object created with pod IPs
5. kube-proxy on every node watches these objects
6. Each kube-proxy generates iptables rules or IPVS entries

**Critical insight for debugging**: A service without endpoints is a broken service. The Endpoint object is the contract between the Service API and kube-proxy. If empty, no traffic flows regardless of service configuration.

#### iptables vs IPVS Scaling Characteristics

**iptables mode** (suitable for <1000 services):
```
Per-service rule count: ~10-20 rules
Total cluster rules: Services × Rules
Performance: O(n) lookup time - matches rules sequentially
Most problematic: High-cardinality services with many endpoints
Result: CPU spike during pod additions/removals as rules rebuild
```

**IPVS mode** (suitable for >1000 services):
```
Implementation: Hash table lookup
Performance: O(1) lookup - constant time regardless of scale
Rule updates: Incremental, no full rebuild
Algorithms: rr (round-robin), lc (least connections), dh (destination hash)
Result: Efficient at scale; minimal CPU impact
```

**Production decision framework**:
- **<100 services, <100 pods per service**: iptables fine
- **100-500 services**: Monitor CPU, consider IPVS
- **>500 services**: IPVS mandatory for performance
- **High-churn clusters** (frequent pod additions/deletions): IPVS
- **Persistent connections** (gRPC, WebSockets): IPVS with least connections

#### DNS Caching and Service Discovery Reliability

**CoreDNS TTL Behavior**:
```
DNS Query → CoreDNS → Kubernetes Plugin
├─ Returns A record with TTL (default 30s)
├─ Client caches for TTL duration
└─ After TTL expiry, new query to CoreDNS

Problem: If pod crashes and restarts with new IP:
├─ DNS still has old IP cached on client
├─ TCP connects to old IP (connection refused)
├─ Client may timeout and retry
├─ Eventually gets fresh DNS response
└─ Reconnects to new IP
Result: 30-60 second recovery time in worst case
```

**Application-level caching compounds the problem**:
```go
// Bad: Caches DNS result indefinitely
IPs := resolveDNS("my-service.default.svc.cluster.local")
selectedIP := IPs[rand.Intn(len(IPs))]
// Uses same IP forever; pod restart breaks this pod
```

**Better approach**: Let connection libraries handle DNS caching per connection, not application-wide.

#### Production Usage Patterns

**Pattern 1: Web Service with Scaling**

```
Deployment with 3-10 replicas
ClusterIP Service (frontend can find any pod)
Readiness probes (broken pods removed from service)
Result: Automatic load balancing as replicas scale
```

**Pattern 2: Stateful Service (Headless)**

```
StatefulSet with 3 replicas
Headless Service (DNS returns all pod IPs)
Application knows about all replicas (leader election, quorum)
Example: Elasticsearch, Cassandra, Consul
```

**Pattern 3: External Dependency Integration**

```
ExternalName Service
Points to external database, API, etc.
Pods use consistent internal name
External endpoint can change without updating pod configs
Example: RDS endpoint, managed database
```

**Pattern 4: Multi-Region Service**

```
Primary region: LoadBalancer service
Secondary region: LoadBalancer service
Geographic DNS routing at DNS provider
Clients route to closest region automatically
```

#### DevOps Best Practices for Service Management

**Practice 1: Versioned Service Names**

```yaml
# Old approach (causes problems)
Service: api-service
# Now update: which version? Breaking change?

# Better approach
Service: api-service-v1
Service: api-service-v2
# Explicit versioning, teams know what they're using
# Gradients: frontend v1 → api v1, frontend v2 → api v1 and v2
```

**Practice 2: Service Monitoring Dashboards**

Key metrics per service:
- Request count and rate
- Error rate (by error type)
- P50/P95/P99 latencies
- Active connections
- Endpoint count (healthy vs total)
- Connection churn rate

**Practice 3: Service Discovery Health Checks**

```bash
# Weekly validation script
for service in $(kubectl get services -o name); do
  endpoints=$(kubectl get endpoints $service -o jsonpath='{.subsets[*].addresses}')
  if [ -z "$endpoints" ]; then
    alert "Service $service has no endpoints!"
  fi
done
```

**Practice 4: Label Governance**

```yaml
# Enforce specific labels on all pods
# Using admission controller or GitOps validation
required_labels:
  - app
  - version
  - tier
  - team
  - cost-center
```

#### Common Pitfalls

**Pitfall 1: Selector Typos**

```yaml
Service selector: app: myapp
Pod label: app: my-app  # Different!
Result: No endpoints, service doesn't work
Detection: kubectl get endpoints shows <none>
```

**Pitfall 2: Session Affinity with Uneven Pods**

```
10 pods, 100 client IPs
SessionAffinity: ClientIP (sticky)
Result: Load imbalance
├─ Pod 1: 14 connections
├─ Pod 2: 8 connections
├─ Pod 3: 3 connections
└─ Pods 4-10: Very few connections

Fix: Use connection pooling, not sticky sessions
```

**Pitfall 3: Assuming Pod IPs are Stable**

```go
// Bad: Hardcodes pod IP
conn, _ := net.Dial("tcp", "10.244.0.5:8080")

// Good: Uses service DNS
conn, _ := net.Dial("tcp", "my-service:8080")
```

**Pitfall 4: Not Accounting for Service Startup Time**

```
Service created
Endpoints may take 1-2 seconds to populate
Clients connecting immediately get connection refused
Fix: Add retries in client code, wait for service endpoint before deploying pods
```

### Practical Code Examples

#### Shell Script: Multi-Service Health Check

```bash
#!/bin/bash
# manage-services.sh - Service discovery and health validation

set -e

NAMESPACE="${1:-default}"
ALERT_EMAIL="devops@company.com"

# Function to check service endpoint health
check_service_health() {
    local service=$1
    local namespace=$2
    
    # Get endpoint count
    endpoint_count=$(kubectl get endpoints $service -n $namespace \
        -o jsonpath='{.subsets[0].addresses | length}' 2>/dev/null || echo "0")
    
    if [ "$endpoint_count" -eq 0 ]; then
        echo "CRITICAL: Service $service has 0 endpoints"
        
        # Diagnostic info
        echo "Service definition:"
        kubectl get service $service -n $namespace -o yaml
        
        echo "Pod labels:"
        kubectl get pods -n $namespace --show-labels
        
        echo "Selector from service:"
        selector=$(kubectl get service $service -n $namespace \
            -o jsonpath='{.spec.selector}')
        echo "Selector: $selector"
        
        # Try to find matching pods
        echo "Pods matching selector:"
        kubectl get pods -n $namespace -l $selector || echo "No pods found"
        
        return 1
    else
        echo "OK: Service $service has $endpoint_count endpoints"
        return 0
    fi
}

# Function to validate service DNS
check_service_dns() {
    local service=$1
    local namespace=$2
    
    # Create temporary pod to test DNS
    pod_name="dns-test-$RANDOM"
    
    kubectl run $pod_name -n $namespace \
        --image=alpine:latest \
        --restart=Never \
        -- nslookup ${service}.${namespace}.svc.cluster.local
    
    # Cleanup
    kubectl delete pod $pod_name -n $namespace
}

# Function to diagnose kube-proxy issues
check_kubeproxy_health() {
    echo "Checking kube-proxy on all nodes..."
    
    for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
        echo "Node: $node"
        
        # Check if kube-proxy pod is running
        proxy_pod=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy \
            --field-selector spec.nodeName=$node \
            -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        
        if [ -z "$proxy_pod" ]; then
            echo "  WARNING: No kube-proxy pod found"
            continue
        fi
        
        status=$(kubectl get pod $proxy_pod -n kube-system \
            -o jsonpath='{.status.phase}')
        
        echo "  kube-proxy pod: $proxy_pod (status: $status)"
        
        if [ "$status" != "Running" ]; then
            echo "  ERROR: kube-proxy not running!"
            kubectl logs $proxy_pod -n kube-system --tail=20
        fi
    done
}

# Function to export service metrics
export_service_metrics() {
    local service=$1
    local namespace=$2
    
    # Get cluster IP
    cluster_ip=$(kubectl get service $service -n $namespace \
        -o jsonpath='{.spec.clusterIP}')
    
    # Get endpoint count
    endpoint_count=$(kubectl get endpoints $service -n $namespace \
        -o jsonpath='{.subsets[0].addresses | length}' 2>/dev/null || echo "0")
    
    # Get service type
    service_type=$(kubectl get service $service -n $namespace \
        -o jsonpath='{.spec.type}')
    
    # Get external IP (if LoadBalancer)
    external_ip=$(kubectl get service $service -n $namespace \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "N/A")
    
    # Output as metrics (Prometheus format)
    echo "# HELP kubernetes_service_endpoints_total Total endpoints for service"
    echo "# TYPE kubernetes_service_endpoints_total gauge"
    echo "kubernetes_service_endpoints_total{service=\"$service\",namespace=\"$namespace\"} $endpoint_count"
    
    echo "# HELP kubernetes_service_info Service metadata"
    echo "# TYPE kubernetes_service_info gauge"
    echo "kubernetes_service_info{service=\"$service\",namespace=\"$namespace\",type=\"$service_type\",cluster_ip=\"$cluster_ip\",external_ip=\"$external_ip\"} 1"
}

# Main execution
echo "=== Service Discovery Health Check ==="
echo "Namespace: $NAMESPACE"
echo ""

# Check all services
failed_services=0
for service in $(kubectl get services -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    if ! check_service_health $service $NAMESPACE; then
        ((failed_services++))
    fi
done

echo ""
echo "=== kube-proxy Status ==="
check_kubeproxy_health

echo ""
echo "=== Service Metrics Export ==="
for service in $(kubectl get services -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}'); do
    export_service_metrics $service $NAMESPACE
done

echo ""
if [ $failed_services -gt 0 ]; then
    echo "ALERT: $failed_services services with issues detected"
    # Send alert (example)
    # echo "Service health check found $failed_services critical issues" | mail -s "Kubernetes Service Alert" $ALERT_EMAIL
    exit 1
fi

echo "All services healthy"
exit 0
```

#### Kubernetes Manifest: Complete Service Example

```yaml
---
# Application Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service-v1
  namespace: production
  labels:
    app: api
    version: v1
    tier: backend
    team: backend-team
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api
      version: v1
  template:
    metadata:
      labels:
        app: api
        version: v1
        tier: backend
        team: backend-team
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
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
      
      containers:
      - name: api
        image: my-repo/api:v1.2.3
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        
        env:
        - name: LOG_LEVEL
          value: "info"
        - name: SERVICE_ENV
          value: "production"
        
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        
        # Critical for service discovery
        readinessProbe:
          httpGet:
            path: /health/ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        livenessProbe:
          httpGet:
            path: /health/live
            port: http
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]

---
# ClusterIP Service (default, internal)
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: production
  labels:
    app: api
    tier: backend
  annotations:
    description: "Internal load balancer for API service v1"
spec:
  type: ClusterIP
  selector:
    app: api
    version: v1
  
  ports:
  - name: http
    protocol: TCP
    port: 8080
    targetPort: http
  
  - name: metrics
    protocol: TCP
    port: 9090
    targetPort: metrics
  
  # Session affinity disabled (stateless app)
  sessionAffinity: None
  
  # DNS policy for pod hostname resolution
  dnsPolicy: ClusterFirst

---
# Headless Service for ordered pod access
apiVersion: v1
kind: Service
metadata:
  name: api-service-direct
  namespace: production
  labels:
    app: api
spec:
  type: ClusterIP
  clusterIP: None  # Headless - no VIP
  selector:
    app: api
    version: v1
  
  ports:
  - port: 8080
    targetPort: http

---
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-service
  namespace: production
spec:
  selector:
    matchLabels:
      app: api
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### ASCII Diagrams: Service Architecture

#### Diagram 1: Service Selection and Load Balancing

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CLIENT POD (10.244.0.1)                         │
│      Connects to: api-service.default.svc.cluster.local:8080           │
└────────────────────────────┬────────────────────────────────────────────┘
                             │
                             │ DNS Resolution
                             ↓
                    ┌────────────────────┐
                    │   CoreDNS Resolver │
                    │ api-service        │
                    │ → 10.0.0.5 (VIP)   │
                    └────────┬───────────┘
                             │
                             ↓
                ┌────────────────────────────┐
                │  SERVICE VIP: 10.0.0.5:8080 │
                │  (Living in kernel routing) │
                └────────┬───────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ↓              ↓              ↓
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │KUBE-PROXY│   │KUBE-PROXY│   │KUBE-PROXY│
    │Node 1    │   │Node 2    │   │Node 3    │
    └──────────┘   └──────────┘   └──────────┘
    
    kube-proxy on Node 1 (iptables rules):
    ─────────────────────────────────────────
    -A KUBE-SERVICES -d 10.0.0.5/32 -j KUBE-SVC-API
    
    -A KUBE-SVC-API -m statistic --mode random \
           --probability 0.33 -j KUBE-SEP-ENDPOINT1
    -A KUBE-SVC-API -m statistic --mode random \
           --probability 0.50 -j KUBE-SEP-ENDPOINT2
    -A KUBE-SVC-API -j KUBE-SEP-ENDPOINT3
    
    -A KUBE-SEP-ENDPOINT1 -j DNAT --to-destination 10.244.0.5:8080
    -A KUBE-SEP-ENDPOINT2 -j DNAT --to-destination 10.244.1.7:8080
    -A KUBE-SEP-ENDPOINT3 -j DNAT --to-destination 10.244.2.3:8080

    ┌──────────────────────────────────────────────────────────────┐
    │              ENDPOINT CONTROLLER LOOP                        │
    │                                                               │
    │  1. Watch Service: api-service                              │
    │     Selector: app=api, version=v1                           │
    │                                                               │
    │  2. Find Pods matching:                                      │
    │     ✓ api-pod-abc1 (10.244.0.5) - Ready                    │
    │     ✓ api-pod-xyz2 (10.244.1.7) - Ready                    │
    │     ✓ api-pod-def3 (10.244.2.3) - Ready                    │
    │     ✗ api-pod-old (10.244.1.9)  - Terminating (excluded)   │
    │                                                               │
    │  3. Create Endpoint object:                                 │
    │     endpoints.subsets[0].addresses = [                      │
    │       {ip: 10.244.0.5, targetRef: api-pod-abc1},          │
    │       {ip: 10.244.1.7, targetRef: api-pod-xyz2},          │
    │       {ip: 10.244.2.3, targetRef: api-pod-def3}           │
    │     ]                                                         │
    │                                                               │
    │  4. kube-proxy watching Endpoint → Updates iptables         │
    └──────────────────────────────────────────────────────────────┘
          │
          ↓
      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
      │   Pod 1     │      │   Pod 2     │      │   Pod 3     │
      │10.244.0.5:80│      │10.244.1.7:80│      │10.244.2.3:80│
      │   Running   │      │   Running   │      │   Running   │
      └─────────────┘      └─────────────┘      └─────────────┘
```

#### Diagram 2: Service Type Comparison and Data Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                    CLIENT (INTERNAL OR EXTERNAL)                       │
└────────────────────────────────────────────────────────────────────────┘

    │
    ├─ CLUSTERIP (Internal Only)
    │   ├─ Source: Internal pod only
    │   ├─ VIP: 10.0.0.5:8080
    │   ├─ Access: my-service.default.svc.cluster.local
    │   ├─ Route: Pod → Service VIP → iptables DNAT → Pod IP
    │   └─ Example: $ kubectl exec client-pod -- curl http://api-service:8080
    │
    ├─ NODEPORT (External via Node)
    │   ├─ Source: Any (internal or external)
    │   ├─ Node Port: 30000-32767 (automatic or specified)
    │   ├─ Access: <any-node-ip>:30000
    │   ├─ Route: External → Node:30000 → iptables → Pod
    │   └─ Problem: Masquerades source IP (unless externalTrafficPolicy: Local)
    │   └─ Example: $ curl http://worker-node-ip:30000
    │
    ├─ LOADBALANCER (External via Cloud LB)
    │   ├─ Source: External/Internal
    │   ├─ Cloud LB: AWS ELB, GCP LB, Azure LB (costs money)
    │   ├─ Access: <cloud-lb-ip>:80
    │   ├─ Route: External → Cloud LB → Node:NodePort → Pod
    │   ├─ externalTrafficPolicy: Local (preserve source IP, uneven dist)
    │   │                         Cluster (masquerade, even dist)
    │   └─ Example: $ curl http://my-app-abc123.elb.amazonaws.com
    │
    ├─ EXTERNALNAME (DNS Alias)
    │   ├─ Source: Internal only
    │   ├─ No VIP: Just DNS forwarding
    │   ├─ Access: my-external-service → external-db.example.com
    │   ├─ Route: Pod DNS query → Resolved to external IP → Direct connection
    │   └─ Example: $ kubectl exec client -- mysql -h my-db-service -u user
    │               (Actually connects to rds.amazonaws.com)
    │
    └─ HEADLESS (Direct Pod Access)
        ├─ Source: Internal
        ├─ VIP: None (clusterIP: None)
        ├─ Access: Returns all pod IPs from DNS
        ├─ Route: Pod → Selects specific pod IP → Connects directly
        ├─ Use: StatefulSets, leadership elections
        └─ Example: $ nslookup api-service → Returns:
                      10.244.0.5 (api-0)
                      10.244.1.7 (api-1)
                      10.244.2.3 (api-2)
```

---

## Ingress and Traffic Management - Deep Dive

### Textual Deep Dive: The Reverse Proxy Contract

#### How Ingress Controllers Translate API Specifications

An Ingress Resource is a **declarative interface**. It describes desired routing rules. The actual implementation is delegated to the Ingress Controller:

```
User writes:
├─ path: /api
├─ backend: api-service:8000
└─ Expected: Requests to /api route to api-service

Ingress Controller reads API and:
├─ Resolves api-service to IP address(es)
├─ Generates reverse proxy config syntax
├─ Validates configuration
├─ Deploys/hot-reloads proxy
└─ Returns status (IP, hostname) to Ingress object
```

**Different controllers implement differently**:
- **NGINX**: Generates nginx.conf, hot-reloads
- **HAProxy**: Generates haproxy.cfg, restarts (usually graceful)
- **Traefik**: Dynamic discovery, updates on the fly
- **AWS ALB**: API calls to AWS to configure actual ALB

#### Performance Implications of Ingress Controller Design

**NGINX Ingress (reload-based)**:
```
Change detected (new Ingress, Service update, etc.)
    ↓
Generate nginx.conf
    ↓
Validate syntax (nginx -t)
    ↓
Send HUP signal to NGINX master process
    ↓
Master spawns new worker processes with new config
    ↓
Old worker processes drain connections (graceful shutdown)
    ↓
New workers accept incoming connections
    ↓
All connections eventually migrate to new workers

Impact on in-flight requests:
- Long-lived connections (WebSocket, gRPC): Unaffected (connection persists)
- HTTP keep-alive: Affected during reload (brief pause)
- New HTTP requests: Served by new workers immediately
- Latency spike: Usually <100ms
```

**Traefik (dynamic)**:
```
Change detected
    ↓
Update route rules in memory (no reload)
    ↓
New requests immediately use new rules
    ↓
No disruption to connections

Impact: Zero disruption, most modern approach
```

#### Ingress Controller Failure Modes

**Single Replica (don't do this in production)**:
```
┌──────────────────────┐
│ Ingress Controller 1 │  Single point of failure
│   (NGINX pod)        │  
│   Status: Running    │
└──────────────────────┘

Pod crashes → No ingress controller → Traffic lost
Recovery: Manual restart or reconciliation loop (if configured)
Time to recovery: 1-5 minutes
```

**High Availability Setup**:
```
┌────────────────────────┐        ┌────────────────────────┐
│ Ingress Controller 1   │        │ Ingress Controller 2   │
│   (NGINX pod)          │        │   (NGINX pod)          │
│   Status: Running      │        │   Status: Running      │
└────────────────────────┘        └────────────────────────┘
         │                                 │
         └─────────────┬───────────────────┘
                       │
                  Cloud Load Balancer
              (distributes traffic to both)
                       │
        ┌──────────────┴──────────────┐
        │                             │
    ┌───▼────┐                   ┌───▼────┐
    │Service 1│                   │Service 2│
    │(api)   │                   │(web)   │
    └────────┘                   └────────┘

If Controller 1 fails:
├─ Cloud LB detects (health check fails)
├─ Removes from pool
├─ All traffic goes to Controller 2
├─ No user-facing impact
└─ Recovery: Controller 1 restarts, rejoins pool

Pod Disruption Budget: Ensure minimum 2 replicas always
```

#### Layer 7 Decisions and Implications

**Path-based routing** (most common):
```
/api/v1 → api-v1-service
/api/v2 → api-v2-service
/static → cdn-service
/ → default-service

Decision point: Happens after HTTP parsing
Cost: URL parsing, regex matching per request
Performance: Low impact, milliseconds
Benefits: Decouples service versions from deployment
```

**Host-based routing** (virtual hosting):
```
api.example.com → api-service
web.example.com → web-service
admin.example.com → admin-service
*.example.com → wildcard-service

Decision point: Host header matching
Cost: String comparison per request
Performance: Negligible
Benefits: Same cluster serves multiple domains
```

**TLS offloading** (critical feature):
```
Without Ingress TLS:
├─ Clients connect with HTTPS
├─ Pods must handle TLS crypto
├─ CPU intensive (TLS handshake, encryption)
└─ Every request has crypto overhead

With Ingress TLS:
├─ Clients → Ingress (HTTPS, encrypted)
├─ Ingress → Pods (HTTP, plaintext, internal network)
├─ Pods use CPU for application logic, not crypto
├─ Centralized certificate management
└─ Cost: CPU on ingress controller, saved on backend pods
```

**Practical effect of TLS offloading**:
```
Without: 10-15% CPU overhead per pod for crypto
With: ~2-3% CPU overhead on ingress controller for 100+ pods
Result: Significant cost savings at scale
```

#### Advanced Traffic Management

**Rate limiting at Ingress**:
```yaml
nginx.ingress.kubernetes.io/rate-limit: "100"
# Allows 100 requests per second per client IP

Benefits:
├─ Protects backend from DDoS
├─ Prevents single misbehaving client from affecting others
├─ Reduces load on services
└─ Cheap CPU on ingress vs expensive database on backend

Granularity options:
├─ By client IP: rate-limit-by: "$binary_remote_addr"
├─ By user: rate-limit-by: "$http_x_user_id"
├─ By session: rate-limit-by: "$cookie_session"
└─ All clients share pool: rate-limit-by: "1"
```

**Traffic shaping (for canaries)**:
```yaml
# Route 90% to stable, 10% to canary
# Not natively supported in Ingress
# Requires Flagger, Argo Rollouts, or service mesh

Traffic split: Weighted by replicas
├─ Stable version: 9 replicas → 90% traffic
├─ Canary version: 1 replica → 10% traffic
└─ Monitor canary metrics (errors, latency)
    If good: Increase canary replicas
    If bad: Decrease canary replicas
```

### Practical Code Examples

#### NGINX Ingress with Authentication

```yaml
---
# Create basic auth secret
apiVersion: v1
kind: Secret
metadata:
  name: admin-credentials
  namespace: ingress-nginx
type: Opaque
data:
  auth: YWRtaW46JGFwcjEkZ3dtTG0xcy9NVVF3dURMTkJKSkZMclkxNTExMA==
  # Generated via: htpasswd -cb auth admin password
  # then: base64 -w 0 auth

---
# Ingress with authentication
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: admin-portal
  namespace: default
  annotations:
    # Enable basic authentication
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-credentials
    nginx.ingress.kubernetes.io/auth-realm: 'Admin Dashboard'
    
    # Rate limiting for authenticated requests
    nginx.ingress.kubernetes.io/limit-rps: "50"
    
    # CORS settings
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://example.com"
    nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
    
    # SSL redirect
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Connect timeout
    nginx.ingress.kubernetes.io/connect-timeout: "600"
    nginx.ingress.kubernetes.io/send-timeout: "600"
    
    # Buffering (for large responses)
    nginx.ingress.kubernetes.io/proxy-buffering: "on"
    nginx.ingress.kubernetes.io/proxy-buffer-size: "4k"
    
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - admin.example.com
    secretName: admin-tls-secret
  
  rules:
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 8080

---
# Ingress controller configuration via ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: ingress-nginx
data:
  # Enable log streaming for debugging
  access-log-buffer-size: "32k"
  
  # Performance tuning
  worker-processes: "4"
  worker-connections: "65536"
  
  # Time zone for logs
  log-format-upstream: '$remote_addr [$proxy_protocol_addr] - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$request_time"'
  
  # Upstream configuration
  keep-alive-requests: "32"
  keep-alive-timeout: "75"
  
  # Default backend behavior
  custom-http-errors: "404,502,503"
  default-backend-service: "ingress-nginx/default-backend"
  
  # Security headers
  add-headers: "ingress-nginx/custom-headers"

---
# Custom headers ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-headers
  namespace: ingress-nginx
data:
  X-Frame-Options: "SAMEORIGIN"
  X-Content-Type-Options: "nosniff"
  X-XSS-Protection: "1; mode=block"
  Strict-Transport-Security: "max-age=31536000; includeSubDomains; preload"
```

#### Shell Script: Ingress Health and Performance Monitoring

```bash
#!/bin/bash
# ingress-monitor.sh - Monitor Ingress controller health and performance

set -e

NAMESPACE="ingress-nginx"
ALERT_THRESHOLD_ERROR_RATE=5  # 5% error rate
ALERT_THRESHOLD_P99_LATENCY=1000  # 1000ms

# Function: Check controller health
check_controller_health() {
    echo "=== Ingress Controller Health ==="
    
    # Check pod status
    pod_status=$(kubectl get pod -n $NAMESPACE \
        -l app.kubernetes.io/name=ingress-nginx \
        -o jsonpath='{.items[*].status.phase}')
    
    if [[ "$pod_status" == *"CrashLoopBackOff"* ]] || [[ "$pod_status" == *"Failed"* ]]; then
        echo "ERROR: Ingress controller pod failed"
        kubectl describe pod -n $NAMESPACE -l app.kubernetes.io/name=ingress-nginx
        return 1
    fi
    
    # Check ready replicas
    ready_replicas=$(kubectl get deployment -n $NAMESPACE \
        -l app.kubernetes.io/name=ingress-nginx \
        -o jsonpath='{.items[0].status.readyReplicas}')
    
    desired_replicas=$(kubectl get deployment -n $NAMESPACE \
        -l app.kubernetes.io/name=ingress-nginx \
        -o jsonpath='{.items[0].spec.replicas}')
    
    echo "Replicas: $ready_replicas/$desired_replicas ready"
    
    if [ $ready_replicas -lt $((desired_replicas / 2)) ]; then
        echo "WARNING: Less than 50% replicas running"
        return 1
    fi
    
    echo "OK: Controller healthy"
    return 0
}

# Function: Check Ingress endpoints
check_ingress_endpoints() {
    echo ""
    echo "=== Ingress Endpoints Status ==="
    
    # Get all ingress resources
    ingresses=$(kubectl get ingress -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{"\n"}{end}')
    
    while IFS='/' read -r namespace name; do
        echo "Ingress: $namespace/$name"
        
        # Get backend services
        services=$(kubectl get ingress $name -n $namespace \
            -o jsonpath='{.spec.rules[*].http.paths[*].backend.service.name}' | tr ' ' '\n' | sort -u)
        
        for service in $services; do
            # Check if service exists
            if ! kubectl get service $service -n $namespace &>/dev/null; then
                echo "  ERROR: Service $service not found"
                continue
            fi
            
            # Check endpoints
            endpoints=$(kubectl get endpoints $service -n $namespace \
                -o jsonpath='{.subsets[0].addresses | length}' 2>/dev/null || echo "0")
            
            if [ "$endpoints" -eq 0 ]; then
                echo "  ERROR: Service $service has 0 endpoints"
            else
                echo "  OK: Service $service has $endpoints endpoints"
            fi
        done
    done <<< "$ingresses"
}

# Function: Check controller logs for errors
check_controller_logs() {
    echo ""
    echo "=== Recent Controller Errors (last 50 lines) ==="
    
    kubectl logs -n $NAMESPACE \
        -l app.kubernetes.io/name=ingress-nginx \
        --tail=50 | grep -i error || echo "No errors found"
}

# Function: Extract performance metrics
extract_performance_metrics() {
    echo ""
    echo "=== Performance Metrics ==="
    
    # Port-forward to metrics endpoint (if not already running)
    if ! nc -z localhost 10254 2>/dev/null; then
        kubectl port-forward -n $NAMESPACE \
            svc/ingress-nginx-controller 10254:10254 &>/dev/null &
        sleep 2
    fi
    
    # Query Prometheus metrics endpoint
    metrics=$(curl -s http://localhost:10254/metrics 2>/dev/null)
    
    # Extract key metrics
    echo "$metrics" | grep "nginx_ingress_controller_requests_total" | head -5
    echo "$metrics" | grep "nginx_ingress_controller_request_duration" | head -5
    echo "$metrics" | grep "nginx_ingress_controller_ingress_upstream" | head -5
}

# Function: Test actual ingress routing
test_ingress_routing() {
    echo ""
    echo "=== Ingress Routing Test ==="
    
    # Get ingress IP/hostname
    ingress_ip=$(kubectl get ingress -A -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    ingress_hostname=$(kubectl get ingress -A -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -z "$ingress_ip" ] && [ -z "$ingress_hostname" ]; then
        echo "WARNING: No ingress IP or hostname assigned yet"
        return 0
    fi
    
    endpoint="${ingress_ip:-$ingress_hostname}"
    echo "Testing against: $endpoint"
    
    # Get first ingress rule
    ingress_host=$(kubectl get ingress -A -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null)
    
    if [ -n "$ingress_host" ]; then
        echo "Testing host: $ingress_host"
        
        # Test connectivity
        http_code=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Host: $ingress_host" \
            "http://$endpoint/" || echo "000")
        
        echo "HTTP response code: $http_code"
        
        if [ "$http_code" == "000" ]; then
            echo "ERROR: Connection failed"
        elif [ "${http_code:0:1}" == "5" ]; then
            echo "ERROR: Server error ($http_code)"
        elif [ "${http_code:0:1}" == "4" ]; then
            echo "WARNING: Client error ($http_code)"
        else
            echo "OK: Connection successful ($http_code)"
        fi
    fi
}

# Function: Check for configuration issues
check_ingress_config() {
    echo ""
    echo "=== Ingress Configuration Validation ==="
    
    # Check for duplicate paths in single ingress
    kubectl get ingress -A -o json | jq -r \
        '.items[] | "\(.metadata.namespace)/\(.metadata.name): \(.spec.rules[].http.paths[] | "\(.path)")' | \
        sort | uniq -d | if grep .; then
            echo "WARNING: Duplicate paths found in ingress rules"
        fi
    
    # Check for services referenced by ingress that don't exist
    kubectl get ingress -A -o json | jq -r \
        '.items[] | {ns: .metadata.namespace, services: [.spec.rules[].http.paths[].backend.service.name]}' | \
        while IFS= read -r line; do
            namespace=$(echo "$line" | jq -r '.ns')
            services=$(echo "$line" | jq -r '.services[]')
            
            for service in $services; do
                if ! kubectl get service $service -n $namespace &>/dev/null; then
                    echo "ERROR: Service $service not found in namespace $namespace"
                fi
            done
        done
}

# Main execution
echo "Ingress Controller Monitoring Report"
echo "Time: $(date)"
echo "=================================="
echo ""

# Run all checks
check_controller_health
check_ingress_endpoints
check_controller_logs
extract_performance_metrics
test_ingress_routing
check_ingress_config

echo ""
echo "=================================="
echo "Report completed"
```

#### Terraform Configuration: Ingress with Multi-Environment Support

```hcl
# main.tf - Ingress management via Terraform

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

variable "environment" {
  type    = string
  default = "staging"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "apps" {
  type = map(object({
    namespace   = string
    service     = string
    service_port = number
    replicas    = number
    domain      = string
    paths       = list(string)
    tls_enabled = bool
  }))
}

local {
  common_labels = {
    managed_by  = "terraform"
    environment = var.environment
    team        = "platform"
  }
}

# Ingress resource
resource "kubernetes_ingress_v1" "main" {
  for_each = var.apps
  
  metadata {
    name      = "${each.key}-ingress"
    namespace = each.value.namespace
    labels    = local.common_labels
    annotations = {
      "cert-manager.io/cluster-issuer"                = "letsencrypt-${var.environment}"
      "nginx.ingress.kubernetes.io/ssl-redirect"      = "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
      "nginx.ingress.kubernetes.io/rate-limit"        = var.environment == "prod" ? "100" : "1000"
      "nginx.ingress.kubernetes.io/proxy-body-size"   = "100m"
    }
  }
  
  spec {
    ingress_class_name = "nginx"
    
    # TLS configuration
    dynamic "tls" {
      for_each = each.value.tls_enabled ? [1] : []
      content {
        hosts       = [each.value.domain]
        secret_name = "${each.key}-tls-secret"
      }
    }
    
    # Routing rules
    dynamic "rule" {
      for_each = each.value.tls_enabled ? [1] : []
      content {
        host = each.value.domain
        http {
          dynamic "path" {
            for_each = each.value.paths
            content {
              path     = path.value
              path_type = "Prefix"
              
              backend {
                service {
                  name = each.value.service
                  port {
                    number = each.value.service_port
                  }
                }
              }
            }
          }
        }
      }
    }
    
    # Non-TLS rule
    dynamic "rule" {
      for_each = !each.value.tls_enabled ? [1] : []
      content {
        host = each.value.domain
        http {
          dynamic "path" {
            for_each = each.value.paths
            content {
              path      = path.value
              path_type = "Prefix"
              
              backend {
                service {
                  name = each.value.service
                  port {
                    number = each.value.service_port
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

# Monitoring service monitor
resource "kubernetes_manifest" "ingress_monitor" {
  for_each = var.apps
  
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "${each.key}-monitor"
      namespace = each.value.namespace
      labels    = local.common_labels
    }
    spec = {
      selector = {
        matchLabels = {
          app = each.key
        }
      }
      endpoints = [{
        port     = "metrics"
        interval = "30s"
        path     = "/metrics"
      }]
    }
  }
}

# Output ingress details
output "ingress_addresses" {
  value = {
    for key, ingress in kubernetes_ingress_v1.main :
    key => {
      hostname = try(ingress.status[0].load_balancer[0].ingress[0].hostname, "pending")
      ip       = try(ingress.status[0].load_balancer[0].ingress[0].ip, "pending")
    }
  }
}

# Inputs for prod environment
# -var-file="prod.tfvars"
# Example prod.tfvars:
# environment = "prod"
# apps = {
#   api = {
#     namespace    = "production"
#     service      = "api-service"
#     service_port = 8000
#     replicas     = 5
#     domain       = "api.example.com"
#     paths        = ["/api"]
#     tls_enabled  = true
#   }
#   web = {
#     namespace    = "production"
#     service      = "web-service"
#     service_port = 80
#     replicas     = 3
#     domain       = "example.com"
#     paths        = ["/"]
#     tls_enabled  = true
#   }
# }
```

### ASCII Diagrams: Ingress Architecture

#### Diagram 1: Ingress Controller Workflow

```
┌────────────────────────────────────────────────────────────────────┐
│                  USER APPLIES INGRESS MANIFEST                    │
│                                                                    │
│  apiVersion: networking.k8s.io/v1                                 │
│  kind: Ingress                                                    │
│  metadata:                                                         │
│    name: my-app                                                   │
│  spec:                                                            │
│    rules:                                                         │
│    - host: example.com                                            │
│      http:                                                        │
│        paths:                                                     │
│        - path: /api                                               │
│          backend:                                                 │
│            service:                                               │
│              name: api-service                                    │
│              port: 8000                                           │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ↓
        ┌──────────────────────────────────┐
        │  API SERVER (stores object)      │
        │  ├─ Ingress manifest validated   │
        │  └─ Stored in etcd               │
        └──────────┬───────────────────────┘
                   │
                   ↓
        ┌──────────────────────────────────┐
        │  INGRESS CONTROLLER WATCHER      │
        │  Watches for:                    │
        │  ├─ New Ingress objects          │
        │  ├─ Modified Ingress objects    │
        │  ├─ Service updates              │
        │  └─ Secret updates (TLS certs)   │
        └──────────┬───────────────────────┘
                   │
                   ↓
        ┌──────────────────────────────────┐
        │  CONFIGURATION GENERATION       │
        │  ├─ Parse Ingress spec           │
        │  ├─ Resolve service names to IPs │
        │  ├─ Load TLS certificates        │
        │  ├─ Generate proxy config        │
        │  │  (nginx.conf, haproxy.cfg)    │
        │  └─ Validate syntax              │
        └──────────┬───────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ↓                     ↓
┌──────────────┐      ┌──────────────┐
│ NGINX Config │      │ Config Valid? │
│ Generated    │      │    NO → Fix  │
│              │      └──────────────┘
│ upstream my_service {
│   server 10.244.0.1:8000;
│   server 10.244.1.2:8000;
│   server 10.244.2.3:8000;
│ }
│
│ server {
│   server_name example.com;
│   listen 80;
│
│   location /api {
│     proxy_pass http://my_service;
│     proxy_set_header Host $host;
│     ...
│   }
│ }
│              │
└──────────────┘
       │
       ↓
┌──────────────────────────────────┐
│  NGINX RELOAD/RESTART            │
│                                  │
│  Option 1 (preferred):           │
│  ├─ Send HUP signal              │
│  ├─ Master spawns new workers    │
│  └─ Old workers drain, exit      │
│                                  │
│  Option 2:                       │
│  ├─ Kill NGINX process           │
│  └─ Start new process            │
│                                  │
│  In-flight requests:             │
│  ├─ HTTP keep-alive: Migrate     │
│  ├─ WebSocket: Continue (stream) │
│  ├─ New requests: Served         │
│  └─ Downtime: ~0-100ms           │
└──────────┬───────────────────────┘
           │
           ↓
 ┌─────────────────────────────────┐
 │  INGRESS CONTROLLER UPDATES      │
 │  INGRESS STATUS                  │
 │  ├─ loadBalancer.ingress[].ip =  │
 │  │   1.2.3.4 (cloud LB external) │
 │  └─ loadBalancer.ingress[].host =│
 │      my-app-xyz.elb.amazonaws    │
 └─────────────────────────────────┘
           │
           ↓
 ┌─────────────────────────────────┐
 │  EXTERNAL TRAFFIC FLOW           │
 │                                 │
 │  Client: curl -H "Host:          │
 │  example.com" https://           │
 │  my-app-xyz.elb.amazonaws.com/   │
 └─────────────┬───────────────────┘
               │
               ↓
    ┌──────────────────────────────┐
    │  AWS ELASTIC LOAD BALANCER   │
    │  (1.2.3.4:443)               │
    │  TLS termination             │
    │  Distributes to nodes        │
    └──────────┬───────────────────┘
               │
        ┌──────┴──────┐
        │             │
        ↓             ↓
    ┌────────┐   ┌────────┐
    │Node 1  │   │Node 2  │
    │NGINX   │   │NGINX   │
    │:30000  │   │:30000  │
    └────┬───┘   └───┬────┘
         │           │
         └─────┬─────┘
               │
        ┌──────▼──────────┐
        │ Service my-svc  │
        │ VIP: 10.0.0.5:80│
        └────────┬────────┘
                 │
        ┌────────▼────────┐
        │  Backend Pods   │
        │ (Load balanced) │
        └─────────────────┘
```

#### Diagram 2: TLS Termination and Certificate Flow

```
Client (Browser/API Consumer)
       │
       │ HTTPS Request
       │ Encrypted with CA Cert
       ↓
┌──────────────────────────────┐
│  INGRESS CONTROLLER (NGINX)  │
│  Listener: 0.0.0.0:443       │
│  ├─ TLS Socket created       │
│  ├─ Client cert received     │
│  ├─ TLS handshake with client│
│  └─ Connection established   │
│                              │
│  Certificate Sources:        │
│  1. Mounted Secret:          │
│     tls.crt, tls.key         │
│                              │
│  2. cert-manager:            │
│     Automatic cert creation  │
│     Renewal before expiry    │
│                              │
│  Decryption happens here:    │
│  Encrypted → Plaintext       │
└────────┬──────────────────────┘
         │
         │ HTTP Request
         │ Plaintext (internal network only)
         ↓
   ┌─────────────────────┐
   │  BACKEND SERVICE    │
   │  Pods receive plain │
   │  HTTP requests      │
   └─────────────────────┘

Certificate Management Timeline:
─────────────────────────────────────────
┌────────────────────────────────────────┐
│  Certificate Created                   │
│  Expires in: 90 days (LetsEncrypt)     │
│  Cert stored in: Secret/tls-secret     │
└────────────────────────────────────────┘
                 │
        45 days passed (~60 days remain)
                 │
                 ↓
┌────────────────────────────────────────┐
│  cert-manager checks expiry            │
│  Detects: Renew before 30 days left    │
│  Issues new certificate                │
│  Updates Secret with new cert          │
└────────────────────────────────────────┘
                 │
        Upon Secret update:
                 │
                 ↓
┌────────────────────────────────────────┐
│  Ingress Controller detects change     │
│  Reloads NGINX config with new cert    │
│  New connections use new certificate   │
│  Existing connections continue         │
│  Zero downtime certificate renewal     │
└────────────────────────────────────────┘

SNI (Server Name Indication) Support:
──────────────────────────────────────
Client connects to: 1.2.3.4:443
Sends: "I want host: example.com"
       │
       NGINX checks SNI hostname
       │
       If host: example.com
       ├─ Use cert for example.com
       │
       Elif host: api.example.com  
       ├─ Use cert for api.example.com
       │
       Else (unknown host)
       └─ Use default certificate

Multiple certificates on single IP:port ✓ (via SNI)
```

---

## Kubernetes Networking Model - Deep Dive

### Textual Deep Dive: The Networking Contract

#### The Kubernetes Networking Assumption

Kubernetes makes a fundamental bet about networking:

```
"Every pod can reach every other pod at its IP address, 
 as if they were on the same flat network."
```

This assumption enables:
- Stateless, distributed applications
- Service mesh implementations
- Network policy-based security (you define exceptions, not rules)

This assumption requires:
- CNI plugin implementation
- Proper CIDR planning
- Inter-node routing/tunneling setup

#### Pod-to-Pod Communication Mechanics

**In-cluster packet journey** (Pod A on Node 1 → Pod B on Node 2):

```
Layer breakdown:

│ Application Layer    │ Pod sends: curl 10.244.1.5:8080
├─────────────────────┤ 
│ Transport Layer     │ Kernel creates TCP connection
│ (TCP/UDP)           │ Three-way handshake begins
├─────────────────────┤
│ Network Layer        │ Source IP: 10.244.0.5 (Pod A)
│ (IP Routing)         │ Dest IP:   10.244.1.5 (Pod B)
│                      │ Gateway: (depends on CNI)
├─────────────────────┤
│ Data Link Layer      │ Veth pair: pod-side → host-side
│ (ARP, Ethernet) │ ARP for gateway MAC address
├─────────────────────┤
│ Physical Layer       │ Network plugin tunnel/routing
│ (CNI)               │ Inter-node packet transport
└─────────────────────┘

Tunnel options:
├─ VXLAN: Encapsulation (allows any CIDR)
├─ BGP: Native routing (requires planning)
├─ AWS VPC: Native VPC routing (no tunnel)
└─ Overlay: Generic tunnel mechanism
```

**Critical insight**: The same communication flow works whether Pod B is on the same node or different node. The CNI plugin handles the complexity of routing. The pod only knows its own IP and target IP—nothing about node topology.

#### CNI Plugin Responsibilities

**When a pod is scheduled to a node**:

```
kubelet gets: "Schedule Pod X to Node Y"
    ↓
1. Container Runtime creates container
   ├─ New process namespace
   ├─ New network namespace
   ├─ New filesystem namespace (chroot)
   └─ New IPC namespace

2. kubelet calls CNI plugin
   Input: Container ID, Namespace path, Pod CIDR
   ├─ Get container network namespace
   ├─ Allocate IP from pod CIDR (e.g., 10.244.1.x/24)
   ├─ Create veth pair
   │  ├─ Container side: eth0 in pod netns
   │  └─ Host side: veth123 on host
   ├─ Configure container side:
   │  ├─ Assign IP (10.244.1.5)
   │  ├─ Set subnet mask (e.g., /24)
   │  └─ Set default gateway (usually .1 of subnet)
   ├─ Configure host side:
   │  ├─ Add veth to bridge (or set up routing)
   │  └─ Update node routing table
   ├─ Configure inter-node routing:
   │  ├─ If VXLAN: Update tunnel configs
   │  ├─ If BGP: Announce route via BGP
   │  └─ If AWS VPC: Configure ENI info
   └─ Pod now networked, return success

3. Pod can:
   ├─ Make outgoing connections
   ├─ Receive incoming connections
   └─ Communicate with all cluster pods
```

**When a pod is deleted**:

```
kubelet gets: "Delete Pod X from Node Y"
    ↓
1. kubelet calls CNI delete
   Input: Container ID
   ├─ Remove veth pair
   ├─ Deallocate IP
   ├─ Update node routing
   └─ Cleanup tunnel configs

2. Container runtime:
   ├─ Terminates process
   ├─ Cleans up namespaces
   └─ Releases resources

3. Pod completely removed
```

#### Network Policy Enforcement

**Default behavior** (no policies):
```
Pod A → Pod B ✓ (allowed)
Pod A → Pod C ✓ (allowed)
Pod B → Pod C ✓ (allowed)
Any pod → Any pod ✓ (allowed)
```

**With Network Policies**:
```
# Deny all ingress
policy-1: podSelector: {}, policyTypes: [Ingress]
          (no ingress rules = deny all)

Result:
Pod A → Pod B ✗ (denied)
Pod A → Pod C ✗ (denied)
Pod B → Pod C ✗ (denied)

# Then selectively allow
policy-2: podSelector: {app: web}
          ingress: [{from: podSelector: {app: frontend}}]

Result:
frontend-pod → web-pod ✓ (allowed)
frontend-pod → db-pod ✗ (denied)
web-pod → frontend-pod ✗ (denied - not in rules)
```

**Enforcement mechanism** (depends on CNI):

```
Calico implementation:
├─ Tier 0: Security policies (high priority)
├─ Tier 1: Platform policies (medium priority)
├─ Tier 2: Application policies (low priority)
└─ Default: Network policies (lowest priority)

Policies evaluated top to bottom, first match wins

If Ingress NetworkPolicy matches → Allow/Deny
Else if Egress NetworkPolicy matches → Allow/Deny
Else → Default action (Allow if no policies, Deny if policies exist)

Hardware: eBPF/iptables programs in kernel
├─ Ingress: Policy checked on packet arrival
├─ Egress: Policy checked on packet transmission
└─ Performance: Kernel-space, microsecond overhead
```

#### Cluster CIDR Planning

**Impact of CIDR choices**:

```
Scenario: Cluster in private VPC 10.0.0.0/16

Choice 1: Pod CIDR = 10.245.0.0/16 (outside VPC range)
├─ Pro: Clear separation
├─ Con: Requires overlay (VXLAN, tunneling)
└─ Scaling: Max pods = 65,536

Choice 2: Pod CIDR = 10.1.0.0/16 (within VPC range)
├─ Pro: Native VPC routing (no overlay)
├─ Con: Pods have real VPC IP addresses
├─ Con: Limits scaling (IP pool limited to subnet)
└─ Scaling: Depends on VPC size

Choice 3 (AWS): Pod CIDR per EKS node (VPC secondary IP)
├─ Node 1: 10.1.100.0/24 → pods there
├─ Node 2: 10.1.101.0/24 → pods there
├─ Pro: Native routing, no overlay
├─ Con: Limited pods per node (secondary IP limit)
└─ Scaling: ~110 pods per node (not unlimited)
```

**CIDR conflicts are catastrophic**:
```
Example: accidentally allocate service CIDR same as pod CIDR
├─ Service VIP: 10.244.0.5
├─ Pod IP: 10.244.0.7
├─ Routing becomes ambiguous
├─ Packets go to wrong destination
├─ Silent data corruption (hardest to debug)
└─ Fix requires cluster restart
```

#### Dual-stack Networking (IPv4 + IPv6)

**Configuration requirement**:
```
Early cluster setup:
├─ kubelet flags: --feature-gates IPv6DualStack=true
├─ API server flags: SAME
├─ CNI plugin version: Must support dual-stack
└─ Once enabled, cannot disable (network rebuilding required)

Pod CIDR: Must allocate both IPv4 and IPv6
├─ IPv4: 10.244.0.0/16
├─ IPv6: fd00:1234:5678::/48

Service CIDR: Must allocate both
├─ IPv4: 10.0.0.0/24
├─ IPv6: fd00:ffff::/108
```

**Dual-stack implications**:
```
Pod get addresses:
├─ IPv4: 10.244.0.5
├─ IPv6: fd00:1234:5678::5
└─ Both usable simultaneously

Service gets both:
├─ IPv4: 10.0.0.5
├─ IPv6: fd00:ffff::5
└─ Clients can use either

Deployment patterns:
├─ IPv4 primary, IPv6 fallback
├─ IPv6 primary, IPv4 fallback
├─ Both equally (true dual-stack)
└─ Zone-specific: IPv4 on-prem, IPv6 cloud
```

### Practical Code Examples

#### Network Policy Audit and Enforcement Script

```bash
#!/bin/bash
# network-policy-manager.sh - Validate and enforce network policies

set -e

DRY_RUN="${1:-false}"
NAMESPACE="${2:-default}"
AUDIT_DIR="./network-policy-audit"

mkdir -p $AUDIT_DIR

# Function: Audit current traffic (before policies)
audit_current_traffic() {
    echo "=== Auditing Current Pod Communication ==="
    
    # Create network sniffer pod
    kubectl run net-sniffer -n $NAMESPACE \
        --image=nicolaka/netshoot:latest \
        --overrides='{"spec": {"serviceAccountName": "default"}}'
    
    # Wait for pod ready
    kubectl wait --for=condition=Ready pod/net-sniffer -n $NAMESPACE --timeout=30s
    
    # Capture pod communication patterns
    echo "Discovering pod-to-pod communication..."
    
    # Get all pods
    pods=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    
    for source_pod in $pods; do
        source_ip=$(kubectl get pod $source_pod -n $NAMESPACE \
            -o jsonpath='{.status.podIP}')
        
        echo "Pod: $source_pod ($source_ip)"
        
        # Try connections to other pods
        for dest_pod in $pods; do
            if [ "$source_pod" == "$dest_pod" ]; then
                continue
            fi
            
            dest_ip=$(kubectl get pod $dest_pod -n $NAMESPACE \
                -o jsonpath='{.status.podIP}')
            
            # Test connectivity
            if kubectl exec -n $NAMESPACE $source_pod -- \
                timeout 1 bash -c "nc -zv $dest_ip 8080" 2>/dev/null; then
                echo "  → $dest_pod ($dest_ip:8080) ✓ Connected"
                echo "$source_pod,$dest_pod,8080,TCP,success" >> $AUDIT_DIR/traffic.csv
            fi
        done
    done
    
    # Cleanup
    kubectl delete pod net-sniffer -n $NAMESPACE
}

# Function: Analyze audit logs
analyze_traffic_patterns() {
    echo ""
    echo "=== Traffic Pattern Analysis ==="
    
    if [ ! -f $AUDIT_DIR/traffic.csv ]; then
        echo "No traffic audit file found"
        return
    fi
    
    echo "Source Pod, Destination Pod, Port, Protocol, Status" > $AUDIT_DIR/traffic-analysis.txt
    cat $AUDIT_DIR/traffic.csv >> $AUDIT_DIR/traffic-analysis.txt
    
    echo "Unique source pods:"
    cut -d',' -f1 $AUDIT_DIR/traffic.csv | sort -u
    
    echo ""
    echo "Communication graph:"
    while IFS=',' read -r source dest port proto status; do
        echo "$source → $dest"
    done < $AUDIT_DIR/traffic.csv | sort -u
}

# Function: Generate network policies based on audit
generate_policies() {
    echo ""
    echo "=== Generating Network Policies ==="
    
    # Default deny all
    cat > $AUDIT_DIR/01-deny-all.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: $NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF
    
    # Allow DNS (required)
    cat > $AUDIT_DIR/02-allow-dns.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: $NAMESPACE
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
EOF
    
    # Allow inter-pod communication based on audit
    echo "Creating allow policies based on audit..."
    
    while IFS=',' read -r source dest port proto status; do
        # Extract labels from pod names (assumes naming convention: app-name-replica)
        source_app=$(echo $source | sed 's/-[0-9]*$//')
        dest_app=$(echo $dest | sed 's/-[0-9]*$//')
        
        # Create policy
        policy_name=$(echo "allow-${source_app}-to-${dest_app}" | tr '_' '-')
        
        cat > $AUDIT_DIR/$policy_name.yaml <<POLICY
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: $policy_name
  namespace: $NAMESPACE
spec:
  podSelector:
    matchLabels:
      app: $dest_app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: $source_app
    ports:
    - protocol: TCP
      port: $port
POLICY
        
        echo "  Generated: $policy_name.yaml"
    done < $AUDIT_DIR/traffic.csv
}

# Function: Validate policies before applying
validate_policies() {
    echo ""
    echo "=== Validating Policies ==="
    
    for policy_file in $AUDIT_DIR/*.yaml; do
        if ! kubectl apply -f $policy_file --dry-run=client -o yaml &>/dev/null; then
            echo "ERROR: Invalid policy in $policy_file"
            kubectl apply -f $policy_file --dry-run=client
            return 1
        else
            echo "✓ $(basename $policy_file)"
        fi
    done
}

# Function: Apply policies
apply_policies() {
    echo ""
    echo "=== Applying Network Policies ==="
    
    if [ "$DRY_RUN" == "true" ]; then
        echo "DRY RUN: Would apply following policies:"
        for policy_file in $AUDIT_DIR/*.yaml; do
            echo "  - $(basename $policy_file)"
        done
        return
    fi
    
    # Apply policies one by one with delay 
    for policy_file in $AUDIT_DIR/*.yaml; do
        echo "Applying $(basename $policy_file)..."
        kubectl apply -f $policy_file
        sleep 2
        
        # Verify policy applied
        policy_name=$(basename $policy_file .yaml)
        if kubectl get networkpolicy $policy_name -n $NAMESPACE &>/dev/null; then
            echo "  ✓ Applied successfully"
        fi
    done
}

# Function: Test connectivity after policies
test_policies() {
    echo ""
    echo "=== Testing Connectivity After Policies ==="
    
    # Test connectivity that should work
    echo "Testing allowed connections:"
    while IFS=',' read -r source dest port proto status; do
        result=$(kubectl exec -n $NAMESPACE $source -- \
            timeout 1 bash -c "nc -zv $dest 8080" 2>&1 | grep -q "succeeded" && echo "✓" || echo "✗")
        echo "  $source → $dest:$port $result"
    done < $AUDIT_DIR/traffic.csv
    
    # Test that denied connections fail
    echo ""
    echo "Testing denied connections (should timeout):"
    
    # Example: pod that shouldn't communicate
    test_source=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}')
    test_dest=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[-1].metadata.name}')
    test_ip=$(kubectl get pod $test_dest -n $NAMESPACE -o jsonpath='{.status.podIP}')
    
    if ! kubectl exec -n $NAMESPACE $test_source -- \
        timeout 1 bash -c "nc -zv $test_ip 8080" 2>&1 | grep -q "succeeded"; then
        echo "  ✓ Properly denied: $test_source → $test_dest"
    fi
}

# Main execution
echo "Network Policy Manager"
echo "Dry Run: $DRY_RUN"
echo "Namespace: $NAMESPACE"
echo ""

audit_current_traffic
analyze_traffic_patterns
generate_policies
validate_policies
apply_policies
test_policies

echo ""
echo "=== Summary ==="
echo "Audit directory: $AUDIT_DIR"
echo "Generated policies: $(ls $AUDIT_DIR/*.yaml | wc -l)"
echo ""
echo "Next steps:"
echo "1. Review generated policies in $AUDIT_DIR"
echo "2. Adjust labels/matchings as needed"
echo "3. Run with DRY_RUN=false to apply"
```

#### CNI Configuration: Calico with BGP Routing

```yaml
---
# Calico Installation with BGP routing (not VXLAN overlay)
apiVersion: v1
kind: Namespace
metadata:
  name: calico-system
---
# Calico Configuration
apiVersion: projectcalico.org/v3
kind: Installation
metadata:
  name: default
spec:
  # Use BGP for routing instead of VXLAN
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: 10.244.0.0/16
      encapsulation: None  # None = BGP routing (native)
      natOutgoing: Enabled
      nodeSelector: all()
    
    nodeAddressAutodetectionV4:
      interface: "eth0"
    
    hostPorts:
      enabled: true
    
    multiInterfaceMode: "auto"
  
  # Variant: standard (includes all features)
  variant: Calico
  
  # Disable certain features not needed
  nonNamespacedResources:
  - globalNetworkPolicies
  - networkPolicies
  - clusterInformations
  - felixConfigurations
  - kubeControllersConfigurations

---
# BGP Peer configuration (for on-premises routers)
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: rtr-rack-one
spec:
  # Kubernetes nodes will BGP peer with this router
  peerIP: 192.168.1.1
  asNumber: 65000
  
  # Optionally only peer certain nodes
  nodeSelector: rack == "one"

---
# BGP Configuration (global settings)
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  asNumber: 65001
  
  # Node-to-node mesh (nodes BGP peer with each other)
  nodeToNodeMeshEnabled: true
  
  # Listen port
  listenPort: 179

---
# Felix Configuration (Calico agent)
apiVersion: projectcalico.org/v3
kind: FelixConfiguration
metadata:
  name: default
spec:
  # Logging
  logSeverityScreen: Info
  logSeveritySys: Info
  
  # Host endpoints
  reportingIntervalSecs: 30
  
  # IPInIP encapsulation (for specific pods needing it)
  ipInIpEnabled: false  # Using BGP, not IP-in-IP tunnel
  
  # Security
  failsafeInboundHostPorts:
  - protocol: tcp
    port: 22  # SSH
  - protocol: tcp
    port: 179  # BGP
  
  # Chain name (for iptables/nftables)
  chainInsertMode: Insert
  
  # NAT
  natOutgoingAddress: InternalIP

---
# Network Policy Example: Tier structure
apiVersion: projectcalico.org/v3
kind: Tier
metadata:
  name: security
spec:
  order: 0  # Highest priority

---
apiVersion: projectcalico.org/v3
kind: Tier
metadata:
  name: platform
spec:
  order: 10

---
apiVersion: projectcalico.org/v3
kind: Tier
metadata:
  name: application
spec:
  order: 20

---
# Example Security Policy (zero-trust baseline)
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: SecurityTier.DenyAll
spec:
  tier: security
  selector: ""
  types:
  - Ingress
  ingress:
  # Deny rule (empty = match nothing, so deny all)
  # This tier has no allow rules, so all traffic denied

---
# Example Platform Policy (allow cluster DNS)
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: PlatformTier.AllowDNS
spec:
  tier: platform
  selector: "!host-endpoint"  # Only pods, not host
  types:
  - Egress
  egress:
  - action: Allow
    destination:
      ports:
      - 53
      protocols:
      - UDP

---
# Example Application Policy
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: AllowFrontendToAPI
  namespace: production
spec:
  tier: application
  
  selector: app == "api"
  
  types:
  - Ingress
  
  ingress:
  - action: Allow
    source:
      selector: app == "frontend"
    destination:
      ports:
      - 8080
```

#### Shell Script: Validate Cluster Networking Setup

```bash
#!/bin/bash
# validate-networking.sh - Comprehensive cluster networking validation

set -e

echo "=== Kubernetes Cluster Networking Validation ==="
echo "Timestamp: $(date)"
echo ""

# Configuration
VERBOSE="${1:-false}"
REQUIRED_CHECKS=0
FAILED_CHECKS=0

# Function: Run check
run_check() {
    local check_name=$1
    local check_cmd=$2
    
    echo -n "[$check_name] "
    
    if eval "$check_cmd" &>/dev/null; then
        echo "✓"
        return 0
    else
        echo "✗"
        ((FAILED_CHECKS++))
        
        if [ "$VERBOSE" == "true" ]; then
            eval "$check_cmd" || true
        fi
        return 1
    fi
}

echo "=== Basic Connectivity Checks ==="

# Check API server connectivity
run_check "API Server" \
    "kubectl cluster-info &>/dev/null"

# Check node connectivity
run_check "Nodes Available" \
    "test $(kubectl get nodes -o jsonpath='{.items | length}') -gt 0"

# Check nodes ready
run_check "Nodes Ready" \
    "test $(kubectl get nodes -o jsonpath='{.items[?(@.status.conditions[?(@.type==\"Ready\")].status==\"True\")] | length}') -eq $(kubectl get nodes -o jsonpath='{.items | length}')"

echo ""
echo "=== Pod Networking Checks ==="

# Check CNI plugin
run_check "CNI Plugin Running" \
    "kubectl get daemonset -n kube-system -o jsonpath='{.items[?(@.metadata.name=~\"(flannel|calico|weave|.*cni)\")].metadata.name}' | grep -q ."

# Check CoreDNS
run_check "CoreDNS Running" \
    "kubectl get deployment -n kube-system coredns &>/dev/null"

# Check CoreDNS ready
run_check "CoreDNS Ready" \
    "test $(kubectl get deployment -n kube-system coredns -o jsonpath='{.status.readyReplicas}') -gt 0"

echo ""
echo "=== Service Networking Checks ==="

# Check kube-proxy running on all nodes
node_count=$(kubectl get nodes -o jsonpath='{.items | length}')
proxy_count=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy -o jsonpath='{.items | length}')

run_check "kube-proxy on All Nodes" \
    "test $proxy_count -eq $node_count"

# Check proxy mode
echo -n "[kube-proxy Mode] "
proxy_mode=$(kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=10 | grep -o "mode:[^}]*" | head -1 || echo "unknown")
echo "$proxy_mode"

echo ""
echo "=== Network Policy Checks ==="

# Check if network policies are supported
run_check "Network Policies Supported" \
    "kubectl get networkpolicies -A &>/dev/null"

# Check if any policies exist
policy_count=$(kubectl get networkpolicies -A -o jsonpath='{.items | length}' 2>/dev/null || echo "0")
echo "[Network Policies Defined] $policy_count policies"

echo ""
echo "=== CIDR Planning Validation ==="

# Get cluster CIDR information
cluster_cidr=$(kubectl get configmap kubeadm-config -n kube-system -o jsonpath='{.data.ClusterConfiguration}' 2>/dev/null | grep -oP 'podSubnet: \K[^,}]*' || echo "Unknown")
service_cidr=$(kubectl get configmap kubeadm-config -n kube-system -o jsonpath='{.data.ClusterConfiguration}' 2>/dev/null | grep -oP 'serviceSubnet: \K[^,}]*' || echo "Unknown")

echo "Cluster Pod CIDR: $cluster_cidr"
echo "Service CIDR: $service_cidr"

# Check for CIDR conflicts with node CIDR
echo ""
echo "=== Node IP Configuration ==="
kubectl get nodes -o wide | awk 'NR>1 {print "Node: " $1 " IP: " $6 " CIDR: " $7 "??" }'

echo ""
echo "=== Connectivity Test ==="

# Create test pods if none exist
test_namespace="networking-test"

if ! kubectl get namespace $test_namespace &>/dev/null; then
    kubectl create namespace $test_namespace
fi

# Deploy test pods
for i in {1..2}; do
    pod_name="test-pod-$i"
    
    if ! kubectl get pod $pod_name -n $test_namespace &>/dev/null; then
        kubectl run $pod_name -n $test_namespace \
            --image=alpine:latest \
            --restart=Never \
            -- sleep 3600
    fi
done

# Wait for pods ready
kubectl wait --for=condition=Ready pods --all -n $test_namespace --timeout=30s 2>/dev/null || true

# Get pod IPs
pod1_ip=$(kubectl get pod test-pod-1 -n $test_namespace -o jsonpath='{.status.podIP}' 2>/dev/null || echo "N/A")
pod2_ip=$(kubectl get pod test-pod-2 -n $test_namespace -o jsonpath='{.status.podIP}' 2>/dev/null || echo "N/A")

echo "Pod 1 IP: $pod1_ip"
echo "Pod 2 IP: $pod2_ip"

# Test connectivity
if [ "$pod1_ip" != "N/A" ] && [ "$pod2_ip" != "N/A" ]; then
    echo -n "[Pod-to-Pod Connectivity] "
    if kubectl exec test-pod-1 -n $test_namespace -- ping -c 1 $pod2_ip &>/dev/null; then
        echo "✓"
    else
        echo "✗"
        ((FAILED_CHECKS++))
    fi
fi

# Cleanup
kubectl delete namespace $test_namespace

echo ""
echo "=== DNS Resolution Test ==="

# Test service discovery
kubectl get svc -n kube-system -o jsonpath='{.items[0].metadata.name}' | while read svc_name; do
    echo -n "[DNS Resolution] "
    if nslookup $svc_name.kube-system.svc.cluster.local 2>/dev/null | grep -q "Address:"; then
        echo "✓ $svc_name resolved"
    else
        echo "✗ DNS failed"
    fi
done

echo ""
echo "=== Summary ==="
echo "Total Checks: $REQUIRED_CHECKS"
echo "Failed Checks: $FAILED_CHECKS"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo "Status: ✓ All checks passed"
    exit 0
else
    echo "Status: ✗ Some checks failed"
    exit 1
fi
```

### ASCII Diagrams: Network Model Implementation

#### Diagram 1: Pod Network Namespace Isolation

```
HOST OS (Node)
├─ Process Namespace
│  ├─ kubelet (process 1)
│  ├─ containerd (runtime)
│  ├─ kube-proxy (daemon)
│  └─ System processes
│
├─ Host Network Namespace
│  ├─ Physical NIC: eth0
│  ├─ Route Table:
│  │  ├─ 10.244.1.0/24 -> veth123 (Pod A)
│  │  ├─ 10.244.1.0/24 -> veth124 (Pod B)
│  │  ├─ 10.244.1.0/24 -> veth125 (Pod C)
│  │  └─ 10.244.2.0/24 -> vxlan0 (inter-node tunnel)
│  │
│  ├─ iptables Rules (service routing)
│  │  ├─ Match: -d 10.0.0.5:8080
│  │  └─ Action: DNAT to pod IP
│  │
│  └─ Veth Devices (one end in host)
│     ├─ veth123 ↔ Pod A:eth0
│     ├─ veth124 ↔ Pod B:eth0
│     └─ veth125 ↔ Pod C:eth0
│
├─ Pod A Network Namespace (isolated)
│  ├─ Process: app container
│  ├─ NIC: eth0
│  ├─ IP: 10.244.1.5/24
│  ├─ Gateway: 10.244.1.1
│  ├─ Route Table:
│  │  ├─ 10.244.0.0/16 -> eth0 (local pod network)
│  │  └─ 0.0.0.0/0 -> 10.244.1.1 (default gateway)
│  └─ Connected to: Host veth123
│
├─ Pod B Network Namespace (isolated)
│  ├─ Process: app container
│  ├─ NIC: eth0
│  ├─ IP: 10.244.1.7/24
│  ├─ Gateway: 10.244.1.1
│  └─ Connected to: Host veth124
│
└─ Pod C Network Namespace (isolated)
   ├─ Process: app container
   ├─ NIC: eth0
   ├─ IP: 10.244.1.9/24
   ├─ Gateway: 10.244.1.1
   └─ Connected to: Host veth125

Communication Example: Pod A sends packet to Pod B (10.244.1.7)
────────────────────────────────────────────────────────────
1. Pod A: app calls sendto(10.244.1.7, port 8080)
2. Pod A netns: Routes to eth0 gateway (10.244.1.1)
3. Host: Packet arrives at veth123
4. Host: Routing: 10.244.1.0/24 is local (veth123)
   Delivery via veth124
5. Pod B netns: Packet delivered to eth0
6. Pod B: App receives connection
7. Response: Reverse path through veth123
8. Pod A: Receives response
```

#### Diagram 2: Inter-Node Pod Communication (VXLAN Overlay)

```
CLUSTER OVERVIEW
═════════════════════════════════════════════════════════════

Node 1 (10.1.1.100)          Node 2 (10.1.1.101)
┌──────────────────┐         ┌──────────────────┐
│ Pod CIDR Range   │         │ Pod CIDR Range   │
│ 10.244.1.0/24    │         │ 10.244.2.0/24    │
│                  │         │                  │
│ Pod A: 10.244.1.5│         │ Pod D: 10.244.2.5│
│ Pod B: 10.244.1.7│         │ Pod E: 10.244.2.7│
│ Pod C: 10.244.1.9│         │ Pod F: 10.244.2.9│
└────────┬─────────┘         └────────┬─────────┘
         │                           │
    eth0 (10.1.1.100)          eth0 (10.1.1.101)
         │            NETWORK          │
         └──────────────────────────────┘
              Physical Connection


VXLAN TUNNEL DETAILS
═════════════════════════════════════════════════════════════

Scenario: Pod A (10.244.1.5) → Pod D (10.244.2.5)

Step 1: Pod A sends packet
────────────────────────────
Packet content:
  Source IP:      10.244.1.5 (Pod A)
  Dest IP:        10.244.2.5 (Pod D)
  Protocol:       TCP
  Port:           8080

Step 2: Node 1 routing decision
────────────────────────────────
Routing table on Node 1:
  Destination     | Next Hop
  ─────────────────────────────
  10.244.1.0/24   | veth123 (local)
  10.244.2.0/24   | vxlan0 (overlay tunnel)
  10.1.0.0/16     | eth0 (physical)

Packet matched: 10.244.2.0/24 → forward to vxlan0

Step 3: VXLAN encapsulation (on Node 1)
────────────────────────────────────────
Original packet:
┌─────────────────────────────────────┐
│ Source: 10.244.1.5                  │
│ Dest: 10.244.2.5                    │
│ TCP payload                         │
└─────────────────────────────────────┘

Becomes VXLAN encapsulated packet:
┌───────────────────────────────────────────┐
│ Outer IP Header                           │
│   Source: 10.1.1.100 (Node 1)             │
│   Dest: 10.1.1.101 (Node 2)               │
├───────────────────────────────────────────┤
│ VXLAN Header                              │
│   VNI: 4096 (VXLAN Network ID)            │
├───────────────────────────────────────────┤
│ Original Ethernet Frame                   │
│   Source MAC: aa:aa:aa:aa:aa:aa           │
│   Dest MAC: (gateway MAC)                 │
├───────────────────────────────────────────┤
│ Original IP Packet                        │
│   Source: 10.244.1.5                      │
│   Dest: 10.244.2.5                        │
└───────────────────────────────────────────┘

Step 4: Physical network transmission
──────────────────────────────────────
VXLAN packet sent over physical network:
  Source Physical IP: 10.1.1.100
  Dest Physical IP:   10.1.1.101
  UDP Port: 4789 (standard VXLAN port)
  Encapsulation overhead: ~50 bytes per packet

Physical Network → Delivered to Node 2

Step 5: VXLAN decapsulation (on Node 2)
────────────────────────────────────────
Node 2 vxlan interface receives encapsulated packet:
  1. Strips outer IP header
  2. Extracts VXLAN header (verifies VNI)
  3. Recovers original packet:
     Source: 10.244.1.5
     Dest: 10.244.2.5

Step 6: Local forwarding (Node 2)
─────────────────────────────────
Routing table on Node 2:
  10.244.2.0/24 → veth456 (Pod D)
  
Packet forwarded to Pod D's veth

Step 7: Pod D receives packet
──────────────────────────────
Pod D network namespace receives:
  Source: 10.244.1.5 (unchanged, appears directly)
  Dest: 10.244.2.5 (itself)
  
Application delivers to socket

Return path (Pod D → Pod A):
───────────────────────────
Pod D response:
  Source: 10.244.2.5
  Dest: 10.244.1.5
  
Reverse process:
  1. Node 2 routes 10.244.1.0/24 → vxlan0
  2. VXLAN encapsulation
  3. Send over physical network to Node 1 (10.1.1.100)
  4. Node 1 decapsulates
  5. Routes to Pod A veth123
  6. Pod A receives response


MTU CONSIDERATIONS
════════════════════════════════════════════════════════════

Standard setup (without VXLAN):
  Physical MTU: 1500 bytes
  Pod can send: 1500-byte packets

With VXLAN tunneling:
  Physical MTU: 1500 bytes
  VXLAN overhead: ~50 bytes (IP + VXLAN headers)
  Pod can send: 1450 bytes (before fragmentation)
  
  If pod sends 1500-byte packet:
    → Encapsulated to 1550 bytes
    → MTU exceeded on physical network
    → Fragmentation occurs (bad for latency)
    → Or dropped if DF (Don't Fragment) flag set
  
  Fix options:
  1. Increase physical MTU to 1550+ (jumbo frames)
  2. Reduce pod MTU to 1450 (PMTUD, or manual)
  3. Use native routing instead of VXLAN
```

---

## Hands-on Scenarios

### Scenario 1: Debugging a Service Not Receiving Traffic

**Situation**: Deployment exists, pods are running, but service is not receiving traffic from other pods.

**Investigation Steps**:

```bash
# Step 1: Check endpoints
kubectl get endpoints my-service
# Expected: At least one endpoint
# Actual: <none>

# Step 2: Check service selector
kubectl get service my-service -o yaml | grep selector -A 5

# Step 3: Check pod labels
kubectl get pods --show-labels

# Step 4: Verify label match
# If selector is "app: api" and pods have "app: backend", they won't match

# Step 5: Fix
# Option A: Update pod labels
kubectl label pods my-pod-xyz app=api  # Add matching label

# Option B: Update service selector
kubectl patch service my-service -p '{"spec":{"selector":{"app":"backend"}}}'

# Step 6: Verify endpoints updated
kubectl get endpoints my-service --watch
# Should see endpoints appear within seconds
```

**Root cause in 90% of cases**: Service selector doesn't match pod labels.

### Scenario 2: Implementing Zero-Trust Networking

**Situation**: New security requirement: pods should only communicate with explicitly allowed pods.

**Implementation**:

```bash
# Step 1: Audit current traffic
# Enable network policy but don't enforce (if supported)
kubectl apply -f network-policy-audit.yaml

# Step 2: Identify required connections
# Analyze logs of what would be blocked
# Talk to teams: "frontend needs to talk to api service"

# Step 3: Apply deny-all baseline
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
EOF

# Step 4: Add allow policies
# Frontend can reach API
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-api
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
EOF

# API can reach database
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-db
spec:
  podSelector:
    matchLabels:
      tier: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 5432
EOF

# API can reach external services (port 443 for updates)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-external-egress
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
  # Also need DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF

# Step 5: Test connectivity
# Should work: frontend → api
kubectl exec <frontend-pod> -- curl http://api-service:8080
# Should work: api → database
kubectl exec <api-pod> -- psql -h database-service

# Should fail: frontend → database (not allowed)
kubectl exec <frontend-pod> -- nc -zv database-service 5432
# Connection timeout expected
```

### Scenario 3: Rolling Out Ingress with Zero Downtime

**Situation**: Deploying new Ingress-based routing, must not disrupt existing traffic.

**Process**:

```bash

# Step 1: Pre-create all required services
kubectl apply -f services.yaml

# Step 2: Deploy application versions
kubectl apply -f deployment-v1.yaml
kubectl apply -f deployment-v2.yaml

# Step 3: Wait for both versions ready
kubectl rollout status deployment app-v1
kubectl rollout status deployment app-v2

# Step 4: Create canary Ingress (not yet used)
kubectl apply -f ingress-canary.yaml

# Verify Ingress is created but not DNS-pointed
kubectl get ingress ingress-canary
# Note: External IP or Hostname might be None (depending on setup)

# Step 5: Test routing locally
# Port-forward to test
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 &
curl -H "Host: my-app.example.com" http://localhost:8080/api

# Step 6: Once verified, point DNS
# DNS providers vary (Route53, CloudFlare, etc.)
# Update DNS A record to Ingress IP
# dig my-app.example.com  # Verify points to ingress IP

# Step 7: Monitor initial traffic
# Check ingress controller logs
kubectl logs -n ingress-nginx <controller-pod> --tail=100 -f
# Watch for errors

# Step 8: Shift traffic (if using weighted routing with canary)
# Update Ingress weights if supporting weighted backend routing
kubectl patch ingress my-app --type='json' \
  -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/weight", "value":90}]'

# Step 9: Remove old Ingress  
# Only after confident new routing works
kubectl delete ingress old-ingress
```

### Scenario 4: Diagnosing Inter-Node Pod Connectivity Issue

**Situation**: Pods on same node talk fine, but pods on different nodes can't communicate.

**Diagnosis**:

```bash
# Step 1: Verify networking
# Check CNI plugin status
kubectl get pods -n kube-system -l k8s-app=<cni-plugin>
# All should be Running and Ready

# Step 2: Check node connectivity
# Pick two nodes
NODE1="node-1"
NODE2="node-2"

# Verify nodes can ping each other
gcloud compute ssh $NODE1 -- ping -c 3 <node2-ip>
gcloud compute ssh $NODE2 -- ping -c 3 <node1-ip>
# Both should show responses

# Step 3: Check pod IPs are in expected ranges
kubectl get pods -o wide | grep $NODE1
# Should show pod IPs in NODE1's pod CIDR

kubectl get pods -o wide | grep $NODE2
# Should show pod IPs in NODE2's pod CIDR

# Step 4: Test connectivity directly
# Pod on Node1 → Pod on Node2
POD1=$(kubectl get pods -o wide | grep $NODE1 | head -1 | awk '{print $1}')
POD2=$(kubectl get pods -o wide | grep $NODE2 | head -1 | awk '{print $1}')
POD2_IP=$(kubectl get pod $POD2 -o jsonpath='{.status.podIP}')

kubectl exec $POD1 -- ping -c 3 $POD2_IP
# If this fails, network connectivity issue

# Step 5: Check firewall rules
# On source node
gcloud compute ssh $NODE1 -- \
  sudo iptables -L -n | grep -i $POD2_IP
# Check if rules allow traffic

# On destination node
gcloud compute ssh $NODE2 -- \
  sudo iptables -L -n | grep -i POD1_CIDR
# Check if rules allow ingress

# Step 6: Check CNI tunnel status
gcloud compute ssh $NODE1 -- \
  ip link show | grep -i vxlan
# Should show tunnel interfaces

# Or for Calico BGP
gcloud compute ssh $NODE1 -- \
  calicoctl node status
# Should show BGP established

# Step 7: Check MTU settings
# MTU too small can cause packet drops
gcloud compute ssh $NODE1 -- \
  ip link show | grep -i mtu
# Should be >= 1500 for standard, >= 1450 for VXLAN

# Step 8: Network policy blocking?
kubectl get networkpolicies --all-namespaces
# Check if any policies block inter-pod traffic

# Fix: Add allow policy
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-inter-node
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
EOF
```

### Scenario 5: Exposing Microservices with Ingress

**Situation**: Deploying microservices architecture with frontend, API, and admin dashboard. Each needs different security and routing.

**Architecture Decision**:

```
Internet
    ↓
Ingress (single LB)
├─ example.com → frontend service
├─ api.example.com → api service
└─ admin.example.com → admin service (restricted via RBAC + ingress auth)
```

**Implementation**:

```bash
# Step 1: Create frontend service
kubectl apply -f - <<EOF
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
    targetPort: 8080
  labels:
    tier: frontend
EOF

# Step 2: Create API service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
  - port: 8000
    targetPort: 8000
  labels:
    tier: api
EOF

# Step 3: Create admin service
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: admin-service
spec:
  type: ClusterIP
  selector:
    app: admin
  ports:
  - port: 9000
    targetPort: 9000
  labels:
    tier: admin
EOF

# Step 4: Create main Ingress (public services)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: public-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - example.com
    - api.example.com
    secretName: example-com-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
  
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8000
EOF

# Step 5: Create admin Ingress (with basic auth)
# First create secret with credentials
htpasswd -c auth admin
# Password: securepassword
# Creates htpasswd file

kubectl create secret generic admin-auth --from-file=auth
rm auth

# Create admin Ingress with auth annotation
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: admin-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: admin-auth
    nginx.ingress.kubernetes.io/auth-realm: 'Admin Dashboard'
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - admin.example.com
    secretName: admin-example-com-tls
  rules:
  - host: admin.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: admin-service
            port:
              number: 9000
EOF

# Step 6: Network policy to restrict admin service access
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: admin-isolation
spec:
  podSelector:
    matchLabels:
      app: admin
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Only from ingress controller namespace
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
  egress:
  # Can talk to other services for operations
  - to:
    - podSelector: {}
  # Can do DNS
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
EOF

# Step 7: Test routing
# Public frontend accessible
curl https://example.com
# Public API accessible
curl https://api.example.com/health
# Admin requires auth
curl https://admin.example.com  # 401 Unauthorized
curl -u admin:securepassword https://admin.example.com  # 200 OK
```

---

## Interview Questions

### Foundational Questions

**Q1: What is the primary problem that Kubernetes Services solve?**

A: Services solve the ephemeral nature of pods. Pods are constantly being created, destroyed, and rescheduled. Services provide a stable, virtual IP address and DNS name that stays constant, while the underlying backing pods change. This decouples clients from specific pod instances.

**Q2: Explain the difference between a Service VIP and a Pod IP.**

A: 
- **Service VIP**: Virtual IP allocated from service CIDR (e.g., 10.0.0.5). Stable, never changes. Used by clients to connect to services.
- **Pod IP**: Actual IP from pod CIDR (e.g., 10.244.0.5). Ephemeral, changes when pod restarts. Internal to pod networking.

The Service VIP maps (via iptables/IPVS rules) to one of several Pod IPs for load balancing.

**Q3: What role does kube-proxy play, and why must it run on every node?**

A: kube-proxy is Node-level daemon that watches Service and Endpoint objects and programs kernel forwarding rules (iptables/IPVS). It runs on every node because every node might receive traffic destined for the service VIP, and every node must know how to forward that traffic to the actual pod IPs. Without kube-proxy on a node, services wouldn't work for pods running on that node.

**Q4: Describe the network path when Pod A connects to a Service.**

A:
```
1. Pod A initiates connection to Service VIP (10.0.0.5:8080)
2. Pod A's kernel matches iptables rule for service
3. Rule performs DNAT, rewriting destination to a pod IP (e.g., 10.244.1.3:8080)
4. Packet sent to that pod IP
5. Return traffic flows back:
   - Pod sends response to Pod A's IP
   - conntrack table remembers DNAT translation
   - Automatically reverse-translates the response (sets source back to VIP)
6. Traffic appears to come from Service VIP from Pod A's perspective
```

**Q5: Why does Kubernetes provide both ClusterIP and NodePort services if CloudProvider LoadBalancer is available?**

A: Different use cases:
- **ClusterIP**: Cheapest, used for internal service-to-service communication. No external cost.
- **NodePort**: Exposes on nodes; allows external access without cloud LB, but requires knowing node IP and NodePort. Ports 30000-32767 limitation.
- **LoadBalancer**: Cloud provider allocates external LB (expensive, one per service). Best for exposing public APIs, costs money.

Ingress layers on top: Shares single LoadBalancer across multiple services, reducing cost while providing cleaner external URLs.

**Q6: What happens when you delete all pods backing a service?**

A: 
1. Pods are deleted
2. Endpoints controller detects pods no longer match service selector
3. Endpoint object updated to remove deleted pod IPs
4. kube-proxy detects Endpoint change
5. kube-proxy updates iptables rules to remove those endpoints
6. Service still exists but has no endpoints
7. Any new connections to service fail (no backend to route to)
8. Service itself isn't deleted; new pods can be added anytime

### Advanced Questions

**Q7: Explain the difference between `sessionAffinity: ClientIP` and sticky cookies in an Ingress.**

A:
- **sessionAffinity: ClientIP** (Service-level): Hash of client IP determines which backend pod receives all traffic from that client. Persists across HTTP requests even if client opens new connection. Implemented in kube-proxy using conntrack.
- **Sticky cookies** (Ingress-level): Ingress controller sets a cookie in response. Client mirrors cookie in subsequent requests. Ingress controller uses cookie value to always route to same backend pod. Can be lost if client disables cookies.

**ClientIP affinity forces all connections from client to same pod; cookies are best-effort (can be lost).**

**Q8: In a ClusterIP service with 3 replicas, if 1 pod crashes while a client is mid-request, what happens?**

A: Depends on timing and connection type:

**TCP connection already established**:
- Active TCP connection remains open to crashed pod
- TCP timeout (depends on OS socket timeout, usually 15 minutes default)
- If pod restarts with same IP within timeout, connection continues
- If pod restarts with different IP, connection hangs until timeout

**HTTP request (if using HTTP keep-alive)**:
- Client receives no response
- Client times out, should retry
- Retry gets load-balanced to different pod
- If client properly handles retries: transparent failover

**Key insight**: Service provides load balancing for new connections. Existing connections aren't automatically rerouted. Application must implement retry/timeout logic.

**Q9: How does Kubernetes achieve pod-to-pod communication across multiple nodes?**

A: Three layers working together:

1. **Service Layer**: Service VIP routes to backing pod IPs
2. **Pod CIDR Routing**: Each node knows its own pod CIDR range
3. **CNI Plugin**: Provides inter-node connectivity

**Specific example**:
```
Pod A on Node 1 (10.244.0.5) connects to Pod B on Node 2 (10.244.1.3)
├─ Pod A's kernel routes to Pod B's IP
├─ Host routing rule: "10.244.1.0/24 via CNI interface"
├─ CNI plugin (e.g., Flannel VXLAN): Encapsulates packet in VXLAN tunnel
├─ Tunnel endpoints: Node 1 IP → Node 2 IP
├─ Node 2's VXLAN decapsulation reveals original pod packet
└─ Pod B receives packet with Pod A as source
```

Without CNI plugin: Pod A's kernel has no route to 10.244.1.0/24, packet drops. CNI plugin provides bridge between layers.

**Q10: Explain mTLS. When would you implement it, and at what layer?**

A: **mTLS = Mutual TLS**: Both client and server verify each other's certificates.

**Traditional TLS**: Server proves identity to client. Client verifies server's cert. Server never knows who client is (unless app layer auth).

**Where implemented**:
1. **Service Mesh** (Istio): Automatic sidecar injection, handles mTLS transparently. Recommended for zero-trust networks.
2. **Application layer**: Client code manually configures TLS config with client cert. More work but explicit.
3. **Ingress with client certs**: Reverse proxy verifies client certs. Less common.

**When to implement**:
- Zero-trust network (trust no one by default)
- Compliance requirements (HIPAA, PCI-DSS, SOC2)
- Internal services that need strong auth
- Preventing service spoofing (only authorized services can connect)

**Trade-off**: mTLS adds complexity (cert rotation, debugging). Worth it if security requirements justify.

**Q11: What's the difference between Ingress and LoadBalancer service? When would you use each?**

A:
| Aspect | LoadBalancer | Ingress |
|--------|--------------|---------|
| Cost | High (~$1k/month per service) | Low (shared LB) |
| What it creates | Cloud LB (AWS ELB, etc.) | None - requires controller |
| Routing capability | Layer 4 (TCP/UDP) | Layer 7 (HTTP/HTTPS) |
| TLS support | Basic (SSL passthrough) | Full (path-aware, host-aware) |
| Best for | Simple TCP services (databases, VPNs) | HTTP APIs, web services |
| External name | Cloud LB URL | Customizable via DNS |

**Use LoadBalancer when**: Exposing non-HTTP services (databases, custom protocols).
**Use Ingress when**: Multiple HTTP services, need path-based routing, cost-conscious.

**Q12: How does the Ingress Controller discover which services to route to?**

A: 
1. Ingress Controller watches API server for Ingress objects
2. Parses Ingress rules, extracts service names
3. Watches Service objects for IP/endpoint changes
4. **Critical**: Ingress controller uses Service DNS name
5. When generating reverse proxy config, uses service DNS (not IP)
6. Service DNS resolves to Service VIP
7. When backend changes (pods added/removed), service endpoint changes
8. Proxy configuration already references service DNS, so no config reload needed

**Example**: Ingress rule says "route to api-service:8000"
- Controller generates config: "proxy_pass http://api-service.default.svc.cluster.local:8000"
- No need to update config when pods restart (DNS resolves to updated VIP)

### Expert-Level Questions

**Q13: Describe a scenario where services fail even though all pods are running.**

A: **Scenario: Label Mismatch**

```yaml
# Service defined with selector
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: backend  # Looking for label "app: backend"
---
# Deployment created with different label
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  selector:
    matchLabels:
      app: my-app  # Pods have label "app: my-app"
  template:
    metadata:
      labels:
        app: my-app
```

**Result**: Pods running, but service has no endpoints. Traffic fails.

**Other scenarios**:
- kube-proxy down on a node
- Network policies blocking traffic
- Pod doesn't have readiness probe (service receives traffic before ready)
- Service selector has typo but no validation catches it

**lesson**: Always verify `kubectl get endpoints my-service` returns actual pods.

**Q14: How would you implement request-level circuit breaking in Kubernetes?**

A: Services and Ingress don't provide request-level circuit breaking. Options:

1. **Application level** (best):
```go
// In app code
client := httpclient.NewClient(
    CircuitBreaker: true,
    FailureThreshold: 50%,
    Timeout: 5s,
)
```

2. **Service mesh** (Istio/Linkerd):
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: api-circuit-breaker
spec:
  host: api
  trafficPolicy:
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

3. **Sidecar proxy** (if using service mesh):
- Proxy detects 5xx responses
- Ejects pod from pool
- After timeout, retries

**Best practice**: Implement in application code or service mesh. Plain Kubernetes doesn't support this.

**Q15: In a multi-region cluster setup, how would you route traffic?**

A: Depends on deployment model:

**Option 1: Separate clusters per region**:
```
Client → Global LB (Route 53, Cloud LB)
├─ Route to US cluster LB
├─ Route to EU cluster LB
└─ Route to APAC cluster LB

Each regional cluster has own Ingress
```

**Option 2: Single cluster spanning regions**:
```
Single Kubernetes cluster with nodes in multiple regions
├─ Leverage Kubernetes scheduling (affinity) to place pods in specific regions
├─ Single Service, pods distributed across regions
└─ Network latency between regions critical (usually bad idea)
```

**Option 3: Service mesh with traffic management**:
```
Istio/Linkerd with multiple control planes
├─ Traffic split based on weight/geography
├─ Automatic failover between regions
├─ Better observability and control
```

**Complexity increases with each option. Most teams use Option 1** (separate regional clusters) because it avoids single huge cluster and provides blast radius isolation.

**Q16: Network policies security: How do you ensure they're correct before enforcing?**

A:

1. **Plan & Document**:
   - Diagram allowed flows on whiteboard
   - List every pod-to-pod connection needed
   - Include external services (APIs, databases outside cluster)

2. **Test in Audit Mode** (if CNI supports):
   - Deploy policy without enforcement
   - Monitor logs: "what would be blocked?"
   - Adjust rules

3. **Staged Rollout**:
   - Apply to non-critical namespace first
   - Monitor for issues
   - Roll out to critical namespaces

4. **Include DNS in planning**:
   - Easy mistake: Block port 53 UDP accidentally
   - Pods can't resolve service names

5. **Test before enforcing**:
   ```bash
   # Create test pod
   kubectl run --rm -it debug --image=alpine -- sh
   # Try connecting to services
   wget -O- http://service.namespace:port
   # If succeeds with policy applied, policy works
   ```

6. **Whitelist external services**:
   ```yaml
   egress:
   - to:
     - ipBlock:
         cidr: 203.0.113.0/24  # External service CIDR
     ports:
     - protocol: TCP
       port: 443
   ```

7. **Document exceptions**:
   ```yaml
   metadata:
     annotations:
       policy-exception: "Team X needs to access analytics (temporary)"
       expires: "2025-12-31"
       approver: "security-team@company.com"
   ```

---

## Advanced Hands-on Scenarios for Production Environments

### Scenario 1: Debugging Silent Service Failures Under Load

**Problem Statement**: In production, users report intermittent API timeouts during peak hours (4-6 PM daily). The Prometheus dashboard shows all services are "healthy," but the error rate spikes to 15%. No clear pattern in pod restarts or node issues.

**Architecture Context**:
```
Production Cluster:
├─ 10 worker nodes
├─ Frontend service: 20 replicas
├─ API service: 15 replicas
├─ Database access service: 5 replicas
├─ Load: ~30,000 RPS during peak
├─ Service type: ClusterIP (internal only)
└─ Ingress controller: 3 replicas (NGINX)
```

**Root Cause Analysis & Resolution**:

```bash
# Step 1: Identify which service has issues
kubectl get services -A --sort-by='{.metadata.creationTimestamp}' | head -20

# Step 2: Check service endpoints during peak load
# Terminal A: Watch endpoints in real-time
watch 'kubectl get endpoints <service-name> -o json | jq ".subsets[0].addresses | length"'

# Step 3: Check kube-proxy performance during load
# SSH to a node
kubectl debug node/<node-name> -it --image=ubuntu

# On node, check kube-proxy logs
journalctl -u kubelet -n 50 | grep kube-proxy

# Check iptables rule count (high count = degradation)
iptables-save | wc -l
# Expected: <50,000 rules
# Actual: 150,000 rules because of high service count

# Step 4: Check conntrack table saturation
cat /proc/sys/net/netfilter/nf_conntrack_count
cat /proc/sys/net/netfilter/nf_conntrack_max
# If count > 0.8 * max, table is nearly full

# Output showed:
# nf_conntrack_count: 500,000 (actual connections)
# nf_conntrack_max: 500,000 (maximum allowed)
# Result: Table is FULL - new connections dropped!
```

**Diagnosis**: During peak load, the kernel connection tracking table (conntrack) fills up. Every new connection needs a conntrack entry. Once full, the kernel silently drops new connections, causing timeouts.

**Fix Implementation**:

```bash
# Step 1: Increase conntrack table size (immediate, temporary)
kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | \
  tr ' ' '\n' | \
  xargs -I {} kubectl debug node/{} -it --image=ubuntu -- \
  sysctl -w net.netfilter.nf_conntrack_max=1000000

# Persistence: Update kubelet config on all nodes
# In /etc/kubernetes/kubelet.conf or systemd drop-in:
# --system-reserved=cpu=100m,memory=512M,ephemeral-storage=2Gi,pid=100
# Add to kubelet extraArgs in cloud config

# Step 2: Switch kube-proxy to IPVS mode (better scalability)
kubectl edit daemonset kube-proxy -n kube-system
# Change: --proxy-mode=ipvs

# Step 3: Implement connection pooling in client apps
# Before: Each request opens new connection
# After: Reuse connections from pool
# In app code (Go example):
func init() {
    client = &http.Client{
        Transport: &http.Transport{
            MaxIdleConns:        100,
            MaxIdleConnsPerHost:  50,
            IdleConnTimeout:     90 * time.Second,
        },
    }
}

# Step 4: Scale down non-essential services
# Some services were over-provisioned
kubectl scale deployment my-service --replicas=3 -n prod

# Step 5: Monitor solution
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: node-monitor
  namespace: kube-system
data:
  monitor.sh: |
    #!/bin/bash
    while true; do
      count=$(cat /proc/sys/net/netfilter/nf_conntrack_count)
      max=$(cat /proc/sys/net/netfilter/nf_conntrack_max)
      percent=$((count * 100 / max))
      echo "conntrack: $count/$max ($percent%)"
      
      if [ $percent -gt 80 ]; then
        echo "WARNING: conntrack table near capacity"
        # Alert monitoring system
      fi
      sleep 10
    done
EOF
```

**Production Lessons**:
- Conntrack saturation is silent (no obvious logs)
- Scales with RPS and connection churn
- Connection pooling is essential for HTTP services
- IPVS mode more efficient than iptables for large deployments
- Monitor /proc metrics, not just application metrics

---

### Scenario 2: Zero-Downtime Ingress Controller Upgrade

**Problem Statement**: Company needs to upgrade NGINX Ingress Controller from 1.6 to 1.8 in production cluster handling 50,000 RPS with mixed HTTP/2 and WebSocket connections. Previous upgrade attempt caused 30+ second downtime with connection resets.

**Architecture Context**:
```
Production Setup:
├─ 5 Ingress controller replicas
├─ Pod Disruption Budget: minAvailable: 3
├─ Traffic: HTTP/2 (80%), WebSocket (15%), gRPC (5%)
├─ SLA: 99.95% uptime (22 minutes downtime/month)
└─ External LB: AWS ALB with connection draining enabled
```

**Implementation Plan**:

```bash
# Step 1: Pre-flight checks
echo "=== Pre-flight Checks ==="

# Verify PDB configuration
kubectl get pdb -n ingress-nginx
# Expected: minAvailable >= 2 for 5 replicas

# Test new version in staging
kubectl create namespace ingress-nginx-staging
helm install ingress-nginx-staging ingress-nginx/ingress-nginx \
  -n ingress-nginx-staging \
  --version 1.8.0 \
  -f values-staging.yaml

# Run load test against staging for 30 minutes
# Using: https://github.com/wg/wrk or Apache Bench
wrk -t 12 -c 400 -d 30m \
  -H "Host: example.com" \
  http://staging-ingress-ip/

# Verify: No errors, latency stable

# Step 2: Upgrade preparation
echo "=== Upgrade Prep ==="

# Get current deployment status snapshot
kubectl get deployment -n ingress-nginx ingress-nginx-controller \
  -o yaml > ingress-controller-backup.yaml

# Verify Pod Disruption Budget allows rolling update
kubectl get pdb -n ingress-nginx ingress-nginx-controller \
  -o jsonpath='{.spec.minAvailable}' | grep -q "^[1-3]$" && echo "PDB OK"

# Step 3: Update Helm chart (with automatic rollback on failure)
echo "=== Performing Upgrade ==="

# Create upgrade transaction script
cat > upgrade.sh <<'UPGRADE'
#!/bin/bash
set -e

echo "Starting upgrade at $(date)"

# Upgrade with careful configuration
helm upgrade ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  --version 1.8.0 \
  --values production-values.yaml \
  --set controller.lifecycle.preStop.exec.command='["/bin/sh","-c","sleep 15"]' \
  --set controller.terminationGracePeriodSeconds=60 \
  --wait \
  --timeout 10m

echo "Upgrade completed at $(date)"
UPGRADE

chmod +x upgrade.sh

# Monitor upgrade in real-time (in separate terminal)
kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=10m

# Step 4: During upgrade, monitor metrics
echo "=== Monitoring Upgrade ==="

# Monitor every 5 seconds
watch -n 5 'kubectl get pods -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx \
  -o wide'

# In another terminal, check ingress responsiveness
bash <<'MONITOR'
for i in {1..200}; do
  response_time=$(curl -w %{time_total} -o /dev/null -s \
    -H "Host: example.com" \
    http://<ingress-ip>/)
  echo "Request $i: ${response_time}s"
  sleep 1
done
MONITOR

# Step 5: Validate upgrade success
echo "=== Post-Upgrade Validation ==="

# Check all pods running
running=$(kubectl get pods -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx \
  --field-selector=status.phase=Running -o json | jq '.items | length')
desired=$(kubectl get deployment ingress-nginx-controller \
  -n ingress-nginx -o jsonpath='{.spec.replicas}')

if [ "$running" -eq "$desired" ]; then
    echo "✓ All pods running"
else
    echo "✗ Not all pods running: $running/$desired"
    exit 1
fi

# Check for deployment issues
kubectl logs -n ingress-nginx \
  -l app.kubernetes.io/name=ingress-nginx \
  --tail=20 | grep -i error && \
  echo "Errors found in logs" || \
  echo "✓ No errors in logs"

# Verify version
kubectl exec -n ingress-nginx \
  $(kubectl get pods -n ingress-nginx \
    -l app.kubernetes.io/name=ingress-nginx \
    -o jsonpath='{.items[0].metadata.name}') \
  -- nginx -v

# Step 6: Smoke test
echo "=== Smoke Tests ==="

# Test HTTP
for path in / /health /api/v1/status; do
    status=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Host: example.com" \
      http://<ingress-ip>$path)
    echo "GET $path: $status"
    [ "$status" != "000" ] || { echo "Failed"; exit 1; }
done

# Test WebSocket upgrade
wscat -c ws://<ingress-ip>/ws \
  -H "Host: example.com"

echo "✓ Upgrade successful and validated"
```

**Key Configurations for Zero-Downtime**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1         # Add 1 pod at a time
      maxUnavailable: 0   # Never take down pods during upgrade
  
  template:
    spec:
      terminationGracePeriodSeconds: 60  # Allow 60s for connections to drain
      
      containers:
      - name: controller
        lifecycle:
          preStop:
            exec:
              # Sleep allows active connections to complete
              command: ["/bin/sh", "-c", "sleep 15"]
        
        # Readiness probe for LB to detect if pod is ready
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10254
          initialDelaySeconds: 2
          periodSeconds: 2
          failureThreshold: 1
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ingress-nginx-pdb
  namespace: ingress-nginx
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
```

**Production Outcome**: Upgrade completed with zero dropped connections. Latency remained stable (P99 < 100ms throughout). WebSocket connections persisted across pod restarts.

---

### Scenario 3: Service Mesh Migration Without Application Changes

**Problem Statement**: Security team mandates mTLS for all inter-service communication. Current setup has 50+ microservices with no mTLS. Updating every service individually would take months. Need approach that adds mTLS without code changes.

**Current State**:
```
50 Microservices
├─ Various languages (Go, Java, Python, Node.js)
├─ No mTLS
├─ Service-to-service communication over plain HTTP
├─ Zero observability into network communication
└─ Cannot modify application code (vendors, legacy systems)
```

**Solution: Istio Service Mesh Implementation**:

```bash
# Step 1: Install Istio control plane
istioctl install --set profile=production -y

# Step 2: Enable automatic sidecar injection
kubectl label namespace production istio-injection=enabled

# Step 3: Strict mTLS policy (default deny, explicit allow)
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: production
spec:
  mtls:
    mode: STRICT  # Only allow mTLS connections
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: default
  namespace: production
spec:
  host: "*.production.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL  # Client must use mTLS
EOF

# Step 4: Rollout sidecar proxies gradually
# Namespace 1 (lowest risk): payments
kubectl set env deployment --all -n payments \
  ISTIO_SIDECAR_INJECTION=true

# Monitor for issues
kubectl logs -n payments -l app=payment-service --tail=50 | grep error

# Namespace 2 (medium risk): auth
# Namespace N (highest risk): frontend

# Step 5: Verify mTLS enforcement
# Test: direct pod-to-pod connection should fail
kubectl exec -it <pod-a> -n production -- \
  curl http://<pod-b-direct-ip>:8080  # Should FAIL

# Test: service-based connection should work (via sidecar)
kubectl exec -it <pod-a> -n production -- \
  curl http://<service-name>.production.svc.cluster.local:8080  # Should SUCCEED

# Step 6: Monitoring and observability gains
# Kiali dashboard now shows service graph with TLS indicators
# Jaeger shows distributed tracing
# Prometheus captures: request rate, latency, errors per route
```

**Certificate Management** (automatic):
```yaml
# Istio automatically:
# 1. Issues certificates to every pod sidecar
# 2. Rotates before expiry (7-30 day validity)
# 3. Manages intermediate CAs
# 4. Handles certificate revocation on pod deletion

# Verification:
kubectl get certificate -n production
# Output shows certificates ready with expiry dates
```

**Traffic Management** (enabled by service mesh):
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: api-service
  namespace: production
spec:
  hosts:
  - api-service
  http:
  - match:
    - uri:
        prefix: /v1
    route:
    - destination:
        host: api-service
        subset: v1
      weight: 90
    - destination:
        host: api-service
        subset: v2
      weight: 10
    timeout: 10s
    retries:
      attempts: 3
      perTryTimeout: 2s
---
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: api-service
  namespace: production
spec:
  host: api-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 100
        http2MaxRequests: 1000
    loadBalancer:
      simple: LEAST_REQUEST
    outlierDetection:
      consecutiveErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

**Production Outcome**: 
- All services automatically using mTLS within 1 week
- Zero code changes required
- 100% certificate coverage
- Instant visibility into service dependencies
- Canary deployments now built into infrastructure

---

### Scenario 4: Handling Service Scale-Out Bottlenecks

**Problem Statement**: Company growing from 100 users to 10,000 users in 3 months. During peak hours, API service experiences latency spikes despite having low CPU/memory usage. Service scales from 5 to 20 replicas, but improvement doesn't match linear scaling expectation.

**Initial Investigation**:

```bash
# Metric analysis during peak hour
kubectl get hpa api-service -n prod --watch

# Observed:
# Replicas: 5-20 (scaling working)
# CPU/Memory: 20-40% (plenty of capacity)
# Latency: 50ms average, 500ms P99 (should be <100ms average)
# Error rate: 2-3% (acceptable threshold is <0.1%)

# Root cause analysis
echo "=== Potential bottlenecks ==="

# 1. Service discovery latency
kubectl logs -n kube-system -l k8s-app=coredns --tail=50 | \
  grep -i slowloop
# Output: Slow DNS resolution during peak (load)

# 2. Service VIP load balancing
kubectl exec -it <api-pod> -- curl -v http://api-service:8000/health 2>&1 | \
  grep -i "connected to"
# Connection times vary widely (10ms-100ms)

# 3. Endpoint churn
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=100 | \
  grep -i "synced\|updated"
# Shows 50+ endpoint updates per minute during burst scaling

# 4. Readiness probe failures
kubectl get pods -n prod -l app=api \
  -o custom-columns=NAME:.metadata.name,\
READY:.status.conditions[?(@.type=="Ready")].status,\
RESTARTS:.status.containerStatuses[*].restartCount

# Some pods restarting due to liveness probe timeout
```

**Problems Identified**:

```
1. CoreDNS under load
   - Limited to 2 replicas
   - Each query takes 50-200ms during peak
   
2. Service load balancing imbalance
   - iptables mode has O(n) lookup
   - New pods don't distribute equally
   - Some pods get 3x traffic of others
   
3. Readiness probe too aggressive
   - Probe timeout: 3 seconds
   - During scaling, startup takes 2-5 seconds
   - Pods marked not ready → removed from service → readded
   - Churn loop: pod added/removed 5-10 times before stable

4. Connection reuse issues
   - Client libraries reconnecting constantly
   - 5000 load balancing decisions needed
   - Iptables rule execution slows with pod count
```

**Solution Implementation**:

```bash
# Fix 1: Scale CoreDNS dynamically
kubectl autoscale deployment coredns -n kube-system \
  --min=2 --max=10 \
  --cpu-percent=70

# Or manually scale
kubectl scale deployment coredns -n kube-system --replicas=5

# Verify DNS performance
time nslookup api-service.prod.svc.cluster.local
# Before: 150ms
# After: 5ms

# Fix 2: Switch to IPVS mode for better scaling
kubectl patch daemonset -n kube-system kube-proxy -p \
  '{"spec":{"template":{"spec":{"containers":[{"name":"kube-proxy","args":["--proxy-mode=ipvs"]}]}}}}'

# Verify mode switched
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
# Look for "ipvs" in startup args

# Fix 3: Tune readiness probe for gradual traffic ramping
kubectl patch deployment api-service -n prod -p \
'{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "api",
          "readinessProbe": {
            "httpGet": {"path": "/healthz", "port": 8000},
            "initialDelaySeconds": 10,
            "periodSeconds": 5,
            "timeoutSeconds": 5,
            "failureThreshold": 3,
            "successThreshold": 2
          },
          "lifecycle": {
            "postStart": {
              "exec": {
                "command": ["/bin/sh", "-c", "sleep 15"]
              }
            }
          }
        }]
      }
    }
  }
}'

# Fix 4: Implement connection pooling in API calls
cat > app-config.yaml <<EOF
# In application config
http:
  client:
    maxIdleConns: 100
    maxIdleConnsPerHost: 50
    idleConnTimeout: 90s
    dialTimeout: 5s
    
  server:
    keepAliveTimeout: 75s
    readTimeout: 30s
    writeTimeout: 30s
EOF

# Fix 5: Implement pod anti-affinity (spread across nodes)
kubectl patch deployment api-service -n prod -p \
'{
  "spec": {
    "template": {
      "spec": {
        "affinity": {
          "podAntiAffinity": {
            "preferredDuringSchedulingIgnoredDuringExecution": [{
              "weight": 100,
              "podAffinityTerm": {
                "labelSelector": {
                  "matchExpressions": [
                    {"key": "app", "operator": "In", "values": ["api"]}
                  ]
                },
                "topologyKey": "kubernetes.io/hostname"
              }
            }]
          }
        }
      }
    }
  }
}'

# Fix 6: Monitor solution effectiveness
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: load-test-config
  namespace: prod
data:
  load-test.sh: |
    #!/bin/bash
    # Run during peak hour
    wrk -t 12 -c 400 -d 1h \
      -s profile.lua \
      -H "Host: api.example.com" \
      http://api-service:8000
EOF
```

**Results After Fixes**:

```
BEFORE:
├─ P50 latency: 50ms
├─ P99 latency: 500ms
├─ Error rate: 2.5%
├─ Replicas during peak: 20
├─ Actual throughput: 5,000 RPS
├─ Imbalance: 40% variance in pod loads
└─ DNS queries: 200ms average

AFTER:
├─ P50 latency: 12ms
├─ P99 latency: 45ms
├─ Error rate: 0.01%
├─ Replicas during peak: 12 (sufficient)
├─ Actual throughput: 15,000 RPS
├─ Imbalance: 5% variance in pod loads
└─ DNS queries: 3ms average
```

**Key Takeaways**:
- Scaling isn't just about pod count; it's about efficient load distribution
- CoreDNS is critical path for service discovery; scale it proactively
- iptables mode has practical limits (~500 services comfortably)
- Pod readiness tuning crucial during rapid scaling
- Connection pooling prevents cascade of new connections
- IPVS mode nearly mandatory for >50 services

---

## Most Asked Interview Questions for Senior DevOps Engineers

### Production Operations & Incident Response

**Q17: You get paged at 2 AM: "All traffic to our API service is failing with 503 errors." Describe your immediate diagnostic steps and decision tree.**

A: First 2 minutes (triage):

```bash
# Connect to cluster immediately
kubectl config use-context prod-cluster

# Step 1: Verify service exists and has traffic route
kubectl get svc api-service -n prod -o wide
kubectl get endpoints api-service -n prod

# Check: Does Endpoint have Pod IPs?
# If empty → label selector mismatch → CRITICAL

# Step 2: Check pod status
kubectl get pods -n prod -l app=api --sort-by='.metadata.creationTimestamp' | tail -10

# Look for: Restart count, CrashLoopBackOff, Pending, NotReady

# Step 3: Traffic path validation
# Are Ingress rules still pointing to service?
kubectl get ingress -n prod -o wide

# Is external LB routing to nodes?
# (Check cloud provider console: AWS ALB health, target groups status)

# Step 4: Application health
kubectl logs -n prod -l app=api --tail=50 --timestamps=true | tail -20

# Look for: Application errors, startup failures, dependency errors
```

**Decision Tree** (first 5 minutes):
```
Question 1: Do pods exist?
├─ NO → Deployment issue
│  └─ Check: kubectl describe deployment api-service
│         Why didn't pods schedule? Resource quota? Node failure?
│
└─ YES → Question 2: Are pods running?
   ├─ NO → CrashLoop or startup failure
   │  └─ Check: kubectl logs, kubectl describe pod
   │         Application failing to start? Readiness probe failing?
   │         Dependencies unavailable?
   │
   └─ YES → Question 3: Do endpoints exist?
      ├─ NO → Label mismatch
      │  └─ Check: Service selector vs Pod labels
      │         kubectl get pods --labels show issues?
      │
      └─ YES → Question 4: Can you reach pod directly?
         ├─ NO → Network policy, CNI issue, pod not listening
         │  └─ Check: kubectl exec -it pod -- curl localhost:8080
         │         Is port correct? Is app listening?
         │
         └─ YES → Question 5: Can you reach pod via service?
            ├─ NO → kube-proxy, iptables, DNS issue
            │  └─ Check: kubectl exec -it pod -- nslookup api-service
            │         DNS works? Service DNS resolves?
            │
            └─ YES → Ingress, LB routing, TLS issue
               └─ Check: Ingress rules, cloud LB config, certificates
                      Is traffic even reaching cluster?
```

**Actions** (parallel to investigation):
```
1. While investigating, check:
   - Cloud provider LB status (AWS ALB/ELB health checks)
   - Node status (any nodes in NotReady state?)
   - Etcd status (core API functionality)
   - Monitoring alerts (was there an event before?)

2. Immediate mitigation options:
   - Scale replicas higher (might unlock resource issues)
   - Restart pods if misconfiguration (rollout restart)
   - Verify DNS is responding (might be CoreDNS down)
   - Check network connectivity between nodes
   - If transient, rolling restart may fix without downtime

3. Communication:
   - Alert on-call team captain
   - Create incident ticket
   - Estimate impact (% of users, service name, SLA)
```

**Real scenario example**:
```
Actual incident: API service returning 503s during promotion

Investigation found: Readiness probe pointing to /healthz but endpoint was /health
Restarted pods → came up healthy → traffic resumed
RCA: Service readiness probe changed during deployment but Deployment spec not updated
```

---

**Q18: Walk us through a high-throughput service redesign. How would you architect services for 1 million RPS?**

A: This is an architecture question revealing understanding of scaling limits:

```
Architecture Design for 1M RPS:
═════════════════════════════════════════════════════

Constraint Analysis:
├─ Single pod capacity: ~50,000 RPS (typical app with 2 CPU cores)
├─ This means: Need minimum 20 pods just to handle load
├─ But add: overhead for failures, graceful shutdown, rolling updates
│  → Realistic minimum: 30-50 pods for 1M RPS
│
├─ Single Service (iptables mode): ~100 endpoint practical limit
│  → IPVS or custom load balancing required
│
├─ Single Ingress controller: ~100,000 RPS capacity
│  → Need ~10 replicas minimum
│
└─ Network per pod: 10Gbps NIC typical
   → Pod can saturate NIC at ~200,000 RPS depending on packet size


Architecture Option 1: Sharded Services
───────────────────────────────────────
Frontend Ingress (10 replicas, running on 5 nodes)
    ↓
Sharding Layer (consistent hash by user_id)
    ├─ service-shard-0 (50 replicas) → Handle user IDs 0-99999
    ├─ service-shard-1 (50 replicas) → Handle user IDs 100000-199999
    ├─ service-shard-2 (50 replicas) → Handle user IDs 200000-299999
    └─ service-shard-N (50 replicas) → ... (10 shards needed)
    
Advantages:
├─ Each service scales independently
├─ Failures limited to one shard
├─ Better cache locality
├─ Can failover between shards

Disadvantages:
├─ Complex routing logic
├─ Rebalancing on pod changes
└─ Operational overhead


Architecture Option 2: Geographic Distribution
──────────────────────────────────────────────
Global DNS (Route 53, ns1.com)
    ├─ 30% traffic → US-East cluster (250K RPS)
    ├─ 25% traffic → US-West cluster (250K RPS)
    ├─ 25% traffic → Europe cluster (250K RPS)
    └─ 20% traffic → APAC cluster (200K RPS)

Each regional cluster:
├─ Service replicas: 25-50 (based on regional load)
├─ Ingress replicas: 3-5
└─ Database: Regional replica for lower latency

Advantages:
├─ Scale limits per cluster: ~1M RPS each
├─ Lower latency per user
├─ Isolation between regions
├─ Better compliance (data sovereignty)

Disadvantages:
├─ Multi-region operational complexity
├─ Cross-region traffic potentially slow
└─ Cost: Multiple clusters


Architecture Option 3: Hybrid (Most Realistic)
──────────────────────────────────────────────
Primary Cluster (750K RPS):
├─ 3 availability zones
├─ Ingress replicas: 8 (across zones)
├─ Service replicas: 200-300
├─ Read-only cache layer (Redis): 5 nodes, 4TB memory
├─ Database: Sharded PostgreSQL (5 shards, primary + 2 replicas each)
└─ Message queue: Kafka cluster (10 brokers) for async processing

Secondary Cluster (250K RPS backup):
├─ Passive replication from primary
├─ Auto-failover on primary region down
└─ Used for canary deployments

Service Design within Cluster:
├─ API Gateway service: 20 replicas
│  └─ Routes to specialized services
├─ Business Logic service: 100 replicas
│  └─ CPU intensive, high replica count
├─ Data Access Layer: 50 replicas
│  └─ Connection pooling to databases
└─ Cache layer: 30 replicas
   └─ Handles hot data, reduces DB load


Operational Considerations:
──────────────────────────
1. Load Shedding:
   ├─ At 95% capacity: Start rejecting new connections
   ├─ Priority queue for critical requests
   └─ Fail fast instead of timeout

2. Connection Limits:
   ├─ Per pod: 10,000 max connections (typical OS limit)
   ├─ Connection pooling: 100-500 pool size
   └─ Keep-alive: 75-90 second timeout

3. Resource Limits:
   ├─ Memory: 2-4GB per pod (reserve overhead)
   ├─ CPU: 2-4 cores per pod (2 preferred to avoid context switching)
   ├─ Disk: Ephemeral storage only
   └─ Network: 1Gbps guaranteed, burst to 10Gbps

4. Horizontal Pod Autoscaler (HPA):
   ├─ CPU threshold: 60% (leave headroom)
   ├─ Scaling window: 30-60 seconds (avoid thrashing)
   ├─ Max replicas: 300 (practical limit)
   └─ Metrics: CPU + custom metrics (queue depth, latency)

5. Orchestration:
   ├─ Node count: 50-100 (distributed across 3 AZs)
   ├─ Pod disruption budgets: Minimum 30% available
   ├─ Rolling updates: 1 pod at a time, 10-minute window
   └─ Rolling back: Must be instant (0-second recovery)
```

**Code Example: Service design for throughput**:

```go
// Go service optimized for 50K RPS per pod
func init() {
    // Connection pooling to database
    db = &sql.DB{
        ConnMaxIdleTime: 5 * time.Minute,
        ConnMaxLifetime: 30 * time.Minute,
        MaxOpenConns: 100,  // Total connections
        MaxIdleConns: 25,   // Always keep 25 ready
    }
    
    // HTTP client pool
    httpClient = &http.Client{
        Timeout: 10 * time.Second,
        Transport: &http.Transport{
            MaxIdleConns: 100,
            MaxIdleConnsPerHost: 50,
            MaxConnsPerHost: 100,
            IdleConnTimeout: 90 * time.Second,
            DisableKeepAlives: false,
            DisableCompression: true,  // Compression expensive, network fast
        },
    }
}

// Request handler: minimal allocations (0 GC)
func handleRequest(w http.ResponseWriter, r *http.Request) {
    // Parse input (use path parameters over query strings)
    userID := r.PathValue("user_id")
    
    // Cache check (often avoids DB hit)
    if cached, ok := cache.Get(userID); ok {
        respondJSON(w, cached)
        return
    }
    
    // Database query (connection from pool)
    data := db.QueryRow("SELECT ... FROM users WHERE id = $1", userID)
    
    // Response with keep-alive connection
    w.Header().Set("Connection", "keep-alive")
    respondJSON(w, data)
}

// Load shedding
var (
    activeRequests int64
    maxRequests    = 50000
)

func middleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        if atomic.LoadInt64(&activeRequests) >= int64(maxRequests) {
            http.Error(w, "Server busy", http.StatusServiceUnavailable)
            return
        }
        
        atomic.AddInt64(&activeRequests, 1)
        defer atomic.AddInt64(&activeRequests, -1)
        
        next.ServeHTTP(w, r)
    })
}
```

**Q19: Your company is expanding globally. How would you approach multi-region Kubernetes deployment?**

A: This tests strategy and operational thinking:

```
Multi-Region Strategy:
═════════════════════════════════════════════

Tier 1: Infrastructure Choice
──────────────────────────────

Option A: Separate Regional Clusters (Recommended)
├─ Each region: Independent Kubernetes cluster
├─ Region 1 (US-East): 50-100 nodes
├─ Region 2 (EU-West): 50-100 nodes
├─ Region 3 (APAC): 50-100 nodes
└─ Advantage: Blast radius containment, independent scaling

Option B: Stretched Single Cluster
├─ Nodes distributed across regions (~50ms latency between zones)
├─ Complex networking (inter-region is slow)
├─ Etcd replication across regions (dangerous for consistency)
└─ Not recommended due to latency sensitivity


Tier 2: Data Consistency Strategy
────────────────────────────────

Strong Consistency (Expensive):
├─ Single primary database (US) with synchronous replication
├─ All writes go to US (latency for EU/APAC users)
├─ Read replicas in each region
└─ Use case: Financial transactions, user auth

Eventual Consistency (Scalable):
├─ Regional databases with async replication
├─ Each region can write locally
├─ Conflicts resolved via Last-Write-Wins or application logic
├─ Use case: User preferences, analytics, non-critical data

Hybrid (Most Common):
├─ Hot data (user profile, settings): Strong consistency via primary
├─ Cold data (analytics, recommendations): Eventual consistency
├─ Cache layer: Local caching for read-heavy data


Tier 3: Application Architecture
────────────────────────────────

Stateless Services (Easy):
├─ API gateway: Replicate to each region
├─ Business logic: Deploy to each region
├─ Does not need cross-region communication
└─ Example: REST API, search service

Stateful Services (Complex):
├─ Cache layer: Redis in each region, cross-region replication
├─ Message queue: Kafka, RabbitMQ (region-specific partitioning)
├─ Database: Primary/replica setup per region
└─ Example: User sessions, queuing system

Coordination Services (Critical):
├─ Leader election: ETCD cluster spanning regions (challenging)
├─ Distributed locks: Globally managed with strong consistency
├─ Secrets: Stored centrally with region-aware access
└─ Solution: Dedicated coordination service instead of distributed


Tier 4: Network Architecture
───────────────────────────

Global Anycast DNS:
```
Global DNS (Route 53, Dyn)
├─ api.example.com
├─ Geolocation routing
├─ Latency-based routing
└─ Failover routing

Regional Ingress:
Region 1 (us-east-1):
├─ ALB: api-us.example.com
├─ IP: 1.2.3.4
└─ Endpoint: traffic routed here for US users

Region 2 (eu-west-1):
├─ ALB: api-eu.example.com
├─ IP: 5.6.7.8
└─ Endpoint: traffic routed here for EU users

Region 3 (ap-south-1):
├─ ALB: api-ap.example.com
├─ IP: 9.10.11.12
└─ Endpoint: traffic routed here for APAC users

Client request:
├─ Resolves api.example.com
├─ DNS resolves to nearest region based on:
│  ├─ Geolocation
│  ├─ Latency measurement
│  └─ Health check status
└─ Traffic routed accordingly
```

**Inter-Region Communication** (for cross-region needs):

```
Service Mesh (Istio, Linkerd):
├─ Supports VirtualService across regions
├─ Automatic failover to secondary region
├─ Circuit breakers for unreliable links
└─ Configure:
   ```yaml
   apiVersion: networking.istio.io/v1beta1
   kind: VirtualService
   metadata:
     name: global-db
   spec:
     hosts:
     - db.global
     http:
     - route:
       - destination:
           host: db-us.us-east.svc.cluster.local
           port: 5432
         weight: 80
       - destination:
           host: db-eu.eu-west.svc.cluster.local
           port: 5432
         weight: 20
       timeout: 5s
       retries:
         attempts: 3
   ```

OR custom gateway service:

```
Global Gateway Service (deployed in each region):
├─ Routes calls to correct region based on:
│  ├─ User's home region (stored in header)
│  ├─ Latency (measure and adapt)
│  └─ Availability (circuit breaker)
├─ Example: gateway.example.com resolves differently per region
└─ Gateway in each region knows how to reach others
```


Tier 5: Operational Challenges
──────────────────────────────

Challenge 1: Secrets Management
├─ Kubernetes Secrets replicated across regions?
├─ Solution: Sealed Secrets + GitOps with region-specific values
├─ Or: Vault cluster with region-specific auth
└─ Example:
   ```bash
   # Sealed secret for region-specific DB password
   sealedsecrets:
     db-password-us: <sealed>
     db-password-eu: <sealed>
   ```

Challenge 2: Image Pull Latency
├─ Pulling images from US registry to APAC takes minutes
├─ Solution: Docker registry cache in each region
├─ Or: Docker registry replicas in each region
└─ Terraform:
   ```hcl
   resource "aws_ecr_repository" "app" {
     repository_name = "app-service"
   }
   
   resource "aws_ecr_replication_configuration" "app" {
     rules {
       destination_region = "eu-west-1"
       destination = "123456789.dkr.ecr.eu-west-1.amazonaws.com"
     }
   }
   ```

Challenge 3: Kubernetes Secrets Sync
├─ Secrets need to exist in every cluster
├─ Solution 1: External Secrets Operator (pulls from Vault)
├─ Solution 2: Manual sync with validation
└─ Example:
   ```bash
   # Deploy ExternalSecret in each region
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: app-secrets
   spec:
     refreshInterval: 1h
     secretStoreRef:
       name: vault
       kind: SecretStore
     target:
       name: app-secrets
       template:
         type: Opaque
     data:
     - secretKey: db-password
       remoteRef:
         key: secret/data/regions/{{REGION}}/db-password
   ```

Challenge 4: Cluster Monitoring  & Logging
├─ Logs from 3-10 regions need central visibility
├─ Prometheus in each region forwards to central Prometheus
├─ ELK Stack: Central ES cluster, region-specific Filebeat
└─ Deployment:
   ```bash
   # Each region's Prometheus scrapes local services
   # Remote write to central Prometheus
   remote_write:
   - url: https://prometheus-central.prod.internal:9009/api/v1/push
     basic_auth:
       username: regional-agent
       password: <region-specific-token>
   ```

Challenge 5: Disaster Recovery
├─ If region N fails completely, what happens?
├─ DNS failover: Route 53 health checks
├─ Pod migration: Not possible across K8s clusters (by design)
├─ Data failover: RTO (Recovery Time Objective) depends on replication lag
└─ Example:
   ```bash
   # Periodic failover testing
   # Every month, simulate region failure
   # Verify traffic shifts to backup region
   # RTO target: 30 seconds (includes DNS TTL)
   # RPO target: 5 minutes (acceptable data loss)
   ```


Tier 6: Cost Optimization
────────────────────────

Multi-cluster costs can be 3-4x single cluster:
├─ Infrastructure: 10x cost (10 clusters instead of 1)
├─ Operations: 5x cost (expertise needed per region)
├─ Replication: 2x cost (bandwidth, storage duplication)
└─ Tools: 2x cost (license per cluster)

Cost Reduction Strategies:
├─ Right-size clusters (not all need same size)
├─ Use spot instances (20-30% savings)
├─ Consolidate non-production workloads
├─ Shared infrastructure (APIGateway, Observability)
└─ Example:
   ```hcl
   # Prod cluster: on-demand instances
   # Staging/Dev: spot instances (80% discount)
   
   resource "aws_eks_node_group" "prod" {
     capacity_type = "ON_DEMAND"
     instance_types = ["t3.xlarge"]
   }
   
   resource "aws_eks_node_group" "dev" {
     capacity_type = "SPOT"
     instance_types = ["t3.xlarge", "t3a.xlarge", "t2.xlarge"]
   }
   ```


Real-World Example: Slack's Global Platform
─────────────────────────────────────────────
- 6+ regional clusters
- Each region independent
- Strong consistency for authentication
- Eventual consistency for messages (!)
- Central monitoring & alerting
- Disaster recovery: RTO 1 hour, full automated failover
- Cost: Estimated $50M+ annually for infrastructure
```

---

**Q20: Your service has customers in EU and US. GDPR requires data not leave EU. How would you architect this?**

A: This tests compliance knowledge (critical for senior roles):

```
GDPR Architecture:
═══════════════════════════════════════════

Requirement: No EU personal data leaves EU

Breakdown:
├─ Personal data: Name, email, IP address, user ID, etc.
├─ Non-personal: Logs, metrics, aggregates
├─ Processing: Must have legal basis
└─ Storage: EU personal data → Must stay in EU


Architecture Applied:
─────────────────────

EU Region (ireland):
├─ Kubernetes cluster in eu-west-1
├─ PostgreSQL: In Ireland (physically located)
├─ Redis cache: In Ireland
├─ Elasticsearch: In Ireland (for EU user logs)
├─ All GDPR data: Must not leave this region
└─ Services: Running on eu-west-1 nodes

US Region (us-east-1):
├─ Kubernetes cluster in us-east-1
├─ PostgreSQL: In US (physically located)
├─ Redis cache: In US
├─ Elasticsearch: In US (for US-only metrics)
├─ US user data lives here
└─ Services: Running on us-east-1 nodes

Global (Must cross borders):
├─ Anonymous metrics (aggregate traffic)
├─ Non-personal logs (error messages, not user info)
├─ Infrastructure monitoring (CPU, memory of servers)
└─ NOT: User names, emails, IP addresses, or anything traceable


Data Separation Implementation:
───────────────────────────────

```yaml
# Kubernetes deployment strategy
---
# EU Service (Kubernetes)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service-eu
  namespace: production-eu
spec:
  template:
    spec:
      nodeSelector:
        region: eu-west-1
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: karpenter.sh/zone
                operator: In
                values: ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
      
      containers:
      - name: api
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: eu-db-url  # Points to Ireland DB only
        
        - name: REDIS_URL
          value: "redis://redis-eu.production-eu.svc.cluster.local:6379"  # EU Redis only
        
        - name: REGION
          value: "EU"
        
        volumeMounts:
        - name: gdpr-config
          mountPath: /etc/gdpr
          readOnly: true
      
      volumes:
      - name: gdpr-config
        configMap:
          name: gdpr-config
---
# GDPR Configuration Map
apiVersion: v1
kind: ConfigMap
metadata:
  name: gdpr-config
  namespace: production-eu
data:
  data-retention-policy.json: |
    {
      "user_data": {
        "retention_days": 730,  # 2 years for GDPR deletion
        "deletion_on_account_close": true,
        "right_to_be_forgotten": true
      },
      "audit_logs": {
        "retention_days": 2555,  # ~7 years for compliance
        "contains_personal_data": false
      },
      "cross_border_transfer": {
        "allowed": false,  # Explicit: No data leaves
        "exceptions": ["anonymized_metrics"],
        "review_frequency": "quarterly"
      }
    }
  
  allowed-data-exports.json: |
    {
      "exports": [
        {
          "name": "daily-metrics",
          "region": "US",
          "contains_personal_data": false,
          "description": "Aggregate traffic, not user-specific"
        },
        {
          "name": "error-logs",
          "region": "US",
          "redaction_rules": [
            "($.*email)",
            "($.*ip_address)",
            "($.*user_id)"
          ]
        }
      ]
    }

---
# Service to enforce GDPR
apiVersion: v1
kind: Service
metadata:
  name: gdpr-enforcement-service
  namespace: production-eu
spec:
  ports:
  - port: 8080
  selector:
    app: gdpr-enforcement

---
# Deployment: GDPR Enforcement
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gdpr-enforcement
  namespace: production-eu
spec:
  replicas: 2
  selector:
    matchLabels:
      app: gdpr-enforcement
  template:
    metadata:
      labels:
        app: gdpr-enforcement
    spec:
      serviceAccountName: gdpr-enforcement
      containers:
      - name: enforcer
        image: my-org/gdpr-enforcement:latest
        ports:
        - containerPort: 8080
        env:
        - name: WATCH_NAMESPACE
          value: "production-eu"
        - name: ENFORCE_CROSS_BORDER
          value: "true"  # Actively block cross-border data transfer
        
        # Read-only config
        volumeMounts:
        - name: gdpr-rules
          mountPath: /etc/gdpr-rules
          readOnly: true
      
      volumes:
      - name: gdpr-rules
        configMap:
          name: gdpr-config
```

**Enforcement Mechanisms**:

1. **Network Policy: Block Cross-Border**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-eu-to-us-data
  namespace: production-eu
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # Allow DNS (outgoing queries)
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: UDP
      port: 53
  
  # Allow to EU databases (in-region only)
  - to:
    - ipBlock:
        cidr: 10.0.0.0/8  # VPC CIDR (Ireland)
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
  
  # Allow to monitoring (with redaction on egress)
  - to:
    - ipBlock:
        cidr: 10.100.0.0/16  # Monitoring region (EU)
    ports:
    - protocol: TCP
      port: 9200  # Elasticsearch
  
  # BLOCKS: Any egress to US (outside VPC CIDR)
  # This will prevent accidental data leaks
```

2. **Data Redaction in Logs**:
```go
// In application
func redactGDPRData(log string) string {
    // Remove email addresses
    log = regexp.MustCompile(`\b[^\s@]+@[^\s@]+\.[^\s@]+\b`).ReplaceAllString(log, "[REDACTED_EMAIL]")
    
    // Remove IP addresses
    log = regexp.MustCompile(`\b(?:\d{1,3}\.){3}\d{1,3}\b`).ReplaceAllString(log, "[REDACTED_IP]")
    
    // Remove user IDs if in EU context
    if os.Getenv("REGION") == "EU" {
        log = regexp.MustCompile(`user_id=\d+`).ReplaceAllString(log, "user_id=[REDACTED]")
    }
    
    return log
}
```

3. **Audit Trail (immutable, in-region)**:
```yaml
# Every data access is logged
apiVersion: v1
kind: ConfigMap
metadata:
  name: data-access-audit
  namespace: production-eu
data:
  audit-policy.yaml: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    # Log all PVC access in EU region
    - level: RequestResponse
      verbs: ["get", "watch", "list"]
      resources:
      - group: ""
        resources: ["secrets", "configmaps"]
      omitStages:
      - RequestReceived
```

4. **Data Subject Rights Implementation**:
```go
// GDPR Right to Access
func (s *Service) ExportUserData(userID string) ([]byte, error) {
    // Verify user is requesting own data
    // Return ALL personal data in portable format (JSON)
    
    data := map[string]interface{}{}
    
    // From user database
    user, _ := s.db.GetUser(userID)
    data["profile"] = user
    
    // From cache
    sessions, _ := s.cache.GetUserSessions(userID)
    data["sessions"] = sessions
    
    // From logs (only EU logs)
    logs, _ := s.logs.GetUserLogs(userID)
    data["activity_logs"] = logs
    
    return json.Marshal(data)
}

// GDPR Right to be Forgotten
func (s *Service) DeleteUserData(userID string) error {
    // Delete from primary storage
    _ = s.db.DeleteUser(userID)
    
    // Delete from cache
    _ = s.cache.DeleteUserSessions(userID)
    
    // Anonymize logs (replace user ID with hash)
    _ = s.logs.AnonymizeUserLogs(userID)
    
    // Delete from backups
    // (must ensure backup retention doesn't violate right to be forgotten)
    
    // Log deletion for compliance
    s.auditLog.Log("DELETE_USER", userID, time.Now())
    
    return nil
}
```

5. **Compliance Reporting**:
```bash
# Monthly GDPR compliance check
#!/bin/bash

echo "=== GDPR Compliance Report ==="

# Check 1: No EU data in US
us_cluster_pods=$(kubectl get pods -n production-us -o name | wc -l)
kubectl get configmaps -n production-us -o json | \
  jq '.items[].data | tostring' | \
  grep -i "email\|ssn\|passport" && \
  echo "WARNING: EU data found in US cluster" || \
  echo "✓ No EU data in US cluster"

# Check 2: Network policies enforced
kubectl get networkpolicies -n production-eu | grep -q "block-eu-to-us" && \
    echo "✓ Cross-border blocking enabled" || \
    echo "ERROR: No cross-border policy!"

# Check 3: Data deletion queue
deleted_users=$(kubectl get -n production-eu \
  configmaps gdpr-deletions -o jsonpath='{.data.count}' || echo "0")
echo "Pending deletions: $deleted_users"

# Check 4: Audit log integrity
est_size=$(du -sh eu-postgresql-backups/ | cut -f1)
echo "Audit trail size: $est_size"

# Check 5: Data retention policies
retention=$(kubectl get configmap -n production-eu gdpr-config \
  -o jsonpath='{.data.data-retention-policy\.json}' | jq '.user_data.retention_days')
echo "Data retention: $retention days (required: 730)"
```

**Key Points**:
- **Hard boundaries**: Network policies enforce region separation
- **No cross-region data transfer**: Data cannot leave EU by design
- **Audit trail**: Every access logged, immutable
- **Deletion**: Automated right-to-be-forgotten with safe retention periods
- **Testing**: Run quarterly GDPR compliance simulations
- **Documentation**: Maintain Data Processing Agreement (DPA) with cloud provider
```

---

**End of Study Guide**

This comprehensive study guide covers Services, Ingress, and Kubernetes Networking at a senior DevOps level, including production scenarios and expert-level interview questions. The material is suitable for engineers with 5-10+ years experience preparing for senior DevOps and Site Reliability roles.

Total content: 6500+ lines of detailed technical knowledge, practical examples, real-world scenarios, and interview preparation material.
