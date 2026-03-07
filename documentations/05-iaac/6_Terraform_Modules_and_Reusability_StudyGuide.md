# Terraform Modules and Reusability: Senior DevOps Study Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Terraform Modules - Module Structure](#terraform-modules---module-structure)
4. [Input Variables in Modules](#input-variables-in-modules)
5. [Module Outputs](#module-outputs)
6. [Module Versioning](#module-versioning)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)
9. [Advanced Module Patterns](#advanced-module-patterns-and-meta-arguments)
10. [Module State Management](#module-state-management-and-isolation)
11. [Module Testing](#module-testing-and-validation)
12. [Module Security](#module-security-and-best-practices)
13. [Performance Optimization](#module-performance-optimization-and-advanced-patterns)

---

## Introduction

### Overview of Topic

Terraform modules are the fundamental building blocks for infrastructure code organization, enablement of code reusability, and establishment of standardized infrastructure patterns across organizations. At the senior level, mastering modules means understanding not just syntax, but architectural patterns that scale across multi-team environments, cloud migrations, and complex infrastructure ecosystems.

Modules represent the DRY (Don't Repeat Yourself) principle applied to Infrastructure as Code. They encapsulate infrastructure logic, enforce consistency, reduce maintenance burden, and enable teams to work autonomously while maintaining organizational standards.

### Real-World Production Use Cases

**1. Multi-Environment Deployments**
- Same module code deployed across dev, staging, and production with different variable values
- Example: VPC module configured with environment-specific CIDR blocks, availability zones, and NAT gateway strategies
- Organization: Reduces code duplication by 60-70% when managing identical infrastructure across environments

**2. Organizational Standardization**
- Central platform engineering teams publish standardized modules (e.g., "approved-vpc", "secure-eks-cluster", "compliance-rds")
- Local teams consume these modules, ensuring security policies, tagging strategies, and operational patterns are consistent
- Example: A financial services firm maintains a centralized module for RDS instances that includes required backup policies, encryption, monitoring, and IAM roles

**3. SaaS Multi-Tenancy Infrastructure**
- Multi-tenant SaaS platforms use modules to provision isolated infrastructure per customer
- Modules handle tenant-specific configuration: sizing, pricing tier mapping, data residency requirements
- Example: A SaaS company deploys customer-specific Kubernetes clusters, databases, and VPCs using parameterized modules

**4. Infrastructure Marketplace / Internal Platforms**
- Organizations publish internal module marketplaces consumed by hundreds of developers
- Teams self-serve infrastructure provisioning through modules without deep Terraform knowledge
- Example: "Create a web application" = orchestrating compute, database, cache, monitoring modules automatically

**5. Disaster Recovery and Cross-Region Replication**
- Same module deployed identically across regions for DR scenarios
- Variables control regional specifics while core infrastructure remains identical
- Example: Active-active multi-region setup for critical services

### Where It Typically Appears in Cloud Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Organization                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Central Platform Team (Publishes Modules)             │ │
│  │  - vpc.module  │ database.module  │ compute.module     │ │
│  └────────────────────────────────────────────────────────┘ │
│           ▲               ▲                 ▲               │
│           │               │                 │               │
│  ┌────────┴──────┐ ┌──────┴────────┐ ┌──────┴────────┐      │
│  │  Team A       │ │  Team B       │ │  Team C       │      │
│  │ (Consumes)    │ │ (Consumes)    │ │ (Consumes)    │      │
│  └───────────────┘ └───────────────┘ └───────────────┘      │
│                                                             │
│  Development  ─ Staging  ─ Production (Organized by Module) │
└─────────────────────────────────────────────────────────────┘
```

Modules appear at the intersection of:
- **Code reusability and organizational governance** (everyone uses approved modules)
- **Scale and consistency** (same patterns across hundreds of resources)
- **Team autonomy and guardrails** (developers provision infrastructure safely)
- **Cost optimization** (standardized sizing and policies)

---

## Foundational Concepts

### Architecture Fundamentals

#### Module Architecture Patterns

**1. Single Responsibility Principle**
Modules should encapsulate a single logical unit of infrastructure:
- ✅ Good: `vpc.module` (creates VPC, subnets, route tables, NAT)
- ✅ Good: `security-group.module` (creates security groups with inbound/outbound rules)
- ❌ Bad: `entire-application.module` (mixes networking, compute, database, monitoring)

This improves testability, reusability, and maintenance. A module that does one thing well can be composed into larger architectures.

**2. Composition Over Deep Nesting**
- Level 1: Root modules (your deployment code)
- Level 2: Leaf modules (atomic building blocks like VPC, RDS)
- Level 3 (rarely): Composite modules that orchestrate leaf modules

```
Root Configuration
├── Module A (VPC)
├── Module B (EKS Cluster)
│   └── Depends on Module A for network_id
└── Module C (RDS)
    └── Depends on Module A for security_group_id
```

Deep nesting (modules calling modules calling modules) creates complexity without benefit.

**3. Interface vs. Implementation**
- **Interface**: Variables (inputs) and outputs—what others see
- **Implementation**: Resource declarations—internal details

A well-designed module hides complexity behind a simple interface:
```
Input: desired_node_count, instance_type, environment
Output: cluster_endpoint, cluster_security_group_id
Hidden: 47 resources, networking configuration, IAM roles
```

#### Dependency Management

**Explicit vs. Implicit Dependencies**
- Explicit: `vpc_id = module.vpc.vpc_id` (clear, testable)
- Implicit: Terraform discovers through resource references

Senior engineers understand that explicit dependencies in module outputs make systems more maintainable.

**Circular Dependencies**
- Modules cannot have circular dependencies (A → B → A)
- Advanced pattern: Use data sources to reference infrastructure created outside the module
- Example: RDS module that looks up VPC by tag instead of requiring it as input

#### State and Module Isolation

Modules share the same Terraform state file (when used within the same root module), but represent independently destructible units:
- You can `terraform destroy` a single module's resources
- Shared state means resource references are cheap (no data source lookups needed)
- Trade-off: Tightly coupled state management

### Important DevOps Principles

#### 1. Infrastructure as Code Philosophy Applied to Modules

**Version Control Everything**
- Module source code and versions must be in version control
- Modules published to registries are like library versions—they're immutable
- Treating modules like versioned APIs enables safe adoption of improvements

**Reproducibility**
- Anyone with the module and correct variables should get identical infrastructure
- Reduces "works on my machine" problems in infrastructure
- Critical for disaster recovery and regional replication

#### 2. The Principle of Least Surprise

Senior teams design modules so downstream users are never surprised:

❌ Module that silently creates a NAT gateway (expensive) when you expected just private subnets
✅ Module that requires explicit `enable_nat_gateway = true` with documentation on cost implications

❌ Module that requires 23 input variables with unclear defaults
✅ Module with sensible defaults and clear documentation on what each variable controls

#### 3. Separation of Concerns

**Module responsibility**: What infrastructure to create
**Calling code responsibility**: How much of it (parameterization)

A VPC module should not enforce "you must use this CIDR block" but should allow customization while maintaining standards.

#### 4. Idempotency and Safety

Modules must be safe to reapply:
- Running `terraform apply` twice with same variables must be safe
- Avoid `count` and `for_each` logic that changes between runs
- Use computed values and data sources appropriately

#### 5. Observability Built-In

Senior modules export sufficient outputs for monitoring and troubleshooting:
```
Outputs:
- resource_ids (for monitoring)
- security_group_ids (for audit)
- endpoint_urls (for applications)
- configuration_summary (for debugging)
```

### Best Practices

#### 1. Module Naming and Versioning

**Naming Convention**: `[provider-]resource-type[-variant]`

Examples:
- `aws-vpc` (basic VPC module)
- `aws-vpc-3tier` (VPC variant with 3 tier subnets)
- `google-gke-cluster` (GCP variant)

**Versioning Strategy**:
- Semantic versioning (v1.2.3): MAJOR.MINOR.PATCH
- MAJOR: Breaking changes to input variables or outputs
- MINOR: New functionality, new optional variables, new outputs
- PATCH: Bug fixes, internal optimizations

#### 2. Input Variable Design

**Good Practices**:
```hcl
# Clear naming
variable "instance_count" { }  # ✅
variable "count" { }          # ❌ Too generic

# Type constraints
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Sensible defaults
variable "enable_monitoring" {
  type    = bool
  default = true  # Safer default
}

# Clear descriptions for downstream users
variable "node_count" {
  type        = number
  description = "Number of worker nodes. Minimum 2 for HA, recommended 3+ for production."
}
```

**Anti-patterns**:
- ❌ Required variables with no defaults that change per environment (use `terraform.tfvars`)
- ❌ Overly sensitive defaults (e.g., `enable_backup = false`)
- ❌ Variables that don't validate input (should catch errors early, not at apply time)

#### 3. Output Strategy

Export only what callers need:
```hcl
output "cluster_id" {
  value       = aws_eks_cluster.main.id
  description = "EKS cluster identifier"
}

output "api_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS API server endpoint URL"
}

# Don't export everything, but do export enough for troubleshooting
output "cluster_status" {
  value       = aws_eks_cluster.main.status
  description = "Current cluster status (CREATING, ACTIVE, DELETING)"
}
```

#### 4. Documentation

Each module should include:
- **README.md**: Purpose, example usage, variable descriptions, output descriptions
- **Inline comments**: Why decisions were made (not what code does)
- **Examples**: Working configurations showing typical usage

#### 5. State Management

For published modules:
- Keep modules stateless (they work within root module's state)
- Avoid dependencies between modules that create ordering issues
- Use `depends_on` explicitly when needed

#### 6. Testing Modules

- Use `terraform validate` and `terraform plan`
- Use `terraform test` (Terraform 1.6+) for module-level testing
- Test variable validation with invalid inputs
- Test against multiple Terraform versions

### Common Misunderstandings

#### Misunderstanding #1: Modules are like Functions
**❌ Wrong**: "Modules are just functions that group resources"

**✅ Correct**: Modules are interfaces to infrastructure components. They carry state implications, have deployment ordering, and represent real resource lifecycle management.

**Why it matters**: This misunderstanding leads to modules that are too granular (single resource modules) or too complex (modules that do everything). Functions are free to call; modules have real infrastructure cost and operational implications.

#### Misunderstanding #2: Module Outputs are "Return Values"
**❌ Wrong**: "Module output is like a function return value—use it however you want"

**✅ Correct**: Module outputs represent the contract with downstream infrastructure. Changing an output is a breaking change for consumers.

**Why it matters**: Backward compatibility of modules is critical. If you remove an output, all consumers break. Outputs should be stable and well-designed.

#### Misunderstanding #3: Modules are for Code Reuse Only
**❌ Wrong**: "Modules are just to avoid copy-paste"

**✅ Correct**: Modules primarily serve three purposes:
1. **Encapsulation**: Hide infrastructure complexity
2. **Standardization**: Enforce organizational patterns
3. **Governance**: Central teams control how production infrastructure is built

**Why it matters**: This changes how you design modules. A module for standardization will look different than one just for code reuse. It will include validation, security checks, and enforced patterns.

#### Misunderstanding #4: All Module Versions Should Be Backward Compatible
**❌ Wrong**: "Never make breaking changes to modules"

**✅ Correct**: Breaking changes are acceptable with major version bumps. However, breaking changes should be infrequent and necessary.

**Why it matters**: Teams that never break compatibility create technical debt. MAJOR version bumps signal to consumers "review and test before upgrading." This is expected and healthy.

#### Misunderstanding #5: Modules Should Handle All Configuration
**❌ Wrong**: "The module should support every possible use case through variables"

**✅ Correct**: Modules encode opinionated defaults. Power users can fork or create variants for special cases.

**Why it matters**: Covering every use case creates bloated modules with 50+ variables. Decide what your module optimizes for (security? cost? simplicity?) and build around that.

#### Misunderstanding #6: More Abstraction = Better
**❌ Wrong**: "Create meta-modules that combine multiple modules automatically"

**✅ Correct**: Composition should be explicit in root configuration. Downstream users should see what infrastructure they're getting.

**Why it matters**: Magic abstractions become maintenance burdens. Explicitly composing modules in root configuration makes infrastructure visible and easy to troubleshoot.

---

## Terraform Modules - Module Structure

### Directory Layout and Organization

#### Standard Module Structure

```
module/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output value declarations
├── versions.tf          # Version constraints (Terraform, providers)
├── locals.tf            # Local values (optional)
├── terraform.tfvars     # Variable values (root modules only)
├── README.md            # Documentation
├── examples/            # Example configurations
│   ├── basic/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── advanced/
│       ├── main.tf
│       └── terraform.tfvars
├── tests/               # Test configurations (Terraform 1.6+)
│   └── module_test.tftest.hcl
└── .gitignore
```

**Enterprise Module Repository Structure**

```
terraform-modules/
├── aws/
│   ├── vpc/
│   │   ├── v2.5.0/
│   │   ├── v2.4.3/
│   │   └── v2.4.2/
│   ├── eks/
│   ├── rds/
│   └── security-group/
├── google/
├── azure/
├── shared/
│   └── monitoring/
├── CHANGELOG.md
└── VERSION
```

### File Organization Best Practices

#### 1. main.tf
Contains resource declarations for the core infrastructure:
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true

  tags = merge(
    var.tags,
    { Name = var.vpc_name }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = var.tags
}
```

**Keep main.tf focused**: Don't mix security group, IAM, and networking resources in one file. Either split into multiple files or keep logically related resources together.

#### 2. variables.tf
All input variable declarations:
```hcl
variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)"
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
```

#### 3. outputs.tf
All output declarations:
```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the created VPC"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the VPC"
}
```

#### 4. versions.tf
Version constraints:
```hcl
terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

#### 5. locals.tf (When Needed)
Computed values used within the module:
```hcl
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  subnet_configurations = [
    for i, az in local.azs : {
      cidr      = cidrsubnet(var.cidr_block, 2, i)
      az        = az
      tier      = "public"
    }
  ]
}
```

### Module Source Types and Registry Integration

#### Local Modules
Used during development or for organization-specific infrastructure:
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  cidr_block = "10.0.0.0/16"
}
```

**Pros**: Full control, no external dependencies, instant iteration
**Cons**: No versioning, harder to share across teams/organizations

#### Terraform Registry
HashiCorp's public registry for community and verified modules:
```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  
  cluster_name = "production"
}
```

**Pros**: Versioning, semantic versioning constraints, community-maintained
**Cons**: Dependency on external registry, potential breaking changes

#### Git Source
Direct from version control:
```hcl
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//aws/vpc?ref=v2.5.0"
  
  cidr_block = "10.0.0.0/16"
}
```

**Pros**: Private modules, full version control, organization standards
**Cons**: Requires Git access, more setup overhead

#### Private Registry (Terraform Cloud/Enterprise)
Enterprise teams use private registries:
```hcl
module "vpc" {
  source  = "app.terraform.io/company-name/vpc/aws"
  version = "~> 3.0"
}
```

**Pros**: Access controls, versioning, enterprise features, policy enforcement
**Cons**: Requires TFC/TFE subscription

### Module Dependency and Resource Lifecycle

#### Explicit Dependencies
Some dependencies are automatically inferred by Terraform, but explicit `depends_on` clarifies intent:

```hcl
module "eks_cluster" {
  source = "./modules/eks"
  
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  
  depends_on = [
    aws_iam_role_policy.eks_service_role
  ]
}
```

**When to use**: When infrastructure must be created in a specific order that Terraform doesn't infer automatically

#### Resource Lifecycle Within Modules

Modules respect Terraform's resource lifecycle:
- **Create**: When variable values lead to new resources
- **Update**: When variable values change (may require resource replacement)
- **Destroy**: When resources are removed or module is destroyed

**Advanced pattern**: Use `create_before_destroy` lifecycle for zero-downtime updates:

```hcl
resource "aws_launch_template" "app" {
  # ... configuration
  
  lifecycle {
    create_before_destroy = true
  }
}
```

### Module Count and For_Each Patterns

#### Using count for Multiple Module Instances

```hcl
module "vpc" {
  for_each = toset(["us-east-1", "eu-west-1"])
  
  source = "./modules/vpc"
  
  region    = each.value
  cidr_block = "10.${index(["us-east-1", "eu-west-1"], each.value)}.0.0/16"
}

# Reference specific instance
output "us_east_vpc_id" {
  value = module.vpc["us-east-1"].vpc_id
}
```

**Best Practice**: Use `for_each` with maps for multi-region/multi-account deployments. Provides stable state and clearer references than numeric count.

---

## Input Variables in Modules

### Variable Design Principles

#### Type Declaration Best Practices

**1. Explicit Types**
```hcl
# ✅ Good: Type is explicit
variable "environment" {
  type = string
}

# ❌ Bad: Type is inferred (less safe)
variable "environment" {
}
```

**2. Complex Types for Flexibility**
```hcl
variable "subnet_config" {
  type = list(object({
    cidr_block        = string
    availability_zone = string
    tier             = string
  }))
  
  description = "Configuration for each subnet"
}
```

**3. Map Types for Key-Value Configurations**
```hcl
variable "resource_tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
```

#### Default Values and Sensibility

**Safety-First Defaults**:
```hcl
# ✅ Defaults to safer option
variable "enable_encryption" {
  type    = bool
  default = true  # Encrypted is safer
}

variable "instance_type" {
  type    = string
  default = "t3.medium"  # Conservative sizing
}

# ❌ Defaults to riskier option
variable "enable_encryption" {
  type    = bool
  default = false  # Unencrypted!
}

variable "enable_backup" {
  type    = bool
  default = false  # No backups!
}
```

#### Nullable Variables

For optional configurations:
```hcl
variable "custom_dns_servers" {
  type        = list(string)
  default     = null
  nullable    = true
  description = "Custom DNS servers. If null, use AWS defaults."
}

# In resource definition, check for null:
resource "aws_vpc_dhcp_options" "custom" {
  count = var.custom_dns_servers != null ? 1 : 0
  
  domain_name_servers = var.custom_dns_servers
}
```

### Input Validation

#### Basic Validation

```hcl
variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}
```

#### Complex Validation with Custom Logic

```hcl
variable "node_count" {
  type = number
  
  validation {
    condition     = var.node_count >= 2 && var.node_count <= 100
    error_message = "Node count must be between 2 and 100"
  }
}

variable "cost_limit_monthly" {
  type = number
  
  validation {
    condition     = var.cost_limit_monthly > 0
    error_message = "Monthly cost limit must be positive"
  }
}
```

#### Cross-Variable Validation

```hcl
variable "enable_multi_az" {
  type = bool
}

variable "instance_count" {
  type = number
  
  validation {
    condition = var.enable_multi_az ? var.instance_count >= 3 : var.instance_count >= 1
    error_message = "Multi-AZ deployments require at least 3 instances"
  }
}
```

#### CIDR Validation

```hcl
variable "cidr_block" {
  type = string
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR notation (e.g., 10.0.0.0/16)"
  }
}
```

### Variable Naming Conventions

#### Senior-Level Naming Strategy

```hcl
# ✅ Clear, hierarchical naming
variable "vpc_cidr_block"
variable "vpc_enable_dns_hostnames"

variable "eks_cluster_version"
variable "eks_node_desired_count"

variable "rds_engine"
variable "rds_backup_retention_days"

# ❌ Ambiguous or too generic
variable "cidr"              # Which CIDR?
variable "count"             # Count of what?
variable "enabled"           # What is enabled?
variable "cluster_version"   # Which cluster?
```

#### Hierarchical Naming for Parameterized Modules

```hcl
variable "subnet_configurations" {
  type = list(object({
    availability_zone = string
    cidr_block        = string
    tier              = string
  }))
}
# Keeps variable namespace clean and groups related config
```

---

## Module Outputs

### Output Strategy and Design

#### Principle: Export What Callers Need, Not Everything

```hcl
# ✅ Good: Essential outputs for downstream use
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC identifier"
}

output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "Private subnet identifiers for EC2 placement"
}

# ❌ Bad: Exports internal implementation details
output "aws_vpc_resource_object" {
  value = aws_vpc.main  # Exposes entire resource
}

output "internal_routing_tables" {
  value = aws_route_table.internal  # Consumers shouldn't know about these
}
```

#### Output Stability and Backward Compatibility

**Golden Rule**: Outputs are contracts with downstream code.
- Removing an output = breaking change (MAJOR version bump)
- Adding a new output = minor change (MINOR version bump)
- Changing output value type = breaking change (MAJOR version bump)

```hcl
# V1.0.0 - Initial release
output "cluster_id" {
  value = aws_eks_cluster.main.id
}

# V1.1.0 - Addition is safe
output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

# V2.0.0 - Type change requires major version
#❌ Don't do this in minor version:
output "cluster_id" {
  value = [aws_eks_cluster.main.id]  # Changed from string to list!
}
```

### Common Output Patterns

#### 1. Identity Outputs
Primary identifiers for resource orchestration:
```hcl
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC identifier"
}

output "security_group_ids" {
  value       = aws_security_group.main[*].id
  description = "Security group identifiers"
}

output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS instance endpoint"
}
```

#### 2. Reference Outputs
For downstream module dependencies:
```hcl
output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR block (used for peering)"
}

output "nat_gateway_ips" {
  value       = aws_eip.nat[*].public_ip
  description = "NAT gateway elastic IPs (for firewall rules)"
}
```

#### 3. Configuration Outputs
Useful operational information:
```hcl
output "cluster_status" {
  value       = aws_eks_cluster.main.status
  description = "Current cluster status (CREATING, ACTIVE, DELETING)"
}

output "instance_count" {
  value       = length(aws_instance.workers)
  description = "Number of compute nodes"
}
```

#### 4. Metadata Outputs
For debugging and troubleshooting:
```hcl
output "created_at" {
  value       = aws_eks_cluster.main.created_at
  description = "Cluster creation timestamp"
}

output "terraform_inputs" {
  value = {
    environment  = var.environment
    node_count   = var.eks_node_desired_count
    instance_type = var.eks_node_instance_type
  }
  description = "Reference of configuration inputs"
}
```

#### 5. Connection Details Outputs
For applications/monitoring to connect:
```hcl
output "database_connection_string" {
  value       = "postgresql://${aws_db_instance.main.username}:****@${aws_db_instance.main.endpoint}/dbname"
  description = "Database connection string (password redacted)"
  sensitive   = true
}

output "elasticache_endpoint" {
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
  description = "ElastiCache cluster endpoint"
}
```

### Sensitive Outputs

#### Protecting Sensitive Data

```hcl
output "rds_password" {
  value       = aws_db_instance.main.password
  sensitive   = true
  description = "RDS master password (sensitive)"
}

output "api_key" {
  value       = aws_secretsmanager_secret.api_key.name
  sensitive   = true
  description = "Secrets Manager secret name (retrieve separately)"
}
```

**When `sensitive = true`**:
- Output value is hidden in `terraform plan` and `terraform apply` output
- Value is still stored in state file (encrypted if configured)
- Best practice: Use AWS Secrets Manager, not Terraform outputs for secrets

#### Anti-Pattern: Secrets in Outputs
```hcl
# ❌ Never put actual secrets in outputs
output "database_password" {
  value = "supersecret123"  # WRONG!
}

# ✅ Instead, use secret management service
output "secret_manager_name" {
  value = aws_secretsmanager_secret.db_password.name
}
```

### Composite Outputs

#### Organizing Related Outputs

Option 1: Individual outputs (verbose but explicit):
```hcl
output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "nat_gateway_ids" { value = aws_nat_gateway.main[*].id }
```

Option 2: Composite output (organized but requires unpacking):
```hcl
output "vpc_configuration" {
  value = {
    vpc_id              = aws_vpc.main.id
    public_subnet_ids   = aws_subnet.public[*].id
    private_subnet_ids  = aws_subnet.private[*].id
    nat_gateway_ids     = aws_nat_gateway.main[*].id
  }
  description = "VPC configuration summary"
}
```

**Recommendation**: Lean toward individual outputs for primary outputs (what callers typically use), use composite for optional/related information.

---

## Module Versioning

### Semantic Versioning for Infrastructure Code

#### Version Format: MAJOR.MINOR.PATCH

**MAJOR Version**: Breaking changes
- Input variable removed or renamed
- Input variable type changed
- Output removed or renamed
- Output type changed
- Fundamental behavior change (e.g., "this module now requires TLS")

```hcl
# v1.0.0 to v2.0.0 (MAJOR)
variable "instance_type" {
  type = string  # Changed from nullable string
}
```

**MINOR Version**: Backward-compatible additions
- New optional input variable with default
- New output added
- New resource created (additive only)
- Performance improvements
- Dependency updates to higher minor/patch versions

```hcl
# v1.5.0 to v1.6.0 (MINOR)
variable "enable_monitoring" {
  type    = bool
  default = true  # New optional variable
}
```

**PATCH Version**: Bug fixes and improvements
- Typo fixes
- Documentation updates
- Parameter adjustments that don't change behavior
- Security patches

```hcl
# v1.5.0 to v1.5.1 (PATCH)
# Fixed: Security group rule now blocks SSH from internet
```

### Version Constraints

#### Specification in Module Configuration

```hcl
# Exact version (rarely used, too restrictive)
version = "2.3.1"

# Tilde constraint (allows patch changes)
version = "~> 2.3"    # Allows 2.3.0, 2.3.1, 2.3.9 but NOT 2.4.0

# Caret constraint (allows minor and patch changes)
version = ">= 2.3.0, < 3.0.0"  # Allows 2.3.x and 2.y.x

# Greater than or equal (least restrictive, test before using)
version = ">= 2.0"

# Range (conservative approach)
version = ">= 2.0, < 2.5"
```

#### Version Strategy by Environment

```hcl
# Development - Allow latest for testing new features
version = ">= 2.0"

# Staging - Allow minor versions
version = "~> 2.3"

# Production - Pin to well-tested version
version = "~> 2.3.0"
```

### Managing Multiple Module Versions

#### Parallel Version Support

Organizations often support multiple versions during transition periods:

```hcl
# Available versions in registry/repo:
# v1.9.5 - Legacy version, being sunset
# v2.0.0 - Current recommended version
# v2.1.0 - New with advanced features
```

**Upgrade Path**:
```hcl
# Period 1: Default everyone to v2.0, allow opt-in to v2.1
# Period 2: Default everyone to v2.1, accept v2.0 only if critical
# Period 3: Deprecate v2.0, mandatory upgrade to v2.1+
```

#### Breaking Change Migration

When MAJOR version requires changes:

```hcl
# Old module (v1.x)
module "vpc" {
  source = "./modules/vpc"
  version = "~> 1.9"
  
  vpc_name = "production"  # This input was renamed in v2.0
}

# New module (v2.x) - MAJOR change
module "vpc" {
  source = "./modules/vpc"
  version = "~> 2.0"
  
  name = "production"  # Input renamed from vpc_name to name
}
```

### Publishing and Updating Modules

#### Publishing to Terraform Registry

1. Push code to GitHub repository
2. Create semantic version tag (`git tag v2.3.1`)
3. HashiCorp automatically publishes when tag matches pattern `v*.*.*`

#### Changelog Management

Maintain **CHANGELOG.md** for every version:

```markdown
## [2.3.0] - 2025-03-15

### Added
- New variable `enable_advanced_monitoring` (optional, default `false`)
- New output `monitoring_dashboard_url`
- Support for Terraform 1.6+

### Changed
- Updated AWS provider version constraint to `>= 5.0`
- Improved performance of subnet calculations (no behavior change)

### Fixed
- Security group rule order now deterministic (resolved intermittent failures)

### Deprecated
- Variable `log_retention_days` deprecated, use `cloudwatch_log_retention_days`

### Breaking Changes
- Removed variable `legacy_mode` (use modern_mode instead)
```

---

## Hands-on Scenarios

### Scenario 1: Multi-Environment VPC Deployment with Modules

**Objective**: Deploy identical VPC infrastructure across dev, staging, and production environments with environment-specific configuration.

**Requirements**:
- VPC module published to registry or local source
- Each environment has distinct CIDR blocks and NAT strategy
- Production has multi-AZ setup, dev is single-AZ
- Common tagging strategy across environments

**Implementation**:

```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  
  tags = merge(
    var.tags,
    { "Name" = "${var.environment}-vpc" }
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_config)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_config[count.index].cidr_block
  availability_zone = var.public_subnet_config[count.index].az
  
  tags = merge(
    var.tags,
    { "Name" = "${var.environment}-public-${count.index + 1}" }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    { "Name" = "${var.environment}-igw" }
  )
}

# NAT gateway (for production multi-AZ, single EIP in dev)
resource "aws_nat_gateway" "main" {
  count         = var.nat_gateway_count
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat[count.index].id
  
  depends_on = [aws_internet_gateway.main]
  
  tags = merge(
    var.tags,
    { "Name" = "${var.environment}-nat-${count.index + 1}" }
  )
}
```

```hcl
# modules/vpc/variables.tf
variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be: dev, staging, or prod"
  }
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for VPC"
  
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be valid CIDR notation"
  }
}

variable "public_subnet_config" {
  type = list(object({
    cidr_block = string
    az         = string
  }))
  description = "Public subnet configurations per AZ"
}

variable "nat_gateway_count" {
  type        = number
  description = "Number of NAT gateways to create"
  default     = 1
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
```

```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC identifier"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "nat_gateway_eips" {
  value       = aws_eip.nat[*].public_ip
  description = "NAT gateway public IPs"
}
```

```hcl
# environments/dev/main.tf
module "vpc" {
  source  = "../../modules/vpc"  # or terraform-aws-modules/vpc/aws
  version = "~> 2.0"
  
  environment = "dev"
  cidr_block  = "10.1.0.0/16"
  
  public_subnet_config = [
    {
      cidr_block = "10.1.1.0/24"
      az         = "us-east-1a"
    }
  ]
  
  nat_gateway_count = 1
  
  tags = {
    "Environment" : "dev"
    "CostCenter" : "engineering"
    "ManagedBy" : "Terraform"
  }
}
```

```hcl
# environments/prod/main.tf
module "vpc" {
  source  = "../../modules/vpc"
  version = "~> 2.0"
  
  environment = "prod"
  cidr_block  = "10.0.0.0/16"
  
  public_subnet_config = [
    {
      cidr_block = "10.0.1.0/24"
      az         = "us-east-1a"
    },
    {
      cidr_block = "10.0.2.0/24"
      az         = "us-east-1b"
    },
    {
      cidr_block = "10.0.3.0/24"
      az         = "us-east-1c"
    }
  ]
  
  nat_gateway_count = 3  # One per AZ for HA
  
  tags = {
    "Environment" : "prod"
    "CostCenter" : "operations"
    "ManagedBy" : "Terraform"
    "Compliance" : "required"
  }
}
```

**Lessons**:
- Module encapsulates infrastructure complexity (internal resources, IAM, routing)
- Environment-specific values passed via variables
- Same module code deploys identically, reducing bugs
- Easy to add new environments by copying environment folder

---

### Scenario 2: Module Composition - EKS Cluster Depending on VPC Module

**Objective**: Create an EKS cluster that depends on VPC created by separate module.

```hcl
# modules/eks/main.tf
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.eks_service_role.arn
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = var.expose_api_publicly
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.eks_service_role_policy
  ]
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  version         = var.kubernetes_version
  
  subnet_ids = var.subnet_ids
  
  scaling_config {
    desired_size = var.worker_desired_count
    max_size     = var.worker_max_count
    min_size     = var.worker_min_count
  }
}
```

```hcl
# modules/eks/variables.tf
variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = "1.28"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for cluster placement"
}

variable "expose_api_publicly" {
  type        = bool
  description = "Expose Kubernetes API publicly"
  default     = false  # Better default: private
}

variable "worker_desired_count" {
  type        = number
  default     = 3
}

variable "worker_max_count" {
  type        = number
  default     = 10
}

variable "worker_min_count" {
  type        = number
  default     = 2
}
```

```hcl
# Composition in root module
module "vpc" {
  source = "../../modules/vpc"
  
  environment         = var.environment
  cidr_block          = var.vpc_cidr_block
  public_subnet_config = var.subnet_config
}

module "eks" {
  source = "../../modules/eks"
  
  cluster_name = var.cluster_name
  
  # Pass VPC module output to EKS module
  subnet_ids = module.vpc.public_subnet_ids
  
  worker_desired_count = var.worker_count
  expose_api_publicly  = var.environment != "prod"
}
```

**Lessons**:
- Modules compose through outputs → inputs
- Module dependencies are explicit (vpc output feeds eks input)
- Root configuration orchestrates module interaction
- Easy to visualize infrastructure: `vpc → eks`

---

### Scenario 3: Testing Module Input Validation

**Objective**: Verify variable validation catches errors early.

```hcl
# test input validation
terraform plan \
  -var="environment=invalid" \
  -var="cidr_block=not-a-cidr"

# Expected output:
# Error: Invalid value for variable "environment":
#   on modules/vpc/variables.tf line 1:
#   1: variable "environment" {
#
# Environment must be: dev, staging, or prod

# Error: Invalid value for variable "cidr_block":
#   on modules/vpc/variables.tf line 10:
#   10: variable "cidr_block" {
#
# Must be valid CIDR notation
```

---

## Interview Questions

### Question 1: When should you create a module vs. inline resources?

**Levels**:
- **Entry**: "When you need to reuse code"
- **Mid**: "When infrastructure repeats, or when you want to encapsulate complexity"
- **Senior**: "Modules serve three purposes: encapsulation (hide complexity), reusability (same code, different values), and governance (enforce standards). Create a module when any of these benefits justify the abstraction overhead. Ask: 'Would this module be simpler to use than the raw resources?' If the answer is no, don't create it."

**Follow-up**: What's an example of a module that improves encapsulation even if never reused?

**Strong answer**: "A security-group module that encapsulates common security patterns—ingress/egress, CIDRs, descriptions. Downstream users don't need to know about security group rules; they just provide 'allow HTTP', 'allow database access', and the module handles the AWS complexity."

---

### Question 2: You're designing a VPC module. What outputs should you provide?

**Entry**: "VPC ID, subnet IDs"

**Mid**: "VPC ID, public/private subnet IDs, NAT gateway IPs, routing table IDs"

**Senior**: "Focus on what downstream infrastructure needs:
- **Identity outputs**: VPC ID (for peering), subnet IDs (for placement), security group IDs (for rules)
- **Connection outputs**: NAT gateway IPs (for network policies), VPN endpoint (for access)
- **Metadata**: CIDR block (for VPN configuration), AZ list (for multi-AZ planning)

Don't export: resource counts, internal routing table IDs, NAT gateway resource objects.

The test: 'Could someone build infrastructure on top of this VPC with only these outputs?' If yes, you're exporting enough."

---

### Question 3: You're publishing a module to a registry. A user wants support for a use case not in your design. Should you add the variable?

**Entry**: "It depends on how many people need it"

**Mid**: "Add optional variables with defaults that don't break existing users"

**Senior**: "Understand that every variable creates maintenance debt. Before adding, ask:
1. Is this a one-off use case or broad pattern?
2. Can the user fork/customize locally?
3. Does this variable increase complexity (more docs, more validation, more edge cases)?

Better approach: 'This is a specialized use case. Our module optimizes for the 80% standard case. I recommend creating a specialized variant (vpc-security-focused, vpc-cost-optimized) rather than bloating the core module. This keeps the core simple, provides choice, and separates concerns.'

A bloated module with 40 variables is harder to maintain than two focused modules."

---

### Question 4: How do you version a module that's used by hundreds of internal teams?

**Entry**: "Use semantic versioning"

**Mid**: "Use semantic versioning. Breaking changes require major version bumps. Provide upgrade documentation."

**Senior**: "Semantic versioning is table stakes. Real challenges:
1. **Deprecation strategy**: Don't break suddenly. Deprecate in minor versions (v1.5: 'this variable will be removed in v2.0'), support for one major cycle, then break in next major.
2. **Communication**: Breaking changes need advance notice through changelogs, team announcements, migration guides.
3. **Compatibility window**: Support 2-3 major versions simultaneously during transition.
4. **Testing before rollout**: Teams should test new majors in non-prod before production adoption.

Example schedule:
- v1.5: Deprecate `database_password` variable (announce: will be removed in v3.0)
- v1.6-v2.9: Both variables work (backward compat)
- v3.0: Remove `database_password` (breaking change, major version)

This prevents sudden breakage while allowing organized migration."

---

### Question 5: A module works 90% of the time, but 10% edge case needs different logic. How do you handle it?

**Entry**: "Add a flag variable to branch logic"

**Mid**: "Add conditional variables/flags. But keep logic understandable—don't let the module become a state machine."

**Senior**: "This is where design matters:
1. **If the edge case is small**: Add optional variable with clear documentation. Increase test coverage for the edge case.
2. **If the edge case is significant**: Create a specialized module variant. Example: `vpc.module` (standard) and `vpc-transit-gateway.module` (for transit gateway use case).
3. **Never**: Build a 'god module' that handles all cases through flags. The module becomes a state machine harder to test, debug, and reason about.

Test mentality: 'Am I testing business logic, or module logic?' If you're testing the module handles 10 different flag combinations, you've crossed into god-module territory. Better to split.

Real-world example: Stripe has simple payment processing 95% of the time, but special cases (subscription credits, disputes, reversals) are complex enough to deserve separate APIs. Same principle applies to modules."

---

### Question 6: How do you handle secrets (database passwords, API keys) in modules?

**Entry**: "Don't put secrets in Terraform outputs; use Secrets Manager"

**Mid**: "Don't hardcode secrets. Use variable references or data sources to retrieve secrets from vault/Secrets Manager."

**Senior**: "Infrastructure-as-code shouldn't manage application secrets. Module should know '*where* secrets are' (Secrets Manager secret name), not 'what the secrets are'.

Pattern:
```hcl
# ✅ Good: Module creates infrastructure, references external secret
resource \"aws_db_instance\" \"main\" {
  password           = var.db_master_password_secret_name  # Reference only
  # ...
}

# Application retrieves the actual secret from Secrets Manager at runtime

# ✅ Alternative: Module creates secret, returns name
resource \"aws_secretsmanager_secret\" \"db_password\" {
  name_prefix = \"${var.environment}/db/\"
}

output \"db_password_secret_name\" {
  value = aws_secretsmanager_secret.db_password.name
}

# Application retrieves from secret by name
```

Rationale: Terraform state is stored on disk, backups created, logs generated. Secrets in state is a compliance liability. Service that generates/manages secrets should be external to IaC."

---

### Question 7: Design a module that works across AWS, GCP, and Azure (multi-cloud).

**Entry**: "You can't; Terraform is provider-specific"

**Mid**: "You'd need separate modules per cloud. Use a wrapper/factory pattern to switch."

**Senior**: "There are three patterns:

1. **Separate modules per cloud** (most common):
   ```hcl
   module \"vpc_aws\" {
     count   = var.cloud_provider == \"aws\" ? 1 : 0
     source  = \"./modules/vpc-aws\"
   }
   
   module \"vpc_gcp\" {
     count   = var.cloud_provider == \"gcp\" ? 1 : 0
     source  = \"./modules/vpc-gcp\"
   }
   
   # Caller doesn't care, gets same outputs
   ```

2. **Cloud abstraction layer** (intermediate complexity):
   Create a custom provider/module in Terraform Cloud that abstracts cloud differences:
   ```hcl
   module \"network\" {
     source = \"app.terraform.io/company/network/cloud\"
     
     cloud_provider = var.cloud
     cidr_block     = var.cidr
     # Module switches internally based on cloud_provider
   }
   ```

3. **Avoid multi-cloud modules** (usually wrong):
   Don't try to write logic that works universally. Clouds differ in fundamentals (VPC vs VNet, security groups vs NSGs, availability zones vs regions).

Real world: Most organizations use pattern #1 (separate modules) or run separate Terraform for each cloud. Multi-cloud abstraction becomes a maintenance burden that rarely provides enough benefit."

---

### Question 8: A colleague created a module with 40+ required variables with no defaults. How do you review this?

**Entry**: "That's too many variables"

**Mid**: "Tell them to add defaults for optional settings, group related variables"

**Senior**: "This requires a design conversation, not just variable count. Questions to ask:

1. **Is the module doing too much?** 40 variables often means 'this module handles 10 different use cases.' Solution: Split into smaller, focused modules.

2. **Are variables obscuring a pattern?** If 30 variables always used together, they should be a single `object` variable:
   ```hcl
   # Before: 30 individual variables
   variable \"database_engine\"
   variable \"database_version\"
   variable \"database_port\"
   # ... 27 more
   
   # After: One structured variable
   variable \"database_config\" {
     type = object({
       engine  = string
       version = string
       port    = number
       # ...
     })
   }
   ```

3. **Are defaults missing?** Most variables should have sensible defaults:
   ```hcl
   # After refactor: Only truly required inputs stay un-defaulted
   variable \"environment\" {
     type = string
     # No default—this must be provided
   }
   
   variable \"enable_monitoring\" {
     type    = bool
     default = true  # Sensible default
   }
   ```

End state: Module with 5-10 required variables (the 'what'), 10-15 optional variables with defaults (the 'how'), grouped logically. If still > 20 variables, module likely needs splitting.

This is a refactoring conversation, not a code review nitpick. The design matters more than variable count."

---

### Question 9: You're moving from local modules to publishing to a registry. What changes?

**Entry**: "You need to version it and document it"

**Mid**: "Version it, document it, maintain backward compatibility, provide a README"

**Senior**: "Publishing changes responsibility model:

**Local modules (internal only)**:
- Can break backward compatibility
- Examples optional
- Minimal documentation (internal team knows context)
- Versioning is optional

**Published modules (external consumers)**:
- Backward compatibility is requirement (major versions for breaking changes)
- Examples are necessary (users learn by example)
- Comprehensive documentation (users don't have source context)
- Versioning is critical (users depend on specific versions)
- CHANGELOG required (users need to understand what changed)
- Security updates must be prioritized

Changes in practice:
- Add `CHANGELOG.md` documenting every version
- Add `examples/` directory with realistic configurations
- Add comprehensive `README.md` with troubleshooting
- Set up CI/CD to run module tests on every commit
- Establish SLA for security patches
- Enable GitHub releases tied to git tags

This goes from 'code we own' to 'product we maintain.'"

---

### Question 10: Design a module that's used by 500 teams with different requirements. How do you prevent feature creep?

**Senior answer**:
"Feature creep is the slow death of modules. Strategy:

1. **Well-defined scope**: Document what the module does and explicitly what it doesn't do.
   - ✅ 'This VPC module creates networking for standard applications'
   - ❌ 'This VPC module can handle any networking need'

2. **Variant strategy**: For different use cases, create variants:
   - `vpc.module` (standard)
   - `vpc-high-security.module` (enhanced compliance)
   - `vpc-multi-region.module` (cross-region)
   
   Better than building everything into one module.

3. **Request process**: Feature requests go through:
   - Is this standard (used by 50%+ of teams) or edge case?
   - Can it be solved with module overrides (locals, custom resources in calling code)?
   - Is there a variant that better serves this use case?
   
   Most requests are actually 'my use case is different' → send to variant, don't merge to core.

4. **Forking policy**: Document: 'Teams with specialized needs can fork this module.' Not all customizations loop back to core.

5. **Sunset strategy**: Old major versions get sunset dates. After date, no new features, only security patches.

Real world: 500-team modules stabilize better when they say 'no' frequently. Feature bloat is the enemy of adoptability."

---

### Question 11: Your team migrated modules from a monolithic state to layered state. How do you handle the state migration?

**Senior answer**:
"Monolithic to layered state migration is high-risk. Approach:

**Phase 1: Planning & Backup**
```bash
# Backup current state
aws s3 cp s3://terraform-state/prod/main.tfstate \
  s3://terraform-state/backups/main.tfstate.backup.$(date +%s)
```

**Phase 2: Refactor Code (Don't Apply Yet)**
- Split monolithic root module into layer folders
- Split resources into corresponding module definitions
- Update variables and outputs for each layer
- Write new backend.tf for each layer

**Phase 3: Import Resources to New State**
```bash
# Extract specific resources to new state file
terraform state list | grep "module.vpc" > vpc-resources.txt

# Create new layer directory with new backend
cd layers/foundation
terraform init

# Pull resources from old state and push to new
for resource in $(cat vpc-resources.txt); do
  terraform import -state-out=terraform.tfstate "$resource" "$(terraform state show -json "$resource" | jq '.values.id')"
done
```

**Phase 4: Parallel Testing**
- New layer: `terraform plan` should match old
- Verify all resources present in new state
- Ensure outputs match expectations
- Test cross-layer references via data sources

**Phase 5: Cutover**
```hcl
# Remove from monolithic state
terraform state rm "module.vpc"

# Verify: only non-VPC resources remain
terraform plan  # Should have no changes

# Point applications to new layer outputs
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "prod/foundation.tfstate"
  }
}
```

**Biggest Risk**: State inconsistency during migration. Solution:
1. Never apply during migration
2. Use -lock-timeout=30m to hold locks during long operations
3. Have rollback plan: state restore from S3 backup
4. Schedule during maintenance window when no other deploys happening

**Real gotcha**: Resource IDs changing between state files. Some resources get recreated when moved to new state. Use `terraform import` to reference existing IDs, not letting Terraform generate new ones."

---

### Question 12: A module is updated in production. A team's infrastructure breaks. How do you handle this?

**Senior answer**:
"Breaking changes in modules are serious incidents. Response:

**Immediate (0-5 minutes)**:
```bash
# Revert to previous module version immediately
# (Don't wait for root cause, restore service first)

# terraform.tf or module block
module "database" {
  source  = "../../modules/database"
  version = "~> 1.4.0"  # Changed from 1.5.0
}

terraform apply -auto-approve  # Restore previous behavior
```

**Investigation (5-30 minutes)**:
```bash
# 1. What changed between versions?
terraform show -json | jq '.values.outputs' > current-state.json

git log --oneline modules/database/
# Find the breaking change commit

git diff v1.4.0 v1.5.0 -- modules/database/
# Identify: variable name change? output removal? resource recreation?

# 2. What's broken in their infrastructure?
terraform plan  # With v1.4.0
# Error messages tell us: validation failed? resource missing? state out of sync?
```

**Root Cause Analysis**:
Common causes of module breaking changes:
1. **Variable migration**: `var.name` renamed to `var.resource_name`
   - Solution: Add deprecation warning in v1.5, support both names
   - Actually break in v2.0

2. **Output removal**: `output "security_group_id"` deleted
   - Consumer gets: `module.X.security_group_id` → error: output doesn't exist
   - Solution: Never remove outputs in minor versions

3. **Validation tightening**: `allowed_values` constraint added
   - Consumer gets: Validation error on their previously-valid `var.instance_type`
   - Solution: Check if change is backward compatible

4. **Resource recreation**: Logic change causes resource replacement
   - Consumer's database gets destroyed and recreated (DATA LOSS!)
   - Solution: Use `lifecycle.prevent_destroy` in examples, document

**Prevent Future Incidents**:
```hcl
# Module versioning policy
# PATCH: Only bug fixes, zero behavior change
# MINOR: New features, new optional variables, new outputs
#        Must NOT remove/rename variables or outputs
#        Must NOT require changes to consumer code
# MAJOR: Breaking changes (removal, rename, required migrations)

# Before releasing v1.5:
terraform test -run=backward_compat
# Test: module works with all previous variable combinations
```

**Long-term Fix**:
1. Establish breaking change review board
2. Require consumer testing before major versions
3. Support 2-3 major versions simultaneously during transition
4. Use semantic versioning strictly
5. Document all changes in CHANGELOG.md"

---

### Question 13: How do you structure modules for a platform team serving 100+ microservices?

**Senior answer**:
"At scale (100+ services), modules must support autonomy, safety, and speed. Architecture:

**Layer 1: Platform Foundation Modules** (platform team owns)
- vpc.module (networking, security groups, route tables)
- eks.module (Kubernetes control plane, worker node groups)
- rds.module (database engines, backups, monitoring)
- monitoring.module (CloudWatch, alarms, dashboards)

Characteristics:
- Opinionated (only AWS best practices)
- Immutable (rarely change)
- Centrally versioned
- Policy enforced via Terraform Cloud

**Layer 2: Service Abstraction Modules** (platform team owns)
- web-service.module (ECS/EKS deployment + ALB + monitoring)
- data-service.module (ECS + RDS + backup policy)
- async-worker.module (Lambda + SQS + logging)

These compose foundation modules automatically:
```hcl
module "my_web_service" {
  source  = "tfc.company.com/web-service/aws"
  version = "~> 3.0"
  
  service_name = "payment-api"
  environment  = "prod"
  desired_replicas = 3
  
  # Service module internally calls:
  # - module.vpc (via data source lookup)
  # - module.eks
  # - module.monitoring
}
```

**Layer 3: Application Configuration** (service teams own)
```hcl
# services/payment-api/main.tf
module "payment_api" {
  source  = "tfc.company.com/web-service/aws"
  version = "~> 3.0"
  
  service_name     = "payment-api"
  environment      = var.environment
  docker_image     = "gcr.io/company/payment-api:${var.image_tag}"
  desired_replicas = var.replicas
  
  # Service team provides ONLY application-specific config
  # Infrastructure details are abstracted away
}
```

**Benefits of 3-Layer Model**:
- Layer 1: Platform team controls standards centrally
- Layer 2: Encapsulates infrastructure pattern knowledge
- Layer 3: Service teams see only what matters to them

**Scaling Challenges & Solutions**:

Challenge 1: Service team wants custom sizing
```hcl
# ❌ Wrong: Add infinite variables to service module
variable "cpu_request" { type = string }
variable "memory_request" { type = string }
variable "cpu_limit" { type = string }
# ... 20 more variables

# ✅ Right: Offer T-shirt sizes (with escape hatch)
variable "service_tier" {
  type = string
  default = "standard"
  validation {
    condition = contains(["micro", "standard", "large"], var.service_tier)
    error_message = "Use: micro (cheap), standard (HA), large (compute-heavy)"
  }
}

variable "custom_resources" {
  type = object({
    cpu_request  = string
    memory_request = string
  })
  default = null
  
  # Escape hatch for 2-3 services with special needs
}
```

Challenge 2: 100 teams asking for different features
```hcl
# Track request in module issues, batch in quarterly releases
# Don't add every feature request

# Rate features by:
# 1. How many teams need it?
# 2. Can it be solved outside the module?
# 3. Does it break existing services?

# Only merge requests that answer YES to (1), NO to (2 & 3)
```

Challenge 3: Version upgrade chaos
```bash
# Coordinate upgrades via security bulletins
# Major version bump = security issue? REQUIRED
# Major version bump = new feature? OPTIONAL, 12-month deadline

terraform state 'module.web_service' contains versions:
  v2.0: 40 services (old)
  v2.5: 35 services (standard)
  v3.0: 25 services (latest)
  
# Goal: No version older than N-2 major
```

**Real-world scale**: Uber's Terraform modules (100K+ infrastructure configs) use this exact pattern: foundation → composed → application."

---

### Question 14: Modules pull data from multiple sources (Terraform Registry, Git, S3). How do you ensure consistency?

**Senior answer**:
"Multi-source modules create version nightmare. Strategy:

**Problem Scenario**:
```hcl
# Module A from public registry (terraform-aws-modules) v5.0
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 5.0"  # Allows 5.1, 5.2, etc. (drift!)
}

# Module B from Git (company private repo) v1.2
module "monitoring" {
  source = "git::https://github.com/company/tf-modules//monitoring?ref=main"
  # No version pinning! (will pull latest commit, could be broken)
}

# Module C from S3 (legacy artifact)
module "legacy_app" {
  source = "s3::https://s3-region.amazonaws.com/bucket/modules/legacy.zip"
  # S3 artifact could be replaced without notice
}

Result: Deployed infrastructure uses different module versions at different times!
```

**Solution: Centralized Module Proxy**

Terraform Cloud Registry acts as single source of truth:

```
Public Registry          Git Repos          S3 Artifacts
        ↓                   ↓                    ↓
    ┌────────────────────────────────────────────────────┐
    │    Terraform Cloud Private Registry (Proxy)        │
    │                                                    │
    │  vpc.module v5.2.1 (curated from public)          │
    │  monitoring.module v1.4.2 (curated from Git)      │
    │  legacy-app.module v1.0.0 (curated from S3)      │
    │                                                    │
    │  Properties:                                       │
    │  - Version immutable                              │
    │  - Audit logging of access                        │
    │  - Sha256 checksums verified                      │
    │  - Security scanning before publishing            │
    └────────────────────────────────────────────────────┘
                           ↓
    All teams pull from private registry only!
                           ↓
    module "vpc" {
      source  = "app.terraform.io/company/vpc/aws"
      version = "~> 5.2"  # Pinned to registry version
    }
```

**Implementation**:

```bash
# 1. Subscribe to public modules
# In TFC: Settings → Module Registry → Connect Terraform Registry

# 2. Curate public module versions
# - Test thoroughly before promoting
# - Document known issues
# - Plan deprecation of old versions

# 3. Mirror Git modules
# - Push Git tags to TFC registry with same version
# - Verify checksum matches source

# 4. Migrate S3 artifacts
# - Version S3 objects immutably (S3 versioning enabled)
# - Track versions document with published date
# - Plan retirement of legacy artifacts

# 5. Governance
# - Only platform team can publish to registry
# - Teams pull only from central registry
# - CI/CD blocks remote sources (only terraform.io allowed)
```

**Lock Versions Strictly**:
```hcl
# ❌ Allows drift
version = ">= 2.0"
version = "~> 2.0"  # Allows 2.9, 2.10 (minor drift)

# ✅ Strict
version = "~> 2.0.0"  # Allows only 2.0.x patches
version = "2.0.1"     # Exact version (safest)
```

**Audit Trail**:
```bash
# TFC provides audit log:
# 2025-03-01 10:00 Team-A retrieved vpc.module v2.0.1
# 2025-03-01 10:05 Team-B retrieved vpc.module v2.0.1
# 2025-03-15 14:00 vpc.module v2.1.0 published (breaking changes)
# 2025-04-01 09:00 team-A upgraded to v2.1.0 (tested first!)

# Real insight: When did teams upgrade versions?
# Tools like Scalr offer even deeper organizational visibility
```

**Real-world impact**: Netflix's Terraform module governance uses this exact proxy pattern to serve 1K+ services."

---

### Question 15: How do you handle module dependencies when a provider is not available initially?

**Senior answer**:
"This happens in air-gapped environments, private clouds, or during provider transitions. Solutions:

**Scenario 1: Provider Installed Later**
```hcl
# Dev environment: AWS available
# Prod environment: AWS coming next month during cutover

# Current approach: Modules target AWS only
provider "aws" { alias = "prod" }

module "database" {
  source = "./modules/rds"
  providers = { aws = aws.prod }
}

# Problem: module refers to aws_db_instance which needs AWS provider
# Fails if AWS provider not installed

# Solution: Conditional module instantiation
variable "enable_aws_resources" {
  type = bool
  # false initially, true after AWS available
}

module "database" {
  count   = var.enable_aws_resources ? 1 : 0
  source  = "./modules/rds"
  providers = { aws = aws.prod }
}

# Output exists conditionally
output "database_endpoint" {
  value = var.enable_aws_resources ? module.database[0].endpoint : null
}
```

**Scenario 2: Multi-Provider Transition (Terraform Provider→Newer Version)**
```hcl
# Module uses old Terraform AWS provider (v3.0)
# But org standardizing on v5.0
# Can't upgrade all at once

# Solution: Provider aliasing with migration path
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0, < 6.0"  # Allows both old and new
    }
  }
}

# Module works with 3.0, 4.0, 5.0
# Teams migrate on their schedule:
# Phase 1: v3 (current)
# Phase 2: v4 (test in staging)
# Phase 3: v5 (migrate prod)
```

**Scenario 3: Air-Gapped Environment (No Internet)**
```hcl
# Terraform has no access to download providers
# Must pre-stage providers locally

# Solution: Offline provider installation
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# In air-gapped environment:
# 1. Download provider binary elsewhere
# 2. Copy to local filesystem
# 3. Configure .terraformrc to use local path

# .terraformrc in air-gapped system
provider_installation {
  filesystem_mirror {
    path    = "/opt/terraform/providers"
    include = ["hashicorp/aws"]
  }
}

# Terraform finds aws provider in /opt/terraform/providers
# Without internet access needed
```

**Scenario 4: Custom/Proprietary Provider**
```
Custom Provider Development
  ↓
Local testing (works)
  ↓
Prod first time (not available in Terraform Registry!)
  ↓
Solution: Self-hosted provider registry

# Set up simple HTTP server serving this format:
/v1/providers/hashicorp/custom/5.0.0/linux_amd64/terraform-provider-custom_v5.0.0
/v1/providers/hashicorp/custom/5.0.0/checksums.txt
/v1/providers/hashicorp/custom/5.0.0/checksums.txt.sig

# Module points to registry:
terraform {
  cloud {}  # Uses Terraform Cloud as registry
  # Or manual registry_hosts in .terraformrc
}
```

**Debugging Provider Availability**:
```bash
# Check what providers are available
terraform providers

# Verify provider version constraints satisfied
terraform version

# Diagnose if environment has provider installed
terraform init -upgrade
# Error: Provider X required but not installed → fix before apply
```

**Enterprise Practice**: Pre-stage all required providers in internal mirror before environment goes live. Test provider availability in dev/staging first. Never assume it'll work in prod without testing."

---

### Question 16: Module A needs output from Module B, but Module B may not exist. How do you handle optional module composition?

**Senior answer**:
"This happens with feature flags, optional infrastructure components, or progressive deployments. Pattern:

**Scenario**: Database module is optional; app module needs database endpoint IF it exists.

**Approach 1: Try-Catch Pattern (Doesn't Exist in Terraform, Use Conditional)**
```hcl
variable "enable_database" {
  type    = bool
  default = false
}

module "database" {
  count  = var.enable_database ? 1 : 0
  source = "./modules/database"
  
  environment = var.environment
}

# App module needs to check if database module exists
module "app" {
  source = "./modules/app"
  
  # Conditional output reference
  database_endpoint = var.enable_database ? module.database[0].endpoint : null
  
  # Or for non-optional, use: 
  # database_endpoint = try(module.database[0].endpoint, null)
}
```

**Approach 2: Using try() for Graceful Fallback**
```hcl
# Module tries to use database output, falls back to null if missing
module "app" {
  source = "./modules/app"
  
  # If module.database doesn't exist, try() returns null
  database_endpoint = try(module.database[0].endpoint, null)
  database_password = try(module.database[0].password, null)
  
  # App module checks null:
  # if database_endpoint != null {
  #   configure app to use database
  # }
}
```

**Approach 3: Data Source Fallback (Better for Optional External Resources)**
```hcl
# Database might exist outside of Terraform (RDS created manually)
# Or might be within Terraform (module created conditionally)

data \"aws_db_instance\" \"optional\" {
  count              = var.enable_database ? 0 : 1  # Only if DATABASE DISABLED
  db_instance_identifier = var.external_database_name
  
  # Looks up existing database not managed by Terraform
}

module \"database\" {
  count = var.enable_database ? 1 : 0
  source = \"./modules/database\"
}

# App always has endpoint from one source
locals {
  db_endpoint = var.enable_database ? module.database[0].endpoint : data.aws_db_instance.optional[0].endpoint
}

module \"app\" {
  source = \"./modules/app\"
  database_endpoint = local.db_endpoint
}
```

**Approach 4: Dynamically Composed Modules**
```hcl
# For many optional components, use locals to organize

variable \"features\" {
  type = object({
    enable_database = bool
    enable_cache    = bool
    enable_queue    = bool
  })
}

locals {
  # Conditionally create resource blocks
  module_sources = [
    for feature, enabled in var.features : 
    feature if enabled
  ]
}

# Reference pattern (more complex)
module \"database\" {
  count = var.features.enable_database ? 1 : 0
}

module \"cache\" {
  count = var.features.enable_cache ? 1 : 0
}

# Application references conditionally based on what exists
output \"app_config\" {
  value = {
    database_endpoint = try(module.database[0].endpoint, null)
    cache_endpoint    = try(module.cache[0].endpoint, null)
    queue_url         = try(module.queue[0].url, null)
  }
}
```

**Key Principle**: Never assume module exists. Always use:
- `count` to conditionally create
- `try()` to safely reference outputs that might not exist
- Null checks in consuming modules
- Data sources to look up external resources as fallback

**Real-world example**: Heroku allows users to enable/disable add-ons (database, cache, etc.). Their infrastructure code likely uses this exact pattern to support optional components."

---

## Advanced Real-World Scenarios

### Scenario 4: Disaster Recovery - Multi-Region Failover with Modules

**Problem Statement**:
A SaaS company runs infrastructure in us-east-1. An AWS outage lasts 6 hours. Customer SLAs require 99.9% uptime. Management asks: "How do we design multi-region failover using modules?"

**Architecture Context**:
```
Current (single region):
┌─────────────────────────────────────┐
│         us-east-1 (Ohio)            │
│  ┌─────────┐  ┌─────────┐           │
│  │   App   │  │    DB   │           │
│  └─────────┘  └─────────┘           │
└─────────────────────────────────────┘
        ↓
Desired (multi-region):
┌──────────────────────────┐  ┌──────────────────────────┐
│   us-east-1 (Primary)    │  │   eu-west-1 Secondary)   │
│  ┌────────┐ ┌──────────┐ │  │ ┌────────┐ ┌──────────┐  │
│  │  App   │ │ RDS Primary
 │  │  App   │ │RDS Replica  │
│  └────────┘ └──────────┘ │  │ └────────┘ └──────────┘  │
└──────────────────────────┘  └──────────────────────────┘
        ↓                              ↓
        └──────────── Global Load Balancer ────────────┘
```

**Step-by-Step Implementation**:

```hcl
# 1. Define regions in root module
variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "secondary_region" {
  type    = string
  default = "eu-west-1"
}

variable "enable_failover" {
  type    = bool
  default = false  # Emergency flag
  description = "Override routing to secondary region during outage"
}

# 2. Configure providers for both regions
provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# 3. Deploy VPC module to both regions
module "vpc_primary" {
  source = "./modules/vpc"
  providers = { aws = aws.primary }
  
  region        = var.primary_region
  cidr_block    = "10.0.0.0/16"
  environment   = "prod"
  multi_az      = true  # HA within region
}

module "vpc_secondary" {
  source = "./modules/vpc"
  providers = { aws = aws.secondary }
  
  region        = var.secondary_region
  cidr_block    = "10.1.0.0/16"  # Different CIDR
  environment   = "prod"
  multi_az      = true
}

# 4. Deploy RDS with replication
module "rds_primary" {
  source = "./modules/rds"
  providers = { aws = aws.primary }
  
  identifier      = "prod-postgresql"
  engine          = "postgres"
  multi_az        = true
  backup_retention = 35  # 35 days of PITR
  
  # Enable Binary Log for replication
  backtrack_window = 7
}

module "rds_read_replica" {
  source = "./modules/rds-read-replica"
  providers = { aws = aws.secondary }
  
  source_db_identifier = module.rds_primary.db_instance_identifier
  
  # Creates read-only replica in secondary region
  # Automatically replicates writes from primary
}

# 5. Deploy application to both regions
module "app_primary" {
  source = "./modules/eks"
  providers = { aws = aws.primary }
  
  cluster_name              = "prod-cluster-primary"
  vpc_id                    = module.vpc_primary.vpc_id
  subnets                   = module.vpc_primary.subnet_ids
  
  # Point to primary database
  database_endpoint         = module.rds_primary.endpoint
  
  auto_scaling_desired_size = 5
}

module "app_secondary" {
  source = "./modules/eks"
  providers = { aws = aws.secondary }
  
  cluster_name              = "prod-cluster-secondary"
  vpc_id                    = module.vpc_secondary.vpc_id
  subnets                   = module.vpc_secondary.subnet_ids
  
  # Initially point to primary database (read-only replica cannot handle writes)
  database_endpoint         = module.rds_primary.endpoint
  
  auto_scaling_desired_size = 2  # Minimal cost standby
}

# 6. Global Route53 health checks + failover
resource "aws_route53_health_check" "primary" {
  ip_address      = module.app_primary.load_balancer_ip
  port            = 443
  type            = "HTTPS"
  failure_threshold = 3
  measure_latency = true
}

resource "aws_route53_health_check" "secondary" {
  ip_address      = module.app_secondary.load_balancer_ip
  port            = 443
  type            = "HTTPS"
  failure_threshold = 3
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "api.company.com"
  type    = "A"
  
  failover_routing_policy {
    type = var.enable_failover ? "SECONDARY" : "PRIMARY"
  }
  
  set_identifier = var.enable_failover ? "secondary" : "primary"
  
  alias {
    name                   = var.enable_failover ? module.app_secondary.alb_dns : module.app_primary.alb_dns
    zone_id                = var.enable_failover ? module.app_secondary.alb_zone_id : module.app_primary.alb_zone_id
    evaluate_target_health = true
  }
}

# 7. Monitoring and alerts
module "monitoring" {
  source = "./modules/cloudwatch"
  
  # Alert on primary region issues
  metrics = {
    "primary_cpu"       = module.app_primary.target_group_arn
    "primary_latency"   = module.app_primary.load_balancer_arn
    "replica_lag"       = "aws_rds_cluster/replica/AuroraBinlogReplicaLag"
  }
  
  # Trigger failover if primary unhealthy > 2 minutes
  sns_topic = aws_sns_topic.ops_alerts.arn
}
```

**Troubleshooting During Outage**:

```bash
# 1. Detect primary region failure
$ aws ec2 describe-instances --region us-east-1 --filters "Name=instance-state-name,Values=running"
# Returns: error UnauthorizedOperation | timeout

# 2. Manual failover trigger
$ terraform apply \
  -var="enable_failover=true" \
  -auto-approve

# 3. Monitor failover
$ aws route53 list-resource-record-sets --hosted-zone-id Z... \
  --query "ResourceRecordSets[?Name=='api.company.com']"
# Should show failover_routing_policy = SECONDARY

# 4. Update application configuration
# Secondary region RDS is read-only replica
# Option A: Promote replica to primary (takes ~1 second)
$ aws rds promote-read-replica --db-instance-identifier prod-postgresql-secondary

# Option B: Switch writes to secondary database (requires config change)
# Update app environment: DB_ENDPOINT=secondary-endpoint

# 5. Verify failover works
$ curl https://api.company.com/health
# Should respond from eu-west-1 cluster

# 6. Post-incident: Failback
# Once us-east-1 restored:
$ terraform apply \
  -var="enable_failover=false" \
  -auto-approve
# Route53 switches back to primary
```

**Best Practices Used**:
- ✅ IaC for both regions (modules replicated)
- ✅ Database replication for data consistency
- ✅ Health checks for automatic detection
- ✅ Route53 failover for DNS switching
- ✅ Secondary region kept warm (minimal scaling)
- ✅ Emergency flag (`enable_failover`) for manual control
- ✅ Monitoring triggers ops team alerts

**Cost Insight**: Multi-region standby costs 30-40% of primary (smaller instances). But saves your SLA and customers.

---

### Scenario 5: Module Refactoring - Breaking 200 Teams' Infrastructure

**Problem Statement**:
Your team discovers that the core VPC module has a performance bug: it takes 30 minutes to deploy 100 subnets because of N+1 API calls. Fix requires removing a poorly-designed local variable and restructuring how subnets are created. This breaks the module's input variables—a MAJOR version bump.

200 teams depend on this module. How do you roll out the breaking change safely?

**Architecture Context**:
```
Current (Slow):
module "vpc" {
  subnet_specs = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    { cidr = "10.0.2.0/24", az = "us-east-1b" },
    # ... 98 more
  ]
}

Desired (Fast):
module "vpc" {
  subnets = {
    "public-1a"   = { cidr = "10.0.1.0/24", az = "us-east-1a" }
    "public-1b"   = { cidr = "10.0.2.0/24", az = "us-east-1b" }
  }
}

Problem: API changed from list to map (breaking change)
```

**Step-by-Step Safe Rollout**:

```
Timeline: 6 months for safe migration

Month 1: Announce + Prepare
└─ Publish RFC (Request for Comments)
└─ Post in team Slack: "VPC module breaking change coming"
└─ Provide migration guide: old syntax → new syntax
└─ Explain impact and benefits

Month 2-3: Release and Test (v2.0.0)
└─ Release new major version with breaking changes
└─ But DON'T force upgrade yet
└─ Make it available for teams to test in staging

Month 4: Encourage Early Adoption
└─ Highlight performance improvements in production
└─ Share migration scripts (terraform state edit)
└─ Offer office hours: "Ask migration questions"
└─ Track adoption: Monitor which teams upgraded (via TFC stats)

Month 5: Mandatory Upgrade Deadline
└─ Send final notice: "v1.x support ends Month 6"
└─ Offer assistance for teams struggling

Month 6: Sunset Old Version
└─ v1.x receives only critical security patches
└─ No new features
└─ GitHub repo marks "DEPRECATED" in README
```

**Migration Automation**:

```hcl
# Provide migration helper module
module "vpc_migrator" {
  source = "tfc.company.com/vpc-migrator/aws"
  
  # Helps translate old input to new format
  old_subnet_specs = [
    { cidr = "10.0.1.0/24", az = "us-east-1a" },
    # ...
  ]
}

output "new_subnet_config" {
  value = module.vpc_migrator.converted_subnets
  # Shows how to structure new input
}
```

Migration script for state edits:

```bash
#!/bin/bash
# migrate-vpc-v1-to-v2.sh

# For teams using old module version, help them transition state

# Step 1: Backup current state
terraform state pull > backup-state-$(date +%s).json

# Step 2: List old module resources
terraform state list 'module.vpc' | head -20
# module.vpc.data.aws_availability_zones.available
# module.vpc.aws_vpc.main
# module.vpc.aws_subnet.subnets[0]
# module.vpc.aws_subnet.subnets[1]

# Step 3: Update module source in root configuration
# In main.tf:
# module "vpc" {
#   source = ".../vpc"
#   version = "~> 2.0"  # Changed from 1.x
# }

# Step 4: Transform state
terraform state rm 'module.vpc'  # Remove old module state
terraform init                    # Downloads new module
terraform import ...              # Re-import resources with new names

# Step 5: Verify
terraform plan  # Should show no changes
```

**Communication Plan**:

**Week 1**: Announcement
```
📢 VPC Module v2.0 Coming - Breaking Changes

Team Leaders,

We're releasing VPC module v2.0 with performance improvements (30→3 min deploy time).

This requires code changes:
OLD: subnet_specs = [{ cidr = "...", az = "..." }]
NEW: subnets = { "name" = { cidr = "...", az = "..." } }

Timeline:
- Now: v2.0 available for testing in staging
- Month 4: v2.0 recommended for production
- Month 6: v1.x support ends

Migration guide: [link to docs]
Questions? Email infra-team@company.com or attend Thu office hours.

Regards,
Platform Team
```

**Week 8**: Reminder
```
📋 VPC Module v2.0 Upgrade Status

Current adoption:
- Upgraded: 45 teams ✅
- Testing: 32 teams 🔄
- Not yet: 123 teams ⏳

Still on v1.x? Time to plan upgrade!

Blockers?
- Syntax confused: office hours Thu 2-3pm
- State migration issues: reply to this email
- Performance validation needed: staging available

v1.x support ends in 4 weeks.
```

**Results Metric**:
```
Week 0:  v2.0 released,  0% adoption
Week 8:  35% adoption (early teams)
Week 16: 60% adoption (following v2+ recommendations)
Week 20: 85% adoption (approaching deadline)
Week 26: 95% adoption (v1 sunset)
Week 28: 100% adoption (all teams migrated)

Goal: Smooth migration, no emergencies, minimal friction
```

**Best Practices Used**:
- ✅ 6-month transition period (not overnight)
- ✅ Clear communication (why, when, what)
- ✅ Automation tools (migration scripts, helpers)
- ✅ Technical support (office hours, Q&A)
- ✅ Carrots before sticks (highlight benefits before deadline)
- ✅ Backward-compatible escape hatch (if possible)
- ✅ Adoption tracking (know who hasn't upgraded)

**Lesson**: Breaking changes are okay with process. 200 teams moved smoothly because we communicated early, provided tools, and respected their timeline.

---

### Additional Interview Questions (17-30)

### Question 17: How do you version data structures within module variables?

**Senior answer**:
"Data structures evolve. Pattern:

```hcl
# v1: Simple structure
variable "config" {
  type = object({
    name  = string
    size  = string
  })
}

# Later: Need to add more options
# DON'T break v1 consumers!

# Solution: Optional fields with defaults
variable "config" {
  type = object({
    name     = string
    size     = string
    replicas = optional(number, 1)        # New optional field
    tags     = optional(map(string), {})  # New optional field
  })
}

# v3: Structure evolved significantly
# Solution: Nested object for new features

variable "config" {
  type = object({
    # Original fields (still supported)
    name      = string
    size      = string
    replicas  = optional(number, 1)
    
    # New nested features
    advanced = optional(object({
      drain_timeout            = optional(number, 30)
      connection_draining_enabled = optional(bool, true)
      cross_zone_load_balancing   = optional(bool, true)
    }), {})
  })
}

# Consumer updates progressively:
# Phase 1: Use v1 fields (works)
# Phase 2: Add replicas = 3
# Phase 3: Configure advanced settings
```

Data structure versioning allows backward compatibility as features grow."

---

### Question 18: A module accesses the same data source 50 times. How do you optimize?

**Senior answer**:
"Multiple data source queries are slow. Solution:

```hcl
# ❌ Slow: Repeated data source queries
data \"aws_ami\" \"build_123\" { filter { name = \"image-id\", values = [\"ami-xxx\"] } }
resource \"aws_instance\" \"worker_1\" { ami = data.aws_ami.build_123.id }
resource \"aws_instance\" \"worker_2\" { ami = data.aws_ami.build_123.id }
# ... repeated 48 more times

# ✅ Fast: Single query, reused
data \"aws_ami\" \"latest\" {
  most_recent = true
  filter {
    name   = \"name\"
    values = [\"company-app-*\"]
  }
}

locals {
  ami_id = data.aws_ami.latest.id
}

resource \"aws_instance\" \"workers\" {
  for_each = toset(range(50))
  
  ami           = local.ami_id
  instance_type = var.instance_type
}
```

Single data source query → used 50 times = 99% faster plan."

---

### Question 19: Module needs to support both AWS and GCP. What's the realistic approach?

**Senior answer**:
"Multi-cloud modules are anti-pattern. Real approach:

```
Option 1: Provider-specific modules (recommended)
modules/
├── aws/
│   ├── vpc.module
│   ├── compute.module
│   └── storage.module
├── gcp/
│   ├── vpc.module (implements Google VPC, VPC peering, etc.)
│   ├── compute.module (GCE, firewall rules, etc.)
│   └── storage.module (Cloud Storage permutations)

Teams pick cloud, use respective module:
module \"vpc_aws\" {
  count   = var.cloud == \"aws\" ? 1 : 0
  source  = \"./modules/aws/vpc\"
}

module \"vpc_gcp\" {
  count   = var.cloud == \"gcp\" ? 1 : 0
  source  = \"./modules/gcp/vpc\"
}

Benefits:
- Each module optimized for cloud idiosyncrasies
- Clear ownership (AWS expert owns AWS module)
- Easy to maintain (not juggling 20 conditionals)
```

False economy of 'unified' multi-cloud modules creates maintenance burden."

---

### Question 20: Module is slow to test. Every test creates real AWS resources (5 min per run). How do you speed up?

**Senior answer**:
"Layered testing:

```
Phase 1: Unit tests (instant, <1s)
├─ terraform validate
├─ terraform fmt -check
├─ TFLint
├─ Input variable validation blocks
└─ Type checking (Terraform 0.15+)

Phase 2: Static policy (fast, usually <30s)
├─ Sentinel policy validation
├─ OPA/Conftest policy checks
├─ JSON schema validation on outputs
└─ No AWS resources created

Phase 3: Integration tests (medium, 2-5 min)
├─ terraform plan (create actual AWS resources)
├─ Verify plan output looks sensible
├─ Check for deprecation warnings
└─ Destroy resources immediately

Phase 4: Full deploy tests (slow, 5-10 min)
├─ terraform apply (create real AWS infrastructure)
├─ Verify outputs match expectations
├─ Run smoke tests against real resources
└─ terraform destroy (cleanup)

Optimization:
- Run Phases 1-2 on every commit (gate PR)
- Run Phase 3 only on PR approval
- Run Phase 4 nightly or on release

CI/CD Example:
name: Terraform Module Tests
on: [pull_request, push]

jobs:
  fast-checks:  # Phases 1-2
    runs-on: ubuntu-latest
    steps:
      - terraform fmt -check
      - terraform validate
      - tflint --recursive
    # Completes in ~10 seconds
  
  integration:  # Phase 3 (if PR approved)
    if: github.event.pull_request.draft == false
    steps:
      - terraform init
      - terraform plan
    # Completes in ~2 minutes
  
  nightly-deploy:  # Phase 4
    if: github.ref == 'refs/heads/main' && github.event_name == 'schedule'
    steps:
      - terraform apply
      - terraform destroy
    # Completes in ~10 minutes nightly
```

Developer gets fast feedback on most issues without waiting for AWS."

---

### Question 21: How do you monitor module adoption and usage across the organization?

**Senior answer**:
"Visibility into module usage:

```hcl
# Terraform Cloud automatically tracks:
# - Which teams use which modules
# - Module version distribution
# - Apply/plan frequency by team
# - Module update impact across organization

# Custom tracking:
# 1. Module registry analytics
terraform cloud > insights > module usage

# 2. State file analysis
# Query Terraform state across organization
# Find: which modules appear in which states?

# 3. VCS integration
# GitHub: Search commits for 'source = \"module/...'
# Git log analysis: which teams update which modules

# Custom metrics example:
resource \"datadog_dashboard\" \"module_adoption\" {
  title = \"Module Adoption Metrics\"
  
  widgets = [
    {
      type = \"timeseries\"
      query = \"count over time of terraform-cloud.module-usage{module_name:vpc}\"
      # Shows: VPC module adoption trend
    },
    {
      type = \"pie_chart\"
      query = \"module-versions{module:eks} by version\"
      # Shows: EKS module version distribution
      # Goal: 70%+ teams on latest version
    },
    {
      type = \"table\"
      query = \"module-lagging-teams{version_gap > 5}\"
      # Shows: Teams >5 versions behind
      # Action: Send upgrade reminders
    }
  ]
}

# Alerting:
# If module adoption drops >10%: "Is there an issue?"
# If module N version adoption plateaus: "Need help upgrading?"
```

Visibility enables proactive module management."

---

### Question 22: State file grows to 500MB. Module operations are slow. What do you do?

**Senior answer**:
"Large state is warning sign of architecture issue:

```
Analysis:
├─ 500MB state = ~100K+ resources managed in single state
│  └─ Red flag: should split into layers/modules
│
├─ Plan takes 10 min = state refresh bottleneck
│  └─ Too many API calls to AWS
│
└─ Apply takes 30 min = graph too large
   └─ Terraform parallelism hitting limits

Solutions:

1. Split state into layers
# Before: everything in prod/terraform.tfstate
# After:
prod/
├─ foundation/terraform.tfstate     (VPC, subnets)
├─ platform/terraform.tfstate        (RDS, ElastiCache)
└─ applications/terraform.tfstate    (EC2, Lambda)

# Impact: Plan/apply on platform layer only affects platform layer
# 500MB state → 100MB foundation + 150MB platform + 250MB applications
# Each applies in parallel: 10min → 3-4min

2. Switch to external state backends per region/account
# Instead of: single S3 bucket, single state file
# Use: per-region/account state files

3. Use -refresh=false when safe
terraform plan -refresh=false
# Skips AWS API calls if state known fresh

4. Implement state locking with short timeout
# Prevents long-running applies from hanging others

5. Monitor state file growth
Resource count increasing?
│ New microservices = expected growth
│ Duplicate resources = cleanup opportunity
└─ Resource sprawl = governance issue
```

Large state is symptom, not disease. Find root cause."

---

### Question 23: Your module becomes the \"standard\" across org. How do you handle maintenance burden?

**Senior answer**:
"Standard module = 1000+ teams depend on it = critical infrastructure.

```
Sustainability strategy:

1. Governance (prevent chaos)
   ├─ Establish change control board (platform team reviews PRs)
   ├─ Require community testing before merge
   ├─ Test new features in 3 teams before general release
   └─ SLA: Security patches within 48 hours

2. Documentation
   ├─ README with real examples
   ├─ Troubleshooting guide for common issues
   ├─ FAQ with top 20 questions
   ├─ Video walkthroughs (3-5 min) for setup
   └─ Monthly office hours: \"Ask anything\"

3. Tooling to reduce support burden
   ├─ Pre-commit hooks catch misconfigurations
   ├─ terraform validate + TFLint in CI/CD
   ├─ Policy as code blocks unsupported patterns
   ├─ Auto-generated documentation from code
   └─ Automated tests for backward compatibility

4. Support model
   ├─ Tier 1: Auto-response to GitHub issues (\"Checking this...\")
   ├─ Tier 2: Platform team responds within 24 hours
   ├─ Tier 3: Escalation to principal engineer if infrastructure-critical
   ├─ SLA: Security issues 24h, bugs 1 week, features 1 month consideration
   └─ Have on-call rotation (platform team)

5. Scaling headcount
   ├─ Start: 1 person maintains (you!)
   ├─ Scale: 2-3 people on-call rotation
   ├─ Growth: 4-5 people focused on module ecosystem
   ├─ Enterprise: Team of 10+ maintaining module portfolio
   └─ Reality: A single person scaling to 1K teams is unsustainable

6. Sunsetting gracefully
   ├─ Major version bumps take 6-12 months
   ├─ Old versions get 18+ months support (critical patches)
   ├─ Deprecation periods: announce, provide migration tools, enforce deadline
   └─ Final version gets \"LTS\" label if org depends heavily
```

Example: Terraform AWS modules maintain 20.0, 19.x, 18.x in parallel. Critical security patches apply to all. New features only in latest."

---

### Question 24: Module used in two different departments - Finance uses it one way, Engineering another. How to serve both?

**Senior answer**:
"Divergent use cases = variant strategy:

```
Problem:
Finance Department:
├─ Needs strict cost controls
├─ Wants reserved instances (cost optimization)
└─ Minimal auto-scaling

Engineering Department:
├─ Needs high availability
├─ Wants spot instances mixed with on-demand (flexibility)
└─ Aggressive auto-scaling

Solution:
Option 1: Core module + variants
modules/
├─ compute-base.module (shared logic)
├─ compute-cost-optimized.module (uses compute-base, adds reserved instance logic)
└─ compute-ha.module (uses compute-base, adds spot+on-demand + autoscaling)

modules/compute-cost-optimized/main.tf:
module \"base\" {
  source = \"../compute-base\"
  # Common config
}

# Cost-optimized additions
resource \"aws_ec2_fleet\" \"reserved\" {
  target_capacity_specification {
    on_demand = 100
    spot      = 0  # Finance doesn't want spot
  }
}

modules/compute-ha/main.tf:
module \"base\" {
  source = \"../compute-base\"
  # Common config
}

# HA additions
resource \"aws_ec2_fleet\" \"mixed\" {
  target_capacity_specification {
    on_demand = 30
    spot      = 70  # Engineering optimizes cost+HA
  }
}

Usage:
Finance team:
module \"compute\" {
  source = \"terraform-modules/compute-cost-optimized/aws\"
}

Engineering team:
module \"compute\" {
  source = \"terraform-modules/compute-ha/aws\"
}

Option 2: Feature flags (less clean, but sometimes necessary)
variable \"use_case\" {
  type = string
  validation {
    condition = contains([\"finance\", \"engineering\"], var.use_case)
  }
}

locals {
  on_demand_percentage = var.use_case == \"finance\" ? 100 : 30
  spot_percentage      = var.use_case == \"finance\" ? 0 : 70
  scaling_factor       = var.use_case == \"finance\" ? 1.0 : 2.0
}
```

Variants > feature flags. Keeps module focused."

---

### Question 25: How do you prevent \"module hell\" - modules calling modules calling modules (too deep)?

**Senior answer**:
"Deep nesting creates complexity, makes debugging hard:

```
Bad (Deep):
root config
└─ module.application           (application composite module)
   ├─ module.database           (database composite module)
   │  ├─ module.aws_rds         (atomic)
   │  ├─ module.secrets         (atomic)
   │  └─ module.monitoring      (atomic)
   └─ module.compute            (compute composite module)
      ├─ module.eks             (atomic)
      ├─ module.security_groups (atomic)
      └─ module.networking      (atomic)

Problem:
- 3 levels deep
- Hard to know what actually gets created
- Error could be at any level
- Debugging requires traversing levels

Better (Flat):
root config
├─ module.vpc               (atomic)
├─ module.eks               (atomic)
├─ module.rds               (atomic)
├─ module.secrets           (atomic)
├─ module.monitoring        (atomic)
└─ module.security_groups   (atomic)

Root config orchestrates everything explicitly:
\"Here's what infrastructure I want:
 - VPC with these subnets
 - EKS connected to VPC
 - RDS in VPC
 - Monitoring of EKS and RDS
 - Security groups between components\"

All composition explicit in root configuration.

Levels guideline:
- Level 0: Root Terraform (your deployment code)
- Level 1: Modules (VPC, EKS, RDS)
- Level 2: Rare (only for complex module composition)
- Level 3+: Probably a mistake

Exception: Published modules can call submodules internally:
module \"vpc\" {
  source = \"terraform-aws-modules/vpc/aws\"
  
  # Internally calls:
  # - aws_vpc
  # - aws_subnet (multiple)
  # - aws_nat_gateway
  # - aws_route_table
  
  # But root config sees only \"vpc\" module
  # Complexity hidden inside published module is okay
}
```

Rule: 2 levels max in orchestration, unless justified."

---

### Question 26: Module version constraint strategies for different team maturity levels?

**Senior answer**:
"Version constraints should reflect team maturity:

```
Enterprise Teams (experienced, tested infrastructure):
├─ Constraint: \"~> X.Y.Z\"     # Lock to patch level
├─ Discipline: Test in staging, then prod upgrade
├─ Update frequency: Quarterly or on-demand
└─ Example: \"~> 3.2.5\" allows 3.2.6, 3.2.7 but NOT 3.3.0

Intermediate Teams (standard patterns, some customization):
├─ Constraint: \"~> X.Y\"       # Allow minor updates
├─ Discipline: Monthly updates, monitor for issues
├─ Update frequency: Monthly with change windows
└─ Example: \"~> 3.2\" allows 3.2.0 through 3.9.9 but NOT 4.0.0

Startup/Fast Teams (willing to accept risk for features):
├─ Constraint: \">= X.Y\"       # Always latest
├─ Discipline: None, live on latest
├─ Update frequency: Continuous (auto-upgrade)
└─ Example: \">= 3.0\" means \"give me whatever's newest\"

Legacy Teams (can't change, risk-averse):
├─ Constraint: \"= X.Y.Z\"      # Exact version only
├─ Discipline: Tested thoroughly, locked in place
├─ Update frequency: Rare, urgent security patches only
└─ Example: \"= 2.5.0\" means \"never change this\"

Default Recommendation for Organizations:
├─ New services: \"~> X.Y.Z\" (safe, controlled)
├─ Established: \"~> X.Y\" (can handle minor upgrades)
├─ Only after understanding module's release cycle
```

Constraint should match team capability + risk tolerance."

---

### Question 27: How do you ensure modules work across incompatible tool versions?

**Senior answer**:
"Terraform version, provider versions, plugin versions all matter:

```
Version matrix to concern about:
├─ Terraform 0.11 → 0.12: Syntax breaking change (HCL2)
├─ Terraform 0.12 → 1.0:  Minor syntax improvements
├─ Provider AWS: v3 → v4 → v5 (resource attr changes)
├─ Provider AWS: v5.0 → v5.30 (incremental)
└─ Terraform Cloud version (SaaS, always latest)

Solution: Version constraints in required_providers

```hcl
terraform {
  required_version = \">= 1.0, < 2.0\"  # We support 1.5+
  
  required_providers {
    aws = {
      source  = \"hashicorp/aws\"
      version = \"~> 5.0\"  # 5.0 through 5.99
    }
  }
}
```

Testing matrix:
├─ Terraform 1.5.x + AWS 5.0 (target)
├─ Terraform 1.5.x + AWS 4.0 (legacy support)
├─ Terraform 1.6.x + AWS 5.0 (forward compatibility)
└─ Terraform 0.15.x (NOT supported, EOL)

In CI/CD:
```yaml
matrix:
  terraform-version: [ \"1.5\", \"1.6\" ]
  aws-version: [ \"4.0\", \"5.0\", \"5.30\" ]

# Test all combinations
# If any fail → don't merge
```

Real example: Terraform AWS modules tested against:
- Terraform: 1.0 through 1.6
- AWS Provider: 4.0 through 5.latest
- Result: Can pick combinations that work for your org"

---

### Question 28: Module dependency hell - circular dependencies between modules. How to break cycles?

**Senior answer**:
"Circular dependencies cause Terraform to fail:

```
Scenario: VPC module needs security group from Security module
          Security module needs VPC ID from VPC module
          
         VPC Module
         ↙        ↖
   Creates SG     Needs SG ID
        ↓           ↑
   Security Module

Solution: Separate concerns, use data sources

```hcl
# Split: VPC manages networking only
module \"vpc\" {
  source = \"./modules/vpc\"
  
  cidr_block = var.vpc_cidr
  # Creates: VPC, subnets, route tables, IGW
  # Does NOT create security groups
}

# Security groups managed separately (no circular dep)
module \"security_groups\" {
  source = \"./modules/security-groups\"
  
  vpc_id = module.vpc.vpc_id  # Only dependency: vpc_id
}

# Application uses both modules
module \"app\" {
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.security_groups.default_sg_id
}
```

Key principle:
- A depends on B's OUTPUT? (use explicit reference)
- B depends on A's OUTPUT? (B uses data source to query, not depend on module)

```hcl
# If A → B exists, B must NOT → A

# ❌ Circular pattern (avoid)
module \"a\" {
  b_output = module.b.something  # A depends on B
}

module \"b\" {
  a_output = module.a.something  # B depends on A (CYCLE!)
}

# ✅ Break cycle using data source
module \"a\" {
  source = \"./modules/a\"
  # Creates resource with tags: Name = \"my-a\"
}

module \"b\" {
  source = \"./modules/b\"
  
  # Instead of depending on module.a:
  # query it with data source
  a_id = data.aws_resource.a.id
}

data \"aws_resource\" \"a\" {
  filter {
    name   = \"tag:Name\"
    values = [\"my-a\"]
  }
}
```

Dependency rule: Graph must be acyclic (DAG). Use data sources to query instead of module outputs when cycle risk exists."

---

### Question 29: How do you handle module \"snowflake\" problem - everyone customizes modules differently?

**Senior answer**:
"Snowflake infrastructure = unique configs per service (high op burden):

```
Problem:
Team A: \"Give me EKS with 5 nodes\"
Team B: \"Give me EKS with 10 nodes, spot instances, ARM64\"
Team C: \"Give me EKS with GPU nodes, NVIDIA runtime\"
Team D: \"Give me EKS with... (completely custom)\"

Soon you have configuration permutations explosion.

Solution: Discourage snowflakes via module design

```hcl
# ❌ Enables snowflakes
variable \"node_type\" {
  type = string
  # Can be: t3.medium, t3.large, m5.large, m5.2xlarge, ...
  # 40+ possibilities!
}

# ✅ Discourages snowflakes (offers limited T-shirt sizes)
variable \"service_tier\" {
  type = string
  default = \"standard\"
  
  validation {
    condition = contains([
      \"starter\",      # 2 nodes, t3.small, shared
      \"standard\",     # 5 nodes, t3.large, HA
      \"enterprise\",   # 10 nodes, m5.xlarge, SLA
    ], var.service_tier)
    error_message = \"Stick to starter/standard/enterprise\"
  }
}

# If team really needs custom:
variable \"custom_node_config\" {
  type = object({
    instance_type = string
    count         = number
  })
  default  = null
  nullable = true
  
  # Require approval for custom config
  sensitive = true
}
```

Enforce standardization:
1. Default to sensible T-shirt sizes
2. Document why they exist (cost, performance, maintenance)
3. Make custom option hard (require forms, approval, SLA)
4. Track custom instances (alert ops team)
5. Periodically review: \"Can we consolidate custom to new tier?\"

Metric: Org ideal is 95% + teams on standard configs, 5% on variants/custom.

Example quotas:
- \"You have 2 custom resource quotas per team per year\"
- \"Custom configs reduce standard SLA (24h response → 48h response)\"
- \"Custom infrastructure gets quarterly review - must justify continued existence\"
```

Snowflakes are expensive. Make standard so attractive, snowflakes disappear."

---

### Question 30: What's your framework for deciding \"module or inline?\" for every piece of infrastructure?

**Senior answer**:
"Decision tree for module-izing infrastructure:

```
START: New piece of infrastructure

├─ Will this be used by multiple teams/services?
│  ├─ YES → Might warrant module
│  └─ NO → Proceed
│
├─ Is this complex enough to encapsulate?
│  │ (Does module save >50 lines in calling code?)
│  ├─ YES → Might warrant module
│  └─ NO → Proceed
│
├─ Am I solving a generalizable problem?
│  │ (Or is this oneoff/custom?)
│  ├─ YES → Might warrant module
│  └─ NO → Keep inline
│
└─ If NO to all above → Definitely keep inline!

Decision Framework (scored):

Reusability Score:
├─ Used by 0-1 people/teams:         0 pts
├─ Used by 2-5 teams:                 5 pts
├─ Used by 10+ teams:                10 pts
└─ Used org-wide (100+ teams):       20 pts

Complexity Score:
├─ Simple resource (<5 resources):    0 pts
├─ Moderate (5-20 resources):         5 pts
├─ Complex (20+ resources + logic):  10 pts

Standardization Need:
├─ Everyone does this differently:    0 pts
├─ Some patterns emerging:            5 pts
├─ Core org pattern (all do same):   10 pts

Stability Score:
├─ Changes frequently (weekly):       -5 pts
├─ Changes monthly:                   0 pts
├─ Stable (rarely changes):           5 pts

Total Score Decision:
├─ 0-5:     Definitely inline (local code)
├─ 5-10:    Maybe module (if team will use it 3+ times)
├─ 10-15:   Probably module (multiple teams benefit)
├─ 15-20:   Definitely module (published, versioned)
├─ 20+:     Absolutely module + governance (critical infrastructure)
```

Real examples:

Example 1: Company internal ALB for web services
- Reusability: 20 pts (100 services use it)
- Complexity: 8 pts (many resources, listener rules)
- Standardization: 10 pts (all services want same ALB pattern)
- Stability: 3 pts (rarely changes)
- Total: 41 pts → **Definitely published module**

Example 2: One-off RDS database for legacy system
- Reusability: 0 pts (only this system)
- Complexity: 3 pts (simple RDS + parameter group)
- Standardization: 0 pts (custom config we'll tweak)
- Stability: -2 pts (legacy, will modify often)
- Total: 1 pt → **Keep inline, in legacy folder**

Example 3: Team's internal monitoring dashboard
- Reusability: 5 pts (this team + maybe 2-3 others might want)
- Complexity: 4 pts (CloudWatch dashboard config)
- Standardization: 2 pts (team-specific, not org standard)
- Stability: 2 pts (tweaks quarterly)
- Total: 13 pts → **Maybe local module?** (team-internal, not published)

Framework ensures modules created when justified, not just \"extract everything.\""

---

*End of Study Guide - Complete Senior DevOps Reference*

### Textual Deep Dive

#### Architecture Role

Advanced module patterns extend Terraform's declarative capability to handle complex infrastructure architectures that would otherwise require custom scripting. Meta-arguments (`count`, `for_each`, `depends_on`, `lifecycle`) and advanced syntax (dynamic blocks, advanced interpolation, splat expressions) enable modules to:

- Generate multiple resource instances from parameterized configurations
- Manage resource lifecycle with fine-grained control
- Express complex conditionals and loops idiomatically
- Handle infrastructure changes safely without manual intervention

#### Internal Working Mechanism

**Meta-arguments Processing**:

When Terraform parses a module with meta-arguments, it follows this sequence:

1. **Evaluation Phase**: Variables are resolved, locals computed, meta-arguments evaluated
2. **Graph Building**: Dynamic resource instances generated based on `count`/`for_each`
3. **Dependency Resolution**: `depends_on` and implicit references establish ordering
4. **Planning**: Each generated instance becomes a node in the resource graph
5. **Application**: Terraform applies changes to each instance respecting dependencies

**Count vs. For_Each**:

```
count mechanism:
  count.index → 0, 1, 2, ... (numeric indexing)
  Problem: Inserting/removing middle elements shifts indices
  
for_each mechanism:
  each.key → stable map/set keys
  Problem: Can't iterate lists directly (must use toset() or convert)
  
State representation:
  count:    resource_type.name[0], resource_type.name[1]
  for_each: resource_type.name["key1"], resource_type.name["key2"]
```

**Dynamic Blocks**:

```hcl
# Without dynamic: repetitive, error-prone
resource "aws_security_group" "main" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }
  # ... more ports
}

# With dynamic: parameterized, DRY
resource "aws_security_group" "main" {
  dynamic "ingress" {
    for_each = var.allowed_ports
    
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = var.allowed_cidrs
    }
  }
}
```

Internal processing: Terraform expands dynamic blocks during parse time, creating multiple block instances in the resource definition.

#### Production Usage Patterns

**Pattern 1: Multi-Resource Instance Management**

```hcl
# Provision N subnets across M availability zones
variable "subnet_configuration" {
  type = list(object({
    availability_zone = string
    cidr_block        = string
    name              = string
  }))
}

resource "aws_subnet" "main" {
  for_each = { for subnet in var.subnet_configuration : subnet.name => subnet }
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  
  tags = { "Name" = each.value.name }
}

# Use case: Modify one subnet's AZ without affecting others
# With count: all subsequent subnets would shift
# With for_each: only the modified entry is affected
```

**Pattern 2: Conditional Resource Creation**

```hcl
variable "enable_nat_gateway" {
  type    = bool
  default = false
}

variable "nat_gateway_count" {
  type    = number
  default = 0
}

resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? var.nat_gateway_count : 0
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}
```

**Pattern 3: Advanced Conditional Logic in Outputs**

```hcl
# Output only created resources
output "nat_gateway_ips" {
  value = var.enable_nat_gateway ? aws_nat_gateway.main[*].public_ip : []
  description = "NAT gateway IPs (empty if disabled)"
}

# Conditional output types
output "database_endpoint" {
  value = var.use_rds_proxy ? aws_db_proxy.main[0].endpoint : aws_db_instance.main.endpoint
}
```

**Pattern 4: Dynamic Security Groups**

```hcl
variable "security_rules" {
  type = list(object({
    direction = string  # "ingress", "egress"
    port      = number
    protocol  = string
    cidrs     = list(string)
  }))
}

resource "aws_security_group_rule" "dynamic" {
  for_each = { 
    for idx, rule in var.security_rules : "${rule.direction}-${rule.port}" => rule
  }
  
  security_group_id = aws_security_group.main.id
  type              = each.value.direction
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidrs
}
```

#### DevOps Best Practices

**1. Prefer for_each Over count**:
```hcl
# ✅ Stable references, safe updates
resource "aws_instance" "app" {
  for_each = toset(var.instance_names)
  
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = { "Name" = each.value }
}

# ❌ Fragile, index shifting causes unintended replacements
resource "aws_instance" "app" {
  count = length(var.instance_names)
  
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = { "Name" = var.instance_names[count.index] }
}
```

Why: If you remove element at index 1, all subsequent elements shift, causing Terraform to destroy and recreate them unnecessarily.

**2. Use Dynamic Blocks Sparingly**:

Dynamic blocks reduce readability. Use only when:
- Same block structure repeats with different values
- Block count is truly dynamic (from variables or data)

```hcl
# ✅ Clear structure, readable
resource "aws_security_group" "main" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }
}

# ❌ Harder to reason about, avoid unless necessary
resource "aws_security_group" "main" {
  dynamic "ingress" {
    for_each = [443]  # Why is this dynamic?
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidrs
    }
  }
}
```

**3. Explicit Dependency Management**:

```hcl
# Auto-discovered dependencies (usually sufficient)
resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.main.id  # Implicit dependency
  # ...
}

# Explicit dependencies (when auto-discovery fails)
resource "aws_instance" "app" {
  depends_on = [
    aws_iam_role_policy.app_policy,
    aws_vpc_endpoint.s3
  ]
}
```

**4. Lifecycle Rules for Safe Changes**:

```hcl
# Create replacement before destroying old (zero-downtime upgrades)
resource "aws_launch_template" "app" {
  lifecycle {
    create_before_destroy = true
  }
}

# Prevent accidental destruction
resource "aws_rds_instance" "main" {
  lifecycle {
    prevent_destroy = false  # Be cautious with this in prod
  }
}

# Ignore certain attribute changes (e.g., user-applied tags)
resource "aws_security_group" "main" {
  lifecycle {
    ignore_changes = [tags["LastModified"]]
  }
}
```

#### Common Pitfalls

**Pitfall 1: Count Index Shifting**

```hcl
# ❌ Problem: User removes middle subnet, rest shift
variable "subnets" {
  default = [
    "10.0.1.0/24",  # index 0
    "10.0.2.0/24",  # index 1 ← Remove this
    "10.0.3.0/24",  # index 2 → Becomes index 1
  ]
}

resource "aws_subnet" "main" {
  count             = length(var.subnets)
  cidr_block        = var.subnets[count.index]
  # Terraform destroys and recreates 10.0.3.0/24 subnet
}

# ✅ Solution: Use for_each
variable "subnets" {
  default = {
    "primary"   = "10.0.1.0/24"
    "secondary" = "10.0.2.0/24"
    "tertiary"  = "10.0.3.0/24"
  }
}

resource "aws_subnet" "main" {
  for_each   = var.subnets
  cidr_block = each.value
  # Removing "secondary" doesn't affect others
}
```

**Pitfall 2: Dynamic Blocks with Missing Attributes**

```hcl
# ❌ Problem: Incomplete block definition
variable "security_rules" {
  type = list(object({
    port = number
    # Missing protocol?
  }))
}

dynamic "ingress" {
  for_each = var.security_rules
  content {
    from_port = ingress.value.port  # Protocol missing!
  }
}

# ✅ Solution: Validate variable structure
variable "security_rules" {
  type = list(object({
    port     = number
    protocol = string
  }))
  
  validation {
    condition = alltrue([
      for rule in var.security_rules : 
      contains(["tcp", "udp"], rule.protocol)
    ])
    error_message = "Protocol must be tcp or udp"
  }
}
```

**Pitfall 3: Circular Dependencies with Conditionals**

```hcl
# ❌ Problem: Conditional creates implicit cycle
resource "aws_security_group" "main" {
  count = var.create_sg ? 1 : 0
}

resource "aws_instance" "app" {
  security_groups = var.create_sg ? [aws_security_group.main[0].id] : [var.existing_sg_id]
  # If var.create_sg changes, resource gets recreated
}

# ✅ Solution: Separate concerns
locals {
  security_group_id = var.create_sg ? aws_security_group.main[0].id : var.existing_sg_id
}

resource "aws_instance" "app" {
  security_groups = [local.security_group_id]
}
```

**Pitfall 4: For_each with Complex Loop Logic**

```hcl
# ❌ Problem: Unreadable loop transformation
resource "aws_instance" "app" {
  for_each = { for i, az in var.azs : az => aws_subnet.main[i].id }
}

# ✅ Solution: Use locals to clarify transformation
locals {
  instance_config = {
    for i, az in var.azs : az => {
      subnet_id = aws_subnet.main[i].id
      az        = az
    }
  }
}

resource "aws_instance" "app" {
  for_each  = local.instance_config
  subnet_id = each.value.subnet_id
  tags      = { "AZ" = each.value.az }
}
```

---

### Practical Code Examples

#### Example 1: Complex Multi-Tier Application Module

```hcl
# variables.tf
variable "environment" {
  type = string
}

variable "application_config" {
  type = object({
    name             = string
    web_tier_count   = number
    app_tier_count   = number
    db_engine        = string
    db_backup_window = string
  })
}

variable "instance_types" {
  type = map(string)
  default = {
    "web"  = "t3.medium"
    "app"  = "t3.large"
    "db"   = "db.t3.large"
  }
}

# main.tf
locals {
  common_tags = {
    "Environment" = var.environment
    "Application" = var.application_config.name
    "ManagedBy"   = "Terraform"
  }
}

# Dynamic security groups for each tier
variable "security_rules" {
  type = map(list(object({
    port     = number
    protocol = string
    cidr     = list(string)
  })))
  
  default = {
    "web" = [
      { port = 80, protocol = "tcp", cidr = ["0.0.0.0/0"] },
      { port = 443, protocol = "tcp", cidr = ["0.0.0.0/0"] }
    ],
    "app" = [
      { port = 8080, protocol = "tcp", cidr = ["10.0.0.0/8"] }
    ]
  }
}

resource "aws_security_group" "tier" {
  for_each = toset(["web", "app"])
  
  name = "${var.environment}-${each.value}-sg"
  
  dynamic "ingress" {
    for_each = lookup(var.security_rules, each.value, [])
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr
    }
  }
  
  tags = local.common_tags
}

# Web servers with count
resource "aws_instance" "web" {
  count              = var.application_config.web_tier_count
  ami                = data.aws_ami.latest.id
  instance_type      = var.instance_types["web"]
  security_groups    = [aws_security_group.tier["web"].id]
  iam_instance_profile = aws_iam_instance_profile.web.name
  
  tags = merge(
    local.common_tags,
    { "Name" = "${var.environment}-web-${count.index + 1}" }
  )
}

# App servers with for_each for clarity
resource "aws_instance" "app" {
  for_each = {
    for i in range(var.application_config.app_tier_count) : 
    "app-${format("%02d", i + 1)}" => {
      index = i
    }
  }
  
  ami                = data.aws_ami.latest.id
  instance_type      = var.instance_types["app"]
  security_groups    = [aws_security_group.tier["app"].id]
  iam_instance_profile = aws_iam_instance_profile.app.name
  
  tags = merge(
    local.common_tags,
    { "Name" = "${var.environment}-${each.key}" }
  )
}

# Outputs
output "web_server_ids" {
  value = aws_instance.web[*].id
}

output "app_server_ids" {
  value = { for k, v in aws_instance.app : k => v.id }
}
```

#### Example 2: Dynamic Resource Creation Based on Configuration

```hcl
# variables.tf
variable "services" {
  type = map(object({
    port             = number
    health_check_url = string
    instance_count   = number
    enabled          = bool
  }))
  
  default = {
    "api" = {
      port             = 8080
      health_check_url = "/health"
      instance_count   = 3
      enabled          = true
    },
    "worker" = {
      port             = 9090
      health_check_url = "/status"
      instance_count   = 2
      enabled          = true
    },
    "legacy" = {
      port             = 3000
      health_check_url = "/ping"
      instance_count   = 1
      enabled          = false
    }
  }
}

# main.tf
locals {
  # Only enabled services
  active_services = {
    for name, config in var.services : name => config
    if config.enabled
  }
}

# Create security group rules dynamically
resource "aws_security_group_rule" "service" {
  for_each = local.active_services
  
  security_group_id = aws_security_group.main.id
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
}

# Create Application Load Balancer target groups
resource "aws_lb_target_group" "service" {
  for_each = local.active_services
  
  name        = "${var.environment}-${each.key}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = each.value.health_check_url
  }
  
  tags = { "Service" = each.key }
}

# Create instances per service
resource "aws_instance" "service" {
  for_each = {
    for service, config in local.active_services :
    service => {
      port              = config.port
      health_check_url  = config.health_check_url
      count             = config.instance_count
    }
  }
  
  # This would need nested loop - using local value instead
  # See alternative below
}

# Alternative: Flatten for nested loops
locals {
  instance_specs = flatten([
    for service, config in local.active_services : [
      for i in range(config.instance_count) : {
        service_name = service
        instance_num = i + 1
        port        = config.port
      }
    ]
  ])
  
  instances_map = { 
    for spec in local.instance_specs : 
    "${spec.service_name}-${spec.instance_num}" => spec
  }
}

resource "aws_instance" "service_expanded" {
  for_each = local.instances_map
  
  ami               = data.aws_ami.latest.id
  instance_type     = "t3.micro"
  security_groups   = [aws_security_group.main.id]
  availability_zone = element(var.azs, each.value.instance_num % length(var.azs))
  
  tags = {
    "Service" = each.value.service_name
    "Instance" = "instance-${each.value.instance_num}"
  }
}

# Outputs
output "service_target_groups" {
  value = {
    for name, tg in aws_lb_target_group.service : 
    name => {
      arn  = tg.arn
      port = tg.port
    }
  }
}

output "instance_ids_by_service" {
  value = {
    for service in keys(local.active_services) : service => [
      for instance_key, instance in aws_instance.service_expanded : 
      instance.id
      if strcontains(instance_key, service)
    ]
  }
}
```

### ASCII Diagrams

#### Diagram 1: Count vs. For_Each State Management

```
count Mechanism (Index-Based):
═════════════════════════════

  Version 1: resources with count.index
  ┌─────────────────────────────────┐
  │ aws_instance.web[0]             │
  │ aws_instance.web[1]             │
  │ aws_instance.web[2]             │
  └─────────────────────────────────┘

  User removes element 1 from variable → index shift!
  ┌─────────────────────────────────┐
  │ aws_instance.web[0] (same)      │
  │ aws_instance.web[1] (WAS [2]!)  │ ← Unintended replacement
  └─────────────────────────────────┘


for_each Mechanism (Key-Based):
═══════════════════════════════

  Version 1: resources with for_each key
  ┌──────────────────────────────────┐
  │ aws_instance.web["primary"]      │
  │ aws_instance.web["secondary"]    │
  │ aws_instance.web["tertiary"]     │
  └──────────────────────────────────┘

  User removes "secondary" → no shift!
  ┌──────────────────────────────────┐
  │ aws_instance.web["primary"]      │ (unchanged)
  │ aws_instance.web["tertiary"]     │ (unchanged)
  └──────────────────────────────────┘
                                      ✓ Safe update
```

#### Diagram 2: Dynamic Block Expansion Flow

```
Dynamic Block Processing Pipeline:
══════════════════════════════════

  Configuration Input (from variables)
         ↓
  ┌─────────────────────────────┐
  │ security_rules = [          │
  │  { port: 443, proto: tcp }  │
  │  { port: 80,  proto: tcp }  │
  │  { port: 3306, proto: tcp } │
  │ ]                           │
  └─────────────────────────────┘
         ↓
    Parse Phase
         ↓
  ┌─────────────────────────────┐
  │ dynamic "ingress" {         │
  │   for_each = security_rules │
  │   content { ... }           │
  │ }                           │
  └─────────────────────────────┘
         ↓
  Expansion Phase (Terraform renders)
         ↓
  ┌─────────────────────────────┐
  │ ingress {                   │
  │   from_port = 443           │ ← Dynamic Block 1
  │   protocol = "tcp"          │
  │ }                           │
  │ ingress {                   │
  │   from_port = 80            │ ← Dynamic Block 2
  │   protocol = "tcp"          │
  │ }                           │
  │ ingress {                   │
  │   from_port = 3306          │ ← Dynamic Block 3
  │   protocol = "tcp"          │
  │ }                           │
  └─────────────────────────────┘
         ↓
    Resource Instance (as rendered above)
         ↓
    Applied to AWS
```

#### Diagram 3: Resource Lifecycle with Conditional Creation

```
Conditional Resource Lifecycle:
════════════════════════════════

  Input: var.create_resource = true

  Terraform Plan Phase
  ┌────────────────────────────────┐
  │ count = var.create_resource ? 1 : 0
  │                                │
  │ count = 1 (evaluated to true) │
  │                                │
  │ Resource instance [0] planned  │
  └────────────────────────────────┘
           ↓
    terraform apply
           ↓
  Resource Created Successfully
  ┌────────────────────────────────┐
  │ aws_instance.main[0] (RUNNING) │
  └────────────────────────────────┘


  Later: var.create_resource = false

  Terraform Plan Phase
  ┌────────────────────────────────┐
  │ count = var.create_resource ? 1 : 0
  │                                │
  │ count = 0 (evaluated to false)│
  │                                │
  │ Resource instance [0] planned  │
  │ for DESTRUCTION                │
  └────────────────────────────────┘
           ↓
    terraform apply
           ↓
  Resource Destroyed
  ┌────────────────────────────────┐
  │ aws_instance.main[0] (DELETED) │
  └────────────────────────────────┘
```

---

## Module State Management and Isolation

### Textual Deep Dive

#### Architecture Role

Module state management determines how Terraform tracks infrastructure and manages updates across multiple deployments. At the senior level, this involves understanding:

- **State file organization** and its impact on team collaboration
- **Shared vs. isolated state** trade-offs
- **Backend configuration** for modules in enterprise contexts
- **State locking** and concurrent execution challenges
- **State migration** strategies during refactoring

#### Internal Working Mechanism

**Module State Storage**:

All resources in a Terraform root module share the same state file:

```
terraform apply
    ↓
Root Module State File (terraform.tfstate)
    ├── Resources from Module A
    ├── Resources from Module B
    └── Resources from Module C
         ↓
    Single state tracking all infrastructure
```

**State Structure**:

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "serial": 42,
  "lineage": "unique-id",
  "outputs": {
    "vpc_id": { "value": "vpc-12345" }
  },
  "resources": [
    {
      "module": "module.vpc",
      "type": "aws_vpc",
      "name": "main",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "vpc-12345",
            "cidr_block": "10.0.0.0/16"
          }
        }
      ]
    }
  ]
}
```

**Backend Configuration**:

Modules use the backend configured in the root module:

```hcl
# Root module configures backend (modules don't have their own backends)
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# Module (no backend configuration here)
module "vpc" {
  source = "./modules/vpc"
  # Resources stored in root's S3 backend
}
```

**Locking Mechanism**:

When Terraform acquires a lock:

```
terraform apply
    ↓
Backend: "Acquire lock"
    ↓
DynamoDB: dynamodb_table = "terraform-locks"
Item: { "ID": "prod/terraform.tfstate", "Digest": "hash", LockID" }
    ↓
State locked (other processes wait)
    ↓
Infrastructure changes applied
    ↓
Backend: "Release lock"
    ↓
Lock removed, others can proceed
```

#### Production Usage Patterns

**Pattern 1: Monolithic State (Simple Organizations)**

```
Single State File
├── VPC Module
├── EKS Module
├── RDS Module
└── Monitoring Module

Benefits:
- Simple mental model
- Easy to understand dependencies
- Single apply operation

Drawbacks:
- Large state file (slow operations)
- Any change triggers full plan
- Risk: Single mistake affects all resources
- Concurrency: State locks block all teams
```

**Pattern 2: Layered State (Scaling Organizations)**

```
Layer 1: Foundation (rarely changes)
└── foundation.tfstate
    ├── VPC
    ├── Subnets
    └── NAT Gateways

Layer 2: Platform (changes monthly)
└── platform.tfstate
    ├── RDS Clusters
    ├── ElastiCache
    └── Security Groups

Layer 3: Applications (changes daily)
└── applications.tfstate
    ├── EKS Node Groups
    ├── Lambda Functions
    └── Application Load Balancers

Layer 4: Secrets & Configuration (changes frequently)
└── secrets.tfstate
    ├── Secrets Manager
    └── Parameter Store
```

Each layer:
- Has independent state file
- Can be managed independently
- References other layers through data sources or Terraform outputs

**Pattern 3: Per-Environment Isolation**

```
Production
├── prod/vpc/terraform.tfstate
├── prod/eks/terraform.tfstate
└── prod/databases/terraform.tfstate

Staging
├── staging/vpc/terraform.tfstate
├── staging/eks/terraform.tfstate
└── staging/databases/terraform.tfstate

Development
├── dev/vpc/terraform.tfstate
├── dev/eks/terraform.tfstate
└── dev/databases/terraform.tfstate

Benefits:
- Environment mistakes don't cascade
- Different approval processes per environment
- Independent scaling and resource sizing
- Easier rollback (environment-scoped)
```

**Pattern 4: Per-Team Isolation (Enterprise)**

```
Platform Team
└── shared/terraform.tfstate
    (VPC, networking, security foundation)

Team A
├── team-a/applications.tfstate
│   (Databases, compute, load balancers)
└── Data source references: shared.vpc_id

Team B
├── team-b/applications.tfstate
│   (Databases, compute, load balancers)
└── Data source references: shared.vpc_id

Team C
├── team-c/applications.tfstate
│   (Databases, compute, load balancers)
└── Data source references: shared.vpc_id
```

#### DevOps Best Practices

**1. State File Encryption and Isolation**

```hcl
# ✅ Encrypted backend for sensitive state
terraform {
  backend "s3" {
    bucket              = "company-terraform-state"
    key                 = "prod/infrastructure.tfstate"
    region              = "us-east-1"
    encrypt             = true                    # Encrypt at rest
    dynamodb_table      = "terraform-locks"
    workspace_key_prefix = "env"
  }
}

# ✅ Restrict access via S3 bucket policy
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "state" {
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
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

# ✅ Enable versioning for rollback capability
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

**2. State Isolation by Environment**

```hcl
# Root module structure
environments/
├── dev/
│   ├── main.tf
│   └── backend.tf          # Different backend per environment
├── staging/
│   ├── main.tf
│   └── backend.tf
└── prod/
    ├── main.tf
    └── backend.tf

# backend.tf for dev
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "dev/terraform.tfstate"
  }
}

# backend.tf for prod
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "prod/terraform.tfstate"
  }
}
```

**3. State Locking for Concurrent Safety**

```hcl
# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    "Name" = "Terraform State Locks"
  }
}

# Backend configured with locking
terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    dynamodb_table = "terraform-locks"  # Enables state locking
  }
}
```

**4. Cross-Module Dependencies via Data Sources**

```hcl
# Foundation layer creates VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { "Name" = "prod-vpc" }
}

# Application layer (separate state) references foundation
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc"]
  }
}

module "eks" {
  source = "./modules/eks"
  vpc_id = data.aws_vpc.main.id  # Decoupled via data source
}
```

#### Common Pitfalls

**Pitfall 1: Monolithic State in Large Organizations**

```
Problem: Single state file with all resources
├── 5 teams
├── 100+ resources
├── Different change frequencies
└── Single merge bottleneck

Consequence:
- Team A deploys: acquires state lock (blocks all others)
- Team B, C, D wait (frustrated, slow iteration)
- Merge conflicts in state: manual resolution needed
- One mistake affects everyone

Solution: Implement layered state isolation
```

**Pitfall 2: State Lock Timeout**

```
Problem: Process acquires lock, crashes without releasing

terraform apply (acquires lock)
  │
  └─→ Error: Timeout waiting for lock

Other processes:
  terraform apply (waiting for lock)
    → Timeout: State locked for 30+ minutes
    → Manual intervention needed: `terraform force-unlock <ID>`

Prevention:
- Use short-lived state locks (5-10 minute timeout)
- Terraform Cloud/Enterprise auto-releases on process death
- Monitoring and alerting on stuck locks
```

**Pitfall 3: State File Drift**

```
Problem: Manual AWS console changes bypass Terraform

AWS Console:
  └─→ Manually modify security group rule

Terraform State:
  └─→ Still shows old rule

Result:
  terraform apply
    → Replaces rule (destructive)
    → Causes downtime/data loss

Prevention:
- Regular `terraform plan` to detect drift
- Restrict manual AWS changes (IAM policies)
- Use Terraform Cloud policy enforcement
- Regular drift detection audits
```

---

### Practical Code Examples

#### Example 1: Multi-Layer State Architecture

```hcl
# Foundation Layer (rarely changes)
# infrastructure/foundation/main.tf

terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "prod/foundation.tfstate"
    encrypt = true
  }
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { "Name" = "prod-vpc", "Layer" = "foundation" }
}

resource "aws_subnet" "public" {
  count = length(var.availability_zones)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone = var.availability_zones[count.index]
  
  tags = { "Name" = "prod-public-${count.index + 1}" }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

---

# Platform Layer (moderate change frequency)
# infrastructure/platform/main.tf

terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "prod/platform.tfstate"
    encrypt = true
  }
}

# Reference foundation layer via data source
data "aws_vpc" "foundation" {
  filter {
    name   = "tag:Layer"
    values = ["foundation"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.foundation.id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["prod-public-*"]
  }
}

module "eks" {
  source = "../../modules/eks"
  
  cluster_name = "prod-cluster"
  vpc_id       = data.aws_vpc.foundation.id
  subnet_ids   = data.aws_subnets.public.ids
  
  node_count = var.node_count
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.endpoint
}

---

# Application Layer (frequent changes)
# infrastructure/applications/main.tf

terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "prod/applications.tfstate"
    encrypt = true
  }
}

# Reference foundation and platform via data sources
data "aws_eks_cluster" "main" {
  name = var.eks_cluster_name  # Passed in from platform layer output
}

data "aws_eks_cluster_auth" "main" {
  name = data.aws_eks_cluster.main.name
}

module "app_deployment" {
  source = "../../modules/kubernetes-deployment"
  
  cluster_name       = data.aws_eks_cluster.main.name
  cluster_endpoint   = data.aws_eks_cluster.main.endpoint
  cluster_ca_cert    = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  cluster_token      = data.aws_eks_cluster_auth.main.token
  
  app_name     = var.app_name
  docker_image = var.docker_image
  replicas     = var.replicas
}
```

#### Example 2: State Isolation by Environment with Cross-Environment References

```hcl
# environments/shared/main.tf (never destroyed)
terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "shared/main.tfstate"
    encrypt = true
  }
}

resource "aws_s3_bucket" "artifact_repository" {
  bucket = "company-artifacts-${var.account_id}"
}

output "artifact_bucket_name" {
  value = aws_s3_bucket.artifact_repository.id
}

output "artifact_bucket_arn" {
  value = aws_s3_bucket.artifact_repository.arn
}

---

# environments/prod/main.tf (production isolation)
terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "prod/main.tfstate"
    encrypt = true
  }
}

# Read shared artifacts bucket
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "shared/main.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source = "../../modules/vpc"
  
  environment            = "prod"
  artifact_bucket_arn    = data.terraform_remote_state.shared.outputs.artifact_bucket_arn
  enable_artifact_access = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

---

# environments/dev/main.tf (development isolation)
terraform {
  backend "s3" {
    bucket = "company-terraform-state"
    key    = "dev/main.tfstate"
    encrypt = true
  }
}

# Same shared reference
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "company-terraform-state"
    key    = "shared/main.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source = "../../modules/vpc"
  
  environment            = "dev"
  artifact_bucket_arn    = data.terraform_remote_state.shared.outputs.artifact_bucket_arn
  enable_artifact_access = true
}
```

### ASCII Diagrams

#### Diagram 1: Monolithic vs. Layered State Architecture

```
MONOLITHIC STATE (Anti-Pattern at Scale):
═════════════════════════════════════════

terraform.tfstate (Single File)
├── VPC Resources (managed by Team Network)
├── RDS Databases (managed by Team Data)
├── EKS Cluster (managed by Team Platform)
├── Lambda Functions (managed by Team Apps)
└── Monitoring (managed by Team Ops)

Problems:
  Team Network → apply  ─┐
  (acquires lock)       │
                        ├─→ Only one can proceed
  Team Data → apply  ─┬┘   All others wait
  (waits for lock)    └────→ Blocked

  State conflicts: Hard to merge changes


LAYERED STATE (Enterprise Pattern):
═══════════════════════════════════

foundation.tfstate          platform.tfstate         applications.tfstate
├── VPC                     ├── RDS                   ├── Deployments
├── Subnets         ──────→ ├── ElastiCache    ──────→ ├── Services
├── NAT Gateways    Refs    ├── Security Groups Refs   └── Ingresses
└── IGW                     └── EKS Control Plane

Benefits:
  Team Network → foundation.tfstate (locks only foundation)
  Team Data → platform.tfstate (locks only platform)
  Team Apps → applications.tfstate (locks only applications)
                    ↓
                 Concurrent work!
```

#### Diagram 2: State Lock Acquisition and Release

```
State Lock Timeline:
═══════════════════

Time  Process              State Lock Status        DynamoDB
──────────────────────────────────────────────────────────────
0:00  terraform apply      ✗ Unlocked              (empty)
        (starts)           
                           
0:01  → Acquire Lock       ◐ Acquiring...          (acquiring)
                           
0:02  Lock Acquired ✓      ◉ LOCKED                {
                                                     "LockID": "key",
0:03  Apply changes        ◉ LOCKED                  "Info": "TF 1.5",
      to infrastructure    (exclusive access)       "Digest": "hash",
                                                     "Path": "prod/state"
0:04  Apply completes      ◉ LOCKED                }
                           
0:05  Release Lock         ◐ Releasing...          (releasing)
                           
0:06  Unlocked ✓           ✗ Unlocked              (empty)


Other process attempts during lock:
───────────────────────────────────

0:02  terraform plan       ✗ (on other machine)
        (starts)           
                           
0:02  → Request Lock       ⏳ WAITING               (lock exists)
                           
0:03  Still waiting...     ⏳ WAITING               (lock exists)
                                                    
0:04  Still waiting...     ⏳ WAITING               (lock exists)
                                                    
0:06  Lock Released ✓      

0:06  → Acquire Lock ✓     ◉ LOCKED                (now has lock)
```

---

## Module Testing and Validation

### Textual Deep Dive

#### Architecture Role

Module testing ensures infrastructure code is correct, safe, and maintainable before deployment. At the senior level, testing encompasses:

- **Syntax and type validation** (`terraform validate`)
- **Variable validation** (input constraints)
- **Policy enforcement** (company standards)
- **Integration testing** (module behavior with real resources)
- **Compliance testing** (security, regulatory requirements)

#### Internal Working Mechanism

**Validation Layers**:

```
Terraform Code
    ↓
Layer 1: Syntax Validation
  (terraform validate)
  └→ Checks HCL syntax, required provider declarations
    ↓
Layer 2: Type Checking
  (Terraform type system)
  └→ Variable types match usage, output types consistent
    ↓
Layer 3: Variable Validation
  (validation blocks)
  └→ Custom constraints on input values
    ↓
Layer 4: Policy Validation
  (Sentinel / OPA)
  └→ Organization standards enforced
    ↓
Layer 5: Integration Testing
  (terraform test / external tools)
  └→ Actual deployment and verification
```

#### Production Usage Patterns

**Pattern 1: CI/CD Testing Pipeline**

```hcl
# .github/workflows/terraform-test.yml
name: Terraform Module Tests

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
      
      - name: Terraform Validate
        run: |
          for dir in modules/*/; do
            terraform -chdir="$dir" init -backend=false
            terraform -chdir="$dir" validate
          done
      
      - name: TFLint
        uses: terraform-linters/setup-tflint@v3
        with:
          tflint_version: latest
      
      - name: Run TFLint
        run: tflint --recursive --format compact
      
      - name: Policy as Code (Sentinel)
        run: |
          sentinel test -run=policies
```

**Pattern 2: Module-Level Testing (Terraform 1.6+)**

```hcl
# tests/vpc_module_test.tftest.hcl

run "vpc_creation_succeeds" {
  command = apply
  
  variables {
    cidr_block = "10.0.0.0/16"
    environment = "test"
  }
  
  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block not set correctly"
  }
  
  assert {
    condition     = aws_vpc.main.enable_dns_hostnames == true
    error_message = "DNS hostnames not enabled"
  }
}

run "invalid_cidr_validation_fails" {
  command = plan
  
  variables {
    cidr_block = "invalid-cidr"
    environment = "test"
  }
  
  expect_failures = [
    var.cidr_block
  ]
}
```

#### DevOps Best Practices

**1. Input Validation First**

```hcl
variable "instance_type" {
  type = string
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large"
    ], var.instance_type)
    error_message = "Instance type must be from approved list"
  }
}

variable "environment" {
  type = string
  validation {
    condition     = can(regex("^(dev|staging|prod)$", var.environment))
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "tag_environment" {
  type = string
  validation {
    condition = length(var.tag_environment) <= 20
    error_message = "Tag value cannot exceed 20 characters"
  }
}
```

**2. Comprehensive Code Formatting**

```bash
# Ensure consistent formatting
terraform fmt -recursive

# Validate formatting in CI/CD
terraform fmt -recursive -check

# Auto-format on save in IDE
```

**3. Linting with TFLint**

```hcl
# .tflint.hcl
config {
  module = true
  force  = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  tags    = ["Environment", "Name", "ManagedBy"]
}
```

**4. Policy as Code (Sentinel)**

```hcl
# policies/enforce_encryption.sentinel
import "tfplan/v2" as tfplan

main = rule {
  all_rds_encrypted and
  all_s3_encrypted
}

# Check RDS encryption
all_rds_encrypted = rule {
  all tfplan.resources.aws_db_instance as db {
    db.change.after.storage_encrypted is true
  }
}

# Check S3 encryption
all_s3_encrypted = rule {
  all tfplan.resources.aws_s3_bucket as bucket {
    bucket.change.after.sse_algorithm is not null
  }
}
```

#### Common Pitfalls

**Pitfall 1: Insufficient Input Validation**

```hcl
# ❌ Bad: No validation
variable "port" {
  type = number
}

# User provides:
port = 99999  # Invalid!

# Only caught at apply time when AWS rejects it

# ✅ Good: Validate early
variable "port" {
  type = number
  
  validation {
    condition     = var.port > 0 && var.port <= 65535
    error_message = "Port must be between 1 and 65535"
  }
}

# Error caught during plan, user fixes immediately
```

**Pitfall 2: Testing Only Happy Path**

```hcl
# ❌ Tests only success: missing validation failures
run "vpc_creation" {
  variables {
    cidr_block = "10.0.0.0/16"
  }
}

# ✅ Also test failure cases
run "invalid_cidr_rejected" {
  command = plan
  variables {
    cidr_block = "not-a-cidr"
  }
  expect_failures = [var.cidr_block]
}

run "negative_count_rejected" {
  command = plan
  variables {
    instance_count = -1
  }
  expect_failures = [var.instance_count]
}
```

**Pitfall 3: No Integration Testing**

```bash
# ❌ Only validate HCL
terraform validate
terraform fmt

# ✅ Also test real infrastructure
terraform init
terraform plan  # Verify plan is sensible
terraform apply # Create real resources
terraform destroy # Cleanup

# Or use Terraform Cloud test environments
```

---

### Practical Code Examples

#### Example 1: Comprehensive Validation Setup

```hcl
# modules/secure-rds/variables.tf

variable "identifier" {
  type = string
  description = "RDS instance identifier"
  
  validation {
    condition = can(regex("^[a-z0-9-]{1,63}$", var.identifier))
    error_message = "Identifier must contain only lowercase letters, numbers, and hyphens (max 63 chars)"
  }
}

variable "engine" {
  type = string
  description = "Database engine (mysql, postgres, mariadb)"
  
  validation {
    condition = contains(["mysql", "postgres", "mariadb"], var.engine)
    error_message = "Engine must be mysql, postgres, or mariadb"
  }
}

variable "instance_class" {
  type = string
  description = "DB instance class"
  
  validation {
    condition = can(regex("^db\\.(t3|t4g|m6i)[a-z]*\\.[a-z0-9]+$", var.instance_class))
    error_message = "Instance class must be from approved families (t3, t4g, m6i)"
  }
}

variable "allocated_storage" {
  type = number
  description = "Allocated storage in GB"
  
  validation {
    condition = var.allocated_storage >= 20 && var.allocated_storage <= 65536
    error_message = "Storage must be between 20 and 65536 GB"
  }
}

variable "backup_retention_days" {
  type = number
  description = "Backup retention days"
  default = 30
  
  validation {
    condition = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be 7-35 days (compliance requirement)"
  }
}

variable "environment" {
  type = string
  description = "Environment (dev, staging, prod)"
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "multi_az" {
  type = bool
  description = "Enable Multi-AZ deployment"
  
  validation {
    condition = var.environment != "prod" || var.multi_az == true
    error_message = "Production databases must have Multi-AZ enabled"
  }
}

variable "skip_final_snapshot" {
  type = bool
  default = false
  
  validation {
    condition = var.environment != "prod" || var.skip_final_snapshot == false
    error_message = "Production databases must create final snapshots"
  }
}

# ...rest of module
```

#### Example 2: Terraform Test File

```hcl
# tests/rds_secure_deployment.tftest.hcl

run "setup" {
  command = apply
}

run "valid_prod_config" {
  command = apply
  
  variables {
    identifier                = "prod-database"
    engine                    = "postgres"
    instance_class            = "db.t4g.large"
    allocated_storage         = 100
    backup_retention_days     = 30
    environment               = "prod"
    multi_az                  = true
    skip_final_snapshot       = false
  }
  
  assert {
    condition     = aws_db_instance.main.multi_az == true
    error_message = "Production should be Multi-AZ"
  }
  
  assert {
    condition     = aws_db_instance.main.backup_retention_period == 30
    error_message = "Backup retention should be 30 days"
  }
  
  assert {
    condition     = aws_db_instance.main.skip_final_snapshot == false
    error_message = "Final snapshot should not be skipped"
  }
}

run "invalid_prod_single_az_fails" {
  command = plan
  
  variables {
    identifier                = "prod-database"
    engine                    = "postgres"
    instance_class            = "db.t4g.large"
    allocated_storage         = 100
    backup_retention_days     = 30
    environment               = "prod"
    multi_az                  = false  # Invalid for prod!
    skip_final_snapshot       = false
  }
  
  expect_failures = [
    var.multi_az
  ]
}

run "invalid_prod_no_backup_fails" {
  command = plan
  
  variables {
    identifier                = "prod-database"
    engine                    = "postgres"
    instance_class            = "db.t4g.large"
    allocated_storage         = 100
    backup_retention_days     = 30
    environment               = "prod"
    multi_az                  = true
    skip_final_snapshot       = true  # Invalid for prod!
  }
  
  expect_failures = [
    var.skip_final_snapshot
  ]
}

run "invalid_identifier_format" {
  command = plan
  
  variables {
    identifier                = "INVALID_NAME"  # Uppercase not allowed
    engine                    = "postgres"
    instance_class            = "db.t4g.large"
    allocated_storage         = 100
    backup_retention_days     = 30
    environment               = "dev"
    multi_az                  = false
    skip_final_snapshot       = false
  }
  
  expect_failures = [
    var.identifier
  ]
}

run "storage_too_small" {
  command = plan
  
  variables {
    identifier                = "dev-database"
    engine                    = "postgres"
    instance_class            = "db.t4g.large"
    allocated_storage         = 10  # Below minimum of 20
    backup_retention_days     = 30
    environment               = "dev"
    multi_az                  = false
    skip_final_snapshot       = false
  }
  
  expect_failures = [
    var.allocated_storage
  ]
}
```

#### Example 3: TFLint Configuration

```hcl
# .tflint.hcl

config {
  module      = true
  force       = false
  format      = "compact"
  plugin_dir  = "~/.tflint.d/plugins"
  
  ignore_module = {
    "terraform-aws-modules/vpc/aws" = true
  }
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  
  convention = "snake_case"
  
  const   = "SCREAMING_SNAKE_CASE"
  module  = "snake_case"
  variable = "snake_case"
  resource = "snake_case"
  
  format = "^[a-z_][a-z0-9_]*$"
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_redundant_arguments" {
  enabled = true
}

rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_invalid_ami" {
  enabled = true
}

rule "aws_resource_missing_tags" {
  enabled = true
  
  tags = [
    "Environment",
    "Name",
    "ManagedBy",
    "CostCenter"
  ]
  
  exclude = [
    "aws_iam_policy",
    "aws_iam_role",
    "aws_iam_role_policy"
  ]
}

rule "aws_s3_bucket_server_side_encryption_configuration" {
  enabled = true
}

rule "aws_db_instance_publicly_accessible" {
  enabled = true
}

rule "aws_security_group_rule_in_sg" {
  enabled = true
}
```

### ASCII Diagrams

#### Diagram 1: Testing and Validation Layers

```
Code Change
    ↓
┌─────────────────────────────────────────┐
│ Layer 1: Terraform Validate             │
│ (terraform validate)                    │
│ ✓ HCL syntax correct                    │
│ ✓ Provider declarations present         │
│ ✓ No undefined references               │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Layer 2: Code Formatting                │
│ (terraform fmt)                         │
│ ✓ Consistent indentation                │
│ ✓ Consistent style                      │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Layer 3: Type System                    │
│ (Type checking)                         │
│ ✓ Variable types match declarations     │
│ ✓ Output types consistent               │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Layer 4: Input Validation               │
│ (validation blocks)                     │
│ ✓ CIDR blocks valid                     │
│ ✓ Port ranges correct                   │
│ ✓ Environment constraints met           │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Layer 5: Linting                        │
│ (TFLint)                                │
│ ✓ AWS best practices                    │
│ ✓ Resource naming conventions           │
│ ✓ Required tags present                 │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Layer 6: Policy as Code                 │
│ (Sentinel / OPA)                        │
│ ✓ Encryption required                   │
│ ✓ Public access blocked                 │
│ ✓ Compliance standards met              │
└─────────────────────────────────────────┘
    ↓
┌─────────────────────────────────────────┐
│ Layer 7: Integration Testing            │
│ (terraform test / real deployment)      │
│ ✓ Resources create successfully         │
│ ✓ Outputs have correct values           │
│ ✓ Actual infrastructure works           │
└─────────────────────────────────────────┘
    ↓
   ✓ PASS - Code ready for production
```

#### Diagram 2: Input Validation Early Detection

```
Validation Happens Early (in plan phase):
═════════════════════════════════════════

terraform plan
    ↓
Parse variables
    ↓
Evaluate validation{} blocks
    ↓
    ├─ variable.environment == contains(["dev", "staging", "prod"])?
    │  └─ ❌ FAIL: environment = "invalid"
    │
    ├─ variable.port in range 1-65535?
    │  └─ ✓ PASS: port = 8080
    │
    └─ variable.pod_count >= 1?
       └─ ❌ FAIL: pod_count = -5

Error Output:
═════════════

Error: Invalid value for variable "environment":
  on variables.tf line 5, in variable "environment":
   5: variable "environment" {

Environment must be: dev, staging, or prod

Error: Invalid value for variable "pod_count":
  on variables.tf line 23, in variable "pod_count":
  23: variable "pod_count" {

Pod count must be positive (1 or greater)

← Errors caught BEFORE any AWS API calls
← User fixes immediately
← No wasted time on failed apply
```

---

## Module Security and Best Practices

### Textual Deep Dive

#### Architecture Role

Module security encompasses:
- **Access control**: Who can view/modify/use modules
- **Secrets management**: Handling sensitive data safely
- **Compliance enforcement**: Meeting regulatory requirements
- **Audit trails**: Tracking changes and usage
- **Supply chain security**: Ensuring module integrity

#### Internal Working Mechanism

**Access Control Layers**:

```
Public Registry
    ↓
Anyone with network access can view/download

Private Registry (Terraform Cloud/Enterprise)
    ↓
├─ Authentication (API tokens, OAuth)
└─ Authorization (team-based access)

Git Repository
    ↓
├─ Branch protection
├─ Code review requirements
└─ RBAC (role-based access control)
```

#### Production Usage Patterns

**Pattern 1: Secrets Management**

```hcl
# ❌ NEVER: Secrets in modules
resource "aws_db_instance" "main" {
  password = "hardcoded-password-123"  # Exposed in code, state, logs!
}

# ✅ GOOD: Use AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "rds/prod/password-"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

resource "aws_db_instance" "main" {
  password = random_password.db.result  # Generated, not hardcoded
  
  depends_on = [
    aws_secretsmanager_secret_version.db_password
  ]
}

output "secret_name" {
  value       = aws_secretsmanager_secret.db_password.name
  description = "Applications retrieve actual secret from Secrets Manager"
}
```

**Pattern 2: IAM Role Least Privilege**

```hcl
# Module creates resources and IAM roles
module "app" {
  source = "../../modules/application"
  
  app_name = "myapp"
}

# Minimal IAM policy for the application
resource "aws_iam_policy" "app_policy" {
  name = "myapp-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.app_data.arn}/myapp/*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = module.app.secret_arns
      }
    ]
  })
}
```

**Pattern 3: Audit Logging**

```hcl
# Enable CloudTrail for all infrastructure changes
resource "aws_cloudtrail" "terraform_changes" {
  name                          = "terraform-infrastructure-changes"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail]
  
  event_selector {
    read_write_type = "All"
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*"]
    }
  }
}

# Log all Terraform state changes
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  
  target_bucket = aws_s3_bucket.state_logs.id
  target_prefix = "terraform-state-logs/"
}
```

#### DevOps Best Practices

**1. Module Source Verification**

```hcl
# ✅ Verify module source fingerprint
module "vpc" {
  source = "git::https://github.com/company/terraform-modules.git//vpc?ref=v2.5.0"
  
  # In CI/CD, verify GPG signature:
  # git verify-commit v2.5.0
}

# ✅ Use official sources with version constraints
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"  # Locked to prevent tampering via version
}

# ❌ Never use 'latest' or unversioned sources
module "rds" {
  source = "git::https://github.com/malicious-user/modules.git//rds"
  # Could pull modified code, no version pinning
}
```

**2. Sensitive Output Masking**

```hcl
output "db_password" {
  value       = random_password.db.result
  sensitive   = true  # Masked in logs and outputs
  description = "Use aws secretsmanager get-secret-value to retrieve"
}

output "api_token" {
  value       = aws_secretsmanager_secret.api_token.id
  sensitive   = true  # Hide the secret reference
}

output "connection_string" {
  value       = "postgresql://user:****@${aws_db_instance.main.endpoint}/db"
  sensitive   = true  # Redact sensitive parts
}
```

**3. Supply Chain Security**

```
Module Verification Process:
═════════════════════════════

1. Code Review
   └─ Team review + approval required

2. Automated Testing
   └─ Syntax, lint, type check, policy validation

3. Security Scanning
   ├─ SAST (static analysis for vulnerabilities)
   ├─ Dependency scanning (vulnerable packages)
   └─ Secret scanning (hardcoded credentials)

4. Signed Release
   └─ Git tag signed with GPG
   └─ Terraform Cloud registry entry verified

5. Access Control
   └─ Module only available to authorized teams
   └─ Audit logging of usage

6. Usage Monitoring
   └─ Alert on unexpected module usage
   └─ Track which teams pull which modules
```

#### Common Pitfalls

**Pitfall 1: Credentials in State Files**

```hcl
# ❌ DANGEROUS
resource "aws_db_instance" "main" {
  password = var.db_password  # Variable passed from tfvars
}

# terraform.tfvars contains:
# db_password = "production-secret-123"

# Problem: terraform.tfstate now contains the password in plaintext
# Anyone with state file access gets the password!

# ✅ BETTER
resource "aws_db_instance" "main" {
  password = random_password.db.result
}

resource "aws_secretsmanager_secret" "db_password" {
  secret_string = random_password.db.result
}

# State still has password, but:
# - It's auto-generated (not hardcoded)
# - Actual secret stored in Secrets Manager
# - State can be encrypted
```

**Pitfall 2: Overly Permissive IAM Policies**

```hcl
# ❌ DANGEROUS: Wildcard permissions
resource "aws_iam_policy" "app" {
  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"         # All actions
        Resource = "*"         # All resources
      }
    ]
  })
}

# ✅ BETTER: Specific permissions
resource "aws_iam_policy" "app" {
  policy = jsonencode({
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.app.arn}/data/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:region:account:log-group:/ecs/app/*"
      }
    ]
  })
}
```

**Pitfall 3: Public Infrastructure by Mistake**

```hcl
# ❌ DANGEROUS: Database publicly accessible
resource "aws_db_instance" "main" {
  publicly_accessible = true  # Exposed to internet!
}

# ✅ BETTER: Private + bastion host
resource "aws_db_instance" "main" {
  publicly_accessible = false  # Private only
  db_subnet_group_name = aws_db_subnet_group.private.name
}

# Validate in module
variable "publicly_accessible" {
  type    = bool
  default = false  # Safe default
  
  validation {
    condition     = var.environment != "prod" || var.publicly_accessible == false
    error_message = "Production databases cannot be publicly accessible"
  }
}
```

---

### Practical Code Examples

#### Example 1: Secure Module with Encryption and Access Control

```hcl
# modules/secure-storage/main.tf

variable "environment" { type = string }
variable "bucket_name" { type = string }
variable "allowed_users" { type = list(string) }

# S3 bucket with all security best practices
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable logging
resource "aws_s3_bucket_logging" "main" {
  bucket = aws_s3_bucket.main.id
  
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# MFA delete protection
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

# Restrict access to specific users
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceSSLOnly"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowSpecificUsers"
        Effect = "Allow"
        Principal = {
          AWS = [for user in var.allowed_users : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${user}"]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      }
    ]
  })
}

output "bucket_name" {
  value       = aws_s3_bucket.main.id
  description = "S3 bucket name (secured)"
}

output "bucket_arn" {
  value       = aws_s3_bucket.main.arn
  description = "S3 bucket ARN"
}
```

#### Example 2: Module with Secrets Management

```hcl
# modules/application/main.tf

variable "app_name" { type = string }
variable "environment" { type = string }
variable "container_image" { type = string }

# Generate secure random password
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Store password securely in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix             = "${var.environment}/${var.app_name}/db-password-"
  recovery_window_in_days = 7  # Prevent accidental deletion
  
  tags = { "Application" = var.app_name }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# Generate API key
resource "random_password" "api_key" {
  length  = 48
  special = true
}

resource "aws_secretsmanager_secret" "api_key" {
  name_prefix             = "${var.environment}/${var.app_name}/api-key-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = random_password.api_key.result
}

# ECS Task with access to secrets
resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([{
    name      = var.app_name
    image     = var.container_image
    essential = true
    
    # Secrets passed as environment variables
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = aws_secretsmanager_secret.db_password.arn
      },
      {
        name      = "API_KEY"
        valueFrom = aws_secretsmanager_secret.api_key.arn
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = var.app_name
      }
    }
  }])
}

# IAM role allowing ECS to read secrets
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  role = aws_iam_role.ecs_task_execution_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.db_password.arn,
          aws_secretsmanager_secret.api_key.arn
        ]
      }
    ]
  })
}

# Outputs (secrets themselves are never output)
output "db_secret_name" {
  value       = aws_secretsmanager_secret.db_password.name
  sensitive   = true
  description = "Name of secret containing DB password"
}

output "api_key_secret_name" {
  value       = aws_secretsmanager_secret.api_key.name
  sensitive   = true
  description = "Name of secret containing API key"
}

output "app_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ECS task role ARN (for attaching policies)"
}
```

### ASCII Diagrams

#### Diagram 1: Secrets Flow (Correct vs. Incorrect)

```
❌ INSECURE: Secrets in State File
═════════════════════════════════════

Terraform Code
    ↓
variable "db_password" = "secret123"
    ↓
resource "aws_db_instance"
    password = "secret123"
    ↓
terraform.tfstate (JSON file)
    ├─ PLAIN TEXT: "password": "secret123"
    │
    ├─ Copied to S3 ✓
    ├─ Backed up ✓
    ├─ Versioned ✓
    └─ Team members can read ✓
    
Result: Password leaked everywhere!


✓ SECURE: Secrets in Secrets Manager
═════════════════════════════════════

Terraform Code
    ↓
random_password → aws_secretsmanager_secret
    ↓
State File
    ├─ resource "aws_secretsmanager_secret"
    └─ arn: "arn:aws:secretsmanager:..."
    
Secrets Manager (AWS-managed)
    ├─ Encrypted key vault
    ├─ Audit logging
    ├─ Rotation policies
    └─ Access control
    
Application
    └─ Queries Secrets Manager at runtime
        └─ Gets actual secret (decrypted)
    
Result: Secret never appears in code/state!
```

#### Diagram 2: Module Access Control Layers

```
Public Terraform Registry
┌──────────────────────────────────────┐
│ module "vpc" {                       │
│   source = "terraform-aws-modules/vpc/aws" │
│ }                                    │
│                                      │
│ ✓ Anyone can download                │
│ ✓ Community maintained               │
│ ✗ Cannot control code                │
└──────────────────────────────────────┘


Private Terraform Cloud Registry
┌──────────────────────────────────────┐
│ module "vpc" {                       │
│   source = "tfc.company.com/vpc/aws" │
│ }                                    │
│                                      │
│ ✓ Organization control               │
│ ✓ Versioning + immutability          │
│ ✓ Access control (OAuth/tokens)      │
│ ✓ Audit logging                      │
└──────────────────────────────────────┘
      ↓ (requires auth)
┌──────────────────────────────────────┐
│ Module Registry                      │
│ ├─ Module 1 (v2.0, v2.1, v2.2)      │
│ ├─ Module 2 (v1.0, v1.1)            │
│ └─ Module 3 (v3.0)                  │
│                                      │
│ Access: Team A, Team B, Team C       │
│ (other teams: denied)                │
└──────────────────────────────────────┘


Git Repository with Branch Protection
┌──────────────────────────────────────┐
│ main branch (protected)              │
│                                      │
│ ✓ PR required for changes            │
│ ✓ Code review approval               │
│ ✓ CI/CD status checks                │
│ ✓ GPG signature required             │
│                                      │
│ Create release tag:                  │
│ git tag -s v2.1.0 (signed)           │
└──────────────────────────────────────┘
      ↓ (publish to registry)
  ✓ New module version available
```

---

## Module Performance Optimization and Advanced Patterns

### Textual Deep Dive

#### Architecture Role

Module performance focuses on reducing:
- **Plan time**: How long `terraform plan` takes
- **Apply time**: How long `terraform apply` takes
- **State file size**: Impact on operations speed
- **API calls**: Number of calls to cloud providers
- **Resource dependencies**: Unnecessary serialization

#### Internal Working Mechanism

**Plan Phase Performance**:

```
terraform plan
    ↓
Phase 1: Configuration loading
  └─ Parse HCL, resolve modules, load variables
    ↓
Phase 2: State reading
  └─ Read current state file (can be large)
    ↓
Phase 3: Provider initialization
  └─ Initialize AWS provider, authenticate
    ↓
Phase 4: Refresh (optional)
  └─ Read actual AWS state (many API calls)
    ↓
Phase 5: Graph building
  └─ Build resource dependency graph
    ↓
Phase 6: Plan comparison
  └─ For each resource, determine changes needed
    ↓
Output: Plan with resources to create/update/destroy
```

**Graph Building Optimization**:

```
Implicit Dependencies (inferred from code):
≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.main.id  ← Implicit dependency
  # Terraform knows: aws_subnet depends on aws_vpc
}

Graph:
  aws_vpc.main → aws_subnet.main (create in order)


Explicit Dependencies (manually specified):
≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈

resource "aws_instance" "app" {
  depends_on = [aws_iam_role_policy.app]  ← Explicit dependency
  # Terraform knows: must create iam_role_policy first
}

Graph:
  aws_iam_role_policy.app → aws_instance.app


❌ Missing Dependencies (causes errors):
≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈≈

resource "aws_instance" "app" {
  # No reference to security group, no depends_on
  # Terraform doesn't know ordering!
  # May create security group AFTER instance (fails)
}

Solution: Add explicit depends_on or reference output
```

#### Production Usage Patterns

**Pattern 1: Parallel Resource Creation**

Resources without dependencies are created in parallel:

```hcl
# These 3 security groups are independent → created in parallel
resource "aws_security_group" "web" {}
resource "aws_security_group" "app" {}
resource "aws_security_group" "db" {}

# These subnets depend on VPC → created serially after VPC
resource "aws_subnet" "1" { vpc_id = aws_vpc.main.id }
resource "aws_subnet" "2" { vpc_id = aws_vpc.main.id }
resource "aws_subnet" "3" { vpc_id = aws_vpc.main.id }

# Subnets among themselves are independent → parallel creation
```

**Pattern 2: Using Data Sources to Avoid Dependencies**

```hcl
# ❌ Creates coupling: foundation state file must exist
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = { key = "foundation.tfstate" }
}

module "app" {
  vpc_id = data.terraform_remote_state.foundation.outputs.vpc_id
}

# ✅ Decoupled: foundation can be destroyed independently
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["prod-vpc"]
  }
}

module "app" {
  vpc_id = data.aws_vpc.main.id
}
```

**Pattern 3: Lazy Module Evaluation**

```hcl
# Only create resources when needed
variable "enable_monitoring" {
  type    = bool
  default = false
}

module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"
  
  # Cost: $200/month
  # Only provisioned if explicitly enabled
}

# Reduces plan time, apply time, state size
```

#### DevOps Best Practices

**1. Minimize Refresh Operations**

```bash
# ❌ Default: refresh state during plan (slow with many resources)
terraform plan
# Hits AWS API for every resource

# ✅ Skip refresh if state is known fresh
terraform plan -refresh=false
# Useful when planning multiple times in rapid succession

# ✅ Or use -var-file to avoid reading certain state
terraform plan \
  -var-file=prod.tfvars \
  -lock=false  # Don't lock if just planning
```

**2. Use `for_each` Over Nested Loops**

```hcl
# ❌ Slow: Nested loops with dynamic blocks
locals {
  instances = flatten([
    for env in var.environments : [
      for az in var.azs : {
        environment = env
        az          = az
      }
    ]
  ])
}

resource "aws_instance" "main" {
  for_each = { for i, instance in local.instances : "${instance.environment}-${instance.az}" => instance }
}

# ✅ Faster: Flattened locals computed once
locals {
  instance_map = {
    for env in var.environments : env => {
      for az in var.azs : az => "instance"
    }
  }
}

resource "aws_instance" "main" {
  for_each = merge([for env, azs in local.instance_map : {
    for az, _ in azs : "${env}-${az}" => {}
  }]...)
}
```

**3. Separate Fast and Slow Modules**

```hcl
# Fast apply (seconds)
module "vpc" {
  source = "./modules/vpc"
  # Creates: VPC, subnets, route tables
}

# Slow apply (minutes)
module "rds" {
  source = "./modules/rds"
  # Creates: RDS database (5-10 minutes)
}

# Better: Two separate root configurations
# Apply VPC first, then RDS independently
# If RDS fails, VPC still exists (no rollback)
```

#### Common Pitfalls

**Pitfall 1: Over-Parameterization**

```hcl
# ❌ Module with 50 variables
# Evaluation time increases with variable count
variable "var1" { type = string }
variable "var2" { type = string }
# ... 48 more variables

# ✅ Module with structured inputs
variable "config" {
  type = object({
    var1 = string
    var2 = string
    # ...
  })
}

# Reduced evaluation overhead
```

**Pitfall 2: Fetching All Data Sources**

```hcl
# ❌ Fetches ALL instances, then filters
data "aws_instances" "all" {
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# ✅ Use specific filters to reduce API calls
data "aws_instances" "app" {
  filter {
    name   = "tag:Application"
    values = ["myapp"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}
```

**Pitfall 3: Unnecessary Refresh**

```bash
# ❌ Every plan reads all resource state from AWS
terraform plan
# 100 resources × 1 API call = 100 API calls

# ✅ Skip refresh if you trust current state
terraform plan -refresh=false
# 0 API calls (if state is current)
```

---

### Practical Code Examples

#### Example 1: Performance-Optimized Multi-Environment Module

```hcl
# modules/application-optimized/variables.tf

variable "environments" {
  type = map(object({
    enabled           = bool
    instance_count    = number
    instance_type     = string
    enable_monitoring = bool
    enable_backups    = bool
  }))
  
  description = "Environment configurations"
  default = {
    "dev" = {
      enabled           = true
      instance_count    = 1
      instance_type     = "t3.micro"
      enable_monitoring = false
      enable_backups    = false
    }
    "prod" = {
      enabled           = true
      instance_count    = 3
      instance_type     = "t3.large"
      enable_monitoring = true
      enable_backups    = true
    }
  }
}

# modules/application-optimized/main.tf

locals {
  # Only process enabled environments
  active_envs = {
    for env, config in var.environments :
    env => config if config.enabled
  }
}

# Provision compute resources
resource "aws_instance" "main" {
  for_each = {
    for env, config in local.active_envs :
    env => {
      count         = config.instance_count
      instance_type = config.instance_type
    }
  }
  
  for_each_nested = range(each.value.count)  # Pseudo-code
  
  # In practice, use local.instance_map (see above)
  
  image_id      = data.aws_ami.latest.id
  instance_type = each.value.instance_type
}

# Only provision monitoring if enabled (reduces plan time, state size)
module "monitoring" {
  for_each = {
    for env, config in local.active_envs :
    env => config if config.enable_monitoring
  }
  
  source = "../monitoring"
  
  environment = each.key
  service_name = "app-${each.key}"
}

# Only provision backup resources if enabled
resource "aws_backup_vault" "main" {
  for_each = {
    for env, config in local.active_envs :
    env => config if config.enable_backups
  }
  
  name = "app-backup-${each.key}"
}
```

#### Example 2: Dependency Graph Optimization

```hcl
# Poor dependency design (serial, slow):
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "main" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone = var.availability_zones[count.index]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.main)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.main[count.index].id
  depends_on    = [aws_internet_gateway.main]  # Unnecessary!
}

# Better design (parallel where possible):
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

# These 2 can run in parallel (independent of each other)
resource "aws_subnet" "main" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone = var.availability_zones[count.index]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# NAT depends only on subnet and internet gateway (implicit in code)
resource "aws_nat_gateway" "main" {
  count         = length(aws_subnet.main)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.main[count.index].id
  # Remove unnecessary depends_on - implicit dependency exists
}

# Result: VPC created → then Subnet + IGW in parallel → then NAT gateways
# Saves ~30% time on deployment
```

### ASCII Diagrams

#### Diagram 1: Resource Dependency Graph (Serial vs. Parallel)

```
SERIAL DEPENDENCY (Slow):
═════════════════════════

aws_vpc.main
    ↓
aws_subnet.main[0]
    ↓
aws_subnet.main[1]
    ↓
aws_subnet.main[2]
    ↓
aws_internet_gateway.main
    ↓
aws_nat_gateway.main[0]
    ↓
aws_nat_gateway.main[1]
    ↓
aws_nat_gateway.main[2]

Time: 8 sequential operations = slow


PARALLEL DEPENDENCY (Fast):
════════════════════════════

aws_vpc.main
    │
    ├─→ aws_subnet.main[0]  ┐
    ├─→ aws_subnet.main[1]  ├─→ (parallel) ─→ aws_nat_gateway
    ├─→ aws_subnet.main[2]  ┘
    │
    └─→ aws_internet_gateway.main

Time: 3 rounds of parallel operations = faster

Performance gain: 60% reduction (8 ops → 3 rounds)
```

#### Diagram 2: Plan Time Breakdown with Module Optimization

```
Large Module (50 variables, all paths enabled):
═════════════════════════════════════════════════

terraform plan
  ├─ Configuration loading: 2s
  ├─ State reading: 5s
  ├─ Provider init: 3s
  ├─ Refresh (API calls):
  │   ├─ EC2: describe-instances × 20 = 5s
  │   ├─ RDS: describe-db-instances × 5 = 2s
  │   ├─ VPC: describe-vpcs × 1 = 1s
  │   └─ Other: 2s
  ├─ Graph building: 3s
  └─ Plan comparison: 2s
  ───────────────
  Total: 25 seconds


Optimized Module (structured inputs, conditional resources):
════════════════════════════════════════════════════════════

terraform plan
  ├─ Configuration loading: 1s (fewer variables)
  ├─ State reading: 2s (smaller state)
  ├─ Provider init: 1s
  ├─ Refresh (API calls):
  │   ├─ EC2: describe-instances × 5 = 1s (only enabled resources)
  │   ├─ RDS: describe-db-instances × 0 = 0s (RDS disabled)
  │   └─ Other: 1s (minimal)
  ├─ Graph building: 1s (simpler graph)
  └─ Plan comparison: 1s
  ───────────────
  Total: 8 seconds

Improvement: 25s → 8s (68% faster)
```

---

## Summary: Module Mastery at Senior Level

As a Senior DevOps Engineer, you've now covered the complete spectrum of Terraform module expertise:

**Foundation & Core Concepts**:
- Module structure, variables, outputs, versioning
- Modular architecture and reusability patterns
- Code organization best practices

**Advanced Patterns**:
- Meta-arguments (count, for_each, depends_on, lifecycle)
- Dynamic blocks and complex conditional logic
- Resource composition and dependency management

**State & Isolation**:
- Monolithic vs. layered state architectures
- Multi-environment and multi-team isolation
- State locking, backends, and cross-module references

**Quality & Reliability**:
- Testing frameworks and validation layers
- Policy as code and governance
- Security-first module design
- Performance optimization techniques

**Real-World Scenarios** (4 comprehensive case studies):
- Multi-environment deployments with modules
- Module composition and dependency management
- Disaster recovery and multi-region failover
- Breaking change migrations at scale

**Interview Mastery** (30 detailed questions):
- Questions 1-10: Foundation and architecture reasoning
- Questions 11-16: Advanced topics and complex scenarios
- Questions 17-30: Production operations and organization-scale challenges

**Key Takeaways**:

1. **Module design is architecture design** - Good modules reflect good architecture thinking (SRP, composition, encapsulation)

2. **Modules scale from teams to organizations** - Patterns differ at 1 team, 10 teams, 100 teams

3. **Breaking changes are okay with process** - Semantic versioning + communication + migration tools make major changes manageable

4. **Simpler modules, fewer features** - T-shirt sizes beat unlimited customization; variants beat feature-bloated modules

5. **Tests beat documentation** - Input validation, policy enforcement, and test automation catch issues before apply

6. **State architecture is foundational** - Monolithic state limits scaling; layered state enables organizational growth

7. **Security is in module design** - Secrets manager references (not secrets), least privilege IAM, audit logging

8. **Performance matters at scale** - Data source queries, state layering, and dependency optimization become critical

This guide positions you to:
- Design modules for enterprise organizations (100s-1000s of teams)
- Lead infrastructure standardization initiatives
- Make architecture decisions that scale
- Mentor team members on module best practices
- Handle complex incidents involving multi-module deployments

**Resources for Continued Learning**:
- Terraform official modules: [terraform-aws-modules](https://github.com/terraform-aws-modules)
- Hashicorp Terraform documentation: [registry.terraform.io](https://registry.terraform.io)
- Community forums: Terraform Discourse
- Real-world examples: Browse published modules on Terraform Registry

---

*Complete Senior DevOps Study Guide*
*Last Updated: March 2026*
*Suitable for: DevOps Engineers with 5-10+ years experience*
