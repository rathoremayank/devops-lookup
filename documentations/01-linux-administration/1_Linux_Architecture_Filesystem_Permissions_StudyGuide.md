# Linux Administration: Architecture, Filesystem & Permissions
## Senior DevOps Study Guide

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [DevOps Principles](#devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)
3. [Linux Architecture & Boot Process](#linux-architecture--boot-process)
4. [Linux Filesystem Hierarchy & Storage](#linux-filesystem-hierarchy--storage)
5. [Users, Groups & Permissions](#users-groups--permissions)
6. [Hands-on Scenarios](#hands-on-scenarios)
7. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Linux Administration at the system level is the foundation of modern DevOps infrastructure. This study guide covers three critical pillars:

1. **Linux Architecture & Boot Process**: Understanding the kernel, boot sequence, and system initialization mechanisms that enable reliable infrastructure automation
2. **Filesystem Hierarchy & Storage**: Managing data persistence, performance optimization, and storage architecture across production environments
3. **Users, Groups & Permissions**: Implementing security boundaries, access control, and privilege management essential for multi-tenant infrastructure

These topics form the backbone of reliable, secure, and efficient infrastructure operations in enterprise DevOps environments.

### Why It Matters in Modern DevOps Platforms

**Infrastructure Reliability**: Understanding boot processes and system initialization is critical for:
- Troubleshooting infrastructure failures in cloud environments
- Implementing custom recovery procedures in EC2, VMs, or Kubernetes nodes
- Designing resilient infrastructure that can recover from failures automatically

**Performance & Optimization**: Filesystem knowledge directly impacts:
- Container performance in Kubernetes/Docker (inode exhaustion, mount strategies)
- Storage optimization in cloud environments (EBS volumes, persistent storage)
- Database performance (fsync behavior, barrier settings, extent allocation)

**Security Hardening**: Permission and access control models are fundamental for:
- Implementing least-privilege access in containers and VMs
- Securing CI/CD pipelines and automation tools
- Preventing privilege escalation attacks and lateral movement

**Production Troubleshooting**: Every production incident investigation requires:
- Diagnose filesystem issues (df/du utilities, inode problems)
- Analyze permission-related failures
- Understanding boot failures and system state recovery

### Real-World Production Use Cases

**Case 1: Kubernetes Node Failures**
- Nodes become NotReady due to inode exhaustion from container logs
- Recovery requires understanding filesystem limits, mount options, and storage management
- Implementation: Configure proper log rotation, storage quotas, and monitoring

**Case 2: Container Permission Failures**
- Containers fail to start due to permission mismatch between host and container
- Applications cannot write to volumes due to UID/GID mapping issues
- Solution requires deep understanding of Linux permission model and container isolation

**Case 3: Database Performance Degradation**
- PostgreSQL/MySQL experiencing slowdown on large EBS volumes
- Root cause: ext4 filesystem allocated blocks suboptimally
- Resolution: Understanding inode allocation, extent fragmentation, and mount options

**Case 4: CI/CD Pipeline Security**
- Jenkins agents or GitLab runners consuming excessive disk space
- Privilege escalation vulnerability in build environment
- Fix requires proper filesystem management and sudoers configuration

**Case 5: Disaster Recovery**
- Need to boot system in rescue mode, mount damaged filesystems, and recover data
- Requires understanding boot process, initramfs, emergency targets, and mount utilities
- Validation: Implement disaster recovery testing with proper boot sequence understanding

### Where It Typically Appears in Cloud Architecture

**In Compute Layers**:
- EC2 instances, VMs, and bare metal servers require OS-level administration
- Kubernetes nodes run Linux kernel and require proper configuration
- Container runtimes (Docker, containerd) leverage Linux namespaces and cgroups

**In Storage Architecture**:
- EBS volumes formatted with ext4/xfs require lifecycle management
- Persistent volumes in Kubernetes depend on filesystem performance characteristics
- NFS mounts rely on proper permission models and ACLs

**In Security Architecture**:
- IAM policies backed by OS-level permission models
- Multi-tenancy implemented through user/group isolation
- Audit logging depends on filesystem permissions and ownership tracking

**In Infrastructure Automation**:
- Terraform provisioning scripts must consider bootloader configuration
- Ansible playbooks must handle permission changes and user management
- Container images require proper filesystem layering and permission inheritance

---

## Foundational Concepts

### Key Terminology

#### Core OS Concepts
- **Kernel**: Core of Linux OS that manages hardware resources, processes, memory, and filesystems. Acts as the intermediary between applications and hardware.
- **User Space**: Where user applications run, isolated from kernel space. Applications cannot directly access hardware; they request services via syscalls.
- **System Calls (Syscalls)**: Interface between user space and kernel space. Examples: `open()`, `read()`, `write()`, `execve()`, `fork()`
- **Process**: Running instance of a program with its own memory space, file descriptors, and execution context.
- **Daemon**: Background process that runs without a controlling terminal, typically started by init system.

#### Boot & Initialization
- **BIOS/UEFI**: Firmware that initializes hardware and loads bootloader before kernel execution
- **Bootloader**: Program (GRUB, LILO) that loads kernel into memory and passes control to it
- **initramfs**: Temporary filesystem in memory loaded before real root filesystem; provides drivers and initialization tools
- **Systemd**: Modern init system managing service startup, dependencies, and system state (replaces SysV init)
- **Targets (Systemd)**: Equivalent to runlevels; define system states (multi-user.target, graphical.target, rescue.target)
- **Runlevels**: Legacy (SysV) system states (0=halt, 1=single-user, 3=multi-user, 5=graphical, 6=reboot)

#### Filesystem Concepts
- **Inode**: Data structure containing metadata about a file (permissions, size, timestamps, owner, block pointers)
- **Block**: Fixed-size unit of data storage on disk (typically 4KB)
- **Block Device**: Device file representing storage media (e.g., /dev/sda, /dev/nvme0n1)
- **Mount Point**: Directory where a filesystem is attached to the directory tree
- **Filesystem Hierarchy Standard (FHS)**: Defines directory structure and purpose of Linux/Unix systems

#### Permission & Access Control
- **User ID (UID)**: Numeric identifier for a user; UID 0 is root
- **Group ID (GID)**: Numeric identifier for a group; groups contain multiple users
- **Permission Bits**: Read (r/4), Write (w/2), Execute (x/1) for owner, group, others
- **Special Bits**: SetUID, SetGID, Sticky bit for special permission behavior
- **ACL (Access Control List)**: Fine-grained permission control beyond basic user/group/other model
- **Sudoers**: Configuration file defining which users can run commands as root or other users without password

### Architecture Fundamentals

#### Linux Kernel Architecture Layers

```
┌─────────────────────────────────────────┐
│        User Space Applications          │
│  (Web servers, databases, services)     │
└────────────────────────────────────────┘
                    ↓ (syscalls)
┌─────────────────────────────────────────┐
│           System Call Interface         │
│  (Standardized kernel API)              │
└─────────────────────────────────────────┘
            ↓ (internal calls)
┌─────────────────────────────────────────┐
│         Kernel Core Subsystems          │
├─────────────────────────────────────────┤
│ • Process Management (scheduler)        │
│ • Memory Management (VM, page tables)   │
│ • Filesystem (VFS, inode cache)         │
│ • Device Management (I/O, drivers)      │
│ • Network Stack (TCP/IP, protocols)     │
│ • Inter-Process Communication (IPC)     │
└─────────────────────────────────────────┘
                    ↓ (HAL)
┌─────────────────────────────────────────┐
│      Hardware Abstraction Layer         │
│  (Device drivers, bus controllers)      │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│         Physical Hardware               │
│  (CPU, RAM, Disk, Network, etc.)        │
└─────────────────────────────────────────┘
```

#### Kernel vs User Space Security Boundary

| Aspect | Kernel Space | User Space |
|--------|--------------|------------|
| **Memory Access** | Direct access to all memory | Protected memory isolation |
| **I/O Operations** | Direct device I/O | Via syscalls or privileged operations |
| **CPU Privilege Level** | Ring 0 (most privileged) | Ring 3 (least privileged) |
| **Execution Context** | Synchronous, interrupts enabled | Asynchronous, signal-based |
| **Recoverable** | Kernel panic if crashed | Process terminated if crashed |
| **Overhead** | No context switch required | Context switch required for syscalls |

**DevOps Implication**: Understanding this boundary is critical for troubleshooting permission errors, identifying privilege escalation vulnerabilities, and designing secure multi-tenant systems.

#### Boot Process Flow

```
BIOS/UEFI
    ↓
Hardware initialization (bus scanning, memory detection)
    ↓
Bootloader (GRUB) loads kernel into memory
    ↓
Kernel decompresses and initializes
    ↓
initramfs loaded into RAM (provides early drivers)
    ↓
Root filesystem mounted (real /dev/sda, etc.)
    ↓
init system starts (PID 1) - typically systemd
    ↓
systemd reads unit files and starts services/targets
    ↓
System enters target state (multi-user, graphical, etc.)
```

#### Filesystem Hierarchy Model

```
/
├── /bin           → Essential user commands (ls, cp, mv)
├── /sbin          → System administration commands (fsck, reboot)
├── /etc           → Configuration files
├── /home          → User home directories
├── /root          → Root user home
├── /lib/modules   → Kernel modules
├── /var           → Variable data (logs, caches, temp files)
├── /tmp           → Temporary files (cleared on reboot)
├── /dev           → Device files
├── /proc          → Kernel interface (process info, hardware)
├── /sys           → Device and kernel subsystems
├── /usr           → User programs and libraries
├── /boot          → Kernel and bootloader files
└── /mnt, /media   → Temporary mount points
```

### DevOps Principles

#### 1. Infrastructure as Code (IaC) Alignment
- **Principle**: System state should be declaratively defined and reproducible
- **Application**: Automated user/group provisioning, filesystem configuration as code
- **In Practice**: Ansible playbooks managing permissions, Terraform provisioning servers with proper mount options

#### 2. Least Privilege Access
- **Principle**: Every user/process should have minimum necessary permissions
- **Application**: Run services as dedicated non-root users, use sudoers for admin tasks
- **In Practice**: Container security (drop capabilities), CI/CD agent limitations, database user permissions

#### 3. Security Observability
- **Principle**: All security-relevant events must be auditable
- **Application**: Audit logs for permission changes, file access tracking
- **In Practice**: Linux audit daemon (auditd), SELinux/AppArmor logging, filesystem integrity monitoring

#### 4. Immutability Where Possible
- **Principle**: Reduce configuration drift through immutable infrastructure
- **Application**: Bake permissions and users into container images, use read-only mount options
- **In Practice**: Container layers with fixed permissions, golden images with pre-configured users

#### 5. Graceful Degradation
- **Principle**: System should remain functional during partial failures
- **Application**: Proper filesystem error handling (fsck), boot recovery procedures, ACL fallbacks
- **In Practice**: Emergency targets in boot sequence, filesystem journaling for crash recovery

### Best Practices

#### Boot Process Best Practices
1. **Monitor Boot Times**: Slow boots indicate kernel issues, module problems, or service dependencies
   - Use `systemd-analyze` to identify slow startup
   - Implement boot testing in CI/CD

2. **Maintain Clean Bootloader Configuration**
   - Remove obsolete kernel versions (manage disk space)
   - Document custom kernel parameters for disaster recovery
   - Test recovery procedures (boot into emergency targets)

3. **Manage initramfs Carefully**
   - Include necessary drivers (storage, network, filesystem)
   - Regenerate after kernel or driver updates
   - Test initramfs in offline environments

4. **Implement Proper Target Dependencies**
   - Understand service startup order (systemd unit dependencies)
   - Implement health checks for critical services
   - Use `After=` and `Requires=` directives correctly

#### Filesystem Management Best Practices
1. **Capacity Planning**
   - Monitor inode usage as rigorously as block usage
   - Plan for log growth, cache expansion, temporary files
   - Implement quotas for multi-tenant systems

2. **Performance Optimization**
   - Choose filesystem based on workload (ext4 for general, xfs for large files, btrfs for snapshots)
   - Configure mount options for performance (noatime, data=writeback for databases)
   - Use separate filesystems for /home, /var, /tmp for stability

3. **Disaster Recovery**
   - Implement filesystem snapshots (LVM, btrfs snapshots)
   - Maintain filesystem integrity checks (fsck, xfs_repair procedures)
   - Document recovery procedures and test regularly

4. **Container/Kubernetes Integration**
   - Understand overlay filesystem layers (overlayfs)
   - Manage persistent storage lifecycle
   - Implement storage quotas in Kubernetes namespaces

#### Permission Management Best Practices
1. **User/Group Strategy**
   - Create dedicated non-root users for services
   - Use system users (UID < 1000) for daemons
   - Avoid sharing accounts between different services

2. **Sudoers Configuration**
   - Use sudoers groups instead of individual entries
   - Implement command restrictions with specific flags
   - Log sudo usage for audit trails
   - Example:
     ```
     %devops_admins ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nginx
     %developers ALL=(ALL) NOPASSWD: /bin/systemctl status *
     ```

3. **ACL Usage**
   - Use ACLs only when standard permissions insufficient
   - Document ACL rationale (future maintainers)
   - Regularly audit ACL inheritance

4. **Security Monitoring**
   - Track UID/GID changes
   - Alert on sudo usage
   - Monitor permission changes (airlied, auditd)
   - Implement filesystem integrity monitoring (AIDE, Tripwire)

### Common Misunderstandings

#### Misunderstanding 1: "BIOS/UEFI is only for old servers"
**Reality**: UEFI is mandatory for modern secure boot, BIOS is legacy. Misunderstanding implications:
- UEFI requires Secure Boot configuration for IPMI/KVM systems
- Different partition layouts required (GPT vs MBR)
- Modern cloud providers (AWS, Azure) handle this abstraction, but bare metal requires knowledge
- **Correct**: Understand both for bare metal and legacy system recovery

#### Misunderstanding 2: "Systemd is just another init system"
**Reality**: Systemd is a comprehensive system and service manager far beyond init responsibilities:
- Manages dependencies, resource limits (cgroups), user sessions, device management
- Critical for container orchestration (systemd-nspawn, integration with Kubernetes)
- Misunderstanding leads to improper unit file configuration
- **Correct**: Treat systemd as infrastructure management layer, not just process launcher

#### Misunderstanding 3: "Ext4 is the right choice for everything"
**Reality**: Filesystem choice significantly impacts workload performance:
- Ext4: Balanced all-purpose, limited scalability
- XFS: Superior for large files, parallel I/O, scalable
- Btrfs: Snapshots, compression, but stability concerns in production
- NFS: Network storage with caching complexity
- **Correct**: Choose based on workload characteristics and operational constraints

#### Misunderstanding 4: "Root filesystem can be mounted read-write always"
**Reality**: Production root filesystems should be read-only where possible:
- Reduces attack surface (attackers can't modify system binaries)
- Benefits containers and immutable infrastructure
- Allows faster recovery from attacks
- **Correct**: Implement as much read-only mounting as architecture allows

#### Misunderstanding 5: "Permission bits (chmod 755) are sufficient for security"
**Reality**: Permission bits are foundational but insufficient:
- Doesn't prevent root compromise
- Can't implement complex delegation (who can restart service?)
- Doesn't provide audit trails
- **Correct**: Use ACLs + sudoers + SELinux/AppArmor for comprehensive security

#### Misunderstanding 6: "Inode count = storage capacity"
**Reality**: Inode exhaustion is independent of block space:
- Small files can consume all inodes before filling blocks
- Large files can fill blocks before consuming all inodes
- Different filesystems have different inode-to-block ratios
- **Correct**: Monitor both inode usage AND block usage separately; set quotas on both

#### Misunderstanding 7: "Container filesystems are isolated from host"
**Reality**: Containers share the host kernel and leverage same filesystems:
- Container image layers use overlayfs on host filesystem
- Inode exhaustion on host affects all containers
- Mount options on host affect container performance
- **Correct**: Manage host filesystem capacity and performance impacts from all containers combined

---

## Linux Architecture & Boot Process

### Learning Objectives
By completing this section, you will understand:
- How Linux kernel manages hardware resources and applications
- Complete boot sequence from BIOS/UEFI through systemd targets
- How to troubleshoot boot failures and design recovery procedures
- Systemd targets, unit files, and dependency management

### Linux Kernel Architecture

#### Kernel Responsibilities
The Linux kernel manages:
1. **Process/Task Management**: Scheduling, context switching, inter-process communication
2. **Memory Management**: Virtual memory, paging, swap management
3. **Filesystem Management**: File I/O, caching, locking, permission enforcement
4. **Device Management**: Device drivers, interrupt handling, I/O scheduling
5. **Network Management**: TCP/IP stack, socket management, packet filtering

#### Kernel vs User Space - Critical DevOps Implications

| Concern | Impact | DevOps Relevance |
|---------|--------|------------------|
| **Memory Access** | User programs cannot access arbitrary kernel memory | Prevents malware, requires controlled privilege escalation |
| **CPU Instruction Set** | User programs limited to unprivileged CPU instructions | Syscalls required for I/O, adds latency |
| **File Access** | All file access checked against inode permissions | Security enforcement point, bottleneck for high-I/O workloads |
| **Resource Limits** | Kernel enforces limits (max processes, file descriptors) | Container limits (cgroups) depend on kernel resource management |

#### Syscall Interface

User space applications interact with kernel exclusively through syscalls:
```
User Application
    ↓ (syscall: write())
Kernel Mode: validate parameters, check permissions
    ↓
Hardware driver: write data to disk
    ↓
Hardware I/O completion
    ↓
Return to User Mode: result code
```

**Performance Implication**: Each syscall causes context switch (expensive). High-frequency operations should batch syscalls or use kernel buffers.

### BIOS vs UEFI: Boot Firmware

#### BIOS (Legacy)
- **Architecture**: 16-bit x86 real mode
- **Boot Drive Limit**: 2.2 TB (MBR partition table)
- **Partition Table**: MBR (Master Boot Record)
- **Secure Boot**: Not supported
- **Bootloader Search**: MBR first sector only (446 bytes limit)
- **Status**: Deprecated, legacy only

#### UEFI (Modern)
- **Architecture**: 32/64-bit, native mode
- **Boot Drive Limit**: Unlimited (GPT partition table)
- **Partition Table**: GPT (GUID Partition Table)
- **Secure Boot**: Supported (cryptographic signature verification)
- **Bootloader Search**: EFI System Partition (ESP), larger capacity
- **Status**: Industry standard for modern systems (2012+)

#### Boot Flow Comparison

**BIOS Boot Sequence**:
```
Power ON
    → BIOS self-test → Load bootloader from MBR → Load kernel
```

**UEFI Boot Sequence**:
```
Power ON
    → UEFI firmware initialization
    → Secure Boot (optional): verify GRUB signature
    → Load GRUB from EFI System Partition (ESP) → Load kernel
```

**DevOps Implications**:
- AWS/Azure abstract this (UEFI handles internally)
- Bare metal requires understanding both
- Secure Boot enabled requires signed bootloaders (corporate environments)
- Recovery requires different approaches (UEFI vs BIOS entry points)

### Systemd Boot Sequence

Modern Linux systems use **systemd** as init system (PID 1). Boot sequence:

```
1. Kernel loads and initializes CPU, memory, devices
2. Kernel mounts root filesystem (read-only initially)
3. Kernel executes /sbin/init or /lib/systemd/systemd
4. Systemd enters target state (usually multi-user.target)
5. Targets activate service units in dependency order
6. System enters operational state
```

#### Systemd Targets (Equivalent to Runlevels)

| Target | SysV Equivalent | Purpose | Use Case |
|--------|-----------------|---------|----------|
| poweroff.target | runlevel 0 | Power off system | N/A |
| rescue.target | runlevel 1 | Single-user, minimal services | Emergency/recovery |
| multi-user.target | runlevel 3 | Full multi-user system | Servers (default) |
| graphical.target | runlevel 5 | GUI, full services | Desktops |
| reboot.target | runlevel 6 | Reboot system | N/A |

#### Unit Files

Systemd organizes all system components as units:
- **Service units** (.service): Daemon processes (nginx, postgres)
- **Mount units** (.mount): Filesystem mounts
- **Target units** (.target): State groupings (multi-user.target)
- **Timer units** (.timer): Scheduled tasks (cron replacement)
- **Socket units** (.socket): IPC sockets

**Example Service Unit**:
```ini
[Unit]
Description=Nginx Web Server
After=network-online.target     # Dependency: start after network
Wants=network-online.target     # Soft dependency: try to start network

[Service]
Type=notify                     # Notify systemd when ready
ExecStart=/usr/sbin/nginx

[Install]
WantedBy=multi-user.target     # Enable as dependency of multi-user
```

**DevOps Practice**: Understand unit dependencies to troubleshoot service startup failures.

### initramfs - Early Boot Environment

**Purpose**: Load kernel drivers and execute initialization before mounting real root filesystem.

**Use Cases**:
- RAID initialization (assemble RAID arrays before mounting)
- Encrypted root (decrypt before mounting)
- iSCSI/NFS root (network setup before mounting)
- Custom hardware initialization

**Structure**:
```
initramfs (compressed CPIO archive in memory)
├── /bin       → busybox, essential utilities
├── /sbin      → init (dracut, systemd-like)
├── /lib       → Kernel modules (storage drivers, network drivers)
├── /dev       → Device files
└── /sys       → Sysfs mountpoint
```

**Troubleshooting**:
- Missing drivers: Boot fails with "device not found" error
- Solution: Regenerate with `dracut --hostonly` for specific hardware
- Testing: Boot into initramfs with kernel parameter `break=pre-mount`

### Runlevels/Targets - System States

#### Legacy Runlevels (SysV Init)
```
Runlevel 0: Power off
Runlevel 1: Single-user (root shell, minimal services)  
Runlevel 2: Multi-user, no NFS (uncommon, Debian-specific)
Runlevel 3: Full multi-user (servers)
Runlevel 4: Unused (customizable)
Runlevel 5: Graphical (full multi-user with X11)
Runlevel 6: Reboot
```

**Commands**:
- `telinit 1` or `init 1`: Switch to runlevel 1
- Stored in `/etc/inittab` (obsolete on modern systems)

#### Modern Targets (Systemd)
```
poweroff.target      → System power off
rescue.target        → Single-user recovery (like runlevel 1)
multi-user.target    → Full system operational (default for servers)
graphical.target     → Desktop with GUI
reboot.target        → System reboot
```

**Commands**:
- `systemctl isolate rescue.target`: Enter rescue mode
- `systemctl get-default`: Check default target
- `systemctl set-default multi-user.target`: Set default target

---

## Linux Filesystem Hierarchy & Storage

### Learning Objectives
By completing this section, you will understand:
- FHS structure and directory purposes
- Inode architecture and file metadata
- Filesystem types and performance characteristics
- Storage management commands (df, du, lsblk, findmnt)

### Filesystem Hierarchy Standard (FHS)

#### Directory Map with DevOps Purpose

```
/                              Root filesystem
├── /bin                       Essential user commands (standard utilities)
├── /sbin                      System administration commands (fsck, reboot)
├── /lib, /lib64               Shared libraries (libc, libssl, etc.)
├── /boot                      Bootloader and kernel (GRUB, vmlinuz)
├── /etc                       Configuration files (read by services)
├── /root                      Root user home directory
├── /home                      Regular user home directories
├── /var                       Variable data (logs, caches, data)
│   ├── /var/log               Service logs (critical for troubleshooting)
│   ├── /var/cache             Cache data (web cache, package cache)
│   └── /var/spool             Printer/mail queues, cron jobs
├── /tmp                       Temporary files (world-writable, cleared at reboot)
├── /run                       Runtime data (PID files, sockets, modern replacement for /var/run)
├── /opt                       Optional third-party software packages
├── /srv                       Service data (websites, databases, served via network)
├── /dev                       Device files (interface to hardware and kernel drivers)
├── /proc                      Virtual filesystem (interface to kernel and process info)
├── /sys                       Virtual filesystem (device and kernel interface)
├── /usr                       User programs and libraries
│   ├── /usr/bin               User commands (same as /bin in modern systems)
│   ├── /usr/sbin              User system admin commands
│   ├── /usr/local             Locally installed software (overrides /usr)
│   └── /usr/share             Architecture-independent data (man pages, docs)
└── /mnt, /media               Temporary mount points (USB, external drives)
```

#### Critical Directories for DevOps

| Directory | Purpose | DevOps Importance |
|-----------|---------|-------------------|
| /var/log | Service logs (syslog, application logs) | Primary troubleshooting location |
| /var/lib | Stateful data (databases, config caches) | Data persistence for services |
| /etc | Configuration files | IaC enforcement point, version control |
| /tmp | Temporary files | Clean between deployments, disk space monitoring |
| /dev | Device files | Hardware/volume access, container device mapping |
| /proc | Kernel interface | Process monitoring, system metrics |
| /sys | Device interface | Hardware monitoring, power management |
| /opt | Third-party software | Single-purpose containers or isolated apps |

### Inode Architecture

#### What is an Inode?

An inode is a data structure storing all metadata about a file except its name:

```
Inode Structure:
┌──────────────────────────────────────┐
│ File Type (regular, directory, link) │
│ Permissions (rwx bits)               │
│ Owner UID / Group GID                │
│ File Size (bytes)                    │
│ Access Time (last read)              │
│ Modification Time (last write)       │
│ Change Time (metadata modification)  │
│ Hard Link Count                      │
│ Block Pointers (where data stored)   │
└──────────────────────────────────────┘
```

#### Inode Numbers

- **Inode Number**: Unique identifier for inode in filesystem
- **Listing**: `ls -i` shows inode numbers
- **Lookup**: Kernel uses directory → inode number → block locations
- **filesystem Limit**: Filesystem has fixed number of inodes (set at creation)

**Example - Finding Inode**:
```bash
$ ls -i /etc/passwd
12345 /etc/passwd          # Inode 12345, filename /etc/passwd
```

#### Hard Links vs Soft Links

**Hard Link**: Another name for same inode
```
Inode 12345 ← file1 (hard link 1)
           ← file2 (hard link 2)
           ← file3 (hard link 3)
```
- Deletion only removes one hard link; data preserved until all links removed
- `ln file1 file2` creates hard link
- Cannot span filesystems (same inode number only valid within filesystem)

**Soft Link** (Symbolic Link): File containing path to another file
```
Inode 54321 → "../../../../etc/passwd"  (symlink)
     ↓
Inode 12345 → actual file content (real file)
```
- Deletion of symlink doesn't affect original
- `ln -s original symlink` creates symlink
- Works across filesystems
- Breaking link if original removed

**DevOps Impact**: Hard links efficient for backups (zero additional space). Soft links error-prone (break with path changes). Prefer explicit copies or snapshots.

### File Types

Linux recognizes multiple file types:

| Type | Symbol | Command | Purpose |
|------|--------|---------|---------|
| Regular File | - | `touch file` | Normal data file |
| Directory | d | `mkdir dir` | Container for files |
| Symlink | l | `ln -s target link` | Reference to another file |
| Block Device | b | Found in /dev | Storage device (e.g., /dev/sda) |
| Character Device | c | Found in /dev | Serial device (e.g., /dev/ttyS0) |
| FIFO | p | `mkfifo pipe` | Named pipe for inter-process communication |
| Socket | s | Created by applications | Network or UNIX socket |

**Viewing file types**:
```bash
$ ls -l /
d rwx------    root root      /bin
- rw-r--r--    root root      /etc/passwd
l rwxrwxrwx    root root      /lib -> usr/lib (symlink)
b rw-rw----    root disk      /dev/sda (block device)
c rw-rw----    root tty       /dev/tty1 (character device)
```

### Mount Points & Filesystems

#### Mount Point Concept

**Mount Point**: Directory where a filesystem attaches to the directory tree.

```
Logical View (user perspective):
/
├── /home        (mounted from /dev/mapper/vg0-home)
├── /var         (mounted from /dev/mapper/vg0-var)
└── /tmp         (mounted from /dev/mapper/vg0-tmp)

Physical View:
/dev/mapper/vg0-root    → /
/dev/mapper/vg0-home    → /home
/dev/mapper/vg0-var     → /var
/dev/mapper/vg0-tmp     → /tmp
```

#### Mount Options Impact

Common mount options:
```bash
mount -o rw,noatime,defaults /dev/sda1 /data
        │   │        │
        │   │        └─ Default options (all Linux defaults)
        │   └─────────── Don't update access time (performance)
        └─────────────── Read-write mount
```

| Option | Purpose | Use Case |
|--------|---------|----------|
| rw/ro | Read-write or read-only | ro for system images in production |
| noatime | Don't update access time | Performance optimization, reduce I/O |
| nodiratime | Don't update dir access time | Better performance than noatime |
| noexec | Don't allow execution | Security on /tmp, /var mount points |
| nosuid | Ignore setuid/setgid bits | Security on /home, /tmp |
| data=journal/ordered/writeback | Ext4 data journaling mode | journal=safe, writeback=fast |
| defaults | See /etc/fstab defaults | Usually includes rw,relatime,errors=continue |

**Production Best Practice**:
```
/                    : defaults
/boot                : ro (read-only after boot)
/var                 : defaults, size quotas enabled
/tmp                 : noexec,nosuid,nodev (prevent privilege escalation)
/home                : nosuid,nodev (prevent privilege escalation)
Database volumes     : noatime,data=writeback (performance)
```

### Ext4 & XFS Basics

#### Ext4 (Fourth Extended Filesystem)

**Characteristics**:
- Default filesystem on most Linux distributions
- Ext3 → Ext4 improvements (extents, larger files, delayed allocation)
- Journaling: Prevents data loss on crash
- Large file support: Up to 16TB per file
- Extent-based allocation: Reduces fragmentation
- Backward/forward compatible with ext3/ext2

**When to Use**: General-purpose server, balanced performance, mature stability

**Ext4 Concepts**:
- **Extent**: Contiguous block allocation (more efficient than block-by-block)
- **Journal**: Log of filesystem operations (allows recovery on crash)
- **Delayed allocation**: Write operations batched for efficiency

**Journaling Modes**:
```
journal        : Slowest, safest (journal data and metadata)
ordered        : Default, balance (journal metadata, order data writes)
writeback      : Fastest, less safe (journal metadata, data async)
```

#### XFS (eXtended Filesystem)

**Characteristics**:
- Enterprise filesystem from SGI
- Optimized for parallel I/O and large files
- Extent-based allocation
- Dynamic inode allocation (grows as needed)
- Superior scalability for large data
- B+ tree indexing (fast lookups)

**When to Use**: Data warehouses, large files (>1TB), parallel workloads, enterprise environments

**XFS Advantages over Ext4**:
- Faster inode allocation (dynamic, never fills up)
- Better for large files and parallel I/O
- Online defragmentation
- Deeper filesystem checking (xfs_repair)
- Quotas on user, group, and project

**Quotas - XFS Example**:
```bash
# Enable project quotas on /data
xfs_quota -x -c 'project -s project1' /data

# Limit project1 to 100GB
xfs_quota -x -c 'limit -p bsoft=100g bhard=100g project1' /data
```

#### Comparison Matrix

| Feature | Ext4 | XFS |
|---------|------|-----|
| Max File Size | 16 TB | 9 EB (exabytes) |
| Max Filesystem Size | 1 EB | 9 EB |
| Inode Limit | Fixed at creation | Dynamic (grows) |
| Parallel I/O | Good | Excellent |
| Fragmentation | Low (extents) | Very low |
| Defragmentation | Online (e4defrag) | Online (xfs_fsr) |
| Snapshots | No | No (separate tools: LVM) |
| Stability | Very stable | Very stable |
| Online Growth | Yes | Yes (xfs_growfs) |
| Quotas | yes/group/project | user/group/project |

#### Storage Layer Architecture

```
Applications
    ↓
Virtual Filesystem (VFS) - abstraction layer
    ↓
Filesystem (ext4, xfs, btrfs, nfs)
    ↓
Block Device Layer (device mapping, RAID, LVM)
    ↓
Device Drivers (SATA, NVMe, SAN, network)
    ↓
Hardware (SSD, HDD, network storage)
```

### Storage Management Commands

#### `df` - Disk Free (Filesystem Level)

```bash
# Show filesystem capacity and usage
$ df -h /var
Filesystem     Size  Used Avail Use% Mounted on
/dev/mapper/vg0-var  100G   45G   55G  45% /var

# Show inode usage
$ df -i /var
Filesystem      Inodes  IUsed  IFree IUse% Mounted on
/dev/mapper/vg0-var  6553600  123456  6430144   2% /var
```

**Interpretation**:
- **Size**: Total capacity
- **Used**: Current usage
- **Avail**: Free space available
- **Use%**: Percentage used
- **Inodes (with -i)**: File count limits

**DevOps Importance**: Monitor both **% disk** (blocks) and **% inodes**. Inode exhaustion prevents new files even with free blocks.

#### `du` - Disk Usage (Directory Tree Analysis)

```bash
# Show size of /var directory and subdirectories
$ du -h /var
4.2G     /var/log
2.1G     /var/cache
800M     /var/lib
7.1G     /var

# Show top 10 largest directories
$ du -h /var | sort -hr | head -10

# Show size of each file, not directories
$ du -h --max-depth=1 /var
```

**Use Case**: Find what's consuming disk space (logs, caches, databases).

**DevOps Example - Debug Full Disk**:
```bash
$ df -h /
/dev/sda1  100G  98G  1.2G  99% /   # Almost full

$ du -h / | sort -hr | head -5
# Find largest consumers
# Likely: /var/log, /var/cache, or database spilling to root
```

#### `lsblk` - List Block Devices

```bash
$ lsblk
NAME                    MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda                       8:0    0   1.8T  0 disk
├─sda1                    8:1    0   500M  0 part  /boot
└─sda2                    8:2    0   1.3T  0 part
  ├─vg0-root (dm-0)     253:0    0    20G  0 lvm   /
  ├─vg0-var (dm-1)      253:1    0    50G  0 lvm   /var
  ├─vg0-home (dm-2)     253:2    0    30G  0 lvm   /home
  └─vg0-data (dm-3)     253:3    0     2T  0 lvm   /data
nvme0n1                 259:0    0 476.8G  0 disk
└─nvme0n1p1             259:1    0 476.8G  0 part  /mnt/ssd
```

**Columns**:
- **NAME**: Device/partition name
- **SIZE**: Capacity
- **TYPE**: disk, part (partition), lvm (logical volume), crypt (encrypted)
- **MOUNTPOINT**: Where it's mounted

**DevOps Troubleshooting**: Identify which block device is full; useful for adding new volumes or expanding storage.

#### `findmnt` - Find Mount Points

```bash
# Show all mounted filesystems
$ findmnt
TARGET                          SOURCE     FSTYPE  OPTIONS
/                               /dev/mapper/vg0-root
├─ /boot                        /dev/sda1  ext4    rw,relatime
├─ /var                         /dev/mapper/vg0-var
├─ /var/lib                     /dev/mapper/vg0-lib
├─ /home                        /dev/mapper/vg0-home
└─ /tmp                         tmpfs      tmpfs   rw,size=8G

# Show specific mount options
$ findmnt -o TARGET,FSTYPE,OPTIONS /var
TARGET FSTYPE OPTIONS
/var   ext4   rw,relatime,errors=remount-ro

# Find what's mounted on loop devices (containers, images)
$ findmnt | grep loop
```

**Use Cases**:
- Verify mount options applied (noatime, noexec, ro)
- Check filesystem types in use
- Find overlay mounts (Docker containers using overlayfs)

---

## Users, Groups & Permissions

### Learning Objectives
By completing this section, you will understand:
- User/group model and namespace isolation
- File permissions and ownership
- Advanced access control (ACLs, SELinux, AppArmor)
- Sudoers configuration for privilege escalation
- Security implications and audit trails

### Linux User & Group Management

#### User Namespace Fundamentals

Every process runs in a **user context** (UID/GID). Linux enforces permissions based on:

```
Process UID 1000 (alice) attempts:
    ↓
Read /root/.ssh/id_rsa (owned by UID 0 - root)
    ↓
Kernel Permission Check:
    Is process UID == file owner?       NO
    Is process GID == file group?       NO (assuming)
    Is process other?                   YES
    ↓
Check "other" permissions:  -------- (no read)
    ↓
DENY - Permission Denied (EACCES error)
```

#### Users (/etc/passwd)

```bash
$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
alice:x:1000:1000:Alice Smith:/home/alice:/bin/bash
bob:x:1001:1001:Bob Jones:/home/bob:/bin/bash
postgres:x:111:119:PostgreSQL:/var/lib/postgresql:/bin/bash

# Format: username:password_hash:UID:GID:GECOS:home_dir:shell
```

| Field | Purpose |
|-------|---------|
| **username** | Login name |
| **password_hash** | Shadow password (actual hash in /etc/shadow) |
| **UID** | User ID (0=root, 1-999=system, 1000+=regular) |
| **GID** | Primary group ID |
| **GECOS** | Comment (full name, description) |
| **home_dir** | Home directory path |
| **shell** | Login shell |

**UID Ranges**:
- **0**: Root (all privileges)
- **1-999**: System users (daemons, services)
- **1000+**: Regular user accounts

#### Groups (/etc/group)

```bash
$ cat /etc/group
root:x:0:
wheel:x:10:alice,bob
docker:x:999:ubuntu,jenkins
postgres:x:119:

# Format: group_name:password_hash:GID:member_list
```

| Field | Purpose |
|-------|---------|
| **group_name** | Group identifier |
| **password_hash** | Group password (rarely used) |
| **GID** | Group ID |
| **members** | Comma-separated user list |

**User Group Membership**:
```bash
$ id alice
uid=1000(alice) gid=1000(alice) groups=1000(alice),10(wheel),999(docker)
# alice has primary group 1000, plus supplementary groups wheel and docker
```

#### User/Group Management Commands

```bash
# Create user
useradd -m -s /bin/bash -G wheel alice
# -m: create home directory
# -s: set shell
# -G: add to supplementary groups

# Add existing user to group
usermod -aG docker jenkins

# Change user password (prompts interactively)
passwd alice

# Delete user
userdel -r alice  # -r removes home directory

# Create group
groupadd developers

# Delete group
groupdel developers
```

#### Service Accounts (DevOps Practice)

Create dedicated non-root users for each service:

```bash
# Create nginx user
useradd -r -s /bin/nologin -d /var/www nginx
# -r: system user (UID < 1000)
# -s /bin/nologin: prevent SSH login
# -d: home directory

# Verify
$ id nginx
uid=111(nginx) gid=111(nginx) groups=111(nginx)
```

**Benefits**:
- Limits daemon privileges to only necessary access
- Isolates services (one compromise doesn't affect others)
- Audit trails show which service performed actions

### File Permissions & Ownership

#### Permission Bits (Mode)

```
-rwxrw-r-- 1 alice wheel 12345 Mar 13 10:30 script.sh
^ ─────────   ^^^^^      ^^^^
│ ─────────   owner      group
│ ─────────
│ ────────────────────────────────────────── Permissions (9 bits)
Special bits (SetUID, SetGID, Sticky) - first character if present
```

#### Permission Model

```
Permissions: rwxrwxrwx
            ─── ─── ───
            owner, group, other
            7     6     4   (example: 764)
```

| Digit | Meaning | Binary | Permissions |
|-------|---------|--------|------------|
| 0 | None | 000 | --- |
| 1 | Execute | 001 | --x |
| 2 | Write | 010 | -w- |
| 3 | Write + Execute | 011 | -wx |
| 4 | Read | 100 | r-- |
| 5 | Read + Execute | 101 | r-x |
| 6 | Read + Write | 110 | rw- |
| 7 | All | 111 | rwx |

**Examples**:
```bash
755 = rwxr-xr-x   (owner: full, group/other: read+execute)
644 = rw-r--r--   (owner: rw, group/other: read-only)
600 = rw-------   (owner: rw, group/other: no access)
700 = rwx------   (owner: full, group/other: no access)
```

#### Special Permission Bits

Three additional permission bits (beyond rwx for owner/group/other):

**SetUID (Set User ID) - Bit 4000**
```
-rwsr-xr-x  1 root root /usr/bin/passwd
     ^
     SetUID bit set
```
- File executes with owner UID, not executor UID
- Use: `chmod u+s file` or `chmod 4755 file`
- **Only meaningful on executable files**
- **Security Risk**: Requires extreme care (why passwd can be run by anyone but changes only /etc/shadow)

**SetGID (Set Group ID) - Bit 2000**
```
-rwxr-sr-x  1 root disk /usr/sbin/fdisk
       ^
       SetGID bit set
```
- File executes with owner GID
- On directories: new files inherit group (not user's primary group)
- Directory benefit: Team collaboration (all files share team group)

**Sticky Bit - Bit 1000**
```
drwxrwxrwt 15 root root /tmp
       ^
       Sticky bit
```
- On directories: only owner can delete files (not just owner+write)
- Prevents users from deleting each other's files in shared spaces
- Common on /tmp, /var/tmp

**Setting Special Bits**:
```bash
chmod u+s file           # SetUID
chmod g+s directory      # SetGID
chmod o+t directory      # Sticky bit

chmod 4755 file          # SetUID + rwxr-xr-x
chmod 2755 file          # SetGID + rwxr-xr-x
chmod 1777 directory     # Sticky + rwxrwxrwx (typical for /tmp)
```

#### Ownership Management

```bash
# Change owner
chown alice file.txt
chown alice:wheel file.txt   # Change owner and group

# Change group only
chgrp wheel file.txt

# Recursive (directory)
chown -R alice:wheel /home/alice/

# Change without following symlinks
chown -h alice symlink.txt  # -h: don't dereference
```

#### Umask - Default Permissions

When new file created, permissions are:
```
file:      666 (rw for all) minus umask = actual permissions
directory: 777 (rwx for all) minus umask = actual permissions
```

```bash
$ umask
0022

# 022 = ----w--w-
# 666 - 022 = 644 (rw-r--r--)  ← default file permission
# 777 - 022 = 755 (rwxr-xr-x)  ← default directory permission
```

**Common Umasks**:
- **0022** (Linux default): files 644, directories 755
- **0077** (restrictive): files 600, directories 700 (only owner access)

**Set umask** (shell startup script):
```bash
# In ~/.bashrc or /etc/profile
umask 0077   # Very restrictive (only owner)
umask 0027   # Moderate (owner: full, group: rx, other: none)
```

### Access Control Lists (ACLs)

**Purpose**: Fine-grained permissions beyond rwx model.

**When to Use**: When standard permissions insufficient (e.g., multiple groups need different permissions).

**Caution**: ACLs add complexity; prefer reorganizing groups/permissions first.

#### ACL Syntax

```bash
# Grant ugo (user/group/other)
setfacl -m u:alice:rw /tmp/shared.txt   # alice: read+write
setfacl -m g:developers:rx /tmp/script.sh  # developers: read+execute
setfacl -m o::- /tmp/secret.txt         # other: no permissions

# View ACLs
getfacl /tmp/shared.txt
# file: /tmp/shared.txt
# owner: root
# group: root
# user:alice:rw-
# group::r--
# other::---

# Remove ACL
setfacl -x u:alice /tmp/shared.txt

# Clear all ACLs
setfacl -b /tmp/shared.txt
```

#### ACL on Directories (Inheritance)

```bash
# Set default ACL (inherited by new files)
setfacl -d -m u:alice:rwx /project_dir

# New files in /project_dir automatically grant alice rwx
touch /project_dir/newfile.txt
# newfile.txt has alice with rwx
```

### Sudoers Configuration

**Purpose**: Delegate administrative tasks to non-root users without sharing root password.

#### Sudoers File Location & Syntax

```bash
# Never edit directly - use visudo (validates syntax)
sudo visudo

# Default location: /etc/sudoers
# Include directory: /etc/sudoers.d/ (prefer for modular setup)
```

#### Sudoers Rule Format

```
[user/group] [host] = [runas_user] [nopasswd] [commands]
```

#### Common Sudoers Examples

```bash
# Full root access (no password prompt)
alice ALL=(ALL) NOPASSWD: ALL

# Service restart (with password prompt)
%developers ALL=(ALL) /usr/bin/systemctl restart nginx

# Multiple commands
bob ALL=(ALL) NOPASSWD: /sbin/reboot, /sbin/shutdown

# Specific host
alice webserver1=(ALL) /usr/sbin/service apache2 restart

# As different user
alice ALL=(postgres) /bin/kill

# With restrictions
jenkins ALL=(root) NOPASSWD: /usr/bin/docker
```

#### Sudoers Best Practices

1. **Use Groups** (not individual users):
   ```
   %wheel ALL=(ALL) NOPASSWD: ALL       # Wheel group = admins
   %developers ALL=(ALL) /usr/bin/systemctl restart tomcat
   ```

2. **Specific Commands Only**:
   ```
   # Good: restricted
   jenkins ALL=(root) NOPASSWD: /usr/bin/docker

   # Risky: generic
   jenkins ALL=(root) NOPASSWD: /usr/bin/*    # Could match unintended
   ```

3. **Require Password When Possible**:
   ```
   # Secure: password required
   %admins ALL=(ALL) ALL

   # Less secure: no password (use only for service accounts in CI/CD)
   jenkins ALL=(ALL) NOPASSWD: ALL
   ```

4. **Log Sudo Usage**:
   ```bash
   # Check sudo audit log
   sudo journalctl SYSLOG_IDENTIFIER=sudo -f
   # or
   sudo tail -f /var/log/auth.log | grep sudo
   ```

#### Sudo Logging

```bash
# Who ran what, when
$ sudo journalctl SYSLOG_IDENTIFIER=sudo
Mar 13 10:45:23 server sudo: alice : TTY=pts/0 ; PWD=/home/alice ; 
                            USER=root ; COMMAND=/usr/bin/systemctl restart nginx

# Count sudo usage
$ sudo journalctl SYSLOG_IDENTIFIER=sudo | grep "COMMAND=" | wc -l
```

### PAM (Pluggable Authentication Modules)

**Purpose**: Flexible authentication framework (replaceable components for password, MFA, etc.).

**Common Use Cases**:
- Password quality checking
- MFA integration (TOTP, Yubikey)
- LDAP/Active Directory authentication
- SSH key-based auth

**Key PAM Config Files**:
```
/etc/pam.d/
├── common-account      # Account validity checks
├── common-auth         # Primary authentication
├── common-password     # Password change
├── common-session      # Session setup (environment, limits)
├── sshd                # SSH authentication
└── sudo                # Sudo authentication
```

**Example - Force Strong Passwords**:
```bash
# /etc/pam.d/common-password

password requisite pam_pwquality.so retry=3 minlen=12 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1
# minlen=12: minimum 12 characters
# dcredit=-1: require at least 1 digit
# ucredit=-1: require at least 1 uppercase
# ocredit=-1: require at least 1 special character
# lcredit=-1: require at least 1 lowercase
```

### Privilege Escalation Concepts

#### Vertical Escalation (User → Root)

**Legitimate**:
- Sudo (with sudoers rules)
- SetUID binaries (passwd, sudoedit)
- Suid wrapping scripts

**Exploitation Vectors**:
- Misconfigured sudoers (wildcards: `ALL /usr/bin/*`)
- SetUID binary with buffer overflow
- Sudo with unrestricted editing permissions (sudoedit)

#### Horizontal Escalation (User → Different User)

```bash
# With sudo
sudo -u databinduser /special/query

# Via group membership
# alice in "docker" group → can execute docker → can mount volumes → access /etc
```

#### Exploitation Mitigation

| Vector | Mitigation |
|--------|-----------|
| Weak sudoers rules | Review with principle of least privilege |
| SetUID exploits | Remove/fix SetUID binaries; use sudo wrapper instead |
| Password compromise | Force password changes; audit sudo usage |
| Group membership escalation | Audit group membership; remove unnecessary groups |
| Kernel vulnerabilities | Keep kernel updated; monitor CVEs |

---

## Hands-on Scenarios

### Scenario 1: Emergency Boot into Rescue Target - Diagnosing Boot Failure

**Problem Statement**: 
A production web server fails to reach multi-user.target during boot. Monitoring alerts show service unavailable, but no console access to observe boot messages. You must recover the system and identify the root cause.

**Architecture Context**:
- Server: Physical bare metal in datacenter with IPMI access
- OS: Ubuntu 20.04 with systemd as init
- Storage: LVM volumes mounted on ext4
- Critical services: nginx, PostgreSQL, monitoring agents

**Troubleshooting Steps**:

```bash
# STEP 1: Access via IPMI serial console (out-of-band)
# Using ipmitool or IPMI web interface to get serial console access
ipmitool -I lanplus -H ipmi.server.local -U admin -P pass sol activate

# STEP 2: Reboot into GRUB menu (if stuck at login)
# Press ESC at startup splash, enter GRUB edit mode
e  # Edit boot entry
# Add: systemd.log_level=debug to kernel line
# Ctrl+X to boot with debug logging

# STEP 3: If system hangs, boot into rescue target
# At GRUB menu: select recovery option OR manually add:
# append: systemd.unit=rescue.target
# Ctrl+X to boot

# STEP 4: In rescue target (root shell, read-only root)
mount -o remount,rw /     # Mount root read-write for repairs

# STEP 5: Check what services failed
systemctl list-units --failed --no-pager

# Output example:
# UNIT                      LOAD   ACTIVE SUB   DESCRIPTION
# nginx.service             loaded failed failed The NGINX HTTP and Reverse Proxy Server
# postgresql.service        loaded failed failed PostgreSQL RDBMS
# 
# 2 loaded units listed

# STEP 6: Examine failure logs for each failed service
journalctl -u nginx.service --no-pager
# Output might show: "Failed to bind to 0.0.0.0:80 - Address already in use"

journalctl -u postgresql.service --no-pager
# Output might show: "/var/lib/postgresql: Permission denied"

# STEP 7: Root cause analysis
# Issue 1: Port 80 in use → check what's running
ss -tunlp | grep 80
# Might find: docker container using port 80

# Issue 2: PostgreSQL permission denied
ls -la /var/lib/postgresql
# If directories owned by root instead of postgres user:
chown -R postgres:postgres /var/lib/postgresql
chmod 0700 /var/lib/postgresql

# Issue 3: Docker service not started
systemctl status docker
# If failed: check logs
journalctl -u docker -n 50

# STEP 8: Fix the issues
# Fix Issue 1: Kill rogue docker container
docker ps -a | grep port
docker rm $(docker ps -aq)

# Fix Issue 2: Ownership already corrected above

# Fix Issue 3: Start docker
systemctl start docker

# STEP 9: Try starting services
systemctl start postgresql.service
# Check status
systemctl status postgresql.service

systemctl start nginx.service
systemctl status nginx.service

# STEP 10: If services still fail, check systemd security context
grep -A 10 "\[Service\]" /etc/systemd/system/postgresql.service
# Check: User=, PrivateTmp=, NoNewPrivileges=
# These can prevent services from accessing required resources

# STEP 11: Exit rescue mode and reboot to multi-user
exit
systemctl reboot
```

**Best Practices Applied**:
- ✓ Used out-of-band access (IPMI) when normal console unavailable
- ✓ Systematically checked failed units before guessing
- ✓ Examined detailed logs for each failure
- ✓ Fixed root causes (ownership, ports, dependencies) rather than masking failures
- ✓ Verified each fix before rebooting
- ✓ Documented findings for incident postmortem

---

### Scenario 2: Inode Exhaustion in Kubernetes - Multi-Pod Diagnosis

**Problem Statement**:
Kubernetes cluster experiencing pod evictions with errors: "PersistentVolumeClaim is full". Block capacity monitoring shows 40% free space, but no new pod replicas can schedule. Investigation needed.

**Architecture Context**:
- 3-node Kubernetes cluster (EKS on AWS)
- Persistent volumes (20GB each) formatted as ext4
- Multiple microservices writing logs to /var/log
- Monitoring with Prometheus (scrape metrics every 15s)

**Troubleshooting Steps**:

```bash
#!/bin/bash
# STEP 1: SSH into worker node experiencing pod eviction
kubectl debug node worker-node-1 -it --image=ubuntu:20.04

# STEP 2: Find the problematic persistent volume mount
df -h /var/lib/kubelet/pods/*/volumes/kubernetes.io~aws-ebs/pvc-*

# Output:
# /dev/xvdc    20G  8.0G  12G  40% /var/lib/kubelet/pods/...

# This shows 40% space used by 8GB, but let's check inodes
df -i /var/lib/kubelet/pods/*/volumes/kubernetes.io~aws-ebs/pvc-*

# Output:
# /dev/xvdc  1310720  1309998  722  99% /var/lib/kubelet/pods/...
# INODES FULL! Only 722 inodes left out of 1.3M

# STEP 3: Mount the PV somewhere to inspect
MOUNT_PATH="/mnt/pvc-debug"
mkdir -p $MOUNT_PATH
mount /dev/xvdc $MOUNT_PATH

# STEP 4: Find directories consuming inodes
find $MOUNT_PATH -type f | wc -l
# Shows: 1,309,000+ files

# STEP 5: Identify high-inode consumers
find $MOUNT_PATH -type d -exec sh -c 'echo $(find "$1" -type f | wc -l) "$1"' _ {} \; | \
    sort -rn | head -20

# Output:
# 450000  /mnt/pvc-debug/app-logs
# 380000  /mnt/pvc-debug/prometheus-data
# 200000  /mnt/pvc-debug/application-temp

# STEP 6: Root cause analysis
# Prometheus is storing metrics with per-container labels
ls -la /mnt/pvc-debug/prometheus-data/wal/
# Shows thousands of .gz files, each WAL segment is a new file

# Application logs are not being rotated
ls -la /mnt/pvc-debug/app-logs/
# Shows: app.log (1.2GB single file), no rotation

# STEP 7: Check PV mount options
mount | grep /dev/xvdc
# Shows: ext4 defaults,noatime (no issue with mount options)

# STEP 8: Check current filesystem inode ratio
dumpe2fs /dev/xvdc | grep "Inode size"
# Shows: 256 bytes (this is fine)
# But: created with default inode ratio (1 inode per 16KB = ~ 1.3M total)

# STEP 9: Prepare remediation plan
# Option A (temporary): Delete old files
find /mnt/pvc-debug/prometheus-data -name "*.gz" -mtime +7 -delete  # Files older than 7 days
find /mnt/pvc-debug/app-logs -name "*.log.1" -delete                # Rotated logs

# Option B (permanent): Reconfigure applications
# Edit Prometheus retention and WAL configuration:
cat > /tmp/prometheus-config.yaml <<'EOF'
global:
  scrape_interval: 15s
storage:
  tsdb:
    out_of_order_time_window: 30m
    max_block_duration: 2h
    min_block_duration: 2h
  retention:
    max_time: 7d  # Keep only 7 days (reduces file count)
EOF

# Configure app log rotation (logrotate)
cat > /etc/logrotate.d/myapp <<'EOF'
/var/log/app.log {
  size 100M
  rotate 5
  compress
  delaycompress
}
EOF

# STEP 10: Expand PV with more inodes (recreate filesystem)
# WARNING: Destructive; requires backup first
umount /mnt/pvc-debug

# Create new filesystem with better inode ratio
# 1 inode per 4KB = more inodes for many small files
mkfs.ext4 -i 4096 /dev/xvdc

# Restore data from backup
mount /dev/xvdc $MOUNT_PATH
rsync -av /backup/pvc-data/ $MOUNT_PATH/

# STEP 11: Unmount and let Kubernetes resume
umount $MOUNT_PATH
# PVC will be remounted by pod controllers

# STEP 12: Verify pods can now schedule
kubectl get pods | grep "Pending\|Evicted"
# Should show no pending/evicted pods
```

**Best Practices Applied**:
- ✓ Monitored BOTH block space AND inode usage (common oversight)
- ✓ Identified root causes (Prometheus WAL files, log rotation missing)
- ✓ Implemented permanent fixes, not just temporary cleanup
- ✓ Adjusted inode ratio at filesystem creation time for workload characteristics
- ✓ Implemented log rotation to prevent future issues

---

### Scenario 3: Kubernetes Cross-Node Permission Mismatch

**Problem Statement**:
StatefulSet pod fails with "permission denied" when reading shared ConfigMap volume. Pod runs as user ID 1000 (app user), but volume contents unreadable. Other pods on same node work fine.

**Architecture Context**:
- Kubernetes StatefulSet with volumeClaimTemplates
- ConfigMap mounted as volume containing application configuration
- Pod security context specifies: runAsUser: 1000, fsGroup: 1000
- Host uses different UID namespace mapping

**Troubleshooting Steps**:

```bash
# STEP 1: Inspect failing pod
kubectl describe pod problematic-pod-0
# Note: mounted volumes, security context, node assignment

# STEP 2: Check pod logs for exact error
kubectl logs problematic-pod-0
# Output: "error opening /config/app.conf: Permission denied"

# STEP 3: SSH into node where pod running and inspect volume
kubectl debug node <node-name> -it --image=ubuntu:20.04

# STEP 4: Find the pod's volume mount
find /var/lib/kubelet/pods -name "app.conf"
# Output: /var/lib/kubelet/pods/<uuid>/volumes/kubernetes.io~configmap/config/app.conf

# STEP 5: Check file ownership and permissions
ls -la /var/lib/kubelet/pods/<uuid>/volumes/kubernetes.io~configmap/config/
# Output:
# -rw-r--r-- 1 root root 1024 Mar 13 10:30 app.conf

# Problem: File owned by root, not readable by UID 1000

# STEP 6: Check pod security context
kubectl get pod problematic-pod-0 -o yaml | grep -A 10 "securityContext:"
# Shows: fsGroup: 1000 (should change group ownership)

# STEP 7: Understand why fsGroup not applied
# fsGroup only works with certain volume types (emptyDir, configMap with defaultMode)
# Check ConfigMap mount parameters
kubectl get pod problematic-pod-0 -o yaml | grep -A 15 "volumeMounts:"
# Look for: defaultMode (should be set, e.g., 0644)

# STEP 8: Root cause: ConfigMap doesn't have defaultMode set
# ConfigMap files default to 0644 (rw-r--r--, owned by root)
# fsGroup 1000 doesn't change root file ownership

# STEP 9: Fix 1 - Set defaultMode in volume spec
kubectl get pod problematic-pod-0 -o yaml > pod.yaml
# Edit pod.yaml, find volumeMounts section, add:
# volumes:
# - name: config
#   configMap:
#     name: app-config
#     defaultMode: 0640  # Make group-readable
#     items:
#     - key: app.conf
#       path: app.conf
#       mode: 0640

kubectl apply -f pod.yaml
kubectl delete pod problematic-pod-0  # Force recreate
kubectl wait --for=condition=ready pod/problematic-pod-0 --timeout=300s

# STEP 10: If defaultMode still insufficient, use init container to fix permissions
cat > pod-with-init.yaml <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: problematic-pod-0
spec:
  securityContext:
    fsGroup: 1000
  
  initContainers:
  - name: fix-permissions
    image: busybox
    command: ['sh', '-c', 'chown -R 1000:1000 /config && chmod -R 0750 /config']
    volumeMounts:
    - name: config
      mountPath: /config
  
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config
      mountPath: /config
  
  volumes:
  - name: config
    configMap:
      name: app-config
      defaultMode: 0644
EOF

kubectl apply -f pod-with-init.yaml

# STEP 11: Verify fix
kubectl logs problematic-pod-0
# Should no longer show "Permission denied"

# STEP 12: Check actual permissions in pod
kubectl exec problematic-pod-0 -- ls -la /config/
# Output:
# drwxr-x--- 2 1000 1000 4096 Mar 13 10:35 .
# -rw-r----- 1 1000 1000 1024 Mar 13 10:35 app.conf

# Now readable by app running as UID 1000
```

**Best Practices Applied**:
- ✓ Understood Kubernetes security context (runAsUser, fsGroup, defaultMode)
- ✓ Recognized limitations of fsGroup (doesn't change file owner in some cases)
- ✓ Used init containers for permission fixes when needed
- ✓ Set proper defaultMode on ConfigMap volumes
- ✓ Tested fix before considering incident resolved

---

### Scenario 4: Sudoers Misconfiguration Causing CI/CD Lockout

**Problem Statement**:
GitLab CI/CD runner can no longer deploy applications. Runner service (running as `gitlab-runner` user) fails when executing deployment scripts that require sudo. Error: "sudo: no such file or directory in sudoers".

**Architecture Context**:
- GitLab CI/CD runner deployed as systemd service
- Runs as unprivileged user: gitlab-runner
- Deployment script needs: docker commands, systemctl restarts, configuration file writes
- Recent sudoers update attempted to tighten permissions

**Troubleshooting Steps**:

```bash
# STEP 1: Check error in runner logs
sudo journalctl -u gitlab-runner -n 50
# Output:
# ERROR: sudo: no such file or directory in sudoers

# STEP 2: Attempt to reproduce locally
sudo -u gitlab-runner sudo /usr/bin/systemctl restart myapp
# Error: sudo: no such file or directory in sudoers

# STEP 3: Check actual sudoers file for syntax errors
sudo visudo -c
# Output:
# parse error in /etc/sudoers.d/gitlab-runner, line 5: ❌ Error found

# STEP 4: Check problematic sudoers file
cat /etc/sudoers.d/gitlab-runner
# Output might show:
```
gitlab-runner ALL=/usr/bin/systemctl restart myapp,  # Missing backslash
gitlab-runner ALL=/usr/bin/docker
```
# Syntax error: mismatched quotes or malformed command

# STEP 5: Fix sudoers file (IMPORTANT: use visudo, never edit directly!)
sudo visudo -f /etc/sudoers.d/gitlab-runner
# Correct version:
```
# Allow gitlab-runner to restart services
gitlab-runner ALL=(ALL) NOPASSWD: \
    /usr/bin/systemctl restart myapp, \
    /usr/bin/systemctl restart nginx, \
    /usr/bin/systemctl reload postgresql

# Allow gitlab-runner to use docker
gitlab-runner ALL=(ALL) NOPASSWD: /usr/bin/docker

# Allow gitlab-runner specific write access
gitlab-runner ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/myapp/config.conf
```

# STEP 6: Validate syntax again
sudo visudo -c
# Output: "parse error in..." should now be gone

# STEP 7: Test the fix
sudo -u gitlab-runner sudo /usr/bin/systemctl restart myapp --dry-run
# Or for docker
sudo -u gitlab-runner sudo /usr/bin/docker ps

# STEP 8: Best practice - implement sudoers through configuration management
# Create Ansible playbook to manage sudoers consistently:
cat > configure-sudoers.yml <<'EOF'
---
- hosts: ci-runners
  become: yes
  
  tasks:
  - name: Create sudoers config for gitlab-runner
    copy:
      content: |
        # Managed by Ansible - do not edit manually
        gitlab-runner ALL=(ALL) NOPASSWD: \
            /usr/bin/systemctl restart myapp, \
            /usr/bin/systemctl restart nginx, \
            /usr/bin/systemctl reload postgresql, \
            /usr/bin/docker
      dest: /etc/sudoers.d/gitlab-runner
      owner: root
      group: root
      mode: '0440'
      validate: '/usr/sbin/visudo -cf %s'
    notify: restart gitlab-runner
  
  handlers:
  - name: restart gitlab-runner
    systemd:
      name: gitlab-runner
      state: restarted
EOF

# STEP 9: Implement sudoers audit mechanism
cat > monitor-sudoers.sh <<'EOF'
#!/bin/bash
# sudoers-audit.sh - Alert on sudoers modifications

SUDOERS_DIR="/etc/sudoers.d"
CHECKSUM_FILE="/var/lib/sudoers-checksums"

# Store current checksums
if [ ! -f $CHECKSUM_FILE ]; then
    find $SUDOERS_DIR -type f -exec sha256sum {} \; > $CHECKSUM_FILE
    exit 0
fi

# Compare with stored checksums
find $SUDOERS_DIR -type f -exec sha256sum {} \; | \
    while read checksum file; do
        original=$(grep "$file" $CHECKSUM_FILE | cut -d' ' -f1)
        if [ "$checksum" != "$original" ]; then
            # File modified - send alert
            echo "ALERT: $file modified" | mail -s "Sudoers Change" ops@company.com
        fi
done

# Update checksums
find $SUDOERS_DIR -type f -exec sha256sum {} \; > $CHECKSUM_FILE
EOF

# Cron job runs this daily
echo "0 3 * * * /usr/local/bin/monitor-sudoers.sh" | crontab -

# STEP 10: Document sudoers configuration with version control
cat > /etc/sudoers-managed-template.txt <<'EOF'
# GitLab CI/CD Runner Sudoers Configuration
# 
# Purpose: Allow gitlab-runner service to perform deployment tasks
# Managed by: Ansible playbook configure-sudoers.yml
# Last updated: 2026-03-13
#
# Commands granted:
# - systemctl restart/reload services
# - docker operations
# - configuration file writes
#
# Security notes:
# - Specific commands only (never wildcards)
# - No password required (CI/CD automation)
# - Logging enabled via sudo audit trail

gitlab-runner ALL=(ALL) NOPASSWD: \
    /usr/bin/systemctl restart myapp, \
    /usr/bin/systemctl restart nginx, \
    /usr/bin/systemctl reload postgresql, \
    /usr/bin/docker
EOF

echo "STEP 11: Verify deployment now works"
gitlab-runner verify  # Check runner connectivity
gitlab-runner run     # Resume builds
```

**Best Practices Applied**:
- ✓ Used `visudo` to validate syntax (prevents lockout)
- ✓ Managed sudoers through IaC (Ansible), not manual edits
- ✓ Implemented audit trail for sudoers modifications
- ✓ Specific command restrictions (no wildcards)
- ✓ Documented configuration with version control
- ✓ Created monitoring to alert on unauthorized changes

---

### Scenario 5: Multi-Tenant Storage Isolation with Quotas

**Problem Statement**:
Multi-tenant SaaS platform with per-customer data volumes. One customer's poorly configured application fills the shared filesystem, impacting all other customers. Need to implement isolation and prevent future incidents.

**Architecture Context**:
- Shared NFS mount for customer data: /data/customers
- 20+ customers, each with 50-200GB quota
- Customers run containerized applications
- SLA violation if any customer loses data access

**Implementation Steps**:

```bash
# STEP 1: Audit current usage and identify problematic customer
du -h /data/customers/ | sort -hr | head -20

# Output:
# 450G   /data/customers/acme-corp
# 210G   /data/customers/widgets-inc
# 85G    /data/customers/...

# STEP 2: Check what's consuming acme-corp space
find /data/customers/acme-corp -type f -size +1G -exec ls -lh {} \;
# Shows: Multiple temp files, uncompressed logs, old backups

# STEP 3: Implement per-customer quotas using XFS project quotas
# (Better than ext4 user quotas for directory-level control)

# Check if filesystem supports project quotas
xfs_quota -x -c 'report -a' /data/customers

# STEP 4: Create project quota configuration
cat > /etc/projects <<'EOF'
1:acme-corp
2:widgets-inc
3:techstartup-llc
EOF

cat > /etc/projid <<'EOF'
acme-corp:1
widgets-inc:2
techstartup-llc:3
EOF

# STEP 5: Set directory project association
for dir in /data/customers/*/; do
    project=$(basename "$dir")
    project_id=$(awk -F: "/^$project:/{print \$2}" /etc/projid)
    xfs_quota -x -c "project -s -p /data/customers/$project $project_id" /data/customers
done

# STEP 6: Apply per-project quotas (limits in 1K blocks)
xfs_quota -x -c 'limit -p bsoft=200g bhard=210g 1' /data/customers   # acme-corp
xfs_quota -x -c 'limit -p bsoft=150g bhard=160g 2' /data/customers   # widgets-inc
xfs_quota -x -c 'limit -p bsoft=100g bhard=110g 3' /data/customers   # techstartup

# STEP 7: Enable quota enforcement
xfs_quota -x -c 'enable -a' /data/customers

# STEP 8: Verify quotas applied
xfs_quota -x -c 'report' /data/customers
# Output shows:
# Project       Used      Soft      Hard    Warn  Mounted on
# acme-corp    450G      200G      210G    OFF   /data/customers

# STEP 9: Handle soft limit enforcement (graceful warnings)
cat > /usr/local/bin/quota-warning.sh <<'EOF'
#!/bin/bash
# Check soft limit violations and send notifications

xfs_quota -x -c 'report' /data/customers | tail -n +3 | while read project used soft hard warn mounted; do
    # Extract numeric values
    used_gb=${used%G}
    soft_gb=${soft%G}
    
    if [ $(echo "$used_gb > $soft_gb" | bc) -eq 1 ]; then
        # Over soft limit - send alert to customer
        CUSTOMER_EMAIL=$(grep "^$project:" /etc/customer-emails | cut -d: -f2)
        
        echo "Your data usage ($used_gb GB) exceeds soft limit ($soft_gb GB)" | \
            mail -s "Storage Warning" "$CUSTOMER_EMAIL"
        
        # Also log to monitoring
        echo "quota_warning{project=\"$project\",used_gb=\"$used_gb\",soft_gb=\"$soft_gb\"}" >> /var/log/quotas.prom
    fi
done
EOF

chmod +x /usr/local/bin/quota-warning.sh

# Cron job runs every 6 hours
echo "0 */6 * * * /usr/local/bin/quota-warning.sh" | crontab -

# STEP 10: Implement automatic cleanup for aged files
cat > /usr/local/bin/cleanup-old-files.sh <<'EOF'
#!/bin/bash
# Remove files older than 90 days (customer policy)

for customer_dir in /data/customers/*/; do
    customer=$(basename "$customer_dir")
    
    # Find files older than 90 days in temp directories
    find "$customer_dir/tmp" -type f -mtime +90 -print0 | \
        xargs -0 rm -f
    
    find "$customer_dir/logs" -type f -mtime +90 -print0 | \
        xargs -0 gzip -f  # Compress instead of delete
done
EOF

# Cron job runs nightly
echo "0 2 * * * /usr/local/bin/cleanup-old-files.sh" | crontab -

# STEP 11: Track quota compliance with monitoring
cat > /usr/local/bin/quota-metrics.sh <<'EOF'
#!/bin/bash
# Export quota metrics for Prometheus

{
    echo '# HELP storage_quota_bytes Allocated quota in bytes'
    echo '# TYPE storage_quota_bytes gauge'
    
    xfs_quota -x -c 'report' /data/customers | tail -n +3 | while read project used soft hard warn mounted; do
        used_bytes=$(echo "$used" | sed 's/G$/*1073741824/' | bc)
        soft_bytes=$(echo "$soft" | sed 's/G$/*1073741824/' | bc)
        hard_bytes=$(echo "$hard" | sed 's/G$/*1073741824/' | bc)
        
        echo "storage_quota_bytes{project=\"$project\",type=\"used\"} $used_bytes"
        echo "storage_quota_bytes{project=\"$project\",type=\"soft_limit\"} $soft_bytes"
        echo "storage_quota_bytes{project=\"$project\",type=\"hard_limit\"} $hard_bytes"
    done
} > /var/lib/node_exporter/quota-metrics.prom
EOF

# Integrate with node_exporter and Prometheus for visualization

# STEP 12: Document per-customer storage policy
cat > /data/customers/.policy.txt <<'EOF'
Storage Policy for Customer Data

Quota Limits:
- Soft limit: When exceeded, customer receives warning email
- Hard limit: Writes blocked when exceeded (prevents data loss)

File Retention:
- Temporary files (/tmp): Auto-deleted after 90 days
- Logs (/logs): Compressed after 90 days, auto-deleted after 365 days
- Application data: Retained per customer agreement

Monitoring:
- Quota reports generated daily
- Soft limit warnings sent when 95% utilization reached
- Capacity planning: Increase quota 30 days in advance

Escalation:
- If customer over hard limit: Contact support@company.com
- Expansion requests: 2-week lead time for infrastructure planning
EOF
```

**Best Practices Applied**:
- ✓ Implemented directory-level quotas (better than per-user quotas)
- ✓ Separated soft limits (warnings) from hard limits (enforcement)
- ✓ Automated cleanup of old/temp files
- ✓ Integrated quotas with monitoring and alerting
- ✓ Documented policy for customers
- ✓ Graceful degradation (warnings before hard stops)
- ✓ Fair resource allocation across multiple tenants

---

## Most Asked Interview Questions

### Linux Architecture & Boot Process

**Q1: Walk me through the complete boot sequence from power-on to systemd starting services. Where can failures occur?**

**Expected Answer (Senior Level)**:
Boot phases and failure points:
1. **BIOS/UEFI (Firmware)**: Initializes hardware, scans bootable devices, loads bootloader
   - Failure: BIOS settings misconfigured (boot order), corrupted firmware
   
2. **Bootloader (GRUB)**: Loads kernel and initrd, passes parameters
   - Failure: GRUB config corrupted, kernel image missing, timeout too short
   
3. **Kernel Initialization**: Decompresses, sets up paging, memory management, loads drivers
   - Failure: Kernel panic (missing drivers, hardware incompatibility, memory issues)
   
4. **Initramfs Execution**: Loads storage drivers, assembles RAID/encryption, mounts real root
   - Failure: Missing drivers for storage, failed decryption, root filesystem not found
   
5. **Init System (systemd)**: Parses units, builds dependency graph, starts services
   - Failure: Failed services, unmet dependencies, permission issues

Recovery options at each stage:
- Bootloader failure: Enter GRUB edit mode, boot alternate kernel, single-user mode
- Kernel failure: Can't recover at runtime; need rescue media or kernel parameters
- Initramfs failure: `break=pre-mount` kernel parameter for debugging
- Systemd failure: Boot to `systemd.unit=rescue.target` for minimal environment

Diagnostic tools:
- `dmesg` for kernel messages
- `journalctl` for systemd logs
- `systemd-analyze` for service startup timing
- IPMI/serial console for bootloader access

**Real-world scenario**: Server fails after kernel update. Bootloader tries new kernel (fails), falls back to previous kernel (works). This is GRUB's default behavior if timeout long enough.

---

**Q2: Explain the difference between Wants and Requires in systemd unit dependencies. When would you use each?**

**Expected Answer**:
Dependency types and behavior:

**Requires=**: Hard dependency
- If dependency fails, dependent unit also fails
- Example: `application.service Requires=database.service`
- If database fails: application also fails (immediately)
- Failure is cascading and visible to user

**Wants=**: Soft dependency
- Independent from dependency status
- Systemd tries to start dependency but continues regardless
- Example: `application.service Wants=monitoring.service`
- If monitoring fails: application still starts (resilient)
- Useful for optional features

Design pattern:
```ini
[Unit]
# Hard dependency: must have network
After=network-online.target
Requires=network-online.target

# Soft dependency: optional monitoring
Wants=prometheus-exporter.service

[Service]
Type=simple
ExecStart=/app/start.sh

# Restart policy: keep running even if optional deps fail
Restart=on-failure
RestartSec=10s
```

Common mistake: Using `Requires=` for everything causes cascading failures. Better practice:
- Requires for truly critical dependencies (database for app, filesystem for filesystem mounter)
- Wants for optional features (monitoring, logging, backups)

Real-world tradeoff:
- Web server (Wants=logging): If logging system fails, web server still serves traffic
- Database replication (Requires=network): If network fails, don't start replica (consistency++)

---

**Q3: How would you troubleshoot a system stuck in emergency.target? Walk through your diagnostic approach.**

**Expected Answer**:
Situation: System boots to emergency.target (black screen, only root shell) instead of multi-user.target. Limited diagnostics possible.

Diagnostic approach:
1. Check what services attempted to start and failed
   ```bash
   systemctl list-units --state=failed --all
   systemctl status <failed-service> -l
   journalctl -u <failed-service> -n 50
   ```

2. Check filesystem status
   ```bash
   df -h  # Any full?
   df -i  # Inode issues?
   findmnt  # Unmounted critical filesystems?
   mount | grep ro  # Read-only root/var?
   ```

3. Check journal for boot errors
   ```bash
   journalctl -b 0 -p err  # All errors since boot
   journalctl --no-tail | tail -100  # Last 100 boot messages
   ```

4. Dependency issues
   ```bash
   systemd-analyze verify /etc/systemd/system/critical.service
   # Check for circular dependencies
   ```

5. Permission issues
   ```bash
   systemctl status systemd-tmpfiles-setup.service
   # Often fails if /etc or /var permissions wrong
   ```

6. Hardware detection
   ```bash
   lsblk  # All storage devices visible?
   ip link  # All network interfaces present?
   lspci | grep -E 'Storage|Network'  # Controllers detected?
   ```

Common causes (in order of frequency):
- Filesystem permission errors (0755 → 0700 accidentally)
- Disk full (/var/log filling up)
- Journal corruption (clear with `journalctl --vacuum-time=1d`)
- FSTAB pointing to non-existent devices
- Network dependency (systemd-networkd) taking too long

System recovery without rescue media:
```bash
# In emergency.target (root shell)
mount -o remount,rw /
systemctl mask <failing-service>  # Disable offending service
systemctl isolate multi-user.target  # Attempt boot
```

---

### Linux Filesystem & Storage

**Q4: Describe scenarios where ext4 and XFS would have drastically different performance. Which would you choose for each?**

**Expected Answer**:
Choice depends on workload characteristics:

**Ext4 Better For**:
1. **General workloads** with balanced read/write
   - Example: Web servers, app servers, typical databases
   - Latency-sensitive (lower overhead)
   
2. **Small files (< 1MB average)**
   - Extent-based allocation works well
   - Inode lookup efficient
   
3. **Volatile data** (temporary, caches)
   - Journal overhead acceptable for safety
   - Performance hit from journal worth reliability gain

**XFS Better For**:
1. **Large file workloads (TB-sized files)**
   - Example: Video files, scientific datasets, big data
   - Ext4 would fragment severely (extents max out at larger sizes)
   - Direct testing: Write 100GB file sequentially
     - Ext4: ~500MB/s sustained
     - XFS: ~700MB/s sustained (30% faster)
   
2. **Parallel I/O patterns**
   - Example: Hadoop HDFS, data warehouse with many concurrent queries
   - XFS allocation groups prevent contention
   - Ext4 would show spinlock contention at 50+ parallel writers
   
3. **Dynamic inode allocation**
   - Ext4 inode count fixed at mkfs time (if fullish, file creates slow)
   - XFS allocates inodes on-demand
   - Example: Kubernetes with volatile pods; XFS never runs out of inodes
   
4. **Production databases** with heavy concurrent load
   - PostgreSQL/Mongo on XFS shows 15-20% better performance
   - Extent allocation strategy better for B-tree operations

Benchmarking approach (production decision):
```bash
# Test workload on both filesystems
# Parallel writes with different file sizes
fio --name=parallel-writes \
    --ioengine=libaio \
    --iodepth=32 \
    --numjobs=16 \
    --size=100G \
    --rw=write

# XFS typically wins at 8+ concurrent operations
```

Personal experience: Switched Hadoop cluster from ext4 to XFS, reduced query latency by 25% without touching application code.

---

**Q5: You're allocating a 5TB EBS volume for PostgreSQL. Walk me through all filesystem decisions: format, mount options, performance tuning.**

**Expected Answer**:
Comprehensive EBS volume setup for production database:

**Step 1: Block Device Preparation**
```bash
# Create single partition (modern practice vs multiple partitions)
parted /dev/nvme0n1 mklabel gpt  # GPT for > 2TB
parted /dev/nvme0n1 mkpart primary 0% 100%
parted /dev/nvme0n1 align-check optimal 1  # Check alignment
```

**Step 2: Filesystem Selection**
- Choose: **XFS** for PostgreSQL (better concurrent I/O, dynamic inode allocation)
- Rationale: PostgreSQL does parallel sequential scans, XFS allocation groups prevent lock contention

**Step 3: Filesystem Creation**
```bash
mkfs.xfs -b size=4096 \
         -d agcount=32 \  # Allocation groups (16GB each) - tune for 5TB
         -L pgdata \      # Label for identification
         /dev/nvme0n1p1
# Parameters:
# agcount=32: PostgreSQL uses many pgfifo/index files; more AGs = better parallelism
# stripe width: Optional if EBS (AWS handles internally)
```

**Step 4: Mount with Production Options**
```bash
# In /etc/fstab:
LABEL=pgdata /var/lib/postgresql xfs rw,noatime,nodiratime,attr2,inode64,allocsize=16m 0 0

# Options explained:
# noatime/nodiratime: Skip access time updates (PostgreSQL doesn't need them)
# attr2: Extended attributes (for lvm snapshots)
# inode64: 64-bit inode (future-proofing, required for large files)
# allocsize=16m: Extent allocation size (16MB chunks, better for sequential scans)

mount /var/lib/postgresql
```

**Step 5: Verify Alignment & Performance**
```bash
# Check 4K alignment (EBS granularity)
cat /sys/block/nvme0n1/queue/optimal_io_size
# Should be 4096 (4KB)

# Benchmark before PostgreSQL installation
fio --name=random-read \
    --ioengine=libaio \
    --iodepth=16 \
    --numjobs=4 \
    --size=100G \
    --rw=randread \
    --runtime=60

# Expect: ~30,000 IOPS (gp3 baseline), up to 16,000 MB/s with provisioning
```

**Step 6: PostgreSQL-Specific Tuning**
```bash
# In postgresql.conf:
shared_buffers = 16GB           # 25% of RAM (avoid double-buffering with page cache)
effective_cache_size = 48GB     # Tell planner there's 48GB available (page cache + buffers)
random_page_cost = 1.1          # EBS is mostly SSD-like (SSD cost = 1.1, HDD = 4.0)
maintenance_work_mem = 4GB      # For VACUUM, CREATE INDEX
wal_buffers = 256MB             # WAL buffer size (writes to XFS allocsize=16m chunks)

# fsync behavior (critical for ACID)
fsync = on                      # ALWAYS (don't disable, losing durability)
synchronous_commit = on         # Balanced: local durable, but not replicas
wal_sync_method = open_datasync # Use datasync (faster than fdatasync)
```

**Step 7: Monitoring & Capacity Planning**
- Monitor with Prometheus:
  ```
  # Space usage
  node_filesystem_avail_bytes{mountpoint="/var/lib/postgresql"}
  
  # I/O performance
  rate(node_disk_io_time_seconds_total[5m])
  ```
- Alert: Trigger expansion at 80% capacity (EBS expansion takes minutes)

**Step 8: Disaster Recovery**
- Daily snapshots: `aws ec2 create-snapshot --volume-id vol-123 --description "pgdata-$(date +%Y%m%d)"`
- Test restore: Monthly practice restoring snapshot to temp volume

Real-world issue encountered: PostgreSQL on ext4 with noatime disabled (using relatime default). Significant contention with 500+ concurrent connections. Switched to XFS + noatime: contention disappeared, latency dropped 30%.

---

**Q6: Explain how overlayfs works in Docker. Why not use it for databases? What would you use instead?**

**Expected Answer**:
Overlayfs architecture and limitations:

**Overlayfs Layers**:
```
Container R/W Layer (writes go here)
    ↓
Image Layers (stacked, read-only)
    ↓
Host Filesystem (ext4, xfs, etc.)
```

Write behavior (copy-on-write):
- Read existing file: Served from image layer (fast)
- Modify existing file: Copied to r/w layer, then modified (copy-on-write tax)
- Delete: Mark as deleted in r/w layer, original still exists (space waste)

Performance characteristics:
```
Sequential writes: 700 MB/s          (host filesystem)
Random writes: 15,000 IOPS           (host filesystem)

With overlayfs:
Sequential writes: 650 MB/s          (2% slower - copy overhead)
Random writes: 12,000 IOPS           (20% slower)

Why slower?
- Page cache separates host and container (buffer duplication)
- All writes must be copied to r/w layer first
- Metadata operations (stat, open) hit multiple layers
```

**Why Overlayfs Unsuitable for Databases**:
1. **Copy-on-Write Overhead**: Database does random writes to modify B-tree nodes
   - Each page write triggers copy → 20% latency penalty
   - Example: PostgreSQL UPDATE statement touches 3-5 pages; all copied first

2. **Deleted Block Reuse**: Database expects deleted space immediately reusable
   - ext4/xfs B-tree: Delete index node, block freed immediately
   - Overlayfs: Delete marked in r/w layer, blocks not freed (inode count rises)
   - Example: VACUUM rarely shrinks tables in overlayfs container

3. **I/O Pattern Mismatch**: Database does sequential WAL writes (streaming)
   - Overlayfs adds seek from image layer to r/w layer (kills sequential I/O)
   - HDD-based systems particularly affected

4. **Snapshot Isolation**: Database expects point-in-time consistency
   - Overlayfs layer composition not atomic (crash mid-transaction visible)

**What to Use Instead**:

**Option 1: Named Volumes (Recommended)**
```dockerfile
FROM postgres:14

VOLUME /var/lib/postgresql/data

# Data stored directly on host filesystem
# No overlayfs copy-on-write penalty
```

Mount native host storage:
```bash
docker run -v pgdata:/var/lib/postgresql/data postgres:14
# Creates `/var/lib/docker/volumes/pgdata/_data/` on host
```

**Option 2: Bind Mount**
```bash
mkdir -p /data/postgres
docker run -v /data/postgres:/var/lib/postgresql/data postgres:14
# /data/postgres directly visible in container (zero overhead)
```

**Option 3: Kubernetes Persistent Volumes**
```yaml
spec:
  containers:
  - name: postgres
    volumeMounts:
    - name: pgdata
      mountPath: /var/lib/postgresql/data
  
  volumes:
  - name: pgdata
    persistentVolumeClaim:
      claimName: postgres-pvc
```

Performance comparison (same hardware):
```
Overlayfs:     TPS = 450 (sysbench oltp read/write)
Named Volume:  TPS = 580 (+28%)
Native Mount:  TPS = 600 (+33%)
```

Real-world lesson: Migrated legacy app from overlayfs container to native volume. Query latency dropped 250ms for same-size dataset (40% improvement).

---

### Permissions & Access Control

**Q7: Design a permission model for a 200-person engineering organization using Unix users/groups on a shared build server. Requirements: developers only access own code, ops can access all, different permission levels (read vs read-write).**

**Expected Answer**:
Permission model design (group-based, scalable):

**User Classification**:
```
├── System Users (UID 0-999)
│   └── build, deploy, monitoring (service accounts)
│
└── Human Users (UID 1000+)
    ├── Developers (1000-1100)
    └── Operations (1100-1110)
```

**Group Hierarchy** (matches organizational structure):
```
/etc/group entries:

# Team groups (for code access)
frontend:1000:                    # developers: alice, bob, charlie
backend:1001:                     # developers: dave, eve, frank
devops:1002:                       # ops: gary, helen

# Permission groups
developers:2000:all frontend and backend team members
sysadmins:2100:gary,helen (only 2 ops)

# Service groups
docker:999:deploy_service
builder:998:build_service
```

**Filesystem Hierarchy** (per team):
```
/code
├── frontend/
│   owner: root
│   group: frontend
│   mode: 0770         # Owner can manage, frontend can rw, others blocked
│
├── backend/
│   owner: root
│   group: backend
│   mode: 0770
│
├── ops/
│   owner: root
│   group: devops
│   mode: 0770
│
└── archive/
    owner: root
    group: developers
    mode: 0550         # Everyone can read (archive), not write
```

**Implementation** (Ansible):
```yaml
---
- name: Setup permission model
  hosts: build-servers
  become: yes
  
  vars:
    teams:
      frontend:
        gid: 1000
        members: [alice, bob, charlie]
        repos: [frontend, shared-libs]
      
      backend:
        gid: 1001
        members: [dave, eve, frank]
        repos: [backend, shared-libs]
      
      devops:
        gid: 1002
        members: [gary, helen]
        can_manage: all
  
  tasks:
  - name: Create team groups
    group:
      name: "{{ item.key }}"
      gid: "{{ item.value.gid }}"
      state: present
    loop: "{{ teams | dict2items }}"
  
  - name: Create developers group (union of all)
    group:
      name: developers
      gid: 2000
      state: present
  
  - name: Add users to team groups
    user:
      name: "{{ user }}"
      groups: "{{ team }}"
      append: yes
    loop: "{{ teams | dict2items | subelements('value.members')|"first" | first }}{{ item[0].key }},{{ item[1] }}"
    loop_control:
      label: "{{ item[1] }} -> {{ item[0].key }}"
  
  - name: Add all users to developers group
    user:
      name: "{{ item }}"
      groups: developers
      append: yes
    loop: [alice, bob, charlie, dave, eve, frank]
  
  - name: Set ACLs for developers to read archive
    acl:
      path: /code/archive
      entity: developers
      etype: group
      permissions: rx
      state: present
  
  - name: Create project directories with permissions
    file:
      path: "/code/{{ item.key }}"
      owner: root
      group: "{{ item.key }}"
      mode: '0770'
      state: directory
    loop: "{{ teams | dict2items }}"
  
  - name: Ops users (sysadmins) can access all
    acl:
      path: "/code"
      entity: devops
      etype: group
      permissions: rwx
      state: present
      recursive: yes
```

**Testing Permission Enforcement**:
```bash
# Verify alice (frontend) can access own code
$ ssh alice@build
$ cd /code/frontend && cat Makefile  # ✓ Success
$ cd /code/backend && cat app.py     # ✗ Permission denied
$ cd /code/archive && cat README.md  # ✓ Success (read-only)

# Verify dave (backend) isolation
$ ssh dave@build
$ cd /code/backend && make deploy    # ✓ Success, own team
$ cd /code/frontend && ls            # ✗ Permission denied

# Verify ops can access all
$ ssh gary@build
$ cd /code/frontend && git pull      # ✓ Success, ops access all
$ cd /code/backend && systemctl restart app  # ✓ Success
```

**Sudoers Policy** (limited escalation):
```bash
# /etc/sudoers.d/developers
# Developers can only restart their own services
%frontend ALL=/usr/bin/systemctl restart frontend-app
%backend ALL=/usr/bin/systemctl restart backend-api
%devops ALL=(ALL) ALL NOPASSWD  # Ops fully trusted

# Developers cannot sudo to other users (isolation)
```

**Audit Trail**:
```bash
# Track who accessed what, when
auditctl -w /code -p wa -k code_access

# Monitor
tail -f /var/log/audit/audit.log | grep code_access
# Output: type=ACCESS msg=audit msg: USER=alice COMM=cat FILE_NAME=/code/frontend/...
```

**Challenges & Solutions**:
- Challenge: New developer joins project → must be added to group
  - Solution: Ansible playbook for onboarding
- Challenge: Cross-team projects (frontend + backend collaboration)
  - Solution: Create additional group `frontend_backend_shared`, add to ACLs
- Challenge: Contractor access (temporary, limited scope)
  - Solution: Separate `contractors` group, explicit project-by-project ACLs

---

**Q8: You discover that /usr/bin/passwd has SetUID bit set but owned by a non-root user. Explain the security implications and how to fix it.**

**Expected Answer**:
Security analysis of SetUID misconfiguration:

**Scenario**: 
```bash
$ ls -la /usr/bin/passwd
-rwsr-xr-x 1 alice wheel 60000 Mar 13
       ^ SetUID bit
```

Wait - passwd owned by alice, not root?

**Implications**:
1. **Privilege Escalation**: Any user running passwd gets alice's UID, not root
   - Normal: passwd runs as root → can modify /etc/shadow (owned by root)
   - Broken: passwd runs as alice → alice's command is executed with alice's permissions
   - Result: passwd fails (alice can't write /etc/shadow)

2. **Worse Scenario**: If alice is a service account (e.g., web server)
   - Attacker compromises web server → runs /usr/bin/passwd → gets alice UID (lateral movement)
   - Attacker could then run exploits as alice that require SetUID privs

3. **File Modifications**: If SetUID binary itself writable by alice
   - Alice modifies /usr/bin/passwd to run arbitrary code
   - Next user running passwd gets compromised
   - Classic privilege escalation attack

**Diagnosis**:
```bash
# How did this happen?
stat /usr/bin/passwd
# File: ownership is alice, SetUID bit present

# Check if this is package-provided or manual modification
rpm -V passwd  # Verify package integrity

# Or if manually installed:
ls -la /usr/bin/passwd  # Check if tampered

# Check modification time
ls -la --full-time /usr/bin/passwd

# Might reveal:
# -rwsr-xr-x  alice wheel 
# Modified today, owner is alice → suspicious!
# Original should be root:root
```

**Fixing**:
```bash
# STEP 1: Verify intended owner (should be root)
# Re-install from package
apt reinstall passwd  # Debian/Ubuntu
yum reinstall util-linux  # RHEL/CentOS

# Verify fix
ls -la /usr/bin/passwd
# Should show: -rwsr-xr-x  1 root root

# STEP 2: If package doesn't fix it, manual correction
sudo chown root:root /usr/bin/passwd
sudo chmod 4755 /usr/bin/passwd  # rws r-x r-x

# STEP 3: Verify integrity
# Check SHA256 against known-good sum
echo "Expected hash from package repository: abc123"
sha256sum /usr/bin/passwd  # Should match

# STEP 4: Audit system for other SetUID misconfigurations
find / -perm -4000 -type f 2>/dev/null | while read file; do
    owner=$(stat -c '%U' "$file")
    if [ "$owner" != "root" ]; then
        echo "ALERT: SetUID $file owned by $owner (not root)"
    fi
done
```

**Root Cause Prevention**:
```bash
# Implement file integrity monitoring
aide --init  # Generate baseline
aide --check # Check against baseline

# Cron job alerts on SetUID changes
cat > /usr/local/bin/audit-setuid.sh <<'EOF'
#!/bin/bash
find / -perm -4000 -o -perm -2000 > /tmp/setuid.new

if [ -f /tmp/setuid.old ]; then
    diff /tmp/setuid.old /tmp/setuid.new | grep "^>" | while read line; do
        echo "NEW SetUID FILE: $line" | mail -s "Security Alert" root
    done
fi

mv /tmp/setuid.new /tmp/setuid.old
EOF

# Run via cron
echo "0 * * * * /usr/local/bin/audit-setuid.sh" | crontab -

# Alternatively: use SELinux/AppArmor to confine SetUID binaries
# /etc/apparmor.d/usr.bin.passwd  defines what passwd can access
```

**Real-world incident**: Malicious insider executed `/bin/cp -p /etc/passwd ~` to copy passwd file, modified it offline to create root account, then overwrote SetUID bit on cp to trigger backdoor. Detected by file integrity monitoring (aide).

---

**Q9: Design sudoers configuration for a multi-team DevOps environment. Requirements: Team A manages databases, Team B manages infrastructure, minimal escalation. Explain your structure and rationale.**

**Expected Answer**:
Multi-team sudoers design (principle of least privilege):

**Organizational Structure**:
```
DevOps Team (20 engineers)
├── Database Team (5 engineers)
│   └── Responsibilities: PostgreSQL, MySQL, backup, DR
├── Infrastructure Team (8 engineers)
│   └── Responsibilities: VMs, networking, load balancers
└── Platform Team (7 engineers)
    └── Responsibilities: Kubernetes, service mesh, CI/CD
```

**Sudoers Configuration Strategy**:
```bash
# File: /etc/sudoers.d/database-team
# Purpose: Restrict database team to DB management only

# Database team users
%db_team ALL=(ALL) \
    NOPASSWD: /usr/bin/systemctl restart postgres, \
    NOPASSWD: /usr/bin/systemctl restart mysql, \
    NOPASSWD: /usr/bin/pg_dump *, \
    NOPASSWD: /usr/bin/mysql -u * -p*, \
    NOPASSWD: /usr/bin/mysqldump *, \
    NOPASSWD: /opt/backup/backup.sh, \
    PASSWD: /sbin/shutdown  # Require password for destructive

# Restrictions
Defaults!/opt/backup/backup.sh !use_pty  # No input redirection
Defaults!/usr/bin/mysql !use_pty

# Prohibition: Cannot access infrastructure commands
%db_team Cmnd_Alias BLOCKED_INFRA = /usr/sbin/ip, /usr/sbin/iptables
Cmnd_Alias BLOCKED_K8S = /usr/bin/kubectl
Cmnd_Alias BLOCKED_DC = /usr/bin/docker, /usr/bin/docker-compose

---

# File: /etc/sudoers.d/infrastructure-team
# Infrastructure team: VM, network, storage

%infra_team ALL=(ALL) \
    NOPASSWD: /usr/sbin/ip *, \
    NOPASSWD: /usr/sbin/iptables, \
    NOPASSWD: /usr/sbin/ufw, \
    NOPASSWD: /usr/bin/systemctl *, \
    NOPASSWD: /sbin/mount, \
    NOPASSWD: /sbin/umount, \
    NOPASSWD: /usr/bin/lvextend, \
    PASSWD: /sbin/shutdown

# Restrictions
Defaults!/usr/bin/systemctl !use_pty
Cmnd_Alias BLOCKED_DB = /usr/bin/psql, /usr/bin/mysql
Cmnd_Alias BLOCKED_K8S = /usr/bin/kubectl

%infra_team !'BLOCKED_DB'  # Cannot access DB commands

---

# File: /etc/sudoers.d/platform-team
# Platform (Kubernetes) team

%platform_team ALL=(ALL) \
    NOPASSWD: /usr/bin/kubectl *, \
    NOPASSWD: /usr/bin/docker, \
    NOPASSWD: /usr/bin/helm, \
    NOPASSWD: /usr/bin/systemctl restart docker, \
    PASSWD: /sbin/shutdown

# Restrictions via kubernetes RBAC (not sudoers)
# You wouldn't sudo to database or infrastructure

Defaults!/usr/bin/kubectl !use_pty
Cmnd_Alias BLOCKED_OS = /usr/sbin/ip, /usr/bin/systemctl
%platform_team !'BLOCKED_OS'  # Cannot modify OS directly
```

**Command-Level Granularity** (more sophisticated):
```bash
# /etc/sudoers.d/db-team-detailed
# Only allow specific operations, not entire toolset

%db_team ALL=(postgres) \
    NOPASSWD: /usr/bin/pg_dump -h localhost -d production *, \
    PASSWD: /usr/bin/pg_dump -h * *

# Only allow localhost dumps (no remote dumps)
# Remote dumps require password (require deliberation)

%db_team ALL=(mysql) \
    NOPASSWD: /usr/bin/mysql -u monitoring -p* --execute "SHOW *", \
    NOPASSWD: /usr/bin/mysqldump --single-transaction *

# Restrictions on mysql: can only read (SHOW), not DROP/ALTER
```

**Logging & Audit Trail**:
```bash
# /etc/sudoers.d/global-logging
# Log ALL sudo usage (all users, all commands)

Defaults log_file="/var/log/sudo.log"
Defaults log_input,log_output     # Log input AND output
Defaults log_passwd               # Log interaction with password prompts
Defaults env_keep+="ANSIBLE_VAULT_PASSWORD_FILE"  # Allow these env vars passthrough
```

**Monitoring Sudo Activity** (Prometheus metrics):
```bash
#!/bin/bash
# monitor-sudo.sh - Export sudo metrics

# Count sudo invocations by user
{
    echo '# HELP sudo_executions_total Total sudo command executions'
    echo '# TYPE sudo_executions_total counter'
    
    grep "COMMAND=" /var/log/sudo.log | \
        awk '{print $5}' | cut -d= -f2 | sort | uniq -c | \
        while read count user; do
            echo "sudo_executions_total{user=\"$user\"} $count"
        done
}
```

**Onboarding Process** (IaC-driven):
```yaml
# playbook: add-devops-engineer.yml
---
- name: Onboard new DevOps engineer
  hosts: all
  vars:
    new_engineer:
      name: newuser
      team: db_team  # Options: db_team, infra_team, platform_team
  
  tasks:
  - name: Create user account
    user:
      name: "{{ new_engineer.name }}"
      groups: "{{ new_engineer.team }}"
      append: yes
    
  - name: User automatically gets sudoers permission
    # Permission inherited from team group membership
    # No manual sudoers editing required
```

**Incident Response**:
```bash
# If engineer compromised:
# Option 1: Remove from team group
usermod -G old_groups username  # Remove from db_team

# Option 2: Revoke specific commands (temporary)
# Edit sudoers.d, remove user from sudo group
groupdel username

# Option 3: Audit what was done with their access
grep "username\|bob" /var/log/sudo.log | tail -100
```

**Advantages of This Design**:
- ✓ Team-based (add/remove users by group membership)
- ✓ Least privilege (specific commands, not wildcard)
- ✓ Auditable (all commands logged)
- ✓ Scalable (add new team = new sudoers file)
- ✓ Reversible (remove team → lost access immediately)

Real-world incident: Engineer escalates via sudo wildcard (`* ALL=(ALL) ALL`). Anyone could sudo to any user, execute any command. Fixed by implementing this model; now sudo is fine-grained per team.

---

## Summary & Key Takeaways

---

# Deep Dive: Subtopic 1 - Linux Architecture & Boot Process

## Textual Deep Dive

### Internal Working Mechanism

#### Kernel Boot Sequence - Step by Step

The Linux kernel boot process involves multiple distinct phases:

**Phase 1: Firmware Initialization (BIOS/UEFI)**
```
Hardware Power-ON
    ↓
BIOS/UEFI runs built-in diagnostics (POST - Power-On Self-Test)
    • Detect CPU, RAM, IO controllers
    • Scan PCI bus for devices (SATA, NVMe, network cards)
    • Initialize bootable devices
    ↓
BIOS/UEFI executes bootloader code from MBR (BIOS) or ESP (UEFI)
    ↓
Control transferred to bootloader (GRUB, LILO)
```

**Phase 2: Bootloader Execution (GRUB)**
```
GRUB Stage 1: Load subsequent stages
    ↓
GRUB Stage 2: Menu display (if configured)
    • User selects kernel or performs recovery
    ↓
GRUB loads:
    1. Kernel image (/vmlinuz or /boot/vmlinuz-*)
    2. Initrd/initramfs image
    3. Passes kernel parameters (console, rootflags, etc.)
    ↓
Bootloader transfers control to kernel entry point
```

**Phase 3: Kernel Execution (start_kernel() function)**
```
Kernel decompresses self (if compressed)
    ↓
Initialize CPU: Set up:
    • Paging (virtual memory)
    • Interrupt handlers
    • Memory management (zone allocator)
    ↓
Detect hardware:
    • CPU features (VMX, AVX, PAE)
    • Memory size
    • Devices from firmware tables (ACPI, Device Tree)
    ↓
Mount initramfs as temporary root filesystem
    ↓
Execute /init script or systemd from initramfs
```

**Phase 4: Initramfs Execution**
```
Kernel executes /init (typically scripts from dracut or systemd-initramfs)

/init responsibilities:
    1. Load kernel modules required for real root
       - Storage drivers (ata_piix for IDE, ahci for SATA, nvme)
       - Network drivers (if network root)
       - Encrypted root drivers (dm-crypt)
    ↓
    2. Assemble devices
       - Detect and activate RAID arrays
       - Unlock encrypted volumes
       - Configure network (for NFS/iSCSI root)
    ↓
    3. Mount real root filesystem
       - Locate /dev reference (by UUID, LABEL, or path)
       - Mount read-only initially
    ↓
    4. Switch root
       - Clean up initramfs (pivot_root syscall)
       - Execute /sbin/init or /lib/systemd/systemd from new root
```

**Phase 5: Init System (Systemd) Takes Over**
```
Systemd (PID 1) executes:
    1. Parse /etc/systemd/system.conf
    2. Load default target (usually multi-user.target)
    ↓
    3. Dependency analysis
       - Read all .service, .target, .mount units
       - Build dependency graph (Before=, After=, Requires=, Wants=)
    ↓
    4. Parallel startup
       - Fork processes for independent units
       - Start units in parallel where possible
       - Enforce ordering constraints
    ↓
    5. System operational
       - All critical services running
       - System ready for user logins/workloads
```

#### Context: Kernel Space vs User Space

The separation is enforced at CPU privilege level:

```
CPU Execute Ring Model:
┌─────────────────────────────────────────┐
│ Ring 0: Kernel Space (Privilege Level)  │ ← Kernel executes here
│ - Full hardware access                  │
│ - All memory directly accessible        │
│ - I/O operations (read/write disks)     │
│ - Memory protection registers           │
│ - Interrupt handlers                    │
└─────────────────────────────────────────┘
            ↓ Context Switch (expensive)
┌─────────────────────────────────────────┐
│ Ring 3: User Space                      │ ← Applications execute here
│ - Limited instruction set               │
│ - Isolated virtual memory               │
│ - Cannot directly access hardware       │
│ - Must use syscalls for I/O             │
│ - Signals for interrupts                │
└─────────────────────────────────────────┘
```

**Syscall Execution Path**:
```
User Application (Ring 3) wants to read file:
    |
    +→ read(file_descriptor) call
        |
        +→ Software interrupt (e.g., int 0x80 or syscall instruction)
            |
            +→ CPU switches to Ring 0 (kernel mode)
                |
                +→ Kernel performs:
                    - Validate file descriptor
                    - Check permissions (inode mode)
                    - Read from disk/cache
                    - Copy data to user buffer
                |
                +→ Return to user space (Ring 3)
                    |
                    +→ Application receives data

Cost: Context switch expensive (~1-10 microseconds)
      Minimize syscalls in performance-critical code
```

### Architecture Role

#### Kernel Subsystems & Boot Dependencies

```
Systemd dependency graph during boot:

local-fs-pre.target  ← Prepare filesystems
        ↓
local-fs.target      ← Mount local filesystems (/etc, /var)
        ↓
sysinit.target       ← System initialization (fsck, swap, modules)
        ↓
system-preset.target ← Apply systemd presets
        ↓
basic.target         ← Basic system setup complete
        │
        ├──→ getty.target      ← Login prompts (serial, terminal)
        │
        ├──→ timers.target     ← Scheduled timers (systemd-timers)
        │
        ├──→ sockets.target    ← Socket activation (systemd-socket-units)
        │
        └──→ network-pre.target ← Pre-network setup
            ↓
            network.target      ← Network interfaces up
            ↓
            network-online.target ← DNS, DHCP complete
            ↓
            multi-user.target   ← Full system operational
            (OR graphical.target on desktops)
```

#### Boot Failure Recovery Architecture

```
Boot Failure Detection and Recovery:

Normal Boot Path:
    Kernel → initramfs → real root → systemd → multi-user.target ✓

Failure Detection Points:
    1. Bootloader cannot find kernel
        Action: GRUB falls back to recovery mode
        
    2. Kernel cannot mount initramfs
        Action: Kernel panic (if no fallback device)
        
    3. Initramfs cannot assemble devices
        Action: Systemd emergency.target activated (drop to root shell)
        
    4. Real root filesystem corrupted
        Action: systemd-fsck runs fsck automatically
                If fails: rescue.target
        
    5. Critical service fails to start
        Action: systemd-analyze shows failed units
                Admin disables/fixes service

Recovery Entry Points:
    ├── GRUB menu (kernel parameter: break=pre-mount)
    ├── Initramfs emergency shell (kernel parameter: init=/bin/sh)
    ├── systemd emergency.target (login as root, no password)
    └── systemd rescue.target (limited services, filesystem R/W)
```

### Production Usage Patterns

#### Pattern 1: Custom Kernel Parameters for Debugging

In production, kernel parameters often configured for specific requirements:

**Example: Database Server Boot Configuration**
```
kernel /vmlinuz-5.15.0 \
    root=/dev/mapper/vg0-root \
    ro \
    crashkernel=256M \
    console=tty0 \
    console=ttyS0,115200 \
    numa=off \
    transparent_hugepage=always \
    vm.swappiness=10
```

**Explanation**:
- `crashkernel=256M`: Reserve kernel memory for kdump (kernel crash dumps)
- `console=ttyS0,115200`: Serial console on ttyS0 at 115200 baud (for IPMI/KVM)
- `numa=off`: Disable NUMA for databases requiring uniform latency
- `transparent_hugepage=always`: Enable 2MB/1GB pages (database performance)
- `vm.swappiness=10`: Strongly prefer page cache over swap (performance)

#### Pattern 2: Multi-Boot Environments (Kernel Selection)

Organizations often maintain multiple kernels for:
- Stable production kernel
- New kernel testing
- Rollback capability

**GRUB Configuration** (`/etc/grub.d/40_custom`):
```bash
menuentry 'Production Kernel 5.15.0 (stable)' {
    search --no-floppy --label root
    insmod gzio
    insmod part_gpt
    insmod ext2
    set root='hd0,gpt2'
    linux /vmlinuz-5.15.0-stable root=/dev/mapper/vg0-root
    initrd /initrd.img-5.15.0-stable
}

menuentry 'Kernel 6.1.0 (testing)' {
    search --no-floppy --label root
    set root='hd0,gpt2'
    linux /vmlinuz-6.1.0-testing root=/dev/mapper/vg0-root
    initrd /initrd.img-6.1.0-testing
}
```

#### Pattern 3: Systemd Target-Based Environments

Production systems often switch targets programmatically:

**Use Case: Maintenance Mode**
```
Normal operation: multi-user.target (all services)
    ↓ (admin initiates maintenance)
Maintenance mode: rescue.target (minimal services, R/W filesystem)
    ↓ (maintenance complete)
Resume: multi-user.target (full services)
```

### DevOps Best Practices

#### Best Practice 1: Immutable Infrastructure Boot

In containerized environments, bake boot configuration:

```dockerfile
# Dockerfile for base system image
FROM ubuntu:22.04

# Bake kernel parameters
RUN echo 'vm.swappiness=10' >> /etc/sysctl.d/99-custom.conf && \
    echo 'net.ipv4.tcp_fin_timeout=30' >> /etc/sysctl.d/99-custom.conf

# Pre-generate initramfs
RUN update-initramfs -u -k all

# Set default systemd target
RUN systemctl set-default multi-user.target
```

#### Best Practice 2: Boot Time Monitoring & Alerts

Implement systemd-analyze based monitoring:

```bash
#!/bin/bash
# boot-time-monitor.sh - Track boot performance degradation

THRESHOLD_SECONDS=60  # Alert if boot takes >60 seconds

# Extract total boot time
BOOT_TIME=$(systemd-analyze | grep "Startup finished" | \
    awk '{print $NF}' | sed 's/s//')

if (( $(echo "$BOOT_TIME > $THRESHOLD_SECONDS" | bc -l) )); then
    # Log slow boot with details
    systemd-analyze blame | head -20 > /var/log/slow-boot.log
    
    # Alert monitoring system
    echo "ALERT: Boot time ${BOOT_TIME}s exceeds threshold" | \
        mail -s "Slow boot detected" ops@company.com
fi
```

#### Best Practice 3: Systemd Unit Dependency Design

**Poor Practice** (sequential, slow):
```ini
[Unit]
After=network.target
RequiredBy=application.service

[Service]
ExecStart=/opt/app/start.sh
```

**Good Practice** (parallel where possible):
```ini
[Unit]
Description=Application Service
After=network-online.target
Wants=network-online.target

# Explicit: only wait for network, not all units
# Wants (not Requires): continue even if network fails

[Service]
Type=notify
ExecStart=/opt/app/start.sh
Restart=on-failure
RestartSec=5s
```

### Common Pitfalls

#### Pitfall 1: Over-reliance on Boot Order

**Problem**:
```ini
[Unit]
After=mysql.service postgresql.service redis.service

[Service]
ExecStart=/app/start.sh
```

**Issue**: If any dependency slow, application boot delayed. Better: use health checks.

**Solution**:
```ini
[Unit]
Description=Application Service
Wants=network-online.target

[Service]
Type=notify
ExecStart=/opt/app/start.sh

# Application itself checks if MySQL responds
# Doesn't wait for MySQL to be "ready", just "started"

ExecStartPost=/usr/local/bin/wait-for-services.sh
```

#### Pitfall 2: Lost Kernel Parameters on Update

**Problem**: Kernel update overwrites bootloader configuration.

**Solution**: Use bootloader hooks:
```bash
# /etc/kernel/postinst.d/99-custom-params

#!/bin/bash
# Ensure kernel parameters applied on each kernel update

KERNEL_VERSION=$1

/usr/sbin/grub-mkconfig -o /boot/grub/grub.cfg

# Verify parameters restored
grep -q "vm.swappiness=10" /boot/grub/grub.cfg || {
    echo "ERROR: Kernel parameters not in GRUB config"
    exit 1
}
```

#### Pitfall 3: Debugging Boot Failures Without Serial Console Access

**Problem**: Server boot fails, no monitor attached, cannot see boot messages.

**Solution**:
```bash
# Configure serial console logging (done at boot time)

# Kernel parameter: console=ttyS0,115200
# Systemd serial console: systemctl start serial-getty@ttyS0.service

# Logs captured: /var/log/dmesg (kernel messages before syslog)
# Recovery: If filesystem writable: messages are saved for post-boot analysis
```

---

# Deep Dive: Subtopic 2 - Linux Filesystem Hierarchy & Storage

## Textual Deep Dive

### Internal Working Mechanism

#### Inode Data Structure - Memory Layout

Modern ext4 inodes are 256 bytes (in newer versions), organized as:

```
Inode Structure (ext4):
┌─────────────────────────────────────────────────────────┐
│ 0-3    │ i_mode (file type, permissions: 16 bits)       │
├─────────────────────────────────────────────────────────┤
│ 4-5    │ i_uid (32-bit UID, split across two fields)    │
├─────────────────────────────────────────────────────────┤
│ 6-9    │ i_size_lo (file size lower 32 bits)            │
├─────────────────────────────────────────────────────────┤
│ 10-13  │ i_atime (access time, seconds since epoch)      │
├─────────────────────────────────────────────────────────┤
│ 14-17  │ i_ctime (change time, metadata modification)    │
├─────────────────────────────────────────────────────────┤
│ 18-21  │ i_mtime (modify time, file content change)      │
├─────────────────────────────────────────────────────────┤
│ 22-25  │ i_dtime (deletion time, if unallocated)         │
├─────────────────────────────────────────────────────────┤
│ 26-27  │ i_gid (32-bit GID, split)                       │
├─────────────────────────────────────────────────────────┤
│ 28-29  │ i_links_count (hard link count)                 │
├─────────────────────────────────────────────────────────┤
│ 30-33  │ i_blocks (512-byte blocks allocated)            │
├─────────────────────────────────────────────────────────┤
│ 34-37  │ i_flags (ext4 flags: immutable, append-only)    │
├─────────────────────────────────────────────────────────┤
│ 38-41  │ i_version (inode generation, prevent reuse)     │
├─────────────────────────────────────────────────────────┤
│ 42-57  │ i_block[15] (direct/indirect block pointers)    │
├─────────────────────────────────────────────────────────┤
│ 58-61  │ i_generation (random gen, recovery)             │
├─────────────────────────────────────────────────────────┤
│ 62-97  │ Reserved for ACL, ext attributes                │
├─────────────────────────────────────────────────────────┤
│ 98-255 │ Extended attributes (up to 4KB of metadata)     │
└─────────────────────────────────────────────────────────┘
```

#### Block Allocation Strategy - Ext4 Extents

**Traditional Approach (Ext3)**:
```
Inode stores 15 block pointers:
├── i_block[0-11]      → Direct blocks (4KB each)
│                         = 12 × 4KB = 48KB direct
├── i_block[12]        → Singly indirect block
│                         (contains 1024 block pointers)
│                         = 1024 × 4KB = 4MB
├── i_block[13]        → Doubly indirect block
│                         (contains 1024 pointers to singly indirect)
│                         = 1024 × 4MB = 4GB
└── i_block[14]        → Triply indirect
                          = large files possible, but slow

Problem: Space overhead, fragmentation with many lookups
```

**Modern Approach (Ext4 Extents)**:
```
Inode stores extent map (extents = contiguous block ranges):

Single Extent Entry:
┌─────────────────────────────────────────┐
│ 32-bit block offset (file position)      │
│ 16-bit block count (consecutive blocks)  │
│ 48-bit physical block address            │
└─────────────────────────────────────────┘

Example: File 1GB, two extents:
  Extent 1: file blocks 0-131071 (512KB) → physical blocks 4096-135167
  Extent 2: file blocks 131072-262143 (512KB) → physical blocks 4198400-4329471

Benefits:
  ✓ Fewer lookups (one extent = up to 128MB contiguous)
  ✓ Reduced inode memory usage
  ✓ Better performance (sequential I/O)
  ✓ Automatic defragmentation during writes
```

#### Filesystem Metadata Layout

```
Physical Block Layout on Disk:

Block 0:
    ┌─────────────────────────────────┐
    │ Boot Sector (if present)        │ ← Bootloader
    └─────────────────────────────────┘

Blocks 1+:
    ┌─────────────────────────────────┐
    │ Superblock (block 1)            │ ← Filesystem parameters
    │ - Block size, inode count, etc.  │
    └─────────────────────────────────┘
    
    ┌─────────────────────────────────┐
    │ Group Descriptors               │ ← Metadata per block group
    │ - Inode table location          │
    │ - Data block bitmap location    │
    │ - Inode bitmap location         │
    └─────────────────────────────────┘
    
    ┌─────────────────────────────────┐
    │ Block Group 0                   │
    ├─────────────────────────────────┤
    │ Data Block Bitmap               │ ← Tracks which blocks allocated
    ├─────────────────────────────────┤
    │ Inode Bitmap                    │ ← Tracks which inodes allocated
    ├─────────────────────────────────┤
    │ Inode Table (256 inodes × 256B) │ ← Inode data
    ├─────────────────────────────────┤
    │ Data Blocks (file content)      │ ← Actual file data
    └─────────────────────────────────┘
    
    ... (Block Group 1, 2, 3, ...)
```

#### Mount and VFS Layer

```
VFS (Virtual Filesystem Switch) Abstraction:

Application: open("/home/alice/file.txt")
    ↓
    Kernel VFS layer receives syscall
    ↓
    Path traversal: / → home → alice → file.txt
    ├── iget(/): retrieve inode #2 (ext4 root)
    ├── iget(/home): traverse directory, find inode #123
    ├── iget(/home/alice): find inode #456
    └── iget(/home/alice/file.txt): find inode #789
    ↓
    VFS resolves: inode #789 belongs to filesystem mounted at /
    ↓
    Call ext4-specific inode_operations:
    ├── ext4_open()
    ├── ext4_read()
    ├── ext4_write()
    ↓
    Return file descriptor to user

Benefits of VFS:
    ✓ Kernel doesn't care which filesystem (ext4, xfs, nfs, tmpfs)
    ✓ Consistent API for all filesystems
    ✓ Supports multiple filesystems simultaneously
```

### Architecture Role

#### Storage Stack in Container Systems

```
Application Container (Docker)
    ↓
Overlayfs (layered filesystem)
    ├── Bottom: Read-only image layers (multiple .diff_cpio)
    ├── Middle: R/W container layer (created per container)
    └── Top: /dev, /proc, /sys virtual filesystems
    ↓
Host Filesystem (ext4 or xfs)
    ├── /var/lib/docker/overlay2/
    │   ├── [container1].../diff (layer data)
    │   ├── [container2].../diff
    │   └── ... (one directory per layer)
    ↓
Block Device
    └── /dev/sda or cloud volume
```

**Critical**: Container layer is host filesystem's problem:
- Host disk space = sum of all container layers + images
- Host inode usage = all inodes in all container layers
- File deletion in one container could be reflink, not space reclaim

### Production Usage Patterns

#### Pattern 1: Multi-Filesystem Architecture in Large Deployments

Enterprise servers typically separate:

```
Logical plan:
├── /             (root, critical binaries, config)    5GB/10GB inode
├── /home         (user data, potential growth)        100GB/unlimited inode
├── /var          (logs, caches, data)                 500GB/limited inode (prevent runaway logs)
└── /tmp          (temporary files, cleaned)           50GB/50M inode (quota)

LVM physical layout:
├── vg0-root   → ext4  5GB  → /
├── vg0-home   → ext4  100GB→ /home
├── vg0-var    → xfs   500GB→ /var        (xfs better for growth)
└── vg0-tmp    → tmpfs 50GB → /tmp        (RAM-backed, ultra-fast cleanup)
```

#### Pattern 2: Kubernetes Persistent Volume Management

Controllers must understand filesystem-level constraints:

```yaml
# Kubernetes - Monitor both blocks AND inodes
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-database
spec:
  capacity:
    storage: 1Ti           # Block size
    inodes: 10000000       # Inode limit (non-standard, app-specific)
  
  fsType: ext4
  accessModes:
    - ReadWriteOnce
  
  awsElasticBlockStore:
    volumeID: vol-12345
    fsType: ext4
```

**Inode Depletion Check** (Kubernetes CronJob):
```bash
#!/bin/bash
# check-inode-usage.sh

MOUNT_POINT=$1
THRESHOLD_PERCENT=80

INODE_USAGE=$(df -i $MOUNT_POINT | awk 'NR==2 {print $5}' | sed 's/%//')

if [ $INODE_USAGE -gt $THRESHOLD_PERCENT ]; then
    kubectl create event inode-warning \
        --type=Warning \
        --reason=InodeUsageHigh \
        --message="Inode usage $INODE_USAGE% on $MOUNT_POINT"
fi
```

#### Pattern 3: Automatic Filesystem Repair on Boot

Production systems need resilience:

```bash
# /etc/rc.d/init.d/filesystem-check (systemd service alternative)

[Unit]
Description=Filesystem Integrity Check
Before=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/e2fsck -p /dev/vg0/data

# -p = auto-repair (safe mode, no questions)
# Returns 0 (no errors) or auto-fixed
```

### DevOps Best Practices

#### Best Practice 1: Filesystem Capacity Planning Algorithm

```bash
#!/bin/bash
# capacity-planner.sh - Predict when filesystem fills

MOUNT_POINT=$1
DAYS_TO_PREDICT=30

# Get current usage trend
CURRENT_USAGE=$(df $MOUNT_POINT | awk 'NR==2 {print $3}')
WEEK_AGO_USAGE=$(du -s $MOUNT_POINT.backup.week | awk '{print $1}')

# Growth rate: blocks per day
GROWTH_RATE=$(echo "scale=0; ($CURRENT_USAGE - $WEEK_AGO_USAGE) / 7" | bc)

# Predict future usage
PROJECTED_USAGE=$(echo "scale=0; $CURRENT_USAGE + ($GROWTH_RATE * $DAYS_TO_PREDICT)" | bc)

# Get capacity
TOTAL_CAPACITY=$(df $MOUNT_POINT | awk 'NR==2 {print $2}')

if [ $PROJECTED_USAGE -gt $TOTAL_CAPACITY ]; then
    DAYS_UNTIL_FULL=$(echo "scale=0; ($TOTAL_CAPACITY - $CURRENT_USAGE) / $GROWTH_RATE" | bc)
    echo "WARNING: $MOUNT_POINT will be FULL in $DAYS_UNTIL_FULL days"
    # ACTION: Expand volume, archive data, etc.
fi
```

#### Best Practice 2: Filesystem Alignment for Cloud Storage

Cloud volumes (EBS, etc.) perform best when aligned to 4K boundaries:

```bash
# Create new partition with proper 4K alignment
parted /dev/nvme0n1 mkpart primary 0% 100%

# Create filesystem with 4K block size (modern default)
mkfs.ext4 -b 4096 -F /dev/nvme0n1p1

# Mount with optimization flags
mount -o rw,noatime,data=writeback /dev/nvme0n1p1 /data
```

#### Best Practice 3: Monitoring Script - Multi-Metric Filesystem Health

```bash
#!/bin/bash
# filesystem-health-check.sh

MOUNTPOINT=$1

BLOCK_USAGE=$(df $MOUNTPOINT | awk 'NR==2 {print $5}' | sed 's/%//')
INODE_USAGE=$(df -i $MOUNTPOINT | awk 'NR==2 {print $5}' | sed 's/%//')
FREE_BLOCKS=$(df $MOUNTPOINT | awk 'NR==2 {print $4}')

echo "Filesystem: $MOUNTPOINT"
echo "Block Usage: $BLOCK_USAGE%"
echo "Inode Usage: $INODE_USAGE%"
echo "Free Space: $FREE_BLOCKS KB"

# Alert conditions
[ $BLOCK_USAGE -gt 90 ] && echo "ALERT: Block usage CRITICAL"
[ $INODE_USAGE -gt 85 ] && echo "ALERT: Inode usage HIGH"
[ $FREE_BLOCKS -lt 10485760 ] && echo "ALERT: Less than 10GB free"

# Health check
if [ $BLOCK_USAGE -gt 90 ] || [ $INODE_USAGE -gt 85 ]; then
    # Trigger remediation
    # Example: delete old logs, archive, expand volume
    find $MOUNTPOINT/logs -mtime +90 -delete
fi
```

### Common Pitfalls

#### Pitfall 1: Ignoring Filesystem Fragmentation

**Problem**: Ext4 marked as "no fragmentation," but performance degrades over months.

**Root Cause**: While extents help, heavily written filesystems still fragment.

**Detection & Fix**:
```bash
# Check fragmentation
e4defrag -c /data

# Output: fragmentation_ratio 45.3%

# Online defragmentation (with caution)
e4defrag -v /data  # Verbose, shows progress
```

#### Pitfall 2: Mount Options Not Persisted Across Reboot

**Problem**: Admin runs `mount -o remount,noatime /data`, but disappears after reboot.

**Root Cause**: /etc/fstab not updated.

**Solution**:
```bash
# Update /etc/fstab FIRST
# Find UUID
blkid /dev/mapper/vg0-data
# UUID=a1b2c3d4-e5f6-7890

# Edit /etc/fstab
UUID=a1b2c3d4-e5f6-7890 /data ext4 rw,noatime,errors=remount-ro 0 2

# Then remount
mount -o remount,noatime /data

# Verify
mount | grep /data
```

#### Pitfall 3: Over-Provisioning Inodes at Creation, Under-Provisioning After

**Problem**: Created filesystem with 1 inode per 16KB (insufficient for many small files).

**Issue**: Cannot increase inode count without rebuild.

**Solution**:
```bash
# At creation: specify inode ratio
mke2fs -b 4096 -i 4096 /dev/sda1
# -i 4096 = 1 inode per 4096 bytes (~1M files per GB)

# For comparison:
mke2fs -b 4096 -i 16384 /dev/sda2
# -i 16384 = 1 inode per 16384 bytes (~250K files per GB)

# If error: recreate (requires backup/restore)
```

---

# Deep Dive: Subtopic 3 - Users, Groups & Permissions

## Textual Deep Dive

### Internal Working Mechanism

#### Permission Check Algorithm (Kernel Level)

When a process attempts file access, the kernel executes this algorithm:

```
File Access Request: process (UID x, GID y) requests read /etc/shadow

┌─ Lookup inode for /etc/shadow
│   inode # = 98765
│   owner UID = 0 (root)
│   owner GID = 0 (root)
│   mode bits = 0100000 (regular file)
│   permissions = 0644 (rw-r--r--)
│
├─ Check if user is root (UID 0)
│   Process UID = 1000 (alice)
│   → NOT root, continue
│
├─ Compare UIDs
│   Is process UID (1000) == file owner UID (0)?
│   → NO, check group permissions next
│
├─ Compare GIDs
│   Is process GID in file owner GID (0) OR file group?
│   → NO, check "other" permissions
│
├─ Apply "other" permission check (o=4)
│   "other" has read (r) = 4
│   Process requests read
│   4 & read = true → ALLOW read
│   BUT: read /etc/shadow would leak password hashes
│   Kernel doesn't enforce this policy (OS design choice)
│   Result: read succeeds, but no meaningful data (hashes not usable)
│
└─ Decision: ALLOW (but DAC insufficient for security)

Alternative scenario: alice writes to owned file
├─ owner UID (1000) matches process UID (1000)
├─ Apply owner permissions (u=6 = rw)
├─ write (2) & 6 = true
└─ Result: ALLOW write
```

#### Group Membership Resolution

```
User-to-Group Mapping:

1. Primary Group (from /etc/passwd)
   alice:x:1000:1000:alice:/home/alice:/bin/bash
                     ↑ primary GID = 1000

2. Supplementary Groups (from /etc/group)
   wheel:x:10:alice,bob,charlie
   docker:x:999:alice,jenkins
   developers:x:1001:alice,bob

3. Kernel Cache of Group Membership (getgroups syscall)
   When alice logs in via SSH:
   ├── PAM reads /etc/passwd (GID=1000)
   ├── PAM reads /etc/group and finds alice in lines: 10, 999, 1001
   ├── Kernel receives: setgroups([1000, 10, 999, 1001])
   └── Process token: UID=1000, GIDs=[1000, 10, 999, 1001]

4. File Access Check Using Process Token
   Access /var/lib/docker with permissions 0750 (rwxr-x---)
   owner=root(0), group=docker(999)
   
   Process token: UID=1000, GIDs=[1000, 10, 999, 1001]
   Check: is 999 in process GID list?
   → YES, use group permissions (rx) = ALLOW
```

#### ACL Evaluation Order

```
File Access with ACLs:

File: /srv/project/data.txt
Basic permissions: 0644 (rw-r--r--), owner=alice, group=wheel

ACLs applied:
user::rw-            (owner permissions)
group::r--           (group permissions)
other::r--           (other permissions)
user:bob:rwx         (specific user ACL)
group:developers:rwx (specific group ACL)
mask::rwx            (ACL mask - effective permission limit)

Access check by bob:
┌─ Is bob the file owner? NO
├─ Does bob have specific ACL entry?
│  → YES: user:bob:rwx
│  ├─ Apply mask::rwx (all bits allowed)
│  └─ Result: bob can rwx
│
└─ Final: ALLOW (request r = allowed)

Access check by charlie (in developers group, not owner):
┌─ Is charlie the file owner? NO
├─ Does charlie have specific user ACL? NO
├─ Is charlie in an ACL group?
│  → YES: group:developers:rwx
│  ├─ No mask restriction
│  └─ Result: charlie can rwx
│
└─ Final: ALLOW (request r = allowed)
```

### Architecture Role

#### Unix User Model Philosophy

```
Principle: Users are Isolated, Processes are Owned

Benefits:
├── Isolation
│   ├── User alice cannot read user bob's files (unless permissions allow)
│   ├── Process leak data only to its UID
│   └── Multi-user system prevents cross-contamination
│
├── Accountability
│   ├── Audit trail: which user performed action
│   ├── Log files show UID/PID of caller
│   └── Enables SLA/compliance tracking
│
├── Resource Limits
│   ├── System enforces per-user resource quotas
│   ├── Prevents fork bomb (single user can't crash system)
│   └── Enables fair resource sharing
│
└── Privilege Escalation Control
    ├── Sudo (controlled, logged privilege escalation)
    ├── SetUID (binary runs as owner, not caller)
    └── Capabilities (CAP_NET_ADMIN, etc. - fine-grained)
```

#### Privilege Escalation Design Patterns

```
Pattern 1: SetUID Binary (Traditional)
┌─────────────────────┐
│ /usr/bin/passwd     │ (rwsr-xr-x, owner=root)
└─────────────────────┘
         │
         ├─ User alice executes passwd
         │  Process UID = 0 (root) despite exec by alice
         │  reads/writes /etc/shadow
         └─ Limitations: all-or-nothing, difficult to restrict

Pattern 2: Sudo Wrapper (Modern)
┌──────────────────────────────────┐
│ Sudoers: alice ALL=/usr/bin/foo  │
└──────────────────────────────────┘
         │
         ├─ /usr/bin/sudo program /usr/bin/foo
         │  sudo validates /etc/sudoers
         │  logs command in /var/log/auth.log
         │  execs /usr/bin/foo as root
         └─ Benefits: auditable, restrictable (specific commands)

Pattern 3: Capabilities (Linux-specific, security hardening)
┌──────────────────────────────────┐
│ /usr/bin/ping                    │
│ cap_net_raw+ep (explicit)        │
└──────────────────────────────────┘
         │
         ├─ Non-root user runs ping
         │  Kernel grants CAP_NET_RAW capability only
         │  Process cannot escalate to full root
         └─ Benefits: minimal privilege (only ICMP needed)
```

### Production Usage Patterns

#### Pattern 1: Service Account Hierarchy

Large enterprises organize service accounts:

```
Service User Architecture:

System ROOT (UID 0)
├── Admin users (wheel group)
│   └── alice, bob (can sudo to root)
│
├── Service Accounts (system users, UID 1-999)
│   ├── nginx (UID 111)
│   │   └── runs /usr/sbin/nginx
│   │   └── accesses /var/www/html (owned by nginx)
│   │
│   ├── postgres (UID 119)
│   │   └── runs /usr/lib/postgresql/...
│   │   └── accesses /var/lib/postgresql (owned by postgres)
│   │
│   ├── prometheus (UID 121)
│   │   └── runs prometheus binary
│   │   └── reads system metrics (via CAP_SYS_ADMIN)
│   │
│   └── jenkins (UID 125)
│       └── runs Java agent
│       └── accesses /var/lib/jenkins
│
├── CI/CD Users (for builds, UID 1000+)
│   ├── buildbot
│   └── deployer
│
└── Developer Users (UID 1000-2000)
    ├── alice (1000)
    ├── bob (1001)
    └── charlie (1002)

Key property:
- Services run as dedicated low-privilege user
- No shared service accounts (cannot cross-service)
- Audit trail shows which service took action
```

#### Pattern 2: Kubernetes User-in-Container Permission Model

Kubernetes provides namespace isolation + user mapping:

```yaml
# Pod Security Policy restricts runAsUser

apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  securityContext:
    runAsUser: 65534        # nobody user (minimal privilege)
    runAsGroup: 65534
    fsGroup: 65534
    
  containers:
  - name: app
    image: myapp:latest
    
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
        add:
          - NET_BIND_SERVICE   # Only capability needed
    
    volumeMounts:
    - name: data
      mountPath: /data      # /data writable by fsGroup 65534
      readOnly: false
  
  volumes:
  - name: data
    emptyDir: {}            # Temporary volume
```

**Interaction**:
- Container process runs as UID 65534 (nobody)
- fsGroup 65534 ensures mounted volumes writable
- Cannot exploit container to modify root files (RO root)
- Cannot escalate to root (allowPrivilegeEscalation: false)

#### Pattern 3: Enterprise LDAP/AD Integration

Production systems often integrate with central directory:

```bash
# /etc/nsswitch.conf - Name Service Switch configuration

# Lookup order: local files first, then LDAP
passwd:         files ldap
group:          files ldap
shadow:         files

# When `id alice` called:
# 1. Check /etc/passwd (find nothing)
# 2. Query LDAP (find UID 1000, GIDs from LDAP groups)
# Result: alice found with LDAP directory identity
```

**Configuration** (`/etc/ldap/ldap.conf`):
```
URI ldap://ldap.company.com:389
BASE dc=company,dc=com
timeout 10
```

**Benefits**:
- Centralized user management
- Single sign-on (SSO) integration
- No local user file maintenance
- Compliance: LDAP provides audit trail of group membership

### DevOps Best Practices

#### Best Practice 1: Automated User/Group Provisioning

Infrastructure-as-Code approach:

```bash
#!/bin/bash
# provision-service-accounts.sh

# Idempotent service account creation

create_service_user() {
    local USERNAME=$1
    local UID=$2
    local HOME=$3
    
    # Check if already exists
    if id "$USERNAME" &>/dev/null; then
        echo "User $USERNAME already exists"
        return 0
    fi
    
    # Create with fixed UID (important for file ownership)
    useradd -r -u $UID -d $HOME -s /bin/nologin $USERNAME
    
    # Create home with proper permissions
    mkdir -p $HOME
    chown $UID:$UID $HOME
    chmod 0700 $HOME
    
    echo "User $USERNAME created (UID $UID)"
}

# Provision standard service accounts
create_service_user "nginx" 111 "/var/www"
create_service_user "postgres" 119 "/var/lib/postgresql"
create_service_user "prometheus" 121 "/var/lib/prometheus"
```

**Ansible Version**:
```yaml
---
- hosts: all
  become: yes
  
  vars:
    service_accounts:
      - {name: nginx, uid: 111, home: /var/www}
      - {name: postgres, uid: 119, home: /var/lib/postgresql}
      - {name: prometheus, uid: 121, home: /var/lib/prometheus}
  
  tasks:
    - name: Create service accounts
      user:
        name: "{{ item.name }}"
        uid: "{{ item.uid }}"
        home: "{{ item.home }}"
        shell: /bin/nologin
        system: yes
      loop: "{{ service_accounts }}"
```

#### Best Practice 2: Least Privilege Sudoers Design

"Command matrix" approach:

```bash
# /etc/sudoers.d/service_operators

# Group: DevOps operators who manage services
%service_operators ALL=(ALL) \
    NOPASSWD: /usr/bin/systemctl restart nginx, \
    NOPASSWD: /usr/bin/systemctl restart postgresql, \
    NOPASSWD: /usr/bin/systemctl reload-or-restart postfix, \
    NOPASSWD: /usr/bin/journalctl -u nginx -n 100, \
    PASSWD: /sbin/shutdown

# Group: Database administrators (more privileges)
%db_admins ALL=(postgres) \
    NOPASSWD: /usr/bin/pgbench, \
    NOPASSWD: /usr/bin/pg_dump

# Jenkins CI/CD service account
jenkins ALL=(root) \
    NOPASSWD: /usr/bin/docker, \
    NOPASSWD: /usr/sbin/iptables, \
    PASSWD: /sbin/reboot

# Restrictions: cannot use pipes or redirects
Defaults!/usr/bin/systemctl !use_pty
Defaults!/usr/bin/journalctl !use_pty

# Log all sudo usage
Defaults log_file="/var/log/sudo.log"
Defaults log_input,log_output
```

#### Best Practice 3: Permission Audit and Remediation Automation

```bash
#!/bin/bash
# audit-permissions.sh - Find and fix overly-permissive files

# Dangerous patterns to scan
PATTERNS=(
    '-rw-rw-rw-'     # World writable (nearly always bad)
    '----rw-rw-'     # Group/other write (often bad)  
    '-rwsr-xr-x'     # SetUID (audit risk)
)

# Remediation whitelist (files that SHOULD be world-writable)
WHITELIST=(
    '/tmp'
    '/var/tmp'
    '/dev/shm'
    '/proc'
)

# Scan for dangerous permissions
find / -type f -executable -perm /022 2>/dev/null | while read file; do
    # Check if file in whitelist
    if [[ " ${WHITELIST[@]} " =~ " ${file} " ]]; then
        continue
    fi
    
    # Found dangerous file
    echo "ALERT: Dangerous permission on $file"
    perms=$(stat -c '%a' $file)
    owner=$(stat -c '%U:%G' $file)
    
    # Log for review
    echo "$file ($owner, perms $perms)" >> /var/log/permission-audit.log
    
    # Optional: Auto-remediate (use with caution)
    # chmod o-rwx "$file"
done
```

### Common Pitfalls

#### Pitfall 1: Shared Service Accounts

**Problem**:
```bash
# DANGEROUS: Multiple services running as same user
useradd -r -s /bin/bash shared_service

# Both nginx and postgres run as shared_service (UID 500)
```

**Issue**: 
- Compromise of nginx process can read postgres private data
- Cannot isolate which service created a file
- Audit trail unclear

**Solution**: Dedicated user per service
```bash
useradd -r -u 111 -s /bin/nologin nginx
useradd -r -u 119 -s /bin/nologin postgres
```

#### Pitfall 2: Root-Owned /tmp Files

**Problem**: Attacker creates sticky file in /tmp:
```bash
# Attacker creates privileged file in /tmp
touch /tmp/malicious
chmod 0755 /tmp/malicious
# Now other users cannot delete it (sticky bit protects root-owned files)
# Fills up /tmp, causing system issues
```

**Solution**: Regular cleanup script
```bash
# /etc/cron.daily/clean-tmp.sh
#!/bin/bash
find /tmp -type f -atime +7 -delete  # Delete unused after 7 days
find /tmp -type d -empty -delete     # Remove empty dirs
```

#### Pitfall 3: Forgetting to Update Group Membership

**Problem**:
```bash
# Add user to group
usermod -aG docker alice

# User logs in immediately
alice$ docker ps
permission denied: /var/run/docker.sock

# Why? SSH session started before group change registered
```

**Root Cause**: Group membership cached at login.

**Solution**:
```bash
# Option 1: Logout and login
# Option 2: Start new shell to re-evaluate groups
alice$ newgrp docker
# Option 3: Check current groups
alice$ id
uid=1000(alice) gid=1000(alice) groups=1000(alice),999(docker)
#                                                    ← now visible
```

---

## Summary & Key Takeaways

This study guide covered three critical pillars of Linux administration essential for senior DevOps engineers:

1. **Linux Architecture & Boot Process**: Understanding kernel architecture, boot sequence (BIOS/UEFI/systemd), and recovery procedures
2. **Filesystem Hierarchy & Storage**: Managing inodes, filesystems (ext4/xfs), mounts, and storage performance
3. **Users, Groups & Permissions**: Implementing least-privilege access, secure delegation via sudoers, and audit trails

These are foundational skills for:
- **Infrastructure Reliability**: Troubleshoot boot failures, storage issues, permission errors
- **Security Hardening**: Implement least privilege, manage user access, audit privilege escalation
- **Production Operations**: Capacity planning, performance optimization, disaster recovery
- **Container Orchestration**: Understanding node boot, volume mounting, permission mapping in Kubernetes

For continued learning, practice hands-on scenarios in test environments, study production incidents involving these topics, and maintain deep understanding of real-world failure modes.

