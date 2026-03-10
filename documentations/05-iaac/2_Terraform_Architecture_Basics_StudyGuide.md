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
    - [Dependency Graph](#dependency-graph)
    - [Execution Plan](#execution-plan)
    - [Parallelism and Resource Ordering](#parallelism-and-resource-ordering)
    - [Plan Output Interpretation](#plan-output-interpretation)

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

---

## State Files

### Textual Deep Dive

#### Architecture Role

State files are the persistent storage mechanism for Terraform's knowledge of deployed infrastructure. Beyond simple key-value storage, .tfstate files serve multiple critical functions:

1. **Resource ID Mapping**: Maps logical Terraform names (`aws_instance.web`) to physical AWS IDs (`i-1234567890abcdef0`)
2. **Attribute Cache**: Stores provider-returned attributes to detect changes without repeated API calls
3. **Dependency Metadata**: Records implicit and explicit dependencies for correct execution ordering
4. **Change Tracking**: Enables minimal change detection (only update resources that changed, not redeploy everything)

#### Internal Working Mechanism

**State File Structure** (v4 format):

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 147,
  "lineage": "8c4488f4-5b7c-47ac-9e22-be59dcf91d8e",
  "outputs": {
    "vpc_id": {
      "value": "vpc-abc123",
      "type": "string",
      "sensitive": false
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-1234567890abcdef0",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t3.micro",
            "private_ip": "10.0.1.50",
            "public_ip": "54.1.2.3",
            "security_groups": ["sg-abc123"],
            "tags": {"Name": "web-server", "Environment": "prod"}
          },
          "sensitive_attributes": [],
          "private": "eyJlMmJmYjczMC1jY2ExLTExZTYtOTJkZi00MjAwMjBkZjIwOTAiOiJlIiwiZTg1YmY4ZWItY2NhMS0xMWU2LTkyZGYtNDIwMDIwZGYyMDkwIjoie1wiaW5kZXhcIjpcIjBcIn0ifQ==",
          "dependencies": ["aws_vpc.main"]
        }
      ]
    }
  ]
}
```

**Key Structures**:
- **serial**: Version counter; incremented on every write. Detects concurrent modifications
- **lineage**: UUID tracking state evolution over time
- **private**: Base64-encoded provider-specific data (resource type specifics)
- **dependencies**: Explicit dependency array for graph ordering

**State Read During Plan**:
```
1. Deserialize .tfstate JSON
2. Index resources by type + name
3. Extract resource IDs
4. For each resource in config:
   a. Look up current ID in state
   b. Call provider.ReadResource(ID)
   c. Compare attributes returned vs. state
   d. Compare attributes vs. config
   e. Determine if Create/Update/Delete needed
```

#### Production Usage Patterns

**Pattern 1: State File Organization for Multi-Team**

```
terraform/
├── backend-config/
│   ├── dev.hcl
│   ├── staging.hcl
│   └── prod.hcl
├── infrastructure/
│   ├── networking/
│   │   ├── main.tf
│   │   └── backend.tf (key = networking/terraform.tfstate)
│   ├── compute/
│   │   ├── main.tf
│   │   └── backend.tf (key = compute/terraform.tfstate)
│   └── databases/
│       ├── main.tf
│       └── backend.tf (key = databases/terraform.tfstate)
```

Each domain maintains independent state with separate backends:
```bash
# Networking team
cd infrastructure/networking
terraform init -backend-config=../../backend-config/prod.hcl
terraform apply

# Compute team (independent)
cd infrastructure/compute
terraform init -backend-config=../../backend-config/prod.hcl
terraform apply
```

**Pattern 2: State File Encryption with KMS**

```hcl
# kms.tf
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# backend.tf
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    kms_key_id = "arn:aws:kms:us-east-1:ACCOUNT:key/KEY-ID"
  }
}
```

#### DevOps Best Practices

**1. Understand State Serialization**

State is not readable or editable text—it's JSON-serialized with embedded binary data:

```bash
# View state in human-readable form
terraform state show

# Don't do this
cat terraform.tfstate | jq '.resources[0]'  # Binary data unreadable

# Instead
terraform state show 'aws_instance.web'
```

**2. Monitor State File Changes**

```bash
# S3 bucket with versioning + CloudTrail
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_grants {
    grantee {
      type = "LogDeliveryWrite"
    }
  }
}

# CloudTrail for S3 access audit
resource "aws_cloudtrail" "terraform_state_trail" {
  name                          = "terraform-state-access"
  s3_bucket_name                = aws_s3_bucket.terraform_state.id
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.allow_cloudtrail]
}
```

**3. Implement State Backup Strategy**

```bash
#!/bin/bash
# backup_terraform_state.sh
BACKUP_DIR="/backups/terraform"
TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)

# Download from S3
aws s3 cp s3://terraform-state-bucket/prod/terraform.tfstate \
  $BACKUP_DIR/terraform_$TIMESTAMP.tfstate

# Encrypt backup
openssl enc -aes-256-cbc -in $BACKUP_DIR/terraform_$TIMESTAMP.tfstate \
  -out $BACKUP_DIR/terraform_$TIMESTAMP.tfstate.enc -k $ENCRYPTION_PASSWORD

# Remove unencrypted copy
rm $BACKUP_DIR/terraform_$TIMESTAMP.tfstate

# Clean old backups (retain 30 days)
find $BACKUP_DIR -type f -mtime +30 -delete
```

#### Common Pitfalls

**Pitfall 1: State File Containing Secrets**

Default state files store all resource attributes—including passwords, API keys, database credentials.

**Risk**: If state is compromised, all secrets are exposed.

**Mitigation**:
```hcl
# Use externally-managed secrets
resource "aws_db_instance" "app" {
  allocated_storage = 20
  engine           = "mysql"
  username         = "admin"
  password         = random_password.db_password.result  # ❌ Still in state!
  # OR (better)
  password         = var.db_password_from_secret_manager  # From external Secret Manager
}

# Mark sensitive outputs
output "db_password" {
  value       = aws_db_instance.app.password
  sensitive   = true  # Won't appear in logs, but STILL in state file
}
```

**Best Practice**: Manage passwords via AWS Secrets Manager, not Terraform variables.

**Pitfall 2: Concurrent State Modifications Without Locking**

Two engineers run apply simultaneously:
```
Engineer 1: Read state (serial=50) → Make changes → Write state (serial=51)
Engineer 2: Read state (serial=50) → Make changes → Write state (serial=51)
Result: Engineer 1's changes lost!
```

**Mitigation**: Always enable DynamoDB locking.

**Pitfall 3: State Without Backups**

Single corrupted resource in state requires manual recovery.

**Mitigation**: S3 versioning + automated daily backups.

---

### Practical Code Examples

#### Example 1: Complete S3 Backend Configuration with Security

```hcl
# s3_backend.tf - Complete production backend setup
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
  
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Purpose   = "state-backend"
    }
  }
}

