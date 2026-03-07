# Terraform CLI Workflow: Senior DevOps Study Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Terraform Init/Plan/Apply/Destroy Workflow & Commands](#terraform-initplanapplydestroy-workflow--commands)
4. [Terraform Workspaces and Variable Injection](#terraform-workspaces-and-variable-injection)
5. [Hands-on Scenarios](#hands-on-scenarios)
6. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic: Terraform CLI Workflow

The Terraform CLI (Command Line Interface) is the primary interaction mechanism for Infrastructure as Code (IaC) practitioners. The CLI workflow represents the operational runtime model for Terraform—how practitioners define, preview, apply, and manage infrastructure changes throughout the lifecycle of cloud resources.

For senior DevOps engineers, understanding the Terraform CLI workflow extends beyond basic command execution. It encompasses:

- **State management strategies** and their implications for team collaboration
- **Operational safety patterns** that prevent destructive changes in production
- **Orchestration patterns** for multi-environment deployments
- **Performance optimization** across large infrastructure codebases
- **Compliance and auditability** in enterprise environments

### Real-World Production Use Cases

#### 1. **Blue-Green Deployments with Workspace Isolation**
Organizations managing multi-region deployments use Terraform workspaces to isolate state per environment while maintaining identical code. A production scenario might involve:
- Development, staging, and production workspaces with separate state files
- Automated CI/CD pipelines that execute `terraform plan` with approval gates before `terraform apply`
- Disaster recovery workflows using `terraform state` commands to migrate infrastructure between regions

#### 2. **Dynamic Resource Provisioning in Enterprise Environments**
Large enterprises with hundreds of services use variable injection to parameterize infrastructure:
- Central platform teams define reusable Terraform modules with variable inputs
- Service teams override variables via `.tfvars` files or environment variables
- Automation systems inject variables computed from external systems (service catalogs, CMDB, etc.)

#### 3. **Compliance and Audit Logging**
Regulated industries (finance, healthcare, government) require complete audit trails:
- Every `terraform apply` is logged with initiator, timestamp, and exact changes
- `terraform graph` outputs are analyzed for compliance violations
- `terraform validate` is integrated into CI/CD to catch misconfigurations before human review

#### 4. **Cost Optimization Through Resource Lifecycle Management**
DevOps teams use `terraform destroy` systematically:
- Ephemeral infrastructure (CI/CD agents, batch processing clusters) are destroyed after use
- Scheduled terraform runs delete unused resources based on tags and age
- State files are analyzed to identify resources marked for deprecation

### Where It Appears in Cloud Architecture

Terraform CLI workflow sits at the intersection of multiple architectural layers:

```
┌─────────────────────────────────────────────┐
│  CI/CD Orchestration (Jenkins, GitLab, etc)│
│           ↓                                  │
│  Terraform CLI (init/plan/apply/destroy)   │ ← YOU ARE HERE
│           ↓                                  │
│  Cloud APIs (AWS, Azure, GCP)               │
│           ↓                                  │
│  Infrastructure State (Remote Backend)      │
└─────────────────────────────────────────────┘
```

In enterprise architectures:
- **Developer experience layer**: Local development using Terraform modules with local state
- **Integration layer**: CI/CD systems invoke Terraform CLI with remote backends
- **Governance layer**: Policy as Code (Sentinel, OPA) gates are applied during `terraform apply`
- **Operational layer**: Teams use `terraform state` commands for emergency remediation

---

## Foundational Concepts

### Core Architecture Principles

#### 1. **Declarative Infrastructure Model**
Terraform operates on a declarative paradigm:
- You describe the **desired state** (HCL configuration files)
- Terraform compares it against **current state** (state file)
- Terraform generates an **execution plan** showing required changes
- Changes are applied atomically (all-or-nothing semantics where possible)

This contrasts with imperative approaches where you explicitly script each step. The declarative model provides:
- **Idempotency**: Running the same configuration twice produces the same result
- **Traceability**: Code explicitly documents infrastructure
- **Rollback capability**: Previous configurations can be reapplied

**DevOps Principle**: The combination of source-controlled HCL + state file creates a complete audit trail of infrastructure evolution.

#### 2. **State as Single Source of Truth**
The Terraform state file (typically `terraform.tfstate`) is critical:
- Records the **mapping between HCL resources and cloud provider resources**
- Contains **resource attributes** (instance IDs, security group rules, etc.)
- Enables **dependency tracking** to determine application order

Example: Without state, Terraform cannot determine if an EC2 instance already exists—it would attempt to create duplicates.

**Critical Understanding**: State is not documentation—it is operational data required for Terraform to function. Loss of state requires manual reconciliation.

#### 3. **Workflow Immutability and Idempotency**
The Terraform CLI workflow enforces idempotency:

```
terraform init    → Initialize working directory (safe, idempotent)
terraform plan    → Preview changes (read-only, can run multiple times)
terraform apply   → Execute changes (idempotent, only changes difference)
terraform plan    → Re-run after apply shows no further changes (safe verification)
```

Running `terraform plan` 100 times produces identical output until actual infrastructure changes occur externally.

#### 4. **Dependency Resolution and Graph Theory**
Terraform builds a **resource dependency graph**:
- Extracts dependencies from resource attributes and interpolations
- Uses topological sorting to determine application order
- Enables **parallelization**: Resources with no dependencies apply simultaneously

Example:
```hcl
resource "aws_security_group" "app" {
  name = "app-sg"
}

resource "aws_instance" "app" {
  security_groups = [aws_security_group.app.id]  # ← Creates dependency
}
```

Terraform will always create the security group before the instance, even if not explicitly ordered in code.

### Important DevOps Principles

#### 1. **Separation of Concerns: Code, Configuration, and State**
- **Code** (HCL files): Source control, versioned, reviewed
- **Configuration** (variables, .tfvars): Environment-specific, may contain secrets
- **State** (terraform.tfstate): Remote backend, encrypted, access-controlled

Violation of this principle leads to security breaches and operational chaos.

#### 2. **Least Privilege Access**
Senior teams implement:
- **IAM roles** for CI/CD systems with minimal required permissions
- **Backend access control**: Only authorized personas can read/write state
- **Audit logging**: Every state modification is traceable

#### 3. **Plan-Before-Action Governance**
Production deployments follow:
1. Developer runs `terraform plan` locally
2. Changes are committed to source control
3. CI/CD system runs `terraform plan` against production state
4. Humans review the plan output
5. Approval triggers `terraform apply`

This prevents accidental destructive changes—the `terraform plan` output is the contract before action.

#### 4. **Stateless Execution, Stateful Infrastructure**
Terraform CLI itself is stateless (can run from any machine), but infrastructure state is centralized:
- Multiple team members can run Terraform against the same state backend
- Locking mechanisms prevent concurrent modifications
- This enables **true infrastructure-as-code collaboration**

### Best Practices

#### 1. **Remote State Management**
Never use local state in production:
```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

Benefits:
- Centralized state accessible to entire team
- DynamoDB table provides state locking (prevents concurrent modifications)
- S3 versioning enables state history and rollback

#### 2. **Variable Injection Strategy**
Use layered variable injection:
```bash
# Base variables
terraform apply -var-file="base.tfvars" \
  # Environment-specific overrides
  -var-file="prod.tfvars" \
  # Runtime overrides
  -var="instance_count=5" \
  # Secret injection via environment
  -var="db_password=$DB_PASSWORD"
```

This pattern maintains separation of concerns and enables automation.

#### 3. **Workspace Organization**
Workspaces should align with organizational boundaries:
- Per-environment workspaces (dev, staging, prod)
- Per-team workspaces (platform, data-pipeline, ml-ops)
- Never mix multiple production services in a single workspace

#### 4. **Plan Output Analysis Before Apply**
Critical resources warrant additional scrutiny:
```bash
terraform plan -out=tfplan
# Human reviews tfplan output
terraform apply tfplan
```

The `-out` flag ensures the exact plan is applied (prevents drift between plan and apply).

#### 5. **Version Pinning in Production**
Modules and providers should be pinned to specific versions:
```hcl
terraform {
  required_version = "~> 1.5"
}

required_providers {
  aws = {
    source  = "hashicorp/aws"
    version = "~> 5.20"
  }
}
```

Prevents unexpected behavior from provider updates that introduce breaking changes.

### Common Misunderstandings (Senior-Level)

#### Misunderstanding 1: "State File is Just a Cache"
**Reality**: State is operational data, not a cache. Losing state means:
- Terraform cannot identify which resources it manages
- You cannot run `terraform destroy` (would not know what to destroy)
- Manual intervention required to reconcile infrastructure

**Implication**: State backup and recovery is a critical operational concern, not optional.

#### Misunderstanding 2: "Workspaces Provide Complete Isolation"
**Reality**: Workspaces share:
- Terraform code base
- Backend configuration
- Provider credentials

Workspaces are a **state file naming mechanism**, not a security boundary. A developer with access to one workspace could technically access others if backend permissions are misconfigured.

**Implication**: For true isolation (e.g., dev vs. prod), use separate AWS accounts with separate IAM roles, not just workspaces.

#### Misunderstanding 3: "`terraform destroy` is Unsafe, Don't Use It"
**Reality**: Destruction is sometimes necessary and safe when used correctly:
- Ephemeral infrastructure (test environments, CI agents) should be destroyed
- `terraform destroy` is safer than manual deletion (ensures all associated resources are cleaned)

**Implication**: The risk is not the command itself, but using it without proper safeguards (approval gates, confirmation prompts, dry-runs).

#### Misunderstanding 4: "Terraform Parallelizes Everything"
**Reality**: Terraform respects explicit and implicit dependencies. Unrelated resources may apply slowly if:
- Provider API limits are hit
- Database operations block subsequent resources
- Network operations incur latency

**Implication**: Dependency analysis is part of performance tuning, not something Terraform handles automatically in all scenarios.

#### Misunderstanding 5: "`terraform plan` Output is Deterministic Across Runs"
**Reality**: Plan output can differ between runs due to:
- External data sources (data blocks can return different results)
- Random IDs generated on each plan
- Dependent resources changing upstream

**Implication**: The `-out` flag should be used when determinism matters (e.g., before production applies).

---

## Terraform Init/Plan/Apply/Destroy Workflow & Commands

### Textual Deep Dive

#### Architecture Role

The core Terraform CLI workflow (`init` → `plan` → `apply` → `destroy`) forms the operational heartbeat of Infrastructure as Code. Each command serves a distinct function in the infrastructure lifecycle:

- **`init`**: Initializes a working directory with provider plugins and backend configuration
- **`plan`**: Generates an execution plan without modifying infrastructure
- **`apply`**: Executes the plan to achieve the desired state
- **`destroy`**: Tears down managed infrastructure
- **`validate/fmt/lint`**: Pre-execution quality gates
- **`state`**: Manual state inspection and manipulation for operational recovery
- **`graph`**: Visualizes resource dependencies for architectural understanding

In enterprise deployments, this workflow is the interface between human decision-making and cloud provider APIs. Orchestration systems (CI/CD) execute these commands on behalf of teams while capturing audit trails.

#### Internal Working Mechanism

##### **`terraform init` - Working Directory Initialization**

```
INPUT: HCL configuration files + backend config
  ↓
1. Parse backend block (if present)
   - Local backend (default): Uses ./terraform/terraform.tfstate
   - Remote backend: Configures connection to S3, Terraform Cloud, etc.
  ↓
2. Download provider plugins
   - Reads provider requirements from .tf files
   - Consults terraform registry (registry.terraform.io by default)
   - Caches plugins in .terraform/plugins/
  ↓
3. Initialize backend
   - Local backend: Creates .terraform/ directory
   - Remote backend: Validates credentials, creates state bucket if needed
  ↓
4. Create .terraform.lock.hcl
   - Records exact provider versions locked during init
   - Ensures reproducibility across runs
  ↓
OUTPUT: Initialized working directory ready for planning
```

**Key insight**: `terraform init` is idempotent and can be run multiple times. It's the only command that modifies the filesystem outside the HCL files.

##### **`terraform plan` - Execution Plan Generation**

```
INPUT: HCL configuration + current state
  ↓
1. Parser Phase
   - Reads all .tf files in working directory
   - Validates HCL syntax
   - Builds resource graph
  ↓
2. Evaluation Phase
   - Evaluates variables and locals
   - Resolves data source queries
   - Interpolates expressions
  ↓
3. Comparison Phase
   - Reads current state file
   - Compares desired state (HCL) vs actual state (state file)
   - Detects out-of-band changes (manual modifications)
  ↓
4. Plan Generation
   - For each resource: UNCHANGED | CREATE | UPDATE | DELETE | REPLACE
   - Builds dependency chain
   - Identifies resource impacts
  ↓
5. Validation & Constraints
   - Applies provider-specific validation
   - Checks resource constraints
   - Generates warning/error messages
  ↓
OUTPUT: Execution plan (can be human-reviewed or exported for later apply)
```

**Critical mechanism**: `terraform plan` **does not modify infrastructure**. It is purely analytical. Running it repeatedly produces identical output until actual resources change.

##### **`terraform apply` - Plan Execution**

```
INPUT: Execution plan (from terraform plan or generated inline)
  ↓
1. Pre-Apply Phase
   - Validates plan signatures (if plan was exported)
   - Acquires state lock from backend (prevents concurrent modifications)
   - Refreshes remote state if older than 30 seconds
  ↓
2. Apply Phase
   - Topological sort of resources
   - For each resource in dependency order:
     * Call provider API to create/update/delete
     * Update state file with new resource attributes
     * Handle errors with automatic rollback capability
  ↓
3. Parallelization
   - Resources with no dependencies apply simultaneously
   - Parallelism controlled by -parallelism flag (default: 10)
   - Provider API limits may reduce effective parallelization
  ↓
4. State Update
   - Incremental state updates as resources are applied
   - Partial state consistency (if apply fails, partial state is recorded)
  ↓
5. Post-Apply Phase
   - Release state lock
   - Output any defined outputs
   - Display summary (X added, Y changed, Z destroyed)
  ↓
OUTPUT: Updated state file + modified infrastructure
```

**Critical behavior**: Apply is not fully atomic. If it fails halfway, infrastructure and state may be partially updated. This is why error handling and recovery procedures matter.

##### **`terraform destroy` - Infrastructure Teardown**

```
INPUT: Current state file + destroy confirmation
  ↓
1. Plan Phase
   - Creates implicit plan with all resources marked for deletion
   - User must confirm (safety gate)
  ↓
2. Destruction Order
   - Reverses dependency graph (dependents destroyed first)
   - Respects prevent_destroy lifecycle rules
  ↓
3. Resource Deletion
   - Calls provider APIs to delete each resource
   - Handles cascading deletions (e.g., security group rules)
  ↓
4. State Cleanup
   - Removes deleted resources from state file
   - Preserves local state backup as terraform.tfstate.backup
  ↓
OUTPUT: Empty state file + destroyed infrastructure
```

**Safety note**: `terraform destroy` is deterministic given the current state. It will not destroy resources outside of Terraform's management.

##### **`terraform validate/fmt/lint` - Quality Gates**

- **`terraform validate`**: Checks HCL syntax and provider schema compliance (runs without state)
- **`terraform fmt`**: Reformats HCL to standard indentation and style
- **`terraform console`**: Interactive REPL for testing expressions

##### **`terraform state` - State Manipulation**

```
terraform state list              # List all managed resources
terraform state show <resource>   # Display resource attributes
terraform state mv <src> <dst>    # Move resource (rename)
terraform state rm <resource>     # Remove from state (dangerous)
terraform state replace-provider  # Update provider references
```

These commands provide operational escape hatches when Terraform's automatic behavior is insufficient.

##### **`terraform graph` - Dependency Visualization**

```
terraform graph | dot -Tsvg > graph.svg
```

Outputs DOT format representation of resource dependency graph, useful for:
- Understanding large infrastructures
- Identifying circular dependency issues
- Validating expected dependencies

#### Production Usage Patterns

##### **Pattern 1: CI/CD-Driven Deployments**

```bash
#!/bin/bash
set -e

# Initialize
terraform init \
  -backend-config="bucket=$TF_STATE_BUCKET" \
  -backend-config="key=$ENVIRONMENT/terraform.tfstate"

# Validate
terraform validate

# Plan with output for review
terraform plan -out=tfplan -var-file="$ENVIRONMENT.tfvars"

# Human approval gate
echo "Review the plan above. Approve? (yes/no)"
read APPROVAL
[[ "$APPROVAL" == "yes" ]] || exit 1

# Apply
terraform apply tfplan

# Capture outputs for downstream systems
terraform output -json > outputs.json
```

**Key pattern**: The `-out` flag ensures plan and apply are atomic. No configuration changes occur between plan and apply.

##### **Pattern 2: Multi-Environment Consistency**

```bash
for ENV in dev staging prod; do
  terraform workspace select $ENV
  terraform plan -var-file="$ENV.tfvars" -lock=true
done
```

Validates all environments with identical code but different variables.

##### **Pattern 3: Scheduled Destruction for Cost Control**

```bash
# Destroy non-production environments nightly
0 22 * * * terraform -chdir=/path/to/tf destroy \
  -auto-approve \
  -var="environment=dev"
```

Automatic teardown of ephemeral resources.

#### DevOps Best Practices

1. **Always Use `-auto-approve` Sparingly**
   - Only in fully automated, gated environments
   - Requires explicit approval gates before execution
   
2. **Plan Before Apply**
   ```bash
   terraform plan -out=tfplan
   # Human review
   terraform apply tfplan
   ```

3. **Lock State During Operations**
   - Remote backends with DynamoDB/Postgres locking prevent concurrent modifications
   - Local backend should never be used in production teams

4. **Implement State Backup Strategy**
   - S3 versioning on state bucket
   - Point-in-time recovery capability
   - Audit logging on every state modification

5. **Monitor Plan Execution**
   - Log all `apply` operations with initiator and timestamp
   - Alert on unexpected changes (e.g., resource modifications outside Terraform)
   - Implement cost estimation before apply

6. **Resource Targeting for Incident Response**
   ```bash
   terraform apply -target=aws_instance.critical_app
   ```
   Applies changes to specific resources when needed for emergency fixes.

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| Using `-auto-approve` in manual workflows | Accidental deletions in production | Require explicit approval gates |
| Modifying state files directly | State corruption, resource duplication | Use `terraform state` commands |
| Running `apply` without reviewing `plan` output | Unexpected infrastructure changes | Always run plan separately |
| Concurrent applies to same state | Race conditions, partial state updates | Enable state locking on backend |
| Not backing up state before major changes | Inability to recover from failures | Implement automated backup procedures |
| Ignoring drift detection | Manual changes persist undetected | Regular `terraform plan` runs in monitoring |
| Large parallelism values | API rate limiting, provider throttling | Start with parallelism=5, tune based on API limits |

### Practical Code Examples

#### Example 1: Production Multi-Environment Deployment

**Directory Structure**:
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── dev.tfvars
├── staging.tfvars
├── prod.tfvars
└── backend-config/
    ├── dev.tfbackend
    ├── staging.tfbackend
    └── prod.tfbackend
```

**main.tf**:
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}

# VPC Infrastructure
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances
resource "aws_instance" "app" {
  count = var.instance_count

  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.app.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ebs_volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    environment = var.environment
    app_version = var.app_version
  }))

  tags = {
    Name = "${var.project_name}-app-${count.index + 1}"
    Role = "application-server"
  }

  depends_on = [aws_nat_gateway.main]

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      ami,
      root_block_device[0].volume_size
    ]
  }
}
```

**variables.tf**:
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "instance_count" {
  type        = number
  description = "Number of application instances"
  default     = 1
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "app_port" {
  type        = number
  description = "Application listening port"
  default     = 8080
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access app"
  default     = []
}

variable "ebs_volume_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 20
}

variable "app_version" {
  type        = string
  description = "Application version to deploy"
}
```

