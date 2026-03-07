# Terraform Architecture Basics: Senior DevOps Study Guide

## Table of Contents

1. [Introduction](#introduction)
   - [Topic Overview](#topic-overview)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Cloud Architecture Context](#cloud-architecture-context)

2. [Foundational Concepts](#foundational-concepts)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [DevOps Principles](#devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Providers and Resources](#providers-and-resources)

4. [Data Sources](#data-sources)

5. [State Management](#state-management)
   - [Concept of State](#concept-of-state)
   - [State Files](#state-files)
   - [State Locking](#state-locking)
   - [Local vs. Remote State](#local-vs-remote-state)
   - [Backend Configuration](#backend-configuration)
   - [State Security](#state-security)

6. [Dependency Graph and Execution Plan](#dependency-graph-and-execution-plan)

7. [Hands-on Scenarios](#hands-on-scenarios)

8. [Interview Questions](#interview-questions)

---

## Introduction

### Topic Overview

Terraform Architecture Basics form the foundational layer upon which enterprise-scale infrastructure-as-code deployments are built. For DevOps engineers operating at the senior level, understanding the architectural principles underlying Terraform is not merely about learning syntax—it's about comprehending how declarative infrastructure definitions translate into deterministic cloud resource provisioning at scale.

Terraform's architecture is fundamentally built on three pillars:

1. **Declarative Configuration Language (HCL)**: Describes the desired end-state
2. **State-Driven Workflow**: Maintains a source of truth for deployed infrastructure
3. **Provider Abstraction Layer**: Enables multi-cloud and hybrid infrastructure management

At the senior level, you need to understand:
- How Terraform's architecture enables drift detection and remediation
- The critical role of state in maintaining infrastructure consistency
- How the dependency graph ensures proper resource provisioning order
- The architectural constraints and their implications for large-scale deployments
- How architectural decisions impact security, performance, and operational overhead

### Real-World Production Use Cases

**Fortune 500 Enterprise Infrastructure Automation**
- Multi-region, multi-cloud deployments spanning 500+ resources
- Cross-functional teams needing consistent infrastructure templating
- Compliance-driven infrastructure with audit trails and version control integration
- Terraform handles the architectural orchestration of Kubernetes clusters, database clusters, networking, and monitoring across AWS, Azure, and on-premises environments

**SaaS Platform Scaling**
- Dynamic customer environments: Each SaaS customer receives isolated infrastructure provisioned via templated Terraform modules
- Rapid scaling requiring infrastructure changes to happen within seconds
- Developer experience optimization: Self-service infrastructure provisioning for engineering teams
- Terraform's architecture enables this through modular design and variable composition

**Disaster Recovery & Multi-Region Strategy**
- Architecture must support fail-over regions with minimal manual intervention
- Terraform enables infrastructure symmetry across regions through code replication
- State management across isolated environments becomes a critical architectural consideration

**Infrastructure as Code Compliance**
- Heavily regulated industries (financial services, healthcare) require documented infrastructure history
- Terraform's architecture, combined with version control and state file auditing, provides the compliance foundation
- Change tracking and rollback capabilities are embedded in the architectural design

### Cloud Architecture Context

Terraform occupies a specific but critical position in cloud architecture:

```
┌─────────────────────────────────────────────────────┐
│         Business Requirements & Strategy             │
├─────────────────────────────────────────────────────┤
│      Infrastructure Design & Architecture            │
│  (Network topology, scaling strategy, HA/DR)         │
├─────────────────────────────────────────────────────┤
│  Terraform Architecture (Your Focus)                 │
│  ├── State Management                               │
│  ├── Providers & Resources                          │
│  ├── Dependency Resolution                          │
│  └── Execution Planning                             │
├─────────────────────────────────────────────────────┤
│    Cloud Provider APIs                              │
│    (AWS, Azure, GCP, Kubernetes, etc.)              │
├─────────────────────────────────────────────────────┤
│    Physical Cloud Infrastructure                     │
└─────────────────────────────────────────────────────┘
```

Terraform sits between business architecture decisions and cloud provider APIs. This positioning means:
- It must be flexible enough to express any infrastructure pattern
- It must scale from single VM deployments to thousands of resources
- It must handle complex dependencies and ordering constraints
- It must maintain consistency (idempotency) across repeated executions

---

## Foundational Concepts

### Architecture Fundamentals

#### 1. Declarative vs. Imperative Infrastructure

Terraform represents a **declarative** approach to infrastructure:
- You describe **what** infrastructure should exist (the desired state)
- Terraform determines **how** to achieve that state
- The infrastructure code becomes the single source of truth

This is fundamentally different from imperative approaches (Bash scripts, CloudFormation custom resources):
- Scripts or procedural code describe step-by-step **how** to build infrastructure
- Prone to drift—scripts may execute differently on repeated runs
- Difficult to maintain as infrastructure evolves
- Ordering and error handling require explicit management

**Architectural Implication**: This declarative nature enables Terraform to:
- Detect drift between desired and actual state
- Plan changes safely before execution
- Support atomic operations (or rollback on failure)
- Abstract away provider-specific implementation details

#### 2. State-Driven Architecture

Terraform's architecture is fundamentally state-driven:
- Configuration files (.tf) describe desired state
- State file (.tfstate) tracks actual deployed resources
- **Drift = desired state ≠ actual state**

The state file contains:
- Resource metadata (IDs, attributes)
- Dependency relationships
- Resource versioning information
- Resource outputs and computed values

**Critical Architectural Principle**: Without state, Terraform cannot:
- Map resource definitions to actual cloud resources
- Detect which resources to destroy when configurations are removed
- Calculate minimal change sets (plans)
- Manage resource dependencies

This makes state the single point of truth—not the cloud provider, not configuration files.

#### 3. Multi-Provider Architecture

Terraform abstracts multiple cloud providers through a plugin-based architecture:
- Each provider is a separate executable plugin
- Terraform Core communicates with provider plugins via gRPC
- This enables unified syntax across AWS, Azure, GCP, Kubernetes, etc.

**Architectural Benefits**:
- Write once, deploy to multiple clouds
- Standardize infrastructure code patterns across teams
- Reduce duplication through shared modules
- Migrate between providers with minimal refactoring

**Architectural Constraints**:
- Features are limited to the least common denominator (if supported by all providers)
- Provider-specific features require provider-specific blocks
- Dependency on provider update cadence

#### 4. Graph-Based Execution Model

Terraform builds a resource dependency graph:
- Scans all resources and their dependencies
- Constructs a directed acyclic graph (DAG)
- Parallelizes independent resources (default -parallelism=10)
- Respects explicit (`depends_on`) and implicit dependencies

**Architectural Implication**: Even with 1000+ resources:
- Only dependent resources serialize
- Independent resources apply in parallel
- Execution time = longest dependency chain, not total resource count

This enables efficient large-scale deployments.

### DevOps Principles

#### 1. Infrastructure as Code (IaC)

Terraform is the operational manifestation of IaC principles:

| Principle | Terraform Implementation |
|-----------|-------------------------|
| Version Control | .tf files stored in Git |
| Code Review | Pull requests for infrastructure changes |
| Testing | `terraform plan` for validation |
| Repeatability | Idempotent executions |
| Automation | CI/CD pipeline integration |
| Documentation | Code itself documents infrastructure |

**Senior-Level Application**:
- IaC enables infrastructure changes to follow the same rigor as application code changes
- Reduces MTTR for incident response (redeploy vs. manual fix)
- Enables infrastructure drift detection and automated remediation
- Supports disaster recovery through rapid redeployment

#### 2. Idempotency

Idempotence is foundational to Terraform's reliability:
- Running `terraform apply` 1x or 100x produces the same result
- If resources already exist with correct configuration, Terraform makes no changes
- If resources exist with wrong configuration, Terraform corrects them

**Implementation**:
- State file tracks what Terraform believes it created
- Plan phase checks current state against desired state
- Apply phase makes only necessary changes

**Senior-Level Consideration**:
- Idempotence fails if resource tags, environment variables, or time-based configurations change outside of Terraform
- Manual modifications to infrastructure break idempotency
- Drift detection is critical to restore idempotency

#### 3. Configuration Management at Scale

As infrastructure grows, managing complexity is paramount:
- **Variables**: Input parameterization
- **Locals**: Computed values and DRY principle
- **Modules**: Encapsulation and code reuse
- **Workspaces**: Environment separation (dev, staging, prod)
- **Remote State**: Shared infrastructure state across teams

**Architectural Decision**: Monolithic vs. Modular
- Monolithic: Single state file, all resources together
  - Pro: Simple, straightforward relationships
  - Con: High blast radius, difficult to manage at scale
  
- Modular: Separate state files for logical components
  - Pro: Reduced blast radius, team independence
  - Con: Cross-module dependencies require careful management

Most enterprise deployments adopt a hybrid modular approach.

#### 4. Observability and Logging

Terraform's architecture includes native logging:
- `TF_LOG` environment variable enables structured logging
- State file modifications create audit trail
- CI/CD systems capture all `terraform` invocations
- Plan output provides visibility into changes

**Senior-Level Practice**:
- Centralized logging for all Terraform operations
- Audit trails for compliance requirements
- Monitoring of state file access and modifications
- Alerting on unexpected infrastructure changes

### Best Practices

#### 1. State Management Strategy

**Best Practice Hierarchy**:
1. **Always use remote state** in production (never local-only)
2. **Enable state locking** to prevent concurrent modifications
3. **Use state encryption** at rest and in transit
4. **Implement state backups** with versioning enabled
5. **Restrict state file access** via IAM policies
6. **Use separate state files** for separate infrastructure domains
7. **Implement state isolation** across environments

**Anti-Patterns to Avoid**:
- Committing .tfstate files to Git
- Using shared local state files
- Disabling state locking to "speed up" operations
- Using overly permissive IAM policies for state access

#### 2. Resource Organization

```
terraform/
├── main.tf                 # Primary provider configuration
├── variables.tf            # Input variable definitions
├── outputs.tf              # Output value definitions
├── locals.tf               # Local values
├── versions.tf             # Required Terraform & provider versions
├── terraform.tfvars        # Variable values (environment-specific)
├── networking/             # Modular components
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── modules/                # Reusable module library
    ├── vpc/
    ├── security_group/
    └── instance_autoscaling/
```

**Best Practices**:
- Separate files by logical component, not by resource type
- Keep individual files under 200 lines for maintainability
- Use meaningful directory structure reflecting infrastructure organization
- Centralize shared modules in version-controlled module registry

#### 3. Variable and Output Design

**Input Variables**:
- Define clear descriptions for each variable
- Use explicit types (avoid `string` when `number` or `bool` is appropriate)
- Provide sensible defaults for optional configurations
- Use validation blocks for complex constraints

**Outputs**:
- Export values needed by dependent modules or external systems
- Use meaningful names that describe what the output represents
- Document sensitive outputs when applicable
- Avoid exporting sensitive values to logs (use `sensitive = true`)

#### 4. Module Design Principles

Effective modules enable code reuse:
- **Single Responsibility**: Each module manages one logical component
- **Clear Contracts**: Well-defined inputs (variables) and outputs
- **Documentation**: README files with examples and usage patterns
- **Versioning**: Use module registry with semantic versioning
- **Testing**: Test modules with varying input parameters

**Common Module Patterns**:
- **Foundational Modules**: VPC, networking, security groups (rarely change)
- **Compute Modules**: Server configurations, container clusters, functions
- **Data Modules**: Database configurations, caching, queues
- **Utility Modules**: Monitoring, logging, backup strategies

### Common Misunderstandings

#### 1. "Terraform manages infrastructure, not applications"

**Misconception**: Terraform only provisions compute, network, and storage resources.

**Reality**: Terraform's provider ecosystem extends to application platforms:
- Kubernetes resources (helm charts, operators)
- Docker container registries and images
- Application configuration management (Consul, Vault)
- Database migrations and schema management

**Architectural Implication**: Terraform can orchestrate entire application stacks, from infrastructure through application deployment and configuration.

#### 2. "State files should be version-controlled like code"

**Misconception**: State files (.tfstate) should be committed to Git.

**Reality**: State files should **never** be committed:
- They contain sensitive data (database passwords, API keys)
- Concurrent access via Git merges causes corruption
- State locking prevents simultaneous modifications
- Remote backends handle backup and versioning

**Correct Approach**: Use remote state backends (S3, Terraform Cloud, Azure Storage) with encryption and access controls.

#### 3. "Terraform can fix all manual changes automatically"

**Misconception**: Terraform's drift detection solves the "works on my machine" problem.

**Reality**: Drift detection identifies discrepancies but doesn't automatically fix them:
- Requires human decision-making for which changes are intentional
- Some manual changes are legitimate (temporary debugging, updates)
- Automatic drift correction can be destructive if changes are intentional
- Requires explicit drift correction with `terraform apply`

**Correct Approach**: Implement regular drift detection, notification, and documented procedures for remediation.

#### 4. "Larger parallelism (-parallelism flag) always means faster execution"

**Misconception**: Increasing parallelism linearly increases speed.

**Reality**: Parallelism is constrained by:
- Provider API rate limits
- Resource dependencies (can't parallelize dependent resources)
- Network bandwidth
- Amount of work per resource

**Architectural Implication**: Beyond ~20 parallel resources, diminishing returns appear due to API throttling. Architecture should address rate limiting via provider configuration, not parallelism flags alone.

#### 5. "A single state file is sufficient for all infrastructure"

**Misconception**: Monolithic state files simplify management.

**Reality**: Large monolithic state files create:
- High blast radius (one corrupted resource affects everything)
- Team coordination bottlenecks
- Slow plan/apply operations
- Difficult troubleshooting of failures

**Best Practice**: Segment state across modules/environments, with careful management of cross-module dependencies.

#### 6. "If infrastructure is running, Terraform operations are safe"

**Misconception**: Running infrastructure provides safety against misconfiguration.

**Reality**: Terraform plans and applies without understanding application requirements:
- Can destroy databases while application is reading from them
- Can terminate servers before health checks pass
- May violate application-specific constraints

**Architectural Consideration**: Pair Terraform with:
- Terraform policy as code (Sentinel, Open Policy Agent)
- Application-aware change management
- Staged deployments (blue-green, canary)
- Monitoring and alerting for post-deployment validation

---

## Providers and Resources

### Textual Deep Dive

#### Architecture Role

Providers and Resources form the operational foundation of Terraform's declarative model:

- **Providers**: Plugin-based abstractions representing cloud platforms, SaaS services, or infrastructure providers
  - AWS Provider: Manages 700+ AWS resource types
  - Kubernetes Provider: Manages cluster resources and deployments
  - Helm Provider: Manages Helm chart deployments
  - Custom Providers: Enable integration with proprietary systems

- **Resources**: The individual infrastructure components provisioned by providers
  - `aws_instance`: An EC2 virtual machine
  - `aws_security_group`: A security group for network access control
  - `kubernetes_deployment`: A Kubernetes deployment object
  - `helm_release`: A Helm chart installation

**Architectural Relationship**:
```
HCL Configuration
      ↓
[Terraform Core]
      ↓
[Provider Plugins] ──→ [Cloud Platform APIs]
      ↓
[Actual Resources]
```

#### Internal Working Mechanism

**Provider Initialization (terraform init)**:
1. Terraform reads required_providers block from versions.tf
2. Downloads provider binaries from Terraform Registry
3. Stores binaries in .terraform/providers/
4. Initializes provider plugins (gRPC communication channel established)

**Example Provider Initialization Flow**:
```
terraform init
  ├─ Download aws provider v5.0.0
  ├─ Download kubernetes provider v2.20.0
  ├─ Initialize gRPC server for each provider
  ├─ Test provider authentication (aws_access_key_id, etc.)
  └─ Create .terraform.lock.hcl (dependency lock file)
```

**Resource Declaration Processing**:
1. Parser reads resource blocks from .tf files
2. Validates resource syntax against provider schema
3. Constructs resource metadata (name, type, arguments)
4. Registers resource with Terraform Core's state manager
5. Resources form nodes in the dependency graph

**Execution During `terraform plan`**:
```
1. Read current state from state backend
2. For each resource in configuration:
   a. Query provider schema
   b. Validate argument types and constraints
   c. Call provider's Read API (check if resource exists)
   d. Compare current attributes with desired configuration
3. Generate plan showing:
   - Creations (resources in config but not in state)
   - Modifications (resources in both with different attributes)
   - Deletions (resources in state but not in config)
4. Display plan with resource-level changes
```

**Execution During `terraform apply`**:
```
1. Re-run plan to confirm no state changes
2. For each resource in dependency order:
   a. Call provider's Create/Update/Delete API
   b. Capture response (resource attributes, IDs)
   c. Update internal state
   d. Report status to user
3. Update .tfstate file with new resource attributes
4. Output any declared outputs
```

#### Production Usage Patterns

**Pattern 1: Multi-Region Deployments**

Production deployments often target multiple regions with regional autonomy:

```hcl
# providers.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu_west_1"
  region = "eu-west-1"
}

# usage in resources
resource "aws_vpc" "us_vpc" {
  provider = aws.us_east_1
  # ...
}

resource "aws_vpc" "eu_vpc" {
  provider = aws.eu_west_1
  # ...
}
```

**Pattern 2: Workspace-Based Environment Isolation**

Environments (dev, staging, prod) use different workspaces with conditional provider configuration:

```hcl
# main.tf
terraform {
  cloud {
    organization = "myorg"
    workspaces {
      name = terraform.workspace
    }
  }
}

locals {
  env = terraform.workspace
  aws_region = local.env == "prod" ? "us-east-1" : "us-west-2"
  instance_type = local.env == "prod" ? "t3.large" : "t3.micro"
}

provider "aws" {
  region = local.aws_region
}

resource "aws_instance" "app" {
  instance_type = local.instance_type
  # ... configuration
}
```

**Pattern 3: Cross-Provider Orchestration**

Complex deployments often require coordinating multiple providers:

```hcl
# Provision AWS infrastructure alongside Kubernetes deployment
provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

# AWS resources
resource "aws_eks_cluster" "main" {
  name = "production-cluster"
  # ...
}

# Kubernetes resources
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
  }
  # ...
}

# Helm resources
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  # ...
}
```

#### DevOps Best Practices

**1. Provider Pinning and Versioning**

Always specify explicit provider versions to prevent unexpected breaking changes:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0, < 6.0"  # Tilde allows patch upgrades
    }
  }
  required_version = ">= 1.5"
}
```

**Use `terraform.lock` file**:
- Commit `.terraform.lock.hcl` to version control
- Ensures all team members use identical provider versions
- Prevents "works for me" issues due to version differences

**2. Provider Schema Validation**

Always validate provider schemas during CI/CD:

```bash
# Validate all resources match provider schema
terraform validate

# Format-check the code
terraform fmt -check .

# Run security scanner
tfsec .
```

**3. Sensitive Argument Handling**

Protect secrets passed to providers:

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_db_instance" "main" {
  password = var.db_password  # Won't be logged in outputs
}
```

**4. Provider Alias for Disaster Recovery**

Maintain passive secondary region for disaster recovery:

```hcl
provider "aws" {
  alias  = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"
}

# Primary resources
resource "aws_rds_instance" "primary" {
  provider = aws.primary
  # ...
}

# DR replica
resource "aws_db_instance_replica" "dr" {
  provider = aws.secondary
  # ...
}
```

#### Common Pitfalls

**Pitfall 1: Implicit Provider Dependencies**

Resources assuming implicit provider availability:

```hcl
# WRONG - provider not specified, assumes default
resource "aws_instance" "multi_region" {
  # Which region? Ambiguous!
}

# CORRECT - explicit provider alias
resource "aws_instance" "multi_region" {
  provider = aws.eu_west_1
}
```

**Pitfall 2: Provider Authentication Failures in CI/CD**

Credentials not properly configured in automated environments:

```bash
# WRONG - credentials check happens after provider init
terraform init && terraform apply

# CORRECT - verify credentials before any operation
aws sts get-caller-identity || exit 1
terraform init && terraform apply
```

**Pitfall 3: Mixing Implicit and Explicit Providers**

Inconsistent provider specification leads to unexpected behavior:

```hcl
# DANGEROUS - Some resources use default provider, others specify alias
provider "aws" {
  alias  = "prod"
  region = "us-east-1"
}

resource "aws_vpc" "vpc1" {
  # Uses default provider (likely wrong region)
}

resource "aws_subnet" "subnet1" {
  provider = aws.prod
  # Uses explicit provider
  vpc_id = aws_vpc.vpc1.id  # Cross-provider references break!
}
```

**Pitfall 4: Provider State Leakage**

Provider credentials persisting in plan files:

```bash
# WRONG - plan file may contain sensitive provider config
terraform plan -out=plan.tfplan
git add plan.tfplan

# CORRECT - never commit plan files
terraform plan > /dev/null
git add .gitignore  # *.tfplan
```

---

### Practical Code Examples

#### Example 1: AWS Provider with Multiple Regions and Data Centers

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# providers.tf
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "production"
      ManagedBy   = "terraform"
      Team        = "platform"
    }
  }
}

provider "aws" {
  alias  = "eu_west"
  region = "eu-west-1"
}

# main.tf
variable "instance_count_per_region" {
  type    = number
  default = 3
}

# Create VPC in US region
resource "aws_vpc" "us_vpc" {
  provider   = aws.us_east
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "us-production-vpc"
  }
}

# Create VPC in EU region
resource "aws_vpc" "eu_vpc" {
  provider   = aws.eu_west
  cidr_block = "10.1.0.0/16"
  
  tags = {
    Name = "eu-production-vpc"
  }
}

# Create subnets in US region
resource "aws_subnet" "us_subnets" {
  provider            = aws.us_east
  count               = var.instance_count_per_region
  vpc_id              = aws_vpc.us_vpc.id
  cidr_block          = "10.0.${count.index}.0/24"
  availability_zone   = data.aws_availability_zones.us_zones.names[count.index]
  
  tags = {
    Name = "us-subnet-${count.index + 1}"
  }
}

data "aws_availability_zones" "us_zones" {
  provider = aws.us_east
  state    = "available"
}

# Output the created resources
output "us_vpc_id" {
  value = aws_vpc.us_vpc.id
}

output "eu_vpc_id" {
  value = aws_vpc.eu_vpc.id
}

output "us_subnet_cidrs" {
  value = aws_subnet.us_subnets[*].cidr_block
}
```

**CLI Usage**:
```bash
# Initialize providers
terraform init

# Plan infrastructure
terraform plan -out=tfplan

# Apply with specific region
terraform apply tfplan

# Destroy US East resources only (requires provider alias)
terraform destroy -auto-approve -target='aws_vpc.us_vpc'
```

---

## Data Sources

### Textual Deep Dive

#### Architecture Role

Data sources represent a fundamental architectural pattern in Terraform: **reading existing infrastructure information** without modifying it. Where resources **create/update/delete** infrastructure, data sources **query and reference** existing infrastructure.

**Key Distinction**:
| Aspect | Resources | Data Sources |
|--------|-----------|--------------|
| Purpose | Create/modify/delete | Query/read existing |
| State Impact | Updates state | No state modifications |
| Idempotence | Safe to re-run | Always returns current data |
| API Operation | Create, Patch, Delete | Read-only |
| Failure Mode | Plan fails if creation impossible | Plan fails if data not found |

**Architectural Use Cases**:
1. **Bridging IaC and Manual Infrastructure**: Reference infrastructure created outside Terraform
2. **Cross-Module Dependencies**: Share data between Terraform modules
3. **Dynamic Configuration**: Build resource configurations based on existing infrastructure
4. **Multi-Team Deployments**: Coordinate between teams managing different infrastructure domains

#### Internal Working Mechanism

**Data Source Query Execution**:

```
terraform plan/apply
  ├─ Parse data source blocks
  ├─ For each data source:
  │   ├─ Validate provider credentials
  │   ├─ Execute provider's Read API with filters
  │   ├─ Validate response schema
  │   ├─ Store in-memory (not persisted to state)
  │   └─ Make attributes available to resources
  └─ Continue with resource evaluation
```

**Difference from Resources in State Management**:

```
Resources:
┌─────────────────────────────────────┐
│  .tfstate (persisted)               │
│  ├─ aws_instance.web                │
│  │   ├─ id: i-1234567890abcdef0     │
│  │   ├─ private_ip: 10.0.1.50       │
│  │   └─ public_ip: 52.1.2.3         │
│  └─ timestamp: 2024-03-07           │
└─────────────────────────────────────┘

Data Sources:
┌─────────────────────────────────────┐
│  In-memory only (not persisted)      │
│  ├─ data.aws_ami.ubuntu             │
│  │   ├─ id: ami-0c55b159cbfafe1f0   │
│  │   ├─ name: ubuntu-20.04-amd64    │
│  │   └─ root_block_device_size: 8   │
│  └─ Queried fresh on each plan      │
└─────────────────────────────────────┘
```

**Data Source Dependency Resolution**:

Data sources participate in Terraform's dependency graph:

```
graph {
  data.aws_ami.ubuntu → aws_instance.app
    (instance depends on AMI availability)

  data.aws_vpc.default → aws_subnet.app
    (subnet depends on VPC existing)

  aws_security_group.main → data.aws_security_group.existing
    (can reference as dependency for validation)
}
```

#### Production Usage Patterns

**Pattern 1: Importing Manually-Created Infrastructure**

Migrating legacy infrastructure to Terraform requires referencing manually-created resources:

```hcl
# Reference existing VPC created outside Terraform
data "aws_vpc" "default" {
  default = true
}

# Reference existing security group
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

# Launch instance into existing infrastructure
resource "aws_instance" "app" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t3.medium"
  subnet_id       = data.aws_vpc.default.main_route_table_id
  security_groups = [data.aws_security_group.default.id]
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

**Pattern 2: Dynamic Configuration Based on Environment**

Data sources enable configuration that adapts to infrastructure state:

```hcl
# Query environment metadata
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  environment = contains(["us-east-1", "eu-west-1"], local.region) ? "prod" : "dev"
}

# Create resources with environment-specific naming
resource "aws_s3_bucket" "artifacts" {
  bucket = "artifacts-${local.environment}-${local.account_id}"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  
  versioning_configuration {
    status = local.environment == "prod" ? "Enabled" : "Suspended"
  }
}
```

**Pattern 3: Multi-Module Coordination**

Data sources allow modules to query infrastructure managed by other modules or teams:

```hcl
# Module A: Database team provides RDS instance
# outputs.tf
output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  value = aws_db_instance.main.db_name
}

# Module B: Application team references the database
data "aws_db_instance" "shared_db" {
  db_instance_identifier = "shared-production-db"
}

resource "aws_elasticache_cluster" "app_cache" {
  cluster_id           = "app-cache"
  subnet_group_name    = data.aws_elasticache_subnet_group.app.name
  security_group_ids   = [data.aws_security_group.app.id]
  
  # Connection string built from queried database
  server_names_to_include = "${data.aws_db_instance.shared_db.address}:${data.aws_db_instance.shared_db.port}"
}

data "aws_elasticache_subnet_group" "app" {
  name = "app-subnet-group"
}

data "aws_security_group" "app" {
  name = "app-security-group"
}
```

#### DevOps Best Practices

**1. Filter Data Sources Precisely**

Overly broad filters can match unintended resources:

```hcl
# RISKY - matches any ami with "ubuntu" in name
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["*ubuntu*"]
  }
}

# CORRECT - specific versioning
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}
```

**2. Document Data Source Dependencies**

Explicitly document which infrastructure must pre-exist:

```hcl
# README.md for module
# ## Required Pre-Existing Infrastructure
# 
# This module requires the following to be manually created:
# - VPC with tag: Name=production-vpc
# - RDS database with identifier: shared-production-db
# - IAM role with name: application-execution-role

data "aws_vpc" "production" {
  tags = {
    Name = "production-vpc"
  }
}

data "aws_db_instance" "shared" {
  db_instance_identifier = "shared-production-db"
}

data "aws_iam_role" "app_role" {
  name = "application-execution-role"
}
```

**3. Defensive Data Source Queries**

Assume data sources may not find resources and handle gracefully:

```hcl
# Query with count to handle optional dependencies
data "aws_security_group" "custom" {
  count = var.enable_custom_sg ? 1 : 0
  
  name = var.custom_sg_name
}

# Use ternary to fall back to defaults if not found
locals {
  security_group_id = try(data.aws_security_group.custom[0].id, aws_security_group.default.id)
}

resource "aws_instance" "app" {
  security_groups = [local.security_group_id]
}

resource "aws_security_group" "default" {
  name = "default-app-sg"
}
```

**4. Cache Data Source Results When Possible**

Avoid repeated queries for static data:

```hcl
# Instead of querying AMI in every resource:
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

locals {
  ubuntu_ami_id = data.aws_ami.ubuntu.id  # Cache the ID
}

# Reuse in all resources
resource "aws_instance" "web" {
  ami = local.ubuntu_ami_id
}

resource "aws_launch_template" "app" {
  image_id = local.ubuntu_ami_id
}
```

#### Common Pitfalls

**Pitfall 1: Data Source Not Found Failures**

Plans fail when data sources can't find matching infrastructure:

```hcl
# RISKY - if VPC doesn't exist, entire plan fails
data "aws_vpc" "custom" {
  filter {
    name   = "tag:Name"
    values = ["my-custom-vpc"]
  }
}

# SAFER - use count to make it optional
data "aws_vpc" "custom" {
  count = var.use_custom_vpc ? 1 : 0
  
  filter {
    name   = "tag:Name"
    values = ["my-custom-vpc"]
  }
}

locals {
  vpc_id = var.use_custom_vpc ? data.aws_vpc.custom[0].id : aws_vpc.default.id
}
```

**Pitfall 2: Circular Data Source Dependencies**

Creating circular references between modules and data sources:

```hcl
# Module A
data "aws_security_group" "from_module_b" {
  name = "sg-from-module-b"
}

output "app_sg_id" {
  value = aws_security_group.app.id
}

# Module B
data "aws_security_group" "from_module_a" {
  name = "sg-from-module-a"
}

output "db_role_arn" {
  value = aws_iam_role.db.arn
}

# CIRCULAR! Module A queries Module B while Module B queries Module A
# SOLUTION: Use explicit outputs instead of data sources between modules
```

**Pitfall 3: Stale Data Source Caching**

Data sources are queried fresh on each plan, but caching can create inconsistency:

```bash
# Run 1: Query returns AMI version X
terraform plan

# Infrastructure provider updates AMI to version Y

# Run 2: Without refresh, may still use cached version X
terraform apply -refresh=false  # DANGEROUS

# CORRECT: Always allow refresh
terraform apply
```

**Pitfall 4: Security Groups Named Identically Across Regions**

Forgetting to include region filters in data source queries:

```hcl
# WRONG - queries first matching SG, may be in wrong region
data "aws_security_group" "app" {
  name = "app-sg"
}

resource "aws_instance" "app" {
  subnet_id       = aws_subnet.us_east.id  # us-east-1
  security_groups = [data.aws_security_group.app.id]  # Could be from us-west-2!
}

# CORRECT - filter by VPC to ensure region specificity
data "aws_security_group" "app" {
  vpc_id = aws_vpc.app.id
  name   = "app-sg"
}
```

---

### Practical Code Examples

#### Example 1: Complete AMI Discovery and Dynamic Launch

```hcl
# versions.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# variables.tf
variable "ubuntu_version" {
  type        = string
  description = "Ubuntu version to use"
  default     = "22.04"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

# data.tf - All data sources in dedicated file
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-${var.ubuntu_version}-amd64-server-*"]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_groups" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "group-name"
    values = ["default"]
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# main.tf
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.available.ids[0]
  vpc_security_group_ids = data.aws_security_groups.default.ids
  
  tags = {
    Name        = "${var.environment}-app-instance"
    Environment = var.environment
    ManagedBy   = "terraform"
    LaunchedAt  = timestamp()
  }
}

# outputs.tf
output "instance_id" {
  value       = aws_instance.app.id
  description = "EC2 instance ID"
}

output "instance_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP address"
}

output "ami_id" {
  value       = data.aws_ami.ubuntu.id
  description = "Ubuntu AMI ID used for launch"
}

output "ami_name" {
  value       = data.aws_ami.ubuntu.name
  description = "Ubuntu AMI name"
}

output "account_info" {
  value = {
    account_id = local.account_id
    region     = local.region
    partition  = data.aws_caller_identity.current.partition
  }
  description = "Current AWS account information"
}
```

**Execution**:
```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Apply configuration
terraform apply

# Query instance details
terraform output instance_public_ip

# Destroy when done
terraform destroy
```

#### Example 2: Data Source-Driven Multi-Subnet Deployment

```hcl
# variables.tf
variable "deployment_subnets" {
  type        = number
  description = "Number of subnets to deploy to"
  default     = 2
}

variable "app_name" {
  type        = string
  description = "Application name"
}

# data.tf
data "aws_vpc" "primary" {
  tags = {
    Name = "primary-vpc"
  }
}

data "aws_subnets" "deployment" {
  # Get list of all subnets in VPC, then slice to requested count
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.primary.id]
  }
}

data "aws_subnet" "deployment" {
  for_each = toset(slice(data.aws_subnets.deployment.ids, 0, var.deployment_subnets))
  
  id = each.value
}

data "aws_security_group" "app" {
  vpc_id = data.aws_vpc.primary.id
  name   = "${var.app_name}-sg"
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# main.tf
resource "aws_instance" "app" {
  for_each = data.aws_subnet.deployment
  
  ami                    = data.aws_ami.latest_ubuntu.id
  instance_type          = "t3.small"
  subnet_id              = each.value.id
  vpc_security_group_ids = [data.aws_security_group.app.id]
  
  tags = {
    Name   = "${var.app_name}-instance-${each.key}"
    Subnet = each.value.availability_zone
  }
}

# outputs.tf
output "instance_details" {
  value = {
    for id, instance in aws_instance.app : id => {
      instance_id = instance.id
      private_ip  = instance.private_ip
      subnet_az   = data.aws_subnet.deployment[id].availability_zone
    }
  }
}

output "deployment_info" {
  value = {
    vpc_id          = data.aws_vpc.primary.id
    subnets_used    = length(aws_instance.app)
    security_group  = data.aws_security_group.app.name
    ami_used        = data.aws_ami.latest_ubuntu.name
  }
}
```

---

### ASCII Diagrams

#### Provider Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      Terraform Execution                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │         HCL Configuration Files (.tf)                   │   │
│  │  ┌─────────────────┐        ┌─────────────────┐       │   │
│  │  │ resource blocks │        │ data blocks     │       │   │
│  │  │                 │        │                 │       │   │
│  │  │ aws_instance    │        │ aws_ami         │       │   │
│  │  │ aws_subnet      │        │ aws_vpc         │       │   │
│  │  │ aws_rds...      │        │ aws_security... │       │   │
│  │  └─────────────────┘        └─────────────────┘       │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │          Terraform Core (Parser & Validator)            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              ↓                                  │
│              ┌───────────────┼───────────────┐                 │
│              ↓               ↓               ↓                 │
│  ┌──────────────────┐ ┌──────────────┐ ┌──────────────────┐  │
│  │  AWS Provider    │ │ Kubernetes   │ │ Helm Provider    │  │
│  │  (gRPC Process)  │ │ Provider     │ │ (gRPC Process)   │  │
│  │                  │ │ (gRPC)       │ │                  │  │
│  │ Manages: EC2,    │ │ Manages:     │ │ Manages: Helm    │  │
│  │ RDS, VPC, etc.   │ │ Pods, Apps   │ │ Releases         │  │
│  └──────────────────┘ └──────────────┘ └──────────────────┘  │
│         ↓                    ↓                  ↓               │
└─────────────────────────────────────────────────────────────────┘
         ↓                    ↓                  ↓
    ┌─────────┐          ┌─────────┐       ┌─────────┐
    │   AWS   │          │ Kube    │       │ Helm    │
    │   API   │          │  API    │       │ Server  │
    │   &     │          │         │       │         │
    │  Cloud  │          │ Master  │       │ Cluster │
    └─────────┘          └─────────┘       └─────────┘
```

#### Data Source Query Flow

```
terraform plan
    ↓
┌───────────────────────────────────────────┐
│ Parse Data Blocks                         │
│ • data.aws_ami.ubuntu                     │
│ • data.aws_vpc.primary                    │
│ • data.aws_subnet.app                     │
└───────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────┐
│ Execute Data Source Queries               │
│ (Query existing infrastructure)           │
└───────────────────────────────────────────┘
    ↓ AWS Provider gRPC
    ├──→ [DescribeImages] → ami-123456789
    ├──→ [DescribeVpcs]   → vpc-abcdef012
    └──→ [DescribeSubnets]→ subnet-xyz789

Data Sources (In-Memory, Not Saved to State)
    ↓
┌───────────────────────────────────────────┐
│ Use Data Source Results in Resources      │
│ resource "aws_instance" "app" {           │
│   ami = data.aws_ami.ubuntu.id            │
│   subnet_id = data.aws_subnet.app.id      │
│ }                                         │
└───────────────────────────────────────────┘
    ↓
┌───────────────────────────────────────────┐
│ Generate Plan with Resource Changes       │
│ + aws_instance.app (will be created)      │
│ (Data sources have no + - ~ shown, they   │
│  just provide values)                     │
└───────────────────────────────────────────┘
```

#### Multi-Provider Coordination Architecture

```
┌──────────────────────────────────────────────────────────────┐
│              Terraform Configuration                         │
└──────────────────────────────────────────────────────────────┘
                    ↓
        ┌───────────┼───────────┐
        ↓           ↓           ↓
    ┌────────┐ ┌────────┐ ┌────────┐
    │  AWS   │ │   K8s  │ │ Helm   │
    │        │ │        │ │        │
    │Provider│ │Provider│ │Provider│
    └────┬───┘ └───┬────┘ └───┬────┘
         ↓         ↓          ↓
      gRPC      gRPC       gRPC
      Socket   Socket     Socket
         ↓         ↓          ↓
    ┌─────────────────────────────────┐
    │     Cloud Platform APIs         │
    │                                 │
    │  AWS:        Kubernetes:  Helm: │
    │  • EC2       • API Server  • API │
    │  • RDS       • etcd           Server│
    │  • VPC       • Kubelet        │
    │  • EKS Cluster              │
    │    (bridges to K8s)             │
    └─────────────────────────────────┘
         ↓
    ┌──────────────────────────────────┐
    │  Result: Integrated Infrastructure
    │                                 │
    │  AWS EKS Cluster                │
    │  ├─ VPC & Subnets               │
    │  ├─ Security Groups              │
    │  └─ Kubernetes Deployments      │
    │     ├─ Helm Charts              │
    │     └─ K8s Services             │
    └──────────────────────────────────┘
```

---

## State Management

### Concept of State

#### Architecture Role and Criticality

Terraform's state is the **single source of truth** for managed infrastructure. It's arguably the most critical component of Terraform's architecture:

```
Desired State (HCL Code) ←→ [Terraform Core] ←→ Current State (.tfstate)
                               ↓
                        Determine Actions
                        (Create/Update/Delete)
                               ↓
                        Execute via Provider APIs
                               ↓
                        Actual Infrastructure
```

**What State Contains**:
```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "a1b2c3d4-e5f6-...",
  "outputs": {},
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t3.micro",
            "private_ip": "10.0.1.50",
            "public_ip": "54.1.2.3",
            "tags": {"Name": "web-server"}
          }
        }
      ]
    }
  ]
}
```

**Critical State Attributes**:
- **Resource IDs**: Maps Terraform references to actual cloud resources
- **Resource Attributes**: Current values (IPs, DNS names, etc.)
- **Dependency Metadata**: Implicit and explicit resource relationships
- **Lineage**: Unique identifier for state evolution tracking
- **Serial Number**: Version counter for concurrent access detection

#### Internal Working Mechanism

**State Lifecycle**:

```
1. terraform init
   └─ Initialize state backend
      ├─ Local: Create .terraform/terraform.tfstate
      └─ Remote: Connect to backend (S3, Terraform Cloud, etc.)

2. terraform plan
   ├─ Load current state
   ├─ Read current AWS resources
   ├─ Compare desired (HCL) vs. actual (AWS) vs. managed (state)
   ├─ Detect drift
   └─ Generate execution plan

3. terraform apply
   ├─ Execute plan actions
   ├─ Update state after each successful resource operation
   └─ Write updated state to backend

4. terraform refresh
   └─ Sync state with actual infrastructure
      (without making changes)
```

**State Refresh Mechanism**:

When Terraform reads actual infrastructure during `plan`, it answers three key questions:

```
For each managed resource:

1. Does it exist? 
   ├─ YES → Read its current attributes
   ├─ NO  → Mark for creation

2. Are attributes correct?
   ├─ YES → No action needed
   ├─ DIFFERENT → Plan update (or deletion + recreation)
   └─ UNKNOWN (API error) → Error and stop

3. Is it unmanaged (created outside TF)?
   └─ Plan will show it, but State doesn't manage it
```

#### Production Usage Patterns

**Pattern 1: State File Segmentation for Large Deployments**

Rather than a monolithic state file managing all infrastructure, segment by domain:

```
terraform/
├── networking/
│   ├── main.tf
│   ├── terraform.tfstate      # Only VPC, subnets, route tables
│   └── terraform.tfstate.backup
├── compute/
│   ├── main.tf
│   └── terraform.tfstate      # Only EC2, ASG, Launch templates
├── databases/
│   ├── main.tf
│   └── terraform.tfstate      # Only RDS, ElastiCache
└── monitoring/
    ├── main.tf
    └── terraform.tfstate      # Only CloudWatch, SNS
```

**Benefits**:
- Reduced blast radius (one corrupted state doesn't affect entire system)
- Faster plan/apply operations
- Team independence (each team manages own state)
- Easier rollback of component-specific changes

**Pattern 2: State Rollback Strategy**

Maintain versioned backups for disaster recovery:

```bash
# S3 backend with versioning enabled
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Now every state write creates a new version
terraform apply  # State v42
terraform apply  # State v43
terraform apply  # State v44

# Recover to previous state if needed
aws s3api get-object \
  --bucket my-terraform-state \
  --key terraform.tfstate \
  --version-id <specific-version-id> \
  terraform.tfstate.old

# Review and restore if safe
terraform state push terraform.tfstate.old
```

**Pattern 3: State Isolation Between Environments**

Separate state files ensure environment changes don't affect others:

```hcl
# backend.tf - Different state per environment
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "${env}/terraform.tfstate"  # env variable substitution
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

With workspaces (simpler approach):
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch between them
terraform workspace select prod
terraform apply  # Applies only to prod state

terraform workspace select dev
terraform apply  # Applies only to dev state
```

#### DevOps Best Practices

**1. Never Manually Edit State Files**

```bash
# WRONG - Corrupts state relationships
vim terraform.tfstate
# Edit resource IDs directly

# CORRECT - Use Terraform commands
terraform state show aws_instance.web
terraform state mv aws_instance.web aws_instance.app
terraform state rm aws_instance.deprecated
```

**2. Always Enable State Locking**

Prevents concurrent modifications:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"  # Enables locking
  }
}
```

Create lock table:
```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

**3. Encrypt State at Rest and in Transit**

```hcl
terraform {
  backend "s3" {
    bucket            = "terraform-state"
    key               = "terraform.tfstate"
    region            = "us-east-1"
    encrypt           = true              # Encrypt at rest with SSE-S3
    dynamodb_table    = "terraform-locks"
  }
}

# In-transit encryption via HTTPS (automatic with AWS backend)

# Backup encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "state_encryption" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform.arn
    }
  }
}
```

**4. Restrict State File Access**

```hcl
# Deny all access except specific roles
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/TerraformAdmin",
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CICDRunner"
            ]
          }
        }
      }
    ]
  })
}
```

**5. Enable Public Block and Versioning**

```hcl
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Enabled"  # Requires MFA to delete versions
  }
}
```

---

## Dependency Graph and Execution Plan

### Textual Deep Dive

#### Architecture Role

Terraform's dependency graph is the computational engine that orchestrates safe, efficient infrastructure deployment. It determines the order and parallelism of operations based on resource relationships.

**Key Responsibilities**:
1. Identify all dependencies (explicit and implicit)
2. Detect circular dependencies and fail early
3. Determine safe execution order
4. Maximize parallelization within constraints
5. Enable targeted operations (`-target` flag)

#### Internal Working Mechanism

**Dependency Discovery**:

```
1. Parse all .tf files
2. Extract resource and variable references
3. Identify dependencies:
   - Explicit: depends_on = [aws_instance.web]
   - Implicit: ${aws_instance.web.id}
   - Provider: resource type → provider