# KMS key for state encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "terraform-state-key"
  }
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# S3 bucket for state storage
resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "terraform-state"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for state recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Enabled"  # Requires MFA to permanently delete versions
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Enable access logging
resource "aws_s3_bucket" "terraform_state_logs" {
  bucket = "terraform-state-logs-${data.aws_caller_identity.current.account_id}"
  
  tags = {
    Name = "terraform-state-logs"
  }
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs.id
  target_prefix = "state-access-logs/"
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "Expiration"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "terraform-locks"
  }
}

# IAM policy for Terraform operations
resource "aws_iam_policy" "terraform_state_access" {
  name        = "terraform-state-access"
  description = "Policy for Terraform state access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3StateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "S3StateListing"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Sid    = "DynamoDBLocking"
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      },
      {
        Sid    = "KMSEncryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.terraform_state.arn
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}

# Outputs for documentation
output "state_bucket" {
  value       = aws_s3_bucket.terraform_state.id
  description = "S3 bucket for Terraform state"
}

output "dynamodb_table" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table for state locking"
}

output "kms_key_id" {
  value       = aws_kms_key.terraform_state.id
  description = "KMS key ID for state encryption"
}

output "terraform_backend_config" {
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    kms_key_id     = aws_kms_key.terraform_state.id
    region         = "us-east-1"
  }
  description = "Backend configuration details"
}
```

**Usage**:
```bash
# 1. Initialize this backend setup
terraform init

# 2. Create backend infrastructure
terraform apply

# 3. Copy output values to downstream terraform backend config:
# backend.tf in application code:
terraform {
  backend "s3" {
    bucket         = "terraform-state-<account-id>"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:<account-id>:key/<key-id>"
    dynamodb_table = "terraform-locks"
  }
}
```

#### Example 2: State Migration and Recovery

```bash
#!/bin/bash
# migrate_state.sh - Migrate from local to S3 backend

set -e

ENVIRONMENT=${1:-dev}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
S3_BUCKET="terraform-state-${ACCOUNT_ID}"
DYNAMODB_TABLE="terraform-locks"
REGION="us-east-1"

echo "=== Terraform State Migration ==="
echo "Environment: $ENVIRONMENT"
echo "S3 Bucket: $S3_BUCKET"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo

# 1. Create backend config file
cat > backend_config.hcl <<EOF
bucket         = "$S3_BUCKET"
key            = "$ENVIRONMENT/terraform.tfstate"
region         = "$REGION"
encrypt        = true
dynamodb_table = "$DYNAMODB_TABLE"
EOF

echo "✓ Created backend_config.hcl"

# 2. Backup current state
if [ -f terraform.tfstate ]; then
  BACKUP_FILE="terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
  cp terraform.tfstate "$BACKUP_FILE"
  echo "✓ Backed up state to $BACKUP_FILE"
fi

# 3. Initialize with new backend
echo "Initializing S3 backend..."
terraform init -backend-config=backend_config.hcl -upgrade

echo
echo "=== Migration Complete ==="
echo "State is now stored in: s3://${S3_BUCKET}/${ENVIRONMENT}/terraform.tfstate"
echo "State locking enabled via DynamoDB"
echo

# 4. Verify state
echo "Current state:"
terraform state list
```

**Recovery Scenario**:
```bash
#!/bin/bash
# recover_state.sh - Recover state from S3 version

STATE_VERSION=${1:?}
BACKUP_DIR="./state_backups"

mkdir -p $BACKUP_DIR

echo "Downloading state version: $STATE_VERSION"
aws s3api get-object \
  --bucket "terraform-state-$(aws sts get-caller-identity --query Account --output text)" \
  --key "prod/terraform.tfstate" \
  --version-id "$STATE_VERSION" \
  "$BACKUP_DIR/terraform.tfstate.recovered"

echo "✓ Downloaded to  $BACKUP_DIR/terraform.tfstate.recovered"

# Review the recovered state
echo "Reviewing recovered state..."
terraform state -h  # Show options

# If confirmed as correct:
# terraform state push "$BACKUP_DIR/terraform.tfstate.recovered"
```

---

## State Locking

### Textual Deep Dive

#### Architecture Role

State locking is the synchronization mechanism preventing concurrent modifications to shared state. Without locking, parallel applies would corrupt state—making infrastructure unmanageable.

#### Internal Working Mechanism

**Lock Acquisition Flow**:
```
terraform apply
  ├─ Acquire lock
  │   └─ DynamoDB: Put item {LockID, Digest, Who, When, Why}
  ├─ Proceed with apply
  │   ├─ Read state
  │   ├─ Execute changes
  │   └─ Write state
  ├─ Release lock
  │   └─ DynamoDB: Delete item {LockID}
  └─ Complete
```

**Lock Contention**:
```
User A: terraform apply
  └─ Acquires lock

User B (concurrent): terraform apply
  └─ Requests lock → WAITS
  └─ Retries every second
  └─ Default timeout: 10 minutes
  └─ If timeout: Error (lock not released)

User A: terraform apply
  └─ Releases lock

User B: Acquires lock → Proceeds
```

#### Production Usage Patterns

**Pattern: Enforced Locking in CI/CD**

```yaml
# .github/workflows/terraform.yml
name: Terraform Apply
on:
  push:
    branches: [main]

jobs:
  apply:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Terraform Init with Lock
        run: terraform init -backend-config=backend.hcl
        
      - name: Terraform Apply with Lock
        run: terraform apply -auto-approve
        timeout-minutes: 30  # Ensure lock released within 30min
        
      - name: Force Unlock if Needed
        if: failure()
        run: |
          LOCK_ID=$(terraform backends -auto-approve 2>&1 | grep LockID | cut -d: -f2)
          if [ ! -z "$LOCK_ID" ]; then
            terraform force-unlock $LOCK_ID
          fi
```

#### Common Pitfalls

**Pitfall 1: Stale Locks Blocking Operations**

If Terraform process crashes, lock remains:
```bash
# BLOCKED - can't proceed
terraform apply  # Error: resource locked

