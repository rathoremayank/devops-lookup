# Kubernetes ConfigMaps, Secrets, Storage, Resource Management, Healthchecks & Probes, Logging & Monitoring

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Introduction](#introduction)
  - [Overview of Topic](#overview-of-topic)
  - [Why It Matters in Modern DevOps Platforms](#why-it-matters-in-modern-devops-platforms)
  - [Real-World Production Use Cases](#real-world-production-use-cases)
  - [Where It Typically Appears in Cloud Architecture](#where-it-typically-appears-in-cloud-architecture)
- [Foundational Concepts](#foundational-concepts)
  - [Key Terminology](#key-terminology)
  - [Architecture Fundamentals](#architecture-fundamentals)
  - [Important DevOps Principles](#important-devops-principles)
  - [Best Practices](#best-practices)
  - [Common Misunderstandings](#common-misunderstandings)
- [ConfigMaps and Secrets](#configmaps-and-secrets)
- [Storage Concepts](#storage-concepts)
- [Resource Management](#resource-management)
- [Healthchecks & Probes](#healthchecks--probes)
- [Logging & Monitoring](#logging--monitoring)
- [Hands-on Scenarios](#hands-on-scenarios)
- [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

This study guide covers five critical pillars of Kubernetes production operations that form the backbone of reliable, scalable, and observable containerized workloads:

1. **ConfigMaps and Secrets** – Configuration and sensitive data management
2. **Storage Concepts** – Persistent data handling, volume abstraction, and stateful applications
3. **Resource Management** – CPU/Memory allocation, Quality of Service (QoS), and cluster efficiency
4. **Healthchecks & Probes** – Application lifecycle management and automatic remediation
5. **Logging & Monitoring** – Observability, diagnostics, and performance management

These components are interdependent and collectively determine whether an application can run reliably in production Kubernetes environments. A Senior DevOps engineer must deeply understand not just the "how" but the "why" behind each component's design and the trade-offs involved in implementation choices.

### Why It Matters in Modern DevOps Platforms

Modern DevOps practices emphasize **infrastructure as code**, **declarative configuration**, **observability**, and **high availability**. Kubernetes provides the orchestration platform, but these five areas determine whether that platform can deliver on those promises:

- **ConfigMaps & Secrets** enable environment-agnostic deployments, allowing the same container image to run across development, staging, and production by externalizing configuration
- **Storage** ensures data persistence across pod lifecycle events and enables stateful applications (databases, caches, message queues) to run in Kubernetes
- **Resource Management** prevents resource contention, improves cluster utilization, and enables horizontal scaling to be both predictable and cost-effective
- **Healthchecks & Probes** automate recovery from transient failures and enable zero-downtime deployments
- **Logging & Monitoring** transforms black boxes into observable systems, enabling rapid incident response and continuous improvement

Without mature understanding of these areas, organizations often face:
- Configuration drift across environments
- Data loss due to improper volume management
- Cluster thrashing due to resource contention
- Cascading failures due to lack of proper health detection
- Long MTTR (Mean Time To Recovery) due to poor observability

### Real-World Production Use Cases

#### E-Commerce Platform (Multi-Tier Application)
A distributed e-commerce platform runs microservices across multiple namespaces:
- **Frontend service** uses ConfigMaps for feature flags and environment URLs
- **API service** stores database credentials and API keys in Secrets
- **Cart service** uses Redis (StatefulSet) with PersistentVolumes for session data
- **Order service** processes orders with strict resource limits to prevent cost overruns
- **Payment processor** uses liveness probes to detect hung connections and readiness probes to handle graceful deployments
- **Audit logging system** aggregates logs from all services via sidecar pattern, feeding into centralized ELK stack

Without proper management:
- Secrets would be committed to Git (security breach)
- Redis pod restarts would lose session data (data loss)
- Unmanaged memory growth would crash worker nodes (availability issue)
- Hung payment connections would go undetected (revenue loss)

#### Data Pipeline (Kafka + Spark + PostgreSQL)
Real-time analytics platform:
- **Kafka brokers** (StatefulSet) require persistent storage per broker (no cross-pod data sharing)
- **Spark jobs** request 8 CPU / 32GB memory; must reject jobs if insufficient cluster resources (resource quotas)
- **PostgreSQL** requires dynamic provisioning of EBS volumes per replica set with proper RWO/RWX semantics
- **Monitoring pipeline** tracks job completion via custom metrics (Prometheus) and logs via EFK stack
- **Startup probe** prevents readiness checks before Kafka broker elected as leader

Without proper implementation:
- Kafka broker failure causes data loss (no persistence guarantees)
- Spark cluster overprovisioning causes all jobs to fail (no QoS enforcement)
- Data corruption across Kafka replicas (storage isolation issues)
- Unable to detect Kafka leader election (no health probes)
- Invisible performance regressions (no monitoring)

#### Multi-Team SaaS Platform
Environment with 50+ microservices across 10+ teams:
- Each team owns a namespace with isolated resource quotas
- Centralized secret management with Sealed Secrets + external secret vault
- Shared storage classes with different QoS tiers (fast NVMe for databases, standard for logs)
- Health checks configured per service type (gRPC, HTTP, TCP)
- Centralized monitoring with cross-namespace dashboards

Without proper governance:
- Team A's misconfigured resource limits crash Team B's services (neighbor noise)
- Secrets scattered across ConfigMaps, environment variables, and code
- Storage allocation decisions left to individual teams (no cost tracking)
- Undocumented health check behavior (operations team confusion)
- No visibility into cross-team dependencies and failures

### Where It Typically Appears in Cloud Architecture

These components form the operational layer of Kubernetes clusters:

```
┌─────────────────────────────────────────────────┐
│          Cloud Platform (AWS/Azure/GCP)         │
├─────────────────────────────────────────────────┤
│          Kubernetes Cluster                     │
│  ┌──────────────────────────────────────────┐  │
│  │ Control Plane (API Server, Scheduler)    │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────┐  │
│  │ Worker Nodes                             │  │
│  │  ┌─────────────┐  ┌──────────────────┐  │  │
│  │  │ Pod with    │  │ Pod with Probe   │  │  │
│  │  │ ConfigMap   │  │ Liveness Check   │  │  │
│  │  │ & Secrets   │  │ Resource Limits  │  │  │
│  │  └─────────────┘  └──────────────────┘  │  │
│  │  ┌──────────────────────────────────┐  │  │
│  │  │ PersistentVolume (Block Storage) │  │  │
│  │  └──────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│ Data Layer                                      │
│ ├─ Block Storage (EBS, Managed Disks)         │
│ ├─ File Storage (EFS, Azure Files)            │
│ └─ Secrets Vault (HashiCorp Vault, AWS SM)    │
├─────────────────────────────────────────────────┤
│ Observability Layer                             │
│ ├─ Metrics (Prometheus, cloud-native)          │
│ ├─ Logging (ELK, Datadog, Splunk)              │
│ └─ Tracing (Jaeger, cloud-native)              │
└─────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Key Terminology

#### Configuration vs. Secrets
- **Configuration**: Non-sensitive operational data (URLs, feature flags, numeric parameters). Typically changes between environments. Suitable for ConfigMaps.
- **Secrets**: Sensitive data that must be protected (passwords, API keys, certificates). Should never be logged or stored unencrypted. Requires enhanced security controls.

#### Volume vs. PersistentVolume vs. PersistentVolumeClaim
- **Volume**: Shared storage within a pod lifecycle. Tied to pod lifetime. Not portable across restarts.
- **PersistentVolume (PV)**: Cluster-level storage resource abstraction. Lifecycle independent of individual pods.
- **PersistentVolumeClaim (PVC)**: Storage request by an application. Claims storage from PV pool. Acts as pod-level storage descriptor.

#### Requests vs. Limits
- **Request**: Amount of resources guaranteed to be available to a pod. Used for scheduling decisions.
- **Limit**: Maximum resources a container can consume. Enforcement mechanism to prevent noisy neighbors.

#### QoS Classes
- **Guaranteed**: Request = Limit. Highest priority, least likely to be evicted.
- **Burstable**: Request < Limit. Medium priority; evicted if node underutilizes.
- **BestEffort**: No request/limit. Lowest priority; evicted first under pressure.

#### Probe Types
- **Liveness Probe**: Is the application still running? Restart if failing.
- **Readiness Probe**: Is the application ready to serve traffic? Remove from load balancing if failing.
- **Startup Probe**: Has the application finished starting? Gates liveness/readiness checks.

#### Health Check Mechanisms
- **HTTP**: GET request to specific endpoint. Most common for REST APIs.
- **TCP Socket**: TCP connection attempt to address:port. Suitable for connection-based services.
- **Exec**: Execute command in container. Exit code 0 = healthy. Overhead highest.
- **gRPC**: gRPC health check protocol. Emerging standard for microservices.

#### Observability Triad
- **Metrics**: Quantifiable measurements (CPU, memory, requests/sec). Time-series data.
- **Logs**: Discrete events and debug information. Unstructured/semi-structured text.
- **Traces**: Request flow across service boundaries. End-to-end causality.

### Architecture Fundamentals

#### Pod Lifecycle and Configuration Injection

When a pod is scheduled, configuration is injected through multiple mechanisms:

1. **Container image**: Baked-in defaults (rarely changed in production)
2. **ConfigMap**: Mounted as files or environment variables
3. **Secrets**: Mounted as volumes (tmpfs, not persisted) or environment variables
4. **Downward API**: Pod metadata (name, namespace, labels, annotations)
5. **Command arguments**: Pod spec override to container ENTRYPOINT
6. **Environment variables**: Direct injection or sourced from ConfigMaps/Secrets

Order of precedence:
```
Pod Spec Args > Environment Variables > Downward API > Defaults in Image
```

#### Storage Abstraction Layers

Kubernetes provides abstraction between application requirements and storage implementation:

```
Application (PVC)
    ↓
Storage Class (provisioning parameters)
    ↓ (dynamic provisioning)
PersistentVolume (cluster resource)
    ↓ (binding)
Backend Storage (EBS, NFS, local disk)
```

This abstraction enables:
- **Portability**: Same application works with EBS, NFS, or cloud storage
- **Automation**: Dynamic provisioning without manual infrastructure setup
- **Multi-tenancy**: Different storage tiers for different workload requirements
- **Cost optimization**: Storage classes can specify reclaim policy (delete/retain)

#### Resource Requests and Scheduling

The Kubernetes scheduler uses resource requests to make placement decisions:

```
Node Allocatable Resources = Total Node Capacity - Reserved (kubelet, system)
Available = Allocatable - (Sum of all Pod Requests in Node)

Pod is scheduled if: Pod Request ≤ Available for all resources
```

Example: 4-CPU node with 2 pods requesting 1.5 CPU each:
- Node Allocatable: 3.5 CPU (0.5 reserved for kubelet)
- Pod 1 & 2 requests: 3 CPU total
- Available: 0.5 CPU
- Third pod with 1 CPU request: CANNOT be scheduled (even if node currently using 0.5 CPU)

#### Liveness vs. Readiness vs. Startup Probes

Probes are evaluated independently on different timelines:

```
Pod Lifecycle:
[Created] → [Running] → [Serving Traffic] → [Terminating] → [Terminated]
    ↓           ↓             ↓                    ↓
  startup      liveness     readiness           (pre-stop hook)
  probe        probe        probe
```

- **Startup probe** (with failureThreshold=30, periodSeconds=10): First 5 minutes, gate all other probes. Purpose: Allow time for slow-starting containers (JVM, database migrations).
- **Liveness probe** (with failureThreshold=3): Continuously running. Detects deadlocks, infinite loops, stuck threads. Restart container if failing.
- **Readiness probe** (with failureThreshold=3): Continuously running. Detects transient issues (database connection timeout, cache miss storm). Remove from endpoints if failing.

#### Logging Architecture

Kubernetes logging operates at three levels:

1. **Container logs**: stdout/stderr captured by container runtime
2. **Pod logs**: `kubectl logs` retrieves from node kubelet
3. **Cluster logs**: Aggregated via sidecar or node-level log collector

Challenges:
- Container restart loses logs (by default)
- Multi-container pods require selecting specific container
- Node failure may lose logs
- Sidecar pattern adds resource overhead
- Log volume can exceed disk capacity if not managed

### Important DevOps Principles

#### Principle: Infrastructure as Code (IaC)
- All configuration (ConfigMaps, Secrets, PVCs, resource limits) should be version-controlled
- Use GitOps: Git as single source of truth, Flux/ArgoCD for synchronization
- ConfigMaps and Secrets committed to Git encrypted (Sealed Secrets, SOPS, or external vault reference)
- Enables disaster recovery, audit trail, code review for operational changes

#### Principle: Least Privilege
- Secrets should only be mounted where explicitly needed
- ServiceAccount permissions (RBAC) should be minimal
- Storage classes should enforce access controls
- Logging should not expose sensitive data (PII redaction)

#### Principle: Defense in Depth
- Multiple layers of failure detection (startup, liveness, readiness probes)
- Multiple layers of resource protection (requests, limits, node reservations)
- Multiple layers of storage safety (replication, snapshots, backups at storage layer)
- Multiple layers of observability (metrics, logs, traces)

#### Principle: Observability Over Monitoring
- **Monitoring**: Check if predefined metrics are within thresholds (reactive)
- **Observability**: Ask arbitrary questions about system state (reactive and proactive)

Kubernetes enables observability through:
- Rich pod metadata (labels, annotations, events)
- Structured logging (JSON logs, semantic fields)
- Metrics at pod, container, and resource level
- Events correlating configuration changes to failures

#### Principle: Resilience by Design
- Applications should be designed to handle configuration reloading
- Storage should be independent of pod lifecycle
- Resource allocation should account for node failures
- Probes should reflect actual application readiness, not just container startup

### Best Practices

#### ConfigMap/Secret Best Practices
1. **Separate concerns**: Use ConfigMaps for configuration, Secrets for sensitive data
2. **Environment-specific**: Use namespaces or separate kustomize bases per environment
3. **Version control secrets securely**: Use Sealed Secrets or external vault integration, never plaintext
4. **Update strategy**: Use ConfigMap watchers (kubewatch, Reloader) to reload apps on change, or use init containers
5. **Size limits**: ConfigMaps/Secrets max 1MB each; break large configs into multiple resources
6. **Immutable flag**: Set immutableData: true to prevent accidental changes in production

**Anti-pattern**: Storing secrets in ConfigMaps
**Anti-pattern**: Committing production secrets to Git in plaintext
**Anti-pattern**: Mounting all ConfigMaps/Secrets as environment variables (limited to 256 env vars per container)

#### Storage Best Practices
1. **Use PersistentVolumeClaims** for all data that must survive pod restarts
2. **Define storage classes** per data tier (NVMe for databases, standard for logs)
3. **Set reclaim policy**: Delete for ephemeral data, Retain for production data
4. **Snapshot strategy**: Regular snapshots for disaster recovery
5. **Capacity planning**: Monitor PVC usage; set up alerts for 80% capacity
6. **StatefulSet for stateful workloads**: Ensures stable pod identities and ordered deployments

**Anti-pattern**: Using local disk (/data) in containers expecting persistence
**Anti-pattern**: Sharing NFS with RWX access without application-level locking
**Anti-pattern**: Creating PVs manually for each pod instead of using StorageClasses

#### Resource Management Best Practices
1. **Set requests and limits for all containers**:
   - Requests: Based on typical usage (measure with Prometheus)
   - Limits: 1.2-1.5x of requests to allow for spikes, but prevent runaway processes
2. **Use HPA (Horizontal Pod Autoscaler)**: Scale pods based on CPU/memory usage
3. **Use VPA (Vertical Pod Autoscaler)**: Automatically tune requests/limits based on actual usage
4. **Set ResourceQuotas per namespace**: Prevent single team from consuming cluster
5. **Set NetworkPolicies**: Prevent unintended traffic patterns consuming bandwidth

**Anti-pattern**: No resource limits (OOMKilled pods, noisy neighbors)
**Anti-pattern**: Requests = Limits (cannot handle traffic spikes)
**Anti-pattern**: Request/Limit settings copied from documentation (unmeasured)

#### Healthcheck Best Practices
1. **Startup probe mandatory**: Always use for containers with slow startup
2. **Liveness probe should be narrow**: Check only if process crashed, not if slow
3. **Readiness probe should include dependencies**: Check database connectivity, cache readiness
4. **Initial delay**: Account for application startup time
5. **Timeout**: Set to application SLA (e.g., 2s for 5s endpoint SLA)
6. **Monitor probe metrics**: `kubernetes_api_prober_*` metrics for probe performance

**Anti-pattern**: Same probe logic for liveness and readiness
**Anti-pattern**: Probe timeout < 1 second (too aggressive for network latency)
**Anti-pattern**: No startup probe (readiness bounces during long startup)
**Anti-pattern**: Liveness probe hitting expensive endpoint (causes cascading failures)

#### Logging & Monitoring Best Practices
1. **Structured logging**: JSON logs with consistent field names (timestamp, level, service, traceID)
2. **Sidecar for log enrichment**: If applications can't produce structured logs natively
3. **Metrics naming**: Follow Prometheus conventions (snake_case, no underscores between parts)
4. **Custom metrics**: Add business-relevant metrics (orders/sec, payment success rate)
5. **Distributed tracing**: Propagate trace IDs across service boundaries
6. **Retention policies**: Different retention for different log levels/types

**Anti-pattern**: Logs without timestamps or service names
**Anti-pattern**: Logging secrets (PII/credentials)
**Anti-pattern**: High cardinality labels in metrics (unbounded growth)
**Anti-pattern**: Alerting only on infrastructure metrics, not business metrics

### Common Misunderstandings

#### Misunderstanding: "ConfigMaps are for configuration, Secrets are for data"
**Reality**: ConfigMaps are for non-sensitive data, Secrets are for sensitive data. Both can hold configuration or not. Example: A database username is configuration but sensitive (→ Secret), while a feature flag value is configuration and non-sensitive (→ ConfigMap).

#### Misunderstanding: "Limits should be as high as possible to avoid issues"
**Reality**: Limits should reflect application needs plus headroom for spikes. Very high limits prevent the scheduler from making intelligent packing decisions and consume excessive memory per pod. Defaults should fail closed (i.e., low limits that fail fast rather than high limits that fail slowly after consuming resources).

#### Misunderstanding: "Persistent storage means the data is safe"
**Reality**: PersistentVolumes are persistence mechanisms; they don't imply replication, backup, or encryption. You must separately implement: replication (RAID, cloud storage replication), backup (snapshots, point-in-time recovery), and encryption (at-rest and in-transit). A single EBS volume failure still causes data loss.

#### Misunderstanding: "If liveness probe succeeds, the pod is healthy"
**Reality**: Liveness probe only confirms the process is running. It doesn't confirm correctness, performance, or resource exhaustion. A pod with a successful liveness probe can still:
- Serve incorrect data
- Have deadlocked threads
- Be experiencing memory pressure
- Have network connectivity issues

Liveness and Readiness probes are independent signals.

#### Misunderstanding: "Logs and metrics serve the same purpose"
**Reality**: 
- Metrics are aggregated, queryable, time-series data. Good for trends and alerting.
- Logs are discrete events. Good for debugging and causality.
- Most issues require BOTH: metrics to detect the problem, logs to understand why.

Example: High latency (detected in metrics) caused by full disk (found in logs).

#### Misunderstanding: "ReplicaSets guarantee no data loss"
**Reality**: ReplicaSets provide availability (multiple copies), not durability guarantee for each replica's local storage. Example:
- StatefulSet with 3 Prometheus replicas, each with PersistentVolume
- If all 3 disks fail simultaneously (unlikely but possible), all data is lost
- Solution: Backup Prometheus data to S3 separately from Kubernetes

#### Misunderstanding: "My pod got OOMKilled, so memory limit is too low"
**Reality**: OOMKilled indicates:
1. Either memory limit is genuinely too low
2. OR application has memory leak/unbounded growth
3. OR cgroups memory accounting counted something unexpected

First step: Check if memory usage grows over time (leak) or constant (genuine need). Then decide between increasing limit or fixing application.

#### Misunderstanding: "Resource requests are optional if there's plenty of free capacity"
**Reality**: Requests are used for scheduling. Without requests:
- Scheduler packs pods too densely
- Node failure evicts all unrequested pods first (cascading blast radius)
- HPA can't make intelligent scaling decisions
- Cost prediction becomes impossible

Even if cluster has free capacity, setting requests is essential for resilience.

---

## ConfigMaps and Secrets

### Textual Deep Dive

#### Internal Working Mechanism

ConfigMaps and Secrets are fundamental Kubernetes API resources that store configuration and sensitive data separately from container images, enabling the Twelve-Factor App principle of configuration externalizing.

**Storage & Accessibility**:
- Stored in etcd cluster-wide (not namespace-isolated; accessible only via RBAC)
- Maximum size: 1MB per resource
- Accessed via:
  - Environment variables (templated into Pod spec)
  - Volume mounts (mounted as files in container filesystem)
  - Downward API (pod metadata)
  - Directly queried by applications (requires API access)

**Data Encoding**:
- **ConfigMaps**: Plain text (keys map to values, no encryption)
- **Secrets**: Base64-encoded by default (encryption optional via EncryptionConfiguration in API server)

**Lifecycle**:
1. Resource created in API server → stored in etcd
2. Kubelet watches ConfigMap/Secret resource
3. On pod scheduling, kubelet injects as environment variables or volumes
4. Changes to ConfigMaps/Secrets do NOT automatically reload in running containers
5. Pod must be restarted or sidecar must watch for changes

#### Architecture Role

ConfigMaps and Secrets act as the **configuration layer** between:
- **Upstream**: CI/CD pipeline, GitOps controller (Flux, ArgoCD)
- **Pod spec**: Deployment, StatefulSet, DaemonSet manifests
- **Container runtime**: Container sees injected values as environment or mounted files

Key architectural patterns:

```
[Git Repo]
    ↓
[GitOps Controller (Flux/ArgoCD)]
    ↓
[Kubernetes API Server]
    ├─ ConfigMap (dev-config, prod-config)
    ├─ Secret (db-credentials, api-keys)
    └─ etcd (persistent storage)
         ↓
[Kubelet]
    ├─ Watches ConfigMap/Secret resources
    ├─ Injects as env vars or volume mounts
    └─ Restarts pod on secret rotation (if using mounted volumes)
```

#### Production Usage Patterns

**Pattern 1: Environment-Specific Configuration**
```
Base image: app:v1.0 (contains no environment-specific config)
Deployments:
  ├─ dev/app-deployment.yaml (references dev-configmap, dev-secrets)
  ├─ staging/app-deployment.yaml (references staging-configmap, staging-secrets)
  └─ prod/app-deployment.yaml (references prod-configmap, prod-secrets)
```
Benefit: Single built image used everywhere; configuration drives behavior.

**Pattern 2: Secrets Rotation**
```
Database password changes in vault → external-secrets operator syncs to Kubernetes Secret
→ Application reload trigger (sidecar or operator) → New connections use new password
Old connections drain within connection timeout → Zero-downtime rotation
```

**Pattern 3: Feature Flags as ConfigMaps**
```
ConfigMap: feature-flags
  ├─ feature.new-ui: "true"
  ├─ feature.beta-api: "false"
  └─ feature.new-payment: "true"

Application watches ConfigMap → Applies flags without restart
Benefit: Canary deployments, A/B testing, runtime feature toggles
```

**Pattern 4: Multi-Tenant Configuration**
```
Namespaces: tenant-a, tenant-b, tenant-c (each isolated)
Each namespace has:
  ├─ ConfigMap (tenant-a-config, tenant-b-config)
  ├─ Secret (tenant-a-db-creds, tenant-b-db-creds)
  └─ Pods reference respective ConfigMap/Secret

Isolation is RBAC-enforced; incorrect RBAC allows cross-tenant access
```

#### DevOps Best Practices

1. **Secrets Management Strategy**
   - Never commit secrets to Git
   - Use external vault (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault)
   - Sync via operator (external-secrets-controller) or pipeline
   - Encrypt secrets at rest in etcd via EncryptionConfiguration
   - Enable audit logging for secret access
   - Rotate secrets regularly (weekly for credentials, immediately for compromised)

2. **ConfigMap Versioning**
   - Version ConfigMaps via naming (app-config-v1, app-config-v2) or via GitOps
   - Use immutableData: true in production to prevent accidental changes
   - Use kustomize or helm for environment-specific overlays
   - Version-control ConfigMaps; use Git as source of truth

3. **Reload Strategy**
   - Option A: Use sidecar pattern (Reloader) to watch ConfigMap and trigger reload
   - Option B: Use init containers to inject and application polls Kubernetes API
   - Option C: Rolling restart (kill pods to force re-injection) with zero-downtime using PodDisruptionBudgets
   - Option D: Stateless applications (restart is free)

4. **Security Hardening**
   - RBAC: Only services that need secrets get Secret read permissions
   - NetworkPolicy: Restrict etcd access to control plane nodes only
   - Pod Security Standards: Restrict privileged pods that could access etcd
   - Audit logging: Track all secret access attempts
   - Encryption: Enable Application-layer Encryption (KMS integration)

5. **Size Management**
   - Split large configs across multiple ConfigMaps (max 1MB)
   - Don't inject large ConfigMaps as environment variables (limit ~256 env vars, each ~131KB)
   - Use volume mounts for large configs
   - Monitor ConfigMap/Secret usage per namespace

#### Common Pitfalls

1. **Secrets in ConfigMaps**: ConfigMaps are not encrypted by default. A developer accidentally using ConfigMap for secrets exposes credentials.
   - Detection: Regular audits of ConfigMap contents
   - Prevention: Policy enforcement (OPA/Gatekeeper policy requiringSecretType for sensitive fields)

2. **Secrets in Environment Variables**: Services like datadog, honeycomb capture process environment; secrets become visible.
   - Solution: Mount secrets as volumes, read from file instead of env var
   - Environment variables also have container log exposure risk

3. **No Change Reload**: Updating a ConfigMap doesn't reload applications. Developers assume new config is live.
   - Solution: Implement ConfigMap watcher sidecar (Reloader) or use immutable config + GitOps-driven restarts

4. **Secret Drift**: Secrets updated manually (kubectl edit secret); Git doesn't reflect current state. Disaster recovery broken.
   - Solution: All secrets managed via external vault or GitOps with sealed-secrets

5. **Over-Mounting Secrets**: Mounting entire secret as volume exposes all keys. Application only needs subset.
   - Solution: Explicitly mount only needed keys into container or use init-container to extract

6. **No RBAC on Secrets**: Default RBAC allows anyone with pod creation to mount any secret.
   - Solution: Use NetworkPolicy + ServiceAccount RBAC to restrict secret access per pod

### Practical Code Examples

#### Example 1: ConfigMap for Database Connection (Non-Sensitive)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-database-config
  namespace: production
data:
  db.host: "postgres.production.svc.cluster.local"
  db.port: "5432"
  db.enableSslMode: "true"
  db.maxConnections: "100"
  db.connectionTimeout: "30s"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-api
  namespace: production
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
      containers:
      - name: api
        image: myregistry.azurecr.io/app-api:v1.2.3
        ports:
        - containerPort: 8080
          name: http
        # Method 1: Environment variables
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-database-config
              key: db.host
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: app-database-config
              key: db.port
        # Method 2: Volume mount (file-based)
        volumeMounts:
        - name: config-volume
          mountPath: /etc/app/config
          readOnly: true
      volumes:
      - name: config-volume
        configMap:
          name: app-database-config
          defaultMode: 0444
---
# Application reads file:
# For volume: cat /etc/app/config/db.host
# For env var: echo $DB_HOST
```

#### Example 2: Secret for Database Credentials (Sensitive)

```yaml
# Option A: Create secret from files (recommended for GitOps with external-secrets-operator)
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: production
type: Opaque  # or kubernetes.io/basic-auth
stringData:  # Automatically base64-encoded by Kubernetes
  username: "postgres-admin"
  password: "super-secret-password-${RANDOM}"  # Should come from vault, not literals
  connection-string: "postgresql://postgres-admin:super-secret-password@postgres.production.svc.cluster.local:5432/appdb"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-worker
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      serviceAccountName: app-worker  # For RBAC
      containers:
      - name: worker
        image: myregistry.azurecr.io/app-worker:v1.2.3
        env:
        # Best practice: Mount secret as file, read from file in application
        # Avoids exposing credentials in process environment
        - name: DB_CREDENTIALS_PATH
          value: "/run/secrets/db"
        volumeMounts:
        - name: db-secret-volume
          mountPath: /run/secrets/db
          readOnly: true
        - name: tmp-volume
          mountPath: /tmp
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
      volumes:
      - name: db-secret-volume
        secret:
          secretName: db-credentials
          defaultMode: 0400  # Read-only for owner
          items:  # Only mount needed keys
          - key: username
            path: username
          - key: password
            path: password
      - name: tmp-volume
        emptyDir: {}
---
# RBAC: Restrict secret access
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-worker
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-worker-secrets
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["db-credentials"]  # Only this secret
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-worker-secrets-binding
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: app-worker-secrets
subjects:
- kind: ServiceAccount
  name: app-worker
  namespace: production
```

#### Example 3: ConfigMap Reload with Sidecar (Reloader Pattern)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: feature-flags
  namespace: production
data:
  features.json: |
    {
      "new-ui": true,
      "beta-payment": false,
      "dark-mode": true
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: service
  template:
    metadata:
      labels:
        app: service
      annotations:
        # Reloader annotation: triggers pod restart on ConfigMap change
        config.reloader.stakater.com/match: "feature-flags"
    spec:
      containers:
      - name: app
        image: myregistry.azurecr.io/app-service:v1.2.3
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: features
          mountPath: /etc/app/features
          readOnly: true
        # Application reads /etc/app/features/features.json on startup
        # or periodically polls
      volumes:
      - name: features
        configMap:
          name: feature-flags
---
# Using external-secrets-operator for secret auto-rotation
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.company.com"
      path: "secret"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "app-role"
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-secret-rotation
  namespace: production
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: password
    remoteRef:
      key: database/prod-password
  - secretKey: username
    remoteRef:
      key: database/prod-username
  # Sync every 1 hour
  refreshInterval: 1h
```

#### Example 4: Shell Script for Secret Management

```bash
#!/bin/bash
# Manage secrets lifecycle: create, rotate, audit

NAMESPACE="production"
SECRET_NAME="db-credentials"
VAULT_ADDR="https://vault.company.com"
VAULT_TOKEN_PATH="/etc/vault/.token"

# Function: Rotate database password
rotate_db_password() {
  echo "[INFO] Starting DB password rotation..."
  
  # Get new password from vault
  VAULT_TOKEN=$(cat $VAULT_TOKEN_PATH)
  NEW_PASSWORD=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
    "$VAULT_ADDR/v1/secret/data/database/prod-password" | \
    jq -r '.data.data.password')
  
  # Verify connection with new password
  if ! psql -h $DB_HOST -U $DB_USER -c "SELECT 1" > /dev/null 2>&1; then
    echo "[ERROR] Cannot connect with new password"
    return 1
  fi
  
  # Update Kubernetes secret
  kubectl patch secret $SECRET_NAME -n $NAMESPACE -p \
    '{"stringData":{"password":"'$NEW_PASSWORD'"}}'
  
  echo "[INFO] Secret updated. Rolling out new pods..."
  
  # Rolling restart via annotation change (triggers pod recreation)
  kubectl patch deployment app-api -n $NAMESPACE -p \
    '{"spec":{"template":{"metadata":{"annotations":{"rotation-timestamp":"'$(date +%s)'"}}}}}}'
  
  echo "[INFO] Rotation complete"
}

# Function: Audit secret access
audit_secret_access() {
  echo "[INFO] Secret access in last 7 days:"
  
  kubectl get events -n $NAMESPACE \
    --field-selector involvedObject.kind=Secret \
    --field-selector involvedObject.name=$SECRET_NAME \
    -o jsonpath='{range .items[*]}{.lastTimestamp}{"\t"}{.reason}{"\t"}{.message}{"\n"}{end}'
}

# Function: Validate secret RBAC
validate_secret_rbac() {
  echo "[INFO] Validating RBAC for secret access:"
  
  # Check which service accounts can read this secret
  kubectl auth can-i get secret/$SECRET_NAME \
    --as=system:serviceaccount:$NAMESPACE:app-api \
    -n $NAMESPACE
  
  if [ $? -eq 0 ]; then
    echo "[OK] app-api ServiceAccount can read secret"
  else
    echo "[ERROR] app-api ServiceAccount cannot read secret"
  fi
}

# Main
case "${1:-help}" in
  rotate)
    rotate_db_password
    ;;
  audit)
    audit_secret_access
    ;;
  validate)
    validate_secret_rbac
    ;;
  *)
    echo "Usage: $0 {rotate|audit|validate}"
    ;;
esac
```

### ASCII Diagrams

#### Diagram 1: ConfigMap/Secret Injection Flow

```
[Source Control / Vault]
     ↓
[GitOps Controller (Flux/ArgoCD)]
     ↓
  [Apply to API Server]
     ├─ ConfigMap: db-config (plain text)
     ├─ Secret: db-creds (base64 encoded)
     └─ Deployment: app-api
     ↓
[Kubernetes API Server]
     ├─ Validate RBAC
     ├─ Store in etcd
     └─ Emit watch event: "ConfigMap/Secret created/updated"
     ↓
[Kubelet on Worker Node]
     ├─ Watch for ConfigMap/Secret changes
     ├─ Resolve values from API server
     ├─ Inject as:
     │   ├─ Environment variables (limited, logged)
     │   └─ Volume mounts (preferred, logs don't expose)
     └─ Trigger container start
     ↓
[Container Runtime]
     ├─ Receive ConfigMap/Secret as env vars or mounted files
     ├─ PID 1: Application process starts
     └─ Application reads config from:
         ├─ Environment (echo $DB_HOST)
         └─ Files (/etc/app/config/db.host)
```

#### Diagram 2: Secret Encryption at Rest in etcd

```
┌──────────────────────────────────┐
│ External Secret Store (AWS SM)   │
│  - Original: "password123"       │
└──────────────┬───────────────────┘
               ↓
      ┌────────────────────┐
      │ API Server         │
      │ (request create)   │
      └────────┬───────────┘
               ↓
      ┌────────────────────────────────────┐
      │ Encryption Plugin (KMS/AEAD)       │
      │ - Input: "password123"             │
      │ - Master Key: (in AWS HSM)         │
      │ - Output: encrypted_blob           │
      └────────┬───────────────────────────┘
               ↓
      ┌────────────────────────────────────┐
      │ etcd (Persistent Storage)          │
      │ Secret: {                          │
      │   encrypted_data: "7a3f9e2c..."  │
      │   iv: "abc123..."                │
      │ }                                  │
      └────────┬───────────────────────────┘
               ↓
      ┌────────────────────────────────────┐
      │ Read Request (pod needs secret)    │
      └────────┬───────────────────────────┘
               ↓
      ┌────────────────────────────────────┐
      │ Decryption Plugin (KMS/AEAD)       │
      │ - Input: encrypted_blob, iv        │
      │ - Master Key: (retrieved from HSM) │
      │ - Output: "password123"            │
      └────────┬───────────────────────────┘
               ↓
      ┌────────────────────────────────────┐
      │ API Server Response                │
      │ Returns plaintext to kubelet       │
      │ (over TLS)                         │
      └────────────────────────────────────┘
```

#### Diagram 3: ConfigMap Update and Reload Flow

```
Scenario: Feature flag toggle, no pod restart desired

[Developer]
  ↓
[Edit feature-flags ConfigMap in Git]
  ↓
[Commit & Push]
  ↓
[GitHub/GitLab Webhook]
  ↓
[Flux/ArgoCD Listener]
  ├─ Detect ConfigMap change
  ├─ Apply to Kubernetes API
  └─ ConfigMap updated in etcd
  ↓
[Kubelet watches ConfigMap resource]
  ├─ Detects update
  └─ Updates mounted volume files
  ↓
[Reloader Sidecar]
  ├─ inotify monitors /etc/app/features/ directory
  ├─ Detects file change
  └─ Sends SIGHUP to app process
  ↓
[Application Process]
  ├─ Catches SIGHUP signal
  ├─ Reloads config from /etc/app/features/features.json
  ├─ Updates in-memory feature flag map
  └─ Continues serving requests (zero-downtime)
  ↓
[New requests use updated flags]
```

## Storage Concepts

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes storage abstraction decouples applications from underlying storage infrastructure, enabling portability across cloud providers and on-premises environments. The abstraction consists of three layers:

**Layer 1: Storage Classes**
- Define provisioning parameters (storage type, IOPS, encryption, reclaim policy)
- Cluster admin creates per environment/tier
- References provisioner (aws-ebs, azure-disk, csi-nfs, etc.)
- Example: fast-nvme (SSD, 1000 IOPS) vs. standard-hdd (HDD, 100 IOPS)

**Layer 2: PersistentVolumeClaim (PVC)**
- Application's storage request ("I need 100GB of fast storage")
- Namespace-scoped; created by application
- Specifies: size, access mode (ReadWriteOnce, ReadOnlyMany, ReadWriteMany), storage class
- Remains even if pod is deleted

**Layer 3: PersistentVolume (PV)**
- Cluster-level storage resource
- Lifecycle independent of pods
- Provisioned either:
  - **Manually** (admin creates PV, app creates PVC, k8s binds them)
  - **Dynamically** (app creates PVC, provisioner auto-creates PV via StorageClass)

**Binding Mechanism**:
```
[PVC Request]
  ├─ Size: 100Gi
  ├─ Access Mode: RWO (ReadWriteOnce)
  └─ StorageClass: aws-ebs
       ↓
  [Scheduler/Provisioner]
  ├─ Find matching StorageClass
  ├─ Invoke provisioner (aws-ebs CSI driver)
  ├─ Create backend storage (EBS volume)
  ├─ Create PV object with backend reference
  └─ Bind PV ↔ PVC
       ↓
  [PV Status: Bound]
  [PVC Status: Bound]
       ↓
  [Pod spec references PVC by name]
  [Kubelet mounts PV at spec.volumes[*].mountPath]
       ↓
  [Container sees filesystem at /mnt/data (or specified path)]
```

**Access Modes**:
- **ReadWriteOnce (RWO)**: Single pod can read/write. Standard for databases.
- **ReadWriteMany (RWM)**: Multiple pods can read/write simultaneously. Requires NFS/SMB backend.
- **ReadOnlyMany (ROM)**: Multiple pods read, no write. Shared config/code distribution.

**Reclaim Policies**:
- **Delete**: PV deleted when PVC is deleted. Risk of data loss if accidental deletion.
- **Retain**: PV kept even after PVC deletion. Requires manual cleanup. Recommended for critical data.
- **Recycle**: Deprecated; replaced by dynamic provisioning.

#### StatefulSet Storage Pattern

StatefulSets enable stateful applications (databases, caches) by:
1. Assigning stable pod identities (pod-0, pod-1, pod-2)
2. Ordering deployment and scaling (maintain leadership)
3. Providing stable network names (postgres-0.postgres.prod, postgres-1.postgres.prod)
4. Allocating a unique PVC per pod replica

```
StatefulSet: postgres (replicas: 3)
├─ Pod: postgres-0 (node-1)
│  └─ PVC: postgres-0-data (100Gi) → PV: pv-001 → EBS vol-abc123
├─ Pod: postgres-1 (node-2)
│  └─ PVC: postgres-1-data (100Gi) → PV: pv-002 → EBS vol-xyz789
└─ Pod: postgres-2 (node-3)
   └─ PVC: postgres-2-data (100Gi) → PV: pv-003 → EBS vol-def456

Benefit: Each replica has independent storage; pod failure doesn't affect other replicas.
Risk: If pod-0 (primary) fails, operator must promote pod-1 or pod-2 to primary.
```

#### Dynamic Provisioning Flow

```
[Developer creates PVC]
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: app-data
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: "aws-ebs-gp3"  ← Critical: References StorageClass
    resources:
      requests:
        storage: 100Gi
      ↓
[Kubernetes PVC Controller]
  ├─ Query StorageClass: aws-ebs-gp3
  ├─ Extract provisioner: ebs.csi.aws.com
  ├─ Extract parameters: volumeType=gp3, iops=3000, throughput=125
  └─ Emit provision event
      ↓
[CSI Driver (ebs.csi.aws.com)]
  ├─ Receive provision request
  ├─ Call AWS API: CreateVolume
  │  └─ Create EBS volume (gp3, 100Gi, 3000 IOPS, 125 MB/s throughput)
  ├─ Tag volume with PVC name, namespace, cluster ID
  └─ Return volume-id: vol-0a1b2c3d4e5f6g7h
      ↓
[Kubernetes API Server]
  ├─ Create PV object:
  │  name: pvc-abc123
  │  ebs.volumeID: vol-0a1b2c3d4e5f6g7h
  │  capacity: 100Gi
  ├─ Bind PV ↔ PVC
  ├─ PVC status: Bound
  └─ PV status: Available
      ↓
[Pod Scheduler]
  ├─ Wait for PVC to be Bound
  ├─ Check pod node requirements
  ├─ Confirm EBS volume is in same AZ as pod node (EBS is zone-locked)
  └─ Schedule pod to node in correct AZ
      ↓
[Kubelet on pod's node]
  ├─ Attach EBS volume to EC2 instance
  │  └─ AWS API: AttachVolume (instanceId, volumeId)
  ├─ Wait for volume to appear as /dev/xvdd
  ├─ Mount volume: mount /dev/xvdd /var/lib/kubelet/pods/[pod-uid]/volumes/kubernetes.io~aws-ebs/...
  ├─ Pass mount path to container
  └─ Container sees filesystem at specified containerPath
      ↓
[Application]
  ├─ Reads/writes to /mnt/data (containerPath)
  └─ Data persists to EBS volume
```

#### Architecture Role

Storage is the **data persistence layer**:
- Without it: All pod data lost on restart (ephemerals only)
- With it: Data survives pod/node/AZ failures (within replication domain)

Storage workflow:
```
┌─────────────┐
│ Application |
└──────┬──────┘
       │
  [Storage Requests]
       │
       ├─ Ephemeral (emptyDir): Lost on pod restart
       ├─ ConfigMap/Secret volumes: Non-persistent config
       ├─ PVC (Bound to PV): Persistent across restarts
       └─ HostPath: Direct node filesystem (avoid!)
       │
       ↓
   [Data Tier]
       ├─ Block Storage (EBS, Managed Disks): Single-node R/W
       ├─ File Storage (EFS, Azure Files): Network file system, multi-node
       ├─ Object Storage (S3, Blob): Not directly mountable; requires sidecar
       └─ Database Services (RDS, Cosmos): Managed databases (outside k8s)
```

#### Production Usage Patterns

**Pattern 1: Per-Pod Persistent Storage (StatefulSet)**
```
PostgreSQL cluster (master-slave replication):
  postgres-master (pod-0) → PVC → EBS vol-master
  postgres-slave (pod-1) → PVC → EBS vol-slave
  postgres-slave (pod-2) → PVC → EBS vol-slave2

Each replica has independent storage; replication handled by PostgreSQL.
Node failure → Pod rescheduled to another node, mounts its original PVC.
Data not lost unless both pod and its attached storage fail simultaneously.
```

**Pattern 2: Shared Persistent Storage (NFS, Azure Files)**
```
Shared log directory (multiple pods writing logs):
  pod-api-0 → Writes to /logs → Mounted NFS share
  pod-api-1 → Writes to /logs → Mounted NFS share
  pod-worker-0 → Reads from /logs → Mounted NFS share

All pods see same filesystem; data shared.
Risk: Without application-level locking, concurrent writes cause data corruption.
Solution: Use log aggregation (sidecar pattern) instead of shared mounts when possible.
```

**Pattern 3: Backup & Disaster Recovery**
```
Production StatefulSet with Velero backup controller:
  ├─ Pod: app-0 → PVC: app-0-data → EBS: vol-001
  │            ↓
  │      [Velero] Snapshots EBS volume
  │       └─ Sends to S3 (cross-region)
  ├─ Pod: app-1 → PVC: app-1-data → EBS: vol-002
  │            ↓
  │      [Velero] Snapshots EBS volume
  │       └─ Sends to S3 (cross-region)
  └─ Pod: app-2 → PVC: app-2-data → EBS: vol-003
                 ↓
         [Velero] Snapshots EBS volume
          └─ Sends to S3 (cross-region)

Disaster scenario: Primary region lost → Restore from S3 snapshots to secondary region.
Data loss: Only data written between last snapshot and failure time.
RTO: Hours (snapshot recovery); RPO: Minutes (snapshot interval).
```

#### DevOps Best Practices

1. **StorageClass Design**
   - Create per data tier (fast-nvme, standard-ssd, archive-slowdisk)
   - Separate production and non-production classes
   - Set default StorageClass if most apps use same tier
   - Document provisioner capabilities (snapshots, encryption, cross-AZ replication)

2. **PVC Capacity Planning**
   - Request slightly more than peak usage (10-20% headroom)
   - Monitor PVC usage; alert at 70% capacity
   - Set ResourceQuota on storage per namespace to prevent runaway allocation
   - Use VolumeAttributesClass for fine-grained control

3. **Access Mode Selection**
   - RWO (default): Most reliable; all single-pod databases
   - RWM: Only if app explicitly handles concurrent writes (NFS-aware)
   - ROM: Documents intent (read-only sharing)
   - Validate provisioner supports chosen mode

4. **Data Protection**
   - Enable snapshots at storage class level
   - Automate daily backups via Velero or cloud provider backup
   - Store backups in separate region (disaster recovery)
   - Test restore procedure regularly (if untested, it doesn't work)
   - Encryption: Enable at-rest (native cloud provider) and in-transit (TLS)

5. **Lifecycle Management**
   - Set reclaim policy: Retain for production, Delete for dev/test
   - Document data retention requirements (regulatory, business)
   - Periodic audit of orphaned PVs (PVC deleted but PV retained)
   - Cost tracking: PVs are long-lived; monitor for unused capacity

6. **StatefulSet Operations**
   - OnDelete update strategy (manual rolling restart) for databases
   - Pod disruption budgets (minAvailable: 1) to prevent simultaneous restarts
   - Init containers for data initialization (schema migration)
   - Separate service for stable DNS names

#### Common Pitfalls

1. **Wrong Access Mode for Workload**: Requesting RWX for single-pod database, which allocates NFS (slower, less safe).
   - Solution: Use RWO; if sharing needed, use application-level replication

2. **Ephemeral Storage Assumption**: Developers assume /data directory persists; pod restart loses state.
   - Solution: Enforce policy requiring PVC for any needed persistence; provide emptyDir for scratch

3. **Cross-AZ PVC Attachment**: App pod scheduled to node in AZ-b; EBS volume in AZ-a (zone-affinity mismatch).
   - Solution: StorageClass with zoned topology; scheduler respects volume zones

4. **Manual PV Provisioning**: Admin creates 50 PVs manually; tracking becomes nightmare; binding unpredictable.
   - Solution: Use dynamic provisioning always; StorageClass automation

5. **RWX Overcrowding**: Multiple unrelated pods mounting same NFS share; no isolation, concurrent access issues.
   - Solution: One PVC per logical workload; NFS quotas per PVC

6. **Snapshot Restore Not Tested**: Backup exists; restore never practiced; failure time discovers restore broken.
   - Solution: Monthly disaster recovery drills; document RTO/RPO; practice step-by-step restore

7. **Capacity Exhaustion**: PVC reaches 100%; application hangs; no monitoring to catch at 80%.
   - Solution: ResourceQuota + monitoring + alerts at 70-80%

### Practical Code Examples

#### Example 1: StorageClass with EBS and Encryption

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-gp3-encrypted
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
  kmsKeyId: "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  tags: |
    ClusterName=production
    ManagedBy=Kubernetes
reclaimPolicy: Retain  # Critical for production: Don't auto-delete
volumeBindingMode: WaitForFirstConsumer  # Zone-aware binding
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
  namespace: databases
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-gp3-encrypted
  resources:
    requests:
      storage: 100Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-backup
  namespace: databases
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-gp3-encrypted
  resources:
    requests:
      storage: 200Gi
```

#### Example 2: StatefulSet with Persistent Storage (PostgreSQL)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: databases
spec:
  clusterIP: None  # Headless service for StatefulSet
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: databases
spec:
  serviceName: postgres  # Required for StatefulSet
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - postgres
            topologyKey: kubernetes.io/hostname  # Spread across nodes
      containers:
      - name: postgres
        image: postgres:14-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: backup
          mountPath: /var/lib/postgresql/backup
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 2000m
            memory: 4Gi
  # Persistent volumes for each replica
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: ebs-gp3-encrypted
      resources:
        requests:
          storage: 100Gi
  - metadata:
      name: backup
    spec:
      accessModes:
        - ReadWriteOnce
      storageClassName: ebs-gp3-encrypted
      resources:
        requests:
          storage: 200Gi
  podManagementPolicy: Parallel  # Scale faster (default: OrderedReady)
  updateStrategy:
    type: OnDelete  # Manual rolling restart for data safety
---
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: databases
type: Opaque
stringData:
  password: "super-secret-postgres-password"  # Should come from vault
```

#### Example 3: PVC Expansion and Monitoring

```bash
#!/bin/bash
# Monitor PVC usage and expand when approaching capacity

NAMESPACE="production"
THRESHOLD_PCT=80

# Function: Check PVC usage
check_pvc_usage() {
  local pvc_name=$1
  
  # Get PVC info
  echo "[INFO] Checking PVC: $pvc_name in namespace: $NAMESPACE"
  
  kubectl get pvc $pvc_name -n $NAMESPACE -o jsonpath='{.spec.resources.requests.storage}'
  
  # Find pod using this PVC
  local pod_name=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' --field-selector status.phase=Running)
  
  # Execute df command in pod
  local usage=$(kubectl exec -n $NAMESPACE $pod_name -- df -h /mnt/data | awk 'NR==2 {print $5}' | sed 's/%//')
  
  echo "[INFO] Current usage: ${usage}%"
  
  if [ $usage -gt $THRESHOLD_PCT ]; then
    echo "[WARN] PVC usage above ${THRESHOLD_PCT}% threshold. Expanding..."
    expand_pvc "$pvc_name"
  fi
}

# Function: Expand PVC
expand_pvc() {
  local pvc_name=$1
  local current_size=$(kubectl get pvc $pvc_name -n $NAMESPACE -o jsonpath='{.spec.resources.requests.storage}')
  local unit=${current_size: -2}  # Gi
  local size_num=${current_size%G*}  # 100
  local new_size=$((size_num * 15 / 10))${unit}  # 150Gi (1.5x)
  
  echo "[INFO] Expanding PVC from $current_size to $new_size"
  
  kubectl patch pvc $pvc_name -n $NAMESPACE -p '{"spec":{"resources":{"requests":{"storage":"'$new_size'"}}}}'
  
  if [ $? -eq 0 ]; then
    echo "[OK] PVC expanded successfully. StorageClass must have allowVolumeExpansion: true"
  else
    echo "[ERROR] Failed to expand PVC"
    return 1
  fi
}

# Function: List all PVCs and usage
list_pvc_usage() {
  echo "[INFO] Listing all PVCs in namespace: $NAMESPACE"
  
  kubectl get pvc -n $NAMESPACE -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.resources.requests.storage,STATUS:.status.phase,STORAGECLASS:.spec.storageClassName
}

# Main
case "${1:-help}" in
  check)
    check_pvc_usage "${2:-postgres-data}"
    ;;
  expand)
    expand_pvc "${2:-postgres-data}"
    ;;
  list)
    list_pvc_usage
    ;;
  *)
    echo "Usage: $0 {check|expand|list} [pvc-name]"
    ;;
esac
```

### ASCII Diagrams

#### Diagram 1: Dynamic Provisioning Flow with CSI Driver

```
[Developer Infrastructure as Code]
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: app-data
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: "ebs-gp3-encrypted"  ← Points to StorageClass
    resources:
      requests:
        storage: 100Gi
           ↓
   [Kubernetes API Server]
   ├─ Validates PVC spec
   ├─ Checks StorageClass: ebs-gp3-encrypted
   └─ Triggers provisioner: ebs.csi.aws.com
           ↓
   [CSI Driver Pod (ebs-csi-controller)]
   ├─ Receives CreateVolume RPC
   ├─ Parameters: type=gp3, iops=3000, encrypted=true
   └─ Calls AWS EC2 API: RunInstances → CreateVolume
           ↓
        [AWS EBS Service]
        ├─ Creates volume: vol-abc123 (100Gi, gp3, 3000 IOPS)
        ├─ Encrypts with KMS key
        ├─ Tags with: ClusterName=prod, ManagedBy=K8s, PVC=app-data
        └─ Returns volumeId: vol-abc123
           ↓
   [Kubernetes PV Controller]
   ├─ Creates PersistentVolume object
   │  spec.csi.volumeHandle: "vol-abc123"
   │  spec.capacity.storage: "100Gi"
   ├─ Sets status: Available
   └─ Binds PV ↔ PVC (PVC status: Bound)
           ↓
   [Pod Scheduler]
   ├─ Receives pod: app-deployment pod-xyz
   ├─ Pod requests PVC: app-data
   ├─ Scheduler checks PVC → PV → EBS volume AZ: us-east-1a
   ├─ Schedules pod to node in us-east-1a (same AZ)
   └─ Pod created on appropriate node
           ↓
   [Kubelet on Chosen Node]
   ├─ Watches for pod mount requirements
   ├─ Calls CSI Driver (ebs-csi-node)
   ├─ Command: NodePublishVolume(volumeId=vol-abc123, targetPath=/mnt/data)
   ├─ CSI Driver calls AWS API: AttachVolume(instanceId=i-xyz, volumeId=vol-abc123)
   ├─ Waits for device to appear: /dev/nvme1n1
   ├─ Potentially formats filesystem (first mount)
   ├─ Mounts: mount /dev/nvme1n1 /var/lib/kubelet/pods/[pod-uid]/volumes/kubernetes.io~aws-ebs/...
   └─ Container receives mount path: /mnt/data
           ↓
   [Container Process]
   └─ Application can read/write to /mnt/data → Persisted to EBS
```

#### Diagram 2: StatefulSet Pod-to-Storage Binding

```
StatefulSet: mysql (replicas: 3)

┌─────────────────────────────────────────────────────────────┐
│ Pod: mysql-0 (node-1, AZ: us-east-1a)                      │
│  ├─ PVC: mysql-0-data (requested)                          │
│  └─ PVC status: Bound to PV: pv-0001                       │
│      └─ EBS: vol-111 (us-east-1a, 100Gi, gp3)             │
├─────────────────────────────────────────────────────────────┤
│ Pod: mysql-1 (node-2, AZ: us-east-1b)                      │
│  ├─ PVC: mysql-1-data (requested)                          │
│  └─ PVC status: Bound to PV: pv-0002                       │
│      └─ EBS: vol-222 (us-east-1b, 100Gi, gp3)             │
├─────────────────────────────────────────────────────────────┤
│ Pod: mysql-2 (node-3, AZ: us-east-1c)                      │
│  ├─ PVC: mysql-2-data (requested)                          │
│  └─ PVC status: Bound to PV: pv-0003                       │
│      └─ EBS: vol-333 (us-east-1c, 100Gi, gp3)             │
└─────────────────────────────────────────────────────────────┘

Key Points:
- Each pod has UNIQUE PVC and PV (stable identity)
- PVC names follow pattern: {statefulset-name}-{volume-name}-{ordinal}
- Storage is zone-affine (pod and EBS in same AZ)
- Pod restart: Kubelet remounts same EBS volume → Data not lost
- Pod migration to different node: Same zone required; volume reattached
- Storage persists even after pod deletion (unless reclaim=Delete)
```

#### Diagram 3: Backup & Disaster Recovery with Velero

```
Production Cluster: us-east-1

[Pods with PVCs]
  ├─ app-0 → mysql-0-data (100Gi) → EBS: vol-101
  ├─ app-1 → mysql-1-data (100Gi) → EBS: vol-102
  └─ app-2 → mysql-2-data (100Gi) → EBS: vol-103
       ↓ [Velero Backup Controller (runs every 24h)]
       ├─ Snapshot each EBS volume
       │  ├─ Snapshot: snap-001 (vol-101)
       │  ├─ Snapshot: snap-002 (vol-102)
       │  └─ Snapshot: snap-003 (vol-103)
       ├─ Upload snapshots to S3: s3://backups/production/2026-03-11/
       ├─ Store Kubernetes manifest snapshot (all CRDs, ConfigMaps, Secrets)
       └─ Velero backup: "production-2026-03-11-daily" (COMPLETE)
       ↓
[Cross-Region Storage]
  S3 Bucket: s3://backups/production/
            ├─ 2026-03-11/
            │  ├─ snapshots/ (snap-001, snap-002, snap-003)
            │  ├─ manifests/ (all K8s objects)
            │  └─ metadata.json
            └─ 2026-03-10/
               └─ ...
       ↓ [Disaster: Primary AZ us-east-1 fails]
       ├─ All pods lost
       ├─ All EBS volumes lost
       └─ Application zero availability
       ↓
[Recover to Secondary Cluster: us-west-2]

[Velero Restore Controller]
  ├─ List backups: "production-2026-03-11-daily"
  ├─ Fetch from S3: snapshots and manifests
  ├─ Restore EBS snapshots to new region
  │  ├─ Snapshot: snap-001 → New EBS: vol-201 (us-west-2a)
  │  ├─ Snapshot: snap-002 → New EBS: vol-202 (us-west-2b)
  │  └─ Snapshot: snap-003 → New EBS: vol-203 (us-west-2c)
  ├─ Create PVs referencing new EBS volumes
  ├─ Restore K8s manifests (Deployments, StatefulSets, Services)
  ├─ Update PVC references to new PVs
  └─ Recreate all pods
       ↓
[Restored Cluster in us-west-2]
  ├─ app-0 (recreated) → mysql-0-data → EBS: vol-201 (data from snapshot)
  ├─ app-1 (recreated) → mysql-1-data → EBS: vol-202 (data from snapshot)
  └─ app-2 (recreated) → mysql-2-data → EBS: vol-203 (data from snapshot)

RTO: ~1 hour (snapshot restore + pod creation)
RPO: 24 hours (last backup) - data loss: <= 24h of writes
Solution: More frequent backups (hourly) reduces RPO; increases cost
```

## Resource Management

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes resource management operates at multiple levels with distinct purposes:

**Level 1: Pod Requests (Scheduling)**
- Used by scheduler to determine if pod fits on node
- Formula: Pod scheduled if requested resource ≤ (Node allocatable - Sum of other pods' requests)
- Node allocatable = Total capacity - Reserved (kubelet, system daemons)
- **Critical**: Requests don't limit actual usage; they determine placement

Example: Node with 4 CPU, kubelet reserves 0.5 CPU:
```
Node Allocatable: 3.5 CPU
Pods already scheduled: pod-a (request 1 CPU), pod-b (request 1.5 CPU)
Used requests: 2.5 CPU
Available for new pods: 1 CPU

New pod asking for 1.2 CPU: CANNOT be scheduled (even if node currently using only 0.5 CPU total)
New pod asking for 0.8 CPU: CAN be scheduled

Actual usage doesn't affect scheduling; requests do.
```

**Level 2: Pod Limits (Enforcement)**
- Hard boundaries; container killed if exceeded (OOMKilled for memory, CPU throttled)
- Enforced by cgroup (cgroupsv2 preferred for more granular control)
- Memory limit: cgroup kills process if usage exceeds limit
- CPU limit: cgroup throttles (slows down) process if usage exceeds limit

```
Container: cpu=2000m, memory=2Gi (limits)
cgroup-v2: memory.max = 2147483648 bytes (2Gi)
cgroup-v2: cpu.max = 200000 microseconds (2 CPU)

Scenario: App allocates 2.5Gi memory
  ├─ kernel tries to allocate 2.5Gi
  ├─ cgroup.memory.max = 2Gi
  ├─ Can't allocate more; cgroup triggers OOMKiller
  ├─ Selects process with highest memory usage (PID 1 = app)
  ├─ Kills process: SIGKILL
  └─ Container exits with code 137 (128 + 9 SIGKILL)
       ↓ Pod disruption
       ├─ Kubelet detects container exit
       ├─ Restarts container (restart policy = Always)
       └─ CrashLoopBackOff after repeated failures
```

**Level 3: QoS Classes (Eviction Priority)**
- Determines which pods are evicted first when node memory pressure
- Assigned automatically based on requests/limits relationship
  - **Guaranteed**: request == limit (for all containers)
  - **Burstable**: request < limit (can burst above request)
  - **BestEffort**: no request/limit (scavenges unused node resources)

Eviction order under memory pressure:
```
1. BestEffort pods:     Guaranteed=false, Burstable=false → Evicted first
2. Burstable pods:      Guaranteed=false, Burstable=true  → Evicted second
                        (within this class, evict pods exceeding request)
3. Guaranteed pods:     Guaranteed=true                   → Evicted last
                        (only if system critically low)

Scenario: Node has 2Gi memory, pod memory usage:
  - pod-a (Guaranteed): request=2Gi, limit=2Gi      → Usage 2Gi
  - pod-b (Burstable):  request=500M, limit=2Gi     → Usage 1.5Gi
  - pod-c (BestEffort): request=none, limit=none    → Usage 500Mi
  ├─ Total usage: 4Gi (overcommitted)
  ├─ Node memory pressure triggered
  ├─ Eviction order: pod-c (BestEffort) → pod-b (Burstable) → pod-a (Guaranteed)
  ├─ pod-c evicted → frees 500Mi
  ├─ If still pressure, pod-b evicted → frees 1.5Gi
  └─ pod-a remains (highest priority)
```

**Level 4: ResourceQuota (Namespace Limits)**
- Cluster admin sets maximum resource consumption per namespace
- Prevents single team from monopolizing cluster

```
ResourceQuota: team-a-quota
  ├─ requests.cpu: 10
  ├─ requests.memory: 20Gi
  ├─ limits.cpu: 40
  ├─ limits.memory: 80Gi
  └─ pods: 100

Namespace: team-a
  ├─ Pod 1: request 2 CPU, 4Gi memory → counts against quota
  ├─ Pod 2: request 2 CPU, 4Gi memory → counts against quota
  ├─ ...
  ├─ Pod N: request 2 CPU, 2Gi memory → total requests: 10 CPU, 20Gi
  └─ Pod N+1: request 2 CPU → FORBIDDEN (would exceed quota)
```

**Level 5: HPA / VPA (Dynamic Scaling)**
- **HPA (Horizontal Pod Autoscaler)**: Adjusts replica count based on metrics
  ```
  target: average CPU usage across pods = 70%
  current: average CPU usage = 85%
  → Scale replicas: 5 → 7 (add 2 pods)
  ```
- **VPA (Vertical Pod Autoscaler)**: Adjusts request/limit per pod
  ```
  Pod history: CPU usage varies 200m → 800m
  VPA recommendation: request = 800m (95th percentile)
  Current request: 500m → Apply recommendation → New request: 800m
  Result: Pod restart with new resources
  ```

#### Architecture Role

Resource management sits at the intersection of:
- **Cluster capacity**: Total hardware resources available
- **Application demands**: Container resource needs
- **Fairness/isolation**: Multiple tenants / workloads sharing cluster

Architecture:
```
[Cluster]
  ├─ Total Capacity: 16 CPU, 64Gi memory (across all nodes)
  ├─ Reserved (kubelet + system): 2 CPU, 8Gi
  └─ Allocatable for pods: 14 CPU, 56Gi
         ↓
  [ResourceQuota]
    ├─ Namespace team-a: max 5 CPU, 20Gi (guarantees others get share)
    ├─ Namespace team-b: max 5 CPU, 20Gi
    ├─ Namespace team-c: max 4 CPU, 16Gi
    └─ Total: 14 CPU, 56Gi (fills allocatable)
         ↓
  [Pods in each namespace]
    ├─ Set requests based on typical usage (measured from metrics)
    ├─ Set limits for burst capacity
    ├─ Scheduler uses requests for placement
    ├─ Kubelet enforces limits at runtime
    └─ HPA/VPA adjust based on actual metrics
```

#### Production Usage Patterns

**Pattern 1: Predictable Workload (Web API)**
```
Deploy web API expected to use 500m CPU, 512Mi memory steady-state
With 20% burst capacity for traffic spikes

Requests: cpu=500m, memory=512Mi    (allocate steady-state need)
Limits:   cpu=600m, memory=614Mi    (1.2x for spikes)
QoS class: Burstable (request < limit)

HPA: target CPU usage 70%
  ├─ If usage > 70%, add replicas
  ├─ If usage < 30%, remove replicas
  └─ Scales horizontally to maintain target utilization

Result: Cluster packs replicas tightly; automatic scale-out prevents starvation
```

**Pattern 2: Variable/Batch Workload (Spark Job)**
```
Spark job needs 8 CPU, 32Gi for batch processing (irregular)
Should not starve other pods when idle

Requests: cpu=1, memory=4Gi      (minimal resource guarantee)
Limits:   cpu=8, memory=32Gi     (max the job can use)
QoS class: Burstable
Priority:  low (non-critical job)

Behavior:
  ├─ Scheduler finds node with 1 CPU available (easy to fit)
  ├─ Job runs; receives 8 CPU + 32Gi available
  ├─ If node under memory pressure, this pod evicted first (low priority)
  └─ Other pods remain (higher priority)

Alternative: PriorityClass = batch-priority (lower than web-api)
  └─ Ensures API pods never evicted for batch jobs
```

**Pattern 3: System Pod (Monitoring, Networking)**
```
Dnsmasq pod (DNS caching) must run on every node
DaemonSet with resource requirements:

Requests: cpu=100m, memory=128Mi
Limits:   cpu=200m, memory=256Mi
QoS class: Burstable
Pod Priority: system-cluster-critical

Behavior:
  ├─ Launched on all nodes (even overcommitted ones)
  ├─ Critical pod class prevents eviction
  ├─ Guaranteed to always be running (DNS must work)
  └─ Small resource footprint (doesn't monopolize node)
```

#### DevOps Best Practices

1. **Measure Before Setting Requests/Limits**
   - Deploy without resources; run under realistic traffic
   - Collect metrics (Prometheus) for 1+ week
   - Calculate: p50, p95, p99 CPU/memory usage
   - Set request = p95 (95th percentile)
   - Set limit = p99 + headroom (10-20%)
   - This prevents both starvation (too-low request) and OOMKill (too-low limit)

2. **Use ResourceQuota per Namespace**
   - Prevents runaway pods from consuming cluster
   - Forces teams to be intentional about resource allocation
   - Monitor ResourceQuota usage; alert at 80%
   - Periodically review and adjust quotas based on actual usage

3. **HPA Configuration**
   - Use CPU for predictable workloads
   - Use custom metrics (business logic) for better control
   - Set reasonable scale-up/scale-down rates
   - Scale up fast (e.g., 2 replicas per minute); scale down slow (1 replica per 5 minutes) to avoid flapping
   - Set min/max replicas conservatively

4. **QoS Class Discipline**
   - Guaranteed (request == limit): Critical databases, APIs
   - Burstable (request < limit): Web services, API gateways
   - BestEffort: Batch jobs, CI runners (non-critical)
   - Never mix on same node if possible (use node affinity)

5. **Overcommitment Policy**
   - Conservative: Sum of requests ≤ 0.7 * allocatable (20-30% headroom)
   - Moderate: Sum of requests ≤ 0.85 * allocatable (15% headroom)
   - Aggressive: Sum of requests ≤ 1.0 * allocatable (risky; no headroom)
   - Choose based on risk tolerance and workload variance

6. **Monitoring Resource Usage**
   - Metrics: `container_cpu_usage`, `container_memory_usage_bytes`
   - Alerts: "Pod CPU request/limit mismatch", "Pod OOMKilled", "Node memory under pressure"
   - Dashboard: Actual vs. requested per namespace, per pod
   - Quarterly review: Adjust requests/limits based on trends

#### Common Pitfalls

1. **Limits Too High (Container Bloat)**
   - Set limit=10 CPU when app never exceeds 2 CPU
   - Result: Scheduler can't pack pods densely; cluster underutilized
   - Fix: Measure actual usage; set limit = p99 + 10%

2. **No Requests (Scheduling Failure)**
   - Pod spec: no requests, limits=2 CPU
   - Scheduler treats as request=0
   - Result: Over-schedules node → All pods starve; system thrashing
   - Fix: Always set requests

3. **Request > Limit (Invalid)**
   - Kubernetes validates at admission; rejects pod
   - Some admission controllers miss this; deployment fails later
   - Fix: Use ValidatingWebhookConfiguration to catch

4. **Not Using ResourceQuota (Noisy Neighbors)**
   - Team A launches resource-intensive job
   - Consumes 80% of cluster
   - Team B's pods can't schedule
   - Fix: ResourceQuota per namespace enforces fairness

5. **HPA Thrashing (Flapping)**
   - Pod slightly above target CPU → Scale up
   - New pods added → CPU drops below target → Scale down
   - New scale down → CPU climbs → Scale up again
   - Result: Pods constantly restarted (connection loss)
   - Fix: Set stabilization window (scale down only after 5+ minutes below target)

6. **OOMKilled but Limit is High**
   - Container limit=4Gi; pod killed at 3.5Gi usage
   - Reason: Memory fragmentation, page cache pressure, swap (if enabled)
   - Diagnostic: `kubectl describe pod` → check actual memory at kill time
   - Fix: Either increase limit or debug memory leak in application

### Practical Code Examples

#### Example 1: Deployment with Resource Requests/Limits and HPA

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
  namespace: production
spec:
  replicas: 3  # Initial replicas; HPA will adjust
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      # Pod Priority for eviction order
      priorityClassName: high-priority
      
      # Disruption budget: maintain minimum 2 pods during voluntary disruptions
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
        image: myregistry.azurecr.io/api-server:v1.5.0
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
        
        # Resource requests: guarantee available resources
        resources:
          requests:
            cpu: 500m           # Based on p95 measurement
            memory: 512Mi       # Based on p95 measurement
          limits:
            cpu: 1000m          # 2x request; allow bursting
            memory: 768Mi       # 1.5x request; prevent OOMKill
        
        # Liveness: Is the process still alive?
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Readiness: Can it serve traffic?
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 2
          failureThreshold: 2
        
        env:
        - name: SERVER_PORT
          value: "8080"
        - name: METRICS_PORT
          value: "9090"
        - name: LOG_LEVEL
          value: "info"
        
        volumeMounts:
        - name: config
          mountPath: /etc/api/config
          readOnly: true
      
      volumes:
      - name: config
        configMap:
          name: api-config
      
      terminationGracePeriodSeconds: 30  # Time for graceful shutdown
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-server-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 3
  maxReplicas: 30
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Target 70% CPU utilization
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Target 80% memory utilization
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
      - type: Percent
        value: 100            # Double replicas
        periodSeconds: 15
      - type: Pods
        value: 4              # Or add 4 pods
        periodSeconds: 15
      selectPolicy: Max       # Apply whichever adds more pods
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 minutes before scaling down
      policies:
      - type: Percent
        value: 50             # Keep at least 50% of current
        periodSeconds: 60
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-server-pdb
  namespace: production
spec:
  minAvailable: 2  # Always keep at least 2 pods available
  selector:
    matchLabels:
      app: api
---
apiVersion: v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000
globalDefault: false
description: "High priority for critical API services"
```

#### Example 2: ResourceQuota and NetworkPolicy for Namespace Isolation

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
  labels:
    team: a
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-a-quota
  namespace: team-a
spec:
  hard:
    requests.cpu: "10"          # Max 10 CPU requests
    limits.cpu: "40"           # Max 40 CPU limits
    requests.memory: "20Gi"    # Max 20Gi memory requests
    limits.memory: "80Gi"      # Max 80Gi memory limits
    pods: "100"                # Max 100 pods
    services.nodeports: "2"    # Max 2 NodePort services
    persistentvolumeclaims: "10"  # Max 10 PVCs
  scopeSelector:
    matchExpressions:
    - operator: In
      scopeName: PriorityClass
      values: ["high-priority", "normal-priority"]
---
apiVersion: v1
kind: LimitRange
metadata:
  name: team-a-limits
  namespace: team-a
spec:
  limits:
  - type: Container
    min:
      cpu: "50m"
      memory: "64Mi"
    max:
      cpu: "4000m"
      memory: "8Gi"
    default:        # Default limits if not specified
      cpu: "1000m"
      memory: "1Gi"
    defaultRequest: # Default requests if not specified
      cpu: "500m"
      memory: "512Mi"
    ratio:          # Max limit/request ratio
      cpu: "2"
      memory: "2"
  - type: Pod
    min:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "8000m"
      memory: "16Gi"
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: team-a-isolation
  namespace: team-a
spec:
  podSelector: {}  # Applies to all pods in namespace
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: team-a  # Only pods from team-a namespace
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: team-a
    ports:
    - protocol: TCP
      port: 8080
  - to:  # Allow DNS egress (to kube-system)
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53  # DNS
```

#### Example 3: Shell Script for Resource Monitoring

```bash
#!/bin/bash
# Monitor resource usage and recommend adjustments

NAMESPACE="production"
DAYS=7

# Function: Get resource usage statistics from Prometheus
get_resource_stats() {
  local pod_label=$1
  
  echo "\n[INFO] Computing resource statistics for label: $pod_label"
  echo "[INFO] Period: Last $DAYS days"
  echo ""
  
  # CPU p95
  local cpu_p95=$(curl -s 'http://prometheus:9090/api/v1/query' \
    --data-urlencode 'query=histogram_quantile(0.95, rate(container_cpu_usage_seconds_total{pod_regex="'$pod_label'"}[5m]))' | \
    jq '.data.result[0].value[1]')
  
  # Memory p95
  local mem_p95=$(curl -s 'http://prometheus:9090/api/v1/query' \
    --data-urlencode 'query=histogram_quantile(0.95, container_memory_usage_bytes{pod=~"'$pod_label'"})[1d:1h]' | \
    jq '.data.result[0].value[1]' | awk '{print int($1/1024/1024)}')
  
  echo "CPU p95 usage:     $(echo "$cpu_p95" | awk '{printf "%.1f", $1}')m"
  echo "Memory p95 usage:  ${mem_p95}Mi"
  echo ""
  echo "[RECOMMENDATION]"
  echo "  request.cpu:     $(echo "$cpu_p95" | awk '{printf "%.0f", $1}')m"
  echo "  limit.cpu:       $(echo "$cpu_p95" | awk '{printf "%.0f", $1 * 1.2}')m"
  echo "  request.memory:  $((mem_p95))Mi"
  echo "  limit.memory:    $((mem_p95 * 3 / 2))Mi"
}

# Function: Check ResourceQuota usage
check_quota() {
  echo "\n[INFO] ResourceQuota status for namespace: $NAMESPACE"
  
  kubectl describe resourcequota -n $NAMESPACE | \
    grep -E "Name:|cpu|memory|pods|Limit|Used" | \
    awk '/Name:/{name=$2} {print }'
}

# Function: List pods exceeding requests
check_overcommitted_pods() {
  echo "\n[INFO] Pods with high actual vs. requested ratio"
  
  kubectl top pods -n $NAMESPACE --no-headers | awk '
    NR>1 {
      cpu=$2; mem=$3
      # Request values (would need to fetch from pod spec; simplified here)
      print $1, "CPU: " cpu "m, Memory: " mem "Mi"
    }
  ' | sort -k3 -nr | head -10
}

# Function: Check HPA status
check_hpa_status() {
  echo "\n[INFO] Horizontal Pod Autoscaler status"
  
  kubectl get hpa -n $NAMESPACE -o custom-columns=NAME:.metadata.name,REFERENCE:.spec.scaleTargetRef.name,TARGETS:.status.currentMetrics[0].resource.current.averageUtilization,MINPODS:.spec.minReplicas,MAXPODS:.spec.maxReplicas,REPLICAS:.status.currentReplicas
}

# Main
case "${1:-help}" in
  stats)
    get_resource_stats "${2:-api.*}"
    ;;
  quota)
    check_quota
    ;;
  pods)
    check_overcommitted_pods
    ;;
  hpa)
    check_hpa_status
    ;;
  all)
    check_quota
    check_hpa_status
    check_overcommitted_pods
    ;;
  *)
    echo "Usage: $0 {stats [pod_regex]|quota|pods|hpa|all}"
    echo "Example: $0 stats 'api-server.*'"
    ;;
esac
```

### ASCII Diagrams

#### Diagram 1: Scheduling Decision with Resource Requests

```
[Pod Spec]
  requests:
    cpu: 500m
    memory: 512Mi
  limits:
    cpu: 1000m
    memory: 1Gi
       ↓
[Scheduler Evaluation]
  For each node:
    Available = (Node Allocatable) - (Sum of pod requests already scheduled)
    
    Node-1: 4 CPU, 8Gi memory
      ├─ Allocatable: 3.5 CPU, 7Gi memory (0.5 CPU reserved)
      ├─ Current pods request: 2 CPU, 4Gi memory
      ├─ Available: 1.5 CPU, 3Gi memory
      ├─ Pod request: 500m CPU, 512Mi memory
      ├─ Fits? 500m ≤ 1.5 CPU ✓, 512Mi ≤ 3Gi ✓
      └─ Node-1: CANDIDATE
    
    Node-2: 2 CPU, 4Gi memory
      ├─ Allocatable: 1.5 CPU, 3.5Gi memory (0.5 CPU reserved)
      ├─ Current pods request: 1.2 CPU, 3Gi memory
      ├─ Available: 0.3 CPU, 0.5Gi memory
      ├─ Pod request: 500m CPU, 512Mi memory
      ├─ Fits? 500m ≤ 0.3 CPU ✗
      └─ Node-2: REJECTED (not enough CPU request guarantee)
    
    Node-3: 8 CPU, 16Gi memory
      ├─ Allocatable: 7.5 CPU, 15Gi memory
      ├─ Current pods request: 3 CPU, 5Gi memory
      ├─ Available: 4.5 CPU, 10Gi memory
      ├─ Pod request: 500m CPU, 512Mi memory
      ├─ Fits? 500m ≤ 4.5 CPU ✓, 512Mi ≤ 10Gi ✓
      └─ Node-3: CANDIDATE
    
    [Scoring]
    Prefer dense packing (less fragmentation) and node affinity
    Node-1 score: 100 (tight fit, less wasted)
    Node-3 score: 50  (lots of free space)
    
    [Decision]
    Schedule to Node-1
       ↓
[Actual Runtime on Node-1]
  Pod starts; kernel requests 512Mi memory
  Memory allocation succeeds (available on node)
  Pod running; CPU usage = 350m (actual)
  
  Note: Actual CPU usage (350m) < Requested (500m)
  Scheduler made placement decision based on request (500m)
  Actual usage doesn't matter for scheduling
```

#### Diagram 2: Container Limit Enforcement (cgroup)

```
[Container Lifecycle]
  spec.resources.limits.memory: 1Gi
       ↓ [Kubelet configures cgroup]
  cgroup v2: memory.max = 1073741824 bytes (1Gi)
       ↓
[Process Running in Container]
  malloc(500Mi) → kernel allocates → cgroup checks: 500Mi < 1Gi → OK
  malloc(300Mi) → kernel allocates → cgroup checks: 800Mi < 1Gi → OK
  malloc(200Mi) → kernel allocates → cgroup checks: 1Gi < 1Gi → LIMIT REACHED
  malloc(100Mi) → kernel tries → cgroup blocks → Out of memory
       ↓
[Kernel OOMKiller]
  ├─ Triggers: memory.oom.group
  ├─ Selects process: PID 1 (container's main process)
  ├─ Action: SIGKILL
  └─ Process dies immediately
       ↓
[Container Runtime (containerd)]
  ├─ Detects process death
  ├─ Exit status: 137 (128 + 9 SIGKILL)
  └─ Logs: "OOMKilled"
       ↓
[Kubelet]
  ├─ Detects container exit
  ├─ Checks pod restart policy: Always
  ├─ Waits backoff delay (1s, 2s, 4s, 8s, 10s, 10s)
  ├─ Restarts container
  └─ Pod enters CrashLoopBackOff after N restarts
       ↓
[Monitoring]
  Alert: "Pod pod-xyz OOMKilled 5 times in 10 minutes"
  → Investigate memory leak or increase limit
```

#### Diagram 3: HPA Scaling Decision Flow

```
[Application Metrics]
  Time T0: 5 pods, avg CPU 65%
  Time T0+1min: 5 pods, avg CPU 75% (↑10%)
  Time T0+2min: 5 pods, avg CPU 82% (↑7%)
  Time T0+3min: 5 pods, avg CPU 85% (↑3%) → Exceeds target (70%)
       ↓
[HPA Controller (evaluates every 15s)]
  Current replicas: 5
  Desired replicas = ceil(current * (current_metric / target_metric))
                   = ceil(5 * (85/70))
                   = ceil(5 * 1.21)
                   = ceil(6.07)
                   = 7 replicas
       ↓
  Scale-up policy check:
    ├─ Percent: 100% of current = 5 pods; can add up to 5
    ├─ Pods: 4 pods per 15s; can add 4 pods
    ├─ Max: min(7, 30) = 7
    └─ Take max of policies: 7 desired
       ↓
[Kubelet Scale Action]
  New replicas: 7 (add 2 pods)
  Create pods: pod-X-6, pod-X-7
  Scheduler finds nodes with available resources
  Pods start; request 500m CPU each
       ↓
[After 2 minutes: New Metrics]
  Time T0+5min: 7 pods, avg CPU 60% (↓25%)
  Below target (70%); stabilization window: 300s (5 min)
  HPA waits until 5 minutes of consistently low usage
  Time T0+10min: still avg CPU 58%
       ↓
  Desired replicas = ceil(7 * (58/70))
                  = ceil(7 * 0.829)
                  = ceil(5.8)
                  = 6 replicas
       ↓
  Scale-down policy check (from 7 to 6):
    ├─ Percent: 50% of current = 3.5; must keep 3.5
    ├─ Can remove: 7 - ceil(3.5) = 4 pods
    ├─ Pods: 1 per 60s; can remove 1 pod
    └─ Take min of policies (conservative): remove 1 pod
       ↓
[Final Decision]
  Scale down: 7 → 6 replicas
  Evict pod: pod-X-7
  Reduced CPU usage; maintained minimum performance
```

## Healthchecks & Probes

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes provides three independent probe mechanisms that run continuously throughout a pod's lifecycle:

**Startup Probe** (executes first; gates others)
- Purpose: Allow container time to initialize before liveness/readiness checks
- Example use: JVM warm-up, database migration, connection pool initialization
- Behavior:
  - Runs until success or failureThreshold exceeded
  - If succeeds: moves to liveness/readiness phase
  - If fails repeatedly: container restarts
  - Timeline: initialDelaySeconds=0, periodSeconds=10, failureThreshold=30 → App has 5 minutes before restart

**Liveness Probe** (continuous; detects hung processes)
- Purpose: Detect if container is deadlocked or in zombie state
- Example use: Check if HTTP server is responsive, detect infinite loop
- Behavior:
  - Runs continuously after startup success
  - If fails repeatedly: kubelet restarts container
  - Should check only if process crashed (narrow scope)
  - Timeline: periodSeconds=10, failureThreshold=3 → 30 seconds of failures before restart

**Readiness Probe** (continuous; detects if ready to serve traffic)
- Purpose: Determine if pod should receive traffic from service load balancer
- Example use: Check database connectivity, check if cache warmed up
- Behavior:
  - Runs continuously
  - If fails: pod removed from endpoints (load balancer stops sending traffic)
  - Pod remains running; doesn't restart
  - Traffic resumes when probe succeeds again
  - Timeline: periodSeconds=5, failureThreshold=2 → pod removed after 10 seconds of failures

**Probe Execution Flow**:
```
[Pod Created]
  ↓
[Kubelet starts container]
  ↓
[startupProbe runs (if defined)]
  loop: every 10s, check if condition met
  success: gate is lifted → proceed to liveness/readiness
  failure after 30x: container restart
  ↓
[livenessProbe runs (if defined)]
  loop: every 10s, check if process responsive
  success: container alive
  failure after 3x: kill container ↔ kubelet restarts
  ↓
[readinessProbe runs (if defined)]
  loop: every 5s, check if ready for traffic
  success: add to service endpoints ← traffic flows
  failure after 2x: remove from endpoints ← traffic stops
  ↓
[Container running; serving traffic]
  continuous monitoring of all three probes
  ↓
[Pod deletion initiated (graceful shutdown)]
  preStop hook (if defined) → up to terminationGracePeriodSeconds
  SIGTERM sent
  probes stopped
  wait terminationGracePeriodSeconds
  SIGKILL if still running
```

**Probe Types**:

1. **HTTP GET** (most common)
   ```
   Kubelet sends: GET /health:8080
   Expected: HTTP status 200-399
   Failure: Any other status or timeout
   Overhead: Low; HTTP protocol well-optimized
   Danger: If endpoint slow/expensive, can cause cascading failures
   ```

2. **TCP Socket** (connection-based services)
   ```
   Kubelet attempts: TCP connect to address:port
   Success: Connection established (even if no data)
   Failure: Connection refused or timeout
   Overhead: Minimal; just 3-way handshake
   Use: Redis, Memcached, database connections
   ```

3. **Exec** (shell command)
   ```
   Kubelet executes: /bin/sh -c <command>
   Success: Exit code 0
   Failure: Non-zero exit code
   Overhead: High; spawns new process, runs shell, captures output
   Use: Complex health checks, filesystem verification
   Avoid: If alternatives exist (HTTP/TCP preferred)
   ```

4. **gRPC** (microservices)
   ```
   Kubelet calls: gRPC health check service
   Method: grpc.health.v1.Health/Check()
   Success: SERVING status
   Failure: Not SERVING or RPC error
   Overhead: Medium; gRPC protocol
   Use: gRPC-based microservices
   ```

#### Architecture Role

Probes enable **self-healing** and **traffic safety**:

```
[Application]
  ├─ Depends on external services (DB, cache, API)
  ├─ May experience transient failures
  ├─ May deadlock or consume resources
  └─ May start slowly
       ↓
[Probes detect and respond]
  ├─ Startup probe: Wait for initialization
  ├─ Liveness probe: Restart if crashed/hung
  ├─ Readiness probe: Remove from load balancing if unhealthy
       ↓
[Automatic recovery]
  ├─ No manual intervention
  ├─ Self-healing cluster
  ├─ Reduced MTTR (Mean Time To Recovery)
  └─ Higher availability
```

#### Production Usage Patterns

**Pattern 1: Quick Health Check (HTTP GET)**
```
Web API with fast health check:

readinessProbe:
  httpGet:
    path: /api/health  ← dedicated lightweight endpoint
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 2  ← 10s failure = removed from service

Behavior:
  - Pod starts → health check attempts immediately
  - If unhealthy, removed from service after 10s
  - Prevents sending 500s to clients
  - Health check endpoint must respond in <2s
```

**Pattern 2: Slow-Starting Application (Startup + Liveness)**
```
Java application (JVM warm-up takes 60s):

startupProbe:
  httpGet:
    path: /api/startup
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30  ← 5 minutes for JVM startup

livenessProbe:
  httpGet:
    path: /api/health
    port: 8080
  initialDelaySeconds: 20  ← Buffer after startup succeeds
  periodSeconds: 30
  failureThreshold: 3  ← Restart if hung >90s

Behavior:
  - Container starts; startup probe runs
  - JVM initializes; startup probe checks every 10s
  - After 60s, startup check succeeds; startup probe disabled
  - Liveness probe begins; restarts container if hangs
```

**Pattern 3: Stateful Application (Database Connectivity)**
```
Microservice with external database dependency:

readinessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - "mysql -h db.prod.svc -u app_user -p$DB_PASSWORD -e 'SELECT 1'"
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 2
  failureThreshold: 2

Behavior:
  - If DB goes down: readiness probe fails
  - Pod removed from service (clients get 503; fallback)
  - DB recovers: readiness succeeds; traffic resumes
  - No pod restart needed (temporary failure, not crash)
```

#### DevOps Best Practices

1. **Startup Probe Discipline**
   - Always use for containers with >10s startup time
   - Set failureThreshold to allow worst-case startup
   - Don't use for genuinely fast containers (overhead)
   - Actual startup time distribution: p99 + 20% headroom

2. **Liveness Probe Scope**
   - Check only if process crashed (has the process exited?)
   - Don't check external dependencies (DB, API, cache)
   - Don't use expensive operations (database queries)
   - Keep timeout short (1-2 seconds)
   - Example: Hit /health endpoint that checks only process internals

3. **Readiness Probe Depth**
   - Check all critical dependencies before serving
   - Include dependency health: database, cache, API
   - Example: /ready endpoint calls SELECT 1 on DB, checks cache connection
   - Timeout: application SLA (if SLA is 5s, timeout should be 2s)
   - Allows graceful degradation (temporarily remove pod if dependency down)

4. **Probe Configuration Tuning**
   - initialDelaySeconds: 0 (unless specific reason for delay)
   - periodSeconds: liveness=10-30s; readiness=5-10s
   - timeoutSeconds: 1-5s (should be <1s for critical paths)
   - failureThreshold: 2-3 (too low = flapping; too high = slow recovery)
   - successThreshold: leave at 1 (only readiness needs > 1)

5. **Monitoring Probe Behavior**
   - Metrics: `kubernetes_api_prober_*` for probe success/failure rates
   - Alert: "Liveness probe failing" (immediate) vs. "Readiness probe failing" (check dependencies)
   - Dashboard: Restart count per pod (high count indicates crash loop)
   - Logging: Application should log health check requests separately

6. **Zero-Downtime Deployment**
   - readiness probe ensures new pods ready before removing old ones
   - Old pods removed after greeting period completes
   - PodDisruptionBudget: maintains minimum available pods during rolling update
   - Graceful shutdown: terminationGracePeriodSeconds for connection drain

#### Common Pitfalls

1. **Same Probe Logic for Liveness and Readiness**
   - App checks external DB in liveness probe
   - DB timeout → liveness fails → pod restarted
   - Pod restart makes DB situation worse
   - Fix: Liveness checks process only; readiness checks DB

2. **Probe Timeout Too Short**
   - timeout: 1s but application response time p99 = 2s
   - Probes timeout frequently; false positives
   - Pod restarted unnecessarily
   - Fix: Set timeout >= application SLA p99

3. **No Startup Probe for Slow Apps**
   - Container startup takes 120s
   - Readiness probe starts timing out
   - Pod removed from service while still starting up
   - Fix: Add startup probe with appropriate failureThreshold

4. **readinessProbe Checks Non-Critical Dependency**
   - Readiness probe checks analytics API
   - Analytics API down → readiness fails → pod removed from service
   - Main functionality unaffected; user impact disproportionate
   - Fix: Only check critical dependencies in readiness probe

5. **Health Check Endpoint is Expensive**
   - /health endpoint triggers full database query or external API call
   - Every 5 seconds, 100 pods call expensive check
   - Causes database overload
   - Fix: /health should be fast; call everything in <100ms

6. **Rollout Fails Because readiness Threshold Too High**
   - New pod fails readiness 1 time out of N checks
   - But readiness probe runs every 5s; expected N random failures even for healthy pod
   - Fix: failureThreshold = 2-3; expect failures; requires consecutive failures

### Practical Code Examples

#### Example 1: Complete Probe Configuration for Production Web API

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api-service
  template:
    metadata:
      labels:
        app: api-service
    spec:
      terminationGracePeriodSeconds: 45  # Time for graceful shutdown
      containers:
      - name: api
        image: myregistry.azurecr.io/api-service:v2.1.0
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        
        # Startup probe: Wait for JVM + app initialization
        # Expected startup time: p99 = 45s; allow until 90s
        startupProbe:
          httpGet:
            path: /actuator/startup  # Spring Boot startup endpoint
            port: http
            scheme: HTTP
            httpHeaders:
            - name: User-Agent
              value: Kubernetes
          initialDelaySeconds: 0  # Start immediately
          periodSeconds: 10       # Check every 10s
          timeoutSeconds: 2       # Give 2s to respond
          failureThreshold: 9     # Allow 9 failures → 90s max
          successThreshold: 1     # One success confirms readiness
        
        # Liveness probe: Detect if process crashed or deadlocked
        # Narrow scope: only checks process is responsive, not dependencies
        livenessProbe:
          httpGet:
            path: /api/live        # Custom lightweight endpoint
            port: http
            scheme: HTTP
            httpHeaders:
            - name: Connection
              value: close          # Don't keep connection alive
          initialDelaySeconds: 30  # Wait for startup to complete + buffer
          periodSeconds: 15        # Check every 15s
          timeoutSeconds: 1        # Very short timeout (should be fast)
          failureThreshold: 3      # Restart after 45s of failures
          successThreshold: 1
        
        # Readiness probe: Determine if ready to serve traffic
        # Checks dependencies: database, cache, message queue
        readinessProbe:
          httpGet:
            path: /api/ready       # Custom comprehensive endpoint
            port: http
            scheme: HTTP
            httpHeaders:
            - name: Connection
              value: close
          initialDelaySeconds: 5   # Quick check after startup
          periodSeconds: 5         # Check frequently (5s)
          timeoutSeconds: 3        # Allow time for DB checks
          failureThreshold: 2      # Remove from service after 10s of failures
          successThreshold: 2      # Require 2 consecutive successes before re-adding
        
        # Environment and resource configuration
        env:
        - name: JAVA_OPTS
          value: "-Xms512m -Xmx1g -XX:+UseG1GC"
        - name: SPRING_PROFILES_ACTIVE
          value: "production"
        - name: DB_HOST
          value: postgres-primary.databases.svc.cluster.local
        - name: CACHE_HOST
          value: redis.cache.svc.cluster.local
        
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1500m
            memory: 1536Mi
        
        # Pre-stop hook: Graceful connection drain before shutdown
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 10; curl -X POST http://localhost:8080/actuator/shutdown || true"]
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-service-pdb
  namespace: production
spec:
  minAvailable: 2              # Maintain at least 2 pods available
  selector:
    matchLabels:
      app: api-service
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: production
spec:
  type: ClusterIP
  selector:
    app: api-service
  ports:
  - port: 80
    targetPort: 8080
    name: http
  # Session affinity helps with stateless apps
  sessionAffinity: None
```

#### Example 2: Custom Health Check Endpoints (Application Code)

```go
// health_handler.go - Spring Boot / Go Fiber equivalent

import (
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/healthcheck"
)

func SetupHealthRoutes(app *fiber.App) {
    // Startup endpoint: Checks if application fully initialized
    app.Get("/api/startup", func(c *fiber.Ctx) error {
        // Check if application bootstrap completed
        if !isApplicationBootstrapped() {
            return c.Status(fiber.StatusServiceUnavailable).SendString("Application starting up")
        }
        return c.Status(fiber.StatusOK).JSON(fiber.Map{
            "status":      "UP",
            "startup": "complete",
        })
    })
    
    // Liveness endpoint: Checks only if process alive
    // Should NOT check external dependencies
    app.Get("/api/live", func(c *fiber.Ctx) error {
        // Quick check: is the HTTP server responding?
        // Do NOT check database, cache, external APIs
        return c.Status(fiber.StatusOK).JSON(fiber.Map{
            "status": "UP",
        })
    })
    
    // Readiness endpoint: Checks if ready to serve traffic
    // Should check all critical dependencies
    app.Get("/api/ready", func(c *fiber.Ctx) error {
        // Check database connectivity
        if !isDatabaseConnected() {
            return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
                "status": "DOWN",
                "reason": "database unreachable",
            })
        }
        
        // Check cache connectivity
        cacheHealthErr := checkCacheHealth()
        if cacheHealthErr != nil && isCacheCritical() {
            return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
                "status": "DOWN",
                "reason": "cache unavailable",
            })
        }
        
        // Optional: Check message queue
        mqErr := checkMessageQueueHealth()
        if mqErr != nil && isMessageQueueCritical() {
            return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
                "status": "DOWN",
                "reason": "message queue unavailable",
            })
        }
        
        // All critical dependencies OK
        return c.Status(fiber.StatusOK).JSON(fiber.Map{
            "status":       "UP",
            "database":    "connected",
            "cache":       "connected",
            "message_queue": "connected",
        })
    })
}

func isDatabaseConnected() bool {
    ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
    defer cancel()
    
    if err := db.PingContext(ctx); err != nil {
        logger.Warn("Database health check failed", zap.Error(err))
        return false
    }
    return true
}

func checkCacheHealth() error {
    ctx, cancel := context.WithTimeout(context.Background(), 500*time.Millisecond)
    defer cancel()
    
    return cache.Ping(ctx).Err()
}

func isApplicationBootstrapped() bool {
    return appState.bootstrapTime != nil && 
           time.Since(appState.bootstrapTime) > 0
}
```

### ASCII Diagrams

#### Diagram 1: Probe Execution Timeline

```
Pod Lifecycle Timeline:

[T=0s] Pod Created (volumeMounts, env vars injected)
  ↓
[T=0-10s] Container Runtime starts (PID 1 = app process)
  ↓
[T=0+] Startup Probe begins (if defined)
  loop: every 10s, call GET /startup
  success? no → failure_count++ → continue
  failure_count > 9 (failureThreshold)? YES → RESTART container
  ↓
[T=50s] Startup succeeds (app ready) → failure_count reset
  Startup Probe DISABLED
  ↓
[T=50+] Liveness & Readiness Probes begin concurrently
  ↓
  Liveness (every 15s)          |  Readiness (every 5s)
  T=50: GET /live → 200 OK     |  T=50: GET /ready → 503 Service Unavailable
  T=65: GET /live → 200 OK     |     (DB still initializing)
  T=80: GET /live → 200 OK     |  T=55: GET /ready → 503
  T=95: GET /live → 200 OK     |  T=60: GET /ready → 200 OK ✓ (DB connected)
  ...                            |  T=65: GET /ready → 200 OK ✓
  Liveness Status: LIVE          |  Readiness: ADDED to Service Endpoints
                                 |     ↓ Traffic starts flowing
  ↓
[T=120s] Application starts degradation (memory leak)
  ↓
  T=120: GET /liveness → 200 OK  |  T=120: GET /ready → 200 OK (success 1/2)
  T=135: GET /liveness → 200 OK  |  T=125: GET /ready → 503 (failure 1/2)
  T=150: GET /liveness timeout    |  T=130: GET /ready → 503 (failure 2/2)
  (liveness_failure_count++)       |     ↓ Pod REMOVED from service
  T=165: GET /liveness timeout    |     ↓ No new traffic sent
  (liveness_failure_count++)       |     Load balanced to other pods
  T=180: GET /liveness timeout    |
  (liveness_failure_count > 3)     |  T=135: GET /ready → 200 OK (success 1/2)
         ↓ RESTART container    |  T=140: GET /ready → 200 OK (success 2/2)
                                  |     ↓ Pod RE-ADDED to service
[T=180s] Container restarted      |     ↓ Traffic resumes
  ↓
[T=180+] Startup probe runs again
  ...
```

#### Diagram 2: Readiness Probe Dependency Check Flow

```
[readinessprobe: GET /api/ready]
  ↓
[Application Handler]
┌──────────────────────┐
│ Check Database                 │
│  SELECT 1 (timeout: 1s)         │
│  Success? ✓ → continue          │
│  Timeout? ✗ → return 503 DOWN   │
└──────────────────────┘
  ↓ (if DB ok, continue)
┌──────────────────────┐
│ Check Cache (Redis)            │
│  PING (timeout: 500ms)          │
│  Success? ✓ → continue          │
│  Timeout? ✗ → return 503 DOWN   │
└──────────────────────┘
  ↓ (if Cache ok or optional, continue)
┌──────────────────────┐
│ Check Message Queue            │
│  PING (timeout: 500ms)          │
│  Success? ✓ → return 200 UP   │
│  Timeout? ✗ → return 503 DOWN   │
└──────────────────────┘
  ↓
[Response: 200 OK]
  ↓
[Kubelet: readinessProbe succeeds]
  status.conditions[readinessProbe]: True
  ↓
[Service Endpoints: Pod ADDED]
  ↓
[Load Balancer: Traffic FLOWS to pod]

---

Alternate Flow: Database Down

[readinessProbe: GET /api/ready]
  ↓
[Check Database]
  ↓
[Database UNREACHABLE (connection refused)]
  ↓
[Return 503 Service Unavailable]
  ↓
[Kubelet:
  readinesProbe status: failure_count++ 
  failure_count >= 2? YES
  ↓
  status.conditions[readinessProbe]: False
  ↓
[Service Endpoints: Pod REMOVED]
  ↓
[Load Balancer: Traffic STOPS]
  ↓
[Requests routed to other healthy pods]

---

When Database Recovers:

[readinessProbe: GET /api/ready]
  ↓
[Check Database: SELECT 1 ✓]
  ↓
[Return 200 OK]
  ↓
[failure_count RESET]
  ↓
[Kubelet: readinesProbe succeeds twice]
  ↓
[status.conditions[readinessProbe]: True]
  ↓
[Service Endpoints: Pod RE-ADDED]
  ↓
[Load Balancer: Traffic RESUMES]
```

## Logging & Monitoring

### Textual Deep Dive

#### Internal Working Mechanism

Kubernetes logging and monitoring operate at three levels with distinct characteristics:

**Level 1: Container Logs (stdout/stderr)**
- Container output captured by container runtime (containerd/Docker)
- Stored in `/var/lib/kubelet/pods/[pod-uid]/containers/[container-name]/` as JSON files
- Accessed via `kubectl logs`
- Limitations:
  - Limited retention (default: 5 files max, each 10MB, total 40MB)
  - Log rotation only on pod restart or file size limit
  - Node disk failure = logs lost
  - Requires kubelet access

**Level 2: Cluster-Wide Logging (Log Aggregation)**
```
Pattern 1: Sidecar Collector (recommended)
  Pod (app container)  --> stdout app logs
                    + Sidecar container (filebeat/fluentbit) --> reads logs --> Elasticsearch
  Benefit: Decoupled; no app modification needed
  Cost: Extra container resource per pod

Pattern 2: Node-Level Collector
  Node kubelet --> log files on node
        + Daemonset container (fluentd) --> reads from /var/lib/kubelet/pods
        --> Elasticsearch
  Benefit: Single collector per node; efficient
  Risk: If daemonset pod stops, logs dropped

Pattern 3: Application-Pushed (not recommended)
  Application --> directly writes to logging service
  Risk: App failure exposes logging credentials; app code tightly coupled
```

**Logging Flow**:
```
[Application] --> stdout/stderr
    (PID 1 output)
    ↓
[Container Runtime captures]
    (containerd reads stdout, stores in JSON)
    ↓
[/var/lib/kubelet/pods/[pod-uid]/containers/[container-name]/]
    cri-containerd-xxxxx.log (JSON format, rotated)
    ↓
Local retention: ~40MB total (rotates)
    ↓
Option A: Manual access
    kubectl logs <pod> --> kubelet reads from node filesystem
    ↓
Option B: Log Aggregation (Sidecar Pattern)
    Sidecar reads: /var/log/containers/[pod-name]_*_*.log
    Sends to: Elasticsearch/Loki/Datadog
    ↓
Central Storage
    Permanent retention
    Searchable index
    Query capability
```

**Level 3: Metrics (Time Series)**

Metrics differ fundamentally from logs:
- **Metrics**: Aggregated, queryable numeric data (CPU usage, requests/sec)
- **Logs**: Discrete events (pod created, error occurred)

```
Kubernetes Metrics Collection:

[Container Runtime Metrics]
  cgroup v2: memory.stat, cpuacct.stat, io.stat
  Kubelet: Reads cgroup files every 10s
  ↓
[kubelet --> cAdvisor]
  (kubelet's embedded container metrics collector)
  Exposes: /metrics/cadvisor endpoint
  ↓
[Metrics Server (optional, cluster-wide)
  Scrapes: All kubelet /metrics/cadvisor endpoints
  Every 15s: Collects and aggregates
  Stores in-memory: Recent metrics only
  Provides: kubectl top pods/nodes, HPA decisions
  ↓
[Prometheus (optional, for long-term storage)
  Scrapes: kubelet, metrics-server, applications /metrics
  Interval: Configurable (default 30s)
  Stores: Time-series database, disk-persistent
  Provides: Historical queries, alerting, dashboards (Grafana)
```

#### Production Usage Patterns

**Pattern 1: Structured JSON Logging with Correlation IDs**
```
Application logs in JSON format:
{
  "timestamp": "2026-03-11T10:15:23.456Z",
  "level": "INFO",
  "service": "api-server",
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "span_id": "f4d31ebd-37b5-447f-a48d-86ceb8ae06c3",
  "pod_name": "api-0",
  "message": "Request processed",
  "method": "POST",
  "path": "/api/orders",
  "status_code": 201,
  "duration_ms": 145,
  "user_id": "user-456",
  "order_id": "order-789"
}

Benefits:
  - Trace across multiple pods via trace_id
  - Structured fields allow filtering, aggregation
  - Correlation ID persists from request to response
```

**Pattern 2: Multi-Container Pod with Sidecar Log Collector**
```
Pod Structure:
  app container:        Logs to /proc/1/fd/1 (stdout)
        ↓
  sidecar container:    Mounts /var/log/app
                        Reads /var/log/app/output.log
                        Posts to logging backend
        ↓
Shared Volume (emptyDir):
  pod.spec.volumes[]
    - name: app-logs
      emptyDir: {}
      
App container volumeMount:
  - name: app-logs
    mountPath: /var/log/app
    
Sidecar volumeMount:
  - name: app-logs
    mountPath: /var/log/app
    readOnly: true  # Sidecar only reads
```

**Pattern 3: Prometheus Metrics with Custom Business Metrics**
```
Application exposes /metrics endpoint (Prometheus format):

# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1234
http_requests_total{method="POST",status="201"} 567

# HELP order_processing_duration_ms Order processing time
# TYPE order_processing_duration_ms histogram
order_processing_duration_ms_bucket{le="100"} 100
order_processing_duration_ms_bucket{le="500"} 450
order_processing_duration_ms_bucket{le="1000"} 490
order_processing_duration_ms_bucket{le="+Inf"} 500

# HELP payment_success_total Total successful payments
# TYPE payment_success_total counter
payment_success_total{currency="USD"} 8900
payment_success_total{currency="EUR"} 1100

HPA / Grafana dashboard:
  - Scales based on http_requests_total rate
  - Alerts on payment_success_total < 99%
  - Dashboard: Real-time payment success by currency
```

**Pattern 4: Events for Operational Changes**
```
Kubernetes Events (describe pod, show deployment history):

Event 1: Pod scheduled
  Type: Normal, Reason: PodScheduled, Message: Successfully assigned pod to node-1
  ↓
Event 2: Container pull
  Type: Normal, Reason: Pulling, Message: Pulling image "api:v1.5"
  ↓
Event 3: Container started
  Type: Normal, Reason: Started, Message: Started container api
  ↓
Event 4: Readiness probe failed
  Type: Warning, Reason: Unhealthy, Message: Readiness probe failed: ... ↓
Event 5: Pod removed from service
  (implicit; endpoint controller updates service)
  ↓
Event 6: Readiness probe succeeded
  Type: Normal, Reason: Healthy, Message: Readiness probe succeeded
  ↓
Event 7: Pod deleted
  Type: Normal, Reason: Killing, Message: Killing container with grace period

Events useful for:
  - Operational audit (who changed what, when)
  - Debugging failed deployments
  - Correlating pod changes with application issues
```

#### DevOps Best Practices

1. **Structured Logging**
   - All logs in JSON with consistent field names
   - Include: timestamp, level, service, trace_id, span_id, message, context
   - Avoid: Logging secrets (passwords, API keys)
   - Redact: PII (email addresses, credit cards, SSNs)
   - Use: Semantic fields (path, method, status_code, duration_ms) instead of free text

2. **Log Retention & Aggregation**
   - Container logs: 1-2 week retention in aggregation system
   - Long-term: Expensive to keep; archive to S3 after 30 days
   - Sampling: Sample 10% of debug logs to reduce volume
   - Retention policy: Align with regulatory requirements (PCI, HIPAA, GDPR)

3. **Metrics & Alerting**
   - Measure what indicates user impact: requests/sec, latency p99, error rate
   - Avoid low-level alerts (CPU > 70%); alert on business metrics instead
   - Alert threshold: Actionable within 5 minutes of alert
   - Runbook linkage: Alert includes link to troubleshooting runbook
   - Alert fatigue: Suppress alerts on known non-issues (maintenance windows)

4. **Event Retention**
   - Kubernetes Events retained only 1 hour by default
   - Option: Run Event exporter daemon to persist to logging backend
   - Useful for: Operational audits, debugging deployments
   - Cost: Events volume is usually low

5. **Correlation Across Services**
   - Every request gets unique trace_id
   - Propagate trace_id in HTTP headers: X-Trace-ID, X-Span-ID
   - Logging system maintains index by trace_id
   - Query capability: Show all logs for trace_id across services
   - Tools: Jaeger, Zipkin for distributed tracing visualization

6. **Monitoring Stack**
   - Metrics Server: For HPA and `kubectl top` (mandatory if using HPA)
   - Prometheus: Long-term metrics storage (weeks/months)
   - Grafana: Dashboards and visualization
   - Alertmanager: Alert routing and grouping
   - Loki: Log aggregation alternative to ELK stack (lower resource usage)

#### Common Pitfalls

1. **Logging Secrets in Application Logs**
   - Application logs database password in connection string
   - Logs aggregated to Elasticsearch
   - Anyone with Elasticsearch access sees password
   - Fix: Log redaction filters; don't log credentials ever

2. **No Log Aggregation (Logs Only on Node)**
   - Pod runs on node-1; logs in /var/lib/kubelet/pods/
   - Pod restarted; logs rotated (lost)
   - Node-1 disk failure; all logs lost
   - Fix: Always send logs to central aggregation system

3. **Metrics Cardinality Explosion**
   - Application emits: `requests_total{path="/users/{id}", user_id="123"}`
   - Every user ID and path combination = new metric
   - Cardinality: 1M users x 100 paths = 100M+ time series
   - Prometheus crashes; storage explodes
   - Fix: Use labels sparingly; avoid high-cardinality dimensions

4. **Alert on Infrastructure, Not User Impact**
   - Alert: "CPU > 70%"
   - But application still responding in
   <100ms; users unaffected
   - Alert silenced; engineer annoyed
   - Fix: Alert on business metrics (error rate, latency p99, throughput)

5. **No Correlation IDs (Hard to Debug)**
   - Request spans multiple services: API --> DB --> Cache
   - Each service logs independently
   - Debug request failure: Search 3 different logs by timestamp
   - Risk: Off-by-a-few-ms timestamp causes missing logs
   - Fix: Generate trace_id on entry point; propagate to all services

6. **Grafana Dashboards Not Documented**
   - Dashboard shows 50 panels; no tooltips
   - Team member inherits it; doesn't understand what each panel means
   - Alerts based on undefined thresholds
   - Fix: Document each dashboard: purpose, intended audience, how to use

### Practical Code Examples

#### Example 1: Deployment with Sidecar Log Collector

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-with-sidecar-logging
  namespace: production
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
      containers:
      # Main application container
      - name: api
        image: myregistry.azurecr.io/api:v1.5.0
        ports:
        - containerPort: 8080
        
        # Configure application to use structured logging
        env:
        - name: LOG_FORMAT
          value: "json"
        - name: LOG_LEVEL
          value: "info"
        - name: JAEGER_AGENT_HOST
          value: "jaeger-agent.observability.svc.cluster.local"
        - name: JAEGER_AGENT_PORT
          value: "6831"
        
        # Write logs to shared volume
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/app
        
        # Standard resource limits
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
      
      # Sidecar container: Log collector
      - name: log-collector
        image: fluent/fluent-bit:2.0-latest
        
        # Read application logs
        volumeMounts:
        - name: log-volume
          mountPath: /var/log/app
          readOnly: true
        # Fluent-bit config
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
          readOnly: true
        
        # Sidecar minimal resources
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
      
      # Volumes
      volumes:
      # Shared log directory
      - name: log-volume
        emptyDir:
          sizeLimit: 2Gi  # Cap log volume to prevent disk exhaustion
      
      # Fluent-bit configuration
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: production
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush        5
        Daemon       Off
        Log_Level    info

    [INPUT]
        Name              tail
        Tag               api.log
        Path              /var/log/app/output.log
        Parser            json
        Read_from_Head    On
        Refresh_Interval  5

    [FILTER]
        Name    modify
        Match   api.log
        Add     pod_name ${POD_NAME}
        Add     pod_namespace ${POD_NAMESPACE}
        Add     pod_uid ${POD_UID}

    [OUTPUT]
        Name            es
        Match           api.log
        Host            elasticsearch.logging.svc.cluster.local
        Port            9200
        Index           app-logs-%Y.%m.%d
        Type            _doc
        Retry_Limit     5
        aws_auth        off
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: production
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 8080
```

#### Example 2: Prometheus ServiceMonitor and Alert Rules

```yaml
apiVersion: v1
kind: Service
metadata:
  name: api-metrics
  namespace: production
  labels:
    app: api
spec:
  selector:
    app: api
  ports:
  - name: metrics
    port: 9090
    targetPort: 9090
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-monitor
  namespace: production
  labels:
    app: api
spec:
  selector:
    matchLabels:
      app: api
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: api-alerts
  namespace: production
spec:
  groups:
  - name: api.rules
    interval: 30s
    rules:
    # Alert on high error rate
    - alert: APIHighErrorRate
      expr: |
        (sum(rate(http_requests_total{app="api",status=~"5.."}[5m]))
         /
         sum(rate(http_requests_total{app="api"}[5m]))
        ) > 0.05
      for: 5m
      labels:
        severity: critical
        team: platform
      annotations:
        summary: "API high error rate ({{ $value | humanizePercentage }})"
        dashbboard: "http://grafana/d/api-dashboard"
        runbook: "http://wiki/ondcall/api-errors"
    
    # Alert on high latency
    - alert: APIHighLatency
      expr: |
        histogram_quantile(0.99, 
          sum(rate(http_request_duration_ms_bucket{app="api"}[5m])) by (le)
        ) > 1000
      for: 5m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "API p99 latency > 1s ({{ $value }}ms)"
        dashboard: "http://grafana/d/api-dashboard"
    
    # Alert on pod crashes
    - alert: APIPodCrashing
      expr: |
        increase(
          kube_pod_container_status_restarts_total{pod=~"api-.*"}[1h]
        ) > 3
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "API pod restarting excessively"
        pod: "{{ $labels.pod }}"
---
# Grafana Dashboard (ConfigMap)
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-dashboard
  namespace: production
data:
  api-dashboard.json: |
    {
      "dashboard": {
        "title": "API Service Dashboard",
        "uid": "api-main",
        "timezone": "browser",
        "panels": [
          {
            "title": "Request Rate (req/sec)",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total{app='api'}[1m]))"
              }
            ]
          },
          {
            "title": "Error Rate (%)",
            "targets": [
              {
                "expr": "(sum(rate(http_requests_total{app='api',status=~'5..'}[1m])) / sum(rate(http_requests_total{app='api'}[1m]))) * 100"
              }
            ]
          },
          {
            "title": "P99 Latency (ms)",
            "targets": [
              {
                "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_ms_bucket{app='api'}[5m])) by (le))"
              }
            ]
          },
          {
            "title": "Pod Restarts (1h)",
            "targets": [
              {
                "expr": "increase(kube_pod_container_status_restarts_total{pod=~'api-.*'}[1h])"
              }
            ]
          }
        ]
      }
    }
```

#### Example 3: Shell Script for Log & Metric Queries

```bash
#!/bin/bash
# Query logs and metrics for troubleshooting

NAMESPACE="production"
APP="api"
PROMETHEUS_URL="http://prometheus:9090"
ELASTICSEARCH_URL="http://elasticsearch:9200"

# Function: Search logs by trace ID
search_logs_by_trace() {
    local trace_id=$1
    echo "[INFO] Searching logs for trace_id: $trace_id"
    
    curl -s -X GET "${ELASTICSEARCH_URL}/app-logs-*/_search" -H 'Content-Type: application/json' -d"
    {
      \"query\": {
        \"match\": {
          \"trace_id\": \"$trace_id\"
        }
      },
      \"sort\": [{\"timestamp\": {\"order\": \"asc\"}}],
      \"size\": 100
    }
    " | jq '.hits.hits[] | {timestamp: ._source.timestamp, message: ._source.message, service: ._source.service}'
}

# Function: Check pod logs
get_pod_logs() {
    local pod=$1
    local lines=${2:-50}
    
    echo "[INFO] Retrieving last $lines lines from pod: $pod"
    kubectl logs -n $NAMESPACE $pod --tail=$lines --timestamps=true
}

# Function: Query metrics at specific time
query_metrics_at_time() {
    local metric=$1
    local timestamp=$2  # Unix timestamp
    
    echo "[INFO] Querying metric '$metric' at time $timestamp"
    
    curl -s "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode "query=$metric" \
        --data-urlencode "time=$timestamp" |
        jq '.data.result[] | {metric: .metric, value: .value}'
}

# Function: Get time-range metrics
get_metric_range() {
    local metric=$1
    local start_time=$2  # RFC3339 or relative (e.g., "1h")
    local end_time=${3:-"now"}
    
    echo "[INFO] Querying metric '$metric' from $start_time to $end_time"
    
    curl -s "${PROMETHEUS_URL}/api/v1/query_range" \
        --data-urlencode "query=$metric" \
        --data-urlencode "start=$start_time" \
        --data-urlencode "end=$end_time" \
        --data-urlencode "step=1m" |
        jq '.data.result[] | {metric: .metric, values: .values | length}'
}

# Function: Compare error rates
compare_error_rates() {
    echo "[INFO] Comparing error rates across pods"
    
    curl -s "${PROMETHEUS_URL}/api/v1/query" \
        --data-urlencode 'query=sum by (pod) (rate(http_requests_total{app="'$APP'",status=~"5.."}[5m])) / sum by (pod) (rate(http_requests_total{app="'$APP'"}[5m]))' |
        jq '.data.result[] | {pod: .metric.pod, error_rate: .value[1]}' |
        sort -k4 -rn
}

# Function: Pod restart analysis
analyze_pod_restarts() {
    local time_window=${1:-"1h"}
    
    echo "[INFO] Analyzing pod restarts in last $time_window"
    
    kubectl get events -n $NAMESPACE \
        --field-selector involvedObject.kind=Pod \
        --field-selector action=Killing \
        -o jsonpath='{range .items[*]}{.involvedObject.name}{"\t"}{.reason}{"\t"}{.message}{"\n"}{end}'
}

# Main
case "${1:-help}" in
    logs)
        search_logs_by_trace "${2:-trace-id}"
        ;;
    pod-logs)
        get_pod_logs "${2:-api-0}" "${3:-50}"
        ;;
    metrics)
        query_metrics_at_time "${2:-http_requests_total}" "$(date +%s)"
        ;;
    range)
        get_metric_range "${2:-rate(http_requests_total[5m])}" "${3:-1h}"
        ;;
    errors)
        compare_error_rates
        ;;
    restarts)
        analyze_pod_restarts "${2:-1h}"
        ;;
    *)
        echo "Usage: $0 {logs|pod-logs|metrics|range|errors|restarts} [args]"
        echo "Examples:"
        echo "  $0 logs trace-id-123"
        echo "  $0 pod-logs api-0 100"
        echo "  $0 errors"
        ;;