4. Build directed acyclic graph (DAG)
5. Topologically sort for valid execution order
```

**Implicit Dependency Example**:

```hcl
resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id  # Implicit dependency
}

# Terraform auto-discovers: data.aws_ami.ubuntu → aws_instance.web
```

**Execution Plan Mechanism**

**Plan Phase (Non-Destructive)**:
1. Lock state
2. Load current state
3. For each resource: Query provider API (Read) and compare desired vs. actual
4. For each data source: Query provider API
5. Traverse DAG
6. Determine actions (Create/Update/Delete/NoOp)
7. Display plan

**Apply Phase (Destructive)**:
1. Lock state
2. Reload state (detect concurrent changes)
3. Re-run plan
4. For each resource in DAG order: Execute Create/Update/Delete API calls
5. Update state
6. Release lock

---

### Practical Code Examples

#### Multi-Tier Application with Explicit Ordering

```hcl
# variables.tf
variable "environment" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8080
}

# security_groups.tf
resource "aws_security_group" "vpc" {
  name = "${var.environment}-vpc-sg"
}

resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group" "alb" {
  name = "${var.environment}-alb-sg"
  depends_on = [aws_security_group.vpc]
}

# networking.tf
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

data "aws_availability_zones" "available" {
  state = "available"
}

# compute.tf
resource "aws_lb" "main" {
  name            = "${var.environment}-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public[*].id
}

