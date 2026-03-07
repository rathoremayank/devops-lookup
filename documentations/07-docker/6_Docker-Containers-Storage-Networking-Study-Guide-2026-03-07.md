# Docker Containers, Storage and Networking
## Senior DevOps Study Guide
**Version:** 2026-03-07 | **Audience:** DevOps Engineers (5–10+ years experience)

---

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Topic](#overview-of-topic)
   - [Why It Matters in Modern DevOps Platforms](#why-it-matters-in-modern-devops-platforms)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Typical Cloud Architecture Position](#typical-cloud-architecture-position)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Container Commands & Lifecycle](#container-commands--lifecycle)
   - [Core Container Management Commands](#core-container-management-commands)
   - [Container Inspection & Monitoring](#container-inspection--monitoring)
   - [Container Modification & Export](#container-modification--export)
   - [Lifecycle State Transitions](#lifecycle-state-transitions)

4. [Docker Storage](#docker-storage)
   - [Storage Driver Architecture](#storage-driver-architecture)
   - [Volumes: Persistent Data Management](#volumes-persistent-data-management)
   - [Bind Mounts: Host Directory Integration](#bind-mounts-host-directory-integration)
   - [tmpfs: In-Memory Storage](#tmpfs-in-memory-storage)
   - [Storage Driver Deep Dive](#storage-driver-deep-dive)
   - [Data Management Strategies](#data-management-strategies)
   - [Persistent Patterns & Anti-Patterns](#persistent-patterns--anti-patterns)

5. [Docker Networking Basics](#docker-networking-basics)
   - [Network Driver Types](#network-driver-types)
   - [Service Discovery & DNS Resolution](#service-discovery--dns-resolution)
   - [Port Mapping & Exposure](#port-mapping--exposure)
   - [Multi-Host Networking](#multi-host-networking)

6. [Hands-on Scenarios](#hands-on-scenarios)

7. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Docker Containers, Storage, and Networking represent the three foundational pillars of containerized application architecture. These three domains are deeply interconnected:

- **Containers** provide process isolation, resource constraints, and lifecycle management
- **Storage** ensures data persistence, performance, and availability across container restarts
- **Networking** enables inter-container communication, service discovery, and external access

For senior DevOps engineers, mastery of these areas is critical for designing scalable, resilient, and maintainable containerized systems at enterprise scale.

### Why It Matters in Modern DevOps Platforms

In modern DevOps platforms (Kubernetes, Swarm, AWS ECS), understanding these fundamentals is essential because:

1. **Production Reliability**: Improper storage configuration causes data loss; misconfigured networking creates service outages
2. **Cost Optimization**: Inefficient storage drivers and networking patterns lead to performance degradation and wasted resources
3. **Security Posture**: Network isolation, storage access controls, and container capabilities directly impact security boundaries
4. **Troubleshooting**: Most production issues stem from misconfigurations in these three areas; deep knowledge enables rapid diagnosis
5. **Platform Migration**: Moving workloads between orchestrators requires understanding how each platform implements storage and networking
6. **Multi-Tenancy**: Storage volumes and network policies enforce isolation between different applications and teams
7. **CI/CD Pipeline Efficiency**: Container layering (storage) and registry networking affect build and deployment speeds

### Real-World Production Use Cases

#### E-Commerce Platform
A high-traffic e-commerce system requires:
- **Storage**: Persistent volumes for databases, distributed file systems for product images, tmpfs for session caches
- **Networking**: Multiple networks isolating frontend, backend, and database services; load balancing across container replicas
- **Containers**: Auto-scaling of frontend containers with orchestration, health checks ensuring service availability

**Pain Point**: Inadequate storage driver configuration for database containers causes I/O contention during peak traffic.

#### Microservices Architecture
Independent services need:
- **Containers**: Each service runs in isolated containers with different update schedules
- **Storage**: Service-specific databases require persistent volumes; logging requires volume sharing with log aggregators
- **Networking**: Service mesh networking for inter-service communication with automatic retry and circuit breaking

**Pain Point**: Sub-optimal DNS resolution caching and overlay network latency causes cascading timeouts.

#### Data Processing Pipeline
ETL/batch processing systems require:
- **Storage**: High-throughput storage drivers for Hadoop/Spark, tmpfs for intermediate results, bind mounts for host GPU access
- **Networking**: Flat network topology for high-speed inter-node communication, custom route tables for data locality
- **Containers**: Long-running containers with resource limits, proper signal handling for graceful failure

**Pain Point**: Improper graceful shutdown of containers causes job failures and data corruption.

#### CI/CD System
Build infrastructure needs:
- **Storage**: Layered image building optimized with storage drivers, Docker-in-Docker containers with proper volume mounting
- **Networking**: Secure networks isolating build agents, artifact registries accessible only within the cluster
- **Containers**: Resource-constrained build agents, proper container cleanup to prevent layer accumulation

**Pain Point**: Layer bloat in build images causes slow pulls and wasted registry storage.

### Typical Cloud Architecture Position

In enterprise cloud architectures, Docker fundamentals fit into this stack:

```
┌─────────────────────────────────────────────────────────┐
│ Application Layer (Your containers running microservices)│
├─────────────────────────────────────────────────────────┤
│ Orchestration Layer (Kubernetes)                         │
│ ├─ Container Scheduling & Lifecycle Management          │
│ ├─ Storage Orchestration (CSI plugins, PVCs)           │
│ └─ Network Policy Enforcement (CNI plugins)            │
├─────────────────────────────────────────────────────────┤
│ Docker Runtime Layer (containerd, CRI-O)                │
│ ├─ Container Commands & Lifecycle                       │
│ ├─ Storage Driver (overlay2, devicemapper)             │
│ └─ Network Driver (bridge, overlay)                    │
├─────────────────────────────────────────────────────────┤
│ Kernel Layer (Linux)                                    │
│ ├─ Cgroups (resource limits)                           │
│ ├─ Namespaces (isolation)                              │
│ └─ iptables/netfilter (network rules)                  │
├─────────────────────────────────────────────────────────┤
│ Infrastructure Layer (Cloud Provider)                   │
│ └─ Virtual Machines, Block Storage, Network VPCs       │
└─────────────────────────────────────────────────────────┘
```

**Position in workflow:**
1. **Design Phase**: Decide storage driver based on workload I/O patterns; plan network topology for multi-node services
2. **Development Phase**: Use volumes and bind mounts for live code reloading; local networking for service communication
3. **Build Phase**: Optimize image layers using storage driver knowledge; minimize final image size
4. **Deployment Phase**: Configure persistent volumes for stateful containers; define network policies for security
5. **Operations Phase**: Monitor storage usage and I/O metrics; troubleshoot connectivity issues using network inspection tools
6. **Scale Phase**: Ensure storage solutions support horizontal scaling; validate network policies under load

---

## Foundational Concepts

### Key Terminology

#### Core Docker Concepts

| Term | Definition | Enterprise Relevance |
|------|-----------|---------------------|
| **Image** | Immutable template consisting of layered filesystems; read-only blueprint for containers | Foundation for reproducible deployments; layer caching drives CI/CD performance |
| **Container** | Running instance of an image with isolated namespaces, cgroup limits, and writable layer | Foundational abstraction; one container = one process mindset vs. monolithic VMs |
| **Layer** | Discrete filesystems stacked via Union Mount (overlay2); each FROM/RUN/COPY/ADD creates a layer | Critical for image size optimization; cache invalidation affects build times |
| **Volume** | Decoupled storage mechanism independent of container lifecycle; survives container deletion | Essential for stateful workloads; enables data sharing between containers |
| **Bind Mount** | Direct mapping of host filesystem into container namespace | Used for development, not production; presents security/portability risks |
| **Network Driver** | Kernel-level networking implementation providing connectivity between containers/hosts | Different drivers (bridge vs. overlay) have different latency/security tradeoffs |
| **Registry** | Centralized repository for storing and distributing images | Acts as single source of truth for what's deployed; performance critical for deployments |

#### Storage-Specific Terminology

| Term | Definition | SRE Implication |
|------|-----------|-----------------|
| **Union Mount** | Technique stacking multiple filesystems transparently (copy-on-write semantics) | Enables image layering; understand performance penalties vs. native filesystems |
| **Copy-on-Write (CoW)** | File modifications create new layer copies instead of modifying originals | Write amplification can degrade performance; devicemapper less efficient than overlay2 |
| **Storage Driver** | Kernel module implementing Union Mount; different options for different I/O patterns | Poor choice causes I/O performance issues; no universal "best" option |
| **Persistent Volume** | Kubernetes abstraction decoupling storage from pod lifecycle | Adds layer of abstraction; understand under-the-hood storage driver usage |
| **tmpfs** | In-memory filesystem performing like disk but with RAM latency; lost on container restart | Ideal for stateless caches; understand memory pressure and container restart implications |

#### Networking-Specific Terminology

| Term | Definition | Architecture Impact |
|------|-----------|-------------------|
| **Bridge Network** | Creates isolated Layer 2 bridge per network; containers on same bridge communicate via Linux bridge | Default for multi-container deployments; understand bridge routing vs. overlay overhead |
| **Overlay Network** | Encapsulates container packets in VXLAN/UDP tunnels for cross-host communication | Enables multi-node deployments; increased packet overhead vs. bridge; enables service discovery |
| **Host Network** | Container shares host's network namespace; no isolation, highest performance | Special cases only (monitoring agents); breaks container isolation guarantee |
| **None Network** | Container has only loopback interface; no external connectivity | Used for offline processing; verification of network-free execution |
| **Service Discovery** | Automatic registration and resolution of container IPs to service names | DNS-based (Docker DNS) or API-based (Consul); enables loose coupling between services |
| **Port Mapping** | Binding container port to host port via iptables rules | Not scalable across orchestrators; service discovery replaces in production |
| **DNS Resolution** | Docker's embedded DNS server (127.0.0.11:53) resolving container names and external domains | Caching behavior and TTLs affect failover speed; understand DNS timeouts in client libraries |

---

### Architecture Fundamentals

#### Container Layering Architecture

Containers are built on **Union Filesystems** that stack multiple read-only layers:

```
┌─────────────────────────────────────────────────┐
│ Container Layer (writable, ephemeral)           │  ← Your running app modifications
├─────────────────────────────────────────────────┤
│ Layer 4 (FROM ubuntu:20.04)                     │  ← Base OS
├─────────────────────────────────────────────────┤
│ Layer 3 (RUN apt-get install nginx)             │  ← Installed packages
├─────────────────────────────────────────────────┤
│ Layer 2 (COPY app.py /app/)                     │  ← Application code
├─────────────────────────────────────────────────┤
│ Layer 1 (RUN pip install -r requirements.txt)   │  ← Dependencies
└─────────────────────────────────────────────────┘
    ↑
    │
    Storage Driver (overlay2) implements CoW semantics
```

**Key implications:**
- Each layer is immutable; modifications are Copy-on-Write
- Container layer is ephemeral; deleted on container removal
- Shared layers enable efficient storage across multiple containers
- Poor layer arrangement causes: redundant copies, slow builds, massive image sizes

#### Storage Driver Implementation

Storage drivers implement Union Mounts differently:

| Driver | Mechanism | Best For | Avoid For |
|--------|-----------|----------|-----------|
| **overlay2** | OverlayFS (kernel module); direct filesystem namedtuples | Modern Linux; general-purpose workloads | Lots of small files causing layer explosion |
| **aufs** | Multiple Union Mount; slower than overlay2 | Legacy systems; not recommended new | Production (deprecated in Docker 19.03+) |
| **devicemapper** | Block-level device; thin provisioning with snapshots | Dense containerization on restricted kernels | High I/O workloads (larger CoW overhead) |
| **btrfs** | Filesystem-level Union; native filesystem semantics | High-performance workloads on btrfs-based systems | Stability concerns; rarely used |

**overlay2** is the recommended default; understand its pitfalls (many small files, container layer writes).

#### Storage Hierarchy

```
Physical Storage (Host Filesystem)
    ↓
Storage Driver (overlay2/devicemapper)
    ↓
Container Image Layers (read-only, shared)
    ↓
Container Layer (ephemeral, writable)
    ↓
Volumes (persistent, decoupled from container)
```

**Critical distinction:** Volumes are NOT managed by storage drivers; they bypass the Union Mount layer entirely.

#### Network Architecture

Docker networking operates at multiple levels:

```
Application Layer (your code)
    ↓ (socket I/O)
Container Network Interface (veth pair)
    ↓
Bridge/Overlay Driver
    ↓ (kernel network stack)
Host Network Interface (eth0)
    ↓
Physical/Cloud Network
```

**Key architectural points:**
1. Each container gets a virtual ethernet pair (veth) connected to a bridge
2. Bridges forward packets between containers and the host
3. Overlay networks encapsulate packets in VXLAN tunnels for cross-host communication
4. DNS runs embedded (127.0.0.11:53) inside each container for service discovery

---

### Important DevOps Principles

#### 1. **Immutability Principle**
**Definition**: Container images should be immutable; changes require new images, not modifications to running containers.

**DevOps Implication:**
- Versioned, reproducible deployments
- Easy rollback to previous image versions
- CI/CD pipelines enforce consistency

**Anti-pattern**: Using `docker exec` to modify running containers; configuration drift; manual changes lost on restart.

**How it applies to storage/networking:**
- Images encode storage driver choice; can't change at runtime
- Network configuration often set during `docker run`; changing requires new container

#### 2. **Separation of Concerns**
**Definition**: Data concerns (storage), network concerns, and runtime concerns should be independently configurable.

**DevOps relevance:**
- Storage decisions (volume type) independent of application logic
- Network policies independent of service code
- Container image focuses on application, not infrastructure

**Example breakdown:**
```
Container Image = Application Code + Runtime Dependencies
Volume = Data Persistence (configured separately)
Network = Connectivity (configured separately)
```

**Risk**: Coupling application config with infrastructure choices; reduces portability between orchestrators.

#### 3. **Resource Isolation Principle**
**Definition**: Each container must be isolated from others using namespaces and cgroups; resource limits prevent noisy neighbor problems.

**DevOps Application:**
- CPU/memory limits prevent one workload starving others
- Network isolation (custom bridges) contain blast radius of network failures
- Storage quotas prevent disk exhaustion

**Common violation**: Running containers without resource limits; one runaway process impacts entire system.

#### 4. **Graceful Degradation**
**Definition**: When containers fail (out of memory, network issues), should fail cleanly without corrupting data.

**Storage consideration:**
- Volumes must be unmounted cleanly on container stop
- In-flight writes to tmpfs are lost; understand implications
- CoW operations may fail under extreme conditions

**Network consideration:**
- Long-lived connections should handle DNS refresh
- Clients should retry with backoff, not hardcoded IPs
- Load balancers should detect failed containers quickly

#### 5. **Monitorability by Default**
**Definition**: All infrastructure decisions should leave observable traces.

**Applies to:**
- Storage driver choice creates different metrics (read/write latencies vary)
- Network driver choice affects packet traces and latency distributions
- Container commands should log actions for audit trails

---

### Best Practices

#### Container Lifecycle Management

1. **Always Use Named Containers**: 
   ```bash
   docker run --name myapp ...  # NOT: random names
   ```
   Enables easier identification, better logging, reproducible references.

2. **Implement Proper Signal Handling**:
   - Containers should trap SIGTERM, perform cleanup, exit within gracefully shutdown timeout
   - Default timeout is 10 seconds; ensure apps can shutdown within window
   - Don't rely on SIGKILL for cleanup

3. **Use Health Checks**:
   ```bash
   docker run --health-cmd="curl localhost:8080" \
              --health-interval=10s \
              --health-retries=3 ...
   ```
   Enables orchestrators to detect unhealthy containers and restart.

4. **Limit Logging Output**:
   - Container logs grow unbounded by default
   - Use log drivers (json-file with max-size, splunk, journald) to prevent disk exhaustion
   - Aggregate logs to centralized system (ELK, Datadog) in production

#### Storage Best Practices

1. **Use Volumes for Persistent Data**:
   ```bash
   docker run -v postgres-data:/var/lib/postgresql/data postgres:13
   ```
   - Named volumes survive container deletion
   - Decoupled from container lifecycle
   - Support backup/restore workflows

2. **Understand Storage Driver Selection**:
   - **Default overlay2** for most workloads
   - Consider alternatives only if you hit specific constraints
   - Profile actual I/O patterns; don't assume

3. **Implement Data Locality**:
   - Co-schedule containers and their volumes on same nodes
   - Multi-node scheduling without data locality causes network bottlenecks

4. **Monitor Storage Metrics**:
   - Track volume usage over time
   - Alert on capacity thresholds (80%, 90%)
   - Implement data retention policies

5. **Plan for Backup/Recovery**:
   - Volumes are not automatically backed up
   - Implement external backup strategy (snapshots, replication)
   - Test recovery procedures regularly

#### Networking Best Practices

1. **Use Custom Networks Instead of Host Network**:
   ```bash
   docker network create mynet
   docker run --network mynet --name app1 ...
   docker run --network mynet --name app2 ...
   ```
   - Maintains isolation
   - Enables service discovery via DNS
   - Host network breaks container abstraction

2. **Explicit Port Mappings**:
   ```bash
   docker run -p 8080:8080 ...  # NOT: -P (random ports)
   ```
   - Predictable external access
   - Easier firewall rules
   - Port conflicts detectible at container start

3. **DNS Caching Awareness**:
   - Docker's embedded DNS caches responses
   - Client libraries may cache beyond Docker DNS TTL
   - For critical failovers, consider using headless services (Kubernetes) with shorter TTLs

4. **Graceful connection handling**:
   - Applications must detect and reconnect on network changes
   - Don't hardcode container IPs; use DNS names
   - Implement retry logic in clients

5. **Network Security**:
   - Use custom bridges to isolate sensitive containers
   - Implement network policies (Kubernetes NetworkPolicy, Calico)
   - Don't expose db containers on public networks

---

### Common Misunderstandings

#### 1. **"Volumes = Persistent Storage"**
**Misconception**: "I'm using a volume, so my data is safe."

**Reality**: Volumes persist across container restarts but are NOT automatically backed up. Deleting a volume deletes data permanently.

**Correction**: Volumes ensure data doesn't vanish on container restart, but require separate backup strategy.

#### 2. **"Bind Mounts are Safe for Production"**
**Misconception**: "I can use bind mounts instead of volumes for production."

**Reality**: Bind mounts present security risks (host filesystem exposure), portability problems (path specificity), and don't work across nodes.

**Correction**: Use bind mounts only for development; volumes for production.

#### 3. **"Storage Drivers Don't Matter; Just Use Default"**
**Misconception**: "Storage driver is an implementation detail; choice doesn't affect my app."

**Reality**: Storage driver choice directly impacts I/O performance, disk usage, memory overhead, and stability.

**Correction**: Understand default (overlay2) characteristics; profile workload I/O patterns if performance is critical.

#### 4. **"The Docker Bridge is Secure Isolation"**
**Misconception**: "Containers on different bridges can't communicate; they're isolated."

**Reality**: Containers on *different* bridges on same Docker host CAN communicate via host IP. Different bridges only isolate within bridge.

**Correction**: Custom bridges isolate from default bridge; for true isolation across hosts, use overlay networks or orchestrator network policies.

#### 5. **"DNS Resolves Container IPs Automatically"**
**Misconception**: "Once I start a container, its IP is immediately resolvable via its name."

**Reality**: DNS resolution works within custom networks; default bridge requires manual `--link` (deprecated). External DNS requires manual registration.

**Correction**: Always use custom networks for service discovery; understand DNS limitations of default bridge.

#### 6. **"Container Layer is Like a Volume"**
**Misconception**: "I can store persistent data in the container layer; it's like a volume."

**Reality**: Container layer is ephemeral; deleted when container is removed. Not suitable for any persistent data.

**Correction**: Use ONLY volumes or bind mounts for data that must outlive containers.

#### 7. **"Port Mapping Replaces Load Balancers"**
**Misconception**: "I can scale by port mapping containers to different host ports; this acts like a load balancer."

**Reality**: Port mapping is manual routing; doesn't include health checks, load distribution, or automatic failover.

**Correction**: Use service discovery (DNS-based) or orchestrator-level load balancing (Kubernetes services) for scaling.

#### 8. **"Overlay2 is Always Faster Than Devicemapper"**
**Misconception**: "Use overlay2 everywhere for maximum performance."

**Reality**: overlay2 excels at read-heavy, large-file workloads; devicemapper excels at many-small-files scenarios due to block-level efficiency.

**Correction**: Profile workload; overlay2 is usually fine, but device-mapper may be faster in dense containerization scenarios.

#### 9. **"Container IP is Persistent"**
**Misconception**: "A container's IP is fixed; I can hardcode IPs in configs."

**Reality**: Container IP is ephemeral; changes on restart or restart with different network. Service discovery (DNS) handles this.

**Correction**: Always use service discovery (DNS names) instead of hardcoded IPs.

#### 10. **"Memory Limit Prevents Out-of-Memory Kills"**
**Misconception**: "If I set memory limit, app will gracefully handle OOM."

**Reality**: Memory limit enforces hard ceiling; exceeding it triggers SIGKILL (not graceful). No warning before termination.

**Correction**: Set memory limit and understand applications will be forcibly killed if they exceed it; implement memory monitoring for earlier warning.

---

## Container Commands & Lifecycle

### Core Container Management Commands

#### `docker run` - Create and Start a Container

**Signature**:
```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

**Senior-level considerations:**

1. **Image Resolution**:
   ```bash
   docker run ubuntu:20.04  # Pulls from Docker Hub if not cached
   docker run myregistry.azurecr.io/myapp:latest  # Private registry
   ```
   - Image is pulled if not in local cache
   - Multiple registries require authentication configuration
   - Pull policy affects startup time vs. security

2. **Container Naming**:
   ```bash
   docker run --name web-server nginx
   ```
   - MUST be unique per Docker host
   - Enables referencing in other commands
   - Network DNS resolution uses container name

3. **Resource Constraints**:
   ```bash
   docker run --cpus="1.5" --memory="512m" \
              --memory-swap="1024m" nginx
   ```
   - `--cpus`: CPU share (fractional allowed)
   - `--memory`: Hard memory limit (SIGKILL on exceed)
   - `--memory-swap`: Total memory + swap limit
   - No constraint = resource starvation risk in production

4. **Storage Configuration**:
   ```bash
   docker run -v myvol:/data \
              -v /host/path:/container/path:ro \
              --tmpfs /tmp:size=64m nginx
   ```
   - `-v` for volumes (decoupled) or bind mounts (host paths)
   - Named volumes preferred for production
   - `:ro` for read-only mounts (limiting blast radius)

5. **Networking**:
   ```bash
   docker run --network mynet --name app \
              -p 8080:80 -e BACKEND_URL=http://db:5432 nginx
   ```
   - `--network`: Attach to custom bridge or overlay
   - `-p`: Map ports (host:container)
   - Environment variables passed to container

6. **Lifecycle Hooks**:
   ```bash
   docker run --health-cmd="curl localhost/health" \
              --health-interval=10s \
              --health-retries=3 \
              --health-start-period=30s nginx
   ```
   - Health checks enable automatic failure detection
   - `--health-start-period`: grace period before checks start
   - Orchestrators use health status for restart decisions

---

#### `docker start` / `docker stop` - Manage Running State

**Signatures**:
```bash
docker start [OPTIONS] CONTAINER [CONTAINER...]
docker stop [OPTIONS] CONTAINER [CONTAINER...]
```

**Lifecycle considerations:**

```
Created → Running → Paused → Running → Stopped → Removed
    ↑                                      ↑
    └──── docker create                   └──── docker stop
    └─ docker start ────────────────────────────┘
```

**`docker start` behavior:**
- Restarts container using original `docker run` configuration
- Cannot change resource limits, volumes, or networking
- Original container layer persists (data from before stop is retained)

```bash
docker stop -t 30 myapp  # 30-second graceful shutdown period
```

**`docker stop` behavior:**
- Sends SIGTERM to PID 1; gives grace period to shutdown
- `-t`: Timeout before forcibly killing (SIGKILL)
- 10-second default often insufficient for databases
- Data in container layer is preserved; lost only on `docker rm`

**SRE considerations:**
- Ensure applications handle SIGTERM properly (cleanup connections, flush caches)
- Monitor stop duration; timeouts indicate graceful shutdown issues
- Stopped containers still consume disk (image layers, container layer); regular cleanup needed

---

#### `docker restart` - Graceful Container Restart

**Signature**:
```bash
docker restart [OPTIONS] CONTAINER [CONTAINER...]
```

**Equivalent to**:
```bash
docker stop CONTAINER && docker start CONTAINER
```

**Use cases:**
- Configuration reload that requires process restart
- Clearing in-memory leaks without losing container-layer persistence
- Controlled restart during maintenance windows

**Does NOT:**
- Modify storage/network configuration
- Clear container layer (ephemeral state retained)
- Update application code (requires new image)

---

#### `docker pause` / `docker unpause` - Suspend Execution

**Signatures**:
```bash
docker pause CONTAINER
docker unpause CONTAINER
```

**Technical mechanism:**
- Uses cgroup freezer to suspend all processes
- Container "frozen" in memory; minimal CPU overhead
- Network connections remain open but unresponsive

**Use cases:**
- Checkpoint/restore workflows (CRIU integration)
- Preventing container from consuming CPU during resource constraints
- Temporary service degradation without full restart

**Caution:**
- Paused containers don't handle signals
- External systems may timeout waiting for response
- Not suitable for production high-availability scenarios

---

#### `docker rm` - Delete Container

**Signature**:
```bash
docker rm [OPTIONS] CONTAINER [CONTAINER...]
```

**Critical behavior:**
```bash
docker rm myapp                    # Error: running container
docker rm -f myapp                 # Force kills and removes
docker rm -f -v myapp              # Also removes anonymous volumes
```

**What gets deleted:**
- ✅ Container metadata
- ✅ Container layer (ephemeral filesystem)
- ❌ Named volumes (explicitly named with `-v` flag)
- ❌ Bind mounts (still exist on host)

**SRE implications:**
- Anonymous volumes (-v without name) are deleted; leaked storage possible
- Container removal is data loss if no external volumes
- Automation should verify persistence mechanisms before cleanup

---

### Container Inspection & Monitoring

#### `docker exec` - Execute Commands in Running Container

**Signature**:
```bash
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

**Common scenarios:**
```bash
docker exec -it mydb bash                    # Interactive shell
docker exec -u postgres mydb psql -U postgres  # Different user
docker exec -w /app myapp python -m pytest   # Set working directory
```

**DevOps anti-patterns:**
- ❌ Using `exec` to modify running containers (configuration drift)
- ❌ Assuming exec output in CI/CD pipelines (container may not have shell tools)
- ❌ Relying on exec for debugging instead of proper logging

**Proper use:**
- One-off maintenance tasks (database migrations, cache flushes)
- Debugging (examining logs, checking configuration)
- Extracting data for backup/analysis

**Implementation detail:**
- Creates new process in container's namespaces
- Inherits environment from container config
- Does NOT create new container; cannot persist changes

---

#### `docker logs` - Extract Container Output

**Signature**:
```bash
docker logs [OPTIONS] CONTAINER
```

**Production usage:**
```bash
docker logs -f myapp                      # Follow output (tail -f)
docker logs --tail 100 myapp              # Last 100 lines
docker logs --since 2026-03-07T10:00:00 myapp  # Time filtering
docker logs --until 2026-03-07T12:00:00 myapp  # Upper bound
```

**Log driver consideration:**
- Default `json-file` driver stores logs locally (unbounded growth)
- Production should use log drivers (splunk, awslogs, etc.)
- Configure log rotation: `--log-opt max-size=100m --log-opt max-file=10`

**Limitations:**
- Only captures stdout/stderr (PID 1 output)
- Logs written directly to files in container not captured
- No structured logging without application logging library

---

#### `docker inspect` - Deep Container State Inspection

**Signature**:
```bash
docker inspect [OPTIONS] CONTAINER [CONTAINER...]
```

**Returns detailed JSON of:**

```bash
docker inspect myapp | jq '.[0].State'       # Running state
docker inspect myapp | jq '.[0].Mounts'      # Volumes and bind mounts
docker inspect myapp | jq '.[0].NetworkSettings'  # Network config
docker inspect myapp | jq '.[0].Config.Cmd'  # Original command
```

**Useful queries (SRE debugging):**
```bash
# Check if container is healthy
docker inspect --format='{{.State.Health.Status}}' myapp

# Verify volume attachments
docker inspect myapp | jq '.[0].Mounts[] | {Source, Destination, Mode}'

# Get container resource limits
docker inspect myapp | jq '.[0].HostConfig | {Memory, MemorySwap, CpuQuota}'

# Connected networks
docker inspect myapp | jq '.[0].NetworkSettings.Networks'
```

**Common fields:**
- `.State`: Running, Paused, Exited, Dead status + exit code + error
- `.Mounts`: Volume and bind mount configuration
- `.HostConfig.Resources`: Memory, CPU limits
- `.NetworkSettings`: IP, ports, gateway, DNS

---

#### `docker top` - Process Listing

**Signature**:
```bash
docker top CONTAINER [ps OPTIONS]
```

**Usage:**
```bash
docker top myapp                              # ps aux equivalent
docker top myapp -eo user,pid,cmd             # Custom columns
```

**Debugging scenarios:**
- Verify application started with correct PID 1
- Check for zombie processes (orphaned children)
- Identify unexpected background processes

**Limitations:**
- Snapshot only; not real-time monitoring
- Does not show resource usage (use `stats` instead)

---

#### `docker stats` - Real-Time Resource Usage

**Signature**:
```bash
docker stats [OPTIONS] [CONTAINER...]
```

**Monitoring usage:**
```bash
docker stats                                    # All containers
docker stats myapp nginx postgres               # Specific containers
docker stats --no-stream                        # Single snapshot

# Prometheus-compatible output
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

**Metrics provided:**
- CPU %: Percentage of limit (if set)
- Memory: Absolute usage + percentage of limit
- I/O: Read/write bytes (block device, not filesystem)
- Network: Bytes in/out

**Caution:**
- Metrics read from cgroup counters (accurate)
- I/O metrics include all block devices (image layers + volumes)
- No breakdown of per-filesystem usage

---

#### `docker attach` - Connect to Container Output

**Signature**:
```bash
docker attach [OPTIONS] CONTAINER
```

**Behavior:**
```bash
docker attach myapp    # Connects to container's stdout/stderr
                      # Can send input if container's stdin open
                      # Ctrl+C may stop container (if not detached)
```

**Differs from `logs`:**
- `logs`: Historical output only
- `attach`: Real-time stream, can interact

**Use case:**
- Debugging running container interactively
- NOT suitable for automation (no history)

---

### Container Modification & Export

#### `docker commit` - Create Image from Container

**Signature**:
```bash
docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
```

**Usage scenario:**
```bash
docker run -it ubuntu:20.04
# Inside container: apt-get install nginx, configure, etc.
exit

docker commit -m "Added nginx" -a "DevOps Team" ubuntu nginx:custom
```

**Mechanism:**
1. Reads container layer (changes made inside container)
2. Creates new image layer
3. Tags with REPOSITORY:TAG

**SRE anti-pattern:**
- ❌ Using `commit` as deployment method (no version control, non-reproducible)
- ❌ Committing containers with secrets baked in
- ❌ Bypassing Dockerfile build process

**Proper use:**
- Occasionally capturing state for backup
- Testing Docker layer mechanics
- Exporting container for archive/analysis

---

#### `docker cp` - Copy Files Between Host and Container

**Signature**:
```bash
docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH
docker cp [OPTIONS] SRC_PATH CONTAINER:DEST_PATH
```

**Usage:**
```bash
docker cp myapp:/var/log/app.log ./local-backup/    # Export logs
docker cp ./config.yaml myapp:/etc/config/           # Inject config
```

**Limitations:**
- Container must exist (can be stopped)
- Copy is file-by-file (not streaming/efficient)
- Not suitable for large datasets (use volumes instead)

**Proper use:**
- Extracting logs, configuration for analysis
- Injecting config files into containers during troubleshooting
- Emergency data extraction when volumes not attached

---

#### `docker diff` - Inspect Layer Changes

**Signature**:
```bash
docker diff CONTAINER
```

**Output markers:**
- `A` = Added files/directories
- `D` = Deleted files/directories
- `C` = Changed files/directories

**Usage:**
```bash
docker diff myapp | head -20

# Sample output:
# C /etc/hosts
# C /var/cache
# A /var/log/app.log
# D /tmp/build-artifacts
```

**DevOps use case:**
- Audit changes made via compromised container (forensics)
- Verify expected modifications before commit
- Implement layer size estimation

**Understanding impact:**
- Large output = many files modified; possibly poor image layer design
- Temporary files added to layer = disk bloat

---

#### `docker export` - Export Filesystem

**Signature**:
```bash
docker export [OPTIONS] CONTAINER
```

**Usage:**
```bash
docker export myapp | gzip > myapp-backup.tar.gz
docker export myapp > myapp.tar

# Extract to verify
tar -tzf myapp.tar | head -20
```

**What's exported:**
- ✅ Merged filesystem (all layers + container layer combined)
- ✅ File contents, permissions, ownership
- ❌ Image metadata, environment variables, exposed ports
- ❌ Volumes (only mounted paths within container visible)

**Use cases:**
- Full container filesystem backup (rarely needed)
- Archival for compliance/forensics
- Bare-metal migration (extract, modify, redeploy)

**Difference from `docker save`**:
- `export`: Container filesystem only
- `save`: Entire image (layers, metadata, history)

---

#### `docker import` - Create Image from Tarball

**Signature**:
```bash
docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
```

**Usage:**
```bash
docker import myapp-backup.tar myapp:restored
```

**Mechanism:**
1. Reads tarball (created by export or from other sources)
2. Creates single-layer image (no layer history preserved)
3. Tags with REPOSITORY:TAG

**Implications:**
- Imported images have NO layer history (all changes in single layer)
- Cannot use `docker history` to see what changed
- Less efficient than Dockerfile-built images (no layer caching)

**Proper use:**
- Recovering from exported containers (rare)
- Creating images from non-Docker sources (VM images, rootfs tarballs)
- NOT suitable for regular image distribution

---

### Lifecycle State Transitions

**Complete state machine:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CONTAINER LIFECYCLE                             │
└─────────────────────────────────────────────────────────────────────────┘

                    docker create
                          ↓
                   [Created] ← Image layers loaded, container layer created
                          ↓
                   docker start
                          ↓
                   [Running] ← Processes executing, stdout/stderr active
                    ↙     ↘
          docker pause    docker stop (SIGTERM, graceful)
             ↓              ↓  ↓ (timeout → SIGKILL)
         [Paused]       [Stopping]
             ↓              ↓
          docker unpause   [Stopped] ← Process terminated, exit code recorded
             ↓
          [Running]        ↓ docker restart/start
                           ↓
                    [Running] ← Same container, new process
                           
         ┌─────────────────┴─────────────────┬──────────────────┐
         │                                   │                  │
      docker rm                         docker rm -f        (system cleanup)
         │                                   │                  │
         ↓                                   ↓                  ↓
    [Removed] ← Data in container       [Removed] ← (Removed) ← [Dead]
       (if stopped)          layer lost      (forced)    (exit code preserved
                                                         briefly then removed)
```

**Exit codes:**
- `0`: Normal termination (healthy exit)
- `1-255`: Application error code
- `137`: SIGKILL received (timeout, resource exceeded)
- `143`: SIGTERM received (graceful shutdown requested)

**Key transitions for DevOps:**
1. **Running → Stopped (graceful)**: Critical for data integrity (databases, caches)
2. **Stopped → Running (restart)**: Container layer persists; previous state retained
3. **Running → Removed**: Irreversible; data loss if no external volumes

---

## Docker Storage

### Storage Driver Architecture

#### Internal Working Mechanism

Docker storage drivers implement **Union Filesystems** using kernel modules to create layered, copy-on-write storage. The mechanism operates in three layers:

```
┌──────────────────────────────────────────────────────────────────────┐
│ User Space (docker daemon, containers)                               │
├──────────────────────────────────────────────────────────────────────┤
│ Union Mount Layer (OverlayFS, AUFS, devicemapper, btrfs)            │
│ • Implements CoW semantics                                           │
│ • Stacks multiple filesystems                                        │
│ • Intercepts read/write operations                                   │
├──────────────────────────────────────────────────────────────────────┤
│ Device Mapper / VFS Layer (kernel module)                            │
│ • Block device management                                            │
│ • Inode caching                                                      │
│ • Filesystem-specific operations                                     │
├──────────────────────────────────────────────────────────────────────┤
│ Linux Kernel (VFS, block layer, device drivers)                     │
├──────────────────────────────────────────────────────────────────────┤
│ Storage Backend (ext4, xfs, btrfs filesystem or block device)       │
└──────────────────────────────────────────────────────────────────────┘
```

#### Copy-on-Write (CoW) Semantics

When a container modifies a file:

1. **Read**: File retrieved from lowest layer containing it
   ```
   Read /app/config.json
      ├─ Check container layer → Not found
      ├─ Check image layer 4 → Not found
      ├─ Check image layer 3 → Found ✓
      └─ Return from layer 3
   ```

2. **Modify**: File copied to container layer, then modified
   ```
   Write /app/config.json
      ├─ Register file in container layer
      ├─ Copy entire file from layer 3 to container layer
      ├─ Modify copy in container layer
      └─ Result: Original in layer 3 unchanged, new version in container layer
   ```

3. **Delete**: Whiteout file in container layer
   ```
   Delete /app/config.json
      ├─ Create whiteout marker in container layer
      ├─ File from layer 3 remains intact
      ├─ When reading: Check container layer first, find whiteout
      └─ Result: File appears deleted to container
   ```

**Performance implication**: First write to large file incurs full-file copy latency.

#### Architecture Role

Storage drivers determine:
- **I/O Performance**: How fast reads/writes execute through layers
- **Memory Overhead**: Caching strategy affects container density
- **Disk Efficiency**: CoW implementation affects duplicated data
- **Snapshot Capabilities**: Whether storage-level snapshots available
- **Compatibility**: Supported filesystems and kernel versions

---

### Volumes: Persistent Data Management

#### Textual Deep Dive

**What they are:**
Named or anonymous storage decoupled from container lifecycle, managed by Docker daemon. Stored in Docker's managed directory (`/var/lib/docker/volumes/`) or on external storage drivers.

**How they work:**
```
Docker creates a volume:
    ├─ Creates directory: /var/lib/docker/volumes/<volume-id>/_data
    ├─ Registers volume metadata in Docker daemon
    └─ Makes path available to container mounts

Container mounts volume:
    ├─ Kernel mount: /var/lib/docker/volumes/<volume-id>/_data → /app/data
    └─ Inside container: /app/data points to volume data
    
Data persistence:
    ├─ Container stops/restarts: Data retained
    ├─ Container deleted: Volume persists (unless -v flag on rm)
    ├─ Volume deleted: docker volume rm <volume-id>
    └─ Data in volume: Gone permanently
```

**Named vs Anonymous:**
```bash
# Named volume (recommended for production)
docker run -v my-db-data:/var/lib/postgresql/data postgres:13

# Anonymous volume (temporary data, not tracked by name)
docker run -v /tmp/cache postgres:13

# List only named volumes
docker volume ls

# Check volume location
docker volume inspect my-db-data | jq '.[0].Mountpoint'
```

#### Production Usage Patterns

**Pattern 1: Database Data Persistence**
```bash
# Production PostgreSQL with persistent volume
docker run \
  --name postgres-prod \
  -v postgres-data:/var/lib/postgresql/data \
  -v postgres-wal:/var/lib/postgresql/wal \
  -e POSTGRES_PASSWORD=secret \
  -e PGDATA=/var/lib/postgresql/data/pgdata \
  --health-cmd="pg_isready -U postgres" \
  --health-interval=10s \
  postgres:13
```

**Pattern 2: Shared Data Between Containers**
```bash
# Create shared volume
docker volume create shared-config

# Writer container
docker run --name writer \
  -v shared-config:/shared:rw \
  alpine sh -c "echo 'app_version=1.2.3' > /shared/config"

# Reader containers
docker run --name app1 \
  -v shared-config:/etc/app:ro \
  myapp:latest

docker run --name app2 \
  -v shared-config:/etc/app:ro \
  myapp:latest
```

**Pattern 3: Backup and Restore**
```bash
# Backup volume to tar
docker run --rm \
  -v postgres-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/db-backup.tar.gz -C /data .

# Restore volume from tar
docker volume create postgres-data-restored

docker run --rm \
  -v postgres-data-restored:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/db-backup.tar.gz -C /data
```

#### DevOps Best Practices

1. **Name volumes consistently**:
   ```bash
   # Bad: Anonymous, untrackable
   docker run -v /data/app postgres
   
   # Good: Named, identifiable
   docker run -v app-postgres-data:/data/app postgres
   ```

2. **Use read-only mounts when possible**:
   ```bash
   # Config volume (read-only for app container)
   docker run -v app-config:/etc/app:ro myapp
   ```

3. **Implement backup strategy**:
   ```bash
   # Scheduled backup script (cron job on host)
   #!/bin/bash
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   for volume in $(docker volume ls -q); do
     docker run --rm \
       -v $volume:/data \
       -v /backup:/backup \
       alpine tar czf /backup/${volume}-${TIMESTAMP}.tar.gz -C /data .
   done
   ```

4. **Monitor volume usage**:
   ```bash
   # Check volume sizes
   docker system df

   # Detailed volume usage
   du -sh /var/lib/docker/volumes/*/_data

   # Alert on capacity
   for vol in $(docker volume ls -q); do
     size=$(du -s /var/lib/docker/volumes/${vol}/_data | awk '{print $1}')
     if [ $size -gt 5242880 ]; then  # > 5GB
       echo "ALERT: Volume ${vol} exceeds 5GB"
     fi
   done
   ```

5. **Clean up unused volumes**:
   ```bash
   # List dangling volumes (not used by any container)
   docker volume ls -f dangling=true

   # Remove dangling volumes
   docker volume prune --filter --force
   ```

#### Common Pitfalls

1. **Anonymous volumes leak storage**:
   ```bash
   # Pitfall: Anonymous volume survives rm without -v
   docker run -v /tmp/data myapp    # Creates anonymous volume
   docker rm myapp                  # Volume NOT removed
   docker system df                 # Shows unused volume
   
   # Fix: Use -v on rm
   docker rm -v myapp               # Removes anonymous volumes
   ```

2. **Permissions issues**:
   ```bash
   # Pitfall: Volume created as root, app runs as non-root
   docker run -v app-data:/data myapp
   # Inside container, app user (1000:1000) can't write to /data (999:999)
   
   # Fix: Match ownership or run as correct user
   docker run --user 1000:1000 \
     -v app-data:/data \
     myapp
   ```

3. **Capacity planning neglected**:
   ```bash
   # Pitfall: Volumes grow unbounded
   # Log files, cache, uploads not cleaned up
   # Disk fills, container crashes with EIO
   
   # Fix: Monitor and implement retention policies
   docker exec postgres-prod \
     pg_dump -U postgres > /data/backup/$(date +%Y%m%d).sql
   # Keep only last 7 days
   find /data/backup -mtime +7 -delete
   ```

4. **Backup strategy missing entirely**:
   ```bash
   # Pitfall: "I'll back it up later"
   # Disk failure → Data gone forever
   
   # Fix: Automated backups with verification
   # docker volume export → cloud storage
   # Regular restore testing
   ```

---

### Bind Mounts: Host Directory Integration

#### Textual Deep Dive

**What they are:**
Direct mounting of host filesystem path into container, providing access to arbitrary host directories.

**How they work:**
```
Host filesystem: /srv/app/config
                      ↓ (kernel mount)
Bind mount: /app/config → points directly to /srv/app/config
                      ↓
Inside container: /app/config reads/writes directly to host /srv/app/config
```

**Key differences from volumes:**
| Aspect | Bind Mount | Volume |
|--------|-----------|--------|
| **Storage location** | Any host path | /var/lib/docker/volumes/ |
| **Portability** | Host-specific (breaks on different hosts) | Portable (works across hosts with volume driver) |
| **Permission management** | SELinux/AppArmor complications | Docker manages permissions |
| **Backup** | Manual, host-level | Docker volume commands available |
| **Performance** | Direct I/O, less overhead | Slight overhead from Union FS |
| **Hot reload** | Files change on host → visible in container | Requires restart to see changes |

#### Production Usage Patterns

**Pattern 1: Development Environment (hot reload)**
```bash
# Flask app with live code reloading
docker run \
  -v $(pwd)/app:/app \
  -v $(pwd)/requirements.txt:/requirements.txt \
  -p 5000:5000 \
  -e FLASK_ENV=development \
  python:3.9 \
  bash -c "pip install -r /requirements.txt && flask run --host=0.0.0.0"
```

**Pattern 2: Configuration Injection**
```bash
# Inject host-specific configs
docker run \
  -v /etc/app/config.yaml:/app/config.yaml:ro \
  -v /etc/app/secrets.env:/app/.env:ro \
  myapp:latest
```

**Common anti-pattern**: Using bind mounts for production
```bash
# DON'T DO THIS IN PRODUCTION
docker run -v /srv/data:/data myapp    # Path specific to one host!
# Container can't be moved to different host
# Same path may not exist elsewhere
# Use volumes instead
```

#### DevOps Best Practices

1. **Development-only, clearly marked**:
   ```bash
   # Add comments to prevent accidental production use
   docker run \
     --label="environment=development" \
     -v $(pwd):/app \
     -p 8000:8000 \
     myapp
   ```

2. **Use read-only when possible**:
   ```bash
   # Prevent container from modifying config
   docker run \
     -v $(pwd)/app:/app:ro \
     python:3.9
   ```

3. **Document mount paths clearly**:
   ```bash
   # Create docker-compose.yml documenting mounts
   # Instead of complex shell commands
   services:
     app:
       image: myapp:latest
       volumes:
         - ./app:/app              # Source code
         - ./data:/tmp/data:rw     # Test data
         - /etc/localtime:/etc/localtime:ro  # Time sync
   ```

#### Common Pitfalls

1. **PATH assumptions break on different systems**:
   ```bash
   # Pitfall: Absolute paths specific to one machine
   docker run -v /home/john/myproject:/app myapp
   # Doesn't work on colleague's computer (different path)
   # Doesn't work in CI/CD pipeline
   
   # Fix: Use relative paths with $(pwd)
   docker run -v $(pwd):/app myapp
   ```

2. **Permission nightmares with SELinux/AppArmor**:
   ```bash
   # Pitfall: Container can't write to bind mount
   # SELinux denies access: "permission denied"
   
   # Fix: Add :z (share) or :Z (private) flag
   docker run -v $(pwd):/app:z myapp
   # :z = shared, SELinux allows container access
   # :Z = private, SELinux isolates to this container
   ```

3. **File descriptor leaks on rapid restart**:
   ```bash
   # Pitfall: Rapidly restarting container with bind mounts
   # File handles don't fully clean up
   # "too many open files" error
   
   # Fix: Add delay between restarts or use orchestrator
   # Orchestrators handle file handle cleanup
   ```

---

### tmpfs: In-Memory Storage

#### Textual Deep Dive

**What it is:**
Temporary filesystem stored entirely in RAM, offering memory-speed I/O without disk latency. Data lost on container restart.

**How it works:**
```
docker run --tmpfs /tmp:size=256m myapp

Inside container:
/tmp as seen by app ← backed by RAM (not disk)
├─ Read: Memory speed (~1-2 μs latency)
├─ Write: Memory speed (~1-2 μs latency)
└─ On container stop: Data discarded

Host perspective:
Memory usage increases by tmpfs size
Container stops → Memory released to kernel
```

**Technical mechanism:**
```
┌──────────────────────────────────────┐
│ Container's tmpfs /tmp               │
│ (RAM-backed filesystem)              │
│ ├─ Sequential read: >1 GB/s          │
│ ├─ Random read: >100k IOPS           │
│ └─ No disk I/O, pure memory ops      │
├──────────────────────────────────────┤
│ Host's physical RAM (tempfile_mode)  │
│ ├─ Allocated from cgroups memory     │
│ ├─ Counts against container limit    │
│ └─ Returned on container exit        │
└──────────────────────────────────────┘
```

#### Production Usage Patterns

**Pattern 1: Cache Storage (ephemeral)**
```bash
# Redis-like cache with tmpfs
docker run \
  --name cache \
  --tmpfs /cache:size=1g \
  -p 6379:6379 \
  -e REDIS_DIR=/cache \
  redis:6 redis-server --dir /cache --logfile ""
```

**Pattern 2: Temporary Session Storage**
```bash
# Web app with ephemeral session storage
docker run \
  --tmpfs /tmp:size=512m,noexec,nosuid \
  --tmpfs /var/run:size=64m \
  -p 8080:8080 \
  mywebapp:latest
```

**Pattern 3: Secure credential handling**
```bash
# Load secrets into tmpfs, not persistent storage
docker run \
  --tmpfs /run/secrets:size=64m,noexec,nosuid,mode=0700 \
  -v /host/encrypted/secrets:/encrypted:ro \
  -e SECRETS_PATH=/run/secrets \
  myapp \
  bash -c "
    # Decrypt secrets into tmpfs
    gpg -d /encrypted/creds.gpg > /run/secrets/creds
    chmod 600 /run/secrets/creds
    # Run app with secrets in memory
    exec /app/start.sh
  "
```

**Pattern 4: Build cache (Docker builds)**
```bash
# Dockerfile using tmpfs for build artifacts
FROM ubuntu:20.04

RUN --mount=type=tmpfs,target=/build \
    cd /build && \
    wget https://source.example.com/large-file.tar.gz && \
    tar xzf large-file.tar.gz && \
    ./configure && \
    make && \
    make install
```

#### DevOps Best Practices

1. **Size tmpfs appropriately**:
   ```bash
   # Memory limit 2GB, tmpfs 1.5GB
   # Ensures enough headroom for app's actual memory
   docker run \
     --memory=2g \
     --tmpfs /tmp:size=1536m \
     myapp
   ```

2. **Combine with security flags**:
   ```bash
   # Prevent execution, setuid bits
   docker run \
     --tmpfs /tmp:size=512m,noexec,nosuid,nodev \
     myapp
   ```

3. **Monitor tmpfs usage**:
   ```bash
   # Inside container
   df -h /tmp

   # From host
   docker stats myapp | grep -i memory
   # Shows total memory; tmpfs counts against limit
   ```

4. **Plan for OOM when tmpfs fills**:
   ```bash
   # If tmpfs fills, writes fail (ENOSPC)
   # App must handle gracefully
   docker run \
     --tmpfs /tmp:size=256m \
     --oom-kill-disable=true \  # Prevent hard kill
     --memory=1g \
     myapp
   ```

#### Common Pitfalls

1. **Assuming tmpfs survives restart**:
   ```bash
   # Pitfall: Store important cache in tmpfs
   docker run --tmpfs /cache myapp
   # Container restarts → /cache empty
   # "cold start" performance hit
   
   # Fix: Use tmpfs for truly ephemeral data
   # Caches should be warm via volume init
   ```

2. **Over-allocating memory to tmpfs**:
   ```bash
   # Pitfall: Container memory limit 512MB, tmpfs 400MB
   # Application + tmpfs exceed limit
   # OOMKiller terminates container
   
   # Fix: tmpfs size << memory limit
   # Leave headroom for app heap/stack
   docker run \
     --memory=1g \
     --tmpfs /tmp:size=256m \  # 25% of limit
     myapp
   ```

3. **Tmpfs not visible in volume backups**:
   ```bash
   # Pitfall: Backup strategy doesn't account for tmpfs
   # "Important" cache data lost on restart
   
   # Fix: If data is important, it shouldn't be in tmpfs
   # Use volumes for anything that must persist
   ```

---

### Storage Driver Deep Dive

#### overlay2 (Recommended Default)

**Internal mechanism:**
Uses OverlayFS (kernel module) for efficient Union Mount implementation.

```
┌────────────────────────────────────────────────────────┐
│ Container Layer (writable)                             │
│ /var/lib/docker/overlay2/<id>/diff                    │
│ ├─ Only modifications stored here (CoW logic)          │
│ └─ Smallest footprint of all container layers         │
├────────────────────────────────────────────────────────┤
│ Merged View (OverlayFS virtual layer)                 │
│ └─ Union of all layers below, as seen by container    │
├────────────────────────────────────────────────────────┤
│ Image Layers (read-only)                              │
│ /var/lib/docker/overlay2/<id>/diff                    │
│ ├─ Layer N (FROM ubuntu)                              │
│ ├─ Layer N-1 (RUN apt-get install)                    │
│ ├─ Layer N-2 (COPY app)                               │
│ └─ Layer N-3 (Base image)                             │
├────────────────────────────────────────────────────────┤
│ Work Directory (OverlayFS internal)                    │
│ /var/lib/docker/overlay2/<id>/work                    │
│ └─ Staging area for CoW operations                    │
└────────────────────────────────────────────────────────┘
```

**Performance characteristics:**
```
Metric                  Value           Use Case Implication
──────────────────────────────────────────────────────────
Sequential read         ~500 MB/s       Good for log files, backups
Sequential write        ~300 MB/s       Good for streaming data
Random read (4K)        ~50k IOPS       Container startup
Random write (4K)       ~20k IOPS       Database writes
First-write penalty     File size       Large files: expensive first write
Layer count limit       128 layers      Rarely hit in practice
─────────────────────────────────────────────────────────
```

**Practical usage:**
```bash
# Configure overlay2 as storage driver in daemon.json
cat > /etc/docker/daemon.json << 'EOF'
{
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

systemctl restart docker

# Verify driver
docker info | grep -A 5 "Storage Driver"
```

**Best for:**
- General-purpose workloads
- Linux kernel 4.0+
- Most modern distributions
- High container density

**Avoid for:**
- Many small files (no inode limit, but slow with thousands of small files)
- Systems without OverlayFS support

---

#### devicemapper (Legacy, Density-Optimized)

**Internal mechanism:**
Uses Linux device-mapper with thin provisioning snapshots.

```
┌────────────────────────────────────────────────────────┐
│ Container Thin Snapshot (writable)                     │
│ └─ Block-device level snapshot of image               │
├────────────────────────────────────────────────────────┤
│ Image Base Snapshot (read-only)                        │
│ └─ Block-device snapshot of full image                │
├────────────────────────────────────────────────────────┤
│ Device-Mapper Pool (thin provisioning)                │
│ ├─ Allocated blocks on demand                         │
│ ├─ Shared blocks between snapshots                    │
│ └─ CoW happens at block level (more efficient)        │
├────────────────────────────────────────────────────────┤
│ Storage (loop device or physical block device)        │
│ /var/lib/docker/devicemapper/devicemapper/data       │
│ └─ Sparse file or partition                           │
└────────────────────────────────────────────────────────┘
```

**Performance characteristics:**
```
Metric                  Value           Comparison
──────────────────────────────────────────────────
Sequential read         ~200 MB/s       Slower than overlay2
Random read (4K)        ~80k IOPS       Better than overlay2
Random write (4K)       ~30k IOPS       Better than overlay2
First-write penalty     Block size (4K) Much lower than overlay2
Snapshot creation       ~100μs          Near-instant
Block device limit      2^31 blocks     Supports large data
─────────────────────────────────────────────
```

**Practical usage (legacy):**
```bash
# NOT RECOMMENDED for new deployments
# Included for reference only

# loopback mode (very poor for production)
cat > /etc/docker/daemon.json << 'EOF'
{
  "storage-driver": "devicemapper",
  "storage-opts": [
    "dm.basesize=10G",
    "dm.loopmountpoint=/var/lib/docker/devicemapper"
  ]
}
EOF

# direct-lvm mode (better)
# Requires pre-configured LVM volumes (complex setup)
```

**Best for:**
- Very high container density
- Many small-file workloads (block-level CoW efficient)
- Restricted kernels without OverlayFS

**Avoid for:**
- Ease of setup (complex LVM configuration)
- Performance-critical workloads (sequential I/O slower)
- New implementations (deprecated in Docker 19.03+)

---

#### btrfs (Filesystem-Level)

**Internal mechanism:**
Leverages btrfs filesystem's native subvolume and snapshot capabilities.

**Performance characteristics:**
```
Metric                  Value           Use Case
──────────────────────────────────────────────
Snapshot creation       ~1μs            Near-free
CoW operation           Filesystem      Efficient for btrfs trees
RAM overhead            Low             Minimal metadata
Compression            Available        Can reduce disk usage
─────────────────────────────────────────────
```

**Practical usage (rare):**
```bash
# Only viable if storage is btrfs
# mkfs.btrfs /dev/sdX
# mount -t btrfs /dev/sdX /var/lib/docker

docker daemon \
  --storage-driver=btrfs \
  --storage=/var/lib/docker
```

**Best for:**
- Systems with btrfs storage
- Environments requiring native compression
- Zero-downtime snapshots

**Avoid for:**
- Most systems (overlay2 more stable)
- Stability concerns with btrfs (RAID configurations)

---

#### AUFS (Deprecated)

**Status**: No longer supported (Docker 19.03+)

---

### Data Management Strategies

#### Strategy 1: Stateless Container Assumption

**Principle**: Containers are ephemeral; all persistent data external to container image.

```bash
# Bad: Data in image
FROM ubuntu:20.04
RUN mkdir -p /app/data && echo "config" > /app/data/config.txt
ENTRYPOINT ["/app/start.sh"]
# Problem: Config baked into image, can't update without rebuild

# Good: Data external via volumes
FROM ubuntu:20.04
ENTRYPOINT ["/app/start.sh"]

# Run with volume
docker run \
  -v app-config:/app/data \
  -v app-logs:/var/log/app \
  myapp:latest
```

**Production pattern:**
```bash
#!/bin/bash
# Init volume with initial data if not present

docker volume create app-config

# One-time init
docker run --rm \
  -v app-config:/data \
  myapp:latest \
  sh -c 'if [ ! -f /data/config.yaml ]; then cp /app/default-config.yaml /data/config.yaml; fi'

# Run actual app (always mounts external volume)
docker run \
  -v app-config:/app/config:ro \
  -v app-logs:/var/log/app \
  myapp:latest
```

#### Strategy 2: Graceful Shutdown & Data Integrity

**Principle**: Ensure data consistency before container termination.

```bash
#!/bin/bash
# Handle SIGTERM gracefully

# App wrapper script
trap cleanup SIGTERM

cleanup() {
  echo "Shutting down..."
  # Flush caches to disk
  redis-cli BGSAVE
  # Close database connections
  kill $APP_PID
  wait $APP_PID
  exit 0
}

exec /app/start.sh &
APP_PID=$!
wait $APP_PID
```

**Docker configuration:**
```bash
# Docker stop sends SIGTERM, waits 10 seconds
# Increase timeout in production for databases
docker run \
  --stop-timeout=30 \
  -v postgres-data:/var/lib/postgresql/data \
  postgres:13
```

#### Strategy 3: Volume Sharing Between Containers

**Pattern: Multi-container coordination via shared volumes**

```bash
# Controller container writes to shared volume
docker run -d \
  --name controller \
  -v shared-data:/output \
  mycontroller:latest

# Worker containers read from shared volume
for i in {1..3}; do
  docker run -d \
    --name worker-$i \
    -v shared-data:/input:ro \
    myworker:latest
done
```

#### Strategy 4: Backup & Restore workflow

```bash
#!/bin/bash
# Automated backup of volumes

backup_volume() {
  local volume=$1
  local backup_dir=$2
  local timestamp=$(date +%Y%m%d_%H%M%S)
  
  docker run --rm \
    -v "$volume":/data \
    -v "$backup_dir":/backup \
    alpine \
    tar czf "/backup/${volume}-${timestamp}.tar.gz" -C /data .
  
  # Keep only last 7 days
  find "$backup_dir" -name "${volume}-*.tar.gz" -mtime +7 -delete
}

# Backup important volumes
for volume in postgres-data redis-data app-config; do
  backup_volume "$volume" /backups/volumes
done

# Replicate to S3 (example)
aws s3 sync /backups/volumes s3://backup-bucket/docker-volumes/
```

---

### Persistent Patterns & Anti-Patterns

#### Anti-Pattern 1: Container as Database

```bash
# ANTI-PATTERN: Data stored in container layer
docker run \
  --name mydb \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:5.7

# Data at: /var/lib/mysql (container layer)
# Container deleted → Data lost
# Container moved to different host → Can't find data
```

**Solution:**
```bash
# CORRECT: Persistent volume for data
docker volume create mysql-data

docker run \
  --name mydb \
  -v mysql-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:5.7
```

#### Anti-Pattern 2: Hardcoded Paths in Bind Mounts

```bash
# ANTI-PATTERN: Host-specific absolute path
docker run \
  -v /home/developer/project:/app \
  myapp:latest

# Fails on different machines
# Fails in CI/CD pipeline
# Not reproducible
```

**Solution:**
```bash
# CORRECT: Relative path with $(pwd)
docker run \
  -v $(pwd):/app \
  myapp:latest

# Works everywhere
# Reproducible in CI/CD
# Clear intent
```

#### Anti-Pattern 3: Volumes Without Retention Policy

```bash
# ANTI-PATTERN: Log volumes grow unbounded
docker run \
  -v app-logs:/var/log/app \
  myapp:latest

# Logs accumulate forever
# Disk fills, container crashes with EIO
# No monitoring of capacity
```

**Solution:**
```bash
# CORRECT: Rotation and monitoring
docker run \
  --log-driver=json-file \
  --log-opt max-size=100m \
  --log-opt max-file=10 \
  -v app-logs:/var/log/app \
  myapp:latest

# Separate monitoring container
docker stats myapp | awk '$5 > 80% { print "ALERT: Disk usage high" }'
```

#### Anti-Pattern 4: Anonymous Volumes

```bash
# ANTI-PATTERN: Unnamed, untrackable volumes
for i in {1..100}; do
  docker run -v /tmp/cache busybox
done

# Creates 100 anonymous volumes
# No clear purpose for each
# Can't identify which is which
# Cleanup impossible without knowledge
```

**Solution:**
```bash
# CORRECT: Named, purposeful volumes
docker volume create cache-layer1
docker volume create cache-layer2
docker volume create cache-layer3

docker run -v cache-layer1:/cache:ro busybox

# List and understand each volume
docker volume ls
docker volume inspect cache-layer1
```

---

## Docker Networking Basics

### Network Driver Types

#### Bridge Network (Default)

**Internal mechanism:**

```
Host Physical NIC (eth0)
    ↓
Host Network Stack
    ↓
Linux Bridge (docker0 or custom br-xxx)
    ├── Virtual Interface 1 (veth1) ← Container A
    ├── Virtual Interface 2 (veth2) ← Container B
    └── Virtual Interface 3 (veth3) ← Container C
    ↓ (NAT via iptables)
Network gateway
```

**Technical flow:**
```bash
Creating the bridge:
docker network create mynet

Inside kernel:
├─ Creates new Linux bridge: br-<random>
├─ Assigns IP pool: 172.17.0.0/16 (default) or custom
├─ Configures iptables rules for NAT
└─ Embedded DNS server listens on 127.0.0.11:53

Container attachment:
docker run --network mynet --name app1 myapp
├─ Creates veth pair (app1-eth0 in container, veth-xxx on host)
├─ Attaches veth to bridge
├─ Assigns IP from pool (172.17.0.2, 172.17.0.3, etc.)
├─ Updates /etc/hosts in container with app1 → 172.17.0.2
└─ Embedded DNS resolves app1 → 172.17.0.2

Container-to-container communication:
app1 (172.17.0.2) → veth pair → bridge → veth pair → app2 (172.17.0.3)
(No NAT needed, same subnet)

Container-to-external:
app1 → veth → bridge → Host eth0 → External network
(NAT: 172.17.0.2:random_port → host_ip:mapped_port)
```

**Practical usage:**
```bash
# Create custom bridge network (recommended over default bridge)
docker network create --driver bridge \
  --subnet=172.20.0.0/16 \
  --gateway=172.20.0.1 \
  app-network

# Run containers on network with service discovery
docker run -d \
  --name frontend \
  --network app-network \
  -p 8080:8080 \
  myapp:latest

docker run -d \
  --name backend \
  --network app-network \
  mybackend:latest

# From frontend container, backend accessible as "backend"
docker exec frontend curl http://backend:8000
```

**DNS Resolution in Bridge:**

```
Default bridge (docker0):
├─ Container-to-container: NOT supported (use --link, deprecated)
├─ Container-to-external: Works via host DNS
└─ Container-to-host: Via host IP (172.17.0.1)

Custom bridge:
├─ Container-to-container: Works via embedded DNS (app1 → app1's IP)
├─ Container hostname registration: Automatic
├─ Embedded DNS caching: 600 seconds default
└─ External DNS: Forwarded to host resolvers
```

**Performance characteristics:**
```
Latency (container-to-container):
├─ Same bridge: ~10-50 microseconds (Linux bridge forward)
├─ Different bridges: ~100-500 microseconds (bridge-to-bridge routing)
└─ Cross-host: N/A (overlay networks for multi-host)

Bandwidth:
├─ Native: Full NIC speed (1-100 Gbps)
└─ No encapsulation overhead (unlike overlay)
```

#### Host Network

**Mechanism:**
Container shares host's network namespace entirely; no isolation.

```
Host network stack
    ├─ eth0 (host's NIC)
    ├─ Container A uses host eth0 directly
    ├─ Container B uses host eth0 directly
    └─ Container C uses host eth0 directly

From host perspective:
├─ Container processes appear in host's netstat
├─ Container ports compete for host ports
└─ Container can modify host routing (if privileged)
```

**Practical usage:**
```bash
# Monitoring agent needs host network metrics
docker run --network host \
  --pid host \
  datadog/agent:latest

# Input/output proxy
docker run --network host \
  --privileged \
  some-network-proxy

# NOT RECOMMENDED for application containers
```

**Pitfalls:**
- Breaks container abstraction (can't relocate)
- Port conflicts across containers
- Security risk (containers can modify host network)
- Routing changes in container affect host

---

#### None Network

**Mechanism:**
Container has isolated network namespace with only loopback interface.

```
Container's network stack
├─ lo (loopback only)
├─ No external connectivity
└─ Completely isolated
```

**Practical usage:**
```bash
# Batch job that shouldn't access network
docker run --network none \
  --read-only \
  datajob:latest

# Verification container
docker run --network none \
  toolbox:latest \
  sh -c "echo 'No network access possible'"
```

#### Overlay Network (Multi-Host)

**Mechanism:**
VXLAN encapsulation for cross-host communication.

```
Host A                              Host B
┌──────────────────┐               ┌──────────────────┐
│ Container 1      │               │ Container 2      │
│ 10.0.1.5         │               │ 10.0.1.6         │
│     ↓ (VXLAN)    │               │     ↑ (VXLAN)    │
│ ┌──────────────┐  │               │ ┌──────────────┐ │
│ │ Overlay net  │  │               │ │ Overlay net  │ │
│ └──────────────┘  │               │ └──────────────┘ │
│     ↓             │   VXLAN        │     ↑            │
│  eth0 (phys)      │────────────────    eth0 (phys)   │
│  192.168.1.10     │  UDP port 4789     192.168.1.11  │
└──────────────────┘               └──────────────────┘

VXLAN encapsulation:
[Container Packet] → [VXLAN header] → [UDP] → Network → [UDP] → [VXLAN] → [Container]
```

**Practical usage (Swarm mode):**
```bash
# Initialize Docker Swarm (manager)
docker swarm init --advertise-addr=192.168.1.10

# Create overlay network (automatic scope: all nodes)
docker network create -d overlay \
  --subnet=10.0.0.0/24 \
  app-overlay

# Deploy service on overlay
docker service create \
  --name web \
  --network app-overlay \
  --replicas=3 \
  myapp:latest

# Service endpoints automatically distributed across nodes
```

**Performance characteristics:**
```
Overhead:
├─ VXLAN encapsulation: ~50 bytes per packet
├─ Latency penalty: ~5-20% over direct NIC
└─ Throughput: ~90-95% of native (encapsulation overhead)

Encryption (optional):
├─ IPSec encryption possible (driver option)
├─ Latency impact: ~20-30% additional
└─ Enables secure cross-datacenter
```

**Limitations acknowledging:**
- Swarm-scoped (works across all Swarm nodes)
- Works only in Swarm mode (not standalone Docker)
- For Kubernetes: Use CNI plugins (Flannel, Calico) instead

---

### Service Discovery & DNS Resolution

#### Docker Embedded DNS

**Architecture:**

```
Container (app1)
    ↓ (resolv.conf configured)
Docker Embedded Resolver: 127.0.0.11:53
    ├─ Local docker network cache
    ├─ Service discovery (app2 → 10.0.1.3)
    └─ External DNS forwarding
        ↓
    Host's resolvers (/etc/resolv.conf)
        ↓
    External nameservers (8.8.8.8, 1.1.1.1, etc.)
```

**Implementation details:**
```bash
# Inside container
cat /etc/resolv.conf
nameserver 127.0.0.11
options ndots:0

# DNS resolver inside container
netstat -an | grep 53
# Shows UDP 127.0.0.11:53 (Docker's embedded DNS)
```

**Resolution flow:**

```
1. Container queries: app2 (service on same network)
   ├─ Query: app2 (in app-network)
   └─ Resolver checks local docker0 database

2. Docker daemon consulted
   ├─ Checks running containers named app2
   ├─ Verifies on app-network
   └─ Returns IP: 10.0.1.3

3. Container queries: google.com (external)
   ├─ Not in local database
   ├─ Forwarded to host's resolvers
   ├─ Resolver chain: /etc/resolv.conf
   └─ Returns public IP

4. Caching
   ├─ Docker caches responses (~600 seconds)
   ├─ Updates on container state changes
   └─ TTL honored for external DNS
```

**Practical usage:**

```bash
# Service lookup in code
# Python example
import socket
ip = socket.gethostbyname('database')  # Resolves to 10.0.1.5

# Bash example
curl http://api:8000/endpoint  # api resolved to its IP automatically
```

**Timing behavior:**
```bash
# First lookup: ~5-10ms (docker daemon query + forwarding)
# Cached lookup: <1ms (cache hit)
# Cache expiration: ~600 seconds, then re-query
# Container restart: Immediate DNS update (cache flushed)
```

---

#### DNS Caching and TTL Issues

**Problem: Client-side caching exceeds Docker TTL**

```
Client Application
├─ Looks up api.example.com
├─ Receives response + TTL=300s
├─ Application caches for 600s (hardcoded)
├─ After 300s: Docker updates IP (container restart)
├─ Application doesn't know, connects to stale IP
└─ Connection fails

Solution: Match TTL expectations
├─ Short TTLs for mutable services (containers)
├─ Longer TTLs for stable services
└─ Client libraries should respect TTL
```

**Practical mitigation:**

```bash
# Java: Set network.cache.ttl system property
docker run -e JAVA_OPTS="-Dnetworkaddress.cache.ttl=0" myapp

# Python: requests doesn't cache, but connection pools do
import requests
session = requests.Session()
# Respects DNS, creates new connections periodically

# Node.js: dnsCache off
const dns = require('dns');
dns.setDefaultResultOrder('ipv6first');
// Applications should implement retry logic
```

---

### Port Mapping & Exposure

#### Port Publishing Mechanism

**Technical implementation:**

```
Container Port (8080)
    ↓ (iptables rule)
Host listening port (3000, 8080, etc.)
    ↓ (connection forwarded)
iptables DNAT rule:
  -A DOCKER -d 172.17.0.2/32 -i docker0 -j ACCEPT
  -A DOCKER -d 172.17.0.2/32 ! -i docker0 -o docker0 -j MASQUERADE
  -A DOCKER ! -i docker0 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 172.17.0.2:8080
    ↓
Container's network stack receives packet
```

**Practical usage:**

```bash
# Single port mapping
docker run -p 8080:8080 myapp
# Host port 8080 → Container port 8080

# Different ports
docker run -p 3000:8080 myapp
# Host port 3000 → Container port 8080

# Multiple ports
docker run \
  -p 8080:8080 \
  -p 8443:8443 \
  -p 9000:9000 \
  myapp

# Bind to specific interface
docker run -p 127.0.0.1:8080:8080 myapp
# Only accessible from localhost

# Random port allocation
docker run -p 8080 myapp
# Host assigns random port
docker port <container>  # See mapping

# All container ports
docker run -P myapp
# Exposes all EXPOSE ports from Dockerfile to random host ports
```

**Performance characteristics:**
```
Port forwarding overhead:
├─ Established connection: <1% latency increase
├─ New connections: iptables lookup ~5-10 microseconds
└─ Impact: Negligible for most workloads
```

#### Port Exposure vs. Publication

```
EXPOSE instruction (Dockerfile):
├─ Documentation only
├─ Metadata (image knows port exists)
├─ Does NOT actually publish
└─ Requires explicit -p flag to actually open

Example:
FROM ubuntu
EXPOSE 8080
# Image now documented as "8080 is important"

# But not accessible without:
docker run -p 8080:8080 myapp
```

---

### Multi-Host Networking

#### Swarm Overlay Networking

**Architecture:**

```
Swarm Manager (node1)
├─ Service: web (3 replicas)
│  ├─ Replica 1 on node1 (10.0.1.2)
│  ├─ Replica 2 on node2 (10.0.1.3)
│  └─ Replica 3 on node3 (10.0.1.4)
├─ Virtual IP (VIP): 10.0.1.5 (service-level)
└─ Embedded LB: Round-robin across replicas
    ├─ Client → VIP (10.0.1.5:8080)
    ├─ Kernel userspace proxy redirects
    └─ Load balanced across replicas

VXLAN Mesh:
node1 ─────VXLAN──── node2
  ↓                    ↓
node3 ──────VXLAN──── All connected
```

**Practical example:**

```bash
# Initialize Swarm
docker swarm init

# Add nodes
docker swarm join --token SWMTKN-... <manager-ip>:2377

# Create overlay network
docker network create -d overlay -o com.docker.network.drive.overlay.vxlanid=4096 mynet

# Deploy service with load balancing
docker service create \
  --name api \
  --network mynet \
  --replicas 3 \
  -p 8080:8080 \
  myapi:latest

# External client connects to VIP
# iptables automatically load-balances across replicas
curl http://<any-swarm-node>:8080/endpoint
# Request distributed to one of 3 replicas
```

#### Ingress Network (Built-in Load Balancer)

```
External Request
    ↓ (Host port 8080)
Ingress Network (default)
├─ All ports exposed via -p published on all nodes
├─ Connection routed to ANY replica (regardless of location)
└─ Transparent load balancing

Example flow:
External client → node1:8080
    ↓
Ingress network intercepts
    ↓
Kernel LB decides destination (round-robin, source IP hash, etc.)
    ↓
Connection forwarded to replica (could be node1, node2, node3)
    ↓
Response returned to client
```

**Behavior:**
```bash
# With port mapping on overlay service
docker service create \
  --name web \
  --network myoverlay \
  --replicas 3 \
  -p 8080:8080 \
  myapp

# Can connect to ANY node, even without replica
docker inspect <service> | jq '.Endpoint.Ports'
# Shows: port 8080 open on all nodes
# Ingress load balances to whichever replica (transparent)
```

---

### Practical Code Examples

#### Multi-Container Application with Networking

```bash
#!/bin/bash
# Complete production setup: nginx → app → postgres

# Create network
docker network create appnet

# PostgreSQL (persistent volume)
docker volume create postgres-data

docker run -d \
  --name postgres \
  --network appnet \
  -v postgres-data:/var/lib/postgresql/data \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_PASSWORD=secret \
  postgres:13

# Backend API
docker run -d \
  --name api \
  --network appnet \
  -e DATABASE_URL="postgresql://postgres:secret@postgres:5432/appdb" \
  myapi:latest

# Frontend (nginx reverse proxy)
cat > nginx.conf << 'EOF'
upstream backend {
  server api:8000;
}

server {
  listen 80;
  location / {
    proxy_pass http://backend;
    proxy_set_header Host $host;
  }
}
EOF

docker run -d \
  --name nginx \
  --network appnet \
  -p 8080:80 \
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf:ro \
  nginx:latest

# Verification
echo "Testing service discovery..."
docker exec api curl http://postgres:5432
docker exec nginx curl http://api:8000/health
docker exec api curl http://nginx/

echo "External access:"
curl http://localhost:8080/
```

#### Storage with Volume Sharing

```bash
#!/bin/bash
# Shared log volume, multiple consumers

# Create shared volume
docker volume create shared-logs

# Log producer
docker run -d \
  --name loggen \
  -v shared-logs:/logs \
  alpine sh -c 'while true; do echo "[$(date)]" >> /logs/app.log; sleep 1; done'

# Log consumers (read-only)
docker run -d \
  --name monitor1 \
  -v shared-logs:/logs:ro \
  alpine sh -c 'tail -f /logs/app.log | while read line; do echo "Monitor1: $line"; done'

docker run -d \
  --name monitor2 \
  -v shared-logs:/logs:ro \
  alpine sh -c 'tail -f /logs/app.log | while read line; do echo "Monitor2: $line"; done'

# Backup
docker run --rm \
  -v shared-logs:/logs \
  -v $(pwd):/backup \
  alpine tar czf /backup/logs-backup.tar.gz -C /logs .
```

#### Storage Driver Comparison Benchmark

```bash
#!/bin/bash
# Compare I/O performance across storage drivers

run_benchmark() {
  local driver=$1
  local container_name="benchmark-$driver"
  
  # Create container with specific driver
  docker run --rm \
    --name "$container_name" \
    -v /dev/shm:/bench \
    alpine \
    ash -c "
      echo 'Sequential write test...'
      time dd if=/dev/zero of=/bench/testfile bs=1M count=1000
      
      echo 'Random read test...'
      time dd if=/bench/testfile of=/dev/null bs=4K
      
      echo 'Docker layer test...'
      time dd if=/dev/urandom of=/tmp/layertest bs=4K count=10000
    "
}

for driver in overlay2 devicemapper; do
  echo "=== Testing $driver ==="
  run_benchmark "$driver"
  echo ""
done
```

---

## Hands-on Scenarios

### Scenario 1: Production Database Container Setup

**Objective**: Deploy PostgreSQL with persistent storage, health checks, and monitoring.

```bash
#!/bin/bash
# Production-grade PostgreSQL deployment

VOLUME_NAME="postgres-prod-data"
CONTAINER_NAME="postgres-prod"
BACKUP_DIR="/backups/postgres"
BACKUP_RETENTION_DAYS=30

# Create volume
docker volume create "$VOLUME_NAME"

# Deploy container
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart=unless-stopped \
  -v "$VOLUME_NAME":/var/lib/postgresql/data \
  -e POSTGRES_DB=production \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD_FILE=/run/secrets/pg_password \
  --secret pg_password \
  --health-cmd="pg_isready -U appuser -d production" \
  --health-interval=10s \
  --health-timeout=5s \
  --health-retries=3 \
  -p 5432:5432 \
  postgres:13

# Wait for healthy
while [ "$(docker inspect -f '{{.State.Health.Status}}' $CONTAINER_NAME)" != "healthy" ]; do
  echo "Waiting for PostgreSQL to be healthy..."
  sleep 2
done

# Automated backup script
cat > "$BACKUP_DIR/backup.sh" << 'BACKUP_EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="/backups/postgres/postgres-prod-${TIMESTAMP}.sql.gz"

docker exec postgres-prod \
  pg_dump -U appuser -d production | \
  gzip > "$BACKUP_FILE"

# Verify backup
if gunzip -t "$BACKUP_FILE" 2>/dev/null; then
  echo "Backup successful: $BACKUP_FILE"
else
  echo "Backup verification failed"
  exit 1
fi

# Cleanup old backups
find /backups/postgres -name "postgres-prod-*.sql.gz" -mtime +30 -delete
BACKUP_EOF

chmod +x "$BACKUP_DIR/backup.sh"

# Schedule backup (add to crontab)
echo "0 2 * * * $BACKUP_DIR/backup.sh >> /var/log/postgres-backup.log 2>&1" | crontab -

echo "PostgreSQL deployed successfully"
docker ps -f name="$CONTAINER_NAME"
```

### Scenario 2: Multi-Container Microservices with Service Discovery

**Objective**: Deploy 3-tier application (frontend, backend, database) with DNS-based service discovery.

```bash
#!/bin/bash
# Complete microservices stack

# Create dedicated network for application
docker network create --driver bridge \
  --subnet=172.25.0.0/16 \
  --gateway=172.25.0.1 \
  app-tier

# Deploy components
components=(
  "postgresql:13 postgres 5432"
  "myapi:latest api 8000"
  "myfront:latest frontend 3000"
)

for component in "${components[@]}"; do
  image=$(echo $component | cut -d' ' -f1)
  name=$(echo $component | cut -d' ' -f2)
  port=$(echo $component | cut -d' ' -f3)
  
  docker run -d \
    --name "$name" \
    --network app-tier \
    -p "${port}:${port}" \
    "$image"
  
  echo "Deployed $name"
done

# Verify service discovery
echo "Testing DNS resolution..."
docker exec api getent hosts postgres  # Should resolve to 172.25.x.x
docker exec frontend getent hosts api   # Should resolve to 172.25.x.x

# Connection test
docker exec api curl http://postgres:5432/  # Database connectivity
docker exec frontend curl http://api:8000/health  # Backend connectivity
```

---

## Interview Questions

### Container Lifecycle & Commands (Senior-level)

**Q1. Explain the difference between `docker stop` and `docker kill`. When would you use each in production?**

A: `docker stop` sends SIGTERM (graceful shutdown), waits for timeout (default 10s), then SIGKILL. `docker kill` sends SIGKILL immediately (force terminate). Production use:
- **stop**: Stateful services (databases, caches) needing graceful shutdown for data consistency
- **kill**: Stuck containers, non-responsive processes, or during emergency failover

```bash
# Graceful shutdown for databases
docker stop -t 30 postgres  # 30-second grace period

# Emergency termination
docker kill runaway-process
```

**Q2. A container keeps exiting with exit code 137. What could be the cause, and how would you debug it?**

A: Exit code 137 = SIGKILL (128 + 9), typically Out-of-Memory termination. Debug steps:
1. Check memory limits: `docker inspect --format='{{.HostConfig.Memory}}'`
2. Check actual usage: `docker stats --no-stream`
3. Review logs: `docker logs <container>` (look for OOMKiller messages)
4. Check container layer size: `docker diff <container>` (excessive writes)
5. Solution: Increase memory limit or reduce memory footprint

**Q3. You need to run a one-off command in a running container without modifying it. Walk through your approach.**

A: Use `docker exec` with read-only mindset:
```bash
# Don't modify the container
docker exec -it myapp bash -c "command"

# Better: Use volume for results
docker exec myapp sh -c "command > /shared/output.txt"
docker cp myapp:/shared/output.txt ./

# Or redirect stdout
docker exec myapp command_that_outputs_data > local_file.txt
```

Key: No `docker commit` afterward; exec is temporary, container should be stateless.

---

### Storage Deep Dive (Senior-level)

**Q4. Explain overlay2's CoW mechanism and its performance implications. When would devicemapper be preferable?**

A: overlay2 uses OverlayFS CoW:
- First write to file = full file copy to container layer (expensive)
- Subsequent writes to same file = direct modification (in container layer)
- Deletes = whiteout markers (free operation)

Performance implications:
```
Large initial write: ~100-500ms (file size dependent)
Cached writes: ~1-5ms (direct container layer)
Many small files: Good (per-file granularity)
```

devicemapper preferable when:
- Dense containerization (block-level efficiency)
- Many small-file workloads (block-level CoW more efficient)
- Complex storage requirements (LVM automation)

Trade-off: devicemapper = better I/O for small files, higher setup complexity.

**Q5. What are the risks of using tmpfs in production? Provide a complete example mitigating these risks.**

A: Risks:
- OOMKill if tmpfs fills
- Data loss on container restart
- Memory pressure from other containers

```bash
# Risk-aware tmpfs usage
docker run \
  --memory=2g \
  --memory-swap=3g \
  --tmpfs /tmp:size=512m,noexec,nosuid \
  --tmpfs /var/run:size=64m \
  --oom-kill-disable=true \
  myapp

# Monitoring wrapper
docker exec myapp sh -c '
  while true; do
    used=$(df /tmp | tail -1 | awk "{print \$3}")
    limit=$(df /tmp | tail -1 | awk "{print \$2}")
    percent=$((used * 100 / limit))
    if [ $percent -gt 80 ]; then
      echo "WARNING: tmpfs at ${percent}%"
    fi
    sleep 60
  done
' &
```

**Q6. Compare volumes, bind mounts, and tmpfs. For a production logging pipeline, which would you use and why?**

A:

| Use Case | Choice | Reason |
|----------|--------|--------|
| **Database data** | Volume | Persistent, portable, auto-backup capable |
| **Dev hot-reload** | Bind mount | Host changes visible immediately |
| **Session cache** | tmpfs | RAM speed, ephemeral, no disk I/O |

For logging pipeline:
```bash
# Logs written to volume (persistent)
docker run \
  -v app-logs:/var/log/app \
  myapp

# Lightweight log aggregator watching volume
docker run \
  -v app-logs:/logs:ro \
  logstash:latest
```

Why not tmpfs: Logs would be lost on log rotation; not suitable for audit trail.
Why not bind mount: Path-specific, not portable, permissions issues.

---

### Networking Deep Dive (Senior-level)

**Q7. Explain Docker's embedded DNS and the TTL problem in relation to container restarts. How would you handle this in a production environment?**

A: Docker embedded DNS (127.0.0.11:53) caches responses ~600 seconds. Problem:

```
Client lib caches DNS response for longer than Docker's TTL
Container A (api.prod) → IP 10.0.1.5
Container A stops, restarts → New IP 10.0.1.6
Client still has cached mapping → Connects to stale IP → Failure
```

Solutions:

1. **Short TTL enforcement**:
```bash
# Java
-Dnetworkaddress.cache.ttl=0

# System-wide
echo "networkaddress.cache.ttl=5" >> $JAVA_HOME/conf/security/java.security
```

2. **Retry logic**:
```python
import socket
def get_service_ip(hostname):
  try:
    return socket.gethostbyname(hostname)
  except socket.gaierror:
    # Retry with refresh
    socket.setdefaulttimeout(2)  # Short timeout
    import time; time.sleep(1)
    return socket.gethostbyname(hostname)
```

3. **Health-check driven routing**:
```bash
# Orchestrator (Kubernetes) actively removes unhealthy endpoints
# Clients use service discovery updated in real-time
```

**Q8. A service deployed across 3 nodes needs to handle client connections from outside the cluster. Explain how port publishing works with Swarm's ingress network.**

A: Swarm ingress network architecture:

```
External client → node1:8080
    ↓
Ingress network listening on all nodes
    ↓
Kernel userspace proxy (KUBE-SVC equivalent)
    ↓
IPVS load balancer (kernel module)
    ↓
Service endpoint selection (could be node1, node2, or node3)
    ↓
Routed via overlay to actual replica
```

Example:
```bash
docker service create \
  --name web \
  --replicas 3 \
  -p 8080:8080 \
  myapp

# Can connect to node2:8080 even if no replica on node2
# Ingress network intercepts, routes to nearest replica
# Transparent load balancing
```

Pro: Scales easily; clients don't track replicas.
Con: Extra hop if client on different node than replica.

**Q9. Design a network topology for a payment system where frontend, backend, and database are isolated networks with specific routing rules.**

A:
```bash
# Create three networks: frontend, backend, database
docker network create frontend-net
docker network create backend-net
docker network create db-net

# Deploy services
docker run -d --name web1 --network frontend-net myfront:latest
docker run -d --name web2 --network frontend-net myfront:latest

docker run -d --name api1 --network backend-net myapi:latest
docker run -d --name api2 --network backend-net myapi:latest

docker run -d --name db --network db-net postgres:13

# Bridge networks for necessary connections
docker network create bridge-frontend-backend
docker network connect bridge-frontend-backend web1
docker network connect bridge-frontend-backend api1

docker network create bridge-backend-db
docker network connect bridge-backend-db api1
docker network connect bridge-backend-db db

# Result: web ↔ api ↔ db, but web ✗ db (enforced isolation)
```

---

**Document Status**: All major sections complete. Study guide includes:
✅ Foundational Concepts
✅ Container Commands & Lifecycle
✅ Docker Storage (deep dive with all variants)
✅ Docker Networking (all driver types)
✅ Hands-on Scenarios
✅ Senior-level Interview Questions

**Last Updated**: 2026-03-07  
**Intended for**: DevOps Engineers with 5–10+ years experience  
**Target Platform**: Docker 20.10+ on Linux (kernel 4.15+)
**Approx Reading Time**: 4-6 hours (comprehensive depth)