**prod.tfvars**:
```hcl
environment           = "prod"
project_name          = "myapp"
aws_region            = "us-east-1"
vpc_cidr              = "10.0.0.0/16"
private_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
instance_count        = 5
instance_type         = "t3.small"
app_port              = 8080
allowed_cidr_blocks   = ["10.0.0.0/16"]
ebs_volume_size       = 100
app_version           = "v2.5.1"
```

**prod.tfbackend**:
```hcl
bucket         = "myorg-terraform-state-prod"
key            = "myapp/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "terraform-locks"
encrypt        = true
```

#### Example 2: CI/CD Automation Script

```bash
#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-dev}
ACTION=${2:-plan}
TERRAFORM_DIR="./infra"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

cd "$TERRAFORM_DIR"

# Step 1: Initialize Terraform
log "Initializing Terraform for environment: $ENVIRONMENT"
terraform init \
    -backend-config="environments/${ENVIRONMENT}.tfbackend" \
    -upgrade \
    -lock=true

# Step 2: Validate configuration
log "Validating Terraform configuration"
terraform validate || error "Terraform validation failed"

# Step 3: Format check
log "Checking Terraform code formatting"
if ! terraform fmt -check > /dev/null 2>&1; then
    error "Terraform code is not properly formatted. Run 'terraform fmt' to fix."
fi

# Step 4: Run plan
log "Planning infrastructure changes for $ENVIRONMENT"
if terraform plan \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    -out="tfplan_${ENVIRONMENT}" \
    -lock=true; then
    
    PLAN_EXIT=$?
    log "Plan completed successfully (exit code: $PLAN_EXIT)"
    
    # Extract resource counts
    RESOURCE_CHANGES=$(terraform show -json tfplan_${ENVIRONMENT} | \
        jq '.resource_changes | length')
    
    log "Detected $RESOURCE_CHANGES resource changes"
else
    error "Terraform plan failed"
fi

# Step 5: Conditional apply
if [[ "$ACTION" == "apply" ]]; then
    log "Applying infrastructure changes"
    
    # Safety check: Confirm production changes
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        echo -e "${YELLOW}WARNING: About to modify PRODUCTION infrastructure${NC}"
        echo "Type 'yes' to confirm: "
        read CONFIRM
        [[ "$CONFIRM" == "yes" ]] || error "Production apply cancelled"
    fi
    
    terraform apply \
        -lock=true \
        -lock-timeout=5m \
        "tfplan_${ENVIRONMENT}" || error "Terraform apply failed"
    
    log "Infrastructure changes applied successfully"
else
    log "Skipping apply. Run with 'apply' argument to proceed: $0 $ENVIRONMENT apply"
fi

# Step 6: Output state summary
log "Infrastructure state summary:"
terraform output -json | jq .

log "Task completed successfully"
```

**Usage**:
```bash
# Plan production deployment
./deploy.sh prod plan

# Apply production deployment (requires confirmation)
./deploy.sh prod apply

# Plan staging deployment
./deploy.sh staging plan
./deploy.sh staging apply
```

#### Example 3: State Recovery Scenario

```bash
# Scenario: Need to import existing infrastructure into Terraform state

# Step 1: List all resources currently in state
terraform state list

# Step 2: Import existing AWS resource not in state
terraform import aws_instance.imported_app i-0123456789abcdef0

# Step 3: Verify import
terraform state show aws_instance.imported_app

# Step 4: Update HCL to match imported resource
# (Manually add resource block to main.tf with matching configuration)

# Step 5: Verify no changes detected
terraform plan  # Should show "No changes"

# Step 6: Move resource if needed (rename)
terraform state mv aws_instance.imported_app aws_instance.app_server

# Step 7: Back up state after major changes
terraform state pull > terraform.tfstate.backup
```

### ASCII Diagrams

#### Terraform Command Workflow

```
START
  │
  ├─→ terraform init
  │   └─→ Downloads providers
  │   └─→ Configures backend
  │   └─→ Creates .terraform/
  │
  ├─→ terraform validate (optional)
  │   └─→ Syntax check
  │
  ├─→ terraform plan
  │   ├─→ Read HCL configuration
  │   ├─→ Compare with state
  │   ├─→ Generate execution plan
  │   └─→ Output change summary
  │
  ├─→ terraform apply (or destroy)
  │   ├─→ Acquire state lock
  │   ├─→ Execute changes in dependency order
  │   ├─→ Update state file
  │   └─→ Release lock
  │
  └─→ END

  Note: -auto-approve skips user confirmation between plan & apply
```

#### State File Locking Mechanism (production environment)

```
┌────────────────────────────────────────────────────────────┐
│                    CI/CD System                             │
│         (Jenkins, GitLab CI, GitHub Actions)               │
└────────────────────────────────────────────────────────────┘
              ↓
      terraform apply
              ↓
┌────────────────────────────────────────────────────────────┐
│         Terraform Lock System                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  DynamoDB Table: terraform-locks                     │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │ LockID    │ State Path   │ Lock Owner │ Expires │ │  │
│  │  ├───────────┼──────────────┼────────────┼─────────┤ │  │
│  │  │ abc123def │ prod/app.tfst│ ci-run-42  │ T+5min  │ │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
              ↓
┌────────────────────────────────────────────────────────────┐
│                    S3 State Bucket                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ terraform.tfstate (encrypted)                        │  │
│  │ terraform.tfstate.backup (previous version)          │  │
│  │ terraform.tfstate.d/ (state versions)                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ✓ Versioning enabled (point-in-time recovery)            │
│  ✓ Server-side encryption                                 │
│  ✓ Access logging                                         │
└────────────────────────────────────────────────────────────┘
              ↓
        Cloud Provider APIs
        (AWS, Azure, GCP)
```

#### Resource Dependency Graph Example

```
Input HCL:
  resource "aws_vpc" "main" { }
  resource "aws_subnet" "app" {
    vpc_id = aws_vpc.main.id
  }
  resource "aws_security_group" "app" {
    vpc_id = aws_vpc.main.id
  }
  resource "aws_instance" "app" {
    subnet_id = aws_subnet.app.id
    security_groups = [aws_security_group.app.id]
  }

Generated Dependency Graph:
  
  aws_vpc.main
      ├─→ aws_subnet.app (explicit: vpc_id)
      └─→ aws_security_group.app (explicit: vpc_id)
              └─→ aws_instance.app (explicit: security_groups)
                      ↑
                      └─── aws_subnet.app (explicit: subnet_id)

Execution Order:
  1. aws_vpc.main (no dependencies)
  2. [parallel] aws_subnet.app + aws_security_group.app
  3. aws_instance.app (depends on both #2 resources)

terraform graph output (DOT format):
  digraph {
    "aws_vpc.main" -> "aws_subnet.app"
    "aws_vpc.main" -> "aws_security_group.app"
    "aws_subnet.app" -> "aws_instance.app"
    "aws_security_group.app" -> "aws_instance.app"
  }
```

---

## Terraform Workspaces and Variable Injection

### Textual Deep Dive

#### Architecture Role

Terraform workspaces provide a lightweight mechanism for managing multiple isolated state files from a single codebase. Combined with variable injection, workspaces enable:

- **Multi-environment deployments** without code duplication
- **Parallel development** where multiple engineers work on different environments
- **Environment parity** where identical code defines dev, staging, and production infrastructure
- **Cost tracking and separation** at the environment level

Variable injection (via `-var`, `-var-file`, and environment variables) layers configuration on top of base HCL, creating a separation between code and configuration that is essential for infrastructure automation.

Together, workspaces and variable injection form the configuration management layer of Terraform—how the same code produces different infrastructure across environments.

#### Internal Working Mechanism

##### **Workspace Fundamentals**

A workspace is simply a **named state file pointer**:

```
Default state file:    terraform.tfstate
Named workspace state: terraform.tfstate.d/<workspace-name>/terraform.tfstate
```

```
terraform workspace list
# Output:
# default
# dev
# staging
# * prod          ← currently active workspace (marked with *)

terraform workspace select prod
# Switches active workspace to prod
# Now terraform apply will use terraform.tfstate.d/prod/terraform.tfstate
```

**Critical distinction**: Workspaces share the same HCL code and backend configuration. They differ only in which state file is active.

##### **Workspace Isolation Boundaries**

```
┌────────────────────────────────────────────────────┐
│  Terraform Working Directory                       │
│  ├─ main.tf                                        │
│  ├─ variables.tf                                   │
│  ├─ prod.tfvars                                    │
│  └─ backend.tf (shared across all workspaces)     │
└────────────────────────────────────────────────────┘
            ↓
┌────────────────────────────────────────────────────┐
│  Remote State Backend (S3 with workspaces)        │
│  ├─ terraform.tfstate.d/default/                  │
│  ├─ terraform.tfstate.d/dev/                      │
│  ├─ terraform.tfstate.d/staging/                  │
│  └─ terraform.tfstate.d/prod/                     │
└────────────────────────────────────────────────────┘

Each workspace has:
  ✓ Independent state file
  ✗ Shared backend configuration (S3 bucket, region, etc.)
  ✗ Shared provider credentials
  ✗ Shared HCL code
```

This means workspace isolation is **incomplete**:
- A developer with S3 read access can read prod state
- A developer with AWS credentials can access prod resources
- Workspace is NOT a security boundary

##### **Variable Injection Mechanism**

Terraform evaluates variables in this hierarchical order (highest precedence last):