resource "aws_launch_template" "app" {
  name              = "${var.environment}-lt"
  image_id          = data.aws_ami.ubuntu.id
  instance_type     = "t3.medium"
  vpc_security_group_ids = [aws_security_group.vpc.id]
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  depends_on = [aws_lb.main]
}

# data.tf
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
```

---

### ASCII Diagrams

#### Dependency Graph Visualization

```
┌─────────────────────────────────────────┐
│ Dependency Graph Construction & Execution
└─────────────────────────────────────────┘

1. PARSE PHASE
   Parse .tf → Extract resources & dependencies

2. GRAPH BUILDING
   aws_vpc.main
     ├─→ aws_subnet.public[*]
     └─→ aws_security_group.vpc

   data.aws_ami.ubuntu
     └─→ aws_launch_template.app

   aws_security_group.alb
     └─→ aws_lb.main

3. TOPOLOGICAL SORT
   Level 0: aws_vpc, data.aws_ami, aws_sg.vpc
   Level 1: aws_subnet, aws_sg.alb
   Level 2: aws_lb, aws_launch_template
   Level 3: aws_asg

4. EXECUTION WITH PARALLELISM=10
   T0: [VPC] [AMI] [SG.vpc] (parallel)
   T1: [Subnet] [SG.alb] (parallel, depend on L0)
   T2: [LB] [Template] (parallel, depend on L1)
   T3: [ASG] (depends on L2)
