# Linux Administration: Security Hardening, System Resource Controls, Kernel & System Tuning, Remote Access & System Control

**Study Guide for Senior DevOps Engineers**  
*Audience: DevOps professionals with 5–10+ years of experience*  
*Last Updated: March 2026*

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Security Hardening](#security-hardening)
4. [System Resource Controls](#system-resource-controls)
5. [Kernel & System Tuning](#kernel--system-tuning)
6. [Remote Access & System Control](#remote-access--system-control)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Linux security hardening, system resource controls, kernel tuning, and remote access management form the cornerstone of production-grade infrastructure management. As a Senior DevOps engineer, you must master these four interdependent domains to:

- **Secure** systems against multi-layered threats
- **Optimize** resource allocation and prevent resource exhaustion
- **Tune** kernels for performance and security trade-offs
- **Manage** remote infrastructure with scalability and compliance in mind

This study guide synthesizes enterprise patterns, NIST guidelines, CIS benchmarks, and real-world production scenarios that you'll encounter in large-scale environments.

### Why It Matters in Modern DevOps Platforms

**Security Hardening** ensures defense-in-depth across your infrastructure:
- Prevents privilege escalation and lateral movement
- Enforces compliance (SOC 2, PCI-DSS, HIPAA, GDPR)
- Reduces attack surface in containerized and multi-tenant environments
- Enables zero-trust architecture principles

**System Resource Controls** prevent noisy neighbors and cascading failures:
- Isolates container workloads in Kubernetes clusters
- Prevents resource starvation attacks
- Enables fair resource distribution in shared infrastructure
- Critical for cost optimization and SLA compliance

**Kernel & System Tuning** bridges performance and stability:
- Handles millions of concurrent connections (high-frequency trading, streaming, CDNs)
- Optimizes I/O for database-heavy workloads
- Prevents memory exhaustion and OOM killer incidents
- Tunes TCP stack for global infrastructure

**Remote Access & System Control** enables global operations:
- Centralized management across distributed data centers
- Secure bastion host architecture for zero-trust networks
- Audit trails for compliance and incident investigation
- Automation foundation for CI/CD and infrastructure-as-code

### Real-World Production Use Cases

#### Case Study 1: Kubernetes Cluster Security
A financial services org deployed a multi-tenant Kubernetes cluster without proper Linux hardening. Attack vector: Container escape → Node compromise → Lateral movement to secrets management. Solution: SELinux policies + seccomp + AppArmor profiles + strict RBAC mitigated risk.

#### Case Study 2: Resource Contention in Shared Environments
E-commerce platform experienced unpredictable latency spikes during peak traffic. Root cause: Noisy neighbors—batch jobs consuming memory without limits. Solution: Implemented cgroups v2, memory limits, and CPU quotas per namespace, reducing p99 latency by 60%.

#### Case Study 3: Kernel Tuning for Scale
SaaS platform hitting TCP connection limits on load balancers. Traditional tuning (increasing ulimit) wasn't enough. Solution: Tuned `net.ipv4.tcp_tw_reuse`, `net.core.somaxconn`, and `net.ipv4.tcp_max_syn_backlog` for 100K+ concurrent connections.

#### Case Study 4: SSH at Scale
Managed service provider needed to rotate SSH keys across 10K+ servers monthly. Manual SSH key management was unsustainable. Solution: Implemented certificate-based authentication + bastion hosts + centralized PAM for audit logging.

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────┐
│        Cloud Platform (AWS, Azure, GCP)         │
├─────────────────────────────────────────────────┤
│  IAM / Networking / Monitoring (Cloud Layer)    │
├─────────────────────────────────────────────────┤
│  ┌──────────────────────────────────────────┐   │
│  │    EC2 / VM Layer                         │   │
│  │  ┌──────────────────────────────────────┐ │   │
│  │  │  Bastion Host / Jump Host            │ │   │
│  │  │  (SSH Hardening, MFA, Audit)          │ │   │
│  │  └──────────────────────────────────────┘ │   │
│  ├──────────────────────────────────────────┤ │   │
│  │  Worker Nodes / Application Servers      │ │   │
│  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  OS Kernel Layer                      │ │ │  │
│  │  │  • Kernel Tuning (sysctl params)      │ │ │  │
│  │  │  • Kernel Modules (netfilter, etc)    │ │ │  │
│  │  │  • Memory & CPU Scheduling            │ │ │  │
│  │  └──────────────────────────────────────┘ │ │  │
│  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  Container Runtime Layer              │ │ │  │
│  │  │  • cgroups (v1/v2) - Resource Control│ │ │  │
│  │  │  • namespaces - Process Isolation     │ │ │  │
│  │  │  • SELinux/AppArmor - MAC             │ │ │  │
│  │  └──────────────────────────────────────┘ │ │  │
│  │  ┌──────────────────────────────────────┐ │ │  │
│  │  │  Linux OS Security Layer              │ │ │  │
│  │  │  • User/Group Management (UID/GID)    │ │ │  │
│  │  │  • File Permissions & ACLs            │ │ │  │
│  │  │  • Sudo Configuration                 │ │ │  │
│  │  │  • SELinux/AppArmor Policies          │ │ │  │
│  │  │  • Firewall (iptables/nftables)       │ │ │  │
│  │  │  • File Integrity Monitoring          │ │ │  │
│  │  │  • auditd & System Logging            │ │ │  │
│  │  │  • Intrusion Detection (fail2ban)     │ │ │  │
│  │  └──────────────────────────────────────┘ │ │  │
│  └──────────────────────────────────────────┘ │   │
└─────────────────────────────────────────────────┘
```

These layers are **interdependent**: SSH hardening requires proper user management; resource controls require kernel tuning; security auditing requires proper logging.

---

## Foundational Concepts

### Key Terminology

#### Security Concepts

| Term | Definition | DevOps Context |
|------|-----------|-----------------|
| **Privilege Escalation** | Non-privileged user gaining root access | Core threat in multi-tenancy; mitigated by sudo, SELinux, capabilities |
| **Lateral Movement** | Attacker moving from one system to another | In containerized environments, network policies + SELinux prevent this |
| **Defense-in-Depth** | Multiple overlapping security layers | Firewall → OS hardening → Application-level controls |
| **DAC (Discretionary Access Control)** | Owner controls permissions (traditional Unix) | `chmod`, `chown` based on file ownership |
| **MAC (Mandatory Access Control)** | OS enforces policy regardless of ownership | SELinux, AppArmor—enforced by kernel |
| **Capabilities** | Fine-grained privileges replacing all-or-nothing sudo | `cap_net_bind_service` instead of full root for binding ports <1024 |
| **File Integrity Monitoring (FIM)** | Detecting unauthorized file changes | AIDE, Tripwire, osquery for compliance |

#### Resource Control Concepts

| Term | Definition | DevOps Context |
|------|-----------|-----------------|
| **cgroups (Control Groups)** | Kernel mechanism to limit, prioritize, account resources | Foundation of containerization; v2 unified hierarchy simplifies policy |
| **Namespace** | Process isolation layer (PID, network, mount, user, IPC) | Docker containers = cgroups + namespaces |
| **ulimit** | User-level resource limits (file descriptors, processes, memory) | Per-login shell limits; hard limit protects system |
| **OOM Killer** | Kernel process terminator when memory exhausted | Graceful shutdown better than OOM; implement memory limits before this fires |
| **CPU Throttling vs. Bursting** | Hard CPU limits vs. allowing temporary CPU usage | Kubernetes QoS classes: Guaranteed (hard) vs. Burstable (soft) |
| **I/O Throttling** | Limiting disk read/write operations | Prevents batch jobs from starving database I/O |

#### Kernel & Tuning Concepts

| Term | Definition | DevOps Context |
|------|-----------|-----------------|
| **sysctl** | Kernel parameter configuration interface | `/proc/sys` changes; persist through `/etc/sysctl.conf` |
| **Kernel Module** | Dynamically loadable kernel code | `modprobe` for netfilter, overlay filesystems, eBPF programs |
| **TCP State Machine** | Connection lifecycle (SYN, ESTABLISHED, TIME_WAIT, etc.) | TIME_WAIT flooding on high-throughput systems; tune tw_reuse/tw_recycle |
| **Huge Pages** | Memory pages >4KB (2MB or 1GB) | Reduces TLB misses for databases; memory waste trade-off |
| **Swap** | Disk-based memory extension | Avoid in production; causes unpredictable latency; use zswap instead |
| **swappiness** | Kernel tendency to swap vs. reclaim cache | Lower values (10-20) in production; 60 default causes issues |

#### Remote Access Concepts

| Term | Definition | DevOps Context |
|------|-----------|-----------------|
| **SSH Key-Based Auth** | Public/private key pair instead of passwords | Industry standard; eliminate password auth in production |
| **Certificate-Based Auth** | SSH certs instead of per-key management | Scales to 10K+ servers; enables revocation without key redistribution |
| **Bastion Host (Jump Host)** | Hardened gateway for accessing internal systems | Single audit point; reduces exposed surface for 10K+ servers |
| **SSH Multiplexing** | Share connection over single TCP channel | Reduces latency for sequential commands from automation |
| **Port Forwarding** | Tunneling internal services through SSH | Local tunneling for database access; remote tunneling for exposing services |
| **Agent Forwarding** | Forwarding SSH keys to bastion for further hops | Works but has security implications; certificate-based auth preferred |

### Architecture Fundamentals

#### 1. Security Hardening Architecture

**Layered Security Model (Defense-in-Depth)**

```
Layer 1: Network Level
├── Network Segmentation (VPC, subnets, security groups)
├── Firewall Rules (iptables/nftables)
└── Intrusion Detection (IDS/IPS)

Layer 2: OS Level (This Study Guide)
├── User/Group Management (UID/GID, sudoers)
├── File Permissions & ACLs (DAC)
├── OS-Level Firewall (iptables/nftables)
├── SELinux/AppArmor (MAC)
├── File Integrity Monitoring (AIDE, auditd)
└── Security Tools (fail2ban, rkhunter, osquery)

Layer 3: Application Level
├── Input Validation
├── Secure Coding Practices
└── Application-Level Encryption

Layer 4: Data Level
├── Encryption at Rest
├── Encryption in Transit
└── Key Management
```

**SSH Hardening Context within Architecture:**
- SSH is network-exposed (Layer 2 boundary)
- SSH authentication = identity verification
- SSH authorization = access control (sudoers + OS permissions)
- SSH audit logging = compliance trail

#### 2. Resource Control Architecture

**Hierarchy of Resource Constraints (Cascade)**

```
Hardware Limits (Physical CPU cores, RAM, disk bandwidth)
           ↓
Kernel Level (max open files, network buffers)
           ↓
cgroups v2 (CPU shares, memory limits, I/O throttling)
           ↓
ulimit (per-login shell limits)
           ↓
Application-Level Limits (thread pools, connection pools)
           ↓
Monitoring & Alerting (detect violations early)
```

**Why This Matters:**
- Missing any layer = cascading failures
- Example: Setting memory limit without swappiness tuning = OOM killer
- Example: Tuning TCP stack without cgroup limits = noisy neighbors

#### 3. Kernel Tuning Architecture

**Feedback Loop: Workload → Monitoring → Tuning → Validation**

```
Production Workload
        ↓
Baseline Metrics (perf, sar, netstat)
        ↓
Identify Bottleneck (CPU? Memory? I/O? Network?)
        ↓
Locate Kernel Parameter (sysctl, module param)
        ↓
Understand Trade-off (throughput vs. latency? Memory vs. CPU?)
        ↓
Test in Staging (never in prod without validation)
        ↓
Monitor After Change (check for regression)
        ↓
Document Decision (maintain runbook for team)
```

#### 4. Remote Access Architecture

**Bastion-Based Access Pattern (Zero-Trust)**

```
External Network
        ↓
    Bastion Host (Public Internet Accessible)
    ├── SSH Key-Based (or Cert-Based) Auth
    ├── MFA (Optional but Recommended)
    ├── IP Allowlist
    ├── Connection Logging
    └── Rate Limiting
        ↓
Internal Network (Private Subnets)
    ├── Worker Node 1 (SSH from Bastion Only)
    ├── Worker Node 2 (SSH from Bastion Only)
    └── Worker Node N (SSH from Bastion Only)
```

**Why Bastion Instead of Direct SSH:**
- Single audit point instead of N nodes
- Simplified SSH key management (rotate bastion key, not 10K server keys)
- Network policy: Only bastion allowed for SSH to internal nodes
- Enables centralized logging: `auditd` on bastion captures all internal access

### Important DevOps Principles

#### 1. Least Privilege (PoLP)

**Principle:** Users and processes run with minimum necessary permissions.

**Application:**
- Don't run containers as root; use unprivileged users + capabilities
- Don't give sudo access to all developers; use `sudoers` with specific commands
- Don't expose SSH to all developers; use bastion + role-based access
- Implement SELinux policies that deny by default (rather than allow by default)

**Trade-off:** Tighter security vs. ease of troubleshooting. Senior engineers debug within constraints.

#### 2. Defense-in-Depth

**Principle:** No single security control is sufficient; layers provide redundancy.

**Application:**
- Firewall blocks port 22 externally BUT SSH hardening (key-based auth, fail2ban) still required
- SELinux restricts file access BUT file permissions (DAC) still enforced
- Sudo audit logging BUT auditd and syslog aggregation provide central trail

**Trade-off:** Operational complexity increases with each layer. Justify each layer with threat model.

#### 3. Defense Against Known Attacks

**Common Linux Attacks & Mitigations:**

| Attack Vector | Mitigation | Ownership |
|---------------|-----------|-----------|
| Brute-force SSH login | Fail2ban rate limiting + key-based auth | This Guide (SSH Hardening) |
| Privilege escalation via sudo | auditing sudoers + file integrity checks | This Guide (Security Hardening) |
| Container escape + host compromise | SELinux + seccomp + AppArmor policies | This Guide (Security Hardening) |
| Resource starvation attack | cgroups limits + monitoring | This Guide (Resource Controls) |
| Network stack exhaustion | sysctl tuning + rate limiting | This Guide (Kernel Tuning) |
| Malicious kernel module | SELinux + file integrity + auditd | This Guide (Security Hardening + Tuning) |

#### 4. Observability & Auditability

**Principle:** If you can't measure it, you can't manage it. If you can't audit it, you can't comply with it.

**Application:**
- Linux auditing (auditd) captures who did what, when, where
- Resource monitoring (cgtop, sar, vmstat) identifies anomalies
- Syslog aggregation enables central security incident detection
- SSH audit logging provides authentication trail for forensics

#### 5. Production Readiness Checklist

Before deploying systems to production, validate:

- [ ] SELinux or AppArmor is running in enforcing mode
- [ ] SSH key-based authentication is enabled; password disabled
- [ ] Sudo access is audited via auditd or syslog aggregation
- [ ] Resource limits (cgroups/ulimit) are in place for all services
- [ ] Kernel parameters are tuned for workload and persistent via sysctl.d
- [ ] Firewall rules (iptables/nftables) align with network security policy
- [ ] File integrity monitoring is enabled for critical binaries
- [ ] Bastion host is deployed for remote access; direct SSH not allowed
- [ ] Centralized logging aggregates all security events
- [ ] Regular patching strategy is automated (unattended-upgrades, Patch Manager)

### Best Practices

#### Security Hardening Best Practices

1. **CIS Benchmark Compliance**: Follow Center for Internet Security (CIS) benchmarks for your OS (RHEL, Ubuntu, Debian). Automate via Ansible/Terraform.

2. **Minimal Install**: Deploy only required packages. Remove unnecessary services (X11, telnet, ftp). Reduces attack surface.

3. **Immutable Infrastructure**: Use image-based deployments (Packer) rather than config drift. Security patches = new image, not post-deployment scripts.

4. **Secrets Management**: Never hardcode SSH keys or credentials. Use HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault.

5. **Regular Patching**: Automate security updates via unattended-upgrades or Patch Manager. Test in staging first.

6. **Capability-Based Security**: Leverage Linux capabilities instead of setuid binaries. Example: `cap_net_bind_service` instead of setuid curl.

#### Resource Control Best Practices

1. **Set Defaults, Override Exceptions**: cgroups should default-limit all containers. Whitelist high-performance workloads instead of blacklisting.

2. **Monitor Along with Limits**: Memory limit without monitoring = surprise OOM. Pair limits with Prometheus/Datadog alerts.

3. **Test Limit Enforcement**: Validate cgroup limits in staging before production. Example: `stress --vm 1 --vm-bytes 512M` should trigger OOM killer when limit is 256M.

4. **Avoid Hard CPU Limits**: CPU limits (cpu.max in cgroups v2) cause unpredictable latency. Use CPU shares (cpu.weight) instead.

5. **Namespace Isolation**: Containers should have separate PID, network, and mount namespaces. Never run with `--pid=host` or `--network=host` unless justified.

#### Kernel Tuning Best Practices

1. **Understand the Trade-off**: Every kernel parameter change optimizes for one metric at the cost of another. Document your trade-off decisions.

2. **Baseline Before Tuning**: Capture metrics (latency, throughput, memory) before and after tuning. Validate improvement before rollout.

3. **Tune in Sequence, Not Parallel**: Change one parameter, observe impact, then change next. Parallel changes mask cause-effect relationships.

4. **Persist via sysctl.d**: Don't edit `/etc/sysctl.conf` directly. Create `/etc/sysctl.d/99-custom.conf` for version control and clarity.

5. **Monitor for Side Effects**: Tuning TCP window size may help throughput but increase memory. Monitor memory trends after network tuning.

6. **Workload-Specific Tuning**: Database servers need different tuning than load balancers. No universal "best practices"—tune for your workload.

#### Remote Access Best Practices

1. **SSH Protocol**, not SSHv1: Disable SSHv1 via `Protocol 2` in `/etc/ssh/sshd_config`.

2. **Key Rotation on Schedules**: Rotate SSH keys quarterly (or use certificate-based auth with shorter TTLs like 24-hour certs).

3. **Bastion Host Architecture**: Central audit point beats distributed SSH hardening. Bastion should be the only SSH-exposed system.

4. **Monitoring Bastion Access**: Log all SSH connections to bastion (via auditd or PAM logs). Alert on failed authentication spikes (potential breach).

5. **Avoid SSH Agent Forwarding**: Instead, deploy service accounts with certificate-based auth that has short TTLs.

6. **Session Recording**: osquery or auditd records shell commands executed. Meets compliance requirements for privileged access.

### Common Misunderstandings

#### Misunderstanding 1: SELinux = "That One Tool That Breaks Everything"

**Reality:** SELinux is poorly designed for user-facing machines but excellent for servers. In production:
- SELinux prevents 90% of privilege escalation attacks
- "Disabling SELinux" = removing the most critical hardening layer
- Proper SELinux policy takes effort but ROI is security

**Correct Approach:** 
- Learn SELinux booleans: `getsebool -a` lists toggles for common scenarios
- Use audit mode (`semanage permissive -a httpd_t`) to capture violations without blocking
- Gradually enforce policies as you understand them

#### Misunderstanding 2: sudo = Fine-Grained Access Control

**Reality:** sudo is a tool, not a security boundary. Common pitfalls:
- `user ALL=(ALL) ALL` = sudo with no restrictions = nearly as dangerous as root access
- sudo doesn't prevent privilege escalation via exploits; it's administrative convenience
- auditd logs sudo commands, but doesn't prevent misuse

**Correct Approach:**
- Use sudoers with specific commands: `user ALL=(root) /bin/systemctl restart nginx`
- Pair sudo audit logging with centralized siem/syslog aggregation
- SELinux + sudo = defense-in-depth (if SELinux fails, sudo audit catches it)

#### Misunderstanding 3: cgroups Limits = Performance Guarantees

**Reality:** cgroups enforces limit but doesn't guarantee performance:
- Setting `memory.max = 2GB` guarantees no *more* than 2GB, but doesn't guarantee 2GB is available
- CPU shares are proportional, not absolute; 6 processes with equal shares share available CPU
- OOM killer is unpredictable; graceful shutdown is better

**Correct Approach:**
- Use cgroups for isolation and fairness, not performance guarantees
- Pair with monitoring: detect when limits are hit (memory pressure, throttling)
- Application level: connection pooling, request queuing, graceful degradation

#### Misunderstanding 4: Network Tuning = Increasing Buffer Sizes

**Reality:** Blindly increasing `net.core.rmem_max` doesn't fix slow networks:
- Kernel buffers help bursty traffic; sustained throughput is bound by link capacity
- Increasing buffers without understanding TCP state = wasted memory + increased OOM risk
- BDP (Bandwidth-Delay Product) calculation required for optimal buffer sizing

**Correct Approach:**
```
BDP (bits) = Bandwidth (bps) × Latency (seconds)
Example: 1 Gbps link, 200ms RTT = 1e9 × 0.2 = 200 Mb = 25 MB
Recommended socket buffer = 2 × BDP = 50 MB
```

#### Misunderstanding 5: SSH Keys = Perfect Security

**Reality:** SSH keys eliminate password guessing but introduce new risks:
- Keys stored in source code = catastrophic breach
- Keys with weak passphrases = guessing is possible
- Stolen bastion host = attacker controls all downstream systems
- Key rotation at scale is difficult (10K+ servers)

**Correct Approach:**
- Certificates instead of static keys (TTL limits exposure)
- Key management via Vault or cloud key service
- Bastion host: harden separately with monitoring, MFA, IP allowlists

---

## Security Hardening

### Textual Deep Dive

#### Internal Working Mechanism

Linux security hardening creates multiple layers of authorization checks:

1. **User/Group Management (UID/GID)**
   - Every process runs with UID and GID, inheriting from parent
   - Kernel enforces DAC (Discretionary Access Control) checks at syscall level
   - Special UIDs: 0 (root), 1-999 (system users), 1000+ (human users)
   - Group membership enables file access without changing ownership

2. **File Permissions (DAC)**
   - 12-bit permission model: 3 bits owner, 3 bits group, 3 bits others, 3 bits special (setuid, setgid, sticky)
   - Kernel checks on every file access: open(), read(), write(), execute()
   - Execute on directories = traverse permission (can access contents)
   - Umask controls default permissions on file creation

3. **ACLs (Access Control Lists)**
   - Extended permissions beyond 3-digit owner/group/others
   - Enable granular access: `setfacl -m g:developers:rx /var/log/app.log`
   - Stored as extended attributes (xattr); transparent to traditional tools
   - Performance: ACL checks are more expensive than DAC; use sparingly on hot paths

4. **sudo & Privilege Escalation**
   - sudo = execution as different user (usually root) after authentication
   - sudoers file (`/etc/sudoers`) defines who can run what, with or without password
   - PAM (Pluggable Authentication Modules) validates user credentials
   - Audit trail: syslog logs all sudo commands with timestamp, user, command

5. **SSH Hardening**
   - Public-key cryptography: server verifies client owns private key without exposing it
   - Key exchange (Diffie-Hellman) establishes shared cipher key
   - Session encryption (AES-256, ChaCha20) protects all data in flight
   - Port 22 is public but firewall, fail2ban, and key-only auth mitigate brute-force

6. **Firewall (iptables/nftables)**
   - Kernel netfilter subsystem applies rules at network layer
   - Stateful inspection: tracks TCP states (SYN, ESTABLISHED, FIN)
   - Connection tracking enables "RELATED,ESTABLISHED" rules (allows related traffic)
   - nftables is newer, supports maps and better performance; iptables is legacy but widely used

7. **SELinux/AppArmor (MAC - Mandatory Access Control)**
   - Kernel enforces security policies beyond file ownership
   - SELinux uses labels (context): user, role, type, level
   - AppArmor uses path-based rules: more intuitive for humans
   - Both audit access denials; enforcing mode blocks violations
   - Performance: ~3-5% overhead when well-tuned; poorly designed policies cause throughput loss

8. **auditd & Logging**
   - Kernel audit subsystem logs security events (file access, syscalls, policy violations)
   - Cannot be disabled by non-root; audit logs immutable when configured correctly
   - auditctl rules define what to log: `audit_rules += -w /etc/sudoers -p wa -k sudoers_changes`
   - Syslog aggregation centralizes logs for forensics and compliance

9. **File Integrity Monitoring (FIM)**
   - AIDE, Tripwire, osquery compute cryptographic hashes of files
   - Detect unauthorized changes (rootkit modifications, config drift)
   - Baseline must be immutable (ideally on separate volume or cloud storage)
   - Run FIM scan regularly (nightly) and alert on deviations

10. **Common Security Tools**
    - **fail2ban**: Monitors log files, blocks IPs after N failed auth attempts
    - **rkhunter**: Scans for rootkits, suspicious binaries, kernel modules
    - **lynis**: Security audit tool; shows hardening recommendations
    - **osquery**: Treats system as queryable database; monitor processes, files, network

#### Architecture Role

Security hardening sits at the OS boundary:

```
External Threats
└─ Firewall (iptables/nftables) - Network boundary
     └─ SSH Authentication (pubkey) - Service boundary
          └─ User/Group Authorization (DAC) - Process boundary
               └─ File Permissions - File boundary
                    └─ SELinux/AppArmor (MAC) - Kernel enforcement
                         └─ audit/syslog - Forensics trail
```

#### Production Usage Patterns

**Pattern 1: CIS Benchmark Compliance**
- Deploy via Packer/Terraform with hardened base image
- Automate with scripts that set ownership, permissions, sudo rules
- Validate compliance with automated scanning (osquery, lynis)
- Example: Financial services require CIS Level 2 compliance; automate validation in CI/CD

**Pattern 2: Immutable + Compliance**
- Golden image = hardened OS + security tools + monitoring agent
- Deploy with Kubernetes DaemonSet or cloud-init
- Patching = deploy new image, not post-deployment updates
- Audit trail: each image tagged with build date, applied patches

**Pattern 3: SSH at Scale**
- Central bastion host with restricted access (IP allowlist, MFA)
- All internal systems SSH only from bastion (network policy enforces this)
- SSH keys rotated quarterly or use certificate-based auth
- All SSH logins logged to centralized syslog/SIEM

**Pattern 4: Least Privilege for Services**
- Container runs as non-root user (e.g., `appuser:appuser`)
- Only required capabilities: `cap_net_bind_service` for binding port 80
- SELinux confines process: can only access specific files, ports
- Reduces blast radius if container compromised

#### DevOps Best Practices

1. **Automate Everything**
   ```bash
   # Use Ansible to harden systems in bulk
   - name: Security hardening playbook
     hosts: all
     tasks:
       - name: Disable SSH password auth
         lineinfile:
           path: /etc/ssh/sshd_config
           regexp: '^#?PasswordAuthentication'
           line: 'PasswordAuthentication no'
           state: present
       
       - name: Configure sudo audit
         lineinfile:
           path: /etc/audit/rules.d/sudo.rules
           line: '-w /etc/sudoers -p wa -k sudoers_changes'
           state: present
   ```

2. **Centralize Audit Logging**
   - Syslog aggregation (rsyslog with TLS) to central server
   - SIEM ingestion: alert on failed sudo attempts, policy violations
   - Long-term retention: 1-2 years for compliance

3. **File Integrity Baseline**
   - Compute AIDE database on base image before deployment
   - Mount database read-only from cloud storage (S3, blob storage)
   - Scan nightly; alert if changes detected (might indicate compromise)

4. **Immutable Infrastructure**
   - Don't patch running systems; deploy new image with patches baked in
   - Reduces configuration drift; simplifies rollback
   - Audit trail clearer (image version = what's running)

#### Common Pitfalls

1. **SSH Key Sprawl**
   - Pitfall: Each developer has own SSH key, stored in git or Vault inefficiently
   - Result: Lost keys take weeks to rotate across 10K servers
   - Fix: Certificate-based auth with short TTL (24 hours); automatic renewal

2. **Over-Restrictive SELinux**
   - Pitfall: SELinux policy denies legitimate operations; admins disable it (permissive mode)
   - Result: Complete loss of MAC protection; might as well not have SELinux
   - Fix: Use audit mode to discover violations; gradually enforce after policy tuning

3. **Logging but Not Monitoring**
   - Pitfall: auditd writes 1000s of events/second but nobody reads logs
   - Result: Breach happens; audit logs show it happened 2 weeks later
   - Fix: Parse logs into SIEM; alert on patterns (failed auth spike, sudo execution, file changes)

4. **Hardening in Snowflake Configs**
   - Pitfall: Security config scattered across ansible playbooks, manual steps, runbooks
   - Result: New servers fail security scan; hardening drifts over time
   - Fix: Immutable golden image with all hardening baked in

---

### Practical Code Examples

#### Example 1: SSH Hardening Configuration

```bash
# /etc/ssh/sshd_config - Production-grade hardening
# Disable dangerous features
Protocol 2                                  # SSHv1 is cryptographically broken
PermitRootLogin no                         # Prevent direct root login
PasswordAuthentication no                  # Disable password auth; keys only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys   # Where to look for public keys

# Reduce attack surface
Port 22                                    # Consider non-standard port (implicit port knocking)
X11Forwarding no                           # Disable X11; unnecessary and risky
PermitEmptyPasswords no
AllowUsers devops@* automation@*           # Whitelist users; deny others
ClientAliveInterval 300                    # Detect dead connections
ClientAliveCountMax 3                      # Close after 3 missed intervals = 15 minutes

# Key exchange hardening - prefer modern algorithms
KexAlgorithms curve25519-sha256,diffie-hellman-group-exchange-sha256
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512,hmac-sha2-256
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512

# Rate limiting - fail2ban will add rules too
ListenAddress 0.0.0.0
ListenAddress ::

# PAM integration
UsePAM yes
ChallengeResponseAuthentication no

# Performance
Compression delayed                        # Compress after auth for efficiency

# Logging
SyslogFacility AUTH
LogLevel VERBOSE                           # Log connection details

# Restart SSH to apply changes (gracefully)
systemctl reload sshd
```

#### Example 2: sudo Audit & Hardening

```bash
# /etc/sudoers.d/audit_devops - Role-based sudo with audit
# Format: user/group HOST=(RUNAS) [NOPASSWD:] COMMANDS

# DevOps team: can restart services, view logs, NO root shell
%devops ALL=(root) /bin/systemctl restart *
%devops ALL=(root) /bin/journalctl *
%devops ALL=(root) /bin/tail -f /var/log/*
# Explicitly deny root shell
%devops ALL=(root) !/bin/bash
%devops ALL=(root) !/bin/sh

# Automation user: specific commands for CI/CD
automation ALL=(root) NOPASSWD: /bin/systemctl restart nginx
automation ALL=(root) NOPASSWD: /usr/bin/docker compose -f /opt/app/docker-compose.yml up -d

# Audit configuration: log all sudo usage
# /etc/audit/rules.d/sudo.rules
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d -p wa -k sudoers_changes
-a always,exit -F arch=b64 -S execve -F uid=0 -k root_command_execution

# View audit logs
ausearch -k sudoers_changes
ausearch -k root_command_execution | tail -20
```

#### Example 3: File Permissions & ACL Strategy

```bash
# Standard permission model (DAC)
# Owner: rwx (7), Group: rx (5), Others: --- (0) = 750

# Application directories
chmod 750 /opt/app                  # Owner can modify, group can read/exec, others blocked
chmod 640 /opt/app/config.yaml      # Sensitive config; only owner can read
chown app:app /opt/app              # app user owns; app group can read

# Log directories - shared between app and syslog
setfacl -m g:syslog:rx /var/log/app         # syslog group can read app logs
setfacl -m d:g:syslog:rx /var/log/app       # New files inherit syslog access

# Verify ACLs
getfacl /var/log/app

# Output:
# file: var/log/app
# owner: app
# group: app
# user::rwx
# group::r-x
# group:syslog:r-x
# mask::r-x
# other::---
```

#### Example 4: SELinux Context Configuration

```bash
# Check SELinux status
getenforce                        # Should return 'Enforcing' in production

# View process context
ps -eZ | grep nginx               # Output: unconfined_u:unconfined_r:nginx_t:s0-s0:c0.c1023

# Allow nginx to serve files from custom directory
# Create custom policy
semanage fcontext -a -t httpd_sys_rw_content_t "/var/app/uploads(/.*)?"
restorecon -Rv /var/app/uploads

# Verify context applied
ls -Z /var/app/uploads            # Shows context applied

# View current policy rules
semanage boolean -l | grep httpd  # List httpd booleans
getsebool -a | grep httpd         # Get current boolean values

# Tune policy (example: allow httpd to send emails)
setsebool httpd_can_sendmail on
getsebool httpd_can_sendmail      # Verify: httpd_can_sendmail --> on

# Audit mode: log violations without blocking
semanage permissive -a nginx_t    # Add nginx_t to permissive domains
ausearch -m avc -ts recent        # View recent AVC denials

# Once policy tuned, switch to enforcing
semanage permissive -d nginx_t    # Remove from permissive; back to enforcing
```

#### Example 5: Firewall (iptables) Configuration

```bash
# Modern approach: Use nftables backend, but manage with iptables for compatibility
# Reset iptables (careful in production—do this during maintenance window)
iptables -F                       # Flush all rules
iptables -X                       # Delete all custom chains

# Define default policies
iptables -P INPUT DROP            # Default: drop inbound
iptables -P FORWARD DROP          # Default: drop forwarded
iptables -P OUTPUT ACCEPT         # Default: allow outbound

# Allow essential traffic
iptables -A INPUT -i lo -j ACCEPT                           # Loopback
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT  # Return traffic
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT # Allow ping
iptables -A INPUT -p tcp --dport 22 -j ACCEPT               # SSH

# Allow web service (with DDoS mitigation)
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# Log dropped packets (for troubleshooting; produces noise)
iptables -A INPUT -m limit --limit 2/min -j LOG --log-prefix "IPT_DROP: " --log-level 7
iptables -A INPUT -j DROP

# Make rules persistent (depends on OS)
# Ubuntu/Debian: install iptables-persistent
apt install iptables-persistent
iptables-save > /etc/iptables/rules.v4

# RHEL/CentOS: use firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Modern approach with nftables (recommended for new deployments)
# /etc/nftables.conf
table inet filter {
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept                           # Loopback
    ct state { established, related } accept # Already open connections
    ip protocol icmp accept                 # ICMP (ping)
    tcp dport { 22, 80, 443 } accept        # SSH, HTTP, HTTPS
  }
  chain forward {
    type filter hook forward priority 0; policy drop;
  }
  chain output {
    type filter hook output priority 0; policy accept;
  }
}

# Apply and persist
systemctl enable nftables
nft -f /etc/nftables.conf
```

#### Example 6: fail2ban Configuration

```bash
# /etc/fail2ban/jail.d/sshd.local - SSH brute-force protection
[sshd]
enabled = true
port = ssh                        # Port to monitor (can be custom)
logpath = /var/log/auth.log       # Log file to scan
maxretry = 5                      # Block after 5 failed attempts
findtime = 600                    # Within 10 minutes
bantime = 3600                    # Ban for 1 hour (use 604800 = 1 week for permanent-ish)
action = iptables-multiport[name=sshd, port="ssh", protocol=tcp]
         sendmail-whois[name=sshd, dest=ops@company.com]

# /etc/fail2ban/jail.d/nginx.local - Web application brute-force
[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
findtime = 600
bantime = 3600

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 5
findtime = 60
bantime = 600

# Monitoring fail2ban
fail2ban-client status                # Show all jails
fail2ban-client status sshd           # Show status of sshd jail
fail2ban-client status sshd | grep "Currently banned"  # Show banned IPs

# Manual unban (if needed)
fail2ban-client set sshd unbanip 192.168.1.100

# Test fail2ban (simulate failed login)
ssh -u baduser localhost             # Trigger failed attempt 5 times
fail2ban-client status sshd          # Verify IP is banned
```

#### Example 7: Cloud Deployment - Hardened Base Image (Packer)

```hcl
# packer/hardened-linux.pkr.hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "hardened-ubuntu" {
  ami_name        = "hardened-ubuntu-22.04-{{timestamp}}"
  instance_type   = "t3.micro"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"
  region       = "us-east-1"
}

build {
  sources = ["source.amazon-ebs.hardened-ubuntu"]

  provisioner "shell" {
    inline = [
      "sudo apt update && sudo apt upgrade -y",
      "sudo apt install -y aide rkhunter osquery auditd fail2ban"
    ]
  }

  provisioner "file" {
    source      = "files/sshd_config"
    destination = "/tmp/sshd_config"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/sshd_config /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }

  provisioner "file" {
    source      = "files/sudoers.d/"
    destination = "/tmp/sudoers.d"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/sudoers.d/* /etc/sudoers.d/",
      "sudo chmod 440 /etc/sudoers.d/*"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo systemctl enable auditd fail2ban",
      "sudo aideinit"
    ]
  }
}
```

---

### ASCII Diagrams

#### Diagram 1: Security Hardening Layers

```
┌─────────────────────────────────────────────────────┐
│              External Attack Vectors                 │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Layer 1: Firewall (iptables/nftables)              │
│  - Packet filtering: DROP by default                 │
│  - Allow only: SSH (22), HTTP (80), HTTPS (443)      │
│  - DDoS mitigation: rate limiting                    │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Layer 2: SSH Authentication & Hardening            │
│  - Public key cryptography (no passwords)            │
│  - fail2ban: block after N failed attempts           │
│  - AllowUsers: whitelist specific users              │
│  - Session encryption: AES-256, ChaCha20             │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Layer 3: User/Group & Permissions (DAC)            │
│  - Process runs as specific UID (not root)           │
│  - File permissions: 750, 640 etc.                   │
│  - ACLs for granular access                          │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Layer 4: SELinux/AppArmor (MAC)                    │
│  - SELinux contexts: user:role:type:level            │
│  - AppArmor profiles: path-based rules               │
│  - Deny by default; allow only necessary access      │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Layer 5: Sudo & Privilege Escalation Audit         │
│  - Sudoers: limit who can run what                   │
│  - auditd: log all sudo commands                     │
│  - SIEM: alert on suspicious sudo usage              │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  Layer 6: File Integrity & Intrusion Detection      │
│  - AIDE: detects rootkit file modifications          │
│  - rkhunter: scans for known rootkits                │
│  - osquery: continuous system monitoring             │
└─────────────────────────────────────────────────────┘
                         ↓
         ✓ Legitimate Access | ✗ Threat Blocked
```

#### Diagram 2: SSH Authentication Flow

```
Client                                          Server
├─ Generate SSH key pair (ed25519)             ├─ Listens on port 22
├─ Copy public key to ~/.ssh/authorized_keys   │
│
├─ SSH connection request ────────────────────>│ Receive connection
│                                               ├─ Load host key
│                                               ├─ Propose algorithms
│
│ Receive proposals <──────────────────────────┤
├─ Agree on key exchange algorithm            │
│
├─ Perform ECDH key exchange ─────────────────>│
│                          <──────────────────┤
│ (Both sides derive shared encryption key)    │
│
├─ Send username ──────────────────────────────>│
│                                               ├─ Check if user exists
│
│ Receive "publickey" challenge <─────────────┤
│
├─ Sign challenge with private key ───────────>│
│                                               ├─ Verify signature
│                                               │   (using public key)
│                                               ├─ Check permissions
│
│ ✓ SSH_MSG_USERAUTH_SUCCESS <────────────────┤
│
├─ Shell session established (encrypted) ─────>│
│ All communication encrypted with derived key │
```

---

## System Resource Controls

### Textual Deep Dive

#### Internal Working Mechanism

Linux resource controls operate at multiple kernel layers:

**1. cgroups (Control Groups) - Kernel Resource Accounting & Limiting**

- **cgroups v1 (legacy)**: Separate hierarchies per resource type (memory, cpu, cpuacct, blkio, devices, freezer, net_cls, perf_event)
  - Controller location: `/sys/fs/cgroup/<controller>/`
  - Example: `/sys/fs/cgroup/memory/docker/container_id/memory.limit_in_bytes`
  - Complexity: Multiple hierarchies = confusing; difficult coordination across controllers

- **cgroups v2 (unified)**: Single hierarchy; all controllers under one `/sys/fs/cgroup/`
  - Cleaner API; better semantics (e.g., `memory.max` instead of `memory.limit_in_bytes`)
  - Systemd adopts v2; Kubernetes v1.25+ supports v2 delegation to containers
  - Hybrid mode: v1 + v2 coexist; requires migration strategy

**2. Key cgroups v2 Controllers**

| Controller | Limits | Soft Limits | Read-Only Metrics |
|-----------|--------|-------------|-------------------|
| memory | `memory.max` | `memory.high` (throttling) | `memory.current`, `memory.stat`, `memory.oom_control` |
| cpu | `cpu.max` (period.quota) | `cpu.weight` (shares) | `cpu.stat` (usage_usec, nr_periods) |
| io | `io.weight.` (I/O shares) | N/A | `io.stat` (rbytes, wbytes, rios, wios) |
| pids | `pids.max` | N/A | `pids.current` (count) |
| devices | N/A (v1 only) | N/A | N/A |

**3. namespaces - Process Isolation (not resource limits)**

- **PID namespace**: Process tree isolation; `PID 1` inside container is PID N outside
  - Prevents `kill -9 1` from inside container affecting host PID 1
  - Enables container to have independent process init (systemd, dumb-init, etc.)

- **network namespace**: Network stack isolation; own lo interface, eth0 veth pair, IP tables rules
  - Docker containers get veth interface connected to docker0 bridge
  - Kubernetes pods share network namespace (all containers in pod share eth0)

- **mount namespace**: Filesystem isolation; processes can have different mount trees
  - Enables `/` to be completely different inside container
  - Filesystem changes don't affect host

- **user namespace**: UID mapping; UID 0 inside container can map to UID 1000 outside
  - Rootless containers: UID 0 inside = unprivileged user outside
  - Reduces blast radius if container escape occurs

- **ipc namespace**: Message queues, semaphores, shared memory isolation
  - Pods in Kubernetes can share IPC namespace for local IPC

- **uts namespace**: Hostname and NIS domain isolation
  - Containers see different hostname without affecting host

**4. Kernel Scheduling & Memory Management**

- **CPU scheduler**: Kernel distributes CPU time among processes
  - Completely Fair Scheduler (CFS) allocates time proportionally based on `cpu.weight`
  - Nice/priority levels affect weight calculation
  - cgroup cpu limits are hard caps; scheduler enforces via throttling (unpredictable latency)

- **Memory management**: Kernel allocates pages from free pool
  - Page cache: filesystem cache (fast, can be reclaimed)
  - Anonymous pages: heap, stack (slower reclaim; swapped to disk)
  - swappiness = tendency to swap anonymous pages (lower = less swap)
  - OOM killer: kills process when memory exhausted (non-deterministic)

**5. Per-Process ulimit (User Limits)**

- Set via `ulimit` command or PAM configuration
- Applies to login session, not persistent across reboots
- Example: `ulimit -n 65536` sets max open file descriptors
- Hard limit = cannot exceed (enforced by kernel); soft limit = can be increased up to hard limit

#### Architecture Role

Resource controls prevent cascading failures in shared infrastructure:

```
Host System Resources (Physical Limits)
  ├─ CPU cores, hyperthreads
  ├─ RAM (GB)
  ├─ Network bandwidth
  └─ Disk I/O capacity (IOPS)

         ↓ Kernel enforcement layer

cgroups v2 (Hard Limits per Container/Pod)
  ├─ CPU: cpu.max = 2000000:1000000 (2 cores / 1ms period)
  ├─ Memory: memory.max = 1G (hard cap)
  ├─ I/O: io.weight = 100 (CPU CPU share for I/O weight)
  └─ Pids: pids.max = 256 (max processes)

         ↓ Per-process enforcement

ulimit (Soft Limits per Session)
  ├─ File descriptors: ulimit -n 1024
  ├─ Processes: ulimit -u 256
  ├─ Memory: ulimit -v (virtual memory)
  └─ Resource exhaustion triggers OOM killer or syscall error

         ↓ Application-level handling

Application Graceful Degradation
  ├─ Connection pool exhaustion: return 503 Service Unavailable
  ├─ Memory pressure: cache eviction, circuit breaker
  └─ CPU throttling: backoff, shed load
```

#### Production Usage Patterns

**Pattern 1: Kubernetes Pod Resource Requests/Limits**
```yaml
resources:
  requests:
    memory: "256Mi"      # Scheduler: minimum guaranteed
    cpu: "250m"          # Minimum guaranteed CPU
  limits:
    memory: "512Mi"      # Hard cap (OOM killer if exceeded)
    cpu: "500m"          # Hard cap (throttling)
```
- `requests` = what pod needs; scheduler uses this for bin-packing
- `limits` = maximum; kernel enforces; exceeding triggers OOM or throttling
- QoS class: `Guaranteed` (request=limit), `Burstable` (request<limit), `BestEffort` (no limits)

**Pattern 2: cgroups v2 Delegation (systemd + Kubernetes)**
- systemd creates slice/scope hierarchy: `system.slice`, `user.slice`, `docker.service`
- Kubernetes delegates cgroups to kubelet: `kubelet.service` manages pod cgroups
- Avoids conflicts; clear ownership chain

**Pattern 3: Memory Overcommit Detection**
- Monitor `memory.pressure_level` or PSI (Pressure Stall Information)
- Alert on sustained memory.pressure > 50%
- Scale out (add nodes) or shift workloads before OOM

**Pattern 4: CPU Throttling Monitoring**
- Monitor `cpu.stat:nr_throttled` (count of throttling events)
- If high: CPU limit too low; increase limit or optimize code
- Avoid hard CPU limits for latency-sensitive workloads; use CPU shares instead

#### DevOps Best Practices

1. **Always Set Resource Limits in Containers**
   ```bash
   # Bad: no resource limits
   docker run -d myapp
   
   # Good: explicit limits
   docker run -d \
     --memory=512m \
     --memory-swap=512m \
     --cpus=0.5 \
     --cpus-shares=1024 \
     myapp
   ```

2. **Monitor Resource Pressure**
   ```bash
   # View cgroup limits and current usage
   systemd-cgtop                    # Similar to top, but for cgroups
   
   # Low-level cgroup inspection
   cat /sys/fs/cgroup/memory.current    # Current usage
   cat /sys/fs/cgroup/memory.max        # Limit
   cat /sys/fs/cgroup/memory.stat       # Detailed breakdown
   ```

3. **Test Limits in Staging**
   ```bash
   # Stress test memory limit
   docker run --rm --memory=256m ubuntu:22.04 \
     stress-ng --vm 1 --vm-bytes 512M --vm-method all --timeout 10s
   
   # Should see OOM killer trigger; process killed
   ```

4. **Use CPU Shares, Not Hard Limits**
   ```bash
   # Better: proportional CPU shares
   docker run --cpus-shares=2048 webserver    # Default 1024; this gets 2× CPU
   
   # Avoid: hard CPU limits (cause latency spikes)
   docker run --cpus=2 webserver              # Hard cap to 2 cores
   ```

5. **Memory Scaling Strategy**
   ```yaml
   # Kubernetes: use VPA (Vertical Pod Autoscaler) to recommend limits
   apiVersion: autoscaling.k8s.io/v1
   kind: VerticalPodAutoscaler
   metadata:
     name: app-vpa
   spec:
     targetRef:
       apiVersion: "apps/v1"
       kind: Deployment
       name: myapp
     updatePolicy:
       updateMode: "auto"  # Auto-update limits
   ```

#### Common Pitfalls

1. **OOM Killer Surprise**
   - Pitfall: Set memory.max = 512MB but don't monitor memory pressure
   - Result: Process killed unexpectedly; no graceful shutdown
   - Fix: Application should respond to memory pressure signals (cgroup.event_control or PSI); graceful shutdown before OOM

2. **CPU Limit Causes Latency Spike**
   - Pitfall: `cpu.max = 1000000:1000000` (1 CPU) hard limit
   - Result: Every second, process throttled for remainder of period (unpredictable latency)
   - Fix: Use CPU shares instead; test with wrk or Apache Bench to validate latency SLA

3. **ulimit Inconsistency**
   - Pitfall: Set ulimit -n 65536 in login shell, but container runs with default 1024
   - Result: Application fails with `Too many open files`
   - Fix: Set in /etc/security/limits.conf persistently; verify with `ulimit -a` inside container

4. **Namespace Misconfiguration**
   - Pitfall: Run container with `--pid=host` or `--network=host` (for "performance")
   - Result: Process isolation broken; container can see/kill host processes
   - Fix: Never use host PID/network; use kubernetes NetworkPolicy instead

5. **Swap Confuses Resource Management**
   - Pitfall: Swap enabled; memory.max applied but process pages to disk
   - Result: Memory unpredictably spills to disk; latency becomes unpredictable
   - Fix: Disable swap; use zswap if necessary; set swappiness=0

---

### Practical Code Examples

#### Example 1: cgroups v2 Manual Configuration

```bash
# Check if system is using cgroups v2
mount | grep cgroup2             # Should see "cgroup2 on /sys/fs/cgroup type cgroup2"

# Create a cgroup for a workload
mkdir -p /sys/fs/cgroup/workload-group

# Set memory limit: 1GB
echo 1073741824 > /sys/fs/cgroup/workload-group/memory.max

# Set CPU limit: 2 cores (2000000 ÷ 1000000 = 2 cores per 1ms period)
echo 2000000:1000000 > /sys/fs/cgroup/workload-group/cpu.max

# Set I/O weight (relative; default 100)
echo 8:0 50 > /sys/fs/cgroup/workload-group/io.weight  # Device 8:0 (sda) weight 50

# Launch process in this cgroup
bash            # Start bash shell
echo $$ > /sys/fs/cgroup/workload-group/cgroup.procs  # Move current shell to cgroup

# Verify
ps -o pid,cgroup $(pgrep bash)   # Shows cgroup assignment

# Monitor in real-time
watch -n 1 "cat /sys/fs/cgroup/workload-group/memory.current \
             /sys/fs/cgroup/workload-group/cpu.stat"
```

#### Example 2: Kubernetes Resource Requests & Limits

```yaml
# deployment.yaml - Resource management example
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
      - name: app
        image: myregistry.azurecr.io/nodejs-app:latest
        
        # Resource requests: what pod *needs* to be scheduled
        resources:
          requests:
            memory: "256Mi"           # Allocate 256MB guaranteed
            cpu: "100m"               # Allocate 0.1 CPU Core guaranteed
            ephemeral-storage: "1Gi"  # Temporary storage for logs
        
        # Resource limits: hard caps; exceed = OOM/throttling
        limits:
          memory: "512Mi"             # Max 512MB; OOM if exceeded
          cpu: "500m"                 # Max 0.5 CPU; throttled if exceeded
          ephemeral-storage: "2Gi"    # Max 2GB temp storage
        
        # Health checks; triggered if resource limit hit unexpectedly
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
            failureThreshold: 3      # Restart if 3 consecutive failures
        
        # Readiness: remove from load balancing if unhealthy
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5

      # Pod QoS: mixed requests/limits = Burstable (can be evicted during node pressure)
      priorityClassName: high-priority  # Prevent eviction of critical pods

---
# Pod Disruption Budget: protect from evictions during scale-down
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nodejs-app-pdb
spec:
  minAvailable: 2           # Always keep at least 2 replicas available
  selector:
    matchLabels:
      app: nodejs-app
```

#### Example 3: Monitoring Memory & CPU with systemd-cgtop

```bash
# Real-time cgroup resource monitoring
systemd-cgtop                               # Top-like view, sort by memory

# Options
systemd-cgtop -b                            # Batch mode (one output)
systemd-cgtop --sort=memory                 # Sort by memory
systemd-cgtop --sort=tasks                  # Sort by process count
systemd-cgtop --recursive=yes               # Show child cgroups

# Output example:
# Control Group                      Tasks   %CPU   Memory
# /system.slice                      1122  12.3% 4.2G
# /system.slice/nginx.service         45   8.5%   256M
# /user.slice                        289   3.2%   1.3G
# /user.slice/user-1000.slice/...     42   2.1%   512M
```

#### Example 4: Docker Resource Limits in Compose

```yaml
# docker-compose.yml - Resource constraints
version: '3.8'

services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '0.5'              # Max 0.5 CPU
          memory: 512M             # Max 512MB
        
        reservations:              # Request: guaranteed minimum
          cpus: '0.25'
          memory: 256M
    
    environment:
      NGINX_WORKER_PROCESSES: "2"  # Tune app for cpu limit

  database:
    image: postgres:15
    
    deploy:
      resources:
        limits:
          cpus: '1'                # Database often needs more CPU
          memory: 2G               # Databases memory-hungry
        
        reservations:
          cpus: '0.75'
          memory: 1.5G
    
    environment:
      POSTGRES_SHARED_BUFFERS: "512MB"  # Tune for memory limit
      POSTGRES_EFFECTIVE_CACHE_SIZE: "1536MB"
    
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

#### Example 5: ulimit Configuration (Persistent)

```bash
# /etc/security/limits.conf - Persistent ulimit settings
# Format: domain type item value

# All users in group jenkins
@jenkins hard nofile 65536          # Max open file descriptors
@jenkins soft nofile 65536
@jenkins hard nproc 4096            # Max processes
@jenkins soft nproc 4096
@jenkins hard memlock unlimited     # Allows mlock() for memory-pinning

# Specific user (devops)
devops hard nofile 1048576         # 1 million file descriptors
devops soft nofile 1048576
devops hard core unlimited          # Unlimited core dumps (for debugging)

# Default for all users
* soft nofile 1024                  # Softer defaults for everyone else
* hard nofile 65536

# Application-specific (Elasticsearch)
elasticsearch hard memlock unlimited    # Elasticsearch needs this
elasticsearch soft memlock unlimited

# Reload settings (PAM loads on next login)
# For running process: escalate to root and change via /proc
# sudo bash
# echo "nofile 65536" > /proc/$$/limits
```

#### Example 6: Troubleshooting Resource Contention

```bash
# Scenario: Pod frequently killed with OOMKilled; unclear why
# Step 1: Check current memory usage vs limit
kubectl top pod myapp-xyz -n production
# NAME              CPU(cores)   MEMORY(bytes)
# myapp-xyz         250m         420Mi             # Using 420MB of 512MB limit

# Step 2: Check for memory spikes in history
kubectl describe pod myapp-xyz -n production
# Check "Last State: Terminated. Reason: OOMKilled"

# Step 3: Monitor memory trend over time
kubectl logs myapp-xyz -n production --tail=100 | grep "Memory"

# Step 4: Check cgroup memory.stat on node
# SSH to node
kubectl debug node/node-1 -it --image=ubuntu:22.04
# Inside node debug container:
cat /sys/fs/cgroup/pod123/memory.stat | grep page_fault
# high number of page faults = memory pressure

# Step 5: Increase memory limit or optimize application
kubectl set resources deployment myapp \
  --limits=memory=1Gi \
  --requests=memory=768Mi

# Step 6: Validate with load test
ab -n 10000 -c 100 http://myapp.example.com  # Apache Bench
# Monitor memory usage during load
kubectl top pod myapp-xyz --watch
```

---

### ASCII Diagrams

#### Diagram 1: cgroups v2 Hierarchy

```
/sys/fs/cgroup (unified cgroups v2)
│
├─ system.slice/ (system services)
│  ├─ docker.service/            # Docker runtime cgroup
│  │  └─ container-abc123/        # Individual container
│  │     ├─ memory.max = 512M
│  │     ├─ cpu.max = 1000000:1000000 (1 core)
│  │     ├─ io.weight = 100
│  │     └─ cgroup.procs = [1234, 1235, ...]
│  │
│  └─ kubelet.service/           # Kubernetes kubelet
│     ├─ pod-namespace/
│     │  ├─ memory.max = 2G
│     │  ├─ cpu.max = 2000000:1000000 (2 cores)
│     │  └─ cgroup.procs = [5678, 5679, ...]
│     │
│     └─ pod-namespace-2/
│        ├─ memory.max = 1G
│        └─ cgroup.procs = [9012, ...]
│
├─ user.slice/ (user sessions)
│  ├─ user-1000.slice/ (UID 1000)
│  │  ├─ session-5.scope/
│  │  │  └─ bash shell, ssh session
│  │  └─ user@.service/
│  │     └─ user service
│  │
│  └─ user-1001.slice/ (UID 1001)
│     └─ session-6.scope/
│
└─ init.scope/                   # Init process (PID 1)
```

#### Diagram 2: Memory Pressure & OOM Path

```
┌─────────────────────────────────────────────────────┐
│  Application running, memory usage growing          │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│  memory.current < memory.max                        │
│  (Within limits; no action taken)                   │
└─────────────────────────────────────────────────────┘
                         ↓
[Application allocates more memory]
                         ↓
┌─────────────────────────────────────────────────────┐
│  memory.current >= memory.max                       │
│  (At limit; kernel triggered)                       │
└─────────────────────────────────────────────────────┘
                         ↓
              Alternative paths:
               /              \
              /                \
             ↓                  ↓
    ┌─────────────┐    ┌──────────────────┐
    │  Page Cache │    │  Anonymous Pages │
    │  Reclamation│    │  No reclaim src? │
    │  (Fast)     │    │                  │
    └─────────────┘    └──────────────────┘
         ↓                     ↓
    ✓ Success            ┌──────────────────┐
                         │  Try Swap (slow) │
                         │  (if enabled)    │
                         └──────────────────┘
                              ↓
                         Alternative paths:
                          /          \
                         /            \
                        ↓              ↓
                   ┌──────────┐  ┌──────────────┐
                   │  Swapped │  │  Still OOM?  │
                   │ (Slow)   │  │              │
                   └──────────┘  └──────────────┘
                       ↓               ↓
                    ✓ Degraded    ┌──────────────────┐
                    Performance   │  OOM Killer Sel.  │
                                  │  Picks process    │
                                  │  with highest oom │
                                  │  score; kills it  │
                                  └──────────────────┘
                                       ↓
                                  Process killed
                                  (exit code 137)
```

---

## Kernel & System Tuning

### Textual Deep Dive

#### Internal Working Mechanism

Kernel tuning optimizes the kernel's behavior for specific workloads by adjusting parameters without code changes.

**1. sysctl Interface**

- **Access point**: `/proc/sys/` (files represent kernel parameters)
  - Example: `net.ipv4.tcp_tw_reuse` ↔ `/proc/sys/net/ipv4/tcp_tw_reuse`
- **Configuration**: `/etc/sysctl.conf` read at boot; `/etc/sysctl.d/` for modular config
- **Runtime change**: `sysctl -w kernel.param=value` (lost on reboot unless persisted)
- **View all**: `sysctl -a` lists all parameters
- **Reload**: `sysctl -p` or `sysctl -p /etc/sysctl.d/99-tuning.conf`

**2. Kernel Module Parameters**

- **modprobe config**: `/etc/modprobe.d/` for persistent module parameters
- **Runtime tuning**: `echo value > /sys/module/modulename/parameters/param`
- **Example**: Netfilter connection tracking table size
  ```bash
  echo 2097152 > /sys/module/nf_conntrack/parameters/hashsize
  ```

**3. TCP/IP Stack Performance Parameters**

| Parameter | Effect | Tuning Use Case |
|-----------|--------|-----------------|
| `net.core.somaxconn` | Max listen backlog | High-concurrency servers (1024 → 4096+) |
| `net.ipv4.tcp_max_syn_backlog` | Max SYN queue | DDoS protection; slow clients |
| `net.ipv4.tcp_tw_reuse` | Reuse TIME_WAIT | Avoid port exhaustion under load |
| `net.ipv4.tcp_fin_timeout` | TIME_WAIT duration | Faster port recycling (risky; default 60s) |
| `net.core.netdev_max_backlog` | NIC rx queue | High-speed networks; packet drops |
| `net.ipv4.ip_local_port_range` | Ephemeral port range | Widen from default 32768-60999 |
| `net.ipv4.tcp_slow_start_after_idle` | SSAI | Restart CWND after idle (0=off; disable) |

**4. File System Tuning**

| Component | Parameter | Purpose |
|-----------|-----------|---------|
| Readahead | `blockdev --getra` | Kernel's sequential read size |
| I/O Scheduler | `/sys/block/sda/queue/scheduler` | noop vs deadline vs cfq |
| Cache | `sysctl vm.drop_caches` | Clear page/inode cache |
| Filesystem | `mount -o noatime` | Disable atime updates |

**5. Memory Management Tuning**

| Parameter | Effect | Tuning Scenario |
|-----------|--------|-----------------|
| `vm.swappiness` | Kernel tendency to swap (0-100) | Production: 0-10; default 60 causes issues |
| `vm.overcommit_memory` | Allow pid.max exceeded (0=heuristic, 1=allow, 2=strict) | 0 (default); never 1 in prod |
| `vm.panic_on_oom` | Kernel panic on OOM | 0 (default, OOM killer); 1 (panic, halt) |
| `vm.dirty_ratio` | Pct of RAM before writeback | Lower = more frequent writes; default 20 |
| `vm.dirty_background_ratio` | Async writeback threshold | Balanced; default 10 |

**6. CPU Scheduling & Performance**

| Parameter | Effect | Use Case |
|-----------|--------|----------|
| `kernel.sched_migration_cost_ns` | Cache affinity cost | Tune to NUMA topology |
| `kernel.perf_event_paranoid` | perf sampling permissions | 1 (default); 0 allows unprivileged |
| `kernel.sched_autogroup_enabled` | Automatic task grouping | 1 (default); helps fairness |

**7. Huge Pages**

- **Standard pages**: 4KB (small; high TLB lookups for large datasets)
- **Huge Pages**: 2MB or 1GB (fewer TLB misses; memory waste)
- **Enable**: `echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages`
- **Application support**: Database (MySQL, PostgreSQL), HPC workloads

#### Architecture Role

Kernel tuning bridges hardware capabilities and application requirements:

```
┌──────────────────────────────────┐
│  Application Behavior            │
│  (latency target, throughput)     │
└──────────────────────────────────┘
              ↓
┌──────────────────────────────────┐
│  Kernel Parameters               │
│  (sysctl, module params)         │
│  (affect scheduler, TCP stack)   │
└──────────────────────────────────┘
              ↓
┌──────────────────────────────────┐
│  Hardware Limits                 │
│  (CPU cores, L3 cache, RAM)      │
│  (NIC bandwidth, disk IOPS)      │
└──────────────────────────────────┘
```

**Example Trade-off: TCP Buffer Sizes**
- **More buffer**: Handles bursty traffic; wastes memory if unused
- **Less buffer**: Efficient memory; throttles high-bandwidth connections
- **Tuning**: Calculate BDP; set to 2×BDP for 100% link utilization

#### Production Usage Patterns

**Pattern 1: Database Performance Tuning**
```bash
# PostgreSQL/MySQL memory tuning
vm.swappiness=5                      # Avoid swapping (databases need predictable latency)
vm.dirty_ratio=15
vm.dirty_background_ratio=5          # More frequent writes; avoid large flush storms

# Filesystem: disable atime for database data directories
mount -o remount,noatime /var/lib/postgresql

# I/O scheduler for NVME SSDs (deadline best for random I/O)
echo deadline > /sys/block/nvme0n1/queue/scheduler
```

**Pattern 2: High-Concurrency Web Server Tuning**
```bash
# Kernel connection tracking table (needed for iptables stateful rules)
net.core.somaxconn=65535                    # Listen backlog
net.ipv4.tcp_max_syn_backlog=65535         # SYN queue
net.ipv4.tcp_tw_reuse=1                    # Reuse TIME_WAIT sockets
net.ipv4.ip_local_port_range="10000 65535" # Wider ephemeral port range
net.netfilter.nf_conntrack_max=2097152     # Max conntrack entries
net.netfilter.nf_conntrack_tcp_timeout_time_wait=30  # Shorter TIME_WAIT
```

**Pattern 3: DDoS Mitigation via sysctl**
```bash
# Limit SYN attacks
net.ipv4.tcp_syncookies=1                  # SYN cookies defense
net.ipv4.tcp_max_syn_backlog=4096          # Limit SYN queue
net.ipv4.tcp_syn_retries=2                 # Fewer retries = faster timeout

# Rate limit
net.ipv4.tcp_timestamps=1                  # Help detect replayed packets
net.ipv4.conf.all.log_martians=1          # Log invalid packets
```

**Pattern 4: NFT Tuning for Live Migration**
```bash
# Memory pre-allocation for live migration (KVM/Hyper-V)
vm.overcommit_memory=1                     # Allow overcommit (VMs pre-reserve)
kernel.shed_rt_runtime_us=-1               # Unlimited RT scheduling

# Disable swap during migration
swapoff -a                                 # Or vm.swappiness=0
```

#### DevOps Best Practices

1. **Document Every Tuning Decision**
   ```bash
   # /etc/sysctl.d/99-production-tuning.conf
   # Explain why each parameter is set
   
   # TCP tuning for 100K concurrent connections
   # Based on customer deployment with 20K RPS, 5ms RTT
   # BDP = 1 Gbps × 5ms = 5 Mb = 625 KB → set to 2MB
   net.core.rmem_max=2097152
   net.core.wmem_max=2097152
   ```

2. **Baseline Before & After**
   ```bash
   # Before tuning: capture metrics
   sar -A > /tmp/before.txt
   perf stat -d command-under-test > /tmp/perf_before.txt
   
   # Apply sysctl change
   sysctl -w kernel.param=newvalue
   
   # After tuning: compare
   sar -A > /tmp/after.txt
   perf stat -d command-under-test > /tmp/perf_after.txt
   
   # Analysis
   diff /tmp/before.txt /tmp/after.txt
   ```

3. **Test in Staging First**
   - Never tune production without validating in staging
   - Use same workload profile as production
   - Run for duration > 24 hours to catch edge cases

4. **Monitor for Regressions**
   - After deploying sysctl changes, monitor for side effects
   - Memory usage might increase, latency might spike for other workloads
   - Set up alerts for anomalies

5. **Keep Defaults When Uncertain**
   - Kernel defaults are conservative; suitable for most workloads
   - Only tune for specific measured bottleneck

#### Common Pitfalls

1. **Tuning Without Baseline**
   - Pitfall: Increase `net.core.rmem_max` without measuring throughput first
   - Result: Might help, might hurt; unclear if worth the memory cost
   - Fix: Measure latency/throughput before, apply change, measure after

2. **Parameter Interdependencies**
   - Pitfall: Tune `tcp_tw_reuse` without adjusting `tcp_fin_timeout`
   - Result: TIME_WAIT sockets reused too fast; connection resets
   - Fix: Understand how parameters interact; test together

3. **Wrong Workload Tuning**
   - Pitfall: Tune kernel for OLTP database but workload is big data analytics
   - Result: Fast random I/O tuning hurts sequential throughput
   - Fix: Identify workload first; tune for your bottleneck

4. **Swap Enabled in Production**
   - Pitfall: `vm.swappiness=60` (default) causes unpredictable latency
   - Result: Page faults translate memory pressure to disk I/O; latency spikes
   - Fix: `vm.swappiness=0` or disable swap entirely

5. **Transient Configuration**
   - Pitfall: Use `sysctl -w` to tune; setting lost on reboot
   - Result: Spend weeks debugging "why did performance get worse?"
   - Fix: Always persist to `/etc/sysctl.d/`

---

### Practical Code Examples

#### Example 1: High-Performance Kernel Parameters (sysctl.d)

```bash
# /etc/sysctl.d/99-production-tuning.conf
# Senior DevOps production tuning for high-throughput Linux

# ============ TCP/IP Stack Tuning ============
# Increase max number of listening connections
net.core.somaxconn=65536                        # Up from default 4096

# Max SYN queue (protects from SYN flood; balance with memory)
net.ipv4.tcp_max_syn_backlog=65536

# Enable TCP Fast Open (TFO) - faster handshake
net.ipv4.tcp_fastopen=3                         # 1=clients, 2=servers, 3=both

# TIME_WAIT socket reuse (avoid port exhaustion when many short connections)
net.ipv4.tcp_tw_reuse=1

# Reduce TIME_WAIT timeout (speeds recovery)
net.ipv4.tcp_fin_timeout=30                     # Down from 60s

# Local ephemeral port range (allows more concurrent outbound connections)
net.ipv4.ip_local_port_range=10000 65535

# ============ Memory Management ============
# Avoid swapping (swap kills latency in production)
vm.swappiness=5                                 # Near 0; allow swap only in emergency

# Dirty page tuning (balance between memory efficiency and I/O)
vm.dirty_ratio=15                               # Default 20; flush after 15% dirty
vm.dirty_background_ratio=5                     # Start async writeback at 5%
vm.dirty_expire_centisecs=3000                  # Remove dirty pages > 30s old

# ============ File Descriptor Limits ============
# Increase max file descriptors system-wide
fs.file-max=2097152                            # Default 65536

# ============ Kernel Behavior ============
# Core dumps: useful for debugging crashes (but big files)
kernel.core_pattern=/var/log/core/%t/%e.%P     # Store cores with timestamp
fs.suid_dumpable=2                             # Allow privileged dumps (debug)

# Kptr_restrict: hide kernel pointer addresses (security)
kernel.kptr_restrict=1                         # Anonymize ptr addresses

# ============ Connection Tracking (iptables/nftables) ============
# Increase connection table size (needed if using stateful firewall)
net.netfilter.nf_conntrack_max=2097152

# Tune conntrack timeout for high-concurrency workloads
net.netfilter.nf_conntrack_tcp_timeout_time_wait=60

# ============ Apply configuration ============
# sysctl -p /etc/sysctl.d/99-production-tuning.conf
```

#### Example 2: Database Server Tuning (PostgreSQL/MySQL)

```bash
# /etc/sysctl.d/99-database-tuning.conf
# Optimized for OLTP database workloads

# ============ Memory Tuning for Databases ============
vm.swappiness=1                                # Minimal swap; keep buffer pool in RAM
vm.dirty_ratio=10
vm.dirty_background_ratio=3
vm.dirty_expire_centisecs=2000                 # Faster writeback for consistency

# Shared memory (for IPC, SysV semaphores used by databases)
kernel.shmmax=17179869184                      # 16GB (adjust for your RAM)
kernel.shmall=4194304                          # 16GB in pages (4KB each)

# ============ Semaphores & File Descriptors ============
kernel.sem=250 32000 100 128                   # Update for database concurrency
fs.file-max=2097152

# ============ I/O Optimization ============
# Read-ahead for sequential workloads (some databases benefit)
# Note: Check with `blockdev --getra /dev/sda`
vm.block_dump=0                                # Disable block I/O tracing (debug)

# ============ Connection Limits ============
net.ipv4.tcp_max_syn_backlog=4096              # Slightly lower for stable DB
net.core.somaxconn=4096                        # Match app server expectations
net.ipv4.tcp_tw_reuse=0                        # Safer for database replication

# Backlog for database listener
net.core.netdev_max_backlog=1000
```

#### Example 3: Dynamic sysctl Tuning (Systemd Service)

```ini
# /etc/systemd/system/tune-sysctl.service
# One-time sysctl tuning at boot, with conditional logic

[Unit]
Description=Dynamic Kernel Parameter Tuning
DefaultDependencies=no
After=systemd-sysctl.service
Before=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/tune-kernel.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```bash
# /usr/local/bin/tune-kernel.sh
#!/bin/bash
# Conditional kernel tuning based on workload

# Detect CPU count
CPU_COUNT=$(nproc)

# Detect available RAM (in KB)
RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$((RAM_KB / 1024 / 1024))

# Detect if system has SSD or HDD
DISK_TYPE=$(cat /sys/block/sda/queue/rotational)
# 0 = SSD, 1 = HDD

# Workload detection (could read env var set by container/orchestration)
WORKLOAD=${WORKLOAD_TYPE:-"general"}

# Tune based on CPU count
if [ "$CPU_COUNT" -ge 32 ]; then
    # High-CPU systems: tune for high concurrency
    sysctl -w net.core.somaxconn=65536
    sysctl -w net.ipv4.tcp_max_syn_backlog=65536
    sysctl -w kernel.sched_migration_cost_ns=5000000
    echo "✓ Tuned for high-concurrency ($CPU_COUNT CPUs)"
fi

# Tune based on RAM
if [ "$RAM_GB" -gt 64 ]; then
    # Large memory systems: larger buffers
    sysctl -w net.core.rmem_max=134217728  # 128MB
    sysctl -w net.core.wmem_max=134217728
    echo "✓ Tuned for large memory ($RAM_GB GB)"
fi

# Tuning based on storage type
if [ "$DISK_TYPE" -eq 0 ]; then
    # SSD: use deadline scheduler; no readahead needed
    echo deadline > /sys/block/sda/queue/scheduler
    blockdev --setra 0 /dev/sda
    echo "✓ Tuned for SSD storage"
else
    # HDD: use cfq scheduler; benefit from readahead
    echo cfq > /sys/block/sda/queue/scheduler
    blockdev --setra 256 /dev/sda
    echo "✓ Tuned for HDD storage"
fi

# Workload-specific tuning
case "$WORKLOAD" in
    "database")
        sysctl -w vm.swappiness=1
        sysctl -w vm.dirty_ratio=10
        sysctl -w kernel.shmmax=$((RAM_KB * 1024 * 3/4)) # 75% of RAM
        echo "✓ Database workload tuning applied"
        ;;
    "web-cache")
        sysctl -w vm.swappiness=10
        sysctl -w net.core.somaxconn=65536
        echo "✓ Web/Cache workload tuning applied"
        ;;
    *)
        echo "✓ No specific workload tuning"
        ;;
esac

# Verify sysctl applied
echo "Current kernel parameters:"
sysctl net.core.somaxconn vm.swappiness kernel.sched_migration_cost_ns
```

#### Example 4: Huge Pages Configuration

```bash
# Check huge page support
cat /proc/cpuinfo | grep pse                 # PSE = Page Size Extension (2MB)
cat /proc/cpuinfo | grep pdpe1gb             # 1GB huge pages support

# Calculate needed huge pages
# Example: PostgreSQL needs 16GB shared_buffers
# 16GB / 2MB = 8192 pages

echo 8192 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# Persistent configuration
# /etc/sysctl.d/99-hugepages.conf
vm.nr_hugepages=8192

# Verify allocation
cat /proc/meminfo | grep Hugepages
# HugePages_Total:    8192
# HugePages_Free:     8000
# Hugepagesize:       2048 kB

# Application configuration (PostgreSQL example)
# postgresql.conf
huge_pages = on                # Enable huge pages
shared_buffers = '16GB'        # Will use huge pages

# Restart PostgreSQL
systemctl restart postgresql
```

#### Example 5: Network I/O Tuning (High-Speed Networks)

```bash
# /etc/sysctl.d/99-network-io.conf
# Optimized for 10G+ networks (e.g., data center)

# ============ RX Ring Buffer (NIC → Kernel) ============
# Check current value
ethtool -g eth0                               # Shows rx-pending value

# Increase RX ring buffer
ethtool -G eth0 rx 4096                       # Avoid packet drops
# Persist via initramfs or systemd-networkd

# ============ TX Ring Buffer (Kernel → NIC) ============
ethtool -G eth0 tx 4096

# ============ Kernel RX Queue ============
net.core.netdev_max_backlog=5000              # Kernel rx queue (default 1000)

# ============ Socket Buffer Tuning (TCP) ============
# Calculate BDP for 10Gbps, 1ms RTT
# BDP = (10 Gbps) × (1ms) = 5 Mb = 625 KB
# Set to 2 × BDP = 1.25 MB

net.core.rmem_default=1310720                 # 1.25 MB RX buffer default
net.core.rmem_max=2097152                     # 2 MB RX buffer max
net.core.wmem_default=1310720                 # 1.25 MB TX buffer default
net.core.wmem_max=2097152                     # 2 MB TX buffer max

# TCP autotune (let kernel scale buffer dynamically)
net.ipv4.tcp_rmem="4096 1310720 16777216"     # min, default, max
net.ipv4.tcp_wmem="4096 1310720 16777216"

# ============ TSO/GSO (Segmentation Offload) ============
# Check if enabled
ethtool -k eth0 | grep segmentation

# Enable (default enabled on modern NICs)
ethtool -K eth0 tso on gso on                 # Offload segmentation to NIC
ethtool -K eth0 gro on                        # Generic Receive Offload

# ============ Jumbo Frames ============
# Increase MTU for large frames (reduces processing overhead)
ip link set eth0 mtu 9000                     # Jumbo frame (9000 bytes)
# Check: ip link show eth0

# Verify all enabled
ethtool -g eth0; ethtool -k eth0
```

---

### ASCII Diagrams

#### Diagram 1: sysctl Parameter Persistence

```
System Boot
    ↓
Kernel starts with compiled-in defaults
    ↓
systemd-sysctl reads /etc/sysctl.conf
    ↓
systemd-sysctl loads /etc/sysctl.d/*.conf (alphab. order)
    ↓
Parameters applied to /proc/sys/
    ↓
Runtime: sysctl -w param=value (apply immediately)
    ↓
To persist runtime changes:
  └─ Add to /etc/sysctl.d/99-custom.conf
  └─ Run sysctl -p to reload
  └─ Survive next reboot
```

#### Diagram 2: TCP Connection Performance Impact (sysctl tuning)

```
Client                          Server
  │                              │
  ├─ SYN ───────────────────────>│ (in listen queue: tcp_max_syn_backlog)
  │                              ├─ Allocate connection
  │                              │
  │<─ SYN-ACK ───────────────────┤
  │                              │
  ├─ ACK ───────────────────────>│ (accepted; in accept queue: somaxconn)
  │                              │
  │ Connection established        │ Connection accepted
  │ (ready to send data)          │ (app calls accept() to get connection)
  │                              │
  │<─ Application Response ──────┤
  │                              │
  ├─ FIN ───────────────────────>│
  │                              │
  │<─ FIN-ACK ───────────────────┤
  │                              │
  └─ ACK ───────────────────────>│
                              ↓
                    TIME_WAIT state (tcp_fin_timeout)
                    Kernel holds socket 60s (default)
                    
Performance impact:
├─ Too small somaxconn: "Address already in use" errors
├─ Too small tcp_max_syn_backlog: SYN floods drop excess requests
├─ tcp_tw_reuse=1: Reuse TIME_WAIT sockets (avoid address exhaustion)
└─ tcp_fin_timeout too long: Ports remain unavailable
```

---

## Remote Access & System Control

### Textual Deep Dive

#### Internal Working Mechanism

SSH enables secure remote command execution through public-key cryptography and encrypted tunnels.

**1. SSH Protocol Layers**

```
Application Layer: scp, sftp, ssh (interactive shell)
         ↓
SSH Protocol (RFC 4250-4260)
  ├─ SSH_MSG_KEXINIT: Propose algorithms
  ├─ SSH_MSG_NEWKEYS: Activate encryption
  ├─ SSH_MSG_USERAUTH_REQUEST: Authenticate user
  ├─ SSH_MSG_CHANNEL_OPEN: Request channel (shell, subsystem, port forward)
  └─ SSH_MSG_CHANNEL_DATA: Transfer data
         ↓
Transport Layer (Encrypted)
  ├─ Algorithm negotiation (KEX, cipher, MAC, compression)
  ├─ Key exchange (Diffie-Hellman, ECDH, or Curve25519)
  ├─ Session key derivation
  └─ Encryption + HMAC on all traffic
         ↓
TCP Layer (Port 22, typically)
         ↓
Network Layer (IP)
```

**2. Public-Key Cryptography (SSH Keys)**

- **Ed25519 (Recommended)**
  - 256-bit elliptic curve; fast, secure, small key
  - `ssh-keygen -t ed25519 -C "email@example.com"`
  - Key format: 1 line, starts with `ssh-ed25519`

- **RSA (Legacy but still secure)**
  - 4096-bit minimum (2048 deprecated)
  - `ssh-keygen -t rsa -b 4096`
  - Key format: `ssh-rsa AAAAB3NzaC...`

- **Authentication Flow**
  ```
  Client: "I'm alice, here's my public key"
  Server: (Check if public key in ~/.ssh/authorized_keys)
  Server: "Prove you own the private key; here's a challenge"
  Client: hashlib.sha256(challenge + private_key) = signature
  Client: Send signature
  Server: Verify signature with public key
  Server: ✓ Authenticated (if signature matches)
  ```

**3. SSH Key Management at Scale**

- **Static key problem**: 10K servers × 100 devs = 1M keys; rotation = nightmare
- **Solution 1**: Certificate-based authentication
  - CA signs each user key with short TTL (24 hours)
  - Server trusts CA; accepts all CA-signed certs
  - Rotation: redeploy CA cert on servers, not individual keys

- **Solution 2**: Vault/Cloud secret manager
  - Developers request temporary SSH credentials from Vault
  - Vault generates time-limited key pairs
  - Automatic rotation; keys never stored persistently

**4. SSH Bastion Host Architecture**

```
Developer
    │
    ├─ SSH to bastion (SSH key + MFA)
    │
    └──> Bastion Host
         │
         ├─ User authenticated
         ├─ Audit log: who logged in, from where, when
         │
         └──> SSH to internal server
              (Bastion's SSH key; no password needed)
              Kernel records: "User X via bastion Y accessed server Z"
```

**Benefits:**
- Central identity verification point
- Single audit trail (all access goes through bastion)
- Network policy: only bastion has SSH to internal servers
- Easier to revoke access: delete bastion user vs. removing them from 10K servers

**5. SSH Multiplexing & Session Reuse**

- **Problem**: Sequential SSH commands create new transport layer connection each time (slow)
- **ControlMaster**: First connection establishes master socket; subsequentcommands reuse it
  ```bash
  # ~/.ssh/config
  Host *
    ControlMaster auto
    ControlPath ~/.ssh/control-%h-%p-%r
    ControlPersist 600  # Keep socket alive for 10 min
  ```
- **Benefit**: 2nd and 3rd commands ~100ms faster (skip TCP handshake + key exchange)

**6. SSH Port Forwarding (Tunneling)**

- **Local forward**: SSH client listening on localhost, forwards to remote
  ```bash
  ssh -L 3306:database.internal:3306 bastion
  # Now: mysql -h localhost -P 3306 connects through bastion to database.internal
  ```
- **Remote forward**: SSH server listening on remote, forwards to local
  ```bash
  ssh -R 8080:localhost:3000 jumphost
  # Now jumphost:8080 connects to your local :3000
  ```
- **Dynamic forward (SOCKS)**: SSH acts as SOCKS5 proxy
  ```bash
  ssh -D 1080 bastion
  # All traffic through bastion via SOCKS protocol
  ```

#### Architecture Role

SSH is the primary remote management channel in DevOps:

```
┌─────────────────────────────────────────┐
│  DevOps Engineer (Local Machine)        │
│  ├─ SSH client                          │
│  ├─ SSH config (~/.ssh/config)          │
│  ├─ SSH keys (~/.ssh/id_*private)       │
│  └─ SSH agent (ssh-add)                 │
└─────────────────────────────────────────┘
         ↓ (SSH over TLS)
┌─────────────────────────────────────────┐
│  Bastion Host (Public Gateway)          │
│  ├─ SSHD listening on port 22           │
│  ├─ PAM authentication / auditd         │
│  ├─ Network policy: inbound only        │
│  └─ Outbound SSH to internal servers    │
└─────────────────────────────────────────┘
         ↓ (SSH over private network)
┌─────────────────────────────────────────┐
│  Internal Servers (No public access)    │
│  ├─ SSH accepted from bastion only      │
│  ├─ Network policy: SSH from bastion    │
│  └─ User audit trail in syslog          │
└─────────────────────────────────────────┘
```

#### Production Usage Patterns

**Pattern 1: Certificate-based SSH Authentication**
```bash
# Organization CA signs user's public key with 24-hour TTL
ssh-keygen -s company-ca-key \
  -I alice@company.com \
  -n alice \
  -V +24h \
  -z 1 \
  alice-public-key.pub

# Result: alice-public-key-cert.pub (signed certificate)
# Servers trust company-ca-key; accept all signed certs
```

**Pattern 2: SSH Agent for Automation**
```bash
# Automation runs ssh commands without interactive password
eval $(ssh-agent -s)
ssh-add /path/to/automation-key
ansible-playbook deploy.yml
# Playbook can SSH to servers without exposing key to playbook
```

**Pattern 3: Bastion + kubectl Port Forwarding**
```bash
# Access Kubernetes API through bastion
ssh -L 6443:kubernetes-api:6443 bastion
# kubectl --kubeconfig config.yaml --server=https://localhost:6443
```

**Pattern 4: rsync for Bulk File Transfer**
```bash
# rsync over SSH; rsync handles files already synced
rsync -avz -e 'ssh -o StrictHostKeyChecking=no' \
  --exclude='.git' \
  local/dir/ bastion:/remote/dir/

# Only new/changed files transferred; resume on error
```

#### DevOps Best Practices

1. **Use Ed25519 Keys (Not RSA)**
   ```bash
   # Default: ed25519 (recommended)
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
   
   # Only use RSA if old systems block Ed25519
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

2. **Centralize Key Management**
   - Do NOT store SSH keys in Git
   - Use Vault/AWS Secrets Manager for key distribution
   - Rotate keys quarterly minimum

3. **Bastion Host for Scale**
   - Never expose SSH to 10K servers directly
   - Route all remote access through bastion
   - Audit layer: syslog from bastion = complete access trail

4. **SSH Agent Security**
   ```bash
   # Add key with 1-hour lock timeout
   ssh-add -t 3600 ~/.ssh/id_ed25519
   
   # Verify loaded keys
   ssh-add -l
   
   # Clear agent on logout
   kill $SSH_AGENT_PID
   ```

5. **rsync for Deployment**
   ```bash
   # More reliable than `scp` for large files
   # Checksums detect corruption; resume on failure
   rsync -avz --delete local/ bastion:/opt/app/
   ```

#### Common Pitfalls

1. **SSH Keys in Source Code**
   - Pitfall: Commit `.pem` file to Git; exposed forever
   - Result: Attacker clones repo, has access to all servers
   - Fix: Use Git hooks + secret scanning (truffleHog); Vault for keys

2. **Agent Forwarding Misconception**
   - Pitfall: Trust agent forwarding to bastion; assumes bastion not breached
   - Result: Compromised bastion = attacker uses your forwarded agent
   - Fix: Certificate-based auth; bastion can't forward your private key

3. **Lack of Bastion Host**
   - Pitfall: All developers SSH directly to 10K servers
   - Result: 10K audit trails; hard to correlate access; IP allowlisting nightmare
   - Fix: Bastion host; single audit point

4. **No Key Rotation**
   - Pitfall: Use same SSH key for 5 years; lost/stolen key not rotated
   - Result: Attacker has persistent access
   - Fix: Quarterly key rotation or certificate-based auth

5. **SSH Multiplexing Not Enabled**
   - Pitfall: Ansible runs 100 sequential SSH commands; 100 TCP handshashs
   - Result: Deployment takes 30 min instead of 5 min
   - Fix: Configure ControlMaster in ~/.ssh/config

---

### Practical Code Examples

#### Example 1: SSH Key Generation & Configuration

```bash
# Generate Ed25519 key pair
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "alice@company.com"
# Output:
# - ~/.ssh/id_ed25519 (private key; 400 permissions)
# - ~/.ssh/id_ed25519.pub (public key; 644 permissions)

# Display public key content (to add to authorized_keys)
cat ~/.ssh/id_ed25519.pub
# Output: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6/yMHX... alice@company.com

# SSH config for convenience
# ~/.ssh/config
Host bastion
    HostName bastion.company.com
    User alice
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes                # Only use specified identity
    ServerAliveInterval 60             # Keep connection alive
    ServerAliveCountMax 3
    ControlMaster auto                 # Multiplex connections
    ControlPath ~/.ssh/control-%h-%p-%r
    ControlPersist 600

Host internal-*
    ProxyJump bastion                  # Route through bastion
    User alice
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60

Host internal-web-*
    Hostname internal-web-%h.internal
    User ec2-user

# Now connect easily
ssh bastion                            # SSH to bastion
ssh internal-web-01                    # SSH through bastion to internal server
```

#### Example 2: Bastion Host Setup (Terraform + Ansible)

```hcl
# bastion.tf - Deploy hardened bastion host
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = aws_subnet.public.id
  
  associate_public_ip_address = true
  
  # Cloud-init: install SSM Session Manager (better than SSH)
  user_data = base64encode(file("${path.module}/bastion-init.sh"))
  
  tags = {
    Name = "bastion-host"
  }
}

resource "aws_security_group" "bastion" {
  name = "bastion-sg"
  
  # Allow SSH from specific IPs only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # Your office IP range
  }
  
  # Allow SSH outbound to VPC
  egress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.internal.id]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow other outbound (NTP, etc)
  }
}

resource "aws_security_group" "internal" {
  name = "internal-sg"
  
  # Only bastion can SSH to internal servers
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
}

# Deploy public SSH keys to bastion
resource "aws_instance" "bastion" {
  # ... (as above)
  
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~ubuntu/.ssh",
      "chmod 700 ~ubuntu/.ssh"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.public_ip
    }
  }
}

# Ansible provisioning
resource "null_resource" "bastion_hardening" {
  provisioner "local-exec" {
    command = "ansible-playbook -i ${aws_instance.bastion.public_ip}, bastion-hardening.yml"
  }
}
```

```yaml
# bastion-hardening.yml - Ansible playbook to harden bastion
---
- hosts: all
  become: yes
  
  tasks:
    - name: Disable SSH password authentication
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: restart sshd
    
    - name: Disable root login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: restart sshd
    
    - name: Restrict SSH to specific users
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?AllowUsers'
        line: 'AllowUsers ubuntu@* ec2-user@*'
      notify: restart sshd
    
    - name: Configure sudo audit
      lineinfile:
        path: /etc/audit/rules.d/sudo.rules
        line: '-w /etc/sudoers -p wa -k sudoers_changes'
        create: yes
      notify: restart auditd
    
    - name: Configure syslog forwarding
      lineinfile:
        path: /etc/rsyslog.conf
        regexp: '^#\*\.\* @@'
        line: '*.* @@syslog-server.internal:514'
      notify: restart rsyslog
    
    - name: Install monitoring agent
      apt:
        name: cloudwatch-agent
        state: present
    
  handlers:
    - name: restart sshd
      systemd:
        name: sshd
        state: restarted
    
    - name: restart auditd
      systemd:
        name: auditd
        state: restarted
    
    - name: restart rsyslog
      systemd:
        name: rsyslog
        state: restarted
```

#### Example 3: SSH Certificate-Based Authentication

```bash
# Organization generates CA key pair (done once, stored securely)
ssh-keygen -t ed25519 -f /etc/ssh/company-ca-key -C "company-ca" -N ""

# User generates their own key pair
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519

# CA signs user's public key with 24-hour TTL
ssh-keygen -s /etc/ssh/company-ca-key \
  -I alice@company.com \             # Certificate identity
  -n alice,alice@company.com \       # Principals (usernames valid for)
  -V +1d \                           # Valid for 1 day
  -C "Signed: $(date)" \
  ~/.ssh/id_ed25519.pub

# Result: ~/.ssh/id_ed25519-cert.pub (certificate; single file)

# Deploy CA public key to all servers (instead of every user's key)
# /etc/ssh/authorized_keys.d/ca.pub
ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub  # Inspect certificate

# Now user can SSH to any server that trusts company-ca-key
ssh alice@internal-server

# On server side, trust CA (one-time setup)
# /etc/ssh/sshd_config
TrustedUserCAKeys /etc/ssh/company-ca-key.pub

# Monitor certificate usage (add to syslog)
# /etc/ssh/sshd_config
SyslogFacility AUTH
LogLevel VERBOSE
```

#### Example 4: rsync for Reliable File Transfer

```bash
# Basic rsync (over SSH, with compression)
rsync -avz local/dir/ user@bastion:/opt/app/

# Options explained:
# -a = archive (preserve permissions, ownership, timestamps)
# -v = verbose (show files being transferred)
# -z = compress in transit (expensive for LAN; skips already compressed)
# -e ssh = use SSH (default; shows explicit)

# Advanced: exclude, delete, bandwidth limit
rsync -avz \
  --exclude='.git' \                 # Skip .git directory
  --exclude='__pycache__' \           # Skip Python cache
  --exclude='*.pyc' \                 # Skip compiled Python
  --delete \                          # Delete files on destination not in source
  --bwlimit=10000 \                   # Limit to 10MB/s
  --progress \                        # Show progress
  local/app/ bastion:/opt/app/

# Dry-run (show what would be transferred without doing it)
rsync -avz --dry-run local/dir/ user@bastion:/opt/app/

# Resume interrupted transfer (rsync is resumable unlike scp)
# If network drops halfway, re-run same command; picks up where it left off
rsync -avz local/dir/ user@bastion:/opt/app/

# Mirror remote to local (useful for logs, backups)
rsync -avz --delete user@bastion:/var/log/app/ local/app-logs/
```

#### Example 5: SSH Multiplexing & ControlMaster

```bash
# ~/.ssh/config - Global multiplexing
Host *
    ControlMaster auto              # Auto-use existing connection
    ControlPath ~/.ssh/control-%h-%p-%r  # Socket path
    ControlPersist 600              # Keep alive 10 min
    ServerAliveInterval 60          # Send keep-alive every 60s
    ServerAliveCountMax 3           # Disconnect after 3 timeouts

# Result: First SSH creates master socket; next 5 commands reuse it
# Before: ssh server1 "cmd1" (3s) + ssh server1 "cmd2" (3s) = 6s
# After: ssh server1 "cmd1" (3s) + ssh server1 "cmd2" (0.1s) = 3.1s

# Advanced: Force new connection (bypass multiplexing)
ssh -o ControlMaster=no server

# View active connections
ls -la ~/.ssh/control-*

# Manual master control
ssh -M -N server                    # Start master, don't run command
ssh server "command"                # Reuse master
ssh -S ~/.ssh/control-server-22-user -O exit server  # Close master
```

#### Example 6: Port Forwarding for Database Access

```bash
# Scenario: Database on private network; access from local machine

# Method 1: Local forwarding (localhost:3306 → database through bastion)
ssh -L 3306:database.internal:3306 \
    -N \                            # Don't execute command; just forward
    -f \                            # Fork to background
    -g \                            # Allow other machines to connect (careful!)
    bastion

# Now on your machine:
mysql -h localhost -P 3306 -u root -p

# Method 2: Dynamic SOCKS5 proxy
ssh -D 1080 \
    -N \
    -f \
    bastion

# Configure curl/wget to use SOCKS5
curl -x socks5h://localhost:1080 http://internal-service:8080

# Or system-wide via proxy settings
```

---

### ASCII Diagrams

#### Diagram 1: SSH Public-Key Authentication Flow

```
┌─────────────────────────────────────┐
│ Client (Alice)                      │
│ Has: private_key                    │
└─────────────────────────────────────┘
              ↓
         SSH Request
              │
              ├─ Username: alice
              ├─ Server public key request
              │
              ↓
┌──────────────────────────────────────┐
│ Server                               │
│ Has: /home/alice/.ssh/authorized_keys│
│      (contains alice's public_key)   │
└──────────────────────────────────────┘
              ↓
    Server generates random challenge
     (256-bit nonce)
              ↓
    Challenge sent to client
              ↓
┌─────────────────────────────────────┐
│ Client signs challenge with private  │
│ signature = sign(challenge,          │
│             private_key)             │
│ Signature sent to server             │
└─────────────────────────────────────┘
              ↓
┌──────────────────────────────────────┐
│ Server verifies signature:
│ if verify(signature,                │
│          alice_public_key,           │
│          challenge) == True:         │
│   ✓ Authentication succeeded         │
│ else:                                │
│   ✗ Authentication failed            │
└──────────────────────────────────────┘
              ↓
   Session established; encrypted
   channel ready for shell/commands
```

#### Diagram 2: Bastion Host with Multiple Hops

```
┌─────────────────┐
│ Developer Local │
│ PC (Public IP)  │
└─────────────────┘
         │
         │ SSH: alice@bastion.company.com (port 22)
         │ Encrypted over internet
         ↓
┌────────────────────────────────┐
│ Bastion Host (Public)          │
│ - ✓ auditd: alice logged in    │
│ - ✓ syslog: connection from IP │
└────────────────────────────────┘
         │
         │ SSH: alice@internal-db (port 22)
         │ Over private VPC network
         │ Bastion uses its own SSH key
         ↓
┌─────────────────────────────────┐
│ Internal DB Server (Private)    │
│ - ✓ auditd: alice@bastion user  │
│ - Network policy: SSH only from │
│   bastion security group        │
└─────────────────────────────────┘

Audit Trail:
1. Bastion syslog: alice from 203.0.113.0 logged in @ 14:32:15
2. Internal DB auditd: user alice (UID 1001) executed command X @ 14:32:20

Result:
- Correlation: Alice accessed DB at specific time
- Compliance: Single audit point (bastion) is authoritative
- Network: Direct access impossible; bastion intercepts all SSH
```

---

## Hands-on Scenarios

### Scenario 1: Kubernetes Cluster Incident - Memory Pressure & OOM Killer

**Problem Statement:**
A Kubernetes production cluster is experiencing unpredictable pod restarts. Pods are being killed with `OOMKilled` error; but metrics show memory usage at only 40-60% of requested limit. Engineering team suspects noisy neighbor problem but can't pinpoint root cause.

**Architecture Context:**
- 50-node Kubernetes cluster, mixed workloads (web services, batch jobs, databases)
- Each node: 64GB RAM, 16 cores
- Pods have resource requests/limits set; no QoS policy differentiation
- No memory pressure monitoring in place

**Step-by-Step Troubleshooting:**

1. **Verify OOM Killer Activity**
   ```bash
   # SSH to affected node (via bastion)
   ssh -J bastion node-12.internal
   
   # Check kernel logs for OOM killer activity
   journalctl -u kubelet | grep -i oom
   # Output: ... kernel: Memory cgroup out of memory: Killing process 15234 (nginx) 
   
   # Check dmesg for OOM invocations (only last 100 lines)
   sudo dmesg | tail -100 | grep -A5 "Out of memory"
   
   # Cross-reference timestamps with pod eviction times
   kubectl get events -A --sort-by='.lastTimestamp' | grep OOM
   ```

2. **Identify Memory Pressure Sources**
   ```bash
   # Monitor real-time memory pressure on node
   watch -n 1 "cat /proc/pressure/memory"
   # Output: some avg10=15.23 avg60=12.45 avg300=10.12 total=45821234
   # avg10 > 5 = significant memory pressure
   
   # Check which cgroup is consuming memory
   systemd-cgtop -b --sort=memory | head -20
   # Identify top memory consumers: maybe a batch job cgroup
   
   # Get detailed cgroup memory stats
   cat /sys/fs/cgroup/memory/kubelet/pod-abc123/memory.stat | grep total_rss
   ```

3. **Discover Root Cause: Memory Cache Bloat**
   ```bash
   # Check page cache (filesystem cache) size
   free -h | grep -i cache
   # Output: Buff/cache 32G  (32GB of memory held by page cache!)
   
   # Identify which files are cached
   sudo cat /proc/sysfs | grep -E "Cached|Buffers"
   
   # Drop caches to see if OOM goes away
   sudo sync && sudo sysctl -w vm.drop_caches=3  # Only for troubleshooting!
   
   # If OOM stops after cache drop: culprit is page cache (I/O-heavy workload)
   # If OOM continues: culprit is anonymous pages (memory leak)
   ```

4. **Root Cause Analysis: Improperly Configured Batch Job**
   ```bash
   # Find the batch job pod
   kubectl get pods -A | grep batch-job
   
   # Inspect pod resource requests
   kubectl get pod batch-job-12345 -o yaml | grep -A5 resources
   # Output: No memory request! (scheduler allows overallocation)
   
   # Check cgroup limits for the pod
   kubectl debug node/node-12 -it --image=busybox
   cat /sys/fs/cgroup/memory/kubelet/kubepods-burstable/pod-abc/memory.max
   # Shows limit, but no enforcement at pod level without request!
   ```

5. **Fix: Resource Policy Implementation**
   ```bash
   # Update batch job deployment with proper resource requests
   kubectl set resources deployment batch-job \
     --requests=memory=16Gi,cpu=8 \
     --limits=memory=20Gi,cpu=10
   
   # Enable ResourceQuota per namespace
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: compute-quota
     namespace: batch-processing
   spec:
     hard:
       requests.memory: "100Gi"
       requests.cpu: "50"
       limits.memory: "150Gi"
       limits.cpu: "100"
   EOF
   
   # Add LimitRange to prevent unbounded requests
   kubectl apply -f - <<EOF
   apiVersion: v1
   kind: LimitRange
   metadata:
     name: pod-limits
     namespace: batch-processing
   spec:
     limits:
     - max:
         memory: "20Gi"
         cpu: "10"
       min:
         memory: "256Mi"
         cpu: "100m"
       type: Pod
   EOF
   ```

6. **Enable Memory Pressure Monitoring**
   ```bash
   # Deploy Prometheus rule to alert on memory pressure
   cat <<EOF | kubectl apply -f -
   apiVersion: monitoring.coreos.com/v1
   kind: PrometheusRule
   metadata:
     name: memory-pressure-alerts
   spec:
     groups:
     - name: memory.rules
       rules:
       - alert: NodeMemoryPressure
         expr: |
           node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes < 0.1
         for: 5m
         labels:
           severity: critical
         annotations:
           summary: "Node {{ \$labels.node }} memory pressure > 90%"
       
       - alert: ContainerOOMKiller
         expr: |
           increase(container_oom_events_total[5m]) > 0
         annotations:
           summary: "Container OOM killed on {{ \$labels.pod }}"
   EOF
   
   # Monitor memory pressure PSI metrics (if available)
   kubectl top node node-12                    # Node-level memory
   kubectl top pod -A | sort -k3 -hr | head   # Pod-level memory
   ```

**Best Practices Applied:**
✓ **Resource requests/limits** for all pods (prevents overallocation)
✓ **Namespace ResourceQuota** (caps per-namespace consumption)
✓ **LimitRange** (prevents extreme requests)
✓ **Memory pressure monitoring** (alert before OOM)
✓ **Graceful draining** instead of eviction (PreStop hooks)

---

### Scenario 2: SSH Key Rotation at Scale (10K Servers)

**Problem Statement:**
Your organization discovered that SSH private keys used by automation agents have been stored in plaintext in Git repositories for the past 3 years. Security team demands immediate key rotation across 10,000 production servers.

**Architecture Context:**
- 10,000 servers across 5 data centers and 3 cloud providers
- 100+ automation users with embedded SSH keys
- No centralized key management system currently in place
- ~8 hours maximum acceptable downtime for rotation

**Step-by-Step Implementation:**

1. **Phase 1: Audit Current Key Usage (2 hours)**
   ```bash
   # Scan all servers to find current authorized SSH keys
   for server in $(cat /tmp/serverlist.txt); do
     ssh -o ConnectTimeout=5 $server \
       "grep -r '^ssh-rsa' /home/*/ssh/authorized_keys 2>/dev/null" \
       >> /tmp/current_keys.txt &
   done | wait
   
   # Aggregate unique keys
   cut -d' ' -f1,2 /tmp/current_keys.txt | sort -u > /tmp/unique_keys.txt
   
   # Find keys in Git repositories
   git log -p --all | grep -E '^[+-].*-----BEGIN PRIVATE KEY-----' \
     > /tmp/leaked_keys.txt
   
   # Match leaked keys with deployed keys (if any match, they're compromised)
   ```

2. **Phase 2: Generate New Keys & Prepare Distribution (1 hour)**
   ```bash
   # Generate new Ed25519 key for automation
   ssh-keygen -t ed25519 -f /tmp/automation-new-key -N "" \
     -C "automation@company.com-$(date +%Y%m%d)"
   
   # Create Ansible playbook for parallel key rotation
   cat <<EOF > rotate-ssh-keys.yml
   ---
   - hosts: all
     become: yes
     vars:
       old_ssh_key: "ssh-rsa AAAAB3NzaC1y...OLD_KEY_HERE"
       new_ssh_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5...NEW_KEY_HERE"
       automation_user: "automation"
     
     pre_tasks:
       - name: Verify old key is present
         shell: grep -q "{{ old_ssh_key }}" /home/{{ automation_user }}/.ssh/authorized_keys
         register: old_key_check
         changed_when: false
     
     tasks:
       - name: Add new key to authorized_keys (dual mode)
         lineinfile:
           path: /home/{{ automation_user }}/.ssh/authorized_keys
           line: "{{ new_ssh_key }}"
           state: present
           create: yes
           mode: 0600
         register: new_key_added
         when: new_key_added is not defined or new_key_added.changed
       
       - name: Test new key works (non-blocking)
         shell: |
           ssh -i /tmp/automation-new-key -o ConnectTimeout=5 \
               -o StrictHostKeyChecking=no {{ automation_user }}@localhost true &
         async: 10
         poll: 0
         register: key_test
       
       - name: Wait for key test
         async_status:
           jid: "{{ key_test.ansible_job_id }}"
         register: job_result
         until: job_result.finished
         retries: 5
         delay: 2
     
     post_tasks:
       - name: Only remove old key after verification  
         lineinfile:
           path: /home/{{ automation_user }}/.ssh/authorized_keys
           line: "{{ old_ssh_key }}"
           state: absent
         when: job_result.failed is not defined or not job_result.failed
   EOF
   
   # Run rotation in batches (avoid all servers at once)
   ansible-playbook rotate-ssh-keys.yml -i inventory.ini \
     --extra-vars "ansible_forks=100" \
     --vault-password-file=/etc/ansible/vault-pass
   ```

3. **Phase 3: Parallel Rotation with Canary Validation (4 hours)**
   ```bash
   # Stage 1: Canary - rotate 5 servers
   ansible-playbook rotate-ssh-keys.yml \
     -i inventory.ini \
     -l "(server001|server002|server003|server004|server005)" \
     --extra-vars "batch_id=canary"
   
   # Validate canary servers respond to new key
   for server in server{001..005}; do
     ssh -i /tmp/automation-new-key $server "systemctl status" \
       && echo "✓ $server: new key works" \
       || echo "✗ $server: FAILED with new key"
   done > /tmp/canary_validation.txt
   
   # If all canary servers pass, continue to production
   if grep "FAILED" /tmp/canary_validation.txt; then
     echo "Canary failed! Halting rotation."
     exit 1
   fi
   
   # Stage 2: Rotate data centers in parallel (2 at a time)
   for datacenter in us-east-1a us-west-1b apac-sg eu-west-1; do
     (
       ansible-playbook rotate-ssh-keys.yml \
         -i inventory.ini \
         --extra-vars "datacenter=$datacenter" \
         --forks=50 &
     )
     sleep 10  # Stagger starts to avoid thundering herd
   done | wait
   
   # Stage 3: Validation & Rollback Plan
   # Monitor Ansible execution
   ansible --all -i inventory.ini -m shell -a \
     "grep -c 'ssh-ed25519' /home/automation/.ssh/authorized_keys" \
     | grep -c "=> 2" > /tmp/rotation_status.txt
   
   ROTATED=$(wc -l < /tmp/rotation_status.txt)
   TOTAL=10000
   if [ "$ROTATED" -lt "$((TOTAL * 95 / 100))" ]; then
     echo "Less than 95% rotated; triggering rollback!"
     # Rollback: add old key back to failed servers
   fi
   ```

4. **Phase 4: Audit Trail & Cleanup (1 hour)**
   ```bash
   # Verify all servers have new key
   ansible all -i inventory.ini -m stat \
     -a "path=/home/automation/.ssh/authorized_keys" \
     | grep "^server" > /tmp/final_inventory.txt
   
   # Generate audit report
   aws s3 cp /tmp/final_inventory.txt s3://compliance-audit-bucket/ \
     --sse AES256
   
   # Record rotation details for compliance
   cat <<EOF > /tmp/rotation_audit.json
   {
     "rotation_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
     "old_key_fingerprint": "$(ssh-keygen -lf /tmp/automation-old-key.pub)",
     "new_key_fingerprint": "$(ssh-keygen -lf /tmp/automation-new-key.pub)",
     "servers_rotated": $ROTATED,
     "servers_total": 10000,
     "rotation_method": "ansible_parallel_with_canary",
     "completed_without_incidents": true
   }
   EOF
   
   # Store audit report
   aws s3 cp /tmp/rotation_audit.json s3://compliance-audit-bucket/ \
     --sse AES256
   
   # Securely destroy old key material (not recovery possible)
   shred -vfz -n 10 /tmp/automation-old-key
   aws secretsmanager delete-secret \
     --secret-id old-automation-ssh-key \
     --force-delete-without-recovery
   ```

5. **Phase 5: Future Prevention (Ongoing)**
   ```bash
   # Implement secret scanning in Git
   # .pre-commit-config.yaml
   repos:
   - repo: https://github.com/Yelp/detect-secrets
     rev: v1.4.0
     hooks:
     - id: detect-secrets
       args: ['--baseline', '.secrets.baseline']
   
   # Deploy secret management via HashiCorp Vault
   # developers request temporary SSH certs instead of static keys
   vault write -f ssh/sign/automation \
     username=automation \
     ip_address=10.0.1.0/24 \
     cert_type=user \
     ttl=24h
   ```

**Best Practices Applied:**
✓ **Automated rotation** (Ansible parallelization)
✓ **Canary validation** (5 servers before full rollout)
✓ **Dual-mode during transition** (old & new keys active)
✓ **Audit trail** (JSON record for compliance)
✓ **Rollback capability** (if > 5% fail)
✓ **Future prevention** (secret scanning + Vault)

---

### Scenario 3: SELinux Policy Troubleshooting - Nginx Cannot Write to Custom Directory

**Problem Statement:**
Nginx web server running in production fails to write logs to a custom directory. Error: `Permission denied` when opening `/var/data/logs/nginx.log`. File permissions appear correct (`755 ownership`), but SELinux denies access.

**Architecture Context:**
- Nginx process runs under `nginx` user
- Custom log directory: `/var/data/logs/` on separate filesystem
- SELinux in enforcing mode (production requirement)
- Team is unfamiliar with SELinux troubleshooting

**Step-by-Step Resolution:**

1. **Verify It's SELinux, Not Standard Permissions**
   ```bash
   # Check current SELinux status
   getenforce                         # Should show "Enforcing"
   
   # Verify standard permissions allow access
   ls -ld /var/data/logs
   # Output: drwxr-xr-x ... nginx nginx ... /var/data/logs
   
   # Try writing as nginx user (should work if only POSIX perms)
   sudo -u nginx touch /var/data/logs/test.txt
   # If fails: ls: cannot open: Permission denied -> SELinux issue
   ```

2. **Check Current SELinux Context**
   ```bash
   # View current contexts
   ls -Z /var/data/logs                # Show SELinux context
   # Output: unconfined_u:object_r:default_t:s0 /var/data/logs
   
   # View Nginx process context
   ps -eZ | grep nginx
   # Output: system_u:system_r:nginx_t:s0 ... nginx: master process
   
   # Mismatch: nginx process context is nginx_t, directory context is default_t
   # nginx_t may not have permission to write to default_t labeled files
   ```

3. **Enable Audit Mode to Capture Violations**
   ```bash
   # Switch SELinux for nginx to permissive (log denials, don't block)
   sudo semanage permissive -a nginx_t
   # Or: sudo semanage permissive -l | grep nginx  # Verify
   
   # Restart Nginx
   systemctl restart nginx
   
   # Wait 30 seconds for operations to trigger
   sleep 30
   
   # Check audit logs for denials
   ausearch -m avc -ts recent 2>/dev/null | grep nginx | head -20
   # Output: type=AVC msg=audit(...): avc: denied { write } for pid=XX 
   #         comm="nginx" name="nginx.log" dev="sda1" scontext=system_u:system_r:nginx_t:s0
   #         tcontext=unconfined_u:object_r:default_t:s0 tclass=file
   ```

4. **Fix: Set Correct SELinux Context**
   ```bash
   # Option A: Apply httpd system policy context
   sudo semanage fcontext -a -t httpd_sys_rw_content_t "/var/data/logs(/.*)?"
   # or
   sudo semanage fcontext -a -t httpd_log_t "/var/data/logs(/.*)?"
   
   # Restore context to directory
   sudo restorecon -Rv /var/data/logs
   
   # Verify context changed
   ls -Z /var/data/logs
   # Output should now be: system_u:object_r:httpd_log_t:s0 /var/data/logs
   
   # Option B: If custom context needed
   sudo semanage fcontext -a -t var_log_t "/var/data/logs(/.*)?"
   sudo restorecon -Rv /var/data/logs
   ```

5. **Verify Write Permission & Switch to Enforcing**
   ```bash
   # Test write as nginx user
   sudo -u nginx bash -c 'echo "test" >> /var/data/logs/nginx.log'
   # Should succeed now
   
   # Remove permissive mode (return to enforcing)
   sudo semanage permissive -d nginx_t
   
   # Restart Nginx in enforcing mode
   systemctl restart nginx
   
   # Verify logs are being written
   tail -f /var/data/logs/nginx.log  # Should show access logs
   
   # Check for any remaining denials (should be none)
   ausearch -m avc -ts recent | grep nginx
   # Should return empty
   ```

6. **Persistent Policy Management**
   ```bash
   # Save policy changes to a script for automation
   cat <<EOF > /opt/selinux-policies/nginx-custom-logs.sh
   #!/bin/bash
   # SELinux policy for Nginx custom log directory
   
   # Define custom context mapping
   semanage fcontext -a -t httpd_log_t "/var/data/logs(/.*)?"
   
   # Apply immediately
   restorecon -Rv /var/data/logs
   
   echo "✓ SELinux context applied for /var/data/logs"
   EOF
   
   chmod +x /opt/selinux-policies/nginx-custom-logs.sh
   
   # Document in Ansible for CI/CD
   - name: Apply SELinux policy for Nginx logs
     shell: /opt/selinux-policies/nginx-custom-logs.sh
     when: ansible_selinux.status == "enabled"
   ```

**Best Practices Applied:**
✓ **Audit mode first** (logs violations without blocking)
✓ **Correct context mappings** (use httpd_log_t, not default_t)
✓ **Persistent policy** (saved as script for reproducibility)
✓ **Graceful enforcement** (test before enforcing mode)
✓ **Documentation** (record policy rationale)

---

### Scenario 4: High-Performance Tuning for Database Server

**Problem Statement:**
Database server (PostgreSQL) is processing 20K queries per second but experiencing unexpected latency spikes (p99 latency increases from 5ms to 150ms at peak hours). Hardware is underutilized (CPU 40%, memory 60%), suggesting kernel/OS bottleneck.

**Architecture Context:**
- Single DB server: 32 cores, 256GB RAM, NVMe SSD storage
- Workload: OLTP (mixed read-write), ~1-2MB average query result size
- Network: 10 Gbps connection to application servers
- Current kernel: default tuning (unoptimized)

**Step-by-Step Optimization:**

1. **Baseline Measurement**
   ```bash
   # Capture baseline metrics before tuning
   # Use `perf` for detailed profiling
   sudo perf stat -e cycles,instructions,cache-references,cache-misses \
     -p $(pgrep postgres | head -1) -- sleep 60
   # Output captures IPC (Instructions Per Cycle), cache hit ratio
   
   # Network baseline
   sar -n DEV 1 60 | grep eth0 > /tmp/baseline_network.txt
   
   # Disk I/O baseline
   iostat -x 1 60 /dev/nvme0n1 > /tmp/baseline_disk.txt
   
   # Database performance baseline
   pgbench -T 60 -c 32 -j 8 > /tmp/baseline_pgbench.txt
   # Records: TPS (transactions per second), latency percentiles
   ```

2. **Identify Bottleneck via System Profiling**
   ```bash
   # Monitor system behavior during load
   watch -n 1 '
     echo "=== CPU Scheduling ===";
     mpstat -P ALL 1 1 | grep "CPU";
     echo "=== Memory ===";
     free -h | tail -2;
     echo "=== Disk I/O ===";
     iostat -dx 1 1 | grep nvme;
     echo "=== Context Switches ===";
     vmstat 1 1 | tail -1 | awk "{print \"Context switches: \" \$12 \"/s\"}";
   '
   
   # If context switches > 10,000/s: CPU migration is high cost
   # If memory pressure > 0: swap/OOM path being hit
   # If disk io wait > 10%: disk is bottleneck (tune readahead/cache)
   
   # Detailed syscall tracing (expensive; run briefly)
   sudo strace -p $(pgrep postgres | head -1) -c -e write 2>&1 | head -20
   # Shows time spent in each syscall
   ```

3. **Apply Kernel Tuning**
   ```bash
   # Create optimized sysctl config for high-performance database
   cat <<EOF> /etc/sysctl.d/99-postgresql-tuning.conf
   # ============ Network Tuning ============
   # Database typically sends/receives large result sets
   net.core.rmem_default=134217728                  # 128MB RX default
   net.core.wmem_default=134217728                  # 128MB TX default
   net.core.rmem_max=134217728
   net.core.wmem_max=134217728
   
   # TCP auto-tuning (let kernel scale buffer dynamically)
   net.ipv4.tcp_rmem="4096 134217728 268435456"   # min, default, max
   net.ipv4.tcp_wmem="4096 134217728 268435456"
   
   # No packet buffering/switching needed at high throughput
   net.core.netdev_max_backlog=5000
   net.ipv4.tcp_max_syn_backlog=8192
   
   # ============ Memory Management ============
   # Database buffers should stay in memory (never swap)
   vm.swappiness=1                                  # Nearly no swapping
   vm.dirty_ratio=20                                # Flush dirty faster = slower writes but less impact
   vm.dirty_background_ratio=10
   vm.dirty_expire_centisecs=3000                   # Flush every 30s if not dirtied
   
   # Shared memory for IPC (PostgreSQL uses for buffer pool)
   kernel.shmmax=214748364800                       # 200GB (adjust for buffer pool size)
   kernel.shmall=52428800                           # 200GB in pages
   
   # ============ Process/Connection Limits ============
   net.core.somaxconn=8192
   net.ipv4.tcp_max_syn_backlog=8192
   fs.file-max=2097152                              # Max open file descriptors globally
   
   # ============ CPU Scheduling ============
   # NUMA-aware scheduling (larger cost = pin migrations to socket boundaries)
   kernel.sched_migration_cost_ns=5000000           # 5ms cost; reduces migrations
   kernel.sched_autogroup_enabled=0                 # Disable for predictable scheduling
   
   # ============ File System ============
   # Reduce file system overhead for database workloads
   fs.mount_max=100000
   
   EOF
   
   # Apply immediately
   sysctl -p /etc/sysctl.d/99-postgresql-tuning.conf
   ```

4. **I/O Scheduler Tuning**
   ```bash
   # Check current I/O scheduler
   cat /sys/block/nvme0n1/queue/scheduler
   # Output: [none] mq-deadline kyber bfq
   
   # For NVME SSD, use 'none' (let device handle scheduling)
   echo none > /sys/block/nvme0n1/queue/scheduler
   
   # Persistent via initramfs (survives reboot)
   echo "SUBSYSTEM==\"block\", ATTR{queue/scheduler}=\"none\"" \
     | sudo tee /etc/udev/rules.d/60-io-scheduler.rules
   
   # Or use tuned profile
   tuned-adm profile latency-performance
   ```

5. **Application-Level Configuration (PostgreSQL)**
   ```ini
   # postgresql.conf - Tune for 20K QPS, 32 cores, 256GB RAM
   
   # Memory configuration
   shared_buffers = 64GB                    # ~25% of RAM for hot data
   effective_cache_size = 200GB             # Help planner choose index scans
   maintenance_work_mem = 4GB                # For VACUUM, REINDEX
   work_mem = 512MB                         # Per-operation (32GB / 64 workers)
   
   # Connection management
   max_connections = 1000
   max_prepared_transactions = 1000
   
   # WAL tuning (Write-Ahead Logging)
   wal_buffers = 16MB
   checkpoint_timeout = 15min               # Balance between durability/performance
   checkpoint_completion_target = 0.9       # Spread I/O over time
   max_wal_size = 8GB
   
   # Query optimization
   random_page_cost = 1.0                   # SSD: very low random access cost
   effective_io_concurrency = 32            # Match NVMe queue depth
   
   # Parallelization for complex queries
   max_parallel_workers = 32
   max_parallel_workers_per_gather = 16
   
   # Logging for analysis
   log_min_duration_statement = 100         # Log queries > 100ms
   log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
   ```

6. **Validate Performance After Tuning**
   ```bash
   # After applying tuning, restart PostgreSQL
   systemctl restart postgresql
   
   # Run same pgbench workload
   pgbench -T 60 -c 32 -j 8 > /tmp/after_tuning_pgbench.txt
   
   # Compare baseline vs tuning
   echo "=== BASELINE ===" && grep "tps" /tmp/baseline_pgbench.txt
   echo "=== AFTER TUNING ===" && grep "tps" /tmp/after_tuning_pgbench.txt
   
   # Expected before tuning:
   # transaction type: <builtin: TPC-B (sort of)>
   # scaling factor: 100
   # query mode: simple
   # number of clients: 32
   # number of threads: 8
   # number of transactions per client: 1666
   # number of statements per transaction: 5
   # latency average = 96.234 ms
   # tps = 332.456 (including connections establishing)
   
   # Expected after tuning:
   # latency average = 12.456 ms (8-10x improvement!)
   # tps = 2567.123
   # p99 latency = 45ms (instead of 150ms)
   ```

**Best Practices Applied:**
✓ **Baseline before tuning** (measure impact quantitatively)
✓ **Bottleneck identification** (CPU/memory/disk/network)
✓ **Workload-specific tuning** (OLTP != OLAP)
✓ **Kernel + application tuning** (both needed)
✓ **Validation with realistic load** (pgbench matches production)
✓ **Documented rationale** (why each parameter set)

---

## Interview Questions

### Question 1: Design a Zero-Trust SSH Architecture for 50,000 Servers

**Question:**
You're tasked with designing remote access for a global infrastructure with 50,000 servers across multiple cloud providers and on-premises data centers. The security team demands zero-trust principles: no direct SSH from the internet, all access logged, and SSH keys should never be stored on personal devices. Design the architecture and explain trade-offs.

**Expected Answer from Senior DevOps Engineer:**

A well-structured answer should cover:

**Architecture Components:**

1. **Bastion Host Layer** (not "bastion = single server")
   ```
   - Multiple bastion hosts per region (HA, geo-redundancy)
   - Deployed on hardened images, minimal attack surface
   - All inbound SSH only to bastion public subnet
   - Internal network policies: bastion → internal servers via SSH only
   ```

2. **Authentication & Authorization**
   ```
   - Certificate-based SSH (not static keys)
   - Short TTL (24-hour user certificates)
   - Issued by central Certificate Authority (Vault, cloud HSM)
   - MFA on bastion authentication (Okta, Azure AD integration via PAM)
   - User credentials stored in central identity system (not local /etc/passwd)
   ```

3. **Audit Trail**
   ```
   - auditd on bastion: log all SSH sessions
   - PAM audit: log authentication attempts
   - Central syslog aggregation (ELK, Splunk, cloud SIEM)
   - SIEM correlation: alice logged in @ 14:30, accessed server X
   - Immutable audit logs (prevent tampering)
   ```

4. **Access Policy**
   ```
   - RBAC: developers can ssh to "web-prod-*" servers only
   - Network policy: developer workstations can't SSH; must use bastion
   - Time-based access: only during business hours (if needed)
   - Approval workflow: access requests → manager approval → issued cert
   ```

**Trade-offs & Reasoning:**

| Design Choice | Benefit | Trade-off |
|---|---|---|
| **Certificate over static keys** | Rotation-free; TTL limits damage | More infrastructure (Vault); cert generation latency |
| **Bastion HA (multi-region)** | Fault-tolerant; comply with SLA | Extra operational cost; state sync complexity |
| **MFA on bastion** | Prevents account hijacking | User friction; slower access; need backup codes |
| **Central audit syslog** | Forensic gold; compliance trail | High bandwidth; storage cost; parsing latency |
| **Deny-by-default network policy** | Prevents lateral movement | Requires careful RBAC; maintenance burden |

**Implementation Sketch:**

```hcl
# Terraform: bastion + certificate setup
resource "aws_instance" "bastion" {
  count = 2  # HA (one per AZ)
  # … hardened AMI, security groups restricting inbound to office IPs
  
  user_data = <<-EOF
    #!/bin/bash
    # Install Vault agent (pulls certs)
    vault agent -config=/etc/vault/bastion-agent.hcl
    
    # SSH config: trust CA instead of individual keys
    echo "TrustedUserCAKeys /etc/ssh/ca.pub" >> /etc/ssh/sshd_config
  EOF
}

# Vault SSH secret engine
resource "vault_generic_secret" "ssh_ca" {
  path = "ssh/config/ca"
  data_json = jsonencode({
    generate_signing_key = true
  })
}

# Developer requests certificate
# vault write -f ssh/sign/developer \
#   username=alice \
#   ip_address=10.0.0.0/8 \
#   ttl=24h
# → Returns alice-cert.pub (signed cert, valid 24h)
```

**Monitoring & Incident Response:**

```bash
# Alert on suspicious patterns
# - Alice typically logs in 9am-5pm; alert if 2am access
# - Alice typically accesses 5 servers; alert if accessing 100+ servers
# - Access patterns: alert if new server accessed

# Example SIEM rule (ELK):
{
  "trigger": "alert",
  "condition": {
    "timeframe": "1h",
    "aggregation": "cardinality",
    "field": "server_hostname",
    "group_by": "user",
    "threshold": 20  # Alert if user accesses > 20 unique servers in 1h
  }
}
```

**Addressing Specific Scenarios:**

1. **"But developers need to SSH from the beach"**
   - Use Vault: developers issue temporary cert on demand
   - Cert is tied to their workstation; if stolen, TTL expires in 24h
   - No persistent keys; if workstation is lost, revoke future certs only

2. **"What if bastion is compromised?"**
   - Attacker can't SSH to internal servers (different SSH key for bastion → internal)
   - Attacker can't read audit logs (immutable, centralized SIEM)
   - Attacker's actions are logged; incident team detects within hours
   - Bastion is ephemeral: destroy and redeploy (minutes, via Terraform)

3. **"Operational overhead?"**
   - Vault operational cost: ~2 FTE to manage (certificate policies, rotation)
   - Automation: Ansible deploys bastion config; CI/CD auto-provisions
   - Trade: small overhead for compliance (SOC 2, PCI-DSS) = worth it

---

### Question 2: Troubleshoot Linux OOM Killer - What Questions Would You Ask?

**Question:**
A production database server is experiencing random process kills. The error log shows OOMKilled, but memory utilization is only 60%. Walk me through how you'd diagnose the root cause.

**Expected Answer from Senior DevOps Engineer:**

The best answer demonstrates **systematic debugging** rather than jumping to conclusions.

**Phase 1: Clarify Context (Ask Questions)**

1. Is this Kubernetes or bare metal?
   - **Why**: OOM behavior differs; cgroups memory.max vs. system-wide memory
   - **If Kubernetes**: check pod limits vs. actual usage; maybe pod has request < limit config
   - **If bare metal**: check system-wide memory accounting

2. Which process is being killed?
   - **Why**: OOM killer selection criterion matters
   - **Check**: `dmesg | grep "Killing process"` to see victim selection
   - **Context**: least-recently-used process? Or highest oom_score?

3. What's the 60% memory? (Used, or used + cache?)
   - **Why**: `free -h` shows confusing numbers
   - **Check**: `cat /proc/meminfo` to see MemAvailable (truly free), not just MemFree
   - **Common mistake**: People confuse MemFree (completely unused) with MemAvailable (can be reclaimed from cache/buffer)

4. Is there swap enabled?
   - **Why**: Swap presence changes behavior
   - **Check**: `free -h | grep Swap` or `swapon -s`
   - **If enabled**: OOM killer might not trigger until swap is exhausted too

5. What workload is running? (Database, batch job, web server?)
   - **Why**: Workload memory pattern matters
   - **Database**: might be holding cache; not a leak
   - **Batch job**: might be reading entire file into memory; expected
   - **Web server**: should behave predictably; unexpected growth = bug

**Phase 2: Data Collection**

```bash
# Snapshot current state
echo "=== Memory Details ===" && cat /proc/meminfo | grep -E "MemTotal|MemFree|MemAvailable|Cached|Buffers"

# Real memory usage vs. shows reported:
MemTotal=262144000 kB         # 250 GB
MemFree=104857600 kB          # 100 GB free (unused)
MemAvailable=204800000 kB     # 195 GB available (can be reclaimed)

# Wait, if MemAvailable > 195GB, why OOM killer?
# Answer: It's not due to lack of memory, likely cgroup limit!

echo "=== Per-Process Memory ===" && \
  ps aux --sort=-%mem | head -20  # Top 20 by memory %

echo "=== Cgroup Limits (if Kubernetes or Docker) ===" && \
  cat /sys/fs/cgroup/memory/memory.limit_in_bytes  # Hard limit
  cat /sys/fs/cgroup/memory/memory.current         # Current usage
  cat /sys/fs/cgroup/memory/memory.max_usage_in_bytes  # Peak usage

echo "=== OOM Score ===" && \
  for pid in $(pgrep postgres); do \
    echo "PID:$pid Score:$(cat /proc/$pid/oom_score)"; \
  done

echo "=== Page Cache Size ===" && \
  grep Cached /proc/meminfo  # Filesystem cache

echo "=== Memory Pressure ===" && \
  cat /proc/pressure/memory  # PSI: some avg10=X avg60=Y avg300=Z
```

**Phase 3: Diagnose Based on Findings**

**Scenario A: cgroup limit exceeded (Most Common)**
```
If: /sys/fs/cgroup/memory/memory.current > memory.limit_in_bytes

Root cause: Pod/container has explicit limit; workload exceeded it
Solution: Increase limit or optimize workload

Fix:
kubectl set resources deployment db --limits memory=16Gi
# or horizontally scale (split workload across multiple pods)
```

**Scenario B: Page cache exhaustion (Second Most Common)**
```
If: MemAvailable << MemTotal
    Cached is eating most of memory
    MemFree is very low

Root cause: Disk workload is reading/writing large files
Solution: Reduce cache hunger or increase disk throughput

Diagnosis:
  vmtouch -s /path/to/large/file  # See file page cache usage
  iotop                           # Which process is doing I/O?

Fix:
  mount -o noatime /data  # Stop atime updates
  sysctl vm.dirty_ratio=5  # More aggressive cache flushing
  # Or: add more I/O bandwidth (SSD, RAID)
```

**Scenario C: Memory leaks in application**
```
If: Process memory % grows over hours
    MemAvailable stays constant
    No workload increase

Root cause: Application has memory leak
Solution: Fix application code or restart periodically

Diagnosis:
  valgrind --leak-check=full myapp  # Detect leaks
  perf mem                          # Track memory allocations
  # Or: Check application logs for error messages

Fix:
  # Patch application code
  # In interim: Kubernetes restartPolicy: OnFailure with restart backoff
```

**Scenario D: Unexpected process growth**
```
If: OOM killer targets process that shouldn't be using 100s GB
Root cause: Bug, misconfiguration, or attack

Diagnosis:
  strace -p $PID           # See which syscalls allocating memory
  /proc/$PID/maps          # Which regions of memory mapped
  # Or: Check recent code changes

Fix: Revert changes, investigate root cause
```

**Follow-up Actions:**

1. **Implement memory monitoring**
   ```bash
   # Alert before OOM killer runs
   memory_available_pct = $(echo "scale=2; $(grep MemAvailable /proc/meminfo | awk '{print $2}') / $(grep MemTotal /proc/meminfo | awk '{print $2}') * 100" | bc)
   if (( $(echo "$memory_available_pct < 5" | bc -l) )); then
     alert "Memory pressure > 95%"
   fi
   ```

2. **Prevent OOM by setting limits**
   ```bash
   # Kubernetes: set resource limits
   # Bare metal: use systemd cgroup limits
   systemctl set-property myapp.service MemoryMax=4G
   ```

3. **Graceful degradation**
   ```bash
   # Application should respond to memory pressure
   # Not rely on OOM killer (non-deterministic)
   # Instead: circuit breaker, cache eviction, shed load
   ```

---

### Question 3: SELinux or AppArmor? How Would You Choose for a New Deployment?

**Question:**
You're deploying a new microservices platform on Linux. Security team is asking whether to use SELinux or AppArmor. Walk through your decision process, including which you'd recommend and why.

**Expected Answer from Senior DevOps Engineer:**

**Initial Context Gathering:**

1. **What's the Linux distribution?**
   - RHEL/CentOS/Fedora → SELinux is default; AppArmor not supported
   - Ubuntu/Debian → AppArmor is default; SELinux available but not native
   - **Implication**: Distribution choice might already decide for you

2. **Who's maintaining this? (Operations team skill level)**
   - Experienced with SELinux? → Leverage that knowledge
   - New deployment? Choose easier option (AppArmor is more intuitive)

3. **What workloads? (Predictability matters)**
   - Stable, well-known services (Nginx, PostgreSQL) → SELinux has reference policies
   - Custom/proprietary services → AppArmor easier to write policies for
   - Rapidly changing code → AppArmor; less churn in policies

**Comparison Matrix:**

| Dimension | SELinux | AppArmor | Winner |
|-----------|---------|----------|--------|
| **Learning Curve** | Steep (contexts, types, roles) | Gentler (path-based) | AppArmor |
| **Policy Reference** | Extensive (Fedora policies) | Limited | SELinux |
| **Flexibility** | Very strict (deny by default) | Flexible (easier exceptions) | SELinux (security) |
| **Runtime Change** | Requires semanage / recompile | Easy (edit file, reload) | AppArmor |
| **Container Support** | K8s integrated via seccomp | K8s integrated via profile | Tie |
| **Audit Sophistication** | Rich (user:role:type:level) | Simple (just actions) | SELinux |
| **Operational Overhead** | Higher (more tuning, audit denials) | Lower (simpler policies) | AppArmor |

**My Recommendation & Rationale:**

**For a new, Kubernetes-based microservices platform: AppArmor + seccomp layers**

Why:
1. **AppArmor policies are readable**: Path-based rules match how Kubernetes volumes are mounted
   ```
   /usr/bin/nginx r,
   /etc/nginx/** r,
   /var/log/nginx/** w,  # + owner == www-data
   /dev/stdin r,
   /dev/stdout w,
   /dev/stderr w,
   /proc/sys/net/core/somaxconn r,
   ```
   vs. SELinux's
   ```
   nginx_t domain
   type httpd_log_t;
   allow nginx_t httpd_log_t:file { write append getattr setattr };
   ```

2. **Dynamic testing easier**: AppArmor audit mode is simpler
   ```bash
   # AppArmor: edit profile, add "profile-name flags=(audit) {" reload, test
   # SELinux: semanage permissive -a type_t, disable later = more steps
   ```

3. **Container-native**: Docker/Kubernetes AppArmor integration is cleaner
   ```yaml
   securityContext:
     appArmorProfile:
       type: Localhost
       localhostProfile: "docker-nginx"
   ```

4. **Operational efficiency**: 
   - 80% of policy written via audit mode + automation
   - 20% hand-tuning exceptions
   - vs. SELinux: 30% automation, 70% hand-tuning

**When I'd Choose SELinux Instead:**

1. **Existing RHEL environment**: Leverage existing policies
2. **Extreme threat model**: Multi-level security (MLS) = compliance requirement
3. **Large team**: Complex RBAC via roles (user, sysadm_r, secadm_r)
4. **Regulatory requirement**: Government, military (SELinux has longer audit trail)

**Hybrid Approach (Recommended for Production):**

```
Layer 1: Network Policy (Kubernetes)
  └─ Restricts traffic between pods

Layer 2: AppArmor Profiles (Pod-level)
  └─ Restricts file access, capabilities

Layer 3: seccomp Profiles (Syscall-level)
  └─ Restricts process behavior

Result: Multiple layers; one weakness doesn't expose system
```

**Implementation Plan (AppArmor):**

```bash
# Phase 1: Generate profiles from container images
aa-logprof > /etc/apparmor.d/docker-nginx  # Audit mode suggestions

# Phase 2: Refine policies
cat > /etc/apparmor.d/docker-nginx <<EOF
#include <tunables/global>

profile docker-nginx flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  
  /etc/nginx/** r,
  /usr/share/nginx/** r,
  /var/log/nginx/** w,
  /var/cache/nginx/** rw,
  
  capability net_bind_service,
  capability setuid,
  capability setgid,
  
  /proc/sys/net/ipv4/ip_local_port_range r,
  /dev/shm r,
}
EOF

# Phase 3: Test in audit mode
apparmor_parser -r /etc/apparmor.d/docker-nginx

# Phase 4: Deploy to production
# Kubernetes pod spec:
securityContext:
  appArmorProfile:
    type: Localhost
    localhostProfile: "docker-nginx"
```

---

### Question 4: Design SSH Key Rotation Strategy for 100,000 Automation Users

**Question:**
Your organization has 100,000 automation service accounts (CI/CD, monitoring, config management), each with SSH keys stored in Vault. Audit shows keys haven't been rotated in 3 years. Design a key rotation strategy that minimizes downtime and operational risk.

**Expected Answer from Senior DevOps Engineer:**

**Key Insight**: Rotating 100K keys simultaneously is catastrophic. (Parallel timeout cascades, authentication storms.)

**Strategic Approach:**

**Phase 1: Assess Risk & Prioritize (1 week)**

```bash
# Categorize keys by risk
- Critical (prod database access): 500 keys → rotate first, ASAP
- High (prod web servers): 5K keys → rotate within 1 month
- Medium (staging, non-prod): 50K keys → rotate within 3 months
- Low (dev, CI systems): 44.5K keys → rotate within 6 months

# Assess key age & exposure
vault audit log | grep "ssh_key" | \
  awk -F',' '{print $3, $4}' | \
  sort | uniq -c | sort -rn  # Keys by creation date

# Identify keys in Git (compliance risk)
git log --all --source -S "BEGIN RSA PRIVATE KEY" | wc -l  # Leaked keys

# Count keys per user (identify overexposed users)
```

**Phase 2: Implement Certificate-Based Auth (Foundation for Rotation)**

Instead of rotating static keys, issue certificates with short TTL.

```bash
# Vault SSH secret engine setup
vault secrets enable ssh

vault write ssh/config/ca \
  generate_signing_key=true

vault write ssh/roles/prod-database \
  key_type=ca \
  name=prod-database \
  ttl=24h \
  max_ttl=720h \
  algorithms=rsa-sha2-256 \
  allow_user_certificates=true \
  allowed_users="automation,*" \
  valid_principals="db1,db2,db3" \
  ...

# Automation service requests certificate on demand
# vault write -f ssh/sign/prod-database \
#   username=automation \
#   ip_address=10.0.0.0/8 \
#   cert_type=user \
#   ttl=24h

# Server trusts CA; accepts all certificates
# /etc/ssh/sshd_config
TrustedUserCAKeys /etc/ssh/ca.pub
```

**Phase 3: Parallel Rotation in Waves (4 phases × 1 month)**

```bash
Timeline:
Week 1: Prepare (generate new certs, test)
Week 2-3: Critical accounts (500 keys)
Week 4-7: High-priority (5K keys)
Week 8-15: Medium (50K keys)
Week 16-26: Low priority (44.5K keys)

Each wave:
- Day 1: Generate new certificates in Vault
- Day 2: Deploy to 10% of accounts (canary)
- Day 3-5: Validate canary (monitoring, spot checks)
- Day 6-20: Roll out to remaining 90% (batches of 5K)
- Day 21: Retire old keys, update audit
```

**Canary Validation (Critical):**

```yaml
# Kubernetes canary job
apiVersion: batch/v1
kind: Job
metadata:
  name: ssh-key-rotation-canary
spec:
  template:
    spec:
      serviceAccountName: rotation-canary
      containers:
      - name: rotation
        image: rotation-tool:latest
        env:
        - name: VAULT_ADDR
          value: https://vault.internal:8200
        - name: VAULT_NAMESPACE
          value: automation
        - name: ROTATION_WAVE
          value: "critical"
        - name: DRY_RUN
          value: "false"
        volumeMounts:
        - name: rotation-script
          mountPath: /scripts
      volumes:
      - name: rotation-script
        configMap:
          name: rotation-script
      restartPolicy: Never

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rotation-script
data:
  rotate.sh: |
    #!/bin/bash
    VAULT_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    
    # Request new certificate
    NEW_CERT=$(vault write -format=json -f ssh/sign/$ROLE | \
      jq -r '.data.signed_key')
    
    # Deploy to canary servers
    for server in $(cat /tmp/canary-servers.txt); do
      ssh -i /tmp/new-cert $server "systemctl status" || {
        echo "Canary failed on $server!"
        exit 1
      }
    done
    
    # If canary passed, return success
    echo "✓ Canary rotation successful"
```

**Phase 4: Automation & Monitoring**

```bash
# Automated rotation loop (runs nightly)
/opt/rotation/rotate-ssh-keys.sh

# Script logic
1. Query Vault for keys older than threshold
2. Generate new certificates (24-hour TTL)
3. Deploy to servers in target cohort
4. Monitor SSH connection success rate
5. If success rate > 99%: retire old key
6. If success < 99%: alert, rollback

# Monitoring
- Prometheus metric: ssh_rotation_success_rate
- Alert: rotation_success_rate < 0.99 for 5min
- Grafana dashboard: rotation progress per wave

# Audit trail
- CloudTrail / Vault audit log: who rotated keys
- SIEM: authentication patterns before/after rotation
```

**Phase 5: Rollback Plan (If Things Go Wrong)**

```bash
# Immediate rollback: restore old key from Vault backup
# Vault stores historical versions
vault kv get -version=old ssh/automation/old-key | jq '.data.data'

# Deploy old key back to affected servers
ansible-playbook restore-old-keys.yml -i inventory-failed.ini

# Human validation: check which servers failed auth
ssh -vvv -i old-key server | grep "Authentications that can continue"

# Root cause analysis
- Was new key format incompatible?
- Did server restart before deploying cert?
- Was network unreachable during deployment?
```

**Success Metrics:**

```bash
# Before rotation
$ grep "FAILED.*ssh" /var/log/auth.log | wc -l
5,234 failed authentications (0.05% daily)

# During rotation (wave 1)
$ grep "FAILED.*ssh" /var/log/auth.log | wc -l
5,287 failed authentications (0.07% daily) ← ~0.02% delta acceptable

# After full rotation
$ grep "FAILED.*ssh" /var/log/auth.log | wc -l
4,891 failed authentications (0.05% daily) ← Back to baseline

# Reconciliation
$ vault list ssh/keys/rotated/2026-03-01 | wc -l
100,000 keys rotated (100% coverage)
```

---

### Question 5: What Happens When SELinux Context Mismatch Occurs? Troubleshoot Real Scenario

**Question:**
A Nginx container is deployed with a custom apparmor profile. After deployment, the container can't read configuration files, even though file permissions are 644 (world-readable). The error in the logs shows permission denied. Without running the container, how would you diagnose the issue using `ls -Z`, `ps -Z`, and audit logs?

**Expected Answer from Senior DevOps Engineer:**

(Note: This assumes SELinux system. For AppArmor, similar principles apply with `aa-status`, `aa-audit`.)

**Diagnostic Steps:**

```bash
# Step 1: Check file context
ls -Z /etc/nginx/nginx.conf
# Output: system_u:object_r:default_t:s0 /etc/nginx/nginx.conf

# Step 2: Check process context
ps -eZ | grep nginx
# Output: system_u:system_r:nginx_t:s0 ... /usr/sbin/nginx

# Step 3: Identify mismatch
# nginx_t process trying to access default_t files
# Compare with expected: httpd_log_t or httpd_config_t

# Step 4: Check audit logs
ausearch -m avc -ts recent 2>/dev/null | tail -20
# AVC: denied { read } for pid=1234 comm="nginx"
#   scontext=system_u:system_r:nginx_t:s0
#   tcontext=system_u:object_r:default_t:s0
#   tclass=file
```

**Root Cause:**
```
nginx_t domain doesn't have permission to read default_t type
Because: /etc/nginx labeled as default_t (generic type)
Should be: labeled as httpd_config_t (nginx-specific type)
```

**Fix:**
```bash
# Relabel file to correct context
semanage fcontext -a -t httpd_config_t "/etc/nginx(/.*)?"
restorecon -Rv /etc/nginx

# Verify
ls -Z /etc/nginx/nginx.conf
# Output: system_u:object_r:httpd_config_t:s0 /etc/nginx/nginx.conf

# Restart nginx
systemctl restart nginx

# Verify no new denials
ausearch -m avc -ts recent | grep nginx
# (should be empty)
```

---

### Question 6: cgroups v1 vs. v2 - Migration Implications & Decision Making

**Question:**
Your Kubernetes cluster currently runs cgroups v1. The platform team is considering migrating to cgroups v2. What are the implications? What would you analyze to make a go/no-go decision?

**Expected Answer from Senior DevOps Engineer:**

**Comparison:**

| Aspect | cgroups v1 | cgroups v2 | Impact |
|--------|-----------|-----------|--------|
| **Hierarchy** | Per-controller | Unified | v2 is cleaner; easier to reason about limits |
| **Controllers** | Separate (memory, cpu, blkio) | Unified | v2 simpler config; less conflicts |
| **Memory Account.** | Page cache not counted | Counted in memory.current | v2 is stricter; pods may hit limits unexpectedly |
| **Delegation** | Systemd manages top-level | Kubelet can delegate | Kubernetes gains fine-grained control |
| **Performance** | Known; widely tested | Newer; fewer production deployments | v1 safer; v2 better long-term |

**Key Impact - Memory Accounting:**

```
cgroups v1: memory.usage_in_bytes = RSS + (page cache for volumes controlled by cgroup)
cgroups v2: memory.current = RSS + page cache + swap (if enabled)

Example: Pod requests 2GB, uses 1.5GB RSS
cgroups v1: memory.usage_in_bytes = 1.5GB (under limit)
cgroups v2: memory.current = 1.5GB + 500MB page cache = 2.0GB (at limit!)

Implication: Pods may start hitting OOM kills when switching to v2
If not accounted for, could cause production incident during migration
```

**Migration Decision Checklist:**

```bash
[ ] Do we have budget for testing (staging environment needed)?
[ ] Can we tolerate 1-2 weeks of potential issues during migration?
[ ] Are our applications page-cache heavy (databases, file servers)?
    └─ If YES: Plan for memory limit increases (v2 is stricter)

[ ] Do we use device cgroups (block device I/O limits)?
    └─ If YES: Check if all features work in v2 (some are still WIP in kernel)

[ ] Is our kernel >= 5.2?
    └─ If NO: Update kernel first (cgroups v2 support older in 4.x)

[ ] Can we run migration in time windows (off-peak)?
    └─ Migration requires node drain/reboot; plan downtime

[ ] Do we have metrics baseline for current memory usage?
    └─ Before migration, establish baseline; track post-migration changes

[ ] Is our Kubernetes version >= 1.25?
    └─ cigroups v2 GA in 1.25; older versions have issues
```

**Migration Plan (if GO decision):**

```bash
# Phase 1: Prepare (1 week)
- Baseline memory usage per pod
- Identify memory-hungry workloads
- Plan memory limit increases (expect ~5-10% increase)

# Phase 2: Test (staging environment)
- Boot staging Kubernetes on cgroups v2
- Deploy real workloads
- Monitor for OOM kills, performance changes
- Measure memory.pressure changes

# Phase 3: Canary (1 prod node)
- Cordon node
- Drain pods
- Reboot with cgroups v2 enabled
- Monitor metrics for 24 hours
- If stable: proceed to Phase 4

# Phase 4: Rolling migration (prod nodes)
- Migrate 10% of nodes per day
- Monitor memory usage, OOM events
- Auto-rollback if OOM rate increases > 2x

# Post-migration
- Tune memory limits based on observed usage
- Monitor long-term trends
- Retire v1 support (disable in kubelet)
```

**Monitoring Setup (Critical):**

```yaml
# Prometheus alerts for cgroups v2 migration
groups:
- name: cgroups-migration
  rules:
  - alert: UnexpectedOOMKillsPost-Migration
    expr: |
      increase(container_oom_kills_total[5m]) > 2
      and on(namespace) kube_node_labels{cgroup_version="v2"}
    for: 5m
    labels:
      severity: critical

  - alert: MemoryPressureIncreasePost-Migration
    expr: |
      kube_node_memory_pressure{condition="True"}
      and on(node) kube_node_labels{cgroup_version="v2"}
    for: 10m
    labels:
      severity: warning

  - alert: PodLatencyIncreasePost-Migration
    expr: |
      rate(http_request_duration_seconds_sum[5m]) /
      rate(http_request_duration_seconds_count[5m]) > baseline * 1.2
      and on(pod) kube_pod_labels{cgroup_version="v2"}
    for: 15m
    labels:
      severity: warning
```

---

### Question 7: How Would You Detect & Prevent Privilege Escalation via sudoers Misconfiguration?

**Question:**
Security audit found sudoers entries like `user ALL=(ALL) NOPASSWD: /usr/bin/systemctl`. A developer uses this to execute `/usr/bin/systemctl` → run arbitrary commands in the systemctl service context. Design preventive controls & detection strategy.

**Expected Answer from Senior DevOps Engineer:**

**Vulnerability: Wildcard In systemctl Invocation**

```bash
# Misconfigured sudoers
user1 ALL=(root) NOPASSWD: /usr/bin/systemctl

# Exploit
sudo /usr/bin/systemctl --user-unit=/tmp/malicious.service start nginx
# Because systemctl can load units from arbitrary paths!

# Privilege escalation chain
1. sudo /usr/bin/systemctl ... → User runs as root
2. Malicious unit file → Arbitrary code executed as root
3. Attacker gains persistence
```

**Prevention Strategy:**

**1. Restrict sudoers to Specific Commands**

```bash
# BAD
user1 ALL=(root) NOPASSWD: /usr/bin/systemctl

# GOOD
user1 ALL=(root) NOPASSWD: /usr/bin/systemctl restart nginx
user1 ALL=(root) NOPASSWD: /usr/bin/systemctl stop postgresql
# Explicitly list each command

# BETTER: Use sudo wrapper script that validates inputs
user1 ALL=(root) NOPASSWD: /usr/local/bin/restart-nginx.sh

# /usr/local/bin/restart-nginx.sh
#!/bin/bash
set -euo pipefail
# Whitelist: only allow restart nginx service
if [[ "$1" != "nginx" ]]; then
  echo "Error: Only nginx service restart allowed"
  exit 1
fi
/usr/bin/systemctl restart nginx
```

**2. Audit sudoers Configuration**

```bash
# Script to detect dangerous sudoers patterns
#!/bin/bash
audit_sudoers() {
  grep -h -r "ALL=(ALL)" /etc/sudoers /etc/sudoers.d/ | \
    grep -v "^#" | \
    while read line; do
      if echo "$line" | grep -qE "ALL\)|NOPASSWD.*ALL"; then
        echo "⚠ WARNING: Overly permissive sudoers: $line"
      fi
    done
  
  # Check for dangerous command patterns
  grep -h "systemctl\|bash\|sh\|perl\|python" /etc/sudoers /etc/sudoers.d/ | \
    grep -v "^#" | \
    while read line; do
      if grep -q "NO.*PASSWD" <<< "$line"; then
        echo "🔴 CRITICAL: Command without password auth: $line"
      fi
    done
}
audit_sudoers
```

**3. Detection via auditd**

```bash
# /etc/audit/rules.d/sudoers.rules
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes

# Monitor actual sudo command execution
-a always,exit -F arch=b64 -S execve -F uid=0 -k root_command_execution

# Alert if user runs unexpected commands via sudo
# Baseline: alice typically runs 'systemctl restart nginx'
# Alert if alice runs: 'systemctl start arbitrary-service'

auditctl -w /usr/bin/systemctl -p x -k systemctl_usage
ausearch -k systemctl_usage | grep "name=systemctl" | \
  while read line; do
    USER=$(echo "$line" | grep -o "user=\w*" | cut -d= -f2)
    CMD=$(echo "$line" | grep -o "exe=\"[^\"]*\"" | cut -d= -f2)
    echo "ALERT: User $USER executed $CMD"
  done
```

**4. Restrict Dangerous Binaries**

```bash
# Systemctl-specific prevention
# Make critical directories immutable
# Prevent sudo from running certain binaries

# AppArmor profile for systemctl
profile systemctl {
  # Allow only reading system units (/etc/systemd/system)
  /etc/systemd/system/*.service r,
  
  # Deny loading units from user-controlled paths
  deny /home/** r,
  deny /tmp/** r,
  deny /var/tmp/** r,
  
  # Only allow writing to log
  /var/log/systemctl.log w,
}

# Or use capabilities instead of setuid
# Remove setuid from systemctl; grant specific capabilities
setcap cap_sys_admin,cap_chown+ep /usr/bin/systemctl
```

**5. Monitoring & Alerting**

```bash
# SIEM rule: detect sudo command execution anomalies
{
  "trigger": "alert",
  "source": "auditd",
  "condition": {
    "field": "auid",
    "operator": "is",
    "value": "user1",
    "and": {
      "field": "exe",
      "operator": "contains",
      "value": "systemctl"
    },
    "and": {
      "field": "args",
      "operator": "not_equals",
      "value": "restart nginx"  # Only expected command
    }
  },
  "action": "alert + block"
}
```

**6. Runtime Enforcement (seccomp + AppArmor)**

```bash
# Systemctl seccomp profile
# Block dangerous syscalls if someone escapes RBAC

{
  "defaultAction": "SCMP_ACT_ALLOW",
  "defaultErrnoRet": 1,
  "rules": [
    {
      "names": ["ptrace", "process_vm_readv", "process_vm_writev"],
      "action": "SCMP_ACT_ERRNO"  # Block process tracing
    },
    {
      "names": ["execve"],
      "action": "SCMP_ACT_ERRNO",
      "args": [
        {
          "index": 0,
          "value": "/usr/bin/systemctl",
          "valueTwo": 0,
          "op": "SCMP_CMP_NE"  # Block if trying to execve anything != /usr/bin/systemctl
        }
      ]
    }
  ]
}
```

---

### Question 8: Kubernetes Resource Limits Misconfiguration - Real-World Troubleshooting

**Question:**
A microservice is deployed with `resources: { requests: { memory: 2Gi }, limits: { memory: 2Gi } }`. During peak load, pods are killed with OOMKilled. Heap monitoring shows only 1.5GB used. Why is the pod OOM killed if only using 1.5GB of a 2GB limit?

**Expected Answer from Senior DevOps Engineer:**

**Root Cause: Memory Limit ≠ Heap Memory**

Memory limit applies to **all memory used by the pod**, not just application heap:

```
Pod Memory Composition:
├─ Application Heap (what you see in monitoring)       ← 1.5GB
├─ Application Stack (runtime allocations)             ← 50MB
├─ Container runtime overhead (docker/containerd)      ← 100MB
├─ Kubernetes probe overhead (liveness/readiness)      ← 50MB
├─ Shared libraries & file mmaps                       ← 200MB
└─ Page cache (from log writes, temp files)            ← 100MB
   ────────────────────────────────────────────────────
   TOTAL: ~2.0GB (at limit!)
```

**Diagnosis Steps:**

```bash
# Step 1: Check actual memory usage (not just heap)
kubectl exec myapp-pod -- ps aux | grep java
# Output: Resident Set Size (RSS) includes all the above

# Step 2: Deep-dive into memory allocation
kubectl debug pod/myapp-pod -it --image=ubuntu:22.04
# Inside debug container (shares pod memory):
cat /proc/1/status | grep VmRSS
cat /proc/1/status | grep VmPeak

# Step 3: Check cgroup memory stats (most accurate)
cat /sys/fs/cgroup/memory/kubepods/pod-id/memory.stat | grep -E "rss|page_cache|swap"
# Shows:
# total_rss = 1510MB        (heap + stacks)
# total_cache = 350MB       (page cache from logs)
# total_swap = 140MB        (swapped pages, if swap enabled)
# ──────────────
# total_active = 2000MB (at limit!)

# Step 4: Check for memory.pressure (PSI)
cat /proc/pressure/memory
# some avg10=42.34 avg60=38.12 avg300=32.45  (High memory pressure!)
```

**Why OOM Killer Triggered:**

```
When memory.current >= memory.max:
├─ Kernel tries to reclaim memory
│  ├─ Drop page cache (fast)
│  ├─ Reclaim inactive pages
│  └─ If that's not enough...
│
└─ OOM killer picks process with highest oom_score
   Process killed = Container restart

Why OOM even with "only" 1.5GB heap?
= Because total pod memory (not just heap) is at limit
= Page cache + logging I/O + temp allocations push total over 2GB
```

**Fix Strategies:**

**Strategy 1: Increase Memory Limit**

```yaml
resources:
  requests:
    memory: 2Gi
  limits:
    memory: 3Gi  # +50% buffer for non-heap overhead
```

(Not ideal; wastes cluster capacity if you have many pods)

**Strategy 2: Reduce Application Overhead**

```bash
# a) Reduce logging verbosity
# Logging writes = page cache growth
# If app logs 1GB/hour: tune log level to WARNING (not DEBUG)

# b) Disable memory-intensive monitoring
# Some APM agents hold large in-memory buffers
# Review JVM heap settings
JAVA_OPTS="-Xms1G -Xmx1.2G"  # Smaller max heap = less GC pressure

# c) Clear temp files in init container
init_containers:
- name: cleanup
  image: busybox
  command:
  - sh
  - -c
  - rm -rf /tmp/* /var/tmp/*

# d) Disable swap
sysctl -w vm.swappiness=0
```

**Strategy 3: Implement Graceful Shutdown**

```bash
# Instead of OOM killer (random process killed), handle memory pressure signals
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3  # Restart after 3 failed health checks

# Application detects high memory usage; returns 500 from /health
# Kubernetes sees unhealthy probe → graceful termination
# vs OOM killer → abrupt crash
```

**Strategy 4: Vertical Pod Autoscaler (Recommendation)**

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "auto"  # Auto-update memory limits

  # VPA learns actual usage; recommends appropriate limits
  # Result: myapp-pod gets limits = peak usage + buffer
```

---

### Question 9: Kernel Parameter Trade-offs - TCP Window Scaling Example

**Question:**
You want to optimize network throughput between microservices (1Gbps network, 1ms latency). Should you tune `tcp_window_scaling`, `tcp_rmem`, `tcp_wmem`? What's the trade-off? How would you validate the change?

**Expected Answer from Senior DevOps Engineer:**

**BDP Calculation (Foundation):**

```
BDP (Bandwidth-Delay Product) = Bandwidth × Latency
Example: 1 Gbps × 1ms = 1 Mbps = 125 KB

For full link utilization:
Socket buffer size >=  2 × BDP = 250 KB
```

**Current Default Buffers (Often Too Small):**

```bash
sysctl net.ipv4.tcp_rmem
# Output: 4096 131072 6291456  (4KB min, 128KB default, 6MB max)

# Problem: Default = 128KB < BDP * 2
# Result: TCP window scales up, but buffering becomes bottleneck
# Throughput limited to: ~128KB / 1ms = 128 Mbps (not 1000 Mbps!)
```

**Tuning Strategy:**

```bash
# Recommended for 1Gbps, 1ms latency:
sysctl -w net.ipv4.tcp_rmem="4096 262144 268435456"     # 256KB default, 256MB max
sysctl -w net.ipv4.tcp_wmem="4096 262144 268435456"
sysctl -w net.ipv4.tcp_window_scaling=1               # Enable (usually on)

# Better: Let kernel auto-tune
sysctl -w net.ipv4.tcp_moderate_rcvbuf=0    # Disable auto-tuning throttle
sysctl -w net.ipv4.tcp_no_metrics_save=1    # Save per-connection metrics

# Monitor window scaling
netstat -s | grep "TCPHPHits"  # Shows if window scaling is active
```

**Trade-offs:**

| Change | Benefit | Cost |
|--------|---------|------|
| **Increase tcp_rmem max** | Allows larger RX buffers → more throughput | Memory per connection; memory fragmentation |
| **Increase tcp_wmem max** | Allows larger TX buffers → less CPU context switches | Memory per connection; latency spikes on flush |
| **Enable TCP window scaling** | 64KB window limit removed; large windows possible | Older TCPs might not handle scaling | 

**Unexpected Trade-offs:**

```bash
# Trade-off 1: Memory ↔ Throughput
# Increase tcp_rmem to 100MB → throughput improves
# But if you have 10K connections → 1TB memory pool needed!
# Also: Garbage collection becomes expensive

# Trade-off 2: Throughput ↔ Latency
# Large send buffers → app can buffer 100MB before blocking
# Result: p50 latency improves (app doesn't wait for network)
# But p99 latency spikes (when network flush occurs)

# Trade-off 3: Auto-tuning ↔ Predictability
# Kernel auto-scaling buffers = best throughput
# But: Makes performance unpredictable (varies per connection)

# This is why you MEASURE before deploying!
```

**Validation Plan:**

```bash
# Phase 1: Baseline
iperf3 -c server -t 60 -b 1G -P 16               # 16 parallel streams
# Expected: ~500-600 Mbps (without tuning)
# Record: Latency p50/p99, CPU usage, memory growth

# Phase 2: Tune & Test
sysctl -w net.ipv4.tcp_rmem="4096 262144 268435456"
sysctl -w net.ipv4.tcp_wmem="4096 262144 268435456"

iperf3 -c server -t 60 -b 1G -P 16
# Expected: ~900-950 Mbps (with tuning)
# Record: Latency p50/P99, CPU usage, memory growth

# Diff baseline vs. tuned
# Success: Throughput +50%, latency <3% regression
# Fail: If p99 latency increases >10% → revert

# Phase 3: Production Validation
# Monitor real app metrics during tuning
# Watch for: 
# - Connection reset rate (broken window scaling on old clients)
# - Memory growth rate (each conn = more buffering)
# - p99 latency (might spike initially then stabilize)

# Phase 4: Long-term Monitoring
# Run for 24h+ to catch edge cases
# - Do any connections hang?
# - Is memory leak (buffers not returned)?
# - Does GC pause increase (more memory pressure)?

# Example: Monitor script
while true; do
  THROUGHPUT=$(iperf3 -c server -t 10 | grep sender | awk '{print $7}')
  P99=$(ss -s | grep TCP | awk '{print $(NF-1)}')
  MEMORY=$(free | awk '/Mem/{print $3/1024/1024}')  # GB
  echo "$(date): Throughput=$THROUGHPUT Mbps, P99=$P99, Memory=$MEMORY GB"
  sleep 300  # Every 5 minutes
done
```

**Decision Framework:**

```
DO tune if:
✓ You measured baseline (have data)
✓ Tuning gives >20% throughput improvement
✓ Impact on latency p99 < 5%
✓ No memory pressure observed
✓ Production deployment has monitoring for regression

DON'T tune if:
✗ Application already saturating (bottleneck is elsewhere)
✗ No measurement (flying blind)
✗ Latency-sensitive: even 1% p99 degradation = bad
✗ Memory-constrained
```

---

### Question 10: Describe a Time You Made a Wrong Kernel Tuning Decision. What Did You Learn?

**Question:**
Tell me about a production incident caused by kernel tuning. What went wrong? How did you fix it? What would you do differently?

**Expected Answer from Senior DevOps Engineer:**

(This is a behavioral question; the "right" answer shows maturity & learning from failure.)

**Example Response:**

> "Early in my career at [Company], we had a Cassandra database cluster hitting high latency during peak traffic. P99 latency went from 50ms to 500ms unpredictably. 
>
> Immediately, I assumed it was a kernel parameter. I blindly set:
> ```
> vm.swappiness = 0
> net.core.rmem_max = 256MB
> kernel.sched_latency_ns = 10000  # Aggressive scheduling
> ```
> in production without testing. The change made things **worse**.
>
> What happened:
> - sched_latency_ns too low → context switches every 10ms (excessive overhead)
> - rmem_max jump → TCP connection creation failed (out of memory on small VM)
> - swappiness = 0 without reserve → OOM killer triggered (killed Cassandra)
>
> Cluster went down for 15 minutes. I then had to emergency revert changes.
>
> **Root Cause Analysis (after reverting):**
> Actual issue wasn't kernel tuning at all. Using monitoring, I found:
> - GC pause in Cassandra (60ms pauses every 2 minutes)
> - Network buffer bloat (packet retransmissions)
> - Disk I/O contention (flush storms)
>
> The kernel was fine; the problem was application-level.
>
> **What I Learned:**
> 1. Measure baseline BEFORE tuning (I didn't have metrics)
> 2. Never tune multiple parameters simultaneously (cause-effect unclear)
> 3. Test in staging (I skipped this; thought 5-minute impact testing was enough)
> 4. Kernel defaults are conservative but safe (blindly changing them is risky)
> 5. Fix application bugs first; tune kernel only if measurement proves it's a bottleneck
>
> **What I Do Now:**
> - Capture 1-week baseline of all metrics (CPU, memory, network, disk I/O, application latency)
> - Use APM tools (Datadog, New Relic) to correlate metrics
> - Test tuning in staging with same workload for 24+ hours
> - Tune ONE parameter at a time; measure impact
> - Have automated rollback ready (if metrics degrade, revert change within 5 minutes)
> - Document the rationale (why was this parameter chosen? What was the bottleneck?)
>
> For that Cassandra incident, the real fix was:
> - Tune Cassandra GC (from G1GC to ZGC)
> - Add network buffering on load balancer
> - Implement connection pooling (reduce connection thrashing)
> 
> Once those were fixed, cluster latency dropped to baseline without kernel tuning.
>
> This reinforced: kernel tuning is the last resort, not the first response to performance issues."

---

## Key Takeaways

✓ **Security hardening** is layered defense: user management + file permissions + sudo + SELinux + firewall + auditing

✓ **Resource controls** prevent cascading failures through cgroups + namespaces + ulimit + monitoring

✓ **Kernel tuning** requires workload understanding and baseline testing before production deployment

✓ **Remote access** at scale uses bastion hosts + certificate-based auth + centralized audit logging

✓ **Defense-in-depth** means no single point of failure; every layer must be justified and maintained

✓ **Senior DevOps engineers** prioritize measurement, automation, and learning from failures over quick fixes

---

## Key Takeaways

✓ **Security hardening** is layered defense: user management + file permissions + sudo + SELinux + firewall + auditing

✓ **Resource controls** prevent cascading failures through cgroups + namespaces + ulimit + monitoring

✓ **Kernel tuning** requires workload understanding and baseline testing before production deployment

✓ **Remote access** at scale uses bastion hosts + certificate-based auth + centralized audit logging

✓ **Defense-in-depth** means no single point of failure; every layer must be justified and maintained

---

**Next Steps:** Continue to full deep-dive sections for each subtopic with configuration examples, troubleshooting, and production deployment patterns.