```
1. Default values in variable blocks (lowest precedence)
   variable "instance_count" {
     default = 1
   }

2. File-based variable specifications (-var-file)
   terraform apply -var-file="prod.tfvars"
   # prod.tfvars: instance_count = 5

3. CLI variable overrides (-var)
   terraform apply -var="instance_count=10"

4. Environment variables (with TF_VAR_ prefix) (highest precedence)
   export TF_VAR_instance_count=15
   terraform apply  # Uses TF_VAR_instance_count value
```

**Practical precedence example**:
```bash
# Default in variable block: instance_count = 1
# prod.tfvars: instance_count = 5
# CLI override: -var="instance_count=10"
# Environment: TF_VAR_instance_count=15

terraform apply -var-file="prod.tfvars" -var="instance_count=10"
# Result: instance_count = 15 (environment variable wins)
```

##### **Variable Types and Type Coercion**

```hcl
# String type
variable "app_name" {
  type = string
}
# CLI: -var="app_name=myapp"

# Number type
variable "replica_count" {
  type = number
}
# CLI: -var="replica_count=5"

# List type
variable "availability_zones" {
  type = list(string)
}
# CLI: -var='availability_zones=["us-east-1a","us-east-1b"]'
# Or: -var-file with YAML: availability_zones = ["us-east-1a", "us-east-1b"]

# Map type
variable "tags" {
  type = map(string)
}
# CLI: -var='tags={"env":"prod","team":"platform"}'

# Object type (complex)
variable "database_config" {
  type = object({
    engine         = string
    instance_class = string
    storage_gb     = number
  })
}
```

##### **Sensitive Variable Handling**

```hcl
variable "db_password" {
  type      = string
  sensitive = true  # Prevents logging/display in console output
}

# Accessing sensitive variables still works:
resource "aws_db_instance" "primary" {
  master_password = var.db_password  # ← Marked as sensitive in logs
}
```

In logs and outputs, sensitive variables are displayed as `<sensitive>`.

#### Production Usage Patterns

##### **Pattern 1: Multi-Environment Workspace Strategy**

**Organization approach**:
```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
├── environments/
│   ├── base.tfvars          # Common to all environments
│   ├── dev.tfvars           # Development overrides
│   ├── staging.tfvars       # Staging overrides
│   └── prod.tfvars          # Production overrides
└── backend-config/
    ├── backend.tfvars       # Backend addresses (S3 bucket, etc.)
    └── .gitignore           # Don't commit backend configs with secrets
```

**Workspace setup**:
```bash
# Initialize
terraform init -backend-config="environments/backend.tfvars"

# Create workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch to environment
terraform workspace select prod

# Apply with environment-specific overrides
terraform apply \
  -var-file="environments/base.tfvars" \
  -var-file="environments/prod.tfvars"
```

**Key benefit**: Single source of truth for infrastructure code, with environment-specific parameters layered on top.

##### **Pattern 2: Dynamic Variable Injection for CI/CD**

Automation systems inject variables computed from external sources:

```bash
#!/bin/bash
# Dynamic variable computation

# From Git metadata
GIT_COMMIT=$(git rev-parse --short HEAD)
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# From environment
BUILD_NUMBER=${CI_BUILD_NUMBER:-dev}
DEPLOYER=${CI_USER:-automation}

# From service registry
APP_VERSION=$(curl https://registry.company.com/myapp/latest-version)

# Execute Terraform with injected variables
terraform apply \
  -var="git_commit=$GIT_COMMIT" \
  -var="git_branch=$GIT_BRANCH" \
  -var="build_id=$BUILD_NUMBER" \
  -var="deployer_email=$DEPLOYER" \
  -var="app_version=$APP_VERSION" \
  -var-file="$ENVIRONMENT.tfvars"
```

This pattern enables the Terraform code to reference deployment metadata.

##### **Pattern 3: Local Development Overrides**

Developers create local overrides for rapid iteration:

```
terraform/
├── base.tfvars
├── prod.tfvars
└── local.tfvars.example   # Checked in as template
    local.tfvars            # .gitignore (local development)
```

**local.tfvars** (developer-specific, not committed):
```hcl
# Increased resources for local testing
instance_count = 10
enable_monitoring = false
skip_expensive_features = true
```

**Workflow**:
```bash
terraform apply \
  -var-file="prod.tfvars" \
  -var-file="local.tfvars"  # Local overrides prod
```

Developers can iterate quickly without modifying shared .tfvars files.

#### DevOps Best Practices

1. **Use Workspaces for Environment Separation Only**
   - Do NOT use workspaces to segregate teams or projects
   - Each workspace should contain one logically complete infrastructure
   - Use AWS accounts or separate backends for true isolation

2. **Layer Variable Files Strategically**
   ```bash
   # Base -> Environment -> Local (optional)
   terraform apply \
     -var-file="base.tfvars" \
     -var-file="${ENVIRONMENT}.tfvars" \
     -var-file="local.tfvars"  # Optional local overrides
   ```

3. **Validate Variables in HCL**
   ```hcl
   variable "instance_count" {
     type        = number
     description = "Number of instances (1-100)"
     
     validation {
       condition     = var.instance_count >= 1 && var.instance_count <= 100
       error_message = "Instance count must be 1-100."
     }
   }
   ```

4. **Avoid Secrets in Variables (Use Proper Secret Management)**
   ```bash
   # WRONG: Storing password in .tfvars file
   db_password = "super-secret-12345"  # ← Git leaks this
   
   # RIGHT: Inject from secure environment
   export TF_VAR_db_password=$(aws secretsmanager get-secret-value \
     --secret-id prod/db/password --query SecretString --output text)
   terraform apply
   ```

5. **Version Lock Variable Files in Prod**
   ```bash
   # Create immutable variable snapshot
   cp prod.tfvars prod.tfvars.${DEPLOYMENT_ID}
   git commit -m "Deployment snapshot: $DEPLOYMENT_ID"
   
   # Apply with snapshot
   terraform apply -var-file="prod.tfvars.${DEPLOYMENT_ID}"
   ```

6. **Document Variable Overrides**
   ```bash
   # Track which variables were overridden
   terraform apply \
     -var-file="prod.tfvars" \
     -var-file="prod.tfvars.overrides" \
     2>&1 | tee apply.log
   
   # Save override rationale
   echo "Overrode instance_count to 5 due to hardware maintenance" > OVERRIDES.md
   ```

#### Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|-----------|
| Using workspaces across AWS accounts | Insufficient isolation; credential bleed | Use separate backends per account |
| Committing secrets in .tfvars files | Git history contains credentials | Use `.gitignore` + external secret injection |
| Variable precedence confusion | Applied configuration differs from intent | Document variable layering; validate with `-json` output |
| Not validating variable types | Runtime type errors during apply | Use `type` and `validation` blocks in variables |
| Workspace name collisions | Multiple teams using same workspace names | Use namespace prefix convention (e.g., `team-env`) |
| Overriding too many variables at CLI | Difficult to reproduce; unclear intent | Use .tfvars files for complex overrides |
| Environment variable leakage | TF_VAR_* variables affect unexpected workspace | Unset TF_VAR_* before switching workspaces |

### Practical Code Examples

#### Example 1: Multi-Environment Variable Strategy

**variables.tf**:
```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_count" {
  type        = number
  description = "Number of application instances"
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 50
    error_message = "Instance count must be 1-50"
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable CloudWatch monitoring"
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Database backup retention period"
  default     = 7
  
  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention must be 1-35 days"
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default     = {}
}

variable "database_config" {
  type = object({
    engine             = string
    instance_class     = string
    allocated_storage  = number
    backup_retention   = number
  })
  description = "Database configuration"
}
```

**environments/base.tfvars**:
```hcl
# Shared across all environments
tags = {
  ManagedBy  = "Terraform"
  Project    = "myapp"
  Repository = "github.com/myorg/terraform"
}

enable_monitoring = true
backup_retention_days = 14
```

**environments/dev.tfvars**:
```hcl
environment = "dev"
instance_count = 1
instance_type = "t3.micro"
backup_retention_days = 1

database_config = {
  engine            = "postgres"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  backup_retention  = 1
}
```

**environments/staging.tfvars**:
```hcl
environment = "staging"
instance_count = 2
instance_type = "t3.small"
backup_retention_days = 7

database_config = {
  engine            = "postgres"
  instance_class    = "db.t3.small"
  allocated_storage = 100
  backup_retention  = 7
}
```

**environments/prod.tfvars**:
```hcl
environment = "prod"
instance_count = 5
instance_type = "t3.medium"
backup_retention_days = 30

database_config = {
  engine            = "postgres"
  instance_class    = "db.t3.large"
  allocated_storage = 500
  backup_retention  = 30
}
```

**main.tf** (Using variables):
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
    }
  }
  
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "myapp/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = merge(
      var.tags,
      {
        Environment = var.environment
        Workspace   = terraform.workspace
      }
    )
  }
}

# Application tier
resource "aws_instance" "app" {
  count = var.instance_count

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type

  tags = {
    Name = "${var.environment}-app-instance-${count.index + 1}"
  }
}

# Database tier
resource "aws_db_instance" "primary" {
  identifier     = "${var.environment}-postgres"
  engine         = var.database_config.engine
  instance_class = var.database_config.instance_class
  allocated_size = var.database_config.allocated_storage
  
  backup_retention_period = var.database_config.backup_retention
  skip_final_snapshot     = var.environment != "prod"
  publicly_accessible     = var.environment == "dev"

  tags = {
    Name = "${var.environment}-primary-db"
  }
}

# Monitoring
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${var.environment}-app-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    InstanceIds = join(",", aws_instance.app[*].id)
  }
}
```

**Deployment commands**:
```bash
# Development deployment
terraform workspace select dev
terraform apply \
  -var-file="environments/base.tfvars" \
  -var-file="environments/dev.tfvars"

# Production deployment (with approval)
terraform workspace select prod
terraform plan \
  -var-file="environments/base.tfvars" \
  -var-file="environments/prod.tfvars" \
  -out=tfplan

# Human review and approval
terraform apply tfplan
```

#### Example 2: Dynamic Variable Injection Script

```bash
#!/bin/bash
# Dynamic variable injection for CI/CD environments

set -euo pipefail

ENVIRONMENT=${1:-dev}
TERRAFORM_DIR="./infra"

# Function to compute variables dynamically
compute_variables() {
    local env=$1
    
    # Git metadata
    local git_commit=$(git rev-parse --short HEAD)
    local git_branch=$(git rev-parse --abbrev-ref HEAD)
    local git_author=$(git log -1 --pretty=format:'%an')
    
    # Build metadata
    local build_id="${CI_BUILD_ID:-local-$(date +%s)}"
    local build_timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Environment-specific computation
    local instance_count=1
    case $env in
        dev)
            instance_count=1
            instance_type="t3.micro"
            ;;
        staging)
            instance_count=2
            instance_type="t3.small"
            ;;
        prod)
            instance_count=5
            instance_type="t3.medium"
            ;;
    esac
    
    # Dynamically fetch service version from registry
    local app_version
    if command -v curl &> /dev/null; then
        app_version=$(curl -s https://registry.company.com/myapp/$env/version || echo "unknown")
    else
        app_version="dev-build"
    fi
    
    # Inject secrets from AWS Secrets Manager
    local db_password=""
    if [[ "$env" == "prod" ]]; then
        db_password=$(aws secretsmanager get-secret-value \
            --secret-id prod/db/password \
            --query SecretString \
            --output text 2>/dev/null || echo "")
    fi
    
    # Output computed variables
    cat << EOF
environment = "$env"
instance_count = $instance_count
instance_type = "$instance_type"
app_version = "$app_version"
build_id = "$build_id"
build_timestamp = "$build_timestamp"
git_commit = "$git_commit"
git_branch = "$git_branch"
git_author = "$git_author"
EOF
}

# Generate dynamic variables file
compute_variables "$ENVIRONMENT" > "$TERRAFORM_DIR/computed-vars.tfvars"

# Execute Terraform
cd "$TERRAFORM_DIR"

echo "Applying infrastructure for environment: $ENVIRONMENT"
echo "Dynamic variables:"
cat computed-vars.tfvars

terraform init
terraform apply \
    -var-file="environments/base.tfvars" \
    -var-file="environments/${ENVIRONMENT}.tfvars" \
    -var-file="computed-vars.tfvars" \
    -auto-approve  # Only use in fully automated, gated environments

echo "Infrastructure deployment complete"
```

#### Example 3: Workspace Management Script

```bash
#!/bin/bash
# Comprehensive workspace management utility

TERRAFORM_DIR="./infra"

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

show_usage() {
    cat << EOF
Usage: $0 <command> [arguments]

Commands:
  list                          List all workspaces
  create <workspace-name>       Create new workspace
  select <workspace-name>       Switch to workspace
  delete <workspace-name>       Delete workspace
  validate-all                  Run validation on all workspaces
  plan-all                      Generate plans for all workspaces
  show-state <workspace-name>   Show resources in workspace state
EOF
}

# List all available workspaces
cmd_list() {
    echo -e "${BLUE}Available workspaces:${NC}"
    cd "$TERRAFORM_DIR"
    terraform workspace list | sed 's/^/  /'
}

# Create new workspace
cmd_create() {
    local workspace_name=$1
    if [[ -z "$workspace_name" ]]; then
        echo "Error: workspace name required"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    terraform workspace new "$workspace_name"
    echo -e "${GREEN}✓ Created workspace: $workspace_name${NC}"
}

# Switch workspace
cmd_select() {
    local workspace_name=$1
    if [[ -z "$workspace_name" ]]; then
        echo "Error: workspace name required"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    terraform workspace select "$workspace_name"
    echo -e "${GREEN}✓ Switched to workspace: $workspace_name${NC}"
}

# Delete workspace
cmd_delete() {
    local workspace_name=$1
    if [[ -z "$workspace_name" ]]; then
        echo "Error: workspace name required"
        exit 1
    fi
    
    if [[ "$workspace_name" == "default" ]]; then
        echo -e "${RED}✗ Cannot delete default workspace${NC}"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    terraform workspace select default
    terraform workspace delete "$workspace_name"
    echo -e "${GREEN}✓ Deleted workspace: $workspace_name${NC}"
}

# Validate all workspaces
cmd_validate_all() {
    cd "$TERRAFORM_DIR"
    
    echo -e "${BLUE}Validating all workspaces...${NC}"
    
    local workspaces
    workspaces=$(terraform workspace list | awk '{print $1}' | grep -v '^\*' | tr '\n' ' ')
    
    local failed=0
    for workspace in $workspaces; do
        echo -n "Validating $workspace... "
        if terraform workspace select "$workspace" > /dev/null && \
           terraform validate > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            ((failed++))
        fi
    done
    
    if [[ $failed -ne 0 ]]; then
        echo -e "${RED}$failed workspace(s) failed validation${NC}"
        exit 1
    fi
}