# CORRECT - remove stale lock (only if process truly dead)
terraform force-unlock $LOCK_ID
```

---

## Local vs. Remote State

### Textual Deep Dive

#### Key Differences

| Aspect | Local | Remote |
|--------|-------|--------|
| Storage | .terraform/terraform.tfstate | Backend (S3, Terraform Cloud, etc.) |
| Sharing | File-based (Git, shared FS) | Automatic sync |
| Locking | Basic file locks | DynamoDB/Native |
| Encryption | None (unless encrypted disk) | Built-in (KMS, HTTPS) |
| Versioning | Manual | Automatic |
| Collaboration | Difficult | Easy (built-in) |

#### When to Use Each

**Local State** (Never in production):
- Single developer learning Terraform
- Temporary/throwaway infrastructure
- Development on isolated machine

**Remote State** (Always in production):
- Teams (2+ people)
- Shared infrastructure
- Compliance requirements
- Disaster recovery needs

#### Internal Working Mechanism

**Local State Workflow**:
```
terraform apply
  ├─ .terraform/terraform.tfstate (check local file)
  ├─ Lock: flock (filesystem lock - unreliable over NFS)
  ├─ Read: Parse JSON
  ├─ Apply changes
  ├─ Update: Write JSON
  └─ Release: Remove lock
```

**Remote State Workflow**:
```
terraform apply
  ├─ S3/Terraform Cloud (network-based)
  ├─ Lock: DynamoDB (reliable, distributed)
  ├─ Read: HTTP GET
  ├─ Apply changes
  ├─ Update: HTTP PUT
  └─ Release: HTTP DELETE
```

#### Common Pitfalls

**Pitfall 1: Git-Committing Local State Files**

```bash
# BAD - state file in Git
git add terraform.tfstate
git commit -m "Add terraform state"
git push

# Now everyone has the old state, secrets are in Git history forever
```

**Correction**:
```bash
# Add to .gitignore
echo "*.tfstate*" >> .gitignore
echo ".terraform/" >> .gitignore

# Remove from history
git rm --cached terraform.tfstate
git commit -m "Remove state from version control"
```

---

## Backend Configuration

### Textual Deep Dive

#### Available Backends

Terraform supports backends for:
- **AWS S3** (with DynamoDB locking)
- **Azure Storage** (with Azure Blobs)
- **Google Cloud GCS** (with state locking)
- **Terraform Cloud/Enterprise** (fully managed)
- **Consul** (distributed storage)
- **HTTP** (custom implementations)

#### Switching Backends

```bash
# Local to S3
# 1. Create backend.tf with S3 configuration
# 2. Run terraform init -migrate-state

# S3 to Terraform Cloud
# 1. Update backend block to cloud
# 2. Run terraform login (for API token)
# 3. Run terraform init -migrate-state
# 4. Confirm migration
```

#### Common Pitfalls

**Pitfall 1: Forgetting to -migrate-state**

```bash
# WRONG - creates new empty state
terraform init  # Terraform asks to migrate, you say no

# CORRECT
terraform init -migrate-state  # Copies state to new backend
```

---

## State Security

### Textual Deep Dive

#### Threat Model

| Threat | Impact | Mitigation |
|--------|--------|-----------|
| Unauthorized Read | Secrets exposed | Encryption + IAM |
| Unauthorized Write | Infrastructure takeover | IAM + State locking |
| Accidental Deletion | Data loss | Versioning + Backups |
| Network Interception | Secrets exposed | HTTPS + VPN |

#### Security Best Practices

1. **Encryption at Rest**: KMS (AWS), SSE (Azure), ...
2. **Encryption in Transit**: HTTPS always
3. **IAM Policies**: Least privilege access
4. **MFA Delete**: Require MFA to permanently delete state
5. **Audit Logging**: CloudTrail for access tracking
6. **Backup Strategy**: Daily snapshots, 30-day retention
7. **Secrets Rotation**: Regular password/key rotation

---

### Practical Code Examples

#### Example: Secure State Backend with Compliance

```hcl
# secure_backend.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  environment = terraform.workspace
  project     = "myapp"
}

# ===== KMS Key for Encryption =====
resource "aws_kms_key" "terraform_state" {
  description = "KMS for Terraform state - ${local.environment}"
  
  enable_key_rotation = true
  rotation_period_in_days = 90
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM policies"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Terraform to use key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.terraform.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${local.project}-terraform-key-${local.environment}"
    Environment = local.environment
  }
}

# ===== S3 Bucket for State =====
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.project}-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${local.project}-state-${local.environment}"
    Environment = local.environment
  }
}

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
    mfa_delete = local.environment == "prod" ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# ===== DynamoDB Lock Table =====
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "${local.project}-terraform-locks-${local.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "Expiration"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "${local.project}-locks-${local.environment}"
    Environment = local.environment
  }
}

# ===== CloudTrail for Audit =====
resource "aws_cloudtrail" "terraform_state_audit" {
  count                         = local.environment == "prod" ? 1 : 0
  name                          = "${local.project}-terraform-audit"
  s3_bucket_name                = aws_s3_bucket.terraform_state_logs[0].id
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# ===== IAM Role for Terraform =====
resource "aws_iam_role" "terraform" {
  name = "${local.project}-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CICDRunner"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "terraform_state" {
  name = "${local.project}-terraform-policy"
  role = aws_iam_role.terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3 Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "DynamoDB Lock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      },
      {
        Sid    = "KMS Encryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.terraform_state.arn
      }
    ]
  })
}

# ===== Data Source =====
data "aws_caller_identity" "current" {}

# ===== Outputs =====
output "backend_config" {
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    kms_key_id     = aws_kms_key.terraform_state.id
    region         = "us-east-1"
  }
  description = "S3 backend configuration"
}
```

---

### ASCII Diagrams

#### State File Security Architecture

```
┌─────────────────────────────────────────────────────┐
│        Terraform Configuration (.tf files)          │
├─────────────────────────────────────────────────────┤
│ • Desired state (version controlled)                │
│ • No secrets here (use variables)                   │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│        Terraform State File (.tfstate)              │
│  ┌─────────────────────────────────────────────┐   │
│  │ Contains:                                   │   │
│  │ • Resource IDs                              │   │
│  │ • Provider attributes                       │   │
│  │ • SECRETS (passwords, keys)                 │   │
│  └─────────────────────────────────────────────┘   │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│              S3 Bucket Storage                      │
│  ┌──────────────────────────────────────────────┐  │
│  │ Encryption: KMS (at rest)                    │  │
│  │ Versioning: Enabled (point-in-time recovery) │  │
│  │ Public Access: Blocked                       │  │
│  │ Logging: CloudTrail (audit trail)            │  │
│  │ MFA Delete: Enabled (compliance)             │  │
│  └──────────────────────────────────────────────┘  │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│        HTTPS Transport + TLS                        │
└──────────────────┬──────────────────────────────────┘
                   ↓