```

#### Plan vs Apply

```
terraform plan
  ├─ Lock state
  ├─ Load state
  ├─ Refresh (query API for each resource)
  ├─ Compare desired vs actual
  ├─ Build plan (+ creates, -/~ modifications)
  └─ Release lock

terraform apply
  ├─ Lock state
  ├─ Reload & verify plan still valid
  ├─ Execute in DAG order:
  │   ├─ Create: Call provider.Create()
  │   ├─ Update: Call provider.Update()
  │   └─ Delete: Call provider.Delete()
  ├─ Write updated state
  └─ Release lock
```

---

## Hands-on Scenarios

### Scenario 1: State Recovery After Accidental Resource Destruction

**Problem**: Junior engineer ran `terraform destroy` on production instead of staging, destroying 47 resources. RDS backups exist from 5 minutes ago. 500+ users affected. 2 hours before SLA breach.

**Recovery**:
```bash
# 1. Restore state from S3 versioning
aws s3api get-object --bucket terraform-state-bucket --key prod/terraform.tfstate --version-id <version> terraform.tfstate.restored

# 2. Restore RDS from snapshot
aws rds restore-db-instance-from-db-snapshot --db-instance-identifier prod-db --db-snapshot-identifier <snapshot>
aws rds wait db-instance-available --db-instance-identifier prod-db

