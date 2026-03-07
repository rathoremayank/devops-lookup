# Docker Images & Layers: Senior DevOps Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Image Layers & Caching](#image-layers--caching)
4. [Immutability & Versioning](#immutability--versioning)
5. [SHA Digests, Manifests & Content Addressability](#sha-digests-manifests--content-addressability)
6. [Docker Registries & Repositories, Structure & Distribution](#docker-registries--repositories-structure--distribution)
7. [Base Image Strategies](#base-image-strategies)
8. [Hands-on Scenarios](#hands-on-scenarios)
9. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Docker Images are immutable blueprints used to create containers—self-contained, executable packages that include application code, runtime, system tools, libraries, and settings. At their core, Docker images are constructed from multiple **layers**—a fundamental architectural concept that differentiates Docker from traditional virtual machine snapshots.

Understanding Docker images and layers is essential for DevOps engineers because:

- **Image Optimization**: Layers determine build performance, download speeds, and storage efficiency across registries
- **Security & Compliance**: Layer composition impacts vulnerability management and supply chain security
- **Resource Efficiency**: Proper layer organization reduces artifact size by 50-80% in production environments
- **Reproducibility & Reliability**: Layer immutability ensures consistency across development, staging, and production pipelines

### Why It Matters in Modern DevOps Platforms

#### 1. **Supply Chain Security**
In modern DevOps, container images are critical components of your infrastructure supply chain. The layered architecture enables:
- Fine-grained vulnerability scanning at each layer
- Traceability of dependencies and their provenance
- Attestation and signing of individual layers
- Compliance with frameworks like SLSA and NIST guidelines

#### 2. **Performance & CI/CD Efficiency**
Layer caching mechanisms directly impact pipeline performance:
- Build time can be reduced from minutes to seconds through intelligent layer ordering
- Registry operations (push/pull) are optimized through layer deduplication
- Content-addressable storage ensures only changed layers are transferred
- Multi-stage builds reduce final artifact size by leveraging layer inheritance

#### 3. **Registry & Infrastructure Operations**
In production environments managing thousands of images:
- Layer deduplication across images saves terabytes of storage
- SHA digests enable verifiable, immutable references to exact image versions
- Multi-architecture support (AMD64, ARM64, s390x) requires manifest management
- Layer distribution across geographic regions affects deployment latency

#### 4. **Kubernetes & Container Orchestration**
Kubernetes scheduling and runtime operations depend on image properties:
- Image pull policies interact with layer availability and caching
- Private registry authentication requires understanding image manifests
- Node image GC policies interact with layer distribution
- Image signature verification requires manifest understanding

### Real-World Production Use Cases

#### Case Study 1: Large-Scale Deployment Acceleration
A major financial services organization reduced deployment time by 65% by:
- Reorganizing Dockerfile instructions to optimize layer cache hits
- Using multi-stage builds to reduce final image size from 1.2GB to 180MB
- Implementing base image scanning to detect vulnerabilities before application layers
- Leveraging registry layer deduplication across 500+ production images

#### Case Study 2: Supply Chain Security Implementation
A healthcare technology company implemented layer-based security controls:
- Scanning each layer independently to identify vulnerability origins
- Signing base image layers separately from application layers for attestation
- Implementing layer-level retention policies for compliance (HIPAA, SOC2)
- Enabling rollback to specific base image versions without rebuilding applications

#### Case Study 3: Registry Optimization at Scale
A cloud platform provider managing millions of container deployments:
- Utilized SHA digest immutability to deduplicate 2.5PB of storage across regions
- Implemented layer distribution across edge registries (CDN-style) for 200ms faster pulls
- Built automated layer dependency analysis to enforce minimal base image policies
- Achieved 99.7% cache hit rate on CI/CD builds through layer strategy optimization

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Developer Workstation                    │
│  (Builds images using Dockerfile → Creates layers)          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                   CI/CD Pipeline                             │
│  (Layer caching, image scanning, manifest generation)       │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Container Registry (DockerHub, ECR, etc.)       │
│  (Stores layers, manifests, SHA digests, distributions)     │
└──────────────────────┬──────────────────────────────────────┘
                       │
      ┌────────────────┼────────────────┐
      ▼                ▼                ▼
 Kubernetes        Docker Swarm    Nomad Clusters
 (Pull layers)   (Pull layers)   (Pull layers)
 
 ▼ Layer Distribution
┌─────────────────────────────────────────────────────────────┐
│         Runtime Environment (Containers execute)             │
│  (Layers mounted as read-only filesystem layers)            │
└─────────────────────────────────────────────────────────────┘
```

---

## Foundational Concepts

### Key Terminology

#### **Layer**
A read-only filesystem snapshot created by each Dockerfile instruction. Layers are stacked using a union filesystem (OverlayFS, AUFS, btrfs) to create the final image filesystem.

**Example**: Each `FROM`, `RUN`, `COPY`, and `ADD` instruction contributes one layer.

#### **Image**
A packaged collection of layers, metadata (environment variables, entrypoint commands), and a manifest describing how to assemble them. Images are identified by a repository name and tag (e.g., `myapp:v1.2.3`).

#### **Container**
A running instance of an image. Containers add a single writable layer (container layer) on top of the read-only image layers.

#### **SHA256 Digest**
A cryptographic hash (e.g., `sha256:abc123...`) that uniquely identifies a layer or image. Unlike tags (which can move between versions), digests are immutable and content-addressable.

**Example**: 
```
Image ID:  myapp:latest → sha256:e3b0c44298fc1c14... (always points to exact content)
Layer ID:  sha256:2c26b46911185... → represents exact RUN instruction output
```

#### **Manifest**
A JSON document describing an image's structure: which layers it contains (in order), their sizes, digests, and configuration metadata (environment, expose ports, etc.).

#### **Registry**
A centralized server storing images organized into repositories. Examples: Docker Hub, Amazon ECR, Google GCR, Azure ACR, private registries.

#### **Union Filesystem**
A technology that layers multiple filesystem snapshots into a single view. Changes in upper layers shadow (hide) identical files in lower layers.

### Architecture Fundamentals

#### **Layered Architecture Model**

Docker images use a **copy-on-write (CoW)** strategy with union filesystems:

```
┌────────────────────────────┐
│  Layer N (COPY app.jar)    │  <- Reads/writes go here first
├────────────────────────────┤
│  Layer 3 (RUN apt-get)     │  
├────────────────────────────┤
│  Layer 2 (ADD config)      │
├────────────────────────────┤
│  Layer 1 (From ubuntu)     │  <- Base layer (foundational)
└────────────────────────────┘
```

**Key principle**: When a container reads a file, the union filesystem checks layers from top to bottom and returns the first match. This enables efficient deduplication—if Layer 1 contains a 500MB library, and Layer 2-N never modify it, all containers share the same 500MB across memory and disk.

#### **Image Composition**

Every image comprises:

```json
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:..."],
    "Cmd": ["/bin/bash"],
    "WorkingDir": "/app",
    "Expose": [8080]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:layer1_digest",
      "sha256:layer2_digest",
      "sha256:layer3_digest"
    ]
  }
}
```

The `config` section contains:
- **Environment variables** (inherited from base images, overridable at runtime)
- **Entrypoint/Cmd** (default execution command)
- **User** (UID/GID for container process)
- **WorkingDir** (default directory)
- **Expose** (documented ports—informational only, doesn't actually publish)
- **Volumes** (documented mount points)

#### **Layer Lifecycle**

```
Dockerfile Instruction → Intermediate Container Created → Layer Generated → Intermediate Container Removed
                    │
                    └─→ Layer digest computed (SHA256 of changes)
                    └─→ Layer stored in image store (/var/lib/docker/overlay2/)
```

Each Dockerfile instruction that modifies the filesystem creates one layer:
- `FROM ubuntu:22.04` → Creates Layer 1 (union of base image layers)
- `RUN apt-get update && apt-get install -y curl` → Creates Layer 2
- `COPY myapp.jar /opt/` → Creates Layer 3
- Instructions like `ENV`, `LABEL`, `EXPOSE` modify image metadata, not layers

### Important DevOps Principles

#### **1. Immutability Principle**
Docker images are **immutable artifacts**—once a layer is created, it cannot be modified. This differs from VMs where you modify in-place.

**DevOps Impact**:
- **Auditability**: Changes require new image builds; all modifications are traceable
- **Rollback Safety**: Previous versions remain available in registries indefinitely
- **Consistency**: The same image hash always runs identically across environments
- **Security**: Compromised image versions can be identified and replaced deterministically

#### **2. Composition Over Inheritance**
Rather than large monolithic images, modern DevOps uses:
- **Multi-stage builds** (separate build and runtime images)
- **Base image inheritance** (application images build from curated base images)
- **Sidecar containers** (logging, monitoring as separate images)

This enables:
- Smaller footprints (dev dependencies removed in final layer)
- Version stability (base images updated independently)
- Security boundaries (application runs with minimum privileges)

#### **3. Content Addressability Principle**
Docker uses **content-based addressing** (SHA256 digests) rather than mutable tags:
- Tags like `latest` can point to different images over time
- Digests like `sha256:abc123...` always reference the exact same content
- This enables **reproducible deployments** and **auditability**

**DevOps Impact**:
- In CI/CD pipelines, record image digests (not tags) for exact version tracking
- Use digest-pinned deployments for security (prevents unexpected base image updates)
- Enable Kubernetes imagePolicy webhooks to enforce digest-pinned images

#### **4. Least Privilege Principle**
Each image layer should contain only what the next layer needs:
- Remove build tools and temporary files before final layers
- Use minimal base images (Alpine 5MB vs Ubuntu 70MB)
- Don't include documentation or test files in production images

**DevOps Impact**:
- Reduces attack surface (fewer binaries = fewer CVEs)
- Faster deployments (smaller downloads)
- Lower storage costs at scale

#### **5. Caching Optimization Principle**
Layer caching is a primary source of build performance:
- Frequently changing instructions should come late in Dockerfile
- Early instructions should be stable (base image, system dependencies)
- Cache invalidation cascades—one changed instruction rebuilds all subsequent layers

**DevOps Impact**:
- Well-structured Dockerfiles build in seconds (cached) vs. minutes (uncached)
- CI/CD pipelines see 10-100x speedup with optimized caching
- Reduces build infrastructure costs and developer wait times

### Best Practices

#### **1. Dockerfile Instruction Ordering**
Order instructions from least frequently changed to most:

```dockerfile
# ✅ Recommended
FROM python:3.11-slim
RUN apt-get update && apt-get install -y postgresql-client  # System deps (stable)
COPY requirements.txt .                                      # Dependencies (stable)
RUN pip install -r requirements.txt                          # Dependencies (stable)
COPY myapp/ /app/                                            # Application code (changes often)
CMD ["python", "app.py"]
```

```dockerfile
# ❌ Anti-pattern
FROM python:3.11-slim
COPY myapp/ /app/                    # Application code first → cache miss on every code change
RUN pip install -r requirements.txt  # This entire layer rebuilds
COPY requirements.txt .
RUN apt-get update && apt-get install postgresql-client
CMD ["python", "app.py"]
```

#### **2. Multi-Stage Build Pattern**
Separate build and runtime stages to exclude build tools from final image:

```dockerfile
# Build stage
FROM golang:1.21 AS builder
WORKDIR /tmp
COPY . .
RUN go build -o myapp .

# Runtime stage
FROM alpine:3.18
COPY --from=builder /tmp/myapp /usr/local/bin/
CMD ["myapp"]
```

**Result**: Final image includes only the 15MB binary, not the 800MB Go SDK.

#### **3. Layer Deduplication Awareness**
Understand how registries deduplicate layers:

```
Image A: ubuntu:22.04 + app1.jar + dependencies
Image B: ubuntu:22.04 + app2.jar + dependencies  ← ubuntu layer reused (not duplicated)
Image C: ubuntu:22.04 + app3.jar + dependencies  ← ubuntu layer reused (not duplicated)
```

If you have 1,000 images all using `ubuntu:22.04`, the base layers are stored once in the registry.

#### **4. Version Pinning**
Always pin base image versions for reproducibility:

```dockerfile
# ✅ Pinned version
FROM python:3.11.2-slim-bullseye
```

```dockerfile
# ❌ Floating version (unpredictable)
FROM python:3.11-slim  # Could be 3.11.0 or 3.11.7 depending on when pulled
```

#### **5. Layer Size Monitoring**
Tools like `dive` and `docker history` help identify bloated layers:

```bash
docker history myapp:v1.0
# Shows size contribution of each layer
```

Aim for optimal balance:
- Base layers: 5-100MB (alpine to ubuntu)
- Application layers: 50-500MB (depends on payload)
- Total: < 1GB for most applications (2-5GB for data-intensive)

### Common Misunderstandings

#### **Misunderstanding 1: "Layers = Files"**
**Incorrect**: "I have 5 files, so I'll have 5 layers"

**Reality**: Layers are created by Dockerfile instructions, not input files. Ten `COPY` instructions = ten layers, even if copying small files.

**Impact**: Developers sometimes create inefficient Dockerfiles with unnecessary RUN instructions:
```dockerfile
# ❌ Creates 5 layers (inefficient)
RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# ✅ Creates 1 layer (efficient)
RUN apt-get update && apt-get install -y wget curl git && apt-get clean
```

#### **Misunderstanding 2: "Docker Tags Are Like Git Tags"**
**Incorrect**: "The `ubuntu:22.04` tag always points to the same image"

**Reality**: Tags are mutable pointers. `ubuntu:22.04` might point to different digests across time as security patches are released. This causes non-deterministic deployments:

```
Day 1: ubuntu:22.04 → sha256:abc123...
Day 7: ubuntu:22.04 → sha256:def456...  (security patch released)
Deployment is NOT identical if you pull without pinning digests
```

**DevOps Solution**: Use digest-pinned images:
```dockerfile
FROM ubuntu:22.04@sha256:abc123def456...  # Immutable reference
```

#### **Misunderstanding 3: "Deleting a File Removes That Layer"**
**Incorrect**: "If I `RUN rm -rf /tmp/bigfile` in the next layer, the previous layer's bigfile is deleted and space freed"

**Reality**: All layers are immutable and read-only. Deletion in layer N doesn't remove data from layer N-1; it just means the file is shadowed (hidden) by the deletion marker in layer N.

```
Layer 1: /tmp/bigfile (1GB)
Layer 2: RUN rm -rf /tmp/bigfile  # Shadows the file, but 1GB still exists in Layer 1
Final Image Size: ~1GB (not freed)
```

**DevOps Solution**: Remove files in the same instruction:
```dockerfile
# ✅ Correct
RUN wget large-file.tar.gz && tar xzf large-file.tar.gz && rm large-file.tar.gz
# File never persists to a layer; only extracted contents remain

# ❌ Incorrect
RUN wget large-file.tar.gz && tar xzf large-file.tar.gz
RUN rm large-file.tar.gz  # Previous layer still contains the archive
```

#### **Misunderstanding 4: "Container Layer Persists After Container Stops"**
**Incorrect**: "Changes made to `/etc/config` inside a running container are automatically persisted to the image"

**Reality**: The writable container layer exists only while the container runs. When stopped, the layer is not automatically committed to the image.

```bash
docker run ubuntu:22.04 /bin/bash -c "echo 'data' > /data.txt"
docker ps -a | grep ubuntu  # Container is stopped
docker run ubuntu:22.04 /bin/bash -c "cat /data.txt"  # File doesn't exist
# New container is created from the same image layers; the previous container's changes are lost
```

**DevOps Solution**: Use `docker commit` explicitly (rarely used in modern workflows) or rebuild the image:
```bash
docker commit <container-id> myapp:v1.1  # Commits container layer as new image
# But this is considered anti-pattern; Dockerfiles are the source of truth
```

#### **Misunderstanding 5: "Registry Storage is Just a Database"**
**Incorrect**: "All 500 of my images take 500 × 500MB space in the registry"

**Reality**: Registries implement **content-addressable storage** where identical layers are stored once and referenced by multiple images:

```
Image alpine-app:v1    Content = layers A, B, C
Image alpine-app:v2    Content = layers A, B, D
Image centos-app:v1    Content = layers A, E, F

Registry storage:
  Layer A: 20MB (referenced 3 times, stored once)
  Layer B: 15MB (referenced 2 times, stored once)
  Layer C: 30MB (referenced 1 time)
  Layer D: 25MB (referenced 1 time)
  Layer E: 50MB (referenced 1 time)
  Layer F: 40MB (referenced 1 time)
  
Total: 180MB (not 1,500MB)
```

**DevOps Impact**: Using common base images (`ubuntu`, `alpine`, etc.) reduces registry storage costs dramatically.

#### **Misunderstanding 6: "Layer Caching Works Automatically"**
**Incorrect**: "Docker automatically caches my layers, so builds are always fast"

**Reality**: Docker caches only **unchanged instructions and their inputs**. If a Dockerfile is restructured or if intermediate file content changes, the cache misses:

```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl  # Layer cached (stable)
COPY . /app/                                    # Cache misses if ANY file in . changed
RUN cd /app && make                             # Cache misses (dependency)
```

Adding a 1-byte comment to a source file invalidates the cache for `COPY` and everything after it.

**DevOps Solution**: 
- Use `.dockerignore` to exclude files that shouldn't trigger cache invalidation
- Copy only necessary files (e.g., `COPY requirements.txt .` before `COPY . /app/`)
- Understand parent layer stability

---

## Image Layers & Caching

### Textual Deep Dive

#### Internal Working Mechanism

Docker's layer caching is built on **content-based addressing** and **build context analysis**:

1. **Build Context Scanning**: When a build executes, Docker reads each instruction and computes a checksum of:
   - The Dockerfile instruction itself
   - The parent layer's digest
   - For `COPY`/`ADD` instructions: The cryptographic hash of all files being copied

2. **Cache Key Generation**: Docker creates a cache key using:
   ```
   Cache Key = SHA256(parent_layer_digest + instruction + file_content_hashes)
   ```

3. **Cache Lookup**: Before executing an instruction, Docker checks if a layer with this cache key exists:
   - **Cache Hit**: Use the existing layer (no execution needed)
   - **Cache Miss**: Execute the instruction, compute new layer digest, store in cache

4. **Cache Invalidation**: The cache is **linear and atomic**—if one instruction misses the cache, all subsequent instructions rebuild even if their content hasn't changed.

#### Architecture Role

Layer caching is the **primary performance optimization** in Docker builds:

```
Cached Build Path          vs.           Non-Cached Build Path
──────────────────────────────────────────────────────────────
FROM ubuntu → 0.1s (cached)              FROM ubuntu → 15s (download + extract)
RUN apt-get → 0.05s (cached)             RUN apt-get → 45s (package update)
COPY app → 0.2s (cache miss) ────┐        COPY app → 2s
RUN build → 25s (rebuilds)        │       RUN build → 60s
────────────────────────────────────      
Total: ~25s                               Total: ~122s
Cache saves 80% build time!
```

**Architectural benefit**: Container images enable **incremental builds** (similar to compiled languages), not **full rebuilds** (like traditional VMs).

#### Production Usage Patterns

##### Pattern 1: Layer Caching in CI/CD Pipelines

Modern CI/CD exploits caching by:
- **Pulling the latest image** before building (provides base cache layer)
- **Building with `--cache-from` flag** to reference external cache sources
- **Reusing registry-stored layers** across multiple machines

```bash
# Producer job: Build and push
docker build -t myapp:latest .
docker push myapp:latest

# Consumer job (on different machine): Use cache
docker pull myapp:latest  # Fetch cache layers before building
docker build --cache-from myapp:latest -t myapp:newfeature .
```

**DevOps Impact**: Distributed teams see identical build performance whether building locally or in CI.

##### Pattern 2: BuildKit and Advanced Caching

Docker BuildKit introduces:
- **Inline cache export**: Store cache metadata with pushed images
- **Max unused cache lifetime**: Automatically clean aged cache entries
- **Parallel builds**: Execute independent stages simultaneously

```bash
docker buildx build \
  --push \
  --cache-to type=registry,ref=myapp:buildcache \
  --cache-from type=registry,ref=myapp:buildcache \
  -t myapp:v1.0 .
```

##### Pattern 3: Cache Busting Strategies

Production teams intentionally bust cache when needed:

```dockerfile
# Force rebuild every time (for CI/CD nightly builds)
RUN echo "Build $(date +%s)" && apt-get update && apt-get upgrade -y

# Cache only security updates (stable base, updated app)
RUN apt-get update && apt-get install -y --no-install-recommends curl
COPY . /app/  # This layer changes frequently; all layers after it rebuild
```

#### DevOps Best Practices

##### 1. Order Instructions by Stability

```dockerfile
# ✅ Optimal: Stable → Changing
FROM python:3.11
RUN apt-get update && apt-get install -y postgresql-client
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . /app/
CMD ["python", "app.py"]

# Each team member's code edits only touch the last COPY layer
# All earlier layers remain cached
```

##### 2. Use `.dockerignore` to Prevent False Cache Misses

```dockerignore
# Files that change frequently but are irrelevant to image
.git
.gitignore
.env.*
*.log
README.md
CHANGELOG.md
node_modules/  # For dependency layers, use COPY package.json first
```

Without `.dockerignore`, a documentation update triggers a full rebuild.

##### 3. Leverage Multi-Stage Builds for Cache Efficiency

```dockerfile
# Stage 1: Builder (large, contains compilers)
FROM golang:1.21 AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download  # Cached separately from source
COPY . .
RUN CGO_ENABLED=0 go build -o myapp .

# Stage 2: Runtime (small, cached independently)
FROM alpine:3.18
COPY --from=builder /src/myapp /usr/local/bin/
CMD ["myapp"]
```

Benefits:
- `RUN go mod download` caches dependency resolution
- Build tools (Go SDK, compilers) never reach final image
- Runtime stage caches independently; rebuilding app only affects final stages

##### 4. Minimize Network Calls Per Layer

```dockerfile
# ❌ Anti-pattern: Multiple RUN statements (each is a separate layer)
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
RUN apt-get clean

# ✅ Optimized: Single layer with all operations
RUN apt-get update && \
    apt-get install -y \
      curl \
      wget \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

Each `RUN` creates a layer; single `RUN` with `&&` executes in one layer.

#### Common Pitfalls

##### Pitfall 1: Cache Invalidation Due to `ADD` Instruction

```dockerfile
# ❌ Problematic: ADD checks timestamp, not just content
FROM ubuntu:22.04
ADD https://example.com/data.tar.gz /tmp/  # Always fetches, busts cache even if unchanged
RUN tar xzf /tmp/data.tar.gz

# ✅ Better: Use RUN with curl for determinism
FROM ubuntu:22.04
RUN curl -sO https://example.com/data.tar.gz \
    && tar xzf data.tar.gz \
    && rm data.tar.gz
```

The `ADD` instruction from URLs is rebuilt on every build (no deterministic caching).

##### Pitfall 2: Building Without Considering the Image Cache Location

```bash
# ❌ Problem: Different machines, no shared cache
docker build -t myapp:v1 .  # Machine A
docker build -t myapp:v1 .  # Machine B (no cache from A)
```

**Solution**: Push/pull latest tag to/from registry before building:

```bash
docker pull myapp:latest || true
docker build --cache-from myapp:latest -t myapp:v1 .
docker push myapp:v1
```

##### Pitfall 3: Assuming Cache Works Across Context Changes

```bash
# First run
docker build -t myapp:v1 .  # Cache created

# Same Dockerfile, but different working directory
cd /other/path
docker build -f /original/Dockerfile -t myapp:v2 .  # Cache MISS!
```

Docker uses absolute file paths and build context; different directories = different cache.

##### Pitfall 4: Secret Handling Busts Cache

```dockerfile
# ❌ Problem: ARG changes every build
ARG BUILD_TOKEN  # User provides --build-arg BUILD_TOKEN=secret
RUN curl -H "Authorization: Bearer $BUILD_TOKEN" https://api.example.com/build

# Every different token invalidates cache for this and subsequent layers
```

**Solution**: Use BuildKit's secret mount (doesn't affect cache):

```dockerfile
# With --secret flag, cache is unaffected
RUN --mount=type=secret,id=token \
    curl -H "Authorization: Bearer $(cat /run/secrets/token)" https://api.example.com/build
```

---

### Practical Code Examples

#### Example 1: Optimized Python Application Build

```dockerfile
# Dockerfile.optimized
FROM python:3.11-slim

# System dependencies (rarely changes)
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and install requirements (changes when dependencies update)
COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code (changes on every commit)
COPY . .

# Verify application
RUN python -m py_compile src/app.py

CMD ["python", "src/app.py"]
```

**Cache behavior**:
1. First build: All layers execute (10-15 seconds)
2. Source code change only: Only final `COPY` and layers after it rebuild (2-3 seconds)
3. Dependency change: `RUN pip install` and after rebuild (5-10 seconds)
4. Base image change: Full rebuild (10-15 seconds)

#### Example 2: Build Cache Inspection Script

```bash
#!/bin/bash
# inspect_cache.sh - Analyze layer cache status

IMAGE_TAG="${1:-myapp:latest}"

echo "=== Docker Build Cache Analysis for $IMAGE_TAG ==="
echo

# List all layers with sizes
docker history --no-trunc "$IMAGE_TAG" | awk '{
    if (NR > 1) {
        size = $2
        cmd = substr($0, index($0, $5))
        printf "%-10s  %-80s\n", size, cmd
    }
}' | column -t

echo
echo "=== Total Image Size ==="
docker images --no-trunc | grep "$IMAGE_TAG" | awk '{print $7}'

echo
echo "=== Layer Digest Information ==="
docker inspect "$IMAGE_TAG" --format='{{json .RootFS.Layers}}' | jq '.[]' | head -5

```

**Usage**:
```bash
./inspect_cache.sh myapp:latest
```

#### Example 3: CI/CD Pipeline with Cache Management

```bash
#!/bin/bash
# ci-build-with-cache.sh

set -e

IMAGE_NAME="myapp"
REGISTRY="docker.io"
BUILD_TAG="${REGISTRY}/${IMAGE_NAME}:latest"
FEATURE_TAG="${REGISTRY}/${IMAGE_NAME}:feature-${CI_COMMIT_SHA:0:8}"

echo "Step 1: Authenticate to registry"
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin "$REGISTRY"

echo "Step 2: Pull latest image for cache"
docker pull "$BUILD_TAG" || echo "No prior image; starting fresh"

echo "Step 3: Build with cache"
docker build \
  --cache-from "$BUILD_TAG" \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VCS_REF="$CI_COMMIT_SHA" \
  --label "org.opencontainers.image.revision=$CI_COMMIT_SHA" \
  --label "org.opencontainers.image.created=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  -t "$FEATURE_TAG" \
  .

echo "Step 4: Verify image"
docker run --rm "$FEATURE_TAG" --version

echo "Step 5: Push for feature validation"
docker push "$FEATURE_TAG"

echo "✓ Build complete: $FEATURE_TAG"
```

#### Example 4: Cache Statistics Collection

```bash
#!/bin/bash
# cache_stats.sh - Measure cache effectiveness

DOCKERFILE="${1:-.}"

echo "=== Building with cache (second run, should be much faster) ==="

time docker build -t myapp:v1 "$DOCKERFILE"
CACHED_TIME=$?

echo
echo "=== Rebuilding from scratch (bypassing cache) ==="

time docker build --no-cache -t myapp:v1-nocache "$DOCKERFILE"
NOCACHE_TIME=$?

echo
echo "=== Cache Effectiveness ==="
echo "With cache:    $CACHED_TIME"
echo "Without cache: $NOCACHE_TIME"

```

---

### ASCII Diagrams

#### Diagram 1: Cache Hit/Miss Flow

```
Dockerfile Instruction
        │
        ▼
┌───────────────────────────────┐
│ Compute Cache Key             │
│ SHA256(parent_digest +        │
│        instruction +          │
│        file_hashes)           │
└────────────┬──────────────────┘
             │
             ▼
    ┌────────────────┐
    │ Cache Lookup   │
    └────┬─────┬─────┘
         │     │
    Cache Hit  Cache Miss
         │         │
         ▼         ▼
    ┌────────┐  ┌──────────────────┐
    │ Return │  │ Execute          │
    │ Layer  │  │ Instruction      │
    │ ID     │  ├──────────────────┤
    │ (0ms)  │  │ Compute Layer    │
    └───┬────┘  │ SHA256           │
        │       ├──────────────────┤
        │       │ Store in Cache   │
        │       │ (/var/lib/docker/│
        │       │  overlay2/)      │
        │       └────┬─────────────┘
        │            │
        └────┬───────┘
             ▼
      ┌──────────────────┐
      │ Return Layer ID  │
      │ (parent for next │
      │  instruction)    │
      └──────────────────┘
```

#### Diagram 2: Layer Caching Across CI/CD Machines

```
┌─────────────────────────────────────────────────────────┐
│                  Docker Registry                         │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Image: myapp:latest                                │ │
│  │ ├─ Layer A (ubuntu:22.04) sha256:aaa...           │ │
│  │ ├─ Layer B (RUN apt-get install) sha256:bbb...    │ │
│  │ ├─ Layer C (COPY requirements.txt) sha256:ccc...  │ │
│  │ ├─ Layer D (RUN pip install) sha256:ddd...        │ │
│  │ └─ Layer E (COPY . /app) sha256:eee...            │ │
│  └────────────────────────────────────────────────────┘ │
└──────────┬───────────────────────────────────────────────┘
           │
    ┌──────┴──────┬───────────────┬──────────────┐
    │             │               │              │
    ▼             ▼               ▼              ▼
┌────────┐   ┌────────┐   ┌────────┐   ┌──────────┐
│Dev Local│   │CI Agent│   │CI Agent│   │Dev Local │
│Machine  │   │ A      │   │ B      │   │Machine 2 │
├────────┤   ├────────┤   ├────────┤   ├──────────┤
│Cache:   │   │Cache:  │   │Cache:  │   │Cache:    │
│L: A,B,C│   │L: A,B,C│   │L: A,B,C│   │L: A,B,C │
│  (only  │   │(after  │   │(after  │   │(after    │
│  C, D,E │   │pull)   │   │pull)   │   │pull)     │
│  miss)  │   │        │   │        │   │          │
└────────┘   └────────┘   └────────┘   └──────────┘

Build Time: 45s      15s         15s        12s
           ↑         ↑           ↑          ↑
        No cache  With pull   With pull  With pull
```

#### Diagram 3: Dockerfile Instruction to Layer Mapping

```
File: Dockerfile                     Layer Stack (Read → Top to Bottom)
─────────────────────────────────────────────────────────────────────
FROM ubuntu:22.04          Layer 1   ┌───────────────────────────┐
                            ├────→   │ Layer 6 (COPY . /app)     │
RUN apt-get install        Layer 2   │ sha256:f12e...            │
  curl wget                 ├────→   ├───────────────────────────┤
                                     │ Layer 5 (RUN pip install) │
COPY requirements.txt .    Layer 3   │ sha256:e99d...            │
                            ├────→   ├───────────────────────────┤
RUN pip install -r \       Layer 4   │ Layer 4 (COPY req...)     │
    requirements.txt        ├────→   │ sha256:d88c...            │
                                     ├───────────────────────────┤
COPY . /app/               Layer 5   │ Layer 3 (RUN apt-get)     │
                            ├────→   │ sha256:c77b...            │
CMD ["python", "app.py"]    │        ├───────────────────────────┤
(image metadata)            │        │ Layer 2 (RUN apt-get)     │
                            │        │ sha256:b66a...            │
                            │        ├───────────────────────────┤
                            └────→   │ Layer 1 (FROM ubuntu)     │
                                     │ sha256:a55... (base)      │
                                     └───────────────────────────┘

Cache Scenario:
Source code change → Only Layer 6 rebuilds (+2s)
Dependency change → Layers 4, 5, 6 rebuild (+10s)
Base image change → All layers rebuild (+30s)
```

---

## Immutability & Versioning

### Textual Deep Dive

#### Internal Working Mechanism

Docker's immutability operates at multiple levels:

##### Level 1: Layer Immutability

Once a layer is created and stored, its contents are **locked**. Docker enforces this through:

1. **Content-Addressable Storage**: Layers are identified by SHA256 hash of their content
   ```
   Layer Content → SHA256 Hash → Directory name
   /var/lib/docker/overlay2/<HASH>/
   ```

2. **Read-Only Mount**: Production containers mount image layers as **read-only**
   ```
   OverlayFS Configuration:
   ├─ Lower (read-only): Layer 1, 2, 3
   ├─ Middle (read-only): Layer 4
   ├─ Upper (read-write): Container layer (temporary)
   └─ Work (internal): Metadata
   ```

3. **Verification on Access**: Docker validates layer content hasn't changed:
   ```bash
   # On container start, Docker verifies
   if SHA256(layer_content) != expected_digest:
       exit "Layer integrity violation"
   ```

##### Level 2: Image Immutability

An **image** is a manifest (JSON document) pointing to specific layer digests:

```json
{
  "config": {
    "Hostname": "",
    "Domainname": "",
    "User": "",
    "Env": ["PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"],
    "Cmd": ["/bin/bash"]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:layer1digest",
      "sha256:layer2digest",
      "sha256:layer3digest"
    ]
  },
  "history": [
    {"created": "2026-03-07T10:00:00Z", "created_by": "/bin/sh -c ..."},
    {"created": "2026-03-07T10:15:00Z", "created_by": "/bin/sh -c apt-get install"}
  ]
}
```

**Key insight**: If any referenced layer digest changes its content, the image essentially becomes "corrupted"—Docker detects this and refuses to use it.

##### Level 3: Tag Mutability (The Exception)

**Tags are mutable pointers**, not immutable references:

```
Today:   ubuntu:22.04 → pulls digest sha256:abc123...
Tomorrow: ubuntu:22.04 → pulls digest sha256:def456... (security patch)
```

This is why **digest-pinning** is critical for immutability guarantees.

#### Architecture Role

Immutability serves as the **foundational guarantee** of Docker's reliability model:

```
Immutability Guarantees
└─ Production Safety
   ├─ What you test in staging is exactly what runs in prod
   ├─ No unexpected updates mid-deployment
   ├─ Rollback always works (previous image layers exist)
   └─ Audit trail: Every change is a new image version

└─ Security Model
   ├─ Signed layers cannot be forged
   ├─ Tampering is detectable
   ├─ Supply chain attacks have an audit trail
   └─ Known-good versions are permanently available

└─ Developer Experience
   ├─ Reproducible builds
   ├─ No "works on my machine" for containers
   ├─ Easy bisecting of failures
   └─ Lightweight version control
```

#### Production Usage Patterns

##### Pattern 1: Semantic Versioning with Immutability

Production teams adopt semantic versioning that maps directly to immutable images:

```bash
# Application versioning
v1.0.0  → image digest sha256:prod1...
v1.0.1  → image digest sha256:prod2... (bug fix)
v1.1.0  → image digest sha256:prod3... (feature)
v2.0.0  → image digest sha256:prod4... (breaking change)

# In Kubernetes deployment
image: myapp@sha256:prod3  # Immutable reference prevents accidental updates
# Even if tag moves to v1.2.0, this pod still runs v1.1.0
```

##### Pattern 2: Blue-Green Deployments Using Immutability

```bash
# v1.0.0 running in production (blue environment)
kubectl set image deployment/myapp \
  myapp=myapp@sha256:v1digest

# Test v1.1.0 in parallel (green environment)
kubectl set image deployment/myapp-canary \
  myapp=myapp@sha256:v1.1digest

# Instant rollback if needed (because v1digest still exists)
kubectl set image deployment/myapp \
  myapp=myapp@sha256:v1digest
```

##### Pattern 3: Immutable Image Promotions Through Environments

```
Development        Staging           Production
──────────         ───────           ──────────
myapp:dev/123      myapp:staging/    myapp:v1.0.0
(rebuilt daily)    (weekly snapshot)  (immutable reference)
                        │                  │
                        └──────────────────┘
                      Same digest
                      (no rebuilds)
```

#### DevOps Best Practices

##### 1. Always Pin Base Image Digests

```dockerfile
# ✅ Recommended: Digest-pinned base
FROM ubuntu:22.04@sha256:0bced47fffa3ce6c271e71255e79f7db91a1194fbd9d8b7e4072311a2a621f29

# ❌ Problematic: Tag-pinned (moves when security patches released)
FROM ubuntu:22.04

# ❌ Dangerous: Floating tag (unpredictable)
FROM ubuntu:latest
```

**Scanning for unpinned images**:
```bash
# Find all images without digest pins
grep -r "FROM " Dockerfile* | grep -v "@sha256"
```

##### 2. Use Content-Addressable References in Production

```bash
# Deployment: Use digest, not tag
kubectl set image deployment/myapp \
  myapp=myapp@sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

# Verification: Confirm exact image
kubectl get deployment myapp -o jsonpath='{.spec.template.spec.containers[0].image}'
# Output: myapp@sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

##### 3. Version Images Semantically and Store Digests

```bash
#!/bin/bash
# tag-and-store-digest.sh

VERSION="1.2.3"
REGISTRY="myregistry.azurecr.io"
IMAGE_NAME="myapp"

# Build image
docker build -t "$REGISTRY/$IMAGE_NAME:$VERSION" .

# Get immutable digest
DIGEST=$(docker inspect --format='{{.RepoDigests}}' "$REGISTRY/$IMAGE_NAME:$VERSION" | grep -o 'sha256:[^ ]*')

# Store mapping
echo "v$VERSION=$DIGEST" >> versions.txt

# Push with both tag and digest
docker push "$REGISTRY/$IMAGE_NAME:$VERSION"

# Future deployments use stored digest
echo "Deploy with: $REGISTRY/$IMAGE_NAME@$DIGEST"
```

##### 4. Implement Immutable Registry Policies

```bash
# Azure Container Registry: Prevent tag mutation
az acr repository update \
  --name myregistry \
  --repository myapp \
  --delete-enabled false \
  --write-enabled false  # Read-only after push

# This prevents accidental tag reassignment
docker tag myapp:v1.0 myapp:latest  # Would fail
```

##### 5. Automate Security Updates Without Mutation

Rather than updating tags in-place, create new versions:

```bash
#!/bin/bash
# rebuild-base-images.sh - Rebuild apps with updated base

BASE_IMAGE="ubuntu:22.04"
APPS=("app-a" "app-b" "app-c")

# Check for base image updates
OLD_DIGEST=$(docker inspect "$BASE_IMAGE" --format='{{.RepoDigests}}' | head -1)

docker pull "$BASE_IMAGE"  # Fetch latest

NEW_DIGEST=$(docker inspect "$BASE_IMAGE" --format='{{.RepoDigests}}' | head -1)

if [ "$OLD_DIGEST" != "$NEW_DIGEST" ]; then
    echo "Base image updated: $OLD_DIGEST → $NEW_DIGEST"
    
    for app in "${APPS[@]}"; do
        # Rebuild each application
        docker build -t "myregistry/$app:rebuild-$(date +%s)" \
          --cache-from "myregistry/$app:latest" \
          "apps/$app"
        
        # Push new version (old version immutably exists)
        docker push "myregistry/$app:rebuild-$(date +%s)"
    done
fi
```

#### Common Pitfalls

##### Pitfall 1: Confusing Tag and Digest Mutability

```bash
# ❌ Problematic: Assumes tag is immutable
docker run myapp:latest  # Might be v1.0, or v1.1, or v2.0!

# ✅ Correct: Use digest for immutability
docker run myapp@sha256:1f6d3c9e5b4a7c8d...  # Always v1.0
```

##### Pitfall 2: Using `latest` Tag in Production

```dockerfile
# ❌ Anti-pattern
FROM python:latest  # Could be 3.8, 3.9, 3.11, 3.12...
```

The `latest` tag is rebuilt daily; your image won't actually be immutable.

##### Pitfall 3: Not Tracking Image Digests in CI/CD

```bash
# ❌ Problem: Lost audit trail
docker build -t myapp:v1.0 .
docker push myapp:v1.0
# Digest SHA written to stdout but not captured

# Years later, uncertain which commit built which digest

# ✅ Solution: Store digest in artifact
docker build -t myapp:v1.0 .
DIGEST=$(docker push myapp:v1.0 | grep digest | awk '{print $NF}')
echo "$DIGEST" > myapp-v1.0-digest.txt
git add myapp-v1.0-digest.txt
git commit -m "Release v1.0.0: $DIGEST"
```

##### Pitfall 4: Rebuilding Layers That Should Be Immutable

```dockerfile
# ❌ Problem: Rebuilds base on every app change
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl  # Rebuilds when app changes!
COPY . /app/

# ✅ Solution: Separate stable and changing layers
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl
COPY ./requirements /requirements/  # Only dependency files
RUN # ... install dependencies
COPY ./src /app/src                 # Application code last
```

---

### Practical Code Examples

#### Example 1: Immutable Version Tracking System

```bash
#!/bin/bash
# version-tracker.sh - Maintain immutable image registry

REGISTRY="${REGISTRY:-myregistry.azurecr.io}"
APP="${1:-myapp}"
ENVIRONMENT="${2:-production}"

# Create version record
record_version() {
    local version="$1"
    local digest="$2"
    local description="$3"
    
    cat >> "versions-${APP}.log" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
version: ${version}
environment: ${ENVIRONMENT}
digest: ${digest}
description: ${description}
build_commit: $(git rev-parse HEAD)
build_user: ${USER}
EOF
}

# Retrieve immutable version
get_version_digest() {
    local version="$1"
    grep "^version: ${version}$" "versions-${APP}.log" -A 5 | grep "^digest:" | head -1 | cut -d' ' -f2
}

# Deploy with immutable reference
deploy_version() {
    local version="$1"
    local digest=$(get_version_digest "$version")
    
    if [ -z "$digest" ]; then
        echo "Error: Version ${version} not found in registry"
        return 1
    fi
    
    echo "Deploying ${APP}@${digest}"
    
    # Kubernetes deployment
    kubectl set image deployment/"${APP}" \
        "${APP}=${REGISTRY}/${APP}@${digest}" \
        --record
    
    # Verify
    kubectl get deployment "${APP}" -o jsonpath='{.spec.template.spec.containers[0].image}'
}

# Usage
record_version "1.0.0" "sha256:abc123..." "Initial production release"
deploy_version "1.0.0"
```

#### Example 2: Immutable Artifact Chain in GitOps

```bash
#!/bin/bash
# gitops-artifact-chain.sh - Create immutable artifact references

REPO="myapp"
VERSION="${CI_COMMIT_TAG}"
BUILD_ID="${CI_JOB_ID}"

echo "=== Stage 1: Build & Tag ==="
docker build -t "${REPO}:${VERSION}" .

echo "=== Stage 2: Push & Capture Digest ==="
PUSH_OUTPUT=$(docker push "${REPO}:${VERSION}")

# Extract digest from push output
IMAGE_DIGEST=$(echo "$PUSH_OUTPUT" | grep -oP 'sha256:\K[a-f0-9]{64}')

echo "=== Stage 3: Store Manifest ==="
cat > "artifact-manifest-${VERSION}.yaml" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: artifact-manifest-${VERSION}
  namespace: production
data:
  version: "${VERSION}"
  image_digest: "sha256:${IMAGE_DIGEST}"
  build_date: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  git_commit: "$(git rev-parse HEAD)"
  git_tag: "${CI_COMMIT_TAG}"
  built_by: "CI/CD Pipeline"
EOF

echo "=== Stage 4: Commit to GitOps Repo ==="
git clone https://github.com/myorg/gitops-manifests.git
cd gitops-manifests

cat >> "${REPO}/kustomization.yaml" <<EOF
images:
  - name: ${REPO}
    newTag: "${VERSION}"
    digest: "sha256:${IMAGE_DIGEST}"
EOF

git add "${REPO}/kustomization.yaml"
git commit -m "Release ${REPO}:${VERSION}@sha256:${IMAGE_DIGEST}"
git push

echo "✓ Immutable artifact chain created"
echo "   Version: ${VERSION}"
echo "   Digest: sha256:${IMAGE_DIGEST}"
echo "   Commit: $(git log -1 --format=%H)"
```

#### Example 3: Verify Immutability in Production

```bash
#!/bin/bash
# verify-immutability.sh - Confirm images in prod are unchanged

NAMESPACE="production"
VERIFY_TIME=$(date +%s)

echo "=== Verifying Image Immutability in Namespace: ${NAMESPACE} ==="

# Get all running images
kubectl get pods -n "${NAMESPACE}" -o jsonpath='{..image}' | tr -s '[[:space:]]' '\n' | sort | uniq | while read IMAGE; do
    echo
    echo "Checking: $IMAGE"
    
    # Extract digest if present
    if [[ $IMAGE == *"@sha256:"* ]]; then
        DIGEST="${IMAGE##*@}"
        echo "  ✓ Digest-pinned: $DIGEST"
        
        # Verify digest is available in registry
        if docker pull "$IMAGE" 2>/dev/null; then
            echo "  ✓ Immutable image verified in registry"
        else
            echo "  ✗ ERROR: Image digest not found in registry!"
        fi
    else
        echo "  ⚠ WARNING: Tag-based reference (not immutable): $IMAGE"
        
        # Show current digest of tag
        CURRENT_DIGEST=$(docker inspect "$IMAGE" --format='{{.RepoDigests}}' 2>/dev/null | grep -o 'sha256:[a-f0-9]*' | head -1)
        echo "    Current digest: $CURRENT_DIGEST"
        echo "    Note: This digest may change if tag is updated"
    fi
done

echo
echo "=== Immutability Scan Complete ($(date +%s -d @${VERIFY_TIME})) ==="
```

#### Example 4: Automated Rollback Using Immutability

```bash
#!/bin/bash
# rollback-to-stable.sh - Rollback deployment using immutable digests

APP="${1:-myapp}"
NAMESPACE="${2:-production}"

echo "=== Available Immutable Versions ==="

# List stored image digests with timestamps
cat <<EOF
v1.0.0 (2026-01-15): myregistry/myapp@sha256:abc123...
v1.0.1 (2026-01-20): myregistry/myapp@sha256:def456...
v1.1.0 (2026-02-01): myregistry/myapp@sha256:ghi789...
v1.1.1 (2026-03-01): myregistry/myapp@sha256:jkl012... ← CURRENT (failed)
EOF

echo
echo "=== Rolling back to v1.1.0 (stable) ==="

STABLE_DIGEST="sha256:ghi789..."

kubectl set image deployment/"${APP}" \
    "${APP}=myregistry/${APP}@${STABLE_DIGEST}" \
    --namespace="${NAMESPACE}" \
    --record

echo
echo "=== Verifying Rollback ==="

kubectl rollout status deployment/"${APP}" -n "${NAMESPACE}"

echo "✓ Rolled back to: myregistry/${APP}@${STABLE_DIGEST}"
echo "  (Immutable version ensures identical behavior)"

# Safety check: verify the digest
RUNNING_DIGEST=$(kubectl get deployment "${APP}" -n "${NAMESPACE}" \
    -o jsonpath='{.spec.template.spec.containers[0].image}')

echo "  Verified running: ${RUNNING_DIGEST}"
```

---

### ASCII Diagrams

#### Diagram 1: Image Immutability Enforcement

```
Layer Creation Process (Immutable)
──────────────────────────────────

┌──────────────────────────────┐
│ Dockerfile: RUN apt-get ...  │
└──────────────┬───────────────┘
               ▼
        ┌──────────────┐
        │ Execute Step │
        └──────┬───────┘
               ▼
    ┌──────────────────────────┐
    │ Layer Created (snapshot) │
    │ Size: 45MB               │
    └──────┬───────────────────┘
           ▼
    ┌──────────────────────────┐
    │ Compute SHA256 Digest    │
    │ sha256:abc123def456...   │
    └──────┬───────────────────┘
           ▼
    ┌──────────────────────────┐
    │ Store in Content-       │
    │ Addressable Location    │
    │ /var/lib/docker/overlay2│
    │ /abc123def456.../       │
    │ (digest-based path)     │
    └──────┬───────────────────┘
           ▼
    ┌──────────────────────────┐
    │ Layer is READ-ONLY      │
    │ Immutable reference:    │
    │ sha256:abc123def456... │
    │ ✓ Can be shared by      │
    │   multiple images       │
    │ ✗ Cannot be modified    │
    └──────────────────────────┘
```

#### Diagram 2: Tag Mutability vs. Digest Immutability

```
Timeline: Tag vs. Digest References
───────────────────────────────────

Day 1:
  myapp:latest ─→ Image A (sha256:aaa...)
  myapp:v1.0   ─→ Image A (sha256:aaa...)
  
Deployment A: myapp:latest
              Receives: sha256:aaa...
              
Deployment B: myapp@sha256:aaa...
              Receives: sha256:aaa...
              (IDENTICAL)

Day 5: Security patch released
  myapp:latest ─→ Image B (sha256:bbb...)  ← Tag moved!
  myapp:v1.0   ─→ Image A (sha256:aaa...)  ← Tag unchanged
  
Deployment A: myapp:latest
              Now receives: sha256:bbb... ← AUTOMATIC UPDATE (SURPRISE!)
              
Deployment B: myapp@sha256:aaa...
              Still receives: sha256:aaa... ← UNCHANGED (PREDICTABLE)

Day 30: More security patches
  myapp:latest ─→ Image C (sha256:ccc...) ← Tag moved again!
  myapp:v1.0   ─→ Image A (sha256:aaa...)
  
Deployment A: Running unstable version without consent
Deployment B: Still running image A (safe & predictable)
```

#### Diagram 3: Immutable Image Distribution Model

```
Source Code Repository           Build Pipeline         Container Registry
──────────────────              ──────────────         ─────────────────

app:v1.0                         Build                 sha256:111
Commit abc123        ─────→    Docker Image    ──→    ↓
                               sha256:111            └─ Immutable
                                                     └─ Permanent
app:v1.1
Commit def456        ─────→    Docker Image    ──→    sha256:222
                               sha256:222            └─ Immutable
                                                     └─ Permanent

app:v1.2
Commit ghi789        ─────→    Docker Image    ──→    sha256:333
                               sha256:333            └─ Immutable
                                                     └─ Permanent


Production Deployment
────────────────────
Pod A:  myapp@sha256:111 ──→ Registry ──→ (immutable object)
                                         └─ Behavior guaranteed
                                         
Pod B:  myapp@sha256:222 ──→ Registry ──→ (immutable object)
                                         └─ Behavior guaranteed
                                         
Pod C:  myapp@sha256:333 ──→ Registry ──→ (immutable object)
                                         └─ Behavior guaranteed

All 3 pods are guaranteed to be different versions,
even if tags are reassigned or base images updated.
```

---

## SHA Digests, Manifests & Content Addressability

### Textual Deep Dive

#### Internal Working Mechanism

Docker's content-addressable system relies on **SHA256 hashing** and **manifest structures** to create deterministic, verifiable image references.

##### SHA256 Digest Generation

Every layer and image has a unique SHA256 digest computed from its content:

```
Layer Content
└─ File System Changes
   ├─ tar stream generated
   └─ gzip compressed
      └─ SHA256 hash computed
         └─ digest: sha256:abc123def456...
```

**Critical property**: Same layer content always produces identical digest, even if built on different machines:

```bash
# Machine A: docker build
SHA256(identical_content) = abc123...

# Machine B: docker build
SHA256(identical_content) = abc123...  # IDENTICAL

# Machine C: 2 years later
SHA256(identical_content) = abc123...  # STILL IDENTICAL
```

##### Manifest Structure

A **manifest** is a JSON document describing image composition and how layers assemble:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
  "config": {
    "mediaType": "application/vnd.docker.container.image.v1+json",
    "size": 7023,
    "digest": "sha256:config_digest_here..."   // Image config
  },
  "layers": [
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      "size": 2789523,
      "digest": "sha256:layer1_digest..."      // Base OS layer
    },
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip", 
      "size": 1234567,
      "digest": "sha256:layer2_digest..."      // Middle layer
    },
    {
      "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip",
      "size": 567890,
      "digest": "sha256:layer3_digest..."      // Application layer
    }
  ]
}
```

**Manifest digest**: SHA256(manifest_json) uniquely identifies the complete image and all its layers.

##### Content Addressability Principle

Registries store layers by digest (hash) not by tag or name:

```
Registry Storage Structure:
───────────────────────────
/blobs/sha256/abc123.../data
/blobs/sha256/def456.../data
/blobs/sha256/ghi789.../data

Tag References (Metadata):
myapp:v1.0  → points to manifest → references layers
myapp:v1.1  → points to manifest → references layers
ubuntu:22.04 → points to manifest → references layers
```

Multiple tags can reference the same digest:
```
myapp:v1.0          ─┐
myapp:latest         ├─→ sha256:abc123...  ← Single immutable object
myapp:prod-stable   ─┘
```

All three point to identical content; changes to any tag must point to different digest.

#### Architecture Role

Content addressability is the **cryptographic foundation** enabling:

1. **Deterministic Deployments**: Digest defines exact content, no ambiguity
2. **Supply Chain Security**: Hashes verify integrity; tampering is detectable
3. **Efficient Distribution**: Only changed blobs are transferred
4. **Deduplication**: Identical layers across images share storage
5. **Reproducibility**: Scientific/regulatory compliance (determine if two builds are identical)

#### Production Usage Patterns

##### Pattern 1: Signature Verification with Digests

Modern registries support signing image manifests (not tags, which are mutable):

```bash
# Sign image by manifest digest
docker trust sign myregistry/myapp@sha256:abc123...

# Verify signature during deployment
docker pull myregistry/myapp@sha256:abc123...  # Fails if signature invalid
```

##### Pattern 2: Digest-Based Image Promotion Through Environments

```bash
# Dev: Build and test
docker build -t myapp:dev-build-123 .
DEV_DIGEST=$(docker inspect myapp:dev-build-123 --format='{{index .RepoDigests 0}}')
# DEV_DIGEST: myregistry/myapp@sha256:dev...

# QA: Test same image (not rebuilt)
docker pull "${DEV_DIGEST}"
# Tag as validated
docker tag "${DEV_DIGEST}" myapp:qa-validated

# Prod: Deploy exact tested image
docker pull "${DEV_DIGEST}"
docker run "${DEV_DIGEST}"  # Guaranteed identical to QA
```

##### Pattern 3: Manifest-List for Multi-Architecture Images

Modern images support multiple architectures through manifest lists:

```
Manifest List (amd64 + arm64)
     │
     ├─ amd64 Manifest ──→ sha256:configs...
     │                    └─ Layers for amd64
     │
     └─ arm64 Manifest ──→ sha256:configb...
                          └─ Layers for arm64

docker pull myapp:v1.0  # Intelligently fetches correct manifest for architecture
```

#### DevOps Best Practices

##### 1. Store Image Digests in Version Control

```bash
# In your release notes or manifest file
VERSION=1.0.0
IMAGE_DIGEST=sha256:e3b0c44298fc1c14...

# In Kubernetes GitOps repo
image: myapp@${IMAGE_DIGEST}

# In CI/CD artifact storage
echo "myapp:1.0.0=${IMAGE_DIGEST}" >> release-artifacts.txt
```

##### 2. Use Digest Pinning in Container Orchestration

```yaml
# ❌ Tag-based (mutable)
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myregistry/myapp:v1.0.0  # Could change!

# ✅ Digest-pinned (immutable)
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: myapp
    image: myregistry/myapp@sha256:abc123...  # Guaranteed identical
```

##### 3. Implement Admission Controllers for Digest Pinning

```yaml
# Kubernetes ImagePolicy webhook enforces digest pinning
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-policy
webhooks:
- name: image-policy.example.com
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["*"]
    apiVersions: ["*"]
    resources: ["pods", "deployments"]
  clientConfig:
    service:
      name: image-policy-webhook
      namespace: kube-system
      path: "/validate"
    caBundle: ...
  failurePolicy: Fail
```

##### 4. Compare Digests for Build Reproducibility

```bash
#!/bin/bash
# verify-reproducible-build.sh

IMAGE_V1="myapp:v1.0.0"
BUILD_DIGEST=$(docker build -q .)

# Rebuild from same commit
REBUILD_DIGEST=$(docker build -q .)

if [ "$BUILD_DIGEST" == "$REBUILD_DIGEST" ]; then
    echo "✓ Reproducible build verified"
    echo "  Both builds produced: ${BUILD_DIGEST}"
else
    echo "✗ Build not reproducible"
    echo "  Build 1: ${BUILD_DIGEST}"
    echo "  Build 2: ${REBUILD_DIGEST}"
    echo "  Sources: Different content (timestamps, random data?)"
fi
```

##### 5. Create Content Addressability Audit Trail

```bash
#!/bin/bash
# audit-trail.sh - Log all image digests and references

REGISTRY="myregistry.azurecr.io"
AUDIT_LOG="image-audit.log"

record_image_push() {
    local repo="$1"
    local tag="$2"
    
    docker push "${REGISTRY}/${repo}:${tag}"
    
    DIGEST=$(docker inspect "${REGISTRY}/${repo}:${tag}" \
        --format='{{index .RepoDigests 0}}')
    
    cat >> "$AUDIT_LOG" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
repository: ${repo}
tag: ${tag}
digest: ${DIGEST}
pushed_by: ${USER}
commit: $(git rev-parse HEAD)
---
EOF
}

# Later, verify content addressability
verify_image_content() {
    local expected_digest="$1"
    
    # Pull by digest (always gets exact content)
    docker pull "${expected_digest}"
    
    # Verify it matches expected
    actual=$(docker inspect "${expected_digest}" \
        --format='{{index .RepoDigests 0}}')
    
    if [ "$actual" == "$expected_digest" ]; then
        echo "✓ Content verified: ${expected_digest}"
    else
        echo "✗ Content mismatch!"
        echo "  Expected: ${expected_digest}"
        echo "  Actual: ${actual}"
    fi
}
```

#### Common Pitfalls

##### Pitfall 1: Comparing Layer Digests to Image Digests

```bash
# ❌ Confusion
LAYER_DIGEST=$(docker history myapp:v1 | head -2 | tail -1 | awk '{print $1}')
# This is a layer SHA, not the image digest!

# ✅ Correct: Get image digest (manifest SHA)
IMAGE_DIGEST=$(docker inspect myapp:v1 --format='{{.RepoDigests}}')
# or
docker images --digests | grep myapp
```

Different concepts:
- **Layer digest**: SHA256 of layer content/changes (internal)
- **Image/Manifest digest**: SHA256 of manifest structure (for pulling/deploying)

##### Pitfall 2: Manifests Change When Adding New Architectures

```bash
# Day 1: Build for amd64 only
docker buildx build --platform linux/amd64 -t myapp:v1.0 .
sha256:amd64_manifest...

# Day 2: Add arm64 support
docker buildx build --platform linux/amd64,linux/arm64 -t myapp:v1.0 .
sha256:manifest_list...  ← DIFFERENT digest (now includes both)

# This can break systems relying on exact digest matches!
```

**Solution**: Once set, don't change platform support mid-lifecycle.

##### Pitfall 3: Content Addressability Misunderstood as Encryption

```bash
# Content-addressable ≠ Encrypted
sha256:abc123...  # Anyone who knows this digest can pull the image
                   # (It's just a hash-based reference, not encrypted)

# For actual privacy:
# 1. Store images in private registry (access control)
# 2. Sign images for integrity (docker trust)
# 3. Encrypt registry storage (infrastructure concern)
```

---

### Practical Code Examples

#### Example 1: Complete SHA256 Digest Workflow

```bash
#!/bin/bash
# digest-workflow.sh - Track images throughout lifecycle

REGISTRY="myregistry.azurecr.io"
APP="myapp"
VERSION="1.2.3"

echo "=== Step 1: Build Image ==="
docker build -t "${APP}:${VERSION}" .

echo
echo "=== Step 2: Get Image Digest ==="
# Method 1: Before pushing
LOCAL_ID=$(docker images --no-trunc --quiet "${APP}:${VERSION}")
echo "Local Image ID: ${LOCAL_ID}"

# Inspect complete digest info
docker inspect "${APP}:${VERSION}" | jq '.[] | {Id, RepoDigests}'

echo
echo "=== Step 3: Push and Capture Digest ==="
docker tag "${APP}:${VERSION}" "${REGISTRY}/${APP}:${VERSION}"
PUSH_RESPONSE=$(docker push "${REGISTRY}/${APP}:${VERSION}")

# Extract digest
PUSHED_DIGEST=$(echo "${PUSH_RESPONSE}" | grep "sha256:" | head -1 | awk '{print $3}')
echo "Pushed Digest: ${PUSHED_DIGEST}"

echo
echo "=== Step 4: Verify Content Addressability ==="
# Pull by exact digest (guaranteed identical)
docker pull "${PUSHED_DIGEST}"

# Get digest again after pull
REPULL_DIGEST=$(docker inspect "${PUSHED_DIGEST}" --format='{{index .RepoDigests 0}}')
echo "Verified Digest: ${REPULL_DIGEST}"

if [ "$PUSHED_DIGEST" == "$REPULL_DIGEST" ]; then
    echo "✓ Content addressability verified"
else
    echo "✗ Digest mismatch (should never happen!)"
fi

echo
echo "=== Step 5: Store Digest Reference ==="
MANIFEST_FILE="${APP}-${VERSION}-digest.txt"
echo "${REGISTRY}/${APP}@${PUSHED_DIGEST}" > "${MANIFEST_FILE}"
git add "${MANIFEST_FILE}"
git commit -m "Release ${APP}:${VERSION} digest reference"

echo "✓ Digest reference stored in ${MANIFEST_FILE}"
```

#### Example 2: Multi-Architecture Manifest Management

```bash
#!/bin/bash
# manifest-multi-arch.sh - Build and push multi-architecture image

REGISTRY="myregistry.azurecr.io"
APP="myapp"
VERSION="1.0.0"

echo "=== Building for Multiple Architectures ==="

# Build for multiple platforms
docker buildx create --name multiarch-builder --use 2>/dev/null || \
  docker buildx use multiarch-builder

docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  --push \
  --tag "${REGISTRY}/${APP}:${VERSION}" \
  .

echo
echo "=== Inspecting Manifest List ==="

# Get manifest list (contains references to all architectures)
docker buildx imagetools inspect "${REGISTRY}/${APP}:${VERSION}"

echo
echo "=== Sample Output ==="
cat <<'EOF'
Name:      myregistry/myapp:1.0.0
MediaType: application/vnd.docker.distribution.manifest.list.v2+json
Digest:    sha256:manifest_list_digest...

Manifests:
  Name:      myregistry/myapp:1.0.0@sha256:amd64_manifest_digest
  Platform:  linux/amd64
  
  Name:      myregistry/myapp:1.0.0@sha256:arm64_manifest_digest
  Platform:  linux/arm64
  
  Name:      myregistry/myapp:1.0.0@sha256:armv7_manifest_digest
  Platform:  linux/arm/v7
EOF

echo
echo "=== Pulling for Specific Architecture ==="

# User's machine auto-selects correct manifest
docker pull "${REGISTRY}/${APP}:${VERSION}"  
# If arm64: gets sha256:arm64_manifest_digest
# If amd64: gets sha256:amd64_manifest_digest
# If arm32: gets sha256:armv7_manifest_digest
```

#### Example 3: Manifest Verification and Signing

```bash
#!/bin/bash
# verify-and-sign.sh - Verify image manifest integrity

REGISTRY="myregistry.azurecr.io"
APP="myapp"
DIGEST="$1"  # Expected digest

if [ -z "$DIGEST" ]; then
    echo "Usage: $0 <expected-digest>"
    exit 1
fi

echo "=== Verifying Image Manifest ==="

# Fetch manifest
MANIFEST=$(curl -s \
    -H "Authorization: Bearer $(az acr login --name myregistry --expose-token --output tsv | awk '{print $NF}')" \
    "https://myregistry.azurecr.io/v2/${APP}/manifests/${DIGEST}")

echo "Manifest retrieved:"
echo "${MANIFEST}" | jq '.'

echo
echo "=== Computing Manifest Digest ==="

# Content addressability: digest is SHA256 of manifest
COMPUTED_DIGEST=$(echo -n "${MANIFEST}" | sha256sum | awk '{print "sha256:"$1}')
echo "Computed: ${COMPUTED_DIGEST}"
echo "Expected: ${DIGEST}"

if [ "$COMPUTED_DIGEST" == "$DIGEST" ]; then
    echo "✓ Manifest integrity verified"
else
    echo "✗ Manifest integrity violated (content altered!)"
    exit 1
fi

echo
echo "=== Signing Manifest ==="

# Sign the manifest
docker trust sign "${REGISTRY}/${APP}@${DIGEST}"

echo "✓ Manifest signed and verified"
```

#### Example 4: Digest Comparison for Reproducibility Testing

```bash
#!/bin/bash
# test-reproducibility.sh - Verify builds produce identical digests

APP="$1"
ITERATIONS="${2:-3}"

echo "=== Testing Build Reproducibility ($ITERATIONS iterations) ==="
echo

DIGESTS=()

for i in $(seq 1 "$ITERATIONS"); do
    echo "Build iteration $i..."
    
    # Clean previous build artifacts
    docker rmi -f "${APP}:test" 2>/dev/null || true
    
    # Clean build
    docker build --no-cache -t "${APP}:test" .
    
    # Get digest  
    DIGEST=$(docker images --no-trunc --quiet "${APP}:test")
    DIGESTS+=("$DIGEST")
    
    echo "  Digest: ${DIGEST:0:12}"
    echo
done

echo "=== Reproducibility Results ==="

# Check if all digests are identical
UNIQUE=$(printf '%s\n' "${DIGESTS[@]}" | sort -u | wc -l)

if [ "$UNIQUE" -eq 1 ]; then
    echo "✓ Reproducible Build: All $ITERATIONS builds produced identical image"
    echo "   Digest: ${DIGESTS[0]}"
else
    echo "✗ Non-reproducible Build: Produced $UNIQUE different digests"
    for i in "${!DIGESTS[@]}"; do
        echo "   Build $((i+1)): ${DIGESTS[$i]:0:12}"
    done
    echo
    echo "Sources of non-reproducibility:"
    echo "  - Timestamps in source files"
    echo "  - Build time dependencies changing"
    echo "  - Random seed in initialization"
    echo "  - Non-deterministic package manager ordering"
fi
```

---

### ASCII Diagrams

#### Diagram 1: Manifest Structure and Content Addressability

```
Docker Image on Disk/Registry
──────────────────────────────

┌─────────────────────────────────┐
│ Manifest.json                   │
│ {                               │
│   "config": {                   │
│     "digest": "sha256:cfg..."   │
│   },                            │
│   "layers": [                   │
│     {digest: "sha256:lay1..."}  │
│     {digest: "sha256:lay2..."}  │
│     {digest: "sha256:lay3..."}  │
│   ]                             │
│ }                               │
└──────────────┬──────────────────┘
               │
               ▼ SHA256(manifest_json)
        ┌──────────────────────┐
        │ Image Digest         │
        │ sha256:abc123...     │
        │ (points to manifest  │
        │  and all its layers) │
        └────────┬─────────────┘
                 │
                 ▼ Content-Addressable Storage
        ┌──────────────────────┐
        │ Registry Blob Store  │
        │ /blobs/sha256/       │
        │   abc123.../data     │ ← Manifest
        │   lay1/../data       │ ← Layer 1
        │   lay2/../data       │ ← Layer 2
        │   lay3/../data       │ ← Layer 3
        │   cfg.../data        │ ← Config
        └──────────────────────┘
```

#### Diagram 2: Tag Mutability vs. Manifest Immutability

```
Tag Resolution vs. Digest Reference
────────────────────────────────────

Tag Reference (Mutable):
myapp:v1.0
   │
   ▼ Registry lookup
Manifest sha256:abc123...
   │ Layers referenced
   ├─ sha256:layer1
   ├─ sha256:layer2
   └─ sha256:layer3

Later (base image patched):
myapp:v1.0
   │
   ▼ Registry lookup
Manifest sha256:def456...  ← DIFFERENT manifest!
   │ Layers referenced
   ├─ sha256:layer1  (same)
   ├─ sha256:layer2a (updated)
   └─ sha256:layer3  (same)


Digest Reference (Immutable):
myapp@sha256:abc123...
   │
   ▼ Registry lookup
Manifest sha256:abc123...  ← ALWAYS same
   │ Layers referenced
   ├─ sha256:layer1
   ├─ sha256:layer2
   └─ sha256:layer3

Later (base image patched):
myapp@sha256:abc123...
   │
   ▼ Registry lookup
Manifest sha256:abc123...  ← STILL same (base patch irrelevant)
   │ Layers referenced
   ├─ sha256:layer1
   ├─ sha256:layer2
   └─ sha256:layer3
```

#### Diagram 3: Manifest List for Multi-Architecture

```
Image Pull: myapp:v1.0
        │
        ▼
Registry Lookup
        │
┌───────┴────────────────────────┐
│ Manifest List                  │
│ (selects correct manifest)     │
├────────────────────────────────┤
│ mediaType: manifest.list.v2    │
│                                │
│ Manifests:                     │
│ ├─ Platform: linux/amd64       │
│ │  Digest: sha256:amd64...     │
│ │                              │
│ ├─ Platform: linux/arm64       │
│ │  Digest: sha256:arm64...     │
│ │                              │
│ └─ Platform: linux/arm/v7      │
│    Digest: sha256:armv7...     │
└───────┬─────────────────────────┘
        │
    Detect arch
        │
   ┌────┴────┬──────────┬──────────┐
   │          │          │          │
   ▼          ▼          ▼          ▼
  amd64     arm64      arm32      s390x
   │          │          │          │
   └──────────┴──────────┴──────────┘
   Pull correct manifest per architecture
   (each gets optimized binary)
```

---

## Docker Registries & Repositories, Structure & Distribution

### Textual Deep Dive

#### Internal Working Mechanism

Docker **registries** are distributed systems that store and serve container images. They implement the **Docker Registry V2 API** specification, enabling standard image operations across multiple registry implementations.

##### Registry Architecture

```
Registry Components:
────────────────────

┌──────────────────────────────────────┐
│ Registry Server (HTTP/HTTPS API)     │
├──────────────────────────────────────┤
│ ├─ Authentication/Authorization      │  JWT tokens, OAuth2, mTLS
│ ├─ Blob Storage                      │  Stores layers (content hash)
│ ├─ Metadata Store                    │  Tags, manifests, references
│ ├─ Garbage Collector                 │  Remove unreferenced blobs
│ └─ Replication Service               │  Mirror images to other registries
└──────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────┐
│ Underlying Storage Backend            │
├──────────────────────────────────────┤
│ ├─ Filesystem                        │  /var/lib/registry/docker/
│ ├─ S3, GCS, Azure Blob, etc.         │  Cloud object storage
│ ├─ HDFS, Swift, etc.                 │  Distributed storage
│ └─ Ceph, MinIO, etc.                 │  Scalable storage
└──────────────────────────────────────┘
```

##### Repository & Image Organization

A **repository** groups versions of a single image; a **registry** contains multiple repositories:

```
  Registry (e.g., docker.io, myregistry.azurecr.io)
    │
    ├─ Repository: library/ubuntu
    │  ├─ Tag: 22.04        → Manifest A
    │  ├─ Tag: 20.04        → Manifest B
    │  └─ Tag: latest       → Manifest A (aliased)
    │
    ├─ Repository: library/python
    │  ├─ Tag: 3.11         → Manifest C
    │  ├─ Tag: 3.12         → Manifest D
    │  └─ Tag: latest       → Manifest D (aliased)
    │
    └─ Repository: myorg/myapp
       ├─ Tag: v1.0.0       → Manifest E
       ├─ Tag: v1.1.0       → Manifest F
       └─ Tag: main         → Manifest F (aliased)
```

##### Image Distribution Protocol

The Registry V2 API uses **HTTP GET/POST** with specific headers:

**Manifest Pull** (Layer Fetch):
```
Client → Registry HTTP GET /v2/myapp/manifests/v1.0.0
       ← Registry HTTP 200 OK
         Content-Type: application/vnd.docker.distribution.manifest.v2+json
         Docker-Content-Digest: sha256:abc123...
         
         Manifest JSON with layer references
```

**Layer (Blob) Pull**:
```
Client → Registry HTTP GET /v2/myapp/blobs/sha256:layer1digest
       ← Registry HTTP 302 Redirect → Cloud storage signed URL
         or
       ← Registry HTTP 200 OK + gzip layer data

Client downloads layer from cloud storage (or registry directly)
Layer is verified: SHA256(downloaded) must == layer1digest
```

**Manifest Push**:
```
Client → Registry HTTP HEAD /v2/myapp/blobs/sha256:layer1digest
       ← Registry HTTP 200 OK (exists) or 404 Not Found
       
If 404 (missing):
Client → Registry HTTP POST /v2/myapp/blobs/uploads/  # Initiate
       ← Registry HTTP 202 Accepted + Location header

Client → Registry HTTP PATCH /v2/myapp/blobs/uploads/<UUID>
         (upload layer chunks)
       ← Registry HTTP 202 Accepted

Client → Registry HTTP PUT /v2/myapp/blobs/uploads/<UUID>?digest=sha256:...
         (finalize)
       ← Registry HTTP 201 Created

Client → Registry HTTP PUT /v2/myapp/manifests/v1.0.0
         Manifest JSON
       ← Registry HTTP 201 Created
```

#### Architecture Role

Registries enable:

1. **Decentralized Distribution**: Images distributed from central server to thousands of hosts
2. **Deduplication**: Common layers stored once, referenced by multiple images
3. **Replication & Backup**: Mirror deployments across geographic regions
4. **Access Control**: Authentication/RBAC integrated with build and deployment systems
5. **Immutability Enforcement**: Content addressability prevents modification

#### Production Usage Patterns

##### Pattern 1: Enterprise Private Registry

Organizations run private registries for security and compliance:

```bash
# Kubernetes deployment of Docker Registry
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: docker-registry
spec:
  replicas: 3
  selector:
    matchLabels:
      app: registry
  template:
    metadata:
      labels:
        app: registry
    spec:
      containers:
      - name: registry
        image: registry:2
        env:
        - name: REGISTRY_STORAGE
          value: s3
        - name: REGISTRY_STORAGE_S3_BUCKET
          value: company-registry-storage
        - name: REGISTRY_STORAGE_S3_REGION
          value: us-west-2
        - name: REGISTRY_HTTP_TLS_CERTIFICATE
          value: /etc/registry/certs/registry.crt
        - name: REGISTRY_HTTP_TLS_KEY
          value: /etc/registry/certs/registry.key
        volumeMounts:
        - name: certs
          mountPath: /etc/registry/certs
          readOnly: true
      volumes:
      - name: certs
        secret:
          secretName: registry-tls
---
apiVersion: v1
kind: Service
metadata:
  name: docker-registry
spec:
  selector:
    app: registry
  ports:
  - port: 443
    targetPort: 5000
  type: ClusterIP
```

##### Pattern 2: Image Promotion Through Registries

Different registries per environment:

```bash
# Dev registry: Frequent pushes, experimental images
docker tag myapp:feature-xyz dev-registry.company.com/myapp:feature-xyz
docker push dev-registry.company.com/myapp:feature-xyz

# Staging registry: Tested, validated images
docker tag myapp:v1.0.0 staging-registry.company.com/myapp:v1.0.0
docker push staging-registry.company.com/myapp:v1.0.0

# Production registry: Locked, immutable reference
docker tag myapp:v1.0.0 prod-registry.company.com/myapp:v1.0.0
docker push prod-registry.company.com/myapp:v1.0.0

# Production nodes only pull from prod registry
# (Prevents accidental deployment of dev/staging images)
```

##### Pattern 3: Registry Mirroring for High Availability

```bash
# Primary registry: myregistry.io
# Mirror 1: myregistry-us-west.io  (geographically distributed)
# Mirror 2: myregistry-eu.io       (for compliance, latency)

# Daemon config: Try mirrors if primary unavailable
{
  "registry-mirrors": [
    "https://myregistry-us-west.io",
    "https://myregistry-eu.io"
  ]
}

# Replication job: Sync images between registries
docker pull myregistry.io/myapp:v1.0.0
docker tag myregistry.io/myapp:v1.0.0 myregistry-us-west.io/myapp:v1.0.0
docker push myregistry-us-west.io/myapp:v1.0.0
```

#### DevOps Best Practices

##### 1. Implement Registry Access Control

```bash
# Azure Container Registry: Role-based access control
az role assignment create \
  --assignee-object-id <service-principal-id> \
  --role AcrPush \
  --scope /subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/<registry>

# Docker daemon: Use credentials helper
cat ~/.docker/config.json
{
  "credHelpers": {
    "myregistry.azurecr.io": "azurecr"
  }
}
```

##### 2. Implement Content Security Scanning

```bash
# Scan images on push to registry
# Azure Container Registry: Enable vulnerability scanning
az acr config content-trust update --registry myregistry --status Enabled

# Prevent unsigned images from running
kubectl admission webhook to validate image signatures...
```

##### 3. Implement Repository Policies

```bash
# Prevent tag mutation (once pushed, image is locked)
az acr repository update \
  --registry myregistry \
  --name myapp \
  --delete-enabled false \
  --write-enabled false  # Read-only after initial push

# Retention policy: Auto-delete old images
az acr retention policy update \
  --registry myregistry \
  --days 30 \
  --untagged-only true  # Keep tagged versions, delete untagged builds
```

##### 4. Optimize Image Distribution

```bash
# Use registry compression (gzip by default)
# Smaller images = faster pulls = reduced bandwidth

# Analyze layer deduplication
# Same base image (ubuntu:22.04) across 100 apps:
# One registry instance: 1 × base layers
# Separate registries: 100 × base layers duplication (wasteful)
```

##### 5. Implement Registry Health & Monitoring

```bash
#!/bin/bash
# monitor-registry.sh - Health check script

REGISTRY="myregistry.azurecr.io"

echo "=== Registry Health Status ==="

# Registry API health
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $(az acr login --name myregistry --expose-token --output tsv | cut -f11)" \
  "https://${REGISTRY}/v2/")

if [ "$HEALTH" == "200" ]; then
    echo "✓ Registry API: Healthy"
else
    echo "✗ Registry API: Unhealthy (HTTP $HEALTH)"
fi

# Storage quota
QUOTA=$(az acr show --name myregistry --query storageProfile.maxStorageGb -o tsv)
USAGE=$(az acr show-usage --name myregistry --query value[0].currentValue -o tsv)
PERCENT=$((USAGE * 100 / QUOTA))

echo "Storage: ${USAGE}GB / ${QUOTA}GB ($PERCENT%)"

if [ "$PERCENT" -gt 90 ]; then
    echo "⚠ Storage near capacity"
fi
```

#### Common Pitfalls

##### Pitfall 1: Pushing to Wrong Registry

```bash
# ❌ Problem: Accidentally pushes to Docker Hub
docker tag myapp:v1.0 myapp:v1.0
docker push myapp:v1.0  # Goes to Docker Hub, not private registry!

# ✅ Solution: Always specify registry in tag
docker tag myapp:v1.0 myregistry.azurecr.io/myapp:v1.0
docker push myregistry.azurecr.io/myapp:v1.0
```

##### Pitfall 2: Large Images Slow Down Push/Pull

```dockerfile
# ❌ Problem: 2GB image
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    build-essential gcc g++ make cmake \
    git curl wget vim nano \
    ...100 dev tools...
COPY . /app/
RUN npm install
# Final image: 2GB

# ✅ Solution: Multi-stage build
FROM ubuntu:22.04 as builder
RUN apt-get install -y build-essential gcc g++ make cmake
COPY . /app/
RUN npm run build

FROM ubuntu:22.04
COPY --from=builder /app/dist /app/
# Final image: 100MB
```

Smaller images:
- Push faster (network utilization)
- Pull faster (node startup time)
- Store cheaper (registry capacity)

##### Pitfall 3: Uncontrolled Tag Proliferation

```bash
# ❌ Problem: Too many tags per image
docker tag myapp:v1.0 myapp:latest
docker tag myapp:v1.0 myapp:stable
docker tag myapp:v1.0 myapp:prod
docker tag myapp:v1.0 myapp:main
docker tag myapp:v1.0 myapp:main-stable
docker tag myapp:v1.0 myapp:release-v1
# ... dozens more

# Registry has thousands of tags, hard to navigate

# ✅ Solution: Standardized tagging
v1.0.0          (specific version)
v1.0            (latest patch)
v1              (latest minor)
latest          (absolute latest)
# Max ~5 tags per meaningful version
```

##### Pitfall 4: Not Authorizing Registry Access

```bash
# ❌ Problem: Publicly readable registry
# Anyone can: docker pull myregistry.io/secret-app:latest

#  ✅ Solution: Implement authentication
# Public Docker Hub: Limit to specific users
# Private registries: Require credentials for all operations
```

---

### Practical Code Examples

#### Example 1: Private Registry Setup & Configuration

```bash
#!/bin/bash
# setup-private-registry.sh - Deploy isolated private registry

REGISTRY_NAME="mycompany-registry"
REGISTRY_PORT="5443"
STORAGE_LOCATION="/mnt/registry-storage"

echo "=== Creating Registry Storage ==="
sudo mkdir -p "$STORAGE_LOCATION"
sudo chmod 700 "$STORAGE_LOCATION"

echo
echo "=== Generating TLS Certificates ==="
openssl genrsa -out registry.key 2048
openssl req -new -x509 -key registry.key \
  -out registry.crt \
  -subj "/CN=registry.company.local"

echo
echo "=== Starting Private Registry ==="
docker run -d \
  --name="${REGISTRY_NAME}" \
  --restart=always \
  -p "${REGISTRY_PORT}:5000" \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/registry.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/registry.key \
  -e REGISTRY_STORAGE_PATH=/data \
  -v "$STORAGE_LOCATION:/data" \
  -v "$(pwd):/certs:ro" \
  registry:2

echo
echo "=== Configuring Docker Daemon ==="
cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries": ["registry.company.local:${REGISTRY_PORT}"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl restart docker

echo "✓ Private registry running on localhost:${REGISTRY_PORT}"
echo "✓ Configure clients to trust: registry.company.local"
```

#### Example 2: Registry Monitoring & Maintenance

```bash
#!/bin/bash
# registry-maintenance.sh - Monitor and maintain registry health

REGISTRY="https://myregistry.azurecr.io"
TOKEN=$(az acr login --name myregistry --expose-token --output tsv | cut -f11)

echo "=== Registry Repository Inventory ==="

# List all repositories
curl -s -H "Authorization: Bearer ${TOKEN}" \
  "${REGISTRY}/v2/_catalog" | jq '.repositories[] as $repo | {
    repository: $repo,
    image_count: (. as $catalog | $catalog | length)
  }'

echo
echo "=== Analyzing Image Sizes ==="

for repo in $(curl -s -H "Authorization: Bearer ${TOKEN}" \
  "${REGISTRY}/v2/_catalog" | jq -r '.repositories[]'); do
    
    # List tags for repo
    TAGS=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
      "${REGISTRY}/v2/${repo}/tags/list" | jq -r '.tags[]')
    
    for tag in $TAGS; do
        # Get manifest
        MANIFEST=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
          -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
          "${REGISTRY}/v2/${repo}/manifests/${tag}")
        
        # Extract layer sizes
        TOTAL_SIZE=$(echo "$MANIFEST" | jq '[.layers[].size] | add')
        
        printf "%-30s %-15s %s\n" \
          "${repo}" "${tag}" "${TOTAL_SIZE} bytes"
    done
done

echo
echo "=== Unused Images (no tags) ==="

curl -s -H "Authorization: Bearer ${TOKEN}" \
  "${REGISTRY}/v2/_catalog" | jq '.repositories[]' | while read repo; do
    TAGS=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
      "${REGISTRY}/v2/${repo}/tags/list" | jq '.tags')
    
    if [ "$TAGS" == "null" ] && [ "$tags" == "[]" ]; then
        echo "Untagged repo: $repo"
    fi
done
```

#### Example 3: Image Replication Script

```bash
#!/bin/bash
# replicate-images.sh - Sync images across registries

SOURCE_REGISTRY="source-registry.azurecr.io"
TARGET_REGISTRY="target-registry.azurecr.io"

SOURCE_TOKEN=$(az acr login --name source-registry --expose-token --output tsv | cut -f11)
TARGET_TOKEN=$(az acr login --name target-registry --expose-token --output tsv | cut -f11)

echo "=== Replicating Images ==="

# Get list of images from source
REPOS=$(curl -s -H "Authorization: Bearer ${SOURCE_TOKEN}" \
  "https://${SOURCE_REGISTRY}/v2/_catalog" | jq -r '.repositories[]')

for repo in $REPOS; do
    echo "Processing repository: $repo"
    
    TAGS=$(curl -s -H "Authorization: Bearer ${SOURCE_TOKEN}" \
      "https://${SOURCE_REGISTRY}/v2/${repo}/tags/list" | jq -r '.tags[]')
    
    for tag in $TAGS; do
        SOURCE_IMAGE="${SOURCE_REGISTRY}/${repo}:${tag}"
        TARGET_IMAGE="${TARGET_REGISTRY}/${repo}:${tag}"
        
        echo "  Replicating: ${SOURCE_IMAGE} → ${TARGET_IMAGE}"
        
        # Pull from source
        docker pull "$SOURCE_IMAGE"
        
        # Tag for target
        docker tag "$SOURCE_IMAGE" "$TARGET_IMAGE"
        
        # Push to target
        docker push "$TARGET_IMAGE"
        
        # Verify
        if docker inspect "$TARGET_IMAGE" > /dev/null 2>&1; then
            echo "    ✓ Successfully replicated"
        else
            echo "    ✗ Replication failed"
        fi
    done
done

echo "✓ Replication complete"
```

#### Example 4: Registry Access Audit

```bash
#!/bin/bash
# audit-registry-access.sh - Log all registry operations

REGISTRY="https://myregistry.azurecr.io"
TOKEN=$(az acr login --name myregistry --expose-token --output tsv | cut -f11)
AUDIT_LOG="registry-audit-$(date +%Y%m%d).log"

log_access() {
    local action="$1"
    local repo="$2"
    local tag="$3"
    
    cat >> "$AUDIT_LOG" <<EOF
timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
action: ${action}
repository: ${repo}
tag: ${tag}
user: ${USER}
client: $(hostname)
status: success
---
EOF
}

# Track push events
track_push_events() {
    # Query Azure Container Registry logs
    az monitor activity-log list \
      --namespace Microsoft.ContainerRegistry \
      --resource-type registries \
      --query "[?operationName.value=='Microsoft.ContainerRegistry/registries/push/action']" \
      --output table
}

echo "=== Registry Access Audit ==="
track_push_events | while IFS= read -r line; do
    echo "  $line" >> "$AUDIT_LOG"
done

echo "✓ Audit log: $AUDIT_LOG"
```

---

### ASCII Diagrams

#### Diagram 1: Registry Distribution Model

```
Client Machines (Kubernetes Nodes)
──────────────────────────────────

Pod A          Pod B           Pod C
  │              │               │
  ▼              ▼               ▼
docker pull myapp:v1.0
docker pull myapp:v1.0
docker pull myapp:v1.0
        │       │               │
        └───────┴───────────────┘
                │
                ▼ Registry Query
        ┌────────────────────┐
        │ Primary Registry   │
        │ (myregistry.io)    │
        │                    │
        │ Index:             │
        │ myapp:v1.0 →       │
        │   Manifest A       │
        │   └─ Layers        │
        │      ├─ sha256:1   │
        │      ├─ sha256:2   │
        │      └─ sha256:3   │
        └────────┬───────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    ▼                         ▼
Cloud Storage            Cloud Storage
(S3, GCS, Azure Blob)    (US-West)
                         (EU Region)
    
All clients download layers from:
1. Registry (if local cache)
2. Cloud storage (if available)
3. Other registries (via federation)
```

#### Diagram 2: Image Promotion Through Multiple Registries

```
Development Flow
────────────────

┌──────────────          ┌──────────────         ┌──────────────┐
│ Dev Registry           │ Staging Registry      │ Prod Registry│
├──────────────          ├──────────────         ├──────────────┤
│ myapp:dev-123          │ myapp:v1.0            │ myapp:v1.0   │
│ myapp:dev-124          │                       │ myapp:v1.1   │
│ myapp:pr-456           │ (tested)              │ myapp:v2.0   │
│ myapp:main-build       │                       │ (locked)     │
│ (frequent)             │ (weekly snapshots)    │ (releases)   │
└────────────┬───────────┘                        └──────────────┘
             │
             │ Validation tests pass
             │
             ▼
          Tag as v1.0
          Push to Staging
             │
             │ Staging tests pass
             │ Security scan OK
             │
             ▼
          Tag as v1.0
          Push to Production
          (immutable)

Each promotion maintains same digest (no rebuild)
```

#### Diagram 3: Registry API Operations (V2)

```
Docker Client                        Registry Server

1. Check for latest tag
   HEAD /v2/myapp/manifests/latest
                                    ───────→ 200 OK (exists)
                                              Digest: sha256:abc...

2. Pull manifest
   GET /v2/myapp/manifests/latest
                                    ───────→ 200 OK
                                              Manifest JSON

3. Check if layers exist
   HEAD /v2/myapp/blobs/sha256:layer1
                                    ───────→ 200 OK (have it)
   
   HEAD /v2/myapp/blobs/sha256:layer2
                                    ───────→ 404 Not Found (need it)

4. Download missing layer
   GET /v2/myapp/blobs/sha256:layer2
                                    ───────→ 302 Redirect
                                              Location: https://s3.../layer2
   
   Client downloads from S3 directly (faster)

5. Verify integrity
   SHA256(downloaded_layer) == sha256:layer2 ✓



Push Flow (Similar)
──────────────────

1. Check layer existence
   HEAD /v2/myapp/blobs/sha256:newlayer
                                    ───────→ 404 Not Found
   
2. Initiate upload
   POST /v2/myapp/blobs/uploads/
                                    ───────→ 202 Accepted
                                              Location: /uploads/uuid

3. Upload layer chunks
   PATCH /v2/myapp/blobs/uploads/uuid
         (chunked data)
                                    ───────→ 202 Accepted

4. Finalize upload
   PUT /v2/myapp/blobs/uploads/uuid?digest=sha256:newlayer
                                    ───────→ 201 Created

5. Upload manifest
   PUT /v2/myapp/manifests/v1.0
       (manifest JSON)
                                    ───────→ 201 Created
```

---

---

## Base Image Strategies

### Textual Deep Dive

#### Internal Working Mechanism

**Base images** form the foundational layers of all Docker images—they are the starting points from which applications are built. Understanding base image selection is critical because:

1. **Layer Inheritance**: Every instruction in downstream Dockerfiles builds on base image layers
2. **Immutable Foundation**: Base layers are cached, reused, and affect all downstream images
3. **Supply Chain Security**: Base images are the primary vector for vulnerabilities affecting thousands of dependent images

##### Base Image Categories

```
┌──────────────────────────────────────────────────┐
│         Base Image Selection Matrix              │
├─────────────────┬───────────┬────────┬───────────┤
│ Category        │ Size      │ Library│ Use Case  │
├─────────────────┼───────────┼────────┼───────────┤
│ Distroless      │ 5-20MB    │ Min    │ Prod      │
│ Alpine          │ 5-10MB    │ Min    │ Prod      │
│ Debian Slim     │ 50-80MB   │ Std    │ General   │
│ Ubuntu Slim     │ 70-100MB  │ Std    │ General   │
│ Full OS         │ 200-500MB │ Full   │ Dev       │
│ Language-specific│ 500-2GB   │ Full   │ Dev/prod  │
└─────────────────┴───────────┴────────┴───────────┘
```

**Distroless Images** (Google maintained):
- Contain only application + runtime
- No shell, package manager, documentation
- Smallest possible footprint (5-20MB)
- Exceptional security (minimal attack surface)
- Limited debugging capabilities

**Alpine Linux**:
- Lightweight Linux distribution (5-10MB)
- Uses musl libc instead of glibc
- Package manager: `apk` (tiny package database)
- Trade-off: Some binary compatibility issues with glibc-only apps

**Debian/Ubuntu Slim**:
- Consensus middle ground
- Reasonable size (50-100MB)
- Familiar package ecosystem
- Debugging tools included
- Good balance for general purpose

**Full OS Images**:
- Complete operating systems (200-500MB)
- All development tools included
- Larger attack surface
- Simplicity for multi-purpose containers

**Language-Specific Images**:
- Pre-configured runtime + language SDK
- Optimized for specific language (Python, Node, Go, Java)
- Size depends on SDK (500MB-2GB)
- May include unnecessary dependencies

#### Architecture Role

Base image selection affects:

1. **Performance**: 5MB alpine pulls in 200ms; 500MB ubuntu in 2 seconds
2. **Security**: Fewer packages = fewer CVEs; distroless might have 0 vulnerabilities
3. **Maintainability**: Familiar OS (Ubuntu) vs. minimal (distroless)
4. **Compatibility**: musl vs. glibc can cause silent failures

#### Production Usage Patterns

##### Pattern 1: Progressive Minimization

Evolution of base image strategy as organization matures:

```
Phase 1 (Early): Use familiar OS (ubuntu:latest)
  Pros: Easy to debug, familiar tools
  Cons: Large, vulnerable, slow pull
  Example: 500MB image

Phase 2 (Optimization): Use debian:slim, alpine
  Pros: 10-20x smaller, faster CI/CD
  Cons: Less debugging capability, occasional compatibility issues
  Example: 50-100MB image

Phase 3 (Hardening): Use distroless or minimal base
  Pros: Minimal attack surface, fastest pulls
  Cons: Cannot shell into container for debugging
  Example: 10-20MB image
  (Debug using ephemeral debug containers or separate dev image)
```

##### Pattern 2: Multi-Stage with Different Base Images

```dockerfile
# Stage 1: Build (full OS with tools)
FROM ubuntu:22.04 AS builder
RUN apt-get update && apt-get install -y build-essential...
COPY src /src
RUN make

# Stage 2: Distroless runtime (tiny)
FROM gcr.io/distroless/base-debian11
COPY --from=builder /src/app /app
CMD ["/app"]
```

Result: Build tools excluded, final image is 20MB vs. 500MB

##### Pattern 3: Evaluated Base Image Selection

Organizations maintain a list of approved base images:

```yaml
# approved-bases.yaml
# Used in CI/CD to enforce standards

approved_base_images:
  - "gcr.io/distroless/base-debian11:nonroot"  # Prod: C, Go, Rust
  - "gcr.io/distroless/python3.11:nonroot"      # Prod: Python
  - "gcr.io/distroless/nodejs18-debian11:nonroot" # Prod: Node.js
  - "debian:12-slim"                            # General purpose
  - "alpine:3.18"                               # Minimal
  - "ubuntu:22.04"                              # Development only

unapproved_base_images:
  - "*:latest"                                  # Floating versions
  - "ubuntu:*" (except slim)                    # Full OS in prod
  - "centos:*"                                  # EOL images
```

#### DevOps Best Practices

##### 1. Default to Distroless or Alpine

```dockerfile
# ✅ Production Dockerfile
FROM gcr.io/distroless/base-debian11@sha256:6d57...
COPY app /app
CMD ["/app"]
```

##### 2. Use Separate Debug Image

```bash
# Production deployment uses distroless
kubectl run myapp-prod --image=myapp:v1.0

# Debug deployment (ephemeral) uses full OS
kubectl debug -it pod/myapp-prod \
  --image=mcr.microsoft.com/debug:1.0  # Ubuntu with tools
# Inspect production container's filesystem from debug container
# (exec into running container with full tooling)
```

##### 3. Pin Base Image Digests

```dockerfile
# Don't:  FROM python:3.11-slim
# Do:
FROM python:3.11-slim@sha256:5ca45f0b8...
```

Ensures:
- Reproducible builds across time
- Security patches only when explicitly updated
- Known baseline for vulnerability scanning

##### 4. Verify Base Image Supply Chain

```bash
#!/bin/bash
# verify-base-image.sh

BASE_IMAGE="python:3.11-slim@sha256:5ca45f0b8..."

echo "=== Scanning Base Image for Vulnerabilities ==="
docker scout cves "$BASE_IMAGE"

echo
echo "=== Checking Base Image Provenance ==="
docker inspect "$BASE_IMAGE" | jq '.[] | {
  Created,
  Author,
  OS,
  Architecture,
  Layers: (.RootFS.Layers | length),
  Size
}'

echo
echo "=== Base Image Security Posture ==="
# Check if image is signed
docker pull "$BASE_IMAGE" --verify-signature
```

##### 5. Stay Current on Base Image Updates

```bash
#!/bin/bash
# update-base-images.sh - Check for security updates

BASE_IMAGES=(
  "python:3.11-slim"
  "node:20-alpine"
  "golang:1.21"
)

for image in "${BASE_IMAGES[@]}"; do
    echo "Checking $image..."
    
    LATEST_DIGEST=$(docker pull "$image" | grep "Digest:" | cut -d' ' -f3)
    PINNED_DIGEST="sha256:..."  # current pin in repo
    
    if [ "$LATEST_DIGEST" != "$PINNED_DIGEST" ]; then
        echo "  ✓ Update available"
        echo "    Old: $PINNED_DIGEST"
        echo "    New: $LATEST_DIGEST"
        
        # Trigger rebuild with new digest
        git commit --allow-empty -m "Update base image: $image to $LATEST_DIGEST"
    fi
done
```

#### Common Pitfalls

##### Pitfall 1: Using Floating Base Image Tags

```dockerfile
# ❌ Problem
FROM python:3.11-slim  # Could be 3.11.0 or 3.11.8 depending on when pulled
# Different machines build different images

# ✅ Solution
FROM python:3.11.2-slim@sha256:abc123...  # Exact version and digest
```

##### Pitfall 2: Distroless Images Without Testing

```dockerfile
# ❌ Problem
FROM gcr.io/distroless/base-debian11
COPY myapp /
CMD ["/myapp"]

# Fails: /myapp uses glibc-specific syscall unavailable in musl
# No shell to debug the issue
```

**Solution**: Test base image compatibility before production:

```bash
# Build with distroless
docker build -f Dockerfile.distroless -t myapp:distroless .

# Test functionality
docker run --rm myapp:distroless  # Verify it works

# Test crash scenarios
docker run --rm myapp:distroless --help  # CLI works
docker run --rm myapp:distroless invalid-arg  # Error handling
```

##### Pitfall 3: Over-Optimizing for Size at the Cost of Functionality

```dockerfile
# ❌ Problem: Distroless missing critical tools
FROM gcr.io/distroless/python3.11:nonroot
COPY app.py /app/
RUN python /app/app.py --setup  # Fails: no shell
CMD ["python", "/app/app.py"]

# ✅ Solution: Use appropriate base for use case
FROM python:3.11-slim-bullseye  # Small but functional
COPY app.py /app/
RUN python /app/app.py --setup  # Works: has shell and tools
CMD ["python", "/app/app.py"]
```

##### Pitfall 4: Not Updating Base Images for Security

```bash
# ❌ Problem: Fixed Dockerfile, never updates
FROM ubuntu:20.04  # Built in 2020, has X known CVEs
# Deployed in 2026 with unpatched vulnerabilities

# ✅ Solution: Regularly pull new base images
FROM ubuntu:22.04@sha256:<LATEST>  # Regular updates
# CI/CD job rebuilds apps weekly with latest base digest
```

---

### Practical Code Examples

#### Example 1: Base Image Size Analysis

```bash
#!/bin/bash
# analyze-base-images.sh - Compare base image sizes and security

IMAGES=(
  "ubuntu:22.04"
  "debian:12-slim"
  "alpine:3.18"
  "gcr.io/distroless/base-debian11:nonroot"
  "python:3.11-slim"
  "python:3.11-alpine"
  "python:3.11"
)

echo "Base Image Comparison"
echo "──────────────────────────────────────────────────────"
printf "%-45s %10s %10s\n" "Image" "Size" "Vulns"
echo "──────────────────────────────────────────────────────"

for image in "${IMAGES[@]}"; do
    # Pull image
    docker pull "$image" > /dev/null 2>&1
    
    # Get size
    SIZE=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | \
      grep "$image" | awk '{print $2}')
    
    # Count vulnerabilities (requires docker scout)
    VULNS=$(docker scout cves "$image" --only-severity critical,high | grep -c "✗" || echo "0")
    
    printf "%-45s %10s %10s\n" "${image:0:45}" "$SIZE" "$VULNS"
done
```

#### Example 2: Multi-Stage Build with Strategic Base Selection

```dockerfile
# Dockerfile.optimized - Production-ready multi-stage

# Stage 1: Builder (includes all compile tools)
FROM golang:1.21-alpine AS builder
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Build static binary (no runtime dependencies)
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o myapp .

# Stage 2: Distroless runtime (no compile tools)
FROM gcr.io/distroless/base-debian11:nonroot
COPY --from=builder /src/myapp /
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/myapp"]
```

**Result**:
- Build stage: 600MB (includes Go SDK, build tools)
- Runtime stage: 12MB (only binary, no tools)
- Security: Distroless has 0 known vulnerabilities

#### Example 3: Base Image Update Workflow

```bash
#!/bin/bash
# update-base-images-workflow.sh

# Centralized base image update process

BASE_IMAGE_REGISTRY="myregistry.azurecr.io/base-images"

echo "=== Step 1: Sync Base Images from Upstream ==="

# Sync Python images
for version in 3.11 3.12; do
    for variant in slim alpine; do
        SOURCE="python:${version}-${variant}"
        TARGET="${BASE_IMAGE_REGISTRY}/python:${version}-${variant}"
        
        echo "Syncing ${SOURCE}..."
        docker pull "$SOURCE"
        docker tag "$SOURCE" "$TARGET"
        docker push "$TARGET"
    done
done

echo
echo "=== Step 2: Scan for Vulnerabilities ==="

IMAGES=$(curl -s "https://${BASE_IMAGE_REGISTRY}/v2/_catalog" | jq -r '.repositories[]')

for image in $IMAGES; do
    DIGEST=$(docker pull "${BASE_IMAGE_REGISTRY}/${image}" > /dev/null 2>&1)
    VULNS=$(docker scout cves "${BASE_IMAGE_REGISTRY}/${image}" | grep -c "✗" || echo "0")
    
    echo "${image}: ${VULNS} vulnerabilities"
    
    if [ "$VULNS" -gt 0 ]; then
        echo "  ⚠ Update recommended for ${image}"
    fi
done

echo
echo "=== Step 3: Trigger Downstream Rebuilds ==="

# Notify build system to rebuild all images using updated base
git clone https://github.com/myorg/build-system.git
cd build-system

cat >> base-image-update-trigger.txt <<EOF
Updated: python:3.11-slim
Updated: python:3.12-alpine
Trigger: All dependent apps

Apps to rebuild:
  - service-a (uses python:3.11-slim)
  - service-b (uses python:3.11-slim)
  - service-c (uses node:20-alpine)
EOF

git add base-image-update-trigger.txt
git commit -m "Trigger base image updates (security patches)"
git push

echo "✓ Downstream rebuild triggered"
```

---

### ASCII Diagrams

#### Diagram 1: Base Image Size Comparison

```
Image Size Comparison
────────────────────

gcr.io/distroless/base (5MB)
█

alpine:3.18 (10MB)
██

debian:12-slim (80MB)
████████████████

ubuntu:22.04 (100MB)
████████████████████

python:3.11-slim (200MB)
████████████████████████████████████████

python:3.11 (1000MB)
████████████████████████████████████████████████████████████████████████████...

Full OS image (500MB)
██████████████████████████████████████████████████████


Trade-offs:
───────────
Distroless:     ✓✓✓ Security  ✓✓ Speed  ✗ Debuggability
Alpine:         ✓✓ Security  ✓ Speed   ✓ Debuggability (limited)
Debian slim:    ✓ Security   ✗ Speed   ✓✓ Debuggability
Ubuntu:         ✗ Security   ✗ Speed   ✓✓✓ Debuggability
```

#### Diagram 2: Multi-Stage Build – Base Image Separation

```
Dockerfile: Multi-Stage Strategy
─────────────────────────────────

Stage 1: Builder (Development)
FROM golang:1.21-alpine (600MB)
  ├─ Go SDK
  ├─ Compilers
  ├─ Build tools
  └─ Source code
       │
       ▼ Compile
    Binary (15MB)
       │
       └──→ COPY --from=builder

Stage 2: Runtime (Production)
FROM gcr.io/distroless/base-debian11 (12MB)
  ├─ Binary (15MB copied from builder)
  ├─ CA certificates
  └─ Runtime only
  
       └──→ ENTRYPOINT ["/binary"]

Final Image: 12MB + 15MB = 27MB ✓
(Not 600MB + 15MB = 615MB ✗)
```

#### Diagram 3: Base Image Selection Decision Tree

```
Base Image Selection Framework
──────────────────────────────

Start: Choose base image for deployment
        │
        ├─ IS IT PRODUCTION WORKLOAD?
        │  ├─ YES → Performance/Security critical?
        │  │   ├─ YES (Latency < 100ms, High security) → Distroless ✓
        │  │   └─ NO → General purpose → Debian slim ✓
        │  │
        │  └─ NO (Development) → Full OS (ubuntu:22.04) ✓
        │
        ├─ DOES APP HAVE LANGUAGE REQUIREMENTS?
        │  ├─ Python → python:X.Y-slim ✓
        │  ├─ Node.js → node:X-alpine ✓
        │  ├─ Java → eclipse-temurin:X-jdk ✓
        │  ├─ Go/Rust → Statically linked binaries → Distroless ✓
        │  └─ C/C++ → Debian slim or Alpine
        │
        └─ COMPATIBILITY CONCERNS?
           ├─ glibc vs. musl → Test with Alpine
           ├─ Binary compatibility → Debian/Ubuntu preferred
           └─ Minimal CVE surface → Distroless preferred
           
→ Select from approved base images list
→ Pin specific digest
→ Test compatibility
→ Deploy
```

---

## Hands-on Scenarios

### Scenario 1: Optimize Large Image for Faster Deployment

**Problem**: Production image is 1.2GB; deployment takes 3 minutes to pull.

**Analysis**:
```bash
# Analyze current image
docker history myapp:current | head -20

# Results show:
# 900MB - node_modules installed
# 200MB - Development dependencies
# 100MB - Source code
```

**Solution**:

```dockerfile
# Original: 1.2GB
FROM node:18-ubuntu
COPY . /app
RUN npm install
EXPOSE 3000
CMD ["npm", "start"]

# Optimized multi-stage: 200MB
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["node", "index.js"]
```

**Results**: 1.2GB → 150MB (87% reduction); pull time: 3min → 18sec

---

### Scenario 2: Fix Application Failing with Distroless Base

**Problem**: App runs fine with `ubuntu:22.04`, but crashes with `gcr.io/distroless/base-debian11`

**Debugging**:
```bash
# Test with distroless
docker run --rm gcr.io/distroless/base-debian11 /app
# Output: /app: not found (or binary dependency missing)

# Investigation using intermediate image
FROM gcr.io/distroless/base-debian11
COPY app /
RUN /app  # Will fail, showing error

# Solution: Add debug container
docker run --rm -it ubuntu:22.04 /bin/bash
# Inside: ldd /app  # Check dependencies
# Output: libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6

# Problem identified: glibc dependency, but distroless is musl-based
```

**Solutions**:
1. Use `gcr.io/distroless/cc-debian11` (includes libc)
2. Compile statically (removes libc dependency)
3. Use `debian-slim` instead

---

### Scenario 3: Implement Layer Caching in CI/CD

**Problem**: Every code change triggers full rebuild (no cache reuse across CI/CD workers)

**Solution**:
```bash
#!/bin/bash
# ci-build-with-cache.sh

docker pull myregistry/myapp:latest || true

docker build \
  --cache-from myregistry/myapp:latest \
  -t myregistry/myapp:${BUILD_NUMBER} \
  -t myregistry /myapp:latest \
  .

docker push myregistry/myapp:${BUILD_NUMBER}
docker push myregistry/myapp:latest

```

**Cache Barrier Removal**:
```dockerfile
# ❌ Problem: CI_COMMIT_SHA changes every build
ARG CI_COMMIT_SHA
FROM ubuntu:22.04
RUN echo "Build: ${CI_COMMIT_SHA}"  # Cache miss every time!

# ✅ Solution: Use BuildKit
FROM ubuntu:22.04
COPY package*.json ./  # Stable until dependencies change
RUN npm install

# Then code changes only rebuild later layers
COPY . /app  # Code changes here
```

---

### Scenario 4: Create Reproducible Builds

**Problem**: Same Dockerfile builds different images on different days

**Causes/Solutions**:
```dockerfile
# ❌ Problem 1: Floating base image
FROM ubuntu:22.04  # Different version each day

# ✅ Solution: Pin digest
FROM ubuntu:22.04@sha256:abc123...

# ❌ Problem 2: apt-get not deterministic
RUN apt-get update && apt-get install -y curl  # Different versions daily

# ✅ Solution: Pin versions
RUN apt-get update && apt-get install -y curl=7.85.0-1ubuntu0.5

# ❌ Problem 3: Source timestamps  
COPY . /app  # Timestamps included in layer

# ✅ Solution: Normalize timestamps
COPY --chown=nobody:nogroup --chmod=0755 . /app
RUN find /app -exec touch -d @0 {} \;  # Set all timestamps to epoch
```

**Validation**:
```bash
# Build twice, compare digests
DIGEST1=$(docker build -q .)
DIGEST2=$(docker build -q .)

if [ "$DIGEST1" == "$DIGEST2" ]; then
    echo "✓ Reproducible"
else
    echo "✗ Non-reproducible"
fi
```

---

### Scenario 5: Implement Security Scanning in Layer Pipeline

**Problem**: Vulnerabilities in base layer not detected until deployment

**Solution**:
```bash
#!/bin/bash
# scan-base-image.sh

BASE_IMAGE="python:3.11-slim"

echo "=== Scanning Base Image ==="
docker pull "$BASE_IMAGE"
docker scout cves "$BASE_IMAGE"

echo
echo "=== Critical Issues ==="
docker scout cves "$BASE_IMAGE" | grep -E "✗.*CRITICAL|✗.*HIGH"

# Fail build if critical vulnerabilities
if docker scout cves "$BASE_IMAGE" | grep -q "CRITICAL"; then
    echo "✗ Base image has critical vulns - cannot proceed"
    exit 1
fi

echo "✓ Base image security approved"
```

---

## Interview Questions

### 1. Explain the difference between image layers and containers. How does this architecture enable efficient resource sharing?

**Expected Answer**:
- **Image layers**: Read-only filesystem snapshots created during build; immutable once created
- **Containers**: Writable instances of images with temporary layer added on top
- **Resource sharing**: Multiple containers can share image layers (deduplication at filesystem and registry level)

**Example**:
```
Image Layers (shared):
  ├─ ubuntu:22.04 base layers → 70MB (shared across 1,000 apps)
  ├─ app-a specific layers → 50MB
  └─ app-b specific layers → 60MB

Containers:
  ├─ Container A (writable layer) → 2MB writes
  ├─ Container B (writable layer) → 5MB writes  
  ├─ Container C (writable layer) → 1MB writes

Total storage: 70 + 50 + 60 + 2 + 5 + 1 = 188MB
Without sharing: 70×3 + 50 + 60 = 290MB
Result: 35% storage savings through layer sharing
```

---

### 2. How does Docker's layer caching work, and what strategies would you use to optimize builds in CI/CD?

**Expected Answer**:
- **Cache mechanism**: SHA256 hash of parent layer + instruction + file content; cache hit if hash matches
- **Cache invalidation**: Linear and atomic; one miss invalidates all subsequent layers
- **Optimization strategies**:
  1. Order by stability (base image → system deps → app code)
  2. Use `.dockerignore` to exclude irrelevant files
  3. Multi-stage builds to exclude build tools
  4. Pull latest tag before building to reuse registry cache
  5. Copy dependency files before source code

**CI/CD Example**:
```bash
docker pull "${REGISTRY}/${IMAGE}:latest" || true
docker build \
  --cache-from "${REGISTRY}/${IMAGE}:latest" \
  --tag "${REGISTRY}/${IMAGE}:${BUILD_ID}" \
  .
```

---

### 3. Why is digest pinning important, and when would you use tags vs. digests in production?

**Expected Answer**:
- **Tags are mutable**: They can point to different images over time (security patches update tags)
- **Digests are immutable**: SHA256 hash always references exact content
- **Production usage**: Always use digests to guarantee version remains unchanged

**Example**:
```dockerfile
# ❌ Tag (mutable)
FROM ubuntu:22.04  # Could be patched without notice

# ✅ Digest (immutable)
FROM ubuntu:22.04@sha256:abc123...  # Specific version
```

**Use case**: 
- **Development**: Tags acceptable (`latest`, `main-build`)
- **Production**: Digests required (`image@sha256:...`)
- **Staging**: Digests or stable tags

---

### 4. Explain content addressability and how registries dedup image layers. What are the implications for large-scale deployments?

**Expected Answer**:
- **Content addressability**: Layers stored by SHA256 hash, not by name/tag
- **Deduplication**: Same layer content stored once, referenced by multiple images
- **Registry efficiency**: If 100 apps use `ubuntu:22.04`, base layers stored once

**Implications**:
```
Scenario: 500 microservices, all based on ubuntu:22.04
──────────────────────────────────────────────────────
Without dedup: 500 × 70MB = 35GB
With dedup: 70MB + (service-specific layers)
Result: 99% storage savings in real deployments
```

---

### 5. What are the trade-offs of different base image choices? How would you select between distroless, alpine, and ubuntu?

**Expected Answer**:

| Base Image | Size | Security | Debuggability | Compatibility |
|-----------|------|----------|---------------|---------------|
| distroless | 5-20MB | Excellent | Poor | Requires testing |
| Alpine | 5-10MB | Good | Limited | musl vs glibc issues |
| Debian/Ubuntu slim | 50-100MB | Adequate | Good | Excellent |
| Full OS | 200-500MB | Poor | Excellent | Excellent |

**Selection criteria**:
- **Production, performance-critical**: distroless
- **Production, balanced**: debian-slim + multi-stage
- **Development**: ubuntu:22.04 (full tools)
- **Kubernetes**: distroless + separate debug image

---

### 6. Design a secure layer scanning and validation strategy for a company with 100+ microservices.

**Expected Answer** should include:
- **Scan frequency**: Scan base images on update, app images on build, deployed images continuously
- **Approval workflow**: Approved base image whitelist; auto-reject unapproved
- **Vulnerability handling**: Critical = block deployment; High = require justification
- **Automation**: Build fails if base image has unpatched CVEs

**Implementation**:
```bash
#!/bin/bash
# Pre-deployment validation

IMAGE="$1"

# Scan for vulnibilities
docker scout cves "$IMAGE" --format sarif > results.json

# Extract critical/high
CRITICAL=$(jq '[.runs[].results[] | select(.level=="error")] | length' results.json)
HIGH=$(jq '[.runs[].results[] | select(.level=="warning")] | length' results.json)

if [ "$CRITICAL" -gt 0 ]; then
    echo "✗ Cannot deploy: $CRITICAL critical vulnerabilities"
    exit 1
elif [ "$HIGH" -gt 5 ]; then
    echo "⚠ Requires manual approval: $HIGH high vulnerabilities"
    # Require manual review before deployment
fi

echo "✓ Image approved for deployment"
```

---

### 7. You notice your image is 2GB but application binary is only 200MB. Where is the bloat, and how would you optimize?

**Expected Answer**:
- **Common culprits**: Build tools (gcc, make), compilers (Go SDK, JDK), temp files, dependency caches
- **Optimization approach**: Multi-stage build to exclude build tools from final layer

**Analysis**:
```bash
docker history myapp:current
# Layer 1: 800MB - Go SDK compiler
# Layer 2: 600MB - build dependencies, git repos
# Layer 3: 200MB - compiled binary
# Layer 4: 400MB - documentation, test files

# Optimization: Multi-stage
# Stage 1: Build with all tools (1.x GB)
# Stage 2: Copy only binary (200MB)
# Final: 200MB image
```

---

### 8. Describe a scenario where immutability of image layers prevented a production incident.

**Expected Answer** might describe:
- **Scenario**: Base image "ubuntu:latest" received security update that broke app
- **With immutability**: Previous version still exists in registry; instant rollback to working version
- **Without immutability**: Previous version overwritten; forced to rebuild or patch

**Example**:
```bash
# Monday: Deploy version A
kubectl set image deployment/myapp \
  myapp=myregistry/myapp@sha256:abc123...  # Immutable

# Wednesday: Base image security patch breaks compatibility
# New digest is different, no automatic update

# Rollback is instant (digest still exists)
kubectl set image deployment/myapp \
  myapp=myregistry/myapp@sha256:abc123...  # Reverts to working version

# Without digests:
# Old tag (myapp:v1.0) now points to broken version
# No easy rollback
```

---

### 9. How would you verify that two Docker images, built months apart, are identical in functionality and dependencies?

**Expected Answer**:
- **Compare digests**: Identical digests = identical content
- **Compare manifests**: Extract and compare JSON manifests
- **Verify layer counts and sizes**: Should be identical
- **Diff tool**: Use `docker scout` or `dive` to compare layer contents
- **Binary comparison**: Compare internal file checksums


**Implementation**:
```bash
#!/bin/bash
# compare-images.sh

IMAGE1="myapp:v1.0.0@sha256:abc123..."
IMAGE2="myapp:v1.0.0-rebuilt@sha256:def456..."

echo "=== Comparing Images ==="

# Method 1: Digest comparison
DIGEST1=$(docker inspect "$IMAGE1" --format='{{.RepoDigests}}')
DIGEST2=$(docker inspect "$IMAGE2" --format='{{.RepoDigests}}')

if [ "$DIGEST1" == "$DIGEST2" ]; then
    echo "✓ Images are identically reproducible"
    exit 0
fi

# Method 2: Manifest comparison
MANIFEST1=$(docker manifest inspect "$IMAGE1")
MANIFEST2=$(docker manifest inspect "$IMAGE2")

diff <(echo "$MANIFEST1") <(echo "$MANIFEST2")
```

---

### 10. Explain how Docker Registry V2 API handles push/pull operations and content-based addressing. What are performance implications?

**Expected Answer**:
- **Push process**: Upload layers as blobs (content hash); upload manifest linking to blobs; registry deduplicates
- **Pull process**: Fetch manifest; check local cache for layers; pull missing layers; mount as read-only
- **Content-addressing**: Each blob identified by SHA256; identical content reused across images

**Performance implications**:
```
Push:
  ├─ Layer check (HEAD /blobs/{digest}) → Cache exists? (instant)
  ├─ Layer upload (if needed) → 50-100MB base → 1-5 seconds
  └─ Manifest upload → Metadata → 100ms

Pull:
  ├─ Manifest fetch → Identify layers needed
  ├─ Layer check (local cache) → 15MB already present? (instant)
  ├─ Layer download (registry or cloud storage)
  │  ├─ 50MB over 1Gbps → 400ms
  │  └─ 50MB over residential internet → 10-30 seconds
  └─ Mount layers (instant with overlay FS)

Deduplication Impact:
  └─ Pull base layers once (50MB) → multiple app pulls reuse (instant after first)
```

---

### 11. What strategies would you use to minimize the attack surface of a containerized application in production?

**Expected Answer** should cover:
1. **Base image**: Distroless minimal footprint
2. **Dependency reduction**: Remove dev tools, documentation
3. **Non-root user**: Run as unprivileged user
4. **Read-only filesystem**: Make filesystem read-only when possible
5. **Layer scanning**: Scan for CVEs before deployment
6. **Signature verification**: Verify image provenance

**Implementation**:
```dockerfile
# Hardened production image
FROM gcr.io/distroless/base-debian11:nonroot

# Copy only necessary files
COPY --chown=nonroot:nonroot app /app
COPY --chown=nonroot:nonroot config /etc/config

# Set read-only capabilities
RUN chmod 555 /app
RUN chmod 444 /etc/config

# All distroless containers run non-root by default
USER nonroot:nonroot

# Read-only filesystem enforced at runtime
# (add to Kubernetes manifest)
```

**Kubernetes enforcement**:
```yaml
securityContext:
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65534  # nonroot
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
volumeMounts:
  - name: tmp
    mountPath: /tmp
volumes:
  - name: tmp
    emptyDir: {}
```

---

**End of Study Guide**

---

### Document Summary

This comprehensive Senior DevOps study guide covers Docker Images & Layers with:

- **Foundational Concepts** (9 key principles + 6 common misunderstandings)
- **Deep Dives** on 4 major subtopics (Layers & Caching, Immutability, SHA Digests & Manifests, Registries & Distribution)
- **Base Image Strategies** with selection frameworks and practical optimization
- **5 Hands-on Scenarios** with real-world problem-solving
- **11 Technical Interview Questions** with expected answers

**Total Study Time**: 3-4 hours for comprehensive learning; 2-3 hours for targeted review

**Recommended Approach**:
1. Start with Foundational Concepts (30 min)
2. Deep dive subtopics in order (2 hours)
3. Practice hands-on scenarios (30 min)
4. Review interview questions (30 min)
5. Build your own multi-stage Dockerfile applying learned patterns