┌─────────────────────────────────────────────────────┐
│        DynamoDB Lock Table                          │
│  ┌──────────────────────────────────────────────┐  │
│  │ Prevents concurrent modifications            │  │
│  │ Encryption: AWS-managed keys                 │  │
│  │ TTL: Automatic stale lock cleanup            │  │
│  │ Point-in-time recovery: Enabled              │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

#### State Lifecycle with Locking

```
┌─────────────────────────────────┐
│   User: terraform apply         │
└────────────┬────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ 1. DynamoDB: Acquire Lock            │
│    ✓ Lock acquired (LockID=unique)   │
└────────────┬─────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ 2. S3: GetObject (state)             │
│    ✓ Retrieved current state          │
│    ✓ Decrypted with KMS              │
└────────────┬─────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ 3. Provider API: Read current AWS    │
│    ✓ Detected drift (if any)          │
└────────────┬─────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ 4. Execute Changes                   │
│    ✓ Create/Update/Delete resources  │
└────────────┬─────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ 5. S3: PutObject (state)             │
│    ✓ Encrypted with KMS              │
│    ✓ Versioned                       │
│    ✓ Logged to CloudTrail            │
└────────────┬─────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ 6. DynamoDB: Release Lock            │
│    ✓ Lock deleted                    │
└──────────────────────────────────────┘
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

#### Example 1: Multi-Tier Application with Explicit Ordering

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

# variables.tf
variable "environment" {
  type = string
  description = "Environment name (dev, staging, prod)"
}

variable "app_port" {
  type    = number
  default = 8080
  description = "Application port"
}

variable "instance_count" {
  type    = number
  default = 3
  description = "Number of instances in ASG"
}

# data.tf - Query existing infrastructure
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# networking.tf - Foundation layer
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# security_groups.tf - Security layer (depends on VPC)
resource "aws_security_group" "alb" {
  name   = "${var.environment}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "app" {
  name   = "${var.environment}-app-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # Implicit dependency
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-app-sg"
  }
  
  depends_on = [aws_security_group.alb]  # Explicit dependency
}

# compute.tf - Application layer (depends on networking & security)
resource "aws_lb" "main" {
  name            = "${var.environment}-alb"
  internal        = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public[*].id

  tags = {
    Name = "${var.environment}-alb"
  }
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-app-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path               = "/"
    matcher            = "200"
  }

  tags = {
    Name = "${var.environment}-app-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_launch_template" "app" {
  name         = "${var.environment}-app-lt"
  image_id     = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              systemctl start nginx
              echo "<h1>Instance $(ec2-metadata --instance-id | cut -d' ' -f2)</h1>" > /var/www/html/index.html
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = "${var.environment}-app-instance"
      Environment = var.environment
    }
  }

  depends_on = [aws_security_group.app]
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.environment}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  min_size         = 2
  max_size         = var.instance_count * 2
  desired_capacity = var.instance_count

  tag {
    key                 = "Name"
    value               = "${var.environment}-asg-instance"
    propagate_launch_template = true
  }

  depends_on = [aws_lb_listener.app]
}

# outputs.tf
output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "DNS name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "Auto scaling group name"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}
```

**Dependency Graph for this example**:

```
Level 0 (Parallel):
  ├─ data.aws_availability_zones
  ├─ data.aws_ami.ubuntu
  └─ aws_vpc.main

Level 1 (Depends on VPC):
  ├─ aws_subnet.public[*]
  ├─ aws_security_group.alb (vpc_id reference)
  └─ aws_security_group.app (vpc_id reference)
  
Level 2 (Depends on L1):
  ├─ aws_internet_gateway.main (vpc_id)
  ├─ aws_route_table.public (vpc_id)
  └─ aws_security_group_rule (SG references)

Level 3 (Depends on L2):
  ├─ aws_route_table_association[*]
  └─ aws_lb.main (subnets, SGs)

Level 4 (Depends on L3):
  ├─ aws_launch_template.app
  └─ aws_lb_target_group.app

Level 5 (Depends on L4):
  ├─ aws_lb_listener.app
  └─ aws_lb_listener requires aws_lb_target_group

Level 6 (Final):
  └─ aws_autoscaling_group.app (depends on listener + template)
```

**Execution with parallelism=10**:
```bash
terraform apply
# Timeline:
T 0s: Start Level 0 (VPC, Zones, AMI) - 3 resources
T 2s: Complete Level 0, Start Level 1 (subnets, SGs) - 3 resources
T 4s: Complete Level 1, Start Level 2 (IGW, route table) - 2 resources
T 5s: Complete Level 2, Start Level 3 (routes + ALB) - 3 resources
T 7s: Complete Level 3, Start Level 4 (launch template, TG) - 2 resources
T 8s: Complete Level 4, Start Level 5 (listener) - 1 resource
T 9s: Complete Level 5, Start Level 6 (ASG) - 1 resource
T 12s: Complete, done
```

#### Example 2: Debugging Dependency Graph

```bash
#!/bin/bash
# analyze_dependencies.sh

echo "=== Terraform Dependency Analysis ==="
echo

# 1. Generate graph in text format
echo "Dependency Graph (text):"
terraform graph | grep '\->'

echo
echo "=== Resource Ordering ==="

# 2. Show apply order
terraform plan -json | jq -r '.resource_changes[] | "\(.change.actions[0]) \(.type).\(.name)"' | head -20

echo
echo "=== Parallelism Analysis ==="

# 3. Count truly parallel resources
TOTAL=$(terraform plan -json | jq '[.resource_changes[]] | length')
echo "Total resources: $TOTAL"
echo "Max parallelism: 10 (default)"
echo "Min depth: $(terraform graph | grep '\->' | wc -l) dependencies"

echo
echo "=== Critical Path ==="
# 4. Find longest dependency chain
terraform graph | grep -E '(aws_autoscaling_group|aws_security_group)' | head -10
```

#### Example 3: Using -target for Selective Deployment

```bash
#!/bin/bash
# selective_apply.sh

RESOURCE=$1
OPERATION=${2:-apply}

if [ -z "$RESOURCE" ]; then
  echo "Usage: $0 <resource> [apply|destroy|plan]"
  echo "Example: $0 'aws_autoscaling_group.app' apply"
  exit 1
fi

echo "=== Planning $OPERATION for $RESOURCE ==="

case $OPERATION in
  plan)
    terraform plan -target="$RESOURCE" -out=tfplan
    echo "✓ Saved plan to tfplan"
    ;;
  apply)
    echo "Planning..."
    terraform plan -target="$RESOURCE" -out=tfplan
    read -p "Proceed with apply? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      terraform apply tfplan
    fi
    ;;
  destroy)
    echo "WARNING: Targeted destroy may leave orphaned resources!"
    read -p "Destroy $RESOURCE? (CONFIRM/cancel) " confirmation
    if [ "$confirmation" = "CONFIRM" ]; then
      terraform destroy -target="$RESOURCE" -auto-approve
    else
      echo "Cancelled"
    fi
    ;;
esac
```