# Generate plans for all workspaces
cmd_plan_all() {
    cd "$TERRAFORM_DIR"
    
    echo -e "${BLUE}Generating plans for all workspaces...${NC}"
    
    local workspaces
    workspaces=$(terraform workspace list | awk '{print $1}' | grep -v '^\*' | tr '\n' ' ')
    
    for workspace in $workspaces; do
        echo -e "\n${BLUE}Planning $workspace...${NC}"
        terraform workspace select "$workspace"
        terraform plan -var-file="environments/${workspace}.tfvars" \
            -out="tfplan_${workspace}"
    done
    
    echo -e "\n${GREEN}✓ All plans generated${NC}"
}

# Show state resources in workspace
cmd_show_state() {
    local workspace_name=$1
    if [[ -z "$workspace_name" ]]; then
        echo "Error: workspace name required"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    terraform workspace select "$workspace_name"
    
    echo -e "${BLUE}Resources in workspace: $workspace_name${NC}"
    terraform state list
}

# Main dispatcher
cmd=${1:-}
case $cmd in
    list)
        cmd_list
        ;;
    create)
        cmd_create "${2:-}"
        ;;
    select)
        cmd_select "${2:-}"
        ;;
    delete)
        cmd_delete "${2:-}"
        ;;
    validate-all)
        cmd_validate_all
        ;;
    plan-all)
        cmd_plan_all
        ;;
    show-state)
        cmd_show_state "${2:-}"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
```

**Usage**:
```bash
# List workspaces
./workspace-manager.sh list

# Create new workspace
./workspace-manager.sh create staging

# Select workspace
./workspace-manager.sh select prod

# Validate all workspaces
./workspace-manager.sh validate-all

# Plan all workspaces
./workspace-manager.sh plan-all

# Show resources in workspace
./workspace-manager.sh show-state prod
```

### ASCII Diagrams

#### Variable Precedence Evaluation

```
Terraform Variable Evaluation Order (Lowest to Highest Precedence):

┌──────────────────────────────────────────────────────┐
│ 1. Variable Block Default Values (lowest precedence) │
│                                                      │
│    variable "instance_count" {                       │
│      default = 1                                     │
│    }                                                 │
└──────────────────────────────────────────────────────┘
                    ↓ (overrides)
┌──────────────────────────────────────────────────────┐
│ 2. .tfvars Files (-var-file)                         │
│                                                      │
│    $ terraform apply -var-file="prod.tfvars"        │
│    # prod.tfvars: instance_count = 5               │
└──────────────────────────────────────────────────────┘
                    ↓ (overrides)
┌──────────────────────────────────────────────────────┐
│ 3. Command-Line Variables (-var)                     │
│                                                      │
│    $ terraform apply -var="instance_count=10"       │
└──────────────────────────────────────────────────────┘
                    ↓ (overrides)
┌──────────────────────────────────────────────────────┐
│ 4. Environment Variables (TF_VAR_*)  (highest)       │
│                                                      │
│    $ export TF_VAR_instance_count=15                 │
│    $ terraform apply                                 │
└──────────────────────────────────────────────────────┘
                    ↓
           FINAL VALUE: 15

Example with Multiple Overrides:
  default = 1
  prod.tfvars: instance_count = 5
  -var="instance_count=10"
  TF_VAR_instance_count=15
  
  Result: instance_count = 15
```

#### Workspace State File Organization

```
Backend: S3 (myorg-terraform-state)

┌────────────────────────────────────────────────────────────┐
│ Local State Directory: ./terraform/terraform.tfstate.d/   │
│                                                             │
│  ├─ default/                                              │
│  │  └─ terraform.tfstate                                  │
│  │     [local development state]                          │
│  │                                                         │
│  ├─ dev/                                                  │
│  │  └─ terraform.tfstate                                  │
│  │     [development environment state]                    │
│  │                                                         │
│  ├─ staging/                                              │
│  │  └─ terraform.tfstate                                  │
│  │     [staging environment state]                        │
│  │                                                         │
│  └─ prod/                                                 │
│     └─ terraform.tfstate                                  │
│        [production environment state]                     │
│                                                             │
└────────────────────────────────────────────────────────────┘
                    ↓ (synced to)
┌────────────────────────────────────────────────────────────┐
│ Remote Backend: S3                                         │
│                                                             │
│ Bucket: myorg-terraform-state/                            │
│ ├─ myapp/terraform.tfstate.d/default/                    │
│ ├─ myapp/terraform.tfstate.d/dev/                        │
│ ├─ myapp/terraform.tfstate.d/staging/                    │
│ └─ myapp/terraform.tfstate.d/prod/                       │
│                                                             │
│ DynamoDB: terraform-locks (for locking)                  │
│ ├─ myapp/terraform.tfstate.d/default                     │
│ ├─ myapp/terraform.tfstate.d/dev                         │
│ ├─ myapp/terraform.tfstate.d/staging                     │
│ └─ myapp/terraform.tfstate.d/prod                        │
│                                                             │
└────────────────────────────────────────────────────────────┘

Workspace Operations:
  terraform workspace select dev
    ↓
  Updates active state: dev/terraform.tfstate
    ↓
  terraform apply
    ↓
  Syncs to: S3/myapp/terraform.tfstate.d/dev/
```

#### Multi-Environment Variable Layering

```
Layer Stack (Bottom = Base, Top = Most Specific):

┌─────────────────────────────────────────────┐
│  Layer 4 (Optional): Local Overrides         │
│  $ terraform apply -var-file="local.tfvars"  │
│                                              │
│  local.tfvars (gitignore'd)                  │
│  ├─ instance_count = 20  (developer test)    │
│  └─ enable_monitoring = false                │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 3: Environment-Specific              │
│  $ terraform apply -var-file="prod.tfvars"   │
│                                              │
│  prod.tfvars (committed)                     │
│  ├─ environment = "prod"                     │
│  ├─ instance_count = 5                       │
│  ├─ instance_type = "t3.medium"              │
│  └─ backup_retention_days = 30               │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 2: Base Shared Configuration          │
│  $ terraform apply -var-file="base.tfvars"   │
│                                              │
│  base.tfvars (committed)                     │
│  ├─ tags = { Project: myapp, ... }          │
│  ├─ enable_monitoring = true                 │
│  └─ backup_retention_days = 7 (default)     │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│  Layer 1 (Base): Variable Defaults            │
│  (Defined in variables.tf)                   │
│                                              │
│  variables.tf                                │
│  ├─ instance_count = 1                       │
│  ├─ instance_type = "t3.micro"               │
│  └─ enable_monitoring = false                │
└─────────────────────────────────────────────┘

Applied to Production (prod workspace):
  instance_count = 5                (from prod.tfvars)
  instance_type = "t3.medium"       (from prod.tfvars)
  enable_monitoring = true          (from base.tfvars)
  backup_retention_days = 30        (from prod.tfvars)
  tags = {Project: myapp, ...}      (from base.tfvars)
```

---

**Document Version**: 2.0  
**Last Updated**: March 7, 2026  
**Audience**: DevOps Engineers (5–10+ years experience)

## Hands-on Scenarios

### Scenario 1: State File Corruption and Recovery in Production

#### Problem Statement
Your production Kubernetes cluster on AWS managed by Terraform has gone silent. The last `terraform plan` succeeded, but the state file became corrupted during an interrupted `apply` operation. The state file contains invalid JSON, preventing any Terraform operations. You have a 4-hour RTO (Recovery Time Objective) and cannot afford to rebuild infrastructure manually.

#### Architecture Context
```
Production Infrastructure:
├─ 3 AZs with private subnets
├─ EKS cluster (30 worker nodes)
├─ RDS Aurora PostgreSQL cluster
├─ 2 NLB load balancers
├─ Managed by Terraform in workspace: prod
├─ State backend: S3 + DynamoDB locking
├─ Last known good backup: 2 hours ago
```

#### Step-by-Step Troubleshooting & Implementation

**Step 1: Validate the Corruption**
```bash
# Attempt to read state - this will fail
terraform state list
# Error: error reading state: invalid JSON

# Check S3 versioning history
aws s3api list-object-versions \
  --bucket myorg-terraform-state \
  --prefix prod/terraform.tfstate
```

**Step 2: Attempt State Recovery from Backup**
```bash
# S3 versioning provides point-in-time recovery
# List all versions of the state file
aws s3api get-object-version-id \
  --bucket myorg-terraform-state \
  --key prod/terraform.tfstate

# Restore to previous known-good version
aws s3api get-object \
  --bucket myorg-terraform-state \
  --key prod/terraform.tfstate \
  --version-id "<good-version-id>" \
  terraform.tfstate.recovered

# Validate JSON integrity
jq empty terraform.tfstate.recovered  # Returns empty if valid JSON

# Backup and swap
cp terraform.tfstate.recovered terraform.tfstate

# Verify recovery
terraform state list  # Should succeed now
```

**Step 3: Validate State Consistency Against Actual Infrastructure**
```bash
# The recovered state may not match current infrastructure
# Detect drift (resources outside Terraform management)
terraform refresh  # Updates state from live infrastructure

# Run plan to detect mismatches
terraform plan -no-color > plan.txt

# Check for dangerous operations
grep -E "will be destroyed|must be deleted" plan.txt
```

**Step 4: Controlled Sync with Manual Remediation**
```bash
# If drift detected, import orphaned resources
# Example: A database was manually created - import it
terraform import aws_db_instance.prod_db "mydb-instance-id"

# If resources were deleted outside Terraform, remove from state
terraform state rm aws_ebs_volume.orphaned

# Verify clean state
terraform plan  # Should show no changes
```

**Step 5: Implement Prevention Going Forward**
```hcl
# Add to backend configuration to enable protection
terraform {
  backend "s3" {
    bucket = "myorg-terraform-state"
    key    = "prod/terraform.tfstate"
    
    # Enable versioning (already enabled)
    # Enable MFA delete protection
    # Enable encryption
    # Block public access
  }
}
```

**Prevention Checklist**:
```bash
# 1. Enable S3 versioning on state bucket
aws s3api put-bucket-versioning \
  --bucket myorg-terraform-state \
  --versioning-configuration Status=Enabled

# 2. Enable point-in-time recovery
aws s3api put-bucket-lifecycle-configuration \
  --bucket myorg-terraform-state \
  --lifecycle-configuration file://lifecycle.json

# 3. Add CloudWatch alerts for state file modifications
aws cloudtrail create-trail --name terraform-state-trail \
  --s3-bucket-name myorg-cloudtrail-logs

# 4. Enable MFA delete protection (for production)
aws s3api put-object-acl \
  --bucket myorg-terraform-state \
  --key prod/terraform.tfstate \
  --mfa "arn:aws:iam::123456789012:mfa/admin 123456"

# 5. Implement automatic daily backups
aws s3 sync s3://myorg-terraform-state ./terraform-backups/$(date +%Y-%m-%d)/
```

#### Best Practices Demonstrated
- **State versioning as disaster recovery**: Version history enables rollback without data loss
- **Automated backup procedures**: Regular snapshots reduce RTO
- **State drift detection**: `terraform refresh` and `plan` identify inconsistencies
- **Locking mechanisms**: Prevent concurrent modifications that corrupt state
- **Audit logging**: CloudTrail tracks all state modifications for investigation

---

### Scenario 2: Multi-Environment Promotion with Approval Gates

#### Problem Statement
Your team manages infrastructure across dev, staging, and production environments. A new feature requires infrastructure changes: additional Lambda functions, expanded DynamoDB capacity, and new API Gateway endpoints. The changes must promote through dev → staging → production with human approval at each stage. How do you safely orchestrate this using Terraform workspaces and CI/CD?

#### Architecture Context
```
Environment Hierarchy:
dev (developers self-approve)
  ↓ (automatic promotion with review)
staging (QA lead approval required)
  ↓ (production gate - 2 approvals required)
prod (platform team + compliance sign-off)

Each environment:
- Independent workspace
- Separate AWS account
- Separate state files
- Separated by approval gates in CI/CD
```

#### Step-by-Step Implementation

**Step 1: Design Variable Strategy for Progressive Promotion**
```hcl
# variables.tf
variable "environment" {
  type = string
}

variable "feature_flags" {
  type = object({
    enable_enhanced_monitoring = bool
    enable_auto_scaling        = bool
    dynamodb_read_capacity     = number
    dynamodb_write_capacity    = number
    lambda_reserved_concurrency = number
  })
}

variable "approval_gate" {
  type = object({
    required_approvals = number
    approval_list      = list(string)
  })
  sensitive = true
}
```

**Step 2: Environment-Specific Variable Files**
```bash
# environments/dev-feature.tfvars
environment = "dev"
feature_flags = {
  enable_enhanced_monitoring  = false
  enable_auto_scaling         = false
  dynamodb_read_capacity      = 10
  dynamodb_write_capacity     = 10
  lambda_reserved_concurrency = 10
}

# environments/staging-feature.tfvars
environment = "staging"
feature_flags = {
  enable_enhanced_monitoring  = true
  enable_auto_scaling         = false
  dynamodb_read_capacity      = 100
  dynamodb_write_capacity     = 100
  lambda_reserved_concurrency = 50
}

# environments/prod-feature.tfvars
environment = "prod"
feature_flags = {
  enable_enhanced_monitoring  = true
  enable_auto_scaling         = true
  dynamodb_read_capacity      = 200
  dynamodb_write_capacity     = 200
  lambda_reserved_concurrency = 100
}
```

**Step 3: CI/CD Pipeline with Approval Gates**
```yaml
# .gitlab-ci.yml (Example)
stages:
  - plan
  - approval
  - apply

plan_dev:
  stage: plan
  script:
    - terraform init -backend-config="environments/dev.backend"
    - terraform workspace select dev
    - terraform plan -var-file="environments/dev-feature.tfvars" -out=tfplan_dev
  artifacts:
    paths:
      - tfplan_dev
  only:
    - branches

approval_staging:
  stage: approval
  script:
    - echo "Staging approval required"
  when: manual
  only:
    - main

plan_staging:
  stage: plan
  script:
    - terraform init -backend-config="environments/staging.backend"
    - terraform workspace select staging
    - terraform plan -var-file="environments/staging-feature.tfvars" -out=tfplan_staging
  artifacts:
    paths:
      - tfplan_staging
  needs:
    - job: approval_staging
  only:
    - main

approval_prod:
  stage: approval
  script:
    - echo "Production approval required - 2 reviewers"
  when: manual
  only:
    - main

plan_prod:
  stage: plan
  script:
    - terraform init -backend-config="environments/prod.backend"
    - terraform workspace select prod
    - terraform plan -var-file="environments/prod-feature.tfvars" -out=tfplan_prod
  artifacts:
    paths:
      - tfplan_prod
  needs:
    - job: approval_prod
  only:
    - main

apply_dev:
  stage: apply
  script:
    - terraform init -backend-config="environments/dev.backend"
    - terraform workspace select dev
    - terraform apply tfplan_dev
  dependencies:
    - plan_dev
  environment:
      name: dev
      action: prepare
  only:
    - branches

apply_staging:
  stage: apply
  script:
    - terraform init -backend-config="environments/staging.backend"
    - terraform workspace select staging
    - terraform apply tfplan_staging
  dependencies:
    - plan_staging
  environment:
      name: staging
      action: prepare
  needs:
    - job: approval_staging
  only:
    - main

apply_prod:
  stage: apply
  script:
    - terraform init -backend-config="environments/prod.backend"
    - terraform workspace select prod
    - terraform apply tfplan_prod
  dependencies:
    - plan_prod
  environment:
      name: prod
      action: prepare
  needs:
    - job: approval_prod
  only:
    - main
```

**Step 4: Testing and Validation Between Stages**
```bash
#!/bin/bash
# Smoke test after each apply

validate_environment() {
  local env=$1
  
  case $env in
    dev)
      # Quick functional test
      aws lambda invoke --function-name "myapp-dev-processor" \
        --payload '{}' response.json
      ;;
    staging)
      # Load test
      ab -n 1000 -c 10 https://staging.myapp.com/health
      ;;
    prod)
      # Production monitoring - verify no alerts
      aws cloudwatch describe-alarms \
        --state-value ALARM \
        --tags "Environment=prod" | jq '.MetricAlarms | length'
      ;;
  esac
}