esac
```

### ASCII Diagrams

#### Diagram 1: End-to-End Logging Flow

```
[Application Process (PID 1)]
  stdout: log JSON
  stderr: log errors
     ↓
[Container Runtime (containerd)]
  Captures stdout/stderr
  Writes to: /var/lib/kubelet/pods/[pod-uid]/containers/[container-name]/cri-containerd-xxxxx.log
  Format: JSON (with container runtime metadata)
     ↓
[kubelet on Node]
  Path: /var/lib/kubelet/pods/[pod-uid]/containers/[container-name]/
  Symlink: /var/log/pods/[namespace]_[pod-name]_[uid]/[container-name]/
  Local retention: 5 files × 10MB = ~40MB total
  On rotation: Older logs deleted
     ↓
[Log Collector Sidecar (Fluent-bit)]
  Mount: /var/log/pods (read-only)
  Read: [container].log files
  Parse: JSON
  Enrich: Add pod_name, pod_namespace, pod_uid, trace_id
  Send: HTTP POST to Elasticsearch
     ↓
[Elasticsearch]
  Index: app-logs-2026.03.11
  Document: {
    timestamp: "2026-03-11T10:15:23.456Z",
    level: "INFO",
    service: "api",
    trace_id: "550e8400-e29b",
    pod_name: "api-0",
    pod_namespace: "production",
    message: "...",
    ...
  }
     ↓