**SAFE Usage Pattern**:
```bash
# 1. Target plan only (read-only)
terraform plan -target='aws_security_group.app'

# 2. Target apply (safe if dependencies OK)
terraform apply -target='aws_security_group.app'

# 3. NEVER do this (creates orphans):
# terraform destroy -target='aws_vpc.main'  # Children left behind!
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

### Scenario 1: State Recovery After Accidental Destruction

**Situation**: Junior engineer runs `terraform destroy` on production instead of staging. 47 AWS resources destroyed in 8 seconds. RDS automated backups exist from 5 minutes ago. 500+ users experiencing outages. SLA breach in 2 hours.

**Root Cause**: Workspace not properly named, applied to wrong environment.

**Recovery Steps**:

**Phase 1: Immediate Response (0-5 minutes)**

```bash
#!/bin/bash
# emergency_recovery.sh

set -x  # Debug mode

ENVIRONMENT="prod"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="terraform-state-${ACCOUNT_ID}"
STATE_KEY="prod/terraform.tfstate"

echo "=== EMERGENCY RECOVERY INITIATED ==="
echo "Environment: $ENVIRONMENT"
echo "Time: $(date)"
echo

# 1. Block further Terraform operations
echo "[Step 1] Acquiring state lock to prevent concurrent applies..."
aws dynamodb put-item \
  --table-name terraform-locks \
  --item "{\"LockID\": {\"S\": \"$STATE_KEY\"}, \"Digest\": {\"S\": \"EMERGENCY_LOCK\"}, \"Who\": {\"S\": \"RECOVERY_TEAM\"}, \"When\": {\"N\": \"$(date +%s)\"}, \"Why\": {\"S\": \"DISASTER_RECOVERY\"}}"

echo "✓ Lock acquired"
echo

# 2. Identify most recent valid state version
echo "[Step 2] Finding most recent valid state..."
aws s3api list-object-versions \
  --bucket $STATE_BUCKET \
  --prefix $STATE_KEY \
  --query 'Versions[?LastModified>=`2024-03-07T10:00:00Z`].[VersionId,LastModified,Size]' \
  --output table

read -p "Enter version ID of last known good state: " VERSION_ID

# 3. Download that state
echo "[Step 3] Downloading state version $VERSION_ID..."
aws s3api get-object \
  --bucket $STATE_BUCKET \
  --key $STATE_KEY \
  --version-id $VERSION_ID \
  terraform.tfstate.recovered

echo "✓ State downloaded"
echo

# 4. Restore RDS from backup (if applicable)
echo "[Step 4] Restoring RDS instance from snapshot..."
DB_SNAPSHOTS=$(aws rds describe-db-snapshots \
  --db-instance-identifier prod-database \
  --query 'DBSnapshots[?SnapshotCreateTime>=`2024-03-07T10:00:00Z`].DBSnapshotIdentifier' \
  --output text)

echo "Available snapshots: $DB_SNAPSHOTS"
read -p "Enter snapshot ID to restore from: " SNAPSHOT_ID

aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-database-restored \
  --db-snapshot-identifier $SNAPSHOT_ID \
  --no-auto-minor-version-upgrade

echo "✓ RDS restore initiated (will take 5-10 minutes)"
echo

# 5. Verify state integ before applying
echo "[Step 5] Verifying state integrity..."
# Check for null/undefined resources
ISSUES=$(grep -o '"id".*"$' terraform.tfstate.recovered | grep -i 'null\|undefined' | wc -l)
echo "Potential issues found: $ISSUES"

echo
echo "=== PHASE 1 COMPLETE ==="
echo "Next steps:"
echo "1. Wait for RDS restore to complete"
echo "2. Run terraform apply with recovered state"
echo "3. Validate connectivity and application health"
```

**Phase 2: Infrastructure Restoration (5-30 minutes)**

```bash
#!/bin/bash
# restore_infrastructure.sh

echo "[Step 6] Preparing for infrastructure restore..."

# Verify Terraform configuration matches state
terraform validate

# Plan the restoration (should show all resources being created)
echo "Generating recovery plan..."
terraform plan -var-file=prod.tfvars -out=recovery.tfplan

# Review plan
echo "=== RECOVERY PLAN ===" 
terraform show recovery.tfplan | grep '^aws_' | wc -l
echo " resources will be recreated"

read -p "Proceed with restoration? (type YES to confirm): " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted"
  exit 1
fi

# Apply the plan
echo "[Step 7] Applying recovery plan..."
terraform apply recovery.tfplan

echo "✓ Infrastructure restored"

# Verify health
echo "[Step 8] Validation checks..."
echo "Checking ELB health..."
aws elbv2 describe-target-health --target-group-arn $(terraform output -raw target_group_arn) \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
  --output table

echo "[Step 9] Smoke tests..."
ALB_DNS=$(terraform output -raw alb_dns_name)
curl -f "http://$ALB_DNS/health" && echo "✓ Application responding"

echo
echo "=== RECOVERY COMPLETE ==="
```

**Post-Incident Actions**:

```bash
# 1. Lock state for safety
terraform state lock  # Prevent future accidental destroys

# 2. Require approval for destroy
# Add to CI/CD: require manual approval for destroy operations

# 3. Rename workspace to prod (if using workspaces)
terraform workspace select prod
terraform workspace rename staging prod

# 4. Document lessons learned
cat > INCIDENT_REPORT.md << EOF
## Incident Report: Production Destruction

### Timeline
- 10:05 GMT: Destruction began
- 10:08 GMT: Outage detected
- 10:12 GMT: Recovery initiated
- 10:45 GMT: Services restored

### Root Cause
- Workspace names not clearly labeled
- No confirmation prompt for destroy
- Missing monitoring alert for sudden resource deletion

### Preventions
1. Require approval for ALL destroy operations
2. Consistent workspace naming (ENVIRONMENT-NAME)
3. Tag resources with environment (prevents cross-env operations)
4. Destroy confirmation prompt required
5. CloudWatch alert on "UnauthorizedOperation" and resource deletion

### Metrics
- RTO: 40 minutes
- RPO: 5 minutes (snapshot age)
- Recovery Success: 100%
EOF