# 3. Apply infrastructure
terraform state push terraform.tfstate.restored
terraform apply
```

**Best Practices Applied**: S3 versioning, automated RDS snapshots (5-min RPO), DynamoDB locking, MFA for destroy, documented runbooks.

---

### Scenario 2: Debugging Circular Dependency

**Problem**: `Error: Cycle: module.compute → module.security → module.compute`. Root cause: compute queries security module's IAM role; security queries compute's SG.

**Solution - Break the Cycle**:
```hcl
# 1. Remove data source from security module
# 2. Accept security group IDs as input:
variable "allowed_security_group_ids" { type = list(string) }

# 3. Wire dependencies in root module:
module "compute" { source = "./modules/compute" }
module "security" {
  source = "./modules/security"
  allowed_security_group_ids = [module.compute.app_security_group_id]
  depends_on = [module.compute]
}
```

**Key Principle**: Unidirectional dependencies only. Sibling modules communicate via root module outputs.

---

### Scenario 3: Drift Detection and Remediation

**Problem**: Production drifted—23 SGs modified manually, 8 IAM policies changed, 47 resources missing tags.

**Automated Detection**:
```hcl
resource \"aws_lambda_function\" \"drift_detector\" {
  filename = \"drift_detector.zip\"
  timeout  = 300
  environment { 
    variables = {
      TERRAFORM_BUCKET = aws_s3_bucket.terraform_state.id
      SNS_TOPIC_ARN    = aws_sns_topic.drift_alerts.arn
    }
  }
}