[Query (Kibana / Log Viewer]
  GET /_search {"query": {"match": {"trace_id": "550e8400"}}}
  Returns: All logs for this request across all services
  Timeline: Visual log flow with microsecond precision
```

#### Diagram 2: Metrics Scrape & Storage

```
[Kubernetes Cluster Pods]
  │
  ├─ api-service-0: /metrics endpoint (Prometheus format)
  ├─ api-service-1: /metrics endpoint
  ├─ api-service-2: /metrics endpoint
  ├─ (custom app metrics)
  │   http_requests_total
  │   http_request_duration_ms
  │   payment_success_total
  │   order_processing_duration_ms
     ↓
[Prometheus Server]
  Loop every 30s:
    ├─ Discover targets (via ServiceMonitor or static config)
    ├─ Scrape /metrics from each pod
    ├─ Parse Prometheus format
    ├─ Relabel (add kubernetes labels: pod, namespace, node)
    ├─ Store in time-series database on disk
     ↓
[Prometheus Time-Series Database]
  ├─ Metric: http_requests_total
  │  Labels: {app="api", pod="api-0", instance="10.0.1.2:8080"}
  │  Data points: [2026-03-11T10:00:00Z, 1000], [10:00:30Z, 1050], ...
  ├─ Metric: http_request_duration_ms_bucket
  │  Labels: {app="api", le="100"}, {le="500"}, {le="+Inf"}
  │  Data points: Time-series bucketed histogram
  └─ Retention: 15 days (configurable)
     ↓
[Query Engine]
  API: /api/v1/query[_range]
  PromQL: sum(rate(http_requests_total[5m]))
     ↓
[Results]
  Returned as JSON time-series (to Grafana, Alertmanager)
     ↓
[Grafana Dashboards]
  Graph 1: Request Rate (queries last 1h)
  Graph 2: Error Rate (p95)
  Graph 3: P99 Latency
  ↓
[Alertmanager]
  Rule: IF (error_rate > 5%) FOR 5m
  Action: Send alert to Slack, PagerDuty, email
```

---

---

## Hands-on Scenarios

### Scenario 1: Debugging High Memory Usage and OOMKill

**Situation**: Pod `api-service-2` restarting every few minutes with exit code 137 (OOMKilled).

**Diagnosis Steps**:
1. Check pod status: `kubectl describe pod api-service-2 -n production`
   - Look for: `State: Waiting, Reason: CrashLoopBackOff`
   - Last state: `ExitCode: 137`

2. Check memory limits: `kubectl get pod api-service-2 -n production -o jsonpath='{.spec.containers[*].resources.limits.memory}'`
   - Returns: `1Gi`

3. Query historical memory usage from Prometheus:
   ```
   max_over_time(container_memory_usage_bytes{pod="api-service-2"}[1d])
   ```
   - If > 1Gi: Genuine memory need; increase limit
   - If < 1Gi: Memory leak; check application code

4. Check if memory usage grows monotonically (leak indicator):
   ```
   SELECT
     (max(container_memory_usage_bytes{pod="api-service-2"}[1d]) - min(container_memory_usage_bytes{pod="api-service-2"}[1d])) / 1024 / 1024 as memory_growth_mb
   ```

5. Examine logs for memory pressure:
   ```
   kubectl logs api-service-2 -n production --previous  # Get logs from last container
   grep -i "oom\|memory\|heap" # Look for memory-related messages
   ```

**Resolution**:
- If memory leak: Debug application (heap dump, profiling)
- If genuine need: Increase limit to p99 + 20%
  ```yaml
  resources:
    requests: 512Mi  # Actual need
    limits: 1536Mi   # 3 × request for JVM
  ```

---

### Scenario 2: ConfigMap Change Not Reflected in Pod

**Situation**: Updated ConfigMap `app-config`; application still using old values.

**Root Cause**: ConfigMap changes don't automatically reload; pod must be restarted.

**Options**:
1. **Automatic reload (recommended)**:
   - Install config reloader: `reloader` or `external-secrets-operator`
   - Add annotation: `config.reloader.stakater.com/match: "app-config"`
   - Reloader watches ConfigMap; restarts pod on change

2. **Manual rolling restart**:
   ```bash
   kubectl rollout restart deployment/app-service -n production
   ```

3. **Verify change took effect**:
   ```bash
   kubectl get pod api-service-0 -n production -o jsonpath='{.spec.containers[0].env[?(@.valueFrom.configMapKeyRef.name=="app-config")]}'
   # Check mounted files
   kubectl exec api-service-0 -n production -- cat /etc/app/config/db.host
   ```

---

### Scenario 3: Pod Won't Scale Up Despite High CPU Usage

**Situation**: HPA configured; max replicas reached; CPU still high; requests failing.

**Diagnosis**:
1. Check HPA status: `kubectl get hpa api-hpa -n production`
   - Current replicas vs. max replicas
   - Current CPU usage vs. target

2. Check metrics availability: `kubectl get deployment api-service -n production -o jsonpath='{.status.conditions[?(@.type=="Progressing")]}' | jq`

3. Check for resource quota limits: `kubectl describe resourcequota -n production | grep -A 5 requests.cpu`
   - If quota exceeded: Cannot create more pods

4. Check node capacity: `kubectl top nodes`
   - If nodes at capacity: Need to add nodes to cluster

**Resolution**:
- Increase HPA `maxReplicas`
- Increase ResourceQuota limits
- Add nodes to cluster: `eksctl scale nodegroup --cluster=my-cluster --nodes=5`
- Optimize application to reduce per-pod CPU consumption

---

### Scenario 4: Pod Marked Unready; Readiness Probe Failing

**Situation**: New deployment rolling out; new pods stuck in `Running` but not added to service endpoints.

**Diagnosis**:
1. Check pod status: `kubectl get pods -n production | grep api-service`
   - Status: `Running`; Ready: `0/1`

2. Check readiness probe failure: `kubectl describe pod api-service-3 -n production | grep -A 5 "Readiness"`
   - Shows: `Readiness probe failed: ... database unreachable`

3. Verify database connectivity from pod:
   ```bash
   kubectl exec api-service-3 -n production -- \
     mysql -h postgres.databases.svc -u app -p$PASSWORD -e "SELECT 1"
   ```

4. Check database service: `kubectl get svc postgres -n databases`
   - Status: Active endpoints?
   - DNS resolvable: `kubectl exec api-service-3 -- nslookup postgres.databases.svc`

**Resolution**:
- Wait for database to become ready
- Or: Reduce readiness probe threshold to allow serving before dependencies (if safe)
- Or: Fix database connection issue

---

### Scenario 5: Storage Volume Running Out of Space

**Situation**: Pod stuck in `Pending`; events show "no PVC with sufficient capacity".

**Diagnosis**:
1. Check PVC status: `kubectl get pvc -n production`
   - Status: `Pending`

2. Check disk availability: `kubectl top nodes`
   - Nodes showing high allocated vs. available

3. Check existing PVCs: `kubectl get pvc -A --sort-by=.spec.resources.requests.storage`
   - Sum requests; compare to allocatable

**Resolution**:
- Expand existing PVC (if StorageClass allows):
  ```bash
  kubectl patch pvc postgres-data -n production -p '{"spec":{"resources":{"requests":{"storage":"200Gi"}}}}'
  ```
- Or add new storage nodes to cluster
- Or clean up unused PVCs (reclaim policy=Retain stores orphaned PVs)

---

## Interview Questions

### ConfigMaps & Secrets

1. **Q: How would you prevent Kubernetes secrets from being stored in plaintext in etcd?**
   - A: Enable encryption at rest via EncryptionConfiguration in API server. This uses KMS keys (AWS KMS, Azure Key Vault) to encrypt secrets before storage in etcd.

2. **Q: What's the difference between mounting a Secret as a volume vs. environment variable? When would you use each?**
   - A: 
     - Volume: Preferred; exposed via tmpfs filesystem; not in process environment (safer); automatically updated if secret rotated
     - Env var: Legacy approach; visible in process environment (logging risk); not automatically updated
     - Use volume for all new applications

3. **Q: How do you rotate database credentials without downtime?**
   - A: Use external-secrets-operator to sync new password from vault → Kubernetes Secret → Pod reads from volume → Can use new password for next connection → Old connections drain with graceful shutdown (terminationGracePeriodSeconds)

### Storage

4. **Q: Explain the difference between PersistentVolume, PersistentVolumeClaim, and StorageClass.**
   - A: StorageClass = template ("create gp3 EBS volumes") → PVC = request ("I need 100Gi RWO") → PV = actual resource ("bound to EBS vol-xyz"). StorageClass enables dynamic provisioning; without it, admin must manually create PVs.

5. **Q: A StatefulSet with 3 replicas loses a pod. How is the data recovered?**
   - A: Each StatefulSet pod has a unique PVC (postgres-0-data, postgres-1-data). If pod-1 is deleted, Kubernetes schedules a new pod-1 in its place, which remounts the same PVC (and original EBS volume). Data is not lost unless the PVC itself is deleted (reclaim policy=Retain).

6. **Q: What's the risk of using RWX (ReadWriteMany) access mode? How would you mitigate it?**
   - A: Risk: Multiple pods writing simultaneously to NFS can cause data corruption without application-level locking. Mitigation: Use RWX only for read-only shared config; if writes required, use database (Kubernetes-managed or external) instead of direct file I/O.

### Resource Management

7. **Q: How does the scheduler make placement decisions? What happens if a pod's request is larger than any node's available resources?**
   - A: Scheduler sums pod requests; finds nodes where available >= request. If no node has enough available, pod stays Pending indefinitely. Key: "available" = allocatable - sum of other pods' requests (not current usage). To fix: reduce requests, add nodes, or reduce other pods' resource usage.

8. **Q: Explain QoS classes. Why would you prefer Guaranteed over BestEffort?**
   - A: Guaranteed (request = limit): Pod never evicted unless system critically low (most predictable). BestEffort: Pod evicted first under pressure. Use Guaranteed for critical services (databases, APIs); BestEffort for fault-tolerant batch jobs.

9. **Q: You set request=1 CPU and limit=4 CPU. Application uses 2.5 CPU on average. What issues could occur?**
   - A: Request=1 means scheduler assumes 1 CPU reserved (might over-schedule). If 50 pods all use 2.5 CPU, node thrashing (all throttled). Better: Measure p95 usage; set request=2 CPU, limit=3 CPU. Or use VPA to auto-tune.

### Healthchecks & Probes

10. **Q: What's the difference between liveness and readiness probes? Which one should restart the container?**
    - A: Liveness = detects crashed/hung process; restarts if failing. Readiness = detects transient issues; removes pod from service (no restart). Common mistake: readiness probe checks database, so database outage kills all pods (cascading failure). Instead, readiness shows pod can't serve, liveness shows process alive.

11. **Q: A pod has startup probe with failureThreshold=30, periodSeconds=10. How long before the container restarts if startup never succeeds?**
    - A: 30 failures × 10 seconds = 300 seconds = 5 minutes. After 5 minutes of failed startup checks, kubelet restarts the container.

12. **Q: Your health check endpoint is slow (2 seconds). What problems could this cause?**
    - A: Each probe timeout means longer failure detection (5s interval + 2s timeout = 7s minimum failure time). Also, if readiness checks expensive endpoint, many failed checks to database (increased load).

### Logging & Monitoring

13. **Q: How would you correlate logs across three microservices to debug a single request failure?**
    - A: Generate unique trace_id at entry point; propagate via HTTP headers (X-Trace-ID) to all services. All services log trace_id in every log message. Query logging system: "show all logs where trace_id = abc123". Tools: Jaeger, Zipkin for visualization.

14. **Q: A pod is emitting sensitive data (credit card numbers) in logs. How would you remediate this?**
    - A: Immediate: Redact logs in aggregation system (Elasticsearch filter, Splunk regex). Long-term: Fix application code to not log PII; add pre-deployment scanning tool (e.g., TruffleHog, GitGuardian) to detect secrets in logs. Audit who accessed logs.

15. **Q: How does Prometheus decide to alert on "high error rate"? What could cause false positives?**
    - A: Alert rule: `error_rate > 5% for 5 minutes`. Evaluates every 30s: if true for 5m, fires alert. False positive: Expected error spikes (deploy, gradual rollout) look like real incidents. Mitigation: Different thresholds per environment; suppress during deployments; correlation with deployment events.

---

**Document Version**: 2.0  
**Last Updated**: March 2026  
**Target Audience**: Senior DevOps Engineers (5–10+ years)  
**Status**: Complete. All subtopics, code examples, diagrams, hands-on scenarios, and interview questions included.
