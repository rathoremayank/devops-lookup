# Docker Architecture: Senior DevOps Study Guide

**Target Audience:** DevOps Engineers (5–10+ years experience)  
**Last Updated:** March 7, 2026  
**Scope:** Docker Engine Components - Daemon, Client, Container Runtime, containerd, runc, Docker API, CLI

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Architecture Overview](#architecture-overview)
   - [Docker Engine Components](#docker-engine-components)
   - [Container Runtime Standards](#container-runtime-standards)
   - [Communication Protocols](#communication-protocols)
   - [DevOps Principles & Best Practices](#devops-principles--best-practices)
   - [Common Misconceptions](#common-misconceptions)
3. [Docker Engine Components](#docker-engine-components-detailed)
   - [Docker Daemon](#docker-daemon)
   - [Docker Client](#docker-client)
   - [Docker API](#docker-api)
   - [Container Runtime](#container-runtime)
   - [containerd](#containerd)
   - [runc](#runc)
   - [Docker CLI](#docker-cli)
4. [Hands-on Scenarios](#hands-on-scenarios)
5. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Docker Architecture represents the foundational design and operational model that powers containerization at enterprise scale. Unlike simplistic views of Docker as merely a "lightweight VM," the actual architecture is a sophisticated, modular system that separates concerns across multiple layers:

- **Client-side tooling** (CLI, SDKs)
- **Daemon orchestration** (Docker Daemon)
- **API abstraction** (RESTful interfaces, gRPC)
- **Container runtime abstraction** (containerd, runc)
- **Linux kernel integration** (Namespaces, cgroups)

This architecture emerged from lessons learned in production container deployments and reflects the industry's move toward standardization (OCI - Open Container Initiative) and decoupling of responsibility.

### Why It Matters in Modern DevOps Platforms

1. **Production Containerization at Scale**
   - Understanding Docker architecture is essential for debugging production incidents
   - Design patterns for high-availability container deployments depend on architectural knowledge
   - Performance optimization requires deep understanding of daemon behavior, resource constraints, and runtime efficiency

2. **Multi-Orchestrator Ecosystems**
   - Kubernetes, Docker Swarm, and other orchestrators leverage the same container runtime standards
   - Docker daemon architecture knowledge directly transfers to managing containerized workloads across platforms
   - The decoupling of runtime (containerd/runc) enables flexible deployment strategies

3. **Security & Compliance**
   - Container isolation mechanisms depend on understanding daemon-to-kernel interactions
   - Security policies (AppArmor, SELinux) operate at layers only visible through architectural knowledge
   - Registry vulnerabilities, image scanning, and supply chain security require understanding the full stack

4. **Operational Reliability**
   - Real-world incidents (storage driver failures, daemon crashes, resource leaks) require architectural understanding to troubleshoot
   - CI/CD pipeline optimization depends on understanding daemon performance characteristics
   - Multi-tenant environments require knowledge of resource isolation and limit enforcement

### Real-World Production Use Cases

**Case 1: Microservices at Scale (E-commerce Platform)**
- Deploying 500+ containers across 50 hosts
- **Challenge:** Daemon crashes causing cascading failures
- **Solution:** Understanding daemon rebuild processes, persistent storage layer separation, and health monitoring
- **Architectural Dependency:** Knowledge of daemon state management and container runtime independence

**Case 2: Hybrid Cloud DevOps (Insurance Sector)**
- Container workloads across on-premises Docker hosts and cloud providers
- **Challenge:** Inconsistent daemon versions causing compatibility issues
- **Solution:** Standardizing daemon versions, understanding upgrade procedures, and validating runtime compatibility
- **Architectural Dependency:** Knowing which components are version-locked and which support independent updates

**Case 3: Security-Critical Applications (Financial Services)**
- Containers processing sensitive data with strict compliance requirements
- **Challenge:** Proving isolation guarantees and audit capabilities
- **Solution:** Understanding containerd security features, kernel integration points, and audit logging
- **Architectural Dependency:** Deep knowledge of namespace isolation and cgroup enforcement

**Case 4: CI/CD Pipeline Optimization (SaaS Company)**
- Building 1000s of images daily, pushing to registries
- **Challenge:** Docker daemon becoming resource bottleneck
- **Solution:** Tuning storage drivers, implementing buildkit, understanding layer caching architecture
- **Architectural Dependency:** Knowledge of daemon resource management and image layer design

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│              (Kubernetes Deployments, Services)              │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│              Container Orchestration Layer                   │
│         (kubelet → Docker API, Container Runtime)           │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                  Docker Architecture                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Client Layer (CLI, SDK, Registry Clients)           │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
│  ┌──────────────▼───────────────────────────────────────┐   │
│  │  Docker API Layer (REST, gRPC)                       │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
│  ┌──────────────▼───────────────────────────────────────┐   │
│  │  Docker Daemon (Engine, Storage, Networking)         │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
│  ┌──────────────▼───────────────────────────────────────┐   │
│  │  Container Runtime (containerd)                      │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                             │
│  ┌──────────────▼───────────────────────────────────────┐   │
│  │  Low-Level Runtime (runc)                            │   │
│  └──────────────┬───────────────────────────────────────┘   │
└────────────────────┬─────────────────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────────────────┐
│              Linux Kernel Layer                               │
│   (Namespaces, cgroups, overlay filesystems, netlink)        │
└─────────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Architecture Overview

Docker's architecture is fundamentally a **separation of concerns** model, where responsibility is divided across multiple abstraction layers:

1. **User-Facing Layer:** Docker Client (CLI) and SDKs
2. **API/Middleware Layer:** Docker API (REST/gRPC) and Docker Daemon
3. **Container Runtime Layer:** containerd (container lifecycle management)
4. **Low-Level Runtime Layer:** runc (OCI container execution)
5. **Kernel Layer:** Linux namespaces, cgroups, and filesystems

This layered approach provides:
- **Modularity:** Runtime changes don't require daemon rebuild
- **Scalability:** Standardized OCI images work across platforms
- **Resilience:** Daemon crashes don't necessarily kill running containers
- **Industry Standardization:** OCI specifications enable multi-runtime support

### Docker Engine Components

#### Component Interaction Matrix
```
┌─────────────────┬──────────────┬─────────────────────────┬──────────────┐
│ Component       │ Responsibility                         │ Restartable? │
├─────────────────┼──────────────────────────────────────┼──────────────┤
│ Docker Daemon   │ Image management, networking, volumes │ YES*         │
│ containerd      │ Container lifecycle, task management  │ YES          │
│ runc            │ Container execution (spawning)        │ NO (instant) │
│ Docker Client   │ User command parsing, API calls       │ N/A          │
│ Docker API      │ REST/gRPC interface                   │ Via daemon   │
└─────────────────┴──────────────────────────────────────┴──────────────┘
* With connection to running containers preserved (shim pattern)
```

#### Dependencies & Lifecycle
- **Daemon depends on:** Host OS, kernel features
- **containerd depends on:** Daemon for task scheduling (can survive daemon restart)
- **runc depends on:** Linux kernel, proper host setup
- **Client depends on:** Daemon API (can work offline for some operations)

### Container Runtime Standards

#### OCI (Open Container Initiative) Standards

Docker's architecture strictly adheres to OCI standards, which define:

1. **OCI Image Specification**
   - Standard for container images (layers, configuration, manifests)
   - Enables image portability across runtimes (Docker, Podman, containerd directly)
   - Versioning: Imagespec v1.0.2, with ongoing refinements

2. **OCI Runtime Specification**
   - Standard for container runtime execution
   - Defines `runtime.json` bundle format and lifecycle operations
   - Enables runc, kata-containers, crun, and other runtimes to be interchangeable

3. **OCI Distribution Specification**
   - Standard for pushing/pulling images to registries
   - Enables multi-registry strategies and private registry deployments
   - Defines authentication and versioning protocols

**Impact on Architecture:**
- You can replace `runc` with `crun` (faster, more resource-efficient) without changing daemon or containerd
- Images from `docker build` work identically on `podman`, `nerdctl`, or Kubernetes
- Distribution layer is standardized, reducing vendor lock-in

### Communication Protocols

Docker architecture uses multiple communication mechanisms:

#### 1. Docker API (Primary Communication Path)
```
Client Command: docker run -d nginx
    │
    ├─→ Socket Connection (Unix socket or TCP)
    │   Default: /var/run/docker.sock (Unix)
    │   Alternative: tcp://localhost:2375 (insecure), tcp://localhost:2376 (TLS)
    │
    ├─→ Docker Daemon / API Server
    │   Request parsing, validation, authentication
    │
    ├─→ containerd API (gRPC)
    │   Create container, setup networking, mount filesystems
    │
    ├─→ runc (via shim)
    │   Execute the process
    │
    └─→ Response back to client
```

#### 2. Socket Types & Implications

| Socket Type | Use Case | Security | Performance |
|-------------|----------|----------|-------------|
| Unix socket (`/var/run/docker.sock`) | Local daemon access, Kubernetes nodes | File permissions | Fastest, no network overhead |
| TCP (port 2375) | Remote access, legacy | NO ENCRYPTION (deprecated) | Network overhead |
| TLS TCP (port 2376) | Remote access, production | TLS certs required | Network overhead + TLS overhead |
| systemd socket activation | Service startup | Integration with systemd | Efficient resource usage |

**Senior DevOps Consideration:** Running Docker daemon with remote TCP access without TLS is a critical security vulnerability equivalent to exposing SSH with no authentication.

#### 3. containerd Communication
- containerd uses **gRPC** for daemon communication
- Event stream for monitoring container lifecycle
- Separate namespace support for multi-tenancy
- Shim process maintains connection to containers independently

### DevOps Principles & Best Practices

#### 1. Separation of Concerns
- **Principle Applied:** Docker daemon handles orchestration/networking, runc handles execution
- **Benefit:** Daemon restart doesn't terminate running containers
- **Implication:** Upgrade daemon independently of running workloads

#### 2. Declarative Configuration
- **All Docker state derivable from:** Images, volumes, network config, daemon settings
- **No imperative-only state:** (Everything is codifiable)
- **DevOps Implication:** Infrastructure-as-Code for container deployments

#### 3. Immutable Infrastructure
- **Containers are:** Built once, deployed multiple times
- **Configuration:** Via environment variables, config files, not runtime modification
- **DevOps Practice:** Rebuild image rather than patch running container

#### 4. Health Observability
- **Container health:** Distinct from process health (requires explicit health checks)
- **Daemon health:** Monitor via `/var/run/docker.sock` responsiveness
- **Best Practice:** Implement health checks in Dockerfile and monitoring systems

#### 5. Resource Governance
- **cgroup v1 vs v2:** Significant implications for resource accounting
- **Daemon OOM:** Prioritize daemon protection; set memory limits on containers, not daemon
- **Swappiness:** Disable swap in production for predictable container behavior

### Common Misconceptions

#### Misconception 1: "Docker containers run 'on the daemon'"
**Reality:** The daemon doesn't run containers. It orchestrates them. Containers run via runc, managed by containerd, coordinated by the daemon. The daemon could crash and containers continue running (verified by shim process).

**Implication:** `docker ps` failing ≠ containers not running. They're still alive; you just can't query them.

#### Misconception 2: "Docker is the container runtime"
**Reality:** Docker is the **orchestration platform**. The container runtime is containerd (or alternative). runc is the **low-level runtime**. Docker uses them.

**Implication:** You can use containerd without Docker. You can run OCI bundles directly with runc. Each layer is independently replaceable.

#### Misconception 3: "Restarting the Docker daemon loses all running containers"
**Reality:** Daemon restart gracefully reconnects to running containers via shims. Container state persists (with caveats around networking and mounted volumes).

**Exception:** Networking state may be inconsistent if volumes were unmounted during the restart window.

#### Misconception 4: "Container resources are limited by daemon's resources"
**Reality:** Container limits are enforced by kernel cgroups, independent of daemon capacity. Daemon processes use separate cgroups.

**Reality Check:** A container using 4GB can run on a daemon using 500MB (separate cgroup trees).

#### Misconception 5: "Docker images are monolithic"
**Reality:** Images are layered (each from-to layer) and distributed as manifests pointing to layers. You can pull only specific layers (though docker client always pulls full images for practical compatibility).

**Advanced:** Buildkit and layer caching enable 10x+ faster builds through layer reuse.

---

## Docker Engine Components (Detailed)

### Docker Daemon

#### Definition & Role
The **Docker Daemon** (dockerd) is a persistent background process that:
- Listens on sockets for API requests
- Manages container lifecycle events
- Handles image storage and distribution
- Orchestrates networking and volume management
- Exposes metrics and health information

#### Lifecycle Management
```
dockerd startup sequence:
1. Load configuration (/etc/docker/daemon.json)
2. Initialize storage driver (overlay2, devicemapper, etc.)
3. Discover existing containers from storage
4. Reconnect to running containers via shims
5. Restore networking (bridge networks, ingress)
6. Listen on socket(s)
7. Begin accepting API requests

Graceful shutdown sequence:
1. Stop accepting new requests (existing requests complete)
2. Signal containers with SIGTERM (via shim)
3. Wait grace period (default 10s)
4. SIGKILL remaining containers
5. Cleanup resources (networks, mounts)
6. Close storage driver and exit
```

#### Key Configuration Parameters (daemon.json)
```json
{
  "debug": false,                          // Enable debug logging
  "log-driver": "json-file",               // Container log driver
  "log-opts": {"max-size": "10m"},         // Log rotation config
  "storage-driver": "overlay2",            // Filesystem driver
  "storage-opts": ["..."],                 // Storage options
  "insecure-registries": [],               // Unencrypted registry access (not recommended)
  "registry-mirrors": [],                  // Mirror for pulling images
  "live-restore": true,                    // Keep containers live on daemon restart
  "max-concurrent-downloads": 3,           // Parallel downloads
  "max-concurrent-uploads": 5,             // Parallel uploads
  "metrics-addr": "127.0.0.1:9323",        // Prometheus metrics endpoint
  "experimental": false                    // Enable experimental features
}
```

#### Resource Limits & Tuning
- **Memory:** Daemon memory is separate from container memory (not pooled)
- **File Descriptors:** Each container requires ~20 FDs; scale calculation: `20 * num_containers`
- **Threads/Go Routines:** Daemon uses goroutines; CPU limits on daemon impact responsiveness
- **Network Connections:** Daemon maintains connection pool to registries; client connections

#### Storage Driver Considerations
| Driver | Performance | Layer Sharing | Snapshots | Use Case |
|--------|-------------|--------|-----------|----------|
| overlay2 | Excellent (native kernel) | Full | COW | Default, recommended |
| devicemapper | Good (block device) | Via snapshots | Native | Legacy, special requirements |
| vfs | Poor (copy-heavy) | None | Copy | Testing only |
| aufs | Declining | Full | CoW | Legacy (deprecated) |
| btrfs | Excellent (filesystem level) | Native | Snapshots | Btrfs-enabled hosts |

#### Health Monitoring

**Daemon Health Checks:**
```bash
# Socket responsiveness (primary metric)
curl -s --unix-socket /var/run/docker.sock http://localhost/v1.40/_ping
# Response: OK (healthy), timeout/refused (unhealthy)

# Detailed daemon info
docker info
# Includes: containers count, images count, storage usage, driver info

# Daemon logs
journalctl -u docker -f    # systemd-managed daemon
tail -f /var/log/docker.log # Direct logging
```

**Warning Signs of Daemon Distress:**
- Slow API response times (> 1 second for basic commands)
- Growing memory usage without container proliferation
- Increasing goroutine count (visible in metrics)
- Unrecoverable storage driver errors in logs
- Connection pool exhaustion (too many registries/builders)

#### Security Context
- **Runs as:** Root (required for namespace/cgroup management)
- **Exposure:** Only over /var/run/docker.sock (or remote TLS)
- **Authentication:** Docker group membership (risk!) or TLS client certs
- **Audit:** All Docker API calls can be audited via systemd/journald

### Docker Client

#### Definition & Role
The **Docker Client** (docker CLI) is:
- Stateless command-line tool
- Parses user commands
- Makes API calls to daemon
- Handles output formatting and streaming
- Can operate offline for some operations (inspect images, read configs)

#### Command Categories

1. **Image Commands** (interact with images)
   - `docker build`, `docker pull`, `docker push`
   - `docker images`, `docker inspect`, `docker tag`
   - Operation: Local image store or remote registry

2. **Container Commands** (interact with running/stopped containers)
   - `docker run`, `docker create`, `docker start`
   - `docker ps`, `docker logs`, `docker exec`
   - Operation: Requires daemon connection

3. **Network Commands** (manage virtual networks)
   - `docker network create`, `docker network connect`
   - Operation: Daemon-dependent (creates kernel virtual NICs)

4. **Volume Commands** (manage persistent storage)
   - `docker volume create`, `docker volume inspect`
   - Operation: Managed by daemon storage driver

5. **Service/Swarm Commands** (cluster mode)
   - `docker service`, `docker stack`, `docker swarm`
   - Operation: Multi-node orchestration

#### Client-Daemon Communication Flow
```
Client Process (CLI)
    │
    ├─→ Parse command & flags
    ├─→ Determine API version (negotiate with daemon)
    ├─→ Construct API request (JSON payload)
    │
    ├─→ Open socket connection
    │   Socket: /var/run/docker.sock (Unix) or TCP
    │
    ├─→ Send HTTP request (GET/POST/etc)
    │   GET /v1.40/containers/json
    │   POST /v1.40/containers/create
    │
    ├─→ Stream response (can be long-lived)
    │   docker logs: streaming response
    │   docker pull: progress events
    │
    └─→ Close connection (or keep-alive for multiplexing)
```

#### Context & Configuration
- **Docker context:** Specifies daemon location (`~/.docker/config.json`)
- **Multiple contexts:** Switch between local, remote, and cloud daemons
- **Authentication:** Stored in `~/.docker/config.json` (base64 encoded)

```bash
docker context create myproduction --docker host=ssh://user@remote.host
docker context use myproduction
```

#### Output Formats & Parsing
```bash
# Default: Human-readable text
docker ps

# JSON: Parseable, complete info
docker ps --format='{{json .}}'

# Custom format: Specific fields
docker ps --format='{{.Names}}\t{{.Ports}}'

# Go templates: Powerful querying
docker ps --filter status=running --format='{{range .}}{{.ID}}\n{{end}}'
```

### Docker API

#### Definition & Scope
The **Docker API** (exposed by daemon) is:
- RESTful HTTP API (POST, GET, DELETE)
- Event streaming (long-lived connections)
- gRPC endpoint for containerd communication
- Versioned (v1.20, v1.30, etc.)

#### API Version Management
```
Docker Client      Docker Daemon
    │                   │
    ├─→ Negotiate API version (docker version)
    │   Client: v1.41 supported
    │   Daemon: v1.40 supported
    │   → Use v1.40 for communication
    │
    └─→ All requests use negotiated version
        Path: /v1.40/containers/create
```

**Implication:** Old clients can't use new daemon features if not backward-compatible.

#### Key API Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/containers/create` | POST | Create container from image |
| `/containers/{id}/start` | POST | Start stopped container |
| `/containers/{id}/wait` | GET | Block until container exits |
| `/containers/{id}/logs` | GET | Stream container output |
| `/containers/{id}/exec` | POST | Execute command in running container |
| `/images/create` | POST | Pull image from registry |
| `/images/{name}/push` | POST | Push image to registry |
| `/networks/create` | POST | Create virtual network |
| `/volumes/create` | POST | Create named volume |
| `/events` | GET | Subscribe to daemon events |

#### Event Schema (Streaming)
```json
{
  "Type": "container",
  "Action": "start",
  "Actor": {
    "ID": "abc123...",
    "Attributes": {
      "image": "nginx:latest",
      "name": "brave_fermi"
    }
  },
  "time": 1234567890,
  "timeNano": 1234567890123456789
}
```

**Use Cases:**
- Monitoring tools subscribe to events for real-time updates
- Orchestrators track container lifecycle
- Log aggregation tools track container starts/stops

#### Authentication & Authorization
- **Socket access:** File permissions (`/var/run/docker.sock` → unix group)
- **Remote access:** TLS client certificates (mutual TLS)
- **Registry auth:** Username/password or OAuth tokens
- **No RBAC:** Docker daemon has no native role-based access control (mitigated by Kubernetes)

### Container Runtime

#### Definition & Role
The **Container Runtime** (containerd) is:
- Daemon for managing containers
- Lifecycle management (create, start, stop, delete)
- Image management (pull, push, store)
- Snapshot management (layer storage)
- **Note:** Runs as separate process from Docker daemon

#### Architecture
```
containerd architecture:
┌────────────────────────────────────────┐
│ containerd Daemon (containerd)          │
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ Task Service (container execution)  ││
│ │  ├─ Create task (fork runc)         ││
│ │  ├─ Kill task (send signals)        ││
│ │  └─ Wait on task (blocking)         ││
│ └─────────────────────────────────────┘│
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ Image Service (layer management)    ││
│ │  ├─ Content store (hash-addressed)  ││
│ │  ├─ Snapshots (writable layers)     ││
│ │  └─ Image metadata                  ││
│ └─────────────────────────────────────┘│
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ Event Service                       ││
│ │  └─ Pub/sub event stream            ││
│ └─────────────────────────────────────┘│
└────────────────────────────────────────┘
```

#### Container Lifecycle (containerd's perspective)
```
1. Create
   ├─ Snapshot writable layer
   ├─ Setup mounts
   └─ Task not running yet

2. Start
   ├─ Invoke runc with bundle
   ├─ Runc forks init process
   └─ Return PID to caller

3. Running
   ├─ Process executes
   ├─ I/O streams available
   └─ Shim monitors process

4. Stop/Kill
   ├─ Send SIGTERM or SIGKILL
   ├─ Shim reports exit
   └─ Status: exited (not deleted)

5. Delete
   ├─ Cleanup snapshots
   ├─ Cleanup mounts
   └─ Remove container state
```

#### Shim Process (containerd-shim)
The **shim** is a lightweight process that:
- Maintains connection to running container's processes
- Relayed I/O (stdin, stdout, stderr)
- Survives daemon restarts (containers stay alive)
- Reports exit status and resource usage

```
containerd Daemon → Fork shim process → Fork runc → Init process (PID 1)
                                                       ├─ User process
                                                       └─ Child processes
```

**Why shim matters:** If containerd crashes, shims reconnect it on restart. Containers continue executing uninterrupted.

#### Snapshot Management
Snapshots provide writable layers for containers:
```
Image Layers (immutable):
layer1 (base OS)
layer2 (application binaries)
layer3 (configuration)

Container Snapshot (writable):
├─ Diff of changes
├─ CoW (copy-on-write) overlay
└─ Mounted as container rootfs
```

### runc

#### Definition & Role
The **runc** tool is:
- OCI Runtime (reference implementation)
- Low-level container execution
- Spawns actual container processes
- Enforces resource limits (cgroups)
- Manages namespaces (isolation)

#### One-Shot Execution Model
```
containerd: "Start container ABC"
    │
    └─→ Fork runc process
        └─→ runc loads bundle (/run/runc/ABC/)
            ├─ config.json (OCI config)
            ├─ rootfs/ (filesystem)
            └─ Spawns actual process
                └─→ Detaches
                    runc exits after successful spawn
```

**Key insight:** runc doesn't stay running. It spawns the process and exits. The shim monitors the spawned process.

#### OCI Bundle Structure
```
/run/containers/ABC/
├── config.json         # OCI spec (image config, resource limits, namespaces)
├── rootfs/             # Container root filesystem (from image layers)
│   ├── bin/
│   ├── etc/
│   ├── lib/
│   └── ...
└── (optional: hooks, certs)
```

#### Namespace & cgroup Enforcement
runc configures:
- **Namespaces** (isolation): pid, ipc, network, uts, mount, user
- **cgroups** (resource limits): memory, CPU, I/O, PIDs
- **Seccomp** (syscall filtering): restrict dangerous syscalls
- **AppArmor/SELinux** (MAC): additional security restrictions

#### Default vs Custom Runtimes
```json
// daemon.json: specify alternative runtime
{
  "runtimes": {
    "kata": {
      "path": "/usr/bin/kata-runtime"
    },
    "crun": {
      "path": "/usr/bin/crun"
    }
  }
}

// Use custom runtime:
docker run --runtime=kata nginx   // Lightweight VM instead of namespace
docker run --runtime=crun nginx   // Faster, more efficient runc
```

### Docker CLI

#### Definition & Scope
The **Docker CLI** (`docker` command) is:
- User-facing command-line interface
- Parses commands and options
- Makes API calls to daemon (or local image store)
- Formats and outputs results
- Handles streaming responses

#### Command Execution Flow
```
$ docker run -d --name web -p 8080:80 nginx

1. Parse command: run
2. Parse flags: -d, --name web, -p, -p 8080:80
3. Determine image: nginx (pull if not present)
4. Create container via /containers/create API
   Payload: {
     "Image": "nginx",
     "Hostname": "web",
     "ExposedPorts": {"80/tcp": {}},
     "HostConfig": {"PortBindings": {"80/tcp": [{"HostPort": "8080"}]}}
   }
5. Start container via /containers/{id}/start API
6. Return container ID/name to user
7. Exit (container runs independently)
```

#### Key Operational Commands (Senior Level)

**Container Inspection:**
```bash
docker inspect <container>      # Full JSON config (perfect for scripting)
docker exec <container> <cmd>   # Run command inside container
docker top <container>          # Process listing
docker events                   # Stream all daemon events
```

**Debugging:**
```bash
docker logs <container>         # Retrieve container output
docker logs -f <container>      # Stream live output
docker stats <container>        # Real-time resource usage
docker diff <container>         # Filesystem changes
```

**Network/Volume:**
```bash
docker network inspect <net>    # View network configuration
docker volume inspect <vol>     # View volume metadata
docker ps --filter label=key=val  # Filter by labels
```

#### Configuration & Context Management
```bash
# Multiple daemon access
docker context create prod --docker host=tcp://prod.host:2376
docker context ls
docker context use prod

# Configuration file (~/.docker/config.json)
{
  "auths": {...},               // Registry credentials
  "currentContext": "default",   // Active context
  "contexts": {...}             // Named daemon connections
}
```

---

## Hands-on Scenarios

### Scenario 1: Emergency Debugging - Persistent Daemon Crashes in Production

**Problem Statement:**
Production Kubernetes cluster experiencing intermittent Docker daemon crashes every 4-6 hours across 3 worker nodes. Each crash cascades: daemon restart → live-restore reconnects containers → but some containers show networking issues → cluster becomes degraded → requires manual intervention every 4 hours.

**Architecture Context:**
- 150 containers across 3 nodes (AWS EC2 instances, c5.4xlarge)
- containerd version: 1.6.2, Docker 24.0.1
- Storage driver: overlay2 on 200GB EBS volumes
- Monitoring: Prometheus scraping daemon metrics
- Kubernetes: 1.28, using Docker socket for kubelet communication

**Step-by-step Troubleshooting:**

1. **Collect baseline metrics and logs:**
   ```bash
   # Gather daemon logs before they become unreadable
   journalctl -u docker -b -n 500 > docker-crash-logs.txt
   
   # Capture system logs (OOM killer, kernel panics)
   dmesg | tail -50 > dmesg-output.txt
   
   # Check disk usage patterns (storage driver bloat)
   docker system df > disk-usage-before.txt
   du -sh /var/lib/docker/* >> disk-usage-before.txt
   
   # Record daemon uptime and restart count
   systemctl status docker >> daemon-status.txt
   ```

2. **Identify root cause through log analysis:**
   ```bash
   # Search for OOM events
   grep -i "out of memory" docker-crash-logs.txt  # Check
   grep "oom-killer" /var/log/syslog              # Check
   
   # Search for storage driver errors
   grep -i "overlay" docker-crash-logs.txt
   grep -i "device or resource busy" docker-crash-logs.txt
   
   # Search for goroutine leaks
   grep "goroutine" docker-crash-logs.txt
   
   # Timeline analysis: How long before crash?
   tail -100 docker-crash-logs.txt | grep -E "time|error"
   ```

3. **Real scenario finding:** Disk usage growing unbounded.
   ```bash
   # Check /var/lib/docker/overlay2 for bloated containers
   find /var/lib/docker/overlay2 -type d -name "diff" \
     -exec du -sh {} \; | sort -h | tail -20
   
   # Result: One container's writable layer is 45GB (should be <500MB)
   # Root cause: Application writing unrotated logs to container
   docker logs <bloated-container> | wc -l  # 2 billion lines!
   ```

4. **Immediate mitigation:**
   ```bash
   # Stop the problematic container
   docker stop <bloated-container>
   
   # Remove its massive writable layer
   docker rm <bloated-container>
   
   # Clean up orphaned layers
   docker system prune -a --force
   
   # Verify disk recovery
   docker system df
   # Before: 95% full (190GB used)
   # After: 45% full (90GB used)
   ```

5. **Prevent recurrence:**
   ```bash
   # Configure aggressive log rotation
   cat > /etc/docker/daemon.json << EOF
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "50m",
       "max-file": "5",
       "labels": "app_version"
     },
     "storage-driver": "overlay2"
   }
   EOF
   
   # Test log rotation on new container
   docker run --name test-logs alpine sh -c "
     for i in {1..1000}; do echo 'Line '$i; done
   "
   
   docker logs test-logs | wc -l  # Should be limited
   du -sh /var/lib/docker/containers/*/logs/  # Should be small
   ```

6. **Implement automated monitoring:**
   ```bash
   #!/bin/bash
   # docker-health-monitor.sh (cron: every 30 minutes)
   
   THRESHOLD_PERCENT=80
   USED=$(docker system df --format "{{json .." | jq '.Containers[0].Size')
   
   if [ $USED -gt $THRESHOLD_PERCENT ]; then
     alert "Docker disk usage at ${USED}%"
     docker system prune -f
   fi
   
   # Alert on containers with writable layers > 1GB
   find /var/lib/docker/overlay2/*/diff/ -type d | while read dir; do
     size=$(du -s "$dir" | awk '{print $1}')
     if [ $size -gt 1000000 ]; then  # 1GB in KB
       alert "Container oversize: $dir ($size KB)"
     fi
   done
   ```

**Best Practices Applied:**
- ✅ Log rotation enforced daemon-wide
- ✅ Monitoring for disk capacity (predictive alerts)
- ✅ Container writable layer limits (via cgroups)
- ✅ Regular cleanup cron jobs

---

### Scenario 2: Networking Troubleshooting - Container Cannot Reach External Services

**Problem Statement:**
After daemon restart, some containers can't resolve DNS and external services time out. Other containers on the same network work fine. Issue appears to be related to containerd shim state restoration.

**Architecture Context:**
- Custom bridge network (`prod-app-net`) with 20 containers
- 2 containers affected: microservices-a and microservices-b
- Unaffected: Redis, Nginx (both using same network)
- DNS: 8.8.8.8 (public)

**Diagnosis & Resolution:**

1. **Verify network connectivity:**
   ```bash
   # Check bridge network status
   docker network inspect prod-app-net | jq '.Containers'
   
   # Are the affected containers listed? YES
   # Are they connected? Let's verify
   docker exec microservices-a ip addr show
   # Should show: eth0 with IP (e.g., 172.19.0.3)
   
   docker exec microservices-a ip route
   # Should show: default via 172.19.0.1 dev eth0
   ```

2. **Test DNS resolution:**
   ```bash
   # From affected container
   docker exec microservices-a nslookup google.com
   # Error: Server failed or no data
   
   # From working container
   docker exec redis nslookup google.com
   # Success: IP returned
   
   # Check /etc/resolv.conf inside container
   docker exec microservices-a cat /etc/resolv.conf
   # Result: empty or contains wrong nameserver
   ```

3. **Root cause:** DNS configuration not restored after daemon restart.

   The daemon restart via live-restore didn't properly restore network namespace DNS settings for these specific containers.

   ```bash
   # Verify shim state
   ps aux | grep containerd-shim | grep microservices
   # Shims are running
   
   # Check namespace connection
   CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' microservices-a)
   cat /proc/$CONTAINER_PID/net/route  # Network configuration
   
   # The issue: iptables rules not restored
   docker exec microservices-a iptables -L -n
   # Should show MASQUERADE rules; they're missing
   ```

4. **Immediate fix:**
   ```bash
   # Reconnect containers to network (network driver re-plumbs)
   docker network disconnect prod-app-net microservices-a
   docker network connect prod-app-net microservices-a
   
   # Verify DNS now works
   docker exec microservices-a nslookup google.com
   # Success!
   ```

5. **Root cause fix:** Prevent incomplete network restoration.
   ```bash
   # Set explicit daemon flags to enforce clean startup
   cat > /etc/docker/daemon.json << EOF
   {
     "live-restore": true,
     "log-driver": "json-file",
     "ipv6": false,
     "userland-proxy": true,
     "userns-remap": "default"
   }
   EOF
   
   # Validate with test restart
   systemctl restart docker
   docker exec microservices-a nslookup google.com
   # Should work immediately without manual reconnect
   ```

6. **Monitor for recurrence:**
   ```bash
   #!/bin/bash
   # Check all containers can resolve DNS
   
   for container in $(docker ps -q); do
     name=$(docker inspect -f '{{.Name}}' $container | sed 's#^/##')
     if ! docker exec $container nslookup google.com &>/dev/null; then
       echo "WARNING: $name DNS failed; reconnecting..."
       # Auto-reconnect if needed
       networks=$(docker inspect -f '{{.HostConfig.NetworkMode}}' $container)
       docker network disconnect $networks $container
       docker network connect $networks $container
     fi
   done
   ```

**Best Practices Applied:**
- ✅ Live-restore not blindly trusted; validation after daemon restart
- ✅ Automated DNS health checks
- ✅ Self-healing network reconnection

---

### Scenario 3: Performance Crisis - Build Times Regressed from 2min to 45min

**Problem Statement:**
CI/CD pipeline experiencing 20x slower `docker build` times. Builds that took 2 minutes now take 45 minutes. Developers blocked. Must be resolved within 4 hours.

**Architecture Context:**
- Docker daemon on dedicated build server (16 CPU, 32GB RAM)
- Building microservices images 50+ times daily
- BuildKit enabled (20.11+)
- Layer caching should be working

**Root Cause Analysis:**

1. **Establish baseline:**
   ```bash
   # Measure single build performance
   time docker build -t test-app:latest .
   # Result: 41 minutes (vs expected 2 minutes)
   ```

2. **Check layer cache status:**
   ```bash
   # List all intermediate layers
   docker images | wc -l  # 500+ images!
   
   # Identify dangling/orphaned layers
   docker images -f dangling=true | wc -l  # 300+ dangling
   
   # Check if build is using cache
   docker build --no-cache -t test-app:latest . 2>&1 | grep "CACHED"
   # Result: NO CACHED layers (cache miss on every build)
   ```

3. **Investigate cache disablement:**
   ```bash
   # Check daemon settings
   cat /etc/docker/daemon.json | jq '.experimental'
   # False (BuildKit requires experimental=true for some features)
   
   # Check BuildKit status
   docker buildx ls  # Is buildx available?
   docker buildx build --help  # Works?
   
   # Check image pull behavior
   docker build --progress=plain -t test-app:latest . 2>&1 | head -20
   # Shows: "Pulling image from registry" on EVERY layer
   # (Cache invalidated)
   ```

4. **Root cause found:** Local cache corrupted; builds using registry instead.

   ```bash
   # Graph driver integrity issue
   docker system df
   # Images: 500 (should be ~20)
   # Layers: 5000+ (should be ~100)
   
   # Disk fragmentation
   ls -la /var/lib/docker/image/overlay2/imagedb/metadata/v1.json | wc -c
   # Meta file: 15MB (should be <1MB) - indicates cache bloat
   ```

5. **Fix cache corruption:**
   ```bash
   # Atomic cache rebuild
   systemctl stop docker
   
   # Backup current state
   tar czf /backup/docker-graph-backup.tar.gz /var/lib/docker/image/
   
   # Remove image metadata (NOT layers)
   rm -rf /var/lib/docker/image/overlay2/imagedb/metadata/
   
   # Restart daemon (rebuilds metadata)
   systemctl start docker
   
   # Rebuild cache from images
   docker images | tail -n +2 | awk '{print $3}' | xargs -I {} \
     docker pull {} 2>/dev/null
   ```

6. **Verify performance recovery:**
   ```bash
   # First build (no cache): 45 minutes expected
   time docker build -t test-app:v1 .
   
   # Second build (cache hit): should be <2 minutes
   time docker build -t test-app:v2 .
   # Result: 90 seconds ✓ Cache working
   ```

7. **Storage driver optimization:**
   ```bash
   # Configure daemon for build performance
   cat > /etc/docker/daemon.json << EOF
   {
     "storage-driver": "overlay2",
     "storage-opts": [
       "overlay2.override_kernel_check=true",
       "overlay2.size=100gb"
     ],
     "experimental": true,
     "features": {
       "buildkit": true
     },
     "max-concurrent-downloads": 5,
     "max-concurrent-uploads": 5
   }
   EOF
   
   systemctl restart docker
   ```

8. **Implement CI/CD safeguards:**
   ```bash
   #!/bin/bash
   # Pre-build health check
   
   # Measure expected build time
   BASELINE=120  # 2 minutes in seconds
   TIMEOUT=$((BASELINE * 5))  # 10 minutes max
   
   timeout $TIMEOUT docker build -t test-app:latest . || {
     echo "Build timeout or failure; clearing cache..."
     docker image prune -a -f
     timeout $TIMEOUT docker build -t test-app:latest .
   }
   ```

**Best Practices Applied:**
- ✅ Regular layer cache validation
- ✅ Build performance baselines with alerts
- ✅ Timeout mechanisms to prevent hung builds

---

### Scenario 4: Security Incident - Secrets Found in Image Layers

**Problem Statement:**
Security audit discovers database passwords hardcoded in layer history of production image. Image has been in use for 8 months across 200 containers in production. Requires immediate remediation without service downtime.

**Discovery:**
```bash
# Security scan reveals secrets in history
docker history myapp:v1.2.3 | grep -i password
# Line 5: RUN echo "PASSWORD=db123456" > /etc/config.env

# Worse: Layer still in registry
docker run myapp:v1.2.3 docker history myapp:v1.2.3 # Shows secret
```

**Remediation Steps:**

1. **Assess exposure:**
   ```bash
   # How many images contain the secret?
   for image in $(docker images -q); do
     if docker history $image | grep -q "db123456"; then
       docker inspect $image | jq '.RepoTags'
     fi
   done
   # Result: 5 images tainted
   
   # Are they in production?
   kubectl get deployments -o jsonpath='{.items[*].spec.template.spec.containers[*].image}' | \
     grep -E "myapp|tainted" | wc -l
   # Result: 150 pods running
   ```

2. **Rotate secrets immediately:**
   ```bash
   # Database password rotation (out-of-band)
   kubectl set env deployment/myapp \
     DB_PASSWORD="new_secure_password_xyz" \
     --overwrite
   
   # Verify new credentials work
   kubectl rollout status deployment/myapp
   ```

3. **Rebuild images without secret:**
   ```dockerfile
   # OLD (WRONG):
   RUN echo "PASSWORD=db123456" > /etc/config.env
   
   # NEW (CORRECT):
   # Use multi-stage build to exclude secrets
   FROM golang:1.20 as builder
   COPY . .
   RUN go build -o myapp .
   
   # Runtime stage - no secrets
   FROM debian:bookworm-slim
   COPY --from=builder /app/myapp /usr/bin/
   # Secrets injected at runtime, not build time
   ```

4. **Rebuild and push new images:**
   ```bash
   # Re-build from scratch (bust cache)
   docker build --no-cache -t myapp:v1.2.4 .
   
   # Verify NO secret in history
   docker history myapp:v1.2.4 | grep -q "db123456"
   # Exit code 1 (not found) ✓
   
   # Push to registry
   docker push myapp:v1.2.4
   ```

5. **Redeploy with new image:**
   ```bash
   # Rolling update (no downtime)
   kubectl set image deployment/myapp \
     myapp=myapp:v1.2.4 \
     --record
   
   # Monitor rollout
   kubectl rollout status deployment/myapp -w
   # Rolls through all 150 pods
   ```

6. **Remove tainted images:**
   ```bash
   # From production registries
   # WARNING: Ensure all pods updated FIRST
   
   # Get registry credentials
   docker login -u $REGISTRY_USER myregistry.azurecr.io
   
   # Delete tainted tags  
   az acr repository delete --name myregistry --image myapp:v1.2.3
   az acr repository delete --name myregistry --image myapp:v1.2.2
   az acr repository delete --name myregistry --image myapp:v1.2.1
   
   # Verify deletion
   az acr repository show --name myregistry --repository myapp | jq '.tags'
   ```

7. **Prevent future secrets in images:**
   ```bash
   # Implement build-time secret scanning
   #!/bin/bash
   # scan-build.sh (git pre-commit hook)
   
   PATTERNS=(
     "PASSWORD="
     "SECRET="
     "TOKEN="
     "AWS_ACCESS_KEY"
     "PRIVATE_KEY"
   )
   
   for pattern in "${PATTERNS[@]}"; do
     if grep -r "$pattern" . --include="Dockerfile*"; then
       echo "ERROR: Secret pattern detected: $pattern"
       exit 1
     fi
   done
   
   # Scan built image layers
   docker build -t test-scan .
   docker history test-scan | while read line; do
     if echo "$line" | grep -qE "${PATTERNS[@]}"; then
       echo "ERROR: Secret in layer: $line"
       exit 1
     fi
   done
   ```

8. **Audit compliance:**
   ```bash
   # Log all image builds and pushes
   # Enable Docker daemon audit logging
   auditctl -w /var/lib/docker -p wa -k docker_images
   
   # Archive all image history
   for tag in $(docker images --format "{{.Repository}}:{{.Tag}}"); do
     docker history $tag > /audit/image-history/$(echo $tag | tr '/' '-').txt
   done
   ```

**Best Practices Applied:**
- ✅ Multi-stage builds to exclude transient secrets
- ✅ Secrets injected at runtime (environment variables, Kubernetes Secrets)
- ✅ Image layer scanning in CI/CD (prevent merge)
- ✅ Audit logs for compliance

---

### Scenario 5: Scaling Challenges - Daemon Becomes Bottleneck at 500+ Containers

**Problem Statement:**
As container count grows, API response times degrade. `docker ps` takes 5+ seconds. Kubernetes kubelet health checks timeout. Cluster becomes unstable above 500 containers per node.

**Architecture Context:**
- Single daemon per node (Kubernetes worker)
- Kubernetes DaemonSet deployment
- 800+ containers scaling up
- containerd + runc (modern stack)

**Performance Diagnosis:**

1. **Measure API responsiveness:**
   ```bash
   # Baseline timing
   time docker ps > /dev/null
   # Real: 5.234s (should be <100ms)
   
   # Isolate bottleneck
   time curl -s --unix-socket /var/run/docker.sock \
     http://localhost/v1.40/_ping > /dev/null
   # Real: 0.05s (daemon is responsive)
   
   time curl -s --unix-socket /var/run/docker.sock \
     http://localhost/v1.40/containers/json > /dev/null
   # Real: 4.8s (listing containers is slow)
   ```

2. **Identify resource limits:**
   ```bash
   # Check daemon CPU usage
   ps aux | grep dockerd
   # Result: PID 1234, consuming 60% CPU during operations
   
   # Check goroutine count
   curl http://localhost:9323/metrics | grep goroutines
   # go_goroutines 5000 (should be <100 normally)
   # Indicates goroutine leak or task explosion
   
   # Memory usage
   ps aux | grep dockerd | awk '{print $6}'
   # 18GB RSS (daemon memory out of hand)
   ```

3. **Root cause:** Daemon resource exhaustion.

   - Each container requires ~15MB daemon memory (metadata, connections)
   - 800 containers × 15MB = 12GB alone
   - Plus image metadata, network state, volume tracking
   - Daemon hitting memory limit triggers GC pressure

4. **Tune daemon for high-density:**
   ```bash
   cat > /etc/docker/daemon.json << EOF
   {
     "storage-driver": "overlay2",
     "live-restore": true,
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "2"
     },
     "insecure-registries": [],
     "metrics-addr": "127.0.0.1:9323",
     "experimental": false,
     "default-runtime": "runc",
     "runtimes": {
       "runc": {
         "path": "runc",
         "runtimeArgs": []
       }
     },
     "max-concurrent-downloads": 3,
     "max-concurrent-uploads": 2,
     "storage-opts": [
       "overlay2.override_kernel_check=true"
     ]
   }
   EOF
   ```

5. **Increase systemd limits:**
   ```bash
   cat > /etc/systemd/system/docker.service.d/limits.conf << EOF
   [Service]
   MemoryLimit=32G
   MemoryHigh=28G
   MemoryAccounting=true
   CPUQuota=300%
   LimitNOFILE=1048576
   LimitNPROC=1048576
   EOF
   
   systemctl daemon-reload
   systemctl restart docker
   ```

6. **Monitor and validate:**
   ```bash
   #!/bin/bash
   # Performance baseline after tuning
   
   ITERATIONS=5
   total_time=0
   
   for i in $(seq 1 $ITERATIONS); do
     time_s=$(( $(date +%s%N) ))
     docker ps -q > /dev/null
     time_e=$(( $(date +%s%N) ))
     elapsed=$((($time_e - $time_s) / 1000000))
     echo "Iteration $i: ${elapsed}ms"
     total_time=$((total_time + elapsed))
   done
   
   avg=$(($total_time / $ITERATIONS))
   echo "Average: ${avg}ms (target: <100ms)"
   
   if [ $avg -gt 100 ]; then
     echo "FAIL: Still too slow"
     exit 1
   fi
   ```

7. **Results after optimization:**
   ```
   Before:
   - docker ps: 5.2 seconds
   - API /containers/json: 4.8 seconds
   - Daemon memory: 18GB
   - Go routines: 5000
   
   After:
   - docker ps: 85ms ✓
   - API /containers/json: 70ms ✓
   - Daemon memory: 8GB ✓
   - Go routines: 150 ✓
   ```

**Best Practices Applied:**
- ✅ Daemon resource limits enforced (systemd)
- ✅ Log rotation prevents unbounded growth
- ✅ Storage driver optimization
- ✅ Metrics-driven monitoring and alerting

## Interview Questions

### Level 1: Architecture Understanding

**Q1: Explain the roles of Docker Daemon, containerd, and runc. Why are they separate?**

**A1 (Strong Answer):**
"Each component has distinct responsibility in increasing order of abstraction level:

- **runc** (low-level): OCI runtime that spawns processes with proper namespaces and cgroups. Executes once per container start and exits; doesn't daemonize.

- **containerd** (middle): Container runtime daemon managing container lifecycle. Maintains shim processes connecting runc-spawned processes to the container abstraction. Survives runc crashes and daemon restarts.

- **Docker daemon** (orchestration): Manages images, networking, volumes, and exposes Docker API. Coordinates with containerd but doesn't directly execute containers.

Separation enables: Daemon restarts without killing containers (via shim), runtime exchangeability (swap runc for crun or kata), and fault isolation (runc failure doesn't cascade to daemon)."

---

**Q2: What happens when the Docker daemon crashes with containers running?**

**A2 (Strong Answer):**
"Containers continue running uninterrupted. Here's why:

1. **Shim maintenance:** Each running container has a containerd-shim process maintaining connection to the actual process (spawned by runc).

2. **Process independence:** The container process is a child of the shim, not the daemon. Daemon death doesn't make the kernel kill the child processes.

3. **Daemon restart (with live-restore):** Shim reconnects containerd to the running processes, and containerd reconnects the daemon. `docker ps` again shows running containers.

4. **Without live-restore (legacy):** Containers continue running but become 'orphaned'—the daemon can't see or manage them until restart.

**Evidence:** Run `ps aux | grep' on host; you'll see actual container processes (PID 1 inside container) as separate processes in host's process tree."

---

**Q3: Can you replace runc with another OCI runtime? What are the implications?**

**A3 (Strong Answer):**
"Yes, runc is replaceable because Docker adheres to OCI Runtime Specification. Common alternatives:

- **crun** (faster, lower memory): Written in C; ~20% faster, ~50% less memory than runc (Golang). Drop-in replacement for performance-critical workloads.

- **kata-containers** (lightweight VMs): Each container is a minimal VM instead of namespace. Stronger isolation but higher overhead. Used for multi-tenant security.

- **gVisor** (sandbox): Google's sandboxed runtime for untrusted workloads. Intercepts syscalls for additional isolation.

**Configuration:**
\`\`\`json
{
  "runtimes": {
    "crun": {"path": "/usr/bin/crun"}
  }
}
\`\`\`

\`docker run --runtime=crun nginx\`

**Implications:**
- All three understand OCI bundles and configs
- Performance characteristics differ (startup time, memory, syscall latency)
- Compatibility: Most workloads work identically, but some syscalls may behave differently
- Image compatibility: Fully compatible—images don't encode runtime choice"

---

### Level 2: Operational & Diagnostic Expertise

**Q4: You notice `docker ps` is taking 30+ seconds. Daemon appears responsive otherwise. Diagnose the root cause and explain your debugging approach.**

**A4 (Strong Answer):**
"First, isolate which layer is slow:

1. **Test daemon responsiveness (baseline):**
   \`\`\`bash
   curl -s --unix-socket /var/run/docker.sock http://localhost/_ping
   # Time this; should be <10ms
   \`\`\`

2. **Test list API directly:**
   \`\`\`bash
   time curl -s --unix-socket /var/run/docker.sock \
     http://localhost/v1.40/containers/json | jq . | wc -l
   # If slow here (>20s), daemon is computing the response slow
   \`\`\`

3. **Check containerd as bottleneck:**
   \`\`\`bash
   sudo ctr tasks list
   # If fast: Docker daemon is the bottleneck
   # If slow: containerd is slow; docker ps is waiting for containerd
   \`\`\`

4. **Likely causes:**
   - **Huge container count:** 5000+ containers in memory; daemon doing N operations
   - **Large image graph:** Image metadata bloated; daemon parsing on each ps
   - **Goroutine leak:** Daemon goroutines stuck; CPU contention
   - **Storage driver issue:** OverlayFS metadata slow; kernel overhead

5. **Real-world fix (from Scenario 5):**
   \`\`\`bash
   # Set resource limits
   # Tune systemd service for daemon
   # Restart + validate
   
   time docker ps  # Should drop from 30s to <100ms
   \`\`\`"

---

**Q5: Explain Docker API versioning and how it affects client-daemon compatibility. What would happen if you ran an old client against a new daemon?**

**A5 (Strong Answer):**
"Docker API uses semantic versioning (v1.20, v1.40, v1.41). Versioning enables controlled evolution without breaking backward compatibility.

**Negotiation Process:**
\`\`\`
docker ps command
  │
  ├─→ Client connects to daemon
  │
  ├─→ Client: 'I support APIs v1.30 to v1.41'
  │
  ├─→ Daemon: 'I support APIs v1.20 to v1.41'
  │
  └─→ Both agree on v1.40 (highest common version)
      All requests use /v1.40/containers/*
\`\`\`

**Scenario: Old client (Docker CLI v19.03) + New daemon (v24.0)**
- CLI supports: v1.20 - v1.39
- Daemon supports: v1.25 - v1.41
- They negotiate v1.39
- Old CLI can't use v1.40+ features (e.g., buildkit, new container options)
- But existing commands still work via backward-compatible v1.39 API

**Scenario: New client (v24.0) + Old daemon (v19.03)**
- CLI supports: v1.25 - v1.41
- Daemon supports: v1.20 - v1.39
- They negotiate v1.39
- New features requiring v1.40+ will fail gracefully
- Standard commands work via v1.39

**Implication:** Clients automatically downgrade to daemon's API version. This enables gradual daemon upgrades without coordinating all clients."

---

**Q6: You observe that after a daemon restart, some containers show as `exited` but their processes are still running on the host. Explain what happened and how to recover.**

**A6 (Strong Answer):**
"This is the **orphaned container** scenario:

**What happened:**
1. Daemon had `live-restore: false` (or legacy Docker)
2. Daemon restarted or crashed
3. Shim processes and container processes continued running (kernel isolated)
4. Daemon restarted fresh; didn't reconnect to running shims
5. Result: Shim are orphaned; daemon doesn't know containers are running

**Evidence:**
\`\`\`bash
# Daemon lost track
docker ps -a | grep exited  # Shows as 'exited'

# But process is alive
ps aux | grep <container_pid>  # Process still running!

# Verify
docker inspect <container> | jq .State
# Status: exited, but Pid: 5678 (should be 0 if truly exited)
\`\`\`

**Recovery (two options):**

Option 1: Enable live-restore and restart (forward-looking)
\`\`\`bash
# Set in daemon.json
{
  \"live-restore\": true
}

systemctl restart docker
# Daemon reconnects to running shims automatically
docker ps | grep <container>  # Now shows 'running'
\`\`\`

Option 2: Force-reconnect orphaned containers (immediate)
\`\`\`bash
for container_id in $(docker ps -a -f status=exited -q); do
  pid=$(docker inspect -f '{{.State.Pid}}' $container_id)
  if ps -p $pid > /dev/null 2>&1; then
    # Process is actually running; daemon lost track
    # Restart container to reconnect
    docker start $container_id
    docker unpause $container_id 2>/dev/null
  fi
done
\`\`\`

**Prevention:** Always enable `live-restore: true` in production."

---

### Level 3: Architecture Design & Complex Scenarios

**Q7: Design a high-availability Docker daemon setup for a production SaaS platform with 10,000+ containers across 50 nodes. Address single points of failure.**

**A7 (Strong Answer):**
"HA architecture for 10k containers:

**1. Daemon Level (per node):**
\`\`\`
Node (Kubernetes worker)
  │
  ├─ Docker Daemon (systemd managed)
  │  ├─ live-restore: true (survives crashes)
  │  ├─ memory limit: 32GB (prevent host swap)
  │  ├─ restart policy: always (systemctl auto-restart)
  │  └─ audit logging: enabled
  │
  └─ Monitoring (Prometheus + Alerting)
     ├─ Daemon responsiveness (/_ping)
     ├─ Container count trending
     ├─ Memory/CPU usage alerts
     └─ API latency percentiles (p99)
\`\`\`

**2. Registry Resilience (Image Distribution):**
- Private registry with 3 replicas (quorum)
- Each replica caches pulls independently
- DNS round-robin for registry VIP
- \`registry-mirrors\` in daemon.json for fallback

\`\`\`json
{
  \"registry-mirrors\": [
    \"https://mirror1.internal:5000\",
    \"https://mirror2.internal:5000\",
    \"https://mirror3.internal:5000\"
  ],
  \"insecure-registries\": [\"mirror1.internal:5000\"]
}
\`\`\`

**3. Network Path Resilience:**
- Docker socket access: Local (Unix socket) - no network SPF
- Remote API: TLS mutual auth to multiple proxy endpoints
- Load balanced daemon access (if needed): Keep it simple; use Kubernetes API instead

**4. Failure Scenarios & Recovery:**

Scenario A: Single daemon crash
- Duration: <10 seconds (systemctl restart)
- Impact: API unavailable; containers unaffected (live-restore)
- Recovery: Daemon restarts, reconnects to running containers

Scenario B: Node failure (hardware)
- Duration: Kubernetes pod eviction (30-60s)
- Impact: All containers on node restart on sister nodes
- Recovery: Automatic; Kubernetes reschedules pods

Scenario C: Cascading daemon failures (e.g., disk full across fleet)
- Prevention: Enforce log rotation, image cleanup, disk monitoring
- Detection: Prometheus alerts if >5 daemons offline
- Recovery: Automated disk cleanup if space <10%; manual intervention if widespread

**5. Operational Safeguards:**

\`\`\`bash
# Cron job: Prevent cascading failures
0 * * * * /opt/daemon-health-check.sh

#!/bin/bash
# daemon-health-check.sh

# Verify daemon responsive
curl -s --unix-socket /var/run/docker.sock http://localhost/_ping || \
  systemctl restart docker

# Cleanup if disk >90%
usage=$(df /var/lib/docker | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $usage -gt 90 ]; then
  docker system prune -a -f
fi

# Check for orphaned shims
orphaned=$(ps aux | grep containerd-shim | grep -v grep | wc -l)
if [ $orphaned -gt 0 ]; then
  systemctl restart containerd
fi
\`\`\`

**6. Key Metrics for Health:**
- API response time (p99 < 50ms)
- Daemon restart frequency (< 1 per week)
- Container success rate (> 99.5%)
- Image pull latency (< 5s median)

This architecture trades redundancy (can't avoid local daemon failure, but it's rare) for simplicity and focuses on prevention + rapid recovery."

---

**Q8: A container running inside a custom namespace cannot reach services outside the Docker network. Explain the networking path and how to debug.**

**A8 (Strong Answer):**
"Container networking involves multiple layers: network namespace isolation, veth pairs, bridge, iptables routing.

**Diagnosis Path:**

1. **Verify container network config:**
   \`\`\`bash
   docker inspect <container> | jq '.NetworkSettings'
   # Shows: Network mode, IP, Gateway, etc.
   \`\`\`

2. **Inside container: test each layer:**
   \`\`\`bash
   # Layer 1: Container interface
   docker exec <container> ip addr show
   # Expected: eth0 with IP (e.g., 172.17.0.2)
   
   # Layer 2: Default route
   docker exec <container> ip route show
   # Expected: default via 172.17.0.1 dev eth0
   
   # Layer 3: Can reach gateway?
   docker exec <container> ping -c 1 172.17.0.1
   # Should succeed
   
   # Layer 4: DNS resolution
   docker exec <container> nslookup google.com
   # Should resolve; if fails, DNS not configured
   
   # Layer 5: External connectivity
   docker exec <container> curl -I https://google.com
   # Should connect; if times out, routing rule missing
   \`\`\`

3. **From host: inspect bridge:**
   \`\`\`bash
   # Find Docker bridge
   ip addr show | grep \"docker0\\|br-\"
   # Example output: docker0: 172.17.0.1/16
   
   # Check veth pair
   ip link show | grep \"veth\"
   # Should have vethXXXXXXX connected to container
   
   # Trace veth to container
   docker inspect <container> | jq '.NetworkSettings.SandboxKey'
   # Check namespace file
   ls -la /var/run/docker/netns/
   \`\`\`

4. **Inspect iptables rules:**
   \`\`\`bash
   # Check SNAT rule for outbound traffic
   sudo iptables -t nat -L -n | grep -A 5 \"docker0\"
   # Should show: MASQUERADE rule for container IPs
   
   # If missing, iptables state lost (network restart issue)
   # Fix: Restart daemon with live-restore
   \`\`\`

**Common Issues & Fixes:**

Issue A: DNS fails
- Cause: /etc/resolv.conf not exposed to container
- Fix: Restart container or reconnect to network
\`\`\`bash
docker network disconnect <network> <container>
docker network connect <network> <container>
\`\`\`

Issue B: MASQUERADE rule missing (after daemon restart)
- Cause: live-restore=false; iptables state lost on daemon crash
- Fix: Enable live-restore; test with daemon restart
\`\`\`json
{\"live-restore\": true}
\`\`\`

Issue C: Custom network with wrong driver
- Cause: User created overlay network on single host (needs swarm cluster)
- Fix: Use bridge network for single-host or proper overlay setup

**Debugging Script:**
\`\`\`bash
#!/bin/bash
# Full network diagnostic

container=$1
echo \"=== Diagnosing $container ===\"

# Container side
echo \"\\n--- Container Network Config ---\"
docker exec $container ip addr show
docker exec $container ip route show
docker exec $container cat /etc/resolv.conf

# Host side
echo \"\\n--- Host Bridge State ---\"
ip addr show | grep docker
sudo iptables -t nat -L -n | grep docker

echo \"\\n--- Connectivity Tests ---\"
docker exec $container ping -c 1 8.8.8.8 && echo \"Internet: OK\" || echo \"Internet: FAILED\"
docker exec $container curl -I https://google.com && echo \"HTTPS: OK\" || echo \"HTTPS: FAILED\"
\`\`\`"

---

**Q9: Your organization wants to migrate from Docker Swarm to Kubernetes. What architectural changes in Docker should they prepare for? What stays the same?**

**A9 (Strong Answer):**
"Docker architecture is stable; migration is mostly orchestrationlayer change.

**What Stays the Same:**
- Images (compliance, format)
- Containers (spec, behavior)
- Storage layer (overlay2, volumes)
- Networking fundamentals (namespace isolation, veth pairs)
- Docker CLI commands (docker run, ps, logs still work)

**What Changes (Orchestration):**
- Daemon becomes \"stupid\" (Kubernetes doesn't use Docker API for scheduling)
- kubelet creates containers via containerd API (docker daemon is optional)
- Service discovery: Docker DNS → Kubernetes Service DNS
- Load balancing: Docker Ingress → Kubernetes Ingress
- Secrets management: Docker Secrets → Kubernetes Secrets
- Logging: Docker logs → Kubernetes logging driver

**Architectural Implications:**

1. **Docker daemon is no longer central:**
   \`\`\`
   Swarm Model (Docker-centric):
   Docker CLI → Docker Daemon API → Swarm orchestrator → containerd
   
   Kubernetes Model (k8s-centric):
   kubectl → Kubernetes API → kubelet → containerd API
   Docker daemon is optional/unused
   \`\`\`

2. **Image Distribution:**
   - Same: Images in registries (still OCI format)
   - Different: Kubernetes ImagePullPolicy replaces Docker pull semantics

3. **Networking (biggest change):**
   - Docker networks (overlay/bridge) → Kubernetes CNI plugins (Flannel, Calico)
   - Container-to-container DNS → Kubernetes Service DNS
   - Expose port → Kubernetes Service NodePort/LoadBalancer

4. **Resource Isolation:**
   - Docker cgroups (memory, CPU limits) → Kubernetes resource requests/limits
   - Both use same underlying kernel mechanisms

**Migration Path:**

1. **Phase 1: Prepare (no service impact)**
   - Enable containerd in Docker daemon (already default in v20.10+)
   - Stop relying on Docker socket access
   - Migrate secrets from Docker Secrets → config files

2. **Phase 2: Run Kubernetes alongside Swarm (weeks)**
   - Deploy Kubernetes clusters in parallel
   - Migrate non-critical workloads first
   - Validate networking, logging, monitoring

3. **Phase 3: Full Cutover**
   - Migrate services to Kubernetes
   - Decommission Swarm clusters
   - Docker daemon becomes container runtime only (not orchestrator)

**What They Should Learn:**
- Kubernetes Pod model (k8s abstraction over Docker container)
- Kubernetes Service/Ingress (replaces Docker load balancing)
- ConfigMaps/Secrets (Kubernetes-native secrets)
- PersistentVolumes (Kubernetes storage model)
- StatefulSets (for databases replace Docker Swarm constraints)

**Skills That Transfer:**
- Container image building (docker build still the same)
- Container debugging (docker exec → kubectl exec)
- Resource limits (CPU/memory concepts the same)
- Logging inspection (docker logs → kubectl logs)"

---

**Q10: Describe the complete lifecycle of an image from `docker build` to a running container. Explain daemon and storage driver involvement at each step.**

**A10 (Strong Answer):**
"End-to-end image and container lifecycle:

**1. BUILD PHASE (docker build -t myapp:1.0 .)**

\`\`\`
User: docker build
  │
  ├─→ Daemon receives /build API request
  │   Payload: {dockerfile, context, tags}
  │
  ├─→ For each Dockerfile instruction:
  │
  │   INSTRUCTION: FROM ubuntu:20.04
  │   └─→ Storage driver checks if ubuntu:20.04 locally available
  │       If not: pull from registry, store layers in /var/lib/docker/
  │
  │   INSTRUCTION: RUN apt-get install nginx
  │   ├─→ Create temporary container (snapshot writable layer)
  │   ├─→ Mount: lowerdir=ubuntu_layers + upperdir=temp_container
  │   ├─→ Execute command inside container
  │   ├─→ Storage driver computes diff (new files/modifications)
  │   ├─→ Commit diff as new layer (calculate SHA256 digest)
  │   └─→ Delete temporary container
  │
  │   INSTRUCTION: COPY . /app
  │   ├─→ Create temporary container from last layer
  │   ├─→ Storage driver copies build context files
  │   ├─→ Commit as new layer
  │   └─→ Delete temporary container
  │
  │   INSTRUCTION: CMD [\"nginx\"]
  │   └─→ No filesystem change; update image metadata
  │
  └─→ Create final image config JSON:
      {
        RootFS: {Layers: [sha256:layer0, sha256:layer1, ...]},
        Cmd: [\"nginx\"],
        Env: [...],
        Created: ISO8601-timestamp
      }

Disk state AFTER BUILD:
  /var/lib/docker/overlay2/
  ├─ l_abc123/ (layer 0: ubuntu base)
  ├─ l_def456/ (layer 1: nginx installation)
  ├─ l_ghi789/ (layer 2: app code)
  └─ image metadata stored in imagedb/
\`\`\`

**2. REGISTRY PUSH (docker push myregistry/myapp:1.0)**

\`\`\`
User: docker push
  │
  ├─→ Daemon reads local image manifest
  │
  ├─→ For each layer SHA256:
  │   └─→ Check if layer already in registry (HEAD request)
  │       If yes: skip (bandwidth savings)
  │       If no: Upload layer to registry
  │
  ├─→ Create image config JSON (immutable)
  │   └─→ Upload config JSON to registry
  │
  └─→ Create image manifest (links layers + config)
      └─→ Upload manifest to registry

Cloud state AFTER PUSH:
  registry.azurecr.io/myapp@sha256:manifest_digest
  ├─ Manifest file (JSON pointing to layers/config)
  ├─ Config blob (image config)
  └─ Layer blobs (l_abc123, l_def456, l_ghi789)
\`\`\`

**3. IMAGE PULL (docker pull myregistry/myapp:1.0)**

\`\`\`
User: docker pull
  │
  ├─→ Daemon downloads image manifest from registry
  │   (Downloaded manifest lists all layers needed)
  │
  ├─→ For each layer in manifest:
  │   ├─→ Check if locally cached (by digest SHA256)
  │   │   If yes: skip download
  │   │   If no: download + decompress + store
  │   │
  │   └─→ Storage driver stores in /var/lib/docker/overlay2/
  │
  ├─→ Download image config JSON (from manifest)
  │
  └─→ Update local image database
      (Image is now available for docker run)

Disk state AFTER PULL:
  /var/lib/docker/overlay2/ (same as build result)
  /var/lib/docker/image/overlay2/imagedb/ (metadata)
\`\`\`

**4. CONTAINER CREATION (docker run -d myapp:1.0)**

\`\`\`
User: docker run
  │
  ├─→ Daemon receives /containers/create API request
  │   Payload: {Image: \"myapp:1.0\", Cmd, Env, Mounts, ...}
  │
  ├─→ Lookup image in local imagedb
  │   Result: Image ID, layer list, config
  │
  ├─→ Storage driver creates container snapshot:
  │   ├─→ Snapshot writable layer (empty)
  │   ├─→ Create /var/lib/docker/overlay2/container_abc123/
  │   │   ├─ lower/ (symlinks to image layers)
  │   │   ├─ merged/ (OverlayFS mount point - NOT YET MOUNTED)
  │   │   ├─ upper/ (container writes go here)
  │   │   └─ work/ (temp directory for CoW)
  │   │
  │   └─→ Calculate layer digests (for caching)
  │
  ├─→ Create OCI runtime bundle:
  │   /run/runc/container_abc123/
  │   ├─ config.json (OCI config with namespaces, cgroups)
  │   ├─ rootfs → /var/lib/docker/overlay2/container_abc123/merged/
  │   └─ (hooks, secrets, etc.)
  │
  ├─→ Create container in daemon database
  │   (Status: CREATED, not running)
  │
  └─→ Return container ID to client

Disk state: Container created but NOT mounted yet
\`\`\`

**5. CONTAINER START (docker start <container_id>)**

\`\`\`
User: docker start
  │
  ├─→ containerd Task Service receives request
  │
  ├─→ Storage driver mounts OverlayFS:
  │   mount -t overlay -o \
  │     lowerdir=/var/lib/docker/overlay2/{l_abc,l_def,l_ghi}, \
  │     upperdir=/var/lib/docker/overlay2/container_abc123/upper, \
  │     workdir=/var/lib/docker/overlay2/container_abc123/work \
  │     none /var/lib/docker/overlay2/container_abc123/merged/
  │
  │   Container now has unified filesystem view
  │
  ├─→ containerd spawns shim:
  │   fork containerd-shim-v2 (one process per container)
  │
  ├─→ Shim spawns runc:
  │   runc run --bundle /run/runc/container_abc123
  │
  │   runc:
  │   ├─→ Setup namespaces (pid, network, mount, ipc, uts)
  │   ├─→ Setup cgroups (memory 512MB, CPU 0.5)
  │   ├─→ Chroot into rootfs
  │   ├─→ Fork init process (PID 1 inside container)
  │   ├─→ Execute CMD: nginx (as child)
  │   └─→ runc exits (shim takes over)
  │
  ├─→ Shim reports:
  │   Container PID: 5678 (on host)
  │   Status: RUNNING
  │
  └─→ Daemon updates database
      Container status: RUNNING

Runtime state: Container executing
  Host: process tree
    PID 1234: containerd-shim-v2
    └─ PID 5678: nginx (parent: 1234)

  Inside container (separate namespace): Process tree
    PID 1: nginx
    └─ PID 2: nginx (worker)

  Filesystem: Merged OverlayFS view
    Read from: Image layers (immutable)
    Write to: container upper/ directory
\`\`\`

**6. RUNNING CONTAINER (logs, exec, networking)**

\`\`\`
docker logs <container>
  └─→ Daemon reads stdout from shim stream

docker exec <container> /bin/sh
  └─→ containerd spawns new process in container namespace
      └─→ Joins existing PID/network/mount namespaces
          └─→ User executes command alongside nginx

docker network inspect
  └─→ Daemon shows veth pair, IP, gateway
      Container can reach other containers + host

Container modifies filesystem:
  # Inside container: touch /data/file.txt
  └─→ OverlayFS detects: /data/ in lowerdir (read-only)
      └─→ Copy /data/ to upper/
          └─→ Write file.txt to upper/data/
          └─→ No impact on image layers

docker stats
  └─→ Daemon reads cgroup metrics
      Memory: 45MB (from /proc/cgroup)
      CPU: 12% (calculated from cgroup .stat)
\`\`\`

**7. CONTAINER STOP (docker stop <container>)**

\`\`\`
User: docker stop
  │
  ├─→ Daemon signals shim: SIGTERM
  │   └─→ Shim forwards SIGTERM to nginx (PID 1)
  │
  ├─→ nginx exits (gracefully)
  │   └─→ Shim detects exit via waitpid()
  │       └─→ Reports exit code to containerd
  │
  ├─→ Daemon updates container status: STOPPED
  │
  ├─→ Shim still running (will be cleaned up on delete)
  │
  └─→ OverlayFS still mounted (writable layer still exists)

Container state: Exited but not deleted
  Writable layer: /var/lib/docker/overlay2/container_abc123/upper/
    └─ Contains all files/changes made while running
    └─ Can be recovered if container restarted
\`\`\`

**8. CONTAINER DELETE (docker rm <container>)**

\`\`\`
User: docker rm
  │
  ├─→ Daemon unmounts OverlayFS
  │   umount /var/lib/docker/overlay2/container_abc123/merged/
  │
  ├─→ Storage driver removes container snapshot
  │   rm -rf /var/lib/docker/overlay2/container_abc123/
  │
  ├─→ Shim cleanup requested
  │   (Exit shim process if still running)
  │
  ├─→ Remove OCI bundle
  │   rm -rf /run/runc/container_abc123/
  │
  └─→ Remove from daemon database
      Container is gone; can't be recovered

Disk state: Only image layers remain
  Image layers: /var/lib/docker/overlay2/l_*/ ← reusable
  Container layer: DELETED
\`\`\`

**Summary - Data Flow:**

\`\`\`
Build:      Dockerfile → Storage driver → Image layers → Layer digest
\`\`\`
Registry:   Layer digest → Upload → CloudSorage
Pull:       Cloud storage → Download → Storage driver → Local layers
Create:     Image layers → Storage driver snapshot → OCI bundle
Start:      OCI bundle → runc → Process + Namespaces + OverlayFS mount
Run:        Shim + Process execution
Logs:       Stdout stream → Daemon → User terminal
Stop:       Signal → Process exit → Daemon notification
Delete:     Unmount → Remove layer → Cleanup

**Storage driver role:**
- Build: Compute diffs after each instruction
- Pull: Store layers efficiently (hash-addressed)
- Create: Create snapshot (writable layer + mount points)
- Start: Mount OverlayFS (unify layers + container writes)
- Delete: Cleanup snapshot + validate layer reuse

**Daemon role:**
- Build: Coordinate container creation/deletion for each instruction
- Pull: Coordinate registry downloads through daemon API
- Create: Build OCI bundle + update database
- Start: Coordinate with containerd Task Service
- Run: Monitor + provide API (logs, exec)
- Delete: Cleanup + database updates"

---

## Conclusion

This comprehensive study guide equips Senior DevOps engineers with:

1. **Architectural Understanding** - How Docker components interact (daemon, containerd, runc, storage, networking)
2. **Operational Competency** - Diagnosing and fixing real-world production issues (5 detailed scenarios)
3. **Systems Design** - Building HA, secure, scalable containerized infrastructure
4. **Crisis Management** - Handling emergencies (crashes, security breaches, performance degradation)
5. **Technical Depth** - Understanding every layer from image building to runtime execution

These 10+ interview questions cover scenarios ranging from basic architecture understanding to advanced production troubleshooting, design patterns, and migration planning—the depth expected of candidates with 5–10+ years of DevOps experience at senior levels.

The next natural study sections would cover:
- [Docker Networking Deep Dive](#) (bridge networks, overlay networks, service discovery)
- [Image Distribution & Registry Architecture](#) (registry design, image signing, vulnerability scanning)
- [Kubernetes Integration](#) (kubelet → container runtime, pod network model)
- [Production Security Architecture](#) (scan, signing, RBAC, admission control)

---

## Deep Dive: Subtopic 1 - Docker Daemon Storage Architecture

### Textual Deep Dive

#### Internal Working Mechanism

The Docker Daemon's storage layer is the foundation for image management, layer caching, and container state persistence. It operates through a **storage driver abstraction** that decouples the daemon from physical storage implementation.

**Storage Stack (bottom-up):**
```
Application Layer (docker run, docker build)
    ↓
Daemon Storage API (internal graph driver interface)
    ↓
Storage Driver (overlay2, devicemapper, etc.)
    ↓
Backing Filesystem (ext4, btrfs, xfs)
    ↓
Block Device (disk, NVMe, SAN)
    ↓
Kernel (VFS, mounts, I/O subsystem)
```

**overlay2 (Modern Standard):**

The `overlay2` driver is the default and most performant for modern Linux systems. It uses Linux kernel's OverlayFS to present multiple layers as a single unified filesystem.

```
Layer Structure:
Image: ubuntu:20.04
├── Layer 1 (base): /var/lib/docker/overlay2/l_abc123/
│   ├── bin/
│   ├── lib/
│   └── etc/ (immutable in production)
│
├── Layer 2 (os updates): /var/lib/docker/overlay2/l_def456/
│   ├── usr/bin/ (new files)
│   └── lib/ (modified files, symlinked)
│
├── Layer 3 (application): /var/lib/docker/overlay2/l_ghi789/
│   └── app/ (application files)
│
Container Writable Layer:
└── Container: /var/lib/docker/overlay2/a1b2c3d4.../
    ├── merged/ (unified view of all layers via OverlayFS)
    ├── work/ (temporary working directory for CoW)
    └── upper/ (container-specific writes)
```

**Isolation Mechanism:**

OverlayFS creates a merged view of multiple directories:
```
lowerdir=layer1:layer2:layer3  (immutable image layers)
upperdir=container_upper/      (writable container changes)
workdir=container_work/        (internal working directory)
merged=                         (the unified filesystem inside container)
```

When a process in the container reads a file:
1. If file exists in `upperdir` → read from there
2. Else if file exists in `lowerdir` → read from there
3. Else file not found → error

When a process writes a file:
1. If file was in `lowerdir`, copy-on-write to `upperdir` first
2. Then write to `upperdir`
3. Original `lowerdir` unchanged (immutable)

#### Architecture Role

The storage layer serves three critical functions:

**1. Image Distribution Efficiency**
- Only changed layers need to be stored/transmitted
- Layer reuse across images (nginx:latest shares base layers with ubuntu:latest)
- Registry efficiency: 100 images might only need 20 unique layers stored

**2. Container Isolation**
- Each container's writable layer is independent
- Two containers from same image don't interfere (separate `upper/` directories)
- Container deletion removes only its layer, not image layers

**3. Build Performance**
- Docker build creates new layers for each instruction
- Layers are cached by daemon
- Rebuilding: only new/changed instructions are re-executed
- Layer caching: `docker build` with `--no-cache` disables caching

**Internal Graph Structure:**

The daemon maintains an in-memory graph of images and layers:
```
Image: ubuntu:20.04
├── ID: sha256:d5c1fc3e4992...
├── Parent Layer: sha256:a1b2c3d4...
├── Config: {
│     Cmd: ["/bin/bash"],
│     Env: ["PATH=/usr/bin:..."],
│     WorkingDir: "/"
│   }
├── Created: 2024-03-07T12:00:00Z
└── Size: 77MB

Containers running from this image:
├── Container ID: abc123def456
│   ├── Parent Image: ubuntu:20.04
│   ├── Writable Layer Size: 2.5MB (diff to image)
│   ├── Status: running
│   └── Upper dir: /var/lib/docker/overlay2/abc123def456/upper/
│
└── Container ID: xyz789uvw012
    ├── Parent Image: ubuntu:20.04
    ├── Writable Layer Size: 512KB
    └── Status: exited
```

#### Production Usage Patterns

**Pattern 1: Multi-Stage Builds (Minimize Layer Count)**
```dockerfile
# Builder stage
FROM golang:1.20 as builder
WORKDIR /app
COPY . .
RUN go build -o myapp .

# Runtime stage
FROM debian:bookworm-slim
COPY --from=builder /app/myapp /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/myapp"]
```

**Impact:** Only the final stage's layers end up in the image. Builder layers are discarded. Reduces image size from 1.2GB to 150MB.

**Pattern 2: Layer Ordering for Cache Efficiency**
```dockerfile
FROM node:18-alpine
WORKDIR /app

# Stable dependencies (rarely change) → layer 1
COPY package*.json ./
RUN npm install

# Volatile source code (frequently changes) → layer 2
COPY . .

RUN npm run build
```

**Impact:** If only source code changes, `npm install` is cached (no re-download of 300+ packages). If dependencies change, full installation happens. Cache hit probability is maximized.

**Pattern 3: Storage Driver Selection for Workload**

- **High-frequency writes:** Use `overlay2` on SSD with `data-root` on separate fast device
- **Multi-tenant with strong isolation:** Use `devicemapper` with thin provisioning or `btrfs`
- **Docker Desktop/Development:** `overlay2` default is sufficient

#### DevOps Best Practices

**1. Monitor Storage Usage**
```bash
# Full breakdown
docker system df

# Per-image details
docker images --quiet | xargs -I {} sh -c 'echo "Image: {}"; du -sh /var/lib/docker/image/overlay2/imagedb/content/sha256/{}/layer'

# Per-container writable layer
du -sh /var/lib/docker/overlay2/*/diff/
```

**2. Implement Layer Cleanup**
```bash
# Remove dangling images (orphaned layers)
docker image prune -a --force

# Remove stopped containers (frees upper dirs)
docker container prune -f

# Full system cleanup (dangerous, use with caution)
docker system prune -a --volumes
```

**3. Configure Log Rotation (Prevents Layer Growth)**
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",     // Per-container log max
    "max-file": "3",       // Number of rotated files
    "labels": "com.example.version"
  }
}
```

**4. Storage Driver Performance Tuning**

For `overlay2`:
```bash
# Use dedicated fast device for /var/lib/docker
# E.g., NVMe partition:
sudo mkfs.ext4 /dev/nvme0n1p1
sudo mkdir -p /mnt/docker-storage
sudo mount /dev/nvme0n1p1 /mnt/docker-storage

# Update daemon.json
{
  "data-root": "/mnt/docker-storage"
}

systemctl restart docker
```

#### Common Pitfalls

**Pitfall 1: Unbounded Layer Growth**
```dockerfile
# WRONG: Writes append to same file
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y nginx
RUN rm -rf /var/lib/apt/lists/*  # Doesn't shrink layer; just marks as deleted
```

The `rm` command creates a new layer documenting deletions, but doesn't actually remove data from the previous layer. The image still contains all apt cache.

**Fix:** Combine commands
```dockerfile
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*
```

This keeps deletion in the same layer: apt-get → install → remove in one RUN instruction.

**Pitfall 2: Storing Secrets in Layers**
```dockerfile
# WRONG: Secret baked into image layer
RUN echo "PASSWORD=blah123" > /etc/config.env
```

Even if later deleted, it's still in the layer history. Tools like `docker history` and layer scanning tools find it.

**Fix:** Use secrets at runtime
```bash
# Via environment variable at containers start
docker run -e PASSWORD=$(</run/secrets/db_password) myapp

# Or Docker Secrets (Swarm)
docker secret create db_password -
docker run --secret db_password myapp
```

**Pitfall 3: Excessive Image Layers**
```dockerfile
# WRONG: 50+ RUN instructions
RUN apt-get update
RUN apt-get install -y nginx
RUN apt-get install -y curl
RUN apt-get install -y wget
...
```

Each RUN creates a layer. Metadata and layer index overhead accumulate.

**Fix:** Combine related commands
```dockerfile
RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    wget
```

**Pitfall 4: volatile Cache Invalidation**
```dockerfile
# WRONG: Cache bust on every build
ADD https://example.com/data.zip /tmp/data.zip  # URL fetched every time
RUN unzip /tmp/data.zip
```

Using `ADD` with volatile URLs bypasses layer caching.

**Fix:** Use stable URLs or build-time args
```dockerfile
ARG DATA_VERSION=1.2.3
ADD https://example.com/data-${DATA_VERSION}.zip /tmp/data.zip
```

Cache is invalid only when `DATA_VERSION` changes.

---

### Practical Code Examples

#### Example 1: Monitor Storage Layer Usage
```bash
#!/bin/bash
# docker-storage-audit.sh

echo "=== Docker Storage Breakdown ==="
docker system df

echo ""
echo "=== Largest Images ==="
docker images --format "{{.Repository}}:{{.Tag}}\t{{.Size}}" | sort -k2 -h | tail -10

echo ""
echo "=== Container Writable Layer Usage (Top 10) ==="
du -sh /var/lib/docker/overlay2/*/diff/ 2>/dev/null | sort -h | tail -10

echo ""
echo "=== Dangling Resources ==="
echo "Dangling images: $(docker images -f dangling=true -q | wc -l)"
echo "Stopped containers: $(docker ps -a -f status=exited -q | wc -l)"
echo "Dangling volumes: $(docker volume ls -f dangling=true -q | wc -l)"

echo ""
echo "=== Storage Driver Info ==="
docker info | grep -A 5 "Storage Driver"
```

**Usage:**
```bash
chmod +x docker-storage-audit.sh
./docker-storage-audit.sh
```

#### Example 2: Layer Inspection Script
```bash
#!/bin/bash
# inspect-layers.sh - Analyze image layers

IMAGE=$1
if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image:tag>"
  exit 1
fi

echo "=== Layer History for $IMAGE ==="
docker history $IMAGE --human --no-trunc

echo ""
echo "=== Layer Sizes (Compressed vs Uncompressed) ==="
docker inspect $IMAGE | jq -r '.RootFS.Layers[]' | while read layer_id; do
  # Find the uncompressed size
  size=$(docker inspect $IMAGE | jq -r ".RootFS.Layers | .[$i].size? // 0")
  echo "$layer_id: $size bytes"
done

echo ""
echo "=== Inspect Final Layer Config ==="
docker inspect $IMAGE | jq '.Config'
```

#### Example 3: Automated Cleanup Script
```bash
#!/bin/bash
# docker-cleanup.sh - Safely remove unused images and containers

set -e

DRY_RUN=${1:-false}

cleanup() {
  local name=$1
  local cmd=$2
  
  if [ "$DRY_RUN" == "true" ]; then
    echo "[DRY RUN] Would execute: $cmd"
  else
    echo "Executing: $cmd"
    eval $cmd
  fi
}

echo "=== Docker Cleanup Script ==="
echo "Mode: $([ "$DRY_RUN" == "true" ] && echo "DRY RUN" || echo "LIVE")"

# Remove stopped containers
echo ""
echo "Removing stopped containers..."
cleanup "containers" "docker container prune -f"

# Remove dangling images
echo ""
echo "Removing dangling images..."
cleanup "dangling_images" "docker image prune -f"

# Remove unused images (not referenced by any container)
echo ""
echo "Removing unused images..."
cleanup "unused_images" "docker image prune -a -f"

# Remove dangling volumes
echo ""
echo "Removing dangling volumes..."
cleanup "volumes" "docker volume prune -f"

# Summary
echo ""
echo "=== Cleanup Summary ==="
docker system df
```

**Usage:**
```bash
chmod +x docker-cleanup.sh
./docker-cleanup.sh true    # Dry run
./docker-cleanup.sh false   # Live execution
```

#### Example 4: Build Optimization Analyzer
```dockerfile
# Dockerfile (optimized for caching)
FROM node:18-alpine AS builder

# Layer 1: Base + dependencies (cached unless package.json changes)
WORKDIR /build
COPY package*.json ./
RUN npm ci --only=production

# Layer 2: Build dependencies (separate cache for dev deps)
COPY package*.json ./
RUN npm ci

# Layer 3: Source code (most volatile; separate from deps)
COPY . .
RUN npm run build && npm prune --production

# Final stage: Runtime image (only runtime deps)
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/package*.json ./

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**Build with layer introspection:**
```bash
# Build with inline layer viewing
docker build --progress=plain -t myapp:latest .

# Inspect resulting layers
docker images myapp
docker history myapp:latest --human

# Analyze efficiency
docker inspect myapp:latest | jq '.RootFS.Layers | length'  # Layer count
docker inspect myapp:latest | jq '.Size'                     # Total size
```

---

### ASCII Diagrams

#### Diagram 1: OverlayFS2 Layer Structure During Container Build

```
IMAGE BUILD PROCESS:
════════════════════════════════════════════════════════════════════

Step 1 (FROM ubuntu:20.04):
┌─────────────────────────────────────────────────────────────┐
│ Image: ubuntu:20.04                                          │
│ Layers:                                                       │
│  ├─ Layer 0 (base): /var/lib/docker/overlay2/l_0000/       │
│  └─ Layer 1 (updates): /var/lib/docker/overlay2/l_0001/    │
│                                                               │
│ Container workspace (temp):                                  │
│  ├─ lowerdir: l_0000:l_0001                                 │
│  ├─ upperdir: builder_12345/upper                           │
│  └─ merged: /var/lib/docker/overlay2/builder_12345/merged   │
└─────────────────────────────────────────────────────────────┘

Step 2 (RUN apt-get install nginx):
┌─────────────────────────────────────────────────────────────┐
│ Image: intermediate                                           │
│ Layers:                                                       │
│  ├─ Layer 0 (base): l_0000/                                 │
│  ├─ Layer 1 (updates): l_0001/                              │
│  └─ Layer 2 (NEW - nginx install): /var/lib/docker/...l_0002/
│                                                               │
│ Diff contains only:                                          │
│  ├─ /usr/sbin/nginx (new file)                              │
│  ├─ /etc/nginx/ (new dir)                                   │
│  └─ /var/www/html (new dir)                                 │
└─────────────────────────────────────────────────────────────┘

Step 3 (COPY app.js /app/):
┌─────────────────────────────────────────────────────────────┐
│ Image: myapp:latest (FINAL)                                 │
│ Layers:                                                       │
│  ├─ Layer 0 (base): l_0000/                                 │
│  ├─ Layer 1 (updates): l_0001/                              │
│  ├─ Layer 2 (nginx): l_0002/                                │
│  └─ Layer 3 (app): /var/lib/docker/overlay2/l_0003/        │
│                                                               │
│ Diff contains:                                               │
│  └─ /app/app.js (new file)                                  │
└─────────────────────────────────────────────────────────────┘


RUNNING A CONTAINER FROM IMAGE:
════════════════════════════════════════════════════════════════════

Container Start:
┌──────────────────────────────────┐
│ Image Layers (read-only):        │
│  ├─ l_0000 (base OS)             │
│  ├─ l_0001 (updates)             │
│  ├─ l_0002 (nginx)               │
│  └─ l_0003 (app code)            │
└──────────────────────────────────┘
           ↓ (OverlayFS mount)
┌──────────────────────────────────┐
│ Container Writable Layer:        │
│  ├─ upper/ (changes)             │
│  ├─ work/ (temp)                 │
│  └─ merged/ (unified view)       │
└──────────────────────────────────┘
           ↓ (process access)
┌──────────────────────────────────┐
│ Container Filesystem (merged):   │
│  /usr/sbin/nginx  (from layer 2) │
│  /etc/nginx/      (from layer 2) │
│  /app/app.js      (from layer 3) │
│  /tmp/myfile      (from upper/)  │
│  /app/data.log    (from upper/)  │
└──────────────────────────────────┘


TWO CONTAINERS FROM SAME IMAGE:
════════════════════════════════════════════════════════════════════

Container A: web_server_1                Container B: web_server_2
┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│ Shared Image Layers (read-only)  │  │ Shared Image Layers (read-only)  │
│  ├─ l_0000 (base OS)             │  │  ├─ l_0000 (base OS)             │
│  ├─ l_0001 (updates)             │  │  ├─ l_0001 (updates)             │
│  ├─ l_0002 (nginx)               │  │  ├─ l_0002 (nginx)               │
│  └─ l_0003 (app code)            │  │  └─ l_0003 (app code)            │
└──────────────────────────────────┘  └──────────────────────────────────┘
           ↓                                       ↓
   INDEPENDENT LAYERS:                   INDEPENDENT LAYERS:
┌──────────────────────────────────┐  ┌──────────────────────────────────┐
│ Container A Writable Layer:      │  │ Container B Writable Layer:      │
│  /app/cache/     (A's data)      │  │  /app/cache/     (B's data)      │
│  /tmp/logs_A     (A's files)     │  │  /tmp/logs_B     (B's files)     │
│  Disk: ~50MB                     │  │  Disk: ~30MB                     │
│ Isolated from B                  │  │ Isolated from A                  │
└──────────────────────────────────┘  └──────────────────────────────────┘

Shared image layers: ~150MB (counted once)
Total storage for both: 150 + 50 + 30 = 230MB (vs 300MB if full copies)
```

#### Diagram 2: Storage Driver Lifecycle During CoW Operation

```
READING FILE FROM LAYER:
═══════════════════════════════════════════════════════════════════

File: /etc/nginx/nginx.conf exists in Layer 2 (from image)

Container Process:
  cat /etc/nginx/nginx.conf
    │
    ├─→ Kernel checks OverlayFS merged/ view
    │
    ├─→ Is file in upperdir (writable)? NO
    │   └─→ Check lowerdir layers (read-only)
    │
    ├─→ Found in lowerdir[1] (nginx installation layer)
    │   └─→ Read directly from layer 2 filesystem
    │
    └─→ Return file contents to process


WRITING NEW FILE (CoW - Copy-on-Write):
═══════════════════════════════════════════════════════════════════

File: /var/www/html/index.html doesn't exist

Container Process:
  echo "Hello" > /var/www/html/index.html
    │
    ├─→ OverlayFS checks: Is /var/www/html in upperdir?
    │   NO → Check lowerdir
    │
    ├─→ /var/www/html/ exists in lowerdir (from image)
    │   BUT: Creating NEW file (not modifying existing)
    │
    ├─→ Directly create in upperdir/var/www/html/index.html
    │   (No copy-on-write needed for new files)
    │
    └─→ File write succeeds


MODIFYING EXISTING FILE (Full CoW):
═══════════════════════════════════════════════════════════════════

File: /etc/nginx/nginx.conf exists in Layer 2 (read-only)

Container Process:
  sed -i 's/worker_processes auto;/worker_processes 8;/' /etc/nginx/nginx.conf
    │
    ├─→ Open file for WRITE
    │
    ├─→ OverlayFS detects: File is in lowerdir, but container is writing
    │
    ├─→ COPY-ON-WRITE triggers:
    │   1. Read entire file from lowerdir
    │   2. Copy to upperdir/etc/nginx/nginx.conf
    │   3. Close lowerdir read
    │
    ├─→ Apply modifications to upperdir copy
    │
    └─→ File modification succeeds (lowerdir unchanged)


FILESYSTEM AFTER MODIFICATIONS:
═══════════════════════════════════════════════════════════════════

Image Layers (immutable):
├─ Layer 0: /etc/nginx/nginx.conf (original)
├─ Layer 0: /var/www/html/index.html (original - empty dir)
└─ Layer 0: /usr/sbin/nginx (original)

Container Writable Layer (upperdir):
├─ /etc/nginx/nginx.conf (modified copy - 2KB)
├─ /var/www/html/index.html (new file - 12 bytes)
└─ (other container-specific changes)

Container View (merged):
├─ /etc/nginx/nginx.conf (from upperdir - modified version)
├─ /var/www/html/index.html (from upperdir - new version)
└─ /usr/sbin/nginx (from Layer 0 via lowerdir - original)
```

#### Diagram 3: Storage Driver Interaction with Daemon API

```
APPLICATION LAYER REQUEST:
═══════════════════════════════════════════════════════════════════

docker build -t myapp:1.0 .
    │
    ├─→ Daemon receives /build API request
    │   {
    │     "dockerfile": "FROM ubuntu:20.04\nRUN apt-get...",
    │     "tags": ["myapp:1.0"],
    │     "buildargs": {},
    │     "cachefrom": []
    │   }
    │
    ├─→ Daemon parses Dockerfile instructions
    │   Step 1: FROM ubuntu:20.04
    │   Step 2: RUN apt-get install -y nginx
    │   Step 3: COPY . /app
    │   Step 4: CMD ["nginx", "-g", "daemon off;"]
    │
    └─→ For each step, invoke Storage Driver


STORAGE DRIVER EXECUTION:
═══════════════════════════════════════════════════════════════════

Step 1: FROM ubuntu:20.04
  ├─→ Storage Driver checks if ubuntu:20.04 cached locally
  │   If not, pull from registry
  │   └─→ Stores layers in /var/lib/docker/overlay2/
  │
  └─→ Get layer digest(s): sha256:abc123...

Step 2: RUN apt-get install -y nginx
  ├─→ Create temporary container from ubuntu:20.04
  │   ├─ Snapshot new layer for changes
  │ └─ Mount lowerdir=(ubuntu layers) + upperdir=(new)
  │
  ├─→ Execute command in temporary container
  │   /bin/bash -c "apt-get install -y nginx"
  │   (Changes written to upperdir)
  │
  ├─→ Store upperdir as new layer 0002
  │   /var/lib/docker/overlay2/l_0002/diff/*
  │
  ├─→ Calculate layer digest (from contents)
  │
  └─→ Remove temporary container

Step 3: COPY . /app
  ├─→ Create temporary container from Step 2's result
  │   ├─ Snapshot new layer for changes
  │   └─ Mount lowerdir=(ubuntu + nginx layers) + upperdir=(new)
  │
  ├─→ Copy local files into container
  │   rsync from /path/to/build/context → /app/
  │   (Changes written to upperdir)
  │
  ├─→ Store upperdir as new layer 0003
  │
  └─→ Remove temporary container

Step 4: CMD ["nginx", "-g", "daemon off;"]
  ├─→ No filesystem change (metadata only)
  │
  ├─→ Create image config JSON:
  │   {
  │     "Cmd": ["nginx", "-g", "daemon off;"],
  │     "Entrypoint": null,
  │     "RootFS": {
  │       "Layers": [
  │         "sha256:0000...",  (ubuntu)
  │         "sha256:0001...",  (nginx)
  │         "sha256:0002...",  (app code)
  │       ]
  │     }
  │   }
  │
  └─→ Store as image metadata


LAYER CACHING OPTIMIZATION:
═══════════════════════════════════════════════════════════════════

Second build (code changed, dependencies same):

docker build -t myapp:1.1 .

Step 1: FROM ubuntu:20.04
  └─→ CACHE HIT: Already have layers, digest matches
      No re-download needed

Step 2: RUN apt-get install -y nginx
  └─→ CACHE HIT: Same instruction, same parent layer
      Fetch digest from cache without re-execution

Step 3: COPY . /app  ← Code changed
  └─→ CACHE MISS: Context hash different
      Execute: need new layer for updated code
      Parent (nginx layer) cached, only COPY executed

Step 4: CMD ...
  └─→ CACHE HIT: Metadata same, recalculate fast

Total build time: ~2 seconds (only COPY executed) vs 45 seconds (full rebuild)
```

---

## Deep Dive: Subtopic 2 - containerd Task Service & Shim Architecture

### Textual Deep Dive

#### Internal Working Mechanism

The **Task Service** is containerd's core component for managing container lifecycle and process execution. It bridges the gap between the external Docker/Kubernetes API and kernel-level execution via runc.

**containerd Service Architecture:**

```
containerd Daemon
│
├─ Content Service (image layer storage, hash-addressed)
├─ Image Service (image metadata, manifests)
├─ Snapshot Service (writable layers, CoW snapshots)
│
└─ Task Service ← PRIMARY FOCUS
   ├─ Task management (create, start, stop, delete)
   ├─ Execution coordination (via shim)
   ├─ Process monitoring (exit status, signals)
   ├─ Event publishing (lifecycle events)
   ├─ Namespace management
   └─ Resource limit enforcement (cgroups)
```

**Task Lifecycle State Machine:**

```
             CREATE
               │
               ▼
        ┌─────────────┐
        │   CREATED   │ (container exists, process not started)
        └─────────────┘
               │
               │ START
               ▼
        ┌─────────────┐
        │   RUNNING   │ (process executing)
        └─────────────┘
         │            │
  PAUSE  │            │ KILL/STOP
         ▼            ▼
    ┌────────┐   ┌──────────┐
    │ PAUSED │   │ STOPPING │
    └────────┘   └──────────┘
         │            │
 RESUME  │            │
         │            ▼
         │       ┌──────────┐
         │       │ STOPPED  │
         │       └──────────┘
         │            │
         └────────────┘

DELETE (from any state)
         │
         ▼
   ┌──────────┐
   │ DELETED  │ (resources cleaned up)
   └──────────┘
```

**Shim Process Architecture:**

The shim is a critical process that sits between containerd and the actual application process:

```
containerd Daemon (main process)
         │
         │ Fork + exec
         ▼
   ┌───────────────────────────┐
   │  containerd-shim-runc-v2  │ (one per container)
   │  PID: 1234                │
   │                            │
   │  Responsibilities:         │
   │  ├─ Monitor init process  │
   │  ├─ Relay I/O streams     │
   │  ├─ Report exit codes     │
   │  └─ Handle signals        │
   └───────────────────────────┘
         │
         │ Fork + exec (via runc)
         ▼
   ┌───────────────────────────┐
   │  Application Container    │
   │  PID 1 (inside container) │
   │  PID 5678 (on host)       │
   │                            │
   │  ├─ nginx process         │
   │  ├─ PHP-FPM child         │
   │  └─ Log aggregator        │
   └───────────────────────────┘
```

**Why Shim Matters:**

The shim allows **daemon independence**. When containerd restarts:

```
Without Shim:
  containerd crash
    │
    └─→ Container processes become orphaned
        No one maintains stdin/stdout/stderr
        Exit codes lost
        Container status unknown

With Shim:
  containerd crash
    │
    ├─→ Application container continues executing
    ├─→ Shim continues monitoring process
    │
    └─→ containerd restarts
        └─→ Shim re-announces tasks
            └─→ containerd restores database
                └─→ Full state restored
```

#### Architecture Role

The Task Service serves these production-critical functions:

**1. Process Spawning (via runc)**
- Creates OCI bundle (config.json + rootfs)
- Invokes runc: `runc run --bundle /run/runc/abc123`
- runc forks actual process, exits
- Shim captures PID and maintains connection

**2. Resource Enforcement**
- Sets up cgroups (memory, CPU, PIDs)
- Configures namespaces (pid, ipc, network, mount, user, uts)
- Applies seccomp rules and AppArmor profiles
- Enables hierarchical cgroup organization (multiple controllers)

**3. Process Monitoring & Cleanup**
- Reports process exit status (exit code, signal)
- Handles zombie process reaping
- Manages process group cleanup (child processes)
- Tracks resource usage (memory, CPU time)

**4. Stream Management**
- Pipes stdin/stdout/stderr through shim
- Multiplexing: one shim manages multiple streams
- PTY support (interactive containers)
- Non-PTY support (daemonized containers)

**5. Lifecycle Events & Subscriptions**
- Publish events to subscribers: "container started", "container exited"
- Enable real-time monitoring (Kubernetes watches these events)
- Maintain event ordering guarantees

#### Production Usage Patterns

**Pattern 1: Interactive Container Execution**
```bash
docker run -it ubuntu:20.04 /bin/bash

# Flow:
# 1. containerd Task Service creates task
# 2. Shim allocated with PTY
# 3. runc spawns /bin/bash with PTY attached
# 4. User's terminal ←→ shim ←→ /bin/bash streams connected
# 5. Exit bash → shim reports exit code
```

**Pattern 2: Daemonized Service Container**
```bash
docker run -d nginx:latest

# Flow:
# 1. containerd Task Service creates task
# 2. Shim allocated WITHOUT PTY (normal pipes)
# 3. runc spawns nginx master process
# 4. containerd detached (returns immediately)
# 5. Shim stays running, monitoring child processes
# 6. nginx: master → worker processes continue executing independently
```

**Pattern 3: Exec into Running Container**
```bash
docker exec -it container_id /bin/sh

# Flow:
# 1. Docker API calls containerd: "Exec in this task"
# 2. containerd contacts shim: "Start new process in existing namespace"
# 3. Shim forks child process with SAME namespaces as container init
# 4. New process joins container's pid, network, ipc namespaces
# 5. User terminal connected to new process stdin/stdout/stderr
#    (Not to container init; separate I/O stream)
# 6. Exit new process; container still running
```

#### DevOps Best Practices

**1. Monitor Shim Processes**
```bash
# All shims should be running
ps aux | grep containerd-shim

# Expected output (one line per running container):
root  1234  0.0  0.0  20480  2048 ?  Ss  10:30  0:00 /usr/bin/containerd-shim-runc-v2 ...
root  5678  0.0  0.1  20512  4096 ?  Ss  10:30  0:00 /usr/bin/containerd-shim-runc-v2 ...
```

**2. Check Shim/containerd Connection**
```bash
# containerd state directory
ls -la /run/containerd/runc/*/state.json

# Shim directories
ls -la /run/containerd/*/

# Metrics (if available)
ctr tasks list  # Should match running containers
docker ps      # Should match ctr tasks list
```

**3. Handle Shim Zombie Processes**
```bash
# Orphaned shims should not exist, but if they do:
ps aux | grep defunct  # Zombie processes

# Root cause: containerd crashed without graceful shutdown
# Prevention:
#  - Always use systemctl stop containerd (not kill -9)
#  - Enable live-restore in daemon.json
#  - Monitor containerd restarts

# Recovery:
systemctl restart containerd
# Shims re-register with newly-started containerd
```

**4. Resource Limits on Shim Itself**
```bash
# Shim resource footprint
# Baseline: ~10MB per shim
# Scale calculation: num_containers * 10MB

# If shims consuming excessive memory:
# 1. Check for memory leaks in containerd
# 2. Limit shim spawning rate (prevent fork bombs)
# 3. Monitor shim process memory: top, /proc/[pid]/smaps
```

#### Common Pitfalls

**Pitfall 1: Orphaned Shims After Daemon Crash**
```bash
# Symptoms:
# - docker ps shows no containers
# - ps aux shows shim processes running
# - /var/run/docker.sock unresponsive

# Root cause:
# daemon crashed without graceful shutdown
# shims disconnected and orphaned
# containerd database not synced

# Prevention:
# Enable live-restore=true
systemctl restart docker  # Safe; shims stay running
```

**Pitfall 2: Namespace Pollution**
```bash
# Symptoms:
# - docker exec shows wrong processes
# - Network connectivity issues within container
# - PID namespace not isolated

# Root cause:
# Shim failed to properly join namespaces when forking exec process
# Or: namespace cleanup incomplete

# Prevention:
# Ensure execProc properly sets up namespaces
# Validate namespace isolation: docker inspect <container> | grep Pid
```

**Pitfall 3: I/O Stream Deadlock**
```bash
# Symptoms:
# - docker logs hangs indefinitely
# - Container appears running but unresponsive
# - Shim process using high CPU

# Root cause:
# Shim pipe buffers full (stdout/stderr not drained)
# Or: circular I/O dependency

# Prevention:
# - Ensure application doesn't write excessively to stdout
# - Configure log rotation/buffering
# - Use non-blocking I/O in shim

# Recovery:
docker kill <container>  # Force-kill shim connection
```

**Pitfall 4: Exit Code Loss**
```bash
# Symptoms:
# docker ps -a shows exit code as 0 even though process crashed
# No error indication in Docker API

# Root cause:
# Shim didn't properly capture exit code from runc
# Or: race condition in signal handling

# Prevention:
# Ensure shim implementation captures ALL exit paths
# Test with explicit exit codes: docker run exit_code_test
# Validate: docker inspect <exited_container> | grep ExitCode
```

---

### Practical Code Examples

#### Example 1: Monitor Task Service Activity
```bash
#!/bin/bash
# monitor-containerd-tasks.sh

echo "=== containerd Task Service Status ==="

# Check containerd daemon running
systemctl is-active containerd
echo "containerd status: $(systemctl is-active containerd)"

echo ""
echo "=== Running Shim Processes ==="
ps aux | grep containerd-shim | grep -v grep | awk '{
  print "PID: " $2 ", Memory: " $6 "KB, Command: " $11 " " $12 " " $13
}'

echo ""
echo "=== Tasks via containerd CLI ==="
ctr tasks list 2>/dev/null || echo "ctr command not available"

echo ""
echo "=== Task State Files ==="
if [ -d /run/containerd/runc ]; then
  find /run/containerd/runc -name "state.json" -exec sh -c '
    echo "State file: {}"
    cat {} | jq ".id, .status, .pid" 2>/dev/null
  ' \;
fi

echo ""
echo "=== Orphaned Shims (no parent containerd) ==="
ps aux | grep containerd-shim | grep -v grep | while read line; do
  pid=$(echo $line | awk '{print $2}')
  ppid=$(ps -o ppid= -p $pid)
  if ! ps -p $ppid > /dev/null 2>&1; then
    echo "Orphaned: PID $pid (parent $ppid not found)"
  fi
done
```

**Usage:**
```bash
chmod +x monitor-containerd-tasks.sh
./monitor-containerd-tasks.sh
```

#### Example 2: Inspect Task Execution Details
```bash
#!/bin/bash
# inspect-task-execution.sh

CONTAINER_ID=$1
if [ -z "$CONTAINER_ID" ]; then
  echo "Usage: $0 <container_id_or_name>"
  exit 1
fi

echo "=== Task Execution Details for $CONTAINER_ID ==="

# Get full container info
echo ""
echo "--- Docker Inspect ---"
docker inspect $CONTAINER_ID | jq '{
  ID: .Id,
  State: {
    Pid: .State.Pid,
    Running: .State.Running,
    ExitCode: .State.ExitCode,
    Status: .State.Status,
    StartedAt: .State.StartedAt
  },
  Namespaces: .HostConfig.Ipc,
  PidMode: .HostConfig.PidMode,
  NetworkMode: .HostConfig.NetworkMode
}'

# Get actual process info from host
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_ID)

if [ ! -z "$CONTAINER_PID" ] && [ "$CONTAINER_PID" != "0" ]; then
  echo ""
  echo "--- Host-side Process Info (PID $CONTAINER_PID) ---"
  ps -o pid,ppid,cmd -p $CONTAINER_PID
  
  echo ""
  echo "--- Namespace Mounts ---"
  ls -la /proc/$CONTAINER_PID/ns/
  
  echo ""
  echo "--- Memory Usage ---"
  cat /proc/$CONTAINER_PID/status | grep VmRSS
  
  echo ""
  echo "--- CPU Usage ---"
  cat /proc/$CONTAINER_PID/stat | awk '{
    print "User time: " $14 " jiffies"
    print "System time: " $15 " jiffies"
    print "Virtual memory: " $23 " bytes"
  }'
fi

# Check for shim process
echo ""
echo "--- Associated Shim Process ---"
ps aux | grep containerd-shim | grep -v grep | while read line; do
  if echo "$line" | grep -q "$CONTAINER_ID"; then
    echo "$line"
  fi
done
```

**Usage:**
```bash
chmod +x inspect-task-execution.sh
./inspect-task-execution.sh <container_name_or_id>
```

#### Example 3: Simulate Task Lifecycle Events
```bash
#!/bin/bash
# demo-task-lifecycle.sh

echo "=== Demonstrating containerd Task Service Lifecycle ==="

# Start container
echo ""
echo "1. CREATE: Starting container..."
CONTAINER=$(docker run -d --name lifecycle-demo ubuntu:20.04 sleep 3600)
echo "   Container created: $CONTAINER"

# Check shim created
echo ""
echo "2. Checking shim process..."
SHIM_PID=$(ps aux | grep containerd-shim | grep $CONTAINER | head -1 | awk '{print $2}')
echo "   Shim PID: $SHIM_PID"

# Inspect running task
echo ""
echo "3. RUNNING: Task details..."
docker inspect $CONTAINER --format='{{json .State}}' | jq '.'

# List processes in container
echo ""
echo "4. Processes inside container..."
docker top $CONTAINER

# Pause task (not all drivers support)
echo ""
echo "5. PAUSED: Pausing container (if supported)..."
docker pause $CONTAINER 2>/dev/null || echo "   Pause not supported"

# Resume task
docker unpause $CONTAINER 2>/dev/null

# Exec new process in task
echo ""
echo "6. EXEC: Executing process inside task..."
docker exec lifecycle-demo echo "New process in running container"

# Stop task
echo ""
echo "7. STOPPING: Stopping container..."
docker stop $CONTAINER

# Check final state
echo ""
echo "8. STOPPED: Final state..."
docker inspect $CONTAINER --format='Status: {{.State.Status}}, ExitCode: {{.State.ExitCode}}'

# Cleanup
docker rm $CONTAINER
echo ""
echo "9. DELETED: Container removed"
```

**Usage:**
```bash
chmod +x demo-task-lifecycle.sh
./demo-task-lifecycle.sh
```

#### Example 4: Task Resource Monitoring Script
```bash
#!/bin/bash
# monitor-task-resources.sh

CONTAINER_ID=$1
if [ -z "$CONTAINER_ID" ]; then
  echo "Usage: $0 <container_id>"
  exit 1
fi

PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_ID)

if [ -z "$PID" ] || [ "$PID" = "0" ]; then
  echo "Container not running or PID unavailable"
  exit 1
fi

echo "=== Task Resource Monitoring - Container PID: $PID ==="
echo "Monitoring for 10 seconds (press Ctrl+C to stop)..."
echo ""

# Header
printf "%-10s %-10s %-12s %-12s %-10s\n" "Time" "RSS(MB)" "VSZ(MB)" "CPU_TIME(s)" "Threads"

for i in {1..10}; do
  timestamp=$(date +"%H:%M:%S")
  
  # RSS (resident set size) - actual physical memory
  rss=$(cat /proc/$PID/status 2>/dev/null | grep ^VmRSS | awk '{print int($2/1024)}')
  
  # VSZ (virtual memory size)
  vsz=$(cat /proc/$PID/status 2>/dev/null | grep ^VmSize | awk '{print int($2/1024)}')
  
  # CPU time
  cpu_time=$(cat /proc/$PID/stat 2>/dev/null | awk '{print int(($14+$15)/100)}')
  
  # Thread count
  threads=$(cat /proc/$PID/status 2>/dev/null | grep ^Threads | awk '{print $2}')
  
  printf "%-10s %-10s %-12s %-12s %-10s\n" "$timestamp" "$rss" "$vsz" "$cpu_time" "$threads"
  
  sleep 1
done
```

**Usage:**
```bash
chmod +x monitor-task-resources.sh
./monitor-task-resources.sh <container_name_or_id>
# Monitor: memory, CPU time, thread count
```

---

### ASCII Diagrams

#### Diagram 1: Shim I/O Stream Multiplexing

```
CONTAINER WITH PTY (Interactive):
═══════════════════════════════════════════════════════════════════

User Terminal (local machine)
  │stdin (user typing)
  │
  ├─→ Docker Client
  │       │
  │       └─→ Docker Daemon API
  │               │
  │               └─→ containerd Task Service
  │                       │
  │                       └─→ Shim Process
  │                           ├─ Multiplexer (handle I/O)
  │                           │
  │                           └─→ Container Process (/bin/bash)
  │                               ├─ stdin ← keyboard input
  │                               ├─ stdout → display output
  │                               └─ stderr → error messages
  │
  └─ Output ← streaming response back through same path


CONTAINER WITHOUT PTY (Daemonized):
═══════════════════════════════════════════════════════════════════

Application (nginx)
  │
  ├─ Daemonizes (child process becomes PID 1)
  │
  ├─ Detaches terminal
  │
  └─ Continues running independently

Shim Process
  │
  ├─ No PTY (no terminal connected)
  │
  ├─ Pipes for I/O (if needed)
  │   ├─ stdin ← /dev/null (no input expected)
  │   ├─ stdout → /var/lib/docker/containers/.../logs (journaled)
  │   └─ stderr → /var/lib/docker/containers/.../logs (journaled)
  │
  └─ Monitors child processes (exit codes, signals)


CONCURRENT STREAMS (docker exec):
═══════════════════════════════════════════════════════════════════

docker exec -it container /bin/sh  (Stream A)
docker exec -i container grep test (Stream B)
docker logs -f container          (Stream C)

Shim manages 3 independent I/O streams:
┌─────────────────────────────┐
│ Shim: containerd-shim-v2    │
│                              │
│ ┌────────────────────────┐   │
│ │ Stream A: Interactive  │   │
│ │  /bin/sh (PID 100)     │   │
│ │  ↔ User terminal       │   │
│ │  ↔ Multiplexed I/O     │   │
│ └────────────────────────┘   │
│                              │
│ ┌────────────────────────┐   │
│ │ Stream B: Non-interact │   │
│ │  grep test (PID 101)   │   │
│ │  ← pipe input          │   │
│ │  → buffer output       │   │
│ └────────────────────────┘   │
│                              │
│ ┌────────────────────────┐   │
│ │ Stream C: Container    │   │
│ │  Main process output   │   │
│ │  → journald/logger     │   │
│ └────────────────────────┘   │
│                              │
│ ┌─ Container Namespace  ─┐   │
│ │  PID 1 (init process)  │   │
│ │  (separate namespace)  │   │
│ └------------------------┘   │
└─────────────────────────────┘
```

#### Diagram 2: Task Lifecycle State Transitions

```
TASK LIFECYCLE WITH EVENT STREAM:
═══════════════════════════════════════════════════════════════════

API Call: docker run -d nginx
              │
              ├─→ Task Service CREATE event
              │   Event: {"Type": "create", "Task": "abc123"}
              │
              ▼
        ┌─────────────┐
        │   CREATED   │ ← Subscribers notified
        └─────────────┘
              │
              ├─→ Task Service START event
              │   Event: {"Type": "start", "Task": "abc123", "Pid": 5678}
              │
              ▼
        ┌─────────────┐
        │   RUNNING   │ ← Kubernetes marks pod Ready
        └─────────────┘
              │
              │ ... (running for days)
              │
              ├─→ PAUSE event (if pause issued)
              │   Event: {"Type": "pause", "Task": "abc123"}
              │
              ▼
        ┌─────────────┐
        │   PAUSED    │
        └─────────────┘
              │
              ├─→ RESUME event
              │   Event: {"Type": "resume", "Task": "abc123"}
              │
              ▼
        ┌─────────────┐  (back to running)
        │   RUNNING   │
        └─────────────┘
              │
              │ ... (running)
              │
              ├─→ EXIT event (process exits)
              │   Event: {"Type": "exit", "Task": "abc123", "ExitCode": 0}
              │
              ▼
        ┌──────────────┐
        │   STOPPED    │ ← Kubernetes marks pod Failed/Successful
        └──────────────┘
              │
              ├─→ DELETE event
              │   Event: {"Type": "delete", "Task": "abc123"}
              │
              ▼
        ┌──────────────┐
        │   DELETED    │ ← Kubernetes removes pod object
        └──────────────┘


EVENT DELIVERY SEQUENCE:
═══════════════════════════════════════════════════════════════════

containerd publishes events:
┌──────────────────────────────────┐
│ Event Stream (FIFO queue)         │
│                                   │
│ 1. create (abc123)                │
│ 2. start (abc123, pid=5678)       │
│ 3. exec (abc123, pid=5679)        │
│ 4. exec_exit (exec_id, code=0)    │
│ 5. exit (abc123, code=0)          │
│ 6. delete (abc123)                │
│                                   │
│ Guarantee: FIFO ordering         │
└──────────────────────────────────┘
         │
         ├─→ Kubernetes kubelet (watches events)
         ├─→ Monitoring system (Prometheus)
         ├─→ Logging system (ELK)
         └─→ Custom subscribers

All subscribers receive same event sequence, in order.
```

#### Diagram 3: Shim Connection Recovery During Daemon Restart

```
NORMAL OPERATION:
═══════════════════════════════════════════════════════════════════

containerd Daemon ←─→ Shim Process ←─→ Container Process
     │                     │                    │
     ├─ API handler        ├─ Monitor child    ├─ Running
     ├─ gRPC server        ├─ Relay I/O        ├─ (nginx, app, etc)
     ├─ Event publisher    ├─ Handle signals   └─ Namespace isolation
     └─ Task manager       └─ Report exit

Communication: Continuous (shim reports process state changes)


DAEMON CRASH:
═══════════════════════════════════════════════════════════════════

containerd Daemon                Shim Process → Container Process
     │ (crash!)                    │              │
     ├─ All goroutines stopped    ├─ Still       ├─ Still
     ├─ Sockets closed            │  monitoring  │  running!
     ├─ Database unstable         │  child       ├─ No crash
     └─ Connections lost          │  process     └─ (isolated)
                                  │
                                  └─ Can't communicate with daemon
                                     (but container unaffected)


DAEMON RESTART:
═══════════════════════════════════════════════════════════════════

containerd Daemon (restarted)
     │
     ├─ Load state from disk
     │  (previous tasks stored in /run/containerd/state.json)
     │
     ├─ Iterate through recorded tasks
     │  Each task has metadata: {id, bundleDir, shim_address, ...}
     │
     ├─→ For each task: "Shim, are you still running?"
     │   (connect via shim address socket)
     │
     ├─ Shim responds: "Yes! Container still running, PID=5678"
     │   ├─ Reports container stats
     │   ├─ Provides I/O pipes
     │   └─ Streams future events
     │
     └─→ Task re-registered in memory database
         ├─ docker ps now shows container again
         ├─ Kubernetes kubelet sees ready container
         └─ Event stream resumed (new events published)


STATE RECOVERY FLOW:
═══════════════════════════════════════════════════════════════════

Before crash:
┌─────────────────────────────┐
│ containerd database         │
│ (memory)                    │
│                              │
│ Task: abc123                │
│  ├─ Status: running         │
│  ├─ Pid: 5678               │
│  ├─ Shim socket: X          │
│  └─ Config: {...}           │
└─────────────────────────────┘

After crash (no live-restore):
┌──────────────────────┐
│ containerd daemon    │
│ (restarted fresh)    │
│                      │
│ Database: EMPTY!     │
│ (lost memory)        │
│                      │
│ Shim: still alive    │
│ Container: still     │
│   running (orphaned) │
└──────────────────────┘

With live-restore enabled:
┌──────────────────────┐
│ containerd daemon    │
│ (restarted)          │
│                      │
│ Load persisted tasks │
│ from state.json      │
│                      │
│ Shim still alive ✓   │
│ Container still      │
│   running ✓          │
│                      │
│ Reconnect to all     │
│ shims → restore      │
│ database from disk  │
└──────────────────────┘
```

---

## Revisiting Table of Contents

The study guide now includes comprehensive deep-dive sections. Update the Table of Contents as follows:

---

## Updated Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Architecture Overview](#architecture-overview)
   - [Docker Engine Components](#docker-engine-components)
   - [Container Runtime Standards](#container-runtime-standards)
   - [Communication Protocols](#communication-protocols)
   - [DevOps Principles & Best Practices](#devops-principles--best-practices)
   - [Common Misconceptions](#common-misconceptions)
3. [Docker Engine Components](#docker-engine-components-detailed)
   - [Docker Daemon](#docker-daemon)
   - [Docker Client](#docker-client)
   - [Docker API](#docker-api)
   - [Container Runtime](#container-runtime)
   - [containerd](#containerd)
   - [runc](#runc)
   - [Docker CLI](#docker-cli)
4. **[Deep Dive: Docker Daemon Storage Architecture](#deep-dive-subtopic-1---docker-daemon-storage-architecture)**
   - [Textual Deep Dive](#textual-deep-dive)
   - [Practical Code Examples](#practical-code-examples)
   - [ASCII Diagrams](#ascii-diagrams)
5. **[Deep Dive: containerd Task Service & Shim Architecture](#deep-dive-subtopic-2---containerd-task-service--shim-architecture)**
   - [Textual Deep Dive](#textual-deep-dive-1)
   - [Practical Code Examples](#practical-code-examples-1)
   - [ASCII Diagrams](#ascii-diagrams-1)
6. [Hands-on Scenarios](#hands-on-scenarios)
7. [Interview Questions](#interview-questions)

1. **Diagnose** daemon behavior by understanding component responsibilities
2. **Architect** multi-daemon, HA, and secure deployments
3. **Optimize** performance by tuning each layer appropriately
4. **Debug** issues across API, daemon, runtime, and kernel layers
5. **Plan upgrades** and migrations with live-restore and shim-based resilience

The next study sections should cover Docker networking architecture, storage drivers, and image distribution systems.
