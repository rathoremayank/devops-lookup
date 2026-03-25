# Project File Index & Navigation Guide

**Last Updated:** 2024
**Project:** Modular Kubernetes on AWS with Terraform

---

## Quick Navigation

### 🚀 Getting Started
1. [README.md](#readme) - Start here for project overview
2. [QUICKSTART.md](#quickstart) - 9 steps to deployment
3. [ARCHITECTURE.md](#architecture) - Understand the design

### 📦 Deployment
4. [Terraform Modules](#terraform-modules) - Core infrastructure code
5. [Environment Configuration](#environment-configuration) - Dev/Prod setup
6. [Bootstrap Scripts](#bootstrap-scripts) - Node initialization

### 🔧 Backend & Operations
7. [BACKEND_SETUP.md](#backend-setup) - Remote state setup
8. [scripts/setup-remote-state.sh](#setup-scripts) - Backend automation
9. [scripts/cleanup-remote-state.sh](#cleanup-scripts) - Destruction automation

### 🧹 Cleanup & Maintenance
10. [CLEANUP_GUIDE.md](#cleanup-guide) - Comprehensive cleanup procedure
11. [CLEANUP_QUICK_REFERENCE.md](#cleanup-quick-reference) - Quick commands
12. [CLEANUP_SAFETY_CHECKLIST.md](#cleanup-safety-checklist) - Team sign-off

### 📚 Additional Resources
13. [scripts/README.md](#scripts-readme) - Script documentation
14. [SUMMARY.md](#summary) - Project summary
15. [MANIFEST.md](#manifest) - Complete file listing

---

## Complete File Reference

### Root Directory Files

#### README.md {#readme}
```
Location: ./README.md
Size: ~375 lines
Purpose: Main project documentation and overview
Contains:
  - Project structure overview
  - Module descriptions
  - Usage instructions (7 steps)
  - Security considerations
  - Troubleshooting guide
  - Customization examples
When to use:
  - First time reading about the project
  - Understanding overall architecture
  - Learning deployment process
```

#### QUICKSTART.md {#quickstart}
```
Location: ./QUICKSTART.md
Size: ~200 lines
Purpose: 9-step quick deployment guide
Contains:
  - Prerequisites checklist
  - Variable configuration
  - Terraform initialization
  - Deployment execution
  - Cluster verification
  - Access instructions
When to use:
  - Need fastest path to deployment
  - Want step-by-step walkthrough
  - Testing deployment process
```

#### ARCHITECTURE.md {#architecture}
```
Location: ./ARCHITECTURE.md
Size: ~300 lines
Purpose: Detailed architecture documentation
Contains:
  - Network design (VPC, subnets, routing)
  - Compute architecture (EC2 provisioning)
  - Kubernetes cluster setup
  - Security group rules
  - Data flow diagrams (text-based)
  - Design decisions and rationale
When to use:
  - Understanding system design
  - Reviewing security architecture
  - Planning modifications
  - Explaining to stakeholders
```

#### BACKEND_SETUP.md {#backend-setup}
```
Location: ./BACKEND_SETUP.md
Size: ~600 lines
Purpose: Complete S3 + DynamoDB remote state setup
Contains:
  - Why remote state is important
  - S3 bucket creation steps
  - DynamoDB table creation
  - Backend configuration
  - Troubleshooting
  - Best practices
When to use:
  - Setting up remote state for team
  - Understanding state management
  - Configuring new environment
  - Troubleshooting state issues
```

#### CLEANUP_GUIDE.md {#cleanup-guide}
```
Location: ./CLEANUP_GUIDE.md
Size: ~700 lines
Purpose: ⚠️ Complete guide for cleaning up backend resources
Contains:
  - When to cleanup (good/bad reasons)
  - Pre-cleanup checklist
  - Backup procedures
  - Step-by-step cleanup process (Linux/Windows)
  - Troubleshooting cleanup issues
  - Recovery procedures
  - Post-cleanup actions
  - Cost implications
When to use:
  - BEFORE running any cleanup
  - Planning resource destruction
  - Understanding cleanup implications
  - Recovering from mistakes
```

#### CLEANUP_QUICK_REFERENCE.md {#cleanup-quick-reference}
```
Location: ./CLEANUP_QUICK_REFERENCE.md
Size: ~300 lines
Purpose: Print-friendly quick reference for cleanup commands
Contains:
  - Pre-cleanup checklist (1 page)
  - Quick cleanup commands (Windows/Linux)
  - Command parameters reference
  - Verification commands
  - Common mistakes
  - Emergency recovery procedures
When to use:
  - Quick command lookup
  - Print as reference card
  - Keep at desk during cleanup
  - Training team members
```

#### CLEANUP_SAFETY_CHECKLIST.md {#cleanup-safety-checklist}
```
Location: ./CLEANUP_SAFETY_CHECKLIST.md
Size: ~500 lines
Purpose: Team-based cleanup verification checklist
Contains:
  - 11-section structured checklist
  - Pre-cleanup verification
  - Team sign-off section
  - Execution verification
  - Post-cleanup verification
  - Incident response procedures
  - Lessons learned section
  - Emergency contacts
When to use:
  - Team cleanup operations
  - Need formal approval process
  - Compliance/auditing requirements
  - Critical infrastructure cleanup
```

#### SUMMARY.md {#summary}
```
Location: ./SUMMARY.md
Size: ~250 lines
Purpose: Project summary and reference
Contains:
  - Module overview
  - File listing
  - Configuration reference
  - Troubleshooting quick tips
  - Common tasks
When to use:
  - Quick reference of project
  - Finding specific configuration
  - Troubleshooting common issues
```

#### MANIFEST.md {#manifest}
```
Location: ./MANIFEST.md
Size: ~400 lines
Purpose: Complete file manifest with descriptions
Contains:
  - Every file in the project
  - Line counts
  - Purpose of each file
  - Key implementation details
When to use:
  - Understanding all files
  - Finding specific logic
  - Code review preparation
```

#### .gitignore
```
Location: ./.gitignore
Size: ~150 lines
Purpose: Git ignore patterns for repository root
Contains:
  - State file patterns (*.tfstate*)
  - Terraform cache patterns (.terraform/)
  - AWS credential patterns
  - IDE patterns (.DS_Store, .idea/, etc.)
  - OS patterns (node_modules/, etc.)
When to use:
  - Preventing accidental commits
  - Understanding what's tracked
  - Adding new exclude patterns
```

#### Makefile
```
Location: ./Makefile
Size: ~100 lines
Purpose: Convenient commands for terraform operations
Contains:
  - terraform validate
  - terraform plan
  - terraform apply
  - terraform destroy
  - backend-setup (S3 + DynamoDB)
  - backend-clean (cleanup)
When to use:
  - Quick terraform commands: make plan
  - Backend operations: make backend-setup
  - Remembering command syntax
```

#### example.tfvars
```
Location: ./example.tfvars
Size: ~50 lines
Purpose: Example Terraform variables file
Contains:
  - AWS region
  - EC2 key pair name
  - Instance types
  - CIDR blocks
  - Example values with placeholders
When to use:
  - Understanding variables
  - Creating new tfvars file
  - Template for configuration
```

---

### Terraform Modules {#terraform-modules}

Location: `./modules/`

#### Module: networking

```
Purpose: AWS VPC networking infrastructure
Files:
  - main.tf        (~150 lines) - VPC, subnets, security groups
  - variables.tf   (~50 lines)  - Input variable declarations
  - outputs.tf     (~30 lines)  - Output values reference

Resources Created:
  - VPC (10.0.0.0/16)
  - Public Subnets (2x)
  - Private Subnets (2x)
  - Internet Gateway
  - NAT Gateways (2x)
  - Route Tables
  - Security Groups (Master, Worker, Internal)

Key Outputs:
  - vpc_id
  - public_subnet_ids
  - private_subnet_ids
  - master_security_group_id
  - worker_security_group_id

When to modify:
  - Changing CIDR blocks
  - Adjusting number of subnets
  - Modifying security group rules
  - Adding new network policies
```

#### Module: ec2

```
Purpose: EC2 instance provisioning and configuration
Files:
  - main.tf        (~100 lines) - Instance provisioning
  - variables.tf   (~40 lines)  - Input variables
  - outputs.tf     (~20 lines)  - Output values

Resources Created:
  - EC2 Instance
  - Elastic IP (EIP)
  - EBS Volume (encrypted)
  - Security Group attachment

Key Outputs:
  - instance_id
  - instance_private_ip
  - instance_public_ip
  - instance_dns

When to modify:
  - Changing instance types
  - Modifying storage configuration
  - Updating security group rules
  - Adding IAM roles
```

#### Module: kubernetes

```
Purpose: Kubernetes cluster initialization and setup
Files:
  - main.tf        (~80 lines)  - Bootstrap script generation
  - variables.tf   (~50 lines)  - Input variables
  - outputs.tf     (~15 lines)  - Output values
  - scripts/
    - common-bootstrap.sh  (~100 lines) - Docker/K8s install
    - master-init.sh       (~80 lines)  - Master setup
    - worker-init.sh       (~70 lines)  - Worker setup

Bootstrap Scripts:
  - common-bootstrap.sh: Docker, kubelet, kubeadm installation
  - master-init.sh: kubeadm init, Calico CNI, token generation
  - worker-init.sh: kubeadm join, node readiness

Key Outputs:
  - bootstrap_config
  - join_command

When to modify:
  - Changing Kubernetes version
  - Modifying CNI (Calico) configuration
  - Adjusting CIDR ranges (Pod, Service)
  - Adding additional software to bootstrap
```

---

### Environment Configuration {#environment-configuration}

Location: `./environments/dev/` and `./environments/prod/`

#### versions.tf

```
Location: ./environments/dev/versions.tf
Size: ~30 lines
Purpose: Terraform and provider version specifications
Contains:
  - Terraform version constraint (>= 1.0)
  - AWS provider version (~> 5.0)
  - S3 backend configuration (commented out by default)

Key Section:
  - Backend configuration for S3 + DynamoDB
  - Encryption settings
  - State locking configuration

When to modify:
  - Updating Terraform version
  - Changing provider version
  - Enabling remote state
```

#### main.tf

```
Location: ./environments/dev/main.tf
Size: ~100+ lines
Purpose: Module instantiation and local configuration
Contains:
  - Module declarations for networking, EC2, kubernetes
  - Local variables
  - Data sources (Ubuntu AMI lookup)
  - Variable mappings

Key Sections:
  - Networking module call
  - Master EC2 instance
  - Worker EC2 instance(s)
  - Output aggregation

When to modify:
  - Adding more worker nodes
  - Changing module configuration
  - Modifying local variables
  - Updating count/for_each logic
```

#### variables.tf

```
Location: ./environments/dev/variables.tf
Size: ~80 lines
Purpose: Variable declarations for environment
Contains:
  - aws_region
  - ec2_key_pair_name
  - Instance types
  - CIDR blocks
  - Kubernetes configuration

When to modify:
  - Adding new variables
  - Changing default values
  - Updating descriptions
```

#### outputs.tf

```
Location: ./environments/dev/outputs.tf
Size: ~50+ lines
Purpose: Output values exposed to users
Contains:
  - Master/Worker IPs
  - SSH commands
  - Kubernetes cluster info
  - VPC/Network info

When to modify:
  - Adding new outputs
  - Calculating derived values
  - Improving output formatting
```

#### terraform.tfvars

```
Location: ./environments/dev/terraform.tfvars
Size: ~20 lines
Purpose: Default variable values
Contains:
  - Region: us-east-1
  - Key pair name
  - Instance types
  - CIDR allocations

When to modify:
  - Setting deployment values
  - Changing region
  - Adjusting instance sizes
  - Modifying network ranges
```

#### backend-dev.tfbackend

```
Location: ./environments/dev/backend-dev.tfbackend
Size: ~10 lines
Purpose: Backend configuration template
Contains:
  - Bucket name
  - Key path
  - Region
  - DynamoDB table name

When to use:
  - terraform init -backend-config=backend-dev.tfbackend
  - Setting up remote state
```

#### backend-prod.tfbackend

```
Location: ./environments/prod/backend-prod.tfbackend
Size: ~10 lines
Purpose: Production backend configuration template
Contains:
  - Production bucket name
  - Production key path
  - Production table name

When to use:
  - Production deployments
  - Separate state management
```

---

### Bootstrap Scripts {#bootstrap-scripts}

Location: `./modules/kubernetes/scripts/`

#### common-bootstrap.sh

```
Location: ./modules/kubernetes/scripts/common-bootstrap.sh
Size: ~100 lines
Purpose: Common setup for all Kubernetes nodes
Contains:
  - Docker installation and configuration
  - Kubernetes package installation (kubeadm, kubelet, kubectl)
  - System configuration (sysctl, modules)
  - CRI socket configuration
  - kubeadm initialization

Executes on:
  - Master node (step 1 of 2)
  - Worker node (step 1 of 2)

When to modify:
  - Changing Kubernetes version
  - Adding additional packages
  - Updating Docker configuration
  - Adjusting system parameters
```

#### master-init.sh

```
Location: ./modules/kubernetes/scripts/master-init.sh
Size: ~80 lines
Purpose: Master node initialization
Contains:
  - kubeadm init with Calico settings
  - kubeconfig setup
  - Calico CNI networking plugin installation
  - Join token generation
  - Cluster readiness checks

Executes on:
  - Master node only (step 2 of 2)

Output Generates:
  - Join command for worker nodes
  - kubeconfig file
  - Admin credentials

When to modify:
  - Changing CNI plugin (Calico to Flannel, etc.)
  - Adjusting pod network CIDR
  - Adding control plane addons
  - Modifying cluster initialization parameters
```

#### worker-init.sh

```
Location: ./modules/kubernetes/scripts/worker-init.sh
Size: ~70 lines
Purpose: Worker node initialization
Contains:
  - Wait for master to be ready
  - Verify master connectivity
  - kubeadm join command execution
  - kubelet verification
  - Node readiness confirmation

Executes on:
  - Worker node only (step 2 of 2)

Depends on:
  - Master node must be initialized first
  - Join command from master (passed via Terraform)

When to modify:
  - Changing join timeout values
  - Adjusting pre-join checks
  - Adding post-join verification
```

---

### Scripts Directory {#cleanup-scripts}

Location: `./scripts/`

#### setup-remote-state.sh

```
Location: ./scripts/setup-remote-state.sh
Size: ~200 lines
Purpose: Create S3 bucket and DynamoDB table for remote state
Type: Bash script (Linux/macOS)
Prerequisites:
  - AWS CLI installed and configured
  - IAM permissions for S3 and DynamoDB

Execution:
  bash scripts/setup-remote-state.sh [BucketName] [TableName] [Region]

Creates:
  - S3 bucket with versioning and encryption
  - DynamoDB table with on-demand billing

When to use:
  - Initial remote state setup
  - Multiple environment deployments
  - Team collaboration setup
```

#### setup-remote-state.ps1

```
Location: ./scripts/setup-remote-state.ps1
Size: ~200 lines
Purpose: Create S3 bucket and DynamoDB table for remote state
Type: PowerShell script (Windows)
Prerequisites:
  - AWS CLI installed and configured
  - PowerShell 5.0+
  - IAM permissions for S3 and DynamoDB

Execution:
  .\scripts\setup-remote-state.ps1 -BucketName "..." -TableName "..."

Creates:
  - S3 bucket with versioning and encryption
  - DynamoDB table with on-demand billing

When to use:
  - Initial remote state setup (Windows)
  - Team collaboration setup
  - Corporate environments
```

#### cleanup-remote-state.sh {#cleanup-scripts}

```
Location: ./scripts/cleanup-remote-state.sh
Size: ~95 lines
Purpose: ⚠️ Delete S3 bucket and DynamoDB table (PERMANENT)
Type: Bash script (Linux/macOS)
Prerequisites:
  - AWS CLI installed and configured
  - IAM permissions to delete S3 and DynamoDB
  - Remote state not in use

Execution (Interactive):
  bash scripts/cleanup-remote-state.sh terraform-state-dev

Execution (Force):
  bash scripts/cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true

Actions:
  1. Creates backup of state files
  2. Lists S3 objects to delete
  3. Prompts for confirmation (type 'yes')
  4. Deletes all S3 versions
  5. Deletes S3 bucket
  6. Deletes DynamoDB table
  7. Verifies deletion

Safety Features:
  - Automatic backup creation
  - Interactive confirmation
  - Verification after deletion
  - Error handling

WARNINGS:
  - ⚠️ Permanently deletes state
  - ⚠️ Cannot be undone
  - ⚠️ Run terraform destroy first

When to use:
  - Decommissioning infrastructure
  - Migrating backends
  - Cleaning up test deployments
  - **READ CLEANUP_GUIDE.md FIRST**
```

#### cleanup-remote-state.ps1

```
Location: ./scripts/cleanup-remote-state.ps1
Size: ~155 lines
Purpose: ⚠️ Delete S3 bucket and DynamoDB table (PERMANENT)
Type: PowerShell script (Windows)
Prerequisites:
  - AWS CLI installed and configured
  - PowerShell 5.0+
  - IAM permissions to delete S3 and DynamoDB
  - Remote state not in use

Execution (Interactive):
  .\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"

Execution (Force):
  .\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Force

Actions:
  1. Creates backup of state files
  2. Lists S3 objects to delete
  3. Prompts for confirmation (colorized)
  4. Deletes all S3 versions
  5. Deletes S3 bucket
  6. Deletes DynamoDB table
  7. Verifies deletion

Safety Features:
  - Automatic backup creation
  - Interactive confirmation with color
  - Verification after deletion
  - Comprehensive error handling
  - Helpful next-step guidance

WARNINGS:
  - ⚠️ Permanently deletes state
  - ⚠️ Cannot be undone
  - ⚠️ Run terraform destroy first

When to use:
  - Decommissioning infrastructure (Windows)
  - Migrating backends
  - Cleaning up test deployments
  - **READ CLEANUP_GUIDE.md FIRST**
```

#### README.md {#scripts-readme}

```
Location: ./scripts/README.md
Size: ~480 lines
Purpose: Comprehensive script documentation
Contains:
  - Script overview and purpose
  - Setup script documentation (create backend)
  - Cleanup script documentation (delete backend)
  - Prerequisites and requirements
  - Troubleshooting procedures
  - Safety features explanation
  - Related documentation links

When to use:
  - Understanding script functionality
  - Troubleshooting script issues
  - Learning script parameters
  - Understanding safety features
```

---

## File Organization Map

```
0_tf_working_examples/
│
├── 📄 README.md                          [Main documentation]
├── 📄 QUICKSTART.md                      [9-step deployment guide]
├── 📄 ARCHITECTURE.md                    [System design documentation]
├── 📄 BACKEND_SETUP.md                   [Remote state setup]
├── 📄 CLEANUP_GUIDE.md                   [Cleanup procedure (READ FIRST!)]
├── 📄 CLEANUP_QUICK_REFERENCE.md         [Print-friendly quick reference]
├── 📄 CLEANUP_SAFETY_CHECKLIST.md        [Team verification checklist]
├── 📄 SUMMARY.md                         [Project summary]
├── 📄 MANIFEST.md                        [File manifest]
├── 📄 .gitignore                         [Git ignore patterns]
├── 📄 Makefile                           [Convenient commands]
├── 📄 example.tfvars                     [Example configuration]
│
├── 📁 modules/                           [Terraform modules]
│   ├── 📁 networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── 📁 ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── 📁 kubernetes/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── scripts/
│           ├── common-bootstrap.sh
│           ├── master-init.sh
│           └── worker-init.sh
│
├── 📁 environments/
│   ├── 📁 dev/
│   │   ├── versions.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   └── backend-dev.tfbackend
│   └── 📁 prod/
│       └── backend-prod.tfbackend
│
├── 📁 scripts/
│   ├── setup-remote-state.sh             [Create backend (bash)]
│   ├── setup-remote-state.ps1            [Create backend (PowerShell)]
│   ├── cleanup-remote-state.sh           [Delete backend (bash)]
│   ├── cleanup-remote-state.ps1          [Delete backend (PowerShell)]
│   └── README.md                         [Script documentation]
│
└── 📁 state-backups/                     [Auto-generated backup dir]
    └── state-backup-TIMESTAMP.zip        [Automatic backups]
```

---

## Usage Flowcharts

### First Time Setup
```
1. README.md          ← Start here
   ↓
2. QUICKSTART.md      ← 9-step walkthrough
   ↓
3. ARCHITECTURE.md    ← Understand design
   ↓
4. Edit terraform.tfvars
   ↓
5. terraform apply
   ↓
6. ✅ Cluster running
```

### Backend Setup
```
1. BACKEND_SETUP.md               ← Read procedure
   ↓
2. Run setup script:
   - bash script (Linux/macOS)
   - PowerShell script (Windows)
   ↓
3. Edit backend-dev.tfbackend
   ↓
4. terraform init -backend-config=...
   ↓
5. ✅ Remote state active
```

### Cleanup Process
```
1. CLEANUP_GUIDE.md               ← READ FIRST (mandatory!)
   ↓
2. CLEANUP_SAFETY_CHECKLIST.md    ← Complete checklist
   ↓
3. CLEANUP_QUICK_REFERENCE.md     ← Quick commands
   ↓
4. terraform destroy              ← Destroy infrastructure first!
   ↓
5. Run cleanup script:
   - bash script (Linux/macOS)
   - PowerShell script (Windows)
   ↓
6. Verify deletion
   ↓
7. ✅ Backend resources deleted
```

### Troubleshooting
```
Issue occurs
   ↓
1. Check README.md Troubleshooting section
   ↓
2. Check SUMMARY.md common issues
   ↓
3. Check scripts/README.md for script issues
   ↓
4. Check ARCHITECTURE.md for design issues
   ↓
5. Manual AWS CLI verification
   ↓
6. Contact team lead if unresolved
```

---

## Finding Specific Information

| What are you looking for? | Where to find it |
|---|---|
| How to deploy? | QUICKSTART.md → Sections 1-8 |
| How does networking work? | ARCHITECTURE.md → Network Design |
| How does Kubernetes init work? | ARCHITECTURE.md → Kubernetes Setup |
| How to setup remote state? | BACKEND_SETUP.md or setup-remote-state.sh |
| How to cleanup backend? | CLEANUP_GUIDE.md (important!) |
| Quick cleanup commands? | CLEANUP_QUICK_REFERENCE.md |
| Team cleanup approval? | CLEANUP_SAFETY_CHECKLIST.md |
| What's in each module? | MANIFEST.md or individual main.tf files |
| How to add more workers? | ARCHITECTURE.md → Scaling |
| Security concerns? | ARCHITECTURE.md → Security |
| Troubleshooting issues? | README.md → Troubleshooting section |
| Bootstrap logic? | modules/kubernetes/scripts/*.sh |
| Terraform variables? | environments/dev/variables.tf |
| Network ranges? | environments/dev/terraform.tfvars |
| All available outputs? | environments/dev/outputs.tf |

---

## File Size Summary

| Category | File Count | Total Size |
|----------|-----------|-----------|
| Documentation | 9 files | ~3,500 lines |
| Terraform Modules | 9 files | ~1,200 lines |
| Environment Config | 6 files | ~300 lines |
| Bootstrap Scripts | 3 files | ~250 lines |
| Operational Scripts | 5 files | ~700 lines |
| Configuration | 3 files | ~200 lines |
| **TOTAL** | **35+ files** | **~6,150+ lines** |

---

## Best Practices for Navigation

✅ **DO:**
- Start with README.md for overview
- Read CLEANUP_GUIDE.md before any cleanup
- Use QUICKSTART.md for quick path to deployment
- Check ARCHITECTURE.md before major changes
- Use CLEANUP_QUICK_REFERENCE.md for command lookup
- Keep CLEANUP_SAFETY_CHECKLIST.md for team ops

❌ **DON'T:**
- Skip documentation (especially CLEANUP_GUIDE.md)
- Directly edit bootstrap scripts without understanding
- Run cleanup scripts without backup
- Make changes without reading comments
- Mix environment configurations

---

**This index was designed to help you quickly find what you need. Bookmark this page!**