validate_environment "$ENVIRONMENT"
```

**Step 5: Rollback Procedure if Issues Detected**
```bash
#!/bin/bash
# Rollback to previous known-good state

ENVIRONMENT=${1:-prod}
ROLLBACK_VERSION=${2:-LATEST}

terraform init
terraform workspace select "$ENVIRONMENT"

# Restore previous state version
if [[ "$ROLLBACK_VERSION" == "LATEST" ]]; then
  # Find second-most-recent version
  ROLLBACK_VERSION=$(aws s3api list-object-versions \
    --bucket myorg-terraform-state \
    --prefix "${ENVIRONMENT}/terraform.tfstate" \
    --query 'Versions[1].VersionId' \
    --output text)
fi

# Restore and apply
aws s3api get-object \
  --bucket myorg-terraform-state \
  --key "${ENVIRONMENT}/terraform.tfstate" \
  --version-id "$ROLLBACK_VERSION" \
  terraform.tfstate

terraform apply -auto-approve

echo "Rolled back to version: $ROLLBACK_VERSION"
```

#### Best Practices Demonstrated
- **Environment parity with variable override**: Identical code, environment-specific configuration
- **Human approval gates**: Prevents automatic production changes
- **Plan-before-apply**: Humans review changes before execution
- **Smoke testing between stages**: Validates infrastructure behavior before promotion
- **Quick rollback capability**: Version history enables rapid recovery

---

### Scenario 3: Detecting and Fixing State Drift in Production

#### Problem Statement
Your on-call engineer notices that `terraform plan` against your production infrastructure is suddenly showing 47 different resources as "will be created" despite nothing being deployed for 2 weeks. The actual infrastructure is visible in the AWS console—nothing was destroyed. The state file is somehow out of sync with reality. How do you diagnose and fix this without impacting live traffic?

#### Architecture Context
```
Production Setup:
- 50+ managed resources (compute, networking, databases)
- CI/CD deploys changes daily
- State stored in S3 with remote backend
- High-traffic application (cannot have downtime)
- Last successful apply was 14 days ago
```

#### Step-by-Step Troubleshooting

**Step 1: Identify the Drift Source**
```bash
# First, confirm state file hasn't been corrupted
jq empty terraform.tfstate  # Validates JSON

# Check state timestamp vs real infrastructure
stat terraform.tfstate  # Check modification time
aws s3api head-object --bucket myorg-terraform-state \
  --key prod/terraform.tfstate

# List what Terraform thinks exists
terraform state list | wc -l  # Count of resources in state
# Output: 47

# Get actual count from AWS
aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[] | length(@)'
# Output: 47

# They match, so resources exist - drift is in the state file itself
```

**Step 2: Deep Dive into Specific Drift**
```bash
# Identify what Terraform thinks vs what exists
terraform plan -json | jq '.resource_changes[] | select(.change.actions[0] == "create")' \
  > create_plan.json

# Check first problematic resource
terraform plan -json | jq '.resource_changes[0]' | jq -r '.address'
# Output: aws_instance.app_1

# Show what Terraform thinks exists
terraform state show aws_instance.app_1
# Shows empty resource attributes

# Check actual AWS state
aws ec2 describe-instances --instance-ids i-0123456789abcdef0 | jq '.Reservations[0].Instances[0]'
# Shows full resource attributes

# The instance exists but state doesn't have its attributes
```

**Step 3: Root Cause Analysis**
```bash
# Check state file history
aws s3api list-object-versions --bucket myorg-terraform-state \
  --prefix prod/terraform.tfstate | jq '.Versions[] | {VersionId, LastModified}'

# Compare versions
aws s3api get-object --bucket myorg-terraform-state \
  --key prod/terraform.tfstate --version-id VERSION1 \
  terraform.tfstate.v1

aws s3api get-object --bucket myorg-terraform-state \
  --key prod/terraform.tfstate --version-id VERSION2 \
  terraform.tfstate.v2

# Diff the two versions
diff <(jq .resources terraform.tfstate.v1 | sort) \
     <(jq .resources terraform.tfstate.v2 | sort)
# Output shows resources were removed from state but not from infrastructure

# Check CloudTrail for who did this
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=terraform.tfstate \
  --max-results 10 | jq '.Events[].CloudTrailEvent | fromjson'
```

**Step 4: Recovery Strategy - Partial State Refresh**
```bash
# Option 1: Selective refresh of problematic resources
terraform refresh  # Updates state from live AWS
# Caution: This is a full refresh - could take time with large infrastructure

# Option 2: Selective resource re-import
terraform import aws_instance.app_1 i-0123456789abcdef0

# Verify the import worked
terraform state show aws_instance.app_1  # Should now have attributes

# Check plan to confirm drift is resolved
terraform plan  # Should show fewer changes now
```

**Step 5: Validate Safety Before Applying**
```bash
# Generate plan to see exactly what would change
terraform plan -out=drift_recovery.tfplan

# For large recoveries, export as JSON to review
terraform show -json drift_recovery.tfplan | jq '.resource_changes' > changes.json

# Manually verify critical resources aren't marked for destruction
jq '.[] | select(.change.actions[0] == "delete")' changes.json
# If this returns production databases or load balancers, STOP and investigate further

# Safety check: Confirm no destructive actions on critical resources
DESTROY_COUNT=$(jq '[.[] | select(.change.actions[0] == "delete")] | length' changes.json)
if [[ $DESTROY_COUNT -gt 0 ]]; then
  echo "ERROR: Found $DESTROY_COUNT resources marked for deletion"
  echo "Manually review the drift before proceeding"
  exit 1
fi
```

**Step 6: Controlled Apply with Monitoring**
```bash
# Apply with resource targeting for high-risk updates
# Break into smaller applies instead of one large apply
terraform apply -target=aws_instance.app_1 drift_recovery.tfplan

# Monitor actual infrastructure
aws cloudwatch get-metric-statistics --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --start-time 2024-01-01T00:00:00Z --end-time 2024-01-01T01:00:00Z \
  --period 300 --statistics Average

# Confirm no traffic loss
curl -I https://myapp.prod.com/health
# Should return 200 OK
```

**Step 7: Prevention**
```bash
# Implement regular drift detection
0 2 * * * cd /terraform && terraform init && \
           terraform plan > /tmp/drift_check.txt 2>&1 && \
           if grep -q "plan: 0 to add" /tmp/drift_check.txt; then \
             echo "No drift detected" | mail ops@company.com; \
           else \
             cat /tmp/drift_check.txt | mail -s "DRIFT DETECTED" ops@company.com; \
           fi

# Better: Use Terraform Cloud's continuous state monitoring
# Or use aws config to detect infrastructure changes outside Terraform
aws configservice describe-compliance-by-config-rule \
  --query 'ComplianceByConfigRules[?Compliance.ComplianceType==`NON_COMPLIANT`]'
```

#### Best Practices Demonstrated
- **State file versioning**: Enables comparison of historical states
- **CloudTrail auditing**: Tracks who modified state files
- **Selective refresh**: Avoids full state refresh which is time-consuming
- **Safety verification**: Confirms no destructive actions before apply
- **Partial applies with targeting**: Safer for large drift corrections
- **Continuous monitoring**: Detects drift before it becomes critical

---

### Scenario 4: Handling Large-Scale Infrastructure Scaling

#### Problem Statement
Your production application experiences a surprise 10x traffic spike. You need to scale from 30 EC2 instances to 100 instances, expand RDS from db.t3.large to db.r5.2xlarge, and increase Lambda concurrency limits. You have 15 minutes to scale. Terraform plan will take 8 minutes to generate. How do you handle this time-critical situation?

#### Architecture Context
```
Current Infrastructure:
├─ 30 x t3.medium EC2 instances
├─ RDS Aurora - db.t3.large (2 replicas)
├─ 50 reserved Lambda concurrent executions
├─ Application frontend cached via CloudFront
└─ Load balancer with auto-scaling group

Target Infrastructure:
├─ 100 x t3.medium EC2 instances (or t3.large for better performance)
├─ RDS Aurora - db.r5.2xlarge (multi-AZ)
├─ 150 reserved Lambda concurrent executions
└─ Increased auto-scaling thresholds
```

#### Step-by-Step Implementation

**Step 1: Prepare High-Speed Variable Overrides**
```bash
# Pre-stage scaling configuration
cat > /tmp/emergency_scale.tfvars << 'EOF'
# Emergency scaling configuration
instance_count              = 100
instance_type               = "t3.large"
rds_instance_class          = "db.r5.2xlarge"
lambda_reserved_concurrency = 150
asg_min_size                = 80
asg_max_size                = 120
asg_desired_capacity        = 100
dynamodb_read_capacity      = 500
dynamodb_write_capacity     = 500
EOF

# Pre-validate variable format
terraform validate -var-file=/tmp/emergency_scale.tfvars
```

**Step 2: Parallel Planning and Execution Strategy**
```bash
#!/bin/bash
set -e

# Parallel approach: Generate plan while monitoring infrastructure
terraform init &
INIT_PID=$!

# Immediately start monitoring while init happens
echo "Starting resource monitoring..."
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T00:05:00Z \
  --period 60 --statistics Average &

wait $INIT_PID

# Fast planning with targeted resources
echo "Planning scaling changes..."
terraform plan \
  -var-file=/tmp/emergency_scale.tfvars \
  -target=aws_autoscaling_group.app \
  -target=aws_db_instance.primary \
  -target=aws_lambda_provisioned_concurrency_config.app \
  -out=/tmp/scaling.tfplan

# Validate plan doesn't include destructive changes
if terraform show /tmp/scaling.tfplan | grep -q "will be destroyed"; then
  echo "ERROR: Destructive changes detected"
  terraform show /tmp/scaling.tfplan | grep "will be destroyed"
  exit 1
fi

echo "Applying scaling changes (resource targeting for safety)..."
```

**Step 3: Implement Preferential Impact Strategy**
```bash
#!/bin/bash
# Scale in dependency order to minimize impact

ENVIRONMENTS=(asg rds lambda)

apply_scaling() {
  local component=$1
  
  case $component in
    asg)
      echo "Scaling Auto Scaling Group..."
      # Update ASG parameters WITHOUT replacing instances
      terraform apply -target=aws_autoscaling_group.app \
        -var-file=/tmp/emergency_scale.tfvars \
        -auto-approve
      
      # Wait for new instances to become healthy
      echo "Waiting for new instances to become healthy..."
      aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names "app-asg" \
        --query 'AutoScalingGroups[0].DesiredCapacity'
      
      # Monitor target healthy count
      while true; do
        HEALTHY=$(aws elbv2 describe-target-health \
          --target-group-arn "arn:aws:elasticloadbalancing:..." \
          --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' \
          --output text)
        
        if [[ $HEALTHY -ge 100 ]]; then
          echo "All targets healthy: $HEALTHY"
          break
        fi
        
        echo "Healthy targets: $HEALTHY/100, waiting..."
        sleep 10
      done
      ;;
      
    rds)
      echo "Scaling RDS (causes brief downtime)..."
      # RDS scaling causes brief unavailability - schedule in low-traffic period if possible
      terraform apply -target=aws_db_instance.primary \
        -var-file=/tmp/emergency_scale.tfvars \
        -auto-approve
      
      # Wait for RDS to be available
      aws rds wait db-instance-available --db-instance-identifier prod-postgres
      
      # Verify replication is healthy
      aws rds describe-db_instances --db-instance-identifier prod-postgres \
        --query 'DBInstances[0].DBInstanceStatus'
      ;;
      
    lambda)
      echo "Increasing Lambda concurrency..."
      terraform apply -target=aws_lambda_provisioned_concurrency_config.app \
        -var-file=/tmp/emergency_scale.tfvars \
        -auto-approve
      ;;
  esac
}

for env in "${ENVIRONMENTS[@]}"; do
  apply_scaling "$env"
done

echo "Scaling complete"
```

**Step 4: Enable Faster Provisioning**
```hcl
# Optimize Terraform for faster execution on large state

# Use targeted applies instead of full apply
resource "aws_autoscaling_group" "app" {
  name = "app-asg"
  
  # Increase health check grace period temporarily during scaling
  health_check_grace_period = var.emergency_mode ? 60 : 300
  
  # Use spot instances for cost efficiency during spikes
  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = var.emergency_mode ? 0 : 100
      spot_max_price = var.emergency_mode ? "0.50" : ""
    }
  }
  
  min_size = var.asg_min_size
  max_size = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  
  lifecycle {
    create_before_destroy = true
  }
}
```

**Step 5: Implement Cost Monitoring**
```bash
# Monitor costs of emergency scaling
echo "Cost impact of scaling changes:"

