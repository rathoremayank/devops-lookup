# Docker Resource Management, Environment Management, Docker Compose & Logging/Monitoring
## Senior DevOps Study Guide

**Date:** March 7, 2026  
**Target Audience:** DevOps Engineers (5-10+ years experience)  
**Difficulty Level:** Advanced/Expert

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Container Resource Isolation](#container-resource-isolation)
   - [Linux Kernel Subsystems & cgroups](#linux-kernel-subsystems--cgroups)
   - [Docker's Resource Management Architecture](#dockers-resource-management-architecture)
   - [Environment & Configuration Management Principles](#environment--configuration-management-principles)
   - [Container Orchestration Patterns](#container-orchestration-patterns)
   - [Observability in Containerized Environments](#observability-in-containerized-environments)
3. [Resource Management - CPU, Memory, Block IO, PIDs, Device Access](#resource-management---cpu-memory-block-io-pids-device-access)
   - [CPU Management](#cpu-management)
   - [Memory Management](#memory-management)
   - [Block IO Management](#block-io-management)
   - [PID Management](#pid-management)
   - [Device Access Control](#device-access-control)
   - [Resource Limits vs Reservations](#resource-limits-vs-reservations)
   - [Swap Management](#swap-management)
4. [Environment Management - Variables, .env files, Configs, Secrets, Build Args](#environment-management---variables-env-files-configs-secrets-build-args)
   - [Environment Variables in Docker](#environment-variables-in-docker)
   - [.env Files & ARG Directives](#env-files--arg-directives)
   - [Docker Configs](#docker-configs)
   - [Docker Secrets](#docker-secrets)
   - [Build Arguments](#build-arguments)
   - [Configuration Management Best Practices](#configuration-management-best-practices)
5. [Docker Compose - Multi-container Orchestration, Networking, Volumes, Scaling](#docker-compose---multi-container-orchestration-networking-volumes-scaling)
   - [Docker Compose Architecture](#docker-compose-architecture)
   - [docker-compose.yml Structure](#docker-composeyml-structure)
   - [Service Definitions](#service-definitions)
   - [Networks in Docker Compose](#networks-in-docker-compose)
   - [Volumes & Bind Mounts](#volumes--bind-mounts)
   - [Scaling & Replication](#scaling--replication)
6. [Logging & Monitoring - Container Logs, Log Drivers, Centralized Logging, Metrics, Health Checks, Alerting](#logging--monitoring---container-logs-log-drivers-centralized-logging-metrics-health-checks-alerting)
   - [Container Logging Fundamentals](#container-logging-fundamentals)
   - [Log Drivers](#log-drivers)
   - [Centralized Logging Architecture](#centralized-logging-architecture)
   - [Metrics Collection & Monitoring](#metrics-collection--monitoring)
   - [Health Checks & Self-Healing](#health-checks--self-healing)
   - [Alerting & Incident Response](#alerting--incident-response)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

In modern DevOps platforms, Docker containers have become the standard unit of deployment. However, running containers in production environments requires sophisticated management of:

- **Resource Allocation & Constraints**: Ensuring containers don't consume excessive CPU, memory, or I/O resources
- **Configuration & Secrets Management**: Handling environment-specific configurations securely and at scale
- **Multi-container Orchestration**: Coordinating dependent services with networking and storage
- **Observability**: Collecting logs, metrics, and health signals for monitoring and alerting

These four pillars form the foundation of production-grade containerized applications. Senior DevOps engineers must understand not just the "how" but the "why" behind each mechanism, and be able to design systems that are resilient, scalable, and maintainable.

### Why It Matters in Modern DevOps Platforms

**Resource Efficiency**: Container sprawl is a real problem. Without proper resource management, containers can starve each other, leading to cascading failures. CPU and memory limits prevent noisy neighbor problems and improve cluster utilization.

**Security & Compliance**: Secrets (API keys, database passwords, certificates) cannot be managed through environment variables in production. Docker's secrets mechanism provides encrypted-at-rest, encrypted-in-transit storage that integrates with container orchestrators like Kubernetes.

**Configuration Flexibility**: Modern applications require different configurations across development, staging, and production environments. Proper environment management decouples application code from infrastructure configuration.

**Operational Visibility**: You cannot manage what you cannot measure. Comprehensive logging and monitoring allow teams to:
- Diagnose issues quickly
- Understand application behavior under load
- Detect security anomalies
- Optimize resource utilization
- Meet compliance requirements (audit trails)

**Orchestration Complexity**: As applications scale from single containers to multi-container systems with complex dependencies, orchestration becomes critical. Docker Compose (and Kubernetes) abstract away the networking, service discovery, and scaling challenges.

### Real-world Production Use Cases

**Multi-tier Web Application**
```
Frontend(nginx) → Backend API(python/flask) → Database(postgres)
Cache(redis) → Message Queue(rabbitmq) → Workers(python)
```
Each service has different resource requirements, environment configurations, and logging needs. Docker Compose allows teams to define this entire stack declaratively, version control it, and replicate it across environments.

**Microservices with Strict Resource Budgets**

A financial services company runs thousands of microservices. Without CPU and memory limits, a single service bug could consume all cluster resources. Resource limits provide isolation and SLA guarantees.

**Compliance-Heavy Organizations**

Healthcare, finance, and government organizations need:
- Encrypted secret storage (HIPAA, PCI-DSS)
- Complete audit trails (SOC2)
- Fine-grained access controls (RBAC)

Docker secrets and proper logging are non-negotiable requirements.

**Zero-Downtime Deployments**

Health checks enabling automatic restarts and orchestrators initiating deployments based on readiness probes reduce mean time to recovery (MTTR) and ensure continuous availability.

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster                      │
│  ┌────────────────────────────────────────────────────┐ │
│  │         Node (VM/Physical Server)                  │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │ │
│  │  │  Pod     │  │  Pod     │  │  Pod     │        │ │
│  │  │ (Docker) │  │ (Docker) │  │ (Docker) │        │ │
│  │  │ - Limits │  │ - Limits │  │ - Limits │        │ │
│  │  │ - Env    │  │ - Env    │  │ - Env    │        │ │
│  │  │ - Logs   │  │ - Logs   │  │ - Logs   │        │ │
│  │  └──────────┘  └──────────┘  └──────────┘        │ │
│  │                    Service Mesh                    │ │
│  │  (Networking, Service Discovery, Observability)   │ │
│  └────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────┐ │
│  │     Monitoring Stack                               │ │
│  │  Prometheus (metrics) → Grafana (visualization)    │ │
│  │  ELK/Loki (logs) → AlertManager (alerting)         │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Container Resource Isolation

**Definition**: Container resource isolation is the mechanism by which Docker ensures that:
1. One container cannot consume unlimited resources at the expense of others
2. Resources are fairly allocated across containers
3. Applications can make assumptions about available resources

**Key Principle**: Containers share the host kernel but have isolated views of:
- Filesystem (via union mounts/overlayfs)
- Network (via virtual network interfaces)
- Process namespace (containers cannot see other container processes)
- IPC (Inter-Process Communication)
- **Resource usage** (via cgroups)

Without resource isolation, a single runaway process could degrade performance across the entire host, making the system unpredictable and unreliable.

### Linux Kernel Subsystems & cgroups

**cgroups (Control Groups)** are the Linux kernel mechanism that enables resource limiting at the process group level. They exist in v1 and v2 (unified hierarchy).

**cgroups v1 (legacy, subsystems-based)**:
```
/sys/fs/cgroup/
├── cpu/           # CPU usage, CPU shares
├── memory/        # Memory limits, swap
├── blkio/         # Block device I/O
├── cpuset/        # CPU affinity
├── devices/       # Device access control
├── freezer/       # Suspend/resume process groups
├── net_cls/       # Network traffic classification
└── pids/          # PID limit per cgroup
```

**cgroups v2 (unified, better architecture)**:
- Single hierarchy instead of multiple trees
- Better resource accounting
- Improved memory pressure notifications
- More intuitive control

**Docker's cgroups Integration**:
- Docker creates cgroups for each container during `docker run`
- Mapped to container ID: `/sys/fs/cgroup/<name>/<container_id>`
- Resource limits applied at cgroup level, not enforced by Docker itself

### Docker's Resource Management Architecture

**Layers of Control**:

1. **Kernel Level (cgroups)**: Actual enforcement of limits
2. **Containerd/Runtime Level**: Translates Docker runtime API to cgroup operations
3. **Docker Engine Level**: Accepts `--memory`, `--cpus` flags
4. **Orchestrator Level (Kubernetes/Swarm)**: Scheduler makes decisions based on available resources

**Important Distinction**:
- `--memory` = **hard limit** (container killed if exceeded, Out of Memory)
- `--memory-reservation` = **soft limit** (kernel tries to reclaim, but allows burst)

### Environment & Configuration Management Principles

**The Twelve-Factor App Principles** (relevant sections):

**Factor III - Store config in the environment**:
- Code should not contain environment-specific values
- Configuration should be loaded from environment variables

**Factor V - Strict separation of stages**:
- Dev, staging, and production should use identical container images
- Only environment configuration differs

**Security By Design**:
- Secrets (passwords, API keys, certs) are NOT environment variables in production
- Secrets are encrypted at rest and in transit
- Secrets are mounted as read-only files or passed via secure channels
- Environment variables appear in `docker inspect` and process listings (security risk)

**Configuration Hierarchy** (specificity increases):
```
Defaults (in application code)
↓
.env files (development only)
↓
Docker build args (immutable, baked into image)
↓
Docker run environment variables (mutable, often for dev)
↓
Docker configs (read-only, swarm/K8s)
↓
Docker secrets (encrypted, immutable, swarm/K8s)
↓
Application-level overrides (config servers, consul, etcd)
```

### Container Orchestration Patterns

**Single Host (docker-compose)**:
- Suitable for development, testing, small deployments
- All containers on one machine
- No automatic failover or scaling
- Simplest mental model

**Multi-Host Orchestration (Docker Swarm/Kubernetes)**:
- Containers distributed across multiple nodes
- Service discovery & load balancing
- Automatic failover & rescheduling
- Rolling updates & versioning
- Resource-aware scheduling

**Container-to-Host Resource Negotiation**:
```
Request (we ask)    → CPU 2 cores, Memory 1GB
Limit (hard max)    → CPU 4 cores, Memory 2GB
Node Available      → CPU 16 cores, Memory 64GB

Scheduler Algorithm → Place container on node with sufficient available resources
```

If requests exceed available resources, container cannot be scheduled. If limits are exceeded, container is throttled or killed.

### Observability in Containerized Environments

**Three Pillars of Observability**:

1. **Metrics** (quantitative): CPU%, memory usage, request latency, error rate
   - Collected via: Prometheus, Telegraf, StatsD
   - Stored in: Prometheus, InfluxDB, Datadog
   - Visualized via: Grafana

2. **Logs** (textual events): Application debug output, audit trails, error messages
   - Collected via: Filebeat, Fluentd, Logstash, or log driver
   - Stored in: Elasticsearch, Loki, S3, datadog
   - Accessed via: Kibana, Grafana, grep

3. **Traces** (distributed request flow): End-to-end latency across microservices
   - Collected via: Jaeger, Zipkin, OTEL agents
   - Visualized via: Jaeger UI

**Container-Specific Challenges**:
- Logs are ephemeral (container deletion = log loss)
- Metrics are isolated to container (no host-level aggregation by default)
- Container churn makes correlation harder

**Solutions**:
- Centralized logging (all logs streamed to external system)
- Log drivers (docker sends logs to external system, not just stdout)
- Container metadata (labels, tags) attached to logs and metrics
- Health checks (additional layer of monitoring)

---

## Resource Management - CPU, Memory, Block IO, PIDs, Device Access

### CPU Management

**Key Concepts**:

**CPU Shares** (--cpu-shares):
- Relative weight in Completely Fair Scheduler (CFS)
- Default: 1024 shares per container
- Only matters under contention
- If container A has 2048 shares and container B has 1024 shares, A gets 2× CPU time when both contending

```bash
docker run --cpu-shares 512 <image>  # Half normal priority
docker run --cpu-shares 2048 <image> # Double normal priority
```

**CPU Quota & Period** (--cpus or --cpu-quota/--cpu-period):
- Hard limit on CPU time
- `--cpus 1.5` = container can use 1.5 CPU cores maximum
- Implemented as: `quota / period` in microseconds
- Default period: 100,000us (100ms)
- Example: `--cpus=1.5` → quota=150,000us per 100,000us period

```bash
docker run --cpus 2 <image>           # Max 2 cores
docker run --cpus 0.5 <image>         # Max 0.5 cores (half core)
docker run --cpu-quota 150000 --cpu-period 100000 <image>  # Same as --cpus 1.5
```

**CPU Pinning** (--cpuset-cpus):
- Bind container to specific CPU cores
- Useful for latency-sensitive, cache-sensitive workloads
- Reduces context switching
- But reduces flexibility (other containers may be starved)

```bash
docker run --cpuset-cpus 0,1 <image>  # Pin to cores 0 and 1
docker run --cpuset-cpus 0-3 <image>  # Pin to cores 0, 1, 2, 3
```

**Practical Example**:
```bash
# Web server: low priority, flexible CPU usage
docker run --cpu-shares 512 \
  --cpus 4 \
  nginx

# Real-time analytics: high priority, pinned cores
docker run --cpu-shares 2048 \
  --cpus 2 \
  --cpuset-cpus 0-1 \
  analytics-worker
```

**Production Considerations**:
- Set `--cpus` to prevent runaway processes
- Use `--cpu-shares` to prioritize critical services
- Avoid `--cpuset-cpus` unless latency-critical
- Monitor CPU throttling in metrics (`container_cpu_throttled_seconds`)

### Memory Management

**Memory Limits** (--memory or -m):
- Hard limit: container cannot exceed
- Exceeding = Out-of-Memory (OOM) killer terminates container
- No soft degradation; immediate termination

```bash
docker run --memory 512m <image>      # 512 MB hard limit
docker run --memory 1g <image>        # 1 GB hard limit
docker run -m 256m <image>            # Shorthand
```

**Memory Reservation** (--memory-reservation):
- Soft limit: kernel attempts to reclaim when needed
- No hard termination
- Allows temporary burst beyond reservation
- More flexible than hard limit

```bash
docker run --memory 2g \
           --memory-reservation 1g \
           <image>
# Hard limit: 2GB, but tries to stay under 1GB unless needed
```

**Memory Swap** (--memory-swap):
- Total memory + swap available to container
- If `--memory-swap=1g` and `--memory=512m`
  - 512MB RAM + 512MB Swap available
- Swapping to disk is slow; should be avoided
- Can be set to equal `--memory` to disable swap

```bash
docker run --memory 512m --memory-swap 512m <image>  # No swap
docker run --memory 512m --memory-swap 1g <image>    # 512MB RAM + 512MB swap
```

**Kernel Memory** (--kernel-memory):
- Limits memory used by kernel on behalf of container
- Includes: page tables, slab allocations, etc.
- Rarely needs adjustment
- Removed in Docker 20.10+ (kernel memory accounting deprecated)

**Memory Pressure & Notifications**:
- `memory.pressure_level` events in cgroups v2
- Applications can register callbacks for low-memory events
- Allows graceful degradation instead of OOM kill

**Memory Swap Behavior - Critical Insight**:

Without proper swap settings, containers can:
1. Consume all available RAM
2. Trigger OOM killer (kills container)
3. Cascade failure across dependent services

Solution: Always set `--memory-swap = --memory` (disable swap) in production.

```bash
# GOOD: No swap, predictable memory usage
docker run --memory 1g --memory-swap 1g myapp

# BAD: Container can swap to disk, unpredictable latency
docker run --memory 1g myapp  # --memory-swap defaults to ~double --memory
```

**Memory Metrics to Monitor**:
```
container_memory_usage_bytes          # Total memory (including cache)
container_memory_max_usage_bytes      # Peak memory usage
container_memory_working_set_bytes    # Actual working set (no cache)
container_memory_limit_bytes          # Configured limit
container_memory_failures_total       # OOM kill count
```

### Block IO Management

**Block IO Limiting** (--blkio-weight, --blkio-weight-device):
- Controls proportional I/O bandwidth
- Similar to CPU shares: relative weight under contention
- Default weight: 500

```bash
docker run --blkio-weight 300 <image>   # Low I/O priority
docker run --blkio-weight 1000 <image>  # High I/O priority
```

**Rate Limiting** (--device-read-rate, --device-write-rate):
- Absolute limits on read/write operations per device
- Specified as `<device>:<rate>`

```bash
docker run --device-read-rate /dev/sda:10mb <image>  # Max 10MB/s read
docker run --device-write-rate /dev/sda:5mb <image>  # Max 5MB/s write
```

**IOPS Limiting** (--device-read-iops, --device-write-iops):
- Limit I/O operations per second
- Useful for preventing DB from being starved by other containers

```bash
docker run --device-read-iops /dev/sda:1000 <image>  # Max 1000 read ops/sec
docker run --device-write-iops /dev/sda:500 <image>  # Max 500 write ops/sec
```

**Practical Scenario**:
```bash
# High-traffic web server: prioritized I/O
docker run --blkio-weight 1000 \
           --device-read-rate /dev/sda:50mb \
           --device-write-rate /dev/sda:50mb \
           nginx

# Batch processing: low priority, rate-limited
docker run --blkio-weight 300 \
           --device-read-rate /dev/sda:10mb \
           --device-write-rate /dev/sda:5mb \
           batch-processor
```

**When to Use**:
- Shared storage systems (NFS, EBS): prevent one container from saturating I/O
- Database containers with strict SLOs: guarantee I/O for critical queries
- Multi-tenant systems: fair resource division

### PID Management

**PID Limit** (--pids-limit):
- Limits number of processes a container can spawn
- Prevents fork bombs and process exhaustion attacks
- Exceeding limit = cannot create new process

```bash
docker run --pids-limit 100 <image>   # Max 100 processes
docker run --pids-limit -1 <image>    # Unlimited (not recommended)
```

**Why This Matters**:
```bash
# Attacker or bug creates fork bomb:
:(){ :|:& };:  # Unix fork bomb

# Without --pids-limit: exhausts system PIDs, affects all containers
# With --pids-limit 100: container cannot create >100 processes, only affects itself
```

**Practical Values**:
- Web server (nginx): 10-50 processes
- Application server (gunicorn): 10-50 + workers
- Database (postgres): 50-200+ (connection-per-process models)
- Default (no limit): 4096 on most systems

### Device Access Control

**Device Access Limitations** (--device):
- Block devices: /dev/sda, /dev/sdb (direct disk access)
- Character devices: /dev/tty, /dev/pts (terminal/pseudo-terminal)
- Special devices: /dev/null, /dev/zero, /dev/random (but usually available by default)
- GPU devices: /dev/nvidia0 (requires special handling)

```bash
# Allow access to USB device
docker run --device /dev/ttyUSB0:/dev/ttyUSB0 <image>

# Allow access to all ports (host level)
docker run --device /dev/input:/dev/input <image>

# GPU access (nvidia-docker)
docker run --gpus all <image>
docker run --gpus "device=0,1" <image>  # Specific GPUs
```

**Permissions Format**:
```bash
--device <device_on_host>:<device_in_container>:<cgroup_permissions>

# cgroup_permissions: r (read), w (write), m (mknod)
docker run --device /dev/sda:/dev/sda:rw <image>  # Read + Write
docker run --device /dev/sda:/dev/sda:r <image>   # Read-only
```

**GPU Usage Example** (Machine Learning):
```bash
# NVIDIA GPU detection
nvidia-docker run --gpus all -it tensorflow/tensorflow:latest-gpu python

# Or with standard docker + device mounting
docker run --device /dev/nvidia0 \
           --device /dev/nvidia-uvm \
           --device /dev/nvidiactl \
           -e NVIDIA_VISIBLE_DEVICES=all \
           tensorflow-gpu
```

**Hardware Availability Matrix**:
```
Device Type    | Default Access | Docker Mapping | Use Case
─────────────────────────────────────────────────────────────
/dev/null      | Yes (auto)     | Always avail   | Discard data
/dev/zero      | Yes (auto)     | Always avail   | Infinite zeros
/dev/random    | Yes (auto)     | Always avail   | Random data
/dev/urandom   | Yes (auto)     | Always avail   | Pseudo-random
─────────────────────────────────────────────────────────────
/dev/sda       | No (explicit)  | --device       | Disk I/O
/dev/ttyUSB0   | No (explicit)  | --device       | Serial/USB
/dev/nvidia0   | No (explicit)  | nvidia-docker  | GPU compute
/dev/kvm       | No (explicit)  | --device       | VM acceleration
```

### Resource Limits vs Reservations - Comprehensive Comparison

**Docker Perspective**:

| Aspect | Limit (Hard) | Reservation (Soft) |
|--------|-------------|-------------------|
| Implementation | cgroups v1/v2 hard limit | cgroup memory.soft_limit |
| Enforcement | Kernel enforces strictly | Kernel suggests, allows burst |
| Action on exceed | OOM kill (memory), throttle (CPU) | Allow temporary usage |
| Visibility | `--cpus`, `--memory` | `--cpus`, `--memory-reservation` |
| Cascade effect | Hard failure | Graceful degradation |

**Kubernetes Perspective** (Maps to Docker):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:1.0.0
    resources:
      # Reservation = what scheduler considers available
      requests:
        memory: "512Mi"      # Maps to --memory-reservation 512m
        cpu: "500m"         # Maps to --cpu-shares 512
      
      # Limit = absolute max allowed
      limits:
        memory: "1Gi"       # Maps to --memory 1g
        cpu: "1"           # Maps to --cpus 1
```

**Kubernetes Behavior**:

1. **At scheduling time**:
   - Pod requests not met → Cannot schedule (stays Pending)
   - Requests met → Pod scheduled on node

2. **At runtime**:
   - Pod exceeds limit → Pod OOM killed (memory) or throttled (CPU)
   - Between request and limit → Allowed to use

**Production Configuration Pattern**:
```bash
# Conservative: request = limit (no oversubscription)
docker run --memory 1g --memory-reservation 1g myapp

# Moderate: reservation = 70% of limit (allow 30% spike)
docker run --memory 1g --memory-reservation 700m myapp

# Aggressive: reservation = 50% of limit (allow 100% spike)
docker run --memory 2g --memory-reservation 1g myapp
# Risk: if all containers spike, some will OOM kill
```

### Swap Management - Deep Dive

**Why Swap is Dangerous in Containers**:

```
Scenario: Container with --memory 1g, using swap

T0:  Container uses 800MB RAM + 400MB Swap
     Latency: 100ms (mostly RAM)

T1:  Memory pressure increases
     Kernel moves more to swap
     500MB RAM + 500MB Swap
     Latency: 500ms (disk I/O slower)

T2:  Heavy swap usage
     100MB RAM + 900MB Swap
     Latency: 5000ms (disk I/O very slow)

Result: Application becomes unresponsive
User sees timeouts, cascade failures begin
```

**Swap Math**:
```bash
# Default (if --memory-swap not specified)
--memory 1g → --memory-swap auto (usually 2g or more)
# Means: 1GB RAM + 1GB+ Swap available

# Explicit control
--memory 1g --memory-swap 1g → Only 1GB total (no swap)
--memory 1g --memory-swap 2g → 1GB RAM + 1GB Swap
--memory 1g --memory-swap -1  → Unlimited (dangerous)
```

**Verification**:
```bash
# Check swap configuration in cgroups
cat /sys/fs/cgroup/memory/docker/<container-id>/memory.memsw.limit_in_bytes
# Output: raw bytes of total memory + swap limit

# Check actual swap usage
cat /sys/fs/cgroup/memory/docker/<container-id>/memory.memsw.usage_in_bytes
# Compare to memory.usage_in_bytes to see swap portion

# In modern systems (systemd)
systemctl status docker
# Shows memory limits
```

**Production Best Practice - Disable Swap**:
```bash
# At container level
docker run --memory 1g --memory-swap 1g myapp

# At docker daemon level (apply to all)
# /etc/docker/daemon.json
{
  "default-ulimits": {
    "memlock": {
      "Name": "memlock",
      "Hard": -1,
      "Soft": -1
    }
  }
}

# At host level (disable all swap)
# Most robust approach for container hosts
swapoff -a  # Disable swap
# Verify: free -h (should show 0 for Swap)
```

### cgroups v2 - Next Generation Resource Control

**cgroups v1** (Legacy, still widely used):
- Separate subsystems (memory, cpu, devices, etc.)
- Complex interface (/sys/fs/cgroup/memory/, /sys/fs/cgroup/cpu/)
- Hard to reason about combined limits

**cgroups v2** (Modern, cleaner):
- Unified hierarchy
- Single interface (/sys/fs/cgroup/mygroup/)
- Simpler resource control

**Check System cpgroups Version**:
```bash
ls /sys/fs/cgroup/
# v1: Shows separate directories (memory, cpu, devices, etc.)
# v2: Shows unified structure

stat -f /sys/fs/cgroup/ | grep Type
# cgroup2fs = v2, tmpfs = v1
```

**cgroups v2 Features**:
- PSI (Pressure Stall Information): Real pressure metrics
- No unnecessary memory accounting
- Cleaner interface
- Better performance

```bash
# cgroups v2 resource interface
cat /sys/fs/cgroup/memory.max        # Hard limit (bytes)
cat /sys/fs/cgroup/memory.high       # Soft limit (bytes)
cat /sys/fs/cgroup/memory.current    # Current usage (bytes)

# Pressure metrics
cat /sys/fs/cgroup/memory.pressure_level
# Some / Full / Extreme
```

**In Docker context**:
- Docker automatically detects cgroups version
- No user action needed for basic operations
- Advanced resource tuning may need cgroups v2 awareness

### Resource Troubleshooting Methodology

**Problem: Container Slow/Timeout**

**Step 1: Determine Resource Bottleneck**
```bash
docker stats <container>
# Watch for: CPU %, Memory %, Network I/O

# If CPU near 100% or throttled → CPU issue
# If Memory near limit → Memory issue
# If Network I/O high → Network saturation
```

**Step 2: Check Limits**
```bash
docker inspect <container> | grep -A 20 Resources
# Shows: MemoryLimit, CpuQuota, CpuPeriod, BlkioWeight, etc.

# Formula: CPUUsagePercent = (CpuQuota / CpuPeriod) * 100
# Example: quota=200000, period=100000 → max is 2 CPUs
```

**Step 3: Profile Application Behavior**
```bash
# CPU profiling - find hotspots
docker exec <container> py-spy record -d 30 -o profile.svg -- python app.py

# Memory profiling - find leaks
docker exec <container> python -m memory_profiler app.py

# I/O profiling
docker exec <container> iotop -b -n 1
```

**Step 4: Adjust Limits and Re-test**
```bash
# If CPU-bound: increase --cpus
docker run --cpus 4 <image>  # From 2 to 4

# If memory issue: increase --memory
docker run --memory 2g <image>  # From 1g to 2g

# If I/O bound: increase block I/O weight
docker run --blkio-weight 1000 <image>

# Monitor again
docker stats <container>
```

**Decision Tree**:
```
Container slow?
├─ CPU % high?
│  ├─ YES → CPU limit too low
│  │       Solution: docker run --cpus X+1
│  └─ NO → Continue
├─ Memory % high?
│  ├─ YES → Memory leak or limit too low
│  │       Solution: profile for leak, or --memory Y+1G
│  └─ NO → Continue
├─ Network I/O high?
│  ├─ YES → Network saturation or inefficient I/O
│  │       Solution: optimize app or increase bandwidth
│  └─ NO → Continue
└─ Check dependent services
   └─ Database slow? Queue backed up? Cache hits low?
```

```bash
docker run --pids-limit 50 \
           -c gunicorn:app \
           web-app
```

### Device Access Control

**Accessing Host Devices** (--device):
- Allow container to access host hardware
- GPU, USB, serial ports, hardware accelerators
- Default: no device access

```bash
docker run --device /dev/nvidia0 <image>     # GPU
docker run --device /dev/ttyUSB0 <image>     # Serial port
docker run --device /dev/kvm <image>         # KVM for nested virtualization
```

**Device Permissions**:
- Read (r): read from device
- Write (w): write to device  
- Mknod (m): create device node

```bash
docker run --device /dev/kvm:rwm <image>     # Full access
docker run --device /dev/stdout:w <image>    # Write-only
```

**Device Groups** (--group-add):
- Add container user to host device group
- Allows unprivileged access to devices

```bash
# On host: docker group allows docker socket access
docker run --group-add docker \
           -v /var/run/docker.sock:/var/run/docker.sock \
           <image>  # Container can talk to Docker daemon
```

**Security Implications**:
- Device access bypasses container isolation
- Privileged access to host resources
- Use only when necessary
- Audit and monitor device access

### Resource Limits vs Reservations

**CPU: Shares vs Quota**

| Aspect | CPU Shares | CPU Quota |
|--------|-----------|-----------|
| Type | Soft limit | Hard limit |
| Behavior | Relative weight | Absolute cap |
| Under contention | Proportional time | Throttled |
| No contention | Can use all available | Limited to quota |
| Use case | Best-effort prioritization | SLA enforcement |

```bash
# Shares (soft): on an 8-core system
docker run --cpu-shares 1024 app1   # Gets 50% when contending
docker run --cpu-shares 1024 app2   # Gets 50% when contending
# But when non-contending, either can use all 8 cores

# Quota (hard): on an 8-core system  
docker run --cpus 2 app1            # Max 2 cores always
docker run --cpus 2 app2            # Max 2 cores always
# Even if one is idle, other cannot exceed 2 cores
```

**Memory: Limit vs Reservation**

| Aspect | Memory Limit | Memory Reservation |
|--------|-------------|-------------------|
| Type | Hard limit | Soft limit |
| Exceeding | OOM kill container | Kernel reclaims, allows burst |
| Enforcement | Strict | Best-effort |
| Use case | Prevent runaway | Guidance for scheduling |

```bash
docker run --memory 1g \
           --memory-reservation 512m \
           <image>
# Under pressure: uses up to 512m normally
# Spikes: allowed up to 1g
# Beyond 1g: OOM killed
```

**Reservation vs Request (Kubernetes analogy)**:
- Docker `--memory-reservation` ≈ Kubernetes `requests.memory`
- Docker `--memory` ≈ Kubernetes `limits.memory`

**Best Practice**:
```bash
# For web servers (can handle some burst)
docker run --memory 2g \
           --memory-reservation 1.5g \
           --cpus 2 \
           --cpu-shares 1024 \
           web-app

# For strict services (fixed capacity)
docker run --memory 4g \
           --memory-reservation 4g \
           --cpus 4 \
           --cpu-shares 2048 \
           database
```

### Swap Management

**Understanding Swap**:
- When RAM is full, kernel moves least-used pages to disk
- Much slower than RAM (100-1000× latency increase)
- Causes unpredictable application behavior
- In production: should disable swap

**Swap Limit Behavior**:

```bash
# Default behavior: --memory-swap not set
docker run --memory 1g <image>
# Docker sets: --memory-swap = 2 × --memory (usually)
# Container can use: 1GB RAM + 1GB Swap (or system default)

# No swap
docker run --memory 1g --memory-swap 1g <image>
# Container can use: 1GB RAM + 0GB Swap

# Explicit swap
docker run --memory 1g --memory-swap 2g <image>
# Container can use: 1GB RAM + 1GB Swap
```

**Swap Metrics to Watch**:
```
container_memory_swap_usage_bytes      # Current swap usage
container_memory_swap_max_usage_bytes  # Peak swap usage
```

**Non-zero swap indicates**:
- Memory limit too low for workload
- Need to increase `--memory`
- Or reduce workload size

**Production Recommendation - Disable Swap Completely**:

```bash
# In docker daemon (all containers)
# /etc/docker/daemon.json
{
  "memory-swap": 0
}

# Per container
docker run --memory 2g --memory-swap 2g <image>
```

**Why Disable Swap in Production**:
1. **Latency**: Swap causes 100-1000× latency increase
2. **Unpredictability**: SLA violations
3. **Cascading failures**: Overcommitted system fails spectacularly
4. **Observability**: Hard to detect swap pressure in monitoring

**Resource Allocation Strategy**:

Instead of relying on swap:
1. Set appropriate `--memory` limits
2. Use `--memory-reservation` for safe headroom
3. Monitor memory usage
4. Scale horizontally or vertically before hitting limits
5. Use orchestrator to prevent overcommitment

---

## Environment Management - Variables, .env files, Configs, Secrets, Build Args

### Environment Variables in Docker

**Setting via `docker run`**:
```bash
docker run -e KEY=value <image>
docker run --env KEY=value <image>
docker run --env-file .env <image>
```

**Setting in Dockerfile**:
```dockerfile
FROM ubuntu:22.04
ENV LANG=C.UTF-8 \
    TZ=UTC \
    APP_HOME=/app

ENV DEBUG=false
ENV PORT 8080
```

**Characteristics**:
- Mutable at runtime
- Visible in `docker inspect`
- Visible in `ps aux` output
- NOT suitable for secrets in production

**Example - Multi-environment Setup**:
```bash
# Development
docker run -e ENVIRONMENT=dev \
           -e LOG_LEVEL=debug \
           -e DATABASE_URL=postgres://localhost \
           <image>

# Production
docker run -e ENVIRONMENT=prod \
           -e LOG_LEVEL=error \
           -e DATABASE_URL=postgres://prod-db.example.com \
           myapp:1.0.0
```

**Anti-pattern: Secrets in Environment Variables**:
```bash
# NEVER DO THIS:
docker run -e DATABASE_PASSWORD=supersecret \
           -e API_KEY=abc123xyz \
           <image>

# Why:
# 1. docker inspect reveals the values
# 2. Process listing (ps aux) shows env vars
# 3. Container logs might log these values
# 4. No encryption at rest in container
```

### .env Files & ARG Directives

**.env File Format** (used by `docker run --env-file`):
```
# .env
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=info
DATABASE_HOST=db.example.com
DATABASE_PORT=5432
# Comments supported
FEATURES=feature1,feature2,feature3
```

**Usage**:
```bash
docker run --env-file .env <image>
# All variables in .env are set in container
```

**Build Arguments (ARG)** - Different from ENV:
- Immutable after build
- Only available during build
- Can be referenced in subsequent build stages
- NOT included in final image unless explicitly promoted to ENV

**ARG in Dockerfile**:
```dockerfile
FROM ubuntu:22.04

# Available during build, not in runtime
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl

# Available during build AND runtime
ARG PYTHON_VERSION=3.11
ENV PYTHON_VERSION=${PYTHON_VERSION}
RUN apt-get install -y python${PYTHON_VERSION}

# Default value
ARG APP_VERSION=1.0.0-unknown
LABEL version=${APP_VERSION}
```

**Using ARG at Build Time**:
```bash
# Override ARG
docker build --build-arg PYTHON_VERSION=3.12 .
docker build --build-arg PYTHON_VERSION=3.12 \
             --build-arg APP_VERSION=2.1.0 \
             -t myapp:2.1.0 .

# Multiple args in file
docker build --build-arg-file build.args .
# build.args:
# PYTHON_VERSION=3.11
# APP_VERSION=1.5.0
```

**ARG vs ENV Best Practices**:

| Use | ARG | ENV |
|-----|-----|-----|
| Build-time config | ✅ | ❌ |
| Runtime config | ❌ | ✅ |
| Immutable build | ✅ | ❌ |
| Final image size | Size increases if promoted | Always in image |
| Security sensitive | Can be leaked in layer cache | Visible at runtime |

**Multi-stage Build with ARG**:
```dockerfile
# Stage 1: Build
FROM golang:1.21 as builder
ARG VERSION=1.0.0
WORKDIR /build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-X main.Version=${VERSION}" \
    -o app .

# Stage 2: Runtime (smaller image)
FROM alpine:3.18
ARG VERSION=1.0.0
ENV APP_VERSION=${VERSION}
COPY --from=builder /build/app /app
RUN /app --version  # Prints version from build
```

### Docker Configs

**What are Configs?**
- Read-only configuration files
- Managed by Docker (Swarm) or Kubernetes
- Not encrypted (use Secrets for sensitive data)
- Updated via rolling restart
- Available as mounted files (not env vars)

**Use Cases**:
- Application configuration files
- Database connection strings
- Feature flags
- Non-sensitive cluster configuration

**Creating and Using Configs (Docker Swarm)**:
```bash
# Create config from file
docker config create app.conf app.conf.yml
docker config create --label env=prod nginx.conf nginx.prod.conf

# List configs
docker config ls

# Inspect config
docker config inspect app.conf

# Use in service
docker service create \
  --config source=app.conf,target=/etc/app/config.yml \
  --name myapp \
  myapp:1.0.0

# Multiple configs
docker service create \
  --config source=app.conf,target=/etc/app/app.conf \
  --config source=nginx.conf,target=/etc/nginx/nginx.conf \
  --name web \
  nginx:latest
```

**In Kubernetes (ConfigMap equivalent)**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  application.yaml: |
    server:
      port: 8080
      workers: 4
    database:
      timezone: UTC
  feature-flags.json: |
    {
      "enable_new_ui": true,
      "enable_analytics": false
    }
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:1.0.0
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
```

**Lifecycle - Config Updates**:

In Docker Swarm:
1. Create new config with version suffix: `app.conf.v2`
2. Update service: `docker service update --config-rm app.conf --config-add source=app.conf.v2,target=/etc/app/config.yml myapp`
3. Docker performs rolling restart
4. Old config can be deleted: `docker config rm app.conf`

### Docker Secrets

**What are Secrets?**
- Encrypted configuration data
- Only decrypted when mounted in container
- Available as files (not env vars)
- Encrypted in transit and at rest
- Not revealed in logs or inspect output
- Better for: passwords, API keys, certificates, tokens

**Creating Secrets (Docker Swarm)**:
```bash
# From file
docker secret create db_password ./password.txt

# From stdin
echo "supersecret" | docker secret create api_key -

# List secrets
docker secret ls

# Inspect (shows only metadata, not value)
docker secret inspect db_password
# Output: Name, Version, CreatedAt, UpdatedAt (no value!)
```

**Using Secrets in Services**:
```bash
# Single secret
docker service create \
  --secret source=db_password,target=db_password \
  --secret source=api_key,target=api_key \
  -e DATABASE_PASSWORD_FILE=/run/secrets/db_password \
  -e API_KEY_FILE=/run/secrets/api_key \
  --name myapp \
  myapp:1.0.0
```

**In Container - How to Use**:
```bash
# Secrets mounted as files in /run/secrets/
cat /run/secrets/db_password
# Output: supersecret

# Application code should read from file:
# Python example
with open('/run/secrets/db_password', 'r') as f:
    password = f.read().strip()
db = psycopg2.connect(password=password)

# Node.js example
const password = fs.readFileSync('/run/secrets/db_password', 'utf-8').trim();
const db = new Pool({ password });
```

**Secret Rotation**:
```bash
# Create new secret version
echo "newsecret" | docker secret create db_password_v2 -

# Update service (rolling restart)
docker service update \
  --secret-rm db_password \
  --secret-add source=db_password_v2,target=db_password \
  myapp

# Verify all replicas updated
docker service ps myapp

# Clean up old secret
docker secret rm db_password
```

**Kubernetes Secrets**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  password: c3VwZXJzZWNyZXQ=  # base64 encoded
  username: YWRtaW4=          # base64 encoded
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myapp:1.0.0
    volumeMounts:
    - name: secrets
      mountPath: /run/secrets
      readOnly: true
    env:
    - name: DB_PASSWORD_FILE
      value: /run/secrets/password
  volumes:
  - name: secrets
    secret:
      secretName: db-credentials
```

**Secrets vs Environment Variables - Decision Tree**:

```
Is it sensitive (password, key, token)?
├─ YES → Use Secrets (swarm) or Secret volumes (K8s)
└─ NO → Is it dynamic/changed at runtime?
        ├─ YES → Use Environment variables or Configs
        └─ NO → Bake into image via ARG

Is it sensitive AND very frequently rotated?
├─ YES → Use external secret manager (Vault, Sealed Secrets)
└─ NO → Docker secrets sufficient
```

### Build Arguments

**Recap - Build Args vs Runtime Env**:

Build args:
- Evaluated at image build time
- Immutable after build
- Can be used in RUN, FROM, COPY, ADD, WORKDIR, EXPOSE, ENV
- Can be cached

Runtime env:
- Set at container start
- Mutable
- Overrides ENV from Dockerfile
- No cache impact

**Advanced ARG Patterns**:

**Base Image Version via ARG**:
```dockerfile
ARG UBUNTU_VERSION=22.04
FROM ubuntu:${UBUNTU_VERSION}
```

```bash
docker build --build-arg UBUNTU_VERSION=20.04 .
docker build --build-arg UBUNTU_VERSION=24.04 .
# Same code, different base OS
```

**Conditional Build Steps**:
```dockerfile
ARG BUILD_TYPE=release
FROM ubuntu:22.04

# Cannot use ARG directly in IF...
# Solution: use RUN with shell conditionals
RUN if [ "${BUILD_TYPE}" = "debug" ]; then \
      apt-get install -y gdb strace; \
    fi

ARG BUILD_TYPE=release
# Store in env for runtime checks if needed
ENV BUILD_TYPE=${BUILD_TYPE}
```

**Cross-compilation**:
```dockerfile
ARG TARGETPLATFORM=linux/amd64
# Multi-architecture builds
FROM --platform=${TARGETPLATFORM} ubuntu:22.04
```

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t myapp:latest .
```

### Configuration Management Best Practices

**1. 12-Factor Config Discipline**:
```
Application Code (no hardcoded config)
        ↓
Defaults (safe fallbacks)
        ↓
Environment/Config loading
        ↓
Runtime behavior
```

**2. Config File Hierarchy**:
```dockerfile
FROM ubuntu:22.04

# System defaults baked in
COPY config/defaults.yaml /etc/app/defaults.yaml

# Allow override via mounts or ENV
# Container can:
# - Mount /etc/app/config.yaml (Configs/ConfigMap)
# - Mount /run/secrets/credentials (Secrets)
# - Accept ENV variables at runtime
```

**3. Secrets Rotation Without Downtime**:
```yaml
# Kubernetes with automatic secret reload
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        volumeMounts:
        - name: secrets
          mountPath: /run/secrets
          readOnly: true
      volumes:
      - name: secrets
        secret:
          secretName: db-credentials
          # Auto-updates when secret changes
```

Application must:
- Read secrets from file at startup
- Re-read periodically or watch for file changes
- Handle rotation gracefully

**4. Environment-Specific Configuration**:

```bash
# Development image
docker build -t myapp:dev --build-arg ENV=dev .

# Production image
docker build -t myapp:prod --build-arg ENV=prod .

# In Dockerfile
ARG ENV=dev
RUN if [ "$ENV" = "prod" ]; then \
      echo "Production build"; \
    else \
      echo "Development build"; \
    fi
```

**5. Configuration Validation**:

```dockerfile
FROM ubuntu:22.04

# Copy config schema validator
COPY scripts/validate-config.sh /app/

HEALTHCHECK --interval=30s CMD \
  /app/validate-config.sh /etc/app/config.yaml

# At startup
RUN /app/validate-config.sh /etc/app/defaults.yaml
```

### Advanced Pattern: External Secret Managers

**HashiCorp Vault Integration**:

Why Vault?
- Centralized secret storage with encryption at rest/transit
- Automatic secret rotation policies
- Detailed audit logging (who accessed what, when)
- Dynamic secrets (generate temporary credentials)
- Multi-environment support with RBAC

```bash
# Install Vault (Docker)
docker run -d \
  -p 8200:8200 \
  -e VAULT_DEV_ROOT_TOKEN_ID=myroot \
  vault:latest server -dev

# Write a secret
curl -X POST http://localhost:8200/v1/secret/prod/myapp/config \
  -H "X-Vault-Token: myroot" \
  -d '{
    "data": {
      "db_password": "secret123",
      "api_key": "key456"
    }
  }'

# Read a secret
curl http://localhost:8200/v1/secret/data/prod/myapp/config \
  -H "X-Vault-Token: myroot"
```

**Application Code - Vault Client**:
```python
import hvac
import os

client = hvac.Client(
    url=os.getenv('VAULT_ADDR', 'http://vault:8200'),
    token=os.getenv('VAULT_TOKEN')  # From secret mount
)

# Retrieve secret
secret = client.secrets.kv.read_secret_version(
    path='prod/myapp/config'
)

db_password = secret['data']['data']['db_password']
api_key = secret['data']['data']['api_key']

print(f"Password: {db_password}")
print(f"API Key: {api_key}")
```

**Kubernetes + Vault (Agent Injection)**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-database: "secret/data/prod/db"
        vault.hashicorp.com/agent-inject-template-database: |
          {{- with secret "secret/data/prod/db" -}}
          DATABASE_URL=postgres://user:{{ .Data.data.password }}@db:5432
          {{- end }}
    spec:
      serviceAccountName: myapp
      containers:
      - name: myapp
        image: myapp:1.0.0
        env:
        - name: VAULT_ADDR
          value: "http://vault.vault.svc.cluster.local:8200"
```

**Sealed Secrets - GitOps Pattern**:

For organizations using git as source of truth, Sealed Secrets provides encrypted secrets that can be committed to git.

```bash
# Install sealed-secrets operator
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Create a secret
kubectl create secret generic myapp-secret \
  --from-literal=db-password=mysecret \
  --dry-run=client -o yaml > secret.yaml

# Seal it (encrypt with public key)
kubeseal -f secret.yaml -w sealed-secret.yaml

# Now safe to commit to git
git add sealed-secret.yaml

# Deploy - controller automatically decrypts
kubectl apply -f sealed-secret.yaml

# Verify
kubectl get secret myapp-secret
```

**Sealed Secret Example**:
```yaml
# This is what gets committed to git (encrypted)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: myapp-secret
  namespace: default
spec:
  encryptedData:
    db-password: AgBvZ3B0TXl4Z0p3MzFmY1h... # Encrypted, safe in git
  template:
    type: Opaque
    metadata:
      name: myapp-secret
      namespace: default
```

### Compliance Patterns

**HIPAA/PCI-DSS/SOC2 Requirements**:

1. **Data Encryption**:
   - At rest: Use encrypted storage backends
   - In transit: All secrets encrypted with TLS
   - In memory: Secrets never written to unencrypted logs

2. **Access Control**:
   - RBAC: Segregate duty (developers ≠ secret access)
   - MFA: Multi-factor authentication for secret access
   - Service accounts: Limit to specific roles

3. **Audit Logging**:
   - All secret access logged
   - Who, what, when, where
   - Cannot be deleted (immutable audit log)

**RBAC Example - Developer vs DevOps**:

```yaml
# Developer role - NO secret access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
# Notably: NO secrets permission!

---
# DevOps role - SECRET access
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: devops-engineer
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

---
# Audit logging config
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Log all secret access
- level: RequestResponse
  verbs: ["get", "list", "create", "update", "patch", "delete"]
  resources: ["secrets"]
  omitStages:
  - RequestReceived
```

**Secret Policies - Automatic Rotation**:

```bash
# Vault policy for automatic rotation
path "secret/data/prod/*" {
  capabilities = ["create", "read", "update", "delete"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Docker Swarm secret rotation script
#!/bin/bash
set -e

SECRET_NAME=$1
DB_PASSWORD=$(docker secret ls | grep ${SECRET_NAME} | awk '{print $1}')

# Generate new secret
NEW_SECRET="${SECRET_NAME}_$(date +%s)"
echo "$NEW_RANDOM_PASSWORD" | docker secret create $NEW_SECRET -

# Update service to use new secret
docker service update \
  --secret-rm $DB_PASSWORD \
  --secret-add source=$NEW_SECRET,target=$DB_PASSWORD \
  --update-order start-first \
  myapp-service

# Wait for rollout
sleep 30

# Remove old secret
docker secret rm $DB_PASSWORD
```

### Environment-Specific Configuration Hierarchy

**Configuration Precedence (highest to lowest)**:

```
Command-line arguments       (Highest priority)
        ↓
Environment variables       (Can override config files)
        ↓
Secret mounts               (/run/secrets/*)
        ↓
Config mounts               (/etc/app/config/)
        ↓
.env file (development)     (Lowest for runtime)
        ↓
Dockerfile ENV              (Base defaults)
        ↓
Application defaults        (Fallback)
```

**Example - Web Service Configuration**:

```bash
# Base images with defaults
docker build -t myapp:base .
# Dockerfile ENV sets: PORT=8080, LOG_LEVEL=info

# Development mount
docker run -e LOG_LEVEL=debug \
           --env-file .env.local \
           myapp:base

# Production secret mount
docker service create \
  --secret db_password \
  --config app.conf \
  --env ENVIRONMENT=prod \
  myapp:base
```

---

## Docker Compose - Multi-container Orchestration, Networking, Volumes, Scaling

### Docker Compose Architecture

**What is Docker Compose?**
- Single-host container orchestration
- Declarative definition (YAML)
- Network creation automatic
- Volume management integrated
- Service discovery via service name
- Simple orchestration (no automatic restarts, rescheduling)

**Architecture Layers**:
```
docker-compose.yml (Human-readable definition)
        ↓
Compose Engine (Parse YAML, resolve variables)
        ↓
Docker API calls (Create networks, volumes, containers)
        ↓
Docker Engine (Actually run containers)
        ↓
Host OS (kernel, filesystem, networking)
```

**Compose Versions**:
- Version 1.x (deprecated): Simple format
- Version 2.x (legacy): Added networks, volumes
- Version 3.x (Compose Specification): Focus on Swarm compatibility, then Kubernetes

**Modern approach**: Specify `version: '3.8'` or `'3.9'` to support both Swarm and Compose deployment.

### docker-compose.yml Structure

**Minimal Example**:
```yaml
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
  
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
```

**Complete Example with All Key Sections**:
```yaml
version: '3.8'

# Define services (containers)
services:
  # Service 1: Web server
  web:
    # Image or build
    image: nginx:1.25-alpine
    # Alternative to image: build locally
    # build:
    #   context: .
    #   dockerfile: Dockerfile
    
    # Network exposure
    ports:
      - "80:80"      # Host:Container
      - "443:443"
    
    # Internal networking (for service-to-service)
    networks:
      - frontend
    
    # Volumes for persistence
    volumes:
      - ./config/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./html:/usr/share/nginx/html
      - shared-logs:/var/log/nginx
    
    # Environment configuration
    environment:
      NGINX_HOST: example.com
      NGINX_PORT: 80
    
    # Alternative: load from file
    # env_file:
    #   - .env
    #   - production.env
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M
    
    # Restart policy
    restart: unless-stopped
    # Options: no | always | unless-stopped | on-failure
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 1m
    
    # Logging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    
    # Dependencies (wait for service to be healthy)
    depends_on:
      db:
        condition: service_healthy
  
  # Service 2: Database
  db:
    image: postgres:15-alpine
    
    # Only expose to internal network (no ports)
    networks:
      - backend
    
    # Volumes for data persistence
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: dbpass
      POSTGRES_DB: myapp
      POSTGRES_INITDB_ARGS: "--encoding=UTF8"
    
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
    
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U dbuser"]
      interval: 10s
      timeout: 5s
      retries: 5
  
  # Service 3: Cache
  cache:
    image: redis:7-alpine
    networks:
      - backend
    volumes:
      - cache-data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s

# Define networks (bridge by default)
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge

# Define volumes
volumes:
  db-data:
    driver: local
  cache-data:
    driver: local
  shared-logs:
    driver: local
```

### Service Definitions

**Image vs Build**:

```yaml
# Use pre-built image from registry
services:
  app:
    image: myregistry.azurecr.io/myapp:1.0.0
    pull_policy: always  # Always fetch latest
```

```yaml
# Build from source
services:
  app:
    build:
      context: ./app              # Directory with Dockerfile
      dockerfile: Dockerfile      # Explicit Dockerfile name
      args:                       # Build arguments
        BUILD_ENV: production
        VERSION: 1.0.0
      cache_from:                 # Use these images for layer cache
        - myapp:latest
      target: production          # Multi-stage target stage
    image: myapp:1.0.0           # Tag the built image
```

**Restart Policies**:

```yaml
services:
  app:
    restart: unless-stopped
    # Options:
    # - no: Don't restart
    # - always: Restart even if exited successfully
    # - unless-stopped: Restart unless explicitly stopped
    # - on-failure: Restart only on non-zero exit
    
    # On-failure with retry limit
    restart_policy:
      condition: on-failure
      max_attempts: 3
      delay: 5s  # Wait before restart
```

**Command Override**:

```yaml
services:
  app:
    image: ubuntu:22.04
    entrypoint: /app/start.sh     # Override ENTRYPOINT
    command:                        # Override CMD
      - --debug
      - --port=8080
```

**User and Permissions**:

```yaml
services:
  app:
    image: myapp:1.0.0
    user: "1000:1000"              # UID:GID
    # or user: appuser
    
    # Drop capabilities for security
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE           # Allow port binding
```

### Networks in Docker Compose

**Default Behavior**:
```yaml
version: '3.8'

services:
  web:
    image: nginx
  db:
    image: postgres
```

Behind the scenes:
1. Docker creates network: `<project>_default`
2. Both services join network
3. Containers can reach each other by service name
   - `web` container resolves to nginx container IP
   - `db` container resolves to postgres container IP

**Multiple Networks**:

```yaml
version: '3.8'

services:
  web:
    image: nginx
    networks:
      - frontend
  
  api:
    image: api:latest
    networks:
      - frontend
      - backend
  
  db:
    image: postgres
    networks:
      - backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

**Service Discovery Across Networks**:
- `web` on frontend can reach `api` (both on frontend)
- `api` can reach both `web` and `db` (on both networks)
- `db` cannot directly reach `web` (different networks)

**Custom Network Configuration**:

```yaml
networks:
  internal:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: br-internal
      com.docker.network.driver.mtu: 1450
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1

services:
  app:
    networks:
      internal:
        ipv4_address: 172.20.0.10
```

**Network Aliases** (Multiple names for same service):

```yaml
services:
  db:
    image: postgres
    networks:
      backend:
        aliases:
          - database
          - postgres
          - backend-db

  web:
    image: myapp
    environment:
      DATABASE_HOST: database  # Can use alias
    networks:
      - backend
```

**Differences Between Network Types**:

| Network Type | Use Case | Reaches Outside | Inter-service DNS |
|-------------|----------|---------------|--------------------|
| bridge | Default, dev | Via port mappings | service name |
| host | Performance-critical | Direct | No DNS |
| overlay | Multi-host (Swarm) | Via swarm routing mesh | service name |

### Volumes & Bind Mounts

**Named Volumes** (Managed by Docker):

```yaml
volumes:
  db-data:
    driver: local
    driver_opts:
      type: tmpfs              # RAM disk
      device: tmpfs
      o: size=1024m

services:
  db:
    image: postgres
    volumes:
      - db-data:/var/lib/postgresql/data
```

**Bind Mounts** (Host filesystem):

```yaml
services:
  app:
    image: myapp
    volumes:
      # Host path : Container path : [Mode]
      - ./app:/app                   # Default: rw
      - ./config:/etc/app:ro         # Read-only
      - ~/.ssh:/root/.ssh:ro         # Mount SSH keys
      - /tmp:/tmp                    # Shared tmpfs
```

**tmpfs Mounts** (In-memory, ephemeral):

```yaml
services:
  app:
    image: myapp
    tmpfs:
      - /tmp
      - /run
    volumes:
      - /cache:size=1g               # Sized tmpfs
```

**Volume Permissions & Ownership**:

```yaml
services:
  app:
    image: myapp
    user: "1000:1000"
    volumes:
      # Bind mount with permission matching
      - ./app:/app
      # Or pre-create with desired ownership:
      # mkdir -p ./app && chown 1000:1000 ./app
```

**Volume Lifecycle**:

```bash
# Create named volume
docker volume create mydata

# List volumes
docker volume ls

# Use in compose
# volumes:
#   - mydata:/data

# Copy data between volumes
docker run --rm -v source:/src -v dest:/dst \
  ubuntu cp -r /src/* /dst/

# Cleanup
docker volume rm mydata
```

### Scaling & Replication

**Scaling Services with Compose**:

```bash
# Run 3 instances of web service
docker-compose up -d --scale web=3

# Creates: web_1, web_2, web_3
# Each on different port (8080, 8081, 8082)
```

**Port Mapping with Scaling**:

```yaml
services:
  web:
    image: nginx
    ports:
      - "80:80"  # ERROR with --scale >1 (port conflict)
    
    # Better: use dynamic port mapping
    ports:
      - "80"     # Host picks random port
```

**Load Balancing Behind Service**:

```yaml
version: '3.8'

services:
  proxy:
    image: nginx
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - web
  
  web:
    image: myapp:1.0.0
    # No ports: not directly accessible
    # Only via proxy (internal network)
```

**nginx.conf for load balancing**:
```nginx
upstream backend {
  server web:8080;
  # Docker Compose DNS resolves 'web' to all instances
}

server {
  listen 80;
  location / {
    proxy_pass http://backend;
    proxy_redirect off;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
```

**Scaling with Resource Constraints**:

```yaml
services:
  api:
    image: api:1.0.0
    deploy:
      replicas: 3                # Explicitly set replicas
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    # Total: can use up to 3 CPUs, 1.5GB memory
```

**Health-Aware Scaling**:
```yaml
services:
  api:
    image: api:latest
    deploy:
      replicas: 3
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 2
    
    # Compose doesn't auto-scale based on health
    # But orchestrators (K8s, Swarm) do
```

### Advanced Docker Compose Patterns

**Environment-Aware Composition**:

```bash
# Use .env files for environment-specific values
docker-compose --env-file .env.prod up -d

# Or override specific services
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               up -d
```

**docker-compose.yml** (Base):
```yaml
version: '3.8'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: dbuser
    volumes:
      - db-data:/var/lib/postgresql/data
```

**docker-compose.prod.yml** (Production overrides):
```yaml
version: '3.8'
services:
  db:
    # Override image tag
    image: postgres:15-alpine
    # Override environment
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    # Add secrets
    secrets:
      - db_password
    # Add resource constraints
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
    
    secrets:
      db_password:
        external: true  # Reference secret created outside
```

**Dependency Management with Health Checks**:

```yaml
version: '3.8'
services:
  app:
    image: myapp:1.0.0
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_healthy
    environment:
      DATABASE_HOST: db
      REDIS_HOST: cache
  
  db:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s
  
  cache:
    image: redis:7
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
```

**Initialization Pattern - Database Migrations**:

```yaml
version: '3.8'
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: myapp
    volumes:
      # SQL init scripts run automatically
      - ./init/001-schema.sql:/docker-entrypoint-initdb.d/001-schema.sql:ro
      - ./init/002-data.sql:/docker-entrypoint-initdb.d/002-data.sql:ro
  
  migrate:
    image: migrate/migrate:latest
    volumes:
      - ./migrations:/migrations:ro
    command:
      - "-path"
      - "/migrations"
      - "-database"
      - "postgres://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}?sslmode=disable"
      - "up"
    depends_on:
      db:
        condition: service_healthy
  
  app:
    image: myapp:1.0.0
    depends_on:
      migrate:
        condition: service_completed_successfully
    environment:
      DATABASE_URL: postgres://myuser:${DB_PASSWORD}@db:5432/myapp
```

**Multi-Stage Build Optimization**:

```dockerfile
# Stage 1: Build
FROM golang:1.21 as builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Stage 2: Runtime (minimal)
FROM alpine:3.18
RUN apk add --no-cache ca-certificates
COPY --from=builder /build/app /app
HEALTHCHECK CMD /app --health || exit 1
ENTRYPOINT ["/app"]
```

In docker-compose:
```yaml
services:
  app:
    build:
      context: .
      target: runtime          # Use runtime stage
    image: myapp:1.0.0
```

**Service Versioning & Rollback**:

```bash
# Deploy v1.2.0
docker-compose -f docker-compose.yml down
docker pull myregistry.azurecr.io/myapp:1.2.0
docker-compose up -d

# Monitor logs
docker-compose logs -f app

# If issues: rollback to v1.1.0
docker pull myregistry.azurecr.io/myapp:1.1.0
sed -i 's/myapp:1.2.0/myapp:1.1.0/' docker-compose.yml
docker-compose up -d

# Verify
docker-compose ps
```

**Networking - Isolation & Security**:

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    internal: true           # Isolated from outside
  cache-network:
    driver: bridge

services:
  web:
    image: nginx
    networks:
      - frontend
    ports:
      - "80:80"
      - "443:443"
  
  api:
    image: myapp
    networks:
      - frontend               # Receives traffic from web
      - backend                # Talks to database
    expose:
      - "8000"                 # Available internally
    # No ports: not accessible from host
  
  db:
    image: postgres
    networks:
      - backend
    # No ports, no networks to web: maximum isolation
  
  cache:
    image: redis
    networks:
      - cache-network
    # Only api can reach if on same network
```

**Production Checklist**:

```yaml
version: '3.8'
services:
  app:
    image: myapp:1.0.0
    
    # ✓ Resource limits
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    
    # ✓ Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 2
      start_period: 30s
    
    # ✓ Restart policy
    restart: unless-stopped
    
    # ✓ Logging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    
    # ✓ Environment from external
    env_file: .env.prod
    
    # ✓ Secrets from external
    secrets:
      - db_password
    
    # ✓ Read-only root (security)
    read_only: true
    tmpfs:
      - /tmp
      - /run
    
    # ✓ Drop privileges
    user: "1000:1000"
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    
    # ✓ Network isolation
    networks:
      - backend
    # No ports: protected from direct access
    
    # ✓ Dependency management
    depends_on:
      db:
        condition: service_healthy

secrets:
  db_password:
    file: ./secrets/db_password.txt

networks:
  backend:
    driver: bridge
```

---

## Logging & Monitoring - Container Logs, Log Drivers, Centralized Logging, Metrics, Health Checks, Alerting

### Container Logging Fundamentals

**How Docker Captures Logs**:

1. Application writes to STDOUT or STDERR
2. Docker captures these streams
3. Log driver processes the logs
4. Logs can be local (json-file) or remote (syslog, splunk, etc.)

```bash
# View captured logs
docker logs <container>
docker logs -f <container>         # Follow
docker logs --tail 100 <container> # Last 100 lines
docker logs --since 1h <container> # Last hour

# In docker-compose
docker-compose logs <service>
docker-compose logs -f web api      # Multiple services
```

**Log Metadata** (JSON File Driver):

```json
{
  "log": "2024-03-07T10:15:30.123Z - Start request",
  "stream": "stdout",
  "time": "2024-03-07T10:15:30.123456Z"
}
```

**Default Behavior Issues**:
- All logs stored locally: `/var/lib/docker/containers/<id>/<id>-json.log`
- No automatic rotation: logs grow without bound
- Container deletion = log loss
- No centralized view across containers

**Solution**: Configure log drivers for persistence, rotation, and centralization.

### Log Drivers

**Available Drivers**:

| Driver | Destination | Use Case | Rotation |
|--------|------------|----------|----------|
| json-file | Local file | Development | configurable |
| syslog | Syslog protocol | Traditional systems | via syslog |
| journald | systemd journal | Modern Linux | journal rotation |
| splunk | Splunk | Enterprise logging | remote |
| awslogs | CloudWatch | AWS environments | AWS managed |
| awsfirelens | FireLens proxy | Advanced AWS | via proxy |
| gcplogs | Google Cloud Logging | GCP | GCP managed |
| logentries | Rapid7 Logentries | SaaS logging | SaaS managed |
| sumologic | Sumo Logic | SaaS logging | SaaS managed |
| none | Discarded | Disable logging | N/A |

**Configuring Log Drivers**:

**Daemon-level** (all containers):
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**Container-level** (override):
```bash
docker run --log-driver json-file \
           --log-opt max-size=10m \
           --log-opt max-file=3 \
           --log-opt labels=env \
           -l env=prod \
           myapp
```

**Docker Compose**:
```yaml
services:
  app:
    image: myapp
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        labels: "service=myapp,env=prod"
```

**JSON File Driver with Rotation**:

```yaml
logging:
  driver: json-file
  options:
    max-size: "10m"      # Rotate when file reaches 10MB
    max-file: "3"        # Keep 3 rotated files
    labels: "service"    # Include labels in logs
    env-regex: "^(ENVIRONMENT|LOG_LEVEL)="  # Include specific env vars
```

Monitor log file size:
```bash
du -h /var/lib/docker/containers/*/
```

**Syslog Driver** (Traditional logging):

```bash
docker run --log-driver syslog \
           --log-opt syslog-address=udp://logs.example.com:514 \
           --log-opt syslog-facility=local0 \
           --log-opt tag="{{.Name}}/{{.FullID}}" \
           myapp

# Receives logs on syslog server:
# 2024 Mar 07 10:15:30 container-name myapp/full-id: log message
```

**Splunk Driver** (Enterprise):

```bash
docker run --log-driver splunk \
           --log-opt splunk-token=your-hec-token \
           --log-opt splunk-url=https://splunk.example.com:8088 \
           --log-opt splunk-format=json \
           --log-opt splunk-sourcetype=docker \
           --log-opt tag="{{.Name}}" \
           myapp
```

**AWS CloudWatch**:

```bash
docker run --log-driver awslogs \
           --log-opt awslogs-group=/aws/ecs/myapp \
           --log-opt awslogs-region=us-west-2 \
           --log-opt awslogs-stream-prefix=container \
           --log-opt awslogs-datetime-format="%Y-%m-%d %H:%M:%S" \
           myapp

# Requires IAM permissions:
# - logs:CreateLogGroup
# - logs:CreateLogStream
# - logs:PutLogEvents
```

### Centralized Logging Architecture

**ELK Stack** (Elasticsearch, Logstash, Kibana):

```
┌─────────────────────────────────────────┐
│ Docker Containers                       │
│  - Syslog driver                        │
│  - Filebeat (log shipper)               │
│  - Fluentd (multi-source collector)     │
└────────────┬────────────────────────────┘
             │
             ↓ (Ship logs via TCP/HTTP)
        ┌────────────┐
        │  Logstash  │ (Parse, enrich, transform)
        │  or        │ (Add metadata, grok patterns)
        │  Filebeat  │
        └────────────┘
             │
             ↓
      ┌─────────────┐
      │Elasticsearch│ (Index and store)
      └─────────────┘
             │
             ↓
       ┌──────────┐
       │  Kibana  │ (Visualize and query)
       └──────────┘
```

**Fluentd Configuration** (Centralized collection):

```yaml
# fluent.conf
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

<filter docker.app>
  @type parser
  key_name log
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</filter>

<filter docker.>
  @type modify
  <replace>
    key hostname
    expression ${Socket.gethostname}
  </replace>
</filter>

<match docker.>
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
  logstash_prefix app-logs
  logstash_dateformat %Y.%m.%d
  include_tag_key true
  tag_key @_fluentd_tag
  type_name _doc
  <buffer>
    @type file
    path /fluentd/log/buffer/
    flush_mode interval
    flush_interval 10s
    chunk_limit_size 5m
  </buffer>
</match>
```

**Docker Compose - ELK Stack**:

```yaml
version: '3.8'

services:
  # Container 1: Application
  app:
    image: myapp:1.0.0
    logging:
      driver: fluentd
      options:
        fluentd-address: fluentd:24224
        labels: "app=myapp,env=prod"
    networks:
      - logging
  
  # Container 2: Fluentd collector
  fluentd:
    image: fluent/fluentd:v1.16-1
    ports:
      - "24224:24224"
    volumes:
      - ./fluent.conf:/fluentd/etc/fluent.conf:ro
      - fluentd-buffer:/fluentd/log
    networks:
      - logging
    depends_on:
      - elasticsearch
  
  # Container 3: Elasticsearch (search/storage)
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    volumes:
      - es-data:/usr/share/elasticsearch/data
    networks:
      - logging
    healthcheck:
      test: curl --fail http://localhost:9200/_cluster/health || exit 1
  
  # Container 4: Kibana (visualization)
  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    ports:
      - "5601:5601"
    environment:
      ELASTICSEARCH_HOSTS: '["http://elasticsearch:9200"]'
    networks:
      - logging
    depends_on:
      - elasticsearch

volumes:
  fluentd-buffer:
  es-data:

networks:
  logging:
```

**Loki** (Lightweight alternative to ELK):

```yaml
# loki-config.yaml
auth_enabled: false

ingester:
  chunk_idle_period: 3m
  max_chunk_age: 1h

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

schema_config:
  configs:
  - from: 2020-10-24
    store: boltdb-shipper
    object_store: filesystem
    schema:
      version: v11
      index:
        prefix: index_
        period: 24h

server:
  http_listen_port: 3100
  log_level: info
```

**Docker Compose - Loki + Promtail**:

```yaml
version: '3.8'

services:
  app:
    image: myapp:1.0.0
    logging:
      driver: loki
      options:
        loki-url: "http://loki:3100/loki/api/v1/push"
        loki-batch-size: "100"
        loki-max-retries: "5"
        loki-timeout: "1s"
        loki-retries: "2"
    networks:
      - logging

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yaml:/etc/loki/local-config.yaml:ro
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - logging

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - logging

volumes:
  loki-data:
  grafana-data:

networks:
  logging:
```

### Metrics Collection & Monitoring

**What are Metrics?**
- Quantitative measurements over time
- CPU%, memory usage, request latency, error rates
- Time-series data (timestamp + value)

**Container Metrics Available**:

```bash
# Real-time stats
docker stats <container>
docker stats --no-stream  # Single snapshot

# Example output:
# CONTAINER    CPU %    MEM USAGE / LIMIT    MEM %    NET I/O
# myapp        15.2%    256MB / 1GB          25%      1.2MB / 800KB
```

**Prometheus** (Metrics collection):

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']  # Docker metrics endpoint

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'cadvisor'              # Container runtime metrics
    static_configs:
      - targets: ['cadvisor:8080']
```

**Docker Compose - Prometheus + cAdvisor**:

```yaml
version: '3.8'

services:
  # Container 1: Application
  app:
    image: myapp:1.0.0
    networks:
      - monitoring

  # Container 2: cAdvisor (collects container metrics)
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    ports:
      - "8080:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    networks:
      - monitoring
    devices:
      - /dev/kmsg

  # Container 3: Prometheus
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    networks:
      - monitoring
    depends_on:
      - cadvisor

  # Container 4: Grafana (visualization)
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring
    depends_on:
      - prometheus

volumes:
  prometheus-data:
  grafana-data:

networks:
  monitoring:
```

**Key Container Metrics**:

```promql
# CPU usage percentage
rate(container_cpu_usage_seconds_total{name="myapp"}[5m]) * 100

# Memory usage (bytes)
container_memory_usage_bytes{name="myapp"}

# Network received (bytes)
rate(container_network_receive_bytes_total{name="myapp"}[1m])

# Disk I/O (bytes)
rate(container_fs_io_current{name="myapp"}[1m])
```

### Health Checks & Self-Healing

**HEALTHCHECK in Dockerfile**:

```dockerfile
FROM ubuntu:22.04

EXPOSE 8080
CMD ["python", "-m", "http.server", "8080"]

# Basic health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

**Health Check Fields**:

| Field | Default | Meaning |
|-------|---------|---------|
| interval | 30s | Check frequency |
| timeout | 30s | How long to wait for response |
| retries | 3 | Consecutive failures before unhealthy |
| start_period | 0s | Grace period during startup |

**Health Check Output**:

```bash
# Health status
docker container inspect myapp --format='{{.State.Health.Status}}'
# Output: starting, healthy, unhealthy

# Recent checks
docker container inspect myapp --format='{{json .State.Health.Log}}' | jq .
```

**Docker Compose Health Check**:

```yaml
services:
  app:
    image: myapp
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 1m

  web:
    image: nginx
    depends_on:
      app:
        condition: service_healthy  # Wait for health check to pass
```

**Application-Level Health Endpoint**:

```python
# Flask example
@app.route('/health')
def health():
    checks = {
        'database': check_db_connection(),
        'cache': check_cache_connection(),
        'disk_space': check_disk_space(),
    }
    
    if all(checks.values()):
        return {'status': 'healthy'}, 200
    else:
        return {'status': 'unhealthy', 'checks': checks}, 503
```

**Kubernetes Liveness vs Readiness**:

```yaml
# Kubernetes probes (more sophisticated)
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    
    # Restart if unhealthy
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    # Remove from load balancer if not ready
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
      timeoutSeconds: 1
      failureThreshold: 1
```

**Docker-Compose Self-Healing** (Limited):

```yaml
services:
  app:
    image: myapp
    restart: unless-stopped  # Restarts on failure
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 2
    
    # Docker only stops/restarts container
    # Swarm/K8s provides more sophisticated orchestration
```

### Alerting & Incident Response

**Alert Rules** (Prometheus):

```yaml
# alert-rules.yml
groups:
  - name: app_alerts
    interval: 30s
    rules:
      # High CPU usage
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 5m
        annotations:
          summary: "{{ $labels.name }} CPU {{ $value | humanizePercentage }}"

      # Container down
      - alert: ContainerDown
        expr: up{job="docker"} == 0
        for: 1m
        annotations:
          summary: "Container {{ $labels.name }} is down"

      # Memory pressure
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_memory_limit_bytes > 0.9
        for: 2m
        annotations:
          summary: "{{ $labels.name }} memory {{ $value | humanizePercentage }}"

      # OOM kills
      - alert: OOMKill
        expr: increase(container_memory_failures_total[5m]) > 0
        annotations:
          summary: "{{ $labels.name }} experienced OOM"
```

**Alertmanager Configuration**:

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  slack_api_url: "https://hooks.slack.com/services/YOUR/WEBHOOK"

route:
  receiver: 'slack'
  group_by: ['alertname', 'cluster']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  routes:
    - match:
        severity: critical
      receiver: slack_critical
      repeat_interval: 5m

receivers:
  - name: 'slack'
    slack_configs:
      - channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'

  - name: 'slack_critical'
    slack_configs:
      - channel: '#critical-alerts'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.summary }}\n{{ end }}'
        send_resolved: true
```

**Docker Compose - Full Monitoring Stack**:

```yaml
version: '3.8'

services:
  app:
    image: myapp:1.0.0
    logging:
      driver: loki
      options:
        loki-url: "http://loki:3100/loki/api/v1/push"
    networks:
      - monitoring

  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./alert-rules.yml:/etc/prometheus/alert-rules.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--alertmanager.url=http://alertmanager:9093'
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - grafana-data:/var/lib/grafana
    networks:
      - monitoring

  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    networks:
      - monitoring

volumes:
  prometheus-data:
  grafana-data:
  loki-data:

networks:
  monitoring:
```

**Incident Response Workflow**:

1. **Alert Fired**: Prometheus detects condition
2. **Notification**: AlertManager sends to Slack/Teams/Email
3. **Investigation**: Engineer queries logs (Loki) + metrics (Grafana)
4. **Diagnosis**: Root cause identified
5. **Action**: Restart container, scale up, fix code
6. **Resolution**: Alert clears once metric recovers

**Best Practices**:
- Alert on business impact, not raw metrics
- Silence noisy alerts (non-critical, high false positive)
- Document runbooks: what each alert means, how to fix
- Practice incident response regularly
- Post-mortems after major incidents

### Advanced: Complete Enterprise Monitoring Stacks

**ELK Stack (Elasticsearch/Logstash/Kibana) for Full-Text Search**:

```yaml
version: '3.8'

services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      - node.name=es01
      - cluster.name=elasticsearch
      - discovery.type=single-node
      - xpack.security.enabled=false
      - \"ES_JAVA_OPTS=-Xms512m -Xmx512m\"
    ports:
      - \"9200:9200\"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    networks:
      - elk

  logstash:
    image: docker.elastic.co/logstash/logstash:8.0.0
    volumes:
      - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf:ro
    environment:
      - \"LS_JAVA_OPTS=-Xmx256m -Xms256m\"
    ports:
      - \"5000:5000\"
    depends_on:
      - elasticsearch
    networks:
      - elk

  kibana:
    image: docker.elastic.co/kibana/kibana:8.0.0
    ports:
      - \"5601:5601\"
    environment:
      ELASTICSEARCH_HOSTS: http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - elk

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.0.0
    user: root
    volumes:
      - ./filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
    command: filebeat -e -strict.perms=false
    depends_on:
      - elasticsearch
    networks:
      - elk

volumes:
  elasticsearch-data:

networks:
  elk:
```

**logstash.conf** (Parse and enrich logs):
```
input {
  tcp {
    port => 5000
    codec => json
  }
}

filter {
  if [type] == \"docker\" {
    mutate {
      add_field => { \"[@metadata][index_name]\" => \"docker-%{+YYYY.MM.dd}\" }
    }
  }
  
  # Parse structured logs
  grok {
    match => { \"message\" => \"%{TIMESTAMP_ISO8601:timestamp} \\\\[%{DATA:level}\\\\] %{GREEDYDATA:msg}\" }
  }
  
  # Parse timestamp
  date {
    match => [ \"timestamp\", \"ISO8601\" ]
    target => \"@timestamp\"
  }
  
  # Add service metadata
  mutate {
    add_field => { \"[@metadata][pipeline]\" => \"main\" }
  }
}

output {
  elasticsearch {
    hosts => [\"elasticsearch:9200\"]
    index => \"%{[@metadata][index_name]}\"
    pipeline => \"%{[@metadata][pipeline]}\"
  }
}
```

**Kibana Queries** (Log analysis):
```
# Find all errors in production
environment: prod AND level: ERROR

# API latency spikes
service: api AND response_time: >= 1000

# Database connection failures
service: postgres AND ERROR AND \"connection refused\"

# Track specific user actions
user_id: \"12345\" AND action: \"login\"
```

**Loki Stack (Cost-optimized, index-less logging)**:

```yaml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    ports:
      - \"3100:3100\"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki

  promtail:
    image: grafana/promtail:latest
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki
    networks:
      - loki

  grafana:
    image: grafana/grafana:latest
    ports:
      - \"3000:3000\"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
    volumes:
      - grafana-data:/var/lib/grafana
    depends_on:
      - loki
    networks:
      - loki

volumes:
  loki-data:
  grafana-data:

networks:
  loki:
```

**Loki Queries** (LogQL for metrics from logs):
```
# Count errors per second
count_over_time({job=\"api\"} | json | level=\"ERROR\" [1m])

# Rate of  4xx errors
rate({service=\"api\"} | json | status=~\"4..\" [5m])

# P95 latency from logs
quantile_over_time(0.95, {service=\"api\"} | json | duration [5m])

# Service health (success rate)
sum(rate({service=\"api\"} | json | status=~\"2..\" [5m]))
/
sum(rate({service=\"api\"} [5m]))
```

**Cost Optimization Comparison**:

| Platform | Storage/month | Retention | Search Speed | Best For |
|----------|--------------|-----------|------------|-----------|
| Elasticsearch | $50+/GB | 1-30 days | Very fast | Full-text search |
| Loki | $1-5/GB | 30-90 days | Fast | Label-based |
| S3 Archive | $0.02/GB | Years | Slow (query via Athena) | Compliance |

**Hybrid Strategy** (Cost-effective):
```
Real-time (1 week)   → Loki      ($5/month)
Hot (30 days)        → Loki      ($15/month)
Warm (90 days)       → Loki      ($30/month)
Cold (1+ years)      → S3        ($2/month)
```

### SLO/SLI Integration - Monitoring Service Quality

**Service Level Indicator (SLI)** = Actual measurement
**Service Level Objective (SLO)** = Target we commit to

```yaml
# Prometheus recording rules for SLIs
groups:
  - name: sli_metrics
    interval: 1m
    rules:
      # Request latency percentiles
      - record: sli:request_latency:p50
        expr: histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))
      
      - record: sli:request_latency:p95
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
      
      - record: sli:request_latency:p99
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
      
      # Error rate SLI
      - record: sli:error_rate
        expr: |
          sum(rate(http_requests_total{status=~\"5..\"}[5m]))
          /
          sum(rate(http_requests_total[5m]))
      
      # Availability SLI (all replicas healthy)
      - record: sli:availability
        expr: |
          count(up{job=\"app\"} == 1)
          /
          count(up{job=\"app\"})
```

**SLO Definition Example** (E-commerce API):
```
Availability SLO:    99.95% monthly (43.2 minutes downtime allowed)
Latency SLO:         P99 < 200ms (99% of requests faster)
Error Rate SLO:      < 0.1% (99.9% success rate)

Error Budget per day: (1 - 0.9995) * 1440 minutes = 0.72 minutes
Error Budget per week: (1 - 0.9995) * 10080 minutes = 5 minutes
Error Budget per month: (1 - 0.9995) * 43200 minutes = ~22 minutes
```

**Error Budget Consumption Alerts**:
```yaml
- alert: ErrorBudgetBurningFast
  expr: |
    (1 - increase(sli:availability[1h])) 
    > 
    (1 - 0.9995) * 30  # 30 days worth in 1 hour
  for: 5m
  annotations:
    summary: \"Error budget consuming 30x normal rate\"
    action: \"Page on-call engineer, investigate immediately\"

- alert: ErrorBudgetDepleted
  expr: |
    increase(sli:error_budget_remaining[30d]) < 0
  annotations:
    summary: \"Monthly error budget depleted\"
    action: \"Stop deployments, focus on reliability fixes\"
```

**SLO Dashboard in Grafana**:
```promql
# Remaining error budget (%)
(1 - SLO_TARGET) * 100 - increase(sli:error_rate[30d]) * 100

# Days remaining at current burn rate
error_budget_seconds_remaining / (sli:error_rate * 86400)

# Latency compliance %
(histogram_quantile(0.99, ...) <= 0.2) * 100
```

---

## Hands-on Scenarios

### Scenario 1: Diagnosing Memory Leak & OOM Kill in Production

**Problem Statement**:
A production microservice that processes user requests starts failing after 2-3 hours of operation. The service restarts repeatedly, and the team sees error logs: "Killed" with exit code 137 (OOM kill signal). The service works fine in development but fails under production load.

**Architecture Context**:
```
Load Balancer → Kubernetes Cluster
├─ 3 replicas of API service
├─ Postgres database
├─ Redis cache
└─ Filebeat/Loki logging
```

**Symptoms Observed**:
1. Container exits with code 137 (OOM kill)
2. Memory usage grows linearly over time
3. No error messages in application logs before kill
4. Occurs under load, not during idle time
5. Restarting temporarily fixes the issue

**Step-by-Step Troubleshooting**:

**Step 1: Confirm OOM Kill**
```bash
# Check container exit status in Kubernetes
kubectl describe pod myapp-xyz-abc

# Look for: "OOMKilled: true" or "Exit Code 137"
# In Docker: docker inspect <container> | grep -A5 State

# Check syslog for OOM killer
dmesg | grep -i "out of memory"
# Output: "[timestamp] Out of memory: Kill process 1234 (python) score 342 or sacrifice child"
```

**Step 2: Get Memory Metrics**
```bash
# Check max memory usage
kubectl top pod myapp-xyz-abc --containers

# Check memory limits
kubectl describe pod myapp-xyz-abc | grep -A5 Limits

# Expected output shows:
# Limits: memory 512Mi
# Current usage: 450Mi at ~2 hours, killed at 512Mi
```

**Step 3: Analyze Memory Growth Pattern**
```bash
# Get historical metrics from Prometheus
promql> container_memory_usage_bytes{pod_name="myapp"} / 1024 / 1024

# Or in Grafana query:
rate(container_memory_usage_bytes[5m]) 
# Shows: linear growth = leak, jumps = cache buildup

# Check for memory caching vs actual leak
# True leak: monotonic growth
# Cache: plateaus after warming up
```

**Step 4: Identify Root Cause**
```python
# Application analysis: Check for common memory leaks

# Bad pattern 1: Global list accumulating objects
results = []  # GLOBAL
@app.route('/process')
def handle_request():
    results.append(process_data())  # Grows unbounded!
    return "OK"

# Bad pattern 2: Unclosed database connections
db_conn = get_db_connection()
# Missing: db_conn.close()

# Bad pattern 3: Large caches without TTL
cache = {}
@app.route('/api/data/<id>')
def get_data(id):
    if id not in cache:
        cache[id] = fetch_from_db(id)  # Grows unbounded!
    return cache[id]
```

**Step 5: Memory Profiling**
```bash
# Install memory profiler (Python example)
pip install memory-profiler pytest-memray

# Run with profiling
python -m memory_profiler app.py

# Or use debugpy for remote profiling
# docker run -e DEBUGPY_LISTEN=0.0.0.0:5678 myapp

# In production with py-spy (sampling profiler):
docker exec -it <container> pip install py-spy
docker exec -it <container> py-spy record -d 60 -o memory.svg --function
```

**Root Cause Found**:
After analysis, the issue is discovered in the caching layer:
```python
# INCORRECT: Cache grows unbounded
@app.route('/api/config/<config_id>')
def get_config(config_id):
    if config_id not in request_cache:
        request_cache[config_id] = expensive_query(config_id)
    return request_cache[config_id]

# Over 2 hours: 10k unique configs × 50KB = 500MB = OOM
```

**Step 6: Implementation of Fix**

**Option A: TTL-based Cache (Redis)**
```python
import redis
from functools import wraps

client = redis.Redis(host='redis', port=6379)

def cached_query(key, ttl=3600):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cached = client.get(key)
            if cached:
                return json.loads(cached)
            result = func(*args, **kwargs)
            client.setex(key, ttl, json.dumps(result))
            return result
        return wrapper
    return decorator

@app.route('/api/config/<config_id>')
@cached_query(f"config:{config_id}", ttl=600)
def get_config(config_id):
    return expensive_query(config_id)
```

**Option B: LRU Cache with Limit**
```python
from functools import lru_cache

@lru_cache(maxsize=1000)  # Only cache 1000 most recent
def get_config(config_id):
    return expensive_query(config_id)

# Or use cachetools:
from cachetools import TTLCache
cache = TTLCache(maxsize=1000, ttl=600)  # 1000 items, 10min TTL

@app.route('/api/config/<config_id>')
def get_config(config_id):
    if config_id in cache:
        return cache[config_id]
    result = expensive_query(config_id)
    cache[config_id] = result
    return result
```

**Step 7: Update Resource Limits Based on Data**

Analysis determined:
- Average steady-state memory: 200MB
- Peak with caching: 400MB
- Safety margin: 500MB

```yaml
# Kubernetes deployment updated
spec:
  containers:
  - name: myapp
    resources:
      requests:
        memory: "300Mi"        # Tell scheduler we need 300MB
        cpu: "500m"
      limits:
        memory: "500Mi"        # Hard limit to prevent OOM kill
        cpu: "1000m"
    
    # Add downward API for app awareness
    env:
    - name: MEMORY_LIMIT
      valueFrom:
        resourceFieldRef:
          containerName: myapp
          resource: limits.memory
```

**Step 8: Add Monitoring & Alerting**

```yaml
# Prometheus alert rules
- alert: MemoryLeakDetected
  expr: |
    rate(container_memory_usage_bytes{pod="myapp"}[1h]) > 0
    and
    container_memory_usage_bytes{pod="myapp"} / container_memory_limit_bytes{pod="myapp"} > 0.7
  for: 30m
  annotations:
    summary: "Memory leak suspected in {{ $labels.pod }}"
    
- alert: HighMemoryUsageSpiking
  expr: container_memory_usage_bytes{pod="myapp"} / container_memory_limit_bytes > 0.9
  for: 5m
  annotations:
    runbook: "scale up OR check caching logic"
```

**Best Practices Applied**:
1. ✅ Proactive monitoring: Memory rate of change
2. ✅ Resource limits: Prevent cascading failures
3. ✅ Proper caching: TTL or bounded size
4. ✅ Memory profiling: Identify root cause
5. ✅ Testing: Load test in staging before production
6. ✅ Alerting: Detect before OOM kill occurs

---

### Scenario 2: Multi-environment Configuration Management with Secrets

**Problem Statement**:
A team manages a microservices application deployed across dev, staging, and production environments. Currently using environment variables for everything, but encountered security breach: database credentials were visible in logs and container inspect. They need to implement proper secrets management with rotation capability.

**Architecture Context**:
```
┌─────────────────────────────────────────────────┐
│ Development Environment                         │
│ - Docker Compose                                │
│ - Local secrets in .env files                   │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│ Staging Environment                             │
│ - Docker Swarm with Docker Secrets              │
│ - CI/CD pipeline secrets                        │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│ Production Environment                          │
│ - Kubernetes with Secret volumes                │
│ - External vault (Hashicorp Vault)              │
└─────────────────────────────────────────────────┘
```

**Current Problem**:
```bash
# Current (INSECURE)
docker run -e DB_PASSWORD=supersecret123 \
           -e API_KEY=abc123xyz \
           myapp:1.0.0

# Issues:
# 1. docker inspect reveals all secrets
# 2. ps aux shows environment variables
# 3. Container logs may contain secrets
# 4. Cannot rotate without redeploy
# 5. Hard to audit who accessed secrets
```

**Step 1: Develop Local Environment (.env files)**

Create separate .env files, NEVER commit to git:

```bash
# .gitignore
.env
.env.local
*.key

# Create: .env.example (for documentation)
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=CHANGE_ME
API_KEY=CHANGE_ME
REDIS_PASSWORD=CHANGE_ME
```

```yaml
# docker-compose.yml (development)
version: '3.8'

services:
  api:
    image: myapp:dev
    env_file: .env
    environment:
      ENVIRONMENT: development
      LOG_LEVEL: debug
    ports:
      - "8080:8080"
  
  postgres:
    image: postgres:15-alpine
    env_file: .env
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    ports:
      - "5432:5432"
```

```bash
# Setup local development
cp .env.example .env
# Edit .env with real local passwords

docker-compose up
```

**Step 2: Staging with Docker Swarm Secrets**

Initialize Swarm and manage secrets:

```bash
# Initialize Swarm manager
docker swarm init

# Create secrets from files
echo "staging-db-password-123" | docker secret create db-password -
echo "staging-api-key-xyz" | docker secret create api-key -
echo "staging-jwt-secret-abc" | docker secret create jwt-secret -

# List secrets
docker secret ls

# Deploy service using secrets
docker service create \
  --secret source=db-password,target=db_password \
  --secret source=api-key,target=api_key \
  --secret source=jwt-secret,target=jwt_secret \
  -e DB_PASSWORD_FILE=/run/secrets/db_password \
  -e API_KEY_FILE=/run/secrets/api_key \
  -e JWT_SECRET_FILE=/run/secrets/jwt_secret \
  --name myapp \
  myapp:1.0.0
```

In the application, read from files:

```python
# Python: Read secrets from file
import os

def load_secret(secret_name):
    secret_file = f"/run/secrets/{secret_name}"
    if os.path.exists(secret_file):
        with open(secret_file, 'r') as f:
            return f.read().strip()
    else:
        return os.getenv(secret_name)  # Fallback for dev

db_password = load_secret('db_password')
api_key = load_secret('api_key')

# Never log these values
logger.debug(f"Connected to database: {db_host}:{db_port}")  # SAFE
logger.debug(f"DB password: {db_password}")  # NEVER!
```

**Secrets Rotation in Swarm**:

```bash
# Step 1: Create new secret version
echo "staging-db-password-new-456" | docker secret create db-password-v2 -

# Step 2: Update service (rolling restart)
docker service update \
  --secret-rm db-password \
  --secret-add source=db-password-v2,target=db_password \
  myapp

# Step 3: Monitor rollout
docker service ps myapp --no-trunc

# Step 4: Verify all tasks using new secret
docker service ps myapp | grep myapp

# Step 5: Delete old secret
docker secret rm db-password

# Step 6: Verify no tasks reference old secret
docker service ps myapp
```

**Step 3: Production with Kubernetes & External Vault**

```yaml
# 1. Kubernetes Secret (encrypted at rest)
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
data:
  db-password: cGFzc3dvcmQtMTIz   # base64 encoded
  api-key: YWJjLTEyMw==           # base64 encoded
  jwt-secret:andULXNlY3JldC1x==   # base64 encoded

---
# 2. Deployment using secrets as volumes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  template:
    spec:
      serviceAccountName: myapp
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:1.0.0
        volumeMounts:
        - name: secrets
          mountPath: /run/secrets
          readOnly: true
        env:
        - name: DB_PASSWORD_FILE
          value: /run/secrets/db-password
        - name: API_KEY_FILE
          value: /run/secrets/api-key
        - name: JWT_SECRET_FILE
          value: /run/secrets/jwt-secret
      
      volumes:
      - name: secrets
        secret:
          secretName: app-secrets
          defaultMode: 0400  # Read-only for owner
```

**External Vault Integration** (Hashicorp Vault):

```yaml
# Install Vault Agent Injector
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --namespace vault --create-namespace

# Annotate deployment for automatic injection
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp-role"
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/prod/db"
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "secret/data/prod/db" -}}
          export DB_PASSWORD="{{ .Data.data.password }}"
          {{- end }}
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        command: ["/bin/sh"]
        args: ["-c", "source /vault/secrets/db && python app.py"]
```

**Step 4: CI/CD Pipeline Secret Handling**

```yaml
# GitHub Actions example
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Secrets are encrypted in GitHub
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/myapp \
            myapp=myregistry.azurecr.io/myapp:${{ github.sha }} \
            -n production
          
          # Create/update secret
          kubectl create secret generic app-secrets \
            --from-literal=db-password=${{ secrets.PROD_DB_PASSWORD }} \
            --from-literal=api-key=${{ secrets.PROD_API_KEY }} \
            --dry-run=client -o yaml | kubectl apply -f -
        env:
          KUBECONFIG: ${{ secrets.KUBE_CONFIG }}
```

**Step 5: Secrets Audit & Monitoring**

```bash
# Audit: Who/what accessed secrets
# Kubernetes audit log
kubectl logs -n kube-system kube-apiserver | grep "get secrets"

# Vault audit log
vault audit list
vault audit enable file file_path=/vault/logs/audit.log

# Monitor secret usage
# Prometheus metric: vault_core_unseal_duration_seconds
# Alert when secrets accessed by unexpected service
```

**Best Practices Implemented**:
1. ✅ Secrets not in environment variables
2. ✅ Encrypted storage: Docker secrets, K8s secrets, Vault
3. ✅ Encrypted in transit: TLS for Vault API
4. ✅ Automated rotation: Vault lease renewal
5. ✅ Audit logging: Track all access
6. ✅ RBAC: Only services that need access get it
7. ✅ Least privilege: Each service has different secrets

---

### Scenario 3: Docker Compose Performance Troubleshooting & Optimization

**Problem Statement**:
A local development environment using Docker Compose runs 8 services (API, database, cache, message queue, search engine, logging, payment service, monitoring). Performance is poor: API responses slow, random container timeouts, high CPU usage on host. Need to diagnose and optimize.

**Current docker-compose.yml (Problematic)**:

```yaml
version: '3'

services:
  api:
    build: ./api
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
      - rabbitmq
  
  postgres:
    image: postgres:latest
    ports:
      - "5432:5432"
  
  redis:
    image: redis:latest
    ports:
      - "6379:6379"
  
  # 5 more services without resource limits...
```

**Issues Identified**:
1. ❌ No resource limits (containers consume unlimited CPU/memory)
2. ❌ No health checks (depends_on doesn't wait for readiness)
3. ❌ All services on default bridge network (broadcasting)
4. ❌ No volume management (fresh data every restart)
5. ❌ Logging driver not configured (massive json.log files)
6. ❌ No restart policy (manual intervention needed)

**Step 1: Diagnose System Resource Usage**

```bash
# Check host resource usage
docker stats

# Output shows:
# NAME           CPU %  MEM USAGE / LIMIT   MEM %
# myapp-api-1    45%    780MB / 8GB         9.7%
# ↑ API using 45% CPU (suspicious)
# ↑ 780MB memory (no limit, could grow)

# Check individual container resource consumption
docker stats --no-stream

# Check what's consuming CPU
docker exec myapp-api-1 top
# Shows process consuming high CPU

# Check memory pressure
free -h
# Check swap usage
vmstat 1 5
```

**Step 2: Analyze Container Dependencies**

```bash
# Check actual startup order
docker-compose logs | grep -E "listening|started|ready"

# Issue: depends_on waits for container start, not health
# Solution: Use service_completed successfully OR health checks

# Check network connectivity issues
docker exec myapp-api-1 nslookup postgres
# Can't resolve: network issue

# Check port accessibility
docker exec myapp-api-1 nc -zv postgres 5432
# Connection refused: service not ready
```

**Step 3: Optimized docker-compose.yml**

```yaml
version: '3.9'

services:
  # API Service
  api:
    build:
      context: ./api
      dockerfile: Dockerfile
      cache_from:
        - myregistry/api:latest
    image: myapp-api:dev
    container_name: myapp-api
    ports:
      - "8000:8000"
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    
    # Multiple networks for isolation
    networks:
      - api-layer
      - data-layer
    
    # Proper logging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    
    # Wait for dependencies to be healthy
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
    
    # Restart on failure
    restart: unless-stopped
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    
    environment:
      DATABASE_URL: postgres://postgres:password@postgres:5432/myapp
      REDIS_URL: redis://redis:6379
      RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
    
    volumes:
      - ./api:/app
      - /app/__pycache__  # Bind mount + override
    
    # More aggressive startup
    command: >
      sh -c "
      python -m pip install -r requirements.txt &&
      python migrations.py &&
      uvicorn main:app --host 0.0.0.0 --port 8000
      "

  # Database Service
  postgres:
    image: postgres:15-alpine      # Alpine = smaller, faster
    container_name: myapp-postgres
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '1'
          memory: 512M
    
    networks:
      - data-layer
    
    # Persistent data volume
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/init.sql:ro
    
    # Logging
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "2"
    
    restart: unless-stopped
    
    # Health check (critical for depends_on)
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: myapp
    
    # Performance optimization
    command:
      - "postgres"
      - "-c"
      - "shared_buffers=256MB"
      - "-c"
      - "max_connections=100"
      - "-c"
      - "work_mem=4MB"

  # Redis Cache
  redis:
    image: redis:7-alpine           # Alpine image
    container_name: myapp-redis
    
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
        reservations:
          cpus: '0.25'
          memory: 128M
    
    networks:
      - data-layer
    
    volumes:
      - redis-data:/data
    
    logging:
      driver: json-file
      options:
        max-size: "5m"
        max-file: "2"
    
    restart: unless-stopped
    
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    
    # Performance optimization
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru

  # RabbitMQ Message Broker
  rabbitmq:
    image: rabbitmq:3.12-alpine
    container_name: myapp-rabbitmq
    
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    
    networks:
      - api-layer
      - data-layer
    
    volumes:
      - rabbitmq-data:/var/lib/rabbitmq
    
    restart: unless-stopped
    
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 30s
      timeout: 10s
      retries: 5
    
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest

  # Elasticsearch (Search)
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.5.0-alpine
    container_name: myapp-elasticsearch
    
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
    
    networks:
      - data-layer
    
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    
    restart: unless-stopped
    
    healthcheck:
      test: curl -s http://localhost:9200/_cluster/health | grep -q '"status":"yellow\|green"'
      interval: 30s
      timeout: 10s
      retries: 3
    
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
      ES_JAVA_OPTS: "-Xms512m -Xmx512m"

  # Prometheus (Metrics)
  prometheus:
    image: prom/prometheus:latest
    container_name: myapp-prometheus
    
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    
    networks:
      - monitoring
    
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    
    restart: unless-stopped
    
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=7d'

  # Grafana (Visualization)
  grafana:
    image: grafana/grafana:latest
    container_name: myapp-grafana
    
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 256M
    
    ports:
      - "3000:3000"
    
    networks:
      - monitoring
    
    volumes:
      - grafana-data:/var/lib/grafana
    
    restart: unless-stopped
    
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin
      GF_INSTALL_PLUGINS: "redis-datasource"

# Define multiple networks for isolation
networks:
  api-layer:
    driver: bridge
  data-layer:
    driver: bridge
  monitoring:
    driver: bridge

# Define volumes for persistence
volumes:
  postgres-data:
  redis-data:
  rabbitmq-data:
  elasticsearch-data:
  prometheus-data:
  grafana-data:
```

**Step 4: Performance Validation**

```bash
# Start the optimized stack
docker-compose up -d

# Wait for all services healthy
docker-compose ps

# Monitor resource usage
docker stats

# After optimization, metrics should show:
# - API CPU: ~5% (was 45%)
# - API Memory: ~200MB (was 780MB)
# - Host CPU: ~15% (was 80%)
# - Boot time: ~30s (was 2+ minutes)

# Test API performance
time curl http://localhost:8000/api/data

# Load test
ab -n 1000 -c 10 http://localhost:8000/api/health

# Check database performance
docker exec myapp-postgres psql -U postgres -d myapp \
  -c "SELECT * FROM pg_stat_statements LIMIT 5;"
```

**Step 5: Monitoring & Continuous Optimization**

```yaml
# Add to prometheus.yml
scrape_configs:
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
  
  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']
```

```bash
# Create alerts for issues
# If CPU > 70%: Scale up or optimize code
# If memory > 80%: Increase limits or adjust caching
# If API latency > 200ms: Check database slow queries
```

**Best Practices Applied**:
1. ✅ Resource limits: Prevent resource exhaustion
2. ✅ Health checks: Proper orchestration
3. ✅ Network segmentation: API, data, monitoring networks
4. ✅ Persistent volumes: Data between restarts
5. ✅ Logging rotation: Prevent disk fill
6. ✅ Performance optimization: Alpine images, parameters tuning
7. ✅ Monitoring: Metrics collection for diagnosis

---

### Scenario 4: Implementing Rolling Deployments with Health Checks

**Problem Statement**:
A production service needs zero-downtime deployments. Current process: kill all containers, restart with new version. Results in 30-60 second downtime. Need to implement rolling deployment where:
- Old and new versions run simultaneously
- Traffic gradually shifts to new version
- Automatic rollback if new version is unhealthy
- Full deployment completes in <5 minutes

**Architecture Context**:
```
Load Balancer (nginx/HAProxy)
└─ Docker Service with 3 replicas
   ├─ Replica 1 (v1.0.0)
   ├─ Replica 2 (v1.0.0)
   └─ Replica 3 (v1.0.0)

After rolling update started:
├─ Replica 1 (v1.1.0) ← New version
├─ Replica 2 (v1.0.0) ← Old version
└─ Replica 3 (v1.0.0) ← Old version

If health checks pass, continue:
├─ Replica 1 (v1.1.0)
├─ Replica 2 (v1.1.0) ← Upgraded
└─ Replica 3 (v1.0.0) ← Old version

Eventually:
├─ Replica 1 (v1.1.0)
├─ Replica 2 (v1.1.0)
└─ Replica 3 (v1.1.0) ← All upgraded
```

**Step 1: Define Health Check Endpoint**

```python
# app.py - Flask example
from flask import Flask, jsonify
import psycopg2
import redis
import os

app = Flask(__name__)

# Cache connections
db_conn = None
redis_conn = None

def check_database():
    """Check if database is accessible"""
    try:
        cursor = db_conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        return True
    except Exception as e:
        app.logger.error(f"DB check failed: {e}")
        return False

def check_cache():
    """Check if redis is accessible"""
    try:
        redis_conn.ping()
        return True
    except Exception as e:
        app.logger.error(f"Cache check failed: {e}")
        return False

@app.route('/health')
def health():
    """Liveness probe: Is the service alive?"""
    return {'status': 'alive'}, 200

@app.route('/ready')
def readiness():
    """Readiness probe: Is the service ready for traffic?"""
    checks = {
        'database': check_database(),
        'cache': check_cache(),
        'version': app.config['VERSION']
    }
    
    if all(checks.values()):
        return jsonify(checks), 200
    else:
        app.logger.warning(f"Readiness check failed: {checks}")
        return jsonify(checks), 503

@app.route('/metrics')
def metrics():
    """For Prometheus scraping"""
    return f"# HELP app_version Application version\n# TYPE app_version gauge\napp_version{{version=\"{app.config['VERSION']}\"}} 1\n"

@app.before_first_request
def setup():
    """Initialize connections"""
    global db_conn, redis_conn
    db_conn = psycopg2.connect(os.getenv('DATABASE_URL'))
    redis_conn = redis.Redis(host=os.getenv('REDIS_HOST'), port=6379)
    app.config['VERSION'] = os.getenv('APP_VERSION', '1.0.0')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

**Step 2: Dockerfile with Version Info**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

ARG APP_VERSION=1.0.0
ENV APP_VERSION=${APP_VERSION}

EXPOSE 5000

# Health check built into container
HEALTHCHECK --interval=10s --timeout=5s --retries=3 --start-period=15s \
  CMD curl -f http://localhost:5000/health || exit 1

CMD ["python", "app.py"]
```

**Step 3: Docker Compose Rolling Update**

```yaml
version: '3.9'

services:
  # Load balancer (HAProxy)
  lb:
    image: haproxy:2.8-alpine
    container_name: myapp-lb
    ports:
      - "80:80"
      - "8404:8404"  # Stats page
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
    networks:
      - frontend
    depends_on:
      - app

  # Application service (scaled)
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        APP_VERSION: ${APP_VERSION:-1.0.0}
    image: myapp:${APP_VERSION:-1.0.0}
    
    # Scale to 3 replicas
    deploy:
      replicas: 3
      update_config:
        parallelism: 1              # Update one at a time
        delay: 10s                  # Wait 10s between updates
        failure_action: rollback    # Rollback if fails
        monitor: 10s                # Monitor for 10s
      resources:
        limits:
          cpus: '1'
          memory: 512M
    
    networks:
      - frontend
      - backend
    
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 15s
    
    environment:
      DATABASE_URL: postgres://user:pass@db:5432/myapp
      REDIS_HOST: redis
      APP_VERSION: ${APP_VERSION:-1.0.0}

  # Database
  db:
    image: postgres:15-alpine
    container_name: myapp-db
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
    environment:
      POSTGRES_PASSWORD: password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s

  # Cache
  redis:
    image: redis:7-alpine
    container_name: myapp-redis
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s

networks:
  frontend:
  backend:

volumes:
  db-data:
```

**HAProxy Configuration** (haproxy.cfg):

```
global
  log stdout local0
  log stdout local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin
  stats timeout 30s

defaults
  log     global
  mode    http
  option  httplog
  option  dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000

# Statistics page
listen stats
  bind *:8404
  stats enable
  stats uri /stats
  stats refresh 30s

# Frontend (public interface)
frontend http_front
  bind *:80
  default_backend http_back

# Backend (application pool)
backend http_back
  balance roundrobin
  option httpchk GET /health HTTP/1.1\r\nHost:\ app
  
  # Dynamic server list (Docker updates this)
  server app1 app:5000 check
  server app2 app:5000 check
  server app3 app:5000 check
```

**Step 4: Perform Rolling Update**

```bash
# Trigger rolling update
APP_VERSION=1.1.0 docker-compose up -d --force-recreate app

# Watch the update progress
docker-compose ps

# After 1st replica (1/3):
# app_1   STARTED (running v1.0.0)
# app_2   RUNNING (v1.0.0)  ← Being updated
# app_3   RUNNING (v1.0.0)

# Check HAProxy stats
curl http://localhost:8404/stats

# Monitor logs during update
docker-compose logs -f app

# Health check being performed:
# [timestamp] GET /health HTTP/1.1 200 OK (v1.1.0)
# [timestamp] GET /health HTTP/1.1 200 OK (v1.1.0)
# All checks pass → move to next replica
```

**Kubernetes Equivalent**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # Start 1 extra pod during update
      maxUnavailable: 0     # Never take down pods (zero downtime)
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: myapp
        image: myapp:1.1.0
        
        # Liveness: Is container running?
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 15
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness: Is container ready for traffic?
        readinessProbe:
          httpGet:
            path: /ready
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 1
          failureThreshold: 1
        
        # Graceful shutdown
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # Wait for connections to drain

        resources:
          requests:
            cpu: "500m"
            memory: "256Mi"
          limits:
            cpu: "1"
            memory: "512Mi"
```

**Step 5: Rollback if Needed**

```bash
# If health checks fail, automatic rollback triggered
# But you can also manually rollback

# Docker Compose: Rollback to v1.0.0
APP_VERSION=1.0.0 docker-compose up -d --force-recreate app

# Kubernetes: Automatic rollback
kubectl rollout undo deployment/myapp --to-revision=1

# Verify rollback
kubectl rollout status deployment/myapp
```

**Best Practices Applied**:
1. ✅ Zero-downtime: maxUnavailable=0
2. ✅ Health checks: Liveness + Readiness
3. ✅ Gradual rollout: One replica at a time
4. ✅ Automatic rollback: On health check failure
5. ✅ Graceful shutdown: Connection draining
6. ✅ Monitoring: Real-time update status

---

## Interview Questions

### 1. **You're troubleshooting a container that OOM kills after 2 hours under production load. Walk through your diagnostic process and explain the difference between `--memory` and `--memory-reservation`.**

**Expected Answer**:

"I'd approach this systematically:

**Diagnostic Process**:
1. First, confirm it's OOM kill: Check exit code 137 via `docker inspect` or `kubectl describe pod`
2. Collect memory metrics: Use `docker stats`, Prometheus, or `kubectl top` to see usage pattern
3. Identify the pattern:
   - Monotonic growth = memory leak (unbounded accumulation)
   - Steep spike = cache not bounded
   - Linear growth = leak getting worse
4. Profile the application:
   - Python: `memory_profiler` or `py-spy`
   - Java: `jprofdump` or `async-profiler`
   - Node: `clinic`, `heapdump`
5. Find root cause:
   - Global lists/caches without size limits
   - Unclosed database connections
   - Event listeners not cleaning up
6. Implement fix:
   - Add cache TTL or bounded size (LRU)
   - Connection pooling with max connections
   - Event cleanup (unregister listeners)

**Memory Limit vs Reservation**:

`--memory` is a **hard limit**:
- Container cannot exceed this under any circumstance
- Exceeding = immediately OOM kill (exit 137)
- Used to prevent runaway process from crashing entire host
- Strict enforcement by Linux kernel (cgroups)

`--memory-reservation` is a **soft limit**:
- Kernel *tries* to keep container under this
- If memory pressure, kernel reclaims, but allows burst
- Container can temporarily exceed reservation
- Used to guide scheduler (Kubernetes) about required memory
- Not an absolute cap

**Example**:
```bash
docker run --memory 2g --memory-reservation 512m myapp

# Scenario 1: Normal operation
# Uses 400MB - no issues, under reservation

# Scenario 2: Spike to 600MB
# Over reservation, but under limit
# Allowed temporarily, kernel may reclaim

# Scenario 3: Reaches 2GB
# At hard limit, no more memory available
# Next malloc → OOM kill

# Scenario 4: Without swap
docker run --memory 2g --memory-swap 2g myapp
# No swap available, stricter behavior
```

**In Kubernetes terms**:
- `requests.memory` = reservation (scheduler considers this)
- `limits.memory` = hard limit (kubelet enforces)

If requests > node available memory, pod cannot be scheduled.
If limits exceeded, pod is OOM killed.

**Production best practice**: Set limits=2× reservation. Reservation provides guidance, limit prevents catastrophe."

---

### 2. **Explain how Docker Compose networking works. How would you ensure services can communicate while maintaining security isolation?**

**Expected Answer**:

"Docker Compose networking provides automatic DNS-based service discovery. Here's how it works:

**Default Behavior**:
- Creates bridge network named `<project>_default`
- Attaches all services to this network
- Docker embedded DNS server resolves service names to container IPs
- Containers reach each other by service name (no hardcoding IPs)

**DNS Resolution Flow**:
```
Container 'web' wants to reach 'db'
  ↓
Makes DNS query to 127.0.0.11:53 (Docker's embedded DNS)
  ↓
Docker daemon looks up 'db' service IPs
  ↓
Returns all healthy 'db' container IPs
  ↓
Container connects to one (round-robin)
```

**Security Isolation via Multiple Networks**:

Services should be segmented by tier:

```yaml
networks:
  frontend:  # Public-facing services
  backend:   # Internal services
  database:  # Data tier

services:
  web:
    networks:
      - frontend
  api:
    networks:
      - frontend
      - backend
  cache:
    networks:
      - backend
      - database
  db:
    networks:
      - database
```

**Result**:
- Web server can reach API (both on frontend)
- API can reach cache and DB (on backend/database)
- **Web cannot reach DB directly** (not on same network)
- **Cache cannot reach web** (not on same network)

This creates a default-deny security model:
- Only explicitly connected services can communicate
- Compromised web service cannot access database directly
- Network policies enforced by Docker, not just iptables

**Advanced: Ingress Network** (Multiple hosts):

```yaml
driver_opts:
  com.docker.network.driver.overlay.vxlan_list: 4789
```

**Network Inspection**:
```bash
docker network inspect myproject_frontend

# Shows:
# - Network driver (bridge/overlay)
# - Containers connected
# - IP addresses assigned
# - Custom DNS servers

docker exec container-name nslookup service-name
# Verify DNS resolution works
```

**Common Gotcha**: Using `localhost` instead of service name:
```python
# WRONG: Works on host, fails in container
db = psycopg2.connect('localhost:5432')

# CORRECT: Uses Docker DNS
db = psycopg2.connect('db:5432')
```

**Network Policies in K8s** (more sophisticated):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
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
```

This ensures only API pods can reach database, everything else blocked."

---

### 3. **How do you handle secrets rotation in a production Swarm cluster without downtime or manual restarts?**

**Expected Answer**:

"Secrets rotation is critical for compliance. Here's the production-grade approach:

**Challenge**: Container has mounted secret file. If we just create new secret, container still sees old one.

**Solution**: Automated rolling restart with health checks.

**Implementation**:

**Step 1: Create new secret version**
```bash
# New secret with version suffix
echo 'new-password-xyz' | docker secret create db-password-v2 -

# Verify both exist
docker secret ls
# db-password     [old]
# db-password-v2  [new]
```

**Step 2: Update service with zero downtime**
```bash
docker service update \
  --secret-rm db-password \           # Remove old
  --secret-add source=db-password-v2,target=db-password \  # Add new
  --update-order start-first \        # Start new before killing old
  --update-parallelism 1 \            # One replica at a time
  --update-delay 10s \                # 10s between updates
  myapp
```

**Step 3: Monitor rolling restart**
```bash
# Watch replica status
watch docker service ps myapp

# Output shows:
# ID  NAME           STATE       DESIRED STATE
# ... myapp.1  RUNNING     Running
# ...   prep for update
# ... myapp.1  SHUTDOWN    Running  [Old task stopping]
# ... myapp.1  RUNNING     Running  [New task started]
# Same process for .2 and .3

# Verify old task fully stopped before next update starts
```

**Step 4: Application safely reads new secret**
```python
# Application code (unchanged)
with open('/run/secrets/db-password', 'r') as f:
    password = f.read().strip()

# During rolling restart:
# Old container: mounted to old secret file
# New container: mounted to new secret file
# Connection pool might need to reconnect
```

**Step 5: Cleanup old secret**
```bash
# Wait 5 minutes to ensure all old tasks are gone
docker service ps myapp --no-trunc  # Verify no 'db-password' references

# Delete old secret
docker secret rm db-password

# Verify
docker secret ls  # Only db-password-v2 remains
```

**Automation with Script**:
```bash
#!/bin/bash
SERVICE=$1
SECRET=$2
NEW_VALUE=$3

# 1. Create with version
VERSION=$(date +%s)
echo "$NEW_VALUE" | docker secret create ${SECRET}-${VERSION} -

# 2. Update service
docker service update \
  --secret-rm $SECRET \
  --secret-add source=${SECRET}-${VERSION},target=${SECRET} \
  --update-order start-first \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-failure-action continue \
  $SERVICE

# 3. Wait for completion
while [[ $(docker service ps $SERVICE | grep 'Running' | wc -l) -lt $(docker service ls --filter name=$SERVICE --format='{{.Replicas}}' | cut -d/ -f1) ]]; do
  echo "Waiting for update..."
  sleep 5
done

# 4. Cleanup old
OLD_SECRETS=$(docker secret ls --filter 'label=secret-pool='$SECRET | awk '{print $1}' | grep -v ${VERSION})
for s in $OLD_SECRETS; do
  docker secret rm $s
done

echo "Rotation complete"
```

**Kubernetes Approach** (Simpler - automatic pod restart):
```bash
# Update secret
kubectl create secret generic db-credentials \
  --from-literal=password=new-value \
  --dry-run=client -o yaml | kubectl apply -f -

# Automatic rolling restart via rollout restart
kubectl rollout restart deployment/myapp -n production

# Monitors: app will re-read secret from mounted file
```

**Compliance Benefits**:
✅ Automatic rotation (scheduled cron job can trigger)
✅ Zero downtime (rolling update)
✅ Audit trail (timestamp in secret name)
✅ Quick rollback (old secret still exists for 5 mins)
✅ No application changes needed (reads from file path)

**Production checklist**:
- [ ] Secrets encrypted in transit (TLS)
- [ ] Secrets encrypted at rest (Swarm uses encrypted RAFT)
- [ ] Audit logging enabled (who rotated when)
- [ ] Rotation frequency: every 30/60/90 days
- [ ] Test rotation in staging first
- [ ] Alert on rotation failure"

---

### 4. **Compare `docker-compose up`, `docker service create`, and Kubernetes deployments. When would you use each?**

**Expected Answer**:

"These three approaches have different tradeoffs. Let me break down the decision matrix:

**docker-compose up** (Single host orchestration):
- **When**: Development, testing, simple deployments
- **Scale**: 1 host, up to ~20 containers
- **Orchestration**: None (no automatic restarts, rescheduling)
- **Networking**: Automatic bridge networks, DNS
- **Secrets**: Via Docker secrets (but limited - must have Swarm mode enabled)
- **Updates**: Manual (recreate containers)
- **State**: Stateless orchestration (compose doesn't track desired state across reboots)

```yaml
docker-compose up
# Great for: Local dev, CI environments, stateless services

docker-compose ps
# Shows current state, but if host reboots, services don't auto-restart
```

**docker service create** (Docker Swarm - multi-host):
- **When**: Multi-host deployments, Swarm-native clusters
- **Scale**: Many hosts, hundreds of containers
- **Orchestration**: Full (distributed, fault-tolerant, state-keeping)
- **Networking**: Overlay networks across hosts, automatic load balancing
- **Secrets**: Native encrypted secrets management
- **Updates**: Declarative rolling updates with health checks
- **State**: Swarm maintains desired state (reconciliation loop)

```bash
docker service create \
  --replicas 3 \
  --secret db-password \
  --healthcheck-cmd 'curl -f http://localhost/health' \
  myapp:1.0.0

# Swarm ensures 3 replicas running at all times
# Automatic restart if container fails
# Rolling updates with automatic rollback
```

**Kubernetes** (Full-featured container orchestration):
- **When**: Complex microservices, multi-cloud, enterprises
- **Scale**: Unlimited (100s of nodes, 1000s+ containers)
- **Orchestration**: Sophisticated (custom controllers, operators)
- **Networking**: CNI plugins (Calico, Flannel), service mesh options
- **Secrets**: Encrypted, RBAC, audit logging
- **Updates**: Advanced strategies (blue-green, canary)
- **State**: Desired state in etcd, highly available

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
```

**Decision Matrix**:

| Criterion | docker-compose | Docker Swarm | Kubernetes |
|-----------|-----------------|--------------|-----------|
| Setup complexity | 5 mins | 30 mins | 2 hours |
| Multi-host | ❌ | ✅ | ✅✅ |
| Self-healing | ❌ | ✅ | ✅✅ |
| Scaling | Manual | Automatic | Automatic |
| Secrets management | Basic | ✅ | ✅✅ |
| Learning curve | Easy | Medium | Steep |
| Production-ready | ✅ Small scale | ✅ Medium scale | ✅ Any scale |
| Vendor lock-in | Docker only | Docker only | Cloud-agnostic |
| Extensions | Limited | Limited | Rich (CNI, CSI, CRDs) |

**Real-world scenarios**:

**Scenario 1: Startup (3-5 services)**
→ Use docker-compose
→ Reason: Fast to setup, easy debugging, sufficient for MVP
→ Migration path: Move to Swarm when multi-host needed

**Scenario 2: Funded startup (15-30 services, 2-4 hosts)**
→ Use Docker Swarm
→ Reason: Distributed, built-in secrets, operational simplicity
→ Low overhead, familiar Docker tools
→ Trade-off: Less flexible than K8s, harder to move later

**Scenario 3: Enterprise (50+ services, high availability)**
→ Use Kubernetes
→ Reason: Industry standard, ecosystem rich (Helm, service mesh)
→ Justifies complexity with operational maturity
→ Can hire K8s specialists

**Hybrid Approach** (Common in large orgs):
```
├─ Kubernetes (production microservices)
├─ Docker Compose (developer local envs)
└─ Docker Swarm (legacy apps, simpler workloads)
```

**My personal recommendation** (as senior engineer):

1. **Start with docker-compose** for anything <10 containers, 1 host
2. **Migrate to Swarm** for multi-host but simpler requirements
3. **Adopt Kubernetes only if**:
   - Multi-team organization (RBAC important)
   - Complex service dependencies (operators/custom resources)
   - Multi-cloud strategy
   - Budget for operational overhead

Kubernetes is powerful but expensive (in time and infrastructure). Don't adopt prematurely."

---

### 5. **A service's response time increases from 100ms to 2000ms+ under load. Walk through your troubleshooting methodology, including resource limiting.**

**Expected Answer**:

"Increased latency under load typically indicates resource contention. Here's my systematic approach:

**Phase 1: Baseline Metrics Collection**

```bash
# 1. Identify affected service (from monitoring/alerting)
# 2. Collect baseline metrics (before issues started)

# Current resource usage
docker stats <service>
# Shows: CPU %, memory, network I/O

# Historical metrics (from Prometheus)
SELECT rate(http_request_duration_seconds_sum[5m]) / 
       rate(http_request_duration_seconds_count[5m])
# Math: sum of durations / count = average latency

# Check request rate
rate(http_requests_total[5m])  # requests per second
```

**Phase 2: Identify Bottleneck**

**Is it CPU?**
```promql
# Rising CPU under load
rate(container_cpu_usage_seconds_total[5m]) > 0.8

# Check CPU throttling (hard limit reached)
container_cpu_throttled_seconds_total > 0  # Non-zero = being throttled

# If CPU is the issue:
# - Application code is slow (profiling needed)
# - Not enough CPU allocated (increase --cpus)
# - CPU contention with other containers (increase --cpu-shares)
```

**Is it Memory?**
```promql
# Memory pressure
container_memory_usage_bytes / container_memory_limit_bytes > 0.9

# Check for swap (slower than RAM)
container_memory_swap_usage_bytes > 0

# If memory is the issue:
# - Increase --memory limit
# - Reduce cache size
# - Check for memory leak
```

**Is it I/O?**
```bash
# Check disk I/O
docker exec <service> iostat -x 1 5

# Look for high 'await' time = slow I/O
# May indicate:
# - Database queries too slow
# - Disk bandwidth saturated
# - Noisy neighbor consuming I/O

# In Prometheus
rate(container_fs_io_current[5m])  # Current I/O operations
```

**Is it Network?**
```bash
# Check network latency
docker exec <service> ping <dependency>

# Check packet loss
docker exec <service> mtr <dependency>

# Check bandwidth saturation
docker stats | grep 'NET I/O'

# Kubernetes service DNS slowness
docker exec <service> nslookup <service-name>
```

**Is it Dependency?**
```bash
# Database slow queries
docker exec postgres psql -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 5;"

# Cache misses
docker exec redis redis-cli INFO stats | grep -E "hits|misses"
# Cache hit ratio should be >90%

# Message queue backlog
docker exec rabbitmq rabbitmqctl list_queues name messages
```

**Phase 3: Find Root Cause**

Example diagnosis:
```bash
# Prometheus query shows:
# - CPU: 45% (not maxed out)
# - Memory: 60% (headroom available)
# - Disk I/O: High 'await' time observed

# Application profiling reveals:
# Database query takes 1.5 seconds (should be <100ms)

# Root cause: N+1 SQL queries
# Under load: 1000 requests/sec × 10 SQL queries each = 10k queries/sec
# Database cannot handle, queue builds, response time increases
```

**Phase 4: Resource Tuning**

```bash
# Current deployment
docker run -e PROFILE=production \
           --cpus 1 \
           --memory 512m \
           myapp

# Issue: Database queries slow
# Solution options:

# Option A: Add query caching
# Reduces database load

# Option B: Database optimization
# Add indexes, rewrite queries

# Option C: Increase resource allocation
docker run --cpus 2 \           # Can now handle 2× requests before hitting CPU limit
           --memory 1g \
           myapp

# Option D: Scale horizontally
docker service scale myapp=5    # Run 5 replicas instead of 1
```

**Phase 5: Implement Fix**

```bash
# Before: 1 replica, CPU limited
docker service create --name myapp \
  --cpus 1 \
  --memory 512m \
  --replicas 1 \
  myapp:1.0.0

# Problem: Under load (1000 req/s), single replica maxes out CPU

# After: 3 replicas, load balanced
docker service create --name myapp \
  --cpus 1 \
  --memory 512m \
  --replicas 3 \
  --update-order start-first \
  myapp:1.0.0

# Now: 1000 req/s ÷ 3 replicas = ~333 req/s per replica
# Each replica at ~30% CPU (well under 1 CPU limit)
```

**Kubernetes Example**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1"
            memory: "1Gi"

# If load increases, HPA auto-scales
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
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
```

**Phase 6: Validation**

```bash
# Load test after fix
ab -n 10000 -c 100 http://localhost:8000/api/data

# Monitor: latency should drop significantly
# Before: p99 = 2000ms
# After: p99 = 150ms

# Verify no resource exhaustion
docker stats
# CPU: ~65-75% (not maxed)
# Memory: ~60% (headroom)
```

**Production Checklist**:
- [ ] Identified bottleneck (CPU/Memory/I/O/Network/Dependency)
- [ ] Appropriate resource limits set
- [ ] Autoscaling configured (if horizontal scaling viable)
- [ ] Dependency optimized (DB indexes, caching, etc.)
- [ ] Monitoring alerts on latency regression
- [ ] Tested fix under realistic load
- [ ] Rollback plan documented"

---

### 6. **Explain the purpose of health checks, liveness probes, and readiness probes. How are they different and when would one fail when others pass?**

**Expected Answer**:

"These three concepts serve different purposes in container lifecycle management:

**Health Checks (Docker native)**:
- Periodic test to determine if container is 'healthy'
- Executes inside container at specified interval
- Three possible states: starting, healthy, unhealthy
- Used by Docker to determine if container should restart
- Separate from actual service readiness

```dockerfile
FROM ubuntu:22.04
CMD ["python", "app.py"]

HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=10s \
  CMD curl -f http://localhost:8000/health || exit 1
```

Output: `docker inspect <container>` shows `Health: healthy/unhealthy`

**Liveness Probe (Kubernetes)**:
- Determines if container is still running
- Framework for determining if container should be restarted
- "Is the process alive?"
- If fails, kubelet kills and restarts container
- Purpose: Detect and restart dead/stuck processes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3  # 3 failures = kill and restart
```

**Readiness Probe (Kubernetes)**:
- Determines if container should receive traffic
- "Is the service ready to handle requests?"
- If fails, service is removed from load balancer (but not killed)
- Purpose: Prevent traffic before service ready

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 1  # Single failure = remove from LB
```

**Key Differences**:

| Aspect | Health Check | Liveness | Readiness |
|--------|-------------|----------|-----------|
| Purpose | Container healthy? | Still running? | Accept traffic? |
| Failure action | Log unhealthy | Kill & restart | Remove from LB |
| Typical endpoint | `/health` | `/health` | `/ready` |
| Sensitivity | Moderate | Coarse-grained | Fine-grained |
| Initial delay | 10-30s | 15-30s | 5-10s |
| Frequency | 30s | 10s | 5s |

**Real-world Scenarios Where They Differ**:

**Scenario 1: Application starts but not ready**

```python
# app.py
@app.route('/health')
def health():
    """Process is running, respond immediately"""
    return {'status': 'alive'}, 200

@app.route('/ready')
def ready():
    """Service is ready when DB connection works"""
    try:
        db.ping()
        return {'status': 'ready'}, 200
    except:
        return {'status': 'not_ready'}, 503
```

**Timeline**:
```
T0s   Container starts
T2s   Application binds to port, /health responds
      Liveness: PASS ✅ (process is running)
      Readiness: FAIL ❌ (still initializing DB)
      Health: PASS ✅ (process alive)

T5s   Database connection established
      Readiness: PASS ✅ (ready for traffic)
      Pod receives traffic from load balancer
```

**Scenario 2: Deadlock (process running but hanging)**

```python
import threading

# Deadlock: Thread A waits for Thread B, Thread B waits for Thread A
lock_a = threading.Lock()
lock_b = threading.Lock()

def thread_a():
    lock_a.acquire()
    time.sleep(0.1)
    lock_b.acquire()  # Waits forever for B to release

def thread_b():
    lock_b.acquire()
    time.sleep(0.1)
    lock_a.acquire()  # Waits forever for A to release

# Probe behavior:
@app.route('/health')
def health():
    """Process still running, this endpoint works"""
    return 200  # Takes milliseconds

@app.route('/ready')
def ready():
    """Tries to call method that's blocked"""
    result = api_call()  # Hangs indefinitely (thread deadlock)
    return 200

# Result:
# Liveness: PASS (curl /health succeeds immediately)
# Readiness: FAIL (curl /ready hangs, timeout triggers)
# Container not restarted (liveness passes)
# But removed from load balancer (readiness fails)
```

**Scenario 3: External Dependency Failure**

```python
@app.route('/health')
def health():
    """Just check if service is running"""
    return {'status': 'healthy'}, 200

@app.route('/ready')
def ready():
    """Check if can talk to dependencies"""
    checks = {
        'database': check_database(),
        'cache': check_cache(),
        'message_queue': check_mq(),
    }
    if all(checks.values()):
        return checks, 200
    else:
        return checks, 503  # Not ready if any dependency down
```

**Scenario**:
- Database goes down (maintenance, failure)
- All containers reach readiness failures
- Removed from load balancer (no traffic)
- Liveness still passes (process not affected)
- Wait for database recovery
- Readiness checks pass again
- Containers back in load balancer

**Scenario 4: Resource Starvation**

```python
# Memory leak or high CPU load
@app.route('/health')
def health():
    """Minimal endpoint, doesn't trigger GC"""
    return 200  # Always fast

@app.route('/ready')
def ready():
    """More complex, triggers memory allocation"""
    data = fetch_large_dataset()  # OOM or timeout
    return 200
```

**Result**:
- Liveness: PASS (lightweight endpoint works)
- Readiness: FAIL (complex endpoint times out or OOM)
- Container not restarted (liveness metric okay)
- Removed from load balancer (graceful degradation)

**Best Practice Implementation**:

```python
from flask import Flask
import threading
import time

app = Flask(__name__)

# Shared state
startup_complete = False
db = None
cache = None
mq = None

def initialize():
    """Run on startup, sets startup_complete flag"""
    global startup_complete, db, cache, mq
    
    db = Database()
    cache = Cache()
    mq = MessageQueue()
    
    startup_complete = True

@app.route('/health')
def health():
    """Liveness: Is the process alive?"""
    # Very lightweight, no I/O
    # Just confirm we're here
    if not startup_complete:
        return {'status': 'starting'}, 503
    return {'status': 'healthy'}, 200

@app.route('/ready')
def ready():
    """Readiness: Can I handle requests?"""
    if not startup_complete:
        return {'status': 'initializing'}, 503
    
    # Check dependencies are accessible
    checks = {
        'database': db.is_connected(),
        'cache': cache.is_connected(),
        'mq': mq.is_connected(),
    }
    
    if all(checks.values()):
        return checks, 200
    else:
        app.logger.warning(f"Ready check failed: {checks}")
        return checks, 503

# Use different endpoints semantically
@app.route('/status')
def status():
    """Health + Ready combined (for monitoring)"""
    return {
        'health': health()[0],
        'ready': ready()[0],
    }, 200
```

**Kubernetes YAML**:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15  # Let startup complete
  periodSeconds: 10
  failureThreshold: 3      # Tolerate 3 failures (30s) before kill
  timeoutSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 5        # Check frequently
  failureThreshold: 1     # Remove from LB immediately on failure
  timeoutSeconds: 1       # Timeout quickly (dependency dependency is down)
```

**When to Use Each**:
- **Liveness only**: Simple stateless services that don't need dependencies
- **Readiness only**: Services that should boot but not receive traffic until ready
- **Both**: Most production services (self-healing + graceful degradation)
- **Health checks**: Docker Compose environments as lightweight alternative"

---

### 7. **You have 10 microservices with complex interdependencies defined in Docker Compose. Describe your strategy for detecting and debugging a cascading failure that started in a single service.**

**Expected Answer**:

"Cascading failures are common in distributed systems. Here's my debugging methodology:

**Step 1: Identify the Initial Failure Point**

```bash
# 1. Check compose logs for earliest error
docker-compose logs --since 10m | grep -i error | head -5

# Look for timestamps - find FIRST error
# 2024-03-07 10:15:30 [service-a] ERROR: Connection refused
# 2024-03-07 10:15:31 [service-b] ERROR: Timeout
# 2024-03-07 10:15:31 [service-c] ERROR: Timeout

# Service-A failed first, B and C timed out trying to reach A

# 2. Check service status
docker-compose ps
# Shows which containers are running, restarting, exited

# 3. Get detailed logs for initial failure
docker-compose logs service-a --tail 50
```

**Step 2: Map Dependencies**

From docker-compose.yml, identify the dependency graph:

```yaml
services:
  database:
    image: postgres
  
  cache:
    image: redis
  
  api:
    image: api:latest
    depends_on:
      - database
      - cache
    environment:
      DATABASE_URL: postgres://database:5432
      REDIS_URL: redis://cache:6379
  
  worker:
    depends_on:
      - api
      - queue
  
  queue:
    image: rabbitmq
  
  web:
    depends_on:
      - api
```

Visual dependency map:
```
database ──┐
           ├─→ api ──→ web
cache ─────┤        └─→ worker
           └→ worker ←── queue
```

**Step 3: Trace Failure Propagation**

```bash
# Scenario: API fails to start

# Effect on dependents:
docker-compose logs web
# "ERROR: Failed to connect to api:8000"
# "ERROR: api service unavailable"

docker-compose logs worker
# "ERROR: Cannot reach api"
# "ERROR: Queue consumer offline"

# Cascade: API failure → Web cannot forward requests → Worker orphaned
# Result: Entire dependent chain offline
```

**Step 4: Investigate API Failure Root Cause**

```bash
# Check API logs for actual error
docker-compose logs api | tail -20

# Possible errors:
# Error 1: "Connection refused to database:5432"
#   → Database not started or not healthy
# Error 2: "ERROR: Unable to bind to port 8000"
#   → Port already in use or permission denied
# Error 3: "ERROR: Certificate not found"
#   → Missing volume mount or config
```

**Diagnosis: Database not healthy**

```bash
# Check database container
docker-compose ps database
# Status: Up (container is running)

# But API can't connect, why?
docker-compose logs database | grep -i error
# "FATAL: password authentication failed for user \"api\""

# Issue: Wrong credentials in API environment

docker-compose logs database | grep -i "listening"
# "listening on IPv4 address \"0.0.0.0\", port 5432"
# Database IS listening

# Test connection from API container
docker-compose exec api psql -h database -U api -d myapp -c "SELECT 1"
# psql: error: FATAL:  password authentication failed

# Root cause confirmed: API environment variable password mismatch
```

**Step 5: Fix and Verify Propagation**

```yaml
# Fix environment variable in docker-compose.yml
services:
  api:
    environment:
      DATABASE_URL: postgres://api:correct-password@database:5432/myapp
```

```bash
# Restart service
docker-compose up -d api

# Verify API comes up
docker-compose ps api
# Status: Up (healthy)

# Verify API is healthy
docker-compose logs api
# "Connected to database successfully"
# "Listening on port 8000"

# Database logs confirm connection
docker-compose logs database | grep "api"
# "authenticating user \"api\""
# "connection received"
```

**Step 6: Cascade Healing**

Once API is healthy, dependent services should recover:

```bash
# With proper depends_on:
services:
  web:
    depends_on:
      api:
        condition: service_healthy

# Docker automatically restarts services with unmet dependencies
docker-compose up -d

# Check recovery
docker-compose ps
# api       Status: Up (now healthy)
# web       Status: starting → Up (restarted, now can reach api)
# worker    Status: starting → Up (restarted)
```

**Step 7: Prevent Similar Cascades**

**Add health checks to all services**:

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      retries: 3
      timeout: 5s
    depends_on:
      database:
        condition: service_healthy  # Wait for DB first
  
  database:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
```

**Add retry logic in application**:

```python
# Python example: Exponential backoff
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
def connect_database():
    """Retry with exponential backoff"""
    return psycopg2.connect(os.environ['DATABASE_URL'])

# Attempt 1: immediate
# Attempt 2: wait 2s
# Attempt 3: wait 4s
# Attempt 4: wait 8s
# Attempt 5: wait 10s
```

**Add circuit breakers**:

```python
from pybreaker import CircuitBreaker

api_breaker = CircuitBreaker(
    fail_max=5,        # Fail after 5 errors
    reset_timeout=60   # Try again after 60s
)

@app.route('/data')
def get_data():
    try:
        return api_breaker.call(fetch_from_upstream)
    except Exception:
        # Fallback to cache
        return get_cached_data()
```

**Monitoring for Cascades**:

```prometheus
# Alert on service dependency failures
- alert: ServiceUnhealthy
  expr: |
    up{job="docker"} == 0
    or
    rate(http_errors_total[5m]) > 0.1
  for: 2m
  annotations:
    summary: "{{ $labels.service }} unhealthy for 2 min"

# Alert on degradation spreading
- alert: CascadingFailureDetected
  expr: |
    increase(services_down_total[5m]) > 1
  annotations:
    summary: "Multiple services offline - cascading failure"
    runbook: "Check root cause service, fix primary issue"
```

**Best Practices for Cascade Resilience**:
1. ✅ Hard dependencies explicitly declared (depends_on + condition)
2. ✅ Health checks on all services
3. ✅ Timeouts and circuit breakers in client code
4. ✅ Graceful degradation (cache fallback, queue buffering)
5. ✅ Monitoring correlation (which failures trigger which cascades)
6. ✅ Testing: Chaos engineering (kill services in sequence, verify failure propagation)"

---

### 8. **How would you design a centralized logging solution for 50+ Docker containers across multiple hosts? Address scalability, retention, searching, and cost.**

**Expected Answer**:

"Logging at scale requires careful architecture. Here's my comprehensive design:

**Architecture Overview**:

```
┌─────────────────────────────────────────┐
│ 50+ Docker Containers (Multiple Hosts)  │
│ - Containers emit logs (stdout/stderr)  │
└────────────┬────────────────────────────┘
             │
       ┌─────▼──────┐
       │ Log Drivers│  (Fluentd, Filebeat, Logstash)
       │ (Collectors)
       └─────┬──────┘
             │
       ┌─────▼──────────────────┐
       │ Message Broker (Kafka) │ (High throughput, fault-tolerant)
       └─────┬──────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼────┐
│ Loki   │      │Elasticsearch│
│ (cheap)│      │  (queryable) │
└───┬────┘      └────┬────┘
    │                │
    └────────┬───────┘
             │
        ┌────▼────────┐
        │  Grafana    │ (Unified dashboard)
        └─────────────┘
```

**Design Decisions**:

**1. Log Collection Strategy**

**Option A: Host-based (Lightweight)**
```
Container logs → Host Docker daemon → Log driver sends to collector
```

```json
// docker daemon.json
{
  "log-driver": "fluentd",
  "log-opts": {
    "fluentd-address": "localhost:24224",
    "labels": "hostname,environment,application",
    "tag": "docker.{{.Name}}"
  }
}
```

Per-host CPU: ~5-10% (for 5-10 containers)
Pros: Centralized config, less per-container overhead
Cons: If log driver fails, logs are lost

**Option B: Sidecar container (Kubernetes-style)**
```yaml
services:
  app:
    image: myapp
    volumes:
      - /var/log/app:/logs  # App writes to file

  filebeat:
    image: elastic/filebeat
    volumes:
      - /var/log/app:/logs:ro
    config:
      filebeat.inputs:
        - type: log
          enabled: true
          paths:
            - /logs/*.log
```

Pros: Failed collector doesn't lose logs (files persist)
Cons: Overhead (extra container per app)

**Recommendation**: Host-based for Docker, sidecar for Kubernetes

**2. Message Broker for Buffering**

Use Kafka for reliability and high throughput:

```bash
# Scale: 50+ hosts × 100MB/s logs = 5GB/s peak
# Single Elasticsearch node can't keep up
# Kafka decouples collection from storage

docker-compose:
  kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3
      KAFKA_LOG_RETENTION_HOURS: 24  # Keep 1 day of raw logs
      KAFKA_NUM_PARTITIONS: 12
      KAFKA_DEFAULT_REPLICATION_FACTOR: 3
```

**3. Storage Choice: Loki vs Elasticsearch**

**Loki** (Logs as time series):
- Cost: 10-100× cheaper than Elasticsearch
- Storage: $1-5/GB/month (vs $50+/GB for ES)
- Retention: Practical for 30-90 days
- Search: Label-based, not full-text
- Good for: Debugging specific services, correlation

```yaml
loki:
  auth_enabled: false
  ingester:
    max_chunk_age: 1h
    max_chunk_idle_period: 30m
  limits_config:
    enforce_metric_name: false
    reject_old_samples: true
    retention_period: 30d  # 30 days retention
  storage_config:
    filesystem:
      directory: /loki/chunks
```

**Elasticsearch** (Full-text search):
- Cost: Higher ($50+/GB/month)
- Storage: Expensive but queryable
- Retention: Practical for 7-30 days
- Search: Full-text, complex queries
- Good for: Compliance audits, forensics, complex analysis

```yaml
elasticsearch:
  environment:
    - discovery.type=single-node
    - xpack.security.enabled=false
  index lifecycle management:
    - rollover: { max_age: "1d", max_size: "50GB" }
    - delete: { min_age: "30d" }
```

**Recommendation**: Loki for primary logging, Elasticsearch for compliance

**4. Collection Configuration**

```yaml
# Fluentd terraform (Centralized config)
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Parse JSON logs
<filter docker.>
  @type parser
  key_name log
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
  emit_invalid_records false
</filter>

# Add metadata
<filter docker.>
  @type record_modifier
  <replace>
    key hostname
    expression ${Socket.gethostname}
  </replace>
  <replace>
    key environment
    expression ${ENV['ENVIRONMENT']}
  </replace>
</filter>

# Kafka sink for buffering
<match docker.>
  @type kafka2
  brokers kafka:9092
  topics logs_raw
  <format>
    @type json
  </format>
  <buffer topic>
    @type file
    path /fluentd/buffer/kafka
    flush_interval 10s
    flush_mode interval
    chunk_limit_size 5M
    queue_limit_length 256
  </buffer>
</match>
```

**5. Forwarding from Kafka to Storage**

```python
# Kafka consumer → Loki/Elasticsearch
import json
from kafka import KafkaConsumer
import requests

consumer = KafkaConsumer(
    'logs_raw',
    bootstrap_servers=['kafka:9092'],
    group_id='loki-loader',
    auto_offset_reset='earliest'
)

for message in consumer:
    log_entry = json.loads(message.value)
    
    # Enrich with metadata
    log_entry['@timestamp'] = log_entry['time']
    log_entry['service'] = log_entry['docker']:
```

**6. Scalability Strategy**

**Tier 1: Real-time analysis** (Loki + Grafana)
- Retention: 7 days
- Cost: $500/month
- Use: Active debugging, monitoring

**Tier 2: Medium-term storage** (Elasticsearch)
- Retention: 30 days
- Cost: $2000/month
- Use: Investigation, correlation

**Tier 3: Long-term archive** (S3)
- Retention: 2 years
- Cost: $100/month
- Use: Compliance, audit trails

```bash
# Export logs daily to S3
# Query using Athena when needed (on-demand)
```

**7. Searching and Visualization**

```grafana
# Real-time dashboard
SELECT sum(bytes) BY (service)
WHERE environment="production" AND level="error"
  OVER (5m)

# Service error rate
SELECT rate(errors[5m]) BY (service)

# Trace cross-service failures
SELECT * FROM logs
WHERE trace_id="xyz-123"
  ORDER BY timestamp ASC
```

**8. Cost Optimization**

```
Scenario: 50 containers × 10MB/s (average)
         × 86400 seconds/day = 43.2TB/day

Daily Cost Breakdown:
- Loki (7d retention): $30/day
- Kafka (1d buffer): $5/day
- Elasticsearch (30d): $50/day
- S3 Archive: $1/day
Total: ~$2000/month

Optimization opportunities:
1. Log sampling: Only send 10% of DEBUG level (~10% savings)
2. Aggregation: Pre-aggregate metrics at host level (~15% savings)
3. Compression: gzip before sending (~40% compression)
4. Tiered storage: Hot/warm/cold Elasticsearch nodes
```

**9. Monitoring the Logging System Itself**

```prometheus
# Alerts for logging infrastructure
- alert: KafkaHighLatency
  expr: kafka_producer_record_send_time_ms > 1000
  for: 5m

- alert: ElasticsearchQueueBacklog
  expr: bulk_queue_size > 10000
  for: 10m

- alert: FluentdBufferFull
  expr: fluentd_buffer_queue_length > 256
  for: 2m
```

**10. Complete Docker Compose Stack**

```yaml
version: '3.9'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"

  fluentd:
    image: fluent/fluentd:v1.16
    volumes:
      - ./fluent.conf:/fluentd/etc/fluent.conf
      - fluentd-buffer:/fluentd/log
    depends_on:
      - kafka

  loki:
    image: grafana/loki:latest
    volumes:
      - loki-data:/loki
      - ./loki-config.yml:/etc/loki/local-config.yaml

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      - discovery.type=single-node
    volumes:
      - es-data:/usr/share/elasticsearch/data

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    depends_on:
      - loki
      - elasticsearch

volumes:
  fluentd-buffer:
  loki-data:
  es-data:
```

**Best Practices**:
1. ✅ Logs as structured data (JSON)
2. ✅ Unique trace IDs (correlation)
3. ✅ Multiple retention tiers (cost optimization)
4. ✅ Circuit breaker (logging failures don't crash app)
5. ✅ Sampling (reduce volume without losing insight)
6. ✅ Monitoring the monitoring system
7. ✅ Regular cost audits"

---

### 9. **You're tasked with migrating a 50-container monolithic Docker Compose environment to Kubernetes. What's your strategy and what are the main challenges?**

**Expected Answer**:

"This is a complex migration. Here's my phased approach:

**Phase 0: Assessment (2 weeks)**

```bash
# 1. Inventory current state
docker-compose ps  # Count services
docker-compose exec <service> env | grep -i "config\|secret\|url"
# Document all environment variables, volumes, mounts

# 2. Analyze dependencies
docker-compose config | yq '.services | keys'  # Service list

# 3. Identify migration blockers
# - Persistent volumes (stateful services)
# - Hardcoded IPs/hostnames
# - Docker Compose features not in K8s
# - Logging infrastructure
# - Secret management approach
```

**Challenge 1: Stateful Services**

Current Docker Compose setup:
```yaml
services:
  postgres:
    image: postgres:15
    volumes:
      - pgdata:/var/lib/postgresql/data
```

In Kubernetes:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pg-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi

---
apiVersion: apps/v1
kind: StatefulSet  # NOT Deployment for stateful services
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

**Challenge 2: Network Interdependencies**

Docker Compose: Service name = DNS hostname automatically
```yaml
services:
  api:
    environment:
      DATABASE_URL: postgres://postgres:5432  # Automatic DNS
```

Kubernetes: Requires explicit Service objects
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

**Challenge 3: Secrets Management**

Docker Compose (development):
```bash
# .env file (NEVER in git)
DB_PASSWORD=mypassword
API_KEY=abc123
```

Kubernetes (production):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db-password: bXlwYXNzd29yZA==  # base64 encoded
  api-key: YWJjMTIz
```

Requires external secret manager for production (Vault, AWS Secrets Manager):
```bash
# Sealed Secrets (encrypted secrets in git)
kubectl apply -f sealed-secret.yaml

# Vault Agent Injector (dynamic secret injection)
kubectl apply -f pod-with-vault-annotation.yaml
```

**Phase 1: Containerization Assessment (1 week)**

For each service:
```
┌─────────────────────────────────────┐
│ Service: API                        │
├─────────────────────────────────────┤
│ Type: Stateless (web application)   │
│ Current limits: --cpus 2 --memory 1g│
│ Dependencies: postgres, redis       │
│ Ports exposed: 8000                 │
│ Volumes: ./code:/app (bind mount)   │
│ Health check: GET /health           │
│ Scale target: 3-10 replicas         │
└─────────────────────────────────────┘
```

Document for each service:
- Stateless vs stateful
- Resource limits/requests
- Dependencies (explicit depends_on)
- Required volumes
- Environment configuration
- Secrets
- Health checks
- Expected replica count

**Phase 2: Create Kubernetes Manifests (2-3 weeks)**

```bash
# Option A: Manual conversion (full control)
# Create one YAML per service type

# Option B: Automated conversion (faster)
kompose convert -f docker-compose.yml  # Tool to auto-convert
# Results in K8s manifests (imperfect but starting point)

# Option C: Helm Charts (production-grade)
helm create myapp  # Templated deployment
# Edit values.yaml per environment
```

**Phase 3: Kubernetes Cluster Setup (1 week)**

```bash
# Create dev K8s cluster
minikube start  # Local development

# Or cloud-managed:
# Azure: az aks create
# AWS: eksctl create cluster
# GCP: gke-gcloud-auth cluster-create

# Install essential components
kubectl apply -f https://raw.githubusercontent.com/kubernetes/metrics-server/master/deploy/components.yaml  # Metrics
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack  # Monitoring
```

**Phase 4: Incremental Migration Strategy**

**Option A: "Strangler Pattern" (Recommended)**

Keep Docker Compose, gradually move services to K8s:

```
T0: All 50 services in Docker Compose
T1: Move 5 services to K8s (stateless first)
    Route traffic: 80% Compose, 20% K8s
T2: Move 15 services to K8s
    Route traffic: 60% Compose, 40% K8s
T3: Move remaining services
    Route traffic: 0% Compose, 100% K8s
```

Benefits:
- Low risk (reverting is easy)
- Can validate K8s approach
- Team learns gradually
- Parallel support of both platforms temporarily

**Option B: "Big Bang" (Only for small setups)**

Migrate everything at once. High risk, fast execution.

**I'd choose Strangler Pattern.**

**Phase 5: Manifest Organization**

```
k8s/
├── base/
│   ├── postgres/
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   ├── pvc.yaml
│   │   └── configmap.yaml
│   ├── api/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── ingress.yaml
│   └── redis/
│
├── overlays/
│   ├── development/
│   │   ├── kustomization.yaml
│   │   ├── replicas-patch.yaml
│   │   └── resource-limits-patch.yaml
│   ├── staging/
│   └── production/
│       ├── kustomization.yaml
│       ├── replicas-patch.yaml
│       └── ingress-patch.yaml
│
└── helmchart/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── ingress.yaml
    └── values-prod.yaml
```

**Phase 6: Testing Strategy**

```bash
# 1. Unit tests (K8s manifests)
kubeval k8s/**/*.yaml  # Syntax validation
helm lint helmchart/

# 2. Integration tests (K8s cluster)
kubectl apply -f k8s/base/
kubectl get pods  # All running?
kubectl logs -l app=api  # Check startup logs

# 3. Functional tests
./run-e2e-tests.sh  # Hit K8s ingress, verify responses
# Same tests that ran against Docker Compose

# 4. Load tests
ab -n 10000 -c 100 http://k8s-ingress.example.com/
# Compare response times vs Docker Compose
```

**Phase 7: Logging and Monitoring**

**Docker Compose logging**:
```yaml
logging:
  driver: fluentd
  options:
    fluentd-address: fluentd:24224
```

**Kubernetes logging**:
```yaml
# Fluentd DaemonSet (one per node)
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  template:
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
```

**Challenges overcome**:

| Challenge | Docker Compose Solution | K8s Solution |
|-----------|------------------------|--------------|
| Service discovery | DNS by name | K8s Service object |
| Configuration | .env files | ConfigMap/Secret |
| Persistent data | Named volume | PVC + StatefulSet |
| Scaling | --scale replica=5 | HPA (CPU-based) |
| Logging | Log driver | DaemonSet collector |
| Health checks | HEALTHCHECK | Liveness/Readiness probes |
| Resource limits | --memory/--cpus | requests/limits in spec |
| Updates | Manual restart | Rolling deployment |

**Major Challenges Remaining**:

1. **Complexity increase**: K8s is 100× more complex
   - Solution: Helm charts to abstract complexity
   - Solution: Teaching team gradually

2. **Cost increase**: More resources needed
   - Docker Compose: Single-node, $500/month
   - K8s: Multi-node HA, $5000+/month
   - Needs justification (reliability, scalability)

3. **Debugging difficulty**: Harder in K8s
   - Solution: Prometheus + Grafana
   - Solution: ELK/Loki for centralized logs
   - Solution: Kube kubeseal + Vault for secrets

4. **Team expertise**: Most teams new to K8s
   - Solution: Kubernetes training
   - Solution: Managed K8s (AKS, EKS) to reduce ops burden
   - Solution: Platform team to abstract complexity

**Migration Timeline**: 8-12 weeks for 50 containers

Week 1-2: Assessment
Week 3-4: K8s setup + manifests
Week 5-6: Strangler pattern (services 1-5 migrate)
Week 7-8: Services 6-15 migrate
Week 9-10: Services 16+ migrate
Week 11-12: Testing, validation, Docker Compose cleanup

**Success Criteria**:
- ✅ All services running on K8s
- ✅ Zero data loss during migration
- ✅ Performance equivalent or better
- ✅ Logging and monitoring equivalent
- ✅ Team trained on K8s
- ✅ Docker Compose environment retired"

---

### 10. **Walk through configuring a production-grade multi-environment deployment strategy (dev, staging, prod) with proper secret management and rollout controls.**

**Expected Answer**:

"A robust multi-environment strategy requires careful consideration of isolation, secrets, and deployment controls. Here's my comprehensive approach:

**Environment Architecture**:

```
┌──────────────────────────────────────────────────────────┐
│ Development Environment (Local)                          │
│ - docker-compose                                         │
│ - .env files (git-ignored)                              │
│ - No encryption (convenience prioritized)                │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Staging Environment (Full production replica)            │
│ - Kubernetes cluster                                     │
│ - Staging namespace isolation                           │
│ - Sealed Secrets (encrypted in git)                     │
│ - Same resource limits as production                     │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Production Environment (High availability)               │
│ - Kubernetes cluster (separate from staging)             │
│ - Restricted RBAC                                        │
│ - HashiCorp Vault (external secret manager)             │
│ - Audit logging (all deployments logged)                │
│ - Blue-green or canary deployments                      │
└──────────────────────────────────────────────────────────┘
```

**Phase 1: Environment Configuration Hierarchy**

```
# Base values (shared)
├── values-base.yaml
│   ├── replicas: 1
│   ├── image.registry: myregistry.azurecr.io
│   ├── image.repository: myapp
│
├── values-dev.yaml (inherits base)
│   ├── replicas: 1
│   ├── resoureces.limits.memory: 512Mi
│   ├── ingress.enabled: false
│   ├── secrets.source: file  # .env
│
├── values-staging.yaml (inherits base)
│   ├── replicas: 2
│   ├── resources.limits.memory: 2Gi
│   ├── ingress.enabled: true
│   ├── secrets.source: sealed-secrets
│   ├── monitoring.enabled: true
│
└── values-prod.yaml (inherits base)
    ├── replicas: 5
    ├── resources.limits.memory: 4Gi
    ├── autoscaling.enabled: true
    ├── ingress.enabled: true
    ├── secrets.source: vault
    ├── audit.enabled: true
    ├── backup.enabled: true
```

**Development Environment Setup**:

```yaml
# docker-compose.yml
version: '3.9'

services:
  app:
    image: myapp:latest
    build:
      context: .
      dockerfile: Dockerfile
    env_file: .env.local
    environment:
      ENVIRONMENT: development
      LOG_LEVEL: debug
      DEBUG: "true"
    ports:
      - "8000:8000"
    volumes:
      - ./src:/app/src  # Live reload
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
```

```bash
# .env.local (NEVER commit)
DATABASE_URL=postgres://postgres:password@localhost:5432/myapp
REDIS_URL=redis://localhost:6379
API_KEY=dev-key-only-for-testing
ENVIRONMENT=development
```

**Staging Environment Setup with Sealed Secrets**:

```bash
# 1. Install Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml -n kube-system

# 2. Create a secret locally
kubectl create secret generic app-secrets \
  --from-literal=database-url=postgres://user:password@postgres-staging:5432/myapp \
  --from-literal=api-key=staging-api-key-xyz \
  --from-literal=jwt-secret=staging-jwt-secret \
  --dry-run=client -o yaml > secret.yaml

# 3. Encrypt it with public sealing key
kubeseal -f secret.yaml -w sealed-secret.yaml

# 4. Commit encrypted secret to git
git add sealed-secret.yaml
git commit -m "Update staging secrets"

# 5. Controller automatically decrypts at runtime
kubectl apply -f sealed-secret.yaml
```

**Sealed Secret YAML**:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: app-secrets
  namespace: staging
spec:
  template:
    metadata:
      name: app-secrets
      namespace: staging
    type: Opaque
  encryptedData:
    api-key: AgBwQ3F...  # Encrypted, safe in git
    database-url: AgDxK2P...
    jwt-secret: AgEfR4M...
  sealing:
    clusterRole: sealed-secrets-key-admin
```

**Production Environment with HashiCorp Vault**:

```bash
# 1. Install Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  -f vault-values.yaml

# 2. Configure Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host=$KUBERNETES_HOST \
  kubernetes_ca_cert=$KUBERNETES_CA_CERT \
  token_reviewer_jwt=$TOKEN_REVIEWER_JWT

# 3. Create policies for each service
vault policy write myapp-policy - <<EOF
path "secret/data/prod/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# 4. Create Kubernetes role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=production \
  policies=myapp-policy \
  ttl=24h
```

**Production Deployment with Vault Integration**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 5
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-app-config: "secret/data/prod/myapp/config"
        vault.hashicorp.com/agent-inject-template-app-config: |
          {{- with secret "secret/data/prod/myapp/config" -}}
          export DATABASE_URL="{{ .Data.data.database_url }}"
          export API_KEY="{{ .Data.data.api_key }}"
          export JWT_SECRET="{{ .Data.data.jwt_secret }}"
          {{- end }}
    spec:
      serviceAccountName: myapp
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:1.2.0
        ports:
        - containerPort: 8000
        
        # Vault agent injects secrets as files
        volumeMounts:
        - name: vault-token
          mountPath: /vault/secrets
        
        # Application reads from mounted files
        env:
        - name: DATABASE_URL_FILE
          value: /vault/secrets/app-config
        
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5

      volumes:
      - name: vault-token
        emptyDir:
          medium: Memory

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
```

**Phase 2: Deployment Orchestration**

**Development** (Lightweight):
```bash
# CI/CD: Simple trigger
docker-compose down && docker-compose up -d
```

**Staging** (Rolling update with testing):
```bash
# Deployment strategy
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:${VERSION}
```

```bash
# Deployment steps
1. Create new pods (maxSurge: 1)
2. Wait for readiness probe
3. Run smoke tests
4. Proceed to next pod
5. All pods updated successfully

# If tests fail: automatic rollback
kubectl rollout undo deployment/myapp -n staging
```

**Production** (Canary deployment):

```bash
#!/bin/bash
# canary-deploy.sh

set -e

NEW_VERSION=$1
CANARY_PERCENTAGE=10  # Start with 10% traffic

echo "Deploying canary: $NEW_VERSION (${CANARY_PERCENTAGE}% traffic)"

# 1. Update Argo Rollouts with new version
argoctl config set image myapp=myregistry/myapp:${NEW_VERSION} -n production

# 2. Argo manages traffic shift: 10% → new, 90% → old
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  strategy:
    canary:
      steps:
      - setWeight: 10  # 10% traffic to new
      - pause: { duration: 10m }  # Monitor for 10 min
      - setWeight: 50  # 50% traffic
      - pause: { duration: 10m }
      - setWeight: 100  # All traffic
EOF

# 3. Monitor metrics during rollout
watch -n 5 'kubectl get rollout myapp -o jsonpath={.status.canaryWeight}'

# 4. Rollout automatic promotion if healthy
# If errors spike: automatic rollback
```

**Phase 3: Secret Rotation Strategy**

```bash
# Automated secret rotation (scheduled)
# CronJob in production

apiVersion: batch/v1
kind: CronJob
metadata:
  name: rotate-secrets
spec:
  schedule: "0 2 * * 0"  # Every Sunday 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: rotate
            image: vault:latest
            command:
            - /bin/sh
            - -c
            - |
              vault login -method=kubernetes role=rotate-role
              
              # Rotate API KEY
              NEW_KEY=$(openssl rand -hex 32)
              vault kv put secret/prod/myapp/config \
                api_key=$NEW_KEY \
                database_url=$DB_URL
              
              # Trigger pod restart to pick up new secret
              kubectl rollout restart deployment/myapp -n production
```

**Phase 4: Access Control & Audit**

**RBAC for each environment**:

```yaml
# Development: Open access (team can deploy)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-developer
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit  # Can create/update/delete
subjects:
- kind: User
  name: developer@company.com

---
# Production: Restricted access (only CI/CD, approved humans)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prod-deployer
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # Read-only
subjects:
- kind: ServiceAccount
  name: ci-cd-service-account

---
# Secret access restricted
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: vault-admin
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "create", "update"]
  resourceNames: ["app-secrets"]  # Only specific secret
```

**Audit logging** (who deployed what, when):

```bash
# Audit log of all API calls
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  verbs: ["create", "update", "patch", "delete"]
  resources: ["deployments", "secrets"]
  namespaces: ["production"]
  omitStages:
  - RequestReceived
```

**Phase 5: Promotion Pipeline**

```
┌─────────────────┐
│ Code Push (git) │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────┐
│ 1. Build & Test             │
│ - Run unit tests            │
│ - Build Docker image        │
│ - Scan for vulnerabilities  │
│ - Push to registry          │
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│ 2. Dev Deployment           │
│ - Auto-deploy on PR         │
│ - Manual approval: none     │
│ - Health checks: basic      │
└────────┬────────────────────┘
         │
         ↓ (Merge to main)
┌─────────────────────────────┐
│ 3. Staging Deployment       │
│ - Rolling update            │
│ - Manual approval: none     │
│ - Health checks: complete   │
│ - E2E tests run             │
└────────┬────────────────────┘
         │
         ↓ (Release tag)
┌─────────────────────────────┐
│ 4. Production Deployment    │
│ - Canary (10% traffic)      │
│ - Manual approval: required │
│ - Health checks: strict     │
│ - Monitoring: enabled       │
│ - Auto-rollback on failure  │
└─────────────────────────────┘
```

**Deployment YAML** (GitOps):

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-prod
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/company/myapp-helm
    targetRevision: main
    path: helm/myapp
    helm:
      valueFiles:
      - values-prod.yaml
      parameters:
      - name: image.tag
        value: v1.2.0  # From release tag
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
  
  # Require manual approval before sync
  revisionHistoryLimit: 10
```

**Best Practices Summary**:

1. ✅ **Secrets by environment**:
   - Dev: .env files (convenience)
   - Staging: Sealed Secrets (encrypted in git)
   - Prod: External Vault (rotation, audit)

2. ✅ **Deployment strategies**:
   - Dev: Immediate (fast feedback)
   - Staging: Rolling (quick iteration)
   - Prod: Canary (safety first)

3. ✅ **Access control**:
   - Dev: Open (developers empowered)
   - Staging: Gated (review required)
   - Prod: Restricted (least privilege)

4. ✅ **Monitoring & Audit**:
   - All deployments logged
   - Automatic rollback on failure
   - Health checks increasing in rigor

5. ✅ **Promotion path**:
   - Code → Dev → Staging → Prod
   - Same binary tested in each environment
   - Configuration differs, not code"

---

**End of Interview Questions Section**

---

## Document Index & References

**Completed Sections**:
1. ✅ Table of Contents
2. ✅ Introduction
3. ✅ Foundational Concepts
4. ✅ Resource Management (CPU, Memory, Block IO, PIDs, Device Access, Swap)
5. ✅ Environment Management (Variables, .env, Configs, Secrets, Build Args)
6. ✅ Docker Compose (Architecture, YAML Structure, Services, Networks, Volumes, Scaling)
7. ✅ Logging & Monitoring (Log drivers, Centralized logging, Metrics, Health checks, Alerting)
8. ✅ Hands-on Scenarios (4 realistic DevOps scenarios with step-by-step solutions)
9. ✅ Interview Questions (10 detailed senior-level interview questions with comprehensive answers)

**Study Guide Completion Status**: 100% COMPLETE

All sections have been generated with:
- Comprehensive explanations
- Real-world examples and code samples
- Production-grade best practices
- Architecture diagrams and decision trees
- Hands-on scenarios with troubleshooting
- Interview questions with senior engineer perspective

**Total Content**: ~28,000 words of expert-level Docker/DevOps material
**Target Audience**: Senior DevOps Engineers (5-10+ years experience)
**Date Generated**: March 7, 2026

---

**Study Guide File Location**:
[7_Docker-Resource-Environment-Compose-Monitoring-Study-Guide-2026-03-07.md](07-docker/7_Docker-Resource-Environment-Compose-Monitoring-Study-Guide-2026-03-07.md)


---

## Interview Questions

### 1. **You're troubleshooting a container that OOM kills after 2 hours under production load. Walk through your diagnostic process and explain the difference between `--memory` and `--memory-reservation`.**

**Expected Answer**:

"I'd approach this systematically:

**Diagnostic Process**:
1. First, confirm it's OOM kill: Check exit code 137 via `docker inspect` or `kubectl describe pod`
2. Collect memory metrics: Use `docker stats`, Prometheus, or `kubectl top` to see usage pattern
3. Identify the pattern:
   - Monotonic growth = memory leak (unbounded accumulation)
   - Steep spike = cache not bounded
   - Linear growth = leak getting worse
4. Profile the application:
   - Python: `memory_profiler` or `py-spy`
   - Java: `jprofdump` or `async-profiler`
   - Node: `clinic`, `heapdump`
5. Find root cause:
   - Global lists/caches without size limits
   - Unclosed database connections
   - Event listeners not cleaning up
6. Implement fix:
   - Add cache TTL or bounded size (LRU)
   - Connection pooling with max connections
   - Event cleanup (unregister listeners)

**Memory Limit vs Reservation**:

`--memory` is a **hard limit**:
- Container cannot exceed this under any circumstance
- Exceeding = immediately OOM kill (exit 137)
- Used to prevent runaway process from crashing entire host
- Strict enforcement by Linux kernel (cgroups)

`--memory-reservation` is a **soft limit**:
- Kernel *tries* to keep container under this
- If memory pressure, kernel reclaims, but allows burst
- Container can temporarily exceed reservation
- Used to guide scheduler (Kubernetes) about required memory
- Not an absolute cap

**Example**:
```bash
docker run --memory 2g --memory-reservation 512m myapp

# Scenario 1: Normal operation
# Uses 400MB - no issues, under reservation

# Scenario 2: Spike to 600MB
# Over reservation, but under limit
# Allowed temporarily, kernel may reclaim

# Scenario 3: Reaches 2GB
# At hard limit, no more memory available
# Next malloc → OOM kill

# Scenario 4: Without swap
docker run --memory 2g --memory-swap 2g myapp
# No swap available, stricter behavior
```

**In Kubernetes terms**:
- `requests.memory` = reservation (scheduler considers this)
- `limits.memory` = hard limit (kubelet enforces)

If requests > node available memory, pod cannot be scheduled.
If limits exceeded, pod is OOM killed.

**Production best practice**: Set limits=2× reservation. Reservation provides guidance, limit prevents catastrophe."

---

### 2. **Explain how Docker Compose networking works. How would you ensure services can communicate while maintaining security isolation?**

**Expected Answer**:

"Docker Compose networking provides automatic DNS-based service discovery. Here's how it works:

**Default Behavior**:
- Creates bridge network named `<project>_default`
- Attaches all services to this network
- Docker embedded DNS server resolves service names to container IPs
- Containers reach each other by service name (no hardcoding IPs)

**DNS Resolution Flow**:
```
Container 'web' wants to reach 'db'
  ↓
Makes DNS query to 127.0.0.11:53 (Docker's embedded DNS)
  ↓
Docker daemon looks up 'db' service IPs
  ↓
Returns all healthy 'db' container IPs
  ↓
Container connects to one (round-robin)
```

**Security Isolation via Multiple Networks**:

Services should be segmented by tier:

```yaml
networks:
  frontend:  # Public-facing services
  backend:   # Internal services
  database:  # Data tier

services:
  web:
    networks:
      - frontend
  api:
    networks:
      - frontend
      - backend
  cache:
    networks:
      - backend
      - database
  db:
    networks:
      - database
```

**Result**:
- Web server can reach API (both on frontend)
- API can reach cache and DB (on backend/database)
- **Web cannot reach DB directly** (not on same network)
- **Cache cannot reach web** (not on same network)

This creates a default-deny security model:
- Only explicitly connected services can communicate
- Compromised web service cannot access database directly
- Network policies enforced by Docker, not just iptables

**Advanced: Ingress Network** (Multiple hosts):

```yaml
driver_opts:
  com.docker.network.driver.overlay.vxlan_list: 4789
```

**Network Inspection**:
```bash
docker network inspect myproject_frontend

# Shows:
# - Network driver (bridge/overlay)
# - Containers connected
# - IP addresses assigned
# - Custom DNS servers

docker exec container-name nslookup service-name
# Verify DNS resolution works
```

**Common Gotcha**: Using `localhost` instead of service name:
```python
# WRONG: Works on host, fails in container
db = psycopg2.connect('localhost:5432')

# CORRECT: Uses Docker DNS
db = psycopg2.connect('db:5432')
```

**Network Policies in K8s** (more sophisticated):
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
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
```

This ensures only API pods can reach database, everything else blocked."

---

### 3. **How do you handle secrets rotation in a production Swarm cluster without downtime or manual restarts?**

**Expected Answer**:

"Secrets rotation is critical for compliance. Here's the production-grade approach:

**Challenge**: Container has mounted secret file. If we just create new secret, container still sees old one.

**Solution**: Automated rolling restart with health checks.

**Implementation**:

**Step 1: Create new secret version**
```bash
# New secret with version suffix
echo 'new-password-xyz' | docker secret create db-password-v2 -

# Verify both exist
docker secret ls
# db-password     [old]
# db-password-v2  [new]
```

**Step 2: Update service with zero downtime**
```bash
docker service update \
  --secret-rm db-password \           # Remove old
  --secret-add source=db-password-v2,target=db-password \  # Add new
  --update-order start-first \        # Start new before killing old
  --update-parallelism 1 \            # One replica at a time
  --update-delay 10s \                # 10s between updates
  myapp
```

**Step 3: Monitor rolling restart**
```bash
# Watch replica status
watch docker service ps myapp

# Output shows:
# ID  NAME           STATE       DESIRED STATE
# ... myapp.1  RUNNING     Running
# ...   prep for update
# ... myapp.1  SHUTDOWN    Running  [Old task stopping]
# ... myapp.1  RUNNING     Running  [New task started]
# Same process for .2 and .3

# Verify old task fully stopped before next update starts
```

**Step 4: Application safely reads new secret**
```python
# Application code (unchanged)
with open('/run/secrets/db-password', 'r') as f:
    password = f.read().strip()

# During rolling restart:
# Old container: mounted to old secret file
# New container: mounted to new secret file
# Connection pool might need to reconnect
```

**Step 5: Cleanup old secret**
```bash
# Wait 5 minutes to ensure all old tasks are gone
docker service ps myapp --no-trunc  # Verify no 'db-password' references

# Delete old secret
docker secret rm db-password

# Verify
docker secret ls  # Only db-password-v2 remains
```

**Automation with Script**:
```bash
#!/bin/bash
SERVICE=$1
SECRET=$2
NEW_VALUE=$3

# 1. Create with version
VERSION=$(date +%s)
echo "$NEW_VALUE" | docker secret create ${SECRET}-${VERSION} -

# 2. Update service
docker service update \
  --secret-rm $SECRET \
  --secret-add source=${SECRET}-${VERSION},target=${SECRET} \
  --update-order start-first \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-failure-action continue \
  $SERVICE

# 3. Wait for completion
while [[ $(docker service ps $SERVICE | grep 'Running' | wc -l) -lt $(docker service ls --filter name=$SERVICE --format='{{.Replicas}}' | cut -d/ -f1) ]]; do
  echo "Waiting for update..."
  sleep 5
done

# 4. Cleanup old
OLD_SECRETS=$(docker secret ls --filter 'label=secret-pool='$SECRET | awk '{print $1}' | grep -v ${VERSION})
for s in $OLD_SECRETS; do
  docker secret rm $s
done

echo "Rotation complete"
```

**Kubernetes Approach** (Simpler - automatic pod restart):
```bash
# Update secret
kubectl create secret generic db-credentials \
  --from-literal=password=new-value \
  --dry-run=client -o yaml | kubectl apply -f -

# Automatic rolling restart via rollout restart
kubectl rollout restart deployment/myapp -n production

# Monitors: app will re-read secret from mounted file
```

**Compliance Benefits**:
✅ Automatic rotation (scheduled cron job can trigger)
✅ Zero downtime (rolling update)
✅ Audit trail (timestamp in secret name)
✅ Quick rollback (old secret still exists for 5 mins)
✅ No application changes needed (reads from file path)

**Production checklist**:
- [ ] Secrets encrypted in transit (TLS)
- [ ] Secrets encrypted at rest (Swarm uses encrypted RAFT)
- [ ] Audit logging enabled (who rotated when)
- [ ] Rotation frequency: every 30/60/90 days
- [ ] Test rotation in staging first
- [ ] Alert on rotation failure"

---

### 4. **Compare `docker-compose up`, `docker service create`, and Kubernetes deployments. When would you use each?**

**Expected Answer**:

"These three approaches have different tradeoffs. Let me break down the decision matrix:

**docker-compose up** (Single host orchestration):
- **When**: Development, testing, simple deployments
- **Scale**: 1 host, up to ~20 containers
- **Orchestration**: None (no automatic restarts, rescheduling)
- **Networking**: Automatic bridge networks, DNS
- **Secrets**: Via Docker secrets (but limited - must have Swarm mode enabled)
- **Updates**: Manual (recreate containers)
- **State**: Stateless orchestration (compose doesn't track desired state across reboots)

```yaml
docker-compose up
# Great for: Local dev, CI environments, stateless services

docker-compose ps
# Shows current state, but if host reboots, services don't auto-restart
```

**docker service create** (Docker Swarm - multi-host):
- **When**: Multi-host deployments, Swarm-native clusters
- **Scale**: Many hosts, hundreds of containers
- **Orchestration**: Full (distributed, fault-tolerant, state-keeping)
- **Networking**: Overlay networks across hosts, automatic load balancing
- **Secrets**: Native encrypted secrets management
- **Updates**: Declarative rolling updates with health checks
- **State**: Swarm maintains desired state (reconciliation loop)

```bash
docker service create \
  --replicas 3 \
  --secret db-password \
  --healthcheck-cmd 'curl -f http://localhost/health' \
  myapp:1.0.0

# Swarm ensures 3 replicas running at all times
# Automatic restart if container fails
# Rolling updates with automatic rollback
```

**Kubernetes** (Full-featured container orchestration):
- **When**: Complex microservices, multi-cloud, enterprises
- **Scale**: Unlimited (100s of nodes, 1000s+ containers)
- **Orchestration**: Sophisticated (custom controllers, operators)
- **Networking**: CNI plugins (Calico, Flannel), service mesh options
- **Secrets**: Encrypted, RBAC, audit logging
- **Updates**: Advanced strategies (blue-green, canary)
- **State**: Desired state in etcd, highly available

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
      maxSurge: 1
```

**Decision Matrix**:

| Criterion | docker-compose | Docker Swarm | Kubernetes |
|-----------|-----------------|--------------|-----------|
| Setup complexity | 5 mins | 30 mins | 2 hours |
| Multi-host | ❌ | ✅ | ✅✅ |
| Self-healing | ❌ | ✅ | ✅✅ |
| Scaling | Manual | Automatic | Automatic |
| Secrets management | Basic | ✅ | ✅✅ |
| Learning curve | Easy | Medium | Steep |
| Production-ready | ✅ Small scale | ✅ Medium scale | ✅ Any scale |
| Vendor lock-in | Docker only | Docker only | Cloud-agnostic |
| Extensions | Limited | Limited | Rich (CNI, CSI, CRDs) |

**Real-world scenarios**:

**Scenario 1: Startup (3-5 services)**
→ Use docker-compose
→ Reason: Fast to setup, easy debugging, sufficient for MVP
→ Migration path: Move to Swarm when multi-host needed

**Scenario 2: Funded startup (15-30 services, 2-4 hosts)**
→ Use Docker Swarm
→ Reason: Distributed, built-in secrets, operational simplicity
→ Low overhead, familiar Docker tools
→ Trade-off: Less flexible than K8s, harder to move later

**Scenario 3: Enterprise (50+ services, high availability)**
→ Use Kubernetes
→ Reason: Industry standard, ecosystem rich (Helm, service mesh)
→ Justifies complexity with operational maturity
→ Can hire K8s specialists

**Hybrid Approach** (Common in large orgs):
```
├─ Kubernetes (production microservices)
├─ Docker Compose (developer local envs)
└─ Docker Swarm (legacy apps, simpler workloads)
```

**My personal recommendation** (as senior engineer):

1. **Start with docker-compose** for anything <10 containers, 1 host
2. **Migrate to Swarm** for multi-host but simpler requirements
3. **Adopt Kubernetes only if**:
   - Multi-team organization (RBAC important)
   - Complex service dependencies (operators/custom resources)
   - Multi-cloud strategy
   - Budget for operational overhead

Kubernetes is powerful but expensive (in time and infrastructure). Don't adopt prematurely."

---

### 5. **A service's response time increases from 100ms to 2000ms+ under load. Walk through your troubleshooting methodology, including resource limiting.**

**Expected Answer**:

"Increased latency under load typically indicates resource contention. Here's my systematic approach:

**Phase 1: Baseline Metrics Collection**

```bash
# 1. Identify affected service (from monitoring/alerting)
# 2. Collect baseline metrics (before issues started)

# Current resource usage
docker stats <service>
# Shows: CPU %, memory, network I/O

# Historical metrics (from Prometheus)
SELECT rate(http_request_duration_seconds_sum[5m]) / 
       rate(http_request_duration_seconds_count[5m])
# Math: sum of durations / count = average latency

# Check request rate
rate(http_requests_total[5m])  # requests per second
```

**Phase 2: Identify Bottleneck**

**Is it CPU?**
```promql
# Rising CPU under load
rate(container_cpu_usage_seconds_total[5m]) > 0.8

# Check CPU throttling (hard limit reached)
container_cpu_throttled_seconds_total > 0  # Non-zero = being throttled

# If CPU is the issue:
# - Application code is slow (profiling needed)
# - Not enough CPU allocated (increase --cpus)
# - CPU contention with other containers (increase --cpu-shares)
```

**Is it Memory?**
```promql
# Memory pressure
container_memory_usage_bytes / container_memory_limit_bytes > 0.9

# Check for swap (slower than RAM)
container_memory_swap_usage_bytes > 0

# If memory is the issue:
# - Increase --memory limit
# - Reduce cache size
# - Check for memory leak
```

**Is it I/O?**
```bash
# Check disk I/O
docker exec <service> iostat -x 1 5

# Look for high 'await' time = slow I/O
# May indicate:
# - Database queries too slow
# - Disk bandwidth saturated
# - Noisy neighbor consuming I/O

# In Prometheus
rate(container_fs_io_current[5m])  # Current I/O operations
```

**Is it Network?**
```bash
# Check network latency
docker exec <service> ping <dependency>

# Check packet loss
docker exec <service> mtr <dependency>

# Check bandwidth saturation
docker stats | grep 'NET I/O'

# Kubernetes service DNS slowness
docker exec <service> nslookup <service-name>
```

**Is it Dependency?**
```bash
# Database slow queries
docker exec postgres psql -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 5;"

# Cache misses
docker exec redis redis-cli INFO stats | grep -E "hits|misses"
# Cache hit ratio should be >90%

# Message queue backlog
docker exec rabbitmq rabbitmqctl list_queues name messages
```

**Phase 3: Find Root Cause**

Example diagnosis:
```bash
# Prometheus query shows:
# - CPU: 45% (not maxed out)
# - Memory: 60% (headroom available)
# - Disk I/O: High 'await' time observed

# Application profiling reveals:
# Database query takes 1.5 seconds (should be <100ms)

# Root cause: N+1 SQL queries
# Under load: 1000 requests/sec × 10 SQL queries each = 10k queries/sec
# Database cannot handle, queue builds, response time increases
```

**Phase 4: Resource Tuning**

```bash
# Current deployment
docker run -e PROFILE=production \
           --cpus 1 \
           --memory 512m \
           myapp

# Issue: Database queries slow
# Solution options:

# Option A: Add query caching
# Reduces database load

# Option B: Database optimization
# Add indexes, rewrite queries

# Option C: Increase resource allocation
docker run --cpus 2 \           # Can now handle 2× requests before hitting CPU limit
           --memory 1g \
           myapp

# Option D: Scale horizontally
docker service scale myapp=5    # Run 5 replicas instead of 1
```

**Phase 5: Implement Fix**

```bash
# Before: 1 replica, CPU limited
docker service create --name myapp \
  --cpus 1 \
  --memory 512m \
  --replicas 1 \
  myapp:1.0.0

# Problem: Under load (1000 req/s), single replica maxes out CPU

# After: 3 replicas, load balanced
docker service create --name myapp \
  --cpus 1 \
  --memory 512m \
  --replicas 3 \
  --update-order start-first \
  myapp:1.0.0

# Now: 1000 req/s ÷ 3 replicas = ~333 req/s per replica
# Each replica at ~30% CPU (well under 1 CPU limit)
```

**Kubernetes Example**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: myapp
        image: myapp:1.0.0
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
          limits:
            cpu: "1"
            memory: "1Gi"

# If load increases, HPA auto-scales
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
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
```

**Phase 6: Validation**

```bash
# Load test after fix
ab -n 10000 -c 100 http://localhost:8000/api/data

# Monitor: latency should drop significantly
# Before: p99 = 2000ms
# After: p99 = 150ms

# Verify no resource exhaustion
docker stats
# CPU: ~65-75% (not maxed)
# Memory: ~60% (headroom)
```

**Production Checklist**:
- [ ] Identified bottleneck (CPU/Memory/I/O/Network/Dependency)
- [ ] Appropriate resource limits set
- [ ] Autoscaling configured (if horizontal scaling viable)
- [ ] Dependency optimized (DB indexes, caching, etc.)
- [ ] Monitoring alerts on latency regression
- [ ] Tested fix under realistic load
- [ ] Rollback plan documented"

---

### 6. **Explain the purpose of health checks, liveness probes, and readiness probes. How are they different and when would one fail when others pass?**

**Expected Answer**:

"These three concepts serve different purposes in container lifecycle management:

**Health Checks (Docker native)**:
- Periodic test to determine if container is 'healthy'
- Executes inside container at specified interval
- Three possible states: starting, healthy, unhealthy
- Used by Docker to determine if container should restart
- Separate from actual service readiness

```dockerfile
FROM ubuntu:22.04
CMD ["python", "app.py"]

HEALTHCHECK --interval=30s --timeout=3s --retries=3 --start-period=10s \
  CMD curl -f http://localhost:8000/health || exit 1
```

Output: `docker inspect <container>` shows `Health: healthy/unhealthy`

**Liveness Probe (Kubernetes)**:
- Determines if container is still running
- Framework for determining if container should be restarted
- "Is the process alive?"
- If fails, kubelet kills and restarts container
- Purpose: Detect and restart dead/stuck processes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3  # 3 failures = kill and restart
```

**Readiness Probe (Kubernetes)**:
- Determines if container should receive traffic
- "Is the service ready to handle requests?"
- If fails, service is removed from load balancer (but not killed)
- Purpose: Prevent traffic before service ready

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 1  # Single failure = remove from LB
```

**Key Differences**:

| Aspect | Health Check | Liveness | Readiness |
|--------|-------------|----------|-----------|
| Purpose | Container healthy? | Still running? | Accept traffic? |
| Failure action | Log unhealthy | Kill & restart | Remove from LB |
| Typical endpoint | `/health` | `/health` | `/ready` |
| Sensitivity | Moderate | Coarse-grained | Fine-grained |
| Initial delay | 10-30s | 15-30s | 5-10s |
| Frequency | 30s | 10s | 5s |

**Real-world Scenarios Where They Differ**:

**Scenario 1: Application starts but not ready**

```python
# app.py
@app.route('/health')
def health():
    """Process is running, respond immediately"""
    return {'status': 'alive'}, 200

@app.route('/ready')
def ready():
    """Service is ready when DB connection works"""
    try:
        db.ping()
        return {'status': 'ready'}, 200
    except:
        return {'status': 'not_ready'}, 503
```

**Timeline**:
```
T0s   Container starts
T2s   Application binds to port, /health responds
      Liveness: PASS ✅ (process is running)
      Readiness: FAIL ❌ (still initializing DB)
      Health: PASS ✅ (process alive)

T5s   Database connection established
      Readiness: PASS ✅ (ready for traffic)
      Pod receives traffic from load balancer
```

**Scenario 2: Deadlock (process running but hanging)**

```python
import threading

# Deadlock: Thread A waits for Thread B, Thread B waits for Thread A
lock_a = threading.Lock()
lock_b = threading.Lock()

def thread_a():
    lock_a.acquire()
    time.sleep(0.1)
    lock_b.acquire()  # Waits forever for B to release

def thread_b():
    lock_b.acquire()
    time.sleep(0.1)
    lock_a.acquire()  # Waits forever for A to release

# Probe behavior:
@app.route('/health')
def health():
    """Process still running, this endpoint works"""
    return 200  # Takes milliseconds

@app.route('/ready')
def ready():
    """Tries to call method that's blocked"""
    result = api_call()  # Hangs indefinitely (thread deadlock)
    return 200

# Result:
# Liveness: PASS (curl /health succeeds immediately)
# Readiness: FAIL (curl /ready hangs, timeout triggers)
# Container not restarted (liveness passes)
# But removed from load balancer (readiness fails)
```

**Scenario 3: External Dependency Failure**

```python
@app.route('/health')
def health():
    """Just check if service is running"""
    return {'status': 'healthy'}, 200

@app.route('/ready')
def ready():
    """Check if can talk to dependencies"""
    checks = {
        'database': check_database(),
        'cache': check_cache(),
        'message_queue': check_mq(),
    }
    if all(checks.values()):
        return checks, 200
    else:
        return checks, 503  # Not ready if any dependency down
```

**Scenario**:
- Database goes down (maintenance, failure)
- All containers reach readiness failures
- Removed from load balancer (no traffic)
- Liveness still passes (process not affected)
- Wait for database recovery
- Readiness checks pass again
- Containers back in load balancer

**Scenario 4: Resource Starvation**

```python
# Memory leak or high CPU load
@app.route('/health')
def health():
    """Minimal endpoint, doesn't trigger GC"""
    return 200  # Always fast

@app.route('/ready')
def ready():
    """More complex, triggers memory allocation"""
    data = fetch_large_dataset()  # OOM or timeout
    return 200
```

**Result**:
- Liveness: PASS (lightweight endpoint works)
- Readiness: FAIL (complex endpoint times out or OOM)
- Container not restarted (liveness metric okay)
- Removed from load balancer (graceful degradation)

**Best Practice Implementation**:

```python
from flask import Flask
import threading
import time

app = Flask(__name__)

# Shared state
startup_complete = False
db = None
cache = None
mq = None

def initialize():
    """Run on startup, sets startup_complete flag"""
    global startup_complete, db, cache, mq
    
    db = Database()
    cache = Cache()
    mq = MessageQueue()
    
    startup_complete = True

@app.route('/health')
def health():
    """Liveness: Is the process alive?"""
    # Very lightweight, no I/O
    # Just confirm we're here
    if not startup_complete:
        return {'status': 'starting'}, 503
    return {'status': 'healthy'}, 200

@app.route('/ready')
def ready():
    """Readiness: Can I handle requests?"""
    if not startup_complete:
        return {'status': 'initializing'}, 503
    
    # Check dependencies are accessible
    checks = {
        'database': db.is_connected(),
        'cache': cache.is_connected(),
        'mq': mq.is_connected(),
    }
    
    if all(checks.values()):
        return checks, 200
    else:
        app.logger.warning(f"Ready check failed: {checks}")
        return checks, 503

# Use different endpoints semantically
@app.route('/status')
def status():
    """Health + Ready combined (for monitoring)"""
    return {
        'health': health()[0],
        'ready': ready()[0],
    }, 200
```

**Kubernetes YAML**:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15  # Let startup complete
  periodSeconds: 10
  failureThreshold: 3      # Tolerate 3 failures (30s) before kill
  timeoutSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8000
  initialDelaySeconds: 5
  periodSeconds: 5        # Check frequently
  failureThreshold: 1     # Remove from LB immediately on failure
  timeoutSeconds: 1       # Timeout quickly (dependency dependency is down)
```

**When to Use Each**:
- **Liveness only**: Simple stateless services that don't need dependencies
- **Readiness only**: Services that should boot but not receive traffic until ready
- **Both**: Most production services (self-healing + graceful degradation)
- **Health checks**: Docker Compose environments as lightweight alternative"

---

### 7. **You have 10 microservices with complex interdependencies defined in Docker Compose. Describe your strategy for detecting and debugging a cascading failure that started in a single service.**

**Expected Answer**:

"Cascading failures are common in distributed systems. Here's my debugging methodology:

**Step 1: Identify the Initial Failure Point**

```bash
# 1. Check compose logs for earliest error
docker-compose logs --since 10m | grep -i error | head -5

# Look for timestamps - find FIRST error
# 2024-03-07 10:15:30 [service-a] ERROR: Connection refused
# 2024-03-07 10:15:31 [service-b] ERROR: Timeout
# 2024-03-07 10:15:31 [service-c] ERROR: Timeout

# Service-A failed first, B and C timed out trying to reach A

# 2. Check service status
docker-compose ps
# Shows which containers are running, restarting, exited

# 3. Get detailed logs for initial failure
docker-compose logs service-a --tail 50
```

**Step 2: Map Dependencies**

From docker-compose.yml, identify the dependency graph:

```yaml
services:
  database:
    image: postgres
  
  cache:
    image: redis
  
  api:
    image: api:latest
    depends_on:
      - database
      - cache
    environment:
      DATABASE_URL: postgres://database:5432
      REDIS_URL: redis://cache:6379
  
  worker:
    depends_on:
      - api
      - queue
  
  queue:
    image: rabbitmq
  
  web:
    depends_on:
      - api
```

Visual dependency map:
```
database ──┐
           ├─→ api ──→ web
cache ─────┤        └─→ worker
           └→ worker ←── queue
```

**Step 3: Trace Failure Propagation**

```bash
# Scenario: API fails to start

# Effect on dependents:
docker-compose logs web
# "ERROR: Failed to connect to api:8000"
# "ERROR: api service unavailable"

docker-compose logs worker
# "ERROR: Cannot reach api"
# "ERROR: Queue consumer offline"

# Cascade: API failure → Web cannot forward requests → Worker orphaned
# Result: Entire dependent chain offline
```

**Step 4: Investigate API Failure Root Cause**

```bash
# Check API logs for actual error
docker-compose logs api | tail -20

# Possible errors:
# Error 1: "Connection refused to database:5432"
#   → Database not started or not healthy
# Error 2: "ERROR: Unable to bind to port 8000"
#   → Port already in use or permission denied
# Error 3: "ERROR: Certificate not found"
#   → Missing volume mount or config
```

**Diagnosis: Database not healthy**

```bash
# Check database container
docker-compose ps database
# Status: Up (container is running)

# But API can't connect, why?
docker-compose logs database | grep -i error
# "FATAL: password authentication failed for user \"api\""

# Issue: Wrong credentials in API environment

docker-compose logs database | grep -i "listening"
# "listening on IPv4 address \"0.0.0.0\", port 5432"
# Database IS listening

# Test connection from API container
docker-compose exec api psql -h database -U api -d myapp -c "SELECT 1"
# psql: error: FATAL:  password authentication failed

# Root cause confirmed: API environment variable password mismatch
```

**Step 5: Fix and Verify Propagation**

```yaml
# Fix environment variable in docker-compose.yml
services:
  api:
    environment:
      DATABASE_URL: postgres://api:correct-password@database:5432/myapp
```

```bash
# Restart service
docker-compose up -d api

# Verify API comes up
docker-compose ps api
# Status: Up (healthy)

# Verify API is healthy
docker-compose logs api
# "Connected to database successfully"
# "Listening on port 8000"

# Database logs confirm connection
docker-compose logs database | grep "api"
# "authenticating user \"api\""
# "connection received"
```

**Step 6: Cascade Healing**

Once API is healthy, dependent services should recover:

```bash
# With proper depends_on:
services:
  web:
    depends_on:
      api:
        condition: service_healthy

# Docker automatically restarts services with unmet dependencies
docker-compose up -d

# Check recovery
docker-compose ps
# api       Status: Up (now healthy)
# web       Status: starting → Up (restarted, now can reach api)
# worker    Status: starting → Up (restarted)
```

**Step 7: Prevent Similar Cascades**

**Add health checks to all services**:

```yaml
services:
  api:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
      retries: 3
      timeout: 5s
    depends_on:
      database:
        condition: service_healthy  # Wait for DB first
  
  database:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 3s
```

**Add retry logic in application**:

```python
# Python example: Exponential backoff
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, min=2, max=10)
)
def connect_database():
    """Retry with exponential backoff"""
    return psycopg2.connect(os.environ['DATABASE_URL'])

# Attempt 1: immediate
# Attempt 2: wait 2s
# Attempt 3: wait 4s
# Attempt 4: wait 8s
# Attempt 5: wait 10s
```

**Add circuit breakers**:

```python
from pybreaker import CircuitBreaker

api_breaker = CircuitBreaker(
    fail_max=5,        # Fail after 5 errors
    reset_timeout=60   # Try again after 60s
)

@app.route('/data')
def get_data():
    try:
        return api_breaker.call(fetch_from_upstream)
    except Exception:
        # Fallback to cache
        return get_cached_data()
```

**Monitoring for Cascades**:

```prometheus
# Alert on service dependency failures
- alert: ServiceUnhealthy
  expr: |
    up{job="docker"} == 0
    or
    rate(http_errors_total[5m]) > 0.1
  for: 2m
  annotations:
    summary: "{{ $labels.service }} unhealthy for 2 min"

# Alert on degradation spreading
- alert: CascadingFailureDetected
  expr: |
    increase(services_down_total[5m]) > 1
  annotations:
    summary: "Multiple services offline - cascading failure"
    runbook: "Check root cause service, fix primary issue"
```

**Best Practices for Cascade Resilience**:
1. ✅ Hard dependencies explicitly declared (depends_on + condition)
2. ✅ Health checks on all services
3. ✅ Timeouts and circuit breakers in client code
4. ✅ Graceful degradation (cache fallback, queue buffering)
5. ✅ Monitoring correlation (which failures trigger which cascades)
6. ✅ Testing: Chaos engineering (kill services in sequence, verify failure propagation)"

---

### 8. **How would you design a centralized logging solution for 50+ Docker containers across multiple hosts? Address scalability, retention, searching, and cost.**

**Expected Answer**:

"Logging at scale requires careful architecture. Here's my comprehensive design:

**Architecture Overview**:

```
┌─────────────────────────────────────────┐
│ 50+ Docker Containers (Multiple Hosts)  │
│ - Containers emit logs (stdout/stderr)  │
└────────────┬────────────────────────────┘
             │
       ┌─────▼──────┐
       │ Log Drivers│  (Fluentd, Filebeat, Logstash)
       │ (Collectors)
       └─────┬──────┘
             │
       ┌─────▼──────────────────┐
       │ Message Broker (Kafka) │ (High throughput, fault-tolerant)
       └─────┬──────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼────┐
│ Loki   │      │Elasticsearch│
│ (cheap)│      │  (queryable) │
└───┬────┘      └────┬────┘
    │                │
    └────────┬───────┘
             │
        ┌────▼────────┐
        │  Grafana    │ (Unified dashboard)
        └─────────────┘
```

**Design Decisions**:

**1. Log Collection Strategy**

**Option A: Host-based (Lightweight)**
```
Container logs → Host Docker daemon → Log driver sends to collector
```

```json
// docker daemon.json
{
  "log-driver": "fluentd",
  "log-opts": {
    "fluentd-address": "localhost:24224",
    "labels": "hostname,environment,application",
    "tag": "docker.{{.Name}}"
  }
}
```

Per-host CPU: ~5-10% (for 5-10 containers)
Pros: Centralized config, less per-container overhead
Cons: If log driver fails, logs are lost

**Option B: Sidecar container (Kubernetes-style)**
```yaml
services:
  app:
    image: myapp
    volumes:
      - /var/log/app:/logs  # App writes to file

  filebeat:
    image: elastic/filebeat
    volumes:
      - /var/log/app:/logs:ro
    config:
      filebeat.inputs:
        - type: log
          enabled: true
          paths:
            - /logs/*.log
```

Pros: Failed collector doesn't lose logs (files persist)
Cons: Overhead (extra container per app)

**Recommendation**: Host-based for Docker, sidecar for Kubernetes

**2. Message Broker for Buffering**

Use Kafka for reliability and high throughput:

```bash
# Scale: 50+ hosts × 100MB/s logs = 5GB/s peak
# Single Elasticsearch node can't keep up
# Kafka decouples collection from storage

docker-compose:
  kafka:
    image: confluentinc/cp-kafka:latest
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 3
      KAFKA_LOG_RETENTION_HOURS: 24  # Keep 1 day of raw logs
      KAFKA_NUM_PARTITIONS: 12
      KAFKA_DEFAULT_REPLICATION_FACTOR: 3
```

**3. Storage Choice: Loki vs Elasticsearch**

**Loki** (Logs as time series):
- Cost: 10-100× cheaper than Elasticsearch
- Storage: $1-5/GB/month (vs $50+/GB for ES)
- Retention: Practical for 30-90 days
- Search: Label-based, not full-text
- Good for: Debugging specific services, correlation

```yaml
loki:
  auth_enabled: false
  ingester:
    max_chunk_age: 1h
    max_chunk_idle_period: 30m
  limits_config:
    enforce_metric_name: false
    reject_old_samples: true
    retention_period: 30d  # 30 days retention
  storage_config:
    filesystem:
      directory: /loki/chunks
```

**Elasticsearch** (Full-text search):
- Cost: Higher ($50+/GB/month)
- Storage: Expensive but queryable
- Retention: Practical for 7-30 days
- Search: Full-text, complex queries
- Good for: Compliance audits, forensics, complex analysis

```yaml
elasticsearch:
  environment:
    - discovery.type=single-node
    - xpack.security.enabled=false
  index lifecycle management:
    - rollover: { max_age: "1d", max_size: "50GB" }
    - delete: { min_age: "30d" }
```

**Recommendation**: Loki for primary logging, Elasticsearch for compliance

**4. Collection Configuration**

```yaml
# Fluentd configuration (Centralized config)
<source>
  @type forward
  port 24224
  bind 0.0.0.0
</source>

# Parse JSON logs
<filter docker.>
  @type parser
  key_name log
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
  emit_invalid_records false
</filter>

# Add metadata
<filter docker.>
  @type record_modifier
  <replace>
    key hostname
    expression ${Socket.gethostname}
  </replace>
  <replace>
    key environment
    expression ${ENV['ENVIRONMENT']}
  </replace>
</filter>

# Kafka sink for buffering
<match docker.>
  @type kafka2
  brokers kafka:9092
  topics logs_raw
  <format>
    @type json
  </format>
  <buffer topic>
    @type file
    path /fluentd/buffer/kafka
    flush_interval 10s
    flush_mode interval
    chunk_limit_size 5M
    queue_limit_length 256
  </buffer>
</match>
```

**5. Forwarding from Kafka to Storage**

```python
# Kafka consumer → Loki/Elasticsearch
import json
from kafka import KafkaConsumer
import requests

consumer = KafkaConsumer(
    'logs_raw',
    bootstrap_servers=['kafka:9092'],
    group_id='loki-loader',
    auto_offset_reset='earliest'
)

for message in consumer:
    log_entry = json.loads(message.value)
    
    # Enrich with metadata
    log_entry['@timestamp'] = log_entry['time']
    log_entry['service'] = log_entry['docker']:
```

**6. Scalability Strategy**

**Tier 1: Real-time analysis** (Loki + Grafana)
- Retention: 7 days
- Cost: $500/month
- Use: Active debugging, monitoring

**Tier 2: Medium-term storage** (Elasticsearch)
- Retention: 30 days
- Cost: $2000/month
- Use: Investigation, correlation

**Tier 3: Long-term archive** (S3)
- Retention: 2 years
- Cost: $100/month
- Use: Compliance, audit trails

```bash
# Export logs daily to S3
# Query using Athena when needed (on-demand)
```

**7. Searching and Visualization**

```grafana
# Real-time dashboard
SELECT sum(bytes) BY (service)
WHERE environment="production" AND level="error"
  OVER (5m)

# Service error rate
SELECT rate(errors[5m]) BY (service)

# Trace cross-service failures
SELECT * FROM logs
WHERE trace_id="xyz-123"
  ORDER BY timestamp ASC
```

**8. Cost Optimization**

```
Scenario: 50 containers × 10MB/s (average)
         × 86400 seconds/day = 43.2TB/day

Daily Cost Breakdown:
- Loki (7d retention): $30/day
- Kafka (1d buffer): $5/day
- Elasticsearch (30d): $50/day
- S3 Archive: $1/day
Total: ~$2000/month

Optimization opportunities:
1. Log sampling: Only send 10% of DEBUG level (~10% savings)
2. Aggregation: Pre-aggregate metrics at host level (~15% savings)
3. Compression: gzip before sending (~40% compression)
4. Tiered storage: Hot/warm/cold Elasticsearch nodes
```

**9. Monitoring the Logging System Itself**

```prometheus
# Alerts for logging infrastructure
- alert: KafkaHighLatency
  expr: kafka_producer_record_send_time_ms > 1000
  for: 5m

- alert: ElasticsearchQueueBacklog
  expr: bulk_queue_size > 10000
  for: 10m

- alert: FluentdBufferFull
  expr: fluentd_buffer_queue_length > 256
  for: 2m
```

**10. Complete Docker Compose Stack**

```yaml
version: '3.9'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"

  fluentd:
    image: fluent/fluentd:v1.16
    volumes:
      - ./fluent.conf:/fluentd/etc/fluent.conf
      - fluentd-buffer:/fluentd/log
    depends_on:
      - kafka

  loki:
    image: grafana/loki:latest
    volumes:
      - loki-data:/loki
      - ./loki-config.yml:/etc/loki/local-config.yaml

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
    environment:
      - discovery.type=single-node
    volumes:
      - es-data:/usr/share/elasticsearch/data

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    depends_on:
      - loki
      - elasticsearch

volumes:
  fluentd-buffer:
  loki-data:
  es-data:
```

**Best Practices**:
1. ✅ Logs as structured data (JSON)
2. ✅ Unique trace IDs (correlation)
3. ✅ Multiple retention tiers (cost optimization)
4. ✅ Circuit breaker (logging failures don't crash app)
5. ✅ Sampling (reduce volume without losing insight)
6. ✅ Monitoring the monitoring system
7. ✅ Regular cost audits"

---

### 9. **You're tasked with migrating a 50-container monolithic Docker Compose environment to Kubernetes. What's your strategy and what are the main challenges?**

**Expected Answer**:

"This is a complex migration. Here's my phased approach:

**Phase 0: Assessment (2 weeks)**

```bash
# 1. Inventory current state
docker-compose ps  # Count services
docker-compose exec <service> env | grep -i "config\|secret\|url"
# Document all environment variables, volumes, mounts

# 2. Analyze dependencies
docker-compose config | yq '.services | keys'  # Service list

# 3. Identify migration blockers
# - Persistent volumes (stateful services)
# - Hardcoded IPs/hostnames
# - Docker Compose features not in K8s
# - Logging infrastructure
# - Secret management approach
```

**Challenge 1: Stateful Services**

Current Docker Compose setup:
```yaml
services:
  postgres:
    image: postgres:15
    volumes:
      - pgdata:/var/lib/postgresql/data
```

In Kubernetes:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pg-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi

---
apiVersion: apps/v1
kind: StatefulSet  # NOT Deployment for stateful services
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:15
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 100Gi
```

**Challenge 2: Network Interdependencies**

Docker Compose: Service name = DNS hostname automatically
```yaml
services:
  api:
    environment:
      DATABASE_URL: postgres://postgres:5432  # Automatic DNS
```

Kubernetes: Requires explicit Service objects
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

**Challenge 3: Secrets Management**

Docker Compose (development):
```bash
# .env file (NEVER in git)
DB_PASSWORD=mypassword
API_KEY=abc123
```

Kubernetes (production):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  db-password: bXlwYXNzd29yZA==  # base64 encoded
  api-key: YWJjMTIz
```

Requires external secret manager for production (Vault, AWS Secrets Manager):
```bash
# Sealed Secrets (encrypted secrets in git)
kubectl apply -f sealed-secret.yaml

# Vault Agent Injector (dynamic secret injection)
kubectl apply -f pod-with-vault-annotation.yaml
```

**Phase 1: Containerization Assessment (1 week)**

For each service:
```
┌─────────────────────────────────────┐
│ Service: API                        │
├─────────────────────────────────────┤
│ Type: Stateless (web application)   │
│ Current limits: --cpus 2 --memory 1g│
│ Dependencies: postgres, redis       │
│ Ports exposed: 8000                 │
│ Volumes: ./code:/app (bind mount)   │
│ Health check: GET /health           │
│ Scale target: 3-10 replicas         │
└─────────────────────────────────────┘
```

Document for each service:
- Stateless vs stateful
- Resource limits/requests
- Dependencies (explicit depends_on)
- Required volumes
- Environment configuration
- Secrets
- Health checks
- Expected replica count

**Phase 2: Create Kubernetes Manifests (2-3 weeks)**

```bash
# Option A: Manual conversion (full control)
# Create one YAML per service type

# Option B: Automated conversion (faster)
kompose convert -f docker-compose.yml  # Tool to auto-convert
# Results in K8s manifests (imperfect but starting point)

# Option C: Helm Charts (production-grade)
helm create myapp  # Templated deployment
# Edit values.yaml per environment
```

**Phase 3: Kubernetes Cluster Setup (1 week)**

```bash
# Create dev K8s cluster
minikube start  # Local development

# Or cloud-managed:
# Azure: az aks create
# AWS: eksctl create cluster
# GCP: gke-gcloud-auth cluster-create

# Install essential components
kubectl apply -f https://raw.githubusercontent.com/kubernetes/metrics-server/master/deploy/components.yaml  # Metrics
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack  # Monitoring
```

**Phase 4: Incremental Migration Strategy**

**Option A: "Strangler Pattern" (Recommended)**

Keep Docker Compose, gradually move services to K8s:

```
T0: All 50 services in Docker Compose
T1: Move 5 services to K8s (stateless first)
    Route traffic: 80% Compose, 20% K8s
T2: Move 15 services to K8s
    Route traffic: 60% Compose, 40% K8s
T3: Move remaining services
    Route traffic: 0% Compose, 100% K8s
```

Benefits:
- Low risk (reverting is easy)
- Can validate K8s approach
- Team learns gradually
- Parallel support of both platforms temporarily

**Option B: "Big Bang" (Only for small setups)**

Migrate everything at once. High risk, fast execution.

**I'd choose Strangler Pattern.**

**Phase 5: Manifest Organization**

```
k8s/
├── base/
│   ├── postgres/
│   │   ├── statefulset.yaml
│   │   ├── service.yaml
│   │   ├── pvc.yaml
│   │   └── configmap.yaml
│   ├── api/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── hpa.yaml
│   │   └── ingress.yaml
│   └── redis/
│
├── overlays/
│   ├── development/
│   │   ├── kustomization.yaml
│   │   ├── replicas-patch.yaml
│   │   └── resource-limits-patch.yaml
│   ├── staging/
│   └── production/
│       ├── kustomization.yaml
│       ├── replicas-patch.yaml
│       └── ingress-patch.yaml
│
└── helmchart/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   └── ingress.yaml
    └── values-prod.yaml
```

**Phase 6: Testing Strategy**

```bash
# 1. Unit tests (K8s manifests)
kubeval k8s/**/*.yaml  # Syntax validation
helm lint helmchart/

# 2. Integration tests (K8s cluster)
kubectl apply -f k8s/base/
kubectl get pods  # All running?
kubectl logs -l app=api  # Check startup logs

# 3. Functional tests
./run-e2e-tests.sh  # Hit K8s ingress, verify responses
# Same tests that ran against Docker Compose

# 4. Load tests
ab -n 10000 -c 100 http://k8s-ingress.example.com/
# Compare response times vs Docker Compose
```

**Phase 7: Logging and Monitoring**

**Docker Compose logging**:
```yaml
logging:
  driver: fluentd
  options:
    fluentd-address: fluentd:24224
```

**Kubernetes logging**:
```yaml
# Fluentd DaemonSet (one per node)
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  template:
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
```

**Challenges overcome**:

| Challenge | Docker Compose Solution | K8s Solution |
|-----------|------------------------|--------------|
| Service discovery | DNS by name | K8s Service object |
| Configuration | .env files | ConfigMap/Secret |
| Persistent data | Named volume | PVC + StatefulSet |
| Scaling | --scale replica=5 | HPA (CPU-based) |
| Logging | Log driver | DaemonSet collector |
| Health checks | HEALTHCHECK | Liveness/Readiness probes |
| Resource limits | --memory/--cpus | requests/limits in spec |
| Updates | Manual restart | Rolling deployment |

**Major Challenges Remaining**:

1. **Complexity increase**: K8s is 100× more complex
   - Solution: Helm charts to abstract complexity
   - Solution: Teaching team gradually

2. **Cost increase**: More resources needed
   - Docker Compose: Single-node, $500/month
   - K8s: Multi-node HA, $5000+/month
   - Needs justification (reliability, scalability)

3. **Debugging difficulty**: Harder in K8s
   - Solution: Prometheus + Grafana
   - Solution: ELK/Loki for centralized logs
   - Solution: Kube kubeseal + Vault for secrets

4. **Team expertise**: Most teams new to K8s
   - Solution: Kubernetes training
   - Solution: Managed K8s (AKS, EKS) to reduce ops burden
   - Solution: Platform team to abstract complexity

**Migration Timeline**: 8-12 weeks for 50 containers

Week 1-2: Assessment
Week 3-4: K8s setup + manifests
Week 5-6: Strangler pattern (services 1-5 migrate)
Week 7-8: Services 6-15 migrate
Week 9-10: Services 16+ migrate
Week 11-12: Testing, validation, Docker Compose cleanup

**Success Criteria**:
- ✅ All services running on K8s
- ✅ Zero data loss during migration
- ✅ Performance equivalent or better
- ✅ Logging and monitoring equivalent
- ✅ Team trained on K8s
- ✅ Docker Compose environment retired"

---

### 10. **Walk through configuring a production-grade multi-environment deployment strategy (dev, staging, prod) with proper secret management and rollout controls.**

**Expected Answer**:

"A robust multi-environment strategy requires careful consideration of isolation, secrets, and deployment controls. Here's my comprehensive approach:

**Environment Architecture**:

```
┌──────────────────────────────────────────────────────────┐
│ Development Environment (Local)                          │
│ - docker-compose                                         │
│ - .env files (git-ignored)                              │
│ - No encryption (convenience prioritized)                │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Staging Environment (Full production replica)            │
│ - Kubernetes cluster                                     │
│ - Staging namespace isolation                           │
│ - Sealed Secrets (encrypted in git)                     │
│ - Same resource limits as production                     │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ Production Environment (High availability)               │
│ - Kubernetes cluster (separate from staging)             │
│ - Restricted RBAC                                        │
│ - HashiCorp Vault (external secret manager)             │
│ - Audit logging (all deployments logged)                │
│ - Blue-green or canary deployments                      │
└──────────────────────────────────────────────────────────┘
```

**Phase 1: Environment Configuration Hierarchy**

```
# Base values (shared)
├── values-base.yaml
│   ├── replicas: 1
│   ├── image.registry: myregistry.azurecr.io
│   ├── image.repository: myapp
│
├── values-dev.yaml (inherits base)
│   ├── replicas: 1
│   ├── resoureces.limits.memory: 512Mi
│   ├── ingress.enabled: false
│   ├── secrets.source: file  # .env
│
├── values-staging.yaml (inherits base)
│   ├── replicas: 2
│   ├── resources.limits.memory: 2Gi
│   ├── ingress.enabled: true
│   ├── secrets.source: sealed-secrets
│   ├── monitoring.enabled: true
│
└── values-prod.yaml (inherits base)
    ├── replicas: 5
    ├── resources.limits.memory: 4Gi
    ├── autoscaling.enabled: true
    ├── ingress.enabled: true
    ├── secrets.source: vault
    ├── audit.enabled: true
    └── backup.enabled: true
```

**Development Environment Setup**:

```yaml
# docker-compose.yml
version: '3.9'

services:
  app:
    image: myapp:latest
    build:
      context: .
      dockerfile: Dockerfile
    env_file: .env.local
    environment:
      ENVIRONMENT: development
      LOG_LEVEL: debug
      DEBUG: "true"
    ports:
      - "8000:8000"
    volumes:
      - ./src:/app/src  # Live reload
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 10s
```

```bash
# .env.local (NEVER commit)
DATABASE_URL=postgres://postgres:password@localhost:5432/myapp
REDIS_URL=redis://localhost:6379
API_KEY=dev-key-only-for-testing
ENVIRONMENT=development
```

**Staging Environment Setup with Sealed Secrets**:

```bash
# 1. Install Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml -n kube-system

# 2. Create a secret locally
kubectl create secret generic app-secrets \
  --from-literal=database-url=postgres://user:password@postgres-staging:5432/myapp \
  --from-literal=api-key=staging-api-key-xyz \
  --from-literal=jwt-secret=staging-jwt-secret \
  --dry-run=client -o yaml > secret.yaml

# 3. Encrypt it with public sealing key
kubeseal -f secret.yaml -w sealed-secret.yaml

# 4. Commit encrypted secret to git
git add sealed-secret.yaml
git commit -m "Update staging secrets"

# 5. Controller automatically decrypts at runtime
kubectl apply -f sealed-secret.yaml
```

**Sealed Secret YAML**:

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: app-secrets
  namespace: staging
spec:
  template:
    metadata:
      name: app-secrets
      namespace: staging
    type: Opaque
  encryptedData:
    api-key: AgBwQ3F...  # Encrypted, safe in git
    database-url: AgDxK2P...
    jwt-secret: AgEfR4M...
  sealing:
    clusterRole: sealed-secrets-key-admin
```

**Production Environment with HashiCorp Vault**:

```bash
# 1. Install Vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  -f vault-values.yaml

# 2. Configure Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
  kubernetes_host=$KUBERNETES_HOST \
  kubernetes_ca_cert=$KUBERNETES_CA_CERT \
  token_reviewer_jwt=$TOKEN_REVIEWER_JWT

# 3. Create policies for each service
vault policy write myapp-policy - <<EOF
path "secret/data/prod/myapp/*" {
  capabilities = ["read", "list"]
}
EOF

# 4. Create Kubernetes role
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=production \
  policies=myapp-policy \
  ttl=24h
```

**Production Deployment with Vault Integration**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 5
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "myapp"
        vault.hashicorp.com/agent-inject-secret-app-config: "secret/data/prod/myapp/config"
        vault.hashicorp.com/agent-inject-template-app-config: |
          {{- with secret "secret/data/prod/myapp/config" -}}
          export DATABASE_URL="{{ .Data.data.database_url }}"
          export API_KEY="{{ .Data.data.api_key }}"
          export JWT_SECRET="{{ .Data.data.jwt_secret }}"
          {{- end }}
    spec:
      serviceAccountName: myapp
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:1.2.0
        ports:
        - containerPort: 8000
        
        # Vault agent injects secrets as files
        volumeMounts:
        - name: vault-token
          mountPath: /vault/secrets
        
        # Application reads from mounted files
        env:
        - name: DATABASE_URL_FILE
          value: /vault/secrets/app-config
        
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 15
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5

      volumes:
      - name: vault-token
        emptyDir:
          medium: Memory

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
```

**Phase 2: Deployment Orchestration**

**Development** (Lightweight):
```bash
# CI/CD: Simple trigger
docker-compose down && docker-compose up -d
```

**Staging** (Rolling update with testing):
```bash
# Deployment strategy
apiVersion: apps/v1
kind: Deployment
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: myapp
        image: myregistry.azurecr.io/myapp:${VERSION}
```

```bash
# Deployment steps
1. Create new pods (maxSurge: 1)
2. Wait for readiness probe
3. Run smoke tests
4. Proceed to next pod
5. All pods updated successfully

# If tests fail: automatic rollback
kubectl rollout undo deployment/myapp -n staging
```

**Production** (Canary deployment):

```bash
#!/bin/bash
# canary-deploy.sh

set -e

NEW_VERSION=$1
CANARY_PERCENTAGE=10  # Start with 10% traffic

echo "Deploying canary: $NEW_VERSION (${CANARY_PERCENTAGE}% traffic)"

# 1. Update Argo Rollouts with new version
argoctl config set image myapp=myregistry/myapp:${NEW_VERSION} -n production

# 2. Argo manages traffic shift: 10% → new, 90% → old
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  strategy:
    canary:
      steps:
      - setWeight: 10  # 10% traffic to new
      - pause: { duration: 10m }  # Monitor for 10 min
      - setWeight: 50  # 50% traffic
      - pause: { duration: 10m }
      - setWeight: 100  # All traffic
EOF

# 3. Monitor metrics during rollout
watch -n 5 'kubectl get rollout myapp -o jsonpath={.status.canaryWeight}'

# 4. Rollout automatic promotion if healthy
# If errors spike: automatic rollback
```

**Phase 3: Secret Rotation Strategy**

```bash
# Automated secret rotation (scheduled)
# CronJob in production

apiVersion: batch/v1
kind: CronJob
metadata:
  name: rotate-secrets
spec:
  schedule: "0 2 * * 0"  # Every Sunday 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: rotate
            image: vault:latest
            command:
            - /bin/sh
            - -c
            - |
              vault login -method=kubernetes role=rotate-role
              
              # Rotate API KEY
              NEW_KEY=$(openssl rand -hex 32)
              vault kv put secret/prod/myapp/config \
                api_key=$NEW_KEY \
                database_url=$DB_URL
              
              # Trigger pod restart to pick up new secret
              kubectl rollout restart deployment/myapp -n production
```

**Phase 4: Access Control & Audit**

**RBAC for each environment**:

```yaml
# Development: Open access (team can deploy)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-developer
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: edit  # Can create/update/delete
subjects:
- kind: User
  name: developer@company.com

---
# Production: Restricted access (only CI/CD, approved humans)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prod-deployer
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view  # Read-only
subjects:
- kind: ServiceAccount
  name: ci-cd-service-account

---
# Secret access restricted
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: vault-admin
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "create", "update"]
  resourceNames: ["app-secrets"]  # Only specific secret
```

**Audit logging** (who deployed what, when):

```bash
# Audit log of all API calls
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  verbs: ["create", "update", "patch", "delete"]
  resources: ["deployments", "secrets"]
  namespaces: ["production"]
  omitStages:
  - RequestReceived
```

**Phase 5: Promotion Pipeline**

```
┌─────────────────┐
│ Code Push (git) │
└────────┬────────┘
         │
         ↓
┌─────────────────────────────┐
│ 1. Build & Test             │
│ - Run unit tests            │
│ - Build Docker image        │
│ - Scan for vulnerabilities  │
│ - Push to registry          │
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│ 2. Dev Deployment           │
│ - Auto-deploy on PR         │
│ - Manual approval: none     │
│ - Health checks: basic      │
└────────┬────────────────────┘
         │
         ↓ (Merge to main)
┌─────────────────────────────┐
│ 3. Staging Deployment       │
│ - Rolling update            │
│ - Manual approval: none     │
│ - Health checks: complete   │
│ - E2E tests run             │
└────────┬────────────────────┘
         │
         ↓ (Release tag)
┌─────────────────────────────┐
│ 4. Production Deployment    │
│ - Canary (10% traffic)      │
│ - Manual approval: required │
│ - Health checks: strict     │
│ - Monitoring: enabled       │
│ - Auto-rollback on failure  │
└─────────────────────────────┘
```

**Deployment YAML** (GitOps):

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-prod
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/company/myapp-helm
    targetRevision: main
    path: helm/myapp
    helm:
      valueFiles:
      - values-prod.yaml
      parameters:
      - name: image.tag
        value: v1.2.0  # From release tag
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
  
  # Require manual approval before sync
  revisionHistoryLimit: 10
```

**Best Practices Summary**:

1. ✅ **Secrets by environment**:
   - Dev: .env files (convenience)
   - Staging: Sealed Secrets (encrypted in git)
   - Prod: External Vault (rotation, audit)

2. ✅ **Deployment strategies**:
   - Dev: Immediate (fast feedback)
   - Staging: Rolling (quick iteration)
   - Prod: Canary (safety first)

3. ✅ **Access control**:
   - Dev: Open (developers empowered)
   - Staging: Gated (review required)
   - Prod: Restricted (least privilege)

4. ✅ **Monitoring & Audit**:
   - All deployments logged
   - Automatic rollback on failure
   - Health checks increasing in rigor

5. ✅ **Promotion path**:
   - Code → Dev → Staging → Prod
   - Same binary tested in each environment
   - Configuration differs, not code"

---

**End of Interview Questions Section**

---

## Document Index & References

**Completed Sections**:
1. ✅ Table of Contents
2. ✅ Introduction
3. ✅ Foundational Concepts
4. ✅ Resource Management (CPU, Memory, Block IO, PIDs, Device Access, Swap)
5. ✅ Environment Management (Variables, .env, Configs, Secrets, Build Args)
6. ✅ Docker Compose (Architecture, YAML Structure, Services, Networks, Volumes, Scaling)
7. ✅ Logging & Monitoring (Log drivers, Centralized logging, Metrics, Health checks, Alerting)
8. ✅ Hands-on Scenarios (4 realistic DevOps scenarios with step-by-step solutions)
9. ✅ Interview Questions (10 detailed senior-level interview questions with comprehensive answers)

**Study Guide Completion Status**: 100% COMPLETE

All sections have been generated with:
- Comprehensive explanations
- Real-world examples and code samples
- Production-grade best practices
- Architecture diagrams and decision trees
- Hands-on scenarios with troubleshooting
- Interview questions with senior engineer perspective

**Total Content**: ~28,000 words of expert-level Docker/DevOps material
**Target Audience**: Senior DevOps Engineers (5-10+ years experience)
**Date Generated**: March 7, 2026

---

**Study Guide File Location**:
[7_Docker-Resource-Environment-Compose-Monitoring-Study-Guide-2026-03-07.md](07-docker/7_Docker-Resource-Environment-Compose-Monitoring-Study-Guide-2026-03-07.md)


---

## Document Index & References

**Next Sections To Be Generated**:
- Hands-on Scenarios (Section 7)
- Interview Questions & Expected Answers (Section 8)

**Study Guide Version**: 2026-03-07  
**Target Audience**: Senior DevOps Engineers (5-10+ years)  
**Status**: Sections 1-6 Complete (Table of Contents, Introduction, Foundational Concepts, all four subtopics)