git add INCIDENT_REPORT.md
git commit -m "docs: incident report for prod destruction recovery"
```

---

### Scenario 2: Circular Dependency Resolution

**Situation**: Terraform plan fails with: `Error: Cycle detected in module dependencies`

**Modules**:
- **Module A** (Compute): EC2 instances, needs security group IDs
- **Module B** (Security): Security groups,needs EC2 instance IDs for authorization rules

**Root Cause**:
```hcl
# Module A (compute)
data "aws_security_group" "from_module_b" {
  name = "app-sg"  # Queries Module B's output!
}

# Module B (security)
data "aws_security_group" "from_module_a" {
  name = "database-sg"  # Queries Module A's output!
}
```

**Resolution**:

```hcl
# Root module - orchestrates dependency wiring
module "security" {
  source = "./modules/security"
  vpc_id = aws_vpc.main.id
  # NO data source queries here
}

module "compute" {
  source = "./modules/compute"
  vpc_id = aws_vpc.main.id
  
  # Pass security group from security module as INPUT
  app_security_group_id = module.security.app_sg_id
  
  # Explicit dependency
  depends_on = [module.security]
}

# Module A (compute/main.tf) - UPDATED
variable "app_security_group_id" {
  type = string
  description = "Security group ID (provided by root module)"
}

resource "aws_instance" "app" {
  security_groups = [var.app_security_group_id]  # Use input, not data source
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

# Module B (security/main.tf) - UPDATED
variable "app_instance_ids" {
  type = list(string)
  default = []
  description = "Instance IDs needing access (optional)"
}

resource "aws_security_group" "app" {
  name = "app-sg"
}

output "app_sg_id" {
  value = aws_security_group.app.id
}
```

**Key Principle**: One-directional dependencies only. Sibling modules communicate via parent (root) module.

---

### Scenario 3: Drift Detection and Automated Remediation

**Situation**: Infrastructure has drifted from desired state:
- 23 security groups manually modified
- 8 IAM policies changed via console
- 12 resources missing required tags
- 4 auto-scaling group configurations outdated

**Setup Automated Detection**:

```hcl
# drift_detection.tf
resource "aws_cloudwatch_event_rule" "drift_detection" {
  name                = "terraform-drift-detection"
  description         = "Trigger drift detection every 6 hours"
  schedule_expression = "cron(0 */6 * * ? *)"
}

resource "aws_cloudwatch_event_target" "drift_lambda" {
  rule     = aws_cloudwatch_event_rule.drift_detection.name
  arn      = aws_lambda_function.drift_detector.arn
  role_arn = aws_iam_role.eventbridge.arn
}

resource "aws_lambda_function" "drift_detector" {
  filename      = "drift_detector.zip"
  function_name = "terraform-drift-detector"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  timeout       = 300

  environment {
    variables = {
      TERRAFORM_DIR = "/tmp/terraform"
      SNS_TOPIC_ARN = aws_sns_topic.drift_alerts.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_s3,
    aws_iam_role_policy_attachment.lambda_sns
  ]
}

resource "aws_sns_topic" "drift_alerts" {
  name = "terraform-drift-alerts"
}

resource "aws_sns_topic_subscription" "drift_email" {
  topic_arn = aws_sns_topic.drift_alerts.arn
  protocol  = "email"
  endpoint  = "devops-team@company.com"
}
```

**Lambda Function for Drift Detection**:

```python
# drift_detector.py
import boto3
import os
import subprocess
import json
from datetime import datetime

s3_client = boto3.client('s3')
sns_client = boto3.client('sns')

def handler(event, context):
    """Detect Terraform drift and notify team"""
    
    TERRAFORM_DIR = os.environ['TERRAFORM_DIR']
    SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
    TERRAFORM_BUCKET = os.environ['TERRAFORM_BUCKET']
    
    try:
        # 1. Download Terraform configuration
        print("Downloading Terraform configuration...")
        download_terraform_config(TERRAFORM_BUCKET, TERRAFORM_DIR)
        
        # 2. Initialize Terraform
        print("Initializing Terraform...")
        subprocess.run(
            ['terraform', 'init', '-input=false'],
            cwd=TERRAFORM_DIR,
            check=True,
            capture_output=True
        )
        
        # 3. Run plan and capture output
        print("Running terraform plan...")
        result = subprocess.run(
            ['terraform', 'plan', '-json'],
            cwd=TERRAFORM_DIR,
            capture_output=True,
            text=True
        )
        
        # 4. Parse plan output for changes
        drift_report = parse_plan_output(result.stdout)
        
        # 5. Notify if drift detected
        if drift_report['has_changes']:
            print(f"Drift detected! {drift_report['change_count']} changes")
            send_drift_alert(SNS_TOPIC_ARN, drift_report)
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'status': 'drift_detected',
                    'changes': drift_report['change_count']
                })
            }
        else:
            print("No drift detected")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'status': 'no_drift',
                    'timestamp': datetime.now().isoformat()
                })
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        error_message = {
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }
        sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject='Terraform Drift Detection Error',
            Message=json.dumps(error_message, indent=2)
        )
        raise

def download_terraform_config(bucket, local_path):
    """Download Terraform config from S3"""
    os.makedirs(local_path, exist_ok=True)
    paginator = s3_client.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=bucket, Prefix='terraform/')
    
    for page in pages:
        for obj in page.get('Contents', []):
            key = obj['Key']
            local_file = os.path.join(local_path, key)
            os.makedirs(os.path.dirname(local_file), exist_ok=True)
            s3_client.download_file(bucket, key, local_file)

def parse_plan_output(plan_json):
    """Parse terraform plan JSON output"""
    changes = {
        'resources_to_create': [],
        'resources_to_modify': [],
        'resources_to_delete': [],
        'has_changes': False,
        'change_count': 0
    }
    
    for line in plan_json.split('\n'):
        if not line.strip():
            continue
        try:
            event = json.loads(line)
            
            if event.get('type') == 'resource_drift':
                changes['has_changes'] = True
                action = event['change']['actions'][0]
                resource = f"{event['type']}.{event['name']}"
                
                if action == 'create':
                    changes['resources_to_create'].append(resource)
                elif action == 'update':
                    changes['resources_to_modify'].append(resource)
                elif action == 'delete':
                    changes['resources_to_delete'].append(resource)
                    
                changes['change_count'] += 1
        except json.JSONDecodeError:
            continue
    
    return changes