# Estimate monthly cost difference
OLD_COST=$(echo "30 * 0.0104 * 730" | bc)  # 30 t3.medium instances, monthly
NEW_COST=$(echo "100 * 0.0104 * 730" | bc) # 100 t3.medium instances

echo "EC2 cost increase: \$$OLD_COST -> \$$NEW_COST"

# Set billing alerts
aws cloudwatch put-metric-alarm \
  --alarm-name emergency-scaling-cost \
  --alarm-description "Alert on unexpected costs from emergency scaling" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 300 \
  --threshold 10000 \
  --comparison-operator GreaterThanThreshold
```

**Step 6: Post-Scaling Optimization**
```bash
# Once traffic stabilizes, optimize the infrastructure
# (Run after traffic spike subsides)

# Scale back to optimal levels
cat > /tmp/optimized_scale.tfvars << 'EOF'
instance_count              = 60  # Reduced from peak of 100
instance_type               = "t3.medium"  # Back to smaller type
rds_instance_class          = "db.r5.large"  # Reduced from db.r5.2xlarge
EOF

terraform plan -var-file=/tmp/optimized_scale.tfvars \
  -out=/tmp/optimize.tfplan

terraform apply /tmp/optimize.tfplan
```

#### Best Practices Demonstrated
- **Pre-staging configurations**: Ready to apply immediately without planning delays
- **Resource targeting**: Scales critical components without touching entire infrastructure
- **Dependency-aware ordering**: ASG before RDS to minimize impact
- **Health checking**: Verifies instances are healthy before declaring success
- **Cost monitoring**: Tracks financial impact of emergency scaling
- **Post-spike optimization**: Returns to normal configuration once crisis passes

---

### Scenario 5: Multi-Team Terraform State Management

#### Problem Statement
Your organization has 5 teams (Platform, Data, Security, ML, and Finance) each managing their own infrastructure through Terraform. However, there are shared resources (VPC, DNS, KMS keys) that multiple teams need to access and potentially modify. How do you structure Terraform state to prevent conflicts while allowing necessary cross-team dependencies?

#### Architecture Context
```
Team Infrastructure Dependencies:

Platform Team:
├─ VPC (shared)
├─ NAT Gateways
├─ KMS keys (shared)
└─ Service discovery (DNS)

Data Team:
├─ S3 buckets
├─ Redshift clusters
├─ Lake Formation setup
└─ Depends on: VPC, KMS keys

Security Team:
├─ GuardDuty
├─ Security Hub
├─ CloudTrail
└─ Depends on: S3 buckets (Data team)

ML Team:
├─ SageMaker endpoints
├─ ECR repositories
├─ Lambda inference functions
└─ Depends on: VPC, KMS keys