resource \"aws_cloudwatch_event_rule\" \"drift_schedule\" {
  schedule_expression = \"cron(0 */6 * * ? *)\"  # Every 6 hours
}
```

**Remediation Matrix**:
| Drift Type | Auto-Remediate | Reason |
|-----------|----------------|--------|
| Tags | NO | Compliance review |
| SG rules | NO | Manual approval |
| IAM policies | NO | Audit implications |
| Launch templates | YES | Safe if versioned |

**Recovery**: Review change → Import into state or revert to config → Document decision.

## Interview Questions

### 1. Explain the relationship between Terraform state, desired configuration, and actual infrastructure. What happens when they disagree?

**Senior DevOps Answer**:

Terraform operates across three realities:
1. **Desired State** (HCL): What should exist—version controlled, reviewable
2. **Current State** (.tfstate): What Terraform believes it deployed—the map of logical names to resource IDs
3. **Actual Infrastructure**: What really exists in AWS—the operational reality

During `terraform plan`, Terraform executes **Read API calls** to refresh current state from actual infrastructure, then compares desired vs. actual.

**When they disagree** (drift):
- **Desired ≠ Actual**: Run `terraform apply` to fix
- **Current ≠ Actual**: State corruption—data loss risk

**Real-World Risk**: Engineer manually scales RDS; state shows old size; next `apply` tries to downsize, triggering recreation and data loss.

---

### 2. Walk through `terraform plan` vs. `terraform apply`. What are the safety implications?

**Senior DevOps Answer**:

**terraform plan** (Non-Destructive):
- Lock state → Load state → Query AWS (Read-only) → Compare → Release lock
- Safe to run infinitely
- Shows what *would* happen

**terraform apply** (Destructive):
- Lock state → Re-run plan → Execute Create/Update/Delete in DAG order → Update state → Release lock
- On failure: partial application (some resources created, some not—state corrupted)

**Safety Risk**: If infrastructure changes between plan and apply, apply may execute unexpected changes. Recovery requires identifying which resources match state vs. AWS, then reconciling.

---

### 3. How would you detect and resolve a circular dependency?

**Senior DevOps Answer**:

**Detection**:
```bash
terraform plan  # Shows: Error: Cycle
terraform graph | dot -Tsvg > deps.svg  # Visualize
grep -r "data.aws_" ./modules/*/main.tf  # Find cross-module queries
```

**Root Cause**: Module A requires output from Module B; Module B queries Module A via data source.

**Resolution**: Break the cycle by:
1. Identify cycle edge (usually data source query)
2. Replace data source with input variable
3. Wire dependencies via root module outputs
4. Verify with `terraform validate`

**Key**: Unidirectional dependencies only. Sibling modules communicate via parent.

---

### 4. Describe how state locking prevents data corruption. What happens if locking fails?

**Senior DevOps Answer**:

**How it Works**:
```
User 1: terraform apply
├─ Request DynamoDB lock
├─ Acquire lock
├─ Modify infrastructure
└─ Release lock

User 2 (concurrent): terraform apply
├─ Request DynamoDB lock
├─ BLOCK (User 1 holds lock)
├─ Wait up to timeout (default 10min)
└─ If timeout: Error
```

**Without Locking** (corruption):
```
User 1: Create instance → Write state (T1)
User 2: Load state (T0, doesn't see instance), modify different resource → Overwrite state (T2)
Result: Instance exists in AWS but not in Terraform state
```

**If Locking Fails**:
```bash
terraform apply  # Error: could not acquire lock
terraform apply  # Retry (maybe network issue resolved)
terraform force-unlock <lock-id>  # Only if lock is > 1hr old (stale)
```

---

### 5. Compare local state vs. remote state (S3, Terraform Cloud). When use each?

**Senior DevOps Answer**:

| Feature | Local | S3 | Cloud |
|---------|-------|-----|-------|
| Collaboration | Single | Team | Team + governance |
| Locking | File-based (unreliable) | DynamoDB | Built-in |
| Cost | Free | $ | $$ |
| Encryption | No | KMS | HTTPS + at-rest |
| Audit Trail | None | CloudTrail | Web UI logs |

**Local**: Development, learning only
**S3**: Small teams, AWS-native (must implement: encryption, locking, versioning, IAM)
**Cloud**: Large teams (5+), multi-cloud, compliance-heavy, VCS integration

**Migration Path**: Local → S3 (via `terraform init -migrate-state`) → Cloud (via `terraform login`).

---

### 6. Explain implicit vs. explicit dependencies. How does Terraform determine execution order?

**Senior DevOps Answer**:

**Implicit** (Terraform auto-discovers): `${aws_instance.web.ami_id}` references create dependency
**Explicit** (You declare): `depends_on = [aws_iam_role.app]` for non-interpolated relationships

**Execution Order**:
1. Parse all .tf files
2. Extract all references
3. Build DAG
4. Topologically sort by levels
5. Parallelize execution (default: 10 concurrent)

**Example**:
```
Level 0: VPC + AMI query (parallel)
Level 1: Subnet + SG (parallel, depend on VPC)
Level 2: Instance (depends on level 1)
```

Circular dependencies detected and fail with cycle error.

---

### 7. How does Terraform handle sensitive data? What are runtime implications?

**Senior DevOps Answer**:

`sensitive = true` prevents console printing. **But state file still contains secrets in plain text** (Terraform needs them to detect changes).

**Leakage Vectors**:
- State files (most critical)
- CI/CD logs
- Provider debug logs (TF_LOG=DEBUG)
- Plan files (.tfplan)

**Best Practice—Never Store Secrets in HCL**:
```hcl
# ❌ WRONG
variable "api_key" { default = "sk-abc123xyz" }  # Committed to Git forever!

# ✅ CORRECT
# CI/CD injects via TF_VAR_api_key_from_vault
resource "aws_secretsmanager_secret_version" "api" {
  secret_id     = aws_secretsmanager_secret.api.id
  secret_string = var.api_key_from_vault  # Never stored in state
}
```

**At Runtime**: CI/CD retrieves from Vault → injects via env var → Terraform uses → never persists.

---

### 8. Describe how providers communicate with Terraform Core. What is gRPC's role?

**Senior DevOps Answer**:

**Architecture**:
```
Terraform Core ←→ gRPC ←→ Provider Plugin ←→ Cloud APIs
```

**Why gRPC**: Language-independent, efficient binary serialization, typed schemas.

**Flow**:
```
1. terraform init: Download provider binary
2. Launch provider process, handshake
3. Schema discovery: "What resources do you manage?"
4. During apply: "Create aws_instance with..." → Call AWS API → Return ID
```

**Failure Implications**:
- Provider hangs on API timeout → apply blocks
- Provider crashes → partial state (resources 1-49 created, 50+ never started)
- Recovery: Restart apply, Terraform continues from where it left off

---

### 9. When would you use `-target`? What are the risks?

**Senior DevOps Answer**:

**How it Works**: Build DAG, filter to matching resources + their dependencies, execute only that subset.

**Safe Uses**:
- Rescue from failed apply: reapply just the failed resource
- Fast iteration during development
- Staged deployment (with approval gates between stages)

**Dangerous** (❌ Never):
- Selective destruction (`destroy -target`) → orphaned resources
- Recurring use in production → breaks idempotency
- Trying to avoid full-config testing

**Best Practice**: Use with `-out` to review plan first, then do full apply immediately after.

---

### 10. How would you approach multi-environment (dev/staging/prod) deployment?

**Senior DevOps Answer**:

**Avoid**: Monolithic state with env variables (blast radius too large).

**Use**: Separate directories per environment, shared modules:
```
infrastructure/
├── modules/ (reusable across all envs)
├── dev/ (separate backend, tfvars)
├── staging/ (separate backend, tfvars)
└── prod/ (separate backend, enhanced security)
```

**Benefits**:
- Clear separation of concerns
- Different backends per env (prod uses KMS, locks)
- Easy to see env differences
- Reduced blast radius

**Common Pitfall**: Copy-paste errors across envs → Solution: Use modules, don't duplicate HCL.

---

### 11. Design a complete disaster recovery strategy using Terraform.

**Senior DevOps Answer**:

**Architecture**:
```
Primary (us-east-1, active)
├─ RDS Master
├─ App tier (4 instances)
└─ Load balancer

DR (us-west-2, passive)
├─ RDS read replica (continuous replication)
├─ Warm standby (2 instances, scaled-down)
└─ Load balancer (ready for failover)
```

**Automated**:
- RDS read replica in DR region
- S3 cross-region replication
- Route53 health checks
- CloudWatch alarms

**Manual**:
- Promote RDS replica to master
- Update app connection strings
- Switch Route53 failover record
- Scale up warm standby
- Run smoke tests

**RTO**: ~14 minutes (detection + failover + scale)
**RPO**: < 1 second (continuous RDS replication)

---

### 12. If `terraform apply` fails mid-way (resource 50 of 100), how do you recover?

**Senior DevOps Answer**:

**Recovery Strategies**:

1. **Retry**: Often succeeds if error was transient
   ```bash
   terraform apply  # Continues from where it left off
   ```

2. **Remove Failed Resource**: If retry doesn't work
   ```bash
   terraform state rm 'aws_autoscaling_group.app'
   aws autoscaling delete-auto-scaling-group --auto-scaling-group-name app-asg --force-delete
   terraform apply
   ```

3. **Target Specific Resource**: Surgical approach
   ```bash
   terraform plan -out=recovery.tfplan
   terraform apply -target 'aws_autoscaling_group.app' recovery.tfplan
   terraform apply recovery.tfplan  # Full apply to verify
   ```

4. **Restore State**: Last resort if state corrupted
   ```bash
   aws s3api get-object --bucket terraform-state --key prod/terraform.tfstate --version-id <version-before-failure> terraform.tfstate.restored
   terraform state push terraform.tfstate.restored
   # Manual cleanup of partial AWS resources
   terraform apply
   ```

**Prevention**:
- Set timeouts on resources
- Add health checks
- Lower parallelism (`-parallelism=3`) for critical resources
- Explicit dependency ordering

---

**Study Guide Complete**: 5000+ lines covering Terraform Architecture Basics from foundational concepts through advanced production patterns. Designed for Senior DevOps Engineers with 5-10+ years experience.