def send_drift_alert(topic_arn, drift_report):
    """Send SNS notification about drift"""
    message = f"""
Terraform Drift Detected
========================

Timestamp: {datetime.now().isoformat()}

SUMMARY:
  Total Changes: {drift_report['change_count']}
  To Create: {len(drift_report['resources_to_create'])}
  To Modify: {len(drift_report['resources_to_modify'])}
  To Delete: {len(drift_report['resources_to_delete'])}

RESOURCES TO CREATE:
{json.dumps(drift_report['resources_to_create'], indent=2)}

RESOURCES TO MODIFY:
{json.dumps(drift_report['resources_to_modify'], indent=2)}

RESOURCES TO DELETE:
{json.dumps(drift_report['resources_to_delete'], indent=2)}

ACTION REQUIRED:
1. Review the drift changes
2. If intentional: Run 'terraform apply' to update state
3. If unintended: Revert manual changes in AWS console
4. Document reason for drift in team wiki
"""
    
    sns_client.publish(
        TopicArn=topic_arn,
        Subject=f'Terraform Drift Alert: {drift_report["change_count"]} changes detected',
        Message=message
    )
```

**Remediation Decision Matrix**:

| Drift Type | Resource Type | Auto-Remediate? | Reason |
|-----------|---------------|-----------------|--------|
| Tag modifications | All | NO | Compliance review needed |
| Security group rules | AWS SGs | NO | May break security policies |
| IAM policies | AWS IAM | NO | Audit trail required |
| Configuration changes | EC2 LTs | YES | Safe if versions not in use |
| Scaling parameters | ASG | NO | May cause disruption |
| DNS records | AWS Route53 | NO | Business impact check |

**Recovery Workflow**:
```bash
# 1. Detect drift (automated)
terraform plan  # Shows 23 SG changes

# 2. Review changes
terraform plan -json | jq '.[].change'

# 3. Classify each change
# - Intentional (document in code): Keep, update HCL
# - Unintentional (revert): AWS console manual rollback

# 4. Remediate
terraform apply  # Reapplies desired state
# OR
aws ec2 revert-security-group-changes ...  # Manual rollback

# 5. Lock state after remediation
terraform state lock

# 6. Document
echo "Drift remediatedon $(date). Reason: XXX" >> DRIFT_LOG.md
```

---

### Scenario 4: Multi-Region Failover Execution

**Situation**: Primary region (us-east-1) experiences outage. Activate DR region (us-west-2) within SLA.

**Architecture**:

```
PRIMARY (us-east-1) - ACTIVE
├─ RDS Master
├─ 4 App Instances (ASG)
└─ ALB + Route53 weight 100

DR (us-west-2) - WARM STANDBY
├─ RDS Read Replica (continuous sync)
├─ 2 App Instances (scaled down)
└─ ALB + Route53 weight 0
```

**Failover Script**:

```bash
#!/bin/bash
# failover_to_dr.sh

set -x

PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"
PRIMARY_ZONE="usea1"
DR_ZONE="uswe2"
CROSS_REGION_REPLICA_ID="prod-db-dr"

echo "=== INITIATING FAILOVER ==="
echo "Primary -> DR: $PRIMARY_REGION -> $DR_REGION"
echo

# 1. Promote RDS read replica to standalone master
echo "[1/6] Promoting RDS replica..."
aws rds promote-read-replica \
  --db-instance-identifier $CROSS_REGION_REPLICA_ID \
  --region $DR_REGION

# Wait for promotion
aws rds wait db-instance-available \
  --db-instance-identifier $CROSS_REGION_REPLICA_ID \
  --region $DR_REGION

echo "✓ RDS promoted to master"
echo

# 2. Scale up DR ASG
echo "[2/6] Scaling DR application tier..."
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name "prod-asg-$DR_ZONE" \
  --desired-capacity 4 \
  --region $DR_REGION

echo "✓ Scaled to 4 instances (will stabilize in 2-3 min)"
echo

# 3. Update Database connection string
echo "[3/6] Updating app configuration..."
# Could use Parameter Store, Secrets Manager, etc.
aws ssm put-parameter \
  --name "/prod/db-endpoint" \
  --value "prod-db-dr.$XXXXXXX.$DR_REGION.rds.amazonaws.com" \
  --overwrite \
  --region $DR_REGION

echo "✓ DB connection string updated"
echo

# 4. Restart app instances (to pick up new DB endpoint)
echo "[4/6] Restarting app instances..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:aws:autoscaling:groupName,Values=prod-asg-$DR_ZONE" \
  --region $DR_REGION \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

for INSTANCE_ID in $INSTANCE_IDS; do
  aws ec2 reboot-instances \
    --instance-ids $INSTANCE_ID \
    --region $DR_REGION
done

echo "✓ Instances restarting"
# Wait for health checks
sleep 30

# 5. Switch Route53
echo "[5/6] Switching Route53 failover record..."
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "api.myapp.com",
          "Type": "A",
          "SetIdentifier": "Primary",
          "Failover": "SECONDARY",
          "AliasTarget": { "HostedZoneId": "'$PRIMARY_ALB_ZONE'", "DNSName": "'$PRIMARY_ALB_DNS'", "EvaluateTargetHealth": true }
        }
      },
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "api.myapp.com",
          "Type": "A",
          "SetIdentifier": "DR",
          "Failover": "PRIMARY",
          "AliasTarget": { "HostedZoneId": "'$DR_ALB_ZONE'", "DNSName": "'$DR_ALB_DNS'", "EvaluateTargetHealth": false }
        }
      }
    ]
  }'

echo "✓ Route53 updated (DNS may take up to 60s to propagate)"
echo

# 6. Validation
echo "[6/6] Validating failover..."
for i in {1..12}; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://api.myapp.com/health)
  if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Application responding (attempt $i/12)"
    break
  else
    echo "⏳ Waiting for DNS propagation... ($i/12)"
    sleep 5
  fi
done

echo
echo "=== FAILOVER COMPLETE ==="
echo "RTO: ~5 minutes"
echo "Users redirected to DR region"
echo "Monitor DR metrics closely"
```

---

### Scenario 5: State Corruption Recovery

**Situation**: State file corrupted due to:
- S3 bucket versioning disabled (version lost)
- Incomplete write during network failure
- Manual JSON editing with syntax errors
- Concurrent apply without locking

**Detection**:

```bash
#!/bin/bash
# detect_state_corruption.sh

STATE_FILE="terraform.tfstate"

echo "=== State Corruption Check ==="
echo

# 1. Verify JSON syntax
echo "Checking JSON syntax..."
if ! jq empty "$STATE_FILE" 2>/dev/null; then
  echo "✗ CORRUPTION DETECTED: Invalid JSON"
  echo "  Fix: Restore from backup"
  exit 1
fi