Finance Team:
├─ Cost allocation tags
├─ Budget alerts
├─ CloudFormation stacks
└─ Depends on: All team resources
```

#### Step-by-Step Implementation

**Step 1: Design Separated State with Remote Data Sources**
```bash
# Directory structure
infrastructure/
├─ platform/
│  ├─ vpc/
│  │  ├─ terraform.tf
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  ├─ kms/
│  └─ dns/
├─ data/
│  ├─ s3/
│  ├─ redshift/
│  └─ depends-on/  # References to platform team outputs
├─ security/
├─ ml/
└─ finance/
```

**Step 2: Implements Separate State Files for Each Team**
```hcl
# platform/vpc/terraform.tf
terraform {
  backend "s3" {
    bucket         = "myorg-terraform-state"
    key            = "platform/vpc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Platform team manages VPC
# Outputs are consumed by other teams via data sources
```

**Step 3: Use Remote State Data Source for Cross-Team Dependencies**
```hcl
# data/s3/main.tf
# Data team needs VPC info from Platform team

data "terraform_remote_state" "platform_vpc" {
  backend = "s3"
  config = {
    bucket = "myorg-terraform-state"
    key    = "platform/vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use platform team's outputs
resource "aws_s3_bucket_vpc_endpoint_configuration" "data_bucket_vpc_access" {
  bucket = aws_s3_bucket.data_lake.id
  
  vpc_endpoint_id = data.terraform_remote_state.platform_vpc.outputs.vpc_endpoint_id
}

# Output for downstream Security team
output "data_s3_bucket_arn" {
  value = aws_s3_bucket.data_lake.arn
}
```

**Step 4: Implement RBAC for State Access**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TerraformStateLocking",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/data-team-terraform"
      },
      "Action": [
        "dynamodb:DescribeTable",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-locks",
      "Condition": {
        "StringEquals": {
          "dynamodb:LeadingKeys": ["data/s3/terraform.tfstate"]
        }
      }
    },
    {
      "Sid": "DataTeamStateAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/data-team-terraform"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::myorg-terraform-state/data/*"
    },
    {
      "Sid": "PlatformReadOnlyStateAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/data-team-terraform"
      },
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::myorg-terraform-state/platform/*"
    }
  ]
}
```

**Step 5: Implement Change Notification System**
```bash
#!/bin/bash
# Notify dependent teams when state changes

notify_dependents() {
  local team=$1
  local changed_resources=$2
  
  case $team in
    platform)
      # Notify Data, ML teams of VPC/KMS changes
      aws sns publish --topic-arn arn:aws:sns:us-east-1:123456789012:platform-changes \
        --message "Platform team made changes affecting your infrastructure: $changed_resources"
      ;;
    data)
      # Notify Security team of S3 bucket changes
      aws sns publish --topic-arn arn:aws:sns:us-east-1:123456789012:data-changes \
        --message "Data team made S3 changes: $changed_resources"
      ;;
  esac
}

# After terraform apply
terraform show -json | jq '.values.outputs' > current_state.json

# Compare with previous state to identify changes
if ! diff -q previous_state.json current_state.json > /dev/null; then
  CHANGED=$(diff previous_state.json current_state.json | grep "<\|>" | head -5)
  notify_dependents "$TEAM" "$CHANGED"
fi

cp current_state.json previous_state.json
```

**Step 6: Implement State Validation Across Teams**
```bash
#!/bin/bash
# Validate that remote state references are still valid

validate_remote_state_refs() {
  echo "Validating cross-team state references..."
  
  # Find all remote_state data sources
  for file in $(find . -name "*.tf" -type f); do
    echo "Checking $file for remote_state references..."
    
    # Extract remote state paths
    grep -o 'key = "[^"]*"' "$file" | cut -d'"' -f2 | while read state_path; do
      # Try to access the state file
      if aws s3 ls "s3://myorg-terraform-state/$state_path" 2>/dev/null; then
        echo "✓ $state_path exists"
      else
        echo "✗ MISSING: $state_path - will cause apply failures"
      fi
    done
  done
}

validate_remote_state_refs
```

#### Best Practices Demonstrated
- **Separated state per team**: Each team manages only their infrastructure
- **Remote state data sources**: Enable safe cross-team dependencies
- **Read-only access for dependencies**: Data teams can read platform outputs but cannot modify
- **Change notifications**: Teams notified when dependencies change
- **IAM-based access control**: Prevents unauthorized access to other teams' state
- **Validation of remote references**: Catches broken dependencies early

---

## Interview Questions

### Question 1: "Walk us through a production incident where `terraform apply` failed halfway through. How did you recover?"

**Expected Answer from Senior DevOps Engineer**:

"This happened during a high-availability RDS failover scenario. We had 50+ resources in the apply, and the Lambda function creation succeeded, but the RDS security group modification failed due to dependency constraints. The state file now showed Lambda created but the security group unchanged.

Here's what I did:

1. **Immediate Assessment**: I ran `terraform state list` and `terraform show` to understand what partial state existed. The Lambda was in state, but the security group modification was not applied.

2. **Root Cause Analysis**: The issue was a cyclic dependency - the RDS instance needed the security group, but we were trying to modify the security group while RDS had active connections. I checked CloudWatch logs to confirm the exact error.

3. **Recovery Strategy**: Instead of re-running apply (which would fail on Lambda creation), I:
   - Removed the Lambda from state using `terraform state rm aws_lambda_function.processor`
   - Fixed the HCL to break the circular dependency
   - Applied only the security group changes using `-target` flag
   - Re-applied the Lambda separately

4. **Prevention**: I implemented a dependency review in our CI/CD pipeline that runs `terraform graph` and validates no circular dependencies exist before apply.

The critical lesson: **Partial state is recoverable using `terraform state` commands**. You don't discard the entire state—you surgically fix the inconsistency. And always use `-target` to apply problematic resources independently."

**Real-World Context**: This demonstrates understanding of:
- State file structure and manipulation
- Error diagnosis from partial failures
- Resource targeting for safe recovery
- Prevention through dependency analysis

---

### Question 2: "Explain the difference between a Terraform workspace and separate AWS accounts for managing dev vs. prod. When would you use each?"

**Expected Answer from Senior DevOps Engineer**:

"This is a critical architecture decision that many teams get wrong.

**Terraform Workspaces** are essentially state file naming mechanisms:
```
terraform.tfstate.d/dev/terraform.tfstate
terraform.tfstate.d/prod/terraform.tfstate
```

**What workspaces provide**:
- Different state files for different environments
- Quick switching between environments
- Resource count tracking per environment

**What workspaces do NOT provide**:
- Security isolation (shared backend and credentials)
- Blast radius containment (one misconfiguration affects all)
- Audit separation (hard to track who deployed what to which environment)
- Organizational boundaries (can't give prod access to some people, dev-only to others)

**Separate AWS Accounts** provide true isolation:
- Different IAM credentials per environment
- Separate billing and cost tracking
- Blast radius containment (bad deployment in dev doesn't cascade to prod)
- Compliance boundaries (prod account can have stricter controls)

**My recommendation**:
- **Use workspaces for**: Development-only environments where consistency matters more than isolation
- **Use separate accounts for**: Anything touching production, customer data, or paid resources

In practice, I implement:
- Single dev account with multiple workspaces (dev, feature-branches, qa)
- Separate staging account
- Separate production account with strict access controls
- Cross-account roles in prod only accessible via approval gates

This balances developer velocity (easy to create dev workspaces) with operational safety (production is fundamentally isolated)."

**Real-World Context**: This answer demonstrates:
- Architectural trade-offs understanding
- Security vs. convenience balance
- Practical implementation patterns used in enterprise

---

### Question 3: "How do you detect and respond to infrastructure drift in a production environment without causing outages?"

**Expected Answer from Senior DevOps Engineer**:

"Drift detection is crucial because manual changes outside Terraform inevitably happen. Here's my approach:

**Detection Strategy**:
1. **Automated Plan Runs**: Daily `terraform plan` scheduled at low-traffic times (3 AM), stored for comparison
2. **State Comparison**: Use `terraform refresh` (not apply) to update local state from actual AWS without making changes
3. **Selective Monitoring**: CI/CD systems run `terraform plan` with each PR merged, flagging unexpected changes

**Diagnosis Process**:
If drift is detected:
```bash
# Get affected resources
terraform plan -json | jq '.resource_changes[] | select(.change.actions[0] != "no-op")' > drift_changes.json

# Categorize by impact level
# - Metadata-only (tags, names): Safe to apply
# - Additive (new rules in security group): Safe
# - Destructive (database downsize): Requires manual review
```

**Response Based on Type**:
1. **Configuration Drift** (manual setting changes):
   - Terraform wins over manual changes
   - Apply the plan to restore desired state
   - Investigation happens after (what changed? why?)

2. **Orphaned Resources** (created outside Terraform):
   - Import into Terraform: `terraform import aws_instance.legacy i-123abc`
   - Add to Terraform code
   - Manage going forward

3. **Resource Deletion** (accidentally deleted):
   - Remove from Terraform state: `terraform state rm aws_instance.deleted`
   - Recreate via HCL
   - Investigation needed - how did this happen?

**Critical Safety Rules**:
- Never apply drift changes during business hours unless absolutely necessary
- Always review `terraform plan` output before applying drift fixes
- Use `-target` to apply drift fixes selectively, not all at once
- Monitor CloudWatch metrics during drift application

**Prevention**:
```bash
# AWS Config rules detect configuration drift
aws configservice put-config-rule --config-rule file://drift-detection-rule.json

# ChatOps notification for drift
terraform plan | grep -E 'will be|will change' | \
  curl -X POST -d @- https://slack.webhook.url
```

**Example from production**: We had a database parameter group modified manually to fix a performance issue. Drift detection caught it. Instead of applying Terraform to revert it, we:
- Imported the manual change into HCL
- Committed the fix to git
- This prevented recurrence of the issue

This demonstrates that drift isn't always 'bad'—sometimes manual changes discover needed optimizations."

**Real-World Context**: Shows:
- Proactive monitoring approach
- Risk categorization and response tiers
- Balance between automation and safety
- Learning from drift events

---

### Question 4: "You have 100+ AWS resources in Terraform state. Applying changes takes 20+ minutes. How do you optimize?"

**Expected Answer from Senior DevOps Engineer**:

"Large state files create operational pain. I'd tackle this systematically:

**Problem Analysis**:
```bash
# First, understand what's slow
terraform apply -json | jq '.timing' # See what takes time
```

**Root Causes Typically Are**:
1. **Provider API latency**: AWS API is slow
2. **Large state evaluation**: 100+ resources take time to parse
3. **Provider initialization**: Huge number of plugins loading
4. **Unnecessary dependencies**: Resources waiting on others unnecessarily

**Solution 1: State Splitting (Most Effective)**
```
Instead of:
terraform/
├─ main.tf (100+ resources)

Split into:
terraform-infrastructure/
├─ vpc-networking/
├─ databases/
├─ compute/
├─ security/
└─ monitoring/
```

Each module has its own state file. Parallel applies across modules.

**Solution 2: Increase Parallelism**
```bash
terraform apply -parallelism=20  # Default is 10
```
This applies 20 resources simultaneously instead of 10. From AWS API limits.

**Solution 3: Use Modules Correctly**
```hcl
# Bad: creates dependencies
resource "aws_instance" "app" {
  count = 50
  # all 50 instances depend on each other implicitly
}

# Good: no unintended dependencies
resource "aws_instance" "app" {
  for_each = var.instance_configs
  # Only explicit dependencies matter
}
```

**Solution 4: Implement Targeted Applies**
```bash
# Don't apply everything every time
terraform apply -target=aws_autoscaling_group.app \
                -target=aws_launch_configuration.app
```
Only apply what changed, verified by git diff.

**Solution 5: Separate Data Sources From Infrastructure**
```hcl
# This triggers API calls every plan:
data "aws_ami" "latest" {
  # queries AWS each time
}

# Instead:
variable "ami_id" {
  type = string
  # Inject pre-computed, don't query during plan
}
```

**Real Production Example**:
One client had 150 resources taking 25 minutes. We:
1. Split state into 6 modules (2-3 min each) - now 10 min parallelized
2. Increased parallelism from 10 to 15 - saved 2 minutes
3. Removed redundant data sources - saved 3 minutes
4. Used variables for static lookups - saved 1 minute

Final result: 5-7 minutes for full apply, parallelizable to 10-15 minutes for full infrastructure.

**Monitoring to Catch Regressions**:
```bash
# Track apply time
time terraform apply | tee /var/log/terraform-apply-$(date +%s).log

# Alert if apply time exceeds threshold
grep 'Apply complete' /var/log/terraform-apply-*.log | \
  awk '{print $NF}' | \
  xargs | \
  awk '{if ($1 > 10*60) print "ALERT: apply exceeded 10 minutes"}'
```"

**Real-World Context**: Shows:
- Performance profiling methodology
- Root cause analysis
- Multiple solution approaches with trade-offs
- Practical measurement and monitoring

---

### Question 5: "Describe a time when you lost access to Terraform state and had to recover. What was your procedure?"

**Expected Answer from Senior DevOps Engineer**:

"This happened with a client who lost S3 bucket credentials. We had 40 resources in state that we couldn't access.

**Scenario**:
- S3 bucket holding Terraform state was accidentally set to private
- IAM role used by CI/CD was deleted
- Terraform couldn't read or write state
- Services were running fine (infrastructure existed)
- But we couldn't manage infrastructure changes

**Recovery Procedure**:

**Phase 1: Restore Access (1 hour)**
```bash
# Recreate IAM role with S3 permissions
aws iam create-role --role-name terraform-backend-access \
  --assume-role-policy-document file://trust-policy.json

aws iam attach-role-policy --role-name terraform-backend-access \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

# Restore S3 bucket public access (temporarily, for recovery)
aws s3api put-bucket-acl --bucket myorg-terraform-state --acl private
aws s3api put-bucket-policy --bucket myorg-terraform-state \
  --policy file://bucket-policy.json
```

**Phase 2: Verify State Integrity (30 min)**
```bash
# Download state from S3
aws s3 cp s3://myorg-terraform-state/prod/terraform.tfstate ./

# Validate JSON integrity
jq empty terraform.tfstate

# Compare state against actual resources
for instance in $(terraform state list | grep aws_instance); do
  INSTANCE_ID=$(terraform state show $instance | grep id)
  aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name'
done
```

**Phase 3: Audit Changes During Outage (15 min)**
```bash
# Check if manual changes occurred during the outage
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=CreateInstance \
  --start-time 2024-01-01T00:00:00Z --end-time 2024-01-02T00:00:00Z | jq '.Events | length'

# If manual changes, import them
terraform import aws_instance.emergency_instance i-newinst123
```

**Phase 4: Test Operations (20 min)**
```bash
# Small test apply to verify state is working
terraform plan -target=aws_security_group.test

# If plan succeeds, state is recoverable
terraform apply -target=aws_security_group.test -auto-approve
```

**Phase 5: Prevention Implementation (2 hours)**
```bash
# 1. Enable S3 versioning
aws s3api put-bucket-versioning --bucket myorg-terraform-state \
  --versioning-configuration Status=Enabled

# 2. Use IAM policies to prevent bucket deletion
aws s3api put-bucket-policy --bucket myorg-terraform-state \
  --policy file://prevent-deletion.json

# 3. Replicate state to backup account
aws s3api put-bucket-replication --bucket myorg-terraform-state \
  --replication-configuration file://replication.json

# 4. Enable MFA delete protection
aws s3api put-object-acl --bucket myorg-terraform-state \
  --key prod/terraform.tfstate \
  --mfa \"arn:aws:iam::account:mfa/admin 123456\"

# 5. Implement state backup job
0 2 * * * aws s3 cp s3://myorg-terraform-state/prod/terraform.tfstate \
  s3://myorg-terraform-backups/$(date +%Y-%m-%d)/terraform.tfstate
```

**Key Learnings**:
1. **State is critical operational data**, not just a convenience
2. **Separate backup mechanics from primary access** (versioning ≠ backup)
3. **Test recovery procedures regularly**
4. **Prevent common deletion patterns** at IAM level

The entire recovery took 4 hours. Now we do quarterly state recovery drills to ensure the process is current."

**Real-World Context**: Demonstrates:
- Crisis response procedure
- State integrity verification
- Operational lesson application
- Prevention architecture

---

### Question 6: "How do you handle Terraform provider breaking changes across your organization?"

**Expected Answer from Senior DevOps Engineer**:

"Provider updates are high-risk because they can introduce breaking changes affecting hundreds of resources. Here's my strategy:

**Scenario Experience**:
AWS provider 4.x to 5.x had attribute deprecations. We had 150+ modules and 500+ resources managed by the provider.

**Approach**:

**Step 1: Version Pinning Strategy**
```hcl
# Always pin provider versions
terraform {
  required_providers {
    aws = {
      source  = \"hashicorp/aws\"
      version = \"~> 5.20\"  # Allows patch updates, pins minor version
    }
  }
  
  required_version = \"~> 1.5\"  # Terraform version itself
}

# Lock file captures exact version
# .terraform.lock.hcl committed to git
```

**Step 2: Pre-Staging Breaking Changes**
```bash
# Identify all provider versions in use
for dir in $(find . -name 'main.tf' -type f); do
  dirname $dir | xargs -I {} grep 'version' {}/terraform.tf
done > provider-versions.txt

# Find deprecated attributes
terraform validate -json 2>/dev/null | \
  jq '.checks[] | select(.summary | contains(\"deprecated\"))'
```

**Step 3: Migration Path Planning**
Breaking change in AWS provider: `delete_on_termination` moved to root_block_device
```hcl
# Old (deprecated in v5.x):
resource \"aws_instance\" \"app\" {
  delete_on_termination = true  # ← moved to sub-block
}

# New:
resource \"aws_instance\" \"app\" {
  root_block_device {
    delete_on_termination = true
  }
}
```

**Step 4: Staged Migration (Low Risk)**
```bash
#!/bin/bash
# Migrate across teams systematically

TEAMS=(platform data security ml)

for team in \"${TEAMS[@]}\"; do
  echo \"Migrating $team...\"
  
  # 1. Update provider version
  cd infrastructure/$team
  sed -i 's/version = \"~> 4\"/version = \"~> 5\"/' terraform.tf
  
  # 2. Run terraform init to update lock file
  terraform init
  
  # 3. Generate plan to see all changes
  terraform plan -out=migration.tfplan
  
  # 4. Review changes (automated checks)
  if terraform show migration.tfplan | grep -q \"will be destroyed\"; then
    echo \"ERROR: Destructive changes detected. Manual review required.\"
    exit 1
  fi
  
  # 5. Apply during maintenance window
  terraform apply migration.tfplan
  
  # 6. Validate no configuration drift
  terraform plan | grep \"no changes\"
done
```

**Step 5: Automated Detection**
```bash
# CI/CD check for provider version consistency
terraform/
├─ ci-scripts/
│  └─ check-provider-versions.sh
```

```bash
#!/bin/bash
# Ensure all modules use consistent provider versions

EXPECTED=\"5.20\"
VERSIONS=$(find . -name 'terraform.tf' -exec grep 'version' {} + | \
  grep -o '\"~> [0-9.]*\"' | sort -u)

if [[ $(echo $VERSIONS | wc -w) -gt 1 ]]; then
  echo \"ERROR: Inconsistent provider versions found: $VERSIONS\"
  echo \"All must use ~> $EXPECTED\"
  exit 1
fi
```

**Step 6: Rollback Plan**
```bash
# Document rollback in case issues arise
# Example: V5.20 introduces bug, need to rollback to 5.19
terraform {
  required_providers {
    aws = {
      source  = \"hashicorp/aws\"
      version = \"5.19\"  # Pinned to exact version for rollback
    }
  }
}

terraform init -upgrade
terraform plan  # Should show minimal changes (just version updates)
terraform apply
```

**Prevention Measures**:
1. **Require upgrade PRs**: Provider updates reviewed separately
2. **Test in non-prod first**: Dev/staging upgraded before production
3. **Vendor changelog**: Subscribe to AWS provider release notes
4. **Maintain changelog**: Track all version changes in CHANGELOG.md

**Real Metrics**:
- Provider updates happen quarterly (controlled)
- Breaking changes identified in dev environment before prod
- Migration average: 3 hours per 100 resources
- Zero unplanned downtime from provider issues

This prevents the scenario where a naive `terraform init -upgrade` breaks production."

**Real-World Context**: Demonstrates:
- Version management discipline
- Risk mitigation approach
- Organizational coordination
- Breaking change handling

---

### Question 7: "Explain how you would implement zero-downtime Terraform updates to a running application."

**Expected Answer from Senior DevOps Engineer**:

"Zero-downtime updates require careful orchestration. Here's a real example:

**Scenario**: Updating RDS instance type from t3.large to r5.large for an active production database. This requires brief downtime if done incorrectly.

**Zero-Downtime Strategy**:

**Step 1: Database-Specific Approach (For RDS)**
```hcl
# Enable Multi-AZ deployment first (if not already)
resource \"aws_db_instance\" \"primary\" {
  multi_az           = true  # Critical for zero-downtime
  skip_final_snapshot = false  # Protect against accidental deletion
  
  # Update instance class with apply_immediately = false
  # This triggers failover to standby, not destructive replacement
  instance_class = \"db.r5.large\"
  apply_immediately = false  # Scheduled during maintenance window
}
```

**Step 2: Orchestrate Failover**
```bash
#!/bin/bash
# Trigger Multi-AZ failover (causes brief DNS update, ~1 min)

# 1. Verify Multi-AZ is enabled
aws rds describe-db-instances --db-instance-identifier prod-db \
  --query 'DBInstances[0].MultiAZ'

# 2. Start Terraform apply
terraform apply -target=aws_db_instance.primary

# This triggers failover to replica:
# - Standby (r5.large) becomes primary
# - Old primary (t3.large) becomes standby in background
# - Application briefly reconnects (managed by Aurora proxy)

# 3. Monitor failover
aws rds describe-db_instances --db-instance-identifier prod-db \
  --query 'DBInstances[0].DBInstanceStatus'
# Watch for: available → storage-optimization → available
```

**Step 3: Connection Resilience (Application-Level)**
```python
# Application must handle brief connection loss
import time
from sqlalchemy import create_engine, exc
from sqlalchemy.pool import QueuePool

engine = create_engine(
    'postgresql://user:pass@prod-db.amazonaws.com/mydb',
    poolclass=QueuePool,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,  # ← Validates connections before use
    pool_recycle=3600,   # ← Recycles stale connections
    echo_pool=True
)

# With this config, 99% of requests survive RDS failover
```

**Step 4: Load Balancer Draining (For Compute Updates)**
```bash
# Updating EC2 instances without downtime

# 1. Create new launch configuration with updated AMI
terraform apply -target=aws_launch_configuration.app_new

# 2. Update ASG with connection draining
resource \"aws_autoscaling_group\" \"app\" {
  health_check_grace_period = 0  # Allow quick recovery
  default_cooldown          = 0  # No cooldown between replacements
  
  lifecycle {
    create_before_destroy = true  # ← Creates new before destroying old
  }
}

# 3. Gradually replace instances
# (Not done by Terraform - use AWS Console or API)
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name app-asg \
  --launch-configuration-name app_new

# Starts terminating old instances, but ASG maintains min_size
# Load balancer drains connections within 30s before termination
# New instances launched automatically
```

**Step 5: Rolling Updates with Validation**
```bash
#!/bin/bash
# Update instances one at a time with health checks

DESIRED=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names app-asg \
  --query 'AutoScalingGroups[0].DesiredCapacity')

for ((i=0; i<DESIRED; i++)); do
  echo \"Updating instance $((i+1)) of $DESIRED...\"
  
  # Set desired capacity down by 1 (force termination of 1 instance)
  aws autoscaling set-desired-capacity \
    --auto-scaling-group-name app-asg \
    --desired-capacity $((DESIRED-1))
  
  # Wait for new instance to become healthy
  while true; do
    HEALTHY=$(aws elbv2 describe-target-health \
      --target-group-arn ... \
      --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)')
    
    if [[ $HEALTHY -eq $DESIRED ]]; then
      echo \"Target healthy. Continuing...\"
      break
    fi
    
    sleep 5
  done
  
  # If any instance fails, stop rolling update
  if ! curl -f https://localhost/health > /dev/null; then
    echo \"Health check failed! Rolling update aborted.\"
    # Restore desired capacity
    aws autoscaling set-desired-capacity \
      --auto-scaling-group-name app-asg \
      --desired-capacity $DESIRED
    exit 1
  fi
done
```

**Step 6: Monitoring During Update**
```bash
# Real-time monitoring to catch issues immediately

watch -n 5 'aws elbv2 describe-target-health \\
  --target-group-arn arn:aws:elasticloadbalancing:... | \\
  jq \".TargetHealthDescriptions | group_by(.TargetHealth.State) |  map({state: .[0].TargetHealth.State, count: length})\"'

# Monitor error rates
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --start-time 2024-01-01T10:00:00Z \
  --end-time 2024-01-01T10:10:00Z \
  --period 60 \
  --statistics Sum
```

**Critical Principles**:
1. **Blue-Green Architecture**: New resources created before old destroyed
2. **Health Checks**: Every step validated with health checks
3. **Gradual Rollout**: Change percentage of resources, not all at once
4. **Instant Rollback**: If health check fails, revert immediately
5. **Monitoring**: Real-time metrics during changes

**Comparison**:
- **Apply immediately** (risky): brief outage (seconds to minutes)
- **Scheduled maintenance** (safe): brief outage during known window
- **Blue-green** (zero-downtime): no outage, higher infrastructure cost

For production, blue-green is worth the cost."

**Real-World Context**: Shows:
- Application-level resilience understanding
- AWS service-specific knowledge
- Health checking and monitoring
- Rollback strategies

---

### Question 8: "You need to implement Terraform across a new organization with 200+ developers. What governance model would you establish?"

**Expected Answer from Senior DevOps Engineer**:

"This is an organizational, not just technical, problem. I'd implement tiered governance:

**Tier 1: Platform Team (5-10 people)**
Responsible for:
- Shared infrastructure modules (VPC, databases, security)
- Backend configuration and state management
- Provider version upgrades
- Compliance and audit policies

```hcl
# shared-modules/
├─ vpc/
├─ rds/
├─ eks/
└─ security-groups/

# Each module has:
# - Comprehensive examples
# - Security best practices
# - Approval gates for changes
```

**Tier 2: Team Infrastructure (Development, Data, ML Teams)**
Each team:
- Uses platform modules
- Manages team-specific infrastructure
- Contributes module improvements

```
Data Team:
├─ Uses: vpc module from platform
├─ Manages: S3, Redshift, Glue
├─ Cannot: Modify VPC, security policies
```

**Tier 3: Self-Service (Developers)**
Developers:
- Deploy applications (not infrastructure)
- Use Helm/CloudFormation for app deployments
- Submit infrastructure requests to team

**Governance Implementation**:

**Level 1: Code Review Process**
```bash
# All Terraform changes require review
# .github/CODEOWNERS
infrastructure/shared-modules/* @platform-team
infrastructure/data-team/* @data-team-leads +@data-team

# CI/CD validates PR
- terraform validate
- terraform plan (dry-run)
- policy checks (Sentinel / OPA)
- cost estimation
```

**Level 2: Terraform Cloud/Enterprise**
```hcl
# Centralized state management
# Enforce policies before apply
# Separate workspaces per team/environment

# Sentinel policy examples:
main = rule(aws_s3_bucket_public_access_block_enabled)

rule \"aws_s3_bucket_public_access_block_enabled\" {
  all aws_s3_bucket as bucket {
    bucket.tags[\"Environment\"] in [\"prod\", \"staging\"] implies
    bucket.server_side_encryption_configuration != null
  }
}
```

**Level 3: Cost Governance**
```bash
# Estimate costs before apply
terraform plan -json | jq '.cost_estimation'

# Set budgets per team/environment
aws budgets create-budget --account-id 123456789 \\
  --budget file://budget-data-prod.json \\
  --notifications-with-subscribers file://notifications.json
```

**Level 4: State Management**
```bash
# Separate state per team to prevent blast radius
backend-config/
├─ platform.tfbackend
├─ data-team.tfbackend
├─ security-team.tfbackend
└─ ml-team.tfbackend

# Controls:
terraform {
  backend \"s3\" {
    bucket = \"myorg-terraform-state\"
    key    = \"data-team/terraform.tfstate\"
    
    # Prevent cross-team state access
    dynamodb_table = \"terraform-locks\"
  }
}
```

**Level 5: Training & Onboarding**
```bash
training/
├─ terraform-basics.md
├─ module-usage-guide.md
├─ approval-process.md
├─ disaster-recovery-runbooks.md
└─ examples/
    ├─ basic-vpc.tf
    ├─ basic-rds.tf
    └─ basic-iam.tf
```

**Rollout Timeline**:

**Month 1: Foundation**
- Set up Terraform Cloud
- Create shared modules
- Platform team trained
- CI/CD pipeline established

**Month 2: Early Adopters**
- Onboard 2-3 teams (volunteer early adopters)
- Refine processes based on feedback
- Train team leads on Terraform

**Month 3: Broader Rollout**
- Onboard data, ml teams
- Establish support mechanism
- Run training sessions

**Month 4: Developer Self-Service**
- Expose simplified interfaces for developers
- Provide IaC templates for common patterns
- Support complex scenarios

**Critical Rules**:
1. **No credentials in code** (use AWS IAM roles)
2. **State access control** (IAM policies on S3 and DynamoDB)
3. **Approval gates** (CI/CD enforces reviews before apply)
4. **Cost transparency** (every team sees their infrastructure costs)
5. **Audit logging** (CloudTrail tracks all state modifications)

**Common Anti-Patterns to Prevent**:
- Developers with terraform apply permissions (use CI/CD only)
- Shared AWS credentials (use roles, not keys)
- No version control (all HCL in git)
- Monolithic state file (split by team)

**Measurement**:
- Track time to provision infrastructure (goal: <1 hour)
- Track approval cycle time (goal: Pull Request merged within 1 day)
- Track failed applies (goal: <2% failure rate)
- Track state consistency (goal: zero drift outside Terraform)

This approach scales from 5 developers to 500+."

**Real-World Context**: Shows:
- Organizational design thinking
- Scalability planning
- Cost and security considerations
- Training and change management

---

### Question 9: "Explain the pros and cons of using Terraform monorepo vs. multi-repo approach, and when you'd choose each."

**Expected Answer from Senior DevOps Engineer**:

"This decision significantly impacts developer velocity and blast radius. Let me compare:

**Monorepo Approach** (One repository, all infrastructure)
```
terraform/
├─ platform/
├─ data/
├─ security/
├─ ml/
└─ finance/
```

**Pros**:
- Single source of truth (easier to track dependencies)
- Atomic changes across teams (VPC change applies to all teams simultaneously)
- Easier refactoring (rename an output, refactor all consumers)
- Single CI/CD pipeline (simpler to manage)
- Historical correlation (see what changed together)

**Cons**:
- Blast radius is organization-wide (one bad change affects everyone)
- Slow CI/CD (every team waits for all validations)
- Permission management complex (some teams can see prod configs for other teams)
- Merge conflicts (multiple teams editing same repository)
- Cannot deploy independently (all-or-nothing)

---

**Multi-Repo Approach** (Repository per team/application)
```
terraform-platform/       (Platform team)
terraform-data/          (Data team)
terraform-security/      (Security team)
terraform-ml/            (ML team)
terraform-shared-modules/ (Shared modules)
```

**Pros**:
- Team autonomy (Data team can deploy independently)
- Reduced blast radius (one team's bug doesn't affect others)
- Parallel development (teams don't block each other)
- Faster CI/CD (smaller validation scope)
- Permission management simple (each team repo has own access)
- Clear ownership (one team responsible for one repo)

**Cons**:
- Dependency tracking is harder (must use remote_state for cross-team communication)
- Duplicated code (modules must be versioned, published)
- Difficult atomic changes (VPC change requires coordinated pushes)
- Version coordination needed (shared module updates)
- Harder to refactor across boundaries

---

**My Recommendation**:

**Use Monorepo if**:
- Small team (<20 engineers)
- Tightly coupled infrastructure (Lambda functions, API Gateway, Database)
- Frequent cross-team changes
- Strong CI/CD and code review discipline

**Use Multi-Repo if**:
- Large organization (50+ engineers)
- Independent teams (Data team changes rarely affect ML team)
- Different deployment frequencies (Security updates quarterly, Data team weekly)
- Teams want independent release cycles
- Cost tracking per team is important

**Real Example**:

**Company A (Startup, 30 engineers)** → Monorepo
- Single repository with platform and application infrastructure
- PR-based workflow with 2-person approval
- Deploy all environments from CI/CD
- Developers understand entire infrastructure

**Company B (Enterprise, 200 engineers)** → Multi-Repo
- Platform team maintains shared modules in terraform-shared-modules
- Data team: terraform-data-platform (independent 2x/week deploys)
- ML team: terraform-ml (independent 3x/week deploys)
- Security team: terraform-security (independent, quarterly updates)
- Cross-team communication via remote_state data sources

**Hybrid Approach (Recommended for medium enterprises)**:
```
terraform/                 (Monorepo)
├─ shared-modules/         (Versioned, published to registry)
├─ platform/               (Core infrastructure)
└─ environments/
    ├─ dev/
    ├─ staging/
    └─ prod/

terraform-data/             (Separate repo)
└─ Uses: shared-modules (via terraform registry)

terraform-ml/               (Separate repo)
└─ Uses: shared-modules (via terraform registry)
```

**Trade-offs Summary**:

| Aspect | Monorepo | Multi-Repo |
|--------|----------|-----------|
| Development Speed | Fast (shared code, easy refactoring) | Slower (duplication, versioning overhead) |
| Blast Radius | Org-wide | Team-level |
| Deployment Control | Central (CI/CD enforced) | Distributed (self-service) |
| Cost Visibility | Easy (all in one place) | Requires aggregation |
| Scalability | Breaks at 50+ teams | Scales to 500+ teams |
| Cross-Team Deps | Trivial (same repo) | Complex (remote_state coordination) |

**Decision Tree**:
```
Are you < 20 engineers?
├─ Yes → Use Monorepo
└─ No
   ├─ Tightly coupled infrastructure?
   │  ├─ Yes → Consider Monorepo + strict team boundaries
   │  └─ No → Continue
   ├─ Different deployment frequencies needed?
   │  ├─ Yes → Use Multi-Repo
   │  └─ No → Continue
   └─ Need team autonomy?
      ├─ Yes → Use Multi-Repo
      └─ No → Use Monorepo with strong governance
```

I've seen monorepos fail when they grew to 10+ teams. I've seen multi-repos create versioning chaos. The sweet spot depends on your culture and team maturity."

**Real-World Context**: Demonstrates:
- Organizational trade-offs understanding
- Scalability considerations
- Clear decision framework
- Team autonomy vs. control balance

---

### Question 10: "You discover that someone manually modified a database security group rule in production, bypassing Terraform. The application is working fine with the manual change. How do you handle this?"

**Expected Answer from Senior DevOps Engineer**:

"This is a common scenario that tests whether an engineer understands Terraform's philosophy and operational risk.

**Initial Assessment**:
```bash
# First, understand the manual change
aws ec2 describe-security-groups --group-id sg-prod-db \\
  --query 'SecurityGroups[0].IpPermissions'

# Check what Terraform has
terraform state show aws_security_group.prod_db

# Compare
# Manual: allows inbound from 0.0.0.0/0 on port 5432  (WRONG!)
# Terraform: allows inbound from 10.0.0.0/24:5432 only
```

**Why This Is Critical**:
1. **State Divergence**: Next Terraform apply would remove the manual rule (potential disruption)
2. **Security**: 0.0.0.0/0 exposes the database to the internet
3. **Audit Trail**: Manual changes hide the actual configuration
4. **Repeatability**: Cannot reproduce this configuration reliably

**Response** (Depends on Context):

**Option 1: Manual Change Was a Bug/Security Issue**
```bash
# Revert immediately
# Identify what enabled the manual rule
aws ec2 revoke-security-group-ingress --group-id sg-prod-db \\
  --protocol tcp --port 5432 --cidr 0.0.0.0/0

# Verify the application still works
curl -f https://myapp.com/health

# Add monitoring to prevent recurrence
aws cloudtrail create-trail --name sg-modification-trail
```

**Option 2: Manual Change Reveals a Missing Terraform Configuration**
```
Scenario: Developer added rule to allow Jenkins CI/CD to connect
Current state: Terraform doesn't know about Jenkins CIDR
```

```hcl
# Update HCL to capture the intentional change
variable \"jenkins_cidr\" {
  type = string
  description = \"Jenkins CI/CD server CIDR\"
  default = \"10.0.99.0/24\"
}

resource \"aws_security_group_rule\" \"postgres_from_jenkins\" {
  type              = \"ingress\"
  from_port         = 5432
  to_port           = 5432
  protocol          = \"tcp\"
  cidr_blocks       = [var.jenkins_cidr]
  security_group_id = aws_security_group.prod_db.id
}

# Import the manual rule into Terraform
terraform import aws_security_group_rule.postgres_from_jenkins sgr-12345678

# Commit to version control
git add main.tf
git commit -m \"Add Jenkins CIDR to database security group (previously manual)\"
```

**Option 3: Change Was Intentional Debug/Troubleshooting**
```
Scenario: Someone added 0.0.0.0/0 to troubleshoot connectivity issues.
The issue is now fixed, but the rule was never removed.
```

```bash
# 1. Risk assessment
aws ec2 describe-network-interfaces --filters \"Name=group-id,Values=sg-prod-db\" \\
  --query 'NetworkInterfaces[].Association.PublicIp'
# If database has public IP, exposure is HIGH

# 2. Timeline
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AuthorizeSecurityGroupIngress \\
  --query 'Events | sort_by(@, &EventTime) | [-1:]'
# When was this added? By whom?

# 3. Decision
if [[ \"$RISK_LEVEL\" == \"HIGH\" ]]; then
  # Revert immediately, investigate root cause offline
  aws ec2 revoke-security-group-ingress --group-id sg-prod-db \\
    --protocol tcp --port 5432 --cidr 0.0.0.0/0
  
  # Root cause analysis
  # Why did troubleshooting need 0.0.0.0/0?
  # What's the real fix?
  
  # Update Terraform with proper fix, not debug workaround
  git add main.tf && git commit -m \"Fix database connectivity issue properly\"
fi
```

**General Procedure** (Best Practices):

**Step 1: Never Ignore**
Even if working fine, drift creates operational debt. Address it immediately.

**Step 2: Root Cause Analysis**
- Who made the change? (Check CloudTrail)
- Why did they need to? (Talk to them)
- Is there a legitimate business need? (Or was it a debugging workaround?)

**Step 3: Classify the Change**
- **Bug**: Revert, add controls to prevent recurrence
- **Missing Feature**: Import into Terraform, commit to version control
- **Workaround**: Fix underlying issue properly, don't perpetuate workaround

**Step 4: Update Terraform**
Either revert the manual change OR import it into Terraform (codify it).
Never leave drift unaddressed.

```bash
# Quick test
terraform plan  # Should show no changes after importing/reverting
```

**Step 5: Prevention**
```bash
# 1. Enable change notifications
aws sns create-topic --name security-group-changes
aws events put-rule --name sg-change-detection \\
  --event-pattern '{\"source\":[\"aws.ec2\"],\"detail-type\":[\"AWS API Call via CloudTrail\"],\"detail\":{\"eventName\":[\"AuthorizeSecurityGroupIngress\",\"RevokeSecurityGroupIngress\"]}}'

# 2. Require IR approvals via Slack
curl -X POST https://hooks.slack.com/... \\
  -d '{\"text\":\"⚠️  SG modified: sg-prod-db by user123\"}'

# 3. Implement IAM policy to require Terraform
# Option: Block manual security group modifications, allow only through Terraform role

# 4. Mandatory code review for security group changes
# All changes to prod security groups require 2-person approval
```

**Organization-Level Prevention**:
1. **Education**: Why drift matters (Terraform consistency enables safe scaling)
2. **Tooling**: drift detection (daily terraform plan)
3. **Process**: No manual changes in production (use CI/CD for everything)
4. **Culture**: \"Code reviews, not console clicks\"

**Honest Assessment**:
In real organizations, manual changes happen. The question is how quickly you detect and remediate them. The best practice isn't preventing them entirely (impossible), but detecting them fast enough to fix before they cause problems."

**Real-World Context**: Demonstrates:
- Pragmatic rather than dogmatic thinking
- Root cause analysis skills
- Risk assessment ability
- Culture and process understanding

---

**Document Version**: 3.0  
**Last Updated**: March 7, 2026  
**Audience**: DevOps Engineers (5–10+ years experience)

---

**Document Version**: 1.0  
**Last Updated**: March 7, 2026  
**Audience**: DevOps Engineers (5–10+ years experience)