# 2. Verify required fields
echo "Checking required fields..."
REQUIRED=("version" "terraform_version" "serial" "lineage" "resources")
for field in "${REQUIRED[@]}"; do
  if ! jq -e ".$field" "$STATE_FILE" > /dev/null 2>&1; then
    echo "✗ CORRUPTION DETECTED: Missing field '$field'"
    exit 1
  fi
done

# 3. Verify resource integrity
echo "Checking resource integrity..."
RESOURCE_COUNT=$(jq '.resources | length' "$STATE_FILE")
echo "  Total resources: $RESOURCE_COUNT"

# Check for orphaned resources (have ID but no attributes)
ORPHANS=$(jq '[.resources[] | select(.instances[] | .attributes | length == 0)] | length' "$STATE_FILE")

if [ $ORPHANS -gt 0 ]; then
  echo "✗ WARNING: $ORPHANS orphaned resources (missing attributes)"
fi

# 4. Checksum validation (if using S3 versioning)
echo "Checking digest integrity..."
STORED_DIGEST=$(jq -r '.terraform_version' "$STATE_FILE")
if [ -z "$STORED_DIGEST" ]; then
  echo "✗ Missing terraform_version field"
  exit 1
fi

echo "✓ State validation passed"
```

**Recovery Steps**:

```bash
#!/bin/bash
# recover_corrupted_state.sh

STATE_BUCKET="terraform-state"
STATE_KEY="prod/terraform.tfstate"

echo "=== Recovering Corrupted State ==="
echo

# 1. Find most recent good backup
echo "[Step 1] Finding valid backup versions..."
aws s3api list-object-versions \
  --bucket $STATE_BUCKET \
  --prefix $STATE_KEY \
  --output table

read -p "Enter version ID to restore: " VERSION_ID

# 2. Download backup
echo "[Step 2] Downloading version $VERSION_ID..."
aws s3api get-object \
  --bucket $STATE_BUCKET \
  --key $STATE_KEY \
  --version-id $VERSION_ID \
  terraform.tfstate.candidate

# 3. Validate backup
echo "[Step 3] Validating backup..."
if ! jq empty terraform.tfstate.candidate 2>/dev/null; then
  echo "✗ Backup is also corrupted!"
  exit 1
fi

echo "✓ Backup valid"

# 4. Reconcile with AWS
echo "[Step 4] Checking if state matches AWS..."
RESOURCES_IN_STATE=$(jq '[.resources[] | .name] | unique | length' terraform.tfstate.candidate)
echo "  Resources in state: $RESOURCES_IN_STATE"

# Query actual AWS resources
RESOURCES_IN_AWS=$(aws ec2 describe-instances \
  --filters "Name=tag:ManagedBy,Values=terraform" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | wc -w)
echo "  Resources in AWS: $RESOURCES_IN_AWS"

if [ $RESOURCES_IN_STATE -ne $RESOURCES_IN_AWS ]; then
  echo "✗ Mismatch! Manual reconciliation needed"
  echo "  Compare both lists carefully"
  exit 1
fi

# 5. Apply backup
echo "[Step 5] Applying recovered state..."
terraform state push terraform.tfstate.candidate

echo "✓ State restored"

# 6. Verify
echo "[Step 6] Running plan to verify..."
terraform plan -out=verify.tfplan

CHANGES=$(terraform show verify.tfplan | grep -c '^aws_')
echo "  Plan shows $CHANGES changes"
echo
echo "Review plan carefully!"
read -p "Apply this plan? (YES/no): " CONFIRM

if [ "$CONFIRM" = "YES" ]; then
  terraform apply verify.tfplan
  echo "✓ Recovery complete"
else
  echo "Aborted"
fi
```



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

## Summary: Mastering Terraform Architecture Basics

This comprehensive study guide has covered the core architectural principles that enable Terraform to safely orchestrate infrastructure across cloud environments at scale.

### Key Takeaways by Section

**Providers and Resources**: Terraform abstracts cloud complexity through plugin-based providers and declarative resource definitions, enabling multi-cloud deployments with unified syntax.

**Data Sources**: Query and reference existing infrastructure without modifying it—enabling bridging between IaC and manually-provisioned resources, and cross-module coordination.

**State Management**: Terraform's state file is the single source of truth mapping logical resource names to physical IDs. Protect it with encryption, versioning, access controls, and distributed locking for production systems.

**Dependency Graph and Execution Plan**: Terraform automatically discovers and topologically sorts dependencies, parallelizing independent resources while respecting critical ordering constraints.

**Hands-on Scenarios**: Real-world recovery procedures demonstrate how architectural understanding translates to operational resilience during incidents.

### Reading Recommendations

**For Quick Refreshers**:
- Review ASCII diagrams in each section
- Read only the "Internal Working Mechanism" subsections
- Scan the "Common Pitfalls" for each topic

**For Deep Understanding**:
- Work through all "Practical Code Examples"
- Run the scripts in your test environment
- Modify examples to experiment with architecture

**For Interview Preparation**:
- Study the "Interview Questions" section thoroughly
- Practice explaining architecture concepts without reading from notes
- Be ready to discuss trade-offs (complexity vs. flexibility, etc.)

### Related Study Materials

Continue your mastery with:
1. [Terraform CLI Workflow](3_Terraform_CLI_Workflow_StudyGuide.md) - Operational commands and workflows
2. [Terraform State Management](4_Terraform_State_Management_StudyGuide.md) - Advanced state strategies
3. [Terraform Variables and Outputs](5_Terraform_Variables_Outputs_Provisioning_Lifecycle_Dependency_StudyGuide.md) - Input/output design patterns
4. [Terraform Modules](6_Terraform_Modules_and_Reusability_StudyGuide.md) - Large-scale code reuse
5. [Terraform Testing](7_Terraform_Debugging_Drift_Detection_Testing_StudyGuide.md) - Quality assurance

---

**Study Guide Version**: 3.0  
**Last Updated**: March 2026  
**Target Audience**: Senior DevOps Engineers (5-10+ years experience)  
**Estimated Study Time**: 8-12 hours  
**Hands-on Practice Time**: 4-6 hours

---

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

**Study Guide Complete**: 8000+ lines covering Terraform Architecture Basics from foundational concepts through advanced production patterns, disaster recovery procedures, and interview preparation. Designed for Senior DevOps Engineers with 5-10+ years experience.

This guide provides:
✓ Comprehensive architectural understanding
✓ Real-world production patterns
✓ Disaster recovery procedures
✓ Interview preparation material
✓ Practical code examples
✓ Common pitfalls and solutions

**Next Steps**: 
1. Practice all code examples in your test environment
2. Review all scenarios with your team
3. Update your incident response playbooks based on learned procedures
4. Continue to advanced topics (Modules, State Management Strategies, Testing)

